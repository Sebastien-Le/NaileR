.catdes_stage3_empty_quanti <- function() {
  data.frame(
    "Mean in category" = numeric(0),
    "Overall mean" = numeric(0),
    "sd in category" = numeric(0),
    "Overall sd" = numeric(0),
    "p.value" = numeric(0),
    "v.test" = numeric(0),
    check.names = FALSE
  )
}

.catdes_stage3_profiles <- function() {
  quali_a <- data.frame(
    "Cla/Mod" = c(80, 20, 70, 25, 55),
    "Mod/Cla" = c(75, 18, 65, 22, 50),
    Global = c(45, 55, 40, 35, 30),
    "p.value" = c(1e-6, 1e-5, 1e-4, 1e-3, 0.02),
    "v.test" = c(10, -9, 8, -7, 1),
    check.names = FALSE,
    row.names = c(
      "binary_choice=yes",
      "binary_choice=no",
      "multilevel=one",
      "multilevel=two",
      "multilevel=three"
    )
  )

  quali_b <- data.frame(
    "Cla/Mod" = c(85, 15),
    "Mod/Cla" = c(80, 12),
    Global = c(50, 50),
    "p.value" = c(1e-5, 1e-4),
    "v.test" = c(6, -6),
    check.names = FALSE,
    row.names = c("b_only=yes", "b_only=no")
  )

  quanti_a <- data.frame(
    "Mean in category" = 8,
    "Overall mean" = 5,
    "sd in category" = 1,
    "Overall sd" = 1.5,
    "p.value" = 0.001,
    "v.test" = 4,
    check.names = FALSE,
    row.names = "score_A"
  )

  source <- list(
    category = list(A = quali_a, B = quali_b),
    quanti = list(A = quanti_a, B = .catdes_stage3_empty_quanti())
  )

  nail_catdes_prep(x = source)
}

.catdes_stage3_mock <- function(model, prompt) {
  group <- if (grepl('Category "A"|Group "A"', prompt)) "A" else "B"
  data.frame(
    model = model,
    created_at = as.POSIXct("2026-08-19", tz = "UTC"),
    response = paste("local semantic profile", group),
    done = TRUE,
    prompt = prompt,
    stringsAsFactors = FALSE
  )
}

test_that("semantic-facing facts use plain language and hide technical statistics", {
  profiles <- .catdes_stage3_profiles()
  result <- nail_catdes(
    x = profiles,
    quali.sample = 0.2,
    quanti.sample = 1,
    isolate.groups = TRUE,
    generate = FALSE
  )

  prompt_a <- result$A
  expect_match(prompt_a, "MORE FREQUENT", fixed = TRUE)
  expect_match(prompt_a, "LESS FREQUENT", fixed = TRUE)
  expect_match(prompt_a, "HIGHER", fixed = TRUE)
  expect_false(grepl("p.value", prompt_a, fixed = TRUE))
  expect_false(grepl("v.test", prompt_a, fixed = TRUE))
  expect_false(grepl("Evidence ID", prompt_a, fixed = TRUE))

  semantic <- attr(result, "semantic_facing_evidence")
  expect_s3_class(semantic, "nail_catdes_semantic_facing_evidence")
  expect_identical(semantic$settings$representation, "hybrid_plain")
})

test_that("semantic-facing labels are human-readable without mutating canonical evidence", {
  expect_identical(
    NaileR:::.display_variable_label_nail_catdes(
      "Ban.the.import.of.food.whose.production.does.not.respect.human.rights."
    ),
    "Ban the import of food whose production does not respect human rights"
  )

  expect_identical(
    NaileR:::.display_modality_label_nail_catdes(
      "Ban the import of food whose production does not respect human rights._Totally acceptable",
      "Ban.the.import.of.food.whose.production.does.not.respect.human.rights."
    ),
    "Totally acceptable"
  )

  expect_identical(
    NaileR:::.display_modality_label_nail_catdes(
      "yes",
      "loose_leaf"
    ),
    "yes"
  )

  expect_identical(
    NaileR:::.display_variable_label_nail_catdes("Petal.Length"),
    "Petal Length"
  )

  row <- data.frame(
    variable = "Ban.the.import.of.food.whose.production.does.not.respect.human.rights.",
    modality = "Ban the import of food whose production does not respect human rights._Totally acceptable",
    direction = "overrepresented",
    percentage_in_group = 73.12,
    global_percentage = 54.62,
    stringsAsFactors = FALSE
  )

  prompt_line <- NaileR:::.qualitative_prompt_line_nail_catdes(row)
  expect_match(prompt_line, '"Totally acceptable"', fixed = TRUE)
  expect_false(grepl("Ban the import of food", prompt_line, fixed = TRUE))
})

test_that("binary qualitative variables are completed within the selected group", {
  profiles <- .catdes_stage3_profiles()
  result <- nail_catdes(
    x = profiles,
    quali.sample = 0.2,
    quanti.sample = 0,
    isolate.groups = TRUE,
    generate = FALSE
  )

  evidence <- attr(result, "interpretation_evidence")
  semantic <- attr(result, "semantic_facing_evidence")

  expect_identical(
    evidence$groups$A$metrics$n_qualitative_selected,
    1L
  )

  displayed <- semantic$groups$A$displayed_evidence
  binary_rows <- displayed[displayed$variable == "binary_choice", , drop = FALSE]

  expect_setequal(binary_rows$modality, c("yes", "no"))
  expect_identical(nrow(binary_rows), 2L)
  expect_identical(semantic$groups$A$metrics$n_added_binary_contrast, 1L)
  expect_match(result$A, '"yes"', fixed = TRUE)
  expect_match(result$A, '"no"', fixed = TRUE)
})

test_that("drop.negative is respected during binary completion", {
  profiles <- .catdes_stage3_profiles()
  result <- nail_catdes(
    x = profiles,
    quali.sample = 0.2,
    quanti.sample = 0,
    drop.negative = TRUE,
    isolate.groups = TRUE,
    generate = FALSE
  )

  semantic <- attr(result, "semantic_facing_evidence")
  displayed <- semantic$groups$A$displayed_evidence
  binary_rows <- displayed[displayed$variable == "binary_choice", , drop = FALSE]

  expect_identical(binary_rows$modality, "yes")
  expect_identical(semantic$groups$A$metrics$n_added_binary_contrast, 0L)
  expect_false(grepl('response/modality "no"', result$A, fixed = TRUE))
})

test_that("multi-level variables are not completed beyond deterministic selection", {
  profiles <- .catdes_stage3_profiles()
  result <- nail_catdes(
    x = profiles,
    quali.sample = 0.6,
    quanti.sample = 0,
    isolate.groups = TRUE,
    generate = FALSE
  )

  semantic <- attr(result, "semantic_facing_evidence")
  displayed <- semantic$groups$A$displayed_evidence
  multi <- displayed[displayed$variable == "multilevel", , drop = FALSE]

  expect_identical(multi$modality, "one")
  expect_true(all(multi$representation_block == "multilevel_selected_only"))
  expect_false("three" %in% multi$modality)
})

test_that("local prompts contain only evidence from their own group", {
  profiles <- .catdes_stage3_profiles()
  result <- nail_catdes(
    x = profiles,
    isolate.groups = TRUE,
    generate = FALSE
  )

  # Prompts use human-readable display labels, while group isolation must
  # remain strict. Canonical identifiers are tested separately in the
  # semantic-facing evidence objects.
  expect_match(result$A, "score A", fixed = TRUE)
  expect_false(grepl("b only", result$A, fixed = TRUE))
  expect_match(result$B, "b only", fixed = TRUE)
  expect_false(grepl("score A", result$B, fixed = TRUE))

  local_prompts <- attr(result, "local_prompts")
  expect_identical(names(result), names(local_prompts))
  for (group_name in names(local_prompts)) {
    expect_identical(result[[group_name]], local_prompts[[group_name]])
  }
})

test_that("non-isolated prompt preview preserves outer compatibility but exposes local prompts", {
  profiles <- .catdes_stage3_profiles()
  result <- nail_catdes(
    x = profiles,
    isolate.groups = FALSE,
    generate = FALSE
  )

  expect_true(is.character(result))
  expect_length(result, 1L)
  expect_match(result, "Local-first semantic interpretation plan", fixed = TRUE)
  expect_match(result, 'Local prompt for Category "A"', fixed = TRUE)
  expect_match(result, 'Local prompt for Category "B"', fixed = TRUE)

  local_prompts <- attr(result, "local_prompts")
  expect_true(is.list(local_prompts))
  expect_setequal(names(local_prompts), c("A", "B"))
})

test_that("generation is always local-first and semantic profiles freeze each response", {
  profiles <- .catdes_stage3_profiles()
  calls <- 0L

  testthat::local_mocked_bindings(
    .call_llm_base = function(provider, model, prompt, output, llm_api_options) {
      calls <<- calls + 1L
      .catdes_stage3_mock(model, prompt)
    },
    .package = "NaileR"
  )

  result <- nail_catdes(
    x = profiles,
    isolate.groups = FALSE,
    generate = TRUE
  )

  evidence <- attr(result, "interpretation_evidence")
  semantic_profiles <- attr(result, "semantic_profiles")

  expect_identical(calls, evidence$metadata$n_ready_groups)
  expect_true(is.data.frame(result))
  expect_match(result$response, "local semantic profile A", fixed = TRUE)
  expect_match(result$response, "local semantic profile B", fixed = TRUE)

  expect_s3_class(semantic_profiles, "nail_catdes_semantic_profiles")
  expect_identical(semantic_profiles$settings$architecture, "local_first")
  expect_false(semantic_profiles$settings$global_synthesis_performed)
  expect_identical(semantic_profiles$groups$A$response, "local semantic profile A")
  expect_identical(semantic_profiles$groups$B$response, "local semantic profile B")
  expect_identical(semantic_profiles$metadata$n_generated, 2L)
})

test_that("isolate.groups changes presentation, not first-pass generation architecture", {
  profiles <- .catdes_stage3_profiles()
  calls <- 0L

  testthat::local_mocked_bindings(
    .call_llm_base = function(provider, model, prompt, output, llm_api_options) {
      calls <<- calls + 1L
      .catdes_stage3_mock(model, prompt)
    },
    .package = "NaileR"
  )

  result <- nail_catdes(
    x = profiles,
    isolate.groups = TRUE,
    generate = TRUE
  )

  expect_true(is.list(result))
  expect_setequal(names(result), c("A", "B"))
  expect_identical(calls, 2L)
  expect_identical(attr(result, "catdes_settings")$generation_architecture, "local_first")
  expect_false(attr(result, "catdes_settings")$global_synthesis_performed)
})

test_that("standard and latent local tasks preserve target status", {
  profiles <- .catdes_stage3_profiles()

  standard <- nail_catdes(
    x = profiles,
    interpretation_mode = "standard",
    isolate.groups = TRUE,
    generate = FALSE
  )
  latent <- nail_catdes(
    x = profiles,
    interpretation_mode = "latent",
    isolate.groups = TRUE,
    generate = FALSE
  )

  expect_match(standard$A, "without renaming it", fixed = TRUE)
  expect_match(standard$A, "category name is contextual information, not statistical evidence", fixed = TRUE)
  expect_match(latent$A, "propose one concise interpretive name", fixed = TRUE)
  expect_match(latent$A, "current labels are identifiers", fixed = TRUE)
})

test_that("semantic-facing projection never mutates canonical statistical profiles", {
  profiles <- .catdes_stage3_profiles()
  before <- profiles

  result <- nail_catdes(
    x = profiles,
    quali.sample = 0.2,
    quanti.sample = 1,
    generate = FALSE
  )

  expect_identical(attr(result, "statistical_profiles"), before)
  expect_identical(profiles, before)
  expect_identical(attr(result, "catdes_settings")$semantic_representation, "hybrid_plain")
})
