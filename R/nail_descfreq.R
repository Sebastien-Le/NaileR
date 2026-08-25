#' @importFrom FactoMineR descfreq
#' @importFrom utils globalVariables
utils::globalVariables(c())

# ---------------------------------------------------------------------------
# Validation and input normalization
# ---------------------------------------------------------------------------

.validate_descfreq_table <- function(dataset) {
  if (!is.data.frame(dataset)) {
    stop("`dataset` must be a data frame corresponding to a contingency table.", call. = FALSE)
  }

  if (nrow(dataset) < 1L || ncol(dataset) < 2L) {
    stop("`dataset` must contain at least one row and two columns.", call. = FALSE)
  }

  numeric_cols <- vapply(dataset, is.numeric, logical(1))
  if (!all(numeric_cols)) {
    stop("Every column of `dataset` must be numeric.", call. = FALSE)
  }

  values <- as.matrix(dataset)
  storage.mode(values) <- "double"

  if (any(!is.finite(values))) {
    stop("`dataset` must contain only finite contingency frequencies.", call. = FALSE)
  }

  if (any(values < 0)) {
    stop("`dataset` cannot contain negative frequencies.", call. = FALSE)
  }

  integer_like <- abs(values - round(values)) <= sqrt(.Machine$double.eps)
  if (!all(integer_like)) {
    stop(
      paste(
        "`dataset` must contain non-negative integer-like frequencies.",
        "`FactoMineR::descfreq()` uses a hypergeometric test on contingency counts."
      ),
      call. = FALSE
    )
  }

  row_totals <- rowSums(values)
  col_totals <- colSums(values)

  if (any(row_totals <= 0)) {
    stop("Every row of `dataset` must have a strictly positive total.", call. = FALSE)
  }

  if (any(col_totals <= 0)) {
    stop(
      paste(
        "Every column of `dataset` must have a strictly positive total.",
        "Remove all-zero columns before calling `nail_descfreq()`."
      ),
      call. = FALSE
    )
  }

  column_names <- colnames(dataset)
  if (is.null(column_names) ||
      anyNA(column_names) ||
      any(!nzchar(trimws(column_names))) ||
      anyDuplicated(column_names)) {
    stop("`dataset` must have unique non-empty column names.", call. = FALSE)
  }

  # FactoMineR replaces literal spaces by dots before assigning descriptor names
  # to its retained-marker tables. Detect collisions before the statistical call
  # so that the original descriptor can always be recovered unambiguously.
  factominer_names <- gsub(" ", ".", column_names, fixed = TRUE)
  if (anyDuplicated(factominer_names)) {
    stop(
      paste(
        "Column names become ambiguous after FactoMineR replaces spaces by dots.",
        "Rename the affected columns before calling `nail_descfreq()`."
      ),
      call. = FALSE
    )
  }

  invisible(TRUE)
}


.normalize_by_quali_descfreq <- function(by.quali, n_rows) {
  if (is.null(by.quali)) {
    return(NULL)
  }

  if (length(by.quali) != n_rows) {
    stop("`by.quali` must have one value per row of `dataset`.", call. = FALSE)
  }

  if (anyNA(by.quali)) {
    stop("`by.quali` cannot contain missing values.", call. = FALSE)
  }

  out <- droplevels(factor(by.quali))

  if (nlevels(out) < 1L) {
    stop("`by.quali` must define at least one non-empty group.", call. = FALSE)
  }

  out
}


validate_descfreq_inputs <- function(dataset,
                                     sample.pct,
                                     proba,
                                     isolate.groups,
                                     drop.negative,
                                     rows_are_ordered,
                                     explicit_row_labels,
                                     generate,
                                     by.quali = NULL) {
  .validate_descfreq_table(dataset)

  if (!is.numeric(sample.pct) ||
      length(sample.pct) != 1L ||
      is.na(sample.pct) ||
      !is.finite(sample.pct) ||
      sample.pct < 0 ||
      sample.pct > 1) {
    stop("`sample.pct` must be a single numeric value in [0, 1].", call. = FALSE)
  }

  if (!is.numeric(proba) ||
      length(proba) != 1L ||
      is.na(proba) ||
      !is.finite(proba) ||
      proba <= 0 ||
      proba > 1) {
    stop("`proba` must be a single numeric value in (0, 1].", call. = FALSE)
  }

  logical_args <- list(
    isolate.groups = isolate.groups,
    drop.negative = drop.negative,
    rows_are_ordered = rows_are_ordered,
    explicit_row_labels = explicit_row_labels,
    generate = generate
  )

  valid_logical <- vapply(
    logical_args,
    function(x) is.logical(x) && length(x) == 1L && !is.na(x),
    logical(1)
  )

  if (!all(valid_logical)) {
    stop(
      paste0(
        "The following arguments must be single non-missing logical values: ",
        paste(names(logical_args)[!valid_logical], collapse = ", "),
        "."
      ),
      call. = FALSE
    )
  }

  .normalize_by_quali_descfreq(by.quali, nrow(dataset))
  invisible(TRUE)
}


.aggregate_descfreq_table <- function(dataset, by.quali = NULL) {
  # The canonical analyzed contingency table is always stored as a numeric
  # matrix. This avoids data-frame row extraction returning list-like objects
  # and gives the same stable representation with and without `by.quali`.
  values <- as.matrix(dataset)
  storage.mode(values) <- "double"

  if (is.null(by.quali)) {
    return(values)
  }

  group <- .normalize_by_quali_descfreq(by.quali, nrow(dataset))
  levels_group <- levels(group)

  pieces <- lapply(
    levels_group,
    function(level) {
      colSums(
        values[group == level, , drop = FALSE]
      )
    }
  )

  mat <- do.call(rbind, pieces)
  rownames(mat) <- levels_group
  colnames(mat) <- colnames(dataset)
  storage.mode(mat) <- "double"

  mat
}



# ---------------------------------------------------------------------------
# Canonical frequency evidence
# ---------------------------------------------------------------------------

.empty_descfreq_marker_table <- function() {
  data.frame(
    evidence_id = character(0),
    row = character(0),
    attribute = character(0),
    direction = character(0),
    row_percentage = numeric(0),
    global_percentage = numeric(0),
    difference_percentage_points = numeric(0),
    row_frequency = numeric(0),
    global_frequency = numeric(0),
    p_value = numeric(0),
    v_test = numeric(0),
    abs_v_test = numeric(0),
    source_order = integer(0),
    rank = integer(0),
    source = character(0),
    stringsAsFactors = FALSE,
    check.names = FALSE
  )
}


.escape_descfreq_evidence_component <- function(x) {
  x <- as.character(x)[1L]
  x <- gsub("%", "%25", x, fixed = TRUE)
  gsub("::", "%3A%3A", x, fixed = TRUE)
}


.make_descfreq_evidence_id <- function(row, attribute) {
  paste(
    "DESCF",
    .escape_descfreq_evidence_component(row),
    .escape_descfreq_evidence_component(attribute),
    sep = "::"
  )
}


.descfreq_original_attribute <- function(label, original_names) {
  internal_names <- gsub(" ", ".", original_names, fixed = TRUE)
  index <- match(as.character(label), internal_names)

  if (is.na(index)) {
    index <- match(as.character(label), original_names)
  }

  if (is.na(index)) {
    stop(
      paste0(
        "Could not map the FactoMineR descriptor `", label,
        "` back to a source column."
      ),
      call. = FALSE
    )
  }

  original_names[[index]]
}


.normalize_descfreq_row_result <- function(x,
                                           row_name,
                                           original_names) {
  if (is.null(x)) {
    return(.empty_descfreq_marker_table())
  }

  raw <- as.data.frame(
    x,
    check.names = FALSE,
    stringsAsFactors = FALSE
  )

  if (nrow(raw) == 0L) {
    return(.empty_descfreq_marker_table())
  }

  names(raw) <- trimws(names(raw))

  required <- c(
    "Intern %",
    "glob %",
    "Intern freq",
    "Glob freq",
    "p.value",
    "v.test"
  )

  missing_cols <- setdiff(required, names(raw))
  if (length(missing_cols) > 0L) {
    stop(
      paste0(
        "The `FactoMineR::descfreq()` result is missing expected columns: ",
        paste(missing_cols, collapse = ", "),
        "."
      ),
      call. = FALSE
    )
  }

  source_labels <- rownames(raw)
  if (is.null(source_labels) ||
      length(source_labels) != nrow(raw)) {
    stop(
      "The `FactoMineR::descfreq()` result has no usable descriptor labels.",
      call. = FALSE
    )
  }

  attributes <- vapply(
    source_labels,
    .descfreq_original_attribute,
    character(1),
    original_names = original_names
  )

  row_pct <- suppressWarnings(as.numeric(raw[["Intern %"]]))
  global_pct <- suppressWarnings(as.numeric(raw[["glob %"]]))
  row_freq <- suppressWarnings(as.numeric(raw[["Intern freq"]]))
  global_freq <- suppressWarnings(as.numeric(raw[["Glob freq"]]))
  p_value <- suppressWarnings(as.numeric(raw[["p.value"]]))
  v_test <- suppressWarnings(as.numeric(raw[["v.test"]]))

  numeric_ok <- is.finite(row_pct) &
    is.finite(global_pct) &
    is.finite(row_freq) &
    is.finite(global_freq) &
    is.finite(p_value) &
    is.finite(v_test)

  if (!all(numeric_ok)) {
    stop(
      paste0(
        "The `FactoMineR::descfreq()` result for row `",
        row_name,
        "` contains non-finite statistical values."
      ),
      call. = FALSE
    )
  }

  direction <- ifelse(
    v_test > 0,
    "overrepresented",
    ifelse(v_test < 0, "underrepresented", "neutral")
  )

  out <- data.frame(
    evidence_id = vapply(
      attributes,
      function(attribute) {
        .make_descfreq_evidence_id(
          row = row_name,
          attribute = attribute
        )
      },
      character(1)
    ),
    row = rep(as.character(row_name), length(attributes)),
    attribute = attributes,
    direction = direction,
    row_percentage = row_pct,
    global_percentage = global_pct,
    difference_percentage_points = row_pct - global_pct,
    row_frequency = row_freq,
    global_frequency = global_freq,
    p_value = p_value,
    v_test = v_test,
    abs_v_test = abs(v_test),
    source_order = seq_along(attributes),
    rank = integer(length(attributes)),
    source = rep("FactoMineR::descfreq", length(attributes)),
    stringsAsFactors = FALSE,
    check.names = FALSE
  )

  ordering <- order(
    out$p_value,
    -out$abs_v_test,
    out$attribute,
    out$source_order,
    na.last = TRUE
  )

  out <- out[ordering, , drop = FALSE]
  rownames(out) <- NULL
  out$rank <- seq_len(nrow(out))
  out
}


.build_descfreq_column_profile <- function(analyzed_table,
                                           row_index) {
  values <- as.numeric(analyzed_table[row_index, , drop = TRUE])
  row_total <- sum(values)
  col_totals <- colSums(analyzed_table)
  grand_total <- sum(col_totals)

  data.frame(
    attribute = colnames(analyzed_table),
    frequency = values,
    row_percentage = 100 * values / row_total,
    global_frequency = as.numeric(col_totals),
    global_percentage = 100 * as.numeric(col_totals) / grand_total,
    difference_percentage_points =
      100 * values / row_total -
      100 * as.numeric(col_totals) / grand_total,
    stringsAsFactors = FALSE,
    check.names = FALSE
  )
}


.build_frequency_profiles_descfreq <- function(dataset,
                                               by.quali,
                                               descfreq_result,
                                               proba) {
  analyzed_table <- .aggregate_descfreq_table(
    dataset = dataset,
    by.quali = by.quali
  )

  row_names <- rownames(analyzed_table)
  if (is.null(row_names)) {
    row_names <- as.character(seq_len(nrow(analyzed_table)))
    rownames(analyzed_table) <- row_names
  }

  if (is.null(names(descfreq_result))) {
    stop(
      "`FactoMineR::descfreq()` returned an unnamed row list.",
      call. = FALSE
    )
  }

  if (!identical(names(descfreq_result), row_names)) {
    if (!setequal(names(descfreq_result), row_names)) {
      stop(
        paste(
          "The rows returned by `FactoMineR::descfreq()` do not match",
          "the rows of the analyzed contingency table."
        ),
        call. = FALSE
      )
    }

    descfreq_result <- descfreq_result[row_names]
  }

  rows <- stats::setNames(
    vector("list", length(row_names)),
    row_names
  )

  registry_parts <- vector("list", length(row_names))

  for (i in seq_along(row_names)) {
    row_name <- row_names[[i]]

    markers <- .normalize_descfreq_row_result(
      x = descfreq_result[[row_name]],
      row_name = row_name,
      original_names = colnames(dataset)
    )

    over <- markers[
      markers$direction == "overrepresented",
      ,
      drop = FALSE
    ]
    under <- markers[
      markers$direction == "underrepresented",
      ,
      drop = FALSE
    ]

    column_profile <- .build_descfreq_column_profile(
      analyzed_table = analyzed_table,
      row_index = i
    )

    p_values <- markers$p_value[is.finite(markers$p_value)]
    v_values <- markers$v_test[is.finite(markers$v_test)]

    rows[[row_name]] <- list(
      row = row_name,
      row_total = as.numeric(sum(analyzed_table[i, , drop = TRUE])),
      row_share_percent = as.numeric(
        100 * sum(analyzed_table[i, , drop = TRUE]) /
          sum(as.matrix(analyzed_table))
      ),
      column_profile = column_profile,
      retained_markers = markers,
      overrepresented = over,
      underrepresented = under,
      metrics = list(
        n_attributes_total = as.integer(ncol(analyzed_table)),
        n_markers_retained = as.integer(nrow(markers)),
        n_overrepresented = as.integer(nrow(over)),
        n_underrepresented = as.integer(nrow(under)),
        min_p_value = if (length(p_values) > 0L) {
          min(p_values)
        } else {
          NA_real_
        },
        max_abs_v_test = if (length(v_values) > 0L) {
          max(abs(v_values))
        } else {
          NA_real_
        }
      )
    )

    registry_parts[[i]] <- markers
  }

  non_empty <- registry_parts[
    vapply(registry_parts, nrow, integer(1)) > 0L
  ]

  evidence_registry <- if (length(non_empty) == 0L) {
    .empty_descfreq_marker_table()
  } else {
    do.call(rbind, non_empty)
  }
  rownames(evidence_registry) <- NULL

  if (anyDuplicated(evidence_registry$evidence_id)) {
    stop(
      "Internal error: duplicated DESCFREQ evidence identifiers were created.",
      call. = FALSE
    )
  }

  row_totals <- rowSums(analyzed_table)
  col_totals <- colSums(analyzed_table)
  grand_total <- sum(row_totals)

  source_row_names <- rownames(dataset)
  if (is.null(source_row_names)) {
    source_row_names <- as.character(seq_len(nrow(dataset)))
  }

  analyzed_row_for_source <- if (is.null(by.quali)) {
    source_row_names
  } else {
    as.character(by.quali)
  }

  aggregation_map <- data.frame(
    source_row = as.integer(seq_len(nrow(dataset))),
    source_row_label = as.character(source_row_names),
    analyzed_row = analyzed_row_for_source,
    stringsAsFactors = FALSE
  )

  out <- list(
    contingency_table = analyzed_table,
    rows = rows,
    evidence_registry = evidence_registry,
    margins = list(
      row_totals = row_totals,
      column_totals = col_totals,
      grand_total = as.numeric(grand_total)
    ),
    aggregation = list(
      performed = !is.null(by.quali),
      source_to_analyzed_row = aggregation_map
    ),
    settings = list(
      proba = proba,
      by_quali_supplied = !is.null(by.quali),
      statistical_source = "FactoMineR::descfreq",
      statistical_test = "two-sided hypergeometric tail test as implemented by FactoMineR::descfreq",
      retention_rule = "FactoMineR retains cells with p.value < proba.",
      ranking_rule = paste(
        "Within each row: increasing p.value, then decreasing absolute v.test,",
        "then attribute and source order."
      )
    ),
    metadata = list(
      schema = "NaileR::descfreq_frequency_profiles",
      schema_version = "1.0.0",
      n_source_rows = as.integer(nrow(dataset)),
      n_rows = as.integer(nrow(analyzed_table)),
      n_attributes = as.integer(ncol(analyzed_table)),
      n_retained_evidence = as.integer(nrow(evidence_registry)),
      aggregation_performed = !is.null(by.quali)
    )
  )

  class(out) <- c(
    "nail_descfreq_frequency_profiles",
    "list"
  )
  out
}


# ---------------------------------------------------------------------------
# Deterministic prompt selection
# ---------------------------------------------------------------------------

.select_descfreq_markers <- function(markers,
                                     sample_pct,
                                     drop_negative) {
  if (!is.data.frame(markers) || nrow(markers) == 0L) {
    return(.empty_descfreq_marker_table())
  }

  eligible <- markers

  if (isTRUE(drop_negative)) {
    eligible <- eligible[
      eligible$direction != "underrepresented",
      ,
      drop = FALSE
    ]
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

  selected <- integer(0)

  directions <- intersect(
    c("overrepresented", "underrepresented"),
    unique(as.character(eligible$direction))
  )

  # Preserve the strongest signal from both directions whenever at least two
  # prompt slots are available. Remaining slots follow canonical evidence rank.
  if (!isTRUE(drop_negative) &&
      length(directions) == 2L &&
      n_keep >= 2L) {
    first_over <- which(
      eligible$direction == "overrepresented"
    )[1L]
    first_under <- which(
      eligible$direction == "underrepresented"
    )[1L]

    selected <- c(first_over, first_under)
  }

  selected <- unique(selected)
  remaining <- setdiff(seq_len(n_available), selected)

  if (length(selected) < n_keep) {
    selected <- c(
      selected,
      utils::head(
        remaining,
        n_keep - length(selected)
      )
    )
  }

  selected <- sort(unique(selected))[seq_len(n_keep)]

  out <- eligible[selected, , drop = FALSE]
  out <- out[order(out$rank), , drop = FALSE]
  rownames(out) <- NULL
  out
}


.build_interpretation_evidence_descfreq <- function(frequency_profiles,
                                                    sample_pct,
                                                    drop_negative) {
  row_names <- names(frequency_profiles$rows)

  rows <- stats::setNames(
    vector("list", length(row_names)),
    row_names
  )

  selected_ids <- character(0)

  for (row_name in row_names) {
    full <- frequency_profiles$rows[[row_name]]$retained_markers
    selected <- .select_descfreq_markers(
      markers = full,
      sample_pct = sample_pct,
      drop_negative = drop_negative
    )

    ids <- selected$evidence_id
    selected_ids <- c(selected_ids, ids)

    rows[[row_name]] <- list(
      row = row_name,
      status = if (nrow(selected) > 0L) {
        "ready"
      } else {
        "no_selected_evidence"
      },
      selected_markers = selected,
      selected_evidence_ids = ids,
      metrics = list(
        n_retained_markers = as.integer(nrow(full)),
        n_eligible_markers = as.integer(
          if (isTRUE(drop_negative)) {
            sum(full$direction != "underrepresented")
          } else {
            nrow(full)
          }
        ),
        n_selected_markers = as.integer(nrow(selected))
      )
    )
  }

  out <- list(
    rows = rows,
    selected_evidence_ids = selected_ids,
    settings = list(
      sample_pct = sample_pct,
      drop_negative = drop_negative,
      selection_rule = paste(
        "Deterministic canonical ranking; when both directions are eligible",
        "and at least two slots are available, preserve the strongest marker",
        "from each direction before filling remaining slots by rank."
      )
    ),
    metadata = list(
      schema = "NaileR::descfreq_interpretation_evidence",
      schema_version = "1.0.0",
      n_rows = as.integer(length(rows)),
      n_ready_rows = as.integer(sum(vapply(
        rows,
        function(row) identical(row$status, "ready"),
        logical(1)
      ))),
      n_selected_evidence = as.integer(length(selected_ids))
    )
  )

  class(out) <- c(
    "nail_descfreq_interpretation_evidence",
    "list"
  )
  out
}


# ---------------------------------------------------------------------------
# Semantic-facing factual evidence
# ---------------------------------------------------------------------------

.format_descfreq_pct <- function(x) {
  if (!is.finite(x)) {
    return("NA")
  }
  paste0(format(round(x, 2), trim = TRUE, nsmall = 0), "%")
}


.format_descfreq_count <- function(x) {
  if (!is.finite(x)) {
    return("NA")
  }
  format(round(x), trim = TRUE, scientific = FALSE)
}


.descfreq_fact_statement <- function(row) {
  direction <- if (identical(
    as.character(row$direction[[1L]]),
    "overrepresented"
  )) {
    "higher"
  } else if (identical(
    as.character(row$direction[[1L]]),
    "underrepresented"
  )) {
    "lower"
  } else {
    "similar"
  }

  paste0(
    'Attribute "', row$attribute[[1L]],
    '" has a ', direction,
    ' relative frequency in this row than in the whole table ',
    '(row profile=', .format_descfreq_pct(row$row_percentage[[1L]]),
    '; global profile=', .format_descfreq_pct(row$global_percentage[[1L]]),
    '; row frequency=', .format_descfreq_count(row$row_frequency[[1L]]),
    '; total attribute frequency=', .format_descfreq_count(row$global_frequency[[1L]]),
    ').'
  )
}


.build_semantic_facing_evidence_descfreq <- function(interpretation_evidence) {
  row_names <- names(interpretation_evidence$rows)
  rows <- stats::setNames(
    vector("list", length(row_names)),
    row_names
  )

  n_displayed <- 0L

  for (row_name in row_names) {
    selected <- interpretation_evidence$rows[[row_name]]
    markers <- selected$selected_markers

    statements <- if (nrow(markers) > 0L) {
      vapply(
        seq_len(nrow(markers)),
        function(i) {
          .descfreq_fact_statement(
            markers[i, , drop = FALSE]
          )
        },
        character(1)
      )
    } else {
      character(0)
    }

    n_displayed <- n_displayed + length(statements)

    factual_text <- if (length(statements) == 0L) {
      paste(
        "No retained statistical attribute is shown for this row",
        "under the current prompt-selection settings."
      )
    } else {
      paste(
        paste0("- ", statements),
        collapse = "\n"
      )
    }

    rows[[row_name]] <- list(
      row = row_name,
      status = selected$status,
      selected_evidence_ids = selected$selected_evidence_ids,
      displayed_evidence = markers,
      factual_statements = statements,
      text = factual_text
    )
  }

  out <- list(
    rows = rows,
    settings = interpretation_evidence$settings,
    metadata = list(
      schema = "NaileR::descfreq_semantic_facing_evidence",
      schema_version = "1.0.0",
      n_rows = as.integer(length(rows)),
      n_displayed_evidence = as.integer(n_displayed)
    )
  )

  class(out) <- c(
    "nail_descfreq_semantic_facing_evidence",
    "list"
  )
  out
}


# ---------------------------------------------------------------------------
# Prompt builders
# ---------------------------------------------------------------------------

build_request_descfreq <- function(isolate.groups = FALSE,
                                   interpretation_mode = c("description", "comparison"),
                                   rows_are_ordered = FALSE,
                                   explicit_row_labels = FALSE) {
  interpretation_mode <- match.arg(interpretation_mode)

  if (isTRUE(isolate.groups)) {
    lines <- c(
      "Using only the statistical facts below, interpret this row as a relative frequency profile.",
      "Identify the attributes that most clearly characterize or distinguish it.",
      "Do not infer causal explanations or properties that are not supported by the displayed frequency evidence."
    )

    if (isTRUE(rows_are_ordered)) {
      lines <- c(
        lines,
        "The rows have an external order, but this prompt contains only one row; do not invent a broader gradient from this row alone."
      )
    }

    if (isTRUE(explicit_row_labels)) {
      lines <- c(lines, "Keep the existing row label and do not rename it.")
    } else {
      lines <- c(
        lines,
        "You may propose a short descriptive name only if it is clearly supported by the displayed attributes."
      )
    }

    return(paste(lines, collapse = "\n"))
  }

  if (identical(interpretation_mode, "comparison")) {
    lines <- c(
      "Using only the statistical facts below, compare the rows as relative frequency profiles.",
      "Identify the main contrasts and the attributes that distinguish the rows.",
      "Do not interpret frequency differences as causal explanations."
    )

    if (isTRUE(rows_are_ordered)) {
      lines <- c(
        lines,
        "The rows form an externally ordered sequence. Describe a broader gradient only if the displayed facts support it, and mention transitions or exceptions."
      )
    } else {
      lines <- c(
        lines,
        "Do not impose a progression or continuum on rows that are not externally ordered."
      )
    }

    if (isTRUE(explicit_row_labels)) {
      lines <- c(lines, "Keep the existing row labels and do not rename them.")
    } else {
      lines <- c(
        lines,
        "You may propose concise descriptive names when they help summarize well-supported profiles."
      )
    }

    return(paste(lines, collapse = "\n"))
  }

  lines <- c(
    "Using only the statistical facts below, describe each row as a relative frequency profile.",
    "For each row, identify the main attributes that characterize or distinguish it.",
    "Do not interpret frequency differences as causal explanations."
  )

  if (isTRUE(rows_are_ordered)) {
    lines <- c(
      lines,
      "The rows have an external order. You may mention broader tendencies only when they are directly supported by the displayed facts."
    )
  } else {
    lines <- c(
      lines,
      "Do not assume that the rows form a progression or continuum."
    )
  }

  if (isTRUE(explicit_row_labels)) {
    lines <- c(lines, "Keep the existing row labels and do not rename them.")
  } else {
    lines <- c(
      lines,
      "You may propose concise descriptive names when they are clearly supported by the evidence."
    )
  }

  paste(lines, collapse = "\n")
}


build_conclusion_descfreq <- function(isolate.groups = FALSE,
                                      interpretation_mode = c("description", "comparison"),
                                      rows_are_ordered = FALSE,
                                      explicit_row_labels = FALSE) {
  interpretation_mode <- match.arg(interpretation_mode)

  if (isTRUE(isolate.groups)) {
    items <- c(
      "# Final Summary Task",
      "1. **A concise interpretation of the row as a relative frequency profile**.",
      "2. **The main attributes supporting that interpretation**."
    )

    if (!isTRUE(explicit_row_labels)) {
      items <- c(
        items,
        "3. **An optional descriptive row name**, only if clearly supported."
      )
    }

    return(
      paste(
        c(
          items,
          "",
          "# Output format",
          "Your output must be **formatted using valid Quarto Markdown**."
        ),
        collapse = "\n"
      )
    )
  }

  if (identical(interpretation_mode, "comparison")) {
    items <- c(
      "# Final Summary Task",
      "1. **A concise synthesis of the main differences across rows**.",
      "2. **The statistical attributes supporting the main contrasts**."
    )

    if (isTRUE(rows_are_ordered)) {
      items <- c(
        items,
        "3. **Any supported gradient, transition, or exception across the ordered rows**."
      )
    }

    if (!isTRUE(explicit_row_labels)) {
      items <- c(
        items,
        paste0(
          if (isTRUE(rows_are_ordered)) "4." else "3.",
          " **Optional descriptive row names**, only where clearly supported."
        )
      )
    }
  } else {
    items <- c(
      "# Final Summary Task",
      "1. **A concise interpretation of each row as a relative frequency profile**.",
      "2. **The main statistical attributes supporting each interpretation**."
    )

    if (!isTRUE(explicit_row_labels)) {
      items <- c(
        items,
        "3. **Optional descriptive row names**, only where clearly supported."
      )
    }
  }

  paste(
    c(
      items,
      "",
      "# Output format",
      "Your output must be **formatted using valid Quarto Markdown**."
    ),
    collapse = "\n"
  )
}


build_guide_descfreq <- function(interpretation_mode = c("description", "comparison"),
                                 rows_are_ordered = FALSE,
                                 explicit_row_labels = FALSE) {
  interpretation_mode <- match.arg(interpretation_mode)

  lines <- c(
    "## How to Read the Evidence",
    "The source is a contingency table: rows are the entities or categories to interpret, and columns are frequency attributes.",
    "For each row, FactoMineR identifies attributes whose relative frequency differs statistically from the overall table profile.",
    "The factual statements below report the retained direction and the row-versus-global relative frequencies.",
    "They are statistical characterizations, not causal explanations.",
    "A higher relative frequency means that an attribute is over-represented in that row relative to the global table profile.",
    "A lower relative frequency means that an attribute is under-represented.",
    "Technical p-values and v-tests remain available in `nail_evidence()` for audit but are deliberately not used as semantic content in this prompt.",
    "Prioritize coherent configurations of several attributes over isolated single signals."
  )

  if (identical(interpretation_mode, "comparison")) {
    lines <- c(
      lines,
      "When several rows are shown together, comparisons may be made directly from their displayed statistical facts."
    )
  }

  if (isTRUE(rows_are_ordered)) {
    lines <- c(
      lines,
      "Row order is contextual information supplied by the analyst; it is not statistical evidence by itself."
    )
  }

  if (isTRUE(explicit_row_labels)) {
    lines <- c(
      lines,
      "Existing row labels carry user-supplied meaning and must be preserved."
    )
  }

  paste(lines, collapse = "\n")
}


.descfreq_row_data_block <- function(row_name,
                                     semantic_row) {
  paste(
    paste0("## Row '", row_name, "'"),
    "",
    "### Retained relative-frequency facts",
    "",
    semantic_row$text,
    sep = "\n"
  )
}


get_prompt_descfreq <- function(semantic_facing_evidence,
                                introduction,
                                request,
                                conclusion,
                                isolate.groups,
                                interpretation_mode = c("description", "comparison"),
                                rows_are_ordered = FALSE) {
  interpretation_mode <- match.arg(interpretation_mode)

  row_names <- names(semantic_facing_evidence$rows)

  blocks <- vapply(
    row_names,
    function(row_name) {
      .descfreq_row_data_block(
        row_name = row_name,
        semantic_row = semantic_facing_evidence$rows[[row_name]]
      )
    },
    character(1)
  )

  if (!isTRUE(isolate.groups)) {
    data_text <- paste(
      blocks,
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
    seq_along(row_names),
    function(i) {
      build_standard_prompt(
        introduction = introduction,
        request = request,
        data = blocks[[i]],
        conclusion = conclusion
      )
    }
  )

  names(out) <- row_names
  out
}


# ---------------------------------------------------------------------------
# LLM IO and artifact attachment
# ---------------------------------------------------------------------------

.descfreq_backend_response_text <- function(x) {
  if (is.character(x)) {
    return(paste(x, collapse = "\n"))
  }

  if (is.data.frame(x) &&
      "response" %in% names(x) &&
      nrow(x) > 0L) {
    return(paste(as.character(x$response), collapse = "\n"))
  }

  if (is.list(x) &&
      !is.null(x$response)) {
    return(paste(as.character(x$response), collapse = "\n"))
  }

  stop(
    "The DESCFREQ LLM backend result does not contain a readable raw response.",
    call. = FALSE
  )
}


.attach_descfreq_artifacts <- function(x,
                                       frequency_profiles,
                                       interpretation_evidence,
                                       semantic_facing_evidence,
                                       descfreq_result,
                                       prompts,
                                       responses,
                                       settings) {
  attr(x, "frequency_profiles") <- frequency_profiles
  attr(x, "interpretation_evidence") <- interpretation_evidence
  attr(x, "semantic_facing_evidence") <- semantic_facing_evidence
  attr(x, "descfreq_result") <- descfreq_result
  attr(x, "descfreq_settings") <- settings
  attr(x, "llm_io") <- .new_nail_llm_io(
    stage = "interpretation",
    prompts = prompts,
    responses = responses,
    metadata = list(
      analysis = "nail_descfreq",
      scope = if (isTRUE(settings$isolate_groups)) {
        "row"
      } else {
        "table"
      },
      provider = settings$provider,
      model = settings$model,
      interpretation_mode = settings$interpretation_mode
    )
  )
  x
}


.descfreq_no_evidence_result <- function(model,
                                         prompt,
                                         message = "No selected statistical evidence found.") {
  list(
    prompt = prompt,
    model = model,
    status = "not_generated_no_selected_evidence",
    message = message
  )
}


# ---------------------------------------------------------------------------
# Main
# ---------------------------------------------------------------------------

#' Interpret the rows of a contingency table using evidence-first frequency profiles
#'
#' `nail_descfreq()` characterizes the rows of a contingency table with
#' [FactoMineR::descfreq()]. It first stores complete canonical
#' `frequency_profiles`, then selects a deterministic subset of retained
#' statistical markers for semantic interpretation.
#'
#' The canonical evidence is invariant to `generate`, `isolate.groups`,
#' `sample.pct`, `drop.negative`, `interpretation_mode`, `rows_are_ordered`,
#' `explicit_row_labels`, `introduction`, `request`, and `conclusion`. These
#' arguments affect only the interpretation layer.
#'
#' @param dataset A data frame corresponding to a contingency table. Cells must
#'   contain non-negative integer-like frequencies.
#' @param introduction Optional study context included in the LLM prompt.
#' @param request Optional analytical request sent to the LLM.
#' @param conclusion Optional final output-instruction block.
#' @param model Model name for the selected provider.
#' @param provider LLM backend, either `"ollama"` or `"gemini"`.
#' @param isolate.groups Logical. If `TRUE`, build one independent prompt per
#'   row. If `FALSE`, build one prompt containing all rows.
#' @param sample.pct Proportion in `[0, 1]` of eligible retained markers shown
#'   to the LLM. This never changes the canonical `frequency_profiles`.
#' @param drop.negative Logical. If `TRUE`, under-represented attributes are
#'   excluded only from the prompt-selection layer.
#' @param by.quali Optional grouping vector with one value per source row.
#'   Source rows sharing a level are summed before row characterization, as in
#'   [FactoMineR::descfreq()].
#' @param proba Significance threshold passed to [FactoMineR::descfreq()].
#' @param interpretation_mode Either `"description"` or `"comparison"`.
#' @param rows_are_ordered Logical contextual flag indicating that row order has
#'   external substantive meaning. It does not alter statistical evidence.
#' @param explicit_row_labels Logical contextual flag indicating that row names
#'   already have substantive meaning and should not be renamed by the LLM.
#' @param generate Logical. If `FALSE`, build prompt(s) without contacting an
#'   LLM. If `TRUE`, call the selected backend.
#' @param ... Additional provider-specific generation arguments.
#'
#' @return For backward compatibility, a prompt string or named list of prompts
#'   when `generate = FALSE`; a model/prompt/response list or named list of such
#'   results when `generate = TRUE`.
#'
#'   Every return carries:
#'
#'   * `frequency_profiles`: complete canonical contingency-frequency evidence;
#'   * `interpretation_evidence`: deterministic subset selected for the prompt;
#'   * `semantic_facing_evidence`: plain-language factual evidence shown to the
#'     LLM;
#'   * `descfreq_result`: the original single [FactoMineR::descfreq()] result;
#'   * `descfreq_settings`: execution and interpretation settings;
#'   * `llm_io`: exact prompt(s) and raw LLM response(s) for [nail_prompt()] and
#'     [nail_response()].
#'
#' @details
#' FactoMineR retains row-column cells using its two-sided hypergeometric test.
#' NaileR does not recompute or replace that test. It normalizes the returned
#' statistics into stable row profiles and assigns deterministic evidence IDs.
#'
#' For prompt selection, NaileR ranks retained evidence by increasing p-value,
#' then decreasing absolute v-test. When both over- and under-represented
#' evidence are eligible and at least two prompt slots are available, the
#' strongest marker from each direction is preserved before remaining slots
#' are filled by canonical rank.
#'
#' Technical p-values, v-tests, counts, and the full table remain inspectable
#' through [nail_evidence()]. The LLM-facing semantic facts use only explicit
#' direction and row-versus-global frequency information.
#'
#' @examples
#' tab <- data.frame(
#'   sweet = c(30, 5, 10),
#'   bitter = c(5, 30, 10),
#'   neutral = c(10, 10, 30),
#'   row.names = c("A", "B", "C")
#' )
#'
#' preview <- nail_descfreq(
#'   tab,
#'   isolate.groups = TRUE,
#'   generate = FALSE
#' )
#'
#' nail_evidence(preview, select = "A")
#' nail_prompt(preview, select = "A")
#'
#' @export
nail_descfreq <- function(dataset,
                          introduction = NULL,
                          request = NULL,
                          conclusion = NULL,
                          model = "llama3",
                          provider = c("ollama", "gemini"),
                          isolate.groups = FALSE,
                          sample.pct = 1,
                          drop.negative = FALSE,
                          by.quali = NULL,
                          proba = 0.05,
                          interpretation_mode = c("description", "comparison"),
                          rows_are_ordered = FALSE,
                          explicit_row_labels = FALSE,
                          generate = FALSE,
                          ...) {
  interpretation_mode <- match.arg(interpretation_mode)
  provider <- match.arg(provider)

  validate_descfreq_inputs(
    dataset = dataset,
    sample.pct = sample.pct,
    proba = proba,
    isolate.groups = isolate.groups,
    drop.negative = drop.negative,
    rows_are_ordered = rows_are_ordered,
    explicit_row_labels = explicit_row_labels,
    generate = generate,
    by.quali = by.quali
  )

  normalized_by_quali <- .normalize_by_quali_descfreq(
    by.quali,
    nrow(dataset)
  )

  descfreq_result <- FactoMineR::descfreq(
    dataset,
    by.quali = normalized_by_quali,
    proba = proba
  )

  frequency_profiles <- .build_frequency_profiles_descfreq(
    dataset = dataset,
    by.quali = normalized_by_quali,
    descfreq_result = descfreq_result,
    proba = proba
  )

  interpretation_evidence <- .build_interpretation_evidence_descfreq(
    frequency_profiles = frequency_profiles,
    sample_pct = sample.pct,
    drop_negative = drop.negative
  )

  semantic_facing_evidence <- .build_semantic_facing_evidence_descfreq(
    interpretation_evidence = interpretation_evidence
  )

  if (is.null(introduction)) {
    introduction <- paste(
      "The table analyzed here is a contingency table.",
      "Each row is interpreted through column attributes whose relative",
      "frequency differs from the overall table profile."
    )
  }

  if (is.null(request)) {
    request <- build_request_descfreq(
      isolate.groups = isolate.groups,
      interpretation_mode = interpretation_mode,
      rows_are_ordered = rows_are_ordered,
      explicit_row_labels = explicit_row_labels
    )
  }

  if (is.null(conclusion)) {
    conclusion <- build_conclusion_descfreq(
      isolate.groups = isolate.groups,
      interpretation_mode = interpretation_mode,
      rows_are_ordered = rows_are_ordered,
      explicit_row_labels = explicit_row_labels
    )
  }

  guide <- build_guide_descfreq(
    interpretation_mode = interpretation_mode,
    rows_are_ordered = rows_are_ordered,
    explicit_row_labels = explicit_row_labels
  )

  prompt_introduction <- paste(
    introduction,
    guide,
    sep = "\n\n---\n\n"
  )

  prompts <- get_prompt_descfreq(
    semantic_facing_evidence = semantic_facing_evidence,
    introduction = prompt_introduction,
    request = request,
    conclusion = conclusion,
    isolate.groups = isolate.groups,
    interpretation_mode = interpretation_mode,
    rows_are_ordered = rows_are_ordered
  )

  prompt_list <- if (isTRUE(isolate.groups)) {
    prompts
  } else {
    list(all_rows = prompts)
  }

  settings <- list(
    proba = proba,
    sample_pct = sample.pct,
    drop_negative = drop.negative,
    by_quali_supplied = !is.null(by.quali),
    interpretation_mode = interpretation_mode,
    rows_are_ordered = rows_are_ordered,
    explicit_row_labels = explicit_row_labels,
    isolate_groups = isolate.groups,
    generate = generate,
    provider = provider,
    model = model,
    statistical_source = "single_FactoMineR_descfreq_call",
    n_selected_evidence =
      interpretation_evidence$metadata$n_selected_evidence
  )

  if (!isTRUE(generate)) {
    return(
      .attach_descfreq_artifacts(
        x = prompts,
        frequency_profiles = frequency_profiles,
        interpretation_evidence = interpretation_evidence,
        semantic_facing_evidence = semantic_facing_evidence,
        descfreq_result = descfreq_result,
        prompts = prompt_list,
        responses = NULL,
        settings = settings
      )
    )
  }

  n_selected <- interpretation_evidence$metadata$n_selected_evidence
  llm_api_options <- list(...)

  .call_llm <- function(prompt) {
    raw <- .call_llm_base(
      provider = provider,
      model = model,
      prompt = prompt,
      output = "text",
      llm_api_options = llm_api_options
    )

    response <- .descfreq_backend_response_text(raw)

    list(
      prompt = prompt,
      response = response,
      model = model
    )
  }

  if (!isTRUE(isolate.groups)) {
    if (n_selected == 0L) {
      out <- .descfreq_no_evidence_result(
        model = model,
        prompt = prompts
      )
      responses <- NULL
    } else {
      out <- .call_llm(prompts)
      responses <- list(
        all_rows = out$response
      )
    }

    return(
      .attach_descfreq_artifacts(
        x = out,
        frequency_profiles = frequency_profiles,
        interpretation_evidence = interpretation_evidence,
        semantic_facing_evidence = semantic_facing_evidence,
        descfreq_result = descfreq_result,
        prompts = prompt_list,
        responses = responses,
        settings = settings
      )
    )
  }

  row_names <- names(prompts)
  out <- stats::setNames(
    vector("list", length(row_names)),
    row_names
  )
  responses <- list()

  for (row_name in row_names) {
    row_status <- interpretation_evidence$rows[[row_name]]$status

    if (identical(row_status, "ready")) {
      out[[row_name]] <- .call_llm(
        prompts[[row_name]]
      )
      responses[[row_name]] <- out[[row_name]]$response
    } else {
      out[[row_name]] <- .descfreq_no_evidence_result(
        model = model,
        prompt = prompts[[row_name]],
        message = paste0(
          "No selected statistical evidence found for row '",
          row_name,
          "'."
        )
      )
    }
  }

  if (length(responses) == 0L) {
    responses <- NULL
  }

  .attach_descfreq_artifacts(
    x = out,
    frequency_profiles = frequency_profiles,
    interpretation_evidence = interpretation_evidence,
    semantic_facing_evidence = semantic_facing_evidence,
    descfreq_result = descfreq_result,
    prompts = prompt_list,
    responses = responses,
    settings = settings
  )
}
