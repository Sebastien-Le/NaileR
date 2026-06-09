# ---------------------------------------------------------------------------
# Validation utilities
# ---------------------------------------------------------------------------

#' Assert that x is a proportion in (0, 1]
#' @param x A numeric scalar.
#' @param arg_name Argument name for error messages.
#' @keywords internal
assert_proportion <- function(x, arg_name) {
  if (!is.numeric(x) || length(x) != 1 || is.na(x) || x <= 0 || x > 1) {
    stop(sprintf("`%s` must be a single numeric value in (0, 1].", arg_name), call. = FALSE)
  }
}

#' Assert that x is a single non-missing logical
#' @param x Object to test.
#' @param arg_name Argument name for error messages.
#' @keywords internal
assert_single_logical <- function(x, arg_name) {
  if (!is.logical(x) || length(x) != 1 || is.na(x)) {
    stop(sprintf("`%s` must be a single non-missing logical value.", arg_name), call. = FALSE)
  }
}

#' Assert that a column index range is valid
#' @param first First index.
#' @param last Last index.
#' @param n Total number of columns.
#' @keywords internal
assert_index_range <- function(first, last, n) {
  if (!is.numeric(first) || length(first) != 1 || is.na(first) || first < 1) {
    stop("`firstvar` must be a single numeric value >= 1.", call. = FALSE)
  }

  if (!is.numeric(last) || length(last) != 1 || is.na(last) || last > n) {
    stop("`lastvar` must be a single numeric value <= ncol(dataset).", call. = FALSE)
  }

  if (first > last) {
    stop("`firstvar` must be <= `lastvar`.", call. = FALSE)
  }
}
