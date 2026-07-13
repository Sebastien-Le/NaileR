

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

validate_catdes_inputs <- function(dataset,
                                   num.var,
                                   isolate.groups = FALSE,
                                   quali.sample = 1,
                                   quanti.sample = 1,
                                   drop.negative = FALSE,
                                   proba = 0.05,
                                   generate = FALSE,
                                   interpretation_mode = c("standard", "latent"),
                                   prompt_style = c("detailed", "compact")) {
  interpretation_mode <- match.arg(interpretation_mode)
  prompt_style <- match.arg(prompt_style)

  assert_data_frame(dataset, "dataset")
  if (ncol(dataset) < 2) {
    stop("`dataset` must contain at least two columns.", call. = FALSE)
  }
  assert_column_index(num.var, ncol(dataset), "num.var")
  assert_single_logical(isolate.groups, "isolate.groups")
  assert_single_logical(drop.negative, "drop.negative")
  assert_single_logical(generate, "generate")
  assert_proportion(quali.sample, "quali.sample")
  assert_proportion(quanti.sample, "quanti.sample")
  assert_proportion(proba, "proba")

  invisible(TRUE)
}

# ---------------------------------------------------------------------------
# nail_catdes (Main Function)
# ---------------------------------------------------------------------------

#' Interpret a categorical variable
#'
#' Generate an LLM response to analyze a categorical variable.
#'
#' @param dataset a data frame made up of at least one categorical variable and a set of quantitative variables and/or categorical variables.
#' @param num.var the index of the variable to be characterized.
#' @param introduction the introduction for the LLM prompt.
#' @param request the request made to the LLM.
#' @param model the model name for the selected provider (e.g., 'llama3' for Ollama or 'gemini-2.5-flash' for Gemini).
#' @param provider LLM backend to use for generation. Use `"ollama"` for a local Ollama model or `"gemini"` for Google Gemini via `GEMINI_API_KEY`.
#' @param isolate.groups a boolean that indicates whether to give the LLM a single prompt, or one prompt per category. Recommended with long catdes results.
#' @param quali.sample from 0 to 1, the proportion of qualitative features that are randomly kept.
#' @param quanti.sample from 0 to 1, the proportion of quantitative features that are randomly kept.
#' @param drop.negative a boolean that indicates whether to drop negative v.test values for interpretation (keeping only positive v.tests).
#' @param proba the significance threshold considered to characterize the categories (by default 0.05).
#' @param row.w a vector of integers corresponding to an optional row weights (by default, a vector of 1 for uniform row weights)
#' @param interpretation_mode either "standard" or "latent".
#' @param prompt_style either "detailed" or "compact".
#' @param generate a boolean that indicates whether to generate the LLM response. If FALSE, the function only returns the prompt.
#' @param ... Additional provider-specific generation arguments passed to the selected LLM backend
#' (e.g., `temperature`, `seed`).
#'
#' @return If `generate = FALSE`, a character prompt or a named list of prompts. If `generate = TRUE`, an object containing the generated interpretation and the underlying analytical result.
#'
#' @details This function (when generate=TRUE) sends a prompt to the selected LLM backend.
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
#' \dontrun{
#' # Processing time is often longer than ten seconds
#' # because the function uses a large language model.
#'
#' ### Example 1: Fisher's iris ###
#' library(NaileR)
#' data(iris)
#'
#' intro_iris <- "A study measured various parts of iris flowers
#' from 3 different species: setosa, versicolor and virginica.
#' I will give you the results from this study.
#' You will have to identify what sets these flowers apart."
#' intro_iris <- gsub('\n', ' ', intro_iris) |>
#' stringr::str_squish()
#'
#' req_iris <- "Please explain what makes each species distinct.
#' Also, tell me which species has the biggest flowers,
#' and which species has the smallest."
#' req_iris <- gsub('\n', ' ', req_iris) |>
#' stringr::str_squish()
#'
#' res_iris <- nail_catdes(iris,
#'                         num.var = 5,
#'                         introduction = intro_iris,
#'                         request = req_iris,
#'                         generate = TRUE)
#'
#' cat(res_iris$response)
#'
#' ### Example 2: food waste dataset ###
#'
#' library(FactoMineR)
#'
#' data(waste)
#' waste <- waste[-14]    # no variability on this question
#'
#' set.seed(1)
#' res_mca_waste <- MCA(waste, quali.sup = c(1,2,50:76),
#' ncp = 35, level.ventil = 0.05, graph = FALSE)
#' plot.MCA(res_mca_waste, choix = "ind",
#' invisible = c("var", "quali.sup"), label = "none")
#' res_hcpc_waste <- HCPC(res_mca_waste, nb.clust = 3, graph = FALSE)
#' plot.HCPC(res_hcpc_waste, choice = "map", draw.tree = FALSE,
#' ind.names = FALSE)
#' don_clust_waste <- res_hcpc_waste$data.clust
#'
#' intro_waste <- 'These data were collected
#' after a survey on food waste,
#' with participants describing their habits.'
#' intro_waste <- gsub('\n', ' ', intro_waste) |>
#' stringr::str_squish()
#'
#' req_waste <- 'Please summarize the characteristics of each group.
#' Then, give each group a new name, based on your conclusions.
#' Finally, give each group a grade between 0 and 10,
#' based on how wasteful they are with food:
#' 0 being "not at all", 10 being "absolutely".'
#' req_waste <- gsub('\n', ' ', req_waste) |>
#' stringr::str_squish()
#'
#' res_waste <- nail_catdes(don_clust_waste,
#'                          num.var = ncol(don_clust_waste),
#'                          introduction = intro_waste,
#'                          request = req_waste,
#'                          drop.negative = TRUE,
#'                          generate = TRUE)
#'
#' cat(res_waste$response)
#'
#'
#' ### Example 3: local_food dataset ###
#'
#' data(local_food)
#'
#' set.seed(1)
#' res_mca_food <- MCA(local_food, quali.sup = 46:63,
#' ncp = 100, level.ventil = 0.05, graph = FALSE)
#' plot.MCA(res_mca_food, choix = "ind",
#' invisible = c("var", "quali.sup"), label = "none")
#' res_hcpc_food <- HCPC(res_mca_food, nb.clust = 3, graph = FALSE)
#' plot.HCPC(res_hcpc_food, choice = "map", draw.tree = FALSE,
#' ind.names = FALSE)
#' don_clust_food <- res_hcpc_food$data.clust
#'
#' intro_food <- 'A study on sustainable food systems
#' was led on several French participants.
#' This study had 2 parts. In the first part,
#' participants had to rate how acceptable
#' "a food system that..." (e.g, "a food system that
#' only uses renewable energy") was to them.
#' In the second part, they had to say
#' if they agreed or disagreed with some statements.'
#' intro_food <- gsub('\n', ' ', intro_food) |>
#' stringr::str_squish()
#'
#' req_food <- 'I will give you the answers from one group.
#' Please explain who the individuals of this group are,
#' what their beliefs are.
#' Then, give this group a new name,
#' and explain why you chose this name.
#' Do not use 1st person ("I", "my"...) in your answer.'
#' req_food <- gsub('\n', ' ', req_food) |>
#' stringr::str_squish()
#'
#' res_food <- nail_catdes(don_clust_food,
#'                         num.var = 64,
#'                         introduction = intro_food,
#'                         request = req_food,
#'                         isolate.groups = TRUE,
#'                         drop.negative = TRUE,
#'                         generate = TRUE)
#'
#' res_food[[1]]$response |> cat()
#' res_food[[2]]$response |> cat()
#' res_food[[3]]$response |> cat()
#' }
nail_catdes <- function(dataset, num.var,
                        introduction = NULL,
                        request      = NULL,
                        model        = "llama3",
                        provider     = c("ollama", "gemini"),
                        isolate.groups  = FALSE,
                        quali.sample    = 1,
                        quanti.sample   = 1,
                        drop.negative   = FALSE,
                        proba           = 0.05,
                        row.w           = NULL,
                        interpretation_mode = c("standard", "latent"),
                        prompt_style        = c("detailed", "compact"),
                        generate = FALSE,
                        ...) {

  interpretation_mode <- match.arg(interpretation_mode)
  prompt_style        <- match.arg(prompt_style)

  provider <- match.arg(provider)

  validate_catdes_inputs(
    dataset = dataset,
    num.var = num.var,
    isolate.groups = isolate.groups,
    quali.sample = quali.sample,
    quanti.sample = quanti.sample,
    drop.negative = drop.negative,
    proba = proba,
    generate = generate,
    interpretation_mode = interpretation_mode,
    prompt_style = prompt_style
  )

  if (is.null(introduction)) {
    introduction <- if (interpretation_mode == "standard")
      "For this study, observations were described according to an explicit categorical variable."
    else
      "For this study, observations were grouped according to their similarities."
  }

  if (is.null(request)) {
    request <- build_request_catdes(
      interpretation_mode = interpretation_mode,
      isolate_groups      = isolate.groups,
      prompt_style        = prompt_style
    )
  }

  target_label <- if (is.null(colnames(dataset)))
    "the target variable"
  else
    colnames(dataset)[num.var]

  GUIDE_CATDES <- build_guide_catdes(
    interpretation_mode = interpretation_mode,
    target_label        = target_label,
    prompt_style        = prompt_style,
    isolate_groups      = isolate.groups
  )

  introduction <- paste(introduction, GUIDE_CATDES, sep = "\n\n---\n\n")

  res_cd <- FactoMineR::catdes(
    dataset,
    num.var = num.var,
    proba = proba,
    row.w = row.w
  )

  ppt <- tryCatch(
    get_prompt_catdes(
      res_cd,
      introduction   = introduction,
      request        = request,
      isolate.groups = isolate.groups,
      quali.sample   = quali.sample,
      quanti.sample  = quanti.sample,
      drop.negative  = drop.negative,
      interpretation_mode = interpretation_mode,
      target_label        = target_label,
      prompt_style        = prompt_style
    ),
    error = function(e) {
      if (grepl("No significant differences", conditionMessage(e))) {
        "NAILER_NO_RESULTS_FOUND"
      } else {
        stop(e)
      }
    }
  )

  if (identical(ppt, "NAILER_NO_RESULTS_FOUND")) {
    no_results_message <- "*No significant differences were found between the groups at this probability threshold.*"

    if (generate) {
      message("Execution halted: No significant differences found. Nothing to generate.")

      if (isolate.groups) {
        out <- list()
        attr(out, "catdes_result") <- res_cd
        return(out)
      }

      out <- data.frame(
        model      = model,
        created_at = Sys.time(),
        response   = "No significant differences found.",
        done       = TRUE,
        prompt     = no_results_message,
        stringsAsFactors = FALSE
      )
      attr(out, "catdes_result") <- res_cd
      return(out)
    }

    header <- glue::glue(
      "# Introduction\n\n{introduction}\n\n",
      "# Task\n\n{request}\n\n",
      "# Data\n\n"
    )

    out <- paste0(header, no_results_message)
    attr(out, "catdes_result") <- res_cd
    return(out)
  }

  if (!generate) {
    attr(ppt, "catdes_result") <- res_cd
    return(ppt)
  }

  extra_args <- list(...)
  llm_api_options <- extra_args

  .call_llm <- function(prompt) {
    res <- .call_llm_base(
      provider = provider,
      model = model,
      prompt = prompt,
      output = "df",
      llm_api_options = llm_api_options
    )
    res$prompt <- prompt
    res
  }

  if (!isolate.groups) {
    out <- .call_llm(ppt)
    attr(out, "catdes_result") <- res_cd
    return(out)
  }

  res_list <- lapply(ppt, .call_llm)

  if (!is.null(names(ppt))) {
    names(res_list) <- names(ppt)
  }

  attr(res_list, "catdes_result") <- res_cd
  res_list
}
