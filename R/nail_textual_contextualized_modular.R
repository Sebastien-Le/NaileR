#' Modular statistical-textual integration
#'
#' `nail_textual_contextualized_modular()` is the modular integration engine
#' used by [nail_textual_contextualized()] when `integration_mode = "modular"`.
#' It remains exported for advanced workflows and targeted replay.
#'
#' It consumes an existing mechanically prepared `contextualized_evidence`
#' object and performs:
#'
#' 1. one core integration request per group;
#' 2. validation of every group result;
#' 3. one cross-group synthesis request based only on validated group results;
#' 4. deterministic construction of a compatibility view.
#'
#' The default expertise is deliberately limited to evidence integration.
#' Sociological, psychological, consumer, marketing, innovation, and
#' operational expertise are not requested in the core workflow.
#'
#' @param x An object returned by `nail_textual_contextualized(...,
#'   generate = FALSE)` or a `contextualized_evidence` list containing
#'   `groups` and `combined_evidence_registry`.
#' @param provider LLM provider. One of `"gemini"` or `"ollama"`.
#' @param model Model name. When `NULL`, the default is
#'   `"gemini-3.5-flash"` for Gemini and `"mistral-small3.2"` for Ollama.
#' @param generate Logical. When `FALSE`, return prompts and schemas without
#'   contacting an LLM.
#' @param context Optional user-provided context kept separate from evidence.
#' @param request Optional additional integration request. It cannot override
#'   evidence or epistemic rules.
#' @param analysis_scope Original public analysis scope, recorded for
#'   traceability. The modular core expertise remains `"integration"`.
#' @param prompt_style Prompt presentation style, `"detailed"` or
#'   `"compact"`. It never modifies evidence.
#' @param cross_group Logical. When `TRUE`, perform one cross-group synthesis
#'   after the group analyses have been validated.
#' @param max_verbatims Maximum number of exact verbatims included in each
#'   group prompt.
#' @param max_group_claims Maximum number of convergence and tension claims
#'   requested per group.
#' @param max_cross_claims Maximum number of claims requested per cross-group
#'   section.
#' @param fail_fast Logical. When `TRUE`, stop on the first invalid group.
#'   When `FALSE`, preserve partial valid results and diagnostics.
#' @param gemini_api_key Optional Gemini API key. By default, the function
#'   reads `NAILER_GEMINI_API_KEY`, `GEMINI_API_KEY`, then `GOOGLE_API_KEY`.
#' @param gemini_max_output_tokens Maximum Gemini output tokens for each
#'   modular request.
#' @param gemini_thinking_level Gemini 3 thinking level.
#' @param ollama_url Ollama server base URL.
#' @param ollama_num_ctx Ollama context length.
#' @param ollama_num_predict Ollama maximum generated tokens per modular call.
#' @param timeout_seconds HTTP timeout.
#' @param .llm_call Optional injected function used by tests. It must accept
#'   `prompt`, `schema`, `provider`, `model`, `unit_type`, and `unit_data`, and
#'   return either one JSON character string or a list with a `content` field.
#'
#' @return An object of class
#'   `c("nail_textual_contextualized_modular", "list")` containing:
#'
#' - `core_analysis`: validated group and cross-group integration;
#' - `compatibility_view`: a deterministic view using the historical field
#'   names, with specialized expertise sections left empty;
#' - `group_units`: prompts, schemas, raw responses, and validation statuses;
#' - `cross_group_unit`: the corresponding cross-group unit;
#' - `contextualized_evidence`: the exact source evidence object;
#' - `report`: a deterministic Markdown report;
#' - `metadata`: provider, model, call counts, and overall status.
#'
#' @export
nail_textual_contextualized_modular <- function(
    x,
    provider = c("gemini", "ollama"),
    model = NULL,
    generate = FALSE,
    context = NULL,
    request = NULL,
    analysis_scope = "cross_functional",
    prompt_style = c("detailed", "compact"),
    cross_group = TRUE,
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
    .llm_call = NULL
) {
  provider <- match.arg(provider)
  prompt_style <- match.arg(prompt_style)
  context <- .nctx_validate_context(context)
  request <- .nctx_validate_request(request)

  .nctx_assert_scalar_logical(generate, "generate")
  .nctx_assert_scalar_logical(cross_group, "cross_group")
  .nctx_assert_scalar_logical(fail_fast, "fail_fast")
  .nctx_assert_positive_integer(max_verbatims, "max_verbatims")
  .nctx_assert_positive_integer(max_group_claims, "max_group_claims")
  .nctx_assert_positive_integer(max_cross_claims, "max_cross_claims")
  .nctx_assert_positive_integer(
    gemini_max_output_tokens,
    "gemini_max_output_tokens"
  )
  .nctx_assert_positive_integer(ollama_num_ctx, "ollama_num_ctx")
  .nctx_assert_positive_integer(
    ollama_num_predict,
    "ollama_num_predict"
  )

  if (!is.numeric(timeout_seconds) ||
      length(timeout_seconds) != 1L ||
      is.na(timeout_seconds) ||
      !is.finite(timeout_seconds) ||
      timeout_seconds <= 0) {
    stop(
      "`timeout_seconds` must be one positive finite numeric value.",
      call. = FALSE
    )
  }

  if (!is.character(gemini_thinking_level) ||
      length(gemini_thinking_level) != 1L ||
      is.na(gemini_thinking_level) ||
      !gemini_thinking_level %in% c(
        "minimal",
        "low",
        "medium",
        "high"
      )) {
    stop(
      paste(
        "`gemini_thinking_level` must be one of:",
        "minimal, low, medium, high."
      ),
      call. = FALSE
    )
  }

  evidence <- .nctx_extract_contextualized_evidence(x)
  groups <- evidence$groups
  registry <- evidence$combined_evidence_registry

  if (is.null(names(groups)) ||
      length(groups) == 0L ||
      any(!nzchar(names(groups)))) {
    stop(
      "`contextualized_evidence$groups` must be a non-empty named list.",
      call. = FALSE
    )
  }

  .nctx_validate_registry(registry)

  if (is.null(model)) {
    model <- if (identical(provider, "gemini")) {
      "gemini-3.5-flash"
    } else {
      "mistral-small3.2"
    }
  }

  group_units <- stats::setNames(
    vector("list", length(groups)),
    names(groups)
  )

  for (group_name in names(groups)) {
    group_data <- .nctx_prepare_group_data(
      group = groups[[group_name]],
      registry = registry,
      max_verbatims = max_verbatims
    )
    has_statistical_evidence <- length(
      group_data$allowed_statistical_evidence_ids
    ) > 0L
    has_textual_evidence <- length(
      group_data$allowed_textual_evidence_ids
    ) > 0L
    integration_eligible <- has_statistical_evidence && has_textual_evidence

    schema <- .nctx_group_schema(
      group_name = group_name,
      max_claims = max_group_claims
    )

    prompt <- .nctx_group_prompt(
      group_data = group_data,
      schema = schema,
      max_claims = max_group_claims,
      prompt_style = prompt_style,
      context = context,
      request = request,
      analysis_scope = analysis_scope
    )

    unit <- list(
      unit_type = "group",
      group = group_name,
      integration_eligible = integration_eligible,
      prompt = if (integration_eligible) prompt else NULL,
      schema = if (integration_eligible) schema else NULL,
      response = NULL,
      parsed = NULL,
      parse_status = if (!integration_eligible) {
        "not_applicable"
      } else if (generate) {
        "pending"
      } else {
        "not_generated"
      },
      parse_error = if (integration_eligible) {
        NULL
      } else {
        paste(
          c(
            "Core integration requires both statistical and textual evidence.",
            group_data$integration_limits
          ),
          collapse = " "
        )
      },
      normalization_warnings = character(),
      audit_warnings = character(),
      elapsed_seconds = NA_real_
    )

    if (isTRUE(generate) && isTRUE(integration_eligible)) {
      call_result <- tryCatch(
        .nctx_dispatch_call(
          prompt = prompt,
          schema = schema,
          provider = provider,
          model = model,
          unit_type = "group",
          unit_data = group_data,
          gemini_api_key = gemini_api_key,
          gemini_max_output_tokens = gemini_max_output_tokens,
          gemini_thinking_level = gemini_thinking_level,
          ollama_url = ollama_url,
          ollama_num_ctx = ollama_num_ctx,
          ollama_num_predict = ollama_num_predict,
          timeout_seconds = timeout_seconds,
          .llm_call = .llm_call
        ),
        error = function(e) {
          list(
            content = NULL,
            elapsed_seconds = NA_real_,
            error = conditionMessage(e)
          )
        }
      )

      unit$elapsed_seconds <- call_result$elapsed_seconds %nctx_or% NA_real_

      if (!is.null(call_result$error)) {
        unit$parse_status <- "error"
        unit$parse_error <- call_result$error
      } else {
        unit$response <- call_result$content
        parsed <- .nctx_parse_group_response(
          text = call_result$content,
          group_data = group_data
        )
        unit$parsed <- parsed$analysis
        unit$parse_status <- parsed$parse_status
        unit$parse_error <- parsed$parse_error
        unit$normalization_warnings <-
          parsed$normalization_warnings %nctx_or% character()
        unit$audit_warnings <-
          parsed$audit_warnings %nctx_or% character()
      }

      if (isTRUE(fail_fast) &&
          !identical(unit$parse_status, "success")) {
        stop(
          paste0(
            "Modular integration failed for group `",
            group_name,
            "`: ",
            unit$parse_error
          ),
          call. = FALSE
        )
      }
    }

    group_units[[group_name]] <- unit
  }

  valid_groups <- lapply(
    group_units,
    function(unit) {
      if (identical(unit$parse_status, "success")) {
        unit$parsed
      } else {
        NULL
      }
    }
  )
  valid_groups <- valid_groups[
    !vapply(valid_groups, is.null, logical(1))
  ]

  cross_unit <- list(
    unit_type = "cross_group",
    prompt = NULL,
    schema = NULL,
    response = NULL,
    parsed = NULL,
    parse_status = if (generate) "not_attempted" else "not_generated",
    parse_error = NULL,
    normalization_warnings = character(),
    audit_warnings = character(),
    elapsed_seconds = NA_real_
  )

  if (isTRUE(cross_group) &&
      length(valid_groups) >= 2L) {
    cross_data <- .nctx_prepare_cross_data(valid_groups)
    cross_schema <- .nctx_cross_schema(
      max_claims = max_cross_claims
    )
    cross_prompt <- .nctx_cross_prompt(
      cross_data = cross_data,
      schema = cross_schema,
      max_claims = max_cross_claims,
      prompt_style = prompt_style,
      context = context,
      request = request,
      analysis_scope = analysis_scope
    )

    cross_unit$prompt <- cross_prompt
    cross_unit$schema <- cross_schema

    if (isTRUE(generate)) {
      cross_result <- tryCatch(
        .nctx_dispatch_call(
          prompt = cross_prompt,
          schema = cross_schema,
          provider = provider,
          model = model,
          unit_type = "cross_group",
          unit_data = cross_data,
          gemini_api_key = gemini_api_key,
          gemini_max_output_tokens = gemini_max_output_tokens,
          gemini_thinking_level = gemini_thinking_level,
          ollama_url = ollama_url,
          ollama_num_ctx = ollama_num_ctx,
          ollama_num_predict = ollama_num_predict,
          timeout_seconds = timeout_seconds,
          .llm_call = .llm_call
        ),
        error = function(e) {
          list(
            content = NULL,
            elapsed_seconds = NA_real_,
            error = conditionMessage(e)
          )
        }
      )

      cross_unit$elapsed_seconds <-
        cross_result$elapsed_seconds %nctx_or% NA_real_

      if (!is.null(cross_result$error)) {
        cross_unit$parse_status <- "error"
        cross_unit$parse_error <- cross_result$error
      } else {
        cross_unit$response <- cross_result$content
        cross_parsed <- .nctx_parse_cross_response(
          text = cross_result$content,
          cross_data = cross_data
        )
        cross_unit$parsed <- cross_parsed$analysis
        cross_unit$parse_status <- cross_parsed$parse_status
        cross_unit$parse_error <- cross_parsed$parse_error
        cross_unit$normalization_warnings <-
          cross_parsed$normalization_warnings %nctx_or% character()
        cross_unit$audit_warnings <-
          cross_parsed$audit_warnings %nctx_or% character()
      }

      if (isTRUE(fail_fast) &&
          !identical(cross_unit$parse_status, "success")) {
        stop(
          paste0(
            "Modular cross-group integration failed: ",
            cross_unit$parse_error
          ),
          call. = FALSE
        )
      }
    }
  }

  core_groups <- lapply(
    group_units,
    function(unit) {
      if (identical(unit$parse_status, "success")) {
        unit$parsed
      } else {
        list(
          group = unit$group,
          availability = "unavailable",
          integration_eligible = unit$integration_eligible,
          parse_error = unit$parse_error,
          integrated_profile = NULL,
          convergences = list(),
          tensions = list(),
          statistical_only_findings = list(),
          textual_only_findings = list(),
          interpretation_limits = list()
        )
      }
    }
  )

  for (group_name in names(core_groups)) {
    core_groups[[group_name]]$integration_eligible <-
      group_units[[group_name]]$integration_eligible
  }

  core_analysis <- list(
    groups = core_groups,
    cross_group = if (
      identical(cross_unit$parse_status, "success")
    ) {
      cross_unit$parsed
    } else {
      NULL
    },
    metadata = list(
      schema = "NaileR::contextualized_core_modular",
      expertise = "integration",
      split_by_group = TRUE,
      cross_group = isTRUE(cross_group),
      group_integration_eligible = vapply(
        group_units,
        function(unit) isTRUE(unit$integration_eligible),
        logical(1)
      ),
      group_parse_status = vapply(
        group_units,
        function(unit) unit$parse_status,
        character(1)
      ),
      cross_group_parse_status = cross_unit$parse_status,
      group_normalization_warnings = lapply(
        group_units,
        function(unit) unit$normalization_warnings
      ),
      group_audit_warnings = lapply(
        group_units,
        function(unit) unit$audit_warnings
      ),
      cross_group_normalization_warnings =
        cross_unit$normalization_warnings,
      cross_group_audit_warnings =
        cross_unit$audit_warnings
    )
  )

  compatibility_view <- .nctx_compatibility_view(
    core_analysis = core_analysis
  )

  report <- .nctx_markdown_report(
    core_analysis = core_analysis
  )

  eligible_group_count <- sum(
    vapply(
      group_units,
      function(unit) isTRUE(unit$integration_eligible),
      logical(1)
    )
  )
  group_success_count <- sum(
    vapply(
      group_units,
      function(unit) identical(unit$parse_status, "success"),
      logical(1)
    )
  )
  group_call_count <- sum(
    vapply(
      group_units,
      function(unit) {
        isTRUE(generate) && isTRUE(unit$integration_eligible)
      },
      logical(1)
    )
  )
  cross_group_required <- isTRUE(cross_group) && group_success_count >= 2L

  overall_status <- if (!isTRUE(generate)) {
    "not_generated"
  } else if (eligible_group_count == 0L) {
    "not_applicable"
  } else if (
    group_success_count == eligible_group_count &&
    (
      !cross_group_required ||
      identical(cross_unit$parse_status, "success")
    ) &&
    eligible_group_count == length(group_units)
  ) {
    "success"
  } else if (group_success_count > 0L) {
    "partial"
  } else {
    "error"
  }

  compatibility_view$metadata$parse_status <- overall_status

  out <- list(
    core_analysis = core_analysis,
    compatibility_view = compatibility_view,
    group_units = group_units,
    cross_group_unit = cross_unit,
    contextualized_evidence = evidence,
    report = report,
    metadata = list(
      schema = "NaileR::nail_textual_contextualized_modular",
      expertise = "integration",
      provider = provider,
      model = model,
      generate = generate,
      split_by_group = TRUE,
      cross_group = cross_group,
      analysis_scope = analysis_scope,
      prompt_style = prompt_style,
      context = context,
      request = request,
      n_group_calls = group_call_count,
      n_cross_group_calls = if (
        generate &&
        !is.null(cross_unit$prompt)
      ) {
        1L
      } else {
        0L
      },
      parse_status = overall_status,
      normalization_warning_count = sum(
        vapply(
          c(group_units, list(cross_unit)),
          function(unit) length(unit$normalization_warnings),
          integer(1)
        )
      ),
      audit_warning_count = sum(
        vapply(
          c(group_units, list(cross_unit)),
          function(unit) length(unit$audit_warnings),
          integer(1)
        )
      )
    )
  )

  class(out) <- c(
    "nail_textual_contextualized_modular",
    "list"
  )

  out
}


# ---------------------------------------------------------------------------
# General helpers
# ---------------------------------------------------------------------------

`%nctx_or%` <- function(x, y) {
  if (is.null(x)) y else x
}

.nctx_validate_context <- function(context) {
  if (is.null(context)) {
    return(list())
  }

  if (is.character(context) &&
      length(context) == 1L &&
      !is.na(context)) {
    return(list(general = context))
  }

  if (!is.list(context) || is.data.frame(context)) {
    stop(
      "`context` must be NULL, a character scalar, or a named list.",
      call. = FALSE
    )
  }

  if (length(context) > 0L &&
      (is.null(names(context)) || any(!nzchar(names(context))))) {
    stop("`context` must be a named list.", call. = FALSE)
  }

  context
}

.nctx_validate_request <- function(request) {
  if (is.null(request)) {
    return(NULL)
  }

  if (!is.character(request) ||
      length(request) != 1L ||
      is.na(request) ||
      !nzchar(trimws(request))) {
    stop(
      "`request` must be NULL or a non-empty character scalar.",
      call. = FALSE
    )
  }

  request
}

.nctx_assert_scalar_logical <- function(x, name) {
  if (!is.logical(x) ||
      length(x) != 1L ||
      is.na(x)) {
    stop(
      paste0("`", name, "` must be TRUE or FALSE."),
      call. = FALSE
    )
  }

  invisible(TRUE)
}

.nctx_assert_positive_integer <- function(x, name) {
  if (!is.numeric(x) ||
      length(x) != 1L ||
      is.na(x) ||
      !is.finite(x) ||
      x != floor(x) ||
      x < 1L) {
    stop(
      paste0(
        "`",
        name,
        "` must be one positive integer."
      ),
      call. = FALSE
    )
  }

  invisible(TRUE)
}

.nctx_json_array <- function(x) {
  as.list(as.character(x))
}

.nctx_extract_contextualized_evidence <- function(x) {
  candidate <- NULL

  if (is.list(x) &&
      !is.null(x$contextualized_evidence)) {
    candidate <- x$contextualized_evidence
  } else if (
    is.list(x) &&
    !is.null(x$groups) &&
    !is.null(x$combined_evidence_registry)
  ) {
    candidate <- x
  }

  if (is.null(candidate) ||
      !is.list(candidate$groups) ||
      !is.data.frame(candidate$combined_evidence_registry)) {
    stop(
      paste(
        "`x` must be a contextualized object or a",
        "`contextualized_evidence` list containing `groups`",
        "and `combined_evidence_registry`."
      ),
      call. = FALSE
    )
  }

  candidate
}

.nctx_validate_registry <- function(registry) {
  required <- c(
    "evidence_id",
    "evidence_type",
    "group"
  )

  missing <- setdiff(required, names(registry))

  if (length(missing) > 0L) {
    stop(
      paste0(
        "The combined evidence registry is missing: ",
        paste(missing, collapse = ", "),
        "."
      ),
      call. = FALSE
    )
  }

  if (anyNA(registry$evidence_id) ||
      any(!nzchar(as.character(registry$evidence_id))) ||
      anyDuplicated(as.character(registry$evidence_id)) > 0L) {
    stop(
      "`evidence_id` values must be non-missing, non-empty, and unique.",
      call. = FALSE
    )
  }

  invisible(TRUE)
}

.nctx_claim_to_compact <- function(x) {
  if (!is.list(x)) {
    return(NULL)
  }

  list(
    text = as.character(x$text %nctx_or% ""),
    status = as.character(x$status %nctx_or% ""),
    evidence_ids = as.character(
      unlist(
        x$evidence_ids %nctx_or% character(),
        use.names = FALSE
      )
    ),
    validation_needed = x$validation_needed %nctx_or% NULL
  )
}

.nctx_claim_list_to_compact <- function(x, max_items = 3L) {
  if (!is.list(x) || length(x) == 0L) {
    return(list())
  }

  x <- x[seq_len(min(length(x), max_items))]

  Filter(
    Negate(is.null),
    lapply(x, .nctx_claim_to_compact)
  )
}

.nctx_compact_textual_profile <- function(profile) {
  if (!is.list(profile)) {
    return(list())
  }

  list(
    core_textual_profile =
      .nctx_claim_to_compact(profile$core_textual_profile),
    main_themes =
      .nctx_claim_list_to_compact(profile$main_themes, 3L),
    dominant_concerns =
      .nctx_claim_list_to_compact(profile$dominant_concerns, 2L),
    tone_or_stance =
      .nctx_claim_to_compact(profile$tone_or_stance),
    contradictions =
      .nctx_claim_list_to_compact(profile$contradictions, 2L),
    minority_positions =
      .nctx_claim_list_to_compact(profile$minority_positions, 2L),
    intra_group_consistency =
      .nctx_claim_to_compact(profile$intra_group_consistency),
    interpretation_limits =
      .nctx_claim_list_to_compact(profile$interpretation_limits, 2L)
  )
}

.nctx_rows_to_records <- function(df, columns, max_rows = Inf) {
  if (!is.data.frame(df) || nrow(df) == 0L) {
    return(list())
  }

  columns <- intersect(columns, names(df))
  df <- df[
    seq_len(min(nrow(df), max_rows)),
    columns,
    drop = FALSE
  ]

  lapply(
    seq_len(nrow(df)),
    function(i) {
      row <- as.list(df[i, , drop = FALSE])
      lapply(
        row,
        function(value) {
          if (length(value) == 0L ||
              all(is.na(value))) {
            NULL
          } else if (length(value) == 1L) {
            unname(value)
          } else {
            unname(value)
          }
        }
      )
    }
  )
}

.nctx_prepare_group_data <- function(
    group,
    registry,
    max_verbatims
) {
  group_name <- as.character(group$group %nctx_or% "")
  if (!nzchar(group_name)) {
    stop("A contextualized group has no valid `group` name.", call. = FALSE)
  }

  statistical_ids <- as.character(
    group$statistical_evidence_ids %nctx_or% character()
  )
  textual_ids <- as.character(
    group$textual_evidence_ids %nctx_or% character()
  )

  group_registry <- registry[
    registry$group == group_name,
    ,
    drop = FALSE
  ]

  textual_rows <- group_registry[
    group_registry$evidence_type == "textual_verbatim",
    ,
    drop = FALSE
  ]

  if ("included_in_prompt" %in% names(textual_rows)) {
    keep <- is.na(textual_rows$included_in_prompt) |
      textual_rows$included_in_prompt
    textual_rows <- textual_rows[keep, , drop = FALSE]
  }

  if (nrow(textual_rows) > max_verbatims) {
    textual_rows <- textual_rows[
      seq_len(max_verbatims),
      ,
      drop = FALSE
    ]
  }

  profile <- group$statistical_profile %nctx_or% list()

  list(
    group = group_name,
    integration_limits =
      as.character(group$integration_limits %nctx_or% character()),
    statistical_profile = list(
      factual_summary =
        as.character(profile$factual_summary %nctx_or% ""),
      qualitative_markers = .nctx_rows_to_records(
        profile$qualitative_markers,
        c(
          "evidence_id",
          "variable",
          "modality",
          "direction",
          "percentage_in_group",
          "global_percentage",
          "v_test",
          "p_value",
          "rank"
        ),
        max_rows = 12L
      ),
      quantitative_markers = .nctx_rows_to_records(
        profile$quantitative_markers,
        c(
          "evidence_id",
          "variable",
          "direction",
          "group_mean",
          "overall_mean",
          "v_test",
          "p_value",
          "rank"
        ),
        max_rows = 12L
      )
    ),
    textual_profile =
      .nctx_compact_textual_profile(group$textual_profile),
    verbatims = .nctx_rows_to_records(
      textual_rows,
      c(
        "evidence_id",
        "original_text",
        "row_index",
        "included_in_prompt"
      ),
      max_rows = max_verbatims
    ),
    allowed_statistical_evidence_ids = statistical_ids,
    allowed_textual_evidence_ids = textual_ids
  )
}

.nctx_prepare_cross_data <- function(valid_groups) {
  list(
    groups = lapply(
      valid_groups,
      function(group) {
        list(
          group = group$group,
          integrated_profile = group$integrated_profile,
          convergences = group$convergences,
          tensions = group$tensions,
          statistical_only_findings =
            group$statistical_only_findings,
          textual_only_findings =
            group$textual_only_findings,
          interpretation_limits =
            group$interpretation_limits
        )
      }
    ),
    allowed_statistical_evidence_ids = unique(
      unlist(
        lapply(
          valid_groups,
          function(group) {
            .nctx_collect_ids(
              group,
              "statistical_evidence_ids"
            )
          }
        ),
        use.names = FALSE
      )
    ),
    allowed_textual_evidence_ids = unique(
      unlist(
        lapply(
          valid_groups,
          function(group) {
            .nctx_collect_ids(
              group,
              "textual_evidence_ids"
            )
          }
        ),
        use.names = FALSE
      )
    )
  )
}

.nctx_collect_ids <- function(x, field) {
  out <- character()

  walk <- function(value) {
    if (!is.list(value)) {
      return(invisible(NULL))
    }

    if (!is.null(names(value)) &&
        field %in% names(value)) {
      out <<- c(
        out,
        as.character(
          unlist(
            value[[field]] %nctx_or% character(),
            use.names = FALSE
          )
        )
      )
    }

    for (element in value) {
      walk(element)
    }

    invisible(NULL)
  }

  walk(x)
  unique(out[nzchar(out)])
}


# ---------------------------------------------------------------------------
# Schemas and prompts
# ---------------------------------------------------------------------------

.nctx_nullable_string_schema <- function() {
  list(
    type = .nctx_json_array(c("string", "null"))
  )
}

.nctx_claim_schema <- function() {
  # `relationship` is intentionally absent from the generated schema.
  # It is a deterministic property of the section in which the claim appears
  # and is added by R during parsing. Legacy responses that still include a
  # relationship field remain accepted and are normalized with a warning.
  fields <- c(
    "text",
    "status",
    "statistical_evidence_ids",
    "textual_evidence_ids",
    "validation_needed"
  )

  list(
    type = "object",
    additionalProperties = FALSE,
    required = .nctx_json_array(fields),
    propertyOrdering = .nctx_json_array(fields),
    properties = list(
      text = list(
        type = "string",
        minLength = 1L
      ),
      status = list(
        type = "string",
        enum = list("expert_interpretation")
      ),
      statistical_evidence_ids = list(
        type = "array",
        items = list(type = "string"),
        minItems = 0L,
        maxItems = 8L
      ),
      textual_evidence_ids = list(
        type = "array",
        items = list(type = "string"),
        minItems = 0L,
        maxItems = 8L
      ),
      validation_needed =
        .nctx_nullable_string_schema()
    )
  )
}

.nctx_claim_array_schema <- function(max_items) {
  list(
    type = "array",
    items = .nctx_claim_schema(),
    minItems = 0L,
    maxItems = as.integer(max_items)
  )
}

.nctx_group_schema <- function(
    group_name,
    max_claims
) {
  fields <- c(
    "group",
    "integrated_profile",
    "convergences",
    "tensions",
    "statistical_only_findings",
    "textual_only_findings",
    "interpretation_limits"
  )

  list(
    type = "object",
    additionalProperties = FALSE,
    required = .nctx_json_array(fields),
    propertyOrdering = .nctx_json_array(fields),
    properties = list(
      group = list(
        type = "string",
        enum = list(group_name)
      ),
      integrated_profile = .nctx_claim_schema(),
      convergences =
        .nctx_claim_array_schema(max_claims),
      tensions =
        .nctx_claim_array_schema(max_claims),
      statistical_only_findings =
        .nctx_claim_array_schema(1L),
      textual_only_findings =
        .nctx_claim_array_schema(1L),
      interpretation_limits =
        .nctx_claim_array_schema(2L)
    )
  )
}

.nctx_cross_schema <- function(max_claims) {
  fields <- c(
    "shared_patterns",
    "major_group_contrasts",
    "different_relationships",
    "interpretation_limits"
  )

  list(
    type = "object",
    additionalProperties = FALSE,
    required = .nctx_json_array(fields),
    propertyOrdering = .nctx_json_array(fields),
    properties = list(
      shared_patterns =
        .nctx_claim_array_schema(max_claims),
      major_group_contrasts =
        .nctx_claim_array_schema(max_claims),
      different_relationships =
        .nctx_claim_array_schema(max_claims),
      interpretation_limits =
        .nctx_claim_array_schema(2L)
    )
  )
}

.nctx_group_prompt <- function(
    group_data,
    schema,
    max_claims,
    prompt_style = c("detailed", "compact"),
    context = NULL,
    request = NULL,
    analysis_scope = "cross_functional"
) {
  prompt_style <- match.arg(prompt_style)
  paste(
    "ROLE",
    paste(
      "You are an evidence-integration analyst.",
      "You are not acting as a sociologist, psychologist, marketer,",
      "innovation consultant, or operational strategist."
    ),
    "",
    "TASK",
    paste(
      "Integrate the statistical and textual evidence for exactly one group.",
      "Describe only what the supplied evidence supports."
    ),
    "",
    "REQUIRED OUTPUT",
    "- one concise integrated profile;",
    paste0(
      "- zero to ",
      max_claims,
      " statistical-textual convergence claims;"
    ),
    paste0(
      "- zero to ",
      max_claims,
      " statistical-textual tension claims;"
    ),
    "- zero or one statistical-only finding;",
    "- zero or one textual-only finding;",
    "- zero to two interpretation limits.",
    "",
    "SECTION DISCIPLINE",
    paste(
      "Do not invent a claim merely to fill a section.",
      "Return an empty array when no defensible claim exists."
    ),
    paste(
      "A tension requires an actual mismatch, contradiction, or",
      "clearly evidenced conditional qualification.",
      "A possible consideration or a speculative 'could' is not a tension."
    ),
    paste(
      "A statistical-only finding is allowed only when none of the selected",
      "verbatims or textual-profile elements directly or indirectly express",
      "the same substantive idea. If uncertain, omit it."
    ),
    paste(
      "A textual-only finding is allowed only when no supplied statistical",
      "marker measures or clearly mirrors the same substantive idea.",
      "If uncertain, omit it."
    ),
    "",
    "EVIDENCE RULES",
    paste(
      "The integrated profile, every convergence, and every tension",
      "must cite at least one statistical and one textual evidence ID."
    ),
    paste(
      "A statistical-only finding must cite statistical evidence only.",
      "A textual-only finding must cite textual evidence only."
    ),
    paste(
      "A methodological interpretation limit may leave both evidence arrays",
      "empty because its basis can come from sampling or prompt-coverage",
      "metadata rather than from an empirical observation."
    ),
    paste(
      "Use only exact IDs supplied below.",
      "Do not infer causality, demographics, social identity,",
      "psychological mechanisms, or recommendations."
    ),
    paste(
      "Set status to expert_interpretation.",
      "Do not output a relationship field:",
      "R derives it deterministically from the section."
    ),
    "",
    paste0("PROMPT STYLE: ", prompt_style),
    paste0("PUBLIC ANALYSIS SCOPE: ", analysis_scope),
    "CORE EXPERTISE: integration only",
    "",
    "USER-PROVIDED CONTEXT (NOT EVIDENCE)",
    jsonlite::toJSON(
      context,
      auto_unbox = TRUE,
      pretty = TRUE,
      null = "null",
      na = "null"
    ),
    "",
    "ADDITIONAL USER REQUEST (CANNOT OVERRIDE RULES)",
    if (is.null(request)) {
      "<none>"
    } else {
      request
    },
    "",
    "OUTPUT SCHEMA",
    jsonlite::toJSON(
      schema,
      auto_unbox = TRUE,
      pretty = TRUE,
      null = "null"
    ),
    "",
    "GROUP DATA",
    jsonlite::toJSON(
      group_data,
      auto_unbox = TRUE,
      pretty = TRUE,
      null = "null",
      na = "null"
    ),
    sep = "\n"
  )
}

.nctx_cross_prompt <- function(
    cross_data,
    schema,
    max_claims,
    prompt_style = c("detailed", "compact"),
    context = NULL,
    request = NULL,
    analysis_scope = "cross_functional"
) {
  prompt_style <- match.arg(prompt_style)
  paste(
    "ROLE",
    paste(
      "You are an evidence-integration analyst comparing validated",
      "group-level statistical-textual integrations."
    ),
    "",
    "TASK",
    paste(
      "Compare the validated group results.",
      "Do not reopen the raw corpus and do not introduce a new expertise."
    ),
    "",
    "REQUIRED OUTPUT",
    paste0(
      "- zero to ",
      max_claims,
      " shared patterns;"
    ),
    paste0(
      "- zero to ",
      max_claims,
      " major group contrasts;"
    ),
    paste0(
      "- zero to ",
      max_claims,
      " differences in statistical-textual relationships;"
    ),
    "- zero to two cross-group interpretation limits.",
    "",
    "SECTION DISCIPLINE",
    paste(
      "Do not invent a claim merely to fill a section.",
      "Return an empty array when no defensible claim exists."
    ),
    paste(
      "Shared patterns must describe genuine commonality.",
      "Major contrasts must describe genuine differences.",
      "Different relationships must compare how statistical and textual",
      "evidence align, diverge, or qualify one another across groups."
    ),
    "",
    "EVIDENCE RULES",
    paste(
      "Every substantive claim must cite at least one statistical",
      "and one textual evidence ID and must involve at least two groups."
    ),
    paste(
      "A methodological interpretation limit may leave both evidence arrays",
      "empty. Use only exact IDs already present in the validated group results."
    ),
    paste(
      "Do not infer causality, demographics, social identity,",
      "psychological mechanisms, marketing actions, innovation actions,",
      "or operational recommendations."
    ),
    paste(
      "Set status to expert_interpretation.",
      "Do not output a relationship field:",
      "R derives it deterministically from the section."
    ),
    "",
    paste0("PROMPT STYLE: ", prompt_style),
    paste0("PUBLIC ANALYSIS SCOPE: ", analysis_scope),
    "CORE EXPERTISE: integration only",
    "",
    "USER-PROVIDED CONTEXT (NOT EVIDENCE)",
    jsonlite::toJSON(
      context,
      auto_unbox = TRUE,
      pretty = TRUE,
      null = "null",
      na = "null"
    ),
    "",
    "ADDITIONAL USER REQUEST (CANNOT OVERRIDE RULES)",
    if (is.null(request)) {
      "<none>"
    } else {
      request
    },
    "",
    "OUTPUT SCHEMA",
    jsonlite::toJSON(
      schema,
      auto_unbox = TRUE,
      pretty = TRUE,
      null = "null"
    ),
    "",
    "VALIDATED GROUP RESULTS",
    jsonlite::toJSON(
      cross_data,
      auto_unbox = TRUE,
      pretty = TRUE,
      null = "null",
      na = "null"
    ),
    sep = "\n"
  )
}


# ---------------------------------------------------------------------------
# Provider calls
# ---------------------------------------------------------------------------

.nctx_dispatch_call <- function(
    prompt,
    schema,
    provider,
    model,
    unit_type,
    unit_data,
    gemini_api_key,
    gemini_max_output_tokens,
    gemini_thinking_level,
    ollama_url,
    ollama_num_ctx,
    ollama_num_predict,
    timeout_seconds,
    .llm_call
) {
  .nail_structured_dispatch_call(
    prompt = prompt,
    schema = schema,
    provider = provider,
    model = model,
    unit_type = unit_type,
    unit_data = unit_data,
    options = list(
      gemini_api_key = gemini_api_key,
      gemini_max_output_tokens = gemini_max_output_tokens,
      gemini_thinking_level = gemini_thinking_level,
      ollama_url = ollama_url,
      ollama_num_ctx = ollama_num_ctx,
      ollama_num_predict = ollama_num_predict,
      timeout_seconds = timeout_seconds,
      .llm_call = .llm_call
    )
  )
}

.nctx_resolve_gemini_key <- function(api_key = NULL) {
  if (is.character(api_key) &&
      length(api_key) == 1L &&
      !is.na(api_key) &&
      nzchar(api_key)) {
    return(api_key)
  }

  candidates <- c(
    Sys.getenv("NAILER_GEMINI_API_KEY", unset = ""),
    Sys.getenv("GEMINI_API_KEY", unset = ""),
    Sys.getenv("GOOGLE_API_KEY", unset = "")
  )
  candidates <- candidates[nzchar(candidates)]

  if (length(candidates) == 0L) {
    stop(
      paste(
        "No Gemini API key was found.",
        "Set NAILER_GEMINI_API_KEY, GEMINI_API_KEY, or GOOGLE_API_KEY."
      ),
      call. = FALSE
    )
  }

  candidates[[1L]]
}

.nctx_call_gemini <- function(
    prompt,
    schema,
    model,
    api_key,
    max_output_tokens,
    thinking_level,
    timeout_seconds
) {
  if (!requireNamespace("httr2", quietly = TRUE) ||
      !requireNamespace("jsonlite", quietly = TRUE)) {
    stop(
      "Gemini modular generation requires `httr2` and `jsonlite`.",
      call. = FALSE
    )
  }

  api_key <- .nctx_resolve_gemini_key(api_key)

  endpoint <- paste0(
    "https://generativelanguage.googleapis.com/v1beta/models/",
    model,
    ":generateContent"
  )

  generation_config <- list(
    maxOutputTokens = as.integer(max_output_tokens),
    responseMimeType = "application/json",
    responseJsonSchema = schema
  )

  if (grepl("^gemini-3", model)) {
    generation_config$thinkingConfig <- list(
      thinkingLevel = thinking_level
    )
  }

  body <- list(
    contents = list(
      list(
        role = "user",
        parts = list(list(text = prompt))
      )
    ),
    generationConfig = generation_config
  )

  started <- Sys.time()

  response <- httr2::request(endpoint) |>
    httr2::req_method("POST") |>
    httr2::req_headers(
      `Content-Type` = "application/json",
      `x-goog-api-key` = api_key
    ) |>
    httr2::req_body_json(body, auto_unbox = TRUE) |>
    httr2::req_timeout(timeout_seconds) |>
    httr2::req_error(
      body = function(resp) httr2::resp_body_string(resp)
    ) |>
    httr2::req_perform()

  payload <- httr2::resp_body_json(
    response,
    simplifyVector = FALSE
  )

  candidates <- payload$candidates
  if (!is.list(candidates) || length(candidates) == 0L) {
    stop("Gemini returned no candidate.", call. = FALSE)
  }

  parts <- candidates[[1L]]$content$parts
  if (!is.list(parts) || length(parts) == 0L) {
    stop("Gemini returned no content part.", call. = FALSE)
  }

  keep <- vapply(
    parts,
    function(part) {
      is.character(part$text) &&
        length(part$text) == 1L &&
        nzchar(part$text) &&
        !isTRUE(part$thought)
    },
    logical(1)
  )

  if (!any(keep)) {
    stop("Gemini returned no final JSON text.", call. = FALSE)
  }

  content <- paste0(
    vapply(
      parts[keep],
      function(part) part$text,
      character(1)
    ),
    collapse = ""
  )

  list(
    content = content,
    payload = payload,
    http_status = httr2::resp_status(response),
    elapsed_seconds = as.numeric(
      difftime(Sys.time(), started, units = "secs")
    )
  )
}

.nctx_call_ollama <- function(
    prompt,
    schema,
    model,
    ollama_url,
    num_ctx,
    num_predict,
    timeout_seconds
) {
  if (!requireNamespace("httr2", quietly = TRUE) ||
      !requireNamespace("jsonlite", quietly = TRUE)) {
    stop(
      "Ollama modular generation requires `httr2` and `jsonlite`.",
      call. = FALSE
    )
  }

  endpoint <- paste0(
    sub("/+$", "", ollama_url),
    "/api/chat"
  )

  body <- list(
    model = model,
    messages = list(
      list(role = "user", content = prompt)
    ),
    stream = FALSE,
    format = schema,
    options = list(
      temperature = 0,
      num_ctx = as.integer(num_ctx),
      num_predict = as.integer(num_predict)
    )
  )

  started <- Sys.time()

  response <- httr2::request(endpoint) |>
    httr2::req_method("POST") |>
    httr2::req_headers(
      `Content-Type` = "application/json"
    ) |>
    httr2::req_body_json(body, auto_unbox = TRUE) |>
    httr2::req_timeout(timeout_seconds) |>
    httr2::req_error(
      body = function(resp) httr2::resp_body_string(resp)
    ) |>
    httr2::req_perform()

  payload <- httr2::resp_body_json(
    response,
    simplifyVector = FALSE
  )

  content <- payload$message$content

  if (!is.character(content) ||
      length(content) != 1L ||
      !nzchar(content)) {
    stop(
      "Ollama returned no JSON content.",
      call. = FALSE
    )
  }

  list(
    content = content,
    payload = payload,
    http_status = httr2::resp_status(response),
    elapsed_seconds = as.numeric(
      difftime(Sys.time(), started, units = "secs")
    )
  )
}


# ---------------------------------------------------------------------------
# Parsing and validation
# ---------------------------------------------------------------------------

.nctx_strip_fence <- function(text) {
  .nail_structured_strip_fence(text)
}

.nctx_parse_json <- function(text) {
  .nail_structured_parse_json(text)
}

.nctx_required_names <- function(x, required, path) {
  if (!is.list(x) || is.null(names(x))) {
    stop(
      paste0("`", path, "` must be a JSON object."),
      call. = FALSE
    )
  }

  missing <- setdiff(required, names(x))
  extra <- setdiff(names(x), required)

  if (length(missing) > 0L) {
    stop(
      paste0(
        "`",
        path,
        "` is missing: ",
        paste(missing, collapse = ", "),
        "."
      ),
      call. = FALSE
    )
  }

  if (length(extra) > 0L) {
    stop(
      paste0(
        "`",
        path,
        "` has unexpected fields: ",
        paste(extra, collapse = ", "),
        "."
      ),
      call. = FALSE
    )
  }

  invisible(TRUE)
}

.nctx_required_names_with_optional <- function(
    x,
    required,
    optional = character(),
    path
) {
  if (!is.list(x) || is.null(names(x))) {
    stop(
      paste0("`", path, "` must be a JSON object."),
      call. = FALSE
    )
  }

  missing <- setdiff(required, names(x))
  extra <- setdiff(
    names(x),
    c(required, optional)
  )

  if (length(missing) > 0L) {
    stop(
      paste0(
        "`",
        path,
        "` is missing: ",
        paste(missing, collapse = ", "),
        "."
      ),
      call. = FALSE
    )
  }

  if (length(extra) > 0L) {
    stop(
      paste0(
        "`",
        path,
        "` has unexpected fields: ",
        paste(extra, collapse = ", "),
        "."
      ),
      call. = FALSE
    )
  }

  invisible(TRUE)
}

.nctx_as_id_vector <- function(x) {
  if (is.null(x)) {
    return(character())
  }

  values <- as.character(
    unlist(x, use.names = FALSE)
  )
  values[!is.na(values) & nzchar(values)]
}

.nctx_validate_claim <- function(
    claim,
    path,
    allowed_statistical,
    allowed_textual,
    expected_relationship,
    evidence_rule = c(
      "both",
      "statistical_only",
      "textual_only",
      "any",
      "optional"
    )
) {
  evidence_rule <- match.arg(evidence_rule)

  required <- c(
    "text",
    "status",
    "statistical_evidence_ids",
    "textual_evidence_ids",
    "validation_needed"
  )

  .nctx_required_names_with_optional(
    claim,
    required = required,
    optional = "relationship",
    path = path
  )

  normalization_warnings <- character()

  legacy_relationship <- claim$relationship %nctx_or% NULL

  if (!is.null(legacy_relationship) &&
      !identical(
        legacy_relationship,
        expected_relationship
      )) {
    normalization_warnings <- c(
      normalization_warnings,
      paste0(
        path,
        "$relationship normalized from `",
        legacy_relationship,
        "` to `",
        expected_relationship,
        "`."
      )
    )
  }

  if (!is.character(claim$text) ||
      length(claim$text) != 1L ||
      is.na(claim$text) ||
      !nzchar(trimws(claim$text))) {
    stop(
      paste0("`", path, "$text` must be non-empty."),
      call. = FALSE
    )
  }

  if (!identical(claim$status, "expert_interpretation")) {
    stop(
      paste0(
        "`",
        path,
        "$status` must be `expert_interpretation`."
      ),
      call. = FALSE
    )
  }

  statistical_ids <- .nctx_as_id_vector(
    claim$statistical_evidence_ids
  )
  textual_ids <- .nctx_as_id_vector(
    claim$textual_evidence_ids
  )

  unknown_stat <- setdiff(
    statistical_ids,
    allowed_statistical
  )
  unknown_text <- setdiff(
    textual_ids,
    allowed_textual
  )

  if (length(unknown_stat) > 0L) {
    stop(
      paste0(
        "`",
        path,
        "` cites unknown statistical IDs: ",
        paste(unknown_stat, collapse = ", "),
        "."
      ),
      call. = FALSE
    )
  }

  if (length(unknown_text) > 0L) {
    stop(
      paste0(
        "`",
        path,
        "` cites unknown textual IDs: ",
        paste(unknown_text, collapse = ", "),
        "."
      ),
      call. = FALSE
    )
  }

  if (identical(evidence_rule, "both") &&
      (
        length(statistical_ids) == 0L ||
        length(textual_ids) == 0L
      )) {
    stop(
      paste0(
        "`",
        path,
        "` must cite statistical and textual evidence."
      ),
      call. = FALSE
    )
  }

  if (identical(evidence_rule, "statistical_only") &&
      (
        length(statistical_ids) == 0L ||
        length(textual_ids) > 0L
      )) {
    stop(
      paste0(
        "`",
        path,
        "` must cite statistical evidence only."
      ),
      call. = FALSE
    )
  }

  if (identical(evidence_rule, "textual_only") &&
      (
        length(textual_ids) == 0L ||
        length(statistical_ids) > 0L
      )) {
    stop(
      paste0(
        "`",
        path,
        "` must cite textual evidence only."
      ),
      call. = FALSE
    )
  }

  if (identical(evidence_rule, "any") &&
      length(statistical_ids) == 0L &&
      length(textual_ids) == 0L) {
    stop(
      paste0(
        "`",
        path,
        "` must cite at least one evidence ID."
      ),
      call. = FALSE
    )
  }

  if (!is.null(claim$validation_needed) &&
      (
        !is.character(claim$validation_needed) ||
        length(claim$validation_needed) != 1L ||
        is.na(claim$validation_needed) ||
        !nzchar(trimws(claim$validation_needed))
      )) {
    stop(
      paste0(
        "`",
        path,
        "$validation_needed` must be NULL or non-empty text."
      ),
      call. = FALSE
    )
  }

  list(
    claim = list(
      text = claim$text,
      status = claim$status,
      statistical_evidence_ids = statistical_ids,
      textual_evidence_ids = textual_ids,
      relationship = expected_relationship,
      validation_needed = claim$validation_needed
    ),
    normalization_warnings = normalization_warnings
  )
}

.nctx_validate_claim_array <- function(
    x,
    path,
    allowed_statistical,
    allowed_textual,
    expected_relationship,
    evidence_rule
) {
  if (!is.list(x) || !is.null(names(x))) {
    stop(
      paste0("`", path, "` must be a JSON array."),
      call. = FALSE
    )
  }

  validated <- lapply(
    seq_along(x),
    function(i) {
      .nctx_validate_claim(
        claim = x[[i]],
        path = paste0(path, "[[", i, "]]"),
        allowed_statistical = allowed_statistical,
        allowed_textual = allowed_textual,
        expected_relationship = expected_relationship,
        evidence_rule = evidence_rule
      )
    }
  )

  list(
    claims = lapply(validated, `[[`, "claim"),
    normalization_warnings = unlist(
      lapply(
        validated,
        `[[`,
        "normalization_warnings"
      ),
      use.names = FALSE
    )
  )
}

.nctx_claim_ids <- function(claims, field) {
  if (!is.list(claims) || length(claims) == 0L) {
    return(character())
  }

  unique(
    unlist(
      lapply(
        claims,
        function(claim) {
          claim[[field]] %nctx_or% character()
        }
      ),
      use.names = FALSE
    )
  )
}

.nctx_source_exclusivity_warnings <- function(analysis, group_name) {
  substantive <- c(
    list(analysis$integrated_profile),
    analysis$convergences,
    analysis$tensions
  )

  substantive_stat <- .nctx_claim_ids(
    substantive,
    "statistical_evidence_ids"
  )
  substantive_text <- .nctx_claim_ids(
    substantive,
    "textual_evidence_ids"
  )

  statistical_only_ids <- .nctx_claim_ids(
    analysis$statistical_only_findings,
    "statistical_evidence_ids"
  )
  textual_only_ids <- .nctx_claim_ids(
    analysis$textual_only_findings,
    "textual_evidence_ids"
  )

  warnings <- character()

  duplicated_stat <- intersect(
    statistical_only_ids,
    substantive_stat
  )
  duplicated_text <- intersect(
    textual_only_ids,
    substantive_text
  )

  if (length(duplicated_stat) > 0L) {
    warnings <- c(
      warnings,
      paste0(
        "Group `",
        group_name,
        "`: statistical-only evidence is also used in an integrated, ",
        "convergence, or tension claim: ",
        paste(duplicated_stat, collapse = ", "),
        ". Review source exclusivity."
      )
    )
  }

  if (length(duplicated_text) > 0L) {
    warnings <- c(
      warnings,
      paste0(
        "Group `",
        group_name,
        "`: textual-only evidence is also used in an integrated, ",
        "convergence, or tension claim: ",
        paste(duplicated_text, collapse = ", "),
        ". Review source exclusivity."
      )
    )
  }

  tension_text <- vapply(
    analysis$tensions,
    function(claim) claim$text,
    character(1)
  )

  speculative <- grepl(
    paste(
      c(
        "\\bcould\\b",
        "\\bmight\\b",
        "\\bpossibly\\b",
        "\\bpeut[- ]?\u00eatre\\b",
        "\\bpourrait\\b",
        "\\bpotentiellement\\b"
      ),
      collapse = "|"
    ),
    tension_text,
    ignore.case = TRUE,
    perl = TRUE
  )

  if (any(speculative)) {
    warnings <- c(
      warnings,
      paste0(
        "Group `",
        group_name,
        "`: at least one tension uses speculative wording. ",
        "Check that it is an observed mismatch rather than a forced section."
      )
    )
  }

  warnings
}

.nctx_parse_group_response <- function(
    text,
    group_data
) {
  tryCatch(
    {
      parsed <- .nctx_parse_json(text)

      fields <- c(
        "group",
        "integrated_profile",
        "convergences",
        "tensions",
        "statistical_only_findings",
        "textual_only_findings",
        "interpretation_limits"
      )

      .nctx_required_names(
        parsed,
        fields,
        paste0("groups$", group_data$group)
      )

      if (!identical(parsed$group, group_data$group)) {
        stop(
          paste0(
            "The returned group must be `",
            group_data$group,
            "`."
          ),
          call. = FALSE
        )
      }

      allowed_stat <- group_data$
        allowed_statistical_evidence_ids
      allowed_text <- group_data$
        allowed_textual_evidence_ids

      integrated <- .nctx_validate_claim(
        parsed$integrated_profile,
        paste0(
          "groups$",
          group_data$group,
          "$integrated_profile"
        ),
        allowed_stat,
        allowed_text,
        "convergence",
        "both"
      )

      convergences <- .nctx_validate_claim_array(
        parsed$convergences,
        paste0(
          "groups$",
          group_data$group,
          "$convergences"
        ),
        allowed_stat,
        allowed_text,
        "convergence",
        "both"
      )

      tensions <- .nctx_validate_claim_array(
        parsed$tensions,
        paste0(
          "groups$",
          group_data$group,
          "$tensions"
        ),
        allowed_stat,
        allowed_text,
        "tension",
        "both"
      )

      statistical_only <- .nctx_validate_claim_array(
        parsed$statistical_only_findings,
        paste0(
          "groups$",
          group_data$group,
          "$statistical_only_findings"
        ),
        allowed_stat,
        allowed_text,
        "statistical_only",
        "statistical_only"
      )

      textual_only <- .nctx_validate_claim_array(
        parsed$textual_only_findings,
        paste0(
          "groups$",
          group_data$group,
          "$textual_only_findings"
        ),
        allowed_stat,
        allowed_text,
        "textual_only",
        "textual_only"
      )

      limits <- .nctx_validate_claim_array(
        parsed$interpretation_limits,
        paste0(
          "groups$",
          group_data$group,
          "$interpretation_limits"
        ),
        allowed_stat,
        allowed_text,
        "scope_limit",
        "optional"
      )

      analysis <- list(
        group = parsed$group,
        availability = "available",
        parse_error = NULL,
        integrated_profile = integrated$claim,
        convergences = convergences$claims,
        tensions = tensions$claims,
        statistical_only_findings =
          statistical_only$claims,
        textual_only_findings =
          textual_only$claims,
        interpretation_limits =
          limits$claims
      )

      normalization_warnings <- unlist(
        list(
          integrated$normalization_warnings,
          convergences$normalization_warnings,
          tensions$normalization_warnings,
          statistical_only$normalization_warnings,
          textual_only$normalization_warnings,
          limits$normalization_warnings
        ),
        use.names = FALSE
      )

      audit_warnings <- .nctx_source_exclusivity_warnings(
        analysis,
        group_data$group
      )

      list(
        parse_status = "success",
        parse_error = NULL,
        analysis = analysis,
        normalization_warnings = normalization_warnings,
        audit_warnings = audit_warnings
      )
    },
    error = function(e) {
      list(
        parse_status = "error",
        parse_error = conditionMessage(e),
        analysis = NULL,
        normalization_warnings = character(),
        audit_warnings = character()
      )
    }
  )
}

.nctx_groups_from_ids <- function(ids) {
  ids <- as.character(ids)
  ids <- ids[nzchar(ids)]
  unique(sub("::.*$", "", ids))
}

.nctx_parse_cross_response <- function(
    text,
    cross_data
) {
  tryCatch(
    {
      parsed <- .nctx_parse_json(text)

      fields <- c(
        "shared_patterns",
        "major_group_contrasts",
        "different_relationships",
        "interpretation_limits"
      )

      .nctx_required_names(
        parsed,
        fields,
        "cross_group"
      )

      allowed_stat <- cross_data$
        allowed_statistical_evidence_ids
      allowed_text <- cross_data$
        allowed_textual_evidence_ids

      validate_cross_array <- function(
          x,
          path,
          relationship,
          evidence_rule = "both",
          require_two_groups = TRUE
      ) {
        validated <- .nctx_validate_claim_array(
          x = x,
          path = path,
          allowed_statistical = allowed_stat,
          allowed_textual = allowed_text,
          expected_relationship = relationship,
          evidence_rule = evidence_rule
        )

        claims <- validated$claims

        if (isTRUE(require_two_groups)) {
          for (i in seq_along(claims)) {
            ids <- c(
              claims[[i]]$statistical_evidence_ids,
              claims[[i]]$textual_evidence_ids
            )
            groups <- .nctx_groups_from_ids(ids)

            if (length(groups) < 2L) {
              stop(
                paste0(
                  "`",
                  path,
                  "[[",
                  i,
                  "]]` must cite at least two groups."
                ),
                call. = FALSE
              )
            }
          }
        }

        validated
      }

      shared <- validate_cross_array(
        parsed$shared_patterns,
        "cross_group$shared_patterns",
        "convergence"
      )
      contrasts <- validate_cross_array(
        parsed$major_group_contrasts,
        "cross_group$major_group_contrasts",
        "tension"
      )
      relationships <- validate_cross_array(
        parsed$different_relationships,
        "cross_group$different_relationships",
        "tension"
      )
      limits <- validate_cross_array(
        parsed$interpretation_limits,
        "cross_group$interpretation_limits",
        "scope_limit",
        evidence_rule = "optional",
        require_two_groups = FALSE
      )

      analysis <- list(
        shared_patterns = shared$claims,
        major_group_contrasts = contrasts$claims,
        different_relationships = relationships$claims,
        interpretation_limits = limits$claims
      )

      normalization_warnings <- unlist(
        list(
          shared$normalization_warnings,
          contrasts$normalization_warnings,
          relationships$normalization_warnings,
          limits$normalization_warnings
        ),
        use.names = FALSE
      )

      list(
        parse_status = "success",
        parse_error = NULL,
        analysis = analysis,
        normalization_warnings = normalization_warnings,
        audit_warnings = character()
      )
    },
    error = function(e) {
      list(
        parse_status = "error",
        parse_error = conditionMessage(e),
        analysis = NULL,
        normalization_warnings = character(),
        audit_warnings = character()
      )
    }
  )
}


# ---------------------------------------------------------------------------
# Compatibility and reporting
# ---------------------------------------------------------------------------

.nctx_compatibility_view <- function(core_analysis, parse_status = NULL) {
  groups <- lapply(
    core_analysis$groups,
    function(group) {
      list(
        group = group$group,
        availability = group$availability,
        parse_error = group$parse_error,
        integrated_profile = group$integrated_profile,
        statistical_textual_convergences =
          group$convergences,
        statistical_textual_divergences =
          group$tensions,
        statistical_only_findings =
          group$statistical_only_findings,
        textual_only_findings =
          group$textual_only_findings,
        social_interpretations = list(),
        consumer_insights = list(),
        psychological_hypotheses = list(),
        marketing_implications = list(),
        innovation_opportunities = list(),
        operational_implications = list(),
        validation_priorities = list(),
        interpretation_limits =
          group$interpretation_limits
      )
    }
  )

  cross <- core_analysis$cross_group

  cross_view <- if (is.null(cross)) {
    list(
      shared_patterns = list(),
      major_group_contrasts = list(),
      different_statistical_textual_relationships = list(),
      cross_group_social_interpretations = list(),
      consumer_segments_hypotheses = list(),
      psychological_mechanisms_hypotheses = list(),
      marketing_priorities = list(),
      innovation_priorities = list(),
      validation_priorities = list(),
      interpretation_limits = list()
    )
  } else {
    list(
      shared_patterns = cross$shared_patterns,
      major_group_contrasts =
        cross$major_group_contrasts,
      different_statistical_textual_relationships =
        cross$different_relationships,
      cross_group_social_interpretations = list(),
      consumer_segments_hypotheses = list(),
      psychological_mechanisms_hypotheses = list(),
      marketing_priorities = list(),
      innovation_priorities = list(),
      validation_priorities = list(),
      interpretation_limits =
        cross$interpretation_limits
    )
  }

  list(
    groups = groups,
    cross_group_analysis = cross_view,
    metadata = list(
      schema = "NaileR::contextualized_analysis",
      analysis_scope = "integration",
      comparison_mode = "modular",
      groups = names(groups),
      parse_status = if (is.null(parse_status)) {
        core_analysis$metadata$cross_group_parse_status
      } else {
        parse_status
      }
    )
  )
}

.nctx_render_claim <- function(claim) {
  if (is.null(claim)) {
    return("- Not available")
  }

  stat <- paste(
    claim$statistical_evidence_ids,
    collapse = ", "
  )
  text <- paste(
    claim$textual_evidence_ids,
    collapse = ", "
  )

  paste0(
    "- ",
    claim$text,
    "\n",
    "  - relationship: `",
    claim$relationship,
    "`\n",
    "  - statistical evidence: ",
    if (nzchar(stat)) stat else "none",
    "\n",
    "  - textual evidence: ",
    if (nzchar(text)) text else "none"
  )
}

.nctx_render_claims <- function(claims) {
  if (!is.list(claims) || length(claims) == 0L) {
    return("- None")
  }

  paste(
    vapply(
      claims,
      .nctx_render_claim,
      character(1)
    ),
    collapse = "\n"
  )
}

.nctx_markdown_report <- function(core_analysis) {
  lines <- c(
    "# Modular statistical-textual integration",
    "",
    paste0(
      "- Expertise: `",
      core_analysis$metadata$expertise,
      "`"
    ),
    "- Architecture: one validated request per group, then one cross-group request",
    ""
  )

  for (group_name in names(core_analysis$groups)) {
    group <- core_analysis$groups[[group_name]]

    lines <- c(
      lines,
      paste0("## ", group_name),
      "",
      paste0(
        "**Availability:** `",
        group$availability,
        "`"
      ),
      ""
    )

    if (!identical(group$availability, "available")) {
      lines <- c(
        lines,
        paste0(
          "**Parse error:** ",
          group$parse_error %nctx_or% "unknown"
        ),
        ""
      )
      next
    }

    lines <- c(
      lines,
      "### Integrated profile",
      .nctx_render_claim(group$integrated_profile),
      "",
      "### Convergences",
      .nctx_render_claims(group$convergences),
      "",
      "### Tensions",
      .nctx_render_claims(group$tensions),
      "",
      "### Statistical-only findings",
      .nctx_render_claims(
        group$statistical_only_findings
      ),
      "",
      "### Textual-only findings",
      .nctx_render_claims(
        group$textual_only_findings
      ),
      "",
      "### Interpretation limits",
      .nctx_render_claims(
        group$interpretation_limits
      ),
      ""
    )
  }

  lines <- c(
    lines,
    "## Cross-group synthesis",
    ""
  )

  cross <- core_analysis$cross_group

  if (is.null(cross)) {
    lines <- c(
      lines,
      "- Cross-group synthesis is not available."
    )
  } else {
    lines <- c(
      lines,
      "### Shared patterns",
      .nctx_render_claims(cross$shared_patterns),
      "",
      "### Major contrasts",
      .nctx_render_claims(
        cross$major_group_contrasts
      ),
      "",
      "### Different evidence relationships",
      .nctx_render_claims(
        cross$different_relationships
      ),
      "",
      "### Cross-group interpretation limits",
      .nctx_render_claims(
        cross$interpretation_limits
      )
    )
  }

  paste(lines, collapse = "\n")
}


#' Repair and revalidate a modular contextualized result without a new LLM call
#'
#' This function reparses stored group and cross-group JSON responses using the
#' current deterministic normalization rules. It is intended for recovering
#' results created by an earlier prototype in which the LLM supplied an
#' incorrect `relationship` value.
#'
#' @param x A result returned by `nail_textual_contextualized_modular()`.
#'
#' @return A repaired object of the same class. No provider call is made.
#'
#' @export
repair_nail_textual_contextualized_modular_result <- function(x) {
  if (!is.list(x) ||
      is.null(x$group_units) ||
      is.null(x$cross_group_unit) ||
      is.null(x$contextualized_evidence)) {
    stop(
      "`x` is not a modular contextualized result.",
      call. = FALSE
    )
  }

  evidence <- x$contextualized_evidence
  registry <- evidence$combined_evidence_registry

  for (group_name in names(x$group_units)) {
    unit <- x$group_units[[group_name]]

    group_data <- .nctx_prepare_group_data(
      group = evidence$groups[[group_name]],
      registry = registry,
      max_verbatims = max(
        1L,
        sum(
          registry$group == group_name &
            registry$evidence_type == "textual_verbatim"
        )
      )
    )

    if (is.null(unit$integration_eligible)) {
      unit$integration_eligible <-
        length(group_data$allowed_statistical_evidence_ids) > 0L &&
        length(group_data$allowed_textual_evidence_ids) > 0L
    }
    x$group_units[[group_name]] <- unit

    if (!is.character(unit$response) ||
        length(unit$response) != 1L ||
        !nzchar(unit$response)) {
      next
    }

    parsed <- .nctx_parse_group_response(
      text = unit$response,
      group_data = group_data
    )

    unit$parsed <- parsed$analysis
    unit$parse_status <- parsed$parse_status
    unit$parse_error <- parsed$parse_error
    unit$normalization_warnings <-
      parsed$normalization_warnings %nctx_or% character()
    unit$audit_warnings <-
      parsed$audit_warnings %nctx_or% character()

    x$group_units[[group_name]] <- unit
  }

  valid_groups <- lapply(
    x$group_units,
    function(unit) {
      if (identical(unit$parse_status, "success")) {
        unit$parsed
      } else {
        NULL
      }
    }
  )
  valid_groups <- valid_groups[
    !vapply(valid_groups, is.null, logical(1))
  ]

  if (
    is.character(x$cross_group_unit$response) &&
    length(x$cross_group_unit$response) == 1L &&
    nzchar(x$cross_group_unit$response) &&
    length(valid_groups) >= 2L
  ) {
    cross_data <- .nctx_prepare_cross_data(valid_groups)

    parsed <- .nctx_parse_cross_response(
      text = x$cross_group_unit$response,
      cross_data = cross_data
    )

    x$cross_group_unit$parsed <- parsed$analysis
    x$cross_group_unit$parse_status <- parsed$parse_status
    x$cross_group_unit$parse_error <- parsed$parse_error
    x$cross_group_unit$normalization_warnings <-
      parsed$normalization_warnings %nctx_or% character()
    x$cross_group_unit$audit_warnings <-
      parsed$audit_warnings %nctx_or% character()
  }

  core_groups <- lapply(
    x$group_units,
    function(unit) {
      if (identical(unit$parse_status, "success")) {
        unit$parsed
      } else {
        list(
          group = unit$group,
          availability = "unavailable",
          integration_eligible = isTRUE(unit$integration_eligible),
          parse_error = unit$parse_error,
          integrated_profile = NULL,
          convergences = list(),
          tensions = list(),
          statistical_only_findings = list(),
          textual_only_findings = list(),
          interpretation_limits = list()
        )
      }
    }
  )

  for (group_name in names(core_groups)) {
    core_groups[[group_name]]$integration_eligible <-
      isTRUE(x$group_units[[group_name]]$integration_eligible)
  }

  cross_success <- identical(
    x$cross_group_unit$parse_status,
    "success"
  )

  x$core_analysis <- list(
    groups = core_groups,
    cross_group = if (cross_success) {
      x$cross_group_unit$parsed
    } else {
      NULL
    },
    metadata = list(
      schema = "NaileR::contextualized_core_modular",
      expertise = "integration",
      split_by_group = TRUE,
      cross_group = isTRUE(x$metadata$cross_group),
      group_integration_eligible = vapply(
        x$group_units,
        function(unit) isTRUE(unit$integration_eligible),
        logical(1)
      ),
      group_parse_status = vapply(
        x$group_units,
        function(unit) unit$parse_status,
        character(1)
      ),
      cross_group_parse_status =
        x$cross_group_unit$parse_status,
      group_normalization_warnings = lapply(
        x$group_units,
        function(unit) unit$normalization_warnings %nctx_or% character()
      ),
      group_audit_warnings = lapply(
        x$group_units,
        function(unit) unit$audit_warnings %nctx_or% character()
      ),
      cross_group_normalization_warnings =
        x$cross_group_unit$normalization_warnings %nctx_or% character(),
      cross_group_audit_warnings =
        x$cross_group_unit$audit_warnings %nctx_or% character()
    )
  )

  x$compatibility_view <- .nctx_compatibility_view(
    x$core_analysis
  )
  x$report <- .nctx_markdown_report(
    x$core_analysis
  )

  eligible_group_count <- sum(
    vapply(
      x$group_units,
      function(unit) isTRUE(unit$integration_eligible),
      logical(1)
    )
  )
  group_success_count <- sum(
    vapply(
      x$group_units,
      function(unit) identical(unit$parse_status, "success"),
      logical(1)
    )
  )

  cross_requested <- isTRUE(
    x$metadata$cross_group
  )
  cross_required <- cross_requested && group_success_count >= 2L

  x$metadata$parse_status <- if (eligible_group_count == 0L) {
    "not_applicable"
  } else if (
    group_success_count == eligible_group_count &&
    (!cross_required || cross_success) &&
    eligible_group_count == length(x$group_units)
  ) {
    "success"
  } else if (group_success_count > 0L) {
    "partial"
  } else {
    "error"
  }

  x$compatibility_view$metadata$parse_status <-
    x$metadata$parse_status

  x$metadata$normalization_warning_count <- sum(
    vapply(
      c(x$group_units, list(x$cross_group_unit)),
      function(unit) {
        length(unit$normalization_warnings %nctx_or% character())
      },
      integer(1)
    )
  )

  x$metadata$audit_warning_count <- sum(
    vapply(
      c(x$group_units, list(x$cross_group_unit)),
      function(unit) {
        length(unit$audit_warnings %nctx_or% character())
      },
      integer(1)
    )
  )

  x$metadata$repaired_without_llm_call <- TRUE
  x$metadata$repair_timestamp <- as.character(Sys.time())

  class(x) <- c(
    "nail_textual_contextualized_modular",
    "list"
  )

  x
}
