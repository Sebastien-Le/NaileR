# ===========================================================================
# Validation and small helpers
# ===========================================================================

validate_qda_space_inputs <- function(ncp,
                                      scale.unit,
                                      min_inertia_pct,
                                      top_n_var,
                                      top_n_products,
                                      top_n_profile_markers,
                                      condes_proba,
                                      generate,
                                      expertise_mode) {
  if (!is.numeric(ncp) ||
      length(ncp) != 1L ||
      is.na(ncp) ||
      !is.finite(ncp) ||
      ncp < 1 ||
      ncp != floor(ncp)) {
    stop(
      "`ncp` must be a single integer >= 1.",
      call. = FALSE
    )
  }

  if (!is.logical(scale.unit) ||
      length(scale.unit) != 1L ||
      is.na(scale.unit)) {
    stop(
      "`scale.unit` must be TRUE or FALSE.",
      call. = FALSE
    )
  }

  if (!is.numeric(min_inertia_pct) ||
      length(min_inertia_pct) != 1L ||
      is.na(min_inertia_pct) ||
      !is.finite(min_inertia_pct) ||
      min_inertia_pct < 0 ||
      min_inertia_pct > 100) {
    stop(
      "`min_inertia_pct` must be a single numeric value in [0, 100].",
      call. = FALSE
    )
  }

  .check_positive_integer <- function(x, name) {
    if (!is.numeric(x) ||
        length(x) != 1L ||
        is.na(x) ||
        !is.finite(x) ||
        x < 1 ||
        x != floor(x)) {
      stop(
        sprintf(
          "`%s` must be a single integer >= 1.",
          name
        ),
        call. = FALSE
      )
    }
  }

  .check_positive_integer(top_n_var, "top_n_var")
  .check_positive_integer(top_n_products, "top_n_products")
  .check_positive_integer(
    top_n_profile_markers,
    "top_n_profile_markers"
  )

  if (!is.numeric(condes_proba) ||
      length(condes_proba) != 1L ||
      is.na(condes_proba) ||
      !is.finite(condes_proba) ||
      condes_proba < 0 ||
      condes_proba > 1) {
    stop(
      "`condes_proba` must be a single numeric value in [0, 1].",
      call. = FALSE
    )
  }

  if (!is.logical(generate) ||
      length(generate) != 1L ||
      is.na(generate)) {
    stop(
      "`generate` must be TRUE or FALSE.",
      call. = FALSE
    )
  }

  if (!expertise_mode %in%
      c("sensory", "positioning", "hybrid")) {
    stop(
      paste(
        "`expertise_mode` must be one of:",
        "'sensory', 'positioning', 'hybrid'."
      ),
      call. = FALSE
    )
  }

  invisible(TRUE)
}


.qda_space_num <- function(x,
                           digits = 2L) {
  value <- suppressWarnings(
    as.numeric(x)[1L]
  )

  if (!is.finite(value)) {
    return("NA")
  }

  formatC(
    value,
    digits = digits,
    format = "f"
  )
}


.qda_space_direction_label <- function(x) {
  if (identical(x, "higher")) {
    return("HIGHER")
  }

  if (identical(x, "lower")) {
    return("LOWER")
  }

  "DIFFERENT"
}


.qda_space_source_label <- function(source) {
  if (is.null(source) ||
      length(source) == 0L ||
      is.na(source[[1L]])) {
    return("interpretive summary")
  }

  source <- as.character(source[[1L]])

  if (identical(source, "expert")) {
    return("expert-edited interpretation")
  }

  if (identical(source, "llm_pass1")) {
    return("model-assisted proposal")
  }

  "retained interpretation"
}


.qda_space_inform_parse_failures <- function(product_interpretations) {
  if (is.null(product_interpretations) ||
      !is.list(product_interpretations) ||
      !is.list(product_interpretations$products) ||
      length(product_interpretations$products) == 0L) {
    return(invisible(character(0)))
  }

  products <- product_interpretations$products
  product_names <- names(products)

  if (is.null(product_names)) {
    return(invisible(character(0)))
  }

  statuses <- vapply(
    products,
    function(item) {
      if (is.null(item$status) || length(item$status) == 0L) {
        return(NA_character_)
      }
      as.character(item$status[[1L]])
    },
    character(1)
  )

  failed <- product_names[
    !is.na(statuses) & statuses == "parse_failed"
  ]

  if (length(failed) == 0L) {
    return(invisible(character(0)))
  }

  if (length(failed) == 1L) {
    message(
      paste0(
        "Reusable QDA product interpretation could not be parsed for '",
        failed,
        "'. `nail_qda_space()` will use the statistical QDA evidence ",
        "for this product. Inspect the original response with ",
        "`nail_response()` or revise the interpretation with ",
        "`nail_qda_interpretation()`."
      )
    )
  } else {
    message(
      paste0(
        "Reusable QDA product interpretations could not be parsed for: ",
        paste(failed, collapse = ", "),
        ". `nail_qda_space()` will use the statistical QDA evidence ",
        "for these products. Inspect the original responses with ",
        "`nail_response()` or revise the interpretations with ",
        "`nail_qda_interpretation()`."
      )
    )
  }

  invisible(failed)
}


# ===========================================================================
# Canonical QDA inputs
# ===========================================================================

.qda_space_adjmean_from_product_profiles <- function(
    product_profiles) {
  if (is.null(product_profiles) ||
      !is.list(product_profiles) ||
      !is.list(product_profiles$products) ||
      length(product_profiles$products) < 2L) {
    return(NULL)
  }

  products <- product_profiles$products
  product_names <- names(products)

  if (is.null(product_names) ||
      anyNA(product_names) ||
      any(!nzchar(product_names)) ||
      anyDuplicated(product_names)) {
    stop(
      "QDA `product_profiles` contain invalid product names.",
      call. = FALSE
    )
  }

  first <- products[[1L]]$adjusted_means

  if (!is.data.frame(first) ||
      !all(c("attribute", "adjusted_mean") %in%
        names(first))) {
    stop(
      paste(
        "QDA `product_profiles` do not contain the expected",
        "adjusted-mean representation."
      ),
      call. = FALSE
    )
  }

  attributes <- as.character(first$attribute)

  if (length(attributes) < 2L ||
      anyNA(attributes) ||
      any(!nzchar(attributes)) ||
      anyDuplicated(attributes)) {
    stop(
      "QDA adjusted-mean attribute names are invalid.",
      call. = FALSE
    )
  }

  out <- matrix(
    NA_real_,
    nrow = length(products),
    ncol = length(attributes),
    dimnames = list(
      product_names,
      attributes
    )
  )

  for (product_name in product_names) {
    item <- products[[product_name]]$adjusted_means

    if (!is.data.frame(item) ||
        !all(c("attribute", "adjusted_mean") %in%
          names(item))) {
      stop(
        sprintf(
          "Product '%s' has no valid adjusted-mean profile.",
          product_name
        ),
        call. = FALSE
      )
    }

    idx <- match(
      attributes,
      as.character(item$attribute)
    )

    if (anyNA(idx)) {
      stop(
        sprintf(
          paste(
            "Product '%s' does not contain the same",
            "adjusted sensory attributes as the other products."
          ),
          product_name
        ),
        call. = FALSE
      )
    }

    out[product_name, ] <- suppressWarnings(
      as.numeric(item$adjusted_mean[idx])
    )
  }

  if (any(!is.finite(out))) {
    stop(
      paste(
        "The canonical QDA adjusted means contain missing or",
        "non-finite values; the product space cannot be built."
      ),
      call. = FALSE
    )
  }

  as.data.frame(
    out,
    check.names = FALSE
  )
}


.qda_space_extract_inputs <- function(x) {
  product_profiles <- attr(
    x,
    "product_profiles",
    exact = TRUE
  )
  product_interpretations <- attr(
    x,
    "product_interpretations",
    exact = TRUE
  )
  decat_result <- attr(
    x,
    "decat_result",
    exact = TRUE
  )

  adjmean <- .qda_space_adjmean_from_product_profiles(
    product_profiles
  )

  source <- "canonical_product_profiles"

  if (is.null(adjmean)) {
    raw <- NULL

    if (!is.null(decat_result) &&
        is.list(decat_result) &&
        !is.null(decat_result$adjmean)) {
      raw <- decat_result$adjmean
    } else if (is.list(x) &&
               !is.null(x$adjmean)) {
      raw <- x$adjmean
    }

    if (is.null(raw)) {
      stop(
        paste(
          "`x` must be an object returned by `nail_qda()`",
          "or a raw `decat` result containing `adjmean`."
        ),
        call. = FALSE
      )
    }

    adjmean <- as.data.frame(
      raw,
      check.names = FALSE
    )

    if (nrow(adjmean) < 2L ||
        ncol(adjmean) < 2L) {
      stop(
        paste(
          "`adjmean` must contain at least two products",
          "and two sensory attributes."
        ),
        call. = FALSE
      )
    }

    adjmean[] <- lapply(
      adjmean,
      function(z) suppressWarnings(as.numeric(z))
    )

    if (any(!is.finite(as.matrix(adjmean)))) {
      stop(
        "`adjmean` contains missing or non-finite values.",
        call. = FALSE
      )
    }

    if (is.null(rownames(adjmean)) ||
        any(!nzchar(rownames(adjmean)))) {
      rownames(adjmean) <- paste0(
        "Product",
        seq_len(nrow(adjmean))
      )
    }

    source <- "raw_decat_adjmean"
  }

  list(
    adjmean = adjmean,
    product_profiles = product_profiles,
    product_interpretations = product_interpretations,
    decat_result = decat_result,
    source = source
  )
}


# ===========================================================================
# PCA and real nail_condes() characterization
# ===========================================================================

.build_qda_space_pca <- function(adjmean,
                                 ncp,
                                 scale.unit,
                                 min_inertia_pct) {
  if (nrow(adjmean) < 2L ||
      ncol(adjmean) < 2L) {
    stop(
      paste(
        "At least two products and two sensory attributes",
        "are required to build the product space."
      ),
      call. = FALSE
    )
  }

  variable_sd <- vapply(
    adjmean,
    stats::sd,
    numeric(1)
  )

  constant <- names(variable_sd)[
    !is.finite(variable_sd) |
      variable_sd == 0
  ]

  if (length(constant) > 0L) {
    stop(
      sprintf(
        paste(
          "The product space contains constant sensory",
          "attribute(s): %s."
        ),
        paste(constant, collapse = ", ")
      ),
      call. = FALSE
    )
  }

  max_ncp <- min(
    as.integer(ncp),
    nrow(adjmean) - 1L,
    ncol(adjmean)
  )

  if (max_ncp < 1L) {
    stop(
      "No PCA dimension can be computed.",
      call. = FALSE
    )
  }

  pca_result <- FactoMineR::PCA(
    adjmean,
    scale.unit = scale.unit,
    ncp = max_ncp,
    graph = FALSE
  )

  eig <- as.data.frame(
    pca_result$eig
  )

  if (ncol(eig) < 3L) {
    stop(
      "Unexpected PCA eigenvalue table.",
      call. = FALSE
    )
  }

  names(eig)[1:3] <- c(
    "eigenvalue",
    "percent",
    "cumulative_percent"
  )

  available_axes <- min(
    max_ncp,
    ncol(pca_result$ind$coord)
  )

  retained_axes <- seq_len(
    available_axes
  )
  retained_axes <- retained_axes[
    eig$percent[retained_axes] >=
      min_inertia_pct
  ]

  list(
    pca_result = pca_result,
    adjmean = adjmean,
    eigenvalues = eig,
    retained_axes = as.integer(retained_axes),
    settings = list(
      ncp_requested = as.integer(ncp),
      ncp_computed = as.integer(max_ncp),
      scale_unit = scale.unit,
      min_inertia_pct = min_inertia_pct
    )
  )
}


.build_qda_space_condes <- function(space,
                                    axis,
                                    condes_proba,
                                    model,
                                    provider) {
  dimension <- paste0(
    "Dim",
    axis
  )

  coord <- as.numeric(
    space$pca_result$ind$coord[, axis]
  )

  work <- data.frame(
    NAILER_DIMENSION_SCORE = coord,
    space$adjmean,
    check.names = FALSE
  )

  condes_out <- nail_condes(
    dataset = work,
    num.var = 1L,
    model = model,
    provider = provider,
    proba = condes_proba,
    sample.pct = 1,
    sample.method = "top",
    generate = FALSE,
    interpretation_mode = "latent",
    prompt_style = "compact",
    target_concept =
      "the sensory continuum represented by this product-space dimension",
    target_label = dimension
  )

  continuous_profile <- attr(
    condes_out,
    "continuous_profile",
    exact = TRUE
  )

  if (is.null(continuous_profile) ||
      !is.list(continuous_profile) ||
      !is.data.frame(
        continuous_profile$quantitative_associations
      )) {
    stop(
      sprintf(
        paste(
          "Internal error: `nail_condes()` did not return",
          "a valid continuous profile for %s."
        ),
        dimension
      ),
      call. = FALSE
    )
  }

  list(
    output = condes_out,
    continuous_profile = continuous_profile
  )
}


.select_qda_space_axis_associations <- function(
    continuous_profile,
    top_n_var) {
  x <- continuous_profile$quantitative_associations

  if (!is.data.frame(x) ||
      nrow(x) == 0L) {
    return(x)
  }

  abs_cor <- suppressWarnings(
    as.numeric(x$abs_correlation)
  )
  p_value <- suppressWarnings(
    as.numeric(x$p_value)
  )

  abs_cor[!is.finite(abs_cor)] <- -Inf
  p_value[!is.finite(p_value)] <- Inf

  x <- x[
    order(
      -abs_cor,
      p_value,
      as.character(x$variable),
      na.last = TRUE
    ),
    ,
    drop = FALSE
  ]

  x <- utils::head(
    x,
    as.integer(top_n_var)
  )
  rownames(x) <- NULL
  x
}


# ===========================================================================
# Product evidence at each pole
# ===========================================================================

.qda_space_expected_marker_direction <- function(
    correlation,
    side) {
  correlation <- suppressWarnings(
    as.numeric(correlation)[1L]
  )

  if (!is.finite(correlation) ||
      !side %in% c("negative", "positive")) {
    return(NA_character_)
  }

  if (side == "positive") {
    if (correlation >= 0) {
      "higher"
    } else {
      "lower"
    }
  } else {
    if (correlation >= 0) {
      "lower"
    } else {
      "higher"
    }
  }
}


.qda_space_product_interpretation <- function(
    product_interpretations,
    product_name) {
  if (is.null(product_interpretations) ||
      !is.list(product_interpretations) ||
      !is.list(product_interpretations$products) ||
      !product_name %in%
        names(product_interpretations$products)) {
    return(NULL)
  }

  item <- product_interpretations$products[[product_name]]

  if (is.null(item) ||
      !identical(item$status, "available") ||
      is.null(item$core_profile) ||
      length(item$core_profile) == 0L ||
      is.na(item$core_profile[[1L]]) ||
      !nzchar(trimws(
        as.character(item$core_profile[[1L]])
      ))) {
    return(NULL)
  }

  item
}


.qda_space_product_profile <- function(product_profiles,
                                       product_name) {
  if (is.null(product_profiles) ||
      !is.list(product_profiles) ||
      !is.list(product_profiles$products) ||
      !product_name %in%
        names(product_profiles$products)) {
    return(NULL)
  }

  product_profiles$products[[product_name]]
}


.qda_space_classify_product_markers <- function(
    markers,
    axis_associations,
    side,
    top_n_profile_markers) {
  empty <- if (is.data.frame(markers)) {
    markers[0, , drop = FALSE]
  } else {
    data.frame()
  }

  if (!is.data.frame(markers) ||
      nrow(markers) == 0L) {
    return(
      list(
        reinforcing = empty,
        conflicting = empty,
        additional = empty
      )
    )
  }

  if (!is.data.frame(axis_associations) ||
      nrow(axis_associations) == 0L) {
    additional <- utils::head(
      markers,
      top_n_profile_markers
    )

    return(
      list(
        reinforcing = empty,
        conflicting = empty,
        additional = additional
      )
    )
  }

  assoc_index <- match(
    as.character(markers$attribute),
    as.character(axis_associations$variable)
  )

  on_axis <- !is.na(assoc_index)
  expected <- rep(
    NA_character_,
    nrow(markers)
  )

  expected[on_axis] <- vapply(
    assoc_index[on_axis],
    function(j) {
      .qda_space_expected_marker_direction(
        axis_associations$correlation[[j]],
        side = side
      )
    },
    character(1)
  )

  marker_direction <- as.character(
    markers$direction
  )

  reinforcing <- markers[
    on_axis &
      marker_direction == expected,
    ,
    drop = FALSE
  ]

  conflicting <- markers[
    on_axis &
      marker_direction != expected &
      !is.na(expected),
    ,
    drop = FALSE
  ]

  additional <- markers[
    !on_axis,
    ,
    drop = FALSE
  ]

  list(
    reinforcing = utils::head(
      reinforcing,
      top_n_profile_markers
    ),
    conflicting = utils::head(
      conflicting,
      top_n_profile_markers
    ),
    additional = utils::head(
      additional,
      top_n_profile_markers
    )
  )
}


.build_qda_space_product_item <- function(
    product_name,
    side,
    coordinate,
    contribution,
    cos2,
    axis_associations,
    product_profiles,
    product_interpretations,
    top_n_profile_markers) {
  profile <- .qda_space_product_profile(
    product_profiles,
    product_name
  )

  markers <- if (!is.null(profile) &&
                 is.data.frame(
                   profile$retained_markers
                 )) {
    profile$retained_markers
  } else {
    data.frame()
  }

  marker_roles <- .qda_space_classify_product_markers(
    markers = markers,
    axis_associations = axis_associations,
    side = side,
    top_n_profile_markers =
      top_n_profile_markers
  )

  interpretation <- .qda_space_product_interpretation(
    product_interpretations,
    product_name
  )

  list(
    product = product_name,
    side = side,
    coordinate = as.numeric(coordinate),
    contribution = as.numeric(contribution),
    cos2 = as.numeric(cos2),
    interpretation = interpretation,
    marker_roles = marker_roles,
    metrics = list(
      n_retained_markers = if (is.data.frame(markers)) {
        as.integer(nrow(markers))
      } else {
        0L
      },
      n_reinforcing_shown =
        as.integer(
          nrow(marker_roles$reinforcing)
        ),
      n_conflicting_shown =
        as.integer(
          nrow(marker_roles$conflicting)
        ),
      n_additional_shown =
        as.integer(
          nrow(marker_roles$additional)
        )
    )
  )
}


.build_qda_space_axis_products <- function(
    space,
    axis,
    axis_associations,
    product_profiles,
    product_interpretations,
    top_n_products,
    top_n_profile_markers) {
  coord <- as.numeric(
    space$pca_result$ind$coord[, axis]
  )
  names(coord) <- rownames(
    space$pca_result$ind$coord
  )

  contribution <- as.numeric(
    space$pca_result$ind$contrib[, axis]
  )
  names(contribution) <- names(coord)

  cos2 <- as.numeric(
    space$pca_result$ind$cos2[, axis]
  )
  names(cos2) <- names(coord)

  negative_names <- names(coord)[
    is.finite(coord) &
      coord < 0
  ]
  positive_names <- names(coord)[
    is.finite(coord) &
      coord > 0
  ]

  negative_names <- negative_names[
    order(
      coord[negative_names],
      names(coord[negative_names])
    )
  ]

  positive_names <- positive_names[
    order(
      -coord[positive_names],
      names(coord[positive_names])
    )
  ]

  negative_names <- utils::head(
    negative_names,
    top_n_products
  )
  positive_names <- utils::head(
    positive_names,
    top_n_products
  )

  build_side <- function(product_names,
                         side) {
    out <- lapply(
      product_names,
      function(product_name) {
        .build_qda_space_product_item(
          product_name = product_name,
          side = side,
          coordinate = coord[[product_name]],
          contribution =
            contribution[[product_name]],
          cos2 = cos2[[product_name]],
          axis_associations =
            axis_associations,
          product_profiles =
            product_profiles,
          product_interpretations =
            product_interpretations,
          top_n_profile_markers =
            top_n_profile_markers
        )
      }
    )

    names(out) <- product_names
    out
  }

  list(
    negative = build_side(
      negative_names,
      "negative"
    ),
    positive = build_side(
      positive_names,
      "positive"
    )
  )
}


# ===========================================================================
# Canonical QDA-space evidence
# ===========================================================================

.build_qda_space_evidence <- function(
    inputs,
    space,
    top_n_var,
    top_n_products,
    top_n_profile_markers,
    condes_proba,
    model,
    provider) {
  axes <- list()
  axis_condes <- list()

  for (axis in space$retained_axes) {
    dimension <- paste0(
      "Dim",
      axis
    )

    condes_axis <- .build_qda_space_condes(
      space = space,
      axis = axis,
      condes_proba = condes_proba,
      model = model,
      provider = provider
    )

    associations <- .select_qda_space_axis_associations(
      continuous_profile =
        condes_axis$continuous_profile,
      top_n_var = top_n_var
    )

    products <- .build_qda_space_axis_products(
      space = space,
      axis = axis,
      axis_associations = associations,
      product_profiles =
        inputs$product_profiles,
      product_interpretations =
        inputs$product_interpretations,
      top_n_products = top_n_products,
      top_n_profile_markers =
        top_n_profile_markers
    )

    axes[[dimension]] <- list(
      dimension = dimension,
      axis = as.integer(axis),
      inertia_percent = as.numeric(
        space$eigenvalues$percent[[axis]]
      ),
      sensory_structure = associations,
      continuous_profile =
        condes_axis$continuous_profile,
      products = products
    )

    axis_condes[[dimension]] <-
      condes_axis$output
  }

  out <- list(
    adjusted_means = space$adjmean,
    pca_result = space$pca_result,
    eigenvalues = space$eigenvalues,
    retained_axes = space$retained_axes,
    axes = axes,
    settings = list(
      input_source = inputs$source,
      ncp_requested =
        space$settings$ncp_requested,
      ncp_computed =
        space$settings$ncp_computed,
      scale_unit =
        space$settings$scale_unit,
      min_inertia_pct =
        space$settings$min_inertia_pct,
      top_n_var =
        as.integer(top_n_var),
      top_n_products =
        as.integer(top_n_products),
      top_n_profile_markers =
        as.integer(top_n_profile_markers),
      condes_proba = condes_proba,
      axis_characterization =
        "nail_condes_latent"
    ),
    metadata = list(
      schema =
        "NaileR::qda_space_evidence",
      schema_version = "1.0.0",
      n_products =
        as.integer(nrow(space$adjmean)),
      n_attributes =
        as.integer(ncol(space$adjmean)),
      n_retained_axes =
        as.integer(length(space$retained_axes))
    )
  )

  class(out) <- c(
    "nail_qda_space_evidence",
    "list"
  )

  list(
    evidence = out,
    axis_condes = axis_condes
  )
}


# ===========================================================================
# Analyst-facing prompt
# ===========================================================================

build_guide_qda_space <- function(
    expertise_mode = c(
      "sensory",
      "positioning",
      "hybrid"
    )) {
  expertise_mode <- match.arg(
    expertise_mode
  )

  mode_text <- switch(
    expertise_mode,
    sensory = paste(
      "Interpretation mode: sensory.",
      "Keep the interpretation and dimension name in sensory and perceptual terms."
    ),
    positioning = paste(
      "Interpretation mode: product positioning.",
      "A broader product-style interpretation is allowed, but it must remain grounded in the sensory configuration."
    ),
    hybrid = paste(
      "Interpretation mode: hybrid.",
      "Start from the sensory configuration and only then propose a broader product-style interpretation when justified."
    )
  )

  paste(
    "## How to Read the Evidence",
    paste(
      "Each dimension represents a major opposition",
      "in the sensory product space."
    ),
    paste(
      "The sensory attributes below describe the",
      "configuration associated with each end of the dimension."
    ),
    paste(
      "Products located near the two ends are concrete",
      "examples of how these configurations are expressed."
    ),
    paste(
      "For each product, statistically distinctive",
      "attributes are factual evidence relative to the evaluated set."
    ),
    paste(
      "A product sensory interpretation is a concise summary retained for that product;",
      "it may be a model-assisted proposal or an expert-edited summary."
    ),
    paste(
      "Use that interpretation as contextual sensory knowledge,",
      "but prioritize the displayed statistical directions if the two disagree."
    ),
    paste(
      "Look for coherent sensory configurations rather than",
      "treating every attribute independently."
    ),
    paste(
      "Distinguish what defines the overall dimension from",
      "what is specific to one product."
    ),
    paste(
      "The sign of a PCA dimension is arbitrary:",
      "interpret the opposition between the two ends, not the sign itself."
    ),
    paste(
      "Do not infer liking, quality, consumer preference,",
      "premium character, market success, or causality from sensory evidence alone."
    ),
    mode_text,
    sep = "\n"
  )
}


build_request_qda_space <- function(
    expertise_mode = c(
      "sensory",
      "positioning",
      "hybrid"
    )) {
  expertise_mode <- match.arg(
    expertise_mode
  )

  final_rule <- switch(
    expertise_mode,
    sensory =
      "Propose one concise sensory name for the dimension.",
    positioning =
      paste(
        "Propose one concise product-space name for the dimension,",
        "grounded in the sensory opposition."
      ),
    hybrid =
      paste(
        "Propose one concise sensory name and, only if useful,",
        "a broader product-style interpretation."
      )
  )

  paste(
    paste(
      "Using only the evidence below, interpret this dimension",
      "as an analyst of sensory product spaces."
    ),
    paste(
      "1. Identify the coherent sensory configuration",
      "toward each end of the dimension."
    ),
    paste(
      "2. Explain how the attributes combine into perceptual",
      "patterns rather than listing them independently."
    ),
    paste(
      "3. Use the extreme products as concrete exemplars",
      "of the two poles."
    ),
    paste(
      "4. Use each retained product sensory summary to enrich",
      "the reading of the product, while checking it against",
      "the statistically distinctive attributes shown below."
    ),
    paste(
      "5. Separate evidence that reinforces the common pole",
      "from additional product-specific nuances."
    ),
    paste(
      "6. If a product interpretation conflicts with the",
      "statistical directions, keep the statistical direction",
      "and mention the interpretive discrepancy only if it matters."
    ),
    paste(
      "7. State what common sensory opposition best explains",
      "both the attribute structure and the products at the two ends."
    ),
    paste(
      '8. Write one sentence beginning with:',
      '"What separates the higher/positive end from the lower/negative end of the dimension is...".'
    ),
    paste0("9. ", final_rule),
    paste(
      "Do not merely paraphrase each fact and do not invent",
      "causal, hedonic, or marketing explanations."
    ),
    sep = "\n"
  )
}


build_conclusion_qda_space <- function(
    expertise_mode = c(
      "sensory",
      "positioning",
      "hybrid"
    )) {
  expertise_mode <- match.arg(
    expertise_mode
  )

  last_item <- switch(
    expertise_mode,
    sensory =
      "6. **Proposed dimension** — one concise sensory name and a short evidence-based justification.",
    positioning =
      "6. **Proposed dimension** — one concise product-space name grounded in the sensory evidence.",
    hybrid =
      "6. **Proposed dimension** — one concise sensory name, plus a broader product-style interpretation only if justified."
  )

  paste(
    "# Final Summary Task",
    "End with:",
    "1. **Main sensory continuum** — one concise statement of the opposition represented by the dimension.",
    "2. **Lower/negative sensory configuration** — the coherent pattern and the products that best embody it.",
    "3. **Higher/positive sensory configuration** — the coherent pattern and the products that best embody it.",
    "4. **Product-based refinements** — the most useful confirmations, nuances, or discrepancies.",
    '5. **What separates the ends** — one sentence beginning with "What separates the higher/positive end from the lower/negative end of the dimension is...".',
    last_item,
    "",
    "# Output format",
    "Your output must be **formatted using valid Quarto Markdown**.",
    sep = "\n"
  )
}


.qda_space_axis_contrast_text <- function(
    associations) {
  if (!is.data.frame(associations) ||
      nrow(associations) == 0L) {
    return(
      "*No sensory attribute met the current axis-characterization threshold.*"
    )
  }

  lines <- vapply(
    seq_len(nrow(associations)),
    function(i) {
      row <- associations[
        i,
        ,
        drop = FALSE
      ]

      lower_direction <-
        .qda_space_expected_marker_direction(
          correlation = row$correlation,
          side = "negative"
        )

      higher_direction <-
        .qda_space_expected_marker_direction(
          correlation = row$correlation,
          side = "positive"
        )

      paste0(
        "- ",
        row$variable,
        ": ",
        toupper(lower_direction),
        " at the lower/negative end",
        " ↔ ",
        toupper(higher_direction),
        " at the higher/positive end",
        " (|r|=",
        .qda_space_num(
          abs(row$correlation),
          digits = 2L
        ),
        ")."
      )
    },
    character(1)
  )

  paste(
    lines,
    collapse = "\n"
  )
}


.qda_space_marker_lines <- function(markers) {
  if (!is.data.frame(markers) ||
      nrow(markers) == 0L) {
    return(character(0))
  }

  vapply(
    seq_len(nrow(markers)),
    function(i) {
      row <- markers[
        i,
        ,
        drop = FALSE
      ]

      paste0(
        "- ",
        row$attribute,
        ": ",
        .qda_space_direction_label(
          as.character(row$direction)
        ),
        " than the average product profile",
        if ("evidence_id" %in%
            names(row) &&
            !is.na(row$evidence_id[[1L]])) {
          paste0(
            " [",
            row$evidence_id[[1L]],
            "]"
          )
        } else {
          ""
        },
        "."
      )
    },
    character(1)
  )
}


.qda_space_product_text <- function(item) {
  pieces <- c(
    paste0(
      "#### Product '",
      item$product,
      "'"
    ),
    "",
    paste0(
      "Position on the dimension: coordinate=",
      .qda_space_num(item$coordinate),
      "; contribution=",
      .qda_space_num(item$contribution),
      "%; cos2=",
      .qda_space_num(item$cos2),
      "."
    )
  )

  interpretation <- item$interpretation

  if (!is.null(interpretation)) {
    pieces <- c(
      pieces,
      "",
      paste0(
        "**Product sensory summary — ",
        .qda_space_source_label(
          interpretation$source
        ),
        "**"
      ),
      "",
      as.character(
        interpretation$core_profile[[1L]]
      )
    )

  } else {
    pieces <- c(
      pieces,
      "",
      paste(
        "**Product sensory summary:**",
        "not available; rely on the statistical product profile below."
      )
    )
  }

  reinforcing <- .qda_space_marker_lines(
    item$marker_roles$reinforcing
  )
  conflicting <- .qda_space_marker_lines(
    item$marker_roles$conflicting
  )
  additional <- .qda_space_marker_lines(
    item$marker_roles$additional
  )

  if (length(reinforcing) > 0L) {
    pieces <- c(
      pieces,
      "",
      "**Statistically distinctive attributes reinforcing this pole**",
      "",
      reinforcing
    )
  }

  if (length(additional) > 0L) {
    pieces <- c(
      pieces,
      "",
      "**Additional statistically distinctive product attributes**",
      "",
      additional
    )
  }

  if (length(conflicting) > 0L) {
    pieces <- c(
      pieces,
      "",
      "**Statistically distinctive attributes that do not follow the selected pole pattern**",
      "",
      conflicting
    )
  }

  normalize_blank_lines(
    paste(
      pieces,
      collapse = "\n"
    )
  )
}


.qda_space_axis_data_text <- function(axis_evidence) {
  negative_products <- axis_evidence$products$negative
  positive_products <- axis_evidence$products$positive

  negative_text <- if (length(negative_products) == 0L) {
    "*No product lies clearly on this side of the dimension.*"
  } else {
    paste(
      vapply(
        negative_products,
        .qda_space_product_text,
        character(1)
      ),
      collapse = "\n\n"
    )
  }

  positive_text <- if (length(positive_products) == 0L) {
    "*No product lies clearly on this side of the dimension.*"
  } else {
    paste(
      vapply(
        positive_products,
        .qda_space_product_text,
        character(1)
      ),
      collapse = "\n\n"
    )
  }

  paste(
    paste0(
      "## ",
      axis_evidence$dimension,
      " (",
      .qda_space_num(
        axis_evidence$inertia_percent,
        digits = 2L
      ),
      "% of inertia)"
    ),
    "",
    "### Sensory contrasts defining the dimension",
    "",
    .qda_space_axis_contrast_text(
      axis_evidence$sensory_structure
    ),
    "",
    "### Products representing the lower/negative end",
    "",
    negative_text,
    "",
    "### Products representing the higher/positive end",
    "",
    positive_text,
    sep = "\n"
  )
}


# ===========================================================================
# LLM IO and artifact attachment
# ===========================================================================

.qda_space_backend_response_text <- function(x) {
  if (is.data.frame(x) &&
      "response" %in% names(x) &&
      nrow(x) > 0L) {
    return(
      paste(
        as.character(x$response),
        collapse = "\n"
      )
    )
  }

  if (is.list(x) &&
      !is.null(x$response)) {
    return(
      paste(
        as.character(x$response),
        collapse = "\n"
      )
    )
  }

  if (is.character(x)) {
    return(
      paste(
        x,
        collapse = "\n"
      )
    )
  }

  stop(
    paste(
      "The QDA-space LLM backend result does not contain",
      "a readable raw response."
    ),
    call. = FALSE
  )
}


.attach_qda_space_artifacts <- function(
    x,
    qda_space_evidence,
    axis_condes,
    product_profiles,
    product_interpretations,
    prompts,
    responses,
    settings) {
  attr(x, "qda_space_evidence") <-
    qda_space_evidence

  # Compatibility/direct-access alias.
  attr(x, "qda_space") <-
    qda_space_evidence

  attr(x, "axis_condes") <-
    axis_condes

  attr(x, "product_profiles") <-
    product_profiles

  attr(x, "product_interpretations") <-
    product_interpretations

  attr(x, "qda_space_settings") <-
    settings

  attr(x, "llm_io") <- .new_nail_llm_io(
    stage = "interpretation",
    prompts = prompts,
    responses = responses,
    metadata = list(
      analysis = "nail_qda_space",
      scope = "pca_dimension",
      provider = settings$provider,
      model = settings$model,
      expertise_mode =
        settings$expertise_mode,
      axis_characterization =
        "nail_condes_latent"
    )
  )

  x
}


# ===========================================================================
# Main
# ===========================================================================

#' Interpret the sensory product space derived from QDA profiles
#'
#' `nail_qda_space()` interprets the main dimensions of the product space built
#' from QDA adjusted means. The normal workflow is:
#'
#' `nail_qda()` -> optional expert revision with
#' [nail_qda_interpretation()] -> `nail_qda_space()`.
#'
#' Internally, a PCA is computed from the canonical adjusted product means.
#' Each retained PCA dimension is then characterized by a real call to
#' [nail_condes()] in latent mode, with `generate = FALSE`. The continuous
#' attribute associations from that characterization define the sensory
#' continuum of the axis. The discretized `nail_condes()` end profiles are
#' retained in the attached evidence for traceability but are deliberately not
#' shown in the final product-space prompt: actual products at the extremes
#' provide the pole exemplars.
#'
#' Product-level interpretation combines PCA geometry, canonical QDA markers,
#' and the retained `product_interpretations` from [nail_qda()]. Expert-edited
#' interpretations are therefore used automatically when present.
#'
#' @param x Preferably an object returned by [nail_qda()]. A raw `decat` result
#'   containing `adjmean` is accepted for compatibility, but reusable product
#'   interpretations and canonical QDA marker evidence are then unavailable.
#' @param profile_summary Deprecated compatibility argument. It is ignored by
#'   the rebuilt evidence-first implementation.
#' @param llm_product_summaries Deprecated compatibility argument. It is ignored;
#'   reusable product interpretations now come directly from [nail_qda()].
#' @param ncp Number of PCA dimensions to compute.
#' @param scale.unit Logical; whether sensory attributes are standardized in
#'   the PCA. The rebuilt workflow defaults to `TRUE`.
#' @param min_inertia_pct Minimum percentage of inertia required for a computed
#'   dimension to receive a prompt.
#' @param top_n_var Maximum number of continuous sensory associations retained
#'   from the latent [nail_condes()] characterization for each dimension.
#' @param top_n_products Number of extreme products displayed at each end.
#' @param top_n_profile_markers Maximum number of product QDA markers displayed
#'   within each role (reinforcing, additional, conflicting).
#' @param condes_proba Significance threshold used by the internal
#'   [nail_condes()] characterization of each PCA dimension.
#' @param expertise_mode Interpretation mode: `"sensory"`, `"positioning"`, or
#'   `"hybrid"`.
#' @param introduction Optional introduction included in every axis prompt.
#' @param request Optional analytical request included in every axis prompt.
#' @param conclusion Optional final output-instruction block.
#' @param model Model name for the selected provider.
#' @param provider LLM backend: `"ollama"` or `"gemini"`.
#' @param generate If `FALSE`, build prompts without calling the final LLM. If
#'   `TRUE`, call the selected backend once per retained axis.
#' @param ... Additional provider-specific arguments for the final LLM calls.
#'
#' @return A named list of exact prompts when `generate = FALSE`, or a named
#'   list of backend results when `generate = TRUE`.
#'
#'   Attached analytical artifacts include:
#'
#'   * `qda_space_evidence`: canonical product-space evidence containing the
#'     adjusted means, PCA, eigenvalues, retained axes, latent continuous
#'     profiles, and product evidence.
#'   * `axis_condes`: the actual preview objects returned by the internal
#'     [nail_condes()] calls, one per retained axis.
#'   * `product_profiles`: canonical QDA evidence when available.
#'   * `product_interpretations`: retained model-assisted or expert-edited
#'     product interpretations when available.
#'   * `llm_io`: exact final prompts and raw final LLM responses for
#'     [nail_prompt()] and [nail_response()].
#'
#' @export
nail_qda_space <- function(
    x,
    profile_summary = NULL,
    llm_product_summaries = NULL,
    ncp = 2,
    scale.unit = TRUE,
    min_inertia_pct = 10,
    top_n_var = 12,
    top_n_products = 2,
    top_n_profile_markers = 5,
    condes_proba = 0.05,
    expertise_mode = c(
      "sensory",
      "positioning",
      "hybrid"
    ),
    introduction = NULL,
    request = NULL,
    conclusion = NULL,
    model = "llama3",
    provider = c(
      "ollama",
      "gemini"
    ),
    generate = FALSE,
    ...) {
  expertise_mode <- match.arg(
    expertise_mode
  )
  provider <- match.arg(provider)

  validate_qda_space_inputs(
    ncp = ncp,
    scale.unit = scale.unit,
    min_inertia_pct =
      min_inertia_pct,
    top_n_var = top_n_var,
    top_n_products =
      top_n_products,
    top_n_profile_markers =
      top_n_profile_markers,
    condes_proba =
      condes_proba,
    generate = generate,
    expertise_mode =
      expertise_mode
  )

  if (!is.null(profile_summary)) {
    warning(
      paste(
        "`profile_summary` is deprecated and ignored;",
        "`nail_qda_space()` now uses canonical QDA profiles directly."
      ),
      call. = FALSE
    )
  }

  if (!is.null(llm_product_summaries)) {
    warning(
      paste(
        "`llm_product_summaries` is deprecated and ignored;",
        "reusable product interpretations now come from `nail_qda()`."
      ),
      call. = FALSE
    )
  }

  inputs <- .qda_space_extract_inputs(x)

  .qda_space_inform_parse_failures(
    inputs$product_interpretations
  )

  space <- .build_qda_space_pca(
    adjmean = inputs$adjmean,
    ncp = ncp,
    scale.unit = scale.unit,
    min_inertia_pct =
      min_inertia_pct
  )

  settings <- list(
    ncp = as.integer(ncp),
    scale_unit = scale.unit,
    min_inertia_pct =
      min_inertia_pct,
    top_n_var =
      as.integer(top_n_var),
    top_n_products =
      as.integer(top_n_products),
    top_n_profile_markers =
      as.integer(top_n_profile_markers),
    condes_proba =
      condes_proba,
    expertise_mode =
      expertise_mode,
    generate = generate,
    provider = provider,
    model = model,
    input_source = inputs$source
  )

  if (length(space$retained_axes) == 0L) {
    out <- paste0(
      "*No PCA dimension reached the minimum inertia threshold of ",
      min_inertia_pct,
      "% under the current settings.*"
    )

    evidence <- list(
      adjusted_means = space$adjmean,
      pca_result = space$pca_result,
      eigenvalues =
        space$eigenvalues,
      retained_axes = integer(0),
      axes = list(),
      settings = c(
        space$settings,
        list(
          input_source =
            inputs$source,
          axis_characterization =
            "nail_condes_latent"
        )
      ),
      metadata = list(
        schema =
          "NaileR::qda_space_evidence",
        schema_version = "1.0.0",
        n_products =
          as.integer(nrow(space$adjmean)),
        n_attributes =
          as.integer(ncol(space$adjmean)),
        n_retained_axes = 0L
      )
    )

    class(evidence) <- c(
      "nail_qda_space_evidence",
      "list"
    )

    attr(out, "qda_space_evidence") <-
      evidence
    attr(out, "qda_space") <-
      evidence
    attr(out, "axis_condes") <- list()
    attr(out, "product_profiles") <-
      inputs$product_profiles
    attr(out, "product_interpretations") <-
      inputs$product_interpretations
    attr(out, "qda_space_settings") <-
      settings

    return(out)
  }

  built <- .build_qda_space_evidence(
    inputs = inputs,
    space = space,
    top_n_var = top_n_var,
    top_n_products =
      top_n_products,
    top_n_profile_markers =
      top_n_profile_markers,
    condes_proba =
      condes_proba,
    model = model,
    provider = provider
  )

  qda_space_evidence <- built$evidence
  axis_condes <- built$axis_condes

  if (is.null(introduction)) {
    introduction <- paste(
      "The evidence below describes one retained dimension of a sensory product space built from adjusted product profiles.",
      "The goal is to identify the coherent sensory continuum represented by the dimension and understand how products at its two ends embody that continuum."
    )
  }

  guide <- build_guide_qda_space(
    expertise_mode =
      expertise_mode
  )

  prompt_introduction <- paste(
    introduction,
    guide,
    sep = "\n\n---\n\n"
  )

  if (is.null(request)) {
    request <- build_request_qda_space(
      expertise_mode =
        expertise_mode
    )
  }

  if (is.null(conclusion)) {
    conclusion <-
      build_conclusion_qda_space(
        expertise_mode =
          expertise_mode
      )
  }

  prompts <- lapply(
    qda_space_evidence$axes,
    function(axis_evidence) {
      build_standard_prompt(
        introduction =
          prompt_introduction,
        request = request,
        data =
          .qda_space_axis_data_text(
            axis_evidence
          ),
        conclusion = conclusion
      )
    }
  )

  names(prompts) <- names(
    qda_space_evidence$axes
  )

  if (!generate) {
    return(
      .attach_qda_space_artifacts(
        x = prompts,
        qda_space_evidence =
          qda_space_evidence,
        axis_condes = axis_condes,
        product_profiles =
          inputs$product_profiles,
        product_interpretations =
          inputs$product_interpretations,
        prompts = prompts,
        responses = NULL,
        settings = settings
      )
    )
  }

  extra_args <- list(...)

  call_one <- function(prompt) {
    backend <- .call_llm_base(
      provider = provider,
      model = model,
      prompt = prompt,
      output = "df",
      llm_api_options =
        extra_args
    )

    backend$prompt <- prompt
    backend
  }

  result <- lapply(
    prompts,
    call_one
  )
  names(result) <- names(prompts)

  raw_responses <- lapply(
    result,
    .qda_space_backend_response_text
  )
  names(raw_responses) <-
    names(result)

  .attach_qda_space_artifacts(
    x = result,
    qda_space_evidence =
      qda_space_evidence,
    axis_condes = axis_condes,
    product_profiles =
      inputs$product_profiles,
    product_interpretations =
      inputs$product_interpretations,
    prompts = prompts,
    responses = raw_responses,
    settings = settings
  )
}
