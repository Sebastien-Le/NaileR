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

.extract_nonempty_texts <- function(x) {
  x <- as.character(x)
  x[is.na(x)] <- ""
  x <- trimws(x)
  x[nzchar(x)]
}

.sample_group_corpus <- function(corpus, sample.pct = 1) {
  if (length(corpus) == 0) return(character(0))
  if (sample.pct >= 1) return(corpus)

  sample_size <- max(1, round(length(corpus) * sample.pct))
  sample(corpus, size = sample_size)
}

.summarize_textual_groups <- function(dataset, num.var, num.text) {
  var_name <- colnames(dataset)[num.var]
  text_name <- colnames(dataset)[num.text]

  grp <- droplevels(as.factor(dataset[[var_name]]))
  split_data <- split(dataset, grp, drop = TRUE)
  out <- list()

  for (grp_name in names(split_data)) {
    df_grp <- split_data[[grp_name]]
    corpus <- .extract_nonempty_texts(df_grp[[text_name]])

    lengths <- if (length(corpus) > 0) nchar(corpus) else numeric(0)

    out[[grp_name]] <- list(
      n_texts = length(corpus),
      median_length = if (length(lengths) > 0) {
        stats::median(lengths)
      } else {
        NA_real_
      },
      max_length = if (length(lengths) > 0) {
        max(lengths)
      } else {
        NA_real_
      },
      min_length = if (length(lengths) > 0) {
        min(lengths)
      } else {
        NA_real_
      }
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

  grp <- droplevels(as.factor(dataset[[var_name]]))
  grouped_data <- split(dataset, grp, drop = TRUE)

  .with_preserved_seed(seed, {
    ppts <- list()

    for (grp_name in names(grouped_data)) {
      group_df <- grouped_data[[grp_name]]
      corpus <- .extract_nonempty_texts(group_df[[text_name]])

      # Do not construct or send a prompt for a group with no usable text.
      if (length(corpus) == 0) {
        next
      }

      total_responses <- length(corpus)
      corpus_sampled <- .sample_group_corpus(
        corpus,
        sample.pct = sample.pct
      )

      header <- if (sample.pct < 1) {
        glue::glue(
          "Showing a sample of **{length(corpus_sampled)}** out of **{total_responses}** total {text_role} for this group:"
        )
      } else {
        glue::glue(
          "Showing all **{total_responses}** {text_role} for this group:"
        )
      }

      corpus_md <- glue::glue_collapse(
        glue::glue("* {corpus_sampled}"),
        sep = "\n"
      )

      ppts[[grp_name]] <- paste(header, corpus_md, sep = "\n\n")
    }

    ppts
  })
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
#'   selected LLM backend, such as `temperature` or other supported options.
#'
#'   The `seed` argument of `nail_textual()` controls only the sampling of
#'   texts.
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
