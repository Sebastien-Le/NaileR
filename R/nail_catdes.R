

# ===========================================================================
# UTILS — vocabulary helpers
# ===========================================================================
# All the mode-dependent vocabulary is centralised here.
# Every other function calls these helpers instead of duplicating strings.

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

.groups_description <- function(mode, plural = FALSE, target_label = "the target variable") {
  if (mode == "standard") {
    unit <- .unit_noun(mode, plural)
    if (plural) {
      paste0("The ", unit, " below correspond to the explicit ", unit, " of '", target_label, "'.")
    } else {
      paste0("The ", unit, " below is one of the explicit ", unit, " of '", target_label, "'.")
    }
  } else {
    if (plural) {
      paste(
        "The groups below correspond to constructed profiles or latent classes.",
        "The group labels are only identifiers and should not be treated as the interpretation of the groups.",
        sep = "\n"
      )
    } else {
      paste(
        "The group below corresponds to a constructed profile or latent class.",
        "The group label is only an identifier and should not be treated as the interpretation of the group.",
        sep = "\n"
      )
    }
  }
}

.groups_instruction <- function(mode, plural = FALSE) {
  if (mode == "standard") {
    if (plural) {
      "Use the results to understand what characterizes each category and what distinguishes it from the others."
    } else {
      "Use the results to understand what characterizes this category."
    }
  } else {
    if (plural) {
      "Use the results to infer what characterizes each group and how the groups differ from one another."
    } else {
      "Use the results to infer what characterizes this group and how it differs from the overall dataset."
    }
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


# ===========================================================================
# UTILS — shared loop body for get_sentences_quali / get_sentences_quanti
# ===========================================================================

.sort_stats_rows <- function(df, sort_col = "v.test") {
  if (
    !is.null(sort_col) &&
    sort_col %in% colnames(df) &&
    is.numeric(df[[sort_col]])
  ) {
    ord <- order(df[[sort_col]], decreasing = TRUE, na.last = TRUE)
    return(df[ord, , drop = FALSE])
  }

  df
}

.sample_stats_rows <- function(df, sample_pct = 1, sort_col = "v.test", bins = 5) {
  if (!is.data.frame(df) || nrow(df) == 0) {
    return(df)
  }

  sample_pct <- as.numeric(sample_pct)[1]

  if (is.na(sample_pct) || sample_pct < 0 || sample_pct > 1) {
    stop("`sample_pct` must be a single number between 0 and 1.", call. = FALSE)
  }

  if (sample_pct >= 1) {
    return(df)
  }

  if (sample_pct <= 0) {
    return(df[0, , drop = FALSE])
  }

  n <- nrow(df)
  n_keep <- max(1L, ceiling(n * sample_pct))

  if (n_keep >= n) {
    return(df)
  }

  x <- NULL
  if (
    !is.null(sort_col) &&
    sort_col %in% colnames(df) &&
    is.numeric(df[[sort_col]])
  ) {
    x <- df[[sort_col]]
  } else {
    is_num_col <- vapply(df, is.numeric, logical(1))
    if (any(is_num_col)) {
      x <- df[[which(is_num_col)[1]]]
    }
  }

  if (is.null(x) || all(!is.finite(x))) {
    idx <- sample(seq_len(n), n_keep)
    return(.sort_stats_rows(df[idx, , drop = FALSE], sort_col = sort_col))
  }

  ok <- is.finite(x)
  ranks <- rep(NA_real_, n)
  ranks[ok] <- rank(x[ok], ties.method = "random")

  n_bins <- min(as.integer(bins), sum(ok), n_keep)
  n_bins <- max(1L, n_bins)

  bin_id <- rep(n_bins + 1L, n)
  if (any(ok)) {
    bin_id[ok] <- pmin(
      n_bins,
      pmax(1L, ceiling(ranks[ok] / max(ranks[ok]) * n_bins))
    )
  }

  ids_by_bin <- split(seq_len(n), bin_id)
  idx <- unlist(
    lapply(ids_by_bin, function(ids) {
      k <- max(1L, ceiling(length(ids) * sample_pct))
      k <- min(length(ids), k)
      sample(ids, k)
    }),
    use.names = FALSE
  )

  idx <- unique(idx)

  if (length(idx) > n_keep) {
    idx <- sample(idx, n_keep)
  }

  if (length(idx) < n_keep) {
    remaining <- setdiff(seq_len(n), idx)
    idx <- c(idx, sample(remaining, n_keep - length(idx)))
  }

  .sort_stats_rows(df[idx, , drop = FALSE], sort_col = sort_col)
}

.prepare_stats_df <- function(res_mat, group_name, cols_to_show,
                              sample_pct, entity) {
  if (!is.data.frame(res_mat) || nrow(res_mat) == 0 || ncol(res_mat) == 0) {
    message(glue::glue("Skipping group {group_name}: empty or invalid data ({entity})."))
    return(NULL)
  }

  is_num_col <- sapply(res_mat, is.numeric)
  if (!any(is_num_col)) {
    message(glue::glue("Skipping group {group_name}: no numeric column found ({entity})."))
    return(NULL)
  }

  sort_col <- if ("v.test" %in% colnames(res_mat) && is.numeric(res_mat[["v.test"]])) {
    "v.test"
  } else {
    colnames(res_mat)[which(is_num_col)[1]]
  }

  df <- .sample_stats_rows(
    res_mat,
    sample_pct = sample_pct,
    sort_col   = sort_col,
    bins       = 5
  )

  cols_exist <- cols_to_show[cols_to_show %in% colnames(df)]
  if (length(cols_exist) == 0 || !"v.test" %in% colnames(df)) {
    message(glue::glue("Skipping group {group_name}: no standard stat/v.test columns found ({entity})."))
    return(NULL)
  }

  df[, cols_exist, drop = FALSE]
}

# ---------------------------------------------------------------------------
# get_sentences_quali
# ---------------------------------------------------------------------------
get_sentences_quali <- function(res_cd, quali.sample, drop.negative,
                                interpretation_mode = c("standard", "latent")) {
  interpretation_mode <- match.arg(interpretation_mode)
  res_cd <- res_cd$category
  ppts   <- list()

  cols_to_show <- c("Cla/Mod", "Mod/Cla", "Global", "p.value", "v.test")

  for (i in seq_along(res_cd)) {
    group_name <- names(res_cd)[i]
    res_mat    <- as.data.frame(res_cd[[i]])

    df <- .prepare_stats_df(res_mat, group_name, cols_to_show,
                            sample_pct = quali.sample, entity = "quali")
    if (is.null(df)) { ppts[[group_name]] <- ""; next }

    if (isTRUE(drop.negative)) df <- dplyr::filter(df, .data$v.test > 0)

    ppts[[group_name]] <- format_stats_as_markdown(
      df_stats = df,
      title    = .quali_title(interpretation_mode)
    )
  }
  ppts
}

# ---------------------------------------------------------------------------
# get_sentences_quanti
# ---------------------------------------------------------------------------
get_sentences_quanti <- function(res_cd, quanti.sample, drop.negative,
                                 interpretation_mode = c("standard", "latent")) {
  interpretation_mode <- match.arg(interpretation_mode)
  res_cd <- res_cd$quanti
  ppts   <- list()

  cols_to_show <- c("Mean in category", "Overall mean",
                    "sd in category",   "Overall sd",
                    "p.value",          "v.test")

  for (i in seq_along(res_cd)) {
    group_name <- names(res_cd)[i]
    res_mat    <- as.data.frame(res_cd[[i]])

    df <- .prepare_stats_df(res_mat, group_name, cols_to_show,
                            sample_pct = quanti.sample, entity = "quanti")
    if (is.null(df)) { ppts[[group_name]] <- ""; next }

    if (isTRUE(drop.negative)) df <- dplyr::filter(df, .data$v.test > 0)

    ppts[[group_name]] <- format_stats_as_markdown(
      df_stats = df,
      title    = .quanti_title(interpretation_mode)
    )
  }
  ppts
}


# ===========================================================================
# UTILS — shared block builder for get_prompt_catdes
# ===========================================================================

.build_data_intro <- function(interpretation_mode, isolate_groups,
                              target_label, prompt_style) {
  plural <- !isolate_groups
  desc   <- .groups_description(interpretation_mode, plural, target_label)
  instr  <- .groups_instruction(interpretation_mode, plural)
  paste0(desc, "
", instr, "
")
}

.build_group_block <- function(qual_text, quant_text) {
  qual  <- if (!is.null(qual_text)  && nzchar(trimws(qual_text)))  qual_text  else NULL
  quant <- if (!is.null(quant_text) && nzchar(trimws(quant_text))) quant_text else NULL
  parts <- c(qual, quant)
  paste(parts[!sapply(parts, is.null)], collapse = "\n\n")
}


# ---------------------------------------------------------------------------
# get_prompt_catdes
# ---------------------------------------------------------------------------
get_prompt_catdes <- function(res_cd, introduction, request, isolate.groups,
                              quali.sample, quanti.sample, drop.negative,
                              interpretation_mode = c("standard", "latent"),
                              target_label = "the target variable",
                              prompt_style = c("detailed", "compact")) {

  interpretation_mode <- match.arg(interpretation_mode)
  prompt_style        <- match.arg(prompt_style)

  stces_quali  <- if ("category" %in% names(res_cd))
    get_sentences_quali( res_cd, quali.sample,  drop.negative, interpretation_mode)
  else list()

  stces_quanti <- if ("quanti" %in% names(res_cd))
    get_sentences_quanti(res_cd, quanti.sample, drop.negative, interpretation_mode)
  else list()

  if (length(stces_quali) == 0 && length(stces_quanti) == 0)
    stop("No significant differences between groups, execution was halted.")

  all_groups <- union(names(stces_quali), names(stces_quanti))
  grp_label  <- .unit_label(interpretation_mode)

  data_intro <- .build_data_intro(interpretation_mode, isolate.groups,
                                  target_label, prompt_style)

  header <- glue::glue(
    "# Introduction\n\n{introduction}\n\n",
    "# Task\n\n{request}\n\n",
    "# Data\n\n{data_intro}\n\n"
  )

  # ── non-isolated: one single prompt ────────────────────────────────────────
  if (!isolate.groups) {
    stces <- character(0)
    for (grp in all_groups) {
      block <- .build_group_block(stces_quali[[grp]], stces_quanti[[grp]])
      if (nzchar(block))
        stces <- c(stces, glue::glue('## {grp_label} "{grp}":\n\n{block}'))
    }
    body <- paste(stces, collapse = "\n\n")
    out  <- paste(header, body, sep = "\n\n")
    return(normalize_blank_lines(out))
  }

  # ── isolated: one prompt per group ─────────────────────────────────────────
  prompts <- list()
  for (grp in all_groups) {
    block <- .build_group_block(stces_quali[[grp]], stces_quanti[[grp]])
    if (nzchar(block)) {
      prompt_i <- paste(
        glue::glue("# Introduction\n\n{introduction}"),
        glue::glue("# Task\n\n{request}"),
        glue::glue("# Data\n\n{data_intro}\n\n## {grp_label} \"{grp}\":\n\n{block}"),
        sep = "\n\n"
      )
      prompts[[grp]] <- normalize_blank_lines(prompt_i)
    }
  }
  prompts
}


# ===========================================================================
# UTILS — shared table-column definitions for build_guide_catdes
# ===========================================================================

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

  # ── detailed ───────────────────────────────────────────────────────────────
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
          "For each category, identify its main coherent characteristics and distinguish the central interpretive pattern from more secondary displayed characteristics, and say whether the main differences seem expected, unexpected, or mixed.",
          "You may synthesize several displayed results into a higher-level interpretation when the connection is reasonable and traceable; do not present that synthesis as a new statistical fact.",
          "Do not rename the categories.",
          sep = "\n"
        ))
      } else {
        return(paste(
          "Describe what characterizes this category.",
          "Identify its main coherent characteristics and distinguish the central interpretive pattern from more secondary displayed characteristics, and say whether the main characteristics seem expected, unexpected, or mixed.",
          "You may synthesize several displayed results into a higher-level interpretation when the connection is reasonable and traceable; do not present that synthesis as a new statistical fact.",
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
        "For each category, identify its main coherent characteristics and distinguish the central interpretive pattern from more secondary displayed characteristics, and comment on whether the main differences seem expected, unexpected, or mixed given the apparent meaning of the categories.",
        "You may synthesize several displayed characteristics into a higher-level interpretation when the connection is reasonable and traceable; do not present that synthesis as a new statistical fact.",
        "If some categories are more clearly defined than others, say so explicitly.",
        sep = "\n"
      ))
    } else {
      return(paste(
        "Based on the results, describe what characterizes this category.",
        "Use the results to clarify the meaning of this category, not to rename it.",
        "Identify its main coherent characteristics and distinguish the central interpretive pattern from more secondary displayed characteristics, and comment on whether its main characteristics seem expected, unexpected, or mixed given the apparent meaning of the category.",
        "You may synthesize several displayed characteristics into a higher-level interpretation when the connection is reasonable and traceable; do not present that synthesis as a new statistical fact.",
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
        "For each group, identify its main coherent characteristics and distinguish the central interpretive pattern from more secondary displayed characteristics, and say whether some groups are clearer or more ambiguous than others.",
        "Then propose a meaningful name for each group.",
        sep = "\n"
      ))
    } else {
      return(paste(
        "Describe what characterizes this group based only on the results shown here.",
        "Do not treat the group label as its interpretation.",
        "Identify its main coherent characteristics and distinguish the central interpretive pattern from more secondary displayed characteristics, and say whether the group seems clearly defined or somewhat ambiguous.",
        "Then infer a meaningful name for this group from the results.",
        sep = "\n"
      ))
    }
  }
  # latent / detailed
  if (plural) {
    paste(
      "Based on the results, describe what characterizes each group and what sets it apart from the other groups.",
      "For each group, identify its main coherent characteristics and distinguish the central interpretive pattern from more secondary displayed characteristics, and comment on whether some groups seem more clearly defined or more ambiguous than others.",
      "Then, based on these characteristics, propose a meaningful name for each group.",
      sep = "\n"
    )
  } else {
    paste(
      "Based on the results shown here, describe what characterizes this group and what makes it distinctive.",
      "Do not treat the group label as the interpretation of the group.",
      "Identify its main coherent characteristics and distinguish the central interpretive pattern from more secondary displayed characteristics, and comment on whether the group appears clearly defined or somewhat ambiguous.",
      "Then, based on these characteristics, propose a meaningful name for this group.",
      sep = "\n"
    )
  }
}



# ---------------------------------------------------------------------------
# Validation
# ---------------------------------------------------------------------------



# ===========================================================================
# MODERN MECHANICAL CORE — statistical_profiles as canonical source
# ===========================================================================

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

  input <- attr(profiles, "catdes_input", exact = TRUE)

  if (is.null(input) && is.list(profiles$metadata$input)) {
    input <- profiles$metadata$input
  }

  group_variable <- NULL

  if (is.list(input) &&
      is.character(input$group_variable) &&
      length(input$group_variable) == 1L &&
      !is.na(input$group_variable) &&
      nzchar(input$group_variable)) {
    group_variable <- input$group_variable
  }

  canonical_input <- list(
    source = "x",
    proba_applied_by_function = FALSE,
    declared_proba = proba,
    group_variable = group_variable
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
      proba = statistical_profiles$settings$proba,
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
# Semantic-facing factual representation
# ---------------------------------------------------------------------------
# `interpretation_evidence` remains the canonical selected statistical subset.
# This layer converts it into plain-language factual statements before any LLM
# call. Evidence IDs remain available for audit but are deliberately not shown
# in the semantic prompt.

.format_catdes_plain_number <- function(x, digits = 2L) {
  value <- suppressWarnings(as.numeric(x)[1L])
  if (length(value) == 0L || is.na(value) || !is.finite(value)) {
    return("NA")
  }
  formatC(value, digits = digits, format = "f")
}

.format_catdes_plain_percent <- function(x) {
  value <- suppressWarnings(as.numeric(x)[1L])
  if (length(value) == 0L || is.na(value) || !is.finite(value)) {
    return("NA")
  }
  paste0(.format_catdes_plain_number(value, 2L), "%")
}

.clean_catdes_plain_text <- function(x) {
  x <- as.character(x)[1L]
  if (length(x) == 0L || is.na(x)) {
    return("<missing>")
  }
  x <- gsub("[\r\n]+", " ", x)
  trimws(x)
}

.display_variable_label_nail_catdes <- function(x) {
  x <- .clean_catdes_plain_text(x)
  if (identical(x, "<missing>")) {
    return(x)
  }

  # Variable names can originate from syntactic names created by R
  # (e.g. "Petal.Length" or a full questionnaire item with dots).
  # Humanise them only for the semantic-facing prompt; the canonical
  # statistical objects keep the original variable name unchanged.
  x <- gsub("[._]+", " ", x)
  x <- gsub("\\s+", " ", x)
  x <- trimws(x)
  x <- sub("[[:space:]]+$", "", x)
  x
}

.normalize_display_key_nail_catdes <- function(x) {
  x <- tolower(.clean_catdes_plain_text(x))
  gsub("[^[:alnum:]]+", "", x)
}

.display_modality_label_nail_catdes <- function(modality, variable) {
  modality <- .clean_catdes_plain_text(modality)
  if (identical(modality, "<missing>")) {
    return(modality)
  }

  variable_display <- .display_variable_label_nail_catdes(variable)

  # FactoMineR row names for questionnaire items can encode the whole
  # proposition in the modality, e.g.
  # "Question text._Totally acceptable".
  # Strip that duplicated prefix only when it clearly matches the variable.
  underscore_positions <- gregexpr("_", modality, fixed = TRUE)[[1L]]
  if (length(underscore_positions) > 0L && underscore_positions[1L] != -1L) {
    pos <- tail(underscore_positions, 1L)
    prefix <- substr(modality, 1L, pos - 1L)
    suffix <- substr(modality, pos + 1L, nchar(modality))

    if (nzchar(suffix) &&
        identical(
          .normalize_display_key_nail_catdes(prefix),
          .normalize_display_key_nail_catdes(variable_display)
        )) {
      return(trimws(suffix))
    }
  }

  modality
}

.qualitative_frequency_word_nail_catdes <- function(direction) {
  direction <- tolower(as.character(direction)[1L])
  if (identical(direction, "overrepresented")) {
    return("MORE FREQUENT")
  }
  if (identical(direction, "underrepresented")) {
    return("LESS FREQUENT")
  }
  "DIFFERENT IN FREQUENCY"
}

.quantitative_mean_word_nail_catdes <- function(direction) {
  direction <- tolower(as.character(direction)[1L])
  if (identical(direction, "higher")) {
    return("HIGHER")
  }
  if (identical(direction, "lower")) {
    return("LOWER")
  }
  "DIFFERENT"
}

.source_data_from_profiles_nail_catdes <- function(statistical_profiles) {
  catdes_result <- attr(statistical_profiles, "catdes_result", exact = TRUE)
  if (!is.null(catdes_result) &&
      !is.null(catdes_result$call) &&
      !is.null(catdes_result$call$X)) {
    return(catdes_result$call$X)
  }
  NULL
}

.is_binary_qualitative_variable_nail_catdes <- function(statistical_profiles,
                                                          variable) {
  variable <- as.character(variable)[1L]
  source_data <- .source_data_from_profiles_nail_catdes(statistical_profiles)

  if (!is.null(source_data) && variable %in% colnames(source_data)) {
    values <- unique(as.character(source_data[[variable]][!is.na(source_data[[variable]])]))
    return(length(values) == 2L)
  }

  all_qualitative <- lapply(
    statistical_profiles$groups,
    function(group) group$qualitative_markers
  )
  all_qualitative <- all_qualitative[vapply(all_qualitative, is.data.frame, logical(1))]
  if (length(all_qualitative) == 0L) {
    return(FALSE)
  }

  all_qualitative <- dplyr::bind_rows(all_qualitative)
  if (nrow(all_qualitative) == 0L || !"variable" %in% names(all_qualitative)) {
    return(FALSE)
  }

  rows <- all_qualitative[
    as.character(all_qualitative$variable) == variable,
    ,
    drop = FALSE
  ]
  if (nrow(rows) == 0L) {
    return(FALSE)
  }

  modalities <- unique(as.character(rows$modality))
  modalities <- modalities[!is.na(modalities)]
  length(modalities) == 2L
}

.qualitative_fact_text_nail_catdes <- function(row) {
  variable_label <- .display_variable_label_nail_catdes(row$variable)
  modality_label <- .display_modality_label_nail_catdes(
    row$modality,
    row$variable
  )

  paste0(
    'The response/modality "', modality_label,
    '" for variable/proposition "', variable_label,
    '" is ', .qualitative_frequency_word_nail_catdes(row$direction),
    ' in this group than in the full sample ',
    '(group=', .format_catdes_plain_percent(row$percentage_in_group),
    '; full sample=', .format_catdes_plain_percent(row$global_percentage), ').'
  )
}

.qualitative_prompt_line_nail_catdes <- function(row) {
  modality_label <- .display_modality_label_nail_catdes(
    row$modality,
    row$variable
  )

  paste0(
    'The response/modality "', modality_label,
    '" is ', .qualitative_frequency_word_nail_catdes(row$direction),
    ' in this group than in the full sample ',
    '(group=', .format_catdes_plain_percent(row$percentage_in_group),
    '; full sample=', .format_catdes_plain_percent(row$global_percentage), ').'
  )
}

.quantitative_fact_text_nail_catdes <- function(row) {
  paste0(
    'The mean of "', .display_variable_label_nail_catdes(row$variable), '" is ',
    .quantitative_mean_word_nail_catdes(row$direction),
    ' in this group than in the full sample ',
    '(group mean=', .format_catdes_plain_number(row$group_mean),
    '; full-sample mean=', .format_catdes_plain_number(row$overall_mean), ').'
  )
}

.build_semantic_facing_evidence_nail_catdes <- function(statistical_profiles,
                                                         interpretation_evidence) {
  .validate_statistical_profiles_nail_catdes(statistical_profiles)

  group_names <- names(interpretation_evidence$groups)
  groups <- stats::setNames(vector("list", length(group_names)), group_names)
  n_displayed <- 0L
  n_added_binary <- 0L

  for (group_name in group_names) {
    selected <- interpretation_evidence$groups[[group_name]]
    qualitative_selected <- .order_markers_for_nail_catdes(selected$qualitative_markers)
    quantitative_selected <- .order_markers_for_nail_catdes(selected$quantitative_markers)

    fact_tables <- list()
    fact_text <- character(0)
    k <- 0L

    if (is.data.frame(qualitative_selected) && nrow(qualitative_selected) > 0L) {
      selected_variables <- unique(as.character(qualitative_selected$variable))
      full_qualitative <- statistical_profiles$groups[[group_name]]$qualitative_markers

      for (variable in selected_variables) {
        selected_block <- qualitative_selected[
          as.character(qualitative_selected$variable) == variable,
          ,
          drop = FALSE
        ]
        selected_block <- .order_markers_for_nail_catdes(selected_block)

        binary <- .is_binary_qualitative_variable_nail_catdes(
          statistical_profiles,
          variable
        )

        if (isTRUE(binary)) {
          block <- full_qualitative[
            as.character(full_qualitative$variable) == variable,
            ,
            drop = FALSE
          ]
          if (isTRUE(interpretation_evidence$settings$drop_negative)) {
            block <- block[
              !(block$direction %in% "underrepresented"),
              ,
              drop = FALSE
            ]
          }
          block <- .order_markers_for_nail_catdes(block)
          if (nrow(block) == 0L) {
            block <- selected_block
          }
          block_type <- "binary_complete_contrast"
        } else {
          block <- selected_block
          block_type <- "multilevel_selected_only"
        }

        block$display_origin <- ifelse(
          block$evidence_id %in% selected_block$evidence_id,
          "selected",
          "completed_binary_contrast"
        )
        block$representation_block <- block_type
        block$factual_statement <- vapply(
          seq_len(nrow(block)),
          function(i) .qualitative_fact_text_nail_catdes(block[i, , drop = FALSE]),
          character(1)
        )
        block$prompt_statement <- vapply(
          seq_len(nrow(block)),
          function(i) .qualitative_prompt_line_nail_catdes(block[i, , drop = FALSE]),
          character(1)
        )

        fact_text <- c(
          fact_text,
          paste0('- For variable/proposition "', .display_variable_label_nail_catdes(variable), '":'),
          paste0("  - ", block$prompt_statement)
        )

        k <- k + 1L
        fact_tables[[k]] <- block
      }
    }

    if (is.data.frame(quantitative_selected) && nrow(quantitative_selected) > 0L) {
      block <- quantitative_selected
      block$display_origin <- "selected"
      block$representation_block <- "quantitative_selected"
      block$factual_statement <- vapply(
        seq_len(nrow(block)),
        function(i) .quantitative_fact_text_nail_catdes(block[i, , drop = FALSE]),
        character(1)
      )
      fact_text <- c(fact_text, paste0("- ", block$factual_statement))
      k <- k + 1L
      fact_tables[[k]] <- block
    }

    displayed <- if (length(fact_tables) > 0L) {
      dplyr::bind_rows(fact_tables)
    } else {
      interpretation_evidence$selected_evidence_registry[0, , drop = FALSE]
    }

    added_binary <- if (is.data.frame(displayed) && nrow(displayed) > 0L) {
      sum(displayed$display_origin == "completed_binary_contrast", na.rm = TRUE)
    } else {
      0L
    }

    status <- selected$status
    text <- if (length(fact_text) == 0L) {
      "*No selected statistical evidence for this group.*"
    } else {
      paste(fact_text, collapse = "\n")
    }

    groups[[group_name]] <- list(
      group = group_name,
      status = status,
      selected_evidence_ids = selected$selected_evidence_ids,
      displayed_evidence = displayed,
      text = text,
      metrics = list(
        n_selected = as.integer(length(selected$selected_evidence_ids)),
        n_displayed = as.integer(if (is.data.frame(displayed)) nrow(displayed) else 0L),
        n_added_binary_contrast = as.integer(added_binary)
      )
    )

    n_displayed <- n_displayed + groups[[group_name]]$metrics$n_displayed
    n_added_binary <- n_added_binary + groups[[group_name]]$metrics$n_added_binary_contrast
  }

  out <- list(
    groups = groups,
    settings = list(
      representation = "hybrid_plain",
      qualitative_binary_rule = paste(
        "When a selected qualitative variable is binary, display every",
        "significant modality available for that variable in the group."
      ),
      qualitative_multilevel_rule = paste(
        "For multi-level qualitative variables, display only modalities",
        "selected by the deterministic sampling step."
      ),
      quantitative_rule = paste(
        "Display selected quantitative markers as plain-language higher/lower",
        "mean facts."
      ),
      llm_exposes_evidence_ids = FALSE,
      llm_exposes_p_values = FALSE,
      llm_exposes_v_tests = FALSE
    ),
    metadata = list(
      schema = "NaileR::catdes_semantic_facing_evidence",
      schema_version = "1.0.0",
      source_schema = interpretation_evidence$metadata$schema,
      n_groups = as.integer(length(groups)),
      n_selected_evidence = as.integer(
        interpretation_evidence$metadata$n_selected_evidence
      ),
      n_displayed_evidence = as.integer(n_displayed),
      n_added_binary_contrast = as.integer(n_added_binary)
    )
  )
  class(out) <- c("nail_catdes_semantic_facing_evidence", "list")
  out
}

.reading_nail_catdes <- function(interpretation_mode,
                                 joint = FALSE) {
  unit <- .unit_noun(interpretation_mode)

  if (isTRUE(joint)) {
    return(paste(
      "R has already performed the statistical analysis.",
      paste0(
        "Read each statement below as a factual comparison between the ",
        unit, " under which it appears and the full sample."
      ),
      paste0(
        "MORE FREQUENT and LESS FREQUENT describe relative modality prevalence in that ",
        unit, "."
      ),
      paste0(
        "HIGHER and LOWER describe that ", unit,
        "'s mean relative to the full-sample mean for the same variable."
      ),
      paste0(
        "When percentages are shown, the ", unit,
        " percentage describes the modality within that ", unit,
        " and the full-sample percentage describes the same modality in the full sample; these are descriptive values, not p-values or measures of statistical strength."
      ),
      paste0(
        "When means are shown, compare each ", unit,
        " mean only with the full-sample mean for that same variable; do not compare mean values across variables as if they shared one scale."
      ),
      "An undisplayed modality or variable is not thereby absent, average, rejected, or unimportant.",
      "You may compare the displayed profiles, but do not present a contrast between two categories/groups as a direct pairwise statistical test unless such a test is explicitly shown.",
      sep = "\n"
    ))
  }

  paste(
    "R has already performed the statistical analysis.",
    paste0(
      "Read each statement below as a factual comparison between this ",
      unit, " and the full sample."
    ),
    paste0(
      "MORE FREQUENT and LESS FREQUENT describe relative modality prevalence in this ",
      unit, "."
    ),
    paste0(
      "HIGHER and LOWER describe the ", unit,
      " mean relative to the full-sample mean for the same variable."
    ),
    paste0(
      "When percentages are shown, the ", unit,
      " percentage describes the modality within this ", unit,
      " and the full-sample percentage describes the same modality in the full sample; these are descriptive values, not p-values or measures of statistical strength."
    ),
    paste0(
      "When means are shown, compare the ", unit,
      " mean only with the full-sample mean for that same variable; do not compare mean values across variables as if they shared one scale."
    ),
    paste0(
      "An undisplayed modality or variable is not thereby absent, average, rejected, or unimportant."
    ),
    sep = "\n"
  )
}

.interpretation_nail_catdes <- function(interpretation_mode,
                                        target_label,
                                        joint = FALSE) {
  if (isTRUE(joint)) {
    if (identical(interpretation_mode, "standard")) {
      return(paste(
        paste0(
          "These are observed categories of '", target_label, "'."
        ),
        "Preserve their original names.",
        "Do not reinterpret them as latent profiles and do not rename them.",
        "Category names are contextual information, not statistical evidence.",
        "Do not invent empirical characteristics.",
        "Higher-level synthesis across displayed categories is allowed when traceable to the displayed evidence.",
        "Broader contextual hypotheses are allowed only when explicitly identified as hypotheses.",
        sep = "\n"
      ))
    }

    return(paste(
      "These are constructed profiles or latent classes whose meaning must be inferred from the results.",
      "Their current labels are identifiers, not interpretations.",
      "Their meanings may be inferred from the displayed evidence and concise meaningful names may be proposed.",
      "Do not invent unlisted statistical characteristics.",
      "Higher-level synthesis across displayed groups is allowed when traceable to the evidence.",
      "Broader contextual hypotheses must be identified as hypotheses.",
      sep = "\n"
    ))
  }

  if (identical(interpretation_mode, "standard")) {
    return(paste(
      paste0(
        "This is an observed category of '", target_label,
        "'. Preserve its original name."
      ),
      "Do not reinterpret this category as a latent profile and do not rename it.",
      "The category name is contextual information, not statistical evidence.",
      "Do not invent a new empirical characteristic or present a synthesis as if it were a direct statistical fact.",
      "A higher-level interpretation is encouraged when it reasonably synthesizes several displayed facts and remains traceable to them.",
      "A broader contextual hypothesis is allowed only when it is clearly identified as a hypothesis.",
      sep = "\n"
    ))
  }

  paste(
    "This is a constructed profile or latent class whose meaning must be inferred from the results.",
    "Its current label is an identifier, not an interpretation.",
    "Its meaning may be inferred from the displayed evidence and a concise meaningful name may be proposed.",
    "Do not invent an unlisted statistical characteristic or present a synthesis as if it were a direct statistical fact.",
    "A higher-level interpretation is allowed when it reasonably synthesizes several displayed facts and remains traceable to them.",
    "A broader contextual hypothesis is allowed only when it is clearly identified as a hypothesis.",
    sep = "\n"
  )
}

.local_task_nail_catdes <- function(interpretation_mode,
                                    joint = FALSE) {
  if (isTRUE(joint)) {
    if (identical(interpretation_mode, "standard")) {
      return(paste(
        "Interpret the complete set of observed categories shown below.",
        "For each category, identify its main coherent pattern.",
        "Then compare the supported profiles to identify the most important similarities and differences.",
        "Preserve all observed category names.",
        "Do not claim pairwise statistical significance that is not explicitly shown."
      ))
    }

    return(paste(
      "Interpret the complete set of constructed groups shown below.",
      "For each group, identify its main coherent pattern.",
      "Then compare the supported profiles to identify the main similarities, differences, and broader structure.",
      "A concise interpretive name may be proposed for each group.",
      "Do not claim pairwise statistical significance that is not explicitly shown."
    ))
  }

  if (identical(interpretation_mode, "standard")) {
    return(paste(
      "Interpret ONLY the observed category shown below.",
      "Combine its qualitative and quantitative facts to identify the strongest convergent semantic pattern.",
      "Explain what characterizes this category without renaming it.",
      "Do not compare it with unseen categories."
    ))
  }

  paste(
    "Interpret ONLY the constructed group shown below.",
    "Combine its facts to identify the strongest convergent semantic pattern.",
    "Explain what this group seems to represent and propose one concise interpretive name.",
    "Do not infer characteristics that are not listed below and do not compare it with unseen groups."
  )
}

.build_catdes_prompt_blocks_nail_catdes <- function(semantic_facing_evidence,
                                                    introduction,
                                                    request,
                                                    interpretation_mode,
                                                    target_label,
                                                    isolate_groups = TRUE) {
  group_names <- names(semantic_facing_evidence$groups)

  if (!isTRUE(isolate_groups)) {
    group_label <- .unit_label(interpretation_mode)
    evidence <- vapply(group_names, function(group_name) {
      paste0(
        "## ", group_label, " \"", group_name, "\"\n\n",
        semantic_facing_evidence$groups[[group_name]]$text
      )
    }, character(1))

    return(list(
      portfolio = list(
        context = introduction,
        reading = .reading_nail_catdes(interpretation_mode, joint = TRUE),
        question = request,
        interpretation = .interpretation_nail_catdes(
          interpretation_mode,
          target_label,
          joint = TRUE
        ),
        local_task = .local_task_nail_catdes(
          interpretation_mode,
          joint = TRUE
        ),
        evidence = paste(evidence, collapse = "\n\n---\n\n"),
        output = NULL
      )
    ))
  }

  stats::setNames(lapply(group_names, function(group_name) {
    group <- semantic_facing_evidence$groups[[group_name]]
    list(
      context = introduction,
      reading = .reading_nail_catdes(interpretation_mode),
      question = request,
      interpretation = .interpretation_nail_catdes(
        interpretation_mode,
        target_label
      ),
      local_task = .local_task_nail_catdes(interpretation_mode),
      evidence = group$text,
      output = NULL
    )
  }), group_names)
}

.render_catdes_prompt_blocks_nail_catdes <- function(blocks,
                                                     group_label = NULL,
                                                     group_name = NULL) {
  data_block <- if (is.null(group_name)) {
    blocks$evidence
  } else {
    paste0(
      "## ", group_label, " \"", group_name, "\"\n\n",
      blocks$evidence
    )
  }

  parts <- c(
    "# Introduction",
    blocks$context,
    "---",
    "## How to Read the Statistical Evidence",
    blocks$reading,
    "# Overall Analytical Request",
    blocks$question,
    "## Interpretation Rules",
    blocks$interpretation,
    "# Local Task",
    blocks$local_task,
    "# Data",
    data_block
  )

  if (!is.null(blocks$output) && nzchar(trimws(blocks$output))) {
    parts <- c(
      parts,
      "# Output",
      blocks$output
    )
  }

  normalize_blank_lines(paste(parts, collapse = "\n\n"))
}

.build_local_semantic_prompts_nail_catdes <- function(semantic_facing_evidence,
                                                       introduction,
                                                       request,
                                                       interpretation_mode,
                                                       target_label) {
  prompt_blocks <- .build_catdes_prompt_blocks_nail_catdes(
    semantic_facing_evidence = semantic_facing_evidence,
    introduction = introduction,
    request = request,
    interpretation_mode = interpretation_mode,
    target_label = target_label,
    isolate_groups = TRUE
  )

  prompts <- lapply(
    names(prompt_blocks),
    function(group_name) {
      .render_catdes_prompt_blocks_nail_catdes(
        blocks = prompt_blocks[[group_name]],
        group_label = .unit_label(interpretation_mode),
        group_name = group_name
      )
    }
  )
  names(prompts) <- names(prompt_blocks)
  attr(prompts, "catdes_prompt_blocks") <- prompt_blocks

  prompts
}

.build_semantic_profiles_nail_catdes <- function(local_results,
                                                  local_prompts,
                                                  semantic_facing_evidence,
                                                  interpretation_mode,
                                                  target_label,
                                                  generated,
                                                  architecture = "local") {
  group_names <- names(semantic_facing_evidence$groups)
  groups <- stats::setNames(vector("list", length(group_names)), group_names)

  for (group_name in group_names) {
    evidence_group <- semantic_facing_evidence$groups[[group_name]]
    result_group <- if (!is.null(local_results)) local_results[[group_name]] else NULL

    response <- NULL
    if (is.data.frame(result_group) && "response" %in% names(result_group) && nrow(result_group) > 0L) {
      response <- as.character(result_group$response[[1L]])
    }

    groups[[group_name]] <- list(
      group = group_name,
      status = if (!identical(evidence_group$status, "ready")) {
        evidence_group$status
      } else if (identical(architecture, "joint") && isTRUE(generated)) {
        "joint_response_not_stored"
      } else if (isTRUE(generated) && is.null(response)) {
        "generation_missing"
      } else if (isTRUE(generated)) {
        "generated"
      } else {
        "prompt_ready"
      },
      prompt = local_prompts[[group_name]],
      response = response,
      backend_result = result_group,
      prompt_role = if (identical(architecture, "joint")) {
        "local_audit_only"
      } else {
        "generation_prompt"
      },
      selected_evidence_ids = evidence_group$selected_evidence_ids,
      n_selected_evidence = evidence_group$metrics$n_selected,
      n_displayed_evidence = evidence_group$metrics$n_displayed
    )
  }

  out <- list(
    groups = groups,
    settings = list(
      interpretation_mode = interpretation_mode,
      target_label = target_label,
      architecture = architecture,
      global_synthesis_performed = FALSE,
      local_responses_generated = identical(architecture, "local") &&
        isTRUE(generated)
    ),
    metadata = list(
      schema = "NaileR::catdes_semantic_profiles",
      schema_version = "0.1.0",
      n_groups = as.integer(length(groups)),
      n_generated = as.integer(sum(vapply(
        groups,
        function(group) identical(group$status, "generated"),
        logical(1)
      )))
    )
  )
  class(out) <- c("nail_catdes_semantic_profiles", "list")
  out
}

# ---------------------------------------------------------------------------
# Validation and compatibility artifacts
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

.catdes_backend_response_text <- function(x) {
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

  NULL
}

.catdes_llm_responses <- function(local_results,
                                  interpretation_evidence) {
  if (is.null(local_results) ||
      length(local_results) == 0L) {
    return(NULL)
  }

  ready_names <- names(interpretation_evidence$groups)[
    vapply(
      interpretation_evidence$groups,
      function(group) identical(group$status, "ready"),
      logical(1)
    )
  ]

  if (length(ready_names) == 0L) {
    return(NULL)
  }

  out <- lapply(
    local_results[ready_names],
    .catdes_backend_response_text
  )
  keep <- !vapply(out, is.null, logical(1))
  out <- out[keep]

  if (length(out) == 0L) {
    return(NULL)
  }

  out
}

.attach_nail_catdes_artifacts <- function(result,
                                          normalized,
                                          interpretation_evidence,
                                          semantic_facing_evidence,
                                          local_prompts,
                                          prompt_blocks,
                                          semantic_profiles,
                                          catdes_settings,
                                          llm_io) {
  attr(result, "statistical_profiles") <- normalized$statistical_profiles
  attr(result, "interpretation_evidence") <- interpretation_evidence
  attr(result, "semantic_facing_evidence") <- semantic_facing_evidence
  attr(result, "local_prompts") <- local_prompts
  attr(result, "catdes_prompt_blocks") <- prompt_blocks
  attr(result, "semantic_profiles") <- semantic_profiles
  if (!is.null(normalized$catdes_result)) {
    attr(result, "catdes_result") <- normalized$catdes_result
  }
  attr(result, "catdes_settings") <- catdes_settings
  attr(result, "llm_io") <- llm_io
  result
}


#' Interpret a categorical variable
#'
#' Compute and interpret the statistical characteristics of an observed
#' categorical variable or of statistically constructed groups. CATDES
#' markers are computed or reused in R, selected mechanically, and translated
#' into plain-language factual statements before the LLM is called. The LLM
#' supplies the substantive interpretation; it does not recompute CATDES.
#' The interpretation scope is controlled by `isolate.groups`: one joint
#' comparative prompt by default, or one local prompt per group when isolation
#' is requested.
#'
#' @param dataset Historical raw-data input. A data frame containing the
#'   grouping variable and at least one descriptor. Positional calls such as
#'   `nail_catdes(dataset, num.var)` remain supported.
#' @param num.var Column index of the grouping variable when `dataset` is used.
#' @param x Advanced input. A direct `statistical_profiles` object, an object
#'   carrying a `statistical_profiles` attribute, a raw [FactoMineR::catdes()]
#'   result, or a historical `nail_catdes()` result carrying a `catdes_result`
#'   attribute. Do not supply `x` together with `dataset`.
#' @param introduction Study context included in the LLM prompt. A default is
#'   generated when `NULL`.
#' @param request Interpretation request. A default is generated from
#'   `interpretation_mode`, `prompt_style`, and `isolate.groups` when `NULL`.
#' @param model Model name used by the selected provider. The default is
#'   `"llama3"`.
#' @param provider LLM backend, either `"ollama"` or `"gemini"`; the default
#'   selected by `match.arg()` is `"ollama"`.
#' @param isolate.groups Logical. If `FALSE`, all categories/groups and their
#'   selected semantic-facing evidence are presented jointly in one prompt and
#'   one LLM call is made when `generate = TRUE`. If `TRUE`, each
#'   category/group is presented independently in its own prompt and
#'   interpreted separately. Isolation can be useful for long CATDES results
#'   or when an autonomous portrait of each group is desired.
#' @param quali.sample,quanti.sample Numbers in `[0, 1]` controlling the
#'   deterministic proportion of ranked qualitative or quantitative markers
#'   shown to the LLM. Zero selects none; one selects every eligible marker;
#'   intermediate values retain `ceiling(n * proportion)` top-ranked markers.
#' @param drop.negative Logical. If `TRUE`, underrepresented qualitative
#'   markers and lower quantitative markers are excluded only from the prompt
#'   selection. They remain unchanged in `statistical_profiles`.
#' @param proba Significance threshold used only when raw data or a raw
#'   `catdes()` result must be prepared. A precomputed `statistical_profiles`
#'   object is not re-filtered.
#' @param row.w Optional row weights used only with the raw `dataset` path.
#' @param interpretation_mode Either `"standard"` (default) for explicit observed
#'   categories whose names and meanings must be respected, or `"latent"` for
#'   constructed groups whose common meaning may be inferred and named.
#' @param prompt_style Either `"detailed"` (default) or `"compact"`; this
#'   changes the amount of reading and interpretation guidance, not the CATDES
#'   evidence.
#' @param generate Logical. If `FALSE`, return the prompt(s) without contacting
#'   a backend. If `TRUE`, generate the historical backend return form.
#' @param ... Provider-specific generation arguments passed to the selected
#'   backend.
#'
#' @details
#' With raw data, [nail_catdes_prep()] performs the only `catdes()` computation
#' and produces the canonical `statistical_profiles` object. With a prepared
#' object, the statistical preparation is reused directly.
#'
#' `quali.sample`, `quanti.sample`, and `drop.negative` affect only the
#' deterministic subset shown to the LLM. They do not modify the complete
#' `statistical_profiles` artifact.
#'
#' Before generation, selected markers are projected into
#' `semantic_facing_evidence`: quantitative markers are stated as higher/lower
#' means, binary qualitative variables are shown as complete significant
#' contrasts when allowed by `drop.negative`, and multi-level qualitative
#' variables keep only the selected modalities. `p.value`, `v.test`, and stable
#' evidence identifiers remain available for audit but are not exposed to the
#' semantic prompt.
#'
#' `isolate.groups` controls the LLM interpretation scope, not the statistical
#' analysis. With `FALSE`, the model receives one joint prompt containing all
#' category/group evidence and can compare the displayed profiles. With
#' `TRUE`, each model call receives only one category/group and produces an
#' autonomous portrait. In both cases, the statistical and semantic-facing
#' evidence are constructed once before prompt projection.
#'
#' Every successful return carries `statistical_profiles`,
#' `interpretation_evidence`, `semantic_facing_evidence`, `local_prompts`,
#' `semantic_profiles`, `catdes_result` when available, and `catdes_settings` as
#' attributes.
#'
#' @return When `generate = FALSE`, the actual joint prompt when
#'   `isolate.groups = FALSE`, or the exact named local prompts when
#'   `isolate.groups = TRUE`. When `generate = TRUE`, a single backend data
#'   frame when `isolate.groups = FALSE`, or the named local backend results
#'   when `isolate.groups = TRUE`. A joint result may also retain local prompts
#'   for audit; those prompts are not additional LLM interactions. Mechanical
#'   and semantic-stage artifacts are attached as attributes, not as `$` fields:
#'
#'   * `statistical_profiles`: complete canonical CATDES evidence;
#'   * `interpretation_evidence`: selected evidence with stable identifiers;
#'   * `semantic_facing_evidence`: factual statements shown to the LLM;
#'   * `local_prompts` and `catdes_prompt_blocks`: local prompt audit objects;
#'   * `semantic_profiles`: parsed or status-bearing interpretation profiles;
#'   * `catdes_result`: the original FactoMineR result, when available;
#'   * `catdes_settings`: execution and interpretation settings;
#'   * `llm_io`: the exact active prompt(s) and raw response(s).
#'
#'   A preview has prompts but no responses. Use [nail_evidence()] for evidence,
#'   [nail_prompt()] for the active prompt(s), and [nail_response()] after
#'   generation.
#'
#' @seealso [nail_catdes_prep()], [nail_catdes_ground()],
#'   [nail_catdes_textual()], [nail_evidence()], [nail_prompt()],
#'   [nail_response()]
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
#' # Observed categorical variable: keep and interpret the species names.
#' prompt <- nail_catdes(
#'   iris,
#'   num.var = 5,
#'   interpretation_mode = "standard",
#'   generate = FALSE
#' )
#' cat(substr(prompt, 1, 700))
#'
#' # Reuse the canonical profile attached to the preview without recomputing catdes().
#' profiles <- nail_catdes_prep(
#'   x = attr(prompt, "statistical_profiles", exact = TRUE)
#' )
#' prompt_from_profiles <- nail_catdes(
#'   x = profiles,
#'   interpretation_mode = "standard",
#'   generate = FALSE
#' )
#'
#' \dontrun{
#' generated <- nail_catdes(
#'   iris,
#'   num.var = 5,
#'   provider = "ollama",
#'   model = "llama3",
#'   generate = TRUE
#' )
#' cat(generated$response)
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

  semantic_facing_evidence <- .build_semantic_facing_evidence_nail_catdes(
    statistical_profiles = profiles,
    interpretation_evidence = interpretation_evidence
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

  local_prompts <- .build_local_semantic_prompts_nail_catdes(
    semantic_facing_evidence = semantic_facing_evidence,
    introduction = introduction,
    request = request,
    interpretation_mode = interpretation_mode,
    target_label = normalized$target_label
  )
  local_prompt_blocks <- attr(local_prompts, "catdes_prompt_blocks", exact = TRUE)

  if (isTRUE(isolate.groups)) {
    prompt_blocks <- local_prompt_blocks
    actual_prompt <- NULL
  } else {
    prompt_blocks <- .build_catdes_prompt_blocks_nail_catdes(
      semantic_facing_evidence = semantic_facing_evidence,
      introduction = introduction,
      request = request,
      interpretation_mode = interpretation_mode,
      target_label = normalized$target_label,
      isolate_groups = FALSE
    )
    actual_prompt <- .render_catdes_prompt_blocks_nail_catdes(
      blocks = prompt_blocks$portfolio
    )
  }

  n_ready_groups <- interpretation_evidence$metadata$n_ready_groups
  n_selected <- interpretation_evidence$metadata$n_selected_evidence
  generation_architecture <- if (isTRUE(isolate.groups)) "local" else "joint"
  llm_calls <- if (!isTRUE(generate)) {
    0L
  } else if (isTRUE(isolate.groups)) {
    as.integer(n_ready_groups)
  } else if (n_selected > 0L) {
    1L
  } else {
    0L
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
    ),
    semantic_representation = "hybrid_plain",
    generation_architecture = generation_architecture,
    prompt_scope = generation_architecture,
    local_prompts_for_audit_only = !isTRUE(isolate.groups),
    global_synthesis_performed = FALSE,
    n_selected_evidence = as.integer(n_selected),
    n_displayed_evidence = as.integer(
      semantic_facing_evidence$metadata$n_displayed_evidence
    ),
    n_added_binary_contrast = as.integer(
      semantic_facing_evidence$metadata$n_added_binary_contrast
    )
  )

  semantic_profiles <- .build_semantic_profiles_nail_catdes(
    local_results = NULL,
    local_prompts = local_prompts,
    semantic_facing_evidence = semantic_facing_evidence,
    interpretation_mode = interpretation_mode,
    target_label = normalized$target_label,
    generated = FALSE,
    architecture = generation_architecture
  )

  active_prompts <- if (isTRUE(isolate.groups)) {
    local_prompts
  } else {
    stats::setNames(list(actual_prompt), "portfolio")
  }

  llm_io <- .new_nail_llm_io(
    stage = "interpretation",
    prompts = active_prompts,
    responses = NULL,
    metadata = list(
      analysis = "nail_catdes",
      scope = generation_architecture,
      architecture = generation_architecture,
      provider = provider,
      model = model,
      interpretation_mode = interpretation_mode,
      local_prompts_for_audit_only = !isTRUE(isolate.groups)
    )
  )

  if (!isTRUE(generate)) {
    result <- if (isTRUE(isolate.groups)) {
      local_prompts
    } else {
      actual_prompt
    }

    return(.attach_nail_catdes_artifacts(
      result,
      normalized,
      interpretation_evidence,
      semantic_facing_evidence,
      local_prompts,
      prompt_blocks,
      semantic_profiles,
      catdes_settings,
      llm_io
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

  if (isTRUE(isolate.groups)) {
    local_results <- stats::setNames(
      vector("list", length(local_prompts)),
      names(local_prompts)
    )

    for (group_name in names(local_prompts)) {
      group_evidence <- interpretation_evidence$groups[[group_name]]
      local_results[[group_name]] <- if (identical(group_evidence$status, "ready")) {
        call_llm(local_prompts[[group_name]])
      } else {
        .catdes_no_results_data_frame(
          model = model,
          prompt = local_prompts[[group_name]],
          response = paste0(
            "No selected statistical evidence found for group '",
            group_name,
            "'."
          )
        )
      }
    }

    semantic_profiles <- .build_semantic_profiles_nail_catdes(
      local_results = local_results,
      local_prompts = local_prompts,
      semantic_facing_evidence = semantic_facing_evidence,
      interpretation_mode = interpretation_mode,
      target_label = normalized$target_label,
      generated = TRUE,
      architecture = "local"
    )
    llm_io <- .new_nail_llm_io(
      stage = "interpretation",
      prompts = local_prompts,
      responses = .catdes_llm_responses(
        local_results,
        interpretation_evidence
      ),
      metadata = list(
        analysis = "nail_catdes",
        scope = "local",
        architecture = "local",
        provider = provider,
        model = model,
        interpretation_mode = interpretation_mode,
        local_prompts_for_audit_only = FALSE
      )
    )
    result <- local_results
  } else {
    result <- if (n_selected == 0L) {
      message("Execution halted: No selected statistical evidence. Nothing to generate.")
      .catdes_no_results_data_frame(
        model = model,
        prompt = actual_prompt,
        response = "No selected statistical evidence found."
      )
    } else {
      call_llm(actual_prompt)
    }

    semantic_profiles <- .build_semantic_profiles_nail_catdes(
      local_results = NULL,
      local_prompts = local_prompts,
      semantic_facing_evidence = semantic_facing_evidence,
      interpretation_mode = interpretation_mode,
      target_label = normalized$target_label,
      generated = TRUE,
      architecture = "joint"
    )
    joint_response <- if (n_selected > 0L) {
      .catdes_backend_response_text(result)
    } else {
      NULL
    }
    llm_io <- .new_nail_llm_io(
      stage = "interpretation",
      prompts = stats::setNames(list(actual_prompt), "portfolio"),
      responses = if (is.null(joint_response)) {
        NULL
      } else {
        stats::setNames(list(joint_response), "portfolio")
      },
      metadata = list(
        analysis = "nail_catdes",
        scope = "joint",
        architecture = "joint",
        provider = provider,
        model = model,
        interpretation_mode = interpretation_mode,
        local_prompts_for_audit_only = TRUE
      )
    )
  }

  .attach_nail_catdes_artifacts(
    result,
    normalized,
    interpretation_evidence,
    semantic_facing_evidence,
    local_prompts,
    prompt_blocks,
    semantic_profiles,
    catdes_settings,
    llm_io
  )
}
