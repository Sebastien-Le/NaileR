test_that("SPISE / Distinction item export is de-identified and stable", {
  data(spise_distinction_items_2025_2026, package = "NaileR")

  expect_s3_class(spise_distinction_items_2025_2026, "data.frame")
  expect_equal(dim(spise_distinction_items_2025_2026), c(181L, 48L))
  expect_equal(anyDuplicated(names(spise_distinction_items_2025_2026)), 0L)
  expect_false(anyNA(spise_distinction_items_2025_2026))
  expect_true(all(vapply(
    spise_distinction_items_2025_2026,
    is.ordered,
    logical(1)
  )))
  expect_identical(
    levels(spise_distinction_items_2025_2026[[1]]),
    c(
      "Strongly disagree",
      "Disagree",
      "Neither agree nor disagree",
      "Agree",
      "Strongly agree"
    )
  )
  expect_false(any(grepl(
    "(^|_)(id|identifier|timestamp|region|cluster|profile)(_|$)",
    names(spise_distinction_items_2025_2026),
    ignore.case = TRUE
  )))
  expect_true(all(grepl("^[a-z][a-z0-9_]*$", names(
    spise_distinction_items_2025_2026
  ))))
})
