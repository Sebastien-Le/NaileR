# This test file belongs in tests/testthat/.
# Do not copy it into R/, where test_that() would run while the package is loaded.

.make_mock_qda_result <- function() {
  product_a <- data.frame(
    Coeff = c(-2.0, 2.5),
    p.value = c(0.001, 0.002),
    v.test = c(-4.0, 3.0),
    stringsAsFactors = FALSE,
    check.names = FALSE
  )
  product_a[["Adjust mean"]] <- c(1.0, 8.0)
  product_a <- product_a[, c("Coeff", "Adjust mean", "p.value", "v.test")]
  rownames(product_a) <- c("Sweet", "Bitter")

  product_b <- data.frame(
    Coeff = 1.8,
    p.value = 0.01,
    v.test = 2.5,
    stringsAsFactors = FALSE,
    check.names = FALSE
  )
  product_b[["Adjust mean"]] <- 7.0
  product_b <- product_b[, c("Coeff", "Adjust mean", "p.value", "v.test")]
  rownames(product_b) <- "Sweet"

  product_c <- data.frame(
    Coeff = numeric(0),
    `Adjust mean` = numeric(0),
    p.value = numeric(0),
    v.test = numeric(0),
    stringsAsFactors = FALSE,
    check.names = FALSE
  )

  list(
    adjmean = data.frame(
      Sweet = c(1, 7, 4),
      Bitter = c(8, 3, 5),
      Aroma = c(4, 6, 5),
      row.names = c("A", "B", "C"),
      check.names = FALSE
    ),
    quanti = list(
      A = product_a,
      B = product_b,
      C = product_c
    )
  )
}

.make_qda_test_dataset <- function() {
  data.frame(
    Product = factor(c("A", "B", "C", "A", "B", "C")),
    Panelist = factor(c("J1", "J1", "J1", "J2", "J2", "J2")),
    Sweet = c(1, 7, 4, 1.2, 6.8, 4.1),
    Bitter = c(8, 3, 5, 7.8, 3.2, 4.9),
    Aroma = c(4, 6, 5, 4.1, 5.9, 5.1),
    check.names = FALSE
  )
}

test_that("QDA prompt sampling safely restores preserved row names", {
  x <- data.frame(
    Coeff = c(-2, 2.5, 1.8),
    `Adjust mean` = c(1, 8, 7),
    p.value = c(0.001, 0.002, 0.01),
    v.test = c(-4, 3, 2.5),
    check.names = FALSE
  )
  rownames(x) <- c("Sweet", "Bitter", "Aroma")

  sampled <- NaileR:::sample_numeric_distribution(
    data = x,
    num_var_index = 4L,
    sample_pct = 1,
    return_matrix = FALSE,
    seed = 1
  )

  expect_s3_class(sampled, "data.frame")
  expect_setequal(rownames(sampled), c("Sweet", "Bitter", "Aroma"))
  expect_false("OriginalRowName" %in% names(sampled))
})

test_that("mechanical QDA product profiles preserve complete evidence", {
  decat_result <- .make_mock_qda_result()

  profiles <- NaileR:::.build_qda_product_profiles(decat_result)

  expect_named(profiles, c("A", "B", "C"))
  expect_length(profiles, 3L)

  expect_named(
    profiles$A,
    c(
      "product",
      "adjusted_means",
      "retained_markers",
      "above_average",
      "below_average",
      "metrics"
    )
  )

  expect_identical(profiles$A$product, "A")
  expect_named(profiles$A$adjusted_means, c("Sweet", "Bitter", "Aroma"))
  expect_equal(unname(profiles$A$adjusted_means), c(1, 8, 4))

  markers_a <- profiles$A$retained_markers

  expect_named(
    markers_a,
    c(
      "evidence_id",
      "product",
      "attribute",
      "direction",
      "coefficient",
      "adjusted_mean",
      "v_test",
      "p_value",
      "abs_v_test",
      "rank"
    )
  )
  expect_equal(nrow(markers_a), nrow(decat_result$quanti$A))
  expect_setequal(markers_a$attribute, rownames(decat_result$quanti$A))
  expect_identical(
    markers_a$evidence_id,
    paste(markers_a$product, markers_a$attribute, sep = "::")
  )
  expect_false(anyDuplicated(markers_a$evidence_id) > 0)
  expect_identical(markers_a$rank, seq_len(nrow(markers_a)))

  expect_true(all(
    profiles$A$above_average$direction == "higher than overall"
  ))
  expect_true(all(
    profiles$A$below_average$direction == "lower than overall"
  ))
  expect_setequal(profiles$A$above_average$attribute, "Bitter")
  expect_setequal(profiles$A$below_average$attribute, "Sweet")

  expect_identical(profiles$A$metrics$n_retained, 2L)
  expect_identical(profiles$A$metrics$n_above_average, 1L)
  expect_identical(profiles$A$metrics$n_below_average, 1L)
  expect_equal(profiles$A$metrics$max_abs_v_test, 4)
  expect_equal(profiles$A$metrics$median_abs_v_test, 3.5)
  expect_equal(profiles$A$metrics$min_p_value, 0.001)
})

test_that("products without retained markers remain explicit", {
  profiles <- NaileR:::.build_qda_product_profiles(
    .make_mock_qda_result()
  )

  profile_c <- profiles$C

  expect_named(profile_c$adjusted_means, c("Sweet", "Bitter", "Aroma"))
  expect_equal(nrow(profile_c$retained_markers), 0L)
  expect_equal(nrow(profile_c$above_average), 0L)
  expect_equal(nrow(profile_c$below_average), 0L)

  expect_identical(profile_c$metrics$n_retained, 0L)
  expect_identical(profile_c$metrics$n_above_average, 0L)
  expect_identical(profile_c$metrics$n_below_average, 0L)
  expect_true(is.na(profile_c$metrics$max_abs_v_test))
  expect_true(is.na(profile_c$metrics$median_abs_v_test))
  expect_true(is.na(profile_c$metrics$min_p_value))
})

test_that("compatibility profile summaries are derived without strength labels", {
  profiles <- NaileR:::.build_qda_product_profiles(
    .make_mock_qda_result()
  )

  summary <- NaileR:::.derive_qda_profile_summary(
    profiles,
    top_n = 5L
  )

  expect_named(summary, names(profiles))
  expect_named(summary$A, c("above", "below", "n_sig"))
  expect_false("profile_strength" %in% names(summary$A))
  expect_identical(summary$A$above, profiles$A$above_average$attribute)
  expect_identical(summary$A$below, profiles$A$below_average$attribute)
  expect_identical(summary$C$n_sig, 0L)
})

test_that("nail_qda always attaches invariant mechanical profiles", {
  dataset <- .make_qda_test_dataset()

  mock_decat_result <- .make_mock_qda_result()

  testthat::local_mocked_bindings(
    .run_decat_qda = function(...) mock_decat_result,
    .call_llm_base = function(provider, model, prompt, output,
                              llm_api_options = list()) {
      data.frame(
        model = model,
        response = "mock response",
        stringsAsFactors = FALSE
      )
    },
    .package = "NaileR"
  )

  base_result <- nail_qda(
    dataset = dataset,
    formul = "~Product+Panelist",
    firstvar = 3,
    lastvar = 5,
    proba = 0.5,
    generate = FALSE
  )

  prompt_variant <- nail_qda(
    dataset = dataset,
    formul = "~Product+Panelist",
    firstvar = 3,
    lastvar = 5,
    proba = 0.5,
    isolate.groups = TRUE,
    drop.negative = TRUE,
    sample.pct = 0.5,
    prompt_style = "compact",
    request = "Provide a deliberately different interpretation request.",
    provider = "gemini",
    model = "different-model",
    generate = FALSE
  )

  generated_variant <- nail_qda(
    dataset = dataset,
    formul = "~Product+Panelist",
    firstvar = 3,
    lastvar = 5,
    proba = 0.5,
    isolate.groups = TRUE,
    drop.negative = FALSE,
    sample.pct = 1,
    prompt_style = "detailed",
    request = "Another request.",
    provider = "ollama",
    model = "mock-model",
    generate = TRUE
  )

  base_profiles <- attr(base_result, "product_profiles", exact = TRUE)
  prompt_profiles <- attr(prompt_variant, "product_profiles", exact = TRUE)
  generated_profiles <- attr(generated_variant, "product_profiles", exact = TRUE)

  expect_type(base_profiles, "list")
  expect_named(base_profiles, levels(dataset$Product))
  expect_length(base_profiles, nlevels(dataset$Product))
  expect_identical(base_profiles, prompt_profiles)
  expect_identical(base_profiles, generated_profiles)

  expect_true(is.list(attr(base_result, "decat_result", exact = TRUE)))

  settings <- attr(base_result, "qda_settings", exact = TRUE)
  expect_true(is.list(settings))
  expect_identical(settings$product_variable, "Product")
  expect_identical(settings$firstvar, 3L)
  expect_identical(settings$lastvar, 5L)
  expect_identical(settings$sensory_attributes, c("Sweet", "Bitter", "Aroma"))
  expect_equal(settings$proba, 0.5)

  for (product in names(base_profiles)) {
    profile <- base_profiles[[product]]
    expect_length(profile$adjusted_means, 3L)
    expect_false("profile_strength" %in% names(profile))

    retained <- attr(base_result, "decat_result", exact = TRUE)$quanti[[product]]
    expected_n <- if (is.null(retained)) 0L else nrow(as.data.frame(retained))
    expect_equal(nrow(profile$retained_markers), expected_n)
  }

  summary <- attr(base_result, "profile_summary", exact = TRUE)
  expect_named(summary, names(base_profiles))
  expect_true(all(vapply(
    summary,
    function(x) !"profile_strength" %in% names(x),
    logical(1)
  )))
})

test_that("no-result outputs retain complete mechanical attributes", {
  dataset <- .make_qda_test_dataset()
  no_marker_result <- list(
    adjmean = .make_mock_qda_result()$adjmean,
    quanti = list()
  )

  testthat::local_mocked_bindings(
    .run_decat_qda = function(...) no_marker_result,
    .call_llm_base = function(...) {
      stop("LLM backend was called")
    },
    .package = "NaileR"
  )

  result <- nail_qda(
    dataset = dataset,
    formul = "~Product+Panelist",
    firstvar = 3,
    lastvar = 5,
    proba = 0.05,
    generate = FALSE
  )

  profiles <- attr(result, "product_profiles", exact = TRUE)

  expect_named(profiles, c("A", "B", "C"))
  expect_true(all(vapply(
    profiles,
    function(x) nrow(x$retained_markers) == 0L,
    logical(1)
  )))
  expect_true(all(vapply(
    profiles,
    function(x) length(x$adjusted_means) == 3L,
    logical(1)
  )))
  expect_true(is.list(attr(result, "decat_result", exact = TRUE)))
  expect_true(is.list(attr(result, "qda_settings", exact = TRUE)))
  expect_named(
    attr(result, "profile_summary", exact = TRUE),
    names(profiles)
  )
})

test_that("all adjusted-mean rows become product profiles", {
  decat_result <- .make_mock_qda_result()
  rownames(decat_result$adjmean) <- c("1", "2", "3")
  names(decat_result$quanti) <- c("1", "2", "3")
  decat_result$quanti[[3]] <- NULL

  profiles <- NaileR:::.build_qda_product_profiles(decat_result)

  expect_named(profiles, c("1", "2", "3"))
  expect_length(profiles[["3"]]$adjusted_means, 3L)
  expect_equal(nrow(profiles[["3"]]$retained_markers), 0L)
})
