.catdes_ground_empty_quanti <- function() {
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

.catdes_ground_profiles <- function() {
  quali_a <- data.frame(
    "Cla/Mod" = c(80, 20),
    "Mod/Cla" = c(75, 18),
    Global = c(45, 55),
    "p.value" = c(1e-6, 1e-5),
    "v.test" = c(10, -9),
    check.names = FALSE,
    row.names = c("binary_choice=yes", "binary_choice=no")
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
    quanti = list(A = quanti_a, B = .catdes_ground_empty_quanti())
  )

  nail_catdes_prep(x = source)
}

.catdes_ground_pass1 <- function(isolate.groups = TRUE) {
  profiles <- .catdes_ground_profiles()

  testthat::local_mocked_bindings(
    .call_llm_base = function(provider, model, prompt, output, llm_api_options) {
      group <- if (grepl('Category "A"', prompt, fixed = TRUE)) "A" else "B"
      response <- if (identical(group, "A")) {
        paste(
          "Category A has a higher score and more yes responses.",
          "This suggests a more engaged profile.",
          "They may also be experts."
        )
      } else {
        "Category B is characterized by more yes responses."
      }
      data.frame(
        model = model,
        created_at = as.POSIXct("2026-08-19", tz = "UTC"),
        response = response,
        done = TRUE,
        prompt = prompt,
        stringsAsFactors = FALSE
      )
    },
    .package = "NaileR"
  )

  nail_catdes(
    x = profiles,
    isolate.groups = isolate.groups,
    generate = TRUE
  )
}

.catdes_ground_json_for_a <- function(allowed_ids) {
  jsonlite::toJSON(
    list(assertions = list(
      list(
        text = "Category A has a higher score.",
        epistemic_level = "fact",
        grounding_status = "supported",
        support_type = "direct",
        supporting_evidence_ids = list(allowed_ids[[3L]]),
        contradicting_evidence_ids = list(),
        rationale = "The quantitative evidence directly reports a higher group mean."
      ),
      list(
        text = "Category A shows a more engaged profile.",
        epistemic_level = "interpretation",
        grounding_status = "supported",
        support_type = "indirect",
        supporting_evidence_ids = as.list(allowed_ids[c(1L, 3L)]),
        contradicting_evidence_ids = list(),
        rationale = "The interpretation combines more yes responses with the higher score."
      ),
      list(
        text = "Category A may contain more experts.",
        epistemic_level = "hypothesis",
        grounding_status = "insufficient",
        support_type = "indirect",
        supporting_evidence_ids = list(allowed_ids[[1L]]),
        contradicting_evidence_ids = list(),
        rationale = paste(
          "The displayed behavior is relevant to the hypothesis,",
          "but expertise was not directly measured."
        )
      )
    )),
    auto_unbox = TRUE
  )
}

.catdes_ground_json_for_b <- function(allowed_ids) {
  jsonlite::toJSON(
    list(assertions = list(
      list(
        text = "Category B is characterized by more yes responses.",
        epistemic_level = "fact",
        grounding_status = "supported",
        support_type = "direct",
        supporting_evidence_ids = list(allowed_ids[[1L]]),
        contradicting_evidence_ids = list(),
        rationale = "The local qualitative evidence directly supports this statement."
      )
    )),
    auto_unbox = TRUE
  )
}

test_that("nail_catdes_ground requires PASS 1 artifacts", {
  expect_error(
    nail_catdes_ground(data.frame(x = 1)),
    "semantic_profiles",
    fixed = TRUE
  )
})

test_that("grounding preview is optional, local, and leaves PASS 1 unchanged", {
  pass1 <- .catdes_ground_pass1()
  before <- pass1

  ground <- nail_catdes_ground(pass1, generate = FALSE)

  expect_s3_class(ground, "nail_catdes_ground")
  expect_identical(pass1, before)
  expect_identical(ground$semantic_profiles, attr(pass1, "semantic_profiles"))
  expect_identical(ground$settings$llm_calls, 0L)
  expect_identical(ground$metadata$n_grounded_groups, 0L)
  expect_identical(ground$grounded_profiles$A$status, "prompt_ready")
  expect_identical(ground$grounded_profiles$B$status, "prompt_ready")

  prompt_a <- ground$grounding_prompts$A
  prompt_b <- ground$grounding_prompts$B
  expect_match(prompt_a, "Frozen PASS 1 Response", fixed = TRUE)
  expect_match(prompt_a, attr(pass1, "semantic_profiles")$groups$A$response, fixed = TRUE)
  expect_match(prompt_b, attr(pass1, "semantic_profiles")$groups$B$response, fixed = TRUE)
  expect_match(prompt_a, "A `supported` assertion MUST cite", fixed = TRUE)
  expect_match(
    prompt_a,
    "`supported` means that the listed local evidence is sufficient",
    fixed = TRUE
  )
  expect_match(
    prompt_a,
    "mere plausibility, compatibility, or thematic consistency is not enough",
    fixed = TRUE
  )
  expect_match(
    prompt_a,
    "A proxy behavior does not by itself establish an unmeasured motivation",
    fixed = TRUE
  )
  expect_match(
    prompt_a,
    "split the observation and the inference into separate assertions",
    fixed = TRUE
  )
  expect_match(
    prompt_a,
    "prefer `grounding_status = insufficient` while retaining the relevant evidence IDs",
    fixed = TRUE
  )

  ids_a <- attr(pass1, "semantic_facing_evidence")$groups$A$displayed_evidence$evidence_id
  ids_b <- attr(pass1, "semantic_facing_evidence")$groups$B$displayed_evidence$evidence_id
  refs_a <- sprintf("G001E%03d", seq_along(ids_a))
  refs_b <- sprintf("G002E%03d", seq_along(ids_b))

  for (ref in refs_a) {
    expect_match(prompt_a, paste0("Evidence ref: ", ref), fixed = TRUE)
  }
  for (ref in refs_b) {
    expect_match(prompt_b, paste0("Evidence ref: ", ref), fixed = TRUE)
  }
  for (id in ids_a) expect_false(grepl(id, prompt_a, fixed = TRUE))
  for (id in ids_b) expect_false(grepl(id, prompt_b, fixed = TRUE))
  for (ref in refs_b) expect_false(grepl(ref, prompt_a, fixed = TRUE))
  for (ref in refs_a) expect_false(grepl(ref, prompt_b, fixed = TRUE))

  expect_identical(unname(ground$evidence_reference_maps$A), as.character(ids_a))
  expect_identical(names(ground$evidence_reference_maps$A), refs_a)
  expect_identical(unname(ground$evidence_reference_maps$B), as.character(ids_b))
  expect_identical(names(ground$evidence_reference_maps$B), refs_b)
})

test_that("grounding assigns deterministic assertion ids and epistemic temperatures", {
  pass1 <- .catdes_ground_pass1()
  semantic <- attr(pass1, "semantic_facing_evidence")
  calls <- 0L

  testthat::local_mocked_bindings(
    .call_llm_base = function(provider, model, prompt, output, llm_api_options) {
      calls <<- calls + 1L
      group <- if (grepl('Category: A', prompt, fixed = TRUE)) "A" else "B"
      ids <- semantic$groups[[group]]$displayed_evidence$evidence_id
      group_index <- if (identical(group, "A")) 1L else 2L
      refs <- sprintf("G%03dE%03d", group_index, seq_along(ids))
      response <- if (identical(group, "A")) {
        .catdes_ground_json_for_a(refs)
      } else {
        .catdes_ground_json_for_b(refs)
      }
      data.frame(
        model = model,
        created_at = as.POSIXct("2026-08-19", tz = "UTC"),
        response = response,
        done = TRUE,
        prompt = prompt,
        stringsAsFactors = FALSE
      )
    },
    .package = "NaileR"
  )

  ground <- nail_catdes_ground(pass1, generate = TRUE)

  expect_identical(calls, 2L)
  expect_identical(ground$settings$llm_calls, 2L)
  expect_identical(ground$metadata$n_grounded_groups, 2L)
  expect_identical(ground$grounded_profiles$A$status, "grounded")

  assertions <- ground$grounded_profiles$A$assertions
  expect_identical(
    vapply(assertions, `[[`, character(1), "assertion_id"),
    c("assertion::A::001", "assertion::A::002", "assertion::A::003")
  )
  expect_identical(
    vapply(assertions, `[[`, integer(1), "epistemic_temperature"),
    c(0L, 2L, 3L)
  )
  expect_identical(assertions[[1L]]$grounding$status, "supported")
  expect_identical(assertions[[1L]]$grounding$normalization_notes, character(0))
  expect_identical(assertions[[3L]]$grounding$status, "insufficient")
  expect_identical(assertions[[3L]]$grounding$support_type, "indirect")
  expect_identical(
    assertions[[3L]]$grounding$supporting_evidence_ids,
    semantic$groups$A$displayed_evidence$evidence_id[[1L]]
  )
  expect_identical(
    ground$grounded_profiles$A$summary$grounding_counts$insufficient,
    1L
  )
})

test_that("PASS 1 raw responses are frozen through grounding", {
  pass1 <- .catdes_ground_pass1()
  semantic <- attr(pass1, "semantic_facing_evidence")
  raw_before <- attr(pass1, "semantic_profiles")$groups$A$response

  testthat::local_mocked_bindings(
    .call_llm_base = function(provider, model, prompt, output, llm_api_options) {
      group <- if (grepl('Category: A', prompt, fixed = TRUE)) "A" else "B"
      ids <- semantic$groups[[group]]$displayed_evidence$evidence_id
      response <- if (identical(group, "A")) {
        .catdes_ground_json_for_a(ids)
      } else {
        .catdes_ground_json_for_b(ids)
      }
      data.frame(
        model = model,
        created_at = Sys.time(),
        response = response,
        done = TRUE,
        prompt = prompt,
        stringsAsFactors = FALSE
      )
    },
    .package = "NaileR"
  )

  ground <- nail_catdes_ground(pass1, generate = TRUE)
  expect_identical(ground$grounded_profiles$A$raw_response, raw_before)
  expect_identical(ground$semantic_profiles$groups$A$response, raw_before)
})

test_that("grounding maps short local Evidence refs back to canonical Evidence IDs", {
  pass1 <- .catdes_ground_pass1()
  semantic <- attr(pass1, "semantic_facing_evidence")

  testthat::local_mocked_bindings(
    .call_llm_base = function(provider, model, prompt, output, llm_api_options) {
      group <- if (grepl('Category: A', prompt, fixed = TRUE)) "A" else "B"
      group_index <- if (identical(group, "A")) 1L else 2L
      wrapped <- paste0("[G", sprintf("%03d", group_index), "E001]")
      response <- jsonlite::toJSON(
        list(assertions = list(list(
          text = paste0("Category ", group, " has a directly supported local characteristic."),
          epistemic_level = "fact",
          grounding_status = "supported",
          support_type = "direct",
          supporting_evidence_ids = list(wrapped),
          contradicting_evidence_ids = list(),
          rationale = "The cited local evidence directly supports the assertion."
        ))),
        auto_unbox = TRUE
      )
      data.frame(
        model = model,
        created_at = Sys.time(),
        response = response,
        done = TRUE,
        prompt = prompt,
        stringsAsFactors = FALSE
      )
    },
    .package = "NaileR"
  )

  ground <- nail_catdes_ground(pass1, generate = TRUE)
  expect_identical(
    ground$grounded_profiles$A$assertions[[1L]]$grounding$supporting_evidence_ids,
    semantic$groups$A$displayed_evidence$evidence_id[[1L]]
  )
  expect_identical(
    ground$grounded_profiles$B$assertions[[1L]]$grounding$supporting_evidence_ids,
    semantic$groups$B$displayed_evidence$evidence_id[[1L]]
  )
})

test_that("grounding rejects Evidence IDs from another group", {
  pass1 <- .catdes_ground_pass1()
  semantic <- attr(pass1, "semantic_facing_evidence")
  foreign_ref <- "G002E001"

  testthat::local_mocked_bindings(
    .call_llm_base = function(provider, model, prompt, output, llm_api_options) {
      group <- if (grepl('Category: A', prompt, fixed = TRUE)) "A" else "B"
      ids <- semantic$groups[[group]]$displayed_evidence$evidence_id
      response <- if (identical(group, "A")) {
        jsonlite::toJSON(
          list(assertions = list(list(
            text = "Cross-group contamination.",
            epistemic_level = "fact",
            grounding_status = "supported",
            support_type = "direct",
            supporting_evidence_ids = list(paste0("[", foreign_ref, "]")),
            contradicting_evidence_ids = list(),
            rationale = "Invalid on purpose."
          ))),
          auto_unbox = TRUE
        )
      } else {
        .catdes_ground_json_for_b(ids)
      }
      data.frame(
        model = model,
        created_at = Sys.time(),
        response = response,
        done = TRUE,
        prompt = prompt,
        stringsAsFactors = FALSE
      )
    },
    .package = "NaileR"
  )

  expect_error(
    nail_catdes_ground(pass1, generate = TRUE),
    "outside that group's local evidence",
    fixed = TRUE
  )
})

test_that("a PASS 1 preview without generated profiles cannot be grounded", {
  profiles <- .catdes_ground_profiles()
  pass1_preview <- nail_catdes(
    x = profiles,
    isolate.groups = TRUE,
    generate = FALSE
  )

  ground <- nail_catdes_ground(pass1_preview, generate = FALSE)
  expect_identical(
    ground$grounded_profiles$A$status,
    "not_grounded_no_generated_profile"
  )
  expect_null(ground$grounding_prompts$A)
  expect_identical(ground$metadata$n_eligible_groups, 0L)
})


test_that("incomplete grounded statuses are conservatively downgraded instead of aborting", {
  pass1 <- .catdes_ground_pass1()
  semantic <- attr(pass1, "semantic_facing_evidence")

  testthat::local_mocked_bindings(
    .call_llm_base = function(provider, model, prompt, output, llm_api_options) {
      group <- if (grepl('Category: A', prompt, fixed = TRUE)) "A" else "B"
      ids <- semantic$groups[[group]]$displayed_evidence$evidence_id

      response <- if (identical(group, "A")) {
        jsonlite::toJSON(
          list(assertions = list(
            list(
              text = "Supported without a cited support ID.",
              epistemic_level = "interpretation",
              grounding_status = "supported",
              support_type = "indirect",
              supporting_evidence_ids = list(),
              contradicting_evidence_ids = list(),
              rationale = "The model forgot to cite the evidence."
            ),
            list(
              text = "Contradicted without a cited contradiction ID.",
              epistemic_level = "fact",
              grounding_status = "contradicted",
              support_type = "none",
              supporting_evidence_ids = list(),
              contradicting_evidence_ids = list(),
              rationale = "The model forgot to cite the contradiction."
            ),
            list(
              text = "Mixed with only one evidence direction.",
              epistemic_level = "semantic_pattern",
              grounding_status = "mixed",
              support_type = "convergent",
              supporting_evidence_ids = list(ids[[1L]]),
              contradicting_evidence_ids = list(),
              rationale = "Only the supporting side was cited."
            )
          )),
          auto_unbox = TRUE
        )
      } else {
        .catdes_ground_json_for_b(ids)
      }

      data.frame(
        model = model,
        created_at = Sys.time(),
        response = response,
        done = TRUE,
        prompt = prompt,
        stringsAsFactors = FALSE
      )
    },
    .package = "NaileR"
  )

  ground <- nail_catdes_ground(pass1, generate = TRUE)
  assertions <- ground$grounded_profiles$A$assertions

  expect_identical(
    vapply(assertions, function(x) x$grounding$status, character(1)),
    rep("insufficient", 3L)
  )
  expect_identical(
    vapply(assertions, function(x) x$grounding$support_type, character(1)),
    c("none", "none", "convergent")
  )
  expect_true(all(vapply(
    assertions,
    function(x) length(x$grounding$normalization_notes) == 1L &&
      grepl("conservatively downgraded", x$grounding$normalization_notes, fixed = TRUE),
    logical(1)
  )))
  expect_identical(
    ground$grounded_profiles$A$summary$grounding_counts$insufficient,
    3L
  )
})

test_that("contradicted sentinel assertions retain local contradicting evidence", {
  pass1 <- .catdes_ground_pass1()
  semantic_profiles <- attr(pass1, "semantic_profiles")
  semantic_profiles$groups$A$response <- paste(
    "Category A has a lower score.",
    "Category A has fewer yes responses."
  )
  attr(pass1, "semantic_profiles") <- semantic_profiles

  semantic <- attr(pass1, "semantic_facing_evidence")
  ids_a <- semantic$groups$A$displayed_evidence$evidence_id

  testthat::local_mocked_bindings(
    .call_llm_base = function(provider, model, prompt, output, llm_api_options) {
      group <- if (grepl('Category: A', prompt, fixed = TRUE)) "A" else "B"
      ids <- semantic$groups[[group]]$displayed_evidence$evidence_id

      response <- if (identical(group, "A")) {
        jsonlite::toJSON(
          list(assertions = list(
            list(
              text = "Category A has a lower score.",
              epistemic_level = "fact",
              grounding_status = "contradicted",
              support_type = "none",
              supporting_evidence_ids = list(),
              contradicting_evidence_ids = list(ids_a[[3L]]),
              rationale = "The local quantitative evidence shows a higher, not lower, mean."
            ),
            list(
              text = "Category A has fewer yes responses.",
              epistemic_level = "fact",
              grounding_status = "contradicted",
              support_type = "none",
              supporting_evidence_ids = list(),
              contradicting_evidence_ids = list(ids_a[[1L]]),
              rationale = "The local qualitative evidence shows more, not fewer, yes responses."
            )
          )),
          auto_unbox = TRUE
        )
      } else {
        .catdes_ground_json_for_b(ids)
      }

      data.frame(
        model = model,
        created_at = Sys.time(),
        response = response,
        done = TRUE,
        prompt = prompt,
        stringsAsFactors = FALSE
      )
    },
    .package = "NaileR"
  )

  ground <- nail_catdes_ground(pass1, generate = TRUE)
  assertions <- ground$grounded_profiles$A$assertions

  expect_identical(
    vapply(assertions, function(x) x$grounding$status, character(1)),
    c("contradicted", "contradicted")
  )
  expect_identical(
    assertions[[1L]]$grounding$contradicting_evidence_ids,
    ids_a[[3L]]
  )
  expect_identical(
    assertions[[2L]]$grounding$contradicting_evidence_ids,
    ids_a[[1L]]
  )
  expect_identical(
    ground$grounded_profiles$A$summary$grounding_counts$contradicted,
    2L
  )
})

test_that("grounding rejects mutated long canonical IDs instead of fuzzy matching them", {
  pass1 <- .catdes_ground_pass1()
  semantic <- attr(pass1, "semantic_facing_evidence")
  canonical <- semantic$groups$A$displayed_evidence$evidence_id[[1L]]
  mutated <- paste0(canonical, ".mutated")

  testthat::local_mocked_bindings(
    .call_llm_base = function(provider, model, prompt, output, llm_api_options) {
      group <- if (grepl('Category: A', prompt, fixed = TRUE)) "A" else "B"
      ids <- semantic$groups[[group]]$displayed_evidence$evidence_id
      response <- if (identical(group, "A")) {
        jsonlite::toJSON(
          list(assertions = list(list(
            text = "Mutated ID sentinel.",
            epistemic_level = "fact",
            grounding_status = "supported",
            support_type = "direct",
            supporting_evidence_ids = list(mutated),
            contradicting_evidence_ids = list(),
            rationale = "Invalid on purpose."
          ))),
          auto_unbox = TRUE
        )
      } else {
        .catdes_ground_json_for_b(ids)
      }
      data.frame(
        model = model,
        created_at = Sys.time(),
        response = response,
        done = TRUE,
        prompt = prompt,
        stringsAsFactors = FALSE
      )
    },
    .package = "NaileR"
  )

  expect_error(
    nail_catdes_ground(pass1, generate = TRUE),
    "outside that group's local evidence",
    fixed = TRUE
  )
})

test_that("grounding records wall-clock and CPU timing without performance thresholds", {
  pass1 <- .catdes_ground_pass1()

  preview <- nail_catdes_ground(pass1, generate = FALSE)

  expect_named(
    preview$timing$total,
    c("elapsed_seconds", "user_cpu_seconds", "system_cpu_seconds")
  )
  for (value in preview$timing$total) {
    expect_true(is.numeric(value) && length(value) == 1L)
    expect_true(is.finite(value))
    expect_gte(value, 0)
  }
  expect_true(all(vapply(
    preview$timing$grounding_calls,
    is.null,
    logical(1)
  )))

  semantic <- attr(pass1, "semantic_facing_evidence")
  testthat::local_mocked_bindings(
    .call_llm_base = function(provider, model, prompt, output, llm_api_options) {
      group <- if (grepl('Category: A', prompt, fixed = TRUE)) "A" else "B"
      ids <- semantic$groups[[group]]$displayed_evidence$evidence_id
      response <- if (identical(group, "A")) {
        .catdes_ground_json_for_a(ids)
      } else {
        .catdes_ground_json_for_b(ids)
      }
      data.frame(
        model = model,
        created_at = Sys.time(),
        response = response,
        done = TRUE,
        prompt = prompt,
        stringsAsFactors = FALSE
      )
    },
    .package = "NaileR"
  )

  ground <- nail_catdes_ground(pass1, generate = TRUE)

  for (group in c("A", "B")) {
    timing <- ground$timing$grounding_calls[[group]]
    expect_named(timing, c("total", "backend", "parse_and_validate"))

    for (part in timing) {
      expect_named(
        part,
        c("elapsed_seconds", "user_cpu_seconds", "system_cpu_seconds")
      )
      for (value in part) {
        expect_true(is.numeric(value) && length(value) == 1L)
        expect_true(is.finite(value))
        expect_gte(value, 0)
      }
    }

    expect_identical(
      ground$grounded_profiles[[group]]$metadata$timing,
      timing
    )
  }

  expect_gte(
    ground$timing$total$elapsed_seconds,
    0
  )
})

