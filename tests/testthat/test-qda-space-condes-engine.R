make_qda_space_condes_test_object <- function() {
  products <- paste0("choc", 1:6)
  attributes <- c(
    "CocoaF",
    "MilkF",
    "Sweetness",
    "Bitterness",
    "Crunchy",
    "Melting"
  )

  means <- rbind(
    choc1 = c(8.2, 2.0, 3.0, 8.0, 4.0, 3.0),
    choc2 = c(7.2, 2.6, 4.0, 7.0, 7.4, 4.0),
    choc3 = c(3.0, 8.2, 8.0, 2.0, 2.2, 8.0),
    choc4 = c(6.2, 3.2, 3.6, 6.4, 5.0, 3.6),
    choc5 = c(7.6, 3.1, 4.3, 6.0, 8.0, 4.2),
    choc6 = c(4.2, 6.2, 7.0, 3.0, 8.0, 5.2)
  )
  colnames(means) <- attributes

  marker_table <- function(product,
                           rows,
                           product_index) {
    if (length(rows) == 0L) {
      return(
        NaileR:::.empty_qda_marker_table()
      )
    }

    out <- data.frame(
      evidence_id = sprintf(
        "QDAP%03dE%03d",
        product_index,
        seq_along(rows)
      ),
      product = product,
      attribute = vapply(
        rows,
        `[[`,
        character(1),
        "attribute"
      ),
      direction = vapply(
        rows,
        `[[`,
        character(1),
        "direction"
      ),
      coefficient = NA_real_,
      adjusted_mean = vapply(
        rows,
        `[[`,
        numeric(1),
        "mean"
      ),
      p_value = seq(
        0.001,
        0.001 * length(rows),
        length.out = length(rows)
      ),
      v_test = vapply(
        rows,
        function(z) {
          if (z$direction == "higher") 5 else -5
        },
        numeric(1)
      ),
      rank = seq_along(rows),
      stringsAsFactors = FALSE
    )

    out
  }

  profile_rows <- list(
    choc1 = list(
      list(attribute = "CocoaF", direction = "higher", mean = 8.2),
      list(attribute = "Bitterness", direction = "higher", mean = 8.0),
      list(attribute = "MilkF", direction = "lower", mean = 2.0),
      list(attribute = "Sweetness", direction = "lower", mean = 3.0)
    ),
    choc2 = list(
      list(attribute = "CocoaF", direction = "higher", mean = 7.2),
      list(attribute = "Crunchy", direction = "higher", mean = 7.4),
      list(attribute = "MilkF", direction = "lower", mean = 2.6)
    ),
    choc3 = list(
      list(attribute = "MilkF", direction = "higher", mean = 8.2),
      list(attribute = "Sweetness", direction = "higher", mean = 8.0),
      list(attribute = "Melting", direction = "higher", mean = 8.0),
      list(attribute = "CocoaF", direction = "lower", mean = 3.0),
      list(attribute = "Bitterness", direction = "lower", mean = 2.0)
    ),
    choc4 = list(
      list(attribute = "Bitterness", direction = "higher", mean = 6.4),
      list(attribute = "Sweetness", direction = "lower", mean = 3.6)
    ),
    choc5 = list(
      list(attribute = "CocoaF", direction = "higher", mean = 7.6),
      list(attribute = "Crunchy", direction = "higher", mean = 8.0)
    ),
    choc6 = list(
      list(attribute = "Sweetness", direction = "higher", mean = 7.0),
      list(attribute = "Crunchy", direction = "higher", mean = 8.0)
    )
  )

  pp <- list(
    products = stats::setNames(
      lapply(
        seq_along(products),
        function(i) {
          p <- products[[i]]
          markers <- marker_table(
            p,
            profile_rows[[p]],
            i
          )

          list(
            product = p,
            adjusted_means = data.frame(
              attribute = attributes,
              adjusted_mean =
                as.numeric(means[p, ]),
              stringsAsFactors = FALSE
            ),
            retained_markers = markers,
            above_average = markers[
              markers$direction == "higher",
              ,
              drop = FALSE
            ],
            below_average = markers[
              markers$direction == "lower",
              ,
              drop = FALSE
            ],
            metrics = list(
              n_attributes_total =
                length(attributes),
              n_markers_retained =
                nrow(markers)
            )
          )
        }
      ),
      products
    ),
    evidence_registry =
      NaileR:::.empty_qda_marker_table(),
    settings = list(),
    metadata = list()
  )
  class(pp) <- c(
    "nail_qda_product_profiles",
    "list"
  )

  pi <- list(
    products = stats::setNames(
      lapply(
        products,
        function(p) {
          list(
            product = p,
            status = "available",
            source = if (p %in%
                         c("choc3", "choc6")) {
              "expert"
            } else {
              "llm_pass1"
            },
            core_profile = paste(
              "Retained sensory interpretation for",
              p
            ),
            dominant_configuration = c(
              paste("dominant", p)
            ),
            secondary_configuration = c(
              paste("secondary", p)
            ),
            distinctive_interpretation =
              paste("distinctive", p),
            descriptive_name =
              NA_character_,
            evidence_ids =
              pp$products[[p]]$
                retained_markers$
                evidence_id,
            response_key = p,
            raw_block =
              paste("raw", p)
          )
        }
      ),
      products
    ),
    metadata = list(
      n_available = length(products)
    )
  )
  class(pi) <- c(
    "nail_qda_product_interpretations",
    "list"
  )

  x <- list(
    placeholder = TRUE
  )
  attr(x, "product_profiles") <- pp
  attr(x, "product_interpretations") <- pi
  x
}


make_sensochoc_qda_space_test_object <- function() {
  data(chocolates, package = "SensoMineR")

  nail_qda(
    dataset = sensochoc,
    formul = "~Product+Panelist",
    firstvar = 5,
    lastvar = 18,
    sample.pct = 1,
    isolate.groups = TRUE,
    generate = FALSE
  )
}


test_that("qda_space really uses nail_condes latent profiles", {
  qda <- make_qda_space_condes_test_object()

  space <- nail_qda_space(
    qda,
    ncp = 1,
    scale.unit = TRUE,
    min_inertia_pct = 0,
    top_n_var = 6,
    top_n_products = 3,
    generate = FALSE
  )

  evidence <- attr(
    space,
    "qda_space_evidence",
    exact = TRUE
  )
  axis_condes <- attr(
    space,
    "axis_condes",
    exact = TRUE
  )

  expect_s3_class(
    evidence,
    "nail_qda_space_evidence"
  )
  expect_named(
    evidence$axes,
    "Dim1"
  )
  expect_named(
    axis_condes,
    "Dim1"
  )

  condes_profile <- attr(
    axis_condes$Dim1,
    "continuous_profile",
    exact = TRUE
  )

  expect_s3_class(
    condes_profile,
    "nail_condes_continuous_profile"
  )

  expect_identical(
    attr(
      axis_condes$Dim1,
      "condes_settings",
      exact = TRUE
    )$interpretation_mode,
    "latent"
  )

  expect_true(
    is.list(condes_profile$end_profiles)
  )

  structure <- evidence$axes$Dim1$
    sensory_structure

  if (nrow(structure) > 0L) {
    expect_true(all(
      grepl(
        "^CONDQ",
        structure$evidence_id
      )
    ))
  }

  expect_identical(
    evidence$settings$
      axis_characterization,
    "nail_condes_latent"
  )
})


test_that("qda_space prompt is analyst-facing, not implementation-facing", {
  qda <- make_qda_space_condes_test_object()

  space <- nail_qda_space(
    qda,
    ncp = 1,
    min_inertia_pct = 0,
    top_n_var = 6,
    top_n_products = 3,
    generate = FALSE
  )

  prompt <- nail_prompt(
    space,
    select = "Dim1",
    print = FALSE
  )

  expect_match(
    prompt,
    "Sensory contrasts defining the dimension",
    fixed = TRUE
  )
  expect_match(
    prompt,
    "Products representing the higher/positive end",
    fixed = TRUE
  )
  expect_match(
    prompt,
    "Product sensory summary",
    fixed = TRUE
  )
  expect_match(
    prompt,
    "Retained sensory interpretation for choc3",
    fixed = TRUE
  )
  expect_match(
    prompt,
    "expert-edited interpretation",
    fixed = TRUE
  )

  expect_false(
    grepl(
      "nail_condes",
      prompt,
      fixed = TRUE
    )
  )
  expect_false(
    grepl(
      "nail_qda",
      prompt,
      fixed = TRUE
    )
  )
  expect_false(
    grepl(
      "Intermediate value",
      prompt,
      fixed = TRUE
    )
  )
  expect_false(
    grepl(
      "End-profile evidence",
      prompt,
      fixed = TRUE
    )
  )
})


test_that("qda_space prompts distinguish descriptive evidence and geometry", {
  qda <- make_qda_space_condes_test_object()

  prompts <- lapply(
    c("sensory", "positioning", "hybrid"),
    function(mode) {
      space <- nail_qda_space(
        qda,
        ncp = 1,
        min_inertia_pct = 0,
        top_n_var = 6,
        top_n_products = 3,
        expertise_mode = mode,
        generate = FALSE
      )

      nail_prompt(
        space,
        select = "Dim1",
        print = FALSE
      )
    }
  )

  for (prompt in prompts) {
    expect_match(
      prompt,
      "descriptive characterizations of the PCA structure, not independent validation tests",
      fixed = TRUE
    )
    expect_match(
      prompt,
      "contribution describes influence on the axis, whereas cos2 describes how well a product is represented on it",
      fixed = TRUE
    )
    expect_match(
      prompt,
      "contribution=",
      fixed = TRUE
    )
    expect_match(
      prompt,
      "cos2=",
      fixed = TRUE
    )
    expect_match(
      prompt,
      "Do not add cultural, hedonic, or marketing claims",
      fixed = TRUE
    )
    expect_match(
      prompt,
      "|r|=0.",
      fixed = TRUE
    )
  }
})


test_that("qda_space marks an axis without selected associations as insufficiently characterized", {
  qda <- make_qda_space_condes_test_object()

  space <- nail_qda_space(
    qda,
    ncp = 1,
    min_inertia_pct = 0,
    top_n_var = 6,
    top_n_products = 3,
    condes_proba = 1e-10,
    generate = FALSE
  )

  evidence <- attr(
    space,
    "qda_space_evidence",
    exact = TRUE
  )
  expect_length(evidence$axes, 1L)
  expect_identical(
    nrow(evidence$axes$Dim1$sensory_structure),
    0L
  )

  prompt <- nail_prompt(
    space,
    select = "Dim1",
    print = FALSE
  )

  expect_match(
    prompt,
    "No attribute-axis association was selected under the current axis-characterization settings.",
    fixed = TRUE
  )
  expect_match(
    prompt,
    "The individual QDA markers shown below are not evidence that this axis has a sensory characterization.",
    fixed = TRUE
  )
  expect_match(
    prompt,
    "do not present a sensory continuum or dimension name as firmly established",
    fixed = TRUE
  )
})


test_that("qda_space keeps evidence invariant across expertise modes", {
  qda <- make_qda_space_condes_test_object()

  reference <- nail_qda_space(
    qda,
    ncp = 1,
    min_inertia_pct = 0,
    top_n_var = 6,
    top_n_products = 3,
    expertise_mode = "sensory",
    generate = FALSE
  )
  reference_evidence <- attr(
    reference,
    "qda_space_evidence",
    exact = TRUE
  )

  for (mode in c("positioning", "hybrid")) {
    current <- nail_qda_space(
      qda,
      ncp = 1,
      min_inertia_pct = 0,
      top_n_var = 6,
      top_n_products = 3,
      expertise_mode = mode,
      generate = FALSE
    )
    current_evidence <- attr(
      current,
      "qda_space_evidence",
      exact = TRUE
    )

    expect_identical(
      current_evidence$adjusted_means,
      reference_evidence$adjusted_means
    )
    expect_identical(
      current_evidence$pca_result,
      reference_evidence$pca_result
    )
    expect_identical(
      current_evidence$axes$Dim1$sensory_structure,
      reference_evidence$axes$Dim1$sensory_structure
    )
    expect_identical(
      attr(current, "product_profiles", exact = TRUE),
      attr(reference, "product_profiles", exact = TRUE)
    )
    expect_identical(
      attr(current, "product_interpretations", exact = TRUE),
      attr(reference, "product_interpretations", exact = TRUE)
    )
  }
})


test_that("qda_space preserves full condes end profiles outside final prompt", {
  qda <- make_qda_space_condes_test_object()

  space <- nail_qda_space(
    qda,
    ncp = 1,
    min_inertia_pct = 0,
    generate = FALSE
  )

  axis_condes <- attr(
    space,
    "axis_condes",
    exact = TRUE
  )

  cp <- attr(
    axis_condes$Dim1,
    "continuous_profile",
    exact = TRUE
  )

  expect_true(
    is.data.frame(cp$end_profiles$low)
  )
  expect_true(
    is.data.frame(cp$end_profiles$high)
  )

  prompt <- nail_prompt(
    space,
    select = "Dim1",
    print = FALSE
  )

  expect_false(
    grepl(
      "Above-average value",
      prompt,
      fixed = TRUE
    )
  )
  expect_false(
    grepl(
      "Below-average value",
      prompt,
      fixed = TRUE
    )
  )
  expect_false(
    grepl(
      "Intermediate value",
      prompt,
      fixed = TRUE
    )
  )
})


test_that("qda_space reuses expert-edited product interpretations", {
  qda <- make_qda_space_condes_test_object()

  qda <- nail_qda_interpretation(
    qda,
    product = "choc3",
    core_profile =
      "Expert sensory profile retained for choc3.",
    dominant_configuration =
      c("milky", "sweet"),
    secondary_configuration =
      c("lower cocoa"),
    print = FALSE
  )

  space <- nail_qda_space(
    qda,
    ncp = 1,
    min_inertia_pct = 0,
    top_n_products = 3,
    generate = FALSE
  )

  prompt <- nail_prompt(
    space,
    select = "Dim1",
    print = FALSE
  )

  expect_match(
    prompt,
    "Expert sensory profile retained for choc3.",
    fixed = TRUE
  )
  expect_false(
    grepl(
      "Dominant configuration:",
      prompt,
      fixed = TRUE
    )
  )
  expect_false(
    grepl(
      "Secondary configuration:",
      prompt,
      fixed = TRUE
    )
  )
  expect_match(
    prompt,
    "expert-edited interpretation",
    fixed = TRUE
  )
})


test_that("qda_space does not alter canonical QDA product profiles", {
  qda <- make_qda_space_condes_test_object()

  before <- attr(
    qda,
    "product_profiles",
    exact = TRUE
  )

  space <- nail_qda_space(
    qda,
    ncp = 1,
    min_inertia_pct = 0,
    generate = FALSE
  )

  expect_identical(
    attr(
      space,
      "product_profiles",
      exact = TRUE
    ),
    before
  )
})


test_that("qda_space final generation calls LLM only at the axis stage", {
  qda <- make_qda_space_condes_test_object()
  call_count <- 0L

  testthat::local_mocked_bindings(
    .call_llm_base = function(
        provider,
        model,
        prompt,
        output,
        llm_api_options) {
      call_count <<- call_count + 1L

      data.frame(
        model = model,
        response =
          "Final sensory interpretation of Dim1.",
        stringsAsFactors = FALSE
      )
    },
    .package = "NaileR"
  )

  warnings <- character()
  space <- withCallingHandlers(
    nail_qda_space(
      qda,
      ncp = 1,
      min_inertia_pct = 0,
      generate = TRUE,
      model = "mock-model"
    ),
    warning = function(condition) {
      warnings <<- c(warnings, conditionMessage(condition))
      invokeRestart("muffleWarning")
    }
  )

  # nail_condes() is always generate = FALSE internally,
  # so only the final axis interpretation calls the backend.
  expect_identical(
    call_count,
    1L
  )
  expect_length(warnings, 1L)
  expect_match(
    warnings[[1L]],
    "original QDA and PCA/CONDES statistical evidence",
    fixed = TRUE
  )

  expect_identical(
    nail_response(
      space,
      select = "Dim1",
      print = FALSE
    ),
    "Final sensory interpretation of Dim1."
  )
})


test_that("qda_space does not warn for expert-only interpretations", {
  qda <- make_qda_space_condes_test_object()
  interpretations <- attr(
    qda,
    "product_interpretations",
    exact = TRUE
  )
  interpretations$products <- lapply(
    interpretations$products,
    function(item) {
      item$source <- "expert"
      item
    }
  )
  attr(qda, "product_interpretations") <- interpretations

  testthat::local_mocked_bindings(
    .call_llm_base = function(
        provider,
        model,
        prompt,
        output,
        llm_api_options) {
      data.frame(
        model = model,
        response = "Final sensory interpretation of Dim1.",
        stringsAsFactors = FALSE
      )
    },
    .package = "NaileR"
  )

  expect_no_warning(
    nail_qda_space(
      qda,
      ncp = 1,
      min_inertia_pct = 0,
      generate = TRUE,
      model = "mock-model"
    )
  )
})


test_that("qda_space does not warn without reusable interpretations", {
  qda <- make_qda_space_condes_test_object()
  interpretations <- attr(
    qda,
    "product_interpretations",
    exact = TRUE
  )
  interpretations$products <- lapply(
    interpretations$products,
    function(item) {
      item$status <- "not_generated"
      item$core_profile <- NA_character_
      item
    }
  )
  attr(qda, "product_interpretations") <- interpretations

  testthat::local_mocked_bindings(
    .call_llm_base = function(
        provider,
        model,
        prompt,
        output,
        llm_api_options) {
      data.frame(
        model = model,
        response = "Final sensory interpretation of Dim1.",
        stringsAsFactors = FALSE
      )
    },
    .package = "NaileR"
  )

  expect_no_warning(
    nail_qda_space(
      qda,
      ncp = 1,
      min_inertia_pct = 0,
      generate = TRUE,
      model = "mock-model"
    )
  )
})


test_that("qda_space records characterization status per retained axis", {
  qda <- make_sensochoc_qda_space_test_object()

  both <- nail_qda_space(
    qda,
    ncp = 2,
    min_inertia_pct = 0,
    condes_proba = 1,
    generate = FALSE
  )
  both_evidence <- attr(
    both,
    "qda_space_evidence",
    exact = TRUE
  )
  expect_length(both_evidence$axes, 2L)
  expect_true(all(vapply(
    both_evidence$axes,
    function(axis) {
      identical(
        axis$characterization_status,
        "associations_selected"
      )
    },
    logical(1)
  )))

  mixed <- nail_qda_space(
    qda,
    ncp = 2,
    min_inertia_pct = 0,
    condes_proba = 0.05,
    generate = FALSE
  )
  mixed_evidence <- attr(
    mixed,
    "qda_space_evidence",
    exact = TRUE
  )
  mixed_status <- vapply(
    mixed_evidence$axes,
    function(axis) axis$characterization_status,
    character(1)
  )
  expect_identical(
    unname(mixed_status),
    c(
      "associations_selected",
      "no_selected_associations"
    )
  )
  expect_true(
    nzchar(
      mixed_evidence$axes$Dim2$deterministic_restitution
    )
  )
  expect_identical(
    mixed_evidence$axes$Dim2$selected_association_count,
    0L
  )
  expect_true(
    is.list(
      mixed_evidence$axes$Dim2$continuous_profile
    )
  )

  none <- nail_qda_space(
    qda,
    ncp = 2,
    min_inertia_pct = 0,
    condes_proba = 1e-10,
    generate = FALSE
  )
  none_evidence <- attr(
    none,
    "qda_space_evidence",
    exact = TRUE
  )
  expect_true(all(vapply(
    none_evidence$axes,
    function(axis) {
      identical(
        axis$characterization_status,
        "no_selected_associations"
      )
    },
    logical(1)
  )))
})


test_that("qda_space blocks only insufficiently characterized axes", {
  qda <- make_sensochoc_qda_space_test_object()
  calls <- character()

  testthat::local_mocked_bindings(
    .call_llm_base = function(
        provider,
        model,
        prompt,
        output,
        llm_api_options) {
      calls <<- c(calls, prompt)
      data.frame(
        model = model,
        response = "Generated interpretation for the characterized axis.",
        stringsAsFactors = FALSE
      )
    },
    .package = "NaileR"
  )

  mixed <- nail_qda_space(
    qda,
    ncp = 2,
    min_inertia_pct = 0,
    condes_proba = 0.05,
    generate = TRUE,
    model = "mock-model"
  )
  io <- attr(mixed, "llm_io", exact = TRUE)

  expect_length(calls, 1L)
  expect_named(io$prompts, c("Dim1", "Dim2"))
  expect_named(io$responses, "Dim1")
  expect_identical(
    io$metadata$submitted_axes,
    "Dim1"
  )
  expect_identical(
    io$metadata$deterministic_axes,
    "Dim2"
  )
  expect_s3_class(
    mixed$Dim2,
    "nail_qda_space_deterministic_axis"
  )
  expect_false(mixed$Dim2$llm_called)
  expect_identical(
    nail_response(mixed, select = "Dim1", print = FALSE),
    "Generated interpretation for the characterized axis."
  )
  expect_error(
    nail_response(mixed, select = "Dim2", print = FALSE),
    "Unknown `select"
  )
  expect_match(
    mixed$Dim2$restitution,
    "No LLM generation was performed for this axis",
    fixed = TRUE
  )
})


test_that("qda_space performs no LLM calls when no axis is characterized", {
  qda <- make_qda_space_condes_test_object()
  calls <- 0L

  testthat::local_mocked_bindings(
    .call_llm_base = function(
        provider,
        model,
        prompt,
        output,
        llm_api_options) {
      calls <<- calls + 1L
      data.frame(
        model = model,
        response = "Should not be called.",
        stringsAsFactors = FALSE
      )
    },
    .package = "NaileR"
  )

  none <- nail_qda_space(
    qda,
    ncp = 2,
    min_inertia_pct = 0,
    condes_proba = 1e-10,
    generate = TRUE,
    model = "mock-model"
  )
  io <- attr(none, "llm_io", exact = TRUE)

  expect_identical(calls, 0L)
  expect_null(io$responses)
  expect_identical(io$metadata$submitted_axes, NULL)
  expect_identical(
    io$metadata$deterministic_axes,
    c("Dim1", "Dim2")
  )
  expect_s3_class(
    none$Dim1,
    "nail_qda_space_deterministic_axis"
  )
  expect_s3_class(
    none$Dim2,
    "nail_qda_space_deterministic_axis"
  )
})


test_that("qda_space preserves the no-retained-axis contract", {
  qda <- make_qda_space_condes_test_object()

  out <- nail_qda_space(
    qda,
    ncp = 2,
    min_inertia_pct = 100,
    generate = TRUE
  )
  evidence <- attr(
    out,
    "qda_space_evidence",
    exact = TRUE
  )

  expect_length(evidence$axes, 0L)
  expect_identical(evidence$retained_axes, integer(0))
  expect_false(inherits(out, "nail_qda_space_deterministic_axis"))
})


test_that("qda_space defaults to a scaled PCA in rebuilt workflow", {
  qda <- make_qda_space_condes_test_object()

  space <- nail_qda_space(
    qda,
    ncp = 1,
    min_inertia_pct = 0,
    generate = FALSE
  )

  evidence <- attr(
    space,
    "qda_space_evidence",
    exact = TRUE
  )

  expect_true(
    isTRUE(evidence$settings$scale_unit)
  )
})
