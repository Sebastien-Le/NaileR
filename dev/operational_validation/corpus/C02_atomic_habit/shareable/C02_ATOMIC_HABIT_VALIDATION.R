#!/usr/bin/env Rscript

# C02 -- atomic_habit_clust validation
# Offline only. This script does not call an LLM and does not modify NaileR.

options(stringsAsFactors = FALSE, warn = 1)

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
  file.path(tempdir(), "nailer-c02-atomic-habit")
)
dir.create(out, recursive = TRUE, showWarnings = FALSE)

if (!requireNamespace("devtools", quietly = TRUE)) {
  stop("The `devtools` package is required.", call. = FALSE)
}
devtools::load_all(repo, quiet = TRUE)

data(atomic_habit, package = "NaileR")
data(atomic_habit_clust, package = "NaileR")

stopifnot(
  identical(dim(atomic_habit), c(167L, 50L)),
  identical(dim(atomic_habit_clust), c(167L, 51L)),
  identical(names(atomic_habit), names(atomic_habit_clust)[seq_len(50L)]),
  identical(atomic_habit, atomic_habit_clust[, seq_len(50L), drop = FALSE]),
  identical(class(atomic_habit_clust$clust), "factor"),
  identical(levels(atomic_habit_clust$clust), c("1", "2", "3")),
  identical(as.integer(table(atomic_habit_clust$clust)), c(84L, 13L, 70L)),
  all(vapply(atomic_habit_clust, function(x) !anyNA(x), logical(1)))
)

family_checks <- list(
  capability = all(vapply(atomic_habit[, 1:10], is.factor, logical(1))),
  restrictive_scale = all(vapply(atomic_habit[, 11:20], is.numeric, logical(1))) &&
    all(vapply(atomic_habit[, 11:20], function(x) all(x >= 0 & x <= 5), logical(1))),
  restrictive_binary = all(vapply(atomic_habit[, 21:30], is.factor, logical(1))),
  text = all(vapply(atomic_habit[, 31:40], is.character, logical(1))) &&
    all(vapply(atomic_habit[, 31:40], function(x) any(nzchar(trimws(x))), logical(1))),
  composites = all(vapply(atomic_habit[, 41:50], is.factor, logical(1)), na.rm = TRUE),
  cluster = is.factor(atomic_habit_clust$clust)
)
stopifnot(all(unlist(family_checks)))

text_names <- names(atomic_habit)[31:40]
text_audit <- do.call(rbind, lapply(seq_along(text_names), function(j) {
  z <- atomic_habit[[30L + j]]
  data.frame(
    text_column = text_names[[j]],
    non_empty = sum(nzchar(trimws(z))),
    missing = sum(is.na(z)),
    unique_texts = length(unique(z)),
    median_characters = stats::median(nchar(z)),
    stringsAsFactors = FALSE
  )
}))
write.csv(text_audit, file.path(out, "text_audit.csv"), row.names = FALSE)

text_by_group <- do.call(rbind, lapply(seq_along(text_names), function(j) {
  z <- trimws(as.character(atomic_habit[[30L + j]]))
  data.frame(
    text_column = text_names[[j]],
    group = levels(atomic_habit_clust$clust),
    non_empty = vapply(levels(atomic_habit_clust$clust), function(g) {
      sum(nzchar(z) & atomic_habit_clust$clust == g)
    }, integer(1)),
    group_n = as.integer(table(atomic_habit_clust$clust)),
    stringsAsFactors = FALSE
  )
}))
write.csv(text_by_group, file.path(out, "text_audit_by_group.csv"), row.names = FALSE)

# Compare a small number of possible historical AFM/HCPC constructions. The
# labels in atomic_habit_clust are treated as the published reference; this
# comparison does not replace them with a newly reconstructed classification.
best_label_invariant_agreement <- function(reference, predicted) {
  reference <- as.character(reference)
  predicted <- as.character(predicted)
  ref_levels <- sort(unique(reference))
  pred_levels <- sort(unique(predicted))
  if (length(ref_levels) != 3L || length(pred_levels) != 3L) return(NA_real_)
  permutations <- rbind(
    c("1", "2", "3"), c("1", "3", "2"), c("2", "1", "3"),
    c("2", "3", "1"), c("3", "1", "2"), c("3", "2", "1")
  )
  max(vapply(seq_len(nrow(permutations)), function(i) {
    map <- setNames(permutations[i, ], pred_levels)
    mean(unname(map[predicted]) == reference)
  }, numeric(1)))
}

run_mfa_hcpc <- function(label, data, group, type, num.group.sup = NULL) {
  mfa <- FactoMineR::MFA(
    data,
    group = group,
    type = type,
    num.group.sup = num.group.sup,
    graph = FALSE
  )
  hcpc <- FactoMineR::HCPC(mfa, nb.clust = 3, graph = FALSE)
  predicted <- hcpc$data.clust$clust
  data.frame(
    construction = label,
    variables = ncol(data),
    groups = paste(group, collapse = "+"),
    types = paste(type, collapse = "+"),
    supplementary_group = if (is.null(num.group.sup)) "none" else as.character(num.group.sup),
    cluster_sizes = paste(as.integer(table(predicted)), collapse = "/"),
    exact_label_agreement = mean(as.character(predicted) == as.character(atomic_habit_clust$clust)),
    label_invariant_agreement = best_label_invariant_agreement(
      atomic_habit_clust$clust, predicted
    ),
    stringsAsFactors = FALSE
  )
}

mfa_checks <- rbind(
  run_mfa_hcpc(
    "documented_30_variables_with_group_3_supplementary",
    atomic_habit[, 1:30], c(10, 10, 10), c("n", "s", "n"), 3
  ),
  run_mfa_hcpc(
    "documented_20_first_variables",
    atomic_habit[, 1:20], c(10, 10), c("n", "s"), NULL
  )
)
stopifnot(
  all(mfa_checks$exact_label_agreement == 1),
  all(mfa_checks$label_invariant_agreement == 1)
)
write.csv(mfa_checks, file.path(out, "mfa_hcpc_reproduction.csv"), row.names = FALSE)

# The analysis table intentionally contains the 20 structured questionnaire
# variables and the published group only. Textual responses, binary copies,
# and derived composites are not treated as independent CATDES evidence.
analysis_data <- atomic_habit_clust[, c(seq_len(20L), 51L), drop = FALSE]
raw_catdes <- FactoMineR::catdes(analysis_data, num.var = 21L, proba = 0.05)
prepared <- nail_catdes_prep(x = raw_catdes, proba = 0.05)
stopifnot(
  inherits(prepared, "statistical_profiles"),
  identical(names(prepared$groups), c("1", "2", "3")),
  nrow(prepared$evidence_registry) > 0L
)

saveRDS(raw_catdes, file.path(out, "catdes_reference.rds"))
saveRDS(prepared, file.path(out, "catdes_prepared_profiles.rds"))

intro <- paste(
  "These data come from a survey of 167 people about everyday practices.",
  "Participants reported whether they felt able to adopt several practices",
  "and how restrictive they perceived them to be. The three groups are",
  "constructed profiles from an upstream classification; their labels are",
  "identifiers, not substantive names."
)
request <- paste(
  "Interpret the constructed groups from the displayed capability and",
  "perceived-restrictiveness evidence. Synthesize convergent findings,",
  "distinguish declared capability from perceived constraint, and do not",
  "turn intentions into observed behaviour or perceived constraints into",
  "demonstrated causes."
)

configs <- list(
  local_full = list(isolate.groups = TRUE, drop.negative = FALSE),
  local_drop_negative = list(isolate.groups = TRUE, drop.negative = TRUE),
  joint_full = list(isolate.groups = FALSE, drop.negative = FALSE),
  joint_drop_negative = list(isolate.groups = FALSE, drop.negative = TRUE)
)

preview_records <- list()
reference_profiles <- NULL
reference_evidence <- NULL
dir.create(file.path(out, "previews"), recursive = TRUE, showWarnings = FALSE)
dir.create(file.path(out, "evidence"), recursive = TRUE, showWarnings = FALSE)
for (config_name in names(configs)) {
  cfg <- configs[[config_name]]
  result <- nail_catdes(
    x = prepared,
    interpretation_mode = "latent",
    isolate.groups = cfg$isolate.groups,
    drop.negative = cfg$drop.negative,
    introduction = intro,
    request = request,
    provider = "ollama",
    model = "mistral-small3.2",
    generate = FALSE
  )
  prompts <- nail_prompt(result, print = FALSE)
  if (is.character(prompts) && length(prompts) == 1L) {
    prompts <- list(portfolio = prompts)
  }
  evidence <- nail_evidence(result)
  profiles <- attr(result, "statistical_profiles", exact = TRUE)
  if (is.null(reference_profiles)) reference_profiles <- profiles
  if (is.null(reference_evidence)) reference_evidence <- evidence
  stopifnot(
    is.list(prompts), length(prompts) >= 1L,
    all(vapply(prompts, function(x) is.character(x) && length(x) == 1L && nzchar(x), logical(1))),
    isTRUE(all.equal(profiles, reference_profiles, check.attributes = TRUE)),
    isTRUE(all.equal(evidence, reference_evidence, check.attributes = TRUE)),
    all(vapply(prompts, function(x) grepl("constructed profiles", x, fixed = TRUE), logical(1)))
  )
  if (cfg$isolate.groups) {
    stopifnot(identical(sort(names(prompts)), c("1", "2", "3")))
  } else {
    stopifnot(length(prompts) == 1L)
  }
  response_error <- tryCatch({
    nail_response(result, print = FALSE)
    NA_character_
  }, error = function(e) conditionMessage(e))
  stopifnot(is.character(response_error), grepl("No LLM response", response_error, fixed = TRUE))

  config_dir <- file.path(out, "prompts", config_name)
  dir.create(config_dir, recursive = TRUE, showWarnings = FALSE)
  for (nm in names(prompts)) {
    writeLines(prompts[[nm]], file.path(config_dir, paste0("group_", nm, ".txt")), useBytes = TRUE)
  }
  saveRDS(result, file.path(out, "previews", paste0(config_name, ".rds")))
  saveRDS(evidence, file.path(out, "evidence", paste0(config_name, ".rds")))
  preview_records[[config_name]] <- list(
    isolate_groups = cfg$isolate.groups,
    drop_negative = cfg$drop.negative,
    prompt_count = length(prompts),
    prompt_chars = vapply(prompts, nchar, integer(1)),
    response_without_generation = response_error,
    evidence_rows = nrow(evidence$evidence_registry),
    statistical_profiles_invariant = TRUE,
    evidence_invariant = TRUE
  )
}

evidence_registry <- reference_evidence$evidence_registry
write.csv(evidence_registry, file.path(out, "evidence_registry.csv"), row.names = FALSE)
saveRDS(reference_profiles, file.path(out, "statistical_profiles_canonical.rds"))
saveRDS(reference_evidence, file.path(out, "evidence_reference.rds"))
saveRDS(preview_records, file.path(out, "preview_records.rds"))
saveRDS(list(
  repo = repo,
  branch = paste(system2("git", c("-C", repo, "branch", "--show-current"), stdout = TRUE), collapse = ""),
  commit = paste(system2("git", c("-C", repo, "rev-parse", "HEAD"), stdout = TRUE), collapse = ""),
  dimensions = dim(atomic_habit_clust),
  group_sizes = as.integer(table(atomic_habit_clust$clust)),
  family_checks = family_checks,
  mfa_checks = mfa_checks,
  configurations = preview_records
), file.path(out, "run_metadata.rds"))

writeLines(c(
  "textual_readiness",
  "text_columns=10",
  paste0("all_text_columns_nonempty=", all(text_audit$non_empty == 167L)),
  "Each text column is a justification associated with the same-named habit.",
  "The future textual route must be run one question/text column at a time.",
  "No textual generation was executed in C02.",
  "No raw verbatim was written to the shareable report or aggregate tables."
), file.path(out, "textual_readiness_summary.txt"), useBytes = TRUE)

status <- c(
  "# C02 — Atomic habits validation status", "",
  "Status: `ready_for_validation`.", "",
  "The data structure, published classification, AFM/HCPC reproducibility candidates,",
  "FactoMineR CATDES reference, NaileR preparation, offline previews and public",
  "accessors were checked. No LLM was called and no semantic validation was attempted.", "",
  "The published three-group classification is reproduced exactly by both documented",
  "AFM candidates, but the available sources do not identify which construction was",
  "historically used. The published `atomic_habit_clust$clust` remains the reference.", "",
  "The analytical CATDES table uses columns 1:20 plus column 51. Text responses,",
  "binary copies and derived composites are excluded from this statistical reference.", "",
  "The small group 2 (n = 13) and the unresolved historical AFM provenance remain",
  "important limitations before any Gemini campaign."
)
writeLines(status, file.path(out, "C02_VALIDATION_STATUS.md"), useBytes = TRUE)

cat("C02_OFFLINE_SUCCESS=TRUE\n")
cat("OUTPUT=", normalizePath(out, mustWork = TRUE), "\n", sep = "")
cat("EVIDENCE_ROWS=", nrow(evidence_registry), "\n", sep = "")
cat("GROUP_SIZES=", paste(as.integer(table(atomic_habit_clust$clust)), collapse = ","), "\n", sep = "")
