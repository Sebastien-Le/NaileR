test_that("IRTSAT item export preserves the English teaching interface", {
  data(irtsat_items_2024_2025, package = "NaileR")

  expect_s3_class(irtsat_items_2024_2025, "data.frame")
  expect_equal(dim(irtsat_items_2024_2025), c(541L, 48L))
  expect_equal(anyDuplicated(names(irtsat_items_2024_2025)), 0L)
  expect_equal(sum(is.na(irtsat_items_2024_2025)), 14L)
  expect_true(all(vapply(irtsat_items_2024_2025, is.ordered, logical(1))))
  expect_true(all(vapply(
    irtsat_items_2024_2025,
    function(x) identical(levels(x), c(
      "Strongly disagree",
      "Disagree",
      "Neither agree nor disagree",
      "Agree",
      "Strongly agree"
    )),
    logical(1)
  )))
  expect_equal(names(irtsat_items_2024_2025)[seq(1L, 8L)], c(
    "origin_geographic_origin_attention",
    "processed_food_origin_attention",
    "recognize_local_label",
    "know_local_producers_or_brands",
    "prefer_food_within_100km",
    "choose_local_or_france_label",
    "avoid_imported_fruit_vegetables",
    "effort_local_processed_food"
  ))
  expect_false(any(c("Horodateur", "Region", "cluster") %in%
                    names(irtsat_items_2024_2025)))
})
