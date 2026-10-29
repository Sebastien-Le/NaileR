# User-facing examples for the Breton Distinction subset.
# These examples assume that `bretons` has been integrated into NaileR's data/
# directory. The generation block is deliberately disabled.

library(FactoMineR)
library(NaileR)

data(bretons, package = "NaileR")

active <- c(
  grep("^assertion_q17_", names(bretons), value = TRUE),
  grep("^assertion_q2[1-5]_", names(bretons), value = TRUE)
)

set.seed(1)
bretons_mca <- FactoMineR::MCA(
  bretons[active],
  ncp = 10,
  graph = FALSE
)
bretons_hcpc <- FactoMineR::HCPC(
  bretons_mca,
  nb.clust = 3,
  graph = FALSE
)
stopifnot(identical(rownames(bretons), rownames(bretons_hcpc$data.clust)))

bretons_prepared <- data.frame(
  bretons[active],
  quality_food_open = as.character(bretons$quality_food_open),
  profile = factor(bretons_hcpc$data.clust[[ncol(bretons_hcpc$data.clust)]]),
  check.names = FALSE
)

intro_bretons <- paste(
  "This exploratory survey examines declared positions about an ideal food",
  "system among respondents living in administrative Brittany.",
  "The groups were constructed from food-system assertions; the open",
  "responses are comments about food and territory, not verified behaviour.",
  "The profiles should be described as configurations of declared positions,",
  "without causal or regional generalisation."
)
request_bretons <- paste(
  "Describe the three exploratory groups using several CATDES findings",
  "together when possible. Keep group identifiers and distinguish",
  "statistical observations from cautious hypotheses. Do not infer causes",
  "or regional differences beyond this sample."
)

# 1. Classical CATDES preview without open-text enrichment.
bretons_classic <- nail_catdes(
  dataset = bretons_prepared[, c(active, "profile"), drop = FALSE],
  num.var = 48,
  interpretation_mode = "latent",
  isolate.groups = FALSE,
  drop.negative = FALSE,
  introduction = intro_bretons,
  request = request_bretons,
  generate = FALSE
)
nail_evidence(bretons_classic)
nail_prompt(bretons_classic, print = FALSE)

# 2. Two-pass CATDES preview with reproducible comment selection.
bretons_enriched <- nail_catdes(
  dataset = bretons_prepared,
  num.var = 49,
  num.textual = 48,
  textual.sample = 0.5,
  textual.seed = 123,
  interpretation_mode = "latent",
  isolate.groups = FALSE,
  drop.negative = FALSE,
  introduction = intro_bretons,
  request = request_bretons,
  generate = FALSE
)
nail_evidence(bretons_enriched)
nail_prompt(bretons_enriched, print = FALSE)
enrichment <- nail_catdes_enrichment(bretons_enriched)
enrichment$selected_texts[, c("text_id", "group", "source_row")]

# 3. Optional generation. Run manually only after reviewing the preview.
if (FALSE) {
  bretons_generated <- nail_catdes(
    dataset = bretons_prepared,
    num.var = 49,
    num.textual = 48,
    textual.sample = 0.5,
    textual.seed = 123,
    interpretation_mode = "latent",
    isolate.groups = FALSE,
    drop.negative = FALSE,
    introduction = intro_bretons,
    request = request_bretons,
    provider = "gemini",
    model = "gemini-2.5-flash",
    max_output_tokens = 32768L,
    max_tries = 1L,
    timeout = 120,
    generate = TRUE
  )
  first_pass_response <- nail_response(bretons_generated, print = FALSE)
  enrichment_generated <- nail_catdes_enrichment(bretons_generated)
  second_pass_response <- enrichment_generated$second_pass$responses[["portfolio"]]
}
