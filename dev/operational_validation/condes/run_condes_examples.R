#!/usr/bin/env Rscript

# Offline CONDES example bench for NaileR.
# Set NAILER_REPO to the package root when running from source. Set
# CONDES_OUTPUT_DIR to save prompts, evidence and a compact report.

repo <- Sys.getenv("NAILER_REPO", unset = getwd())
if (file.exists(file.path(repo, "DESCRIPTION"))) {
  if (!requireNamespace("devtools", quietly = TRUE)) {
    stop("Install devtools or run this script with an installed NaileR.")
  }
  devtools::load_all(repo, quiet = TRUE)
}
if (!requireNamespace("NaileR", quietly = TRUE)) {
  stop("NaileR is not available. Set NAILER_REPO or install NaileR first.")
}

output_dir <- Sys.getenv("CONDES_OUTPUT_DIR", unset = "")
if (nzchar(output_dir)) {
  dir.create(output_dir, recursive = TRUE, showWarnings = FALSE)
}

save_case <- function(label, result, metadata) {
  evidence <- NaileR::nail_evidence(result)
  prompt <- NaileR::nail_prompt(result, print = FALSE)
  if (nzchar(output_dir)) {
    saveRDS(result, file.path(output_dir, paste0(label, "_result.rds")))
    saveRDS(evidence, file.path(output_dir, paste0(label, "_evidence.rds")))
    writeLines(prompt, file.path(output_dir, paste0(label, "_prompt.txt")))
  }
  data.frame(
    case = label,
    observations = metadata$observations,
    predictors = metadata$predictors,
    active = metadata$active,
    supplementary = metadata$supplementary,
    missing = metadata$missing,
    dim1_inertia_percent = metadata$dim1_inertia_percent,
    retained_markers = nrow(evidence$evidence_registry),
    prompt_characters = nchar(prompt),
    stringsAsFactors = FALSE
  )
}

run_case <- function(label, data, mca, active, supplementary, target,
                     target_concept, introduction, request) {
  work <- data.frame(
    Dim1 = as.numeric(target),
    data,
    check.names = FALSE
  )
  result <- NaileR::nail_condes(
    dataset = work,
    num.var = 1,
    interpretation_mode = "latent",
    target_label = "Dim1",
    target_concept = target_concept,
    introduction = introduction,
    request = request,
    generate = FALSE
  )
  prompt <- NaileR::nail_prompt(result, print = FALSE)
  evidence <- NaileR::nail_evidence(result)
  stopifnot(
    length(prompt) == 1L,
    nchar(prompt) > 0L,
    nrow(evidence$evidence_registry) > 0L
  )
  save_case(
    label,
    result,
    list(
      observations = nrow(data),
      predictors = ncol(data),
      active = length(active),
      supplementary = length(supplementary),
      missing = sum(is.na(data)),
      dim1_inertia_percent = unname(mca$eig[1, 2])
    )
  )
}

same_numeric <- function(x, y, tolerance = 1e-12) {
  isTRUE(all.equal(
    unname(x),
    unname(y),
    tolerance = tolerance,
    check.attributes = FALSE
  ))
}

same_or_global_sign <- function(x, y, tolerance = 1e-12) {
  same_numeric(x, y, tolerance) || same_numeric(x, -y, tolerance)
}

cases <- list()

# Reference examples already present in the main help: an observed target and
# a PCA-derived latent target.
data(decathlon, package = "FactoMineR")
decathlon_standard <- NaileR::nail_condes(
  decathlon,
  num.var = 12,
  interpretation_mode = "standard",
  generate = FALSE
)
cases[["decathlon_standard"]] <- save_case(
  "decathlon_standard",
  decathlon_standard,
  list(
    observations = nrow(decathlon),
    predictors = ncol(decathlon) - 1L,
    active = ncol(decathlon) - 1L,
    supplementary = 0L,
    missing = sum(is.na(decathlon)),
    dim1_inertia_percent = NA_real_
  )
)
decathlon_pca <- FactoMineR::PCA(
  decathlon[, 1:10],
  scale.unit = TRUE,
  graph = FALSE
)
cases[["decathlon_pca"]] <- run_case(
  "decathlon_pca",
  decathlon[, 1:10],
  decathlon_pca,
  1:10,
  integer(),
  decathlon_pca$ind$coord[, 1],
  "athletic performance",
  "The first ten variables are quantitative athletic performance measures.",
  "Interpret the opposition between lower and higher values of the first PCA dimension without treating its sign as intrinsically meaningful."
)

# Historical ACM example: 38 active assertions and four supplementary
# personal variables.
data(agri_studies, package = "NaileR")
agri_mca <- FactoMineR::MCA(
  agri_studies,
  quali.sup = 39:42,
  graph = FALSE
)
cases[["agri_studies"]] <- run_case(
  "agri_studies",
  agri_studies,
  agri_mca,
  1:38,
  39:42,
  agri_mca$ind$coord[, 1],
  "agribusiness expectations",
  paste(
    "Students ranked 38 statements about agribusiness studies and then",
    "answered four personal questions. Dim1 is a constructed contrast in",
    "these reported expectations."
  ),
  paste(
    "Interpret the opposition between the two ends of Dim1 using the",
    "retained associations. Do not infer causes or general abilities from",
    "these reported expectations."
  )
)

# Historical ACM example: 25 active assertions and 16 supplementary
# personal/contextual variables.
data(glossophobia, package = "NaileR")
gloss_mca <- FactoMineR::MCA(
  glossophobia,
  quali.sup = 26:41,
  graph = FALSE
)
cases[["glossophobia"]] <- run_case(
  "glossophobia",
  glossophobia,
  gloss_mca,
  1:25,
  26:41,
  gloss_mca$ind$coord[, 1],
  "public-speaking perceptions",
  paste(
    "Participants ranked 25 descriptions of speaking in public and",
    "answered personal questions. Dim1 is a constructed contrast in",
    "these reported perceptions, not a clinical diagnosis."
  ),
  paste(
    "Describe the opposition between lower and higher Dim1 values from",
    "the displayed evidence, preserving uncertainty and avoiding causal",
    "or psychological claims not contained in the survey."
  )
)

# Historical AFC example: the predictors are row profiles derived from the
# same beard contingency table, not individual-level survey variables.
data(beard_cont, package = "NaileR")
beard_ca <- FactoMineR::CA(beard_cont, graph = FALSE)
beard_profiles <- sweep(
  as.matrix(beard_cont),
  1,
  rowSums(beard_cont),
  "/"
)
cases[["beard_cont"]] <- run_case(
  "beard_cont",
  beard_profiles,
  beard_ca,
  seq_len(ncol(beard_profiles)),
  integer(),
  beard_ca$row$coord[, 1],
  "beard correspondence profiles",
  paste(
    "The rows are eight observed beard types and the columns are words",
    "used to describe them. Row profiles from this same contingency table",
    "characterize the first correspondence dimension."
  ),
  paste(
    "Describe the opposition between the two ends of the first AFC",
    "dimension from the displayed row-profile evidence. Do not treat it",
    "as an individual-level survey or infer causes."
  )
)

# MASHS / local_food: 45 active assertions and 18 supplementary variables.
data(local_food, package = "NaileR")
food_mca <- FactoMineR::MCA(
  local_food,
  quali.sup = 46:63,
  ncp = 100,
  graph = FALSE
)
cases[["local_food"]] <- run_case(
  "local_food",
  local_food,
  food_mca,
  1:45,
  46:63,
  food_mca$ind$coord[, 1],
  "sustainable food-system representations",
  paste(
    "Participants rated 45 statements about a sustainable food system",
    "and answered additional opinion and contextual questions. Dim1 is a",
    "constructed contrast in declared representations, not behaviour."
  ),
  paste(
    "Interpret both ends of Dim1 from the retained evidence. Distinguish",
    "active statements that construct the ACM from supplementary variables",
    "and do not infer causal mechanisms."
  )
)

# IRTSAT: all 48 assertions are active. The item table is analyzed on its
# own; it is intentionally not joined to the separate 529-row profile table.
data(irtsat_items_2024_2025, package = "NaileR")
irtsat_mca <- FactoMineR::MCA(
  irtsat_items_2024_2025,
  ncp = 5,
  graph = FALSE
)
cases[["irtsat_items_2024_2025"]] <- run_case(
  "irtsat_items_2024_2025",
  irtsat_items_2024_2025,
  irtsat_mca,
  seq_len(ncol(irtsat_items_2024_2025)),
  integer(),
  irtsat_mca$ind$coord[, 1],
  "local-food representations",
  paste(
    "This 48-item instrument covers six blocks of local-food attitudes",
    "and practices. The ordered Likert items are treated as categorical",
    "by MCA, with no join to the separate 529-row profile table."
  ),
  paste(
    "Interpret Dim1 as a descriptive contrast in the item responses.",
    "Use the retained evidence, not an IRT interpretation, and do not",
    "infer behaviour or causality."
  )
)

# Distinction: six coherent assertion blocks. Context variables and the open
# response are deliberately excluded from the active ACM.
data(distinction, package = "NaileR")
distinction_active <- c(
  grep("^assertion_q17_", names(distinction), value = TRUE),
  grep("^assertion_q2[1-5]_", names(distinction), value = TRUE)
)
stopifnot(length(distinction_active) == 47L)
distinction_dictionary <- utils::read.csv(
  file.path(repo, "dev/transition_reconstruction/DISTINCTION_VARIABLE_DICTIONARY.csv"),
  check.names = FALSE,
  stringsAsFactors = FALSE,
  fileEncoding = "UTF-8"
)
stopifnot(
  all(c("original_position", "original_name", "english_name") %in%
    names(distinction_dictionary))
)
distinction_dictionary_rows <- match(
  distinction_active,
  distinction_dictionary$english_name
)
stopifnot(
  all(!is.na(distinction_dictionary_rows)),
  !anyDuplicated(distinction_dictionary$original_name[distinction_dictionary_rows]),
  all(nzchar(distinction_dictionary$original_name[distinction_dictionary_rows]))
)
distinction_assertion_crosswalk <- data.frame(
  technical_name = distinction_active,
  documented_label = distinction_dictionary$original_name[distinction_dictionary_rows],
  dictionary_position = distinction_dictionary$original_position[distinction_dictionary_rows],
  label_language = "French",
  stringsAsFactors = FALSE,
  check.names = FALSE
)
distinction_active_data_raw <- distinction[, distinction_active, drop = FALSE]
distinction_active_data <- distinction_active_data_raw
names(distinction_active_data) <- distinction_assertion_crosswalk$documented_label
distinction_mca_raw <- FactoMineR::MCA(
  distinction_active_data_raw,
  ncp = 5,
  graph = FALSE
)
distinction_mca <- FactoMineR::MCA(
  distinction_active_data,
  ncp = 5,
  graph = FALSE
)
distinction_raw_work <- data.frame(
  Dim1 = distinction_mca_raw$ind$coord[, 1],
  distinction_active_data_raw,
  check.names = FALSE
)
distinction_semantic_work <- data.frame(
  Dim1 = distinction_mca$ind$coord[, 1],
  distinction_active_data,
  check.names = FALSE
)
distinction_raw_result <- NaileR::nail_condes(
  dataset = distinction_raw_work,
  num.var = 1,
  interpretation_mode = "latent",
  target_label = "Dim1",
  target_concept = "food-transition representations",
  introduction = paste(
    "This survey records reported food, territory and food-choice",
    "attitudes. The active variables cover local-food representations,",
    "literacy, social context, place confidence, cooking time and health."
  ),
  request = paste(
    "Interpret the opposition between the two ends of Dim1 from the",
    "retained evidence. Keep reported attitudes distinct from observed",
    "behaviour, and do not use the open response as an active ACM variable."
  ),
  generate = FALSE
)
distinction_semantic_result <- NaileR::nail_condes(
  dataset = distinction_semantic_work,
  num.var = 1,
  interpretation_mode = "latent",
  target_label = "Dim1",
  target_concept = "food-transition representations",
  introduction = paste(
    "This survey records reported food, territory and food-choice",
    "attitudes. The active variables cover local-food representations,",
    "literacy, social context, place confidence, cooking time and health."
  ),
  request = paste(
    "Interpret the opposition between the two ends of Dim1 from the",
    "retained evidence. Keep reported attitudes distinct from observed",
    "behaviour, and do not use the open response as an active ACM variable."
  ),
  generate = FALSE
)
distinction_raw_evidence <- NaileR::nail_evidence(distinction_raw_result)
distinction_semantic_evidence <- NaileR::nail_evidence(distinction_semantic_result)
registry_numeric_columns <- c(
  "family", "category", "direction", "statistic", "statistic_name",
  "p_value", "rank"
)
distinction_invariance <- data.frame(
  check = c(
    "mca_eigenvalues",
    "mca_ind_coord_dim1_same_or_sign_flip",
    "mca_ind_contrib",
    "mca_ind_cos2",
    "mca_var_coord_same_or_sign_flip",
    "mca_var_contrib",
    "mca_var_cos2",
    "condes_target",
    "condes_registry_numeric",
    "condes_marker_count"
  ),
  passed = c(
    same_numeric(distinction_mca_raw$eig, distinction_mca$eig),
    same_or_global_sign(
      distinction_mca_raw$ind$coord[, 1],
      distinction_mca$ind$coord[, 1]
    ),
    same_numeric(distinction_mca_raw$ind$contrib, distinction_mca$ind$contrib),
    same_numeric(distinction_mca_raw$ind$cos2, distinction_mca$ind$cos2),
    same_or_global_sign(
      distinction_mca_raw$var$coord,
      distinction_mca$var$coord
    ),
    same_numeric(distinction_mca_raw$var$contrib, distinction_mca$var$contrib),
    same_numeric(distinction_mca_raw$var$cos2, distinction_mca$var$cos2),
    identical(distinction_raw_evidence$target, distinction_semantic_evidence$target),
    isTRUE(all.equal(
      distinction_raw_evidence$evidence_registry[registry_numeric_columns],
      distinction_semantic_evidence$evidence_registry[registry_numeric_columns],
      check.attributes = FALSE
    )),
    identical(
      nrow(distinction_raw_evidence$evidence_registry),
      nrow(distinction_semantic_evidence$evidence_registry)
    )
  ),
  stringsAsFactors = FALSE
)
stopifnot(all(distinction_invariance$passed))
if (nzchar(output_dir)) {
  utils::write.csv(
    distinction_assertion_crosswalk,
    file.path(output_dir, "distinction_assertion_crosswalk.csv"),
    row.names = FALSE,
    fileEncoding = "UTF-8"
  )
  saveRDS(
    distinction_raw_evidence,
    file.path(output_dir, "distinction_raw_evidence.rds")
  )
  saveRDS(
    distinction_semantic_evidence,
    file.path(output_dir, "distinction_semantic_evidence.rds")
  )
  utils::write.csv(
    distinction_invariance,
    file.path(output_dir, "distinction_semantic_invariance.csv"),
    row.names = FALSE
  )
}
cases[["distinction"]] <- run_case(
  "distinction",
  distinction_active_data,
  distinction_mca,
  seq_along(distinction_active),
  integer(),
  distinction_mca$ind$coord[, 1],
  "food-transition representations",
  paste(
    "This survey records reported food, territory and food-choice",
    "attitudes. The active variables cover local-food representations,",
    "literacy, social context, place confidence, cooking time and health."
  ),
  paste(
    "Interpret the opposition between the two ends of Dim1 from the",
    "retained evidence. Keep reported attitudes distinct from observed",
    "behaviour, and do not use the open response as an active ACM variable."
  )
)

summary <- do.call(rbind, cases)
rownames(summary) <- NULL
if (nzchar(output_dir)) {
  utils::write.csv(
    summary,
    file.path(output_dir, "condes_examples_summary.csv"),
    row.names = FALSE
  )
}
print(summary, row.names = FALSE)
