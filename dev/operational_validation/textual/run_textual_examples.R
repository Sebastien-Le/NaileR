#!/usr/bin/env Rscript

# Offline operational previews for the historical and Distinction TEXTUAL cases.
# Set NAILER_REPO when running from a source checkout and TEXTUAL_OUTPUT_DIR to
# save complete prompts, evidence and result objects. No LLM call is made.

repo <- Sys.getenv("NAILER_REPO", unset = getwd())
if (file.exists(file.path(repo, "DESCRIPTION"))) {
  if (!requireNamespace("devtools", quietly = TRUE)) {
    stop("Install devtools or run this script with an installed NaileR.")
  }
  devtools::load_all(repo, quiet = TRUE)
}
if (!requireNamespace("NaileR", quietly = TRUE)) {
  stop("NaileR is not available. Set NAILER_REPO or install NaileR first.")
}

output_dir <- Sys.getenv("TEXTUAL_OUTPUT_DIR", unset = "")
if (nzchar(output_dir)) {
  dir.create(output_dir, recursive = TRUE, showWarnings = FALSE)
}

safe_name <- function(x) {
  x <- gsub("[^A-Za-z0-9]+", "_", x)
  x <- gsub("(^_|_$)", "", x)
  if (!nzchar(x)) "group" else x
}

run_preview <- function(label, dataset, num.var, num.text,
                        introduction, request, isolate.groups,
                        sample.pct = 1, seed = NULL, text_role = "responses",
                        expected_groups = NULL) {
  result <- NaileR::nail_textual(
    dataset = dataset,
    num.var = num.var,
    num.text = num.text,
    introduction = introduction,
    request = request,
    isolate.groups = isolate.groups,
    sample.pct = sample.pct,
    seed = seed,
    text_role = text_role,
    generate = FALSE
  )
  evidence <- NaileR::nail_evidence(result)
  prompts <- NaileR::nail_prompt(result, print = FALSE)
  if (is.null(names(prompts))) {
    names(prompts) <- names(evidence$groups)[seq_along(prompts)]
  }
  stopifnot(length(prompts) == length(evidence$groups))
  if (!is.null(expected_groups)) {
    stopifnot(identical(names(evidence$groups), expected_groups))
  }

  interpretation_input <- attr(result, "interpretation_input", exact = TRUE)
  rows <- lapply(names(evidence$groups), function(group) {
    metrics <- evidence$groups[[group]]$metrics
    shown <- interpretation_input$groups[[group]]$metrics
    data.frame(
      case = label,
      group = group,
      group_rows = metrics$n_group_rows,
      available_texts = shown$n_available_texts,
      shown_texts = shown$n_shown_texts,
      response_rate = metrics$response_rate,
      interpretation_coverage = shown$interpretation_coverage,
      prompt_characters = nchar(prompts[[group]]),
      stringsAsFactors = FALSE,
      check.names = FALSE
    )
  })
  summary <- do.call(rbind, rows)

  if (nzchar(output_dir)) {
    saveRDS(result, file.path(output_dir, paste0(label, "_result.rds")))
    saveRDS(evidence, file.path(output_dir, paste0(label, "_evidence.rds")))
    utils::write.csv(
      summary,
      file.path(output_dir, paste0(label, "_summary.csv")),
      row.names = FALSE
    )
    for (group in names(prompts)) {
      writeLines(
        prompts[[group]],
        file.path(output_dir, paste0(label, "_prompt_", safe_name(group), ".txt")),
        useBytes = TRUE
      )
    }
  }

  summary
}

fabric_intro <- paste(
  "In this consumer study, fabric A was evaluated through open comments.",
  "Group 0 contains reasons for not appreciating the fabric and group 1",
  "contains reasons for appreciating it."
)
fabric_request <- paste(
  "Describe the reasons for disliking and liking fabric A from the comments",
  "shown for groups 0 and 1. Preserve the distinction between the groups and",
  "do not infer properties that respondents did not mention."
)
data(fabric, package = "NaileR")
fabric_A <- droplevels(fabric[fabric$Fabric == "A", , drop = FALSE])
fabric_summary <- run_preview(
  "fabric",
  fabric_A,
  num.var = 4,
  num.text = 3,
  introduction = fabric_intro,
  request = fabric_request,
  isolate.groups = FALSE,
  expected_groups = c("0", "1")
)

car_intro <- paste(
  "This survey records perceived benefits and constraints of using a car alone.",
  "The four groups combine declared car use with whether sharing is perceived",
  "as restrictive."
)
car_request <- paste(
  "Summarize what respondents literally express about the benefits and",
  "constraints of car use, preserving differences between the four groups",
  "without inferring behaviour."
)
data(car_alone, package = "NaileR")
car_summary <- run_preview(
  "car_alone",
  car_alone,
  num.var = 1,
  num.text = 2,
  introduction = car_intro,
  request = car_request,
  isolate.groups = TRUE,
  sample.pct = 0.5,
  seed = 20261027,
  text_role = "comments"
)

atomic_intro <- paste(
  "The survey asks respondents what benefits and constraints they associate",
  "with giving up air travel. The historical value 'THAT' is excluded because",
  "it is not a textual response."
)
atomic_request <- paste(
  "Describe the distinct ways in which the three constructed groups discuss",
  "reducing air travel. Keep perceived capacity distinct from felt constraint."
)
data(atomic_habit_clust, package = "NaileR")
atomic_plane <- atomic_habit_clust[
  !is.na(atomic_habit_clust$never_plane_text) &
    atomic_habit_clust$never_plane_text != "THAT",
  c(32, 51),
  drop = FALSE
]
stopifnot(
  nrow(atomic_plane) == 163L,
  identical(sort(unique(as.character(atomic_plane[[2]]))), c("1", "2", "3"))
)
atomic_summary <- run_preview(
  "atomic_habits",
  atomic_plane,
  num.var = 2,
  num.text = 1,
  introduction = atomic_intro,
  request = atomic_request,
  isolate.groups = TRUE,
  text_role = "responses",
  expected_groups = c("1", "2", "3")
)

rorschach_intro <- paste(
  "Participants described ten Rorschach inkblots in panel A.",
  "The prompts summarize the recorded descriptions without treating them as diagnoses."
)
rorschach_request <- paste(
  "Describe recurring perceptions associated with each inkblot, preserving",
  "variation and avoiding psychological or causal claims."
)
data(rorschach, package = "NaileR")
rorschach_A <- droplevels(rorschach[rorschach$Panel == "A", , drop = FALSE])
rorschach_summary <- run_preview(
  "rorschach_panel_A",
  rorschach_A,
  num.var = 2,
  num.text = 5,
  introduction = rorschach_intro,
  request = rorschach_request,
  isolate.groups = TRUE,
  text_role = "responses",
  expected_groups = as.character(1:10)
)

distinction_intro <- paste(
  "This survey includes one open question about what respondents mean by",
  "food quality. The English comments are translations of the original survey",
  "responses and are analysed as textual material, not as quantitative scores."
)
distinction_request <- paste(
  "Describe the diversity of representations of food quality in the complete",
  "corpus. Preserve tensions and minority views, and do not treat a sampled",
  "preview as an exhaustive account."
)
data(distinction, package = "NaileR")
distinction_text <- data.frame(
  respondent_scope = factor("All respondents"),
  quality_food_open = distinction$quality_food_open,
  check.names = FALSE
)
distinction_nonempty <- !is.na(distinction_text$quality_food_open) &
  nzchar(trimws(distinction_text$quality_food_open))
stopifnot(
  nrow(distinction) == 1226L,
  sum(distinction_nonempty) == 1225L,
  sum(is.na(distinction$quality_food_open)) == 1L
)
distinction_global_summary <- run_preview(
  "distinction_global",
  distinction_text,
  num.var = 1,
  num.text = 2,
  introduction = distinction_intro,
  request = distinction_request,
  isolate.groups = FALSE,
  sample.pct = 1,
  seed = 20261027,
  text_role = "comments",
  expected_groups = "All respondents"
)

distinction_education_intro <- paste(
  "The same food-quality question is compared descriptively across the",
  "six observed education categories in the survey."
)
distinction_education_request <- paste(
  "Summarize how the food-quality representations expressed in the comments",
  "vary across education categories. Do not infer education effects or causality."
)
distinction_education_summary <- run_preview(
  "distinction_highest_education",
  distinction,
  num.var = 4,
  num.text = 105,
  introduction = distinction_education_intro,
  request = distinction_education_request,
  isolate.groups = FALSE,
  sample.pct = 0.1,
  seed = 20261027,
  text_role = "comments",
  expected_groups = c(
    "Bac", "Bac +2", "Bachelor level or equivalent", "CAP / BEP",
    "Master level or higher", "No diploma"
  )
)

all_summaries <- rbind(
  fabric_summary,
  car_summary,
  atomic_summary,
  rorschach_summary,
  distinction_global_summary,
  distinction_education_summary
)
if (nzchar(output_dir)) {
  utils::write.csv(
    all_summaries,
    file.path(output_dir, "textual_examples_summary.csv"),
    row.names = FALSE
  )
}
print(all_summaries, row.names = FALSE)
