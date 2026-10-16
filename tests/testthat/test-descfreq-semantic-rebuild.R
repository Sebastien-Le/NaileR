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
  expect_match(
    prompt,
    "higher-level substantive characterization",
    fixed = TRUE
  )
  expect_match(
    prompt,
    "Build the main interpretation and any descriptive name primarily from the strongest coherent pattern.",
    fixed = TRUE
  )
  expect_match(
    prompt,
    "Rare or sparsely represented attributes may provide secondary contextual nuance, but they should not drive the descriptive name unless supported by several convergent signals.",
    fixed = TRUE
  )
  expect_match(
    prompt,
    "not as an additional directly observed frequency",
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


test_that("descfreq renders the approved modular prompt blocks", {
  tab <- data.frame(
    sweet = c(30, 5, 10),
    bitter = c(5, 30, 10),
    neutral = c(10, 10, 30),
    row.names = c("A", "B", "C")
  )

  local <- nail_descfreq(
    tab,
    isolate.groups = TRUE,
    generate = FALSE
  )
  local_prompt <- nail_prompt(
    local,
    select = "A",
    print = FALSE
  )

  headings <- c(
    "# Introduction",
    "## How to Read the Statistical Evidence",
    "# Analytical Request",
    "## Interpretation Rules",
    "## Row Identity — not specified",
    "## Task — local",
    "# Data",
    "# Final Interpretation Requirements"
  )
  heading_positions <- vapply(
    headings,
    function(heading) regexpr(heading, local_prompt, fixed = TRUE)[[1]],
    integer(1)
  )

  expect_true(all(diff(heading_positions) > 0))
  expect_match(
    local_prompt,
    "The results come from `FactoMineR::descfreq()` and describe rows of a contingency table through their frequency profiles across columns.",
    fixed = TRUE
  )
  expect_match(
    local_prompt,
    "When several frequency patterns converge, you may synthesize them into a higher-level substantive characterization",
    fixed = TRUE
  )
  expect_match(
    local_prompt,
    "Rare or sparsely represented attributes may provide secondary contextual nuance",
    fixed = TRUE
  )
  expect_false(
    grepl("formatted using valid Quarto Markdown", local_prompt, fixed = TRUE)
  )

  description <- nail_descfreq(
    tab,
    isolate.groups = FALSE,
    interpretation_mode = "description",
    generate = FALSE
  )
  comparison <- nail_descfreq(
    tab,
    isolate.groups = FALSE,
    interpretation_mode = "comparison",
    rows_are_ordered = TRUE,
    generate = FALSE
  )

  expect_match(
    nail_prompt(description, print = FALSE),
    "## Task — description",
    fixed = TRUE
  )
  expect_match(
    nail_prompt(comparison, print = FALSE),
    "## Task — comparison",
    fixed = TRUE
  )
  expect_match(
    nail_prompt(comparison, print = FALSE),
    "The rows have an external order supplied by the analyst.",
    fixed = TRUE
  )

  standard <- nail_descfreq(
    tab,
    isolate.groups = FALSE,
    explicit_row_labels = TRUE,
    generate = FALSE
  )
  standard_prompt <- nail_prompt(standard, print = FALSE)
  expect_match(standard_prompt, "## Row Identity — standard", fixed = TRUE)
  expect_false(grepl("## Row Identity — latent", standard_prompt, fixed = TRUE))
})


test_that("descfreq preserves custom prompt blocks and canonical evidence", {
  tab <- data.frame(
    sweet = c(30, 5, 10),
    bitter = c(5, 30, 10),
    neutral = c(10, 10, 30),
    row.names = c("A", "B", "C")
  )

  baseline <- nail_descfreq(
    tab,
    isolate.groups = FALSE,
    generate = FALSE
  )
  customized <- nail_descfreq(
    tab,
    introduction = "Study context supplied by the analyst.",
    request = "Answer the analyst's frequency-profile question.",
    conclusion = "Return a concise, traceable interpretation.",
    isolate.groups = FALSE,
    generate = FALSE
  )

  customized_prompt <- nail_prompt(customized, print = FALSE)
  expect_match(
    customized_prompt,
    "Study context supplied by the analyst.",
    fixed = TRUE
  )
  expect_match(
    customized_prompt,
    "Answer the analyst's frequency-profile question.",
    fixed = TRUE
  )
  expect_match(
    customized_prompt,
    "# Final Interpretation Requirements\n\nReturn a concise, traceable interpretation.",
    fixed = TRUE
  )
  expect_identical(
    attr(baseline, "frequency_profiles", exact = TRUE),
    attr(customized, "frequency_profiles", exact = TRUE)
  )
  expect_identical(
    nail_evidence(baseline),
    nail_evidence(customized)
  )
})


test_that("descfreq supports the six identity and task combinations", {
  tab <- data.frame(
    sweet = c(30, 5, 10),
    bitter = c(5, 30, 10),
    neutral = c(10, 10, 30),
    row.names = c("A", "B", "C")
  )

  standard_local <- nail_descfreq(
    tab,
    isolate.groups = TRUE,
    explicit_row_labels = TRUE,
    row_identity_mode = "standard",
    generate = FALSE
  )
  standard_description <- nail_descfreq(
    tab,
    isolate.groups = FALSE,
    explicit_row_labels = TRUE,
    row_identity_mode = "standard",
    interpretation_mode = "description",
    generate = FALSE
  )
  standard_comparison <- nail_descfreq(
    tab,
    isolate.groups = FALSE,
    explicit_row_labels = TRUE,
    row_identity_mode = "standard",
    interpretation_mode = "comparison",
    generate = FALSE
  )
  latent_local <- nail_descfreq(
    tab,
    isolate.groups = TRUE,
    explicit_row_labels = FALSE,
    row_identity_mode = "latent",
    generate = FALSE
  )
  latent_description <- nail_descfreq(
    tab,
    isolate.groups = FALSE,
    row_identity_mode = "latent",
    interpretation_mode = "description",
    generate = FALSE
  )
  latent_comparison <- nail_descfreq(
    tab,
    isolate.groups = FALSE,
    row_identity_mode = "latent",
    interpretation_mode = "comparison",
    generate = FALSE
  )

  expect_match(
    nail_prompt(standard_local, select = "A", print = FALSE),
    "## Row Identity — standard",
    fixed = TRUE
  )
  expect_match(
    nail_prompt(standard_local, select = "A", print = FALSE),
    "## Task — local",
    fixed = TRUE
  )
  expect_match(
    nail_prompt(standard_description, print = FALSE),
    "## Task — description",
    fixed = TRUE
  )
  expect_match(
    nail_prompt(standard_comparison, print = FALSE),
    "## Task — comparison",
    fixed = TRUE
  )
  expect_match(
    nail_prompt(latent_local, select = "A", print = FALSE),
    "## Row Identity — latent",
    fixed = TRUE
  )
  expect_match(
    nail_prompt(latent_description, print = FALSE),
    "## Task — description",
    fixed = TRUE
  )
  expect_match(
    nail_prompt(latent_comparison, print = FALSE),
    "## Task — comparison",
    fixed = TRUE
  )
  expect_match(
    nail_prompt(latent_local, select = "A", print = FALSE),
    "Keep the original identifier alongside the proposed name.",
    fixed = TRUE
  )
  expect_match(
    nail_prompt(latent_local, select = "A", print = FALSE),
    "## Row 'A'",
    fixed = TRUE
  )
  expect_false(
    grepl(
      "## Row Identity — standard",
      nail_prompt(latent_local, select = "A", print = FALSE),
      fixed = TRUE
    )
  )
})


test_that("descfreq preserves positional generate and named row identity mode", {
  tab <- data.frame(
    sweet = c(40, 5),
    bitter = c(5, 40),
    row.names = c("A", "B")
  )

  testthat::local_mocked_bindings(
    .call_llm_base = function(provider,
                              model,
                              prompt,
                              output,
                              llm_api_options) {
      "Mock positional generation"
    },
    .package = "NaileR"
  )

  positional_generated <- nail_descfreq(
    tab,
    NULL,
    NULL,
    NULL,
    "llama3",
    "ollama",
    FALSE,
    1,
    FALSE,
    NULL,
    0.05,
    "description",
    FALSE,
    FALSE,
    TRUE
  )

  expect_true(
    attr(positional_generated, "descfreq_settings", exact = TRUE)$generate
  )
  expect_match(
    nail_response(positional_generated, print = FALSE),
    "Mock positional generation",
    fixed = TRUE
  )

  named_latent <- nail_descfreq(
    tab,
    row_identity_mode = "latent",
    generate = FALSE
  )

  expect_match(
    nail_prompt(named_latent, print = FALSE),
    "## Row Identity — latent",
    fixed = TRUE
  )
})


test_that("auto identity mode preserves historical prompt behavior", {
  tab <- data.frame(
    sweet = c(30, 5, 10),
    bitter = c(5, 30, 10),
    neutral = c(10, 10, 30),
    row.names = c("A", "B", "C")
  )

  legacy <- nail_descfreq(
    tab,
    isolate.groups = FALSE,
    generate = FALSE
  )
  explicit_auto <- nail_descfreq(
    tab,
    isolate.groups = FALSE,
    row_identity_mode = "auto",
    generate = FALSE
  )
  explicit_standard <- nail_descfreq(
    tab,
    isolate.groups = FALSE,
    explicit_row_labels = TRUE,
    row_identity_mode = "auto",
    generate = FALSE
  )
  explicit_standard_mode <- nail_descfreq(
    tab,
    isolate.groups = FALSE,
    explicit_row_labels = TRUE,
    row_identity_mode = "standard",
    generate = FALSE
  )

  expect_identical(
    nail_prompt(legacy, print = FALSE),
    nail_prompt(explicit_auto, print = FALSE)
  )
  expect_identical(
    nail_prompt(explicit_standard, print = FALSE),
    nail_prompt(explicit_standard_mode, print = FALSE)
  )
  expect_error(
    nail_descfreq(
      tab,
      row_identity_mode = "unknown",
      generate = FALSE
    ),
    "one of",
    fixed = TRUE
  )
})


test_that("rows without selected evidence remain identifiable without false claims", {
  tab <- data.frame(
    sweet = c(30, 5, 10),
    bitter = c(5, 30, 10),
    neutral = c(10, 10, 30),
    row.names = c("A", "B", "C")
  )

  no_selected <- nail_descfreq(
    tab,
    isolate.groups = FALSE,
    sample.pct = 0,
    generate = FALSE
  )
  prompt <- nail_prompt(no_selected, print = FALSE)

  expect_true(all(vapply(
    rownames(tab),
    function(row_name) grepl(paste0("## Row '", row_name, "'"), prompt, fixed = TRUE),
    logical(1)
  )))
  expect_match(
    prompt,
    "No selected statistical evidence is available for this row in the facts supplied to the prompt.",
    fixed = TRUE
  )
  expect_match(
    prompt,
    "This does not establish the absence of a statistical difference or demonstrate similarity to the global profile.",
    fixed = TRUE
  )
  expect_match(
    prompt,
    "not through direct pairwise tests between rows",
    fixed = TRUE
  )

  ordinary <- nail_descfreq(
    tab,
    isolate.groups = FALSE,
    generate = FALSE
  )
  expect_false(
    grepl(
      "No selected statistical evidence is available",
      nail_prompt(ordinary, print = FALSE),
      fixed = TRUE
    )
  )
})


test_that("latent explicit labels are preserved without proposing a replacement", {
  tab <- data.frame(
    sweet = c(40, 5),
    bitter = c(5, 40),
    row.names = c("Sweet-preferring group", "Bitter-preferring group")
  )

  labeled_local <- nail_descfreq(
    tab,
    row_identity_mode = "latent",
    explicit_row_labels = TRUE,
    isolate.groups = TRUE,
    generate = FALSE
  )
  unlabeled_local <- nail_descfreq(
    tab,
    row_identity_mode = "latent",
    explicit_row_labels = FALSE,
    isolate.groups = TRUE,
    generate = FALSE
  )
  labeled_global <- nail_descfreq(
    tab,
    row_identity_mode = "latent",
    explicit_row_labels = TRUE,
    isolate.groups = FALSE,
    interpretation_mode = "comparison",
    generate = FALSE
  )

  local_prompt <- nail_prompt(
    labeled_local,
    select = "Sweet-preferring group",
    print = FALSE
  )
  global_prompt <- nail_prompt(labeled_global, print = FALSE)
  unlabeled_prompt <- nail_prompt(
    unlabeled_local,
    select = "Sweet-preferring group",
    print = FALSE
  )

  for (prompt in list(local_prompt, global_prompt)) {
    expect_match(prompt, "## Row Identity — latent", fixed = TRUE)
    expect_match(
      prompt,
      "Preserve the supplied row identifier and label exactly.",
      fixed = TRUE
    )
    expect_match(
      prompt,
      "Do not rename the group or propose an alternative name.",
      fixed = TRUE
    )
    expect_match(
      prompt,
      "complement the supplied label with an evidence-grounded characterization",
      fixed = TRUE
    )
    expect_false(grepl("propose a concise, meaningful name", prompt, fixed = TRUE))
  }

  expect_match(
    local_prompt,
    "## Row 'Sweet-preferring group'",
    fixed = TRUE
  )
  expect_match(
    global_prompt,
    "## Row 'Bitter-preferring group'",
    fixed = TRUE
  )
  expect_match(
    unlabeled_prompt,
    "propose a concise, meaningful name",
    fixed = TRUE
  )

  expect_identical(
    attr(labeled_local, "frequency_profiles", exact = TRUE),
    attr(unlabeled_local, "frequency_profiles", exact = TRUE)
  )
  expect_identical(
    nail_evidence(labeled_local),
    nail_evidence(unlabeled_local)
  )
})
