# ---------------------------------------------------------------------------
# CATDES + textual enrichment
# ---------------------------------------------------------------------------

.validate_nail_catdes_textual_inputs <- function(catdes,
                                                 textual,
                                                 isolate.groups,
                                                 generate) {
  if (is.null(catdes)) {
    stop("`catdes` must be a `nail_catdes()` result.", call. = FALSE)
  }

  if (is.null(textual)) {
    stop("`textual` must be a `nail_textual()` result.", call. = FALSE)
  }

  semantic_facing <- attr(catdes, "semantic_facing_evidence", exact = TRUE)
  if (is.null(semantic_facing) ||
      !inherits(semantic_facing, "nail_catdes_semantic_facing_evidence")) {
    stop(
      paste(
        "`catdes` does not contain canonical CATDES semantic-facing evidence.",
        "Recreate it with `nail_catdes()`."
      ),
      call. = FALSE
    )
  }

  textual_evidence <- attr(textual, "textual_evidence", exact = TRUE)
  interpretation_input <- attr(textual, "interpretation_input", exact = TRUE)
  textual_profiles <- attr(textual, "textual_profiles", exact = TRUE)

  if (is.null(textual_evidence) ||
      !inherits(textual_evidence, "nail_textual_evidence")) {
    stop(
      paste(
        "`textual` does not contain canonical textual evidence.",
        "Recreate it with the rebuilt `nail_textual()`."
      ),
      call. = FALSE
    )
  }

  if (is.null(interpretation_input) ||
      !inherits(
        interpretation_input,
        "nail_textual_interpretation_input"
      )) {
    stop(
      paste(
        "`textual` does not contain canonical interpretation input.",
        "Recreate it with the rebuilt `nail_textual()`."
      ),
      call. = FALSE
    )
  }

  if (is.null(textual_profiles) ||
      !inherits(textual_profiles, "nail_textual_profiles")) {
    stop(
      paste(
        "`textual` does not contain canonical textual profiles.",
        "Recreate it with the rebuilt `nail_textual()`."
      ),
      call. = FALSE
    )
  }

  if (!is.logical(isolate.groups) ||
      length(isolate.groups) != 1L ||
      is.na(isolate.groups)) {
    stop(
      "`isolate.groups` must be a single non-missing logical value.",
      call. = FALSE
    )
  }

  if (!is.logical(generate) ||
      length(generate) != 1L ||
      is.na(generate)) {
    stop(
      "`generate` must be a single non-missing logical value.",
      call. = FALSE
    )
  }

  catdes_groups <- names(semantic_facing$groups)
  textual_groups <- names(textual_profiles$groups)

  if (!setequal(catdes_groups, textual_groups)) {
    only_catdes <- setdiff(catdes_groups, textual_groups)
    only_textual <- setdiff(textual_groups, catdes_groups)

    details <- c(
      if (length(only_catdes) > 0L) {
        paste0(
          "CATDES only: ",
          paste(only_catdes, collapse = ", ")
        )
      },
      if (length(only_textual) > 0L) {
        paste0(
          "textual only: ",
          paste(only_textual, collapse = ", ")
        )
      }
    )

    stop(
      paste0(
        "`catdes` and `textual` must describe exactly the same groups. ",
        paste(details, collapse = "; "),
        "."
      ),
      call. = FALSE
    )
  }

  unavailable_catdes <- catdes_groups[
    !vapply(
      semantic_facing$groups[catdes_groups],
      function(group) identical(group$status, "ready"),
      logical(1)
    )
  ]

  if (length(unavailable_catdes) > 0L) {
    statuses <- vapply(
      semantic_facing$groups[unavailable_catdes],
      function(group) as.character(group$status)[1L],
      character(1)
    )

    stop(
      paste0(
        "Canonical CATDES statistical anchors are not available for group(s): ",
        paste(
          paste0(unavailable_catdes, " [", statuses, "]"),
          collapse = ", "
        ),
        ". Review the CATDES selection before calling `nail_catdes_textual()`."
      ),
      call. = FALSE
    )
  }

  unavailable <- catdes_groups[
    !vapply(
      textual_profiles$groups[catdes_groups],
      function(group) identical(group$status, "available"),
      logical(1)
    )
  ]

  if (length(unavailable) > 0L) {
    statuses <- vapply(
      textual_profiles$groups[unavailable],
      function(group) as.character(group$status)[1L],
      character(1)
    )

    stop(
      paste0(
        "Canonical textual profiles are not available for group(s): ",
        paste(
          paste0(unavailable, " [", statuses, "]"),
          collapse = ", "
        ),
        ". Generate or repair these profiles with `nail_textual(generate = TRUE)` ",
        "before calling `nail_catdes_textual()`."
      ),
      call. = FALSE
    )
  }

  invisible(TRUE)
}


.extract_catdes_semantic_response <- function(catdes, group_name) {
  semantic_profiles <- attr(catdes, "semantic_profiles", exact = TRUE)

  if (is.null(semantic_profiles) ||
      is.null(semantic_profiles$groups) ||
      !group_name %in% names(semantic_profiles$groups)) {
    return(NULL)
  }

  response <- semantic_profiles$groups[[group_name]]$response

  if (is.null(response) ||
      length(response) == 0L ||
      is.na(response[[1L]]) ||
      !nzchar(trimws(as.character(response[[1L]])))) {
    return(NULL)
  }

  as.character(response[[1L]])
}


.resolve_textual_ids_catdes_textual <- function(textual_evidence, ids) {
  registry <- textual_evidence$text_registry

  if (length(ids) == 0L) {
    return(registry[FALSE, c("text_id", "group", "source_row", "text"), drop = FALSE])
  }

  positions <- match(ids, registry$text_id)

  if (anyNA(positions)) {
    missing <- ids[is.na(positions)]
    stop(
      paste0(
        "Internal inconsistency: textual profile references unknown text ID(s): ",
        paste(missing, collapse = ", "),
        "."
      ),
      call. = FALSE
    )
  }

  out <- registry[
    positions,
    c("text_id", "group", "source_row", "text"),
    drop = FALSE
  ]
  rownames(out) <- NULL
  out
}


.build_catdes_textual_evidence <- function(catdes, textual) {
  semantic_facing <- attr(
    catdes,
    "semantic_facing_evidence",
    exact = TRUE
  )
  catdes_settings <- attr(
    catdes,
    "catdes_settings",
    exact = TRUE
  )
  textual_evidence <- attr(
    textual,
    "textual_evidence",
    exact = TRUE
  )
  interpretation_input <- attr(
    textual,
    "interpretation_input",
    exact = TRUE
  )
  textual_profiles <- attr(
    textual,
    "textual_profiles",
    exact = TRUE
  )

  group_names <- names(semantic_facing$groups)
  groups <- stats::setNames(
    vector("list", length(group_names)),
    group_names
  )

  for (group_name in group_names) {
    statistical <- semantic_facing$groups[[group_name]]
    text_profile <- textual_profiles$groups[[group_name]]
    text_metrics <- textual_evidence$groups[[group_name]]$metrics
    input_metrics <- interpretation_input$groups[[group_name]]$metrics

    allowed_text_ids <-
      interpretation_input$groups[[group_name]]$selected_text_ids

    invalid_representative <- setdiff(
      text_profile$representative_text_ids,
      allowed_text_ids
    )
    invalid_tension <- setdiff(
      text_profile$tension_text_ids,
      allowed_text_ids
    )

    if (length(invalid_representative) > 0L ||
        length(invalid_tension) > 0L) {
      stop(
        paste0(
          "Internal inconsistency: textual profile for group '",
          group_name,
          "' references text IDs that were not shown to the textual LLM."
        ),
        call. = FALSE
      )
    }

    representative <- .resolve_textual_ids_catdes_textual(
      textual_evidence,
      text_profile$representative_text_ids
    )
    tension <- .resolve_textual_ids_catdes_textual(
      textual_evidence,
      text_profile$tension_text_ids
    )

    if (nrow(representative) > 0L &&
        any(representative$group != group_name)) {
      stop(
        paste0(
          "Internal inconsistency: representative text IDs for group '",
          group_name,
          "' point to another group."
        ),
        call. = FALSE
      )
    }

    if (nrow(tension) > 0L &&
        any(tension$group != group_name)) {
      stop(
        paste0(
          "Internal inconsistency: tension text IDs for group '",
          group_name,
          "' point to another group."
        ),
        call. = FALSE
      )
    }

    groups[[group_name]] <- list(
      group = group_name,
      status = "ready",
      statistical_anchor = list(
        status = statistical$status,
        factual_text = statistical$text,
        selected_evidence_ids = statistical$selected_evidence_ids,
        n_selected_evidence = statistical$metrics$n_selected,
        n_displayed_evidence = statistical$metrics$n_displayed,
        existing_semantic_interpretation =
          .extract_catdes_semantic_response(catdes, group_name)
      ),
      textual_enrichment = list(
        core_textual_profile = text_profile$core_textual_profile,
        dominant_themes = text_profile$dominant_themes,
        within_group_coherence = text_profile$within_group_coherence,
        internal_diversity = text_profile$internal_diversity,
        representative_texts = representative,
        tension_texts = tension,
        metrics = list(
          n_group_rows = text_metrics$n_group_rows,
          n_texts = text_metrics$n_texts,
          response_rate = text_metrics$response_rate,
          n_unique_texts = text_metrics$n_unique_texts,
          n_available_texts = input_metrics$n_available_texts,
          n_shown_texts = input_metrics$n_shown_texts,
          interpretation_coverage =
            input_metrics$interpretation_coverage
        )
      )
    )
  }

  out <- list(
    groups = groups,
    settings = list(
      architecture = "catdes_anchor_textual_enrichment",
      local_first = TRUE,
      global_synthesis_performed = FALSE,
      catdes_interpretation_mode =
        if (!is.null(catdes_settings$interpretation_mode)) {
          catdes_settings$interpretation_mode
        } else {
          NA_character_
        }
    ),
    metadata = list(
      schema = "NaileR::catdes_textual_evidence",
      schema_version = "0.1.0",
      n_groups = as.integer(length(groups)),
      statistical_source = "semantic_facing_evidence",
      textual_source = "textual_profiles",
      textual_grounding_source = "textual_evidence",
      textual_variable = textual_evidence$settings$text_variable
    )
  )

  class(out) <- c(
    "nail_catdes_textual_evidence",
    "list"
  )
  out
}


.format_exact_texts_catdes_textual <- function(x) {
  if (!is.data.frame(x) || nrow(x) == 0L) {
    return("*None identified.*")
  }

  paste0(
    "[",
    x$text_id,
    "] ",
    x$text,
    collapse = "\n\n"
  )
}


.format_textual_profile_catdes_textual <- function(x) {
  themes <- if (length(x$dominant_themes) > 0L) {
    paste0(
      "- ",
      x$dominant_themes,
      collapse = "\n"
    )
  } else {
    "*No dominant themes available.*"
  }

  paste0(
    "Core textual profile:\n",
    x$core_textual_profile,
    "\n\nDominant themes:\n",
    themes,
    "\n\nWithin-group coherence:\n",
    x$within_group_coherence,
    "\n\nInternal diversity:\n",
    x$internal_diversity
  )
}


.catdes_textual_default_introduction <- function() {
  paste(
    "The group below has already been characterized statistically with CATDES.",
    "Open-ended responses from individuals in the same group provide a supplementary",
    "textual layer that can enrich the interpretation of this statistical profile."
  )
}


.catdes_textual_default_request <- function() {
  paste(
    "Use the textual evidence to enrich the interpretation of the statistically characterized group.",
    "Treat the CATDES evidence as the statistical anchor.",
    "First identify which displayed CATDES characteristic or characteristics, if any, are substantively connected to what respondents explicitly express in the texts.",
    "Use the textual evidence to interpret, contextualize, or nuance only those supported connections.",
    "Name the CATDES characteristic or characteristics being enriched rather than speaking vaguely about the group as a whole.",
    "Do not generalize reasons, constraints, values, or considerations expressed about one characteristic to other CATDES dimensions.",
    "Do not generalize the textual profile to unrelated CATDES dimensions.",
    "Identify additional insights that emerge from the texts without forcing them to correspond to a statistical descriptor.",
    "Preserve meaningful internal diversity in the textual evidence.",
    "Do not reinterpret the statistical facts from the texts.",
    "Do not infer hidden motives, personality traits, moral qualities, or causal explanations that are not supported by the evidence."
  )
}


.catdes_textual_default_conclusion <- function() {
  paste(
    "# Required output",
    "",
    "Your answer must contain exactly these fields and nothing else:",
    "",
    "Statistical anchor:",
    "[One concise statement summarizing the statistical characterization, grounded only in the CATDES evidence.]",
    "",
    "Textual enrichment:",
    "[Explain how the textual profile helps interpret, contextualize, or nuance CATDES characteristics when an explicit substantive connection is supported by the texts. Do not generalize it to unrelated dimensions.]",
    "",
    "Additional insights:",
    "[State what the texts add beyond the directly related CATDES characteristic or characteristics. Keep these insights within the scope of what respondents explicitly express. If nothing clear is added, write: none.]",
    "",
    "Internal diversity:",
    "[Describe meaningful textual diversity or tensions that should not be generalized to the whole group.]",
    "",
    "Contextualized profile:",
    "[One concise integrated portrait in which the CATDES characterization remains the broad anchor and textual enrichment is kept within what the observed discourse actually supports.]",
    sep = "\n"
  )
}


.catdes_textual_guide <- function() {
  paste(
    "CATDES and textual evidence do not play symmetrical roles here.",
    "The CATDES facts characterize the group statistically and form the anchor of the interpretation.",
    "The textual profile is supplementary evidence about how members of the group express the phenomenon in open-ended responses.",
    "A textual theme may confirm, clarify, nuance, or add information to the statistical characterization.",
    "A textual theme that has no direct CATDES counterpart is not automatically a contradiction; it may be an additional insight.",
    "Conversely, the absence of a statistical characteristic from the texts does not invalidate that characteristic.",
    "Representative and tension texts are illustrative grounding for the textual profile, not independent statistical proof.",
    "The textual evidence may illuminate only part of the statistical profile.",
    "Relate textual evidence to CATDES characteristics only when the connection is supported by what respondents explicitly express.",
    "When connecting textual evidence to CATDES, state explicitly which statistical characteristic or characteristics are being enriched.",
    "Do not use reasons, constraints, values, or considerations expressed about one characteristic as explanations for other CATDES characteristics.",
    "Do not use textual evidence as support for CATDES characteristics that are not substantively connected to the observed discourse.",
    "Response coverage and interpretation coverage are different: the first describes how many group members supplied text, while the second describes how much of the available corpus was shown to the textual LLM.",
    "When interpretation coverage is partial, avoid treating the textual profile as exhaustive evidence of everything expressed in the full corpus.",
    "Do not force agreement between the two layers of evidence.",
    "Stay close to the evidence shown for this group."
  )
}


.build_one_catdes_textual_data_block <- function(contextualized_evidence,
                                                 group_name) {
  group <- contextualized_evidence$groups[[group_name]]
  stat <- group$statistical_anchor
  txt <- group$textual_enrichment
  metrics <- txt$metrics

  response_coverage <- if (is.na(metrics$response_rate)) {
    "NA"
  } else {
    sprintf("%.1f%%", 100 * metrics$response_rate)
  }

  interpretation_coverage <- if (is.na(metrics$interpretation_coverage)) {
    "NA"
  } else {
    sprintf("%.1f%%", 100 * metrics$interpretation_coverage)
  }

  existing_interpretation <- if (
    is.null(stat$existing_semantic_interpretation)
  ) {
    "*No prior CATDES semantic interpretation was generated. Use the statistical facts above as the anchor.*"
  } else {
    stat$existing_semantic_interpretation
  }

  paste0(
    "## Group \"", group_name, "\"\n\n",
    "### Statistical anchor — mechanical CATDES evidence\n\n",
    stat$factual_text,
    "\n\n### Existing CATDES interpretation\n\n",
    existing_interpretation,
    "\n\n### Textual profile\n\n",
    .format_textual_profile_catdes_textual(txt),
    "\n\n### Textual coverage\n\n",
    "- Non-empty textual responses: ", metrics$n_texts,
    " of ", metrics$n_group_rows,
    " observations (", response_coverage, ")\n",
    "- Texts used to build the textual profile: ",
    metrics$n_shown_texts,
    " of ",
    metrics$n_available_texts,
    " (", interpretation_coverage, ")\n",
    "- Distinct textual responses in the complete corpus: ",
    metrics$n_unique_texts,
    "\n\n### Representative grounding texts\n\n",
    .format_exact_texts_catdes_textual(
      txt$representative_texts
    ),
    "\n\n### Tension or minority grounding texts\n\n",
    .format_exact_texts_catdes_textual(
      txt$tension_texts
    )
  )
}


.build_local_catdes_textual_prompts <- function(contextualized_evidence,
                                                introduction,
                                                request,
                                                conclusion) {
  group_names <- names(contextualized_evidence$groups)
  prompts <- stats::setNames(
    vector("list", length(group_names)),
    group_names
  )

  for (group_name in group_names) {
    prompts[[group_name]] <- normalize_blank_lines(
      paste0(
        "# Introduction\n\n",
        introduction,
        "\n\n---\n\n## How to Read the Evidence\n\n",
        .catdes_textual_guide(),
        "\n\n# Overall Analytical Request\n\n",
        request,
        "\n\n# Local Task\n\n",
        "Interpret only the group shown below. ",
        "Do not compare it with other groups at this stage.",
        "\n\n# Data\n\n",
        .build_one_catdes_textual_data_block(
          contextualized_evidence,
          group_name
        ),
        "\n\n",
        conclusion
      )
    )
  }

  prompts
}


.combine_local_catdes_textual_prompt_preview <- function(local_prompts) {
  parts <- vapply(
    names(local_prompts),
    function(group_name) {
      paste0(
        "## Local prompt for group \"",
        group_name,
        "\"\n\n",
        local_prompts[[group_name]]
      )
    },
    character(1)
  )

  normalize_blank_lines(
    paste0(
      "# Local-first CATDES textual enrichment plan\n\n",
      "Each statistically characterized group will be enriched independently. ",
      "No group receives evidence from another group during this pass.\n\n",
      paste(parts, collapse = "\n\n---\n\n")
    )
  )
}


.extract_field_block_catdes_textual <- function(text,
                                                field,
                                                next_fields = NULL) {
  escaped_field <- gsub(
    "([][{}()+*^$|\\\\?.])",
    "\\\\\\1",
    field
  )

  if (is.null(next_fields) || length(next_fields) == 0L) {
    pattern <- paste0(
      "(?is)",
      "(?:^|\\n)\\s*(?:[-*+]\\s*)?",
      "(?:\\*\\*|__|###?\\s*)?\\s*",
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
        "(?:[-*+]\\s*)?(?:\\*\\*|__|###?\\s*)?\\s*",
        escaped_next,
        "\\s*:?"
      ),
      collapse = "|"
    )

    pattern <- paste0(
      "(?is)",
      "(?:^|\\n)\\s*(?:[-*+]\\s*)?",
      "(?:\\*\\*|__|###?\\s*)?\\s*",
      escaped_field,
      "\\s*:?\\s*(?:\\*\\*|__)?\\s*\\n?",
      "(.*?)",
      "(?=\\n\\s*(?:",
      next_pattern,
      ")|$)"
    )
  }

  match <- regexec(pattern, text, perl = TRUE)
  pieces <- regmatches(text, match)[[1L]]

  if (length(pieces) >= 2L) {
    trimws(pieces[[2L]])
  } else {
    NA_character_
  }
}


.clean_field_catdes_textual <- function(x) {
  if (is.na(x) || !nzchar(trimws(x))) {
    return(NA_character_)
  }

  x <- trimws(x)
  x <- gsub("^[-*+]\\s*", "", x)
  x <- gsub("\\n+", " ", x)
  x <- gsub("[[:space:]]+", " ", x)
  trimws(x)
}


.parse_catdes_textual_response <- function(text) {
  text <- paste(text, collapse = "\n")
  text <- gsub("\r\n", "\n", text, fixed = TRUE)
  text <- gsub("\r", "\n", text, fixed = TRUE)

  fields <- c(
    "Statistical anchor",
    "Textual enrichment",
    "Additional insights",
    "Internal diversity",
    "Contextualized profile"
  )

  get_block <- function(field) {
    index <- match(field, fields)
    next_fields <- if (index < length(fields)) {
      fields[(index + 1L):length(fields)]
    } else {
      NULL
    }

    .extract_field_block_catdes_textual(
      text,
      field,
      next_fields
    )
  }

  statistical_anchor <- .clean_field_catdes_textual(
    get_block("Statistical anchor")
  )
  textual_enrichment <- .clean_field_catdes_textual(
    get_block("Textual enrichment")
  )
  additional_insights <- .clean_field_catdes_textual(
    get_block("Additional insights")
  )
  internal_diversity <- .clean_field_catdes_textual(
    get_block("Internal diversity")
  )
  contextualized_profile <- .clean_field_catdes_textual(
    get_block("Contextualized profile")
  )

  issues <- character(0)

  if (is.na(statistical_anchor)) {
    issues <- c(issues, "missing_statistical_anchor")
  }
  if (is.na(textual_enrichment)) {
    issues <- c(issues, "missing_textual_enrichment")
  }
  if (is.na(additional_insights)) {
    issues <- c(issues, "missing_additional_insights")
  }
  if (is.na(internal_diversity)) {
    issues <- c(issues, "missing_internal_diversity")
  }
  if (is.na(contextualized_profile)) {
    issues <- c(issues, "missing_contextualized_profile")
  }

  list(
    status = if (length(issues) == 0L) {
      "available"
    } else {
      "parse_failed"
    },
    statistical_anchor = statistical_anchor,
    textual_enrichment = textual_enrichment,
    additional_insights = additional_insights,
    internal_diversity = internal_diversity,
    contextualized_profile = contextualized_profile,
    parse_issues = unique(issues)
  )
}


.extract_catdes_textual_backend_response <- function(result) {
  if (is.data.frame(result) &&
      "response" %in% names(result) &&
      nrow(result) > 0L) {
    return(as.character(result$response[[1L]]))
  }

  if (is.list(result) &&
      !is.null(result$response) &&
      length(result$response) > 0L) {
    return(as.character(result$response[[1L]]))
  }

  NULL
}


.empty_catdes_textual_profile <- function(status,
                                          prompt,
                                          response = NULL,
                                          backend_result = NULL,
                                          parse_issues = character(0)) {
  list(
    status = status,
    statistical_anchor = NA_character_,
    textual_enrichment = NA_character_,
    additional_insights = NA_character_,
    internal_diversity = NA_character_,
    contextualized_profile = NA_character_,
    parse_issues = parse_issues,
    prompt = prompt,
    response = response,
    backend_result = backend_result
  )
}


.build_catdes_textual_profiles <- function(local_results,
                                           local_prompts,
                                           generated) {
  group_names <- names(local_prompts)
  groups <- stats::setNames(
    vector("list", length(group_names)),
    group_names
  )

  for (group_name in group_names) {
    result_group <- if (!is.null(local_results)) {
      local_results[[group_name]]
    } else {
      NULL
    }

    response <- .extract_catdes_textual_backend_response(
      result_group
    )

    if (!isTRUE(generated)) {
      groups[[group_name]] <- .empty_catdes_textual_profile(
        status = "prompt_ready",
        prompt = local_prompts[[group_name]]
      )
      next
    }

    if (is.null(response)) {
      groups[[group_name]] <- .empty_catdes_textual_profile(
        status = "generation_missing",
        prompt = local_prompts[[group_name]],
        backend_result = result_group,
        parse_issues = "missing_backend_response"
      )
      next
    }

    parsed <- .parse_catdes_textual_response(response)

    groups[[group_name]] <- c(
      parsed,
      list(
        prompt = local_prompts[[group_name]],
        response = response,
        backend_result = result_group
      )
    )
  }

  out <- list(
    groups = groups,
    settings = list(
      architecture = "catdes_anchor_textual_enrichment",
      local_first = TRUE,
      global_synthesis_performed = FALSE
    ),
    metadata = list(
      schema = "NaileR::catdes_textual_profiles",
      schema_version = "0.1.0",
      n_groups = as.integer(length(groups)),
      n_available = as.integer(sum(vapply(
        groups,
        function(group) identical(group$status, "available"),
        logical(1)
      ))),
      n_parse_failed = as.integer(sum(vapply(
        groups,
        function(group) identical(group$status, "parse_failed"),
        logical(1)
      )))
    )
  )

  class(out) <- c(
    "nail_catdes_textual_profiles",
    "list"
  )
  out
}


.combine_local_catdes_textual_results <- function(local_results,
                                                  combined_prompt,
                                                  model) {
  responses <- vapply(
    names(local_results),
    function(group_name) {
      response <- .extract_catdes_textual_backend_response(
        local_results[[group_name]]
      )

      if (is.null(response)) {
        response <- "No local CATDES-textual enrichment was generated."
      }

      paste0(
        "## Group \"",
        group_name,
        "\"\n\n",
        response
      )
    },
    character(1)
  )

  data.frame(
    model = model,
    created_at = Sys.time(),
    response = paste(responses, collapse = "\n\n"),
    done = TRUE,
    prompt = combined_prompt,
    stringsAsFactors = FALSE
  )
}


.catdes_textual_llm_responses <- function(local_results) {
  if (is.null(local_results) || length(local_results) == 0L) {
    return(NULL)
  }

  out <- lapply(
    local_results,
    .extract_catdes_textual_backend_response
  )
  keep <- !vapply(out, is.null, logical(1))
  out <- out[keep]

  if (length(out) == 0L) {
    return(NULL)
  }

  out
}


.attach_catdes_textual_artifacts <- function(result,
                                             contextualized_evidence,
                                             local_prompts,
                                             contextualized_profiles,
                                             settings,
                                             llm_io) {
  attr(result, "contextualized_evidence") <- contextualized_evidence
  attr(result, "local_prompts") <- local_prompts
  attr(result, "contextualized_profiles") <- contextualized_profiles
  attr(result, "catdes_textual_settings") <- settings
  attr(result, "llm_io") <- llm_io
  result
}


#' Enrich a CATDES group characterization with open-ended textual evidence
#'
#' `nail_catdes_textual()` takes the statistical characterization produced by
#' [nail_catdes()] as its anchor and enriches it with the canonical textual
#' profiles produced by [nail_textual()]. The two sources are deliberately not
#' treated symmetrically: CATDES characterizes the group statistically, while
#' open-ended responses provide a supplementary interpretive layer.
#'
#' @param catdes A result returned by [nail_catdes()]. It must carry canonical
#'   `semantic_facing_evidence`. The CATDES LLM interpretation itself is
#'   optional: mechanical CATDES facts remain the statistical anchor.
#' @param textual A result returned by the rebuilt [nail_textual()] with
#'   `generate = TRUE`. It must carry canonical `textual_evidence` and
#'   successfully parsed `textual_profiles`.
#' @param introduction Optional study context added to every local prompt.
#' @param request Optional analytical request. The default asks the LLM to use
#'   textual evidence to confirm, clarify, nuance, or supplement the CATDES
#'   characterization without rewriting the statistical evidence.
#' @param conclusion Optional output instruction. The default requests five
#'   structured fields: statistical anchor, textual enrichment, additional
#'   insights, internal diversity, and contextualized profile.
#' @param model Model name for the selected provider.
#' @param provider LLM backend, either `"ollama"` or `"gemini"`.
#' @param isolate.groups Logical. Contextualized interpretation is always
#'   performed locally one group at a time. If `TRUE`, return the named local
#'   prompts/results. If `FALSE`, preserve a combined outer return shape while
#'   still making one independent LLM call per group.
#' @param generate Logical. If `FALSE`, build the contextualized prompts without
#'   contacting a backend. If `TRUE`, generate one independent contextualized
#'   interpretation per group.
#' @param ... Provider-specific generation arguments passed to the selected
#'   backend.
#'
#' @details
#' The function never recomputes CATDES and never re-analyzes raw textual
#' responses. It consumes only canonical artifacts already produced by
#' [nail_catdes()] and [nail_textual()].
#'
#' The statistical side comes from `semantic_facing_evidence`, a mechanical
#' plain-language representation of selected CATDES facts. If a CATDES semantic
#' interpretation was generated upstream, it is shown separately as an existing
#' synthesis and never substitutes for the statistical facts.
#'
#' The textual side comes from the parsed `textual_profiles`. Representative and
#' tension text IDs are resolved back to exact texts through `textual_evidence`
#' so that the final enrichment remains inspectable and grounded.
#'
#' @return When `generate = FALSE`, a named list of local prompts when
#'   `isolate.groups = TRUE`, otherwise a combined local-first preview. When
#'   `generate = TRUE`, a named list of local backend results when
#'   `isolate.groups = TRUE`, otherwise a combined data frame. All returns carry
#'   `contextualized_evidence`, `local_prompts`, `contextualized_profiles`,
#'   `catdes_textual_settings`, and canonical `llm_io` attributes.
#'
#' @export
nail_catdes_textual <- function(catdes,
                                textual,
                                introduction = NULL,
                                request = NULL,
                                conclusion = NULL,
                                model = "llama3",
                                provider = c("ollama", "gemini"),
                                isolate.groups = TRUE,
                                generate = FALSE,
                                ...) {
  provider <- match.arg(provider)

  .validate_nail_catdes_textual_inputs(
    catdes = catdes,
    textual = textual,
    isolate.groups = isolate.groups,
    generate = generate
  )

  contextualized_evidence <- .build_catdes_textual_evidence(
    catdes = catdes,
    textual = textual
  )

  if (is.null(introduction)) {
    introduction <- .catdes_textual_default_introduction()
  }

  if (is.null(request)) {
    request <- .catdes_textual_default_request()
  }

  if (is.null(conclusion)) {
    conclusion <- .catdes_textual_default_conclusion()
  }

  local_prompts <- .build_local_catdes_textual_prompts(
    contextualized_evidence = contextualized_evidence,
    introduction = introduction,
    request = request,
    conclusion = conclusion
  )

  combined_prompt_preview <-
    .combine_local_catdes_textual_prompt_preview(
      local_prompts
    )

  settings <- list(
    architecture = "catdes_anchor_textual_enrichment",
    local_first = TRUE,
    global_synthesis_performed = FALSE,
    isolate_groups = isolate.groups,
    generate = generate,
    provider = provider,
    model = model,
    n_groups = as.integer(length(local_prompts)),
    llm_calls = if (isTRUE(generate)) {
      as.integer(length(local_prompts))
    } else {
      0L
    }
  )

  contextualized_profiles <- .build_catdes_textual_profiles(
    local_results = NULL,
    local_prompts = local_prompts,
    generated = FALSE
  )

  llm_io <- .new_nail_llm_io(
    stage = "contextualization",
    prompts = local_prompts,
    responses = NULL,
    metadata = list(
      analysis = "nail_catdes_textual",
      scope = "group",
      architecture = "catdes_anchor_textual_enrichment"
    )
  )

  if (!isTRUE(generate)) {
    result <- if (isTRUE(isolate.groups)) {
      local_prompts
    } else {
      combined_prompt_preview
    }

    return(.attach_catdes_textual_artifacts(
      result = result,
      contextualized_evidence = contextualized_evidence,
      local_prompts = local_prompts,
      contextualized_profiles = contextualized_profiles,
      settings = settings,
      llm_io = llm_io
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

  local_results <- lapply(local_prompts, call_llm)
  names(local_results) <- names(local_prompts)

  contextualized_profiles <- .build_catdes_textual_profiles(
    local_results = local_results,
    local_prompts = local_prompts,
    generated = TRUE
  )

  llm_io <- .new_nail_llm_io(
    stage = "contextualization",
    prompts = local_prompts,
    responses = .catdes_textual_llm_responses(
      local_results
    ),
    metadata = list(
      analysis = "nail_catdes_textual",
      scope = "group",
      architecture = "catdes_anchor_textual_enrichment"
    )
  )

  result <- if (isTRUE(isolate.groups)) {
    local_results
  } else {
    .combine_local_catdes_textual_results(
      local_results = local_results,
      combined_prompt = combined_prompt_preview,
      model = model
    )
  }

  .attach_catdes_textual_artifacts(
    result = result,
    contextualized_evidence = contextualized_evidence,
    local_prompts = local_prompts,
    contextualized_profiles = contextualized_profiles,
    settings = settings,
    llm_io = llm_io
  )
}
