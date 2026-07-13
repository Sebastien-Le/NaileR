test_that("provider-specific options are separated", {
  ollama_options <- filter_ollama_options(list(
    temperature = 0.2,
    seed = 42,
    api_key = "must-not-leak",
    max_output_tokens = 100
  ))

  expect_true(
    all(c("temperature", "seed") %in% names(ollama_options))
  )
  expect_false("api_key" %in% names(ollama_options))
  expect_false("max_output_tokens" %in% names(ollama_options))

  gemini_options <- filter_gemini_options(list(
    temperature = 0.2,
    seed = 42,
    api_key = "test-key",
    max_output_tokens = 100,
    keep_alive = "5m"
  ))

  expect_true(
    all(
      c(
        "temperature",
        "seed",
        "api_key",
        "max_output_tokens"
      ) %in% names(gemini_options)
    )
  )
  expect_false("keep_alive" %in% names(gemini_options))
})
