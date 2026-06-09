# ---------------------------------------------------------------------------
# LLM parsing utilities
# ---------------------------------------------------------------------------

.escape_regex <- function(x) {
  gsub("([][{}()+*^$|\\\\?.])", "\\\\\\1", x)
}

.strip_markdown_fences <- function(text) {
  text <- paste(text, collapse = "\n")
  text <- gsub("\r\n", "\n", text, fixed = TRUE)
  text <- gsub("\r", "\n", text, fixed = TRUE)
  text <- gsub("(?im)^\\s*```[[:alnum:]_-]*\\s*$", "", text, perl = TRUE)
  text <- gsub("(?im)^\\s*```\\s*$", "", text, perl = TRUE)
  trimws(text)
}

.extract_json_candidate <- function(text) {
  text <- .strip_markdown_fences(text)
  if (!nzchar(text)) return(text)

  starts <- regexpr("[\\[{]", text, perl = TRUE)
  if (starts[1] < 0) return(text)

  first <- starts[1]
  chars <- strsplit(substr(text, first, nchar(text)), "", fixed = TRUE)[[1]]
  depth <- 0L
  in_string <- FALSE
  escape_next <- FALSE

  for (i in seq_along(chars)) {
    ch <- chars[[i]]

    if (escape_next) {
      escape_next <- FALSE
      next
    }
    if (identical(ch, "\\") && in_string) {
      escape_next <- TRUE
      next
    }
    if (identical(ch, '"')) {
      in_string <- !in_string
      next
    }
    if (in_string) next

    if (ch %in% c("{", "[")) depth <- depth + 1L
    if (ch %in% c("}", "]")) depth <- depth - 1L

    if (depth == 0L && ch %in% c("}", "]")) {
      return(substr(text, first, first + i - 1L))
    }
  }

  last_brace <- max(gregexpr("[\\]}]", text, perl = TRUE)[[1]])
  if (is.finite(last_brace) && last_brace > first) {
    return(substr(text, first, last_brace))
  }

  text
}

.parse_json_response <- function(text, simplifyDataFrame = TRUE) {
  candidate <- .extract_json_candidate(text)
  jsonlite::fromJSON(candidate, simplifyDataFrame = simplifyDataFrame)
}

.extract_field_block <- function(text, field, fields) {
  text <- paste(text, collapse = "\n")
  text <- gsub("\r\n", "\n", text, fixed = TRUE)
  text <- gsub("\r", "\n", text, fixed = TRUE)

  escaped_field <- .escape_regex(field)
  start_pattern <- paste0(
    "(?im)^\\s*(?:[-*+]\\s*)?(?:\\*\\*|__)?\\s*",
    escaped_field,
    "\\s*:\\s*(?:\\*\\*|__)?\\s*"
  )

  start <- regexpr(start_pattern, text, perl = TRUE)
  if (start[1] < 0) return(NA_character_)

  value_start <- start[1] + attr(start, "match.length")
  rest <- substr(text, value_start, nchar(text))

  other_fields <- setdiff(fields, field)
  other_pattern <- paste0(
    "(?im)^\\s*(?:[-*+]\\s*)?(?:\\*\\*|__)?\\s*(?:",
    paste(vapply(other_fields, .escape_regex, character(1)), collapse = "|"),
    ")\\s*:\\s*"
  )

  next_match <- regexpr(other_pattern, rest, perl = TRUE)
  if (next_match[1] >= 0) {
    rest <- substr(rest, 1, next_match[1] - 1L)
  }

  rest <- gsub("(?m)^\\s*[-*+]\\s*", "", rest, perl = TRUE)
  rest <- gsub("(?m)^\\s*(?:\\*\\*|__)(.*?)(?:\\*\\*|__)\\s*$", "\\1", rest, perl = TRUE)
  trimws(rest)
}

.split_semicolon_traits <- function(x) {
  if (length(x) == 0 || is.na(x) || !nzchar(trimws(x))) {
    return(character(0))
  }

  x <- gsub("\\n+", ";", x)
  vals <- unlist(strsplit(x, ";", fixed = TRUE))
  vals <- trimws(vals)
  vals <- vals[nzchar(vals)]
  vals <- gsub("^[[:punct:][:space:]]+", "", vals)
  vals <- gsub("[[:punct:][:space:]]+$", "", vals)
  vals <- trimws(vals)
  vals <- vals[nzchar(vals)]

  if (length(vals) == 1 && tolower(vals) %in% c("none", "unclear", "no", "na", "n/a")) {
    return(character(0))
  }

  vals
}
