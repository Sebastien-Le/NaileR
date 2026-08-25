# =============================================================================
# NaileR operational stabilization — book baseline / end-to-end campaign
# Purpose:
#   1. validate book-facing calls with optional real LLM generation;
#   2. verify homogeneous access through nail_evidence(), nail_prompt(),
#      and nail_response();
#   3. persist inspectable artifacts for each analysis;
#   4. create a ZIP archive that can be shared for external audit.
#
# Recommended execution from the NaileR RStudio project:
#   source("dev/NaileR_operational_book_baseline.R", echo = FALSE)
#
# Running the file as one script is intentional: it avoids spurious RStudio
# post-evaluation inspection errors sometimes seen when ordinary expressions are
# executed line by line in the Console.
# =============================================================================

library(NaileR)

# -----------------------------------------------------------------------------
# 0. Global settings
# -----------------------------------------------------------------------------

RUN_LLM <- FALSE  # Set TRUE for the full end-to-end LLM campaign
NAILER_PROVIDER <- "ollama"
NAILER_MODEL <- "mistral-small3.2"

RUN_ID <- format(Sys.time(), "%Y%m%d_%H%M%S")
RESULTS_DIR <- file.path(
  getwd(),
  paste0("NaileR_stabilization_", if (RUN_LLM) "TRUE_" else "FALSE_", RUN_ID)
)
ZIP_FILE <- paste0(RESULTS_DIR, ".zip")

dir.create(RESULTS_DIR, recursive = TRUE, showWarnings = FALSE)
dir.create(file.path(RESULTS_DIR, "summary"), showWarnings = FALSE)

# Capture the script itself when sourced from a file.
SCRIPT_PATH <- tryCatch(
  normalizePath(sys.frame(1)$ofile, mustWork = TRUE),
  error = function(e) NA_character_
)
if (!is.na(SCRIPT_PATH)) {
  file.copy(
    SCRIPT_PATH,
    file.path(RESULTS_DIR, basename(SCRIPT_PATH)),
    overwrite = TRUE
  )
}

# -----------------------------------------------------------------------------
# Audit helpers
# -----------------------------------------------------------------------------

audit_log <- data.frame(
  analysis = character(0),
  unit = character(0),
  analysis_ok = logical(0),
  evidence_ok = logical(0),
  prompt_ok = logical(0),
  response_ok = logical(0),
  message = character(0),
  stringsAsFactors = FALSE
)

error_log <- data.frame(
  analysis = character(0),
  stage = character(0),
  message = character(0),
  stringsAsFactors = FALSE
)

add_error <- function(analysis, stage, message) {
  error_log <<- rbind(
    error_log,
    data.frame(
      analysis = analysis,
      stage = stage,
      message = as.character(message),
      stringsAsFactors = FALSE
    )
  )
  invisible(NULL)
}

write_text <- function(x, file) {
  x <- as.character(x)
  writeLines(x, con = file, useBytes = TRUE)
  invisible(file)
}

write_print <- function(x, file) {
  txt <- capture.output(print(x))
  write_text(txt, file)
}

write_structure <- function(x, file) {
  txt <- capture.output(str(x, max.level = 3, give.attr = TRUE))
  write_text(txt, file)
}

safe_call <- function(analysis, stage, expr) {
  tryCatch(
    force(expr),
    error = function(e) {
      add_error(analysis, stage, conditionMessage(e))
      message(
        "[", analysis, "] ", stage, " FAILED: ", conditionMessage(e)
      )
      NULL
    }
  )
}

first_name <- function(x) {
  if (is.null(x) || length(x) == 0L) return(NULL)
  names_x <- names(x)
  if (is.null(names_x) || length(names_x) == 0L || !nzchar(names_x[[1L]])) {
    return(1L)
  }
  names_x[[1L]]
}

save_case <- function(analysis, x, select = NULL) {
  case_dir <- file.path(RESULTS_DIR, analysis)
  dir.create(case_dir, recursive = TRUE, showWarnings = FALSE)

  if (is.null(x)) {
    audit_log <<- rbind(
      audit_log,
      data.frame(
        analysis = analysis,
        unit = if (is.null(select)) "<all>" else as.character(select),
        analysis_ok = FALSE,
        evidence_ok = FALSE,
        prompt_ok = FALSE,
        response_ok = FALSE,
        message = "analysis object unavailable",
        stringsAsFactors = FALSE
      )
    )
    return(invisible(NULL))
  }

  # Keep the complete object for reproducibility.
  tryCatch(
    saveRDS(x, file.path(case_dir, "result.rds")),
    error = function(e) add_error(analysis, "save result.rds", conditionMessage(e))
  )
  write_structure(x, file.path(case_dir, "result_structure.txt"))

  complete_evidence <- safe_call(
    analysis,
    "nail_evidence complete",
    nail_evidence(x)
  )

  if (!is.null(complete_evidence)) {
    tryCatch(
      saveRDS(complete_evidence, file.path(case_dir, "evidence_complete.rds")),
      error = function(e) add_error(
        analysis,
        "save evidence_complete.rds",
        conditionMessage(e)
      )
    )
    write_structure(
      complete_evidence,
      file.path(case_dir, "evidence_complete_structure.txt")
    )
  }

  selected_evidence <- safe_call(
    analysis,
    "nail_evidence selected",
    nail_evidence(x, select = select)
  )

  evidence_ok <- !is.null(selected_evidence)
  if (evidence_ok) {
    tryCatch(
      saveRDS(selected_evidence, file.path(case_dir, "evidence_selected.rds")),
      error = function(e) add_error(
        analysis,
        "save evidence_selected.rds",
        conditionMessage(e)
      )
    )
    write_print(
      selected_evidence,
      file.path(case_dir, "evidence_selected.txt")
    )
  }

  prompt <- safe_call(
    analysis,
    "nail_prompt",
    nail_prompt(x, select = select, print = FALSE)
  )

  prompt_ok <- is.character(prompt) &&
    length(prompt) == 1L &&
    !is.na(prompt) &&
    nzchar(prompt)

  if (prompt_ok) {
    write_text(prompt, file.path(case_dir, "prompt.md"))
  }

  response <- NULL
  response_ok <- !isTRUE(RUN_LLM)

  if (isTRUE(RUN_LLM)) {
    response <- safe_call(
      analysis,
      "nail_response",
      nail_response(x, select = select, print = FALSE)
    )

    response_ok <- is.character(response) &&
      length(response) == 1L &&
      !is.na(response) &&
      nzchar(response)

    if (response_ok) {
      write_text(response, file.path(case_dir, "response.md"))
    }
  }

  message_text <- if (
    evidence_ok && prompt_ok && response_ok
  ) {
    "OK"
  } else {
    paste(
      c(
        if (!evidence_ok) "evidence unavailable" else NULL,
        if (!prompt_ok) "prompt unavailable" else NULL,
        if (!response_ok) "response unavailable" else NULL
      ),
      collapse = "; "
    )
  }

  audit_log <<- rbind(
    audit_log,
    data.frame(
      analysis = analysis,
      unit = if (is.null(select)) "<all>" else as.character(select),
      analysis_ok = TRUE,
      evidence_ok = evidence_ok,
      prompt_ok = prompt_ok,
      response_ok = response_ok,
      message = message_text,
      stringsAsFactors = FALSE
    )
  )

  message("[", analysis, "] access contract: ", message_text)
  invisible(
    list(
      evidence = selected_evidence,
      prompt = prompt,
      response = response
    )
  )
}

# -----------------------------------------------------------------------------
# Run metadata
# -----------------------------------------------------------------------------

git_value <- function(args) {
  out <- tryCatch(
    system2("git", args, stdout = TRUE, stderr = TRUE),
    error = function(e) character(0)
  )
  if (length(out) == 0L) NA_character_ else paste(out, collapse = "\n")
}

metadata <- c(
  paste0("run_id: ", RUN_ID),
  paste0("run_llm: ", RUN_LLM),
  paste0("provider: ", NAILER_PROVIDER),
  paste0("model: ", NAILER_MODEL),
  paste0("working_directory: ", getwd()),
  paste0("NaileR_version: ", as.character(utils::packageVersion("NaileR"))),
  paste0("R_version: ", R.version.string),
  paste0("git_branch: ", git_value(c("branch", "--show-current"))),
  paste0("git_commit: ", git_value(c("rev-parse", "--short", "HEAD")))
)
write_text(metadata, file.path(RESULTS_DIR, "00_run_metadata.txt"))

book_contract <- c(
  "NaileR book-facing public grammar",
  "=================================",
  "",
  "res <- nail_xxx(...)",
  "nail_evidence(res, select = ...)",
  "nail_prompt(res, select = ...)",
  "nail_response(res, select = ...)",
  "",
  "The analysis-specific internal attributes are deliberately not part of this contract."
)
write_text(book_contract, file.path(RESULTS_DIR, "00_book_contract.txt"))

message("NaileR stabilization TRUE campaign")
message("Results directory: ", RESULTS_DIR)
message("Provider/model: ", NAILER_PROVIDER, " / ", NAILER_MODEL)

# =============================================================================
# 1. QDA — product sensory profiles
# =============================================================================

message("\n[1/9] QDA")
data(chocolates, package = "SensoMineR")

res_qda <- safe_call(
  "01_qda",
  "analysis",
  nail_qda(
    dataset = sensochoc,
    formul = "~Product+Panelist",
    firstvar = 5,
    isolate.groups = TRUE,
    product_knowledge = "known",
    provider = NAILER_PROVIDER,
    model = NAILER_MODEL,
    generate = RUN_LLM
  )
)

qda_product <- NULL
if (!is.null(res_qda)) {
  qda_evidence <- safe_call("01_qda", "find product", nail_evidence(res_qda))
  if (!is.null(qda_evidence)) qda_product <- first_name(qda_evidence$products)
}
save_case("01_qda", res_qda, select = qda_product)

# =============================================================================
# 2. QDA SPACE — product-space geometry
# =============================================================================

message("\n[2/9] QDA space")
res_qda_space <- if (!is.null(res_qda)) {
  safe_call(
    "02_qda_space",
    "analysis",
    nail_qda_space(
      x = res_qda,
      ncp = 2,
      expertise_mode = "sensory",
      provider = NAILER_PROVIDER,
      model = NAILER_MODEL,
      generate = RUN_LLM
    )
  )
} else {
  add_error("02_qda_space", "analysis", "Skipped because QDA failed")
  NULL
}

qda_axis <- NULL
if (!is.null(res_qda_space)) {
  qda_space_evidence <- safe_call(
    "02_qda_space",
    "find axis",
    nail_evidence(res_qda_space)
  )
  if (!is.null(qda_space_evidence)) qda_axis <- first_name(qda_space_evidence$axes)
}
save_case("02_qda_space", res_qda_space, select = qda_axis)

# =============================================================================
# 3. CONDES — observed continuous variable
# =============================================================================

message("\n[3/9] CONDES observed")
data(decathlon, package = "FactoMineR")

res_condes <- safe_call(
  "03_condes_observed",
  "analysis",
  nail_condes(
    dataset = decathlon,
    num.var = 12,
    interpretation_mode = "standard",
    provider = NAILER_PROVIDER,
    model = NAILER_MODEL,
    generate = RUN_LLM
  )
)
save_case("03_condes_observed", res_condes)

# =============================================================================
# 4. CONDES — latent PCA dimension
# =============================================================================

message("\n[4/9] CONDES latent")

# These preparatory expressions are intentionally run inside the sourced script.
# If RStudio previously displayed `.rs.exprMutatesPackageLibrary(part)`, that was
# an IDE post-evaluation issue: the assignments themselves were successful.
decathlon_active <- decathlon[, seq_len(10L), drop = FALSE]

pca_decathlon <- safe_call(
  "04_condes_latent",
  "PCA preparation",
  FactoMineR::PCA(
    decathlon_active,
    scale.unit = TRUE,
    graph = FALSE
  )
)

latent_data <- if (!is.null(pca_decathlon)) {
  data.frame(
    Dim1 = pca_decathlon$ind$coord[, 1L],
    decathlon_active,
    check.names = FALSE
  )
} else {
  NULL
}

res_condes_latent <- if (!is.null(latent_data)) {
  safe_call(
    "04_condes_latent",
    "analysis",
    nail_condes(
      dataset = latent_data,
      num.var = 1,
      interpretation_mode = "latent",
      target_label = "Dim1",
      provider = NAILER_PROVIDER,
      model = NAILER_MODEL,
      generate = RUN_LLM
    )
  )
} else {
  NULL
}
save_case("04_condes_latent", res_condes_latent)

# =============================================================================
# 5. CATDES — observed categories
# =============================================================================

message("\n[5/9] CATDES observed")
res_catdes <- safe_call(
  "05_catdes_observed",
  "analysis",
  nail_catdes(
    dataset = iris,
    num.var = 5,
    interpretation_mode = "standard",
    isolate.groups = TRUE,
    provider = NAILER_PROVIDER,
    model = NAILER_MODEL,
    generate = RUN_LLM
  )
)

catdes_group <- NULL
if (!is.null(res_catdes)) {
  catdes_evidence <- safe_call(
    "05_catdes_observed",
    "find group",
    nail_evidence(res_catdes)
  )
  if (!is.null(catdes_evidence)) catdes_group <- first_name(catdes_evidence$groups)
}
save_case("05_catdes_observed", res_catdes, select = catdes_group)

# =============================================================================
# 6. CATDES — latent / constructed groups
# =============================================================================

message("\n[6/9] CATDES latent")
data(atomic_habit_clust, package = "NaileR")

catdes_latent_data <- atomic_habit_clust[, c(seq_len(20L), 51L), drop = FALSE]

res_catdes_latent <- safe_call(
  "06_catdes_latent",
  "analysis",
  nail_catdes(
    dataset = catdes_latent_data,
    num.var = ncol(catdes_latent_data),
    interpretation_mode = "latent",
    isolate.groups = TRUE,
    provider = NAILER_PROVIDER,
    model = NAILER_MODEL,
    generate = RUN_LLM
  )
)

latent_group <- NULL
if (!is.null(res_catdes_latent)) {
  catdes_latent_evidence <- safe_call(
    "06_catdes_latent",
    "find group",
    nail_evidence(res_catdes_latent)
  )
  if (!is.null(catdes_latent_evidence)) {
    latent_group <- first_name(catdes_latent_evidence$groups)
  }
}
save_case("06_catdes_latent", res_catdes_latent, select = latent_group)

# =============================================================================
# 7. DESCFREQ — contingency / CATA-type frequency profiles
# =============================================================================

message("\n[7/9] DESCFREQ")
data(beard_cont, package = "NaileR")

res_descfreq <- safe_call(
  "07_descfreq",
  "analysis",
  nail_descfreq(
    dataset = beard_cont,
    interpretation_mode = "description",
    isolate.groups = TRUE,
    explicit_row_labels = FALSE,
    provider = NAILER_PROVIDER,
    model = NAILER_MODEL,
    generate = RUN_LLM
  )
)

descfreq_row <- NULL
if (!is.null(res_descfreq)) {
  descfreq_evidence <- safe_call(
    "07_descfreq",
    "find row",
    nail_evidence(res_descfreq)
  )
  if (!is.null(descfreq_evidence)) descfreq_row <- first_name(descfreq_evidence$rows)
}
save_case("07_descfreq", res_descfreq, select = descfreq_row)

# =============================================================================
# 8. TEXTUAL — grouped open-ended responses
# =============================================================================

message("\n[8/9] TEXTUAL")
data(fabric, package = "NaileR")

# Explicit base indexing is retained, but the whole campaign should be sourced
# rather than executed expression-by-expression in the RStudio Console.
fabric_A <- fabric[fabric$Fabric == "A", , drop = FALSE]
fabric_A <- droplevels(fabric_A)

res_textual <- safe_call(
  "08_textual",
  "analysis",
  nail_textual(
    dataset = fabric_A,
    num.var = 4,
    num.text = 3,
    isolate.groups = TRUE,
    sample.pct = 0.35,
    seed = 123,
    text_role = "responses",
    provider = NAILER_PROVIDER,
    model = NAILER_MODEL,
    generate = RUN_LLM
  )
)

textual_group <- NULL
if (!is.null(res_textual)) {
  textual_evidence <- safe_call(
    "08_textual",
    "find group",
    nail_evidence(res_textual)
  )
  if (!is.null(textual_evidence)) textual_group <- first_name(textual_evidence$groups)
}
save_case("08_textual", res_textual, select = textual_group)

# =============================================================================
# 9. CATDES + TEXTUAL — statistical anchor enriched by texts
# =============================================================================

message("\n[9/9] CATDES + TEXTUAL")

# Reuse the CATDES latent result generated above instead of paying for and
# recomputing an identical CATDES analysis. Only the aligned textual analysis
# and the contextualization stage require additional generation.
contextual_text_data <- data.frame(
  group = atomic_habit_clust[[51L]],
  text = atomic_habit_clust[[31L]],
  stringsAsFactors = FALSE
)

res_txt_context <- safe_call(
  "09_catdes_textual_upstream_textual",
  "analysis",
  nail_textual(
    dataset = contextual_text_data,
    num.var = 1,
    num.text = 2,
    isolate.groups = TRUE,
    sample.pct = 0.40,
    seed = 123,
    text_role = "responses",
    provider = NAILER_PROVIDER,
    model = NAILER_MODEL,
    generate = RUN_LLM
  )
)

contextual_text_group <- NULL
if (!is.null(res_txt_context)) {
  tmp_evidence <- safe_call(
    "09_catdes_textual_upstream_textual",
    "find group",
    nail_evidence(res_txt_context)
  )
  if (!is.null(tmp_evidence)) contextual_text_group <- first_name(tmp_evidence$groups)
}
save_case(
  "09a_context_textual",
  res_txt_context,
  select = contextual_text_group
)

res_contextualized <- if (!is.null(res_catdes_latent) && !is.null(res_txt_context)) {
  safe_call(
    "09_catdes_textual",
    "analysis",
    nail_catdes_textual(
      catdes = res_catdes_latent,
      textual = res_txt_context,
      isolate.groups = TRUE,
      provider = NAILER_PROVIDER,
      model = NAILER_MODEL,
      generate = RUN_LLM
    )
  )
} else {
  add_error(
    "09_catdes_textual",
    "analysis",
    "Skipped because one or both upstream objects are unavailable"
  )
  NULL
}

contextual_group <- NULL
if (!is.null(res_contextualized)) {
  contextual_evidence <- safe_call(
    "09_catdes_textual",
    "find group",
    nail_evidence(res_contextualized)
  )
  if (!is.null(contextual_evidence)) contextual_group <- first_name(contextual_evidence$groups)
}
save_case("09_catdes_textual", res_contextualized, select = contextual_group)

# =============================================================================
# 10. Final audit files and ZIP archive
# =============================================================================

utils::write.csv(
  audit_log,
  file.path(RESULTS_DIR, "summary", "access_contract.csv"),
  row.names = FALSE
)

utils::write.csv(
  error_log,
  file.path(RESULTS_DIR, "summary", "errors.csv"),
  row.names = FALSE
)

session_txt <- capture.output(sessionInfo())
write_text(session_txt, file.path(RESULTS_DIR, "00_sessionInfo.txt"))

summary_txt <- c(
  "NaileR stabilization TRUE campaign summary",
  "=========================================",
  "",
  paste0("Completed at: ", Sys.time()),
  paste0("RUN_LLM: ", RUN_LLM),
  paste0("Provider/model: ", NAILER_PROVIDER, " / ", NAILER_MODEL),
  paste0("Number of access checks: ", nrow(audit_log)),
  paste0("Number of recorded errors: ", nrow(error_log)),
  "",
  "Access contract:",
  capture.output(print(audit_log, row.names = FALSE)),
  "",
  "Errors:",
  if (nrow(error_log) == 0L) "None" else capture.output(print(error_log, row.names = FALSE))
)
write_text(summary_txt, file.path(RESULTS_DIR, "summary", "summary.txt"))

# Build the ZIP from inside the results directory so the archive contains
# relative paths and remains easy to inspect after upload.
old_wd <- getwd()
zip_ok <- tryCatch({
  setwd(RESULTS_DIR)
  files_to_zip <- list.files(
    ".",
    recursive = TRUE,
    all.files = FALSE,
    no.. = TRUE
  )
  utils::zip(
    zipfile = ZIP_FILE,
    files = files_to_zip,
    flags = "-r9X"
  )
  TRUE
}, error = function(e) {
  add_error("archive", "zip", conditionMessage(e))
  FALSE
}, finally = {
  setwd(old_wd)
})

cat("\n============================================================\n")
cat("NaileR operational stabilization campaign completed.\n")
cat("Results directory:\n  ", RESULTS_DIR, "\n", sep = "")
cat("ZIP archive:\n  ", ZIP_FILE, "\n", sep = "")
cat("ZIP created: ", zip_ok, "\n", sep = "")
cat("Recorded errors: ", nrow(error_log), "\n", sep = "")
cat("============================================================\n")

# Return paths invisibly when sourced.
invisible(
  list(
    results_dir = RESULTS_DIR,
    zip_file = ZIP_FILE,
    audit = audit_log,
    errors = error_log
  )
)
