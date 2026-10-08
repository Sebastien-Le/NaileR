.catdes_prompt_blocks_example <- function(interpretation_mode = "standard",
                                           isolate_groups = TRUE) {
  data(atomic_habit, package = "NaileR")

  nail_catdes(
    dataset = atomic_habit,
    num.var = 2,
    interpretation_mode = interpretation_mode,
    isolate.groups = isolate_groups,
    quali.sample = 1,
    quanti.sample = 1,
    generate = FALSE
  )
}

.catdes_prompt_blocks_group <- function(x) {
  "I feel able not to take the plane"
}

test_that("CATDES stores a stable block representation and renders it in order", {
  result <- .catdes_prompt_blocks_example("standard")
  group_name <- .catdes_prompt_blocks_group(result)
  blocks <- attr(result, "catdes_prompt_blocks", exact = TRUE)[[group_name]]

  expect_identical(
    names(blocks),
    c(
      "context", "reading", "question", "interpretation",
      "local_task", "evidence", "output"
    )
  )
  expect_null(blocks$output)
  expect_identical(
    blocks$evidence,
    attr(result, "semantic_facing_evidence")$groups[[group_name]]$text
  )

  prompt <- nail_prompt(result, select = group_name, print = FALSE)
  headings <- c(
    "# Introduction",
    "## How to Read the Statistical Evidence",
    "# Overall Analytical Request",
    "## Interpretation Rules",
    "# Local Task",
    "# Data"
  )
  positions <- vapply(
    headings,
    function(heading) regexpr(heading, prompt, fixed = TRUE)[1L],
    integer(1)
  )

  expect_true(all(positions > 0L))
  expect_true(all(diff(positions) > 0L))
  expect_identical(prompt, result[[group_name]])
})

test_that("CATDES standard reading contains the R2 statistical semantics", {
  result <- .catdes_prompt_blocks_example("standard")
  group_name <- .catdes_prompt_blocks_group(result)
  reading <- attr(result, "catdes_prompt_blocks")[[group_name]]$reading

  expect_match(reading, "category", fixed = TRUE)
  expect_match(reading, "full sample", fixed = TRUE)
  expect_match(reading, "MORE FREQUENT", fixed = TRUE)
  expect_match(reading, "LESS FREQUENT", fixed = TRUE)
  expect_match(reading, "HIGHER", fixed = TRUE)
  expect_match(reading, "LOWER", fixed = TRUE)
  expect_match(reading, "descriptive values, not p-values", fixed = TRUE)
  expect_match(reading, "same variable", fixed = TRUE)
  expect_match(reading, "not thereby absent, average, rejected, or unimportant", fixed = TRUE)

  expect_false(grepl("rename", reading, fixed = TRUE))
  expect_false(grepl("meaningful name", reading, fixed = TRUE))
  expect_false(grepl("higher-level interpretation", reading, fixed = TRUE))
  expect_false(grepl("hypothesis", reading, fixed = TRUE))
  expect_false(grepl("unseen", reading, fixed = TRUE))
})

test_that("CATDES latent keeps the same reading core with group vocabulary", {
  standard <- .catdes_prompt_blocks_example("standard")
  latent <- .catdes_prompt_blocks_example("latent")
  group_name <- .catdes_prompt_blocks_group(standard)
  standard_blocks <- attr(standard, "catdes_prompt_blocks")[[group_name]]
  latent_blocks <- attr(latent, "catdes_prompt_blocks")[[group_name]]

  standard_core <- gsub(
    "category", "UNIT",
    standard_blocks$reading,
    fixed = TRUE
  )
  latent_core <- gsub("group", "UNIT", latent_blocks$reading, fixed = TRUE)

  expect_identical(standard_core, latent_core)
  expect_match(latent_blocks$reading, "this group", fixed = TRUE)
  expect_false(grepl("category", latent_blocks$reading, fixed = TRUE))
  expect_match(latent_blocks$interpretation, "This is a constructed profile or latent class", fixed = TRUE)
  expect_match(latent_blocks$interpretation, "identifier", fixed = TRUE)
  expect_match(latent_blocks$interpretation, "Its current label is an identifier", fixed = TRUE)
  expect_match(latent_blocks$interpretation, "Its meaning may be inferred", fixed = TRUE)
  expect_match(latent_blocks$interpretation, "meaningful name", fixed = TRUE)
  expect_false(grepl("These are constructed profiles", latent_blocks$interpretation, fixed = TRUE))
  expect_false(grepl("Their current labels", latent_blocks$interpretation, fixed = TRUE))
  expect_false(grepl("preserve their original names", latent_blocks$interpretation, fixed = TRUE))
  expect_match(latent_blocks$local_task, "constructed group", fixed = TRUE)
  expect_match(latent_blocks$local_task, "interpretive name", fixed = TRUE)
})

test_that("CATDES interpretation and local task keep mode-specific epistemic rules", {
  standard <- .catdes_prompt_blocks_example("standard")
  latent <- .catdes_prompt_blocks_example("latent")
  group_name <- .catdes_prompt_blocks_group(standard)
  standard_blocks <- attr(standard, "catdes_prompt_blocks")[[group_name]]
  latent_blocks <- attr(latent, "catdes_prompt_blocks")[[group_name]]

  expect_match(standard_blocks$interpretation, "This is an observed category", fixed = TRUE)
  expect_match(standard_blocks$interpretation, "Preserve its original name", fixed = TRUE)
  expect_match(standard_blocks$interpretation, "this category", fixed = TRUE)
  expect_match(standard_blocks$interpretation, "The category name is contextual information", fixed = TRUE)
  expect_false(grepl("These are observed categories", standard_blocks$interpretation, fixed = TRUE))
  expect_false(grepl("their original names", standard_blocks$interpretation, fixed = TRUE))
  expect_false(grepl("the categories", standard_blocks$interpretation, fixed = TRUE))
  expect_match(standard_blocks$interpretation, "higher-level interpretation", fixed = TRUE)
  expect_match(standard_blocks$interpretation, "contextual hypothesis", fixed = TRUE)
  expect_match(standard_blocks$local_task, "observed category", fixed = TRUE)
  expect_match(standard_blocks$local_task, "unseen categories", fixed = TRUE)

  expect_match(latent_blocks$interpretation, "meaning may be inferred", fixed = TRUE)
  expect_match(latent_blocks$interpretation, "traceable", fixed = TRUE)
  expect_match(latent_blocks$interpretation, "contextual hypothesis", fixed = TRUE)
  expect_match(latent_blocks$local_task, "unseen groups", fixed = TRUE)
  expect_false(grepl("do not rename", tolower(latent_blocks$interpretation), fixed = TRUE))
})

test_that("CATDES prompt modularization preserves displayed and canonical evidence", {
  result <- .catdes_prompt_blocks_example("standard")
  group_name <- .catdes_prompt_blocks_group(result)
  semantic_group <- attr(result, "semantic_facing_evidence")$groups[[group_name]]
  selected <- nail_evidence(result, select = group_name)
  profiles <- attr(result, "statistical_profiles")
  interpretation <- attr(result, "interpretation_evidence")$groups[[group_name]]
  registry <- profiles$evidence_registry

  expect_identical(semantic_group$metrics$n_displayed, 12L)
  expect_identical(selected$metrics$n_qualitative_markers, 10L)
  expect_identical(selected$metrics$n_quantitative_markers, 2L)
  expect_setequal(
    semantic_group$displayed_evidence$evidence_id,
    selected$evidence_ids
  )
  expect_setequal(
    interpretation$selected_evidence_ids,
    selected$evidence_ids
  )
  expect_true(all(selected$evidence_ids %in% registry$evidence_id))
  expect_false(grepl("p.value", semantic_group$text, fixed = TRUE))
  expect_false(grepl("v.test", semantic_group$text, fixed = TRUE))
  expect_false(grepl("Evidence ID", semantic_group$text, fixed = TRUE))
})

test_that("CATDES non-isolated mode stores and renders one joint portfolio prompt", {
  result <- .catdes_prompt_blocks_example(
    interpretation_mode = "standard",
    isolate_groups = FALSE
  )
  blocks <- attr(result, "catdes_prompt_blocks", exact = TRUE)
  portfolio <- blocks$portfolio

  expect_identical(names(blocks), "portfolio")
  expect_identical(
    names(portfolio),
    c("context", "reading", "question", "interpretation",
      "local_task", "evidence", "output")
  )
  expect_true(is.character(result))
  expect_length(result, 1L)
  expect_match(result, "Interpret the complete set of observed categories", fixed = TRUE)
  expect_match(result, "Preserve all observed category names", fixed = TRUE)
  expect_match(result, "do not present a contrast between two categories", fixed = TRUE)
  expect_match(result, "Category \"I feel able not to take the plane\"", fixed = TRUE)
  expect_false(grepl("Local-first semantic interpretation plan", result, fixed = TRUE))
  expect_identical(attr(result, "catdes_settings")$generation_architecture, "joint")
  expect_identical(attr(result, "catdes_settings")$prompt_scope, "joint")
  expect_true(attr(result, "catdes_settings")$local_prompts_for_audit_only)
})

test_that("CATDES joint and local scopes preserve identical evidence", {
  data(atomic_habit, package = "NaileR")
  local <- nail_catdes(
    dataset = atomic_habit,
    num.var = 2,
    isolate.groups = TRUE,
    generate = FALSE
  )
  prepared <- attr(local, "statistical_profiles")
  joint <- nail_catdes(
    x = prepared,
    isolate.groups = FALSE,
    generate = FALSE
  )

  expect_identical(
    attr(local, "statistical_profiles"),
    attr(joint, "statistical_profiles")
  )
  expect_identical(
    attr(local, "interpretation_evidence"),
    attr(joint, "interpretation_evidence")
  )
  expect_identical(
    attr(local, "semantic_facing_evidence"),
    attr(joint, "semantic_facing_evidence")
  )
  expect_identical(
    nail_evidence(local),
    nail_evidence(joint)
  )
  expect_identical(
    names(attr(local, "semantic_facing_evidence")$groups),
    names(attr(joint, "semantic_facing_evidence")$groups)
  )
})

test_that("CATDES latent joint mode keeps group naming and comparison rules", {
  result <- .catdes_prompt_blocks_example(
    interpretation_mode = "latent",
    isolate_groups = FALSE
  )
  portfolio <- attr(result, "catdes_prompt_blocks", exact = TRUE)$portfolio

  expect_match(portfolio$reading, "under which it appears", fixed = TRUE)
  expect_match(portfolio$reading, "pairwise statistical test", fixed = TRUE)
  expect_match(portfolio$interpretation, "labels are identifiers", fixed = TRUE)
  expect_match(portfolio$interpretation, "meaningful names may be proposed", fixed = TRUE)
  expect_match(portfolio$local_task, "A concise interpretive name may be proposed", fixed = TRUE)
  expect_false(grepl("Preserve all observed category names", portfolio$local_task, fixed = TRUE))
  expect_false(grepl("do not rename", tolower(portfolio$interpretation), fixed = TRUE))
})

test_that("CATDES default requests express interpretive rather than statistical hierarchy", {
  requests <- unlist(lapply(c("standard", "latent"), function(mode) {
    unlist(lapply(c(FALSE, TRUE), function(isolate) {
      c(
        detailed = build_request_catdes(mode, isolate, "detailed"),
        compact = build_request_catdes(mode, isolate, "compact")
      )
    }), use.names = FALSE)
  }), use.names = FALSE)

  expect_true(all(grepl("central interpretive pattern", requests, fixed = TRUE)))
  expect_true(all(grepl("secondary displayed characteristics", requests, fixed = TRUE)))
  expect_false(any(grepl("strongest results", requests, fixed = TRUE)))
  expect_false(any(grepl("strong evidence", requests, fixed = TRUE)))
})

test_that("CATDES joint generation uses one backend response without fabricating local responses", {
  profiles <- .catdes_prompt_blocks_example("standard", isolate_groups = TRUE)
  calls <- 0L

  testthat::local_mocked_bindings(
    .call_llm_base = function(provider, model, prompt, output, llm_api_options) {
      calls <<- calls + 1L
      data.frame(
        model = model,
        created_at = as.POSIXct("2026-01-01", tz = "UTC"),
        response = "joint mock response",
        done = TRUE,
        prompt = prompt,
        stringsAsFactors = FALSE
      )
    },
    .package = "NaileR"
  )

  result <- nail_catdes(
    x = attr(profiles, "statistical_profiles"),
    isolate.groups = FALSE,
    generate = TRUE
  )
  semantic_profiles <- attr(result, "semantic_profiles")

  expect_identical(calls, 1L)
  expect_true(is.data.frame(result))
  expect_identical(attr(result, "catdes_settings")$llm_calls, 1L)
  expect_identical(semantic_profiles$settings$architecture, "joint")
  expect_false(semantic_profiles$settings$local_responses_generated)
  expect_identical(semantic_profiles$metadata$n_generated, 0L)
  expect_true(all(vapply(
    semantic_profiles$groups,
    function(group) is.null(group$response) &&
      identical(group$status, "joint_response_not_stored"),
    logical(1)
  )))
})
