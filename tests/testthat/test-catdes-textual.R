make_catdes_textual_test_data <- function() {
  n <- 12L
  groups <- factor(
    rep(c("G1", "G2", "G3"), each = n),
    levels = c("G1", "G2", "G3")
  )
  index <- rep(seq_len(n), times = 3L)

  data.frame(
    group = groups,
    score = c(
      9 + index * 0.03,
      5 + index * 0.02,
      1 + index * 0.01
    ),
    choice = factor(
      rep(c("high", "middle", "low"), each = n),
      levels = c("low", "middle", "high")
    ),
    text = c(
      paste(
        "Mobility matters but I try to reduce unnecessary travel",
        index
      ),
      paste(
        "I balance convenience with environmental concerns",
        index
      ),
      paste(
        "I prefer local alternatives and rarely need long travel",
        index
      )
    ),
    stringsAsFactors = FALSE
  )
}


mock_textual_profile_for_catdes_textual <- function(prompt) {
  ids <- regmatches(
    prompt,
    gregexpr("TXT[0-9]{6}", prompt, perl = TRUE)
  )[[1L]]
  ids <- unique(ids)

  paste(
    "Core textual profile:",
    "The group expresses a recurring practical frame around travel choices.",
    "",
    "Dominant themes:",
    "practical constraints; alternatives; environmental concern",
    "",
    "Within-group coherence:",
    "moderate",
    "",
    "Internal diversity:",
    "Members differ in how far they are willing to change their travel habits.",
    "",
    "Representative text IDs:",
    ids[[1L]],
    "",
    "Tension text IDs:",
    if (length(ids) >= 2L) ids[[2L]] else "none",
    sep = "\n"
  )
}


mock_contextualized_profile <- function(prompt) {
  paste(
    "Statistical anchor:",
    "The group has a distinctive statistical profile defined by the CATDES evidence.",
    "",
    "Textual enrichment:",
    "The open responses make the statistical profile more understandable by showing how respondents frame their choices in practice.",
    "",
    "Additional insights:",
    "The texts add explicit references to practical trade-offs that are not themselves statistical descriptors.",
    "",
    "Internal diversity:",
    "The common frame coexists with differences in how strongly respondents are willing to change.",
    "",
    "Contextualized profile:",
    "Overall, the statistical profile remains the anchor while the texts reveal the practical meaning and internal nuance of that profile.",
    sep = "\n"
  )
}


build_catdes_textual_test_objects <- function() {
  dat <- make_catdes_textual_test_data()

  cat <- nail_catdes(
    dataset = dat[, c("group", "score", "choice")],
    num.var = 1,
    interpretation_mode = "latent",
    isolate.groups = TRUE,
    generate = FALSE
  )

  txt <- nail_textual(
    dataset = dat[, c("group", "text")],
    num.var = 1,
    num.text = 2,
    isolate.groups = TRUE,
    sample.pct = 1,
    generate = FALSE
  )

  profiles <- attr(
    txt,
    "textual_profiles",
    exact = TRUE
  )
  input <- attr(
    txt,
    "interpretation_input",
    exact = TRUE
  )

  for (g in names(profiles$groups)) {
    ids <- input$groups[[g]]$selected_text_ids

    profiles$groups[[g]]$status <- "available"
    profiles$groups[[g]]$core_textual_profile <-
      "The group expresses a recurring practical frame around travel choices."
    profiles$groups[[g]]$dominant_themes <- c(
      "practical constraints",
      "alternatives",
      "environmental concern"
    )
    profiles$groups[[g]]$within_group_coherence <- "moderate"
    profiles$groups[[g]]$internal_diversity <-
      "Members differ in how far they are willing to change their travel habits."
    profiles$groups[[g]]$representative_text_ids <- ids[[1L]]
    profiles$groups[[g]]$tension_text_ids <-
      if (length(ids) >= 2L) ids[[2L]] else character(0)
    profiles$groups[[g]]$parse_issues <- character(0)
  }

  attr(txt, "textual_profiles") <- profiles

  list(
    data = dat,
    catdes = cat,
    textual = txt
  )
}


test_that("nail_catdes_textual consumes canonical artifacts without recomputation", {
  obj <- build_catdes_textual_test_objects()

  x <- nail_catdes_textual(
    catdes = obj$catdes,
    textual = obj$textual,
    generate = FALSE
  )

  evidence <- attr(
    x,
    "contextualized_evidence",
    exact = TRUE
  )

  expect_s3_class(
    evidence,
    "nail_catdes_textual_evidence"
  )
  expect_named(
    evidence$groups,
    c("G1", "G2", "G3")
  )
  expect_identical(
    evidence$metadata$statistical_source,
    "semantic_facing_evidence"
  )
  expect_identical(
    evidence$metadata$textual_source,
    "textual_profiles"
  )
  expect_identical(
    evidence$metadata$textual_grounding_source,
    "textual_evidence"
  )
})


test_that("CATDES is the anchor and textual evidence is explicitly supplementary", {
  obj <- build_catdes_textual_test_objects()

  x <- nail_catdes_textual(
    catdes = obj$catdes,
    textual = obj$textual,
    isolate.groups = TRUE,
    generate = FALSE
  )

  prompt <- nail_prompt(
    x,
    select = "G1",
    print = FALSE
  )

  expect_match(
    prompt,
    "Statistical anchor - mechanical CATDES evidence",
    fixed = TRUE
  )
  expect_match(
    prompt,
    "textual layer",
    fixed = TRUE
  )
  expect_match(
    prompt,
    "CATDES and textual evidence do not play symmetrical roles here.",
    fixed = TRUE
  )
  expect_match(
    prompt,
    "Do not reinterpret the statistical facts from the texts.",
    fixed = TRUE
  )
})


test_that("contextualized evidence resolves exact representative and tension texts", {
  obj <- build_catdes_textual_test_objects()

  x <- nail_catdes_textual(
    catdes = obj$catdes,
    textual = obj$textual,
    generate = FALSE
  )

  evidence <- attr(
    x,
    "contextualized_evidence",
    exact = TRUE
  )
  txt_profiles <- attr(
    obj$textual,
    "textual_profiles",
    exact = TRUE
  )
  txt_registry <- attr(
    obj$textual,
    "textual_evidence",
    exact = TRUE
  )$text_registry

  for (g in names(evidence$groups)) {
    representative <-
      evidence$groups[[g]]$textual_enrichment$representative_texts
    tension <-
      evidence$groups[[g]]$textual_enrichment$tension_texts

    expected_rep <-
      txt_profiles$groups[[g]]$representative_text_ids
    expected_tension <-
      txt_profiles$groups[[g]]$tension_text_ids

    expect_identical(
      representative$text_id,
      expected_rep
    )
    expect_identical(
      tension$text_id,
      expected_tension
    )
    expect_true(all(
      representative$text %in% txt_registry$text
    ))
    expect_true(all(
      tension$text %in% txt_registry$text
    ))
  }
})


test_that("nail_catdes_textual rejects unavailable textual profiles", {
  dat <- make_catdes_textual_test_data()

  cat <- nail_catdes(
    dataset = dat[, c("group", "score", "choice")],
    num.var = 1,
    interpretation_mode = "latent",
    isolate.groups = TRUE,
    generate = FALSE
  )

  txt <- nail_textual(
    dataset = dat[, c("group", "text")],
    num.var = 1,
    num.text = 2,
    isolate.groups = TRUE,
    generate = FALSE
  )

  expect_error(
    nail_catdes_textual(
      catdes = cat,
      textual = txt,
      generate = FALSE
    ),
    "Canonical textual profiles are not available",
    fixed = TRUE
  )
})


test_that("nail_catdes_textual rejects mismatched group sets", {
  obj <- build_catdes_textual_test_objects()

  textual_profiles <- attr(
    obj$textual,
    "textual_profiles",
    exact = TRUE
  )
  textual_profiles$groups$G3 <- NULL

  broken <- obj$textual
  attr(broken, "textual_profiles") <- textual_profiles

  expect_error(
    nail_catdes_textual(
      catdes = obj$catdes,
      textual = broken,
      generate = FALSE
    ),
    "must describe exactly the same groups",
    fixed = TRUE
  )
})


test_that("nail_catdes_textual remains local-first when isolate.groups is FALSE", {
  obj <- build_catdes_textual_test_objects()
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
        response = mock_contextualized_profile(prompt),
        stringsAsFactors = FALSE
      )
    },
    .package = "NaileR"
  )

  x <- nail_catdes_textual(
    catdes = obj$catdes,
    textual = obj$textual,
    isolate.groups = FALSE,
    generate = TRUE,
    model = "mock-model"
  )

  expect_identical(counter$n, 3L)
  expect_true(is.data.frame(x))

  settings <- attr(
    x,
    "catdes_textual_settings",
    exact = TRUE
  )

  expect_true(settings$local_first)
  expect_false(settings$global_synthesis_performed)
  expect_identical(settings$llm_calls, 3L)
})


test_that("generated CATDES textual enrichment produces structured profiles", {
  obj <- build_catdes_textual_test_objects()

  testthat::local_mocked_bindings(
    .call_llm_base = function(provider,
                              model,
                              prompt,
                              output,
                              llm_api_options) {
      data.frame(
        model = model,
        response = mock_contextualized_profile(prompt),
        stringsAsFactors = FALSE
      )
    },
    .package = "NaileR"
  )

  x <- nail_catdes_textual(
    catdes = obj$catdes,
    textual = obj$textual,
    isolate.groups = TRUE,
    generate = TRUE,
    model = "mock-model"
  )

  profiles <- attr(
    x,
    "contextualized_profiles",
    exact = TRUE
  )

  expect_s3_class(
    profiles,
    "nail_catdes_textual_profiles"
  )
  expect_named(
    profiles$groups,
    c("G1", "G2", "G3")
  )

  for (g in names(profiles$groups)) {
    profile <- profiles$groups[[g]]

    expect_identical(
      profile$status,
      "available"
    )
    expect_true(nzchar(profile$statistical_anchor))
    expect_true(nzchar(profile$textual_enrichment))
    expect_true(nzchar(profile$additional_insights))
    expect_true(nzchar(profile$internal_diversity))
    expect_true(nzchar(profile$contextualized_profile))
    expect_length(profile$parse_issues, 0L)
  }
})


test_that("canonical llm_io exposes contextualized prompts and raw responses", {
  obj <- build_catdes_textual_test_objects()

  testthat::local_mocked_bindings(
    .call_llm_base = function(provider,
                              model,
                              prompt,
                              output,
                              llm_api_options) {
      data.frame(
        model = model,
        response = mock_contextualized_profile(prompt),
        stringsAsFactors = FALSE
      )
    },
    .package = "NaileR"
  )

  x <- nail_catdes_textual(
    catdes = obj$catdes,
    textual = obj$textual,
    isolate.groups = TRUE,
    generate = TRUE
  )

  io <- attr(x, "llm_io", exact = TRUE)

  expect_s3_class(io, "nail_llm_io")
  expect_identical(
    io$stage,
    "contextualization"
  )
  expect_identical(
    io$metadata$analysis,
    "nail_catdes_textual"
  )
  expect_identical(
    io$metadata$scope,
    "group"
  )

  expect_identical(
    nail_prompt(
      x,
      select = "G1",
      print = FALSE
    ),
    io$prompts$G1
  )
  expect_identical(
    nail_response(
      x,
      select = "G1",
      print = FALSE
    ),
    io$responses$G1
  )
})


test_that("missing required contextualized fields are reported as parse_failed", {
  obj <- build_catdes_textual_test_objects()

  testthat::local_mocked_bindings(
    .call_llm_base = function(provider,
                              model,
                              prompt,
                              output,
                              llm_api_options) {
      data.frame(
        model = model,
        response = paste(
          "Statistical anchor:",
          "A statistical profile.",
          "",
          "Textual enrichment:",
          "A textual enrichment.",
          "",
          "Additional insights:",
          "none",
          sep = "\n"
        ),
        stringsAsFactors = FALSE
      )
    },
    .package = "NaileR"
  )

  x <- nail_catdes_textual(
    catdes = obj$catdes,
    textual = obj$textual,
    isolate.groups = TRUE,
    generate = TRUE
  )

  profile <- attr(
    x,
    "contextualized_profiles",
    exact = TRUE
  )$groups$G1

  expect_identical(
    profile$status,
    "parse_failed"
  )
  expect_true(
    "missing_internal_diversity" %in%
      profile$parse_issues
  )
  expect_true(
    "missing_contextualized_profile" %in%
      profile$parse_issues
  )
})

test_that("textual scope is governed by observed discourse rather than the variable name", {
  obj <- build_catdes_textual_test_objects()

  x <- nail_catdes_textual(
    catdes = obj$catdes,
    textual = obj$textual,
    isolate.groups = TRUE,
    generate = FALSE
  )

  evidence <- attr(
    x,
    "contextualized_evidence",
    exact = TRUE
  )
  prompt <- nail_prompt(
    x,
    select = "G1",
    print = FALSE
  )

  # The source variable is retained mechanically for provenance.
  expect_identical(
    evidence$metadata$textual_variable,
    "text"
  )

  # But its technical column name is not used as semantic evidence in the prompt.
  expect_false(grepl(
    'Open-ended textual variable: "text"',
    prompt,
    fixed = TRUE
  ))

  expect_match(
    prompt,
    "Relate textual evidence to CATDES characteristics only when the connection is supported by what respondents explicitly express.",
    fixed = TRUE
  )
  expect_match(
    prompt,
    "Do not generalize the textual profile to unrelated CATDES dimensions.",
    fixed = TRUE
  )
  expect_match(
    prompt,
    "Response coverage and interpretation coverage are different",
    fixed = TRUE
  )
})



test_that("textual enrichment stays tied to explicitly identified CATDES characteristics", {
  obj <- build_catdes_textual_test_objects()

  x <- nail_catdes_textual(
    catdes = obj$catdes,
    textual = obj$textual,
    isolate.groups = TRUE,
    generate = FALSE
  )

  prompt <- nail_prompt(
    x,
    select = "G1",
    print = FALSE
  )

  expect_match(
    prompt,
    "When connecting textual evidence to CATDES, state explicitly which statistical characteristic or characteristics are being enriched.",
    fixed = TRUE
  )

  expect_match(
    prompt,
    "Do not use reasons, constraints, values, or considerations expressed about one characteristic as explanations for other CATDES characteristics.",
    fixed = TRUE
  )

  expect_match(
    prompt,
    "Name the CATDES characteristic or characteristics being enriched rather than speaking vaguely about the group as a whole.",
    fixed = TRUE
  )

  expect_match(
    prompt,
    "State what the texts add beyond the directly related CATDES characteristic or characteristics.",
    fixed = TRUE
  )
})
