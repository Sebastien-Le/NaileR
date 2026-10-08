# QDA evidence-level representation experiment
#
# This script is intentionally outside the package implementation. It builds
# one frozen QDA evidence object, renders four experimental representations,
# calls Ollama three times per condition, and writes a blinded review packet.

devtools::load_all(quiet = TRUE)

output_dir <- file.path(
  "dev", "prompt_blocks_poc", "experiments", "qda", "evidence_levels"
)
dir.create(output_dir, recursive = TRUE, showWarnings = FALSE)

data(chocolates, package = "SensoMineR")

reference <- nail_qda(
  dataset = sensochoc,
  formul = "~Product+Panelist",
  firstvar = 5,
  isolate.groups = TRUE,
  drop.negative = FALSE,
  proba = 0.05,
  sample.pct = 1,
  sample.method = "stratified",
  prompt_style = "detailed",
  product_knowledge = "known",
  provider = "ollama",
  model = "mistral-small3.2",
  generate = FALSE
)

product <- "choc1"
product_profiles <- attr(reference, "product_profiles", exact = TRUE)
interpretation_evidence <- attr(reference, "interpretation_evidence", exact = TRUE)
semantic_facing_evidence <- attr(reference, "semantic_facing_evidence", exact = TRUE)
qda_prompt_blocks <- attr(reference, "qda_prompt_blocks", exact = TRUE)

reference_blocks <- qda_prompt_blocks[[product]]
selected_markers <- interpretation_evidence$products[[product]]$selected_markers

if (!identical(
  interpretation_evidence$products[[product]]$selected_evidence_ids,
  selected_markers$evidence_id
)) {
  stop("Selected evidence IDs do not match the selected marker table.", call. = FALSE)
}

if (!identical(
  selected_markers$evidence_id,
  semantic_facing_evidence$products[[product]]$selected_evidence_ids
)) {
  stop("Semantic-facing evidence IDs differ from interpretation evidence IDs.", call. = FALSE)
}

format_p_value <- function(x) {
  ifelse(
    is.na(x),
    NA_character_,
    ifelse(x < 0.001, "<0.001", formatC(x, format = "f", digits = 3))
  )
}

format_number <- function(x, digits = 2) {
  formatC(as.numeric(x), format = "f", digits = digits)
}

direction_word <- function(direction) {
  ifelse(direction == "higher", "HIGHER", "LOWER")
}

numeric_evidence <- paste(
  c(
    "| Variable | Coeff | Adjust mean | p.value | v.test |",
    "|---|---:|---:|---:|---:|",
    vapply(seq_len(nrow(selected_markers)), function(i) {
      row <- selected_markers[i, , drop = FALSE]
      paste0(
        "| ", row$attribute,
        " | ", format_number(row$coefficient),
        " | ", format_number(row$adjusted_mean),
        " | ", format_p_value(row$p_value),
        " | ", format_number(row$v_test), " |"
      )
    }, character(1))
  ),
  collapse = "\n"
)

numeric_evidence <- paste(
  paste0("## Product '", product, "'"),
  "R-derived facts retained for this product:",
  numeric_evidence,
  sep = "\n\n"
)

numeric_reading <- paste(
  "The results below come from SensoMineR::decat().",
  "Each row describes a sensory attribute that statistically characterizes the product relative to the evaluated set.",
  "Coeff gives the direction of the product effect.",
  "Adjust mean is the adjusted mean score for the product on that attribute.",
  "A positive v.test indicates a result above the average product profile for that attribute; a negative v.test indicates a result below it.",
  "Smaller p.values indicate stronger statistical evidence for the deviation.",
  "Do not interpret v.test or p.value as measures of sensory intensity or substantive importance.",
  sep = "\n"
)

semantic_numeric <- semantic_facing_evidence$products[[product]]$prompt_text

semantic_minimal <- paste(
  vapply(seq_len(nrow(selected_markers)), function(i) {
    row <- selected_markers[i, , drop = FALSE]
    paste0(
      'Attribute "', row$attribute, '" is ',
      direction_word(row$direction),
      " than the average product profile."
    )
  }, character(1)),
  collapse = "\n"
)

semantic_minimal <- paste(
  paste0("## Product '", product, "'"),
  "R-derived facts retained for this product:",
  semantic_minimal,
  sep = "\n\n"
)

semantic_minimal_reading <- paste(
  "The statistical facts below are mechanically derived from SensoMineR::decat().",
  "For each sensory attribute, HIGHER means that the product is above the average product profile for that attribute, and LOWER means that it is below the average product profile.",
  "These are relative statistical characterizations, not absolute judgments about the product.",
  "Only statistically retained markers selected for this prompt are shown.",
  "An undisplayed attribute must not be interpreted as absent or exactly average.",
  "Both HIGHER and LOWER retained markers may be shown.",
  sep = "\n"
)

ranked_semantic <- paste(
  vapply(seq_len(nrow(selected_markers)), function(i) {
    row <- selected_markers[i, , drop = FALSE]
    priority <- if (identical(as.integer(row$rank), 1L)) {
      "Primary statistical marker"
    } else {
      "Secondary statistical marker"
    }
    paste0(
      priority, ": Attribute \"", row$attribute, "\" is ",
      direction_word(row$direction),
      " than the average product profile."
    )
  }, character(1)),
  collapse = "\n"
)

ranked_semantic <- paste(
  paste0("## Product '", product, "'"),
  "R-derived facts retained for this product:",
  ranked_semantic,
  sep = "\n\n"
)

hierarchy_reading <- paste(
  semantic_minimal_reading,
  "The marker hierarchy indicates the relative statistical priority assigned mechanically by R among the displayed retained markers.",
  "It should be used to distinguish central statistical support from more secondary support, not as a measure of sensory intensity.",
  sep = "\n"
)

make_blocks <- function(reading, evidence) {
  blocks <- reference_blocks
  blocks$reading <- reading
  blocks$evidence <- evidence
  blocks
}

condition_blocks <- list(
  A = make_blocks(numeric_reading, numeric_evidence),
  B = make_blocks(reference_blocks$reading, semantic_numeric),
  C = make_blocks(semantic_minimal_reading, semantic_minimal),
  D = make_blocks(hierarchy_reading, ranked_semantic)
)

condition_prompts <- lapply(condition_blocks, .render_qda_prompt_blocks)

if (!all(vapply(condition_blocks, function(blocks) {
  identical(blocks$context, reference_blocks$context) &&
    identical(blocks$question, reference_blocks$question) &&
    identical(blocks$interpretation, reference_blocks$interpretation) &&
    identical(blocks$local_task, reference_blocks$local_task) &&
    identical(blocks$reusable, reference_blocks$reusable) &&
    identical(blocks$output, reference_blocks$output)
}, logical(1)))) {
  stop("At least one protected prompt block differs between conditions.", call. = FALSE)
}

invariance <- data.frame(
  condition = names(condition_blocks),
  product_profiles_identical = vapply(condition_blocks, function(x) identical(product_profiles, attr(reference, "product_profiles", exact = TRUE)), logical(1)),
  interpretation_evidence_identical = vapply(condition_blocks, function(x) identical(interpretation_evidence, attr(reference, "interpretation_evidence", exact = TRUE)), logical(1)),
  selected_evidence_ids_identical = vapply(condition_blocks, function(x) identical(selected_markers$evidence_id, interpretation_evidence$products[[product]]$selected_evidence_ids), logical(1)),
  marker_count = nrow(selected_markers),
  directions_identical = vapply(condition_blocks, function(x) identical(selected_markers$direction, interpretation_evidence$products[[product]]$selected_markers$direction), logical(1)),
  product_identical = product,
  ordering_basis = "existing selected_markers order / rank",
  stringsAsFactors = FALSE
)

if (!all(invariance$product_profiles_identical,
         invariance$interpretation_evidence_identical,
         invariance$selected_evidence_ids_identical,
         invariance$directions_identical)) {
  stop("Evidence invariance check failed.", call. = FALSE)
}

condition_table <- data.frame(
  condition = names(condition_prompts),
  prompt_chars = vapply(condition_prompts, nchar, integer(1)),
  stringsAsFactors = FALSE
)

condition_spec <- data.frame(
  condition = c("A", "B", "C", "D"),
  name = c(
    "NUMERIC TABLE",
    "CURRENT SEMANTIC + NUMERIC",
    "SEMANTIC MINIMAL",
    "SEMANTIC + MECHANICAL HIERARCHY"
  ),
  reading = c("numeric_table", "current_reference", "semantic_minimal", "semantic_minimal_plus_rank_priority"),
  evidence = c("numeric_table", "current_semantic_numeric", "semantic_minimal", "semantic_minimal_plus_rank_priority"),
  stringsAsFactors = FALSE
)

replications <- 3L
raw_results <- vector("list", length(condition_prompts) * replications)
cursor <- 0L

for (condition in names(condition_prompts)) {
  for (replicate in seq_len(replications)) {
    cursor <- cursor + 1L
    cat(sprintf("Generating %s repetition %d/%d\\n", condition, replicate, replications))
    backend <- .call_llm_base(
      provider = "ollama",
      model = "mistral-small3.2",
      prompt = condition_prompts[[condition]],
      output = "df",
      llm_api_options = list()
    )
    response <- as.character(backend$response[[1L]])
    raw_results[[cursor]] <- list(
      condition = condition,
      replicate = replicate,
      product = product,
      model = "mistral-small3.2",
      provider = "ollama",
      seed = NA_integer_,
      prompt = condition_prompts[[condition]],
      response = response,
      backend = backend
    )
  }
}

names(raw_results) <- vapply(
  raw_results,
  function(item) paste0(item$condition, "_", sprintf("%02d", item$replicate)),
  character(1)
)

raw_artifact <- list(
  metadata = list(
    experiment = "qda_evidence_levels",
    source_commit = "c06d1d81106241aaa54540a6784a8d301f69588e",
    product = product,
    model = "mistral-small3.2",
    replications = replications,
    conditions = condition_spec,
    condition_table = condition_table,
    invariance = invariance,
    selected_evidence_ids = selected_markers$evidence_id,
    selected_marker_count = nrow(selected_markers),
    selected_directions = selected_markers$direction,
    no_fixed_seed = TRUE
  ),
  reference = list(
    product_profiles = product_profiles,
    interpretation_evidence = interpretation_evidence,
    semantic_facing_evidence = semantic_facing_evidence,
    qda_prompt_blocks = qda_prompt_blocks,
    selected_markers = selected_markers
  ),
  prompts = condition_prompts,
  blocks = condition_blocks,
  results = raw_results
)

saveRDS(
  raw_artifact,
  file.path(output_dir, "qda_evidence_levels_raw_results.rds")
)

set.seed(20261008)
blind_order <- sample(seq_along(raw_results))
blind_ids <- sprintf("R%02d", seq_along(blind_order))

blind_key <- data.frame(
  blind_id = blind_ids,
  raw_id = names(raw_results)[blind_order],
  condition = vapply(raw_results[blind_order], `[[`, character(1), "condition"),
  replicate = vapply(raw_results[blind_order], `[[`, integer(1), "replicate"),
  stringsAsFactors = FALSE
)

write.table(
  blind_key,
  file.path(output_dir, "qda_evidence_levels_blind_key.csv"),
  row.names = FALSE,
  col.names = TRUE,
  sep = ",",
  quote = TRUE
)

blind_response_lines <- unlist(lapply(seq_along(blind_order), function(i) {
  item <- raw_results[[blind_order[[i]]]]
  c(
    paste0("===== ", blind_ids[[i]], " ====="),
    item$response,
    paste0("===== END ", blind_ids[[i]], " ====="),
    ""
  )
}), use.names = FALSE)

writeLines(
  blind_response_lines,
  file.path(output_dir, "qda_evidence_levels_blind_responses.txt")
)

common_context <- condition_blocks$B$context
common_question <- condition_blocks$B$question
common_evidence <- paste(
  "All responses concern the same product 'choc1' and the same ten retained",
  "QDA markers. The exact canonical evidence IDs are held outside this blind",
  "packet. Review the response fidelity to the directions, reference profile,",
  "and displayed evidence without inferring the representation condition.",
  sep = "\n"
)

review_lines <- c(
  "# QDA Evidence-Level Representation — Blind Review Packet",
  "",
  "This packet contains 12 responses under blind identifiers. It does not",
  "identify the representation condition. Do not infer or reconstruct the key",
  "from response style alone.",
  "",
  "## Common context",
  "",
  common_context,
  "",
  "## Common analytical question",
  "",
  common_question,
  "",
  "## Common evidence scope",
  "",
  common_evidence,
  "",
  "## Blind responses",
  ""
)

for (i in seq_along(blind_order)) {
  item <- raw_results[[blind_order[[i]]]]
  review_lines <- c(
    review_lines,
    paste0("### ", blind_ids[[i]]),
    "",
    item$response,
    "",
    "Statistical fidelity:",
    "[ ] high", "[ ] minor direction/reference issue", "[ ] meaning changed", "",
    "Evidence hierarchy:",
    "[ ] central/secondary distinction appropriate", "[ ] partly appropriate", "[ ] hierarchy distorted", "",
    "Interpretive lift:",
    "[ ] paraphrase", "[ ] coherent sensory configuration", "[ ] higher-level sensory interpretation", "[ ] unsupported semantic leap", "",
    "Unjustified extrapolation:",
    "[ ] none or clearly marked", "[ ] minor", "[ ] substantial", "",
    "Comments:",
    "",
    "---",
    ""
  )
}

writeLines(
  review_lines,
  file.path(output_dir, "qda_evidence_levels_review_packet.md")
)

cat("Wrote raw results, blind responses, blind key, and review packet.\\n")
cat("Selected markers:", nrow(selected_markers), "\\n")
cat("IDs:", paste(selected_markers$evidence_id, collapse = ", "), "\\n")
