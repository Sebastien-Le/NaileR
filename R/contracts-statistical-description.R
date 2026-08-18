# ---------------------------------------------------------------------------
# Structured statistical-description contract used by nail_catdes()
# ---------------------------------------------------------------------------

.nail_stat_nullable_string_schema <- function() {
  list(type = .nail_structured_json_array(c("string", "null")))
}

.nail_stat_claim_schema <- function(max_evidence_ids = 8L,
                                    min_evidence_ids = 0L) {
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
      status = list(
        type = "string",
        enum = list("expert_interpretation")
      ),
      evidence_ids = list(
        type = "array",
        items = list(type = "string"),
        minItems = as.integer(min_evidence_ids),
        maxItems = as.integer(max_evidence_ids)
      ),
      support = list(type = "string", minLength = 1L),
      validation_needed = list(type = "null")
    )
  )
}

.nail_stat_claim_array_schema <- function(max_items,
                                          max_evidence_ids = 8L,
                                          min_evidence_ids = 0L) {
  list(
    type = "array",
    items = .nail_stat_claim_schema(
      max_evidence_ids = max_evidence_ids,
      min_evidence_ids = min_evidence_ids
    ),
    minItems = 0L,
    maxItems = as.integer(max_items)
  )
}

.nail_stat_group_schema <- function(group_name,
                                    interpretation_mode,
                                    max_dominant = 4L,
                                    max_secondary = 3L,
                                    max_contrasts = 2L,
                                    max_limits = 3L,
                                    max_evidence_ids = 20L) {
  fields <- c(
    "group",
    "suggested_label",
    "core_statistical_profile",
    "dominant_markers",
    "secondary_markers",
    "internal_contrasts",
    "interpretation_limits"
  )

  label_schema <- .nail_stat_nullable_string_schema()

  list(
    type = "object",
    additionalProperties = FALSE,
    required = .nail_structured_json_array(fields),
    propertyOrdering = .nail_structured_json_array(fields),
    properties = list(
      group = list(type = "string", enum = list(group_name)),
      suggested_label = label_schema,
      core_statistical_profile = .nail_stat_claim_schema(
        max_evidence_ids = max_evidence_ids,
        min_evidence_ids = 1L
      ),
      dominant_markers = .nail_stat_claim_array_schema(
        max_dominant,
        max_evidence_ids = max_evidence_ids,
        min_evidence_ids = 1L
      ),
      secondary_markers = .nail_stat_claim_array_schema(
        max_secondary,
        max_evidence_ids = max_evidence_ids,
        min_evidence_ids = 1L
      ),
      internal_contrasts = .nail_stat_claim_array_schema(
        max_contrasts,
        max_evidence_ids = max_evidence_ids,
        min_evidence_ids = 2L
      ),
      interpretation_limits = .nail_stat_claim_array_schema(
        max_limits,
        max_evidence_ids = 0L,
        min_evidence_ids = 0L
      )
    )
  )
}

.nail_stat_records <- function(x, columns) {
  if (!is.data.frame(x) || nrow(x) == 0L) return(list())
  columns <- intersect(columns, names(x))
  rows <- lapply(seq_len(nrow(x)), function(i) {
    row <- as.list(x[i, columns, drop = FALSE])
    lapply(row, function(value) {
      if (length(value) == 0L || is.na(value[[1L]])) NULL else value[[1L]]
    })
  })
  unname(rows)
}

.nail_stat_group_data <- function(group_evidence,
                                  interpretation_mode,
                                  target_label) {
  list(
    group = group_evidence$group,
    interpretation_mode = interpretation_mode,
    target_variable = target_label,
    metrics = group_evidence$metrics,
    allowed_evidence_ids = as.character(group_evidence$selected_evidence_ids),
    qualitative_markers = .nail_stat_records(
      group_evidence$qualitative_markers,
      c(
        "evidence_id", "variable", "modality", "direction",
        "percentage_in_group", "percentage_in_modality",
        "global_percentage", "v_test", "p_value", "rank"
      )
    ),
    quantitative_markers = .nail_stat_records(
      group_evidence$quantitative_markers,
      c(
        "evidence_id", "variable", "direction", "group_mean",
        "overall_mean", "standard_deviation",
        "overall_standard_deviation", "v_test", "p_value", "rank"
      )
    )
  )
}

.nail_stat_group_prompt <- function(group_data,
                                    schema,
                                    introduction,
                                    request,
                                    prompt_style) {
  mode_rule <- if (identical(group_data$interpretation_mode, "latent")) {
    paste(
      "The group label is only an identifier.",
      "You may propose one concise suggested_label, but the evidence must determine its meaning."
    )
  } else {
    paste(
      "The group is an observed category of the target variable.",
      "Do not rename it; suggested_label must be null."
    )
  }

  detail_rule <- if (identical(prompt_style, "compact")) {
    "Keep claims concise and prioritize only the clearest markers."
  } else {
    paste(
      "Distinguish dominant from secondary markers.",
      "Use internal_contrasts only for a genuine relation between at least two distinct markers.",
      "Each internal contrast must cite at least two distinct evidence_ids; otherwise place the claim in dominant_markers or secondary_markers, or omit it."
    )
  }

  evidence_json <- jsonlite::toJSON(
    group_data,
    auto_unbox = TRUE,
    pretty = TRUE,
    null = "null",
    na = "null"
  )

  paste(
    "# ROLE",
    paste(
      "You are an expert in the interpretation of group profiles produced by",
      "FactoMineR::catdes(). You interpret associations, not causes."
    ),
    "",
    "# STUDY CONTEXT",
    introduction,
    "",
    "# ANALYTICAL TASK",
    request,
    mode_rule,
    detail_rule,
    "",
    "# TRACEABILITY RULES",
    paste(
      "- Every substantive claim must cite one or more evidence_ids shown below.",
      "- interpretation_limits must use an empty evidence_ids array and state only methodological restrictions: missing measurement, sampling or coverage limits, uncertainty, non-causality, or limited generalizability.",
      "- Never use interpretation_limits to add a group characteristic, label, rigidity/flexibility judgment, preference, motivation, attitude, or any other substantive profile claim.",
      "- The support field must explain why the cited values support a substantive claim, or why a methodological limitation applies.",
      "- Do not invent values, variables, modalities, counts, causal mechanisms, or demographic characteristics.",
      "- Positive and negative directions are both informative when present.",
      "- A marker characterizes the group relative to the full sample; it need not describe every individual.",
      "- Return only the JSON object constrained by the supplied schema.",
      sep = "\n"
    ),
    "",
    "# MECHANICAL STATISTICAL EVIDENCE",
    evidence_json,
    sep = "\n"
  )
}

.nail_stat_scalar_string <- function(x, path, allow_null = FALSE) {
  if (is.null(x) && allow_null) return(NULL)
  if (!is.character(x) || length(x) != 1L || is.na(x) || !nzchar(trimws(x))) {
    stop(paste0("`", path, "` must be one non-empty string."), call. = FALSE)
  }
  as.character(x)
}

.nail_stat_evidence_source_text <- function(group_data, evidence_ids) {
  records <- c(group_data$qualitative_markers, group_data$quantitative_markers)
  if (length(records) == 0L || length(evidence_ids) == 0L) return("")
  keep <- vapply(records, function(record) {
    id <- record$evidence_id
    is.character(id) && length(id) == 1L && !is.na(id) && id %in% evidence_ids
  }, logical(1))
  if (!any(keep)) return("")
  jsonlite::toJSON(
    records[keep],
    auto_unbox = TRUE,
    null = "null",
    na = "null"
  )
}

.nail_stat_normalize_phrase <- function(x) {
  x <- tolower(paste(x, collapse = " "))
  x <- gsub("[^[:alnum:]]+", " ", x, perl = TRUE)
  trimws(gsub("[[:space:]]+", " ", x, perl = TRUE))
}

.nail_stat_claim_mentions_record_number <- function(text, record) {
  if (!exists(".textual_prep_number_tokens", mode = "function") ||
      !exists(".textual_prep_number_value", mode = "function") ||
      !exists(".textual_prep_number_tolerance", mode = "function")) {
    return(FALSE)
  }
  claim_tokens <- .textual_prep_number_tokens(text)
  if (length(claim_tokens) == 0L) return(FALSE)
  number_fields <- setdiff(
    names(record),
    c("evidence_id", "variable", "modality", "direction", "rank", "source_row")
  )
  record_text <- jsonlite::toJSON(
    record[number_fields],
    auto_unbox = TRUE,
    null = "null",
    na = "null"
  )
  record_tokens <- .textual_prep_number_tokens(record_text)
  if (length(record_tokens) == 0L) return(FALSE)
  record_values <- vapply(
    record_tokens,
    .textual_prep_number_value,
    numeric(1)
  )
  record_values <- record_values[is.finite(record_values)]
  if (length(record_values) == 0L) return(FALSE)

  any(vapply(claim_tokens, function(token) {
    value <- .textual_prep_number_value(token)
    if (!is.finite(value)) return(FALSE)
    tolerance <- .textual_prep_number_tolerance(token, value)
    any(abs(record_values - value) <= tolerance)
  }, logical(1)))
}

.nail_stat_recover_evidence_ids <- function(text,
                                            support,
                                            evidence_ids,
                                            group_data) {
  combined <- paste(text, support, sep = "\n")
  combined_normalized <- .nail_stat_normalize_phrase(combined)
  records <- c(group_data$qualitative_markers, group_data$quantitative_markers)
  if (length(records) == 0L) return(character(0))

  recovered <- vapply(records, function(record) {
    evidence_id <- record$evidence_id
    if (!is.character(evidence_id) || length(evidence_id) != 1L ||
        is.na(evidence_id) || evidence_id %in% evidence_ids) {
      return(NA_character_)
    }
    if (grepl(evidence_id, combined, fixed = TRUE)) return(evidence_id)

    modality <- record$modality
    has_modality <- is.character(modality) && length(modality) == 1L &&
      !is.na(modality) && nzchar(trimws(modality))
    labels <- if (has_modality) modality else record$variable
    labels <- labels[vapply(
      labels,
      function(label) is.character(label) && length(label) == 1L &&
        !is.na(label) && nzchar(trimws(label)),
      logical(1)
    )]
    labels <- unique(vapply(labels, .nail_stat_normalize_phrase, character(1)))
    labels <- labels[nchar(labels) >= 3L]
    label_mentioned <- length(labels) > 0L && any(vapply(
      labels,
      grepl,
      logical(1),
      x = combined_normalized,
      fixed = TRUE
    ))
    if (label_mentioned &&
        .nail_stat_claim_mentions_record_number(combined, record)) {
      evidence_id
    } else {
      NA_character_
    }
  }, character(1))

  unique(recovered[!is.na(recovered)])
}

.nail_stat_validate_claim_safety <- function(text,
                                             support,
                                             evidence_ids,
                                             group_data,
                                             allow_methodological_language = FALSE) {
  combined <- paste(text, support, sep = "\n")
  source_text <- .nail_stat_evidence_source_text(group_data, evidence_ids)
  if (isTRUE(allow_methodological_language)) {
    source_text <- paste(
      source_text,
      jsonlite::toJSON(
        group_data$metrics,
        auto_unbox = TRUE,
        null = "null",
        na = "null"
      ),
      sep = "\n"
    )
  }

  if (!isTRUE(allow_methodological_language) &&
      exists(".textual_prep_contains_diagnostic_claim", mode = "function") &&
      .textual_prep_contains_diagnostic_claim(combined)) {
    stop("Psychological diagnoses of individuals or groups are not allowed.", call. = FALSE)
  }

  if (!isTRUE(allow_methodological_language) &&
      exists(".contextualized_contains_unqualified_causality", mode = "function") &&
      .contextualized_contains_unqualified_causality(
        combined,
        status = "expert_interpretation"
      )) {
    stop("A statistical interpretation contains an unqualified causal claim.", call. = FALSE)
  }

  number_checked_text <- if (exists(
    ".textual_prep_strip_evidence_id_numbers",
    mode = "function"
  )) {
    .textual_prep_strip_evidence_id_numbers(
      combined,
      evidence_ids = evidence_ids
    )
  } else {
    combined
  }
  if (exists(".textual_prep_claim_has_unsupported_number", mode = "function") &&
      .textual_prep_claim_has_unsupported_number(number_checked_text, source_text)) {
    stop(
      "A statistical interpretation contains a numerical statement absent from its cited evidence.",
      call. = FALSE
    )
  }

  if (!isTRUE(allow_methodological_language) &&
      exists(".textual_prep_contains_demographic_claim", mode = "function") &&
      .textual_prep_contains_demographic_claim(combined) &&
      !.textual_prep_contains_demographic_claim(source_text)) {
    stop(
      "A demographic interpretation is not supported by the cited statistical evidence.",
      call. = FALSE
    )
  }

  invisible(TRUE)
}

.nail_stat_validate_claim <- function(x,
                                      path,
                                      allowed_evidence_ids,
                                      group_data,
                                      require_evidence = TRUE,
                                      allow_methodological_language = FALSE) {
  fields <- c(
    "text", "status", "evidence_ids", "support", "validation_needed"
  )
  .nail_structured_required_names(x, fields, path = path)

  text <- .nail_stat_scalar_string(x$text, paste0(path, "$text"))
  support <- .nail_stat_scalar_string(x$support, paste0(path, "$support"))
  status <- .nail_stat_scalar_string(x$status, paste0(path, "$status"))
  if (!identical(status, "expert_interpretation")) {
    stop(paste0("`", path, "$status` must be `expert_interpretation`."), call. = FALSE)
  }

  evidence_ids <- .nail_structured_as_id_vector(x$evidence_ids)
  if (isTRUE(require_evidence) && length(evidence_ids) == 0L) {
    stop(paste0("`", path, "` must cite at least one evidence ID."), call. = FALSE)
  }
  unknown <- setdiff(evidence_ids, allowed_evidence_ids)
  if (length(unknown) > 0L) {
    stop(
      paste0(
        "`", path, "` cites unknown or inadmissible evidence IDs: ",
        paste(unknown, collapse = ", "), "."
      ),
      call. = FALSE
    )
  }

  recovered_evidence_ids <- if (isTRUE(allow_methodological_language)) {
    character(0)
  } else {
    .nail_stat_recover_evidence_ids(
      text = text,
      support = support,
      evidence_ids = evidence_ids,
      group_data = group_data
    )
  }
  evidence_ids <- unique(c(evidence_ids, recovered_evidence_ids))

  if (!is.null(x$validation_needed)) {
    stop(
      paste0(
        "`", path,
        "$validation_needed` must be null for an expert interpretation."
      ),
      call. = FALSE
    )
  }

  if (isTRUE(allow_methodological_language)) {
    .nail_structured_validate_methodological_limit(
      text = text,
      support = support,
      evidence_ids = evidence_ids,
      path = path
    )
  }

  .nail_stat_validate_claim_safety(
    text = text,
    support = support,
    evidence_ids = evidence_ids,
    group_data = group_data,
    allow_methodological_language = allow_methodological_language
  )

  list(
    text = text,
    status = status,
    evidence_ids = evidence_ids,
    evidence_ids_recovered = recovered_evidence_ids,
    support = support,
    validation_needed = x$validation_needed
  )
}

.nail_stat_validate_claim_array <- function(x,
                                            path,
                                            allowed_evidence_ids,
                                            group_data,
                                            require_evidence = TRUE,
                                            allow_methodological_language = FALSE) {
  if (is.null(x)) return(list())
  if (!is.list(x) || is.data.frame(x)) {
    stop(paste0("`", path, "` must be a JSON array."), call. = FALSE)
  }
  lapply(seq_along(x), function(i) {
    .nail_stat_validate_claim(
      x[[i]],
      path = paste0(path, "[[", i, "]]"),
      allowed_evidence_ids = allowed_evidence_ids,
      group_data = group_data,
      require_evidence = require_evidence,
      allow_methodological_language = allow_methodological_language
    )
  })
}

.nail_stat_add_claim_ids <- function(claims, group_name, section) {
  if (length(claims) == 0L) return(list())
  lapply(seq_along(claims), function(i) {
    claim <- claims[[i]]
    claim$claim_id <- paste("stat", group_name, section, i, sep = "::")
    claim$source <- "statistical"
    claim$group <- group_name
    claim$section <- section
    claim
  })
}

.nail_stat_validate_group_response <- function(parsed,
                                               group_data,
                                               interpretation_mode) {
  fields <- c(
    "group", "suggested_label", "core_statistical_profile",
    "dominant_markers", "secondary_markers", "internal_contrasts",
    "interpretation_limits"
  )
  .nail_structured_required_names(parsed, fields, path = "statistical_description")

  group_name <- .nail_stat_scalar_string(parsed$group, "statistical_description$group")
  if (!identical(group_name, group_data$group)) {
    stop("The generated group does not match the requested group.", call. = FALSE)
  }

  suggested_label <- if (identical(interpretation_mode, "latent")) {
    .nail_stat_scalar_string(
      parsed$suggested_label,
      "statistical_description$suggested_label",
      allow_null = TRUE
    )
  } else {
    if (!is.null(parsed$suggested_label)) {
      stop("`suggested_label` must be null in standard mode.", call. = FALSE)
    }
    NULL
  }

  allowed <- group_data$allowed_evidence_ids
  core <- .nail_stat_validate_claim(
    parsed$core_statistical_profile,
    "statistical_description$core_statistical_profile",
    allowed,
    group_data = group_data,
    require_evidence = TRUE
  )
  dominant <- .nail_stat_validate_claim_array(
    parsed$dominant_markers,
    "statistical_description$dominant_markers",
    allowed,
    group_data = group_data,
    require_evidence = TRUE
  )
  secondary <- .nail_stat_validate_claim_array(
    parsed$secondary_markers,
    "statistical_description$secondary_markers",
    allowed,
    group_data = group_data,
    require_evidence = TRUE
  )
  contrasts <- .nail_stat_validate_claim_array(
    parsed$internal_contrasts,
    "statistical_description$internal_contrasts",
    allowed,
    group_data = group_data,
    require_evidence = TRUE
  )
  is_genuine_contrast <- vapply(
    contrasts,
    function(claim) length(unique(claim$evidence_ids)) >= 2L,
    logical(1)
  )
  reclassified_contrasts <- contrasts[!is_genuine_contrast]
  contrasts <- contrasts[is_genuine_contrast]
  normalization_warnings <- character(0)
  if (length(reclassified_contrasts) > 0L) {
    secondary <- c(secondary, reclassified_contrasts)
    normalization_warnings <- paste0(
      length(reclassified_contrasts),
      " one-marker internal contrast claim(s) were reclassified as secondary markers."
    )
  }
  limits <- .nail_stat_validate_claim_array(
    parsed$interpretation_limits,
    "statistical_description$interpretation_limits",
    allowed,
    group_data = group_data,
    require_evidence = FALSE,
    allow_methodological_language = TRUE
  )
  all_claims <- c(list(core), dominant, secondary, contrasts, limits)
  n_recovered <- sum(vapply(
    all_claims,
    function(claim) length(claim$evidence_ids_recovered %nail_or% character(0)),
    integer(1)
  ))
  if (n_recovered > 0L) {
    normalization_warnings <- c(
      normalization_warnings,
      paste0(
        n_recovered,
        " omitted evidence ID(s) were recovered mechanically from marker labels and values."
      )
    )
  }

  list(
    group = group_name,
    suggested_label = suggested_label,
    normalization_warnings = normalization_warnings,
    core_statistical_profile = .nail_stat_add_claim_ids(
      list(core), group_name, "core_statistical_profile"
    )[[1L]],
    dominant_markers = .nail_stat_add_claim_ids(
      dominant, group_name, "dominant_markers"
    ),
    secondary_markers = .nail_stat_add_claim_ids(
      secondary, group_name, "secondary_markers"
    ),
    internal_contrasts = .nail_stat_add_claim_ids(
      contrasts, group_name, "internal_contrasts"
    ),
    interpretation_limits = .nail_stat_add_claim_ids(
      limits, group_name, "interpretation_limits"
    )
  )
}

.nail_stat_parse_group_response <- function(text,
                                            group_data,
                                            interpretation_mode) {
  tryCatch({
    parsed <- .nail_structured_parse_json(text)
    analysis <- .nail_stat_validate_group_response(
      parsed,
      group_data = group_data,
      interpretation_mode = interpretation_mode
    )
    list(
      parse_status = "success",
      parse_error = NULL,
      analysis = analysis
    )
  }, error = function(e) {
    list(
      parse_status = "error",
      parse_error = conditionMessage(e),
      analysis = NULL
    )
  })
}


.nail_stat_empty_claim_registry <- function() {
  data.frame(
    claim_id = character(),
    group = character(),
    source = character(),
    section = character(),
    text = character(),
    status = character(),
    support = character(),
    evidence_ids = character(),
    evidence_ids_recovered = character(),
    validation_needed = character(),
    stringsAsFactors = FALSE
  )
}

.nail_stat_claim_rows <- function(group_analysis) {
  sections <- c(
    "core_statistical_profile", "dominant_markers", "secondary_markers",
    "internal_contrasts", "interpretation_limits"
  )
  rows <- list()
  for (section in sections) {
    claims <- group_analysis[[section]]
    if (identical(section, "core_statistical_profile")) claims <- list(claims)
    if (length(claims) == 0L) next
    for (claim in claims) {
      rows[[length(rows) + 1L]] <- data.frame(
        claim_id = claim$claim_id,
        group = group_analysis$group,
        source = "statistical",
        section = section,
        text = claim$text,
        status = claim$status,
        support = claim$support,
        evidence_ids = paste(claim$evidence_ids, collapse = " | "),
        evidence_ids_recovered = paste(
          claim$evidence_ids_recovered %nail_or% character(0),
          collapse = " | "
        ),
        validation_needed = if (is.null(claim$validation_needed)) NA_character_ else claim$validation_needed,
        stringsAsFactors = FALSE
      )
    }
  }
  if (length(rows) == 0L) {
    return(.nail_stat_empty_claim_registry())
  }
  do.call(rbind, rows)
}

.nail_stat_combine_units <- function(units,
                                     interpretation_mode,
                                     target_label,
                                     provider,
                                     model) {
  groups <- list()
  claim_rows <- list()
  errors <- list()

  for (group_name in names(units)) {
    unit <- units[[group_name]]
    if (identical(unit$parse_status, "success")) {
      groups[[group_name]] <- unit$parsed
      claim_rows[[length(claim_rows) + 1L]] <- .nail_stat_claim_rows(unit$parsed)
    } else if (!identical(unit$parse_status, "not_applicable")) {
      errors[[group_name]] <- unit$parse_error
    }
  }

  registry <- if (length(claim_rows) == 0L) {
    .nail_stat_empty_claim_registry()
  } else {
    do.call(rbind, claim_rows)
  }

  eligible_units <- units[vapply(
    units,
    function(x) !identical(x$parse_status, "not_applicable"),
    logical(1)
  )]
  n_expected <- length(eligible_units)

  status <- if (n_expected == 0L) {
    "not_applicable"
  } else if (length(groups) == 0L) {
    if (all(vapply(
      eligible_units,
      function(x) identical(x$parse_status, "not_generated"),
      logical(1)
    ))) {
      "not_generated"
    } else {
      "error"
    }
  } else if (length(groups) == n_expected) {
    "success"
  } else {
    "partial"
  }

  out <- list(
    schema = "NaileR::statistical_description",
    schema_version = "1.0.0",
    target_variable = target_label,
    interpretation_mode = interpretation_mode,
    groups = groups,
    claim_registry = registry,
    metadata = list(
      parse_status = status,
      provider = provider,
      model = model,
      n_groups_total = as.integer(length(units)),
      n_groups_requested = as.integer(n_expected),
      n_groups_validated = as.integer(length(groups)),
      errors = errors
    )
  )
  class(out) <- c("statistical_description", "list")
  out
}


.nail_catdes_prompt_view <- function(units) {
  prompts <- lapply(units, function(unit) unit$prompt)
  stats::setNames(prompts, names(units))
}

.nail_catdes_validation_view <- function(description, units) {
  group_status <- data.frame(
    group = names(units),
    eligible = vapply(units, function(unit) isTRUE(unit$eligible), logical(1)),
    parse_status = vapply(
      units,
      function(unit) {
        status <- unit$parse_status
        if (is.null(status) || length(status) == 0L) NA_character_ else as.character(status[[1L]])
      },
      character(1)
    ),
    parse_error = vapply(
      units,
      function(unit) {
        error <- unit$parse_error
        if (is.null(error) || length(error) == 0L) NA_character_ else as.character(error[[1L]])
      },
      character(1)
    ),
    stringsAsFactors = FALSE
  )

  list(
    status = description$metadata$parse_status,
    claim_registry = description$claim_registry,
    groups = group_status,
    errors = description$metadata$errors
  )
}

.nail_catdes_report_view <- function(description) {
  list(
    target_variable = description$target_variable,
    interpretation_mode = description$interpretation_mode,
    availability = description$metadata$parse_status,
    groups = description$groups,
    claim_registry = description$claim_registry
  )
}

.nail_catdes_structured <- function(
    interpretation_evidence,
    statistical_profiles,
    catdes_result,
    catdes_settings,
    introduction,
    request,
    interpretation_mode,
    prompt_style,
    provider,
    model,
    generate,
    target_label,
    llm_api_options
) {
  units <- stats::setNames(
    vector("list", length(interpretation_evidence$groups)),
    names(interpretation_evidence$groups)
  )

  for (group_name in names(interpretation_evidence$groups)) {
    group_evidence <- interpretation_evidence$groups[[group_name]]
    eligible <- identical(group_evidence$status, "ready")
    group_data <- .nail_stat_group_data(
      group_evidence,
      interpretation_mode = interpretation_mode,
      target_label = target_label
    )
    schema <- .nail_stat_group_schema(
      group_name = group_name,
      interpretation_mode = interpretation_mode,
      max_evidence_ids = max(1L, length(group_data$allowed_evidence_ids))
    )
    prompt <- .nail_stat_group_prompt(
      group_data = group_data,
      schema = schema,
      introduction = introduction,
      request = request,
      prompt_style = prompt_style
    )

    unit <- list(
      unit_type = "statistical_group_description",
      group = group_name,
      eligible = eligible,
      prompt = if (eligible) prompt else NULL,
      schema = if (eligible) schema else NULL,
      response = NULL,
      parsed = NULL,
      parse_status = if (!eligible) {
        "not_applicable"
      } else if (generate) {
        "pending"
      } else {
        "not_generated"
      },
      parse_error = if (eligible) NULL else paste0(
        "No selected statistical evidence was available for group '",
        group_name, "'."
      ),
      elapsed_seconds = NA_real_
    )

    if (isTRUE(generate) && isTRUE(eligible)) {
      call_result <- tryCatch(
        .nail_structured_dispatch_call(
          prompt = prompt,
          schema = schema,
          provider = provider,
          model = model,
          unit_type = "statistical_group_description",
          unit_data = group_data,
          options = llm_api_options
        ),
        error = function(e) list(
          content = NULL,
          elapsed_seconds = NA_real_,
          error = conditionMessage(e)
        )
      )
      unit$elapsed_seconds <- call_result$elapsed_seconds %nail_or% NA_real_
      if (!is.null(call_result$error)) {
        unit$parse_status <- "error"
        unit$parse_error <- call_result$error
      } else {
        unit$response <- call_result$content
        parsed <- .nail_stat_parse_group_response(
          text = call_result$content,
          group_data = group_data,
          interpretation_mode = interpretation_mode
        )
        unit$parsed <- parsed$analysis
        unit$parse_status <- parsed$parse_status
        unit$parse_error <- parsed$parse_error
      }
    }

    units[[group_name]] <- unit
  }

  description <- .nail_stat_combine_units(
    units = units,
    interpretation_mode = interpretation_mode,
    target_label = target_label,
    provider = provider,
    model = model
  )

  prompt <- .nail_catdes_prompt_view(units)
  structured_llm_calls <- as.integer(sum(vapply(
    units,
    function(unit) !is.null(unit$response),
    logical(1)
  )))

  preparation <- list(
    statistical_profiles = statistical_profiles,
    interpretation_evidence = interpretation_evidence,
    catdes_result = catdes_result
  )

  generation <- list(
    requested = isTRUE(generate),
    provider = provider,
    model = model,
    llm_calls = structured_llm_calls,
    units = units
  )

  validation <- .nail_catdes_validation_view(description, units)
  report <- .nail_catdes_report_view(description)

  metadata <- catdes_settings
  metadata$return_format <- "structured"
  metadata$semantic_status <- description$metadata$parse_status
  metadata$structured_llm_calls <- structured_llm_calls

  result <- list(
    preparation = preparation,
    prompt = prompt,
    statistical_description = description,
    generation = generation,
    validation = validation,
    report = report,
    metadata = metadata,

    # Compatibility aliases retained for existing code.
    units = units,
    statistical_profiles = statistical_profiles,
    interpretation_evidence = interpretation_evidence,
    catdes_result = catdes_result,
    legacy_output = NULL
  )
  class(result) <- c("nail_catdes", "list")
  attr(result, "statistical_profiles") <- statistical_profiles
  attr(result, "interpretation_evidence") <- interpretation_evidence
  attr(result, "statistical_description") <- description
  if (!is.null(catdes_result)) attr(result, "catdes_result") <- catdes_result
  attr(result, "catdes_settings") <- result$metadata
  result
}
