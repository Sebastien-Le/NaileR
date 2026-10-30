test_that("LLM options are explicit and provider-specific", {
  expect_identical(
    NaileR:::filter_ollama_options(list(temperature = 0.2, format = "json")),
    list(temperature = 0.2, format = "json")
  )

  expect_identical(
    NaileR:::filter_gemini_options(list(temperature = 0.2, max_tries = 1L)),
    list(temperature = 0.2, max_tries = 1L)
  )

  expect_error(
    NaileR:::filter_ollama_options(list(max_output_tokens = 32L)),
    "not compatible with provider `ollama`"
  )
  expect_error(
    NaileR:::filter_gemini_options(list(format = "json")),
    "not compatible with provider `gemini`"
  )
  expect_error(
    NaileR:::filter_gemini_options(list(unknown_option = TRUE)),
    "Unknown LLM option"
  )
})

test_that("Gemini option types and ranges are checked without exposing secrets", {
  expect_error(
    NaileR:::.validate_gemini_generation_options(list(temperature = 2.1)),
    "temperature"
  )
  expect_error(
    NaileR:::.validate_gemini_generation_options(list(top_p = -0.1)),
    "top_p"
  )
  expect_error(
    NaileR:::.validate_gemini_generation_options(list(max_tries = 0L)),
    "max_tries"
  )

  condition <- tryCatch(
    NaileR:::.validate_gemini_generation_options(
      list(api_key = 123456789L)
    ),
    error = identity
  )
  expect_s3_class(condition, "error")
  expect_match(conditionMessage(condition), "api_key")
  expect_false(grepl("123456789", conditionMessage(condition), fixed = TRUE))
})

test_that("preview validates options and never calls a provider", {
  local_mocked_bindings(
    .call_llm_base = function(...) stop("provider must not be called"),
    .package = "NaileR"
  )

  expect_silent(
    nail_catdes(
      dataset = iris,
      num.var = 5,
      provider = "gemini",
      temperature = 0.2,
      max_output_tokens = 32L,
      generate = FALSE
    )
  )
  expect_silent(
    nail_catdes(
      dataset = iris,
      num.var = 5,
      provider = "ollama",
      format = "json",
      generate = FALSE
    )
  )
  expect_error(
    nail_catdes(
      dataset = iris,
      num.var = 5,
      provider = "gemini",
      unknown_option = TRUE,
      generate = FALSE
    ),
    "Unknown LLM option"
  )
  expect_error(
    nail_catdes(
      dataset = iris,
      num.var = 5,
      provider = "ollama",
      timeout = 10,
      generate = FALSE
    ),
    "not compatible with provider `ollama`"
  )
})

test_that("omitted and explicit models are resolved for all CORE5 functions", {
  data(chocolates, package = "SensoMineR")

  condes <- nail_condes(
    dataset = iris,
    num.var = 1,
    provider = "gemini",
    generate = FALSE
  )
  catdes <- nail_catdes(
    dataset = iris,
    num.var = 5,
    provider = "gemini",
    generate = FALSE
  )
  descfreq <- nail_descfreq(
    dataset = data.frame(
      a = c(4, 3, 2),
      b = c(1, 2, 3),
      c = c(2, 3, 4)
    ),
    provider = "gemini",
    generate = FALSE
  )
  qda <- nail_qda(
    dataset = sensochoc,
    formul = "~Product+Panelist",
    firstvar = 5,
    lastvar = 18,
    provider = "gemini",
    generate = FALSE
  )
  textual <- nail_textual(
    dataset = data.frame(
      group = factor(c("A", "A", "B")),
      text = c("one", "two", "three")
    ),
    num.var = 1,
    num.text = 2,
    provider = "gemini",
    generate = FALSE
  )

  expect_identical(attr(condes, "condes_settings")$model, "gemini-2.5-flash")
  expect_identical(attr(catdes, "catdes_settings")$model, "gemini-2.5-flash")
  expect_identical(attr(descfreq, "descfreq_settings")$model, "gemini-2.5-flash")
  expect_identical(attr(qda, "qda_settings")$model, "gemini-2.5-flash")
  expect_identical(attr(textual, "textual_settings")$model, "gemini-2.5-flash")

  explicit <- nail_catdes(
    dataset = iris,
    num.var = 5,
    provider = "gemini",
    model = "explicit-test-model",
    generate = FALSE
  )
  expect_identical(
    attr(explicit, "catdes_settings")$model,
    "explicit-test-model"
  )

  ollama <- nail_catdes(
    dataset = iris,
    num.var = 5,
    provider = "ollama",
    generate = FALSE
  )
  expect_identical(attr(ollama, "catdes_settings")$model, "llama3")
})

test_that("the shared dispatcher validates options before either backend", {
  expect_error(
    NaileR:::.call_llm_base(
      provider = "gemini",
      model = "gemini-2.5-flash",
      prompt = "test",
      llm_api_options = list(format = "json")
    ),
    "not compatible with provider `gemini`"
  )
  expect_error(
    NaileR:::.call_llm_base(
      provider = "ollama",
      model = "llama3",
      prompt = "test",
      llm_api_options = list(unknown_option = TRUE)
    ),
    "Unknown LLM option"
  )
})

test_that("associated CATDES review routes resolve explicit provider defaults", {
  changed <- NaileR:::.catdes_ground_resolve_backend(
    model = NULL,
    provider = "gemini",
    catdes_settings = list(model = "saved-model", provider = "ollama")
  )
  expect_identical(changed$model, "gemini-2.5-flash")
  expect_identical(changed$provider, "gemini")

  inherited <- NaileR:::.catdes_ground_resolve_backend(
    model = NULL,
    provider = NULL,
    catdes_settings = list(model = "saved-model", provider = "ollama")
  )
  expect_identical(inherited$model, "saved-model")
  expect_identical(inherited$provider, "ollama")
})
