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
  call_args <- c(
    list(
      model = model,
      prompt = prompt,
      output = output
    ),
    ollama_api_options
  )

  tryCatch(
    do.call(ollamar::generate, call_args),
    error = function(e) {
      stop(paste("Ollama API call failed:", conditionMessage(e)), call. = FALSE)
    }
  )
}
