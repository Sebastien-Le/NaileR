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
      num.var < 1 || num.var > ncol(dataset)) {
    stop("`num.var` must be a single valid column index.", call. = FALSE)
  }

  if (!is.numeric(num.text) || length(num.text) != 1 || is.na(num.text) ||
      num.text < 1 || num.text > ncol(dataset)) {
    stop("`num.text` must be a single valid column index.", call. = FALSE)
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
        "Then propose a short name for each group.",
        sep = "\n"
      ))
    }

    return(paste(
      "Using only the raw texts below, describe what characterizes each group and what differentiates the groups from one another.",
      "Identify the dominant themes, recurring ideas, and any notable contrasts between groups.",
      "Then propose a short descriptive name for each group.",
      "If a group is weakly documented or internally heterogeneous, say so explicitly.",
      sep = "\n"
    ))
  }

  if (prompt_style == "compact") {
    return(paste(
      "Using only the raw texts below, describe what characterizes this group.",
      "Then propose a short descriptive name for the group.",
      sep = "\n"
    ))
  }

  paste(
    "Using only the raw texts below, describe what characterizes this group.",
    "Identify the dominant themes, recurring ideas, tone, and any notable internal diversity.",
    "Then propose a short descriptive name for the group.",
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
      "3. **A list of the group names you assigned**.",
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
    "2. **A group name you assigned**.",
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
      ppts[[grp_name]] <- "This group has **no textual responses** to display."
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

#' Analyze open-ended responses across groups
#'
#' Use `nail_textual()` to explore what people say in open-ended responses or
#' comments. The function registers the raw responses with stable text IDs,
#' group-level coverage and volume metrics, selects the texts shown to the
#' language model, and either interprets each group independently or builds one
#' comparative interpretation across all groups. The textual evidence is built
#' mechanically in R; the LLM supplies the structured substantive profile and
#' does not alter the registered evidence.
#'
#' @param dataset A data frame containing at least one grouping variable
#'   and one textual variable.
#' @param num.var Index of the grouping variable.
#' @param num.text Index of the textual variable.
#' @param introduction Study context included in every active LLM prompt.
#'   A generic default is used when `NULL`.
#' @param request Analytical request included in every active LLM prompt.
#'   A generic textual-profiling request is used when `NULL`.
#' @param conclusion Output instruction appended to every active LLM prompt.
#'   When `NULL`, NaileR requests the canonical structured textual profile.
#'   A custom value is preserved for backward compatibility; if its output
#'   format is incompatible with the canonical parser, `textual_profiles`
#'   may report `status = "parse_failed"` while preserving the raw response.
#' @param model Model name for the selected provider. When omitted, the
#'   validated provider default is used: `"llama3"` for Ollama and
#'   `"gemini-2.5-flash"` for Gemini. An explicit model is always respected.
#' @param provider LLM backend to use for generation. Use `"ollama"` for a
#'   local Ollama model or `"gemini"` for Google Gemini via `GEMINI_API_KEY`.
#' @param isolate.groups Logical. If `TRUE` (the default), interpret each
#'   group independently with one prompt and one response per group. If
#'   `FALSE`, build one comparative prompt containing the selected texts from
#'   all groups and make one LLM call for the joint interpretation. The joint
#'   mode is not a concatenation of local responses and does not create local
#'   profiles from a comparative response.
#' @param sample.pct Proportion of non-empty texts shown to the LLM within
#'   each group. This affects only `interpretation_input`; the complete
#'   `textual_evidence` object is invariant to this option.
#' @param seed Optional seed used to sample texts reproducibly without
#'   altering the user's RNG state.
#' @param prompt_style Either `"detailed"` (default) or `"compact"`; this
#'   changes the reading and interpretation instructions without changing the
#'   registered texts or selected text IDs.
#' @param text_role Either `"responses"` (default), `"comments"`, or
#'   `"verbatims"`; this changes the terminology used in the prompt.
#' @param default_blocks Character vector selecting optional NaileR prompt
#'   blocks. Allowed values are `"reading"`, `"interpretation"`, and
#'   `"local_task"`; the default includes all three. Context, question,
#'   evidence, and output are always retained.
#' @param generate Logical. If `FALSE`, return prompt(s) only. If `TRUE`,
#'   generate one independent response per group in isolated mode, or one
#'   comparative response in joint mode.
#' @param ... Additional provider-specific generation arguments passed to the
#'   selected LLM backend. Unknown or provider-incompatible options are
#'   rejected before a preview or generation; no option is silently discarded.
#'
#' @details
#' `textual_evidence` is produced mechanically from the complete dataset before
#' any sampling or LLM call. It contains an exact text registry with stable text
#' IDs plus group-level coverage and volume metrics.
#'
#' `interpretation_input` records the exact subset of text IDs shown to the LLM
#' and its interpretation coverage. Sampling never changes `textual_evidence`.
#'
#' With the default output instruction, each local LLM response is parsed into
#' `textual_profiles`, which contains the core textual profile, dominant themes,
#' within-group coherence (`strong`, `moderate`, `mixed`, or `weak`), internal
#' diversity, and IDs of representative or tension texts. In joint mode the
#' object contains one `joint` comparative profile and an explicit
#' `scope = "joint"`; it does not fabricate one profile per group. Referenced
#' IDs must exist in the subset actually shown to the LLM.
#'
#' Every successful return carries `textual_evidence`, `interpretation_input`,
#' `textual_prompt_blocks`, `local_prompts`, `textual_profiles`, `textual_settings`,
#' `textual_data_summary` (historical compatibility view), and canonical
#' `llm_io` attributes.
#'
#' @return When `generate = FALSE`, the single comparative prompt when
#'   `isolate.groups = FALSE`, or the exact named local prompts when
#'   `isolate.groups = TRUE`. When `generate = TRUE`, a single backend result
#'   and comparative profile when `isolate.groups = FALSE`, or named local
#'   backend results and profiles when `isolate.groups = TRUE`.
#'   Mechanical and semantic artifacts are attached as attributes, not as `$`
#'   fields:
#'
#'   * `textual_evidence`: the complete registered text evidence;
#'   * `interpretation_input`: the exact text IDs shown to each group;
#'   * `textual_prompt_blocks` and `local_prompts`: rendered prompt structure;
#'   * `textual_profiles`: parsed local profiles, or one explicit comparative
#'     profile in joint mode;
#'   * `textual_settings`: execution and architecture settings;
#'   * `textual_data_summary`: the historical compatibility view;
#'   * `llm_io`: exact local prompts and raw local responses.
#'
#'   A preview has no LLM responses. Use [nail_evidence()] and [nail_prompt()]
#'   to inspect a preview, and [nail_response()] after generation. In joint
#'   mode, the active prompt and response are available under the selector
#'   `"portfolio"` through the canonical accessors.
#'
#' @seealso [nail_textual_prep()], [nail_catdes_textual()],
#'   [nail_textual_contextualized()], [nail_evidence()], [nail_prompt()],
#'   [nail_response()]
#'
#' @export
#' @examples
#' ## 1. Fabric: inspect comments for one fabric category
#' # Question: what do respondents say about fabric category A?
#' data(fabric, package = "NaileR")
#' fabric_A <- fabric[fabric$Fabric == "A", , drop = FALSE]
#' fabric_introduction <- paste(
#'   "This dataset contains short comments about fabric category A.",
#'   "Class is the grouping variable; the comments are textual responses",
#'   "and are not quantitative measurements."
#' )
#' fabric_request <- paste(
#'   "Describe recurring points in the comments within each Class group for",
#'   "fabric category A. Preserve variation between respondents and do not",
#'   "infer causes or behaviour."
#' )
#'
#' textual_preview <- nail_textual(
#'   dataset = fabric_A,
#'   num.var = 4,
#'   num.text = 3,
#'   introduction = fabric_introduction,
#'   request = fabric_request,
#'   isolate.groups = TRUE,
#'   sample.pct = 1,
#'   seed = 123,
#'   text_role = "responses",
#'   generate = FALSE
#' )
#'
#' textual_evidence <- nail_evidence(textual_preview)
#' textual_prompts <- nail_prompt(textual_preview, print = FALSE)
#' textual_evidence
#' textual_prompts
#'
#' # The evidence keeps the registered text IDs and source rows. The prompts
#' # use the selected comments; they do not turn comments into measurements.
#'
#' ## 2. Fabric: compare comments across Class categories
#' fabric_joint_introduction <- paste(
#'   "This dataset contains short comments about ten fabric types.",
#'   "Class is the grouping variable with two categories, 0 and 1."
#' )
#' fabric_joint_request <- paste(
#'   "Compare the comments associated with Class 0 and Class 1.",
#'   "Which similarities and differences appear in these two groups?",
#'   "Do not infer causes or behaviour from the comments."
#' )
#' textual_joint <- nail_textual(
#'   dataset = fabric,
#'   num.var = 4,
#'   num.text = 3,
#'   introduction = fabric_joint_introduction,
#'   request = fabric_joint_request,
#'   isolate.groups = FALSE,
#'   sample.pct = 1,
#'   seed = 123,
#'   text_role = "responses",
#'   generate = FALSE
#' )
#' nail_evidence(textual_joint)
#' nail_prompt(textual_joint, print = FALSE)
#' # The joint option summarizes the same selected comments in one prompt.
#'
#' ## 3. Car Alone: perceived benefits and constraints of individual car use.
#' data(car_alone, package = "NaileR")
#' car_alone_preview <- nail_textual(
#'   dataset = car_alone,
#'   num.var = 1,
#'   num.text = 2,
#'   introduction = paste(
#'     "This survey records perceived benefits and constraints of using a car alone.",
#'     "The four groups combine declared car use with whether sharing is perceived as restrictive."
#'   ),
#'   request = paste(
#'     "Summarize what respondents literally express about the benefits and constraints",
#'     "of car use, preserving differences between the four groups without inferring behaviour."
#'   ),
#'   isolate.groups = TRUE,
#'   sample.pct = 0.5,
#'   seed = 20261027,
#'   text_role = "comments",
#'   generate = FALSE
#' )
#' nail_evidence(car_alone_preview)
#' nail_prompt(car_alone_preview, select = "I take my car alone, and sharing it is for me restrictive",
#'             print = FALSE)
#'
#' # Atomic Habits: responses about giving up air travel and three constructed groups.
#' data(atomic_habit_clust, package = "NaileR")
#' atomic_plane <- atomic_habit_clust[
#'   !is.na(atomic_habit_clust$never_plane_text) &
#'     atomic_habit_clust$never_plane_text != "THAT",
#'   c(32, 51),
#'   drop = FALSE
#' ]
#' atomic_preview <- nail_textual(
#'   dataset = atomic_plane,
#'   num.var = 2,
#'   num.text = 1,
#'   introduction = paste(
#'     "The survey asks respondents what benefits and constraints they associate",
#'     "with giving up air travel. The historical value 'THAT' is excluded because",
#'     "it is not a textual response."
#'   ),
#'   request = paste(
#'     "Describe the distinct ways in which the three constructed groups discuss",
#'     "reducing air travel. Keep perceived capacity distinct from felt constraint."
#'   ),
#'   isolate.groups = TRUE,
#'   text_role = "responses",
#'   generate = FALSE
#' )
#' nail_evidence(atomic_preview)
#' nail_prompt(atomic_preview, select = "1", print = FALSE)
#'
#' # Rorschach: ten local prompts for the ten inkblots in panel A.
#' data(rorschach, package = "NaileR")
#' rorschach_A <- droplevels(rorschach[rorschach$Panel == "A", , drop = FALSE])
#' rorschach_preview <- nail_textual(
#'   dataset = rorschach_A,
#'   num.var = 2,
#'   num.text = 5,
#'   introduction = paste(
#'     "Participants described ten Rorschach inkblots in panel A.",
#'     "The prompts summarize the recorded descriptions without treating them as diagnoses."
#'   ),
#'   request = paste(
#'     "Describe recurring perceptions associated with each inkblot, preserving",
#'     "variation and avoiding psychological or causal claims."
#'   ),
#'   isolate.groups = TRUE,
#'   text_role = "responses",
#'   generate = FALSE
#' )
#' nail_evidence(rorschach_preview)
#' length(nail_prompt(rorschach_preview, print = FALSE))
#'
#' # Distinction: one global profile from 1,225 translated comments on food quality.
#' data(distinction, package = "NaileR")
#' distinction_text <- data.frame(
#'   respondent_scope = factor("All respondents"),
#'   quality_food_open = distinction$quality_food_open,
#'   check.names = FALSE
#' )
#' distinction_preview <- nail_textual(
#'   dataset = distinction_text,
#'   num.var = 1,
#'   num.text = 2,
#'   introduction = paste(
#'     "This survey includes one open question about what respondents mean by",
#'     "food quality. The English comments are translations of the original survey",
#'     "responses and are analysed as textual material, not as quantitative scores."
#'   ),
#'   request = paste(
#'     "Describe the diversity of representations of food quality in the complete",
#'     "corpus. Preserve tensions and minority views, and do not treat a sampled",
#'     "preview as an exhaustive account."
#'   ),
#'   isolate.groups = FALSE,
#'   sample.pct = 1,
#'   seed = 20261027,
#'   text_role = "comments",
#'   generate = FALSE
#' )
#' nail_evidence(distinction_preview)
#' cat(substr(nail_prompt(distinction_preview, print = FALSE), 1, 600), "\n")
#'
#' # Distinction: a reproducible comparative preview across education categories.
#' distinction_education_preview <- nail_textual(
#'   dataset = distinction,
#'   num.var = 4,
#'   num.text = 105,
#'   introduction = paste(
#'     "The same food-quality question is compared descriptively across the",
#'     "six observed education categories in the survey."
#'   ),
#'   request = paste(
#'     "Summarize how the food-quality representations expressed in the comments",
#'     "vary across education categories. Do not infer education effects or causality."
#'   ),
#'   isolate.groups = FALSE,
#'   sample.pct = 0.1,
#'   seed = 20261027,
#'   text_role = "comments",
#'   generate = FALSE
#' )
#' nail_evidence(distinction_education_preview)
#' cat(substr(
#'   nail_prompt(distinction_education_preview, print = FALSE),
#'   1,
#'   600
#' ), "\n")
#'
#' # Optional Gemini generation: one local request per Fabric group.
#' # This opt-in block requires a user-managed GEMINI_API_KEY and may make
#' # multiple external requests. A parsed profile is not scientific validation.
#' \dontrun{
#' fabric_gemini <- nail_textual(
#'   dataset = fabric_A,
#'   num.var = 4,
#'   num.text = 3,
#'   isolate.groups = TRUE,
#'   sample.pct = 1,
#'   seed = 123,
#'   text_role = "responses",
#'   provider = "gemini",
#'   model = "gemini-2.5-flash",
#'   generate = TRUE
#' )
#' nail_evidence(fabric_gemini)
#' fabric_group <- names(nail_evidence(fabric_gemini)$groups)[[1L]]
#' nail_prompt(fabric_gemini, select = fabric_group, print = FALSE)
#' nail_response(fabric_gemini, select = fabric_group, print = FALSE)
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
                         default_blocks = c(
                           "reading",
                           "interpretation",
                           "local_task"
                         ),
                         ...) {
  model_missing <- missing(model)
  prompt_style <- match.arg(prompt_style)
  text_role <- match.arg(text_role)
  provider <- match.arg(provider)
  model <- .resolve_llm_model(model, provider, model_missing)
  llm_api_options <- list(...)
  .validate_llm_api_options(llm_api_options, provider)
  default_blocks <- .validate_textual_default_blocks(default_blocks)

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

  textual_evidence <- .build_textual_evidence(
    dataset = dataset,
    num.var = num.var,
    num.text = num.text
  )

  interpretation_input <- .build_textual_interpretation_input(
    textual_evidence = textual_evidence,
    sample.pct = sample.pct,
    seed = seed
  )

  if (is.null(introduction)) {
    introduction <- .textual_default_introduction()
  }

  if (is.null(request)) {
    request <- if (isTRUE(isolate.groups)) {
      .textual_default_request(prompt_style = prompt_style)
    } else {
      .textual_joint_default_request(prompt_style = prompt_style)
    }
  }

  canonical_output_requested <- is.null(conclusion)

  if (canonical_output_requested) {
    conclusion <- .textual_canonical_conclusion(
      isolate.groups = isolate.groups
    )
  }

  prompt_bundles <- .build_local_textual_prompt_bundles(
    textual_evidence = textual_evidence,
    interpretation_input = interpretation_input,
    introduction = introduction,
    request = request,
    conclusion = conclusion,
    prompt_style = prompt_style,
    text_role = text_role,
    default_blocks = default_blocks
  )

  local_prompts <- lapply(
    prompt_bundles,
    function(bundle) bundle$prompt
  )
  prompt_blocks <- lapply(
    prompt_bundles,
    function(bundle) bundle$blocks
  )

  joint_prompt_bundle <- if (!isTRUE(isolate.groups)) {
    .build_joint_textual_prompt_bundle(
      textual_evidence = textual_evidence,
      interpretation_input = interpretation_input,
      introduction = introduction,
      request = request,
      conclusion = conclusion,
      prompt_style = prompt_style,
      text_role = text_role,
      default_blocks = default_blocks
    )
  } else {
    NULL
  }

  active_prompts <- if (isTRUE(isolate.groups)) {
    local_prompts
  } else {
    list(portfolio = joint_prompt_bundle$prompt)
  }

  active_prompt_blocks <- if (isTRUE(isolate.groups)) {
    prompt_blocks
  } else {
    list(portfolio = joint_prompt_bundle$blocks)
  }

  textual_data_summary <- .build_textual_compatibility_summary(
    textual_evidence
  )

  n_ready_groups <- interpretation_input$metadata$n_ready_groups

  textual_settings <- list(
    grouping_variable = textual_evidence$settings$grouping_variable,
    text_variable = textual_evidence$settings$text_variable,
    isolate_groups = isolate.groups,
    sample_pct = sample.pct,
    seed = seed,
    prompt_style = prompt_style,
    text_role = text_role,
    default_blocks = default_blocks,
    generate = generate,
    provider = provider,
    model = model,
    canonical_output_requested = canonical_output_requested,
    generation_architecture = if (isTRUE(isolate.groups)) {
      "local_first"
    } else {
      "joint"
    },
    global_synthesis_performed = !isTRUE(isolate.groups),
    active_scope = if (isTRUE(isolate.groups)) "group" else "portfolio",
    llm_calls = if (isTRUE(generate)) {
      if (isTRUE(isolate.groups)) {
        as.integer(n_ready_groups)
      } else {
        as.integer(n_ready_groups > 0L)
      }
    } else {
      0L
    }
  )

  textual_profiles <- if (isTRUE(isolate.groups)) {
    .build_textual_profiles(
      local_results = NULL,
      local_prompts = local_prompts,
      interpretation_input = interpretation_input,
      generated = FALSE
    )
  } else {
    .build_joint_textual_profile(
      result = NULL,
      prompt = joint_prompt_bundle$prompt,
      interpretation_input = interpretation_input,
      generated = FALSE
    )
  }

  llm_io <- .new_nail_llm_io(
    stage = "interpretation",
    prompts = active_prompts,
    responses = NULL,
    metadata = list(
      analysis = "nail_textual",
      scope = if (isTRUE(isolate.groups)) "group" else "portfolio",
      architecture = if (isTRUE(isolate.groups)) "local_first" else "joint"
    )
  )

  if (!isTRUE(generate)) {
    result <- if (isTRUE(isolate.groups)) {
      local_prompts
    } else {
      joint_prompt_bundle$prompt
    }

    return(.attach_nail_textual_artifacts(
      result = result,
      textual_evidence = textual_evidence,
      interpretation_input = interpretation_input,
      prompt_blocks = active_prompt_blocks,
      local_prompts = local_prompts,
      textual_profiles = textual_profiles,
      textual_settings = textual_settings,
      textual_data_summary = textual_data_summary,
      llm_io = llm_io
    ))
  }

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

  local_results <- NULL
  if (isTRUE(isolate.groups)) {
    local_results <- stats::setNames(
      vector("list", length(local_prompts)),
      names(local_prompts)
    )

    for (group_name in names(local_prompts)) {
      input_group <- interpretation_input$groups[[group_name]]

      local_results[[group_name]] <- if (
        identical(input_group$status, "ready")
      ) {
        call_llm(local_prompts[[group_name]])
      } else {
        .textual_no_results_data_frame(
          model = model,
          prompt = local_prompts[[group_name]],
          group_name = group_name
        )
      }
    }

    textual_profiles <- .build_textual_profiles(
      local_results = local_results,
      local_prompts = local_prompts,
      interpretation_input = interpretation_input,
      generated = TRUE
    )
  } else {
    joint_result <- if (n_ready_groups > 0L) {
      call_llm(joint_prompt_bundle$prompt)
    } else {
      .textual_no_results_data_frame(
        model = model,
        prompt = joint_prompt_bundle$prompt,
        group_name = "portfolio"
      )
    }

    local_results <- list(portfolio = joint_result)
    textual_profiles <- .build_joint_textual_profile(
      result = joint_result,
      prompt = joint_prompt_bundle$prompt,
      interpretation_input = interpretation_input,
      generated = TRUE
    )
  }

  llm_io <- .new_nail_llm_io(
    stage = "interpretation",
    prompts = active_prompts,
    responses = if (isTRUE(isolate.groups)) {
      .textual_llm_responses(local_results, interpretation_input)
    } else {
      list(portfolio = .extract_textual_backend_response(local_results$portfolio))
    },
    metadata = list(
      analysis = "nail_textual",
      scope = if (isTRUE(isolate.groups)) "group" else "portfolio",
      architecture = if (isTRUE(isolate.groups)) "local_first" else "joint"
    )
  )

  result <- if (isTRUE(isolate.groups)) local_results else local_results$portfolio

  .attach_nail_textual_artifacts(
    result = result,
    textual_evidence = textual_evidence,
    interpretation_input = interpretation_input,
    prompt_blocks = active_prompt_blocks,
    local_prompts = local_prompts,
    textual_profiles = textual_profiles,
    textual_settings = textual_settings,
    textual_data_summary = textual_data_summary,
    llm_io = llm_io
  )
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
    "- what this group says in its texts,",
    "- and what this group is like according to external statistical descriptors.",
    "",
    "Interpretive rules:",
    "- Start from recurring themes before proposing a broader interpretation.",
    "- Treat individual phrases as illustrative evidence, not as standalone proof.",
    "- Distinguish central themes from more secondary or marginal elements.",
    "- Explicitly mention internal tensions or hesitations when they appear.",
    "- Do not infer hidden motives or deep personality traits unless they are strongly and repeatedly supported.",
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
    "Dominant concerns or motives:",
    "[1 to 3 short phrases separated by semicolons. If unclear, write: unclear]",
    "",
    "Tone or stance:",
    "[One short expression such as positive / negative / ambivalent / pragmatic / engaged / resigned / mixed]",
    "",
    "Intra-group consistency:",
    "[Choose exactly one: strong / moderate / mixed / weak]",
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
      "Tension verbatim cues:",
      "[0 to 2 very short quoted excerpts or paraphrased cues separated by semicolons. If none, write: none]"
    ),
    collapse = "\n"
  )
}

build_conclusion_textual_prep <- function(include_verbatims = TRUE) {
  fields <- c(
    "1. Core textual profile",
    "2. Main themes",
    "3. Dominant concerns or motives",
    "4. Tone or stance",
    "5. Intra-group consistency",
    "6. Injectable summary"
  )

  if (include_verbatims) {
    fields <- c(
      fields,
      "7. Central verbatim cues",
      "8. Tension verbatim cues"
    )
  }

  paste(
    c(
      "# Output constraint",
      "Your answer must contain exactly these fields and nothing else:",
      fields
    ),
    collapse = "\n"
  )
}

# ---------------------------------------------------------------------------
# Structured textual prep parser (V2)
# ---------------------------------------------------------------------------

.extract_field_block_textual <- function(text, field, next_fields = NULL) {
  escaped_field <- gsub("([][{}()+*^$|\\\\?.])", "\\\\\\1", field)

  if (is.null(next_fields) || length(next_fields) == 0) {
    pattern <- paste0(
      "(?is)",
      "(?:^|\\n)\\s*(?:[-*+]\\s*)?(?:\\*\\*|__|###?\\s*)?\\s*",
      escaped_field,
      "\\s*:?\\s*(?:\\*\\*|__)?\\s*\\n?",
      "(.*)$"
    )
  } else {
    escaped_next <- vapply(
      next_fields,
      function(x) gsub("([][{}()+*^$|\\\\?.])", "\\\\\\1", x),
      character(1)
    )

    next_pattern <- paste(
      paste0("(?:[-*+]\\s*)?(?:\\*\\*|__|###?\\s*)?\\s*", escaped_next, "\\s*:?"),
      collapse = "|"
    )

    pattern <- paste0(
      "(?is)",
      "(?:^|\\n)\\s*(?:[-*+]\\s*)?(?:\\*\\*|__|###?\\s*)?\\s*",
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

  text <- gsub("(?im)^\\s*here is the output\\s*:?\\s*\n?", "", text, perl = TRUE)
  text <- gsub("(?im)^\\s*output\\s*:?\\s*\n?", "", text, perl = TRUE)

  field_order <- c(
    "Core textual profile",
    "Main themes",
    "Dominant concerns or motives",
    "Tone or stance",
    "Intra-group consistency",
    "Injectable summary"
  )

  if (include_verbatims) {
    field_order <- c(
      field_order,
      "Central verbatim cues",
      "Tension verbatim cues"
    )
  }

  get_block <- function(field) {
    idx <- match(field, field_order)
    next_fields <- if (idx < length(field_order)) field_order[(idx + 1):length(field_order)] else NULL
    .extract_field_block_textual(text, field, next_fields = next_fields)
  }

  core_textual_profile <- .clean_field_textual(get_block("Core textual profile"))
  main_themes_raw <- get_block("Main themes")
  dominant_concerns_raw <- get_block("Dominant concerns or motives")
  tone_or_stance_raw <- .clean_field_textual(get_block("Tone or stance"))
  intra_group_consistency_raw <- .clean_field_textual(get_block("Intra-group consistency"))
  injectable_summary <- .clean_field_textual(get_block("Injectable summary"))

  central_verbatim_cues_raw <- if (include_verbatims) get_block("Central verbatim cues") else NA_character_
  tension_verbatim_cues_raw <- if (include_verbatims) get_block("Tension verbatim cues") else NA_character_

  main_themes <- .split_field_textual(main_themes_raw)
  dominant_concerns <- .split_field_textual(dominant_concerns_raw, none_words = c("unclear"))
  central_verbatim_cues <- .split_field_textual(central_verbatim_cues_raw)
  tension_verbatim_cues <- .split_field_textual(tension_verbatim_cues_raw, none_words = c("none"))

  tone_or_stance <- .split_field_textual(tone_or_stance_raw)

  normalize_consistency <- function(x) {
    if (is.na(x) || !nzchar(trimws(x))) return(NA_character_)
    x_low <- tolower(trimws(x))

    for (lab in c("strong", "moderate", "mixed", "weak")) {
      if (startsWith(x_low, lab)) return(lab)
    }

    # fallback : first token before ";" or newline
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
# Textual prep main (V2)
# ---------------------------------------------------------------------------

#' Prepare group-wise structured textual summaries for later contextualization
#'
#' This function reuses `nail_textual()` in isolated mode with a dedicated prompt
#' designed to create short, structured, reusable textual summaries for each group.
#' In V2, it can also attach representative verbatims selected mechanically.
#' It is a preparation route for later contextualization rather than the
#' canonical `nail_textual()` evidence object.
#'
#' @param dataset A data frame containing a grouping and a textual variable.
#' @param num.var Index of the grouping variable.
#' @param num.text Index of the textual variable.
#' @param model LLM model name for the selected provider. When omitted, the
#'   validated provider default is used: `"llama3"` for Ollama and
#'   `"gemini-2.5-flash"` for Gemini. An explicit model is always respected.
#' @param provider LLM backend to use for generation. Use `"ollama"` for a local Ollama model or `"gemini"` for Google Gemini via `GEMINI_API_KEY`.
#' @param sample.pct Proportion of non-empty texts retained per group.
#' @param seed Optional seed used to sample texts reproducibly without altering the user's RNG state.
#' @param language Language used for basic stopword filtering in notable expressions (`"en"`, `"fr"`, or `"none"`).
#' @param prompt_style Either `"detailed"` (default) or `"compact"`.
#' @param text_role Either `"responses"` (default), `"comments"`, or
#'   `"verbatims"`.
#' @param include_verbatims_in_prompt Logical; whether to ask the LLM for brief verbatim cues.
#' @param attach_selected_verbatims Logical; whether to attach mechanically selected representative verbatims.
#' @param n_central_verbatims Number of central verbatims to attach per group.
#' @param n_tension_verbatims Number of tension verbatims to attach per group.
#' @param max_verbatim_chars Maximum number of characters per attached verbatim.
#' @param generate Logical; if `FALSE` returns prompts only. If `TRUE`, calls
#' the provider once per group and parses the structured response.
#' @param ... Additional provider-specific generation arguments passed to the
#'   selected LLM backend. Unknown or provider-incompatible options are
#'   rejected before a preview or generation.
#'
#' @return If `generate = FALSE`, a named list of prompts. If `generate = TRUE`,
#' a named list with `prompt`, `response`, `parsed`, `selected_verbatims`, and
#' `notable_expressions` for each group. The result is not the canonical
#' `nail_textual()` object and does not expose its full evidence accessor
#' contract.
#'
#' @seealso [nail_textual()], [nail_textual_contextualized()],
#'   [nail_catdes_textual()]
#'
#' @examples
#' data(fabric, package = "NaileR")
#' fabric_A <- droplevels(fabric[fabric$Fabric == "A", , drop = FALSE])
#' prep_prompts <- nail_textual_prep(
#'   fabric_A,
#'   num.var = 4,
#'   num.text = 3,
#'   generate = FALSE
#' )
#' names(prep_prompts)
#'
#' @export
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
  model_missing <- missing(model)
  prompt_style <- match.arg(prompt_style)
  text_role <- match.arg(text_role)
  language <- match.arg(language)
  provider <- match.arg(provider)
  model <- .resolve_llm_model(model, provider, model_missing)
  llm_api_options <- list(...)
  .validate_llm_api_options(llm_api_options, provider)
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
          tone_or_stance = NA_character_,
          intra_group_consistency = NA_character_,
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
