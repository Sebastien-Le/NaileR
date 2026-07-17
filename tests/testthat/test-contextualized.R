.ctx_statistical_profiles <- function(groups = c("A", "B")) {
  registry <- data.frame(
    evidence_id = paste0(groups, "::quanti::score"),
    group = groups,
    marker_type = "quantitative",
    variable = "score",
    modality = NA_character_,
    direction = c("higher", "lower")[seq_along(groups)],
    direction_basis = "v_test",
    v_test = c(2.4, -2.1)[seq_along(groups)],
    p_value = c(0.01, 0.03)[seq_along(groups)],
    abs_v_test = abs(c(2.4, -2.1)[seq_along(groups)]),
    rank = 1L,
    source = "catdes$quanti",
    source_row = 1L,
    stringsAsFactors = FALSE
  )
  profiles <- lapply(groups, function(group) {
    id <- paste0(group, "::quanti::score")
    list(
      group = group,
      qualitative_markers = data.frame(),
      quantitative_markers = data.frame(
        evidence_id = id,
        group = group,
        variable = "score",
        direction = if (group == groups[[1]]) "higher" else "lower",
        v_test = registry$v_test[registry$group == group],
        p_value = registry$p_value[registry$group == group],
        rank = 1L,
        stringsAsFactors = FALSE
      ),
      positive_markers = data.frame(),
      negative_markers = data.frame(),
      metrics = list(n_quantitative_markers = 1L),
      evidence_ids = id,
      factual_summary = paste0("Group ", group, " has one quantitative marker.")
    )
  })
  names(profiles) <- groups
  out <- list(
    groups = profiles,
    evidence_registry = registry,
    settings = list(proba = 0.05),
    metadata = list(schema = "NaileR::statistical_profiles")
  )
  class(out) <- c("nail_catdes_prep", "statistical_profiles", "list")
  out
}

.ctx_textual_claim <- function(text, evidence_id, status = "expert_interpretation",
                               validation_needed = NULL) {
  list(
    text = text,
    status = status,
    evidence_ids = evidence_id,
    validation_needed = validation_needed
  )
}

.ctx_textual_group_profile <- function(group, evidence_id, quotation) {
  claim <- .ctx_textual_claim(paste0("Text profile for ", group), evidence_id)
  list(
    group = group,
    core_textual_profile = claim,
    main_themes = list(.ctx_textual_claim("A recurring practical theme", evidence_id)),
    dominant_concerns = list(.ctx_textual_claim("A practical concern", evidence_id)),
    tone_or_stance = .ctx_textual_claim("A pragmatic stance", evidence_id),
    narrative_frames = list(),
    motivations = list(),
    barriers = list(),
    perceived_benefits = list(),
    social_norms = list(),
    identity_cues = list(),
    contradictions = list(),
    minority_positions = list(),
    representative_verbatims = list(list(
      evidence_id = evidence_id,
      quotation = quotation,
      rationale = "This exact verbatim illustrates the central theme.",
      status = "expert_interpretation"
    )),
    tension_verbatims = list(),
    intra_group_consistency = .ctx_textual_claim("The available statements are aligned", evidence_id),
    interpretation_limits = list()
  )
}

.ctx_textual_preparation <- function(groups = c("A", "B"),
                                     with_profiles = TRUE,
                                     included = TRUE) {
  ids <- paste0(groups, "::verbatim::", seq_along(groups))
  texts <- paste0("Original statement from ", groups)
  registry <- data.frame(
    evidence_id = ids,
    group = groups,
    row_index = seq_along(groups),
    original_text = texts,
    character_count = nchar(texts),
    word_count = 4L,
    text_status = "non_empty",
    missing_or_empty = FALSE,
    included_in_prompt = included,
    sampling_rank = seq_along(groups),
    exclusion_reason = if (included) NA_character_ else "not_sampled",
    source = "text",
    stringsAsFactors = FALSE
  )
  diagnostics <- data.frame(
    group = groups,
    n_total = 1L,
    n_missing = 0L,
    n_empty = 0L,
    n_whitespace = 0L,
    n_non_empty = 1L,
    n_included_in_prompt = as.integer(included),
    n_excluded_from_prompt = as.integer(!included),
    n_not_sampled = as.integer(!included),
    n_prompt_budget = 0L,
    total_characters = nchar(texts),
    total_words = 4L,
    median_words = 4,
    min_words = 4,
    max_words = 4,
    sampling_fraction = as.numeric(included),
    prompt_character_count = if (included) nchar(texts) else 0L,
    stringsAsFactors = FALSE
  )
  evidence_groups <- lapply(seq_along(groups), function(i) {
    list(
      group = groups[[i]],
      diagnostics = diagnostics[i, , drop = FALSE]
    )
  })
  names(evidence_groups) <- groups
  evidence <- list(
    groups = evidence_groups,
    evidence_registry = registry,
    group_diagnostics = diagnostics,
    settings = list(seed = 1L),
    metadata = list(schema = "NaileR::textual_evidence")
  )
  class(evidence) <- c("textual_evidence", "list")

  profiles <- NULL
  if (with_profiles) {
    profile_groups <- lapply(seq_along(groups), function(i) {
      .ctx_textual_group_profile(groups[[i]], ids[[i]], texts[[i]])
    })
    names(profile_groups) <- groups
    profiles <- list(
      groups = profile_groups,
      cross_group = list(
        shared_themes = list(),
        group_contrasts = list(),
        minority_patterns = list(),
        interpretation_limits = list()
      ),
      metadata = list(
        schema = "NaileR::textual_profiles",
        analysis_scope = "general",
        comparison_mode = "isolated"
      )
    )
  }

  units <- lapply(groups, function(group) {
    list(
      unit = group,
      groups = group,
      prompt = paste0("prompt ", group),
      response = if (with_profiles) "generated" else NULL,
      parsed = list(
        parse_status = if (with_profiles) "success" else "not_generated",
        parse_error = NULL,
        textual_profiles = if (with_profiles) {
          list(
            groups = stats::setNames(list(profiles$groups[[group]]), group),
            cross_group = NULL
          )
        } else {
          NULL
        }
      )
    )
  })
  names(units) <- groups

  out <- list(
    prompt = lapply(units, `[[`, "prompt"),
    response = if (with_profiles) lapply(units, `[[`, "response") else NULL,
    parsed = list(
      parse_status = if (with_profiles) "success" else "not_generated",
      parse_error = NULL,
      textual_profiles = profiles
    ),
    textual_profiles = profiles,
    textual_evidence = evidence,
    units = units,
    legacy_groups = NULL,
    metadata = list(
      schema = "NaileR::nail_textual_prep",
      analysis_scope = "general",
      comparison_mode = "isolated"
    )
  )
  class(out) <- c("nail_textual_prep", "list")
  attr(out, "textual_evidence") <- evidence
  attr(out, "textual_profiles") <- profiles
  out
}

.ctx_integrated_claim <- function(text, stat_ids = character(), text_ids = character(),
                                  status = "expert_interpretation",
                                  relationship = NULL,
                                  validation_needed = NULL,
                                  quotations = list()) {
  list(
    text = text,
    status = status,
    statistical_evidence_ids = unname(stat_ids),
    textual_evidence_ids = unname(text_ids),
    relationship = relationship,
    quotations = quotations,
    validation_needed = validation_needed
  )
}

.ctx_group_analysis <- function(group, stat_id, text_id, quotation) {
  list(
    group = group,
    availability = "available",
    parse_error = NULL,
    integrated_profile = .ctx_integrated_claim(
      paste0("Measured and expressed patterns form an integrated profile for ", group),
      stat_id,
      text_id
    ),
    statistical_textual_convergences = list(.ctx_integrated_claim(
      "The measured direction complements the expressed practical stance",
      stat_id,
      text_id,
      relationship = "complement",
      quotations = list(list(evidence_id = text_id, quotation = quotation))
    )),
    statistical_textual_divergences = list(.ctx_integrated_claim(
      "The discourse adds a nuance not captured by the measured marker",
      stat_id,
      text_id,
      relationship = "tension"
    )),
    statistical_only_findings = list(.ctx_integrated_claim(
      "The measured marker has no direct textual equivalent in this integration",
      stat_id,
      character()
    )),
    textual_only_findings = list(.ctx_integrated_claim(
      "The practical framing has no direct statistical equivalent in this integration",
      character(),
      text_id
    )),
    social_interpretations = list(),
    consumer_insights = list(),
    psychological_hypotheses = list(.ctx_integrated_claim(
      "The discourse may reflect a cautious sense of control",
      stat_id,
      text_id,
      status = "hypothesis",
      validation_needed = "Conduct targeted interviews about perceived control"
    )),
    marketing_implications = list(.ctx_integrated_claim(
      "Test a communication route grounded in practical usefulness",
      stat_id,
      text_id,
      status = "recommendation",
      validation_needed = "Run a controlled message test"
    )),
    innovation_opportunities = list(),
    operational_implications = list(),
    validation_priorities = list(),
    interpretation_limits = list()
  )
}

.ctx_contextualized_response <- function(groups = c("A", "B"),
                                         comparison_mode = "joint") {
  analyses <- lapply(seq_along(groups), function(i) {
    .ctx_group_analysis(
      groups[[i]],
      paste0(groups[[i]], "::quanti::score"),
      paste0(groups[[i]], "::verbatim::", match(groups[[i]], c("A", "B", "C", "Alpha"))),
      paste0("Original statement from ", groups[[i]])
    )
  })
  names(analyses) <- groups
  cross <- if (comparison_mode == "joint") {
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
    NULL
  }
  jsonlite::toJSON(
    list(groups = analyses, cross_group_analysis = cross),
    auto_unbox = TRUE,
    null = "null"
  )
}

.ctx_run_generated <- function(response, comparison_mode = "joint") {
  stat <- .ctx_statistical_profiles()
  text <- .ctx_textual_preparation()
  calls <- new.env(parent = emptyenv())
  calls$n <- 0L
  testthat::local_mocked_bindings(
    .call_llm_base = function(...) {
      calls$n <- calls$n + 1L
      data.frame(response = response[[calls$n]], stringsAsFactors = FALSE)
    },
    .package = "NaileR"
  )
  result <- nail_textual_contextualized(
    integration_mode = "legacy",
    statistical_profiles = stat,
    textual_preparation = text,
    comparison_mode = comparison_mode,
    generate = TRUE
  )
  list(result = result, calls = calls$n)
}

test_that("prepared inputs build complete mechanical integration without upstream calls", {
  stat <- .ctx_statistical_profiles()
  text <- .ctx_textual_preparation()

  testthat::local_mocked_bindings(
    nail_catdes_prep = function(...) stop("statistical preparation was called"),
    nail_textual_prep = function(...) stop("textual preparation was called"),
    .call_llm_base = function(...) stop("LLM backend was called"),
    .package = "NaileR"
  )

  result <- nail_textual_contextualized(
    integration_mode = "legacy",
    statistical_profiles = stat,
    textual_preparation = text,
    generate = FALSE
  )

  expect_s3_class(result, "nail_textual_contextualized")
  expect_s3_class(result$contextualized_evidence, "contextualized_evidence")
  expect_identical(result$parsed$parse_status, "not_generated")
  expect_null(result$contextualized_analysis)
  expect_identical(result$statistical_profiles, stat)
  expect_identical(result$textual_evidence, text$textual_evidence)
  expect_identical(result$textual_profiles, text$textual_profiles)
  expect_identical(result$metadata$upstream_calls$nail_catdes_prep, 0L)
  expect_identical(result$metadata$upstream_calls$nail_textual_prep, 0L)
  expect_identical(result$metadata$integration_llm_calls, 0L)
})

test_that("group alignment is deterministic and independent of source order", {
  first <- nail_textual_contextualized(
    integration_mode = "legacy",
    statistical_profiles = .ctx_statistical_profiles(c("A", "B")),
    textual_preparation = .ctx_textual_preparation(c("A", "B")),
    generate = FALSE
  )
  second <- nail_textual_contextualized(
    integration_mode = "legacy",
    statistical_profiles = .ctx_statistical_profiles(c("B", "A")),
    textual_preparation = .ctx_textual_preparation(c("B", "A")),
    generate = FALSE
  )

  expect_identical(
    first$contextualized_evidence$group_alignment,
    second$contextualized_evidence$group_alignment
  )
  expect_identical(
    names(first$contextualized_evidence$groups),
    c("A", "B")
  )
})

test_that("groups present in only one source remain explicit", {
  result <- nail_textual_contextualized(
    integration_mode = "legacy",
    statistical_profiles = .ctx_statistical_profiles(c("A", "B")),
    textual_preparation = .ctx_textual_preparation(c("A", "C")),
    generate = FALSE
  )
  alignment <- result$contextualized_evidence$group_alignment

  expect_identical(alignment$alignment_status[alignment$canonical_group == "A"], "matched")
  expect_identical(alignment$alignment_status[alignment$canonical_group == "B"], "statistical_only")
  expect_identical(alignment$alignment_status[alignment$canonical_group == "C"], "textual_only")
  expect_true(any(grepl(
    "No traceable textual evidence",
    result$contextualized_evidence$groups$B$integration_limits,
    fixed = TRUE
  )))
  expect_true(any(grepl(
    "No statistical profile",
    result$contextualized_evidence$groups$C$integration_limits,
    fixed = TRUE
  )))
})

test_that("manual group mapping preserves source names and canonical group", {
  stat <- .ctx_statistical_profiles("A")
  text <- .ctx_textual_preparation("Alpha")
  text$textual_evidence$evidence_registry$evidence_id <- "Alpha::verbatim::1"
  text$textual_profiles$groups$Alpha$core_textual_profile$evidence_ids <- "Alpha::verbatim::1"

  result <- nail_textual_contextualized(
    integration_mode = "legacy",
    statistical_profiles = stat,
    textual_preparation = text,
    group_map = c(A = "Alpha"),
    generate = FALSE
  )
  alignment <- result$contextualized_evidence$group_alignment
  registry <- result$contextualized_evidence$combined_evidence_registry

  expect_identical(alignment$canonical_group, "A")
  expect_identical(alignment$textual_group, "Alpha")
  expect_identical(alignment$alignment_basis, "manual_map")
  expect_true(all(registry$group[registry$source_group == "Alpha"] == "A"))
  expect_identical(result$metadata$group_map, c(A = "Alpha"))
})

test_that("invalid and ambiguous group maps fail explicitly", {
  expect_error(
    nail_textual_contextualized(
    integration_mode = "legacy",
      statistical_profiles = .ctx_statistical_profiles(),
      textual_preparation = .ctx_textual_preparation(),
      group_map = c(A = "Z"),
      generate = FALSE
    ),
    "unknown textual"
  )
  expect_error(
    nail_textual_contextualized(
    integration_mode = "legacy",
      statistical_profiles = .ctx_statistical_profiles(),
      textual_preparation = .ctx_textual_preparation(),
      group_map = c(A = "A", B = "A"),
      generate = FALSE
    ),
    "several statistical groups"
  )
})

test_that("combined registry preserves IDs and distinguishes evidence layers", {
  result <- nail_textual_contextualized(
    integration_mode = "legacy",
    statistical_profiles = .ctx_statistical_profiles(),
    textual_preparation = .ctx_textual_preparation(),
    generate = FALSE
  )
  registry <- result$contextualized_evidence$combined_evidence_registry

  expect_identical(anyDuplicated(registry$evidence_id), 0L)
  expect_true(all(c(
    "statistical_quantitative",
    "textual_verbatim",
    "textual_interpretation"
  ) %in% registry$evidence_type))
  expect_true("A::quanti::score" %in% registry$evidence_id)
  expect_true("A::verbatim::1" %in% registry$evidence_id)
  interpretation_rows <- registry$evidence_type == "textual_interpretation"
  expect_true(any(lengths(registry$grounding_evidence_ids[interpretation_rows]) > 0L))
})

test_that("prompt hierarchy separates statistics, verbatims, profiles and context", {
  joint <- nail_textual_contextualized(
    integration_mode = "legacy",
    statistical_profiles = .ctx_statistical_profiles(),
    textual_preparation = .ctx_textual_preparation(),
    context = list(study = "Food practices study"),
    request = "Focus on practical tensions.",
    generate = FALSE
  )
  prompt <- joint$prompt
  headers <- c(
    "STATISTICAL EVIDENCE",
    "TEXTUAL EVIDENCE",
    "VALIDATED TEXTUAL PROFILES",
    "USER-PROVIDED CONTEXT",
    "INTEGRATION TASK",
    "ADDITIONAL USER REQUEST",
    "MANDATORY EPISTEMIC RULES",
    "OUTPUT SCHEMA"
  )
  positions <- vapply(headers, function(x) regexpr(x, prompt, fixed = TRUE)[[1]], integer(1))

  expect_true(all(positions > 0L))
  expect_true(all(diff(positions) > 0L))
  expect_match(prompt, "Food practices study", fixed = TRUE)
  expect_match(prompt, "A::quanti::score", fixed = TRUE)
  expect_match(prompt, "A::verbatim::1", fixed = TRUE)
  expect_match(prompt, "These three layers must not be confused", fixed = TRUE)
})

test_that("joint and isolated modes change units but not evidence", {
  joint <- nail_textual_contextualized(
    integration_mode = "legacy",
    statistical_profiles = .ctx_statistical_profiles(),
    textual_preparation = .ctx_textual_preparation(),
    comparison_mode = "joint",
    generate = FALSE
  )
  isolated <- nail_textual_contextualized(
    integration_mode = "legacy",
    statistical_profiles = .ctx_statistical_profiles(),
    textual_preparation = .ctx_textual_preparation(),
    comparison_mode = "isolated",
    generate = FALSE
  )

  expect_identical(joint$contextualized_evidence, isolated$contextualized_evidence)
  expect_identical(names(joint$units), "joint")
  expect_setequal(names(isolated$units), c("A", "B"))
  expect_identical(isolated$units$A$groups, "A")
  expect_false(grepl("B::verbatim", isolated$units$A$prompt, fixed = TRUE))
})

test_that("interpretive options do not modify contextualized evidence", {
  baseline <- nail_textual_contextualized(
    integration_mode = "legacy",
    statistical_profiles = .ctx_statistical_profiles(),
    textual_preparation = .ctx_textual_preparation(),
    generate = FALSE
  )
  variant <- nail_textual_contextualized(
    integration_mode = "legacy",
    statistical_profiles = .ctx_statistical_profiles(),
    textual_preparation = .ctx_textual_preparation(),
    analysis_scope = "sociological",
    context = list(territory = "Rural area"),
    request = "Examine legitimacy.",
    prompt_style = "compact",
    report_format = "markdown",
    provider = "gemini",
    model = "another-model",
    generate = FALSE
  )

  expect_identical(baseline$contextualized_evidence, variant$contextualized_evidence)
  expect_false(identical(baseline$prompt, variant$prompt))
})

test_that("valid generated JSON is parsed with one integration call in joint mode", {
  run <- .ctx_run_generated(list(.ctx_contextualized_response()))
  result <- run$result

  expect_identical(run$calls, 1L)
  expect_identical(result$parsed$parse_status, "success")
  expect_s3_class(result, "nail_textual_contextualized")
  expect_true(is.list(result$contextualized_analysis$groups$A))
  convergence <- result$contextualized_analysis$groups$A$statistical_textual_convergences[[1]]
  expect_identical(convergence$relationship, "complement")
  expect_identical(convergence$statistical_evidence_ids, "A::quanti::score")
  expect_identical(convergence$textual_evidence_ids, "A::verbatim::1")
  expect_identical(convergence$quotations[[1]]$quotation, "Original statement from A")
})

test_that("invalid JSON is retained with an explicit parse error", {
  run <- .ctx_run_generated(list("not JSON"))
  expect_identical(run$result$parsed$parse_status, "error")
  expect_match(run$result$parsed$parse_error, "strict JSON")
  expect_null(run$result$contextualized_analysis)
  expect_identical(run$result$units$joint$response$response, "not JSON")
})

test_that("unknown statistical evidence is rejected", {
  parsed <- jsonlite::fromJSON(.ctx_contextualized_response(), simplifyDataFrame = FALSE)
  parsed$groups$A$integrated_profile$statistical_evidence_ids <- "unknown::stat"
  response <- jsonlite::toJSON(parsed, auto_unbox = TRUE, null = "null")
  run <- .ctx_run_generated(list(response))

  expect_identical(run$result$parsed$parse_status, "error")
  expect_match(run$result$parsed$parse_error, "unknown statistical")
})

test_that("unknown or non-presented textual evidence is rejected", {
  parsed <- jsonlite::fromJSON(.ctx_contextualized_response(), simplifyDataFrame = FALSE)
  parsed$groups$A$integrated_profile$textual_evidence_ids <- "unknown::text"
  response <- jsonlite::toJSON(parsed, auto_unbox = TRUE, null = "null")
  run <- .ctx_run_generated(list(response))

  expect_identical(run$result$parsed$parse_status, "error")
  expect_match(run$result$parsed$parse_error, "non-presented textual")
})

test_that("convergences and divergences require both evidence types", {
  parsed <- jsonlite::fromJSON(.ctx_contextualized_response(), simplifyDataFrame = FALSE)
  parsed$groups$A$statistical_textual_convergences[[1]]$textual_evidence_ids <- list()
  response <- jsonlite::toJSON(parsed, auto_unbox = TRUE, null = "null")
  run <- .ctx_run_generated(list(response))
  expect_identical(run$result$parsed$parse_status, "error")
  expect_match(run$result$parsed$parse_error, "both statistical and textual")

  parsed <- jsonlite::fromJSON(.ctx_contextualized_response(), simplifyDataFrame = FALSE)
  parsed$groups$A$statistical_textual_divergences[[1]]$statistical_evidence_ids <- list()
  response <- jsonlite::toJSON(parsed, auto_unbox = TRUE, null = "null")
  run <- .ctx_run_generated(list(response))
  expect_identical(run$result$parsed$parse_status, "error")
  expect_match(run$result$parsed$parse_error, "both statistical and textual")
})

test_that("group claims cannot cite evidence from another group", {
  response <- .ctx_contextualized_response("A", comparison_mode = "isolated")
  parsed <- jsonlite::fromJSON(response, simplifyDataFrame = FALSE)
  parsed$groups$A$integrated_profile$textual_evidence_ids <- "B::verbatim::2"
  response <- jsonlite::toJSON(parsed, auto_unbox = TRUE, null = "null")

  stat <- .ctx_statistical_profiles()
  text <- .ctx_textual_preparation()
  testthat::local_mocked_bindings(
    .call_llm_base = function(...) data.frame(response = response, stringsAsFactors = FALSE),
    .package = "NaileR"
  )
  result <- nail_textual_contextualized(
    integration_mode = "legacy",
    statistical_profiles = stat,
    textual_preparation = text,
    comparison_mode = "isolated",
    generate = TRUE
  )
  expect_identical(result$units$A$parsed$parse_status, "error")
  expect_match(result$units$A$parsed$parse_error, "another group")
})

test_that("modified quotations are rejected", {
  parsed <- jsonlite::fromJSON(.ctx_contextualized_response(), simplifyDataFrame = FALSE)
  parsed$groups$A$statistical_textual_convergences[[1]]$quotations[[1]]$quotation <- "Edited statement"
  response <- jsonlite::toJSON(parsed, auto_unbox = TRUE, null = "null")
  run <- .ctx_run_generated(list(response))

  expect_identical(run$result$parsed$parse_status, "error")
  expect_match(run$result$parsed$parse_error, "exactly match original_text")
})

test_that("hypotheses and recommendations require validation_needed", {
  parsed <- jsonlite::fromJSON(.ctx_contextualized_response(), simplifyDataFrame = FALSE)
  parsed$groups$A$psychological_hypotheses[[1]]$validation_needed <- NULL
  response <- jsonlite::toJSON(parsed, auto_unbox = TRUE, null = "null")
  run <- .ctx_run_generated(list(response))
  expect_identical(run$result$parsed$parse_status, "error")
  expect_match(run$result$parsed$parse_error, "validation_needed")

  parsed <- jsonlite::fromJSON(.ctx_contextualized_response(), simplifyDataFrame = FALSE)
  parsed$groups$A$marketing_implications[[1]]$validation_needed <- NULL
  response <- jsonlite::toJSON(parsed, auto_unbox = TRUE, null = "null")
  run <- .ctx_run_generated(list(response))
  expect_identical(run$result$parsed$parse_status, "error")
  expect_match(run$result$parsed$parse_error, "validation_needed")
})

test_that("diagnoses, unsupported numbers and unqualified causality are rejected", {
  parsed <- jsonlite::fromJSON(.ctx_contextualized_response(), simplifyDataFrame = FALSE)
  parsed$groups$A$integrated_profile$text <- "This group is depressed"
  run <- .ctx_run_generated(list(jsonlite::toJSON(parsed, auto_unbox = TRUE, null = "null")))
  expect_identical(run$result$parsed$parse_status, "error")
  expect_match(run$result$parsed$parse_error, "diagnoses")

  parsed <- jsonlite::fromJSON(.ctx_contextualized_response(), simplifyDataFrame = FALSE)
  parsed$groups$A$integrated_profile$text <- "The pattern concerns 74 percent of participants"
  run <- .ctx_run_generated(list(jsonlite::toJSON(parsed, auto_unbox = TRUE, null = "null")))
  expect_identical(run$result$parsed$parse_status, "error")
  expect_match(run$result$parsed$parse_error, "numerical statement")

  parsed <- jsonlite::fromJSON(.ctx_contextualized_response(), simplifyDataFrame = FALSE)
  parsed$groups$A$integrated_profile$text <- "The measured marker causes the practical stance"
  run <- .ctx_run_generated(list(jsonlite::toJSON(parsed, auto_unbox = TRUE, null = "null")))
  expect_identical(run$result$parsed$parse_status, "error")
  expect_match(run$result$parsed$parse_error, "causal claim")
})

test_that("isolated generation preserves valid groups when another unit fails", {
  responses <- list(
    .ctx_contextualized_response("A", "isolated"),
    "invalid"
  )
  stat <- .ctx_statistical_profiles()
  text <- .ctx_textual_preparation()
  calls <- 0L
  testthat::local_mocked_bindings(
    .call_llm_base = function(...) {
      calls <<- calls + 1L
      data.frame(response = responses[[calls]], stringsAsFactors = FALSE)
    },
    .package = "NaileR"
  )
  result <- nail_textual_contextualized(
    integration_mode = "legacy",
    statistical_profiles = stat,
    textual_preparation = text,
    comparison_mode = "isolated",
    generate = TRUE
  )

  expect_identical(result$metadata$integration_llm_calls, 2L)
  expect_identical(result$parsed$parse_status, "partial")
  expect_identical(result$contextualized_analysis$groups$A$availability, "available")
  expect_identical(result$contextualized_analysis$groups$B$availability, "unavailable")
  expect_match(result$contextualized_analysis$groups$B$parse_error, "strict JSON")
})

test_that("a nail_textual result reuses its original preparation", {
  prep <- .ctx_textual_preparation()
  textual_result <- structure(
    list(
      preparation = prep,
      textual_evidence = prep$textual_evidence,
      textual_profiles = prep$textual_profiles,
      metadata = list()
    ),
    class = c("nail_textual", "list")
  )
  result <- nail_textual_contextualized(
    integration_mode = "legacy",
    statistical_profiles = .ctx_statistical_profiles(),
    textual_preparation = textual_result,
    generate = FALSE
  )

  expect_identical(result$textual_preparation, prep)
  expect_identical(result$textual_evidence, prep$textual_evidence)
  expect_identical(result$metadata$upstream_calls$nail_textual_prep, 0L)
})

test_that("raw input calls each upstream preparation at most once", {
  stat <- .ctx_statistical_profiles()
  text <- .ctx_textual_preparation(with_profiles = FALSE)
  calls <- new.env(parent = emptyenv())
  calls$stat <- 0L
  calls$text <- 0L
  calls$stat_args <- NULL

  testthat::local_mocked_bindings(
    nail_catdes_prep = function(...) {
      calls$stat <- calls$stat + 1L
      calls$stat_args <- list(...)
      stat
    },
    nail_textual_prep = function(...) {
      calls$text <- calls$text + 1L
      text
    },
    .call_llm_base = function(...) stop("integration backend was called"),
    .package = "NaileR"
  )

  result <- nail_textual_contextualized(
    integration_mode = "legacy",
    dataset = data.frame(group = c("A", "B"), text = c("a", "b")),
    num.var = 1,
    num.text = 2,
    generate = FALSE
  )

  expect_identical(calls$stat, 1L)
  expect_identical(calls$text, 1L)
  expect_identical(calls$stat_args$exclude, 2)
  expect_identical(result$metadata$upstream_calls$nail_catdes_prep, 1L)
  expect_identical(result$metadata$upstream_calls$nail_textual_prep, 1L)
  expect_null(result$textual_profiles)
})

test_that("report formats are derived without modifying evidence or analysis", {
  response <- .ctx_contextualized_response()
  make <- function(format) {
    stat <- .ctx_statistical_profiles()
    text <- .ctx_textual_preparation()
    testthat::local_mocked_bindings(
      .call_llm_base = function(...) data.frame(response = response, stringsAsFactors = FALSE),
      .package = "NaileR"
    )
    nail_textual_contextualized(
    integration_mode = "legacy",
      statistical_profiles = stat,
      textual_preparation = text,
      report_format = format,
      generate = TRUE
    )
  }
  structured <- make("structured")
  markdown <- make("markdown")
  compact <- make("compact")

  expect_identical(structured$contextualized_evidence, markdown$contextualized_evidence)
  expect_identical(structured$contextualized_evidence, compact$contextualized_evidence)
  expect_identical(structured$contextualized_analysis, markdown$contextualized_analysis)
  expect_identical(structured$contextualized_analysis, compact$contextualized_analysis)
  expect_true(is.character(markdown$report))
  expect_true(is.list(compact$report))
})

test_that("textual evidence without a profile remains usable offline", {
  result <- nail_textual_contextualized(
    integration_mode = "legacy",
    statistical_profiles = .ctx_statistical_profiles(),
    textual_preparation = .ctx_textual_preparation(with_profiles = FALSE),
    generate = FALSE
  )

  expect_null(result$textual_profiles)
  expect_identical(
    result$contextualized_evidence$group_alignment$alignment_status,
    rep("matched_without_textual_profile", 2L)
  )
  expect_true(all(vapply(
    result$contextualized_evidence$groups,
    function(x) any(grepl("no validated textual profile", x$integration_limits, ignore.case = TRUE)),
    logical(1)
  )))
})

test_that("deprecated isolation argument maps explicitly", {
  result <- NULL
  expect_warning(
    result <- nail_textual_contextualized(
    integration_mode = "legacy",
      statistical_profiles = .ctx_statistical_profiles(),
      textual_preparation = .ctx_textual_preparation(),
      isolate.groups = TRUE,
      generate = FALSE
    ),
    "deprecated"
  )
  expect_identical(result$metadata$comparison_mode, "isolated")
  expect_setequal(names(result$units), c("A", "B"))
})

test_that("invalid prepared objects fail explicitly", {
  expect_error(
    nail_textual_contextualized(
    integration_mode = "legacy",
      statistical_profiles = list(),
      textual_preparation = .ctx_textual_preparation(),
      generate = FALSE
    ),
    "statistical source"
  )
  expect_error(
    nail_textual_contextualized(
    integration_mode = "legacy",
      statistical_profiles = .ctx_statistical_profiles(),
      textual_preparation = list(),
      generate = FALSE
    ),
    "textual source"
  )
  expect_error(
    nail_textual_contextualized(generate = FALSE),
    "Provide"
  )
})


.ctx_modular_claim <- function(text,
                               stat = character(),
                               textual = character(),
                               validation_needed = NULL) {
  list(
    text = text,
    status = "expert_interpretation",
    statistical_evidence_ids = as.list(stat),
    textual_evidence_ids = as.list(textual),
    validation_needed = validation_needed
  )
}

.ctx_modular_dispatch <- function(prompt,
                                  schema,
                                  provider,
                                  model,
                                  unit_type,
                                  unit_data,
                                  ...) {
  if (identical(unit_type, "group")) {
    stat <- unit_data$allowed_statistical_evidence_ids[[1L]]
    textual <- unit_data$allowed_textual_evidence_ids[[1L]]

    return(list(
      content = jsonlite::toJSON(
        list(
          group = unit_data$group,
          integrated_profile = .ctx_modular_claim(
            paste("Integrated profile", unit_data$group),
            stat,
            textual
          ),
          convergences = list(
            .ctx_modular_claim(
              paste("Convergence", unit_data$group),
              stat,
              textual
            )
          ),
          tensions = list(),
          statistical_only_findings = list(),
          textual_only_findings = list(),
          interpretation_limits = list(
            .ctx_modular_claim(
              paste("Coverage limit", unit_data$group)
            )
          )
        ),
        auto_unbox = TRUE,
        null = "null"
      ),
      elapsed_seconds = 0
    ))
  }

  list(
    content = jsonlite::toJSON(
      list(
        shared_patterns = list(
          .ctx_modular_claim(
            "Validated shared pattern",
            unit_data$allowed_statistical_evidence_ids,
            unit_data$allowed_textual_evidence_ids
          )
        ),
        major_group_contrasts = list(),
        different_relationships = list(),
        interpretation_limits = list(
          .ctx_modular_claim("Cross-group coverage limit")
        )
      ),
      auto_unbox = TRUE,
      null = "null"
    ),
    elapsed_seconds = 0
  )
}


test_that("public modular preparation is offline and builds group prompts", {
  testthat::local_mocked_bindings(
    .nctx_dispatch_call = function(...) {
      stop("backend must not be called")
    },
    .package = "NaileR"
  )

  result <- nail_textual_contextualized(
    statistical_profiles = .ctx_statistical_profiles(),
    textual_preparation = .ctx_textual_preparation(),
    generate = FALSE
  )

  expect_identical(result$metadata$integration_mode, "modular")
  expect_identical(result$metadata$parse_status, "not_generated")
  expect_identical(result$metadata$integration_llm_calls, 0L)
  expect_null(result$contextualized_analysis)
  expect_setequal(names(result$units), c("A", "B", "cross_group"))
  expect_true(is.character(result$units$A$prompt))
  expect_identical(result$units$A$prompt_contract, "modular")
  expect_true(result$units$A$prompt_generation_eligible)
  expect_null(result$units$cross_group$prompt)
})


test_that("public contextualized analysis uses modular integration by default", {
  calls <- character()

  testthat::local_mocked_bindings(
    .nctx_dispatch_call = function(..., unit_type, unit_data) {
      calls <<- c(calls, unit_type)
      .ctx_modular_dispatch(
        ...,
        unit_type = unit_type,
        unit_data = unit_data
      )
    },
    .package = "NaileR"
  )

  result <- nail_textual_contextualized(
    statistical_profiles = .ctx_statistical_profiles(),
    textual_preparation = .ctx_textual_preparation(),
    context = list(study = "Food practices"),
    request = "Focus on defensible integration.",
    generate = TRUE
  )

  expect_s3_class(result, "nail_textual_contextualized")
  expect_identical(result$metadata$integration_mode, "modular")
  expect_identical(result$metadata$expertise, "integration")
  expect_identical(result$metadata$integration_llm_calls, 3L)
  expect_identical(calls, c("group", "group", "cross_group"))
  expect_identical(result$parsed$parse_status, "success")
  expect_true(is.list(result$core_analysis$groups$A))
  expect_identical(
    result$core_analysis$groups$A$integrated_profile$relationship,
    "convergence"
  )
  expect_length(
    result$contextualized_analysis$groups$A$marketing_implications,
    0L
  )
  expect_setequal(names(result$units), c("A", "B", "cross_group"))
  expect_match(
    result$units$A$prompt,
    "USER-PROVIDED CONTEXT (NOT EVIDENCE)",
    fixed = TRUE
  )
  expect_match(result$units$A$prompt, "Food practices", fixed = TRUE)
  expect_identical(result$metadata$normalization_warning_count, 0L)
})


test_that("public modular mode selects the Gemini default model", {
  models <- character()

  testthat::local_mocked_bindings(
    .nctx_dispatch_call = function(..., model, unit_type, unit_data) {
      models <<- c(models, model)
      .ctx_modular_dispatch(
        ...,
        model = model,
        unit_type = unit_type,
        unit_data = unit_data
      )
    },
    .package = "NaileR"
  )

  result <- nail_textual_contextualized(
    statistical_profiles = .ctx_statistical_profiles(),
    textual_preparation = .ctx_textual_preparation(),
    provider = "gemini",
    generate = TRUE
  )

  expect_true(length(models) == 3L)
  expect_true(all(models == "gemini-3.5-flash"))
  expect_identical(result$metadata$model, "gemini-3.5-flash")
})


test_that("modular isolated mode omits the cross-group request", {
  calls <- character()

  testthat::local_mocked_bindings(
    .nctx_dispatch_call = function(..., unit_type, unit_data) {
      calls <<- c(calls, unit_type)
      .ctx_modular_dispatch(
        ...,
        unit_type = unit_type,
        unit_data = unit_data
      )
    },
    .package = "NaileR"
  )

  result <- nail_textual_contextualized(
    statistical_profiles = .ctx_statistical_profiles(),
    textual_preparation = .ctx_textual_preparation(),
    comparison_mode = "isolated",
    generate = TRUE
  )

  expect_identical(calls, c("group", "group"))
  expect_identical(result$metadata$integration_llm_calls, 2L)
  expect_identical(result$metadata$cross_group, FALSE)
  expect_false("cross_group" %in% names(result$units))
  expect_identical(result$parsed$parse_status, "success")
})


test_that("modular mode skips source-incomplete groups without an invalid call", {
  calls <- character()

  testthat::local_mocked_bindings(
    .nctx_dispatch_call = function(..., unit_type, unit_data) {
      calls <<- c(calls, paste(unit_type, if (is.null(unit_data$group)) "cross" else unit_data$group))
      .ctx_modular_dispatch(
        ...,
        unit_type = unit_type,
        unit_data = unit_data
      )
    },
    .package = "NaileR"
  )

  result <- nail_textual_contextualized(
    statistical_profiles = .ctx_statistical_profiles(c("A", "B")),
    textual_preparation = .ctx_textual_preparation(c("A", "C")),
    generate = TRUE
  )

  expect_identical(calls, "group A")
  expect_identical(result$metadata$integration_llm_calls, 1L)
  expect_identical(result$metadata$parse_status, "partial")
  expect_identical(result$metadata$group_parse_status[["A"]], "success")
  expect_identical(
    result$metadata$group_parse_status[["B"]],
    "not_applicable"
  )
  expect_identical(
    result$metadata$group_parse_status[["C"]],
    "not_applicable"
  )
  expect_identical(
    result$contextualized_analysis$groups$A$availability,
    "available"
  )
  expect_identical(
    result$contextualized_analysis$groups$B$availability,
    "unavailable"
  )
})


test_that("legacy integration remains explicitly available", {
  run <- .ctx_run_generated(list(.ctx_contextualized_response()))

  expect_identical(run$result$metadata$integration_mode, "legacy")
  expect_identical(run$calls, 1L)
  expect_identical(run$result$parsed$parse_status, "success")
})
