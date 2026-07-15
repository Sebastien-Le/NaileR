.make_qda_space_fixture <- function(adjmean = NULL) {
  if (is.null(adjmean)) {
    adjmean <- data.frame(
      Sweet = c(1, 2, 5, 4),
      Bitter = c(5, 3, 1, 2),
      Aroma = c(2, 5, 3, 1),
      row.names = c("A", "B", "C", "D"),
      check.names = FALSE
    )
  }

  empty_markers <- function() {
    data.frame(
      evidence_id = character(0), product = character(0),
      attribute = character(0), direction = character(0),
      coefficient = numeric(0), adjusted_mean = numeric(0),
      v_test = numeric(0), p_value = numeric(0),
      abs_v_test = numeric(0), rank = integer(0),
      stringsAsFactors = FALSE
    )
  }

  profiles <- lapply(rownames(adjmean), function(product) {
    means <- as.numeric(adjmean[product, , drop = TRUE])
    names(means) <- colnames(adjmean)
    centered <- means - colMeans(adjmean)
    keep <- which(abs(centered) > 1e-12)
    markers <- if (length(keep)) {
      v <- centered[keep] * 2
      p <- pmin(0.049, exp(-abs(v)))
      data.frame(
        evidence_id = paste(product, names(means)[keep], sep = "::"),
        product = product,
        attribute = names(means)[keep],
        direction = ifelse(v > 0, "higher than overall", "lower than overall"),
        coefficient = centered[keep],
        adjusted_mean = means[keep],
        v_test = as.numeric(v),
        p_value = as.numeric(p),
        abs_v_test = abs(as.numeric(v)),
        rank = seq_along(keep),
        stringsAsFactors = FALSE
      )
    } else {
      empty_markers()
    }
    above <- markers[markers$direction == "higher than overall", , drop = FALSE]
    below <- markers[markers$direction == "lower than overall", , drop = FALSE]
    list(
      product = product,
      adjusted_means = means,
      retained_markers = markers,
      above_average = above,
      below_average = below,
      metrics = list(
        n_retained = nrow(markers),
        n_above_average = nrow(above),
        n_below_average = nrow(below),
        max_abs_v_test = if (nrow(markers)) max(markers$abs_v_test) else NA_real_,
        median_abs_v_test = if (nrow(markers)) stats::median(markers$abs_v_test) else NA_real_,
        min_p_value = if (nrow(markers)) min(markers$p_value) else NA_real_
      )
    )
  })
  names(profiles) <- rownames(adjmean)

  out <- "mock qda prompt"
  attr(out, "decat_result") <- list(adjmean = adjmean)
  attr(out, "product_profiles") <- profiles
  attr(out, "qda_settings") <- list(formul = "~Product+Panelist", proba = 0.05)
  attr(out, "profile_summary") <- lapply(profiles, function(profile) {
    list(
      above = profile$above_average$attribute,
      below = profile$below_average$attribute,
      n_sig = profile$metrics$n_retained
    )
  })
  out
}

.qda_space_claim <- function(text, evidence_ids,
                             status = "expert_interpretation",
                             validation_needed = NULL) {
  list(
    text = text,
    status = status,
    evidence_ids = as.list(evidence_ids),
    validation_needed = validation_needed
  )
}

.qda_space_axis_json <- function(space, axis = 1L,
                                 unknown_id = NULL,
                                 recommendation_without_validation = FALSE) {
  evidence <- space$qda_space_evidence
  valid <- NaileR:::.qda_space_axis_valid_ids(evidence, axis)
  variable_id <- valid[grepl(paste0("^Dim", axis, "::variable::"), valid)][1]
  product_id <- valid[grepl(paste0("^Dim", axis, "::product::"), valid)][1]
  product <- sub(paste0("^Dim", axis, "::product::"), "", product_id)
  cited <- if (is.null(unknown_id)) variable_id else unknown_id
  nuance <- if (recommendation_without_validation) {
    .qda_space_claim("Move the product toward the opposite pole.", product_id,
                     status = "recommendation", validation_needed = NULL)
  } else {
    .qda_space_claim("Products on the same side are not necessarily identical.", product_id)
  }

  object <- list(
    dimension = axis,
    sensory_opposition = .qda_space_claim("A sensory opposition.", cited),
    negative_pole = .qda_space_claim("The negative pole.", variable_id),
    positive_pole = .qda_space_claim("The positive pole.", variable_id),
    representative_products = list(c(
      list(product = product),
      .qda_space_claim("A representative product.", product_id)
    )),
    within_pole_nuances = list(nuance),
    interpretation_limits = list(
      .qda_space_claim("Interpret the axis with regard to representation quality.",
                       paste0("Dim", axis, "::inertia"))
    )
  )
  jsonlite::toJSON(object, auto_unbox = TRUE, null = "null", pretty = FALSE)
}

.qda_space_portfolio_json <- function(space, unknown_id = NULL) {
  evidence <- space$qda_space_evidence
  registry <- evidence$evidence_registry
  distance_id <- registry$evidence_id[registry$evidence_type == "pairwise_distance"][1]
  axis_id <- registry$evidence_id[registry$evidence_type == "axis_variable"][1]
  cited <- if (is.null(unknown_id)) axis_id else unknown_id
  products <- rownames(evidence$adjusted_means)[1:2]

  object <- list(
    sensory_architecture = .qda_space_claim("The portfolio has a dominant sensory contrast.", cited),
    major_product_families = list(c(
      list(label = "Nearby products", products = as.list(products)),
      .qda_space_claim("These products form a geometric neighborhood.", distance_id)
    )),
    proximity_patterns = list(
      .qda_space_claim("Some products are close in the computed space.", distance_id)
    ),
    differentiation_risks = list(
      .qda_space_claim(
        "Close products may require differentiation testing.", distance_id,
        status = "hypothesis", validation_needed = "Direct discrimination or concept testing"
      )
    ),
    underoccupied_territories = list(),
    formulation_trajectories = list(
      .qda_space_claim(
        "A sensory movement could be explored.", axis_id,
        status = "recommendation", validation_needed = "Formulation trial and sensory retest"
      )
    ),
    marketing_implications = list(),
    consumer_research_hypotheses = list(
      .qda_space_claim(
        "Preference segments may align with the sensory opposition.", axis_id,
        status = "hypothesis", validation_needed = "Consumer preference mapping"
      )
    ),
    validation_priorities = list(
      .qda_space_claim(
        "Validate the proposed differentiation.", distance_id,
        status = "recommendation", validation_needed = "Independent validation study"
      )
    )
  )
  jsonlite::toJSON(object, auto_unbox = TRUE, null = "null", pretty = FALSE)
}

test_that("nail_qda_space builds complete offline mechanical evidence", {
  qda <- .make_qda_space_fixture()
  testthat::local_mocked_bindings(
    .call_llm_base = function(...) stop("LLM backend was called"),
    .package = "NaileR"
  )

  result <- nail_qda_space(
    x = qda,
    ncp = 3,
    scale.unit = FALSE,
    min_inertia_pct = 0,
    generate = FALSE
  )

  expect_s3_class(result, "nail_qda_space")
  expect_identical(result$parsed$parse_status, "not_generated")
  evidence <- result$qda_space_evidence
  expect_true(all(c(
    "adjusted_means", "product_profiles", "pca_result", "eigenvalues",
    "retained_axes", "axes", "product_geometry", "evidence_registry",
    "settings"
  ) %in% names(evidence)))
  expect_identical(evidence$adjusted_means, attr(qda, "decat_result")$adjmean)
  expect_identical(evidence$product_profiles, attr(qda, "product_profiles"))
  expect_identical(attr(result, "qda_space_evidence"), evidence)
})

test_that("PCA values, coordinates, contributions and cos2 are preserved", {
  result <- nail_qda_space(
    .make_qda_space_fixture(), ncp = 3, min_inertia_pct = 0,
    interpretation_level = "axis", generate = FALSE
  )
  evidence <- result$qda_space_evidence
  pca <- evidence$pca_result

  expect_equal(evidence$eigenvalues$eigenvalue, as.numeric(pca$eig[, 1]))
  expect_equal(evidence$eigenvalues$inertia_percent, as.numeric(pca$eig[, 2]))
  expect_equal(evidence$eigenvalues$cumulative_percent, as.numeric(pca$eig[, 3]))

  for (axis in evidence$retained_axes) {
    axis_name <- paste0("Dim.", axis)
    item <- evidence$axes[[paste0("Dim", axis)]]
    expect_equal(item$variables$coordinate, as.numeric(pca$var$coord[, axis_name]))
    expect_equal(item$variables$correlation, as.numeric(pca$var$cor[, axis_name]))
    expect_equal(item$variables$contribution, as.numeric(pca$var$contrib[, axis_name]))
    expect_equal(item$variables$cos2, as.numeric(pca$var$cos2[, axis_name]))
    expect_equal(item$products$coordinate, as.numeric(pca$ind$coord[, axis_name]))
    expect_equal(item$products$contribution, as.numeric(pca$ind$contrib[, axis_name]))
    expect_equal(item$products$cos2, as.numeric(pca$ind$cos2[, axis_name]))
  }
})

test_that("axis sides, ranks and selections are deterministic", {
  result <- nail_qda_space(
    .make_qda_space_fixture(), ncp = 2, min_inertia_pct = 0,
    top_n_var = 1, top_n_products = 1, generate = FALSE
  )
  item <- result$qda_space_evidence$axes$Dim1

  expect_true(all(item$variables$side %in% c("negative", "positive", "neutral")))
  expect_true(all(item$products$side %in% c("negative", "positive", "neutral")))
  expect_identical(sort(item$variables$rank_by_abs_coordinate), seq_len(nrow(item$variables)))
  expect_identical(sort(item$products$rank_by_abs_coordinate), seq_len(nrow(item$products)))
  expect_lte(nrow(item$selected_for_interpretation$negative_variables), 1L)
  expect_lte(nrow(item$selected_for_interpretation$positive_variables), 1L)
  expect_lte(nrow(item$selected_for_interpretation$negative_products), 1L)
  expect_lte(nrow(item$selected_for_interpretation$positive_products), 1L)
  expect_null(item$linked_product_expertise)
})

test_that("evidence identifiers are unique and deterministic", {
  result <- nail_qda_space(
    .make_qda_space_fixture(), ncp = 2, min_inertia_pct = 0,
    generate = FALSE
  )
  registry <- result$qda_space_evidence$evidence_registry
  expect_false(anyDuplicated(registry$evidence_id) > 0L)
  expect_true(any(grepl("^Dim1::variable::", registry$evidence_id)))
  expect_true(any(grepl("^Dim1::product::", registry$evidence_id)))
  expect_true(any(grepl("^geometry::distance::", registry$evidence_id)))
  expect_true(any(grepl("^geometry::nearest_neighbor::", registry$evidence_id)))
  expect_true(any(grepl("^product_profile::", registry$evidence_id)))
  expect_true(any(registry$evidence_id == "A::Sweet"))
})

test_that("product geometry equals direct Euclidean calculations", {
  result <- nail_qda_space(
    .make_qda_space_fixture(), ncp = 3, min_inertia_pct = 0,
    generate = FALSE
  )
  geometry <- result$qda_space_evidence$product_geometry
  direct <- as.matrix(stats::dist(geometry$coordinates))

  expect_equal(geometry$pairwise_distances, direct)
  expect_equal(geometry$pairwise_distances, t(geometry$pairwise_distances))
  expect_equal(diag(geometry$pairwise_distances), rep(0, nrow(direct)))
  pair_table <- geometry$pairwise_distance_table
  expect_identical(
    paste(pair_table$product_1, pair_table$product_2, sep = "::"),
    sort(paste(pair_table$product_1, pair_table$product_2, sep = "::"), method = "radix")
  )
  expect_equal(
    geometry$distance_to_origin$distance,
    sqrt(rowSums(geometry$coordinates^2))
  )

  for (product in rownames(direct)) {
    row <- direct[product, setdiff(colnames(direct), product)]
    expected <- sort(names(row)[abs(row - min(row)) <= sqrt(.Machine$double.eps)])
    actual <- geometry$nearest_neighbors$neighbor[
      geometry$nearest_neighbors$product == product
    ]
    expect_identical(actual, expected)
  }
})

test_that("identical product coordinates and nearest-neighbor ties are explicit", {
  adjmean <- data.frame(
    Sweet = c(1, 1, 4, 5),
    Bitter = c(5, 5, 2, 1),
    Aroma = c(2, 2, 5, 3),
    row.names = c("A", "B", "C", "D")
  )
  result <- nail_qda_space(
    .make_qda_space_fixture(adjmean), ncp = 3,
    min_inertia_pct = 0, generate = FALSE
  )
  geometry <- result$qda_space_evidence$product_geometry
  expect_equal(geometry$pairwise_distances["A", "B"], 0)
  nn_a <- geometry$nearest_neighbors[geometry$nearest_neighbors$product == "A", ]
  expect_identical(nn_a$neighbor[[1]], "B")
  expect_equal(nn_a$distance[[1]], 0)
})

test_that("equal nearest-neighbor distances are retained and resolved deterministically", {
  adjmean <- data.frame(
    Sweet = c(1, 2, 3),
    Bitter = c(3, 2, 1),
    row.names = c("A", "B", "C")
  )
  result <- nail_qda_space(
    .make_qda_space_fixture(adjmean), ncp = 2,
    min_inertia_pct = 0, generate = FALSE
  )
  neighbors <- result$qda_space_evidence$product_geometry$nearest_neighbors
  middle <- neighbors[neighbors$product == "B", , drop = FALSE]
  expect_identical(middle$neighbor, c("A", "C"))
  expect_identical(middle$tie_count, c(2L, 2L))
  expect_identical(middle$selected, c(TRUE, FALSE))
  expect_equal(middle$distance[[1]], middle$distance[[2]])
})

test_that("two-product spaces have one deterministic dimension and neighbor", {
  adjmean <- data.frame(
    Sweet = c(1, 4),
    Bitter = c(5, 2),
    row.names = c("A", "B")
  )
  result <- nail_qda_space(
    .make_qda_space_fixture(adjmean), ncp = 5,
    min_inertia_pct = 0, generate = FALSE
  )
  evidence <- result$qda_space_evidence
  expect_identical(evidence$settings$ncp_effective, 1L)
  expect_identical(evidence$product_geometry$nearest_neighbors$neighbor, c("B", "A"))
  expect_true(all(evidence$product_geometry$nearest_neighbors$selected))
})

test_that("exact and negligible coordinates are mechanically neutral", {
  side <- NaileR:::.qda_space_side(c(0, .Machine$double.eps, 1, -1))
  expect_identical(side, c("neutral", "neutral", "positive", "negative"))
})

test_that("ncp is limited by the available centered rank", {
  result <- nail_qda_space(
    .make_qda_space_fixture(), ncp = 99,
    min_inertia_pct = 0, generate = FALSE
  )
  settings <- result$qda_space_evidence$settings
  expect_identical(settings$ncp_requested, 99L)
  expect_lte(settings$ncp_effective, settings$rank_available)
  expect_lte(settings$ncp_effective, nrow(result$qda_space_evidence$adjusted_means) - 1L)
})

test_that("no retained axis remains a structured offline result", {
  result <- nail_qda_space(
    .make_qda_space_fixture(), ncp = 2,
    min_inertia_pct = 100, generate = FALSE
  )
  expect_length(result$qda_space_evidence$retained_axes, 0L)
  expect_length(result$prompt$axes, 0L)
  expect_null(result$prompt$portfolio)
  expect_identical(result$parsed$parse_status, "no_units")
})

test_that("invalid source objects fail explicitly", {
  expect_error(nail_qda_space(list()), "object returned by `nail_qda\\(\\)`")

  qda <- .make_qda_space_fixture()
  attr(qda, "product_profiles") <- NULL
  expect_error(nail_qda_space(qda), "no valid `product_profiles`")

  qda <- .make_qda_space_fixture()
  attr(qda, "decat_result") <- NULL
  expect_error(nail_qda_space(qda), "decat_result")
})

test_that("raw decat input remains deprecated but analyzable", {
  raw <- list(adjmean = attr(.make_qda_space_fixture(), "decat_result")$adjmean)
  expect_warning(
    result <- nail_qda_space(raw, min_inertia_pct = 0, generate = FALSE),
    "deprecated"
  )
  expect_identical(result$metadata$legacy_input, TRUE)
  expect_true(all(vapply(
    result$qda_space_evidence$product_profiles,
    function(x) nrow(x$retained_markers) == 0L,
    logical(1)
  )))
})

test_that("one product, one attribute and inconsistent profiles fail clearly", {
  one_product <- data.frame(Sweet = 1, Bitter = 2, row.names = "A")
  expect_error(
    nail_qda_space(.make_qda_space_fixture(one_product)),
    "at least 2 products"
  )

  one_attribute <- data.frame(Sweet = c(1, 2, 3), row.names = c("A", "B", "C"))
  expect_error(
    nail_qda_space(.make_qda_space_fixture(one_attribute)),
    "at least 2 sensory attributes"
  )

  qda <- .make_qda_space_fixture()
  profiles <- attr(qda, "product_profiles")
  profiles$A$adjusted_means[[1]] <- 999
  attr(qda, "product_profiles") <- profiles
  expect_error(nail_qda_space(qda), "inconsistent")
})

test_that("zero-variance attributes are explicit when scaling", {
  adjmean <- data.frame(
    Constant = c(1, 1, 1, 1),
    Sweet = c(1, 2, 4, 5),
    row.names = c("A", "B", "C", "D")
  )
  expect_error(
    nail_qda_space(.make_qda_space_fixture(adjmean), scale.unit = TRUE),
    "zero variance"
  )
})

test_that("non-syntactic and non-ASCII names are preserved", {
  adjmean <- data.frame(
    "Sweet taste" = c(1, 3, 5),
    "Amertume é" = c(5, 2, 1),
    row.names = c("P A", "P-é", "P/3"),
    check.names = FALSE
  )
  result <- nail_qda_space(
    .make_qda_space_fixture(adjmean), ncp = 2,
    min_inertia_pct = 0, generate = FALSE
  )
  expect_identical(rownames(result$qda_space_evidence$adjusted_means), rownames(adjmean))
  expect_identical(colnames(result$qda_space_evidence$adjusted_means), colnames(adjmean))
  expect_true(any(grepl("Amertume é", result$qda_space_evidence$evidence_registry$evidence_id,
                        fixed = TRUE)))
})

test_that("interpretation levels create only requested units", {
  qda <- .make_qda_space_fixture()
  axis <- nail_qda_space(qda, min_inertia_pct = 0,
                         interpretation_level = "axis", generate = FALSE)
  portfolio <- nail_qda_space(qda, min_inertia_pct = 0,
                              interpretation_level = "portfolio", generate = FALSE)
  both <- nail_qda_space(qda, min_inertia_pct = 0,
                         interpretation_level = "both", generate = FALSE)

  expect_gt(length(axis$prompt$axes), 0L)
  expect_null(axis$prompt$portfolio)
  expect_length(portfolio$prompt$axes, 0L)
  expect_type(portfolio$prompt$portfolio, "character")
  expect_gt(length(both$prompt$axes), 0L)
  expect_type(both$prompt$portfolio, "character")
})

test_that("prompt hierarchy separates evidence, expertise and context", {
  qda <- .make_qda_space_fixture()
  expertise <- list(
    portfolio = list(),
    products = list(A = list(
      sensory_identity = .qda_space_claim("A bitter product.", "A::Bitter")
    )),
    metadata = list()
  )
  result <- nail_qda_space(
    qda,
    product_expertise = expertise,
    context = list(category = "Chocolate"),
    introduction = "A trained panel evaluated the products.",
    request = "Emphasize differentiation.",
    interpretation_level = "axis",
    min_inertia_pct = 0,
    generate = FALSE
  )
  prompt <- result$prompt$axes[[1]]
  headers <- c(
    "# 1. ROLE", "# 2. SPACE GEOMETRY EVIDENCE",
    "# 3. PRODUCT SENSORY PROFILES", "# 4. OPTIONAL PRODUCT EXPERTISE",
    "# 5. USER-PROVIDED CONTEXT", "# 6. INTERPRETATION TASK",
    "# 7. MANDATORY EPISTEMIC RULES", "# 8. OUTPUT SCHEMA"
  )
  positions <- vapply(headers, function(header) regexpr(header, prompt, fixed = TRUE)[1], integer(1))
  expect_true(all(positions > 0L))
  expect_true(all(diff(positions) > 0L))
  expect_match(prompt, "Chocolate", fixed = TRUE)
  expect_match(prompt, "Emphasize differentiation", fixed = TRUE)

  portfolio <- nail_qda_space(
    qda,
    interpretation_level = "portfolio",
    top_n_var = 1,
    min_inertia_pct = 0,
    generate = FALSE
  )
  complete_axis_id <- portfolio$qda_space_evidence$axes$Dim1$variables$evidence_id[[1]]
  expect_match(portfolio$prompt$portfolio, complete_axis_id, fixed = TRUE)
})

test_that("product expertise formats are normalized and unknown products are signaled", {
  qda <- .make_qda_space_fixture()
  direct <- list(
    portfolio = list(),
    products = list(A = list(sensory_identity = .qda_space_claim("Identity", "A::Sweet"))),
    metadata = list()
  )
  full <- list(product_expertise = direct)
  attached <- structure(list(), product_expertise = direct)

  for (value in list(direct, full, attached)) {
    result <- nail_qda_space(
      qda, product_expertise = value, interpretation_level = "axis",
      min_inertia_pct = 0, generate = FALSE
    )
    expect_identical(names(result$product_expertise$products), "A")
  }

  unknown <- direct
  unknown$products$UNKNOWN <- list()
  expect_warning(
    result <- nail_qda_space(
      qda, product_expertise = unknown,
      min_inertia_pct = 0, generate = FALSE
    ),
    "absent from the PCA"
  )
  expect_false("UNKNOWN" %in% names(result$product_expertise$products))

  empty <- list(portfolio = list(), products = list(), metadata = list())
  empty_result <- nail_qda_space(
    qda, product_expertise = empty,
    min_inertia_pct = 0, generate = FALSE
  )
  expect_length(empty_result$product_expertise$products, 0L)

  malformed <- direct
  malformed$products$A$sensory_identity$validation_needed <- NULL
  expect_error(
    nail_qda_space(
      qda, product_expertise = malformed,
      min_inertia_pct = 0, generate = FALSE
    ),
    "missing required claim field"
  )
})

test_that("legacy summaries are deprecated and competing sources are rejected", {
  qda <- .make_qda_space_fixture()
  legacy <- list(A = list(parsed = list(
    injectable_summary = "Legacy summary",
    positioning_cues = "Legacy cue",
    core_profile = "Legacy profile",
    positive_traits = "Sweet",
    negative_traits = "Bitter"
  )))

  expect_warning(
    result <- nail_qda_space(
      qda, llm_product_summaries = legacy,
      min_inertia_pct = 0, generate = FALSE
    ),
    "deprecated"
  )
  expect_identical(result$metadata$product_expertise_source, "legacy")

  expect_warning(
    profile_result <- nail_qda_space(
      qda,
      profile_summary = attr(qda, "profile_summary"),
      min_inertia_pct = 0,
      generate = FALSE
    ),
    "deprecated"
  )
  expect_identical(profile_result$metadata$product_expertise_source, "legacy")

  expect_error(
    nail_qda_space(
      qda,
      product_expertise = list(portfolio = list(), products = list(), metadata = list()),
      llm_product_summaries = legacy
    ),
    "only one"
  )
})

test_that("qda_space_evidence is invariant to interpretive options", {
  qda <- .make_qda_space_fixture()
  base <- nail_qda_space(
    qda, ncp = 2, min_inertia_pct = 0,
    interpretation_level = "axis", expertise_scope = "sensory",
    generate = FALSE
  )$qda_space_evidence
  expertise <- list(portfolio = list(), products = list(A = list()), metadata = list())
  variant <- nail_qda_space(
    qda, ncp = 2, min_inertia_pct = 0,
    interpretation_level = "portfolio", expertise_scope = "marketing",
    request = "Different request", product_expertise = expertise,
    provider = "gemini", model = "different-model", generate = FALSE
  )$qda_space_evidence

  expect_identical(variant, base)
})

test_that("axis JSON is parsed and validated offline", {
  space <- nail_qda_space(
    .make_qda_space_fixture(), ncp = 2, min_inertia_pct = 0,
    interpretation_level = "axis", generate = FALSE
  )
  valid_ids <- NaileR:::.qda_space_axis_valid_ids(space$qda_space_evidence, 1L)
  parsed <- NaileR:::.parse_qda_space_response(
    text = .qda_space_axis_json(space, 1L),
    unit_type = "axis",
    valid_evidence_ids = valid_ids,
    analyzed_products = rownames(space$qda_space_evidence$adjusted_means),
    context_present = FALSE,
    consumer_context_present = FALSE,
    axis = 1L
  )
  expect_identical(parsed$parse_status, "success")
  expect_identical(parsed$interpretation$dimension, 1L)
})

test_that("invalid JSON and unknown evidence are explicit", {
  space <- nail_qda_space(
    .make_qda_space_fixture(), ncp = 2, min_inertia_pct = 0,
    interpretation_level = "axis", generate = FALSE
  )
  valid_ids <- NaileR:::.qda_space_axis_valid_ids(space$qda_space_evidence, 1L)
  common <- list(
    unit_type = "axis",
    valid_evidence_ids = valid_ids,
    analyzed_products = rownames(space$qda_space_evidence$adjusted_means),
    context_present = FALSE,
    consumer_context_present = FALSE,
    axis = 1L
  )

  invalid <- do.call(NaileR:::.parse_qda_space_response,
                     c(list(text = "not json"), common))
  expect_identical(invalid$parse_status, "error")
  expect_type(invalid$parse_error, "character")

  fenced <- do.call(
    NaileR:::.parse_qda_space_response,
    c(list(text = paste0("```json\n", .qda_space_axis_json(space, 1L), "\n```")), common)
  )
  expect_identical(fenced$parse_status, "error")
  expect_match(fenced$parse_error, "strict JSON", fixed = TRUE)

  unknown <- do.call(NaileR:::.parse_qda_space_response,
                     c(list(text = .qda_space_axis_json(space, 1L, "unknown::evidence")), common))
  expect_identical(unknown$parse_status, "error")
  expect_match(unknown$parse_error, "unknown evidence", ignore.case = TRUE)
})

test_that("an axis cannot cite evidence belonging only to another axis", {
  space <- nail_qda_space(
    .make_qda_space_fixture(), ncp = 2, min_inertia_pct = 0,
    interpretation_level = "axis", generate = FALSE
  )
  skip_if(length(space$qda_space_evidence$retained_axes) < 2L)
  other_id <- space$qda_space_evidence$axes$Dim2$selected_for_interpretation$positive_variables$evidence_id[1]
  if (is.na(other_id)) {
    other_id <- space$qda_space_evidence$axes$Dim2$selected_for_interpretation$negative_variables$evidence_id[1]
  }
  parsed <- NaileR:::.parse_qda_space_response(
    text = .qda_space_axis_json(space, 1L, other_id),
    unit_type = "axis",
    valid_evidence_ids = NaileR:::.qda_space_axis_valid_ids(space$qda_space_evidence, 1L),
    analyzed_products = rownames(space$qda_space_evidence$adjusted_means),
    context_present = FALSE,
    consumer_context_present = FALSE,
    axis = 1L
  )
  expect_identical(parsed$parse_status, "error")
  expect_match(parsed$parse_error, "unknown evidence", ignore.case = TRUE)
})

test_that("recommendations require validation_needed", {
  space <- nail_qda_space(
    .make_qda_space_fixture(), ncp = 1, min_inertia_pct = 0,
    interpretation_level = "axis", generate = FALSE
  )
  parsed <- NaileR:::.parse_qda_space_response(
    text = .qda_space_axis_json(space, 1L,
                                recommendation_without_validation = TRUE),
    unit_type = "axis",
    valid_evidence_ids = NaileR:::.qda_space_axis_valid_ids(space$qda_space_evidence, 1L),
    analyzed_products = rownames(space$qda_space_evidence$adjusted_means),
    context_present = FALSE,
    consumer_context_present = FALSE,
    axis = 1L
  )
  expect_identical(parsed$parse_status, "error")
  expect_match(parsed$parse_error, "validation_needed", fixed = TRUE)
})

test_that("portfolio JSON is parsed with traceable hypotheses and recommendations", {
  space <- nail_qda_space(
    .make_qda_space_fixture(), ncp = 2, min_inertia_pct = 0,
    interpretation_level = "portfolio", generate = FALSE
  )
  parsed <- NaileR:::.parse_qda_space_response(
    text = .qda_space_portfolio_json(space),
    unit_type = "portfolio",
    valid_evidence_ids = space$qda_space_evidence$evidence_registry$evidence_id,
    analyzed_products = rownames(space$qda_space_evidence$adjusted_means),
    context_present = FALSE,
    consumer_context_present = FALSE
  )
  expect_identical(parsed$parse_status, "success")
  expect_identical(
    parsed$interpretation$consumer_research_hypotheses[[1]]$status,
    "hypothesis"
  )
  expect_identical(
    parsed$interpretation$formulation_trajectories[[1]]$status,
    "recommendation"
  )
})

test_that("demographic claims require explicit consumer context", {
  space <- nail_qda_space(
    .make_qda_space_fixture(), ncp = 2, min_inertia_pct = 0,
    interpretation_level = "portfolio", generate = FALSE
  )
  object <- jsonlite::fromJSON(.qda_space_portfolio_json(space), simplifyVector = FALSE)
  id <- space$qda_space_evidence$evidence_registry$evidence_id[1]
  object$consumer_research_hypotheses <- list(
    .qda_space_claim(
      "This product targets women aged 35 to 50.", id,
      status = "hypothesis", validation_needed = "Consumer study"
    )
  )
  text <- jsonlite::toJSON(object, auto_unbox = TRUE, null = "null")

  parsed <- NaileR:::.parse_qda_space_response(
    text = text,
    unit_type = "portfolio",
    valid_evidence_ids = space$qda_space_evidence$evidence_registry$evidence_id,
    analyzed_products = rownames(space$qda_space_evidence$adjusted_means),
    context_present = FALSE,
    consumer_context_present = FALSE
  )
  expect_identical(parsed$parse_status, "error")
  expect_match(parsed$parse_error, "demographic", ignore.case = TRUE)
})

test_that("generate TRUE preserves prompts, responses and parsed axis output", {
  qda <- .make_qda_space_fixture()
  offline <- nail_qda_space(
    qda, ncp = 1, min_inertia_pct = 0,
    interpretation_level = "axis", generate = FALSE
  )
  response_json <- .qda_space_axis_json(offline, 1L)

  testthat::local_mocked_bindings(
    .call_llm_base = function(provider, model, prompt, output, llm_api_options) {
      expect_identical(output, "text")
      response_json
    },
    .package = "NaileR"
  )

  generated <- nail_qda_space(
    qda, ncp = 1, min_inertia_pct = 0,
    interpretation_level = "axis", generate = TRUE
  )
  expect_identical(generated$response$axes$Dim1, response_json)
  expect_identical(generated$parsed$axes$Dim1$parse_status, "success")
  expect_identical(generated$parsed$parse_status, "success")
  expect_identical(generated$axis_interpretations$Dim1$dimension, 1L)
  expect_null(generated$portfolio_interpretation)
})

test_that("invalid generated JSON is retained with an explicit parse error", {
  testthat::local_mocked_bindings(
    .call_llm_base = function(...) "invalid JSON",
    .package = "NaileR"
  )
  generated <- nail_qda_space(
    .make_qda_space_fixture(), ncp = 1, min_inertia_pct = 0,
    interpretation_level = "axis", generate = TRUE
  )
  expect_identical(generated$response$axes$Dim1, "invalid JSON")
  expect_identical(generated$parsed$axes$Dim1$parse_status, "error")
  expect_type(generated$parsed$axes$Dim1$parse_error, "character")
  expect_null(generated$axis_interpretations$Dim1)
})

test_that("deprecated expertise_mode maps only prompt scope", {
  expect_warning(
    result <- nail_qda_space(
      .make_qda_space_fixture(), ncp = 1, min_inertia_pct = 0,
      expertise_mode = "hybrid", generate = FALSE
    ),
    "deprecated"
  )
  expect_identical(result$metadata$expertise_scope, "cross_functional")

  expect_warning(
    positioning <- nail_qda_space(
      .make_qda_space_fixture(), ncp = 1, min_inertia_pct = 0,
      expertise_mode = "positioning", generate = FALSE
    ),
    "deprecated"
  )
  expect_identical(positioning$metadata$expertise_scope, "innovation")
})
