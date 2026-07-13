test_that("the core public API is available", {
  exports <- getNamespaceExports("NaileR")

  expect_true(length(exports) > 0L)
  expect_true(all(c(
    "nail_catdes",
    "nail_condes",
    "nail_qda",
    "nail_textual"
  ) %in% exports))
})
