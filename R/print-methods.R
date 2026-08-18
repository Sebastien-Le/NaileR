# ---------------------------------------------------------------------------
# Concise print methods for NaileR structured objects
# ---------------------------------------------------------------------------

.nail_print_scalar <- function(x, default = "unknown") {
  if (is.null(x) || length(x) == 0L || is.na(x[[1L]]) || !nzchar(as.character(x[[1L]]))) {
    return(default)
  }
  as.character(x[[1L]])
}

.nail_print_count <- function(x) {
  if (is.null(x) || length(x) == 0L || is.na(x[[1L]])) return(0L)
  as.integer(x[[1L]])
}

#' Print a structured nail_catdes result
#'
#' @param x A `nail_catdes` object.
#' @param ... Unused.
#' @return `x`, invisibly.
#' @export
print.nail_catdes <- function(x, ...) {
  profiles <- if (is.list(x$preparation)) {
    x$preparation$statistical_profiles
  } else {
    x$statistical_profiles
  }
  groups <- if (is.list(profiles$groups)) names(profiles$groups) else character(0)
  selected <- if (is.list(x$preparation)) {
    x$preparation$interpretation_evidence$selected_evidence_registry
  } else {
    x$interpretation_evidence$selected_evidence_registry
  }
  n_evidence <- if (is.data.frame(selected)) nrow(selected) else 0L

  generation <- x$generation
  requested <- is.list(generation) && isTRUE(generation$requested)
  provider <- if (is.list(generation)) generation$provider else x$metadata$provider
  model <- if (is.list(generation)) generation$model else x$metadata$model
  status <- if (is.list(x$validation)) x$validation$status else x$metadata$semantic_status

  cat("NaileR statistical description\n")
  cat("--------------------------------\n")
  cat("Target variable: ", .nail_print_scalar(x$metadata$target_label), "\n", sep = "")
  cat("Groups: ", length(groups), "\n", sep = "")
  cat("Selected statistical evidence: ", n_evidence, "\n", sep = "")
  cat("Generation requested: ", if (requested) "yes" else "no", "\n", sep = "")
  cat("Provider/model: ", .nail_print_scalar(provider), " / ", .nail_print_scalar(model), "\n", sep = "")
  cat("Semantic status: ", .nail_print_scalar(status), "\n", sep = "")
  cat("\nAvailable components:\n")
  cat("  $preparation\n")
  cat("  $prompt\n")
  cat("  $statistical_description\n")
  cat("  $generation\n")
  cat("  $validation\n")
  cat("  $report\n")
  cat("  $metadata\n")
  invisible(x)
}

#' Print mechanical statistical profiles
#'
#' @param x A `statistical_profiles` object.
#' @param ... Unused.
#' @return `x`, invisibly.
#' @export
print.statistical_profiles <- function(x, ...) {
  registry <- x$evidence_registry
  n_evidence <- if (is.data.frame(registry)) nrow(registry) else 0L
  n_quali <- if (is.data.frame(registry) && "marker_type" %in% names(registry)) {
    sum(registry$marker_type == "qualitative", na.rm = TRUE)
  } else {
    0L
  }
  n_quanti <- if (is.data.frame(registry) && "marker_type" %in% names(registry)) {
    sum(registry$marker_type == "quantitative", na.rm = TRUE)
  } else {
    0L
  }
  groups <- if (is.list(x$groups)) names(x$groups) else character(0)

  cat("NaileR statistical profiles\n")
  cat("----------------------------\n")
  cat("Source: ", .nail_print_scalar(x$metadata$source), "\n", sep = "")
  cat("Groups: ", length(groups), "\n", sep = "")
  cat("Retained evidence: ", n_evidence, "\n", sep = "")
  cat("  Qualitative markers: ", n_quali, "\n", sep = "")
  cat("  Quantitative markers: ", n_quanti, "\n", sep = "")
  cat("LLM used: ", if (isTRUE(x$metadata$llm_used)) "yes" else "no", "\n", sep = "")
  cat("\nAvailable components:\n")
  cat("  $groups\n")
  cat("  $evidence_registry\n")
  cat("  $settings\n")
  cat("  $metadata\n")
  invisible(x)
}

#' Print a structured nail_textual result
#'
#' @param x A `nail_textual` object.
#' @param ... Unused.
#' @return `x`, invisibly.
#' @export
print.nail_textual <- function(x, ...) {
  groups <- if (is.list(x$textual_evidence$groups)) names(x$textual_evidence$groups) else character(0)
  registry <- x$textual_evidence$evidence_registry
  n_evidence <- if (is.data.frame(registry)) nrow(registry) else 0L

  cat("NaileR textual description\n")
  cat("----------------------------\n")
  cat("Groups: ", length(groups), "\n", sep = "")
  cat("Textual evidence: ", n_evidence, "\n", sep = "")
  cat("Comparison mode: ", .nail_print_scalar(x$metadata$comparison_mode), "\n", sep = "")
  cat("Generation calls: ", .nail_print_count(x$metadata$llm_calls), "\n", sep = "")
  cat("Semantic status: ", .nail_print_scalar(x$metadata$semantic_status), "\n", sep = "")
  cat("Report format: ", .nail_print_scalar(x$metadata$report_format), "\n", sep = "")
  cat("\nAvailable components:\n")
  cat("  $preparation\n")
  cat("  $prompt\n")
  cat("  $textual_description\n")
  cat("  $generation\n")
  cat("  $validation\n")
  cat("  $report\n")
  cat("  $metadata\n")
  invisible(x)
}

#' Print a nail_textual_prep object
#'
#' @param x A `nail_textual_prep` object.
#' @param ... Unused.
#' @return `x`, invisibly.
#' @export
print.nail_textual_prep <- function(x, ...) {
  groups <- if (is.list(x$textual_evidence$groups)) names(x$textual_evidence$groups) else character(0)
  registry <- x$textual_evidence$evidence_registry
  n_evidence <- if (is.data.frame(registry)) nrow(registry) else 0L
  status <- if (is.list(x$parsed)) x$parsed$parse_status else NULL

  cat("NaileR textual preparation\n")
  cat("---------------------------\n")
  cat("Groups: ", length(groups), "\n", sep = "")
  cat("Textual evidence: ", n_evidence, "\n", sep = "")
  cat("Comparison mode: ", .nail_print_scalar(x$metadata$comparison_mode), "\n", sep = "")
  cat("Semantic status: ", .nail_print_scalar(status), "\n", sep = "")
  cat("\nAvailable components:\n")
  cat("  $textual_evidence\n")
  cat("  $units\n")
  cat("  $textual_description\n")
  cat("  $generation\n")
  cat("  $validation\n")
  cat("  $metadata\n")
  invisible(x)
}
