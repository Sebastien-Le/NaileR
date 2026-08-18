.textual_test_data <- function() {
  data.frame(
    group = factor(c("A", "A", "B", "B"), levels = c("A", "B")),
    text = c(
      "Fresh and easy to eat.",
      "Light and floral.\nEasy to share.",
      "Dark and intense.",
      "Strong cocoa character."
    ),
    stringsAsFactors = FALSE
  )
}

.textual_test_claim <- function(text, evidence_id) {
  list(
    text = text,
    status = "expert_interpretation",
    evidence_ids = as.list(evidence_id),
    support = "The cited verbatim explicitly supports this interpretation.",
    validation_needed = NULL
  )
}

.textual_test_group_profile <- function(prep, group_name) {
  registry <- prep$textual_evidence$evidence_registry
  row <- registry[
    registry$group == group_name & registry$included_in_prompt,
    ,
    drop = FALSE
  ][1L, , drop = FALSE]
  id <- row$evidence_id[[1L]]
  quotation <- row$original_text[[1L]]

  list(
    group = group_name,
    core_textual_profile = .textual_test_claim(
      paste0("Group ", group_name, " emphasizes an expressed experience."),
      id
    ),
    main_themes = list(
      .textual_test_claim("A recurring sensory theme is expressed.", id)
    ),
    dominant_concerns = list(
      .textual_test_claim("Practical experience is foregrounded.", id)
    ),
    tone_or_stance = .textual_test_claim(
      "The expressed tone is descriptive.",
      id
    ),
    internal_variation = list(),
    minority_positions = list(),
    representative_verbatims = list(list(
      evidence_id = id,
      quotation = quotation,
      rationale = "This exact verbatim illustrates the central expressed pattern.",
      status = "expert_interpretation"
    )),
    contrastive_verbatims = list(),
    interpretation_limits = list()
  )
}

.textual_test_json_for_unit <- function(prep, unit_data) {
  groups <- names(unit_data$groups)
  group_profiles <- stats::setNames(lapply(groups, function(group_name) {
    .textual_test_group_profile(prep, group_name)
  }), groups)
  jsonlite::toJSON(
    list(groups = group_profiles),
    auto_unbox = TRUE,
    null = "null"
  )
}

.textual_test_preparation <- function(comparison_mode = "isolated",
                                      generated = TRUE,
                                      mixed_error = FALSE) {
  prep <- nail_textual_prep(
    .textual_test_data(), 1, 2,
    comparison_mode = comparison_mode,
    sample.pct = 1,
    seed = 17,
    lexical_analysis = FALSE,
    compute_length_analysis = FALSE,
    generate = FALSE
  )

  if (!generated) return(prep)

  llm_call <- function(prompt, schema, provider, model, unit_type, unit_data) {
    groups <- names(unit_data$groups)
    if (isTRUE(mixed_error) && identical(groups, "B")) {
      stop("Invalid JSON for group B.")
    }
    .textual_test_json_for_unit(prep, unit_data)
  }

  completed <- NaileR:::.nail_text_complete_preparation(
    preparation = prep,
    provider = "ollama",
    model = "test-model",
    llm_api_options = list(.llm_call = llm_call)
  )
  completed$preparation
}

test_that("a validated preparation is reused without another LLM call", {
  prep <- .textual_test_preparation(generated = TRUE)
  testthat::local_mocked_bindings(
    .nail_structured_dispatch_call = function(...) stop("LLM backend was called"),
    .package = "NaileR"
  )

  result <- nail_textual(x = prep, generate = TRUE)

  expect_s3_class(result, "nail_textual")
  expect_identical(result$textual_evidence, prep$textual_evidence)
  expect_identical(result$textual_profiles, prep$textual_profiles)
  expect_identical(result$metadata$preparation_calls, 0L)
  expect_identical(result$metadata$llm_calls, 0L)
  expect_false(result$metadata$generated_in_this_call)
})

test_that("raw input delegates exactly once to nail_textual_prep", {
  fixture <- .textual_test_preparation(generated = TRUE)
  calls <- 0L
  testthat::local_mocked_bindings(
    nail_textual_prep = function(...) {
      calls <<- calls + 1L
      fixture
    },
    .package = "NaileR"
  )

  result <- nail_textual(
    dataset = .textual_test_data(),
    num.var = 1,
    num.text = 2,
    generate = TRUE
  )

  expect_identical(calls, 1L)
  expect_identical(result$metadata$preparation_calls, 1L)
  expect_identical(result$preparation, fixture)
  expect_identical(result$textual_evidence, fixture$textual_evidence)
})

test_that("raw offline input remains mechanical and network-free", {
  testthat::local_mocked_bindings(
    .nail_structured_dispatch_call = function(...) stop("LLM backend was called"),
    .package = "NaileR"
  )

  result <- nail_textual(
    dataset = .textual_test_data(),
    num.var = 1,
    num.text = 2,
    generate = FALSE,
    lexical_analysis = FALSE,
    compute_length_analysis = FALSE
  )

  expect_identical(result$metadata$semantic_status, "not_generated")
  expect_identical(result$metadata$report_status, "mechanical_only")
  expect_null(result$textual_profiles)
  expect_s3_class(result$textual_evidence, "textual_evidence")
  expect_true(all(vapply(result$preparation$units, function(x) is.character(x$prompt), logical(1))))
  expect_identical(result$metadata$llm_calls, 0L)
})

test_that("offline preparations can be completed from existing units", {
  prep <- .textual_test_preparation(comparison_mode = "joint", generated = FALSE)
  evidence_before <- prep$textual_evidence
  prompts_before <- lapply(prep$units, `[[`, "prompt")
  calls <- 0L

  llm_call <- function(prompt, schema, provider, model, unit_type, unit_data) {
    calls <<- calls + 1L
    .textual_test_json_for_unit(prep, unit_data)
  }

  result <- nail_textual(
    x = prep,
    generate = TRUE,
    .llm_call = llm_call
  )

  expect_identical(calls, 1L)
  expect_identical(result$metadata$llm_calls, 1L)
  expect_identical(result$textual_evidence, evidence_before)
  expect_identical(lapply(result$preparation$units, `[[`, "prompt"), prompts_before)
  expect_identical(result$preparation$parsed$parse_status, "success")
  expect_true(is.list(result$textual_profiles$groups))
})

test_that("nail_textual exposes the canonical contract and compatibility views", {
  prep <- .textual_test_preparation(generated = TRUE)
  result <- nail_textual(x = prep, report_format = "structured")

  expect_s3_class(result$textual_description, "textual_description")
  expect_identical(
    result$textual_description,
    result$preparation$textual_description
  )
  expect_true(is.data.frame(result$validation$claim_registry))
  expect_true(result$generation$llm_calls >= 1L)
  expect_identical(
    attr(result, "textual_description"),
    result$textual_description
  )
  expect_true(is.list(result$textual_profiles$groups))
  expect_true(is.list(result$legacy_output))
})

test_that("report formats never modify evidence or profiles", {
  prep <- .textual_test_preparation(comparison_mode = "joint", generated = TRUE)

  structured <- nail_textual(x = prep, report_format = "structured")
  markdown <- nail_textual(x = prep, report_format = "markdown")
  compact <- nail_textual(x = prep, report_format = "compact")

  expect_identical(structured$textual_evidence, markdown$textual_evidence)
  expect_identical(structured$textual_evidence, compact$textual_evidence)
  expect_identical(structured$textual_profiles, markdown$textual_profiles)
  expect_identical(structured$textual_profiles, compact$textual_profiles)
  expect_type(structured$report, "list")
  expect_type(markdown$report, "character")
  expect_type(compact$report, "character")
  expect_match(markdown$report, "Textual analysis report", fixed = TRUE)
  expect_match(compact$report, "Compact textual report", fixed = TRUE)
})

test_that("structured reports preserve statuses, evidence and exact quotations", {
  prep <- .textual_test_preparation(generated = TRUE)
  result <- nail_textual(x = prep, report_format = "structured")
  group_a <- result$group_reports$A
  quote <- group_a$verbatim_evidence$representative[[1]]
  registry <- prep$textual_evidence$evidence_registry
  source_text <- registry$original_text[match(quote$evidence_id, registry$evidence_id)]

  expect_identical(group_a$central_profile$status, "expert_interpretation")
  expect_true(length(group_a$central_profile$evidence_ids) > 0L)
  expect_identical(quote$quotation, source_text)
  expect_true(is.data.frame(group_a$diagnostics))
})

test_that("cross-group interpretation is deferred in both batching modes", {
  joint <- nail_textual(x = .textual_test_preparation("joint", TRUE))
  isolated <- nail_textual(x = .textual_test_preparation("isolated", TRUE))

  expect_identical(joint$cross_group_report$availability, "unavailable")
  expect_identical(isolated$cross_group_report$availability, "unavailable")
  expect_true(joint$textual_description$metadata$cross_group_deferred)
  expect_true(isolated$textual_description$metadata$cross_group_deferred)
  expect_length(joint$textual_profiles$cross_group$group_contrasts, 0L)
})

test_that("partial parsing keeps valid groups and flags unavailable groups", {
  prep <- .textual_test_preparation("isolated", TRUE, mixed_error = TRUE)
  result <- nail_textual(x = prep)

  expect_identical(result$metadata$report_status, "partial")
  expect_identical(result$metadata$profile_source, "validated_textual_profiles")
  expect_identical(result$group_reports$A$availability, "available")
  expect_identical(result$group_reports$B$availability, "unavailable")
  expect_true(any(grepl(
    "Invalid JSON for group B",
    vapply(result$group_reports$B$interpretation_limits, `[[`, character(1), "text"),
    fixed = TRUE
  )))
  expect_s3_class(result$textual_description, "textual_description")
  expect_true(is.list(result$textual_profiles$groups))
})

test_that("methodological limits are derived from diagnostics", {
  data <- data.frame(
    group = factor(c("A", "A", "B")),
    text = c("one", "two", "three"),
    stringsAsFactors = FALSE
  )
  prep <- nail_textual_prep(
    data, 1, 2,
    sample.pct = 0.5,
    seed = 7,
    lexical_analysis = FALSE,
    compute_length_analysis = FALSE,
    generate = FALSE
  )
  result <- nail_textual(x = prep, generate = FALSE)
  texts <- unlist(lapply(result$group_reports, function(report) {
    vapply(report$interpretation_limits, `[[`, character(1), "text")
  }))

  expect_true(any(grepl("were included", texts, fixed = TRUE)))
  expect_identical(result$metadata$report_status, "mechanical_only")
})

test_that("prepared analysis scope and comparison mode are authoritative", {
  prep <- .textual_test_preparation("isolated", TRUE)

  expect_error(
    nail_textual(x = prep, analysis_scope = "consumer"),
    "create a new preparation"
  )
  expect_error(
    nail_textual(x = prep, comparison_mode = "joint"),
    "cannot be relabelled"
  )
})

test_that("late analytical request and context are not attributed to existing profiles", {
  prep <- .textual_test_preparation(generated = TRUE)

  expect_error(
    nail_textual(x = prep, request = "Reinterpret through a consumer lens."),
    "cannot retroactively modify"
  )
  expect_error(
    nail_textual(x = prep, context = "New external information."),
    "cannot retroactively modify"
  )

  result <- nail_textual(
    x = prep,
    report_request = "Keep the report concise.",
    report_context = list(audience = "research team"),
    report_format = "markdown"
  )
  expect_identical(result$metadata$report_request, "Keep the report concise.")
  expect_identical(result$metadata$report_context$audience, "research team")
  expect_match(result$report, "Report-stage context", fixed = TRUE)
})

test_that("legacy prompt and response views are derived from the preparation", {
  offline <- .textual_test_preparation(generated = FALSE)
  generated <- .textual_test_preparation(generated = TRUE)

  offline_result <- nail_textual(x = offline)
  generated_result <- nail_textual(x = generated)

  expect_identical(offline_result$legacy_output, lapply(offline$units, `[[`, "prompt"))
  expect_identical(
    generated_result$legacy_output$A$prompt,
    generated$units$A$prompt
  )
  expect_identical(attr(generated_result, "legacy_output"), generated_result$legacy_output)
})

test_that("prepared evidence identity includes rows, identifiers and sampling", {
  prep <- .textual_test_preparation(generated = TRUE)
  result <- nail_textual(x = prep, report_format = "compact")

  expect_identical(
    result$textual_evidence$verbatims,
    prep$textual_evidence$verbatims
  )
  expect_identical(
    result$textual_evidence$evidence_registry,
    prep$textual_evidence$evidence_registry
  )
  expect_identical(
    result$textual_evidence$sampling,
    prep$textual_evidence$sampling
  )
})

test_that("invalid prepared objects fail explicitly", {
  expect_error(nail_textual(x = list()), "valid object")

  invalid <- .textual_test_preparation(generated = FALSE)
  invalid$textual_evidence <- NULL
  expect_error(nail_textual(x = invalid), "textual_evidence")

  expect_error(
    nail_textual(dataset = .textual_test_data(), x = .textual_test_preparation()),
    "either `x` or `dataset`"
  )
})

test_that("textual results expose prompts and print concise summaries", {
  prep <- .textual_test_preparation(generated = FALSE)
  result <- nail_textual(x = prep)

  expect_setequal(names(result$prompt), names(prep$units))
  expect_identical(result$prompt$A, prep$units$A$prompt)
  expect_output(print(prep), "NaileR textual preparation", fixed = TRUE)
  expect_output(print(result), "NaileR textual description", fixed = TRUE)
  expect_output(print(result), "\\$prompt")
})
