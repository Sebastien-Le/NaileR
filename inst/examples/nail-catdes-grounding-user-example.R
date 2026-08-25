# NaileR — user example for nail_catdes() + nail_catdes_ground()
#
# PASS 1:
#   statistical evidence -> local semantic interpretation
#
# PASS 2 (optional):
#   frozen PASS 1 interpretation -> epistemic review
#
# The script does not call an LLM unless NAILER_RUN_LLM=true.
#
# Example:
#   Sys.setenv(NAILER_RUN_LLM = "true")
#   Sys.setenv(NAILER_MODEL = "mistral-small3.2")
#   source("NaileR-catdes-grounding-user-example.R")

library(NaileR)

# ---------------------------------------------------------------------------
# Helpers
# ---------------------------------------------------------------------------

print_ground_profile <- function(x, group) {

  profile <- x$grounded_profiles[[group]]

  cat("\n##", group, "\n\n")

  if (!length(profile$assertions)) {
    cat("No grounded assertions available.\n")
    return(invisible(profile))
  }

  for (a in profile$assertions) {

    cat(
      sprintf(
        "[%s | temperature=%d | %s | support=%s]\n",
        toupper(a$epistemic_level),
        a$epistemic_temperature,
        toupper(a$grounding$status),
        toupper(a$grounding$support_type)
      )
    )

    cat(a$text, "\n")

    if (length(a$grounding$supporting_evidence_ids)) {
      cat(
        "supporting evidence:",
        paste(
          a$grounding$supporting_evidence_ids,
          collapse = " | "
        ),
        "\n"
      )
    }

    if (length(a$grounding$contradicting_evidence_ids)) {
      cat(
        "contradicting evidence:",
        paste(
          a$grounding$contradicting_evidence_ids,
          collapse = " | "
        ),
        "\n"
      )
    }

    cat("rationale:", a$grounding$rationale, "\n\n")
  }

  invisible(profile)
}

collect_assertions <- function(x) {

  rows <- lapply(
    names(x$grounded_profiles),
    function(group) {

      assertions <- x$grounded_profiles[[group]]$assertions

      if (!length(assertions))
        return(NULL)

      do.call(
        rbind,
        lapply(
          assertions,
          function(a) {
            data.frame(
              group = group,
              text = a$text,
              epistemic_level = a$epistemic_level,
              temperature = a$epistemic_temperature,
              grounding = a$grounding$status,
              support = a$grounding$support_type,
              stringsAsFactors = FALSE
            )
          }
        )
      )
    }
  )

  rows <- Filter(Negate(is.null), rows)

  if (!length(rows)) {
    return(data.frame())
  }

  do.call(rbind, rows)
}

timing_table <- function(x) {

  calls <- x$timing$grounding_calls
  calls <- calls[!vapply(calls, is.null, logical(1))]

  if (!length(calls))
    return(data.frame())

  data.frame(
    group = names(calls),

    elapsed = vapply(
      calls,
      function(z) z$total$elapsed_seconds,
      numeric(1)
    ),

    backend = vapply(
      calls,
      function(z) z$backend$elapsed_seconds,
      numeric(1)
    ),

    parse_validate = vapply(
      calls,
      function(z) z$parse_and_validate$elapsed_seconds,
      numeric(1)
    ),

    stringsAsFactors = FALSE
  )
}

# ---------------------------------------------------------------------------
# 1. Reproducible observed-category example
# ---------------------------------------------------------------------------

set.seed(20260819)

n <- 240

segment <- factor(
  rep(c("Routine", "Explorer", "Involved"), each = n / 3)
)

tea <- data.frame(
  specialist_shop = factor(c(
    sample(c("yes", "no"), n / 3, TRUE, c(0.15, 0.85)),
    sample(c("yes", "no"), n / 3, TRUE, c(0.45, 0.55)),
    sample(c("yes", "no"), n / 3, TRUE, c(0.80, 0.20))
  )),

  loose_leaf = factor(c(
    sample(c("yes", "no"), n / 3, TRUE, c(0.10, 0.90)),
    sample(c("yes", "no"), n / 3, TRUE, c(0.50, 0.50)),
    sample(c("yes", "no"), n / 3, TRUE, c(0.85, 0.15))
  )),

  organic = factor(c(
    sample(c("yes", "no"), n / 3, TRUE, c(0.20, 0.80)),
    sample(c("yes", "no"), n / 3, TRUE, c(0.65, 0.35)),
    sample(c("yes", "no"), n / 3, TRUE, c(0.55, 0.45))
  )),

  consumption_frequency = c(
    rnorm(n / 3, 2.5, 0.7),
    rnorm(n / 3, 4.5, 0.8),
    rnorm(n / 3, 6.5, 0.7)
  ),

  willingness_to_pay = c(
    rnorm(n / 3, 3.5, 0.8),
    rnorm(n / 3, 5.5, 0.9),
    rnorm(n / 3, 7.5, 0.8)
  ),

  Segment = segment
)

INTRODUCTION <- paste(
  "A study investigates tea purchasing and consumption practices.",
  "The three segments are observed categories defined before this analysis."
)

REQUEST <- paste(
  "Explain the profile of each segment by combining the selected facts.",
  "Keep the original segment names."
)

# ---------------------------------------------------------------------------
# 2. PASS 1 preview — no LLM call
# ---------------------------------------------------------------------------

pass1_preview <- nail_catdes(
  tea,
  num.var = ncol(tea),
  introduction = INTRODUCTION,
  request = REQUEST,
  interpretation_mode = "standard",
  quali.sample = 0.10,
  quanti.sample = 0.10,
  drop.negative = FALSE,
  generate = FALSE
)

cat("\n=== PASS 1 PREVIEW ===\n")
cat(pass1_preview, "\n")

semantic_facts <- attr(
  pass1_preview,
  "semantic_facing_evidence"
)

cat("\n=== SEMANTIC-FACING FACTS: INVOLVED ===\n")
cat(
  semantic_facts$groups$Involved$text,
  "\n"
)

# ---------------------------------------------------------------------------
# 3. Optional real LLM run
# ---------------------------------------------------------------------------

RUN_LLM <- identical(
  tolower(Sys.getenv("NAILER_RUN_LLM")),
  "true"
)

MODEL <- Sys.getenv(
  "NAILER_MODEL",
  unset = "mistral-small3.2"
)

if (!RUN_LLM) {

  cat(
    "\nNo LLM call was made.\n",
    "To run PASS 1 and PASS 2:\n",
    '  Sys.setenv(NAILER_RUN_LLM = "true")\n',
    '  Sys.setenv(NAILER_MODEL = "mistral-small3.2")\n',
    "  source(this_script)\n",
    sep = ""
  )

} else {

  # -------------------------------------------------------------------------
  # 4. PASS 1 generation
  # -------------------------------------------------------------------------

  pass1 <- nail_catdes(
    tea,
    num.var = ncol(tea),
    introduction = INTRODUCTION,
    request = REQUEST,
    interpretation_mode = "standard",
    quali.sample = 0.10,
    quanti.sample = 0.10,
    drop.negative = FALSE,
    provider = "ollama",
    model = MODEL,
    generate = TRUE
  )

  cat("\n=== PASS 1 INTERPRETATION ===\n")
  cat(pass1$response, "\n")

  # -------------------------------------------------------------------------
  # 5. PASS 2 preview — no LLM call
  # -------------------------------------------------------------------------

  ground_preview <- nail_catdes_ground(
    pass1,
    generate = FALSE
  )

  cat("\n=== PASS 2 PREVIEW: EXPLORER ===\n")
  cat(
    ground_preview$grounding_prompts$Explorer,
    "\n"
  )

  # -------------------------------------------------------------------------
  # 6. PASS 2 generation
  # -------------------------------------------------------------------------

  ground <- nail_catdes_ground(
    pass1,
    generate = TRUE
  )

  cat("\n=== GROUNDED PROFILE: EXPLORER ===\n")
  print_ground_profile(
    ground,
    "Explorer"
  )

  cat("\n=== GROUNDED PROFILE: INVOLVED ===\n")
  print_ground_profile(
    ground,
    "Involved"
  )

  cat("\n=== GROUNDED PROFILE: ROUTINE ===\n")
  print_ground_profile(
    ground,
    "Routine"
  )

  # -------------------------------------------------------------------------
  # 7. Fast epistemic audit
  # -------------------------------------------------------------------------

  review_table <- collect_assertions(ground)

  cat("\n=== ASSERTIONS REQUIRING CAUTION ===\n")

  print(
    subset(
      review_table,
      temperature >= 2 |
        grounding != "supported"
    ),
    row.names = FALSE
  )

  cat("\n=== HYPOTHESES ===\n")

  print(
    subset(
      review_table,
      epistemic_level == "hypothesis"
    ),
    row.names = FALSE
  )

  cat("\n=== CONTRADICTED ASSERTIONS ===\n")

  print(
    subset(
      review_table,
      grounding == "contradicted"
    ),
    row.names = FALSE
  )

  # -------------------------------------------------------------------------
  # 8. Timing
  # -------------------------------------------------------------------------

  cat("\n=== PASS 2 TIMING ===\n")

  cat(
    sprintf(
      "Total elapsed time: %.3f s\n",
      ground$timing$total$elapsed_seconds
    )
  )

  print(
    timing_table(ground),
    row.names = FALSE
  )

  # -------------------------------------------------------------------------
  # 9. Advanced audit examples
  # -------------------------------------------------------------------------

  cat("\n=== PASS 1 / PASS 2 PRESERVATION CHECK ===\n")

  stopifnot(
    identical(
      ground$semantic_profiles,
      attr(pass1, "semantic_profiles")
    )
  )

  cat("PASS 1 semantic profiles are preserved in PASS 2: TRUE\n")

  cat("\n=== CANONICAL EVIDENCE MAP: EXPLORER ===\n")
  print(
    ground$evidence_reference_maps$Explorer
  )
}
