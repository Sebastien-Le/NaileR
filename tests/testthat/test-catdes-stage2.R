.catdes_stage2_empty_quali <- function() {
  data.frame(
    "Cla/Mod" = numeric(0),
    "Mod/Cla" = numeric(0),
    Global = numeric(0),
    "p.value" = numeric(0),
    "v.test" = numeric(0),
    check.names = FALSE
  )
}

.catdes_stage2_empty_quanti <- function() {
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

.catdes_stage2_source <- function() {
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
    Empty = .catdes_stage2_empty_quali(),
    special_quali
  )
  names(category)[4] <- special_name

  quanti <- list(
    A = quanti_a,
    B = quanti_b,
    Empty = .catdes_stage2_empty_quanti(),
    .catdes_stage2_empty_quanti()
  )
  names(quanti)[4] <- special_name

  list(category = category, quanti = quanti)
}

.catdes_stage2_profiles <- function() {
  nail_catdes_prep(x = .catdes_stage2_source())
}

.catdes_stage2_mock_response <- function(model, prompt) {
  data.frame(
    model = model,
    created_at = as.POSIXct("2026-01-01", tz = "UTC"),
    response = "mock interpretation",
    done = TRUE,
    prompt = prompt,
    stringsAsFactors = FALSE
  )
}

test_that("prepared statistical profiles are the canonical source", {
  profiles <- .catdes_stage2_profiles()

  testthat::local_mocked_bindings(
    nail_catdes_prep = function(...) stop("nail_catdes_prep must not be called"),
    .package = "NaileR"
  )

  result <- nail_catdes(x = profiles, generate = FALSE)

  expect_true(is.character(result))
  expect_identical(attr(result, "statistical_profiles"), profiles)
  expect_identical(attr(result, "catdes_settings")$nail_catdes_prep_calls, 0L)
  expect_identical(attr(result, "catdes_settings")$direct_catdes_calls_in_nail_catdes, 0L)
})

test_that("raw input is prepared once and keeps historical positional calls", {
  calls <- 0L
  profiles <- .catdes_stage2_profiles()

  testthat::local_mocked_bindings(
    nail_catdes_prep = function(...) {
      calls <<- calls + 1L
      profiles
    },
    .package = "NaileR"
  )

  result <- nail_catdes(
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

test_that("raw and prepared routes preserve the same statistical core", {
  raw_result <- nail_catdes(
    dataset = iris,
    num.var = 5,
    proba = 0.05,
    generate = FALSE
  )

  catdes_result <- FactoMineR::catdes(iris, num.var = 5, proba = 0.05)
  profiles <- nail_catdes_prep(x = catdes_result, proba = 0.05)
  prepared_result <- nail_catdes(x = profiles, generate = FALSE)

  expect_identical(attr(raw_result, "statistical_profiles"), profiles)
  expect_identical(attr(prepared_result, "statistical_profiles"), profiles)
})

test_that("prompt selection is deterministic and does not touch RNG", {
  profiles <- .catdes_stage2_profiles()
  set.seed(847)
  before <- .Random.seed

  first <- nail_catdes(
    x = profiles,
    quali.sample = 0.5,
    quanti.sample = 0.5,
    isolate.groups = TRUE,
    generate = FALSE
  )
  after <- .Random.seed
  second <- nail_catdes(
    x = profiles,
    quali.sample = 0.5,
    quanti.sample = 0.5,
    isolate.groups = TRUE,
    generate = FALSE
  )

  expect_identical(after, before)
  expect_identical(
    attr(first, "interpretation_evidence"),
    attr(second, "interpretation_evidence")
  )
  expect_identical(
    attr(first, "interpretation_evidence")$groups$A$metrics$n_qualitative_selected,
    2L
  )
  expect_identical(
    attr(first, "interpretation_evidence")$groups$A$metrics$n_quantitative_selected,
    2L
  )
})

test_that("sampling and drop.negative never mutate statistical_profiles", {
  profiles <- .catdes_stage2_profiles()

  full <- nail_catdes(x = profiles, generate = FALSE)
  reduced <- nail_catdes(
    x = profiles,
    quali.sample = 0.25,
    quanti.sample = 0.5,
    drop.negative = TRUE,
    generate = FALSE
  )

  expect_identical(attr(full, "statistical_profiles"), profiles)
  expect_identical(attr(reduced, "statistical_profiles"), profiles)
  expect_identical(
    attr(reduced, "interpretation_evidence")$groups$A$metrics$n_negative_selected,
    0L
  )
})

test_that("the LLM prompt does not expose evidence IDs", {
  profiles <- .catdes_stage2_profiles()
  result <- nail_catdes(
    x = profiles,
    isolate.groups = TRUE,
    generate = FALSE
  )
  evidence <- attr(result, "interpretation_evidence")

  expect_true(nrow(evidence$selected_evidence_registry) > 0L)
  expect_false(any(vapply(result, grepl, logical(1), pattern = "Evidence ID", fixed = TRUE)))
  expect_false(any(vapply(
    result,
    function(prompt) any(vapply(
      evidence$selected_evidence_registry$evidence_id,
      function(id) grepl(id, prompt, fixed = TRUE),
      logical(1)
    )),
    logical(1)
  )))
})

test_that("standard and latent modes preserve the historical semantic contract", {
  profiles <- .catdes_stage2_profiles()

  standard <- nail_catdes(
    x = profiles,
    interpretation_mode = "standard",
    generate = FALSE
  )
  latent <- nail_catdes(
    x = profiles,
    interpretation_mode = "latent",
    generate = FALSE
  )

  expect_match(standard, "Do not reinterpret the categories as latent profiles", fixed = TRUE)
  expect_match(standard, "do not rename them", fixed = TRUE)
  expect_match(latent, "meaning must be inferred from the results", fixed = TRUE)
  expect_match(latent, "propose a meaningful name for each group", fixed = TRUE)
})

test_that("markdown formatting preserves ordinary r and n characters", {
  profiles <- .catdes_stage2_profiles()
  prompt <- nail_catdes(
    x = profiles,
    interpretation_mode = "standard",
    generate = FALSE
  )

  expect_match(prompt, "Purchase_place", fixed = TRUE)
  expect_match(prompt, "Local_market", fixed = TRUE)
  expect_match(prompt, "Organic", fixed = TRUE)
  expect_match(prompt, "Sustainability_score", fixed = TRUE)
  expect_match(prompt, "Trust_score", fixed = TRUE)

  expect_equal(
    .escape_markdown_cell_nail_catdes("line1\r\nline2"),
    "line1 line2"
  )
})

test_that("joint and isolated prompt forms remain available", {
  profiles <- .catdes_stage2_profiles()
  joint <- nail_catdes(x = profiles, isolate.groups = FALSE, generate = FALSE)
  isolated <- nail_catdes(x = profiles, isolate.groups = TRUE, generate = FALSE)

  expect_true(is.character(joint))
  expect_length(joint, 1L)
  expect_true(is.list(isolated))
  expect_setequal(names(isolated), names(profiles$groups))
})

test_that("joint generation makes exactly one backend call", {
  profiles <- .catdes_stage2_profiles()
  calls <- 0L

  testthat::local_mocked_bindings(
    .call_llm_base = function(provider, model, prompt, output, llm_api_options) {
      calls <<- calls + 1L
      .catdes_stage2_mock_response(model, prompt)
    },
    .package = "NaileR"
  )

  result <- nail_catdes(x = profiles, generate = TRUE)
  expect_identical(calls, 1L)
  expect_true(is.data.frame(result))
  expect_identical(attr(result, "catdes_settings")$llm_calls, 1L)
})

test_that("isolated generation calls only groups with selected evidence", {
  profiles <- .catdes_stage2_profiles()
  calls <- 0L

  testthat::local_mocked_bindings(
    .call_llm_base = function(provider, model, prompt, output, llm_api_options) {
      calls <<- calls + 1L
      .catdes_stage2_mock_response(model, prompt)
    },
    .package = "NaileR"
  )

  result <- nail_catdes(x = profiles, isolate.groups = TRUE, generate = TRUE)
  evidence <- attr(result, "interpretation_evidence")

  expect_identical(calls, evidence$metadata$n_ready_groups)
  expect_identical(
    attr(result, "catdes_settings")$llm_calls,
    evidence$metadata$n_ready_groups
  )
  expect_match(result$Empty$response, "No selected statistical evidence", fixed = TRUE)
})

test_that("zero selected evidence never calls a backend", {
  profiles <- .catdes_stage2_profiles()

  testthat::local_mocked_bindings(
    .call_llm_base = function(...) stop("backend must not be called"),
    .package = "NaileR"
  )

  result <- nail_catdes(
    x = profiles,
    quali.sample = 0,
    quanti.sample = 0,
    generate = TRUE
  )

  expect_true(is.data.frame(result))
  expect_identical(result$response, "No selected statistical evidence found.")
  expect_identical(attr(result, "catdes_settings")$llm_calls, 0L)
})

test_that("target label is recovered for raw and prepared dataset routes", {
  raw <- nail_catdes(iris, 5, generate = FALSE)
  prepared <- suppressWarnings(nail_catdes_prep(dataset = iris, num.var = 5))
  from_prepared <- nail_catdes(x = prepared, generate = FALSE)

  expect_identical(attr(raw, "catdes_settings")$target_label, "Species")
  expect_identical(attr(from_prepared, "catdes_settings")$target_label, "Species")
  expect_match(raw, "'Species'", fixed = TRUE)
  expect_match(from_prepared, "'Species'", fixed = TRUE)
})

test_that("ambiguous and invalid inputs fail explicitly", {
  profiles <- .catdes_stage2_profiles()

  expect_error(nail_catdes(dataset = iris, num.var = 5, x = profiles), "only one")
  expect_error(nail_catdes(), "either `x` or `dataset`")
  expect_error(nail_catdes(x = list()), "valid `statistical_profiles`")
  expect_error(nail_catdes(x = profiles, num.var = 1), "cannot be used")
  expect_error(nail_catdes(x = profiles, row.w = 1), "cannot be used")
  expect_error(nail_catdes(x = profiles, quali.sample = -0.1), "single numeric value in [0, 1]", fixed = TRUE)
  expect_error(nail_catdes(x = profiles, quanti.sample = 1.1), "single numeric value in [0, 1]", fixed = TRUE)
})
