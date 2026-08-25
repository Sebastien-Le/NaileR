test_that("modern textual contextualized route delegates to nail_catdes_textual", {
  cat_obj <- structure(list(id = "cat"), class = "dummy_catdes")
  txt_obj <- structure(list(id = "txt"), class = "dummy_textual")

  seen <- new.env(parent = emptyenv())

  testthat::local_mocked_bindings(
    nail_catdes_textual = function(catdes,
                                   textual,
                                   introduction,
                                   request,
                                   conclusion,
                                   model,
                                   provider,
                                   isolate.groups,
                                   generate,
                                   ...) {
      seen$catdes <- catdes
      seen$textual <- textual
      seen$introduction <- introduction
      seen$request <- request
      seen$conclusion <- conclusion
      seen$model <- model
      seen$provider <- provider
      seen$isolate.groups <- isolate.groups
      seen$generate <- generate
      seen$dots <- list(...)

      structure(
        list(ok = TRUE),
        llm_io = structure(
          list(
            stage = "contextualization",
            prompts = list(G1 = "prompt"),
            responses = NULL,
            metadata = list(
              analysis = "nail_catdes_textual",
              scope = "group"
            )
          ),
          class = c("nail_llm_io", "list")
        )
      )
    },
    .package = "NaileR"
  )

  out <- nail_textual_contextualized(
    catdes = cat_obj,
    textual = txt_obj,
    introduction = "study context",
    request = "enrich",
    conclusion = "structured output",
    model = "mock-model",
    provider = "ollama",
    isolate.groups = TRUE,
    generate = FALSE,
    temperature = 0.1
  )

  expect_true(out$ok)
  expect_identical(seen$catdes, cat_obj)
  expect_identical(seen$textual, txt_obj)
  expect_identical(seen$introduction, "study context")
  expect_identical(seen$request, "enrich")
  expect_identical(seen$conclusion, "structured output")
  expect_identical(seen$model, "mock-model")
  expect_identical(seen$provider, "ollama")
  expect_true(seen$isolate.groups)
  expect_false(seen$generate)
  expect_identical(seen$dots$temperature, 0.1)

  route <- attr(out, "compatibility_route", exact = TRUE)

  expect_identical(
    route$route,
    "canonical"
  )
  expect_identical(
    route$canonical_function,
    "nail_catdes_textual"
  )
})


test_that("modern compatibility route requires catdes and textual together", {
  expect_error(
    nail_textual_contextualized(
      catdes = list(),
      generate = FALSE
    ),
    "`catdes` and `textual` must be supplied together",
    fixed = TRUE
  )

  expect_error(
    nail_textual_contextualized(
      textual = list(),
      generate = FALSE
    ),
    "`catdes` and `textual` must be supplied together",
    fixed = TRUE
  )
})


test_that("modern compatibility route rejects historical source inputs", {
  expect_error(
    nail_textual_contextualized(
      catdes = list(),
      textual = list(),
      dataset = data.frame(
        group = c("A", "B"),
        text = c("x", "y")
      ),
      num.var = 1,
      num.text = 2,
      generate = FALSE
    ),
    "Do not mix canonical `catdes`/`textual` inputs",
    fixed = TRUE
  )
})


test_that("modern compatibility route rejects explicitly supplied legacy tuning", {
  expect_error(
    nail_textual_contextualized(
      catdes = list(),
      textual = list(),
      sample.pct.text = 0.5,
      generate = FALSE
    ),
    "Do not mix canonical `catdes`/`textual` inputs",
    fixed = TRUE
  )

  expect_error(
    nail_textual_contextualized(
      catdes = list(),
      textual = list(),
      interpretation_mode = "groupwise",
      generate = FALSE
    ),
    "Do not mix canonical `catdes`/`textual` inputs",
    fixed = TRUE
  )
})


test_that("historical route delegates unchanged to preserved implementation", {
  seen <- new.env(parent = emptyenv())

  testthat::local_mocked_bindings(
    .nail_textual_contextualized_legacy = function(
        group_profile_prep,
        textual_prep,
        representative_verbatims,
        dataset,
        num.var,
        num.text,
        proba,
        sample.pct.text,
        sample.pct.profile,
        profile_mode,
        prompt_style,
        interpretation_mode,
        include_verbatims,
        n_central_verbatims,
        n_tension_verbatims,
        max_verbatim_chars,
        introduction,
        request,
        conclusion,
        isolate.groups,
        model,
        provider,
        row.w,
        generate,
        ...) {

      seen$group_profile_prep <- group_profile_prep
      seen$textual_prep <- textual_prep
      seen$proba <- proba
      seen$sample.pct.text <- sample.pct.text
      seen$profile_mode <- profile_mode
      seen$prompt_style <- prompt_style
      seen$interpretation_mode <- interpretation_mode
      seen$include_verbatims <- include_verbatims
      seen$model <- model
      seen$provider <- provider
      seen$generate <- generate
      seen$dots <- list(...)

      "legacy-result"
    },
    .package = "NaileR"
  )

  old_profile <- list(G1 = list(parsed = list()))
  old_text <- list(G1 = list(parsed = list()))

  out <- nail_textual_contextualized(
    group_profile_prep = old_profile,
    textual_prep = old_text,
    proba = 0.03,
    sample.pct.text = 0.75,
    profile_mode = "categorical",
    prompt_style = "detailed",
    interpretation_mode = "comparative",
    include_verbatims = FALSE,
    model = "legacy-model",
    provider = "gemini",
    generate = TRUE,
    seed = 123
  )

  expect_identical(out, "legacy-result")
  expect_identical(seen$group_profile_prep, old_profile)
  expect_identical(seen$textual_prep, old_text)
  expect_identical(seen$proba, 0.03)
  expect_identical(seen$sample.pct.text, 0.75)
  expect_identical(seen$profile_mode, "categorical")
  expect_identical(seen$prompt_style, "detailed")
  expect_identical(seen$interpretation_mode, "comparative")
  expect_false(seen$include_verbatims)
  expect_identical(seen$model, "legacy-model")
  expect_identical(seen$provider, "gemini")
  expect_true(seen$generate)
  expect_identical(seen$dots$seed, 123)
})


test_that("modern compatibility route does not invoke historical preparation", {
  cat_obj <- list(id = "cat")
  txt_obj <- list(id = "txt")

  testthat::local_mocked_bindings(
    nail_catdes_textual = function(...) {
      list(ok = TRUE)
    },
    .nail_textual_contextualized_legacy = function(...) {
      stop("legacy route should not be called")
    },
    nail_group_profile_prep = function(...) {
      stop("group profile prep should not be called")
    },
    nail_textual_prep = function(...) {
      stop("textual prep should not be called")
    },
    .package = "NaileR"
  )

  out <- nail_textual_contextualized(
    catdes = cat_obj,
    textual = txt_obj,
    generate = FALSE
  )

  expect_true(out$ok)
})
