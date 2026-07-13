#' @importFrom glue glue
#' @importFrom utils globalVariables
utils::globalVariables(c())

# ---------------------------------------------------------------------------
# Validation
# ---------------------------------------------------------------------------

validate_textual_contextualized_inputs <- function(group_profile_prep = NULL,
                                                   textual_prep = NULL,
                                                   dataset = NULL,
                                                   num.var = NULL,
                                                   num.text = NULL,
                                                   representative_verbatims = NULL,
                                                   generate = FALSE,
                                                   isolate.groups = FALSE,
                                                   interpretation_mode = c("groupwise", "comparative")) {
  interpretation_mode <- match.arg(interpretation_mode)
  if (is.null(group_profile_prep) && is.null(textual_prep) && is.null(dataset)) {
    stop(
      "You must provide either (`group_profile_prep` and/or `textual_prep`) or a `dataset`.",
      call. = FALSE
    )
  }

  if (!is.null(dataset)) {
    if (!is.data.frame(dataset)) {
      stop("`dataset` must be a data frame.", call. = FALSE)
    }

    if (is.null(num.var) || !is.numeric(num.var) || length(num.var) != 1 ||
        is.na(num.var) || num.var < 1 || num.var > ncol(dataset)) {
      stop("`num.var` must be a single valid column index when `dataset` is provided.", call. = FALSE)
    }

    if (is.null(num.text) || !is.numeric(num.text) || length(num.text) != 1 ||
        is.na(num.text) || num.text < 1 || num.text > ncol(dataset)) {
      stop("`num.text` must be a single valid column index when `dataset` is provided.", call. = FALSE)
    }

    if (num.var == num.text) {
      stop("`num.var` and `num.text` must refer to different columns.", call. = FALSE)
    }
  }

  if (!is.null(representative_verbatims) && !is.list(representative_verbatims)) {
    stop("`representative_verbatims` must be a named list when provided.", call. = FALSE)
  }

  if (!is.logical(generate) || length(generate) != 1 || is.na(generate)) {
    stop("`generate` must be a single non-missing logical value.", call. = FALSE)
  }

  if (!is.logical(isolate.groups) || length(isolate.groups) != 1 || is.na(isolate.groups)) {
    stop("`isolate.groups` must be a single non-missing logical value.", call. = FALSE)
  }

  invisible(TRUE)
}

# ---------------------------------------------------------------------------
# Extractors
# ---------------------------------------------------------------------------

.extract_group_profile_parsed <- function(x) {
  if (is.null(x)) return(NULL)

  if (is.list(x) && length(x) > 0) {
    ok <- vapply(x, function(el) is.list(el) && "parsed" %in% names(el), logical(1))
    if (any(ok)) {
      return(lapply(x[ok], function(el) el$parsed))
    }
  }

  NULL
}

.extract_textual_parsed <- function(x) {
  if (is.null(x)) return(NULL)

  if (is.list(x) && length(x) > 0) {
    ok <- vapply(x, function(el) is.list(el) && "parsed" %in% names(el), logical(1))
    if (any(ok)) {
      return(lapply(x[ok], function(el) el$parsed))
    }
  }

  NULL
}

.extract_selected_verbatims_from_textual_prep <- function(x) {
  if (is.null(x)) return(NULL)

  if (is.list(x) && length(x) > 0) {
    ok <- vapply(x, function(el) is.list(el) && "selected_verbatims" %in% names(el), logical(1))
    if (any(ok)) {
      return(lapply(x[ok], function(el) el$selected_verbatims))
    }
  }

  NULL
}

.extract_notable_expressions_from_textual_prep <- function(x) {
  if (is.null(x)) return(NULL)

  if (is.list(x) && length(x) > 0) {
    ok <- vapply(x, function(el) is.list(el) && "notable_expressions" %in% names(el), logical(1))
    if (any(ok)) {
      return(lapply(x[ok], function(el) el$notable_expressions))
    }
  }

  NULL
}

.get_common_groups <- function(group_profile_summary, textual_summary) {
  g1 <- if (!is.null(group_profile_summary)) names(group_profile_summary) else character(0)
  g2 <- if (!is.null(textual_summary)) names(textual_summary) else character(0)

  if (length(g1) == 0 && length(g2) == 0) return(character(0))
  if (length(g1) == 0) return(g2)
  if (length(g2) == 0) return(g1)

  intersect(g1, g2)
}

# ---------------------------------------------------------------------------
# Text helpers for fallback verbatim selection
# ---------------------------------------------------------------------------

.extract_nonempty_texts_context <- function(x) {
  x <- as.character(x)
  x[is.na(x)] <- ""
  x <- trimws(x)
  x[nzchar(x)]
}

.normalize_for_dedup <- function(x) {
  x <- tolower(trimws(x))
  x <- gsub("[[:space:]]+", " ", x)
  x
}

.deduplicate_texts <- function(x) {
  if (length(x) == 0) return(x)
  keep <- !duplicated(.normalize_for_dedup(x))
  x[keep]
}

.truncate_verbatim <- function(x, max_chars = 220) {
  ifelse(
    nchar(x) <= max_chars,
    x,
    paste0(substr(x, 1, max_chars - 3), "...")
  )
}

.tokenize_keywords <- function(x) {
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

.text_keyword_score <- function(text, keywords) {
  if (length(keywords) == 0) return(0)

  txt <- tolower(text)
  txt <- gsub("[[:punct:]]+", " ", txt)

  sum(vapply(keywords, function(k) grepl(paste0("\\b", k, "\\b"), txt), logical(1)))
}

.lexical_distance_to_set <- function(text, set_texts) {
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

.select_representative_verbatims <- function(dataset,
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
    corpus <- .extract_nonempty_texts_context(df_grp[[text_name]])
    corpus <- .deduplicate_texts(corpus)
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
      keywords <- .tokenize_keywords(c(
        parsed$main_themes,
        parsed$dominant_concerns,
        parsed$core_textual_profile
      ))
    }

    lengths <- nchar(corpus)
    med_len <- stats::median(lengths)

    keyword_scores <- vapply(corpus, .text_keyword_score, numeric(1), keywords = keywords)
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
        keyword_score = vapply(remainder, .text_keyword_score, numeric(1), keywords = keywords),
        lexical_distance = vapply(remainder, .lexical_distance_to_set, numeric(1), set_texts = central),
        stringsAsFactors = FALSE
      )

      tension_df <- tension_df[order(tension_df$keyword_score, -tension_df$lexical_distance), , drop = FALSE]
      tension <- utils::head(tension_df$text, n_tension)
    }

    out[[grp_name]] <- list(
      central = .truncate_verbatim(central, max_chars = max_chars),
      tension = .truncate_verbatim(tension, max_chars = max_chars)
    )
  }

  out
}

# ---------------------------------------------------------------------------
# Verbatim merge helpers
# ---------------------------------------------------------------------------

.clean_verbatim_vector_context <- function(x) {
  if (is.null(x) || length(x) == 0) return(character(0))
  x <- as.character(x)
  x <- trimws(x)
  x <- x[nzchar(x)]
  x <- gsub('^"+|"+$', "", x)
  x <- gsub("^'+|'+$", "", x)
  x <- trimws(x)
  x[!duplicated(.normalize_for_dedup(x))]
}

.merge_verbatim_sources <- function(selected_verbatims = NULL, parsed = NULL) {
  selected_central <- if (!is.null(selected_verbatims) && "central" %in% names(selected_verbatims)) {
    selected_verbatims$central
  } else {
    character(0)
  }

  selected_tension <- if (!is.null(selected_verbatims) && "tension" %in% names(selected_verbatims)) {
    selected_verbatims$tension
  } else {
    character(0)
  }

  parsed_central <- if (!is.null(parsed) && "central_verbatim_cues" %in% names(parsed)) {
    parsed$central_verbatim_cues
  } else {
    character(0)
  }

  parsed_tension <- if (!is.null(parsed) && "tension_verbatim_cues" %in% names(parsed)) {
    parsed$tension_verbatim_cues
  } else {
    character(0)
  }

  list(
    central = .clean_verbatim_vector_context(c(selected_central, parsed_central)),
    tension = .clean_verbatim_vector_context(c(selected_tension, parsed_tension))
  )
}

# ---------------------------------------------------------------------------
# Formatting helpers
# ---------------------------------------------------------------------------

.format_profile_summary_block <- function(x) {
  if (is.null(x)) {
    return("*No structured statistical profile summary available.*")
  }

  quanti_txt <- if (!is.null(x$quantitative_traits) && length(x$quantitative_traits) > 0) {
    paste(x$quantitative_traits, collapse = "; ")
  } else {
    "none"
  }

  quali_txt <- if (!is.null(x$categorical_traits) && length(x$categorical_traits) > 0) {
    paste(x$categorical_traits, collapse = "; ")
  } else {
    "none"
  }

  markers_txt <- if (!is.null(x$distinctive_markers) && length(x$distinctive_markers) > 0) {
    paste(x$distinctive_markers, collapse = "; ")
  } else {
    "none"
  }

  paste(
    "### Statistical group profile",
    "",
    paste0("- Core group profile: ", ifelse(is.null(x$core_group_profile) || is.na(x$core_group_profile), "NA", x$core_group_profile)),
    paste0("- Distinctive quantitative traits: ", quanti_txt),
    paste0("- Distinctive categorical traits: ", quali_txt),
    paste0("- Distinctive markers: ", markers_txt),
    paste0("- Profile strength: ", ifelse(is.null(x$profile_strength) || is.na(x$profile_strength), "NA", x$profile_strength)),
    paste0("- Injectable summary: ", ifelse(is.null(x$injectable_summary) || is.na(x$injectable_summary), "NA", x$injectable_summary)),
    sep = "\n"
  )
}

.format_textual_summary_block <- function(x, notable_expressions = NULL) {
  if (is.null(x)) {
    return("*No structured textual summary available.*")
  }

  themes_txt <- if (!is.null(x$main_themes) && length(x$main_themes) > 0) {
    paste(x$main_themes, collapse = "; ")
  } else {
    "none"
  }

  concerns_txt <- if (!is.null(x$dominant_concerns) && length(x$dominant_concerns) > 0) {
    paste(x$dominant_concerns, collapse = "; ")
  } else {
    "none"
  }

  tone_txt <- if (!is.null(x$tone_or_stance) && length(x$tone_or_stance) > 0) {
    paste(x$tone_or_stance, collapse = "; ")
  } else {
    "NA"
  }

  notable_txt <- if (!is.null(notable_expressions) && length(notable_expressions) > 0) {
    paste(notable_expressions, collapse = "; ")
  } else {
    "none"
  }

  paste(
    "### Textual group profile",
    "",
    paste0("- Core textual profile: ", ifelse(is.null(x$core_textual_profile) || is.na(x$core_textual_profile), "NA", x$core_textual_profile)),
    paste0("- Main themes: ", themes_txt),
    paste0("- Dominant concerns or motives: ", concerns_txt),
    paste0("- Tone or stance: ", tone_txt),
    paste0("- Intra-group consistency: ", ifelse(is.null(x$intra_group_consistency) || is.na(x$intra_group_consistency), "NA", x$intra_group_consistency)),
    paste0("- Injectable summary: ", ifelse(is.null(x$injectable_summary) || is.na(x$injectable_summary), "NA", x$injectable_summary)),
    paste0("- Notable expressions: ", notable_txt),
    sep = "\n"
  )
}

.format_verbatim_block <- function(x) {
  if (is.null(x)) {
    return("*No illustrative verbatims available.*")
  }

  central <- if (!is.null(x$central) && length(x$central) > 0) {
    paste0("- \"", x$central, "\"", collapse = "\n")
  } else {
    "- *No central verbatim available.*"
  }

  tension <- if (!is.null(x$tension) && length(x$tension) > 0) {
    paste0("- \"", x$tension, "\"", collapse = "\n")
  } else {
    "- *No tension or minority verbatim available.*"
  }

  paste(
    "### Illustrative verbatims",
    "",
    "#### Central verbatims",
    central,
    "",
    "#### Tension or minority verbatims",
    tension,
    sep = "\n"
  )
}

# ---------------------------------------------------------------------------
# Builders
# ---------------------------------------------------------------------------

build_guide_textual_contextualized <- function(interpretation_mode = c("groupwise", "comparative"),
                                               isolate.groups = FALSE,
                                               include_verbatims = TRUE) {
  interpretation_mode <- match.arg(interpretation_mode)

  intro_lines <- if (isolate.groups) {
    c(
      "## How to Read the Results",
      "The information below combines two complementary sources about one group:",
      "1. a structured statistical profile of the group, based on retained descriptors;",
      "2. a structured textual profile of the group, based on open-ended texts."
    )
  } else {
    c(
      "## How to Read the Results",
      "The information below combines two complementary sources for each group:",
      "1. a structured statistical profile of the group, based on retained descriptors;",
      "2. a structured textual profile of the group, based on open-ended texts."
    )
  }

  if (include_verbatims) {
    intro_lines <- c(
      intro_lines,
      "3. a small set of illustrative verbatims chosen to exemplify either central tendencies or internal nuances."
    )
  }

  discipline_lines <- c(
    "",
    "## Interpretive discipline",
    "- Start from recurring themes and retained descriptors before proposing a broader interpretation.",
    "- Treat verbatims as illustrative evidence, not as standalone proof.",
    "- Distinguish central themes from secondary or marginal elements.",
    "- Explicitly mention internal tensions, hesitations, or contradictions when they appear.",
    "- Do not infer hidden motives, deep personality traits, or moral qualities unless they are strongly and repeatedly supported.",
    "- Do not treat the absence of a theme as proof that the group does not care about it.",
    "- Use the statistical profile and the textual profile together, but do not collapse one into the other.",
    "- When statistical and textual evidence align, say so.",
    "- When they diverge, describe the divergence rather than forcing coherence.",
    "- Stay close to the evidence shown below."
  )

  if (isolate.groups) {
    task_lines <- c(
      "",
      "Your task is to interpret this group by articulating these sources together.",
      "Do not simply repeat them side by side."
    )
  } else if (interpretation_mode == "comparative") {
    task_lines <- c(
      "",
      "Your task is to compare groups by articulating these sources together.",
      "Do not simply summarize them one after another."
    )
  } else {
    task_lines <- c(
      "",
      "Your task is to interpret each group by articulating these sources together.",
      "Do not simply summarize them one after another."
    )
  }

  paste(c(intro_lines, discipline_lines, task_lines), collapse = "\n")
}

build_request_textual_contextualized <- function(interpretation_mode = c("groupwise", "comparative"),
                                                 isolate.groups = FALSE,
                                                 include_verbatims = TRUE) {
  interpretation_mode <- match.arg(interpretation_mode)

  verbatim_lines <- if (include_verbatims) {
    c(
      "Use the verbatims to illustrate or nuance your interpretation.",
      "Do not generalize from a single quote unless it clearly echoes the broader evidence."
    )
  } else {
    character(0)
  }

  if (isolate.groups) {
    return(paste(
      c(
        "Using only the structured evidence below, interpret this group.",
        "Explain:",
        "- what the group looks like statistically,",
        "- what the group expresses in its texts,",
        "- how these two sources converge, complement each other, or reveal tensions.",
        "- which themes appear central, and which appear more secondary or marginal.",
        verbatim_lines,
        "Then propose a short interpretive portrait of the group.",
        "If the evidence is partial, weak, or mixed, say so explicitly."
      ),
      collapse = "\n"
    ))
  }

  if (interpretation_mode == "comparative") {
    return(paste(
      c(
        "Using only the structured evidence below, compare the groups.",
        "For each group, explain:",
        "- what the group looks like statistically,",
        "- what the group expresses in its texts,",
        "- how these two sources converge, complement each other, or reveal tensions.",
        "- which themes appear central, and which appear more secondary, marginal, or internally contested.",
        verbatim_lines,
        "",
        "Then explain what mainly differentiates the groups from one another.",
        "If some groups are clearer than others, or if some groups show internal tensions, say so explicitly."
      ),
      collapse = "\n"
    ))
  }

  paste(
    c(
      "Using only the structured evidence below, interpret each group.",
      "For each group, explain:",
      "- what the group looks like statistically,",
      "- what the group expresses in its texts,",
      "- how these two sources converge, complement each other, or reveal tensions.",
      "- which themes appear central, and which appear more secondary, marginal, or internally contested.",
      verbatim_lines,
      "",
      "Then provide a concise interpretive portrait of each group.",
      "If some groups are clearer than others, or if some groups show internal tensions, say so explicitly."
    ),
    collapse = "\n"
  )
}

build_conclusion_textual_contextualized <- function(isolate.groups = FALSE,
                                                    interpretation_mode = c("groupwise", "comparative")) {
  interpretation_mode <- match.arg(interpretation_mode)

  if (isolate.groups) {
    return(paste(
      "# Final Summary Task",
      "At the end, provide:",
      "1. **A short contextualized interpretation of the group**.",
      "2. **A brief statement about the convergence or tension between the statistical profile and the textual profile**.",
      "3. **A brief distinction between central themes and more secondary or marginal elements**.",
      "",
      "# Output format",
      "Your output must be **formatted using valid Quarto Markdown**.",
      sep = "\n"
    ))
  }

  if (interpretation_mode == "comparative") {
    return(paste(
      "# Final Summary Task",
      "At the end, provide:",
      "1. **A short contextualized interpretation of each group**.",
      "2. **A comparison of the groups**.",
      "3. **A brief statement for each group about the convergence or tension between the statistical profile and the textual profile**.",
      "4. **A brief distinction for each group between central themes and more secondary or marginal elements**.",
      "",
      "# Output format",
      "Your output must be **formatted using valid Quarto Markdown**.",
      sep = "\n"
    ))
  }

  paste(
    "# Final Summary Task",
    "At the end, provide:",
    "1. **A short contextualized interpretation of each group**.",
    "2. **A brief statement for each group about the convergence or tension between the statistical profile and the textual profile**.",
    "3. **A brief distinction for each group between central themes and more secondary or marginal elements**.",
    "",
    "# Output format",
    "Your output must be **formatted using valid Quarto Markdown**.",
    sep = "\n"
  )
}

# ---------------------------------------------------------------------------
# Prompt assembly
# ---------------------------------------------------------------------------

get_prompt_textual_contextualized <- function(group_profile_summary,
                                              textual_summary,
                                              representative_verbatims = NULL,
                                              notable_expressions = NULL,
                                              introduction,
                                              request,
                                              conclusion,
                                              isolate.groups = FALSE,
                                              interpretation_mode = c("groupwise", "comparative"),
                                              include_verbatims = TRUE) {
  interpretation_mode <- match.arg(interpretation_mode)

  groups <- .get_common_groups(group_profile_summary, textual_summary)

  if (length(groups) == 0) {
    stop("No common groups were found between the group profile summaries and the textual summaries.", call. = FALSE)
  }

  .one_group_block <- function(grp) {
    prof_block <- .format_profile_summary_block(group_profile_summary[[grp]])
    txt_block  <- .format_textual_summary_block(
      textual_summary[[grp]],
      notable_expressions = notable_expressions[[grp]]
    )

    parts <- c(
      glue::glue("## Group '{grp}'"),
      "",
      prof_block,
      "",
      txt_block
    )

    if (include_verbatims) {
      vb_block <- .format_verbatim_block(representative_verbatims[[grp]])
      parts <- c(parts, "", vb_block)
    }

    paste(parts, collapse = "\n")
  }

  if (!isolate.groups) {
    blocks <- vapply(groups, .one_group_block, character(1))
    data_txt <- paste(blocks, collapse = "\n\n---\n\n")

    return(
      build_standard_prompt(
        introduction = introduction,
        request = request,
        data = data_txt,
        conclusion = conclusion
      )
    )
  }

  out <- lapply(groups, function(grp) {
    data_txt <- .one_group_block(grp)

    build_standard_prompt(
      introduction = introduction,
      request = request,
      data = data_txt,
      conclusion = conclusion
    )
  })

  names(out) <- groups
  out
}

# ---------------------------------------------------------------------------
# Main
# ---------------------------------------------------------------------------

#' Contextualized interpretation of textual group differences
#'
#' This function crosses:
#' - a structured statistical summary of each group
#' - a structured textual summary of each group
#' - optional representative verbatims for each group
#'
#' It can work either from precomputed objects (`nail_group_profile_prep()`,
#' `nail_textual_prep()`) or compute them internally from the raw dataset.
#'
#' @param group_profile_prep Optional output from `nail_group_profile_prep(generate = TRUE)`.
#' @param textual_prep Optional output from `nail_textual_prep(generate = TRUE)`.
#' @param representative_verbatims Optional named list of verbatims per group.
#' @param dataset Optional raw dataset.
#' @param num.var Index of grouping variable if `dataset` is used.
#' @param num.text Index of textual variable if `dataset` is used.
#' @param proba Significance threshold forwarded to `nail_group_profile_prep()`.
#' @param sample.pct.text Proportion of texts retained per group for textual prep.
#' @param sample.pct.profile Proportion of retained descriptors kept for group profile prep.
#' @param profile_mode `"balanced"`, `"categorical"`, or `"quantitative"`.
#' @param prompt_style `"compact"` or `"detailed"`.
#' @param interpretation_mode `"groupwise"` or `"comparative"`.
#' @param include_verbatims Logical; whether to include illustrative verbatims in the final prompt.
#' @param n_central_verbatims Number of central verbatims per group for fallback selection.
#' @param n_tension_verbatims Number of tension verbatims per group for fallback selection.
#' @param max_verbatim_chars Maximum number of characters per fallback verbatim.
#' @param introduction Optional introduction.
#' @param request Optional request block.
#' @param conclusion Optional conclusion block.
#' @param isolate.groups Logical; if TRUE, one prompt per group.
#' @param model LLM model name for the selected provider.
#' @param provider LLM backend to use for generation. Use `"ollama"` for a local Ollama model or `"gemini"` for Google Gemini via `GEMINI_API_KEY`.
#' @param row.w Optional row weights forwarded to `nail_group_profile_prep()`.
#' @param generate Logical; if FALSE, return prompt(s) only.
#' @param ... Additional provider-specific generation arguments passed to the selected LLM backend.
#'
#' @return When `generate = FALSE`, both `group_profile_prep` and `textual_prep` must be supplied as precomputed objects. Internal preparation from raw data requires LLM generation.
#' If `generate = TRUE`, a data frame or a named list of data frames.
#'
#' Attributes:
#' - `group_profile_summary`
#' - `textual_group_summary`
#' - `representative_verbatims`
#' - `notable_expressions`
#'
#' @export
nail_textual_contextualized <- function(group_profile_prep = NULL,
                                        textual_prep = NULL,
                                        representative_verbatims = NULL,
                                        dataset = NULL,
                                        num.var = NULL,
                                        num.text = NULL,
                                        proba = 0.05,
                                        sample.pct.text = 1,
                                        sample.pct.profile = 1,
                                        profile_mode = c("balanced", "categorical", "quantitative"),
                                        prompt_style = c("compact", "detailed"),
                                        interpretation_mode = c("groupwise", "comparative"),
                                        include_verbatims = TRUE,
                                        n_central_verbatims = 2,
                                        n_tension_verbatims = 1,
                                        max_verbatim_chars = 220,
                                        introduction = NULL,
                                        request = NULL,
                                        conclusion = NULL,
                                        isolate.groups = FALSE,
                                        model = "llama3",
                                        provider = c("ollama", "gemini"),
                                        row.w = NULL,
                                        generate = FALSE,
                                        ...) {
  profile_mode <- match.arg(profile_mode)
  prompt_style <- match.arg(prompt_style)
  interpretation_mode <- match.arg(interpretation_mode)

  provider <- match.arg(provider)

  validate_textual_contextualized_inputs(
    group_profile_prep = group_profile_prep,
    textual_prep = textual_prep,
    dataset = dataset,
    num.var = num.var,
    num.text = num.text,
    representative_verbatims = representative_verbatims,
    generate = generate,
    isolate.groups = isolate.groups,
    interpretation_mode = interpretation_mode
  )

  if (!generate && (is.null(group_profile_prep) || is.null(textual_prep))) {
    stop(
      paste(
        "`generate = FALSE` is a no-LLM mode in `nail_textual_contextualized()`.",
        "Provide already generated `group_profile_prep` and `textual_prep` artifacts,",
        "or call the preparation functions explicitly before building contextualized prompts."
      ),
      call. = FALSE
    )
  }

  if (is.null(group_profile_prep) && !is.null(dataset)) {
    group_profile_prep <- nail_group_profile_prep(
      dataset = dataset,
      num.var = num.var,
      proba = proba,
      sample.pct = sample.pct.profile,
      profile_mode = profile_mode,
      prompt_style = prompt_style,
      model = model,
      provider = provider,
      row.w = row.w,
      generate = TRUE,
      ...
    )
  }

  if (is.null(textual_prep) && !is.null(dataset)) {
    textual_prep <- nail_textual_prep(
      dataset = dataset,
      num.var = num.var,
      num.text = num.text,
      sample.pct = sample.pct.text,
      prompt_style = prompt_style,
      model = model,
      provider = provider,
      generate = TRUE,
      ...
    )
  }

  group_profile_summary <- .extract_group_profile_parsed(group_profile_prep)
  textual_group_summary <- .extract_textual_parsed(textual_prep)

  if (is.null(group_profile_summary) || length(group_profile_summary) == 0) {
    stop("No parsed group-profile summaries were found.", call. = FALSE)
  }

  if (is.null(textual_group_summary) || length(textual_group_summary) == 0) {
    stop("No parsed textual summaries were found.", call. = FALSE)
  }

  selected_from_prep <- .extract_selected_verbatims_from_textual_prep(textual_prep)
  notable_from_prep <- .extract_notable_expressions_from_textual_prep(textual_prep)

  if (is.null(representative_verbatims) && !is.null(selected_from_prep)) {
    representative_verbatims <- selected_from_prep
  }

  if (is.null(representative_verbatims) && include_verbatims && !is.null(dataset)) {
    representative_verbatims <- .select_representative_verbatims(
      dataset = dataset,
      num.var = num.var,
      num.text = num.text,
      textual_summary = textual_group_summary,
      n_central = n_central_verbatims,
      n_tension = n_tension_verbatims,
      max_chars = max_verbatim_chars
    )
  }

  if (is.null(representative_verbatims)) {
    representative_verbatims <- list()
  }

  groups <- .get_common_groups(group_profile_summary, textual_group_summary)

  representative_verbatims <- lapply(groups, function(grp) {
    selected <- if (grp %in% names(representative_verbatims)) representative_verbatims[[grp]] else NULL
    parsed   <- if (grp %in% names(textual_group_summary)) textual_group_summary[[grp]] else NULL
    .merge_verbatim_sources(selected_verbatims = selected, parsed = parsed)
  })
  names(representative_verbatims) <- groups

  notable_expressions <- if (!is.null(notable_from_prep)) notable_from_prep else list()
  if (length(notable_expressions) == 0) {
    notable_expressions <- stats::setNames(vector("list", length(groups)), groups)
  }

  if (is.null(introduction)) {
    introduction <- if (interpretation_mode == "comparative") {
      "The results below combine structured statistical summaries, structured textual summaries, and selected illustrative verbatims for several groups. The goal is to interpret the groups in a contextualized way and compare them."
    } else {
      "The results below combine structured statistical summaries, structured textual summaries, and selected illustrative verbatims for several groups. The goal is to interpret each group in a contextualized way."
    }
  }

  if (is.null(request)) {
    request <- build_request_textual_contextualized(
      interpretation_mode = interpretation_mode,
      isolate.groups = isolate.groups,
      include_verbatims = include_verbatims
    )
  }

  if (is.null(conclusion)) {
    conclusion <- build_conclusion_textual_contextualized(
      isolate.groups = isolate.groups,
      interpretation_mode = interpretation_mode
    )
  }

  guide <- build_guide_textual_contextualized(
    interpretation_mode = interpretation_mode,
    isolate.groups = isolate.groups,
    include_verbatims = include_verbatims
  )

  introduction <- paste(introduction, guide, sep = "\n\n---\n\n")

  prompts <- get_prompt_textual_contextualized(
    group_profile_summary = group_profile_summary,
    textual_summary = textual_group_summary,
    representative_verbatims = representative_verbatims,
    notable_expressions = notable_expressions,
    introduction = introduction,
    request = request,
    conclusion = conclusion,
    isolate.groups = isolate.groups,
    interpretation_mode = interpretation_mode,
    include_verbatims = include_verbatims
  )

  if (!generate) {
    attr(prompts, "group_profile_summary") <- group_profile_summary
    attr(prompts, "textual_group_summary") <- textual_group_summary
    attr(prompts, "representative_verbatims") <- representative_verbatims
    attr(prompts, "notable_expressions") <- notable_expressions
    return(prompts)
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
    out <- .call_llm(prompts)
    attr(out, "group_profile_summary") <- group_profile_summary
    attr(out, "textual_group_summary") <- textual_group_summary
    attr(out, "representative_verbatims") <- representative_verbatims
    attr(out, "notable_expressions") <- notable_expressions
    return(out)
  }

  out <- lapply(prompts, .call_llm)
  names(out) <- names(prompts)
  attr(out, "group_profile_summary") <- group_profile_summary
  attr(out, "textual_group_summary") <- textual_group_summary
  attr(out, "representative_verbatims") <- representative_verbatims
  attr(out, "notable_expressions") <- notable_expressions
  out
}
