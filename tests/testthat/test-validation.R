test_that("invalid and insufficient inputs fail explicitly", {
  dataset <- data.frame(
    group = factor(c("A", "B")),
    text = c("first", "second")
  )

  one_verbatim_result <- nail_textual(
    dataset,
    num.var = 1,
    num.text = 2,
    lexical_analysis = FALSE,
    compute_length_analysis = FALSE,
    generate = FALSE
  )
  expect_true(all(vapply(
    one_verbatim_result$group_reports,
    function(report) {
      any(vapply(
        report$interpretation_limits,
        function(limit) {
          grepl(
            "Only one non-empty verbatim was available",
            limit$text,
            fixed = TRUE
          )
        },
        logical(1)
      ))
    },
    logical(1)
  )))

  empty_result <- nail_textual(
    data.frame(
      group = factor(c("A", "B")),
      text = c("", NA_character_)
    ),
    num.var = 1,
    num.text = 2,
    lexical_analysis = FALSE,
    compute_length_analysis = FALSE,
    generate = FALSE
  )
  expect_identical(empty_result$metadata$report_status, "mechanical_only")
  expect_true(all(
    empty_result$textual_evidence$group_diagnostics$n_non_empty == 0L
  ))

  zero_selection <- nail_catdes(
    iris,
    num.var = 5,
    quali.sample = 0,
    quanti.sample = 0,
    generate = FALSE
  )
  expect_identical(
    attr(zero_selection, "interpretation_evidence")$metadata$n_selected_evidence,
    0L
  )

  expect_error(
    nail_qda_space(
      list(
        adjmean = data.frame(
          a = 1,
          b = 2,
          row.names = "P1"
        )
      ),
      generate = FALSE
    ),
    "at least 2 products"
  )
})


test_that("gemini_generate rejects a missing API key before networking", {
  expect_error(
    gemini_generate(
      prompt = "Test prompt",
      api_key = ""
    ),
    "GEMINI_API_KEY"
  )
})
