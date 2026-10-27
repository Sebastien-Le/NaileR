test_that("MASHS food-system data are de-identified and usable", {
  data(mashs_food_system, package = "NaileR")

  expect_s3_class(mashs_food_system, "data.frame")
  expect_equal(dim(mashs_food_system), c(573L, 61L))
  expect_false(anyNA(mashs_food_system))
  expect_false("ID" %in% names(mashs_food_system))
  expect_equal(as.integer(table(mashs_food_system$clust)),
               c(226L, 113L, 116L, 118L))

  preview <- nail_catdes(
    dataset = mashs_food_system,
    num.var = ncol(mashs_food_system),
    interpretation_mode = "latent",
    generate = FALSE
  )
  expect_gt(nchar(paste(nail_prompt(preview, print = FALSE), collapse = "")), 0L)
  expect_true(length(nail_evidence(preview)) > 0L)
})
