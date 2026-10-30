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
  expect_identical(
    nail_prompt(preview, print = FALSE),
    enrichment$first_pass$prompts
  )
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
  expect_identical(nail_response(result, print = FALSE), "mock response 2")
  expect_identical(
    nail_prompt(result, print = FALSE),
    enrichment$second_pass$prompts$portfolio
  )
  expect_identical(enrichment$first_pass$responses$portfolio, "mock response 1")
  expect_identical(enrichment$second_pass$responses$portfolio, "mock response 2")
  expect_identical(enrichment$second_pass$status, c(portfolio = "generated"))
  expect_identical(enrichment$first_pass$prompts$portfolio, calls[[1L]])
  expect_identical(enrichment$second_pass$prompts$portfolio, calls[[2L]])
  expect_match(calls[[2L]], "mock response 1", fixed = TRUE)
  expect_match(calls[[2L]], "TXT", fixed = TRUE)
  expect_identical(attr(result, "catdes_settings")$llm_calls, 2L)
})


test_that("the second pass confronts comments without retransmitting CATDES evidence", {
  data(atomic_habit_clust, package = "NaileR")
  statistical_data <- atomic_habit_clust[, -31, drop = FALSE]
  baseline <- nail_catdes(statistical_data, num.var = 50, generate = FALSE)
  calls <- character()
  first_response <- paste(
    "First-pass quantitative proposal.",
    "It contains a displayed percentage 67.7% that must remain unchanged.",
    sep = "\n"
  )

  testthat::local_mocked_bindings(
    .call_llm_base = function(provider, model, prompt, output, llm_api_options) {
      calls <<- c(calls, prompt)
      response <- if (length(calls) == 1L) first_response else "second-pass confrontation"
      data.frame(
        model = model,
        response = response,
        prompt = prompt,
        done = TRUE,
        stringsAsFactors = FALSE
      )
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
  second_prompt <- calls[[2L]]

  expect_false(grepl("# Canonical CATDES evidence", second_prompt, fixed = TRUE))
  expect_false(grepl(
    "The following statistical statements are the canonical CATDES evidence",
    second_prompt,
    fixed = TRUE
  ))
  old_block <- getFromNamespace(
    ".catdes_textual_evidence_block",
    "NaileR"
  )(
    attr(result, "semantic_facing_evidence"),
    names(attr(result, "semantic_facing_evidence")$groups)
  )
  expect_false(grepl(old_block, second_prompt, fixed = TRUE))

  initial_start <- regexpr(
    "# Initial CATDES interpretation",
    second_prompt,
    fixed = TRUE
  )[1L]
  comments_start <- regexpr(
    "# Selected textual comments",
    second_prompt,
    fixed = TRUE
  )[1L]
  initial_section <- substring(second_prompt, initial_start, comments_start - 1L)
  expect_match(initial_section, first_response, fixed = TRUE)

  expected_comments <- getFromNamespace(
    ".textual_joint_data_block",
    "NaileR"
  )(
    enrichment$textual_evidence,
    enrichment$interpretation_input
  )
  expect_match(second_prompt, expected_comments, fixed = TRUE)
  expect_identical(nail_evidence(result), nail_evidence(baseline))
  expect_identical(
    enrichment$first_pass$responses$portfolio,
    first_response
  )
})


test_that("isolated second-pass prompts contain only their group's comments", {
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
  group_names <- names(enrichment$interpretation_input$groups)
  expect_length(calls, 6L)

  for (index in seq_along(group_names)) {
    group_name <- group_names[[index]]
    second_prompt <- calls[[length(group_names) + index]]
    expected_group_comments <- getFromNamespace(
      ".textual_group_data_block",
      "NaileR"
    )(
      enrichment$textual_evidence,
      enrichment$interpretation_input,
      group_name
    )
    expect_match(second_prompt, expected_group_comments, fixed = TRUE)
    expect_false(grepl("# Canonical CATDES evidence", second_prompt, fixed = TRUE))

    other_ids <- enrichment$selected_texts$text_id[
      enrichment$selected_texts$group != group_name
    ]
    expect_false(any(vapply(
      other_ids,
      function(text_id) grepl(text_id, second_prompt, fixed = TRUE),
      logical(1)
    )))
  }
})


test_that("a generated enrichment cannot hide a missing or invalid second prompt", {
  data(atomic_habit_clust, package = "NaileR")

  testthat::local_mocked_bindings(
    .call_llm_base = function(provider, model, prompt, output, llm_api_options) {
      .catdes_enrichment_mock_response(model, prompt, 1L)
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

  enrichment$second_pass$prompts <- NULL
  attr(result, "catdes_textual_enrichment") <- enrichment
  expect_error(
    nail_prompt(result, print = FALSE),
    "second-pass prompt.*will not fall back",
    perl = TRUE
  )

  enrichment$second_pass$prompts <- list(portfolio = "")
  attr(result, "catdes_textual_enrichment") <- enrichment
  expect_error(
    nail_prompt(result, print = FALSE),
    "prompts are malformed or invalid.*will not fall back",
    perl = TRUE
  )
})


test_that("missing or invalid second-pass statuses are explicit non-successes", {
  data(atomic_habit_clust, package = "NaileR")

  testthat::local_mocked_bindings(
    .call_llm_base = function(provider, model, prompt, output, llm_api_options) {
      .catdes_enrichment_mock_response(model, prompt, 1L)
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

  for (invalid_status in list(NA_character_, "", "not_a_valid_status")) {
    enrichment$second_pass$status <- c(portfolio = invalid_status)
    attr(result, "catdes_textual_enrichment") <- enrichment
    expected_status <- if (
      is.na(invalid_status) || !nzchar(invalid_status)
    ) "<missing or invalid>" else invalid_status
    expect_error(
      nail_response(result, print = FALSE),
      paste0(
        "will not fall back.*Statuses: portfolio=",
        expected_status
      ),
      perl = TRUE
    )
  }
})


test_that("invalid isolated status keeps explicit group selection safe", {
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
  group_names <- names(enrichment$second_pass$status)
  failed_group <- group_names[[1L]]
  successful_group <- group_names[[2L]]
  enrichment$second_pass$status[[failed_group]] <- NA_character_
  attr(result, "catdes_textual_enrichment") <- enrichment

  expect_error(
    nail_response(result, print = FALSE),
    "will not fall back.*Statuses:",
    perl = TRUE
  )
  expect_error(
    nail_response(result, select = failed_group, print = FALSE),
    "unavailable.*missing or invalid",
    perl = TRUE
  )
  expect_identical(
    nail_response(result, select = successful_group, print = FALSE),
    enrichment$second_pass$responses[[successful_group]]
  )
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
  expect_identical(
    nail_prompt(result, print = FALSE),
    enrichment$second_pass$prompts
  )
  expect_identical(
    nail_response(result, print = FALSE),
    enrichment$second_pass$responses
  )
  expect_identical(
    nail_response(result, select = names(enrichment$second_pass$status)[[1L]],
                  print = FALSE),
    enrichment$second_pass$responses[[1L]]
  )
  expect_identical(attr(result, "catdes_settings")$llm_calls, 6L)
})


test_that("isolated partial enrichment blocks global response but allows a successful selection", {
  data(atomic_habit_clust, package = "NaileR")
  calls <- 0L

  testthat::local_mocked_bindings(
    .call_llm_base = function(provider, model, prompt, output, llm_api_options) {
      calls <<- calls + 1L
      if (calls == 5L) {
        stop("simulated group enrichment failure")
      }
      .catdes_enrichment_mock_response(model, prompt, calls)
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
  group_names <- names(enrichment$second_pass$status)

  expect_equal(calls, 6L)
  expect_true(any(enrichment$second_pass$status == "generation_failed"))
  expect_error(
    nail_response(result, print = FALSE),
    "will not fall back to the first pass"
  )
  successful_group <- group_names[
    enrichment$second_pass$status == "generated"
  ][[1L]]
  failed_group <- group_names[
    enrichment$second_pass$status == "generation_failed"
  ][[1L]]
  expect_identical(
    nail_response(result, select = successful_group, print = FALSE),
    enrichment$second_pass$responses[[successful_group]]
  )
  expect_error(
    nail_response(result, select = failed_group, print = FALSE),
    "unavailable"
  )
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
  expect_error(
    nail_response(result, print = FALSE),
    "will not fall back to the first pass"
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
    provider = "gemini",
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


test_that("CATDES enrichment retry reuses the saved joint prompt only", {
  data(atomic_habit_clust, package = "NaileR")
  calls <- character()
  options_seen <- list()

  testthat::local_mocked_bindings(
    .call_llm_base = function(provider, model, prompt, output, llm_api_options) {
      calls <<- c(calls, prompt)
      options_seen[[length(options_seen) + 1L]] <<- llm_api_options
      if (length(calls) == 2L) stop("temporary second-pass failure")
      .catdes_enrichment_mock_response(model, prompt, length(calls))
    },
    .package = "NaileR"
  )

  result <- nail_catdes(
    atomic_habit_clust,
    num.var = 51,
    num.textual = 31,
    isolate.groups = FALSE,
    provider = "gemini",
    max_tries = 1L,
    generate = TRUE
  )
  before_evidence <- nail_evidence(result)
  before_selected <- nail_catdes_enrichment(result)$selected_texts
  saved_prompt <- nail_catdes_enrichment(result)$second_pass$prompts$portfolio

  retried <- nail_catdes_enrichment_retry(
    result,
    max_tries = 1L,
    timeout = 90
  )
  audit <- nail_catdes_enrichment(retried)

  expect_length(calls, 3L)
  expect_identical(calls[[2L]], saved_prompt)
  expect_identical(calls[[3L]], saved_prompt)
  expect_identical(
    audit$first_pass$responses$portfolio,
    "mock response 1"
  )
  expect_identical(audit$second_pass$status, c(portfolio = "generated"))
  expect_identical(nail_response(retried, print = FALSE), "mock response 3")
  expect_identical(nail_prompt(retried, print = FALSE), saved_prompt)
  expect_identical(nail_evidence(retried), before_evidence)
  expect_identical(audit$selected_texts, before_selected)
  expect_match(
    audit$second_pass$errors$portfolio,
    "temporary second-pass failure",
    fixed = TRUE
  )
  expect_length(audit$second_pass$retry_history, 1L)
  expect_identical(
    audit$second_pass$retry_history[[1L]]$previous_error,
    "temporary second-pass failure"
  )
  expect_identical(options_seen[[3L]]$max_tries, 1L)
  expect_false("textual.seed" %in% names(options_seen[[3L]]))
})


test_that("CATDES enrichment retry relaunches only the failed isolated group", {
  data(atomic_habit_clust, package = "NaileR")
  calls <- character()

  testthat::local_mocked_bindings(
    .call_llm_base = function(provider, model, prompt, output, llm_api_options) {
      calls <<- c(calls, prompt)
      if (length(calls) == 5L) stop("isolated temporary failure")
      .catdes_enrichment_mock_response(model, prompt, length(calls))
    },
    .package = "NaileR"
  )

  result <- nail_catdes(
    atomic_habit_clust,
    num.var = 51,
    num.textual = 31,
    isolate.groups = TRUE,
    provider = "gemini",
    max_tries = 1L,
    generate = TRUE
  )
  before_evidence <- nail_evidence(result)
  before_selected <- nail_catdes_enrichment(result)$selected_texts
  audit_before <- nail_catdes_enrichment(result)
  failed_group <- names(audit_before$second_pass$status)[
    audit_before$second_pass$status == "generation_failed"
  ][[1L]]
  failed_prompt <- audit_before$second_pass$prompts[[failed_group]]
  first_prompts <- audit_before$first_pass$prompts

  retried <- nail_catdes_enrichment_retry(result, max_tries = 1L)
  audit_after <- nail_catdes_enrichment(retried)

  expect_length(calls, 7L)
  expect_identical(calls[[5L]], failed_prompt)
  expect_identical(calls[[7L]], failed_prompt)
  expect_identical(
    unname(calls[seq_len(3L)]),
    unname(unlist(first_prompts, use.names = FALSE))
  )
  expect_true(all(audit_after$second_pass$status == "generated"))
  expect_identical(
    nail_response(retried, select = failed_group, print = FALSE),
    "mock response 7"
  )
  expect_identical(nail_evidence(retried), before_evidence)
  expect_identical(audit_after$selected_texts, before_selected)
  expect_length(audit_after$second_pass$retry_history, 1L)
  expect_identical(
    attr(retried, "catdes_settings")$second_pass_retry_llm_calls,
    1L
  )
})


test_that("CATDES enrichment retry preserves persistent failures and refuses previews", {
  data(atomic_habit_clust, package = "NaileR")
  calls <- 0L

  testthat::local_mocked_bindings(
    .call_llm_base = function(provider, model, prompt, output, llm_api_options) {
      calls <<- calls + 1L
      if (calls >= 2L) stop("persistent provider failure")
      .catdes_enrichment_mock_response(model, prompt, calls)
    },
    .package = "NaileR"
  )

  expect_error(
    nail_catdes_enrichment_retry(
      nail_catdes(
        atomic_habit_clust,
        num.var = 51,
        num.textual = 31,
        generate = FALSE
      )
    ),
    "generated first pass",
    fixed = TRUE
  )

  # The mock fails the second pass and the explicit retry as well.
  result <- nail_catdes(
    atomic_habit_clust,
    num.var = 51,
    num.textual = 31,
    isolate.groups = FALSE,
    provider = "gemini",
    max_tries = 1L,
    generate = TRUE
  )
  retried <- nail_catdes_enrichment_retry(result, max_tries = 1L)
  audit <- nail_catdes_enrichment(retried)

  expect_identical(calls, 3L)
  expect_identical(audit$second_pass$status, c(portfolio = "generation_failed"))
  expect_error(
    nail_response(retried, print = FALSE),
    "will not fall back to the first pass",
    fixed = TRUE
  )
  expect_length(audit$second_pass$retry_history, 1L)
  expect_length(audit$second_pass$error_history$portfolio, 2L)
  expect_match(
    audit$second_pass$error_history$portfolio[[1L]],
    "persistent provider failure",
    fixed = TRUE
  )
  expect_match(
    audit$second_pass$error_history$portfolio[[2L]],
    "persistent provider failure",
    fixed = TRUE
  )
})


test_that("CATDES enrichment retry is idempotent after complete generation", {
  data(atomic_habit_clust, package = "NaileR")
  calls <- 0L

  testthat::local_mocked_bindings(
    .call_llm_base = function(provider, model, prompt, output, llm_api_options) {
      calls <<- calls + 1L
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
  retried <- nail_catdes_enrichment_retry(result)

  expect_identical(retried, result)
  expect_identical(calls, 2L)
})


test_that("CATDES enrichment retry refuses missing or empty saved prompts", {
  data(atomic_habit_clust, package = "NaileR")

  testthat::local_mocked_bindings(
    .call_llm_base = function(provider, model, prompt, output, llm_api_options) {
      .catdes_enrichment_mock_response(model, prompt, 1L)
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

  for (saved_prompts in list(NULL, list(portfolio = ""))) {
    candidate <- result
    candidate_enrichment <- enrichment
    candidate_enrichment$second_pass$status <- c(
      portfolio = "generation_failed"
    )
    candidate_enrichment$second_pass$responses <- NULL
    candidate_enrichment$second_pass$prompts <- saved_prompts
    attr(candidate, "catdes_textual_enrichment") <- candidate_enrichment
    expect_error(
      nail_catdes_enrichment_retry(candidate),
      "retryable CATDES second-pass unit must have a saved non-empty prompt",
      fixed = TRUE
    )
  }
})


test_that("CATDES enrichment retry refuses invalid second-pass statuses", {
  data(atomic_habit_clust, package = "NaileR")

  testthat::local_mocked_bindings(
    .call_llm_base = function(provider, model, prompt, output, llm_api_options) {
      .catdes_enrichment_mock_response(model, prompt, 1L)
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

  for (invalid_status in list(NA_character_, "", "invalid_status")) {
    candidate <- result
    candidate_enrichment <- enrichment
    candidate_enrichment$second_pass$status <- c(portfolio = invalid_status)
    attr(candidate, "catdes_textual_enrichment") <- candidate_enrichment
    expect_error(
      nail_catdes_enrichment_retry(candidate),
      "missing or invalid values",
      fixed = TRUE
    )
  }
})


test_that("CATDES enrichment retry refuses an absent or empty first response", {
  data(atomic_habit_clust, package = "NaileR")

  testthat::local_mocked_bindings(
    .call_llm_base = function(provider, model, prompt, output, llm_api_options) {
      .catdes_enrichment_mock_response(model, prompt, 1L)
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

  for (first_response in list(NULL, "")) {
    candidate <- result
    candidate_enrichment <- enrichment
    candidate_enrichment$first_pass$responses$portfolio <- first_response
    attr(candidate, "catdes_textual_enrichment") <- candidate_enrichment
    expect_error(
      nail_catdes_enrichment_retry(candidate),
      "non-empty first-pass response",
      fixed = TRUE
    )
  }
})


test_that("CATDES enrichment retry uses saved and explicitly overridden backend settings", {
  data(atomic_habit_clust, package = "NaileR")
  calls <- list()

  testthat::local_mocked_bindings(
    .call_llm_base = function(provider, model, prompt, output, llm_api_options) {
      calls[[length(calls) + 1L]] <<- list(
        provider = provider,
        model = model,
        prompt = prompt,
        options = llm_api_options
      )
      if (length(calls) %in% c(2L, 3L)) {
        stop("controlled retry failure")
      }
      .catdes_enrichment_mock_response(model, prompt, length(calls))
    },
    .package = "NaileR"
  )

  result <- nail_catdes(
    atomic_habit_clust,
    num.var = 51,
    num.textual = 31,
    isolate.groups = FALSE,
    provider = "gemini",
    model = "saved-model",
    generate = TRUE
  )
  first_retry <- nail_catdes_enrichment_retry(result, max_tries = 1L)
  second_retry <- nail_catdes_enrichment_retry(
    first_retry,
    provider = "ollama",
    model = "override-model",
    temperature = 0.2
  )
  history <- nail_catdes_enrichment(second_retry)$second_pass$retry_history

  expect_identical(calls[[3L]]$provider, "gemini")
  expect_identical(calls[[3L]]$model, "saved-model")
  expect_identical(calls[[4L]]$provider, "ollama")
  expect_identical(calls[[4L]]$model, "override-model")
  expect_identical(history[[1L]]$provider, "gemini")
  expect_identical(history[[1L]]$model, "saved-model")
  expect_identical(history[[2L]]$provider, "ollama")
  expect_identical(history[[2L]]$model, "override-model")
  expect_identical(calls[[4L]]$options$temperature, 0.2)
})
