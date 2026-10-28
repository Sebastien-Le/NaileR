test_that("CATDES textual enrichment preserves the statistical CATDES contract", {
  data(atomic_habit_clust, package = "NaileR")

  statistical_data <- atomic_habit_clust[, -31, drop = FALSE]
  baseline <- nail_catdes(
    statistical_data,
    num.var = 50,
    interpretation_mode = "latent",
    isolate.groups = FALSE,
    generate = FALSE
  )
  null_sample <- nail_catdes(
    statistical_data,
    num.var = 50,
    textual.sample = 0.1,
    textual.seed = 777,
    interpretation_mode = "latent",
    generate = FALSE
  )
  expect_identical(nail_evidence(null_sample), nail_evidence(baseline))
  expect_identical(
    nail_prompt(null_sample, print = FALSE),
    nail_prompt(baseline, print = FALSE)
  )

  set.seed(11)
  enriched <- nail_catdes(
    atomic_habit_clust,
    num.var = 51,
    num.textual = 31,
    textual.sample = 0.25,
    interpretation_mode = "latent",
    isolate.groups = FALSE,
    generate = FALSE
  )

  expect_identical(nail_evidence(enriched), nail_evidence(baseline))
  expect_identical(
    nail_prompt(enriched, print = FALSE),
    nail_prompt(baseline, print = FALSE)
  )
  expect_s3_class(nail_evidence(enriched), "statistical_profiles")
  expect_s3_class(
    nail_catdes_enrichment(enriched),
    "nail_catdes_textual_enrichment"
  )
  expect_identical(
    nail_catdes_enrichment(enriched)$second_pass$status,
    c(portfolio = "pending_first_pass")
  )
  expect_null(nail_catdes_enrichment(enriched)$second_pass$prompts)
  expect_gt(nrow(nail_catdes_enrichment(enriched)$selected_texts), 0L)
  expect_identical(
    nail_catdes_enrichment(enriched)$settings$num_textual,
    31L
  )

  set.seed(11)
  full_text <- nail_catdes(
    atomic_habit_clust,
    num.var = 51,
    num.textual = 31,
    textual.sample = 1,
    generate = FALSE
  )
  expect_identical(nail_evidence(full_text), nail_evidence(enriched))
  expect_identical(
    nail_catdes_enrichment(full_text)$textual_evidence$text_registry,
    nail_catdes_enrichment(enriched)$textual_evidence$text_registry
  )
})


test_that("textual column positions are excluded without changing CATDES evidence", {
  data(atomic_habit_clust, package = "NaileR")
  text <- atomic_habit_clust$car_alone_text
  statistical_data <- atomic_habit_clust[, -31, drop = FALSE]
  baseline <- nail_catdes(statistical_data, num.var = 50, generate = FALSE)

  before_group <- cbind(
    text = text,
    atomic_habit_clust[, -31, drop = FALSE]
  )
  after_group <- cbind(
    atomic_habit_clust[, -31, drop = FALSE],
    text = text
  )

  for (case in list(
    list(data = before_group, group = 51L, text = 1L),
    list(data = atomic_habit_clust, group = 51L, text = 31L),
    list(data = after_group, group = 50L, text = 51L)
  )) {
    preview <- nail_catdes(
      case$data,
      num.var = case$group,
      num.textual = case$text,
      generate = FALSE
    )
    expect_identical(nail_evidence(preview), nail_evidence(baseline))
    expect_identical(
      nail_prompt(preview, print = FALSE),
      nail_prompt(baseline, print = FALSE)
    )
  }
})


test_that("preview prepares text evidence but never fabricates the second prompt", {
  data(atomic_habit_clust, package = "NaileR")

  testthat::local_mocked_bindings(
    .call_llm_base = function(...) stop("backend must not be called"),
    .package = "NaileR"
  )

  preview <- nail_catdes(
    atomic_habit_clust,
    num.var = 51,
    num.textual = 31,
    textual.sample = 0.2,
    isolate.groups = TRUE,
    generate = FALSE
  )
  enrichment <- nail_catdes_enrichment(preview)

  expect_length(enrichment$first_pass$prompts, 3L)
  expect_true(all(nzchar(unname(enrichment$first_pass$prompts))))
  expect_identical(
    unname(enrichment$first_pass$status),
    rep("prompt_ready", 3L)
  )
  expect_identical(
    unname(enrichment$second_pass$status),
    rep("pending_first_pass", 3L)
  )
  expect_null(enrichment$second_pass$prompts)
  expect_true(all(grepl("TXT[0-9]{6}", enrichment$selected_texts$text_id)))
})


.catdes_enrichment_mock_response <- function(model, prompt, suffix) {
  data.frame(
    model = model,
    response = paste("mock response", suffix),
    prompt = prompt,
    done = TRUE,
    stringsAsFactors = FALSE
  )
}


test_that("generated CATDES enrichment preserves both passes in joint mode", {
  data(atomic_habit_clust, package = "NaileR")
  calls <- character()

  testthat::local_mocked_bindings(
    .call_llm_base = function(provider, model, prompt, output, llm_api_options) {
      calls <<- c(calls, prompt)
      .catdes_enrichment_mock_response(model, prompt, length(calls))
    },
    .package = "NaileR"
  )

  result <- nail_catdes(
    atomic_habit_clust,
    num.var = 51,
    num.textual = 31,
    isolate.groups = FALSE,
    generate = TRUE
  )
  enrichment <- nail_catdes_enrichment(result)

  expect_length(calls, 2L)
  expect_identical(nail_response(result, print = FALSE), "mock response 1")
  expect_identical(enrichment$first_pass$responses$portfolio, "mock response 1")
  expect_identical(enrichment$second_pass$responses$portfolio, "mock response 2")
  expect_identical(enrichment$second_pass$status, c(portfolio = "generated"))
  expect_identical(enrichment$first_pass$prompts$portfolio, calls[[1L]])
  expect_identical(enrichment$second_pass$prompts$portfolio, calls[[2L]])
  expect_match(calls[[2L]], "mock response 1", fixed = TRUE)
  expect_match(calls[[2L]], "TXT", fixed = TRUE)
  expect_identical(attr(result, "catdes_settings")$llm_calls, 2L)
})


test_that("isolated CATDES enrichment uses two calls per eligible group", {
  data(atomic_habit_clust, package = "NaileR")
  calls <- character()

  testthat::local_mocked_bindings(
    .call_llm_base = function(provider, model, prompt, output, llm_api_options) {
      calls <<- c(calls, prompt)
      .catdes_enrichment_mock_response(model, prompt, length(calls))
    },
    .package = "NaileR"
  )

  result <- nail_catdes(
    atomic_habit_clust,
    num.var = 51,
    num.textual = 31,
    isolate.groups = TRUE,
    generate = TRUE
  )
  enrichment <- nail_catdes_enrichment(result)

  expect_length(calls, 6L)
  expect_length(enrichment$first_pass$responses, 3L)
  expect_length(enrichment$second_pass$responses, 3L)
  expect_true(all(enrichment$second_pass$status == "generated"))
  expect_identical(attr(result, "catdes_settings")$llm_calls, 6L)
})


test_that("a failed second pass preserves the first pass and its status", {
  data(atomic_habit_clust, package = "NaileR")
  calls <- 0L

  testthat::local_mocked_bindings(
    .call_llm_base = function(provider, model, prompt, output, llm_api_options) {
      calls <<- calls + 1L
      if (calls == 2L) {
        stop("simulated enrichment failure")
      }
      .catdes_enrichment_mock_response(model, prompt, calls)
    },
    .package = "NaileR"
  )

  result <- nail_catdes(
    atomic_habit_clust,
    num.var = 51,
    num.textual = 31,
    isolate.groups = FALSE,
    generate = TRUE
  )
  enrichment <- nail_catdes_enrichment(result)

  expect_identical(calls, 2L)
  expect_identical(enrichment$first_pass$responses$portfolio, "mock response 1")
  expect_identical(
    enrichment$second_pass$status,
    c(portfolio = "generation_failed")
  )
  expect_match(
    enrichment$second_pass$errors$portfolio,
    "simulated enrichment failure",
    fixed = TRUE
  )
})


test_that("a failed first pass cannot trigger textual enrichment", {
  data(atomic_habit_clust, package = "NaileR")
  calls <- 0L

  testthat::local_mocked_bindings(
    .call_llm_base = function(...) {
      calls <<- calls + 1L
      stop("simulated first-pass failure")
    },
    .package = "NaileR"
  )

  expect_error(
    nail_catdes(
      atomic_habit_clust,
      num.var = 51,
      num.textual = 31,
      isolate.groups = FALSE,
      generate = TRUE
    ),
    "simulated first-pass failure",
    fixed = TRUE
  )
  expect_identical(calls, 1L)
})


test_that("textual enrichment rejects prepared x objects and empty text columns", {
  data(atomic_habit_clust, package = "NaileR")
  prepared <- nail_catdes(
    atomic_habit_clust[, -31, drop = FALSE],
    num.var = 50,
    generate = FALSE
  )

  expect_error(
    nail_catdes(x = prepared, num.textual = 31),
    "requires the raw `dataset` interface",
    fixed = TRUE
  )
  empty_text <- atomic_habit_clust
  empty_text$car_alone_text <- ""
  expect_error(
    nail_catdes(empty_text, num.var = 51, num.textual = 31),
    "No non-empty textual responses",
    fixed = TRUE
  )
})


.catdes_textual_selected_ids <- function(x) {
  lapply(
    nail_catdes_enrichment(x)$interpretation_input$groups,
    function(group) group$selected_text_ids
  )
}


test_that("textual.seed makes selected IDs reproducible without changing RNG state", {
  data(atomic_habit_clust, package = "NaileR")

  set.seed(901)
  before <- .Random.seed
  first <- nail_catdes(
    atomic_habit_clust,
    num.var = 51,
    num.textual = 31,
    textual.sample = 0.2,
    textual.seed = 123,
    generate = FALSE
  )
  after <- .Random.seed
  second <- nail_catdes(
    atomic_habit_clust,
    num.var = 51,
    num.textual = 31,
    textual.sample = 0.2,
    textual.seed = 123,
    generate = FALSE
  )
  different <- nail_catdes(
    atomic_habit_clust,
    num.var = 51,
    num.textual = 31,
    textual.sample = 0.2,
    textual.seed = 456,
    generate = FALSE
  )

  expect_identical(before, after)
  expect_identical(
    .catdes_textual_selected_ids(first),
    .catdes_textual_selected_ids(second)
  )
  expect_false(identical(
    .catdes_textual_selected_ids(first),
    .catdes_textual_selected_ids(different)
  ))
  expect_identical(nail_evidence(first), nail_evidence(second))
  expect_identical(
    nail_catdes_enrichment(first)$textual_evidence,
    nail_catdes_enrichment(second)$textual_evidence
  )
  expect_identical(
    nail_catdes_enrichment(first)$settings$textual_seed,
    123
  )
})


test_that("preview and simulated generation share a seeded selection", {
  data(atomic_habit_clust, package = "NaileR")
  preview <- nail_catdes(
    atomic_habit_clust,
    num.var = 51,
    num.textual = 31,
    textual.sample = 0.2,
    textual.seed = 321,
    isolate.groups = FALSE,
    generate = FALSE
  )
  calls <- character()
  options_seen <- list()

  testthat::local_mocked_bindings(
    .call_llm_base = function(provider, model, prompt, output, llm_api_options) {
      calls <<- c(calls, prompt)
      options_seen[[length(options_seen) + 1L]] <<- llm_api_options
      data.frame(
        model = model,
        response = paste("mock", length(calls)),
        prompt = prompt,
        done = TRUE,
        stringsAsFactors = FALSE
      )
    },
    .package = "NaileR"
  )
  generated <- nail_catdes(
    atomic_habit_clust,
    num.var = 51,
    num.textual = 31,
    textual.sample = 0.2,
    textual.seed = 321,
    isolate.groups = FALSE,
    max_tries = 1L,
    generate = TRUE
  )

  expect_identical(
    .catdes_textual_selected_ids(preview),
    .catdes_textual_selected_ids(generated)
  )
  expect_identical(
    nail_catdes_enrichment(preview)$selected_texts,
    nail_catdes_enrichment(generated)$selected_texts
  )
  expect_length(calls, 2L)
  expect_true(all(vapply(options_seen, function(x) {
    !"textual.seed" %in% names(x)
  }, logical(1))))
})


test_that("seeded selection is identical in local and joint modes", {
  data(atomic_habit_clust, package = "NaileR")
  local <- nail_catdes(
    atomic_habit_clust,
    num.var = 51,
    num.textual = 31,
    textual.sample = 0.2,
    textual.seed = 789,
    isolate.groups = TRUE,
    generate = FALSE
  )
  joint <- nail_catdes(
    atomic_habit_clust,
    num.var = 51,
    num.textual = 31,
    textual.sample = 0.2,
    textual.seed = 789,
    isolate.groups = FALSE,
    generate = FALSE
  )

  expect_identical(
    .catdes_textual_selected_ids(local),
    .catdes_textual_selected_ids(joint)
  )
  expect_identical(nail_evidence(local), nail_evidence(joint))
})


test_that("textual.seed handles full samples, missing comments, and edge groups", {
  data(atomic_habit_clust, package = "NaileR")

  full <- nail_catdes(
    atomic_habit_clust,
    num.var = 51,
    num.textual = 31,
    textual.sample = 1,
    textual.seed = 12,
    generate = FALSE
  )
  full_enrichment <- nail_catdes_enrichment(full)
  expect_identical(
    full_enrichment$interpretation_input$groups[["1"]]$selected_text_ids,
    full_enrichment$textual_evidence$groups[["1"]]$text_ids
  )

  missing <- atomic_habit_clust
  missing$car_alone_text[missing$clust == "1"] <- ""
  local_missing <- nail_catdes(
    missing,
    num.var = 51,
    num.textual = 31,
    textual.sample = 0.5,
    textual.seed = 12,
    isolate.groups = TRUE,
    generate = FALSE
  )
  missing_enrichment <- nail_catdes_enrichment(local_missing)
  expect_identical(
    missing_enrichment$interpretation_input$groups[["1"]]$status,
    "no_texts"
  )
  expect_length(
    missing_enrichment$interpretation_input$groups[["1"]]$selected_text_ids,
    0L
  )
  expect_gt(
    missing_enrichment$interpretation_input$groups[["2"]]$metrics$n_shown_texts,
    0L
  )

  expect_error(
    nail_catdes(
      atomic_habit_clust,
      num.var = 51,
      num.textual = 31,
      textual.sample = 0.5,
      textual.seed = "not-a-seed",
      generate = FALSE
    ),
    "textual.seed",
    fixed = TRUE
  )
})
