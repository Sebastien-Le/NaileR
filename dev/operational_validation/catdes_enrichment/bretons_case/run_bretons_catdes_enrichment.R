#!/usr/bin/env Rscript

# Reproducible Breton CATDES / textual-enrichment validation.
# The package-ready data file in data/ is provisional and must not be committed
# by this script. Generated artefacts are written outside Git.

repo <- normalizePath(Sys.getenv("NAILER_REPO", unset = "."), mustWork = TRUE)
out_dir <- Sys.getenv(
  "NAILER_BRETONS_VALIDATION_DIR",
  unset = "/private/tmp/nailer-bretons-distinction-20261029/validation"
)
generate <- identical(tolower(Sys.getenv("BRETONS_GENERATE", "false")), "true")
dir.create(out_dir, recursive = TRUE, showWarnings = FALSE)

devtools::load_all(repo, quiet = TRUE)
data(bretons, package = "NaileR")
ref_env <- new.env(parent = emptyenv())
load(file.path(repo, "data", "distinction.rda"), envir = ref_env)
distinction <- ref_env[["distinction"]]

stopifnot(
  is.data.frame(bretons),
  identical(dim(bretons), c(485L, 105L)),
  identical(names(bretons), names(distinction)),
  identical(
    vapply(bretons, function(x) paste(class(x), collapse = "|"), character(1)),
    vapply(distinction, function(x) paste(class(x), collapse = "|"), character(1))
  ),
  identical(
    lapply(bretons, function(x) if (is.factor(x)) levels(x) else NULL),
    lapply(distinction, function(x) if (is.factor(x)) levels(x) else NULL)
  ),
  sum(!is.na(bretons$quality_food_open)) == 485L
)

active <- c(
  grep("^assertion_q17_", names(bretons), value = TRUE),
  grep("^assertion_q2[1-5]_", names(bretons), value = TRUE)
)
stopifnot(length(active) == 47L)

set.seed(1)
res.mca <- FactoMineR::MCA(
  bretons[active],
  ncp = 10,
  graph = FALSE
)
res.hcpc <- FactoMineR::HCPC(
  res.mca,
  nb.clust = 3,
  graph = FALSE
)
stopifnot(identical(rownames(bretons), rownames(res.hcpc$data.clust)))
profile <- factor(res.hcpc$data.clust[[ncol(res.hcpc$data.clust)]])
stopifnot(length(profile) == nrow(bretons), !anyNA(profile))

bretons_prepared <- data.frame(
  bretons[active],
  quality_food_open = as.character(bretons$quality_food_open),
  profile = profile,
  check.names = FALSE
)
bretons_classic <- bretons_prepared[, c(active, "profile"), drop = FALSE]
stopifnot(
  ncol(bretons_prepared) == 49L,
  ncol(bretons_classic) == 48L,
  identical(as.character(bretons_prepared$profile), as.character(profile))
)

introduction <- paste(
  "This exploratory survey examines declared positions about an ideal food",
  "system among respondents living in administrative Brittany.",
  "The groups were constructed from 47 food-system assertions; the open",
  "responses are comments about food and territory, not verified behaviour.",
  "The profiles should be described as configurations of declared positions,",
  "without causal or regional generalisation."
)
request <- paste(
  "Describe the three exploratory Breton groups using several CATDES findings",
  "together when possible. Keep the group identifiers and distinguish",
  "statistical observations from cautious hypotheses. Do not infer behaviour,",
  "causes, representativeness, or regional differences beyond this sample."
)

common <- list(
  interpretation_mode = "latent",
  isolate.groups = FALSE,
  drop.negative = FALSE,
  introduction = introduction,
  request = request,
  generate = FALSE
)
classic <- do.call(
  nail_catdes,
  c(list(dataset = bretons_classic, num.var = 48L), common)
)
enriched_preview <- do.call(
  nail_catdes,
  c(
    list(
      dataset = bretons_prepared,
      num.var = 49L,
      num.textual = 48L,
      textual.sample = 0.5,
      textual.seed = 123L
    ),
    common
  )
)

classic_evidence <- nail_evidence(classic)
enriched_evidence <- nail_evidence(enriched_preview)
enrichment <- nail_catdes_enrichment(enriched_preview)
stopifnot(identical(classic_evidence, enriched_evidence))

selected <- enrichment$selected_texts
stopifnot(
  identical(names(selected), c("text_id", "group", "source_row", "text")),
  nrow(selected) == 242L,
  all(vapply(enrichment$interpretation_input$groups, function(x) {
    identical(x$status, "ready")
  }, logical(1)))
)

group_sizes <- as.data.frame(table(profile), stringsAsFactors = FALSE)
names(group_sizes) <- c("group", "n")
selected_sizes <- as.data.frame(table(selected$group), stringsAsFactors = FALSE)
names(selected_sizes) <- c("group", "n_selected_texts")
group_summary <- merge(group_sizes, selected_sizes, by = "group", all.x = TRUE)
group_summary$n_selected_texts[is.na(group_summary$n_selected_texts)] <- 0L
group_summary <- group_summary[order(group_summary$group), , drop = FALSE]

saveRDS(res.mca, file.path(out_dir, "bretons_mca.rds"), compress = "xz")
saveRDS(res.hcpc, file.path(out_dir, "bretons_hcpc.rds"), compress = "xz")
saveRDS(bretons_prepared, file.path(out_dir, "bretons_prepared_private.rds"), compress = "xz")
saveRDS(classic, file.path(out_dir, "CATDES_CLASSIC_PREVIEW.rds"), compress = "xz")
saveRDS(enriched_preview, file.path(out_dir, "CATDES_ENRICHED_PREVIEW.rds"), compress = "xz")
saveRDS(classic_evidence, file.path(out_dir, "evidence_classic.rds"), compress = "xz")
saveRDS(enriched_evidence, file.path(out_dir, "evidence_enriched.rds"), compress = "xz")
saveRDS(enrichment, file.path(out_dir, "CATDES_ENRICHMENT_PREVIEW_PRIVATE.rds"), compress = "xz")
write.csv(group_summary, file.path(out_dir, "BRETONS_GROUP_SUMMARY.csv"), row.names = FALSE)
write.csv(
  selected[, c("text_id", "group", "source_row")],
  file.path(out_dir, "BRETONS_SELECTED_TEXT_IDS.csv"),
  row.names = FALSE
)
writeLines(nail_prompt(classic, print = FALSE), file.path(out_dir, "CATDES_CLASSIC_PROMPT.txt"), useBytes = TRUE)
writeLines(nail_prompt(enriched_preview, print = FALSE), file.path(out_dir, "CATDES_ENRICHED_FIRST_PROMPT.txt"), useBytes = TRUE)

result <- NULL
generation_error <- NULL
if (isTRUE(generate)) {
  generation_started <- Sys.time()
  result <- tryCatch(
    nail_catdes(
      dataset = bretons_prepared,
      num.var = 49L,
      num.textual = 48L,
      textual.sample = 0.5,
      textual.seed = 123L,
      interpretation_mode = "latent",
      isolate.groups = FALSE,
      drop.negative = FALSE,
      introduction = introduction,
      request = request,
      provider = "gemini",
      model = "gemini-2.5-flash",
      max_output_tokens = 32768L,
      max_tries = 1L,
      timeout = 120,
      generate = TRUE
    ),
    error = function(error) {
      generation_error <<- conditionMessage(error)
      NULL
    }
  )
  generation_finished <- Sys.time()
  if (!is.null(result)) {
    saveRDS(result, file.path(out_dir, "CATDES_ENRICHED_GEMINI_RESULT_PRIVATE.rds"), compress = "xz")
    writeLines(nail_prompt(result, print = FALSE), file.path(out_dir, "CATDES_ENRICHED_GEMINI_PROMPT.txt"), useBytes = TRUE)
    generated_enrichment <- nail_catdes_enrichment(result)
    writeLines(
      generated_enrichment$first_pass$prompts[["portfolio"]],
      file.path(out_dir, "PASS1_PROMPT.txt"),
      useBytes = TRUE
    )
    writeLines(
      generated_enrichment$second_pass$prompts[["portfolio"]],
      file.path(out_dir, "PASS2_PROMPT.txt"),
      useBytes = TRUE
    )
    first_response <- generated_enrichment$first_pass$responses[["portfolio"]]
    second_response <- generated_enrichment$second_pass$responses[["portfolio"]]
    if (is.character(first_response) && length(first_response) == 1L) {
      writeLines(first_response, file.path(out_dir, "PASS1_RESPONSE.txt"), useBytes = TRUE)
    }
    if (is.character(second_response) && length(second_response) == 1L) {
      writeLines(second_response, file.path(out_dir, "PASS2_RESPONSE.txt"), useBytes = TRUE)
    }
    writeLines(
      c(
        "provider=gemini",
        "model=gemini-2.5-flash",
        "max_output_tokens=32768",
        "max_tries=1",
        "timeout=120",
        "interpretation_mode=latent",
        "isolate.groups=FALSE",
        "drop.negative=FALSE",
        "textual.sample=0.5",
        "textual.seed=123",
        paste("pass1_status=", generated_enrichment$first_pass$status[["portfolio"]], sep = ""),
        paste("pass2_status=", generated_enrichment$second_pass$status[["portfolio"]], sep = ""),
        paste("pass1_response_chars=", nchar(first_response), sep = ""),
        paste("pass2_response_chars=", nchar(second_response), sep = "")
      ),
      file.path(out_dir, "GENERATION_METADATA.txt")
    )
  }
} else {
  generation_started <- NA
  generation_finished <- NA
}

writeLines(
  c(
    "# Breton CATDES / textual-enrichment validation",
    "",
    paste("Generated:", format(Sys.time(), "%Y-%m-%d %H:%M:%S %Z")),
    paste("generate:", generate),
    paste("Rows:", nrow(bretons), "| assertions:", length(active), "| groups:", nlevels(profile)),
    paste("Group sizes:", paste(group_summary$group, group_summary$n, sep = "=", collapse = "; ")),
    paste("Selected comments:", nrow(selected), "(group-wise 0.5 sample, seed 123)"),
    "",
    paste("CATDES evidence identical between classic and enriched:", identical(classic_evidence, enriched_evidence)),
    paste("Preview prompt lengths:", nchar(nail_prompt(classic, print = FALSE)), nchar(nail_prompt(enriched_preview, print = FALSE))),
    paste("Generation started:", if (is.na(generation_started)) "not run" else format(generation_started, tz = "UTC")),
    paste("Generation finished:", if (is.na(generation_finished)) "not run" else format(generation_finished, tz = "UTC")),
    paste("Generation status:", if (!isTRUE(generate)) "not run" else if (!is.null(result)) "returned" else "failed"),
    if (!is.null(generation_error)) paste("Generation error:", generation_error) else character(0),
    "",
    "The selected text registry and prepared data contain individual responses and are private.",
    "This report contains only aggregate counts and technical statuses."
  ),
  file.path(out_dir, "BRETONS_CATDES_VALIDATION_STATUS.md")
)

cat(sprintf(
  "Offline validation passed: %d rows, %d assertions, %d groups, %d selected texts. generate=%s\n",
  nrow(bretons), length(active), nlevels(profile), nrow(selected), generate
))
if (!is.null(generation_error)) {
  stop(generation_error, call. = FALSE)
}
