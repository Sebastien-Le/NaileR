# Offline reinjection of the eight published GPT-6 responses.
# No network backend is used. The fake backend requires an exact prompt SHA.

options(stringsAsFactors = FALSE)
root <- file.path(getwd(), "validation", "scientific_benchmark_v1")
gpt6_root <- file.path(root, "gpt6")
out <- file.path(gpt6_root, "reinjection")
for (dir in c("prompts", "responses", "evidence", "objects", "checks")) {
  dir.create(file.path(out, dir), recursive = TRUE, showWarnings = FALSE)
}
devtools::load_all(getwd(), quiet = TRUE)

manifest <- utils::read.csv(file.path(gpt6_root, "RESPONSE_MANIFEST.csv"),
                            check.names = FALSE, stringsAsFactors = FALSE)
prompt_root <- root
response_root <- gpt6_root
prompt_sha <- vapply(manifest$source_prompt_file, function(path) {
  digest::digest(file = file.path(prompt_root, path), algo = "sha256")
}, character(1))
response_sha <- vapply(manifest$response_file, function(path) {
  digest::digest(file = file.path(response_root, path), algo = "sha256")
}, character(1))
stopifnot(all(prompt_sha == manifest$source_prompt_sha256))
stopifnot(all(response_sha == manifest$response_sha256))

responses_by_prompt <- stats::setNames(
  lapply(manifest$response_file, function(path) {
    paste(readLines(file.path(response_root, path), encoding = "UTF-8"),
          collapse = "\n")
  }),
  vapply(manifest$source_prompt_file, function(path) {
    prompt_path <- file.path(prompt_root, path)
    digest::digest(readBin(prompt_path, "raw", n = file.info(prompt_path)$size),
                   algo = "sha256")
  }, character(1))
)
calls <- list()
fake_backend <- function(provider, model, prompt, output, llm_api_options) {
  key <- digest::digest(charToRaw(enc2utf8(prompt)), algo = "sha256")
  response <- responses_by_prompt[[key]]
  if (is.null(response)) {
    stop(paste("No published GPT-6 response for prompt SHA", key), call. = FALSE)
  }
  calls[[length(calls) + 1L]] <<- list(provider = provider, model = model,
                                       prompt = prompt, prompt_sha256 = key)
  data.frame(response = response, prompt = prompt,
             stringsAsFactors = FALSE)
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
prompt_sha256 <- function(text) digest::digest(charToRaw(enc2utf8(text)),
                                               algo = "sha256")
response_text <- function(x) {
  if (is.character(x)) return(paste(x, collapse = "\n"))
  if (is.data.frame(x) && "response" %in% names(x)) {
    return(paste(as.character(x$response), collapse = "\n"))
  }
  if (is.list(x) && !is.null(x$response)) return(response_text(x$response))
  NA_character_
}
prompt_list <- function(x) {
  p <- nail_prompt(x, print = FALSE)
  if (!is.list(p)) p <- list(p)
  p
}
write_prompts <- function(x, prefix) {
  p <- prompt_list(x)
  for (id in names(p)) {
    safe <- gsub("[^A-Za-z0-9_.-]+", "_", id)
    write_exact(file.path(out, "prompts", paste0(prefix, "_", safe, ".txt")),
                p[[id]])
  }
  p
}
write_responses <- function(x, prefix) {
  r <- nail_response(x, print = FALSE)
  saveRDS(r, file.path(out, "responses", paste0(prefix, ".rds")))
  r
}
usage_rows <- function(x) nrow(nail_usage(x))

consumer <- utils::read.csv(file.path(root, "study_consumer", "consumer_data.csv"),
                            stringsAsFactors = TRUE)
consumer$group <- factor(consumer$group, levels = c("G1", "G2", "G3"))
consumer$diet <- factor(consumer$diet,
                        levels = c("conventional", "flexitarian", "vegetarian"))
consumer$channel <- factor(consumer$channel,
                           levels = c("supermarket", "online", "local_market"))
consumer$concern <- factor(consumer$concern,
                           levels = c("price", "convenience", "quality", "environment"))
consumer_stats <- consumer[setdiff(names(consumer), c("respondent_id", "comment"))]
freq <- as.data.frame.matrix(table(consumer$group, consumer$channel))
freq <- freq[, c("supermarket", "online", "local_market"), drop = FALSE]
intro <- paste(
  "This study examines food-purchasing behavior in 96 consumers from the same",
  "population, organized into three neutral groups named G1, G2 and G3.",
  "The data combine quantitative measures, categorical characteristics, and",
  "individual open comments. The purpose is to characterize patterns while",
  "preserving within-group heterogeneity and distinguishing observations from",
  "interpretive hypotheses."
)
requests <- list(
  condes = paste("Characterize the substantive profile associated with satisfaction",
                 "from the statistical associations shown. Synthesize convergent",
                 "facts, keep interpretation traceable, and distinguish observed",
                 "associations from broader hypotheses. Do not infer causality."),
  catdes = paste("For each group, describe the main coherent profile from the",
                 "displayed statistical facts. Distinguish central interpretive",
                 "patterns from secondary characteristics and do not infer",
                 "causality or individual properties from group-level results."),
  descfreq = paste("Describe the main frequency profile of the groups from the",
                   "displayed relative frequencies. Synthesize convergent patterns",
                   "without treating a frequency difference as an absolute",
                   "preference or causal effect."),
  textual = paste("Identify recurring themes and meaningful tensions in the",
                  "comments. Synthesize several responses when justified, preserve",
                  "minority positions and distinguish what respondents literally",
                  "expressed from contextual interpretation. Do not infer hidden",
                  "motivations.")
)
sensory_intro <- paste(
  "Six chocolate products were evaluated by a trained sensory panel using",
  "common sensory attributes. The aim is to describe product profiles and",
  "the main sensory opposition in the adjusted product means without making",
  "causal or hedonic claims."
)
sensory_request <- paste(
  "Interpret the sensory configuration of the products from the statistical",
  "evidence. Group related attributes into a coherent meaning, distinguish",
  "product markers from axis associations, and keep every interpretation",
  "traceable to the displayed facts."
)
sensory_conclusion <- paste(
  "Provide a concise descriptive interpretation while preserving product",
  "identifiers and distinguishing evidence from interpretation."
)

base <- list(
  condes = readRDS(file.path(root, "objects", "condes_consumer.rds")),
  catdes = readRDS(file.path(root, "objects", "catdes_consumer.rds")),
  descfreq = readRDS(file.path(root, "objects", "descfreq_consumer.rds")),
  textual = readRDS(file.path(root, "objects", "textual_consumer.rds")),
  qda = readRDS(file.path(root, "objects", "qda_sensochoc.rds")),
  qda_space = readRDS(file.path(root, "objects", "qda_space_sensochoc.rds"))
)

# Reuse the exact CATDES input retained in the validated reference object.
# This preserves the original R column types in the diagnostic catdes_result
# call attribute as well as the canonical evidence values.
consumer_stats <- attr(nail_evidence(base$catdes), "catdes_result",
                       exact = TRUE)$call$X

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

generated <- with_fake_backend({
  list(
    condes = nail_condes(
      dataset = consumer_stats, num.var = 6, introduction = intro,
      request = requests$condes, target_concept = "consumer satisfaction",
      target_label = "satisfaction", provider = "gemini",
      model = "gemini-2.5-flash", generate = TRUE
    ),
    catdes = nail_catdes(
      dataset = consumer_stats, num.var = 1, introduction = intro,
      request = requests$catdes, isolate.groups = FALSE, provider = "gemini",
      model = "gemini-2.5-flash", generate = TRUE
    ),
    descfreq = nail_descfreq(
      dataset = freq, introduction = intro, request = requests$descfreq,
      isolate.groups = FALSE, rows_are_ordered = TRUE,
      explicit_row_labels = TRUE, row_identity_mode = "standard",
      provider = "gemini", model = "gemini-2.5-flash", generate = TRUE
    ),
    textual = nail_textual(
      dataset = consumer[, c("group", "respondent_id", "comment")],
      num.var = 1, num.text = 3, introduction = intro,
      request = requests$textual, isolate.groups = TRUE, sample.pct = 1,
      seed = 42, prompt_style = "detailed", text_role = "comments",
      provider = "gemini", model = "gemini-2.5-flash", generate = TRUE
    ),
    qda = {
      data("chocolates", package = "SensoMineR")
      nail_qda(
        dataset = sensochoc, formul = "~Product+Panelist", firstvar = 5,
        introduction = sensory_intro, request = sensory_request,
        conclusion = sensory_conclusion, isolate.groups = FALSE,
        sample.pct = 1, provider = "gemini", model = "gemini-2.5-flash",
        generate = TRUE
      )
    },
    qda_space = {
      nail_qda_space(
        x = base$qda, ncp = 1, min_inertia_pct = 10,
        condes_proba = 0.05, expertise_mode = "sensory",
        introduction = sensory_intro, request = sensory_request,
        conclusion = sensory_conclusion, provider = "gemini",
        model = "gemini-2.5-flash", generate = TRUE
      )
    }
  )
})

saveRDS(generated, file.path(out, "objects", "generated_six.rds"))
for (name in names(generated)) {
  write_prompts(generated[[name]], paste0(name, "_generated"))
  write_responses(generated[[name]], paste0(name, "_raw_responses"))
  write_json(file.path(out, "evidence", paste0(name, "_evidence.json")),
             nail_evidence(generated[[name]]))
  utils::write.csv(nail_usage(generated[[name]]),
                   file.path(out, "checks", paste0(name, "_usage.csv")),
                   row.names = FALSE)
}

textual_profiles <- attr(generated$textual, "textual_profiles", exact = TRUE)
textual_status <- vapply(textual_profiles$groups, function(g) g$status,
                         character(1))
qda_interpretations <- attr(generated$qda, "product_interpretations", exact = TRUE)
qda_status <- vapply(qda_interpretations$products, function(p) p$status,
                     character(1))

catdes_textual <- nail_catdes_textual(
  catdes = generated$catdes, textual = generated$textual,
  introduction = intro,
  request = paste(
    "Use the authoritative CATDES profile as the statistical anchor and use",
    "the parsed comments to illustrate, nuance or question it. Do not force",
    "one-to-one characteristic matching or invent individual configurations."
  ),
  isolate.groups = TRUE, provider = "gemini",
  model = "gemini-2.5-flash", generate = FALSE
)
catdes_textual_prompts <- write_prompts(catdes_textual,
                                        "catdes_textual_preview")
write_json(file.path(out, "evidence", "catdes_textual_evidence.json"),
           attr(catdes_textual, "contextualized_evidence", exact = TRUE))
saveRDS(catdes_textual, file.path(out, "objects", "catdes_textual_preview.rds"))
catdes_textual_evidence_file <- file.path(out, "evidence",
                                          "catdes_textual_evidence.json")
catdes_textual_prompt_manifest <- data.frame(
  group = names(catdes_textual_prompts),
  prompt_file = file.path(
    "reinjection", "prompts",
    paste0("catdes_textual_preview_", names(catdes_textual_prompts), ".txt")
  ),
  prompt_sha256 = vapply(names(catdes_textual_prompts), function(id) {
    path <- file.path(out, "prompts",
                      paste0("catdes_textual_preview_", id, ".txt"))
    digest::digest(file = path, algo = "sha256")
  }, character(1)),
  evidence_file = file.path(
    "reinjection", "evidence", "catdes_textual_evidence.json"
  ),
  evidence_sha256 = digest::digest(file = catdes_textual_evidence_file,
                                   algo = "sha256"),
  stringsAsFactors = FALSE
)
utils::write.csv(catdes_textual_prompt_manifest,
                 file.path(out, "checks", "CATDES_TEXTUAL_MANIFEST.csv"),
                 row.names = FALSE)

preview_names <- c("condes", "catdes", "descfreq", "textual", "qda", "qda_space")
evidence_equal <- vapply(preview_names, function(name) {
  identical(nail_evidence(base[[name]]), nail_evidence(generated[[name]]))
}, logical(1))
prompt_equal <- vapply(preview_names, function(name) {
  identical(prompt_list(base[[name]]), prompt_list(generated[[name]]))
}, logical(1))
raw_equal <- vapply(preview_names, function(name) {
  generated_hashes <- vapply(calls, function(call) call$prompt_sha256,
                             character(1))
  all(vapply(prompt_list(base[[name]]), function(prompt) {
    prompt_sha256(prompt) %in% generated_hashes
  }, logical(1)))
}, logical(1))
usage_zero <- vapply(generated, function(x) usage_rows(x) == 0L, logical(1))

matrix <- data.frame(
  `function` = preview_names,
  prompt_exact = prompt_equal,
  evidence_invariant = evidence_equal,
  response_reinjected = raw_equal,
  usage_rows = vapply(generated, usage_rows, integer(1)),
  status = "executed_offline_simulated_backend",
  stringsAsFactors = FALSE
)
utils::write.csv(matrix, file.path(out, "checks", "VALIDATION_MATRIX.csv"),
                 row.names = FALSE)
writeLines(c(
  "# Offline GPT-6 reinjection report", "",
  "No network request was made. The backend was replaced in memory by a",
  "prompt-SHA keyed simulator returning the exact published response.", "",
  "RESPONSE_MANIFEST.csv: all 8 prompt SHA-256 and response SHA-256",
  "entries were verified before reinjection.", "",
  paste0("Prompt exact for all six functions: ", all(prompt_equal)),
  paste0("Canonical evidence invariant for all six functions: ", all(evidence_equal)),
  paste0("Published responses reinjected for all six functions: ", all(raw_equal)),
  paste0("No fabricated usage metadata: ", all(usage_zero)),
  paste0("Simulated calls recorded: ", length(calls)), "",
  paste0("TEXTUAL parsed statuses: ", paste(textual_status, collapse = ", ")),
  paste0("QDA reusable interpretation statuses: ", paste(qda_status, collapse = ", ")),
  if (all(qda_status == "available")) {
    "All six QDA product interpretation blocks were parsed and retained with source llm_pass1."
  } else {
    "At least one QDA reusable interpretation block was not parsed; it is not treated as reusable."
  }, "",
  "CATDES-TEXTUAL preview prompts were constructed from the generated CATDES",
  "and successfully parsed TEXTUAL objects. No CATDES-TEXTUAL response was",
  "fabricated or generated in this pass."
), file.path(out, "checks", "REINJECTION_REPORT.md"), useBytes = TRUE)
cat("REINJECTION_OK=", all(prompt_equal) && all(evidence_equal) &&
      all(usage_zero) && all(raw_equal) &&
      all(textual_status %in% c("available", "generated")) &&
      all(qda_status == "available"),
    "\n", sep = "")
