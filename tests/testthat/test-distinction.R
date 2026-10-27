test_that("Distinction dataset is complete, de-identified, and documented", {
  data(distinction, package = "NaileR")

  expect_s3_class(distinction, "data.frame")
  expect_equal(dim(distinction), c(1226L, 105L))
  expect_equal(anyDuplicated(names(distinction)), 0L)
  expect_false("residential_postal_code" %in% names(distinction))
  expect_false("quality_food_open_fr" %in% names(distinction))
  expect_true("quality_food_open" %in% names(distinction))
  expect_equal(sum(!is.na(distinction$quality_food_open)), 1225L)
  expect_true(any(distinction$quality_food_open == ".", na.rm = TRUE))

  ordered_columns <- vapply(distinction, is.ordered, logical(1))
  expect_equal(sum(ordered_columns), 50L)
  expect_true(all(vapply(
    distinction[ordered_columns],
    function(x) identical(
      levels(x),
      c(
        "Strongly disagree",
        "Disagree",
        "Moderately agree",
        "Agree",
        "Strongly agree"
      )
    ),
    logical(1)
  )))
})

test_that("Distinction supports offline public NaileR previews", {
  data(distinction, package = "NaileR")

  catdes_preview <- nail_catdes(
    dataset = distinction,
    num.var = 1,
    interpretation_mode = "standard",
    generate = FALSE
  )
  expect_gt(nchar(paste(nail_prompt(catdes_preview, print = FALSE), collapse = "")), 0L)
  expect_true(length(nail_evidence(catdes_preview)) > 0L)

  condes_preview <- nail_condes(
    dataset = distinction,
    num.var = 2,
    interpretation_mode = "standard",
    generate = FALSE
  )
  expect_gt(nchar(paste(nail_prompt(condes_preview, print = FALSE), collapse = "")), 0L)
  expect_true(length(nail_evidence(condes_preview)) > 0L)

  textual_preview <- nail_textual(
    dataset = distinction,
    num.var = 1,
    num.text = 105,
    isolate.groups = TRUE,
    generate = FALSE
  )
  expect_gt(nchar(paste(nail_prompt(textual_preview, print = FALSE), collapse = "")), 0L)
  expect_true(length(nail_evidence(textual_preview)) > 0L)
})
