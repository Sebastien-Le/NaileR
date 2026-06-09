#' @importFrom dplyr filter arrange desc mutate
#' @importFrom glue glue
#' @importFrom knitr kable
#' @importFrom tibble rownames_to_column
#' @importFrom utils globalVariables
#' @importFrom FactoMineR catdes
utils::globalVariables(c(".data", "abs_vtest"))

# ---------------------------------------------------------------------------
# Validation
# ---------------------------------------------------------------------------

validate_group_profile_prep_inputs <- function(x = NULL,
                                               dataset = NULL,
                                               num.var = NULL,
                                               proba = 0.05,
                                               sample.pct = 1,
                                               prompt_style = c("compact", "detailed"),
                                               generate = FALSE,
                                               profile_mode = c("balanced", "categorical", "quantitative")) {
  prompt_style <- match.arg(prompt_style)
  profile_mode <- match.arg(profile_mode)

  if (is.null(x) && is.null(dataset)) {
    stop("You must provide either `x` or `dataset`.", call. = FALSE)
  }

  if (!is.null(dataset)) {
    if (!is.data.frame(dataset)) {
      stop("`dataset` must be a data frame.", call. = FALSE)
    }

    if (ncol(dataset) < 2) {
      stop("`dataset` must contain at least two columns.", call. = FALSE)
    }

    if (is.null(num.var)) {
      stop("When `dataset` is provided, `num.var` must also be provided.", call. = FALSE)
    }

    if (!is.numeric(num.var) || length(num.var) != 1 || is.na(num.var) ||
        num.var < 1 || num.var > ncol(dataset)) {
      stop("`num.var` must be a single valid column index.", call. = FALSE)
    }
  }

  if (!is.numeric(proba) || length(proba) != 1 || is.na(proba) ||
      proba <= 0 || proba > 1) {
    stop("`proba` must be a single numeric value in ]0, 1].", call. = FALSE)
  }

  if (!is.numeric(sample.pct) || length(sample.pct) != 1 || is.na(sample.pct) ||
      sample.pct <= 0 || sample.pct > 1) {
    stop("`sample.pct` must be a single numeric value in ]0, 1].", call. = FALSE)
  }

  if (!is.logical(generate) || length(generate) != 1 || is.na(generate)) {
    stop("`generate` must be a single non-missing logical value.", call. = FALSE)
  }

  invisible(TRUE)
}

# ---------------------------------------------------------------------------
# Helpers
# ---------------------------------------------------------------------------

.group_profile_strength_label <- function(n_quanti = 0, n_quali = 0) {
  n_total <- n_quanti + n_quali

  if (n_total >= 10) return("strong")
  if (n_total >= 5) return("moderate")
  if (n_total >= 1) return("weak")
  "very weak"
}

.sample_profile_rows <- function(df, sample.pct = 1, score_col = "v.test") {
  if (is.null(df) || nrow(df) == 0) return(df)
  if (sample.pct >= 1) return(df)

  n_keep <- max(1, round(nrow(df) * sample.pct))

  if (!is.null(score_col) && score_col %in% colnames(df)) {
    df <- df |>
      dplyr::mutate(abs_vtest = abs(.data[[score_col]])) |>
      dplyr::arrange(dplyr::desc(.data$abs_vtest))

    out <- utils::head(df, n_keep)
    out$abs_vtest <- NULL
    return(out)
  }

  utils::head(df, n_keep)
}

.format_profile_table <- function(df) {
  knitr::kable(
    df,
    digits = 2,
    format = "pipe",
    align = c("l", rep("r", ncol(df) - 1))
  )
}

.get_all_group_names <- function(quanti_list, quali_list) {
  unique(c(names(quanti_list), names(quali_list)))
}

# ---------------------------------------------------------------------------
# Extraction of catdes inputs
# ---------------------------------------------------------------------------

.extract_group_profile_inputs <- function(x = NULL,
                                          dataset = NULL,
                                          num.var = NULL,
                                          proba = 0.05,
                                          row.w = NULL) {
  if (!is.null(x)) {
    # future-proof if you later add attributes to nail_catdes
    catdes_result <- attr(x, "catdes_result", exact = TRUE)
    if (!is.null(catdes_result)) {
      return(list(catdes_result = catdes_result))
    }

    # raw catdes result
    if (inherits(x, "catdes") || (is.list(x) && ("category" %in% names(x) || "quanti" %in% names(x)))) {
      return(list(catdes_result = x))
    }

    stop(
      paste(
        "`x` does not look like a raw `catdes` result.",
        "Your current `nail_catdes()` does not attach `catdes_result`,",
        "so `x = nail_catdes(...)` cannot be reused automatically yet."
      ),
      call. = FALSE
    )
  }

  res_cd <- FactoMineR::catdes(dataset, num.var = num.var, proba = proba, row.w = row.w)
  list(catdes_result = res_cd)
}

# ---------------------------------------------------------------------------
# Standardized extraction from real catdes result
# ---------------------------------------------------------------------------

.extract_quanti_profiles <- function(catdes_result) {
  if (!"quanti" %in% names(catdes_result) || is.null(catdes_result$quanti)) {
    return(list())
  }

  out <- catdes_result$quanti
  if (!is.list(out)) return(list())

  res <- vector("list", length(out))
  names(res) <- names(out)

  for (i in seq_along(out)) {
    df <- as.data.frame(out[[i]], check.names = FALSE, stringsAsFactors = FALSE)

    if (nrow(df) == 0) {
      res[[i]] <- NULL
      next
    }

    df <- tibble::rownames_to_column(df, var = "Variable")

    # expected names from your catdes():
    # v.test, Mean in category, Overall mean, sd in category, Overall sd, p.value
    res[[i]] <- df
  }

  res[!vapply(res, is.null, logical(1))]
}

.extract_quali_profiles <- function(catdes_result) {
  if (!"category" %in% names(catdes_result) || is.null(catdes_result$category)) {
    return(list())
  }

  out <- catdes_result$category
  if (!is.list(out)) return(list())

  res <- vector("list", length(out))
  names(res) <- names(out)

  for (i in seq_along(out)) {
    df <- as.data.frame(out[[i]], check.names = FALSE, stringsAsFactors = FALSE)

    if (nrow(df) == 0) {
      res[[i]] <- NULL
      next
    }

    df <- tibble::rownames_to_column(df, var = "Modality")

    # expected names from your catdes():
    # Cla/Mod, Mod/Cla, Global, p.value, v.test
    res[[i]] <- df
  }

  res[!vapply(res, is.null, logical(1))]
}

# ---------------------------------------------------------------------------
# Mechanical summary object
# ---------------------------------------------------------------------------

.summarize_group_profiles_mechanical <- function(catdes_result,
                                                 top_n_quanti = 5,
                                                 top_n_quali = 5) {
  quanti_list <- .extract_quanti_profiles(catdes_result)
  quali_list  <- .extract_quali_profiles(catdes_result)

  all_groups <- .get_all_group_names(quanti_list, quali_list)
  out <- list()

  for (grp in all_groups) {
    quanti_df <- quanti_list[[grp]]
    quali_df  <- quali_list[[grp]]

    quanti_vars <- character(0)
    quali_mods  <- character(0)

    if (!is.null(quanti_df) && nrow(quanti_df) > 0) {
      quanti_df <- quanti_df |>
        dplyr::mutate(abs_vtest = abs(.data$v.test)) |>
        dplyr::arrange(dplyr::desc(.data$abs_vtest))

      quanti_vars <- utils::head(quanti_df$Variable, top_n_quanti)
    }

    if (!is.null(quali_df) && nrow(quali_df) > 0) {
      quali_df <- quali_df |>
        dplyr::mutate(abs_vtest = abs(.data$v.test)) |>
        dplyr::arrange(dplyr::desc(.data$abs_vtest))

      quali_mods <- utils::head(quali_df$Modality, top_n_quali)
    }

    out[[grp]] <- list(
      salient_quantitative_traits = quanti_vars,
      salient_categorical_traits = quali_mods,
      n_quanti = length(quanti_vars),
      n_quali = length(quali_mods),
      profile_strength = .group_profile_strength_label(
        n_quanti = length(quanti_vars),
        n_quali = length(quali_mods)
      )
    )
  }

  out
}

# ---------------------------------------------------------------------------
# Sentences
# ---------------------------------------------------------------------------

get_sentences_group_profile <- function(catdes_result,
                                        sample.pct = 1,
                                        profile_mode = c("balanced", "categorical", "quantitative")) {
  profile_mode <- match.arg(profile_mode)

  quanti_list <- .extract_quanti_profiles(catdes_result)
  quali_list  <- .extract_quali_profiles(catdes_result)
  all_groups  <- .get_all_group_names(quanti_list, quali_list)

  out <- list()

  for (grp in all_groups) {
    quanti_df <- quanti_list[[grp]]
    quali_df  <- quali_list[[grp]]

    blocks <- c()

    if (profile_mode %in% c("balanced", "quantitative")) {
      if (!is.null(quanti_df) && nrow(quanti_df) > 0) {
        keep_cols <- c("Variable", "Mean in category", "Overall mean", "p.value", "v.test")
        keep_cols <- keep_cols[keep_cols %in% colnames(quanti_df)]

        quanti_df2 <- quanti_df[, keep_cols, drop = FALSE]
        quanti_df2 <- .sample_profile_rows(quanti_df2, sample.pct = sample.pct, score_col = "v.test")

        txt <- paste(
          "### Quantitative markers",
          "",
          paste(.format_profile_table(quanti_df2), collapse = "\n"),
          sep = "\n"
        )
        blocks <- c(blocks, txt)
      }
    }

    if (profile_mode %in% c("balanced", "categorical")) {
      if (!is.null(quali_df) && nrow(quali_df) > 0) {
        keep_cols <- c("Modality", "Cla/Mod", "Mod/Cla", "Global", "p.value", "v.test")
        keep_cols <- keep_cols[keep_cols %in% colnames(quali_df)]

        quali_df2 <- quali_df[, keep_cols, drop = FALSE]
        quali_df2 <- .sample_profile_rows(quali_df2, sample.pct = sample.pct, score_col = "v.test")

        txt <- paste(
          "### Categorical markers",
          "",
          paste(.format_profile_table(quali_df2), collapse = "\n"),
          sep = "\n"
        )
        blocks <- c(blocks, txt)
      }
    }

    if (length(blocks) == 0) {
      out[[grp]] <- "This group has **no retained statistical descriptors** under the current analysis settings."
    } else {
      out[[grp]] <- paste(blocks, collapse = "\n\n")
    }
  }

  out
}

# ---------------------------------------------------------------------------
# Prompt builders
# ---------------------------------------------------------------------------

build_guide_group_profile_prep <- function(proba = 0.05,
                                           profile_mode = c("balanced", "categorical", "quantitative"),
                                           prompt_style = c("compact", "detailed")) {
  profile_mode <- match.arg(profile_mode)
  prompt_style <- match.arg(prompt_style)

  mode_txt <- switch(
    profile_mode,
    balanced = "The results may include both quantitative and categorical descriptors of the group.",
    categorical = "The interpretation should focus primarily on categorical descriptors of the group.",
    quantitative = "The interpretation should focus primarily on quantitative descriptors of the group."
  )

  if (prompt_style == "compact") {
    return(paste(
      "## How to Read the Results",
      "The tables below describe what statistically characterizes each group under the current analysis settings.",
      paste0("Only retained descriptors are shown here (current threshold: p <= ", proba, ")."),
      mode_txt,
      "Use these retained descriptors to summarize the relative profile of the group.",
      "Do not invent causal explanations.",
      sep = "\n"
    ))
  }

  paste(
    "## How to Read the Results",
    "The tables below describe what statistically characterizes each group under the current analysis settings.",
    paste0("Only retained descriptors are shown here (current threshold: p <= ", proba, ")."),
    mode_txt,
    "",
    "### Quantitative markers",
    "These lines identify quantitative variables that are unusually high or low for the group relative to the full sample.",
    "",
    "### Categorical markers",
    "These lines identify modalities that are over-represented or otherwise associated with the group relative to the full sample.",
    "",
    "Use these retained descriptors to summarize the profile of the group in a compact and reusable way.",
    "Do not interpret the results as causal explanations, and do not infer more than what is supported by the retained evidence.",
    sep = "\n"
  )
}

build_request_group_profile_prep <- function(profile_mode = c("balanced", "categorical", "quantitative")) {
  profile_mode <- match.arg(profile_mode)

  mode_block <- switch(
    profile_mode,
    balanced = c(
      "Use both quantitative and categorical evidence when available.",
      "Distinguish what is central from what is secondary."
    ),
    categorical = c(
      "Prioritize categorical markers when summarizing the group.",
      "Use quantitative evidence only if it helps clarify the overall profile."
    ),
    quantitative = c(
      "Prioritize quantitative markers when summarizing the group.",
      "Use categorical evidence only if it helps clarify the overall profile."
    )
  )

  paste(
    c(
      "Using only the results below, produce a short structured summary of this group.",
      "",
      "The goal is not only to summarize the statistical profile for itself, but to prepare a later contextualized interpretation together with the group's textual productions.",
      "",
      mode_block,
      "",
      "Rules:",
      "- Stay close to the retained descriptors shown below.",
      "- Distinguish core profile from more secondary markers.",
      "- Do not invent causal explanations.",
      "- If the evidence is sparse, mixed, or weak, say so explicitly.",
      "- Use the exact output format below.",
      "",
      "Output format:",
      "Core group profile:",
      "[One short sentence summarizing what statistically characterizes the group.]",
      "",
      "Distinctive quantitative traits:",
      "[3 to 5 short traits separated by semicolons. If none, write: none]",
      "",
      "Distinctive categorical traits:",
      "[3 to 5 short traits or modalities separated by semicolons. If none, write: none]",
      "",
      "Distinctive markers:",
      "[1 to 3 short phrases capturing the most central markers of the group.]",
      "",
      "Profile strength:",
      "[Choose exactly one: strong / moderate / mixed / weak]",
      "",
      "Injectable summary:",
      "[One short sentence reusable later in a cross-group contextualized interpretation.]"
    ),
    collapse = "\n"
  )
}

build_conclusion_group_profile_prep <- function() {
  paste(
    "# Output constraint",
    "Your answer must contain exactly these six fields and nothing else:",
    "1. Core group profile",
    "2. Distinctive quantitative traits",
    "3. Distinctive categorical traits",
    "4. Distinctive markers",
    "5. Profile strength",
    "6. Injectable summary",
    sep = "\n"
  )
}

# ---------------------------------------------------------------------------
# Parser
# ---------------------------------------------------------------------------

parse_group_profile_prep_response <- function(text) {
  text <- paste(text, collapse = "\n")
  text <- gsub("\r\n", "\n", text, fixed = TRUE)
  text <- gsub("\r", "\n", text, fixed = TRUE)
  text <- .strip_markdown_fences(text)

  text <- gsub("(?im)^\\s*here is the output\\s*:?\\s*\\n?", "", text, perl = TRUE)
  text <- gsub("(?im)^\\s*output\\s*:?\\s*\\n?", "", text, perl = TRUE)

  fields <- c(
    "Core group profile",
    "Distinctive quantitative traits",
    "Distinctive categorical traits",
    "Distinctive markers",
    "Profile strength",
    "Injectable summary"
  )

  core_group_profile <- .extract_field_block(text, "Core group profile", fields)
  quantitative_raw   <- .extract_field_block(text, "Distinctive quantitative traits", fields)
  categorical_raw    <- .extract_field_block(text, "Distinctive categorical traits", fields)
  markers_raw        <- .extract_field_block(text, "Distinctive markers", fields)
  profile_strength   <- .extract_field_block(text, "Profile strength", fields)
  injectable_summary <- .extract_field_block(text, "Injectable summary", fields)

  quantitative_traits <- .split_semicolon_traits(quantitative_raw)
  categorical_traits  <- .split_semicolon_traits(categorical_raw)
  distinctive_markers <- .split_semicolon_traits(markers_raw)

  if (!is.na(profile_strength)) {
    profile_strength <- tolower(trimws(profile_strength))
  }

  list(
    core_group_profile = core_group_profile,
    quantitative_traits = quantitative_traits,
    categorical_traits = categorical_traits,
    distinctive_markers = distinctive_markers,
    profile_strength = profile_strength,
    injectable_summary = injectable_summary
  )
}

# ---------------------------------------------------------------------------
# Prompt assembly
# ---------------------------------------------------------------------------

get_prompt_group_profile_prep <- function(catdes_result,
                                          introduction,
                                          request,
                                          conclusion,
                                          sample.pct = 1,
                                          profile_mode = c("balanced", "categorical", "quantitative")) {
  profile_mode <- match.arg(profile_mode)

  stces <- get_sentences_group_profile(
    catdes_result = catdes_result,
    sample.pct = sample.pct,
    profile_mode = profile_mode
  )

  if (length(stces) == 0 ||
      all(vapply(stces, function(x) !nzchar(trimws(x)), logical(1)))) {
    stop("No retained group-profile descriptors found to process.", call. = FALSE)
  }

  out <- lapply(names(stces), function(grp) {
    data_txt <- glue::glue(
      "## Group '{grp}'\n\n",
      "{stces[[grp]]}"
    )

    build_standard_prompt(
      introduction = introduction,
      request = request,
      data = data_txt,
      conclusion = conclusion
    )
  })

  names(out) <- names(stces)
  out
}

# ---------------------------------------------------------------------------
# Main
# ---------------------------------------------------------------------------

#' Prepare group-wise structured statistical summaries for later contextualization
#'
#' @param x Optional raw `catdes` result.
#' @param dataset Optional data frame. Used if `x` is NULL.
#' @param num.var Index of grouping variable for `FactoMineR::catdes()`.
#' @param proba Retention threshold forwarded to `catdes`.
#' @param sample.pct Proportion of retained descriptors kept in the prompt.
#' @param profile_mode `"balanced"`, `"categorical"`, or `"quantitative"`.
#' @param prompt_style `"compact"` or `"detailed"`.
#' @param introduction Optional introduction.
#' @param request Optional request block.
#' @param conclusion Optional conclusion/output block.
#' @param model LLM model name.
#' @param row.w Optional row weights forwarded to `catdes`.
#' @param generate Logical; if FALSE returns prompts only.
#' @param ... Additional arguments passed to `ollamar::generate`.
#'
#' @return If `generate = FALSE`, a named list of prompts.
#' If `generate = TRUE`, a named list where each element contains:
#' - `prompt`
#' - `response`
#' - `parsed`
#'
#' Attributes:
#' - `group_profile_summary_mechanical`
#' - `catdes_result`
#'
#' @export
nail_group_profile_prep <- function(x = NULL,
                                    dataset = NULL,
                                    num.var = NULL,
                                    proba = 0.05,
                                    sample.pct = 1,
                                    profile_mode = c("balanced", "categorical", "quantitative"),
                                    prompt_style = c("compact", "detailed"),
                                    introduction = NULL,
                                    request = NULL,
                                    conclusion = NULL,
                                    model = "llama3",
                                    row.w = NULL,
                                    generate = FALSE,
                                    ...) {
  profile_mode <- match.arg(profile_mode)
  prompt_style <- match.arg(prompt_style)

  validate_group_profile_prep_inputs(
    x = x,
    dataset = dataset,
    num.var = num.var,
    proba = proba,
    sample.pct = sample.pct,
    prompt_style = prompt_style,
    generate = generate,
    profile_mode = profile_mode
  )

  extracted <- .extract_group_profile_inputs(
    x = x,
    dataset = dataset,
    num.var = num.var,
    proba = proba,
    row.w = row.w
  )

  catdes_result <- extracted$catdes_result

  mechanical_summary <- .summarize_group_profiles_mechanical(
    catdes_result = catdes_result,
    top_n_quanti = 5,
    top_n_quali = 5
  )

  if (is.null(introduction)) {
    introduction <- paste(
      "The results below describe one specific group through statistical descriptors retained from a group characterization analysis.",
      "The goal is to summarize this group's statistical profile in a short structured format that can later be crossed with the group's textual productions."
    )
  }

  if (is.null(request)) {
    request <- build_request_group_profile_prep(
      profile_mode = profile_mode
    )
  }

  if (is.null(conclusion)) {
    conclusion <- build_conclusion_group_profile_prep()
  }

  guide <- build_guide_group_profile_prep(
    proba = proba,
    profile_mode = profile_mode,
    prompt_style = prompt_style
  )

  introduction <- paste(introduction, guide, sep = "\n\n---\n\n")

  prompts <- tryCatch(
    get_prompt_group_profile_prep(
      catdes_result = catdes_result,
      introduction = introduction,
      request = request,
      conclusion = conclusion,
      sample.pct = sample.pct,
      profile_mode = profile_mode
    ),
    error = function(e) {
      if (grepl("No retained group-profile descriptors", conditionMessage(e))) {
        "NAILER_NO_GROUP_PROFILE_FOUND"
      } else {
        stop(e)
      }
    }
  )

  if (identical(prompts, "NAILER_NO_GROUP_PROFILE_FOUND")) {
    if (generate) {
      message("Execution halted: No retained group-profile descriptors found. Nothing to generate.")
      out <- list()
      attr(out, "group_profile_summary_mechanical") <- mechanical_summary
      attr(out, "catdes_result") <- catdes_result
      return(out)
    }

    out <- list()
    attr(out, "group_profile_summary_mechanical") <- mechanical_summary
    attr(out, "catdes_result") <- catdes_result
    return(out)
  }

  if (!generate) {
    attr(prompts, "group_profile_summary_mechanical") <- mechanical_summary
    attr(prompts, "catdes_result") <- catdes_result
    return(prompts)
  }

  extra_args <- list(...)
  ollama_api_options <- filter_ollama_options(extra_args)

  out <- lapply(prompts, function(prompt) {
    res_llm <- .call_ollama_base(
      model = model,
      prompt = prompt,
      output = "df",
      ollama_api_options = ollama_api_options
    )

    response_text <- paste(res_llm$response, collapse = "\n")
    parsed <- tryCatch(
      parse_group_profile_prep_response(response_text),
      error = function(e) {
        list(
          core_group_profile = NA_character_,
          quantitative_traits = character(0),
          categorical_traits = character(0),
          distinctive_markers = character(0),
          profile_strength = NA_character_,
          injectable_summary = NA_character_
        )
      }
    )

    list(
      prompt = prompt,
      response = response_text,
      parsed = parsed
    )
  })

  names(out) <- names(prompts)
  attr(out, "group_profile_summary_mechanical") <- mechanical_summary
  attr(out, "catdes_result") <- catdes_result
  out
}
