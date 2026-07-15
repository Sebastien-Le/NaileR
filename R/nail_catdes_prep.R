#' @importFrom FactoMineR catdes
#' @importFrom knitr kable
#' @importFrom tibble rownames_to_column

# ---------------------------------------------------------------------------
# Validation and input preparation
# ---------------------------------------------------------------------------

validate_catdes_prep_inputs <- function(x = NULL,
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
                                        row.w = NULL,
                                        generate = FALSE) {
  profile_mode <- match.arg(profile_mode)
  prompt_style <- match.arg(prompt_style)

  if (is.null(x) == is.null(dataset)) {
    stop(
      "Provide exactly one of `x` or `dataset`.",
      call. = FALSE
    )
  }

  if (!is.null(dataset)) {
    if (!is.data.frame(dataset)) {
      stop("`dataset` must be a data frame.", call. = FALSE)
    }

    if (ncol(dataset) < 2) {
      stop("`dataset` must contain at least two columns.", call. = FALSE)
    }

    if (is.null(num.var) || !is.numeric(num.var) || length(num.var) != 1 ||
        is.na(num.var) || !is.finite(num.var) || num.var != floor(num.var) ||
        num.var < 1 || num.var > ncol(dataset)) {
      stop(
        "When `dataset` is supplied, `num.var` must be a single valid integer column index.",
        call. = FALSE
      )
    }
  }

  if (!is.null(x)) {
    if (!is.null(exclude)) {
      stop(
        "`exclude` can only be used when `dataset` is supplied. Exclusions must be applied before `catdes()` is computed.",
        call. = FALSE
      )
    }

    if (!is.null(row.w)) {
      stop(
        "`row.w` can only be used when `dataset` is supplied. A raw `catdes` result has already been computed.",
        call. = FALSE
      )
    }
  }

  if (!is.null(exclude) &&
      !(is.numeric(exclude) || is.character(exclude))) {
    stop(
      "`exclude` must be NULL, a vector of column indices, or a vector of column names.",
      call. = FALSE
    )
  }

  if (!is.numeric(proba) || length(proba) != 1 || is.na(proba) ||
      !is.finite(proba) || proba <= 0 || proba > 1) {
    stop("`proba` must be a single numeric value in ]0, 1].", call. = FALSE)
  }

  if (!is.numeric(sample.pct) || length(sample.pct) != 1 || is.na(sample.pct) ||
      !is.finite(sample.pct) || sample.pct <= 0 || sample.pct > 1) {
    stop("`sample.pct` must be a single numeric value in ]0, 1].", call. = FALSE)
  }

  for (arg_name in c("top_n_quanti", "top_n_quali")) {
    value <- get(arg_name, inherits = FALSE)

    if (!is.numeric(value) || length(value) != 1 || is.na(value) ||
        !is.finite(value) || value != floor(value) || value < 0) {
      stop(
        sprintf("`%s` must be a single non-negative integer.", arg_name),
        call. = FALSE
      )
    }
  }

  if (!is.logical(include_metrics_in_prompt) ||
      length(include_metrics_in_prompt) != 1 ||
      is.na(include_metrics_in_prompt)) {
    stop(
      "`include_metrics_in_prompt` must be a single non-missing logical value.",
      call. = FALSE
    )
  }

  if (!is.logical(generate) || length(generate) != 1 || is.na(generate)) {
    stop("`generate` must be a single non-missing logical value.", call. = FALSE)
  }

  if (!is.null(row.w)) {
    if (!is.numeric(row.w) || length(row.w) != nrow(dataset) ||
        anyNA(row.w) || any(!is.finite(row.w)) || any(row.w < 0) ||
        sum(row.w) <= 0) {
      stop(
        "`row.w` must be a non-negative finite numeric vector of length `nrow(dataset)` with a positive sum.",
        call. = FALSE
      )
    }
  }

  invisible(TRUE)
}

.resolve_exclude_catdesprep <- function(dataset, exclude = NULL) {
  if (is.null(exclude) || length(exclude) == 0) {
    return(integer(0))
  }

  if (is.numeric(exclude)) {
    if (anyNA(exclude) || any(!is.finite(exclude)) ||
        any(exclude != floor(exclude)) ||
        any(exclude < 1) || any(exclude > ncol(dataset))) {
      stop(
        "Numeric `exclude` values must be valid integer column indices.",
        call. = FALSE
      )
    }

    return(sort(unique(as.integer(exclude))))
  }

  missing_names <- setdiff(exclude, colnames(dataset))

  if (length(missing_names) > 0) {
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

.prepare_dataset_catdesprep <- function(dataset,
                                        num.var,
                                        exclude = NULL) {
  exclude_idx <- .resolve_exclude_catdesprep(dataset, exclude)

  if (num.var %in% exclude_idx) {
    stop(
      "The grouping variable selected by `num.var` cannot also be excluded.",
      call. = FALSE
    )
  }

  keep_idx <- setdiff(seq_len(ncol(dataset)), exclude_idx)

  if (length(keep_idx) < 2) {
    stop(
      "After applying `exclude`, at least the grouping variable and one descriptor must remain.",
      call. = FALSE
    )
  }

  prepared <- dataset[, keep_idx, drop = FALSE]
  new_num_var <- match(num.var, keep_idx)

  # FactoMineR expects qualitative descriptors to be factors. Character
  # columns are converted explicitly; numeric columns remain numeric.
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

  if (length(unique(observed_groups)) < 2) {
    stop(
      "The grouping variable must contain at least two observed groups.",
      call. = FALSE
    )
  }

  group_names <- levels(droplevels(prepared[[new_num_var]]))

  list(
    dataset = prepared,
    num.var = new_num_var,
    group_names = group_names,
    metadata = list(
      source = "dataset",
      original_group_index = num.var,
      prepared_group_index = new_num_var,
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

.extract_catdes_input_catdesprep <- function(x = NULL,
                                             dataset = NULL,
                                             num.var = NULL,
                                             exclude = NULL,
                                             proba = 0.05,
                                             row.w = NULL) {
  if (!is.null(x)) {
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
          "`x` does not look like a raw `FactoMineR::catdes()` result",
          "and does not contain a `catdes_result` attribute."
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
# Standardization of catdes results
# ---------------------------------------------------------------------------

.add_rownames_column_catdesprep <- function(df, column_name) {
  df <- as.data.frame(
    df,
    check.names = FALSE,
    stringsAsFactors = FALSE
  )

  if (column_name %in% colnames(df)) {
    return(df)
  }

  tibble::rownames_to_column(df, var = column_name)
}

.extract_quanti_catdesprep <- function(catdes_result) {
  if (!"quanti" %in% names(catdes_result) ||
      is.null(catdes_result$quanti) ||
      !is.list(catdes_result$quanti)) {
    return(list())
  }

  out <- vector("list", length(catdes_result$quanti))
  names(out) <- names(catdes_result$quanti)

  for (i in seq_along(catdes_result$quanti)) {
    df <- .add_rownames_column_catdesprep(
      catdes_result$quanti[[i]],
      "Variable"
    )

    if (nrow(df) == 0) {
      out[[i]] <- NULL
      next
    }

    if ("v.test" %in% colnames(df)) {
      vtest <- suppressWarnings(as.numeric(df$v.test))
      df$direction <- ifelse(
        is.na(vtest),
        NA_character_,
        ifelse(
          vtest > 0,
          "higher than overall",
          ifelse(vtest < 0, "lower than overall", "no signed difference")
        )
      )
      df$abs_v_test <- abs(vtest)
    } else {
      df$direction <- NA_character_
      df$abs_v_test <- NA_real_
    }

    if (all(c("Mean in category", "Overall mean") %in% colnames(df))) {
      df$mean_difference <- suppressWarnings(
        as.numeric(df[["Mean in category"]]) -
          as.numeric(df[["Overall mean"]])
      )
    }

    out[[i]] <- df
  }

  out[!vapply(out, is.null, logical(1))]
}

.extract_quali_catdesprep <- function(catdes_result) {
  if (!"category" %in% names(catdes_result) ||
      is.null(catdes_result$category) ||
      !is.list(catdes_result$category)) {
    return(list())
  }

  out <- vector("list", length(catdes_result$category))
  names(out) <- names(catdes_result$category)

  for (i in seq_along(catdes_result$category)) {
    df <- .add_rownames_column_catdesprep(
      catdes_result$category[[i]],
      "Modality"
    )

    if (nrow(df) == 0) {
      out[[i]] <- NULL
      next
    }

    if ("v.test" %in% colnames(df)) {
      vtest <- suppressWarnings(as.numeric(df$v.test))
      df$direction <- ifelse(
        is.na(vtest),
        NA_character_,
        ifelse(
          vtest > 0,
          "over-represented",
          ifelse(vtest < 0, "under-represented", "no signed association")
        )
      )
      df$abs_v_test <- abs(vtest)
    } else {
      df$direction <- NA_character_
      df$abs_v_test <- NA_real_
    }

    out[[i]] <- df
  }

  out[!vapply(out, is.null, logical(1))]
}

.sort_markers_catdesprep <- function(df) {
  if (is.null(df) || nrow(df) == 0) {
    return(df)
  }

  p_values <- if ("p.value" %in% colnames(df)) {
    suppressWarnings(as.numeric(df$p.value))
  } else {
    rep(NA_real_, nrow(df))
  }

  if ("abs_v_test" %in% colnames(df)) {
    ordering <- order(
      -suppressWarnings(as.numeric(df$abs_v_test)),
      p_values,
      na.last = TRUE
    )
    return(df[ordering, , drop = FALSE])
  }

  if ("v.test" %in% colnames(df)) {
    ordering <- order(
      -abs(suppressWarnings(as.numeric(df$v.test))),
      p_values,
      na.last = TRUE
    )
    return(df[ordering, , drop = FALSE])
  }

  df
}

.select_markers_catdesprep <- function(df,
                                       sample.pct = 1,
                                       top_n = 5) {
  if (is.null(df)) {
    return(NULL)
  }

  if (nrow(df) == 0 || top_n == 0) {
    return(df[0, , drop = FALSE])
  }

  df <- .sort_markers_catdesprep(df)

  n_from_pct <- if (sample.pct >= 1) {
    nrow(df)
  } else {
    max(1, round(nrow(df) * sample.pct))
  }

  n_keep <- min(nrow(df), n_from_pct, top_n)
  utils::head(df, n_keep)
}

.empty_marker_metrics_catdesprep <- function() {
  list(
    n_retained = 0L,
    n_positive_v_test = 0L,
    n_negative_v_test = 0L,
    n_zero_v_test = 0L,
    max_abs_v_test = NA_real_,
    median_abs_v_test = NA_real_,
    min_p_value = NA_real_
  )
}

.compute_marker_metrics_catdesprep <- function(df) {
  if (is.null(df) || nrow(df) == 0) {
    return(.empty_marker_metrics_catdesprep())
  }

  vtest <- if ("v.test" %in% colnames(df)) {
    suppressWarnings(as.numeric(df$v.test))
  } else {
    rep(NA_real_, nrow(df))
  }

  p_values <- if ("p.value" %in% colnames(df)) {
    suppressWarnings(as.numeric(df$p.value))
  } else {
    rep(NA_real_, nrow(df))
  }

  finite_v <- vtest[is.finite(vtest)]
  finite_p <- p_values[is.finite(p_values)]

  list(
    n_retained = as.integer(nrow(df)),
    n_positive_v_test = as.integer(sum(finite_v > 0)),
    n_negative_v_test = as.integer(sum(finite_v < 0)),
    n_zero_v_test = as.integer(sum(finite_v == 0)),
    max_abs_v_test = if (length(finite_v) > 0) max(abs(finite_v)) else NA_real_,
    median_abs_v_test = if (length(finite_v) > 0) stats::median(abs(finite_v)) else NA_real_,
    min_p_value = if (length(finite_p) > 0) min(finite_p) else NA_real_
  )
}

.combine_marker_metrics_catdesprep <- function(quanti_df, quali_df) {
  quanti_metrics <- .compute_marker_metrics_catdesprep(quanti_df)
  quali_metrics <- .compute_marker_metrics_catdesprep(quali_df)

  all_v <- c(
    if (!is.null(quanti_df) && "v.test" %in% colnames(quanti_df)) {
      suppressWarnings(as.numeric(quanti_df$v.test))
    } else {
      numeric(0)
    },
    if (!is.null(quali_df) && "v.test" %in% colnames(quali_df)) {
      suppressWarnings(as.numeric(quali_df$v.test))
    } else {
      numeric(0)
    }
  )
  all_v <- all_v[is.finite(all_v)]

  all_p <- c(
    if (!is.null(quanti_df) && "p.value" %in% colnames(quanti_df)) {
      suppressWarnings(as.numeric(quanti_df$p.value))
    } else {
      numeric(0)
    },
    if (!is.null(quali_df) && "p.value" %in% colnames(quali_df)) {
      suppressWarnings(as.numeric(quali_df$p.value))
    } else {
      numeric(0)
    }
  )
  all_p <- all_p[is.finite(all_p)]

  overall <- list(
    n_retained = as.integer(
      quanti_metrics$n_retained + quali_metrics$n_retained
    ),
    n_quantitative_retained = quanti_metrics$n_retained,
    n_categorical_retained = quali_metrics$n_retained,
    n_positive_v_test = as.integer(sum(all_v > 0)),
    n_negative_v_test = as.integer(sum(all_v < 0)),
    n_zero_v_test = as.integer(sum(all_v == 0)),
    max_abs_v_test = if (length(all_v) > 0) max(abs(all_v)) else NA_real_,
    median_abs_v_test = if (length(all_v) > 0) stats::median(abs(all_v)) else NA_real_,
    min_p_value = if (length(all_p) > 0) min(all_p) else NA_real_
  )

  list(
    overall = overall,
    quantitative = quanti_metrics,
    categorical = quali_metrics
  )
}

.empty_profile_table_catdesprep <- function(type = c("quantitative", "categorical")) {
  type <- match.arg(type)

  if (type == "quantitative") {
    return(data.frame(
      Variable = character(0),
      direction = character(0),
      v.test = numeric(0),
      p.value = numeric(0),
      stringsAsFactors = FALSE,
      check.names = FALSE
    ))
  }

  data.frame(
    Modality = character(0),
    direction = character(0),
    v.test = numeric(0),
    p.value = numeric(0),
    stringsAsFactors = FALSE,
    check.names = FALSE
  )
}

.build_catdes_profiles_mechanical <- function(
    catdes_result,
    group_names = NULL,
    sample.pct = 1,
    top_n_quanti = 5,
    top_n_quali = 5,
    profile_mode = c("balanced", "categorical", "quantitative")) {

  profile_mode <- match.arg(profile_mode)

  quanti_list <- .extract_quanti_catdesprep(catdes_result)
  quali_list <- .extract_quali_catdesprep(catdes_result)

  all_groups <- unique(c(
    group_names,
    names(quanti_list),
    names(quali_list)
  ))
  all_groups <- all_groups[!is.na(all_groups) & nzchar(all_groups)]

  out <- vector("list", length(all_groups))
  names(out) <- all_groups

  for (group_name in all_groups) {
    quanti_full <- if (group_name %in% names(quanti_list)) {
      .sort_markers_catdesprep(quanti_list[[group_name]])
    } else {
      .empty_profile_table_catdesprep("quantitative")
    }

    quali_full <- if (group_name %in% names(quali_list)) {
      .sort_markers_catdesprep(quali_list[[group_name]])
    } else {
      .empty_profile_table_catdesprep("categorical")
    }

    quanti_prompt <- .select_markers_catdesprep(
      quanti_full,
      sample.pct = sample.pct,
      top_n = top_n_quanti
    )

    quali_prompt <- .select_markers_catdesprep(
      quali_full,
      sample.pct = sample.pct,
      top_n = top_n_quali
    )

    if (profile_mode == "quantitative") {
      quali_prompt <- quali_full[0, , drop = FALSE]
    }

    if (profile_mode == "categorical") {
      quanti_prompt <- quanti_full[0, , drop = FALSE]
    }

    out[[group_name]] <- list(
      quantitative = quanti_full,
      categorical = quali_full,
      selected_for_prompt = list(
        quantitative = quanti_prompt,
        categorical = quali_prompt
      ),
      salient_quantitative_traits = if (nrow(quanti_prompt) > 0) {
        as.character(quanti_prompt$Variable)
      } else {
        character(0)
      },
      salient_categorical_traits = if (nrow(quali_prompt) > 0) {
        as.character(quali_prompt$Modality)
      } else {
        character(0)
      },
      metrics = list(
        retained = .combine_marker_metrics_catdesprep(
          quanti_full,
          quali_full
        ),
        shown_in_prompt = .combine_marker_metrics_catdesprep(
          quanti_prompt,
          quali_prompt
        )
      )
    )
  }

  out
}

# ---------------------------------------------------------------------------
# Prompt data blocks
# ---------------------------------------------------------------------------

.format_catdes_table <- function(df) {
  if (is.null(df) || nrow(df) == 0) {
    return(character(0))
  }

  out <- as.data.frame(
    df,
    check.names = FALSE,
    stringsAsFactors = FALSE
  )

  numeric_columns <- names(out)[
    vapply(out, is.numeric, logical(1))
  ]

  regular_numeric_columns <- setdiff(
    numeric_columns,
    "p.value"
  )

  for (column_name in regular_numeric_columns) {
    values <- out[[column_name]]

    out[[column_name]] <- ifelse(
      is.na(values),
      NA_character_,
      format(
        signif(values, digits = 5),
        scientific = FALSE,
        trim = TRUE
      )
    )
  }

  if ("p.value" %in% names(out)) {
    p_values <- suppressWarnings(
      as.numeric(out[["p.value"]])
    )

    out[["p.value"]] <- ifelse(
      is.na(p_values),
      NA_character_,
      format.pval(
        p_values,
        digits = 5,
        eps = .Machine$double.eps
      )
    )
  }

  knitr::kable(
    out,
    format = "pipe",
    align = c(
      "l",
      rep("r", max(0, ncol(out) - 1))
    )
  )
}

.keep_prompt_columns_catdesprep <- function(
    df,
    type = c("quantitative", "categorical")) {

  type <- match.arg(type)

  if (is.null(df) || nrow(df) == 0) {
    return(df)
  }

  wanted <- if (type == "quantitative") {
    c(
      "Variable",
      "direction"
    )
  } else {
    c(
      "Modality",
      "direction"
    )
  }

  wanted <- wanted[
    wanted %in% colnames(df)
  ]

  df[, wanted, drop = FALSE]
}

.format_metric_value_catdesprep <- function(x,
                                                   digits = 4,
                                                   p_value = FALSE) {
  if (length(x) == 0 || is.na(x) || !is.finite(x)) {
    return("NA")
  }

  if (p_value) {
    return(
      format.pval(
        x,
        digits = digits,
        eps = .Machine$double.eps
      )
    )
  }

  if (x != 0 && abs(x) < 10^(-digits)) {
    return(
      format(
        x,
        digits = digits,
        scientific = TRUE,
        trim = TRUE
      )
    )
  }

  format(
    signif(x, digits = digits),
    scientific = FALSE,
    trim = TRUE
  )
}

.build_metrics_block_catdesprep <- function(metrics) {
  retained <- metrics$retained$overall
  shown <- metrics$shown_in_prompt$overall

  paste(
    "### Mechanical descriptor summary",
    paste0(
      "- Retained by `catdes()`: ",
      retained$n_quantitative_retained,
      " quantitative + ",
      retained$n_categorical_retained,
      " categorical = ",
      retained$n_retained,
      " total markers."
    ),
    paste0(
      "- Shown in this prompt: ",
      shown$n_quantitative_retained,
      " quantitative + ",
      shown$n_categorical_retained,
      " categorical = ",
      shown$n_retained,
      " total markers."
    ),
    paste0(
      "- Largest absolute v-test among retained markers: ",
      .format_metric_value_catdesprep(
        retained$max_abs_v_test
      )
    ),
    paste0(
      "- Median absolute v-test among retained markers: ",
      .format_metric_value_catdesprep(
        retained$median_abs_v_test
      )
    ),
    paste0(
      "- Smallest retained p-value: ",
      .format_metric_value_catdesprep(
        retained$min_p_value,
        p_value = TRUE
      )
    ),
    "- Marker counts describe the retained statistical output only. They do not measure sample representativeness, reliability, data quality, statistical power, or evidential strength.",
    sep = "\n"
  )
}

get_sentences_catdes_prep <- function(mechanical_profiles,
                                      profile_mode = c("balanced", "categorical", "quantitative"),
                                      include_metrics_in_prompt = TRUE) {
  profile_mode <- match.arg(profile_mode)

  out <- vector("list", length(mechanical_profiles))
  names(out) <- names(mechanical_profiles)

  for (group_name in names(mechanical_profiles)) {
    profile <- mechanical_profiles[[group_name]]
    blocks <- character(0)

    if (include_metrics_in_prompt) {
      blocks <- c(
        blocks,
        .build_metrics_block_catdesprep(profile$metrics)
      )
    }

    if (profile_mode %in% c("balanced", "quantitative")) {
      quanti_df <- .keep_prompt_columns_catdesprep(
        profile$selected_for_prompt$quantitative,
        type = "quantitative"
      )

      if (!is.null(quanti_df) && nrow(quanti_df) > 0) {
        blocks <- c(
          blocks,
          paste(
            "### Quantitative markers",
            "",
            paste(.format_catdes_table(quanti_df), collapse = "\n"),
            sep = "\n"
          )
        )
      } else {
        blocks <- c(
          blocks,
          "### Quantitative markers\n\nNo quantitative descriptor was retained for this group under the current settings."
        )
      }
    }

    if (profile_mode %in% c("balanced", "categorical")) {
      quali_df <- .keep_prompt_columns_catdesprep(
        profile$selected_for_prompt$categorical,
        type = "categorical"
      )

      if (!is.null(quali_df) && nrow(quali_df) > 0) {
        blocks <- c(
          blocks,
          paste(
            "### Categorical markers",
            "",
            paste(.format_catdes_table(quali_df), collapse = "\n"),
            sep = "\n"
          )
        )
      } else {
        blocks <- c(
          blocks,
          "### Categorical markers\n\nNo categorical descriptor was retained for this group under the current settings."
        )
      }
    }

    out[[group_name]] <- paste(blocks, collapse = "\n\n")
  }

  out
}

# ---------------------------------------------------------------------------
# Prompt builders
# ---------------------------------------------------------------------------

build_guide_catdes_prep <- function(
    proba = 0.05,
    profile_mode = c(
      "balanced",
      "categorical",
      "quantitative"
    ),
    prompt_style = c(
      "compact",
      "detailed"
    ),
    source = c(
      "dataset",
      "x"
    )) {

  profile_mode <- match.arg(profile_mode)
  prompt_style <- match.arg(prompt_style)
  source <- match.arg(source)

  mode_text <- switch(
    profile_mode,

    balanced = paste(
      "Quantitative and categorical descriptors belong to the evidence base",
      "when both corresponding tables are present."
    ),

    categorical = paste(
      "Only the categorical descriptors displayed in the prompt should be",
      "used in the narrative synthesis."
    ),

    quantitative = paste(
      "Only the quantitative descriptors displayed in the prompt should be",
      "used in the narrative synthesis."
    )
  )

  threshold_text <- if (source == "dataset") {
    paste0(
      "The descriptors were retained by `FactoMineR::catdes()` using ",
      "proba = ",
      proba,
      "."
    )
  } else {
    paste0(
      "A precomputed `catdes` result was supplied. The declared retention ",
      "threshold is proba = ",
      proba,
      ", but the function cannot verify the threshold originally used ",
      "to compute `x`."
    )
  }

  if (prompt_style == "compact") {
    return(
      paste(
        "## How to Read the Results",
        threshold_text,
        mode_text,
        paste(
          "Positive and negative v-tests indicate statistical directions;",
          "they are not favorable or unfavorable judgments."
        ),
        paste(
          "The displayed tables may contain only a deterministic subset of",
          "the complete retained results. The mechanical summary distinguishes",
          "the number retained from the number displayed."
        ),
        paste(
          "Use the term retained rather than statistically significant unless",
          "such wording is explicitly justified by the selected threshold."
        ),
        paste(
          "The results describe associations relative to the full sample.",
          "They do not establish causality, individual-level properties,",
          "sample representativeness, reliability, data quality, or",
          "statistical power."
        ),
        sep = "\n"
      )
    )
  }

  paste(
    "## How to Read the Results",
    threshold_text,
    mode_text,
    "",
    "### Quantitative descriptors",
    paste(
      "A positive quantitative v-test indicates a higher value for the group",
      "than for the full sample; a negative v-test indicates a lower value."
    ),
    paste(
      "This direction is mathematical. It must not be translated into a",
      "judgment of quality, desirability, superiority, or inferiority."
    ),
    "",
    "### Categorical descriptors",
    paste(
      "A positive categorical v-test indicates over-representation or a",
      "positive association with the group."
    ),
    paste(
      "A negative categorical v-test indicates under-representation or a",
      "negative association under the current analysis."
    ),
    "",
    "### Retained and displayed descriptors",
    paste(
      "The complete mechanical profile preserves every descriptor retained",
      "by `catdes()` under the selected analysis settings."
    ),
    paste(
      "The prompt may display only a deterministic subset ranked primarily",
      "by decreasing absolute v-test."
    ),
    paste(
      "The mechanical summary reports both the complete number retained and",
      "the smaller number displayed to the language model."
    ),
    paste(
      "Only rows that appear in the displayed tables may be named in the",
      "generated narrative. Counts describing the complete retained set are",
      "contextual information, not additional descriptors."
    ),
    "",
    "### Interpretation limits",
    paste(
      "The retained descriptors characterize the group relative to the full",
      "sample. They do not establish causality and need not apply to every",
      "individual in the group."
    ),
    paste(
      "The absence of a descriptor from the retained tables does not prove",
      "that the corresponding characteristic is absent."
    ),
    paste(
      "A descriptor should be called retained rather than statistically",
      "significant unless such wording is explicitly justified by the",
      "selected threshold."
    ),
    paste(
      "The number of retained descriptors and the magnitude of their v-tests",
      "are explicit numerical outputs. They are not converted into a",
      "qualitative strong, moderate, or weak profile classification."
    ),
    paste(
      "A sparse retained profile does not by itself establish poor sample",
      "representativeness, low reliability, inadequate sample size, low",
      "statistical power, weak evidence, or poor data quality."
    ),
    paste(
      "The analysis remains exploratory, particularly when many descriptors",
      "are examined or when categorical modalities are sparse."
    ),
    sep = "\n"
  )
}

build_request_catdes_prep <- function(
    profile_mode = c(
      "balanced",
      "categorical",
      "quantitative"
    )) {

  profile_mode <- match.arg(profile_mode)

  mode_rules <- switch(
    profile_mode,

    balanced = c(
      paste(
        "- Use both quantitative and categorical evidence when both",
        "corresponding tables contain rows."
      ),
      paste(
        "- When both tables contain rows, `Core group profile` and",
        "`Injectable summary` must each name at least one concrete",
        "quantitative descriptor and one concrete categorical modality."
      ),
      paste(
        "- When both tables contain rows, `Distinctive markers` must include",
        "at least one quantitative marker and one categorical marker."
      )
    ),

    categorical = c(
      "- Use only the displayed categorical table.",
      paste(
        "- Do not introduce quantitative variables, quantitative values,",
        "or higher/lower quantitative directions."
      )
    ),

    quantitative = c(
      "- Use only the displayed quantitative table.",
      paste(
        "- Do not introduce categorical modalities, percentages,",
        "over-representation, or under-representation."
      )
    )
  )

  paste(
    c(
      paste(
        "Using only the displayed statistical tables below, produce a short",
        "narrative profile of the group."
      ),
      "",
      paste(
        "The result will later be combined with a structured analysis of",
        "the group's open-ended texts."
      ),
      "",
      "## Evidence coverage",
      mode_rules,
      paste(
        "- Only descriptors appearing as rows in the displayed tables may",
        "be named."
      ),
      paste(
        "- Counts describing the complete retained set are contextual",
        "information and must not be used to invent additional descriptors."
      ),
      paste(
        "- When selecting descriptors for a short synthesis, prioritize rows",
        "appearing earlier in the displayed tables."
      ),
      "",
      "## Direction and interpretation",
      paste(
        "- Preserve the direction of every named descriptor exactly as shown",
        "in the displayed tables."
      ),
      paste(
        "- Describe positive quantitative directions as higher than overall",
        "and negative quantitative directions as lower than overall."
      ),
      paste(
        "- Describe positive categorical directions as over-represented and",
        "negative categorical directions as under-represented."
      ),
      paste(
        "- Never place a higher-than-overall descriptor in a clause introduced",
        "by `lower`, or a lower-than-overall descriptor in a clause introduced",
        "by `higher`."
      ),
      "- Use separate clauses for descriptors with opposite directions.",
      paste(
        "- Before finalizing the answer, cross-check every named variable",
        "and modality against its direction in the displayed tables."
      ),
      paste(
        "- Do not interpret a positive direction as favorable or a negative",
        "direction as unfavorable."
      ),
      "",
      "## Narrative constraints",
      paste(
        "- Name the concrete variables or modalities used. Do not use vague",
        "expressions such as `certain markers`, `some variables`,",
        "`various traits`, or `several descriptors`."
      ),
      paste(
        "- Do not use the words `unique`, `uniquely`, `exclusive`,",
        "`exceptional`, `representative`, or `non-representative`."
      ),
      paste(
        "- Do not introduce causal explanations, hidden motives, personality",
        "traits, moral qualities, or unobserved mechanisms."
      ),
      "- Do not generalize a group-level association to every individual.",
      paste(
        "- Refer to descriptors as retained rather than statistically",
        "significant unless significance is explicitly justified by the",
        "analysis settings."
      ),
      paste(
        "- Do not include numerical values, percentages, differences, v-tests,",
        "p-values, sample sizes, or any other numbers in `Core group profile`,",
        "`Distinctive markers`, or `Injectable summary`."
      ),
      paste(
        "- The exact numerical evidence is preserved mechanically outside the",
        "language-model narrative. Use only descriptor names and statistical",
        "directions in the three narrative fields."
      ),
      paste(
        "- Do not place any numerical value inside parentheses after a variable",
        "or modality name."
      ),
      "",
      "## Required output",
      "Use exactly the three fields below, in the specified order.",
      "",
      "Core group profile:",
      paste(
        "[Write one concrete sentence naming the main displayed descriptors",
        "and their correct directions relative to the full sample. Do not",
        "include numerical values."
      ),
      paste(
        "In balanced mode, when both tables contain rows, mention at least",
        "one quantitative descriptor and one categorical modality.]"
      ),
      "",
      "Distinctive markers:",
      paste(
        "[Write 1 to 3 concise synthesized markers, one bullet per line and",
        "beginning with `- `. Name the variables or modalities used and state",
        "their directions explicitly. Do not include numerical values."
      ),
      paste(
        "In balanced mode, when both tables contain rows, include at least",
        "one quantitative marker and one categorical marker.]"
      ),
      "",
      "Injectable summary:",
      paste(
        "[Write one concrete sentence reusable in a later contextualized",
        "interpretation. Name the displayed descriptors or modalities used",
        "and preserve their directions. Do not include numerical values."
      ),
      paste(
        "In balanced mode, when both tables contain rows, mention at least",
        "one quantitative descriptor and one categorical modality.]"
      )
    ),
    collapse = "\n"
  )
}

build_conclusion_catdes_prep <- function() {
  paste(
    "# Output constraint",
    paste(
      "Begin directly with `Core group profile:`.",
      "Do not add any preamble, introduction, explanation, or closing remark."
    ),
    paste(
      "Use each of the following field labels exactly once and in the",
      "order shown."
    ),
    "Do not number the fields.",
    "Do not convert the field labels into Markdown headings.",
    "Do not repeat instructions, examples, templates, or placeholders.",
    "The only permitted field labels are:",
    "Core group profile:",
    "Distinctive markers:",
    "Injectable summary:",
    sep = "\n"
  )
}

# ---------------------------------------------------------------------------
# Structured parser
# ---------------------------------------------------------------------------

.strip_markdown_fences_catdesprep <- function(text) {
  text <- gsub("(?m)^\\s*```[^\\n]*\\n?", "", text, perl = TRUE)
  text <- gsub("(?m)^\\s*```\\s*$", "", text, perl = TRUE)
  text
}

.extract_field_block_catdesprep <- function(text,
                                             field,
                                             next_fields = NULL) {
  escaped_field <- gsub(
    "([][{}()+*^$|\\\\?.])",
    "\\\\\\1",
    field
  )

  field_prefix <- "(?:(?:[-*+]|\\d+[.)])\\s*)?"
  markdown_prefix <- "(?:\\*\\*|__|###?\\s*)?"

  if (is.null(next_fields) || length(next_fields) == 0) {
    pattern <- paste0(
      "(?is)",
      "(?:^|\\n)\\s*",
      field_prefix,
      markdown_prefix,
      "\\s*",
      escaped_field,
      "\\s*:?\\s*(?:\\*\\*|__)?\\s*\\n?",
      "(.*)$"
    )
  } else {
    escaped_next <- vapply(
      next_fields,
      function(x) {
        gsub(
          "([][{}()+*^$|\\\\?.])",
          "\\\\\\1",
          x
        )
      },
      character(1)
    )

    next_pattern <- paste(
      paste0(
        field_prefix,
        markdown_prefix,
        "\\s*",
        escaped_next,
        "\\s*:?(?:\\*\\*|__)?"
      ),
      collapse = "|"
    )

    pattern <- paste0(
      "(?is)",
      "(?:^|\\n)\\s*",
      field_prefix,
      markdown_prefix,
      "\\s*",
      escaped_field,
      "\\s*:?\\s*(?:\\*\\*|__)?\\s*\\n?",
      "(.*?)",
      "(?=\\n\\s*(?:", next_pattern, ")|$)"
    )
  }

  match_object <- regexec(pattern, text, perl = TRUE)
  matched <- regmatches(text, match_object)[[1]]

  if (length(matched) >= 2) {
    trimws(matched[2])
  } else {
    NA_character_
  }
}

.clean_field_catdesprep <- function(x) {
  if (length(x) == 0 || is.na(x) || !nzchar(trimws(x))) {
    return(NA_character_)
  }

  x <- trimws(x)
  x <- gsub("^(?:[-*+]|\\d+[.)])\\s*", "", x, perl = TRUE)
  x <- gsub("\\n+", " ", x)
  x <- gsub("[[:space:]]+", " ", x)
  trimws(x)
}

.split_field_catdesprep <- function(x, none_words = c("none")) {
  if (length(x) == 0 || is.na(x) || !nzchar(trimws(x))) {
    return(character(0))
  }

  x <- trimws(x)

  if (grepl("\\|\\|", x, perl = TRUE)) {
    values <- unlist(
      strsplit(
        x,
        "\\s*\\|\\|\\s*",
        perl = TRUE
      )
    )
  } else {
    lines <- strsplit(x, "\\n", fixed = FALSE)[[1]]
    nonempty_lines <- lines[nzchar(trimws(lines))]
    bullet_lines <- grepl(
      "^\\s*(?:[-*+]\\s+|\\d+[.)]\\s+)",
      nonempty_lines,
      perl = TRUE
    )

    if (length(nonempty_lines) > 1 && all(bullet_lines)) {
      values <- nonempty_lines
    } else {
      values <- gsub("\\n+", " ", x)
    }
  }

  values <- trimws(values)
  values <- values[nzchar(values)]

  # Remove one or more repeated bullet/numbering prefixes. This also cleans
  # model outputs such as "- - Label=Chinon".
  values <- gsub(
    "^(?:(?:[-*+]\\s+|\\d+[.)]\\s+))+",
    "",
    values,
    perl = TRUE
  )

  values <- gsub("[[:space:]]+", " ", values)
  values <- trimws(values)
  values <- values[nzchar(values)]

  none_like <- vapply(
    values,
    function(value) {
      normalized <- tolower(trimws(value))

      any(
        normalized %in% tolower(none_words)
      ) ||
        grepl(
          "^none\\b",
          normalized,
          perl = TRUE
        )
    },
    logical(1)
  )

  values <- values[!none_like]

  if (length(values) == 0) {
    return(character(0))
  }

  values
}

.standard_statistical_caution_catdesprep <- function() {
  paste(
    "These descriptors characterize the group relative to the full sample",
    "under the variables and analysis settings used; they are associations,",
    "are not causal, and need not apply to every individual."
  )
}


.empty_parsed_catdesprep <- function() {
  list(
    core_group_profile = NA_character_,
    quantitative_traits = character(0),
    categorical_traits = character(0),
    distinctive_markers = character(0),
    statistical_caution = NA_character_,
    injectable_summary = NA_character_
  )
}

parse_catdes_prep_response <- function(text) {
  text <- paste(text, collapse = "\n")
  text <- gsub("\r\n", "\n", text, fixed = TRUE)
  text <- gsub("\r", "\n", text, fixed = TRUE)
  text <- .strip_markdown_fences_catdesprep(text)

  text <- gsub(
    "(?im)^\\s*here is the output[^\\n]*\\n?",
    "",
    text,
    perl = TRUE
  )
  text <- gsub(
    "(?im)^\\s*output\\s*:?\\s*\\n?",
    "",
    text,
    perl = TRUE
  )

  # Compatibility with wording and field labels used by earlier versions.
  text <- gsub(
    "Central statistical markers",
    "Distinctive markers",
    text,
    ignore.case = TRUE
  )

  # The current prompt requests three narrative fields. The older field labels
  # remain in this boundary list so that previously generated six-field
  # responses can still be parsed without contaminating adjacent fields.
  field_order <- c(
    "Core group profile",
    "Distinctive quantitative traits",
    "Distinctive categorical traits",
    "Distinctive markers",
    "Statistical caution",
    "Injectable summary"
  )

  get_block <- function(field) {
    idx <- match(field, field_order)

    next_fields <- if (!is.na(idx) && idx < length(field_order)) {
      field_order[(idx + 1):length(field_order)]
    } else {
      NULL
    }

    .extract_field_block_catdesprep(
      text,
      field,
      next_fields = next_fields
    )
  }

  list(
    core_group_profile = .clean_field_catdesprep(
      get_block("Core group profile")
    ),
    quantitative_traits = character(0),
    categorical_traits = character(0),
    distinctive_markers = .split_field_catdesprep(
      get_block("Distinctive markers")
    ),
    statistical_caution =
      .standard_statistical_caution_catdesprep(),
    injectable_summary = .clean_field_catdesprep(
      get_block("Injectable summary")
    )
  )
}

.format_trait_number_catdesprep <- function(x, digits = 6) {
  x <- suppressWarnings(
    as.numeric(as.character(x))
  )

  if (
    length(x) != 1 ||
    is.na(x) ||
    !is.finite(x)
  ) {
    return(NA_character_)
  }

  use_scientific <- (
    x != 0 &&
      (
        abs(x) < 1e-4 ||
          abs(x) >= 1e6
      )
  )

  format(
    signif(x, digits = digits),
    scientific = use_scientific,
    trim = TRUE
  )
}


.format_trait_p_value_catdesprep <- function(x, digits = 6) {
  x <- suppressWarnings(
    as.numeric(as.character(x))
  )

  if (
    length(x) != 1 ||
    is.na(x) ||
    !is.finite(x)
  ) {
    return(NA_character_)
  }

  use_scientific <- (
    x != 0 &&
      x < 1e-4
  )

  format(
    signif(x, digits = digits),
    scientific = use_scientific,
    trim = TRUE
  )
}


.build_quantitative_traits_catdesprep <- function(df) {
  if (is.null(df) || nrow(df) == 0) {
    return(character(0))
  }

  vapply(
    seq_len(nrow(df)),
    function(i) {
      row <- df[i, , drop = FALSE]

      variable <- if ("Variable" %in% names(row)) {
        as.character(row[["Variable"]][1])
      } else {
        NA_character_
      }

      direction <- if ("direction" %in% names(row)) {
        as.character(row[["direction"]][1])
      } else {
        NA_character_
      }

      group_mean <- if ("Mean in category" %in% names(row)) {
        .format_trait_number_catdesprep(
          row[["Mean in category"]][1]
        )
      } else {
        NA_character_
      }

      overall_mean <- if ("Overall mean" %in% names(row)) {
        .format_trait_number_catdesprep(
          row[["Overall mean"]][1]
        )
      } else {
        NA_character_
      }

      v_test <- if ("v.test" %in% names(row)) {
        .format_trait_number_catdesprep(
          row[["v.test"]][1]
        )
      } else {
        NA_character_
      }

      p_value <- if ("p.value" %in% names(row)) {
        .format_trait_p_value_catdesprep(
          row[["p.value"]][1]
        )
      } else {
        NA_character_
      }

      parts <- c(
        variable,
        if (!is.na(direction)) {
          paste0("direction = ", direction)
        },
        if (!is.na(group_mean)) {
          paste0("group mean = ", group_mean)
        },
        if (!is.na(overall_mean)) {
          paste0("overall mean = ", overall_mean)
        },
        if (!is.na(v_test)) {
          paste0("v-test = ", v_test)
        },
        if (!is.na(p_value)) {
          paste0("p-value = ", p_value)
        }
      )

      parts <- parts[
        !is.na(parts) &
          nzchar(trimws(parts))
      ]

      paste(
        parts,
        collapse = "; "
      )
    },
    character(1)
  )
}


.build_categorical_traits_catdesprep <- function(df) {
  if (is.null(df) || nrow(df) == 0) {
    return(character(0))
  }

  vapply(
    seq_len(nrow(df)),
    function(i) {
      row <- df[i, , drop = FALSE]

      modality <- if ("Modality" %in% names(row)) {
        as.character(row[["Modality"]][1])
      } else {
        NA_character_
      }

      direction <- if ("direction" %in% names(row)) {
        as.character(row[["direction"]][1])
      } else {
        NA_character_
      }

      cla_mod <- if ("Cla/Mod" %in% names(row)) {
        .format_trait_number_catdesprep(
          row[["Cla/Mod"]][1]
        )
      } else {
        NA_character_
      }

      mod_cla <- if ("Mod/Cla" %in% names(row)) {
        .format_trait_number_catdesprep(
          row[["Mod/Cla"]][1]
        )
      } else {
        NA_character_
      }

      global <- if ("Global" %in% names(row)) {
        .format_trait_number_catdesprep(
          row[["Global"]][1]
        )
      } else {
        NA_character_
      }

      v_test <- if ("v.test" %in% names(row)) {
        .format_trait_number_catdesprep(
          row[["v.test"]][1]
        )
      } else {
        NA_character_
      }

      p_value <- if ("p.value" %in% names(row)) {
        .format_trait_p_value_catdesprep(
          row[["p.value"]][1]
        )
      } else {
        NA_character_
      }

      parts <- c(
        modality,
        if (!is.na(direction)) {
          paste0("direction = ", direction)
        },
        if (!is.na(cla_mod)) {
          paste0("Cla/Mod = ", cla_mod)
        },
        if (!is.na(mod_cla)) {
          paste0("Mod/Cla = ", mod_cla)
        },
        if (!is.na(global)) {
          paste0("Global = ", global)
        },
        if (!is.na(v_test)) {
          paste0("v-test = ", v_test)
        },
        if (!is.na(p_value)) {
          paste0("p-value = ", p_value)
        }
      )

      parts <- parts[
        !is.na(parts) &
          nzchar(trimws(parts))
      ]

      paste(
        parts,
        collapse = "; "
      )
    },
    character(1)
  )
}

.strip_numeric_parentheticals_catdesprep <- function(x) {
  if (
    length(x) == 0 ||
    all(is.na(x))
  ) {
    return(x)
  }

  out <- gsub(
    paste0(
      "\\s*\\(",
      "\\s*[<>\u2264\u2265=]?\\s*",
      "[-+]?",
      "(?:\\d+(?:[.,]\\d*)?|[.,]\\d+)",
      "(?:[eE][-+]?\\d+)?",
      "\\s*\\)"
    ),
    "",
    x,
    perl = TRUE
  )

  out <- gsub(
    "[[:space:]]+",
    " ",
    out
  )

  trimws(out)
}
# ---------------------------------------------------------------------------
# Prompt assembly
# ---------------------------------------------------------------------------

get_prompt_catdes_prep <- function(mechanical_profiles,
                                    introduction,
                                    request,
                                    conclusion,
                                    profile_mode = c("balanced", "categorical", "quantitative"),
                                    include_metrics_in_prompt = TRUE) {
  profile_mode <- match.arg(profile_mode)

  group_blocks <- get_sentences_catdes_prep(
    mechanical_profiles = mechanical_profiles,
    profile_mode = profile_mode,
    include_metrics_in_prompt = include_metrics_in_prompt
  )

  if (length(group_blocks) == 0) {
    stop(
      "No group was available in the `catdes` result.",
      call. = FALSE
    )
  }

  prompts <- lapply(names(group_blocks), function(group_name) {
    data_text <- paste0(
      "## Group '",
      group_name,
      "'\n\n",
      group_blocks[[group_name]]
    )

    build_standard_prompt(
      introduction = introduction,
      request = request,
      data = data_text,
      conclusion = conclusion
    )
  })

  names(prompts) <- names(group_blocks)
  prompts
}


# ---------------------------------------------------------------------------
# Main function
# ---------------------------------------------------------------------------

#' Prepare structured `catdes` profiles for later contextualization
#'
#' Runs or reuses [FactoMineR::catdes()], preserves the retained statistical
#' descriptors for every group, constructs one controlled prompt per group,
#' and optionally parses one language-model response per group into a stable
#' object intended for later contextualization.
#'
#' `nail_catdes_prep()` is the statistical counterpart of
#' [nail_textual_prep()]. It prepares the external statistical profile that may
#' later be combined with the structured textual profile in
#' [nail_textual_contextualized()].
#'
#' The suffix `_prep` refers to the complete preparation workflow. Parsing is
#' one part of that workflow, but the function also computes or retrieves the
#' `catdes()` result, standardizes the retained tables, selects the descriptors
#' displayed in each prompt, calculates explicit mechanical summaries, and
#' preserves the exact statistical evidence used for generation.
#'
#' @param x Optional raw result returned by [FactoMineR::catdes()], or an object
#'   carrying such a result in a `"catdes_result"` attribute. In particular,
#'   an object returned by [nail_catdes()] can be supplied directly because
#'   `nail_catdes()` preserves its underlying `catdes()` result.
#'
#'   Supply exactly one of `x` or `dataset`.
#'
#'   When `x` is supplied, `exclude` and `row.w` cannot be applied because the
#'   analysis has already been computed. The value of `proba` is then stored as
#'   declared metadata; the function cannot verify the threshold originally
#'   used to compute `x`.
#' @param dataset Optional data frame from which [FactoMineR::catdes()] is
#'   computed. Supply exactly one of `dataset` or `x`.
#'
#'   Character columns retained in the prepared data are converted to factors.
#'   Numeric columns remain numeric. The grouping variable is converted to a
#'   factor when necessary.
#' @param num.var A single integer giving the column index of the grouping
#'   variable in the original `dataset`. It is required when `dataset` is
#'   supplied.
#' @param exclude Optional column indices or column names removed before
#'   `catdes()` is computed.
#'
#'   This argument should be used for identifiers, open-ended text columns,
#'   technical variables, and any other columns that should not participate in
#'   the external statistical characterization of the groups. The grouping
#'   variable cannot be excluded.
#' @param proba A single numeric value in ]0, 1] forwarded to
#'   [FactoMineR::catdes()] when `dataset` is supplied. The default is `0.05`.
#'
#'   When `x` is supplied, this value is recorded only as declared metadata.
#' @param sample.pct A single numeric value in ]0, 1] controlling the
#'   proportion of descriptors retained by `catdes()` that are displayed in
#'   each prompt.
#'
#'   This is a deterministic selection rather than random sampling. Within
#'   each descriptor type, rows are ranked by decreasing absolute v-test and
#'   then by increasing p-value. The complete retained tables remain available
#'   in the mechanical profile.
#' @param top_n_quanti A single non-negative integer giving the maximum number
#'   of quantitative descriptors displayed in each prompt. The default is `5`.
#' @param top_n_quali A single non-negative integer giving the maximum number
#'   of categorical descriptors displayed in each prompt. The default is `5`.
#' @param profile_mode One of `"balanced"`, `"categorical"`, or
#'   `"quantitative"`.
#'
#'   `"balanced"` displays both types when available. The other modes restrict
#'   the prompt to one descriptor type, while the complete mechanical profile
#'   still preserves all retained results.
#' @param prompt_style One of `"compact"` or `"detailed"`. This controls the
#'   amount of statistical guidance included in the prompt. It does not change
#'   the underlying `catdes()` result or the descriptor selection.
#' @param include_metrics_in_prompt Logical indicating whether the mechanical
#'   descriptor summary is displayed before the statistical tables.
#'
#'   The summary distinguishes the descriptors retained by `catdes()` from the
#'   subset shown in the prompt. It reports numerical quantities only and does
#'   not create a qualitative strong/moderate/weak classification.
#' @param introduction Optional common introduction added to every group
#'   prompt. If `NULL`, a generic introduction is created.
#' @param request Optional request block. If `NULL`, the function uses its
#'   internal default request builder.
#'
#'   A custom request used with `generate = TRUE` should ask for the three
#'   narrative labels `Core group profile:`, `Distinctive markers:`, and
#'   `Injectable summary:`. Quantitative traits, categorical traits, and the
#'   statistical caution are constructed mechanically and are not taken from
#'   the language-model response.
#' @param conclusion Optional output-constraint block. If `NULL`, the
#'   function uses its internal default output constraint.
#'
#'   A custom conclusion used with `generate = TRUE` should preserve the same
#'   three narrative labels and their order so that the response can be parsed
#'   automatically.
#' @param model Character string giving the language model used by the selected
#'   provider. The default is `"llama3"`.
#' @param provider LLM backend, one of `"ollama"` or `"gemini"`.
#' @param row.w Optional non-negative row weights forwarded to `catdes()` when
#'   `dataset` is supplied. The vector must have length `nrow(dataset)` and a
#'   positive sum.
#' @param generate Logical.
#'
#'   If `FALSE`, no language model is called and the function returns one
#'   structured prompt per group.
#'
#'   If `TRUE`, one request is sent independently for each group and the
#'   generated response is parsed.
#' @param ... Additional provider-specific generation arguments passed to the
#'   selected LLM backend.
#'
#' @details
#' ## Statistical directions
#'
#' For quantitative variables, a positive v-test means that the group value is
#' higher than the overall value, whereas a negative v-test means that it is
#' lower.
#'
#' For categorical variables, positive and negative v-tests indicate
#' over-representation and under-representation, respectively, under the
#' current analysis.
#'
#' These signs are mathematical directions. They do not indicate favorable or
#' unfavorable qualities, superiority, inferiority, desirability, or value.
#'
#' ## Mechanical profile
#'
#' Every group profile contains:
#'
#' - `quantitative`: the complete retained quantitative table;
#' - `categorical`: the complete retained categorical table;
#' - `selected_for_prompt`: the deterministic subsets actually displayed to
#'   the language model;
#' - `salient_quantitative_traits` and `salient_categorical_traits`;
#' - `metrics$retained`: summaries of all descriptors retained by `catdes()`;
#' - `metrics$shown_in_prompt`: summaries of the smaller displayed subsets.
#'
#' Each metrics component contains counts of retained descriptors and signed
#' v-tests, the maximum and median absolute v-test, and the smallest p-value.
#' These are explicit numerical summaries. No qualitative profile-strength
#' label is calculated or returned.
#'
#' Small p-values are formatted with [base::format.pval()] before they are
#' inserted into the prompt. A non-zero p-value is therefore not rounded and
#' displayed as zero merely because it is smaller than three decimal places.
#'
#' ## Descriptor selection
#'
#' `sample.pct`, `top_n_quanti`, and `top_n_quali` change only the information
#' displayed in the prompt. They do not modify the complete `catdes()` result
#' or the complete retained tables stored in the mechanical profile.
#'
#' The prompt explicitly reports both the number of descriptors retained and
#' the number shown. This prevents a selected prompt subset from being confused
#' with the complete statistical result.
#'
#' ## Parsed profile
#'
#' The current prompt asks the language model for three narrative fields only:
#'
#' ```
#' Core group profile: ...
#' Distinctive markers: ...
#' Injectable summary: ...
#' ```
#'
#' The language model is therefore used for synthesis rather than for copying
#' numerical tables. The parser also tolerates the six-field layout used by
#' earlier exploratory versions, but generated quantitative traits,
#' categorical traits, and statistical cautions are ignored.
#'
#' The final parsed object always retains six components. Their origins are:
#'
#' - `core_group_profile`: parsed from the language-model response;
#' - `quantitative_traits`: constructed mechanically from the exact
#'   quantitative rows displayed in the prompt;
#' - `categorical_traits`: constructed mechanically from the exact categorical
#'   rows displayed in the prompt;
#' - `distinctive_markers`: parsed from the language-model response;
#' - `statistical_caution`: assigned mechanically from a fixed,
#'   methodologically conservative sentence;
#' - `injectable_summary`: parsed from the language-model response, with
#'   `core_group_profile` used as a fallback when the field is omitted.
#'
#' The two trait vectors preserve every displayed descriptor exactly once and
#' in table order. They retain the descriptor name, statistical direction,
#' available group and overall values or percentages, v-test, and p-value.
#' Their completeness therefore does not depend on language-model compliance.
#'
#' The narrative fields are instructed to name concrete displayed descriptors,
#' preserve their directions, avoid vague placeholders, and avoid unsupported
#' claims of uniqueness, representativeness, causality, or individual-level
#' generality.
#'
#' ## Statistical caution
#'
#' `statistical_caution` is not generated by the language model and is not a
#' qualitative profile-strength score. It is assigned mechanically to state
#' that the descriptors characterize the group relative to the full sample
#' under the variables and analysis settings used, describe associations rather
#' than causal effects, and need not apply to every individual.
#'
#' ## Excluding textual and technical variables
#'
#' Open-ended text columns should normally be excluded. Otherwise, distinct
#' responses may be interpreted as categorical modalities and contaminate the
#' external statistical profile intended to complement the textual analysis.
#'
#' ## Interpretation limits
#'
#' Retained descriptors characterize a group relative to the full sample. They
#' do not establish causality, do not describe every individual, and do not
#' prove that an omitted descriptor is absent. Results should be treated as
#' exploratory when many descriptors are tested or categories are sparse.
#'
#' @return
#' With `generate = FALSE`, a named list of character prompts is returned, with
#' one element per group.
#'
#' With `generate = TRUE`, a named list is returned, with one element per
#' group. Each element contains:
#'
#' - `prompt`: the exact prompt sent to the selected backend;
#' - `response`: the raw generated response stored as one character string;
#' - `parsed`: the structured fields extracted from the response;
#' - `mechanical_profile`: the retained statistical evidence and explicit
#'   metrics for the group.
#'
#' The parsed component contains:
#'
#' - `core_group_profile`: narrative synthesis parsed from the model response;
#' - `quantitative_traits`: mechanically constructed from the displayed
#'   quantitative table;
#' - `categorical_traits`: mechanically constructed from the displayed
#'   categorical table;
#' - `distinctive_markers`: concise narrative markers parsed from the model
#'   response;
#' - `statistical_caution`: mechanically assigned conservative scope
#'   statement;
#' - `injectable_summary`: narrative synthesis parsed from the model response,
#'   with a fallback to `core_group_profile` if omitted.
#'
#' The complete returned object has the following attributes:
#'
#' - `"catdes_result"`: the raw [FactoMineR::catdes()] result;
#' - `"catdes_profiles"`: all mechanical group profiles;
#' - `"catdes_input"`: source, exclusion, and prepared-data metadata;
#' - `"catdes_settings"`: threshold and prompt-selection settings.
#'
#' @seealso [FactoMineR::catdes()], [nail_catdes()],
#'   [nail_textual_prep()], [nail_textual_contextualized()]
#'
#' @export
#'
#' @examples
#' ### Example 1: Fisher's iris data, without an LLM ###
#'
#' data(iris)
#'
#' iris_prompts <- nail_catdes_prep(
#'   dataset = iris,
#'   num.var = 5,
#'   proba = 0.05,
#'   profile_mode = "quantitative",
#'   generate = FALSE
#' )
#'
#' # One structured prompt is prepared for each species.
#' names(iris_prompts)
#'
#' # Display one prompt and inspect its complete mechanical profile.
#' cat(iris_prompts[["setosa"]])
#' attr(iris_prompts, "catdes_profiles")[["setosa"]]
#'
#'
#' ### Example 2: reuse the analytical result preserved by nail_catdes() ###
#'
#' iris_catdes_prompt <- nail_catdes(
#'   dataset = iris,
#'   num.var = 5,
#'   isolate.groups = TRUE,
#'   proba = 0.05,
#'   generate = FALSE
#' )
#'
#' iris_prep_from_nail <- nail_catdes_prep(
#'   x = iris_catdes_prompt,
#'   proba = 0.05,
#'   profile_mode = "quantitative",
#'   generate = FALSE
#' )
#'
#' names(iris_prep_from_nail)
#' attr(iris_prep_from_nail, "catdes_input")
#'
#'
#' \dontrun{
#' # The following examples either call an LLM or compute an MCA and HCPC.
#' library(FactoMineR)
#'
#'
#' ### Example 3: generate structured iris profiles ###
#'
#' iris_generated <- nail_catdes_prep(
#'   dataset = iris,
#'   num.var = 5,
#'   proba = 0.05,
#'   profile_mode = "quantitative",
#'   provider = "ollama",
#'   model = "llama3",
#'   generate = TRUE
#' )
#'
#' cat(iris_generated[["setosa"]]$response)
#' iris_generated[["setosa"]]$parsed
#' iris_generated[["setosa"]]$mechanical_profile
#'
#'
#' ### Example 4: food-waste clusters used by nail_catdes() ###
#'
#' data(waste)
#' waste_work <- waste[-14]
#'
#' set.seed(1)
#' waste_mca <- MCA(
#'   waste_work,
#'   quali.sup = c(1, 2, 50:76),
#'   ncp = 35,
#'   level.ventil = 0.05,
#'   graph = FALSE
#' )
#'
#' waste_hcpc <- HCPC(
#'   waste_mca,
#'   nb.clust = 3,
#'   graph = FALSE
#' )
#'
#' waste_clusters <- waste_hcpc$data.clust
#'
#' waste_prep <- nail_catdes_prep(
#'   dataset = waste_clusters,
#'   num.var = ncol(waste_clusters),
#'   introduction = paste(
#'     "These data were collected in a survey on food waste.",
#'     "The groups were obtained from an MCA followed by HCPC."
#'   ),
#'   sample.pct = 0.75,
#'   top_n_quanti = 5,
#'   top_n_quali = 8,
#'   provider = "ollama",
#'   model = "llama3",
#'   generate = TRUE
#' )
#'
#' cat(waste_prep[[1]]$response)
#'
#'
#' ### Example 5: sustainable-food clusters used by nail_catdes() ###
#'
#' data(local_food)
#'
#' set.seed(1)
#' food_mca <- MCA(
#'   local_food,
#'   quali.sup = 46:63,
#'   ncp = 100,
#'   level.ventil = 0.05,
#'   graph = FALSE
#' )
#'
#' food_hcpc <- HCPC(
#'   food_mca,
#'   nb.clust = 3,
#'   graph = FALSE
#' )
#'
#' food_clusters <- food_hcpc$data.clust
#'
#' food_prep <- nail_catdes_prep(
#'   dataset = food_clusters,
#'   num.var = ncol(food_clusters),
#'   introduction = paste(
#'     "This study concerns sustainable food systems.",
#'     "The groups were obtained from an MCA followed by HCPC."
#'   ),
#'   sample.pct = 0.50,
#'   top_n_quali = 10,
#'   provider = "ollama",
#'   model = "llama3",
#'   generate = TRUE
#' )
#'
#' cat(food_prep[[1]]$response)
#' }
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
  profile_mode <- match.arg(profile_mode)
  prompt_style <- match.arg(prompt_style)
  provider <- match.arg(provider)

  validate_catdes_prep_inputs(
    x = x,
    dataset = dataset,
    num.var = num.var,
    exclude = exclude,
    proba = proba,
    sample.pct = sample.pct,
    top_n_quanti = top_n_quanti,
    top_n_quali = top_n_quali,
    profile_mode = profile_mode,
    prompt_style = prompt_style,
    include_metrics_in_prompt = include_metrics_in_prompt,
    row.w = row.w,
    generate = generate
  )

  extracted <- .extract_catdes_input_catdesprep(
    x = x,
    dataset = dataset,
    num.var = num.var,
    exclude = exclude,
    proba = proba,
    row.w = row.w
  )

  catdes_result <- extracted$catdes_result

  mechanical_profiles <- .build_catdes_profiles_mechanical(
    catdes_result = catdes_result,
    group_names = extracted$group_names,
    sample.pct = sample.pct,
    top_n_quanti = top_n_quanti,
    top_n_quali = top_n_quali,
    profile_mode = profile_mode
  )

  if (length(mechanical_profiles) == 0) {
    stop(
      "No group could be identified from the supplied data or `catdes` result.",
      call. = FALSE
    )
  }

  if (is.null(introduction)) {
    introduction <- paste(
      "The results below characterize one group relative to the full sample using descriptors retained by a `catdes` analysis.",
      "The goal is to prepare a short statistical profile that can later be combined with a structured analysis of the group's open-ended texts."
    )
  }

  if (is.null(request)) {
    request <- build_request_catdes_prep(profile_mode = profile_mode)
  }

  if (is.null(conclusion)) {
    conclusion <- build_conclusion_catdes_prep()
  }

  guide <- build_guide_catdes_prep(
    proba = proba,
    profile_mode = profile_mode,
    prompt_style = prompt_style,
    source = extracted$input_metadata$source
  )

  introduction <- paste(introduction, guide, sep = "\n\n---\n\n")

  prompts <- get_prompt_catdes_prep(
    mechanical_profiles = mechanical_profiles,
    introduction = introduction,
    request = request,
    conclusion = conclusion,
    profile_mode = profile_mode,
    include_metrics_in_prompt = include_metrics_in_prompt
  )

  settings <- list(
    proba = proba,
    proba_applied_by_function = isTRUE(
      extracted$input_metadata$proba_applied_by_function
    ),
    sample.pct = sample.pct,
    top_n_quanti = top_n_quanti,
    top_n_quali = top_n_quali,
    profile_mode = profile_mode,
    prompt_style = prompt_style,
    include_metrics_in_prompt = include_metrics_in_prompt,
    provider = provider,
    model = model,
    generate = generate
  )

  attach_attributes <- function(object) {
    attr(object, "catdes_result") <- catdes_result
    attr(object, "catdes_profiles") <- mechanical_profiles
    attr(object, "catdes_input") <- extracted$input_metadata
    attr(object, "catdes_settings") <- settings
    class(object) <- unique(c("nail_catdes_prep", class(object)))
    object
  }

  if (!generate) {
    return(attach_attributes(prompts))
  }

  llm_api_options <- list(...)

  generated <- lapply(prompts, function(prompt) {
    result <- .call_llm_base(
      provider = provider,
      model = model,
      prompt = prompt,
      output = "df",
      llm_api_options = llm_api_options
    )
    result$prompt <- prompt
    result
  })
  names(generated) <- names(prompts)

  out <- lapply(
    names(generated),
    function(group_name) {
      generated_group <- generated[[group_name]]

      response_text <- if (!is.null(generated_group$response)) {
        paste(
          generated_group$response,
          collapse = "\n"
        )
      } else {
        ""
      }

      parsed <- tryCatch(
        parse_catdes_prep_response(response_text),
        error = function(e) {
          .empty_parsed_catdesprep()
        }
      )

      mechanical_profile <-
        mechanical_profiles[[group_name]]

      shown_profile <-
        mechanical_profile$selected_for_prompt

      # These two fields are constructed mechanically from the exact
      # descriptor rows shown in the prompt.
      parsed$quantitative_traits <-
        .build_quantitative_traits_catdesprep(
          shown_profile$quantitative
        )

      parsed$categorical_traits <-
        .build_categorical_traits_catdesprep(
          shown_profile$categorical
        )

      # Statistical caution is standardized and does not depend on the LLM.
      parsed$statistical_caution <-
        .standard_statistical_caution_catdesprep()

      # Narrative fallback when one of the two synthesis fields is missing.
      core_missing <- (
        length(parsed$core_group_profile) == 0 ||
          is.na(parsed$core_group_profile) ||
          !nzchar(trimws(parsed$core_group_profile))
      )

      summary_missing <- (
        length(parsed$injectable_summary) == 0 ||
          is.na(parsed$injectable_summary) ||
          !nzchar(trimws(parsed$injectable_summary))
      )

      if (core_missing && !summary_missing) {
        parsed$core_group_profile <-
          parsed$injectable_summary
      }

      if (summary_missing && !core_missing) {
        parsed$injectable_summary <-
          parsed$core_group_profile
      }

      # Remove numerical parenthetical additions invented by the LLM
      # from the narrative fields only.
      parsed$core_group_profile <-
        .strip_numeric_parentheticals_catdesprep(
          parsed$core_group_profile
        )

      parsed$distinctive_markers <-
        .strip_numeric_parentheticals_catdesprep(
          parsed$distinctive_markers
        )

      parsed$injectable_summary <-
        .strip_numeric_parentheticals_catdesprep(
          parsed$injectable_summary
        )

      list(
        prompt = prompts[[group_name]],
        response = response_text,
        parsed = parsed,
        mechanical_profile = mechanical_profile
      )
    }
  )

  names(out) <- names(generated)

  attach_attributes(out)
}

# ---------------------------------------------------------------------------
# Backward-compatible alias
# ---------------------------------------------------------------------------

#' @rdname nail_catdes_prep
#' @export
nail_group_profile_prep <- function(...) {
  .Deprecated(
    new = "nail_catdes_prep",
    package = "NaileR"
  )
  nail_catdes_prep(...)
}
