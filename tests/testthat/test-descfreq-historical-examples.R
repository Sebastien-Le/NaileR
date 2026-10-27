test_that("historical beard description example is an offline preview", {
  data(beard_cont, package = "NaileR")

  result <- nail_descfreq(
    dataset = beard_cont,
    interpretation_mode = "description",
    isolate.groups = TRUE,
    generate = FALSE
  )

  expect_equal(dim(beard_cont), c(8L, 335L))
  expect_equal(length(nail_prompt(result, print = FALSE)), 8L)
  expect_equal(
    attr(result, "descfreq_settings")$interpretation_mode,
    "description"
  )
  expect_true(length(nail_evidence(result)$evidence_registry$evidence_id) > 0L)
})

test_that("historical children comparison example is an offline preview", {
  data(children, package = "FactoMineR")
  children_table <- children[1:14, 1:5] |> t() |> as.data.frame()
  rownames(children_table) <- c(
    "No education", "Elementary school", "Middle school",
    "High school", "University"
  )

  result <- nail_descfreq(
    dataset = children_table,
    interpretation_mode = "comparison",
    isolate.groups = FALSE,
    generate = FALSE
  )

  expect_equal(dim(children_table), c(5L, 14L))
  expect_equal(length(nail_prompt(result, print = FALSE)), 1L)
  expect_equal(
    attr(result, "descfreq_settings")$interpretation_mode,
    "comparison"
  )
  expect_true(length(nail_evidence(result)$evidence_registry$evidence_id) > 0L)
})
