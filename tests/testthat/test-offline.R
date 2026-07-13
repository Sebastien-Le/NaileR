test_that("nail_catdes with generate FALSE never calls an LLM", {
  testthat::local_mocked_bindings(
    .call_llm_base = function(...) {
      stop("LLM backend was called")
    },
    .package = "NaileR"
  )

  result <- nail_catdes(
    dataset = iris,
    num.var = 5,
    generate = FALSE
  )

  expect_true(
    is.character(result) || is.list(result)
  )

  expect_true(
    is.list(attr(result, "catdes_result", exact = TRUE))
  )
})


test_that("nail_textual with generate FALSE is offline", {
  dataset <- data.frame(
    group = factor(c("A", "A", "B", "B")),
    text = c(
      "fresh and light",
      "light and floral",
      "dark and intense",
      "strong cocoa"
    )
  )

  testthat::local_mocked_bindings(
    .call_llm_base = function(...) {
      stop("LLM backend was called")
    },
    .package = "NaileR"
  )

  result <- nail_textual(
    dataset = dataset,
    num.var = 1,
    num.text = 2,
    isolate.groups = TRUE,
    generate = FALSE
  )

  expect_type(result, "list")
  expect_setequal(names(result), c("A", "B"))
  expect_true(
    all(vapply(result, is.character, logical(1)))
  )
})
