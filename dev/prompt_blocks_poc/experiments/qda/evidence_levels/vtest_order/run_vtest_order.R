# QDA signed v.test-order experiment

devtools::load_all(quiet = TRUE)

output_dir <- file.path(
  "dev", "prompt_blocks_poc", "experiments", "qda", "evidence_levels",
  "vtest_order"
)
dir.create(output_dir, recursive = TRUE, showWarnings = FALSE)

previous <- readRDS(file.path(
  "dev", "prompt_blocks_poc", "experiments", "qda", "evidence_levels",
  "replication_less_dense", "qda_evidence_levels_replication_raw_results.rds"
))

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

product <- "choc2"
product_profiles <- attr(reference, "product_profiles", exact = TRUE)
interpretation_evidence <- attr(reference, "interpretation_evidence", exact = TRUE)
semantic_facing_evidence <- attr(reference, "semantic_facing_evidence", exact = TRUE)
qda_prompt_blocks <- attr(reference, "qda_prompt_blocks", exact = TRUE)
reference_blocks <- qda_prompt_blocks[[product]]
selected_markers <- interpretation_evidence$products[[product]]$selected_markers

if (!identical(product_profiles, previous$reference$product_profiles) ||
    !identical(interpretation_evidence, previous$reference$interpretation_evidence)) {
  stop("The replicated canonical QDA artifacts differ from the previous replication.", call. = FALSE)
}

if (!identical(previous$blocks$C[c(
  "context", "question", "interpretation", "local_task", "reusable", "output"
)], reference_blocks[c(
  "context", "question", "interpretation", "local_task", "reusable", "output"
)])) {
  stop("The reused C protected prompt blocks differ from the reference.", call. = FALSE)
}

direction_word <- function(direction) {
  ifelse(direction == "higher", "HIGHER", "LOWER")
}

semantic_minimal_evidence <- function(markers) {
  paste(
    c(
      paste0("## Product '", product, "'"),
      "R-derived facts retained for this product:",
      vapply(seq_len(nrow(markers)), function(i) {
        row <- markers[i, , drop = FALSE]
        paste0(
          'Attribute "', row$attribute, '" is ',
          direction_word(row$direction),
          " than the average product profile."
        )
      }, character(1))
    ),
    collapse = "\n\n"
  )
}

condition_C <- previous$blocks$C

signed_order <- order(selected_markers$v_test, decreasing = TRUE)
ordered_markers <- selected_markers[signed_order, , drop = FALSE]

expected_order <- c("Crunchy", "CocoaF", "Sweetness", "Caramel", "Melting", "MilkF")
if (!identical(as.character(ordered_markers$attribute), expected_order)) {
  stop("Signed decreasing v.test order did not match the expected choc2 order.", call. = FALSE)
}
if (!identical(signed_order, order(selected_markers$v_test, decreasing = TRUE))) {
  stop("The E order is not signed decreasing v.test order.", call. = FALSE)
}

e_reading <- paste(
  "The statistical facts below are mechanically derived from SensoMineR::decat().",
  "For each sensory attribute, HIGHER means that the product is above the average product profile for that attribute, and LOWER means that it is below the average product profile.",
  "These are relative statistical characterizations, not absolute judgments about the product.",
  "Only statistically retained markers selected for this prompt are shown.",
  "The facts are ordered by decreasing v.test, following the statistical structure of the analysis.",
  "When identifying the main statistical characteristics of the product, pay particular attention to both ends of the list: attributes near the top provide the strongest positive characterization, while attributes near the bottom provide the strongest negative characterization.",
  "Position in this ordering reflects statistical evidence for the deviation. It must not be interpreted as sensory intensity, effect size, or substantive importance.",
  "An undisplayed attribute must not be interpreted as absent or exactly average.",
  "Both HIGHER and LOWER retained markers may be shown.",
  sep = "\n"
)

condition_E <- condition_C
condition_E$reading <- e_reading
condition_E$evidence <- semantic_minimal_evidence(ordered_markers)

condition_blocks <- list(C = condition_C, E = condition_E)
condition_prompts <- lapply(condition_blocks, .render_qda_prompt_blocks)

protected_names <- c(
  "context", "question", "interpretation", "local_task", "reusable", "output"
)
protected_identical <- identical(
  condition_C[protected_names],
  condition_E[protected_names]
)

invariance <- data.frame(
  condition = c("C", "E"),
  product_profiles_identical = c(TRUE, TRUE),
  interpretation_evidence_identical = c(TRUE, TRUE),
  selected_evidence_ids_identical = c(TRUE, TRUE),
  directions_identical = c(TRUE, TRUE),
  six_markers_identical = c(TRUE, TRUE),
  product_identical = c(product, product),
  protected_prompt_blocks_identical = c(protected_identical, protected_identical),
  stringsAsFactors = FALSE
)

if (!protected_identical ||
    !identical(
      interpretation_evidence$products[[product]]$selected_evidence_ids,
      selected_markers$evidence_id
    ) ||
    !identical(
      semantic_facing_evidence$products[[product]]$selected_evidence_ids,
      selected_markers$evidence_id
    )) {
  stop("C/E evidence invariance check failed.", call. = FALSE)
}

condition_table <- data.frame(
  condition = names(condition_prompts),
  prompt_chars = vapply(condition_prompts, nchar, integer(1)),
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
    experiment = "qda_vtest_order",
    source_commit = "c06d1d81106241aaa54540a6784a8d301f69588e",
    product = product,
    model = "mistral-small3.2",
    replications = replications,
    conditions = c("C", "E"),
    condition_table = condition_table,
    signed_vtest_order = ordered_markers$attribute,
    signed_vtest_values = ordered_markers$v_test,
    selected_evidence_ids = selected_markers$evidence_id,
    selected_directions = selected_markers$direction,
    invariance = invariance,
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

saveRDS(raw_artifact, file.path(output_dir, "qda_vtest_order_raw_results.rds"))

set.seed(20261010)
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
  file.path(output_dir, "qda_vtest_order_blind_key.csv"),
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
writeLines(blind_response_lines, file.path(output_dir, "qda_vtest_order_blind_responses.txt"))

review_lines <- c(
  "# QDA Signed v.test Order — Blind Review Packet",
  "",
  "This packet contains six responses under blind identifiers R01-R06.",
  "The evidence representation condition is not identified here.",
  "",
  "## Common context",
  "",
  condition_C$context,
  "",
  "## Common analytical question",
  "",
  condition_C$question,
  "",
  "## Common evidence scope",
  "",
  "All responses concern the same product 'choc2' and the same six retained",
  "QDA markers. Review the two-direction hierarchy without reconstructing the",
  "condition assignment.",
  "",
  "## Reviewer-only hierarchy reference",
  "",
  "The expected signed statistical order is:",
  "strong positive end: Crunchy",
  "then: CocoaF",
  "middle / weaker evidence: Sweetness, Caramel, Melting",
  "strong negative end: MilkF",
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
    "[ ] recognizes strongest support from both directions", "[ ] partly recognizes both directions", "[ ] treats one direction as inherently secondary", "",
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
writeLines(review_lines, file.path(output_dir, "qda_vtest_order_review_packet.md"))

cat("Wrote signed v.test-order artifacts.\n")
cat("Product:", product, "markers:", nrow(selected_markers), "\n")
