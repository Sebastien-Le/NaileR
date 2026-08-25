test_that("QDA parser accepts a product-prefixed interpretation marker", {
  response <- paste(
    "<!-- choc1_PRODUCT_INTERPRETATION",
    "product: choc1",
    "core_profile: Bitter, astringent and acidic with high cocoa flavor.",
    "dominant_configuration: bitter; astringent; acidic; high cocoa flavor",
    "secondary_configuration: none",
    "distinctive_interpretation: More bitter, astringent, acidic and cocoa-flavored than the average sensory profile.",
    "descriptive_name: none",
    "END_choc1_PRODUCT_INTERPRETATION -->",
    sep = "\n"
  )

  parsed <- NaileR:::.qda_parse_response_interpretations(
    text = response,
    product_names = "choc1",
    response_key = "choc1",
    single_product_fallback = "choc1"
  )

  expect_named(parsed, "choc1")
  expect_identical(
    parsed$choc1$core_profile,
    "Bitter, astringent and acidic with high cocoa flavor."
  )
})
