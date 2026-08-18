.textual_test_claim <- function(text,
                                evidence_ids,
                                support = "The cited verbatim explicitly supports this interpretation.") {
  list(
    text = text,
    status = "expert_interpretation",
    evidence_ids = as.list(evidence_ids),
    support = support,
    validation_needed = NULL
  )
}

.textual_test_group_profile <- function(group, evidence_id, quotation) {
  claim <- .textual_test_claim(
    paste("The group expresses a practical orientation grounded in", quotation),
    evidence_id
  )

  list(
    group = group,
    core_textual_profile = claim,
    main_themes = list(
      .textual_test_claim(
        "Practical considerations structure the discourse.",
        evidence_id
      )
    ),
    dominant_concerns = list(
      .textual_test_claim("Ease of use is explicitly valued.", evidence_id)
    ),
    tone_or_stance = .textual_test_claim(
      "The expressed stance is pragmatic.",
      evidence_id
    ),
    internal_variation = list(),
    minority_positions = list(),
    representative_verbatims = list(
      list(
        evidence_id = evidence_id,
        quotation = quotation,
        rationale = "This verbatim directly expresses the central practical theme.",
        status = "expert_interpretation"
      )
    ),
    contrastive_verbatims = list(),
    interpretation_limits = list()
  )
}

.textual_test_response <- function(evidence, groups) {
  profiles <- stats::setNames(lapply(groups, function(group) {
    rows <- evidence$evidence_registry[
      evidence$evidence_registry$group == group &
        evidence$evidence_registry$included_in_prompt,
      ,
      drop = FALSE
    ]
    stopifnot(nrow(rows) > 0L)
    .textual_test_group_profile(
      group = group,
      evidence_id = rows$evidence_id[[1]],
      quotation = rows$original_text[[1]]
    )
  }), groups)

  jsonlite::toJSON(
    list(groups = profiles),
    auto_unbox = TRUE,
    null = "null",
    na = "null"
  )
}

.textual_test_dataset <- function() {
  data.frame(
    group = factor(c("A", "A", "A", "B", "B", NA), levels = c("A", "B", "C")),
    text = c(
      "  exact text  ",
      NA,
      "",
      "line one\nline two",
      "   ",
      "orphan text"
    ),
    stringsAsFactors = FALSE
  )
}

test_that("textual_evidence preserves every source row and text exactly", {
  dataset <- .textual_test_dataset()
  result <- nail_textual_prep(
    dataset = dataset,
    num.var = 1,
    num.text = 2,
    lexical_analysis = FALSE,
    compute_length_analysis = FALSE,
    generate = FALSE
  )

  evidence <- result$textual_evidence
  expect_s3_class(evidence, "textual_evidence")
  expect_equal(nrow(evidence$verbatims), nrow(dataset))
  expect_identical(evidence$verbatims$original_text, dataset$text)
  expect_identical(evidence$verbatims$row_index, seq_len(nrow(dataset)))
  expect_identical(
    evidence$verbatims$text_status,
    c("non_empty", "missing", "empty", "non_empty", "whitespace", "non_empty")
  )
  expect_identical(
    evidence$verbatims$exclusion_reason,
    c(NA_character_, "missing", "empty", NA_character_, "empty", "invalid_group")
  )
  expect_setequal(names(evidence$groups), c("A", "B", "C"))
  expect_equal(
    evidence$group_diagnostics$n_total[
      evidence$group_diagnostics$group == "C"
    ],
    0L
  )
  expect_false(anyDuplicated(evidence$verbatims$verbatim_id) > 0L)
  expect_true(all(evidence$evidence_registry$source == "text"))
})

test_that("verbatim identifiers are deterministic and escape the separator", {
  dataset <- data.frame(
    group = c("G::roupe", "G::roupe", "caf\u00e9"),
    text = c("same", "same", "quoted \"text\""),
    stringsAsFactors = FALSE
  )

  first <- nail_textual_prep(
    dataset, 1, 2,
    lexical_analysis = FALSE,
    compute_length_analysis = FALSE,
    generate = FALSE
  )$textual_evidence
  second <- nail_textual_prep(
    dataset, 1, 2,
    lexical_analysis = FALSE,
    compute_length_analysis = FALSE,
    generate = FALSE,
    request = "A different interpretation request"
  )$textual_evidence

  expect_identical(first, second)
  expect_true(all(grepl("::verbatim::", first$verbatims$verbatim_id, fixed = TRUE)))
  expect_true(any(grepl("%3A", first$verbatims$verbatim_id, fixed = TRUE)))
  expect_equal(length(unique(first$verbatims$verbatim_id)), 3L)
})

test_that("sampling is deterministic, seed-sensitive, and keeps the complete corpus", {
  dataset <- data.frame(
    group = rep(c("A", "B"), each = 12),
    text = paste("verbatim", seq_len(24)),
    stringsAsFactors = FALSE
  )

  build <- function(seed) {
    nail_textual_prep(
      dataset, 1, 2,
      sample.pct = 0.4,
      seed = seed,
      lexical_analysis = FALSE,
      compute_length_analysis = FALSE,
      generate = FALSE
    )$textual_evidence
  }

  first <- build(11)
  second <- build(11)
  third <- build(29)

  expect_identical(first, second)
  expect_equal(nrow(first$verbatims), 24L)
  expect_false(identical(
    first$verbatims$verbatim_id[first$verbatims$included_in_prompt],
    third$verbatims$verbatim_id[third$verbatims$included_in_prompt]
  ))
  expect_true(all(!is.na(
    first$verbatims$sampling_rank[first$verbatims$text_status == "non_empty"]
  )))
  expect_true(all(
    first$verbatims$exclusion_reason[!first$verbatims$included_in_prompt] %in%
      c("not_sampled", "prompt_budget")
  ))
})

test_that("prompt character budgets are explicit and never delete evidence", {
  dataset <- data.frame(
    group = c("A", "A"),
    text = c("a long first verbatim", "a long second verbatim"),
    stringsAsFactors = FALSE
  )

  result <- nail_textual_prep(
    dataset, 1, 2,
    max_prompt_characters = 1,
    lexical_analysis = FALSE,
    compute_length_analysis = FALSE,
    generate = FALSE
  )

  evidence <- result$textual_evidence
  expect_equal(nrow(evidence$verbatims), 2L)
  expect_false(any(evidence$verbatims$included_in_prompt))
  expect_true(all(evidence$verbatims$exclusion_reason == "prompt_budget"))
  expect_equal(evidence$group_diagnostics$n_prompt_budget, 2L)
})

test_that("textual preparation does not modify the global random state", {
  dataset <- data.frame(
    group = rep("A", 8),
    text = paste("text", seq_len(8)),
    stringsAsFactors = FALSE
  )

  set.seed(123)
  before <- .Random.seed
  nail_textual_prep(
    dataset, 1, 2,
    sample.pct = 0.5,
    seed = 999,
    lexical_analysis = FALSE,
    compute_length_analysis = FALSE,
    generate = FALSE
  )
  after <- .Random.seed

  expect_identical(after, before)
})

test_that("offline prompts include only selected evidence and separate context", {
  dataset <- data.frame(
    group = rep("A", 4),
    text = c("alpha statement", "beta statement", "gamma statement", "delta statement"),
    stringsAsFactors = FALSE
  )

  result <- nail_textual_prep(
    dataset, 1, 2,
    sample.pct = 0.5,
    seed = 7,
    lexical_analysis = FALSE,
    compute_length_analysis = FALSE,
    request = "Focus on practical barriers.",
    context = list(study = "External study context"),
    analysis_scope = "consumer",
    generate = FALSE
  )

  prompt <- result$prompt$A
  evidence <- result$textual_evidence$verbatims
  included <- evidence[evidence$included_in_prompt, , drop = FALSE]
  excluded <- evidence[!evidence$included_in_prompt, , drop = FALSE]

  expect_true(all(vapply(included$verbatim_id, grepl, logical(1), x = prompt, fixed = TRUE)))
  expect_true(all(vapply(included$original_text, grepl, logical(1), x = prompt, fixed = TRUE)))
  expect_false(any(vapply(excluded$original_text, grepl, logical(1), x = prompt, fixed = TRUE)))
  expect_match(prompt, "# TEXTUAL EVIDENCE", fixed = TRUE)
  expect_match(prompt, "# USER-PROVIDED CONTEXT", fixed = TRUE)
  expect_match(prompt, "External study context", fixed = TRUE)
  expect_match(prompt, "Focus on practical barriers", fixed = TRUE)
  expect_false(grepl("# OUTPUT SCHEMA", prompt, fixed = TRUE))
  expect_true(is.list(result$units$A$schema))
  expect_identical(result$units$A$schema$type, "object")
  expect_match(prompt, "machine schema", ignore.case = TRUE)
  expect_match(prompt, "consumer", ignore.case = TRUE)
})

test_that("joint and isolated modes create the requested generation units only", {
  dataset <- data.frame(
    group = c("A", "A", "B", "B"),
    text = c("A first", "A second", "B first", "B second"),
    stringsAsFactors = FALSE
  )

  isolated <- nail_textual_prep(
    dataset, 1, 2,
    comparison_mode = "isolated",
    lexical_analysis = FALSE,
    compute_length_analysis = FALSE,
    generate = FALSE
  )
  joint <- nail_textual_prep(
    dataset, 1, 2,
    comparison_mode = "joint",
    lexical_analysis = FALSE,
    compute_length_analysis = FALSE,
    generate = FALSE
  )

  expect_setequal(names(isolated$units), c("A", "B"))
  expect_identical(names(joint$units), "joint")
  expect_match(joint$prompt, '"A"', fixed = TRUE)
  expect_match(joint$prompt, '"B"', fixed = TRUE)
  expect_false(grepl('"B"', isolated$prompt$A, fixed = TRUE))
  expect_identical(isolated$textual_evidence, joint$textual_evidence)
})

test_that("analysis scopes and requests change prompts but not textual evidence", {
  dataset <- data.frame(
    group = c("A", "A"),
    text = c("one", "two"),
    stringsAsFactors = FALSE
  )

  general <- nail_textual_prep(
    dataset, 1, 2,
    analysis_scope = "general",
    lexical_analysis = FALSE,
    compute_length_analysis = FALSE,
    generate = FALSE
  )
  sociological <- nail_textual_prep(
    dataset, 1, 2,
    analysis_scope = "sociological",
    request = "Read the relation to institutions.",
    context = list(setting = "A public service"),
    provider = "gemini",
    model = "another-model",
    prompt_style = "compact",
    lexical_analysis = FALSE,
    compute_length_analysis = FALSE,
    generate = FALSE
  )

  expect_identical(general$textual_evidence, sociological$textual_evidence)
  expect_false(identical(general$prompt, sociological$prompt))
  expect_match(sociological$prompt$A, "sociological", ignore.case = TRUE)
})

test_that("generate FALSE never calls an LLM backend", {
  testthat::local_mocked_bindings(
    .nail_structured_dispatch_call = function(...) stop("LLM backend was called"),
    .package = "NaileR"
  )

  result <- nail_textual_prep(
    data.frame(group = "A", text = "hello"),
    1, 2,
    lexical_analysis = FALSE,
    compute_length_analysis = FALSE,
    generate = FALSE
  )

  expect_identical(result$parsed$parse_status, "not_generated")
  expect_null(result$response)
  expect_null(result$textual_profiles)
})

test_that("offline textual units expose the reduced machine schema", {
  prep <- nail_textual_prep(
    data.frame(group = "A", text = "A concise response"),
    1, 2,
    lexical_analysis = FALSE,
    compute_length_analysis = FALSE,
    generate = FALSE
  )

  fields <- names(prep$units$A$schema$properties$groups$properties$A$properties)
  expect_setequal(
    fields,
    c(
      "group",
      "core_textual_profile",
      "main_themes",
      "dominant_concerns",
      "tone_or_stance",
      "internal_variation",
      "minority_positions",
      "representative_verbatims",
      "contrastive_verbatims",
      "interpretation_limits"
    )
  )
  expect_false(any(c(
    "motivations",
    "barriers",
    "perceived_benefits",
    "social_norms",
    "identity_cues",
    "contradictions"
  ) %in% fields))
  group_schema <- prep$units$A$schema$properties$groups$properties$A$properties
  expect_identical(
    group_schema$core_textual_profile$properties$evidence_ids$minItems,
    1L
  )
  expect_identical(
    group_schema$interpretation_limits$items$properties$evidence_ids$minItems,
    0L
  )
  expect_false(grepl("# OUTPUT SCHEMA", prep$units$A$prompt, fixed = TRUE))
})

test_that("valid isolated constrained JSON builds the canonical textual description", {
  dataset <- data.frame(
    group = c("A", "A", "B", "B"),
    text = c(
      "easy to use",
      "simple and reliable",
      "works well",
      "practical but basic"
    ),
    stringsAsFactors = FALSE
  )
  offline <- nail_textual_prep(
    dataset, 1, 2,
    lexical_analysis = FALSE,
    compute_length_analysis = FALSE,
    generate = FALSE
  )
  calls <- 0L
  llm_call <- function(prompt, schema, provider, model, unit_type, unit_data) {
    calls <<- calls + 1L
    .textual_test_response(
      offline$textual_evidence,
      names(unit_data$groups)
    )
  }

  result <- nail_textual_prep(
    dataset, 1, 2,
    lexical_analysis = FALSE,
    compute_length_analysis = FALSE,
    generate = TRUE,
    .llm_call = llm_call
  )

  expect_equal(calls, 2L)
  expect_identical(result$parsed$parse_status, "success")
  expect_s3_class(result$textual_description, "textual_description")
  expect_setequal(names(result$textual_description$groups), c("A", "B"))
  expect_true(nrow(result$textual_description$claim_registry) > 0L)
  expect_true(all(grepl(
    "^text::",
    result$textual_description$claim_registry$claim_id
  )))
  expect_identical(
    result$textual_description$groups$A$representative_verbatims[[1]]$quotation,
    "easy to use"
  )
  expect_identical(
    result$legacy_groups$A$parsed$core_textual_profile,
    result$textual_description$groups$A$core_textual_profile$text
  )
  expect_s3_class(result, "nail_textual_prep")
})

test_that("joint mode uses constrained batching but defers cross-group analysis", {
  dataset <- data.frame(
    group = c("A", "B"),
    text = c("easy and direct", "careful and detailed"),
    stringsAsFactors = FALSE
  )
  offline <- nail_textual_prep(
    dataset, 1, 2,
    comparison_mode = "joint",
    lexical_analysis = FALSE,
    compute_length_analysis = FALSE,
    generate = FALSE
  )
  calls <- 0L
  llm_call <- function(prompt, schema, provider, model, unit_type, unit_data) {
    calls <<- calls + 1L
    .textual_test_response(
      offline$textual_evidence,
      names(unit_data$groups)
    )
  }

  result <- nail_textual_prep(
    dataset, 1, 2,
    comparison_mode = "joint",
    lexical_analysis = FALSE,
    compute_length_analysis = FALSE,
    generate = TRUE,
    .llm_call = llm_call
  )

  expect_identical(calls, 1L)
  expect_identical(result$parsed$parse_status, "success")
  expect_null(result$textual_description$cross_group)
  expect_true(result$textual_description$metadata$cross_group_deferred)
  expect_length(result$textual_profiles$cross_group$group_contrasts, 0L)
})

test_that("the machine schema and strict validator reject invalid textual outputs", {
  dataset <- data.frame(
    group = "A",
    text = "exact quotation",
    stringsAsFactors = FALSE
  )
  offline <- nail_textual_prep(
    dataset, 1, 2,
    lexical_analysis = FALSE,
    compute_length_analysis = FALSE,
    generate = FALSE
  )
  evidence <- offline$textual_evidence
  unit_data <- offline$units$A$unit_data
  valid <- jsonlite::fromJSON(
    .textual_test_response(evidence, "A"),
    simplifyVector = FALSE
  )

  invalid_json <- NaileR:::.nail_text_parse_unit_response(
    "not JSON",
    unit_data = unit_data,
    registry = evidence$evidence_registry,
    context = list()
  )
  expect_identical(invalid_json$parse_status, "error")

  unknown_field <- valid
  unknown_field$groups$A$unexpected <- "x"
  parsed <- NaileR:::.nail_text_parse_unit_response(
    jsonlite::toJSON(unknown_field, auto_unbox = TRUE, null = "null"),
    unit_data,
    evidence$evidence_registry,
    list()
  )
  expect_match(parsed$parse_error, "unexpected", ignore.case = TRUE)

  unknown_status <- valid
  unknown_status$groups$A$core_textual_profile$status <- "certain"
  parsed <- NaileR:::.nail_text_parse_unit_response(
    jsonlite::toJSON(unknown_status, auto_unbox = TRUE, null = "null"),
    unit_data,
    evidence$evidence_registry,
    list()
  )
  expect_match(parsed$parse_error, "expert_interpretation", fixed = TRUE)

  unknown_evidence <- valid
  unknown_evidence$groups$A$core_textual_profile$evidence_ids <-
    list("A::verbatim::999")
  parsed <- NaileR:::.nail_text_parse_unit_response(
    jsonlite::toJSON(unknown_evidence, auto_unbox = TRUE, null = "null"),
    unit_data,
    evidence$evidence_registry,
    list()
  )
  expect_match(parsed$parse_error, "unknown", ignore.case = TRUE)

  non_null_validation <- valid
  non_null_validation$groups$A$core_textual_profile$validation_needed <-
    "More interviews"
  parsed <- NaileR:::.nail_text_parse_unit_response(
    jsonlite::toJSON(non_null_validation, auto_unbox = TRUE, null = "null"),
    unit_data,
    evidence$evidence_registry,
    list()
  )
  expect_match(parsed$parse_error, "must be null", ignore.case = TRUE)
})

test_that("diagnostic numerical limits may use empty textual evidence IDs", {
  dataset <- data.frame(
    group = "A",
    text = "exact quotation",
    stringsAsFactors = FALSE
  )
  offline <- nail_textual_prep(
    dataset, 1, 2,
    lexical_analysis = FALSE,
    compute_length_analysis = FALSE,
    generate = FALSE
  )
  evidence <- offline$textual_evidence
  unit_data <- offline$units$A$unit_data
  valid <- jsonlite::fromJSON(
    .textual_test_response(evidence, "A"),
    simplifyVector = FALSE
  )
  valid$groups$A$interpretation_limits <- list(
    .textual_test_claim(
      text = "Only 1 source row was available for this group.",
      evidence_ids = character(),
      support = "The mechanical diagnostics report 1 total source row."
    )
  )

  parsed <- NaileR:::.nail_text_parse_unit_response(
    jsonlite::toJSON(valid, auto_unbox = TRUE, null = "null"),
    unit_data,
    evidence$evidence_registry,
    list()
  )

  expect_identical(parsed$parse_status, "success")
  expect_length(parsed$groups$A$interpretation_limits, 1L)
  expect_length(
    parsed$groups$A$interpretation_limits[[1L]]$evidence_ids,
    0L
  )
})

test_that("group ownership, exact quotations, and explicit support are enforced", {
  dataset <- data.frame(
    group = c("A", "B"),
    text = c("A quotation", "B quotation"),
    stringsAsFactors = FALSE
  )
  offline <- nail_textual_prep(
    dataset, 1, 2,
    comparison_mode = "joint",
    lexical_analysis = FALSE,
    compute_length_analysis = FALSE,
    generate = FALSE
  )
  evidence <- offline$textual_evidence
  unit_data <- offline$units$joint$unit_data
  valid <- jsonlite::fromJSON(
    .textual_test_response(evidence, c("A", "B")),
    simplifyVector = FALSE
  )

  wrong_group <- valid
  id_b <- evidence$evidence_registry$evidence_id[
    evidence$evidence_registry$group == "B"
  ][[1L]]
  wrong_group$groups$A$core_textual_profile$evidence_ids <- list(id_b)
  parsed <- NaileR:::.nail_text_parse_unit_response(
    jsonlite::toJSON(wrong_group, auto_unbox = TRUE, null = "null"),
    unit_data,
    evidence$evidence_registry,
    list()
  )
  expect_match(parsed$parse_error, "cross-group", ignore.case = TRUE)

  changed_quote <- valid
  changed_quote$groups$A$representative_verbatims[[1]]$quotation <-
    "A corrected quotation"
  parsed <- NaileR:::.nail_text_parse_unit_response(
    jsonlite::toJSON(changed_quote, auto_unbox = TRUE, null = "null"),
    unit_data,
    evidence$evidence_registry,
    list()
  )
  expect_match(parsed$parse_error, "exactly", ignore.case = TRUE)

  empty_support <- valid
  empty_support$groups$A$core_textual_profile$support <- ""
  parsed <- NaileR:::.nail_text_parse_unit_response(
    jsonlite::toJSON(empty_support, auto_unbox = TRUE, null = "null"),
    unit_data,
    evidence$evidence_registry,
    list()
  )
  expect_match(parsed$parse_error, "support", ignore.case = TRUE)
})

test_that("unsupported demographic, diagnostic, and numerical claims are rejected", {
  dataset <- data.frame(
    group = "A",
    text = "I value convenience",
    stringsAsFactors = FALSE
  )
  offline <- nail_textual_prep(
    dataset, 1, 2,
    lexical_analysis = FALSE,
    compute_length_analysis = FALSE,
    generate = FALSE
  )
  evidence <- offline$textual_evidence
  unit_data <- offline$units$A$unit_data
  valid <- jsonlite::fromJSON(
    .textual_test_response(evidence, "A"),
    simplifyVector = FALSE
  )

  demographic <- valid
  demographic$groups$A$core_textual_profile$text <-
    "Women in this group value convenience."
  parsed <- NaileR:::.nail_text_parse_unit_response(
    jsonlite::toJSON(demographic, auto_unbox = TRUE, null = "null"),
    unit_data,
    evidence$evidence_registry,
    list()
  )
  expect_match(parsed$parse_error, "demographic", ignore.case = TRUE)

  diagnostic <- valid
  diagnostic$groups$A$core_textual_profile$text <- "The group is depressed."
  parsed <- NaileR:::.nail_text_parse_unit_response(
    jsonlite::toJSON(diagnostic, auto_unbox = TRUE, null = "null"),
    unit_data,
    evidence$evidence_registry,
    list()
  )
  expect_match(parsed$parse_error, "diagnos", ignore.case = TRUE)

  numeric_claim <- valid
  numeric_claim$groups$A$core_textual_profile$text <-
    "80 percent value convenience."
  parsed <- NaileR:::.nail_text_parse_unit_response(
    jsonlite::toJSON(numeric_claim, auto_unbox = TRUE, null = "null"),
    unit_data,
    evidence$evidence_registry,
    list()
  )
  expect_match(parsed$parse_error, "numerical", ignore.case = TRUE)
})

test_that("sampling limits and cited-support metrics are added mechanically", {
  dataset <- data.frame(
    group = rep("A", 6),
    text = paste("textual contribution", letters[1:6]),
    stringsAsFactors = FALSE
  )
  offline <- nail_textual_prep(
    dataset, 1, 2,
    sample.pct = 0.5,
    seed = 1,
    lexical_analysis = FALSE,
    compute_length_analysis = FALSE,
    generate = FALSE
  )
  llm_call <- function(prompt, schema, provider, model, unit_type, unit_data) {
    .textual_test_response(
      offline$textual_evidence,
      names(unit_data$groups)
    )
  }

  result <- nail_textual_prep(
    dataset, 1, 2,
    sample.pct = 0.5,
    seed = 1,
    lexical_analysis = FALSE,
    compute_length_analysis = FALSE,
    generate = TRUE,
    .llm_call = llm_call
  )

  group <- result$textual_description$groups$A
  limits <- group$interpretation_limits
  expect_true(any(vapply(
    limits,
    function(x) identical(x$status, "user_context"),
    logical(1)
  )))
  expect_true(any(grepl(
    "Only",
    vapply(limits, `[[`, character(1), "text"),
    fixed = TRUE
  )))
  metrics <- group$core_textual_profile$support_metrics
  expect_identical(metrics$cited_support_n, 1L)
  expect_identical(
    metrics$included_verbatim_n,
    result$textual_evidence$group_diagnostics$n_included_in_prompt[[1L]]
  )
})

test_that("groups with no included evidence remain explicit without an LLM call", {
  dataset <- data.frame(group = c("A", "A"), text = c("one", "two"))
  calls <- 0L
  llm_call <- function(...) {
    calls <<- calls + 1L
    stop("LLM backend was called")
  }

  result <- nail_textual_prep(
    dataset, 1, 2,
    sample.pct = 0,
    lexical_analysis = FALSE,
    compute_length_analysis = FALSE,
    generate = TRUE,
    .llm_call = llm_call
  )

  expect_identical(calls, 0L)
  expect_identical(result$parsed$parse_status, "no_evidence")
  expect_null(result$textual_profiles)
  expect_false(any(result$textual_evidence$verbatims$included_in_prompt))
  expect_identical(
    result$textual_description$groups$A$availability,
    "unavailable"
  )
})

test_that("deprecated isolate.groups maps explicitly to comparison_mode", {
  dataset <- data.frame(group = c("A", "B"), text = c("one", "two"))

  result <- NULL
  expect_warning(
    result <- nail_textual_prep(
      dataset, 1, 2,
      isolate.groups = FALSE,
      lexical_analysis = FALSE,
      compute_length_analysis = FALSE,
      generate = FALSE
    ),
    "deprecated"
  )
  expect_identical(result$metadata$comparison_mode, "joint")

  expect_error(
    nail_textual_prep(
      dataset, 1, 2,
      comparison_mode = "joint",
      isolate.groups = TRUE,
      lexical_analysis = FALSE,
      compute_length_analysis = FALSE,
      generate = FALSE
    ),
    "conflicting"
  )
})

test_that("new textual preparation remains consumable by contextualized prompts", {
  dataset <- data.frame(
    group = c("A", "B"),
    text = c("easy to use", "careful evaluation"),
    stringsAsFactors = FALSE
  )
  offline <- nail_textual_prep(
    dataset, 1, 2,
    lexical_analysis = FALSE,
    compute_length_analysis = FALSE,
    generate = FALSE
  )
  calls <- 0L
  llm_call <- function(prompt, schema, provider, model, unit_type, unit_data) {
    calls <<- calls + 1L
    .textual_test_response(
      offline$textual_evidence,
      names(unit_data$groups)
    )
  }

  textual <- nail_textual_prep(
    dataset, 1, 2,
    lexical_analysis = FALSE,
    compute_length_analysis = FALSE,
    generate = TRUE,
    .llm_call = llm_call
  )

  group_profile <- list(
    A = list(parsed = list(
      core_group_profile = "Profile A",
      quantitative_traits = "Trait A",
      categorical_traits = "Category A",
      distinctive_markers = "Marker A",
      injectable_summary = "Summary A"
    )),
    B = list(parsed = list(
      core_group_profile = "Profile B",
      quantitative_traits = "Trait B",
      categorical_traits = "Category B",
      distinctive_markers = "Marker B",
      injectable_summary = "Summary B"
    ))
  )

  result <- nail_textual_contextualized(
    group_profile_prep = group_profile,
    textual_prep = textual,
    comparison_mode = "isolated",
    generate = FALSE
  )

  expect_s3_class(result, "nail_textual_contextualized")
  expect_setequal(names(result$units), c("A", "B"))
  expect_true(all(vapply(result$units, function(x) is.character(x$prompt), logical(1))))
  expect_true(all(vapply(
    result$units,
    function(x) identical(x$prompt_contract, "compatibility_preview"),
    logical(1)
  )))
  expect_true(all(!vapply(
    result$units,
    function(x) isTRUE(x$integration_eligible),
    logical(1)
  )))
  expect_identical(result$metadata$integration_llm_calls, 0L)
})

test_that("invalid inputs fail with explicit messages", {
  expect_error(
    nail_textual_prep(data.frame(group = "A"), 1, 2),
    "valid column index"
  )
  expect_error(
    nail_textual_prep(data.frame(group = "A", text = "x"), 1, 1),
    "different columns"
  )
  expect_error(
    nail_textual_prep(data.frame(group = "A", text = "x"), 1, 2, sample.pct = -1),
    "in \\[0, 1\\]"
  )
  expect_error(
    nail_textual_prep(
      data.frame(group = "A", text = "x"), 1, 2,
      context = list("unnamed"),
      lexical_analysis = FALSE
    ),
    "named list"
  )
})

test_that("joint mode excludes evidence-free groups from the generation unit", {
  dataset <- data.frame(
    group = factor(c("A", "A", "B"), levels = c("A", "B", "C")),
    text = c("usable text", "another text", NA_character_),
    stringsAsFactors = FALSE
  )

  result <- nail_textual_prep(
    dataset, 1, 2,
    comparison_mode = "joint",
    lexical_analysis = FALSE,
    compute_length_analysis = FALSE,
    generate = FALSE
  )

  expect_identical(result$units$joint$groups, "A")
  expect_true("C" %in% names(result$textual_evidence$groups))
  expect_equal(
    result$textual_evidence$groups$C$diagnostics$n_non_empty,
    0L
  )
  expect_false(grepl('"B"\\s*:', result$units$joint$prompt))
  expect_false(grepl('"C"\\s*:', result$units$joint$prompt))
})

test_that("nongenerated new preparation is not treated as semantic output", {
  dataset <- data.frame(
    group = c("A", "B"),
    text = c("text A", "text B"),
    stringsAsFactors = FALSE
  )
  textual <- nail_textual_prep(
    dataset, 1, 2,
    lexical_analysis = FALSE,
    compute_length_analysis = FALSE,
    generate = FALSE
  )
  group_profile <- list(
    A = list(parsed = list(core_group_profile = "Profile A")),
    B = list(parsed = list(core_group_profile = "Profile B"))
  )

  result <- nail_textual_contextualized(
    group_profile_prep = group_profile,
    textual_prep = textual,
    comparison_mode = "isolated",
    generate = FALSE
  )

  expect_s3_class(result, "nail_textual_contextualized")
  expect_null(result$textual_profiles)
  expect_true(all(
    result$contextualized_evidence$group_alignment$alignment_status ==
      "matched_without_textual_profile"
  ))
  expect_identical(result$parsed$parse_status, "not_generated")
})

test_that("number validation accepts rounding and ignores verbatim ID suffixes", {
  source <- paste(
    "group percentage 36.6666667",
    "v.test -4.123456",
    sep = "\n"
  )

  expect_false(
    NaileR:::.textual_prep_claim_has_unsupported_number(
      "The group percentage is 36.67 and the v-test is -4.12.",
      source
    )
  )
  expect_true(
    NaileR:::.textual_prep_claim_has_unsupported_number(
      "The group percentage is 99.99.",
      source
    )
  )
  expect_false(
    NaileR:::.textual_prep_claim_has_unsupported_number(
      paste(
        "The support cites A::verbatim::41,",
        "A::verbatim::42 and A::verbatim::43."
      ),
      "No numerical result is present."
    )
  )
})

test_that("methodological textual limits may name prohibited inference categories", {
  dataset <- data.frame(
    group = "A",
    text = "I value convenience.",
    stringsAsFactors = FALSE
  )
  offline <- nail_textual_prep(
    dataset, 1, 2,
    lexical_analysis = FALSE,
    compute_length_analysis = FALSE,
    generate = FALSE
  )
  evidence <- offline$textual_evidence
  unit_data <- offline$units$A$unit_data
  valid <- jsonlite::fromJSON(
    .textual_test_response(evidence, "A"),
    simplifyVector = FALSE
  )
  valid$groups$A$core_textual_profile$support <- paste(
    "The cited text A::verbatim::1 explicitly supports convenience."
  )
  valid$groups$A$interpretation_limits <- list(
    .textual_test_claim(
      text = paste(
        "The analysis does not infer age, income, social class,",
        "prevalence, or psychological diagnoses."
      ),
      evidence_ids = character(),
      support = "These are explicit methodological exclusions, not group claims."
    )
  )

  parsed <- NaileR:::.nail_text_parse_unit_response(
    jsonlite::toJSON(valid, auto_unbox = TRUE, null = "null"),
    unit_data,
    evidence$evidence_registry,
    list()
  )

  expect_identical(parsed$parse_status, "success")
  expect_length(parsed$groups$A$interpretation_limits, 1L)
})

test_that("textual prompts consolidate themes and reserve concerns for problems", {
  dataset <- data.frame(
    group = c("A", "A"),
    text = c("I value convenience.", "Convenience matters to me."),
    stringsAsFactors = FALSE
  )
  offline <- nail_textual_prep(
    dataset, 1, 2,
    lexical_analysis = FALSE,
    compute_length_analysis = FALSE,
    generate = FALSE
  )
  prompt <- offline$units$A$prompt

  expect_match(prompt, "Consolidate overlapping content", fixed = TRUE)
  expect_match(prompt, "at most three distinct main themes", fixed = TRUE)
  expect_match(prompt, "Use dominant_concerns only", fixed = TRUE)
  expect_match(prompt, "Do not repeat evidence_id strings", fixed = TRUE)
})

test_that("full evidence IDs are removed before textual number checks", {
  registry <- data.frame(
    evidence_id = "Group 2::verbatim::41",
    group = "Group 2",
    original_text = "Convenience matters.",
    stringsAsFactors = FALSE
  )

  expect_silent(
    NaileR:::.textual_prep_validate_claim_safety(
      text = paste(
        "Convenience is explicitly expressed.",
        "Support: Group 2::verbatim::41."
      ),
      evidence_ids = "Group 2::verbatim::41",
      registry = registry,
      context = list()
    )
  )
})

test_that("textual core schema caps themes and concerns at three", {
  dataset <- data.frame(
    group = c("A", "A"),
    text = c("I value convenience.", "Price is sometimes difficult."),
    stringsAsFactors = FALSE
  )
  offline <- nail_textual_prep(
    dataset, 1, 2,
    lexical_analysis = FALSE,
    compute_length_analysis = FALSE,
    generate = FALSE
  )
  schema <- offline$units$A$schema$properties$groups$properties$A$properties

  expect_identical(schema$main_themes$maxItems, 3L)
  expect_identical(schema$dominant_concerns$maxItems, 3L)
  expect_identical(
    schema$interpretation_limits$items$properties$evidence_ids$maxItems,
    0L
  )
  expect_identical(offline$units$A$unit_data$constraints$max_main_themes, 3L)
  expect_identical(
    offline$units$A$unit_data$constraints$max_dominant_concerns,
    3L
  )
  expect_match(
    offline$units$A$prompt,
    "single most appropriate section",
    fixed = TRUE
  )
  expect_match(
    offline$units$A$prompt,
    "isolated worries or conditional reservations",
    fixed = TRUE
  )
})

test_that("textual methodological limits accept self-report and scoped-domain wording", {
  dataset <- data.frame(
    group = "A",
    text = "I value convenience.",
    stringsAsFactors = FALSE
  )
  offline <- nail_textual_prep(
    dataset, 1, 2,
    lexical_analysis = FALSE,
    compute_length_analysis = FALSE,
    generate = FALSE
  )
  evidence <- offline$textual_evidence
  unit_data <- offline$units$A$unit_data

  valid <- jsonlite::fromJSON(
    .textual_test_response(evidence, "A"),
    simplifyVector = FALSE
  )
  valid$groups$A$interpretation_limits <- list(
    .textual_test_claim(
      text = paste(
        "The verbatims are self-reported and may reflect individual",
        "perceptions rather than objective realities."
      ),
      evidence_ids = character(),
      support = paste(
        "The comments describe personal experiences and may differ from",
        "independently observed conditions."
      )
    ),
    .textual_test_claim(
      text = paste(
        "The analysis is based on a specific set of food comments and may",
        "not fully capture broader interests or behaviors of group members."
      ),
      evidence_ids = character(),
      support = paste(
        "The verbatims are focused on one particular context and may have",
        "limited generalizability to other domains."
      )
    )
  )

  parsed <- NaileR:::.nail_text_parse_unit_response(
    jsonlite::toJSON(valid, auto_unbox = TRUE, null = "null"),
    unit_data,
    evidence$evidence_registry,
    list()
  )

  expect_identical(parsed$parse_status, "success")
  expect_length(parsed$groups$A$interpretation_limits, 2L)
})

test_that("textual methodological limits still reject substantive support", {
  dataset <- data.frame(
    group = "A",
    text = "I value convenience.",
    stringsAsFactors = FALSE
  )
  offline <- nail_textual_prep(
    dataset, 1, 2,
    lexical_analysis = FALSE,
    compute_length_analysis = FALSE,
    generate = FALSE
  )
  evidence <- offline$textual_evidence
  unit_data <- offline$units$A$unit_data
  valid <- jsonlite::fromJSON(
    .textual_test_response(evidence, "A"),
    simplifyVector = FALSE
  )
  valid$groups$A$interpretation_limits <- list(
    .textual_test_claim(
      text = "The analysis is limited to this sample.",
      evidence_ids = character(),
      support = "The group appears rigid and prefers convenience."
    )
  )

  parsed <- NaileR:::.nail_text_parse_unit_response(
    jsonlite::toJSON(valid, auto_unbox = TRUE, null = "null"),
    unit_data,
    evidence$evidence_registry,
    list()
  )

  expect_identical(parsed$parse_status, "error")
  expect_match(
    parsed$parse_error,
    "must not introduce a new substantive description",
    fixed = TRUE
  )
})

test_that("textual interpretation limits reject substantive profile claims", {
  dataset <- data.frame(
    group = "A",
    text = "I value convenience.",
    stringsAsFactors = FALSE
  )
  offline <- nail_textual_prep(
    dataset, 1, 2,
    lexical_analysis = FALSE,
    compute_length_analysis = FALSE,
    generate = FALSE
  )
  evidence <- offline$textual_evidence
  unit_data <- offline$units$A$unit_data
  valid <- jsonlite::fromJSON(
    .textual_test_response(evidence, "A"),
    simplifyVector = FALSE
  )
  valid$groups$A$interpretation_limits <- list(
    .textual_test_claim(
      text = paste(
        "The group appears more rigid and less flexible,",
        "which defines a pragmatic profile."
      ),
      evidence_ids = character(),
      support = "This is a substantive profile statement, not a limitation."
    )
  )

  parsed <- NaileR:::.nail_text_parse_unit_response(
    jsonlite::toJSON(valid, auto_unbox = TRUE, null = "null"),
    unit_data,
    evidence$evidence_registry,
    list()
  )

  expect_identical(parsed$parse_status, "error")
  expect_match(
    parsed$parse_error,
    "must not introduce a new substantive description",
    fixed = TRUE
  )
})

test_that("textual interpretation limits reject cited verbatim evidence", {
  dataset <- data.frame(
    group = "A",
    text = "I value convenience.",
    stringsAsFactors = FALSE
  )
  offline <- nail_textual_prep(
    dataset, 1, 2,
    lexical_analysis = FALSE,
    compute_length_analysis = FALSE,
    generate = FALSE
  )
  evidence <- offline$textual_evidence
  unit_data <- offline$units$A$unit_data
  valid <- jsonlite::fromJSON(
    .textual_test_response(evidence, "A"),
    simplifyVector = FALSE
  )
  evidence_id <- unit_data$groups$A$allowed_evidence_ids[[1L]]
  valid$groups$A$interpretation_limits <- list(
    .textual_test_claim(
      text = "The analysis cannot establish prevalence from this small corpus.",
      evidence_ids = evidence_id,
      support = "A verbatim was cited even though the statement is methodological."
    )
  )

  parsed <- NaileR:::.nail_text_parse_unit_response(
    jsonlite::toJSON(valid, auto_unbox = TRUE, null = "null"),
    unit_data,
    evidence$evidence_registry,
    list()
  )

  expect_identical(parsed$parse_status, "error")
  expect_match(parsed$parse_error, "empty evidence_ids array", fixed = TRUE)
})
