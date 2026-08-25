make_textual_semantic_test_data <- function() {
  data.frame(
    group = factor(
      c("A", "A", "A", "A", "B", "B", "B", "B"),
      levels = c("A", "B")
    ),
    text = c(
      "I value travel but would reduce flights when alternatives are practical.",
      "Train travel is preferable when time and cost allow it.",
      "Family abroad makes complete avoidance of flying difficult.",
      "",
      "I already avoid flying and prefer nearby destinations.",
      "Slow travel by train is part of the experience for me.",
      "I rarely fly, although some distant trips may still require it.",
      NA_character_
    ),
    stringsAsFactors = FALSE
  )
}


mock_textual_response <- function(prompt) {
  ids <- regmatches(
    prompt,
    gregexpr("TXT[0-9]{6}", prompt, perl = TRUE)
  )[[1L]]
  ids <- unique(ids)

  representative <- ids[[1L]]
  tension <- if (length(ids) >= 2L) ids[[2L]] else "none"

  paste(
    "Core textual profile:",
    "The group shares a pragmatic discourse about reducing flying while recognizing practical constraints.",
    "",
    "Dominant themes:",
    "travel constraints; alternatives to flying; selective reduction",
    "",
    "Within-group coherence:",
    "moderate",
    "",
    "Internal diversity:",
    "Members vary in how far they are willing or able to avoid flying.",
    "",
    "Representative text IDs:",
    representative,
    "",
    "Tension text IDs:",
    tension,
    sep = "\n"
  )
}


test_that("textual_evidence is canonical, complete, and mechanically traceable", {
  dat <- make_textual_semantic_test_data()

  x <- nail_textual(
    dat,
    num.var = 1,
    num.text = 2,
    generate = FALSE
  )

  evidence <- attr(x, "textual_evidence", exact = TRUE)

  expect_s3_class(evidence, "nail_textual_evidence")
  expect_named(evidence$groups, c("A", "B"))
  expect_true(is.data.frame(evidence$text_registry))
  expect_identical(
    names(evidence$text_registry),
    c("text_id", "group", "source_row", "text")
  )
  expect_identical(anyDuplicated(evidence$text_registry$text_id), 0L)

  expect_identical(
    evidence$text_registry$text_id,
    sprintf("TXT%06d", c(1L, 2L, 3L, 5L, 6L, 7L))
  )

  expect_identical(evidence$groups$A$metrics$n_group_rows, 4L)
  expect_identical(evidence$groups$A$metrics$n_texts, 3L)
  expect_equal(evidence$groups$A$metrics$response_rate, 0.75)
  expect_identical(evidence$groups$A$metrics$n_unique_texts, 3L)

  expect_identical(evidence$groups$B$metrics$n_group_rows, 4L)
  expect_identical(evidence$groups$B$metrics$n_texts, 3L)
  expect_equal(evidence$groups$B$metrics$response_rate, 0.75)
})


test_that("textual_evidence is invariant to interpretation options", {
  dat <- make_textual_semantic_test_data()

  x1 <- nail_textual(
    dat,
    num.var = 1,
    num.text = 2,
    isolate.groups = TRUE,
    sample.pct = 1,
    seed = 1,
    prompt_style = "detailed",
    text_role = "responses",
    generate = FALSE
  )

  x2 <- nail_textual(
    dat,
    num.var = 1,
    num.text = 2,
    isolate.groups = FALSE,
    sample.pct = 0.5,
    seed = 999,
    prompt_style = "compact",
    text_role = "verbatims",
    generate = FALSE
  )

  expect_identical(
    attr(x1, "textual_evidence", exact = TRUE),
    attr(x2, "textual_evidence", exact = TRUE)
  )
})


test_that("interpretation_input records only what the LLM sees", {
  dat <- make_textual_semantic_test_data()

  x <- nail_textual(
    dat,
    num.var = 1,
    num.text = 2,
    sample.pct = 0.5,
    seed = 123,
    generate = FALSE
  )

  evidence <- attr(x, "textual_evidence", exact = TRUE)
  input <- attr(x, "interpretation_input", exact = TRUE)

  expect_s3_class(input, "nail_textual_interpretation_input")

  for (g in names(input$groups)) {
    selected <- input$groups[[g]]$selected_text_ids
    available <- evidence$groups[[g]]$text_ids

    expect_true(all(selected %in% available))
    expect_identical(input$groups[[g]]$metrics$n_available_texts, 3L)
    expect_identical(input$groups[[g]]$metrics$n_shown_texts, 2L)
    expect_equal(
      input$groups[[g]]$metrics$interpretation_coverage,
      2 / 3
    )
  }

  x2 <- nail_textual(
    dat,
    num.var = 1,
    num.text = 2,
    sample.pct = 0.5,
    seed = 123,
    generate = FALSE
  )

  expect_identical(
    attr(x, "interpretation_input", exact = TRUE),
    attr(x2, "interpretation_input", exact = TRUE)
  )
})


test_that("textual prompts are local-first and preserve user instructions", {
  dat <- make_textual_semantic_test_data()

  x <- nail_textual(
    dat,
    num.var = 1,
    num.text = 2,
    introduction = "USER INTRODUCTION SENTINEL",
    request = "USER REQUEST SENTINEL",
    isolate.groups = TRUE,
    generate = FALSE
  )

  prompt_a <- nail_prompt(x, select = "A", print = FALSE)

  expect_match(prompt_a, "USER INTRODUCTION SENTINEL", fixed = TRUE)
  expect_match(prompt_a, "USER REQUEST SENTINEL", fixed = TRUE)
  expect_match(prompt_a, '## Group "A"', fixed = TRUE)
  expect_false(grepl('## Group "B"', prompt_a, fixed = TRUE))

  ids_a <- attr(x, "interpretation_input", exact = TRUE)$groups$A$selected_text_ids
  expect_true(all(vapply(
    ids_a,
    function(id) grepl(id, prompt_a, fixed = TRUE),
    logical(1)
  )))
})


test_that("isolate.groups = FALSE still performs local-first generation", {
  dat <- make_textual_semantic_test_data()
  counter <- new.env(parent = emptyenv())
  counter$n <- 0L

  testthat::local_mocked_bindings(
    .call_llm_base = function(provider,
                              model,
                              prompt,
                              output,
                              llm_api_options) {
      counter$n <- counter$n + 1L
      data.frame(
        model = model,
        response = mock_textual_response(prompt),
        stringsAsFactors = FALSE
      )
    },
    .package = "NaileR"
  )

  x <- nail_textual(
    dat,
    num.var = 1,
    num.text = 2,
    isolate.groups = FALSE,
    generate = TRUE,
    model = "mock-model"
  )

  expect_identical(counter$n, 2L)
  expect_true(is.data.frame(x))

  settings <- attr(x, "textual_settings", exact = TRUE)
  expect_identical(settings$generation_architecture, "local_first")
  expect_false(settings$global_synthesis_performed)
  expect_identical(settings$llm_calls, 2L)
})


test_that("default generation creates canonical textual_profiles", {
  dat <- make_textual_semantic_test_data()

  testthat::local_mocked_bindings(
    .call_llm_base = function(provider,
                              model,
                              prompt,
                              output,
                              llm_api_options) {
      data.frame(
        model = model,
        response = mock_textual_response(prompt),
        stringsAsFactors = FALSE
      )
    },
    .package = "NaileR"
  )

  x <- nail_textual(
    dat,
    num.var = 1,
    num.text = 2,
    isolate.groups = TRUE,
    generate = TRUE,
    model = "mock-model"
  )

  profiles <- attr(x, "textual_profiles", exact = TRUE)

  expect_s3_class(profiles, "nail_textual_profiles")
  expect_named(profiles$groups, c("A", "B"))

  for (g in names(profiles$groups)) {
    profile <- profiles$groups[[g]]

    expect_identical(profile$status, "available")
    expect_true(nzchar(profile$core_textual_profile))
    expect_gt(length(profile$dominant_themes), 0L)
    expect_identical(profile$within_group_coherence, "moderate")
    expect_true(nzchar(profile$internal_diversity))

    allowed <- attr(
      x,
      "interpretation_input",
      exact = TRUE
    )$groups[[g]]$selected_text_ids

    expect_true(all(profile$representative_text_ids %in% allowed))
    expect_true(all(profile$tension_text_ids %in% allowed))
  }
})


test_that("hallucinated text IDs make the canonical profile parse_failed", {
  dat <- make_textual_semantic_test_data()

  testthat::local_mocked_bindings(
    .call_llm_base = function(provider,
                              model,
                              prompt,
                              output,
                              llm_api_options) {
      data.frame(
        model = model,
        response = paste(
          "Core textual profile:",
          "A coherent summary.",
          "",
          "Dominant themes:",
          "theme one; theme two",
          "",
          "Within-group coherence:",
          "moderate",
          "",
          "Internal diversity:",
          "Some variation is present.",
          "",
          "Representative text IDs:",
          "TXT999999",
          "",
          "Tension text IDs:",
          "none",
          sep = "\n"
        ),
        stringsAsFactors = FALSE
      )
    },
    .package = "NaileR"
  )

  x <- nail_textual(
    dat,
    num.var = 1,
    num.text = 2,
    isolate.groups = TRUE,
    generate = TRUE
  )

  profiles <- attr(x, "textual_profiles", exact = TRUE)

  expect_identical(profiles$groups$A$status, "parse_failed")
  expect_true(
    "unknown_representative_text_ids" %in%
      profiles$groups$A$parse_issues
  )
})


test_that("canonical llm_io exposes exact textual prompts and raw responses", {
  dat <- make_textual_semantic_test_data()

  testthat::local_mocked_bindings(
    .call_llm_base = function(provider,
                              model,
                              prompt,
                              output,
                              llm_api_options) {
      data.frame(
        model = model,
        response = mock_textual_response(prompt),
        stringsAsFactors = FALSE
      )
    },
    .package = "NaileR"
  )

  x <- nail_textual(
    dat,
    num.var = 1,
    num.text = 2,
    isolate.groups = TRUE,
    generate = TRUE
  )

  io <- attr(x, "llm_io", exact = TRUE)

  expect_s3_class(io, "nail_llm_io")
  expect_identical(io$stage, "interpretation")
  expect_identical(io$metadata$analysis, "nail_textual")
  expect_identical(io$metadata$scope, "group")
  expect_identical(io$metadata$architecture, "local_first")

  expect_identical(
    nail_prompt(x, select = "A", print = FALSE),
    io$prompts$A
  )
  expect_identical(
    nail_response(x, select = "A", print = FALSE),
    io$responses$A
  )
})


test_that("historical textual_data_summary remains available as compatibility view", {
  dat <- make_textual_semantic_test_data()

  x <- nail_textual(
    dat,
    num.var = 1,
    num.text = 2,
    generate = FALSE
  )

  summary <- attr(x, "textual_data_summary", exact = TRUE)

  expect_true(is.list(summary))
  expect_named(summary, c("A", "B"))
  expect_true(all(c(
    "n_texts",
    "median_length",
    "max_length",
    "min_length",
    "evidence_strength"
  ) %in% names(summary$A)))
})


test_that("custom conclusion remains compatible with historical textual_prep prompts", {
  dat <- make_textual_semantic_test_data()

  x <- nail_textual(
    dat,
    num.var = 1,
    num.text = 2,
    isolate.groups = TRUE,
    conclusion = "CUSTOM HISTORICAL OUTPUT SENTINEL",
    generate = FALSE
  )

  expect_match(
    nail_prompt(x, select = "A", print = FALSE),
    "CUSTOM HISTORICAL OUTPUT SENTINEL",
    fixed = TRUE
  )

  settings <- attr(x, "textual_settings", exact = TRUE)
  expect_false(settings$canonical_output_requested)
})


test_that("mixed valid tension IDs and none are parsed without failure", {
  dat <- make_textual_semantic_test_data()

  testthat::local_mocked_bindings(
    .call_llm_base = function(provider,
                              model,
                              prompt,
                              output,
                              llm_api_options) {
      ids <- regmatches(
        prompt,
        gregexpr("TXT[0-9]{6}", prompt, perl = TRUE)
      )[[1L]]
      ids <- unique(ids)

      data.frame(
        model = model,
        response = paste(
          "Core textual profile:",
          "The group shares a common interpretive frame with some variation.",
          "",
          "Dominant themes:",
          "theme one; theme two",
          "",
          "Within-group coherence:",
          "moderate",
          "",
          "Internal diversity:",
          "Some variation is present.",
          "",
          "Representative text IDs:",
          ids[[1L]],
          "",
          "Tension text IDs:",
          paste(ids[[2L]], "none", sep = "; "),
          sep = "\n"
        ),
        stringsAsFactors = FALSE
      )
    },
    .package = "NaileR"
  )

  x <- nail_textual(
    dat,
    num.var = 1,
    num.text = 2,
    isolate.groups = TRUE,
    generate = TRUE
  )

  profile <- attr(x, "textual_profiles", exact = TRUE)$groups$A

  expect_identical(profile$status, "available")
  expect_identical(length(profile$tension_text_ids), 1L)
  expect_false("none" %in% tolower(profile$tension_text_ids))
})
