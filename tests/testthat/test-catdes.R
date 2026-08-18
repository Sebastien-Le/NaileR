.catdes_stage1_empty_quali <- function() {
  data.frame(
    "Cla/Mod" = numeric(0),
    "Mod/Cla" = numeric(0),
    Global = numeric(0),
    "p.value" = numeric(0),
    "v.test" = numeric(0),
    check.names = FALSE
  )
}

.catdes_stage1_empty_quanti <- function() {
  data.frame(
    "Mean in category" = numeric(0),
    "Overall mean" = numeric(0),
    "sd in category" = numeric(0),
    "Overall sd" = numeric(0),
    "p.value" = numeric(0),
    "v.test" = numeric(0),
    check.names = FALSE
  )
}

.catdes_stage1_source <- function() {
  quali_a <- data.frame(
    "Cla/Mod" = c(70, 15, 62, 20),
    "Mod/Cla" = c(65, 12, 58, 18),
    Global = c(30, 45, 25, 40),
    "p.value" = c(0.001, 0.002, 0.004, 0.010),
    "v.test" = c(5, -4, 3, -2),
    check.names = FALSE,
    row.names = c(
      "Purchase_place=Local_market",
      "Purchase_place=Supermarket",
      "Label::source=Organic",
      "Budget=Constrained"
    )
  )

  quali_b <- data.frame(
    "Cla/Mod" = c(60, 18),
    "Mod/Cla" = c(55, 15),
    Global = c(28, 35),
    "p.value" = c(0.003, 0.020),
    "v.test" = c(3.5, -1.8),
    check.names = FALSE,
    row.names = c("Routine=Stable", "Exploration=Frequent")
  )

  quanti_a <- data.frame(
    "Mean in category" = c(8, 3, 6),
    "Overall mean" = c(5, 5, 5),
    "sd in category" = c(1, 1.2, 1.1),
    "Overall sd" = c(1.5, 1.6, 1.4),
    "p.value" = c(0.001, 0.002, 0.040),
    "v.test" = c(4.5, -3.5, 1.5),
    check.names = FALSE,
    row.names = c(
      "Sustainability_score",
      "Constraint_score",
      "Openness_score"
    )
  )

  quanti_b <- data.frame(
    "Mean in category" = c(7, 2),
    "Overall mean" = c(5, 4),
    "sd in category" = c(1.1, 1.0),
    "Overall sd" = c(1.5, 1.3),
    "p.value" = c(0.005, 0.030),
    "v.test" = c(3, -2),
    check.names = FALSE,
    row.names = c("Trust_score", "Convenience_score")
  )

  special_name <- paste0("Groupe sp", "\u00e9", "cial::", "\u00e9")
  special_quali <- data.frame(
    "Cla/Mod" = 80,
    "Mod/Cla" = 75,
    Global = 20,
    "p.value" = 0.001,
    "v.test" = 4,
    check.names = FALSE,
    row.names = "Canal::achat=March\u00e9"
  )

  category <- list(
    A = quali_a,
    B = quali_b,
    Empty = .catdes_stage1_empty_quali(),
    special_quali
  )
  names(category)[4] <- special_name

  quanti <- list(
    A = quanti_a,
    B = quanti_b,
    Empty = .catdes_stage1_empty_quanti(),
    .catdes_stage1_empty_quanti()
  )
  names(quanti)[4] <- special_name

  list(category = category, quanti = quanti)
}

.catdes_stage1_profiles <- function() {
  nail_catdes_prep(x = .catdes_stage1_source())
}

.catdes_stage1_mock_response <- function(model, prompt) {
  data.frame(
    model = model,
    created_at = as.POSIXct("2026-01-01", tz = "UTC"),
    response = "mock interpretation",
    done = TRUE,
    prompt = prompt,
    stringsAsFactors = FALSE
  )
}

.nail_catdes_legacy <- function(...) {
  nail_catdes(..., return_format = "legacy")
}

test_that("prepared statistical profiles are the exact internal source", {
  profiles <- .catdes_stage1_profiles()

  testthat::local_mocked_bindings(
    nail_catdes_prep = function(...) {
      stop("nail_catdes_prep must not be called")
    },
    .package = "NaileR"
  )

  result <- .nail_catdes_legacy(x = profiles, generate = FALSE)

  expect_true(is.character(result))
  expect_identical(attr(result, "statistical_profiles"), profiles)
  expect_identical(
    attr(result, "catdes_settings")$nail_catdes_prep_calls,
    0L
  )
  expect_identical(
    attr(result, "catdes_settings")$direct_catdes_calls_in_nail_catdes,
    0L
  )
})

test_that("an attached statistical_profiles object is reused without preparation", {
  profiles <- .catdes_stage1_profiles()
  carrier <- structure(list(value = 1), statistical_profiles = profiles)

  testthat::local_mocked_bindings(
    nail_catdes_prep = function(...) {
      stop("nail_catdes_prep must not be called")
    },
    .package = "NaileR"
  )

  result <- .nail_catdes_legacy(x = carrier, generate = FALSE)
  expect_identical(attr(result, "statistical_profiles"), profiles)
  expect_identical(
    attr(result, "catdes_settings")$source_type,
    "statistical_profiles_attribute"
  )
})

test_that("a catdes-compatible historical object is normalized once", {
  profiles <- .catdes_stage1_profiles()
  historical <- structure(list(response = "old"), catdes_result = .catdes_stage1_source())
  calls <- 0L

  testthat::local_mocked_bindings(
    nail_catdes_prep = function(...) {
      calls <<- calls + 1L
      profiles
    },
    .package = "NaileR"
  )

  result <- .nail_catdes_legacy(x = historical, generate = FALSE)
  expect_identical(calls, 1L)
  expect_identical(attr(result, "statistical_profiles"), profiles)
  expect_identical(
    attr(result, "catdes_settings")$nail_catdes_prep_calls,
    1L
  )
})

test_that("the raw path calls nail_catdes_prep exactly once", {
  profiles <- .catdes_stage1_profiles()
  calls <- 0L

  testthat::local_mocked_bindings(
    nail_catdes_prep = function(...) {
      calls <<- calls + 1L
      profiles
    },
    .package = "NaileR"
  )

  result <- .nail_catdes_legacy(
    dataset = iris,
    num.var = 5,
    generate = FALSE
  )

  expect_identical(calls, 1L)
  expect_identical(attr(result, "statistical_profiles"), profiles)
  expect_identical(
    attr(result, "catdes_settings")$direct_catdes_calls_in_nail_catdes,
    0L
  )
  expect_false(any(grepl(
    "FactoMineR::catdes",
    deparse(body(nail_catdes)),
    fixed = TRUE
  )))
})

test_that("raw and precomputed catdes paths preserve the same mechanical core", {
  raw_result <- .nail_catdes_legacy(
    dataset = iris,
    num.var = 5,
    proba = 0.05,
    generate = FALSE
  )

  catdes_result <- FactoMineR::catdes(
    iris,
    num.var = 5,
    proba = 0.05
  )
  profiles <- nail_catdes_prep(x = catdes_result, proba = 0.05)
  prepared_result <- .nail_catdes_legacy(x = profiles, generate = FALSE)

  raw_profiles <- attr(raw_result, "statistical_profiles")
  expect_identical(raw_profiles, profiles)
  expect_identical(attr(prepared_result, "statistical_profiles"), profiles)
  expect_true(
    isTRUE(attr(raw_result, "catdes_settings")$statistical_profiles_canonicalized)
  )
  expect_identical(
    attr(raw_result, "catdes_settings")$preparation_input$source,
    "dataset"
  )
})

test_that("qualitative and quantitative selection is deterministic", {
  profiles <- .catdes_stage1_profiles()

  first <- .nail_catdes_legacy(
    x = profiles,
    quali.sample = 0.5,
    quanti.sample = 0.5,
    isolate.groups = TRUE,
    generate = FALSE
  )
  second <- .nail_catdes_legacy(
    x = profiles,
    quali.sample = 0.5,
    quanti.sample = 0.5,
    isolate.groups = TRUE,
    generate = FALSE
  )

  first_evidence <- attr(first, "interpretation_evidence")
  second_evidence <- attr(second, "interpretation_evidence")

  expect_identical(first_evidence, second_evidence)
  expect_identical(
    first_evidence$groups$A$metrics$n_qualitative_selected,
    2L
  )
  expect_identical(
    first_evidence$groups$A$metrics$n_quantitative_selected,
    2L
  )
  expect_identical(
    first_evidence$groups$A$qualitative_markers$rank,
    c(1L, 2L)
  )
  expect_identical(
    first_evidence$groups$A$quantitative_markers$rank,
    c(1L, 2L)
  )
})

test_that("selection does not alter the global random state", {
  profiles <- .catdes_stage1_profiles()
  set.seed(847)
  before <- .Random.seed

  invisible(.nail_catdes_legacy(
    x = profiles,
    quali.sample = 0.4,
    quanti.sample = 0.4,
    isolate.groups = TRUE,
    generate = FALSE
  ))

  expect_identical(.Random.seed, before)
})

test_that("zero and full proportions have explicit selection rules", {
  profiles <- .catdes_stage1_profiles()

  empty <- .nail_catdes_legacy(
    x = profiles,
    quali.sample = 0,
    quanti.sample = 0,
    isolate.groups = TRUE,
    generate = FALSE
  )
  empty_evidence <- attr(empty, "interpretation_evidence")
  expect_identical(empty_evidence$metadata$n_selected_evidence, 0L)
  expect_true(all(vapply(
    empty_evidence$groups,
    function(group) group$metrics$n_qualitative_selected == 0L &&
      group$metrics$n_quantitative_selected == 0L,
    logical(1)
  )))

  full <- .nail_catdes_legacy(
    x = profiles,
    quali.sample = 1,
    quanti.sample = 1,
    isolate.groups = TRUE,
    generate = FALSE
  )
  full_evidence <- attr(full, "interpretation_evidence")
  expect_identical(
    full_evidence$groups$A$metrics$n_qualitative_selected,
    full_evidence$groups$A$metrics$n_qualitative_available
  )
  expect_identical(
    full_evidence$groups$A$metrics$n_quantitative_selected,
    full_evidence$groups$A$metrics$n_quantitative_available
  )
})

test_that("drop.negative changes only interpretation evidence", {
  profiles <- .catdes_stage1_profiles()

  kept <- .nail_catdes_legacy(
    x = profiles,
    drop.negative = FALSE,
    isolate.groups = TRUE,
    generate = FALSE
  )
  dropped <- .nail_catdes_legacy(
    x = profiles,
    drop.negative = TRUE,
    isolate.groups = TRUE,
    generate = FALSE
  )

  kept_evidence <- attr(kept, "interpretation_evidence")
  dropped_evidence <- attr(dropped, "interpretation_evidence")

  expect_identical(attr(kept, "statistical_profiles"), profiles)
  expect_identical(attr(dropped, "statistical_profiles"), profiles)
  expect_gt(kept_evidence$groups$A$metrics$n_negative_selected, 0L)
  expect_identical(
    dropped_evidence$groups$A$metrics$n_negative_selected,
    0L
  )
  expect_identical(
    dropped_evidence$groups$A$metrics$n_negative_excluded_by_policy,
    dropped_evidence$groups$A$metrics$n_negative_available
  )
  expect_true(all(
    profiles$groups$A$negative_markers$evidence_id %in%
      profiles$evidence_registry$evidence_id
  ))
})

test_that("selected markers retain their original evidence identifiers", {
  profiles <- .catdes_stage1_profiles()
  result <- .nail_catdes_legacy(
    x = profiles,
    quali.sample = 0.5,
    quanti.sample = 0.5,
    isolate.groups = TRUE,
    generate = FALSE
  )
  evidence <- attr(result, "interpretation_evidence")

  expect_true(all(
    evidence$selected_evidence_registry$evidence_id %in%
      profiles$evidence_registry$evidence_id
  ))
  expect_identical(
    anyDuplicated(evidence$selected_evidence_registry$evidence_id),
    0L
  )
  expect_match(result$A, "Evidence ID", fixed = TRUE)
  expect_match(
    result$A,
    evidence$groups$A$selected_evidence_ids[1],
    fixed = TRUE
  )
})

test_that("groups without selected markers remain explicit", {
  profiles <- .catdes_stage1_profiles()
  result <- .nail_catdes_legacy(
    x = profiles,
    quali.sample = 0,
    quanti.sample = 0,
    isolate.groups = TRUE,
    generate = FALSE
  )
  evidence <- attr(result, "interpretation_evidence")

  expect_setequal(names(result), names(profiles$groups))
  expect_setequal(names(evidence$groups), names(profiles$groups))
  expect_identical(evidence$groups$Empty$status, "no_available_markers")
  expect_match(result$Empty, "No statistical evidence was selected", fixed = TRUE)
})

test_that("qualitative-only, quantitative-only, and negative-only groups remain explicit", {
  profiles <- .catdes_stage1_profiles()

  qualitative_only <- profiles
  special_name <- paste0("Groupe sp", "\u00e9", "cial::", "\u00e9")
  qualitative_only$groups <- qualitative_only$groups[special_name]
  qualitative_only$evidence_registry <- qualitative_only$evidence_registry[
    qualitative_only$evidence_registry$group == special_name,
    ,
    drop = FALSE
  ]
  qualitative_result <- .nail_catdes_legacy(
    x = qualitative_only,
    isolate.groups = TRUE,
    generate = FALSE
  )
  qualitative_evidence <- attr(
    qualitative_result,
    "interpretation_evidence"
  )$groups[[special_name]]
  expect_gt(qualitative_evidence$metrics$n_qualitative_selected, 0L)
  expect_identical(
    qualitative_evidence$metrics$n_quantitative_selected,
    0L
  )

  quantitative_only <- profiles
  quantitative_group <- quantitative_only$groups$A
  quantitative_group$qualitative_markers <-
    quantitative_group$qualitative_markers[0, , drop = FALSE]
  quantitative_group$evidence_ids <-
    quantitative_group$quantitative_markers$evidence_id
  quantitative_only$groups <- list(A = quantitative_group)
  quantitative_only$evidence_registry <- quantitative_only$evidence_registry[
    quantitative_only$evidence_registry$group == "A" &
      quantitative_only$evidence_registry$marker_type == "quantitative",
    ,
    drop = FALSE
  ]
  quantitative_result <- .nail_catdes_legacy(
    x = quantitative_only,
    isolate.groups = TRUE,
    generate = FALSE
  )
  quantitative_evidence <- attr(
    quantitative_result,
    "interpretation_evidence"
  )$groups$A
  expect_identical(
    quantitative_evidence$metrics$n_qualitative_selected,
    0L
  )
  expect_gt(quantitative_evidence$metrics$n_quantitative_selected, 0L)

  negative_only <- profiles
  negative_group <- negative_only$groups$A
  negative_group$qualitative_markers <- negative_group$qualitative_markers[
    negative_group$qualitative_markers$direction == "underrepresented",
    ,
    drop = FALSE
  ]
  negative_group$quantitative_markers <- negative_group$quantitative_markers[
    negative_group$quantitative_markers$direction == "lower",
    ,
    drop = FALSE
  ]
  negative_group$evidence_ids <- c(
    negative_group$qualitative_markers$evidence_id,
    negative_group$quantitative_markers$evidence_id
  )
  negative_only$groups <- list(A = negative_group)
  negative_only$evidence_registry <- negative_only$evidence_registry[
    negative_only$evidence_registry$evidence_id %in% negative_group$evidence_ids,
    ,
    drop = FALSE
  ]
  negative_result <- .nail_catdes_legacy(
    x = negative_only,
    drop.negative = TRUE,
    isolate.groups = TRUE,
    generate = FALSE
  )
  negative_evidence <- attr(
    negative_result,
    "interpretation_evidence"
  )$groups$A
  expect_identical(negative_evidence$status, "no_eligible_markers")
  expect_identical(
    negative_evidence$metrics$n_negative_excluded_by_policy,
    negative_evidence$metrics$n_negative_available
  )
  expect_identical(
    attr(negative_result, "statistical_profiles"),
    negative_only
  )
})

test_that("non-syntactic and non-ASCII group names are preserved", {
  profiles <- .catdes_stage1_profiles()
  special_name <- paste0("Groupe sp", "\u00e9", "cial::", "\u00e9")

  result <- .nail_catdes_legacy(
    x = profiles,
    isolate.groups = TRUE,
    generate = FALSE
  )
  evidence <- attr(result, "interpretation_evidence")

  expect_true(special_name %in% names(result))
  expect_true(special_name %in% names(evidence$groups))
  expect_true(any(grepl(
    "%3A%3A",
    profiles$evidence_registry$evidence_id,
    fixed = TRUE
  )))
})

test_that("historical prompt return types remain available", {
  profiles <- .catdes_stage1_profiles()

  joint <- .nail_catdes_legacy(x = profiles, isolate.groups = FALSE, generate = FALSE)
  isolated <- .nail_catdes_legacy(x = profiles, isolate.groups = TRUE, generate = FALSE)

  expect_true(is.character(joint))
  expect_length(joint, 1L)
  expect_true(is.list(isolated))
  expect_setequal(names(isolated), names(profiles$groups))
  expect_false(inherits(joint, "nail_catdes"))
  expect_false(inherits(isolated, "nail_catdes"))
})

test_that("all historical return forms carry the mechanical artifacts", {
  profiles <- .catdes_stage1_profiles()
  result <- .nail_catdes_legacy(x = profiles, isolate.groups = TRUE, generate = FALSE)

  expect_identical(attr(result, "statistical_profiles"), profiles)
  expect_s3_class(
    attr(result, "interpretation_evidence"),
    "nail_catdes_interpretation_evidence"
  )
  expect_true(is.list(attr(result, "catdes_result")))
  expect_true(is.list(attr(result, "catdes_settings")))
})

test_that("generation uses only eligible prompt units", {
  profiles <- .catdes_stage1_profiles()
  calls <- character(0)

  testthat::local_mocked_bindings(
    .call_llm_base = function(provider, model, prompt, output,
                              llm_api_options) {
      calls <<- c(calls, prompt)
      .catdes_stage1_mock_response(model, prompt)
    },
    .package = "NaileR"
  )

  result <- .nail_catdes_legacy(
    x = profiles,
    isolate.groups = TRUE,
    quali.sample = 1,
    quanti.sample = 1,
    generate = TRUE
  )
  evidence <- attr(result, "interpretation_evidence")

  expect_identical(length(calls), evidence$metadata$n_ready_groups)
  expect_identical(
    attr(result, "catdes_settings")$llm_calls,
    evidence$metadata$n_ready_groups
  )
  expect_identical(result$Empty$response, "No selected statistical evidence found for group 'Empty'.")
})

test_that("joint generation makes at most one backend call", {
  profiles <- .catdes_stage1_profiles()
  calls <- 0L

  testthat::local_mocked_bindings(
    .call_llm_base = function(provider, model, prompt, output,
                              llm_api_options) {
      calls <<- calls + 1L
      .catdes_stage1_mock_response(model, prompt)
    },
    .package = "NaileR"
  )

  result <- .nail_catdes_legacy(x = profiles, generate = TRUE)
  expect_identical(calls, 1L)
  expect_true(is.data.frame(result))
  expect_identical(attr(result, "catdes_settings")$llm_calls, 1L)
})

test_that("zero selected evidence never calls a backend", {
  profiles <- .catdes_stage1_profiles()

  testthat::local_mocked_bindings(
    .call_llm_base = function(...) {
      stop("backend must not be called")
    },
    .package = "NaileR"
  )

  result <- .nail_catdes_legacy(
    x = profiles,
    quali.sample = 0,
    quanti.sample = 0,
    generate = TRUE
  )

  expect_true(is.data.frame(result))
  expect_identical(result$response, "No selected statistical evidence found.")
  expect_identical(attr(result, "catdes_settings")$llm_calls, 0L)
})

test_that("backend errors remain explicit", {
  profiles <- .catdes_stage1_profiles()

  testthat::local_mocked_bindings(
    .call_llm_base = function(...) {
      stop("simulated backend failure")
    },
    .package = "NaileR"
  )

  expect_error(
    .nail_catdes_legacy(x = profiles, generate = TRUE),
    "simulated backend failure"
  )
})

test_that("one-group statistical profiles remain analyzable", {
  profiles <- .catdes_stage1_profiles()
  profiles$groups <- profiles$groups["A"]
  profiles$evidence_registry <- profiles$evidence_registry[
    profiles$evidence_registry$group == "A",
    ,
    drop = FALSE
  ]

  result <- .nail_catdes_legacy(x = profiles, isolate.groups = TRUE, generate = FALSE)
  expect_identical(names(result), "A")
  expect_identical(
    names(attr(result, "interpretation_evidence")$groups),
    "A"
  )
})

test_that("ambiguous and invalid inputs fail explicitly", {
  profiles <- .catdes_stage1_profiles()

  expect_error(
    .nail_catdes_legacy(dataset = iris, num.var = 5, x = profiles),
    "only one"
  )
  expect_error(.nail_catdes_legacy(), "either `x` or `dataset`")
  expect_error(.nail_catdes_legacy(x = list()), "valid `statistical_profiles`")
  empty_profiles <- profiles
  empty_profiles$groups <- list()
  empty_profiles$evidence_registry <-
    empty_profiles$evidence_registry[0, , drop = FALSE]
  expect_error(.nail_catdes_legacy(x = empty_profiles), "non-empty uniquely named")
  expect_error(.nail_catdes_legacy(x = profiles, num.var = 1), "cannot be used")
  expect_error(.nail_catdes_legacy(x = profiles, row.w = 1), "cannot be used")
  expect_error(
    .nail_catdes_legacy(x = profiles, quali.sample = -0.1),
    "single numeric value in [0, 1]",
    fixed = TRUE
  )
  expect_error(
    .nail_catdes_legacy(x = profiles, quanti.sample = 1.1),
    "single numeric value in [0, 1]",
    fixed = TRUE
  )
})

test_that("historical positional arguments keep their original meaning", {
  profiles <- .catdes_stage1_profiles()
  calls <- 0L

  testthat::local_mocked_bindings(
    nail_catdes_prep = function(...) {
      calls <<- calls + 1L
      profiles
    },
    .package = "NaileR"
  )

  result <- .nail_catdes_legacy(
    iris,
    5,
    "Historical introduction",
    "Historical request",
    generate = FALSE
  )

  expect_identical(calls, 1L)
  expect_match(result, "Historical introduction", fixed = TRUE)
  expect_match(result, "Historical request", fixed = TRUE)
})

test_that("generation and prompt options do not alter statistical_profiles", {
  profiles <- .catdes_stage1_profiles()

  testthat::local_mocked_bindings(
    .call_llm_base = function(provider, model, prompt, output,
                              llm_api_options) {
      .catdes_stage1_mock_response(model, prompt)
    },
    .package = "NaileR"
  )

  offline <- .nail_catdes_legacy(
    x = profiles,
    introduction = "offline context",
    request = "offline request",
    generate = FALSE
  )
  generated <- .nail_catdes_legacy(
    x = profiles,
    introduction = "another context",
    request = "another request",
    provider = "gemini",
    model = "mock-model",
    isolate.groups = TRUE,
    drop.negative = TRUE,
    quali.sample = 0.25,
    quanti.sample = 0.5,
    generate = TRUE
  )

  expect_identical(attr(offline, "statistical_profiles"), profiles)
  expect_identical(attr(generated, "statistical_profiles"), profiles)
})

.catdes_structured_mock_json <- function(unit_data,
                                         invalid_evidence = FALSE,
                                         latent = FALSE) {
  evidence_id <- if (isTRUE(invalid_evidence)) {
    "unknown::statistical::evidence"
  } else {
    unit_data$allowed_evidence_ids[[1L]]
  }

  claim <- list(
    text = paste0("Structured interpretation for ", unit_data$group, "."),
    status = "expert_interpretation",
    evidence_ids = list(evidence_id),
    support = paste0(
      "The cited marker directly characterizes group ",
      unit_data$group, "."
    ),
    validation_needed = NULL
  )

  jsonlite::toJSON(
    list(
      group = unit_data$group,
      suggested_label = if (isTRUE(latent)) {
        paste("Profile", unit_data$group)
      } else {
        NULL
      },
      core_statistical_profile = claim,
      dominant_markers = list(claim),
      secondary_markers = list(),
      internal_contrasts = list(),
      interpretation_limits = list()
    ),
    auto_unbox = TRUE,
    null = "null"
  )
}


test_that("structured catdes is the default and exposes ergonomic components", {
  profiles <- .catdes_stage1_profiles()

  result <- nail_catdes(x = profiles, generate = FALSE)

  expect_s3_class(result, "nail_catdes")
  expect_identical(result$preparation$statistical_profiles, profiles)
  expect_identical(
    result$preparation$interpretation_evidence,
    result$interpretation_evidence
  )
  expect_setequal(names(result$prompt), names(profiles$groups))
  expect_true(all(vapply(
    result$prompt,
    function(prompt) is.null(prompt) || is.character(prompt),
    logical(1)
  )))
  expect_true(is.list(result$generation))
  expect_true(is.list(result$validation))
  expect_true(is.list(result$report))
  expect_identical(result$metadata$return_format, "structured")
  expect_identical(anyDuplicated(names(result$metadata)), 0L)
  expect_identical(result$validation$status, "not_generated")
})

test_that("legacy catdes remains available only when explicitly requested", {
  profiles <- .catdes_stage1_profiles()

  joint <- nail_catdes(
    x = profiles,
    return_format = "legacy",
    isolate.groups = FALSE,
    generate = FALSE
  )
  isolated <- nail_catdes(
    x = profiles,
    return_format = "legacy",
    isolate.groups = TRUE,
    generate = FALSE
  )

  expect_true(is.character(joint))
  expect_true(is.list(isolated))
  expect_false(inherits(joint, "nail_catdes"))
  expect_false(inherits(isolated, "nail_catdes"))
})

test_that("catdes and statistical profiles print concise summaries", {
  profiles <- .catdes_stage1_profiles()
  result <- nail_catdes(x = profiles, generate = FALSE)

  expect_output(print(profiles), "NaileR statistical profiles", fixed = TRUE)
  expect_output(print(result), "NaileR statistical description", fixed = TRUE)
  expect_output(print(result), "\\$prompt")
})

test_that("structured catdes offline exposes prompts and schemas without generation", {
  profiles <- .catdes_stage1_profiles()

  testthat::local_mocked_bindings(
    .nail_structured_dispatch_call = function(...) {
      stop("structured backend must not be called")
    },
    .package = "NaileR"
  )

  result <- nail_catdes(
    x = profiles,
    return_format = "structured",
    generate = FALSE
  )

  expect_s3_class(result, "nail_catdes")
  expect_s3_class(result$statistical_description, "statistical_description")
  expect_identical(
    result$statistical_description$metadata$parse_status,
    "not_generated"
  )
  expect_identical(result$metadata$structured_llm_calls, 0L)
  expect_true(is.character(result$legacy_output))

  ready <- vapply(
    result$units,
    function(unit) isTRUE(unit$eligible),
    logical(1)
  )
  expect_true(all(vapply(
    result$units[ready],
    function(unit) is.character(unit$prompt) && is.list(unit$schema),
    logical(1)
  )))
  expect_true(all(vapply(
    result$units[ready],
    function(unit) identical(unit$parse_status, "not_generated"),
    logical(1)
  )))
})

test_that("structured catdes generation validates claims and evidence IDs", {
  profiles <- .catdes_stage1_profiles()
  calls <- 0L
  schemas <- list()

  result <- nail_catdes(
    x = profiles,
    return_format = "structured",
    generate = TRUE,
    .llm_call = function(prompt, schema, provider, model,
                         unit_type, unit_data) {
      calls <<- calls + 1L
      schemas[[unit_data$group]] <<- schema
      .catdes_structured_mock_json(unit_data)
    }
  )

  evidence <- result$interpretation_evidence
  description <- result$statistical_description

  expect_identical(calls, evidence$metadata$n_ready_groups)
  expect_identical(
    result$metadata$structured_llm_calls,
    evidence$metadata$n_ready_groups
  )
  expect_identical(description$metadata$parse_status, "success")
  expect_identical(
    description$metadata$n_groups_validated,
    evidence$metadata$n_ready_groups
  )
  expect_true(all(vapply(schemas, is.list, logical(1))))
  expect_identical(anyDuplicated(description$claim_registry$claim_id), 0L)

  cited <- unique(unlist(lapply(
    description$groups,
    function(group) c(
      group$core_statistical_profile$evidence_ids,
      unlist(lapply(group$dominant_markers, `[[`, "evidence_ids"), use.names = FALSE)
    )
  ), use.names = FALSE))
  expect_true(all(cited %in% evidence$selected_evidence_registry$evidence_id))
  expect_identical(
    attr(result, "statistical_description"),
    description
  )
})

test_that("structured catdes rejects inadmissible statistical evidence IDs", {
  profiles <- .catdes_stage1_profiles()

  result <- nail_catdes(
    x = profiles,
    return_format = "structured",
    generate = TRUE,
    .llm_call = function(prompt, schema, provider, model,
                         unit_type, unit_data) {
      .catdes_structured_mock_json(unit_data, invalid_evidence = TRUE)
    }
  )

  expect_identical(
    result$statistical_description$metadata$parse_status,
    "error"
  )
  expect_length(result$statistical_description$groups, 0L)
  errors <- unlist(result$statistical_description$metadata$errors)
  expect_true(any(grepl("inadmissible evidence IDs", errors, fixed = TRUE)))
})

test_that("structured latent catdes may propose labels but still cites evidence", {
  profiles <- .catdes_stage1_profiles()

  result <- nail_catdes(
    x = profiles,
    interpretation_mode = "latent",
    return_format = "structured",
    generate = TRUE,
    .llm_call = function(prompt, schema, provider, model,
                         unit_type, unit_data) {
      .catdes_structured_mock_json(unit_data, latent = TRUE)
    }
  )

  expect_identical(
    result$statistical_description$metadata$parse_status,
    "success"
  )
  expect_true(all(vapply(
    result$statistical_description$groups,
    function(group) is.character(group$suggested_label) &&
      nzchar(group$suggested_label),
    logical(1)
  )))
})

test_that("statistical methodological limits accept causal disclaimers", {
  profiles <- .catdes_stage1_profiles()
  offline <- nail_catdes(x = profiles, generate = FALSE)
  group_data <- NaileR:::.nail_stat_group_data(
    offline$preparation$interpretation_evidence$groups$A,
    interpretation_mode = "standard",
    target_label = "target"
  )
  valid <- jsonlite::fromJSON(
    .catdes_structured_mock_json(group_data),
    simplifyVector = FALSE
  )
  valid$interpretation_limits <- list(
    list(
      text = "The results describe associations, not causes.",
      status = "expert_interpretation",
      evidence_ids = list(),
      support = "No causal mechanism can be established from catdes markers.",
      validation_needed = NULL
    )
  )

  parsed <- NaileR:::.nail_stat_parse_group_response(
    jsonlite::toJSON(valid, auto_unbox = TRUE, null = "null"),
    group_data = group_data,
    interpretation_mode = "standard"
  )

  expect_identical(parsed$parse_status, "success")
  expect_length(parsed$analysis$interpretation_limits, 1L)
})

test_that("one-marker historical contrasts are transparently reclassified", {
  profiles <- .catdes_stage1_profiles()
  offline <- nail_catdes(x = profiles, generate = FALSE)
  group_data <- NaileR:::.nail_stat_group_data(
    offline$preparation$interpretation_evidence$groups$A,
    interpretation_mode = "standard",
    target_label = "target"
  )
  valid <- jsonlite::fromJSON(
    .catdes_structured_mock_json(group_data),
    simplifyVector = FALSE
  )
  valid$internal_contrasts <- list(
    list(
      text = "This is a one-marker statement rather than a contrast.",
      status = "expert_interpretation",
      evidence_ids = list(group_data$allowed_evidence_ids[[1L]]),
      support = "Only one marker is cited.",
      validation_needed = NULL
    )
  )

  parsed <- NaileR:::.nail_stat_parse_group_response(
    jsonlite::toJSON(valid, auto_unbox = TRUE, null = "null"),
    group_data = group_data,
    interpretation_mode = "standard"
  )

  expect_identical(parsed$parse_status, "success")
  expect_length(parsed$analysis$internal_contrasts, 0L)
  expect_length(parsed$analysis$secondary_markers, 1L)
  expect_match(
    parsed$analysis$normalization_warnings,
    "reclassified as secondary markers",
    fixed = TRUE
  )
  expect_identical(
    parsed$analysis$secondary_markers[[1L]]$section,
    "secondary_markers"
  )
})

test_that("future statistical schemas require two markers for contrasts", {
  schema <- NaileR:::.nail_stat_group_schema(
    group_name = "A",
    interpretation_mode = "standard"
  )
  min_items <- schema$properties$internal_contrasts$items$properties$evidence_ids$minItems

  expect_identical(min_items, 2L)

  profiles <- .catdes_stage1_profiles()
  offline <- nail_catdes(x = profiles, generate = FALSE)
  expect_match(
    offline$prompt$A,
    "at least two distinct evidence_ids",
    fixed = TRUE
  )
})

test_that("omitted statistical evidence IDs are recovered from labels and values", {
  profiles <- .catdes_stage1_profiles()
  offline <- nail_catdes(x = profiles, generate = FALSE)
  group_data <- NaileR:::.nail_stat_group_data(
    offline$preparation$interpretation_evidence$groups$A,
    interpretation_mode = "standard",
    target_label = "target"
  )
  valid <- jsonlite::fromJSON(
    .catdes_structured_mock_json(group_data),
    simplifyVector = FALSE
  )
  omitted <- group_data$quantitative_markers[[1L]]
  valid$core_statistical_profile$text <- paste(
    omitted$variable,
    "has a group mean of",
    omitted$group_mean,
    "versus",
    omitted$overall_mean,
    "overall."
  )
  valid$core_statistical_profile$support <- paste(
    "The displayed values for",
    omitted$variable,
    "support this interpretation."
  )
  valid$core_statistical_profile$evidence_ids <- list(
    group_data$allowed_evidence_ids[[length(group_data$allowed_evidence_ids)]]
  )

  parsed <- NaileR:::.nail_stat_parse_group_response(
    jsonlite::toJSON(valid, auto_unbox = TRUE, null = "null"),
    group_data = group_data,
    interpretation_mode = "standard"
  )

  expect_identical(parsed$parse_status, "success")
  expect_true(
    omitted$evidence_id %in%
      parsed$analysis$core_statistical_profile$evidence_ids
  )
  expect_identical(
    parsed$analysis$core_statistical_profile$evidence_ids_recovered,
    omitted$evidence_id
  )
  expect_true(any(grepl(
    "recovered mechanically",
    parsed$analysis$normalization_warnings,
    fixed = TRUE
  )))
})

test_that("statistical schema capacity follows the selected evidence registry", {
  profiles <- .catdes_stage1_profiles()
  offline <- nail_catdes(x = profiles, generate = FALSE)

  for (group_name in names(offline$units)) {
    expected <- length(
      offline$preparation$interpretation_evidence$groups[[group_name]]$selected_evidence_ids
    )
    unit <- offline$units[[group_name]]

    if (expected == 0L) {
      expect_false(unit$eligible)
      expect_null(unit$schema)
    } else {
      observed <- unit$schema$properties$core_statistical_profile$properties$evidence_ids$maxItems
      expect_identical(observed, max(1L, expected))
    }
  }
})

test_that("statistical interpretation limits reject substantive profile claims", {
  profiles <- .catdes_stage1_profiles()
  offline <- nail_catdes(x = profiles, generate = FALSE)
  group_data <- NaileR:::.nail_stat_group_data(
    offline$preparation$interpretation_evidence$groups$A,
    interpretation_mode = "standard",
    target_label = "target"
  )
  valid <- jsonlite::fromJSON(
    .catdes_structured_mock_json(group_data),
    simplifyVector = FALSE
  )
  valid$interpretation_limits <- list(
    list(
      text = paste(
        "The group's characteristics are clearly defined by a pragmatic",
        "and constrained approach, suggesting a more rigid and less flexible profile."
      ),
      status = "expert_interpretation",
      evidence_ids = list(),
      support = "This sentence adds a substantive characterization of the group.",
      validation_needed = NULL
    )
  )

  parsed <- NaileR:::.nail_stat_parse_group_response(
    jsonlite::toJSON(valid, auto_unbox = TRUE, null = "null"),
    group_data = group_data,
    interpretation_mode = "standard"
  )

  expect_identical(parsed$parse_status, "error")
  expect_match(
    parsed$parse_error,
    "must not introduce a new substantive description",
    fixed = TRUE
  )
})

test_that("statistical interpretation limits are evidence-free in schema and validation", {
  schema <- NaileR:::.nail_stat_group_schema(
    group_name = "A",
    interpretation_mode = "standard"
  )
  limit_evidence <- schema$properties$interpretation_limits$items$properties$evidence_ids
  expect_identical(limit_evidence$minItems, 0L)
  expect_identical(limit_evidence$maxItems, 0L)

  profiles <- .catdes_stage1_profiles()
  offline <- nail_catdes(x = profiles, generate = FALSE)
  expect_match(
    offline$prompt$A,
    "interpretation_limits must use an empty evidence_ids array",
    fixed = TRUE
  )

  group_data <- NaileR:::.nail_stat_group_data(
    offline$preparation$interpretation_evidence$groups$A,
    interpretation_mode = "standard",
    target_label = "target"
  )
  valid <- jsonlite::fromJSON(
    .catdes_structured_mock_json(group_data),
    simplifyVector = FALSE
  )
  valid$interpretation_limits <- list(
    list(
      text = "The results describe associations, not causes.",
      status = "expert_interpretation",
      evidence_ids = list(group_data$allowed_evidence_ids[[1L]]),
      support = "A marker was cited even though this is a methodological limit.",
      validation_needed = NULL
    )
  )

  parsed <- NaileR:::.nail_stat_parse_group_response(
    jsonlite::toJSON(valid, auto_unbox = TRUE, null = "null"),
    group_data = group_data,
    interpretation_mode = "standard"
  )
  expect_identical(parsed$parse_status, "error")
  expect_match(parsed$parse_error, "empty evidence_ids array", fixed = TRUE)
})
