#' @importFrom dplyr filter select arrange desc mutate
#' @importFrom glue glue glue_collapse
#' @importFrom tibble rownames_to_column
#' @importFrom utils globalVariables
#' @importFrom stats median
utils::globalVariables(c(".data", "nchar_text", "group"))

# ---------------------------------------------------------------------------
# Validation
# ---------------------------------------------------------------------------

validate_textual_inputs <- function(dataset,
                                    num.var,
                                    num.text,
                                    isolate.groups,
                                    sample.pct,
                                    generate,
                                    prompt_style,
                                    text_role) {
  if (!is.data.frame(dataset)) {
    stop("`dataset` must be a data frame.", call. = FALSE)
  }

  if (ncol(dataset) < 2) {
    stop("`dataset` must contain at least two columns.", call. = FALSE)
  }

  if (!is.numeric(num.var) || length(num.var) != 1 || is.na(num.var) ||
      !is.finite(num.var) || num.var != floor(num.var) ||
      num.var < 1 || num.var > ncol(dataset)) {
    stop("`num.var` must be a single valid integer column index.", call. = FALSE)
  }

  if (!is.numeric(num.text) || length(num.text) != 1 || is.na(num.text) ||
      !is.finite(num.text) || num.text != floor(num.text) ||
      num.text < 1 || num.text > ncol(dataset)) {
    stop("`num.text` must be a single valid integer column index.", call. = FALSE)
  }

  if (num.var == num.text) {
    stop("`num.var` and `num.text` must refer to two different columns.", call. = FALSE)
  }

  if (!is.logical(isolate.groups) || length(isolate.groups) != 1 || is.na(isolate.groups)) {
    stop("`isolate.groups` must be a single non-missing logical value.", call. = FALSE)
  }

  if (!is.logical(generate) || length(generate) != 1 || is.na(generate)) {
    stop("`generate` must be a single non-missing logical value.", call. = FALSE)
  }

  if (!is.numeric(sample.pct) || length(sample.pct) != 1 || is.na(sample.pct) ||
      sample.pct <= 0 || sample.pct > 1) {
    stop("`sample.pct` must be a single numeric value in ]0, 1].", call. = FALSE)
  }

  if (!prompt_style %in% c("detailed", "compact")) {
    stop("`prompt_style` must be one of: 'detailed', 'compact'.", call. = FALSE)
  }

  if (!text_role %in% c("responses", "comments", "verbatims")) {
    stop("`text_role` must be one of: 'responses', 'comments', 'verbatims'.", call. = FALSE)
  }

  grp <- dataset[[num.var]]
  txt <- dataset[[num.text]]

  if (all(is.na(grp))) {
    stop("The grouping variable contains only missing values.", call. = FALSE)
  }

  if (all(is.na(txt))) {
    stop("The textual variable contains only missing values.", call. = FALSE)
  }

  txt_chr <- as.character(txt)
  txt_chr[is.na(txt_chr)] <- ""
  txt_chr <- trimws(txt_chr)

  if (!any(nzchar(txt_chr))) {
    stop("No non-empty textual responses were found in the textual variable.", call. = FALSE)
  }

  invisible(TRUE)
}

# ---------------------------------------------------------------------------
# Helpers
# ---------------------------------------------------------------------------

.text_unit_word <- function(text_role = c("responses", "comments", "verbatims"),
                            capital = FALSE,
                            plural = TRUE) {
  text_role <- match.arg(text_role)

  word <- switch(
    text_role,
    responses = if (plural) "responses" else "response",
    comments  = if (plural) "comments" else "comment",
    verbatims = if (plural) "verbatims" else "verbatim"
  )

  if (capital) {
    paste0(toupper(substr(word, 1, 1)), substr(word, 2, nchar(word)))
  } else {
    word
  }
}

.textual_strength_label <- function(n_texts, median_length) {
  if (is.na(n_texts) || n_texts <= 1) return("weak")
  if (is.na(median_length)) return("moderate")

  if (n_texts >= 15 && median_length >= 80) return("strong")
  if (n_texts >= 8 && median_length >= 40) return("moderate")
  "weak"
}

.extract_nonempty_texts <- function(x) {
  x <- as.character(x)
  x[is.na(x)] <- ""
  x <- trimws(x)
  x[nzchar(x)]
}

.sample_group_corpus <- function(corpus, sample.pct = 1, seed = NULL) {
  if (length(corpus) == 0) return(character(0))
  if (sample.pct >= 1) return(corpus)

  sample_size <- max(1, round(length(corpus) * sample.pct))
  .with_preserved_seed(seed, {
    sample(corpus, size = sample_size)
  })
}

.summarize_textual_groups <- function(dataset, num.var, num.text) {
  var_name <- colnames(dataset)[num.var]
  text_name <- colnames(dataset)[num.text]

  grp <- dataset[[var_name]]
  if (!is.factor(grp)) {
    grp <- as.factor(grp)
  }

  split_data <- split(dataset, grp)
  out <- list()

  for (grp_name in names(split_data)) {
    df_grp <- split_data[[grp_name]]
    corpus <- .extract_nonempty_texts(df_grp[[text_name]])

    lengths <- if (length(corpus) > 0) nchar(corpus) else numeric(0)

    out[[grp_name]] <- list(
      n_texts = length(corpus),
      median_length = if (length(lengths) > 0) stats::median(lengths) else NA_real_,
      max_length = if (length(lengths) > 0) max(lengths) else NA_real_,
      min_length = if (length(lengths) > 0) min(lengths) else NA_real_,
      evidence_strength = .textual_strength_label(
        n_texts = length(corpus),
        median_length = if (length(lengths) > 0) stats::median(lengths) else NA_real_
      )
    )
  }

  out
}

# ---------------------------------------------------------------------------
# Builders
# ---------------------------------------------------------------------------

build_guide_textual <- function(sample.pct = 1,
                                prompt_style = c("detailed", "compact"),
                                text_role = c("responses", "comments", "verbatims")) {
  prompt_style <- match.arg(prompt_style)
  text_role <- match.arg(text_role)
  text_plural <- .text_unit_word(text_role, capital = FALSE, plural = TRUE)

  if (prompt_style == "compact") {
    return(paste(
      "## How to Read the Data",
      paste0("The data below contains raw ", text_plural, " grouped by category."),
      "Each bullet point corresponds to one individual textual contribution.",
      if (sample.pct < 1) {
        paste0("Only a sample of the available texts is shown for each group (sample.pct = ", sample.pct, ").")
      } else {
        "All available non-empty texts are shown for each group."
      },
      "Your task is to synthesize what characterizes each group based only on these texts.",
      "Treat recurring patterns as group-level textual evidence, not as properties shared by every individual.",
      "Do not infer hidden motives, personality traits, moral qualities, or causal explanations that are not supported by the corpus.",
      sep = "\n"
    ))
  }

  paste(
    "## How to Read the Data",
    paste0("The data below contains raw ", text_plural, " grouped by category."),
    "Each bullet point corresponds to one individual textual contribution.",
    if (sample.pct < 1) {
      paste0("Only a sample of the available non-empty texts is shown for each group (sample.pct = ", sample.pct, ").")
    } else {
      "All available non-empty texts are shown for each group."
    },
    "The texts are raw observations and may contain redundancy, variability in phrasing, and unequal levels of detail.",
    "Your task is to synthesize what characterizes each group from these texts without inventing information that is not supported by the corpus.",
    "Treat recurring patterns as group-level textual evidence, not as properties shared by every individual.",
    "Do not infer hidden motives, personality traits, moral qualities, or causal explanations that are not supported by the corpus.",
    "When the evidence is mixed, partial, or weak, say so explicitly.",
    sep = "\n"
  )
}

build_request_textual <- function(isolate.groups = TRUE,
                                  prompt_style = c("detailed", "compact")) {
  prompt_style <- match.arg(prompt_style)

  if (!isolate.groups) {
    if (prompt_style == "compact") {
      return(paste(
        "Using only the raw texts below, describe what characterizes each group and what differentiates the groups from one another.",
        "Then propose a short neutral descriptive label for each group, based only on the recurring themes in the texts.",
        sep = "\n"
      ))
    }

    return(paste(
      "Using only the raw texts below, describe what characterizes each group and what differentiates the groups from one another.",
      "Identify the dominant themes, recurring ideas, and any notable contrasts between groups.",
      "Then propose a short neutral descriptive label for each group, based only on the recurring themes in the texts.",
      "If a group is weakly documented or internally heterogeneous, say so explicitly.",
      sep = "\n"
    ))
  }

  if (prompt_style == "compact") {
    return(paste(
      "Using only the raw texts below, describe what characterizes this group.",
      "Then propose a short neutral descriptive label for the group, based only on the recurring themes in the texts.",
      sep = "\n"
    ))
  }

  paste(
    "Using only the raw texts below, describe what characterizes this group.",
    "Identify the dominant themes, recurring ideas, tone, and any notable internal diversity.",
    "Then propose a short neutral descriptive label for the group, based only on the recurring themes in the texts.",
    "If the evidence is limited, mixed, or weak, say so explicitly.",
    sep = "\n"
  )
}

build_conclusion_textual <- function(isolate.groups = TRUE) {
  if (!isolate.groups) {
    return(paste(
      "# Final Summary Task",
      "At the end, provide:",
      "1. **A comparison of all groups**.",
      "2. **A short profile of each group**.",
      "3. **A list of the neutral descriptive group labels you assigned**.",
      "",
      "# Output format",
      "Your output must be **formatted using valid Quarto Markdown**.",
      sep = "\n"
    ))
  }

  paste(
    "# Final Summary Task",
    "At the end, provide:",
    "1. **A short profile of the group**.",
    "2. **A neutral descriptive group label you assigned**.",
    "",
    "# Output format",
    "Your output must be **formatted using valid Quarto Markdown**.",
    sep = "\n"
  )
}

# ---------------------------------------------------------------------------
# Sentences
# ---------------------------------------------------------------------------

get_sentences_textual <- function(dataset, num.var, num.text, sample.pct = 1,
                                  text_role = c("responses", "comments", "verbatims"),
                                  seed = NULL) {
  text_role <- match.arg(text_role)

  var_name <- colnames(dataset)[num.var]
  text_name <- colnames(dataset)[num.text]

  if (!is.factor(dataset[[var_name]])) {
    dataset[[var_name]] <- as.factor(dataset[[var_name]])
  }

  grouped_data <- split(dataset, dataset[[var_name]])
  ppts <- list()

  for (grp_name in names(grouped_data)) {
    group_df <- grouped_data[[grp_name]]
    corpus <- .extract_nonempty_texts(group_df[[text_name]])

    if (length(corpus) == 0) {
      text_plural <- .text_unit_word(text_role, capital = FALSE, plural = TRUE)
      ppts[[grp_name]] <- paste0(
        "This group has **no non-empty ", text_plural, "** to display."
      )
      next
    }

    total_responses <- length(corpus)
    corpus_sampled <- .sample_group_corpus(corpus, sample.pct = sample.pct, seed = seed)

    header <- if (sample.pct < 1) {
      glue::glue(
        "Showing a sample of **{length(corpus_sampled)}** out of **{total_responses}** total {text_role} for this group:"
      )
    } else {
      glue::glue(
        "Showing all **{total_responses}** {text_role} for this group:"
      )
    }

    corpus_md <- glue::glue_collapse(glue::glue("* {corpus_sampled}"), sep = "\n")
    ppts[[grp_name]] <- paste(header, corpus_md, sep = "\n\n")
  }

  ppts
}

# ---------------------------------------------------------------------------
# Prompt assembly
# ---------------------------------------------------------------------------

get_prompt_textual <- function(dataset, num.var, num.text,
                               introduction, request, conclusion,
                               isolate.groups = TRUE,
                               sample.pct = 1,
                               text_role = c("responses", "comments", "verbatims"),
                               seed = NULL) {
  text_role <- match.arg(text_role)

  sentences_list <- get_sentences_textual(
    dataset = dataset,
    num.var = num.var,
    num.text = num.text,
    sample.pct = sample.pct,
    text_role = text_role,
    seed = seed
  )

  if (length(sentences_list) == 0 ||
      all(vapply(sentences_list, function(x) !nzchar(trimws(x)), logical(1)))) {
    stop("No textual data found to process, execution was halted.", call. = FALSE)
  }

  all_groups <- names(sentences_list)

  stces <- vapply(
    all_groups,
    function(grp) {
      sent <- sentences_list[[grp]]
      glue::glue(
        "## Group '{grp}'\n\n",
        "{sent}"
      )
    },
    character(1)
  )

  if (!isolate.groups) {
    data_text <- paste(stces, collapse = "\n\n---\n\n")
    return(build_standard_prompt(
      introduction = introduction,
      request = request,
      data = data_text,
      conclusion = conclusion
    ))
  }

  prompts_list <- lapply(seq_along(stces), function(i) {
    build_standard_prompt(
      introduction = introduction,
      request = request,
      data = stces[[i]],
      conclusion = conclusion
    )
  })

  names(prompts_list) <- all_groups
  prompts_list
}

# ---------------------------------------------------------------------------
# Main textual function
# ---------------------------------------------------------------------------

#' Interpret grouped responses to open-ended questions
#'
#' Builds evidence-based prompts from raw open-ended texts grouped by a
#' categorical variable and optionally sends these prompts to a large language
#' model.
#'
#' The function can either:
#'
#' - place all groups in one prompt to support direct comparison;
#' - create one separate prompt for each group to obtain more focused
#'   group-level interpretations.
#'
#' Missing and empty texts are removed before the prompts are constructed.
#' When requested, texts can be sampled independently within each group to
#' reduce prompt length.
#'
#' By default, `generate = FALSE`, so no language model is called and the
#' constructed prompt or prompts can be inspected before generation.
#'
#' @param dataset A data frame containing at least:
#'
#'   - one categorical or discrete variable defining the groups;
#'   - one variable containing the open-ended texts.
#'
#'   Rows generally correspond to individual respondents, observations, or
#'   textual contributions.
#'
#'   The grouping variable does not need to be a factor. It is converted
#'   internally when necessary.
#'
#'   The textual variable is converted to character. Missing values, empty
#'   strings, and strings containing only spaces are excluded from the
#'   textual corpus.
#' @param num.var A single integer giving the column index of the grouping
#'   variable in `dataset`.
#'
#'   For example, if the first column contains the group membership, use
#'   `num.var = 1`.
#'
#'   This argument expects a column position, not a column name.
#' @param num.text A single integer giving the column index of the textual
#'   variable in `dataset`.
#'
#'   For example, if the second column contains the open-ended responses, use
#'   `num.text = 2`.
#'
#'   `num.var` and `num.text` must refer to two different columns.
#' @param introduction An optional character string providing the study context
#'   at the beginning of the prompt.
#'
#'   A useful introduction may explain:
#'
#'   - the question that was asked;
#'   - who produced the texts;
#'   - the meaning of the grouping variable;
#'   - the purpose of the textual analysis.
#'
#'   If `NULL`, a generic introduction is created. The default introduction
#'   depends on `isolate.groups`.
#'
#'   The statistical and methodological reading guide created internally by
#'   the function is appended to this introduction.
#' @param request An optional character string specifying the interpretation
#'   expected from the language model.
#'
#'   If `NULL`, a default request is created according to `isolate.groups` and
#'   `prompt_style`.
#'
#'   The default request asks the model to identify recurring themes and
#'   characterize the textual profile of each group. It may also request a
#'   short neutral descriptive label based only on the themes present in the
#'   texts.
#' @param conclusion An optional character string defining the expected final
#'   synthesis and output format.
#'
#'   If `NULL`, a default conclusion is created.
#'
#'   With `isolate.groups = FALSE`, the default conclusion requests:
#'
#'   - a comparison of all groups;
#'   - a short textual profile of each group;
#'   - the neutral descriptive labels assigned to the groups.
#'
#'   With `isolate.groups = TRUE`, it requests a short profile and a neutral
#'   descriptive label for the current group.
#' @param model Character string giving the language model used by the selected
#'   provider. The default is `"llama3"`, intended for the default Ollama
#'   backend.
#' @param provider LLM backend used when `generate = TRUE`. One of
#'   `"ollama"` or `"gemini"`.
#'
#'   The default is `"ollama"`, which uses a local Ollama installation.
#'
#'   Gemini requires a valid API key, typically supplied through the
#'   `GEMINI_API_KEY` environment variable.
#'
#'   This argument has no effect on prompt construction when
#'   `generate = FALSE`.
#' @param isolate.groups Logical indicating whether groups should be placed in
#'   separate prompts. The default is `TRUE`.
#'
#'   With `isolate.groups = FALSE`, all groups and all selected texts are
#'   included in one prompt. This gives the language model direct access to
#'   the complete set of groups and is generally preferable when the objective
#'   is to compare groups.
#'
#'   With `isolate.groups = TRUE`, one named prompt is created for each group.
#'   This is useful when:
#'
#'   - the complete corpus would create a very long prompt;
#'   - each group requires a focused interpretation;
#'   - group-level summaries will later be reused by
#'     `nail_textual_prep()` or another workflow.
#'
#'   An isolated prompt contains only the texts of the current group. It can
#'   therefore characterize recurring patterns within that group, but it does
#'   not provide the model with the complete textual evidence needed for
#'   detailed direct comparisons with the other groups.
#' @param sample.pct A numeric value in the interval ]0, 1] giving the
#'   proportion of non-empty texts retained within each group.
#'
#'   The default is `1`, meaning that all available non-empty texts are
#'   included.
#'
#'   When `sample.pct < 1`, sampling is performed separately within each
#'   group. The number retained is approximately:
#'
#'   ```
#'   round(number of texts in the group * sample.pct)
#'   ```
#'
#'   At least one text is retained for every non-empty group.
#'
#'   Sampling changes only the texts included in the prompt. It does not alter
#'   the original `dataset` or the complete group-level information stored in
#'   the `"textual_data_summary"` attribute.
#' @param seed An optional numeric seed used to make within-group text sampling
#'   reproducible when `sample.pct < 1`.
#'
#'   The user's random-number generator state is preserved. Consequently,
#'   using `seed` does not modify the random sequence used by subsequent code
#'   in the R session.
#'
#'   If `NULL`, the current random-number generator state is used.
#' @param prompt_style Character string controlling the amount of methodological
#'   guidance included in the prompt. One of `"detailed"` or `"compact"`.
#'
#'   With `"detailed"`, the prompt explains that:
#'
#'   - the texts are raw observations;
#'   - phrasing and level of detail may vary;
#'   - recurring themes should not be treated as properties shared by every
#'     individual;
#'   - mixed, partial, or weak evidence should be reported explicitly.
#'
#'   With `"compact"`, the same general safeguards are retained in a shorter
#'   form.
#'
#'   This argument changes only the prompt instructions. It does not change
#'   the grouping, filtering, or sampling of the texts.
#' @param text_role Character string indicating how the textual contributions
#'   should be named in the prompt. One of `"responses"`, `"comments"`, or
#'   `"verbatims"`.
#'
#'   This argument changes only the terminology used in the prompt. It does
#'   not change the way the texts are processed.
#'
#'   Use:
#'
#'   - `"responses"` for answers to an open-ended question;
#'   - `"comments"` for comments, reviews, or free annotations;
#'   - `"verbatims"` when the textual units are explicitly treated as
#'     verbatims.
#' @param generate Logical.
#'
#'   If `FALSE`, no language model is called. The function returns the
#'   constructed prompt or prompts.
#'
#'   If `TRUE`, the prompt or prompts are sent to the selected LLM backend.
#'
#'   With `isolate.groups = TRUE`, one independent request is sent for each
#'   group.
#' @param ... Additional provider-specific generation arguments passed to the
#'   selected LLM backend, such as `temperature`, `seed`, or other supported
#'   options.
#'
#'   The `seed` argument of `nail_textual()` controls only the sampling of
#'   texts. A provider-specific generation seed, when supported, must be
#'   supplied through `...`.
#'
#' @details
#' ## Purpose of the analysis
#'
#' `nail_textual()` assists with the interpretation of open-ended texts whose
#' authors or observations have been assigned to groups.
#'
#' The function does not fit a statistical textual model. It organizes raw
#' texts into prompts that ask a language model to identify recurring themes,
#' contrasts, tones, and internal diversity.
#'
#' The generated interpretation is therefore a qualitative synthesis of the
#' supplied corpus. It should not be treated as a formal test of group
#' differences.
#'
#' ## Preparation of the textual corpus
#'
#' For each group, the function:
#'
#' 1. converts the textual variable to character;
#' 2. removes missing values;
#' 3. trims leading and trailing spaces;
#' 4. removes empty textual contributions;
#' 5. optionally samples a proportion of the remaining texts;
#' 6. formats every retained contribution as a separate Markdown bullet.
#'
#' The texts themselves are not rewritten, translated, or summarized before
#' being inserted into the prompt.
#'
#' ## Group-level interpretation
#'
#' The default instructions ask the language model to describe recurring
#' patterns at the group level.
#'
#' A recurring theme should not be interpreted as a characteristic shared by
#' every individual in the group. Similarly, an isolated sentence should not
#' be treated as sufficient evidence for a general statement about the group.
#'
#' The default prompt explicitly discourages:
#'
#' - unsupported causal explanations;
#' - hidden-motive interpretations;
#' - personality or moral judgments;
#' - generalization from one individual contribution to the complete group.
#'
#' Neutral descriptive labels may be proposed to facilitate interpretation,
#' but they should remain grounded in recurring textual themes.
#'
#' ## Combined and isolated prompts
#'
#' With `isolate.groups = FALSE`, all groups are included in a single prompt.
#' This is the recommended setting for identifying direct contrasts among
#' groups, because the language model sees all textual corpora simultaneously.
#'
#' With `isolate.groups = TRUE`, every group receives its own prompt. This can
#' improve focus and reduce prompt length, but detailed cross-group comparisons
#' should not be expected because the model sees only one group at a time.
#'
#' ## Sampling and representativeness
#'
#' Sampling can be useful when groups contain many or very long texts.
#' However, the interpretation then applies only to the sampled corpus shown
#' to the model.
#'
#' A small `sample.pct` may omit infrequent themes, minority positions, or
#' internal tensions. The returned prompt explicitly tells the model when only
#' a sample of the corpus is shown.
#'
#' Reproducible sampling can be obtained by supplying `seed`.
#'
#' ## Textual data summary
#'
#' The returned object contains a `"textual_data_summary"` attribute. It is a
#' named list with one element per group.
#'
#' Each element contains:
#'
#' - `n_texts`: number of non-empty texts available in the complete group
#'   corpus;
#' - `median_length`: median text length in characters;
#' - `max_length`: maximum text length in characters;
#' - `min_length`: minimum text length in characters;
#' - `evidence_strength`: a heuristic label based on the number and median
#'   length of the available texts.
#'
#' The `"textual_data_summary"` is calculated from the complete non-empty
#' corpus before sampling. It is therefore not reduced by `sample.pct`.
#'
#' The `evidence_strength` field is an internal descriptive heuristic about
#' corpus volume and text length. It is not a statistical measure of validity,
#' representativeness, reliability, or certainty.
#'
#' ## Custom prompt components
#'
#' `introduction`, `request`, and `conclusion` may be supplied to adapt the
#' analysis to a particular research question.
#'
#' Supplying a custom `request` or `conclusion` replaces the corresponding
#' default block. The reading guide generated by `build_guide_textual()` is
#' still appended to the introduction.
#'
#' Custom instructions should preserve a clear distinction between:
#'
#' - statements directly supported by the corpus;
#' - broader interpretations;
#' - uncertainty, heterogeneity, or missing evidence.
#'
#' ## Generation and confidentiality
#'
#' With `generate = TRUE`, the retained raw texts are included in the request
#' sent to the selected provider.
#'
#' Users should review the corpus before generation when it contains personal,
#' confidential, sensitive, or identifying information.
#'
#' With an external provider, the sampled texts leave the local R process.
#' With a local Ollama installation, generation is normally performed by the
#' locally running model.
#'
#' ## Interpretation limits
#'
#' The generated synthesis does not replace:
#'
#' - examination of the raw corpus;
#' - assessment of sampling and data-collection conditions;
#' - consideration of group sizes;
#' - qualitative coding by a researcher;
#' - formal statistical or lexical analyses when these are required.
#'
#' The result should be treated as an assisted interpretation rather than as
#' definitive evidence about individuals or groups.
#'
#' @return
#' The returned object depends on `generate` and `isolate.groups`.
#'
#' When `generate = FALSE`:
#'
#' - with `isolate.groups = FALSE`, a single character string containing the
#'   complete prompt is returned;
#' - with `isolate.groups = TRUE`, a named list of character prompts is
#'   returned, with one element per group.
#'
#' When `generate = TRUE`:
#'
#' - with `isolate.groups = FALSE`, a data frame returned by the selected LLM
#'   backend is returned;
#' - with `isolate.groups = TRUE`, a named list of backend result data frames
#'   is returned, with one element per group.
#'
#' Every generated result includes a `prompt` column containing the exact
#' prompt sent to the language model.
#'
#' In all normal return modes, the `"textual_data_summary"` attribute contains
#' the complete group-level corpus summary described in the Details section.
#'
#' If the grouping variable contains only missing values, or if the textual
#' variable contains no non-empty text, the function stops with an informative
#' error.
#'
#' @seealso
#' [nail_textual_prep()], [nail_textual_contextualized()]
#'
#' @export
#'
#' @examples
#' ### Basic example without an LLM ###
#'
#' # This small example constructs prompts without calling an LLM.
#' textual_example <- data.frame(
#'   group = factor(c(
#'     "Local orientation", "Local orientation",
#'     "Local orientation", "Local orientation",
#'     "Convenience orientation", "Convenience orientation",
#'     "Convenience orientation", "Convenience orientation"
#'   )),
#'   response = c(
#'     "I prefer buying at the market because I know where the products come from.",
#'     "Local producers and seasonal food are important in my daily choices.",
#'     "I often visit nearby farms and value direct contact with producers.",
#'     "I try to reduce supermarket purchases and support small local shops.",
#'     "I mainly need shopping to be fast and easy after work.",
#'     "The supermarket is practical because everything is available in one place.",
#'     "Price, opening hours, and convenience matter most in my routine.",
#'     "I often use the drive service because it saves time."
#'   ),
#'   stringsAsFactors = FALSE
#' )
#'
#' textual_prompts <- nail_textual(
#'   dataset = textual_example,
#'   num.var = 1,
#'   num.text = 2,
#'   isolate.groups = TRUE,
#'   sample.pct = 1,
#'   prompt_style = "detailed",
#'   text_role = "responses",
#'   generate = FALSE
#' )
#'
#' # Display the available groups.
#' names(textual_prompts)
#'
#' # Display one complete group prompt.
#' cat(textual_prompts[["Local orientation"]])
#'
#' # Inspect the summary calculated from the complete corpus.
#' textual_data_summary <- attr(
#'   textual_prompts,
#'   "textual_data_summary"
#' )
#'
#' textual_data_summary[["Local orientation"]]
#'
#'
#' \dontrun{
#' # The following examples call a large language model.
#' # Processing time may therefore be longer than ten seconds.
#' #
#' # For Ollama examples, Ollama must be running locally and
#' # the requested model must be installed.
#'
#' library(NaileR)
#'
#'
#' ### Example 1: Car-alone survey ###
#'
#' data(car_alone)
#'
#' intro_car <- paste(
#'   "Knowing the impact on the climate, respondents explained",
#'   "the benefits and constraints that influenced their mobility choices."
#' )
#'
#' # sample.pct = 0.5 samples half of the non-empty texts
#' # separately within each group.
#' #
#' # seed makes this within-group sampling reproducible.
#' res_nail_textual_car <- nail_textual(
#'   dataset = car_alone,
#'   num.var = 1,
#'   num.text = 2,
#'   introduction = intro_car,
#'   request = NULL,
#'   model = "llama3",
#'   provider = "ollama",
#'   isolate.groups = TRUE,
#'   sample.pct = 0.5,
#'   seed = 123,
#'   prompt_style = "detailed",
#'   text_role = "responses",
#'   generate = TRUE
#' )
#'
#' # One generated result is returned for each group.
#' names(res_nail_textual_car)
#'
#' # Display each interpretation together with its group name.
#' for (grp in names(res_nail_textual_car)) {
#'   cat("\n\n###", grp, "###\n")
#'   cat(res_nail_textual_car[[grp]]$response)
#' }
#'
#' # Inspect the exact prompt sent for the first group.
#' cat(res_nail_textual_car[[1]]$prompt)
#'
#'
#' ### Example 2: Atomic-habits survey ###
#'
#' data(atomic_habit_clust)
#'
#' intro_atomic <- paste(
#'   "These data were collected in a survey on atomic habits.",
#'   "Respondents explained what they were prepared to change",
#'   "in their daily habits to make the world a better place,",
#'   "which habits they felt able to adopt,",
#'   "and which habits they considered restrictive."
#' )
#'
#' # Keep the open-ended response and clustering variables.
#' dta_plane <- atomic_habit_clust[, c(32, 51), drop = FALSE]
#'
#' # Remove missing, empty, and placeholder responses.
#' plane_text <- trimws(as.character(dta_plane$never_plane_text))
#'
#' keep_plane <- !is.na(plane_text) &
#'   nzchar(plane_text) &
#'   plane_text != "THAT"
#'
#' dta_plane <- droplevels(
#'   dta_plane[keep_plane, , drop = FALSE]
#' )
#'
#' summary(dta_plane)
#'
#' # Create one interpretation per cluster.
#' res_nail_textual_plane <- nail_textual(
#'   dataset = dta_plane,
#'   num.var = 2,
#'   num.text = 1,
#'   introduction = intro_atomic,
#'   request = NULL,
#'   model = "llama3",
#'   provider = "ollama",
#'   isolate.groups = TRUE,
#'   sample.pct = 0.75,
#'   seed = 123,
#'   prompt_style = "detailed",
#'   text_role = "responses",
#'   generate = TRUE
#' )
#'
#' names(res_nail_textual_plane)
#'
#' # Inspect the prompt and response for each cluster.
#' for (grp in names(res_nail_textual_plane)) {
#'   cat("\n\n###", grp, "— prompt ###\n")
#'   cat(res_nail_textual_plane[[grp]]$prompt)
#'
#'   cat("\n\n###", grp, "— response ###\n")
#'   cat(res_nail_textual_plane[[grp]]$response)
#' }
#'
#' # Place all clusters in one prompt to support direct comparison.
#' res_nail_textual_plane_comparison <- nail_textual(
#'   dataset = dta_plane,
#'   num.var = 2,
#'   num.text = 1,
#'   introduction = intro_atomic,
#'   request = NULL,
#'   model = "llama3",
#'   provider = "ollama",
#'   isolate.groups = FALSE,
#'   sample.pct = 0.75,
#'   seed = 123,
#'   prompt_style = "detailed",
#'   text_role = "responses",
#'   generate = TRUE
#' )
#'
#' cat(res_nail_textual_plane_comparison$prompt)
#' cat(res_nail_textual_plane_comparison$response)
#'
#'
#' ### Example 3: Car-seat fabrics ###
#'
#' data(fabric)
#'
#' # Compare the drivers of liking and disliking in one prompt.
#' intro_fabric <- paste(
#'   "In this consumer study, several car-seat fabrics were",
#'   "evaluated by consumers who explained their reasons for liking",
#'   "or disliking the fabrics.",
#'   "Reasons for disliking were recorded in group '0',",
#'   "whereas reasons for liking were recorded in group '1'."
#' )
#'
#' request_fabric <- paste(
#'   "Using only the consumer comments, explain the recurring reasons",
#'   "why the fabrics were not appreciated in group '0'",
#'   "and the recurring reasons why they were appreciated in group '1'.",
#'   "Then compare the main drivers of disliking and liking.",
#'   "Do not generalize an isolated comment to the complete group."
#' )
#'
#' res_nail_textual_fabric <- nail_textual(
#'   dataset = fabric,
#'   num.var = 4,
#'   num.text = 3,
#'   introduction = intro_fabric,
#'   request = request_fabric,
#'   model = "llama3",
#'   provider = "ollama",
#'   isolate.groups = FALSE,
#'   prompt_style = "detailed",
#'   text_role = "comments",
#'   generate = TRUE
#' )
#'
#' cat(res_nail_textual_fabric$prompt)
#' cat(res_nail_textual_fabric$response)
#'
#'
#' # Analyze only the reasons for disliking.
#' fabric_disliking <- droplevels(
#'   fabric[
#'     as.character(fabric[[4]]) == "0",
#'     ,
#'     drop = FALSE
#'   ]
#' )
#'
#' intro_fabric_disliking <- paste(
#'   "In this consumer study, several car-seat fabrics were evaluated",
#'   "by consumers who explained their reasons for disliking them.",
#'   "Only reasons for disliking are included below."
#' )
#'
#' request_fabric_disliking <- paste(
#'   "Using only the comments below, identify the recurring reasons",
#'   "why the fabrics were not appreciated.",
#'   "Distinguish central drivers of disliking from less frequent comments."
#' )
#'
#' prompt_fabric_disliking <- nail_textual(
#'   dataset = fabric_disliking,
#'   num.var = 4,
#'   num.text = 3,
#'   introduction = intro_fabric_disliking,
#'   request = request_fabric_disliking,
#'   isolate.groups = TRUE,
#'   prompt_style = "detailed",
#'   text_role = "comments",
#'   generate = FALSE
#' )
#'
#' cat(prompt_fabric_disliking[[1]])
#'
#' res_fabric_disliking <- nail_textual(
#'   dataset = fabric_disliking,
#'   num.var = 4,
#'   num.text = 3,
#'   introduction = intro_fabric_disliking,
#'   request = request_fabric_disliking,
#'   model = "llama3",
#'   provider = "ollama",
#'   isolate.groups = TRUE,
#'   prompt_style = "detailed",
#'   text_role = "comments",
#'   generate = TRUE
#' )
#'
#' cat(res_fabric_disliking[[1]]$response)
#'
#'
#' # Analyze only the reasons for liking.
#' fabric_liking <- droplevels(
#'   fabric[
#'     as.character(fabric[[4]]) == "1",
#'     ,
#'     drop = FALSE
#'   ]
#' )
#'
#' intro_fabric_liking <- paste(
#'   "In this consumer study, several car-seat fabrics were evaluated",
#'   "by consumers who explained their reasons for liking them.",
#'   "Only reasons for liking are included below."
#' )
#'
#' request_fabric_liking <- paste(
#'   "Using only the comments below, identify the recurring reasons",
#'   "why the fabrics were appreciated.",
#'   "Distinguish central drivers of liking from less frequent comments."
#' )
#'
#' prompt_fabric_liking <- nail_textual(
#'   dataset = fabric_liking,
#'   num.var = 4,
#'   num.text = 3,
#'   introduction = intro_fabric_liking,
#'   request = request_fabric_liking,
#'   isolate.groups = TRUE,
#'   prompt_style = "detailed",
#'   text_role = "comments",
#'   generate = FALSE
#' )
#'
#' cat(prompt_fabric_liking[[1]])
#'
#' res_fabric_liking <- nail_textual(
#'   dataset = fabric_liking,
#'   num.var = 4,
#'   num.text = 3,
#'   introduction = intro_fabric_liking,
#'   request = request_fabric_liking,
#'   model = "llama3",
#'   provider = "ollama",
#'   isolate.groups = TRUE,
#'   prompt_style = "detailed",
#'   text_role = "comments",
#'   generate = TRUE
#' )
#'
#' cat(res_fabric_liking[[1]]$response)
#'
#'
#' ### Example 4: Rorschach inkblots ###
#'
#' data(rorschach)
#'
#' # Construct one prompt per inkblot.
#' intro_rorschach <- paste(
#'   "In this study, sixty people were asked to briefly describe",
#'   "one of the inkblots of the Rorschach test."
#' )
#'
#' request_rorschach <- paste(
#'   "Using only the comments below, describe how the inkblot was perceived.",
#'   "Identify recurring images, themes, and emotional tones.",
#'   "Indicate whether the corpus conveys a predominantly favorable,",
#'   "unfavorable, ambivalent, or mixed perception.",
#'   "Report internal diversity and do not generalize an isolated response."
#' )
#'
#' prompts_rorschach <- nail_textual(
#'   dataset = rorschach,
#'   num.var = 2,
#'   num.text = 5,
#'   introduction = intro_rorschach,
#'   request = request_rorschach,
#'   isolate.groups = TRUE,
#'   prompt_style = "detailed",
#'   text_role = "comments",
#'   generate = FALSE
#' )
#'
#' # The list names correspond to the inkblot identifiers.
#' names(prompts_rorschach)
#'
#' # Display the prompts for inkblots 10 and 5.
#' cat(prompts_rorschach[["10"]])
#' cat(prompts_rorschach[["5"]])
#'
#'
#' # Generate an interpretation for inkblot 10 only.
#' rorschach_inkblot_10 <- droplevels(
#'   rorschach[
#'     as.character(rorschach$Inkblot) == "10",
#'     ,
#'     drop = FALSE
#'   ]
#' )
#'
#' res_inkblot_10 <- nail_textual(
#'   dataset = rorschach_inkblot_10,
#'   num.var = 2,
#'   num.text = 5,
#'   introduction = intro_rorschach,
#'   request = request_rorschach,
#'   model = "llama3",
#'   provider = "ollama",
#'   isolate.groups = TRUE,
#'   prompt_style = "detailed",
#'   text_role = "comments",
#'   generate = TRUE
#' )
#'
#' cat(res_inkblot_10[[1]]$prompt)
#' cat(res_inkblot_10[[1]]$response)
#'
#'
#' # Compare the three panels for inkblot 10.
#' rorschach_panel_10 <- droplevels(
#'   rorschach[
#'     as.character(rorschach$Inkblot) == "10",
#'     ,
#'     drop = FALSE
#'   ]
#' )
#'
#' intro_rorschach_panels <- paste(
#'   "In this study, sixty people were asked to briefly describe",
#'   "one inkblot of the Rorschach test.",
#'   "The respondents belonged to three panels,",
#'   "with twenty people in each panel."
#' )
#'
#' request_rorschach_panels <- paste(
#'   "Using only the comments below, identify what is common",
#'   "across the three panels and what is specific to each panel",
#'   "in the perception of the inkblot.",
#'   "Distinguish recurring group-level patterns from isolated comments."
#' )
#'
#' res_rorschach_panels <- nail_textual(
#'   dataset = rorschach_panel_10,
#'   num.var = 1,
#'   num.text = 5,
#'   introduction = intro_rorschach_panels,
#'   request = request_rorschach_panels,
#'   model = "llama3",
#'   provider = "ollama",
#'   isolate.groups = FALSE,
#'   prompt_style = "detailed",
#'   text_role = "comments",
#'   generate = TRUE
#' )
#'
#' cat(res_rorschach_panels$prompt)
#' cat(res_rorschach_panels$response)
#' }
nail_textual <- function(dataset, num.var, num.text,
                         introduction = NULL,
                         request = NULL,
                         conclusion = NULL,
                         model = "llama3",
                         provider = c("ollama", "gemini"),
                         isolate.groups = TRUE,
                         sample.pct = 1,
                         seed = NULL,
                         prompt_style = c("detailed", "compact"),
                         text_role = c("responses", "comments", "verbatims"),
                         generate = FALSE,
                         ...) {
  prompt_style <- match.arg(prompt_style)
  text_role <- match.arg(text_role)
  provider <- match.arg(provider)
  validate_textual_inputs(
    dataset = dataset,
    num.var = num.var,
    num.text = num.text,
    isolate.groups = isolate.groups,
    sample.pct = sample.pct,
    generate = generate,
    prompt_style = prompt_style,
    text_role = text_role
  )

  if (is.null(introduction)) {
    introduction <- if (!isolate.groups) {
      "For this study, individuals answered an open-ended question and were grouped into different categories."
    } else {
      "For this study, individuals answered an open-ended question. The texts below correspond to one specific group."
    }
  }

  if (is.null(request)) {
    request <- build_request_textual(
      isolate.groups = isolate.groups,
      prompt_style = prompt_style
    )
  }

  if (is.null(conclusion)) {
    conclusion <- build_conclusion_textual(
      isolate.groups = isolate.groups
    )
  }

  guide <- build_guide_textual(
    sample.pct = sample.pct,
    prompt_style = prompt_style,
    text_role = text_role
  )

  introduction <- paste(introduction, guide, sep = "\n\n---\n\n")

  textual_data_summary <- .summarize_textual_groups(
    dataset = dataset,
    num.var = num.var,
    num.text = num.text
  )

  ppt <- tryCatch(
    get_prompt_textual(
      dataset = dataset,
      num.var = num.var,
      num.text = num.text,
      introduction = introduction,
      request = request,
      conclusion = conclusion,
      isolate.groups = isolate.groups,
      sample.pct = sample.pct,
      text_role = text_role,
      seed = seed
    ),
    error = function(e) {
      if (grepl("No textual data found", conditionMessage(e))) {
        "NAILER_NO_RESULTS_FOUND"
      } else {
        stop(e)
      }
    }
  )

  if (identical(ppt, "NAILER_NO_RESULTS_FOUND")) {
    no_results_message <- "*No textual data was found for the specified groups.*"

    if (generate) {
      message("Execution halted: No textual data found. Nothing to generate.")

      if (isolate.groups) {
        out <- list()
        attr(out, "textual_data_summary") <- textual_data_summary
        return(out)
      }

      out <- data.frame(
        model = model,
        response = "No textual data found.",
        prompt = no_results_message,
        stringsAsFactors = FALSE
      )
      attr(out, "textual_data_summary") <- textual_data_summary
      return(out)
    }

    if (isolate.groups) {
      out <- list()
      attr(out, "textual_data_summary") <- textual_data_summary
      return(out)
    }

    out <- build_standard_prompt(
      introduction = introduction,
      request = request,
      data = no_results_message,
      conclusion = NULL
    )
    attr(out, "textual_data_summary") <- textual_data_summary
    return(out)
  }

  if (!generate) {
    attr(ppt, "textual_data_summary") <- textual_data_summary
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
    attr(out, "textual_data_summary") <- textual_data_summary
    return(out)
  }

  out <- lapply(ppt, .call_llm)
  names(out) <- names(ppt)
  attr(out, "textual_data_summary") <- textual_data_summary
  out
}

# ---------------------------------------------------------------------------
# Helpers for representative verbatims (textual prep V2)
# ---------------------------------------------------------------------------

.extract_nonempty_texts_textprep <- function(x) {
  x <- as.character(x)
  x[is.na(x)] <- ""
  x <- trimws(x)
  x[nzchar(x)]
}

.normalize_text_for_dedup_textprep <- function(x) {
  x <- tolower(trimws(x))
  x <- gsub("[[:space:]]+", " ", x)
  x
}

.deduplicate_texts_textprep <- function(x) {
  if (length(x) == 0) return(x)
  keep <- !duplicated(.normalize_text_for_dedup_textprep(x))
  x[keep]
}

.truncate_verbatim_textprep <- function(x, max_chars = 220) {
  ifelse(
    nchar(x) <= max_chars,
    x,
    paste0(substr(x, 1, max_chars - 3), "...")
  )
}

.tokenize_keywords_textprep <- function(x) {
  if (is.null(x) || length(x) == 0) return(character(0))

  x <- paste(x, collapse = " ")
  x <- tolower(x)
  x <- gsub("[[:punct:]]+", " ", x)
  toks <- unlist(strsplit(x, "\\s+"))
  toks <- trimws(toks)
  toks <- toks[nzchar(toks)]
  toks <- toks[nchar(toks) >= 4]
  unique(toks)
}

.text_keyword_score_textprep <- function(text, keywords) {
  if (length(keywords) == 0) return(0)

  txt <- tolower(text)
  txt <- gsub("[[:punct:]]+", " ", txt)

  sum(vapply(keywords, function(k) grepl(paste0("\\b", k, "\\b"), txt), logical(1)))
}

.lexical_distance_to_set_textprep <- function(text, set_texts) {
  if (length(set_texts) == 0) return(0)

  tok <- function(z) {
    z <- tolower(z)
    z <- gsub("[[:punct:]]+", " ", z)
    out <- unlist(strsplit(z, "\\s+"))
    out <- trimws(out)
    out <- out[nzchar(out)]
    unique(out[nchar(out) >= 3])
  }

  a <- tok(text)
  if (length(a) == 0) return(1)

  dists <- vapply(set_texts, function(s) {
    b <- tok(s)
    if (length(b) == 0) return(1)
    inter <- length(intersect(a, b))
    union <- length(unique(c(a, b)))
    1 - inter / union
  }, numeric(1))

  min(dists, na.rm = TRUE)
}

.select_representative_verbatims_textprep <- function(dataset,
                                                      num.var,
                                                      num.text,
                                                      textual_summary = NULL,
                                                      n_central = 2,
                                                      n_tension = 1,
                                                      min_chars = 25,
                                                      max_chars = 220) {
  var_name <- colnames(dataset)[num.var]
  text_name <- colnames(dataset)[num.text]

  grp <- dataset[[var_name]]
  if (!is.factor(grp)) {
    grp <- as.factor(grp)
  }

  split_data <- split(dataset, grp)
  out <- list()

  for (grp_name in names(split_data)) {
    df_grp <- split_data[[grp_name]]
    corpus <- .extract_nonempty_texts_textprep(df_grp[[text_name]])
    corpus <- .deduplicate_texts_textprep(corpus)
    corpus <- corpus[nchar(corpus) >= min_chars]

    if (length(corpus) == 0) {
      out[[grp_name]] <- list(
        central = character(0),
        tension = character(0)
      )
      next
    }

    parsed <- NULL
    if (!is.null(textual_summary) && grp_name %in% names(textual_summary)) {
      parsed <- textual_summary[[grp_name]]
    }

    keywords <- character(0)
    if (!is.null(parsed)) {
      keywords <- .tokenize_keywords_textprep(c(
        parsed$main_themes,
        parsed$dominant_concerns,
        parsed$core_textual_profile
      ))
    }

    lengths <- nchar(corpus)
    med_len <- stats::median(lengths)

    keyword_scores <- vapply(corpus, .text_keyword_score_textprep, numeric(1), keywords = keywords)
    length_scores  <- -abs(lengths - med_len)

    ranking_df <- data.frame(
      text = corpus,
      keyword_score = keyword_scores,
      length_score = length_scores,
      stringsAsFactors = FALSE
    )

    ranking_df <- ranking_df[order(-ranking_df$keyword_score, -ranking_df$length_score), , drop = FALSE]
    central <- utils::head(ranking_df$text, n_central)

    remainder <- setdiff(corpus, central)

    # This is a mechanically selected contrastive contribution. It may reflect
    # a tension, a minority position, an atypical formulation, or simply a
    # less central text. The later prompt must not treat it as a contradiction
    # without additional supporting evidence.
    tension <- character(0)

    if (length(remainder) > 0 && n_tension > 0) {
      tension_df <- data.frame(
        text = remainder,
        keyword_score = vapply(remainder, .text_keyword_score_textprep, numeric(1), keywords = keywords),
        lexical_distance = vapply(remainder, .lexical_distance_to_set_textprep, numeric(1), set_texts = central),
        stringsAsFactors = FALSE
      )

      tension_df <- tension_df[order(tension_df$keyword_score, -tension_df$lexical_distance), , drop = FALSE]
      tension <- utils::head(tension_df$text, n_tension)
    }

    out[[grp_name]] <- list(
      central = .truncate_verbatim_textprep(central, max_chars = max_chars),
      tension = .truncate_verbatim_textprep(tension, max_chars = max_chars)
    )
  }

  out
}

.extract_notable_expressions_textprep <- function(dataset,
                                                  num.var,
                                                  num.text,
                                                  top_n = 5,
                                                  min_nchar = 4,
                                                  language = c("en", "fr", "none")) {
  language <- match.arg(language)

  stopwords_en <- c(
    "that", "this", "with", "have", "from", "they", "them", "their",
    "there", "would", "could", "should", "because", "about", "when",
    "what", "which", "will", "only", "then", "than", "into", "very",
    "more", "less", "just", "also", "some", "such", "than", "been",
    "being", "over", "under", "after", "before", "onto",
    "time", "times", "thing", "things"
  )

  stopwords_fr <- c(
    "avec", "dans", "pour", "plus", "moins", "tres", "tres", "mais",
    "donc", "comme", "quand", "tout", "tous", "toute", "toutes",
    "cette", "cela", "ceci", "etre", "etre", "avoir", "fait", "font",
    "aussi", "ainsi", "alors", "apres", "apres", "avant", "entre",
    "chez", "sans", "sous", "sur", "aux", "des", "les", "une", "que",
    "qui", "quoi", "dont", "leur", "leurs", "nous", "vous"
  )

  stopwords_basic <- switch(
    language,
    en = stopwords_en,
    fr = stopwords_fr,
    none = character(0)
  )

  var_name <- colnames(dataset)[num.var]
  text_name <- colnames(dataset)[num.text]

  grp <- dataset[[var_name]]
  if (!is.factor(grp)) {
    grp <- as.factor(grp)
  }

  split_data <- split(dataset, grp)
  out <- list()

  for (grp_name in names(split_data)) {
    corpus <- .extract_nonempty_texts_textprep(split_data[[grp_name]][[text_name]])
    if (length(corpus) == 0) {
      out[[grp_name]] <- character(0)
      next
    }

    txt <- tolower(paste(corpus, collapse = " "))
    txt <- gsub("[[:punct:]]+", " ", txt)
    toks <- unlist(strsplit(txt, "\\s+"))
    toks <- trimws(toks)
    toks <- toks[nzchar(toks)]
    toks <- toks[nchar(toks) >= min_nchar]
    toks <- toks[!toks %in% stopwords_basic]

    if (length(toks) == 0) {
      out[[grp_name]] <- character(0)
      next
    }

    tab <- sort(table(toks), decreasing = TRUE)
    out[[grp_name]] <- names(utils::head(tab, top_n))
  }

  out
}

# ---------------------------------------------------------------------------
# Structured textual prep builders (V2)
# ---------------------------------------------------------------------------

build_request_textual_prep <- function(include_verbatims = TRUE) {
  base <- c(
    "Using only the texts below, produce a short structured summary of this group.",
    "",
    "The goal is not only to summarize the texts for themselves, but to prepare a later comparison between:",
    "- what this group expresses in its texts,",
    "- and how this group is characterized by external statistical descriptors.",
    "",
    "Interpretive rules:",
    "- Start from recurring themes before proposing a broader interpretation.",
    "- Treat individual phrases as illustrative evidence, not as standalone proof.",
    "- Treat recurring patterns as group-level textual evidence, not as properties shared by every individual.",
    "- Distinguish central themes from more secondary or marginal elements.",
    "- Distinguish demonstrated internal tensions from isolated contrastive or atypical contributions.",
    "- Report an internal tension only when it is supported by several elements of the corpus.",
    "- A minority, atypical, or less central contribution may still be reported as a contrastive cue, but it must not be presented as proof of an internal contradiction.",
    "- Do not infer hidden motives, unexpressed intentions, deep personality traits, or moral qualities.",
    "- Summarize reasons only when they are explicitly expressed in the texts.",
    "- Do not treat the absence of a theme as proof that the group does not care about it.",
    "- Stay close to the texts.",
    "- Use the exact output format below.",
    "",
    "Output format:",
    "Core textual profile:",
    "[One short sentence summarizing what mainly characterizes this group in the texts.]",
    "",
    "Main themes:",
    "[3 to 5 short themes separated by semicolons.]",
    "",
    "Dominant concerns or expressed reasons:",
    "[1 to 3 short phrases separated by semicolons. Include reasons only when they are explicitly expressed. If unclear, write: unclear]",
    "",
    "Tone or stance:",
    "[One short expression such as supportive / critical / ambivalent / pragmatic / engaged / hesitant / resigned / mixed]",
    "",
    "Intra-group consistency:",
    "[Choose exactly one: strong / moderate / mixed / weak, according to how consistently the main themes recur across the available texts.]",
    "",
    "Injectable summary:",
    "[One short sentence reusable later in a contextualized cross-group interpretation.]"
  )

  if (!include_verbatims) {
    return(paste(base, collapse = "\n"))
  }

  paste(
    c(
      base,
      "",
      "Central verbatim cues:",
      "[1 to 2 very short quoted excerpts or paraphrased cues separated by semicolons. Use them only as illustrative cues, not as proof.]",
      "",
      "Potential tension or contrastive verbatim cues:",
      "[0 to 2 very short quoted excerpts or paraphrased cues separated by semicolons. Retain a cue when the corpus contains a clearly minority, atypical, less central, or contrasting contribution. Describe it cautiously and do not treat it as proof of a contradiction. If no such contribution is identifiable, write: none]"
    ),
    collapse = "\n"
  )
}
build_conclusion_textual_prep <- function(include_verbatims = TRUE) {
  fields <- c(
    "Core textual profile:",
    "Main themes:",
    "Dominant concerns or expressed reasons:",
    "Tone or stance:",
    "Intra-group consistency:",
    "Injectable summary:"
  )

  if (include_verbatims) {
    fields <- c(
      fields,
      "Central verbatim cues:",
      "Potential tension or contrastive verbatim cues:"
    )
  }

  paste(
    c(
      "# Output constraint",
      "Your answer must contain exactly the following field labels and nothing else.",
      "Do not number the fields.",
      "Write each field label exactly as shown below:",
      fields
    ),
    collapse = "\n"
  )
}

# ---------------------------------------------------------------------------
# Structured textual prep parser (V2)
# ---------------------------------------------------------------------------

.extract_field_block_textual <- function(text, field, next_fields = NULL) {
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
        "\\s*:?"
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

  m <- regexec(pattern, text, perl = TRUE)
  regmatch <- regmatches(text, m)[[1]]

  if (length(regmatch) >= 2) {
    trimws(regmatch[2])
  } else {
    NA_character_
  }
}

.clean_field_textual <- function(x) {
  if (is.na(x) || !nzchar(trimws(x))) {
    return(NA_character_)
  }

  x <- trimws(x)
  x <- gsub("^[-*+]\\s*", "", x)
  x <- gsub("\\n+", " ", x)
  x <- gsub("[[:space:]]+", " ", x)
  trimws(x)
}

.split_field_textual <- function(x, none_words = NULL) {
  if (is.na(x) || !nzchar(trimws(x))) {
    return(character(0))
  }

  vals <- unlist(strsplit(x, ";|\\n", perl = TRUE))
  vals <- trimws(vals)
  vals <- vals[nzchar(vals)]
  vals <- gsub("^[-*+]\\s*", "", vals)
  vals <- gsub("^[[:punct:][:space:]]+", "", vals)
  vals <- gsub("[[:punct:][:space:]]+$", "", vals)
  vals <- trimws(vals)
  vals <- vals[nzchar(vals)]

  if (!is.null(none_words) && length(vals) == 1 &&
      tolower(vals) %in% tolower(none_words)) {
    return(character(0))
  }

  vals
}

parse_textual_prep_response <- function(text, include_verbatims = TRUE) {
  text <- paste(text, collapse = "\n")
  text <- gsub("\r\n", "\n", text, fixed = TRUE)
  text <- gsub("\r", "\n", text, fixed = TRUE)
  text <- .strip_markdown_fences(text)

  text <- gsub("(?im)^\\s*here is the output\\s*:?\\s*\\n?", "", text, perl = TRUE)
  text <- gsub("(?im)^\\s*output\\s*:?\\s*\\n?", "", text, perl = TRUE)

  # Backward compatibility with responses generated with former field names.
  text <- gsub(
    "(?im)^\\s*Dominant concerns or motives\\s*:",
    "Dominant concerns or expressed reasons:",
    text,
    perl = TRUE
  )

  text <- gsub(
    "(?im)^\\s*Tension verbatim cues\\s*:",
    "Potential tension or contrastive verbatim cues:",
    text,
    perl = TRUE
  )

  field_order <- c(
    "Core textual profile",
    "Main themes",
    "Dominant concerns or expressed reasons",
    "Tone or stance",
    "Intra-group consistency",
    "Injectable summary"
  )

  if (include_verbatims) {
    field_order <- c(
      field_order,
      "Central verbatim cues",
      "Potential tension or contrastive verbatim cues"
    )
  }

  get_block <- function(field) {
    idx <- match(field, field_order)
    next_fields <- if (idx < length(field_order)) {
      field_order[(idx + 1):length(field_order)]
    } else {
      NULL
    }

    .extract_field_block_textual(text, field, next_fields = next_fields)
  }

  core_textual_profile <- .clean_field_textual(get_block("Core textual profile"))
  main_themes_raw <- get_block("Main themes")
  dominant_concerns_raw <- get_block("Dominant concerns or expressed reasons")
  tone_or_stance_raw <- .clean_field_textual(get_block("Tone or stance"))
  intra_group_consistency_raw <- .clean_field_textual(get_block("Intra-group consistency"))
  injectable_summary <- .clean_field_textual(get_block("Injectable summary"))

  central_verbatim_cues_raw <- if (include_verbatims) {
    get_block("Central verbatim cues")
  } else {
    NA_character_
  }

  tension_verbatim_cues_raw <- if (include_verbatims) {
    get_block("Potential tension or contrastive verbatim cues")
  } else {
    NA_character_
  }

  main_themes <- .split_field_textual(main_themes_raw)
  dominant_concerns <- .split_field_textual(
    dominant_concerns_raw,
    none_words = c("unclear")
  )
  central_verbatim_cues <- .split_field_textual(central_verbatim_cues_raw)
  tension_verbatim_cues <- .split_field_textual(
    tension_verbatim_cues_raw,
    none_words = c("none")
  )
  tone_or_stance <- .split_field_textual(tone_or_stance_raw)

  normalize_consistency <- function(x) {
    if (is.na(x) || !nzchar(trimws(x))) return(NA_character_)
    x_low <- tolower(trimws(x))

    for (lab in c("strong", "moderate", "mixed", "weak")) {
      if (startsWith(x_low, lab)) return(lab)
    }

    # Fallback: first token before ";" or a line break.
    x_low <- strsplit(x_low, ";|\\n", perl = TRUE)[[1]][1]
    trimws(x_low)
  }

  intra_group_consistency <- normalize_consistency(intra_group_consistency_raw)

  list(
    core_textual_profile = core_textual_profile,
    main_themes = main_themes,
    dominant_concerns = dominant_concerns,
    tone_or_stance = tone_or_stance,
    intra_group_consistency = intra_group_consistency,
    intra_group_consistency_raw = intra_group_consistency_raw,
    injectable_summary = injectable_summary,
    central_verbatim_cues = central_verbatim_cues,
    tension_verbatim_cues = tension_verbatim_cues
  )
}

# ---------------------------------------------------------------------------
# Textual prep main
# ---------------------------------------------------------------------------

#' Prepare structured textual summaries for later contextualization
#'
#' Creates one short, structured textual summary for each level of a grouping
#' variable and optionally enriches these summaries with mechanically selected
#' verbatims and frequently occurring expressions.
#'
#' The function reuses [nail_textual()] in isolated mode, so the complete
#' textual analysis is performed separately for each group. When
#' `generate = TRUE`, one request is sent to the selected language model for
#' every group, and the generated response is parsed into a standardized set
#' of fields.
#'
#' The resulting summaries are designed for later use in
#' [nail_textual_contextualized()], where they may be combined with structured
#' statistical descriptions produced by [nail_group_profile_prep()].
#'
#' The function may also attach representative verbatims selected through a
#' deterministic lexical procedure. Verbatims identified as contrastive are
#' illustrative candidates only. They may reflect a minority position, an
#' atypical formulation, a less central contribution, or a possible internal
#' tension. They must not be treated as proof of a contradiction without
#' additional supporting evidence.
#'
#' @param dataset A data frame containing at least:
#'
#'   - one variable defining the groups;
#'   - one variable containing open-ended texts.
#'
#'   Rows generally correspond to respondents, observations, or individual
#'   textual contributions.
#'
#'   The grouping variable does not need to be a factor. It is converted
#'   internally when required.
#'
#'   The textual variable is converted to character. Missing values, empty
#'   strings, and strings containing only spaces are excluded.
#' @param num.var A single integer giving the column index of the grouping
#'   variable in `dataset`.
#'
#'   This argument expects a column position rather than a column name.
#'
#'   For example, use `num.var = 1` when the first column contains the group
#'   membership.
#' @param num.text A single integer giving the column index of the textual
#'   variable in `dataset`.
#'
#'   This argument expects a column position rather than a column name.
#'
#'   `num.var` and `num.text` must refer to two different columns.
#' @param model Character string giving the language model used by the selected
#'   provider. The default is `"llama3"`, intended for the default Ollama
#'   backend.
#' @param provider LLM backend used when `generate = TRUE`. One of
#'   `"ollama"` or `"gemini"`.
#'
#'   The default is `"ollama"`, which uses a locally running Ollama service.
#'
#'   Gemini requires a valid API key, typically supplied through the
#'   `GEMINI_API_KEY` environment variable.
#'
#'   This argument has no effect when `generate = FALSE`.
#' @param sample.pct A numeric value in the interval ]0, 1] giving the
#'   proportion of non-empty texts included in the LLM prompt for each group.
#'
#'   The default is `1`, meaning that all available non-empty texts are
#'   included.
#'
#'   When `sample.pct < 1`, sampling is carried out independently within each
#'   group. At least one text is retained for every non-empty group.
#'
#'   Sampling affects only the texts shown to the language model. It does not
#'   alter the original dataset.
#'
#'   The mechanically selected verbatims and notable expressions are extracted
#'   from the available group corpus rather than from the parsed LLM response
#'   alone.
#' @param seed An optional numeric seed used to make within-group text sampling
#'   reproducible when `sample.pct < 1`.
#'
#'   The user's random-number generator state is preserved. Supplying `seed`
#'   therefore does not alter the random sequence used by subsequent code in
#'   the R session.
#'
#'   This seed controls corpus sampling only. It is not a language-model
#'   generation parameter.
#' @param language Character string controlling the basic stopword list used
#'   when extracting `notable_expressions`. One of `"en"`, `"fr"`, or
#'   `"none"`.
#'
#'   Use:
#'
#'   - `"en"` for a basic English stopword list;
#'   - `"fr"` for a basic French stopword list;
#'   - `"none"` to disable this stopword removal.
#'
#'   This argument affects only the mechanical extraction of notable
#'   expressions. It does not translate the texts, detect their language, or
#'   control the language of the LLM response.
#' @param prompt_style Character string controlling the amount of guidance
#'   included in the prompt created by [nail_textual()]. One of `"detailed"`
#'   or `"compact"`.
#'
#'   The `"detailed"` style gives additional guidance about variability,
#'   partial evidence, and the limits of group-level generalization.
#'
#'   The `"compact"` style produces a shorter reading guide.
#'
#'   The dedicated structured output requested by
#'   `nail_textual_prep()` remains the same in both modes.
#' @param text_role Character string indicating how the textual units should be
#'   named in the prompt. One of `"responses"`, `"comments"`, or
#'   `"verbatims"`.
#'
#'   This argument changes only the terminology displayed in the prompt. It
#'   does not change text filtering, sampling, or parsing.
#' @param include_verbatims_in_prompt Logical indicating whether the language
#'   model should be asked to return short verbatim cues in addition to the
#'   structured textual summary. The default is `TRUE`.
#'
#'   If `TRUE`, the requested and parsed response includes:
#'
#'   - central verbatim cues;
#'   - potential tension or contrastive verbatim cues.
#'
#'   These cues are selected or paraphrased by the language model and should
#'   be treated as illustrative evidence.
#'
#'   If `FALSE`, these two fields are omitted from the requested LLM output.
#'
#'   This argument is independent of `attach_selected_verbatims`, which
#'   controls a separate mechanical selection procedure.
#' @param attach_selected_verbatims Logical indicating whether mechanically
#'   selected verbatims should be attached to each generated group result. The
#'   default is `TRUE`.
#'
#'   Mechanical selection is performed only after structured LLM summaries
#'   have been generated. Consequently, this argument has an observable effect
#'   only when `generate = TRUE`.
#'
#'   The attached object contains:
#'
#'   - `central`: verbatims selected as relatively representative of the main
#'     themes;
#'   - `tension`: lexically contrastive verbatims selected as possible minority,
#'     atypical, or less central contributions.
#'
#'   The name `tension` is an internal storage label. A selected text should
#'   not be interpreted as evidence of a genuine contradiction without
#'   examining the corpus.
#' @param n_central_verbatims A single non-negative integer giving the maximum
#'   number of mechanically selected central verbatims attached to each group.
#'
#'   The default is `2`.
#'
#'   Central verbatims are ranked using their overlap with keywords extracted
#'   from the structured textual summary and their proximity to the median text
#'   length of the group corpus.
#' @param n_tension_verbatims A single non-negative integer giving the maximum
#'   number of mechanically selected contrastive verbatims attached to each
#'   group.
#'
#'   The default is `1`.
#'
#'   These verbatims are selected among texts not already retained as central.
#'   The ranking favors contributions that are less aligned with the central
#'   keywords and lexically more distant from the selected central verbatims.
#'
#'   A contrastive verbatim may represent a potential tension, a minority
#'   position, an atypical formulation, or simply a less central contribution.
#' @param max_verbatim_chars A single positive integer giving the maximum
#'   number of characters retained for each mechanically selected verbatim.
#'
#'   Longer texts are truncated and completed with an ellipsis. The default is
#'   `220`.
#'
#'   This limit applies only to the verbatims attached in
#'   `selected_verbatims`. It does not truncate the raw texts inserted into the
#'   LLM prompt.
#' @param generate Logical.
#'
#'   If `FALSE`, no language model is called and the function returns one
#'   structured prompt per group.
#'
#'   If `TRUE`, one prompt is sent independently for each group. The function
#'   then returns the prompt, raw response, parsed response, mechanically
#'   selected verbatims, and notable expressions for every group.
#' @param ... Additional provider-specific generation arguments passed to the
#'   selected LLM backend, such as `temperature` or other supported options.
#'
#' @details
#' ## Relationship with `nail_textual()`
#'
#' `nail_textual_prep()` calls [nail_textual()] internally with:
#'
#' ```
#' isolate.groups = TRUE
#' ```
#'
#' One prompt is therefore constructed for every group. The prompt contains
#' only the texts associated with the current group.
#'
#' The function supplies a dedicated introduction, request, and conclusion to
#' obtain a stable structured response suitable for automatic parsing.
#'
#' The texts are nevertheless extracted and filtered through the same
#' machinery as in [nail_textual()].
#'
#' ## Purpose of the structured summaries
#'
#' The summaries are intended to capture what is expressed in the textual
#' corpus of each group before this information is combined with external
#' statistical descriptors.
#'
#' The prompt asks the language model to:
#'
#' - identify recurring themes;
#' - distinguish central themes from secondary or marginal elements;
#' - report expressed concerns or reasons without inferring hidden motives;
#' - describe the tone or stance visible in the texts;
#' - assess how consistently the main themes recur across the available
#'   corpus;
#' - produce a concise sentence that can later be reused in a contextualized
#'   interpretation.
#'
#' Individual phrases should be treated as illustrative contributions rather
#' than as standalone proof of a group-level property.
#'
#' The absence of a topic from the available corpus should not be interpreted
#' as evidence that the group rejects or does not care about that topic.
#'
#' ## Requested output structure
#'
#' With `generate = TRUE`, the language model is instructed to return the
#' following core fields:
#'
#' ```
#' Core textual profile: ...
#' Main themes: ...
#' Dominant concerns or expressed reasons: ...
#' Tone or stance: ...
#' Intra-group consistency: ...
#' Injectable summary: ...
#' ```
#'
#' When `include_verbatims_in_prompt = TRUE`, two additional fields are
#' requested:
#'
#' ```
#' Central verbatim cues: ...
#' Potential tension or contrastive verbatim cues: ...
#' ```
#'
#' The intended meanings are:
#'
#' - `Core textual profile`: one sentence summarizing what mainly characterizes
#'   the group in the texts;
#' - `Main themes`: three to five recurring themes;
#' - `Dominant concerns or expressed reasons`: concerns or reasons explicitly
#'   supported by the corpus;
#' - `Tone or stance`: a concise characterization of the expressed stance,
#'   such as supportive, critical, ambivalent, pragmatic, engaged, hesitant,
#'   resigned, or mixed;
#' - `Intra-group consistency`: the degree to which the principal themes recur
#'   consistently across the available texts;
#' - `Injectable summary`: one sentence designed for later reuse;
#' - `Central verbatim cues`: short illustrative excerpts or paraphrased cues
#'   representing central themes;
#' - `Potential tension or contrastive verbatim cues`: excerpts or cues that
#'   may illustrate a minority, atypical, less central, or potentially
#'   contrasting position.
#'
#' ## Parsing the LLM response
#'
#' The raw LLM response is parsed automatically into a named list.
#'
#' The parsed component contains:
#'
#' - `core_textual_profile`: a character string or `NA`;
#' - `main_themes`: a character vector;
#' - `dominant_concerns`: a character vector;
#' - `tone_or_stance`: a character vector;
#' - `intra_group_consistency`: a normalized lower-case label;
#' - `intra_group_consistency_raw`: the complete text originally returned for
#'   this field;
#' - `injectable_summary`: a character string or `NA`;
#' - `central_verbatim_cues`: a character vector;
#' - `tension_verbatim_cues`: a character vector.
#'
#' Semicolon-separated fields are split into character vectors. Common
#' Markdown wrappers and introductory formulations are removed before field
#' extraction.
#'
#' If a response cannot be parsed, the complete multi-group workflow is not
#' interrupted. The affected group receives missing scalar fields and empty
#' character vectors where appropriate.
#'
#' Users should inspect both `response` and `parsed` before reusing a generated
#' summary.
#'
#' ## Mechanically selected verbatims
#'
#' When `attach_selected_verbatims = TRUE`, the function performs an additional
#' deterministic selection from the group corpus.
#'
#' The procedure:
#'
#' 1. removes empty texts;
#' 2. removes duplicate texts after basic normalization;
#' 3. excludes very short contributions;
#' 4. extracts keywords from the parsed textual summary;
#' 5. ranks possible central verbatims using keyword overlap and text length;
#' 6. ranks possible contrastive verbatims using lower keyword overlap and
#'    lexical distance from the central set;
#' 7. truncates the selected texts according to `max_verbatim_chars`.
#'
#' This is a lexical heuristic rather than a semantic or statistical proof of
#' representativeness.
#'
#' A central verbatim is not necessarily shared by most members of the group.
#' Similarly, a contrastive verbatim does not by itself demonstrate an
#' internal contradiction.
#'
#' ## LLM verbatim cues and mechanical verbatims
#'
#' Two different sources of verbatims may be present in the result:
#'
#' - `parsed$central_verbatim_cues` and
#'   `parsed$tension_verbatim_cues` are generated or paraphrased by the
#'   language model;
#' - `selected_verbatims$central` and `selected_verbatims$tension` are selected
#'   mechanically from the original corpus.
#'
#' These sources should not be confused. Mechanically selected verbatims are
#' taken directly from the available texts, whereas LLM cues may be shortened
#' or paraphrased interpretations.
#'
#' ## Notable expressions
#'
#' For each group, the function also extracts a small set of frequently
#' occurring lexical items.
#'
#' The extraction:
#'
#' - converts the corpus to lower case;
#' - removes punctuation;
#' - splits the corpus into individual tokens;
#' - excludes very short tokens;
#' - optionally removes a basic English or French stopword list;
#' - returns the most frequent remaining terms.
#'
#' These `notable_expressions` are simple frequency-based indicators. They are
#' not necessarily complete themes, phrases, concepts, or statistically
#' distinctive words.
#'
#' ## Sampling considerations
#'
#' When `sample.pct < 1`, only the sampled texts are shown to the language
#' model. Consequently, the parsed textual summary reflects the sampled
#' corpus.
#'
#' A small sample may omit minority positions, uncommon themes, or internal
#' diversity. Reproducible sampling can be obtained with `seed`.
#'
#' The `"textual_data_summary"` attribute inherited from [nail_textual()] is
#' calculated from the complete non-empty corpus before sampling.
#'
#' ## Use in contextualized interpretation
#'
#' A result produced with `generate = TRUE` can be passed directly to
#' [nail_textual_contextualized()]:
#'
#' ```
#' textual_prep <- nail_textual_prep(..., generate = TRUE)
#'
#' contextualized <- nail_textual_contextualized(
#'   group_profile_prep = group_profile_prep,
#'   textual_prep = textual_prep
#' )
#' ```
#'
#' In that workflow, the parsed textual profile is combined with a structured
#' statistical group profile. The two sources should be articulated without
#' forcing agreement between them.
#'
#' ## Generation and confidentiality
#'
#' With `generate = TRUE`, the sampled raw texts are included in the request
#' sent to the selected provider.
#'
#' Users should review the corpus before generation when it contains personal,
#' confidential, sensitive, or identifying information.
#'
#' The generated summaries should be treated as assisted qualitative
#' syntheses. They do not replace examination of the original corpus,
#' systematic qualitative coding, or formal textual analyses when these are
#' required.
#'
#' @return
#' The returned object depends on `generate`.
#'
#' When `generate = FALSE`, a named list of character prompts is returned, with
#' one element per group.
#'
#' The names correspond to the levels of the grouping variable. The
#' `"textual_data_summary"` attribute inherited from [nail_textual()] contains
#' a summary of the complete non-empty corpus for each group.
#'
#' When `generate = TRUE`, a named list is returned, with one element per
#' group. Each element contains:
#'
#' - `prompt`: the exact prompt sent to the selected LLM backend;
#' - `response`: the unmodified generated response stored as one character
#'   string;
#' - `parsed`: the structured fields extracted from the generated response;
#' - `selected_verbatims`: mechanically selected central and contrastive
#'   verbatims;
#' - `notable_expressions`: frequently occurring lexical items extracted from
#'   the group corpus.
#'
#' The `selected_verbatims` component contains:
#'
#' - `central`;
#' - `tension`.
#'
#' The `parsed` component contains:
#'
#' - `core_textual_profile`;
#' - `main_themes`;
#' - `dominant_concerns`;
#' - `tone_or_stance`;
#' - `intra_group_consistency`;
#' - `intra_group_consistency_raw`;
#' - `injectable_summary`;
#' - `central_verbatim_cues`;
#' - `tension_verbatim_cues`.
#'
#' The `"textual_data_summary"` attribute is attached to the complete returned
#' list.
#'
#' @seealso
#' [nail_textual()], [nail_group_profile_prep()],
#' [nail_textual_contextualized()]
#'
#' @export
#'
#' @examples
#' # Small reproducible example without an LLM.
#' textual_example <- data.frame(
#'   group = factor(c(
#'     "Local orientation", "Local orientation",
#'     "Local orientation", "Local orientation",
#'     "Convenience orientation", "Convenience orientation",
#'     "Convenience orientation", "Convenience orientation"
#'   )),
#'   response = c(
#'     "I prefer buying at the market because I know where the products come from.",
#'     "Local producers and seasonal foods are important in my daily choices.",
#'     "I often visit nearby farms and value direct contact with producers.",
#'     "I try to reduce supermarket purchases and support small local shops.",
#'     "I mainly need shopping to be fast and easy after work.",
#'     "The supermarket is practical because everything is available in one place.",
#'     "Price, opening hours, and convenience matter most in my routine.",
#'     "I often use the drive service because it saves time."
#'   ),
#'   stringsAsFactors = FALSE
#' )
#'
#' # Construct one structured prompt per group without calling an LLM.
#' prep_prompts <- nail_textual_prep(
#'   dataset = textual_example,
#'   num.var = 1,
#'   num.text = 2,
#'   sample.pct = 1,
#'   prompt_style = "detailed",
#'   text_role = "responses",
#'   include_verbatims_in_prompt = TRUE,
#'   generate = FALSE
#' )
#'
#' # Inspect the available groups.
#' names(prep_prompts)
#'
#' # Display the complete structured prompt for one group.
#' cat(prep_prompts[["Local orientation"]])
#'
#' # Inspect the summary of the complete group corpus.
#' attr(prep_prompts, "textual_data_summary")
#'
#'
#' \dontrun{
#' # The following examples call a language model.
#' # Processing time may therefore exceed ten seconds.
#'
#' library(NaileR)
#'
#'
#' ### Example 1: structured summaries of a mobility survey ###
#'
#' data("car_alone", package = "NaileR")
#'
#' # One LLM request is sent for each group.
#' textual_car <- nail_textual_prep(
#'   dataset = car_alone,
#'   num.var = 1,
#'   num.text = 2,
#'   model = "llama3",
#'   provider = "ollama",
#'   sample.pct = 0.5,
#'   seed = 123,
#'   language = "en",
#'   prompt_style = "detailed",
#'   text_role = "responses",
#'   include_verbatims_in_prompt = TRUE,
#'   attach_selected_verbatims = TRUE,
#'   n_central_verbatims = 2,
#'   n_tension_verbatims = 1,
#'   generate = TRUE
#' )
#'
#' # Display the groups for which summaries were produced.
#' names(textual_car)
#'
#' # Inspect the exact prompt and the raw response for the first group.
#' cat(textual_car[[1]]$prompt)
#' cat(textual_car[[1]]$response)
#'
#' # Inspect the structured fields extracted from the response.
#' textual_car[[1]]$parsed
#'
#' # Inspect the mechanically selected verbatims.
#' textual_car[[1]]$selected_verbatims
#'
#' # Inspect the frequent lexical items retained for the group.
#' textual_car[[1]]$notable_expressions
#'
#'
#' ### Example 2: inspect parsing quality across groups ###
#'
#' # Extract the core textual profile of every group.
#' vapply(
#'   textual_car,
#'   function(x) {
#'     value <- x$parsed$core_textual_profile
#'     if (is.na(value)) "" else value
#'   },
#'   character(1)
#' )
#'
#' # Extract the normalized intra-group consistency labels.
#' vapply(
#'   textual_car,
#'   function(x) {
#'     value <- x$parsed$intra_group_consistency
#'     if (is.na(value)) "" else value
#'   },
#'   character(1)
#' )
#'
#' # Identify groups whose injectable summary could not be parsed.
#' missing_summaries <- vapply(
#'   textual_car,
#'   function(x) {
#'     value <- x$parsed$injectable_summary
#'     is.na(value) || !nzchar(trimws(value))
#'   },
#'   logical(1)
#' )
#'
#' names(textual_car)[missing_summaries]
#'
#'
#' ### Example 3: atomic-habits survey ###
#'
#' data("atomic_habit_clust", package = "NaileR")
#'
#' dta_plane <- atomic_habit_clust[, c(32, 51), drop = FALSE]
#'
#' plane_text <- trimws(as.character(dta_plane$never_plane_text))
#'
#' keep_plane <- !is.na(plane_text) &
#'   nzchar(plane_text) &
#'   plane_text != "THAT"
#'
#' dta_plane <- droplevels(
#'   dta_plane[keep_plane, , drop = FALSE]
#' )
#'
#' textual_plane <- nail_textual_prep(
#'   dataset = dta_plane,
#'   num.var = 2,
#'   num.text = 1,
#'   model = "llama3",
#'   provider = "ollama",
#'   sample.pct = 0.75,
#'   seed = 123,
#'   language = "en",
#'   prompt_style = "detailed",
#'   text_role = "responses",
#'   include_verbatims_in_prompt = TRUE,
#'   attach_selected_verbatims = TRUE,
#'   generate = TRUE
#' )
#'
#' # Compare the parsed themes across clusters.
#' lapply(
#'   textual_plane,
#'   function(x) x$parsed$main_themes
#' )
#'
#' # Compare mechanically selected contrastive verbatims.
#' lapply(
#'   textual_plane,
#'   function(x) x$selected_verbatims$tension
#' )
#'
#'
#' ### Example 4: prepare summaries without LLM verbatim cues ###
#'
#' # The LLM is not asked to provide verbatim cues, but the function
#' # still attaches mechanically selected verbatims.
#' textual_car_mechanical_only <- nail_textual_prep(
#'   dataset = car_alone,
#'   num.var = 1,
#'   num.text = 2,
#'   model = "llama3",
#'   provider = "ollama",
#'   sample.pct = 0.5,
#'   seed = 123,
#'   language = "en",
#'   include_verbatims_in_prompt = FALSE,
#'   attach_selected_verbatims = TRUE,
#'   generate = TRUE
#' )
#'
#' textual_car_mechanical_only[[1]]$parsed$central_verbatim_cues
#' textual_car_mechanical_only[[1]]$selected_verbatims$central
#' }
nail_textual_prep <- function(dataset, num.var, num.text,
                              model = "llama3",
                              provider = c("ollama", "gemini"),
                              sample.pct = 1,
                              seed = NULL,
                              language = c("en", "fr", "none"),
                              prompt_style = c("detailed", "compact"),
                              text_role = c("responses", "comments", "verbatims"),
                              include_verbatims_in_prompt = TRUE,
                              attach_selected_verbatims = TRUE,
                              n_central_verbatims = 2,
                              n_tension_verbatims = 1,
                              max_verbatim_chars = 220,
                              generate = FALSE,
                              ...) {
  prompt_style <- match.arg(prompt_style)
  text_role <- match.arg(text_role)
  language <- match.arg(language)
  provider <- match.arg(provider)

  if (!is.logical(include_verbatims_in_prompt) ||
      length(include_verbatims_in_prompt) != 1 ||
      is.na(include_verbatims_in_prompt)) {
    stop("`include_verbatims_in_prompt` must be a single non-missing logical value.", call. = FALSE)
  }

  if (!is.logical(attach_selected_verbatims) ||
      length(attach_selected_verbatims) != 1 ||
      is.na(attach_selected_verbatims)) {
    stop("`attach_selected_verbatims` must be a single non-missing logical value.", call. = FALSE)
  }

  for (arg_name in c("n_central_verbatims", "n_tension_verbatims")) {
    value <- get(arg_name, inherits = FALSE)
    if (!is.numeric(value) || length(value) != 1 || is.na(value) ||
        !is.finite(value) || value != floor(value) || value < 0) {
      stop(sprintf("`%s` must be a single non-negative integer.", arg_name), call. = FALSE)
    }
  }

  if (!is.numeric(max_verbatim_chars) || length(max_verbatim_chars) != 1 ||
      is.na(max_verbatim_chars) || !is.finite(max_verbatim_chars) ||
      max_verbatim_chars != floor(max_verbatim_chars) ||
      max_verbatim_chars < 4) {
    stop("`max_verbatim_chars` must be a single integer >= 4.", call. = FALSE)
  }

  intro <- paste(
    "The texts below come from one specific group.",
    "The goal is to summarize this group's textual profile in a short structured format that can later be reused in a broader contextualized interpretation."
  )

  req <- build_request_textual_prep(include_verbatims = include_verbatims_in_prompt)
  concl <- build_conclusion_textual_prep(include_verbatims = include_verbatims_in_prompt)

  prompts_or_results <- nail_textual(
    dataset = dataset,
    num.var = num.var,
    num.text = num.text,
    introduction = intro,
    request = req,
    conclusion = concl,
    model = model,
    provider = provider,
    isolate.groups = TRUE,
    sample.pct = sample.pct,
    seed = seed,
    prompt_style = prompt_style,
    text_role = text_role,
    generate = generate,
    ...
  )

  if (!generate) {
    return(prompts_or_results)
  }

  parsed_only <- lapply(prompts_or_results, function(x) {
    response_text <- paste(x$response, collapse = "\n")

    tryCatch(
      parse_textual_prep_response(
        response_text,
        include_verbatims = include_verbatims_in_prompt
      ),
      error = function(e) {
        list(
          core_textual_profile = NA_character_,
          main_themes = character(0),
          dominant_concerns = character(0),
          tone_or_stance = character(0),
          intra_group_consistency = NA_character_,
          intra_group_consistency_raw = NA_character_,
          injectable_summary = NA_character_,
          central_verbatim_cues = character(0),
          tension_verbatim_cues = character(0)
        )
      }
    )
  })
  names(parsed_only) <- names(prompts_or_results)

  selected_verbatims <- if (attach_selected_verbatims) {
    .select_representative_verbatims_textprep(
      dataset = dataset,
      num.var = num.var,
      num.text = num.text,
      textual_summary = parsed_only,
      n_central = n_central_verbatims,
      n_tension = n_tension_verbatims,
      max_chars = max_verbatim_chars
    )
  } else {
    stats::setNames(vector("list", length(parsed_only)), names(parsed_only))
  }

  notable_expressions <- .extract_notable_expressions_textprep(
    dataset = dataset,
    num.var = num.var,
    num.text = num.text,
    top_n = 5,
    language = language
  )

  out <- lapply(names(prompts_or_results), function(grp_name) {
    x <- prompts_or_results[[grp_name]]
    response_text <- paste(x$response, collapse = "\n")

    list(
      prompt = x$prompt,
      response = response_text,
      parsed = parsed_only[[grp_name]],
      selected_verbatims = selected_verbatims[[grp_name]],
      notable_expressions = notable_expressions[[grp_name]]
    )
  })

  names(out) <- names(prompts_or_results)
  attr(out, "textual_data_summary") <- attr(prompts_or_results, "textual_data_summary", exact = TRUE)
  out
}
