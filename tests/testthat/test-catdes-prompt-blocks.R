.catdes_prompt_blocks_example <- function(interpretation_mode = "standard") {
  data(atomic_habit, package = "NaileR")

  nail_catdes(
    dataset = atomic_habit,
    num.var = 2,
    interpretation_mode = interpretation_mode,
    isolate.groups = TRUE,
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
