#' @importFrom glue glue
#' @importFrom utils globalVariables
utils::globalVariables(c())

# ---------------------------------------------------------------------------
# Helpers
# ---------------------------------------------------------------------------


# ---------------------------------------------------------------------------
# Builders
# ---------------------------------------------------------------------------

build_request_qda_spaceprep <- function(product_knowledge = c("known", "unknown"),
                                        expertise_mode = c("sensory", "positioning", "hybrid")) {
  product_knowledge <- match.arg(product_knowledge)
  expertise_mode <- match.arg(expertise_mode)
  unit_word <- .unit_word_qda(product_knowledge, capital = FALSE, plural = FALSE)
  unit_plural <- .unit_word_qda(product_knowledge, capital = FALSE, plural = TRUE)

  common_header <- c(
    glue::glue("Using only the results below, describe this {unit_word} as a relative profile within the full set of {unit_plural}."),
    "",
    "The goal is not only to describe it for itself, but to prepare a later multidimensional interpretation of the product space.",
    "Your task is to identify what makes this item occupy a particular position relative to the others.",
    "",
    "Focus on the retained attributes shown here under the current analysis settings.",
    "Think in terms of relative profile, contrast, and positioning within a broader product space."
  )

  sensory_rules <- c(
    "",
    "Interpretation mode: sensory",
    "Use sensory and perceptual vocabulary first.",
    "Anchor the interpretation in the retained attributes.",
    "Describe the item as a sensory profile relative to the others.",
    "Prefer sensory descriptors such as bitter, sweet, acidic, astringent, milky, cocoa-like, crunchy, melting, granular, sticky, caramel-like, or vanilla-like when supported by the results.",
    "Avoid branding, marketing, emotional, or hedonic wording.",
    "Avoid generic expressions such as 'experience', 'indulgent', 'premium', 'luxurious', or 'treat'.",
    "Do not summarize the profile in generic lifestyle or promotional terms."
  )

  positioning_rules <- c(
    "",
    "Interpretation mode: positioning",
    "You may use broader product-style vocabulary.",
    "You may infer what kind of product style or product pole this item seems to represent.",
    "Stay grounded in the retained attributes shown here.",
    "Do not invent claims unrelated to the retained profile."
  )

  hybrid_rules <- c(
    "",
    "Interpretation mode: hybrid",
    "Start from the sensory profile and then infer a broader product style.",
    "Keep the sensory evidence primary and the broader positioning secondary.",
    "Do not let broader wording replace the retained sensory evidence."
  )

  general_rules <- c(
    "",
    "Rules:",
    "- Stay close to the retained results.",
    "- Emphasize the attributes that most distinguish this item from the average profile.",
    "- Distinguish what is most central from what is more secondary.",
    "- Think in terms of contrasts and positioning, not only simple description.",
    "- Do not invent causal explanations.",
    "- Do not write a long paragraph.",
    "- Use the exact output format below.",
    "",
    "Output format:",
    "Core profile: [One short sentence summarizing the profile.]",
    "",
    "Distinctive positive traits: [3 to 5 attributes clearly above the average profile, separated by semicolons.]",
    "",
    "Distinctive negative traits: [3 to 5 attributes clearly below the average profile, separated by semicolons. If none, write: none]",
    "",
    if (expertise_mode == "sensory") {
      "Positioning cues: [One short sentence indicating what sensory pole or sensory direction this item seems to represent in a broader product space.]"
    } else {
      "Positioning cues: [One short sentence indicating what kind of pole, direction, or role this item seems to represent in a broader product space.]"
    },
    "",
    "Profile clarity: [Choose exactly one: strong / moderate / mixed / weak]",
    "",
    if (expertise_mode == "sensory") {
      "Injectable summary: [One short sentence describing the item as a sensory profile relative to the other items. Avoid generic promotional wording.]"
    } else {
      "Injectable summary: [One short sentence reusable later when interpreting a product space.]"
    }
  )

  mode_block <- switch(
    expertise_mode,
    sensory = sensory_rules,
    positioning = positioning_rules,
    hybrid = hybrid_rules
  )

  paste(c(common_header, mode_block, general_rules), collapse = "\n")
}

build_conclusion_qda_spaceprep <- function() {
  paste(
    "# Output constraint",
    "Your answer must contain exactly six lines and nothing else.",
    "Do not use Markdown.",
    "Do not use bold text.",
    "Do not use bullet points.",
    "Do not add any introduction such as 'Here is the output'.",
    "Each line must follow exactly this format: Field name: value",
    "",
    "Core profile: ...",
    "Distinctive positive traits: ...",
    "Distinctive negative traits: ...",
    "Positioning cues: ...",
    "Profile clarity: ...",
    "Injectable summary: ...",
    sep = "\n"
  )
}

# ---------------------------------------------------------------------------
# Parser
# ---------------------------------------------------------------------------

parse_qda_spaceprep_response <- function(text) {
  text <- paste(text, collapse = "\n")
  text <- gsub("\r\n", "\n", text, fixed = TRUE)
  text <- gsub("\r", "\n", text, fixed = TRUE)
  text <- .strip_markdown_fences(text)

  text <- gsub("(?im)^\\s*here is the output\\s*:?\\s*\\n?", "", text, perl = TRUE)
  text <- gsub("(?im)^\\s*output\\s*:?\\s*\\n?", "", text, perl = TRUE)

  fields <- c(
    "Core profile",
    "Distinctive positive traits",
    "Distinctive negative traits",
    "Positioning cues",
    "Profile clarity",
    "Injectable summary"
  )

  core_profile <- .extract_field_block(text, "Core profile", fields)
  positive_traits_raw <- .extract_field_block(text, "Distinctive positive traits", fields)
  negative_traits_raw <- .extract_field_block(text, "Distinctive negative traits", fields)
  positioning_cues <- .extract_field_block(text, "Positioning cues", fields)
  profile_clarity <- .extract_field_block(text, "Profile clarity", fields)
  injectable_summary <- .extract_field_block(text, "Injectable summary", fields)

  positive_traits <- .split_semicolon_traits(positive_traits_raw)
  negative_traits <- .split_semicolon_traits(negative_traits_raw)

  if (!is.na(profile_clarity)) {
    profile_clarity <- tolower(trimws(profile_clarity))
  }

  list(
    core_profile = core_profile,
    positive_traits = positive_traits,
    negative_traits = negative_traits,
    positioning_cues = positioning_cues,
    profile_clarity = profile_clarity,
    injectable_summary = injectable_summary
  )
}

# ---------------------------------------------------------------------------
# Main
# ---------------------------------------------------------------------------

#' Prepare historical product-wise summaries for product-space interpretation
#'
#' `nail_qda_spaceprep()` is retained for backward compatibility with the
#' historical QDA-space workflow. It is no longer required by the rebuilt
#' [nail_qda_space()] implementation.
#'
#' New analyses should use [nail_qda()] directly, optionally inspect or revise
#' product interpretations with [nail_qda_interpretation()], and then pass the
#' resulting QDA object to [nail_qda_space()].
#'
#' The historical function still reuses `nail_qda()` in isolated mode with a
#' dedicated prompt to create structured product summaries for older code.
#'
#' @param dataset QDA dataset.
#' @param formul Formula passed to `nail_qda()`.
#' @param firstvar Index of first sensory variable.
#' @param lastvar Index of last sensory variable.
#' @param model LLM model name for the selected provider.
#' @param provider LLM backend to use for generation. Use `"ollama"` for a local Ollama model or `"gemini"` for Google Gemini via `GEMINI_API_KEY`.
#' @param proba Significance threshold forwarded to `nail_qda()`.
#' @param sample.pct Proportion of retained attributes kept in each prompt.
#' @param drop.negative Whether to hide negative v.tests.
#' @param product_knowledge Either `"known"` or `"unknown"`.
#' @param expertise_mode Either `"sensory"`, `"positioning"`, or `"hybrid"`.
#' @param generate If FALSE, returns prompts only. If TRUE, returns prompts,
#' raw responses, and parsed structured summaries.
#' @param ... Additional provider-specific generation arguments passed to the selected LLM backend.
#'
#' @return If `generate = FALSE`, a named list of prompts.
#' If `generate = TRUE`, a named list where each element contains:
#' - prompt
#' - response
#' - parsed
#'
#' @export
nail_qda_spaceprep <- function(dataset, formul, firstvar,
                               lastvar = length(colnames(dataset)),
                               model = "llama3",
                               provider = c("ollama", "gemini"),
                               proba = 0.05,
                               sample.pct = 1,
                               drop.negative = FALSE,
                               product_knowledge = c("known", "unknown"),
                               expertise_mode = c("sensory", "positioning", "hybrid"),
                               generate = FALSE,
                               ...) {
  product_knowledge <- match.arg(product_knowledge)
  expertise_mode <- match.arg(expertise_mode)
  provider <- match.arg(provider)

  intro <- if (product_knowledge == "known") {
    paste(
      "The product below belongs to a common sensory product set.",
      "The goal is to describe this product as a relative profile that may later help interpret the overall product space."
    )
  } else {
    paste(
      "The stimulus below belongs to a common sensory set.",
      "The goal is to describe this stimulus as a relative profile that may later help interpret the overall product space."
    )
  }

  req <- build_request_qda_spaceprep(
    product_knowledge = product_knowledge,
    expertise_mode = expertise_mode
  )

  concl <- build_conclusion_qda_spaceprep()

  prompts_or_results <- nail_qda(
    dataset = dataset,
    formul = formul,
    firstvar = firstvar,
    lastvar = lastvar,
    introduction = intro,
    request = req,
    conclusion = concl,
    model = model,
    provider = provider,
    isolate.groups = TRUE,
    drop.negative = drop.negative,
    proba = proba,
    sample.pct = sample.pct,
    prompt_style = "compact",
    product_knowledge = product_knowledge,
    generate = generate,
    ...
  )

  if (!generate) {
    return(prompts_or_results)
  }

  out <- lapply(prompts_or_results, function(x) {
    response_text <- paste(x$response, collapse = "\n")

    parsed <- tryCatch(
      parse_qda_spaceprep_response(response_text),
      error = function(e) {
        list(
          core_profile = NA_character_,
          positive_traits = character(0),
          negative_traits = character(0),
          positioning_cues = NA_character_,
          profile_clarity = NA_character_,
          injectable_summary = NA_character_
        )
      }
    )

    list(
      prompt = x$prompt,
      response = response_text,
      parsed = parsed
    )
  })

  names(out) <- names(prompts_or_results)
  out
}
