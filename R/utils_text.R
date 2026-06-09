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


#' Return the wording used for product/group units in QDA prompts
#'
#' @param product_knowledge Either "known" or "unknown".
#' @param capital Logical; capitalize first letter.
#' @param plural Logical; return plural form.
#'
#' @return A unit label.
#' @keywords internal
.unit_word_qda <- function(product_knowledge = c("known", "unknown"),
                           capital = FALSE,
                           plural = FALSE) {
  product_knowledge <- match.arg(product_knowledge)

  word <- if (product_knowledge == "known") {
    if (plural) "products" else "product"
  } else {
    if (plural) "samples" else "sample"
  }

  if (capital) {
    paste0(toupper(substr(word, 1, 1)), substr(word, 2, nchar(word)))
  } else {
    word
  }
}
