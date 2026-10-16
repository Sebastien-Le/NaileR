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


test_that("QDA prompts allow traceable higher-level sensory concepts", {
  x <- do.call(
    nail_qda,
    c(
      qda_semantic_args(),
      list(
        isolate.groups = TRUE,
        generate = FALSE
      )
    )
  )

  prompt <- nail_prompt(x, select = "A", print = FALSE)

  expect_match(
    prompt,
    "develop a higher-level interpretation that captures their combined meaning",
    fixed = TRUE
  )
  expect_match(
    prompt,
    "connect conceptually related characteristics across the relevant perceptual dimensions",
    fixed = TRUE
  )
  expect_match(
    prompt,
    "do not present conceptual connections as statistically demonstrated relationships",
    fixed = TRUE
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
  expect_true(grepl("than for the average product", all_text, fixed = TRUE))
  expect_false(
    grepl("average sensory profile for this item", all_text, fixed = TRUE)
  )
})


test_that("QDA reading defines the average product and statistical meanings", {
  x <- do.call(
    nail_qda,
    c(
      qda_semantic_args(),
      list(
        isolate.groups = TRUE,
        generate = FALSE
      )
    )
  )

  reading <- attr(x, "qda_prompt_blocks", exact = TRUE)$A$reading

  expected_reading <- paste(
    "The results come from `SensoMineR::decat()` and characterize evaluated products or stimuli through their sensory attributes, relative to the average sensory profile of the evaluated set. This average product is a statistical reference, not an actual evaluated product.",
    "",
    "For a given attribute, HIGHER means that the product's adjusted sensory score is statistically higher than the reference; LOWER means it is statistically lower. These directions are relative: LOWER does not mean that the attribute is absent or that its opposite is present.",
    "",
    "The adjusted mean is the model-adjusted sensory score for the product and attribute, not its difference from the reference. The `v.test` is a signed standardized statistic, while the `p.value` describes statistical evidence. Neither measures sensory intensity or substantive importance. Do not compare adjusted means across different attributes as if they measured the same sensory characteristic.",
    "",
    "Preserve the meaning of each sensory attribute. Use the study context to understand the sensory characteristics, without treating it as additional statistical evidence. Do not infer liking, preference, quality, manufacturing causes, or statistically demonstrated differences between pairs of products from these results.",
    sep = "\n"
  )

  expect_identical(reading, expected_reading)
  expect_false(grepl("eligible retained markers", reading, fixed = TRUE))
  expect_false(grepl("undisplayed attribute", reading, fixed = TRUE))
})


test_that("QDA local and global prompts preserve scope and user request", {
  args <- qda_semantic_args()
  custom_request <- "Describe the products jointly and compare their sensory patterns."

  local <- do.call(
    nail_qda,
    c(
      args,
      list(
        request = custom_request,
        isolate.groups = TRUE,
        generate = FALSE
      )
    )
  )
  global <- do.call(
    nail_qda,
    c(
      args,
      list(
        request = custom_request,
        isolate.groups = FALSE,
        generate = FALSE
      )
    )
  )

  local_prompt <- nail_prompt(local, select = "A", print = FALSE)
  global_prompt <- nail_prompt(global, print = FALSE)

  expect_match(local_prompt, custom_request, fixed = TRUE)
  expect_match(
    local_prompt,
    "Interpret only the product or stimulus \"A\" using its displayed statistical evidence and the user's analytical request.",
    fixed = TRUE
  )
  expect_match(
    local_prompt,
    "Characterize its distinctive sensory profile relative to the average product.",
    fixed = TRUE
  )
  expect_match(
    local_prompt,
    "Do not describe or compare other products or stimuli.",
    fixed = TRUE
  )
  expect_match(global_prompt, custom_request, fixed = TRUE)
  expect_match(
    global_prompt,
    "Interpret the displayed products or stimuli jointly, using their statistical evidence and the user's analytical request.",
    fixed = TRUE
  )
  expect_match(
    global_prompt,
    "Ground comparisons in the displayed sensory profiles, interpreted relative to the average product.",
    fixed = TRUE
  )
  expect_false(grepl("This prompt addresses only product", global_prompt, fixed = TRUE))
  expect_true(grepl("# Global Task", global_prompt, fixed = TRUE))
  expect_false(grepl("# Local Task", global_prompt, fixed = TRUE))
})


test_that("QDA approved identity and task blocks cover known and unknown scopes", {
  args <- qda_semantic_args()
  cases <- list(
    known_local = list(
      product_knowledge = "known",
      isolate.groups = TRUE,
      expected_identity = "## Identity — known",
      expected_task = "# Local Task"
    ),
    known_global = list(
      product_knowledge = "known",
      isolate.groups = FALSE,
      expected_identity = "## Identity — known",
      expected_task = "# Global Task"
    ),
    unknown_local = list(
      product_knowledge = "unknown",
      isolate.groups = TRUE,
      expected_identity = "## Identity — unknown",
      expected_task = "# Local Task"
    ),
    unknown_global = list(
      product_knowledge = "unknown",
      isolate.groups = FALSE,
      expected_identity = "## Identity — unknown",
      expected_task = "# Global Task"
    )
  )

  for (case in cases) {
    x <- do.call(
      nail_qda,
      c(
        args,
        case[c("product_knowledge", "isolate.groups")],
        list(generate = FALSE)
      )
    )

    prompt <- if (isTRUE(case$isolate.groups)) {
      nail_prompt(x, select = "A", print = FALSE)
    } else {
      nail_prompt(x, print = FALSE)
    }

    expect_match(prompt, case$expected_identity, fixed = TRUE)
    expect_match(prompt, case$expected_task, fixed = TRUE)
    expect_match(
      prompt,
      "This average product is a statistical reference, not an actual evaluated product.",
      fixed = TRUE
    )
    expect_match(
      prompt,
      "Write a clear, well-structured and substantive interpretation of the evaluated sensory profiles.",
      fixed = TRUE
    )
  }

  compact <- do.call(
    nail_qda,
    c(
      args,
      list(
        isolate.groups = TRUE,
        product_knowledge = "unknown",
        prompt_style = "compact",
        generate = FALSE
      )
    )
  )
  compact_prompt <- nail_prompt(compact, select = "A", print = FALSE)
  expect_match(
    compact_prompt,
    "The adjusted mean is the model-adjusted sensory score for the product and attribute",
    fixed = TRUE
  )
  expect_false(
    grepl("eligible retained markers", compact_prompt, fixed = TRUE)
  )
})


test_that("QDA reading stays approved when selection settings change", {
  x <- do.call(
    nail_qda,
    c(
      qda_semantic_args(),
      list(
        isolate.groups = TRUE,
        sample.pct = 0.5,
        sample.method = "top",
        drop.negative = TRUE,
        generate = FALSE
      )
    )
  )

  reading <- attr(x, "qda_prompt_blocks", exact = TRUE)$A$reading
  expect_false(grepl("50% of the eligible retained markers", reading, fixed = TRUE))
  expect_false(grepl("statistically strongest eligible markers", reading, fixed = TRUE))
  expect_false(grepl("intentionally excluded", reading, fixed = TRUE))
  expect_false(grepl("undisplayed attribute", reading, fixed = TRUE))
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


test_that("QDA stores ordered modular prompt blocks and renders their order", {
  x <- do.call(
    nail_qda,
    c(
      qda_semantic_args(),
      list(
        isolate.groups = TRUE,
        generate = FALSE
      )
    )
  )

  blocks <- attr(x, "qda_prompt_blocks", exact = TRUE)
  expect_named(blocks, c("A", "B", "C"))
  expect_named(
    blocks$A,
    c(
      "context",
      "reading",
      "question",
      "interpretation",
      "identity",
      "local_task",
      "evidence",
      "reusable",
      "output"
    )
  )
  expect_true(all(vapply(blocks$A, is.character, logical(1))))

  prompt <- nail_prompt(x, select = "A", print = FALSE)
  headings <- c(
    "# Introduction",
    "## How to Read the Statistical Evidence",
    "# Analytical Request",
    "## Interpretation Rules",
    "## Identity — known",
    "# Local Task",
    "# Data",
    "## Reusable NaileR Metadata",
    "# Final Interpretation Requirements"
  )
  positions <- vapply(
    headings,
    function(heading) regexpr(heading, prompt, fixed = TRUE)[[1L]],
    integer(1)
  )
  expect_true(all(positions > 0L))
  expect_true(all(diff(positions) > 0L))
  expect_true(
    positions[[9L]] >
      regexpr("END_NAILER_PRODUCT_INTERPRETATION", prompt, fixed = TRUE)[[1L]]
  )
})


test_that("QDA custom conclusions are explicit final requirements", {
  conclusion <- paste(
    "Provide a concise descriptive name for this product.",
    "The name may express a higher-level sensory synthesis."
  )

  x <- do.call(
    nail_qda,
    c(
      qda_semantic_args(),
      list(
        conclusion = conclusion,
        isolate.groups = TRUE,
        generate = FALSE
      )
    )
  )

  prompt <- nail_prompt(x, select = "A", print = FALSE)
  expect_match(
    prompt,
    paste("# Final Interpretation Requirements", conclusion, sep = "\n\n"),
    fixed = TRUE
  )
})


test_that("QDA interpretation and reusable blocks have distinct responsibilities", {
  x <- do.call(
    nail_qda,
    c(
      qda_semantic_args(),
      list(
        conclusion = "Provide a concise descriptive name for this product.",
        isolate.groups = TRUE,
        generate = FALSE
      )
    )
  )

  blocks <- attr(x, "qda_prompt_blocks", exact = TRUE)$A
  interpretation <- blocks$interpretation
  identity <- blocks$identity
  reusable <- blocks$reusable

  expect_match(
    identity,
    "Preserve its original identifier and label.",
    fixed = TRUE
  )
  expect_match(
    identity,
    "A concise sensory characterization may complement it when useful.",
    fixed = TRUE
  )
  expect_match(
    interpretation,
    "develop a higher-level interpretation that captures their combined meaning",
    fixed = TRUE
  )
  expect_match(
    interpretation,
    "do not present conceptual connections as statistically demonstrated relationships",
    fixed = TRUE
  )
  expect_match(
    interpretation,
    "Preserve meaningful contrasts, nuances, and ambiguities.",
    fixed = TRUE
  )
  expect_match(
    interpretation,
    "When the evidence is heterogeneous or insufficient to support a unified characterization",
    fixed = TRUE
  )

  expect_false(grepl("STRICT GROUNDING RULES", reusable, fixed = TRUE))
  expect_false(grepl("descriptive_name: none", reusable, fixed = TRUE))
  expect_match(
    reusable,
    "descriptive_name: <short evidence-grounded descriptive name; write none only if no descriptive name is requested or no defensible name can be proposed>",
    fixed = TRUE
  )
  expect_gt(nchar(reusable), 0)
})


test_that("QDA default blocks can be removed without changing evidence", {
  args <- qda_semantic_args()

  full <- do.call(
    nail_qda,
    c(args, list(isolate.groups = TRUE, generate = FALSE))
  )
  minimal <- do.call(
    nail_qda,
    c(
      args,
      list(
        isolate.groups = TRUE,
        default_blocks = character(0),
        generate = FALSE
      )
    )
  )
  reading_only <- do.call(
    nail_qda,
    c(
      args,
      list(
        isolate.groups = TRUE,
        default_blocks = "reading",
        generate = FALSE
      )
    )
  )
  interpretation_only <- do.call(
    nail_qda,
    c(
      args,
      list(
        isolate.groups = TRUE,
        default_blocks = "interpretation",
        generate = FALSE
      )
    )
  )
  local_task_only <- do.call(
    nail_qda,
    c(
      args,
      list(
        isolate.groups = TRUE,
        default_blocks = "local_task",
        generate = FALSE
      )
    )
  )

  minimal_prompt <- nail_prompt(minimal, select = "A", print = FALSE)
  reading_prompt <- nail_prompt(reading_only, select = "A", print = FALSE)
  interpretation_prompt <- nail_prompt(
    interpretation_only,
    select = "A",
    print = FALSE
  )
  local_task_prompt <- nail_prompt(
    local_task_only,
    select = "A",
    print = FALSE
  )

  expect_false(grepl("## How to Read the Statistical Evidence", minimal_prompt, fixed = TRUE))
  expect_false(grepl("## Interpretation Rules", minimal_prompt, fixed = TRUE))
  expect_false(grepl("# Local Task", minimal_prompt, fixed = TRUE))
  expect_true(grepl("## Identity — known", minimal_prompt, fixed = TRUE))
  expect_true(grepl("# Data", minimal_prompt, fixed = TRUE))
  expect_true(grepl("## Reusable NaileR Metadata", minimal_prompt, fixed = TRUE))
  expect_true(grepl("# Final Interpretation Requirements", minimal_prompt, fixed = TRUE))
  expect_true(grepl("## How to Read the Statistical Evidence", reading_prompt, fixed = TRUE))
  expect_false(grepl("## Interpretation Rules", reading_prompt, fixed = TRUE))
  expect_true(grepl("## Interpretation Rules", interpretation_prompt, fixed = TRUE))
  expect_false(
    grepl("## How to Read the Statistical Evidence", interpretation_prompt, fixed = TRUE)
  )
  expect_false(grepl("# Local Task", interpretation_prompt, fixed = TRUE))
  expect_true(grepl("# Local Task", local_task_prompt, fixed = TRUE))
  expect_false(
    grepl("## How to Read the Statistical Evidence", local_task_prompt, fixed = TRUE)
  )
  expect_false(
    grepl("## Interpretation Rules", local_task_prompt, fixed = TRUE)
  )

  expect_identical(
    attr(full, "product_profiles", exact = TRUE),
    attr(minimal, "product_profiles", exact = TRUE)
  )
  expect_identical(
    attr(full, "product_profiles", exact = TRUE),
    attr(reading_only, "product_profiles", exact = TRUE)
  )
  expect_identical(
    attr(full, "product_profiles", exact = TRUE),
    attr(interpretation_only, "product_profiles", exact = TRUE)
  )
  expect_identical(
    attr(full, "product_profiles", exact = TRUE),
    attr(local_task_only, "product_profiles", exact = TRUE)
  )
  expect_identical(
    nail_evidence(full, select = "A"),
    nail_evidence(minimal, select = "A")
  )
})


test_that("QDA rejects unknown default prompt blocks", {
  expect_error(
    do.call(
      nail_qda,
      c(
        qda_semantic_args(),
        list(default_blocks = "banana", generate = FALSE)
      )
    ),
    "Unknown QDA default block"
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


test_that("QDA local and joint generation forward scalar prompts", {
  args <- qda_semantic_args()
  seen_prompts <- list()

  testthat::local_mocked_bindings(
    .call_llm_base = function(provider,
                              model,
                              prompt,
                              output,
                              llm_api_options) {
      seen_prompts[[length(seen_prompts) + 1L]] <<- prompt
      data.frame(
        model = model,
        response = "Mock scalar-prompt response",
        stringsAsFactors = FALSE
      )
    },
    .package = "NaileR"
  )

  local <- do.call(
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
  joint <- do.call(
    nail_qda,
    c(
      args,
      list(
        isolate.groups = FALSE,
        generate = TRUE,
        model = "mock-model"
      )
    )
  )

  expect_length(seen_prompts, 4L)
  expect_true(all(vapply(
    seen_prompts,
    function(prompt) is.character(prompt) && length(prompt) == 1L,
    logical(1)
  )))
  expect_identical(
    nail_prompt(joint, print = FALSE),
    attr(joint, "llm_io", exact = TRUE)$prompts$portfolio
  )
  expect_true(is.list(local))
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
