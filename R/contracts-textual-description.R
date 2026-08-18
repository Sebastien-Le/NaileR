# ---------------------------------------------------------------------------
# Structured textual-description contract used by nail_textual_prep()
# and nail_textual()
# ---------------------------------------------------------------------------

.nail_text_nullable_string_schema <- function() {
  list(type = .nail_structured_json_array(c("string", "null")))
}

.nail_text_claim_schema <- function(max_evidence_ids = 50L,
                                    min_evidence_ids = 1L) {
  fields <- c(
    "text",
    "status",
    "evidence_ids",
    "support",
    "validation_needed"
  )

  list(
    type = "object",
    additionalProperties = FALSE,
    required = .nail_structured_json_array(fields),
    propertyOrdering = .nail_structured_json_array(fields),
    properties = list(
      text = list(type = "string", minLength = 1L),
      status = list(type = "string", enum = list("expert_interpretation")),
      evidence_ids = list(
        type = "array",
        items = list(type = "string"),
        minItems = as.integer(min_evidence_ids),
        maxItems = as.integer(max_evidence_ids)
      ),
      support = list(type = "string", minLength = 1L),
      validation_needed = .nail_text_nullable_string_schema()
    )
  )
}

.nail_text_claim_array_schema <- function(max_items,
                                          max_evidence_ids = 50L,
                                          min_evidence_ids = 1L) {
  list(
    type = "array",
    items = .nail_text_claim_schema(
      max_evidence_ids = max_evidence_ids,
      min_evidence_ids = min_evidence_ids
    ),
    minItems = 0L,
    maxItems = as.integer(max_items)
  )
}

.nail_text_quote_schema <- function() {
  fields <- c("evidence_id", "quotation", "rationale", "status")

  list(
    type = "object",
    additionalProperties = FALSE,
    required = .nail_structured_json_array(fields),
    propertyOrdering = .nail_structured_json_array(fields),
    properties = list(
      evidence_id = list(type = "string", minLength = 1L),
      quotation = list(type = "string", minLength = 1L),
      rationale = list(type = "string", minLength = 1L),
      status = list(type = "string", enum = list("expert_interpretation"))
    )
  )
}

.nail_text_quote_array_schema <- function(max_items) {
  list(
    type = "array",
    items = .nail_text_quote_schema(),
    minItems = 0L,
    maxItems = as.integer(max_items)
  )
}

.nail_text_group_schema <- function(group_name,
                                    n_central_verbatims = 2L,
                                    n_contrastive_verbatims = 1L,
                                    max_themes = 3L,
                                    max_concerns = 3L,
                                    max_variations = 3L,
                                    max_minority = 3L,
                                    max_limits = 4L) {
  fields <- c(
    "group",
    "core_textual_profile",
    "main_themes",
    "dominant_concerns",
    "tone_or_stance",
    "internal_variation",
    "minority_positions",
    "representative_verbatims",
    "contrastive_verbatims",
    "interpretation_limits"
  )

  list(
    type = "object",
    additionalProperties = FALSE,
    required = .nail_structured_json_array(fields),
    propertyOrdering = .nail_structured_json_array(fields),
    properties = list(
      group = list(type = "string", enum = list(group_name)),
      core_textual_profile = .nail_text_claim_schema(),
      main_themes = .nail_text_claim_array_schema(max_themes),
      dominant_concerns = .nail_text_claim_array_schema(max_concerns),
      tone_or_stance = .nail_text_claim_schema(),
      internal_variation = .nail_text_claim_array_schema(max_variations),
      minority_positions = .nail_text_claim_array_schema(max_minority),
      representative_verbatims = .nail_text_quote_array_schema(
        n_central_verbatims
      ),
      contrastive_verbatims = .nail_text_quote_array_schema(
        n_contrastive_verbatims
      ),
      interpretation_limits = .nail_text_claim_array_schema(
        max_limits,
        max_evidence_ids = 0L,
        min_evidence_ids = 0L
      )
    )
  )
}

.nail_text_unit_schema <- function(groups,
                                   n_central_verbatims,
                                   n_contrastive_verbatims) {
  group_properties <- stats::setNames(
    lapply(groups, function(group_name) {
      .nail_text_group_schema(
        group_name = group_name,
        n_central_verbatims = n_central_verbatims,
        n_contrastive_verbatims = n_contrastive_verbatims
      )
    }),
    groups
  )

  list(
    type = "object",
    additionalProperties = FALSE,
    required = list("groups"),
    propertyOrdering = list("groups"),
    properties = list(
      groups = list(
        type = "object",
        additionalProperties = FALSE,
        required = .nail_structured_json_array(groups),
        propertyOrdering = .nail_structured_json_array(groups),
        properties = group_properties
      )
    )
  )
}

.nail_text_records <- function(x) {
  if (!is.data.frame(x) || nrow(x) == 0L) return(list())
  unname(lapply(seq_len(nrow(x)), function(i) {
    row <- as.list(x[i, , drop = FALSE])
    lapply(row, function(value) {
      if (length(value) == 0L || is.na(value[[1L]])) NULL else value[[1L]]
    })
  }))
}

.nail_text_group_data <- function(textual_evidence,
                                  group_name,
                                  include_indicators = TRUE) {
  registry <- textual_evidence$evidence_registry
  rows <- registry[
    !is.na(registry$group) &
      registry$group == group_name &
      !is.na(registry$included_in_prompt) &
      registry$included_in_prompt,
    ,
    drop = FALSE
  ]

  diagnostics <- textual_evidence$group_diagnostics[
    textual_evidence$group_diagnostics$group == group_name,
    ,
    drop = FALSE
  ]
  diagnostics <- if (nrow(diagnostics) == 0L) {
    list()
  } else {
    as.list(diagnostics[1L, , drop = FALSE])
  }

  group_info <- textual_evidence$groups[[group_name]]
  lexical <- if (!isTRUE(include_indicators) || is.null(group_info)) {
    NULL
  } else {
    .textual_prep_lexical_prompt_view(group_info, include_indicators = TRUE)
  }

  verbatims <- lapply(seq_len(nrow(rows)), function(i) {
    list(
      evidence_id = rows$evidence_id[[i]],
      row_index = rows$row_index[[i]],
      original_text = rows$original_text[[i]]
    )
  })

  list(
    group = group_name,
    diagnostics = diagnostics,
    lexical_indicators = lexical,
    allowed_evidence_ids = as.character(rows$evidence_id),
    verbatims = verbatims
  )
}

.nail_text_unit_data <- function(textual_evidence,
                                 groups,
                                 include_indicators = TRUE) {
  list(
    groups = stats::setNames(
      lapply(groups, function(group_name) {
        .nail_text_group_data(
          textual_evidence = textual_evidence,
          group_name = group_name,
          include_indicators = include_indicators
        )
      }),
      groups
    )
  )
}

.nail_text_scope_emphasis <- function(analysis_scope) {
  if (identical(analysis_scope, "general")) {
    return(paste(
      "Describe only the explicit textual profile: central themes, concerns,",
      "tone, internal variation, minority positions, and methodological limits."
    ))
  }

  paste(
    "Use the requested", analysis_scope,
    "scope only as an analytical emphasis.",
    "Do not add specialized fields, diagnoses, recommendations, causal claims,",
    "or constructs not explicitly supported by the supplied texts."
  )
}

.nail_text_unit_prompt <- function(unit_data,
                                   analysis_scope,
                                   comparison_mode,
                                   request,
                                   context,
                                   prompt_style,
                                   text_role,
                                   n_central_verbatims,
                                   n_contrastive_verbatims) {
  evidence_json <- jsonlite::toJSON(
    unit_data,
    auto_unbox = TRUE,
    pretty = TRUE,
    null = "null",
    na = "null"
  )
  context_json <- if (length(context) > 0L) {
    jsonlite::toJSON(
      context,
      auto_unbox = TRUE,
      pretty = TRUE,
      null = "null",
      na = "null"
    )
  } else {
    "null"
  }
  request_text <- if (is.null(request)) "None." else request

  batching_rule <- if (identical(comparison_mode, "joint")) {
    paste(
      "Several groups are supplied in the same request only to harmonize",
      "terminology. Describe each group independently. Do not make cross-group",
      "claims in this contract."
    )
  } else {
    "Only one group is supplied in this generation unit."
  }

  detail_rule <- if (identical(prompt_style, "compact")) {
    paste(
      "Keep each claim concise and omit unsupported optional items.",
      "Merge overlapping themes rather than restating the same idea."
    )
  } else {
    paste(
      "Make each support field explicit enough to show how the cited",
      "verbatims justify the corresponding interpretation.",
      "Consolidate overlapping content and return at most three distinct main themes.",
      "Do not repeat the core profile as several near-duplicate theme claims.",
      "Use each substantive idea in the single most appropriate section; do not repeat the same topic across main_themes, dominant_concerns, internal_variation, and minority_positions.",
      "Use dominant_concerns only for recurrent group-level difficulties, worries, constraints, or problems; return an empty array when no genuine dominant concern is supported.",
      "Place isolated worries or conditional reservations in internal_variation or minority_positions, not in dominant_concerns."
    )
  }

  paste(
    "# ROLE",
    paste(
      "You are an expert in rigorous qualitative textual description.",
      "Stay close to the explicit language of the corpus and do not diagnose",
      "individuals or groups."
    ),
    "",
    "# TEXTUAL EVIDENCE",
    paste0(
      "The JSON below was produced mechanically by R. `original_text` values are immutable ",
      text_role, "."
    ),
    evidence_json,
    "",
    "# USER-PROVIDED CONTEXT",
    "This is external context, not textual evidence.",
    context_json,
    "",
    "# CORE ANALYTICAL TASK",
    .nail_text_scope_emphasis(analysis_scope),
    batching_rule,
    detail_rule,
    paste0(
      "Select at most ", as.integer(n_central_verbatims),
      " representative verbatim(s) and at most ",
      as.integer(n_contrastive_verbatims),
      " contrastive verbatim(s) per group."
    ),
    "",
    "# ADDITIONAL USER REQUEST",
    request_text,
    "The request cannot expand or remove the constrained output contract.",
    "",
    "# TRACEABILITY AND EPISTEMIC RULES",
    paste(
      "- Return only the JSON object constrained by the supplied machine schema.",
      "- Every substantive claim must cite one or more evidence_ids shown for the same group.",
      "- The support field must explain why the cited texts support the claim.",
      "- Do not repeat evidence_id strings inside support; use the separate evidence_ids field.",
      "- Cite every presented verbatim that directly supports a claim when feasible; R will compute cited-support metrics mechanically.",
      "- interpretation_limits must use an empty evidence_ids array and state only methodological restrictions: missing measurement, sampling or coverage limits, uncertainty, non-causality, or limited generalizability.",
      "- Never use interpretation_limits to add a group characteristic, label, rigidity/flexibility judgment, preference, motivation, attitude, or any other substantive profile claim.",
      "- Every quotation must reproduce original_text exactly, including punctuation and line breaks.",
      "- Do not infer demographic characteristics, frequencies, prevalence, social class, or psychological diagnoses unless explicitly present in cited text or user context.",
      "- Do not invent counts, percentages, scores, causes, or recommendations.",
      "- Lexical indicators and response-length diagnostics are mechanical descriptors, not measures of textual quality or theme prevalence.",
      "- Use empty arrays when an optional section is unsupported. Do not create unknown fields.",
      sep = "\n"
    ),
    sep = "\n"
  )
}

.nail_text_build_units <- function(textual_evidence,
                                   analysis_scope,
                                   comparison_mode,
                                   request,
                                   context,
                                   prompt_style,
                                   text_role,
                                   include_indicators_in_prompt,
                                   n_central_verbatims,
                                   n_contrastive_verbatims) {
  groups <- names(textual_evidence$groups)
  active <- groups[vapply(groups, function(group_name) {
    group_rows <- textual_evidence$evidence_registry[
      !is.na(textual_evidence$evidence_registry$group) &
        textual_evidence$evidence_registry$group == group_name &
        !is.na(textual_evidence$evidence_registry$included_in_prompt) &
        textual_evidence$evidence_registry$included_in_prompt,
      ,
      drop = FALSE
    ]
    nrow(group_rows) > 0L
  }, logical(1))]

  make_unit <- function(unit_name, unit_groups) {
    has_evidence <- length(unit_groups) > 0L
    unit_data <- if (has_evidence) {
      data <- .nail_text_unit_data(
        textual_evidence = textual_evidence,
        groups = unit_groups,
        include_indicators = include_indicators_in_prompt
      )
      data$constraints <- list(
        max_main_themes = 3L,
        max_dominant_concerns = 3L,
        max_internal_variation = 3L,
        max_minority_positions = 3L,
        max_representative_verbatims = as.integer(n_central_verbatims),
        max_contrastive_verbatims = as.integer(n_contrastive_verbatims),
        max_interpretation_limits = 4L
      )
      data
    } else {
      list(groups = list(), constraints = list())
    }
    schema <- if (has_evidence) {
      .nail_text_unit_schema(
        groups = unit_groups,
        n_central_verbatims = n_central_verbatims,
        n_contrastive_verbatims = n_contrastive_verbatims
      )
    } else {
      NULL
    }
    prompt <- if (has_evidence) {
      .nail_text_unit_prompt(
        unit_data = unit_data,
        analysis_scope = analysis_scope,
        comparison_mode = comparison_mode,
        request = request,
        context = context,
        prompt_style = prompt_style,
        text_role = text_role,
        n_central_verbatims = n_central_verbatims,
        n_contrastive_verbatims = n_contrastive_verbatims
      )
    } else {
      NULL
    }

    list(
      unit_type = "textual_group_description",
      unit_name = unit_name,
      groups = unit_groups,
      has_evidence = has_evidence,
      prompt = prompt,
      schema = schema,
      unit_data = unit_data,
      response = NULL,
      raw_response = NULL,
      call_attempted = FALSE,
      parsed = list(
        parse_status = if (has_evidence) "not_generated" else "no_evidence",
        parse_error = if (has_evidence) NULL else
          "No verbatim was included in this generation unit.",
        textual_profiles = NULL,
        textual_description = NULL
      ),
      parse_status = if (has_evidence) "not_generated" else "no_evidence",
      parse_error = if (has_evidence) NULL else
        "No verbatim was included in this generation unit.",
      elapsed_seconds = NA_real_
    )
  }

  if (identical(comparison_mode, "joint")) {
    return(list(joint = make_unit("joint", active)))
  }

  units <- lapply(groups, function(group_name) {
    unit_groups <- if (group_name %in% active) group_name else character(0)
    make_unit(group_name, unit_groups)
  })
  names(units) <- groups
  units
}

.nail_text_scalar_string <- function(x, path) {
  if (!is.character(x) || length(x) != 1L || is.na(x) || !nzchar(trimws(x))) {
    stop(paste0("`", path, "` must be one non-empty string."), call. = FALSE)
  }
  trimws(as.character(x))
}

.nail_text_validate_claim <- function(x,
                                      path,
                                      group_data,
                                      registry,
                                      context,
                                      require_evidence = TRUE,
                                      methodological_limit = FALSE) {
  fields <- c(
    "text", "status", "evidence_ids", "support", "validation_needed"
  )
  .nail_structured_required_names(x, fields, path = path)

  text <- .nail_text_scalar_string(x$text, paste0(path, "$text"))
  support <- .nail_text_scalar_string(x$support, paste0(path, "$support"))
  status <- .nail_text_scalar_string(x$status, paste0(path, "$status"))
  if (!identical(status, "expert_interpretation")) {
    stop(
      paste0("`", path, "$status` must be `expert_interpretation`."),
      call. = FALSE
    )
  }

  evidence_ids <- .nail_structured_as_id_vector(x$evidence_ids)
  if (isTRUE(require_evidence) && length(evidence_ids) == 0L) {
    stop(paste0("`", path, "` must cite at least one evidence ID."), call. = FALSE)
  }
  unknown <- setdiff(evidence_ids, group_data$allowed_evidence_ids)
  if (length(unknown) > 0L) {
    stop(
      paste0(
        "`", path, "` cites unknown, non-presented, or cross-group evidence IDs: ",
        paste(unknown, collapse = ", "), "."
      ),
      call. = FALSE
    )
  }

  if (!is.null(x$validation_needed)) {
    stop(
      paste0(
        "`", path,
        "$validation_needed` must be null in the core textual-description contract."
      ),
      call. = FALSE
    )
  }

  if (isTRUE(methodological_limit)) {
    .nail_structured_validate_methodological_limit(
      text = text,
      support = support,
      evidence_ids = evidence_ids,
      path = path
    )
  }

  safety_context <- context
  if (isTRUE(methodological_limit)) {
    safety_context$.mechanical_diagnostics <- group_data$diagnostics
    safety_context$.mechanical_lexical_indicators <-
      group_data$lexical_indicators
  }

  .textual_prep_validate_claim_safety(
    text = paste(text, support, sep = "\n"),
    evidence_ids = evidence_ids,
    registry = registry,
    context = safety_context,
    allow_methodological_language = isTRUE(methodological_limit)
  )

  list(
    text = text,
    status = status,
    evidence_ids = evidence_ids,
    support = support,
    validation_needed = NULL
  )
}

.nail_text_validate_claim_array <- function(x,
                                            path,
                                            group_data,
                                            registry,
                                            context,
                                            require_evidence = TRUE,
                                            methodological_limit = FALSE) {
  if (is.null(x) || length(x) == 0L) return(list())
  if (!is.list(x) || is.data.frame(x)) {
    stop(paste0("`", path, "` must be a JSON array."), call. = FALSE)
  }
  lapply(seq_along(x), function(i) {
    .nail_text_validate_claim(
      x[[i]],
      path = paste0(path, "[[", i, "]]"),
      group_data = group_data,
      registry = registry,
      context = context,
      require_evidence = require_evidence,
      methodological_limit = methodological_limit
    )
  })
}

.nail_text_validate_quote <- function(x,
                                      path,
                                      group_data,
                                      registry) {
  fields <- c("evidence_id", "quotation", "rationale", "status")
  .nail_structured_required_names(x, fields, path = path)

  evidence_id <- .nail_text_scalar_string(
    x$evidence_id,
    paste0(path, "$evidence_id")
  )
  if (!evidence_id %in% group_data$allowed_evidence_ids) {
    stop(
      paste0("`", path, "` cites unknown or cross-group evidence."),
      call. = FALSE
    )
  }
  if (!is.character(x$quotation) || length(x$quotation) != 1L ||
      is.na(x$quotation) || !nzchar(trimws(x$quotation))) {
    stop(
      paste0("`", path, "$quotation` must be one non-empty string."),
      call. = FALSE
    )
  }
  quotation <- as.character(x$quotation)
  rationale <- .nail_text_scalar_string(x$rationale, paste0(path, "$rationale"))
  status <- .nail_text_scalar_string(x$status, paste0(path, "$status"))
  if (!identical(status, "expert_interpretation")) {
    stop(
      paste0("`", path, "$status` must be `expert_interpretation`."),
      call. = FALSE
    )
  }

  source_text <- registry$original_text[
    match(evidence_id, registry$evidence_id)
  ]
  if (length(source_text) != 1L || is.na(source_text) ||
      !identical(quotation, source_text)) {
    stop(
      paste0("`", path, "$quotation` must reproduce original_text exactly."),
      call. = FALSE
    )
  }

  list(
    evidence_id = evidence_id,
    quotation = quotation,
    rationale = rationale,
    status = status
  )
}

.nail_text_validate_quote_array <- function(x,
                                            path,
                                            group_data,
                                            registry) {
  if (is.null(x) || length(x) == 0L) return(list())
  if (!is.list(x) || is.data.frame(x)) {
    stop(paste0("`", path, "` must be a JSON array."), call. = FALSE)
  }
  lapply(seq_along(x), function(i) {
    .nail_text_validate_quote(
      x[[i]],
      path = paste0(path, "[[", i, "]]"),
      group_data = group_data,
      registry = registry
    )
  })
}

.nail_text_support_metrics <- function(evidence_ids, group_data) {
  included_n <- length(group_data$allowed_evidence_ids)
  cited_n <- length(unique(evidence_ids))
  list(
    cited_support_n = as.integer(cited_n),
    included_verbatim_n = as.integer(included_n),
    cited_support_fraction = if (included_n == 0L) NA_real_ else cited_n / included_n,
    interpretation_note = paste(
      "This is the fraction of included verbatims explicitly cited by the claim.",
      "It is not an estimated prevalence of the theme in the full group."
    )
  )
}

.nail_text_add_claim_ids <- function(claims,
                                     group_name,
                                     section,
                                     group_data) {
  if (length(claims) == 0L) return(list())
  lapply(seq_along(claims), function(i) {
    claim <- claims[[i]]
    claim$claim_id <- paste("text", group_name, section, i, sep = "::")
    claim$source <- "textual"
    claim$group <- group_name
    claim$section <- section
    claim$support_metrics <- .nail_text_support_metrics(
      claim$evidence_ids,
      group_data = group_data
    )
    claim
  })
}

.nail_text_add_quote_ids <- function(quotes,
                                     group_name,
                                     section) {
  if (length(quotes) == 0L) return(list())
  lapply(seq_along(quotes), function(i) {
    quote <- quotes[[i]]
    quote$quote_id <- paste("text_quote", group_name, section, i, sep = "::")
    quote$source <- "textual"
    quote$group <- group_name
    quote$section <- section
    quote
  })
}

.nail_text_validate_group_response <- function(parsed,
                                               group_data,
                                               registry,
                                               context,
                                               constraints) {
  fields <- c(
    "group",
    "core_textual_profile",
    "main_themes",
    "dominant_concerns",
    "tone_or_stance",
    "internal_variation",
    "minority_positions",
    "representative_verbatims",
    "contrastive_verbatims",
    "interpretation_limits"
  )
  .nail_structured_required_names(parsed, fields, path = "textual_description")

  length_checks <- c(
    main_themes = constraints$max_main_themes,
    dominant_concerns = constraints$max_dominant_concerns,
    internal_variation = constraints$max_internal_variation,
    minority_positions = constraints$max_minority_positions,
    representative_verbatims = constraints$max_representative_verbatims,
    contrastive_verbatims = constraints$max_contrastive_verbatims,
    interpretation_limits = constraints$max_interpretation_limits
  )
  for (field in names(length_checks)) {
    if (length(parsed[[field]]) > length_checks[[field]]) {
      stop(
        paste0(
          "`textual_description$", field, "` exceeds the permitted length of ",
          length_checks[[field]], "."
        ),
        call. = FALSE
      )
    }
  }

  group_name <- .nail_text_scalar_string(
    parsed$group,
    "textual_description$group"
  )
  if (!identical(group_name, group_data$group)) {
    stop("The generated group does not match the requested group.", call. = FALSE)
  }

  core <- .nail_text_validate_claim(
    parsed$core_textual_profile,
    "textual_description$core_textual_profile",
    group_data,
    registry,
    context,
    require_evidence = TRUE
  )
  themes <- .nail_text_validate_claim_array(
    parsed$main_themes,
    "textual_description$main_themes",
    group_data,
    registry,
    context,
    require_evidence = TRUE
  )
  concerns <- .nail_text_validate_claim_array(
    parsed$dominant_concerns,
    "textual_description$dominant_concerns",
    group_data,
    registry,
    context,
    require_evidence = TRUE
  )
  tone <- .nail_text_validate_claim(
    parsed$tone_or_stance,
    "textual_description$tone_or_stance",
    group_data,
    registry,
    context,
    require_evidence = TRUE
  )
  variation <- .nail_text_validate_claim_array(
    parsed$internal_variation,
    "textual_description$internal_variation",
    group_data,
    registry,
    context,
    require_evidence = TRUE
  )
  minority <- .nail_text_validate_claim_array(
    parsed$minority_positions,
    "textual_description$minority_positions",
    group_data,
    registry,
    context,
    require_evidence = TRUE
  )
  representative <- .nail_text_validate_quote_array(
    parsed$representative_verbatims,
    "textual_description$representative_verbatims",
    group_data,
    registry
  )
  contrastive <- .nail_text_validate_quote_array(
    parsed$contrastive_verbatims,
    "textual_description$contrastive_verbatims",
    group_data,
    registry
  )
  limits <- .nail_text_validate_claim_array(
    parsed$interpretation_limits,
    "textual_description$interpretation_limits",
    group_data,
    registry,
    context,
    require_evidence = FALSE,
    methodological_limit = TRUE
  )

  list(
    group = group_name,
    availability = "available",
    core_textual_profile = .nail_text_add_claim_ids(
      list(core), group_name, "core_textual_profile", group_data
    )[[1L]],
    main_themes = .nail_text_add_claim_ids(
      themes, group_name, "main_themes", group_data
    ),
    dominant_concerns = .nail_text_add_claim_ids(
      concerns, group_name, "dominant_concerns", group_data
    ),
    tone_or_stance = .nail_text_add_claim_ids(
      list(tone), group_name, "tone_or_stance", group_data
    )[[1L]],
    internal_variation = .nail_text_add_claim_ids(
      variation, group_name, "internal_variation", group_data
    ),
    minority_positions = .nail_text_add_claim_ids(
      minority, group_name, "minority_positions", group_data
    ),
    representative_verbatims = .nail_text_add_quote_ids(
      representative, group_name, "representative_verbatims"
    ),
    contrastive_verbatims = .nail_text_add_quote_ids(
      contrastive, group_name, "contrastive_verbatims"
    ),
    interpretation_limits = .nail_text_add_claim_ids(
      limits, group_name, "interpretation_limits", group_data
    )
  )
}

.nail_text_validate_unit_response <- function(parsed,
                                              unit_data,
                                              registry,
                                              context) {
  .nail_structured_required_names(parsed, "groups", path = "textual_description")
  if (!is.list(parsed$groups) || is.data.frame(parsed$groups) ||
      is.null(names(parsed$groups))) {
    stop("`textual_description$groups` must be a named JSON object.", call. = FALSE)
  }

  expected <- names(unit_data$groups)
  if (!setequal(names(parsed$groups), expected)) {
    stop("The parsed group names do not match the generation unit.", call. = FALSE)
  }

  groups <- stats::setNames(lapply(expected, function(group_name) {
    .nail_text_validate_group_response(
      parsed = parsed$groups[[group_name]],
      group_data = unit_data$groups[[group_name]],
      registry = registry,
      context = context,
      constraints = unit_data$constraints
    )
  }), expected)

  list(groups = groups)
}

.nail_text_parse_unit_response <- function(text,
                                           unit_data,
                                           registry,
                                           context) {
  tryCatch({
    parsed <- .nail_structured_parse_json(text)
    validated <- .nail_text_validate_unit_response(
      parsed = parsed,
      unit_data = unit_data,
      registry = registry,
      context = context
    )
    list(
      parse_status = "success",
      parse_error = NULL,
      groups = validated$groups
    )
  }, error = function(e) {
    list(
      parse_status = "error",
      parse_error = conditionMessage(e),
      groups = NULL
    )
  })
}

.nail_text_mechanical_claim <- function(text,
                                        group_name,
                                        section,
                                        index = 1L) {
  list(
    text = text,
    status = "user_context",
    evidence_ids = character(),
    support = "This limit was derived mechanically from corpus coverage or generation status.",
    validation_needed = NULL,
    claim_id = paste("text", group_name, section, index, sep = "::"),
    source = "textual",
    group = group_name,
    section = section,
    support_metrics = list(
      cited_support_n = 0L,
      included_verbatim_n = NA_integer_,
      cited_support_fraction = NA_real_,
      interpretation_note = "This is a mechanically added methodological limit."
    )
  )
}

.nail_text_unavailable_group <- function(group_name, reason) {
  list(
    group = group_name,
    availability = "unavailable",
    core_textual_profile = NULL,
    main_themes = list(),
    dominant_concerns = list(),
    tone_or_stance = NULL,
    internal_variation = list(),
    minority_positions = list(),
    representative_verbatims = list(),
    contrastive_verbatims = list(),
    interpretation_limits = list(
      .nail_text_mechanical_claim(
        text = reason,
        group_name = group_name,
        section = "interpretation_limits"
      )
    )
  )
}

.nail_text_add_sampling_limit <- function(group_description,
                                          textual_evidence) {
  group_name <- group_description$group
  diag <- textual_evidence$group_diagnostics[
    textual_evidence$group_diagnostics$group == group_name,
    ,
    drop = FALSE
  ]
  if (nrow(diag) == 0L) return(group_description)

  if (diag$n_non_empty[[1L]] == 0L) {
    return(.nail_text_unavailable_group(
      group_name,
      "No non-empty verbatim was available for this group."
    ))
  }
  if (diag$n_included_in_prompt[[1L]] == 0L) {
    return(.nail_text_unavailable_group(
      group_name,
      "No verbatim from this group was included in the prompt."
    ))
  }

  if (is.finite(diag$sampling_fraction[[1L]]) &&
      diag$sampling_fraction[[1L]] < 1) {
    index <- length(group_description$interpretation_limits) + 1L
    group_description$interpretation_limits <- c(
      group_description$interpretation_limits,
      list(.nail_text_mechanical_claim(
        text = paste0(
          "Only ", diag$n_included_in_prompt[[1L]], " of ",
          diag$n_non_empty[[1L]],
          " non-empty verbatims from this group were included; minority positions may be omitted."
        ),
        group_name = group_name,
        section = "interpretation_limits",
        index = index
      ))
    )
  }
  group_description
}

.nail_text_empty_claim_registry <- function() {
  data.frame(
    claim_id = character(),
    group = character(),
    source = character(),
    section = character(),
    text = character(),
    status = character(),
    support = character(),
    evidence_ids = character(),
    cited_support_n = integer(),
    included_verbatim_n = integer(),
    cited_support_fraction = numeric(),
    validation_needed = character(),
    stringsAsFactors = FALSE
  )
}

.nail_text_claim_rows <- function(group_description) {
  sections <- c(
    "core_textual_profile",
    "main_themes",
    "dominant_concerns",
    "tone_or_stance",
    "internal_variation",
    "minority_positions",
    "interpretation_limits"
  )
  rows <- list()

  for (section in sections) {
    claims <- group_description[[section]]
    if (section %in% c("core_textual_profile", "tone_or_stance")) {
      claims <- if (is.null(claims)) list() else list(claims)
    }
    if (length(claims) == 0L) next

    for (claim in claims) {
      metrics <- claim$support_metrics
      rows[[length(rows) + 1L]] <- data.frame(
        claim_id = claim$claim_id,
        group = group_description$group,
        source = "textual",
        section = section,
        text = claim$text,
        status = claim$status,
        support = claim$support,
        evidence_ids = paste(claim$evidence_ids, collapse = " | "),
        cited_support_n = as.integer(metrics$cited_support_n),
        included_verbatim_n = as.integer(metrics$included_verbatim_n),
        cited_support_fraction = as.numeric(metrics$cited_support_fraction),
        validation_needed = if (is.null(claim$validation_needed)) {
          NA_character_
        } else {
          claim$validation_needed
        },
        stringsAsFactors = FALSE
      )
    }
  }

  if (length(rows) == 0L) return(.nail_text_empty_claim_registry())
  do.call(rbind, rows)
}

.nail_text_combine_units <- function(units,
                                     all_groups,
                                     textual_evidence,
                                     analysis_scope,
                                     comparison_mode,
                                     provider,
                                     model) {
  groups <- list()
  errors <- list()

  for (unit_name in names(units)) {
    unit <- units[[unit_name]]
    if (identical(unit$parse_status, "success") &&
        is.list(unit$validated_groups)) {
      groups <- c(groups, unit$validated_groups)
    } else if (unit$parse_status %in% c("error")) {
      errors[[unit_name]] <- unit$parse_error
    }
  }

  for (group_name in all_groups) {
    if (is.null(groups[[group_name]])) {
      diag <- textual_evidence$group_diagnostics[
        textual_evidence$group_diagnostics$group == group_name,
        ,
        drop = FALSE
      ]
      reason <- if (nrow(diag) > 0L && diag$n_non_empty[[1L]] == 0L) {
        "No non-empty verbatim was available for this group."
      } else if (nrow(diag) > 0L && diag$n_included_in_prompt[[1L]] == 0L) {
        "No verbatim from this group was included in the prompt."
      } else if (length(errors) > 0L) {
        paste0("No validated textual description was available: ",
               paste(unique(unlist(errors, use.names = FALSE)), collapse = " | "))
      } else {
        "No semantic textual description was generated for this group."
      }
      groups[[group_name]] <- .nail_text_unavailable_group(group_name, reason)
    }
    groups[[group_name]] <- .nail_text_add_sampling_limit(
      groups[[group_name]],
      textual_evidence = textual_evidence
    )
  }
  groups <- groups[all_groups]

  active_units <- units[vapply(
    units,
    function(unit) isTRUE(unit$has_evidence),
    logical(1)
  )]
  statuses <- if (length(active_units) == 0L) character() else
    vapply(active_units, `[[`, character(1), "parse_status")
  n_available <- sum(vapply(
    groups,
    function(group) identical(group$availability, "available"),
    logical(1)
  ))

  status <- if (length(active_units) == 0L) {
    "no_evidence"
  } else if (all(statuses == "not_generated")) {
    "not_generated"
  } else if (n_available == length(all_groups)) {
    "success"
  } else if (n_available > 0L) {
    "partial"
  } else {
    "error"
  }

  claim_rows <- lapply(groups, .nail_text_claim_rows)
  claim_rows <- claim_rows[vapply(claim_rows, nrow, integer(1)) > 0L]
  claim_registry <- if (length(claim_rows) == 0L) {
    .nail_text_empty_claim_registry()
  } else {
    do.call(rbind, claim_rows)
  }

  out <- list(
    schema = "NaileR::textual_description",
    schema_version = "1.0.0",
    groups = groups,
    claim_registry = claim_registry,
    cross_group = NULL,
    metadata = list(
      parse_status = status,
      analysis_scope = analysis_scope,
      comparison_mode = comparison_mode,
      provider = provider,
      model = model,
      n_groups_total = as.integer(length(all_groups)),
      n_groups_available = as.integer(n_available),
      errors = errors,
      cross_group_deferred = TRUE
    )
  )
  class(out) <- c("textual_description", "list")
  out
}

.nail_text_description_to_legacy_profiles <- function(description,
                                                      analysis_scope,
                                                      comparison_mode) {
  if (is.null(description) ||
      !description$metadata$parse_status %in% c("success", "partial")) {
    return(NULL)
  }

  groups <- lapply(description$groups, function(group) {
    list(
      group = group$group,
      core_textual_profile = group$core_textual_profile,
      main_themes = group$main_themes,
      dominant_concerns = group$dominant_concerns,
      tone_or_stance = group$tone_or_stance,
      narrative_frames = list(),
      motivations = list(),
      barriers = list(),
      perceived_benefits = list(),
      social_norms = list(),
      identity_cues = list(),
      contradictions = group$internal_variation,
      minority_positions = group$minority_positions,
      representative_verbatims = group$representative_verbatims,
      tension_verbatims = group$contrastive_verbatims,
      intra_group_consistency = NULL,
      interpretation_limits = group$interpretation_limits
    )
  })

  list(
    groups = groups,
    cross_group = .textual_prep_empty_cross_group(),
    metadata = list(
      schema = "NaileR::textual_profiles_compatibility",
      source_schema = description$schema,
      analysis_scope = analysis_scope,
      comparison_mode = comparison_mode,
      groups = names(groups),
      parse_status = description$metadata$parse_status,
      cross_group_deferred = TRUE
    )
  )
}

.nail_text_run_units <- function(units,
                                 textual_evidence,
                                 context,
                                 provider,
                                 model,
                                 generate,
                                 llm_api_options) {
  if (!isTRUE(generate)) return(units)

  lapply(units, function(unit) {
    if (!isTRUE(unit$has_evidence)) return(unit)

    unit$call_attempted <- TRUE
    call_result <- tryCatch(
      .nail_structured_dispatch_call(
        prompt = unit$prompt,
        schema = unit$schema,
        provider = provider,
        model = model,
        unit_type = "textual_group_description",
        unit_data = unit$unit_data,
        options = llm_api_options
      ),
      error = function(e) list(
        content = NULL,
        elapsed_seconds = NA_real_,
        error = conditionMessage(e)
      )
    )

    unit$elapsed_seconds <- call_result$elapsed_seconds %nail_or% NA_real_
    unit$raw_response <- call_result

    if (!is.null(call_result$error)) {
      unit$parse_status <- "error"
      unit$parse_error <- call_result$error
      unit$parsed <- list(
        parse_status = "error",
        parse_error = call_result$error,
        textual_profiles = NULL,
        textual_description = NULL
      )
      return(unit)
    }

    unit$response <- call_result$content
    parsed <- .nail_text_parse_unit_response(
      text = call_result$content,
      unit_data = unit$unit_data,
      registry = textual_evidence$evidence_registry,
      context = context
    )
    unit$parse_status <- parsed$parse_status
    unit$parse_error <- parsed$parse_error
    unit$validated_groups <- parsed$groups

    unit_description <- if (identical(parsed$parse_status, "success")) {
      list(
        schema = "NaileR::textual_description_unit",
        groups = parsed$groups
      )
    } else {
      NULL
    }
    unit_profiles <- if (is.null(unit_description)) {
      NULL
    } else {
      .nail_text_description_to_legacy_profiles(
        description = list(
          schema = "NaileR::textual_description",
          groups = parsed$groups,
          metadata = list(parse_status = "success")
        ),
        analysis_scope = NA_character_,
        comparison_mode = "isolated"
      )
    }

    unit$parsed <- list(
      parse_status = parsed$parse_status,
      parse_error = parsed$parse_error,
      textual_profiles = unit_profiles,
      textual_description = unit_description
    )
    unit
  })
}

.nail_text_build_preparation_result <- function(units,
                                                textual_evidence,
                                                analysis_scope,
                                                comparison_mode,
                                                provider,
                                                model,
                                                generate,
                                                context,
                                                request,
                                                prompt_style,
                                                text_role,
                                                attach_selected_verbatims,
                                                n_central_verbatims,
                                                n_contrastive_verbatims,
                                                max_verbatim_chars,
                                                llm_api_options = list()) {
  units <- .nail_text_run_units(
    units = units,
    textual_evidence = textual_evidence,
    context = context,
    provider = provider,
    model = model,
    generate = generate,
    llm_api_options = llm_api_options
  )
  names(units) <- names(units)

  description <- .nail_text_combine_units(
    units = units,
    all_groups = names(textual_evidence$groups),
    textual_evidence = textual_evidence,
    analysis_scope = analysis_scope,
    comparison_mode = comparison_mode,
    provider = provider,
    model = model
  )
  profiles <- .nail_text_description_to_legacy_profiles(
    description = description,
    analysis_scope = analysis_scope,
    comparison_mode = comparison_mode
  )

  prompts <- if (identical(comparison_mode, "joint")) {
    units$joint$prompt
  } else {
    lapply(units, `[[`, "prompt")
  }
  responses <- if (!isTRUE(generate)) {
    NULL
  } else if (identical(comparison_mode, "joint")) {
    units$joint$response
  } else {
    lapply(units, `[[`, "response")
  }

  errors <- description$metadata$errors
  parse_error <- if (length(errors) == 0L) NULL else
    paste(unique(unlist(errors, use.names = FALSE)), collapse = " | ")
  llm_calls <- sum(vapply(
    units,
    function(unit) isTRUE(unit$call_attempted),
    logical(1)
  ))

  list(
    prompt = prompts,
    response = responses,
    parsed = list(
      parse_status = description$metadata$parse_status,
      parse_error = parse_error,
      textual_profiles = profiles,
      textual_description = description
    ),
    textual_profiles = profiles,
    textual_description = description,
    textual_evidence = textual_evidence,
    units = units,
    generation = list(
      provider = provider,
      model = model,
      generate = isTRUE(generate),
      llm_calls = as.integer(llm_calls),
      unit_status = stats::setNames(lapply(units, function(unit) {
        list(
          groups = unit$groups,
          parse_status = unit$parse_status,
          parse_error = unit$parse_error,
          elapsed_seconds = unit$elapsed_seconds
        )
      }), names(units)),
      raw_responses = stats::setNames(
        lapply(units, `[[`, "raw_response"),
        names(units)
      )
    ),
    validation = list(
      status = description$metadata$parse_status,
      errors = errors,
      claim_registry = description$claim_registry
    ),
    legacy_groups = NULL,
    metadata = list(
      analysis_scope = analysis_scope,
      comparison_mode = comparison_mode,
      provider = provider,
      model = model,
      generate = isTRUE(generate),
      context_supplied = length(context) > 0L,
      context = context,
      preparation_request = request,
      prompt_style = prompt_style,
      text_role = text_role,
      attach_selected_verbatims = attach_selected_verbatims,
      n_central_verbatims = as.integer(n_central_verbatims),
      n_tension_verbatims = as.integer(n_contrastive_verbatims),
      max_verbatim_chars = as.integer(max_verbatim_chars),
      semantic_contract = "NaileR::textual_description::1.0.0",
      cross_group_deferred = TRUE
    )
  )
}

.nail_text_complete_preparation <- function(preparation,
                                            provider,
                                            model,
                                            llm_api_options = list()) {
  if (!inherits(preparation, "nail_textual_prep")) {
    stop("`preparation` must inherit from `nail_textual_prep`.", call. = FALSE)
  }

  if (!is.null(preparation$textual_description) &&
      preparation$textual_description$metadata$parse_status %in%
        c("success", "partial")) {
    return(list(preparation = preparation, llm_calls = 0L))
  }

  units <- preparation$units
  has_new_contract <- length(units) > 0L && all(vapply(
    units,
    function(unit) !is.null(unit$schema) && !is.null(unit$unit_data),
    logical(1)
  ))
  if (!has_new_contract) {
    units <- .nail_text_build_units(
      textual_evidence = preparation$textual_evidence,
      analysis_scope = preparation$metadata$analysis_scope,
      comparison_mode = preparation$metadata$comparison_mode,
      request = preparation$metadata$preparation_request,
      context = preparation$metadata$context %nail_or% list(),
      prompt_style = preparation$metadata$prompt_style %nail_or% "detailed",
      text_role = preparation$metadata$text_role %nail_or% "responses",
      include_indicators_in_prompt = TRUE,
      n_central_verbatims = preparation$metadata$n_central_verbatims %nail_or% 2L,
      n_contrastive_verbatims = preparation$metadata$n_tension_verbatims %nail_or% 1L
    )
  }

  rebuilt <- .nail_text_build_preparation_result(
    units = units,
    textual_evidence = preparation$textual_evidence,
    analysis_scope = preparation$metadata$analysis_scope,
    comparison_mode = preparation$metadata$comparison_mode,
    provider = provider,
    model = model,
    generate = TRUE,
    context = preparation$metadata$context %nail_or% list(),
    request = preparation$metadata$preparation_request,
    prompt_style = preparation$metadata$prompt_style %nail_or% "detailed",
    text_role = preparation$metadata$text_role %nail_or% "responses",
    attach_selected_verbatims = preparation$metadata$attach_selected_verbatims %nail_or% TRUE,
    n_central_verbatims = preparation$metadata$n_central_verbatims %nail_or% 2L,
    n_contrastive_verbatims = preparation$metadata$n_tension_verbatims %nail_or% 1L,
    max_verbatim_chars = preparation$metadata$max_verbatim_chars %nail_or% 220L,
    llm_api_options = llm_api_options
  )

  preparation[names(rebuilt)] <- rebuilt
  class(preparation) <- c("nail_textual_prep", "list")
  preparation$legacy_groups <- .build_textual_prep_legacy_groups(
    result = preparation,
    attach_selected_verbatims = preparation$metadata$attach_selected_verbatims,
    n_central_verbatims = preparation$metadata$n_central_verbatims,
    n_tension_verbatims = preparation$metadata$n_tension_verbatims,
    max_verbatim_chars = preparation$metadata$max_verbatim_chars
  )
  attr(preparation, "textual_evidence") <- preparation$textual_evidence
  attr(preparation, "textual_profiles") <- preparation$textual_profiles
  attr(preparation, "textual_description") <- preparation$textual_description
  attr(preparation, "legacy_textual_prep") <- preparation$legacy_groups

  list(
    preparation = preparation,
    llm_calls = rebuilt$generation$llm_calls
  )
}
