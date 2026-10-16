# Offline validation of the five interpretive-deepening B responses.
# No provider API is called and no package source is modified.

options(stringsAsFactors = FALSE)
root <- file.path(getwd(), "validation", "scientific_benchmark_v1")
gpt6_root <- file.path(root, "gpt6")
experiment_root <- file.path(root, "interpretive_deepening")
out <- file.path(experiment_root, "response_validation")
for (dir in c("checks", "objects", "prompts", "responses", "evidence")) {
  dir.create(file.path(out, dir), recursive = TRUE, showWarnings = FALSE)
}
devtools::load_all(getwd(), quiet = TRUE)

read_exact <- function(path) {
  rawToChar(readBin(path, "raw", n = file.info(path)$size))
}
sha256_file <- function(path) {
  digest::digest(readBin(path, "raw", n = file.info(path)$size),
                 algo = "sha256")
}
git_blob_sha1 <- function(path) {
  trimws(system2("git", c("hash-object", path), stdout = TRUE))
}
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
prompt_list <- function(x) {
  p <- nail_prompt(x, print = FALSE)
  if (!is.list(p)) p <- list(portfolio = p)
  p
}
evidence_equal <- function(x, y) identical(nail_evidence(x), nail_evidence(y))
attr_equal <- function(x, y, names) {
  names <- names[vapply(names, function(nm) {
    !is.null(attr(x, nm, exact = TRUE)) &&
      !is.null(attr(y, nm, exact = TRUE))
  }, logical(1))]
  if (!length(names)) return(TRUE)
  all(vapply(names, function(nm) {
    identical(attr(x, nm, exact = TRUE), attr(y, nm, exact = TRUE))
  }, logical(1)))
}
collect_response_strings <- function(x, path = "") {
  if (is.character(x)) {
    return(data.frame(scope = path, text = paste(x, collapse = "\n"),
                      stringsAsFactors = FALSE))
  }
  if (is.data.frame(x) && "response" %in% names(x)) {
    return(data.frame(scope = path, text = paste(as.character(x$response),
                                                 collapse = "\n"),
                      stringsAsFactors = FALSE))
  }
  if (is.list(x)) {
    if (!is.null(x$response)) {
      return(collect_response_strings(x$response, path))
    }
    pieces <- lapply(names(x), function(nm) {
      collect_response_strings(x[[nm]],
                               if (nzchar(path)) paste(path, nm, sep = "$")
                               else nm)
    })
    pieces <- pieces[vapply(pieces, nrow, integer(1)) > 0L]
    if (length(pieces)) return(do.call(rbind, pieces))
  }
  data.frame(scope = character(), text = character(),
             stringsAsFactors = FALSE)
}

manifest <- utils::read.csv(
  file.path(experiment_root, "RESPONSE_PAIR_MANIFEST.csv"),
  check.names = FALSE, stringsAsFactors = FALSE
)
stopifnot(nrow(manifest) == 5L)
prompt_paths <- c(
  file.path(experiment_root, "prompts",
            paste0(manifest[["function"]], "_A_", manifest$scope_id, ".txt")),
  file.path(experiment_root, "prompts",
            paste0(manifest[["function"]], "_B_", manifest$scope_id, ".txt"))
)
response_paths <- c(
  file.path(root, manifest$response_A_path_relative_to_benchmark_v1),
  file.path(root, manifest$response_B_path_relative_to_benchmark_v1)
)
stopifnot(all(file.exists(prompt_paths)), all(file.exists(response_paths)))
prompt_sha_actual <- vapply(prompt_paths, sha256_file, character(1))
prompt_sha_expected <- c(manifest$prompt_A_sha256, manifest$prompt_B_sha256)
response_blob_actual <- vapply(response_paths, git_blob_sha1, character(1))
response_blob_expected <- c(manifest$response_A_git_blob_sha1,
                           manifest$response_B_git_blob_sha1)
response_sha_actual <- vapply(response_paths, sha256_file, character(1))
manifest_check <- data.frame(
  reference = c(paste(manifest[["function"]], manifest$scope_id, "A", sep = "/"),
                paste(manifest[["function"]], manifest$scope_id, "B", sep = "/")),
  prompt_sha256_expected = prompt_sha_expected,
  prompt_sha256_actual = prompt_sha_actual,
  prompt_sha256_match = prompt_sha_actual == prompt_sha_expected,
  response_git_blob_sha1_expected = response_blob_expected,
  response_git_blob_sha1_actual = response_blob_actual,
  response_git_blob_sha1_match = response_blob_actual == response_blob_expected,
  response_sha256_actual = response_sha_actual,
  stringsAsFactors = FALSE
)
utils::write.csv(manifest_check,
                 file.path(out, "checks", "RESPONSE_PAIR_CHECK.csv"),
                 row.names = FALSE)
stopifnot(all(manifest_check$prompt_sha256_match),
          all(manifest_check$response_git_blob_sha1_match))

extra_sentence <- paste(
  "When the evidence allows it, identify and explain the most informative",
  "insight that emerges from the configuration of findings rather than from",
  "any one finding alone, without presenting that insight as an additional",
  "demonstrated fact."
)
intro_consumer <- paste(
  "This study examines food-purchasing behavior in 96 consumers from the same",
  "population, organized into three neutral groups named G1, G2 and G3.",
  "The data combine quantitative measures, categorical characteristics, and",
  "individual open comments. The purpose is to characterize patterns while",
  "preserving within-group heterogeneity and distinguishing observations from",
  "interpretive hypotheses."
)
request_catdes <- paste(
  "For each group, describe the main coherent profile from the displayed",
  "statistical facts. Distinguish central interpretive patterns from secondary",
  "characteristics and do not infer causality or individual properties from",
  "group-level results."
)
request_qda <- paste(
  "Interpret the sensory configuration of the products from the statistical",
  "evidence. Group related attributes into a coherent meaning, distinguish",
  "product markers from axis associations, and keep every interpretation",
  "traceable to the displayed facts."
)
request_catdes_textual <- paste(
  "Use the authoritative CATDES profile as the statistical anchor and use",
  "the parsed comments to illustrate, nuance or question it. Do not force",
  "one-to-one characteristic matching or invent individual configurations."
)
intro_sensory <- paste(
  "Six chocolate products were evaluated by a trained sensory panel using",
  "common sensory attributes. The aim is to describe product profiles and",
  "the main sensory opposition in the adjusted product means without making",
  "causal or hedonic claims."
)
conclusion_qda <- paste(
  "Provide a concise descriptive interpretation while preserving product",
  "identifiers and distinguishing evidence from interpretation."
)
request_B <- list(
  catdes = paste(request_catdes, extra_sentence),
  qda = paste(request_qda, extra_sentence),
  catdes_textual = paste(request_catdes_textual, extra_sentence)
)

base_catdes <- readRDS(file.path(root, "objects", "catdes_consumer.rds"))
consumer_stats <- attr(nail_evidence(base_catdes), "catdes_result",
                       exact = TRUE)$call$X
prior <- readRDS(file.path(gpt6_root, "reinjection", "objects",
                           "generated_six.rds"))
previews <- readRDS(file.path(experiment_root, "objects", "previews_A_B.rds"))

make_catdes <- function() {
  nail_catdes(
    dataset = consumer_stats, num.var = 1,
    introduction = intro_consumer, request = request_B$catdes,
    isolate.groups = FALSE, provider = "gemini",
    model = "gemini-2.5-flash", generate = TRUE
  )
}
make_qda <- function() {
  data("chocolates", package = "SensoMineR")
  nail_qda(
    dataset = sensochoc, formul = "~Product+Panelist", firstvar = 5,
    introduction = intro_sensory, request = request_B$qda,
    conclusion = conclusion_qda, isolate.groups = FALSE, sample.pct = 1,
    provider = "gemini", model = "gemini-2.5-flash", generate = TRUE
  )
}
make_catdes_textual <- function() {
  nail_catdes_textual(
    catdes = prior$catdes, textual = prior$textual,
    introduction = intro_consumer, request = request_B$catdes_textual,
    isolate.groups = TRUE, provider = "gemini",
    model = "gemini-2.5-flash", generate = TRUE
  )
}

prompt_B_text <- vapply(seq_len(nrow(manifest)), function(i) {
  read_exact(file.path(experiment_root, "prompts",
                       paste0(manifest[["function"]][i], "_B_",
                              manifest$scope_id[i], ".txt")))
}, character(1))
prompt_B_runtime_sha <- vapply(prompt_B_text, function(text) {
  digest::digest(charToRaw(enc2utf8(text)), algo = "sha256")
}, character(1))
responses_by_prompt <- stats::setNames(
  lapply(seq_len(nrow(manifest)), function(i) {
    read_exact(file.path(root, manifest$response_B_path_relative_to_benchmark_v1[i]))
  }),
  prompt_B_runtime_sha
)
calls <- list()
fake_backend <- function(provider, model, prompt, output, llm_api_options) {
  key <- digest::digest(charToRaw(enc2utf8(prompt)), algo = "sha256")
  response <- responses_by_prompt[[key]]
  if (is.null(response)) {
    stop(paste("No published B response for prompt SHA", key), call. = FALSE)
  }
  calls[[length(calls) + 1L]] <<- list(provider = provider, model = model,
                                       prompt = prompt, prompt_sha256 = key)
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
generated <- with_fake_backend(list(
  catdes = make_catdes(),
  qda = make_qda(),
  catdes_textual = make_catdes_textual()
))
saveRDS(generated, file.path(out, "objects", "generated_B.rds"))

for (fun in names(generated)) {
  prompts <- prompt_list(generated[[fun]])
  for (id in names(prompts)) {
    write_exact(file.path(out, "prompts", paste0(fun, "_B_", id, ".txt")),
                prompts[[id]])
  }
  write_json(file.path(out, "evidence", paste0(fun, "_B.json")),
             nail_evidence(generated[[fun]]))
  saveRDS(nail_response(generated[[fun]], print = FALSE),
          file.path(out, "responses", paste0(fun, "_B_raw.rds")))
}

qda_meta <- attr(generated$qda, "product_interpretations", exact = TRUE)
qda_rows <- data.frame(
  product = names(qda_meta$products),
  status = vapply(qda_meta$products, `[[`, character(1), "status"),
  parse_issues = vapply(qda_meta$products,
                        function(x) length(x$parse_issues), integer(1)),
  stringsAsFactors = FALSE
)
textual_meta <- attr(generated$catdes_textual,
                     "contextualized_profiles", exact = TRUE)
textual_rows <- lapply(names(textual_meta$groups), function(id) {
  profile <- textual_meta$groups[[id]]
  fields <- c("statistical_anchor", "textual_enrichment",
              "additional_insights", "internal_diversity",
              "contextualized_profile")
  data.frame(
    group = id,
    status = profile$status,
    parse_issues = length(profile$parse_issues),
    five_fields = all(vapply(fields, function(field) {
      is.character(profile[[field]]) && length(profile[[field]]) == 1L &&
        !is.na(profile[[field]])
    }, logical(1))),
    stringsAsFactors = FALSE
  )
})
textual_rows <- do.call(rbind, textual_rows)
utils::write.csv(qda_rows, file.path(out, "checks", "QDA_BLOCKS.csv"),
                 row.names = FALSE)
utils::write.csv(textual_rows,
                 file.path(out, "checks", "CATDES_TEXTUAL_FIELDS.csv"),
                 row.names = FALSE)

catdes_semantic_profiles_preview <- attr(
  previews$catdes$B, "semantic_profiles", exact = TRUE
)
catdes_semantic_profiles_generated <- attr(
  generated$catdes, "semantic_profiles", exact = TRUE
)
semantic_profile_state <- data.frame(
  group = names(catdes_semantic_profiles_preview$groups),
  preview_status = vapply(
    catdes_semantic_profiles_preview$groups,
    function(x) x$status %||% NA_character_, character(1)
  ),
  generated_status = vapply(
    catdes_semantic_profiles_generated$groups,
    function(x) x$status %||% NA_character_, character(1)
  ),
  stringsAsFactors = FALSE
)
semantic_profile_state$runtime_state_only <-
  semantic_profile_state$preview_status == "prompt_ready" &
  semantic_profile_state$generated_status == "joint_response_not_stored"
utils::write.csv(
  semantic_profile_state,
  file.path(out, "checks", "CATDES_SEMANTIC_PROFILE_RUNTIME_STATE.csv"),
  row.names = FALSE
)

prompt_exact <- vapply(seq_len(nrow(manifest)), function(i) {
  fun <- manifest[["function"]][i]
  id <- manifest$scope_id[i]
  current <- file.path(out, "prompts", paste0(fun, "_B_", id, ".txt"))
  source <- file.path(experiment_root, "prompts",
                      paste0(fun, "_B_", id, ".txt"))
  identical(read_exact(current), read_exact(source))
}, logical(1))
response_exact <- vapply(seq_len(nrow(manifest)), function(i) {
  fun <- manifest[["function"]][i]
  id <- manifest$scope_id[i]
  records <- collect_response_strings(
    nail_response(generated[[fun]], print = FALSE)
  )
  expected <- read_exact(file.path(root,
                                   manifest$response_B_path_relative_to_benchmark_v1[i]))
  any(vapply(records$text, identical, logical(1), expected))
}, logical(1))
invariance <- data.frame(
  function. = c("catdes", "qda", "catdes_textual"),
  evidence_invariant = c(
    evidence_equal(generated$catdes, previews$catdes$B),
    evidence_equal(generated$qda, previews$qda$B),
    evidence_equal(generated$catdes_textual, previews$catdes_textual$B)
  ),
  canonical_attributes_invariant = c(
    attr_equal(generated$catdes, previews$catdes$B,
               c("statistical_profiles", "interpretation_evidence",
                 "semantic_facing_evidence")),
    attr_equal(generated$qda, previews$qda$B,
               c("product_profiles", "statistical_profiles",
                 "interpretation_evidence", "semantic_facing_evidence")),
    attr_equal(generated$catdes_textual, previews$catdes_textual$B,
               c("contextualized_evidence", "catdes_textual_evidence"))
  ),
  stringsAsFactors = FALSE
)
names(invariance)[names(invariance) == "function."] <- "function"
utils::write.csv(invariance, file.path(out, "checks", "INVARIANCE.csv"),
                 row.names = FALSE)
usage <- lapply(generated, nail_usage)
usage_rows <- vapply(usage, nrow, integer(1))
usage_table <- data.frame(function. = names(usage), usage_rows = usage_rows)
names(usage_table)[names(usage_table) == "function."] <- "function"
utils::write.csv(usage_table,
                 file.path(out, "checks", "USAGE.csv"), row.names = FALSE)

writeLines(c(
  "# Validation of interpretive-deepening B responses", "",
  "This validation was performed offline. An in-memory backend returned only",
  "the five published B responses when the exact B prompt matched.", "",
  paste0("Manifest prompt SHA-256 checks: ",
         all(manifest_check$prompt_sha256_match)),
  paste0("Manifest response Git blob checks: ",
         all(manifest_check$response_git_blob_sha1_match)),
  paste0("All five raw B responses matched the accessors: ",
         all(response_exact)),
  paste0("All five B prompts matched the source prompts: ",
         all(prompt_exact)),
  paste0("Evidence and canonical statistical attributes invariant: ",
         all(invariance$evidence_invariant) &&
         all(invariance$canonical_attributes_invariant)),
  "CATDES semantic_profiles runtime state is reported separately:",
  "preview statuses are prompt_ready and generated statuses are",
  "joint_response_not_stored; this expected execution-state difference is",
  "not treated as a change to canonical statistical evidence.",
  paste0("QDA reusable blocks available: ",
         all(qda_rows$status == "available") &&
         all(qda_rows$parse_issues == 0L)),
  paste0("CATDES-TEXTUAL profiles available with five fields: ",
         all(textual_rows$status == "available") &&
         all(textual_rows$parse_issues == 0L) &&
         all(textual_rows$five_fields)),
  paste0("No fabricated usage metadata: ", all(usage_rows == 0L)),
  paste0("Simulated calls: ", length(calls)), "",
  "Scientific limits: parsing and exact field preservation do not establish",
  "the substantive correctness of the B interpretations. The benchmark is",
  "single-run, unblinded and based on synthetic/repeated textual data; the",
  "existing exploratory review should remain the qualitative interpretation",
  "record. No provider tokens, costs or durations were inferred."
), file.path(out, "FINAL_B_VALIDATION_REPORT.md"), useBytes = TRUE)

ok <- all(manifest_check$prompt_sha256_match) &&
  all(manifest_check$response_git_blob_sha1_match) &&
  all(prompt_exact) && all(response_exact) &&
  all(invariance$evidence_invariant) &&
  all(invariance$canonical_attributes_invariant) &&
  all(semantic_profile_state$runtime_state_only) &&
  all(qda_rows$status == "available") &&
  all(qda_rows$parse_issues == 0L) &&
  all(textual_rows$status == "available") &&
  all(textual_rows$parse_issues == 0L) &&
  all(textual_rows$five_fields) && all(usage_rows == 0L) &&
  length(calls) == 5L
cat("B_VALIDATION_OK=", ok, "\n", sep = "")
