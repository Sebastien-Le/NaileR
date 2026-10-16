# ---------------------------------------------------------------------------
# LLM utilities
# ---------------------------------------------------------------------------

#' Match an LLM provider
#'
#' @param provider Provider name. Currently supports `"ollama"` and `"gemini"`.
#'
#' @return A single provider name.
#' @keywords internal
.match_llm_provider <- function(provider = c("ollama", "gemini")) {
  match.arg(provider)
}

#' Filter supported ollamar::generate options
#'
#' @param extra_args A named list of extra arguments.
#'
#' @return A filtered named list containing only supported Ollama options.
#' @keywords internal
filter_ollama_options <- function(extra_args) {
  if (is.null(extra_args) || length(extra_args) == 0) {
    return(list())
  }
  if (is.null(names(extra_args))) {
    return(list())
  }

  valid_ollama_opts <- c(
    "temperature", "top_p", "top_k", "seed",
    "system", "template", "context", "keep_alive",
    "stream", "format"
  )

  extra_args[names(extra_args) %in% valid_ollama_opts]
}

#' Filter supported Gemini options
#'
#' @param extra_args A named list of extra arguments.
#'
#' @return A filtered named list containing only supported Gemini options.
#' @keywords internal
filter_gemini_options <- function(extra_args) {
  if (is.null(extra_args) || length(extra_args) == 0) {
    return(list())
  }
  if (is.null(names(extra_args))) {
    return(list())
  }

  valid_gemini_opts <- c(
    "api_key", "user_agent", "base_url",
    "temperature", "top_p", "top_k", "max_output_tokens",
    "stop_sequences", "system_instruction", "safety_settings", "seed",
    "timeout", "verbose", "max_tries", "backoff_base", "backoff_cap"
  )

  extra_args[names(extra_args) %in% valid_gemini_opts]
}

#' Base wrapper around ollamar::generate
#'
#' @param model Model name.
#' @param prompt Prompt string.
#' @param output Output format for ollamar::generate.
#' @param ollama_api_options Named list of additional supported options.
#'
#' @return Result returned by ollamar::generate.
#' @keywords internal
.call_ollama_base <- function(model, prompt, output = "df", ollama_api_options = list()) {
  if (!is.character(model) || length(model) != 1 || is.na(model) || !nzchar(model)) {
    stop("`model` must be a single non-empty character string.", call. = FALSE)
  }
  if (!is.character(prompt) || length(prompt) != 1 || is.na(prompt) || !nzchar(prompt)) {
    stop("`prompt` must be a single non-empty character string.", call. = FALSE)
  }

  call_args <- c(
    list(
      model = model,
      prompt = prompt,
      output = output
    ),
    filter_ollama_options(ollama_api_options)
  )

  res <- tryCatch(
    do.call(ollamar::generate, call_args),
    error = function(e) {
      stop(paste("Ollama API call failed:", conditionMessage(e)), call. = FALSE)
    }
  )

  if (output == "df" && is.data.frame(res) && "response" %in% names(res)) {
    if (length(res$response) == 0 || all(is.na(res$response))) {
      stop("Ollama API call returned an empty response.", call. = FALSE)
    }
  }

  ollama_record <- list(
    call_id = .nail_usage_next_id(),
    provider = "ollama",
    model_requested = model,
    model_version = if (is.data.frame(res) && "model" %in% names(res)) as.character(res$model[[1L]]) else NA_character_,
    input_tokens = if (is.data.frame(res) && "prompt_eval_count" %in% names(res)) as.numeric(res$prompt_eval_count[[1L]]) else NA_real_,
    output_tokens = if (is.data.frame(res) && "eval_count" %in% names(res)) as.numeric(res$eval_count[[1L]]) else NA_real_,
    thinking_tokens = NA_real_,
    cached_input_tokens = NA_real_,
    total_tokens_reported = if (is.data.frame(res) && "prompt_eval_count" %in% names(res) && "eval_count" %in% names(res)) as.numeric(res$prompt_eval_count[[1L]] + res$eval_count[[1L]]) else NA_real_,
    duration_seconds = if (is.data.frame(res) && "total_duration" %in% names(res)) as.numeric(res$total_duration[[1L]]) / 1e9 else NA_real_,
    load_duration_seconds = if (is.data.frame(res) && "load_duration" %in% names(res)) as.numeric(res$load_duration[[1L]]) / 1e9 else NA_real_,
    prompt_eval_duration_seconds = if (is.data.frame(res) && "prompt_eval_duration" %in% names(res)) as.numeric(res$prompt_eval_duration[[1L]]) / 1e9 else NA_real_,
    eval_duration_seconds = if (is.data.frame(res) && "eval_duration" %in% names(res)) as.numeric(res$eval_duration[[1L]]) / 1e9 else NA_real_,
    http_attempts = 1L,
    finish_reason = if (is.data.frame(res) && "done_reason" %in% names(res)) as.character(res$done_reason[[1L]]) else NA_character_,
    http_status = NA_integer_,
    generation_status = .ollama_generation_status(res)
  )
  res <- .nail_usage_attach(res, ollama_record)

  res
}


.ollama_generation_status <- function(result) {
  has_reason <- is.data.frame(result) &&
    "done_reason" %in% names(result) &&
    length(result$done_reason) > 0L &&
    !is.na(result$done_reason[[1L]]) &&
    nzchar(as.character(result$done_reason[[1L]]))
  if (has_reason) {
    reason <- tolower(as.character(result$done_reason[[1L]]))
    if (identical(reason, "length")) return("interrupted")
    if (identical(reason, "stop")) return("completed")
    return("other_finished")
  }

  has_done <- is.data.frame(result) &&
    "done" %in% names(result) &&
    length(result$done) > 0L &&
    !is.na(result$done[[1L]])
  if (has_done && isTRUE(as.logical(result$done[[1L]]))) {
    return("completed")
  }
  "unknown"
}

#' Base wrapper around Google Gemini
#'
#' @param model Gemini model name.
#' @param prompt Prompt string.
#' @param output Output format: `"text"` or `"df"`.
#' @param gemini_api_options Named list of additional supported Gemini options.
#'
#' @return A character scalar if `output = "text"`; otherwise a small data frame
#'   with a `response` column, compatible with NaileR's existing LLM workflow.
#' @keywords internal
.call_gemini_base <- function(model, prompt, output = "df", gemini_api_options = list()) {
  if (!is.character(model) || length(model) != 1 || is.na(model) || !nzchar(model)) {
    stop("`model` must be a single non-empty character string.", call. = FALSE)
  }
  if (!is.character(prompt) || length(prompt) != 1 || is.na(prompt) || !nzchar(prompt)) {
    stop("`prompt` must be a single non-empty character string.", call. = FALSE)
  }
  if (!output %in% c("df", "text")) {
    stop("`output` must be either 'df' or 'text' for Gemini calls.", call. = FALSE)
  }

  call_args <- c(
    list(
      prompt = prompt,
      model = model
    ),
    filter_gemini_options(gemini_api_options)
  )

  response <- tryCatch(
    do.call(gemini_generate, call_args),
    error = function(e) {
      stop(paste("Gemini API call failed:", conditionMessage(e)), call. = FALSE)
    }
  )

  if (!is.character(response) || length(response) != 1 || is.na(response) || !nzchar(response)) {
    stop("Gemini API call returned an empty response.", call. = FALSE)
  }

  usage <- attr(response, "nail_usage", exact = TRUE)

  if (output == "text") {
    return(response)
  }

  out <- data.frame(
    model = model,
    provider = "gemini",
    created_at = Sys.time(),
    response = response,
    done = TRUE,
    stringsAsFactors = FALSE
  )
  .nail_usage_attach(out, usage)
}

#' Base provider-dispatching LLM wrapper
#'
#' @description
#' This is the single internal entry point for all NaileR functions that call a
#' text-generation model. Public functions should pass their `provider`, `model`,
#' prompt, output type and extra model options here instead of calling a provider
#' directly.
#'
#' @param provider LLM backend, either `"ollama"` or `"gemini"`.
#' @param model Model name for the selected provider.
#' @param prompt Prompt string.
#' @param output Output format expected by the caller: `"df"` or `"text"`.
#' @param llm_api_options Named list of additional provider-specific options.
#'
#' @return Provider response in the requested output format.
#' @keywords internal
.call_llm_base <- function(provider = c("ollama", "gemini"),
                           model,
                           prompt,
                           output = "df",
                           llm_api_options = list()) {
  provider <- .match_llm_provider(provider)

  switch(
    provider,
    ollama = .call_ollama_base(
      model = model,
      prompt = prompt,
      output = output,
      ollama_api_options = llm_api_options
    ),
    gemini = .call_gemini_base(
      model = model,
      prompt = prompt,
      output = output,
      gemini_api_options = llm_api_options
    )
  )
}
