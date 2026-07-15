#' @importFrom FactoMineR PCA
#' @importFrom utils globalVariables
utils::globalVariables(c(".data"))

# ---------------------------------------------------------------------------
# Constants
# ---------------------------------------------------------------------------

.qda_space_scopes <- c(
  "sensory",
  "formulation",
  "marketing",
  "consumer",
  "innovation",
  "cross_functional"
)

.qda_space_levels <- c("axis", "portfolio", "both")
.qda_space_statuses <- c(
  "expert_interpretation",
  "hypothesis",
  "recommendation",
  "user_context"
)
.qda_space_zero_tolerance <- sqrt(.Machine$double.eps)

# ---------------------------------------------------------------------------
# Small helpers and validation
# ---------------------------------------------------------------------------

.qda_space_nonempty_scalar <- function(x) {
  is.character(x) && length(x) == 1L && !is.na(x) && nzchar(trimws(x))
}

.qda_space_integerish <- function(x, name, minimum = 1L) {
  if (!is.numeric(x) || length(x) != 1L || is.na(x) || !is.finite(x) ||
      x < minimum || abs(x - round(x)) > .Machine$double.eps^0.5) {
    stop(sprintf("`%s` must be a single integer greater than or equal to %d.", name, minimum),
         call. = FALSE)
  }
  as.integer(round(x))
}

.validate_qda_space_inputs <- function(ncp,
                                       scale.unit,
                                       min_inertia_pct,
                                       top_n_var,
                                       top_n_products,
                                       interpretation_level,
                                       expertise_scope,
                                       generate,
                                       request,
                                       introduction,
                                       conclusion) {
  ncp <- .qda_space_integerish(ncp, "ncp")
  top_n_var <- .qda_space_integerish(top_n_var, "top_n_var")
  top_n_products <- .qda_space_integerish(top_n_products, "top_n_products")

  if (!is.logical(scale.unit) || length(scale.unit) != 1L || is.na(scale.unit)) {
    stop("`scale.unit` must be a single non-missing logical value.", call. = FALSE)
  }
  if (!is.numeric(min_inertia_pct) || length(min_inertia_pct) != 1L ||
      is.na(min_inertia_pct) || !is.finite(min_inertia_pct) ||
      min_inertia_pct < 0 || min_inertia_pct > 100) {
    stop("`min_inertia_pct` must be a single numeric value in [0, 100].", call. = FALSE)
  }
  if (!is.logical(generate) || length(generate) != 1L || is.na(generate)) {
    stop("`generate` must be a single non-missing logical value.", call. = FALSE)
  }
  if (!interpretation_level %in% .qda_space_levels) {
    stop(
      sprintf("`interpretation_level` must be one of: %s.",
              paste(.qda_space_levels, collapse = ", ")),
      call. = FALSE
    )
  }
  if (!expertise_scope %in% .qda_space_scopes) {
    stop(
      sprintf("`expertise_scope` must be one of: %s.",
              paste(.qda_space_scopes, collapse = ", ")),
      call. = FALSE
    )
  }

  for (item in c("request", "introduction", "conclusion")) {
    value <- get(item, inherits = FALSE)
    if (!is.null(value) && !.qda_space_nonempty_scalar(value)) {
      stop(sprintf("`%s` must be NULL or a single non-empty character string.", item),
           call. = FALSE)
    }
  }

  list(
    ncp = ncp,
    top_n_var = top_n_var,
    top_n_products = top_n_products
  )
}

.qda_space_validate_context <- function(context) {
  if (is.null(context)) {
    return(stats::setNames(vector("list", length(.qda_spaceprep_context_fields)),
                    .qda_spaceprep_context_fields))
  }
  .validate_qda_spaceprep_context(context)
}

.qda_space_context_present <- function(context, introduction = NULL) {
  .is_qda_spaceprep_context_present(context) || .qda_space_nonempty_scalar(introduction)
}

# ---------------------------------------------------------------------------
# Source extraction and consistency checks
# ---------------------------------------------------------------------------

.qda_space_empty_markers <- function() {
  data.frame(
    evidence_id = character(0),
    product = character(0),
    attribute = character(0),
    direction = character(0),
    coefficient = numeric(0),
    adjusted_mean = numeric(0),
    v_test = numeric(0),
    p_value = numeric(0),
    abs_v_test = numeric(0),
    rank = integer(0),
    stringsAsFactors = FALSE
  )
}

.qda_space_legacy_product_profiles <- function(adjusted_means) {
  products <- rownames(adjusted_means)
  attributes <- colnames(adjusted_means)
  out <- lapply(seq_along(products), function(i) {
    means <- as.numeric(adjusted_means[i, , drop = TRUE])
    names(means) <- attributes
    list(
      product = products[[i]],
      adjusted_means = means,
      retained_markers = .qda_space_empty_markers(),
      above_average = .qda_space_empty_markers(),
      below_average = .qda_space_empty_markers(),
      metrics = list(
        n_retained = 0L,
        n_above_average = 0L,
        n_below_average = 0L,
        max_abs_v_test = NA_real_,
        median_abs_v_test = NA_real_,
        min_p_value = NA_real_
      )
    )
  })
  names(out) <- products
  out
}

.qda_space_validate_adjusted_means <- function(adjusted_means) {
  adjusted_means <- as.data.frame(adjusted_means, stringsAsFactors = FALSE)

  if (nrow(adjusted_means) < 2L) {
    stop("The adjusted-mean table must contain at least 2 products.", call. = FALSE)
  }
  if (ncol(adjusted_means) < 2L) {
    stop("The adjusted-mean table must contain at least 2 sensory attributes.", call. = FALSE)
  }
  if (is.null(rownames(adjusted_means)) || any(!nzchar(rownames(adjusted_means))) ||
      anyDuplicated(rownames(adjusted_means)) > 0L) {
    stop("The adjusted-mean table must have unique non-empty product row names.", call. = FALSE)
  }
  if (is.null(colnames(adjusted_means)) || any(!nzchar(colnames(adjusted_means))) ||
      anyDuplicated(colnames(adjusted_means)) > 0L) {
    stop("The adjusted-mean table must have unique non-empty sensory-attribute names.", call. = FALSE)
  }

  numeric_columns <- vapply(adjusted_means, is.numeric, logical(1))
  if (!all(numeric_columns)) {
    stop(
      sprintf("All adjusted-mean columns must be numeric. Non-numeric column(s): %s.",
              paste(names(adjusted_means)[!numeric_columns], collapse = ", ")),
      call. = FALSE
    )
  }
  values <- as.matrix(adjusted_means)
  if (any(!is.finite(values))) {
    stop("The adjusted-mean table must contain only finite numeric values.", call. = FALSE)
  }

  adjusted_means
}

.qda_space_check_profile_consistency <- function(adjusted_means,
                                                 product_profiles,
                                                 tolerance = 1e-10) {
  .validate_qda_spaceprep_product_profiles(product_profiles)

  products <- rownames(adjusted_means)
  attributes <- colnames(adjusted_means)

  if (!identical(names(product_profiles), products)) {
    stop(
      paste(
        "The product names and order in `decat_result$adjmean` must match",
        "those in `attr(x, 'product_profiles')`."
      ),
      call. = FALSE
    )
  }

  for (product in products) {
    profile <- product_profiles[[product]]
    means <- profile$adjusted_means
    if (!is.numeric(means) || is.null(names(means)) ||
        !identical(names(means), attributes)) {
      stop(
        sprintf(
          "`product_profiles[['%s']]$adjusted_means` must contain all attributes in the same order as `decat_result$adjmean`.",
          product
        ),
        call. = FALSE
      )
    }
    target <- as.numeric(adjusted_means[product, attributes, drop = TRUE])
    if (!isTRUE(all.equal(as.numeric(means), target, tolerance = tolerance,
                          check.attributes = FALSE))) {
      stop(
        sprintf(
          "Adjusted means for product `%s` are inconsistent between `decat_result` and `product_profiles`.",
          product
        ),
        call. = FALSE
      )
    }
  }

  invisible(TRUE)
}

.extract_qda_space_source <- function(x) {
  decat_result <- attr(x, "decat_result", exact = TRUE)
  product_profiles <- attr(x, "product_profiles", exact = TRUE)
  qda_settings <- attr(x, "qda_settings", exact = TRUE)

  if (!is.null(decat_result) || !is.null(product_profiles)) {
    if (is.null(product_profiles)) {
      stop(
        "`x` has QDA attributes but no valid `product_profiles` attribute. Recreate it with the validated `nail_qda()` workflow.",
        call. = FALSE
      )
    }
    if (is.null(decat_result) || !is.list(decat_result) || is.null(decat_result$adjmean)) {
      stop(
        "`x` must contain a `decat_result` attribute with an `adjmean` component.",
        call. = FALSE
      )
    }

    adjusted_means <- .qda_space_validate_adjusted_means(decat_result$adjmean)
    .qda_space_check_profile_consistency(adjusted_means, product_profiles)

    return(list(
      adjusted_means = adjusted_means,
      decat_result = decat_result,
      product_profiles = product_profiles,
      qda_settings = qda_settings,
      source = "nail_qda",
      legacy_input = FALSE
    ))
  }

  if (is.list(x) && !is.null(x$adjmean)) {
    adjusted_means <- .qda_space_validate_adjusted_means(x$adjmean)
    warning(
      paste(
        "Passing a raw `decat()` result to `nail_qda_space()` is deprecated.",
        "Call `nail_qda()` first and pass its result through `x`."
      ),
      call. = FALSE
    )
    return(list(
      adjusted_means = adjusted_means,
      decat_result = x,
      product_profiles = .qda_space_legacy_product_profiles(adjusted_means),
      qda_settings = NULL,
      source = "raw_decat_legacy",
      legacy_input = TRUE
    ))
  }

  stop(
    paste(
      "`x` must be an object returned by `nail_qda()` with",
      "`decat_result` and `product_profiles` attributes."
    ),
    call. = FALSE
  )
}

# ---------------------------------------------------------------------------
# Product-expertise normalization and compatibility
# ---------------------------------------------------------------------------

.qda_space_claim_text <- function(claim) {
  if (is.list(claim) && .qda_space_nonempty_scalar(claim$text)) {
    return(trimws(claim$text))
  }
  NA_character_
}

.extract_product_expertise_object <- function(x) {
  if (is.null(x)) return(NULL)

  candidates <- list(
    if (is.list(x)) x$product_expertise else NULL,
    if (is.list(x) && is.list(x$parsed)) x$parsed$product_expertise else NULL,
    attr(x, "product_expertise", exact = TRUE),
    if (is.list(x) && all(c("portfolio", "products", "metadata") %in% names(x))) x else NULL
  )

  for (candidate in candidates) {
    if (is.list(candidate) && is.list(candidate$products)) {
      return(candidate)
    }
  }
  NULL
}

# Transitional helper retained for the validated step-2 compatibility contract.
# It converts structured product expertise, or historical per-product summaries,
# to the compact legacy view formerly consumed by nail_qda_space().
.extract_llm_profile_summaries <- function(llm_product_summaries) {
  if (is.null(llm_product_summaries)) {
    return(NULL)
  }

  expertise <- .extract_product_expertise_object(llm_product_summaries)
  if (!is.null(expertise)) {
    out <- lapply(names(expertise$products), function(product_name) {
      product <- expertise$products[[product_name]]
      proposed_name <- .qda_space_claim_text(product$proposed_name)
      identity <- .qda_space_claim_text(product$sensory_identity)
      archetype <- .qda_space_claim_text(product$sensory_archetype)
      role <- .qda_space_claim_text(product$differentiation_role)

      summary_parts <- c(
        if (!is.na(proposed_name)) proposed_name else NULL,
        if (!is.na(identity)) identity else NULL
      )
      injectable <- if (length(summary_parts) > 0L) {
        paste(summary_parts, collapse = ": ")
      } else {
        NA_character_
      }

      list(
        injectable_summary = injectable,
        positioning_cues = if (!is.na(role)) role else archetype,
        profile_clarity = NA_character_,
        core_profile = identity,
        above_average_traits = character(0),
        below_average_traits = character(0)
      )
    })
    names(out) <- names(expertise$products)
    return(out)
  }

  if (!is.list(llm_product_summaries)) {
    return(list())
  }

  out <- list()

  for (nm in names(llm_product_summaries)) {
    item <- llm_product_summaries[[nm]]

    parsed <- NULL
    if (is.list(item) && !is.null(item$parsed)) {
      parsed <- item$parsed
    } else if (is.list(item)) {
      has_new_names <- all(c(
        "core_profile",
        "above_average_traits",
        "below_average_traits",
        "positioning_cues",
        "profile_clarity",
        "injectable_summary"
      ) %in% names(item))

      has_legacy_names <- all(c(
        "core_profile",
        "positive_traits",
        "negative_traits",
        "positioning_cues",
        "profile_clarity",
        "injectable_summary"
      ) %in% names(item))

      if (has_new_names || has_legacy_names) {
        parsed <- item
      }
    }

    if (is.null(parsed)) {
      next
    }

    above_traits <- parsed$above_average_traits
    below_traits <- parsed$below_average_traits
    if (is.null(above_traits)) {
      above_traits <- parsed$positive_traits
    }
    if (is.null(below_traits)) {
      below_traits <- parsed$negative_traits
    }
    if (is.null(above_traits)) {
      above_traits <- character(0)
    }
    if (is.null(below_traits)) {
      below_traits <- character(0)
    }

    out[[nm]] <- list(
      injectable_summary = parsed$injectable_summary,
      positioning_cues = parsed$positioning_cues,
      profile_clarity = parsed$profile_clarity,
      core_profile = parsed$core_profile,
      above_average_traits = above_traits,
      below_average_traits = below_traits
    )
  }

  out
}

.qda_space_validate_prior_claims <- function(x,
                                            valid_evidence_ids,
                                            path = "product_expertise") {
  if (!is.list(x)) return(invisible(TRUE))

  claim_fields <- c("text", "status", "evidence_ids", "validation_needed")
  present_claim_fields <- intersect(names(x), claim_fields)
  if (length(present_claim_fields) > 0L) {
    missing_claim_fields <- setdiff(claim_fields, names(x))
    if (length(missing_claim_fields) > 0L) {
      stop(
        sprintf(
          "`%s` is missing required claim field(s): %s.",
          path, paste(missing_claim_fields, collapse = ", ")
        ),
        call. = FALSE
      )
    }
    status <- as.character(x$status)
    if (length(status) != 1L || is.na(status) || !status %in% .qda_space_statuses) {
      stop(
        sprintf("`%s$status` contains an invalid epistemic status.", path),
        call. = FALSE
      )
    }
    ids <- .qda_spaceprep_as_character_vector(
      x$evidence_ids,
      paste0(path, "$evidence_ids")
    )
    if (status == "user_context") {
      if (length(ids) > 0L) {
        stop(
          sprintf("`%s` with status `user_context` must not cite statistical evidence.", path),
          call. = FALSE
        )
      }
    } else {
      if (length(ids) == 0L) {
        stop(
          sprintf("`%s` must cite at least one product-profile evidence ID.", path),
          call. = FALSE
        )
      }
      unknown <- setdiff(ids, valid_evidence_ids)
      if (length(unknown) > 0L) {
        stop(
          sprintf(
            "`%s` cites product-profile evidence absent from the current QDA result: %s.",
            path, paste(unknown, collapse = ", ")
          ),
          call. = FALSE
        )
      }
    }
    if (status %in% c("hypothesis", "recommendation") &&
        !.qda_space_nonempty_scalar(x$validation_needed)) {
      stop(
        sprintf("`%s` requires a non-empty `validation_needed` field.", path),
        call. = FALSE
      )
    }
    return(invisible(TRUE))
  }

  nms <- names(x)
  for (i in seq_along(x)) {
    child <- if (!is.null(nms) && nzchar(nms[[i]])) {
      paste0(path, "$", nms[[i]])
    } else {
      sprintf("%s[[%d]]", path, i)
    }
    .qda_space_validate_prior_claims(x[[i]], valid_evidence_ids, child)
  }
  invisible(TRUE)
}

.qda_space_validate_structured_expertise <- function(expertise,
                                                     valid_evidence_ids) {
  if (!is.list(expertise) || !is.list(expertise$products)) {
    stop("`product_expertise` must contain a `products` list.", call. = FALSE)
  }
  if (length(expertise$products) > 0L &&
      (is.null(names(expertise$products)) || any(!nzchar(names(expertise$products))) ||
       anyDuplicated(names(expertise$products)) > 0L)) {
    stop("`product_expertise$products` must be uniquely named by product identifiers.",
         call. = FALSE)
  }
  for (product in names(expertise$products)) {
    item <- expertise$products[[product]]
    if (!is.list(item)) {
      stop(sprintf("`product_expertise$products$%s` must be a list.", product),
           call. = FALSE)
    }
    if (!is.null(item$product) && !identical(as.character(item$product), product)) {
      stop(
        sprintf("`product_expertise$products$%s$product` does not match its list name.", product),
        call. = FALSE
      )
    }
  }
  .qda_space_validate_prior_claims(expertise, valid_evidence_ids)
  invisible(TRUE)
}

.qda_space_legacy_summary_item <- function(item) {
  parsed <- if (is.list(item) && is.list(item$parsed)) item$parsed else item
  if (!is.list(parsed)) return(NULL)

  fields <- c(
    "injectable_summary", "positioning_cues", "core_profile",
    "above_average_traits", "below_average_traits",
    "positive_traits", "negative_traits"
  )
  if (!any(fields %in% names(parsed))) return(NULL)

  list(
    injectable_summary = parsed$injectable_summary,
    positioning_cues = parsed$positioning_cues,
    core_profile = parsed$core_profile,
    above_average_traits = parsed$above_average_traits %||% parsed$positive_traits,
    below_average_traits = parsed$below_average_traits %||% parsed$negative_traits
  )
}

`%||%` <- function(x, y) if (is.null(x)) y else x

.normalize_qda_space_product_expertise <- function(product_expertise,
                                                   llm_product_summaries,
                                                   profile_summary,
                                                   analyzed_products,
                                                   valid_product_evidence_ids,
                                                   legacy_argument_supplied = FALSE,
                                                   profile_summary_supplied = FALSE) {
  if (!is.null(product_expertise) && !is.null(llm_product_summaries)) {
    stop(
      "Supply only one of `product_expertise` or deprecated `llm_product_summaries`.",
      call. = FALSE
    )
  }

  if (legacy_argument_supplied) {
    warning(
      "`llm_product_summaries` is deprecated; use `product_expertise` instead.",
      call. = FALSE
    )
  }
  if (profile_summary_supplied) {
    warning(
      "`profile_summary` is deprecated in `nail_qda_space()`; product profiles are read from `x`.",
      call. = FALSE
    )
  }

  source_object <- if (!is.null(product_expertise)) product_expertise else llm_product_summaries
  expertise <- .extract_product_expertise_object(source_object)
  legacy <- NULL

  if (!is.null(source_object) && is.null(expertise)) {
    if (!is.list(source_object)) {
      stop("The supplied product expertise is not a supported structured object.", call. = FALSE)
    }
    legacy <- lapply(source_object, .qda_space_legacy_summary_item)
    legacy <- legacy[!vapply(legacy, is.null, logical(1))]
    if (length(legacy) == 0L) {
      stop("The supplied product expertise is not a supported structured object.", call. = FALSE)
    }
  }

  if (!is.null(profile_summary)) {
    if (!is.list(profile_summary)) {
      stop("Deprecated `profile_summary` must be NULL or a named list.", call. = FALSE)
    }
    profile_legacy <- lapply(profile_summary, function(item) {
      if (!is.list(item)) return(NULL)
      above <- as.character(item$above %||% character(0))
      below <- as.character(item$below %||% character(0))
      list(
        injectable_summary = paste0(
          "Above average on ", if (length(above)) paste(above, collapse = ", ") else "none",
          "; below average on ", if (length(below)) paste(below, collapse = ", ") else "none", "."
        ),
        positioning_cues = NULL,
        core_profile = NULL,
        above_average_traits = above,
        below_average_traits = below
      )
    })
    profile_legacy <- profile_legacy[!vapply(profile_legacy, is.null, logical(1))]
    if (length(profile_legacy)) {
      legacy <- c(legacy %||% list(), profile_legacy[setdiff(names(profile_legacy), names(legacy))])
    }
  }

  if (!is.null(expertise)) {
    if (length(expertise$products) > 0L &&
        (is.null(names(expertise$products)) || any(!nzchar(names(expertise$products))))) {
      stop("`product_expertise$products` must be named by product identifiers.", call. = FALSE)
    }
    unknown <- setdiff(names(expertise$products), analyzed_products)
    if (length(unknown) > 0L) {
      warning(
        sprintf(
          "Ignoring product expertise for product(s) absent from the PCA: %s.",
          paste(unknown, collapse = ", ")
        ),
        call. = FALSE
      )
      expertise$products <- expertise$products[setdiff(names(expertise$products), unknown)]
    }
    .qda_space_validate_structured_expertise(
      expertise,
      valid_evidence_ids = valid_product_evidence_ids
    )
  }

  if (!is.null(legacy)) {
    if (is.null(names(legacy)) || any(!nzchar(names(legacy)))) {
      stop("Deprecated product summaries must be named by product identifiers.",
           call. = FALSE)
    }
    unknown <- setdiff(names(legacy), analyzed_products)
    if (length(unknown) > 0L) {
      warning(
        sprintf(
          "Ignoring deprecated product summaries for product(s) absent from the PCA: %s.",
          paste(unknown, collapse = ", ")
        ),
        call. = FALSE
      )
      legacy <- legacy[setdiff(names(legacy), unknown)]
    }
  }

  list(
    product_expertise = expertise,
    legacy_summaries = legacy,
    source = if (!is.null(expertise)) "product_expertise" else if (!is.null(legacy)) "legacy" else "none"
  )
}

# ---------------------------------------------------------------------------
# PCA and mechanical evidence
# ---------------------------------------------------------------------------

.qda_space_extract_matrix <- function(x, component, dimensions, row_names) {
  value <- x[[component]]
  if (is.null(value)) {
    out <- matrix(NA_real_, nrow = length(row_names), ncol = length(dimensions),
                  dimnames = list(row_names, paste0("Dim.", dimensions)))
    return(out)
  }
  value <- as.matrix(value)
  wanted <- paste0("Dim.", dimensions)
  out <- matrix(NA_real_, nrow = length(row_names), ncol = length(dimensions),
                dimnames = list(row_names, wanted))
  common_rows <- intersect(row_names, rownames(value))
  common_cols <- intersect(wanted, colnames(value))
  if (length(common_rows) && length(common_cols)) {
    out[common_rows, common_cols] <- value[common_rows, common_cols, drop = FALSE]
  }
  out
}

.qda_space_rank <- function(values, labels) {
  order_index <- order(-abs(values), labels, na.last = TRUE)
  ranks <- integer(length(values))
  ranks[order_index] <- seq_along(order_index)
  ranks
}

.qda_space_side <- function(values, tolerance = .qda_space_zero_tolerance) {
  out <- rep("neutral", length(values))
  finite <- is.finite(values)
  out[finite & values > tolerance] <- "positive"
  out[finite & values < -tolerance] <- "negative"
  out
}

.qda_space_eigenvalues <- function(pca_result) {
  eig <- as.data.frame(pca_result$eig, stringsAsFactors = FALSE)
  if (ncol(eig) < 3L) {
    stop("The PCA result does not contain a complete eigenvalue table.", call. = FALSE)
  }
  data.frame(
    dimension = seq_len(nrow(eig)),
    eigenvalue = as.numeric(eig[[1L]]),
    inertia_percent = as.numeric(eig[[2L]]),
    cumulative_percent = as.numeric(eig[[3L]]),
    stringsAsFactors = FALSE
  )
}

.qda_space_axis_variable_table <- function(pca_result,
                                          dimension,
                                          tolerance = .qda_space_zero_tolerance) {
  attributes <- rownames(pca_result$var$coord)
  dims <- dimension
  coord <- .qda_space_extract_matrix(pca_result$var, "coord", dims, attributes)[, 1L]
  cor <- .qda_space_extract_matrix(pca_result$var, "cor", dims, attributes)[, 1L]
  contrib <- .qda_space_extract_matrix(pca_result$var, "contrib", dims, attributes)[, 1L]
  cos2 <- .qda_space_extract_matrix(pca_result$var, "cos2", dims, attributes)[, 1L]

  data.frame(
    evidence_id = paste0("Dim", dimension, "::variable::", attributes),
    attribute = attributes,
    coordinate = as.numeric(coord),
    correlation = as.numeric(cor),
    contribution = as.numeric(contrib),
    cos2 = as.numeric(cos2),
    side = .qda_space_side(coord, tolerance),
    rank_by_abs_coordinate = .qda_space_rank(coord, attributes),
    stringsAsFactors = FALSE,
    check.names = FALSE
  )
}

.qda_space_axis_product_table <- function(pca_result,
                                         dimension,
                                         tolerance = .qda_space_zero_tolerance) {
  products <- rownames(pca_result$ind$coord)
  dims <- dimension
  coord <- .qda_space_extract_matrix(pca_result$ind, "coord", dims, products)[, 1L]
  contrib <- .qda_space_extract_matrix(pca_result$ind, "contrib", dims, products)[, 1L]
  cos2 <- .qda_space_extract_matrix(pca_result$ind, "cos2", dims, products)[, 1L]

  data.frame(
    evidence_id = paste0("Dim", dimension, "::product::", products),
    product = products,
    coordinate = as.numeric(coord),
    contribution = as.numeric(contrib),
    cos2 = as.numeric(cos2),
    side = .qda_space_side(coord, tolerance),
    rank_by_abs_coordinate = .qda_space_rank(coord, products),
    stringsAsFactors = FALSE,
    check.names = FALSE
  )
}

.qda_space_select_side <- function(table, side, n, label_column) {
  selected <- table[table$side == side & is.finite(table$coordinate), , drop = FALSE]
  if (nrow(selected) == 0L) return(selected)
  labels <- selected[[label_column]]
  selected <- selected[order(-abs(selected$coordinate), labels), , drop = FALSE]
  utils::head(selected, n)
}

.qda_space_selected_products <- function(selected) {
  unique(c(
    selected$negative_products$product,
    selected$positive_products$product
  ))
}

.qda_space_canonical_pair <- function(a, b) {
  sort(c(as.character(a), as.character(b)), method = "radix")
}

.qda_space_pairwise_distance_table <- function(distance_matrix) {
  products <- rownames(distance_matrix)
  if (length(products) < 2L) {
    return(data.frame(
      evidence_id = character(0),
      product_1 = character(0),
      product_2 = character(0),
      distance = numeric(0),
      stringsAsFactors = FALSE
    ))
  }

  pairs <- utils::combn(products, 2L, simplify = FALSE)
  rows <- lapply(pairs, function(pair) {
    canonical <- .qda_space_canonical_pair(pair[[1L]], pair[[2L]])
    data.frame(
      evidence_id = paste0("geometry::distance::", canonical[[1L]], "::", canonical[[2L]]),
      product_1 = canonical[[1L]],
      product_2 = canonical[[2L]],
      distance = as.numeric(distance_matrix[canonical[[1L]], canonical[[2L]]]),
      stringsAsFactors = FALSE
    )
  })
  out <- do.call(rbind, rows)
  out <- out[order(out$product_1, out$product_2, method = "radix"), , drop = FALSE]
  rownames(out) <- NULL
  out
}

.qda_space_nearest_neighbors <- function(distance_matrix,
                                         tolerance = .qda_space_zero_tolerance) {
  products <- rownames(distance_matrix)
  empty <- data.frame(
    evidence_id = character(0),
    product = character(0),
    neighbor = character(0),
    distance = numeric(0),
    tie_count = integer(0),
    tie_rank = integer(0),
    selected = logical(0),
    stringsAsFactors = FALSE
  )
  if (length(products) < 2L) return(empty)

  rows <- lapply(products, function(product) {
    candidates <- setdiff(products, product)
    distances <- as.numeric(distance_matrix[product, candidates])
    min_distance <- min(distances)
    tied <- candidates[abs(distances - min_distance) <= tolerance]
    tied <- sort(tied, method = "radix")
    data.frame(
      evidence_id = paste0("geometry::nearest_neighbor::", product, "::", tied),
      product = product,
      neighbor = tied,
      distance = rep(min_distance, length(tied)),
      tie_count = rep(length(tied), length(tied)),
      tie_rank = seq_along(tied),
      selected = seq_along(tied) == 1L,
      stringsAsFactors = FALSE
    )
  })
  do.call(rbind, rows)
}

.qda_space_product_geometry <- function(pca_result,
                                       geometry_dimensions,
                                       tolerance = .qda_space_zero_tolerance) {
  products <- rownames(pca_result$ind$coord)
  coordinates <- .qda_space_extract_matrix(
    pca_result$ind, "coord", geometry_dimensions, products
  )
  cos2 <- .qda_space_extract_matrix(
    pca_result$ind, "cos2", geometry_dimensions, products
  )
  contributions <- .qda_space_extract_matrix(
    pca_result$ind, "contrib", geometry_dimensions, products
  )

  if (any(!is.finite(coordinates))) {
    stop("The PCA product coordinates contain missing or non-finite values.", call. = FALSE)
  }

  distance_to_origin <- sqrt(rowSums(coordinates^2))
  distance_to_origin <- data.frame(
    evidence_id = paste0("geometry::distance_to_origin::", products),
    product = products,
    distance = as.numeric(distance_to_origin),
    stringsAsFactors = FALSE
  )

  pairwise <- as.matrix(stats::dist(coordinates, method = "euclidean"))
  if (length(products) == 1L) {
    pairwise <- matrix(0, nrow = 1L, ncol = 1L,
                       dimnames = list(products, products))
  }
  pairwise_table <- .qda_space_pairwise_distance_table(pairwise)
  nearest <- .qda_space_nearest_neighbors(pairwise, tolerance = tolerance)

  list(
    dimensions_used = geometry_dimensions,
    coordinates = coordinates,
    cos2 = cos2,
    contributions = contributions,
    distance_to_origin = distance_to_origin,
    pairwise_distances = pairwise,
    pairwise_distance_table = pairwise_table,
    nearest_neighbors = nearest
  )
}

.qda_space_profile_registry <- function(product_profiles) {
  rows <- list()
  k <- 0L

  for (product in names(product_profiles)) {
    profile <- product_profiles[[product]]
    means <- profile$adjusted_means
    for (attribute in names(means)) {
      k <- k + 1L
      rows[[k]] <- data.frame(
        evidence_id = paste0("product_profile::", product, "::", attribute),
        evidence_type = "product_adjusted_mean",
        dimension = NA_integer_,
        entity = paste(product, attribute, sep = "::"),
        metric = "adjusted_mean",
        value = as.numeric(means[[attribute]]),
        details = "Complete adjusted mean from product_profiles.",
        stringsAsFactors = FALSE
      )
    }

    markers <- profile$retained_markers
    if (is.data.frame(markers) && nrow(markers) > 0L) {
      for (i in seq_len(nrow(markers))) {
        k <- k + 1L
        rows[[k]] <- data.frame(
          evidence_id = as.character(markers$evidence_id[[i]]),
          evidence_type = "product_retained_marker",
          dimension = NA_integer_,
          entity = paste(product, markers$attribute[[i]], sep = "::"),
          metric = "v_test",
          value = as.numeric(markers$v_test[[i]]),
          details = paste0(
            "direction=", markers$direction[[i]],
            "; adjusted_mean=", markers$adjusted_mean[[i]],
            "; p_value=", markers$p_value[[i]]
          ),
          stringsAsFactors = FALSE
        )
      }
    }
  }

  if (!length(rows)) {
    return(data.frame(
      evidence_id = character(0), evidence_type = character(0),
      dimension = integer(0), entity = character(0), metric = character(0),
      value = numeric(0), details = character(0), stringsAsFactors = FALSE
    ))
  }
  do.call(rbind, rows)
}

.qda_space_build_registry <- function(eigenvalues,
                                     axes,
                                     product_geometry,
                                     product_profiles) {
  rows <- list()
  k <- 0L
  add <- function(df) {
    if (is.null(df) || nrow(df) == 0L) return(invisible(NULL))
    for (i in seq_len(nrow(df))) {
      k <<- k + 1L
      rows[[k]] <<- df[i, , drop = FALSE]
    }
    invisible(NULL)
  }

  inertia_rows <- data.frame(
    evidence_id = paste0("Dim", eigenvalues$dimension, "::inertia"),
    evidence_type = "axis_inertia",
    dimension = eigenvalues$dimension,
    entity = paste0("Dim", eigenvalues$dimension),
    metric = "inertia_percent",
    value = eigenvalues$inertia_percent,
    details = paste0("eigenvalue=", eigenvalues$eigenvalue,
                     "; cumulative_percent=", eigenvalues$cumulative_percent),
    stringsAsFactors = FALSE
  )
  add(inertia_rows)

  for (axis_name in names(axes)) {
    axis <- axes[[axis_name]]
    var_rows <- data.frame(
      evidence_id = axis$variables$evidence_id,
      evidence_type = "axis_variable",
      dimension = axis$dimension,
      entity = axis$variables$attribute,
      metric = "coordinate",
      value = axis$variables$coordinate,
      details = paste0(
        "correlation=", axis$variables$correlation,
        "; contribution=", axis$variables$contribution,
        "; cos2=", axis$variables$cos2,
        "; side=", axis$variables$side
      ),
      stringsAsFactors = FALSE
    )
    add(var_rows)

    prod_rows <- data.frame(
      evidence_id = axis$products$evidence_id,
      evidence_type = "axis_product",
      dimension = axis$dimension,
      entity = axis$products$product,
      metric = "coordinate",
      value = axis$products$coordinate,
      details = paste0(
        "contribution=", axis$products$contribution,
        "; cos2=", axis$products$cos2,
        "; side=", axis$products$side
      ),
      stringsAsFactors = FALSE
    )
    add(prod_rows)
  }

  origin <- product_geometry$distance_to_origin
  add(data.frame(
    evidence_id = origin$evidence_id,
    evidence_type = "distance_to_origin",
    dimension = NA_integer_,
    entity = origin$product,
    metric = "distance",
    value = origin$distance,
    details = paste0("dimensions=", paste(product_geometry$dimensions_used, collapse = ",")),
    stringsAsFactors = FALSE
  ))

  pair <- product_geometry$pairwise_distance_table
  add(data.frame(
    evidence_id = pair$evidence_id,
    evidence_type = "pairwise_distance",
    dimension = NA_integer_,
    entity = paste(pair$product_1, pair$product_2, sep = "::"),
    metric = "distance",
    value = pair$distance,
    details = paste0("product_1=", pair$product_1, "; product_2=", pair$product_2),
    stringsAsFactors = FALSE
  ))

  nearest <- product_geometry$nearest_neighbors
  add(data.frame(
    evidence_id = nearest$evidence_id,
    evidence_type = "nearest_neighbor",
    dimension = NA_integer_,
    entity = paste(nearest$product, nearest$neighbor, sep = "::"),
    metric = "distance",
    value = nearest$distance,
    details = paste0(
      "product=", nearest$product,
      "; neighbor=", nearest$neighbor,
      "; tie_count=", nearest$tie_count,
      "; selected=", nearest$selected
    ),
    stringsAsFactors = FALSE
  ))

  add(.qda_space_profile_registry(product_profiles))

  registry <- if (length(rows)) do.call(rbind, rows) else data.frame()
  if (nrow(registry) && anyDuplicated(registry$evidence_id) > 0L) {
    duplicated_ids <- unique(registry$evidence_id[duplicated(registry$evidence_id)])
    stop(
      sprintf("The evidence registry contains duplicate ID(s): %s.",
              paste(duplicated_ids, collapse = ", ")),
      call. = FALSE
    )
  }
  rownames(registry) <- NULL
  registry
}

.build_qda_space_evidence <- function(source,
                                     ncp,
                                     scale.unit,
                                     min_inertia_pct,
                                     top_n_var,
                                     top_n_products,
                                     zero_tolerance = .qda_space_zero_tolerance) {
  adjusted_means <- source$adjusted_means

  if (scale.unit) {
    sds <- vapply(adjusted_means, stats::sd, numeric(1))
    zero_variance <- names(sds)[!is.finite(sds) | sds <= zero_tolerance]
    if (length(zero_variance) > 0L) {
      stop(
        sprintf(
          "`scale.unit = TRUE` cannot be used because the following attribute(s) have zero variance across products: %s.",
          paste(zero_variance, collapse = ", ")
        ),
        call. = FALSE
      )
    }
  }

  centered <- scale(as.matrix(adjusted_means), center = TRUE, scale = FALSE)
  rank_available <- qr(centered, tol = zero_tolerance)$rank
  if (rank_available < 1L) {
    stop("The adjusted-mean table has no non-zero PCA dimension.", call. = FALSE)
  }
  effective_ncp <- min(ncp, rank_available, nrow(adjusted_means) - 1L, ncol(adjusted_means))
  if (effective_ncp < 1L) {
    stop("No PCA dimension can be computed from the adjusted-mean table.", call. = FALSE)
  }

  pca_result <- FactoMineR::PCA(
    adjusted_means,
    scale.unit = scale.unit,
    ncp = effective_ncp,
    graph = FALSE
  )
  eigenvalues <- .qda_space_eigenvalues(pca_result)
  available_dimensions <- seq_len(min(effective_ncp, nrow(eigenvalues)))
  retained_axes <- available_dimensions[
    eigenvalues$inertia_percent[available_dimensions] >= min_inertia_pct
  ]

  geometry_dimensions <- available_dimensions
  product_geometry <- .qda_space_product_geometry(
    pca_result,
    geometry_dimensions = geometry_dimensions,
    tolerance = zero_tolerance
  )

  axes <- lapply(retained_axes, function(dimension) {
    variables <- .qda_space_axis_variable_table(
      pca_result, dimension, tolerance = zero_tolerance
    )
    products <- .qda_space_axis_product_table(
      pca_result, dimension, tolerance = zero_tolerance
    )
    selected <- list(
      negative_variables = .qda_space_select_side(variables, "negative", top_n_var, "attribute"),
      positive_variables = .qda_space_select_side(variables, "positive", top_n_var, "attribute"),
      negative_products = .qda_space_select_side(products, "negative", top_n_products, "product"),
      positive_products = .qda_space_select_side(products, "positive", top_n_products, "product")
    )
    selected_products <- .qda_space_selected_products(selected)

    list(
      dimension = as.integer(dimension),
      inertia_percent = eigenvalues$inertia_percent[dimension],
      variables = variables,
      products = products,
      selected_for_interpretation = selected,
      linked_product_profiles = source$product_profiles[selected_products],
      linked_product_expertise = NULL
    )
  })
  if (length(retained_axes) > 0L) {
    names(axes) <- paste0("Dim", retained_axes)
  } else {
    axes <- list()
  }

  registry <- .qda_space_build_registry(
    eigenvalues = eigenvalues,
    axes = axes,
    product_geometry = product_geometry,
    product_profiles = source$product_profiles
  )

  list(
    adjusted_means = adjusted_means,
    product_profiles = source$product_profiles,
    pca_result = pca_result,
    eigenvalues = eigenvalues,
    retained_axes = as.integer(retained_axes),
    axes = axes,
    product_geometry = product_geometry,
    evidence_registry = registry,
    settings = list(
      ncp_requested = ncp,
      ncp_effective = effective_ncp,
      rank_available = rank_available,
      scale.unit = scale.unit,
      min_inertia_pct = min_inertia_pct,
      top_n_var = top_n_var,
      top_n_products = top_n_products,
      zero_tolerance = zero_tolerance,
      geometry_dimensions = geometry_dimensions,
      geometry_distance_rule = "Euclidean distance on all computed PCA dimensions",
      selection_rule = "Descending absolute coordinate within each non-neutral side; ties resolved by label",
      source = source$source
    )
  )
}

# ---------------------------------------------------------------------------
# Interpretation inputs and prompts
# ---------------------------------------------------------------------------

.qda_space_scope_mission <- function(expertise_scope) {
  switch(
    expertise_scope,
    sensory = paste(
      "Interpret the sensory oppositions and the way products express them.",
      "Remain close to perceptual evidence and representation limits."
    ),
    formulation = paste(
      "Interpret the sensory space for formulation teams.",
      "Propose sensory movement directions, not unobserved recipes or causal mechanisms."
    ),
    marketing = paste(
      "Interpret differentiated sensory territories and communication implications.",
      "Do not infer market success, brand value, or observed consumer demand."
    ),
    consumer = paste(
      "Formulate consumer-preference and research hypotheses grounded in sensory geometry.",
      "Do not invent demographic segments or observed preferences."
    ),
    innovation = paste(
      "Identify potentially underoccupied sensory territories and innovation hypotheses.",
      "Treat opportunities as hypotheses requiring validation."
    ),
    cross_functional = paste(
      "Integrate sensory, formulation, marketing, consumer-research, and innovation perspectives.",
      "Keep statistical evidence primary and label hypotheses and recommendations explicitly."
    )
  )
}

.qda_space_compact_profile <- function(profile) {
  list(
    product = profile$product,
    adjusted_means = as.list(profile$adjusted_means),
    retained_markers = if (nrow(profile$retained_markers)) {
      profile$retained_markers[, c(
        "evidence_id", "attribute", "direction", "adjusted_mean",
        "v_test", "p_value"
      ), drop = FALSE]
    } else {
      profile$retained_markers
    }
  )
}

.qda_space_compact_expertise <- function(normalized,
                                               products,
                                               include_portfolio = TRUE) {
  if (!is.null(normalized$product_expertise)) {
    expertise <- normalized$product_expertise
    return(list(
      source_type = "structured_product_expertise",
      portfolio = if (include_portfolio) expertise$portfolio else NULL,
      products = expertise$products[intersect(products, names(expertise$products))]
    ))
  }
  if (!is.null(normalized$legacy_summaries)) {
    return(list(
      source_type = "deprecated_unvalidated_summary",
      portfolio = NULL,
      products = normalized$legacy_summaries[intersect(products, names(normalized$legacy_summaries))]
    ))
  }
  NULL
}

.qda_space_axis_valid_ids <- function(evidence, axis) {
  axis_obj <- evidence$axes[[paste0("Dim", axis)]]
  selected <- axis_obj$selected_for_interpretation
  products <- .qda_space_selected_products(selected)
  profile_ids <- evidence$evidence_registry$evidence_id[
    evidence$evidence_registry$evidence_type %in% c(
      "product_adjusted_mean", "product_retained_marker"
    ) & vapply(evidence$evidence_registry$entity, function(entity) {
      any(startsWith(entity, paste0(products, "::")))
    }, logical(1))
  ]
  unique(c(
    paste0("Dim", axis, "::inertia"),
    selected$negative_variables$evidence_id,
    selected$positive_variables$evidence_id,
    selected$negative_products$evidence_id,
    selected$positive_products$evidence_id,
    profile_ids
  ))
}

.qda_space_axis_prompt_payload <- function(evidence, axis) {
  axis_obj <- evidence$axes[[paste0("Dim", axis)]]
  list(
    dimension = axis,
    inertia_evidence_id = paste0("Dim", axis, "::inertia"),
    inertia_percent = axis_obj$inertia_percent,
    selected_for_interpretation = axis_obj$selected_for_interpretation
  )
}

.qda_space_portfolio_prompt_payload <- function(evidence) {
  axes <- lapply(evidence$axes, function(axis) {
    list(
      dimension = axis$dimension,
      inertia_percent = axis$inertia_percent,
      variables = axis$variables,
      products = axis$products,
      selected_for_interpretation = axis$selected_for_interpretation
    )
  })
  list(
    eigenvalues = evidence$eigenvalues,
    retained_axes = evidence$retained_axes,
    axes = axes,
    product_geometry = list(
      dimensions_used = evidence$product_geometry$dimensions_used,
      distance_to_origin = evidence$product_geometry$distance_to_origin,
      pairwise_distances = evidence$product_geometry$pairwise_distance_table,
      nearest_neighbors = evidence$product_geometry$nearest_neighbors
    )
  )
}

.qda_space_claim_schema <- function() {
  list(
    text = "string",
    status = paste(.qda_space_statuses, collapse = " | "),
    evidence_ids = list("existing evidence ID"),
    validation_needed = "string or null; mandatory for hypothesis/recommendation"
  )
}

.qda_space_axis_schema <- function(axis) {
  claim <- .qda_space_claim_schema()
  list(
    dimension = as.integer(axis),
    sensory_opposition = claim,
    negative_pole = claim,
    positive_pole = claim,
    representative_products = list(c(list(product = "exact product identifier"), claim)),
    within_pole_nuances = list(claim),
    interpretation_limits = list(claim)
  )
}

.qda_space_portfolio_schema <- function() {
  claim <- .qda_space_claim_schema()
  family <- c(
    list(label = "string", products = list("exact product identifier")),
    claim
  )
  list(
    sensory_architecture = claim,
    major_product_families = list(family),
    proximity_patterns = list(claim),
    differentiation_risks = list(claim),
    underoccupied_territories = list(claim),
    formulation_trajectories = list(claim),
    marketing_implications = list(claim),
    consumer_research_hypotheses = list(claim),
    validation_priorities = list(claim)
  )
}

.qda_space_json <- function(x) {
  jsonlite::toJSON(
    x,
    auto_unbox = TRUE,
    pretty = TRUE,
    na = "null",
    null = "null",
    dataframe = "rows",
    digits = NA
  )
}

.build_qda_space_prompt <- function(role,
                                   geometry,
                                   profiles,
                                   product_expertise,
                                   context,
                                   introduction,
                                   task,
                                   request,
                                   conclusion,
                                   valid_evidence_ids,
                                   schema,
                                   scope_label) {
  context_payload <- list(
    structured_context = context,
    introduction = introduction
  )
  expertise_payload <- product_expertise %||% list(
    source_type = "none",
    note = "No prior product expertise was supplied."
  )

  task_lines <- c(
    .qda_space_scope_mission(scope_label),
    task,
    if (!is.null(request)) paste0("Additional user request: ", request) else NULL,
    if (!is.null(conclusion)) paste0("Additional synthesis instruction: ", conclusion) else NULL
  )

  paste(
    "# 1. ROLE",
    role,
    "",
    "# 2. SPACE GEOMETRY EVIDENCE",
    "The following values were calculated by R and constitute the statistical evidence.",
    .qda_space_json(geometry),
    "",
    "# 3. PRODUCT SENSORY PROFILES",
    "These profiles come from attr(x, 'product_profiles'). They are mechanical evidence, not LLM output.",
    .qda_space_json(profiles),
    "",
    "# 4. OPTIONAL PRODUCT EXPERTISE",
    "This section contains prior interpretations, hypotheses, or recommendations. It is not PCA evidence and must never alter the geometry.",
    .qda_space_json(expertise_payload),
    "",
    "# 5. USER-PROVIDED CONTEXT",
    "This context was supplied by the user and must not be presented as a statistical result.",
    .qda_space_json(context_payload),
    "",
    "# 6. INTERPRETATION TASK",
    paste(task_lines, collapse = "\n"),
    "",
    "# 7. MANDATORY EPISTEMIC RULES",
    paste(
      "Return interpretations only; never recalculate or approximately restate PCA values.",
      "Use only these statuses: expert_interpretation, hypothesis, recommendation, user_context.",
      "Every non-user-context claim must cite at least one evidence ID from the allowed registry below.",
      "Every hypothesis or recommendation must include a non-empty validation_needed field.",
      "A user_context claim must use an empty evidence_ids array and is allowed only when user context was provided.",
      "Do not invent demographic segments, observed preferences, causal formulation mechanisms, market performance, or numerical results.",
      "Low cos2 indicates limited representation on the current dimension and must be reflected in interpretation limits.",
      "The sign of a PCA axis is arbitrary; interpret the opposition between poles rather than assigning value to positive or negative signs.",
      "Do not add unknown JSON fields.",
      sep = "\n"
    ),
    "Allowed evidence IDs:",
    paste(valid_evidence_ids, collapse = "\n"),
    "",
    "# 8. OUTPUT SCHEMA",
    "Return one strict JSON object only, without Markdown fences, comments, or surrounding text.",
    .qda_space_json(schema),
    sep = "\n"
  )
}

.build_qda_space_interpretation_units <- function(evidence,
                                                 normalized_expertise,
                                                 interpretation_level,
                                                 expertise_scope,
                                                 context,
                                                 introduction,
                                                 request,
                                                 conclusion) {
  products <- rownames(evidence$adjusted_means)
  units <- list(axes = list(), portfolio = NULL)

  if (interpretation_level %in% c("axis", "both")) {
    for (axis in evidence$retained_axes) {
      axis_obj <- evidence$axes[[paste0("Dim", axis)]]
      selected_products <- .qda_space_selected_products(
        axis_obj$selected_for_interpretation
      )
      profiles <- lapply(
        axis_obj$linked_product_profiles,
        .qda_space_compact_profile
      )
      valid_ids <- .qda_space_axis_valid_ids(evidence, axis)
      units$axes[[paste0("Dim", axis)]] <- list(
        unit_type = "axis",
        axis = axis,
        products = selected_products,
        valid_evidence_ids = valid_ids,
        prompt = .build_qda_space_prompt(
          role = "You are a senior sensory scientist interpreting one PCA dimension for cross-functional product teams.",
          geometry = .qda_space_axis_prompt_payload(evidence, axis),
          profiles = profiles,
          product_expertise = .qda_space_compact_expertise(
            normalized_expertise, selected_products,
            include_portfolio = FALSE
          ),
          context = context,
          introduction = introduction,
          task = paste0(
            "Interpret Dimension ", axis,
            ". Explain the sensory opposition, both poles, representative products, within-pole nuances, and interpretation limits."
          ),
          request = request,
          conclusion = conclusion,
          valid_evidence_ids = valid_ids,
          schema = .qda_space_axis_schema(axis),
          scope_label = expertise_scope
        )
      )
    }
  }

  if (interpretation_level %in% c("portfolio", "both") &&
      length(evidence$retained_axes) > 0L) {
    profiles <- lapply(
      evidence$product_profiles %||% list(),
      .qda_space_compact_profile
    )
    if (length(profiles) == 0L) {
      profiles <- list()
      # Reconstruct from the profile registry is deliberately avoided; the
      # complete profiles are attached below by the caller.
    }
    valid_ids <- evidence$evidence_registry$evidence_id
    units$portfolio <- list(
      unit_type = "portfolio",
      products = products,
      valid_evidence_ids = valid_ids,
      prompt = .build_qda_space_prompt(
        role = "You are a senior sensory scientist interpreting a complete product space for sensory, formulation, marketing, consumer-research, and innovation teams.",
        geometry = .qda_space_portfolio_prompt_payload(evidence),
        profiles = profiles,
        product_expertise = .qda_space_compact_expertise(
          normalized_expertise, products
        ),
        context = context,
        introduction = introduction,
        task = paste(
          "Interpret the portfolio across all retained dimensions and product distances.",
          "Address sensory architecture, product families, proximity patterns, differentiation risks, underoccupied territories, formulation trajectories, marketing implications, consumer-research hypotheses, and validation priorities."
        ),
        request = request,
        conclusion = conclusion,
        valid_evidence_ids = valid_ids,
        schema = .qda_space_portfolio_schema(),
        scope_label = expertise_scope
      )
    )
  }

  units
}

# ---------------------------------------------------------------------------
# JSON validation
# ---------------------------------------------------------------------------

.qda_space_as_character <- function(x, field) {
  .qda_spaceprep_as_character_vector(x, field)
}

.qda_space_validate_claim <- function(claim,
                                     field,
                                     valid_evidence_ids,
                                     context_present) {
  .qda_spaceprep_validate_claim(
    claim = claim,
    field = field,
    valid_evidence_ids = valid_evidence_ids,
    context_present = context_present
  )
}

.qda_space_validate_claim_list <- function(x,
                                          field,
                                          valid_evidence_ids,
                                          context_present,
                                          required_status = NULL) {
  .qda_spaceprep_validate_claim_list(
    x = x,
    field = field,
    valid_evidence_ids = valid_evidence_ids,
    context_present = context_present,
    required_status = required_status
  )
}

.qda_space_validate_representative_product <- function(item,
                                                       field,
                                                       analyzed_products,
                                                       valid_evidence_ids,
                                                       context_present,
                                                       axis) {
  if (!is.list(item) || is.data.frame(item)) {
    stop(sprintf("`%s` must be an object.", field), call. = FALSE)
  }
  required <- c("product", "text", "status", "evidence_ids", "validation_needed")
  missing <- setdiff(required, names(item))
  unknown <- setdiff(names(item), required)
  if (length(missing)) {
    stop(sprintf("`%s` is missing required field(s): %s.", field,
                 paste(missing, collapse = ", ")), call. = FALSE)
  }
  if (length(unknown)) {
    stop(sprintf("`%s` contains unexpected field(s): %s.", field,
                 paste(unknown, collapse = ", ")), call. = FALSE)
  }
  if (!.qda_space_nonempty_scalar(item$product) || !item$product %in% analyzed_products) {
    stop(sprintf("`%s$product` must identify a product analyzed in the PCA.", field),
         call. = FALSE)
  }
  claim <- .qda_space_validate_claim(
    item[setdiff(names(item), "product")],
    field = field,
    valid_evidence_ids = valid_evidence_ids,
    context_present = context_present
  )
  product <- item$product
  product_prefixes <- c(
    paste0("Dim", axis, "::product::", product),
    paste0("product_profile::", product, "::"),
    paste0(product, "::")
  )
  if (claim$status != "user_context" &&
      !any(vapply(claim$evidence_ids, function(id) {
        any(id == product_prefixes[[1L]] |
              startsWith(id, product_prefixes[[2L]]) |
              startsWith(id, product_prefixes[[3L]]))
      }, logical(1)))) {
    stop(sprintf("`%s` must cite at least one evidence ID for product `%s`.", field, product),
         call. = FALSE)
  }
  c(list(product = product), claim)
}

.validate_qda_space_axis_parsed <- function(parsed,
                                           axis,
                                           analyzed_products,
                                           valid_evidence_ids,
                                           context_present) {
  if (!is.list(parsed) || is.data.frame(parsed)) {
    stop("The axis response must be a JSON object.", call. = FALSE)
  }
  allowed <- c(
    "dimension", "sensory_opposition", "negative_pole", "positive_pole",
    "representative_products", "within_pole_nuances", "interpretation_limits"
  )
  missing <- setdiff(allowed, names(parsed))
  unknown <- setdiff(names(parsed), allowed)
  if (length(missing)) {
    stop(sprintf("The axis response is missing required field(s): %s.",
                 paste(missing, collapse = ", ")), call. = FALSE)
  }
  if (length(unknown)) {
    stop(sprintf("The axis response contains unexpected field(s): %s.",
                 paste(unknown, collapse = ", ")), call. = FALSE)
  }
  if (!is.numeric(parsed$dimension) || length(parsed$dimension) != 1L ||
      is.na(parsed$dimension) || as.integer(parsed$dimension) != axis) {
    stop(sprintf("`dimension` must be exactly %d.", axis), call. = FALSE)
  }

  out <- list(dimension = as.integer(axis))
  for (field in c("sensory_opposition", "negative_pole", "positive_pole")) {
    out[[field]] <- .qda_space_validate_claim(
      parsed[[field]],
      field = field,
      valid_evidence_ids = valid_evidence_ids,
      context_present = context_present
    )
  }

  representatives <- parsed$representative_products
  if (is.null(representatives)) representatives <- list()
  if (!is.list(representatives) || is.data.frame(representatives)) {
    stop("`representative_products` must be a JSON array.", call. = FALSE)
  }
  out$representative_products <- lapply(seq_along(representatives), function(i) {
    .qda_space_validate_representative_product(
      representatives[[i]],
      field = sprintf("representative_products[[%d]]", i),
      analyzed_products = analyzed_products,
      valid_evidence_ids = valid_evidence_ids,
      context_present = context_present,
      axis = axis
    )
  })

  out$within_pole_nuances <- .qda_space_validate_claim_list(
    parsed$within_pole_nuances,
    field = "within_pole_nuances",
    valid_evidence_ids = valid_evidence_ids,
    context_present = context_present
  )
  out$interpretation_limits <- .qda_space_validate_claim_list(
    parsed$interpretation_limits,
    field = "interpretation_limits",
    valid_evidence_ids = valid_evidence_ids,
    context_present = context_present
  )
  out
}

.qda_space_validate_family <- function(item,
                                      field,
                                      analyzed_products,
                                      valid_evidence_ids,
                                      context_present) {
  if (!is.list(item) || is.data.frame(item)) {
    stop(sprintf("`%s` must be an object.", field), call. = FALSE)
  }
  required <- c(
    "label", "products", "text", "status", "evidence_ids", "validation_needed"
  )
  missing <- setdiff(required, names(item))
  unknown <- setdiff(names(item), required)
  if (length(missing)) {
    stop(sprintf("`%s` is missing required field(s): %s.", field,
                 paste(missing, collapse = ", ")), call. = FALSE)
  }
  if (length(unknown)) {
    stop(sprintf("`%s` contains unexpected field(s): %s.", field,
                 paste(unknown, collapse = ", ")), call. = FALSE)
  }
  if (!.qda_space_nonempty_scalar(item$label)) {
    stop(sprintf("`%s$label` must be a non-empty string.", field), call. = FALSE)
  }
  products <- .qda_space_as_character(item$products, paste0(field, "$products"))
  if (length(products) == 0L || any(!products %in% analyzed_products)) {
    stop(sprintf("`%s$products` must contain analyzed product identifiers.", field),
         call. = FALSE)
  }
  claim <- .qda_space_validate_claim(
    item[setdiff(names(item), c("label", "products"))],
    field = field,
    valid_evidence_ids = valid_evidence_ids,
    context_present = context_present
  )
  c(list(label = trimws(item$label), products = unique(products)), claim)
}

.validate_qda_space_portfolio_parsed <- function(parsed,
                                                analyzed_products,
                                                valid_evidence_ids,
                                                context_present) {
  if (!is.list(parsed) || is.data.frame(parsed)) {
    stop("The portfolio response must be a JSON object.", call. = FALSE)
  }
  allowed <- c(
    "sensory_architecture", "major_product_families", "proximity_patterns",
    "differentiation_risks", "underoccupied_territories",
    "formulation_trajectories", "marketing_implications",
    "consumer_research_hypotheses", "validation_priorities"
  )
  missing <- setdiff(allowed, names(parsed))
  unknown <- setdiff(names(parsed), allowed)
  if (length(missing)) {
    stop(sprintf("The portfolio response is missing required field(s): %s.",
                 paste(missing, collapse = ", ")), call. = FALSE)
  }
  if (length(unknown)) {
    stop(sprintf("The portfolio response contains unexpected field(s): %s.",
                 paste(unknown, collapse = ", ")), call. = FALSE)
  }

  out <- list()
  out$sensory_architecture <- .qda_space_validate_claim(
    parsed$sensory_architecture,
    field = "sensory_architecture",
    valid_evidence_ids = valid_evidence_ids,
    context_present = context_present
  )

  families <- parsed$major_product_families
  if (is.null(families)) families <- list()
  if (!is.list(families) || is.data.frame(families)) {
    stop("`major_product_families` must be a JSON array.", call. = FALSE)
  }
  out$major_product_families <- lapply(seq_along(families), function(i) {
    .qda_space_validate_family(
      families[[i]],
      field = sprintf("major_product_families[[%d]]", i),
      analyzed_products = analyzed_products,
      valid_evidence_ids = valid_evidence_ids,
      context_present = context_present
    )
  })

  required_statuses <- c(
    proximity_patterns = NA_character_,
    differentiation_risks = "hypothesis",
    underoccupied_territories = "hypothesis",
    formulation_trajectories = "recommendation",
    marketing_implications = NA_character_,
    consumer_research_hypotheses = "hypothesis",
    validation_priorities = "recommendation"
  )
  for (field in names(required_statuses)) {
    required_status <- required_statuses[[field]]
    if (is.na(required_status)) required_status <- NULL
    out[[field]] <- .qda_space_validate_claim_list(
      parsed[[field]],
      field = field,
      valid_evidence_ids = valid_evidence_ids,
      context_present = context_present,
      required_status = required_status
    )
  }
  out
}

.parse_qda_space_strict_json <- function(text) {
  if (!is.character(text) || length(text) == 0L || anyNA(text)) {
    stop("The LLM response must be a non-missing character string containing one strict JSON object.",
         call. = FALSE)
  }
  text <- trimws(paste(text, collapse = "
"))
  if (!nzchar(text) || !startsWith(text, "{") || !endsWith(text, "}")) {
    stop(
      "The LLM response must contain one strict JSON object with no Markdown fence or surrounding text.",
      call. = FALSE
    )
  }
  jsonlite::fromJSON(text, simplifyDataFrame = FALSE)
}

.qda_space_collect_claim_texts <- function(x) {
  out <- character(0)
  walk <- function(value) {
    if (is.list(value)) {
      if (.qda_space_nonempty_scalar(value$text)) {
        out <<- c(out, trimws(value$text))
      }
      for (item in value) walk(item)
    }
    invisible(NULL)
  }
  walk(x)
  unique(out)
}

.parse_qda_space_response <- function(text,
                                     unit_type,
                                     valid_evidence_ids,
                                     analyzed_products,
                                     context_present,
                                     consumer_context_present,
                                     axis = NULL) {
  tryCatch(
    {
      parsed <- .parse_qda_space_strict_json(text)
      interpretation <- if (identical(unit_type, "axis")) {
        .validate_qda_space_axis_parsed(
          parsed = parsed,
          axis = axis,
          analyzed_products = analyzed_products,
          valid_evidence_ids = valid_evidence_ids,
          context_present = context_present
        )
      } else {
        .validate_qda_space_portfolio_parsed(
          parsed = parsed,
          analyzed_products = analyzed_products,
          valid_evidence_ids = valid_evidence_ids,
          context_present = context_present
        )
      }
      if (!consumer_context_present) {
        claim_texts <- .qda_space_collect_claim_texts(interpretation)
        demographic <- claim_texts[vapply(
          claim_texts,
          .qda_spaceprep_contains_demographic_claim,
          logical(1)
        )]
        if (length(demographic) > 0L) {
          stop(
            paste(
              "The response contains a demographic or observed-frequency consumer claim,",
              "but no explicit `context$consumers` was supplied."
            ),
            call. = FALSE
          )
        }
      }

      list(
        parse_status = "success",
        parse_error = NULL,
        interpretation = interpretation
      )
    },
    error = function(e) {
      list(
        parse_status = "error",
        parse_error = conditionMessage(e),
        interpretation = NULL
      )
    }
  )
}

.as_qda_space_response_text <- function(response) {
  if (is.character(response)) return(paste(response, collapse = "\n"))
  if (is.data.frame(response) && "response" %in% names(response)) {
    return(paste(response$response, collapse = "\n"))
  }
  stop("The LLM backend returned an unsupported response format.", call. = FALSE)
}

# ---------------------------------------------------------------------------
# Public function
# ---------------------------------------------------------------------------

#' Interpret a QDA product space with traceable mechanical evidence
#'
#' @description
#' `nail_qda_space()` constructs a principal component analysis from the
#' adjusted product means produced by [nail_qda()], creates a complete and
#' deterministic `qda_space_evidence` object, and optionally asks a language
#' model to interpret individual axes, the complete product portfolio, or both.
#'
#' The statistical layer is produced exclusively by R. Product expertise from
#' [nail_qda_spaceprep()] is optional and is presented to the language model as
#' a prior interpretive layer; it never changes the PCA, retained axes,
#' coordinates, contributions, cos2 values, distances, nearest neighbors, or
#' mechanical selections.
#'
#' @param x An object returned by [nail_qda()]. It must contain the
#'   `"decat_result"`, `"product_profiles"`, and normally `"qda_settings"`
#'   attributes. Passing a raw `SensoMineR::decat()` result with an `adjmean`
#'   component remains temporarily supported with a deprecation warning, but
#'   such an object does not contain retained product markers.
#' @param product_expertise Optional structured expertise produced by
#'   [nail_qda_spaceprep()]. The function accepts the complete result, its
#'   `product_expertise` component, an attached `"product_expertise"` object,
#'   or the already extracted `list(portfolio, products, metadata)` object.
#'   Products absent from the PCA are ignored with a warning. Missing product
#'   expertise never prevents the mechanical analysis.
#' @param interpretation_level One of `"axis"`, `"portfolio"`, or `"both"`.
#'   `"axis"` builds one interpretation unit per retained PCA dimension;
#'   `"portfolio"` builds one global unit from all retained dimensions and the
#'   product geometry; `"both"` builds both kinds of units. The default is
#'   `"both"`.
#' @param expertise_scope Interpretive perspective. One of `"sensory"`,
#'   `"formulation"`, `"marketing"`, `"consumer"`, `"innovation"`, or
#'   `"cross_functional"`. This argument changes prompts only.
#' @param ncp Positive integer giving the maximum requested number of PCA
#'   dimensions. The effective value is limited by the centered rank of the
#'   adjusted-mean table and is recorded in `qda_space_evidence$settings`.
#' @param scale.unit Logical passed to `FactoMineR::PCA()`. The default is
#'   `FALSE`, preserving the relative dispersions of attributes measured on
#'   comparable scales.
#' @param min_inertia_pct Minimum individual percentage of inertia required for
#'   a dimension to be retained for automatic interpretation.
#' @param top_n_var Maximum number of variables selected on each non-neutral
#'   side of a retained dimension.
#' @param top_n_products Maximum number of products selected on each
#'   non-neutral side of a retained dimension.
#' @param context Optional named product context list with fields `category`,
#'   `products`, `formulation`, `brand`, `market`, `consumers`, `usage`, and
#'   `constraints`. It is clearly separated from statistical evidence.
#' @param introduction Optional free-text study context. It is treated as
#'   user-provided context, not as statistical evidence.
#' @param request Optional additional interpretation request. It supplements
#'   the mandatory task and JSON contract but cannot remove traceability or
#'   epistemic requirements.
#' @param conclusion Optional additional synthesis instruction. The strict JSON
#'   schema remains mandatory.
#' @param model Model name used when `generate = TRUE`.
#' @param provider LLM provider, `"ollama"` or `"gemini"`.
#' @param generate Logical. With `FALSE`, all PCA computations, evidence,
#'   selections, geometry, and prompts are created without an LLM call. With
#'   `TRUE`, each requested unit is generated and parsed as strict JSON.
#' @param profile_summary Deprecated compatibility argument. Product profiles
#'   are now read from `attr(x, "product_profiles")`.
#' @param llm_product_summaries Deprecated compatibility argument. Use
#'   `product_expertise` instead. Supplying both arguments is an error.
#' @param expertise_mode Deprecated compatibility argument. `"sensory"` maps
#'   to `expertise_scope = "sensory"`, `"positioning"` to `"innovation"`, and
#'   `"hybrid"` to `"cross_functional"` when `expertise_scope` is omitted.
#' @param ... Additional provider-specific generation arguments.
#'
#' @details
#' ## Mechanical evidence
#'
#' `qda_space_evidence` contains:
#'
#' - `adjusted_means`: the exact product-by-attribute table used for PCA;
#' - `pca_result`: the complete `FactoMineR::PCA()` result;
#' - `eigenvalues`: dimension, eigenvalue, individual inertia percentage, and
#'   cumulative percentage;
#' - `retained_axes`: dimensions meeting `min_inertia_pct`;
#' - `axes`: complete variable and product tables with coordinates,
#'   correlations where applicable, contributions, cos2, sides, deterministic
#'   ranks, mechanical selections, and linked product profiles;
#' - `product_geometry`: product coordinates, cos2, contributions, distances to
#'   the origin, pairwise Euclidean distances, and deterministically resolved
#'   nearest-neighbor ties;
#' - `evidence_registry`: the central registry of all evidence IDs that an LLM
#'   is allowed to cite;
#' - `settings`: the statistical and mechanical rules used to build the object.
#'
#' Geometry distances use all computed PCA dimensions, not only dimensions that
#' cross the interpretation threshold. This rule is explicit in
#' `settings$geometry_dimensions` and `settings$geometry_distance_rule`.
#'
#' Variables and products are assigned to `"negative"`, `"positive"`, or
#' `"neutral"` using a numerical tolerance. Within each non-neutral side,
#' selection is ordered by descending absolute coordinate, with labels used to
#' resolve exact ties deterministically. Contribution and cos2 remain available
#' so that an interpretation can distinguish axis construction from quality of
#' representation.
#'
#' ## Evidence identifiers
#'
#' Axis and geometry evidence identifiers include forms such as
#' `Dim1::variable::Bitterness`, `Dim1::product::A`,
#' `geometry::distance::A::B`, and
#' `geometry::nearest_neighbor::A::B`. Pairwise distance identifiers use a
#' canonical lexicographic product order. Product-profile marker identifiers
#' from [nail_qda()] retain their exact historical form such as
#' `A::Bitterness`; complete adjusted means additionally receive identifiers
#' such as `product_profile::A::Bitterness`.
#'
#' ## JSON interpretation
#'
#' Prompts always present sources in this order: role, space geometry evidence,
#' product sensory profiles, optional product expertise, user-provided context,
#' interpretation task, mandatory epistemic rules, and output schema. Product
#' expertise is explicitly labelled as an earlier interpretation and never as
#' PCA evidence.
#'
#' Valid statuses are `expert_interpretation`, `hypothesis`, `recommendation`,
#' and `user_context`. Every non-context claim must cite existing evidence IDs.
#' Hypotheses and recommendations require a non-empty `validation_needed` field.
#' Invalid JSON or invalid evidence produces `parse_status = "error"` and an
#' informative `parse_error`; no partial structure is silently invented.
#'
#' ## Invariance
#'
#' At fixed data and statistical parameters, `qda_space_evidence` is independent
#' of `generate`, `request`, `expertise_scope`, `interpretation_level`, provider,
#' model, and optional product expertise. Those arguments may change prompts,
#' generation units, interpretations, and LLM metadata only.
#'
#' @return A structured object with components:
#'
#' - `prompt`: axis prompts and/or a portfolio prompt;
#' - `response`: raw LLM responses, or `NULL` placeholders when not generated;
#' - `parsed`: explicit parsing results for every unit;
#' - `qda_space_evidence`: the complete mechanical evidence object;
#' - `axis_interpretations`: validated axis interpretations when generated;
#' - `portfolio_interpretation`: the validated portfolio interpretation when
#'   generated;
#' - `product_expertise`: the normalized optional prior expertise;
#' - `metadata`: interpretation and provider settings.
#'
#' Compatibility attributes `"qda_space"`, `"qda_space_evidence"`,
#' `"product_expertise"`, and `"profile_summary"` are attached when relevant.
#'
#' @seealso [nail_qda()], [nail_qda_spaceprep()], [FactoMineR::PCA()]
#' @export
#'
#' @examples
#' \dontrun{
#' library(NaileR)
#' library(SensoMineR)
#' data("chocolates", package = "SensoMineR")
#'
#' qda <- nail_qda(
#'   dataset = sensochoc,
#'   formul = "~Product+Panelist",
#'   firstvar = 5,
#'   lastvar = ncol(sensochoc),
#'   generate = FALSE
#' )
#'
#' space <- nail_qda_space(
#'   x = qda,
#'   ncp = 3,
#'   scale.unit = FALSE,
#'   interpretation_level = "both",
#'   generate = FALSE
#' )
#'
#' space$qda_space_evidence$retained_axes
#' space$qda_space_evidence$product_geometry$nearest_neighbors
#' cat(space$prompt$axes[[1]])
#'
#' expertise <- nail_qda_spaceprep(
#'   x = qda,
#'   expertise_scope = "cross_functional",
#'   generate = TRUE
#' )
#'
#' enriched <- nail_qda_space(
#'   x = qda,
#'   product_expertise = expertise,
#'   interpretation_level = "both",
#'   expertise_scope = "cross_functional",
#'   generate = TRUE
#' )
#' }

nail_qda_space <- function(x,
                           product_expertise = NULL,
                           interpretation_level = c("both", "axis", "portfolio"),
                           expertise_scope = c(
                             "cross_functional", "sensory", "formulation",
                             "marketing", "consumer", "innovation"
                           ),
                           ncp = 3,
                           scale.unit = FALSE,
                           min_inertia_pct = 10,
                           top_n_var = 5,
                           top_n_products = 2,
                           context = NULL,
                           introduction = NULL,
                           request = NULL,
                           conclusion = NULL,
                           model = "llama3",
                           provider = c("ollama", "gemini"),
                           generate = FALSE,
                           profile_summary = NULL,
                           llm_product_summaries = NULL,
                           expertise_mode = NULL,
                           ...) {
  expertise_scope_missing <- missing(expertise_scope)
  interpretation_level <- match.arg(interpretation_level)
  provider <- match.arg(provider)

  if (!is.null(expertise_mode)) {
    expertise_mode <- match.arg(expertise_mode, c("sensory", "positioning", "hybrid"))
    warning(
      "`expertise_mode` is deprecated; use `expertise_scope` instead.",
      call. = FALSE
    )
    if (expertise_scope_missing) {
      expertise_scope <- switch(
        expertise_mode,
        sensory = "sensory",
        positioning = "innovation",
        hybrid = "cross_functional"
      )
    }
  }
  expertise_scope <- match.arg(expertise_scope)

  validated <- .validate_qda_space_inputs(
    ncp = ncp,
    scale.unit = scale.unit,
    min_inertia_pct = min_inertia_pct,
    top_n_var = top_n_var,
    top_n_products = top_n_products,
    interpretation_level = interpretation_level,
    expertise_scope = expertise_scope,
    generate = generate,
    request = request,
    introduction = introduction,
    conclusion = conclusion
  )
  ncp <- validated$ncp
  top_n_var <- validated$top_n_var
  top_n_products <- validated$top_n_products
  context <- .qda_space_validate_context(context)

  source <- .extract_qda_space_source(x)
  mechanical <- .build_qda_space_evidence(
    source = source,
    ncp = ncp,
    scale.unit = scale.unit,
    min_inertia_pct = min_inertia_pct,
    top_n_var = top_n_var,
    top_n_products = top_n_products
  )
  normalized_expertise <- .normalize_qda_space_product_expertise(
    product_expertise = product_expertise,
    llm_product_summaries = llm_product_summaries,
    profile_summary = profile_summary,
    analyzed_products = rownames(mechanical$adjusted_means),
    valid_product_evidence_ids = mechanical$evidence_registry$evidence_id[
      mechanical$evidence_registry$evidence_type %in% c(
        "product_adjusted_mean", "product_retained_marker"
      )
    ],
    legacy_argument_supplied = !missing(llm_product_summaries),
    profile_summary_supplied = !missing(profile_summary)
  )

  units <- .build_qda_space_interpretation_units(
    evidence = mechanical,
    normalized_expertise = normalized_expertise,
    interpretation_level = interpretation_level,
    expertise_scope = expertise_scope,
    context = context,
    introduction = introduction,
    request = request,
    conclusion = conclusion
  )

  context_present <- .qda_space_context_present(context, introduction)
  consumer_context_present <- .is_qda_spaceprep_context_present(
    list(consumers = context$consumers)
  )
  prompts <- list(
    axes = lapply(units$axes, `[[`, "prompt"),
    portfolio = if (!is.null(units$portfolio)) units$portfolio$prompt else NULL
  )

  not_generated <- function(unit) {
    list(
      parse_status = "not_generated",
      parse_error = NULL,
      interpretation = NULL
    )
  }

  responses <- list(
    axes = stats::setNames(vector("list", length(units$axes)), names(units$axes)),
    portfolio = NULL
  )
  parsed <- list(
    axes = lapply(units$axes, not_generated),
    portfolio = if (!is.null(units$portfolio)) not_generated(units$portfolio) else NULL
  )

  if (generate) {
    llm_api_options <- list(...)
    generate_unit <- function(unit) {
      raw <- .call_llm_base(
        provider = provider,
        model = model,
        prompt = unit$prompt,
        output = "text",
        llm_api_options = llm_api_options
      )
      text <- .as_qda_space_response_text(raw)
      list(
        response = raw,
        parsed = .parse_qda_space_response(
          text = text,
          unit_type = unit$unit_type,
          valid_evidence_ids = unit$valid_evidence_ids,
          analyzed_products = rownames(mechanical$adjusted_means),
          context_present = context_present,
          consumer_context_present = consumer_context_present,
          axis = unit$axis %||% NULL
        )
      )
    }

    if (length(units$axes)) {
      generated_axes <- lapply(units$axes, generate_unit)
      responses$axes <- lapply(generated_axes, `[[`, "response")
      parsed$axes <- lapply(generated_axes, `[[`, "parsed")
    }
    if (!is.null(units$portfolio)) {
      generated_portfolio <- generate_unit(units$portfolio)
      responses$portfolio <- generated_portfolio$response
      parsed$portfolio <- generated_portfolio$parsed
    }
  }

  axis_interpretations <- if (interpretation_level %in% c("axis", "both")) {
    lapply(parsed$axes, function(item) item$interpretation)
  } else {
    NULL
  }
  portfolio_interpretation <- if (!is.null(parsed$portfolio)) {
    parsed$portfolio$interpretation
  } else {
    NULL
  }

  aggregate_status <- c(
    vapply(parsed$axes, `[[`, character(1), "parse_status"),
    if (!is.null(parsed$portfolio)) parsed$portfolio$parse_status else character(0)
  )
  parsed$parse_status <- if (length(aggregate_status) == 0L) {
    "no_units"
  } else if (all(aggregate_status == "not_generated")) {
    "not_generated"
  } else if (all(aggregate_status == "success")) {
    "success"
  } else if (any(aggregate_status == "error")) {
    "error"
  } else {
    "partial"
  }

  metadata <- list(
    interpretation_level = interpretation_level,
    expertise_scope = expertise_scope,
    provider = provider,
    model = model,
    generate = generate,
    context = context,
    introduction = introduction,
    request = request,
    conclusion = conclusion,
    product_expertise_source = normalized_expertise$source,
    qda_settings = source$qda_settings,
    legacy_input = source$legacy_input
  )

  output <- list(
    prompt = prompts,
    response = responses,
    parsed = parsed,
    qda_space_evidence = mechanical,
    axis_interpretations = axis_interpretations,
    portfolio_interpretation = portfolio_interpretation,
    product_expertise = normalized_expertise$product_expertise,
    interpretation_inputs = list(
      axis_products = lapply(units$axes, `[[`, "products"),
      axis_product_expertise = lapply(units$axes, function(unit) {
        .qda_space_compact_expertise(
          normalized_expertise, unit$products,
          include_portfolio = FALSE
        )
      }),
      portfolio_products = if (!is.null(units$portfolio)) units$portfolio$products else NULL,
      portfolio_product_expertise = if (!is.null(units$portfolio)) {
        .qda_space_compact_expertise(normalized_expertise, units$portfolio$products)
      } else {
        NULL
      },
      product_expertise_source = normalized_expertise$source
    ),
    metadata = metadata
  )
  class(output) <- c("nail_qda_space", "list")

  compatibility_space <- list(
    pca_result = mechanical$pca_result,
    adjmean = mechanical$adjusted_means,
    eig = data.frame(
      eigenvalue = mechanical$eigenvalues$eigenvalue,
      percent = mechanical$eigenvalues$inertia_percent,
      cumulative_percent = mechanical$eigenvalues$cumulative_percent,
      stringsAsFactors = FALSE
    ),
    retained_axes = mechanical$retained_axes,
    scale.unit = mechanical$settings$scale.unit,
    min_inertia_pct = mechanical$settings$min_inertia_pct
  )
  attr(output, "qda_space") <- compatibility_space
  attr(output, "qda_space_evidence") <- mechanical
  attr(output, "product_expertise") <- normalized_expertise$product_expertise
  attr(output, "profile_summary") <- attr(x, "profile_summary", exact = TRUE)
  attr(output, "llm_profile_summaries") <- normalized_expertise$legacy_summaries
  output
}
