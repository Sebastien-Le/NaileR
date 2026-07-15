.spaceprep_mock_decat_result <- function() {
  product_a <- data.frame(
    Coeff = c(-2.0, 2.5),
    `Adjust mean` = c(1.0, 8.0),
    p.value = c(0.001, 0.002),
    v.test = c(-4.0, 3.0),
    check.names = FALSE
  )
  rownames(product_a) <- c("Sweet", "Bitter")

  product_b <- data.frame(
    Coeff = c(1.8, -1.5),
    `Adjust mean` = c(7.0, 3.0),
    p.value = c(0.01, 0.02),
    v.test = c(2.5, -2.2),
    check.names = FALSE
  )
  rownames(product_b) <- c("Sweet", "Bitter")

  product_c <- data.frame(
    Coeff = numeric(0),
    `Adjust mean` = numeric(0),
    p.value = numeric(0),
    v.test = numeric(0),
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
    quanti = list(A = product_a, B = product_b, C = product_c)
  )
}

.spaceprep_dataset <- function() {
  data.frame(
    Product = factor(c("A", "B", "C", "A", "B", "C")),
    Panelist = factor(c("J1", "J1", "J1", "J2", "J2", "J2")),
    Sweet = c(1, 7, 4, 1.2, 6.8, 4.1),
    Bitter = c(8, 3, 5, 7.8, 3.2, 4.9),
    Aroma = c(4, 6, 5, 4.1, 5.9, 5.1),
    check.names = FALSE
  )
}

.spaceprep_qda_object <- function() {
  decat_result <- .spaceprep_mock_decat_result()
  profiles <- NaileR:::.build_qda_product_profiles(decat_result)
  x <- "mock qda prompt"
  attr(x, "decat_result") <- decat_result
  attr(x, "product_profiles") <- profiles
  attr(x, "qda_settings") <- list(
    formul = "~Product+Panelist",
    product_variable = "Product",
    sensory_attributes = c("Sweet", "Bitter", "Aroma"),
    proba = 0.05
  )
  x
}

.spaceprep_claim <- function(text,
                             status = "expert_interpretation",
                             evidence_ids = "A::Bitter",
                             validation_needed = NULL) {
  list(
    text = text,
    status = status,
    evidence_ids = as.list(evidence_ids),
    validation_needed = validation_needed
  )
}

.spaceprep_valid_expertise <- function(consumer_claim = NULL) {
  list(
    portfolio = list(
      overall_reading = .spaceprep_claim(
        "The set contrasts a bitter profile with a sweeter profile.",
        evidence_ids = c("A::Bitter", "B::Sweet")
      ),
      product_families = list(),
      differentiation_issues = list(
        .spaceprep_claim(
          "Products A and B occupy clearly different sensory identities.",
          status = "hypothesis",
          evidence_ids = c("A::Bitter", "B::Sweet"),
          validation_needed = "Confirm with multidimensional product-space distances."
        )
      ),
      cross_functional_priorities = list(
        .spaceprep_claim(
          "Validate whether the main sensory contrast structures preference.",
          status = "recommendation",
          evidence_ids = c("A::Bitter", "B::Sweet"),
          validation_needed = "Collect consumer liking and preference data."
        )
      )
    ),
    products = list(
      A = list(
        product = "A",
        proposed_name = .spaceprep_claim("Intense bitter profile"),
        sensory_identity = .spaceprep_claim(
          "Bitter and low-sweetness sensory identity.",
          evidence_ids = c("A::Bitter", "A::Sweet")
        ),
        sensory_archetype = .spaceprep_claim("Intense sensory reference"),
        differentiation_role = .spaceprep_claim(
          "Represents the intense end of the set.",
          status = "hypothesis",
          evidence_ids = c("A::Bitter", "A::Sweet"),
          validation_needed = "Confirm in the multidimensional product space."
        ),
        formulation_directions = list(
          .spaceprep_claim(
            "Reduce bitterness if a milder sensory target is desired.",
            status = "recommendation",
            evidence_ids = "A::Bitter",
            validation_needed = "Run a formulation trial followed by sensory evaluation."
          )
        ),
        consumer_preference_hypotheses = if (is.null(consumer_claim)) list() else list(consumer_claim),
        usage_hypotheses = list(),
        communication_territory = .spaceprep_claim(
          "Sensory intensity and restrained sweetness.",
          evidence_ids = c("A::Bitter", "A::Sweet")
        ),
        validation_needs = list("Consumer preference study")
      ),
      B = list(
        product = "B",
        proposed_name = .spaceprep_claim(
          "Sweet accessible profile",
          evidence_ids = "B::Sweet"
        ),
        sensory_identity = .spaceprep_claim(
          "Sweeter and less bitter sensory identity.",
          evidence_ids = c("B::Sweet", "B::Bitter")
        ),
        sensory_archetype = .spaceprep_claim(
          "Milder sensory reference",
          evidence_ids = "B::Sweet"
        ),
        differentiation_role = NULL,
        formulation_directions = list(),
        consumer_preference_hypotheses = list(),
        usage_hypotheses = list(),
        communication_territory = .spaceprep_claim(
          "Sweetness and mildness.",
          evidence_ids = c("B::Sweet", "B::Bitter")
        ),
        validation_needs = list()
      ),
      C = list(
        product = "C",
        proposed_name = NULL,
        sensory_identity = NULL,
        sensory_archetype = NULL,
        differentiation_role = NULL,
        formulation_directions = list(),
        consumer_preference_hypotheses = list(),
        usage_hypotheses = list(),
        communication_territory = NULL,
        validation_needs = list("Collect stronger differentiating sensory evidence.")
      )
    )
  )
}

.spaceprep_json <- function(x) {
  jsonlite::toJSON(
    x,
    auto_unbox = TRUE,
    pretty = TRUE,
    null = "null",
    na = "null"
  )
}

.spaceprep_all_evidence_ids <- function(x = .spaceprep_qda_object()) {
  profiles <- attr(x, "product_profiles", exact = TRUE)
  unlist(lapply(profiles, function(profile) {
    profile$retained_markers$evidence_id
  }), use.names = FALSE)
}

test_that("nail_qda_spaceprep accepts a nail_qda result and never recalculates decat", {
  dataset <- .spaceprep_dataset()
  mock_decat <- .spaceprep_mock_decat_result()

  testthat::local_mocked_bindings(
    .run_decat_qda = function(...) mock_decat,
    .package = "NaileR"
  )

  qda_result <- nail_qda(
    dataset = dataset,
    formul = "~Product+Panelist",
    firstvar = 3,
    lastvar = 5,
    proba = 0.5,
    generate = FALSE
  )

  testthat::local_mocked_bindings(
    .run_decat_qda = function(...) stop("decat was recalculated"),
    .call_llm_base = function(...) stop("LLM was called"),
    .package = "NaileR"
  )

  result <- nail_qda_spaceprep(x = qda_result, generate = FALSE)

  expect_s3_class(result, "nail_qda_spaceprep")
  expect_identical(
    attr(result, "product_profiles", exact = TRUE),
    attr(qda_result, "product_profiles", exact = TRUE)
  )
  expect_identical(result$parsed$parse_status, "not_generated")
})

test_that("nail_qda_spaceprep fails clearly without product_profiles", {
  expect_error(
    nail_qda_spaceprep(x = "not a qda result", generate = FALSE),
    "product_profiles"
  )

  bad <- .spaceprep_qda_object()
  attr(bad, "product_profiles") <- list(A = list(product = "A"))
  expect_error(nail_qda_spaceprep(x = bad, generate = FALSE), "invalid")
})

test_that("joint mode creates one prompt containing every product", {
  x <- .spaceprep_qda_object()

  result <- nail_qda_spaceprep(
    x = x,
    comparison_mode = "joint",
    generate = FALSE
  )

  expect_type(result$prompt, "character")
  expect_length(result$prompt, 1L)
  expect_match(result$prompt, "A::Bitter", fixed = TRUE)
  expect_match(result$prompt, "B::Sweet", fixed = TRUE)
  expect_match(result$prompt, '"C"', fixed = TRUE)
  expect_match(result$prompt, "Analyze all products together", fixed = TRUE)
  expect_named(result$evidence$products, c("A", "B", "C"))
})

test_that("isolated mode creates one generation unit per product", {
  x <- .spaceprep_qda_object()

  result <- nail_qda_spaceprep(
    x = x,
    comparison_mode = "isolated",
    generate = FALSE
  )

  expect_s3_class(result, "nail_qda_spaceprep_isolated")
  expect_named(result, c("A", "B", "C"))
  expect_match(result$A$prompt, "A::Bitter", fixed = TRUE)
  expect_false(grepl("B::Sweet", result$A$prompt, fixed = TRUE))
  expect_match(result$B$prompt, "B::Sweet", fixed = TRUE)
  expect_false(grepl("A::Bitter", result$B$prompt, fixed = TRUE))
  expect_named(result$A$evidence$products, "A")
  expect_named(result$C$evidence$products, "C")
})

test_that("expertise_scope, request, and context remain separate prompt layers", {
  x <- .spaceprep_qda_object()
  custom_request <- "Propose names that are distinct across the range."
  context <- list(
    category = "dark chocolate",
    formulation = "Sugar cannot be increased.",
    brand = "The brand uses factual sensory wording only."
  )

  sensory <- nail_qda_spaceprep(
    x = x,
    expertise_scope = "sensory",
    request = custom_request,
    context = context,
    generate = FALSE
  )
  formulation <- nail_qda_spaceprep(
    x = x,
    expertise_scope = "formulation",
    request = custom_request,
    context = context,
    generate = FALSE
  )

  expect_match(sensory$prompt, "SENSORY PERSPECTIVE", fixed = TRUE)
  expect_match(formulation$prompt, "FORMULATION PERSPECTIVE", fixed = TRUE)
  expect_match(formulation$prompt, custom_request, fixed = TRUE)
  expect_match(formulation$prompt, "USER-PROVIDED PRODUCT CONTEXT", fixed = TRUE)
  expect_match(formulation$prompt, "dark chocolate", fixed = TRUE)
  expect_match(formulation$prompt, "This section is external context", fixed = TRUE)
  expect_match(formulation$prompt, "OUTPUT SCHEMA", fixed = TRUE)
  expect_match(formulation$prompt, "evidence_ids", fixed = TRUE)
  expect_match(formulation$prompt, "validation_needed", fixed = TRUE)
  expect_match(formulation$prompt, "expert_interpretation", fixed = TRUE)
})

test_that("generate FALSE never calls an LLM", {
  x <- .spaceprep_qda_object()

  testthat::local_mocked_bindings(
    .call_llm_base = function(...) stop("LLM backend was called"),
    .package = "NaileR"
  )

  expect_error(
    result <- nail_qda_spaceprep(
      x = x,
      comparison_mode = "joint",
      provider = "gemini",
      model = "unavailable-model",
      generate = FALSE
    ),
    NA
  )
  expect_null(result$response)
  expect_identical(result$parsed$parse_status, "not_generated")
})

test_that("valid JSON is parsed into traceable product expertise", {
  x <- .spaceprep_qda_object()
  response_json <- .spaceprep_json(.spaceprep_valid_expertise())

  parsed <- NaileR:::.parse_qda_spaceprep_response(
    text = response_json,
    expected_products = c("A", "B", "C"),
    valid_evidence_ids = .spaceprep_all_evidence_ids(x),
    context = NaileR:::.validate_qda_spaceprep_context(NULL),
    expertise_scope = "cross_functional",
    comparison_mode = "joint",
    metadata = list(model = "mock")
  )

  expect_identical(parsed$parse_status, "success")
  expect_null(parsed$parse_error)
  expect_named(parsed$product_expertise, c("portfolio", "products", "metadata"))
  expect_named(parsed$product_expertise$products, c("A", "B", "C"))
  expect_identical(
    parsed$product_expertise$products$A$sensory_identity$evidence_ids,
    c("A::Bitter", "A::Sweet")
  )
  expect_identical(parsed$product_expertise$metadata$parse_status, "success")
})

test_that("joint generation preserves prompt response and parsed expertise", {
  x <- .spaceprep_qda_object()
  response_json <- .spaceprep_json(.spaceprep_valid_expertise())

  testthat::local_mocked_bindings(
    .call_llm_base = function(provider, model, prompt, output,
                              llm_api_options = list()) {
      expect_identical(output, "text")
      response_json
    },
    .package = "NaileR"
  )

  result <- nail_qda_spaceprep(
    x = x,
    expertise_scope = "cross_functional",
    comparison_mode = "joint",
    model = "mock-model",
    generate = TRUE
  )

  expect_type(result$prompt, "character")
  expect_identical(result$response, response_json)
  expect_identical(result$parsed$parse_status, "success")
  expect_identical(result$product_expertise, result$parsed$product_expertise)
})

test_that("invalid JSON is explicitly marked as unparsed", {
  x <- .spaceprep_qda_object()

  testthat::local_mocked_bindings(
    .call_llm_base = function(...) "This is not JSON.",
    .package = "NaileR"
  )

  result <- nail_qda_spaceprep(x = x, generate = TRUE)

  expect_identical(result$parsed$parse_status, "error")
  expect_true(nzchar(result$parsed$parse_error))
  expect_null(result$parsed$product_expertise)
  expect_null(result$product_expertise)
})

test_that("unknown evidence IDs are rejected explicitly", {
  x <- .spaceprep_qda_object()
  expertise <- .spaceprep_valid_expertise()
  expertise$products$A$sensory_identity$evidence_ids <- list("A::Invented")

  parsed <- NaileR:::.parse_qda_spaceprep_response(
    text = .spaceprep_json(expertise),
    expected_products = c("A", "B", "C"),
    valid_evidence_ids = .spaceprep_all_evidence_ids(x),
    context = NaileR:::.validate_qda_spaceprep_context(NULL),
    expertise_scope = "sensory",
    comparison_mode = "joint"
  )

  expect_identical(parsed$parse_status, "error")
  expect_match(parsed$parse_error, "unknown evidence ID", ignore.case = TRUE)
})

test_that("consumer claims must be hypotheses with validation needs", {
  x <- .spaceprep_qda_object()

  wrong_status <- .spaceprep_valid_expertise(
    consumer_claim = .spaceprep_claim(
      "May suit consumers preferring bitter products.",
      status = "expert_interpretation",
      evidence_ids = "A::Bitter"
    )
  )
  parsed_status <- NaileR:::.parse_qda_spaceprep_response(
    text = .spaceprep_json(wrong_status),
    expected_products = c("A", "B", "C"),
    valid_evidence_ids = .spaceprep_all_evidence_ids(x),
    context = NaileR:::.validate_qda_spaceprep_context(NULL),
    expertise_scope = "consumer",
    comparison_mode = "joint"
  )
  expect_identical(parsed_status$parse_status, "error")
  expect_match(parsed_status$parse_error, "must use status `hypothesis`", fixed = TRUE)

  missing_validation <- .spaceprep_valid_expertise(
    consumer_claim = .spaceprep_claim(
      "May suit consumers preferring bitter products.",
      status = "hypothesis",
      evidence_ids = "A::Bitter",
      validation_needed = NULL
    )
  )
  parsed_validation <- NaileR:::.parse_qda_spaceprep_response(
    text = .spaceprep_json(missing_validation),
    expected_products = c("A", "B", "C"),
    valid_evidence_ids = .spaceprep_all_evidence_ids(x),
    context = NaileR:::.validate_qda_spaceprep_context(NULL),
    expertise_scope = "consumer",
    comparison_mode = "joint"
  )
  expect_identical(parsed_validation$parse_status, "error")
  expect_match(parsed_validation$parse_error, "validation_needed", fixed = TRUE)
})

test_that("demographic consumer claims require explicit consumer context", {
  x <- .spaceprep_qda_object()
  demographic_claim <- .spaceprep_claim(
    "Women aged 35 to 50 may prefer this bitter profile.",
    status = "hypothesis",
    evidence_ids = "A::Bitter",
    validation_needed = "Validate with a stratified consumer study."
  )
  expertise <- .spaceprep_valid_expertise(consumer_claim = demographic_claim)

  without_context <- NaileR:::.parse_qda_spaceprep_response(
    text = .spaceprep_json(expertise),
    expected_products = c("A", "B", "C"),
    valid_evidence_ids = .spaceprep_all_evidence_ids(x),
    context = NaileR:::.validate_qda_spaceprep_context(NULL),
    expertise_scope = "consumer",
    comparison_mode = "joint"
  )
  expect_identical(without_context$parse_status, "error")
  expect_match(without_context$parse_error, "context\\$consumers")

  with_context <- NaileR:::.parse_qda_spaceprep_response(
    text = .spaceprep_json(expertise),
    expected_products = c("A", "B", "C"),
    valid_evidence_ids = .spaceprep_all_evidence_ids(x),
    context = NaileR:::.validate_qda_spaceprep_context(list(
      consumers = "The planned study explicitly recruits women aged 35 to 50."
    )),
    expertise_scope = "consumer",
    comparison_mode = "joint"
  )
  expect_identical(with_context$parse_status, "success")
})

test_that("isolated generation produces one LLM call per product and combines valid outputs", {
  x <- .spaceprep_qda_object()
  calls <- character(0)

  testthat::local_mocked_bindings(
    .call_llm_base = function(provider, model, prompt, output,
                              llm_api_options = list()) {
      product <- if (grepl("A::Bitter", prompt, fixed = TRUE)) {
        "A"
      } else if (grepl("B::Sweet", prompt, fixed = TRUE)) {
        "B"
      } else {
        "C"
      }
      calls <<- c(calls, product)
      expertise <- .spaceprep_valid_expertise()
      expertise$products <- expertise$products[product]
      expertise$portfolio <- list(
        overall_reading = NULL,
        product_families = list(),
        differentiation_issues = list(),
        cross_functional_priorities = list()
      )
      .spaceprep_json(expertise)
    },
    .package = "NaileR"
  )

  result <- nail_qda_spaceprep(
    x = x,
    comparison_mode = "isolated",
    generate = TRUE
  )

  expect_named(result, c("A", "B", "C"))
  expect_setequal(calls, c("A", "B", "C"))
  expect_true(all(vapply(result, function(unit) {
    identical(unit$parsed$parse_status, "success")
  }, logical(1))))

  combined <- attr(result, "product_expertise", exact = TRUE)
  expect_named(combined$products, c("A", "B", "C"))
  expect_false(combined$metadata$portfolio_interpretation_available)
})

test_that("legacy data interface is deprecated but remains available", {
  x <- .spaceprep_qda_object()

  testthat::local_mocked_bindings(
    nail_qda = function(...) x,
    .call_llm_base = function(...) stop("LLM was called"),
    .package = "NaileR"
  )

  expect_warning(
    result <- nail_qda_spaceprep(
      dataset = .spaceprep_dataset(),
      formul = "~Product+Panelist",
      firstvar = 3,
      lastvar = 5,
      generate = FALSE
    ),
    "deprecated"
  )

  expect_s3_class(result, "nail_qda_spaceprep")
  expect_true(result$metadata$legacy_interface)
})

test_that("deprecated expertise_mode maps to the new scope", {
  x <- .spaceprep_qda_object()

  expect_warning(
    result <- nail_qda_spaceprep(
      x = x,
      expertise_mode = "hybrid",
      generate = FALSE
    ),
    "expertise_mode"
  )

  expect_identical(result$metadata$expertise_scope, "cross_functional")
  expect_match(result$prompt, "CROSS-FUNCTIONAL PERSPECTIVE", fixed = TRUE)
})

test_that("new product_expertise has a minimal compatibility bridge to nail_qda_space", {
  x <- .spaceprep_qda_object()
  parsed <- NaileR:::.parse_qda_spaceprep_response(
    text = .spaceprep_json(.spaceprep_valid_expertise()),
    expected_products = c("A", "B", "C"),
    valid_evidence_ids = .spaceprep_all_evidence_ids(x),
    context = NaileR:::.validate_qda_spaceprep_context(NULL),
    expertise_scope = "cross_functional",
    comparison_mode = "joint"
  )
  prep <- list(product_expertise = parsed$product_expertise)

  legacy_view <- NaileR:::.extract_llm_profile_summaries(prep)

  expect_named(legacy_view, c("A", "B", "C"))
  expect_match(legacy_view$A$injectable_summary, "Intense bitter profile", fixed = TRUE)
  expect_match(legacy_view$A$injectable_summary, "Bitter and low-sweetness", fixed = TRUE)
  expect_identical(legacy_view$A$profile_clarity, NA_character_)
  expect_length(legacy_view$A$above_average_traits, 0L)
})

test_that("product families cite evidence for every listed product", {
  x <- .spaceprep_qda_object()
  expertise <- .spaceprep_valid_expertise()
  expertise$portfolio$product_families <- list(list(
    label = "Opposed profiles",
    products = list("A", "B"),
    text = "A and B form a contrasted family.",
    status = "expert_interpretation",
    evidence_ids = list("A::Bitter"),
    validation_needed = NULL
  ))

  parsed <- NaileR:::.parse_qda_spaceprep_response(
    text = .spaceprep_json(expertise),
    expected_products = c("A", "B", "C"),
    valid_evidence_ids = .spaceprep_all_evidence_ids(x),
    context = NaileR:::.validate_qda_spaceprep_context(NULL),
    expertise_scope = "sensory",
    comparison_mode = "joint"
  )

  expect_identical(parsed$parse_status, "error")
  expect_match(parsed$parse_error, "every listed product", fixed = TRUE)
})

test_that("isolated mode rejects portfolio-level claims", {
  x <- .spaceprep_qda_object()
  expertise <- .spaceprep_valid_expertise()
  expertise$products <- expertise$products["A"]
  expertise$portfolio <- list(
    overall_reading = .spaceprep_claim(
      "Product A has an intense bitter profile.",
      evidence_ids = "A::Bitter"
    ),
    product_families = list(),
    differentiation_issues = list(),
    cross_functional_priorities = list()
  )

  parsed <- NaileR:::.parse_qda_spaceprep_response(
    text = .spaceprep_json(expertise),
    expected_products = "A",
    valid_evidence_ids = c("A::Sweet", "A::Bitter"),
    context = NaileR:::.validate_qda_spaceprep_context(NULL),
    expertise_scope = "sensory",
    comparison_mode = "isolated"
  )

  expect_identical(parsed$parse_status, "error")
  expect_match(parsed$parse_error, "Portfolio-level claims", fixed = TRUE)
})

test_that("formulation directions are explicit recommendations", {
  x <- .spaceprep_qda_object()
  expertise <- .spaceprep_valid_expertise()
  expertise$products$A$formulation_directions[[1]]$status <- "expert_interpretation"
  expertise$products$A$formulation_directions[[1]]$validation_needed <- NULL

  parsed <- NaileR:::.parse_qda_spaceprep_response(
    text = .spaceprep_json(expertise),
    expected_products = c("A", "B", "C"),
    valid_evidence_ids = .spaceprep_all_evidence_ids(x),
    context = NaileR:::.validate_qda_spaceprep_context(NULL),
    expertise_scope = "formulation",
    comparison_mode = "joint"
  )

  expect_identical(parsed$parse_status, "error")
  expect_match(parsed$parse_error, "must use status `recommendation`", fixed = TRUE)
})

test_that("normalized context is retained in metadata", {
  x <- .spaceprep_qda_object()
  context <- list(
    category = "dark chocolate",
    constraints = "Sugar cannot be increased."
  )

  result <- nail_qda_spaceprep(
    x = x,
    context = context,
    generate = FALSE
  )

  expect_identical(result$metadata$context$category, "dark chocolate")
  expect_identical(result$metadata$context$constraints, "Sugar cannot be increased.")
  expect_setequal(result$metadata$context_fields, c("category", "constraints"))
})
