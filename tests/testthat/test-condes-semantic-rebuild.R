make_condes_semantic_data <- function(n = 90L) {
  target <- seq(-2.5, 2.5, length.out = n)
  i <- seq_len(n)

  data.frame(
    Score = target,
    Aligned = 1.8 * target + 0.12 * sin(i / 2),
    Opposed = -1.5 * target + 0.10 * cos(i / 3),
    Secondary = 0.65 * target + 0.35 * sin(i / 5),
    Group = factor(
      ifelse(
        target < -0.7,
        "Lower group",
        ifelse(target > 0.7, "Higher group", "Middle group")
      )
    ),
    Alternating = factor(
      ifelse(i %% 2L == 0L, "Even", "Odd")
    ),
    stringsAsFactors = TRUE
  )
}


condes_semantic_args <- function() {
  list(
    dataset = make_condes_semantic_data(),
    num.var = 1,
    proba = 0.05
  )
}


test_that("condes continuous_profile is canonical and inspectable", {
  x <- do.call(
    nail_condes,
    c(
      condes_semantic_args(),
      list(generate = FALSE)
    )
  )

  profile <- attr(
    x,
    "continuous_profile",
    exact = TRUE
  )

  expect_s3_class(
    profile,
    "nail_condes_continuous_profile"
  )

  expect_true(
    all(
      c(
        "target",
        "quantitative_associations",
        "qualitative_associations",
        "end_profiles",
        "evidence_registry",
        "settings",
        "metadata"
      ) %in% names(profile)
    )
  )

  expect_identical(
    profile$target$variable,
    "Score"
  )

  expect_true(
    all(
      c("Aligned", "Opposed") %in%
        profile$quantitative_associations$variable
    )
  )

  expect_true(
    nrow(profile$end_profiles$low) > 0L
  )
  expect_true(
    nrow(profile$end_profiles$high) > 0L
  )

  expect_identical(
    anyDuplicated(
      profile$evidence_registry$evidence_id
    ),
    0L
  )
})


test_that("end-profile evidence preserves source variable identity", {
  x <- nail_condes(
    make_condes_semantic_data(),
    num.var = 1,
    generate = FALSE
  )

  profile <- attr(
    x,
    "continuous_profile",
    exact = TRUE
  )

  ends <- rbind(
    profile$end_profiles$low,
    profile$end_profiles$high
  )

  expect_true(
    all(!is.na(ends$variable))
  )
  expect_true(
    any(
      ends$source_type == "quantitative"
    )
  )
  expect_true(
    any(
      ends$variable %in% c(
        "Aligned",
        "Opposed",
        "Secondary"
      )
    )
  )
})


test_that("continuous_profile is invariant to interpretation options", {
  args <- condes_semantic_args()

  standard <- do.call(
    nail_condes,
    c(
      args,
      list(
        interpretation_mode = "standard",
        sample.pct = 1,
        sample.method = "top",
        prompt_style = "detailed",
        target_label = "Observed score",
        target_concept = "observed construct",
        generate = FALSE
      )
    )
  )

  latent <- do.call(
    nail_condes,
    c(
      args,
      list(
        interpretation_mode = "latent",
        sample.pct = 0.5,
        sample.method = "stratified",
        prompt_style = "compact",
        target_label = "Dim1",
        target_concept = "latent construct",
        generate = FALSE
      )
    )
  )

  expect_identical(
    attr(
      standard,
      "continuous_profile",
      exact = TRUE
    ),
    attr(
      latent,
      "continuous_profile",
      exact = TRUE
    )
  )
})


test_that("standard and latent prompts use different semantic tasks", {
  dat <- make_condes_semantic_data()

  standard <- nail_condes(
    dat,
    num.var = 1,
    interpretation_mode = "standard",
    generate = FALSE
  )

  latent <- nail_condes(
    dat,
    num.var = 1,
    interpretation_mode = "latent",
    target_label = "Dim1",
    generate = FALSE
  )

  p_standard <- nail_prompt(
    standard,
    print = FALSE
  )
  p_latent <- nail_prompt(
    latent,
    print = FALSE
  )

  expect_false(
    identical(
      p_standard,
      p_latent
    )
  )

  expect_match(
    p_standard,
    "do not rename",
    ignore.case = TRUE
  )

  expect_match(
    p_latent,
    "What separates the higher end from the lower end",
    fixed = TRUE
  )

  expect_match(
    p_latent,
    "propose one concise name",
    ignore.case = TRUE
  )

  expect_false(
    grepl(
      "more favorable|less favorable",
      p_standard,
      ignore.case = TRUE
    )
  )
})


test_that("semantic-facing evidence contains explicit R-derived facts", {
  x <- nail_condes(
    make_condes_semantic_data(),
    num.var = 1,
    interpretation_mode = "latent",
    generate = FALSE
  )

  semantic <- attr(
    x,
    "semantic_facing_evidence",
    exact = TRUE
  )

  expect_s3_class(
    semantic,
    "nail_condes_semantic_facing_evidence"
  )

  expect_match(
    semantic$prompt_text,
    "correlation="
  )

  expect_match(
    semantic$prompt_text,
    "LOWER end|HIGHER end"
  )
})


test_that("custom introduction request and conclusion are preserved", {
  intro <- "INTRODUCTION_SENTINEL"
  request <- "REQUEST_SENTINEL"
  conclusion <- paste(
    "# CONCLUSION_SENTINEL",
    "",
    "Return a short answer.",
    sep = "\n"
  )

  x <- nail_condes(
    make_condes_semantic_data(),
    num.var = 1,
    introduction = intro,
    request = request,
    conclusion = conclusion,
    generate = FALSE
  )

  prompt <- nail_prompt(
    x,
    print = FALSE
  )

  expect_match(
    prompt,
    intro,
    fixed = TRUE
  )
  expect_match(
    prompt,
    request,
    fixed = TRUE
  )
  expect_match(
    prompt,
    conclusion,
    fixed = TRUE
  )
})


test_that("condes sampling is deterministic", {
  df <- data.frame(
    evidence_id = sprintf("E%02d", 1:10),
    direction = c(
      rep("positive", 7),
      rep("negative", 3)
    ),
    rank = 1:10,
    stringsAsFactors = FALSE
  )

  s1 <- NaileR:::.select_condes_ranked(
    df,
    sample_pct = 0.5,
    sample_method = "stratified",
    preserve_direction = TRUE
  )

  s2 <- NaileR:::.select_condes_ranked(
    df,
    sample_pct = 0.5,
    sample_method = "stratified",
    preserve_direction = TRUE
  )

  top <- NaileR:::.select_condes_ranked(
    df,
    sample_pct = 0.5,
    sample_method = "top",
    preserve_direction = TRUE
  )

  expect_identical(
    s1,
    s2
  )

  expect_equal(
    nrow(s1),
    5L
  )

  expect_equal(
    nrow(top),
    5L
  )

  expect_false(
    identical(
      s1$evidence_id,
      top$evidence_id
    )
  )

  expect_true(
    all(
      c("positive", "negative") %in%
        s1$direction
    )
  )
})


test_that("sample.pct changes interpretation evidence but not canonical evidence", {
  dat <- make_condes_semantic_data()

  all_evidence <- nail_condes(
    dat,
    num.var = 1,
    sample.pct = 1,
    generate = FALSE
  )

  sampled <- nail_condes(
    dat,
    num.var = 1,
    sample.pct = 0.4,
    sample.method = "stratified",
    generate = FALSE
  )

  expect_identical(
    attr(
      all_evidence,
      "continuous_profile",
      exact = TRUE
    ),
    attr(
      sampled,
      "continuous_profile",
      exact = TRUE
    )
  )

  expect_false(
    identical(
      attr(
        all_evidence,
        "interpretation_evidence",
        exact = TRUE
      )$selected_evidence_ids,
      attr(
        sampled,
        "interpretation_evidence",
        exact = TRUE
      )$selected_evidence_ids
    )
  )
})


test_that("missing quantitative values remain missing in profile construction", {
  dat <- data.frame(
    Target = c(-2, -1, 0, 1, 2),
    X = c(1, NA, 3, 4, 5),
    G = factor(c("A", "A", "B", "B", "B"))
  )

  built <- NaileR:::.build_condes_augmented_data(
    dataset = dat,
    num.var = 1,
    quanti.threshold = 1,
    quanti.cat = c(
      "Above-average value",
      "Below-average value",
      "Intermediate value"
    )
  )

  expect_true(
    is.na(built$data$NCONDS001[[2L]])
  )
})


test_that("weighted standardization is centered under supplied weights", {
  x <- c(0, 10, 20, 30)
  w <- c(10, 2, 1, 1)

  z <- NaileR:::.condes_standardize(
    x,
    weights = w
  )

  expect_equal(
    stats::weighted.mean(z, w),
    0,
    tolerance = 1e-10
  )
})


test_that("llm_io stores exact condes prompt and raw response", {
  testthat::local_mocked_bindings(
    .call_llm_base = function(provider,
                              model,
                              prompt,
                              output,
                              llm_api_options) {
      data.frame(
        response = "RAW_CONDES_RESPONSE",
        stringsAsFactors = FALSE
      )
    },
    .package = "NaileR"
  )

  x <- nail_condes(
    make_condes_semantic_data(),
    num.var = 1,
    interpretation_mode = "latent",
    target_label = "Dim1",
    generate = TRUE
  )

  prompt <- nail_prompt(
    x,
    select = "Dim1",
    print = FALSE
  )

  response <- nail_response(
    x,
    select = "Dim1",
    print = FALSE
  )

  expect_identical(
    prompt,
    x$prompt[[1L]]
  )

  expect_identical(
    response,
    "RAW_CONDES_RESPONSE"
  )

  expect_identical(
    attr(
      x,
      "llm_io",
      exact = TRUE
    )$stage,
    "interpretation"
  )
})


test_that("one condes result is the statistical source of truth", {
  x <- nail_condes(
    make_condes_semantic_data(),
    num.var = 1,
    generate = FALSE
  )

  primary <- attr(
    x,
    "condes_result",
    exact = TRUE
  )

  compatibility <- attr(
    x,
    "condes_profile_result",
    exact = TRUE
  )

  expect_s3_class(
    primary,
    "condes"
  )

  expect_identical(
    compatibility,
    primary
  )

  profile <- attr(
    x,
    "continuous_profile",
    exact = TRUE
  )

  expect_identical(
    profile$settings$statistical_source,
    "single_condes_on_augmented_data"
  )

  settings <- attr(
    x,
    "condes_settings",
    exact = TRUE
  )

  expect_identical(
    settings$statistical_source,
    "single_condes_on_augmented_data"
  )
})


test_that("technical quantitative states use value labels rather than score labels", {
  x <- nail_condes(
    make_condes_semantic_data(),
    num.var = 1,
    generate = FALSE
  )

  profile <- attr(
    x,
    "continuous_profile",
    exact = TRUE
  )

  ends <- rbind(
    profile$end_profiles$low,
    profile$end_profiles$high
  )

  quantitative_states <- ends[
    ends$source_type == "quantitative",
    ,
    drop = FALSE
  ]

  expect_true(
    nrow(quantitative_states) > 0L
  )

  expect_true(
    all(
      quantitative_states$category %in% c(
        "Above-average value",
        "Below-average value",
        "Intermediate value"
      )
    )
  )

  expect_false(
    any(
      grepl(
        "score",
        quantitative_states$category,
        ignore.case = TRUE
      )
    )
  )
})


test_that("augmented condes data keeps continuous predictors and adds technical states", {
  dat <- make_condes_semantic_data()

  augmented <- NaileR:::.build_condes_augmented_data(
    dataset = dat,
    num.var = 1,
    quanti.threshold = 1,
    quanti.cat = c(
      "Above-average value",
      "Below-average value",
      "Intermediate value"
    )
  )

  expect_true(
    is.numeric(augmented$data$NCONDQ001)
  )

  expect_true(
    is.factor(augmented$data$NCONDS001)
  )

  expect_true(
    any(
      augmented$variable_map$source_type == "technical_state"
    )
  )

  expect_true(
    any(
      augmented$variable_map$source_type == "qualitative"
    )
  )
})
