.textual_test_claim <- function(text,
                                evidence_ids,
                                status = "expert_interpretation",
                                validation_needed = NULL) {
  list(
    text = text,
    status = status,
    evidence_ids = as.list(evidence_ids),
    validation_needed = validation_needed
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
      .textual_test_claim("Practical considerations structure the discourse.", evidence_id)
    ),
    dominant_concerns = list(
      .textual_test_claim("Ease of use is explicitly valued.", evidence_id)
    ),
    tone_or_stance = .textual_test_claim("The stance is pragmatic.", evidence_id),
    narrative_frames = list(),
    motivations = list(),
    barriers = list(),
    perceived_benefits = list(),
    social_norms = list(),
    identity_cues = list(),
    contradictions = list(),
    minority_positions = list(),
    representative_verbatims = list(
      list(
        evidence_id = evidence_id,
        quotation = quotation,
        rationale = "This verbatim directly expresses the central practical theme.",
        status = "expert_interpretation"
      )
    ),
    tension_verbatims = list(),
    intra_group_consistency = .textual_test_claim(
      "The available verbatim supports the same practical reading.",
      evidence_id
    ),
    interpretation_limits = list()
  )
}

.textual_test_response <- function(evidence, groups, comparison_mode = "isolated") {
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

  cross_group <- list(
    shared_themes = list(),
    group_contrasts = list(),
    minority_patterns = list(),
    interpretation_limits = list()
  )

  if (comparison_mode == "joint" && length(groups) > 1L) {
    ids <- vapply(groups, function(group) {
      evidence$evidence_registry$evidence_id[
        evidence$evidence_registry$group == group &
          evidence$evidence_registry$included_in_prompt
      ][[1]]
    }, character(1))

    cross_group$group_contrasts <- list(
      .textual_test_claim(
        "The groups express distinct practical emphases.",
        ids
      )
    )
  }

  jsonlite::toJSON(
    list(groups = profiles, cross_group = cross_group),
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
  expect_match(prompt, "# OUTPUT SCHEMA", fixed = TRUE)
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
  expect_match(sociological$prompt$A, "social norms", ignore.case = TRUE)
})

test_that("generate FALSE never calls an LLM backend", {
  testthat::local_mocked_bindings(
    .call_llm_base = function(...) stop("LLM backend was called"),
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

test_that("valid isolated JSON is parsed and combined into textual_profiles", {
  dataset <- data.frame(
    group = c("A", "A", "B", "B"),
    text = c("easy to use", "simple and reliable", "works well", "practical but basic"),
    stringsAsFactors = FALSE
  )
  offline <- nail_textual_prep(
    dataset, 1, 2,
    lexical_analysis = FALSE,
    compute_length_analysis = FALSE,
    generate = FALSE
  )
  responses <- list(
    A = .textual_test_response(offline$textual_evidence, "A", "isolated"),
    B = .textual_test_response(offline$textual_evidence, "B", "isolated")
  )
  calls <- new.env(parent = emptyenv())
  calls$n <- 0L

  testthat::local_mocked_bindings(
    .call_llm_base = function(...) {
      calls$n <- calls$n + 1L
      data.frame(response = as.character(responses[[calls$n]]), stringsAsFactors = FALSE)
    },
    .package = "NaileR"
  )

  result <- nail_textual_prep(
    dataset, 1, 2,
    lexical_analysis = FALSE,
    compute_length_analysis = FALSE,
    generate = TRUE
  )

  expect_equal(calls$n, 2L)
  expect_identical(result$parsed$parse_status, "success")
  expect_setequal(names(result$textual_profiles$groups), c("A", "B"))
  expect_identical(
    result$textual_profiles$groups$A$representative_verbatims[[1]]$quotation,
    "easy to use"
  )
  expect_identical(
    result$legacy_groups$A$parsed$core_textual_profile,
    result$textual_profiles$groups$A$core_textual_profile$text
  )
  expect_s3_class(result, "nail_textual_prep")
})

test_that("valid joint JSON supports traceable cross-group interpretations", {
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
  response <- .textual_test_response(
    offline$textual_evidence,
    c("A", "B"),
    "joint"
  )

  testthat::local_mocked_bindings(
    .call_llm_base = function(...) {
      data.frame(response = as.character(response), stringsAsFactors = FALSE)
    },
    .package = "NaileR"
  )

  result <- nail_textual_prep(
    dataset, 1, 2,
    comparison_mode = "joint",
    lexical_analysis = FALSE,
    compute_length_analysis = FALSE,
    generate = TRUE
  )

  expect_identical(result$parsed$parse_status, "success")
  expect_length(result$textual_profiles$cross_group$group_contrasts, 1L)
  expect_length(
    result$textual_profiles$cross_group$group_contrasts[[1]]$evidence_ids,
    2L
  )
})

test_that("strict parser rejects invalid JSON, fields, statuses, and evidence", {
  dataset <- data.frame(group = "A", text = "exact quotation", stringsAsFactors = FALSE)
  offline <- nail_textual_prep(
    dataset, 1, 2,
    lexical_analysis = FALSE,
    compute_length_analysis = FALSE,
    generate = FALSE
  )
  evidence <- offline$textual_evidence
  valid <- jsonlite::fromJSON(
    .textual_test_response(evidence, "A", "isolated"),
    simplifyDataFrame = FALSE
  )

  invalid_json <- NaileR:::.parse_textual_prep_response(
    "not JSON",
    expected_groups = "A",
    textual_evidence = evidence,
    context = list(),
    analysis_scope = "general",
    comparison_mode = "isolated"
  )
  expect_identical(invalid_json$parse_status, "error")

  unknown_field <- valid
  unknown_field$groups$A$unexpected <- "x"
  parsed <- NaileR:::.parse_textual_prep_response(
    jsonlite::toJSON(unknown_field, auto_unbox = TRUE, null = "null"),
    "A", evidence, list(), "general", "isolated"
  )
  expect_match(parsed$parse_error, "unexpected", ignore.case = TRUE)

  unknown_status <- valid
  unknown_status$groups$A$core_textual_profile$status <- "certain"
  parsed <- NaileR:::.parse_textual_prep_response(
    jsonlite::toJSON(unknown_status, auto_unbox = TRUE, null = "null"),
    "A", evidence, list(), "general", "isolated"
  )
  expect_match(parsed$parse_error, "must be one of", ignore.case = TRUE)

  unknown_evidence <- valid
  unknown_evidence$groups$A$core_textual_profile$evidence_ids <- list("A::verbatim::999")
  parsed <- NaileR:::.parse_textual_prep_response(
    jsonlite::toJSON(unknown_evidence, auto_unbox = TRUE, null = "null"),
    "A", evidence, list(), "general", "isolated"
  )
  expect_match(parsed$parse_error, "unknown or non-presented", ignore.case = TRUE)
})

test_that("group ownership, exact quotations, and validation needs are enforced", {
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
  valid <- jsonlite::fromJSON(
    .textual_test_response(evidence, c("A", "B"), "joint"),
    simplifyDataFrame = FALSE
  )

  wrong_group <- valid
  id_b <- evidence$evidence_registry$evidence_id[evidence$evidence_registry$group == "B"][[1]]
  wrong_group$groups$A$core_textual_profile$evidence_ids <- list(id_b)
  parsed <- NaileR:::.parse_textual_prep_response(
    jsonlite::toJSON(wrong_group, auto_unbox = TRUE, null = "null"),
    c("A", "B"), evidence, list(), "general", "joint"
  )
  expect_match(parsed$parse_error, "another group", ignore.case = TRUE)

  changed_quote <- valid
  changed_quote$groups$A$representative_verbatims[[1]]$quotation <- "A corrected quotation"
  parsed <- NaileR:::.parse_textual_prep_response(
    jsonlite::toJSON(changed_quote, auto_unbox = TRUE, null = "null"),
    c("A", "B"), evidence, list(), "general", "joint"
  )
  expect_match(parsed$parse_error, "exactly match", ignore.case = TRUE)

  no_validation <- valid
  id_a <- evidence$evidence_registry$evidence_id[evidence$evidence_registry$group == "A"][[1]]
  no_validation$groups$A$contradictions <- list(
    .textual_test_claim(
      "The discourse may contain an unresolved tension.",
      id_a,
      status = "hypothesis",
      validation_needed = NULL
    )
  )
  parsed <- NaileR:::.parse_textual_prep_response(
    jsonlite::toJSON(no_validation, auto_unbox = TRUE, null = "null"),
    c("A", "B"), evidence, list(), "general", "joint"
  )
  expect_match(parsed$parse_error, "requires validation_needed", ignore.case = TRUE)
})

test_that("unsupported demographic, diagnostic, and numerical claims are rejected", {
  dataset <- data.frame(group = "A", text = "I value convenience", stringsAsFactors = FALSE)
  offline <- nail_textual_prep(
    dataset, 1, 2,
    lexical_analysis = FALSE,
    compute_length_analysis = FALSE,
    generate = FALSE
  )
  evidence <- offline$textual_evidence
  valid <- jsonlite::fromJSON(
    .textual_test_response(evidence, "A", "isolated"),
    simplifyDataFrame = FALSE
  )

  demographic <- valid
  demographic$groups$A$core_textual_profile$text <- "Women in this group value convenience."
  parsed <- NaileR:::.parse_textual_prep_response(
    jsonlite::toJSON(demographic, auto_unbox = TRUE, null = "null"),
    "A", evidence, list(), "general", "isolated"
  )
  expect_match(parsed$parse_error, "demographic", ignore.case = TRUE)

  diagnostic <- valid
  diagnostic$groups$A$core_textual_profile$text <- "The group is depressed."
  parsed <- NaileR:::.parse_textual_prep_response(
    jsonlite::toJSON(diagnostic, auto_unbox = TRUE, null = "null"),
    "A", evidence, list(), "psychological", "isolated"
  )
  expect_match(parsed$parse_error, "diagnos", ignore.case = TRUE)

  numeric_claim <- valid
  numeric_claim$groups$A$core_textual_profile$text <- "80 percent value convenience."
  parsed <- NaileR:::.parse_textual_prep_response(
    jsonlite::toJSON(numeric_claim, auto_unbox = TRUE, null = "null"),
    "A", evidence, list(), "consumer", "isolated"
  )
  expect_match(parsed$parse_error, "numerical", ignore.case = TRUE)
})

test_that("sampling limitations are attached mechanically after successful parsing", {
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
  response <- .textual_test_response(offline$textual_evidence, "A", "isolated")

  testthat::local_mocked_bindings(
    .call_llm_base = function(...) {
      data.frame(response = as.character(response), stringsAsFactors = FALSE)
    },
    .package = "NaileR"
  )

  result <- nail_textual_prep(
    dataset, 1, 2,
    sample.pct = 0.5,
    seed = 1,
    lexical_analysis = FALSE,
    compute_length_analysis = FALSE,
    generate = TRUE
  )

  limits <- result$textual_profiles$groups$A$interpretation_limits
  expect_true(any(vapply(limits, function(x) x$status == "user_context", logical(1))))
  expect_true(any(grepl("Only", vapply(limits, `[[`, character(1), "text"), fixed = TRUE)))
})

test_that("groups with no included evidence remain explicit without an LLM call", {
  dataset <- data.frame(group = c("A", "A"), text = c("one", "two"))
  testthat::local_mocked_bindings(
    .call_llm_base = function(...) stop("LLM backend was called"),
    .package = "NaileR"
  )

  result <- nail_textual_prep(
    dataset, 1, 2,
    sample.pct = 0,
    lexical_analysis = FALSE,
    compute_length_analysis = FALSE,
    generate = TRUE
  )

  expect_identical(result$parsed$parse_status, "no_evidence")
  expect_null(result$textual_profiles)
  expect_false(any(result$textual_evidence$verbatims$included_in_prompt))
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
  responses <- list(
    A = .textual_test_response(offline$textual_evidence, "A", "isolated"),
    B = .textual_test_response(offline$textual_evidence, "B", "isolated")
  )
  calls <- new.env(parent = emptyenv())
  calls$n <- 0L

  testthat::local_mocked_bindings(
    .call_llm_base = function(...) {
      calls$n <- calls$n + 1L
      data.frame(response = as.character(responses[[calls$n]]), stringsAsFactors = FALSE)
    },
    .package = "NaileR"
  )

  textual <- nail_textual_prep(
    dataset, 1, 2,
    lexical_analysis = FALSE,
    compute_length_analysis = FALSE,
    generate = TRUE
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
