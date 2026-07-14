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
    "Use sensory and perceptual vocabulary only.",
    "Anchor every interpretation in the retained attributes shown below.",
    "Use the exact attribute labels whenever possible.",
    "You may reformulate an attribute label only to improve readability, without changing its substantive meaning.",
    "Describe the item as a relative sensory profile within the full product set.",
    "Interpret attributes according to their sensory modality when this information is supported by their labels, such as appearance, odor or aroma, taste or flavor, texture or mouthfeel, trigeminal sensations, sound, or temporal perception.",
    "Do not introduce sensory descriptors that are absent from the retained results."
  )

  positioning_rules <- c(
    "",
    "Interpretation mode: positioning",
    "You may use broader sensory-profile vocabulary.",
    "You may infer what kind of sensory style or sensory pole this item seems to represent within the analyzed set.",
    "Here, positioning refers to relative sensory positioning, not market positioning.",
    "Stay grounded in the retained attributes shown here.",
    "Do not infer target consumers, brand image, price level, liking, quality, or commercial value.",
    "Do not invent claims unrelated to the retained profile."
  )

  hybrid_rules <- c(
    "",
    "Interpretation mode: hybrid",
    "Start from the sensory profile and then infer a broader sensory style or sensory direction.",
    "Keep the sensory evidence primary and the broader positioning secondary.",
    "Here, positioning refers only to relative sensory positioning within the analyzed set.",
    "Do not let broader wording replace the retained sensory evidence.",
    "Do not infer liking, quality, target consumers, market segment, or commercial value."
  )

  general_rules <- c(
    "",
    "Rules:",
    "- Stay close to the retained results.",
    "- Emphasize the attributes that most distinguish this item from the average profile.",
    "- Preserve the direction of each result: clearly distinguish attributes above the average profile from attributes below the average profile.",
    "- Distinguish what is most central from what is more secondary.",
    "- Treat above-average and below-average intensities as descriptive sensory differences, not as favorable or unfavorable characteristics.",
    "- Do not infer liking, preference, acceptance, quality, desirability, superiority, inferiority, or commercial value.",
    "- Do not infer ingredients, composition, manufacturing processes, or physical mechanisms unless they are explicitly provided in the study context.",
    "- Avoid branding, marketing, emotional, lifestyle, and promotional wording.",
    "- Do not use generic evaluative expressions such as 'premium', 'luxurious', 'indulgent', 'appealing', or 'treat'.",
    "- Think in terms of sensory contrasts and relative positioning, not only simple description.",
    "- Do not invent causal explanations.",
    "- Do not write a long paragraph.",
    "- Use the exact output format below.",
    "",
    "Output format:",
    "Core profile: [One short sentence summarizing the profile.]",
    "",
    "Distinctive above-average traits: [3 to 5 attributes clearly above the average profile, separated by semicolons.]",
    "",
    "Distinctive below-average traits: [3 to 5 attributes clearly below the average profile, separated by semicolons. If none, write: none]",
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
    "Distinctive above-average traits: ...",
    "Distinctive below-average traits: ...",
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

  text <- gsub(
    "(?im)^\\s*here is the output\\s*:?\\s*\\n?",
    "",
    text,
    perl = TRUE
  )

  text <- gsub(
    "(?im)^\\s*output\\s*:?\\s*\\n?",
    "",
    text,
    perl = TRUE
  )

  # Backward compatibility with responses using the former field names.
  text <- gsub(
    "(?im)^\\s*Distinctive positive traits\\s*:",
    "Distinctive above-average traits:",
    text,
    perl = TRUE
  )

  text <- gsub(
    "(?im)^\\s*Distinctive negative traits\\s*:",
    "Distinctive below-average traits:",
    text,
    perl = TRUE
  )

  fields <- c(
    "Core profile",
    "Distinctive above-average traits",
    "Distinctive below-average traits",
    "Positioning cues",
    "Profile clarity",
    "Injectable summary"
  )

  core_profile <- .extract_field_block(
    text,
    "Core profile",
    fields
  )

  above_traits_raw <- .extract_field_block(
    text,
    "Distinctive above-average traits",
    fields
  )

  below_traits_raw <- .extract_field_block(
    text,
    "Distinctive below-average traits",
    fields
  )

  positioning_cues <- .extract_field_block(
    text,
    "Positioning cues",
    fields
  )

  profile_clarity <- .extract_field_block(
    text,
    "Profile clarity",
    fields
  )

  injectable_summary <- .extract_field_block(
    text,
    "Injectable summary",
    fields
  )

  above_traits <- .split_semicolon_traits(above_traits_raw)
  below_traits <- .split_semicolon_traits(below_traits_raw)

  if (!is.na(profile_clarity)) {
    profile_clarity <- tolower(trimws(profile_clarity))
  }

  list(
    core_profile = core_profile,
    above_average_traits = above_traits,
    below_average_traits = below_traits,
    positioning_cues = positioning_cues,
    profile_clarity = profile_clarity,
    injectable_summary = injectable_summary
  )
}

# ---------------------------------------------------------------------------
# Main
# ---------------------------------------------------------------------------

#' Prepare optional product-level LLM summaries for product-space interpretation
#'
#' Creates short, structured summaries of individual product profiles for
#' optional use in a later interpretation of a multidimensional product
#' space.
#'
#' The function reuses `nail_qda()` with one isolated prompt per product and
#' requests a standardized six-field response describing:
#'
#' - the core sensory profile;
#' - the main attributes above the average product profile;
#' - the main attributes below the average product profile;
#' - the product's possible positioning within a broader product space;
#' - the clarity of the profile;
#' - a short summary suitable for later reuse.
#'
#' These summaries do not contribute to the statistical construction of the
#' product space. In particular, they do not modify the adjusted product
#' means, the PCA, the eigenvalues, or the product coordinates computed by
#' `nail_qda_space()`.
#'
#' This preparation step is optional. `nail_qda_space()` can be used directly
#' on an object returned by `nail_qda()` without calling
#' `nail_qda_spaceprep()`.
#'
#' @param dataset A data frame containing the QDA sensory evaluations.
#'
#'   Rows generally correspond to evaluations of products by panelists. The
#'   data frame must contain the categorical variables used in `formul`,
#'   followed by the quantitative sensory attributes specified by `firstvar`
#'   and `lastvar`.
#'
#'   In a standard QDA design, the categorical variables usually include a
#'   product factor and a panelist factor, while the quantitative variables
#'   contain sensory intensity scores.
#' @param formul A one-sided analysis-of-variance formula passed to
#'   `nail_qda()`.
#'
#'   It is typically supplied as a character string, for example:
#'
#'   ```
#'   "~Product+Panelist"
#'   ```
#'
#'   The first term on the right-hand side must identify the product or
#'   stimulus factor whose levels are to be summarized.
#'
#'   For example, in `"~Product+Panelist"`, `Product` is characterized and
#'   `Panelist` is included to account for systematic differences among
#'   panelists.
#' @param firstvar A single integer giving the column index of the first
#'   quantitative sensory attribute to analyze.
#' @param lastvar A single integer giving the column index of the last
#'   quantitative sensory attribute to analyze. The default is the last column
#'   of `dataset`.
#' @param model Character string giving the language model used by the selected
#'   provider. The default is `"llama3"`, intended for the default Ollama
#'   backend.
#' @param provider LLM backend used when `generate = TRUE`. One of
#'   `"ollama"` or `"gemini"`.
#'
#'   The default is `"ollama"`, which uses a local Ollama installation.
#'
#'   Gemini requires a valid API key, typically supplied through the
#'   `GEMINI_API_KEY` environment variable.
#' @param proba A numeric value between 0 and 1 giving the significance
#'   threshold forwarded to `nail_qda()`. The default is `0.05`.
#'
#'   Only product-by-attribute results retained under this threshold are
#'   available for inclusion in the individual product prompts.
#' @param sample.pct A numeric value between 0 and 1 giving the proportion of
#'   retained sensory attributes included in each product prompt. The default
#'   is `1`, meaning that all retained attributes are included.
#'
#'   Lower values may be useful when many sensory attributes characterize a
#'   product and shorter prompts are required.
#'
#'   Sampling changes only the information included in the prompts. It does
#'   not alter the underlying QDA analysis.
#'
#'   Use `set.seed()` before calling the function when reproducible sampling
#'   is required.
#' @param drop.negative Logical indicating whether sensory attributes with
#'   negative v-tests should be excluded from the individual product prompts.
#'   The default is `FALSE`.
#'
#'   With `drop.negative = FALSE`, the prompt may contain both:
#'
#'   - attributes above the average product profile;
#'   - attributes below the average product profile.
#'
#'   This generally provides the most complete relative description of each
#'   product.
#'
#'   With `drop.negative = TRUE`, only attributes associated with positive
#'   v-tests are retained. The resulting summary focuses on sensory attributes
#'   that are more intense than in the average product profile.
#' @param product_knowledge Character string indicating how the product labels
#'   should be treated. One of `"known"` or `"unknown"`.
#'
#'   With `"known"`, the levels of the product factor are treated as meaningful
#'   product names or established identifiers.
#'
#'   With `"unknown"`, the levels are treated as anonymous stimulus codes. The
#'   summaries may then describe the sensory style represented by the
#'   stimulus without assuming prior knowledge of its identity.
#'
#'   This argument changes the terminology and interpretation instructions in
#'   the prompts. It does not change the statistical analysis.
#' @param expertise_mode Character string controlling the vocabulary and the
#'   level of interpretation requested for each product. One of `"sensory"`,
#'   `"positioning"`, or `"hybrid"`.
#'
#'   With `"sensory"`, the response must remain closely anchored in sensory
#'   and perceptual vocabulary. Promotional, emotional, branding, and hedonic
#'   interpretations are discouraged.
#'
#'   With `"positioning"`, the response may infer a broader product style,
#'   product pole, or positioning, provided that this interpretation remains
#'   grounded in the retained sensory attributes.
#'
#'   With `"hybrid"`, the response first describes the sensory profile and may
#'   then infer a broader product style. The sensory evidence must remain
#'   primary.
#'
#'   When the summaries are later supplied to `nail_qda_space()`, using the
#'   same `expertise_mode` in both functions generally produces the most
#'   coherent interpretation.
#' @param generate Logical.
#'
#'   If `FALSE`, no language model is called. The function returns one
#'   structured prompt per product.
#'
#'   If `TRUE`, each product prompt is sent separately to the selected LLM
#'   backend. The function returns the prompt, raw response, and parsed
#'   structured summary for each product.
#'
#'   Because one LLM request is made per product, processing time and API usage
#'   increase with the number of products.
#' @param ... Additional provider-specific generation arguments passed to the
#'   selected LLM backend, such as `temperature`, `seed`, or other supported
#'   options.
#'
#' @details
#' ## Purpose of the function
#'
#' `nail_qda_spaceprep()` prepares concise textual summaries of individual
#' products before the interpretation of a multidimensional product space.
#'
#' It does not compute the product-space PCA. The PCA is computed later by
#' `nail_qda_space()` from the adjusted product mean table returned by
#' `SensoMineR::decat()`.
#'
#' The summaries created here are used only as optional product-level context.
#' They can help explain how products located at the ends of a PCA dimension
#' express the sensory opposition identified from the variables.
#'
#' The minimal workflow is therefore:
#'
#' ```
#' qda_result <- nail_qda(...)
#' space_prompts <- nail_qda_space(x = qda_result)
#' ```
#'
#' The optional enriched workflow is:
#'
#' ```
#' qda_result <- nail_qda(...)
#'
#' product_summaries <- nail_qda_spaceprep(
#'   ...,
#'   generate = TRUE
#' )
#'
#' space_prompts <- nail_qda_space(
#'   x = qda_result,
#'   llm_product_summaries = product_summaries
#' )
#' ```
#'
#' ## Relationship with `nail_qda()`
#'
#' Internally, the function calls `nail_qda()` with:
#'
#' ```
#' isolate.groups = TRUE
#' prompt_style = "compact"
#' ```
#'
#' This means that the statistical characterization is computed from the
#' complete QDA dataset, but one separate prompt is constructed for each
#' product.
#'
#' Each product remains characterized relative to the average profile of the
#' complete product set. Isolating the prompts does not mean that the
#' statistical analysis is performed separately for each product.
#'
#' The function uses a dedicated introduction, request, and conclusion. These
#' instructions are intentionally standardized because the resulting summaries
#' must follow a stable structure before they can be reused by
#' `nail_qda_space()`.
#'
#' ## Requested response structure
#'
#' When `generate = TRUE`, the language model is instructed to return exactly
#' six fields:
#'
#' ```
#' Core profile: ...
#' Distinctive above-average traits: ...
#' Distinctive below-average traits: ...
#' Positioning cues: ...
#' Profile clarity: ...
#' Injectable summary: ...
#' ```
#'
#' Their intended meanings are:
#'
#' - `Core profile`: one short sentence summarizing the relative product
#'   profile;
#' - `Distinctive above-average traits`: three to five attributes clearly above the
#'   average product profile, separated by semicolons;
#' - `Distinctive below-average traits`: three to five attributes clearly below the
#'   average profile, or `"none"` when no such attribute is available;
#' - `Positioning cues`: one short sentence describing the sensory pole,
#'   broader product direction, or positioning suggested by the profile;
#' - `Profile clarity`: one of `"strong"`, `"moderate"`, `"mixed"`, or
#'   `"weak"`;
#' - `Injectable summary`: one short sentence intended for later inclusion in
#'   the product-level evidence of `nail_qda_space()`.
#'
#' The model is instructed not to add Markdown, bullets, introductory text, or
#' additional sections.
#'
#' ## Parsing the LLM response
#'
#' The raw response is parsed automatically into a named list.
#'
#' The parser:
#'
#' - removes common Markdown code fences;
#' - removes introductory expressions such as `"Here is the output"`;
#' - extracts the six expected fields;
#' - splits positive and negative traits at semicolons;
#' - converts `profile_clarity` to lower case.
#'
#' The parsed object contains:
#'
#' - `core_profile`: a character string or `NA`;
#' - `above_average_traits`: a character vector;
#' - `below_average_traits`: a character vector;
#' - `positioning_cues`: a character string or `NA`;
#' - `profile_clarity`: a lower-case character string or `NA`;
#' - `injectable_summary`: a character string or `NA`.
#'
#' Language models do not always follow formatting instructions perfectly.
#' Users should therefore inspect both the raw `response` and the `parsed`
#' result before using the summaries in a final analysis.
#'
#' If parsing fails for one product, the complete workflow is not interrupted.
#' The corresponding parsed result contains `NA` values and empty character
#' vectors where appropriate.
#'
#' ## Sensory, positioning, and hybrid modes
#'
#' In `"sensory"` mode, the model is instructed to remain within sensory and
#' perceptual vocabulary and to base every descriptor on the retained
#' attributes.
#'
#' Depending on the variables present in the dataset, the interpretation may
#' refer to appearance, odor or aroma, taste or flavor, texture or mouthfeel,
#' trigeminal sensations, sound, or temporal perception. No sensory modality
#' or descriptor is introduced unless it is supported by the retained
#' attribute labels.
#'
#' Generic promotional expressions such as `"premium"`, `"luxurious"`,
#' `"indulgent"`, or `"treat"` are discouraged.
#'
#' In `"positioning"` mode, the model may infer the broader product style or
#' pole represented by the item, but it must remain grounded in the retained
#' QDA attributes.
#'
#' In `"hybrid"` mode, the sensory profile is described first. A broader
#' product interpretation may then be proposed as a secondary conclusion.
#'
#' ## Positive and negative product traits
#'
#' The positive and negative traits refer to relative product profiles:
#'
#' - a positive trait is an attribute retained as higher than the average
#'   profile of the analyzed product set;
#' - a negative trait is an attribute retained as lower than the average
#'   profile.
#'
#' These terms do not mean desirable and undesirable. A negative trait is not
#' necessarily a defect; it only indicates a lower relative sensory intensity.
#'
#' For example, `"lower bitterness"` may be represented among the negative
#' traits because bitterness is less intense than in the average product, even
#' though this characteristic may be desirable for some consumers.
#'
#' ## Use in `nail_qda_space()`
#'
#' A valid result produced with `generate = TRUE` can be passed directly to:
#'
#' ```
#' nail_qda_space(
#'   x = qda_result,
#'   llm_product_summaries = product_summaries
#' )
#' ```
#'
#' For each extreme product, `nail_qda_space()` primarily uses:
#'
#' - `injectable_summary`;
#' - `positioning_cues`;
#' - `profile_clarity`.
#'
#' When no valid `injectable_summary` is available, `nail_qda_space()` falls
#' back to the deterministic product summary obtained from `nail_qda()`, when
#' available.
#'
#' Results produced with `generate = FALSE` contain prompts only. They cannot
#' provide parsed product summaries to `llm_product_summaries`.
#'
#' ## Generation considerations
#'
#' With `generate = TRUE`, one request is sent for every product. For a dataset
#' containing six products, six independent LLM requests are therefore made.
#'
#' The summaries are generated interpretations of statistical results. They
#' should be reviewed before being reused, particularly when product names,
#' commercial claims, or broader positioning language are involved.
#'
#' They should not be interpreted as causal findings or as a substitute for
#' examination of the original sensory data and QDA model.
#'
#' @return
#' The returned object depends on `generate`.
#'
#' When `generate = FALSE`, a named list of character prompts is returned, with
#' one element per product or stimulus.
#'
#' The names of the list correspond to the product levels characterized by
#' `nail_qda()`.
#'
#' When `generate = TRUE`, a named list is returned, with one element per
#' product or stimulus. Each element contains:
#'
#' - `prompt`: the exact character prompt sent to the selected LLM backend;
#' - `response`: the raw generated response, stored as a single character
#'   string;
#' - `parsed`: a named list containing the six structured fields extracted
#'   from the response.
#'
#' The `parsed` component contains:
#'
#' - `core_profile`;
#' - `above_average_traits`;
#' - `below_average_traits`;
#' - `positioning_cues`;
#' - `profile_clarity`;
#' - `injectable_summary`.
#'
#' If a response cannot be parsed, the corresponding `parsed` component is
#' returned with missing character fields and empty trait vectors rather than
#' stopping the complete multi-product workflow.
#'
#' @seealso
#' [nail_qda()], [nail_qda_space()], [SensoMineR::decat()]
#'
#' @export
#'
#' @examples
#' \dontrun{
#' # These examples use the sensochoc dataset from SensoMineR.
#' #
#' # The first example constructs the product prompts without
#' # calling a language model.
#' #
#' # The later examples use Ollama and may therefore take more
#' # than ten seconds to run.
#'
#' library(NaileR)
#' library(SensoMineR)
#'
#' data(chocolates, package = "SensoMineR")
#'
#'
#' ### Example 1: inspect one structured product prompt ###
#'
#' # Product is the first term in the model because it is
#' # the factor whose levels must be summarized.
#' #
#' # Panelist is included to account for systematic differences
#' # among assessors.
#' #
#' # generate = FALSE constructs one prompt per product
#' # without calling an LLM.
#' prep_prompts <- nail_qda_spaceprep(
#'   dataset = sensochoc,
#'   formul = "~Product+Panelist",
#'   firstvar = 5,
#'   lastvar = ncol(sensochoc),
#'   proba = 0.05,
#'   sample.pct = 1,
#'   drop.negative = FALSE,
#'   product_knowledge = "known",
#'   expertise_mode = "sensory",
#'   generate = FALSE
#' )
#'
#' # Display the products for which prompts were created.
#' names(prep_prompts)
#'
#' # Display the complete prompt for the first product.
#' cat(prep_prompts[[1]])
#'
#' # A prompt may also be accessed by product name.
#' cat(prep_prompts[["choc1"]])
#'
#'
#' ### Example 2: generate and parse one summary per product ###
#'
#' # Ollama must be running locally and the llama3 model
#' # must be installed.
#' #
#' # One LLM request is sent for each chocolate.
#' product_summaries <- nail_qda_spaceprep(
#'   dataset = sensochoc,
#'   formul = "~Product+Panelist",
#'   firstvar = 5,
#'   lastvar = ncol(sensochoc),
#'   proba = 0.05,
#'   sample.pct = 1,
#'   drop.negative = FALSE,
#'   product_knowledge = "known",
#'   expertise_mode = "sensory",
#'   provider = "ollama",
#'   model = "llama3",
#'   generate = TRUE
#' )
#'
#' # Display the products for which summaries were generated.
#' names(product_summaries)
#'
#' # Inspect the exact prompt sent for the first product.
#' cat(product_summaries[[1]]$prompt)
#'
#' # Inspect the unmodified LLM response.
#' cat(product_summaries[[1]]$response)
#'
#' # Inspect the structured fields extracted from the response.
#' product_summaries[[1]]$parsed
#'
#'
#' ### Example 3: inspect parsing quality across all products ###
#'
#' # Extract the profile clarity returned for each product.
#' vapply(
#'   product_summaries,
#'   function(x) x$parsed$profile_clarity,
#'   character(1)
#' )
#'
#' # Display the injectable summary for each product.
#' vapply(
#'   product_summaries,
#'   function(x) {
#'     value <- x$parsed$injectable_summary
#'     if (is.na(value)) "" else value
#'   },
#'   character(1)
#' )
#'
#' # Identify products for which the injectable summary is missing.
#' missing_summaries <- vapply(
#'   product_summaries,
#'   function(x) {
#'     value <- x$parsed$injectable_summary
#'     is.na(value) || !nzchar(trimws(value))
#'   },
#'   logical(1)
#' )
#'
#' names(product_summaries)[missing_summaries]
#'
#'
#' ### Example 4: reuse the summaries in nail_qda_space() ###
#'
#' # First construct the usual nail_qda() result.
#' # No LLM is required at this stage.
#' qda_choc <- nail_qda(
#'   dataset = sensochoc,
#'   formul = "~Product+Panelist",
#'   firstvar = 5,
#'   lastvar = ncol(sensochoc),
#'   product_knowledge = "known",
#'   generate = FALSE
#' )
#'
#' # Build the product-space prompts and add the optional
#' # structured LLM summaries for the extreme products.
#' enriched_space_prompts <- nail_qda_space(
#'   x = qda_choc,
#'   llm_product_summaries = product_summaries,
#'   ncp = 3,
#'   scale.unit = TRUE,
#'   min_inertia_pct = 10,
#'   expertise_mode = "sensory",
#'   generate = FALSE
#' )
#'
#' # Display the enriched prompt for the first retained dimension.
#' cat(enriched_space_prompts[[1]])
#'
#'
#' ### Example 5: prepare summaries for anonymous stimuli ###
#'
#' # Replace the original product levels with anonymous codes.
#' sensochoc_blind <- sensochoc
#'
#' levels(sensochoc_blind$Product) <- paste0(
#'   "Stimulus_",
#'   seq_len(nlevels(sensochoc_blind$Product))
#' )
#'
#' # product_knowledge = "unknown" indicates that the codes
#' # should be treated only as stimulus identifiers.
#' blind_prompts <- nail_qda_spaceprep(
#'   dataset = sensochoc_blind,
#'   formul = "~Product+Panelist",
#'   firstvar = 5,
#'   lastvar = ncol(sensochoc_blind),
#'   product_knowledge = "unknown",
#'   expertise_mode = "hybrid",
#'   generate = FALSE
#' )
#'
#' cat(blind_prompts[[1]])
#'
#'
#' ### Example 6: compare expertise modes without an LLM ###
#'
#' sensory_prompts <- nail_qda_spaceprep(
#'   dataset = sensochoc,
#'   formul = "~Product+Panelist",
#'   firstvar = 5,
#'   expertise_mode = "sensory",
#'   generate = FALSE
#' )
#'
#' positioning_prompts <- nail_qda_spaceprep(
#'   dataset = sensochoc,
#'   formul = "~Product+Panelist",
#'   firstvar = 5,
#'   expertise_mode = "positioning",
#'   generate = FALSE
#' )
#'
#' hybrid_prompts <- nail_qda_spaceprep(
#'   dataset = sensochoc,
#'   formul = "~Product+Panelist",
#'   firstvar = 5,
#'   expertise_mode = "hybrid",
#'   generate = FALSE
#' )
#'
#' # Compare the task instructions used in the first product prompt.
#' cat(sensory_prompts[[1]])
#' cat(positioning_prompts[[1]])
#' cat(hybrid_prompts[[1]])
#' }
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
          above_average_traits = character(0),
          below_average_traits = character(0),
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
