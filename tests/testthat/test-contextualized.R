test_that("precomputed contextualized prompts require no final LLM call", {
  group_profile <- list(
    A = list(
      parsed = list(
        core_group_profile = "Profile A",
        quantitative_traits = "Trait A",
        categorical_traits = "Category A",
        distinctive_markers = "Marker A",
        profile_strength = "strong",
        injectable_summary = "Summary A"
      )
    ),
    B = list(
      parsed = list(
        core_group_profile = "Profile B",
        quantitative_traits = "Trait B",
        categorical_traits = "Category B",
        distinctive_markers = "Marker B",
        profile_strength = "moderate",
        injectable_summary = "Summary B"
      )
    )
  )

  textual_profile <- list(
    A = list(
      parsed = list(
        core_textual_profile = "Text profile A",
        main_themes = "Theme A",
        dominant_concerns = "Concern A",
        tone_or_stance = "positive",
        intra_group_consistency = "strong",
        injectable_summary = "Text summary A",
        central_verbatim_cues = character(),
        tension_verbatim_cues = character()
      ),
      selected_verbatims = NULL
    ),
    B = list(
      parsed = list(
        core_textual_profile = "Text profile B",
        main_themes = "Theme B",
        dominant_concerns = "Concern B",
        tone_or_stance = "reserved",
        intra_group_consistency = "moderate",
        injectable_summary = "Text summary B",
        central_verbatim_cues = character(),
        tension_verbatim_cues = character()
      ),
      selected_verbatims = NULL
    )
  )

  testthat::local_mocked_bindings(
    .call_llm_base = function(...) {
      stop("LLM backend was called")
    },
    .package = "NaileR"
  )

  result <- nail_textual_contextualized(
    group_profile_prep = group_profile,
    textual_prep = textual_profile,
    isolate.groups = TRUE,
    include_verbatims = FALSE,
    generate = FALSE
  )

  expect_type(result, "list")
  expect_setequal(names(result), c("A", "B"))
  expect_true(
    all(vapply(result, is.character, logical(1)))
  )
})
