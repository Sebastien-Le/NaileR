# Offline reinjection of the three published GPT-6 CATDES-TEXTUAL responses.
# No network backend is used; the simulator is keyed by exact prompt SHA-256.

options(stringsAsFactors = FALSE)
root <- file.path(getwd(), "validation", "scientific_benchmark_v1")
gpt6_root <- file.path(root, "gpt6")
composition_root <- file.path(gpt6_root, "composition")
out <- file.path(composition_root, "reinjection")
for (dir in c("prompts", "responses", "evidence", "objects", "checks")) {
  dir.create(file.path(out, dir), recursive = TRUE, showWarnings = FALSE)
}
devtools::load_all(getwd(), quiet = TRUE)

manifest <- utils::read.csv(
  file.path(composition_root, "COMPOSITION_MANIFEST.csv"),
  check.names = FALSE, stringsAsFactors = FALSE
)
prompt_root <- gpt6_root
prompt_paths <- file.path(prompt_root, manifest$prompt_file)
response_paths <- file.path(gpt6_root, manifest$response_file)
stopifnot(all(file.exists(prompt_paths)), all(file.exists(response_paths)))

file_sha256 <- function(path) digest::digest(file = path, algo = "sha256")
git_blob_sha1 <- function(path) {
  trimws(system2("git", c("hash-object", path), stdout = TRUE))
}
prompt_sha <- vapply(prompt_paths, file_sha256, character(1))
response_sha <- vapply(response_paths, file_sha256, character(1))
response_blob_sha <- vapply(response_paths, git_blob_sha1, character(1))
stopifnot(all(prompt_sha == manifest$prompt_sha256))
source_manifest_check <- data.frame(
  group = manifest$group,
  prompt_sha256_declared = manifest$prompt_sha256,
  prompt_sha256_actual = prompt_sha,
  prompt_sha256_match = prompt_sha == manifest$prompt_sha256,
  response_git_blob_sha1_declared = manifest$response_git_blob_sha1,
  response_git_blob_sha1_actual = response_blob_sha,
  response_git_blob_sha1_match = response_blob_sha ==
    manifest$response_git_blob_sha1,
  response_sha256_actual = response_sha,
  stringsAsFactors = FALSE
)
manifest_bad_groups <- source_manifest_check$group[
  !source_manifest_check$response_git_blob_sha1_match
]
manifest_bad_groups_text <- if (length(manifest_bad_groups)) {
  paste(manifest_bad_groups, collapse = ", ")
} else {
  "none"
}
utils::write.csv(source_manifest_check,
                 file.path(out, "checks", "SOURCE_MANIFEST_CHECK.csv"),
                 row.names = FALSE)

read_exact <- function(path) {
  rawToChar(readBin(path, "raw", n = file.info(path)$size))
}
runtime_prompt_text <- vapply(prompt_paths, read_exact, character(1))
runtime_prompt_sha <- vapply(runtime_prompt_text, function(text) {
  digest::digest(charToRaw(enc2utf8(text)), algo = "sha256")
}, character(1))
responses_by_prompt <- stats::setNames(
  lapply(response_paths, read_exact), prompt_sha
)
names(responses_by_prompt) <- runtime_prompt_sha
stopifnot(length(unique(names(responses_by_prompt))) == nrow(manifest))

calls <- list()
fake_backend <- function(provider, model, prompt, output, llm_api_options) {
  key <- digest::digest(charToRaw(enc2utf8(prompt)), algo = "sha256")
  response <- responses_by_prompt[[key]]
  if (is.null(response)) {
    stop(paste("No published composition response for prompt SHA", key),
         call. = FALSE)
  }
  calls[[length(calls) + 1L]] <<- list(
    provider = provider, model = model, prompt = prompt,
    prompt_sha256 = key
  )
  data.frame(response = response, prompt = prompt,
             stringsAsFactors = FALSE)
}

with_fake_backend <- function(expr) {
  ns <- asNamespace("NaileR")
  old <- get(".call_llm_base", envir = ns)
  unlockBinding(".call_llm_base", ns)
  assign(".call_llm_base", fake_backend, envir = ns)
  lockBinding(".call_llm_base", ns)
  on.exit({
    unlockBinding(".call_llm_base", ns)
    assign(".call_llm_base", old, envir = ns)
    lockBinding(".call_llm_base", ns)
  }, add = TRUE)
  force(expr)
}

prior <- readRDS(file.path(gpt6_root, "reinjection", "objects",
                           "generated_six.rds"))
reference <- list(
  catdes = readRDS(file.path(root, "objects", "catdes_consumer.rds")),
  textual = readRDS(file.path(root, "objects", "textual_consumer.rds"))
)
preview <- readRDS(file.path(gpt6_root, "reinjection", "objects",
                             "catdes_textual_preview.rds"))
intro <- paste(
  "This study examines food-purchasing behavior in 96 consumers from the same",
  "population, organized into three neutral groups named G1, G2 and G3.",
  "The data combine quantitative measures, categorical characteristics, and",
  "individual open comments. The purpose is to characterize patterns while",
  "preserving within-group heterogeneity and distinguishing observations from",
  "interpretive hypotheses."
)
request <- paste(
  "Use the authoritative CATDES profile as the statistical anchor and use",
  "the parsed comments to illustrate, nuance or question it. Do not force",
  "one-to-one characteristic matching or invent individual configurations."
)

composition <- with_fake_backend({
  nail_catdes_textual(
    catdes = prior$catdes,
    textual = prior$textual,
    introduction = intro,
    request = request,
    isolate.groups = TRUE,
    provider = "gemini",
    model = "gemini-2.5-flash",
    generate = TRUE
  )
})

write_exact <- function(path, text) {
  con <- file(path, "wb")
  on.exit(close(con), add = TRUE)
  writeBin(charToRaw(enc2utf8(as.character(text))), con)
}
write_json <- function(path, object) {
  clean <- function(x) {
    if (is.language(x)) return(paste(deparse(x), collapse = ""))
    if (is.function(x)) return("<function>")
    if (is.environment(x)) return("<environment>")
    if (is.data.frame(x)) return(lapply(x, clean))
    if (is.list(x)) return(lapply(x, clean))
    x
  }
  writeLines(jsonlite::toJSON(clean(object), auto_unbox = TRUE,
                              pretty = TRUE, null = "null"), path,
             useBytes = TRUE)
}
prompt_list <- nail_prompt(composition, print = FALSE)
if (!is.list(prompt_list)) prompt_list <- list(prompt_list)
response_list <- nail_response(composition, print = FALSE)
if (!is.list(response_list)) response_list <- list(response_list)
group_ids <- names(prompt_list)
stopifnot(identical(group_ids, manifest$group))

for (id in group_ids) {
  write_exact(file.path(out, "prompts",
                        paste0("catdes_textual_generated_", id, ".txt")),
              prompt_list[[id]])
}
saveRDS(response_list, file.path(out, "responses",
                                 "catdes_textual_raw_responses.rds"))
saveRDS(composition, file.path(out, "objects",
                               "catdes_textual_generated.rds"))
write_json(file.path(out, "evidence", "catdes_textual_evidence.json"),
           attr(composition, "contextualized_evidence", exact = TRUE))

profiles <- attr(composition, "contextualized_profiles", exact = TRUE)
required_fields <- c(
  "statistical_anchor", "textual_enrichment", "additional_insights",
  "internal_diversity", "contextualized_profile"
)
profile_rows <- lapply(group_ids, function(id) {
  profile <- profiles$groups[[id]]
  data.frame(
    group = id,
    status = profile$status,
    parse_issues = length(profile$parse_issues),
    all_five_fields = all(vapply(required_fields, function(field) {
      is.character(profile[[field]]) && length(profile[[field]]) == 1L &&
        !is.na(profile[[field]])
    }, logical(1))),
    stringsAsFactors = FALSE
  )
})
profile_matrix <- do.call(rbind, profile_rows)
utils::write.csv(profile_matrix,
                 file.path(out, "checks", "PROFILE_VALIDATION.csv"),
                 row.names = FALSE)

prompt_exact <- vapply(seq_along(group_ids), function(i) {
  identical(read_exact(prompt_paths[[i]]),
            read_exact(file.path(out, "prompts",
                                 paste0("catdes_textual_generated_",
                                        group_ids[[i]], ".txt"))))
}, logical(1))
response_exact <- vapply(seq_along(group_ids), function(i) {
  published <- responses_by_prompt[[runtime_prompt_sha[[i]]]]
  current <- response_list[[group_ids[[i]]]]
  if (is.data.frame(current) && "response" %in% names(current)) {
    current <- paste(as.character(current$response), collapse = "\n")
  }
  if (is.list(current) && !is.null(current$response)) {
    current <- current$response
  }
  identical(as.character(current), as.character(published))
}, logical(1))
contextual_evidence_invariant <- identical(
  attr(composition, "contextualized_evidence", exact = TRUE),
  attr(preview, "contextualized_evidence", exact = TRUE)
)
catdes_evidence_invariant <- identical(
  nail_evidence(prior$catdes),
  nail_evidence(reference$catdes)
)
textual_evidence_invariant <- identical(
  nail_evidence(prior$textual),
  nail_evidence(reference$textual)
)
usage <- nail_usage(composition)
usage_zero <- nrow(usage) == 0L
settings <- attr(composition, "catdes_textual_settings", exact = TRUE)
calls_ok <- length(calls) == 3L && identical(settings$llm_calls, 3L)

composition_manifest <- data.frame(
  group = group_ids,
  prompt_file = file.path("reinjection", "prompts",
                          paste0("catdes_textual_generated_", group_ids,
                                 ".txt")),
  prompt_file_sha256 = vapply(group_ids, function(id) {
    file_sha256(file.path(out, "prompts",
                          paste0("catdes_textual_generated_", id, ".txt")))
  }, character(1)),
  prompt_sha256_runtime = vapply(group_ids, function(id) {
    digest::digest(charToRaw(enc2utf8(prompt_list[[id]])), algo = "sha256")
  }, character(1)),
  response_file = manifest$response_file,
  response_sha256 = response_sha,
  response_git_blob_sha1_declared = manifest$response_git_blob_sha1,
  response_git_blob_sha1 = response_blob_sha,
  stringsAsFactors = FALSE
)
utils::write.csv(composition_manifest,
                 file.path(out, "checks", "COMPOSITION_REINJECTION_MANIFEST.csv"),
                 row.names = FALSE)

prior_matrix <- utils::read.csv(
  file.path(gpt6_root, "reinjection", "checks", "VALIDATION_MATRIX.csv"),
  stringsAsFactors = FALSE
)
final_matrix <- rbind(
  prior_matrix,
  data.frame(
    function. = "catdes_textual",
    prompt_exact = all(prompt_exact),
    evidence_invariant = contextual_evidence_invariant &&
      catdes_evidence_invariant && textual_evidence_invariant,
    response_reinjected = all(response_exact),
    usage_rows = nrow(usage),
    status = if (all(source_manifest_check$response_git_blob_sha1_match)) {
      "executed_offline_simulated_backend"
    } else {
      "executed_offline;published_manifest_mismatch_G1"
    },
    stringsAsFactors = FALSE
  )
)
names(final_matrix)[names(final_matrix) == "function."] <- "function"
utils::write.csv(final_matrix,
                 file.path(out, "checks", "SEVEN_FUNCTIONS_FINAL_MATRIX.csv"),
                 row.names = FALSE)

writeLines(c(
  "# Final seven-function scientific benchmark report", "",
  "All checks in this report were performed offline. No provider API was",
  "called. The in-memory backend returned the three published GPT-6",
  "composition responses only when the exact prompt SHA-256 matched.", "",
  paste0("Composition prompt/response manifest verified: ",
         all(source_manifest_check$prompt_sha256_match) &&
         all(source_manifest_check$response_git_blob_sha1_match)),
  paste0("Published response blob SHA-1 mismatch groups: ",
         manifest_bad_groups_text),
  paste0("Three contextualized profiles available: ",
         all(profile_matrix$status == "available")),
  paste0("No composition parse issues: ",
         all(profile_matrix$parse_issues == 0L)),
  paste0("Five required fields preserved for all profiles: ",
         all(profile_matrix$all_five_fields)),
  paste0("Prompts exact: ", all(prompt_exact)),
  paste0("Raw responses exact: ", all(response_exact)),
  paste0("CATDES evidence invariant: ", catdes_evidence_invariant),
  paste0("TEXTUAL evidence invariant: ", textual_evidence_invariant),
  paste0("Contextualized evidence invariant: ", contextual_evidence_invariant),
  paste0("No fabricated usage rows/tokens/costs: ", usage_zero),
  paste0("Simulated composition calls: ", length(calls)), "",
  "Technical validations cover CONDES, CATDES, DESCFREQ, TEXTUAL, QDA,",
  "QDA-space and CATDES-TEXTUAL. The six upstream reinjections were",
  "validated in the preceding report; this pass validates the seventh",
  "composition stage from those validated objects.", "",
  "Scientific reserves: successful parsing and field preservation do not",
  "establish substantive correctness. The consumer data are synthetic,",
  "the textual corpus contains repeated formulations, and G3 has a sparse",
  "statistical profile. The five response fields and the authoritative",
  "CATDES anchor were checked, but the interpretations remain subject to",
  "human scientific review.", "",
  "No CATDES-TEXTUAL response was fabricated; the three published responses",
  "were replayed exactly through the simulated backend. No API token, cost,",
  "duration or provider usage was inferred."
), file.path(out, "checks", "FINAL_SEVEN_FUNCTIONS_REPORT.md"),
useBytes = TRUE)

ok <- all(prompt_exact) && all(response_exact) &&
  all(profile_matrix$status == "available") &&
  all(profile_matrix$parse_issues == 0L) &&
  all(profile_matrix$all_five_fields) &&
  contextual_evidence_invariant && catdes_evidence_invariant &&
  textual_evidence_invariant && usage_zero && calls_ok &&
  all(source_manifest_check$response_git_blob_sha1_match)
cat("COMPOSITION_REINJECTION_OK=", ok, "\n", sep = "")
