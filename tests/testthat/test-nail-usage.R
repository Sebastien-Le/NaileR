make_usage_textual_data <- function() {
  data.frame(
    group = factor(rep(c("A", "B", "C"), each = 6)),
    score = c(8, 7, 9, 8, 7, 9, 5, 4, 6, 5, 4, 6, 2, 3, 1, 2, 3, 1),
    text = rep(
      c(
        "bright and fresh",
        "fresh and light",
        "not too heavy",
        "dark and rich",
        "bitter and intense",
        "not sweet"
      ),
      3
    ),
    stringsAsFactors = FALSE
  )
}

make_usage_qda_data <- function() {
  data(chocolates, package = "SensoMineR")
  sensochoc
}


test_that("nail_usage returns a stable empty table for previews", {
  x <- nail_condes(
    data.frame(
      Score = seq(-2, 2, length.out = 30),
      Aligned = seq(-1, 3, length.out = 30),
      Group = factor(rep(c("low", "high"), 15)),
      stringsAsFactors = TRUE
    ),
    num.var = 1,
    generate = FALSE
  )

  usage <- nail_usage(x)
  expect_s3_class(usage, "nail_usage")
  expect_equal(nrow(usage), 0L)
  expect_true(all(.nail_usage_columns() %in% names(usage)))
  expect_identical(attr(usage, "usage_status"), "not_generated")
})


test_that("historical llm_io without usage is explicitly unknown", {
  old <- structure(
    list(value = TRUE),
    llm_io = .new_nail_llm_io(
      stage = "interpretation",
      prompts = list(one = "prompt"),
      responses = list(one = "response"),
      metadata = list(analysis = "historical")
    )
  )
  usage <- nail_usage(old)
  expect_equal(nrow(usage), 0L)
  expect_identical(attr(usage, "usage_status"), "unknown")
})


test_that("usage normalization records tokens without double counting thinking", {
  usage <- .nail_usage_normalize_record(
    list(
      provider = "gemini",
      model_requested = "gemini-2.5-flash",
      input_tokens = 100,
      cached_input_tokens = 20,
      output_tokens = 30,
      thinking_tokens = 10,
      total_tokens_reported = 140,
      generation_status = "completed",
      parse_status = "success"
    ),
    prompt = "short prompt"
  )

  expect_equal(
    usage$estimated_cost,
    (80 * 0.30 + 20 * 0.03 + (30 + 10) * 2.50) / 1e6
  )
  expect_equal(usage$cost_status, "estimated_from_reported_usage")
  expect_equal(usage$cost_hypothesis, "cached_input_tokens_reported_by_provider")
  expect_equal(usage$input_tokens, 100)
  expect_equal(usage$thinking_tokens, 10)
  expect_equal(usage$total_tokens_reported, 140)

  summary <- nail_usage_summary(structure(
    usage,
    class = c("nail_usage", "data.frame")
  ))
  expect_equal(
    summary$value[summary$metric == "estimated_cost_total"],
    usage$estimated_cost
  )
})


test_that("Gemini finish reasons are mapped without assuming completion", {
  response <- function(reason = NULL) {
    candidate <- list(
      content = list(parts = list(list(text = "response text")))
    )
    if (!is.null(reason)) candidate$finishReason <- reason
    list(
      modelVersion = "gemini-test-version",
      candidates = list(candidate),
      usageMetadata = list(
        promptTokenCount = 10,
        candidatesTokenCount = 4,
        thoughtsTokenCount = 3,
        totalTokenCount = 17
      )
    )
  }

  expect_identical(
    .gemini_parse_response(response("STOP"), "gemini-2.5-flash")$usage$generation_status,
    "completed"
  )
  expect_identical(
    .gemini_parse_response(response("MAX_TOKENS"), "gemini-2.5-flash")$usage$generation_status,
    "interrupted"
  )
  expect_identical(
    .gemini_parse_response(response("SAFETY"), "gemini-2.5-flash")$usage$generation_status,
    "safety_blocked"
  )
  expect_identical(
    .gemini_parse_response(response("RECITATION"), "gemini-2.5-flash")$usage$generation_status,
    "recitation_blocked"
  )
  expect_identical(
    .gemini_parse_response(response("OTHER_REASON"), "gemini-2.5-flash")$usage$generation_status,
    "other_finished"
  )
  expect_identical(
    .gemini_parse_response(response(), "gemini-2.5-flash")$usage$generation_status,
    "unknown"
  )
})


test_that("interrupted and unknown statuses are excluded from completion", {
  make_record <- function(status) {
    .nail_usage_normalize_record(list(
      provider = "ollama",
      model_requested = "mock",
      input_tokens = 10,
      output_tokens = 5,
      thinking_tokens = NA_real_,
      cached_input_tokens = NA_real_,
      generation_status = status
    ))
  }
  usage <- do.call(rbind, lapply(
    c("completed", "interrupted", "failed", "unknown"),
    make_record
  ))
  class(usage) <- c("nail_usage", "data.frame")
  summary <- nail_usage_summary(usage)
  value <- function(name) summary$value[summary$metric == name]

  expect_equal(value("n_completed"), 1)
  expect_equal(value("n_interrupted"), 1)
  expect_equal(value("n_failed"), 1)
  expect_equal(value("n_unknown_status"), 1)
  expect_equal(value("generation_completion_denominator"), 4)
  expect_equal(value("generation_completion_rate"), 0.25)
  expect_true(is.na(value("thinking_tokens_total")))
  expect_equal(value("thinking_tokens_coverage"), 0)
  expect_equal(value("input_tokens_coverage"), 1)
})


test_that("missing cache tokens produce a conditional cost estimate", {
  usage <- .nail_usage_normalize_record(list(
    provider = "gemini",
    model_requested = "gemini-2.5-flash",
    input_tokens = 100,
    output_tokens = 20,
    thinking_tokens = 10,
    cached_input_tokens = NA_real_,
    duration_seconds = 0.2,
    generation_status = "completed"
  ))
  expect_equal(usage$estimated_cost, (100 * 0.30 + (20 + 10) * 2.50) / 1e6)
  expect_identical(usage$cost_status, "estimated_conditional")
  expect_identical(usage$cost_hypothesis, "cached_input_tokens_missing_assumed_zero")

  class(usage) <- c("nail_usage", "data.frame")
  pdf_path <- tempfile(fileext = ".pdf")
  grDevices::pdf(pdf_path)
  on.exit(grDevices::dev.off(), add = TRUE)
  expect_silent(plot(usage, metric = "tokens"))
  expect_silent(plot(usage, metric = "cost"))
})


test_that("missing reflection tokens keep cost unknown", {
  usage <- .nail_usage_normalize_record(list(
    provider = "gemini",
    model_requested = "gemini-2.5-flash",
    input_tokens = 100,
    output_tokens = 20,
    thinking_tokens = NA_real_,
    cached_input_tokens = NA_real_,
    duration_seconds = 0.2,
    generation_status = "completed"
  ))
  expect_true(is.na(usage$estimated_cost))
  expect_identical(usage$cost_status, "unknown_missing_cost_components")
  expect_identical(usage$cost_hypothesis, "not_estimable_from_available_usage_metadata")

  class(usage) <- c("nail_usage", "data.frame")
  pdf_path <- tempfile(fileext = ".pdf")
  grDevices::pdf(pdf_path)
  on.exit(grDevices::dev.off(), add = TRUE)
  expect_warning(plot(usage, metric = "cost"), "excluded")
  expect_warning(plot(usage, metric = "tokens"), "Missing token component")
})


test_that("all seven public analyses expose a valid preview usage table", {
  condes_data <- data.frame(
    Score = seq(-2, 2, length.out = 30),
    Aligned = seq(-1, 3, length.out = 30),
    Opposed = seq(3, 1, length.out = 30),
    Group = factor(rep(c("low", "high"), 15)),
    stringsAsFactors = TRUE
  )
  text_data <- make_usage_textual_data()
  qda_data <- make_usage_qda_data()

  condes <- nail_condes(condes_data, num.var = 1, generate = FALSE)
  catdes <- nail_catdes(
    text_data[, c("group", "score")],
    num.var = 1,
    proba = 1,
    generate = FALSE
  )
  descfreq <- nail_descfreq(
    data.frame(
      sweet = c(30, 5, 10),
      bitter = c(5, 30, 10),
      neutral = c(10, 10, 30),
      row.names = c("A", "B", "C")
    ),
    isolate.groups = TRUE,
    generate = FALSE
  )
  textual <- nail_textual(
    text_data[, c("group", "text")],
    num.var = 1,
    num.text = 2,
    generate = FALSE
  )
  qda <- nail_qda(
    qda_data,
    formul = "~Product+Panelist",
    firstvar = 5,
    lastvar = 18,
    generate = FALSE
  )
  qda_space <- nail_qda_space(
    qda,
    ncp = 1,
    min_inertia_pct = 0,
    generate = FALSE
  )

  textual_profiles <- attr(textual, "textual_profiles", exact = TRUE)
  for (group_name in names(textual_profiles$groups)) {
    textual_profiles$groups[[group_name]]$status <- "available"
  }
  attr(textual, "textual_profiles") <- textual_profiles
  catdes_textual <- nail_catdes_textual(
    catdes,
    textual,
    generate = FALSE
  )

  results <- list(
    condes = condes,
    catdes = catdes,
    descfreq = descfreq,
    qda = qda,
    textual = textual,
    qda_space = qda_space,
    catdes_textual = catdes_textual
  )

  for (result in results) {
    usage <- nail_usage(result)
    expect_s3_class(usage, "nail_usage")
    expect_equal(nrow(usage), 0L)
    expect_true(all(.nail_usage_columns() %in% names(usage)))
    expect_identical(attr(usage, "usage_status"), "not_generated")
  }
})


test_that("simulated backend usage is associated with exact prompts and responses", {
  fake_backend <- function(provider, model, prompt, output, llm_api_options) {
    out <- data.frame(
      model = model,
      provider = provider,
      response = "A concise generated answer.",
      stringsAsFactors = FALSE
    )
    attr(out, "nail_usage") <- list(
      provider = provider,
      model_requested = model,
      model_version = "test-model-version",
      input_tokens = 11,
      output_tokens = 7,
      thinking_tokens = 2,
      total_tokens_reported = 20,
      duration_seconds = 0.01,
      http_attempts = 1L,
      finish_reason = "STOP",
      http_status = 200L,
      generation_status = "completed"
    )
    out
  }

  data <- make_usage_textual_data()
  testthat::local_mocked_bindings(.call_llm_base = fake_backend)

  result <- nail_textual(
    data[, c("group", "text")],
    num.var = 1,
    num.text = 2,
    model = "mock-model",
    provider = "ollama",
    generate = TRUE
  )

  usage <- nail_usage(result)
  expect_equal(nrow(usage), 3L)
  expect_true(all(usage$provider == "ollama"))
  expect_true(all(usage$input_tokens == 11))
  expect_true(all(usage$output_tokens == 7))
  expect_true(all(usage$generation_status == "completed"))
  expect_equal(
    unname(unlist(nail_prompt(result, print = FALSE))),
    unname(unlist(attr(result, "llm_io", exact = TRUE)$prompts))
  )
  expect_equal(
    unname(unlist(nail_response(result, print = FALSE))),
    unname(unlist(attr(result, "llm_io", exact = TRUE)$responses))
  )
})


test_that("CONDES usage scope_id uses the original target variable name", {
  fake_backend <- function(provider, model, prompt, output, llm_api_options) {
    out <- data.frame(
      model = model,
      provider = provider,
      response = "A generated interpretation.",
      done = TRUE,
      stringsAsFactors = FALSE
    )
    attr(out, "nail_usage") <- list(
      provider = provider,
      model_requested = model,
      input_tokens = 10,
      output_tokens = 5,
      thinking_tokens = 1,
      cached_input_tokens = 0,
      total_tokens_reported = 16,
      generation_status = "completed"
    )
    out
  }
  testthat::local_mocked_bindings(.call_llm_base = fake_backend)

  x <- nail_condes(
    data.frame(
      Satisfaction = seq(-2, 2, length.out = 30),
      Group = factor(rep(c("low", "high"), 15)),
      stringsAsFactors = TRUE
    ),
    num.var = 1,
    provider = "ollama",
    generate = TRUE,
    target_label = "Displayed satisfaction"
  )
  usage <- nail_usage(x)
  expect_equal(nrow(usage), 1L)
  expect_identical(usage$scope_id, "Satisfaction")
  expect_identical(
    unname(nail_prompt(x, print = FALSE)),
    unname(attr(x, "llm_io", exact = TRUE)$prompts[["Displayed satisfaction"]])
  )
})


test_that("Gemini text and data-frame adapters preserve provider metadata", {
  fake_generate <- function(prompt, model, ...) {
    out <- "generated text"
    attr(out, "nail_usage") <- list(
      provider = "gemini",
      model_requested = model,
      model_version = "gemini-test-version",
      input_tokens = 20,
      output_tokens = 8,
      thinking_tokens = 3,
      cached_input_tokens = 5,
      total_tokens_reported = 31,
      duration_seconds = 0.2,
      http_attempts = 1L,
      finish_reason = "MAX_TOKENS",
      http_status = 200L,
      generation_status = "interrupted",
      max_output_tokens = 8
    )
    out
  }
  testthat::local_mocked_bindings(
    gemini_generate = fake_generate,
    .package = "NaileR"
  )

  text <- NaileR:::.call_gemini_base(
    model = "gemini-2.5-flash",
    prompt = "test",
    output = "text"
  )
  frame <- NaileR:::.call_gemini_base(
    model = "gemini-2.5-flash",
    prompt = "test",
    output = "df"
  )

  expect_identical(attr(text, "nail_usage", exact = TRUE)$finish_reason, "MAX_TOKENS")
  expect_identical(attr(text, "nail_usage", exact = TRUE)$generation_status, "interrupted")
  expect_equal(attr(frame, "nail_usage", exact = TRUE)$input_tokens, 20)
  expect_equal(as.character(frame$response), "generated text")
})


test_that("Ollama completion requires an established end state", {
  done_only <- data.frame(done = TRUE, stringsAsFactors = FALSE)
  not_done <- data.frame(done = FALSE, stringsAsFactors = FALSE)
  no_status <- data.frame(response = "text", stringsAsFactors = FALSE)
  stopped <- data.frame(done_reason = "stop", stringsAsFactors = FALSE)
  length_limited <- data.frame(done_reason = "length", stringsAsFactors = FALSE)

  expect_identical(.ollama_generation_status(done_only), "completed")
  expect_identical(.ollama_generation_status(not_done), "unknown")
  expect_identical(.ollama_generation_status(no_status), "unknown")
  expect_identical(.ollama_generation_status(stopped), "completed")
  expect_identical(.ollama_generation_status(length_limited), "interrupted")
})


test_that("all seven generated workflows attribute simulated calls", {
  calls <- 0L
  fake_backend <- function(provider, model, prompt, output, llm_api_options) {
    calls <<- calls + 1L
    out <- data.frame(
      model = model,
      provider = provider,
      response = "Generated text for an offline usage test.",
      done = TRUE,
      stringsAsFactors = FALSE
    )
    attr(out, "nail_usage") <- list(
      provider = provider,
      model_requested = model,
      model_version = "offline-test-model",
      input_tokens = 12,
      output_tokens = 9,
      thinking_tokens = 0,
      total_tokens_reported = 21,
      duration_seconds = 0.01,
      http_attempts = 1L,
      finish_reason = "STOP",
      http_status = 200L,
      generation_status = "completed"
    )
    out
  }
  testthat::local_mocked_bindings(.call_llm_base = fake_backend)

  condes_data <- data.frame(
    Score = seq(-2, 2, length.out = 30),
    Aligned = seq(-1, 3, length.out = 30),
    Group = factor(rep(c("low", "high"), 15)),
    stringsAsFactors = TRUE
  )
  text_data <- make_usage_textual_data()
  condes <- nail_condes(condes_data, num.var = 1, generate = TRUE, model = "mock")
  catdes <- nail_catdes(
    text_data[, c("group", "score")], num.var = 1,
    proba = 1, generate = TRUE, model = "mock"
  )
  descfreq <- nail_descfreq(
    data.frame(sweet = c(30, 5, 10), bitter = c(5, 30, 10), neutral = c(10, 10, 30),
               row.names = c("A", "B", "C")),
    generate = TRUE, model = "mock"
  )
  textual <- nail_textual(
    text_data[, c("group", "text")], 1, 2,
    generate = TRUE, model = "mock"
  )
  data(chocolates, package = "SensoMineR")
  qda <- nail_qda(
    sensochoc, "~Product+Panelist", 5, lastvar = 18,
    generate = TRUE, model = "mock"
  )
  qda_space <- nail_qda_space(
    qda, ncp = 1, min_inertia_pct = 0,
    generate = TRUE, model = "mock"
  )
  textual_profiles <- attr(textual, "textual_profiles", exact = TRUE)
  for (group_name in names(textual_profiles$groups)) {
    textual_profiles$groups[[group_name]]$status <- "available"
  }
  attr(textual, "textual_profiles") <- textual_profiles
  catdes_textual <- nail_catdes_textual(
    catdes = nail_catdes(
      text_data[, c("group", "score")], num.var = 1,
      proba = 1, generate = FALSE
    ),
    textual = textual,
    generate = TRUE,
    model = "mock"
  )

  generated <- list(
    condes = condes,
    catdes = catdes,
    descfreq = descfreq,
    qda = qda,
    textual = textual,
    qda_space = qda_space,
    catdes_textual = catdes_textual
  )
  expect_gt(calls, 0L)
  expect_true(all(vapply(generated, function(result) {
    usage <- nail_usage(result)
    is.data.frame(usage) && nrow(usage) >= 1L &&
      all(usage$generation_status == "completed")
  }, logical(1))))
})


test_that("usage plots and RDS round-trip are offline and non-mutating", {
  usage <- .nail_usage_normalize_record(
    list(
      provider = "ollama",
      model_requested = "mock",
      input_tokens = 10,
      output_tokens = 5,
      thinking_tokens = NA_real_,
      duration_seconds = 0.1,
      generation_status = "completed"
    )
  )
  class(usage) <- c("nail_usage", "data.frame")

  pdf_path <- tempfile(fileext = ".pdf")
  grDevices::pdf(pdf_path)
  on.exit(grDevices::dev.off(), add = TRUE)
  expect_warning(plot(usage, metric = "tokens"), "Missing token component")
  expect_warning(plot(usage, metric = "cost"), "excluded")
  expect_silent(plot(usage, metric = "duration"))

  rds_path <- tempfile(fileext = ".rds")
  saveRDS(usage, rds_path)
  roundtrip <- readRDS(rds_path)
  expect_identical(roundtrip, usage)
})
