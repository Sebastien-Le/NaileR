test_that("IRTSAT data preserve the four-group frozen export", {
  data(irtsat_2024_2025, package = "NaileR")

  expect_s3_class(irtsat_2024_2025, "data.frame")
  expect_equal(dim(irtsat_2024_2025), c(529L, 36L))
  expect_true(is.numeric(irtsat_2024_2025$IRT_score))
  expect_false(anyNA(irtsat_2024_2025))
  expect_equal(as.integer(table(irtsat_2024_2025$profile)),
               c(83L, 180L, 179L, 87L))
  expect_length(levels(irtsat_2024_2025$profile), 4L)

  catdes_preview <- nail_catdes(
    dataset = irtsat_2024_2025,
    num.var = ncol(irtsat_2024_2025),
    interpretation_mode = "latent",
    generate = FALSE
  )
  expect_gt(nchar(paste(nail_prompt(catdes_preview, print = FALSE), collapse = "")), 0L)
  expect_true(length(nail_evidence(catdes_preview)) > 0L)

  condes_preview <- nail_condes(
    dataset = irtsat_2024_2025[, -ncol(irtsat_2024_2025)],
    num.var = 1,
    interpretation_mode = "latent",
    generate = FALSE
  )
  expect_gt(nchar(paste(nail_prompt(condes_preview, print = FALSE), collapse = "")), 0L)
  expect_true(length(nail_evidence(condes_preview)) > 0L)
})
