# QDA evidence-level representation: less-dense replication

devtools::load_all(quiet = TRUE)

output_dir <- file.path(
  "dev", "prompt_blocks_poc", "experiments", "qda", "evidence_levels",
  "replication_less_dense"
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

product_profiles <- attr(reference, "product_profiles", exact = TRUE)
interpretation_evidence <- attr(reference, "interpretation_evidence", exact = TRUE)
semantic_facing_evidence <- attr(reference, "semantic_facing_evidence", exact = TRUE)
qda_prompt_blocks <- attr(reference, "qda_prompt_blocks", exact = TRUE)

pre_screen <- lapply(c("choc2", "choc4"), function(product) {
  markers <- interpretation_evidence$products[[product]]$selected_markers
  data.frame(
    product = product,
    n_selected_markers = nrow(markers),
    n_higher = sum(markers$direction == "higher"),
    n_lower = sum(markers$direction == "lower"),
    min_p = min(markers$p_value),
    max_p = max(markers$p_value),
    min_abs_vtest = min(abs(markers$v_test)),
    max_abs_vtest = max(abs(markers$v_test)),
    ordered_attributes = paste(markers$attribute, collapse = ";"),
    ordered_directions = paste(toupper(markers$direction), collapse = ";"),
    ordered_vtests = paste(formatC(markers$v_test, format = "f", digits = 2), collapse = ";"),
    ordered_pvalues = paste(ifelse(markers$p_value < 0.001, "<.001", formatC(markers$p_value, format = "f", digits = 6)), collapse = ";"),
    evidence_ids = paste(markers$evidence_id, collapse = ";"),
    stringsAsFactors = FALSE
  )
})
pre_screen <- do.call(rbind, pre_screen)
rownames(pre_screen) <- NULL

product <- "choc2"
reference_blocks <- qda_prompt_blocks[[product]]
selected_markers <- interpretation_evidence$products[[product]]$selected_markers

if (nrow(selected_markers) != 6L) {
  stop("The mechanical pre-screen did not select the expected six choc2 markers.", call. = FALSE)
}

format_p_value <- function(x) {
  ifelse(x < 0.001, "<0.001", formatC(x, format = "f", digits = 3))
}

format_number <- function(x, digits = 2) {
  formatC(as.numeric(x), format = "f", digits = digits)
}

direction_word <- function(direction) {
  ifelse(direction == "higher", "HIGHER", "LOWER")
}

numeric_evidence <- paste(
  c(
    paste0("## Product '", product, "'"),
    "R-derived facts retained for this product:",
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
  collapse = "\n\n"
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
  c(
    paste0("## Product '", product, "'"),
    "R-derived facts retained for this product:",
    vapply(seq_len(nrow(selected_markers)), function(i) {
      row <- selected_markers[i, , drop = FALSE]
      paste0(
        'Attribute "', row$attribute, '" is ',
        direction_word(row$direction),
        " than the average product profile."
      )
    }, character(1))
  ),
  collapse = "\n\n"
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

make_blocks <- function(reading, evidence) {
  blocks <- reference_blocks
  blocks$reading <- reading
  blocks$evidence <- evidence
  blocks
}

condition_blocks <- list(
  A = make_blocks(numeric_reading, numeric_evidence),
  B = make_blocks(reference_blocks$reading, semantic_numeric),
  C = make_blocks(semantic_minimal_reading, semantic_minimal)
)
condition_prompts <- lapply(condition_blocks, .render_qda_prompt_blocks)

protected_names <- c(
  "context", "question", "interpretation", "local_task", "reusable", "output"
)
protected_identical <- vapply(
  condition_blocks,
  function(blocks) identical(blocks[protected_names], reference_blocks[protected_names]),
  logical(1)
)

invariance <- data.frame(
  condition = names(condition_blocks),
  product_profiles_identical = TRUE,
  interpretation_evidence_identical = TRUE,
  selected_evidence_ids_identical = vapply(
    condition_blocks,
    function(blocks) identical(
      selected_markers$evidence_id,
      interpretation_evidence$products[[product]]$selected_evidence_ids
    ),
    logical(1)
  ),
  marker_count = nrow(selected_markers),
  directions_identical = vapply(
    condition_blocks,
    function(blocks) identical(
      selected_markers$direction,
      interpretation_evidence$products[[product]]$selected_markers$direction
    ),
    logical(1)
  ),
  product_identical = product,
  marker_order_identical = TRUE,
  protected_blocks_identical = protected_identical,
  stringsAsFactors = FALSE
)

if (!all(invariance$selected_evidence_ids_identical,
         invariance$directions_identical,
         invariance$protected_blocks_identical)) {
  stop("Replication invariance check failed.", call. = FALSE)
}

condition_table <- data.frame(
  condition = names(condition_prompts),
  prompt_chars = vapply(condition_prompts, nchar, integer(1)),
  stringsAsFactors = FALSE
)

condition_spec <- data.frame(
  condition = c("A", "B", "C"),
  name = c("NUMERIC TABLE", "CURRENT SEMANTIC + NUMERIC", "SEMANTIC MINIMAL"),
  stringsAsFactors = FALSE
)

replications <- 3L
raw_results <- vector("list", length(condition_prompts) * replications)
cursor <- 0L

for (condition in names(condition_prompts)) {
  for (replicate in seq_len(replications)) {
    cursor <- cursor + 1L
    cat(sprintf("Generating %s repetition %d/%d\n", condition, replicate, replications))
    backend <- .call_llm_base(
      provider = "ollama",
      model = "mistral-small3.2",
      prompt = condition_prompts[[condition]],
      output = "df",
      llm_api_options = list()
    )
    raw_results[[cursor]] <- list(
      condition = condition,
      replicate = replicate,
      product = product,
      model = "mistral-small3.2",
      provider = "ollama",
      seed = NA_integer_,
      prompt = condition_prompts[[condition]],
      response = as.character(backend$response[[1L]]),
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
    experiment = "qda_evidence_levels_replication_less_dense",
    source_commit = "c06d1d81106241aaa54540a6784a8d301f69588e",
    product = product,
    model = "mistral-small3.2",
    replications = replications,
    conditions = condition_spec,
    condition_table = condition_table,
    pre_screen = pre_screen,
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

saveRDS(raw_artifact, file.path(output_dir, "qda_evidence_levels_replication_raw_results.rds"))

set.seed(20261009)
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
  file.path(output_dir, "qda_evidence_levels_replication_blind_key.csv"),
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
writeLines(blind_response_lines, file.path(output_dir, "qda_evidence_levels_replication_blind_responses.txt"))

review_lines <- c(
  "# QDA Evidence-Level Representation — Less-Dense Replication Blind Review",
  "",
  "This packet contains nine responses under blind identifiers R01-R09.",
  "The representation condition is not identified here.",
  "",
  "## Common context",
  "",
  reference_blocks$context,
  "",
  "## Common analytical question",
  "",
  reference_blocks$question,
  "",
  "## Common evidence scope",
  "",
  "All responses concern the same product 'choc2' and the same six retained",
  "QDA markers. Review direction, reference, hierarchy, interpretive lift, and",
  "unsupported extrapolation without reconstructing the representation condition.",
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
writeLines(review_lines, file.path(output_dir, "qda_evidence_levels_replication_review_packet.md"))

cat("Wrote less-dense replication artifacts.\n")
cat("Product:", product, "markers:", nrow(selected_markers), "\n")
