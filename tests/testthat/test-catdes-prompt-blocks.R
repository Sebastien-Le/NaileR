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

# Independent frozen reference for the approved scientific blocks.  These
# strings intentionally do not call any production helper.
.catdes_approved_prompt_reference <- list(
  reading = paste(
    "The results come from `FactoMineR::catdes()`. Each qualitative finding compares the frequency of a response modality within a group with its frequency in the full analyzed sample.",
    "MORE FREQUENT indicates statistical overrepresentation; LESS FREQUENT indicates statistical underrepresentation. The full sample is the reference, not another group.",
    "Overrepresentation does not necessarily imply a majority within the group. Interpret each direction together with the reported group and full-sample percentages.",
    "Interpret each response modality according to its actual meaning, including negation and, when relevant, its position on an ordered scale. Do not infer the distribution of unreported modalities from a single displayed result.",
    "Each quantitative finding compares a variable's mean within a group with its mean in the full analyzed sample. HIGHER and LOWER indicate that the group mean is statistically higher or lower, respectively.",
    "Read each difference according to what the variable measures, its unit when known, and the meaning of high and low values. Do not assume that higher means better or lower means worse.",
    "If the variable's meaning, scale, or unit is unclear, do not invent it. Do not compare means of unrelated variables as if they were measured on the same scale.",
    "Base your analysis on the provided statistical evidence. Do not make assumptions about variables or modalities that are not shown.",
    sep = "\n"
  ),
  interpretation_standard = paste(
    "Interpret each group by considering its statistical characteristics jointly, rather than describing variables one by one. Identify meaningful patterns and distinctive configurations, and develop a substantive synthesis that reveals what emerges from their combination.",
    "Use the study context to connect characteristics conceptually, while grounding your interpretation in the provided evidence. Do not present these connections as statistically demonstrated relationships or causal mechanisms. Preserve important nuances and ambiguities, without forcing an artificial coherence.",
    "Each group corresponds to an observed category defined by a specific variable and one of its response modalities. All group members share this modality.",
    "Use the meaning of both the defining variable and its modality to guide the interpretation of the group's statistical characteristics. Explain how the displayed findings characterize this category, combining its known identity with the multidimensional profile emerging from the evidence.",
    "Preserve the original category name. You may develop a higher-level interpretation, but do not replace the observed category with an invented identity.",
    sep = "\n"
  ),
  interpretation_latent = paste(
    "Interpret each group by considering its statistical characteristics jointly, rather than describing variables one by one. Identify meaningful patterns and distinctive configurations, and develop a substantive synthesis that reveals what emerges from their combination.",
    "Use the study context to connect characteristics conceptually, while grounding your interpretation in the provided evidence. Do not present these connections as statistically demonstrated relationships or causal mechanisms. Preserve important nuances and ambiguities, without forcing an artificial coherence.",
    "Each group is a constructed group whose identifier does not define its substantive meaning. Interpret its combined statistical characteristics to identify what makes it distinctive.",
    "When supported by the evidence, propose a concise, meaningful name that captures the group's overall profile. Keep the original identifier alongside the proposed name.",
    "Do not force a label when the profile is too heterogeneous or insufficiently informative.",
    sep = "\n"
  ),
  local_task = "Interpret only the selected group using its displayed statistical evidence. Do not describe groups whose profiles have not been provided.",
  global_task = "Interpret each displayed group, then provide an overall synthesis of meaningful similarities, contrasts, and configurations across groups. Do not present descriptive contrasts as statistically demonstrated pairwise differences.",
  output = "Write a clear, substantive interpretation highlighting the central profile, its main supporting statistical characteristics, and important nuances or exceptions. Favor meaningful synthesis over repetitive numerical reporting."
)

test_that("CATDES blocks match the independent approved wording reference", {
  reference <- .catdes_approved_prompt_reference

  for (mode in c("standard", "latent")) {
    result <- .catdes_prompt_blocks_example(mode, isolate_groups = FALSE)
    blocks <- attr(result, "catdes_prompt_blocks", exact = TRUE)$portfolio

    expect_identical(blocks$reading, reference$reading)
    expect_identical(
      blocks$interpretation,
      reference[[paste0("interpretation_", mode)]]
    )
    expect_identical(blocks$output, reference$output)
    expect_true(startsWith(blocks$local_task, reference$global_task))
  }

  local <- .catdes_prompt_blocks_example("standard", isolate_groups = TRUE)
  local_blocks <- attr(local, "catdes_prompt_blocks", exact = TRUE)[[1L]]
  expect_true(startsWith(local_blocks$local_task, reference$local_task))
})

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
  expect_match(
    blocks$output,
    "Write a clear, substantive interpretation",
    fixed = TRUE
  )
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
    "# Data",
    "# Output"
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

test_that("CATDES reading follows the approved statistical semantics", {
  result <- .catdes_prompt_blocks_example("standard")
  group_name <- .catdes_prompt_blocks_group(result)
  reading <- attr(result, "catdes_prompt_blocks")[[group_name]]$reading

  expect_match(reading, "FactoMineR::catdes()", fixed = TRUE)
  expect_match(reading, "full analyzed sample", fixed = TRUE)
  expect_match(reading, "MORE FREQUENT", fixed = TRUE)
  expect_match(reading, "LESS FREQUENT", fixed = TRUE)
  expect_match(reading, "HIGHER", fixed = TRUE)
  expect_match(reading, "LOWER", fixed = TRUE)
  expect_match(reading, "group and full-sample percentages", fixed = TRUE)
  expect_match(reading, "including negation", fixed = TRUE)
  expect_match(reading, "ordered scale", fixed = TRUE)
  expect_match(reading, "unit when known", fixed = TRUE)
  expect_match(reading, "Do not compare means of unrelated variables", fixed = TRUE)
  expect_match(reading, "provided statistical evidence", fixed = TRUE)

  expect_false(grepl("hypothesis", reading, fixed = TRUE))
  expect_false(grepl("meaningful name", reading, fixed = TRUE))
})

test_that("CATDES latent keeps the same reading core with group vocabulary", {
  standard <- .catdes_prompt_blocks_example("standard")
  latent <- .catdes_prompt_blocks_example("latent")
  group_name <- .catdes_prompt_blocks_group(standard)
  standard_blocks <- attr(standard, "catdes_prompt_blocks")[[group_name]]
  latent_blocks <- attr(latent, "catdes_prompt_blocks")[[group_name]]

  expect_identical(standard_blocks$reading, latent_blocks$reading)
  expect_match(
    latent_blocks$interpretation,
    "constructed group whose identifier does not define its substantive meaning",
    fixed = TRUE
  )
  expect_match(
    latent_blocks$interpretation,
    "Keep the original identifier alongside the proposed name",
    fixed = TRUE
  )
  expect_match(
    latent_blocks$interpretation,
    "Do not force a label",
    fixed = TRUE
  )
  expect_match(latent_blocks$local_task, "constructed group", fixed = TRUE)
  expect_match(latent_blocks$local_task, "original identifier", fixed = TRUE)
})

test_that("CATDES interpretation and local task keep mode-specific epistemic rules", {
  standard <- .catdes_prompt_blocks_example("standard")
  latent <- .catdes_prompt_blocks_example("latent")
  group_name <- .catdes_prompt_blocks_group(standard)
  standard_blocks <- attr(standard, "catdes_prompt_blocks")[[group_name]]
  latent_blocks <- attr(latent, "catdes_prompt_blocks")[[group_name]]

  expect_match(
    standard_blocks$interpretation,
    "observed category defined by a specific variable",
    fixed = TRUE
  )
  expect_match(standard_blocks$interpretation, "Preserve the original category name", fixed = TRUE)
  expect_match(
    standard_blocks$interpretation,
    "invented identity",
    fixed = TRUE
  )
  expect_match(standard_blocks$local_task, "selected group", fixed = TRUE)
  expect_match(
    standard_blocks$local_task,
    "profiles have not been provided",
    fixed = TRUE
  )

  expect_match(latent_blocks$interpretation, "constructed group", fixed = TRUE)
  expect_match(latent_blocks$interpretation, "proposed name", fixed = TRUE)
  expect_match(latent_blocks$interpretation, "Do not force a label", fixed = TRUE)
  expect_match(
    latent_blocks$local_task,
    "constructed group identifier",
    fixed = TRUE
  )
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
  expect_match(
    result,
    "Do not present descriptive contrasts as statistically demonstrated pairwise differences.",
    fixed = TRUE
  )
  expect_match(result, "# Global Task", fixed = TRUE)
  expect_false(grepl("# Local Task", result, fixed = TRUE))
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

  expect_match(
    portfolio$reading,
    "response modality within a group",
    fixed = TRUE
  )
  expect_match(
    portfolio$local_task,
    "descriptive contrasts as statistically demonstrated pairwise differences",
    fixed = TRUE
  )
  expect_match(
    portfolio$interpretation,
    "identifier does not define its substantive meaning",
    fixed = TRUE
  )
  expect_match(
    portfolio$interpretation,
    "Keep the original identifier alongside the proposed name",
    fixed = TRUE
  )
  expect_false(grepl("observed category", portfolio$interpretation, fixed = TRUE))
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

  latent_requests <- unlist(lapply(c(FALSE, TRUE), function(isolate) {
    c(
      detailed = build_request_catdes("latent", isolate, "detailed"),
      compact = build_request_catdes("latent", isolate, "compact")
    )
  }), use.names = FALSE)
  expect_true(all(grepl(
    "If ", latent_requests, fixed = TRUE
  )))
  expect_true(all(grepl(
    "sufficiently coherent and informative", latent_requests, fixed = TRUE
  )))
  expect_true(all(grepl(
    "retain its original identifier", latent_requests, fixed = TRUE
  )))
  expect_false(any(grepl(
    "Then propose a meaningful name", latent_requests, fixed = TRUE
  )))
  expect_false(any(grepl(
    "Then infer a meaningful name", latent_requests, fixed = TRUE
  )))
  expect_false(any(grepl(
    "Then, based on these characteristics, propose", latent_requests,
    fixed = TRUE
  )))
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

test_that("CATDES default blocks are the blocks used by all four routes", {
  data(atomic_habit, package = "NaileR")
  data(atomic_habit_clust, package = "NaileR")

  cases <- list(
    standard_local = list(
      data = atomic_habit,
      num.var = 2,
      mode = "standard",
      isolate = TRUE
    ),
    standard_global = list(
      data = atomic_habit,
      num.var = 2,
      mode = "standard",
      isolate = FALSE
    ),
    latent_local = list(
      data = atomic_habit_clust,
      num.var = 21,
      mode = "latent",
      isolate = TRUE
    ),
    latent_global = list(
      data = atomic_habit_clust,
      num.var = 21,
      mode = "latent",
      isolate = FALSE
    )
  )

  for (case in cases) {
    result <- nail_catdes(
      dataset = case$data,
      num.var = case$num.var,
      interpretation_mode = case$mode,
      isolate.groups = case$isolate,
      generate = FALSE
    )
    blocks <- attr(result, "catdes_prompt_blocks", exact = TRUE)[[1L]]
    defaults <- nail_catdes_default_blocks(
      interpretation_mode = case$mode,
      isolate.groups = case$isolate
    )

    expect_identical(blocks[c("reading", "interpretation", "output")], defaults)
    expect_true(
      grepl(
        if (case$isolate) "# Local Task" else "# Global Task",
        if (case$isolate) result[[1L]] else result,
        fixed = TRUE
      )
    )
    expect_match(
      if (case$isolate) result[[1L]] else result,
      "# Output",
      fixed = TRUE
    )
  }
})

test_that("CATDES prompt overrides replace only the requested blocks", {
  data(atomic_habit, package = "NaileR")
  base <- nail_catdes(
    dataset = atomic_habit,
    num.var = 2,
    isolate.groups = TRUE,
    generate = FALSE
  )
  custom <- nail_catdes(
    dataset = atomic_habit,
    num.var = 2,
    isolate.groups = TRUE,
    prompt_overrides = list(
      reading = "CUSTOM READING SENTINEL",
      output = "CUSTOM OUTPUT SENTINEL"
    ),
    generate = FALSE
  )

  group_name <- names(custom)[1L]
  base_blocks <- attr(base, "catdes_prompt_blocks", exact = TRUE)[[group_name]]
  custom_blocks <- attr(custom, "catdes_prompt_blocks", exact = TRUE)[[group_name]]

  expect_identical(custom_blocks$reading, "CUSTOM READING SENTINEL")
  expect_identical(custom_blocks$output, "CUSTOM OUTPUT SENTINEL")
  expect_identical(
    custom_blocks$interpretation,
    base_blocks$interpretation
  )
  expect_identical(custom_blocks$local_task, base_blocks$local_task)
  expect_identical(custom_blocks$evidence, base_blocks$evidence)
  expect_match(custom[[group_name]], "CUSTOM READING SENTINEL", fixed = TRUE)
  expect_match(custom[[group_name]], "CUSTOM OUTPUT SENTINEL", fixed = TRUE)

  for (artifact in c(
    "statistical_profiles",
    "interpretation_evidence",
    "semantic_facing_evidence"
  )) {
    expect_identical(
      attr(custom, artifact, exact = TRUE),
      attr(base, artifact, exact = TRUE)
    )
  }
  expect_identical(nail_evidence(custom), nail_evidence(base))
})

test_that("CATDES interpretation overrides are full replacements in all routes", {
  data(atomic_habit, package = "NaileR")
  data(atomic_habit_clust, package = "NaileR")

  cases <- list(
    standard_local = list(
      data = atomic_habit, num.var = 2,
      interpretation_mode = "standard", isolate.groups = TRUE
    ),
    standard_global = list(
      data = atomic_habit, num.var = 2,
      interpretation_mode = "standard", isolate.groups = FALSE
    ),
    latent_local = list(
      data = atomic_habit_clust, num.var = 21,
      interpretation_mode = "latent", isolate.groups = TRUE
    ),
    latent_global = list(
      data = atomic_habit_clust, num.var = 21,
      interpretation_mode = "latent", isolate.groups = FALSE
    )
  )
  custom_text <- "CUSTOM INTERPRETATION OVERRIDE ONLY"

  for (case in cases) {
    base <- nail_catdes(
      dataset = case$data,
      num.var = case$num.var,
      interpretation_mode = case$interpretation_mode,
      isolate.groups = case$isolate.groups,
      generate = FALSE
    )
    custom <- nail_catdes(
      dataset = case$data,
      num.var = case$num.var,
      interpretation_mode = case$interpretation_mode,
      isolate.groups = case$isolate.groups,
      prompt_overrides = list(interpretation = custom_text),
      generate = FALSE
    )

    key <- if (case$isolate.groups) names(custom)[1L] else "portfolio"
    base_blocks <- attr(base, "catdes_prompt_blocks", exact = TRUE)[[key]]
    custom_blocks <- attr(custom, "catdes_prompt_blocks", exact = TRUE)[[key]]
    expect_identical(custom_blocks$interpretation, custom_text)
    expect_false(grepl(
      "Interpret each group by considering its statistical characteristics jointly",
      custom_blocks$interpretation,
      fixed = TRUE
    ))
    for (block in c("reading", "local_task", "evidence", "output")) {
      expect_identical(custom_blocks[[block]], base_blocks[[block]])
    }
    expect_true(all(grepl(
      custom_text,
      nail_prompt(custom, print = FALSE),
      fixed = TRUE
    )))

    if (case$interpretation_mode == "standard") {
      if (case$isolate.groups) {
        expect_match(custom_blocks$local_task, "observed category", fixed = TRUE)
        expect_match(custom_blocks$local_task, "Preserve its original name", fixed = TRUE)
      } else {
        expect_match(custom_blocks$local_task, "displayed observed categories", fixed = TRUE)
        expect_match(custom_blocks$local_task, "Preserve each category's original name", fixed = TRUE)
      }
    } else {
      if (case$isolate.groups) {
        expect_match(custom_blocks$local_task, "constructed group identifier", fixed = TRUE)
        expect_match(custom_blocks$local_task, "original identifier", fixed = TRUE)
      } else {
        expect_match(custom_blocks$local_task, "constructed group identifiers", fixed = TRUE)
        expect_match(custom_blocks$local_task, "Keep each original identifier", fixed = TRUE)
      }
    }

    for (artifact in c(
      "statistical_profiles", "interpretation_evidence",
      "semantic_facing_evidence"
    )) {
      expect_identical(
        attr(custom, artifact, exact = TRUE),
        attr(base, artifact, exact = TRUE)
      )
    }
    expect_identical(
      attr(custom, "statistical_profiles", exact = TRUE)$evidence_registry,
      attr(base, "statistical_profiles", exact = TRUE)$evidence_registry
    )
    expect_identical(nail_evidence(custom), nail_evidence(base))
  }
})

test_that("CATDES requests preserve explicit user text without rewriting", {
  data(atomic_habit_clust, package = "NaileR")
  user_request <- "USER REQUEST: explain this constructed group without naming it."

  for (isolate in c(TRUE, FALSE)) {
    result <- nail_catdes(
      dataset = atomic_habit_clust,
      num.var = 21,
      interpretation_mode = "latent",
      isolate.groups = isolate,
      request = user_request,
      generate = FALSE
    )
    key <- if (isolate) names(result)[1L] else "portfolio"
    blocks <- attr(result, "catdes_prompt_blocks", exact = TRUE)[[key]]
    expect_identical(blocks$question, user_request)
    expect_true(grepl(user_request, if (isolate) result[[key]] else result, fixed = TRUE))
  }
})

test_that("CATDES prompt override validation is explicit", {
  data(atomic_habit, package = "NaileR")
  call <- function(overrides) {
    nail_catdes(
      dataset = atomic_habit,
      num.var = 2,
      prompt_overrides = overrides,
      generate = FALSE
    )
  }

  expect_error(call("not a list"), "named list")
  expect_error(call(list(unknown = "x")), "Unknown")
  expect_error(call(list(reading = c("x", "y"))), "one non-empty")
  expect_error(call(list(reading = NA_character_)), "one non-empty")
  expect_error(call(list(reading = "   ")), "one non-empty")
  expect_error(
    call(list(reading = "x", reading = "y")),
    "duplicated"
  )
  expect_error(call(list()), "named list")
})

test_that("CATDES prompts preserve grouping variables, modalities, and latent identifiers", {
  data(atomic_habit, package = "NaileR")
  data(atomic_habit_clust, package = "NaileR")

  standard <- nail_catdes(
    dataset = atomic_habit,
    num.var = 2,
    isolate.groups = TRUE,
    generate = FALSE
  )
  standard_prompt <- standard[[1L]]
  expect_match(
    standard_prompt,
    "grouping variable 'never_plane_capable'",
    fixed = TRUE
  )
  expect_match(
    standard_prompt,
    paste0("response modality '", names(standard)[1L], "'"),
    fixed = TRUE
  )

  latent <- nail_catdes(
    dataset = atomic_habit_clust,
    num.var = 21,
    interpretation_mode = "latent",
    isolate.groups = TRUE,
    generate = FALSE
  )
  expect_match(
    latent[[1L]],
    paste0("constructed group identifier shown below is '", names(latent)[1L], "'"),
    fixed = TRUE
  )
})
