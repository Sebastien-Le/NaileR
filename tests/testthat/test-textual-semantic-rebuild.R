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


approved_textual_reading <- function() {
  paste(
    "The evidence consists of textual observations associated with one group. These texts are the empirical material for qualitative analysis. Themes and broader interpretations are constructed from the texts by the language model; they are not statistical results calculated beforehand.",
    "",
    "Each text has an identifier linked to a source observation. An observation does not necessarily represent a distinct individual, and identical statements may occur more than once. Preserve the original wording and use the supplied text identifiers when referring to supporting or contrasting evidence. Do not invent quotations.",
    "",
    "Interpret the meaning and strength of each statement carefully, preserving negations, hesitation, qualifications, ambiguity and contradictions. Distinguish expressed opinions, perceptions, intentions, reported experiences and observed behaviors.",
    "",
    "Distinguish recurring ideas in the texts from the prevalence of opinions among individuals. Repetition does not necessarily imply independent agreement or group consensus. Do not invent numerical prevalence estimates.",
    "",
    "Use the study context to understand the responses and the analytical question, without treating it as additional empirical evidence.",
    sep = "\n"
  )
}


approved_textual_interpretation <- function() {
  paste(
    "Identify the main themes expressed in the texts, grouping statements according to their meaning rather than shared vocabulary. Explain their substantive significance in relation to the analytical question.",
    "",
    "Interpret the group's discourse by considering these themes jointly, rather than presenting them as a simple list. When supported by the texts, develop a higher-level interpretation that captures the broader concerns, perspectives or frames of meaning emerging from their combination.",
    "",
    "Examine internal diversity, including differences in emphasis, reservations, ambivalence, contradictions and meaningful minority perspectives. A shared interpretive frame may accommodate different positions, while several distinct or conflicting frames may coexist within the same group.",
    "",
    "Assess whether the discourse exhibits a recognizable common frame. Treat coherence as a qualitative interpretation, not a statistical measure. Do not impose unity when the texts support multiple perspectives or when the evidence is insufficient.",
    "",
    "Adapt the depth of interpretation to the richness and diversity of the texts. Avoid elaborate group-level characterizations from sparse evidence. Do not infer hidden motives, personality traits, social identities or causal mechanisms that the texts do not support.",
    sep = "\n"
  )
}


approved_textual_output <- function() {
  paste(
    "Produce a concise, substantive and evidence-grounded qualitative profile of the group.",
    "",
    "Use exactly the following fields and preserve their names and order:",
    "",
    "Core textual profile:",
    "One concise statement capturing the main configuration of meaning emerging from the discourse.",
    "",
    "Dominant themes:",
    "One to five concise themes, separated by semicolons.",
    "",
    "Within-group coherence:",
    "Choose exactly one: `strong` / `moderate` / `mixed` / `weak`, based on the qualitative organization of the discourse, not numerical recurrence alone.",
    "",
    "Internal diversity:",
    "One concise statement identifying meaningful variations, reservations, tensions or minority perspectives.",
    "",
    "Representative text IDs:",
    "One to three supplied text identifiers supporting the central interpretation, separated by semicolons.",
    "",
    "Tension text IDs:",
    "Zero to three supplied text identifiers illustrating tensions or contrasting perspectives, separated by semicolons, or `none`.",
    "",
    "Do not add other fields or introductory text. Use only supplied text identifiers. Representative texts illustrate an interpretation; they do not establish the prevalence of a theme.",
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


test_that("text_role changes only descriptive data labels and preserves evidence", {
  dat <- make_textual_semantic_test_data()

  by_role <- lapply(
    c("responses", "comments", "verbatims"),
    function(role) {
      nail_textual(
        dat,
        num.var = 1,
        num.text = 2,
        text_role = role,
        generate = FALSE
      )
    }
  )
  names(by_role) <- c("responses", "comments", "verbatims")

  expect_match(
    by_role$responses[[1L]],
    "- Non-empty responses:",
    fixed = TRUE
  )
  expect_match(
    by_role$comments[[1L]],
    "- Non-empty comments:",
    fixed = TRUE
  )
  expect_match(
    by_role$verbatims[[1L]],
    "- Non-empty verbatims:",
    fixed = TRUE
  )
  expect_match(by_role$responses[[1L]], "### Responses", fixed = TRUE)
  expect_match(by_role$comments[[1L]], "### Comments", fixed = TRUE)
  expect_match(by_role$verbatims[[1L]], "### Verbatims", fixed = TRUE)

  expect_identical(
    lapply(
      by_role,
      function(x) attr(x, "textual_evidence", exact = TRUE)
    )[[1L]],
    lapply(
      by_role,
      function(x) attr(x, "textual_evidence", exact = TRUE)
    )[[2L]]
  )
  expect_identical(
    lapply(
      by_role,
      function(x) attr(x, "textual_evidence", exact = TRUE)
    )[[1L]],
    lapply(
      by_role,
      function(x) attr(x, "textual_evidence", exact = TRUE)
    )[[3L]]
  )

  blocks <- lapply(
    by_role,
    function(x) attr(x, "textual_prompt_blocks", exact = TRUE)$A
  )
  expect_identical(blocks$responses$reading, blocks$comments$reading)
  expect_identical(blocks$responses$reading, blocks$verbatims$reading)
  expect_identical(
    blocks$responses$interpretation,
    blocks$comments$interpretation
  )
  expect_identical(
    blocks$responses$interpretation,
    blocks$verbatims$interpretation
  )
  expect_identical(blocks$responses$output, blocks$comments$output)
  expect_identical(blocks$responses$output, blocks$verbatims$output)
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
  expect_match(
    prompt_a,
    "The evidence consists of textual observations associated with one group.",
    fixed = TRUE
  )
  expect_match(
    prompt_a,
    "Interpret the group's discourse by considering these themes jointly",
    fixed = TRUE
  )
  expect_identical(
    attr(x, "textual_prompt_blocks", exact = TRUE)$A$local_task,
    paste(
      'Interpret only the texts associated with group "A", in light of the user\'s analytical request.',
      "Construct a substantive textual profile of this group without describing, comparing or inferring the discourse of other groups.",
      sep = "\n\n"
    )
  )
  expect_match(prompt_a, '## Group "A"', fixed = TRUE)
  expect_false(grepl('## Group "B"', prompt_a, fixed = TRUE))

  ids_a <- attr(x, "interpretation_input", exact = TRUE)$groups$A$selected_text_ids
  expect_true(all(vapply(
    ids_a,
    function(id) grepl(id, prompt_a, fixed = TRUE),
    logical(1)
  )))
})


test_that("textual prompts expose ordered semantic blocks", {
  dat <- make_textual_semantic_test_data()

  x <- nail_textual(
    dat,
    num.var = 1,
    num.text = 2,
    isolate.groups = TRUE,
    generate = FALSE
  )

  blocks <- attr(x, "textual_prompt_blocks", exact = TRUE)
  expect_named(blocks, c("A", "B"))
  expect_named(
    blocks$A,
    c(
      "context",
      "reading",
      "question",
      "interpretation",
      "local_task",
      "evidence",
      "output"
    )
  )
  expect_true(all(vapply(blocks$A, is.character, logical(1))))

  prompt_a <- nail_prompt(x, select = "A", print = FALSE)
  headings <- c(
    "# Introduction",
    "## How to Read the Textual Evidence",
    "# Overall Analytical Request",
    "## Interpretation Rules",
    "# Local Task",
    "# Data",
    "# Required output"
  )
  positions <- vapply(
    headings,
    function(heading) regexpr(heading, prompt_a, fixed = TRUE)[[1L]],
    integer(1)
  )
  expect_true(all(positions > 0L))
  expect_true(all(diff(positions) > 0L))

  expect_identical(blocks$A$reading, approved_textual_reading())
  expect_identical(
    blocks$A$interpretation,
    approved_textual_interpretation()
  )
  expect_match(blocks$A$local_task, 'group "A"', fixed = TRUE)
  expect_false(grepl('## Group "B"', blocks$A$evidence, fixed = TRUE))
  expect_true(
    regexpr("# Required output", prompt_a, fixed = TRUE)[[1L]] >
      regexpr("# Data", prompt_a, fixed = TRUE)[[1L]]
  )
})


test_that("approved textual blocks are identical in detailed and compact styles", {
  dat <- make_textual_semantic_test_data()

  detailed <- nail_textual(
    dat,
    num.var = 1,
    num.text = 2,
    prompt_style = "detailed",
    generate = FALSE
  )
  compact <- nail_textual(
    dat,
    num.var = 1,
    num.text = 2,
    prompt_style = "compact",
    generate = FALSE
  )

  detailed_blocks <- attr(
    detailed,
    "textual_prompt_blocks",
    exact = TRUE
  )$A
  compact_blocks <- attr(
    compact,
    "textual_prompt_blocks",
    exact = TRUE
  )$A

  expect_identical(detailed_blocks$reading, approved_textual_reading())
  expect_identical(
    detailed_blocks$interpretation,
    approved_textual_interpretation()
  )
  expect_identical(detailed_blocks$output, approved_textual_output())
  expect_identical(compact_blocks$reading, detailed_blocks$reading)
  expect_identical(
    compact_blocks$interpretation,
    detailed_blocks$interpretation
  )
  expect_identical(compact_blocks$output, detailed_blocks$output)
  expect_match(
    nail_prompt(detailed, select = "A", print = FALSE),
    "# Required output",
    fixed = TRUE
  )
})


test_that("textual default blocks support ablation without changing evidence", {
  dat <- make_textual_semantic_test_data()
  args <- list(
    dataset = dat,
    num.var = 1,
    num.text = 2,
    isolate.groups = TRUE,
    sample.pct = 0.5,
    seed = 123,
    generate = FALSE
  )

  conditions <- list(
    M = character(0),
    R = "reading",
    I = "interpretation",
    L = "local_task",
    RI = c("reading", "interpretation"),
    RL = c("reading", "local_task"),
    IL = c("interpretation", "local_task"),
    F = c("reading", "interpretation", "local_task")
  )
  results <- lapply(
    conditions,
    function(default_blocks) {
      do.call(
        nail_textual,
        c(args, list(default_blocks = default_blocks))
      )
    }
  )

  reference <- results$M
  full_blocks <- attr(results$F, "textual_prompt_blocks", exact = TRUE)$A
  minimal_blocks <- attr(results$M, "textual_prompt_blocks", exact = TRUE)$A
  reading_blocks <- attr(results$R, "textual_prompt_blocks", exact = TRUE)$A
  interpretation_blocks <- attr(
    results$I,
    "textual_prompt_blocks",
    exact = TRUE
  )$A
  local_task_blocks <- attr(
    results$L,
    "textual_prompt_blocks",
    exact = TRUE
  )$A

  expect_true(all(vapply(full_blocks, is.character, logical(1))))
  expect_true(all(vapply(minimal_blocks[c("context", "question", "evidence", "output")], is.character, logical(1))))
  expect_null(minimal_blocks$reading)
  expect_null(minimal_blocks$interpretation)
  expect_null(minimal_blocks$local_task)
  expect_true(is.character(reading_blocks$reading))
  expect_null(reading_blocks$interpretation)
  expect_null(reading_blocks$local_task)
  expect_true(is.character(interpretation_blocks$interpretation))
  expect_null(interpretation_blocks$reading)
  expect_null(interpretation_blocks$local_task)
  expect_true(is.character(local_task_blocks$local_task))
  expect_null(local_task_blocks$reading)
  expect_null(local_task_blocks$interpretation)

  for (condition_name in names(results)) {
    result <- results[[condition_name]]
    expect_identical(
      attr(result, "textual_evidence", exact = TRUE),
      attr(reference, "textual_evidence", exact = TRUE),
      info = condition_name
    )
    expect_identical(
      attr(result, "interpretation_input", exact = TRUE),
      attr(reference, "interpretation_input", exact = TRUE),
      info = condition_name
    )
    expect_identical(
      attr(result, "textual_data_summary", exact = TRUE),
      attr(reference, "textual_data_summary", exact = TRUE),
      info = condition_name
    )
    expect_identical(
      nail_evidence(result),
      nail_evidence(reference),
      info = condition_name
    )

    for (group_name in names(
      attr(reference, "interpretation_input", exact = TRUE)$groups
    )) {
      expect_identical(
        attr(result, "interpretation_input", exact = TRUE)$groups[[group_name]]$selected_text_ids,
        attr(reference, "interpretation_input", exact = TRUE)$groups[[group_name]]$selected_text_ids,
        info = paste(condition_name, group_name, sep = ":")
      )
    }
  }
})


test_that("textual default blocks validate names, duplicates, and missing values", {
  dat <- make_textual_semantic_test_data()

  expect_error(
    nail_textual(dat, 1, 2, default_blocks = "banana"),
    "Unknown TEXTUAL default block"
  )
  expect_error(
    nail_textual(dat, 1, 2, default_blocks = c("reading", "reading")),
    "must not contain duplicate"
  )
  expect_error(
    nail_textual(dat, 1, 2, default_blocks = NA_character_),
    "without NA"
  )
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


test_that("identical mock responses preserve parsed textual profiles across block ablation", {
  dat <- make_textual_semantic_test_data()

  build <- function(default_blocks) {
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

    nail_textual(
      dat,
      num.var = 1,
      num.text = 2,
      isolate.groups = TRUE,
      generate = TRUE,
      model = "mock-model",
      default_blocks = default_blocks
    )
  }

  full <- build(c("reading", "interpretation", "local_task"))
  minimal <- build(character(0))

  full_profiles <- attr(full, "textual_profiles", exact = TRUE)
  minimal_profiles <- attr(minimal, "textual_profiles", exact = TRUE)
  parsed_fields <- c(
    "group",
    "status",
    "core_textual_profile",
    "dominant_themes",
    "within_group_coherence",
    "internal_diversity",
    "representative_text_ids",
    "tension_text_ids",
    "parse_issues"
  )

  expect_identical(
    lapply(
      full_profiles$groups,
      function(group) group[intersect(parsed_fields, names(group))]
    ),
    lapply(
      minimal_profiles$groups,
      function(group) group[intersect(parsed_fields, names(group))]
    )
  )
  expect_identical(
    nail_response(full, select = "A", print = FALSE),
    nail_response(minimal, select = "A", print = FALSE)
  )
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
  expect_identical(
    attr(x, "textual_prompt_blocks", exact = TRUE)$A$output,
    "CUSTOM HISTORICAL OUTPUT SENTINEL"
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


test_that("empty groups remain no_texts without an invented profile", {
  dat <- data.frame(
    group = factor(c("A", "B", "C"), levels = c("A", "B", "C")),
    text = c("A substantive response.", "", ""),
    stringsAsFactors = FALSE
  )

  x <- nail_textual(
    dat,
    num.var = 1,
    num.text = 2,
    isolate.groups = TRUE,
    generate = FALSE
  )

  profiles <- attr(x, "textual_profiles", exact = TRUE)
  input <- attr(x, "interpretation_input", exact = TRUE)

  expect_named(profiles$groups, c("A", "B", "C"))
  expect_identical(profiles$groups$B$status, "no_texts")
  expect_identical(profiles$groups$C$status, "no_texts")
  expect_length(profiles$groups$B$selected_text_ids, 0L)
  expect_length(profiles$groups$C$selected_text_ids, 0L)
  expect_identical(input$groups$C$status, "no_texts")
  expect_match(
    nail_prompt(x, select = "C", print = FALSE),
    "Do not invent a textual profile for it.",
    fixed = TRUE
  )
})


test_that("textual prep keeps its distinct output contract after shared blocks", {
  dat <- make_textual_semantic_test_data()

  with_cues <- nail_textual_prep(
    dat,
    num.var = 1,
    num.text = 2,
    include_verbatims_in_prompt = TRUE,
    generate = FALSE
  )
  without_cues <- nail_textual_prep(
    dat,
    num.var = 1,
    num.text = 2,
    include_verbatims_in_prompt = FALSE,
    generate = FALSE
  )

  expect_named(with_cues, c("A", "B"))
  expect_named(without_cues, c("A", "B"))
  expect_match(
    with_cues$A,
    "The evidence consists of textual observations associated with one group.",
    fixed = TRUE
  )
  expect_match(with_cues$A, "Main themes:", fixed = TRUE)
  expect_match(with_cues$A, "Central verbatim cues:", fixed = TRUE)
  expect_match(with_cues$A, "Tension verbatim cues:", fixed = TRUE)
  expect_false(grepl("Central verbatim cues:", without_cues$A, fixed = TRUE))
  expect_false(grepl("Tension verbatim cues:", without_cues$A, fixed = TRUE))
  expect_match(without_cues$A, "Injectable summary:", fixed = TRUE)
})


test_that("textual prep generation separates generated cues from selected verbatims", {
  dat <- make_textual_semantic_test_data()

  mock_prep_response <- paste(
    "Core textual profile:",
    "The group combines practical support with reservations.",
    "",
    "Main themes:",
    "practical alternatives; constraints",
    "",
    "Dominant concerns or motives:",
    "feasibility; selective change",
    "",
    "Tone or stance:",
    "ambivalent",
    "",
    "Intra-group consistency:",
    "moderate",
    "",
    "Injectable summary:",
    "The group supports selective change under practical constraints.",
    "",
    "Central verbatim cues:",
    "generated central cue",
    "",
    "Tension verbatim cues:",
    "generated tension cue",
    sep = "\n"
  )

  testthat::local_mocked_bindings(
    .call_llm_base = function(provider,
                              model,
                              prompt,
                              output,
                              llm_api_options) {
      data.frame(
        model = model,
        response = mock_prep_response,
        stringsAsFactors = FALSE
      )
    },
    .package = "NaileR"
  )

  with_cues <- nail_textual_prep(
    dat,
    num.var = 1,
    num.text = 2,
    include_verbatims_in_prompt = TRUE,
    generate = TRUE,
    model = "mock-model"
  )
  without_cues <- nail_textual_prep(
    dat,
    num.var = 1,
    num.text = 2,
    include_verbatims_in_prompt = FALSE,
    generate = TRUE,
    model = "mock-model"
  )

  expect_named(
    with_cues$A$parsed,
    c(
      "core_textual_profile",
      "main_themes",
      "dominant_concerns",
      "tone_or_stance",
      "intra_group_consistency",
      "intra_group_consistency_raw",
      "injectable_summary",
      "central_verbatim_cues",
      "tension_verbatim_cues"
    )
  )
  expect_length(with_cues$A$parsed$central_verbatim_cues, 1L)
  expect_length(with_cues$A$parsed$tension_verbatim_cues, 1L)
  expect_length(without_cues$A$parsed$central_verbatim_cues, 0L)
  expect_length(without_cues$A$parsed$tension_verbatim_cues, 0L)
  expect_true(
    all(
      c("generated central cue", "generated tension cue") %in%
        c(
          with_cues$A$parsed$central_verbatim_cues,
          with_cues$A$parsed$tension_verbatim_cues
        )
    )
  )
  expect_false(
    any(
      c("generated central cue", "generated tension cue") %in%
        c(
          with_cues$A$selected_verbatims$central,
          with_cues$A$selected_verbatims$tension
        )
    )
  )
  expect_match(with_cues$A$prompt, "Central verbatim cues:", fixed = TRUE)
  expect_false(grepl("Central verbatim cues:", without_cues$A$prompt, fixed = TRUE))
})
