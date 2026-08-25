# =============================================================================
# NaileR operational stabilization script
# Purpose: freeze user-facing calls and verify easy access to outputs
# =============================================================================

library(NaileR)

# -----------------------------------------------------------------------------
# Global execution settings
# -----------------------------------------------------------------------------

RUN_LLM <- FALSE
NAILER_PROVIDER <- "ollama"
NAILER_MODEL <- "mistral-small3.2"

# Switch RUN_LLM to TRUE to validate real generation.
# With RUN_LLM = FALSE, all analyses remain fully inspectable through
# nail_evidence() and nail_prompt().

check_nailer_access <- function(x, select = NULL, response_expected = RUN_LLM) {
  evidence <- nail_evidence(x, select = select)
  prompt <- nail_prompt(x, select = select, print = FALSE)

  stopifnot(!is.null(evidence))
  stopifnot(is.character(prompt), length(prompt) == 1L, !is.na(prompt))

  if (isTRUE(response_expected)) {
    response <- nail_response(x, select = select, print = FALSE)
    stopifnot(is.character(response), length(response) == 1L, !is.na(response))
  }

  invisible(TRUE)
}

# =============================================================================
# 1. QDA — product sensory profiles
# =============================================================================

# BOOK CONTRACT:
#   result <- nail_qda(...)
#   nail_evidence(result, select = product)
#   nail_prompt(result, select = product)
#   nail_response(result, select = product)   # if generate = TRUE

data(chocolates, package = "SensoMineR")

res_qda <- nail_qda(
  dataset = sensochoc,
  formul = "~Product+Panelist",
  firstvar = 5,
  isolate.groups = TRUE,
  product_knowledge = "known",
  provider = NAILER_PROVIDER,
  model = NAILER_MODEL,
  generate = RUN_LLM
)

qda_evidence <- nail_evidence(res_qda)
qda_products <- names(qda_evidence$products)
qda_product <- qda_products[[1L]]

qda_product_evidence <- nail_evidence(res_qda, select = qda_product)
qda_product_evidence$retained_markers

nail_prompt(res_qda, select = qda_product)
if (RUN_LLM) nail_response(res_qda, select = qda_product)

check_nailer_access(res_qda, select = qda_product)

# =============================================================================
# 2. QDA SPACE — geometry built from QDA evidence
# =============================================================================

# BOOK CONTRACT:
#   space <- nail_qda_space(res_qda, ...)
#   nail_evidence(space, select = dimension)
#   nail_prompt(space, select = dimension)
#   nail_response(space, select = dimension)  # if generate = TRUE

res_qda_space <- nail_qda_space(
  x = res_qda,
  ncp = 2,
  expertise_mode = "sensory",
  provider = NAILER_PROVIDER,
  model = NAILER_MODEL,
  generate = RUN_LLM
)

qda_space_evidence <- nail_evidence(res_qda_space)
qda_axes <- names(qda_space_evidence$axes)

if (length(qda_axes) > 0L) {
  qda_axis <- qda_axes[[1L]]
  nail_evidence(res_qda_space, select = qda_axis)
  nail_prompt(res_qda_space, select = qda_axis)
  if (RUN_LLM) nail_response(res_qda_space, select = qda_axis)
  check_nailer_access(res_qda_space, select = qda_axis)
}

# =============================================================================
# 3. CONDES — observed continuous variable
# =============================================================================

# BOOK CONTRACT:
#   result <- nail_condes(..., interpretation_mode = "standard")
#   nail_evidence(result)
#   nail_prompt(result)
#   nail_response(result)                     # if generate = TRUE

data(decathlon, package = "FactoMineR")

res_condes <- nail_condes(
  dataset = decathlon,
  num.var = 12,
  interpretation_mode = "standard",
  provider = NAILER_PROVIDER,
  model = NAILER_MODEL,
  generate = RUN_LLM
)

condes_evidence <- nail_evidence(res_condes)
condes_evidence$quantitative_associations
condes_evidence$qualitative_associations
condes_evidence$end_profiles

nail_prompt(res_condes)
if (RUN_LLM) nail_response(res_condes)

check_nailer_access(res_condes)

# =============================================================================
# 4. CONDES — latent dimension
# =============================================================================

pca_decathlon <- FactoMineR::PCA(
  decathlon[, 1:10],
  scale.unit = TRUE,
  graph = FALSE
)

latent_data <- data.frame(
  Dim1 = pca_decathlon$ind$coord[, 1],
  decathlon[, 1:10],
  check.names = FALSE
)

res_condes_latent <- nail_condes(
  dataset = latent_data,
  num.var = 1,
  interpretation_mode = "latent",
  target_label = "Dim1",
  provider = NAILER_PROVIDER,
  model = NAILER_MODEL,
  generate = RUN_LLM
)

nail_evidence(res_condes_latent)
nail_prompt(res_condes_latent)
if (RUN_LLM) nail_response(res_condes_latent)

check_nailer_access(res_condes_latent)

# =============================================================================
# 5. CATDES — observed categorical variable
# =============================================================================

# BOOK CONTRACT:
#   result <- nail_catdes(...)
#   nail_evidence(result, select = group)
#   nail_prompt(result, select = group)
#   nail_response(result, select = group)      # if generate = TRUE

res_catdes <- nail_catdes(
  dataset = iris,
  num.var = 5,
  interpretation_mode = "standard",
  isolate.groups = TRUE,
  provider = NAILER_PROVIDER,
  model = NAILER_MODEL,
  generate = RUN_LLM
)

catdes_evidence <- nail_evidence(res_catdes)
catdes_groups <- names(catdes_evidence$groups)
catdes_group <- catdes_groups[[1L]]

catdes_group_evidence <- nail_evidence(res_catdes, select = catdes_group)
catdes_group_evidence$qualitative_markers
catdes_group_evidence$quantitative_markers
catdes_group_evidence$factual_summary

nail_prompt(res_catdes, select = catdes_group)
if (RUN_LLM) nail_response(res_catdes, select = catdes_group)

check_nailer_access(res_catdes, select = catdes_group)

# =============================================================================
# 6. CATDES — latent / constructed groups
# =============================================================================

data(atomic_habit_clust, package = "NaileR")

# Keep a compact statistical table for the operational example:
# 20 questionnaire variables + the existing cluster variable.
catdes_latent_data <- atomic_habit_clust[, c(1:20, 51)]

res_catdes_latent <- nail_catdes(
  dataset = catdes_latent_data,
  num.var = ncol(catdes_latent_data),
  interpretation_mode = "latent",
  isolate.groups = TRUE,
  provider = NAILER_PROVIDER,
  model = NAILER_MODEL,
  generate = RUN_LLM
)

catdes_latent_groups <- names(nail_evidence(res_catdes_latent)$groups)
latent_group <- catdes_latent_groups[[1L]]

nail_evidence(res_catdes_latent, select = latent_group)
nail_prompt(res_catdes_latent, select = latent_group)
if (RUN_LLM) nail_response(res_catdes_latent, select = latent_group)

check_nailer_access(res_catdes_latent, select = latent_group)

# =============================================================================
# 7. DESCFREQ — contingency / CATA-type frequency profiles
# =============================================================================

# BOOK CONTRACT:
#   result <- nail_descfreq(...)
#   nail_evidence(result, select = row)
#   nail_prompt(result, select = row)
#   nail_response(result, select = row)        # if generate = TRUE

data(beard_cont, package = "NaileR")

res_descfreq <- nail_descfreq(
  dataset = beard_cont,
  interpretation_mode = "description",
  isolate.groups = TRUE,
  explicit_row_labels = FALSE,
  provider = NAILER_PROVIDER,
  model = NAILER_MODEL,
  generate = RUN_LLM
)

descfreq_evidence <- nail_evidence(res_descfreq)
descfreq_rows <- names(descfreq_evidence$rows)
descfreq_row <- descfreq_rows[[1L]]

descfreq_row_evidence <- nail_evidence(res_descfreq, select = descfreq_row)
descfreq_row_evidence$retained_markers

nail_prompt(res_descfreq, select = descfreq_row)
if (RUN_LLM) nail_response(res_descfreq, select = descfreq_row)

check_nailer_access(res_descfreq, select = descfreq_row)

# =============================================================================
# 8. TEXTUAL — grouped open-ended responses
# =============================================================================

# BOOK CONTRACT:
#   result <- nail_textual(...)
#   nail_evidence(result, select = group)
#   nail_prompt(result, select = group)
#   nail_response(result, select = group)      # if generate = TRUE

data(fabric, package = "NaileR")
fabric_A <- droplevels(fabric[fabric$Fabric == "A", ])

res_textual <- nail_textual(
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

textual_evidence <- nail_evidence(res_textual)
textual_groups <- names(textual_evidence$groups)
textual_group <- textual_groups[[1L]]

textual_group_evidence <- nail_evidence(res_textual, select = textual_group)
textual_group_evidence$metrics
head(textual_group_evidence$texts)

nail_prompt(res_textual, select = textual_group)
if (RUN_LLM) nail_response(res_textual, select = textual_group)

check_nailer_access(res_textual, select = textual_group)

# =============================================================================
# 9. CATDES + TEXTUAL — statistical anchor enriched by texts
# =============================================================================

# This composed example requires generated textual profiles.
# It is therefore executed only when RUN_LLM = TRUE.

if (RUN_LLM) {
  contextual_cat_data <- atomic_habit_clust[, c(1:20, 51)]
  contextual_text_data <- data.frame(
    group = atomic_habit_clust[[51]],
    text = atomic_habit_clust[[31]],
    stringsAsFactors = FALSE
  )

  res_cat_context <- nail_catdes(
    dataset = contextual_cat_data,
    num.var = ncol(contextual_cat_data),
    interpretation_mode = "latent",
    isolate.groups = TRUE,
    provider = NAILER_PROVIDER,
    model = NAILER_MODEL,
    generate = TRUE
  )

  res_txt_context <- nail_textual(
    dataset = contextual_text_data,
    num.var = 1,
    num.text = 2,
    isolate.groups = TRUE,
    sample.pct = 0.40,
    seed = 123,
    text_role = "responses",
    provider = NAILER_PROVIDER,
    model = NAILER_MODEL,
    generate = TRUE
  )

  res_contextualized <- nail_catdes_textual(
    catdes = res_cat_context,
    textual = res_txt_context,
    isolate.groups = TRUE,
    provider = NAILER_PROVIDER,
    model = NAILER_MODEL,
    generate = TRUE
  )

  contextual_groups <- names(nail_evidence(res_contextualized)$groups)
  contextual_group <- contextual_groups[[1L]]

  nail_evidence(res_contextualized, select = contextual_group)
  nail_prompt(res_contextualized, select = contextual_group)
  nail_response(res_contextualized, select = contextual_group)

  check_nailer_access(res_contextualized, select = contextual_group)
}

# =============================================================================
# 10. Final operational contract
# =============================================================================

# The book-facing public grammar should remain:
#
#   res <- nail_xxx(...)
#   nail_evidence(res, select = ...)
#   nail_prompt(res, select = ...)
#   nail_response(res, select = ...)
#
# Direct access through attributes such as attr(res, "product_profiles") or
# attr(res, "statistical_profiles") is intentionally NOT used in this script.

cat("\nNaileR operational stabilization script completed.\n")
cat("RUN_LLM =", RUN_LLM, "\n")

sessionInfo()
