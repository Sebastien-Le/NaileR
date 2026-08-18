# ---------------------------------------------------------------------------
# Shared constrained structured-generation infrastructure
# ---------------------------------------------------------------------------

`%nail_or%` <- function(x, y) {
  if (is.null(x)) y else x
}

.nail_structured_json_array <- function(x) {
  as.list(as.character(x))
}

.nail_structured_assert_scalar_logical <- function(x, name) {
  if (!is.logical(x) || length(x) != 1L || is.na(x)) {
    stop(paste0("`", name, "` must be TRUE or FALSE."), call. = FALSE)
  }
  invisible(TRUE)
}

.nail_structured_assert_positive_integer <- function(x, name) {
  if (!is.numeric(x) || length(x) != 1L || is.na(x) ||
      !is.finite(x) || x != floor(x) || x < 1L) {
    stop(
      paste0("`", name, "` must be one positive integer."),
      call. = FALSE
    )
  }
  invisible(TRUE)
}

.nail_structured_resolve_gemini_key <- function(api_key = NULL) {
  if (is.character(api_key) && length(api_key) == 1L &&
      !is.na(api_key) && nzchar(api_key)) {
    return(api_key)
  }

  candidates <- c(
    Sys.getenv("NAILER_GEMINI_API_KEY", unset = ""),
    Sys.getenv("GEMINI_API_KEY", unset = ""),
    Sys.getenv("GOOGLE_API_KEY", unset = "")
  )
  candidates <- candidates[nzchar(candidates)]

  if (length(candidates) == 0L) {
    stop(
      paste(
        "No Gemini API key was found.",
        "Set NAILER_GEMINI_API_KEY, GEMINI_API_KEY, or GOOGLE_API_KEY."
      ),
      call. = FALSE
    )
  }

  candidates[[1L]]
}

.nail_structured_options <- function(options = list()) {
  if (is.null(options)) options <- list()
  if (!is.list(options)) {
    stop("Structured-generation options must be supplied as a named list.", call. = FALSE)
  }
  if (length(options) > 0L && is.null(names(options))) {
    stop("Structured-generation options must be named.", call. = FALSE)
  }

  list(
    gemini_api_key = options$gemini_api_key %nail_or% options$api_key,
    gemini_max_output_tokens = options$gemini_max_output_tokens %nail_or%
      options$max_output_tokens %nail_or% 8192L,
    gemini_thinking_level = options$gemini_thinking_level %nail_or% "low",
    ollama_url = options$ollama_url %nail_or%
      Sys.getenv("OLLAMA_HOST", unset = "http://127.0.0.1:11434"),
    ollama_num_ctx = options$ollama_num_ctx %nail_or% 32768L,
    ollama_num_predict = options$ollama_num_predict %nail_or%
      options$num_predict %nail_or% 8192L,
    timeout_seconds = options$timeout_seconds %nail_or%
      options$timeout %nail_or% 900,
    llm_call = options$.llm_call
  )
}

.nail_structured_dispatch_call <- function(
    prompt,
    schema,
    provider,
    model,
    unit_type,
    unit_data,
    options = list()
) {
  provider <- match.arg(provider, c("gemini", "ollama"))
  resolved <- .nail_structured_options(options)

  .nail_structured_assert_positive_integer(
    resolved$gemini_max_output_tokens,
    "gemini_max_output_tokens"
  )
  .nail_structured_assert_positive_integer(
    resolved$ollama_num_ctx,
    "ollama_num_ctx"
  )
  .nail_structured_assert_positive_integer(
    resolved$ollama_num_predict,
    "ollama_num_predict"
  )
  if (!is.numeric(resolved$timeout_seconds) ||
      length(resolved$timeout_seconds) != 1L ||
      is.na(resolved$timeout_seconds) ||
      !is.finite(resolved$timeout_seconds) ||
      resolved$timeout_seconds <= 0) {
    stop("`timeout_seconds` must be one positive finite numeric value.", call. = FALSE)
  }

  if (!is.null(resolved$llm_call)) {
    started <- Sys.time()
    value <- resolved$llm_call(
      prompt = prompt,
      schema = schema,
      provider = provider,
      model = model,
      unit_type = unit_type,
      unit_data = unit_data
    )
    elapsed <- as.numeric(difftime(Sys.time(), started, units = "secs"))

    if (is.character(value) && length(value) == 1L) {
      return(list(content = value, elapsed_seconds = elapsed))
    }
    if (is.list(value) && is.character(value$content) &&
        length(value$content) == 1L) {
      value$elapsed_seconds <- value$elapsed_seconds %nail_or% elapsed
      return(value)
    }
    stop(
      "`.llm_call` must return one JSON string or a list with `content`.",
      call. = FALSE
    )
  }

  if (identical(provider, "gemini")) {
    return(.nail_structured_call_gemini(
      prompt = prompt,
      schema = schema,
      model = model,
      api_key = resolved$gemini_api_key,
      max_output_tokens = resolved$gemini_max_output_tokens,
      thinking_level = resolved$gemini_thinking_level,
      timeout_seconds = resolved$timeout_seconds
    ))
  }

  .nail_structured_call_ollama(
    prompt = prompt,
    schema = schema,
    model = model,
    ollama_url = resolved$ollama_url,
    num_ctx = resolved$ollama_num_ctx,
    num_predict = resolved$ollama_num_predict,
    timeout_seconds = resolved$timeout_seconds
  )
}

.nail_structured_call_gemini <- function(
    prompt,
    schema,
    model,
    api_key,
    max_output_tokens,
    thinking_level,
    timeout_seconds
) {
  if (!requireNamespace("httr2", quietly = TRUE) ||
      !requireNamespace("jsonlite", quietly = TRUE)) {
    stop("Gemini structured generation requires `httr2` and `jsonlite`.", call. = FALSE)
  }

  api_key <- .nail_structured_resolve_gemini_key(api_key)
  endpoint <- paste0(
    "https://generativelanguage.googleapis.com/v1beta/models/",
    sub("^models/", "", model),
    ":generateContent"
  )

  generation_config <- list(
    maxOutputTokens = as.integer(max_output_tokens),
    responseMimeType = "application/json",
    responseJsonSchema = schema
  )
  if (grepl("^gemini-3", model)) {
    generation_config$thinkingConfig <- list(thinkingLevel = thinking_level)
  }

  body <- list(
    contents = list(list(
      role = "user",
      parts = list(list(text = prompt))
    )),
    generationConfig = generation_config
  )

  started <- Sys.time()
  response <- httr2::request(endpoint) |>
    httr2::req_method("POST") |>
    httr2::req_headers(
      `Content-Type` = "application/json",
      `x-goog-api-key` = api_key
    ) |>
    httr2::req_body_json(body, auto_unbox = TRUE) |>
    httr2::req_timeout(timeout_seconds) |>
    httr2::req_error(body = function(resp) httr2::resp_body_string(resp)) |>
    httr2::req_perform()

  payload <- httr2::resp_body_json(response, simplifyVector = FALSE)
  candidates <- payload$candidates
  if (!is.list(candidates) || length(candidates) == 0L) {
    stop("Gemini returned no candidate.", call. = FALSE)
  }
  parts <- candidates[[1L]]$content$parts
  if (!is.list(parts) || length(parts) == 0L) {
    stop("Gemini returned no content part.", call. = FALSE)
  }

  keep <- vapply(parts, function(part) {
    is.character(part$text) && length(part$text) == 1L &&
      nzchar(part$text) && !isTRUE(part$thought)
  }, logical(1))
  if (!any(keep)) {
    stop("Gemini returned no final JSON text.", call. = FALSE)
  }

  content <- paste0(vapply(
    parts[keep],
    function(part) part$text,
    character(1)
  ), collapse = "")

  list(
    content = content,
    payload = payload,
    http_status = httr2::resp_status(response),
    elapsed_seconds = as.numeric(difftime(Sys.time(), started, units = "secs"))
  )
}

.nail_structured_call_ollama <- function(
    prompt,
    schema,
    model,
    ollama_url,
    num_ctx,
    num_predict,
    timeout_seconds
) {
  if (!requireNamespace("httr2", quietly = TRUE) ||
      !requireNamespace("jsonlite", quietly = TRUE)) {
    stop("Ollama structured generation requires `httr2` and `jsonlite`.", call. = FALSE)
  }

  endpoint <- paste0(sub("/+$", "", ollama_url), "/api/chat")
  body <- list(
    model = model,
    messages = list(list(role = "user", content = prompt)),
    stream = FALSE,
    format = schema,
    options = list(
      temperature = 0,
      num_ctx = as.integer(num_ctx),
      num_predict = as.integer(num_predict)
    )
  )

  started <- Sys.time()
  response <- httr2::request(endpoint) |>
    httr2::req_method("POST") |>
    httr2::req_headers(`Content-Type` = "application/json") |>
    httr2::req_body_json(body, auto_unbox = TRUE) |>
    httr2::req_timeout(timeout_seconds) |>
    httr2::req_error(body = function(resp) httr2::resp_body_string(resp)) |>
    httr2::req_perform()

  payload <- httr2::resp_body_json(response, simplifyVector = FALSE)
  content <- payload$message$content
  if (!is.character(content) || length(content) != 1L || !nzchar(content)) {
    stop("Ollama returned no JSON content.", call. = FALSE)
  }

  list(
    content = content,
    payload = payload,
    http_status = httr2::resp_status(response),
    elapsed_seconds = as.numeric(difftime(Sys.time(), started, units = "secs"))
  )
}

.nail_structured_strip_fence <- function(text) {
  text <- trimws(text)
  if (!grepl("^```(?:json)?[[:space:]]*", text,
             perl = TRUE, ignore.case = TRUE)) {
    return(text)
  }
  text <- sub("^```(?:json)?[[:space:]]*", "", text,
              perl = TRUE, ignore.case = TRUE)
  text <- sub("[[:space:]]*```$", "", text, perl = TRUE)
  trimws(text)
}

.nail_structured_parse_json <- function(text) {
  if (!requireNamespace("jsonlite", quietly = TRUE)) {
    stop("Parsing requires `jsonlite`.", call. = FALSE)
  }
  if (!is.character(text) || length(text) != 1L || is.na(text) ||
      !nzchar(trimws(text))) {
    stop("The LLM response is empty.", call. = FALSE)
  }

  text <- .nail_structured_strip_fence(text)
  if (!jsonlite::validate(text)) {
    stop("The LLM response is not valid JSON.", call. = FALSE)
  }
  jsonlite::fromJSON(text, simplifyVector = FALSE)
}

.nail_structured_required_names <- function(x, required, optional = character(), path) {
  if (!is.list(x) || is.null(names(x))) {
    stop(paste0("`", path, "` must be a JSON object."), call. = FALSE)
  }
  missing <- setdiff(required, names(x))
  extra <- setdiff(names(x), c(required, optional))
  if (length(missing) > 0L) {
    stop(
      paste0("`", path, "` is missing: ", paste(missing, collapse = ", "), "."),
      call. = FALSE
    )
  }
  if (length(extra) > 0L) {
    stop(
      paste0("`", path, "` has unexpected fields: ", paste(extra, collapse = ", "), "."),
      call. = FALSE
    )
  }
  invisible(TRUE)
}

.nail_structured_as_id_vector <- function(x) {
  if (is.null(x)) return(character())
  values <- as.character(unlist(x, use.names = FALSE))
  unique(values[!is.na(values) & nzchar(values)])
}

# ---------------------------------------------------------------------------
# Shared validation for methodological-limit claims
# ---------------------------------------------------------------------------

.nail_structured_normalize_prose <- function(x) {
  x <- tolower(paste(x, collapse = " "))
  x <- gsub("[^[:alnum:]]+", " ", x, perl = TRUE)
  trimws(gsub("[[:space:]]+", " ", x, perl = TRUE))
}

.nail_structured_methodological_limit_reason <- function(text,
                                                         support,
                                                         evidence_ids = character()) {
  if (length(evidence_ids) > 0L) {
    return("must use an empty evidence_ids array because methodological limits are not evidence claims")
  }

  text_normalized <- .nail_structured_normalize_prose(text)
  support_normalized <- .nail_structured_normalize_prose(support)
  normalized_parts <- c(text_normalized, support_normalized)

  substantive_patterns <- c(
    "\\b(group|members?|respondents?|participants?)\\b.{0,60}\\b(are|appears?|seems?|tends? to|prefers?|values?|feels?|believes?|displays?|demonstrates?|shows? a|has a)\\b",
    "\\b(group s characteristics?|profile)\\b.{0,80}\\b(defined|characteri[sz]ed|rigid|flexible|open|constrained|pragmatic|engaged|knowledgeable|enthusiastic|resistant|preference|motivation|attitude|behavio[u]?r|identity|personality)\\b",
    "\\b(more|less)\\s+(rigid|flexible|open|constrained|pragmatic|engaged|knowledgeable|enthusiastic|resistant)\\b"
  )
  has_substantive_profile <- any(vapply(
    normalized_parts,
    function(part) {
      any(vapply(
        substantive_patterns,
        grepl,
        logical(1),
        x = part,
        perl = TRUE
      ))
    },
    logical(1)
  ))
  if (has_substantive_profile) {
    return(paste(
      "must not introduce a new substantive description of the group;",
      "move that content to a substantive profile section or omit it"
    ))
  }

  methodological_patterns <- c(
    "\\b(limit|limitation|scope|coverage|sampling|sampled|selection|selected|retained|available|unavailable|missing|absence|insufficient|uncertain|uncertainty)\\b",
    "\\b(cannot|can not|does not|do not|did not|not infer|not establish|not demonstrate|not measure|not measured|not observed|not available|should not be interpreted)\\b",
    "\\b(association|associations|causal|causality|prevalence|frequency|cross sectional|observational)\\b|\\b(generaliz|demograph|diagnos)[[:alnum:]]*\\b",
    "\\b(only|no|not|limited|missing|available|retained|selected)\\b.{0,50}\\b(data|evidence|observations?|rows?|verbatims?|markers?|variables?|sample)\\b",
    "\\b(data|evidence|observations?|rows?|verbatims?|markers?|variables?|sample)\\b.{0,50}\\b(only|no|not|limited|missing|available|retained|selected)\\b",
    "\\b(self reported|self report|subjective|perceptions?|recall bias|response bias|social desirability|objective realit(?:y|ies))\\b",
    "\\b(specific|particular|single)\\b.{0,50}\\b(context|domain|set of comments|corpus|group|sample)\\b",
    "\\b(may not|might not|cannot|can not)\\b.{0,70}\\b(capture|represent|reflect|apply|generalize|generalise)\\b"
  )
  has_methodological_scope <- any(vapply(
    methodological_patterns,
    grepl,
    logical(1),
    x = text_normalized,
    perl = TRUE
  ))
  if (!has_methodological_scope) {
    return(paste(
      "must state a methodological restriction such as missing measurement,",
      "sampling or coverage limits, uncertainty, non-causality,",
      "self-report limitations, or limited generalizability"
    ))
  }

  NULL
}

.nail_structured_validate_methodological_limit <- function(text,
                                                           support,
                                                           evidence_ids = character(),
                                                           path = "methodological limit") {
  reason <- .nail_structured_methodological_limit_reason(
    text = text,
    support = support,
    evidence_ids = evidence_ids
  )
  if (!is.null(reason)) {
    stop(paste0("`", path, "` ", reason, "."), call. = FALSE)
  }
  invisible(TRUE)
}
