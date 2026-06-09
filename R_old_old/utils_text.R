# ---------------------------------------------------------------------------
# Text utilities
# ---------------------------------------------------------------------------

#' Normalize blank lines in markdown text
#'
#' Removes trailing spaces before line breaks and collapses 3+ blank lines
#' into 2 blank lines.
#'
#' @param x A character string.
#'
#' @return A cleaned character string.
#' @keywords internal
normalize_blank_lines <- function(x) {
  x <- gsub("[ \t]+\n", "\n", x)
  gsub("\\n{3,}", "\n\n", x)
}
