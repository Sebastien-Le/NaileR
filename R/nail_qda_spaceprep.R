#' @importFrom glue glue
#' @importFrom utils globalVariables
utils::globalVariables(c())

# ---------------------------------------------------------------------------
# Constants
# ---------------------------------------------------------------------------

.qda_spaceprep_scopes <- c(
  "sensory",
  "formulation",
  "marketing",
  "consumer",
  "innovation",
  "cross_functional"
)

.qda_spaceprep_statuses <- c(
  "expert_interpretation",
  "hypothesis",
  "recommendation",
  "user_context"
)

.qda_spaceprep_context_fields <- c(
  "category",
  "products",
  "formulation",
  "brand",
  "market",
  "consumers",
  "usage",
  "constraints"
)

.qda_spaceprep_product_fields <- c(
  "product",
  "proposed_name",
  "sensory_identity",
  "sensory_archetype",
  "differentiation_role",
  "formulation_directions",
  "consumer_preference_hypotheses",
  "usage_hypotheses",
  "communication_territory",
  "validation_needs"
)

# ---------------------------------------------------------------------------
# Small validation and normalization helpers
# ---------------------------------------------------------------------------

.qda_spaceprep_is_nonempty_character_scalar <- function(x) {
  is.character(x) && length(x) == 1L && !is.na(x) && nzchar(trimws(x))
}

.is_qda_spaceprep_context_present <- function(context) {
  if (is.null(context) || length(context) == 0L) {
    return(FALSE)
  }

  any(vapply(context, function(x) {
    if (is.null(x) || length(x) == 0L) {
      return(FALSE)
    }
    if (is.character(x)) {
      return(any(!is.na(x) & nzchar(trimws(x))))
    }
    TRUE
  }, logical(1)))
}

.validate_qda_spaceprep_context <- function(context) {
  if (is.null(context)) {
    return(stats::setNames(vector("list", length(.qda_spaceprep_context_fields)),
                    .qda_spaceprep_context_fields))
  }

  if (!is.list(context)) {
    stop("`context` must be NULL or a named list.", call. = FALSE)
  }

  if (length(context) > 0L && (is.null(names(context)) || any(!nzchar(names(context))))) {
    stop("Every non-empty element of `context` must be named.", call. = FALSE)
  }

  unknown <- setdiff(names(context), .qda_spaceprep_context_fields)
  if (length(unknown) > 0L) {
    stop(
      paste0(
        "Unknown `context` field(s): ", paste(unknown, collapse = ", "),
        ". Allowed fields are: ",
        paste(.qda_spaceprep_context_fields, collapse = ", "), "."
      ),
      call. = FALSE
    )
  }

  out <- stats::setNames(vector("list", length(.qda_spaceprep_context_fields)),
                  .qda_spaceprep_context_fields)
  out[names(context)] <- context
  out
}

.validate_qda_spaceprep_product_profiles <- function(product_profiles) {
  if (!is.list(product_profiles) || length(product_profiles) == 0L) {
    stop(
      "`x` must contain a non-empty `product_profiles` attribute created by `nail_qda()`.",
      call. = FALSE
    )
  }

  if (is.null(names(product_profiles)) || any(!nzchar(names(product_profiles))) ||
      anyDuplicated(names(product_profiles)) > 0L) {
    stop(
      "The `product_profiles` attribute must be a uniquely named list with one element per product.",
      call. = FALSE
    )
  }

  required_profile_fields <- c(
    "product",
    "adjusted_means",
    "retained_markers",
    "above_average",
    "below_average",
    "metrics"
  )
  required_marker_fields <- c(
    "evidence_id",
    "product",
    "attribute",
    "direction",
    "coefficient",
    "adjusted_mean",
    "v_test",
    "p_value",
    "abs_v_test",
    "rank"
  )

  for (nm in names(product_profiles)) {
    profile <- product_profiles[[nm]]

    if (!is.list(profile) || !all(required_profile_fields %in% names(profile))) {
      stop(
        sprintf(
          "Product profile `%s` is invalid. It must contain: %s.",
          nm,
          paste(required_profile_fields, collapse = ", ")
        ),
        call. = FALSE
      )
    }

    if (!.qda_spaceprep_is_nonempty_character_scalar(as.character(profile$product)) ||
        !identical(as.character(profile$product), nm)) {
      stop(
        sprintf(
          "Product profile `%s` must contain `product = \"%s\"`.",
          nm, nm
        ),
        call. = FALSE
      )
    }

    adjusted_means <- profile$adjusted_means
    if (!is.numeric(adjusted_means) || length(adjusted_means) == 0L ||
        is.null(names(adjusted_means)) || any(!nzchar(names(adjusted_means))) ||
        anyDuplicated(names(adjusted_means)) > 0L) {
      stop(
        sprintf(
          "`adjusted_means` for product `%s` must be a non-empty uniquely named numeric vector.",
          nm
        ),
        call. = FALSE
      )
    }

    if (!is.data.frame(profile$above_average) || !is.data.frame(profile$below_average)) {
      stop(
        sprintf(
          "`above_average` and `below_average` for product `%s` must be data frames.",
          nm
        ),
        call. = FALSE
      )
    }

    if (!is.list(profile$metrics)) {
      stop(sprintf("`metrics` for product `%s` must be a list.", nm), call. = FALSE)
    }

    markers <- profile$retained_markers
    if (!is.data.frame(markers) || !all(required_marker_fields %in% names(markers))) {
      stop(
        sprintf(
          "`retained_markers` for product `%s` is invalid. It must contain: %s.",
          nm,
          paste(required_marker_fields, collapse = ", ")
        ),
        call. = FALSE
      )
    }

    if (nrow(markers) > 0L) {
      if (anyNA(markers$product) || any(as.character(markers$product) != nm) ||
          anyNA(markers$attribute) || any(!nzchar(trimws(as.character(markers$attribute)))) ||
          anyNA(markers$direction) ||
          any(!as.character(markers$direction) %in% c("higher than overall", "lower than overall"))) {
        stop(
          sprintf(
            "`retained_markers` for product `%s` contains invalid product, attribute, or direction values.",
            nm
          ),
          call. = FALSE
        )
      }

      expected_ids <- paste(markers$product, markers$attribute, sep = "::")
      if (anyNA(markers$evidence_id) || any(!nzchar(markers$evidence_id)) ||
          !identical(as.character(markers$evidence_id), as.character(expected_ids)) ||
          anyDuplicated(markers$evidence_id) > 0L) {
        stop(
          sprintf(
            "`retained_markers` for product `%s` contains invalid or duplicated `evidence_id` values.",
            nm
          ),
          call. = FALSE
        )
      }
    }
  }

  all_ids <- unlist(lapply(product_profiles, function(x) {
    as.character(x$retained_markers$evidence_id)
  }), use.names = FALSE)

  if (anyDuplicated(all_ids) > 0L) {
    stop("`evidence_id` values must be unique across all product profiles.", call. = FALSE)
  }

  invisible(TRUE)
}

.extract_qda_spaceprep_source <- function(x = NULL,
                                          dataset = NULL,
                                          formul = NULL,
                                          firstvar = NULL,
                                          lastvar = NULL,
                                          proba = 0.05,
                                          model = "llama3",
                                          provider = "ollama",
                                          product_knowledge = "unknown") {
  legacy_used <- is.null(x)

  if (!legacy_used) {
    if (!is.null(dataset) || !is.null(formul) || !is.null(firstvar) || !is.null(lastvar)) {
      warning(
        "`x` was supplied; deprecated data-based arguments are ignored.",
        call. = FALSE
      )
    }

    product_profiles <- attr(x, "product_profiles", exact = TRUE)
    .validate_qda_spaceprep_product_profiles(product_profiles)

    return(list(
      x = x,
      product_profiles = product_profiles,
      decat_result = attr(x, "decat_result", exact = TRUE),
      qda_settings = attr(x, "qda_settings", exact = TRUE),
      legacy_interface = FALSE
    ))
  }

  if (is.null(dataset) || is.null(formul) || is.null(firstvar)) {
    stop(
      paste(
        "Supply `x`, an object returned by `nail_qda()` containing",
        "a valid `product_profiles` attribute. The legacy",
        "`dataset`/`formul`/`firstvar` interface is deprecated."
      ),
      call. = FALSE
    )
  }

  warning(
    paste(
      "The `dataset`/`formul`/`firstvar` interface of",
      "`nail_qda_spaceprep()` is deprecated.",
      "Call `nail_qda()` first and pass its result through `x`."
    ),
    call. = FALSE
  )

  if (is.null(lastvar)) {
    lastvar <- ncol(dataset)
  }

  qda_result <- nail_qda(
    dataset = dataset,
    formul = formul,
    firstvar = firstvar,
    lastvar = lastvar,
    model = model,
    provider = provider,
    proba = proba,
    product_knowledge = product_knowledge,
    generate = FALSE
  )

  product_profiles <- attr(qda_result, "product_profiles", exact = TRUE)
  .validate_qda_spaceprep_product_profiles(product_profiles)

  list(
    x = qda_result,
    product_profiles = product_profiles,
    decat_result = attr(qda_result, "decat_result", exact = TRUE),
    qda_settings = attr(qda_result, "qda_settings", exact = TRUE),
    legacy_interface = TRUE
  )
}

# ---------------------------------------------------------------------------
# Evidence builders
# ---------------------------------------------------------------------------

.format_qda_spaceprep_number <- function(x, digits = 6L) {
  x <- suppressWarnings(as.numeric(x))
  if (length(x) == 0L || is.na(x) || !is.finite(x)) {
    return(NULL)
  }
  as.numeric(formatC(x, digits = digits, format = "fg", flag = "#"))
}

.select_qda_spaceprep_markers <- function(markers,
                                          sample.pct = 1,
                                          drop.negative = FALSE) {
  if (!is.data.frame(markers) || nrow(markers) == 0L) {
    return(markers[0, , drop = FALSE])
  }

  out <- markers
  if (isTRUE(drop.negative)) {
    out <- out[out$direction == "higher than overall", , drop = FALSE]
  }

  if (nrow(out) == 0L || sample.pct >= 1) {
    return(out)
  }

  target_n <- max(1L, as.integer(ceiling(nrow(out) * sample.pct)))
  target_n <- min(target_n, nrow(out))

  if ("rank" %in% names(out)) {
    out <- out[order(out$rank, out$evidence_id), , drop = FALSE]
  }

  out[seq_len(target_n), , drop = FALSE]
}

.qda_spaceprep_marker_records <- function(markers) {
  if (!is.data.frame(markers) || nrow(markers) == 0L) {
    return(list())
  }

  lapply(seq_len(nrow(markers)), function(i) {
    list(
      evidence_id = as.character(markers$evidence_id[[i]]),
      attribute = as.character(markers$attribute[[i]]),
      direction = as.character(markers$direction[[i]]),
      coefficient = .format_qda_spaceprep_number(markers$coefficient[[i]]),
      adjusted_mean = .format_qda_spaceprep_number(markers$adjusted_mean[[i]]),
      v_test = .format_qda_spaceprep_number(markers$v_test[[i]]),
      p_value = .format_qda_spaceprep_number(markers$p_value[[i]]),
      rank = as.integer(markers$rank[[i]])
    )
  })
}

.qda_spaceprep_adjusted_mean_records <- function(adjusted_means) {
  nm <- names(adjusted_means)
  values <- as.numeric(adjusted_means)
  if (is.null(nm)) {
    nm <- paste0("attribute_", seq_along(values))
  }

  stats::setNames(
    lapply(values, .format_qda_spaceprep_number),
    nm
  )
}

.build_qda_spaceprep_evidence <- function(product_profiles,
                                          products = names(product_profiles),
                                          sample.pct = 1,
                                          drop.negative = FALSE) {
  products <- intersect(as.character(products), names(product_profiles))

  evidence_products <- lapply(products, function(product) {
    profile <- product_profiles[[product]]
    markers <- .select_qda_spaceprep_markers(
      profile$retained_markers,
      sample.pct = sample.pct,
      drop.negative = drop.negative
    )

    list(
      product = product,
      adjusted_means = .qda_spaceprep_adjusted_mean_records(profile$adjusted_means),
      retained_markers = .qda_spaceprep_marker_records(markers),
      metrics = profile$metrics
    )
  })
  names(evidence_products) <- products

  evidence_ids <- unlist(lapply(evidence_products, function(x) {
    vapply(x$retained_markers, function(marker) marker$evidence_id, character(1))
  }), use.names = FALSE)

  list(
    products = evidence_products,
    evidence_ids = unique(evidence_ids),
    settings = list(
      sample_pct = sample.pct,
      drop_negative = drop.negative,
      source = "attr(x, 'product_profiles')"
    )
  )
}

# ---------------------------------------------------------------------------
# Prompt builders
# ---------------------------------------------------------------------------

.qda_spaceprep_scope_mission <- function(expertise_scope) {
  switch(
    expertise_scope,
    sensory = paste(
      "SENSORY PERSPECTIVE",
      "Describe each product's relative sensory identity and sensory archetype.",
      "Compare products, identify coherent sensory families, and explain",
      "how products differ without introducing marketing, consumer, formulation,",
      "quality, liking, ingredient, or process claims.",
      sep = "\n"
    ),
    formulation = paste(
      "FORMULATION PERSPECTIVE",
      "Translate the sensory evidence into sensory reformulation directions.",
      "State the sensory changes that could move or differentiate a product,",
      "but do not invent ingredients, recipes, process mechanisms, or technical",
      "causes that are absent from the user-provided context.",
      sep = "\n"
    ),
    marketing = paste(
      "MARKETING PERSPECTIVE",
      "Propose evidence-grounded descriptive product names, sensory identities,",
      "communication territories, and differentiation roles.",
      "Do not infer liking, quality, price, market performance, demographics,",
      "or commercial success from sensory evidence alone.",
      sep = "\n"
    ),
    consumer = paste(
      "CONSUMER-RESEARCH PERSPECTIVE",
      "Formulate only sensory-preference compatibility hypotheses and the",
      "consumer studies needed to test them. Without explicit consumer context,",
      "do not invent demographic segments, observed behavior, liking, acceptance,",
      "purchase intent, or consumption frequency.",
      sep = "\n"
    ),
    innovation = paste(
      "INNOVATION PERSPECTIVE",
      "Identify product families, differentiation issues, underexplored sensory",
      "directions suggested by the set, and validation priorities.",
      "Do not call a sensory direction a market opportunity unless market or",
      "consumer evidence is explicitly supplied in the user context.",
      sep = "\n"
    ),
    cross_functional = paste(
      "CROSS-FUNCTIONAL PERSPECTIVE",
      "Integrate sensory, formulation, marketing, consumer-research, and",
      "innovation perspectives. Keep sensory evidence primary. Separate",
      "evidence-grounded interpretations from hypotheses and recommendations,",
      "and state the additional validation needed before business decisions.",
      sep = "\n"
    )
  )
}

.qda_spaceprep_empty_claim <- function() NULL

.qda_spaceprep_empty_product <- function(product) {
  list(
    product = product,
    proposed_name = .qda_spaceprep_empty_claim(),
    sensory_identity = .qda_spaceprep_empty_claim(),
    sensory_archetype = .qda_spaceprep_empty_claim(),
    differentiation_role = .qda_spaceprep_empty_claim(),
    formulation_directions = list(),
    consumer_preference_hypotheses = list(),
    usage_hypotheses = list(),
    communication_territory = .qda_spaceprep_empty_claim(),
    validation_needs = character(0)
  )
}

.qda_spaceprep_empty_portfolio <- function() {
  list(
    overall_reading = NULL,
    product_families = list(),
    differentiation_issues = list(),
    cross_functional_priorities = list()
  )
}

.build_qda_spaceprep_schema <- function(products) {
  products <- as.character(products)
  product_template <- lapply(products, .qda_spaceprep_empty_product)
  names(product_template) <- products

  skeleton <- list(
    portfolio = .qda_spaceprep_empty_portfolio(),
    products = product_template
  )

  paste(
    "Return one JSON object only. Do not use Markdown fences or explanatory text.",
    "",
    "Every non-null claim must use exactly this object shape:",
    '{"text":"...","status":"expert_interpretation|hypothesis|recommendation|user_context","evidence_ids":["Product::Attribute"],"validation_needed":null}',
    "",
    "Each `product_families` item must use this object shape:",
    '{"label":"...","products":["Product"],"text":"...","status":"expert_interpretation|hypothesis|recommendation|user_context","evidence_ids":["Product::Attribute"],"validation_needed":null}',
    "",
    "For every hypothesis or recommendation, `validation_needed` must be a non-empty string.",
    "Every `formulation_directions` item must use status `recommendation`.",
    "Every `consumer_preference_hypotheses` and `usage_hypotheses` item must use status `hypothesis`.",
    "Each product family must cite at least one evidence ID for every product listed in that family.",
    "For `user_context`, use an empty `evidence_ids` array and only restate information explicitly supplied in USER-PROVIDED PRODUCT CONTEXT.",
    "Use null for a non-applicable singular claim and [] for a non-applicable list.",
    "Do not add fields and do not omit product entries.",
    "",
    jsonlite::toJSON(
      skeleton,
      auto_unbox = TRUE,
      pretty = TRUE,
      null = "null",
      na = "null"
    ),
    sep = "\n"
  )
}

.build_qda_spaceprep_prompt <- function(evidence,
                                        request = NULL,
                                        context = NULL,
                                        expertise_scope = "sensory",
                                        comparison_mode = "joint",
                                        product_knowledge = "unknown") {
  products <- names(evidence$products)
  unit_word <- .unit_word_qda(product_knowledge, capital = FALSE, plural = FALSE)
  unit_plural <- .unit_word_qda(product_knowledge, capital = FALSE, plural = TRUE)

  mode_instruction <- if (comparison_mode == "joint") {
    paste(
      "Analyze all products together in one coherent portfolio reading.",
      "Use the full set to propose genuinely distinctive names and identities,",
      "identify product families, and detect possible differentiation issues."
    )
  } else {
    paste(
      "Analyze this product independently.",
      "Do not claim portfolio-level families or differentiation issues because",
      "the other products are not included in this generation unit."
    )
  }

  context_block <- if (.is_qda_spaceprep_context_present(context)) {
    jsonlite::toJSON(
      context,
      auto_unbox = TRUE,
      pretty = TRUE,
      null = "null",
      na = "null"
    )
  } else {
    "No user-provided product context was supplied."
  }

  custom_request <- if (.qda_spaceprep_is_nonempty_character_scalar(request)) {
    request
  } else {
    "No additional user request was supplied."
  }

  evidence_json <- jsonlite::toJSON(
    evidence$products,
    auto_unbox = TRUE,
    pretty = TRUE,
    null = "null",
    na = "null"
  )

  paste(
    "ROLE",
    paste0(
      "You are a senior sensory scientist working transversally with sensory, ",
      "formulation, marketing, innovation, and consumer-research teams."
    ),
    paste0(
      "Your task is to create traceable product expertise from statistical ",
      "sensory profiles, not to recalculate or transcribe the analysis."
    ),
    "",
    "SENSORY EVIDENCE",
    paste0(
      "The JSON below comes exclusively from `attr(x, \"product_profiles\")`. ",
      "Adjusted means describe the complete profile and are provided as descriptive context. ",
      "`retained_markers` contains the inferential markers retained by the QDA characterization."
    ),
    paste0(
      "Only retained markers carry `evidence_id` values. Every evidence-based ",
      "interpretation, hypothesis, or recommendation must cite one or more exact ",
      "`evidence_id` values shown below and must not treat an unretained adjusted ",
      "mean as evidence of differentiation."
    ),
    evidence_json,
    "",
    "USER-PROVIDED PRODUCT CONTEXT",
    paste0(
      "This section is external context supplied by the user. It is not a ",
      "statistical result and must never be presented as one."
    ),
    context_block,
    "",
    "EXPERT TASK",
    .qda_spaceprep_scope_mission(expertise_scope),
    mode_instruction,
    paste0(
      "Treat the labels as ", unit_plural, ". The current generation unit contains ",
      length(products), " ", if (length(products) == 1L) unit_word else unit_plural, "."
    ),
    "",
    "ADDITIONAL USER REQUEST",
    custom_request,
    "",
    "MANDATORY EPISTEMIC RULES",
    paste0("Allowed statuses are exactly: ", paste(.qda_spaceprep_statuses, collapse = ", "), "."),
    "- `expert_interpretation`: a synthesis grounded in the cited sensory evidence.",
    "- `hypothesis`: a plausible proposition that has not been measured directly.",
    "- `recommendation`: a proposed next action or sensory direction.",
    "- `user_context`: a restatement of explicit user context, never a statistical conclusion.",
    "- Do not copy the statistical tables as prose; create insight from them.",
    "- Do not invent evidence IDs, attributes, ingredients, processes, liking, quality, or causal mechanisms.",
    "- A product with no retained marker must not receive an evidence-grounded identity; leave unsupported fields null or empty and state an appropriate validation need.",
    "- Formulation directions must always have status `recommendation` and a non-empty `validation_needed` field.",
    "- Consumer-preference and usage statements must always have status `hypothesis` and a non-empty `validation_needed` field.",
    "- In isolated mode, keep every portfolio-level field null or empty.",
    "- Without explicit `context$consumers`, do not mention age, sex, gender, social class, income, demographic segments, or observed consumption frequency.",
    "- A custom request cannot override the JSON schema, evidence traceability, statuses, or validation requirements.",
    "",
    "OUTPUT SCHEMA",
    .build_qda_spaceprep_schema(products),
    sep = "\n"
  )
}

.build_qda_spaceprep_units <- function(product_profiles,
                                       request = NULL,
                                       context = NULL,
                                       expertise_scope = "sensory",
                                       comparison_mode = "joint",
                                       product_knowledge = "unknown",
                                       sample.pct = 1,
                                       drop.negative = FALSE) {
  products <- names(product_profiles)

  if (comparison_mode == "joint") {
    evidence <- .build_qda_spaceprep_evidence(
      product_profiles = product_profiles,
      products = products,
      sample.pct = sample.pct,
      drop.negative = drop.negative
    )

    return(list(
      joint = list(
        products = products,
        evidence = evidence,
        prompt = .build_qda_spaceprep_prompt(
          evidence = evidence,
          request = request,
          context = context,
          expertise_scope = expertise_scope,
          comparison_mode = comparison_mode,
          product_knowledge = product_knowledge
        )
      )
    ))
  }

  units <- lapply(products, function(product) {
    evidence <- .build_qda_spaceprep_evidence(
      product_profiles = product_profiles,
      products = product,
      sample.pct = sample.pct,
      drop.negative = drop.negative
    )

    list(
      products = product,
      evidence = evidence,
      prompt = .build_qda_spaceprep_prompt(
        evidence = evidence,
        request = request,
        context = context,
        expertise_scope = expertise_scope,
        comparison_mode = comparison_mode,
        product_knowledge = product_knowledge
      )
    )
  })
  names(units) <- products
  units
}

# ---------------------------------------------------------------------------
# JSON parsing and epistemic validation
# ---------------------------------------------------------------------------

.qda_spaceprep_as_character_vector <- function(x, field) {
  if (is.null(x)) {
    return(character(0))
  }

  if (is.list(x) && !is.data.frame(x)) {
    x <- unlist(x, recursive = TRUE, use.names = FALSE)
  }

  if (is.null(x) || length(x) == 0L) {
    return(character(0))
  }

  if (!is.atomic(x)) {
    stop(sprintf("`%s` must be a character array.", field), call. = FALSE)
  }

  x <- as.character(x)
  x <- x[!is.na(x) & nzchar(trimws(x))]
  unname(x)
}

.qda_spaceprep_validate_claim <- function(claim,
                                          field,
                                          valid_evidence_ids,
                                          context_present) {
  if (is.null(claim)) {
    return(NULL)
  }

  if (!is.list(claim) || is.data.frame(claim)) {
    stop(sprintf("`%s` must be null or a claim object.", field), call. = FALSE)
  }

  required <- c("text", "status", "evidence_ids", "validation_needed")
  missing_fields <- setdiff(required, names(claim))
  if (length(missing_fields) > 0L) {
    stop(
      sprintf(
        "`%s` is missing required field(s): %s.",
        field,
        paste(missing_fields, collapse = ", ")
      ),
      call. = FALSE
    )
  }

  unknown_fields <- setdiff(names(claim), required)
  if (length(unknown_fields) > 0L) {
    stop(
      sprintf(
        "`%s` contains unexpected field(s): %s.",
        field,
        paste(unknown_fields, collapse = ", ")
      ),
      call. = FALSE
    )
  }

  if (!.qda_spaceprep_is_nonempty_character_scalar(claim$text)) {
    stop(sprintf("`%s$text` must be a non-empty string.", field), call. = FALSE)
  }

  status <- as.character(claim$status)
  if (length(status) != 1L || is.na(status) || !status %in% .qda_spaceprep_statuses) {
    stop(
      sprintf(
        "`%s$status` must be one of: %s.",
        field,
        paste(.qda_spaceprep_statuses, collapse = ", ")
      ),
      call. = FALSE
    )
  }

  evidence_ids <- .qda_spaceprep_as_character_vector(
    claim$evidence_ids,
    paste0(field, "$evidence_ids")
  )

  if (status == "user_context") {
    if (!context_present) {
      stop(
        sprintf("`%s` uses status `user_context`, but no user context was supplied.", field),
        call. = FALSE
      )
    }
    if (length(evidence_ids) > 0L) {
      stop(
        sprintf("`%s` with status `user_context` must use an empty `evidence_ids` array.", field),
        call. = FALSE
      )
    }
  } else {
    if (length(evidence_ids) == 0L) {
      stop(
        sprintf("`%s` must cite at least one sensory `evidence_id`.", field),
        call. = FALSE
      )
    }

    invalid_ids <- setdiff(evidence_ids, valid_evidence_ids)
    if (length(invalid_ids) > 0L) {
      stop(
        sprintf(
          "`%s` cites unknown evidence ID(s): %s.",
          field,
          paste(invalid_ids, collapse = ", ")
        ),
        call. = FALSE
      )
    }
  }

  validation_needed <- claim$validation_needed
  if (is.null(validation_needed) ||
      (is.character(validation_needed) && length(validation_needed) == 1L &&
       (is.na(validation_needed) || !nzchar(trimws(validation_needed))))) {
    validation_needed <- NULL
  } else if (!.qda_spaceprep_is_nonempty_character_scalar(validation_needed)) {
    stop(
      sprintf("`%s$validation_needed` must be null or a non-empty string.", field),
      call. = FALSE
    )
  } else {
    validation_needed <- trimws(validation_needed)
  }

  if (status %in% c("hypothesis", "recommendation") && is.null(validation_needed)) {
    stop(
      sprintf(
        "`%s` has status `%s` and therefore requires a non-empty `validation_needed` field.",
        field, status
      ),
      call. = FALSE
    )
  }

  list(
    text = trimws(claim$text),
    status = status,
    evidence_ids = unique(evidence_ids),
    validation_needed = validation_needed
  )
}

.qda_spaceprep_validate_claim_list <- function(x,
                                               field,
                                               valid_evidence_ids,
                                               context_present,
                                               required_status = NULL) {
  if (is.null(x) || length(x) == 0L) {
    return(list())
  }

  if (!is.list(x) || is.data.frame(x)) {
    stop(sprintf("`%s` must be a JSON array of claim objects.", field), call. = FALSE)
  }

  out <- lapply(seq_along(x), function(i) {
    claim_field <- sprintf("%s[[%d]]", field, i)
    raw_claim <- x[[i]]

    # Enforce field-specific epistemic status before the generic claim
    # validation. This yields the most informative error when a formulation
    # direction or consumer hypothesis uses the wrong status, even if another
    # required field is also missing.
    if (!is.null(required_status) &&
        is.list(raw_claim) &&
        !is.data.frame(raw_claim) &&
        "status" %in% names(raw_claim) &&
        .qda_spaceprep_is_nonempty_character_scalar(raw_claim$status) &&
        !identical(as.character(raw_claim$status), required_status)) {
      stop(
        sprintf(
          "`%s` must use status `%s`.",
          claim_field, required_status
        ),
        call. = FALSE
      )
    }

    claim <- .qda_spaceprep_validate_claim(
      raw_claim,
      field = claim_field,
      valid_evidence_ids = valid_evidence_ids,
      context_present = context_present
    )

    if (!is.null(required_status) && !identical(claim$status, required_status)) {
      stop(
        sprintf(
          "`%s` must use status `%s`.",
          claim_field, required_status
        ),
        call. = FALSE
      )
    }

    claim
  })

  unname(out)
}

.qda_spaceprep_validate_family <- function(family,
                                           index,
                                           expected_products,
                                           valid_evidence_ids,
                                           context_present) {
  field <- sprintf("portfolio$product_families[[%d]]", index)
  if (!is.list(family) || is.data.frame(family)) {
    stop(sprintf("`%s` must be an object.", field), call. = FALSE)
  }

  required <- c("label", "products", "text", "status", "evidence_ids", "validation_needed")
  missing_fields <- setdiff(required, names(family))
  if (length(missing_fields) > 0L) {
    stop(
      sprintf("`%s` is missing: %s.", field, paste(missing_fields, collapse = ", ")),
      call. = FALSE
    )
  }

  unknown_fields <- setdiff(names(family), required)
  if (length(unknown_fields) > 0L) {
    stop(
      sprintf(
        "`%s` contains unexpected field(s): %s.",
        field,
        paste(unknown_fields, collapse = ", ")
      ),
      call. = FALSE
    )
  }

  if (!.qda_spaceprep_is_nonempty_character_scalar(family$label)) {
    stop(sprintf("`%s$label` must be a non-empty string.", field), call. = FALSE)
  }

  products <- .qda_spaceprep_as_character_vector(family$products, paste0(field, "$products"))
  if (length(products) == 0L || length(setdiff(products, expected_products)) > 0L) {
    stop(
      sprintf("`%s$products` must contain only products included in this generation unit.", field),
      call. = FALSE
    )
  }

  claim <- .qda_spaceprep_validate_claim(
    family[c("text", "status", "evidence_ids", "validation_needed")],
    field = field,
    valid_evidence_ids = valid_evidence_ids,
    context_present = context_present
  )

  products <- unique(products)
  if (!identical(claim$status, "user_context")) {
    evidence_products <- sub("::.*$", "", claim$evidence_ids)
    unsupported_products <- setdiff(products, evidence_products)
    if (length(unsupported_products) > 0L) {
      stop(
        sprintf(
          "`%s` must cite at least one evidence ID for every listed product. Missing: %s.",
          field,
          paste(unsupported_products, collapse = ", ")
        ),
        call. = FALSE
      )
    }
  }

  c(
    list(label = trimws(family$label), products = products),
    claim
  )
}

.qda_spaceprep_validate_product_claim_ownership <- function(claim,
                                                        product_name,
                                                        field) {
  if (is.null(claim) || identical(claim$status, "user_context")) {
    return(invisible(TRUE))
  }

  prefix <- paste0(product_name, "::")
  if (!any(startsWith(claim$evidence_ids, prefix))) {
    stop(
      sprintf(
        "`%s` must cite at least one evidence ID belonging to product `%s`.",
        field, product_name
      ),
      call. = FALSE
    )
  }

  invisible(TRUE)
}

.qda_spaceprep_contains_demographic_claim <- function(text) {
  if (length(text) == 0L || is.na(text) || !nzchar(text)) {
    return(FALSE)
  }

  patterns <- c(
    "\\b(men|women|male|female|boys|girls|gender|sex)\\b",
    "\\b(hommes?|femmes?|masculin|f\u00e9minin|genre|sexe)\\b",
    "\\b(age|aged|years? old|ans)\\b",
    "\\b(young adults?|teenagers?|adolescents?|older adults?|seniors?|millennials?|gen[ -]?z)\\b",
    "\\b(jeunes? adultes?|adolescents?|personnes? \u00e2g\u00e9es?|seniors?)\\b",
    "\\b[1-9][0-9]?\\s*[-\u2013]\\s*[1-9][0-9]?\\b",
    "\\b(social class|socioeconomic|income|low-income|high-income)\\b",
    "\\b(classe sociale|cat\u00e9gorie sociale|csp|revenu)\\b",
    "\\b(daily|weekly|monthly|frequent|occasional) consumers?\\b",
    "\\bconsum(?:e|es|ing|ption)[^.!?]{0,30}(daily|weekly|monthly|frequently|occasionally)\\b",
    "\\bconsommateurs? (quotidiens?|hebdomadaires?|fr\u00e9quents?|occasionnels?)\\b",
    "\\bconsomm(?:e|ent|ation)[^.!?]{0,30}(quotidiennement|chaque semaine|mensuellement|fr\u00e9quemment|occasionnellement)\\b"
  )

  any(vapply(patterns, grepl, logical(1), x = text, ignore.case = TRUE, perl = TRUE))
}

.qda_spaceprep_collect_claim_texts <- function(product_expertise) {
  texts <- character(0)

  add_claim <- function(x) {
    if (is.list(x) && .qda_spaceprep_is_nonempty_character_scalar(x$text)) {
      texts <<- c(texts, x$text)
    }
  }

  add_claim(product_expertise$portfolio$overall_reading)
  lapply(product_expertise$portfolio$product_families, add_claim)
  lapply(product_expertise$portfolio$differentiation_issues, add_claim)
  lapply(product_expertise$portfolio$cross_functional_priorities, add_claim)

  for (product in product_expertise$products) {
    add_claim(product$proposed_name)
    add_claim(product$sensory_identity)
    add_claim(product$sensory_archetype)
    add_claim(product$differentiation_role)
    lapply(product$formulation_directions, add_claim)
    lapply(product$consumer_preference_hypotheses, add_claim)
    lapply(product$usage_hypotheses, add_claim)
    add_claim(product$communication_territory)
  }

  texts
}

.validate_qda_spaceprep_parsed <- function(parsed,
                                           expected_products,
                                           valid_evidence_ids,
                                           context,
                                           expertise_scope,
                                           comparison_mode,
                                           metadata) {
  if (!is.list(parsed) || is.data.frame(parsed)) {
    stop("The JSON root must be an object.", call. = FALSE)
  }

  unknown_top <- setdiff(names(parsed), c("portfolio", "products"))
  if (length(unknown_top) > 0L) {
    stop(
      sprintf("Unexpected top-level JSON field(s): %s.", paste(unknown_top, collapse = ", ")),
      call. = FALSE
    )
  }

  if (is.null(parsed$portfolio) || !is.list(parsed$portfolio) || is.data.frame(parsed$portfolio)) {
    stop("The JSON output must contain a `portfolio` object.", call. = FALSE)
  }
  if (is.null(parsed$products) || !is.list(parsed$products) || is.data.frame(parsed$products)) {
    stop("The JSON output must contain a named `products` object.", call. = FALSE)
  }

  expected_portfolio_fields <- c(
    "overall_reading",
    "product_families",
    "differentiation_issues",
    "cross_functional_priorities"
  )
  unknown_portfolio <- setdiff(names(parsed$portfolio), expected_portfolio_fields)
  if (length(unknown_portfolio) > 0L) {
    stop(
      sprintf("Unexpected `portfolio` field(s): %s.", paste(unknown_portfolio, collapse = ", ")),
      call. = FALSE
    )
  }

  product_names <- names(parsed$products)
  if (is.null(product_names) || any(!nzchar(product_names))) {
    stop("The JSON `products` object must be named by product identifiers.", call. = FALSE)
  }

  missing_products <- setdiff(expected_products, product_names)
  extra_products <- setdiff(product_names, expected_products)
  if (length(missing_products) > 0L || length(extra_products) > 0L) {
    stop(
      paste0(
        "The JSON `products` object must contain exactly: ",
        paste(expected_products, collapse = ", "), "."
      ),
      call. = FALSE
    )
  }

  context_present <- .is_qda_spaceprep_context_present(context)
  consumer_context_present <- .is_qda_spaceprep_context_present(list(consumers = context$consumers))

  portfolio <- .qda_spaceprep_empty_portfolio()
  portfolio$overall_reading <- .qda_spaceprep_validate_claim(
    parsed$portfolio$overall_reading,
    field = "portfolio$overall_reading",
    valid_evidence_ids = valid_evidence_ids,
    context_present = context_present
  )

  families <- parsed$portfolio$product_families
  if (is.null(families)) families <- list()
  if (!is.list(families) || is.data.frame(families)) {
    stop("`portfolio$product_families` must be a JSON array.", call. = FALSE)
  }
  portfolio$product_families <- lapply(seq_along(families), function(i) {
    .qda_spaceprep_validate_family(
      families[[i]],
      index = i,
      expected_products = expected_products,
      valid_evidence_ids = valid_evidence_ids,
      context_present = context_present
    )
  })

  portfolio$differentiation_issues <- .qda_spaceprep_validate_claim_list(
    parsed$portfolio$differentiation_issues,
    field = "portfolio$differentiation_issues",
    valid_evidence_ids = valid_evidence_ids,
    context_present = context_present
  )

  portfolio$cross_functional_priorities <- .qda_spaceprep_validate_claim_list(
    parsed$portfolio$cross_functional_priorities,
    field = "portfolio$cross_functional_priorities",
    valid_evidence_ids = valid_evidence_ids,
    context_present = context_present
  )

  if (identical(comparison_mode, "isolated")) {
    has_portfolio_content <- !is.null(portfolio$overall_reading) ||
      length(portfolio$product_families) > 0L ||
      length(portfolio$differentiation_issues) > 0L ||
      length(portfolio$cross_functional_priorities) > 0L

    if (has_portfolio_content) {
      stop(
        paste(
          "Portfolio-level claims are not allowed when",
          "`comparison_mode = \"isolated\"`; use null or empty arrays."
        ),
        call. = FALSE
      )
    }
  }

  products <- lapply(expected_products, function(product_name) {
    item <- parsed$products[[product_name]]
    field <- paste0("products$", product_name)

    if (!is.list(item) || is.data.frame(item)) {
      stop(sprintf("`%s` must be an object.", field), call. = FALSE)
    }

    unknown_fields <- setdiff(names(item), .qda_spaceprep_product_fields)
    if (length(unknown_fields) > 0L) {
      stop(
        sprintf("Unexpected field(s) in `%s`: %s.", field, paste(unknown_fields, collapse = ", ")),
        call. = FALSE
      )
    }

    if (!.qda_spaceprep_is_nonempty_character_scalar(item$product) || !identical(item$product, product_name)) {
      stop(
        sprintf("`%s$product` must be exactly `%s`.", field, product_name),
        call. = FALSE
      )
    }

    out <- .qda_spaceprep_empty_product(product_name)

    for (claim_field in c(
      "proposed_name",
      "sensory_identity",
      "sensory_archetype",
      "differentiation_role",
      "communication_territory"
    )) {
      claim_path <- paste0(field, "$", claim_field)
      out[[claim_field]] <- .qda_spaceprep_validate_claim(
        item[[claim_field]],
        field = claim_path,
        valid_evidence_ids = valid_evidence_ids,
        context_present = context_present
      )
      .qda_spaceprep_validate_product_claim_ownership(
        out[[claim_field]],
        product_name = product_name,
        field = claim_path
      )
    }

    out$formulation_directions <- .qda_spaceprep_validate_claim_list(
      item$formulation_directions,
      field = paste0(field, "$formulation_directions"),
      valid_evidence_ids = valid_evidence_ids,
      context_present = context_present,
      required_status = "recommendation"
    )

    out$consumer_preference_hypotheses <- .qda_spaceprep_validate_claim_list(
      item$consumer_preference_hypotheses,
      field = paste0(field, "$consumer_preference_hypotheses"),
      valid_evidence_ids = valid_evidence_ids,
      context_present = context_present,
      required_status = "hypothesis"
    )

    out$usage_hypotheses <- .qda_spaceprep_validate_claim_list(
      item$usage_hypotheses,
      field = paste0(field, "$usage_hypotheses"),
      valid_evidence_ids = valid_evidence_ids,
      context_present = context_present,
      required_status = "hypothesis"
    )

    for (claim_field in c(
      "formulation_directions",
      "consumer_preference_hypotheses",
      "usage_hypotheses"
    )) {
      claims <- out[[claim_field]]
      for (i in seq_along(claims)) {
        .qda_spaceprep_validate_product_claim_ownership(
          claims[[i]],
          product_name = product_name,
          field = sprintf("%s$%s[[%d]]", field, claim_field, i)
        )
      }
    }

    out$validation_needs <- .qda_spaceprep_as_character_vector(
      item$validation_needs,
      paste0(field, "$validation_needs")
    )

    out
  })
  names(products) <- expected_products

  expertise_metadata <- metadata
  expertise_metadata$expertise_scope <- expertise_scope
  expertise_metadata$comparison_mode <- comparison_mode
  expertise_metadata$parse_status <- "success"

  product_expertise <- list(
    portfolio = portfolio,
    products = products,
    metadata = expertise_metadata
  )

  if (!consumer_context_present) {
    all_text <- .qda_spaceprep_collect_claim_texts(product_expertise)
    demographic_text <- all_text[vapply(
      all_text,
      .qda_spaceprep_contains_demographic_claim,
      logical(1)
    )]

    if (length(demographic_text) > 0L) {
      stop(
        paste(
          "The response contains a demographic or observed-frequency consumer claim,",
          "but no explicit `context$consumers` was supplied."
        ),
        call. = FALSE
      )
    }
  }

  product_expertise
}

.parse_qda_spaceprep_response <- function(text,
                                          expected_products,
                                          valid_evidence_ids,
                                          context,
                                          expertise_scope,
                                          comparison_mode,
                                          metadata = list()) {
  tryCatch(
    {
      parsed <- .parse_json_response(text, simplifyDataFrame = FALSE)
      expertise <- .validate_qda_spaceprep_parsed(
        parsed = parsed,
        expected_products = expected_products,
        valid_evidence_ids = valid_evidence_ids,
        context = context,
        expertise_scope = expertise_scope,
        comparison_mode = comparison_mode,
        metadata = metadata
      )

      list(
        parse_status = "success",
        parse_error = NULL,
        product_expertise = expertise
      )
    },
    error = function(e) {
      list(
        parse_status = "error",
        parse_error = conditionMessage(e),
        product_expertise = NULL
      )
    }
  )
}

.as_qda_spaceprep_response_text <- function(response) {
  if (is.character(response)) {
    return(paste(response, collapse = "\n"))
  }

  if (is.data.frame(response) && "response" %in% names(response)) {
    return(paste(response$response, collapse = "\n"))
  }

  stop(
    "The LLM backend returned an unsupported response type for `nail_qda_spaceprep()`.",
    call. = FALSE
  )
}

.combine_isolated_qda_expertise <- function(unit_results,
                                            metadata,
                                            product_order) {
  statuses <- vapply(
    unit_results,
    function(x) x$parsed$parse_status,
    character(1)
  )

  if (!all(statuses == "success")) {
    return(list(
      parse_status = if (all(statuses == "error")) "error" else "partial_error",
      parse_error = stats::setNames(
        lapply(unit_results, function(x) x$parsed$parse_error),
        names(unit_results)
      ),
      product_expertise = NULL
    ))
  }

  products <- lapply(product_order, function(product) {
    unit_results[[product]]$parsed$product_expertise$products[[product]]
  })
  names(products) <- product_order

  list(
    parse_status = "success",
    parse_error = NULL,
    product_expertise = list(
      portfolio = .qda_spaceprep_empty_portfolio(),
      products = products,
      metadata = utils::modifyList(
        metadata,
        list(
          comparison_mode = "isolated",
          parse_status = "success",
          portfolio_interpretation_available = FALSE
        )
      )
    )
  )
}

# ---------------------------------------------------------------------------
# Main function
# ---------------------------------------------------------------------------

#' Prepare traceable product expertise from QDA profiles
#'
#' Converts the deterministic `product_profiles` artifact created by
#' [nail_qda()] into prompts for structured, evidence-traceable product
#' expertise. The function does not recalculate `decat()` and does not ask the
#' language model to transcribe statistical tables.
#'
#' The model is instead asked to interpret what the sensory profiles may mean
#' for product identity, differentiation, formulation, marketing, innovation,
#' and future consumer research. Every generated interpretation, hypothesis,
#' or recommendation must cite valid `evidence_id` values from
#' `attr(x, "product_profiles")`.
#'
#' @param dataset Deprecated. A QDA data frame used by the historical interface.
#'   Prefer supplying an object returned by [nail_qda()] through `x`.
#' @param formul Deprecated. Formula forwarded to [nail_qda()] only when the
#'   historical data-based interface is used.
#' @param firstvar Deprecated. Index of the first sensory variable, used only by
#'   the historical data-based interface.
#' @param lastvar Deprecated. Index of the last sensory variable, used only by
#'   the historical data-based interface. When omitted, the last column of
#'   `dataset` is used.
#' @param x The preferred input: an object returned by [nail_qda()] containing a
#'   valid `"product_profiles"` attribute. The optional `"decat_result"` and
#'   `"qda_settings"` attributes are preserved as provenance metadata.
#' @param request Optional single character string adding a customized expert
#'   task. It complements the selected `expertise_scope`; it cannot remove the
#'   mandatory JSON schema, evidence traceability, epistemic statuses, or
#'   validation requirements.
#' @param context Optional named list containing user-provided product context.
#'   Supported fields are `category`, `products`, `formulation`, `brand`,
#'   `market`, `consumers`, `usage`, and `constraints`. This context is displayed
#'   in a separate prompt section and is never presented as a statistical
#'   result.
#' @param expertise_scope Perspective requested from the model. One of
#'   `"sensory"`, `"formulation"`, `"marketing"`, `"consumer"`,
#'   `"innovation"`, or `"cross_functional"`. The conservative default is
#'   `"sensory"`.
#' @param comparison_mode Either `"joint"` or `"isolated"`. In joint mode, all
#'   products are included in one generation unit so that the model can compare
#'   the range, propose distinct identities, identify families, and discuss
#'   differentiation. In isolated mode, one independent generation unit is
#'   created per product.
#' @param product_knowledge Either `"known"` or `"unknown"`, controlling whether
#'   labels are treated as meaningful product names or anonymous stimulus codes.
#' @param model Character scalar naming the model used when `generate = TRUE`.
#' @param provider LLM provider, either `"ollama"` or `"gemini"`.
#' @param proba Significance threshold used only by the deprecated data-based
#'   interface when it internally calls [nail_qda()]. It does not modify an
#'   existing `x` object.
#' @param sample.pct Proportion of retained markers exposed in each prompt. The
#'   selection is deterministic and follows the marker rank stored in
#'   `product_profiles`. This affects prompt evidence only, never the source
#'   profiles.
#' @param drop.negative Logical. When `TRUE`, below-average retained markers are
#'   omitted from the prompt evidence. This does not modify
#'   `attr(x, "product_profiles")`.
#' @param expertise_mode Deprecated compatibility argument. `"sensory"` maps to
#'   `expertise_scope = "sensory"`, `"positioning"` to `"innovation"`, and
#'   `"hybrid"` to `"cross_functional"` when `expertise_scope` is not supplied.
#' @param generate Logical. With `FALSE`, the complete evidence payload and
#'   prompt are returned without an LLM call. With `TRUE`, each generation unit
#'   is sent to the selected provider and its JSON response is parsed and
#'   validated.
#' @param ... Additional provider-specific generation options passed to the
#'   internal LLM dispatcher.
#'
#' @details
#' The preferred workflow is:
#'
#' ```r
#' qda <- nail_qda(..., generate = FALSE)
#' expertise <- nail_qda_spaceprep(x = qda, generate = TRUE)
#' ```
#'
#' The statistical evidence used by this function comes exclusively from the
#' `product_profiles` attribute. Adjusted means provide the complete product
#' profile, while `retained_markers` provides the inferentially retained
#' product-by-attribute evidence and its deterministic `evidence_id` values.
#'
#' Generated claims may use only four statuses:
#'
#' - `"expert_interpretation"`;
#' - `"hypothesis"`;
#' - `"recommendation"`;
#' - `"user_context"`.
#'
#' Hypotheses and recommendations require a non-empty `validation_needed`
#' field. Formulation directions must be recommendations, while consumer-
#' preference and usage claims must be hypotheses. Each product family must cite
#' evidence for every product it lists. In isolated mode, portfolio-level fields
#' must remain empty. Without explicit `context$consumers`, demographic and
#' observed-frequency consumer claims are rejected during parsing.
#'
#' @return
#' With `comparison_mode = "joint"`, a list containing at least:
#'
#' - `prompt`: the complete prompt;
#' - `response`: the raw response, or `NULL` when `generate = FALSE`;
#' - `parsed`: an explicit parsing record containing `parse_status`,
#'   `parse_error`, and `product_expertise`;
#' - `product_expertise`: the validated expertise object on success;
#' - `evidence`: the exact evidence payload exposed to the model;
#' - `metadata`: generation and provenance metadata.
#'
#' With `comparison_mode = "isolated"`, a named list of such generation units is
#' returned, one per product. A combined `product_expertise` object is attached
#' as an attribute when every unit parses successfully.
#'
#' A successful `product_expertise` object contains predictable `portfolio`,
#' `products`, and `metadata` components. Invalid JSON or invalid epistemic
#' content never produces a silently completed expertise object: `parse_status`
#' is set to `"error"` and the validation message is stored in `parse_error`.
#'
#' @seealso [nail_qda()], [nail_qda_space()]
#' @export
#'
#' @examples
#' \dontrun{
#' library(NaileR)
#' library(SensoMineR)
#'
#' data(chocolates, package = "SensoMineR")
#'
#' qda_choc <- nail_qda(
#'   dataset = sensochoc,
#'   formul = "~Product+Panelist",
#'   firstvar = 5,
#'   lastvar = ncol(sensochoc),
#'   product_knowledge = "known",
#'   generate = FALSE
#' )
#'
#' # Build one portfolio-level prompt without calling an LLM.
#' prep <- nail_qda_spaceprep(
#'   x = qda_choc,
#'   expertise_scope = "cross_functional",
#'   comparison_mode = "joint",
#'   request = "Propose distinct descriptive identities and validation priorities.",
#'   context = list(category = "chocolate"),
#'   generate = FALSE
#' )
#'
#' cat(prep$prompt)
#' prep$evidence
#'
#' # Create one independent prompt per product.
#' isolated <- nail_qda_spaceprep(
#'   x = qda_choc,
#'   expertise_scope = "sensory",
#'   comparison_mode = "isolated",
#'   generate = FALSE
#' )
#'
#' cat(isolated[[1]]$prompt)
#'
#' # Generate and validate a joint JSON response with Ollama.
#' generated <- nail_qda_spaceprep(
#'   x = qda_choc,
#'   expertise_scope = "cross_functional",
#'   comparison_mode = "joint",
#'   provider = "ollama",
#'   model = "llama3",
#'   generate = TRUE
#' )
#'
#' generated$parsed$parse_status
#' generated$product_expertise$portfolio
#' generated$product_expertise$products[[1]]
#' }
nail_qda_spaceprep <- function(dataset = NULL,
                               formul = NULL,
                               firstvar = NULL,
                               lastvar = NULL,
                               x = NULL,
                               request = NULL,
                               context = NULL,
                               expertise_scope = "sensory",
                               comparison_mode = "joint",
                               product_knowledge = "unknown",
                               model = "llama3",
                               provider = c("ollama", "gemini"),
                               proba = 0.05,
                               sample.pct = 1,
                               drop.negative = FALSE,
                               expertise_mode = NULL,
                               generate = FALSE,
                               ...) {
  expertise_scope_missing <- missing(expertise_scope)

  if (!is.null(expertise_mode)) {
    expertise_mode <- match.arg(expertise_mode, c("sensory", "positioning", "hybrid"))
    warning(
      paste(
        "`expertise_mode` is deprecated in `nail_qda_spaceprep()`.",
        "Use `expertise_scope` instead."
      ),
      call. = FALSE
    )

    if (expertise_scope_missing) {
      expertise_scope <- switch(
        expertise_mode,
        sensory = "sensory",
        positioning = "innovation",
        hybrid = "cross_functional"
      )
    }
  }

  expertise_scope <- match.arg(expertise_scope, .qda_spaceprep_scopes)
  comparison_mode <- match.arg(comparison_mode, c("joint", "isolated"))
  product_knowledge <- match.arg(product_knowledge, c("unknown", "known"))
  provider <- match.arg(provider)

  if (!is.logical(generate) || length(generate) != 1L || is.na(generate)) {
    stop("`generate` must be a single non-missing logical value.", call. = FALSE)
  }
  if (!is.logical(drop.negative) || length(drop.negative) != 1L || is.na(drop.negative)) {
    stop("`drop.negative` must be a single non-missing logical value.", call. = FALSE)
  }
  if (!is.numeric(sample.pct) || length(sample.pct) != 1L || is.na(sample.pct) ||
      sample.pct <= 0 || sample.pct > 1) {
    stop("`sample.pct` must be a single numeric value in (0, 1].", call. = FALSE)
  }
  if (!is.null(request) && !.qda_spaceprep_is_nonempty_character_scalar(request)) {
    stop("`request` must be NULL or a single non-empty character string.", call. = FALSE)
  }

  context <- .validate_qda_spaceprep_context(context)

  source <- .extract_qda_spaceprep_source(
    x = x,
    dataset = dataset,
    formul = formul,
    firstvar = firstvar,
    lastvar = lastvar,
    proba = proba,
    model = model,
    provider = provider,
    product_knowledge = product_knowledge
  )

  all_evidence_ids <- unlist(lapply(source$product_profiles, function(p) {
    p$retained_markers$evidence_id
  }), use.names = FALSE)

  if (length(all_evidence_ids) == 0L) {
    stop(
      "Execution halted: No significant sensory differences (retained_markers) found in the provided object. There is no statistical evidence for the LLM to interpret.",
      call. = FALSE
    )
  }

  units <- .build_qda_spaceprep_units(
    product_profiles = source$product_profiles,
    request = request,
    context = context,
    expertise_scope = expertise_scope,
    comparison_mode = comparison_mode,
    product_knowledge = product_knowledge,
    sample.pct = sample.pct,
    drop.negative = drop.negative
  )

  metadata <- list(
    expertise_scope = expertise_scope,
    comparison_mode = comparison_mode,
    product_knowledge = product_knowledge,
    provider = provider,
    model = model,
    generate = generate,
    request = request,
    context = context,
    context_fields = names(context)[vapply(context, function(z) {
      .is_qda_spaceprep_context_present(list(value = z))
    }, logical(1))],
    products = names(source$product_profiles),
    evidence_source = "attr(x, 'product_profiles')",
    legacy_interface = source$legacy_interface,
    qda_settings = source$qda_settings
  )

  make_not_generated_unit <- function(unit) {
    list(
      prompt = unit$prompt,
      response = NULL,
      parsed = list(
        parse_status = "not_generated",
        parse_error = NULL,
        product_expertise = NULL
      ),
      product_expertise = NULL,
      evidence = unit$evidence,
      metadata = c(metadata, list(unit_products = unit$products))
    )
  }

  if (!generate) {
    out <- lapply(units, make_not_generated_unit)

    if (comparison_mode == "joint") {
      result <- out[[1L]]
      class(result) <- c("nail_qda_spaceprep_joint", "nail_qda_spaceprep", "list")
      attr(result, "product_profiles") <- source$product_profiles
      attr(result, "decat_result") <- source$decat_result
      return(result)
    }

    class(out) <- c("nail_qda_spaceprep_isolated", "nail_qda_spaceprep", "list")
    attr(out, "product_expertise") <- NULL
    attr(out, "parsed") <- list(
      parse_status = "not_generated",
      parse_error = NULL,
      product_expertise = NULL
    )
    attr(out, "metadata") <- metadata
    attr(out, "product_profiles") <- source$product_profiles
    attr(out, "decat_result") <- source$decat_result
    return(out)
  }

  llm_api_options <- list(...)

  generated_units <- lapply(units, function(unit) {
    raw_response <- .call_llm_base(
      provider = provider,
      model = model,
      prompt = unit$prompt,
      output = "text",
      llm_api_options = llm_api_options
    )
    response_text <- .as_qda_spaceprep_response_text(raw_response)

    parsed <- .parse_qda_spaceprep_response(
      text = response_text,
      expected_products = unit$products,
      valid_evidence_ids = unit$evidence$evidence_ids,
      context = context,
      expertise_scope = expertise_scope,
      comparison_mode = comparison_mode,
      metadata = c(metadata, list(unit_products = unit$products))
    )

    list(
      prompt = unit$prompt,
      response = raw_response,
      parsed = parsed,
      product_expertise = parsed$product_expertise,
      evidence = unit$evidence,
      metadata = c(metadata, list(unit_products = unit$products))
    )
  })
  names(generated_units) <- names(units)

  if (comparison_mode == "joint") {
    result <- generated_units[[1L]]
    class(result) <- c("nail_qda_spaceprep_joint", "nail_qda_spaceprep", "list")
    attr(result, "product_profiles") <- source$product_profiles
    attr(result, "decat_result") <- source$decat_result
    return(result)
  }

  combined <- .combine_isolated_qda_expertise(
    unit_results = generated_units,
    metadata = metadata,
    product_order = names(source$product_profiles)
  )

  class(generated_units) <- c("nail_qda_spaceprep_isolated", "nail_qda_spaceprep", "list")
  attr(generated_units, "product_expertise") <- combined$product_expertise
  attr(generated_units, "parsed") <- combined
  attr(generated_units, "metadata") <- metadata
  attr(generated_units, "product_profiles") <- source$product_profiles
  attr(generated_units, "decat_result") <- source$decat_result
  generated_units
}
