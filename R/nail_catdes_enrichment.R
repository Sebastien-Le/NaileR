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
  statistical_block <- .catdes_textual_evidence_block(
    semantic_facing_evidence = semantic_facing_evidence,
    group_names = group_names
  )

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

  normalize_blank_lines(paste(
    "# Introduction",
    introduction,
    "# Enrichment scope",
    group_scope,
    "# Canonical CATDES evidence",
    "The following statistical statements are the canonical CATDES evidence. They are not changed by this enrichment step:",
    statistical_block,
    "# Initial CATDES interpretation",
    "The following text is the raw output of the first LLM pass. It is a proposal, not a statistical fact:",
    response_block,
    "# Selected textual comments",
    "The following comments are raw observations from the same rows as the statistical analysis. Their TXT identifiers are stable references:",
    text_block,
    "# Enrichment task",
    paste(
      "Use the CATDES evidence as the statistical anchor and the selected comments as a supplementary source.",
      "Identify which aspects of the initial interpretation are confirmed, clarified, nuanced, or contradicted by the comments.",
      "Highlight heterogeneity, tensions, and limits of the selected comments.",
      "You may propose an interpretation that goes beyond a paraphrase of either source, but distinguish every such synthesis from a demonstrated statistical fact.",
      "Do not infer behaviour, motives, personality, or causality. Do not treat the initial LLM interpretation as ground truth.",
      sep = "\n"
    ),
    "# Output",
    paste(
      "Write a clear enrichment of the initial CATDES interpretation.",
      "Keep group identifiers and reference the supplied TXT identifiers when discussing comments.",
      "Separate confirmations, qualifications or contradictions from new interpretive hypotheses.",
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
#'   selected textual evidence, both passes, and their statuses.
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
