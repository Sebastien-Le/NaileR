#' @importFrom dplyr filter arrange select mutate desc
#' @importFrom glue glue
#' @importFrom knitr kable
#' @importFrom tibble rownames_to_column
#' @importFrom utils globalVariables
#' @importFrom stats as.formula terms median
#' @importFrom SensoMineR decat

utils::globalVariables(c(".data", "p.value", "v.test"))

# ---------------------------------------------------------------------------
# Validation
# ---------------------------------------------------------------------------

validate_qda_inputs <- function(dataset, formul, firstvar, lastvar,
                                isolate.groups, drop.negative,
                                proba, generate, sample.pct,
                                prompt_style, product_knowledge) {
  if (!is.data.frame(dataset)) {
    stop("`dataset` must be a data frame.", call. = FALSE)
  }

  if (ncol(dataset) < 2) {
    stop("`dataset` must contain at least two columns.", call. = FALSE)
  }

  assert_index_range(firstvar, lastvar, ncol(dataset))
  assert_proportion(proba, "proba")
  assert_proportion(sample.pct, "sample.pct")
  assert_single_logical(isolate.groups, "isolate.groups")
  assert_single_logical(drop.negative, "drop.negative")
  assert_single_logical(generate, "generate")

  if (!prompt_style %in% c("detailed", "compact")) {
    stop("`prompt_style` must be one of: 'detailed', 'compact'.", call. = FALSE)
  }

  if (!product_knowledge %in% c("known", "unknown")) {
    stop("`product_knowledge` must be one of: 'known', 'unknown'.", call. = FALSE)
  }

  if (missing(formul) || is.null(formul) || !nzchar(trimws(paste(formul, collapse = " ")))) {
    stop("`formul` must be provided and non-empty.", call. = FALSE)
  }

  formula_obj <- tryCatch(
    stats::as.formula(paste(formul, collapse = " ")),
    error = function(e) {
      stop("`formul` could not be parsed as a valid formula.", call. = FALSE)
    }
  )

  rhs_terms <- attr(stats::terms(formula_obj), "term.labels")

  if (length(rhs_terms) < 1) {
    stop("`formul` must contain at least one right-hand-side term.", call. = FALSE)
  }

  product_var <- trimws(rhs_terms[1])

  if (!product_var %in% colnames(dataset)) {
    stop(sprintf(
      "The first right-hand-side term in `formul` ('%s') was not found in `dataset`.",
      product_var
    ), call. = FALSE)
  }

  product_col <- dataset[[product_var]]
  if (!is.factor(product_col)) {
    product_col <- as.factor(product_col)
  }

  if (nlevels(product_col) < 2) {
    stop(sprintf(
      "The product factor '%s' must have at least 2 levels.",
      product_var
    ), call. = FALSE)
  }

  invisible(TRUE)
}

# ---------------------------------------------------------------------------
# Helpers
# ---------------------------------------------------------------------------


.attribute_title <- function(direction = c("higher", "lower"),
                             prompt_style = c("detailed", "compact")) {
  direction <- match.arg(direction)
  prompt_style <- match.arg(prompt_style)

  if (prompt_style == "compact") {
    if (direction == "higher") "Higher than average profile" else "Lower than average profile"
  } else {
    if (direction == "higher") {
      "Higher than Average Profile (Most Significant First)"
    } else {
      "Lower than Average Profile (Most Significant First)"
    }
  }
}

.format_qda_table <- function(df) {
  knitr::kable(
    df,
    digits = 2,
    format = "pipe",
    align = c("l", rep("r", ncol(df) - 1))
  )
}

.prepare_qda_df <- function(res_df, sample.pct = 1) {
  if (is.null(res_df) || nrow(as.data.frame(res_df)) == 0) {
    return(NULL)
  }

  res_work <- as.data.frame(res_df) |>
    tibble::rownames_to_column(var = "Variable") |>
    dplyr::select("Variable", "Coeff", "Adjust mean", "p.value", "v.test")

  if (sample.pct < 1) {
    res_work <- sample_numeric_distribution(
      res_work,
      num_var_index = which(colnames(res_work) == "v.test"),
      sample_pct = sample.pct,
      method = "stratified",
      bins = 5,
      return_matrix = FALSE
    )
  }

  res_work
}

.profile_strength_label <- function(vtests) {
  if (length(vtests) == 0) return("weak")
  med <- stats::median(abs(vtests), na.rm = TRUE)

  if (is.na(med)) return("weak")
  if (med >= 5) return("strong")
  if (med >= 3) return("moderate")
  "weak"
}

.standardize_qda_result_names <- function(df) {
  if (is.null(df) || ncol(df) == 0) {
    return(df)
  }

  nms <- colnames(df)

  # robust handling of R-sanitized names
  nms[nms %in% c("Adjust.mean", "Adjust mean")] <- "Adjust mean"
  nms[nms %in% c("P-value", "P.value", "p.value")] <- "p.value"
  nms[nms %in% c("Vtest", "v.test")] <- "v.test"

  colnames(df) <- nms
  df
}

# ---------------------------------------------------------------------------
# Structured profile summary
# ---------------------------------------------------------------------------

.summarize_qda_profiles <- function(res_cd,
                                    drop.negative = FALSE,
                                    top_n = 5) {
  if (!"quanti" %in% names(res_cd)) {
    return(list())
  }

  out <- list()

  for (grp_name in names(res_cd$quanti)) {
    res_df <- res_cd$quanti[[grp_name]]
    res_work <- .prepare_qda_df(res_df, sample.pct = 1)

    if (is.null(res_work) || nrow(res_work) == 0) {
      out[[grp_name]] <- list(
        above = character(0),
        below = character(0),
        n_sig = 0,
        profile_strength = "weak"
      )
      next
    }

    positive_df <- res_work |>
      dplyr::filter(.data$v.test > 0) |>
      dplyr::mutate(abs_vtest = abs(.data$v.test)) |>
      dplyr::arrange(dplyr::desc(.data$abs_vtest), .data$p.value)

    negative_df <- res_work |>
      dplyr::filter(.data$v.test < 0) |>
      dplyr::mutate(abs_vtest = abs(.data$v.test)) |>
      dplyr::arrange(dplyr::desc(.data$abs_vtest), .data$p.value)

    above <- utils::head(positive_df$Variable, top_n)
    below <- if (drop.negative) character(0) else utils::head(negative_df$Variable, top_n)

    out[[grp_name]] <- list(
      above = above,
      below = below,
      n_sig = nrow(res_work),
      profile_strength = .profile_strength_label(res_work$v.test)
    )
  }

  out
}

# ---------------------------------------------------------------------------
# Builders
# ---------------------------------------------------------------------------

build_guide_qda <- function(proba = 0.05,
                            prompt_style = c("detailed", "compact"),
                            product_knowledge = c("known", "unknown")) {
  prompt_style <- match.arg(prompt_style)
  product_knowledge <- match.arg(product_knowledge)
  unit_singular <- .unit_word_qda(product_knowledge, capital = FALSE, plural = FALSE)
  unit_plural <- .unit_word_qda(product_knowledge, capital = FALSE, plural = TRUE)

  if (prompt_style == "compact") {
    lines <- c(
      "## How to Read the Tables",
      paste0(
        "The tables below show which sensory attributes are higher or lower than the overall average profile for each ",
        unit_singular, "."
      ),
      paste0(
        "They report the results retained under the threshold chosen for this analysis ",
        "(here p <= ", proba, ")."
      ),
      "* **Adjust mean**: adjusted mean score for the item on the attribute.",
      "* **p.value**: smaller values indicate stronger evidence under the current analysis settings.",
      "* **v.test**: positive = higher than the average profile; negative = lower than the average profile.",
      "* Positive and negative signs indicate statistical direction only; they do not indicate liking, quality, desirability, or an unfavorable or favorable perception."
    )

    if (product_knowledge == "known") {
      lines <- c(lines, "Use the results to clarify the sensory profile of each product, not to rename it.")
    } else {
      lines <- c(lines, "Use the results to infer the relative profile of each stimulus; you may propose descriptive names if appropriate.")
    }

    return(paste(lines, collapse = "\n"))
  }

  lines <- c(
    "## How to Read the Tables",
    paste0(
      "The tables below describe which sensory attributes are associated with each ",
      unit_singular, " relative to the overall average profile across the set of ", unit_plural, "."
    ),
    paste0(
      "They report the results retained under the threshold chosen for this analysis ",
      "(here p <= ", proba, ")."
    ),
    "",
    "* **Variable**: sensory attribute.",
    "* **Coeff**: coefficient from the linear model; it indicates the direction of the effect.",
    "* **Adjust mean**: adjusted mean score for this item on the attribute.",
    "* **p.value**: smaller values indicate stronger evidence under the current analysis settings.",
    "* **v.test**: positive means higher than the average profile, negative means lower than the average profile; larger absolute values indicate a stronger deviation from the average profile.",
    "The directions above and below the average profile are descriptive sensory differences. They must not be interpreted as favorable or unfavorable evaluations.",
    "",
    paste0("Use the retained attributes to understand what characterizes each ", unit_singular, " relative to the others."),
    "Do not interpret the results as causal explanations."
  )

  if (product_knowledge == "known") {
    lines <- c(lines, "Treat the product labels as already meaningful. Do not rename the products.")
  } else {
    lines <- c(lines, "Treat the stimulus labels as identifiers only. You may infer descriptive names from the retained attributes.")
  }

  paste(lines, collapse = "\n")
}

build_request_qda <- function(isolate_groups = FALSE,
                              prompt_style = c("detailed", "compact"),
                              product_knowledge = c("known", "unknown")) {
  prompt_style <- match.arg(prompt_style)
  product_knowledge <- match.arg(product_knowledge)

  if (!isolate_groups) {
    if (prompt_style == "compact") {
      if (product_knowledge == "known") {
        return(paste(
          "Using only the results below, describe what characterizes each product and what distinguishes it from the others.",
          "Do not rename the products.",
          sep = "\n"
        ))
      } else {
        return(paste(
          "Using only the results below, describe what characterizes each stimulus and what distinguishes it from the others.",
          "You may propose a short descriptive name for each stimulus if the evidence is clear enough.",
          sep = "\n"
        ))
      }
    }

    if (product_knowledge == "known") {
      return(paste(
        "Using only the results below, describe what characterizes each product and what distinguishes it from the others.",
        "For each product, identify the strongest sensory attributes that are above and below the average profile.",
        "Then summarize the main contrasts across all products.",
        "Do not rename the products.",
        sep = "\n"
      ))
    }

    return(paste(
      "Using only the results below, describe what characterizes each stimulus and what distinguishes it from the others.",
      "For each stimulus, identify the strongest sensory attributes that are above and below the average profile.",
      "Then summarize the main contrasts across all stimuli.",
      "If the profile is sufficiently clear, you may propose a short descriptive name for each stimulus.",
      sep = "\n"
    ))
  }

  if (prompt_style == "compact") {
    if (product_knowledge == "known") {
      return(paste(
        "Using only the results below, describe this product as a relative sensory profile within the full product set.",
        "Focus on what distinguishes it from the average profile and from the other products.",
        "Do not rename the product.",
        sep = "\n"
      ))
    } else {
      return(paste(
        "Using only the results below, describe this stimulus as a relative sensory profile within the full stimulus set.",
        "Focus on what distinguishes it from the average profile and from the other stimuli.",
        "If the profile is clear enough, you may propose a short descriptive name.",
        sep = "\n"
      ))
    }
  }

  if (product_knowledge == "known") {
    return(paste(
      "Using only the results below, describe this product as a relative sensory profile within the full product set.",
      "Identify the strongest sensory attributes that are above and below the average profile.",
      "Explain what makes this product distinctive relative to the others.",
      "Do not rename the product.",
      sep = "\n"
    ))
  }

  paste(
    "Using only the results below, describe this stimulus as a relative sensory profile within the full stimulus set.",
    "Identify the strongest sensory attributes that are above and below the average profile.",
    "Explain what makes this stimulus distinctive relative to the others.",
    "If the profile is sufficiently clear, you may propose a short descriptive name for the stimulus.",
    sep = "\n"
  )
}

build_conclusion_qda <- function(isolate_groups = FALSE,
                                 product_knowledge = c("known", "unknown")) {
  product_knowledge <- match.arg(product_knowledge)

  unit_singular <- .unit_word_qda(product_knowledge, capital = FALSE, plural = FALSE)
  unit_plural <- .unit_word_qda(product_knowledge, capital = FALSE, plural = TRUE)

  if (!isolate_groups) {
    if (product_knowledge == "known") {
      return(paste(
        "# Final Summary Task",
        paste0("1. **A comparison of all ", unit_plural, "**, highlighting the main sensory contrasts."),
        paste0("2. **A short profile of each ", unit_singular, "** based on the retained attributes."),
        "",
        "# Output format",
        "Your output must be **formatted using valid Quarto Markdown**.",
        sep = "\n"
      ))
    }

    return(paste(
      "# Final Summary Task",
      paste0("1. **A comparison of all ", unit_plural, "**, highlighting the main sensory contrasts."),
      paste0("2. **A short profile of each ", unit_singular, "** based on the retained attributes."),
      "3. **A list of descriptive names you assigned**, if any.",
      "",
      "# Output format",
      "Your output must be **formatted using valid Quarto Markdown**.",
      sep = "\n"
    ))
  }

  if (product_knowledge == "known") {
    return(paste(
      "# Final Summary Task",
      "1. **A short sensory profile of the product** based on the retained attributes.",
      "2. **A brief explanation of what makes it distinctive relative to the other products**.",
      "",
      "# Output format",
      "Your output must be **formatted using valid Quarto Markdown**.",
      sep = "\n"
    ))
  }

  paste(
    "# Final Summary Task",
    "1. **A short sensory profile of the stimulus** based on the retained attributes.",
    "2. **A brief explanation of what makes it distinctive relative to the other stimuli**.",
    "3. **A descriptive name**, if you assigned one.",
    "",
    "# Output format",
    "Your output must be **formatted using valid Quarto Markdown**.",
    sep = "\n"
  )
}

# ---------------------------------------------------------------------------
# Sentences
# ---------------------------------------------------------------------------

get_sentences_qda <- function(res_cd,
                              drop.negative,
                              proba = 0.05,
                              sample.pct = 1,
                              prompt_style = c("detailed", "compact"),
                              product_knowledge = c("known", "unknown")) {
  prompt_style <- match.arg(prompt_style)
  product_knowledge <- match.arg(product_knowledge)
  res_cd <- res_cd$quanti
  ppts <- list()

  unit_singular <- .unit_word_qda(product_knowledge, capital = FALSE, plural = FALSE)

  for (grp_name in names(res_cd)) {
    res_df <- res_cd[[grp_name]]
    res_work <- .prepare_qda_df(res_df, sample.pct = sample.pct)

    positive_df <- data.frame()
    negative_df <- data.frame()

    if (!is.null(res_work) && nrow(res_work) > 0) {
      positive_df <- res_work |>
        dplyr::filter(.data$v.test > 0) |>
        dplyr::arrange(.data$p.value)

      negative_df <- res_work |>
        dplyr::filter(.data$v.test < 0) |>
        dplyr::arrange(.data$p.value)
    }

    has_positive_results <- nrow(positive_df) > 0
    has_negative_results <- nrow(negative_df) > 0

    if (!has_positive_results && (drop.negative || !has_negative_results)) {
      if (drop.negative && has_negative_results) {
        ppts[[grp_name]] <- paste(
          paste0(
            "This ", unit_singular, " has **no retained sensory attributes higher than the average profile** ",
            "under the threshold chosen for this analysis (here p <= ", proba, ")."
          ),
          "(Note: Attributes lower than the average profile were found but are hidden because `drop.negative` is TRUE.)",
          sep = "\n"
        )
      } else if (drop.negative) {
        ppts[[grp_name]] <- paste(
          paste0(
            "This ", unit_singular, " has **no retained sensory attributes higher than the average profile** ",
            "under the threshold chosen for this analysis (here p <= ", proba, ")."
          ),
          "(Note: Attributes lower than the average profile are excluded from this analysis.)",
          sep = "\n"
        )
      } else {
        ppts[[grp_name]] <- paste0(
          "This ", unit_singular, " has **no retained sensory attributes** ",
          "under the threshold chosen for this analysis ",
          "(neither higher nor lower than the average profile, here p <= ", proba, ")."
        )
      }
      next
    }

    ppt_high <- if (has_positive_results) {
      table_high <- .format_qda_table(positive_df)
      glue::glue(
        "### {.attribute_title('higher', prompt_style = prompt_style)}\n\n",
        "{paste(table_high, collapse = '\n')}"
      )
    } else {
      paste0("This ", unit_singular, " has no retained sensory attributes **higher** than the average profile.")
    }

    ppt_low <- ""
    if (!drop.negative) {
      ppt_low <- if (has_negative_results) {
        table_low <- .format_qda_table(negative_df)
        glue::glue(
          "### {.attribute_title('lower', prompt_style = prompt_style)}\n\n",
          "{paste(table_low, collapse = '\n')}"
        )
      } else {
        paste0("This ", unit_singular, " has no retained sensory attributes **lower** than the average profile.")
      }
    }

    ppts[[grp_name]] <- normalize_blank_lines(paste(ppt_high, ppt_low, sep = "\n\n"))
  }

  ppts
}

# ---------------------------------------------------------------------------
# Prompt assembly
# ---------------------------------------------------------------------------

get_prompt_qda <- function(res_cd, introduction, request, conclusion,
                           isolate_groups, drop.negative, proba = 0.05,
                           sample.pct = 1,
                           prompt_style = c("detailed", "compact"),
                           product_knowledge = c("known", "unknown")) {
  prompt_style <- match.arg(prompt_style)
  product_knowledge <- match.arg(product_knowledge)

  stces_quanti <- if ("quanti" %in% names(res_cd)) {
    get_sentences_qda(
      res_cd,
      drop.negative = drop.negative,
      proba = proba,
      sample.pct = sample.pct,
      prompt_style = prompt_style,
      product_knowledge = product_knowledge
    )
  } else {
    list()
  }

  if (length(stces_quanti) == 0 ||
      all(vapply(stces_quanti, function(x) is.null(x) || !nzchar(trimws(x)), logical(1)))) {
    stop("No significant differences between items retained under the current settings, execution was halted.", call. = FALSE)
  }

  unit_word <- .unit_word_qda(product_knowledge, capital = TRUE, plural = FALSE)
  all_groups <- names(stces_quanti)

  if (!isolate_groups) {
    blocks <- vapply(
      all_groups,
      function(grp) {
        quant <- stces_quanti[[grp]]
        glue::glue(
          "## {unit_word} '{grp}'\n\n",
          "### Key Sensory Attributes (Compared to the Average Profile)\n\n",
          "{quant}"
        )
      },
      character(1)
    )

    data_text <- paste(blocks, collapse = "\n\n---\n\n")

    return(
      build_standard_prompt(
        introduction = introduction,
        request = request,
        data = data_text,
        conclusion = conclusion
      )
    )
  }

  prompts_list <- lapply(all_groups, function(grp) {
    quant <- stces_quanti[[grp]]

    data_text <- glue::glue(
      "## {unit_word} '{grp}'\n\n",
      "### Key Sensory Attributes (Compared to the Average Profile)\n\n",
      "{quant}"
    )

    build_standard_prompt(
      introduction = introduction,
      request = request,
      data = data_text,
      conclusion = conclusion
    )
  })

  names(prompts_list) <- all_groups
  prompts_list
}

# ---------------------------------------------------------------------------
# Main
# ---------------------------------------------------------------------------

#' Interpret quantitative descriptive analysis data
#'
#' Characterizes the relative sensory profiles of products or stimuli using
#' `SensoMineR::decat()`, formats the retained product-by-attribute results as
#' an evidence-based prompt, and optionally sends this prompt to a large
#' language model.
#'
#' For each product or stimulus, the function identifies sensory attributes
#' whose adjusted means are significantly higher or lower than the overall
#' average profile. The interpretation may be produced for all products
#' together or separately for each product.
#'
#' @param dataset A data frame containing the sensory evaluations.
#'
#'   Rows generally correspond to individual evaluations of products by
#'   panelists. The data frame must contain the categorical variables used in
#'   `formul`, followed by the quantitative sensory attributes specified by
#'   `firstvar` and `lastvar`.
#'
#'   In a standard quantitative descriptive analysis design, the categorical
#'   variables usually include a product factor and a panelist factor, while
#'   the quantitative variables contain the intensity scores assigned to the
#'   sensory attributes.
#' @param formul A one-sided analysis-of-variance formula describing the model
#'   fitted separately to each sensory attribute.
#'
#'   It is typically supplied as a character string, for example
#'   `"~Product+Panelist"` or
#'   `"~Product+Panelist+Product:Panelist"`.
#'
#'   The first term on the right-hand side is treated as the categorical
#'   variable of interest. It must therefore be the product or stimulus
#'   variable to be characterized, and it must correspond to a column of
#'   `dataset`.
#'
#'   For example, in `"~Product+Panelist"`, `Product` is characterized and
#'   `Panelist` is included in the model to account for differences between
#'   panelists.
#' @param firstvar A single integer giving the column index of the first
#'   quantitative sensory attribute to analyze.
#' @param lastvar A single integer giving the column index of the last
#'   quantitative sensory attribute to analyze. The default is the final
#'   column of `dataset`.
#' @param introduction An optional character string providing the study
#'   context in the prompt.
#'
#'   A useful introduction should explain what was evaluated, who performed
#'   the evaluations, how the evaluations were collected, and what the
#'   sensory attributes represent.
#'
#'   If `NULL`, a generic introduction is created according to
#'   `product_knowledge` and `isolate.groups`.
#' @param request An optional character string describing the interpretation
#'   expected from the language model.
#'
#'   If `NULL`, a default request is created according to `prompt_style`,
#'   `product_knowledge`, and `isolate.groups`.
#' @param conclusion An optional character string defining the expected final
#'   synthesis or output structure.
#'
#'   If `NULL`, the function creates a default conclusion asking for either a
#'   comparison of all products or a synthesis of the current product,
#'   depending on `isolate.groups`.
#' @param model Character string giving the model used by the selected
#'   provider. The default is `"llama3"`, intended for the default Ollama
#'   backend.
#' @param provider LLM backend used when `generate = TRUE`. One of
#'   `"ollama"` or `"gemini"`.
#'
#'   The default is `"ollama"`. Gemini requires a valid API key, typically
#'   supplied through the `GEMINI_API_KEY` environment variable.
#' @param isolate.groups Logical.
#'
#'   If `FALSE`, a single prompt containing the profiles of all products or
#'   stimuli is created. This is generally the most appropriate setting when
#'   the objective is to compare products and identify the main sensory
#'   contrasts across the complete product set.
#'
#'   If `TRUE`, one prompt is created for each product or stimulus. Each
#'   product is still interpreted relative to the overall product set, but
#'   only its own statistical table is included in the corresponding prompt.
#'
#'   Isolated prompts may be useful when there are many products, when the
#'   complete prompt would be too long, or when a separate detailed
#'   description is required for every product.
#' @param drop.negative Logical.
#'
#'   If `FALSE`, the prompt includes both attributes that are higher than the
#'   overall average profile and attributes that are lower than the overall
#'   average profile.
#'
#'   If `TRUE`, attributes associated with negative v-tests are removed, so
#'   only attributes that are significantly higher than the average profile
#'   are retained.
#'
#'   Keeping negative v-tests is generally recommended when the objective is
#'   to produce a complete sensory profile, because an unusually low intensity
#'   may be as informative as an unusually high intensity.
#' @param proba A numeric value between 0 and 1 giving the significance
#'   threshold passed to `SensoMineR::decat()`. The default is `0.05`.
#'
#'   Only product-by-attribute results retained under this threshold are
#'   included in the prompt.
#' @param sample.pct A numeric value between 0 and 1 giving the proportion of
#'   retained sensory attributes included in the prompt.
#'
#'   The default is `1`, meaning that all retained attributes are included.
#'   When `sample.pct < 1`, attributes are sampled across the distribution of
#'   v-test values rather than being selected through unrestricted simple
#'   random sampling. This helps preserve attributes with different strengths
#'   and directions of association.
#'
#'   Use `set.seed()` before calling the function when reproducible sampling
#'   is required.
#'
#'   Sampling affects only the content of the prompt. It does not alter the
#'   complete analytical result stored in the `"decat_result"` attribute.
#' @param prompt_style Character string controlling the amount of statistical
#'   guidance and interpretive detail included in the prompt. One of
#'   `"detailed"` or `"compact"`.
#'
#'   The `"detailed"` style explains the statistical indicators, separates
#'   higher-than-average and lower-than-average attributes, and requests a
#'   structured interpretation.
#'
#'   The `"compact"` style produces a shorter prompt while preserving the
#'   principal interpretation rules.
#'
#'   This argument changes only the prompt. It does not modify the underlying
#'   statistical analysis.
#' @param product_knowledge Character string indicating how product labels
#'   should be treated. One of `"known"` or `"unknown"`.
#'
#'   With `"known"`, the labels are considered meaningful identifiers that
#'   must be preserved. The language model is instructed to describe the
#'   sensory profiles without renaming the products.
#'
#'   With `"unknown"`, the labels are treated as anonymous stimulus codes. The
#'   language model may propose descriptive names when the sensory evidence is
#'   sufficiently clear.
#'
#'   This argument does not change the statistical analysis. It changes only
#'   the terminology and naming instructions used in the prompt.
#' @param generate Logical.
#'
#'   If `FALSE`, no language model is called and the function returns the
#'   constructed prompt or prompts.
#'
#'   If `TRUE`, the prompt or prompts are sent to the selected LLM backend.
#' @param ... Additional provider-specific generation arguments passed to the
#'   selected LLM backend, such as `temperature`, `seed`, or other supported
#'   options.
#'
#' @details
#' ## Statistical analysis
#'
#' The function applies `SensoMineR::decat()` to each quantitative sensory
#' attribute between `firstvar` and `lastvar`.
#'
#' The model supplied through `formul` is fitted separately to each sensory
#' attribute. The first term on the right-hand side of the formula identifies
#' the product or stimulus factor whose levels are to be characterized.
#'
#' For example:
#'
#' ```
#' formul = "~Product+Panelist"
#' ```
#'
#' asks the function to characterize the levels of `Product` while accounting
#' for the panelist effect.
#'
#' The complete `decat()` result contains information about:
#'
#' - the global discriminatory effect of the product factor for each sensory
#'   attribute;
#' - the coefficients associated with individual products;
#' - the adjusted means of the products;
#' - product-specific p-values and v-tests.
#'
#' The prompt constructed by `nail_qda()` focuses on the product-specific
#' results: it describes which sensory attributes characterize each product
#' relative to the average sensory profile of the complete product set.
#'
#' ## Reading the product profiles
#'
#' The tables included in the prompt contain the following columns:
#'
#' - `Variable`: name of the sensory attribute;
#' - `Coeff`: coefficient associated with the product in the fitted model;
#' - `Adjust mean`: adjusted mean intensity for the product on that sensory
#'   attribute;
#' - `p.value`: statistical evidence associated with the product-specific
#'   difference;
#' - `v.test`: standardized direction and strength of the difference from the
#'   average profile.
#'
#' A positive v-test indicates that the product has a higher intensity than
#' the average product profile for the corresponding sensory attribute.
#'
#' A negative v-test indicates that the product has a lower intensity than the
#' average product profile.
#'
#' Larger absolute v-test values indicate stronger departures from the
#' average profile. Smaller p-values indicate stronger statistical evidence
#' under the fitted model.
#'
#' The adjusted mean gives the estimated intensity of the attribute for the
#' product. It should be interpreted together with the v-test and the meaning
#' of the sensory scale.
#'
#' A product profile is therefore relative rather than absolute. For example,
#' a product described as higher in bitterness is more bitter than the
#' average profile of the products included in the current analysis; this
#' statement does not necessarily mean that it would be perceived as highly
#' bitter in a different product set.
#'
#' ## Higher and lower attributes
#'
#' When `drop.negative = FALSE`, both ends of the sensory profile are retained:
#'
#' - positive v-tests identify attributes with intensities above the average
#'   product profile;
#' - negative v-tests identify attributes with intensities below the average
#'   product profile.
#'
#' This generally provides the most complete description of a product.
#'
#' When `drop.negative = TRUE`, only positive v-tests are included. This can
#' be useful when the objective is restricted to identifying the dominant or
#' most intense sensory characteristics, but it removes information about
#' attributes that are unusually weak.
#'
#' ## Known and unknown products
#'
#' With `product_knowledge = "known"`, the product labels are treated as
#' established names or identifiers. The model is asked to preserve them and
#' to explain their relative sensory profiles.
#'
#' With `product_knowledge = "unknown"`, the product labels are treated as
#' anonymous codes. The model may infer descriptive names from the retained
#' sensory attributes. Such names are generated interpretations and do not
#' replace the original factor levels in `dataset`.
#'
#' ## Combined and isolated prompts
#'
#' With `isolate.groups = FALSE`, all product profiles appear in one prompt.
#' This gives the language model direct access to the complete set of
#' contrasts and is preferable for comparative synthesis.
#'
#' With `isolate.groups = TRUE`, one prompt is created for each product. The
#' statistical results are still computed from the complete dataset, so each
#' isolated profile remains relative to the same overall product set.
#'
#' However, the language model sees only one product-specific table at a time.
#' It can therefore describe that product relative to the overall average, but
#' it has less direct information for making detailed pairwise comparisons
#' with other products.
#'
#' ## Prompt construction and generation
#'
#' The final prompt combines:
#'
#' - the study introduction;
#' - a statistical reading guide;
#' - the requested interpretation task;
#' - the retained product-by-attribute tables;
#' - the expected final synthesis.
#'
#' By default, `generate = FALSE`, so the prompt can be inspected, edited, or
#' sent to another model manually.
#'
#' When `generate = TRUE`, the default backend is Ollama and the default model
#' is `"llama3"`. These defaults can be changed with `provider` and `model`.
#'
#' The generated interpretation should be treated as an assisted synthesis of
#' the statistical evidence. It does not replace examination of the fitted
#' model, the experimental design, panel performance, interactions, residuals,
#' or other diagnostic results.
#'
#' The associations reported by the function are descriptive and should not
#' be interpreted as causal effects.
#'
#' @return
#' The returned object depends on `generate` and `isolate.groups`.
#'
#' When `generate = FALSE`:
#'
#' - if `isolate.groups = FALSE`, a character string containing one complete
#'   prompt is returned;
#' - if `isolate.groups = TRUE`, a named list of character prompts is returned,
#'   with one element per product or stimulus.
#'
#' When `generate = TRUE`:
#'
#' - if `isolate.groups = FALSE`, a data frame containing the generated
#'   response and the prompt sent to the selected backend is returned;
#' - if `isolate.groups = TRUE`, a named list of generated results is returned,
#'   with one element per product or stimulus.
#'
#' Two attributes are attached to the returned object:
#'
#' - `"decat_result"` contains the complete analytical result produced by
#'   `SensoMineR::decat()`, after internal standardization of the names used by
#'   NaileR;
#' - `"profile_summary"` contains a compact structured summary for each
#'   product, including the principal attributes above the average profile,
#'   the principal attributes below the average profile when retained, the
#'   number of significant attributes, and an internal indication of profile
#'   strength.
#'
#' The `"decat_result"` attribute is not reduced by `sample.pct`.
#'
#' If no product-by-attribute results are retained under the current settings,
#' the language model is not called and an informative result is returned.
#'
#' @seealso
#' `SensoMineR::decat()`
#'
#' @export
#'
#' @examples
#' \dontrun{
#' # These examples use the sensochoc data from SensoMineR.
#' #
#' # The dataset contains sensory evaluations of six chocolates.
#' # The products were evaluated twice by 29 panelists according
#' # to 14 sensory attributes.
#' #
#' # In sensochoc:
#' # - Product is the factor to be characterized;
#' # - Panelist is included in the ANOVA model;
#' # - the sensory attributes begin in column 5.
#'
#' library(NaileR)
#' library(SensoMineR)
#'
#' data("chocolates", package = "SensoMineR")
#'
#'
#' ### Example 1: construct one detailed prompt for all chocolates ###
#'
#' intro_choc <- "Six chocolates were evaluated twice
#' by a trained panel of 29 assessors.
#' The panelists rated the intensity of 14 sensory attributes.
#' The objective is to describe the relative sensory profile
#' of each chocolate within this product set."
#'
#' intro_choc <- gsub("\n", " ", intro_choc) |>
#'   stringr::str_squish()
#'
#' req_choc <- "Describe the relative sensory profile of each chocolate.
#' For each one, distinguish attributes that are higher
#' than the average profile from attributes that are lower.
#' Then summarize the main sensory contrasts among the six chocolates.
#' Do not rename the chocolates."
#'
#' req_choc <- gsub("\n", " ", req_choc) |>
#'   stringr::str_squish()
#'
#' # Product is the first term in the model because it is
#' # the factor whose levels must be characterized.
#' #
#' # Panelist is included to account for systematic differences
#' # in the use of the sensory scales by the assessors.
#' #
#' # generate = FALSE constructs the prompt without calling an LLM.
#' prompt_choc <- nail_qda(
#'   dataset = sensochoc,
#'   formul = "~Product+Panelist",
#'   firstvar = 5,
#'   lastvar = ncol(sensochoc),
#'   introduction = intro_choc,
#'   request = req_choc,
#'   isolate.groups = FALSE,
#'   drop.negative = FALSE,
#'   proba = 0.05,
#'   sample.pct = 1,
#'   prompt_style = "detailed",
#'   product_knowledge = "known",
#'   generate = FALSE
#' )
#'
#' # Display the complete prompt.
#' cat(prompt_choc)
#'
#' # Inspect the underlying decat() result.
#' decat_choc <- attr(prompt_choc, "decat_result")
#'
#' names(decat_choc)
#'
#' # Inspect the compact structured product summaries.
#' profile_choc <- attr(prompt_choc, "profile_summary")
#'
#' profile_choc
#'
#'
#' ### Example 2: construct one compact prompt per chocolate ###
#'
#' # sample.pct = 0.75 retains a reduced selection of attributes
#' # in each prompt. set.seed() makes this selection reproducible.
#' set.seed(123)
#'
#' prompts_choc <- nail_qda(
#'   dataset = sensochoc,
#'   formul = "~Product+Panelist",
#'   firstvar = 5,
#'   lastvar = ncol(sensochoc),
#'   introduction = intro_choc,
#'   isolate.groups = TRUE,
#'   drop.negative = FALSE,
#'   proba = 0.05,
#'   sample.pct = 0.75,
#'   prompt_style = "compact",
#'   product_knowledge = "known",
#'   generate = FALSE
#' )
#'
#' # The result contains one prompt per chocolate.
#' names(prompts_choc)
#'
#' # Display the prompt for the first chocolate.
#' cat(prompts_choc[[1]])
#'
#' # A named element may also be accessed directly.
#' cat(prompts_choc[["choc1"]])
#'
#'
#' ### Example 3: generate a comparative interpretation with Ollama ###
#'
#' # This example calls a local language model.
#' # Ollama must be running and the llama3 model must be installed.
#' res_choc <- nail_qda(
#'   dataset = sensochoc,
#'   formul = "~Product+Panelist",
#'   firstvar = 5,
#'   lastvar = ncol(sensochoc),
#'   introduction = intro_choc,
#'   request = req_choc,
#'   isolate.groups = FALSE,
#'   drop.negative = FALSE,
#'   proba = 0.05,
#'   sample.pct = 1,
#'   prompt_style = "detailed",
#'   product_knowledge = "known",
#'   provider = "ollama",
#'   model = "llama3",
#'   generate = TRUE
#' )
#'
#' # Display the generated interpretation.
#' cat(res_choc$response)
#'
#' # Display the exact prompt sent to Ollama.
#' cat(res_choc$prompt)
#'
#' # Recover the statistical evidence attached to the result.
#' decat_choc <- attr(res_choc, "decat_result")
#' profile_choc <- attr(res_choc, "profile_summary")
#'
#'
#' ### Example 4: interpret anonymous stimuli and allow naming ###
#'
#' # Create a copy in which the product levels are anonymous codes.
#' sensochoc_blind <- sensochoc
#'
#' levels(sensochoc_blind$Product) <- paste0(
#'   "Stimulus_",
#'   seq_len(nlevels(sensochoc_blind$Product))
#' )
#'
#' intro_blind <- "Six anonymous chocolate stimuli
#' were evaluated twice by 29 trained panelists
#' according to 14 sensory attributes.
#' The stimulus codes do not convey information
#' about the identity or composition of the chocolates."
#'
#' intro_blind <- gsub("\n", " ", intro_blind) |>
#'   stringr::str_squish()
#'
#' # product_knowledge = "unknown" tells the language model
#' # that the stimulus codes are identifiers only.
#' #
#' # The model may propose descriptive sensory names,
#' # but it must base them on the retained statistical evidence.
#' res_blind <- nail_qda(
#'   dataset = sensochoc_blind,
#'   formul = "~Product+Panelist",
#'   firstvar = 5,
#'   lastvar = ncol(sensochoc_blind),
#'   introduction = intro_blind,
#'   isolate.groups = FALSE,
#'   drop.negative = FALSE,
#'   proba = 0.05,
#'   sample.pct = 1,
#'   prompt_style = "detailed",
#'   product_knowledge = "unknown",
#'   provider = "ollama",
#'   model = "llama3",
#'   generate = TRUE
#' )
#'
#' cat(res_blind$response)
#'
#'
#' ### Example 5: retain only attributes above the average profile ###
#'
#' # drop.negative = TRUE removes attributes with negative v-tests.
#' # This produces a more restricted description focused only
#' # on sensory intensities above the average product profile.
#' prompt_positive_choc <- nail_qda(
#'   dataset = sensochoc,
#'   formul = "~Product+Panelist",
#'   firstvar = 5,
#'   lastvar = ncol(sensochoc),
#'   introduction = intro_choc,
#'   isolate.groups = FALSE,
#'   drop.negative = TRUE,
#'   prompt_style = "compact",
#'   product_knowledge = "known",
#'   generate = FALSE
#' )
#'
#' cat(prompt_positive_choc)
#' }
nail_qda <- function(dataset, formul, firstvar, lastvar = length(colnames(dataset)),
                     introduction = NULL, request = NULL, conclusion = NULL,
                     model = "llama3",
                     provider = c("ollama", "gemini"),
                     isolate.groups = FALSE, drop.negative = FALSE,
                     proba = 0.05,
                     sample.pct = 1,
                     prompt_style = c("detailed", "compact"),
                     product_knowledge = c("known", "unknown"),
                     generate = FALSE, ...) {

  prompt_style <- match.arg(prompt_style)
  product_knowledge <- match.arg(product_knowledge)

  provider <- match.arg(provider)

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
    prompt_style = prompt_style,
    product_knowledge = product_knowledge
  )

  if (is.null(introduction)) {
    if (product_knowledge == "known") {
      introduction <- if (!isolate.groups) {
        "For this study, several products were evaluated by panelists using a common list of sensory or perceptual attributes."
      } else {
        paste(
          "The product below belongs to a set of products evaluated by panelists",
          "using a common list of sensory or perceptual attributes.",
          "The goal is to describe this specific product relative to the overall product set."
        )
      }
    } else {
      introduction <- if (!isolate.groups) {
        "For this study, several stimuli were evaluated by panelists using a common list of sensory or perceptual attributes."
      } else {
        paste(
          "The stimulus below belongs to a set of stimuli evaluated by panelists",
          "using a common list of sensory or perceptual attributes.",
          "The goal is to describe this specific stimulus relative to the overall stimulus set."
        )
      }
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

  guide_qda <- build_guide_qda(
    proba = proba,
    prompt_style = prompt_style,
    product_knowledge = product_knowledge
  )
  introduction <- paste(introduction, guide_qda, sep = "\n\n---\n\n")

  res_cd <- SensoMineR::decat(
    dataset,
    formul = formul,
    firstvar = firstvar,
    lastvar = lastvar,
    proba = proba,
    graph = FALSE
  )

  # Robust slot renaming
  if (!"quanti" %in% names(res_cd) && "resT" %in% names(res_cd)) {
    names(res_cd)[names(res_cd) == "resT"] <- "quanti"
  }

  # Robust column renaming inside quanti
  if ("quanti" %in% names(res_cd)) {
    for (i in seq_along(res_cd$quanti)) {
      res_cd$quanti[[i]] <- .standardize_qda_result_names(res_cd$quanti[[i]])
    }
  }

  profile_summary <- .summarize_qda_profiles(
    res_cd,
    drop.negative = drop.negative,
    top_n = 5
  )

  ppt <- tryCatch(
    get_prompt_qda(
      res_cd = res_cd,
      introduction = introduction,
      request = request,
      conclusion = conclusion,
      isolate_groups = isolate.groups,
      drop.negative = drop.negative,
      proba = proba,
      sample.pct = sample.pct,
      prompt_style = prompt_style,
      product_knowledge = product_knowledge
    ),
    error = function(e) {
      if (grepl("No significant differences", conditionMessage(e)) ||
          grepl("No significant differences between items retained", conditionMessage(e))) {
        "NAILER_NO_RESULTS_FOUND"
      } else {
        stop(e)
      }
    }
  )

  if (identical(ppt, "NAILER_NO_RESULTS_FOUND")) {
    no_results_message <- paste0(
      "*No results were retained for interpretation under the threshold chosen for this analysis ",
      "(here p <= ", proba, ").*"
    )

    if (generate) {
      message("Execution halted: No retained differences found. Nothing to generate.")

      if (isolate.groups) {
        out <- list()
        attr(out, "profile_summary") <- profile_summary
        attr(out, "decat_result") <- res_cd
        return(out)
      }

      out <- data.frame(
        model = model,
        response = "No retained differences found.",
        prompt = no_results_message,
        stringsAsFactors = FALSE
      )
      attr(out, "profile_summary") <- profile_summary
      attr(out, "decat_result") <- res_cd
      return(out)
    }

    if (isolate.groups) {
      out <- list()
      attr(out, "profile_summary") <- profile_summary
      attr(out, "decat_result") <- res_cd
      return(out)
    }

    out <- build_standard_prompt(
      introduction = introduction,
      request = request,
      data = no_results_message,
      conclusion = NULL
    )
    attr(out, "profile_summary") <- profile_summary
    attr(out, "decat_result") <- res_cd
    return(out)
  }

  if (!generate) {
    attr(ppt, "profile_summary") <- profile_summary
    attr(ppt, "decat_result") <- res_cd
    return(ppt)
  }

  extra_args <- list(...)
  llm_api_options <- extra_args

  .call_llm <- function(prompt) {
    res_llm <- .call_llm_base(
      provider = provider,
      model = model,
      prompt = prompt,
      output = "df",
      llm_api_options = llm_api_options
    )

    res_llm$prompt <- prompt
    res_llm
  }

  if (!isolate.groups) {
    out <- .call_llm(ppt)
    attr(out, "profile_summary") <- profile_summary
    attr(out, "decat_result") <- res_cd
    return(out)
  }

  res_list <- lapply(ppt, .call_llm)
  names(res_list) <- names(ppt)
  attr(res_list, "profile_summary") <- profile_summary
  attr(res_list, "decat_result") <- res_cd
  res_list
}
