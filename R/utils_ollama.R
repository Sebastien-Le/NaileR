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

# The two option sets are deliberately maintained here rather than inferred
# from `...` at the call site.  This gives previews and generations the same
# configuration contract and lets us distinguish an unknown option from an
# option belonging to the other provider.
.llm_option_names <- function(provider) {
  provider <- .match_llm_provider(provider)

  if (identical(provider, "ollama")) {
    return(c(
      "temperature", "top_p", "top_k", "seed",
      "system", "template", "context", "keep_alive",
      "stream", "format", "suffix", "images", "raw",
      "endpoint", "host"
    ))
  }

  c(
    "api_key", "user_agent", "base_url",
    "temperature", "top_p", "top_k", "max_output_tokens",
    "stop_sequences", "system_instruction", "safety_settings", "seed",
    "timeout", "verbose", "max_tries", "backoff_base", "backoff_cap"
  )
}

.llm_all_option_names <- function() {
  unique(c(.llm_option_names("ollama"), .llm_option_names("gemini")))
}

.validate_gemini_generation_options <- function(options) {
  if (is.null(options) || length(options) == 0L) {
    return(invisible(options))
  }

  stop_invalid <- function(name, requirement) {
    stop(
      sprintf("Gemini option `%s` %s.", name, requirement),
      call. = FALSE
    )
  }

  scalar_character <- function(value, name, allow_empty = FALSE) {
    valid <- is.character(value) && length(value) == 1L && !is.na(value)
    if (!allow_empty) valid <- valid && nzchar(value)
    if (!valid) stop_invalid(name, "must be a single non-empty character string")
  }

  scalar_logical <- function(value, name) {
    if (!is.logical(value) || length(value) != 1L || is.na(value)) {
      stop_invalid(name, "must be a single non-missing logical value")
    }
  }

  scalar_number <- function(value, name, lower = NULL, upper = NULL,
                            integer = FALSE) {
    valid <- is.numeric(value) && length(value) == 1L &&
      !is.na(value) && is.finite(value)
    if (valid && integer) valid <- value == floor(value)
    if (valid && !is.null(lower)) valid <- value >= lower
    if (valid && !is.null(upper)) valid <- value <= upper
    if (!valid) stop_invalid(name, "has an invalid numeric value or range")
  }

  if (!is.null(options$api_key)) {
    scalar_character(options$api_key, "api_key")
  }
  if (!is.null(options$user_agent)) {
    scalar_character(options$user_agent, "user_agent")
  }
  if (!is.null(options$base_url)) {
    scalar_character(options$base_url, "base_url")
  }
  if (!is.null(options$temperature)) {
    scalar_number(options$temperature, "temperature", lower = 0, upper = 2)
  }
  if (!is.null(options$top_p)) {
    scalar_number(options$top_p, "top_p", lower = 0, upper = 1)
  }
  if (!is.null(options$top_k)) {
    scalar_number(options$top_k, "top_k", lower = 1, integer = TRUE)
  }
  if (!is.null(options$max_output_tokens)) {
    scalar_number(
      options$max_output_tokens,
      "max_output_tokens",
      lower = 1,
      integer = TRUE
    )
  }
  if (!is.null(options$stop_sequences)) {
    valid <- is.character(options$stop_sequences) &&
      !anyNA(options$stop_sequences)
    if (!valid) stop_invalid("stop_sequences", "must be a character vector without NA")
  }
  if (!is.null(options$system_instruction)) {
    scalar_character(options$system_instruction, "system_instruction", allow_empty = TRUE)
  }
  if (!is.null(options$safety_settings) && !is.list(options$safety_settings)) {
    stop_invalid("safety_settings", "must be a list")
  }
  if (!is.null(options$seed)) {
    scalar_number(options$seed, "seed", integer = TRUE)
  }
  if (!is.null(options$timeout)) {
    scalar_number(options$timeout, "timeout", lower = 0)
  }
  if (!is.null(options$verbose)) {
    scalar_logical(options$verbose, "verbose")
  }
  if (!is.null(options$max_tries)) {
    scalar_number(options$max_tries, "max_tries", lower = 1, integer = TRUE)
  }
  if (!is.null(options$backoff_base)) {
    scalar_number(options$backoff_base, "backoff_base", lower = 0)
  }
  if (!is.null(options$backoff_cap)) {
    scalar_number(options$backoff_cap, "backoff_cap", lower = 0)
  }

  invisible(options)
}

.validate_llm_api_options <- function(extra_args, provider) {
  provider <- .match_llm_provider(provider)

  if (is.null(extra_args) || length(extra_args) == 0L) {
    return(invisible(list()))
  }
  if (!is.list(extra_args)) {
    stop("LLM options must be supplied as a named list.", call. = FALSE)
  }

  option_names <- names(extra_args)
  if (is.null(option_names) || anyNA(option_names) ||
      any(!nzchar(option_names))) {
    stop("All LLM options supplied through `...` must be named.", call. = FALSE)
  }
  if (anyDuplicated(option_names)) {
    stop(
      sprintf(
        "LLM option names must be unique; duplicated option(s): %s.",
        paste(unique(option_names[duplicated(option_names)]), collapse = ", ")
      ),
      call. = FALSE
    )
  }

  unknown <- setdiff(option_names, .llm_all_option_names())
  if (length(unknown) > 0L) {
    stop(
      sprintf(
        "Unknown LLM option(s): %s.",
        paste(unknown, collapse = ", ")
      ),
      call. = FALSE
    )
  }

  incompatible <- setdiff(option_names, .llm_option_names(provider))
  if (length(incompatible) > 0L) {
    stop(
      sprintf(
        "LLM option(s) %s are not compatible with provider `%s`.",
        paste(incompatible, collapse = ", "),
        provider
      ),
      call. = FALSE
    )
  }

  if (identical(provider, "gemini")) {
    .validate_gemini_generation_options(extra_args)
  }

  invisible(extra_args)
}

.default_llm_model <- function(provider) {
  provider <- .match_llm_provider(provider)
  if (identical(provider, "gemini")) "gemini-2.5-flash" else "llama3"
}

.resolve_llm_model <- function(model, provider, model_missing = FALSE) {
  if (isTRUE(model_missing) || is.null(model)) {
    return(.default_llm_model(provider))
  }
  model
}

#' Validate and return supported ollamar::generate options
#'
#' @param extra_args A named list of extra arguments.
#'
#' @return The validated named list containing compatible Ollama options.
#' @keywords internal
filter_ollama_options <- function(extra_args) {
  if (is.null(extra_args) || length(extra_args) == 0) {
    return(list())
  }
  .validate_llm_api_options(extra_args, "ollama")
  extra_args
}

#' Validate and return supported Gemini options
#'
#' @param extra_args A named list of extra arguments.
#'
#' @return The validated named list containing compatible Gemini options.
#' @keywords internal
filter_gemini_options <- function(extra_args) {
  if (is.null(extra_args) || length(extra_args) == 0) {
    return(list())
  }
  .validate_llm_api_options(extra_args, "gemini")
  extra_args
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
  .validate_llm_api_options(ollama_api_options, "ollama")

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

  res
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
  .validate_llm_api_options(gemini_api_options, "gemini")

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

  if (output == "text") {
    return(response)
  }

  data.frame(
    model = model,
    provider = "gemini",
    created_at = Sys.time(),
    response = response,
    done = TRUE,
    stringsAsFactors = FALSE
  )
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
  .validate_llm_api_options(llm_api_options, provider)

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
