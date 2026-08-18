# ---------------------------------------------------------------------------
# nail_textual_contextualized(): traceable statistical-textual integration
# ---------------------------------------------------------------------------

.contextualized_scopes <- c(
  "general",
  "sociological",
  "consumer",
  "psychological",
  "marketing",
  "innovation",
  "cross_functional"
)

.contextualized_comparison_modes <- c("joint", "isolated")
.contextualized_report_formats <- c("structured", "markdown", "compact")
.contextualized_statuses <- c(
  "expert_interpretation",
  "hypothesis",
  "recommendation",
  "user_context"
)
.contextualized_relationships <- c(
  "complement",
  "nuance",
  "tension",
  "apparent_divergence",
  "direct_contradiction"
)

.contextualized_group_fields <- c(
  "group",
  "availability",
  "parse_error",
  "integrated_profile",
  "statistical_textual_convergences",
  "statistical_textual_divergences",
  "statistical_only_findings",
  "textual_only_findings",
  "social_interpretations",
  "consumer_insights",
  "psychological_hypotheses",
  "marketing_implications",
  "innovation_opportunities",
  "operational_implications",
  "validation_priorities",
  "interpretation_limits"
)

.contextualized_cross_fields <- c(
  "shared_patterns",
  "major_group_contrasts",
  "different_statistical_textual_relationships",
  "cross_group_social_interpretations",
  "consumer_segments_hypotheses",
  "psychological_mechanisms_hypotheses",
  "marketing_priorities",
  "innovation_priorities",
  "validation_priorities",
  "interpretation_limits"
)

.contextualized_claim_fields <- c(
  "text",
  "status",
  "statistical_evidence_ids",
  "textual_evidence_ids",
  "relationship",
  "quotations",
  "validation_needed"
)

.contextualized_quote_fields <- c("evidence_id", "quotation")

.contextualized_is_scalar_string <- function(x, allow_empty = FALSE) {
  is.character(x) && length(x) == 1L && !is.na(x) &&
    (allow_empty || nzchar(trimws(x)))
}

.contextualized_as_character_vector <- function(x, field) {
  if (is.null(x) || length(x) == 0L) return(character(0))
  if (is.list(x) && !is.data.frame(x)) {
    x <- unlist(x, recursive = TRUE, use.names = FALSE)
  }
  if (!is.atomic(x)) {
    stop(sprintf("`%s` must be a character array.", field), call. = FALSE)
  }
  x <- as.character(x)
  x <- x[!is.na(x) & nzchar(trimws(x))]
  unname(x)
}

.contextualized_validate_context <- function(context) {
  if (is.null(context)) return(list())
  if (is.character(context) && length(context) == 1L && !is.na(context)) {
    return(list(general = context))
  }
  if (!is.list(context) || is.data.frame(context)) {
    stop("`context` must be NULL, a character scalar, or a named list.", call. = FALSE)
  }
  if (length(context) > 0L &&
      (is.null(names(context)) || any(is.na(names(context))) || any(!nzchar(names(context))))) {
    stop("`context` must be a named list.", call. = FALSE)
  }
  context
}

.contextualized_escape_id_component <- function(x, fallback = "unknown") {
  if (length(x) == 0L || is.na(x) || !nzchar(as.character(x))) {
    x <- fallback
  }
  x <- as.character(x)
  x <- gsub("%", "%25", x, fixed = TRUE)
  gsub("::", "%3A%3A", x, fixed = TRUE)
}

.contextualized_records <- function(x) {
  if (is.null(x) || !is.data.frame(x) || nrow(x) == 0L) return(list())
  unname(lapply(seq_len(nrow(x)), function(i) {
    row <- x[i, , drop = FALSE]
    out <- lapply(row, function(value) {
      if (is.list(value) && length(value) == 1L) return(value[[1L]])
      value <- value[[1L]]
      if (length(value) == 0L || is.na(value)) NULL else unname(value)
    })
    names(out) <- names(row)
    out
  }))
}

.contextualized_deprecation_warning <- function(argument, replacement = NULL) {
  message <- if (is.null(replacement)) {
    sprintf("`%s` is deprecated in `nail_textual_contextualized()`.", argument)
  } else {
    sprintf("`%s` is deprecated; use `%s`.", argument, replacement)
  }
  warning(message, call. = FALSE)
}

.contextualized_empty_stat_registry <- function() {
  data.frame(
    evidence_id = character(0),
    group = character(0),
    marker_type = character(0),
    variable = character(0),
    modality = character(0),
    direction = character(0),
    direction_basis = character(0),
    v_test = numeric(0),
    p_value = numeric(0),
    abs_v_test = numeric(0),
    rank = integer(0),
    source = character(0),
    source_row = integer(0),
    stringsAsFactors = FALSE,
    check.names = FALSE
  )
}

.contextualized_empty_text_registry <- function() {
  data.frame(
    evidence_id = character(0),
    group = character(0),
    row_index = integer(0),
    original_text = character(0),
    character_count = integer(0),
    word_count = integer(0),
    text_status = character(0),
    missing_or_empty = logical(0),
    included_in_prompt = logical(0),
    sampling_rank = integer(0),
    exclusion_reason = character(0),
    source = character(0),
    stringsAsFactors = FALSE,
    check.names = FALSE
  )
}

.contextualized_validate_statistical_profiles <- function(x) {
  if (!is.list(x) || !is.list(x$groups) || !is.data.frame(x$evidence_registry)) {
    stop(
      paste(
        "The statistical source must contain `groups` and a data-frame",
        "`evidence_registry`, as returned by `nail_catdes_prep()`."
      ),
      call. = FALSE
    )
  }
  if (is.null(names(x$groups)) || any(!nzchar(names(x$groups))) || anyDuplicated(names(x$groups))) {
    stop("Statistical groups must have unique, non-empty names.", call. = FALSE)
  }
  required <- c(
    "evidence_id", "group", "marker_type", "variable", "modality",
    "direction", "v_test", "p_value", "rank", "source"
  )
  missing_fields <- setdiff(required, names(x$evidence_registry))
  if (length(missing_fields) > 0L) {
    stop(
      sprintf(
        "The statistical evidence registry is missing: %s.",
        paste(missing_fields, collapse = ", ")
      ),
      call. = FALSE
    )
  }
  if (anyDuplicated(x$evidence_registry$evidence_id)) {
    stop("The statistical evidence registry contains duplicated evidence IDs.", call. = FALSE)
  }
  unknown_groups <- setdiff(unique(x$evidence_registry$group), names(x$groups))
  unknown_groups <- unknown_groups[!is.na(unknown_groups) & nzchar(unknown_groups)]
  if (length(unknown_groups) > 0L) {
    stop("The statistical evidence registry refers to unknown groups.", call. = FALSE)
  }
  x
}

.contextualized_legacy_statistical_profiles <- function(x) {
  if (!is.list(x) || length(x) == 0L || is.null(names(x))) return(NULL)
  ok <- vapply(
    x,
    function(el) is.list(el) && !is.null(el$parsed) && is.list(el$parsed),
    logical(1)
  )
  if (!all(ok)) return(NULL)

  groups <- lapply(names(x), function(group_name) {
    list(
      group = group_name,
      qualitative_markers = data.frame(),
      quantitative_markers = data.frame(),
      positive_markers = data.frame(),
      negative_markers = data.frame(),
      metrics = list(),
      evidence_ids = character(0),
      factual_summary = NA_character_,
      legacy_summary = x[[group_name]]$parsed
    )
  })
  names(groups) <- names(x)

  out <- list(
    groups = groups,
    evidence_registry = .contextualized_empty_stat_registry(),
    settings = list(legacy = TRUE),
    metadata = list(
      schema = "NaileR::legacy_statistical_profiles",
      source = "legacy_contextualized_input"
    )
  )
  class(out) <- c("statistical_profiles", "list")
  out
}

.normalize_contextualized_statistical_input <- function(x) {
  if (is.null(x)) {
    stop("A statistical source is required.", call. = FALSE)
  }

  if (inherits(x, "statistical_profiles") ||
      (is.list(x) && is.list(x$groups) && is.data.frame(x$evidence_registry))) {
    return(.contextualized_validate_statistical_profiles(x))
  }

  if (inherits(x, "nail_catdes") &&
      is.list(x$preparation) &&
      !is.null(x$preparation$statistical_profiles)) {
    return(.contextualized_validate_statistical_profiles(
      x$preparation$statistical_profiles
    ))
  }

  if (is.list(x) && !is.null(x$statistical_profiles)) {
    return(.contextualized_validate_statistical_profiles(x$statistical_profiles))
  }

  attached <- attr(x, "statistical_profiles", exact = TRUE)
  if (!is.null(attached)) {
    return(.contextualized_validate_statistical_profiles(attached))
  }

  catdes_result <- attr(x, "catdes_result", exact = TRUE)
  if (!is.null(catdes_result) && exists(".build_statistical_profiles_catdesprep", mode = "function")) {
    normalized <- .build_statistical_profiles_catdesprep(
      catdes_result = catdes_result,
      group_names = unique(c(names(catdes_result$category), names(catdes_result$quanti))),
      input_metadata = list(source = "catdes_result_attribute"),
      proba = NA_real_
    )
    return(.contextualized_validate_statistical_profiles(normalized))
  }

  legacy <- .contextualized_legacy_statistical_profiles(x)
  if (!is.null(legacy)) return(legacy)

  stop(
    paste(
      "The statistical source must be a `statistical_profiles` object,",
      "an object carrying a `statistical_profiles` attribute, or a supported legacy object."
    ),
    call. = FALSE
  )
}

.contextualized_validate_textual_evidence <- function(x) {
  if (!is.list(x) || !is.list(x$groups) || !is.data.frame(x$evidence_registry)) {
    stop(
      paste(
        "The textual source must contain a valid `textual_evidence` object",
        "with `groups` and an `evidence_registry`."
      ),
      call. = FALSE
    )
  }
  if (is.null(names(x$groups)) || any(!nzchar(names(x$groups))) || anyDuplicated(names(x$groups))) {
    stop("Textual evidence groups must have unique, non-empty names.", call. = FALSE)
  }
  required <- c(
    "evidence_id", "group", "row_index", "original_text",
    "included_in_prompt", "source"
  )
  missing_fields <- setdiff(required, names(x$evidence_registry))
  if (length(missing_fields) > 0L) {
    stop(
      sprintf(
        "The textual evidence registry is missing: %s.",
        paste(missing_fields, collapse = ", ")
      ),
      call. = FALSE
    )
  }
  if (anyDuplicated(x$evidence_registry$evidence_id)) {
    stop("The textual evidence registry contains duplicated evidence IDs.", call. = FALSE)
  }
  x
}

.contextualized_extract_textual_unit_status <- function(x) {
  if (is.null(x$units) || length(x$units) == 0L) return(list())
  lapply(x$units, function(unit) {
    parsed <- unit$parsed
    list(
      groups = if (is.null(unit$groups)) character(0) else as.character(unit$groups),
      parse_status = if (is.null(parsed$parse_status)) NA_character_ else as.character(parsed$parse_status),
      parse_error = if (is.null(parsed$parse_error)) NULL else as.character(parsed$parse_error)
    )
  })
}

.contextualized_legacy_textual_input <- function(x) {
  if (!is.list(x) || length(x) == 0L || is.null(names(x))) return(NULL)
  ok <- vapply(
    x,
    function(el) is.list(el) && !is.null(el$parsed) && is.list(el$parsed),
    logical(1)
  )
  if (!all(ok)) return(NULL)

  profiles <- lapply(names(x), function(group_name) {
    parsed <- x[[group_name]]$parsed
    parsed$group <- group_name
    parsed
  })
  names(profiles) <- names(x)

  list(
    textual_evidence = NULL,
    textual_profiles = list(
      groups = profiles,
      cross_group = NULL,
      metadata = list(
        schema = "NaileR::legacy_textual_profiles",
        comparison_mode = "unknown",
        analysis_scope = "unknown"
      )
    ),
    preparation = x,
    preparation_metadata = list(legacy = TRUE),
    generation_status = "legacy_unverified",
    unit_status = list(),
    legacy = TRUE
  )
}

.normalize_contextualized_textual_input <- function(x) {
  if (is.null(x)) {
    stop("A textual source is required.", call. = FALSE)
  }

  if (inherits(x, "nail_textual") && is.list(x$preparation)) {
    x <- x$preparation
  }

  if (inherits(x, "nail_textual_prep") ||
      (is.list(x) && "textual_evidence" %in% names(x) && "metadata" %in% names(x))) {
    evidence <- .contextualized_validate_textual_evidence(x$textual_evidence)
    profiles <- x$textual_profiles
    if (!is.null(profiles) && (!is.list(profiles) || !is.list(profiles$groups))) {
      stop("`textual_profiles` must be NULL or contain a named `groups` list.", call. = FALSE)
    }
    if (!is.null(profiles) &&
        (is.null(names(profiles$groups)) || anyDuplicated(names(profiles$groups)))) {
      stop("Textual profile groups must have unique names.", call. = FALSE)
    }
    return(list(
      textual_evidence = evidence,
      textual_profiles = profiles,
      preparation = x,
      preparation_metadata = x$metadata,
      generation_status = if (is.null(x$parsed$parse_status)) {
        if (is.null(profiles)) "unknown" else "success"
      } else {
        as.character(x$parsed$parse_status)
      },
      unit_status = .contextualized_extract_textual_unit_status(x),
      legacy = FALSE
    ))
  }

  if (is.list(x) && !is.null(x$textual_evidence)) {
    evidence <- .contextualized_validate_textual_evidence(x$textual_evidence)
    profiles <- x$textual_profiles
    if (!is.null(profiles) && (!is.list(profiles) || !is.list(profiles$groups))) {
      stop("`textual_profiles` must be NULL or contain a named `groups` list.", call. = FALSE)
    }
    return(list(
      textual_evidence = evidence,
      textual_profiles = profiles,
      preparation = x,
      preparation_metadata = if (is.null(x$metadata)) list() else x$metadata,
      generation_status = if (is.null(profiles)) "not_generated" else "success",
      unit_status = .contextualized_extract_textual_unit_status(x),
      legacy = FALSE
    ))
  }

  evidence <- attr(x, "textual_evidence", exact = TRUE)
  profiles <- attr(x, "textual_profiles", exact = TRUE)
  if (!is.null(evidence)) {
    evidence <- .contextualized_validate_textual_evidence(evidence)
    return(list(
      textual_evidence = evidence,
      textual_profiles = profiles,
      preparation = x,
      preparation_metadata = list(source = "attributes"),
      generation_status = if (is.null(profiles)) "not_generated" else "success",
      unit_status = list(),
      legacy = FALSE
    ))
  }

  legacy <- .contextualized_legacy_textual_input(x)
  if (!is.null(legacy)) return(legacy)

  stop(
    paste(
      "The textual source must be a `nail_textual_prep` result, a `nail_textual`",
      "result containing its preparation, an explicit evidence/profile object,",
      "or a supported legacy object."
    ),
    call. = FALSE
  )
}

.contextualized_validate_group_map <- function(group_map) {
  if (is.null(group_map)) return(stats::setNames(character(0), character(0)))
  if (is.list(group_map) && !is.data.frame(group_map)) {
    group_map <- unlist(group_map, recursive = FALSE, use.names = TRUE)
  }
  if (!is.character(group_map) || is.null(names(group_map))) {
    stop("`group_map` must be a named character vector: statistical = textual.", call. = FALSE)
  }
  if (length(group_map) > 0L &&
      (any(is.na(names(group_map))) || any(!nzchar(names(group_map))) ||
       any(is.na(group_map)) || any(!nzchar(group_map)))) {
    stop("`group_map` names and values must be non-empty.", call. = FALSE)
  }
  if (anyDuplicated(names(group_map))) {
    stop("`group_map` contains duplicated statistical group names.", call. = FALSE)
  }
  if (anyDuplicated(unname(group_map))) {
    stop("`group_map` maps several statistical groups to the same textual group.", call. = FALSE)
  }
  group_map
}

.build_contextualized_group_alignment <- function(statistical_profiles,
                                                  textual_input,
                                                  group_map = NULL) {
  group_map <- .contextualized_validate_group_map(group_map)
  stat_groups <- sort(names(statistical_profiles$groups))

  evidence_groups <- if (is.null(textual_input$textual_evidence)) {
    character(0)
  } else {
    names(textual_input$textual_evidence$groups)
  }
  profile_groups <- if (is.null(textual_input$textual_profiles)) {
    character(0)
  } else {
    names(textual_input$textual_profiles$groups)
  }
  text_groups <- sort(unique(c(evidence_groups, profile_groups)))

  unknown_stat <- setdiff(names(group_map), stat_groups)
  unknown_text <- setdiff(unname(group_map), text_groups)
  if (length(unknown_stat) > 0L) {
    stop(
      sprintf("`group_map` refers to unknown statistical group(s): %s.", paste(unknown_stat, collapse = ", ")),
      call. = FALSE
    )
  }
  if (length(unknown_text) > 0L) {
    stop(
      sprintf("`group_map` refers to unknown textual group(s): %s.", paste(unknown_text, collapse = ", ")),
      call. = FALSE
    )
  }

  used_text <- character(0)
  rows <- list()
  k <- 0L

  for (stat_group in stat_groups) {
    text_group <- if (stat_group %in% names(group_map)) {
      unname(group_map[[stat_group]])
    } else if (stat_group %in% text_groups) {
      stat_group
    } else {
      NA_character_
    }

    if (!is.na(text_group)) {
      if (text_group %in% used_text) {
        stop("The group alignment is ambiguous because a textual group is used more than once.", call. = FALSE)
      }
      used_text <- c(used_text, text_group)
    }

    has_evidence <- !is.na(text_group) && text_group %in% evidence_groups
    has_profile <- !is.na(text_group) && text_group %in% profile_groups
    status <- if (has_evidence && has_profile) {
      "matched"
    } else if (has_evidence && !has_profile) {
      "matched_without_textual_profile"
    } else if (!has_evidence && has_profile) {
      "matched_profile_without_textual_evidence"
    } else {
      "statistical_only"
    }

    k <- k + 1L
    rows[[k]] <- data.frame(
      canonical_group = stat_group,
      statistical_group = stat_group,
      textual_group = text_group,
      has_statistical_profile = TRUE,
      has_textual_evidence = has_evidence,
      has_textual_profile = has_profile,
      alignment_status = status,
      alignment_basis = if (!is.na(text_group) && stat_group %in% names(group_map)) {
        "manual_map"
      } else if (!is.na(text_group)) {
        "exact_name"
      } else {
        "unmatched"
      },
      stringsAsFactors = FALSE,
      check.names = FALSE
    )
  }

  remaining_text <- setdiff(text_groups, used_text)
  for (text_group in remaining_text) {
    has_evidence <- text_group %in% evidence_groups
    has_profile <- text_group %in% profile_groups
    status <- if (has_evidence && has_profile) {
      "textual_only"
    } else if (has_evidence) {
      "textual_evidence_only"
    } else {
      "textual_profile_only"
    }
    k <- k + 1L
    rows[[k]] <- data.frame(
      canonical_group = text_group,
      statistical_group = NA_character_,
      textual_group = text_group,
      has_statistical_profile = FALSE,
      has_textual_evidence = has_evidence,
      has_textual_profile = has_profile,
      alignment_status = status,
      alignment_basis = "unmatched",
      stringsAsFactors = FALSE,
      check.names = FALSE
    )
  }

  if (length(rows) == 0L) {
    stop("No statistical or textual group could be identified.", call. = FALSE)
  }

  alignment <- do.call(rbind, rows)
  alignment <- alignment[order(alignment$canonical_group), , drop = FALSE]
  rownames(alignment) <- NULL
  if (anyDuplicated(alignment$canonical_group)) {
    stop("The group alignment produced duplicated canonical group names.", call. = FALSE)
  }
  alignment
}

.contextualized_unit_error_for_group <- function(textual_input, textual_group) {
  if (is.na(textual_group) || length(textual_input$unit_status) == 0L) return(NULL)
  hits <- Filter(
    function(x) textual_group %in% x$groups && identical(x$parse_status, "error"),
    textual_input$unit_status
  )
  if (length(hits) == 0L) return(NULL)
  unique(vapply(hits, function(x) x$parse_error, character(1)))[[1L]]
}

.contextualized_group_diagnostics <- function(textual_evidence, textual_group) {
  if (is.null(textual_evidence) || is.na(textual_group)) return(NULL)
  diagnostics <- textual_evidence$group_diagnostics
  if (is.null(diagnostics) || !is.data.frame(diagnostics) || !"group" %in% names(diagnostics)) {
    group_obj <- textual_evidence$groups[[textual_group]]
    return(if (is.null(group_obj)) NULL else group_obj$diagnostics)
  }
  out <- diagnostics[diagnostics$group == textual_group, , drop = FALSE]
  if (nrow(out) == 0L) NULL else out
}

.contextualized_build_group_limits <- function(alignment_row,
                                               textual_input,
                                               diagnostics) {
  limits <- character(0)
  if (!isTRUE(alignment_row$has_statistical_profile[[1L]])) {
    limits <- c(limits, "No statistical profile is available for this group.")
  }
  if (!isTRUE(alignment_row$has_textual_evidence[[1L]])) {
    limits <- c(limits, "No traceable textual evidence is available for this group.")
  }
  if (!isTRUE(alignment_row$has_textual_profile[[1L]])) {
    limits <- c(
      limits,
      "Textual evidence may be available, but no validated textual profile is available for this group."
    )
  }

  if (!is.null(diagnostics) && is.data.frame(diagnostics) && nrow(diagnostics) > 0L) {
    if ("n_non_empty" %in% names(diagnostics) && diagnostics$n_non_empty[[1L]] == 0L) {
      limits <- c(limits, "The group contains no non-empty verbatim.")
    }
    if ("n_included_in_prompt" %in% names(diagnostics) && diagnostics$n_included_in_prompt[[1L]] == 0L) {
      limits <- c(limits, "No verbatim from this group was included in the textual prompt.")
    }
    if ("sampling_fraction" %in% names(diagnostics) &&
        is.finite(diagnostics$sampling_fraction[[1L]]) &&
        diagnostics$sampling_fraction[[1L]] < 1) {
      limits <- c(
        limits,
        paste0(
          "Only ", diagnostics$n_included_in_prompt[[1L]], " of ",
          diagnostics$n_non_empty[[1L]],
          " non-empty verbatims were included in the textual prompt."
        )
      )
    }
    if ("n_prompt_budget" %in% names(diagnostics) && diagnostics$n_prompt_budget[[1L]] > 0L) {
      limits <- c(
        limits,
        paste0(
          diagnostics$n_prompt_budget[[1L]],
          " verbatim(s) were excluded by the prompt character budget."
        )
      )
    }
  }

  parse_error <- .contextualized_unit_error_for_group(
    textual_input,
    alignment_row$textual_group[[1L]]
  )
  if (!is.null(parse_error)) {
    limits <- c(limits, paste0("The textual profile could not be parsed: ", parse_error))
  }
  unique(limits)
}

.contextualized_empty_combined_registry <- function() {
  out <- data.frame(
    evidence_id = character(0),
    evidence_type = character(0),
    group = character(0),
    source_group = character(0),
    source = character(0),
    subtype = character(0),
    variable = character(0),
    modality = character(0),
    direction = character(0),
    statistic = numeric(0),
    p_value = numeric(0),
    v_test = numeric(0),
    original_text = character(0),
    interpretation_text = character(0),
    row_index = integer(0),
    included_in_prompt = logical(0),
    availability = logical(0),
    stringsAsFactors = FALSE,
    check.names = FALSE
  )
  out$grounding_evidence_ids <- I(list())
  out
}

.contextualized_registry_piece <- function(n) {
  out <- data.frame(
    evidence_id = rep(NA_character_, n),
    evidence_type = rep(NA_character_, n),
    group = rep(NA_character_, n),
    source_group = rep(NA_character_, n),
    source = rep(NA_character_, n),
    subtype = rep(NA_character_, n),
    variable = rep(NA_character_, n),
    modality = rep(NA_character_, n),
    direction = rep(NA_character_, n),
    statistic = rep(NA_real_, n),
    p_value = rep(NA_real_, n),
    v_test = rep(NA_real_, n),
    original_text = rep(NA_character_, n),
    interpretation_text = rep(NA_character_, n),
    row_index = rep(NA_integer_, n),
    included_in_prompt = rep(NA, n),
    availability = rep(TRUE, n),
    stringsAsFactors = FALSE,
    check.names = FALSE
  )
  out$grounding_evidence_ids <- I(rep(list(character(0)), n))
  out
}

.contextualized_statistical_registry_piece <- function(registry) {
  if (is.null(registry) || nrow(registry) == 0L) {
    return(.contextualized_empty_combined_registry())
  }
  out <- .contextualized_registry_piece(nrow(registry))
  out$evidence_id <- as.character(registry$evidence_id)
  out$evidence_type <- ifelse(
    registry$marker_type == "qualitative",
    "statistical_qualitative",
    "statistical_quantitative"
  )
  out$group <- as.character(registry$group)
  out$source_group <- as.character(registry$group)
  out$source <- as.character(registry$source)
  out$subtype <- as.character(registry$marker_type)
  out$variable <- as.character(registry$variable)
  out$modality <- as.character(registry$modality)
  out$direction <- as.character(registry$direction)
  out$statistic <- as.numeric(registry$v_test)
  out$p_value <- as.numeric(registry$p_value)
  out$v_test <- as.numeric(registry$v_test)
  out$included_in_prompt <- NA
  out
}

.contextualized_textual_registry_piece <- function(registry) {
  if (is.null(registry) || nrow(registry) == 0L) {
    return(.contextualized_empty_combined_registry())
  }
  out <- .contextualized_registry_piece(nrow(registry))
  out$evidence_id <- as.character(registry$evidence_id)
  out$evidence_type <- "textual_verbatim"
  out$group <- as.character(registry$group)
  out$source_group <- as.character(registry$group)
  out$source <- as.character(registry$source)
  out$subtype <- "verbatim"
  out$original_text <- as.character(registry$original_text)
  out$row_index <- as.integer(registry$row_index)
  out$included_in_prompt <- as.logical(registry$included_in_prompt)
  out$availability <- !is.na(registry$original_text)
  out
}

.contextualized_is_textual_claim <- function(x) {
  is.list(x) && !is.data.frame(x) &&
    all(c("text", "status", "evidence_ids") %in% names(x))
}

.contextualized_collect_profile_claims <- function(profile,
                                                   group_name,
                                                   prefix = NULL) {
  records <- list()
  index <- 0L

  recurse <- function(x, path) {
    if (.contextualized_is_textual_claim(x)) {
      index <<- index + 1L
      records[[index]] <<- list(path = path, claim = x)
      return(invisible(NULL))
    }
    if (!is.list(x) || is.data.frame(x) || length(x) == 0L) return(invisible(NULL))
    nms <- names(x)
    for (i in seq_along(x)) {
      component <- if (!is.null(nms) && nzchar(nms[[i]])) nms[[i]] else as.character(i)
      recurse(x[[i]], c(path, component))
    }
    invisible(NULL)
  }

  recurse(profile, if (is.null(prefix)) character(0) else prefix)
  records
}

.contextualized_interpretation_registry_piece <- function(textual_profiles) {
  if (is.null(textual_profiles) || !is.list(textual_profiles$groups)) {
    return(.contextualized_empty_combined_registry())
  }

  records <- list()
  k <- 0L
  for (group_name in sort(names(textual_profiles$groups))) {
    claims <- .contextualized_collect_profile_claims(
      textual_profiles$groups[[group_name]],
      group_name
    )
    for (item in claims) {
      k <- k + 1L
      field <- paste(item$path, collapse = "__")
      records[[k]] <- list(
        group = group_name,
        field = field,
        claim = item$claim
      )
    }
  }

  if (!is.null(textual_profiles$cross_group)) {
    claims <- .contextualized_collect_profile_claims(
      textual_profiles$cross_group,
      "__cross_group__"
    )
    for (item in claims) {
      k <- k + 1L
      field <- paste(item$path, collapse = "__")
      records[[k]] <- list(
        group = "__cross_group__",
        field = field,
        claim = item$claim
      )
    }
  }

  if (length(records) == 0L) return(.contextualized_empty_combined_registry())

  out <- .contextualized_registry_piece(length(records))
  for (i in seq_along(records)) {
    record <- records[[i]]
    group_id <- .contextualized_escape_id_component(record$group, "cross_group")
    field_id <- .contextualized_escape_id_component(record$field, "claim")
    out$evidence_id[[i]] <- paste0(
      group_id, "::textual_profile::", field_id, "::", i
    )
    out$evidence_type[[i]] <- "textual_interpretation"
    out$group[[i]] <- record$group
    out$source_group[[i]] <- record$group
    out$source[[i]] <- "textual_profiles"
    out$subtype[[i]] <- record$field
    out$interpretation_text[[i]] <- as.character(record$claim$text)
    ids <- .contextualized_as_character_vector(
      record$claim$evidence_ids,
      "textual_profile$evidence_ids"
    )
    out$grounding_evidence_ids[[i]] <- ids
  }
  out
}

.build_contextualized_combined_registry <- function(statistical_profiles,
                                                    textual_input) {
  pieces <- list(
    .contextualized_statistical_registry_piece(
      statistical_profiles$evidence_registry
    )
  )
  if (!is.null(textual_input$textual_evidence)) {
    pieces[[length(pieces) + 1L]] <- .contextualized_textual_registry_piece(
      textual_input$textual_evidence$evidence_registry
    )
  }
  pieces[[length(pieces) + 1L]] <- .contextualized_interpretation_registry_piece(
    textual_input$textual_profiles
  )

  keep <- vapply(pieces, nrow, integer(1)) > 0L
  if (!any(keep)) return(.contextualized_empty_combined_registry())
  out <- do.call(rbind, pieces[keep])
  rownames(out) <- NULL
  if (anyDuplicated(out$evidence_id)) {
    duplicated_ids <- unique(out$evidence_id[duplicated(out$evidence_id)])
    stop(
      sprintf(
        "The combined evidence registry contains duplicated ID(s): %s.",
        paste(duplicated_ids, collapse = ", ")
      ),
      call. = FALSE
    )
  }
  out
}

.build_contextualized_evidence <- function(statistical_profiles,
                                          textual_input,
                                          group_map = NULL) {
  alignment <- .build_contextualized_group_alignment(
    statistical_profiles = statistical_profiles,
    textual_input = textual_input,
    group_map = group_map
  )

  groups <- stats::setNames(vector("list", nrow(alignment)), alignment$canonical_group)
  for (i in seq_len(nrow(alignment))) {
    row <- alignment[i, , drop = FALSE]
    canonical <- row$canonical_group[[1L]]
    stat_group <- row$statistical_group[[1L]]
    text_group <- row$textual_group[[1L]]

    stat_profile <- if (is.na(stat_group)) NULL else statistical_profiles$groups[[stat_group]]
    text_profile <- if (is.na(text_group) || is.null(textual_input$textual_profiles)) {
      NULL
    } else {
      textual_input$textual_profiles$groups[[text_group]]
    }
    diagnostics <- .contextualized_group_diagnostics(
      textual_input$textual_evidence,
      text_group
    )

    stat_ids <- if (is.na(stat_group)) character(0) else {
      statistical_profiles$evidence_registry$evidence_id[
        statistical_profiles$evidence_registry$group == stat_group
      ]
    }
    text_ids <- if (is.na(text_group) || is.null(textual_input$textual_evidence)) {
      character(0)
    } else {
      textual_input$textual_evidence$evidence_registry$evidence_id[
        textual_input$textual_evidence$evidence_registry$group == text_group
      ]
    }
    prompt_text_ids <- if (is.na(text_group) || is.null(textual_input$textual_evidence)) {
      character(0)
    } else {
      registry <- textual_input$textual_evidence$evidence_registry
      registry$evidence_id[
        registry$group == text_group & registry$included_in_prompt
      ]
    }

    available_sources <- character(0)
    if (!is.null(stat_profile)) available_sources <- c(available_sources, "statistical")
    if (length(text_ids) > 0L || isTRUE(row$has_textual_evidence[[1L]])) {
      available_sources <- c(available_sources, "textual_evidence")
    }
    if (!is.null(text_profile)) available_sources <- c(available_sources, "textual_profile")

    groups[[canonical]] <- list(
      group = canonical,
      alignment_status = row$alignment_status[[1L]],
      statistical_group = if (is.na(stat_group)) NULL else stat_group,
      textual_group = if (is.na(text_group)) NULL else text_group,
      statistical_profile = stat_profile,
      textual_profile = text_profile,
      textual_diagnostics = diagnostics,
      statistical_evidence_ids = unname(stat_ids),
      textual_evidence_ids = unname(text_ids),
      textual_prompt_evidence_ids = unname(prompt_text_ids),
      available_sources = available_sources,
      integration_limits = .contextualized_build_group_limits(
        row,
        textual_input,
        diagnostics
      )
    )
  }

  combined_registry <- .build_contextualized_combined_registry(
    statistical_profiles,
    textual_input
  )
  if (nrow(combined_registry) > 0L) {
    for (i in seq_len(nrow(alignment))) {
      canonical <- alignment$canonical_group[[i]]
      stat_group <- alignment$statistical_group[[i]]
      text_group <- alignment$textual_group[[i]]
      if (!is.na(stat_group)) {
        stat_rows <- combined_registry$evidence_type %in% c(
          "statistical_qualitative", "statistical_quantitative"
        ) & combined_registry$source_group == stat_group
        combined_registry$group[stat_rows] <- canonical
      }
      if (!is.na(text_group)) {
        text_rows <- combined_registry$evidence_type %in% c(
          "textual_verbatim", "textual_interpretation"
        ) & combined_registry$source_group == text_group
        combined_registry$group[text_rows] <- canonical
      }
    }
  }

  out <- list(
    group_alignment = alignment,
    groups = groups,
    statistical_evidence_registry = statistical_profiles$evidence_registry,
    textual_evidence_registry = if (is.null(textual_input$textual_evidence)) {
      .contextualized_empty_text_registry()
    } else {
      textual_input$textual_evidence$evidence_registry
    },
    combined_evidence_registry = combined_registry,
    settings = list(
      alignment_rule = paste(
        "Exact original names are matched unless an explicit named group_map",
        "maps a statistical group to a textual group. No fuzzy matching is used."
      ),
      group_map = .contextualized_validate_group_map(group_map),
      statistical_evidence_ids_preserved = TRUE,
      textual_evidence_ids_preserved = TRUE,
      only_prompted_verbatims_may_ground_generated_analysis = TRUE
    ),
    metadata = list(
      schema = "NaileR::contextualized_evidence",
      version = "1.0.0",
      groups = names(groups),
      statistical_schema = statistical_profiles$metadata$schema,
      textual_schema = if (is.null(textual_input$textual_evidence)) {
        "legacy_without_textual_evidence"
      } else {
        textual_input$textual_evidence$metadata$schema
      }
    )
  )
  class(out) <- c("contextualized_evidence", "list")
  out
}

.contextualized_statistical_payload <- function(contextualized_evidence, group_name) {
  group <- contextualized_evidence$groups[[group_name]]
  registry <- contextualized_evidence$combined_evidence_registry
  rows <- registry[
    registry$group == group_name &
      registry$evidence_type %in% c("statistical_qualitative", "statistical_quantitative"),
    c(
      "evidence_id", "evidence_type", "group", "variable", "modality",
      "direction", "v_test", "p_value", "source"
    ),
    drop = FALSE
  ]
  list(
    available = nrow(rows) > 0L || !is.null(group$statistical_profile),
    factual_summary = if (is.null(group$statistical_profile)) {
      NULL
    } else {
      group$statistical_profile$factual_summary
    },
    evidence = .contextualized_records(rows)
  )
}

.contextualized_textual_payload <- function(contextualized_evidence, group_name) {
  group <- contextualized_evidence$groups[[group_name]]
  registry <- contextualized_evidence$combined_evidence_registry
  rows <- registry[
    registry$group == group_name &
      registry$evidence_type == "textual_verbatim" &
      !is.na(registry$included_in_prompt) & registry$included_in_prompt,
    c(
      "evidence_id", "evidence_type", "group", "original_text",
      "row_index", "included_in_prompt", "source"
    ),
    drop = FALSE
  ]
  list(
    available = nrow(rows) > 0L,
    verbatims = .contextualized_records(rows)
  )
}

.contextualized_profiles_payload <- function(contextualized_evidence, group_name) {
  group <- contextualized_evidence$groups[[group_name]]
  list(
    available = !is.null(group$textual_profile),
    profile = group$textual_profile,
    note = paste(
      "This is a validated LLM interpretation grounded in the verbatim IDs",
      "stored inside its claims. It is not a raw observation."
    )
  )
}

.contextualized_scope_instructions <- function(analysis_scope) {
  switch(
    analysis_scope,
    general = paste(
      "Integrate measured group characteristics with expressed discourse.",
      "Prioritize convergences, nuances, divergences, source-specific findings, and limits."
    ),
    sociological = paste(
      "Examine practices, social norms, legitimacy, institutional relationships,",
      "territorial anchoring, resources, constraints, distinction, and gaps between prescriptions and possibilities."
    ),
    consumer = paste(
      "Examine measured behavior together with benefits, barriers, trade-offs, trust,",
      "perceived value, routines, and cautious behavioral segmentation hypotheses."
    ),
    psychological = paste(
      "Examine expressed attitudes, motivations, ambivalence, perceived control,",
      "self-efficacy, value-practice tensions, and resistance to change without diagnosing anyone."
    ),
    marketing = paste(
      "Translate the integrated evidence into benefits to communicate, barriers to address,",
      "consumer vocabulary, positioning hypotheses, and communication directions that require validation."
    ),
    innovation = paste(
      "Identify unmet needs, category tensions, weak signals, possible product or service concepts,",
      "and usage hypotheses that require validation."
    ),
    cross_functional = paste(
      "Integrate sociological, consumer, psychological, marketing, and innovation perspectives.",
      "Keep each interpretation tied to evidence and distinguish insight, hypothesis, and recommendation."
    )
  )
}

.contextualized_claim_template <- function(status = "expert_interpretation",
                                           relationship = NULL) {
  list(
    text = "<integrated interpretation grounded in the cited evidence IDs>",
    status = status,
    statistical_evidence_ids = list("<statistical_evidence_id>"),
    textual_evidence_ids = list("<verbatim_evidence_id>"),
    relationship = relationship,
    quotations = list(),
    validation_needed = if (status %in% c("hypothesis", "recommendation")) {
      "<additional study or evidence needed>"
    } else {
      NULL
    }
  )
}

.contextualized_group_schema <- function(group_name) {
  list(
    group = group_name,
    availability = "available",
    parse_error = NULL,
    integrated_profile = .contextualized_claim_template(),
    statistical_textual_convergences = list(
      .contextualized_claim_template(relationship = "complement")
    ),
    statistical_textual_divergences = list(
      .contextualized_claim_template(relationship = "tension")
    ),
    statistical_only_findings = list(.contextualized_claim_template()),
    textual_only_findings = list(.contextualized_claim_template()),
    social_interpretations = list(.contextualized_claim_template("hypothesis")),
    consumer_insights = list(.contextualized_claim_template()),
    psychological_hypotheses = list(.contextualized_claim_template("hypothesis")),
    marketing_implications = list(.contextualized_claim_template("recommendation")),
    innovation_opportunities = list(.contextualized_claim_template("recommendation")),
    operational_implications = list(.contextualized_claim_template("recommendation")),
    validation_priorities = list(.contextualized_claim_template("recommendation")),
    interpretation_limits = list()
  )
}

.contextualized_cross_schema <- function() {
  list(
    shared_patterns = list(.contextualized_claim_template()),
    major_group_contrasts = list(.contextualized_claim_template("hypothesis")),
    different_statistical_textual_relationships = list(.contextualized_claim_template()),
    cross_group_social_interpretations = list(.contextualized_claim_template("hypothesis")),
    consumer_segments_hypotheses = list(.contextualized_claim_template("hypothesis")),
    psychological_mechanisms_hypotheses = list(.contextualized_claim_template("hypothesis")),
    marketing_priorities = list(.contextualized_claim_template("recommendation")),
    innovation_priorities = list(.contextualized_claim_template("recommendation")),
    validation_priorities = list(.contextualized_claim_template("recommendation")),
    interpretation_limits = list()
  )
}

.contextualized_output_schema <- function(groups, comparison_mode) {
  schema <- list(
    groups = stats::setNames(lapply(groups, .contextualized_group_schema), groups),
    cross_group_analysis = if (comparison_mode == "joint") {
      .contextualized_cross_schema()
    } else {
      NULL
    }
  )
  jsonlite::toJSON(schema, auto_unbox = TRUE, null = "null", pretty = TRUE)
}

.contextualized_json <- function(x) {
  jsonlite::toJSON(
    x,
    auto_unbox = TRUE,
    null = "null",
    na = "null",
    pretty = TRUE,
    dataframe = "rows"
  )
}

.build_contextualized_prompt <- function(contextualized_evidence,
                                        groups,
                                        analysis_scope,
                                        comparison_mode,
                                        context,
                                        request,
                                        prompt_style) {
  statistical <- stats::setNames(
    lapply(groups, function(group_name) {
      .contextualized_statistical_payload(contextualized_evidence, group_name)
    }),
    groups
  )
  textual <- stats::setNames(
    lapply(groups, function(group_name) {
      .contextualized_textual_payload(contextualized_evidence, group_name)
    }),
    groups
  )
  profiles <- stats::setNames(
    lapply(groups, function(group_name) {
      .contextualized_profiles_payload(contextualized_evidence, group_name)
    }),
    groups
  )
  limits <- stats::setNames(
    lapply(groups, function(group_name) {
      contextualized_evidence$groups[[group_name]]$integration_limits
    }),
    groups
  )

  request_text <- if (is.null(request) || !nzchar(trimws(request))) {
    "No additional user request."
  } else {
    request
  }
  context_payload <- if (length(context) == 0L) list() else context

  paste(
    "ROLE",
    paste(
      "You are an interdisciplinary analyst integrating mechanical statistical evidence,",
      "exact participant verbatims, and already validated textual interpretations."
    ),
    "",
    "STATISTICAL EVIDENCE",
    .contextualized_json(statistical),
    "",
    "TEXTUAL EVIDENCE",
    .contextualized_json(textual),
    "",
    "VALIDATED TEXTUAL PROFILES",
    .contextualized_json(profiles),
    "",
    "USER-PROVIDED CONTEXT",
    .contextualized_json(context_payload),
    "",
    "INTEGRATION TASK",
    .contextualized_scope_instructions(analysis_scope),
    paste0("Comparison mode: ", comparison_mode, "."),
    paste0("Prompt detail: ", prompt_style, "."),
    "Mechanical integration limits by group:",
    .contextualized_json(limits),
    "",
    "ADDITIONAL USER REQUEST",
    request_text,
    "",
    "MANDATORY EPISTEMIC RULES",
    paste(
      "1. Statistical evidence describes measured associations or group characterizations.",
      "Textual evidence describes what participants expressed.",
      "A validated textual profile is an interpretation grounded in cited verbatims.",
      "These three layers must not be confused."
    ),
    "2. Cite evidence IDs only; do not copy, round, or invent statistical numbers in claim text.",
    "3. A convergence or divergence must cite at least one statistical ID and one prompted verbatim ID.",
    "4. Statistical-only findings must not be described as textually confirmed.",
    "5. Textual-only findings must not be described as statistically demonstrated.",
    "6. Use direct contradiction only when the evidence clearly warrants it; otherwise use nuance, tension, or apparent divergence.",
    "7. Hypotheses and recommendations require a concrete validation_needed field.",
    "8. Do not diagnose individuals or groups, invent demographic segments, or assert unqualified causality.",
    "9. Direct quotations must exactly match original_text and cite their verbatim evidence_id.",
    "10. In isolated mode, cite only the current group and set cross_group_analysis to null.",
    "11. Return one strict JSON object, without Markdown fences, comments, or surrounding prose.",
    "",
    "OUTPUT SCHEMA",
    .contextualized_output_schema(groups, comparison_mode),
    sep = "\n"
  )
}

.build_contextualized_units <- function(contextualized_evidence,
                                       analysis_scope,
                                       comparison_mode,
                                       context,
                                       request,
                                       prompt_style) {
  groups <- names(contextualized_evidence$groups)
  if (length(groups) == 0L) return(list())

  if (comparison_mode == "joint") {
    prompt <- .build_contextualized_prompt(
      contextualized_evidence = contextualized_evidence,
      groups = groups,
      analysis_scope = analysis_scope,
      comparison_mode = comparison_mode,
      context = context,
      request = request,
      prompt_style = prompt_style
    )
    return(list(
      joint = list(
        unit = "joint",
        groups = groups,
        prompt = prompt,
        response = NULL,
        parsed = list(
          parse_status = "not_generated",
          parse_error = NULL,
          contextualized_analysis = NULL
        )
      )
    ))
  }

  units <- lapply(groups, function(group_name) {
    list(
      unit = group_name,
      groups = group_name,
      prompt = .build_contextualized_prompt(
        contextualized_evidence = contextualized_evidence,
        groups = group_name,
        analysis_scope = analysis_scope,
        comparison_mode = comparison_mode,
        context = context,
        request = request,
        prompt_style = prompt_style
      ),
      response = NULL,
      parsed = list(
        parse_status = "not_generated",
        parse_error = NULL,
        contextualized_analysis = NULL
      )
    )
  })
  names(units) <- groups
  units
}

.contextualized_response_text <- function(response) {
  if (is.null(response)) return("")
  if (is.data.frame(response) && "response" %in% names(response)) {
    return(paste(response$response, collapse = "\n"))
  }
  if (is.list(response) && !is.null(response$response)) {
    return(paste(response$response, collapse = "\n"))
  }
  paste(response, collapse = "\n")
}

.contextualized_contains_demographic_claim <- function(text) {
  if (exists(".textual_prep_contains_demographic_claim", mode = "function")) {
    return(.textual_prep_contains_demographic_claim(text))
  }
  grepl(
    "\\b(age|gender|sex|income|social class|men|women|hommes?|femmes?|revenu)\\b",
    text,
    ignore.case = TRUE,
    perl = TRUE
  )
}

.contextualized_contains_diagnostic_claim <- function(text) {
  if (exists(".textual_prep_contains_diagnostic_claim", mode = "function")) {
    return(.textual_prep_contains_diagnostic_claim(text))
  }
  grepl(
    "\\b(depression|depressed|bipolar|psychotic|autistic|adhd|diagnosed|depression|bipolaire|psychotique|autiste)\\b",
    text,
    ignore.case = TRUE,
    perl = TRUE
  )
}

.contextualized_contains_unqualified_causality <- function(text, status) {
  causal <- grepl(
    paste0(
      "\\b(causes?|caused|leads? to|results? in|proves?|demonstrates? that|",
      "responsible for|provoque|provoquent|entraine|entrainent|cause|causent|prouve)\\b"
    ),
    text,
    ignore.case = TRUE,
    perl = TRUE
  )
  if (!causal) return(FALSE)
  hedged <- grepl(
    "\\b(may|might|could|possibly|potentially|suggests?|peut|pourrait|semble|hypothese)\\b",
    text,
    ignore.case = TRUE,
    perl = TRUE
  )
  !(identical(status, "hypothesis") && hedged)
}

.contextualized_contains_unsupported_number <- function(text, source_text) {
  if (exists(".textual_prep_claim_has_unsupported_number", mode = "function")) {
    return(.textual_prep_claim_has_unsupported_number(text, source_text))
  }
  matches <- regmatches(
    text,
    gregexpr("\\b[0-9]+(?:[.,][0-9]+)?%?\\b", text, perl = TRUE)
  )[[1L]]
  if (length(matches) == 0L || identical(matches, "")) return(FALSE)
  source_text <- paste(source_text, collapse = "\n")
  any(!vapply(matches, grepl, logical(1), x = source_text, fixed = TRUE))
}

.contextualized_validate_quote <- function(x,
                                           field,
                                           registry,
                                           group = NULL,
                                           allowed_textual_ids) {
  if (!is.list(x) || is.data.frame(x)) {
    stop(sprintf("`%s` must be a quotation object.", field), call. = FALSE)
  }
  missing_fields <- setdiff(.contextualized_quote_fields, names(x))
  unknown_fields <- setdiff(names(x), .contextualized_quote_fields)
  if (length(missing_fields) > 0L) {
    stop(sprintf("`%s` is missing: %s.", field, paste(missing_fields, collapse = ", ")), call. = FALSE)
  }
  if (length(unknown_fields) > 0L) {
    stop(sprintf("`%s` contains unexpected fields.", field), call. = FALSE)
  }
  if (!.contextualized_is_scalar_string(x$evidence_id) ||
      !x$evidence_id %in% allowed_textual_ids) {
    stop(sprintf("`%s$evidence_id` is unknown or was not included in the prompt.", field), call. = FALSE)
  }
  row <- registry[match(x$evidence_id, registry$evidence_id), , drop = FALSE]
  if (!is.null(group) && row$group[[1L]] != group) {
    stop(sprintf("`%s` cites a quotation from another group.", field), call. = FALSE)
  }
  if (!.contextualized_is_scalar_string(x$quotation, allow_empty = TRUE) ||
      !identical(as.character(x$quotation), as.character(row$original_text[[1L]]))) {
    stop(sprintf("`%s$quotation` must exactly match original_text.", field), call. = FALSE)
  }
  list(evidence_id = x$evidence_id, quotation = x$quotation)
}

.contextualized_validate_claim <- function(claim,
                                           field,
                                           registry,
                                           group = NULL,
                                           context = list(),
                                           source_requirement = c("any", "both", "statistical_only", "textual_only"),
                                           allowed_statuses = .contextualized_statuses,
                                           allowed_relationships = NULL,
                                           require_multiple_groups = FALSE) {
  source_requirement <- match.arg(source_requirement)
  if (is.null(claim)) return(NULL)
  if (!is.list(claim) || is.data.frame(claim)) {
    stop(sprintf("`%s` must be null or a claim object.", field), call. = FALSE)
  }
  missing_fields <- setdiff(.contextualized_claim_fields, names(claim))
  unknown_fields <- setdiff(names(claim), .contextualized_claim_fields)
  if (length(missing_fields) > 0L) {
    stop(sprintf("`%s` is missing: %s.", field, paste(missing_fields, collapse = ", ")), call. = FALSE)
  }
  if (length(unknown_fields) > 0L) {
    stop(sprintf("`%s` contains unexpected field(s): %s.", field, paste(unknown_fields, collapse = ", ")), call. = FALSE)
  }
  if (!.contextualized_is_scalar_string(claim$text)) {
    stop(sprintf("`%s$text` must be a non-empty string.", field), call. = FALSE)
  }
  status <- as.character(claim$status)
  if (length(status) != 1L || is.na(status) || !status %in% allowed_statuses) {
    stop(
      sprintf("`%s$status` must be one of: %s.", field, paste(allowed_statuses, collapse = ", ")),
      call. = FALSE
    )
  }

  stat_ids <- unique(.contextualized_as_character_vector(
    claim$statistical_evidence_ids,
    paste0(field, "$statistical_evidence_ids")
  ))
  text_ids <- unique(.contextualized_as_character_vector(
    claim$textual_evidence_ids,
    paste0(field, "$textual_evidence_ids")
  ))

  stat_rows <- registry$evidence_type %in% c("statistical_qualitative", "statistical_quantitative")
  text_rows <- registry$evidence_type == "textual_verbatim" &
    !is.na(registry$included_in_prompt) & registry$included_in_prompt
  invalid_stat <- setdiff(stat_ids, registry$evidence_id[stat_rows])
  invalid_text <- setdiff(text_ids, registry$evidence_id[text_rows])
  if (length(invalid_stat) > 0L) {
    stop(sprintf("`%s` cites unknown statistical evidence ID(s): %s.", field, paste(invalid_stat, collapse = ", ")), call. = FALSE)
  }
  if (length(invalid_text) > 0L) {
    stop(sprintf("`%s` cites unknown or non-presented textual evidence ID(s): %s.", field, paste(invalid_text, collapse = ", ")), call. = FALSE)
  }

  if (!is.null(group)) {
    evidence_groups <- registry$group[match(c(stat_ids, text_ids), registry$evidence_id)]
    if (length(evidence_groups) > 0L && any(is.na(evidence_groups) | evidence_groups != group)) {
      stop(sprintf("`%s` cites evidence belonging to another group.", field), call. = FALSE)
    }
  }

  if (status == "user_context") {
    if (length(context) == 0L) {
      stop(sprintf("`%s` cannot use `user_context` without context.", field), call. = FALSE)
    }
    if (length(stat_ids) > 0L || length(text_ids) > 0L) {
      stop(sprintf("`%s` with status `user_context` must not cite evidence IDs.", field), call. = FALSE)
    }
  } else {
    if (source_requirement == "both" && (length(stat_ids) == 0L || length(text_ids) == 0L)) {
      stop(sprintf("`%s` must cite both statistical and textual evidence.", field), call. = FALSE)
    }
    if (source_requirement == "statistical_only" &&
        (length(stat_ids) == 0L || length(text_ids) > 0L)) {
      stop(sprintf("`%s` must cite statistical evidence only.", field), call. = FALSE)
    }
    if (source_requirement == "textual_only" &&
        (length(text_ids) == 0L || length(stat_ids) > 0L)) {
      stop(sprintf("`%s` must cite textual evidence only.", field), call. = FALSE)
    }
    if (source_requirement == "any" && length(stat_ids) == 0L && length(text_ids) == 0L) {
      stop(sprintf("`%s` must cite at least one evidence ID.", field), call. = FALSE)
    }
  }

  relationship <- claim$relationship
  if (is.null(relationship) ||
      (is.character(relationship) && length(relationship) == 1L &&
       (is.na(relationship) || !nzchar(trimws(relationship))))) {
    relationship <- NULL
  } else if (!.contextualized_is_scalar_string(relationship)) {
    stop(sprintf("`%s$relationship` must be null or a non-empty string.", field), call. = FALSE)
  }
  if (is.null(allowed_relationships)) {
    if (!is.null(relationship)) {
      stop(sprintf("`%s$relationship` must be null in this field.", field), call. = FALSE)
    }
  } else if (is.null(relationship) || !relationship %in% allowed_relationships) {
    stop(
      sprintf("`%s$relationship` must be one of: %s.", field, paste(allowed_relationships, collapse = ", ")),
      call. = FALSE
    )
  }

  validation_needed <- claim$validation_needed
  if (is.null(validation_needed) ||
      (is.character(validation_needed) && length(validation_needed) == 1L &&
       (is.na(validation_needed) || !nzchar(trimws(validation_needed))))) {
    validation_needed <- NULL
  } else if (!.contextualized_is_scalar_string(validation_needed)) {
    stop(sprintf("`%s$validation_needed` must be null or a non-empty string.", field), call. = FALSE)
  } else {
    validation_needed <- trimws(validation_needed)
  }
  if (status %in% c("hypothesis", "recommendation") && is.null(validation_needed)) {
    stop(sprintf("`%s` with status `%s` requires validation_needed.", field, status), call. = FALSE)
  }

  quotations <- claim$quotations
  if (is.null(quotations) || length(quotations) == 0L) {
    quotations <- list()
  } else if (!is.list(quotations) || is.data.frame(quotations)) {
    stop(sprintf("`%s$quotations` must be a JSON array.", field), call. = FALSE)
  } else {
    quotations <- unname(lapply(seq_along(quotations), function(i) {
      quote <- .contextualized_validate_quote(
        quotations[[i]],
        field = sprintf("%s$quotations[[%d]]", field, i),
        registry = registry,
        group = group,
        allowed_textual_ids = text_ids
      )
      quote
    }))
  }

  source_text <- c(
    registry$original_text[match(text_ids, registry$evidence_id, nomatch = 0L)],
    if (length(context) > 0L) unlist(context, recursive = TRUE, use.names = FALSE) else character(0)
  )
  if (.contextualized_contains_diagnostic_claim(claim$text)) {
    stop("Psychological diagnoses of individuals or groups are not allowed.", call. = FALSE)
  }
  if (.contextualized_contains_unqualified_causality(claim$text, status)) {
    stop("An unqualified causal claim is not supported by this integration.", call. = FALSE)
  }
  if (.contextualized_contains_unsupported_number(claim$text, source_text)) {
    stop("A claim contains a numerical statement not present in its cited textual evidence or context.", call. = FALSE)
  }
  if (.contextualized_contains_demographic_claim(claim$text) &&
      !.contextualized_contains_demographic_claim(paste(source_text, collapse = "\n"))) {
    stop("A demographic claim is not supported by cited verbatims or user context.", call. = FALSE)
  }

  if (require_multiple_groups && status != "user_context") {
    evidence_groups <- unique(registry$group[match(c(stat_ids, text_ids), registry$evidence_id)])
    evidence_groups <- evidence_groups[!is.na(evidence_groups)]
    if (length(evidence_groups) < 2L) {
      stop(sprintf("`%s` must cite evidence from at least two groups.", field), call. = FALSE)
    }
  }

  list(
    text = trimws(claim$text),
    status = status,
    statistical_evidence_ids = stat_ids,
    textual_evidence_ids = text_ids,
    relationship = relationship,
    quotations = quotations,
    validation_needed = validation_needed
  )
}

.contextualized_validate_claim_list <- function(x,
                                                field,
                                                registry,
                                                group = NULL,
                                                context = list(),
                                                source_requirement = "any",
                                                allowed_statuses = .contextualized_statuses,
                                                allowed_relationships = NULL,
                                                require_multiple_groups = FALSE) {
  if (is.null(x) || length(x) == 0L) return(list())
  if (!is.list(x) || is.data.frame(x)) {
    stop(sprintf("`%s` must be a JSON array of claim objects.", field), call. = FALSE)
  }
  unname(lapply(seq_along(x), function(i) {
    .contextualized_validate_claim(
      x[[i]],
      field = sprintf("%s[[%d]]", field, i),
      registry = registry,
      group = group,
      context = context,
      source_requirement = source_requirement,
      allowed_statuses = allowed_statuses,
      allowed_relationships = allowed_relationships,
      require_multiple_groups = require_multiple_groups
    )
  }))
}

.contextualized_validate_group_analysis <- function(x,
                                                    group_name,
                                                    registry,
                                                    context) {
  field <- paste0("groups$", group_name)
  if (!is.list(x) || is.data.frame(x)) {
    stop(sprintf("`%s` must be an object.", field), call. = FALSE)
  }
  missing_fields <- setdiff(.contextualized_group_fields, names(x))
  unknown_fields <- setdiff(names(x), .contextualized_group_fields)
  if (length(missing_fields) > 0L) {
    stop(sprintf("`%s` is missing: %s.", field, paste(missing_fields, collapse = ", ")), call. = FALSE)
  }
  if (length(unknown_fields) > 0L) {
    stop(sprintf("`%s` contains unexpected fields.", field), call. = FALSE)
  }
  if (!.contextualized_is_scalar_string(x$group) || !identical(as.character(x$group), group_name)) {
    stop(sprintf("`%s$group` must equal `%s`.", field, group_name), call. = FALSE)
  }
  if (!identical(as.character(x$availability), "available")) {
    stop(sprintf("`%s$availability` must be `available` in generated JSON.", field), call. = FALSE)
  }
  if (!is.null(x$parse_error)) {
    stop(sprintf("`%s$parse_error` must be null in generated JSON.", field), call. = FALSE)
  }

  out <- list(
    group = group_name,
    availability = "available",
    parse_error = NULL,
    integrated_profile = .contextualized_validate_claim(
      x$integrated_profile,
      paste0(field, "$integrated_profile"),
      registry,
      group_name,
      context,
      source_requirement = "any",
      allowed_statuses = c("expert_interpretation", "hypothesis", "user_context")
    ),
    statistical_textual_convergences = .contextualized_validate_claim_list(
      x$statistical_textual_convergences,
      paste0(field, "$statistical_textual_convergences"),
      registry,
      group_name,
      context,
      source_requirement = "both",
      allowed_statuses = c("expert_interpretation", "hypothesis"),
      allowed_relationships = c("complement", "nuance")
    ),
    statistical_textual_divergences = .contextualized_validate_claim_list(
      x$statistical_textual_divergences,
      paste0(field, "$statistical_textual_divergences"),
      registry,
      group_name,
      context,
      source_requirement = "both",
      allowed_statuses = c("expert_interpretation", "hypothesis"),
      allowed_relationships = c("tension", "apparent_divergence", "direct_contradiction")
    ),
    statistical_only_findings = .contextualized_validate_claim_list(
      x$statistical_only_findings,
      paste0(field, "$statistical_only_findings"),
      registry,
      group_name,
      context,
      source_requirement = "statistical_only",
      allowed_statuses = c("expert_interpretation", "hypothesis")
    ),
    textual_only_findings = .contextualized_validate_claim_list(
      x$textual_only_findings,
      paste0(field, "$textual_only_findings"),
      registry,
      group_name,
      context,
      source_requirement = "textual_only",
      allowed_statuses = c("expert_interpretation", "hypothesis")
    ),
    social_interpretations = .contextualized_validate_claim_list(
      x$social_interpretations,
      paste0(field, "$social_interpretations"),
      registry,
      group_name,
      context,
      source_requirement = "any",
      allowed_statuses = c("expert_interpretation", "hypothesis", "user_context")
    ),
    consumer_insights = .contextualized_validate_claim_list(
      x$consumer_insights,
      paste0(field, "$consumer_insights"),
      registry,
      group_name,
      context,
      source_requirement = "any",
      allowed_statuses = c("expert_interpretation", "hypothesis", "user_context")
    ),
    psychological_hypotheses = .contextualized_validate_claim_list(
      x$psychological_hypotheses,
      paste0(field, "$psychological_hypotheses"),
      registry,
      group_name,
      context,
      source_requirement = "any",
      allowed_statuses = "hypothesis"
    ),
    marketing_implications = .contextualized_validate_claim_list(
      x$marketing_implications,
      paste0(field, "$marketing_implications"),
      registry,
      group_name,
      context,
      source_requirement = "any",
      allowed_statuses = "recommendation"
    ),
    innovation_opportunities = .contextualized_validate_claim_list(
      x$innovation_opportunities,
      paste0(field, "$innovation_opportunities"),
      registry,
      group_name,
      context,
      source_requirement = "any",
      allowed_statuses = "recommendation"
    ),
    operational_implications = .contextualized_validate_claim_list(
      x$operational_implications,
      paste0(field, "$operational_implications"),
      registry,
      group_name,
      context,
      source_requirement = "any",
      allowed_statuses = "recommendation"
    ),
    validation_priorities = .contextualized_validate_claim_list(
      x$validation_priorities,
      paste0(field, "$validation_priorities"),
      registry,
      group_name,
      context,
      source_requirement = "any",
      allowed_statuses = "recommendation"
    ),
    interpretation_limits = .contextualized_validate_claim_list(
      x$interpretation_limits,
      paste0(field, "$interpretation_limits"),
      registry,
      group_name,
      context,
      source_requirement = "any",
      allowed_statuses = c("expert_interpretation", "hypothesis", "user_context")
    )
  )
  out[.contextualized_group_fields]
}

.contextualized_validate_cross_analysis <- function(x,
                                                    registry,
                                                    context,
                                                    comparison_mode) {
  if (comparison_mode == "isolated") {
    if (!is.null(x)) {
      stop("`cross_group_analysis` must be null in isolated mode.", call. = FALSE)
    }
    return(NULL)
  }
  if (!is.list(x) || is.data.frame(x)) {
    stop("`cross_group_analysis` must be an object in joint mode.", call. = FALSE)
  }
  missing_fields <- setdiff(.contextualized_cross_fields, names(x))
  unknown_fields <- setdiff(names(x), .contextualized_cross_fields)
  if (length(missing_fields) > 0L) {
    stop(sprintf("`cross_group_analysis` is missing: %s.", paste(missing_fields, collapse = ", ")), call. = FALSE)
  }
  if (length(unknown_fields) > 0L) {
    stop("`cross_group_analysis` contains unexpected fields.", call. = FALSE)
  }

  multi_fields <- c(
    "major_group_contrasts",
    "different_statistical_textual_relationships",
    "consumer_segments_hypotheses",
    "psychological_mechanisms_hypotheses"
  )
  recommendation_fields <- c(
    "marketing_priorities",
    "innovation_priorities",
    "validation_priorities"
  )
  hypothesis_fields <- c(
    "consumer_segments_hypotheses",
    "psychological_mechanisms_hypotheses"
  )

  out <- list()
  for (name in .contextualized_cross_fields) {
    allowed_statuses <- if (name %in% recommendation_fields) {
      "recommendation"
    } else if (name %in% hypothesis_fields) {
      "hypothesis"
    } else {
      c("expert_interpretation", "hypothesis", "user_context")
    }
    out[[name]] <- .contextualized_validate_claim_list(
      x[[name]],
      field = paste0("cross_group_analysis$", name),
      registry = registry,
      group = NULL,
      context = context,
      source_requirement = "any",
      allowed_statuses = allowed_statuses,
      require_multiple_groups = name %in% multi_fields
    )
  }
  out[.contextualized_cross_fields]
}

.validate_contextualized_analysis <- function(parsed,
                                              expected_groups,
                                              contextualized_evidence,
                                              context,
                                              analysis_scope,
                                              comparison_mode) {
  if (!is.list(parsed) || is.data.frame(parsed)) {
    stop("The JSON root must be an object.", call. = FALSE)
  }
  required <- c("groups", "cross_group_analysis")
  missing_fields <- setdiff(required, names(parsed))
  unknown_fields <- setdiff(names(parsed), required)
  if (length(missing_fields) > 0L) {
    stop(sprintf("The JSON root is missing: %s.", paste(missing_fields, collapse = ", ")), call. = FALSE)
  }
  if (length(unknown_fields) > 0L) {
    stop(sprintf("The JSON root contains unexpected field(s): %s.", paste(unknown_fields, collapse = ", ")), call. = FALSE)
  }
  if (!is.list(parsed$groups) || is.null(names(parsed$groups))) {
    stop("`groups` must be a named JSON object.", call. = FALSE)
  }
  if (!setequal(names(parsed$groups), expected_groups)) {
    stop("The parsed group names do not match the generation unit.", call. = FALSE)
  }

  registry <- contextualized_evidence$combined_evidence_registry
  groups <- stats::setNames(
    lapply(expected_groups, function(group_name) {
      .contextualized_validate_group_analysis(
        parsed$groups[[group_name]],
        group_name,
        registry,
        context
      )
    }),
    expected_groups
  )
  cross <- .contextualized_validate_cross_analysis(
    parsed$cross_group_analysis,
    registry,
    context,
    comparison_mode
  )

  list(
    groups = groups,
    cross_group_analysis = cross,
    metadata = list(
      schema = "NaileR::contextualized_analysis",
      analysis_scope = analysis_scope,
      comparison_mode = comparison_mode,
      groups = expected_groups,
      parse_status = "success"
    )
  )
}

.parse_textual_contextualized_response <- function(text,
                                                   expected_groups,
                                                   contextualized_evidence,
                                                   context,
                                                   analysis_scope,
                                                   comparison_mode) {
  tryCatch({
    text <- paste(text, collapse = "\n")
    text <- gsub("\r\n", "\n", text, fixed = TRUE)
    text <- gsub("\r", "\n", text, fixed = TRUE)
    trimmed <- trimws(text)
    if (!nzchar(trimmed)) {
      stop("The LLM response is empty.", call. = FALSE)
    }
    if (grepl("```", trimmed, fixed = TRUE)) {
      stop("The LLM response contains a Markdown fence; strict JSON was required.", call. = FALSE)
    }
    if (substr(trimmed, 1L, 1L) != "{" ||
        substr(trimmed, nchar(trimmed), nchar(trimmed)) != "}") {
      stop("The LLM response must contain one strict JSON object and no surrounding text.", call. = FALSE)
    }

    parsed <- jsonlite::fromJSON(trimmed, simplifyDataFrame = FALSE)
    analysis <- .validate_contextualized_analysis(
      parsed = parsed,
      expected_groups = expected_groups,
      contextualized_evidence = contextualized_evidence,
      context = context,
      analysis_scope = analysis_scope,
      comparison_mode = comparison_mode
    )
    list(
      parse_status = "success",
      parse_error = NULL,
      contextualized_analysis = analysis
    )
  }, error = function(e) {
    list(
      parse_status = "error",
      parse_error = conditionMessage(e),
      contextualized_analysis = NULL
    )
  })
}

.contextualized_empty_group_analysis <- function(group_name, parse_error) {
  out <- list(
    group = group_name,
    availability = "unavailable",
    parse_error = parse_error,
    integrated_profile = NULL,
    statistical_textual_convergences = list(),
    statistical_textual_divergences = list(),
    statistical_only_findings = list(),
    textual_only_findings = list(),
    social_interpretations = list(),
    consumer_insights = list(),
    psychological_hypotheses = list(),
    marketing_implications = list(),
    innovation_opportunities = list(),
    operational_implications = list(),
    validation_priorities = list(),
    interpretation_limits = list()
  )
  out[.contextualized_group_fields]
}

.combine_contextualized_units <- function(units,
                                          all_groups,
                                          analysis_scope,
                                          comparison_mode) {
  if (length(units) == 0L) {
    return(list(
      parse_status = "no_units",
      parse_error = "No contextualized generation unit was available.",
      contextualized_analysis = NULL
    ))
  }
  statuses <- vapply(units, function(x) x$parsed$parse_status, character(1))
  if (all(statuses == "not_generated")) {
    return(list(
      parse_status = "not_generated",
      parse_error = NULL,
      contextualized_analysis = NULL
    ))
  }

  if (comparison_mode == "joint") {
    parsed <- units[[1L]]$parsed
    return(parsed)
  }

  groups <- list()
  errors <- character(0)
  for (unit in units) {
    group_name <- unit$groups[[1L]]
    if (identical(unit$parsed$parse_status, "success")) {
      groups[[group_name]] <- unit$parsed$contextualized_analysis$groups[[group_name]]
    } else {
      error <- if (is.null(unit$parsed$parse_error)) {
        paste0("Unit status: ", unit$parsed$parse_status)
      } else {
        unit$parsed$parse_error
      }
      groups[[group_name]] <- .contextualized_empty_group_analysis(group_name, error)
      errors <- c(errors, paste0(group_name, ": ", error))
    }
  }
  groups <- groups[all_groups]
  status <- if (length(errors) == 0L) {
    "success"
  } else if (length(errors) < length(units)) {
    "partial"
  } else {
    "error"
  }
  analysis <- list(
    groups = groups,
    cross_group_analysis = NULL,
    metadata = list(
      schema = "NaileR::contextualized_analysis",
      analysis_scope = analysis_scope,
      comparison_mode = comparison_mode,
      groups = all_groups,
      parse_status = status
    )
  )
  list(
    parse_status = status,
    parse_error = if (length(errors) == 0L) NULL else paste(errors, collapse = " | "),
    contextualized_analysis = analysis
  )
}

.contextualized_claim_text <- function(x) {
  if (is.null(x) || !is.list(x) || is.null(x$text)) return(NA_character_)
  as.character(x$text)
}

.contextualized_format_claim_markdown <- function(claim) {
  if (is.null(claim)) return(character(0))
  stat_ids <- if (length(claim$statistical_evidence_ids) == 0L) {
    "none"
  } else {
    paste(claim$statistical_evidence_ids, collapse = ", ")
  }
  text_ids <- if (length(claim$textual_evidence_ids) == 0L) {
    "none"
  } else {
    paste(claim$textual_evidence_ids, collapse = ", ")
  }
  validation <- if (is.null(claim$validation_needed)) "" else {
    paste0(" Validation: ", claim$validation_needed, ".")
  }
  relationship <- if (is.null(claim$relationship)) "" else {
    paste0(" Relationship: ", claim$relationship, ".")
  }
  paste0(
    "- ", claim$text, " [", claim$status, "] ",
    "Statistical evidence: ", stat_ids, "; textual evidence: ", text_ids, ".",
    relationship, validation
  )
}

.contextualized_render_markdown <- function(analysis, contextualized_evidence, parsed) {
  lines <- c("# Contextualized statistical-textual analysis", "")
  lines <- c(lines, paste0("Parse status: **", parsed$parse_status, "**"), "")
  for (group_name in names(contextualized_evidence$groups)) {
    evidence_group <- contextualized_evidence$groups[[group_name]]
    group_analysis <- if (is.null(analysis)) NULL else analysis$groups[[group_name]]
    lines <- c(lines, paste0("## ", group_name), "")
    lines <- c(
      lines,
      paste0("Alignment: `", evidence_group$alignment_status, "`."),
      paste0("Available sources: ", paste(evidence_group$available_sources, collapse = ", "), ".")
    )
    if (length(evidence_group$integration_limits) > 0L) {
      lines <- c(lines, "", "### Mechanical limits")
      lines <- c(lines, paste0("- ", evidence_group$integration_limits))
    }
    if (is.null(group_analysis)) {
      lines <- c(lines, "", "No contextualized semantic analysis is available.", "")
      next
    }
    if (!identical(group_analysis$availability, "available")) {
      lines <- c(lines, "", paste0("Analysis unavailable: ", group_analysis$parse_error), "")
      next
    }
    sections <- c(
      integrated_profile = "Integrated profile",
      statistical_textual_convergences = "Convergences",
      statistical_textual_divergences = "Divergences and tensions",
      statistical_only_findings = "Statistical-only findings",
      textual_only_findings = "Textual-only findings",
      social_interpretations = "Social interpretations",
      consumer_insights = "Consumer insights",
      psychological_hypotheses = "Psychological hypotheses",
      marketing_implications = "Marketing implications",
      innovation_opportunities = "Innovation opportunities",
      operational_implications = "Operational implications",
      validation_priorities = "Validation priorities",
      interpretation_limits = "Interpretation limits"
    )
    for (field in names(sections)) {
      value <- group_analysis[[field]]
      values <- if (field == "integrated_profile") {
        if (is.null(value)) list() else list(value)
      } else {
        value
      }
      if (length(values) == 0L) next
      lines <- c(lines, "", paste0("### ", sections[[field]]))
      lines <- c(lines, vapply(values, .contextualized_format_claim_markdown, character(1)))
    }
    lines <- c(lines, "")
  }

  if (!is.null(analysis) && !is.null(analysis$cross_group_analysis)) {
    lines <- c(lines, "# Cross-group analysis", "")
    for (field in names(analysis$cross_group_analysis)) {
      values <- analysis$cross_group_analysis[[field]]
      if (length(values) == 0L) next
      title <- gsub("_", " ", field, fixed = TRUE)
      lines <- c(lines, paste0("## ", title))
      lines <- c(lines, vapply(values, .contextualized_format_claim_markdown, character(1)), "")
    }
  }
  paste(lines, collapse = "\n")
}

.contextualized_compact_report <- function(analysis, contextualized_evidence, parsed) {
  groups <- lapply(names(contextualized_evidence$groups), function(group_name) {
    evidence_group <- contextualized_evidence$groups[[group_name]]
    group_analysis <- if (is.null(analysis)) NULL else analysis$groups[[group_name]]
    list(
      group = group_name,
      availability = if (is.null(group_analysis)) "not_generated" else group_analysis$availability,
      integrated_profile = if (is.null(group_analysis)) NULL else group_analysis$integrated_profile,
      main_convergences = if (is.null(group_analysis)) list() else utils::head(group_analysis$statistical_textual_convergences, 3L),
      main_divergences = if (is.null(group_analysis)) list() else utils::head(group_analysis$statistical_textual_divergences, 3L),
      integration_limits = evidence_group$integration_limits
    )
  })
  names(groups) <- names(contextualized_evidence$groups)
  list(parse_status = parsed$parse_status, groups = groups)
}

.contextualized_build_report <- function(analysis,
                                         contextualized_evidence,
                                         parsed,
                                         report_format) {
  switch(
    report_format,
    structured = if (is.null(analysis)) {
      list(
        parse_status = parsed$parse_status,
        groups = lapply(contextualized_evidence$groups, function(x) {
          list(
            group = x$group,
            alignment_status = x$alignment_status,
            available_sources = x$available_sources,
            integration_limits = x$integration_limits
          )
        })
      )
    } else {
      analysis
    },
    markdown = .contextualized_render_markdown(
      analysis,
      contextualized_evidence,
      parsed
    ),
    compact = .contextualized_compact_report(
      analysis,
      contextualized_evidence,
      parsed
    )
  )
}

# ---------------------------------------------------------------------------
# Compatibility extractors retained for downstream and validated tests
# ---------------------------------------------------------------------------

.extract_group_profile_parsed <- function(x) {
  if (is.null(x)) return(NULL)
  if (is.list(x) && is.list(x$groups) && is.data.frame(x$evidence_registry)) {
    return(lapply(x$groups, .catdes_group_to_legacy_summary))
  }
  if (inherits(x, "nail_catdes") &&
      is.list(x$preparation) &&
      inherits(x$preparation$statistical_profiles, "statistical_profiles")) {
    return(lapply(
      x$preparation$statistical_profiles$groups,
      .catdes_group_to_legacy_summary
    ))
  }
  if (is.list(x) && inherits(x$statistical_profiles, "statistical_profiles")) {
    return(lapply(x$statistical_profiles$groups, .catdes_group_to_legacy_summary))
  }
  profiles <- attr(x, "statistical_profiles", exact = TRUE)
  if (inherits(profiles, "statistical_profiles") && is.list(profiles$groups)) {
    return(lapply(profiles$groups, .catdes_group_to_legacy_summary))
  }
  if (is.list(x) && length(x) > 0L) {
    ok <- vapply(x, function(el) is.list(el) && "parsed" %in% names(el), logical(1))
    if (any(ok)) return(lapply(x[ok], function(el) el$parsed))
  }
  NULL
}

.extract_textual_parsed <- function(x) {
  if (is.null(x)) return(NULL)
  if (inherits(x, "nail_textual") && is.list(x$preparation)) x <- x$preparation
  if (is.list(x) && is.list(x$textual_profiles) &&
      is.list(x$textual_profiles$groups)) {
    return(lapply(x$textual_profiles$groups, .textual_profile_group_to_legacy))
  }
  profiles <- attr(x, "textual_profiles", exact = TRUE)
  if (is.list(profiles) && is.list(profiles$groups)) {
    return(lapply(profiles$groups, .textual_profile_group_to_legacy))
  }
  if (is.list(x) && length(x) > 0L) {
    ok <- vapply(x, function(el) is.list(el) && "parsed" %in% names(el), logical(1))
    if (any(ok)) return(lapply(x[ok], function(el) el$parsed))
  }
  NULL
}

.contextualized_modular_parse_error <- function(modular_result) {
  errors <- character()

  for (group_name in names(modular_result$group_units)) {
    unit <- modular_result$group_units[[group_name]]
    if (identical(unit$parse_status, "error")) {
      errors <- c(
        errors,
        paste0(
          "Group `",
          group_name,
          "`: ",
          unit$parse_error
        )
      )
    }
  }

  cross_unit <- modular_result$cross_group_unit
  if (identical(cross_unit$parse_status, "error")) {
    errors <- c(
      errors,
      paste0(
        "Cross-group synthesis: ",
        cross_unit$parse_error
      )
    )
  }

  if (length(errors) == 0L) NULL else paste(errors, collapse = "\n")
}

.contextualized_modular_warnings <- function(modular_result, field) {
  values <- c(
    lapply(
      modular_result$group_units,
      function(unit) unit[[field]]
    ),
    list(modular_result$cross_group_unit[[field]])
  )

  out <- unique(
    unlist(values, use.names = FALSE)
  )

  if (is.null(out)) character() else as.character(out)
}

.contextualized_add_offline_preview_prompts <- function(
    units,
    contextualized_evidence,
    analysis_scope,
    context,
    request,
    prompt_style
) {
  group_names <- intersect(
    names(contextualized_evidence$groups),
    names(units)
  )

  for (group_name in group_names) {
    unit <- units[[group_name]]

    if (!identical(unit$unit_type, "group")) {
      next
    }

    if (is.character(unit$prompt) &&
        length(unit$prompt) == 1L &&
        !is.na(unit$prompt) &&
        nzchar(unit$prompt)) {
      unit$prompt_contract <- "modular"
      units[[group_name]] <- unit
      next
    }

    unit$prompt <- .build_contextualized_prompt(
      contextualized_evidence = contextualized_evidence,
      groups = group_name,
      analysis_scope = analysis_scope,
      comparison_mode = "isolated",
      context = context,
      request = request,
      prompt_style = prompt_style
    )
    unit$prompt_contract <- "compatibility_preview"
    unit$prompt_generation_eligible <- FALSE
    units[[group_name]] <- unit
  }

  units
}

.contextualized_public_modular_units <- function(modular_result,
                                                  include_cross_group = TRUE) {
  units <- lapply(
    modular_result$group_units,
    function(unit) {
      list(
        unit = unit$group,
        unit_type = "group",
        groups = unit$group,
        integration_eligible = unit$integration_eligible,
        prompt = unit$prompt,
        prompt_contract = if (is.null(unit$prompt)) "none" else "modular",
        prompt_generation_eligible = isTRUE(unit$integration_eligible),
        schema = unit$schema,
        response = unit$response,
        parsed = list(
          parse_status = unit$parse_status,
          parse_error = unit$parse_error,
          core_analysis = unit$parsed
        ),
        normalization_warnings = unit$normalization_warnings,
        audit_warnings = unit$audit_warnings,
        elapsed_seconds = unit$elapsed_seconds
      )
    }
  )

  if (isTRUE(include_cross_group)) {
    cross <- modular_result$cross_group_unit
    units$cross_group <- list(
      unit = "cross_group",
      unit_type = "cross_group",
      groups = names(modular_result$core_analysis$groups)[
        vapply(
          modular_result$core_analysis$groups,
          function(group) identical(group$availability, "available"),
          logical(1)
        )
      ],
      integration_eligible = !is.null(cross$prompt),
      prompt = cross$prompt,
      prompt_contract = if (is.null(cross$prompt)) "none" else "modular",
      prompt_generation_eligible = !is.null(cross$prompt),
      schema = cross$schema,
      response = cross$response,
      parsed = list(
        parse_status = cross$parse_status,
        parse_error = cross$parse_error,
        core_analysis = cross$parsed
      ),
      normalization_warnings = cross$normalization_warnings,
      audit_warnings = cross$audit_warnings,
      elapsed_seconds = cross$elapsed_seconds
    )
  }

  units
}

.contextualized_finalize_result <- function(result,
                                            normalized_statistical,
                                            normalized_textual) {
  class(result) <- c("nail_textual_contextualized", "list")

  attr(result, "contextualized_evidence") <- result$contextualized_evidence
  attr(result, "contextualized_analysis") <- result$contextualized_analysis
  attr(result, "statistical_profiles") <- result$statistical_profiles
  attr(result, "textual_evidence") <- result$textual_evidence
  attr(result, "textual_profiles") <- result$textual_profiles
  attr(result, "group_profile_summary") <- .extract_group_profile_parsed(
    normalized_statistical
  )
  attr(result, "textual_group_summary") <- .extract_textual_parsed(
    normalized_textual$preparation
  )
  attr(result, "legacy_output") <- result$legacy_output
  result
}

#' Integrate mechanical statistical profiles and traceable textual profiles
#'
#' `nail_textual_contextualized()` combines three layers without recalculating
#' them: mechanical statistical evidence from [nail_catdes_prep()], exact
#' textual evidence from [nail_textual_prep()], and validated semantic
#' `textual_profiles`. R aligns groups and builds a combined evidence registry.
#' By default, the LLM then receives one small integration request per eligible
#' group, followed by one cross-group synthesis built only from validated group
#' results. The historical monolithic request remains available explicitly.
#'
#' @param group_profile_prep Deprecated-compatible first positional statistical
#'   source. Prefer `statistical_profiles`. It may be a direct result of
#'   [nail_catdes_prep()], an object carrying a `statistical_profiles`
#'   attribute, or a supported legacy prepared object.
#' @param textual_prep Deprecated-compatible second positional textual source.
#'   Prefer `textual_preparation`. It may be a result of
#'   [nail_textual_prep()], a [nail_textual()] result containing its original
#'   preparation, an explicit evidence/profile object, or a supported legacy
#'   prepared object.
#' @param statistical_profiles Preferred statistical source. It cannot be used
#'   simultaneously with `group_profile_prep`.
#' @param textual_preparation Preferred textual source. It cannot be used
#'   simultaneously with `textual_prep`.
#' @param dataset Optional historical raw data frame. Missing prepared sources
#'   are created at most once from this data frame.
#' @param num.var Grouping-column index for raw data.
#' @param num.text Text-column index for raw data.
#' @param group_map Optional named character vector mapping statistical group
#'   names to textual group names. Exact original names are used otherwise;
#'   no fuzzy matching is performed.
#' @param context Optional character scalar or named list of user-provided
#'   context. It is separated from measured and textual evidence in the prompt.
#' @param analysis_scope Public analysis scope retained for upstream textual
#'   preparation, context, and metadata. In modular mode the core expertise is
#'   deliberately limited to evidence integration; specialized expert modules
#'   are not generated in the same call.
#' @param comparison_mode In modular mode, `"joint"` means one request per
#'   eligible group followed by one validated cross-group synthesis;
#'   `"isolated"` omits the cross-group synthesis. In legacy mode it retains
#'   the historical joint-versus-isolated behavior.
#' @param integration_mode `"modular"` (default) or `"legacy"`. Modular mode
#'   uses the validated split architecture. Legacy mode preserves the historical
#'   monolithic JSON contract during the transition.
#' @param expertise Core expertise requested in modular mode. The current
#'   validated value is `"integration"`; specialized expertise will be added
#'   as separate modules rather than mixed into the core request.
#' @param report_format `"structured"`, `"markdown"`, or `"compact"`.
#'   Reporting never modifies evidence or the structured analysis.
#' @param request Optional additional analytical request. It cannot remove the
#'   mandatory evidence, epistemic, or JSON rules.
#' @param prompt_style `"detailed"` or `"compact"`; this changes prompt
#'   presentation only.
#' @param proba Historical raw-data preparation argument forwarded to
#'   [nail_catdes_prep()].
#' @param sample.pct.text Historical raw-data sampling proportion forwarded to
#'   [nail_textual_prep()]. Sampling never occurs inside this function.
#' @param sample.pct.profile Deprecated; statistical profiles now retain all
#'   mechanical markers.
#' @param profile_mode Deprecated presentation argument.
#' @param interpretation_mode Deprecated. Use `comparison_mode`.
#' @param representative_verbatims Deprecated. Exact prompted verbatims are
#'   read from `textual_evidence`.
#' @param include_verbatims Deprecated. Traceable prompts always include the
#'   exact verbatims selected by `nail_textual_prep()`.
#' @param n_central_verbatims,n_tension_verbatims,max_verbatim_chars Deprecated
#'   fallback-selection arguments. This function performs no new selection.
#' @param introduction Deprecated; use `context`.
#' @param conclusion Deprecated; use `request`.
#' @param isolate.groups Deprecated logical alias for `comparison_mode`.
#' @param model LLM model for the final integration. When Gemini is selected
#'   and no model is supplied, the public function uses `gemini-3.5-flash`.
#' @param provider LLM provider, `"ollama"` or `"gemini"`.
#' @param llm_model,llm_engine Optional aliases for `model` and `provider`.
#' @param max_verbatims Maximum exact verbatims included in each modular group
#'   request.
#' @param max_group_claims Maximum convergence and tension claims requested per
#'   modular group. Empty sections are allowed.
#' @param max_cross_claims Maximum claims requested per cross-group section.
#' @param fail_fast Stop on the first modular validation error when `TRUE`;
#'   otherwise preserve valid groups and return a partial result.
#' @param gemini_api_key,gemini_max_output_tokens,gemini_thinking_level Gemini
#'   options for modular generation.
#' @param ollama_url,ollama_num_ctx,ollama_num_predict Ollama options for modular
#'   generation.
#' @param timeout_seconds HTTP timeout for each modular request.
#' @param row.w Optional row weights used only when a missing statistical source
#'   is created from raw data.
#' @param generate Logical. With `FALSE`, all mechanical evidence and prompts
#'   are built without contacting a backend and `contextualized_analysis` is
#'   `NULL`. If a supported legacy prepared object lacks the evidence IDs
#'   required for modular generation, its group unit receives a non-generative
#'   compatibility preview prompt while `integration_eligible` remains `FALSE`.
#' @param ... Provider-specific generation arguments used by the legacy
#'   integration path and by raw textual preparation. Modular integration uses
#'   the explicit Gemini and Ollama arguments documented above.
#'
#' @details
#' The mechanical `contextualized_evidence` object is invariant to provider,
#' model, request, context, analysis scope, comparison mode, report format, and
#' generation. It contains the deterministic `group_alignment`, unmodified
#' upstream profiles and registries, group-specific source availability and
#' limits, and a `combined_evidence_registry` distinguishing statistical
#' qualitative markers, statistical quantitative markers, exact verbatims,
#' and validated textual interpretations.
#'
#' Group alignment uses exact original names. A manual `group_map` is recorded
#' in settings. Statistical-only, textual-only, evidence-without-profile, and
#' profile-without-evidence groups remain explicit; missing sources are never
#' silently imputed.
#'
#' In modular mode, core claims use `expert_interpretation` only. Integrated
#' profiles, convergences, and tensions must cite statistical and textual
#' evidence; source-only findings must cite exactly one source layer.
#' `relationship` is derived deterministically by R from the section rather than
#' generated by the model. Empty sections are valid, methodological limits may
#' rely on coverage metadata without artificial evidence IDs, and unknown or
#' cross-group evidence IDs are rejected. Semantic ambiguities such as forced
#' tensions or source-exclusivity conflicts are returned as audit warnings.
#' Legacy mode retains the previous epistemic validator and full expert schema.
#' In offline modular preparation, supported historical summary-only inputs
#' remain inspectable through `units[[group]]$prompt`; such prompts are marked
#' with `prompt_contract = "compatibility_preview"` and are never treated as
#' generation-eligible evidence contracts.
#'
#' @return An object of class `c("nail_textual_contextualized", "list")`
#'   containing `prompt`, `response`, `parsed`, `contextualized_analysis`,
#'   `contextualized_evidence`, the normalized upstream statistical and textual
#'   artifacts, generation `units`, a derived `report`, a `legacy_output` view,
#'   `core_analysis`, normalization and audit warnings in modular mode, and
#'   `metadata`.
#'
#' @examples
#' \dontrun{
#' stats <- nail_catdes_prep(catdes_result)
#' text <- nail_textual_prep(
#'   dataset, num.var = 1, num.text = 2,
#'   analysis_scope = "consumer", generate = TRUE
#' )
#' integrated <- nail_textual_contextualized(
#'   statistical_profiles = stats,
#'   textual_preparation = text,
#'   analysis_scope = "cross_functional",
#'   comparison_mode = "joint",
#'   generate = FALSE
#' )
#' integrated$contextualized_evidence$group_alignment
#' }
#'
#' @export
nail_textual_contextualized <- function(group_profile_prep = NULL,
                                        textual_prep = NULL,
                                        statistical_profiles = NULL,
                                        textual_preparation = NULL,
                                        dataset = NULL,
                                        num.var = NULL,
                                        num.text = NULL,
                                        group_map = NULL,
                                        context = NULL,
                                        analysis_scope = c(
                                          "cross_functional",
                                          "general",
                                          "sociological",
                                          "consumer",
                                          "psychological",
                                          "marketing",
                                          "innovation"
                                        ),
                                        comparison_mode = c("joint", "isolated"),
                                        integration_mode = c("modular", "legacy"),
                                        expertise = c("integration"),
                                        report_format = c("structured", "markdown", "compact"),
                                        request = NULL,
                                        prompt_style = c("detailed", "compact"),
                                        proba = 0.05,
                                        sample.pct.text = 1,
                                        sample.pct.profile = 1,
                                        profile_mode = c("balanced", "categorical", "quantitative"),
                                        interpretation_mode = NULL,
                                        representative_verbatims = NULL,
                                        include_verbatims = TRUE,
                                        n_central_verbatims = 2,
                                        n_tension_verbatims = 1,
                                        max_verbatim_chars = 220,
                                        introduction = NULL,
                                        conclusion = NULL,
                                        isolate.groups = NULL,
                                        model = "llama3",
                                        provider = c("ollama", "gemini"),
                                        llm_model = NULL,
                                        llm_engine = NULL,
                                        max_verbatims = 12L,
                                        max_group_claims = 2L,
                                        max_cross_claims = 2L,
                                        fail_fast = FALSE,
                                        gemini_api_key = NULL,
                                        gemini_max_output_tokens = 8192L,
                                        gemini_thinking_level = "low",
                                        ollama_url = Sys.getenv(
                                          "OLLAMA_HOST",
                                          unset = "http://127.0.0.1:11434"
                                        ),
                                        ollama_num_ctx = 32768L,
                                        ollama_num_predict = 8192L,
                                        timeout_seconds = 900,
                                        row.w = NULL,
                                        generate = FALSE,
                                        ...) {
  comparison_mode_was_missing <- missing(comparison_mode)
  model_was_missing <- missing(model)
  analysis_scope <- match.arg(analysis_scope)
  comparison_mode <- match.arg(comparison_mode)
  integration_mode <- match.arg(integration_mode)
  expertise <- match.arg(expertise)
  report_format <- match.arg(report_format)
  prompt_style <- match.arg(prompt_style)
  provider <- match.arg(provider)

  if (!is.null(statistical_profiles)) {
    if (!is.null(group_profile_prep)) {
      stop("Use only one of `statistical_profiles` and `group_profile_prep`.", call. = FALSE)
    }
    group_profile_prep <- statistical_profiles
  }
  if (!is.null(textual_preparation)) {
    if (!is.null(textual_prep)) {
      stop("Use only one of `textual_preparation` and `textual_prep`.", call. = FALSE)
    }
    textual_prep <- textual_preparation
  }

  if (!is.null(llm_model)) {
    model <- llm_model
  }
  if (!is.null(llm_engine)) {
    if (!llm_engine %in% c("ollama", "gemini")) {
      stop("`llm_engine` must be `ollama` or `gemini`.", call. = FALSE)
    }
    provider <- llm_engine
  }

  if (
    isTRUE(model_was_missing) &&
    is.null(llm_model) &&
    identical(provider, "gemini")
  ) {
    model <- "gemini-3.5-flash"
  }

  deprecated_mode_alias <- NULL
  if (!is.null(isolate.groups)) {
    if (!is.logical(isolate.groups) || length(isolate.groups) != 1L || is.na(isolate.groups)) {
      stop("`isolate.groups` must be NULL or a single logical value.", call. = FALSE)
    }
    .contextualized_deprecation_warning("isolate.groups", "comparison_mode")
    mapped <- if (isolate.groups) "isolated" else "joint"
    if (!comparison_mode_was_missing && !identical(comparison_mode, mapped)) {
      stop("`isolate.groups` and `comparison_mode` are conflicting.", call. = FALSE)
    }
    comparison_mode <- mapped
    deprecated_mode_alias <- mapped
  }

  if (!is.null(interpretation_mode)) {
    interpretation_mode <- match.arg(interpretation_mode, c("groupwise", "comparative"))
    .contextualized_deprecation_warning("interpretation_mode", "comparison_mode")
    mapped <- if (interpretation_mode == "comparative") "joint" else "isolated"
    if (!is.null(deprecated_mode_alias) && !identical(deprecated_mode_alias, mapped)) {
      stop("`isolate.groups` and `interpretation_mode` are conflicting.", call. = FALSE)
    }
    if (!comparison_mode_was_missing && !identical(comparison_mode, mapped)) {
      stop("`interpretation_mode` and `comparison_mode` are conflicting.", call. = FALSE)
    }
    comparison_mode <- mapped
  }

  if (!missing(sample.pct.profile)) {
    .contextualized_deprecation_warning("sample.pct.profile")
  }
  if (!missing(profile_mode)) {
    .contextualized_deprecation_warning("profile_mode")
  }
  if (!missing(representative_verbatims) && !is.null(representative_verbatims)) {
    .contextualized_deprecation_warning("representative_verbatims")
  }
  if (!missing(include_verbatims) && !isTRUE(include_verbatims)) {
    .contextualized_deprecation_warning("include_verbatims")
  }
  if (!missing(n_central_verbatims)) .contextualized_deprecation_warning("n_central_verbatims")
  if (!missing(n_tension_verbatims)) .contextualized_deprecation_warning("n_tension_verbatims")
  if (!missing(max_verbatim_chars)) .contextualized_deprecation_warning("max_verbatim_chars")

  context <- .contextualized_validate_context(context)
  if (!is.null(introduction)) {
    .contextualized_deprecation_warning("introduction", "context")
    context$legacy_introduction <- introduction
  }
  if (!is.null(conclusion)) {
    .contextualized_deprecation_warning("conclusion", "request")
    request <- paste(c(request, conclusion), collapse = "\n\n")
  }
  if (!is.null(request) && !.contextualized_is_scalar_string(request)) {
    stop("`request` must be NULL or a non-empty character scalar.", call. = FALSE)
  }
  if (!is.logical(generate) || length(generate) != 1L || is.na(generate)) {
    stop("`generate` must be a single non-missing logical value.", call. = FALSE)
  }
  if (!is.numeric(sample.pct.text) || length(sample.pct.text) != 1L ||
      is.na(sample.pct.text) || sample.pct.text < 0 || sample.pct.text > 1) {
    stop("`sample.pct.text` must be in [0, 1].", call. = FALSE)
  }

  upstream_calls <- list(
    nail_catdes_prep = 0L,
    nail_textual_prep = 0L,
    catdes = 0L
  )
  raw_input_used <- !is.null(dataset)

  if (is.null(group_profile_prep)) {
    if (is.null(dataset)) {
      stop("Provide `statistical_profiles`/`group_profile_prep` or `dataset`.", call. = FALSE)
    }
    if (!is.data.frame(dataset)) stop("`dataset` must be a data frame.", call. = FALSE)
    if (is.null(num.var)) stop("`num.var` is required for raw data.", call. = FALSE)
    group_profile_prep <- suppressWarnings(nail_catdes_prep(
      dataset = dataset,
      num.var = num.var,
      exclude = num.text,
      proba = proba,
      row.w = row.w
    ))
    upstream_calls$nail_catdes_prep <- 1L
    upstream_calls$catdes <- 1L
  }

  if (is.null(textual_prep)) {
    if (is.null(dataset)) {
      stop("Provide `textual_preparation`/`textual_prep` or `dataset`.", call. = FALSE)
    }
    if (!is.data.frame(dataset)) stop("`dataset` must be a data frame.", call. = FALSE)
    if (is.null(num.var) || is.null(num.text)) {
      stop("`num.var` and `num.text` are required for raw textual data.", call. = FALSE)
    }
    textual_prep <- nail_textual_prep(
      dataset = dataset,
      num.var = num.var,
      num.text = num.text,
      sample.pct = sample.pct.text,
      analysis_scope = analysis_scope,
      comparison_mode = comparison_mode,
      context = context,
      request = request,
      prompt_style = prompt_style,
      model = model,
      provider = provider,
      generate = generate,
      ...
    )
    upstream_calls$nail_textual_prep <- 1L
  }

  normalized_statistical <- .normalize_contextualized_statistical_input(
    group_profile_prep
  )
  normalized_textual <- .normalize_contextualized_textual_input(textual_prep)

  contextualized_evidence <- .build_contextualized_evidence(
    statistical_profiles = normalized_statistical,
    textual_input = normalized_textual,
    group_map = group_map
  )

  if (identical(integration_mode, "modular")) {
    if (!analysis_scope %in% c("cross_functional", "general")) {
      warning(
        paste0(
          "`analysis_scope = \"",
          analysis_scope,
          "\"` is recorded, but modular core generation uses ",
          "`expertise = \"integration\"` only. Specialized expertise must be ",
          "requested through a separate future module."
        ),
        call. = FALSE
      )
    }

    modular_result <- nail_textual_contextualized_modular(
      x = contextualized_evidence,
      provider = provider,
      model = model,
      generate = generate,
      context = context,
      request = request,
      analysis_scope = analysis_scope,
      prompt_style = prompt_style,
      cross_group = identical(comparison_mode, "joint"),
      max_verbatims = max_verbatims,
      max_group_claims = max_group_claims,
      max_cross_claims = max_cross_claims,
      fail_fast = fail_fast,
      gemini_api_key = gemini_api_key,
      gemini_max_output_tokens = gemini_max_output_tokens,
      gemini_thinking_level = gemini_thinking_level,
      ollama_url = ollama_url,
      ollama_num_ctx = ollama_num_ctx,
      ollama_num_predict = ollama_num_predict,
      timeout_seconds = timeout_seconds
    )

    units <- .contextualized_public_modular_units(
      modular_result,
      include_cross_group = identical(comparison_mode, "joint")
    )
    if (!isTRUE(generate)) {
      units <- .contextualized_add_offline_preview_prompts(
        units = units,
        contextualized_evidence = contextualized_evidence,
        analysis_scope = analysis_scope,
        context = context,
        request = request,
        prompt_style = prompt_style
      )
    }
    prompt <- lapply(units, function(unit) unit$prompt)
    response <- if (generate) {
      lapply(units, function(unit) unit$response)
    } else {
      NULL
    }

    available_groups <- vapply(
      modular_result$core_analysis$groups,
      function(group) identical(group$availability, "available"),
      logical(1)
    )
    analysis <- if (generate && any(available_groups)) {
      modular_result$compatibility_view
    } else {
      NULL
    }

    if (!is.null(analysis)) {
      analysis$metadata$analysis_scope <- analysis_scope
      analysis$metadata$comparison_mode <- comparison_mode
      analysis$metadata$integration_mode <- integration_mode
      analysis$metadata$expertise <- expertise
      analysis$metadata$parse_status <- modular_result$metadata$parse_status
    }

    parsed <- list(
      parse_status = modular_result$metadata$parse_status,
      parse_error = .contextualized_modular_parse_error(modular_result),
      contextualized_analysis = analysis,
      core_analysis = modular_result$core_analysis
    )
    normalization_warnings <- .contextualized_modular_warnings(
      modular_result,
      "normalization_warnings"
    )
    audit_warnings <- .contextualized_modular_warnings(
      modular_result,
      "audit_warnings"
    )
    report <- .contextualized_build_report(
      analysis = analysis,
      contextualized_evidence = contextualized_evidence,
      parsed = parsed,
      report_format = report_format
    )

    result <- list(
      prompt = prompt,
      response = response,
      parsed = parsed,
      contextualized_analysis = analysis,
      core_analysis = modular_result$core_analysis,
      contextualized_evidence = contextualized_evidence,
      statistical_profiles = normalized_statistical,
      textual_evidence = normalized_textual$textual_evidence,
      textual_profiles = normalized_textual$textual_profiles,
      textual_preparation = normalized_textual$preparation,
      units = units,
      report = report,
      normalization_warnings = normalization_warnings,
      audit_warnings = audit_warnings,
      legacy_output = if (generate) response else prompt,
      metadata = list(
        schema = "NaileR::nail_textual_contextualized",
        analysis_scope = analysis_scope,
        comparison_mode = comparison_mode,
        integration_mode = integration_mode,
        expertise = expertise,
        split_by_group = TRUE,
        cross_group = identical(comparison_mode, "joint"),
        report_format = report_format,
        generate = generate,
        provider = provider,
        model = model,
        parse_status = modular_result$metadata$parse_status,
        groups = names(contextualized_evidence$groups),
        group_map = .contextualized_validate_group_map(group_map),
        raw_input_used = raw_input_used,
        upstream_calls = upstream_calls,
        integration_llm_calls = modular_result$metadata$n_group_calls +
          modular_result$metadata$n_cross_group_calls,
        group_parse_status = modular_result$core_analysis$metadata$group_parse_status,
        group_integration_eligible =
          modular_result$core_analysis$metadata$group_integration_eligible,
        cross_group_parse_status =
          modular_result$core_analysis$metadata$cross_group_parse_status,
        normalization_warning_count = length(normalization_warnings),
        audit_warning_count = length(audit_warnings),
        textual_generation_status = normalized_textual$generation_status,
        context = context,
        request = request
      )
    )

    return(
      .contextualized_finalize_result(
        result,
        normalized_statistical,
        normalized_textual
      )
    )
  }

  units <- .build_contextualized_units(
    contextualized_evidence = contextualized_evidence,
    analysis_scope = analysis_scope,
    comparison_mode = comparison_mode,
    context = context,
    request = request,
    prompt_style = prompt_style
  )

  llm_calls <- 0L
  if (generate && length(units) > 0L) {
    llm_api_options <- list(...)
    for (unit_name in names(units)) {
      response <- .call_llm_base(
        provider = provider,
        model = model,
        prompt = units[[unit_name]]$prompt,
        output = "df",
        llm_api_options = llm_api_options
      )
      llm_calls <- llm_calls + 1L
      units[[unit_name]]$response <- response
      units[[unit_name]]$parsed <- .parse_textual_contextualized_response(
        text = .contextualized_response_text(response),
        expected_groups = units[[unit_name]]$groups,
        contextualized_evidence = contextualized_evidence,
        context = context,
        analysis_scope = analysis_scope,
        comparison_mode = comparison_mode
      )
    }
  }

  parsed <- .combine_contextualized_units(
    units = units,
    all_groups = names(contextualized_evidence$groups),
    analysis_scope = analysis_scope,
    comparison_mode = comparison_mode
  )
  analysis <- parsed$contextualized_analysis
  report <- .contextualized_build_report(
    analysis = analysis,
    contextualized_evidence = contextualized_evidence,
    parsed = parsed,
    report_format = report_format
  )

  prompt <- if (comparison_mode == "joint") {
    if (length(units) == 0L) NULL else units[[1L]]$prompt
  } else {
    lapply(units, function(x) x$prompt)
  }
  response <- if (!generate) {
    NULL
  } else if (comparison_mode == "joint") {
    if (length(units) == 0L) NULL else units[[1L]]$response
  } else {
    lapply(units, function(x) x$response)
  }

  result <- list(
    prompt = prompt,
    response = response,
    parsed = parsed,
    contextualized_analysis = analysis,
    contextualized_evidence = contextualized_evidence,
    statistical_profiles = normalized_statistical,
    textual_evidence = normalized_textual$textual_evidence,
    textual_profiles = normalized_textual$textual_profiles,
    textual_preparation = normalized_textual$preparation,
    units = units,
    report = report,
    legacy_output = if (generate) response else prompt,
    metadata = list(
      schema = "NaileR::nail_textual_contextualized",
      analysis_scope = analysis_scope,
      comparison_mode = comparison_mode,
      integration_mode = integration_mode,
      expertise = expertise,
      report_format = report_format,
      generate = generate,
      provider = provider,
      model = model,
      parse_status = parsed$parse_status,
      groups = names(contextualized_evidence$groups),
      group_map = .contextualized_validate_group_map(group_map),
      raw_input_used = raw_input_used,
      upstream_calls = upstream_calls,
      integration_llm_calls = llm_calls,
      textual_generation_status = normalized_textual$generation_status,
      context = context,
      request = request
    )
  )
  .contextualized_finalize_result(
    result,
    normalized_statistical,
    normalized_textual
  )
}
