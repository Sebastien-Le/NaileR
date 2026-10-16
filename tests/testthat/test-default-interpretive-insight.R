interpretive_insight_sentence <- paste(
  "When the evidence allows it, identify and explain the most informative",
  "insight that emerges from the configuration of findings rather than from",
  "any one finding alone, without presenting that insight as an additional",
  "demonstrated fact."
)

count_fixed_text <- function(text, pattern) {
  sum(lengths(regmatches(text, gregexpr(pattern, text, fixed = TRUE))))
}

strip_default_insight <- function(text) {
  suffix <- paste0("\n\n", interpretive_insight_sentence)
  expect_true(endsWith(text, interpretive_insight_sentence))
  substring(text, 1L, nchar(text) - nchar(suffix))
}

test_that("the shared instruction is exact and default request builders append it once", {
  expect_identical(
    NaileR:::.nail_interpretive_insight_instruction(),
    interpretive_insight_sentence
  )

  requests <- c(
    catdes_standard_global_detailed = NaileR:::build_request_catdes(
      interpretation_mode = "standard",
      isolate_groups = FALSE,
      prompt_style = "detailed"
    ),
    catdes_standard_local_compact = NaileR:::build_request_catdes(
      interpretation_mode = "standard",
      isolate_groups = TRUE,
      prompt_style = "compact"
    ),
    catdes_latent_global_compact = NaileR:::build_request_catdes(
      interpretation_mode = "latent",
      isolate_groups = FALSE,
      prompt_style = "compact"
    ),
    catdes_latent_local_detailed = NaileR:::build_request_catdes(
      interpretation_mode = "latent",
      isolate_groups = TRUE,
      prompt_style = "detailed"
    ),
    condes_standard_detailed = NaileR:::build_request_condes(
      mode = "standard",
      target_concept = "the target concept",
      target_label = "Score",
      prompt_style = "detailed"
    ),
    condes_latent_compact = NaileR:::build_request_condes(
      mode = "latent",
      target_concept = "a meaningful continuum",
      target_label = "Dim1",
      prompt_style = "compact"
    ),
    descfreq_description = NaileR:::build_request_descfreq(
      isolate.groups = FALSE,
      interpretation_mode = "description",
      rows_are_ordered = FALSE,
      explicit_row_labels = FALSE
    ),
    descfreq_comparison_ordered = NaileR:::build_request_descfreq(
      isolate.groups = FALSE,
      interpretation_mode = "comparison",
      rows_are_ordered = TRUE,
      explicit_row_labels = TRUE
    ),
    qda_known_global_detailed = NaileR:::build_request_qda(
      isolate_groups = FALSE,
      prompt_style = "detailed",
      product_knowledge = "known"
    ),
    qda_unknown_local_compact = NaileR:::build_request_qda(
      isolate_groups = TRUE,
      prompt_style = "compact",
      product_knowledge = "unknown"
    ),
    qda_space_sensory = NaileR:::build_request_qda_space("sensory"),
    qda_space_positioning = NaileR:::build_request_qda_space("positioning"),
    qda_space_hybrid = NaileR:::build_request_qda_space("hybrid"),
    textual_detailed = NaileR:::.textual_default_request("detailed"),
    textual_compact = NaileR:::.textual_default_request("compact"),
    catdes_textual = NaileR:::.catdes_textual_default_request()
  )

  appended <- vapply(
    requests,
    NaileR:::.append_nail_default_interpretive_insight,
    character(1)
  )

  expect_true(all(vapply(
    appended,
    function(x) count_fixed_text(x, interpretive_insight_sentence) == 1L,
    logical(1)
  )))
  expect_identical(
    unname(vapply(appended, strip_default_insight, character(1))),
    unname(requests)
  )
})


make_default_insight_condes_data <- function() {
  target <- seq(-2, 2, length.out = 40L)
  data.frame(
    Score = target,
    Aligned = 1.5 * target + 0.12 * sin(seq_along(target) / 2),
    Opposed = -1.2 * target + 0.10 * cos(seq_along(target) / 3),
    Group = factor(rep(c("low", "high"), each = 20L))
  )
}


make_default_insight_textual_data <- function() {
  data.frame(
    group = factor(c("A", "A", "B", "B")),
    text = c("short response", "another response", "different view", "more detail"),
    stringsAsFactors = FALSE
  )
}


make_default_insight_catdes_textual_objects <- function() {
  dat <- data.frame(
    group = factor(rep(c("G1", "G2"), each = 4L)),
    score = c(8, 8.2, 7.8, 8.1, 2, 2.2, 1.8, 2.1),
    choice = factor(rep(c("high", "low"), each = 4L)),
    text = c(
      "high score and practical choice", "similar high profile",
      "a nuanced high response", "one more high observation",
      "low score but useful option", "similar low profile",
      "a nuanced low response", "one more low observation"
    ),
    stringsAsFactors = FALSE
  )
  catdes <- nail_catdes(
    dat[, c("group", "score", "choice")],
    num.var = 1,
    interpretation_mode = "latent",
    isolate.groups = TRUE,
    generate = FALSE
  )
  textual <- nail_textual(
    dat[, c("group", "text")],
    num.var = 1,
    num.text = 2,
    isolate.groups = TRUE,
    generate = FALSE
  )
  profiles <- attr(textual, "textual_profiles", exact = TRUE)
  input <- attr(textual, "interpretation_input", exact = TRUE)
  for (group in names(profiles$groups)) {
    ids <- input$groups[[group]]$selected_text_ids
    profiles$groups[[group]]$status <- "available"
    profiles$groups[[group]]$core_textual_profile <- "A recurring profile."
    profiles$groups[[group]]$dominant_themes <- "practical choices"
    profiles$groups[[group]]$within_group_coherence <- "moderate"
    profiles$groups[[group]]$internal_diversity <- "Some variation remains."
    profiles$groups[[group]]$representative_text_ids <- ids[[1L]]
    profiles$groups[[group]]$tension_text_ids <- ids[[2L]]
    profiles$groups[[group]]$parse_issues <- character(0)
  }
  attr(textual, "textual_profiles") <- profiles
  list(catdes = catdes, textual = textual)
}


test_that("all seven public defaults contain the instruction and custom requests do not", {
  condes_data <- make_default_insight_condes_data()
  textual_data <- make_default_insight_textual_data()
  data(chocolates, package = "SensoMineR")

  previews <- list(
    catdes = nail_catdes(iris, num.var = 5, generate = FALSE),
    condes = nail_condes(condes_data, num.var = 1, generate = FALSE),
    descfreq = nail_descfreq(
      data.frame(
        A = c(20, 5, 2), B = c(5, 20, 5), C = c(2, 5, 20),
        row.names = c("R1", "R2", "R3")
      ),
      generate = FALSE
    ),
    qda = nail_qda(
      sensochoc,
      formul = "~Product+Panelist",
      firstvar = 5,
      generate = FALSE
    ),
    textual = nail_textual(
      textual_data,
      num.var = 1,
      num.text = 2,
      generate = FALSE
    )
  )

  qda_space <- nail_qda_space(
    previews$qda,
    ncp = 1,
    min_inertia_pct = 0,
    generate = FALSE
  )
  previews$qda_space <- qda_space

  composed <- make_default_insight_catdes_textual_objects()
  previews$catdes_textual <- nail_catdes_textual(
    composed$catdes,
    composed$textual,
    generate = FALSE
  )

  for (name in names(previews)) {
    prompts <- nail_prompt(previews[[name]], print = FALSE)
    if (!is.list(prompts)) prompts <- list(prompts)
    expect_true(
      all(vapply(
        prompts,
        function(prompt) {
          count_fixed_text(prompt, interpretive_insight_sentence) == 1L
        },
        logical(1)
      )),
      info = name
    )
  }

  custom <- "CUSTOM REQUEST MUST REMAIN BYTE IDENTICAL."
  custom_objects <- list(
    nail_catdes(iris, num.var = 5, request = custom, generate = FALSE),
    nail_condes(condes_data, num.var = 1, request = custom, generate = FALSE),
    nail_descfreq(
      data.frame(
        A = c(20, 5, 2), B = c(5, 20, 5), C = c(2, 5, 20),
        row.names = c("R1", "R2", "R3")
      ),
      request = custom,
      generate = FALSE
    ),
    nail_qda(
      sensochoc,
      formul = "~Product+Panelist",
      firstvar = 5,
      request = custom,
      generate = FALSE
    ),
    nail_textual(
      textual_data,
      num.var = 1,
      num.text = 2,
      request = custom,
      generate = FALSE
    ),
    nail_qda_space(
      previews$qda,
      ncp = 1,
      min_inertia_pct = 0,
      request = custom,
      generate = FALSE
    ),
    nail_catdes_textual(
      composed$catdes,
      composed$textual,
      request = custom,
      generate = FALSE
    )
  )

  for (object in custom_objects) {
    prompts <- nail_prompt(object, print = FALSE)
    if (!is.list(prompts)) prompts <- list(prompts)
    expect_true(all(vapply(
      prompts,
      function(prompt) count_fixed_text(prompt, interpretive_insight_sentence) == 0L,
      logical(1)
    )))
    expect_true(all(vapply(
      prompts,
      grepl,
      logical(1),
      pattern = custom,
      fixed = TRUE
    )))
  }

  empty_request <- nail_catdes(
    iris,
    num.var = 5,
    request = "",
    generate = FALSE
  )
  empty_prompts <- nail_prompt(empty_request, print = FALSE)
  if (!is.list(empty_prompts)) empty_prompts <- list(empty_prompts)
  expect_true(all(vapply(
    empty_prompts,
    function(prompt) count_fixed_text(prompt, interpretive_insight_sentence) == 0L,
    logical(1)
  )))
})


test_that("default request changes do not change evidence or data sections", {
  data(chocolates, package = "SensoMineR")
  default <- nail_qda(
    sensochoc,
    formul = "~Product+Panelist",
    firstvar = 5,
    generate = FALSE
  )
  custom <- nail_qda(
    sensochoc,
    formul = "~Product+Panelist",
    firstvar = 5,
    request = "A custom analytical request.",
    generate = FALSE
  )

  data_section <- function(prompt) {
    sub("^.*# Data\\n\\n", "", prompt)
  }

  expect_identical(
    nail_evidence(default),
    nail_evidence(custom)
  )
  expect_identical(
    data_section(nail_prompt(default, print = FALSE)),
    data_section(nail_prompt(custom, print = FALSE))
  )
})


test_that("textual_prep remains unaffected because it supplies an explicit request", {
  dat <- make_default_insight_textual_data()
  preview <- nail_textual_prep(
    dataset = dat,
    num.var = 1,
    num.text = 2,
    generate = FALSE
  )
  prompt_text <- paste(nail_prompt(preview, print = FALSE), collapse = "\n")

  expect_equal(count_fixed_text(prompt_text, interpretive_insight_sentence), 0L)
  expect_match(prompt_text, "The texts below come from one specific group.", fixed = TRUE)
})
