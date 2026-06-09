# ---------------------------------------------------------------------------
# Validation utilities
# ---------------------------------------------------------------------------

#' Assert that x is a data frame
#' @param x Object to test.
#' @param arg_name Argument name for error messages.
#' @keywords internal
assert_data_frame <- function(x, arg_name = "dataset") {
  if (!is.data.frame(x)) {
    stop(sprintf("`%s` must be a data frame.", arg_name), call. = FALSE)
  }
  invisible(TRUE)
}

#' Assert that x is a proportion in (0, 1]
#' @param x A numeric scalar.
#' @param arg_name Argument name for error messages.
#' @keywords internal
assert_proportion <- function(x, arg_name) {
  if (!is.numeric(x) || length(x) != 1 || is.na(x) || x <= 0 || x > 1) {
    stop(sprintf("`%s` must be a single numeric value in (0, 1].", arg_name), call. = FALSE)
  }
  invisible(TRUE)
}

#' Assert that x is a single non-missing logical
#' @param x Object to test.
#' @param arg_name Argument name for error messages.
#' @keywords internal
assert_single_logical <- function(x, arg_name) {
  if (!is.logical(x) || length(x) != 1 || is.na(x)) {
    stop(sprintf("`%s` must be a single non-missing logical value.", arg_name), call. = FALSE)
  }
  invisible(TRUE)
}

#' Assert that a column index is valid
#' @param x Column index.
#' @param n Total number of columns.
#' @param arg_name Argument name for error messages.
#' @keywords internal
assert_column_index <- function(x, n, arg_name = "num.var") {
  if (!is.numeric(x) || length(x) != 1 || is.na(x) || x < 1 || x > n || x != as.integer(x)) {
    stop(sprintf("`%s` must be a single valid column index between 1 and %s.", arg_name, n), call. = FALSE)
  }
  invisible(TRUE)
}

#' Assert that a column index range is valid
#' @param first First index.
#' @param last Last index.
#' @param n Total number of columns.
#' @keywords internal
assert_index_range <- function(first, last, n) {
  if (!is.numeric(first) || length(first) != 1 || is.na(first) || first < 1 || first != as.integer(first)) {
    stop("`firstvar` must be a single integer-like value >= 1.", call. = FALSE)
  }

  if (!is.numeric(last) || length(last) != 1 || is.na(last) || last > n || last != as.integer(last)) {
    stop("`lastvar` must be a single integer-like value <= ncol(dataset).", call. = FALSE)
  }

  if (first > last) {
    stop("`firstvar` must be <= `lastvar`.", call. = FALSE)
  }
  invisible(TRUE)
}

#' Assert that x is a positive integer-like scalar
#' @param x Object to test.
#' @param arg_name Argument name for error messages.
#' @param allow_zero Whether zero is accepted.
#' @keywords internal
assert_positive_integerish <- function(x, arg_name, allow_zero = FALSE) {
  lower_ok <- if (allow_zero) x >= 0 else x >= 1
  if (!is.numeric(x) || length(x) != 1 || is.na(x) || !lower_ok || x != as.integer(x)) {
    bound <- if (allow_zero) ">= 0" else ">= 1"
    stop(sprintf("`%s` must be a single integer-like value %s.", arg_name, bound), call. = FALSE)
  }
  invisible(TRUE)
}

#' Assert that x is one of the allowed choices
#' @param x Object to test.
#' @param choices Allowed values.
#' @param arg_name Argument name for error messages.
#' @keywords internal
assert_choice <- function(x, choices, arg_name) {
  if (!is.character(x) || length(x) != 1 || is.na(x) || !x %in% choices) {
    stop(
      sprintf("`%s` must be one of: %s.", arg_name, paste(choices, collapse = ", ")),
      call. = FALSE
    )
  }
  invisible(TRUE)
}

#' Assert that x is a numeric scalar within optional bounds
#' @param x Object to test.
#' @param arg_name Argument name for error messages.
#' @param lower Optional lower bound.
#' @param upper Optional upper bound.
#' @param inclusive Whether bounds are inclusive.
#' @keywords internal
assert_numeric_scalar <- function(x, arg_name, lower = NULL, upper = NULL, inclusive = TRUE) {
  ok <- is.numeric(x) && length(x) == 1 && !is.na(x)
  if (ok && !is.null(lower)) {
    ok <- if (inclusive) x >= lower else x > lower
  }
  if (ok && !is.null(upper)) {
    ok <- if (inclusive) x <= upper else x < upper
  }
  if (!ok) {
    bounds <- character(0)
    if (!is.null(lower)) bounds <- c(bounds, paste0(if (inclusive) ">= " else "> ", lower))
    if (!is.null(upper)) bounds <- c(bounds, paste0(if (inclusive) "<= " else "< ", upper))
    bounds_txt <- if (length(bounds) > 0) paste0(" and ", paste(bounds, collapse = " and ")) else ""
    stop(sprintf("`%s` must be a single numeric value%s.", arg_name, bounds_txt), call. = FALSE)
  }
  invisible(TRUE)
}
