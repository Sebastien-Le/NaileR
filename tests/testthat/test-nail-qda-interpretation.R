make_qda_interpretation_test_object <- function() {
  x <- structure(
    list(dummy = TRUE),
    class = "nail_qda_test_object"
  )

  interpretations <- list(
    products = list(
      choc1 = list(
        product = "choc1",
        status = "available",
        source = "llm_pass1",
        core_profile = "Bitter and cocoa-forward.",
        dominant_configuration = c(
          "higher bitterness",
          "higher cocoa flavor"
        ),
        secondary_configuration = "lower sweetness",
        distinctive_interpretation =
          "More bitter and cocoa-forward than average.",
        descriptive_name = NA_character_,
        evidence_ids = c(
          "QDAP001E001",
          "QDAP001E002"
        ),
        response_key = "choc1",
        raw_block = "<!-- original choc1 block -->"
      ),
      choc6 = list(
        product = "choc6",
        status = "parse_failed",
        source = "llm_pass1",
        core_profile = NA_character_,
        dominant_configuration = character(0),
        secondary_configuration = character(0),
        distinctive_interpretation = NA_character_,
        descriptive_name = NA_character_,
        evidence_ids = c(
          "QDAP006E001",
          "QDAP006E002"
        ),
        response_key = NA_character_,
        raw_block = NA_character_
      )
    ),
    metadata = list(
      schema = "NaileR::qda_product_interpretations",
      schema_version = "1.0.0",
      n_products = 2L,
      n_available = 1L,
      n_parse_failed = 1L,
      n_not_generated = 0L
    )
  )

  class(interpretations) <- c(
    "nail_qda_product_interpretations",
    "list"
  )

  attr(x, "product_interpretations") <- interpretations

  # Canonical evidence should never be changed by the editor.
  attr(x, "product_profiles") <- list(
    sentinel = "canonical evidence"
  )

  x
}


test_that("nail_qda_interpretation returns a compact overview", {
  x <- make_qda_interpretation_test_object()

  overview <- nail_qda_interpretation(
    x,
    print = FALSE
  )

  expect_s3_class(overview, "data.frame")
  expect_identical(
    overview$product,
    c("choc1", "choc6")
  )
  expect_identical(
    overview$status,
    c("available", "parse_failed")
  )
  expect_identical(
    overview$source,
    c("llm_pass1", "llm_pass1")
  )
  expect_true(is.na(
    overview$core_profile[
      overview$product == "choc6"
    ]
  ))
})


test_that("nail_qda_interpretation reads one product", {
  x <- make_qda_interpretation_test_object()

  item <- nail_qda_interpretation(
    x,
    product = "choc1",
    print = FALSE
  )

  expect_identical(
    item$core_profile,
    "Bitter and cocoa-forward."
  )
  expect_identical(
    item$source,
    "llm_pass1"
  )
})


test_that("expert revision repairs a failed parse without losing provenance", {
  x <- make_qda_interpretation_test_object()

  before_profiles <- attr(
    x,
    "product_profiles",
    exact = TRUE
  )

  updated <- nail_qda_interpretation(
    x,
    product = "choc6",
    core_profile =
      "Crunchy and sweet, with lower melting and acidity.",
    dominant_configuration = c(
      "higher crunchy",
      "higher sweetness"
    ),
    secondary_configuration = c(
      "lower melting",
      "lower acidity"
    ),
    distinctive_interpretation =
      "More crunchy and sweet, with lower melting and acidity than average.",
    print = FALSE
  )

  item <- attr(
    updated,
    "product_interpretations",
    exact = TRUE
  )$products$choc6

  expect_identical(item$status, "available")
  expect_identical(item$source, "expert")
  expect_identical(
    item$core_profile,
    "Crunchy and sweet, with lower melting and acidity."
  )
  expect_identical(
    item$dominant_configuration,
    c("higher crunchy", "higher sweetness")
  )
  expect_identical(
    item$secondary_configuration,
    c("lower melting", "lower acidity")
  )

  # Original provenance remains available.
  expect_identical(
    item$evidence_ids,
    c("QDAP006E001", "QDAP006E002")
  )
  expect_true(is.na(item$response_key))
  expect_true(is.na(item$raw_block))

  expect_identical(
    attr(updated, "product_profiles", exact = TRUE),
    before_profiles
  )

  metadata <- attr(
    updated,
    "product_interpretations",
    exact = TRUE
  )$metadata

  expect_identical(metadata$n_available, 2L)
  expect_identical(metadata$n_parse_failed, 0L)
})


test_that("expert revision of an available LLM interpretation preserves raw trace", {
  x <- make_qda_interpretation_test_object()

  updated <- nail_qda_interpretation(
    x,
    product = "choc1",
    core_profile =
      "Bitter, astringent and cocoa-forward.",
    print = FALSE
  )

  item <- attr(
    updated,
    "product_interpretations",
    exact = TRUE
  )$products$choc1

  expect_identical(item$source, "expert")
  expect_identical(item$status, "available")
  expect_identical(
    item$raw_block,
    "<!-- original choc1 block -->"
  )
  expect_identical(
    item$response_key,
    "choc1"
  )
})


test_that("failed parse requires a core profile before expert retention", {
  x <- make_qda_interpretation_test_object()

  expect_error(
    nail_qda_interpretation(
      x,
      product = "choc6",
      dominant_configuration = "higher crunchy",
      print = FALSE
    ),
    "requires a non-empty.*core_profile"
  )
})


test_that("nail_qda_interpretation validates product names", {
  x <- make_qda_interpretation_test_object()

  expect_error(
    nail_qda_interpretation(
      x,
      product = "unknown",
      print = FALSE
    ),
    "Available products: choc1, choc6"
  )
})


test_that("editing requires an explicit product", {
  x <- make_qda_interpretation_test_object()

  expect_error(
    nail_qda_interpretation(
      x,
      core_profile = "Expert profile.",
      print = FALSE
    ),
    "`product` must be supplied"
  )
})


test_that("object without product interpretations is rejected", {
  x <- list()

  expect_error(
    nail_qda_interpretation(
      x,
      print = FALSE
    ),
    "does not contain reusable QDA product interpretations"
  )
})
