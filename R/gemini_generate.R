#' Generate text with Google Gemini (Generative Language API) - robust w/ retries
#'
#' @description
#' Minimal wrapper around the Generative Language API
#' `:generateContent` endpoint for text prompts, with retries,
#' exponential backoff, and clearer errors.
#'
#' @param prompt Character scalar. The user prompt (plain text).
#' @param model Character scalar. Gemini model id (e.g., "gemini-2.5-flash",
#'   "gemini-2.5-pro"). You may also pass "models/..." and it will be normalized.
#' @param api_key Character scalar. API key. Defaults to env var
#'   `GEMINI_API_KEY`.
#' @param user_agent Character scalar for the HTTP User-Agent header.
#'   Default: "EnTraineR/0.9.0 (https://github.com/Sebastien-Le/EnTraineR)".
#' @param base_url Character scalar. API base URL.
#'   Default: "https://generativelanguage.googleapis.com/v1beta".
#' @param temperature Optional numeric, range 0 to 2. Sampling temperature.
#' @param top_p Optional numeric, range 0 to 1. Nucleus sampling.
#' @param top_k Optional integer >= 1. Top-k sampling.
#' @param max_output_tokens Optional integer > 0. Maximum tokens in response.
#' @param stop_sequences Optional character vector of stop strings.
#' @param system_instruction Optional character scalar with a system instruction.
#' @param safety_settings Optional list passed as-is to the API (advanced).
#' @param seed Optional integer seed for deterministic sampling (where supported).
#' @param timeout Numeric seconds for the HTTP request timeout (default 120).
#' @param verbose Logical; if TRUE, prints the resolved URL and retry notices.
#' @param max_tries Integer. Maximum attempts per call (default 5).
#' @param backoff_base Numeric. Initial backoff seconds (default 0.8).
#' @param backoff_cap Numeric. Maximum backoff seconds (default 8).
#'
#' @details
#' The function retries on common transient failures (network timeouts,
#' HTTP 429, HTTP 5xx). Backoff is exponential with jitter and capped by
#' `backoff_cap`. The first successful candidate's text is returned.
#'
#' @return Character scalar with the first candidate's text. If no text is
#' returned, an informative error is thrown (finish reason or safety block).
#'   Successful responses carry internal usage metadata. Their
#'   `generation_status` is `completed` for `STOP`, `interrupted` for
#'   `MAX_TOKENS`, `safety_blocked` for `SAFETY`, `recitation_blocked` for
#'   `RECITATION`, `other_finished` for another explicit finish reason, and
#'   `unknown` when the finish reason is absent.
#'
#' @examples
#' \dontrun{
#' Sys.setenv(GEMINI_API_KEY = "YOUR_KEY")
#' gemini_generate(
#'   prompt = "Say hello in one short sentence.",
#'   model  = "gemini-2.5-flash",
#'   verbose = TRUE
#' )
#' }
#'
#' @importFrom httr2 request req_url_query req_user_agent req_headers
#' @importFrom httr2 req_body_json req_perform resp_body_json req_timeout
#' @importFrom stats runif
#' @export
gemini_generate <- function(
    prompt,
    model = "gemini-2.5-flash",
    api_key = Sys.getenv("GEMINI_API_KEY"),
    user_agent = "EnTraineR/0.9.0 (https://github.com/Sebastien-Le/EnTraineR)",
    base_url = "https://generativelanguage.googleapis.com/v1beta",
    temperature = NULL,
    top_p = NULL,
    top_k = NULL,
    max_output_tokens = NULL,
    stop_sequences = NULL,
    system_instruction = NULL,
    safety_settings = NULL,
    seed = NULL,
    timeout = 120,                 # <- longer default
    verbose = FALSE,
    max_tries = 5,                 # <- new
    backoff_base = 0.8,            # <- new
    backoff_cap  = 8               # <- new
) {
  started_at <- Sys.time()
  # ---- Guardrails ------------------------------------------------------------
  if (!nzchar(api_key)) {
    stop("Set GEMINI_API_KEY env var first, e.g. Sys.setenv(GEMINI_API_KEY = 'YOUR_KEY')")
  }
  if (length(prompt) != 1L || !nzchar(prompt)) {
    stop("`prompt` must be a non-empty character scalar.")
  }

  # Normalize model id: accept "models/xxx" or "xxx"
  model_id <- sub("^models/", "", model)

  # Endpoint
  url <- sprintf("%s/models/%s:generateContent", base_url, model_id)
  if (isTRUE(verbose)) message("POST ", url)

  # Generation config (only non-NULL entries)
  gen_cfg <- Filter(Negate(is.null), list(
    temperature     = temperature,
    topP            = top_p,
    topK            = top_k,
    maxOutputTokens = max_output_tokens,
    stopSequences   = stop_sequences,
    seed            = seed
  ))

  # Body
  body <- list(
    contents = list(list(
      role  = "user",
      parts = list(list(text = as.character(prompt)))
    ))
  )
  if (length(gen_cfg)) body$generationConfig <- gen_cfg
  if (!is.null(system_instruction)) {
    body$systemInstruction <- list(
      role  = "system",
      parts = list(list(text = as.character(system_instruction)))
    )
  }
  if (!is.null(safety_settings)) body$safetySettings <- safety_settings

  # Build request
  req <- httr2::request(url) |>
    httr2::req_url_query(key = api_key) |>
    httr2::req_user_agent(user_agent) |>
    httr2::req_headers(`Content-Type` = "application/json") |>
    httr2::req_body_json(body, auto_unbox = TRUE) |>
    httr2::req_timeout(timeout)

  # ---- Retry loop ------------------------------------------------------------
  attempt <- 1L
  last_err <- NULL
  while (attempt <= max_tries) {
    j <- NULL
    # Try request
    ok <- FALSE
    resp <- NULL
    tryCatch({
      resp <- httr2::req_perform(req)
      # If server returns non-2xx, httr2 throws; otherwise parse JSON:
      j <- httr2::resp_body_json(resp)
      ok <- TRUE
    }, error = function(e) {
      last_err <<- conditionMessage(e)
    })

    # Success: parse and return
    if (ok) {
      parsed <- .gemini_parse_response(
        response = j,
        model = model,
        started_at = started_at,
        attempt = attempt,
        temperature = temperature,
        top_p = top_p,
        max_output_tokens = max_output_tokens,
        http_status = 200L
      )
      out <- parsed$text
      attr(out, "nail_usage") <- parsed$usage
      return(out)
    }

    # Not ok: decide if retryable
    # Timeouts, transient network errors, 429, 5xx: retry
    retryable <- FALSE
    if (!is.null(last_err)) {
      # httr2 errors include HTTP status when available; curl timeouts have this text:
      if (grepl("Timeout was reached", last_err, fixed = TRUE)) retryable <- TRUE
      if (grepl("HTTP 429", last_err, fixed = TRUE)) retryable <- TRUE
      if (grepl("HTTP 5\\d\\d", last_err)) retryable <- TRUE
      if (grepl("Failed to perform HTTP request", last_err, fixed = TRUE)) retryable <- TRUE
    }

    if (!retryable || attempt == max_tries) {
      stop(sprintf("Request failed before completion after %d attempt(s): %s",
                   attempt, if (is.null(last_err)) "<unknown>" else last_err))
    }

    # Backoff with jitter
    wait <- min(backoff_cap, backoff_base * (2^(attempt - 1)))
    wait <- wait * stats::runif(1, 0.8, 1.25)
    if (isTRUE(verbose)) message(sprintf("Retrying in %.2fs (attempt %d/%d) ...",
                                         wait, attempt + 1L, max_tries))
    Sys.sleep(wait)
    attempt <- attempt + 1L
  }

  # Should not reach here
  stop("Unexpected error in gemini_generate().")
}


# Map the provider's finish reason to a diagnostic status without treating an
# absent reason as successful.
.gemini_generation_status <- function(finish_reason) {
  if (is.null(finish_reason) || length(finish_reason) == 0L ||
      is.na(finish_reason[[1L]]) || !nzchar(as.character(finish_reason[[1L]]))) {
    return("unknown")
  }

  switch(
    toupper(as.character(finish_reason[[1L]])),
    STOP = "completed",
    MAX_TOKENS = "interrupted",
    SAFETY = "safety_blocked",
    RECITATION = "recitation_blocked",
    "other_finished"
  )
}


# Parse an already decoded Gemini response. Keeping this pure response-layer
# helper separate makes recorded HTTP JSON replayable without network access.
.gemini_parse_response <- function(response,
                                   model,
                                   started_at = Sys.time(),
                                   attempt = 1L,
                                   temperature = NULL,
                                   top_p = NULL,
                                   max_output_tokens = NULL,
                                   http_status = 200L) {
  cand <- tryCatch(response$candidates, error = function(e) NULL)
  if (is.null(cand) || length(cand) < 1L) {
    fr <- tryCatch(response$candidates[[1]]$finishReason, error = function(e) NULL)
    sft <- tryCatch(response$promptFeedback$safetyRatings, error = function(e) NULL)
    if (!is.null(fr)) stop(sprintf("No content returned. finishReason: %s", as.character(fr)))
    if (!is.null(sft)) stop("No content returned. Likely blocked by safety settings.")
    stop("No content returned. Empty candidates.")
  }

  c1 <- cand[[1L]]
  parts <- tryCatch(c1$content$parts, error = function(e) NULL)
  fr <- tryCatch(c1$finishReason, error = function(e) NULL)
  if (is.null(parts) || !length(parts)) {
    stop(sprintf(
      "Candidate has no parts. finishReason: %s",
      if (is.null(fr)) "unknown" else as.character(fr)
    ))
  }

  texts <- vapply(
    parts,
    function(p) as.character(if (is.null(p$text)) "" else p$text),
    character(1)
  )
  out <- paste(texts[nzchar(texts)], collapse = "")
  if (!nzchar(out)) {
    stop(sprintf(
      "Empty text in first candidate. finishReason: %s",
      if (is.null(fr)) "unknown" else as.character(fr)
    ))
  }

  usage_metadata <- response$usageMetadata
  usage <- list(
    call_id = .nail_usage_next_id(),
    provider = "gemini",
    model_requested = model,
    model_version = if (is.null(response$modelVersion)) NA_character_ else as.character(response$modelVersion),
    started_at = started_at,
    input_tokens = if (is.null(usage_metadata$promptTokenCount)) NA_real_ else as.numeric(usage_metadata$promptTokenCount),
    output_tokens = if (is.null(usage_metadata$candidatesTokenCount)) NA_real_ else as.numeric(usage_metadata$candidatesTokenCount),
    thinking_tokens = if (is.null(usage_metadata$thoughtsTokenCount)) NA_real_ else as.numeric(usage_metadata$thoughtsTokenCount),
    cached_input_tokens = if (is.null(usage_metadata$cachedContentTokenCount)) NA_real_ else as.numeric(usage_metadata$cachedContentTokenCount),
    total_tokens_reported = if (is.null(usage_metadata$totalTokenCount)) NA_real_ else as.numeric(usage_metadata$totalTokenCount),
    duration_seconds = as.numeric(difftime(Sys.time(), started_at, units = "secs")),
    http_attempts = attempt,
    finish_reason = if (is.null(fr)) NA_character_ else as.character(fr),
    http_status = http_status,
    generation_status = .gemini_generation_status(fr),
    temperature = temperature,
    top_p = top_p,
    max_output_tokens = max_output_tokens
  )

  list(text = out, usage = usage)
}
