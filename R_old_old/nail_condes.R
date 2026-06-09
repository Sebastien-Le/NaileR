#' @importFrom dplyr mutate across where case_when filter desc arrange
#' @importFrom glue glue
#' @importFrom tibble rownames_to_column column_to_rownames
#' @importFrom dplyr slice_sample group_by select ungroup
#' @importFrom stats quantile
#' @importFrom FactoMineR condes
#' @importFrom rlang .data

# ===========================================================================
# UTILS — shared helpers
# ===========================================================================

#' @importFrom dplyr mutate
#' @importFrom dplyr across
#' @importFrom dplyr where
#' @importFrom dplyr case_when
get_bins <- function(dataset, keep, quanti.threshold, quanti.cat) {
  dta <- dataset |>
    mutate(across(where(is.numeric), scale), .keep = "all")

  dta <- dta |>
    mutate(across(
      where(is.numeric),
      ~ as.factor(case_when(
        . >= quanti.threshold ~ quanti.cat[1],
        . <= -quanti.threshold ~ quanti.cat[2],
        .default = quanti.cat[3]
      ))
    ))

  cbind(dataset[, keep, drop = FALSE], dta)
}

normalize_blank_lines <- function(x) {
  gsub("\\n{3,}", "\n\n", x)
}

# ===========================================================================
# UTILS — vocabulary helpers
# ===========================================================================

.target_kind <- function(mode) {
  if (mode == "standard") {
    "the explicit measured variable"
  } else {
    "a latent continuous score"
  }
}

.continuous_title <- function(mode) {
  if (mode == "standard") {
    "Continuous variables associated with the target variable"
  } else {
    "Continuous variables associated with the scale"
  }
}

.quali_global_title <- function(mode) {
  if (mode == "standard") {
    "Qualitative variables globally associated with the target variable"
  } else {
    "Qualitative variables globally associated with the scale"
  }
}

.profiles_main_title <- function(mode) {
  if (mode == "standard") {
    "Typical profiles at the low and high ends of the target variable"
  } else {
    "Typical profiles at the low and high ends of the scale"
  }
}

.low_end_title <- function(mode) {
  if (mode == "standard") {
    "Typical categories associated with the low end of the target variable"
  } else {
    "Typical categories associated with the low end of the scale"
  }
}

.high_end_title <- function(mode) {
  if (mode == "standard") {
    "Typical categories associated with the high end of the target variable"
  } else {
    "Typical categories associated with the high end of the scale"
  }
}

# ===========================================================================
# Prompt builders
# ===========================================================================

build_request_condes <- function(
    mode = c("standard", "latent"),
    target_concept = "the target concept",
    target_label = "the target variable",
    prompt_style = c("detailed", "compact")
) {
  mode <- match.arg(mode)
  prompt_style <- match.arg(prompt_style)

  if (mode == "standard") {
    if (prompt_style == "compact") {
      return(paste(
        paste0("Interpret '", target_label, "' as an explicit measured variable using only the results below."),
        "",
        "Guide:",
        "- Variable-level evidence is the main evidence.",
        "- Profile-level evidence only illustrates the low and high ends.",
        paste0("- A positive correlation means higher values tend to go with higher values of '", target_label, "'; a negative correlation means the opposite."),
        "- A negative Estimate indicates a category more typical of the low end; a positive Estimate indicates a category more typical of the high end.",
        "",
        "Steps and rules:",
        paste0("1. Identify the strongest variables associated with '", target_label, "'."),
        paste0("2. Interpret them using their substantive meaning, not only their sign or raw value."),
        paste0("3. Describe the low end and the high end of '", target_label, "'."),
        paste0("4. Explain whether the main associations seem expected, unexpected, or mixed given the meaning of '", target_label, "'."),
        "5. Use all displayed results, not only those below p < 0.05.",
        "6. Treat smaller p.values as stronger evidence and larger p.values as weaker or more tentative evidence.",
        "7. If a displayed result has a relatively large p.value, discuss it as a tendency or weak signal rather than as a firm conclusion.",
        "8. Do not invent causal explanations.",
        "",
        "Required output:",
        paste0("1. Meaning of ", target_label),
        paste0("2. Low end of ", target_label),
        paste0("3. High end of ", target_label),
        paste0("4. Interpretation of the associations with ", target_label),
        sep = "\n"
      ))
    }

    return(paste(
      paste0("Using only the results below, interpret '", target_label, "' as an explicit measured variable."),
      "",
      "Steps:",
      paste0("1. Identify the strongest continuous variables associated with '", target_label, "'."),
      paste0("2. Determine whether higher values of the strongest variables correspond to a more favorable or less favorable meaning for '", target_label, "'."),
      paste0("3. Describe what characterizes the low end of '", target_label, "'."),
      paste0("4. Describe what characterizes the high end of '", target_label, "'."),
      paste0("5. Explain whether the main associations seem expected, unexpected, or mixed, given the meaning of '", target_label, "'."),
      paste0("6. Summarize what these results add to the understanding of '", target_label, "'."),
      "7. Mention any weak, mixed, ambiguous, or counterintuitive evidence.",
      "",
      "Rules:",
      paste0("- Do not rename '", target_label, "'."),
      "- Do not invent a new latent dimension.",
      "- Do not simply restate the tables.",
      "- Use the continuous associations as the main evidence and the profile-level categories as illustrations.",
      "- Pay close attention to what higher or lower values mean for each observed variable.",
      "- Base your interpretation on the substantive meaning of the variables, not only on whether their values are high or low.",
      "- Translate raw variable values into substantive meaning whenever possible.",
      paste0("- Comment on whether the direction of the strongest associations is coherent with the meaning of '", target_label, "'."),
      "- If some associations seem surprising or difficult to interpret, say so explicitly.",
      "- Do not invent causal explanations.",
      "- Use all displayed results, not only those below p < 0.05.",
      "- Treat smaller p.values as stronger evidence and larger p.values as weaker or more tentative evidence.",
      "- If a displayed result has a relatively large p.value, discuss it as a tendency, a weak signal, or a tentative pattern rather than as a firm conclusion.",
      "",
      "Your answer must contain exactly these four sections:",
      paste0("1. Meaning of ", target_label),
      paste0("2. Low end of ", target_label),
      paste0("3. High end of ", target_label),
      paste0("4. Interpretation of the associations with ", target_label),
      sep = "\n"
    ))
  }

  if (prompt_style == "compact") {
    return(paste(
      "Interpret this scale as one continuous latent dimension using only the results below.",
      "",
      "Guide:",
      "1. Variable-level = main evidence.",
      "2. Profile-level = secondary evidence illustrating the two ends.",
      "3. Interpret variables by their substantive meaning, not only by their sign.",
      "",
      "Steps and rules:",
      "1. Identify the strongest associations.",
      "2. Translate the strongest variables into their substantive meaning.",
      "3. Describe the low end and the high end using this substantive meaning.",
      "4. Infer the common underlying meaning that best explains both ends.",
      "5. Use all displayed results, not only those below p < 0.05.",
      "6. Treat smaller p.values as stronger evidence and larger p.values as weaker or more tentative evidence.",
      "7. In the final justification, include one sentence beginning with: 'What separates the high end from the low end of the scale is...'",
      "8. Propose a unifying name for the continuum.",
      if (identical(target_concept, "the target concept")) {
        "9. Avoid overly generic names unless no more specific interpretation is supported."
      } else {
        paste0("9. Avoid generic names such as '", target_concept, "' unless no more specific interpretation is supported.")
      },
      "10. Do not invent causal explanations.",
      "",
      "Required output:",
      "1. Main continuum",
      "2. Low end of the scale",
      "3. High end of the scale",
      "4. Proposed latent dimension and justification",
      sep = "\n"
    ))
  }

  paste(
    "Using only the results below, interpret the scale as one latent continuous dimension.",
    "",
    "Steps:",
    "1. Identify the strongest continuous associations.",
    "2. For the strongest variables, determine whether higher values correspond to a more favorable or less favorable meaning on the continuum.",
    "3. Translate the strongest variables into their substantive meaning before interpreting the scale.",
    "4. Describe the low end of the scale using this substantive meaning.",
    "5. Describe the high end of the scale using this substantive meaning.",
    "6. Infer the common underlying meaning that best explains the strongest variables and the two end profiles along the same continuum.",
    "7. Distinguish the strongest evidence from weaker or more tentative tendencies based on the p.values shown in the tables.",
    "8. Before proposing names, write one sentence beginning with: 'What separates the high end from the low end of the scale is...'",
    "9. Propose two or three possible names for this continuum.",
    "10. Select the best name and justify why it best captures the common underlying meaning of the strongest and most coherent results.",
    "11. Mention any mixed, ambiguous, or only weakly supported evidence.",
    "",
    "Rules:",
    "- Treat the scale as one continuous latent dimension.",
    "- Treat the two ends as opposite manifestations of the same continuum.",
    "- Do not simply restate the tables.",
    "- Use the strongest and most coherent associations first.",
    "- Use profile-level categories only as illustrations of the two ends.",
    "- Pay close attention to what higher or lower values mean for each observed variable.",
    "- Do not assume that higher values always indicate a more favorable meaning.",
    "- Base your interpretation on the substantive meaning of the variables, not only on whether their values are high or low.",
    "- When describing the two ends, translate raw variable values into substantive meaning whenever possible.",
    "- The justification must remain consistent with the direction of the associations.",
    "- Do not invent causal explanations.",
    "- Consider the broader pattern formed by the strongest and most coherent variables together.",
    "- Do not base the name only on the first one or two variables in the table.",
    "- Prefer the simplest unifying latent name supported by most of the strongest results.",
    "- Prefer a general unifying name if most strong associations point in the same substantive direction.",
    "- If several names are plausible, prefer the one that best captures the continuum as a whole rather than only one end.",
    paste0("- Do not use a generic label such as 'perception', 'evaluation', 'attitude', or '", target_concept, "' unless no more specific interpretation is supported."),
    "- Do not propose a name that is more specific than the evidence supports.",
    "- The sentence 'What separates the high end from the low end of the scale is...' must reflect the main structural difference supported by the strongest variables.",
    "- Do not propose names before clearly stating this structural difference.",
    "- If you propose alternative names, include them inside the final section 'Proposed latent dimension and justification', not as separate sections.",
    "- Use all displayed results, not only those below p < 0.05.",
    "- Treat smaller p.values as stronger evidence and larger p.values as weaker or more tentative evidence.",
    "- If a displayed result has a relatively large p.value, discuss it as a tendency, a weak signal, or a tentative pattern rather than as a firm conclusion.",
    "",
    "Your answer must contain exactly these four sections:",
    "1. Main continuum",
    "2. Low end of the scale",
    "3. High end of the scale",
    "4. Proposed latent dimension and justification",
    sep = "\n"
  )
}

build_guide_condes <- function(mode = c("standard", "latent"),
                               target_label = "the target variable",
                               prompt_style = c("detailed", "compact")) {
  mode <- match.arg(mode)
  prompt_style <- match.arg(prompt_style)

  if (mode == "standard") {
    if (prompt_style == "compact") {
      return(paste(
        "## How to Read the Results",
        paste0("The target variable is '", target_label, "'."),
        "- Variable-level evidence is the main evidence.",
        "- Profile-level evidence only illustrates the low and high ends.",
        paste0("- A positive correlation means higher values tend to go with higher values of '", target_label, "'; a negative correlation means the opposite."),
        "- A negative Estimate indicates a category more typical of the low end; a positive Estimate indicates a category more typical of the high end.",
        sep = "\n"
      ))
    }

    return(paste(
      "## How to Read the Results",
      paste0("The target variable is the explicit measured variable '", target_label, "'."),
      "",
      "### 1. Variable-level view",
      "This section shows how the other variables are associated with the target variable.",
      "* **correlation**: positive means higher values go with higher values on the target variable; negative means the opposite.",
      "* **p.value**: significance level.",
      "",
      "### 2. Profile-level view",
      "This section shows which technical categories are more typical of the low and high ends after discretization.",
      "* **Estimate**: negative means more typical of the low end; positive means more typical of the high end.",
      "* **p.value**: significance level.",
      "",
      paste0("Use the variable-level view as the main evidence to better understand '", target_label, "'."),
      paste0("Use the profile-level view only to illustrate the low and high ends of '", target_label, "'."),
      sep = "\n"
    ))
  }

  if (prompt_style == "compact") {
    return(paste(
      "## How to Read the Results",
      "The target variable is a latent continuous score.",
      sep = "\n"
    ))
  }

  paste(
    "## How to Read the Results",
    "The target variable is a continuous score interpreted here as a latent continuum. It should be understood as a synthetic dimension that summarizes a coherent pattern across the observed variables.",
    "",
    "### 1. Variable-level view",
    "This section shows global associations with the target variable.",
    "* **correlation**: positive means higher values go with higher values on the target variable; negative means the opposite.",
    "* **p.value**: significance level.",
    "",
    "### 2. Profile-level view",
    "This section shows the technical categories that are more typical of the low and high ends after discretization.",
    "* **Estimate**: negative means more typical of the low end; positive means more typical of the high end.",
    "* **p.value**: significance level.",
    "",
    "Use the variable-level view as the main evidence to infer the latent continuum.",
    "Use the profile-level view only to illustrate what the two ends of the continuum look like.",
    sep = "\n"
  )
}

# ===========================================================================
# Sentence builders
# ===========================================================================

.prepare_sampled_df_condes <- function(df, sample.pct) {
  if (sample.pct < 1) {
    return(sample_numeric_distribution(
      df,
      num_var_index = 1,
      sample_pct = sample.pct,
      method = "stratified",
      bins = 5,
      return_matrix = FALSE
    ))
  }
  df
}

get_sentences_condes_quanti <- function(res_cd, sample.pct = 1, mode = c("standard", "latent")) {
  mode <- match.arg(mode)
  title_txt <- .continuous_title(mode)
  res_q <- res_cd$quanti

  if (is.null(res_q) || nrow(as.data.frame(res_q)) == 0) {
    return(paste0("### ", title_txt, "\n\n*No significant continuous variables were found.*\n"))
  }

  res_q <- .prepare_sampled_df_condes(as.data.frame(res_q), sample.pct)
  res_q$AbsCorrelation <- abs(res_q$correlation)
  res_q$Association <- ifelse(res_q$correlation > 0, "Positive association", "Negative association")
  res_q$Strength <- dplyr::case_when(
    abs(res_q$correlation) >= 0.70 ~ "Very strong",
    abs(res_q$correlation) >= 0.50 ~ "Strong",
    abs(res_q$correlation) >= 0.30 ~ "Moderate",
    TRUE ~ "Weak"
  )

  res_q <- res_q |>
    dplyr::arrange(.data$p.value, dplyr::desc(.data$AbsCorrelation))

  out <- res_q[, c("correlation", "p.value", "Strength", "Association"), drop = FALSE]
  format_stats_as_markdown(out, title = title_txt)
}

get_sentences_condes_profiles <- function(res_cd, sample.pct = 1, mode = c("standard", "latent")) {
  mode <- match.arg(mode)
  main_title <- .profiles_main_title(mode)
  left_title <- .low_end_title(mode)
  right_title <- .high_end_title(mode)
  res_cat <- res_cd$category

  if (is.null(res_cat) || nrow(as.data.frame(res_cat)) == 0) {
    return(paste0("### ", main_title, "\n\n*No significant profile-level categories were found.*\n"))
  }

  res_mat <- .prepare_sampled_df_condes(as.data.frame(res_cat), sample.pct)
  res_mat$AbsEstimate <- abs(res_mat$Estimate)
  res_mat$ProfileMeaning <- ifelse(res_mat$Estimate < 0, "Low-end profile", "High-end profile")

  left_df <- res_mat |>
    dplyr::filter(.data$Estimate < 0) |>
    dplyr::arrange(.data$p.value, dplyr::desc(.data$AbsEstimate))

  right_df <- res_mat |>
    dplyr::filter(.data$Estimate > 0) |>
    dplyr::arrange(.data$p.value, dplyr::desc(.data$AbsEstimate))

  left_out <- left_df[, c("Estimate", "p.value", "ProfileMeaning"), drop = FALSE]
  right_out <- right_df[, c("Estimate", "p.value", "ProfileMeaning"), drop = FALSE]

  paste(
    format_stats_as_markdown(left_out, title = left_title),
    format_stats_as_markdown(right_out, title = right_title),
    sep = "\n\n"
  )
}

build_body_intro_condes <- function(interpretation_mode = c("standard", "latent"),
                                    prompt_style = c("detailed", "compact"),
                                    target_label = "the target variable") {
  interpretation_mode <- match.arg(interpretation_mode)
  prompt_style <- match.arg(prompt_style)

  if (interpretation_mode == "standard") {
    if (prompt_style == "compact") {
      return(paste(
        paste0("The target variable is '", target_label, "'."),
        "All displayed results should be considered.",
        "Treat smaller p.values as stronger evidence and larger p.values as weaker or more tentative evidence.",
        sep = "\n"
      ))
    }

    return(paste(
      paste0("The target variable is the explicit measured variable '", target_label, "'."),
      "It is the variable being characterized in this analysis.",
      paste0("The variable-level evidence describes how the listed variables are associated with '", target_label, "' across its full continuum."),
      paste0("The profile-level evidence describes which technical categories are more typical of the low and high ends of '", target_label, "'."),
      "The results shown below were retained using the significance threshold chosen for this analysis.",
      "All displayed results should be considered.",
      "Interpret smaller p.values as stronger evidence and larger p.values as weaker or more tentative evidence.",
      "Do not ignore a displayed result only because its p.value is above 0.05.",
      sep = "\n"
    ))
  }

  if (prompt_style == "compact") {
    return(paste(
      "The target variable is a latent continuous score.",
      "The results below should all be considered, with smaller p.values treated as stronger evidence.",
      sep = "\n"
    ))
  }

  paste(
    "The target variable is a latent continuous score.",
    "It is not one of the variables listed below.",
    "The variable-level evidence describes how the listed variables are associated with this score across its full continuum.",
    "The profile-level evidence describes which technical categories are more typical of the low and high ends of this score.",
    "The results shown below were retained using the significance threshold chosen for this analysis.",
    "All displayed results should be considered.",
    "Interpret smaller p.values as stronger evidence and larger p.values as weaker or more tentative evidence.",
    "Do not ignore a displayed result only because its p.value is above 0.05.",
    sep = "\n"
  )
}

.build_quali_global_condes <- function(res_cd_original, interpretation_mode) {
  quali_title <- .quali_global_title(interpretation_mode)

  if (!is.null(res_cd_original$quali) && nrow(as.data.frame(res_cd_original$quali)) > 0) {
    res_f <- as.data.frame(res_cd_original$quali) |>
      dplyr::arrange(.data$p.value, dplyr::desc(.data$R2))
    return(format_stats_as_markdown(res_f, title = quali_title))
  }

  paste0("### ", quali_title, "\n\n*No significant qualitative variables were found.*\n")
}

get_prompt_condes <- function(introduction, request, body_intro, ppt_quanti, ppt_quali, ppt_profiles) {
  body_text <- paste(
    body_intro,
    "",
    "## Variable-level evidence",
    "",
    ppt_quanti,
    "",
    ppt_quali,
    "",
    "## Profile-level evidence",
    "",
    ppt_profiles,
    sep = "\n"
  )

  final_prompt <- glue::glue(
    "# Introduction\n\n{introduction}\n\n",
    "# Task\n\n{request}\n\n",
    "# Data\n\n{body_text}"
  )

  normalize_blank_lines(final_prompt)
}

# ---------------------------------------------------------------------------
# Main function
# ---------------------------------------------------------------------------

#' Interpret a continuous variable
#'
#' Generate an LLM response to analyze a continuous variable.
#'
#' @param dataset a data frame made up of at least one quantitative variable and a set of quantitative variables and/or categorical variables.
#' @param num.var the index of the variable to be characterized.
#' @param introduction the introduction for the LLM prompt.
#' @param request the request made to the LLM.
#' @param model the model name (e.g., 'llama3').
#' @param quanti.threshold the threshold above (resp. below) which a scaled variable is considered significantly above (resp. below) the average. Used when converting continuous variables to categorical ones.
#' @param quanti.cat a vector of the 3 possible technical categories used after discretizing continuous variables according to the threshold. Default is "High score", "Low score", "Intermediate score".
#' @param sample.pct the proportion of features to be sampled.
#' @param weights weights for the individuals (see [FactoMineR::condes()]).
#' @param proba the significance threshold considered to characterize the category (by default 0.05).
#' @param interpretation_mode either "standard" or "latent".
#' @param prompt_style either "detailed" or "compact".
#' @param target_concept generic concept used in the prompt to describe what the scale refers to.
#' @param target_label optional label for the target variable. If NULL, uses the name of the variable indexed by `num.var`.
#' @param generate a boolean that indicates whether to generate the LLM response. If FALSE, the function only returns the prompt.
#' @param ... additional arguments passed to 'ollamar::generate' (e.g., `temperature`, `seed`).
#'
#' @return A data frame containing the LLM's prompt and response (if generate = TRUE).
#'
#' @details This function (when generate = TRUE) sends a prompt to an Ollama LLM.
#'
#' @export
#' @examples
#'\dontrun{
#' # Processing time is often longer than ten seconds
#' # because the function uses a large language model.
#'
#' ### Example 1: decathlon dataset ###
#'
#' library(FactoMineR)
#' data(decathlon)
#'
#' names(decathlon) <- c('Time taken to complete the 100m',
#' 'Distance reached for the long jump',
#' 'Distance reached for the shot put',
#' 'Height reached for the high jump',
#' 'Time taken to complete the 400m',
#' 'Time taken to complete the 110m hurdle',
#' 'Distance reached for the discus',
#' 'Height reached for the pole vault',
#' 'Distance reached for the javeline',
#' 'Time taken to complete the 1500 m',
#' 'Rank/Counter-performance indicator',
#' 'Points', 'Competition')
#'
#' res_pca_deca <- FactoMineR::PCA(decathlon,
#' quanti.sup = 11:12, quali.sup = 13, graph = FALSE)
#' plot.PCA(res_pca_deca, choix = 'var')
#' deca_work <- res_pca_deca$ind$coord |> as.data.frame()
#' deca_work <- deca_work[,1] |> cbind(decathlon)
#'
#' intro_deca <- "A study was led on athletes
#' participating in a decathlon event.
#' Their performance was assessed on each part of the decathlon,
#' and they were all placed on an unidimensional scale."
#' intro_deca <- gsub('\n', ' ', intro_deca) |>
#' stringr::str_squish()
#'
#' res_deca <- nail_condes(deca_work,
#'                         num.var = 1,
#'                         quanti.threshold = 1,
#'                         quanti.cat = c('High', 'Low', 'Average'),
#'                         introduction = intro_deca,
#'                         generate = TRUE)
#'
#' cat(res_deca$response)
#'
#'
#' ### Example 2: agri_studies dataset ###
#'
#' data(agri_studies)
#'
#' set.seed(1)
#' res_mca_agri <- FactoMineR::MCA(agri_studies, quali.sup = 39:42,
#' level.ventil = 0.05, graph = FALSE)
#' plot.MCA(res_mca_agri, choix = 'ind',
#' invisible = c('var', 'quali.sup'), label = 'none')
#'
#' agri_work <- res_mca_agri$ind$coord |> as.data.frame()
#' agri_work <- agri_work[,1] |> cbind(agri_studies)
#'
#' intro_agri <- "These data were collected after a survey
#' on students' expectations of agribusiness studies.
#' Participants had to rank how much they agreed with 38 statements
#' about possible benefits from agribusiness studies;
#' then, they were asked personal questions."
#' intro_agri <- gsub('\n', ' ', intro_agri) |>
#' stringr::str_squish()
#'
#' res_agri <- nail_condes(agri_work,
#'                         num.var = 1,
#'                         introduction = intro_agri,
#'                         generate = TRUE)
#'
#' cat(res_agri$response)
#'
#' ### Example 3: glossophobia dataset ###
#'
#' data(glossophobia)
#'
#' set.seed(1)
#' res_mca_phobia <- FactoMineR::MCA(glossophobia,
#' quali.sup = 26:41, level.ventil = 0.05, graph = FALSE)
#' plot.MCA(res_mca_phobia, choix = 'ind',
#' invisible = c('var', 'quali.sup'), label = 'none')
#'
#' phobia_work <- res_mca_phobia$ind$coord |> as.data.frame()
#' phobia_work <- phobia_work[,1] |> cbind(glossophobia)
#'
#' intro_phobia <- "These data were collected after a survey
#' on participants' feelings about speaking in public.
#' Participants had to rank how much they agreed with
#' 25 descriptions of speaking in public;
#' then, they were asked personal questions."
#' intro_phobia <- gsub('\n', ' ', intro_phobia) |>
#' stringr::str_squish()
#'
#' res_phobia <- nail_condes(phobia_work,
#'                           num.var = 1,
#'                           introduction = intro_phobia,
#'                           generate = TRUE)
#'
#' cat(res_phobia$response)
#'
#' ### Example 4: beard_cont dataset ###
#'
#' data(beard_cont)
#'
#' set.seed(1)
#' res_ca_beard <- FactoMineR::CA(beard_cont, graph = FALSE)
#' plot.CA(res_ca_beard, invisible = 'col')
#'
#' beard_work <- res_ca_beard$row$coord |> as.data.frame()
#' beard_work <- beard_work[,1] |> cbind(beard_cont)
#'
#' intro_beard <- "These data refer to 8 types of beards.
#' Each beard was evaluated by 62 assessors."
#' intro_beard <- gsub('\n', ' ', intro_beard) |>
#' stringr::str_squish()
#'
#' req_beard <- "Please explain what differentiates beards
#' on both sides of the scale.
#' Then, give the scale a name."
#' req_beard <- gsub('\n', ' ', req_beard) |>
#' stringr::str_squish()
#'
#' res_beard <- nail_condes(beard_work,
#'                          num.var = 1,
#'                          quanti.threshold = 0.5,
#'                          quanti.cat = c('Very often used', 'Never used', 'Sometimes used'),
#'                          introduction = intro_beard,
#'                          request = req_beard)
#'
#' res_beard
#'
#' ppt <- stringr::str_replace_all(res_beard, 'observations', 'beards')
#' cat(ppt)
#'
#' res_beard <- ollamar::generate(model = 'llama3', prompt = ppt, output = 'text')
#'
#' cat(res_beard)
#' }
#'
nail_condes <- function(dataset, num.var,
                        introduction = NULL,
                        request = NULL,
                        model = "llama3",
                        quanti.threshold = 0,
                        quanti.cat = c("High score", "Low score", "Intermediate score"),
                        sample.pct = 1,
                        weights = NULL,
                        proba = 0.05,
                        generate = FALSE,
                        interpretation_mode = c("standard", "latent"),
                        prompt_style = c("detailed", "compact"),
                        target_concept = "the target concept",
                        target_label = NULL,
                        ...) {

  interpretation_mode <- match.arg(interpretation_mode)
  prompt_style <- match.arg(prompt_style)

  if (is.null(target_label)) {
    if (is.null(colnames(dataset))) {
      target_label <- "the target variable"
    } else {
      target_label <- colnames(dataset)[num.var]
    }
  }

  if (is.null(introduction)) {
    introduction <- if (interpretation_mode == "standard") {
      paste0("The target variable analyzed here is '", target_label, "'.")
    } else {
      paste0(
        "Observations were placed on a quantitative scale. ",
        "The target variable analyzed here is '", target_label, "'."
      )
    }
  }

  if (is.null(request)) {
    request <- build_request_condes(
      mode = interpretation_mode,
      target_concept = target_concept,
      target_label = target_label,
      prompt_style = prompt_style
    )
  }

  guide_condes <- build_guide_condes(
    mode = interpretation_mode,
    target_label = target_label,
    prompt_style = prompt_style
  )
  introduction <- paste(introduction, guide_condes, sep = "\n\n---\n\n")

  res_cd_original <- FactoMineR::condes(
    dataset,
    num.var = num.var,
    weights = weights,
    proba = proba
  )

  ppt_quanti <- get_sentences_condes_quanti(
    res_cd_original,
    sample.pct = sample.pct,
    mode = interpretation_mode
  )

  ppt_quali <- .build_quali_global_condes(res_cd_original, interpretation_mode)

  dta <- get_bins(
    dataset,
    keep = num.var,
    quanti.threshold = quanti.threshold,
    quanti.cat = quanti.cat
  )

  res_cd_profiles <- FactoMineR::condes(
    dta[-(num.var + 1)],
    1,
    weights = weights,
    proba = proba
  )

  ppt_profiles <- get_sentences_condes_profiles(
    res_cd_profiles,
    sample.pct = sample.pct,
    mode = interpretation_mode
  )

  body_intro <- build_body_intro_condes(
    interpretation_mode = interpretation_mode,
    prompt_style = prompt_style,
    target_label = target_label
  )

  final_prompt <- get_prompt_condes(
    introduction = introduction,
    request = request,
    body_intro = body_intro,
    ppt_quanti = ppt_quanti,
    ppt_quali = ppt_quali,
    ppt_profiles = ppt_profiles
  )

  if (!generate) {
    return(final_prompt)
  }

  extra_args <- list(...)
  valid_ollama_opts <- c(
    "temperature", "top_p", "top_k", "seed",
    "system", "template", "context", "keep_alive",
    "stream", "format"
  )
  ollama_api_options <- extra_args[names(extra_args) %in% valid_ollama_opts]

  call_args <- c(
    list(
      model = model,
      prompt = final_prompt,
      output = "df"
    ),
    ollama_api_options
  )

  res_llm <- tryCatch(
    do.call(ollamar::generate, call_args),
    error = function(e) {
      stop(paste("Ollama API call (generate=TRUE) failed:", conditionMessage(e)))
    }
  )

  res_llm$prompt <- final_prompt
  res_llm
}
