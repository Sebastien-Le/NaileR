test_that("historical Fabric preview preserves groups 0 and 1", {
  data(fabric, package = "NaileR")
  fabric_A <- droplevels(fabric[fabric$Fabric == "A", , drop = FALSE])
  result <- nail_textual(
    fabric_A,
    num.var = 4,
    num.text = 3,
    isolate.groups = FALSE,
    generate = FALSE
  )
  evidence <- nail_evidence(result)
  expect_identical(names(evidence$groups), c("0", "1"))
  expect_equal(evidence$metadata$n_rows, 57L)
  expect_length(nail_prompt(result, print = FALSE), 1L)
})

test_that("historical Car Alone preview uses all four observed groups", {
  data(car_alone, package = "NaileR")
  result <- nail_textual(
    car_alone,
    num.var = 1,
    num.text = 2,
    isolate.groups = TRUE,
    sample.pct = 0.5,
    seed = 20261027,
    generate = FALSE
  )
  evidence <- nail_evidence(result)
  expect_equal(nrow(car_alone), 158L)
  expect_length(evidence$groups, 4L)
  expect_true(all(vapply(evidence$groups, function(x) x$metrics$n_texts > 0L, logical(1))))
})

test_that("Atomic Habits preview excludes only the historical THAT value", {
  data(atomic_habit_clust, package = "NaileR")
  atomic_plane <- atomic_habit_clust[
    !is.na(atomic_habit_clust$never_plane_text) &
      atomic_habit_clust$never_plane_text != "THAT",
    c(32, 51),
    drop = FALSE
  ]
  result <- nail_textual(
    atomic_plane,
    num.var = 2,
    num.text = 1,
    isolate.groups = TRUE,
    generate = FALSE
  )
  expect_equal(nrow(atomic_plane), 163L)
  expect_false(any(atomic_plane[[1]] == "THAT"))
  expect_identical(names(nail_evidence(result)$groups), c("1", "2", "3"))
})

test_that("Rorschach panel A exposes ten local prompts", {
  data(rorschach, package = "NaileR")
  rorschach_A <- droplevels(rorschach[rorschach$Panel == "A", , drop = FALSE])
  result <- nail_textual(
    rorschach_A,
    num.var = 2,
    num.text = 5,
    isolate.groups = TRUE,
    generate = FALSE
  )
  expect_equal(nrow(rorschach_A), 200L)
  expect_length(nail_prompt(result, print = FALSE), 10L)
  expect_length(nail_evidence(result)$groups, 10L)
})

test_that("Distinction text previews retain the complete corpus and coverage", {
  data(distinction, package = "NaileR")
  nonempty <- !is.na(distinction$quality_food_open) &
    nzchar(trimws(distinction$quality_food_open))
  distinction_text <- data.frame(
    respondent_scope = factor("All respondents"),
    quality_food_open = distinction$quality_food_open,
    check.names = FALSE
  )
  global <- nail_textual(
    distinction_text,
    num.var = 1,
    num.text = 2,
    isolate.groups = FALSE,
    sample.pct = 1,
    seed = 20261027,
    generate = FALSE
  )
  global_evidence <- nail_evidence(global)
  input <- attr(global, "interpretation_input", exact = TRUE)
  expect_equal(nrow(distinction), 1226L)
  expect_equal(sum(nonempty), 1225L)
  expect_equal(sum(is.na(distinction$quality_food_open)), 1L)
  expect_identical(names(global_evidence$groups), "All respondents")
  expect_equal(input$groups[[1]]$metrics$n_available_texts, 1225L)
  expect_equal(input$groups[[1]]$metrics$n_shown_texts, 1225L)

  grouped <- nail_textual(
    distinction,
    num.var = 4,
    num.text = 105,
    isolate.groups = FALSE,
    sample.pct = 0.1,
    seed = 20261027,
    generate = FALSE
  )
  grouped_input <- attr(grouped, "interpretation_input", exact = TRUE)
  expect_identical(
    names(nail_evidence(grouped)$groups),
    c("Bac", "Bac +2", "Bachelor level or equivalent", "CAP / BEP",
      "Master level or higher", "No diploma")
  )
  expect_identical(
    unname(vapply(grouped_input$groups, function(x) x$metrics$n_shown_texts, integer(1))),
    c(20L, 20L, 37L, 5L, 37L, 3L)
  )
})
