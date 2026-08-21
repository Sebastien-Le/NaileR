make_qda_pass1_interpretation_test_data <- function() {
  design <- expand.grid(
    Product = factor(
      c("A", "B", "C"),
      levels = c("A", "B", "C")
    ),
    Panelist = factor(seq_len(12))
  )

  p <- as.character(design$Product)
  p_num <- as.numeric(design$Product)
  j <- as.numeric(design$Panelist)

  r1 <- ((p_num * j) %% 5 - 2) * 0.06
  r2 <- ((p_num * (j + 2)) %% 7 - 3) * 0.05
  r3 <- (((p_num + 1) * j) %% 6 - 2.5) * 0.05
  r4 <- (((p_num + 2) * (j + 1)) %% 8 - 3.5) * 0.04

  design$Sweet <- c(A = 8, B = 5, C = 2)[p] + j * 0.01 + r1
  design$Bitter <- c(A = 2, B = 5, C = 8)[p] + j * 0.01 + r2
  design$Creamy <- c(A = 8, B = 3, C = 5)[p] + j * 0.01 + r3
  design$Acidic <- c(A = 2, B = 7, C = 5)[p] + j * 0.01 + r4

  design
}


qda_pass1_interpretation_args <- function() {
  list(
    dataset = make_qda_pass1_interpretation_test_data(),
    formul = "~ Product + Panelist",
    firstvar = 3,
    lastvar = 6,
    proba = 0.05
  )
}


qda_mock_interpretation_block <- function(product,
                                          core = NULL) {
  if (is.null(core)) {
    core <- paste0(
      product,
      " has an integrated sensory profile."
    )
  }

  paste(
    "<!-- NAILER_PRODUCT_INTERPRETATION",
    paste0("product: ", product),
    paste0("core_profile: ", core),
    "dominant_configuration: sweet; creamy",
    "secondary_configuration: low bitterness",
    paste0(
      "distinctive_interpretation: ",
      product,
      " is distinctive through its coherent sensory bundle."
    ),
    "descriptive_name: none",
    "END_NAILER_PRODUCT_INTERPRETATION -->",
    sep = "\n"
  )
}


test_that("QDA preview exposes not-generated reusable interpretations", {
  args <- qda_pass1_interpretation_args()

  x <- do.call(
    nail_qda,
    c(
      args,
      list(
        generate = FALSE,
        isolate.groups = FALSE
      )
    )
  )

  interpretations <- attr(
    x,
    "product_interpretations",
    exact = TRUE
  )

  expect_s3_class(
    interpretations,
    "nail_qda_product_interpretations"
  )
  expect_named(
    interpretations$products,
    c("A", "B", "C")
  )
  expect_true(all(
    vapply(
      interpretations$products,
      function(item) identical(
        item$status,
        "not_generated"
      ),
      logical(1)
    )
  ))

  prompt <- nail_prompt(
    x,
    print = FALSE
  )

  expect_match(
    prompt,
    "NAILER_PRODUCT_INTERPRETATION",
    fixed = TRUE
  )

  expect_identical(
    interpretations$metadata$n_available,
    0L
  )
})


test_that("QDA joint PASS1 yields reusable product interpretations", {
  args <- qda_pass1_interpretation_args()
  call_count <- 0L

  testthat::local_mocked_bindings(
    .call_llm_base = function(provider,
                              model,
                              prompt,
                              output,
                              llm_api_options) {
      call_count <<- call_count + 1L

      response <- paste(
        "# Visible portfolio interpretation",
        qda_mock_interpretation_block(
          "A",
          "Sweet and creamy with little bitterness."
        ),
        qda_mock_interpretation_block(
          "B",
          "Acidic and less creamy, with a balanced sweet-bitter profile."
        ),
        qda_mock_interpretation_block(
          "C",
          "Bitter and less sweet, with a moderate creamy note."
        ),
        sep = "\n\n"
      )

      data.frame(
        model = model,
        response = response,
        stringsAsFactors = FALSE
      )
    },
    .package = "NaileR"
  )

  x <- do.call(
    nail_qda,
    c(
      args,
      list(
        generate = TRUE,
        isolate.groups = FALSE,
        model = "mock-model"
      )
    )
  )

  expect_identical(call_count, 1L)

  interpretations <- attr(
    x,
    "product_interpretations",
    exact = TRUE
  )

  expect_s3_class(
    interpretations,
    "nail_qda_product_interpretations"
  )
  expect_identical(
    interpretations$metadata$n_available,
    3L
  )

  expect_identical(
    interpretations$products$A$status,
    "available"
  )
  expect_identical(
    interpretations$products$A$core_profile,
    "Sweet and creamy with little bitterness."
  )
  expect_identical(
    interpretations$products$A$dominant_configuration,
    c("sweet", "creamy")
  )
  expect_identical(
    interpretations$products$A$secondary_configuration,
    "low bitterness"
  )
  expect_identical(
    interpretations$products$A$source,
    "llm_pass1"
  )
  expect_identical(
    interpretations$products$A$response_key,
    "portfolio"
  )

  semantic <- attr(
    x,
    "semantic_facing_evidence",
    exact = TRUE
  )

  expect_identical(
    interpretations$products$A$evidence_ids,
    semantic$products$A$selected_evidence_ids
  )

  expect_match(
    nail_response(x, print = FALSE),
    "# Visible portfolio interpretation",
    fixed = TRUE
  )
  expect_match(
    nail_response(x, print = FALSE),
    "NAILER_PRODUCT_INTERPRETATION",
    fixed = TRUE
  )
})


test_that("QDA isolated PASS1 reuses the existing product-level LLM calls", {
  args <- qda_pass1_interpretation_args()
  call_count <- 0L

  testthat::local_mocked_bindings(
    .call_llm_base = function(provider,
                              model,
                              prompt,
                              output,
                              llm_api_options) {
      call_count <<- call_count + 1L

      product <- c("A", "B", "C")[
        vapply(
          c("A", "B", "C"),
          function(p) {
            grepl(
              paste0("Product '", p, "'"),
              prompt,
              fixed = TRUE
            )
          },
          logical(1)
        )
      ][1L]

      if (is.na(product)) {
        stop("Mock could not identify the product prompt.")
      }

      data.frame(
        model = model,
        response = paste(
          paste0("# Visible interpretation for ", product),
          qda_mock_interpretation_block(product),
          sep = "\n\n"
        ),
        stringsAsFactors = FALSE
      )
    },
    .package = "NaileR"
  )

  x <- do.call(
    nail_qda,
    c(
      args,
      list(
        generate = TRUE,
        isolate.groups = TRUE,
        model = "mock-model"
      )
    )
  )

  expect_identical(call_count, 3L)

  interpretations <- attr(
    x,
    "product_interpretations",
    exact = TRUE
  )

  expect_identical(
    interpretations$metadata$n_available,
    3L
  )

  for (product in c("A", "B", "C")) {
    expect_identical(
      interpretations$products[[product]]$status,
      "available"
    )
    expect_identical(
      interpretations$products[[product]]$response_key,
      product
    )
    expect_match(
      interpretations$products[[product]]$core_profile,
      product,
      fixed = TRUE
    )
  }
})


test_that("QDA malformed reusable blocks fail closed", {
  args <- qda_pass1_interpretation_args()

  testthat::local_mocked_bindings(
    .call_llm_base = function(provider,
                              model,
                              prompt,
                              output,
                              llm_api_options) {
      data.frame(
        model = model,
        response = "# Visible answer without reusable metadata",
        stringsAsFactors = FALSE
      )
    },
    .package = "NaileR"
  )

  x <- do.call(
    nail_qda,
    c(
      args,
      list(
        generate = TRUE,
        isolate.groups = FALSE,
        model = "mock-model"
      )
    )
  )

  interpretations <- attr(
    x,
    "product_interpretations",
    exact = TRUE
  )

  expect_identical(
    interpretations$metadata$n_available,
    0L
  )
  expect_identical(
    interpretations$metadata$n_parse_failed,
    3L
  )

  expect_true(all(
    vapply(
      interpretations$products,
      function(item) {
        identical(item$status, "parse_failed") &&
          is.na(item$core_profile)
      },
      logical(1)
    )
  ))
})


test_that("QDA product_profiles remain unchanged by reusable PASS1 metadata", {
  args <- qda_pass1_interpretation_args()

  preview <- do.call(
    nail_qda,
    c(
      args,
      list(
        generate = FALSE,
        isolate.groups = FALSE
      )
    )
  )

  testthat::local_mocked_bindings(
    .call_llm_base = function(provider,
                              model,
                              prompt,
                              output,
                              llm_api_options) {
      data.frame(
        model = model,
        response = paste(
          "# Visible answer",
          qda_mock_interpretation_block("A"),
          qda_mock_interpretation_block("B"),
          qda_mock_interpretation_block("C"),
          sep = "\n\n"
        ),
        stringsAsFactors = FALSE
      )
    },
    .package = "NaileR"
  )

  generated <- do.call(
    nail_qda,
    c(
      args,
      list(
        generate = TRUE,
        isolate.groups = FALSE,
        model = "mock-model"
      )
    )
  )

  expect_identical(
    attr(preview, "product_profiles", exact = TRUE),
    attr(generated, "product_profiles", exact = TRUE)
  )
})
