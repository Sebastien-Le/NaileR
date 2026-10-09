#' @importFrom stats as.formula terms median setNames
#' @importFrom SensoMineR decat

# ===========================================================================
# Validation
# ===========================================================================

validate_qda_inputs <- function(dataset, formul, firstvar, lastvar,
                                isolate.groups, drop.negative,
                                proba, generate, sample.pct, sample.method,
                                prompt_style, product_knowledge) {
  if (!is.data.frame(dataset)) {
    stop("`dataset` must be a data frame.", call. = FALSE)
  }

  if (ncol(dataset) < 2L) {
    stop("`dataset` must contain at least two columns.", call. = FALSE)
  }

  assert_index_range(firstvar, lastvar, ncol(dataset))
  assert_proportion(proba, "proba")
  assert_proportion(sample.pct, "sample.pct")
  if (!sample.method %in% c("stratified", "top")) {
    stop("`sample.method` must be one of: 'stratified', 'top'.", call. = FALSE)
  }
  assert_single_logical(isolate.groups, "isolate.groups")
  assert_single_logical(drop.negative, "drop.negative")
  assert_single_logical(generate, "generate")

  if (!prompt_style %in% c("detailed", "compact")) {
    stop("`prompt_style` must be one of: 'detailed', 'compact'.", call. = FALSE)
  }

  if (!product_knowledge %in% c("known", "unknown")) {
    stop("`product_knowledge` must be one of: 'known', 'unknown'.", call. = FALSE)
  }

  if (missing(formul) || is.null(formul) ||
      !nzchar(trimws(paste(formul, collapse = " ")))) {
    stop("`formul` must be provided and non-empty.", call. = FALSE)
  }

  formula_obj <- tryCatch(
    stats::as.formula(paste(formul, collapse = " ")),
    error = function(e) {
      stop("`formul` could not be parsed as a valid formula.", call. = FALSE)
    }
  )

  rhs_terms <- attr(stats::terms(formula_obj), "term.labels")

  if (length(rhs_terms) < 1L) {
    stop("`formul` must contain at least one right-hand-side term.", call. = FALSE)
  }

  product_var <- trimws(rhs_terms[1L])

  if (!product_var %in% colnames(dataset)) {
    stop(
      sprintf(
        "The first right-hand-side term in `formul` ('%s') was not found in `dataset`.",
        product_var
      ),
      call. = FALSE
    )
  }

  product_col <- dataset[[product_var]]
  if (!is.factor(product_col)) {
    product_col <- as.factor(product_col)
  }

  if (nlevels(product_col) < 2L) {
    stop(
      sprintf(
        "The product factor '%s' must have at least 2 levels.",
        product_var
      ),
      call. = FALSE
    )
  }

  invisible(TRUE)
}


validate_qda_default_blocks <- function(default_blocks) {
  allowed <- c("reading", "interpretation", "local_task")

  if (!is.character(default_blocks) || anyNA(default_blocks)) {
    stop(
      "`default_blocks` must be a character vector containing only: reading, interpretation, local_task.",
      call. = FALSE
    )
  }

  unknown <- setdiff(default_blocks, allowed)
  if (length(unknown) > 0L) {
    stop(
      sprintf(
        "Unknown QDA default block(s): %s. Allowed blocks are: %s.",
        paste(sprintf("'%s'", unknown), collapse = ", "),
        paste(allowed, collapse = ", ")
      ),
      call. = FALSE
    )
  }

  if (anyDuplicated(default_blocks)) {
    stop("`default_blocks` must not contain duplicated block names.", call. = FALSE)
  }

  default_blocks
}


# ===========================================================================
# Mechanical helpers
# ===========================================================================

.standardize_qda_result_names <- function(df) {
  if (is.null(df) || ncol(df) == 0L) {
    return(df)
  }

  nms <- colnames(df)
  nms[nms %in% c("Adjust.mean", "Adjust mean")] <- "Adjust mean"
  nms[nms %in% c("P-value", "P.value", "p.value")] <- "p.value"
  nms[nms %in% c("Vtest", "v.test")] <- "v.test"
  nms[nms %in% c("Coefficient", "Coeff")] <- "Coeff"
  colnames(df) <- nms
  df
}


.extract_qda_product_variable <- function(formul) {
  formula_obj <- stats::as.formula(paste(formul, collapse = " "))
  rhs_terms <- attr(stats::terms(formula_obj), "term.labels")
  trimws(rhs_terms[1L])
}


.qda_numeric <- function(x) {
  suppressWarnings(as.numeric(as.character(x)))
}


.empty_qda_marker_table <- function() {
  data.frame(
    evidence_id = character(0),
    product = character(0),
    attribute = character(0),
    direction = character(0),
    coefficient = numeric(0),
    adjusted_mean = numeric(0),
    p_value = numeric(0),
    v_test = numeric(0),
    rank = integer(0),
    stringsAsFactors = FALSE
  )
}


.order_qda_markers <- function(markers) {
  if (!is.data.frame(markers) || nrow(markers) == 0L) {
    return(markers)
  }

  p <- markers$p_value
  p[!is.finite(p)] <- Inf

  v <- abs(markers$v_test)
  v[!is.finite(v)] <- -Inf

  attribute <- as.character(markers$attribute)
  attribute[is.na(attribute)] <- ""

  markers[
    order(p, -v, attribute, na.last = TRUE),
    ,
    drop = FALSE
  ]
}


.qda_adjusted_means_for_product <- function(adjmean,
                                             product_name,
                                             attribute_names) {
  values <- rep(NA_real_, length(attribute_names))

  if (is.data.frame(adjmean) &&
      nrow(adjmean) > 0L &&
      product_name %in% rownames(adjmean)) {
    common <- intersect(attribute_names, colnames(adjmean))
    if (length(common) > 0L) {
      row <- adjmean[product_name, common, drop = FALSE]
      values[match(common, attribute_names)] <- vapply(
        row,
        function(x) .qda_numeric(x)[1L],
        numeric(1)
      )
    }
  }

  data.frame(
    attribute = attribute_names,
    adjusted_mean = values,
    stringsAsFactors = FALSE
  )
}


.qda_markers_for_product <- function(res_cd,
                                     product_name,
                                     product_index,
                                     proba) {
  if (!"quanti" %in% names(res_cd) ||
      is.null(res_cd$quanti[[product_name]])) {
    return(.empty_qda_marker_table())
  }

  raw <- as.data.frame(res_cd$quanti[[product_name]])
  raw <- .standardize_qda_result_names(raw)

  if (nrow(raw) == 0L) {
    return(.empty_qda_marker_table())
  }

  attribute <- rownames(raw)
  if (is.null(attribute) || any(!nzchar(attribute))) {
    attribute <- as.character(seq_len(nrow(raw)))
  }

  get_num <- function(name) {
    if (!name %in% names(raw)) {
      return(rep(NA_real_, nrow(raw)))
    }
    .qda_numeric(raw[[name]])
  }

  coefficient <- get_num("Coeff")
  adjusted_mean <- get_num("Adjust mean")
  p_value <- get_num("p.value")
  v_test <- get_num("v.test")

  keep <- rep(TRUE, nrow(raw))
  finite_p <- is.finite(p_value)
  keep[finite_p] <- p_value[finite_p] <= proba

  direction <- ifelse(
    is.finite(v_test) & v_test > 0,
    "higher",
    ifelse(
      is.finite(v_test) & v_test < 0,
      "lower",
      ifelse(
        is.finite(coefficient) & coefficient > 0,
        "higher",
        ifelse(
          is.finite(coefficient) & coefficient < 0,
          "lower",
          "undetermined"
        )
      )
    )
  )

  markers <- data.frame(
    evidence_id = rep(NA_character_, nrow(raw)),
    product = rep(product_name, nrow(raw)),
    attribute = as.character(attribute),
    direction = direction,
    coefficient = coefficient,
    adjusted_mean = adjusted_mean,
    p_value = p_value,
    v_test = v_test,
    rank = rep(NA_integer_, nrow(raw)),
    stringsAsFactors = FALSE
  )

  markers <- markers[keep, , drop = FALSE]
  markers <- .order_qda_markers(markers)

  if (nrow(markers) == 0L) {
    return(.empty_qda_marker_table())
  }

  markers$rank <- seq_len(nrow(markers))
  markers$evidence_id <- sprintf(
    "QDAP%03dE%03d",
    as.integer(product_index),
    markers$rank
  )
  rownames(markers) <- NULL
  markers
}


.build_product_profiles_qda <- function(res_cd,
                                        dataset,
                                        formul,
                                        firstvar,
                                        lastvar,
                                        proba) {
  attribute_names <- colnames(dataset)[seq.int(firstvar, lastvar)]
  product_variable <- .extract_qda_product_variable(formul)

  adjmean <- if (!is.null(res_cd$adjmean)) {
    as.data.frame(res_cd$adjmean)
  } else {
    data.frame()
  }

  product_names <- rownames(adjmean)
  product_names <- product_names[
    !is.na(product_names) & nzchar(product_names)
  ]

  quanti_names <- if ("quanti" %in% names(res_cd)) {
    names(res_cd$quanti)
  } else {
    character(0)
  }
  quanti_names <- quanti_names[
    !is.na(quanti_names) & nzchar(quanti_names)
  ]

  product_names <- unique(c(product_names, quanti_names))

  if (length(product_names) == 0L) {
    source_products <- unique(as.character(dataset[[product_variable]]))
    source_products <- source_products[
      !is.na(source_products) & nzchar(source_products)
    ]
    product_names <- source_products
  }

  if (length(product_names) == 0L) {
    stop(
      "No products could be identified from the QDA result.",
      call. = FALSE
    )
  }

  products <- stats::setNames(
    vector("list", length(product_names)),
    product_names
  )

  registry_parts <- vector("list", length(product_names))

  for (i in seq_along(product_names)) {
    product_name <- product_names[[i]]

    adjusted_means <- .qda_adjusted_means_for_product(
      adjmean = adjmean,
      product_name = product_name,
      attribute_names = attribute_names
    )

    markers <- .qda_markers_for_product(
      res_cd = res_cd,
      product_name = product_name,
      product_index = i,
      proba = proba
    )

    above <- markers[
      markers$direction == "higher",
      ,
      drop = FALSE
    ]
    below <- markers[
      markers$direction == "lower",
      ,
      drop = FALSE
    ]

    products[[product_name]] <- list(
      product = product_name,
      adjusted_means = adjusted_means,
      retained_markers = markers,
      above_average = above,
      below_average = below,
      metrics = list(
        n_attributes_total = as.integer(length(attribute_names)),
        n_markers_retained = as.integer(nrow(markers)),
        n_above_average = as.integer(nrow(above)),
        n_below_average = as.integer(nrow(below))
      )
    )

    registry_parts[[i]] <- markers
  }

  non_empty <- registry_parts[
    vapply(registry_parts, nrow, integer(1)) > 0L
  ]

  evidence_registry <- if (length(non_empty) == 0L) {
    .empty_qda_marker_table()
  } else {
    do.call(rbind, non_empty)
  }
  rownames(evidence_registry) <- NULL

  out <- list(
    products = products,
    evidence_registry = evidence_registry,
    settings = list(
      formula = paste(formul, collapse = " "),
      product_variable = product_variable,
      firstvar = as.integer(firstvar),
      lastvar = as.integer(lastvar),
      proba = proba
    ),
    metadata = list(
      schema = "NaileR::qda_product_profiles",
      schema_version = "1.0.0",
      n_products = as.integer(length(products)),
      n_attributes = as.integer(length(attribute_names)),
      n_retained_evidence = as.integer(nrow(evidence_registry)),
      evidence_source = "SensoMineR::decat"
    )
  )

  class(out) <- c("nail_qda_product_profiles", "list")
  out
}


.is_product_profiles_qda <- function(x) {
  inherits(x, "nail_qda_product_profiles") &&
    is.list(x) &&
    is.list(x$products) &&
    is.data.frame(x$evidence_registry) &&
    is.list(x$settings) &&
    is.list(x$metadata)
}


.validate_product_profiles_qda <- function(x) {
  if (!.is_product_profiles_qda(x)) {
    stop("Invalid QDA `product_profiles` object.", call. = FALSE)
  }

  product_names <- names(x$products)
  if (length(product_names) == 0L ||
      is.null(product_names) ||
      anyNA(product_names) ||
      any(!nzchar(product_names)) ||
      anyDuplicated(product_names)) {
    stop(
      "`product_profiles$products` must be a non-empty uniquely named list.",
      call. = FALSE
    )
  }

  required_marker_cols <- names(.empty_qda_marker_table())

  for (product_name in product_names) {
    item <- x$products[[product_name]]

    if (!is.list(item) ||
        !is.data.frame(item$adjusted_means) ||
        !is.data.frame(item$retained_markers) ||
        !is.data.frame(item$above_average) ||
        !is.data.frame(item$below_average)) {
      stop(
        paste0(
          "Product '", product_name,
          "' contains an invalid QDA profile."
        ),
        call. = FALSE
      )
    }

    if (length(setdiff(required_marker_cols, names(item$retained_markers))) > 0L) {
      stop(
        paste0(
          "Product '", product_name,
          "' contains an incomplete retained-marker table."
        ),
        call. = FALSE
      )
    }
  }

  if (anyDuplicated(x$evidence_registry$evidence_id)) {
    stop(
      "`product_profiles$evidence_registry$evidence_id` must be unique.",
      call. = FALSE
    )
  }

  invisible(TRUE)
}


# ===========================================================================
# Deprecated compatibility view
# ===========================================================================

.profile_strength_label <- function(vtests) {
  if (length(vtests) == 0L) {
    return("weak")
  }

  med <- stats::median(abs(vtests), na.rm = TRUE)

  if (!is.finite(med)) {
    return("weak")
  }
  if (med >= 5) {
    return("strong")
  }
  if (med >= 3) {
    return("moderate")
  }
  "weak"
}


.build_profile_summary_compat_qda <- function(product_profiles,
                                              drop.negative = FALSE,
                                              top_n = 5L) {
  .validate_product_profiles_qda(product_profiles)

  out <- lapply(product_profiles$products, function(item) {
    above <- utils::head(
      item$above_average$attribute,
      top_n
    )

    below <- if (isTRUE(drop.negative)) {
      character(0)
    } else {
      utils::head(
        item$below_average$attribute,
        top_n
      )
    }

    list(
      above = above,
      below = below,
      n_sig = nrow(item$retained_markers),
      # Compatibility only. This field is deliberately absent from the
      # canonical product_profiles object and will disappear when
      # nail_qda_space() is rebuilt.
      profile_strength = .profile_strength_label(
        item$retained_markers$v_test
      )
    )
  })

  names(out) <- names(product_profiles$products)
  out
}


# ===========================================================================
# Prompt-selection evidence
# ===========================================================================

.select_qda_markers <- function(markers,
                                sample_pct,
                                drop_negative,
                                sample_method = c("stratified", "top")) {
  sample_method <- match.arg(sample_method)

  if (!is.data.frame(markers) || nrow(markers) == 0L) {
    return(.empty_qda_marker_table())
  }

  ordered <- .order_qda_markers(markers)

  eligible <- if (isTRUE(drop_negative)) {
    ordered[
      ordered$direction != "lower",
      ,
      drop = FALSE
    ]
  } else {
    ordered
  }

  n_available <- nrow(eligible)

  if (n_available == 0L || sample_pct <= 0) {
    return(eligible[0, , drop = FALSE])
  }

  n_keep <- if (sample_pct >= 1) {
    n_available
  } else {
    ceiling(n_available * sample_pct)
  }

  n_keep <- min(n_keep, n_available)

  if (n_keep >= n_available) {
    return(eligible)
  }

  if (identical(sample_method, "top")) {
    return(
      eligible[
        seq_len(n_keep),
        ,
        drop = FALSE
      ]
    )
  }

  # With one or two available slots, preserve the statistical backbone only.
  # Exploration becomes useful once at least three markers can be displayed.
  if (n_keep <= 2L) {
    return(
      eligible[
        seq_len(n_keep),
        ,
        drop = FALSE
      ]
    )
  }

  # Anchor + exploration strategy.
  # Around 60% of the available prompt slots are reserved for the strongest
  # retained markers. The remaining slots explore lower-ranked retained
  # evidence without jumping automatically to the tail of the distribution.
  n_anchor <- min(
    n_keep - 1L,
    max(2L, ceiling(0.60 * n_keep))
  )
  n_explore <- n_keep - n_anchor

  anchor_idx <- seq_len(n_anchor)
  remaining_idx <- setdiff(seq_len(n_available), anchor_idx)
  explore_idx <- integer(0)

  # If the statistical backbone contains only one direction and the opposite
  # direction exists, reserve one exploration slot for its strongest retained
  # marker. This adds a potentially important sensory nuance without replacing
  # any anchor evidence.
  if (!isTRUE(drop_negative) && n_explore > 0L) {
    anchor_directions <- unique(as.character(eligible$direction[anchor_idx]))
    available_directions <- intersect(
      c("higher", "lower"),
      unique(as.character(eligible$direction))
    )
    missing_directions <- setdiff(
      available_directions,
      anchor_directions
    )

    if (length(missing_directions) > 0L) {
      opposite_idx <- which(
        eligible$direction %in% missing_directions &
          seq_len(n_available) %in% remaining_idx
      )[1L]

      if (length(opposite_idx) > 0L && !is.na(opposite_idx)) {
        explore_idx <- c(explore_idx, opposite_idx)
      }
    }
  }

  slots_left <- n_explore - length(explore_idx)

  if (slots_left > 0L) {
    exploration_pool <- setdiff(remaining_idx, explore_idx)

    if (length(exploration_pool) <= slots_left) {
      explore_idx <- c(explore_idx, exploration_pool)
    } else {
      # Select internal quantiles of the remaining ranked evidence. Using
      # internal rather than endpoint quantiles avoids automatically selecting
      # the weakest retained marker simply because stratification is requested.
      probs <- seq_len(slots_left) / (slots_left + 1)
      pool_positions <- unique(as.integer(round(
        1 + probs * (length(exploration_pool) - 1)
      )))
      pool_positions <- pmax(1L, pmin(length(exploration_pool), pool_positions))

      # Rounding can occasionally collapse two positions. Complete the set
      # deterministically with the strongest still-unselected pool positions.
      if (length(pool_positions) < slots_left) {
        missing_positions <- setdiff(
          seq_along(exploration_pool),
          pool_positions
        )
        pool_positions <- c(
          pool_positions,
          utils::head(
            missing_positions,
            slots_left - length(pool_positions)
          )
        )
      }

      explore_idx <- c(
        explore_idx,
        exploration_pool[
          sort(unique(pool_positions))[seq_len(slots_left)]
        ]
      )
    }
  }

  selected_idx <- sort(unique(c(anchor_idx, explore_idx)))

  # Defensive completion: preserve exactly n_keep markers if an edge case in
  # index construction ever leaves an empty slot.
  if (length(selected_idx) < n_keep) {
    completion <- setdiff(seq_len(n_available), selected_idx)
    selected_idx <- c(
      selected_idx,
      utils::head(completion, n_keep - length(selected_idx))
    )
  }

  selected_idx <- sort(unique(selected_idx))[seq_len(n_keep)]
  selected <- eligible[selected_idx, , drop = FALSE]
  selected <- .order_qda_markers(selected)
  rownames(selected) <- NULL
  selected
}


.build_interpretation_evidence_qda <- function(product_profiles,
                                               sample_pct = 1,
                                               drop_negative = FALSE,
                                               sample_method = c(
                                                 "stratified",
                                                 "top"
                                               )) {
  sample_method <- match.arg(sample_method)
  .validate_product_profiles_qda(product_profiles)

  product_names <- names(product_profiles$products)
  products <- stats::setNames(
    vector("list", length(product_names)),
    product_names
  )

  selected_ids <- character(0)

  for (product_name in product_names) {
    profile <- product_profiles$products[[product_name]]
    markers <- profile$retained_markers

    selected <- .select_qda_markers(
      markers = markers,
      sample_pct = sample_pct,
      drop_negative = drop_negative,
      sample_method = sample_method
    )

    negative_ids <- markers$evidence_id[
      markers$direction == "lower"
    ]

    n_eligible <- if (isTRUE(drop_negative)) {
      sum(markers$direction != "lower")
    } else {
      nrow(markers)
    }

    status <- if (nrow(markers) == 0L) {
      "no_available_markers"
    } else if (n_eligible == 0L) {
      "no_eligible_markers"
    } else if (nrow(selected) == 0L) {
      "selection_empty"
    } else {
      "ready"
    }

    products[[product_name]] <- list(
      product = product_name,
      status = status,
      selected_markers = selected,
      selected_evidence_ids = selected$evidence_id,
      excluded_negative_evidence_ids = if (isTRUE(drop_negative)) {
        negative_ids
      } else {
        character(0)
      },
      metrics = list(
        n_markers_available = as.integer(nrow(markers)),
        n_markers_eligible = as.integer(n_eligible),
        n_markers_selected = as.integer(nrow(selected)),
        n_negative_available = as.integer(
          sum(markers$direction == "lower")
        ),
        n_negative_excluded_by_policy = as.integer(
          if (isTRUE(drop_negative)) length(negative_ids) else 0L
        )
      )
    )

    selected_ids <- c(
      selected_ids,
      products[[product_name]]$selected_evidence_ids
    )
  }

  registry <- product_profiles$evidence_registry

  selected_registry <- if (length(selected_ids) == 0L) {
    registry[0, , drop = FALSE]
  } else {
    positions <- match(selected_ids, registry$evidence_id)

    if (anyNA(positions)) {
      stop(
        "Internal error: selected QDA evidence is absent from the central registry.",
        call. = FALSE
      )
    }

    registry[positions, , drop = FALSE]
  }

  rownames(selected_registry) <- NULL

  out <- list(
    products = products,
    selected_evidence_registry = selected_registry,
    settings = list(
      sample_pct = sample_pct,
      sample_method = sample_method,
      drop_negative = drop_negative,
      selection_rule = if (identical(sample_method, "top")) {
        paste(
          "Order deterministic retained markers by p.value, absolute v.test,",
          "and attribute name; retain the strongest ceiling(n * sample.pct)",
          "markers after applying the negative-marker policy."
        )
      } else {
        paste(
          "Order deterministic retained markers by p.value, absolute v.test,",
          "and attribute name; retain ceiling(n * sample.pct) markers using",
          "an anchor + exploration strategy. Around 60% of the prompt slots",
          "preserve the strongest retained markers, while the remaining slots",
          "sample lower-ranked retained evidence. If the anchor contains only",
          "one direction, prioritize the strongest opposite-direction marker",
          "as exploratory evidence when available."
        )
      },
      zero_proportion_rule = "A zero proportion selects no marker.",
      full_proportion_rule = "A proportion of one selects every eligible marker."
    ),
    metadata = list(
      schema = "NaileR::qda_interpretation_evidence",
      schema_version = "1.0.0",
      n_products = as.integer(length(products)),
      n_selected_evidence = as.integer(nrow(selected_registry)),
      n_ready_products = as.integer(sum(vapply(
        products,
        function(x) identical(x$status, "ready"),
        logical(1)
      )))
    )
  )

  class(out) <- c("nail_qda_interpretation_evidence", "list")
  out
}


# ===========================================================================
# Semantic-facing factual evidence
# ===========================================================================

.qda_display_label <- function(x) {
  x <- as.character(x)[1L]

  if (length(x) == 0L || is.na(x)) {
    return("<missing>")
  }

  x <- gsub("[._]+", " ", x)
  x <- gsub("\\s+", " ", x)
  trimws(x)
}


.qda_format_number <- function(x, digits = 2L) {
  value <- suppressWarnings(as.numeric(x)[1L])

  if (length(value) == 0L || !is.finite(value)) {
    return("NA")
  }

  formatC(
    value,
    digits = digits,
    format = "f"
  )
}


.qda_format_p <- function(x) {
  value <- suppressWarnings(as.numeric(x)[1L])

  if (length(value) == 0L || !is.finite(value)) {
    return("NA")
  }

  if (value < 0.001) {
    return("<0.001")
  }

  formatC(
    value,
    digits = 3L,
    format = "f"
  )
}


.qda_marker_fact <- function(row) {
  direction_word <- if (identical(row$direction, "higher")) {
    "HIGHER"
  } else if (identical(row$direction, "lower")) {
    "LOWER"
  } else {
    "DIFFERENT"
  }

  paste0(
    'Attribute "', .qda_display_label(row$attribute), '" is ',
    direction_word,
    " than for the average product ",
    "(adjusted mean=", .qda_format_number(row$adjusted_mean),
    "; v.test=", .qda_format_number(row$v_test),
    "; p.value=", .qda_format_p(row$p_value),
    ")."
  )
}


.build_semantic_facing_evidence_qda <- function(interpretation_evidence,
                                                product_knowledge = c(
                                                  "known",
                                                  "unknown"
                                                )) {
  product_knowledge <- match.arg(product_knowledge)

  product_names <- names(interpretation_evidence$products)
  products <- stats::setNames(
    vector("list", length(product_names)),
    product_names
  )

  unit <- if (product_knowledge == "known") {
    "Product"
  } else {
    "Stimulus"
  }

  total_facts <- 0L

  for (product_name in product_names) {
    selected <- interpretation_evidence$products[[product_name]]
    markers <- selected$selected_markers

    if (nrow(markers) == 0L) {
      facts <- data.frame(
        evidence_id = character(0),
        attribute = character(0),
        direction = character(0),
        text = character(0),
        stringsAsFactors = FALSE
      )

      status_text <- switch(
        selected$status,
        no_available_markers = paste(
          "No sensory attribute was retained by the statistical analysis",
          "for this item under the current significance threshold."
        ),
        no_eligible_markers = paste(
          "No sensory attribute remains after applying the current",
          "negative-marker policy."
        ),
        selection_empty = paste(
          "No sensory attribute was selected for the LLM under the",
          "current sampling setting."
        ),
        "No sensory attribute is available for interpretation."
      )

      prompt_text <- paste0(
        "## ", unit, " '", product_name, "'\n\n",
        status_text
      )
    } else {
      fact_text <- vapply(
        seq_len(nrow(markers)),
        function(i) .qda_marker_fact(markers[i, , drop = FALSE]),
        character(1)
      )

      facts <- data.frame(
        evidence_id = markers$evidence_id,
        attribute = markers$attribute,
        direction = markers$direction,
        text = fact_text,
        stringsAsFactors = FALSE
      )

      prompt_text <- paste(
        paste0("## ", unit, " '", product_name, "'"),
        "",
        paste0(
          "R-derived facts retained for this ",
          tolower(unit),
          ":"
        ),
        paste0("- ", fact_text, collapse = "\n"),
        sep = "\n"
      )

      total_facts <- total_facts + nrow(facts)
    }

    products[[product_name]] <- list(
      product = product_name,
      status = selected$status,
      facts = facts,
      prompt_text = normalize_blank_lines(prompt_text),
      selected_evidence_ids = selected$selected_evidence_ids
    )
  }

  out <- list(
    products = products,
    settings = list(
      product_knowledge = product_knowledge
    ),
    metadata = list(
      schema = "NaileR::qda_semantic_facing_evidence",
      schema_version = "1.0.0",
      n_products = as.integer(length(products)),
      n_facts = as.integer(total_facts)
    )
  )

  class(out) <- c("nail_qda_semantic_facing_evidence", "list")
  out
}


# ===========================================================================
# Prompt builders
# ===========================================================================

.build_qda_guide_blocks <- function(proba = 0.05,
                                    sample.pct = 1,
                                    sample.method = c("stratified", "top"),
                                    drop.negative = FALSE,
                                    prompt_style = c("detailed", "compact"),
                                    product_knowledge = c("known", "unknown")) {
  prompt_style <- match.arg(prompt_style)
  product_knowledge <- match.arg(product_knowledge)
  sample.method <- match.arg(sample.method)

  unit <- if (product_knowledge == "known") {
    "product"
  } else {
    "stimulus"
  }

  common <- c(
    "## How to Read the Evidence",
    paste0(
      "The R-derived facts below come from `SensoMineR::decat()` under the ",
      "current significance threshold (p <= ", proba, ")."
    ),
    paste0(
      "For each sensory attribute, the evaluated ", unit,
      " is characterized relative to the average product, defined by the ",
      "average product profile for that attribute across the evaluated set."
    ),
    "The average product is a statistical reference profile, not an actual evaluated product.",
    "Understanding the statistical information:",
    paste0(
      "- HIGHER indicates that the adjusted score of the evaluated ", unit,
      " is significantly higher than that of the average product for the named attribute."
    ),
    paste0(
      "- LOWER indicates that the adjusted score is significantly lower than that of the ",
      "average product for the named attribute."
    ),
    paste0(
      "- The adjusted mean is the model-adjusted sensory score for the evaluated ",
      unit, " and attribute. It is not the deviation from the average product."
    ),
    "- The v.test is a signed standardized test statistic. It provides information about the statistical deviation, not sensory intensity or practical importance.",
    "- The p.value quantifies statistical evidence against the corresponding null hypothesis. It does not measure sensory intensity or substantive importance.",
    paste0(
      "Each comparison concerns one sensory attribute. Do not compare adjusted means across different attributes as though they were measurements of the same sensory characteristic."
    ),
    "Role of the study context:",
    "The introduction provides the scientific and experimental context for interpreting the results.",
    "It may inform the substantive meaning of the sensory characteristics but does not provide additional statistical evidence.",
    "The statistical results establish how the product differs from the average product; the study context helps interpret what those differences mean."
  )

  selection <- c(
    paste0(
      "The LLM receives ", round(100 * sample.pct, 1),
      "% of the eligible retained markers under the current sampling setting."
    ),
    if (identical(sample.method, "stratified") && sample.pct < 1) {
      paste(
        "The retained subset is selected deterministically using an anchor +",
        "exploration strategy: the strongest retained markers form the",
        "statistical backbone, while some lower-ranked retained markers are",
        "included to preserve potentially informative sensory nuances."
      )
    } else if (identical(sample.method, "top") && sample.pct < 1) {
      "The retained subset contains the statistically strongest eligible markers."
    } else {
      "All eligible retained markers are shown, so the sampling method has no effect."
    },
    if (isTRUE(drop.negative)) {
      "Markers LOWER than the average product are intentionally excluded from the LLM evidence."
    } else {
      "Both HIGHER and LOWER retained markers are eligible for the LLM evidence."
    },
    "An undisplayed attribute must not automatically be interpreted as absent, average, unimportant, or non-discriminating: it may be absent because it was not statistically retained or because of the prompt-selection settings.",
    "When the sensory scoring scale is not specified, use relative interpretations rather than unsupported absolute intensity categories.",
    if (isTRUE(drop.negative)) {
      "Only retained HIGHER attributes contribute to the sensory characterization under the current negative-marker policy."
    } else {
      "Both HIGHER and LOWER retained attributes contribute to the sensory characterization of a product."
    }
  )

  epistemic <- c(
    "Build an overall sensory interpretation from the retained attributes together instead of merely listing them.",
    "Identify meaningful relationships among their sensory meanings and propose an overall description supported by the displayed results.",
    "Where relevant, distinguish or connect sensory dimensions such as taste, aroma, and texture.",
    "A higher-level sensory concept is allowed when it is a reasonable synthesis of several displayed attributes; present this broader sensory characterization as an interpretation, not as a directly measured attribute or an additional measured attribute.",
    "Do not force a single unifying concept when the evidence is limited or heterogeneous.",
    "Preserve the direction of every displayed fact: HIGHER means more of the named attribute and LOWER means less of the named attribute relative to the average product.",
    "Do not turn a LOWER attribute into a positive presence of that attribute or infer an opposite attribute that was not measured.",
    "Do not invent sensory notes or unsupported sensory descriptors, change the technical meaning of an attribute, or present a synthesis as a directly measured sensory fact.",
    "Do not equate statistical significance with sensory intensity, sensory importance, or practical importance.",
    "Adapt the specificity of the synthesis to the quantity and coherence of the available information.",
    "Do not claim a multivariate statistical association that was not analyzed.",
    "Do not infer unsupported hedonic, evaluative, marketing, positioning, or causal claims, including unsupported liking, preference, quality, composition, manufacturing, or market-positioning claims, from the displayed evidence.",
    "If you move beyond direct sensory description, make clear that you are offering an interpretation or hypothesis."
  )

  relative_interpretation <- c(
    "Interpret every HIGHER/LOWER result relative to the average product.",
    "Prefer:",
    "- \"more marked by [attribute]\" for HIGHER;",
    "- \"less marked by [attribute]\" for LOWER.",
    "Preserve this relative meaning when building the overall sensory interpretation."
  )

  labels <- if (product_knowledge == "known") {
    paste(
      "Product labels are meaningful identifiers. Preserve them as identifiers.",
      "A descriptive name may supplement the identifier when requested, but it must not replace the original product label."
    )
  } else {
    "Stimulus labels are identifiers only. A short descriptive name may be proposed when the sensory evidence is sufficiently coherent."
  }

  reading <- if (prompt_style == "compact") {
    c(common[-1L], selection)
  } else {
    c(common[-1L], "", selection)
  }

  interpretation <- if (prompt_style == "compact") {
    c(epistemic[1:4], relative_interpretation, labels)
  } else {
    c(epistemic, relative_interpretation, labels)
  }

  list(
    reading = paste(reading, collapse = "\n"),
    interpretation = paste(interpretation, collapse = "\n")
  )
}


build_guide_qda <- function(proba = 0.05,
                            sample.pct = 1,
                            sample.method = c("stratified", "top"),
                            drop.negative = FALSE,
                            prompt_style = c("detailed", "compact"),
                            product_knowledge = c("known", "unknown")) {
  blocks <- .build_qda_guide_blocks(
    proba = proba,
    sample.pct = sample.pct,
    sample.method = sample.method,
    drop.negative = drop.negative,
    prompt_style = prompt_style,
    product_knowledge = product_knowledge
  )

  paste(
    c(
      "## How to Read the Evidence",
      blocks$reading,
      "",
      blocks$interpretation
    ),
    collapse = "\n"
  )
}


build_request_qda <- function(isolate_groups = FALSE,
                              prompt_style = c("detailed", "compact"),
                              product_knowledge = c("known", "unknown")) {
  prompt_style <- match.arg(prompt_style)
  product_knowledge <- match.arg(product_knowledge)

  if (isolate_groups) {
    if (product_knowledge == "known") {
      return(
        paste(
          "Using only the evidence below, interpret this product as a coherent relative sensory profile.",
          "Identify the dominant sensory pattern, distinguish central from secondary evidence, and explain what makes the product distinctive relative to the average product profile.",
          "Preserve the product label as its identifier; a descriptive name, when requested, supplements rather than replaces it.",
          "Do not claim specific pairwise differences that are not shown.",
          sep = "\n"
        )
      )
    }

    return(
      paste(
        "Using only the evidence below, interpret this stimulus as a coherent relative sensory profile.",
        "Identify the dominant sensory pattern, distinguish central from secondary evidence, and explain what makes the stimulus distinctive relative to the average stimulus profile.",
        "If the pattern is sufficiently coherent, you may propose a short descriptive name.",
        "Do not claim specific pairwise differences that are not shown.",
        sep = "\n"
      )
    )
  }

  if (product_knowledge == "known") {
    return(
      paste(
        "Using only the evidence below, interpret the sensory profiles of the products jointly.",
        "For each product, identify the coherent sensory pattern formed by its retained attributes and distinguish central from secondary evidence.",
        "Then identify the main contrasts, similarities, or product families that emerge across the full set.",
        "Preserve the product names and do not invent pairwise differences that are not supported by the evidence.",
        sep = "\n"
      )
    )
  }

  paste(
    "Using only the evidence below, interpret the sensory profiles of the stimuli jointly.",
    "For each stimulus, identify the coherent sensory pattern formed by its retained attributes and distinguish central from secondary evidence.",
    "Then identify the main contrasts, similarities, or families that emerge across the full set.",
    "If useful and sufficiently supported, propose short descriptive names for the stimuli.",
    "Do not invent pairwise differences that are not supported by the evidence.",
    sep = "\n"
  )
}


build_conclusion_qda <- function(isolate_groups = FALSE,
                                 product_knowledge = c("known", "unknown")) {
  product_knowledge <- match.arg(product_knowledge)

  if (isolate_groups) {
    if (product_knowledge == "known") {
      return(
        paste(
          "# Final Summary Task",
          "End with:",
          "1. **Core sensory profile** - one concise synthesis of the product.",
          "2. **Main supporting evidence** - the most important retained sensory facts.",
          "3. **Distinctive interpretation** - what this profile suggests relative to the evaluated set, without replacing the product identifier.",
          "",
          "# Output format",
          "Your output must be **formatted using valid Quarto Markdown**.",
          sep = "\n"
        )
      )
    }

    return(
      paste(
        "# Final Summary Task",
        "End with:",
        "1. **Core sensory profile** - one concise synthesis of the stimulus.",
        "2. **Main supporting evidence** - the most important retained sensory facts.",
        "3. **Descriptive name** - only if the sensory pattern is sufficiently coherent.",
        "",
        "# Output format",
        "Your output must be **formatted using valid Quarto Markdown**.",
        sep = "\n"
      )
    )
  }

  if (product_knowledge == "known") {
    return(
      paste(
        "# Final Summary Task",
        "End with:",
        "1. **A short profile of each product**.",
        "2. **The main contrasts and similarities across products**.",
        "3. **Any coherent product families or sensory poles**, only when supported by the evidence.",
        "",
        "# Output format",
        "Your output must be **formatted using valid Quarto Markdown**.",
        sep = "\n"
      )
    )
  }

  paste(
    "# Final Summary Task",
    "End with:",
    "1. **A short profile of each stimulus**.",
    "2. **The main contrasts and similarities across stimuli**.",
    "3. **Any coherent families or sensory poles**, only when supported by the evidence.",
    "4. **Descriptive names**, when justified by the evidence.",
    "",
    "# Output format",
    "Your output must be **formatted using valid Quarto Markdown**.",
    sep = "\n"
  )
}


.build_qda_local_task <- function(product_name = NULL,
                                  isolate_groups = FALSE,
                                  product_knowledge = c("known", "unknown")) {
  product_knowledge <- match.arg(product_knowledge)

  if (!isTRUE(isolate_groups)) {
    return(
      paste(
        "This prompt addresses the complete evaluated set of products or stimuli shown below.",
        "Interpret the complete set as coherent sensory profiles and compare their supported patterns.",
        "Do not treat this as a single-product prompt.",
        sep = "\n"
      )
    )
  }

  unit <- if (identical(product_knowledge, "known")) {
    "product"
  } else {
    "stimulus"
  }

  identifier_rule <- if (identical(product_knowledge, "known")) {
    paste0("Preserve \"", product_name, "\" as its product identifier.")
  } else {
    paste0(
      "Treat \"", product_name,
      "\" as an identifier; propose a descriptive sensory name only if supported."
    )
  }

  paste(
    paste0(
      "This prompt addresses only ", unit, " \"", product_name,
      "\" as part of the overall analytical request."
    ),
    paste0(
      "Describe its sensory profile relative to the average product using the evidence provided.",
      " Do not describe other products whose evidence is not shown."
    ),
    identifier_rule,
    sep = "\n"
  )
}


.format_qda_output_block <- function(conclusion,
                                     conclusion_supplied = FALSE) {
  if (is.null(conclusion) || !nzchar(trimws(conclusion))) {
    stop("QDA final interpretation requirements cannot be empty.", call. = FALSE)
  }

  body <- conclusion
  if (!isTRUE(conclusion_supplied)) {
    body <- sub("^# Final Summary Task\\s*", "", body)
  }

  body
}


.render_qda_prompt_blocks <- function(blocks,
                                      isolate_groups = FALSE) {
  section_values <- list(
    c("# Introduction", blocks$context),
    if (!is.null(blocks$reading)) {
      c("## How to Read the Evidence", blocks$reading)
    },
    c("# Analytical Question", blocks$question),
    if (!is.null(blocks$interpretation)) {
      c("## Interpretation Rules", blocks$interpretation)
    },
    if (!is.null(blocks$local_task)) {
      c(
        if (isTRUE(isolate_groups)) "# Local Task" else "# Global Task",
        blocks$local_task
      )
    },
    c("# Data", blocks$evidence),
    c("## Reusable NaileR Metadata", blocks$reusable),
    c("# Final Interpretation Requirements", blocks$output)
  )

  section_values <- Filter(
    function(value) !is.null(value) && length(value) > 0L,
    section_values
  )

  normalize_blank_lines(
    paste(
      vapply(
        section_values,
        function(value) paste(value, collapse = "\n\n"),
        character(1)
      ),
      collapse = "\n\n---\n\n"
    )
  )
}


.build_qda_prompt_bundle <- function(semantic_facing_evidence,
                                     context,
                                     question,
                                     interpretation,
                                     reusable,
                                     output,
                                     isolate_groups = FALSE,
                                     product_knowledge = c("known", "unknown"),
                                     default_blocks = c(
                                       "reading",
                                       "interpretation",
                                       "local_task"
                                     )) {
  product_knowledge <- match.arg(product_knowledge)
  default_blocks <- validate_qda_default_blocks(default_blocks)
  product_names <- names(semantic_facing_evidence$products)

  if (length(product_names) == 0L) {
    stop(
      "No QDA product evidence is available for prompt construction.",
      call. = FALSE
    )
  }

  reusable <- sub(
    "^## Reusable product interpretation metadata\\s*",
    "",
    reusable
  )

  make_blocks <- function(product_name, evidence) {
    blocks <- list(
      context = context,
      reading = if ("reading" %in% default_blocks) interpretation$reading else NULL,
      question = question,
      interpretation = if ("interpretation" %in% default_blocks) {
        interpretation$interpretation
      } else {
        NULL
      },
      local_task = if ("local_task" %in% default_blocks) {
        .build_qda_local_task(
          product_name = product_name,
          isolate_groups = isolate_groups,
          product_knowledge = product_knowledge
        )
      } else {
        NULL
      },
      evidence = evidence,
      reusable = reusable,
      output = output
    )

    blocks
  }

  if (!isTRUE(isolate_groups)) {
    evidence <- paste(
      vapply(
        product_names,
        function(product_name) {
          semantic_facing_evidence$products[[product_name]]$prompt_text
        },
        character(1)
      ),
      collapse = "\n\n---\n\n"
    )
    blocks <- list(
      portfolio = make_blocks(
        product_name = NULL,
        evidence = evidence
      )
    )
  } else {
    blocks <- stats::setNames(
      lapply(
        product_names,
        function(product_name) {
          make_blocks(
            product_name = product_name,
            evidence = semantic_facing_evidence$products[[product_name]]$prompt_text
          )
        }
      ),
      product_names
    )
  }

  prompts <- lapply(
    blocks,
    .render_qda_prompt_blocks,
    isolate_groups = isolate_groups
  )

  list(
    blocks = blocks,
    prompts = prompts
  )
}


get_prompt_qda <- function(semantic_facing_evidence,
                           introduction,
                           request,
                           conclusion,
                           isolate_groups = FALSE) {
  product_names <- names(semantic_facing_evidence$products)

  if (length(product_names) == 0L) {
    stop(
      "No QDA product evidence is available for prompt construction.",
      call. = FALSE
    )
  }

  if (!isolate_groups) {
    data_text <- paste(
      vapply(
        product_names,
        function(product_name) {
          semantic_facing_evidence$products[[product_name]]$prompt_text
        },
        character(1)
      ),
      collapse = "\n\n---\n\n"
    )

    return(
      build_standard_prompt(
        introduction = introduction,
        request = request,
        data = data_text,
        conclusion = conclusion
      )
    )
  }

  out <- lapply(
    product_names,
    function(product_name) {
      build_standard_prompt(
        introduction = introduction,
        request = request,
        data = semantic_facing_evidence$products[[product_name]]$prompt_text,
        conclusion = conclusion
      )
    }
  )
  names(out) <- product_names
  out
}


# ===========================================================================
# LLM IO and artifact attachment
# ===========================================================================

.qda_backend_response_text <- function(x) {
  if (is.data.frame(x) &&
      "response" %in% names(x) &&
      nrow(x) > 0L) {
    return(paste(as.character(x$response), collapse = "\n"))
  }

  if (is.list(x) && !is.null(x$response)) {
    return(paste(as.character(x$response), collapse = "\n"))
  }

  if (is.character(x)) {
    return(paste(x, collapse = "\n"))
  }

  stop(
    "The QDA LLM backend result does not contain a readable raw response.",
    call. = FALSE
  )
}


.attach_qda_artifacts <- function(x,
                                  product_profiles,
                                  interpretation_evidence,
                                  semantic_facing_evidence,
                                  prompt_blocks,
                                  prompts,
                                  responses,
                                  decat_result,
                                  profile_summary,
                                  qda_settings,
                                  scope) {
  prompt_list <- if (is.character(prompts) && length(prompts) == 1L) {
    list(portfolio = prompts)
  } else {
    prompts
  }

  if (!is.list(prompt_list)) {
    stop(
      "Internal error: QDA prompts must be a string or a named list.",
      call. = FALSE
    )
  }

  product_interpretations <- .build_product_interpretations_qda(
    responses = responses,
    semantic_facing_evidence = semantic_facing_evidence,
    product_profiles = product_profiles,
    scope = scope
  )

  attr(x, "product_profiles") <- product_profiles
  attr(x, "product_interpretations") <- product_interpretations
  attr(x, "interpretation_evidence") <- interpretation_evidence
  attr(x, "semantic_facing_evidence") <- semantic_facing_evidence
  attr(x, "qda_prompt_blocks") <- prompt_blocks
  attr(x, "qda_prompts") <- prompt_list

  # Temporary compatibility views for the current qda_space implementation.
  attr(x, "profile_summary") <- profile_summary
  attr(x, "decat_result") <- decat_result

  attr(x, "qda_settings") <- qda_settings
  attr(x, "llm_io") <- .new_nail_llm_io(
    stage = "interpretation",
    prompts = prompt_list,
    responses = responses,
    metadata = list(
      analysis = "nail_qda",
      scope = scope,
      provider = qda_settings$provider,
      model = qda_settings$model,
      product_knowledge = qda_settings$product_knowledge
    )
  )

  x
}


# ===========================================================================
# Main
# ===========================================================================

#' Interpret QDA data using evidence-first sensory profiles
#'
#' `nail_qda()` computes statistical sensory profiles using
#' [SensoMineR::decat()], including model-adjusted means and statistically
#' characteristic sensory attributes for each product or stimulus. Retained
#' marker tables include p-values and `v.test` statistics when those fields are
#' returned by `decat()`; `proba` controls the significance threshold used to
#' retain markers.
#'
#' The full R-derived statistical profile is kept separate from the subset
#' shown to the LLM. The `product_profiles` object is the canonical statistical
#' source: it contains adjusted means for every requested sensory attribute and
#' the retained `decat()` markers. `interpretation_evidence` is a deterministic
#' subset of those markers selected for the prompt, while
#' `semantic_facing_evidence` expresses the selected facts in explicit language
#' for the LLM. The model interprets those facts; it does not compute the QDA
#' statistics.
#'
#' `product_profiles` is invariant to `generate`, `isolate.groups`,
#' `sample.pct`, `sample.method`, `drop.negative`, `prompt_style`,
#' `product_knowledge`, and `default_blocks`. These arguments affect the
#' prompt or the interpretation layer, not the statistical calculation.
#'
#' The prompt combines the optional study context (`introduction`), the
#' analytical question (`request`), QDA reading and interpretation rules, the
#' selected sensory evidence, and the final output requirements
#' (`conclusion`). `sample.pct`, `sample.method`, and `drop.negative` control
#' which retained markers are shown to the LLM; they do not rewrite the full
#' statistical profile.
#'
#' @param dataset A data frame containing the product factor, panelist/design
#'   variables, and quantitative sensory attributes.
#' @param formul The analysis-of-variance model evaluated for each sensory
#'   attribute. The first right-hand-side term is treated as the product factor.
#' @param firstvar Index of the first sensory attribute.
#' @param lastvar Index of the last sensory attribute.
#' @param introduction Optional study context included in the LLM prompt. It
#'   helps explain the substantive setting but is not statistical evidence.
#' @param request Optional analytical question included in the LLM prompt.
#' @param conclusion Optional final output-instruction block.
#' @param model Model name for the selected provider. The default is
#'   `"llama3"`.
#' @param provider LLM backend. Currently `"ollama"` or `"gemini"`; when the
#'   argument is omitted, `match.arg()` selects `"ollama"`.
#' @param isolate.groups If `FALSE`, one joint portfolio prompt is built. If
#'   `TRUE`, one independent prompt is built per product/stimulus.
#' @param drop.negative If `TRUE`, sensory markers below the average profile
#'   remain in the canonical evidence but are excluded from the LLM evidence.
#' @param proba Significance threshold passed to [SensoMineR::decat()].
#' @param sample.pct Proportion of eligible retained markers included in the
#'   LLM evidence. Selection is deterministic and does not alter
#'   `product_profiles`.
#' @param sample.method Marker-selection strategy when `sample.pct < 1`.
#'   `"stratified"` (the default selected by `match.arg()`) uses an anchor + exploration strategy: the
#'   strongest retained markers form the statistical backbone and the remaining
#'   slots sample lower-ranked retained evidence. When the anchor contains only
#'   one direction, the strongest opposite-direction marker is prioritized when
#'   available. `"top"` keeps only the statistically strongest eligible markers.
#' @param prompt_style Either `"detailed"` (the default selected by
#'   `match.arg()`) or `"compact"`. The detailed style includes the full QDA
#'   reading and interpretation safeguards, including relative direction,
#'   unsupported-descriptor, and causal-claim guidance. The compact style keeps
#'   the core reading and synthesis rules while shortening the interpretation
#'   instructions. It is an abbreviated prompt style, but its exact token
#'   savings depend on the evidence and surrounding user text.
#' @param product_knowledge Either `"known"` (the default selected by
#'   `match.arg()`) for meaningful product names or `"unknown"` for
#'   identifier-like stimulus labels. With `"known"`, the prompt refers to
#'   products and instructs the LLM to preserve their labels as identifiers.
#'   With `"unknown"`, it refers to stimuli and treats labels as anonymous
#'   identifiers, allowing a descriptive sensory name only when supported by a
#'   coherent pattern. These instructions guide the interpretation but do not
#'   guarantee that a model will avoid hallucinations.
#' @param generate If `FALSE`, build prompt(s) without calling an LLM. If
#'   `TRUE`, call the selected backend.
#' @param default_blocks QDA-specific default semantic blocks to include in
#'   the prompt. Allowed values are `"reading"`, `"interpretation"`, and
#'   `"local_task"`. The default is all three blocks. The evidence and reusable
#'   metadata blocks are always included and are not controlled by this
#'   argument; unknown or duplicated block names produce an error.
#' @param ... Additional provider-specific generation arguments.
#'
#' @return The main return value contains prompts or backend results. Its
#'   structure depends on `generate` and `isolate.groups`:
#'
#'   * with `generate = FALSE` and `isolate.groups = FALSE`, a named list with
#'     one element called `portfolio`, containing the exact joint prompt;
#'   * with `generate = FALSE` and `isolate.groups = TRUE`, a named list with
#'     one exact prompt per product or stimulus;
#'   * with `generate = TRUE` and `isolate.groups = FALSE`, the data frame
#'     returned by the selected backend for the joint call, with the exact
#'     prompt also retained in the backend result;
#'   * with `generate = TRUE` and `isolate.groups = TRUE`, a named list of
#'     backend data frames, one for each product or stimulus.
#'
#'   In addition to the outer return value described above, the same object
#'   carries analytical attributes. They can be inspected with `attr()` or the
#'   public accessors: use [nail_evidence()] for the statistical evidence and
#'   [nail_prompt()] for the exact stored prompt. [nail_response()] retrieves
#'   the raw LLM response after generation; it reports that no response is
#'   available when `generate = FALSE`.
#'
#'   The attached analytical attributes are:
#'
#'   * `product_profiles`: canonical R-derived statistical evidence, including
#'     adjusted means for every sensory attribute and retained `decat()` markers
#'     with their available p-values and `v.test` statistics.
#'   * `product_interpretations`: reusable PASS1 LLM interpretations for each
#'     product/stimulus, linked to the evidence IDs actually shown to the LLM.
#'     When generation has not run, status is \code{"not_generated"}; malformed
#'     reusable blocks are marked \code{"parse_failed"} rather than reconstructed.
#'   * `interpretation_evidence`: deterministic subset selected for the LLM.
#'   * `semantic_facing_evidence`: explicit factual sensory statements.
#'   * `qda_prompt_blocks`: QDA-specific ordered prompt blocks used to render
#'     each exact prompt.
#'   * `llm_io`: exact prompts and raw LLM responses used by
#'     [nail_prompt()] and [nail_response()].
#'   * `decat_result`: original standardized `decat()` result.
#'   * `qda_settings`: execution settings.
#'
#'   `profile_summary` is retained temporarily as a deprecated compatibility
#'   view for older workflows. It is not canonical QDA evidence and is not
#'   used by the rebuilt [nail_qda_space()] implementation. The `llm_io`
#'   attribute always records the exact prompt(s); its response slot is
#'   `NULL` when no LLM generation has occurred.
#'
#' @seealso [SensoMineR::decat()], [nail_qda_interpretation()],
#'   [nail_qda_space()], [nail_evidence()], [nail_prompt()],
#'   [nail_response()]
#'
#' @export
#' @examples
#' data(chocolates, package = "SensoMineR")
#'
#' qda_preview <- nail_qda(
#'   dataset = sensochoc,
#'   formul = "~Product+Panelist",
#'   firstvar = 5,
#'   isolate.groups = TRUE,
#'   sample.pct = 1,
#'   generate = FALSE
#' )
#'
#' qda_product <- names(nail_evidence(qda_preview)$products)[[1L]]
#' nail_evidence(qda_preview, select = qda_product)
#' cat(
#'   substr(
#'     nail_prompt(qda_preview, select = qda_product, print = FALSE),
#'     1,
#'     600
#'   ),
#'   "\n"
#' )
nail_qda <- function(dataset, formul, firstvar,
                     lastvar = length(colnames(dataset)),
                     introduction = NULL,
                     request = NULL,
                     conclusion = NULL,
                     model = "llama3",
                     provider = c("ollama", "gemini"),
                     isolate.groups = FALSE,
                     drop.negative = FALSE,
                     proba = 0.05,
                     sample.pct = 1,
                     sample.method = c("stratified", "top"),
                     prompt_style = c("detailed", "compact"),
                     product_knowledge = c("known", "unknown"),
                     generate = FALSE,
                     default_blocks = c(
                       "reading",
                       "interpretation",
                       "local_task"
                     ),
                     ...) {
  prompt_style <- match.arg(prompt_style)
  product_knowledge <- match.arg(product_knowledge)
  provider <- match.arg(provider)
  sample.method <- match.arg(sample.method)
  default_blocks <- validate_qda_default_blocks(default_blocks)

  conclusion_supplied <- !is.null(conclusion)

  validate_qda_inputs(
    dataset = dataset,
    formul = formul,
    firstvar = firstvar,
    lastvar = lastvar,
    isolate.groups = isolate.groups,
    drop.negative = drop.negative,
    proba = proba,
    generate = generate,
    sample.pct = sample.pct,
    sample.method = sample.method,
    prompt_style = prompt_style,
    product_knowledge = product_knowledge
  )

  if (is.null(introduction)) {
    introduction <- if (product_knowledge == "known") {
      paste(
        "Several products were evaluated by panelists using a common set",
        "of sensory or perceptual attributes."
      )
    } else {
      paste(
        "Several stimuli were evaluated by panelists using a common set",
        "of sensory or perceptual attributes."
      )
    }
  }

  if (is.null(request)) {
    request <- build_request_qda(
      isolate_groups = isolate.groups,
      prompt_style = prompt_style,
      product_knowledge = product_knowledge
    )
  }

  if (is.null(conclusion)) {
    conclusion <- build_conclusion_qda(
      isolate_groups = isolate.groups,
      product_knowledge = product_knowledge
    )
  }

  res_cd <- SensoMineR::decat(
    dataset,
    formul = formul,
    firstvar = firstvar,
    lastvar = lastvar,
    proba = proba,
    graph = FALSE
  )

  if (!"quanti" %in% names(res_cd) && "resT" %in% names(res_cd)) {
    names(res_cd)[names(res_cd) == "resT"] <- "quanti"
  }

  if ("quanti" %in% names(res_cd)) {
    for (i in seq_along(res_cd$quanti)) {
      res_cd$quanti[[i]] <- .standardize_qda_result_names(
        res_cd$quanti[[i]]
      )
    }
  }

  product_profiles <- .build_product_profiles_qda(
    res_cd = res_cd,
    dataset = dataset,
    formul = formul,
    firstvar = firstvar,
    lastvar = lastvar,
    proba = proba
  )

  interpretation_evidence <- .build_interpretation_evidence_qda(
    product_profiles = product_profiles,
    sample_pct = sample.pct,
    drop_negative = drop.negative,
    sample_method = sample.method
  )

  semantic_facing_evidence <- .build_semantic_facing_evidence_qda(
    interpretation_evidence = interpretation_evidence,
    product_knowledge = product_knowledge
  )

  guide_blocks <- .build_qda_guide_blocks(
    proba = proba,
    sample.pct = sample.pct,
    sample.method = sample.method,
    drop.negative = drop.negative,
    prompt_style = prompt_style,
    product_knowledge = product_knowledge
  )

  prompt_blocks <- .build_qda_prompt_bundle(
    semantic_facing_evidence = semantic_facing_evidence,
    context = introduction,
    question = request,
    interpretation = guide_blocks,
    reusable = .build_qda_product_interpretation_instruction(
      product_knowledge = product_knowledge
    ),
    output = .format_qda_output_block(
      conclusion,
      conclusion_supplied = conclusion_supplied
    ),
    isolate_groups = isolate.groups,
    product_knowledge = product_knowledge,
    default_blocks = default_blocks
  )

  prompts <- prompt_blocks$prompts

  profile_summary <- .build_profile_summary_compat_qda(
    product_profiles = product_profiles,
    drop.negative = drop.negative,
    top_n = 5L
  )

  qda_settings <- list(
    formula = paste(formul, collapse = " "),
    product_variable = .extract_qda_product_variable(formul),
    firstvar = as.integer(firstvar),
    lastvar = as.integer(lastvar),
    proba = proba,
    sample_pct = sample.pct,
    sample_method = sample.method,
    drop_negative = drop.negative,
    isolate_groups = isolate.groups,
    prompt_style = prompt_style,
    product_knowledge = product_knowledge,
    default_blocks = default_blocks,
    generate = generate,
    provider = provider,
    model = model
  )

  scope <- if (isolate.groups) {
    "product"
  } else {
    "portfolio"
  }

  if (!generate) {
    return(
      .attach_qda_artifacts(
        x = prompts,
        product_profiles = product_profiles,
        interpretation_evidence = interpretation_evidence,
        semantic_facing_evidence = semantic_facing_evidence,
        prompt_blocks = prompt_blocks$blocks,
        prompts = prompts,
        responses = NULL,
        decat_result = res_cd,
        profile_summary = profile_summary,
        qda_settings = qda_settings,
        scope = scope
      )
    )
  }

  extra_args <- list(...)

  .call_llm <- function(prompt) {
    backend <- .call_llm_base(
      provider = provider,
      model = model,
      prompt = prompt,
      output = "df",
      llm_api_options = extra_args
    )

    backend$prompt <- prompt
    backend
  }

  if (!isolate.groups) {
    result <- .call_llm(prompts)

    return(
      .attach_qda_artifacts(
        x = result,
        product_profiles = product_profiles,
        interpretation_evidence = interpretation_evidence,
        semantic_facing_evidence = semantic_facing_evidence,
        prompt_blocks = prompt_blocks$blocks,
        prompts = prompts,
        responses = list(
          portfolio = .qda_backend_response_text(result)
        ),
        decat_result = res_cd,
        profile_summary = profile_summary,
        qda_settings = qda_settings,
        scope = scope
      )
    )
  }

  result <- lapply(prompts, .call_llm)
  names(result) <- names(prompts)

  raw_responses <- lapply(
    result,
    .qda_backend_response_text
  )
  names(raw_responses) <- names(result)

  .attach_qda_artifacts(
    x = result,
    product_profiles = product_profiles,
    interpretation_evidence = interpretation_evidence,
    semantic_facing_evidence = semantic_facing_evidence,
    prompt_blocks = prompt_blocks$blocks,
    prompts = prompts,
    responses = raw_responses,
    decat_result = res_cd,
    profile_summary = profile_summary,
    qda_settings = qda_settings,
    scope = scope
  )
}
