test_that("nail_qda_space creates offline prompts", {
  qda_result <- list(
    adjmean = data.frame(
      Sweet = c(1, 2, 4),
      Bitter = c(4, 2, 1),
      Aroma = c(1, 4, 2),
      row.names = c("P1", "P2", "P3")
    )
  )

  testthat::local_mocked_bindings(
    .call_llm_base = function(...) {
      stop("LLM backend was called")
    },
    .package = "NaileR"
  )

  result <- nail_qda_space(
    qda_result,
    ncp = 2,
    min_inertia_pct = 0,
    generate = FALSE
  )

  expect_type(result, "list")
  expect_gte(length(result), 1L)

  space <- attr(result, "qda_space", exact = TRUE)

  expect_type(space, "list")
  expect_true(
    all(
      c(
        "pca_result",
        "adjmean",
        "eig",
        "retained_axes"
      ) %in% names(space)
    )
  )
})
