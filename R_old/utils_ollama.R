# ---------------------------------------------------------------------------
# Ollama utilities
# ---------------------------------------------------------------------------

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

  res
}
