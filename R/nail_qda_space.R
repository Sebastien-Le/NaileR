#' @importFrom dplyr filter arrange desc
#' @importFrom glue glue
#' @importFrom knitr kable
#' @importFrom utils globalVariables
#' @importFrom FactoMineR PCA

utils::globalVariables(c(".data", "coord", "abs_coord", "correlation", "abs_correlation"))

# ---------------------------------------------------------------------------
# Validation
# ---------------------------------------------------------------------------

validate_qda_space_inputs <- function(ncp, scale.unit, min_inertia_pct,
                                      top_n_var, top_n_products, generate,
                                      expertise_mode) {
  if (!is.numeric(ncp) || length(ncp) != 1 || is.na(ncp) || ncp < 1) {
    stop("`ncp` must be a single numeric value >= 1.", call. = FALSE)
  }

  if (!is.logical(scale.unit) || length(scale.unit) != 1 || is.na(scale.unit)) {
    stop("`scale.unit` must be a single non-missing logical value.", call. = FALSE)
  }

  if (!is.numeric(min_inertia_pct) || length(min_inertia_pct) != 1 || is.na(min_inertia_pct) ||
      min_inertia_pct < 0 || min_inertia_pct > 100) {
    stop("`min_inertia_pct` must be a single numeric value in [0, 100].", call. = FALSE)
  }

  if (!is.numeric(top_n_var) || length(top_n_var) != 1 || is.na(top_n_var) || top_n_var < 1) {
    stop("`top_n_var` must be a single numeric value >= 1.", call. = FALSE)
  }

  if (!is.numeric(top_n_products) || length(top_n_products) != 1 || is.na(top_n_products) || top_n_products < 1) {
    stop("`top_n_products` must be a single numeric value >= 1.", call. = FALSE)
  }

  if (!is.logical(generate) || length(generate) != 1 || is.na(generate)) {
    stop("`generate` must be a single non-missing logical value.", call. = FALSE)
  }

  if (!expertise_mode %in% c("sensory", "positioning", "hybrid")) {
    stop("`expertise_mode` must be one of: 'sensory', 'positioning', 'hybrid'.", call. = FALSE)
  }

  invisible(TRUE)
}

# ---------------------------------------------------------------------------
# Extract inputs from nail_qda outputs or raw decat results
# ---------------------------------------------------------------------------

.extract_qda_space_inputs <- function(x, profile_summary = NULL) {
  decat_result <- attr(x, "decat_result", exact = TRUE)
  profile_attr <- attr(x, "profile_summary", exact = TRUE)

  if (!is.null(decat_result)) {
    if (is.null(profile_summary)) {
      profile_summary <- profile_attr
    }
    return(list(
      decat_result = decat_result,
      profile_summary = profile_summary
    ))
  }

  if (is.list(x) && !is.null(x$adjmean)) {
    return(list(
      decat_result = x,
      profile_summary = profile_summary
    ))
  }

  stop("`x` must be either an object returned by `nail_qda()` or a raw `decat` result containing `adjmean`.", call. = FALSE)
}

.extract_llm_profile_summaries <- function(llm_product_summaries) {
  if (is.null(llm_product_summaries)) {
    return(NULL)
  }

  out <- list()

  for (nm in names(llm_product_summaries)) {
    item <- llm_product_summaries[[nm]]

    parsed <- NULL
    if (is.list(item) && !is.null(item$parsed)) {
      parsed <- item$parsed
    } else if (
      is.list(item) &&
      all(c(
        "core_profile", "positive_traits", "negative_traits",
        "positioning_cues", "profile_clarity", "injectable_summary"
      ) %in% names(item))
    ) {
      parsed <- item
    }

    if (is.null(parsed)) next

    out[[nm]] <- list(
      injectable_summary = parsed$injectable_summary,
      positioning_cues = parsed$positioning_cues,
      profile_clarity = parsed$profile_clarity,
      core_profile = parsed$core_profile,
      positive_traits = parsed$positive_traits,
      negative_traits = parsed$negative_traits
    )
  }

  out
}

# ---------------------------------------------------------------------------
# Prompt builders
# ---------------------------------------------------------------------------

build_guide_qda_space <- function(min_inertia_pct = 10,
                                  expertise_mode = c("sensory", "positioning", "hybrid")) {
  expertise_mode <- match.arg(expertise_mode)
  mode_lines <- switch(
    expertise_mode,
    sensory = c(
      "Interpretation mode: sensory.",
      "Prioritize sensory oppositions between products.",
      "Describe the axes using sensory and perceptual contrasts first."
    ),
    positioning = c(
      "Interpretation mode: positioning.",
      "You may interpret the axes as broader product styles or product poles.",
      "Stay grounded in the sensory evidence."
    ),
    hybrid = c(
      "Interpretation mode: hybrid.",
      "Start from the sensory oppositions and, when relevant, infer broader product styles.",
      "Keep the sensory evidence primary."
    )
  )

  paste(
    c(
      "## How to Read the Results",
      "The product space is built from the adjusted mean sensory profiles of the products.",
      "Each retained dimension summarizes one major opposition in the sensory space, under the current PCA settings.",
      "The sign of a PCA dimension is arbitrary: interpret the opposition between the two ends, not the absolute meaning of positive versus negative coordinates.",
      paste0("Only dimensions explaining at least ", min_inertia_pct, "% of the inertia are interpreted automatically."),
      "",
      "### Variable-level evidence",
      "This section lists the attributes most positively and most negatively associated with the dimension.",
      "These attributes help identify the main sensory opposition carried by the axis, but they should be interpreted as the strongest associations under the current analysis settings.",
      "",
      "### Product-level evidence",
      "This section lists the products located at the negative and positive ends of the dimension.",
      "For each product, the summary recalls the profile of the product in a form meant to help interpret the product space.",
      "",
      mode_lines,
      "",
      "Use both sections together: the variable-level evidence gives the general meaning of the dimension, and the product-level evidence shows how this dimension is expressed in concrete products.",
      "When variable-level evidence and product-level evidence do not align perfectly, prioritize the variable-level structure and use the products as illustrations."
    ),
    collapse = "\n"
  )
}

build_request_qda_space <- function(expertise_mode = c("sensory", "positioning", "hybrid")) {
  expertise_mode <- match.arg(expertise_mode)

  if (expertise_mode == "sensory") {
    return(paste(
      "Using only the results below, interpret each retained dimension of the product sensory space.",
      "For each dimension, explain what sensory opposition structures the axis.",
      "Use the variable-level evidence to identify the general sensory meaning of the dimension.",
      "Use the product-level evidence to explain how this sensory opposition is expressed by the products located at the two ends.",
      "Stay close to sensory and perceptual vocabulary.",
      "If the evidence is partial, mixed, or somewhat unstable, say so explicitly.",
      "Do not interpret the retained attributes as absolute truths; treat them as the strongest associations selected under the current analysis settings.",
      sep = "\n"
    ))
  }

  if (expertise_mode == "positioning") {
    return(paste(
      "Using only the results below, interpret each retained dimension of the product space.",
      "For each dimension, explain what broader product opposition or product style structures the axis.",
      "Use the sensory evidence as the basis of your interpretation.",
      "Use the product-level evidence to explain how the products at the two ends embody this opposition.",
      "If the evidence is partial, mixed, or somewhat unstable, say so explicitly.",
      "Do not interpret the retained attributes as absolute truths; treat them as the strongest associations selected under the current analysis settings.",
      sep = "\n"
    ))
  }

  paste(
    "Using only the results below, interpret each retained dimension of the product space.",
    "For each dimension, first explain the main sensory opposition that structures the axis, then explain what broader product contrast or style it may suggest.",
    "Use the variable-level evidence to identify the sensory structure of the dimension.",
    "Use the product-level evidence to explain how this opposition is expressed by the products located at the two ends.",
    "Keep the sensory evidence primary and the broader interpretation secondary.",
    "If the evidence is partial, mixed, or somewhat unstable, say so explicitly.",
    "Do not interpret the retained attributes as absolute truths; treat them as the strongest associations selected under the current analysis settings.",
    sep = "\n"
  )
}

build_conclusion_qda_space <- function(expertise_mode = c("sensory", "positioning", "hybrid")) {
  expertise_mode <- match.arg(expertise_mode)

  if (expertise_mode == "sensory") {
    return(paste(
      "# Final Summary Task",
      "For each retained dimension, provide:",
      "1. **The main sensory opposition carried by the axis**.",
      "2. **What characterizes the negative end and the positive end in sensory terms**.",
      "3. **How the extreme products help make this opposition concrete**.",
      "",
      "# Output format",
      "Your output must be **formatted using valid Quarto Markdown**.",
      sep = "\n"
    ))
  }

  if (expertise_mode == "positioning") {
    return(paste(
      "# Final Summary Task",
      "For each retained dimension, provide:",
      "1. **The main product opposition or product style contrast carried by the axis**.",
      "2. **What characterizes the negative end and the positive end**.",
      "3. **How the extreme products help make this opposition concrete**.",
      "",
      "# Output format",
      "Your output must be **formatted using valid Quarto Markdown**.",
      sep = "\n"
    ))
  }

  paste(
    "# Final Summary Task",
    "For each retained dimension, provide:",
    "1. **The main sensory opposition carried by the axis**.",
    "2. **The broader product contrast or style that this opposition may suggest**.",
    "3. **What characterizes the negative end and the positive end**.",
    "4. **How the extreme products help make this opposition concrete**.",
    "",
    "# Output format",
    "Your output must be **formatted using valid Quarto Markdown**.",
    sep = "\n"
  )
}

# ---------------------------------------------------------------------------
# Core computations
# ---------------------------------------------------------------------------

.build_qda_space_object <- function(decat_result, ncp = 2, scale.unit = FALSE, min_inertia_pct = 10) {
  adjmean <- as.data.frame(decat_result$adjmean)

  if (nrow(adjmean) < 2 || ncol(adjmean) < 2) {
    stop("`adjmean` must contain at least 2 products and 2 attributes to build a product space.", call. = FALSE)
  }

  max_ncp <- min(ncp, nrow(adjmean) - 1, ncol(adjmean))
  if (max_ncp < 1) {
    stop("No interpretable PCA dimension can be computed from `adjmean`.", call. = FALSE)
  }

  res_pca <- FactoMineR::PCA(
    adjmean,
    scale.unit = scale.unit,
    ncp = max_ncp,
    graph = FALSE
  )

  eig <- as.data.frame(res_pca$eig)
  colnames(eig)[1:3] <- c("eigenvalue", "percent", "cumulative_percent")

  available_axes <- ncol(res_pca$var$cor)

  retained_axes <- which(eig$percent >= min_inertia_pct)
  retained_axes <- retained_axes[retained_axes <= available_axes]

  list(
    pca_result = res_pca,
    adjmean = adjmean,
    eig = eig,
    retained_axes = retained_axes,
    scale.unit = scale.unit,
    min_inertia_pct = min_inertia_pct
  )
}

# ---------------------------------------------------------------------------
# Axis-level evidence
# ---------------------------------------------------------------------------

get_sentences_qda_axis <- function(space_obj, axis, top_n_var = 5) {
  var_cor <- as.data.frame(space_obj$pca_result$var$cor)
  axis_name <- paste0("Dim.", axis)

  if (!axis_name %in% colnames(var_cor)) {
    stop(sprintf("Axis '%s' not found in PCA variable correlations.", axis_name), call. = FALSE)
  }

  axis_df <- data.frame(
    Variable = rownames(var_cor),
    correlation = var_cor[[axis_name]],
    stringsAsFactors = FALSE
  )

  axis_df$abs_correlation <- abs(axis_df$correlation)

  pos_df <- axis_df |>
    dplyr::filter(.data$correlation > 0) |>
    dplyr::arrange(dplyr::desc(.data$abs_correlation))

  neg_df <- axis_df |>
    dplyr::filter(.data$correlation < 0) |>
    dplyr::arrange(dplyr::desc(.data$abs_correlation))

  pos_df <- utils::head(pos_df[, c("Variable", "correlation"), drop = FALSE], top_n_var)
  neg_df <- utils::head(neg_df[, c("Variable", "correlation"), drop = FALSE], top_n_var)

  pos_txt <- if (nrow(pos_df) > 0) {
    paste(
      "### Attributes positively associated with the dimension",
      "",
      paste(knitr::kable(pos_df, digits = 2, format = "pipe", align = c("l", "r")), collapse = "\n"),
      sep = "\n"
    )
  } else {
    "### Attributes positively associated with the dimension\n\n*No positive associations retained.*"
  }

  neg_txt <- if (nrow(neg_df) > 0) {
    paste(
      "### Attributes negatively associated with the dimension",
      "",
      paste(knitr::kable(neg_df, digits = 2, format = "pipe", align = c("l", "r")), collapse = "\n"),
      sep = "\n"
    )
  } else {
    "### Attributes negatively associated with the dimension\n\n*No negative associations retained.*"
  }

  normalize_blank_lines(paste(pos_txt, neg_txt, sep = "\n\n"))
}

# ---------------------------------------------------------------------------
# Product-level evidence
# ---------------------------------------------------------------------------

.build_axis_product_evidence <- function(space_obj, axis,
                                         profile_summary = NULL,
                                         llm_profile_summaries = NULL,
                                         top_n_products = 2) {
  coord_df <- as.data.frame(space_obj$pca_result$ind$coord)
  axis_name <- paste0("Dim.", axis)

  if (!axis_name %in% colnames(coord_df)) {
    stop(sprintf("Axis '%s' not found in PCA individual coordinates.", axis_name), call. = FALSE)
  }

  prod_df <- data.frame(
    Product = rownames(coord_df),
    coord = coord_df[[axis_name]],
    stringsAsFactors = FALSE
  )

  neg_products <- prod_df |>
    dplyr::filter(.data$coord < 0) |>
    dplyr::arrange(.data$coord)

  pos_products <- prod_df |>
    dplyr::filter(.data$coord > 0) |>
    dplyr::arrange(dplyr::desc(.data$coord))

  neg_products <- utils::head(neg_products, top_n_products)
  pos_products <- utils::head(pos_products, top_n_products)

  .one_line_mechanical <- function(product_name, coord_value, profile_summary_item) {
    if (is.null(profile_summary_item)) {
      return(paste0("- ", product_name, " (coord. = ", round(coord_value, 2), ")"))
    }

    above_txt <- if (length(profile_summary_item$above) > 0) {
      paste(profile_summary_item$above, collapse = ", ")
    } else {
      "none"
    }

    below_txt <- if (length(profile_summary_item$below) > 0) {
      paste(profile_summary_item$below, collapse = ", ")
    } else {
      "none"
    }

    paste0(
      "- ", product_name,
      " (coord. = ", round(coord_value, 2), "): ",
      "above average on ", above_txt,
      "; below average on ", below_txt,
      " (profile strength: ", profile_summary_item$profile_strength, ")"
    )
  }

  .one_line_llm <- function(product_name, coord_value, llm_item, fallback_item = NULL) {
    if (is.null(llm_item)) {
      return(.one_line_mechanical(product_name, coord_value, fallback_item))
    }

    summary_txt <- llm_item$injectable_summary
    cue_txt <- llm_item$positioning_cues
    clarity_txt <- llm_item$profile_clarity

    if (is.null(summary_txt) || is.na(summary_txt) || !nzchar(trimws(summary_txt))) {
      return(.one_line_mechanical(product_name, coord_value, fallback_item))
    }

    pieces <- c(
      paste0("- ", product_name, " (coord. = ", round(coord_value, 2), "): ", summary_txt),
      if (!is.null(cue_txt) && !is.na(cue_txt) && nzchar(trimws(cue_txt)))
        paste0(" Intermediate summary cue: ", cue_txt) else NULL,
      if (!is.null(clarity_txt) && !is.na(clarity_txt) && nzchar(trimws(clarity_txt)))
        paste0(" Profile clarity: ", clarity_txt, ".") else NULL
    )

    paste0(pieces, collapse = "")
  }

  neg_lines <- if (nrow(neg_products) > 0) {
    vapply(
      seq_len(nrow(neg_products)),
      function(i) {
        p <- neg_products$Product[i]
        llm_item <- if (!is.null(llm_profile_summaries)) llm_profile_summaries[[p]] else NULL
        fallback_item <- if (!is.null(profile_summary)) profile_summary[[p]] else NULL
        .one_line_llm(p, neg_products$coord[i], llm_item, fallback_item)
      },
      character(1)
    )
  } else {
    "*No product clearly located at the negative end.*"
  }

  pos_lines <- if (nrow(pos_products) > 0) {
    vapply(
      seq_len(nrow(pos_products)),
      function(i) {
        p <- pos_products$Product[i]
        llm_item <- if (!is.null(llm_profile_summaries)) llm_profile_summaries[[p]] else NULL
        fallback_item <- if (!is.null(profile_summary)) profile_summary[[p]] else NULL
        .one_line_llm(p, pos_products$coord[i], llm_item, fallback_item)
      },
      character(1)
    )
  } else {
    "*No product clearly located at the positive end.*"
  }

  paste(
    "### Products at the negative end of the dimension",
    "",
    paste(neg_lines, collapse = "\n"),
    "",
    "### Products at the positive end of the dimension",
    "",
    paste(pos_lines, collapse = "\n"),
    sep = "\n"
  )
}

# ---------------------------------------------------------------------------
# Main
# ---------------------------------------------------------------------------

#' Interpret the product space built from QDA adjusted means
#'
#' Builds a PCA on the adjusted mean table returned by `decat()`, then prepares
#' prompts to interpret the retained product-space dimensions.
#'
#' @param x Either an object returned by `nail_qda()` or a raw `decat` result.
#' @param profile_summary Optional structured profile summary. If `x` comes from
#' `nail_qda()`, this is extracted automatically when available.
#' @param llm_product_summaries Optional output from `nail_qda_spaceprep(generate = TRUE)`.
#' @param ncp Number of dimensions to compute in the PCA.
#' @param scale.unit Should the adjusted mean variables be scaled before PCA?
#' @param min_inertia_pct Minimum inertia percentage required to interpret an axis automatically.
#' @param top_n_var Number of top positive and negative attributes to display per axis.
#' @param top_n_products Number of extreme products to display at each end of the axis.
#' @param expertise_mode Either `"sensory"`, `"positioning"`, or `"hybrid"`.
#' @param introduction Optional introduction for the LLM prompt.
#' @param request Optional request for the LLM prompt.
#' @param conclusion Optional conclusion/output-format block.
#' @param model Model name for the selected provider.
#' @param provider LLM backend to use for generation. Use `"ollama"` for a local Ollama model or `"gemini"` for Google Gemini via `GEMINI_API_KEY`.
#' @param generate Logical; if FALSE returns prompt(s), otherwise calls the LLM.
#' @param ... Additional provider-specific generation arguments passed to the selected LLM backend.
#'
#' @return If `generate = FALSE`, a named list of prompts, one per retained axis.
#' If `generate = TRUE`, a named list of data frames returned by the selected LLM backend.
#'
#' @export
nail_qda_space <- function(x,
                           profile_summary = NULL,
                           llm_product_summaries = NULL,
                           ncp = 2,
                           scale.unit = FALSE,
                           min_inertia_pct = 10,
                           top_n_var = 5,
                           top_n_products = 2,
                           expertise_mode = c("sensory", "positioning", "hybrid"),
                           introduction = NULL,
                           request = NULL,
                           conclusion = NULL,
                           model = "llama3",
                           provider = c("ollama", "gemini"),
                           generate = FALSE,
                           ...) {
  expertise_mode <- match.arg(expertise_mode)

  provider <- match.arg(provider)

  validate_qda_space_inputs(
    ncp = ncp,
    scale.unit = scale.unit,
    min_inertia_pct = min_inertia_pct,
    top_n_var = top_n_var,
    top_n_products = top_n_products,
    generate = generate,
    expertise_mode = expertise_mode
  )

  extracted <- .extract_qda_space_inputs(x, profile_summary = profile_summary)
  decat_result <- extracted$decat_result
  profile_summary <- extracted$profile_summary
  llm_profile_summaries <- .extract_llm_profile_summaries(llm_product_summaries)

  space_obj <- .build_qda_space_object(
    decat_result = decat_result,
    ncp = ncp,
    scale.unit = scale.unit,
    min_inertia_pct = min_inertia_pct
  )

  if (is.null(introduction)) {
    introduction <- switch(
      expertise_mode,
      sensory = paste(
        "The results below describe the main dimensions of a product sensory space built from adjusted mean sensory profiles.",
        "Each dimension corresponds to one major sensory opposition between products in that space."
      ),
      positioning = paste(
        "The results below describe the main dimensions of a product space built from adjusted mean sensory profiles.",
        "Each dimension may reflect a broader contrast between product styles or product poles."
      ),
      hybrid = paste(
        "The results below describe the main dimensions of a product space built from adjusted mean sensory profiles.",
        "Each dimension first reflects a sensory opposition and may also suggest a broader contrast between product styles."
      )
    )
  }

  if (is.null(request)) {
    request <- build_request_qda_space(expertise_mode = expertise_mode)
  }

  if (is.null(conclusion)) {
    conclusion <- build_conclusion_qda_space(expertise_mode = expertise_mode)
  }

  guide <- build_guide_qda_space(
    min_inertia_pct = min_inertia_pct,
    expertise_mode = expertise_mode
  )
  introduction <- paste(introduction, guide, sep = "\n\n---\n\n")

  prompts <- tryCatch(
    {
      retained_axes <- space_obj$retained_axes

      if (length(retained_axes) == 0) {
        stop("No retained dimensions to interpret under the current inertia threshold.", call. = FALSE)
      }

      out <- lapply(retained_axes, function(ax) {
        eig <- space_obj$eig
        inertia_pct <- round(eig$percent[ax], 2)

        var_txt <- get_sentences_qda_axis(space_obj, axis = ax, top_n_var = top_n_var)
        prod_txt <- .build_axis_product_evidence(
          space_obj,
          axis = ax,
          profile_summary = profile_summary,
          llm_profile_summaries = llm_profile_summaries,
          top_n_products = top_n_products
        )

        data_txt <- paste(
          glue::glue("## Dimension {ax} ({inertia_pct}% of inertia)"),
          "",
          "### Variable-level evidence",
          "",
          var_txt,
          "",
          "### Product-level evidence",
          "",
          prod_txt,
          sep = "\n"
        )

        build_standard_prompt(
          introduction = introduction,
          request = request,
          data = data_txt,
          conclusion = conclusion
        )
      })

      names(out) <- paste0("Dim", retained_axes)
      out
    },
    error = function(e) {
      if (grepl("No retained dimensions", conditionMessage(e))) {
        "NAILER_NO_AXES_FOUND"
      } else {
        stop(e)
      }
    }
  )

  if (identical(prompts, "NAILER_NO_AXES_FOUND")) {
    no_axes_message <- paste0(
      "*No PCA dimension reached the minimum inertia threshold of ",
      min_inertia_pct,
      "% under the current settings.*"
    )

    if (generate) {
      message("Execution halted: No retained dimensions found. Nothing to generate.")
      return(list())
    }

    out <- no_axes_message
    attr(out, "qda_space") <- space_obj
    return(out)
  }

  if (!generate) {
    attr(prompts, "qda_space") <- space_obj
    attr(prompts, "profile_summary") <- profile_summary
    attr(prompts, "llm_profile_summaries") <- llm_profile_summaries
    return(prompts)
  }

  extra_args <- list(...)
  llm_api_options <- extra_args

  .call_llm <- function(prompt) {
    res_llm <- .call_llm_base(
      provider = provider,
      model = model,
      prompt = prompt,
      output = "df",
      llm_api_options = llm_api_options
    )
    res_llm$prompt <- prompt
    res_llm
  }

  out <- lapply(prompts, .call_llm)
  names(out) <- names(prompts)
  attr(out, "qda_space") <- space_obj
  attr(out, "profile_summary") <- profile_summary
  attr(out, "llm_profile_summaries") <- llm_profile_summaries
  out
}
