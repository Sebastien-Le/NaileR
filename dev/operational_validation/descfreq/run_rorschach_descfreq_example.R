#!/usr/bin/env Rscript

# Deterministic, offline Rorschach example for nail_descfreq().
# This script deliberately does not call an LLM. It constructs a contingency
# table from observed description tokens and leaves significance selection to
# FactoMineR::descfreq(), through NaileR.

repo <- Sys.getenv("NAILER_REPO", unset = getwd())
if (file.exists(file.path(repo, "DESCRIPTION"))) {
  if (!requireNamespace("devtools", quietly = TRUE)) {
    stop("Install the devtools package or run this script with an installed NaileR.")
  }
  devtools::load_all(repo, quiet = TRUE)
}

if (!requireNamespace("NaileR", quietly = TRUE)) {
  stop("NaileR is not available. Set NAILER_REPO or install NaileR first.")
}

data(rorschach, package = "NaileR")
stopifnot(
  identical(dim(rorschach), c(600L, 5L)),
  identical(
    names(rorschach),
    c("Panel", "Inkblot", "Panelist", "Consumer", "Description")
  ),
  all(vapply(rorschach[1:4], is.factor, logical(1))),
  is.character(rorschach$Description),
  nlevels(rorschach$Panel) == 3L,
  nlevels(rorschach$Inkblot) == 10L,
  nlevels(rorschach$Panelist) == 20L
)

# These terms are observed in the supplied descriptions. The rule counts a
# term once per description, so repeated mentions do not inflate a response.
rorschach_terms <- c(
  "animal", "bat", "black", "butterfly", "color", "red"
)
rorschach_tokens <- strsplit(
  tolower(gsub("[^a-z]+", " ", rorschach$Description)),
  "\\s+"
)
rorschach_counts <- vapply(
  rorschach_terms,
  function(term) {
    vapply(
      rorschach_tokens,
      function(tokens) as.numeric(term %in% tokens),
      numeric(1)
    )
  },
  numeric(nrow(rorschach))
)

tab_rorschach <- aggregate(
  rorschach_counts,
  by = list(Inkblot = rorschach$Inkblot),
  FUN = sum
)
rownames(tab_rorschach) <- as.character(tab_rorschach$Inkblot)
tab_rorschach$Inkblot <- NULL
tab_rorschach <- tab_rorschach[, colSums(tab_rorschach) > 0, drop = FALSE]

stopifnot(
  identical(dim(tab_rorschach), c(10L, 6L)),
  identical(rownames(tab_rorschach), as.character(1:10)),
  all(tab_rorschach >= 0),
  all(tab_rorschach == round(tab_rorschach)),
  all(colSums(tab_rorschach) > 0),
  identical(as.numeric(colSums(tab_rorschach)), c(75, 42, 70, 27, 68, 25))
)

preview <- NaileR::nail_descfreq(
  dataset = tab_rorschach,
  introduction = paste(
    "Participants described ten Rorschach inkblots.",
    "This contingency table counts six observed descriptive terms",
    "at most once per description across the ten inkblots."
  ),
  request = paste(
    "Describe the perceptual characteristics associated with each inkblot",
    "using the retained frequency evidence. Distinguish inkblots based on",
    "their descriptions without inferring personality or causal mechanisms."
  ),
  proba = 0.05,
  interpretation_mode = "comparison",
  isolate.groups = FALSE,
  generate = FALSE
)

evidence <- NaileR::nail_evidence(preview)
prompt <- NaileR::nail_prompt(preview, print = FALSE)
preview_response <- tryCatch(
  NaileR::nail_response(preview, print = FALSE),
  error = function(error) error
)
stopifnot(
  length(prompt) == 1L,
  nrow(evidence$evidence_registry) == 22L,
  inherits(preview_response, "error")
)

cat("Rorschach input: 600 x 5\n")
cat("Contingency table:", paste(dim(tab_rorschach), collapse = " x "), "\n")
cat("Term totals:", paste(colSums(tab_rorschach), collapse = ", "), "\n")
cat("Selected markers:", nrow(evidence$evidence_registry), "\n")
cat("Prompt characters:", nchar(prompt), "\n")
