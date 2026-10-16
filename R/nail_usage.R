# ---------------------------------------------------------------------------
# LLM usage analytics
# ---------------------------------------------------------------------------

.nail_usage_state <- new.env(parent = emptyenv())
.nail_usage_state$next_id <- 0L

.nail_usage_columns <- function() {
  c(
    "call_id", "provider", "model_requested", "model_version", "analysis",
    "stage", "scope", "scope_id", "started_at", "input_tokens",
    "output_tokens", "thinking_tokens", "cached_input_tokens",
    "total_tokens_reported", "duration_seconds", "load_duration_seconds",
    "prompt_eval_duration_seconds", "eval_duration_seconds", "http_attempts",
    "finish_reason", "http_status", "generation_status", "parse_status",
    "error_message", "temperature", "top_p", "max_output_tokens",
    "estimated_cost", "currency", "tariff_model", "tariff_service",
    "tariff_date", "tariff_source", "cost_status", "cost_hypothesis"
  )
}

.nail_usage_empty <- function() {
  out <- data.frame(
    call_id = character(), provider = character(), model_requested = character(),
    model_version = character(), analysis = character(), stage = character(),
    scope = character(), scope_id = character(), started_at = character(),
    input_tokens = numeric(), output_tokens = numeric(), thinking_tokens = numeric(),
    cached_input_tokens = numeric(), total_tokens_reported = numeric(),
    duration_seconds = numeric(), load_duration_seconds = numeric(),
    prompt_eval_duration_seconds = numeric(), eval_duration_seconds = numeric(),
    http_attempts = integer(), finish_reason = character(),
    http_status = integer(), generation_status = character(), parse_status = character(),
    error_message = character(), temperature = numeric(), top_p = numeric(),
    max_output_tokens = numeric(), estimated_cost = numeric(), currency = character(),
    tariff_model = character(), tariff_service = character(), tariff_date = character(),
    tariff_source = character(), cost_status = character(), cost_hypothesis = character(),
    stringsAsFactors = FALSE
  )
  class(out) <- c("nail_usage", "data.frame")
  out
}

.nail_usage_next_id <- function() {
  .nail_usage_state$next_id <- .nail_usage_state$next_id + 1L
  sprintf("LLM%06d", .nail_usage_state$next_id)
}

.nail_usage_pricing <- function(provider, model) {
  if (identical(provider, "gemini") && identical(model, "gemini-2.5-flash")) {
    return(list(
      input = 0.30,
      cached = 0.03,
      output = 2.50,
      model = "gemini-2.5-flash",
      service = "standard_paid",
      date = "2026-10-16",
      source = "https://ai.google.dev/gemini-api/docs/pricing"
    ))
  }
  NULL
}

.nail_usage_normalize_record <- function(record,
                                         provider = NA_character_,
                                         model = NA_character_,
                                         prompt = NULL,
                                         analysis = NA_character_,
                                         stage = NA_character_,
                                         scope = NA_character_,
                                         scope_id = NA_character_,
                                         parse_status = NA_character_) {
  if (is.null(record)) return(NULL)
  record <- as.list(record)
  if (is.null(record$call_id)) record$call_id <- .nail_usage_next_id()
  if (is.null(record$provider)) record$provider <- provider
  if (is.null(record$model_requested)) record$model_requested <- model
  if (is.null(record$analysis)) record$analysis <- analysis
  if (is.null(record$stage)) record$stage <- stage
  if (is.null(record$scope)) record$scope <- scope
  if (is.null(record$scope_id)) record$scope_id <- scope_id
  if (is.null(record$parse_status)) record$parse_status <- parse_status
  if (is.null(record$started_at)) record$started_at <- NA_character_
  if (is.null(record$input_tokens)) record$input_tokens <- NA_real_
  if (is.null(record$output_tokens)) record$output_tokens <- NA_real_
  if (is.null(record$thinking_tokens)) record$thinking_tokens <- NA_real_
  if (is.null(record$cached_input_tokens)) record$cached_input_tokens <- NA_real_
  if (is.null(record$total_tokens_reported)) record$total_tokens_reported <- NA_real_
  if (is.null(record$duration_seconds)) record$duration_seconds <- NA_real_
  if (is.null(record$http_attempts)) record$http_attempts <- NA_integer_
  if (is.null(record$finish_reason)) record$finish_reason <- NA_character_
  if (is.null(record$http_status)) record$http_status <- NA_integer_
  if (is.null(record$generation_status)) record$generation_status <- NA_character_
  if (is.null(record$error_message)) record$error_message <- NA_character_
  if (is.null(record$temperature)) record$temperature <- NA_real_
  if (is.null(record$top_p)) record$top_p <- NA_real_
  if (is.null(record$max_output_tokens)) record$max_output_tokens <- NA_real_
  if (is.null(record$prompt_characters)) record$prompt_characters <- if (is.null(prompt)) NA_integer_ else nchar(prompt)

  price <- .nail_usage_pricing(record$provider, record$model_requested)
  complete_tokens <- !is.null(price) &&
    is.finite(record$input_tokens) &&
    is.finite(record$output_tokens) &&
    is.finite(record$thinking_tokens)
  if (isTRUE(complete_tokens)) {
    cached_known <- is.finite(record$cached_input_tokens)
    cached <- if (cached_known) record$cached_input_tokens else 0
    uncached <- max(0, record$input_tokens - cached)
    record$estimated_cost <- uncached * price$input / 1e6 +
      cached * price$cached / 1e6 +
      (record$output_tokens + record$thinking_tokens) * price$output / 1e6
    record$currency <- "USD"
    record$tariff_model <- price$model
    record$tariff_service <- price$service
    record$tariff_date <- price$date
    record$tariff_source <- price$source
    record$cost_status <- if (cached_known) {
      "estimated_from_reported_usage"
    } else {
      "estimated_conditional"
    }
    record$cost_hypothesis <- if (cached_known) {
      "cached_input_tokens_reported_by_provider"
    } else {
      "cached_input_tokens_missing_assumed_zero"
    }
  } else if (!is.null(price)) {
    record$estimated_cost <- NA_real_
    record$currency <- "USD"
    record$tariff_model <- price$model
    record$tariff_service <- price$service
    record$tariff_date <- price$date
    record$tariff_source <- price$source
    record$cost_status <- "unknown_missing_cost_components"
    record$cost_hypothesis <- "not_estimable_from_available_usage_metadata"
  } else {
    record$estimated_cost <- NA_real_
    record$currency <- NA_character_
    record$tariff_model <- NA_character_
    record$tariff_service <- NA_character_
    record$tariff_date <- NA_character_
    record$tariff_source <- NA_character_
    record$cost_status <- "unknown"
    record$cost_hypothesis <- "no_supported_tariff"
  }

  out <- as.data.frame(lapply(.nail_usage_columns(), function(name) {
    value <- record[[name]]
    if (is.null(value)) NA else value
  }), stringsAsFactors = FALSE)
  names(out) <- .nail_usage_columns()
  out
}

.nail_usage_from_backend <- function(x,
                                     provider = NA_character_,
                                     model = NA_character_,
                                     prompt = NULL,
                                     analysis = NA_character_,
                                     stage = NA_character_,
                                     scope = NA_character_,
                                     scope_id = NA_character_,
                                     parse_status = NA_character_) {
  record <- attr(x, "nail_usage", exact = TRUE)
  if (is.null(record) && is.list(x) && !is.null(x$usage)) record <- x$usage
  .nail_usage_normalize_record(
    record = record,
    provider = provider,
    model = model,
    prompt = prompt,
    analysis = analysis,
    stage = stage,
    scope = scope,
    scope_id = scope_id,
    parse_status = parse_status
  )
}

.nail_usage_from_results <- function(results,
                                     prompts,
                                     provider,
                                     model,
                                     analysis,
                                     stage = "interpretation",
                                     scope = "unit",
                                     parse_status = NULL) {
  if (is.null(results) || length(results) == 0L) return(.nail_usage_empty())
  if (!is.list(results)) results <- list(results)
  if (is.null(names(results))) names(results) <- as.character(seq_along(results))
  if (!is.list(prompts)) prompts <- stats::setNames(list(prompts), names(results)[1L])
  rows <- lapply(names(results), function(id) {
    item <- results[[id]]
    prompt <- if (!is.null(prompts[[id]])) prompts[[id]] else NULL
    ps <- if (is.null(parse_status)) {
      NA_character_
    } else if (length(parse_status) == 1L && is.null(names(parse_status))) {
      parse_status[[1L]]
    } else {
      parse_status[[id]]
    }
    .nail_usage_from_backend(item, provider, model, prompt, analysis, stage, scope, id, ps)
  })
  rows <- rows[!vapply(rows, is.null, logical(1))]
  if (!length(rows)) return(.nail_usage_empty())
  out <- do.call(rbind, rows)
  class(out) <- c("nail_usage", "data.frame")
  out
}

.nail_usage_parse_status <- function(groups) {
  if (is.null(groups) || length(groups) == 0L) return(NULL)
  statuses <- vapply(groups, function(group) {
    status <- if (is.list(group) && !is.null(group$status)) {
      as.character(group$status[[1L]])
    } else {
      NA_character_
    }
    if (status %in% c("available", "generated")) {
      "success"
    } else if (status %in% c("parse_failed", "generation_missing")) {
      "failed"
    } else {
      NA_character_
    }
  }, character(1))
  statuses
}

.nail_usage_attach <- function(x, record) {
  if (!is.null(record)) attr(x, "nail_usage") <- record
  x
}

#' Inspect LLM consumption metadata stored in a NaileR result
#'
#' @param result A result returned by a NaileR analysis function.
#' @return A `nail_usage` data frame with one row per effective LLM call.
#'   Preview results return a valid zero-row table. Older objects without the
#'   metadata return a table with no rows and an `unknown` attribute.
#' @export
nail_usage <- function(result) {
  io <- attr(result, "llm_io", exact = TRUE)
  if (is.null(io) || is.null(io$metadata$usage)) {
    out <- .nail_usage_empty()
    attr(out, "usage_status") <- if (is.null(io)) {
      "unknown"
    } else if (is.null(io$responses)) {
      "not_generated"
    } else {
      "unknown"
    }
    return(out)
  }
  out <- io$metadata$usage
  if (!is.data.frame(out)) stop("Stored usage metadata is malformed.", call. = FALSE)
  class(out) <- c("nail_usage", "data.frame")
  if (nrow(out) == 0L) attr(out, "usage_status") <- "not_generated"
  out
}

#' Summarize LLM consumption metadata
#'
#' @param result A NaileR result, or a `nail_usage` table.
#' @return A two-column data frame of summary metrics and values. Completion is
#'   `n_completed / generation_completion_denominator`, where the denominator
#'   is the number of recorded calls (`n_calls`), including interrupted,
#'   failed, other-status, and unknown-status calls. Missing usage metrics are
#'   not treated as zero. Complete totals are `NA` when any call is missing the
#'   metric; corresponding `*_available_sum` and `*_coverage` metrics expose
#'   partial coverage explicitly.
#' @export
nail_usage_summary <- function(result) {
  usage <- if (inherits(result, "nail_usage")) result else nail_usage(result)
  known <- function(x) sum(!is.na(x))
  available_total <- function(x) if (!any(!is.na(x))) NA_real_ else sum(x, na.rm = TRUE)
  complete_total <- function(x) if (length(x) && all(!is.na(x))) sum(x) else NA_real_
  coverage <- function(x) if (nrow(usage)) sum(!is.na(x)) / nrow(usage) else NA_real_
  mean_known <- function(x) if (!any(!is.na(x))) NA_real_ else mean(x, na.rm = TRUE)
  median_known <- function(x) if (!any(!is.na(x))) NA_real_ else median(x, na.rm = TRUE)
  statuses <- as.character(usage$generation_status)
  completed <- sum(statuses == "completed", na.rm = TRUE)
  interrupted <- sum(usage$generation_status == "interrupted", na.rm = TRUE)
  failed <- sum(usage$generation_status == "failed", na.rm = TRUE)
  other_status <- sum(
    statuses %in% c("safety_blocked", "recitation_blocked", "other_finished"),
    na.rm = TRUE
  )
  unknown_status <- sum(
    is.na(statuses) | statuses == "unknown",
    na.rm = TRUE
  )
  parsed <- sum(usage$parse_status %in% c("success", "available"), na.rm = TRUE)
  vals <- c(
    n_calls = nrow(usage), n_completed = completed,
    n_successful = completed + interrupted,
    n_interrupted = interrupted, n_failed = failed,
    n_other_status = other_status, n_unknown_status = unknown_status,
    n_parsed = parsed,
    generation_completion_denominator = nrow(usage),
    generation_completion_rate = if (nrow(usage)) completed / nrow(usage) else NA_real_,
    input_tokens_total = complete_total(usage$input_tokens),
    input_tokens_available_sum = available_total(usage$input_tokens),
    input_tokens_known_calls = known(usage$input_tokens),
    input_tokens_coverage = coverage(usage$input_tokens),
    output_tokens_total = complete_total(usage$output_tokens),
    output_tokens_available_sum = available_total(usage$output_tokens),
    output_tokens_known_calls = known(usage$output_tokens),
    output_tokens_coverage = coverage(usage$output_tokens),
    thinking_tokens_total = complete_total(usage$thinking_tokens),
    thinking_tokens_available_sum = available_total(usage$thinking_tokens),
    thinking_tokens_known_calls = known(usage$thinking_tokens),
    thinking_tokens_coverage = coverage(usage$thinking_tokens),
    total_tokens_reported = complete_total(usage$total_tokens_reported),
    total_tokens_available_sum = available_total(usage$total_tokens_reported),
    total_tokens_known_calls = known(usage$total_tokens_reported),
    total_tokens_coverage = coverage(usage$total_tokens_reported),
    input_tokens_mean = mean_known(usage$input_tokens), input_tokens_median = median_known(usage$input_tokens),
    duration_total_seconds = complete_total(usage$duration_seconds),
    duration_available_sum_seconds = available_total(usage$duration_seconds),
    duration_known_calls = known(usage$duration_seconds),
    duration_coverage = coverage(usage$duration_seconds),
    estimated_cost_total = complete_total(usage$estimated_cost),
    estimated_cost_available_sum = available_total(usage$estimated_cost),
    estimated_cost_mean = mean_known(usage$estimated_cost),
    known_cost_calls = known(usage$estimated_cost),
    estimated_cost_coverage = coverage(usage$estimated_cost),
    known_parse_status_calls = known(usage$parse_status)
  )
  data.frame(metric = names(vals), value = as.numeric(vals), stringsAsFactors = FALSE)
}

#' Plot NaileR LLM usage metadata
#'
#' @param x A `nail_usage` table, normally returned by `nail_usage()`.
#' @param metric One of `"tokens"`, `"cost"`, or `"duration"`.
#' @param ... Additional graphical arguments passed to base graphics.
#' @details Missing values are never silently converted to zero. For token
#'   plots, calls with at least one known token component remain visible;
#'   missing components are shown as zero-height placeholders and a warning
#'   identifies them. Calls with no known token component, and calls with
#'   incomplete cost or duration, are excluded from the corresponding plot and
#'   a warning identifies the exclusion. The original observations remain
#'   available in the returned usage table and summaries.
#' @export
plot.nail_usage <- function(x, metric = c("tokens", "cost", "duration"), ...) {
  metric <- match.arg(metric)
  if (!nrow(x)) {
    graphics::plot.new()
    graphics::title(main = "No LLM usage recorded")
    return(invisible(x))
  }
  complete <- if (metric == "tokens") {
    token_values <- do.call(
      cbind,
      lapply(x[, c("input_tokens", "thinking_tokens", "output_tokens"), drop = FALSE], is.finite)
    )
    rowSums(token_values) > 0
  } else if (metric == "cost") {
    is.finite(x$estimated_cost)
  } else {
    is.finite(x$duration_seconds)
  }
  if (any(!complete)) {
    warning(
      sum(!complete), " call(s) excluded from the ", metric,
      " plot because the required metric is incomplete.",
      call. = FALSE
    )
  }
  if (!any(complete)) {
    graphics::plot.new()
    graphics::title(main = paste("No complete", metric, "usage recorded"))
    return(invisible(x))
  }
  x <- x[complete, , drop = FALSE]
  labels <- ifelse(is.na(x$scope_id), x$call_id, x$scope_id)
  if (metric == "tokens") {
    token_columns <- c("input_tokens", "thinking_tokens", "output_tokens")
    missing_components <- token_columns[vapply(
      token_columns,
      function(column) any(!is.finite(x[[column]])),
      logical(1)
    )]
    if (length(missing_components)) {
      warning(
        "Missing token component(s): ", paste(missing_components, collapse = ", "),
        ". Available components are plotted; missing values are shown only as " ,
        "zero-height placeholders.",
        call. = FALSE
      )
    }
    y <- rbind(
      ifelse(is.finite(x$input_tokens), x$input_tokens, 0),
      ifelse(is.finite(x$thinking_tokens), x$thinking_tokens, 0),
      ifelse(is.finite(x$output_tokens), x$output_tokens, 0)
    )
    legend <- c("input", "thinking", "output")
    legend <- ifelse(
      token_columns %in% missing_components,
      paste0(legend, " (missing values present)"),
      legend
    )
    graphics::barplot(y, beside = FALSE, names.arg = labels, legend.text = legend, ylab = "tokens", ...)
    if (length(missing_components)) {
      graphics::mtext(
        "Missing token values are not zero consumption; they are display placeholders.",
        side = 1, line = 3, cex = 0.7
      )
    }
  } else if (metric == "cost") {
    graphics::barplot(x$estimated_cost, names.arg = labels, ylab = "estimated cost", ...)
  } else {
    graphics::barplot(x$duration_seconds, names.arg = labels, ylab = "seconds", ...)
  }
  invisible(x)
}
