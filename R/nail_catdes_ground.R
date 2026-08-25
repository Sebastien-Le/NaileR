# ==========================================================================
# Optional epistemic grounding for nail_catdes()
# ==========================================================================
# PASS 2 is deliberately independent from nail_catdes(). It reads the frozen
# local semantic profiles produced by PASS 1 and reviews them against the
# local semantic-facing evidence. It never mutates or regenerates PASS 1.

.catdes_ground_epistemic_levels <- c(
  "fact",
  "semantic_pattern",
  "interpretation",
  "hypothesis"
)

.catdes_ground_temperatures <- c(
  fact = 0L,
  semantic_pattern = 1L,
  interpretation = 2L,
  hypothesis = 3L
)

.catdes_ground_statuses <- c(
  "supported",
  "contradicted",
  "insufficient",
  "mixed"
)

.catdes_ground_support_types <- c(
  "direct",
  "convergent",
  "indirect",
  "none"
)

.catdes_ground_assert_single_logical <- function(x, argument) {
  if (!is.logical(x) || length(x) != 1L || is.na(x)) {
    stop(sprintf("`%s` must be TRUE or FALSE.", argument), call. = FALSE)
  }
  invisible(TRUE)
}

.catdes_ground_timer_start <- function() {
  proc.time()
}

.catdes_ground_timer_stop <- function(start) {
  delta <- proc.time() - start
  list(
    elapsed_seconds = unname(as.numeric(delta[["elapsed"]])),
    user_cpu_seconds = unname(as.numeric(delta[["user.self"]])),
    system_cpu_seconds = unname(as.numeric(delta[["sys.self"]]))
  )
}

.catdes_ground_result_artifact <- function(x, name) {
  value <- attr(x, name, exact = TRUE)
  if (is.null(value)) {
    stop(
      paste0(
        "`x` does not contain the `", name,
        "` artifact required by `nail_catdes_ground()`."
      ),
      call. = FALSE
    )
  }
  value
}

.validate_nail_catdes_ground_input <- function(x) {
  semantic_profiles <- .catdes_ground_result_artifact(x, "semantic_profiles")
  semantic_facing <- .catdes_ground_result_artifact(x, "semantic_facing_evidence")
  interpretation_evidence <- .catdes_ground_result_artifact(x, "interpretation_evidence")
  statistical_profiles <- .catdes_ground_result_artifact(x, "statistical_profiles")

  if (!inherits(semantic_profiles, "nail_catdes_semantic_profiles")) {
    stop(
      "`x` must contain semantic profiles produced by `nail_catdes()`.",
      call. = FALSE
    )
  }
  if (!inherits(semantic_facing, "nail_catdes_semantic_facing_evidence")) {
    stop(
      "`x` must contain semantic-facing evidence produced by `nail_catdes()`.",
      call. = FALSE
    )
  }
  if (!inherits(interpretation_evidence, "nail_catdes_interpretation_evidence")) {
    stop(
      "`x` must contain interpretation evidence produced by `nail_catdes()`.",
      call. = FALSE
    )
  }
  if (!inherits(statistical_profiles, "statistical_profiles")) {
    stop(
      "`x` must contain canonical statistical profiles produced by `nail_catdes_prep()`.",
      call. = FALSE
    )
  }

  semantic_names <- names(semantic_profiles$groups)
  evidence_names <- names(semantic_facing$groups)
  interpretation_names <- names(interpretation_evidence$groups)

  if (!identical(semantic_names, evidence_names) ||
      !identical(semantic_names, interpretation_names)) {
    stop(
      "The PASS 1 artifacts do not contain the same ordered group set.",
      call. = FALSE
    )
  }

  list(
    semantic_profiles = semantic_profiles,
    semantic_facing_evidence = semantic_facing,
    interpretation_evidence = interpretation_evidence,
    statistical_profiles = statistical_profiles,
    catdes_settings = attr(x, "catdes_settings", exact = TRUE)
  )
}

.catdes_ground_resolve_backend <- function(model, provider, catdes_settings) {
  inherited_model <- if (is.list(catdes_settings)) catdes_settings$model else NULL
  inherited_provider <- if (is.list(catdes_settings)) catdes_settings$provider else NULL

  if (is.null(model)) {
    model <- inherited_model
  }
  if (is.null(provider)) {
    provider <- inherited_provider
  }
  if (is.null(model) || !is.character(model) || length(model) != 1L ||
      is.na(model) || !nzchar(model)) {
    model <- "llama3"
  }
  if (is.null(provider) || !is.character(provider) || length(provider) != 1L ||
      is.na(provider) || !nzchar(provider)) {
    provider <- "ollama"
  }

  provider <- match.arg(provider, c("ollama", "gemini"))
  list(model = model, provider = provider)
}

.catdes_ground_local_evidence_rows <- function(group) {
  displayed <- group$displayed_evidence
  if (!is.data.frame(displayed) || nrow(displayed) == 0L) {
    return(displayed)
  }

  if (!"evidence_id" %in% names(displayed) ||
      !"factual_statement" %in% names(displayed)) {
    stop(
      paste0(
        "Semantic-facing evidence for group '", group$group,
        "' is missing `evidence_id` or `factual_statement`."
      ),
      call. = FALSE
    )
  }
  displayed
}

.catdes_ground_evidence_map <- function(group, group_index) {
  displayed <- .catdes_ground_local_evidence_rows(group)
  if (!is.data.frame(displayed) || nrow(displayed) == 0L) {
    return(data.frame(
      evidence_ref = character(0),
      evidence_id = character(0),
      factual_statement = character(0),
      stringsAsFactors = FALSE
    ))
  }

  data.frame(
    evidence_ref = sprintf("G%03dE%03d", as.integer(group_index), seq_len(nrow(displayed))),
    evidence_id = as.character(displayed$evidence_id),
    factual_statement = as.character(displayed$factual_statement),
    stringsAsFactors = FALSE
  )
}

.catdes_ground_evidence_text <- function(group, group_index) {
  evidence_map <- .catdes_ground_evidence_map(group, group_index)
  if (nrow(evidence_map) == 0L) {
    return("*No local statistical evidence is available for grounding.*")
  }

  paste0(
    "- Evidence ref: ", evidence_map$evidence_ref, "\n",
    "  Fact: ", evidence_map$factual_statement,
    collapse = "\n"
  )
}

.catdes_ground_contract_text <- function() {
  paste(
    "Return one JSON object and nothing else.",
    "The object must contain an `assertions` array.",
    "Each assertion must contain exactly these fields:",
    "text, epistemic_level, grounding_status, support_type,",
    "supporting_evidence_ids, contradicting_evidence_ids, rationale.",
    "Allowed epistemic_level values: fact, semantic_pattern, interpretation, hypothesis.",
    "Allowed grounding_status values: supported, contradicted, insufficient, mixed.",
    "Allowed support_type values: direct, convergent, indirect, none.",
    "The two evidence-id fields must be JSON arrays of strings.",
    "Use only the short Evidence refs listed in the Local Evidence section; copy the refs shown there exactly.",
    "Put those short refs, not the long internal Evidence IDs, in `supporting_evidence_ids` and `contradicting_evidence_ids`.",
    "Copy each Evidence ref exactly as the text following `Evidence ref:`; do not add brackets, backticks, prefixes, or suffixes.",
    "Do not rewrite, correct, or replace the frozen PASS 1 response.",
    "Split that response into the smallest meaningful assertions needed for epistemic review.",
    "If one sentence contains both an observed result and an inference introduced by wording such as `suggesting`, `indicating`, `implying`, `reflecting`, or `therefore`, split the observation and the inference into separate assertions.",
    "Temperature is NOT truth: classify how far each assertion moves beyond direct observation.",
    "A fact is directly restatable from the evidence; a semantic_pattern combines convergent facts;",
    "an interpretation gives a higher-level meaning; a hypothesis proposes an explanation or extension not directly measured.",
    "Grounding is independent of epistemic level: a cold assertion may be contradicted, and a warm assertion may be supported indirectly.",
    "`supported` means that the listed local evidence is sufficient to justify the assertion AS WORDED; mere plausibility, compatibility, or thematic consistency is not enough.",
    "Use `insufficient` when evidence is relevant but does not establish the assertion. In that case, keep the relevant `supporting_evidence_ids` and use `support_type = indirect`, `convergent`, or `direct` as appropriate.",
    "Use `support_type = none` only when no listed local evidence genuinely supports the assertion.",
    "A proxy behavior does not by itself establish an unmeasured motivation, personality trait, causal mechanism, expertise, value orientation, or preferred alternative.",
    "A decrease in a neutral response category does not establish the direction of an attitude unless directional evidence is also listed.",
    "A change in one response category must not be generalized to the whole construct unless the displayed modalities justify that generalization.",
    "A `supported` assertion MUST cite at least one `supporting_evidence_ids` entry and cannot use `support_type = none`.",
    "A `contradicted` assertion MUST cite at least one `contradicting_evidence_ids` entry.",
    "A `mixed` assertion MUST cite at least one supporting and one contradicting Evidence ID and cannot use `support_type = none`.",
    "If the evidence is only suggestive or proxy-based, prefer `grounding_status = insufficient` while retaining the relevant evidence IDs rather than upgrading plausibility to `supported`.",
    sep = "\n"
  )
}

.build_catdes_ground_prompt <- function(group_name,
                                        group_index,
                                        semantic_profile,
                                        semantic_facing_group,
                                        interpretation_mode,
                                        target_label) {
  response <- semantic_profile$response
  if (is.null(response) || !is.character(response) || length(response) != 1L ||
      is.na(response) || !nzchar(trimws(response))) {
    stop(
      paste0(
        "No generated semantic profile is available for grounding in group '",
        group_name, "'."
      ),
      call. = FALSE
    )
  }

  unit <- if (identical(interpretation_mode, "latent")) "Group" else "Category"

  paste0(
    "# Epistemic Review of a Frozen PASS 1 Interpretation\n\n",
    "You are reviewing an interpretation already produced by another analytical pass. ",
    "Your role is not to produce a better interpretation. Your role is to expose how each assertion should be read relative to the local statistical evidence.\n\n",
    "## Target\n\n",
    "Target variable: ", target_label, "\n",
    unit, ": ", group_name, "\n\n",
    "## Frozen PASS 1 Response\n\n",
    response, "\n\n",
    "## Local Evidence\n\n",
    .catdes_ground_evidence_text(semantic_facing_group, group_index), "\n\n",
    "## Epistemic Contract\n\n",
    .catdes_ground_contract_text()
  )
}

.catdes_ground_strip_json_fence <- function(text) {
  text <- trimws(text)
  text <- sub("^```(?:json)?[[:space:]]*", "", text, perl = TRUE, ignore.case = TRUE)
  text <- sub("[[:space:]]*```$", "", text, perl = TRUE)
  trimws(text)
}

.catdes_ground_extract_json_object <- function(text) {
  text <- .catdes_ground_strip_json_fence(text)
  if (jsonlite::validate(text)) {
    return(text)
  }

  first <- regexpr("\\{", text, perl = TRUE)[1L]
  last_positions <- gregexpr("\\}", text, perl = TRUE)[[1L]]
  last_positions <- last_positions[last_positions > 0L]
  if (first < 1L || length(last_positions) == 0L) {
    stop("The grounding LLM response is not valid JSON.", call. = FALSE)
  }

  candidate <- substr(text, first, max(last_positions))
  if (!jsonlite::validate(candidate)) {
    stop("The grounding LLM response is not valid JSON.", call. = FALSE)
  }
  candidate
}

.catdes_ground_character_array <- function(x, field, group_name, index) {
  if (is.null(x)) {
    return(character(0))
  }
  if (is.character(x)) {
    return(as.character(x))
  }
  if (is.list(x) && all(vapply(x, function(value) {
    is.character(value) && length(value) == 1L && !is.na(value)
  }, logical(1)))) {
    return(vapply(x, as.character, character(1)))
  }
  stop(
    sprintf(
      "Invalid `%s` for assertion %d in group '%s'.",
      field, index, group_name
    ),
    call. = FALSE
  )
}

.catdes_ground_scalar_choice <- function(x, allowed, field, group_name, index) {
  if (!is.character(x) || length(x) != 1L || is.na(x) || !(x %in% allowed)) {
    stop(
      sprintf(
        "Invalid `%s` for assertion %d in group '%s'. Allowed values are: %s.",
        field, index, group_name, paste(allowed, collapse = ", ")
      ),
      call. = FALSE
    )
  }
  x
}

.catdes_ground_strip_reference_wrapper <- function(id) {
  id <- trimws(id)
  if (grepl("^\\[.*\\]$", id, perl = TRUE)) {
    id <- trimws(sub("^\\[(.*)\\]$", "\\1", id, perl = TRUE))
  }
  if (grepl("^`.*`$", id, perl = TRUE)) {
    id <- trimws(sub("^`(.*)`$", "\\1", id, perl = TRUE))
  }
  id
}

.catdes_ground_resolve_evidence_references <- function(ids,
                                                        evidence_reference_map) {
  if (length(ids) == 0L) {
    return(character(0))
  }

  refs <- names(evidence_reference_map)
  canonical <- unname(evidence_reference_map)

  vapply(ids, function(id) {
    candidate <- .catdes_ground_strip_reference_wrapper(id)

    if (candidate %in% refs) {
      return(unname(evidence_reference_map[[candidate]]))
    }

    # Backward-compatible defensive path for exact canonical IDs returned by
    # a mocked/custom backend. No fuzzy matching is performed.
    if (candidate %in% canonical) {
      return(candidate)
    }

    candidate
  }, character(1))
}

.catdes_ground_validate_evidence_ids <- function(ids,
                                                  evidence_reference_map,
                                                  field,
                                                  group_name,
                                                  index) {
  allowed_ids <- unname(evidence_reference_map)
  ids <- .catdes_ground_resolve_evidence_references(
    ids,
    evidence_reference_map = evidence_reference_map
  )
  ids <- unique(ids)
  unknown <- setdiff(ids, allowed_ids)
  if (length(unknown) > 0L) {
    stop(
      sprintf(
        paste0(
          "Grounding assertion %d for group '%s' references Evidence refs/IDs ",
          "outside that group's local evidence in `%s`: %s."
        ),
        index, group_name, field, paste(unknown, collapse = ", ")
      ),
      call. = FALSE
    )
  }
  ids
}


.catdes_ground_reconcile_grounding <- function(status,
                                                support_type,
                                                supporting,
                                                contradicting,
                                                group_name,
                                                index) {
  notes <- character(0)
  original_status <- status
  original_support_type <- support_type

  needs_downgrade <- FALSE
  reason <- NULL

  if (identical(status, "supported") &&
      (length(supporting) == 0L || identical(support_type, "none"))) {
    needs_downgrade <- TRUE
    reason <- "`supported` lacked explicit supporting evidence or used `support_type = none`"
  } else if (identical(status, "contradicted") && length(contradicting) == 0L) {
    needs_downgrade <- TRUE
    reason <- "`contradicted` lacked explicit contradicting evidence"
  } else if (identical(status, "mixed") &&
             (length(supporting) == 0L || length(contradicting) == 0L ||
              identical(support_type, "none"))) {
    needs_downgrade <- TRUE
    reason <- "`mixed` lacked both evidence directions or used `support_type = none`"
  }

  if (isTRUE(needs_downgrade)) {
    status <- "insufficient"
    if (length(supporting) == 0L) {
      support_type <- "none"
    }
    notes <- paste0(
      "R conservatively downgraded the LLM grounding from `",
      original_status, "` / `", original_support_type,
      "` to `insufficient` / `", support_type, "` because ", reason,
      ". No Evidence ID was invented and any cited local evidence was preserved."
    )
  }

  list(
    status = status,
    support_type = support_type,
    normalization_notes = notes
  )
}

.catdes_ground_parse_assertions <- function(text,
                                             group_name,
                                             evidence_reference_map) {
  json <- .catdes_ground_extract_json_object(text)
  parsed <- jsonlite::fromJSON(json, simplifyVector = FALSE)

  assertions <- parsed$assertions
  if (!is.list(assertions)) {
    stop(
      paste0("Grounding response for group '", group_name,
             "' must contain an `assertions` array."),
      call. = FALSE
    )
  }

  out <- vector("list", length(assertions))
  if (length(assertions) == 0L) {
    return(out)
  }

  for (i in seq_along(assertions)) {
    item <- assertions[[i]]
    if (!is.list(item)) {
      stop(
        sprintf("Assertion %d in group '%s' is not a JSON object.", i, group_name),
        call. = FALSE
      )
    }

    assertion_text <- item$text
    if (!is.character(assertion_text) || length(assertion_text) != 1L ||
        is.na(assertion_text) || !nzchar(trimws(assertion_text))) {
      stop(
        sprintf("Assertion %d in group '%s' has invalid `text`.", i, group_name),
        call. = FALSE
      )
    }

    epistemic_level <- .catdes_ground_scalar_choice(
      item$epistemic_level,
      .catdes_ground_epistemic_levels,
      "epistemic_level",
      group_name,
      i
    )
    grounding_status <- .catdes_ground_scalar_choice(
      item$grounding_status,
      .catdes_ground_statuses,
      "grounding_status",
      group_name,
      i
    )
    support_type <- .catdes_ground_scalar_choice(
      item$support_type,
      .catdes_ground_support_types,
      "support_type",
      group_name,
      i
    )

    supporting <- .catdes_ground_character_array(
      item$supporting_evidence_ids,
      "supporting_evidence_ids",
      group_name,
      i
    )
    contradicting <- .catdes_ground_character_array(
      item$contradicting_evidence_ids,
      "contradicting_evidence_ids",
      group_name,
      i
    )

    supporting <- .catdes_ground_validate_evidence_ids(
      supporting,
      evidence_reference_map,
      "supporting_evidence_ids",
      group_name,
      i
    )
    contradicting <- .catdes_ground_validate_evidence_ids(
      contradicting,
      evidence_reference_map,
      "contradicting_evidence_ids",
      group_name,
      i
    )

    rationale <- item$rationale
    if (!is.character(rationale) || length(rationale) != 1L ||
        is.na(rationale) || !nzchar(trimws(rationale))) {
      stop(
        sprintf("Assertion %d in group '%s' has invalid `rationale`.", i, group_name),
        call. = FALSE
      )
    }

    reconciled <- .catdes_ground_reconcile_grounding(
      status = grounding_status,
      support_type = support_type,
      supporting = supporting,
      contradicting = contradicting,
      group_name = group_name,
      index = i
    )
    grounding_status <- reconciled$status
    support_type <- reconciled$support_type

    out[[i]] <- list(
      assertion_id = paste0(
        "assertion::", group_name, "::", sprintf("%03d", i)
      ),
      group = group_name,
      text = trimws(assertion_text),
      epistemic_level = epistemic_level,
      epistemic_temperature = unname(
        .catdes_ground_temperatures[[epistemic_level]]
      ),
      grounding = list(
        status = grounding_status,
        support_type = support_type,
        supporting_evidence_ids = supporting,
        contradicting_evidence_ids = contradicting,
        rationale = trimws(rationale),
        normalization_notes = reconciled$normalization_notes
      )
    )
  }

  out
}

.catdes_ground_summary <- function(assertions) {
  statuses <- if (length(assertions) == 0L) {
    character(0)
  } else {
    vapply(assertions, function(x) x$grounding$status, character(1))
  }
  levels <- if (length(assertions) == 0L) {
    character(0)
  } else {
    vapply(assertions, function(x) x$epistemic_level, character(1))
  }

  counts <- stats::setNames(
    as.list(as.integer(vapply(
      .catdes_ground_statuses,
      function(status) sum(statuses == status),
      integer(1)
    ))),
    .catdes_ground_statuses
  )

  list(
    grounding_counts = counts,
    hypotheses = if (length(assertions) == 0L) character(0) else vapply(
      assertions[levels == "hypothesis"],
      function(x) x$text,
      character(1)
    ),
    contradicted_assertions = if (length(assertions) == 0L) character(0) else vapply(
      assertions[statuses == "contradicted"],
      function(x) x$text,
      character(1)
    )
  )
}

.catdes_ground_backend_content <- function(result, group_name) {
  if (is.data.frame(result) && "response" %in% names(result) && nrow(result) > 0L) {
    return(as.character(result$response[[1L]]))
  }
  if (is.character(result) && length(result) == 1L && !is.na(result)) {
    return(result)
  }
  stop(
    paste0("Grounding backend returned no usable response for group '", group_name, "'."),
    call. = FALSE
  )
}

#' Critically review a `nail_catdes()` interpretation
#'
#' `nail_catdes_ground()` is an optional second analytical pass. It does not
#' modify or regenerate the semantic interpretation produced by
#' [nail_catdes()]. Instead, it freezes each local PASS 1 response, decomposes
#' it into assertions, assigns an epistemic level from fact to hypothesis, and
#' grounds each assertion against the local statistical evidence that was
#' available to that group.
#'
#' Epistemic temperature and grounding are deliberately independent. The
#' temperature describes distance from direct observation (`0 = fact`,
#' `1 = semantic_pattern`, `2 = interpretation`, `3 = hypothesis`), whereas
#' grounding describes evidential status relative to the local evidence
#' (`supported`, `contradicted`, `insufficient`, or `mixed`).
#'
#' @param x A result returned by `nail_catdes()` after local semantic profiles
#'   have been generated. PASS 1 is never modified by this function.
#' @param model LLM model used for the epistemic review. When `NULL`, inherit
#'   the model recorded by `nail_catdes()`; fall back to `"llama3"`.
#' @param provider LLM backend, `"ollama"` or `"gemini"`. When `NULL`, inherit
#'   the provider recorded by `nail_catdes()`; fall back to `"ollama"`.
#' @param generate Logical. If `FALSE` (default), build and return grounding
#'   prompts without calling an LLM. If `TRUE`, run one independent grounding
#'   call per group that has both a generated PASS 1 response and local
#'   statistical evidence.
#' @param ... Additional backend options forwarded to NaileR's LLM caller.
#'
#' @return An object of class `nail_catdes_ground`. It contains a preserved
#'   copy of the PASS 1 semantic profiles, the local grounding prompts,
#'   deterministic short-to-canonical `evidence_reference_maps`, and a
#'   `grounded_profiles` list. The input `x` is not modified. A `timing`
#'   component records total wall-clock/CPU time and, when generation is
#'   enabled, backend and parse/validation timing for each grounded group.
#'
#' @export
nail_catdes_ground <- function(x,
                               model = NULL,
                               provider = NULL,
                               generate = FALSE,
                               ...) {
  total_timer <- .catdes_ground_timer_start()
  .catdes_ground_assert_single_logical(generate, "generate")
  artifacts <- .validate_nail_catdes_ground_input(x)
  backend <- .catdes_ground_resolve_backend(
    model = model,
    provider = provider,
    catdes_settings = artifacts$catdes_settings
  )

  semantic_profiles <- artifacts$semantic_profiles
  semantic_facing <- artifacts$semantic_facing_evidence
  interpretation_mode <- semantic_profiles$settings$interpretation_mode
  target_label <- semantic_profiles$settings$target_label
  group_names <- names(semantic_profiles$groups)

  prompts <- stats::setNames(vector("list", length(group_names)), group_names)
  evidence_reference_maps <- stats::setNames(vector("list", length(group_names)), group_names)
  grounded_profiles <- stats::setNames(vector("list", length(group_names)), group_names)
  eligible <- logical(length(group_names))
  names(eligible) <- group_names

  for (group_name in group_names) {
    semantic_group <- semantic_profiles$groups[[group_name]]
    evidence_group <- semantic_facing$groups[[group_name]]
    group_index <- match(group_name, group_names)
    group_evidence_map <- .catdes_ground_evidence_map(
      evidence_group,
      group_index = group_index
    )
    evidence_reference_maps[[group_name]] <- stats::setNames(
      group_evidence_map$evidence_id,
      group_evidence_map$evidence_ref
    )

    has_response <- identical(semantic_group$status, "generated") &&
      is.character(semantic_group$response) &&
      length(semantic_group$response) == 1L &&
      !is.na(semantic_group$response) &&
      nzchar(trimws(semantic_group$response))
    has_evidence <- identical(evidence_group$status, "ready") &&
      is.data.frame(evidence_group$displayed_evidence) &&
      nrow(evidence_group$displayed_evidence) > 0L

    eligible[[group_name]] <- isTRUE(has_response && has_evidence)

    if (!isTRUE(eligible[[group_name]])) {
      prompts[[group_name]] <- NULL
      grounded_profiles[[group_name]] <- list(
        group = group_name,
        status = if (!isTRUE(has_response)) {
          "not_grounded_no_generated_profile"
        } else {
          "not_grounded_no_evidence"
        },
        raw_response = semantic_group$response,
        assertions = list(),
        summary = .catdes_ground_summary(list()),
        metadata = list(
          architecture = "optional_local_epistemic_review",
          grounded = FALSE
        )
      )
      next
    }

    prompts[[group_name]] <- .build_catdes_ground_prompt(
      group_name = group_name,
      group_index = group_index,
      semantic_profile = semantic_group,
      semantic_facing_group = evidence_group,
      interpretation_mode = interpretation_mode,
      target_label = target_label
    )

    grounded_profiles[[group_name]] <- list(
      group = group_name,
      status = "prompt_ready",
      raw_response = semantic_group$response,
      assertions = list(),
      summary = .catdes_ground_summary(list()),
      metadata = list(
        architecture = "optional_local_epistemic_review",
        grounded = FALSE
      )
    )
  }

  backend_results <- stats::setNames(vector("list", length(group_names)), group_names)
  grounding_call_timings <- stats::setNames(vector("list", length(group_names)), group_names)
  llm_calls <- 0L

  if (isTRUE(generate)) {
    llm_api_options <- list(...)

    for (group_name in group_names[eligible]) {
      group_timer <- .catdes_ground_timer_start()
      backend_timer <- .catdes_ground_timer_start()

      result <- .call_llm_base(
        provider = backend$provider,
        model = backend$model,
        prompt = prompts[[group_name]],
        output = "df",
        llm_api_options = llm_api_options
      )
      backend_timing <- .catdes_ground_timer_stop(backend_timer)

      backend_results[[group_name]] <- result
      llm_calls <- llm_calls + 1L

      parse_timer <- .catdes_ground_timer_start()
      content <- .catdes_ground_backend_content(result, group_name)
      evidence_reference_map <- evidence_reference_maps[[group_name]]
      assertions <- .catdes_ground_parse_assertions(
        text = content,
        group_name = group_name,
        evidence_reference_map = evidence_reference_map
      )
      parse_timing <- .catdes_ground_timer_stop(parse_timer)
      group_timing <- .catdes_ground_timer_stop(group_timer)

      grounding_call_timings[[group_name]] <- list(
        total = group_timing,
        backend = backend_timing,
        parse_and_validate = parse_timing
      )

      grounded_profiles[[group_name]] <- list(
        group = group_name,
        status = "grounded",
        raw_response = semantic_profiles$groups[[group_name]]$response,
        assertions = assertions,
        summary = .catdes_ground_summary(assertions),
        backend_result = result,
        metadata = list(
          architecture = "optional_local_epistemic_review",
          grounded = TRUE,
          timing = grounding_call_timings[[group_name]]
        )
      )
    }
  }

  total_timing <- .catdes_ground_timer_stop(total_timer)

  out <- list(
    semantic_profiles = semantic_profiles,
    grounding_prompts = prompts,
    evidence_reference_maps = evidence_reference_maps,
    grounded_profiles = grounded_profiles,
    settings = list(
      architecture = "optional_local_epistemic_review",
      interpretation_mode = interpretation_mode,
      target_label = target_label,
      generate = generate,
      provider = backend$provider,
      model = backend$model,
      epistemic_levels = .catdes_ground_epistemic_levels,
      epistemic_temperature = as.list(.catdes_ground_temperatures),
      grounding_statuses = .catdes_ground_statuses,
      support_types = .catdes_ground_support_types,
      global_synthesis_performed = FALSE,
      llm_calls = as.integer(llm_calls)
    ),
    metadata = list(
      schema = "NaileR::catdes_ground",
      schema_version = "0.2.0",
      source_semantic_schema = semantic_profiles$metadata$schema,
      n_groups = as.integer(length(group_names)),
      n_eligible_groups = as.integer(sum(eligible)),
      n_grounded_groups = as.integer(sum(vapply(
        grounded_profiles,
        function(group) identical(group$status, "grounded"),
        logical(1)
      )))
    ),
    timing = list(
      total = total_timing,
      grounding_calls = grounding_call_timings
    )
  )

  class(out) <- c("nail_catdes_ground", "list")
  out
}
