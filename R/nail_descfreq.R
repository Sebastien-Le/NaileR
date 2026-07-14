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
    "Treat evidence as graded within the retained results:",
    paste0(
      "* all displayed attributes satisfy p.value <= ",
      proba,
      "."
    ),
    "* smaller p.values indicate stronger statistical evidence.",
    "* larger absolute v.test values indicate stronger departures from the global proportion.",
    "* interpret results with comparatively larger p.values more cautiously.",
    "Prioritize the smallest p.values and the largest absolute v.test values."
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

#' Interpret rows or groups of rows in a contingency table
#'
#' Characterizes the rows of a contingency table using
#' `FactoMineR::descfreq()`, formats the retained over-represented and
#' under-represented column attributes as an evidence-based prompt, and
#' optionally sends this prompt to a large language model.
#'
#' Each row is interpreted as a relative profile. The function identifies the
#' column attributes whose proportions within that row are unusually high or
#' unusually low compared with their proportions in the complete contingency
#' table.
#'
#' Rows may be interpreted separately, compared with one another, treated as
#' ordered levels, or merged into broader groups using `by.quali`.
#'
#' @param dataset A data frame representing a contingency table. Rows
#'   correspond to the categories or objects to be characterized, columns
#'   correspond to descriptive attributes, and cells contain frequencies.
#'   The table should contain at least one row and two columns. Meaningful row
#'   names and column names are strongly recommended because they are included
#'   in the prompt and used by the language model during interpretation.
#' @param introduction An optional character string providing the study
#'   context in the prompt. It should explain what the rows, columns, and
#'   frequencies represent. If `NULL`, a generic introduction describing the
#'   table as a contingency table is created automatically.
#' @param request An optional character string describing the interpretation
#'   expected from the language model. If `NULL`, a default request is created
#'   according to `interpretation_mode`, `isolate.groups`,
#'   `rows_are_ordered`, and `explicit_row_labels`.
#' @param conclusion An optional character string containing final
#'   instructions about the expected synthesis and output format. If `NULL`,
#'   a default conclusion is created according to `interpretation_mode`,
#'   `isolate.groups`, `rows_are_ordered`, and `explicit_row_labels`.
#' @param model Character string giving the model used by the selected
#'   provider. The default is `"llama3"`, intended for the default Ollama
#'   backend.
#' @param provider LLM backend used when `generate = TRUE`. One of
#'   `"ollama"` or `"gemini"`. The default is `"ollama"`. Gemini requires a
#'   valid API key, typically supplied through the `GEMINI_API_KEY`
#'   environment variable.
#' @param isolate.groups Logical. If `FALSE`, a single prompt containing all
#'   rows or row groups is created. If `TRUE`, one prompt is created for each
#'   row or each group defined by `by.quali`.
#'
#'   Using `isolate.groups = TRUE` can be useful when the contingency table
#'   contains many rows or when each profile should be interpreted
#'   independently. However, a single combined prompt is generally preferable
#'   when the objective is to compare rows directly.
#' @param sample.pct A numeric value between 0 and 1 giving the proportion of
#'   retained descriptive attributes included in the prompt. The default is
#'   `1`, meaning that all attributes retained by
#'   `FactoMineR::descfreq()` are included.
#'
#'   When `sample.pct < 1`, a stratified sample is selected across the
#'   distribution of v-test values so that the prompt retains attributes with
#'   different levels and directions of association. Use `set.seed()` before
#'   calling the function when reproducible sampling is required.
#' @param drop.negative Logical. If `FALSE`, both over-represented attributes
#'   with positive v-tests and under-represented attributes with negative
#'   v-tests are included. If `TRUE`, attributes with negative v-tests are
#'   omitted and only over-represented attributes are presented.
#'
#'   Keeping the negative v-tests is generally recommended for a complete
#'   interpretation because an unusually low frequency may be as informative
#'   as an unusually high frequency.
#' @param by.quali An optional factor used to merge rows of `dataset` before
#'   characterization. It must associate each original row with a group. When
#'   `NULL`, each row is characterized separately. When supplied,
#'   `FactoMineR::descfreq()` characterizes the groups defined by the factor
#'   rather than the original rows.
#' @param proba A numeric value between 0 and 1 giving the significance
#'   threshold used by `FactoMineR::descfreq()` to retain descriptive
#'   attributes. The default is `0.05`.
#' @param interpretation_mode Character string specifying the main objective
#'   of the interpretation. One of `"description"` or `"comparison"`.
#'
#'   With `"description"`, each row is primarily interpreted as a relative
#'   profile using its over-represented and under-represented attributes.
#'
#'   With `"comparison"`, the prompt emphasizes the main contrasts,
#'   similarities, and distinctive profiles across rows.
#' @param rows_are_ordered Logical indicating whether the order of the rows
#'   has a substantive meaning. If `TRUE`, the prompt asks the language model
#'   to examine possible gradients, transitions, or intermediate positions
#'   across rows.
#'
#'   This argument does not sort or reorder `dataset`. The rows must already
#'   be supplied in the intended substantive order. The model is also
#'   instructed not to force a gradient when the retained evidence does not
#'   support one.
#' @param explicit_row_labels Logical indicating whether the row names already
#'   have an explicit substantive meaning. If `TRUE`, the prompt instructs the
#'   language model not to rename the rows. If `FALSE`, the model may propose
#'   short descriptive names when the statistical evidence is sufficiently
#'   clear.
#'
#'   This argument does not create or modify the row names of `dataset`.
#' @param generate Logical. If `FALSE`, no language model is called and the
#'   function returns the constructed prompt or prompts. If `TRUE`, each
#'   prompt is sent to the selected provider.
#' @param ... Additional provider-specific generation arguments passed to the
#'   selected LLM backend, such as `temperature`, `seed`, or other supported
#'   options.
#'
#' @details
#' The statistical characterization is computed with
#' `FactoMineR::descfreq()`.
#'
#' For each row, or each group of rows defined through `by.quali`, the
#' proportion of each column attribute within that row is compared with the
#' overall proportion of the same attribute in the complete table.
#'
#' The resulting tables may contain the following statistics:
#'
#' - `Intern %`: percentage of the attribute within the current row or group;
#' - `glob %`: overall percentage of the attribute in the complete table;
#' - `Intern freq`: observed frequency of the attribute within the current row
#'   or group;
#' - `Glob freq`: overall frequency of the attribute in the complete table;
#' - `p.value`: probability associated with the statistical characterization;
#' - `v.test`: standardized measure of the direction and strength of the
#'   difference from the global proportion.
#'
#' A positive v-test indicates that an attribute is over-represented within
#' the row relative to the complete table. A negative v-test indicates that
#' the attribute is under-represented. Larger absolute v-test values indicate
#' stronger departures from the global proportion.
#'
#' The rows must therefore be interpreted as relative profiles, not merely
#' from their raw frequencies. An attribute may have a large frequency in a
#' row without being characteristic of that row when the same attribute is
#' also frequent throughout the table.
#'
#' ## Interpretation modes
#'
#' With `interpretation_mode = "description"`, the prompt asks for a
#' description of each row based on its characteristic and uncharacteristic
#' attributes. When all rows are included in one prompt, a brief synthesis of
#' the most distinctive profiles is also requested.
#'
#' With `interpretation_mode = "comparison"`, the prompt asks the language
#' model to compare the rows and identify their main contrasts, proximities,
#' and distinctive profiles. This mode is most informative when
#' `isolate.groups = FALSE`, because all rows are then available in the same
#' prompt.
#'
#' When `interpretation_mode = "comparison"` and
#' `isolate.groups = TRUE`, each row is still processed separately. The model
#' can describe how that row differs from the global table, but it cannot
#' perform a complete direct comparison with rows that are absent from the
#' current prompt.
#'
#' ## Ordered rows
#'
#' Setting `rows_are_ordered = TRUE` indicates that the row sequence has a
#' substantive interpretation, such as increasing education, age, intensity,
#' preference, or performance levels.
#'
#' In description mode, the row order is used as contextual information and
#' the model may discuss intermediate positions or broader tendencies.
#'
#' In comparison mode, the model is explicitly asked to examine whether the
#' profiles form a gradient. It must nevertheless report mixed patterns,
#' discontinuities, or exceptions when the evidence does not support a simple
#' progression.
#'
#' ## Row labels
#'
#' Setting `explicit_row_labels = TRUE` is appropriate when row names already
#' have a clear meaning, such as `"No education"`, `"High school"`, or
#' `"University"`. The model is then instructed to preserve these names.
#'
#' Setting `explicit_row_labels = FALSE` allows the model to propose a
#' descriptive name for a row when this helps summarize its relative profile.
#' The proposed name is generated text only: the function does not modify the
#' row names of `dataset`.
#'
#' ## Prompt construction and generation
#'
#' The `introduction`, statistical reading guide, `request`, retained
#' statistical tables, and `conclusion` are combined into one structured
#' prompt.
#'
#' If `isolate.groups = FALSE`, all row profiles are included in this prompt.
#' If `isolate.groups = TRUE`, the same introduction, request, and conclusion
#' are combined separately with the statistical results for each row or row
#' group.
#'
#' By default, `generate = FALSE`, so no language model is called. When
#' `generate = TRUE`, the default backend is Ollama and the default model is
#' `"llama3"`. These defaults can be changed with `provider` and `model`.
#'
#' No causal conclusion should be inferred from the reported associations.
#' The results describe departures from global proportions within the
#' contingency table.
#'
#' @return
#' The returned object depends on `generate` and `isolate.groups`.
#'
#' When `generate = FALSE`:
#'
#' - if `isolate.groups = FALSE`, a character string containing the complete
#'   prompt is returned;
#' - if `isolate.groups = TRUE`, a named list of character prompts is
#'   returned, with one element per row or row group.
#'
#' When `generate = TRUE`:
#'
#' - if `isolate.groups = FALSE`, a list with components `prompt`,
#'   `response`, and `model` is returned;
#' - if `isolate.groups = TRUE`, a named list is returned, with one generated
#'   result per row or row group. Each result contains `prompt`, `response`,
#'   and `model`.
#'
#' In all normal cases, the complete object returned by
#' `FactoMineR::descfreq()` is stored in the `"descfreq_result"` attribute.
#'
#' If no over-represented or under-represented attributes are retained under
#' the chosen threshold, the LLM is not called and an informative result is
#' returned.
#'
#' @export
#'
#' @examples
#' \dontrun{
#' # Some examples below use a large language model and may therefore
#' # take more than ten seconds to run.
#'
#' # Generated responses explicitly use:
#' # - the local Ollama backend;
#' # - the llama3 model.
#'
#' # Ollama must be running locally and the llama3 model must be installed.
#' # To use Gemini instead, set:
#' # provider = "gemini"
#' # model = "<a supported Gemini model>"
#' # and define the GEMINI_API_KEY environment variable.
#'
#' # The interpretation_mode argument controls the main objective:
#' #
#' # - "description" describes each row as a relative profile;
#' # - "comparison" emphasizes contrasts and similarities across rows.
#'
#' # rows_are_ordered = TRUE indicates that the current row order
#' # has a substantive meaning. It does not reorder the table.
#'
#' # explicit_row_labels = TRUE preserves existing row names.
#' # With FALSE, the model may propose descriptive names.
#'
#'
#' ### Example 1: beard dataset and isolated prompt construction ###
#'
#' library(NaileR)
#' data(beard_cont)
#'
#' # The rows represent eight types of beards and the columns represent
#' # descriptive attributes or uses recorded by the assessors.
#' intro_beard <- "A survey was conducted about eight types of beards.
#' The rows of the contingency table represent the beards,
#' and the columns represent descriptive attributes reported by assessors."
#'
#' intro_beard <- gsub("\n", " ", intro_beard) |>
#'   stringr::str_squish()
#'
#' # The beard codes do not have an explicit substantive meaning.
#' # Therefore, explicit_row_labels = FALSE allows the model to propose
#' # descriptive names when the statistical evidence is sufficient.
#' #
#' # isolate.groups = TRUE creates one prompt per beard.
#' # generate = FALSE means that no language model is called.
#' prompts_beard <- nail_descfreq(
#'   dataset = beard_cont,
#'   introduction = intro_beard,
#'   interpretation_mode = "description",
#'   isolate.groups = TRUE,
#'   rows_are_ordered = FALSE,
#'   explicit_row_labels = FALSE,
#'   drop.negative = FALSE,
#'   generate = FALSE
#' )
#'
#' # Display the prompt created for the first beard.
#' cat(prompts_beard[[1]])
#'
#' # Display the names of all isolated prompts.
#' names(prompts_beard)
#'
#'
#' ### Example 2: beard dataset with one generated comparative response ###
#'
#' req_beard <- "Compare the relative profiles of the eight beards.
#' For each beard, identify its most characteristic
#' and least characteristic attributes.
#' Propose a short descriptive name only when the evidence is clear."
#'
#' req_beard <- gsub("\n", " ", req_beard) |>
#'   stringr::str_squish()
#'
#' # All rows are included in one prompt so that the model can compare them
#' # directly. Both positive and negative v-tests are retained.
#' res_beard <- nail_descfreq(
#'   dataset = beard_cont,
#'   introduction = intro_beard,
#'   request = req_beard,
#'   interpretation_mode = "comparison",
#'   isolate.groups = FALSE,
#'   rows_are_ordered = FALSE,
#'   explicit_row_labels = FALSE,
#'   drop.negative = FALSE,
#'   provider = "ollama",
#'   model = "llama3",
#'   generate = TRUE
#' )
#'
#' # Display the generated interpretation.
#' cat(res_beard$response)
#'
#' # Inspect the exact prompt sent to Ollama.
#' cat(res_beard$prompt)
#'
#' # Access the complete statistical result produced by descfreq().
#' beard_descfreq <- attr(res_beard, "descfreq_result")
#'
#'
#' ### Example 3: ordered education levels in the children dataset ###
#'
#' data(children, package = "FactoMineR")
#'
#' # Retain five education levels and fourteen possible reasons,
#' # then transpose the table so that education levels are in rows.
#' children_table <- children[1:14, 1:5] |>
#'   t() |>
#'   as.data.frame()
#'
#' rownames(children_table) <- c(
#'   "No education",
#'   "Elementary school",
#'   "Middle school",
#'   "High school",
#'   "University"
#' )
#'
#' intro_children <- "This contingency table summarizes answers
#' to a survey question about reasons that may make
#' a woman or a couple hesitate to have children.
#' Rows represent ordered education levels,
#' from no education to university,
#' and columns represent the possible reasons."
#'
#' intro_children <- gsub("\n", " ", intro_children) |>
#'   stringr::str_squish()
#'
#' req_children <- "Compare the relative profiles across education levels.
#' Identify the main differences between lower and higher education levels.
#' Determine whether the rows form a clear gradient,
#' and report intermediate transitions or exceptions."
#'
#' req_children <- gsub("\n", " ", req_children) |>
#'   stringr::str_squish()
#'
#' # The row order is meaningful, so rows_are_ordered = TRUE.
#' # The education labels already have an explicit meaning,
#' # so explicit_row_labels = TRUE prevents their renaming.
#' res_children <- nail_descfreq(
#'   dataset = children_table,
#'   introduction = intro_children,
#'   request = req_children,
#'   interpretation_mode = "comparison",
#'   rows_are_ordered = TRUE,
#'   explicit_row_labels = TRUE,
#'   isolate.groups = FALSE,
#'   drop.negative = FALSE,
#'   provider = "ollama",
#'   model = "llama3",
#'   generate = TRUE
#' )
#'
#' cat(res_children$response)
#'
#'
#' ### Example 4: merge rows into broader education groups ###
#'
#' # by.quali may be used to merge the five original rows
#' # into broader groups before characterization.
#' education_group <- factor(
#'   c(
#'     "Lower education",
#'     "Lower education",
#'     "Secondary education",
#'     "Secondary education",
#'     "Higher education"
#'   ),
#'   levels = c(
#'     "Lower education",
#'     "Secondary education",
#'     "Higher education"
#'   )
#' )
#'
#' # Here only the prompt is constructed.
#' # The three grouped levels are interpreted as an ordered sequence.
#' prompt_education_groups <- nail_descfreq(
#'   dataset = children_table,
#'   introduction = intro_children,
#'   by.quali = education_group,
#'   interpretation_mode = "comparison",
#'   rows_are_ordered = TRUE,
#'   explicit_row_labels = TRUE,
#'   isolate.groups = FALSE,
#'   generate = FALSE
#' )
#'
#' cat(prompt_education_groups)
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
      message(
        "Execution halted: No retained differences found. Nothing to generate."
      )

      if (isolate.groups) {
        out <- list()
        attr(out, "descfreq_result") <- res_df
        return(out)
      }

      out <- list(
        prompt = no_results_message,
        response = "No retained differences found.",
        model = model
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
