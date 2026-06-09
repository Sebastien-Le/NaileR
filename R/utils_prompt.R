# ---------------------------------------------------------------------------
# Prompt utilities
# ---------------------------------------------------------------------------

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
