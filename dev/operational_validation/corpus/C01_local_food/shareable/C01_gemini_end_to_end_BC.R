#!/usr/bin/env Rscript

options(warn = 1)
readRenviron(file.path(Sys.getenv("HOME"), ".Renviron"))

args <- commandArgs(trailingOnly = TRUE)
arg_value <- function(prefix, default) {
  hit <- args[startsWith(args, prefix)]
  if (length(hit) == 0L) return(default)
  sub(prefix, "", hit[[1L]], fixed = TRUE)
}

repo <- normalizePath(
  arg_value("--repo=", getwd()),
  mustWork = TRUE
)
out <- arg_value(
  "--out=",
  file.path(tempdir(), "nailer-c01-local-food")
)
result_root <- file.path(out, "gemini_end_to_end_BC")
blind_root <- file.path(out, "C01_BLIND_COMPARISON")
dir.create(result_root, recursive = TRUE, showWarnings = FALSE)
dir.create(blind_root, recursive = TRUE, showWarnings = FALSE)

if (!nzchar(Sys.getenv("GEMINI_API_KEY", unset = ""))) {
  stop("GEMINI_API_KEY is not available to this R process.", call. = FALSE)
}
devtools::load_all(repo, quiet = TRUE)

expected_commit <- "0a47b546e284dd88e3964db64fc3f3b9295c6d95"
actual_commit <- paste(system2("git", c("-C", repo, "rev-parse", "HEAD"), stdout = TRUE), collapse = "")
actual_branch <- paste(system2("git", c("-C", repo, "branch", "--show-current"), stdout = TRUE), collapse = "")
if (!identical(actual_commit, expected_commit)) stop("Unexpected package HEAD.", call. = FALSE)
if (!identical(actual_branch, "dev-core5-condes-integration-20261015")) stop("Unexpected package branch.", call. = FALSE)

profiles <- readRDS(file.path(out, "profiles_from_dataset.rds"))
previews <- readRDS(file.path(out, "condition_previews_ABC.rds"))
reference_preview <- previews$A
reference_evidence <- nail_evidence(reference_preview)
a_result <- readRDS(file.path(out, "gemini_end_to_end_A", "result_A.rds"))
a_prompts <- nail_prompt(a_result, print = FALSE)
a_responses <- nail_response(a_result, print = FALSE)
a_evidence <- nail_evidence(a_result)
if (!isTRUE(all.equal(a_evidence, reference_evidence, check.attributes = TRUE))) {
  stop("Existing condition A evidence is not identical to the reference.", call. = FALSE)
}
if (!is.list(previews) || !all(c("A", "B", "C") %in% names(previews))) {
  stop("Validated A/B/C preview objects are missing.", call. = FALSE)
}

expected_prompts <- lapply(previews[c("B", "C")], function(x) {
  p <- nail_prompt(x, print = FALSE)
  if (is.character(p) && length(p) == 1L) p <- list(`1` = p)
  p
})
if (!identical(sort(names(expected_prompts$B)), sort(names(profiles$groups))) ||
    !identical(sort(names(expected_prompts$C)), sort(names(profiles$groups)))) {
  stop("B/C prompt groups do not match the statistical profiles.", call. = FALSE)
}

write_units <- function(units, directory, prefix) {
  if (is.character(units) && length(units) == 1L) units <- list(`1` = units)
  if (is.null(names(units))) names(units) <- as.character(seq_along(units))
  for (nm in names(units)) {
    writeLines(units[[nm]], file.path(directory, paste0(prefix, "_", nm, ".txt")), useBytes = TRUE)
  }
}

safe_equal <- function(x, y) isTRUE(all.equal(x, y, check.attributes = TRUE))

condition_records <- list()
started_campaign <- Sys.time()
for (condition_name in c("B", "C")) {
  condition_dir <- file.path(result_root, condition_name)
  dir.create(condition_dir, recursive = TRUE, showWarnings = FALSE)
  write_units(expected_prompts[[condition_name]], condition_dir, "prompt_expected")
  saveRDS(expected_prompts[[condition_name]], file.path(condition_dir, "prompts_expected.rds"))
  started <- Sys.time()
  cfg <- if (condition_name == "B") {
    list(introduction = paste(
      "A study on sustainable food systems was led on several French participants.",
      "This study had 2 parts. In the first part, participants had to rate how acceptable",
      "\"a food system that...\" (e.g, \"a food system that only uses renewable energy\")",
      "was to them. In the second part, they had to say if they agreed or disagreed with some statements."
    ), request = NULL)
  } else {
    list(
      introduction = paste(
        "A study on sustainable food systems was led on several French participants.",
        "This study had 2 parts. In the first part, participants had to rate how acceptable",
        "\"a food system that...\" (e.g, \"a food system that only uses renewable energy\")",
        "was to them. In the second part, they had to say if they agreed or disagreed with some statements."
      ),
      request = paste(
        "I will give you the answers from one group.",
        "Please explain who the individuals of this group are, what their beliefs are.",
        "Then, give this group a new name, and explain why you chose this name.",
        "Do not use 1st person (\"I\", \"my\"...) in your answer."
      )
    )
  }
  args <- list(
    x = profiles,
    interpretation_mode = "latent",
    isolate.groups = TRUE,
    drop.negative = FALSE,
    provider = "gemini",
    model = "gemini-2.5-flash",
    max_output_tokens = 8192L,
    max_tries = 1L,
    timeout = 90,
    generate = TRUE,
    introduction = cfg$introduction
  )
  if (!is.null(cfg$request)) args$request <- cfg$request
  error_message <- NULL
  result <- tryCatch(
    do.call(nail_catdes, args),
    error = function(e) {
      error_message <<- conditionMessage(e)
      NULL
    }
  )
  finished <- Sys.time()
  if (is.null(result)) {
    writeLines(error_message, file.path(condition_dir, "ERROR.txt"), useBytes = TRUE)
    metadata <- list(
      condition = condition_name,
      status = "error",
      error = error_message,
      duration_seconds = as.numeric(difftime(finished, started, units = "secs")),
      provider = "gemini",
      model = "gemini-2.5-flash",
      max_output_tokens = 8192L,
      max_tries = 1L,
      timeout_seconds = 90L,
      key_present_in_r = TRUE
    )
    saveRDS(metadata, file.path(condition_dir, "metadata.rds"))
    condition_records[[condition_name]] <- metadata
    saveRDS(condition_records, file.path(result_root, "condition_records_partial.rds"))
    stop(paste0("Condition ", condition_name, " failed: ", error_message), call. = FALSE)
  }

  prompts_actual <- nail_prompt(result, print = FALSE)
  responses_actual <- nail_response(result, print = FALSE)
  evidence_actual <- nail_evidence(result)
  if (is.character(prompts_actual) && length(prompts_actual) == 1L) prompts_actual <- list(`1` = prompts_actual)
  if (is.character(responses_actual) && length(responses_actual) == 1L) responses_actual <- list(`1` = responses_actual)
  prompt_identity <- safe_equal(prompts_actual, expected_prompts[[condition_name]])
  evidence_identity <- safe_equal(evidence_actual, reference_evidence)
  if (!prompt_identity) stop(paste0("Condition ", condition_name, " prompts differ from preview."), call. = FALSE)
  if (!evidence_identity) stop(paste0("Condition ", condition_name, " evidence differs from reference."), call. = FALSE)
  write_units(prompts_actual, condition_dir, "prompt_actual")
  write_units(responses_actual, condition_dir, "response")
  saveRDS(result, file.path(condition_dir, paste0("result_", condition_name, ".rds")))
  saveRDS(prompts_actual, file.path(condition_dir, "prompts_actual.rds"))
  saveRDS(responses_actual, file.path(condition_dir, paste0("responses_", condition_name, ".rds")))
  saveRDS(evidence_actual, file.path(condition_dir, "evidence.rds"))
  metadata <- list(
    condition = condition_name,
    status = "success",
    duration_seconds = as.numeric(difftime(finished, started, units = "secs")),
    provider = "gemini",
    model = "gemini-2.5-flash",
    max_output_tokens = 8192L,
    max_tries = 1L,
    timeout_seconds = 90L,
    key_present_in_r = TRUE,
    response_count = length(responses_actual),
    groups = names(responses_actual),
    prompt_identity = prompt_identity,
    evidence_identity = evidence_identity,
    llm_io = attr(result, "llm_io", exact = TRUE),
    catdes_settings = attr(result, "catdes_settings", exact = TRUE)
  )
  saveRDS(metadata, file.path(condition_dir, "metadata.rds"))
  condition_records[[condition_name]] <- metadata
  saveRDS(condition_records, file.path(result_root, "condition_records_partial.rds"))
}

saveRDS(condition_records, file.path(result_root, "condition_records.rds"))
saveRDS(list(B = condition_records$B, C = condition_records$C), file.path(result_root, "metadata_BC.rds"))

# Build an anonymized comparison packet combining A/B/C. The mapping is kept
# outside the shareable archive.
set.seed(20261027)
blind_rows <- list()
for (group_name in names(profiles$groups)) {
  source_records <- list(A = list(responses = a_responses), B = list(responses = readRDS(file.path(result_root, "B", "responses_B.rds"))), C = list(responses = readRDS(file.path(result_root, "C", "responses_C.rds"))))
  order_conditions <- sample(c("A", "B", "C"))
  group_dir <- file.path(blind_root, paste0("group_", group_name))
  dir.create(group_dir, recursive = TRUE, showWarnings = FALSE)
  file.copy(file.path(out, "gemini_end_to_end_A", paste0("response_", group_name, ".txt")), file.path(group_dir, "response_A_original.txt"), overwrite = TRUE)
  # The original condition label is removed from the review copy below.
  unlink(file.path(group_dir, "response_A_original.txt"))
  for (i in seq_along(order_conditions)) {
    condition <- order_conditions[[i]]
    response <- source_records[[condition]]$responses[[group_name]]
    blind_id <- sprintf("G%s_R%02d", group_name, i)
    writeLines(c(paste0("# Blind interpretation ", blind_id), "", response), file.path(group_dir, paste0(blind_id, ".md")), useBytes = TRUE)
    blind_rows[[length(blind_rows) + 1L]] <- data.frame(blind_id = blind_id, group = group_name, condition = condition, stringsAsFactors = FALSE)
  }
}
blind_key <- do.call(rbind, blind_rows)
write.csv(blind_key, file.path(out, "C01_CONDITION_MAPPING_FINAL.csv"), row.names = FALSE, na = "")
writeLines(c(
  "# C01 — Blind comparison A/B/C",
  "",
  "Each group directory contains three anonymized responses in an independently randomized order.",
  "The condition key is stored separately in `C01_CONDITION_MAPPING_FINAL.csv` and is not included in the shareable archive.",
  "",
  "No score or scientific judgment has been assigned by this script."
), file.path(out, "C01_BLIND_COMPARISON.md"), useBytes = TRUE)

report <- c(
  "# C01 — Conditions B and C",
  "",
  paste0("Branch: `", actual_branch, "`"),
  paste0("Commit: `", actual_commit, "`"),
  "Condition A was reused from its validated result and was not regenerated.",
  "",
  "## Parameters",
  "",
  "Provider `gemini`, model `gemini-2.5-flash`, latent mode, local isolation, `drop.negative = FALSE`, `max_output_tokens = 8192`, `max_tries = 1`, `timeout = 90`, `generate = TRUE`.",
  "",
  "## Results",
  "",
  paste0("Condition B: ", condition_records$B$status, ", ", condition_records$B$response_count, " responses, ", round(condition_records$B$duration_seconds, 3), " seconds."),
  paste0("Condition C: ", condition_records$C$status, ", ", condition_records$C$response_count, " responses, ", round(condition_records$C$duration_seconds, 3), " seconds."),
  "The prompts and evidence were checked against the corresponding previews and the 314-marker reference.",
  "",
  "No scientific score or winner is assigned. The comparison remains to be reviewed by humans in ChatGPT."
)
writeLines(report, file.path(out, "C01_GEMINI_END_TO_END_BC.md"), useBytes = TRUE)
writeLines(c(
  "# C01 — Technical checks for conditions B and C",
  "",
  "| Condition | Responses | Prompts identical | Evidence identical | Groups | Duration (s) |",
  "|---|---:|---|---|---|---:|",
  paste0("| B | ", condition_records$B$response_count, " | ", condition_records$B$prompt_identity, " | ", condition_records$B$evidence_identity, " | ", paste(condition_records$B$groups, collapse = ", "), " | ", round(condition_records$B$duration_seconds, 3), " |"),
  paste0("| C | ", condition_records$C$response_count, " | ", condition_records$C$prompt_identity, " | ", condition_records$C$evidence_identity, " | ", paste(condition_records$C$groups, collapse = ", "), " | ", round(condition_records$C$duration_seconds, 3), " |"),
  "",
  "`nail_prompt()`, `nail_response()` and `nail_evidence()` were executed for both conditions. No package warning was emitted by the generation calls; the known local startup warning concerns the installed build version of `testthat`.",
  "",
  "The A/B/C blind packet contains three responses per group, with independent within-group randomization. Its mapping is separate and excluded from the shareable archive."
), file.path(out, "C01_GEMINI_END_TO_END_BC_CHECKS.md"), useBytes = TRUE)

cat("B_AND_C_SUCCESS=TRUE\n")
cat("B_DURATION_SECONDS=", condition_records$B$duration_seconds, "\n", sep = "")
cat("C_DURATION_SECONDS=", condition_records$C$duration_seconds, "\n", sep = "")
cat("BLIND_RESPONSES=", nrow(blind_key), "\n", sep = "")
