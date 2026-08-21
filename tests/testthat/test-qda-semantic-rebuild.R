make_qda_semantic_test_data <- function() {
  design <- expand.grid(
    Product = factor(c("A", "B", "C"), levels = c("A", "B", "C")),
    Panelist = factor(seq_len(12))
  )

  p <- as.character(design$Product)
  p_num <- as.numeric(design$Product)
  j <- as.numeric(design$Panelist)

  # Small deterministic product-by-panelist terms avoid a zero-residual
  # additive model while keeping the product effects very clear.
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


qda_semantic_args <- function() {
  list(
    dataset = make_qda_semantic_test_data(),
    formul = "~ Product + Panelist",
    firstvar = 3,
    lastvar = 6,
    proba = 0.05
  )
}


test_that("QDA product_profiles are canonical and complete", {
  args <- qda_semantic_args()

  x <- do.call(
    nail_qda,
    c(args, list(generate = FALSE))
  )

  profiles <- attr(x, "product_profiles", exact = TRUE)

  expect_s3_class(profiles, "nail_qda_product_profiles")
  expect_named(profiles$products, c("A", "B", "C"))
  expect_true(is.data.frame(profiles$evidence_registry))
  expect_gt(nrow(profiles$evidence_registry), 0)
  expect_identical(
    anyDuplicated(profiles$evidence_registry$evidence_id),
    0L
  )

  for (product in names(profiles$products)) {
    item <- profiles$products[[product]]

    expect_identical(
      item$adjusted_means$attribute,
      c("Sweet", "Bitter", "Creamy", "Acidic")
    )
    expect_equal(nrow(item$adjusted_means), 4)
    expect_true(is.data.frame(item$retained_markers))
    expect_true(is.data.frame(item$above_average))
    expect_true(is.data.frame(item$below_average))
    expect_false("profile_strength" %in% names(item))
  }
})


test_that("QDA product_profiles are invariant to interpretation options", {
  args <- qda_semantic_args()

  x1 <- do.call(
    nail_qda,
    c(
      args,
      list(
        generate = FALSE,
        isolate.groups = FALSE,
        drop.negative = FALSE,
        sample.pct = 1,
        sample.method = "top",
        prompt_style = "detailed",
        product_knowledge = "known"
      )
    )
  )

  x2 <- do.call(
    nail_qda,
    c(
      args,
      list(
        generate = FALSE,
        isolate.groups = TRUE,
        drop.negative = TRUE,
        sample.pct = 0.5,
        sample.method = "stratified",
        prompt_style = "compact",
        product_knowledge = "unknown"
      )
    )
  )

  expect_identical(
    attr(x1, "product_profiles", exact = TRUE),
    attr(x2, "product_profiles", exact = TRUE)
  )
})


test_that("QDA selection is deterministic and separate from product_profiles", {
  args <- qda_semantic_args()

  full <- do.call(
    nail_qda,
    c(
      args,
      list(
        generate = FALSE,
        isolate.groups = TRUE,
        sample.pct = 1,
        drop.negative = FALSE
      )
    )
  )

  reduced1 <- do.call(
    nail_qda,
    c(
      args,
      list(
        generate = FALSE,
        isolate.groups = TRUE,
        sample.pct = 0.5,
        drop.negative = TRUE
      )
    )
  )

  reduced2 <- do.call(
    nail_qda,
    c(
      args,
      list(
        generate = FALSE,
        isolate.groups = TRUE,
        sample.pct = 0.5,
        drop.negative = TRUE
      )
    )
  )

  expect_identical(
    attr(reduced1, "interpretation_evidence", exact = TRUE),
    attr(reduced2, "interpretation_evidence", exact = TRUE)
  )

  expect_identical(
    attr(full, "product_profiles", exact = TRUE),
    attr(reduced1, "product_profiles", exact = TRUE)
  )

  reduced_ev <- attr(
    reduced1,
    "interpretation_evidence",
    exact = TRUE
  )

  expect_true(all(
    reduced_ev$selected_evidence_registry$direction != "lower"
  ))
})


test_that("QDA semantic-facing evidence contains explicit directional facts", {
  args <- qda_semantic_args()

  x <- do.call(
    nail_qda,
    c(
      args,
      list(
        generate = FALSE,
        isolate.groups = TRUE,
        sample.pct = 1,
        drop.negative = FALSE
      )
    )
  )

  semantic <- attr(
    x,
    "semantic_facing_evidence",
    exact = TRUE
  )

  expect_s3_class(
    semantic,
    "nail_qda_semantic_facing_evidence"
  )

  all_text <- paste(
    unlist(
      lapply(
        semantic$products,
        function(item) item$facts$text
      )
    ),
    collapse = "\n"
  )

  expect_true(grepl("HIGHER|LOWER", all_text))
  expect_true(grepl("adjusted mean=", all_text, fixed = TRUE))
  expect_true(grepl("v.test=", all_text, fixed = TRUE))
  expect_true(grepl("p.value=", all_text, fixed = TRUE))
})


test_that("QDA prompt preserves user introduction and request", {
  args <- qda_semantic_args()

  x <- do.call(
    nail_qda,
    c(
      args,
      list(
        introduction = "USER INTRODUCTION SENTINEL",
        request = "USER REQUEST SENTINEL",
        isolate.groups = TRUE,
        generate = FALSE
      )
    )
  )

  prompt_a <- nail_prompt(
    x,
    select = "A",
    print = FALSE
  )

  expect_match(
    prompt_a,
    "USER INTRODUCTION SENTINEL",
    fixed = TRUE
  )
  expect_match(
    prompt_a,
    "USER REQUEST SENTINEL",
    fixed = TRUE
  )
})


test_that("QDA canonical llm_io stores the exact prompts", {
  args <- qda_semantic_args()

  x <- do.call(
    nail_qda,
    c(
      args,
      list(
        isolate.groups = TRUE,
        generate = FALSE
      )
    )
  )

  io <- attr(x, "llm_io", exact = TRUE)

  expect_s3_class(io, "nail_llm_io")
  expect_identical(io$stage, "interpretation")
  expect_identical(io$metadata$analysis, "nail_qda")
  expect_identical(io$metadata$scope, "product")

  expect_identical(
    nail_prompt(x, select = "A", print = FALSE),
    io$prompts$A
  )
})


test_that("QDA generated results expose raw LLM responses without reinterpretation", {
  args <- qda_semantic_args()

  testthat::local_mocked_bindings(
    .call_llm_base = function(provider,
                              model,
                              prompt,
                              output,
                              llm_api_options) {
      data.frame(
        model = model,
        response = paste0(
          "RAW MOCK RESPONSE::",
          substr(prompt, 1, 12)
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
        isolate.groups = TRUE,
        generate = TRUE,
        model = "mock-model"
      )
    )
  )

  expect_true(is.list(x))
  expect_named(x, c("A", "B", "C"))

  io <- attr(x, "llm_io", exact = TRUE)

  expect_identical(
    nail_response(x, select = "A", print = FALSE),
    io$responses$A
  )
  expect_match(
    nail_response(x, select = "A", print = FALSE),
    "RAW MOCK RESPONSE::",
    fixed = TRUE
  )
})


test_that("QDA keeps legacy compatibility artifacts for current qda_space", {
  args <- qda_semantic_args()

  x <- do.call(
    nail_qda,
    c(args, list(generate = FALSE))
  )

  expect_true(is.list(attr(x, "profile_summary", exact = TRUE)))
  expect_true(is.list(attr(x, "decat_result", exact = TRUE)))
  expect_true(is.list(attr(x, "qda_settings", exact = TRUE)))

  product_profiles <- attr(x, "product_profiles", exact = TRUE)

  expect_false(
    "profile_strength" %in%
      names(product_profiles$products$A)
  )
})


test_that("QDA stratified sampling is deterministic and differs from top sampling", {
  markers <- data.frame(
    evidence_id = sprintf("E%02d", 1:8),
    product = "A",
    attribute = paste0("Attr", 1:8),
    direction = c(
      "higher", "higher", "higher", "higher",
      "higher", "lower", "lower", "lower"
    ),
    coefficient = seq(0.8, 0.1, length.out = 8),
    adjusted_mean = seq(8, 1),
    p_value = c(0.001, 0.002, 0.003, 0.004, 0.005, 0.02, 0.03, 0.04),
    v_test = c(7, 6, 5, 4, 3, -2.8, -2.5, -2.2),
    rank = 1:8,
    stringsAsFactors = FALSE
  )

  s1 <- NaileR:::.select_qda_markers(
    markers,
    sample_pct = 0.5,
    drop_negative = FALSE,
    sample_method = "stratified"
  )

  s2 <- NaileR:::.select_qda_markers(
    markers,
    sample_pct = 0.5,
    drop_negative = FALSE,
    sample_method = "stratified"
  )

  top <- NaileR:::.select_qda_markers(
    markers,
    sample_pct = 0.5,
    drop_negative = FALSE,
    sample_method = "top"
  )

  expect_identical(s1, s2)
  expect_equal(nrow(s1), 4)
  expect_equal(nrow(top), 4)
  expect_false(identical(s1$evidence_id, top$evidence_id))
})


test_that("QDA stratified sampling protects the statistical backbone", {
  markers <- data.frame(
    evidence_id = sprintf("E%02d", 1:10),
    product = "A",
    attribute = paste0("Attr", 1:10),
    direction = c("higher", "lower", rep("higher", 8)),
    coefficient = seq(1, 0.1, length.out = 10),
    adjusted_mean = seq(10, 1),
    p_value = seq(0.001, 0.010, length.out = 10),
    v_test = c(10, -9, 8:1),
    rank = 1:10,
    stringsAsFactors = FALSE
  )

  selected <- NaileR:::.select_qda_markers(
    markers,
    sample_pct = 0.5,
    drop_negative = FALSE,
    sample_method = "stratified"
  )

  # Five retained slots -> three anchors + two exploratory markers.
  expect_true(all(c("E01", "E02", "E03") %in% selected$evidence_id))
  expect_equal(nrow(selected), 5)
  expect_false("E10" %in% selected$evidence_id)
})


test_that("QDA stratified sampling prioritizes an opposite-direction nuance", {
  markers <- data.frame(
    evidence_id = sprintf("E%02d", 1:10),
    product = "A",
    attribute = paste0("Attr", 1:10),
    direction = c(rep("higher", 8), rep("lower", 2)),
    coefficient = c(rep(1, 8), rep(-1, 2)),
    adjusted_mean = seq(10, 1),
    p_value = seq(0.001, 0.010, length.out = 10),
    v_test = c(10:3, -2.5, -2.0),
    rank = 1:10,
    stringsAsFactors = FALSE
  )

  selected <- NaileR:::.select_qda_markers(
    markers,
    sample_pct = 0.3,
    drop_negative = FALSE,
    sample_method = "stratified"
  )

  # Three slots -> two strong anchors + strongest opposite-direction nuance.
  expect_identical(selected$evidence_id, c("E01", "E02", "E09"))
  expect_true("higher" %in% selected$direction)
  expect_true("lower" %in% selected$direction)
})


test_that("QDA stratified sampling matches top sampling with only two slots", {
  markers <- data.frame(
    evidence_id = sprintf("E%02d", 1:6),
    product = "A",
    attribute = paste0("Attr", 1:6),
    direction = c("higher", "lower", "higher", "lower", "higher", "lower"),
    coefficient = c(1, -1, 1, -1, 1, -1),
    adjusted_mean = 1:6,
    p_value = c(0.001, 0.002, 0.003, 0.004, 0.005, 0.006),
    v_test = c(6, -5, 4, -3, 2.5, -2.2),
    rank = 1:6,
    stringsAsFactors = FALSE
  )

  stratified <- NaileR:::.select_qda_markers(
    markers,
    sample_pct = 0.3,
    drop_negative = FALSE,
    sample_method = "stratified"
  )

  top <- NaileR:::.select_qda_markers(
    markers,
    sample_pct = 0.3,
    drop_negative = FALSE,
    sample_method = "top"
  )

  expect_identical(stratified$evidence_id, top$evidence_id)
  expect_identical(stratified$evidence_id, c("E01", "E02"))
})


test_that("QDA top sampling keeps the statistically strongest eligible markers", {
  markers <- data.frame(
    evidence_id = sprintf("E%02d", 1:6),
    product = "A",
    attribute = paste0("Attr", 1:6),
    direction = c("higher", "lower", "higher", "lower", "higher", "lower"),
    coefficient = c(1, -1, 1, -1, 1, -1),
    adjusted_mean = 1:6,
    p_value = c(0.030, 0.001, 0.020, 0.004, 0.002, 0.010),
    v_test = c(2.2, -6.0, 2.5, -4.5, 5.0, -3.0),
    rank = 1:6,
    stringsAsFactors = FALSE
  )

  selected <- NaileR:::.select_qda_markers(
    markers,
    sample_pct = 0.5,
    drop_negative = FALSE,
    sample_method = "top"
  )

  expect_identical(
    selected$evidence_id,
    c("E02", "E05", "E04")
  )
})


test_that("QDA product_profiles are invariant to sample.method", {
  args <- qda_semantic_args()

  stratified <- do.call(
    nail_qda,
    c(
      args,
      list(
        generate = FALSE,
        isolate.groups = TRUE,
        sample.pct = 0.5,
        sample.method = "stratified"
      )
    )
  )

  top <- do.call(
    nail_qda,
    c(
      args,
      list(
        generate = FALSE,
        isolate.groups = TRUE,
        sample.pct = 0.5,
        sample.method = "top"
      )
    )
  )

  expect_identical(
    attr(stratified, "product_profiles", exact = TRUE),
    attr(top, "product_profiles", exact = TRUE)
  )

  expect_identical(
    attr(stratified, "qda_settings", exact = TRUE)$sample_method,
    "stratified"
  )

  expect_identical(
    attr(top, "qda_settings", exact = TRUE)$sample_method,
    "top"
  )
})
