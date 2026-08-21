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

  space <- nail_qda_space(
    qda,
    ncp = 1,
    min_inertia_pct = 0,
    generate = TRUE,
    model = "mock-model"
  )

  # nail_condes() is always generate = FALSE internally,
  # so only the final axis interpretation calls the backend.
  expect_identical(
    call_count,
    1L
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
