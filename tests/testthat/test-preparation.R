test_that("nail_textual_prep returns documented structured fields", {
  dataset <- data.frame(
    group = factor(c("A", "A", "B", "B")),
    text = c(
      "easy to use",
      "simple and reliable",
      "works very well",
      "practical but basic"
    )
  )

  mocked_response <- paste(
    "Core textual profile: Practical and positive.",
    "Main themes: simplicity; comfort; reliability",
    "Dominant concerns or motives: saving time; avoiding complexity",
    "Tone or stance: pragmatic",
    "Intra-group consistency: strong",
    paste(
      "Injectable summary:",
      "The group values simple and reliable solutions."
    ),
    'Central verbatim cues: "easy to use"; "works very well"',
    "Tension verbatim cues: none",
    sep = "\n"
  )

  testthat::local_mocked_bindings(
    .call_llm_base = function(...) {
      data.frame(
        response = mocked_response,
        stringsAsFactors = FALSE
      )
    },
    .package = "NaileR"
  )

  result <- nail_textual_prep(
    dataset = dataset,
    num.var = 1,
    num.text = 2,
    generate = TRUE,
    attach_selected_verbatims = FALSE
  )

  expected_names <- c(
    "prompt",
    "response",
    "parsed",
    "selected_verbatims",
    "notable_expressions"
  )

  expect_type(result, "list")

  expect_true(
    all(
      vapply(
        result,
        function(x) {
          all(expected_names %in% names(x))
        },
        logical(1)
      )
    )
  )

  expect_true(
    all(
      vapply(
        result,
        function(x) {
          identical(
            x$parsed$intra_group_consistency,
            "strong"
          )
        },
        logical(1)
      )
    )
  )
})
