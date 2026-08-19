

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
# Prompt projection from selected statistical evidence
# ---------------------------------------------------------------------------
# The statistical_profiles/evidence registry remains available for audit, but
# stable evidence identifiers are deliberately not shown to the LLM here.
# This keeps the historical NaileR semantic contract: the model interprets a
# coherent set of selected statistical characteristics rather than formatting
# a registry of claims.

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

.format_qualitative_prompt_nail_catdes <- function(markers,
                                                    interpretation_mode) {
  title <- .quali_title(interpretation_mode)
  if (!is.data.frame(markers) || nrow(markers) == 0L) {
    return(paste0("### ", title, "\n\n*No significant data to display.*\n"))
  }

  table <- data.frame(
    Variable = markers$variable,
    Modalite = markers$modality,
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

.format_quantitative_prompt_nail_catdes <- function(markers,
                                                     interpretation_mode) {
  title <- .quanti_title(interpretation_mode)
  if (!is.data.frame(markers) || nrow(markers) == 0L) {
    return(paste0("### ", title, "\n\n*No significant data to display.*\n"))
  }

  table <- data.frame(
    Variable = markers$variable,
    `Mean in category` = .format_catdes_prompt_number(markers$group_mean),
    `Overall mean` = .format_catdes_prompt_number(markers$overall_mean),
    `sd in category` = .format_catdes_prompt_number(markers$standard_deviation),
    `Overall sd` = .format_catdes_prompt_number(markers$overall_standard_deviation),
    `p.value` = .format_catdes_prompt_number(markers$p_value, p_value = TRUE),
    `v.test` = .format_catdes_prompt_number(markers$v_test),
    stringsAsFactors = FALSE,
    check.names = FALSE
  )

  paste0("### ", title, "\n\n", .markdown_table_nail_catdes(table), "\n")
}

.build_group_block_from_evidence_nail_catdes <- function(group_evidence,
                                                          interpretation_mode) {
  if (!identical(group_evidence$status, "ready")) {
    return("*No significant statistical characteristics were selected for this group.*")
  }

  paste(
    .format_qualitative_prompt_nail_catdes(
      group_evidence$qualitative_markers,
      interpretation_mode
    ),
    .format_quantitative_prompt_nail_catdes(
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
      block <- .build_group_block_from_evidence_nail_catdes(
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
    block <- .build_group_block_from_evidence_nail_catdes(
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


#' Interpret a categorical variable
#'
#' Interpret the statistical characteristics of an observed categorical
#' variable or of statistically constructed groups. The semantic contract is
#' the historical NaileR one: statistical results are selected mechanically,
#' then presented together so that the LLM can synthesize their convergent
#' meaning in the study context.
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
#' @param model Model name used by the selected provider.
#' @param provider LLM backend, either `"ollama"` or `"gemini"`.
#' @param isolate.groups Logical. If `FALSE`, build one joint prompt. If
#'   `TRUE`, build one prompt per category/group.
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
#' @param interpretation_mode Either `"standard"` for explicit observed
#'   categories whose names and meanings must be respected, or `"latent"` for
#'   constructed groups whose common meaning may be inferred and named.
#' @param prompt_style Either `"detailed"` or `"compact"`.
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
#' Stable evidence identifiers remain available in the attached mechanical
#' artifacts for audit, but they are deliberately not included in the prompt at
#' this stage. The LLM is asked to interpret the selected statistical pattern
#' rather than to produce an evidence registry.
#'
#' Every successful return carries `statistical_profiles`,
#' `interpretation_evidence`, `catdes_result` when available, and
#' `catdes_settings` as attributes.
#'
#' @return When `generate = FALSE`, a character prompt or named list of prompts.
#'   When `generate = TRUE`, a backend data frame or named list of backend data
#'   frames. Mechanical artifacts are attached as attributes in both cases.
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
#' # Reuse the mechanical preparation without recomputing catdes().
#' profiles <- nail_catdes_prep(dataset = iris, num.var = 5)
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

  if (!isTRUE(generate)) {
    if (n_selected == 0L && !isTRUE(isolate.groups)) {
      no_results_message <- paste0(
        "# Introduction\n\n", introduction_with_guide,
        "\n\n# Task\n\n", request,
        "\n\n# Data\n\n*No selected statistical evidence was found at this probability threshold.*"
      )
      prompts <- normalize_blank_lines(no_results_message)
    }

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

  if (!isTRUE(isolate.groups)) {
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
