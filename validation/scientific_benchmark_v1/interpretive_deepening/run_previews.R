# Offline A/B preview experiment for multidimensional interpretive lift.
# This script does not modify package code and does not call an LLM.

options(stringsAsFactors = FALSE)
root <- file.path(getwd(), "validation", "scientific_benchmark_v1")
gpt6_root <- file.path(root, "gpt6")
out <- file.path(root, "interpretive_deepening")
for (dir in c("prompts", "evidence", "objects", "checks")) {
  dir.create(file.path(out, dir), recursive = TRUE, showWarnings = FALSE)
}
devtools::load_all(getwd(), quiet = TRUE)

extra_sentence <- paste(
  "When the evidence allows it, identify and explain the most informative",
  "insight that emerges from the configuration of findings rather than from",
  "any one finding alone, without presenting that insight as an additional",
  "demonstrated fact."
)

write_exact <- function(path, text) {
  con <- file(path, "wb")
  on.exit(close(con), add = TRUE)
  writeBin(charToRaw(enc2utf8(as.character(text))), con)
}
read_exact <- function(path) {
  rawToChar(readBin(path, "raw", n = file.info(path)$size))
}
sha256_file <- function(path) {
  digest::digest(readBin(path, "raw", n = file.info(path)$size),
                 algo = "sha256")
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
  if (!is.list(p)) p <- list(p)
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
write_prompt_bundle <- function(x, function_name, condition) {
  prompts <- prompt_list(x)
  for (id in names(prompts)) {
    safe <- gsub("[^A-Za-z0-9_.-]+", "_", id)
    write_exact(file.path(out, "prompts",
                          paste0(function_name, "_", condition, "_",
                                 safe, ".txt")), prompts[[id]])
    write_json(file.path(out, "evidence",
                         paste(function_name, condition, safe,
                               "json", sep = ".")),
               nail_evidence(x))
  }
  prompts
}

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
request_qda <- paste(
  "Interpret the sensory configuration of the products from the statistical",
  "evidence. Group related attributes into a coherent meaning, distinguish",
  "product markers from axis associations, and keep every interpretation",
  "traceable to the displayed facts."
)
conclusion_qda <- paste(
  "Provide a concise descriptive interpretation while preserving product",
  "identifiers and distinguishing evidence from interpretation."
)

base_catdes <- readRDS(file.path(root, "objects", "catdes_consumer.rds"))
consumer_stats <- attr(nail_evidence(base_catdes), "catdes_result",
                       exact = TRUE)$call$X
prior <- readRDS(file.path(gpt6_root, "reinjection", "objects",
                           "generated_six.rds"))

make_catdes <- function(request) {
  nail_catdes(
    dataset = consumer_stats, num.var = 1,
    introduction = intro_consumer, request = request,
    isolate.groups = FALSE, provider = "gemini",
    model = "gemini-2.5-flash", generate = FALSE
  )
}
make_qda <- function(request) {
  data("chocolates", package = "SensoMineR")
  nail_qda(
    dataset = sensochoc, formul = "~Product+Panelist", firstvar = 5,
    introduction = intro_sensory, request = request,
    conclusion = conclusion_qda, isolate.groups = FALSE, sample.pct = 1,
    provider = "gemini", model = "gemini-2.5-flash", generate = FALSE
  )
}
make_catdes_textual <- function(request) {
  nail_catdes_textual(
    catdes = prior$catdes, textual = prior$textual,
    introduction = intro_consumer, request = request,
    isolate.groups = TRUE, provider = "gemini",
    model = "gemini-2.5-flash", generate = FALSE
  )
}

requests <- list(
  catdes = c(A = request_catdes, B = paste(request_catdes, extra_sentence)),
  qda = c(A = request_qda, B = paste(request_qda, extra_sentence)),
  catdes_textual = c(
    A = request_catdes_textual,
    B = paste(request_catdes_textual, extra_sentence)
  )
)
results <- list(
  catdes = list(A = make_catdes(requests$catdes[["A"]]),
                B = make_catdes(requests$catdes[["B"]])),
  qda = list(A = make_qda(requests$qda[["A"]]),
             B = make_qda(requests$qda[["B"]])),
  catdes_textual = list(
    A = make_catdes_textual(requests$catdes_textual[["A"]]),
    B = make_catdes_textual(requests$catdes_textual[["B"]])
  )
)
saveRDS(results, file.path(out, "objects", "previews_A_B.rds"))

manifest_rows <- list()
comparison_rows <- list()
for (fun in names(results)) {
  prompts_A <- write_prompt_bundle(results[[fun]]$A, fun, "A")
  prompts_B <- write_prompt_bundle(results[[fun]]$B, fun, "B")
  if (!identical(names(prompts_A), names(prompts_B))) {
    stop("A/B prompt scopes differ for ", fun, call. = FALSE)
  }
  stripped_B <- vapply(prompts_B, function(text) {
    sub(paste0(" ", extra_sentence), "", text, fixed = TRUE)
  }, character(1))
  prompt_diff_only <- all(vapply(names(prompts_A), function(id) {
    identical(prompts_A[[id]], stripped_B[[id]])
  }, logical(1)))
  ev_equal <- evidence_equal(results[[fun]]$A, results[[fun]]$B)
  canonical_equal <- attr_equal(
    results[[fun]]$A, results[[fun]]$B,
    c("statistical_profiles", "interpretation_evidence",
      "semantic_facing_evidence", "product_profiles",
      "contextualized_evidence", "catdes_textual_evidence")
  )
  comparison_rows[[fun]] <- data.frame(
    function. = fun,
    n_prompts = length(prompts_A),
    evidence_identical = ev_equal,
    canonical_attributes_identical = canonical_equal,
    only_extra_sentence = prompt_diff_only,
    stringsAsFactors = FALSE
  )
  for (id in names(prompts_A)) {
    for (condition in c("A", "B")) {
      path <- file.path(out, "prompts",
                        paste0(fun, "_", condition, "_",
                               gsub("[^A-Za-z0-9_.-]+", "_", id),
                               ".txt"))
      manifest_rows[[length(manifest_rows) + 1L]] <- data.frame(
        function. = fun,
        condition = condition,
        scope_id = id,
        prompt_file = file.path("prompts", basename(path)),
        prompt_sha256 = sha256_file(path),
        stringsAsFactors = FALSE
      )
    }
  }
}
comparison <- do.call(rbind, comparison_rows)
manifest <- do.call(rbind, manifest_rows)
names(comparison)[names(comparison) == "function."] <- "function"
names(manifest)[names(manifest) == "function."] <- "function"
utils::write.csv(comparison, file.path(out, "checks", "COMPARISON.csv"),
                 row.names = FALSE)
utils::write.csv(manifest, file.path(out, "checks", "PROMPT_MANIFEST.csv"),
                 row.names = FALSE)

writeLines(c(
  "# Interpretive deepening preview experiment", "",
  "No package source, default prompt, statistical calculation or LLM call",
  "was changed or executed. Conditions A and B use the same data, evidence,",
  "context, public options and output contracts. B appends exactly one",
  "sentence to the complete reference request for each function.", "",
  "## Conditions", "",
  "- A: validated reference request.",
  paste0("- B: reference request plus: `", extra_sentence, "`"), "",
  "## Checks", "",
  paste0("All evidence comparisons passed: ",
         all(comparison$evidence_identical)),
  paste0("All canonical attribute comparisons passed: ",
         all(comparison$canonical_attributes_identical)),
  paste0("All prompt differences are limited to the added sentence: ",
         all(comparison$only_extra_sentence)), "",
  "The previews are fixtures for a later blind interpretation comparison;",
  "no model response is included or inferred in this experiment."
), file.path(out, "README.md"), useBytes = TRUE)

ok <- all(comparison$evidence_identical) &&
  all(comparison$canonical_attributes_identical) &&
  all(comparison$only_extra_sentence)
cat("PREVIEW_EXPERIMENT_OK=", ok, "\n", sep = "")
