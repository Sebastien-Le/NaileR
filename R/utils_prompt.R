# ---------------------------------------------------------------------------
# Prompt utilities
# ---------------------------------------------------------------------------

.nail_interpretive_insight_instruction <- function() {
  paste(
    "When the evidence allows it, identify and explain the most informative",
    "insight that emerges from the configuration of findings rather than from",
    "any one finding alone, without presenting that insight as an additional",
    "demonstrated fact."
  )
}

.append_nail_default_interpretive_insight <- function(request) {
  paste(
    request,
    .nail_interpretive_insight_instruction(),
    sep = "\n\n"
  )
}

#' Build a standard markdown prompt
#'
#' @param introduction Introduction section.
#' @param request Task section.
#' @param data Data section.
#' @param conclusion Optional conclusion/output-format section.
#'
#' @return A markdown prompt.
#' @keywords internal
build_standard_prompt <- function(introduction, request, data, conclusion = NULL) {
  out <- paste(
    "# Introduction\n\n",
    introduction,
    "\n\n# Task\n\n",
    request,
    "\n\n# Data\n\n",
    data,
    sep = ""
  )

  if (!is.null(conclusion) && nzchar(trimws(conclusion))) {
    out <- paste(out, "\n\n", conclusion, sep = "")
  }

  normalize_blank_lines(out)
}
