remove_punctuation <- function(text) {
  gsub("[[:punct:]]", "", text)
}


#' Sort textual data
#'
#' Group textual data according to their similarity, in a context in which the assessors have commented on a set of stimuli.
#'
#' @param dataset a data frame where each row is a stimulus and each column is an assessor.
#' @param name_size the maximum number of words in a group name created by the LLM.
#' @param stimulus_id the nature of the stimulus. Customizing it is highly recommended.
#' @param introduction the introduction to the LLM prompt.
#' @param measure the type of measure used in the experiment.
#' @param request the request of the LLM prompt.
#' @param model the model name for the selected provider ('llama3.1' by default for Ollama).
#' @param provider LLM backend to use for generation. Use `"ollama"` for a local Ollama model or `"gemini"` for Google Gemini via `GEMINI_API_KEY`.
#' @param nb.clusters the maximum number of clusters the LLM can form per assessor.
#' @param generate a boolean that indicates whether to generate the LLM response. If FALSE, the function only returns the prompt.
#' @param max.attempts the maximum number of attempts for a column.
#' @param ... Additional provider-specific generation arguments passed to the selected LLM backend.
#'
#' @return A list consisting of:
#' * a list of prompts (one per assessor);
#' * a list of results (one per assessor);
#' * a data frame with the group names.
#'
#' @details This function uses a while loop to ensure that the LLM gives the right number of groups. Therefore, customizing the stimulus ID, prompt introduction and measure is highly recommended; a clear prompt can help the LLM finish its task faster.
#'
#' @export
#'
#' @examples
#'\dontrun{
#' # Processing time is often longer than ten seconds
#' # because the function uses a large language model.
#'
#' library(NaileR)
#' data(beard_wide)
#'
#' intro_beard <- "As a barber, you make
#' recommendations based on consumers comments.
#' Examples of consumers descriptions of beards
#' are as follows."
#' intro_beard <- gsub('\n', ' ', intro_beard) |>
#' stringr::str_squish()
#'
#' req_beard <- "Each group should contain beards with descriptions
#' that relate to a similar type of person - not
#' necessarily the same person, but sharing common traits.
#' Each group must have a short,
#' meaningful name that characterizes the person."
#' req_beard <- gsub('\n', ' ', req_beard) |>
#' stringr::str_squish()
#'
#' res <- nail_sort(beard_wide[,1:5], name_size = 3,
#' stimulus_id = "beard", introduction = intro_beard,
#' measure = 'the description was',
#' request = req_beard,
#' nb.clusters = 6,
#' generate = TRUE)
#'
#' cat(res$prompt_llm[[1]])
#' cat(res$res_llm[[1]])
#' res$dta_sort
#' }


#' @importFrom glue glue
#' @importFrom ollamar generate
#' @importFrom stringr str_split_1 str_squish str_count str_remove_all str_extract
#' @importFrom utils tail
#' @importFrom jsonlite fromJSON

nail_sort <- function(dataset, name_size = 3, stimulus_id = "individual",
                      introduction = NULL, measure = NULL, request = NULL, model = "llama3.1", provider = c("ollama", "gemini"),
                      nb.clusters = 4, generate = FALSE, max.attempts = 5, ...) {

  provider <- match.arg(provider)

  assert_data_frame(dataset, "dataset")
  if (nrow(dataset) < 2 || ncol(dataset) < 1) {
    stop("`dataset` must contain at least two rows and one column.", call. = FALSE)
  }
  assert_positive_integerish(name_size, "name_size")
  assert_positive_integerish(nb.clusters, "nb.clusters")
  assert_positive_integerish(max.attempts, "max.attempts")
  assert_single_logical(generate, "generate")

  if (nb.clusters < 2) {
    stop("`nb.clusters` must be at least 2.", call. = FALSE)
  }
  if (nb.clusters > nrow(dataset)) {
    stop("`nb.clusters` cannot exceed the number of rows in `dataset`.", call. = FALSE)
  }

  prompts <- vector("list", ncol(dataset))
  responses <- vector("list", ncol(dataset))
  sorted_groups <- dataset[, FALSE]

  introduction <- if (is.null(introduction)) "Individuals are described by free comments." else introduction
  measure <- if (is.null(measure)) "the description was" else measure
  request <- if (is.null(request)) "Each group should contain individuals with similar descriptions and have a short, meaningful name." else request

  extra_args <- list(...)
  llm_api_options <- extra_args

  for (j in seq_len(ncol(dataset))) {
    dta_j <- as.character(dataset[[j]])
    dta_j[is.na(dta_j)] <- ""
    liste <- character(nrow(dataset))

    for (i in seq_len(nrow(dataset))) {
      texte_j <- stringr::str_split_1(dta_j[i], pattern = ";") |>
        paste(collapse = ", ")
      liste[i] <- glue::glue("For {stimulus_id} {i}, {measure} '{texte_j}'.")
    }

    descr <- paste(liste, collapse = " ")

    json_instruction <- glue::glue(
      "Please categorize the {nrow(dataset)} {stimulus_id}s into groups while strictly ensuring that the total number of groups is between 2 and {nb.clusters}. ",
      "This is a hard constraint: do not exceed {nb.clusters} groups and do not use fewer than 2 groups. ",
      "Do not provide explanations, justifications, or any extra text. ",
      "You must output only a valid JSON array of objects, with no other text before or after. ",
      "Each object in the array must represent one {stimulus_id} and have two keys: ",
      "`stimulus_id` (numeric ID from 1 to {nrow(dataset)}) and `group_name` (max {name_size} words). ",
      "Ensure all {nrow(dataset)} {stimulus_id}s are present exactly once. ",
      "Example format:\n\n",
      "[\n",
      "  {{\"stimulus_id\": 1, \"group_name\": \"Group Name A\"}},\n",
      "  {{\"stimulus_id\": 2, \"group_name\": \"Group Name B\"}}\n",
      "]",
      "\n\nUser request: {request}"
    )

    prompt <- paste(introduction, descr, json_instruction)
    prompts[[j]] <- prompt

    grps <- rep(NA_character_, nrow(dataset))

    if (generate) {
      for (attempt in seq_len(max.attempts)) {
        response_raw <- tryCatch({
          res <- .call_llm_base(
            provider = provider,
            model = model,
            prompt = prompt,
            output = "df",
            llm_api_options = llm_api_options
          )
          paste(res$response, collapse = "\n")
        }, error = function(e) {
          message(glue::glue("Column {j}, attempt {attempt}: API call failed: {conditionMessage(e)}"))
          NULL
        })

        if (is.null(response_raw)) {
          responses[[j]] <- "API call failed"
          next
        }

        responses[[j]] <- response_raw

        parsed_data <- tryCatch(
          .parse_json_response(response_raw, simplifyDataFrame = TRUE),
          error = function(e) {
            message(glue::glue("Column {j}, attempt {attempt}: failed to parse JSON. Retrying..."))
            NULL
          }
        )

        if (is.null(parsed_data)) next

        if (!is.data.frame(parsed_data) || !all(c("stimulus_id", "group_name") %in% names(parsed_data))) {
          message(glue::glue("Column {j}, attempt {attempt}: JSON structure incorrect. Retrying..."))
          next
        }

        if (nrow(parsed_data) != nrow(dataset)) {
          message(glue::glue("Column {j}, attempt {attempt}: incorrect number of items in JSON ({nrow(parsed_data)} found, {nrow(dataset)} expected). Retrying..."))
          next
        }

        parsed_data$stimulus_id <- suppressWarnings(as.numeric(parsed_data$stimulus_id))
        parsed_data <- parsed_data[order(parsed_data$stimulus_id), , drop = FALSE]

        if (!identical(parsed_data$stimulus_id, as.numeric(seq_len(nrow(dataset))))) {
          message(glue::glue("Column {j}, attempt {attempt}: missing, duplicated, or invalid stimulus IDs. Retrying..."))
          next
        }

        candidate_groups <- stringr::str_squish(as.character(parsed_data$group_name))
        if (any(is.na(candidate_groups)) || any(!nzchar(candidate_groups))) {
          message(glue::glue("Column {j}, attempt {attempt}: empty group name found. Retrying..."))
          next
        }

        nb_words <- max(stringr::str_count(candidate_groups, "\\w+"), na.rm = TRUE)
        if (nb_words > name_size) {
          message(glue::glue("Column {j}, attempt {attempt}: group name too long ({nb_words} words, max {name_size}). Retrying..."))
          next
        }

        nb_unique_grps <- length(unique(candidate_groups))
        if (nb_unique_grps > nb.clusters || nb_unique_grps < 2) {
          message(glue::glue("Column {j}, attempt {attempt}: incorrect number of groups ({nb_unique_grps} found, expected 2-{nb.clusters}). Retrying..."))
          next
        }

        grps <- candidate_groups
        attempt_word <- ifelse(attempt == 1, "attempt", "attempts")
        message(glue::glue("Column {j} generated after {attempt} {attempt_word}."))
        break
      }

      if (all(is.na(grps))) {
        message(glue::glue("Column {j}: maximum attempts ({max.attempts}) reached. Returning NA values."))
      }

      sorted_groups[, j] <- grps
      colnames(sorted_groups)[j] <- colnames(dataset)[j]
    }
  }

  out <- list(
    prompts = prompts,
    responses = responses,
    sorted_groups = sorted_groups,
    prompt_llm = prompts,
    res_llm = responses,
    dta_sort = sorted_groups
  )
  out
}
