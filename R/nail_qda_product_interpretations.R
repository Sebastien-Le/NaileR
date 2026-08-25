# ===========================================================================
# Reusable QDA PASS1 product interpretations
# ===========================================================================

.build_qda_product_interpretation_instruction <- function(
    product_knowledge = c("known", "unknown")) {
  product_knowledge <- match.arg(product_knowledge)

  name_rule <- if (identical(product_knowledge, "known")) {
    "descriptive_name: none"
  } else {
    paste(
      "descriptive_name: <a short sensory name if justified;",
      "otherwise none>"
    )
  }

  paste(
    "## Reusable product interpretation metadata",
    "After the visible answer, append one HTML comment block for each product or stimulus discussed in the evidence.",
    "These comment blocks are for downstream reuse and are not part of the visible report.",
    "Use the exact product/stimulus label shown in the evidence.",
    "Base every field only on the sensory evidence displayed in this prompt.",
    "",
    "STRICT GROUNDING RULES FOR THE REUSABLE BLOCK:",
    "- Remain strictly sensory and descriptive.",
    "- Preserve the direction of every displayed fact. HIGHER means more of that named attribute; LOWER means less of that named attribute.",
    "- Do not turn a LOWER attribute into a positive presence of that attribute. For example, Sticky LOWER must not become 'sticky texture'.",
    "- Do not change the technical meaning of an attribute. For example, a sensory attribute named Melting must not be rewritten as physical 'melting point'.",
    "- Do not infer an opposite attribute that was not measured. LOWER Sweetness means less sweet, not necessarily bitter; LOWER Sticky does not imply smooth.",
    "- Do not introduce unsupported sensory descriptors such as velvety, creamy, tangy, rich, intense, or smooth unless they are directly supported by displayed evidence.",
    "- Do not use evaluative, hedonic, marketing, or positioning language such as indulgent, premium, appealing, bold, unique offering, experience, desirable, or high quality.",
    "- The distinctive_interpretation field must describe sensory distinctiveness relative to the evaluated set only.",
    "- When a synthesis cannot be stated without adding unsupported meaning, stay close to the measured sensory attributes.",
    "",
    "<!-- NAILER_PRODUCT_INTERPRETATION",
    "product: <exact label>",
    "core_profile: <one concise evidence-grounded sensory synthesis>",
    "dominant_configuration: <2 to 5 evidence-grounded sensory descriptors or short phrases separated by semicolons>",
    "secondary_configuration: <secondary evidence-grounded descriptors or short phrases separated by semicolons; write none if absent>",
    "distinctive_interpretation: <one concise strictly sensory statement of what distinguishes this item relative to the evaluated set>",
    name_rule,
    "END_NAILER_PRODUCT_INTERPRETATION -->",
    "",
    "Repeat the complete comment block once for every product/stimulus represented in the answer.",
    sep = "\n"
  )
}


.qda_clean_interpretation_value <- function(x) {
  if (length(x) == 0L || is.null(x) || is.na(x[[1L]])) {
    return(NA_character_)
  }

  value <- trimws(as.character(x[[1L]]))
  value <- sub("^['\"`]+", "", value)
  value <- sub("['\"`]+$", "", value)
  value <- trimws(value)

  if (!nzchar(value)) {
    return(NA_character_)
  }

  value
}


.qda_split_interpretation_terms <- function(x) {
  value <- .qda_clean_interpretation_value(x)

  if (is.na(value) ||
      tolower(value) %in% c("none", "na", "n/a", "not applicable")) {
    return(character(0))
  }

  out <- trimws(strsplit(value, ";", fixed = TRUE)[[1L]])
  out <- out[nzchar(out)]
  unique(out)
}


.qda_extract_interpretation_field <- function(block, field) {
  field_pattern <- gsub(
    "_",
    "[ _]+",
    field,
    fixed = TRUE
  )

  pattern <- paste0(
    "(?im)^\\s*",
    field_pattern,
    "\\s*:\\s*([^\\r\\n]*)"
  )

  hit <- regmatches(
    block,
    regexpr(pattern, block, perl = TRUE)
  )

  if (length(hit) == 0L || identical(hit, "")) {
    return(NA_character_)
  }

  value <- sub(
    paste0(
      "(?im)^\\s*",
      field_pattern,
      "\\s*:\\s*"
    ),
    "",
    hit,
    perl = TRUE
  )

  .qda_clean_interpretation_value(value)
}


.qda_extract_interpretation_blocks <- function(text) {
  if (is.null(text) || length(text) == 0L) {
    return(character(0))
  }

  text <- paste(as.character(text), collapse = "\n")

  # Accept the canonical NaileR marker and harmless model variations such as
  # `choc1_PRODUCT_INTERPRETATION ... END_choc1_PRODUCT_INTERPRETATION`.
  # The same prefix must be used at the opening and closing marker.
  pattern <- paste0(
    "(?s)<!--\\s*([^\\r\\n]*?)_PRODUCT_INTERPRETATION\\s*",
    "(.*?)",
    "\\s*END_\\1_PRODUCT_INTERPRETATION\\s*-->"
  )

  loc <- gregexpr(pattern, text, perl = TRUE)
  blocks <- regmatches(text, loc)[[1L]]

  if (length(blocks) == 1L && identical(blocks, "")) {
    return(character(0))
  }

  blocks
}


.qda_parse_interpretation_block <- function(block) {
  product <- .qda_extract_interpretation_field(
    block,
    "product"
  )
  core_profile <- .qda_extract_interpretation_field(
    block,
    "core_profile"
  )
  dominant_raw <- .qda_extract_interpretation_field(
    block,
    "dominant_configuration"
  )
  secondary_raw <- .qda_extract_interpretation_field(
    block,
    "secondary_configuration"
  )
  distinctive_interpretation <- .qda_extract_interpretation_field(
    block,
    "distinctive_interpretation"
  )
  descriptive_name <- .qda_extract_interpretation_field(
    block,
    "descriptive_name"
  )

  if (!is.na(descriptive_name) &&
      tolower(descriptive_name) %in%
        c("none", "na", "n/a", "not applicable")) {
    descriptive_name <- NA_character_
  }

  list(
    product = product,
    core_profile = core_profile,
    dominant_configuration =
      .qda_split_interpretation_terms(dominant_raw),
    secondary_configuration =
      .qda_split_interpretation_terms(secondary_raw),
    distinctive_interpretation =
      distinctive_interpretation,
    descriptive_name = descriptive_name,
    raw_block = block
  )
}


.qda_match_interpretation_product <- function(label,
                                              product_names) {
  label <- .qda_clean_interpretation_value(label)

  if (is.na(label)) {
    return(NA_character_)
  }

  if (label %in% product_names) {
    return(label)
  }

  lower_match <- which(
    tolower(product_names) == tolower(label)
  )

  if (length(lower_match) == 1L) {
    return(product_names[[lower_match]])
  }

  NA_character_
}


.qda_empty_product_interpretation <- function(product_name,
                                              status,
                                              evidence_ids,
                                              response_key = NA_character_) {
  list(
    product = product_name,
    status = status,
    source = "llm_pass1",
    core_profile = NA_character_,
    dominant_configuration = character(0),
    secondary_configuration = character(0),
    distinctive_interpretation = NA_character_,
    descriptive_name = NA_character_,
    evidence_ids = as.character(evidence_ids),
    response_key = response_key,
    raw_block = NA_character_
  )
}


.qda_fill_product_interpretation <- function(parsed,
                                             product_name,
                                             evidence_ids,
                                             response_key) {
  required_ok <- !is.na(parsed$core_profile) &&
    nzchar(trimws(parsed$core_profile))

  if (!required_ok) {
    return(
      .qda_empty_product_interpretation(
        product_name = product_name,
        status = "parse_failed",
        evidence_ids = evidence_ids,
        response_key = response_key
      )
    )
  }

  list(
    product = product_name,
    status = "available",
    source = "llm_pass1",
    core_profile = parsed$core_profile,
    dominant_configuration =
      parsed$dominant_configuration,
    secondary_configuration =
      parsed$secondary_configuration,
    distinctive_interpretation =
      parsed$distinctive_interpretation,
    descriptive_name = parsed$descriptive_name,
    evidence_ids = as.character(evidence_ids),
    response_key = response_key,
    raw_block = parsed$raw_block
  )
}


.qda_parse_response_interpretations <- function(text,
                                                product_names,
                                                response_key,
                                                single_product_fallback = NULL) {
  blocks <- .qda_extract_interpretation_blocks(text)

  if (length(blocks) == 0L) {
    return(list())
  }

  parsed <- lapply(
    blocks,
    .qda_parse_interpretation_block
  )

  out <- list()

  for (item in parsed) {
    matched <- .qda_match_interpretation_product(
      item$product,
      product_names
    )

    if (is.na(matched) &&
        length(product_names) == 1L &&
        !is.null(single_product_fallback) &&
        identical(product_names[[1L]], single_product_fallback)) {
      matched <- product_names[[1L]]
    }

    if (is.na(matched) || matched %in% names(out)) {
      next
    }

    item$product <- matched
    item$response_key <- response_key
    out[[matched]] <- item
  }

  out
}


.build_product_interpretations_qda <- function(
    responses,
    semantic_facing_evidence,
    product_profiles,
    scope = c("portfolio", "product")) {
  scope <- match.arg(scope)
  .validate_product_profiles_qda(product_profiles)

  product_names <- names(product_profiles$products)

  evidence_ids_for <- function(product_name) {
    item <- semantic_facing_evidence$products[[product_name]]

    if (is.null(item) ||
        is.null(item$selected_evidence_ids)) {
      return(character(0))
    }

    as.character(item$selected_evidence_ids)
  }

  products <- stats::setNames(
    lapply(
      product_names,
      function(product_name) {
        .qda_empty_product_interpretation(
          product_name = product_name,
          status = if (is.null(responses)) {
            "not_generated"
          } else {
            "parse_failed"
          },
          evidence_ids = evidence_ids_for(product_name)
        )
      }
    ),
    product_names
  )

  if (!is.null(responses)) {
    if (identical(scope, "portfolio")) {
      response_key <- if ("portfolio" %in% names(responses)) {
        "portfolio"
      } else {
        names(responses)[[1L]]
      }

      text <- responses[[response_key]]

      parsed <- .qda_parse_response_interpretations(
        text = text,
        product_names = product_names,
        response_key = response_key
      )

      for (product_name in names(parsed)) {
        products[[product_name]] <- .qda_fill_product_interpretation(
          parsed = parsed[[product_name]],
          product_name = product_name,
          evidence_ids = evidence_ids_for(product_name),
          response_key = response_key
        )
      }
    } else {
      for (product_name in product_names) {
        if (!product_name %in% names(responses)) {
          next
        }

        parsed <- .qda_parse_response_interpretations(
          text = responses[[product_name]],
          product_names = product_name,
          response_key = product_name,
          single_product_fallback = product_name
        )

        if (product_name %in% names(parsed)) {
          products[[product_name]] <- .qda_fill_product_interpretation(
            parsed = parsed[[product_name]],
            product_name = product_name,
            evidence_ids = evidence_ids_for(product_name),
            response_key = product_name
          )
        }
      }
    }
  }

  statuses <- vapply(
    products,
    function(x) x$status,
    character(1)
  )

  out <- list(
    products = products,
    settings = list(
      scope = scope,
      source = "llm_pass1"
    ),
    metadata = list(
      schema = "NaileR::qda_product_interpretations",
      schema_version = "1.0.0",
      n_products = as.integer(length(products)),
      n_available = as.integer(sum(statuses == "available")),
      n_parse_failed = as.integer(sum(statuses == "parse_failed")),
      n_not_generated = as.integer(sum(statuses == "not_generated"))
    )
  )

  class(out) <- c(
    "nail_qda_product_interpretations",
    "list"
  )

  out
}
