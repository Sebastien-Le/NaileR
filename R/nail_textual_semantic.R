# ---------------------------------------------------------------------------
# Canonical textual evidence and semantic profiles
# ---------------------------------------------------------------------------

.build_textual_evidence <- function(dataset, num.var, num.text) {
  group_name <- names(dataset)[[num.var]]
  text_name <- names(dataset)[[num.text]]

  group_raw <- dataset[[num.var]]
  group_factor <- if (is.factor(group_raw)) {
    droplevels(group_raw)
  } else {
    factor(group_raw)
  }

  text_raw <- as.character(dataset[[num.text]])
  text_raw[is.na(text_raw)] <- ""
  text_raw <- trimws(text_raw)

  valid_group <- !is.na(group_factor)
  valid_text <- nzchar(text_raw)
  source_row <- seq_len(nrow(dataset))
  registry_rows <- valid_group & valid_text

  text_registry <- data.frame(
    text_id = sprintf("TXT%06d", source_row[registry_rows]),
    group = as.character(group_factor[registry_rows]),
    source_row = as.integer(source_row[registry_rows]),
    text = text_raw[registry_rows],
    stringsAsFactors = FALSE
  )

  group_names <- levels(group_factor)
  group_names <- group_names[
    vapply(
      group_names,
      function(g) any(valid_group & as.character(group_factor) == g),
      logical(1)
    )
  ]

  groups <- stats::setNames(vector("list", length(group_names)), group_names)

  for (g in group_names) {
    in_group <- valid_group & as.character(group_factor) == g
    reg_g <- text_registry[text_registry$group == g, , drop = FALSE]
    lengths <- nchar(reg_g$text)
    n_group_rows <- sum(in_group)
    n_texts <- nrow(reg_g)

    groups[[g]] <- list(
      group = g,
      text_ids = reg_g$text_id,
      metrics = list(
        n_group_rows = as.integer(n_group_rows),
        n_texts = as.integer(n_texts),
        response_rate = if (n_group_rows > 0L) {
          as.numeric(n_texts / n_group_rows)
        } else {
          NA_real_
        },
        n_unique_texts = as.integer(length(unique(reg_g$text))),
        total_chars = as.integer(sum(lengths)),
        median_chars = if (length(lengths) > 0L) {
          as.numeric(stats::median(lengths))
        } else {
          NA_real_
        }
      )
    )
  }

  out <- list(
    text_registry = text_registry,
    groups = groups,
    settings = list(
      grouping_variable = group_name,
      text_variable = text_name
    ),
    metadata = list(
      schema = "NaileR::textual_evidence",
      schema_version = "0.1.0",
      n_rows = as.integer(nrow(dataset)),
      n_groups = as.integer(length(groups)),
      n_texts = as.integer(nrow(text_registry))
    )
  )

  class(out) <- c("nail_textual_evidence", "list")
  out
}


.build_textual_compatibility_summary <- function(textual_evidence) {
  groups <- lapply(textual_evidence$groups, function(group) {
    ids <- group$text_ids
    registry <- textual_evidence$text_registry
    rows <- match(ids, registry$text_id)
    lengths <- nchar(registry$text[rows])
    n_texts <- length(ids)
    median_length <- if (length(lengths) > 0L) {
      stats::median(lengths)
    } else {
      NA_real_
    }

    list(
      n_texts = n_texts,
      median_length = median_length,
      max_length = if (length(lengths) > 0L) max(lengths) else NA_real_,
      min_length = if (length(lengths) > 0L) min(lengths) else NA_real_,
      evidence_strength = .textual_strength_label(
        n_texts = n_texts,
        median_length = median_length
      )
    )
  })

  names(groups) <- names(textual_evidence$groups)
  groups
}


.build_textual_interpretation_input <- function(textual_evidence,
                                                sample.pct = 1,
                                                seed = NULL) {
  group_names <- names(textual_evidence$groups)
  registry <- textual_evidence$text_registry

  groups <- .with_preserved_seed(seed, {
    out <- stats::setNames(vector("list", length(group_names)), group_names)

    for (g in group_names) {
      available_ids <- textual_evidence$groups[[g]]$text_ids
      n_available <- length(available_ids)

      selected_ids <- if (n_available == 0L) {
        character(0)
      } else if (sample.pct >= 1) {
        available_ids
      } else {
        n_selected <- max(1L, as.integer(round(n_available * sample.pct)))
        sample(available_ids, size = n_selected, replace = FALSE)
      }

      selected_texts <- if (length(selected_ids) == 0L) {
        registry[FALSE, , drop = FALSE]
      } else {
        registry[
          match(selected_ids, registry$text_id),
          ,
          drop = FALSE
        ]
      }

      n_shown <- length(selected_ids)

      out[[g]] <- list(
        group = g,
        status = if (n_available == 0L) "no_texts" else "ready",
        selected_text_ids = selected_ids,
        selected_texts = selected_texts,
        metrics = list(
          n_available_texts = as.integer(n_available),
          n_shown_texts = as.integer(n_shown),
          interpretation_coverage = if (n_available > 0L) {
            as.numeric(n_shown / n_available)
          } else {
            NA_real_
          }
        )
      )
    }

    out
  })

  out <- list(
    groups = groups,
    settings = list(
      sample_pct = sample.pct,
      seed = seed
    ),
    metadata = list(
      schema = "NaileR::textual_interpretation_input",
      schema_version = "0.1.0",
      n_groups = as.integer(length(groups)),
      n_ready_groups = as.integer(sum(vapply(
        groups,
        function(group) identical(group$status, "ready"),
        logical(1)
      )))
    )
  )

  class(out) <- c("nail_textual_interpretation_input", "list")
  out
}


.textual_default_introduction <- function() {
  paste(
    "For this study, observations are grouped by a categorical variable",
    "and each observation may contain an open-ended textual response.",
    "The grouping variable is supplied independently of this textual interpretation."
  )
}


.textual_default_request <- function(prompt_style = c("detailed", "compact")) {
  prompt_style <- match.arg(prompt_style)

  if (identical(prompt_style, "compact")) {
    return(paste(
      "Using only the texts shown for this group, characterize its discourse.",
      "Identify the main recurring themes, assess whether a common interpretive",
      "frame is present, and report meaningful internal diversity or tensions."
    ))
  }

  paste(
    "Using only the texts shown for this group, characterize its discourse.",
    "Identify the core textual profile and the dominant recurring themes.",
    "Assess whether a common interpretive frame structures the responses.",
    "Distinguish a shared frame with variations from the coexistence of several",
    "different frames, and report meaningful internal diversity or tensions.",
    "Stay close to the texts and do not infer hidden motives, personality traits,",
    "or attitudes that are not expressed in the corpus."
  )
}


.textual_canonical_conclusion <- function() {
  paste(
    "# Required output",
    "",
    "Your answer must contain exactly these fields and nothing else:",
    "",
    "Core textual profile:",
    "[One concise statement describing what mainly characterizes the discourse.]",
    "",
    "Dominant themes:",
    "[1 to 5 short themes separated by semicolons.]",
    "",
    "Within-group coherence:",
    "[Choose exactly one: strong / moderate / mixed / weak]",
    "",
    "Internal diversity:",
    "[One concise statement describing meaningful variations, tensions, minority positions, or the absence of clear internal diversity.]",
    "",
    "Representative text IDs:",
    "[1 to 3 supplied text IDs separated by semicolons.]",
    "",
    "Tension text IDs:",
    "[0 to 3 supplied text IDs separated by semicolons, or none.]",
    sep = "\n"
  )
}


.textual_semantic_guide <- function(prompt_style = c("detailed", "compact"),
                                    text_role = c("responses", "comments", "verbatims")) {
  prompt_style <- match.arg(prompt_style)
  text_role <- match.arg(text_role)
  unit <- .text_unit_word(text_role, plural = TRUE)

  core <- c(
    paste0("The evidence below consists of raw ", unit, "."),
    "Each displayed text has a mechanically assigned ID that refers to an exact observation.",
    "Do not assume that a statistical or observed group necessarily has a homogeneous discourse.",
    "Base the interpretation on recurring patterns across several texts.",
    "A shared discourse may consist of a common interpretive frame even when positions vary within that frame.",
    "Do not treat the absence of a theme as evidence that the group rejects or ignores it.",
    "Do not infer hidden motives, personality traits, or moral qualities.",
    "Representative and tension texts must be referenced only by supplied text IDs."
  )

  if (identical(prompt_style, "compact")) {
    core <- core[c(1, 2, 3, 4, 8)]
  }

  paste(core, collapse = "\n")
}


.textual_group_data_block <- function(textual_evidence,
                                      interpretation_input,
                                      group_name) {
  evidence_group <- textual_evidence$groups[[group_name]]
  input_group <- interpretation_input$groups[[group_name]]
  m <- evidence_group$metrics
  im <- input_group$metrics

  coverage_pct <- if (is.na(im$interpretation_coverage)) {
    "NA"
  } else {
    sprintf("%.1f%%", 100 * im$interpretation_coverage)
  }

  response_pct <- if (is.na(m$response_rate)) {
    "NA"
  } else {
    sprintf("%.1f%%", 100 * m$response_rate)
  }

  corpus_info <- paste(
    paste0("- Individuals/observations in group: ", m$n_group_rows),
    paste0("- Non-empty textual responses: ", m$n_texts),
    paste0("- Response coverage: ", response_pct),
    paste0("- Distinct textual responses: ", m$n_unique_texts),
    paste0("- Texts shown for this interpretation: ", im$n_shown_texts,
           " of ", im$n_available_texts, " (", coverage_pct, ")"),
    sep = "\n"
  )

  text_lines <- if (nrow(input_group$selected_texts) == 0L) {
    "*No non-empty texts are available for this group.*"
  } else {
    paste0(
      "[",
      input_group$selected_texts$text_id,
      "] ",
      input_group$selected_texts$text,
      collapse = "\n\n"
    )
  }

  paste0(
    "## Group \"", group_name, "\"\n\n",
    "### Corpus information\n\n",
    corpus_info,
    "\n\n### Texts\n\n",
    text_lines
  )
}


.build_local_textual_prompts <- function(textual_evidence,
                                         interpretation_input,
                                         introduction,
                                         request,
                                         conclusion,
                                         prompt_style,
                                         text_role) {
  group_names <- names(textual_evidence$groups)
  prompts <- stats::setNames(vector("list", length(group_names)), group_names)
  guide <- .textual_semantic_guide(
    prompt_style = prompt_style,
    text_role = text_role
  )

  for (g in group_names) {
    local_task <- if (identical(
      interpretation_input$groups[[g]]$status,
      "ready"
    )) {
      paste(
        "Interpret only the group shown below.",
        "Do not compare it with groups whose texts are not shown.",
        "Address the overall analytical request while respecting the evidence rules."
      )
    } else {
      paste(
        "This group has no non-empty textual response.",
        "Do not invent a textual profile for it."
      )
    }

    prompts[[g]] <- normalize_blank_lines(paste0(
      "# Introduction\n\n",
      introduction,
      "\n\n---\n\n## How to Read the Textual Evidence\n\n",
      guide,
      "\n\n# Overall Analytical Request\n\n",
      request,
      "\n\n# Local Task\n\n",
      local_task,
      "\n\n# Data\n\n",
      .textual_group_data_block(
        textual_evidence = textual_evidence,
        interpretation_input = interpretation_input,
        group_name = g
      ),
      "\n\n",
      conclusion
    ))
  }

  prompts
}


.combine_local_textual_prompt_preview <- function(local_prompts) {
  parts <- vapply(names(local_prompts), function(group_name) {
    paste0(
      "## Local prompt for group \"",
      group_name,
      "\"\n\n",
      local_prompts[[group_name]]
    )
  }, character(1))

  normalize_blank_lines(paste0(
    "# Local-first textual interpretation plan\n\n",
    "Each group will be interpreted independently. ",
    "No group receives texts from another group during this first semantic pass.\n\n",
    paste(parts, collapse = "\n\n---\n\n")
  ))
}


.extract_textual_backend_response <- function(result) {
  if (is.data.frame(result) &&
      "response" %in% names(result) &&
      nrow(result) > 0L) {
    return(as.character(result$response[[1L]]))
  }

  if (is.list(result) && !is.null(result$response)) {
    value <- result$response
    if (length(value) > 0L && !is.na(value[[1L]])) {
      return(as.character(value[[1L]]))
    }
  }

  NULL
}


.split_text_ids_textual <- function(x, allow_none = FALSE) {
  if (is.na(x) || !nzchar(trimws(x))) {
    return(character(0))
  }

  values <- unlist(strsplit(x, ";|,|\\n", perl = TRUE))
  values <- trimws(values)
  values <- gsub("^[-*+]\\s*", "", values)
  values <- gsub("^[[:punct:][:space:]]+", "", values)
  values <- gsub("[[:punct:][:space:]]+$", "", values)
  values <- trimws(values)
  values <- values[nzchar(values)]

  if (isTRUE(allow_none)) {
    none_tokens <- c("none", "no", "none identified")
    values <- values[!tolower(values) %in% none_tokens]
  }

  unique(values)
}


.normalize_textual_coherence <- function(x) {
  if (is.na(x) || !nzchar(trimws(x))) {
    return(NA_character_)
  }

  x <- tolower(trimws(x))

  for (level in c("strong", "moderate", "mixed", "weak")) {
    if (startsWith(x, level)) {
      return(level)
    }
  }

  NA_character_
}


.parse_textual_profile_response <- function(text, allowed_text_ids) {
  text <- paste(text, collapse = "\n")
  text <- gsub("\r\n", "\n", text, fixed = TRUE)
  text <- gsub("\r", "\n", text, fixed = TRUE)

  field_order <- c(
    "Core textual profile",
    "Dominant themes",
    "Within-group coherence",
    "Internal diversity",
    "Representative text IDs",
    "Tension text IDs"
  )

  get_block <- function(field) {
    index <- match(field, field_order)
    next_fields <- if (index < length(field_order)) {
      field_order[(index + 1L):length(field_order)]
    } else {
      NULL
    }

    .extract_field_block_textual(
      text,
      field,
      next_fields = next_fields
    )
  }

  core_textual_profile <- .clean_field_textual(
    get_block("Core textual profile")
  )
  dominant_themes <- .split_field_textual(
    get_block("Dominant themes")
  )
  within_group_coherence <- .normalize_textual_coherence(
    .clean_field_textual(get_block("Within-group coherence"))
  )
  internal_diversity <- .clean_field_textual(
    get_block("Internal diversity")
  )
  representative_text_ids <- .split_text_ids_textual(
    get_block("Representative text IDs")
  )
  tension_text_ids <- .split_text_ids_textual(
    get_block("Tension text IDs"),
    allow_none = TRUE
  )

  issues <- character(0)

  if (is.na(core_textual_profile)) {
    issues <- c(issues, "missing_core_textual_profile")
  }
  if (length(dominant_themes) == 0L) {
    issues <- c(issues, "missing_dominant_themes")
  }
  if (is.na(within_group_coherence)) {
    issues <- c(issues, "invalid_within_group_coherence")
  }
  if (is.na(internal_diversity)) {
    issues <- c(issues, "missing_internal_diversity")
  }
  if (length(representative_text_ids) == 0L) {
    issues <- c(issues, "missing_representative_text_ids")
  }

  invalid_representative <- setdiff(
    representative_text_ids,
    allowed_text_ids
  )
  invalid_tension <- setdiff(
    tension_text_ids,
    allowed_text_ids
  )

  if (length(invalid_representative) > 0L) {
    issues <- c(issues, "unknown_representative_text_ids")
  }
  if (length(invalid_tension) > 0L) {
    issues <- c(issues, "unknown_tension_text_ids")
  }

  list(
    status = if (length(issues) == 0L) "available" else "parse_failed",
    core_textual_profile = core_textual_profile,
    dominant_themes = dominant_themes,
    within_group_coherence = within_group_coherence,
    internal_diversity = internal_diversity,
    representative_text_ids = representative_text_ids,
    tension_text_ids = tension_text_ids,
    parse_issues = unique(issues)
  )
}


.empty_textual_profile <- function(status,
                                   prompt,
                                   selected_text_ids,
                                   response = NULL,
                                   backend_result = NULL,
                                   parse_issues = character(0)) {
  list(
    status = status,
    core_textual_profile = NA_character_,
    dominant_themes = character(0),
    within_group_coherence = NA_character_,
    internal_diversity = NA_character_,
    representative_text_ids = character(0),
    tension_text_ids = character(0),
    parse_issues = parse_issues,
    selected_text_ids = selected_text_ids,
    prompt = prompt,
    response = response,
    backend_result = backend_result
  )
}


.build_textual_profiles <- function(local_results,
                                    local_prompts,
                                    interpretation_input,
                                    generated) {
  group_names <- names(interpretation_input$groups)
  groups <- stats::setNames(vector("list", length(group_names)), group_names)

  for (g in group_names) {
    input_group <- interpretation_input$groups[[g]]
    result_group <- if (!is.null(local_results)) local_results[[g]] else NULL
    response <- .extract_textual_backend_response(result_group)

    if (identical(input_group$status, "no_texts")) {
      groups[[g]] <- .empty_textual_profile(
        status = "no_texts",
        prompt = local_prompts[[g]],
        selected_text_ids = character(0),
        response = response,
        backend_result = result_group
      )
      next
    }

    if (!isTRUE(generated)) {
      groups[[g]] <- .empty_textual_profile(
        status = "prompt_ready",
        prompt = local_prompts[[g]],
        selected_text_ids = input_group$selected_text_ids
      )
      next
    }

    if (is.null(response)) {
      groups[[g]] <- .empty_textual_profile(
        status = "generation_missing",
        prompt = local_prompts[[g]],
        selected_text_ids = input_group$selected_text_ids,
        backend_result = result_group,
        parse_issues = "missing_backend_response"
      )
      next
    }

    parsed <- .parse_textual_profile_response(
      response,
      allowed_text_ids = input_group$selected_text_ids
    )

    groups[[g]] <- c(
      parsed,
      list(
        selected_text_ids = input_group$selected_text_ids,
        prompt = local_prompts[[g]],
        response = response,
        backend_result = result_group
      )
    )
  }

  out <- list(
    groups = groups,
    settings = list(
      architecture = "local_first",
      global_synthesis_performed = FALSE
    ),
    metadata = list(
      schema = "NaileR::textual_profiles",
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

  class(out) <- c("nail_textual_profiles", "list")
  out
}


.textual_no_results_data_frame <- function(model, prompt, group_name) {
  data.frame(
    model = model,
    created_at = Sys.time(),
    response = paste0(
      "No textual data found for group '",
      group_name,
      "'."
    ),
    done = TRUE,
    prompt = prompt,
    stringsAsFactors = FALSE
  )
}


.combine_local_textual_results <- function(local_results,
                                           combined_prompt,
                                           model) {
  responses <- vapply(names(local_results), function(group_name) {
    response <- .extract_textual_backend_response(
      local_results[[group_name]]
    )

    if (is.null(response)) {
      response <- "No local textual interpretation was generated."
    }

    paste0(
      "## Group \"",
      group_name,
      "\"\n\n",
      response
    )
  }, character(1))

  data.frame(
    model = model,
    created_at = Sys.time(),
    response = paste(responses, collapse = "\n\n"),
    done = TRUE,
    prompt = combined_prompt,
    stringsAsFactors = FALSE
  )
}


.textual_llm_responses <- function(local_results,
                                             interpretation_input) {
  if (is.null(local_results) || length(local_results) == 0L) {
    return(NULL)
  }

  ready_names <- names(interpretation_input$groups)[
    vapply(
      interpretation_input$groups,
      function(group) identical(group$status, "ready"),
      logical(1)
    )
  ]

  if (length(ready_names) == 0L) {
    return(NULL)
  }

  out <- lapply(
    local_results[ready_names],
    .extract_textual_backend_response
  )
  keep <- !vapply(out, is.null, logical(1))
  out <- out[keep]

  if (length(out) == 0L) {
    return(NULL)
  }

  out
}


.attach_nail_textual_artifacts <- function(result,
                                           textual_evidence,
                                           interpretation_input,
                                           local_prompts,
                                           textual_profiles,
                                           textual_settings,
                                           textual_data_summary,
                                           llm_io) {
  attr(result, "textual_evidence") <- textual_evidence
  attr(result, "interpretation_input") <- interpretation_input
  attr(result, "local_prompts") <- local_prompts
  attr(result, "textual_profiles") <- textual_profiles
  attr(result, "textual_settings") <- textual_settings
  attr(result, "textual_data_summary") <- textual_data_summary
  attr(result, "llm_io") <- llm_io
  result
}
