#' @importFrom dplyr filter select arrange desc
#' @importFrom glue glue
#' @importFrom tibble rownames_to_column
#' @importFrom utils globalVariables

utils::globalVariables(c("v.test", "p.value", ".data"))

# ---------------------------------------------------------------------------
# Helpers
# ---------------------------------------------------------------------------


.row_heading <- function(row_name) {
  glue::glue("## Row '{row_name}'")
}

.section_heading_descfreq <- function() {
  "### Key Descriptive Attributes (Compared to Global Proportions)"
}


validate_descfreq_inputs <- function(dataset, sample.pct, proba,
                                     isolate.groups,
                                     drop.negative,
                                     rows_are_ordered,
                                     explicit_row_labels,
                                     generate) {
  assert_data_frame(dataset, "dataset")
  if (nrow(dataset) < 1 || ncol(dataset) < 2) {
    stop("`dataset` must contain at least one row and two columns.", call. = FALSE)
  }
  assert_proportion(sample.pct, "sample.pct")
  assert_proportion(proba, "proba")

  logical_args <- list(
    isolate.groups = isolate.groups,
    drop.negative = drop.negative,
    rows_are_ordered = rows_are_ordered,
    explicit_row_labels = explicit_row_labels,
    generate = generate
  )

  invalid_logicals <- names(logical_args)[!vapply(logical_args, function(x) is.logical(x) && length(x) == 1 && !is.na(x), logical(1))]

  if (length(invalid_logicals) > 0) {
    stop(
      sprintf(
        "The following arguments must be single non-missing logical values: %s.",
        paste(invalid_logicals, collapse = ", ")
      ),
      call. = FALSE
    )
  }
  invisible(TRUE)
}


build_request_descfreq <- function(isolate.groups = FALSE,
                                   interpretation_mode = c("description", "comparison"),
                                   rows_are_ordered = FALSE,
                                   explicit_row_labels = FALSE) {
  interpretation_mode <- match.arg(interpretation_mode)
  if (interpretation_mode == "description") {
    if (!isolate.groups) {
      lines <- c(
        "Using only the results below, describe each row as a relative profile.",
        "Identify the main over-represented and under-represented attributes for each row.",
        "Explain what distinguishes each row when relevant.",
        "If the evidence is limited, mixed, or weak, say so explicitly.",
        "Keep the interpretation close to the reported attributes.",
        "Do not interpret the results as causal explanations."
      )

      if (rows_are_ordered) {
        lines <- c(
          lines,
          "If the row labels form an ordered sequence, you may comment on intermediate positions, local shifts, or broader tendencies across rows.",
          "Do not force a single overall gradient unless it is clearly supported by the results."
        )
      } else {
        lines <- c(
          lines,
          "Do not assume that the rows form a progression or a continuum unless this is directly supported by the results."
        )
      }

      if (explicit_row_labels) {
        lines <- c(lines, "Do not rename the rows because they already have an explicit meaning.")
      } else {
        lines <- c(lines, "Propose a short descriptive name only when the evidence is sufficient.")
      }

      return(paste(lines, collapse = "\n"))
    }

    lines <- c(
      "Using only the results below, describe this row as a relative profile.",
      "Identify the main over-represented and under-represented attributes.",
      "Keep the interpretation close to the reported attributes.",
      "If the evidence is limited, mixed, or weak, say so explicitly.",
      "Do not interpret the results as causal explanations."
    )

    if (explicit_row_labels) {
      lines <- c(lines, "Do not rename the row because it already has an explicit meaning.")
    } else {
      lines <- c(lines, "Propose a short descriptive name only when the evidence is sufficient.")
    }

    return(paste(lines, collapse = "\n"))
  }

  if (!isolate.groups) {
    lines <- c(
      "Using only the results below, compare the rows in terms of their relative profiles.",
      "Focus on the main contrasts across rows rather than on separate row-by-row descriptions.",
      "Use over-represented and under-represented attributes as evidence.",
      "Do not interpret the results as causal explanations."
    )

    if (rows_are_ordered) {
      lines <- c(
        lines,
        "Treat the rows as ordered levels from lower rows to higher rows.",
        "Identify the main gradient across rows and what changes along it.",
        "If the pattern is not strictly linear, mention intermediate transitions, mixed patterns, or exceptions."
      )
    } else {
      lines <- c(
        lines,
        "Do not assume that the rows form a progression or a continuum unless this is directly supported by the results.",
        "Highlight the main oppositions, proximities, and especially distinctive profiles."
      )
    }

    if (explicit_row_labels) {
      lines <- c(lines, "Do not rename the rows because they already have an explicit meaning.")
    } else {
      lines <- c(lines, "Rename rows only if doing so truly helps summarize their relative profiles.")
    }

    return(paste(lines, collapse = "\n"))
  }

  lines <- c(
    "Using only the results below, describe how this row is positioned relative to the overall table.",
    "Use over-represented and under-represented attributes as evidence.",
    "Focus on the relative profile of this row, not on raw totals.",
    "Do not interpret the results as causal explanations."
  )

  if (rows_are_ordered) {
    lines <- c(lines, "If the rows form an ordered sequence, explain how this row fits into that broader pattern only when the results clearly support it.")
  }

  if (explicit_row_labels) {
    lines <- c(lines, "Do not rename the row because it already has an explicit meaning.")
  } else {
    lines <- c(lines, "Rename the row only if doing so helps summarize its profile and the evidence is sufficient.")
  }

  paste(lines, collapse = "\n")
}


build_conclusion_descfreq <- function(isolate.groups = FALSE,
                                      interpretation_mode = c("description", "comparison"),
                                      rows_are_ordered = FALSE,
                                      explicit_row_labels = FALSE) {
  interpretation_mode <- match.arg(interpretation_mode)

  if (interpretation_mode == "description") {
    if (!isolate.groups) {
      items <- c("# Final Summary Task")

      if (rows_are_ordered) {
        items <- c(
          items,
          "1. **A description of each row as a relative profile**.",
          "2. **A brief synthesis of the most distinctive row profiles**.",
          "3. **Any intermediate positions, mixed profiles, or rows with limited evidence**."
        )
      } else {
        items <- c(
          items,
          "1. **A description of each row as a relative profile**.",
          "2. **A brief synthesis of the most distinctive row profiles**.",
          "3. **A note about rows with limited, mixed, or weak evidence**."
        )
      }

      if (!explicit_row_labels) {
        items <- c(items, "4. **A list of row names you assigned**, if any, and the attributes supporting them.")
      }

      items <- c(items, "", "# Output format", "Your output must be **formatted using valid Quarto Markdown**.")
      return(paste(items, collapse = "\n"))
    }

    items <- c("# Final Summary Task", "1. **A description of the row as a relative profile**.")

    if (!explicit_row_labels) {
      items <- c(items, "2. **A row name you assigned**, if any, and the attributes supporting it.")
    }

    items <- c(items, "", "# Output format", "Your output must be **formatted using valid Quarto Markdown**.")
    return(paste(items, collapse = "\n"))
  }

  if (!isolate.groups) {
    items <- c("# Final Summary Task")

    if (rows_are_ordered) {
      items <- c(
        items,
        "1. **A synthesis of the main differences across rows**.",
        "2. **The main gradient from lower rows to higher rows**.",
        "3. **Any intermediate transitions, mixed patterns, or exceptions**."
      )
      if (!explicit_row_labels) {
        items <- c(items, "4. **A list of row names you assigned**, if you chose to rename them, and their distinguishing features.")
      }
    } else {
      items <- c(
        items,
        "1. **A synthesis of the main contrasts, proximities, and distinctive profiles across rows**."
      )
      if (!explicit_row_labels) {
        items <- c(items, "2. **A list of row names you assigned**, if you chose to rename them, and their distinguishing features.")
      }
    }

    items <- c(items, "", "# Output format", "Your output must be **formatted using valid Quarto Markdown**.")
    return(paste(items, collapse = "\n"))
  }

  items <- c("# Final Summary Task", "1. **A description of the row as a relative profile**.")

  if (rows_are_ordered) {
    items <- c(items, "2. **How this row fits into the broader gradient across rows**, if clearly supported.")
  }

  if (!explicit_row_labels) {
    next_num <- if (rows_are_ordered) 3 else 2
    items <- c(items, paste0(next_num, ". **A row name you assigned**, if you chose to rename it."))
  }

  items <- c(items, "", "# Output format", "Your output must be **formatted using valid Quarto Markdown**.")
  paste(items, collapse = "\n")
}


build_guide_descfreq <- function(proba = 0.05,
                                 interpretation_mode = c("description", "comparison"),
                                 rows_are_ordered = FALSE,
                                 explicit_row_labels = FALSE) {
  interpretation_mode <- match.arg(interpretation_mode)

  lines <- c(
    "## How to Read the Tables",
    "For each row, the analysis compares the proportion of each column attribute within that row to its overall proportion across the whole table.",
    "The tables below contain the attributes retained using the chosen significance threshold.",
    "",
    "* **Intern %**: percentage of the attribute within this row.",
    "* **glob %**: overall percentage of the attribute across all rows.",
    "* **Intern freq**: observed frequency of the attribute within this row.",
    "* **Glob freq**: overall frequency of the attribute across all rows.",
    "* **p.value**: smaller values indicate stronger evidence; larger values indicate weaker or more tentative evidence.",
    "* **v.test**: positive = over-represented; negative = under-represented; larger absolute values indicate a stronger difference from the global proportion.",
    "",
    "Interpret each row as a relative profile, not as a raw total.",
    "Characteristic attributes are more frequent than expected given their global proportion.",
    "Uncharacteristic attributes are less frequent than expected given their global proportion.",
    "",
    "Treat evidence as graded:",
    "* very strong: p.value <= 0.01",
    "* strong: 0.01 < p.value <= 0.05",
    "* moderate: 0.05 < p.value <= 0.10",
    paste0("* weak/tentative: 0.10 < p.value <= ", proba),
    "Prioritize the strongest signals."
  )

  if (interpretation_mode == "comparison") {
    lines <- c(lines, "When comparing rows, focus on contrasts in relative profiles rather than on isolated row descriptions.")
    if (rows_are_ordered) {
      lines <- c(lines, "Treat the rows as ordered levels from lower rows to higher rows.")
    } else {
      lines <- c(lines, "Do not assume that the rows form a progression or a continuum unless this is directly supported by the results.")
    }
  } else {
    if (rows_are_ordered) {
      lines <- c(lines, "If the row labels form an ordered sequence, you may comment on intermediate positions or broader tendencies, but do not force a single gradient unless the results support it.")
    } else {
      lines <- c(lines, "Do not assume that the rows form a progression or a continuum unless this is directly supported by the results.")
    }
  }

  if (explicit_row_labels) {
    lines <- c(lines, "Do not rename the rows if they already have an explicit meaning.")
  }

  lines <- c(lines, "Do not interpret the results as causal explanations.")
  paste(lines, collapse = "\n")
}

get_sentences_descfreq <- function(res_df, sample.pct, drop.negative, proba = 0.05) {
  ppts <- list()

  for (i in seq_along(res_df)) {
    grp_name <- names(res_df)[i]
    res_mat <- as.data.frame(res_df[[i]])
    names(res_mat) <- trimws(names(res_mat))

    if (is.null(res_mat) || nrow(res_mat) == 0 || !"v.test" %in% colnames(res_mat)) {
      ppts[[grp_name]] <- paste0(
        "This row has **no descriptive attributes retained under the chosen threshold** (p <= ", proba, ")."
      )
      next
    }

    num_index <- which(colnames(res_mat) == "v.test")
    if (sample.pct < 1) {
      res_sampled <- sample_numeric_distribution(
        res_mat,
        num_var_index = num_index,
        sample_pct = sample.pct,
        method = "stratified",
        bins = 5,
        return_matrix = FALSE
      )
    } else {
      res_sampled <- res_mat
    }

    cols_to_show <- c("Intern %", "glob %", "Intern freq", "Glob freq", "p.value", "v.test")
    cols_to_show <- cols_to_show[cols_to_show %in% colnames(res_sampled)]

    positive_df <- res_sampled |>
      dplyr::filter(v.test > 0) |>
      dplyr::arrange(p.value)

    negative_df <- res_sampled |>
      dplyr::filter(v.test < 0) |>
      dplyr::arrange(p.value)

    has_positive_results <- nrow(positive_df) > 0
    has_negative_results <- nrow(negative_df) > 0

    if (!has_positive_results && (drop.negative || !has_negative_results)) {
      if (drop.negative && has_negative_results) {
        ppts[[grp_name]] <- paste(
          glue::glue("This row has **no over-represented attributes retained under the chosen threshold** (p <= {proba})."),
          "(Note: Under-represented attributes were found but are hidden because `drop.negative` is TRUE.)",
          sep = "\n"
        )
      } else if (drop.negative) {
        ppts[[grp_name]] <- paste(
          glue::glue("This row has **no over-represented attributes retained under the chosen threshold** (p <= {proba})."),
          "(Note: Under-represented attributes are excluded from this analysis.)",
          sep = "\n"
        )
      } else {
        ppts[[grp_name]] <- glue::glue(
          "This row has **no descriptive attributes retained under the chosen threshold** (neither over- nor under-represented, p <= {proba})."
        )
      }
    } else {
      ppt1 <- if (has_positive_results) {
        format_stats_as_markdown(
          positive_df[, cols_to_show, drop = FALSE],
          title = "Over-represented Attributes (v.test > 0)"
        )
      } else {
        "This row has no retained **over-represented** attributes under the chosen threshold."
      }

      ppt2 <- ""
      if (!drop.negative) {
        ppt2 <- if (has_negative_results) {
          format_stats_as_markdown(
            negative_df[, cols_to_show, drop = FALSE],
            title = "Under-represented Attributes (v.test < 0)"
          )
        } else {
          "This row has no retained **under-represented** attributes under the chosen threshold."
        }
      }

      ppts[[grp_name]] <- normalize_blank_lines(paste(ppt1, ppt2, sep = "\n\n"))
    }
  }

  ppts
}



get_prompt_descfreq <- function(res_df, introduction, request, conclusion,
                                isolate.groups, sample.pct, drop.negative,
                                proba = 0.05,
                                interpretation_mode = c("description", "comparison"),
                                rows_are_ordered = FALSE) {
  interpretation_mode <- match.arg(interpretation_mode)
  stces_list <- get_sentences_descfreq(res_df, sample.pct, drop.negative, proba = proba)

  if (length(stces_list) == 0 ||
      all(vapply(stces_list, function(x) is.null(x) || !nzchar(x), logical(1)))) {
    stop("No significant differences between rows, execution was halted.")
  }

  all_groups <- names(stces_list)
  stces <- c()

  for (grp in all_groups) {
    quant <- if (is.null(stces_list[[grp]])) "" else stces_list[[grp]]
    ppt_grp <- glue::glue(
      "{.row_heading(grp)}\n\n",
      "{.section_heading_descfreq()}\n\n",
      "{quant}",
      .trim = TRUE
    )
    stces <- c(stces, ppt_grp)
  }

  data_intro <- if (interpretation_mode == "comparison") {
    if (rows_are_ordered) {
      paste(
        "Use the results below to compare the rows as ordered relative profiles.",
        "Assess whether they form a clear gradient, and mention intermediate transitions, mixed profiles, or exceptions when relevant.",
        sep = "\n"
      )
    } else {
      "Use the results below to compare the rows as relative profiles."
    }
  } else {
    if (rows_are_ordered) {
      paste(
        "Use the results below to describe each row as a relative profile.",
        "You may use the row order as contextual information, but do not force a single overall gradient unless it is directly supported by the results.",
        sep = "\n"
      )
    } else {
      "Use the results below to describe each row as a relative profile."
    }
  }

  header <- glue::glue(
    "# Introduction - Objective\n\n{introduction}\n\n",
    "# Task\n\n{request}\n\n",
    "---\n\n",
    "# Data\n\n{data_intro}\n\n\n"
  )

  if (!isolate.groups) {
    body <- paste(stces, collapse = "\n\n---\n\n")
    return(normalize_blank_lines(paste(header, body, "\n\n", conclusion, sep = "")))
  }

  prompts_list <- list()
  for (i in seq_along(stces)) {
    grp_name <- names(stces_list)[i]
    grp_body <- stces[i]
    prompts_list[[grp_name]] <- normalize_blank_lines(
      paste(header, grp_body, "\n\n", conclusion, sep = "")
    )
  }
  prompts_list
}

#' Interpret the rows of a contingency table
#'
#' Describes the rows of a contingency table. For each row, this description is based on the columns of the contingency table that are significantly related to it.
#'
#' @param dataset a data frame corresponding to a contingency table.
#' @param introduction the introduction for the LLM prompt.
#' @param request the request made to the LLM.
#' @param conclusion the conclusion for the LLM prompt.
#' @param model the model name for the selected provider ('llama3' by default for Ollama).
#' @param provider LLM backend to use for generation. Use `"ollama"` for a local Ollama model or `"gemini"` for Google Gemini via `GEMINI_API_KEY`.
#' @param isolate.groups a boolean that indicates whether to give the LLM a single prompt, or one prompt per row. Recommended if the contingency table has a great number of rows.
#' @param sample.pct from 0 to 1, the proportion of descriptive features that are randomly kept.
#' @param drop.negative a boolean that indicates whether to drop negative v.test values for interpretation (keeping only positive v.tests).
#' @param proba the significance threshold considered to characterize the category (by default 0.05).
#' @param interpretation_mode either "description" or "comparison".
#' @param rows_are_ordered logical; if TRUE, the prompt encourages the LLM to look for a gradient across rows.
#' @param explicit_row_labels logical; if TRUE, the prompt tells the LLM not to rename the rows.
#' @param by.quali a factor used to merge the data from different rows of the contingency table; by default NULL and each row is characterized.
#' @param generate a boolean that indicates whether to generate the LLM response. If FALSE, the function only returns the prompt.
#' @param ... Additional provider-specific generation arguments passed to the selected LLM backend
#' (e.g., `temperature`, `seed`).
#'
#' @return If `generate = FALSE`, a character prompt or a named list of prompts. If `generate = TRUE`, an object containing the generated interpretation and the underlying analytical result.
#'
#' @details This function directly sends a prompt to an LLM. Therefore, to get a consistent answer, we highly recommend to customize the parameters introduction and request and add all relevant information on your data for the LLM.
#'
#' Additionally, if isolate.groups = TRUE, you will need an introduction and a request that take into account the fact that only one group is analyzed at a time.
#'
#' @export
#'
#' @examples
#'\dontrun{
#' # Processing time is often longer than ten seconds
#' # because the function uses a large language model.
#'
#' ### Example 1: beard dataset ###
#'
#' data(beard_cont)
#'
#' intro_beard_iso <- 'A survey was conducted about beards
#' and 8 types of beards were described.
#' I will give you the results for one type of beard.'
#' intro_beard_iso <- gsub('\n', ' ', intro_beard_iso) |>
#' stringr::str_squish()
#'
#' req_beard_iso <- 'Please give a name to this beard
#' and summarize what makes this beard unique.'
#' req_beard_iso <- gsub('\n', ' ', req_beard_iso) |>
#' stringr::str_squish()
#'
#' res_beard <- nail_descfreq(beard_cont,
#'                            introduction = intro_beard_iso,
#'                            request = req_beard_iso,
#'                            isolate.groups = TRUE,
#'                            generate = FALSE)
#'
#' res_beard[[1]]
#' res_beard[[2]]
#'
#' intro_beard <- 'A survey was conducted about beards
#' and 8 types of beards were described.
#' In the data that follow, beards are named B1 to B8.'
#' intro_beard <- gsub('\n', ' ', intro_beard) |>
#' stringr::str_squish()
#'
#' req_beard <- 'Please give a name to each beard
#' and summarize what makes this beard unique.'
#' req_beard <- gsub('\n', ' ', req_beard) |>
#' stringr::str_squish()
#'
#' res_beard <- nail_descfreq(beard_cont,
#'                            introduction = intro_beard,
#'                            request = req_beard,
#'                            generate = TRUE)
#'
#' cat(res_beard$response)
#'
#' text <- res_beard$response
#' titles <- stringr::str_extract_all(text, "\\*\\*B[0-9]+: [^\\*\\*]+\\*\\*")[[1]]
#'
#' titles
#'
#' # for the following code to work, the response must have the beards'
#' # new names with this format: **B1: The Nice beard**, etc.
#'
#' titles <- stringr::str_replace_all(titles, "\\*\\*", "")  # remove asterisks
#' names <- stringr::str_extract(titles, ": .+")
#' names <- stringr::str_replace_all(names, ": ", "")  # remove the colon and space
#'
#' rownames(beard_cont) <- names
#'
#' library(FactoMineR)
#'
#' res_ca_beard <- CA(beard_cont, graph = F)
#' plot.CA(res_ca_beard, invisible = "col")
#'
#'
#' ### Example 2: children dataset ###
#'
#' data(children)
#'
#' children <- children[1:14, 1:5] |> t() |> as.data.frame()
#' rownames(children) <- c('No education', 'Elementary school',
#' 'Middle school', 'High school', 'University')
#'
#' intro_children <- 'The data used here is a contingency table
#' that summarizes the answers
#' given by different categories of people to the following question:
#' "according to you, what are the reasons that can make
#' a woman or a couple hesitate to have children?".
#' Each row corresponds to a level of education, and columns are reasons.'
#' intro_children <- gsub('\n', ' ', intro_children) |>
#' stringr::str_squish()
#'
#' req_children <- "Please explain the main differences
#' between more educated and less educated couples,
#' when it comes to hesitating to have children."
#' req_children <- gsub('\n', ' ', req_children) |>
#' stringr::str_squish()
#'
#' res_children <- nail_descfreq(children,
#'                               introduction = intro_children,
#'                               request = req_children,
#'                               generate = TRUE)
#'
#' cat(res_children$response)
#' }
#'
#' @importFrom FactoMineR descfreq
#' @importFrom glue glue
nail_descfreq <- function(dataset,
                          introduction = NULL,
                          request = NULL,
                          conclusion = NULL,
                          model = "llama3",
                          provider = c("ollama", "gemini"),
                          isolate.groups = FALSE,
                          sample.pct = 1,
                          drop.negative = FALSE,
                          by.quali = NULL,
                          proba = 0.05,
                          interpretation_mode = c("description", "comparison"),
                          rows_are_ordered = FALSE,
                          explicit_row_labels = FALSE,
                          generate = FALSE,
                          ...) {

  interpretation_mode <- match.arg(interpretation_mode)

  provider <- match.arg(provider)

  validate_descfreq_inputs(
    dataset = dataset,
    sample.pct = sample.pct,
    proba = proba,
    isolate.groups = isolate.groups,
    drop.negative = drop.negative,
    rows_are_ordered = rows_are_ordered,
    explicit_row_labels = explicit_row_labels,
    generate = generate
  )

  if (is.null(introduction)) {
    introduction <- "The table analyzed here is a contingency table. Each row represents a category to be interpreted through the column attributes that are unusually frequent or unusually infrequent relative to the overall table."
  }

  if (is.null(request)) {
    request <- build_request_descfreq(
      isolate.groups = isolate.groups,
      interpretation_mode = interpretation_mode,
      rows_are_ordered = rows_are_ordered,
      explicit_row_labels = explicit_row_labels
    )
  }

  if (is.null(conclusion)) {
    conclusion <- build_conclusion_descfreq(
      isolate.groups = isolate.groups,
      interpretation_mode = interpretation_mode,
      rows_are_ordered = rows_are_ordered,
      explicit_row_labels = explicit_row_labels
    )
  }

  guide_descfreq <- build_guide_descfreq(
    proba = proba,
    interpretation_mode = interpretation_mode,
    rows_are_ordered = rows_are_ordered,
    explicit_row_labels = explicit_row_labels
  )

  introduction <- paste(
    introduction,
    guide_descfreq,
    sep = "\n\n---\n\n"
  )

  res_df <- FactoMineR::descfreq(dataset, by.quali = by.quali, proba = proba)

  ppt <- tryCatch(
    get_prompt_descfreq(
      res_df = res_df,
      introduction = introduction,
      request = request,
      conclusion = conclusion,
      isolate.groups = isolate.groups,
      sample.pct = sample.pct,
      drop.negative = drop.negative,
      proba = proba,
      interpretation_mode = interpretation_mode,
      rows_are_ordered = rows_are_ordered
    ),
    error = function(e) {
      if (grepl("No significant differences", conditionMessage(e))) {
        "NAILER_NO_RESULTS_FOUND"
      } else {
        stop(e)
      }
    }
  )

  if (identical(ppt, "NAILER_NO_RESULTS_FOUND")) {
    no_results_message <- glue::glue(
      "*No retained over- or under-represented attributes were found under the chosen threshold (p <= {proba}).*"
    )

    if (generate) {
      message("Execution halted: No retained differences found. Nothing to generate.")
      if (isolate.groups) {
        out <- list()
        attr(out, "descfreq_result") <- res_df
        return(out)
      }
      out <- data.frame(
        model = model,
        response = "No retained differences found.",
        prompt = no_results_message,
        stringsAsFactors = FALSE
      )
      attr(out, "descfreq_result") <- res_df
      return(out)
    }

    header <- glue::glue(
      "# Introduction - Objective\n\n{introduction}\n\n",
      "# Task\n\n{request}\n\n",
      "---\n\n",
      "# Data\n\n"
    )
    out <- normalize_blank_lines(paste0(header, no_results_message))
    attr(out, "descfreq_result") <- res_df
    return(out)
  }

  if (!generate) {
    attr(ppt, "descfreq_result") <- res_df
    return(ppt)
  }

  extra_args <- list(...)
  llm_api_options <- extra_args

  .call_llm <- function(prompt) {
    res_llm <- .call_llm_base(
      provider = provider,
      model = model,
      prompt = prompt,
      output = "text",
      llm_api_options = llm_api_options
    )

    list(prompt = prompt, response = res_llm, model = model)
  }

  if (!isolate.groups) {
    out <- .call_llm(ppt)
    attr(out, "descfreq_result") <- res_df
    return(out)
  }

  res_list <- lapply(ppt, .call_llm)
  if (!is.null(names(ppt))) {
    names(res_list) <- names(ppt)
  }
  attr(res_list, "descfreq_result") <- res_df
  res_list
}
