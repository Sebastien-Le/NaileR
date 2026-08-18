.make_catdes_prep_fixture <- function() {
  qualitative_a <- data.frame(
    "Cla/Mod" = c(72, 18, 61, 55, 54),
    "Mod/Cla" = c(65, 12, 40, 32, 31),
    "Global" = c(30, 44, 20, 18, 18),
    "p.value" = c(0.001, 0.004, 0.030, 0.020, 0.020),
    "v.test" = c(4, -3, 1.5, 2, 2),
    check.names = FALSE
  )
  rownames(qualitative_a) <- c(
    "Purchase place=Local market",
    "Purchase place=Supermarket",
    "Label::organic",
    "Var 1=Yes",
    "Var 2=Yes"
  )

  qualitative_special <- data.frame(
    "Cla/Mod" = c(66, 22),
    "Mod/Cla" = c(58, 10),
    "Global" = c(35, 28),
    "p.value" = c(0.002, 0.040),
    "v.test" = c(3.5, -1.8),
    check.names = FALSE
  )
  rownames(qualitative_special) <- c(
    "Lieu d'achat=March\u00e9 local",
    "Fr\u00e9quence::rare"
  )

  quantitative_a <- data.frame(
    "Mean in category" = c(7.2, 2.1, 4.0),
    "Overall mean" = c(5.0, 3.8, 4.0),
    "sd in category" = c(1.0, 0.9, 1.2),
    "Overall sd" = c(1.5, 1.4, 1.2),
    "p.value" = c(0.001, 0.002, 0.900),
    "v.test" = c(4.5, -4.0, 0),
    check.names = FALSE
  )
  rownames(quantitative_a) <- c(
    "Sustainability score",
    "Budget pressure",
    "Neutral variable"
  )

  quantitative_b <- data.frame(
    "Mean in category" = 6.5,
    "Overall mean" = 5.0,
    "sd in category" = 1.1,
    "Overall sd" = 1.5,
    "p.value" = 0.010,
    "v.test" = 2.7,
    check.names = FALSE
  )
  rownames(quantitative_b) <- "Exploration score"

  empty_quali <- data.frame(
    "Cla/Mod" = numeric(0),
    "Mod/Cla" = numeric(0),
    "Global" = numeric(0),
    "p.value" = numeric(0),
    "v.test" = numeric(0),
    check.names = FALSE
  )

  empty_quanti <- data.frame(
    "Mean in category" = numeric(0),
    "Overall mean" = numeric(0),
    "sd in category" = numeric(0),
    "Overall sd" = numeric(0),
    "p.value" = numeric(0),
    "v.test" = numeric(0),
    check.names = FALSE
  )

  group_special <- "Groupe sp\u00e9cial::\u00e9"
  category <- list(A = qualitative_a, Empty = empty_quali)
  category[[group_special]] <- qualitative_special

  list(
    category = category,
    quanti = list(
      A = quantitative_a,
      B = quantitative_b,
      Empty = empty_quanti
    )
  )
}

.expect_stable_qualitative_columns <- function(x) {
  expect_identical(
    names(x),
    c(
      "evidence_id", "group", "variable", "modality", "direction",
      "direction_basis", "observed", "expected", "percentage_in_group",
      "percentage_in_modality", "global_percentage", "v_test", "p_value",
      "abs_v_test", "rank", "source_row", "source"
    )
  )
}

.expect_stable_quantitative_columns <- function(x) {
  expect_identical(
    names(x),
    c(
      "evidence_id", "group", "variable", "direction", "direction_basis",
      "group_mean", "overall_mean", "standard_deviation",
      "overall_standard_deviation", "coefficient", "v_test", "p_value",
      "abs_v_test", "rank", "source_row", "source"
    )
  )
}

test_that("nail_catdes_prep builds the documented mechanical artifact", {
  source <- .make_catdes_prep_fixture()
  result <- nail_catdes_prep(source)

  expect_s3_class(result, "nail_catdes_prep")
  expect_s3_class(result, "statistical_profiles")
  expect_identical(
    names(result),
    c("groups", "evidence_registry", "settings", "metadata")
  )
  expect_identical(
    names(result$groups),
    c("A", "B", "Empty", "Groupe sp\u00e9cial::\u00e9")
  )
  expect_false(result$metadata$llm_used)
  expect_identical(result$metadata$schema, "NaileR::statistical_profiles")
  expect_true(is.data.frame(result$evidence_registry))
  expect_true(is.list(result$settings))
  expect_identical(attr(result, "catdes_result"), source)
  expect_true(is.list(attr(result, "catdes_profiles")))
})

test_that("qualitative markers preserve source values and signed directions", {
  result <- nail_catdes_prep(.make_catdes_prep_fixture())
  markers <- result$groups$A$qualitative_markers

  .expect_stable_qualitative_columns(markers)
  expect_equal(nrow(markers), 5L)

  local <- markers[markers$modality == "Local market", , drop = FALSE]
  supermarket <- markers[markers$modality == "Supermarket", , drop = FALSE]

  expect_identical(local$variable, "Purchase place")
  expect_identical(local$direction, "overrepresented")
  expect_identical(supermarket$direction, "underrepresented")
  expect_equal(local$percentage_in_group, 65)
  expect_equal(local$percentage_in_modality, 72)
  expect_equal(local$global_percentage, 30)
  expect_equal(local$v_test, 4)
  expect_equal(local$p_value, 0.001)
  expect_true(all(is.na(markers$observed)))
  expect_true(all(is.na(markers$expected)))
})

test_that("quantitative markers preserve means, dispersions, and directions", {
  result <- nail_catdes_prep(.make_catdes_prep_fixture())
  markers <- result$groups$A$quantitative_markers

  .expect_stable_quantitative_columns(markers)
  expect_equal(nrow(markers), 3L)

  sustainability <- markers[
    markers$variable == "Sustainability score",
    ,
    drop = FALSE
  ]
  budget <- markers[markers$variable == "Budget pressure", , drop = FALSE]
  neutral <- markers[markers$variable == "Neutral variable", , drop = FALSE]

  expect_identical(sustainability$direction, "higher")
  expect_identical(budget$direction, "lower")
  expect_identical(neutral$direction, "neutral")
  expect_equal(sustainability$group_mean, 7.2)
  expect_equal(sustainability$overall_mean, 5.0)
  expect_equal(sustainability$standard_deviation, 1.0)
  expect_equal(sustainability$overall_standard_deviation, 1.5)
  expect_true(is.na(sustainability$coefficient))
})

test_that("ranks are deterministic and preserve the historical absolute-v ordering", {
  result <- nail_catdes_prep(.make_catdes_prep_fixture())
  quali <- result$groups$A$qualitative_markers
  quanti <- result$groups$A$quantitative_markers

  expect_identical(quanti$variable, c(
    "Sustainability score",
    "Budget pressure",
    "Neutral variable"
  ))
  expect_identical(quanti$rank, 1:3)

  tied <- quali[quali$abs_v_test == 2, , drop = FALSE]
  expect_identical(tied$variable, c("Var 1", "Var 2"))
  expect_true(all(diff(quali$rank) == 1L))
})

test_that("evidence identifiers are unique, deterministic, and robust", {
  source <- .make_catdes_prep_fixture()
  first <- nail_catdes_prep(source)
  second <- nail_catdes_prep(source)
  registry <- first$evidence_registry

  expect_identical(first, second)
  expect_false(anyDuplicated(registry$evidence_id) > 0L)
  expect_identical(
    sort(unlist(lapply(first$groups, `[[`, "evidence_ids"), use.names = FALSE)),
    sort(registry$evidence_id)
  )
  expect_true(any(grepl("%3A%3A", registry$evidence_id, fixed = TRUE)))
  expect_true(any(grepl("Groupe sp\u00e9cial%3A%3A\u00e9", registry$evidence_id, fixed = TRUE)))
  expect_true(any(grepl("Purchase place::Local market", registry$evidence_id, fixed = TRUE)))
})

test_that("positive and negative views are derived from the main tables", {
  result <- nail_catdes_prep(.make_catdes_prep_fixture())
  group <- result$groups$A
  all_markers <- c(
    group$qualitative_markers$evidence_id,
    group$quantitative_markers$evidence_id
  )

  expect_true(all(group$positive_markers$evidence_id %in% all_markers))
  expect_true(all(group$negative_markers$evidence_id %in% all_markers))
  expect_true(all(group$positive_markers$direction %in% c("overrepresented", "higher")))
  expect_true(all(group$negative_markers$direction %in% c("underrepresented", "lower")))
  expect_setequal(
    group$positive_markers$evidence_id,
    c(
      group$qualitative_markers$evidence_id[
        group$qualitative_markers$direction == "overrepresented"
      ],
      group$quantitative_markers$evidence_id[
        group$quantitative_markers$direction == "higher"
      ]
    )
  )
})

test_that("group metrics are exact and empty groups remain explicit", {
  result <- nail_catdes_prep(.make_catdes_prep_fixture())
  metrics <- result$groups$A$metrics
  empty <- result$groups$Empty

  expect_identical(metrics$n_qualitative_markers, 5L)
  expect_identical(metrics$n_quantitative_markers, 3L)
  expect_identical(metrics$n_positive_markers, 5L)
  expect_identical(metrics$n_negative_markers, 2L)
  expect_identical(metrics$n_neutral_markers, 1L)
  expect_equal(metrics$min_p_value, 0.001)
  expect_equal(metrics$max_abs_v_test, 4.5)

  expect_equal(nrow(empty$qualitative_markers), 0L)
  expect_equal(nrow(empty$quantitative_markers), 0L)
  expect_identical(empty$metrics$n_positive_markers, 0L)
  expect_true(is.na(empty$metrics$min_p_value))
  expect_length(empty$evidence_ids, 0L)
})

test_that("groups present in only one catdes branch remain analyzable", {
  result <- nail_catdes_prep(.make_catdes_prep_fixture())

  expect_equal(nrow(result$groups$B$qualitative_markers), 0L)
  expect_equal(nrow(result$groups$B$quantitative_markers), 1L)
  expect_equal(nrow(result$groups[["Groupe sp\u00e9cial::\u00e9"]]$qualitative_markers), 2L)
  expect_equal(nrow(result$groups[["Groupe sp\u00e9cial::\u00e9"]]$quantitative_markers), 0L)
})

test_that("missing statistical fields are retained as NA and use valid fallbacks", {
  qualitative <- data.frame(
    "Mod/Cla" = c(70, 20),
    "Global" = c(40, 30),
    check.names = FALSE
  )
  rownames(qualitative) <- c("Choice=One", "Choice=Two")

  quantitative <- data.frame(
    "Mean in category" = c(8, 2),
    "Overall mean" = c(5, 5),
    check.names = FALSE
  )
  rownames(quantitative) <- c("High", "Low")

  result <- nail_catdes_prep(list(
    category = list(A = qualitative),
    quanti = list(A = quantitative)
  ))

  quali <- result$groups$A$qualitative_markers
  quanti <- result$groups$A$quantitative_markers

  expect_true(all(is.na(quali$v_test)))
  expect_true(all(is.na(quali$p_value)))
  expect_identical(quali$direction, c("overrepresented", "underrepresented"))
  expect_true(all(quali$direction_basis == "available_difference"))

  expect_true(all(is.na(quanti$v_test)))
  expect_true(all(is.na(quanti$p_value)))
  expect_identical(quanti$direction, c("higher", "lower"))
  expect_true(all(quanti$direction_basis == "available_difference"))
})

test_that("deprecated prompt, sampling, and LLM arguments do not alter evidence", {
  source <- .make_catdes_prep_fixture()
  baseline <- nail_catdes_prep(source)

  expect_warning(
    variant <- nail_catdes_prep(
      source,
      sample.pct = 0.1,
      top_n_quanti = 0,
      top_n_quali = 1,
      profile_mode = "categorical",
      prompt_style = "detailed",
      include_metrics_in_prompt = FALSE,
      introduction = "ignored",
      request = "ignored",
      conclusion = "ignored",
      model = "other-model",
      provider = "gemini",
      generate = TRUE,
      temperature = 0.9
    ),
    "entirely mechanical"
  )

  expect_identical(variant, baseline)
})

test_that("nail_catdes_prep never calls an LLM backend", {
  testthat::local_mocked_bindings(
    .call_llm_base = function(...) stop("LLM backend was called"),
    .package = "NaileR"
  )

  expect_warning(
    result <- nail_catdes_prep(
      .make_catdes_prep_fixture(),
      generate = TRUE,
      provider = "ollama"
    ),
    "entirely mechanical"
  )

  expect_s3_class(result, "statistical_profiles")
})

test_that("objects returned by nail_catdes are accepted through their attribute", {
  raw <- .make_catdes_prep_fixture()
  nail_result <- list(A = "prompt A")
  attr(nail_result, "catdes_result") <- raw

  from_raw <- nail_catdes_prep(raw)
  from_nail <- nail_catdes_prep(nail_result)

  expect_identical(from_nail, from_raw)
})

test_that("existing statistical profiles are returned unchanged", {
  result <- nail_catdes_prep(.make_catdes_prep_fixture())
  expect_identical(nail_catdes_prep(result), result)
})

test_that("the contextualized compatibility bridge is factual and mechanical", {
  result <- nail_catdes_prep(.make_catdes_prep_fixture())
  summaries <- NaileR:::.extract_group_profile_parsed(result)

  expect_identical(names(summaries), names(result$groups))
  expect_true(all(c(
    "core_group_profile",
    "quantitative_traits",
    "categorical_traits",
    "distinctive_markers",
    "statistical_caution",
    "injectable_summary"
  ) %in% names(summaries$A)))
  expect_false("profile_strength" %in% names(summaries$A))
  expect_match(summaries$A$core_group_profile, "retained qualitative marker")
})

test_that("nail_textual_contextualized accepts the mechanical profiles", {
  profiles <- nail_catdes_prep(.make_catdes_prep_fixture())
  textual <- list(
    A = list(
      parsed = list(
        core_textual_profile = "Text profile A",
        main_themes = "Theme A",
        dominant_concerns = "Concern A",
        tone_or_stance = "pragmatic",
        intra_group_consistency = "mixed",
        injectable_summary = "Text summary A",
        central_verbatim_cues = character(),
        tension_verbatim_cues = character()
      ),
      selected_verbatims = NULL
    ),
    B = list(
      parsed = list(
        core_textual_profile = "Text profile B",
        main_themes = "Theme B",
        dominant_concerns = "Concern B",
        tone_or_stance = "reserved",
        intra_group_consistency = "mixed",
        injectable_summary = "Text summary B",
        central_verbatim_cues = character(),
        tension_verbatim_cues = character()
      ),
      selected_verbatims = NULL
    )
  )

  result <- nail_textual_contextualized(
    group_profile_prep = profiles,
    textual_prep = textual,
    comparison_mode = "isolated",
    generate = FALSE
  )

  expect_s3_class(result, "nail_textual_contextualized")
  expect_setequal(names(result$units), names(profiles$groups))
  expect_true(all(vapply(result$units, function(x) is.character(x$prompt), logical(1))))
  expect_identical(result$units$A$prompt_contract, "compatibility_preview")
  expect_false(result$units$A$integration_eligible)
  expect_false(result$units$A$prompt_generation_eligible)
  expect_match(result$units$A$prompt, "STATISTICAL EVIDENCE")
  expect_match(result$units$A$prompt, "retained qualitative marker")
  expect_false(grepl("Profile strength", result$units$A$prompt, fixed = TRUE))
})

test_that("invalid and empty source objects fail explicitly", {
  expect_error(nail_catdes_prep(list()), "must be a raw")
  expect_error(
    nail_catdes_prep(list(category = list(), quanti = list())),
    "No named group"
  )
  expect_error(nail_catdes_prep(), "exactly one")
  expect_error(
    nail_catdes_prep(.make_catdes_prep_fixture(), dataset = data.frame(a = 1, b = 2)),
    "exactly one"
  )

  malformed_table <- data.frame(p.value = 0.01, v.test = 2)
  expect_error(
    nail_catdes_prep(list(category = malformed_table)),
    "named list of group tables"
  )

  duplicated_groups <- structure(
    list(malformed_table, malformed_table),
    names = c("A", "A")
  )
  expect_error(
    nail_catdes_prep(list(category = duplicated_groups)),
    "duplicated group names"
  )
})

test_that("nail_catdes reuses the validated mechanical profiles unchanged", {
  profiles <- nail_catdes_prep(.make_catdes_prep_fixture())

  result <- nail_catdes(
    x = profiles,
    isolate.groups = TRUE,
    quali.sample = 0.5,
    quanti.sample = 0.5,
    drop.negative = TRUE,
    generate = FALSE
  )

  expect_identical(attr(result, "statistical_profiles"), profiles)
  expect_s3_class(
    attr(result, "interpretation_evidence"),
    "nail_catdes_interpretation_evidence"
  )
  expect_true(all(
    profiles$evidence_registry$evidence_id %in%
      attr(result, "statistical_profiles")$evidence_registry$evidence_id
  ))
})

test_that("num.var is canonically stored as an integer", {
  catdes_result <- FactoMineR::catdes(
    iris,
    num.var = 5,
    proba = 0.05
  )

  catdes_double <- catdes_result
  catdes_double$call$num.var <- 5

  catdes_integer <- catdes_result
  catdes_integer$call$num.var <- 5L

  profiles_double <- nail_catdes_prep(
    x = catdes_double
  )

  profiles_integer <- nail_catdes_prep(
    x = catdes_integer
  )

  expect_identical(
    attr(profiles_double, "catdes_result")$call$num.var,
    5L
  )

  expect_identical(
    attr(profiles_integer, "catdes_result")$call$num.var,
    5L
  )

  expect_identical(
    profiles_double,
    profiles_integer
  )
})
