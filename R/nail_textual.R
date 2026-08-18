# ---------------------------------------------------------------------------
# nail_textual(): deterministic reporting from nail_textual_prep()
# ---------------------------------------------------------------------------

.nail_textual_report_formats <- c("structured", "markdown", "compact")

.nail_textual_is_scalar_string <- function(x, allow_empty = FALSE) {
  is.character(x) && length(x) == 1L && !is.na(x) &&
    (allow_empty || nzchar(trimws(x)))
}

.nail_textual_is_preparation <- function(x) {
  inherits(x, "nail_textual_prep") ||
    (is.list(x) && !is.data.frame(x) &&
       all(c("textual_evidence", "units", "metadata") %in% names(x)))
}

.nail_textual_validate_preparation <- function(x) {
  if (!.nail_textual_is_preparation(x)) {
    stop(
      "`x` must be a valid object returned by `nail_textual_prep()`.",
      call. = FALSE
    )
  }
  if (!is.list(x$textual_evidence) || is.null(x$textual_evidence$evidence_registry)) {
    stop("The preparation does not contain a valid `textual_evidence` object.", call. = FALSE)
  }
  if (!is.list(x$units)) {
    stop("The preparation does not contain valid generation `units`.", call. = FALSE)
  }
  if (!is.list(x$metadata)) {
    stop("The preparation does not contain valid `metadata`.", call. = FALSE)
  }
  invisible(TRUE)
}

.nail_textual_as_context <- function(x, name) {
  if (is.null(x)) return(list())
  if (is.character(x) && length(x) == 1L && !is.na(x)) {
    return(stats::setNames(list(x), name))
  }
  if (!is.list(x) || is.data.frame(x)) {
    stop(sprintf("`%s` must be NULL, a character scalar, or a named list.", name), call. = FALSE)
  }
  if (length(x) > 0L && (is.null(names(x)) || any(!nzchar(names(x))))) {
    stop(sprintf("`%s` must be a named list.", name), call. = FALSE)
  }
  x
}

.nail_textual_claim <- function(text, evidence_ids = character(0)) {
  list(
    text = text,
    status = "user_context",
    evidence_ids = evidence_ids,
    validation_needed = NULL
  )
}

.nail_textual_claim_text <- function(x) {
  if (is.null(x) || !is.list(x) || is.null(x$text)) return(NA_character_)
  as.character(x$text)
}

.nail_textual_claims <- function(x) {
  if (is.null(x) || length(x) == 0L) return(list())
  x[vapply(x, function(item) is.list(item) && !is.null(item$text), logical(1))]
}

.nail_textual_profile_available <- function(x) {
  is.list(x) && !is.data.frame(x) &&
    !is.null(x$group) &&
    any(vapply(
      x[c(
        "core_textual_profile", "main_themes", "dominant_concerns",
        "tone_or_stance", "narrative_frames", "motivations", "barriers",
        "perceived_benefits", "social_norms", "identity_cues",
        "contradictions", "minority_positions", "representative_verbatims",
        "tension_verbatims", "intra_group_consistency"
      )],
      function(value) !is.null(value) && length(value) > 0L,
      logical(1)
    ))
}

.nail_textual_collect_profiles <- function(preparation) {
  if (!is.null(preparation$textual_profiles) &&
      is.list(preparation$textual_profiles$groups)) {
    return(list(
      profiles = preparation$textual_profiles,
      source = "validated_textual_profiles"
    ))
  }

  groups <- list()
  cross_group <- .textual_prep_empty_cross_group()
  for (unit in preparation$units) {
    parsed <- unit$parsed
    if (is.null(parsed) || !identical(parsed$parse_status, "success") ||
        is.null(parsed$textual_profiles)) {
      next
    }
    groups <- c(groups, parsed$textual_profiles$groups)
    if (!is.null(parsed$textual_profiles$cross_group) &&
        any(lengths(parsed$textual_profiles$cross_group) > 0L)) {
      cross_group <- parsed$textual_profiles$cross_group
    }
  }

  if (length(groups) == 0L) {
    return(list(profiles = NULL, source = "none"))
  }

  all_groups <- names(preparation$textual_evidence$groups)
  groups <- groups[!duplicated(names(groups))]
  groups <- groups[intersect(all_groups, names(groups))]

  list(
    profiles = list(
      groups = groups,
      cross_group = cross_group,
      metadata = list(
        analysis_scope = preparation$metadata$analysis_scope,
        comparison_mode = preparation$metadata$comparison_mode,
        groups = names(groups),
        parse_status = "partial"
      )
    ),
    source = "valid_generation_units"
  )
}

.nail_textual_unit_errors <- function(preparation) {
  if (length(preparation$units) == 0L) return(list())
  out <- lapply(names(preparation$units), function(unit_name) {
    unit <- preparation$units[[unit_name]]
    parsed <- unit$parsed
    status <- if (is.null(parsed$parse_status)) "unknown" else parsed$parse_status
    if (!status %in% c("error", "no_evidence")) return(NULL)
    list(
      unit = unit_name,
      groups = unit$groups,
      parse_status = status,
      parse_error = parsed$parse_error
    )
  })
  Filter(Negate(is.null), out)
}

.nail_textual_group_diagnostics <- function(preparation, group_name) {
  diagnostics <- preparation$textual_evidence$group_diagnostics
  if (!is.data.frame(diagnostics) || !"group" %in% names(diagnostics)) {
    return(NULL)
  }
  row <- diagnostics[diagnostics$group == group_name, , drop = FALSE]
  if (nrow(row) == 0L) NULL else row[1L, , drop = FALSE]
}

.nail_textual_mechanical_limits <- function(preparation, group_name) {
  diag <- .nail_textual_group_diagnostics(preparation, group_name)
  if (is.null(diag)) {
    return(list(.nail_textual_claim(
      "No mechanical group diagnostics were available for this group."
    )))
  }

  limits <- list()
  n_non_empty <- diag$n_non_empty[[1]]
  n_included <- diag$n_included_in_prompt[[1]]
  n_total <- diag$n_total[[1]]

  if (identical(n_non_empty, 0L)) {
    limits <- c(limits, list(.nail_textual_claim(
      "No non-empty verbatim was available for this group."
    )))
  } else if (identical(n_non_empty, 1L)) {
    limits <- c(limits, list(.nail_textual_claim(
      "Only one non-empty verbatim was available; recurring group-level patterns cannot be established from repetition."
    )))
  }

  if (n_total > n_non_empty) {
    limits <- c(limits, list(.nail_textual_claim(sprintf(
      "%d of %d source rows contained a non-empty verbatim.",
      n_non_empty,
      n_total
    ))))
  }

  if (n_non_empty > 0L && n_included == 0L) {
    limits <- c(limits, list(.nail_textual_claim(
      "No verbatim from this group was included in the semantic-analysis prompt."
    )))
  }

  if (n_non_empty > 0L && n_included < n_non_empty) {
    limits <- c(limits, list(.nail_textual_claim(sprintf(
      "%d of %d non-empty verbatims were included in the semantic-analysis prompt.",
      n_included,
      n_non_empty
    ))))
  }

  if ("n_prompt_budget" %in% names(diag) && diag$n_prompt_budget[[1]] > 0L) {
    limits <- c(limits, list(.nail_textual_claim(sprintf(
      "%d non-empty verbatim(s) were excluded by the prompt character budget.",
      diag$n_prompt_budget[[1]]
    ))))
  }

  unit_errors <- .nail_textual_unit_errors(preparation)
  for (error in unit_errors) {
    if (group_name %in% error$groups) {
      limits <- c(limits, list(.nail_textual_claim(paste0(
        "Semantic generation status for unit `", error$unit, "`: ",
        error$parse_status,
        if (!is.null(error$parse_error) && nzchar(error$parse_error)) {
          paste0(" (", error$parse_error, ")")
        } else {
          ""
        },
        "."
      ))))
    }
  }

  limits
}

.nail_textual_deduplicate_limits <- function(x) {
  if (length(x) == 0L) return(list())
  texts <- vapply(x, .nail_textual_claim_text, character(1))
  x[!duplicated(texts)]
}

.nail_textual_build_group_report <- function(preparation, profile, group_name) {
  diagnostics <- .nail_textual_group_diagnostics(preparation, group_name)
  mechanical_limits <- .nail_textual_mechanical_limits(preparation, group_name)

  if (is.null(profile) || !.nail_textual_profile_available(profile)) {
    return(list(
      group = group_name,
      availability = "unavailable",
      central_profile = NULL,
      central_patterns = list(main_themes = list(), dominant_concerns = list()),
      orientation = list(tone_or_stance = NULL, narrative_frames = list()),
      expressed_drivers = list(
        motivations = list(),
        barriers = list(),
        perceived_benefits = list()
      ),
      social_and_identity_cues = list(social_norms = list(), identity_cues = list()),
      tensions_and_diversity = list(
        contradictions = list(),
        minority_positions = list(),
        intra_group_consistency = NULL
      ),
      verbatim_evidence = list(representative = list(), tension = list()),
      interpretation_limits = mechanical_limits,
      diagnostics = diagnostics
    ))
  }

  semantic_limits <- .nail_textual_claims(profile$interpretation_limits)
  list(
    group = group_name,
    availability = "available",
    central_profile = profile$core_textual_profile,
    central_patterns = list(
      main_themes = .nail_textual_claims(profile$main_themes),
      dominant_concerns = .nail_textual_claims(profile$dominant_concerns)
    ),
    orientation = list(
      tone_or_stance = profile$tone_or_stance,
      narrative_frames = .nail_textual_claims(profile$narrative_frames)
    ),
    expressed_drivers = list(
      motivations = .nail_textual_claims(profile$motivations),
      barriers = .nail_textual_claims(profile$barriers),
      perceived_benefits = .nail_textual_claims(profile$perceived_benefits)
    ),
    social_and_identity_cues = list(
      social_norms = .nail_textual_claims(profile$social_norms),
      identity_cues = .nail_textual_claims(profile$identity_cues)
    ),
    tensions_and_diversity = list(
      contradictions = .nail_textual_claims(profile$contradictions),
      minority_positions = .nail_textual_claims(profile$minority_positions),
      intra_group_consistency = profile$intra_group_consistency
    ),
    verbatim_evidence = list(
      representative = profile$representative_verbatims,
      tension = profile$tension_verbatims
    ),
    interpretation_limits = .nail_textual_deduplicate_limits(c(
      semantic_limits,
      mechanical_limits
    )),
    diagnostics = diagnostics
  )
}

.nail_textual_build_cross_group_report <- function(preparation, profiles) {
  comparison_mode <- preparation$metadata$comparison_mode
  if (is.null(profiles) || is.null(profiles$cross_group) ||
      all(lengths(profiles$cross_group) == 0L)) {
    reason <- if (identical(comparison_mode, "isolated")) {
      paste(
        "No validated cross-group interpretation is available because the",
        "preparation was generated in isolated mode."
      )
    } else {
      "No validated cross-group interpretation is available."
    }
    return(list(
      availability = "unavailable",
      shared_themes = list(),
      group_contrasts = list(),
      minority_patterns = list(),
      interpretation_limits = list(.nail_textual_claim(reason))
    ))
  }

  list(
    availability = "available",
    shared_themes = .nail_textual_claims(profiles$cross_group$shared_themes),
    group_contrasts = .nail_textual_claims(profiles$cross_group$group_contrasts),
    minority_patterns = .nail_textual_claims(profiles$cross_group$minority_patterns),
    interpretation_limits = .nail_textual_claims(
      profiles$cross_group$interpretation_limits
    )
  )
}

.nail_textual_build_reports <- function(preparation) {
  collected <- .nail_textual_collect_profiles(preparation)
  profiles <- collected$profiles
  group_names <- names(preparation$textual_evidence$groups)
  available_groups <- if (is.null(profiles)) character(0) else names(profiles$groups)

  group_reports <- stats::setNames(lapply(group_names, function(group_name) {
    profile <- if (group_name %in% available_groups) profiles$groups[[group_name]] else NULL
    .nail_textual_build_group_report(preparation, profile, group_name)
  }), group_names)

  n_available <- sum(vapply(
    group_reports,
    function(x) identical(x$availability, "available"),
    logical(1)
  ))
  report_status <- if (n_available == length(group_reports) && n_available > 0L) {
    "complete"
  } else if (n_available > 0L) {
    "partial"
  } else if (identical(preparation$parsed$parse_status, "error")) {
    "error"
  } else {
    "mechanical_only"
  }

  list(
    group_reports = group_reports,
    cross_group_report = .nail_textual_build_cross_group_report(preparation, profiles),
    profiles_for_reporting = profiles,
    profile_source = collected$source,
    report_status = report_status
  )
}

.nail_textual_format_evidence <- function(x) {
  ids <- x$evidence_ids
  if (is.null(ids) || length(ids) == 0L) return("")
  paste0(" [evidence: ", paste(ids, collapse = ", "), "]")
}

.nail_textual_format_claim <- function(x) {
  if (is.null(x) || !is.list(x) || is.null(x$text)) return(character(0))
  validation <- if (!is.null(x$validation_needed) && nzchar(x$validation_needed)) {
    paste0(" Validation needed: ", x$validation_needed)
  } else {
    ""
  }
  paste0(
    x$text,
    .nail_textual_format_evidence(x),
    " {", x$status, "}.",
    validation
  )
}

.nail_textual_markdown_claims <- function(title, claims) {
  claims <- .nail_textual_claims(claims)
  if (length(claims) == 0L) return(character(0))
  c(
    paste0("### ", title),
    vapply(claims, function(x) paste0("- ", .nail_textual_format_claim(x)), character(1)),
    ""
  )
}

.nail_textual_markdown_quote <- function(x) {
  if (is.null(x$quotation)) return(character(0))
  quotation <- gsub("\r\n|\r", "\n", x$quotation)
  quoted <- paste0("> ", strsplit(quotation, "\n", fixed = TRUE)[[1]])
  c(
    quoted,
    paste0(
      "- Evidence: `", x$evidence_id, "`",
      if (!is.null(x$rationale) && nzchar(x$rationale)) paste0(" - ", x$rationale) else ""
    )
  )
}

.nail_textual_render_group_markdown <- function(report, compact = FALSE) {
  out <- c(paste0("## Group: ", report$group), "")
  if (!identical(report$availability, "available")) {
    out <- c(out, "No validated semantic profile is available for this group.", "")
    return(c(
      out,
      .nail_textual_markdown_claims("Methodological limits", report$interpretation_limits)
    ))
  }

  if (!is.null(report$central_profile)) {
    out <- c(
      out,
      "### Central textual profile",
      .nail_textual_format_claim(report$central_profile),
      ""
    )
  }

  themes <- report$central_patterns$main_themes
  concerns <- report$central_patterns$dominant_concerns
  contradictions <- report$tensions_and_diversity$contradictions
  minority <- report$tensions_and_diversity$minority_positions
  representative <- report$verbatim_evidence$representative

  if (compact) {
    themes <- utils::head(themes, 3L)
    concerns <- utils::head(concerns, 2L)
    contradictions <- utils::head(contradictions, 2L)
    minority <- utils::head(minority, 1L)
    representative <- utils::head(representative, 1L)
  }

  out <- c(
    out,
    .nail_textual_markdown_claims("Main themes", themes),
    .nail_textual_markdown_claims("Dominant concerns", concerns)
  )

  if (!compact) {
    out <- c(
      out,
      .nail_textual_markdown_claims(
        "Tone or stance",
        if (is.null(report$orientation$tone_or_stance)) list() else list(report$orientation$tone_or_stance)
      ),
      .nail_textual_markdown_claims("Narrative frames", report$orientation$narrative_frames),
      .nail_textual_markdown_claims("Motivations", report$expressed_drivers$motivations),
      .nail_textual_markdown_claims("Barriers", report$expressed_drivers$barriers),
      .nail_textual_markdown_claims("Perceived benefits", report$expressed_drivers$perceived_benefits),
      .nail_textual_markdown_claims("Social norms", report$social_and_identity_cues$social_norms),
      .nail_textual_markdown_claims("Identity cues", report$social_and_identity_cues$identity_cues)
    )
  }

  out <- c(
    out,
    .nail_textual_markdown_claims("Contradictions", contradictions),
    .nail_textual_markdown_claims("Minority positions", minority)
  )

  if (!compact && !is.null(report$tensions_and_diversity$intra_group_consistency)) {
    out <- c(
      out,
      "### Intra-group consistency",
      .nail_textual_format_claim(report$tensions_and_diversity$intra_group_consistency),
      ""
    )
  }

  if (length(representative) > 0L) {
    out <- c(out, "### Representative verbatim evidence")
    for (quote in representative) {
      out <- c(out, .nail_textual_markdown_quote(quote), "")
    }
  }

  if (!compact && length(report$verbatim_evidence$tension) > 0L) {
    out <- c(out, "### Tension verbatim evidence")
    for (quote in report$verbatim_evidence$tension) {
      out <- c(out, .nail_textual_markdown_quote(quote), "")
    }
  }

  c(out, .nail_textual_markdown_claims(
    "Methodological and interpretation limits",
    report$interpretation_limits
  ))
}

.nail_textual_render_cross_markdown <- function(report, compact = FALSE) {
  out <- c("# Cross-group reading", "")
  if (!identical(report$availability, "available")) {
    return(c(
      out,
      "No validated cross-group interpretation is available.",
      "",
      .nail_textual_markdown_claims("Limits", report$interpretation_limits)
    ))
  }

  shared <- report$shared_themes
  contrasts <- report$group_contrasts
  minority <- report$minority_patterns
  if (compact) {
    shared <- utils::head(shared, 3L)
    contrasts <- utils::head(contrasts, 3L)
    minority <- utils::head(minority, 2L)
  }

  c(
    out,
    .nail_textual_markdown_claims("Shared themes", shared),
    .nail_textual_markdown_claims("Group contrasts", contrasts),
    .nail_textual_markdown_claims("Minority patterns", minority),
    .nail_textual_markdown_claims("Cross-group limits", report$interpretation_limits)
  )
}

.nail_textual_render_report <- function(group_reports,
                                        cross_group_report,
                                        report_format,
                                        report_request,
                                        report_context) {
  if (identical(report_format, "structured")) {
    return(list(
      groups = group_reports,
      cross_group = cross_group_report,
      report_request = report_request,
      report_context = report_context
    ))
  }

  compact <- identical(report_format, "compact")
  title <- if (compact) "# Compact textual report" else "# Textual analysis report"
  out <- c(title, "")

  if (!is.null(report_request)) {
    out <- c(out, "## Report-stage request", report_request, "")
  }
  if (length(report_context) > 0L) {
    out <- c(
      out,
      "## Report-stage context",
      paste0(
        "- ", names(report_context), ": ",
        vapply(
          report_context,
          function(value) paste(unlist(value, recursive = TRUE, use.names = FALSE), collapse = "; "),
          character(1)
        )
      ),
      ""
    )
  }

  for (group_report in group_reports) {
    out <- c(out, .nail_textual_render_group_markdown(group_report, compact = compact))
  }
  out <- c(out, .nail_textual_render_cross_markdown(cross_group_report, compact = compact))
  paste(out, collapse = "\n")
}

.nail_textual_legacy_output <- function(preparation) {
  comparison_mode <- preparation$metadata$comparison_mode
  generated <- isTRUE(preparation$metadata$generate)

  if (identical(comparison_mode, "joint")) {
    unit <- preparation$units[["joint"]]
    if (!generated) return(unit$prompt)
    return(list(prompt = unit$prompt, response = unit$response, parsed = unit$parsed))
  }

  if (!generated) {
    return(lapply(preparation$units, `[[`, "prompt"))
  }
  lapply(preparation$units, function(unit) {
    list(prompt = unit$prompt, response = unit$response, parsed = unit$parsed)
  })
}


.nail_textual_prompt_view <- function(preparation) {
  prompts <- lapply(preparation$units, function(unit) unit$prompt)
  stats::setNames(prompts, names(preparation$units))
}

.nail_textual_resume_preparation <- function(preparation,
                                             provider,
                                             model,
                                             llm_api_options) {
  .nail_textual_validate_preparation(preparation)
  .nail_text_complete_preparation(
    preparation = preparation,
    provider = provider,
    model = model,
    llm_api_options = llm_api_options
  )
}

#' Report a traceable textual analysis
#'
#' `nail_textual()` is the user-facing reporting layer for grouped open-ended
#' texts. It delegates corpus validation, deterministic sampling, constrained
#' semantic generation, JSON parsing, and epistemic validation to
#' [nail_textual_prep()]. It exposes the canonical `textual_description` and
#' derives the historical `textual_profiles` view used by existing reports.
#'
#' The preferred input is an existing `nail_textual_prep` object supplied with
#' `x`. Raw data remain supported through `dataset`, `num.var`, and `num.text`;
#' in that path `nail_textual_prep()` is called exactly once.
#'
#' @param dataset Either a data frame containing a grouping column and a text
#'   column, or, for positional backward compatibility, a prepared object
#'   returned by [nail_textual_prep()].
#' @param num.var Integer position of the grouping column for raw data.
#' @param num.text Integer position of the text column for raw data.
#' @param x Optional prepared object returned by [nail_textual_prep()]. Supply
#'   either `x` or `dataset`, not both.
#' @param introduction Deprecated historical prompt introduction. For raw input
#'   it is preserved as user context for `nail_textual_prep()`; for prepared
#'   input it is retained only as report-stage context.
#' @param request Preparation-stage analytical request for raw input. It is
#'   passed once to [nail_textual_prep()]. It cannot be supplied for an already
#'   prepared object because it would falsely imply that the existing profiles
#'   were generated with that request.
#' @param conclusion Deprecated historical output instruction. It is preserved
#'   as a report-stage request and does not alter validated profiles.
#' @param model LLM model used only when semantic generation is required.
#' @param provider LLM provider used only when semantic generation is required.
#' @param isolate.groups Deprecated compatibility argument. Use
#'   `comparison_mode` instead.
#' @param sample.pct Proportion of non-empty verbatims sampled within each group
#'   when raw data are prepared.
#' @param seed Optional deterministic sampling seed passed to
#'   [nail_textual_prep()].
#' @param prompt_style Prompt detail level passed to [nail_textual_prep()] for
#'   raw data.
#' @param text_role Terminology used only in preparation prompts to refer to
#'   the source texts. It has no effect on evidence or analysis.
#' @param generate Logical. With raw input, controls the single call to
#'   [nail_textual_prep()]. With an offline prepared object, `TRUE` completes
#'   generation from its existing units and prompts without rebuilding any
#'   evidence or sampling. Existing validated profiles are never regenerated by
#'   default.
#' @param analysis_scope Optional analytical scope. For raw input the default is
#'   `"general"`. For prepared input the stored scope is reused. Requesting a
#'   different scope for existing profiles is rejected explicitly.
#' @param comparison_mode Optional `"isolated"` or `"joint"` preparation mode.
#'   For prepared input the stored mode is authoritative.
#' @param report_format One of `"structured"`, `"markdown"`, or `"compact"`.
#'   Formats change only the deterministic report, never the evidence or
#'   profiles.
#' @param report_request Optional presentation-stage request. It is recorded
#'   separately from the preparation request and cannot change the semantic
#'   profiles.
#' @param context Optional preparation-stage context for raw input. For prepared
#'   input, use `report_context` for late contextual information.
#' @param report_context Optional character scalar or named list recorded only
#'   at the reporting stage. It is never presented as textual evidence.
#' @param ... Additional arguments. For raw input they are passed once to
#'   [nail_textual_prep()]. When completing an offline preparation, they are
#'   passed as provider-specific LLM options.
#'
#' @return An object of class `nail_textual` containing:
#'   * `report`, the requested deterministic report format;
#'   * `prompt`, the named generation prompts used by the preparation;
#'   * `group_reports` and `cross_group_report`, the stable reporting views;
#'   * `textual_description`, the canonical claim-based semantic contract;
#'   * unchanged `textual_profiles` compatibility data and `textual_evidence`;
#'   * `preparation`, `generation`, and `validation`;
#'   * `legacy_output`, a compatibility view of prompts and raw responses;
#'   * `metadata`, including exact preparation and LLM call counts.
#'
#' If semantic profiles are unavailable, no interpretation is invented. The
#' result remains usable as a mechanical report of diagnostics, prompts, and
#' explicit generation or parsing status.
#'
#' @examples
#' text_data <- data.frame(
#'   group = factor(c("A", "A", "B", "B")),
#'   comment = c(
#'     "Fresh and easy to eat.",
#'     "Light and floral.",
#'     "Dark and intense.",
#'     "Strong cocoa character."
#'   )
#' )
#'
#' offline <- nail_textual(
#'   dataset = text_data,
#'   num.var = 1,
#'   num.text = 2,
#'   generate = FALSE,
#'   report_format = "structured",
#'   lexical_analysis = FALSE,
#'   compute_length_analysis = FALSE
#' )
#' offline$textual_evidence$group_diagnostics
#' offline$preparation$prompt
#'
#' prep <- nail_textual_prep(
#'   text_data, 1, 2,
#'   generate = FALSE,
#'   lexical_analysis = FALSE,
#'   compute_length_analysis = FALSE
#' )
#' report <- nail_textual(x = prep, generate = FALSE)
#' identical(report$textual_evidence, prep$textual_evidence)
#'
#' @export
nail_textual <- function(dataset = NULL,
                         num.var = NULL,
                         num.text = NULL,
                         x = NULL,
                         introduction = NULL,
                         request = NULL,
                         conclusion = NULL,
                         model = "llama3",
                         provider = c("ollama", "gemini"),
                         isolate.groups = NULL,
                         sample.pct = 1,
                         seed = NULL,
                         prompt_style = c("detailed", "compact"),
                         text_role = c("responses", "comments", "verbatims"),
                         generate = FALSE,
                         analysis_scope = NULL,
                         comparison_mode = NULL,
                         report_format = c("structured", "markdown", "compact"),
                         report_request = NULL,
                         context = NULL,
                         report_context = NULL,
                         ...) {
  provider <- match.arg(provider)
  prompt_style <- match.arg(prompt_style)
  text_role <- match.arg(text_role)
  report_format <- match.arg(report_format)

  if (!is.logical(generate) || length(generate) != 1L || is.na(generate)) {
    stop("`generate` must be a single non-missing logical value.", call. = FALSE)
  }
  if (!is.null(report_request) && !.nail_textual_is_scalar_string(report_request)) {
    stop("`report_request` must be NULL or a non-empty character scalar.", call. = FALSE)
  }
  if (!is.null(introduction) && !.nail_textual_is_scalar_string(introduction)) {
    stop("`introduction` must be NULL or a non-empty character scalar.", call. = FALSE)
  }
  if (!is.null(conclusion) && !.nail_textual_is_scalar_string(conclusion)) {
    stop("`conclusion` must be NULL or a non-empty character scalar.", call. = FALSE)
  }
  report_context <- .nail_textual_as_context(report_context, "report_context")

  if (!is.null(x) && !is.null(dataset)) {
    stop("Supply either `x` or `dataset`, not both.", call. = FALSE)
  }
  input <- if (!is.null(x)) x else dataset
  if (is.null(input)) {
    stop("Supply raw `dataset` data or a prepared object through `x`.", call. = FALSE)
  }

  # `x` is reserved for an already prepared object.  Treating any invalid
  # list supplied through `x` as raw input obscures the intended contract and
  # produces a misleading data-frame error.
  prepared_input <- !is.null(x)
  preparation_calls <- 0L
  llm_calls <- 0L
  source_type <- if (prepared_input) "prepared" else "raw"

  if (prepared_input) {
    .nail_textual_validate_preparation(input)
    preparation <- input

    if (!is.null(num.var) || !is.null(num.text)) {
      warning("`num.var` and `num.text` are ignored for a prepared input.", call. = FALSE)
    }
    if (!is.null(request)) {
      stop(
        paste(
          "`request` cannot retroactively modify existing textual profiles.",
          "Use `report_request` for presentation-only instructions or create a new preparation."
        ),
        call. = FALSE
      )
    }
    if (!is.null(context)) {
      stop(
        paste(
          "`context` cannot retroactively modify existing textual profiles.",
          "Use `report_context` for report-stage context or create a new preparation."
        ),
        call. = FALSE
      )
    }

    stored_scope <- preparation$metadata$analysis_scope
    if (!is.null(analysis_scope) && !identical(analysis_scope, stored_scope)) {
      stop(
        sprintf(
          "The preparation used analysis_scope = '%s'; create a new preparation for '%s'.",
          stored_scope,
          analysis_scope
        ),
        call. = FALSE
      )
    }
    analysis_scope <- stored_scope

    stored_mode <- preparation$metadata$comparison_mode
    if (!is.null(comparison_mode) && !identical(comparison_mode, stored_mode)) {
      stop(
        sprintf(
          "The preparation used comparison_mode = '%s'; its evidence units cannot be relabelled as '%s'.",
          stored_mode,
          comparison_mode
        ),
        call. = FALSE
      )
    }
    comparison_mode <- stored_mode

    if (!is.null(isolate.groups)) {
      mapped <- if (isTRUE(isolate.groups)) "isolated" else "joint"
      warning("`isolate.groups` is deprecated; use `comparison_mode`.", call. = FALSE)
      if (!identical(mapped, stored_mode)) {
        stop("`isolate.groups` conflicts with the prepared comparison mode.", call. = FALSE)
      }
    }

    if (!is.null(introduction)) {
      warning(
        "`introduction` cannot alter an existing preparation and is retained only as report-stage context.",
        call. = FALSE
      )
      report_context$legacy_introduction <- introduction
    }
    if (!is.null(conclusion)) {
      warning(
        "`conclusion` is deprecated and is retained only as a report-stage request.",
        call. = FALSE
      )
      if (is.null(report_request)) report_request <- conclusion
    }

    if (generate && identical(preparation$parsed$parse_status, "not_generated")) {
      resumed <- .nail_textual_resume_preparation(
        preparation = preparation,
        provider = provider,
        model = model,
        llm_api_options = list(...)
      )
      preparation <- resumed$preparation
      llm_calls <- resumed$llm_calls
    }
  } else {
    if (!is.data.frame(input)) {
      stop("Raw input must be a data frame or a valid `nail_textual_prep` object.", call. = FALSE)
    }
    if (is.null(num.var) || is.null(num.text)) {
      stop("`num.var` and `num.text` are required for raw input.", call. = FALSE)
    }

    if (is.null(analysis_scope)) analysis_scope <- "general"
    analysis_scope <- match.arg(analysis_scope, .textual_prep_scopes)

    comparison_mode_missing <- is.null(comparison_mode)
    if (comparison_mode_missing) comparison_mode <- "isolated"
    comparison_mode <- match.arg(comparison_mode, .textual_prep_comparison_modes)

    if (!is.null(isolate.groups)) {
      if (!is.logical(isolate.groups) || length(isolate.groups) != 1L || is.na(isolate.groups)) {
        stop("`isolate.groups` must be NULL or a single logical value.", call. = FALSE)
      }
      mapped <- if (isolate.groups) "isolated" else "joint"
      if (!comparison_mode_missing && !identical(comparison_mode, mapped)) {
        stop("`isolate.groups` and `comparison_mode` specify conflicting modes.", call. = FALSE)
      }
      warning("`isolate.groups` is deprecated; use `comparison_mode`.", call. = FALSE)
      comparison_mode <- mapped
    }

    preparation_context <- .nail_textual_as_context(context, "context")
    if (!is.null(introduction)) {
      warning(
        "`introduction` is deprecated; its value is preserved as preparation context.",
        call. = FALSE
      )
      preparation_context$legacy_introduction <- introduction
    }
    if (!is.null(conclusion)) {
      warning(
        "`conclusion` is deprecated; its value is preserved as a report-stage request.",
        call. = FALSE
      )
      if (is.null(report_request)) report_request <- conclusion
    }

    preparation <- nail_textual_prep(
      dataset = input,
      num.var = num.var,
      num.text = num.text,
      model = model,
      provider = provider,
      sample.pct = sample.pct,
      seed = seed,
      prompt_style = prompt_style,
      text_role = text_role,
      generate = generate,
      analysis_scope = analysis_scope,
      comparison_mode = comparison_mode,
      request = request,
      context = preparation_context,
      ...
    )
    preparation_calls <- 1L
    if (generate) {
      llm_calls <- if (!is.null(preparation$generation$llm_calls)) {
        as.integer(preparation$generation$llm_calls)
      } else {
        sum(vapply(
          preparation$units,
          function(unit) !is.null(unit$response),
          logical(1)
        ))
      }
    }
  }

  built <- .nail_textual_build_reports(preparation)
  report <- .nail_textual_render_report(
    group_reports = built$group_reports,
    cross_group_report = built$cross_group_report,
    report_format = report_format,
    report_request = report_request,
    report_context = report_context
  )

  result <- list(
    report = report,
    prompt = .nail_textual_prompt_view(preparation),
    group_reports = built$group_reports,
    cross_group_report = built$cross_group_report,
    textual_description = preparation$textual_description,
    textual_profiles = preparation$textual_profiles,
    textual_evidence = preparation$textual_evidence,
    preparation = preparation,
    generation = preparation$generation,
    validation = preparation$validation,
    legacy_output = .nail_textual_legacy_output(preparation),
    metadata = list(
      source_type = source_type,
      report_format = report_format,
      report_status = built$report_status,
      semantic_status = preparation$parsed$parse_status,
      profile_source = built$profile_source,
      analysis_scope = preparation$metadata$analysis_scope,
      comparison_mode = preparation$metadata$comparison_mode,
      preparation_request = preparation$metadata$preparation_request,
      report_request = report_request,
      preparation_context = preparation$metadata$context,
      report_context = report_context,
      preparation_calls = preparation_calls,
      llm_calls = llm_calls,
      generated_in_this_call = llm_calls > 0L
    )
  )
  class(result) <- c("nail_textual", "list")

  attr(result, "textual_evidence") <- result$textual_evidence
  attr(result, "textual_profiles") <- result$textual_profiles
  attr(result, "textual_description") <- result$textual_description
  attr(result, "textual_preparation") <- result$preparation
  attr(result, "textual_data_summary") <- result$textual_evidence$group_diagnostics
  attr(result, "legacy_output") <- result$legacy_output
  result
}
