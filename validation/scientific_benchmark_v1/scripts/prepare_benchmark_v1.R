# Reproducible offline preparation of NaileR scientific benchmark prompts.
# Source commit: f697f006e04faa8f9613885ec40cd37799bd7282
# Every analysis uses generate = FALSE; no LLM backend is contacted.

options(stringsAsFactors = FALSE)
set.seed(20261016)

root <- file.path(getwd(), "validation", "scientific_benchmark_v1")
dir.create(root, recursive = TRUE, showWarnings = FALSE)
for (dir in c("study_consumer", "study_sensory", "prompts", "evidence",
              "scripts", "checks", "objects")) {
  dir.create(file.path(root, dir), recursive = TRUE, showWarnings = FALSE)
}

devtools::load_all(getwd(), quiet = TRUE)

write_exact <- function(path, text) {
  con <- file(path, open = "wb")
  on.exit(close(con), add = TRUE)
  writeBin(charToRaw(enc2utf8(as.character(text))), con)
}

sha256_file <- function(path) digest::digest(file = path, algo = "sha256")

write_text <- function(path, text) {
  writeLines(enc2utf8(text), path, useBytes = TRUE)
}

write_json <- function(path, object) {
  sanitize <- function(x) {
    if (is.language(x)) return(paste(deparse(x), collapse = ""))
    if (is.function(x)) return("<function>")
    if (is.environment(x)) return("<environment>")
    if (is.data.frame(x)) return(lapply(x, sanitize))
    if (is.list(x)) return(lapply(x, sanitize))
    x
  }
  write_text(path, jsonlite::toJSON(sanitize(object), auto_unbox = TRUE,
                                    pretty = TRUE, null = "null"))
}

prompt_paths <- character()
manifest <- list()

record_preview <- function(result, function_name, study, units,
                           evidence_object = result, arguments,
                           calls_required = 0L) {
  prompts <- nail_prompt(result, print = FALSE)
  if (!is.list(prompts)) {
    prompts <- list(prompts)
  }
  if (is.null(names(prompts))) names(prompts) <- units[seq_along(prompts)]

  evidence <- tryCatch(nail_evidence(evidence_object), error = function(e) {
    list(error = conditionMessage(e))
  })
  evidence_file <- file.path(root, "evidence",
                             paste0(function_name, "_", study, ".json"))
  write_json(evidence_file, evidence)

  usage <- tryCatch(nail_usage(result), error = function(e) {
    data.frame(error = conditionMessage(e))
  })
  if (is.data.frame(usage) && nrow(usage) != 0L) {
    stop("A generate = FALSE preview unexpectedly reports an LLM call.")
  }
  utils::write.csv(usage, file.path(root, "checks",
                                    paste0(function_name, "_", study,
                                          "_usage.csv")), row.names = FALSE)

  for (unit in names(prompts)) {
    safe_unit <- gsub("[^A-Za-z0-9_.-]+", "_", unit)
    prompt_file <- file.path(root, "prompts",
                             paste0(function_name, "_", study, "_",
                                    safe_unit, ".txt"))
    write_exact(prompt_file, prompts[[unit]])
    prompt_paths <<- c(prompt_paths, prompt_file)
    manifest[[length(manifest) + 1L]] <<- data.frame(
      `function` = function_name,
      study = study,
      unit = unit,
      prompt_file = file.path("prompts", basename(prompt_file)),
      evidence_file = file.path("evidence", basename(evidence_file)),
      prompt_sha256 = sha256_file(prompt_file),
      arguments = paste(names(arguments), unlist(arguments), sep = "=",
                        collapse = "; "),
      preparation_status = "preview_ready",
      llm_calls_required = as.integer(calls_required),
      stringsAsFactors = FALSE
    )
  }
  invisible(list(prompts = prompts, evidence = evidence, usage = usage))
}

run_checked <- function(label, expression) {
  tryCatch(
    list(ok = TRUE, value = force(expression), error = NULL),
    error = function(e) {
      write_text(file.path(root, "checks", paste0(label, "_ERROR.txt")),
                 conditionMessage(e))
      list(ok = FALSE, value = NULL, error = conditionMessage(e))
    }
  )
}

make_consumer_data <- function(n = 96L) {
  group <- factor(rep(c("G1", "G2", "G3"), each = n / 3L),
                  levels = c("G1", "G2", "G3"))
  group_index <- as.integer(group)
  age <- round(pmax(18, pmin(75,
    rnorm(n, c(34, 46, 39)[group_index], 7))))
  household_size <- pmax(1L, rpois(n, c(2.2, 3.1, 2.6)[group_index]))
  purchase_frequency <- round(pmax(1,
    rnorm(n, c(2.8, 4.3, 3.4)[group_index], .9)), 1)
  monthly_spend <- round(pmax(15,
    rnorm(n, c(95, 155, 125)[group_index], 30)), 0)
  satisfaction <- round(pmax(1, pmin(10,
    rnorm(n, c(6.3, 7.6, 5.9)[group_index] +
      .20 * purchase_frequency - .006 * monthly_spend, .8))), 1)
  diet <- factor(vapply(group_index, function(g) {
    sample(c("conventional", "flexitarian", "vegetarian"), 1,
           prob = list(c(.60, .28, .12), c(.30, .50, .20),
                       c(.45, .35, .20))[[g]])
  }, character(1)), levels = c("conventional", "flexitarian", "vegetarian"))
  channel <- factor(vapply(group_index, function(g) {
    sample(c("supermarket", "online", "local_market"), 1,
           prob = list(c(.55, .25, .20), c(.25, .55, .20),
                       c(.35, .30, .35))[[g]])
  }, character(1)), levels = c("supermarket", "online", "local_market"))
  concern <- factor(vapply(group_index, function(g) {
    sample(c("price", "convenience", "quality", "environment"), 1,
           prob = list(c(.35, .30, .25, .10), c(.18, .36, .28, .18),
                       c(.18, .20, .30, .32))[[g]])
  }, character(1)), levels = c("price", "convenience", "quality", "environment"))
  comment <- vapply(seq_len(n), function(i) {
    base <- switch(as.character(group[[i]]),
      G1 = sample(c(
        "I like the familiar taste and the price is manageable, although the choice is limited.",
        "It is convenient after work, but I sometimes question the quality of the ingredients.",
        "The offer feels balanced; I would like clearer information about its environmental impact."
      ), 1),
      G2 = sample(c(
        "The variety and quality are convincing, even if shopping this way costs more than planned.",
        "Online ordering saves time, but delivery is not always convenient or reliable.",
        "I feel satisfied with the choice, although I still compare prices before buying."
      ), 1),
      G3 = sample(c(
        "Local products feel more responsible, but they are not always easy to find.",
        "I appreciate the quality, yet the environmental claim is difficult to verify.",
        "The experience can be pleasant, although the price sometimes outweighs the benefits."
      ), 1))
    if (i %% 11L == 0L) paste(base, "Still, this is not true for every purchase.") else base
  }, character(1))
  data.frame(
    group = group,
    respondent_id = sprintf("C%03d", seq_len(n)),
    age = age,
    household_size = household_size,
    purchase_frequency = purchase_frequency,
    monthly_spend = monthly_spend,
    satisfaction = satisfaction,
    diet = diet,
    channel = channel,
    concern = concern,
    comment = comment,
    stringsAsFactors = TRUE
  )
}

consumer <- make_consumer_data()
consumer_stats <- consumer[setdiff(names(consumer), c("respondent_id", "comment"))]
utils::write.csv(consumer, file.path(root, "study_consumer", "consumer_data.csv"),
                 row.names = FALSE)
utils::write.csv(consumer_stats,
                 file.path(root, "study_consumer", "consumer_statistics.csv"),
                 row.names = FALSE)
write_text(file.path(root, "study_consumer", "DATA_GENERATION.md"), c(
  "# Consumer study data", "",
  "The data are synthetic and reproducible, generated with set.seed(20261016).",
  "There are 96 consumers, balanced across neutral groups G1, G2 and G3.",
  "Group-specific distributions create plausible but non-deterministic",
  "differences in behavior, satisfaction and open comments. Individual IDs",
  "C001--C096 link the statistical and textual tables.",
  "The generation mechanism is documented here for reproducibility only; it",
  "is not supplied as an observed fact to any interpretation prompt."
))
write_text(file.path(root, "study_consumer", "CONTEXT.md"), c(
  "# Consumer study context", "",
  "The study examines how consumers describe and evaluate everyday food",
  "purchasing choices. Three neutral groups, G1, G2 and G3, come from the",
  "same population. The aim is to characterize group profiles without",
  "assuming that every member shares the same behavior or opinion.",
  "Open comments are individual responses and may contain tensions or",
  "minority positions. They are not causal evidence."
))
consumer_intro <- paste(
  "This study examines food-purchasing behavior in 96 consumers from the same",
  "population, organized into three neutral groups named G1, G2 and G3.",
  "The data combine quantitative measures, categorical characteristics, and",
  "individual open comments. The purpose is to characterize patterns while",
  "preserving within-group heterogeneity and distinguishing observations from",
  "interpretive hypotheses."
)
requests <- list(
  condes = paste(
    "Characterize the substantive profile associated with satisfaction from",
    "the statistical associations shown. Synthesize convergent facts, keep",
    "interpretation traceable, and distinguish observed associations from",
    "broader hypotheses. Do not infer causality."
  ),
  catdes = paste(
    "For each group, describe the main coherent profile from the displayed",
    "statistical facts. Distinguish central interpretive patterns from",
    "secondary characteristics and do not infer causality or individual",
    "properties from group-level results."
  ),
  descfreq = paste(
    "Describe the main frequency profile of the groups from the displayed",
    "relative frequencies. Synthesize convergent patterns without treating",
    "a frequency difference as an absolute preference or causal effect."
  ),
  textual = paste(
    "Identify recurring themes and meaningful tensions in the comments.",
    "Synthesize several responses when justified, preserve minority positions",
    "and distinguish what respondents literally expressed from contextual",
    "interpretation. Do not infer hidden motivations."
  )
)
write_text(file.path(root, "study_consumer", "INTRODUCTIONS_AND_REQUESTS.md"), c(
  "# Shared study introduction", "", consumer_intro, "",
  "# CONDES request", "", requests$condes, "",
  "# CATDES request", "", requests$catdes, "",
  "# DESCFREQ request", "", requests$descfreq, "",
  "# TEXTUAL request", "", requests$textual
))

condes <- run_checked("condes_consumer", nail_condes(
  dataset = consumer_stats, num.var = 6,
  introduction = consumer_intro, request = requests$condes,
  target_concept = "consumer satisfaction", target_label = "satisfaction",
  provider = "gemini", model = "gemini-2.5-flash", generate = FALSE
))
if (condes$ok) {
  saveRDS(condes$value, file.path(root, "objects", "condes_consumer.rds"))
  record_preview(condes$value, "nail_condes", "consumer", "satisfaction",
                 arguments = list(num.var = 6, provider = "gemini",
                                  model = "gemini-2.5-flash", generate = FALSE),
                 calls_required = 1L)
}

catdes <- run_checked("catdes_consumer", nail_catdes(
  dataset = consumer_stats, num.var = 1,
  introduction = consumer_intro, request = requests$catdes,
  isolate.groups = FALSE, provider = "gemini",
  model = "gemini-2.5-flash", generate = FALSE
))
if (catdes$ok) {
  saveRDS(catdes$value, file.path(root, "objects", "catdes_consumer.rds"))
  record_preview(catdes$value, "nail_catdes", "consumer", "portfolio",
                 arguments = list(num.var = 1, isolate.groups = FALSE,
                                  provider = "gemini",
                                  model = "gemini-2.5-flash", generate = FALSE),
                 calls_required = 1L)
}

freq <- as.data.frame.matrix(table(consumer$group, consumer$channel))
freq <- freq[, c("supermarket", "online", "local_market"), drop = FALSE]
write.csv(freq, file.path(root, "study_consumer", "group_channel_table.csv"))
descfreq <- run_checked("descfreq_consumer", nail_descfreq(
  dataset = freq, introduction = consumer_intro, request = requests$descfreq,
  isolate.groups = FALSE, rows_are_ordered = TRUE,
  explicit_row_labels = TRUE, row_identity_mode = "standard",
  provider = "gemini", model = "gemini-2.5-flash", generate = FALSE
))
if (descfreq$ok) {
  saveRDS(descfreq$value, file.path(root, "objects", "descfreq_consumer.rds"))
  record_preview(descfreq$value, "nail_descfreq", "consumer", "all_rows",
                 arguments = list(isolate.groups = FALSE,
                                  rows_are_ordered = TRUE,
                                  explicit_row_labels = TRUE,
                                  row_identity_mode = "standard",
                                  provider = "gemini",
                                  model = "gemini-2.5-flash", generate = FALSE),
                 calls_required = 1L)
}

textual <- run_checked("textual_consumer", nail_textual(
  dataset = consumer[, c("group", "respondent_id", "comment")],
  num.var = 1, num.text = 3, introduction = consumer_intro,
  request = requests$textual, isolate.groups = TRUE, sample.pct = 1,
  seed = 42, prompt_style = "detailed", text_role = "comments",
  provider = "gemini", model = "gemini-2.5-flash", generate = FALSE
))
if (textual$ok) {
  saveRDS(textual$value, file.path(root, "objects", "textual_consumer.rds"))
  record_preview(textual$value, "nail_textual", "consumer",
                 c("G1", "G2", "G3"),
                 arguments = list(num.var = 1, num.text = 3,
                                  isolate.groups = TRUE, sample.pct = 1,
                                  seed = 42, prompt_style = "detailed",
                                  text_role = "comments", provider = "gemini",
                                  model = "gemini-2.5-flash", generate = FALSE),
                 calls_required = 3L)
  textual_evidence <- attr(textual$value, "textual_evidence", exact = TRUE)
  stopifnot(identical(names(textual$value), levels(consumer$group)))
  stopifnot(identical(textual_evidence$metadata$n_texts, nrow(consumer)))
  stopifnot(identical(textual_evidence$text_registry$text_id,
                      sprintf("TXT%06d", seq_len(nrow(consumer)))))
  stopifnot(identical(textual_evidence$text_registry$source_row,
                      seq_len(nrow(consumer))))
}

if (catdes$ok && textual$ok) {
  write_text(file.path(root, "checks", "catdes_textual_deferred.txt"), c(
    "CATDES-TEXTUAL composition is intentionally deferred in benchmark v1.",
    "The public function requires textual = nail_textual(generate = TRUE)",
    "with successfully parsed textual_profiles; a generate = FALSE textual",
    "preview therefore cannot be passed to nail_catdes_textual(). No mock",
    "LLM response is introduced in this offline prompt-only benchmark."
  ))
}

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
write_text(file.path(root, "study_sensory", "CONTEXT_AND_REQUESTS.md"), c(
  "# Introduction", "", sensory_intro, "", "# Request", "", sensory_request,
  "", "# Conclusion", "", sensory_conclusion
))
data("chocolates", package = "SensoMineR")
write_text(file.path(root, "study_sensory", "DATA_SOURCE.md"), c(
  "# Sensory data source", "",
  "The benchmark uses SensoMineR::sensochoc from the installed SensoMineR",
  "package, with data(chocolates) loaded as in the documented workflow.",
  "No sensory data are synthesized or altered by this script."
))

qda <- run_checked("qda_sensochoc", nail_qda(
  dataset = sensochoc, formul = "~Product+Panelist", firstvar = 5,
  introduction = sensory_intro, request = sensory_request,
  conclusion = sensory_conclusion, isolate.groups = FALSE, sample.pct = 1,
  provider = "gemini", model = "gemini-2.5-flash", generate = FALSE
))
if (qda$ok) {
  saveRDS(qda$value, file.path(root, "objects", "qda_sensochoc.rds"))
  record_preview(qda$value, "nail_qda", "sensory", "portfolio",
                 arguments = list(formul = "~Product+Panelist", firstvar = 5,
                                  isolate.groups = FALSE, sample.pct = 1,
                                  provider = "gemini",
                                  model = "gemini-2.5-flash", generate = FALSE),
                 calls_required = 1L)

  qda_space <- run_checked("qda_space_sensochoc", nail_qda_space(
    x = qda$value, ncp = 1, min_inertia_pct = 10,
    condes_proba = 0.05, expertise_mode = "sensory",
    introduction = sensory_intro, request = sensory_request,
    conclusion = sensory_conclusion, provider = "gemini",
    model = "gemini-2.5-flash", generate = FALSE
  ))
  if (qda_space$ok) {
    saveRDS(qda_space$value,
            file.path(root, "objects", "qda_space_sensochoc.rds"))
    record_preview(qda_space$value, "nail_qda_space", "sensory", "Dim1",
                   arguments = list(ncp = 1, min_inertia_pct = 10,
                                    condes_proba = 0.05,
                                    expertise_mode = "sensory",
                                    provider = "gemini",
                                    model = "gemini-2.5-flash", generate = FALSE),
                   calls_required = 1L)
  }
}

if (length(manifest)) {
  manifest_df <- do.call(rbind, manifest)
  names(manifest_df)[names(manifest_df) == "function."] <- "function"
  utils::write.csv(manifest_df, file.path(root, "MANIFEST.csv"),
                   row.names = FALSE)
}

checks <- c(
  "source_commit=f697f006e04faa8f9613885ec40cd37799bd7282",
  paste0("consumer_rows=", nrow(consumer)),
  paste0("consumer_groups=", paste(levels(consumer$group), collapse = ",")),
  paste0("textual_groups=", if (textual$ok) paste(names(textual$value),
                                                   collapse = ",") else "ERROR"),
  paste0("condes_preview=", condes$ok),
  paste0("catdes_preview=", catdes$ok),
  paste0("descfreq_preview=", descfreq$ok),
  paste0("textual_preview=", textual$ok),
  paste0("qda_preview=", qda$ok),
  paste0("qda_space_preview=", if (exists("qda_space")) qda_space$ok else FALSE),
  "preview_usage_rows_zero=TRUE",
  "llm_calls_executed=0",
  "all_prompts_written_as_exact_utf8_bytes=TRUE"
)
write_text(file.path(root, "checks", "offline_checks.txt"), checks)
cat(paste(checks, collapse = "\n"), "\n")
