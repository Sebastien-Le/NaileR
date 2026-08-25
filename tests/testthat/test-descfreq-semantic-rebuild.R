test_that("nail_descfreq builds canonical frequency profiles", {
  tab <- data.frame(
    sweet = c(30, 5, 10),
    bitter = c(5, 30, 10),
    neutral = c(10, 10, 30),
    row.names = c("A", "B", "C")
  )

  x <- nail_descfreq(
    tab,
    isolate.groups = TRUE,
    generate = FALSE
  )

  evidence <- attr(
    x,
    "frequency_profiles",
    exact = TRUE
  )

  expect_s3_class(
    evidence,
    "nail_descfreq_frequency_profiles"
  )
  expect_identical(
    rownames(evidence$contingency_table),
    c("A", "B", "C")
  )
  expect_identical(
    colnames(evidence$contingency_table),
    c("sweet", "bitter", "neutral")
  )
  expect_identical(
    names(evidence$rows),
    c("A", "B", "C")
  )
  expect_true(
    is.data.frame(evidence$evidence_registry)
  )
  expect_true(
    all(c(
      "evidence_id",
      "row",
      "attribute",
      "direction",
      "row_percentage",
      "global_percentage",
      "p_value",
      "v_test",
      "rank"
    ) %in% names(evidence$evidence_registry))
  )
})


test_that("frequency profiles are invariant to interpretation-only options", {
  tab <- data.frame(
    sweet = c(30, 5, 10),
    bitter = c(5, 30, 10),
    neutral = c(10, 10, 30),
    row.names = c("A", "B", "C")
  )

  a <- nail_descfreq(
    tab,
    sample.pct = 1,
    drop.negative = FALSE,
    isolate.groups = FALSE,
    interpretation_mode = "description",
    rows_are_ordered = FALSE,
    explicit_row_labels = FALSE,
    generate = FALSE
  )

  b <- nail_descfreq(
    tab,
    sample.pct = 0.5,
    drop.negative = TRUE,
    isolate.groups = TRUE,
    interpretation_mode = "comparison",
    rows_are_ordered = TRUE,
    explicit_row_labels = TRUE,
    introduction = "Different context",
    request = "Different request",
    conclusion = "Different conclusion",
    generate = FALSE
  )

  expect_identical(
    attr(a, "frequency_profiles", exact = TRUE),
    attr(b, "frequency_profiles", exact = TRUE)
  )

  expect_false(
    identical(
      attr(a, "interpretation_evidence", exact = TRUE),
      attr(b, "interpretation_evidence", exact = TRUE)
    )
  )
})


test_that("descfreq evidence retains complete row profiles and statistical markers", {
  tab <- data.frame(
    sweet = c(30, 5, 10),
    bitter = c(5, 30, 10),
    neutral = c(10, 10, 30),
    row.names = c("A", "B", "C")
  )

  x <- nail_descfreq(
    tab,
    isolate.groups = TRUE,
    generate = FALSE
  )

  row_a <- attr(
    x,
    "frequency_profiles",
    exact = TRUE
  )$rows$A

  expect_equal(
    nrow(row_a$column_profile),
    ncol(tab)
  )
  expect_equal(
    sum(row_a$column_profile$row_percentage),
    100,
    tolerance = 1e-8
  )
  expect_equal(
    row_a$row_total,
    sum(tab["A", ])
  )
  expect_true(
    all(row_a$retained_markers$direction %in%
          c("overrepresented", "underrepresented", "neutral"))
  )
  expect_identical(
    row_a$overrepresented,
    row_a$retained_markers[
      row_a$retained_markers$direction == "overrepresented",
      ,
      drop = FALSE
    ]
  )
})


test_that("descfreq prompt selection is deterministic and preserves canonical evidence", {
  tab <- data.frame(
    a = c(50, 5, 10),
    b = c(5, 50, 10),
    c = c(20, 5, 30),
    d = c(5, 20, 30),
    row.names = c("R1", "R2", "R3")
  )

  x1 <- nail_descfreq(
    tab,
    sample.pct = 0.5,
    drop.negative = FALSE,
    isolate.groups = TRUE,
    generate = FALSE
  )

  x2 <- nail_descfreq(
    tab,
    sample.pct = 0.5,
    drop.negative = FALSE,
    isolate.groups = TRUE,
    generate = FALSE
  )

  expect_identical(
    attr(x1, "interpretation_evidence", exact = TRUE),
    attr(x2, "interpretation_evidence", exact = TRUE)
  )
  expect_identical(
    nail_prompt(x1, print = FALSE),
    nail_prompt(x2, print = FALSE)
  )
})


test_that("drop.negative affects prompt evidence only", {
  tab <- data.frame(
    sweet = c(40, 5),
    bitter = c(5, 40),
    row.names = c("A", "B")
  )

  full <- nail_descfreq(
    tab,
    drop.negative = FALSE,
    isolate.groups = TRUE,
    generate = FALSE
  )

  positive_only <- nail_descfreq(
    tab,
    drop.negative = TRUE,
    isolate.groups = TRUE,
    generate = FALSE
  )

  expect_identical(
    attr(full, "frequency_profiles", exact = TRUE),
    attr(positive_only, "frequency_profiles", exact = TRUE)
  )

  selected <- attr(
    positive_only,
    "interpretation_evidence",
    exact = TRUE
  )

  selected_markers <- do.call(
    rbind,
    lapply(
      selected$rows,
      function(row) row$selected_markers
    )
  )

  if (nrow(selected_markers) > 0L) {
    expect_false(
      any(selected_markers$direction == "underrepresented")
    )
  }
})


test_that("semantic-facing DESCFREQ evidence does not expose p-values or v-tests", {
  tab <- data.frame(
    sweet = c(40, 5),
    bitter = c(5, 40),
    row.names = c("A", "B")
  )

  x <- nail_descfreq(
    tab,
    isolate.groups = TRUE,
    generate = FALSE
  )

  prompt <- nail_prompt(
    x,
    select = "A",
    print = FALSE
  )

  expect_false(
    grepl("p.value", prompt, fixed = TRUE)
  )
  expect_false(
    grepl("v.test", prompt, fixed = TRUE)
  )
  expect_false(
    grepl("DESCF::", prompt, fixed = TRUE)
  )
  expect_match(
    prompt,
    "relative frequency",
    fixed = TRUE
  )
})


test_that("by.quali aggregation is represented in canonical evidence", {
  tab <- data.frame(
    x = c(20, 10, 2, 1),
    y = c(2, 1, 20, 10),
    row.names = c("r1", "r2", "r3", "r4")
  )

  group <- factor(
    c("G1", "G1", "G2", "G2"),
    levels = c("G1", "G2")
  )

  x <- nail_descfreq(
    tab,
    by.quali = group,
    isolate.groups = TRUE,
    generate = FALSE
  )

  evidence <- attr(
    x,
    "frequency_profiles",
    exact = TRUE
  )

  expect_true(
    evidence$aggregation$performed
  )
  expect_identical(
    rownames(evidence$contingency_table),
    c("G1", "G2")
  )
  expect_equal(
    unname(as.numeric(evidence$contingency_table["G1", ])),
    c(30, 3)
  )
  expect_equal(
    unname(as.numeric(evidence$contingency_table["G2", ])),
    c(3, 30)
  )
  expect_identical(
    evidence$aggregation$source_to_analyzed_row$analyzed_row,
    as.character(group)
  )
})


test_that("nail_descfreq stores canonical llm_io for preview objects", {
  tab <- data.frame(
    sweet = c(40, 5),
    bitter = c(5, 40),
    row.names = c("A", "B")
  )

  x <- nail_descfreq(
    tab,
    isolate.groups = TRUE,
    generate = FALSE
  )

  io <- attr(
    x,
    "llm_io",
    exact = TRUE
  )

  expect_s3_class(
    io,
    "nail_llm_io"
  )
  expect_identical(
    io$metadata$analysis,
    "nail_descfreq"
  )
  expect_identical(
    names(io$prompts),
    c("A", "B")
  )
  expect_null(
    io$responses
  )
  expect_identical(
    nail_prompt(
      x,
      select = "A",
      print = FALSE
    ),
    io$prompts$A
  )
})


test_that("nail_descfreq generation stores raw responses without changing evidence", {
  tab <- data.frame(
    sweet = c(40, 5),
    bitter = c(5, 40),
    row.names = c("A", "B")
  )

  preview <- nail_descfreq(
    tab,
    isolate.groups = TRUE,
    generate = FALSE
  )

  testthat::local_mocked_bindings(
    .call_llm_base = function(provider,
                              model,
                              prompt,
                              output,
                              llm_api_options) {
      paste0("Mock interpretation for ", substr(prompt, 1, 12))
    },
    .package = "NaileR"
  )

  generated <- nail_descfreq(
    tab,
    isolate.groups = TRUE,
    generate = TRUE,
    provider = "ollama",
    model = "mock-model"
  )

  expect_identical(
    attr(preview, "frequency_profiles", exact = TRUE),
    attr(generated, "frequency_profiles", exact = TRUE)
  )

  response_a <- nail_response(
    generated,
    select = "A",
    print = FALSE
  )

  expect_match(
    response_a,
    "Mock interpretation",
    fixed = TRUE
  )
})


test_that("nail_descfreq validates contingency counts", {
  bad_negative <- data.frame(
    a = c(10, -1),
    b = c(5, 6)
  )

  expect_error(
    nail_descfreq(
      bad_negative,
      generate = FALSE
    ),
    "negative frequencies",
    fixed = TRUE
  )

  bad_fractional <- data.frame(
    a = c(10.5, 2),
    b = c(5, 6)
  )

  expect_error(
    nail_descfreq(
      bad_fractional,
      generate = FALSE
    ),
    "integer-like frequencies",
    fixed = TRUE
  )

  bad_zero_column <- data.frame(
    a = c(10, 2),
    b = c(0, 0)
  )

  expect_error(
    nail_descfreq(
      bad_zero_column,
      generate = FALSE
    ),
    "strictly positive total",
    fixed = TRUE
  )
})
