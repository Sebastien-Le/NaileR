test_that("modular contextualization derives relationships deterministically", {
  registry <- data.frame(
    evidence_id = c(
      "A::quanti::score",
      "A::verbatim::1",
      "B::quanti::score",
      "B::verbatim::1"
    ),
    evidence_type = c(
      "statistical_quantitative",
      "textual_verbatim",
      "statistical_quantitative",
      "textual_verbatim"
    ),
    group = c("A", "A", "B", "B"),
    original_text = c(
      NA,
      "A exact verbatim",
      NA,
      "B exact verbatim"
    ),
    included_in_prompt = c(
      NA,
      TRUE,
      NA,
      TRUE
    ),
    stringsAsFactors = FALSE
  )

  make_group <- function(group) {
    list(
      group = group,
      statistical_profile = list(
        factual_summary = paste("Profile", group),
        qualitative_markers = data.frame(),
        quantitative_markers = data.frame(
          evidence_id = paste0(group, "::quanti::score"),
          variable = "score",
          direction = "higher",
          group_mean = 8,
          overall_mean = 5,
          v_test = 3,
          p_value = 0.01,
          rank = 1L,
          stringsAsFactors = FALSE
        )
      ),
      textual_profile = list(
        core_textual_profile = list(
          text = paste("Text profile", group),
          status = "expert_interpretation",
          evidence_ids = paste0(group, "::verbatim::1"),
          validation_needed = NULL
        )
      ),
      statistical_evidence_ids =
        paste0(group, "::quanti::score"),
      textual_evidence_ids =
        paste0(group, "::verbatim::1"),
      integration_limits = character()
    )
  }

  evidence <- list(
    groups = list(
      A = make_group("A"),
      B = make_group("B")
    ),
    combined_evidence_registry = registry
  )

  claim <- function(
      text,
      stat = character(),
      textual = character()
  ) {
    list(
      text = text,
      status = "expert_interpretation",
      statistical_evidence_ids = as.list(stat),
      textual_evidence_ids = as.list(textual),
      validation_needed = NULL
    )
  }

  mock_call <- function(
      prompt,
      schema,
      provider,
      model,
      unit_type,
      unit_data
  ) {
    if (identical(unit_type, "group")) {
      group <- unit_data$group
      stat <- unit_data$allowed_statistical_evidence_ids[[1]]
      textual <- unit_data$allowed_textual_evidence_ids[[1]]

      return(
        jsonlite::toJSON(
          list(
            group = group,
            integrated_profile = claim(
              paste("Integrated", group),
              stat,
              textual
            ),
            convergences = list(
              claim(
                paste("Convergence", group),
                stat,
                textual
              )
            ),
            tensions = list(),
            statistical_only_findings = list(),
            textual_only_findings = list(),
            interpretation_limits = list(
              claim(
                paste("Methodological limit", group)
              )
            )
          ),
          auto_unbox = TRUE,
          null = "null"
        )
      )
    }

    stat <- unit_data$allowed_statistical_evidence_ids
    textual <- unit_data$allowed_textual_evidence_ids

    jsonlite::toJSON(
      list(
        shared_patterns = list(
          claim(
            "Shared pattern",
            stat,
            textual
          )
        ),
        major_group_contrasts = list(),
        different_relationships = list(),
        interpretation_limits = list(
          claim("Cross methodological limit")
        )
      ),
      auto_unbox = TRUE,
      null = "null"
    )
  }

  result <- nail_textual_contextualized_modular(
    x = evidence,
    provider = "gemini",
    generate = TRUE,
    .llm_call = mock_call
  )

  expect_s3_class(
    result,
    "nail_textual_contextualized_modular"
  )

  expect_identical(
    result$metadata$parse_status,
    "success"
  )

  expect_identical(
    result$core_analysis$
      groups$A$
      integrated_profile$
      relationship,
    "convergence"
  )

  expect_identical(
    result$core_analysis$
      groups$A$
      interpretation_limits[[1]]$
      relationship,
    "scope_limit"
  )

  expect_length(
    result$core_analysis$
      groups$A$
      interpretation_limits[[1]]$
      statistical_evidence_ids,
    0L
  )

  expect_length(
    result$core_analysis$
      groups$A$
      interpretation_limits[[1]]$
      textual_evidence_ids,
    0L
  )

  expect_identical(
    result$core_analysis$
      cross_group$
      shared_patterns[[1]]$
      relationship,
    "convergence"
  )

  expect_length(
    result$core_analysis$groups$A$tensions,
    0L
  )
})


test_that("legacy relationship values are normalized instead of rejected", {
  registry <- data.frame(
    evidence_id = c(
      "A::quanti::score",
      "A::verbatim::1",
      "B::quanti::score",
      "B::verbatim::1"
    ),
    evidence_type = c(
      "statistical_quantitative",
      "textual_verbatim",
      "statistical_quantitative",
      "textual_verbatim"
    ),
    group = c("A", "A", "B", "B"),
    original_text = c(
      NA,
      "A exact verbatim",
      NA,
      "B exact verbatim"
    ),
    included_in_prompt = c(
      NA,
      TRUE,
      NA,
      TRUE
    ),
    stringsAsFactors = FALSE
  )

  make_group <- function(group) {
    list(
      group = group,
      statistical_profile = list(
        factual_summary = paste("Profile", group),
        qualitative_markers = data.frame(),
        quantitative_markers = data.frame()
      ),
      textual_profile = list(),
      statistical_evidence_ids =
        paste0(group, "::quanti::score"),
      textual_evidence_ids =
        paste0(group, "::verbatim::1"),
      integration_limits = character()
    )
  }

  evidence <- list(
    groups = list(
      A = make_group("A"),
      B = make_group("B")
    ),
    combined_evidence_registry = registry
  )

  legacy_claim <- function(
      text,
      stat,
      textual,
      relationship
  ) {
    list(
      text = text,
      status = "expert_interpretation",
      statistical_evidence_ids = as.list(stat),
      textual_evidence_ids = as.list(textual),
      relationship = relationship,
      validation_needed = NULL
    )
  }

  mock_call <- function(
      prompt,
      schema,
      provider,
      model,
      unit_type,
      unit_data
  ) {
    if (identical(unit_type, "group")) {
      stat <- unit_data$allowed_statistical_evidence_ids[[1]]
      textual <- unit_data$allowed_textual_evidence_ids[[1]]

      return(
        jsonlite::toJSON(
          list(
            group = unit_data$group,
            integrated_profile = legacy_claim(
              "Integrated",
              stat,
              textual,
              "tension"
            ),
            convergences = list(),
            tensions = list(),
            statistical_only_findings = list(),
            textual_only_findings = list(),
            interpretation_limits = list()
          ),
          auto_unbox = TRUE,
          null = "null"
        )
      )
    }

    jsonlite::toJSON(
      list(
        shared_patterns = list(
          legacy_claim(
            "Shared",
            unit_data$allowed_statistical_evidence_ids,
            unit_data$allowed_textual_evidence_ids,
            "tension"
          )
        ),
        major_group_contrasts = list(),
        different_relationships = list(),
        interpretation_limits = list()
      ),
      auto_unbox = TRUE,
      null = "null"
    )
  }

  result <- nail_textual_contextualized_modular(
    x = evidence,
    provider = "ollama",
    generate = TRUE,
    .llm_call = mock_call
  )

  expect_identical(
    result$metadata$parse_status,
    "success"
  )

  expect_identical(
    result$core_analysis$
      groups$A$
      integrated_profile$
      relationship,
    "convergence"
  )

  expect_identical(
    result$core_analysis$
      cross_group$
      shared_patterns[[1]]$
      relationship,
    "convergence"
  )

  expect_gt(
    result$metadata$normalization_warning_count,
    0L
  )

  expect_match(
    paste(
      result$cross_group_unit$normalization_warnings,
      collapse = "\n"
    ),
    "normalized from `tension` to `convergence`"
  )
})


test_that("modular contextualization rejects unknown evidence", {
  registry <- data.frame(
    evidence_id = c(
      "A::quanti::score",
      "A::verbatim::1"
    ),
    evidence_type = c(
      "statistical_quantitative",
      "textual_verbatim"
    ),
    group = c("A", "A"),
    original_text = c(
      NA,
      "A exact verbatim"
    ),
    included_in_prompt = c(
      NA,
      TRUE
    ),
    stringsAsFactors = FALSE
  )

  evidence <- list(
    groups = list(
      A = list(
        group = "A",
        statistical_profile = list(
          factual_summary = "Profile A",
          qualitative_markers = data.frame(),
          quantitative_markers = data.frame()
        ),
        textual_profile = list(),
        statistical_evidence_ids =
          "A::quanti::score",
        textual_evidence_ids =
          "A::verbatim::1",
        integration_limits = character()
      )
    ),
    combined_evidence_registry = registry
  )

  bad_mock <- function(...) {
    jsonlite::toJSON(
      list(
        group = "A",
        integrated_profile = list(
          text = "Bad claim",
          status = "expert_interpretation",
          statistical_evidence_ids =
            list("A::quanti::unknown"),
          textual_evidence_ids =
            list("A::verbatim::1"),
          validation_needed = NULL
        ),
        convergences = list(),
        tensions = list(),
        statistical_only_findings = list(),
        textual_only_findings = list(),
        interpretation_limits = list()
      ),
      auto_unbox = TRUE,
      null = "null"
    )
  }

  result <- nail_textual_contextualized_modular(
    x = evidence,
    provider = "gemini",
    generate = TRUE,
    cross_group = FALSE,
    fail_fast = FALSE,
    .llm_call = bad_mock
  )

  expect_identical(
    result$metadata$parse_status,
    "error"
  )

  expect_match(
    result$group_units$A$parse_error,
    "unknown statistical IDs"
  )
})


test_that("repair recovers an earlier cross-group relationship failure", {
  registry <- data.frame(
    evidence_id = c(
      "A::quanti::score",
      "A::verbatim::1",
      "B::quanti::score",
      "B::verbatim::1"
    ),
    evidence_type = c(
      "statistical_quantitative",
      "textual_verbatim",
      "statistical_quantitative",
      "textual_verbatim"
    ),
    group = c("A", "A", "B", "B"),
    original_text = c(
      NA,
      "A exact verbatim",
      NA,
      "B exact verbatim"
    ),
    included_in_prompt = c(
      NA,
      TRUE,
      NA,
      TRUE
    ),
    stringsAsFactors = FALSE
  )

  make_group <- function(group) {
    list(
      group = group,
      statistical_profile = list(
        factual_summary = paste("Profile", group),
        qualitative_markers = data.frame(),
        quantitative_markers = data.frame()
      ),
      textual_profile = list(),
      statistical_evidence_ids =
        paste0(group, "::quanti::score"),
      textual_evidence_ids =
        paste0(group, "::verbatim::1"),
      integration_limits = character()
    )
  }

  evidence <- list(
    groups = list(
      A = make_group("A"),
      B = make_group("B")
    ),
    combined_evidence_registry = registry
  )

  base_claim <- function(group) {
    list(
      text = paste("Integrated", group),
      status = "expert_interpretation",
      statistical_evidence_ids =
        list(paste0(group, "::quanti::score")),
      textual_evidence_ids =
        list(paste0(group, "::verbatim::1")),
      validation_needed = NULL
    )
  }

  mock_call <- function(
      prompt,
      schema,
      provider,
      model,
      unit_type,
      unit_data
  ) {
    if (identical(unit_type, "group")) {
      return(
        jsonlite::toJSON(
          list(
            group = unit_data$group,
            integrated_profile =
              base_claim(unit_data$group),
            convergences = list(),
            tensions = list(),
            statistical_only_findings = list(),
            textual_only_findings = list(),
            interpretation_limits = list()
          ),
          auto_unbox = TRUE,
          null = "null"
        )
      )
    }

    jsonlite::toJSON(
      list(
        shared_patterns = list(
          list(
            text = "Shared",
            status = "expert_interpretation",
            statistical_evidence_ids = as.list(
              unit_data$allowed_statistical_evidence_ids
            ),
            textual_evidence_ids = as.list(
              unit_data$allowed_textual_evidence_ids
            ),
            relationship = "tension",
            validation_needed = NULL
          )
        ),
        major_group_contrasts = list(),
        different_relationships = list(),
        interpretation_limits = list()
      ),
      auto_unbox = TRUE,
      null = "null"
    )
  }

  result <- nail_textual_contextualized_modular(
    x = evidence,
    provider = "ollama",
    generate = TRUE,
    .llm_call = mock_call
  )

  # Recreate the state of the earlier prototype before deterministic
  # relationship normalization was introduced.
  result$cross_group_unit$parsed <- NULL
  result$cross_group_unit$parse_status <- "error"
  result$cross_group_unit$parse_error <-
    "legacy relationship mismatch"
  result$core_analysis$cross_group <- NULL
  result$core_analysis$metadata$
    cross_group_parse_status <- "error"
  result$metadata$parse_status <- "partial"

  repaired <-
    repair_nail_textual_contextualized_modular_result(
      result
    )

  expect_identical(
    repaired$cross_group_unit$parse_status,
    "success"
  )

  expect_identical(
    repaired$metadata$parse_status,
    "success"
  )

  expect_identical(
    repaired$core_analysis$
      cross_group$
      shared_patterns[[1]]$
      relationship,
    "convergence"
  )

  expect_true(
    repaired$metadata$repaired_without_llm_call
  )
})


test_that("source exclusivity issues are surfaced as audit warnings", {
  analysis <- list(
    integrated_profile = list(
      statistical_evidence_ids = "A::quanti::score",
      textual_evidence_ids = "A::verbatim::1"
    ),
    convergences = list(),
    tensions = list(
      list(
        text = "This could indicate a tension.",
        statistical_evidence_ids = "A::quanti::other",
        textual_evidence_ids = "A::verbatim::2"
      )
    ),
    statistical_only_findings = list(
      list(
        statistical_evidence_ids = "A::quanti::score",
        textual_evidence_ids = character()
      )
    ),
    textual_only_findings = list(
      list(
        statistical_evidence_ids = character(),
        textual_evidence_ids = "A::verbatim::1"
      )
    )
  )

  source_exclusivity_warnings <- getFromNamespace(
    ".nctx_source_exclusivity_warnings",
    "NaileR"
  )

  warnings <- source_exclusivity_warnings(
    analysis,
    "A"
  )

  expect_true(
    any(grepl("statistical-only", warnings))
  )
  expect_true(
    any(grepl("textual-only", warnings))
  )
  expect_true(
    any(grepl("speculative wording", warnings))
  )
})
