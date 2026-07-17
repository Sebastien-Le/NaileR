#' @importFrom FactoMineR catdes

# ---------------------------------------------------------------------------
# Input validation and extraction
# ---------------------------------------------------------------------------

.validate_catdes_prep_core_inputs <- function(x = NULL,
                                               dataset = NULL,
                                               num.var = NULL,
                                               exclude = NULL,
                                               proba = 0.05,
                                               row.w = NULL) {
  if (is.null(x) == is.null(dataset)) {
    stop("Provide exactly one of `x` or `dataset`.", call. = FALSE)
  }

  if (!is.null(dataset)) {
    if (!is.data.frame(dataset)) {
      stop("`dataset` must be a data frame.", call. = FALSE)
    }
    if (ncol(dataset) < 2L) {
      stop("`dataset` must contain at least two columns.", call. = FALSE)
    }
    if (is.null(num.var) || !is.numeric(num.var) || length(num.var) != 1L ||
        is.na(num.var) || !is.finite(num.var) || num.var != floor(num.var) ||
        num.var < 1L || num.var > ncol(dataset)) {
      stop(
        "When `dataset` is supplied, `num.var` must be one valid integer column index.",
        call. = FALSE
      )
    }
  }

  if (!is.null(x)) {
    if (!is.null(exclude)) {
      stop(
        "`exclude` can only be used when `dataset` is supplied.",
        call. = FALSE
      )
    }
    if (!is.null(row.w)) {
      stop(
        "`row.w` can only be used when `dataset` is supplied.",
        call. = FALSE
      )
    }
  }

  if (!is.null(exclude) && !(is.numeric(exclude) || is.character(exclude))) {
    stop(
      "`exclude` must be NULL, column indices, or column names.",
      call. = FALSE
    )
  }

  if (!is.numeric(proba) || length(proba) != 1L || is.na(proba) ||
      !is.finite(proba) || proba <= 0 || proba > 1) {
    stop("`proba` must be one numeric value in ]0, 1].", call. = FALSE)
  }

  if (!is.null(row.w)) {
    if (!is.numeric(row.w) || length(row.w) != nrow(dataset) ||
        anyNA(row.w) || any(!is.finite(row.w)) || any(row.w < 0) ||
        sum(row.w) <= 0) {
      stop(
        paste(
          "`row.w` must be a non-negative finite numeric vector",
          "of length `nrow(dataset)` with a positive sum."
        ),
        call. = FALSE
      )
    }
  }

  invisible(TRUE)
}

.resolve_exclude_catdesprep <- function(dataset, exclude = NULL) {
  if (is.null(exclude) || length(exclude) == 0L) {
    return(integer(0))
  }

  if (is.numeric(exclude)) {
    if (anyNA(exclude) || any(!is.finite(exclude)) ||
        any(exclude != floor(exclude)) || any(exclude < 1L) ||
        any(exclude > ncol(dataset))) {
      stop(
        "Numeric `exclude` values must be valid integer column indices.",
        call. = FALSE
      )
    }
    return(sort(unique(as.integer(exclude))))
  }

  missing_names <- setdiff(exclude, colnames(dataset))
  if (length(missing_names) > 0L) {
    stop(
      paste0(
        "Unknown column name(s) in `exclude`: ",
        paste(missing_names, collapse = ", "),
        "."
      ),
      call. = FALSE
    )
  }

  sort(unique(which(colnames(dataset) %in% exclude)))
}

.prepare_dataset_catdesprep <- function(dataset, num.var, exclude = NULL) {
  exclude_idx <- .resolve_exclude_catdesprep(dataset, exclude)

  if (num.var %in% exclude_idx) {
    stop(
      "The grouping variable selected by `num.var` cannot be excluded.",
      call. = FALSE
    )
  }

  keep_idx <- setdiff(seq_len(ncol(dataset)), exclude_idx)
  if (length(keep_idx) < 2L) {
    stop(
      paste(
        "After applying `exclude`, at least the grouping variable",
        "and one descriptor must remain."
      ),
      call. = FALSE
    )
  }

  prepared <- dataset[, keep_idx, drop = FALSE]
  new_num_var <- match(num.var, keep_idx)
  character_columns <- vapply(prepared, is.character, logical(1))
  prepared[character_columns] <- lapply(
    prepared[character_columns],
    function(z) factor(z)
  )

  if (!is.factor(prepared[[new_num_var]])) {
    prepared[[new_num_var]] <- factor(prepared[[new_num_var]])
  } else {
    prepared[[new_num_var]] <- droplevels(prepared[[new_num_var]])
  }

  observed_groups <- prepared[[new_num_var]][!is.na(prepared[[new_num_var]])]
  if (length(unique(observed_groups)) < 2L) {
    stop(
      "The grouping variable must contain at least two observed groups.",
      call. = FALSE
    )
  }

  list(
    dataset = prepared,
    num.var = new_num_var,
    group_names = levels(droplevels(prepared[[new_num_var]])),
    metadata = list(
      source = "dataset",
      original_group_index = as.integer(num.var),
      prepared_group_index = as.integer(new_num_var),
      group_variable = colnames(dataset)[num.var],
      excluded_indices = exclude_idx,
      excluded_columns = colnames(dataset)[exclude_idx],
      retained_indices = keep_idx,
      retained_columns = colnames(dataset)[keep_idx],
      character_columns_converted_to_factor = colnames(prepared)[character_columns]
    )
  )
}

.looks_like_catdes_result <- function(x) {
  is.list(x) && any(c("category", "quanti") %in% names(x))
}

.canonicalize_catdes_result_catdesprep <- function(catdes_result) {
  if (!is.null(catdes_result$call) &&
      !is.null(catdes_result$call$num.var)) {
    catdes_result$call$num.var <- as.integer(catdes_result$call$num.var)
  }

  catdes_result
}

.extract_catdes_input_catdesprep <- function(x = NULL,
                                             dataset = NULL,
                                             num.var = NULL,
                                             exclude = NULL,
                                             proba = 0.05,
                                             row.w = NULL) {
  if (!is.null(x)) {
    if (inherits(x, "statistical_profiles") &&
        is.list(x$groups) && is.data.frame(x$evidence_registry)) {
      return(list(already_prepared = x))
    }

    catdes_result <- attr(x, "catdes_result", exact = TRUE)

    if (is.null(catdes_result) && is.list(x) &&
        "catdes_result" %in% names(x) &&
        .looks_like_catdes_result(x$catdes_result)) {
      catdes_result <- x$catdes_result
    }

    if (is.null(catdes_result) && .looks_like_catdes_result(x)) {
      catdes_result <- x
    }

    if (is.null(catdes_result)) {
      stop(
        paste(
          "`x` must be a raw `FactoMineR::catdes()` result, an object",
          "returned by `nail_catdes()`, or an existing `statistical_profiles` object."
        ),
        call. = FALSE
      )
    }

    group_names <- unique(c(
      if (is.list(catdes_result$quanti)) names(catdes_result$quanti) else NULL,
      if (is.list(catdes_result$category)) names(catdes_result$category) else NULL
    ))

    return(list(
      catdes_result = catdes_result,
      group_names = group_names,
      input_metadata = list(
        source = "x",
        proba_applied_by_function = FALSE,
        declared_proba = proba
      )
    ))
  }

  warning(
    paste(
      "The `dataset`/`num.var` interface of `nail_catdes_prep()` is deprecated.",
      "Compute `FactoMineR::catdes()` or call `nail_catdes()` first, then pass the result through `x`."
    ),
    call. = FALSE
  )

  prepared <- .prepare_dataset_catdesprep(
    dataset = dataset,
    num.var = num.var,
    exclude = exclude
  )

  catdes_result <- FactoMineR::catdes(
    prepared$dataset,
    num.var = prepared$num.var,
    proba = proba,
    row.w = row.w
  )

  prepared$metadata$proba_applied_by_function <- TRUE
  prepared$metadata$declared_proba <- proba

  list(
    catdes_result = catdes_result,
    group_names = prepared$group_names,
    input_metadata = prepared$metadata
  )
}

# ---------------------------------------------------------------------------
# Generic extraction helpers
# ---------------------------------------------------------------------------

.normalize_column_key_catdesprep <- function(x) {
  x <- tolower(as.character(x))
  x[is.na(x)] <- ""
  x <- gsub("[\u00e0\u00e1\u00e2\u00e3\u00e4\u00e5]", "a", x)
  x <- gsub("[\u00e7]", "c", x)
  x <- gsub("[\u00e8\u00e9\u00ea\u00eb]", "e", x)
  x <- gsub("[\u00ec\u00ed\u00ee\u00ef]", "i", x)
  x <- gsub("[\u00f1]", "n", x)
  x <- gsub("[\u00f2\u00f3\u00f4\u00f5\u00f6]", "o", x)
  x <- gsub("[\u00f9\u00fa\u00fb\u00fc]", "u", x)
  x <- gsub("[\u00fd\u00ff]", "y", x)
  gsub("[^a-z0-9]+", "", x)
}

.find_column_catdesprep <- function(df, candidates) {
  if (is.null(df) || ncol(df) == 0L) {
    return(NULL)
  }

  keys <- .normalize_column_key_catdesprep(colnames(df))
  candidate_keys <- .normalize_column_key_catdesprep(candidates)
  hit <- match(candidate_keys, keys, nomatch = 0L)
  hit <- hit[hit > 0L]

  if (length(hit) == 0L) NULL else colnames(df)[hit[1L]]
}

.numeric_column_catdesprep <- function(df, candidates, default = NA_real_) {
  column_name <- .find_column_catdesprep(df, candidates)
  if (is.null(column_name)) {
    return(rep(default, nrow(df)))
  }
  suppressWarnings(as.numeric(df[[column_name]]))
}

.character_column_catdesprep <- function(df, candidates) {
  column_name <- .find_column_catdesprep(df, candidates)
  if (is.null(column_name)) {
    return(rep(NA_character_, nrow(df)))
  }
  out <- as.character(df[[column_name]])
  out[is.na(out) | !nzchar(trimws(out))] <- NA_character_
  out
}

.meaningful_rownames_catdesprep <- function(df) {
  rn <- rownames(df)
  if (is.null(rn) || length(rn) != nrow(df)) {
    return(rep(NA_character_, nrow(df)))
  }

  default <- identical(rn, as.character(seq_len(nrow(df))))
  if (default) {
    return(rep(NA_character_, nrow(df)))
  }

  rn <- as.character(rn)
  rn[is.na(rn) | !nzchar(trimws(rn))] <- NA_character_
  rn
}

.as_source_data_frame_catdesprep <- function(x, source_label) {
  if (is.null(x)) {
    return(NULL)
  }

  out <- tryCatch(
    as.data.frame(x, check.names = FALSE, stringsAsFactors = FALSE),
    error = function(e) NULL
  )

  if (is.null(out)) {
    stop(
      sprintf("`%s` could not be converted to a data frame.", source_label),
      call. = FALSE
    )
  }

  out
}

.split_qualitative_label_catdesprep <- function(label,
                                                 explicit_variable = NA_character_,
                                                 explicit_modality = NA_character_) {
  variable <- explicit_variable
  modality <- explicit_modality

  if (is.na(modality) || !nzchar(trimws(modality))) {
    modality <- label
  }

  if ((is.na(variable) || !nzchar(trimws(variable))) &&
      !is.na(label) && grepl("=", label, fixed = TRUE)) {
    position <- regexpr("=", label, fixed = TRUE)[1L]
    if (position > 1L && position < nchar(label)) {
      variable <- substr(label, 1L, position - 1L)
      if (is.na(explicit_modality) || !nzchar(trimws(explicit_modality))) {
        modality <- substr(label, position + 1L, nchar(label))
      }
    }
  }

  variable <- if (is.na(variable) || !nzchar(trimws(variable))) {
    NA_character_
  } else {
    trimws(variable)
  }

  modality <- if (is.na(modality) || !nzchar(trimws(modality))) {
    NA_character_
  } else {
    trimws(modality)
  }

  list(variable = variable, modality = modality)
}

.escape_evidence_component_catdesprep <- function(x, fallback) {
  if (length(x) == 0L || is.na(x) || !nzchar(as.character(x))) {
    x <- fallback
  }
  x <- as.character(x)
  x <- gsub("%", "%25", x, fixed = TRUE)
  gsub("::", "%3A%3A", x, fixed = TRUE)
}

.make_evidence_id_catdesprep <- function(group,
                                         marker_type,
                                         variable = NA_character_,
                                         modality = NA_character_,
                                         source_row = NA_integer_) {
  group_id <- .escape_evidence_component_catdesprep(group, "unknown_group")
  type_id <- .escape_evidence_component_catdesprep(marker_type, "unknown_type")
  row_fallback <- if (is.na(source_row)) "unknown_row" else paste0("row_", source_row)
  variable_id <- .escape_evidence_component_catdesprep(
    variable,
    paste0("unknown_variable_", row_fallback)
  )

  if (identical(marker_type, "quali")) {
    modality_id <- .escape_evidence_component_catdesprep(
      modality,
      paste0("unknown_modality_", row_fallback)
    )
    return(paste(group_id, type_id, variable_id, modality_id, sep = "::"))
  }

  paste(group_id, type_id, variable_id, sep = "::")
}

.ensure_unique_evidence_ids_catdesprep <- function(ids, source_rows) {
  if (length(ids) == 0L || !anyDuplicated(ids)) {
    return(ids)
  }

  duplicated_base <- unique(ids[duplicated(ids) | duplicated(ids, fromLast = TRUE)])
  out <- ids
  for (base_id in duplicated_base) {
    positions <- which(ids == base_id)
    out[positions] <- paste0(base_id, "::source_row::", source_rows[positions])
  }

  if (anyDuplicated(out)) {
    positions <- stats::ave(seq_along(out), out, FUN = seq_along)
    out <- ifelse(duplicated(out) | duplicated(out, fromLast = TRUE),
                  paste0(out, "::occurrence::", positions), out)
  }

  out
}

.direction_from_values_catdesprep <- function(v_test,
                                               fallback_difference = NULL,
                                               positive_label,
                                               negative_label,
                                               tolerance = 1e-12) {
  n <- length(v_test)
  if (is.null(fallback_difference)) {
    fallback_difference <- rep(NA_real_, n)
  }

  direction <- rep(NA_character_, n)
  basis <- rep(NA_character_, n)

  for (i in seq_len(n)) {
    value <- v_test[i]
    current_basis <- "v_test"

    if (!is.finite(value)) {
      value <- fallback_difference[i]
      current_basis <- "available_difference"
    }

    if (!is.finite(value)) {
      next
    }

    direction[i] <- if (abs(value) <= tolerance) {
      "neutral"
    } else if (value > 0) {
      positive_label
    } else {
      negative_label
    }
    basis[i] <- current_basis
  }

  list(direction = direction, basis = basis)
}

.rank_markers_catdesprep <- function(df, name_columns) {
  if (nrow(df) == 0L) {
    df$rank <- integer(0)
    return(df)
  }

  abs_v <- if ("abs_v_test" %in% names(df)) df$abs_v_test else rep(NA_real_, nrow(df))
  p_value <- if ("p_value" %in% names(df)) df$p_value else rep(NA_real_, nrow(df))

  name_values <- lapply(name_columns, function(column_name) {
    if (column_name %in% names(df)) {
      value <- as.character(df[[column_name]])
      value[is.na(value)] <- ""
      value
    } else {
      rep("", nrow(df))
    }
  })

  ordering_args <- c(
    list(-abs_v, p_value),
    name_values,
    list(df$source_row, na.last = TRUE)
  )
  ordering <- do.call(order, ordering_args)
  df <- df[ordering, , drop = FALSE]
  rownames(df) <- NULL
  df$rank <- seq_len(nrow(df))
  df
}

.validate_catdes_branch_catdesprep <- function(branch, branch_name) {
  if (is.null(branch)) {
    return(invisible(TRUE))
  }
  if (!is.list(branch) || is.data.frame(branch)) {
    stop(
      sprintf("`catdes_result$%s` must be a named list of group tables.", branch_name),
      call. = FALSE
    )
  }
  if (length(branch) == 0L) {
    return(invisible(TRUE))
  }
  branch_names <- names(branch)
  if (is.null(branch_names) || anyNA(branch_names) || any(!nzchar(branch_names))) {
    stop(
      sprintf("Every element of `catdes_result$%s` must have a non-empty group name.", branch_name),
      call. = FALSE
    )
  }
  if (anyDuplicated(branch_names)) {
    stop(
      sprintf("`catdes_result$%s` contains duplicated group names.", branch_name),
      call. = FALSE
    )
  }
  invisible(TRUE)
}

# ---------------------------------------------------------------------------
# Stable marker tables
# ---------------------------------------------------------------------------

.empty_qualitative_markers_catdesprep <- function() {
  data.frame(
    evidence_id = character(0),
    group = character(0),
    variable = character(0),
    modality = character(0),
    direction = character(0),
    direction_basis = character(0),
    observed = numeric(0),
    expected = numeric(0),
    percentage_in_group = numeric(0),
    percentage_in_modality = numeric(0),
    global_percentage = numeric(0),
    v_test = numeric(0),
    p_value = numeric(0),
    abs_v_test = numeric(0),
    rank = integer(0),
    source_row = integer(0),
    source = character(0),
    stringsAsFactors = FALSE,
    check.names = FALSE
  )
}

.empty_quantitative_markers_catdesprep <- function() {
  data.frame(
    evidence_id = character(0),
    group = character(0),
    variable = character(0),
    direction = character(0),
    direction_basis = character(0),
    group_mean = numeric(0),
    overall_mean = numeric(0),
    standard_deviation = numeric(0),
    overall_standard_deviation = numeric(0),
    coefficient = numeric(0),
    v_test = numeric(0),
    p_value = numeric(0),
    abs_v_test = numeric(0),
    rank = integer(0),
    source_row = integer(0),
    source = character(0),
    stringsAsFactors = FALSE,
    check.names = FALSE
  )
}

.normalize_qualitative_markers_catdesprep <- function(x,
                                                       group,
                                                       tolerance = 1e-12) {
  df <- .as_source_data_frame_catdesprep(
    x,
    paste0("catdes_result$category[[", group, "]]")
  )
  if (is.null(df) || nrow(df) == 0L) {
    return(.empty_qualitative_markers_catdesprep())
  }

  labels <- .meaningful_rownames_catdesprep(df)
  explicit_variable <- .character_column_catdesprep(
    df,
    c("Variable", "variable", "Descriptor", "descriptor")
  )
  explicit_modality <- .character_column_catdesprep(
    df,
    c("Modality", "modality", "Modalite", "Level", "level", "Category")
  )

  parsed <- lapply(seq_len(nrow(df)), function(i) {
    .split_qualitative_label_catdesprep(
      label = labels[i],
      explicit_variable = explicit_variable[i],
      explicit_modality = explicit_modality[i]
    )
  })

  variable <- vapply(parsed, `[[`, character(1), "variable")
  modality <- vapply(parsed, `[[`, character(1), "modality")
  v_test <- .numeric_column_catdesprep(df, c("v.test", "v_test", "vtest"))
  p_value <- .numeric_column_catdesprep(df, c("p.value", "p_value", "pvalue"))
  observed <- .numeric_column_catdesprep(df, c("observed", "observed count", "count"))
  expected <- .numeric_column_catdesprep(df, c("expected", "expected count"))
  percentage_in_group <- .numeric_column_catdesprep(
    df,
    c("Mod/Cla", "percentage in group", "percent in group")
  )
  percentage_in_modality <- .numeric_column_catdesprep(
    df,
    c("Cla/Mod", "percentage in modality", "percent in modality")
  )
  global_percentage <- .numeric_column_catdesprep(
    df,
    c("Global", "global percentage", "overall percentage")
  )

  fallback_difference <- percentage_in_group - global_percentage
  direction_info <- .direction_from_values_catdesprep(
    v_test = v_test,
    fallback_difference = fallback_difference,
    positive_label = "overrepresented",
    negative_label = "underrepresented",
    tolerance = tolerance
  )

  source_row <- seq_len(nrow(df))
  evidence_id <- vapply(seq_len(nrow(df)), function(i) {
    .make_evidence_id_catdesprep(
      group = group,
      marker_type = "quali",
      variable = variable[i],
      modality = modality[i],
      source_row = source_row[i]
    )
  }, character(1))
  evidence_id <- .ensure_unique_evidence_ids_catdesprep(evidence_id, source_row)

  out <- data.frame(
    evidence_id = evidence_id,
    group = rep(as.character(group), nrow(df)),
    variable = variable,
    modality = modality,
    direction = direction_info$direction,
    direction_basis = direction_info$basis,
    observed = observed,
    expected = expected,
    percentage_in_group = percentage_in_group,
    percentage_in_modality = percentage_in_modality,
    global_percentage = global_percentage,
    v_test = v_test,
    p_value = p_value,
    abs_v_test = abs(v_test),
    rank = integer(nrow(df)),
    source_row = as.integer(source_row),
    source = rep("FactoMineR::catdes()$category", nrow(df)),
    stringsAsFactors = FALSE,
    check.names = FALSE
  )

  .rank_markers_catdesprep(out, c("variable", "modality", "evidence_id"))
}

.normalize_quantitative_markers_catdesprep <- function(x,
                                                        group,
                                                        tolerance = 1e-12) {
  df <- .as_source_data_frame_catdesprep(
    x,
    paste0("catdes_result$quanti[[", group, "]]")
  )
  if (is.null(df) || nrow(df) == 0L) {
    return(.empty_quantitative_markers_catdesprep())
  }

  variable <- .character_column_catdesprep(
    df,
    c("Variable", "variable", "Descriptor", "descriptor")
  )
  row_labels <- .meaningful_rownames_catdesprep(df)
  missing_variable <- is.na(variable)
  variable[missing_variable] <- row_labels[missing_variable]

  source_row <- seq_len(nrow(df))

  group_mean <- .numeric_column_catdesprep(
    df,
    c("Mean in category", "group mean", "mean in group")
  )
  overall_mean <- .numeric_column_catdesprep(
    df,
    c("Overall mean", "global mean", "overall average")
  )
  standard_deviation <- .numeric_column_catdesprep(
    df,
    c("sd in category", "group sd", "standard deviation in category")
  )
  overall_standard_deviation <- .numeric_column_catdesprep(
    df,
    c("Overall sd", "global sd", "overall standard deviation")
  )
  coefficient <- .numeric_column_catdesprep(
    df,
    c("coefficient", "estimate", "coef")
  )
  v_test <- .numeric_column_catdesprep(df, c("v.test", "v_test", "vtest"))
  p_value <- .numeric_column_catdesprep(df, c("p.value", "p_value", "pvalue"))

  fallback_difference <- coefficient
  missing_coefficient <- !is.finite(fallback_difference)
  fallback_difference[missing_coefficient] <- (
    group_mean[missing_coefficient] - overall_mean[missing_coefficient]
  )

  direction_info <- .direction_from_values_catdesprep(
    v_test = v_test,
    fallback_difference = fallback_difference,
    positive_label = "higher",
    negative_label = "lower",
    tolerance = tolerance
  )

  evidence_id <- vapply(seq_len(nrow(df)), function(i) {
    .make_evidence_id_catdesprep(
      group = group,
      marker_type = "quanti",
      variable = variable[i],
      source_row = source_row[i]
    )
  }, character(1))
  evidence_id <- .ensure_unique_evidence_ids_catdesprep(evidence_id, source_row)

  out <- data.frame(
    evidence_id = evidence_id,
    group = rep(as.character(group), nrow(df)),
    variable = as.character(variable),
    direction = direction_info$direction,
    direction_basis = direction_info$basis,
    group_mean = group_mean,
    overall_mean = overall_mean,
    standard_deviation = standard_deviation,
    overall_standard_deviation = overall_standard_deviation,
    coefficient = coefficient,
    v_test = v_test,
    p_value = p_value,
    abs_v_test = abs(v_test),
    rank = integer(nrow(df)),
    source_row = as.integer(source_row),
    source = rep("FactoMineR::catdes()$quanti", nrow(df)),
    stringsAsFactors = FALSE,
    check.names = FALSE
  )

  .rank_markers_catdesprep(out, c("variable", "evidence_id"))
}

# ---------------------------------------------------------------------------
# Derived views, metrics, and registry
# ---------------------------------------------------------------------------

.empty_marker_view_catdesprep <- function() {
  data.frame(
    evidence_id = character(0),
    group = character(0),
    marker_type = character(0),
    variable = character(0),
    modality = character(0),
    direction = character(0),
    v_test = numeric(0),
    p_value = numeric(0),
    abs_v_test = numeric(0),
    rank = integer(0),
    source = character(0),
    stringsAsFactors = FALSE,
    check.names = FALSE
  )
}

.marker_view_from_tables_catdesprep <- function(qualitative_markers,
                                                quantitative_markers) {
  qualitative_view <- if (nrow(qualitative_markers) > 0L) {
    data.frame(
      evidence_id = qualitative_markers$evidence_id,
      group = qualitative_markers$group,
      marker_type = "qualitative",
      variable = qualitative_markers$variable,
      modality = qualitative_markers$modality,
      direction = qualitative_markers$direction,
      v_test = qualitative_markers$v_test,
      p_value = qualitative_markers$p_value,
      abs_v_test = qualitative_markers$abs_v_test,
      rank = qualitative_markers$rank,
      source = qualitative_markers$source,
      stringsAsFactors = FALSE,
      check.names = FALSE
    )
  } else {
    .empty_marker_view_catdesprep()
  }

  quantitative_view <- if (nrow(quantitative_markers) > 0L) {
    data.frame(
      evidence_id = quantitative_markers$evidence_id,
      group = quantitative_markers$group,
      marker_type = "quantitative",
      variable = quantitative_markers$variable,
      modality = rep(NA_character_, nrow(quantitative_markers)),
      direction = quantitative_markers$direction,
      v_test = quantitative_markers$v_test,
      p_value = quantitative_markers$p_value,
      abs_v_test = quantitative_markers$abs_v_test,
      rank = quantitative_markers$rank,
      source = quantitative_markers$source,
      stringsAsFactors = FALSE,
      check.names = FALSE
    )
  } else {
    .empty_marker_view_catdesprep()
  }

  out <- rbind(qualitative_view, quantitative_view)
  rownames(out) <- NULL
  out
}

.compute_catdes_group_metrics <- function(qualitative_markers,
                                          quantitative_markers,
                                          marker_view) {
  v_values <- marker_view$v_test[is.finite(marker_view$v_test)]
  p_values <- marker_view$p_value[is.finite(marker_view$p_value)]

  positive_directions <- c("overrepresented", "higher")
  negative_directions <- c("underrepresented", "lower")

  list(
    n_qualitative_markers = as.integer(nrow(qualitative_markers)),
    n_quantitative_markers = as.integer(nrow(quantitative_markers)),
    n_positive_markers = as.integer(sum(marker_view$direction %in% positive_directions)),
    n_negative_markers = as.integer(sum(marker_view$direction %in% negative_directions)),
    n_neutral_markers = as.integer(sum(marker_view$direction == "neutral", na.rm = TRUE)),
    n_markers_with_unknown_direction = as.integer(sum(is.na(marker_view$direction))),
    min_p_value = if (length(p_values) > 0L) min(p_values) else NA_real_,
    max_abs_v_test = if (length(v_values) > 0L) max(abs(v_values)) else NA_real_,
    median_abs_v_test = if (length(v_values) > 0L) stats::median(abs(v_values)) else NA_real_
  )
}

.build_factual_summary_catdesprep <- function(group, metrics) {
  paste0(
    "Group ", group, " has ", metrics$n_qualitative_markers,
    " retained qualitative marker(s) and ", metrics$n_quantitative_markers,
    " retained quantitative marker(s): ", metrics$n_positive_markers,
    " positive-direction marker(s), ", metrics$n_negative_markers,
    " negative-direction marker(s), and ", metrics$n_neutral_markers,
    " neutral marker(s)."
  )
}

.empty_evidence_registry_catdesprep <- function() {
  data.frame(
    evidence_id = character(0),
    group = character(0),
    marker_type = character(0),
    variable = character(0),
    modality = character(0),
    direction = character(0),
    direction_basis = character(0),
    v_test = numeric(0),
    p_value = numeric(0),
    abs_v_test = numeric(0),
    rank = integer(0),
    source = character(0),
    source_row = integer(0),
    stringsAsFactors = FALSE,
    check.names = FALSE
  )
}

.build_evidence_registry_catdesprep <- function(groups) {
  pieces <- list()
  index <- 0L

  for (group_name in names(groups)) {
    group_profile <- groups[[group_name]]

    if (nrow(group_profile$qualitative_markers) > 0L) {
      q <- group_profile$qualitative_markers
      index <- index + 1L
      pieces[[index]] <- data.frame(
        evidence_id = q$evidence_id,
        group = q$group,
        marker_type = "qualitative",
        variable = q$variable,
        modality = q$modality,
        direction = q$direction,
        direction_basis = q$direction_basis,
        v_test = q$v_test,
        p_value = q$p_value,
        abs_v_test = q$abs_v_test,
        rank = q$rank,
        source = q$source,
        source_row = q$source_row,
        stringsAsFactors = FALSE,
        check.names = FALSE
      )
    }

    if (nrow(group_profile$quantitative_markers) > 0L) {
      q <- group_profile$quantitative_markers
      index <- index + 1L
      pieces[[index]] <- data.frame(
        evidence_id = q$evidence_id,
        group = q$group,
        marker_type = "quantitative",
        variable = q$variable,
        modality = rep(NA_character_, nrow(q)),
        direction = q$direction,
        direction_basis = q$direction_basis,
        v_test = q$v_test,
        p_value = q$p_value,
        abs_v_test = q$abs_v_test,
        rank = q$rank,
        source = q$source,
        source_row = q$source_row,
        stringsAsFactors = FALSE,
        check.names = FALSE
      )
    }
  }

  if (length(pieces) == 0L) {
    return(.empty_evidence_registry_catdesprep())
  }

  registry <- do.call(rbind, pieces)
  rownames(registry) <- NULL

  if (anyDuplicated(registry$evidence_id)) {
    stop(
      "Internal error: duplicated `evidence_id` values were created.",
      call. = FALSE
    )
  }

  registry
}

.build_statistical_profiles_catdesprep <- function(catdes_result,
                                                    group_names = NULL,
                                                    input_metadata = list(),
                                                    proba = 0.05,
                                                    tolerance = 1e-12) {
  if (!.looks_like_catdes_result(catdes_result)) {
    stop(
      "The supplied object does not contain `category` or `quanti` catdes results.",
      call. = FALSE
    )
  }

  .validate_catdes_branch_catdesprep(catdes_result$category, "category")
  .validate_catdes_branch_catdesprep(catdes_result$quanti, "quanti")

  category <- if (is.null(catdes_result$category)) list() else catdes_result$category
  quanti <- if (is.null(catdes_result$quanti)) list() else catdes_result$quanti

  all_groups <- unique(c(group_names, names(category), names(quanti)))
  all_groups <- all_groups[!is.na(all_groups) & nzchar(all_groups)]

  if (length(all_groups) == 0L) {
    stop(
      paste(
        "No named group could be identified in the supplied `catdes` result.",
        "The `category` and `quanti` branches must be named by group."
      ),
      call. = FALSE
    )
  }

  groups <- stats::setNames(vector("list", length(all_groups)), all_groups)

  for (group_name in all_groups) {
    qualitative_markers <- if (group_name %in% names(category)) {
      .normalize_qualitative_markers_catdesprep(
        category[[group_name]],
        group = group_name,
        tolerance = tolerance
      )
    } else {
      .empty_qualitative_markers_catdesprep()
    }

    quantitative_markers <- if (group_name %in% names(quanti)) {
      .normalize_quantitative_markers_catdesprep(
        quanti[[group_name]],
        group = group_name,
        tolerance = tolerance
      )
    } else {
      .empty_quantitative_markers_catdesprep()
    }

    marker_view <- .marker_view_from_tables_catdesprep(
      qualitative_markers,
      quantitative_markers
    )

    positive_markers <- marker_view[
      marker_view$direction %in% c("overrepresented", "higher"),
      ,
      drop = FALSE
    ]
    negative_markers <- marker_view[
      marker_view$direction %in% c("underrepresented", "lower"),
      ,
      drop = FALSE
    ]
    rownames(positive_markers) <- NULL
    rownames(negative_markers) <- NULL

    metrics <- .compute_catdes_group_metrics(
      qualitative_markers,
      quantitative_markers,
      marker_view
    )

    groups[[group_name]] <- list(
      group = group_name,
      qualitative_markers = qualitative_markers,
      quantitative_markers = quantitative_markers,
      positive_markers = positive_markers,
      negative_markers = negative_markers,
      metrics = metrics,
      evidence_ids = marker_view$evidence_id,
      factual_summary = .build_factual_summary_catdesprep(group_name, metrics)
    )
  }

  evidence_registry <- .build_evidence_registry_catdesprep(groups)

  out <- list(
    groups = groups,
    evidence_registry = evidence_registry,
    settings = list(
      proba = proba,
      proba_applied_by_function = isTRUE(input_metadata$proba_applied_by_function),
      zero_tolerance = tolerance,
      qualitative_direction_rule = paste(
        "Sign of v_test; otherwise percentage_in_group minus global_percentage;",
        "absolute values at or below zero_tolerance are neutral."
      ),
      quantitative_direction_rule = paste(
        "Sign of v_test; otherwise coefficient; otherwise group_mean minus overall_mean;",
        "absolute values at or below zero_tolerance are neutral."
      ),
      ranking_rule = paste(
        "Within each group and marker type: decreasing absolute v_test,",
        "then increasing p_value, then variable/modality/source-row order."
      ),
      evidence_id_rule = paste(
        "group::quali::variable::modality or group::quanti::variable;",
        "literal '::' inside source labels is escaped as %3A%3A."
      )
    ),
    metadata = list(
      schema = "NaileR::statistical_profiles",
      schema_version = "1.0.0",
      source = "FactoMineR::catdes",
      input = input_metadata,
      llm_used = FALSE
    )
  )

  class(out) <- c("nail_catdes_prep", "statistical_profiles", "list")
  out
}

# ---------------------------------------------------------------------------
# Compatibility views for current downstream consumers
# ---------------------------------------------------------------------------

.format_stat_value_catdesprep <- function(x, p_value = FALSE) {
  if (length(x) == 0L || is.na(x) || !is.finite(x)) {
    return("NA")
  }
  if (p_value) {
    return(format.pval(x, digits = 4, eps = 1e-04))
  }
  format(signif(x, 5), trim = TRUE, scientific = FALSE)
}

.format_marker_for_context_catdesprep <- function(row, marker_type) {
  if (identical(marker_type, "quantitative")) {
    label <- as.character(row$variable[1L])
  } else {
    variable <- as.character(row$variable[1L])
    modality <- as.character(row$modality[1L])
    label <- if (!is.na(variable) && nzchar(variable)) {
      paste0(variable, "=", modality)
    } else {
      modality
    }
  }

  paste0(
    label,
    " (", row$direction[1L],
    "; v.test=", .format_stat_value_catdesprep(row$v_test[1L]),
    "; p.value=", .format_stat_value_catdesprep(row$p_value[1L], p_value = TRUE),
    ")"
  )
}

.catdes_group_to_legacy_summary <- function(group_profile) {
  quantitative_traits <- if (nrow(group_profile$quantitative_markers) > 0L) {
    vapply(seq_len(nrow(group_profile$quantitative_markers)), function(i) {
      .format_marker_for_context_catdesprep(
        group_profile$quantitative_markers[i, , drop = FALSE],
        "quantitative"
      )
    }, character(1))
  } else {
    character(0)
  }

  categorical_traits <- if (nrow(group_profile$qualitative_markers) > 0L) {
    vapply(seq_len(nrow(group_profile$qualitative_markers)), function(i) {
      .format_marker_for_context_catdesprep(
        group_profile$qualitative_markers[i, , drop = FALSE],
        "qualitative"
      )
    }, character(1))
  } else {
    character(0)
  }

  list(
    core_group_profile = group_profile$factual_summary,
    quantitative_traits = quantitative_traits,
    categorical_traits = categorical_traits,
    distinctive_markers = c(categorical_traits, quantitative_traits),
    statistical_caution = paste(
      "These markers characterize the group relative to the full sample",
      "under the variables and analysis settings used; they are associations,",
      "not causal effects, and need not describe every individual."
    ),
    injectable_summary = group_profile$factual_summary
  )
}

.as_legacy_catdes_profiles <- function(statistical_profiles) {
  lapply(statistical_profiles$groups, function(group_profile) {
    marker_view <- .marker_view_from_tables_catdesprep(
      group_profile$qualitative_markers,
      group_profile$quantitative_markers
    )

    list(
      quantitative = group_profile$quantitative_markers,
      categorical = group_profile$qualitative_markers,
      selected_for_prompt = list(
        quantitative = group_profile$quantitative_markers,
        categorical = group_profile$qualitative_markers
      ),
      salient_quantitative_traits = group_profile$quantitative_markers$variable,
      salient_categorical_traits = group_profile$qualitative_markers$modality,
      metrics = list(
        retained = group_profile$metrics,
        shown_in_prompt = group_profile$metrics
      ),
      evidence_ids = marker_view$evidence_id
    )
  })
}

.warn_ignored_catdes_prep_arguments <- function(arguments) {
  arguments <- unique(arguments[nzchar(arguments)])
  if (length(arguments) == 0L) {
    return(invisible(NULL))
  }

  warning(
    paste0(
      "`nail_catdes_prep()` is now entirely mechanical. The following ",
      "deprecated prompt/LLM arguments are ignored: ",
      paste(arguments, collapse = ", "),
      "."
    ),
    call. = FALSE
  )

  invisible(NULL)
}

# ---------------------------------------------------------------------------
# Public function
# ---------------------------------------------------------------------------

#' Build deterministic statistical profiles from a `catdes` result
#'
#' `nail_catdes_prep()` normalizes the qualitative and quantitative tables
#' retained by [FactoMineR::catdes()] into one stable, traceable mechanical
#' artifact. It never calls a language model and never creates a sociological,
#' psychological, consumer, marketing, or other domain interpretation.
#'
#' The function answers only: which statistical markers characterize each
#' group, in which direction, with which values, ranks, and evidence IDs?
#'
#' @param x Preferred input. A raw result returned by
#'   [FactoMineR::catdes()], an object returned by [nail_catdes()] carrying a
#'   `"catdes_result"` attribute, or an existing `statistical_profiles` object.
#' @param dataset Deprecated compatibility input. A data frame from which
#'   [FactoMineR::catdes()] is calculated once. Prefer computing the analysis
#'   first and supplying it through `x`.
#' @param num.var Deprecated compatibility argument giving the grouping-column
#'   index when `dataset` is supplied.
#' @param exclude Optional column names or indices excluded before `catdes()`
#'   is calculated through the deprecated `dataset` interface.
#' @param proba Probability threshold passed to [FactoMineR::catdes()] only
#'   when `dataset` is supplied. With a precomputed `x`, the retained rows are
#'   accepted as the statistical result and `proba` is recorded as metadata.
#' @param sample.pct,top_n_quanti,top_n_quali Deprecated prompt-selection
#'   arguments. They are ignored and never remove evidence.
#' @param profile_mode,prompt_style,include_metrics_in_prompt Deprecated prompt
#'   presentation arguments. They are ignored.
#' @param introduction,request,conclusion Deprecated prompt text arguments.
#'   They are ignored.
#' @param model,provider,generate Deprecated LLM arguments. They are ignored;
#'   no provider is contacted even when `generate = TRUE` is supplied.
#' @param row.w Optional row weights passed to [FactoMineR::catdes()] only with
#'   the deprecated `dataset` interface.
#' @param ... Deprecated provider or prompt arguments. They are ignored.
#'
#' @details
#' ## Main artifact
#'
#' The returned object is a `statistical_profiles` list with four components:
#'
#' - `groups`: one explicit element per group;
#' - `evidence_registry`: one row per retained statistical marker;
#' - `settings`: deterministic rules used for directions, ranks, and IDs;
#' - `metadata`: source and schema information, including `llm_used = FALSE`.
#'
#' Each group contains `qualitative_markers`, `quantitative_markers`,
#' `positive_markers`, `negative_markers`, descriptive `metrics`, its complete
#' `evidence_ids`, and a short factual summary produced mechanically by R.
#'
#' ## Directions
#'
#' For qualitative markers, positive and negative v-tests produce
#' `"overrepresented"` and `"underrepresented"`. For quantitative markers,
#' they produce `"higher"` and `"lower"`. Values whose absolute magnitude is
#' at or below the stored tolerance are `"neutral"`. If the v-test is missing,
#' the function uses an available observed difference and records that basis.
#' If no signed quantity is available, direction remains `NA`.
#'
#' ## Ranking
#'
#' Rows are ranked separately within each group and marker type by decreasing
#' absolute v-test, then increasing p-value, then source names and source-row
#' order. Missing statistics are retained and sorted deterministically after
#' available values.
#'
#' ## Evidence IDs
#'
#' IDs use `group::quali::variable::modality` or
#' `group::quanti::variable`. Literal `::` inside source labels is escaped as
#' `%3A%3A`; source labels themselves are otherwise preserved. If a source
#' table does not expose a qualitative variable name, the variable column is
#' `NA` and a deterministic source-row placeholder is used only inside the ID.
#'
#' ## Missing source fields
#'
#' Stable columns are always present. A field that has a clear meaning but is
#' absent from the source table is stored as `NA`; it is never reconstructed
#' from insufficient information. In standard `catdes()` category tables,
#' `Mod/Cla`, `Cla/Mod`, and `Global` are mapped respectively to
#' `percentage_in_group`, `percentage_in_modality`, and `global_percentage`.
#'
#' ## Compatibility
#'
#' The raw `catdes` result and compatibility views are attached as
#' `"catdes_result"`, `"catdes_profiles"`, `"catdes_input"`, and
#' `"catdes_settings"` attributes. The compatibility views are derived from
#' the main artifact and are not a second source of truth. The alias
#' [nail_group_profile_prep()] remains deprecated.
#'
#' This object is intended to supply exact statistical evidence to a later
#' contextual interpretation, notably [nail_textual_contextualized()], where a
#' language model may connect the markers to textual evidence and domain
#' questions.
#'
#' @return A list of class `c("nail_catdes_prep", "statistical_profiles",
#'   "list")` containing `groups`, `evidence_registry`, `settings`, and
#'   `metadata`. The function returns the same mechanical artifact regardless
#'   of deprecated prompt, sampling, or LLM arguments.
#'
#' @seealso [FactoMineR::catdes()], [nail_catdes()],
#'   [nail_textual_contextualized()]
#' @export
#'
#' @examples
#' data(iris)
#'
#' iris_catdes <- FactoMineR::catdes(
#'   iris,
#'   num.var = 5,
#'   proba = 0.05
#' )
#'
#' iris_profiles <- nail_catdes_prep(iris_catdes)
#' names(iris_profiles$groups)
#' iris_profiles$groups$setosa$quantitative_markers
#' iris_profiles$evidence_registry
nail_catdes_prep <- function(x = NULL,
                              dataset = NULL,
                              num.var = NULL,
                              exclude = NULL,
                              proba = 0.05,
                              sample.pct = 1,
                              top_n_quanti = 5,
                              top_n_quali = 5,
                              profile_mode = c("balanced", "categorical", "quantitative"),
                              prompt_style = c("compact", "detailed"),
                              include_metrics_in_prompt = TRUE,
                              introduction = NULL,
                              request = NULL,
                              conclusion = NULL,
                              model = "llama3",
                              provider = c("ollama", "gemini"),
                              row.w = NULL,
                              generate = FALSE,
                              ...) {
  legacy_arguments <- character(0)

  if (!missing(sample.pct)) legacy_arguments <- c(legacy_arguments, "sample.pct")
  if (!missing(top_n_quanti)) legacy_arguments <- c(legacy_arguments, "top_n_quanti")
  if (!missing(top_n_quali)) legacy_arguments <- c(legacy_arguments, "top_n_quali")
  if (!missing(profile_mode)) legacy_arguments <- c(legacy_arguments, "profile_mode")
  if (!missing(prompt_style)) legacy_arguments <- c(legacy_arguments, "prompt_style")
  if (!missing(include_metrics_in_prompt)) legacy_arguments <- c(legacy_arguments, "include_metrics_in_prompt")
  if (!missing(introduction)) legacy_arguments <- c(legacy_arguments, "introduction")
  if (!missing(request)) legacy_arguments <- c(legacy_arguments, "request")
  if (!missing(conclusion)) legacy_arguments <- c(legacy_arguments, "conclusion")
  if (!missing(model)) legacy_arguments <- c(legacy_arguments, "model")
  if (!missing(provider)) legacy_arguments <- c(legacy_arguments, "provider")
  if (!missing(generate)) legacy_arguments <- c(legacy_arguments, "generate")

  dots <- list(...)
  if (length(dots) > 0L) {
    dot_names <- names(dots)
    if (is.null(dot_names)) {
      dot_names <- rep("...", length(dots))
    }
    dot_names[!nzchar(dot_names)] <- "..."
    legacy_arguments <- c(legacy_arguments, dot_names)
  }

  .warn_ignored_catdes_prep_arguments(legacy_arguments)

  .validate_catdes_prep_core_inputs(
    x = x,
    dataset = dataset,
    num.var = num.var,
    exclude = exclude,
    proba = proba,
    row.w = row.w
  )

  extracted <- .extract_catdes_input_catdesprep(
    x = x,
    dataset = dataset,
    num.var = num.var,
    exclude = exclude,
    proba = proba,
    row.w = row.w
  )

  if (!is.null(extracted$already_prepared)) {
    return(extracted$already_prepared)
  }

  extracted$catdes_result <- .canonicalize_catdes_result_catdesprep(
    extracted$catdes_result
  )

  statistical_profiles <- .build_statistical_profiles_catdesprep(
    catdes_result = extracted$catdes_result,
    group_names = extracted$group_names,
    input_metadata = extracted$input_metadata,
    proba = proba
  )

  attr(statistical_profiles, "catdes_result") <- extracted$catdes_result
  attr(statistical_profiles, "catdes_profiles") <- .as_legacy_catdes_profiles(
    statistical_profiles
  )
  attr(statistical_profiles, "catdes_input") <- extracted$input_metadata
  attr(statistical_profiles, "catdes_settings") <- statistical_profiles$settings

  statistical_profiles
}

#' @rdname nail_catdes_prep
#' @export
nail_group_profile_prep <- function(...) {
  .Deprecated(new = "nail_catdes_prep", package = "NaileR")
  nail_catdes_prep(...)
}
