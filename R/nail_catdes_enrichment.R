# ---------------------------------------------------------------------------
# CATDES textual enrichment: preparation, prompts, and public inspection
# ---------------------------------------------------------------------------

.validate_catdes_textual_arguments <- function(dataset,
                                               x,
                                               num.var,
                                               num.textual,
                                               textual.sample,
                                               textual.seed) {
  if (is.null(num.textual)) {
    return(NULL)
  }

  if (!is.null(x)) {
    stop(
      paste(
        "`num.textual` requires the raw `dataset` interface.",
        "A prepared `x` object cannot be silently reconnected to textual rows."
      ),
      call. = FALSE
    )
  }

  if (!is.data.frame(dataset)) {
    stop("`num.textual` requires a raw data-frame `dataset`.", call. = FALSE)
  }

  if (!is.numeric(num.textual) || length(num.textual) != 1L ||
      is.na(num.textual) || !is.finite(num.textual) ||
      num.textual != as.integer(num.textual) ||
      num.textual < 1L || num.textual > ncol(dataset)) {
    stop(
      "`num.textual` must be one valid integer column index.",
      call. = FALSE
    )
  }

  num.textual <- as.integer(num.textual)
  if (is.null(num.var) || !is.numeric(num.var) || length(num.var) != 1L ||
      is.na(num.var) || !is.finite(num.var) ||
      num.var != as.integer(num.var)) {
    stop(
      "`num.var` must be one valid integer column index when `num.textual` is used.",
      call. = FALSE
    )
  }
  num.var <- as.integer(num.var)

  if (num.var == num.textual) {
    stop(
      "`num.var` and `num.textual` must refer to different columns.",
      call. = FALSE
    )
  }

  if (!is.numeric(textual.sample) || length(textual.sample) != 1L ||
      is.na(textual.sample) || !is.finite(textual.sample) ||
      textual.sample <= 0 || textual.sample > 1) {
    stop(
      "`textual.sample` must be a single numeric value in ]0, 1].",
      call. = FALSE
    )
  }

  if (!is.null(textual.seed)) {
    tryCatch(
      suppressWarnings(.with_preserved_seed(textual.seed, NULL)),
      error = function(error) {
        stop(
          paste0(
            "`textual.seed` must be NULL or a value accepted by `set.seed()`. ",
            conditionMessage(error)
          ),
          call. = FALSE
        )
      }
    )
  }

  group_values <- dataset[[num.var]]
  text_values <- as.character(dataset[[num.textual]])
  text_values[is.na(text_values)] <- ""

  if (all(is.na(group_values))) {
    stop("The grouping variable contains only missing values.", call. = FALSE)
  }
  if (!any(nzchar(trimws(text_values)))) {
    stop(
      "No non-empty textual responses were found in `num.textual`.",
      call. = FALSE
    )
  }

  list(
    num.var = num.var,
    num.textual = num.textual,
    textual.sample = as.numeric(textual.sample),
    textual.seed = textual.seed
  )
}

.prepare_catdes_statistical_dataset <- function(dataset, num.var, num.textual) {
  if (is.null(num.textual)) {
    return(list(dataset = dataset, num.var = num.var))
  }

  keep <- seq_len(ncol(dataset)) != num.textual
  statistical_dataset <- dataset[, keep, drop = FALSE]
  statistical_num_var <- num.var - as.integer(num.textual < num.var)

  list(
    dataset = statistical_dataset,
    num.var = statistical_num_var
  )
}

.catdes_textual_selected_registry <- function(textual_evidence,
                                              interpretation_input) {
  selected_ids <- unique(unlist(
    lapply(
      interpretation_input$groups,
      function(group) group$selected_text_ids
    ),
    use.names = FALSE
  ))

  registry <- textual_evidence$text_registry
  if (length(selected_ids) == 0L) {
    return(registry[0, , drop = FALSE])
  }

  positions <- match(selected_ids, registry$text_id)
  if (anyNA(positions)) {
    stop(
      "Internal error: a selected textual ID is absent from the text registry.",
      call. = FALSE
    )
  }

  registry[positions, , drop = FALSE]
}

.catdes_textual_evidence_block <- function(semantic_facing_evidence,
                                           group_names) {
  blocks <- vapply(group_names, function(group_name) {
    group <- semantic_facing_evidence$groups[[group_name]]
    paste0(
      "## Group \"", group_name, "\"\n\n",
      group$text
    )
  }, character(1))

  paste(blocks, collapse = "\n\n---\n\n")
}

.catdes_textual_prompt <- function(semantic_facing_evidence,
                                   textual_evidence,
                                   interpretation_input,
                                   first_response,
                                   introduction,
                                   group_names,
                                   isolate.groups) {
  text_block <- if (isTRUE(isolate.groups)) {
    .textual_group_data_block(
      textual_evidence = textual_evidence,
      interpretation_input = interpretation_input,
      group_name = group_names[[1L]]
    )
  } else {
    .textual_joint_data_block(
      textual_evidence = textual_evidence,
      interpretation_input = interpretation_input
    )
  }

  response_block <- if (is.null(first_response) ||
                        !nzchar(trimws(first_response))) {
    "<The initial CATDES interpretation is not available.>"
  } else {
    first_response
  }

  group_scope <- if (isTRUE(isolate.groups)) {
    paste0(
      "The enrichment concerns only group \"", group_names[[1L]], "\"."
    )
  } else {
    paste0(
      "The enrichment concerns the displayed groups: ",
      paste(sprintf('"%s"', group_names), collapse = ", "), "."
    )
  }

  # The statistical evidence remains in the CATDES result and its public
  # accessors. It is intentionally not retransmitted in this second prompt:
  # this pass confronts the first interpretation with the selected comments.
  normalize_blank_lines(paste(
    "# Introduction",
    introduction,
    "# Enrichment scope",
    group_scope,
    "# Initial CATDES interpretation",
    "The following text is the raw output of the first LLM pass. It is a proposal, not a statistical fact:",
    response_block,
    "# Selected textual comments",
    "The following comments are raw observations from the same rows as the statistical analysis. Their TXT identifiers are stable references:",
    text_block,
    "# Enrichment task",
    paste(
      "Treat the initial CATDES interpretation as a quantitative proposal to confront with the selected comments, not as ground truth.",
      "Identify which aspects of that proposal the comments support, specify, nuance, leave unaddressed, or appear to challenge.",
      "Make explicit what the comments add beyond the first interpretation, while distinguishing observations in the comments from interpretive hypotheses.",
      "Recognize common concerns and heterogeneity across the displayed groups when the supplied comments support them.",
      "An apparent contradiction between a comment and the first interpretation does not necessarily contradict the CATDES results; distinguish an individual comment, a textual pattern, and a statistical finding.",
      "The comments do not provide new CATDES statistics. Do not claim to verify statistics that are not supplied in this second prompt, and do not treat the absence of a textual contradiction as statistical confirmation.",
      "Do not infer behaviour, motives, personality, regional characteristics, or causality. Do not create artificial qualitative oppositions from quantitative group differences.",
      sep = "\n"
    ),
    "# Output",
    paste(
      "Write a clear quantitative/qualitative confrontation of the initial CATDES interpretation.",
      "Keep group identifiers and cite the supplied TXT identifiers when discussing comments.",
      "Separate comment-supported observations, qualifications or apparent tensions from new interpretive hypotheses.",
      "Preserve uncertainty, disagreement and limits in the comments rather than forcing a single coherent portrait.",
      sep = "\n"
    ),
    sep = "\n\n---\n\n"
  ))
}

.catdes_textual_first_responses <- function(local_results,
                                            result,
                                            interpretation_evidence,
                                            isolate.groups,
                                            n_selected) {
  if (isTRUE(isolate.groups)) {
    groups <- names(interpretation_evidence$groups)
    out <- stats::setNames(vector("list", length(groups)), groups)
    for (group_name in groups) {
      if (!identical(
        interpretation_evidence$groups[[group_name]]$status,
        "ready"
      )) {
        next
      }
      out[[group_name]] <- .catdes_backend_response_text(
        local_results[[group_name]]
      )
    }
    return(out)
  }

  if (n_selected <= 0L) {
    return(list(portfolio = NULL))
  }

  list(portfolio = .catdes_backend_response_text(result))
}

.new_catdes_textual_enrichment <- function(
    textual_evidence,
    interpretation_input,
    selected_texts,
    semantic_facing_evidence,
    interpretation_evidence,
    num.textual,
    first_prompts,
    first_responses,
    isolate.groups,
    textual.sample,
    textual.seed,
    generate,
    second_prompts = NULL,
    second_responses = NULL,
    second_status = NULL,
    second_errors = NULL) {
  group_names <- names(interpretation_input$groups)

  first_status <- stats::setNames(
    vapply(group_names, function(group_name) {
      if (!isTRUE(generate)) {
        return("prompt_ready")
      }
      response <- first_responses[[group_name]]
      if (is.null(response) || !nzchar(trimws(response))) {
        return("generation_missing")
      }
      "generated"
    }, character(1)),
    group_names
  )

  if (!isTRUE(isolate.groups)) {
    first_status <- stats::setNames(
      if (!isTRUE(generate)) "prompt_ready" else if (
        is.null(first_responses$portfolio) ||
          !nzchar(trimws(first_responses$portfolio))
      ) "generation_missing" else "generated",
      "portfolio"
    )
  }

  first_pass <- list(
    prompts = first_prompts,
    responses = if (isTRUE(generate)) first_responses else NULL,
    status = first_status,
    scope = if (isTRUE(isolate.groups)) "group" else "portfolio"
  )

  if (is.null(second_status)) {
    second_status <- if (isTRUE(generate)) {
      if (isTRUE(isolate.groups)) {
        stats::setNames(rep("pending", length(group_names)), group_names)
      } else {
        stats::setNames("pending", "portfolio")
      }
    } else {
      if (isTRUE(isolate.groups)) {
        stats::setNames(rep("pending_first_pass", length(group_names)), group_names)
      } else {
        stats::setNames("pending_first_pass", "portfolio")
      }
    }
  }

  out <- list(
    statistical_evidence = interpretation_evidence,
    statistical_semantic_evidence = semantic_facing_evidence,
    textual_evidence = textual_evidence,
    interpretation_input = interpretation_input,
    selected_texts = selected_texts,
    first_pass = first_pass,
    second_pass = list(
      prompts = second_prompts,
      responses = second_responses,
      status = second_status,
      errors = second_errors,
      scope = if (isTRUE(isolate.groups)) "group" else "portfolio"
    ),
    settings = list(
      num_textual = as.integer(num.textual),
      textual_variable = textual_evidence$settings$text_variable,
      textual_sample = textual.sample,
      textual_seed = textual.seed,
      isolate_groups = isolate.groups,
      architecture = if (isTRUE(isolate.groups)) "local_two_pass" else "joint_two_pass",
      generate = generate,
      second_prompt_requires_first_response = TRUE
    ),
    metadata = list(
      schema = "NaileR::catdes_textual_enrichment",
      schema_version = "0.1.0",
      n_groups = as.integer(length(group_names)),
      n_selected_texts = as.integer(nrow(selected_texts)),
      n_first_pass_responses = as.integer(sum(
        vapply(first_responses, function(x) {
          is.character(x) && length(x) == 1L && nzchar(trimws(x))
        },
        logical(1)
      ))),
      n_second_pass_responses = as.integer(if (is.null(second_responses)) {
        0L
      } else {
        sum(vapply(second_responses, function(x) {
          is.character(x) && length(x) == 1L && nzchar(trimws(x))
        }, logical(1)))
      })
    )
  )

  class(out) <- c("nail_catdes_textual_enrichment", "list")
  out
}

.prepare_catdes_textual_enrichment <- function(dataset,
                                               num.var,
                                               num.textual,
                                               textual.sample,
                                               textual.seed) {
  textual_evidence <- .build_textual_evidence(
    dataset = dataset,
    num.var = num.var,
    num.text = num.textual
  )
  interpretation_input <- .build_textual_interpretation_input(
    textual_evidence = textual_evidence,
    sample.pct = textual.sample,
    seed = textual.seed
  )

  list(
    textual_evidence = textual_evidence,
    interpretation_input = interpretation_input,
    selected_texts = .catdes_textual_selected_registry(
      textual_evidence,
      interpretation_input
    )
  )
}

.run_catdes_textual_enrichment <- function(prepared,
                                           semantic_facing_evidence,
                                           interpretation_evidence,
                                           num.textual,
                                           first_prompts,
                                           first_responses,
                                           introduction,
                                           isolate.groups,
                                           textual.sample,
                                           textual.seed,
                                           provider,
                                           model,
                                           llm_api_options) {
  group_names <- names(prepared$interpretation_input$groups)
  second_prompts <- list()
  second_responses <- list()
  second_status <- character(0)
  second_errors <- list()

  if (isTRUE(isolate.groups)) {
    for (group_name in group_names) {
      input_group <- prepared$interpretation_input$groups[[group_name]]
      first_response <- first_responses[[group_name]]
      can_run <- identical(input_group$status, "ready") &&
        !is.null(first_response) && nzchar(trimws(first_response))

      if (!can_run) {
        second_status[[group_name]] <- if (
          !identical(input_group$status, "ready")
        ) "no_texts" else "first_pass_unavailable"
        next
      }

      prompt <- .catdes_textual_prompt(
        semantic_facing_evidence = semantic_facing_evidence,
        textual_evidence = prepared$textual_evidence,
        interpretation_input = prepared$interpretation_input,
        first_response = first_response,
        introduction = introduction,
        group_names = group_name,
        isolate.groups = TRUE
      )
      second_prompts[[group_name]] <- prompt

      value <- tryCatch(
        .call_llm_base(
          provider = provider,
          model = model,
          prompt = prompt,
          output = "df",
          llm_api_options = llm_api_options
        ),
        error = function(error) {
          second_errors[[group_name]] <<- conditionMessage(error)
          NULL
        }
      )
      response <- .catdes_backend_response_text(value)
      if (is.null(response) || !nzchar(trimws(response))) {
        second_status[[group_name]] <- "generation_failed"
      } else {
        second_responses[[group_name]] <- response
        second_status[[group_name]] <- "generated"
      }
    }
  } else {
    first_response <- first_responses$portfolio
    ready_text <- any(vapply(
      prepared$interpretation_input$groups,
      function(group) identical(group$status, "ready"),
      logical(1)
    ))

    if (!ready_text || is.null(first_response) || !nzchar(trimws(first_response))) {
      second_status <- stats::setNames(
        "first_pass_unavailable",
        "portfolio"
      )
    } else {
      prompt <- .catdes_textual_prompt(
        semantic_facing_evidence = semantic_facing_evidence,
        textual_evidence = prepared$textual_evidence,
        interpretation_input = prepared$interpretation_input,
        first_response = first_response,
        introduction = introduction,
        group_names = group_names,
        isolate.groups = FALSE
      )
      second_prompts$portfolio <- prompt

      value <- tryCatch(
        .call_llm_base(
          provider = provider,
          model = model,
          prompt = prompt,
          output = "df",
          llm_api_options = llm_api_options
        ),
        error = function(error) {
          second_errors$portfolio <<- conditionMessage(error)
          NULL
        }
      )
      response <- .catdes_backend_response_text(value)
      if (is.null(response) || !nzchar(trimws(response))) {
        second_status <- stats::setNames("generation_failed", "portfolio")
      } else {
        second_responses$portfolio <- response
        second_status <- stats::setNames("generated", "portfolio")
      }
    }
  }

  .new_catdes_textual_enrichment(
    textual_evidence = prepared$textual_evidence,
    interpretation_input = prepared$interpretation_input,
    selected_texts = prepared$selected_texts,
    semantic_facing_evidence = semantic_facing_evidence,
    interpretation_evidence = interpretation_evidence,
    num.textual = num.textual,
    first_prompts = first_prompts,
    first_responses = first_responses,
    isolate.groups = isolate.groups,
    textual.sample = textual.sample,
    textual.seed = textual.seed,
    generate = TRUE,
    second_prompts = if (length(second_prompts) > 0L) second_prompts else NULL,
    second_responses = if (length(second_responses) > 0L) second_responses else NULL,
    second_status = second_status,
    second_errors = if (length(second_errors) > 0L) second_errors else NULL
  )
}

#' Inspect the two-pass CATDES textual enrichment artifact
#'
#' @param x A result returned by [nail_catdes()] with `num.textual` set.
#' @return The canonical enrichment artifact containing the CATDES evidence,
#'   selected textual evidence, both passes, and their statuses. For a
#'   successful generated CATDES enrichment, [nail_prompt()] and
#'   [nail_response()] expose the second pass; use this accessor to inspect
#'   both passes and any errors. The second prompt confronts the first
#'   interpretation with the selected comments without retransmitting the
#'   detailed CATDES evidence, which remains in this artifact and in
#'   [nail_evidence()]. A preview has `pending_first_pass` status and no
#'   second-pass response.
#' @export
#' @examples
#' data(atomic_habit_clust, package = "NaileR")
#' preview <- nail_catdes(
#'   atomic_habit_clust,
#'   num.var = 51,
#'   num.textual = 31,
#'   generate = FALSE
#' )
#' nail_catdes_enrichment(preview)$second_pass$status
nail_catdes_enrichment <- function(x) {
  enrichment <- attr(x, "catdes_textual_enrichment", exact = TRUE)
  if (is.null(enrichment) ||
      !inherits(enrichment, "nail_catdes_textual_enrichment")) {
    stop(
      paste(
        "No CATDES textual enrichment is available.",
        "Run `nail_catdes()` with `num.textual` set."
      ),
      call. = FALSE
    )
  }
  enrichment
}

.catdes_retry_scalar_text <- function(value) {
  is.character(value) && length(value) == 1L &&
    !is.na(value) && nzchar(trimws(value))
}

.catdes_retry_validate_unit_list <- function(value, unit_names, label) {
  if (is.null(value)) {
    return(list())
  }
  if (!is.list(value)) {
    stop(
      sprintf("The stored CATDES `%s` must be a list.", label),
      call. = FALSE
    )
  }
  if (is.null(names(value)) || any(!nzchar(names(value)))) {
    stop(
      sprintf("The stored CATDES `%s` must have named units.", label),
      call. = FALSE
    )
  }
  unknown <- setdiff(names(value), unit_names)
  if (length(unknown) > 0L) {
    stop(
      sprintf(
        "The stored CATDES `%s` contains unknown unit(s): %s.",
        label,
        paste(unknown, collapse = ", ")
      ),
      call. = FALSE
    )
  }
  value
}

.catdes_retry_validate_state <- function(x) {
  enrichment <- attr(x, "catdes_textual_enrichment", exact = TRUE)
  if (is.null(enrichment) ||
      !inherits(enrichment, "nail_catdes_textual_enrichment")) {
    stop(
      paste(
        "`x` must be a CATDES result with textual enrichment.",
        "Run `nail_catdes()` with `num.textual` set and `generate = TRUE`."
      ),
      call. = FALSE
    )
  }

  settings <- enrichment$settings
  if (!is.list(settings) || !isTRUE(settings$generate)) {
    stop(
      "CATDES enrichment retry requires a generated first pass.",
      call. = FALSE
    )
  }
  isolate_groups <- isTRUE(settings$isolate_groups)
  interpretation_input <- enrichment$interpretation_input
  if (!is.list(interpretation_input) ||
      !is.list(interpretation_input$groups) ||
      is.null(names(interpretation_input$groups)) ||
      any(!nzchar(names(interpretation_input$groups)))) {
    stop(
      "The stored CATDES textual interpretation input is incomplete.",
      call. = FALSE
    )
  }

  group_names <- names(interpretation_input$groups)
  unit_names <- if (isolate_groups) group_names else "portfolio"
  first_pass <- enrichment$first_pass
  second_pass <- enrichment$second_pass
  if (!is.list(first_pass) || !is.list(second_pass)) {
    stop(
      "The stored CATDES two-pass enrichment is incomplete.",
      call. = FALSE
    )
  }

  first_status <- first_pass$status
  if (!is.character(first_status) ||
      is.null(names(first_status)) ||
      !identical(names(first_status), unit_names) ||
      !all(!is.na(first_status) & first_status == "generated")) {
    stop(
      "CATDES enrichment retry requires generated first-pass responses for every unit.",
      call. = FALSE
    )
  }
  first_responses <- .catdes_retry_validate_unit_list(
    first_pass$responses,
    unit_names,
    "first_pass$responses"
  )
  if (!all(vapply(
    unit_names,
    function(name) .catdes_retry_scalar_text(first_responses[[name]]),
    logical(1)
  ))) {
    stop(
      "CATDES enrichment retry requires a non-empty first-pass response for every unit.",
      call. = FALSE
    )
  }

  status <- second_pass$status
  if (!is.character(status) ||
      is.null(names(status)) ||
      !identical(names(status), unit_names)) {
    stop(
      "The stored CATDES second-pass statuses are incomplete or unnamed.",
      call. = FALSE
    )
  }
  known_statuses <- c(
    "generated", "generation_failed", "pending", "pending_first_pass",
    "first_pass_unavailable", "no_texts"
  )
  invalid_status <- is.na(status) | !nzchar(status) |
    !(status %in% known_statuses)
  if (any(invalid_status)) {
    stop(
      paste0(
        "The stored CATDES second-pass status contains missing or invalid values: ",
        paste(names(status)[invalid_status], collapse = ", "), "."
      ),
      call. = FALSE
    )
  }
  if (any(status %in% c("pending_first_pass", "first_pass_unavailable"))) {
    stop(
      "CATDES enrichment retry cannot start before the first pass is complete.",
      call. = FALSE
    )
  }

  prompts <- .catdes_retry_validate_unit_list(
    second_pass$prompts,
    unit_names,
    "second_pass$prompts"
  )
  responses <- .catdes_retry_validate_unit_list(
    second_pass$responses,
    unit_names,
    "second_pass$responses"
  )
  errors <- .catdes_retry_validate_unit_list(
    second_pass$errors,
    unit_names,
    "second_pass$errors"
  )

  generated_units <- names(status)[status == "generated"]
  if (length(generated_units) > 0L) {
    if (!all(generated_units %in% names(prompts)) ||
        !all(generated_units %in% names(responses)) ||
        !all(vapply(
          generated_units,
          function(name) {
            .catdes_retry_scalar_text(prompts[[name]]) &&
              .catdes_retry_scalar_text(responses[[name]])
          },
          logical(1)
        ))) {
      stop(
        "The stored generated CATDES second-pass units are incomplete.",
        call. = FALSE
      )
    }
  }

  eligible <- names(status)[status %in% c("generation_failed", "pending")]
  if (length(eligible) > 0L) {
    if (!all(eligible %in% names(prompts)) ||
        !all(vapply(
          eligible,
          function(name) .catdes_retry_scalar_text(prompts[[name]]),
          logical(1)
        ))) {
      stop(
        "Every retryable CATDES second-pass unit must have a saved non-empty prompt.",
        call. = FALSE
      )
    }
    ambiguous <- eligible[eligible %in% names(responses)]
    if (length(ambiguous) > 0L && any(vapply(
      ambiguous,
      function(name) .catdes_retry_scalar_text(responses[[name]]),
      logical(1)
    ))) {
      stop(
        "A retryable CATDES unit already has a response but is not marked generated.",
        call. = FALSE
      )
    }
  }

  list(
    enrichment = enrichment,
    isolate_groups = isolate_groups,
    unit_names = unit_names,
    status = status,
    prompts = prompts,
    responses = responses,
    errors = errors,
    eligible = eligible
  )
}

#' Retry failed CATDES textual-enrichment second passes
#'
#' Retry only the saved CATDES textual-enrichment second-pass units that are
#' not already marked `generated`. The first CATDES pass, the CATDES evidence,
#' the textual registry, the selected comments and all saved prompts are reused
#' without reconstruction. Provider retry behavior remains controlled by the
#' options passed in `...`; this function adds no hidden retry loop.
#'
#' @param x A generated result returned by [nail_catdes()] with `num.textual`
#'   set and with the second-pass artifact attached.
#' @param provider Optional provider override. By default the provider saved in
#'   `attr(x, "catdes_settings")` is used. An explicit replacement is allowed
#'   and is recorded in the retry history.
#' @param model Optional model override. By default the model saved in
#'   `attr(x, "catdes_settings")` is used. An explicit replacement is allowed
#'   and is recorded in the retry history. If an explicit provider replacement
#'   is supplied without a model, that provider's default model is used.
#' @param ... Provider-specific options passed unchanged to the existing
#'   backend, such as `max_tries`, `timeout` and `max_output_tokens`. Do not
#'   pass `textual.seed` or other CATDES parameters. These options control the
#'   retry call and need not be the options used for the initial generation.
#'
#' @return `x` with the same class, statistical attributes and textual
#'   evidence, but with eligible second-pass responses and statuses updated.
#'   Original errors remain available in `second_pass$errors`; retry attempts
#'   are recorded in `second_pass$retry_history` and
#'   `second_pass$error_history`.
#' @export
#' @examples
#' \dontrun{
#' retry <- nail_catdes_enrichment_retry(
#'   generated,
#'   max_tries = 1L,
#'   timeout = 90,
#'   max_output_tokens = 8192L
#' )
#' nail_response(retry, print = FALSE)
#' nail_catdes_enrichment(retry)$second_pass$retry_history
#' }
nail_catdes_enrichment_retry <- function(x,
                                        provider = NULL,
                                        model = NULL,
                                        ...) {
  state <- .catdes_retry_validate_state(x)
  catdes_settings <- attr(x, "catdes_settings", exact = TRUE)
  if (!is.list(catdes_settings)) {
    stop(
      "The CATDES result does not contain saved backend settings.",
      call. = FALSE
    )
  }
  provider_supplied <- !is.null(provider)
  if (is.null(provider)) provider <- catdes_settings$provider
  if (!is.character(provider) || length(provider) != 1L ||
      is.na(provider) || !nzchar(provider)) {
    stop("A provider must be saved in `x` or supplied explicitly.", call. = FALSE)
  }
  provider <- .match_llm_provider(provider)
  if (is.null(model)) {
    model <- if (isTRUE(provider_supplied)) {
      .default_llm_model(provider)
    } else {
      catdes_settings$model
    }
  }
  if (!is.character(model) || length(model) != 1L ||
      is.na(model) || !nzchar(model)) {
    stop("A model must be saved in `x` or supplied explicitly.", call. = FALSE)
  }

  llm_api_options <- list(...)
  .validate_llm_api_options(llm_api_options, provider)

  if (length(state$eligible) == 0L) {
    return(x)
  }

  enrichment <- state$enrichment
  second_pass <- enrichment$second_pass
  responses <- state$responses
  status <- state$status
  errors <- state$errors
  error_history <- second_pass$error_history
  if (is.null(error_history)) {
    error_history <- lapply(errors, function(error) {
      if (is.null(error)) character(0) else as.character(error)
    })
  }
  if (!is.list(error_history)) {
    stop(
      "The stored CATDES second-pass error history is malformed.",
      call. = FALSE
    )
  }
  retry_history <- second_pass$retry_history
  if (is.null(retry_history)) retry_history <- list()
  if (!is.list(retry_history)) {
    stop(
      "The stored CATDES second-pass retry history is malformed.",
      call. = FALSE
    )
  }

  for (unit_name in state$eligible) {
    previous_status <- status[[unit_name]]
    previous_error <- errors[[unit_name]]
    prompt <- state$prompts[[unit_name]]
    started_at <- Sys.time()
    error_message <- NULL
    value <- tryCatch(
      .call_llm_base(
        provider = provider,
        model = model,
        prompt = prompt,
        output = "df",
        llm_api_options = llm_api_options
      ),
      error = function(error) {
        error_message <<- conditionMessage(error)
        NULL
      }
    )
    finished_at <- Sys.time()
    response <- .catdes_backend_response_text(value)
    retry_status <- if (.catdes_retry_scalar_text(response)) {
      "generated"
    } else {
      "generation_failed"
    }
    status[[unit_name]] <- retry_status
    if (identical(retry_status, "generated")) {
      responses[[unit_name]] <- response
    } else {
      if (is.null(error_message)) {
        error_message <- "The retry backend returned an empty response."
      }
      if (is.null(errors[[unit_name]])) {
        errors[[unit_name]] <- error_message
      }
      error_history[[unit_name]] <- c(
        error_history[[unit_name]],
        error_message
      )
    }

    retry_history[[length(retry_history) + 1L]] <- list(
      unit = unit_name,
      previous_status = previous_status,
      previous_error = previous_error,
      status = retry_status,
      error = error_message,
      provider = provider,
      model = model,
      prompt_characters = nchar(prompt),
      prompt_bytes = nchar(prompt, type = "bytes"),
      started_at = started_at,
      finished_at = finished_at,
      elapsed_seconds = as.numeric(
        difftime(finished_at, started_at, units = "secs")
      )
    )
  }

  second_pass$prompts <- state$prompts
  second_pass$responses <- if (length(responses) > 0L) responses else NULL
  second_pass$status <- status
  second_pass$errors <- if (length(errors) > 0L) errors else NULL
  second_pass$error_history <- if (length(error_history) > 0L) {
    error_history
  } else {
    NULL
  }
  second_pass$retry_history <- retry_history
  enrichment$second_pass <- second_pass
  enrichment$metadata$n_second_pass_responses <- sum(vapply(
    responses,
    .catdes_retry_scalar_text,
    logical(1)
  ))
  enrichment$metadata$n_retry_attempts <- length(retry_history)
  enrichment$metadata$last_retry_provider <- provider
  enrichment$metadata$last_retry_model <- model
  enrichment$settings$last_retry_provider <- provider
  enrichment$settings$last_retry_model <- model
  enrichment$settings$last_retry_option_names <- setdiff(
    names(llm_api_options),
    "api_key"
  )

  out <- x
  attr(out, "catdes_textual_enrichment") <- enrichment

  updated_catdes_settings <- catdes_settings
  prior_retry_calls <- updated_catdes_settings$second_pass_retry_llm_calls
  if (!is.numeric(prior_retry_calls) || length(prior_retry_calls) != 1L ||
      is.na(prior_retry_calls)) {
    prior_retry_calls <- 0L
  }
  updated_catdes_settings$second_pass_retry_llm_calls <- as.integer(
    prior_retry_calls + length(state$eligible)
  )
  original_calls <- updated_catdes_settings$llm_calls
  if (is.numeric(original_calls) && length(original_calls) == 1L &&
      !is.na(original_calls)) {
    updated_catdes_settings$llm_calls_including_retries <- as.integer(
      original_calls + updated_catdes_settings$second_pass_retry_llm_calls
    )
  }
  attr(out, "catdes_settings") <- updated_catdes_settings
  out
}
