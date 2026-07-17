# ---------------------------------------------------------------------------
# Vocabulary used by the historical catdes prompts
# ---------------------------------------------------------------------------

.unit_noun <- function(mode, plural = FALSE) {
  if (mode == "standard") {
    if (plural) "categories" else "category"
  } else {
    if (plural) "groups" else "group"
  }
}

.unit_label <- function(mode) {
  if (mode == "standard") "Category" else "Group"
}

.groups_description <- function(mode, plural = FALSE,
                                target_label = "the target variable") {
  if (mode == "standard") {
    unit <- .unit_noun(mode, plural)
    if (plural) {
      paste0(
        "The ", unit, " below correspond to the explicit ", unit,
        " of '", target_label, "'."
      )
    } else {
      paste0(
        "The ", unit, " below is one of the explicit ", unit,
        " of '", target_label, "'."
      )
    }
  } else if (plural) {
    paste(
      "The groups below correspond to constructed profiles or latent classes.",
      paste(
        "The group labels are only identifiers and should not be treated",
        "as the interpretation of the groups."
      ),
      sep = "\n"
    )
  } else {
    paste(
      "The group below corresponds to a constructed profile or latent class.",
      paste(
        "The group label is only an identifier and should not be treated",
        "as the interpretation of the group."
      ),
      sep = "\n"
    )
  }
}

.groups_instruction <- function(mode, plural = FALSE) {
  if (mode == "standard") {
    if (plural) {
      paste(
        "Use the results to understand what characterizes each category",
        "and what distinguishes it from the others."
      )
    } else {
      "Use the results to understand what characterizes this category."
    }
  } else if (plural) {
    paste(
      "Use the results to infer what characterizes each group",
      "and how the groups differ from one another."
    )
  } else {
    paste(
      "Use the results to infer what characterizes this group",
      "and how it differs from the overall dataset."
    )
  }
}

.quali_title <- function(mode) {
  if (mode == "standard") {
    "Characteristic qualitative variables for this category"
  } else {
    "Characteristic qualitative variables for this group"
  }
}

.quanti_title <- function(mode) {
  if (mode == "standard") {
    "Characteristic quantitative variables for this category"
  } else {
    "Characteristic quantitative variables for this group"
  }
}

# ---------------------------------------------------------------------------
# Input normalization
# ---------------------------------------------------------------------------

.is_statistical_profiles_nail_catdes <- function(x) {
  inherits(x, "statistical_profiles") &&
    is.list(x) &&
    is.list(x$groups) &&
    is.data.frame(x$evidence_registry) &&
    is.list(x$settings) &&
    is.list(x$metadata)
}

.validate_statistical_profiles_nail_catdes <- function(x) {
  if (!.is_statistical_profiles_nail_catdes(x)) {
    stop(
      paste(
        "`x` must be a valid `statistical_profiles` object, an object",
        "carrying a `statistical_profiles` attribute, or a supported",
        "catdes-compatible object."
      ),
      call. = FALSE
    )
  }

  group_names <- names(x$groups)
  if (length(x$groups) == 0L || is.null(group_names) ||
      anyNA(group_names) || any(!nzchar(group_names)) ||
      anyDuplicated(group_names)) {
    stop(
      "`statistical_profiles$groups` must be a non-empty uniquely named list.",
      call. = FALSE
    )
  }

  required_registry <- c(
    "evidence_id", "group", "marker_type", "direction", "rank"
  )
  missing_registry <- setdiff(required_registry, names(x$evidence_registry))
  if (length(missing_registry) > 0L) {
    stop(
      paste0(
        "`statistical_profiles$evidence_registry` is missing: ",
        paste(missing_registry, collapse = ", "),
        "."
      ),
      call. = FALSE
    )
  }

  if (anyDuplicated(x$evidence_registry$evidence_id)) {
    stop(
      "`statistical_profiles$evidence_registry$evidence_id` must be unique.",
      call. = FALSE
    )
  }

  qualitative_columns <- c(
    "evidence_id", "group", "variable", "modality", "direction",
    "percentage_in_group", "percentage_in_modality",
    "global_percentage", "v_test", "p_value", "rank"
  )
  quantitative_columns <- c(
    "evidence_id", "group", "variable", "direction", "group_mean",
    "overall_mean", "standard_deviation",
    "overall_standard_deviation", "v_test", "p_value", "rank"
  )

  for (group_name in group_names) {
    group <- x$groups[[group_name]]
    if (!is.list(group) ||
        !is.data.frame(group$qualitative_markers) ||
        !is.data.frame(group$quantitative_markers)) {
      stop(
        paste0(
          "Group '", group_name,
          "' must contain qualitative and quantitative marker tables."
        ),
        call. = FALSE
      )
    }

    missing_quali <- setdiff(
      qualitative_columns,
      names(group$qualitative_markers)
    )
    missing_quanti <- setdiff(
      quantitative_columns,
      names(group$quantitative_markers)
    )
    if (length(missing_quali) > 0L || length(missing_quanti) > 0L) {
      stop(
        paste0(
          "Group '", group_name,
          "' contains incomplete statistical marker tables."
        ),
        call. = FALSE
      )
    }

    group_ids <- c(
      group$qualitative_markers$evidence_id,
      group$quantitative_markers$evidence_id
    )
    if (any(!group_ids %in% x$evidence_registry$evidence_id)) {
      stop(
        paste0(
          "Group '", group_name,
          "' contains evidence IDs absent from the central registry."
        ),
        call. = FALSE
      )
    }
  }

  invisible(TRUE)
}

.muffle_catdes_prep_dataset_deprecation <- function(expr) {
  withCallingHandlers(
    expr,
    warning = function(w) {
      message <- conditionMessage(w)
      if (grepl(
        "dataset`/`num.var` interface of `nail_catdes_prep", message,
        fixed = TRUE
      )) {
        invokeRestart("muffleWarning")
      }
    }
  )
}

.extract_target_label_nail_catdes <- function(profiles, dataset = NULL,
                                               num.var = NULL) {
  if (!is.null(dataset) && !is.null(num.var) &&
      !is.null(colnames(dataset)) &&
      num.var >= 1L && num.var <= ncol(dataset)) {
    return(colnames(dataset)[num.var])
  }

  input <- attr(profiles, "catdes_input", exact = TRUE)
  if (is.null(input) && is.list(profiles$metadata$input)) {
    input <- profiles$metadata$input
  }

  if (is.list(input) && is.character(input$group_variable) &&
      length(input$group_variable) == 1L &&
      !is.na(input$group_variable) && nzchar(input$group_variable)) {
    return(input$group_variable)
  }

  "the target variable"
}

.canonicalize_raw_profiles_nail_catdes <- function(profiles, proba) {
  canonical_input <- list(
    source = "x",
    proba_applied_by_function = FALSE,
    declared_proba = proba
  )

  profiles$settings$proba_applied_by_function <- FALSE
  profiles$metadata$input <- canonical_input
  attr(profiles, "catdes_input") <- canonical_input
  attr(profiles, "catdes_settings") <- profiles$settings
  profiles
}

.normalize_nail_catdes_input <- function(x = NULL,
                                         dataset = NULL,
                                         num.var = NULL,
                                         proba = 0.05,
                                         row.w = NULL) {
  if (!is.null(x) && !is.null(dataset)) {
    stop("Provide only one of `x` and `dataset`.", call. = FALSE)
  }
  if (is.null(x) && is.null(dataset)) {
    stop("Provide either `x` or `dataset`.", call. = FALSE)
  }

  if (!is.null(x)) {
    if (!is.null(num.var)) {
      stop("`num.var` cannot be used when `x` is supplied.", call. = FALSE)
    }
    if (!is.null(row.w)) {
      stop("`row.w` cannot be used when `x` is supplied.", call. = FALSE)
    }

    if (.is_statistical_profiles_nail_catdes(x)) {
      profiles <- x
      source_type <- "statistical_profiles"
      preparation_performed <- FALSE
    } else {
      attached <- attr(x, "statistical_profiles", exact = TRUE)
      if (.is_statistical_profiles_nail_catdes(attached)) {
        profiles <- attached
        source_type <- "statistical_profiles_attribute"
        preparation_performed <- FALSE
      } else {
        profiles <- tryCatch(
          nail_catdes_prep(x = x, proba = proba),
          error = function(e) {
            stop(
              paste0(
                "`x` must be a valid `statistical_profiles` object, an object ",
                "carrying a `statistical_profiles` attribute, or a supported ",
                "catdes-compatible object. Original error: ",
                conditionMessage(e)
              ),
              call. = FALSE
            )
          }
        )
        source_type <- "catdes_compatible_x"
        preparation_performed <- TRUE
      }
    }

    .validate_statistical_profiles_nail_catdes(profiles)

    return(list(
      statistical_profiles = profiles,
      catdes_result = attr(profiles, "catdes_result", exact = TRUE),
      source_type = source_type,
      preparation_performed = preparation_performed,
      target_label = .extract_target_label_nail_catdes(profiles),
      metadata = list(
        source_type = source_type,
        nail_catdes_prep_calls = as.integer(preparation_performed),
        raw_dataset_supplied = FALSE
      )
    ))
  }

  profiles <- .muffle_catdes_prep_dataset_deprecation(
    nail_catdes_prep(
      dataset = dataset,
      num.var = num.var,
      proba = proba,
      row.w = row.w
    )
  )
  .validate_statistical_profiles_nail_catdes(profiles)
  preparation_input <- attr(profiles, "catdes_input", exact = TRUE)
  profiles <- .canonicalize_raw_profiles_nail_catdes(profiles, proba = proba)

  list(
    statistical_profiles = profiles,
    catdes_result = attr(profiles, "catdes_result", exact = TRUE),
    source_type = "dataset",
    preparation_performed = TRUE,
    target_label = .extract_target_label_nail_catdes(
      profiles,
      dataset = dataset,
      num.var = num.var
    ),
    metadata = list(
      source_type = "dataset",
      nail_catdes_prep_calls = 1L,
      raw_dataset_supplied = TRUE,
      preparation_input = preparation_input,
      statistical_profiles_canonicalized = TRUE
    )
  )
}

# ---------------------------------------------------------------------------
# Deterministic prompt-selection evidence
# ---------------------------------------------------------------------------

.empty_selected_registry_nail_catdes <- function(registry) {
  out <- registry[0, , drop = FALSE]
  out$selection_order <- integer(0)
  out
}

.order_markers_for_nail_catdes <- function(markers) {
  if (!is.data.frame(markers) || nrow(markers) == 0L) {
    return(markers)
  }

  rank_value <- suppressWarnings(as.numeric(markers$rank))
  rank_value[!is.finite(rank_value)] <- Inf
  evidence_id <- as.character(markers$evidence_id)
  evidence_id[is.na(evidence_id)] <- ""

  markers[order(rank_value, evidence_id, na.last = TRUE), , drop = FALSE]
}

.select_markers_for_nail_catdes <- function(markers,
                                            proportion,
                                            drop_negative,
                                            negative_directions) {
  if (!is.data.frame(markers) || nrow(markers) == 0L) {
    return(markers)
  }

  ordered <- .order_markers_for_nail_catdes(markers)
  eligible <- if (isTRUE(drop_negative)) {
    ordered[!(ordered$direction %in% negative_directions), , drop = FALSE]
  } else {
    ordered
  }

  n_available <- nrow(eligible)
  if (n_available == 0L || proportion <= 0) {
    return(eligible[0, , drop = FALSE])
  }

  n_selected <- if (proportion >= 1) {
    n_available
  } else {
    ceiling(n_available * proportion)
  }

  eligible[seq_len(min(n_selected, n_available)), , drop = FALSE]
}

.build_interpretation_evidence_nail_catdes <- function(statistical_profiles,
                                                        quali_sample = 1,
                                                        quanti_sample = 1,
                                                        drop_negative = FALSE) {
  .validate_statistical_profiles_nail_catdes(statistical_profiles)

  group_names <- names(statistical_profiles$groups)
  groups <- stats::setNames(vector("list", length(group_names)), group_names)
  selected_ids <- character(0)

  for (group_name in group_names) {
    profile <- statistical_profiles$groups[[group_name]]
    qualitative <- profile$qualitative_markers
    quantitative <- profile$quantitative_markers

    if (!is.data.frame(qualitative) || !is.data.frame(quantitative)) {
      stop(
        paste0(
          "Group '", group_name,
          "' does not contain valid qualitative and quantitative marker tables."
        ),
        call. = FALSE
      )
    }

    qualitative_selected <- .select_markers_for_nail_catdes(
      qualitative,
      proportion = quali_sample,
      drop_negative = drop_negative,
      negative_directions = "underrepresented"
    )
    quantitative_selected <- .select_markers_for_nail_catdes(
      quantitative,
      proportion = quanti_sample,
      drop_negative = drop_negative,
      negative_directions = "lower"
    )

    all_negative <- c(
      qualitative$evidence_id[
        qualitative$direction %in% "underrepresented"
      ],
      quantitative$evidence_id[
        quantitative$direction %in% "lower"
      ]
    )
    selected_negative <- c(
      qualitative_selected$evidence_id[
        qualitative_selected$direction %in% "underrepresented"
      ],
      quantitative_selected$evidence_id[
        quantitative_selected$direction %in% "lower"
      ]
    )

    n_available <- nrow(qualitative) + nrow(quantitative)
    n_eligible <- if (isTRUE(drop_negative)) {
      n_available - length(all_negative)
    } else {
      n_available
    }
    n_selected <- nrow(qualitative_selected) + nrow(quantitative_selected)

    status <- if (n_available == 0L) {
      "no_available_markers"
    } else if (n_eligible == 0L) {
      "no_eligible_markers"
    } else if (n_selected == 0L) {
      "selection_empty"
    } else {
      "ready"
    }

    groups[[group_name]] <- list(
      group = group_name,
      status = status,
      qualitative_markers = qualitative_selected,
      quantitative_markers = quantitative_selected,
      selected_evidence_ids = c(
        qualitative_selected$evidence_id,
        quantitative_selected$evidence_id
      ),
      excluded_negative_evidence_ids = if (isTRUE(drop_negative)) {
        setdiff(all_negative, selected_negative)
      } else {
        character(0)
      },
      metrics = list(
        n_qualitative_available = as.integer(nrow(qualitative)),
        n_qualitative_selected = as.integer(nrow(qualitative_selected)),
        n_quantitative_available = as.integer(nrow(quantitative)),
        n_quantitative_selected = as.integer(nrow(quantitative_selected)),
        n_negative_available = as.integer(length(all_negative)),
        n_negative_selected = as.integer(length(selected_negative)),
        n_negative_excluded_by_policy = as.integer(
          if (isTRUE(drop_negative)) length(all_negative) else 0L
        )
      )
    )

    selected_ids <- c(
      selected_ids,
      groups[[group_name]]$selected_evidence_ids
    )
  }

  registry <- statistical_profiles$evidence_registry
  if (length(selected_ids) == 0L) {
    selected_registry <- .empty_selected_registry_nail_catdes(registry)
  } else {
    positions <- match(selected_ids, registry$evidence_id)
    if (anyNA(positions)) {
      stop(
        "Internal error: selected evidence is absent from the full registry.",
        call. = FALSE
      )
    }
    selected_registry <- registry[positions, , drop = FALSE]
    selected_registry$selection_order <- seq_len(nrow(selected_registry))
    rownames(selected_registry) <- NULL
  }

  out <- list(
    groups = groups,
    selected_evidence_registry = selected_registry,
    settings = list(
      quali_sample = quali_sample,
      quanti_sample = quanti_sample,
      drop_negative = drop_negative,
      qualitative_selection_rule = paste(
        "Filter negative directions only when requested; order by the",
        "precomputed rank and evidence_id; retain ceiling(n * quali_sample)."
      ),
      quantitative_selection_rule = paste(
        "Filter negative directions only when requested; order by the",
        "precomputed rank and evidence_id; retain ceiling(n * quanti_sample)."
      ),
      zero_proportion_rule = "A zero proportion selects no marker.",
      full_proportion_rule = "A proportion of one selects every eligible marker."
    ),
    metadata = list(
      schema = "NaileR::catdes_interpretation_evidence",
      schema_version = "1.0.0",
      source_schema = statistical_profiles$metadata$schema,
      n_groups = as.integer(length(groups)),
      n_selected_evidence = as.integer(nrow(selected_registry)),
      n_ready_groups = as.integer(sum(vapply(
        groups,
        function(group) identical(group$status, "ready"),
        logical(1)
      )))
    )
  )
  class(out) <- c("nail_catdes_interpretation_evidence", "list")
  out
}

# ---------------------------------------------------------------------------
# Historical prompt builders, now based only on interpretation_evidence
# ---------------------------------------------------------------------------

.format_catdes_prompt_number <- function(x, p_value = FALSE) {
  vapply(x, function(value) {
    if (length(value) == 0L || is.na(value) || !is.finite(value)) {
      return("NA")
    }
    if (isTRUE(p_value) && value < 0.001) {
      return("<0.001")
    }
    if (isTRUE(p_value)) {
      return(formatC(value, digits = 3, format = "f"))
    }
    formatC(value, digits = 2, format = "f")
  }, character(1))
}

.escape_markdown_cell_nail_catdes <- function(x) {
  x <- as.character(x)
  x[is.na(x)] <- "-"
  x <- gsub("\\|", "\\\\|", x)
  x <- gsub("[\r\n]+", " ", x)
  x
}

.markdown_table_nail_catdes <- function(df) {
  if (!is.data.frame(df) || nrow(df) == 0L) {
    return("*No significant data to display.*")
  }

  for (column in names(df)) {
    df[[column]] <- .escape_markdown_cell_nail_catdes(df[[column]])
  }

  header <- paste("|", paste(names(df), collapse = " | "), "|")
  separator <- paste("|", paste(rep("---", ncol(df)), collapse = " | "), "|")
  rows <- apply(df, 1L, function(row) {
    paste("|", paste(row, collapse = " | "), "|")
  })
  paste(header, separator, paste(rows, collapse = "\n"), sep = "\n")
}

.format_qualitative_evidence_nail_catdes <- function(markers,
                                                      interpretation_mode) {
  title <- .quali_title(interpretation_mode)
  if (nrow(markers) == 0L) {
    return(paste0("### ", title, "\n\n*No significant data to display.*\n"))
  }

  table <- data.frame(
    `Evidence ID` = markers$evidence_id,
    Variable = markers$variable,
    Modality = markers$modality,
    Direction = markers$direction,
    `Cla/Mod` = .format_catdes_prompt_number(markers$percentage_in_modality),
    `Mod/Cla` = .format_catdes_prompt_number(markers$percentage_in_group),
    Global = .format_catdes_prompt_number(markers$global_percentage),
    `p.value` = .format_catdes_prompt_number(markers$p_value, p_value = TRUE),
    `v.test` = .format_catdes_prompt_number(markers$v_test),
    stringsAsFactors = FALSE,
    check.names = FALSE
  )

  paste0("### ", title, "\n\n", .markdown_table_nail_catdes(table), "\n")
}

.format_quantitative_evidence_nail_catdes <- function(markers,
                                                       interpretation_mode) {
  title <- .quanti_title(interpretation_mode)
  if (nrow(markers) == 0L) {
    return(paste0("### ", title, "\n\n*No significant data to display.*\n"))
  }

  table <- data.frame(
    `Evidence ID` = markers$evidence_id,
    Variable = markers$variable,
    Direction = markers$direction,
    `Mean in category` = .format_catdes_prompt_number(markers$group_mean),
    `Overall mean` = .format_catdes_prompt_number(markers$overall_mean),
    `sd in category` = .format_catdes_prompt_number(markers$standard_deviation),
    `Overall sd` = .format_catdes_prompt_number(
      markers$overall_standard_deviation
    ),
    `p.value` = .format_catdes_prompt_number(markers$p_value, p_value = TRUE),
    `v.test` = .format_catdes_prompt_number(markers$v_test),
    stringsAsFactors = FALSE,
    check.names = FALSE
  )

  paste0("### ", title, "\n\n", .markdown_table_nail_catdes(table), "\n")
}

.build_data_intro <- function(interpretation_mode, isolate_groups,
                              target_label, prompt_style) {
  plural <- !isolate_groups
  desc <- .groups_description(interpretation_mode, plural, target_label)
  instr <- .groups_instruction(interpretation_mode, plural)
  paste0(desc, "\n", instr, "\n")
}

.build_group_block_nail_catdes <- function(group_evidence,
                                           interpretation_mode) {
  metrics <- group_evidence$metrics
  counts <- paste0(
    "Selected evidence: ", metrics$n_qualitative_selected,
    "/", metrics$n_qualitative_available, " qualitative marker(s) and ",
    metrics$n_quantitative_selected, "/",
    metrics$n_quantitative_available, " quantitative marker(s)."
  )

  if (!identical(group_evidence$status, "ready")) {
    return(paste(
      counts,
      paste0("Selection status: ", group_evidence$status, "."),
      "*No statistical evidence was selected for this group.*",
      sep = "\n\n"
    ))
  }

  paste(
    counts,
    .format_qualitative_evidence_nail_catdes(
      group_evidence$qualitative_markers,
      interpretation_mode
    ),
    .format_quantitative_evidence_nail_catdes(
      group_evidence$quantitative_markers,
      interpretation_mode
    ),
    sep = "\n\n"
  )
}

.build_prompts_from_interpretation_evidence <- function(
    interpretation_evidence,
    introduction,
    request,
    isolate_groups,
    interpretation_mode,
    target_label,
    prompt_style) {
  group_names <- names(interpretation_evidence$groups)
  group_label <- .unit_label(interpretation_mode)
  data_intro <- .build_data_intro(
    interpretation_mode,
    isolate_groups,
    target_label,
    prompt_style
  )

  if (!isolate_groups) {
    blocks <- vapply(group_names, function(group_name) {
      block <- .build_group_block_nail_catdes(
        interpretation_evidence$groups[[group_name]],
        interpretation_mode
      )
      paste0("## ", group_label, " \"", group_name, "\":\n\n", block)
    }, character(1))

    return(normalize_blank_lines(paste(
      paste0("# Introduction\n\n", introduction),
      paste0("# Task\n\n", request),
      paste0("# Data\n\n", data_intro, "\n", paste(blocks, collapse = "\n\n")),
      sep = "\n\n"
    )))
  }

  prompts <- stats::setNames(vector("list", length(group_names)), group_names)
  for (group_name in group_names) {
    block <- .build_group_block_nail_catdes(
      interpretation_evidence$groups[[group_name]],
      interpretation_mode
    )
    prompts[[group_name]] <- normalize_blank_lines(paste(
      paste0("# Introduction\n\n", introduction),
      paste0("# Task\n\n", request),
      paste0(
        "# Data\n\n", data_intro, "\n\n## ", group_label,
        " \"", group_name, "\":\n\n", block
      ),
      sep = "\n\n"
    ))
  }
  prompts
}

# ---------------------------------------------------------------------------
# Historical guide and request text
# ---------------------------------------------------------------------------

.guide_quali_columns <- function(mode = c("standard", "latent")) {
  mode <- match.arg(mode)

  if (mode == "standard") {
    return(paste(
      "### Characteristic Qualitative Variables",
      "* **Cla/Mod**: Percentage of individuals who selected this modality AND belong to this category.",
      "* **Mod/Cla**: Percentage of individuals WITHIN this category who selected this modality.",
      "* **Global**: Overall percentage of individuals (all categories) who selected this modality.",
      "* **p.value**: Significance level of the test.",
      "* **v.test**: Test value. A positive value means the modality is overrepresented. A negative value means it is underrepresented.",
      sep = "
"
    ))
  }

  paste(
    "### Characteristic Qualitative Variables",
    "* **Cla/Mod**: Percentage of individuals who selected this modality AND belong to this group.",
    "* **Mod/Cla**: Percentage of individuals WITHIN this group who selected this modality.",
    "* **Global**: Overall percentage of individuals (all groups) who selected this modality.",
    "* **p.value**: Significance level of the test.",
    "* **v.test**: Test value. A positive value means the modality is overrepresented. A negative value means it is underrepresented.",
    sep = "
"
  )
}

.guide_quanti_columns <- function(mode = c("standard", "latent")) {
  mode <- match.arg(mode)

  if (mode == "standard") {
    return(paste(
      "### Characteristic Quantitative Variables",
      "* **Mean in category**: The average value of the variable for this category.",
      "* **Overall mean**: The average value of the variable for the entire dataset.",
      "* **sd in category**: The standard deviation of the variable for this category.",
      "* **Overall sd**: The standard deviation of the variable for the entire dataset.",
      "* **p.value**: Significance level of the test.",
      "* **v.test**: A positive value means the category has a significantly higher mean. A negative value means a significantly lower mean.",
      sep = "
"
    ))
  }

  paste(
    "### Characteristic Quantitative Variables",
    "* **Mean in category**: The average value of the variable for this group.",
    "* **Overall mean**: The average value of the variable for the entire dataset.",
    "* **sd in category**: The standard deviation of the variable for this group.",
    "* **Overall sd**: The standard deviation of the variable for the entire dataset.",
    "* **p.value**: Significance level of the test.",
    "* **v.test**: A positive value means the group has a significantly higher mean. A negative value means a significantly lower mean.",
    sep = "
"
  )
}

.guide_compact_vtest <- function() {
  paste(
    "### Reading the results",
    "- For qualitative variables, a positive v.test means that the modality is overrepresented in the category/group; a negative v.test means that it is underrepresented.",
    "- For quantitative variables, a positive v.test means that the category/group has a higher mean than the overall mean; a negative v.test means that it has a lower mean.",
    "- Smaller p.values and larger absolute v.tests indicate stronger evidence.",
    "- Larger p.values or smaller absolute v.tests should be treated as weaker or more tentative tendencies.",
    sep = "\n"
  )
}

# ---------------------------------------------------------------------------
# build_guide_catdes
# ---------------------------------------------------------------------------
build_guide_catdes <- function(interpretation_mode = c("standard", "latent"),
                               target_label  = "the target variable",
                               prompt_style  = c("detailed", "compact"),
                               isolate_groups = FALSE) {

  isolate_groups      <- isTRUE(isolate_groups)
  interpretation_mode <- match.arg(interpretation_mode)
  prompt_style        <- match.arg(prompt_style)

  plural <- !isolate_groups
  desc   <- .groups_description(interpretation_mode, plural, target_label)
  instr  <- .groups_instruction(interpretation_mode, plural)

  header <- paste("## How to Read the Tables", desc, instr, sep = "\n")

  if (prompt_style == "compact") {
    return(paste(header, "", .guide_compact_vtest(), sep = "\n"))
  }

  # detailed
  # Additional lines that differ between standard and latent
  if (interpretation_mode == "standard") {
    no_rename <- if (plural)
      "Do not reinterpret the categories as latent profiles and do not rename them."
    else
      "Do not reinterpret it as a latent profile and do not rename it."

    closing <- if (plural)
      paste(
        "Use the tables as evidence to clarify the meaning of each category.",
        "Use positive and negative v.tests to understand what is overrepresented, underrepresented, higher, or lower in each category.",
        sep = "\n"
      )
    else
      paste(
        "Use the tables as evidence to clarify the meaning of this category.",
        "Use positive and negative v.tests to understand what is overrepresented, underrepresented, higher, or lower in this category.",
        sep = "\n"
      )

    return(paste(
      header, no_rename, "",
      .guide_quali_columns(interpretation_mode), "",
      .guide_quanti_columns(interpretation_mode), "",
      closing,
      sep = "\n"
    ))
  }

  # latent / detailed
  extra_desc <- if (!plural)
    "The group may correspond to a constructed profile or latent class whose meaning must be inferred from the results.\nThe group label is only an identifier and should not be treated as the interpretation of the group.\nUse the results to understand what characterizes this group, what makes it distinctive, and how it differs from the overall dataset."
  else
    "The groups may correspond to constructed profiles or latent classes whose meaning must be inferred from the results.\nThe group labels are only identifiers and should not be treated as the interpretation of the groups.\nUse the results to understand what characterizes each group, what makes it distinctive, and how the groups differ from one another."

  closing <- if (!plural)
    paste(
      "Use the tables as evidence to infer the meaning of this group.",
      "Use positive and negative v.tests to understand what is overrepresented, underrepresented, higher, or lower in this group.",
      sep = "\n"
    )
  else
    paste(
      "Use the tables as evidence to infer the meaning of each group.",
      "Use positive and negative v.tests to understand what is overrepresented, underrepresented, higher, or lower in each group.",
      sep = "\n"
    )

  paste(
    paste("## How to Read the Tables", extra_desc, sep = "\n"), "",
    .guide_quali_columns(interpretation_mode), "",
    .guide_quanti_columns(interpretation_mode), "",
    closing,
    sep = "\n"
  )
}


# ---------------------------------------------------------------------------
# build_request_catdes
# ---------------------------------------------------------------------------
build_request_catdes <- function(interpretation_mode = c("standard", "latent"),
                                 isolate_groups = FALSE,
                                 prompt_style   = c("detailed", "compact")) {

  interpretation_mode <- match.arg(interpretation_mode)
  prompt_style        <- match.arg(prompt_style)
  plural              <- !isolate_groups

  if (interpretation_mode == "standard") {
    if (prompt_style == "compact") {
      if (plural) {
        return(paste(
          "Describe what characterizes each category and what distinguishes it from the others.",
          "For each category, identify the most distinctive results, distinguish strong evidence from more secondary evidence, and say whether the main differences seem expected, unexpected, or mixed.",
          "Do not rename the categories.",
          sep = "\n"
        ))
      } else {
        return(paste(
          "Describe what characterizes this category.",
          "Identify the most distinctive results, distinguish strong evidence from more secondary evidence, and say whether the main characteristics seem expected, unexpected, or mixed.",
          "Do not rename the category.",
          sep = "\n"
        ))
      }
    }
    # detailed
    if (plural) {
      return(paste(
        "Based on the results, describe what characterizes each category and what distinguishes it from the others.",
        "Use the results to clarify the meaning of each category, not to rename it.",
        "For each category, identify the most distinctive characteristics, distinguish the strongest results from the more secondary ones, and comment on whether the main differences seem expected, unexpected, or mixed given the apparent meaning of the categories.",
        "If some categories are more clearly defined than others, say so explicitly.",
        sep = "\n"
      ))
    } else {
      return(paste(
        "Based on the results, describe what characterizes this category.",
        "Use the results to clarify the meaning of this category, not to rename it.",
        "Identify its most distinctive characteristics, distinguish the strongest results from the more secondary ones, and comment on whether its main characteristics seem expected, unexpected, or mixed given the apparent meaning of the category.",
        "If the evidence is weak, ambiguous, or only moderately distinctive, say so explicitly.",
        sep = "\n"
      ))
    }
  }

  # latent
  if (prompt_style == "compact") {
    if (plural) {
      return(paste(
        "Describe what characterizes each group and what distinguishes it from the others.",
        "For each group, identify the most distinctive results, distinguish strong evidence from more secondary evidence, and say whether some groups are clearer or more ambiguous than others.",
        "Then propose a meaningful name for each group.",
        sep = "\n"
      ))
    } else {
      return(paste(
        "Describe what characterizes this group based only on the results shown here.",
        "Do not treat the group label as its interpretation.",
        "Identify the most distinctive results, distinguish strong evidence from more secondary evidence, and say whether the group seems clearly defined or somewhat ambiguous.",
        "Then infer a meaningful name for this group from the results.",
        sep = "\n"
      ))
    }
  }
  # latent / detailed
  if (plural) {
    paste(
      "Based on the results, describe what characterizes each group and what sets it apart from the other groups.",
      "For each group, identify the most distinctive characteristics, distinguish the strongest results from the more secondary ones, and comment on whether some groups seem more clearly defined or more ambiguous than others.",
      "Then, based on these characteristics, propose a meaningful name for each group.",
      sep = "\n"
    )
  } else {
    paste(
      "Based on the results shown here, describe what characterizes this group and what makes it distinctive.",
      "Do not treat the group label as the interpretation of the group.",
      "Identify its most distinctive characteristics, distinguish the strongest results from the more secondary ones, and comment on whether the group appears clearly defined or somewhat ambiguous.",
      "Then, based on these characteristics, propose a meaningful name for this group.",
      sep = "\n"
    )
  }
}




# Keep the historical guide text and add only the traceability rule introduced
# by the statistical_profiles workflow.
.build_guide_catdes_historical <- build_guide_catdes
build_guide_catdes <- function(interpretation_mode = c("standard", "latent"),
                               target_label = "the target variable",
                               prompt_style = c("detailed", "compact"),
                               isolate_groups = FALSE) {
  paste(
    .build_guide_catdes_historical(
      interpretation_mode = interpretation_mode,
      target_label = target_label,
      prompt_style = prompt_style,
      isolate_groups = isolate_groups
    ),
    "Each displayed row includes a stable Evidence ID. Use that ID when referring to a marker.",
    sep = "\n"
  )
}

# ---------------------------------------------------------------------------
# Validation and output helpers
# ---------------------------------------------------------------------------

.validate_zero_one_nail_catdes <- function(x, argument) {
  if (!is.numeric(x) || length(x) != 1L || is.na(x) ||
      !is.finite(x) || x < 0 || x > 1) {
    stop(
      sprintf("`%s` must be a single numeric value in [0, 1].", argument),
      call. = FALSE
    )
  }
  invisible(TRUE)
}

validate_catdes_inputs <- function(dataset = NULL,
                                   num.var = NULL,
                                   x = NULL,
                                   isolate.groups = FALSE,
                                   quali.sample = 1,
                                   quanti.sample = 1,
                                   drop.negative = FALSE,
                                   proba = 0.05,
                                   generate = FALSE,
                                   interpretation_mode = c("standard", "latent"),
                                   prompt_style = c("detailed", "compact")) {
  match.arg(interpretation_mode)
  match.arg(prompt_style)

  if (!is.null(x) && !is.null(dataset)) {
    stop("Provide only one of `x` and `dataset`.", call. = FALSE)
  }
  if (is.null(x) && is.null(dataset)) {
    stop("Provide either `x` or `dataset`.", call. = FALSE)
  }

  if (!is.null(dataset)) {
    assert_data_frame(dataset, "dataset")
    if (ncol(dataset) < 2L) {
      stop("`dataset` must contain at least two columns.", call. = FALSE)
    }
    assert_column_index(num.var, ncol(dataset), "num.var")
  } else if (!is.null(num.var)) {
    stop("`num.var` cannot be used when `x` is supplied.", call. = FALSE)
  }

  assert_single_logical(isolate.groups, "isolate.groups")
  assert_single_logical(drop.negative, "drop.negative")
  assert_single_logical(generate, "generate")
  .validate_zero_one_nail_catdes(quali.sample, "quali.sample")
  .validate_zero_one_nail_catdes(quanti.sample, "quanti.sample")

  if (!is.numeric(proba) || length(proba) != 1L || is.na(proba) ||
      !is.finite(proba) || proba <= 0 || proba > 1) {
    stop("`proba` must be a single numeric value in (0, 1].", call. = FALSE)
  }

  invisible(TRUE)
}

.catdes_no_results_data_frame <- function(model, prompt,
                                           response = "No significant differences found.") {
  data.frame(
    model = model,
    created_at = Sys.time(),
    response = response,
    done = TRUE,
    prompt = prompt,
    stringsAsFactors = FALSE
  )
}

.attach_nail_catdes_artifacts <- function(result,
                                          normalized,
                                          interpretation_evidence,
                                          catdes_settings) {
  attr(result, "statistical_profiles") <- normalized$statistical_profiles
  attr(result, "interpretation_evidence") <- interpretation_evidence
  if (!is.null(normalized$catdes_result)) {
    attr(result, "catdes_result") <- normalized$catdes_result
  }
  attr(result, "catdes_settings") <- catdes_settings
  result
}

# ---------------------------------------------------------------------------
# Public function
# ---------------------------------------------------------------------------

#' Interpret statistical profiles produced from `catdes()`
#'
#' `nail_catdes()` is the autonomous interpretation layer for a categorical
#' typology. Its internal statistical source of truth is always the
#' `statistical_profiles` artifact produced by [nail_catdes_prep()]. The
#' function preserves its historical prompt and backend return forms while
#' removing the former parallel extraction and random sampling workflow.
#'
#' @param dataset Historical raw-data input. A data frame containing the
#'   grouping variable and at least one descriptor. Positional calls such as
#'   `nail_catdes(dataset, num.var)` remain supported.
#' @param num.var Column index of the grouping variable when `dataset` is used.
#' @param x Preferred advanced input. A direct `statistical_profiles` object,
#'   an object carrying a `statistical_profiles` attribute, a raw
#'   [FactoMineR::catdes()] result, or a historical `nail_catdes()` result
#'   carrying a `catdes_result` attribute. Do not supply `x` with `dataset`.
#' @param introduction Optional study context included in the historical
#'   prompt. A default is generated when `NULL`.
#' @param request Optional interpretation request. A default is generated from
#'   `interpretation_mode`, `prompt_style`, and `isolate.groups` when `NULL`.
#' @param model Model name used by the selected provider.
#' @param provider LLM backend, either `"ollama"` or `"gemini"`.
#' @param isolate.groups Logical. If `FALSE`, build one joint prompt. If
#'   `TRUE`, build one prompt per group.
#' @param quali.sample,quanti.sample Numbers in `[0, 1]` controlling only the
#'   deterministic proportion of ranked qualitative or quantitative markers
#'   shown in the prompt. Zero selects none; one selects every eligible marker;
#'   intermediate values retain `ceiling(n * proportion)` top-ranked markers.
#' @param drop.negative Logical. If `TRUE`, underrepresented qualitative
#'   markers and lower quantitative markers are excluded only from the prompt
#'   selection. They remain unchanged in `statistical_profiles`.
#' @param proba Significance threshold used only when raw data must be prepared.
#'   A precomputed `x` is not re-filtered.
#' @param row.w Optional row weights used only with the raw `dataset` path.
#' @param interpretation_mode Either `"standard"` for explicit categories or
#'   `"latent"` for statistically constructed groups.
#' @param prompt_style Either `"detailed"` or `"compact"`.
#' @param generate Logical. If `FALSE`, return the historical prompt form
#'   without contacting a backend. If `TRUE`, send each eligible prompt to the
#'   selected backend.
#' @param ... Provider-specific generation arguments.
#'
#' @details
#' ## Single statistical source
#'
#' With raw data, `nail_catdes_prep()` is called exactly once and performs the
#' only `catdes()` computation. With a prepared `statistical_profiles` object,
#' neither `nail_catdes_prep()` nor `FactoMineR::catdes()` is called.
#'
#' All groups, marker tables, directions, v-tests, p-values, ranks, metrics,
#' and evidence identifiers are read from `statistical_profiles`. The original
#' `catdes_result` is retained only for compatibility and inspection.
#'
#' For route invariance, the raw-data path stores its source-specific
#' preparation provenance in `catdes_settings$preparation_input` and exposes a
#' canonical `statistical_profiles` object equivalent to preparing the same
#' precomputed `catdes_result` through `x`.
#'
#' ## Prompt selection
#'
#' A separate `interpretation_evidence` artifact is derived deterministically
#' from the complete profiles. Selection follows the precomputed marker rank,
#' then `evidence_id` for deterministic tie breaking. No call to `sample()` and
#' no random tie handling is used. Each displayed marker retains its original
#' evidence ID.
#'
#' Groups with no available or selected marker remain represented in
#' `interpretation_evidence`. No LLM call is made for an empty isolated group.
#'
#' ## Transitional return contract
#'
#' The historical main return forms are intentionally preserved for this
#' transition step: a character prompt or named list of prompts when
#' `generate = FALSE`, and backend data frames or a named list of backend
#' results when `generate = TRUE`. A new main output class is deferred to the
#' next refactoring stage.
#'
#' Every successful return carries the attributes `statistical_profiles`,
#' `interpretation_evidence`, `catdes_result` when available, and
#' `catdes_settings`.
#'
#' @return The historical prompt or backend result form, augmented with the
#'   mechanical attributes described above.
#'
#' @importFrom dplyr mutate filter arrange desc pull select slice_sample group_by n ungroup
#' @importFrom glue glue
#' @importFrom tibble rownames_to_column column_to_rownames
#' @importFrom stats quantile
#' @importFrom rlang sym
#' @importFrom FactoMineR catdes
#' @export
#'
#' @examples
#' data(iris)
#'
#' # Historical raw-data interface.
#' prompt <- nail_catdes(
#'   dataset = iris,
#'   num.var = 5,
#'   generate = FALSE
#' )
#' attr(prompt, "statistical_profiles")
#'
#' # Recommended advanced interface.
#' catdes_result <- FactoMineR::catdes(iris, num.var = 5, proba = 0.05)
#' profiles <- nail_catdes_prep(catdes_result)
#' prompt_from_profiles <- nail_catdes(x = profiles, generate = FALSE)
#' identical(attr(prompt_from_profiles, "statistical_profiles"), profiles)
#' \dontrun{
#' generated <- nail_catdes(
#'   x = profiles,
#'   provider = "ollama",
#'   model = "llama3",
#'   generate = TRUE
#' )
#' }
nail_catdes <- function(dataset = NULL,
                        num.var = NULL,
                        introduction = NULL,
                        request = NULL,
                        model = "llama3",
                        provider = c("ollama", "gemini"),
                        isolate.groups = FALSE,
                        quali.sample = 1,
                        quanti.sample = 1,
                        drop.negative = FALSE,
                        proba = 0.05,
                        row.w = NULL,
                        interpretation_mode = c("standard", "latent"),
                        prompt_style = c("detailed", "compact"),
                        generate = FALSE,
                        x = NULL,
                        ...) {
  interpretation_mode <- match.arg(interpretation_mode)
  prompt_style <- match.arg(prompt_style)
  provider <- match.arg(provider)

  validate_catdes_inputs(
    dataset = dataset,
    num.var = num.var,
    x = x,
    isolate.groups = isolate.groups,
    quali.sample = quali.sample,
    quanti.sample = quanti.sample,
    drop.negative = drop.negative,
    proba = proba,
    generate = generate,
    interpretation_mode = interpretation_mode,
    prompt_style = prompt_style
  )

  normalized <- .normalize_nail_catdes_input(
    x = x,
    dataset = dataset,
    num.var = num.var,
    proba = proba,
    row.w = row.w
  )
  profiles <- normalized$statistical_profiles

  interpretation_evidence <- .build_interpretation_evidence_nail_catdes(
    statistical_profiles = profiles,
    quali_sample = quali.sample,
    quanti_sample = quanti.sample,
    drop_negative = drop.negative
  )

  if (is.null(introduction)) {
    introduction <- if (interpretation_mode == "standard") {
      "For this study, observations were described according to an explicit categorical variable."
    } else {
      "For this study, observations were grouped according to their similarities."
    }
  }

  if (is.null(request)) {
    request <- build_request_catdes(
      interpretation_mode = interpretation_mode,
      isolate_groups = isolate.groups,
      prompt_style = prompt_style
    )
  }

  guide <- build_guide_catdes(
    interpretation_mode = interpretation_mode,
    target_label = normalized$target_label,
    prompt_style = prompt_style,
    isolate_groups = isolate.groups
  )
  introduction_with_guide <- paste(
    introduction,
    guide,
    sep = "\n\n---\n\n"
  )

  prompts <- .build_prompts_from_interpretation_evidence(
    interpretation_evidence = interpretation_evidence,
    introduction = introduction_with_guide,
    request = request,
    isolate_groups = isolate.groups,
    interpretation_mode = interpretation_mode,
    target_label = normalized$target_label,
    prompt_style = prompt_style
  )

  n_ready_groups <- interpretation_evidence$metadata$n_ready_groups
  n_selected <- interpretation_evidence$metadata$n_selected_evidence
  llm_calls <- if (!isTRUE(generate)) {
    0L
  } else if (!isTRUE(isolate.groups)) {
    as.integer(n_selected > 0L)
  } else {
    as.integer(n_ready_groups)
  }

  catdes_settings <- list(
    source_type = normalized$source_type,
    preparation_performed = normalized$preparation_performed,
    nail_catdes_prep_calls = normalized$metadata$nail_catdes_prep_calls,
    direct_catdes_calls_in_nail_catdes = 0L,
    proba = profiles$settings$proba,
    requested_proba = proba,
    proba_reapplied_to_prepared_profiles = FALSE,
    interpretation_mode = interpretation_mode,
    prompt_style = prompt_style,
    isolate_groups = isolate.groups,
    quali_sample = quali.sample,
    quanti_sample = quanti.sample,
    drop_negative = drop.negative,
    generate = generate,
    provider = provider,
    model = model,
    llm_calls = llm_calls,
    target_label = normalized$target_label,
    preparation_input = normalized$metadata$preparation_input,
    statistical_profiles_canonicalized = isTRUE(
      normalized$metadata$statistical_profiles_canonicalized
    )
  )

  if (!generate) {
    return(.attach_nail_catdes_artifacts(
      prompts,
      normalized,
      interpretation_evidence,
      catdes_settings
    ))
  }

  llm_api_options <- list(...)
  call_llm <- function(prompt) {
    response <- .call_llm_base(
      provider = provider,
      model = model,
      prompt = prompt,
      output = "df",
      llm_api_options = llm_api_options
    )
    response$prompt <- prompt
    response
  }

  if (!isolate.groups) {
    result <- if (n_selected == 0L) {
      message("Execution halted: No selected statistical evidence. Nothing to generate.")
      .catdes_no_results_data_frame(
        model = model,
        prompt = prompts,
        response = "No selected statistical evidence found."
      )
    } else {
      call_llm(prompts)
    }

    return(.attach_nail_catdes_artifacts(
      result,
      normalized,
      interpretation_evidence,
      catdes_settings
    ))
  }

  result <- stats::setNames(vector("list", length(prompts)), names(prompts))
  for (group_name in names(prompts)) {
    group_evidence <- interpretation_evidence$groups[[group_name]]
    result[[group_name]] <- if (identical(group_evidence$status, "ready")) {
      call_llm(prompts[[group_name]])
    } else {
      .catdes_no_results_data_frame(
        model = model,
        prompt = prompts[[group_name]],
        response = paste0(
          "No selected statistical evidence found for group '",
          group_name,
          "'."
        )
      )
    }
  }

  .attach_nail_catdes_artifacts(
    result,
    normalized,
    interpretation_evidence,
    catdes_settings
  )
}
