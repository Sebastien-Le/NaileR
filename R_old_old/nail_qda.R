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

.unit_word_qda <- function(product_knowledge = c("known", "unknown"),
                           capital = FALSE,
                           plural = FALSE) {
  product_knowledge <- match.arg(product_knowledge)

  word <- if (product_knowledge == "known") {
    if (plural) "products" else "product"
  } else {
    if (plural) "stimuli" else "stimulus"
  }

  if (capital) {
    paste0(toupper(substr(word, 1, 1)), substr(word, 2, nchar(word)))
  } else {
    word
  }
}

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
      "* **v.test**: positive = higher than the average profile; negative = lower than the average profile."
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

#' Interpret QDA data
#'
#' Generate an LLM response to analyze QDA data.
#'
#' @param dataset a data frame made up of at least two categorical variables
#' (product, panelist) and a set of quantitative variables (sensory attributes).
#' @param formul the analysis of variance model to be evaluated for each sensory attribute.
#' @param firstvar the index of the first sensory attribute.
#' @param lastvar the index of the last sensory attribute.
#' @param introduction the introduction for the LLM prompt.
#' @param request the request for the LLM prompt.
#' @param conclusion the conclusion for the LLM prompt.
#' @param model the model name ('llama3' by default).
#' @param isolate.groups a boolean that indicates whether to give the LLM
#' a single prompt, or one prompt per product.
#' @param drop.negative a boolean that indicates whether to drop negative
#' v.test values for interpretation.
#' @param proba the significance threshold used to retain results for interpretation.
#' @param sample.pct proportion of retained attributes to keep in the prompt.
#' @param prompt_style either "detailed" or "compact".
#' @param product_knowledge either "known" or "unknown".
#' @param generate a boolean that indicates whether to generate the LLM response.
#' If FALSE, the function only returns the prompt.
#' @param ... Additional arguments passed to `ollamar::generate`
#' (e.g., `temperature`, `seed`).
#'
#' @return If `generate = FALSE`, a prompt string or a named list of prompt strings.
#' If `generate = TRUE`, a data frame or named list of data frames.
#'
#' @export
nail_qda <- function(dataset, formul, firstvar, lastvar = length(colnames(dataset)),
                     introduction = NULL, request = NULL, conclusion = NULL,
                     model = "llama3",
                     isolate.groups = FALSE, drop.negative = FALSE,
                     proba = 0.05,
                     sample.pct = 1,
                     prompt_style = c("detailed", "compact"),
                     product_knowledge = c("known", "unknown"),
                     generate = FALSE, ...) {

  prompt_style <- match.arg(prompt_style)
  product_knowledge <- match.arg(product_knowledge)

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
  ollama_api_options <- filter_ollama_options(extra_args)

  .call_ollama <- function(prompt) {
    res_llm <- .call_ollama_base(
      model = model,
      prompt = prompt,
      output = "df",
      ollama_api_options = ollama_api_options
    )

    res_llm$prompt <- prompt
    res_llm
  }

  if (!isolate.groups) {
    out <- .call_ollama(ppt)
    attr(out, "profile_summary") <- profile_summary
    attr(out, "decat_result") <- res_cd
    return(out)
  }

  res_list <- lapply(ppt, .call_ollama)
  names(res_list) <- names(ppt)
  attr(res_list, "profile_summary") <- profile_summary
  attr(res_list, "decat_result") <- res_cd
  res_list
}
