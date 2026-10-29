repo <- "/Users/sebastienle/Documents/GitHub/NaileR"
out <- file.path(repo, "dev/operational_validation/catdes_enrichment/gemini_retry_20261029")
dir.create(out, recursive = TRUE, showWarnings = FALSE)

if (!nzchar(Sys.getenv("GEMINI_API_KEY"))) {
  stop("GEMINI_API_KEY is not available in this R process.", call. = FALSE)
}

devtools::load_all(repo, quiet = TRUE)
data(atomic_habit_clust, package = "NaileR")

introduction <- paste(
  "This study examines respondents' perceived ability to adopt",
  "environmentally relevant everyday practices and the",
  "restrictions they associate with these practices.",
  "The questions cover consumption choices, household practices,",
  "diet, mobility, and other everyday behaviors.",
  "",
  "Respondents have been classified into three groups according",
  "to their response patterns. The objective is to understand",
  "the distinctive configurations of perceived capability and",
  "constraints characterizing these groups.",
  "",
  "The statistical characterization concerns reported perceptions,",
  "not verified behaviors. Open-ended comments about using a car",
  "when traveling alone will subsequently be used to enrich and",
  "critically reassess the initial statistical interpretations.",
  sep = "\n"
)

request <- paste(
  "Identify and interpret the main configurations of perceived",
  "capability and practical constraints that distinguish the",
  "three respondent groups.",
  "",
  "For each group, develop a coherent substantive profile from",
  "the joint interpretation of the retained statistical markers,",
  "rather than describing variables individually.",
  "",
  "Compare the groups, identify the most meaningful contrasts",
  "and complementarities, and distinguish central patterns from",
  "secondary or ambiguous characteristics.",
  "",
  "Pay particular attention to the smaller group 2 and avoid",
  "overstating the generality of its characteristics.",
  "",
  "Propose interpretive group labels only when sufficiently",
  "supported by the statistical evidence.",
  sep = "\n"
)

retry_messages <- character()
started <- Sys.time()
result <- withCallingHandlers(tryCatch(
  nail_catdes(
    dataset = atomic_habit_clust,
    num.var = 51,
    num.textual = 31,
    textual.sample = 0.5,
    textual.seed = 123,
    interpretation_mode = "latent",
    isolate.groups = FALSE,
    introduction = introduction,
    request = request,
    provider = "gemini",
    model = "gemini-2.5-flash",
    max_output_tokens = 8192L,
    max_tries = 5L,
    backoff_base = 2,
    backoff_cap = 16,
    verbose = TRUE,
    timeout = 90,
    generate = TRUE
  ),
  error = function(error) error
), message = function(message) {
  retry_messages <<- c(
    retry_messages,
    paste(format(Sys.time(), "%Y-%m-%d %H:%M:%S %z"), conditionMessage(message))
  )
  invokeRestart("muffleMessage")
})
elapsed <- as.numeric(difftime(Sys.time(), started, units = "secs"))
writeLines(retry_messages, file.path(out, "RETRY_LOG.txt"), useBytes = TRUE)

saveRDS(
  list(
    result = if (inherits(result, "error")) NULL else result,
    error = if (inherits(result, "error")) conditionMessage(result) else NULL,
    elapsed_seconds = elapsed,
    parameters = list(
      num.var = 51L,
      num.textual = 31L,
      textual.sample = 0.5,
      textual.seed = 123L,
      interpretation_mode = "latent",
      isolate.groups = FALSE,
      provider = "gemini",
      model = "gemini-2.5-flash",
      max_output_tokens = 8192L,
      max_tries = 5L,
      backoff_base = 2,
      backoff_cap = 16,
      verbose = TRUE,
      timeout = 90L,
      generate = TRUE
    )
  ),
  file.path(out, "CATDES_ENRICHMENT_GEMINI_RESULT.rds")
)

if (inherits(result, "error")) {
  writeLines(
    c(
      "status: error",
      paste0("elapsed_seconds: ", format(elapsed, scientific = FALSE)),
      paste0("error: ", conditionMessage(result))
    ),
    file.path(out, "GENERATION_ERROR.txt"),
    useBytes = TRUE
  )
  quit(save = "no", status = 1L)
}

enrichment <- nail_catdes_enrichment(result)
prompt <- nail_prompt(result, print = FALSE)
evidence <- nail_evidence(result)

writeLines(prompt, file.path(out, "PASS1_PROMPT.txt"), useBytes = TRUE)
writeLines(enrichment$first_pass$prompts$portfolio,
           file.path(out, "PASS1_PROMPT_FROM_ENRICHMENT.txt"),
           useBytes = TRUE)
writeLines(enrichment$first_pass$responses$portfolio,
           file.path(out, "PASS1_RESPONSE.txt"), useBytes = TRUE)
writeLines(enrichment$second_pass$prompts$portfolio,
           file.path(out, "PASS2_PROMPT.txt"), useBytes = TRUE)
writeLines(enrichment$second_pass$responses$portfolio,
           file.path(out, "PASS2_RESPONSE.txt"), useBytes = TRUE)

saveRDS(
  list(
    result = result,
    enrichment = enrichment,
    evidence = evidence,
    prompt = prompt,
    parameters = list(
      model = "gemini-2.5-flash",
      provider = "gemini",
      max_output_tokens = 8192L,
      max_tries = 5L,
      timeout = 90L,
      elapsed_seconds = elapsed
    )
  ),
  file.path(out, "CATDES_ENRICHMENT_GEMINI_FULL.rds")
)

write.csv(
  enrichment$selected_texts[, c("text_id", "group", "source_row")],
  file.path(out, "SELECTED_TEXT_IDS.csv"),
  row.names = FALSE
)
write.csv(
  evidence$evidence_registry,
  file.path(out, "EVIDENCE_REGISTRY.csv"),
  row.names = FALSE
)

writeLines(
  c(
    "status: generated",
    "first_pass_status: generated",
    paste0("second_pass_status: ", enrichment$second_pass$status[[1L]]),
    paste0("elapsed_seconds: ", format(elapsed, scientific = FALSE)),
    paste0("first_prompt_characters: ", nchar(enrichment$first_pass$prompts$portfolio)),
    paste0("first_response_characters: ", nchar(enrichment$first_pass$responses$portfolio)),
    paste0("second_prompt_characters: ", nchar(enrichment$second_pass$prompts$portfolio)),
    paste0("second_response_characters: ", nchar(enrichment$second_pass$responses$portfolio)),
    "api_key_recorded: false",
    "retry_policy: backend max_tries = 5; no external retry loop",
    "backoff_policy: base 2 seconds, cap 16 seconds, backend jitter retained",
    "retry_after: not exposed by current backend"
  ),
  file.path(out, "GENERATION_METADATA.txt"),
  useBytes = TRUE
)
