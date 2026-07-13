test_that("invalid and insufficient inputs fail explicitly", {
  dataset <- data.frame(
    group = factor(c("A", "B")),
    text = c("first", "second")
  )

  expect_error(
    nail_textual(
      dataset,
      num.var = 1,
      num.text = 1,
      generate = FALSE
    ),
    "different"
  )

  expect_error(
    nail_textual(
      data.frame(
        group = factor(c("A", "B")),
        text = c("", NA_character_)
      ),
      num.var = 1,
      num.text = 2,
      generate = FALSE
    ),
    "No non-empty"
  )

  expect_error(
    nail_catdes(
      iris,
      num.var = 5,
      quali.sample = 0,
      generate = FALSE
    ),
    "single numeric value"
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
