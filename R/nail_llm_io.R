# ---------------------------------------------------------------------------
# Public UX helpers for inspecting LLM prompts and responses
# ---------------------------------------------------------------------------

.new_nail_llm_io <- function(stage,
                             prompts,
                             responses = NULL,
                             metadata = list()) {
  if (!is.character(stage) || length(stage) != 1L ||
      is.na(stage) || !nzchar(trimws(stage))) {
    stop("`stage` must be one non-empty character string.", call. = FALSE)
  }

  normalize_units <- function(x, name) {
    if (is.null(x)) {
      return(NULL)
    }

    if (is.character(x) && length(x) == 1L && !is.na(x)) {
      return(list(`1` = x))
    }

    if (!is.list(x) || length(x) == 0L) {
      stop(
        sprintf(
          "`%s` must be NULL, one character string, or a named list of character strings.",
          name
        ),
        call. = FALSE
      )
    }

    ok <- vapply(
      x,
      function(value) {
        is.character(value) &&
          length(value) == 1L &&
          !is.na(value)
      },
      logical(1)
    )

    if (!all(ok)) {
      stop(
        sprintf(
          "Every `%s` item must be one non-missing character string.",
          name
        ),
        call. = FALSE
      )
    }

    if (is.null(names(x)) || any(!nzchar(names(x)))) {
      names(x) <- as.character(seq_along(x))
    }

    x
  }

  prompts <- normalize_units(prompts, "prompts")
  responses <- normalize_units(responses, "responses")

  structure(
    list(
      stage = trimws(stage),
      prompts = prompts,
      responses = responses,
      metadata = metadata
    ),
    class = c("nail_llm_io", "list")
  )
}

.nail_io_from_canonical <- function(x, field) {
  io <- attr(x, "llm_io", exact = TRUE)

  if (is.null(io) && is.list(x) && !is.null(x$llm_io)) {
    io <- x$llm_io
  }

  if (is.null(io)) {
    return(NULL)
  }

  if (!is.list(io)) {
    stop(
      "The stored `llm_io` artifact is malformed: expected a list.",
      call. = FALSE
    )
  }

  slot <- if (identical(field, "prompt")) "prompts" else "responses"
  units <- io[[slot]]

  if (is.null(units)) {
    return(NULL)
  }

  if (is.character(units) && length(units) == 1L && !is.na(units)) {
    return(list(`1` = units))
  }

  if (!is.list(units) || length(units) == 0L) {
    stop(
      sprintf("The stored `llm_io$%s` artifact is malformed.", slot),
      call. = FALSE
    )
  }

  ok <- vapply(
    units,
    function(value) {
      is.character(value) &&
        length(value) == 1L &&
        !is.na(value)
    },
    logical(1)
  )

  if (!all(ok)) {
    stop(
      sprintf(
        "The stored `llm_io$%s` artifact contains non-character items.",
        slot
      ),
      call. = FALSE
    )
  }

  if (is.null(names(units)) || any(!nzchar(names(units)))) {
    names(units) <- as.character(seq_along(units))
  }

  units
}

.nail_io_assert_print <- function(print) {
  if (!is.logical(print) || length(print) != 1L || is.na(print)) {
    stop("`print` must be a single non-missing logical value.", call. = FALSE)
  }
  invisible(TRUE)
}

.nail_io_normalize_select <- function(select) {
  if (is.null(select)) {
    return(NULL)
  }

  if (is.numeric(select) && length(select) == 1L && !is.na(select)) {
    if (select < 1 || select != as.integer(select)) {
      stop("Numeric `select` must be a positive integer.", call. = FALSE)
    }
    return(as.integer(select))
  }

  if (is.character(select) && length(select) == 1L &&
      !is.na(select) && nzchar(select)) {
    return(select)
  }

  stop(
    "`select` must be NULL, one non-empty name, or one positive integer.",
    call. = FALSE
  )
}

.nail_io_scalar_character <- function(x) {
  if (is.character(x) && length(x) == 1L && !is.na(x)) {
    return(x)
  }
  NULL
}

.nail_io_units_from_data_frame <- function(x, field) {
  if (!is.data.frame(x) || !field %in% names(x) || nrow(x) == 0L) {
    return(NULL)
  }

  vals <- x[[field]]
  vals <- as.character(vals)
  keep <- !is.na(vals)

  if (!any(keep)) {
    return(NULL)
  }

  vals <- vals[keep]
  labels <- rownames(x)[keep]

  if (is.null(labels) || any(!nzchar(labels))) {
    labels <- as.character(seq_along(vals))
  }

  stats::setNames(as.list(vals), labels)
}

.nail_io_units_from_semantic_profiles <- function(x, field) {
  semantic_profiles <- attr(x, "semantic_profiles", exact = TRUE)

  if (is.null(semantic_profiles) &&
      is.list(x) &&
      !is.null(x$semantic_profiles)) {
    semantic_profiles <- x$semantic_profiles
  }

  if (is.null(semantic_profiles) ||
      !is.list(semantic_profiles$groups) ||
      length(semantic_profiles$groups) == 0L) {
    return(NULL)
  }

  out <- lapply(semantic_profiles$groups, function(group) {
    if (!is.list(group) || is.null(group[[field]])) {
      return(NULL)
    }
    .nail_io_scalar_character(group[[field]])
  })

  keep <- !vapply(out, is.null, logical(1))
  out <- out[keep]

  if (length(out) == 0L) {
    return(NULL)
  }

  out
}

.nail_io_units_from_ground <- function(x, field) {
  if (!inherits(x, "nail_catdes_ground")) {
    return(NULL)
  }

  if (identical(field, "prompt")) {
    prompts <- x$grounding_prompts
    if (!is.list(prompts) || length(prompts) == 0L) {
      return(NULL)
    }

    out <- lapply(prompts, .nail_io_scalar_character)
    keep <- !vapply(out, is.null, logical(1))
    out <- out[keep]

    if (length(out) == 0L) {
      return(NULL)
    }

    return(out)
  }

  if (identical(field, "response")) {
    profiles <- x$grounded_profiles
    if (!is.list(profiles) || length(profiles) == 0L) {
      return(NULL)
    }

    out <- lapply(profiles, function(profile) {
      if (!is.list(profile) || is.null(profile$backend_result)) {
        return(NULL)
      }

      backend_result <- profile$backend_result

      if (is.data.frame(backend_result) &&
          "response" %in% names(backend_result) &&
          nrow(backend_result) > 0L) {
        return(.nail_io_scalar_character(
          as.character(backend_result$response[[1L]])
        ))
      }

      if (is.list(backend_result) && !is.null(backend_result$response)) {
        return(.nail_io_scalar_character(
          as.character(backend_result$response[[1L]])
        ))
      }

      .nail_io_scalar_character(backend_result)
    })

    keep <- !vapply(out, is.null, logical(1))
    out <- out[keep]

    if (length(out) == 0L) {
      return(NULL)
    }

    return(out)
  }

  NULL
}

.nail_io_units_from_list <- function(x, field) {
  if (!is.list(x) || is.data.frame(x) || length(x) == 0L) {
    return(NULL)
  }

  # A non-isolated historical result can itself be a list with
  # $prompt / $response / $model.
  direct <- .nail_io_scalar_character(x[[field]])
  if (!is.null(direct)) {
    return(list(`1` = direct))
  }

  out <- vector("list", length(x))
  names(out) <- names(x)

  for (i in seq_along(x)) {
    item <- x[[i]]
    value <- NULL

    if (is.data.frame(item)) {
      extracted <- .nail_io_units_from_data_frame(item, field)
      if (!is.null(extracted) && length(extracted) > 0L) {
        value <- extracted[[1L]]
      }
    } else if (is.list(item)) {
      value <- .nail_io_scalar_character(item[[field]])

      if (is.null(value) &&
          !is.null(item$backend_result) &&
          identical(field, "response")) {
        backend <- item$backend_result
        if (is.data.frame(backend) &&
            "response" %in% names(backend) &&
            nrow(backend) > 0L) {
          value <- .nail_io_scalar_character(
            as.character(backend$response[[1L]])
          )
        }
      }
    } else if (identical(field, "prompt")) {
      # Preview objects returned in isolated mode are commonly named lists
      # whose elements are the exact prompt strings.
      value <- .nail_io_scalar_character(item)
    }

    out[[i]] <- value
  }

  keep <- !vapply(out, is.null, logical(1))
  out <- out[keep]

  if (length(out) == 0L) {
    return(NULL)
  }

  if (is.null(names(out)) || any(!nzchar(names(out)))) {
    names(out) <- as.character(seq_along(out))
  }

  out
}

.nail_io_extract_units <- function(x, field = c("prompt", "response")) {
  field <- match.arg(field)

  # Canonical future contract. Rebuilt NaileR functions should store their
  # current-stage LLM interaction here, independently of their analytical
  # result structure.
  units <- .nail_io_from_canonical(x, field)
  if (!is.null(units)) {
    return(units)
  }

  # Compatibility adapters below are intentionally secondary. They allow
  # current/historical NaileR objects to use the same public UX while those
  # analytical functions are progressively rebuilt around the canonical
  # evidence-first architecture.

  # PASS 2 has its own current-stage prompt/response. This must take precedence
  # over the preserved PASS 1 semantic profiles stored inside the object.
  units <- .nail_io_units_from_ground(x, field)
  if (!is.null(units)) {
    return(units)
  }

  # PASS 1 nail_catdes() stores the exact local prompts and responses here.
  # Prefer these over any combined historical outer representation.
  units <- .nail_io_units_from_semantic_profiles(x, field)
  if (!is.null(units)) {
    return(units)
  }

  if (is.data.frame(x)) {
    units <- .nail_io_units_from_data_frame(x, field)
    if (!is.null(units)) {
      return(units)
    }
  }

  if (is.list(x)) {
    units <- .nail_io_units_from_list(x, field)
    if (!is.null(units)) {
      return(units)
    }
  }

  if (identical(field, "prompt")) {
    direct <- .nail_io_scalar_character(x)
    if (!is.null(direct)) {
      return(list(`1` = direct))
    }
  }

  NULL
}

.nail_io_select_units <- function(units, select, what) {
  if (is.null(units) || length(units) == 0L) {
    if (identical(what, "response")) {
      stop(
        paste(
          "No LLM response is available in this object.",
          "Run the analysis with `generate = TRUE` before calling `nail_response()`."
        ),
        call. = FALSE
      )
    }

    stop(
      "No stored LLM prompt could be found in this object.",
      call. = FALSE
    )
  }

  if (is.null(names(units)) || any(!nzchar(names(units)))) {
    names(units) <- as.character(seq_along(units))
  }

  select <- .nail_io_normalize_select(select)

  if (is.null(select)) {
    return(units)
  }

  if (is.integer(select)) {
    if (select > length(units)) {
      stop(
        sprintf(
          "`select = %d` is out of range; %d %s(s) are available.",
          select,
          length(units),
          what
        ),
        call. = FALSE
      )
    }
    return(units[select])
  }

  if (!select %in% names(units)) {
    stop(
      paste0(
        "Unknown `select = \"", select, "\"`. Available names are: ",
        paste(sprintf('"%s"', names(units)), collapse = ", "),
        "."
      ),
      call. = FALSE
    )
  }

  units[select]
}

.nail_io_display_units <- function(units, what) {
  if (length(units) == 1L) {
    cat(units[[1L]])
    if (!grepl("\n$", units[[1L]])) {
      cat("\n")
    }
    return(invisible(NULL))
  }

  for (i in seq_along(units)) {
    if (i > 1L) {
      cat("\n")
    }

    cat(
      "===== NaileR ", what, ": ", names(units)[[i]], " =====\n\n",
      sep = ""
    )
    cat(units[[i]])
    if (!grepl("\n$", units[[i]])) {
      cat("\n")
    }
  }

  invisible(NULL)
}

.nail_io_public <- function(x, field, select, print) {
  .nail_io_assert_print(print)

  units <- .nail_io_extract_units(x, field = field)
  units <- .nail_io_select_units(units, select = select, what = field)

  value <- if (length(units) == 1L) {
    units[[1L]]
  } else {
    units
  }

  if (isTRUE(print)) {
    .nail_io_display_units(units, what = field)
    return(invisible(value))
  }

  value
}

#' Inspect the LLM prompt or response stored by NaileR
#'
#' `nail_prompt()` and `nail_response()` provide a stable user-facing way to
#' inspect the dialogue between NaileR and a large language model, independently
#' of the internal structure used by a particular analysis function.
#'
#' `nail_prompt()` displays the exact prompt stored by the analysis object. When
#' an analysis uses several independent LLM calls, all available prompts are
#' displayed by default and one can be selected with `select`.
#'
#' `nail_response()` displays the raw response returned by the LLM for the
#' current analytical stage. It does not validate, reinterpret, summarize, or
#' modify that response. For example, on a result from `nail_catdes()` it shows
#' the PASS 1 semantic response, whereas on a result from
#' `nail_catdes_ground()` it shows the raw PASS 2 reviewer response before
#' parsing and epistemic validation.
#'
#' @param x An object returned by a NaileR function that builds an LLM prompt
#'   or generates an LLM response.
#' @param select Optional prompt/response selector. Use a name such as a group,
#'   product, or dimension identifier (for example `"1"` or `"Dim1"`), or a
#'   positive integer position. If `NULL`, all available items are displayed.
#' @param print Logical. If `TRUE` (default), print the selected content to the
#'   console and return it invisibly. If `FALSE`, return the exact stored content
#'   without printing.
#'
#' @return A character string when one item is selected, or a named list of
#'   character strings when several items are returned. With `print = TRUE`,
#'   the value is returned invisibly.
#'
#' @details
#' These helpers do not rebuild prompts and do not call an LLM. They only read
#' content already stored in the supplied object.
#'
#' The preferred internal contract for future/rebuilt NaileR analyses is a
#' canonical `llm_io` artifact containing the current analytical `stage`, the
#' exact `prompts`, the raw `responses`, and optional metadata. The public
#' functions deliberately hide that internal representation: users only need
#' `nail_prompt()` and `nail_response()`.
#'
#' Compatibility adapters remain available for current historical return
#' structures while `nail_condes()`, `nail_qda()`, `nail_textual()`, and other
#' analyses are progressively rebuilt around the evidence-first architecture.
#'
#' For `nail_catdes()`, the local semantic profiles take precedence over the
#' historical combined outer return shape, so `nail_prompt()` exposes the
#' actual local prompts used by the local-first architecture.
#'
#' @examples
#' data(iris)
#'
#' preview <- nail_catdes(
#'   iris,
#'   num.var = 5,
#'   interpretation_mode = "standard",
#'   isolate.groups = TRUE,
#'   generate = FALSE
#' )
#'
#' nail_prompt(preview, select = "setosa")
#'
#' # Retrieve without printing:
#' prompt_text <- nail_prompt(preview, select = 1, print = FALSE)
#'
#' \dontrun{
#' generated <- nail_catdes(
#'   iris,
#'   num.var = 5,
#'   interpretation_mode = "standard",
#'   isolate.groups = TRUE,
#'   generate = TRUE
#' )
#'
#' nail_response(generated, select = "setosa")
#' }
#'
#' @name nail_llm_io
NULL

#' @rdname nail_llm_io
#' @export
nail_prompt <- function(x, select = NULL, print = TRUE) {
  .nail_io_public(
    x = x,
    field = "prompt",
    select = select,
    print = print
  )
}

#' @rdname nail_llm_io
#' @export
nail_response <- function(x, select = NULL, print = TRUE) {
  .nail_io_public(
    x = x,
    field = "response",
    select = select,
    print = print
  )
}
