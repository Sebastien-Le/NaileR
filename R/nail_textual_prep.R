# ---------------------------------------------------------------------------
# nail_textual_prep(): traceable textual evidence and semantic profiles
# ---------------------------------------------------------------------------

.textual_prep_scopes <- c(
  "general",
  "sociological",
  "consumer",
  "psychological",
  "marketing",
  "innovation",
  "cross_functional"
)

.textual_prep_comparison_modes <- c("isolated", "joint")

.textual_prep_statuses <- c(
  "expert_interpretation",
  "hypothesis",
  "recommendation",
  "user_context"
)

.textual_prep_group_fields <- c(
  "group",
  "core_textual_profile",
  "main_themes",
  "dominant_concerns",
  "tone_or_stance",
  "narrative_frames",
  "motivations",
  "barriers",
  "perceived_benefits",
  "social_norms",
  "identity_cues",
  "contradictions",
  "minority_positions",
  "representative_verbatims",
  "tension_verbatims",
  "intra_group_consistency",
  "interpretation_limits"
)

.textual_prep_cross_group_fields <- c(
  "shared_themes",
  "group_contrasts",
  "minority_patterns",
  "interpretation_limits"
)

.textual_prep_is_scalar_string <- function(x, allow_empty = FALSE) {
  is.character(x) && length(x) == 1L && !is.na(x) &&
    (allow_empty || nzchar(trimws(x)))
}

.textual_prep_validate_context <- function(context) {
  if (is.null(context)) {
    return(list())
  }

  if (is.character(context) && length(context) == 1L && !is.na(context)) {
    return(list(general = context))
  }

  if (!is.list(context) || is.data.frame(context)) {
    stop("`context` must be NULL, a character scalar, or a named list.", call. = FALSE)
  }

  if (length(context) > 0L &&
      (is.null(names(context)) || any(!nzchar(names(context))))) {
    stop("`context` must be a named list.", call. = FALSE)
  }

  context
}

.validate_textual_prep_options <- function(dataset,
                                           num.var,
                                           num.text,
                                           sample.pct,
                                           seed,
                                           max_prompt_characters,
                                           include_verbatims_in_prompt,
                                           attach_selected_verbatims,
                                           n_central_verbatims,
                                           n_tension_verbatims,
                                           max_verbatim_chars,
                                           lexical_analysis,
                                           lexical_proba,
                                           min_word_frequency,
                                           min_word_length,
                                           top_n_characteristic_words,
                                           top_n_frequent_terms,
                                           include_indicators_in_prompt,
                                           compute_length_analysis,
                                           generate,
                                           request,
                                           context) {
  if (!is.data.frame(dataset)) {
    stop("`dataset` must be a data frame.", call. = FALSE)
  }

  validate_index <- function(x, name) {
    if (!is.numeric(x) || length(x) != 1L || is.na(x) || !is.finite(x) ||
        x != floor(x) || x < 1L || x > ncol(dataset)) {
      stop(sprintf("`%s` must be a valid column index.", name), call. = FALSE)
    }
  }

  validate_index(num.var, "num.var")
  validate_index(num.text, "num.text")

  if (num.var == num.text) {
    stop("`num.var` and `num.text` must refer to different columns.", call. = FALSE)
  }

  if (!is.numeric(sample.pct) || length(sample.pct) != 1L || is.na(sample.pct) ||
      !is.finite(sample.pct) || sample.pct < 0 || sample.pct > 1) {
    stop("`sample.pct` must be a single numeric value in [0, 1].", call. = FALSE)
  }

  if (!is.null(seed) &&
      (!is.numeric(seed) || length(seed) != 1L || is.na(seed) ||
       !is.finite(seed) || seed != floor(seed))) {
    stop("`seed` must be NULL or a single finite integer.", call. = FALSE)
  }

  if (is.null(max_prompt_characters)) {
    max_prompt_characters <- Inf
  }
  if (!is.numeric(max_prompt_characters) || length(max_prompt_characters) != 1L ||
      is.na(max_prompt_characters) || max_prompt_characters < 0) {
    stop(
      "`max_prompt_characters` must be NULL, Inf, or a single non-negative number.",
      call. = FALSE
    )
  }

  logical_args <- list(
    include_verbatims_in_prompt = include_verbatims_in_prompt,
    attach_selected_verbatims = attach_selected_verbatims,
    lexical_analysis = lexical_analysis,
    include_indicators_in_prompt = include_indicators_in_prompt,
    compute_length_analysis = compute_length_analysis,
    generate = generate
  )

  invalid_logicals <- names(logical_args)[
    !vapply(
      logical_args,
      function(x) is.logical(x) && length(x) == 1L && !is.na(x),
      logical(1)
    )
  ]

  if (length(invalid_logicals) > 0L) {
    stop(
      sprintf(
        "The following arguments must be single non-missing logical values: %s.",
        paste(invalid_logicals, collapse = ", ")
      ),
      call. = FALSE
    )
  }

  integer_args <- list(
    n_central_verbatims = n_central_verbatims,
    n_tension_verbatims = n_tension_verbatims,
    min_word_frequency = min_word_frequency,
    min_word_length = min_word_length,
    top_n_characteristic_words = top_n_characteristic_words,
    top_n_frequent_terms = top_n_frequent_terms
  )

  for (arg_name in names(integer_args)) {
    value <- integer_args[[arg_name]]
    minimum <- if (arg_name %in% c(
      "n_central_verbatims",
      "n_tension_verbatims",
      "top_n_characteristic_words",
      "top_n_frequent_terms"
    )) 0L else 1L

    if (!is.numeric(value) || length(value) != 1L || is.na(value) ||
        !is.finite(value) || value != floor(value) || value < minimum) {
      stop(
        sprintf("`%s` must be a single integer >= %d.", arg_name, minimum),
        call. = FALSE
      )
    }
  }

  if (!is.numeric(max_verbatim_chars) || length(max_verbatim_chars) != 1L ||
      is.na(max_verbatim_chars) || !is.finite(max_verbatim_chars) ||
      max_verbatim_chars != floor(max_verbatim_chars) || max_verbatim_chars < 4L) {
    stop("`max_verbatim_chars` must be a single integer >= 4.", call. = FALSE)
  }

  if (!is.numeric(lexical_proba) || length(lexical_proba) != 1L ||
      is.na(lexical_proba) || !is.finite(lexical_proba) ||
      lexical_proba <= 0 || lexical_proba > 1) {
    stop("`lexical_proba` must be a single numeric value in ]0, 1].", call. = FALSE)
  }

  if (!is.null(request) && !.textual_prep_is_scalar_string(request)) {
    stop("`request` must be NULL or a non-empty character scalar.", call. = FALSE)
  }

  .textual_prep_validate_context(context)
  invisible(TRUE)
}

.empty_characteristic_terms_textprep <- function() {
  data.frame(
    term = character(0),
    within_group_percent = numeric(0),
    global_percent = numeric(0),
    within_group_frequency = numeric(0),
    global_frequency = numeric(0),
    p_value = numeric(0),
    v_test = numeric(0),
    direction = character(0),
    stringsAsFactors = FALSE
  )
}

.empty_lexical_profile_textprep <- function(unit = NA_character_) {
  empty <- .empty_characteristic_terms_textprep()

  list(
    analysis_unit = unit,

    characteristic_words = character(0),
    overrepresented = empty,
    underrepresented = empty,

    marker_counts = list(
      n_overrepresented = 0,
      n_underrepresented = 0
    ),

    occurrence_metrics = list(
      source_table = "retained occurrence table",
      total_retained_word_occurrences = 0,
      retained_vocabulary_size = 0,
      type_token_ratio = NA_real_,
      shannon_entropy = NA_real_,
      normalized_shannon_entropy = NA_real_
    )
  )
}

.extract_nonempty_texts_textprep <- function(x) {
  x <- as.character(x)
  x[is.na(x)] <- ""
  x <- trimws(x)
  x[nzchar(x)]
}

.normalize_text_for_dedup_textprep <- function(x) {
  x <- tolower(trimws(x))
  x <- gsub("[[:space:]]+", " ", x)
  x
}

.deduplicate_texts_textprep <- function(x) {
  if (length(x) == 0) return(x)
  x[!duplicated(.normalize_text_for_dedup_textprep(x))]
}

.truncate_verbatim_textprep <- function(x, max_chars = 220) {
  ifelse(
    nchar(x) <= max_chars,
    x,
    paste0(substr(x, 1, max_chars - 3), "...")
  )
}

.textprep_stopwords <- function(language = c("en", "fr", "none")) {
  language <- match.arg(language)

  stopwords_en <- c(
    "that", "this", "with", "have", "from", "they", "them", "their",
    "there", "would", "could", "should", "because", "about", "when",
    "what", "which", "will", "only", "then", "than", "into", "very",
    "more", "less", "just", "also", "some", "such", "been", "being",
    "over", "under", "after", "before", "onto", "time", "times",
    "thing", "things", "does", "doing", "done", "were", "where",
    "while", "each", "much", "many", "most", "other", "another"
  )

  stopwords_fr <- c(
    "avec", "dans", "pour", "plus", "moins", "tres", "mais", "donc",
    "comme", "quand", "tout", "tous", "toute", "toutes", "cette",
    "cela", "ceci", "etre", "avoir", "fait", "font", "aussi", "ainsi",
    "alors", "apres", "avant", "entre", "chez", "sans", "sous", "sur",
    "aux", "des", "les", "une", "que", "qui", "quoi", "dont", "leur",
    "leurs", "nous", "vous", "elle", "elles", "ils", "mais", "meme",
    "encore", "autre", "autres", "beaucoup", "peu", "trop", "bien"
  )

  switch(
    language,
    en = unique(stopwords_en),
    fr = unique(stopwords_fr),
    none = character(0)
  )
}

.tokenize_one_text_textprep <- function(x,
                                        min_word_length = 1,
                                        stopwords = character(0),
                                        unique_only = FALSE) {
  if (length(x) == 0 || is.na(x) || !nzchar(trimws(x))) {
    return(character(0))
  }

  x <- tolower(as.character(x))
  x <- gsub("[[:punct:]]+", " ", x)
  tokens <- unlist(strsplit(x, "\\s+", perl = TRUE), use.names = FALSE)
  tokens <- trimws(tokens)
  tokens <- tokens[nzchar(tokens)]
  tokens <- tokens[nchar(tokens) >= min_word_length]

  if (length(stopwords) > 0) {
    tokens <- tokens[!tokens %in% stopwords]
  }

  if (unique_only) {
    tokens <- unique(tokens)
  }

  tokens
}

.tokenize_keywords_textprep <- function(x, min_word_length = 4) {
  if (is.null(x) || length(x) == 0) return(character(0))

  .tokenize_one_text_textprep(
    paste(x, collapse = " "),
    min_word_length = min_word_length,
    stopwords = character(0),
    unique_only = TRUE
  )
}

# ---------------------------------------------------------------------------
# Corpus metrics and response-length analysis
# ---------------------------------------------------------------------------

.compute_corpus_metrics_textprep <- function(dataset, num.var, num.text) {
  var_name <- colnames(dataset)[num.var]
  text_name <- colnames(dataset)[num.text]

  group_values <- dataset[[var_name]]
  keep_group <- !is.na(group_values)
  working <- dataset[keep_group, , drop = FALSE]
  working[[var_name]] <- droplevels(as.factor(working[[var_name]]))

  split_data <- split(working, working[[var_name]], drop = TRUE)
  out <- list()

  for (group_name in names(split_data)) {
    group_data <- split_data[[group_name]]
    raw_text <- as.character(group_data[[text_name]])
    corpus <- .extract_nonempty_texts_textprep(raw_text)

    character_lengths <- nchar(corpus)
    word_lengths <- vapply(
      corpus,
      function(x) length(.tokenize_one_text_textprep(x)),
      integer(1)
    )

    n_rows <- nrow(group_data)
    n_texts <- length(corpus)

    out[[group_name]] <- list(
      n_rows = n_rows,
      n_texts = n_texts,
      response_rate = if (n_rows > 0) n_texts / n_rows else NA_real_,
      total_characters = if (n_texts > 0) sum(character_lengths) else 0,
      mean_characters = if (n_texts > 0) mean(character_lengths) else NA_real_,
      median_characters = if (n_texts > 0) stats::median(character_lengths) else NA_real_,
      iqr_characters = if (n_texts > 0) stats::IQR(character_lengths) else NA_real_,
      min_characters = if (n_texts > 0) min(character_lengths) else NA_real_,
      max_characters = if (n_texts > 0) max(character_lengths) else NA_real_,
      total_words = if (n_texts > 0) sum(word_lengths) else 0,
      mean_words = if (n_texts > 0) mean(word_lengths) else NA_real_,
      median_words = if (n_texts > 0) stats::median(word_lengths) else NA_real_,
      iqr_words = if (n_texts > 0) stats::IQR(word_lengths) else NA_real_,
      min_words = if (n_texts > 0) min(word_lengths) else NA_real_,
      max_words = if (n_texts > 0) max(word_lengths) else NA_real_
    )
  }

  out
}

.empty_length_analysis_textprep <- function(reason) {
  list(
    available = FALSE,
    reason = reason,
    outcome = "log1p(number of characters)",
    n_texts = 0,
    n_groups = 0,
    anova = list(
      f_value = NA_real_,
      df1 = NA_real_,
      df2 = NA_real_,
      p_value = NA_real_,
      eta_squared = NA_real_,
      omega_squared = NA_real_
    ),
    welch = list(
      f_value = NA_real_,
      df1 = NA_real_,
      df2 = NA_real_,
      p_value = NA_real_
    ),
    group_descriptives = data.frame()
  )
}

.compute_length_group_analysis_textprep <- function(dataset, num.var, num.text) {
  group_values <- dataset[[num.var]]
  text_values <- as.character(dataset[[num.text]])
  text_values[is.na(text_values)] <- ""
  text_values <- trimws(text_values)

  keep <- !is.na(group_values) & nzchar(text_values)

  if (!any(keep)) {
    return(.empty_length_analysis_textprep("No non-empty text is available."))
  }

  analysis_data <- data.frame(
    group = droplevels(as.factor(group_values[keep])),
    characters = nchar(text_values[keep]),
    stringsAsFactors = FALSE
  )
  analysis_data$log_characters <- log1p(analysis_data$characters)

  n_texts <- nrow(analysis_data)
  n_groups <- nlevels(analysis_data$group)

  group_descriptives <- do.call(
    rbind,
    lapply(levels(analysis_data$group), function(group_name) {
      values <- analysis_data$characters[analysis_data$group == group_name]
      data.frame(
        group = group_name,
        n_texts = length(values),
        mean_characters = mean(values),
        median_characters = stats::median(values),
        sd_characters = if (length(values) > 1) stats::sd(values) else NA_real_,
        mean_log1p_characters = mean(log1p(values)),
        stringsAsFactors = FALSE
      )
    })
  )
  rownames(group_descriptives) <- NULL

  if (n_groups < 2) {
    out <- .empty_length_analysis_textprep(
      "At least two groups are required for a group-effect analysis."
    )
    out$n_texts <- n_texts
    out$n_groups <- n_groups
    out$group_descriptives <- group_descriptives
    return(out)
  }

  if (n_texts <= n_groups) {
    out <- .empty_length_analysis_textprep(
      "There are not enough non-empty texts to estimate within-group variability."
    )
    out$n_texts <- n_texts
    out$n_groups <- n_groups
    out$group_descriptives <- group_descriptives
    return(out)
  }

  model <- stats::lm(log_characters ~ group, data = analysis_data)
  anova_table <- stats::anova(model)

  ss_between <- anova_table[1, "Sum Sq"]
  ss_within <- anova_table[2, "Sum Sq"]
  df_between <- anova_table[1, "Df"]
  df_within <- anova_table[2, "Df"]
  ss_total <- ss_between + ss_within
  ms_within <- if (df_within > 0) ss_within / df_within else NA_real_

  eta_squared <- if (ss_total > 0) ss_between / ss_total else NA_real_
  omega_squared <- if (is.finite(ms_within) && (ss_total + ms_within) > 0) {
    max(0, (ss_between - df_between * ms_within) / (ss_total + ms_within))
  } else {
    NA_real_
  }

  welch <- tryCatch(
    stats::oneway.test(
      log_characters ~ group,
      data = analysis_data,
      var.equal = FALSE
    ),
    error = function(e) NULL
  )

  list(
    available = TRUE,
    reason = NULL,
    outcome = "log1p(number of characters)",
    n_texts = n_texts,
    n_groups = n_groups,
    anova = list(
      f_value = unname(anova_table[1, "F value"]),
      df1 = unname(df_between),
      df2 = unname(df_within),
      p_value = unname(anova_table[1, "Pr(>F)"]),
      eta_squared = unname(eta_squared),
      omega_squared = unname(omega_squared)
    ),
    welch = list(
      f_value = if (!is.null(welch)) unname(welch$statistic) else NA_real_,
      df1 = if (!is.null(welch)) unname(welch$parameter[1]) else NA_real_,
      df2 = if (!is.null(welch)) unname(welch$parameter[2]) else NA_real_,
      p_value = if (!is.null(welch)) unname(welch$p.value) else NA_real_
    ),
    group_descriptives = group_descriptives,
    interpretation_note = paste(
      "This analysis concerns response length only.",
      "It does not measure textual quality, richness, validity, or evidential strength."
    )
  )
}

# ---------------------------------------------------------------------------
# Lexical contingency tables and descfreq indicators
# ---------------------------------------------------------------------------

.filter_word_table_textprep <- function(tab,
                                        min_word_frequency = 2,
                                        min_word_length = 4,
                                        stopwords = character(0)) {
  tab <- as.matrix(tab)

  if (ncol(tab) == 0) {
    return(tab)
  }

  storage.mode(tab) <- "numeric"
  terms <- colnames(tab)
  terms_lower <- tolower(terms)

  keep <- nchar(terms) >= min_word_length &
    colSums(tab, na.rm = TRUE) >= min_word_frequency

  if (length(stopwords) > 0) {
    keep <- keep & !terms_lower %in% stopwords
  }

  tab[, keep, drop = FALSE]
}

.build_occurrence_table_textprep <- function(dataset,
                                             num.var,
                                             num.text,
                                             min_word_frequency = 2,
                                             min_word_length = 4,
                                             stopwords = character(0)) {
  group_values <- dataset[[num.var]]
  text_values <- as.character(dataset[[num.text]])
  text_values[is.na(text_values)] <- ""
  text_values <- trimws(text_values)

  keep <- !is.na(group_values) & nzchar(text_values)

  if (!any(keep)) {
    return(list(
      table = matrix(numeric(0), nrow = 0, ncol = 0),
      raw_table = matrix(numeric(0), nrow = 0, ncol = 0),
      textual_result = NULL,
      retained_occurrence_rate = NA_real_
    ))
  }

  working <- data.frame(
    group = droplevels(as.factor(group_values[keep])),
    text = text_values[keep],
    stringsAsFactors = FALSE
  )

  textual_result <- FactoMineR::textual(
    tab = working,
    num.text = 2,
    contingence.by = 1,
    maj.in.min = TRUE
  )

  raw_table <- as.matrix(textual_result$cont.table)
  storage.mode(raw_table) <- "numeric"

  expected_groups <- levels(working$group)
  if (nrow(raw_table) == length(expected_groups)) {
    rownames(raw_table) <- expected_groups
  }

  filtered_table <- .filter_word_table_textprep(
    raw_table,
    min_word_frequency = min_word_frequency,
    min_word_length = min_word_length,
    stopwords = stopwords
  )

  raw_total <- sum(raw_table, na.rm = TRUE)
  retained_total <- sum(filtered_table, na.rm = TRUE)

  list(
    table = filtered_table,
    raw_table = raw_table,
    textual_result = textual_result,
    retained_occurrence_rate = if (raw_total > 0) retained_total / raw_total else NA_real_
  )
}

.build_document_table_textprep <- function(dataset,
                                           num.var,
                                           num.text,
                                           min_word_frequency = 2,
                                           min_word_length = 4,
                                           stopwords = character(0)) {
  group_values <- dataset[[num.var]]
  text_values <- as.character(dataset[[num.text]])
  text_values[is.na(text_values)] <- ""
  text_values <- trimws(text_values)

  keep <- !is.na(group_values) & nzchar(text_values)

  if (!any(keep)) {
    return(matrix(numeric(0), nrow = 0, ncol = 0))
  }

  groups <- droplevels(as.factor(group_values[keep]))
  texts <- text_values[keep]

  tokens_by_document <- lapply(
    texts,
    .tokenize_one_text_textprep,
    min_word_length = min_word_length,
    stopwords = stopwords,
    unique_only = TRUE
  )

  token_counts <- lengths(tokens_by_document)
  if (sum(token_counts) == 0) {
    return(matrix(
      0,
      nrow = nlevels(groups),
      ncol = 0,
      dimnames = list(levels(groups), character(0))
    ))
  }

  long_groups <- rep(as.character(groups), token_counts)
  long_terms <- unlist(tokens_by_document, use.names = FALSE)

  table_out <- table(
    factor(long_groups, levels = levels(groups)),
    factor(long_terms, levels = sort(unique(long_terms)))
  )
  table_out <- unclass(table_out)
  storage.mode(table_out) <- "numeric"

  table_out <- table_out[
    ,
    colSums(table_out, na.rm = TRUE) >= min_word_frequency,
    drop = FALSE
  ]

  table_out
}

.safe_descfreq_column_textprep <- function(mat, pattern) {
  if (is.null(colnames(mat))) {
    return(rep(NA_real_, nrow(mat)))
  }

  normalized <- tolower(trimws(colnames(mat)))
  index <- grep(pattern, normalized)

  if (length(index) == 0) {
    return(rep(NA_real_, nrow(mat)))
  }

  as.numeric(mat[, index[1]])
}

.descfreq_matrix_to_data_frame_textprep <- function(x) {
  if (is.null(x) || length(x) == 0) {
    return(.empty_characteristic_terms_textprep())
  }

  mat <- as.matrix(x)
  if (nrow(mat) == 0) {
    return(.empty_characteristic_terms_textprep())
  }

  terms <- rownames(mat)
  if (is.null(terms)) {
    terms <- rep("", nrow(mat))
  }

  v_test <- .safe_descfreq_column_textprep(mat, "^v\\.test$|^v test$")

  out <- data.frame(
    term = terms,
    within_group_percent = .safe_descfreq_column_textprep(mat, "^intern %$"),
    global_percent = .safe_descfreq_column_textprep(mat, "^glob %$"),
    within_group_frequency = .safe_descfreq_column_textprep(mat, "^intern freq$"),
    global_frequency = .safe_descfreq_column_textprep(mat, "^glob freq$"),
    p_value = .safe_descfreq_column_textprep(mat, "^p\\.value$|^p value$"),
    v_test = v_test,
    direction = ifelse(
      is.na(v_test),
      NA_character_,
      ifelse(v_test >= 0, "overrepresented", "underrepresented")
    ),
    stringsAsFactors = FALSE
  )

  out[order(out$p_value, -abs(out$v_test), na.last = TRUE), , drop = FALSE]
}

.compute_occurrence_metrics_textprep <- function(occurrence_table) {
  occurrence_table <- as.matrix(occurrence_table)

  if (nrow(occurrence_table) == 0) {
    return(list())
  }

  out <- list()

  for (group_name in rownames(occurrence_table)) {
    counts <- as.numeric(
      occurrence_table[group_name, , drop = TRUE]
    )

    counts <- counts[
      is.finite(counts) &
        counts > 0
    ]

    total <- sum(counts)
    vocabulary_size <- length(counts)

    if (total > 0) {
      probabilities <- counts / total

      entropy <- -sum(
        probabilities * log(probabilities)
      )

      normalized_entropy <- if (vocabulary_size > 1) {
        entropy / log(vocabulary_size)
      } else {
        0
      }

      type_token_ratio <- vocabulary_size / total
    } else {
      entropy <- NA_real_
      normalized_entropy <- NA_real_
      type_token_ratio <- NA_real_
    }

    out[[group_name]] <- list(
      source_table = "retained occurrence table",
      total_retained_word_occurrences = total,
      retained_vocabulary_size = vocabulary_size,
      type_token_ratio = type_token_ratio,
      shannon_entropy = entropy,
      normalized_shannon_entropy = normalized_entropy
    )
  }

  out
}

.compute_global_lexical_association_textprep <- function(tab) {
  tab <- as.matrix(tab)
  storage.mode(tab) <- "numeric"

  if (nrow(tab) < 2 || ncol(tab) < 2 || sum(tab) <= 0) {
    return(list(
      available = FALSE,
      reason = "At least two non-empty groups and two retained terms are required.",
      chi_square = NA_real_,
      df = NA_real_,
      p_value = NA_real_,
      total_inertia = NA_real_,
      cramers_v = NA_real_,
      min_expected = NA_real_,
      percent_expected_below_5 = NA_real_,
      interpretation_note = paste(
        "The global lexical association is descriptive and exploratory.",
        "It should not be interpreted as a measure of textual quality."
      )
    ))
  }

  row_totals <- rowSums(tab)
  col_totals <- colSums(tab)
  keep_rows <- row_totals > 0
  keep_cols <- col_totals > 0
  tab <- tab[keep_rows, keep_cols, drop = FALSE]

  total <- sum(tab)
  expected <- outer(rowSums(tab), colSums(tab)) / total
  valid <- expected > 0
  chi_square <- sum((tab[valid] - expected[valid])^2 / expected[valid])
  df <- (nrow(tab) - 1) * (ncol(tab) - 1)
  p_value <- stats::pchisq(chi_square, df = df, lower.tail = FALSE)
  total_inertia <- chi_square / total
  min_dimension <- min(nrow(tab) - 1, ncol(tab) - 1)
  cramers_v <- if (min_dimension > 0) {
    sqrt(chi_square / (total * min_dimension))
  } else {
    NA_real_
  }

  list(
    available = TRUE,
    reason = NULL,
    chi_square = unname(chi_square),
    df = unname(df),
    p_value = unname(p_value),
    total_inertia = unname(total_inertia),
    cramers_v = unname(cramers_v),
    min_expected = min(expected),
    percent_expected_below_5 = 100 * mean(expected < 5),
    interpretation_note = paste(
      "The chi-square p-value is asymptotic and may be unreliable for a sparse table.",
      "Use the expected-count diagnostics and interpret the result as exploratory.",
      "Cramer's V and total inertia describe association, not textual quality."
    )
  )
}

.run_descfreq_textprep <- function(tab,
                                   proba = 0.05,
                                   top_n = 8,
                                   occurrence_table = NULL) {
  tab <- as.matrix(tab)
  storage.mode(tab) <- "numeric"

  if (nrow(tab) == 0 || ncol(tab) == 0) {
    return(list(
      result = NULL,
      group_profiles = list(),
      global_association = .compute_global_lexical_association_textprep(tab)
    ))
  }

  descfreq_input <- as.data.frame(tab, stringsAsFactors = FALSE)
  colnames(descfreq_input) <- colnames(tab)

  descfreq_result <- FactoMineR::descfreq(
    descfreq_input,
    proba = proba
  )

  group_profiles <- stats::setNames(
    lapply(rownames(tab), function(group_name) {
      raw <- descfreq_result[[group_name]]
      if (is.null(raw)) {
        # FactoMineR usually preserves row names, but use the row position as a
        # fallback for unusual or duplicated labels.
        raw <- descfreq_result[[match(group_name, rownames(tab))]]
      }

      indicators <- .descfreq_matrix_to_data_frame_textprep(raw)
      over <- indicators[
        !is.na(indicators$v_test) & indicators$v_test > 0,
        ,
        drop = FALSE
      ]
      under <- indicators[
        !is.na(indicators$v_test) & indicators$v_test < 0,
        ,
        drop = FALSE
      ]

      if (top_n >= 0) {
        over <- utils::head(over, top_n)
        under <- utils::head(under, top_n)
      }

      list(
        analysis_unit = NA_character_,

        characteristic_words = over$term,
        overrepresented = over,
        underrepresented = under,

        marker_counts = list(
          n_overrepresented = nrow(over),
          n_underrepresented = nrow(under)
        ),

        occurrence_metrics = NULL
      )
    }),
    rownames(tab)
  )

  occurrence_metrics <- .compute_occurrence_metrics_textprep(
    occurrence_table = if (is.null(occurrence_table)) {
      tab
    } else {
      occurrence_table
    }
  )

  for (group_name in names(group_profiles)) {
    group_profiles[[group_name]]$occurrence_metrics <- if (
      group_name %in% names(occurrence_metrics)
    ) {
      occurrence_metrics[[group_name]]
    } else {
      .empty_lexical_profile_textprep()$occurrence_metrics
    }
  }

  list(
    result = descfreq_result,
    group_profiles = group_profiles,
    global_association = .compute_global_lexical_association_textprep(tab)
  )
}

.compute_lexical_analysis_textprep <- function(dataset,
                                               num.var,
                                               num.text,
                                               lexical_unit = c("occurrence", "document"),
                                               language = c("en", "fr", "none"),
                                               lexical_proba = 0.05,
                                               min_word_frequency = 2,
                                               min_word_length = 4,
                                               top_n_characteristic_words = 8) {
  lexical_unit <- match.arg(lexical_unit)
  language <- match.arg(language)
  stopwords <- .textprep_stopwords(language)

  occurrence <- .build_occurrence_table_textprep(
    dataset = dataset,
    num.var = num.var,
    num.text = num.text,
    min_word_frequency = min_word_frequency,
    min_word_length = min_word_length,
    stopwords = stopwords
  )

  analysis_table <- if (lexical_unit == "occurrence") {
    occurrence$table
  } else {
    .build_document_table_textprep(
      dataset = dataset,
      num.var = num.var,
      num.text = num.text,
      min_word_frequency = min_word_frequency,
      min_word_length = min_word_length,
      stopwords = stopwords
    )
  }

  descfreq_analysis <- .run_descfreq_textprep(
    tab = analysis_table,
    proba = lexical_proba,
    top_n = top_n_characteristic_words,
    occurrence_table = occurrence$table
  )

  for (group_name in names(descfreq_analysis$group_profiles)) {
    descfreq_analysis$group_profiles[[group_name]]$analysis_unit <- lexical_unit
  }

  list(
    settings = list(
      lexical_unit = lexical_unit,
      language = language,
      lexical_proba = lexical_proba,
      min_word_frequency = min_word_frequency,
      min_word_length = min_word_length,
      top_n_characteristic_words = top_n_characteristic_words,
      multiple_testing_adjustment = "none"
    ),
    contingency_table = analysis_table,
    occurrence_table = occurrence$table,
    raw_occurrence_table = occurrence$raw_table,
    retained_occurrence_rate = occurrence$retained_occurrence_rate,
    textual_result = occurrence$textual_result,
    descfreq_result = descfreq_analysis$result,
    group_profiles = descfreq_analysis$group_profiles,
    global_association = descfreq_analysis$global_association
  )
}

.extract_frequent_terms_textprep <- function(dataset,
                                             num.var,
                                             num.text,
                                             top_n = 5,
                                             min_word_length = 4,
                                             language = c("en", "fr", "none")) {
  language <- match.arg(language)
  stopwords <- .textprep_stopwords(language)

  group_values <- dataset[[num.var]]
  keep_group <- !is.na(group_values)
  working <- dataset[keep_group, , drop = FALSE]
  working[[num.var]] <- droplevels(as.factor(working[[num.var]]))
  split_data <- split(working, working[[num.var]], drop = TRUE)

  out <- list()

  for (group_name in names(split_data)) {
    corpus <- .extract_nonempty_texts_textprep(split_data[[group_name]][[num.text]])
    tokens <- unlist(
      lapply(
        corpus,
        .tokenize_one_text_textprep,
        min_word_length = min_word_length,
        stopwords = stopwords,
        unique_only = FALSE
      ),
      use.names = FALSE
    )

    if (length(tokens) == 0 || top_n == 0) {
      out[[group_name]] <- character(0)
      next
    }

    frequencies <- sort(table(tokens), decreasing = TRUE)
    out[[group_name]] <- names(utils::head(frequencies, top_n))
  }

  out
}

# ---------------------------------------------------------------------------
# Representative and contrastive verbatims
# ---------------------------------------------------------------------------


.format_number_textprep <- function(x, digits = 3) {
  if (length(x) == 0 || is.na(x) || !is.finite(x)) {
    return("NA")
  }

  formatC(x, digits = digits, format = "fg", flag = "#")
}

.format_characteristic_terms_textprep <- function(x, max_terms = 8) {
  if (is.null(x) || nrow(x) == 0 || max_terms == 0) {
    return("none at the selected threshold")
  }

  x <- utils::head(x, max_terms)

  paste(
    vapply(seq_len(nrow(x)), function(i) {
      paste0(
        x$term[i],
        " (v-test = ", .format_number_textprep(x$v_test[i]),
        ", p = ", .format_number_textprep(x$p_value[i]),
        ", group frequency = ", .format_number_textprep(x$within_group_frequency[i], digits = 5),
        ", global frequency = ", .format_number_textprep(x$global_frequency[i], digits = 5),
        ")"
      )
    }, character(1)),
    collapse = "; "
  )
}



# ---------------------------------------------------------------------------
# Mechanical textual evidence
# ---------------------------------------------------------------------------

.textual_prep_group_levels <- function(x) {
  if (is.factor(x)) {
    return(as.character(levels(x)))
  }

  x <- as.character(x)
  x <- x[!is.na(x) & nzchar(trimws(x))]
  unique(x)
}

.textual_prep_text_status <- function(x) {
  if (is.na(x)) return("missing")
  if (identical(x, "")) return("empty")
  if (!nzchar(trimws(x))) return("whitespace")
  "non_empty"
}

.textual_prep_escape_component <- function(x) {
  x <- enc2utf8(as.character(x))
  x <- gsub("%", "%25", x, fixed = TRUE)
  gsub(":", "%3A", x, fixed = TRUE)
}

.textual_prep_make_verbatim_id <- function(group, row_index) {
  group_component <- if (is.na(group) || !nzchar(trimws(group))) {
    "<missing_group>"
  } else {
    group
  }

  paste0(
    .textual_prep_escape_component(group_component),
    "::verbatim::",
    as.integer(row_index)
  )
}

.textual_prep_stable_hash <- function(x) {
  ints <- utf8ToInt(enc2utf8(paste(x, collapse = "|")))
  if (length(ints) == 0L) return(0)

  modulus <- 2147483647
  hash <- 2166136261 %% modulus
  for (i in seq_along(ints)) {
    hash <- (hash * 16777619 + as.numeric(ints[[i]]) + i) %% modulus
  }
  hash
}

.textual_prep_word_count <- function(x) {
  if (length(x) == 0L || is.na(x) || !nzchar(trimws(x))) return(0L)
  length(
    .tokenize_one_text_textprep(
      x,
      min_word_length = 1L,
      stopwords = character(0),
      unique_only = FALSE
    )
  )
}

.textual_prep_empty_lexical_results <- function(lexical_unit,
                                                language,
                                                lexical_proba,
                                                min_word_frequency,
                                                min_word_length,
                                                top_n_characteristic_words,
                                                reason = NULL) {
  list(
    settings = list(
      lexical_unit = lexical_unit,
      language = language,
      lexical_proba = lexical_proba,
      min_word_frequency = min_word_frequency,
      min_word_length = min_word_length,
      top_n_characteristic_words = top_n_characteristic_words,
      multiple_testing_adjustment = "none",
      available = FALSE,
      reason = reason
    ),
    contingency_table = matrix(numeric(0), nrow = 0, ncol = 0),
    occurrence_table = matrix(numeric(0), nrow = 0, ncol = 0),
    raw_occurrence_table = matrix(numeric(0), nrow = 0, ncol = 0),
    retained_occurrence_rate = NA_real_,
    textual_result = NULL,
    descfreq_result = NULL,
    group_profiles = list(),
    global_association = .compute_global_lexical_association_textprep(
      matrix(numeric(0), nrow = 0, ncol = 0)
    )
  )
}

.textual_prep_build_verbatim_table <- function(dataset,
                                               num.var,
                                               num.text,
                                               sample.pct,
                                               seed,
                                               max_prompt_characters) {
  group_raw <- dataset[[num.var]]
  group <- as.character(group_raw)
  original_text <- as.character(dataset[[num.text]])
  row_index <- seq_len(nrow(dataset))

  valid_group <- !is.na(group) & nzchar(trimws(group))
  text_status <- unname(vapply(
    original_text,
    .textual_prep_text_status,
    character(1),
    USE.NAMES = FALSE
  ))
  character_count <- unname(vapply(
    original_text,
    function(x) if (is.na(x)) 0L else nchar(x, type = "chars"),
    integer(1),
    USE.NAMES = FALSE
  ))
  word_count <- unname(vapply(
    original_text,
    .textual_prep_word_count,
    integer(1),
    USE.NAMES = FALSE
  ))
  evidence_id <- unname(vapply(
    seq_along(row_index),
    function(i) .textual_prep_make_verbatim_id(group[[i]], row_index[[i]]),
    character(1),
    USE.NAMES = FALSE
  ))

  out <- data.frame(
    verbatim_id = evidence_id,
    group = group,
    original_text = original_text,
    row_index = as.integer(row_index),
    character_count = as.integer(character_count),
    word_count = as.integer(word_count),
    text_status = text_status,
    missing_or_empty = text_status != "non_empty",
    included_in_prompt = FALSE,
    sampling_rank = rep(NA_integer_, length(row_index)),
    exclusion_reason = rep(NA_character_, length(row_index)),
    prompt_character_cost = rep(NA_integer_, length(row_index)),
    stringsAsFactors = FALSE,
    check.names = FALSE
  )

  out$exclusion_reason[!valid_group] <- "invalid_group"
  out$exclusion_reason[valid_group & text_status == "missing"] <- "missing"
  out$exclusion_reason[valid_group & text_status == "empty"] <- "empty"
  out$exclusion_reason[valid_group & text_status == "whitespace"] <- "empty"

  group_levels <- .textual_prep_group_levels(group_raw)
  seed_key <- if (is.null(seed)) "0" else format(seed, scientific = FALSE, trim = TRUE)
  budget <- if (is.null(max_prompt_characters)) Inf else max_prompt_characters

  for (group_name in group_levels) {
    eligible <- which(
      valid_group &
        !is.na(group) &
        group == group_name &
        text_status == "non_empty"
    )

    if (length(eligible) == 0L) next

    scores <- vapply(
      eligible,
      function(i) {
        .textual_prep_stable_hash(c(seed_key, group_name, row_index[[i]]))
      },
      numeric(1)
    )
    ordered <- eligible[order(scores, row_index[eligible])]
    out$sampling_rank[ordered] <- seq_along(ordered)

    n_available <- length(ordered)
    n_sample <- if (sample.pct <= 0) {
      0L
    } else if (sample.pct >= 1) {
      n_available
    } else {
      min(n_available, max(1L, as.integer(round(n_available * sample.pct))))
    }

    candidates <- if (n_sample > 0L) ordered[seq_len(n_sample)] else integer(0)
    not_sampled <- setdiff(ordered, candidates)
    out$exclusion_reason[not_sampled] <- "not_sampled"

    cumulative <- 0
    for (i in candidates) {
      line_cost <- nchar(
        paste0("[", out$verbatim_id[[i]], "] ", out$original_text[[i]]),
        type = "chars"
      )
      out$prompt_character_cost[[i]] <- as.integer(line_cost)

      if (is.infinite(budget) || cumulative + line_cost <= budget) {
        out$included_in_prompt[[i]] <- TRUE
        out$exclusion_reason[[i]] <- NA_character_
        cumulative <- cumulative + line_cost
      } else {
        out$exclusion_reason[[i]] <- "prompt_budget"
      }
    }
  }

  if (anyDuplicated(out$verbatim_id)) {
    stop("Internal error: textual evidence identifiers are not unique.", call. = FALSE)
  }

  out
}

.textual_prep_group_diagnostics <- function(verbatims, group_levels) {
  rows <- lapply(group_levels, function(group_name) {
    idx <- which(!is.na(verbatims$group) & verbatims$group == group_name)
    block <- verbatims[idx, , drop = FALSE]
    non_empty <- block$text_status == "non_empty"
    words <- block$word_count[non_empty]
    chars <- block$character_count[non_empty]

    data.frame(
      group = group_name,
      n_total = nrow(block),
      n_missing = sum(block$text_status == "missing"),
      n_empty = sum(block$text_status == "empty"),
      n_whitespace = sum(block$text_status == "whitespace"),
      n_non_empty = sum(non_empty),
      n_included_in_prompt = sum(block$included_in_prompt),
      n_excluded_from_prompt = nrow(block) - sum(block$included_in_prompt),
      n_not_sampled = sum(block$exclusion_reason == "not_sampled", na.rm = TRUE),
      n_prompt_budget = sum(block$exclusion_reason == "prompt_budget", na.rm = TRUE),
      total_characters = if (length(chars) > 0L) sum(chars) else 0L,
      total_words = if (length(words) > 0L) sum(words) else 0L,
      median_words = if (length(words) > 0L) stats::median(words) else NA_real_,
      min_words = if (length(words) > 0L) min(words) else NA_real_,
      max_words = if (length(words) > 0L) max(words) else NA_real_,
      sampling_fraction = if (sum(non_empty) > 0L) {
        sum(block$included_in_prompt) / sum(non_empty)
      } else {
        NA_real_
      },
      prompt_character_count = sum(
        block$prompt_character_cost[block$included_in_prompt],
        na.rm = TRUE
      ),
      stringsAsFactors = FALSE,
      check.names = FALSE
    )
  })

  if (length(rows) == 0L) {
    return(data.frame(
      group = character(0),
      n_total = integer(0),
      n_missing = integer(0),
      n_empty = integer(0),
      n_whitespace = integer(0),
      n_non_empty = integer(0),
      n_included_in_prompt = integer(0),
      n_excluded_from_prompt = integer(0),
      n_not_sampled = integer(0),
      n_prompt_budget = integer(0),
      total_characters = integer(0),
      total_words = integer(0),
      median_words = numeric(0),
      min_words = numeric(0),
      max_words = numeric(0),
      sampling_fraction = numeric(0),
      prompt_character_count = numeric(0),
      stringsAsFactors = FALSE
    ))
  }

  out <- do.call(rbind, rows)
  rownames(out) <- NULL
  out
}

.build_textual_evidence <- function(dataset,
                                    num.var,
                                    num.text,
                                    sample.pct,
                                    seed,
                                    max_prompt_characters,
                                    language,
                                    lexical_analysis,
                                    lexical_unit,
                                    lexical_proba,
                                    min_word_frequency,
                                    min_word_length,
                                    top_n_characteristic_words,
                                    top_n_frequent_terms,
                                    compute_length_analysis) {
  group_levels <- .textual_prep_group_levels(dataset[[num.var]])
  verbatims <- .textual_prep_build_verbatim_table(
    dataset = dataset,
    num.var = num.var,
    num.text = num.text,
    sample.pct = sample.pct,
    seed = seed,
    max_prompt_characters = max_prompt_characters
  )

  group_diagnostics <- .textual_prep_group_diagnostics(
    verbatims = verbatims,
    group_levels = group_levels
  )

  corpus_metrics <- .compute_corpus_metrics_textprep(
    dataset = dataset,
    num.var = num.var,
    num.text = num.text
  )

  length_group_analysis <- if (compute_length_analysis) {
    tryCatch(
      .compute_length_group_analysis_textprep(
        dataset = dataset,
        num.var = num.var,
        num.text = num.text
      ),
      error = function(e) {
        .empty_length_analysis_textprep(
          paste("Length analysis failed:", conditionMessage(e))
        )
      }
    )
  } else {
    .empty_length_analysis_textprep(
      "The analysis was disabled by `compute_length_analysis = FALSE`."
    )
  }

  lexical_results <- if (lexical_analysis) {
    tryCatch(
      .compute_lexical_analysis_textprep(
        dataset = dataset,
        num.var = num.var,
        num.text = num.text,
        lexical_unit = lexical_unit,
        language = language,
        lexical_proba = lexical_proba,
        min_word_frequency = min_word_frequency,
        min_word_length = min_word_length,
        top_n_characteristic_words = top_n_characteristic_words
      ),
      error = function(e) {
        .textual_prep_empty_lexical_results(
          lexical_unit = lexical_unit,
          language = language,
          lexical_proba = lexical_proba,
          min_word_frequency = min_word_frequency,
          min_word_length = min_word_length,
          top_n_characteristic_words = top_n_characteristic_words,
          reason = conditionMessage(e)
        )
      }
    )
  } else {
    .textual_prep_empty_lexical_results(
      lexical_unit = lexical_unit,
      language = language,
      lexical_proba = lexical_proba,
      min_word_frequency = min_word_frequency,
      min_word_length = min_word_length,
      top_n_characteristic_words = top_n_characteristic_words,
      reason = "The lexical analysis was disabled."
    )
  }

  frequent_terms <- .extract_frequent_terms_textprep(
    dataset = dataset,
    num.var = num.var,
    num.text = num.text,
    top_n = top_n_frequent_terms,
    min_word_length = min_word_length,
    language = language
  )

  groups <- stats::setNames(
    lapply(group_levels, function(group_name) {
      idx <- which(!is.na(verbatims$group) & verbatims$group == group_name)
      diag_row <- group_diagnostics[
        group_diagnostics$group == group_name,
        ,
        drop = FALSE
      ]

      list(
        group = group_name,
        evidence_ids = verbatims$verbatim_id[idx],
        non_empty_evidence_ids = verbatims$verbatim_id[
          idx[verbatims$text_status[idx] == "non_empty"]
        ],
        included_evidence_ids = verbatims$verbatim_id[
          idx[verbatims$included_in_prompt[idx]]
        ],
        diagnostics = diag_row,
        lexical_profile = if (group_name %in% names(lexical_results$group_profiles)) {
          lexical_results$group_profiles[[group_name]]
        } else {
          .empty_lexical_profile_textprep(unit = lexical_unit)
        },
        frequent_terms = if (group_name %in% names(frequent_terms)) {
          frequent_terms[[group_name]]
        } else {
          character(0)
        }
      )
    }),
    group_levels
  )

  evidence_registry <- verbatims[, c(
    "verbatim_id",
    "group",
    "row_index",
    "original_text",
    "character_count",
    "word_count",
    "text_status",
    "missing_or_empty",
    "included_in_prompt",
    "sampling_rank",
    "exclusion_reason"
  ), drop = FALSE]
  names(evidence_registry)[names(evidence_registry) == "verbatim_id"] <- "evidence_id"
  evidence_registry$source <- colnames(dataset)[num.text]

  corpus <- verbatims[, c(
    "row_index",
    "group",
    "original_text",
    "text_status"
  ), drop = FALSE]

  sampling_by_group <- group_diagnostics[, c(
    "group",
    "n_non_empty",
    "n_included_in_prompt",
    "n_not_sampled",
    "n_prompt_budget",
    "sampling_fraction",
    "prompt_character_count"
  ), drop = FALSE]

  out <- list(
    corpus = corpus,
    groups = groups,
    verbatims = verbatims,
    group_diagnostics = group_diagnostics,
    sampling = list(
      method = "deterministic_hash_within_group",
      sample_pct = sample.pct,
      seed = seed,
      max_prompt_characters_per_group = if (is.null(max_prompt_characters)) {
        Inf
      } else {
        max_prompt_characters
      },
      by_group = sampling_by_group
    ),
    evidence_registry = evidence_registry,
    lexical_analysis = lexical_results,
    length_group_analysis = length_group_analysis,
    corpus_metrics = corpus_metrics,
    settings = list(
      group_column_index = as.integer(num.var),
      group_column = colnames(dataset)[num.var],
      text_column_index = as.integer(num.text),
      text_column = colnames(dataset)[num.text],
      sample_pct = sample.pct,
      seed = seed,
      max_prompt_characters_per_group = if (is.null(max_prompt_characters)) {
        Inf
      } else {
        max_prompt_characters
      },
      lexical_analysis = lexical_analysis,
      lexical_unit = lexical_unit,
      language = language,
      lexical_proba = lexical_proba,
      min_word_frequency = as.integer(min_word_frequency),
      min_word_length = as.integer(min_word_length),
      top_n_characteristic_words = as.integer(top_n_characteristic_words),
      top_n_frequent_terms = as.integer(top_n_frequent_terms),
      compute_length_analysis = compute_length_analysis
    ),
    metadata = list(
      source = "dataset",
      n_rows = nrow(dataset),
      n_groups = length(group_levels),
      n_invalid_group_rows = sum(
        is.na(as.character(dataset[[num.var]])) |
          !nzchar(trimws(as.character(dataset[[num.var]])))
      )
    )
  )

  class(out) <- c("textual_evidence", "list")
  out
}

# ---------------------------------------------------------------------------
# Prompt construction
# ---------------------------------------------------------------------------

.textual_prep_scope_mission <- function(analysis_scope) {
  switch(
    analysis_scope,
    general = paste(
      "Describe themes, expressed concerns, tone, contradictions, and minority positions.",
      "Stay close to the explicit textual content."
    ),
    sociological = paste(
      "Examine social norms, legitimacy, institutional relationships, ordinary practices,",
      "social constraints, territorial anchoring, cultural distance, and tensions between",
      "prescriptions and practical possibilities."
    ),
    consumer = paste(
      "Examine sought benefits, barriers, decision criteria, trade-offs, trust, perceived",
      "value, routines, rejection motives, and cautious behavioral hypotheses."
    ),
    psychological = paste(
      "Examine expressed motivations, emotions, ambivalence, perceived control, self-efficacy,",
      "value-practice dissonance, and resistance to change. Never diagnose an individual or group."
    ),
    marketing = paste(
      "Identify unmet needs, benefits to communicate, barriers to address, consumer vocabulary,",
      "positioning territories, and propositions that require validation."
    ),
    innovation = paste(
      "Identify category tensions, weak signals, emerging expectations, possible new uses,",
      "and concept hypotheses that require validation."
    ),
    cross_functional = paste(
      "Integrate sociological, consumer, psychological, marketing, and innovation perspectives,",
      "while distinguishing direct interpretation from hypotheses and recommendations."
    )
  )
}

.textual_prep_records <- function(x) {
  if (is.null(x) || nrow(x) == 0L) return(list())
  unname(lapply(seq_len(nrow(x)), function(i) as.list(x[i, , drop = FALSE])))
}

.textual_prep_lexical_prompt_view <- function(group_info, include_indicators) {
  if (!include_indicators) return(NULL)

  profile <- group_info$lexical_profile
  list(
    frequent_terms = unname(as.character(group_info$frequent_terms)),
    overrepresented = .textual_prep_records(profile$overrepresented),
    underrepresented = .textual_prep_records(profile$underrepresented),
    interpretation_note = paste(
      "Lexical indicators are mechanical comparative indicators.",
      "They do not prove that every person used a term and they do not measure textual quality."
    )
  )
}

.textual_prep_claim_template <- function(status = "expert_interpretation") {
  list(
    text = "<interpretation grounded in the cited verbatims>",
    status = status,
    evidence_ids = list("<verbatim_id>"),
    validation_needed = if (status %in% c("hypothesis", "recommendation")) {
      "<additional evidence or study needed>"
    } else {
      NULL
    }
  )
}

.textual_prep_quote_template <- function() {
  list(
    evidence_id = "<verbatim_id>",
    quotation = "<exact original_text>",
    rationale = "<why this verbatim is representative or contrastive>",
    status = "expert_interpretation"
  )
}

.textual_prep_group_schema <- function(group_name) {
  claim <- .textual_prep_claim_template()
  list(
    group = group_name,
    core_textual_profile = claim,
    main_themes = list(claim),
    dominant_concerns = list(claim),
    tone_or_stance = claim,
    narrative_frames = list(claim),
    motivations = list(claim),
    barriers = list(claim),
    perceived_benefits = list(claim),
    social_norms = list(claim),
    identity_cues = list(claim),
    contradictions = list(.textual_prep_claim_template("hypothesis")),
    minority_positions = list(claim),
    representative_verbatims = list(.textual_prep_quote_template()),
    tension_verbatims = list(.textual_prep_quote_template()),
    intra_group_consistency = claim,
    interpretation_limits = list(claim)
  )
}

.textual_prep_output_schema <- function(groups, comparison_mode) {
  group_schema <- stats::setNames(
    lapply(groups, .textual_prep_group_schema),
    groups
  )

  cross_group <- if (comparison_mode == "joint") {
    list(
      shared_themes = list(.textual_prep_claim_template()),
      group_contrasts = list(.textual_prep_claim_template()),
      minority_patterns = list(.textual_prep_claim_template("hypothesis")),
      interpretation_limits = list(.textual_prep_claim_template())
    )
  } else {
    list(
      shared_themes = list(),
      group_contrasts = list(),
      minority_patterns = list(),
      interpretation_limits = list()
    )
  }

  jsonlite::toJSON(
    list(groups = group_schema, cross_group = cross_group),
    auto_unbox = TRUE,
    pretty = TRUE,
    na = "null",
    null = "null"
  )
}

.textual_prep_build_evidence_payload <- function(textual_evidence,
                                                 groups,
                                                 include_indicators) {
  group_payload <- stats::setNames(
    lapply(groups, function(group_name) {
      group_info <- textual_evidence$groups[[group_name]]
      diagnostics <- group_info$diagnostics
      if (nrow(diagnostics) > 0L) diagnostics <- as.list(diagnostics[1, , drop = FALSE])

      rows <- textual_evidence$verbatims[
        !is.na(textual_evidence$verbatims$group) &
          textual_evidence$verbatims$group == group_name &
          textual_evidence$verbatims$included_in_prompt,
        ,
        drop = FALSE
      ]

      verbatims <- lapply(seq_len(nrow(rows)), function(i) {
        list(
          evidence_id = rows$verbatim_id[[i]],
          row_index = rows$row_index[[i]],
          original_text = rows$original_text[[i]]
        )
      })

      list(
        group = group_name,
        diagnostics = diagnostics,
        lexical_indicators = .textual_prep_lexical_prompt_view(
          group_info,
          include_indicators = include_indicators
        ),
        verbatims = verbatims
      )
    }),
    groups
  )

  list(groups = group_payload)
}

.textual_prep_build_prompt <- function(textual_evidence,
                                       groups,
                                       analysis_scope,
                                       comparison_mode,
                                       request,
                                       context,
                                       prompt_style,
                                       text_role,
                                       include_indicators_in_prompt,
                                       n_central_verbatims,
                                       n_tension_verbatims) {
  evidence_payload <- .textual_prep_build_evidence_payload(
    textual_evidence = textual_evidence,
    groups = groups,
    include_indicators = include_indicators_in_prompt
  )

  evidence_json <- jsonlite::toJSON(
    evidence_payload,
    auto_unbox = TRUE,
    pretty = TRUE,
    na = "null",
    null = "null"
  )

  context_json <- if (length(context) > 0L) {
    jsonlite::toJSON(
      context,
      auto_unbox = TRUE,
      pretty = TRUE,
      na = "null",
      null = "null"
    )
  } else {
    "null"
  }

  request_text <- if (is.null(request)) "None." else request
  mode_task <- if (comparison_mode == "joint") {
    paste(
      "Compare the groups while preserving a complete group-level profile for each group.",
      "Cross-group claims may cite evidence from several groups."
    )
  } else {
    paste(
      "Interpret only the single group supplied in this generation unit.",
      "All cross_group arrays must be empty and no other group may be discussed."
    )
  }

  detail_rule <- if (prompt_style == "compact") {
    "Keep each claim concise."
  } else {
    "Provide concise but sufficiently explicit claims to show how the cited verbatims support the interpretation."
  }

  paste(
    "# ROLE",
    paste(
      "You are an expert in qualitative textual analysis working across social science,",
      "consumer research, psychology, marketing, and innovation."
    ),
    "Do not diagnose individuals and do not invent facts that are absent from the evidence.",
    "",
    "# TEXTUAL EVIDENCE",
    paste0(
      "The JSON below is data produced mechanically by R. The field `original_text` must be treated as immutable ",
      text_role, "."
    ),
    evidence_json,
    "",
    "# USER-PROVIDED CONTEXT",
    "This section is external context. It is not evidence extracted from the verbatims.",
    context_json,
    "",
    "# ANALYTICAL TASK",
    .textual_prep_scope_mission(analysis_scope),
    mode_task,
    detail_rule,
    paste0(
      "Select at most ", as.integer(n_central_verbatims),
      " representative verbatim(s) and at most ", as.integer(n_tension_verbatims),
      " tension or contrastive verbatim(s) per group."
    ),
    "",
    "# ADDITIONAL USER REQUEST",
    request_text,
    "The additional request cannot remove the output schema, evidence rules, or validation requirements.",
    "",
    "# EPISTEMIC RULES",
    paste(
      "- Return strict JSON only: no Markdown fence, no introduction, no comment, and no text after the JSON object.",
      "- Use only these statuses: expert_interpretation, hypothesis, recommendation, user_context.",
      "- Every interpretation, hypothesis, or recommendation must cite one or more evidence_ids actually shown above.",
      "- Group-level claims may cite only verbatims from that group.",
      "- A hypothesis or recommendation must include a non-empty validation_needed field.",
      "- Do not quote a paraphrase. Every quotation must reproduce original_text exactly, including punctuation and line breaks.",
      "- Do not cite a verbatim that was not included in this prompt.",
      "- Do not infer age, gender, income, social class, frequency, or another demographic characteristic unless it is explicitly supported by the cited text or user context.",
      "- Do not make an individual psychological diagnosis.",
      "- Do not invent counts, percentages, scores, or other numerical results.",
      "- Response length and lexical indicators are descriptive mechanical information; they are not measures of textual quality, coherence, or evidential strength.",
      "- When only part of a group corpus is included, state the sampling limitation in interpretation_limits.",
      "- Use null or an empty array when a field is not supported. Do not create unknown fields.",
      sep = "\n"
    ),
    "",
    "# OUTPUT SCHEMA",
    "Replace every placeholder below while preserving exactly the same field names and nesting.",
    .textual_prep_output_schema(groups, comparison_mode),
    sep = "\n"
  )
}

.textual_prep_build_units <- function(textual_evidence,
                                      analysis_scope,
                                      comparison_mode,
                                      request,
                                      context,
                                      prompt_style,
                                      text_role,
                                      include_indicators_in_prompt,
                                      n_central_verbatims,
                                      n_tension_verbatims) {
  groups <- names(textual_evidence$groups)

  if (comparison_mode == "joint") {
    active_groups <- groups[vapply(
      groups,
      function(group_name) {
        group_rows <- textual_evidence$verbatims[
          !is.na(textual_evidence$verbatims$group) &
            textual_evidence$verbatims$group == group_name,
          ,
          drop = FALSE
        ]
        any(group_rows$included_in_prompt)
      },
      logical(1)
    )]

    return(list(
      joint = list(
        groups = active_groups,
        has_evidence = length(active_groups) > 0L,
        prompt = .textual_prep_build_prompt(
          textual_evidence = textual_evidence,
          groups = active_groups,
          analysis_scope = analysis_scope,
          comparison_mode = comparison_mode,
          request = request,
          context = context,
          prompt_style = prompt_style,
          text_role = text_role,
          include_indicators_in_prompt = include_indicators_in_prompt,
          n_central_verbatims = n_central_verbatims,
          n_tension_verbatims = n_tension_verbatims
        )
      )
    ))
  }

  units <- lapply(groups, function(group_name) {
    group_rows <- textual_evidence$verbatims[
      !is.na(textual_evidence$verbatims$group) &
        textual_evidence$verbatims$group == group_name,
      ,
      drop = FALSE
    ]

    list(
      groups = group_name,
      has_evidence = any(group_rows$included_in_prompt),
      prompt = .textual_prep_build_prompt(
        textual_evidence = textual_evidence,
        groups = group_name,
        analysis_scope = analysis_scope,
        comparison_mode = comparison_mode,
        request = request,
        context = context,
        prompt_style = prompt_style,
        text_role = text_role,
        include_indicators_in_prompt = include_indicators_in_prompt,
        n_central_verbatims = n_central_verbatims,
        n_tension_verbatims = n_tension_verbatims
      )
    )
  })
  names(units) <- groups
  units
}

# ---------------------------------------------------------------------------
# Strict JSON parsing and epistemic validation
# ---------------------------------------------------------------------------

.textual_prep_as_character_vector <- function(x, field) {
  if (is.null(x) || length(x) == 0L) return(character(0))
  if (is.list(x) && !is.data.frame(x)) {
    x <- unlist(x, recursive = TRUE, use.names = FALSE)
  }
  if (!is.atomic(x)) {
    stop(sprintf("`%s` must be a character array.", field), call. = FALSE)
  }
  x <- as.character(x)
  x <- x[!is.na(x) & nzchar(trimws(x))]
  unname(x)
}

.textual_prep_strip_evidence_id_numbers <- function(text,
                                                       evidence_ids = character(0)) {
  text <- paste(text, collapse = "\n")
  evidence_ids <- unique(as.character(evidence_ids))
  evidence_ids <- evidence_ids[!is.na(evidence_ids) & nzchar(evidence_ids)]
  if (length(evidence_ids) > 0L) {
    for (evidence_id in evidence_ids) {
      text <- gsub(evidence_id, "EVIDENCE_ID", text, fixed = TRUE)
    }
  }
  gsub(
    "::verbatim::[0-9]+",
    "::verbatim::ID",
    text,
    perl = TRUE
  )
}

.textual_prep_number_tokens <- function(text) {
  text <- .textual_prep_strip_evidence_id_numbers(text)
  matches <- regmatches(
    text,
    gregexpr(
      paste0(
        "(?<![[:alnum:]_])[-+]?(?:",
        "[0-9]+(?:[.,][0-9]+)?|[.,][0-9]+",
        ")(?:[eE][-+]?[0-9]+)?%?(?![[:alnum:]_])"
      ),
      text,
      perl = TRUE
    )
  )[[1L]]
  if (length(matches) == 0L || identical(matches, "")) character(0) else matches
}

.textual_prep_number_value <- function(token) {
  token <- sub("%$", "", token)
  suppressWarnings(as.numeric(gsub(",", ".", token, fixed = TRUE)))
}

.textual_prep_number_tolerance <- function(token, value) {
  clean <- sub("%$", "", token)
  exponent <- 0
  if (grepl("[eE]", clean)) {
    exponent <- suppressWarnings(as.numeric(sub(".*[eE]", "", clean)))
    if (!is.finite(exponent)) exponent <- 0
    clean <- sub("[eE].*$", "", clean)
  }
  decimal_digits <- if (grepl("[.,]", clean)) {
    nchar(sub(".*[.,]", "", clean))
  } else {
    0L
  }
  rounding_step <- 10^(exponent - decimal_digits)
  max(
    abs(rounding_step) / 2,
    sqrt(.Machine$double.eps) * max(1, abs(value))
  )
}

.textual_prep_claim_has_unsupported_number <- function(text, source_text) {
  claim_text <- .textual_prep_strip_evidence_id_numbers(text)
  source_text <- .textual_prep_strip_evidence_id_numbers(source_text)
  claim_tokens <- .textual_prep_number_tokens(claim_text)
  if (length(claim_tokens) == 0L) return(FALSE)

  source_tokens <- .textual_prep_number_tokens(source_text)
  if (length(source_tokens) == 0L) return(TRUE)
  source_values <- vapply(
    source_tokens,
    .textual_prep_number_value,
    numeric(1)
  )
  source_values <- source_values[is.finite(source_values)]

  unsupported <- vapply(claim_tokens, function(token) {
    if (grepl(token, source_text, fixed = TRUE)) return(FALSE)
    value <- .textual_prep_number_value(token)
    if (!is.finite(value) || length(source_values) == 0L) return(TRUE)
    tolerance <- .textual_prep_number_tolerance(token, value)
    !any(abs(source_values - value) <= tolerance)
  }, logical(1))

  any(unsupported)
}

.textual_prep_contains_demographic_claim <- function(text) {
  patterns <- c(
    "\\b(men|women|male|female|boys|girls|gender|sex)\\b",
    "\\b(age|aged|years? old|teenagers?|seniors?|millennials?|gen[ -]?z)\\b",
    "\\b(social class|socioeconomic|income|low-income|high-income)\\b",
    "\\b(hommes?|femmes?|genre|sexe|age|ans|revenu|classe sociale)\\b"
  )
  any(vapply(patterns, grepl, logical(1), x = text, ignore.case = TRUE, perl = TRUE))
}

.textual_prep_contains_diagnostic_claim <- function(text) {
  patterns <- c(
    "\\b(is|are|has|have|suffers? from|diagnos(?:ed|is|ing))[^.!?]{0,35}\\b(depress(?:ed|ion)|anxiety disorder|bipolar|narciss(?:ist|istic)|psychotic|autis(?:m|tic)|adhd)\\b",
    "\\b(est|sont|a|ont|souffre(?:nt)? de)[^.!?]{0,35}\\b(depressif|depression|trouble anxieux|bipolaire|narcissique|psychotique|autiste)\\b"
  )
  any(vapply(patterns, grepl, logical(1), x = text, ignore.case = TRUE, perl = TRUE))
}

.textual_prep_validate_claim_safety <- function(text,
                                                evidence_ids,
                                                registry,
                                                context,
                                                allow_methodological_language = FALSE) {
  if (.textual_prep_contains_diagnostic_claim(text)) {
    stop("Psychological diagnoses of individuals or groups are not allowed.", call. = FALSE)
  }

  evidence_text <- registry$original_text[
    match(evidence_ids, registry$evidence_id, nomatch = 0L)
  ]
  context_text <- if (length(context) > 0L) {
    paste(unlist(context, recursive = TRUE, use.names = FALSE), collapse = "\n")
  } else {
    ""
  }
  source_text <- c(evidence_text, context_text)

  number_checked_text <- .textual_prep_strip_evidence_id_numbers(
    text,
    evidence_ids = evidence_ids
  )
  if (.textual_prep_claim_has_unsupported_number(number_checked_text, source_text)) {
    stop("A textual claim contains a numerical statement not present in its cited evidence or context.", call. = FALSE)
  }

  if (!isTRUE(allow_methodological_language) &&
      .textual_prep_contains_demographic_claim(text) &&
      !.textual_prep_contains_demographic_claim(paste(source_text, collapse = "\n"))) {
    stop("A demographic claim is not supported by the cited verbatim or user context.", call. = FALSE)
  }

  invisible(TRUE)
}

.textual_prep_validate_claim <- function(claim,
                                         field,
                                         registry,
                                         group = NULL,
                                         context = list(),
                                         allow_user_context = FALSE) {
  if (is.null(claim)) return(NULL)
  if (!is.list(claim) || is.data.frame(claim)) {
    stop(sprintf("`%s` must be null or a claim object.", field), call. = FALSE)
  }

  required <- c("text", "status", "evidence_ids", "validation_needed")
  missing_fields <- setdiff(required, names(claim))
  unknown_fields <- setdiff(names(claim), required)
  if (length(missing_fields) > 0L) {
    stop(
      sprintf("`%s` is missing required field(s): %s.", field, paste(missing_fields, collapse = ", ")),
      call. = FALSE
    )
  }
  if (length(unknown_fields) > 0L) {
    stop(
      sprintf("`%s` contains unexpected field(s): %s.", field, paste(unknown_fields, collapse = ", ")),
      call. = FALSE
    )
  }

  if (!.textual_prep_is_scalar_string(claim$text)) {
    stop(sprintf("`%s$text` must be a non-empty string.", field), call. = FALSE)
  }
  status <- as.character(claim$status)
  if (length(status) != 1L || is.na(status) || !status %in% .textual_prep_statuses) {
    stop(
      sprintf("`%s$status` must be one of: %s.", field, paste(.textual_prep_statuses, collapse = ", ")),
      call. = FALSE
    )
  }

  evidence_ids <- .textual_prep_as_character_vector(
    claim$evidence_ids,
    paste0(field, "$evidence_ids")
  )

  if (status == "user_context") {
    if (!allow_user_context || length(context) == 0L) {
      stop(
        sprintf("`%s` cannot use status `user_context` in this field.", field),
        call. = FALSE
      )
    }
    if (length(evidence_ids) > 0L) {
      stop(
        sprintf("`%s` with status `user_context` must use an empty evidence_ids array.", field),
        call. = FALSE
      )
    }
  } else {
    if (length(evidence_ids) == 0L) {
      stop(sprintf("`%s` must cite at least one verbatim evidence_id.", field), call. = FALSE)
    }

    invalid <- setdiff(evidence_ids, registry$evidence_id[registry$included_in_prompt])
    if (length(invalid) > 0L) {
      stop(
        sprintf("`%s` cites unknown or non-presented evidence ID(s): %s.", field, paste(invalid, collapse = ", ")),
        call. = FALSE
      )
    }

    if (!is.null(group)) {
      evidence_groups <- registry$group[match(evidence_ids, registry$evidence_id)]
      if (any(is.na(evidence_groups) | evidence_groups != group)) {
        stop(
          sprintf("`%s` cites evidence belonging to another group.", field),
          call. = FALSE
        )
      }
    }
  }

  validation_needed <- claim$validation_needed
  if (is.null(validation_needed) ||
      (is.character(validation_needed) && length(validation_needed) == 1L &&
       (is.na(validation_needed) || !nzchar(trimws(validation_needed))))) {
    validation_needed <- NULL
  } else if (!.textual_prep_is_scalar_string(validation_needed)) {
    stop(
      sprintf("`%s$validation_needed` must be null or a non-empty string.", field),
      call. = FALSE
    )
  } else {
    validation_needed <- trimws(validation_needed)
  }

  if (status %in% c("hypothesis", "recommendation") && is.null(validation_needed)) {
    stop(
      sprintf("`%s` has status `%s` and requires validation_needed.", field, status),
      call. = FALSE
    )
  }

  .textual_prep_validate_claim_safety(
    text = claim$text,
    evidence_ids = evidence_ids,
    registry = registry,
    context = context
  )

  list(
    text = trimws(claim$text),
    status = status,
    evidence_ids = unique(evidence_ids),
    validation_needed = validation_needed
  )
}

.textual_prep_validate_claim_list <- function(x,
                                              field,
                                              registry,
                                              group = NULL,
                                              context = list(),
                                              allow_user_context = FALSE) {
  if (is.null(x) || length(x) == 0L) return(list())
  if (!is.list(x) || is.data.frame(x)) {
    stop(sprintf("`%s` must be a JSON array of claim objects.", field), call. = FALSE)
  }

  unname(lapply(seq_along(x), function(i) {
    .textual_prep_validate_claim(
      x[[i]],
      field = sprintf("%s[[%d]]", field, i),
      registry = registry,
      group = group,
      context = context,
      allow_user_context = allow_user_context
    )
  }))
}

.textual_prep_validate_quote <- function(x, field, registry, group) {
  if (!is.list(x) || is.data.frame(x)) {
    stop(sprintf("`%s` must be a quotation object.", field), call. = FALSE)
  }
  required <- c("evidence_id", "quotation", "rationale", "status")
  missing_fields <- setdiff(required, names(x))
  unknown_fields <- setdiff(names(x), required)
  if (length(missing_fields) > 0L) {
    stop(sprintf("`%s` is missing: %s.", field, paste(missing_fields, collapse = ", ")), call. = FALSE)
  }
  if (length(unknown_fields) > 0L) {
    stop(sprintf("`%s` contains unexpected field(s): %s.", field, paste(unknown_fields, collapse = ", ")), call. = FALSE)
  }

  if (!.textual_prep_is_scalar_string(x$evidence_id) ||
      !x$evidence_id %in% registry$evidence_id[registry$included_in_prompt]) {
    stop(sprintf("`%s$evidence_id` is unknown or was not included in the prompt.", field), call. = FALSE)
  }

  row <- registry[match(x$evidence_id, registry$evidence_id), , drop = FALSE]
  if (is.na(row$group[[1]]) || row$group[[1]] != group) {
    stop(sprintf("`%s` cites a verbatim from another group.", field), call. = FALSE)
  }
  if (!.textual_prep_is_scalar_string(x$quotation, allow_empty = TRUE) ||
      !identical(as.character(x$quotation), as.character(row$original_text[[1]]))) {
    stop(sprintf("`%s$quotation` must exactly match original_text.", field), call. = FALSE)
  }
  if (!.textual_prep_is_scalar_string(x$rationale)) {
    stop(sprintf("`%s$rationale` must be a non-empty string.", field), call. = FALSE)
  }
  if (!identical(as.character(x$status), "expert_interpretation")) {
    stop(sprintf("`%s$status` must be `expert_interpretation`.", field), call. = FALSE)
  }

  list(
    evidence_id = x$evidence_id,
    quotation = x$quotation,
    rationale = trimws(x$rationale),
    status = "expert_interpretation"
  )
}

.textual_prep_validate_quote_list <- function(x, field, registry, group) {
  if (is.null(x) || length(x) == 0L) return(list())
  if (!is.list(x) || is.data.frame(x)) {
    stop(sprintf("`%s` must be a JSON array of quotation objects.", field), call. = FALSE)
  }

  unname(lapply(seq_along(x), function(i) {
    .textual_prep_validate_quote(
      x[[i]],
      field = sprintf("%s[[%d]]", field, i),
      registry = registry,
      group = group
    )
  }))
}

.textual_prep_validate_group_profile <- function(x,
                                                 group_name,
                                                 registry,
                                                 context) {
  field <- paste0("groups$", group_name)
  if (!is.list(x) || is.data.frame(x)) {
    stop(sprintf("`%s` must be an object.", field), call. = FALSE)
  }
  missing_fields <- setdiff(.textual_prep_group_fields, names(x))
  unknown_fields <- setdiff(names(x), .textual_prep_group_fields)
  if (length(missing_fields) > 0L) {
    stop(sprintf("`%s` is missing: %s.", field, paste(missing_fields, collapse = ", ")), call. = FALSE)
  }
  if (length(unknown_fields) > 0L) {
    stop(sprintf("`%s` contains unexpected field(s): %s.", field, paste(unknown_fields, collapse = ", ")), call. = FALSE)
  }
  if (!.textual_prep_is_scalar_string(x$group) || !identical(as.character(x$group), group_name)) {
    stop(sprintf("`%s$group` must equal `%s`.", field, group_name), call. = FALSE)
  }

  scalar_fields <- c(
    "core_textual_profile",
    "tone_or_stance",
    "intra_group_consistency"
  )
  list_fields <- c(
    "main_themes",
    "dominant_concerns",
    "narrative_frames",
    "motivations",
    "barriers",
    "perceived_benefits",
    "social_norms",
    "identity_cues",
    "contradictions",
    "minority_positions"
  )

  out <- list(group = group_name)
  for (name in scalar_fields) {
    out[[name]] <- .textual_prep_validate_claim(
      x[[name]],
      field = paste0(field, "$", name),
      registry = registry,
      group = group_name,
      context = context,
      allow_user_context = FALSE
    )
  }
  for (name in list_fields) {
    out[[name]] <- .textual_prep_validate_claim_list(
      x[[name]],
      field = paste0(field, "$", name),
      registry = registry,
      group = group_name,
      context = context,
      allow_user_context = FALSE
    )
  }

  out$representative_verbatims <- .textual_prep_validate_quote_list(
    x$representative_verbatims,
    field = paste0(field, "$representative_verbatims"),
    registry = registry,
    group = group_name
  )
  out$tension_verbatims <- .textual_prep_validate_quote_list(
    x$tension_verbatims,
    field = paste0(field, "$tension_verbatims"),
    registry = registry,
    group = group_name
  )
  out$interpretation_limits <- .textual_prep_validate_claim_list(
    x$interpretation_limits,
    field = paste0(field, "$interpretation_limits"),
    registry = registry,
    group = group_name,
    context = context,
    allow_user_context = length(context) > 0L
  )

  out[.textual_prep_group_fields]
}

.textual_prep_validate_cross_group <- function(x,
                                               registry,
                                               context,
                                               comparison_mode) {
  if (!is.list(x) || is.data.frame(x)) {
    stop("`cross_group` must be an object.", call. = FALSE)
  }
  missing_fields <- setdiff(.textual_prep_cross_group_fields, names(x))
  unknown_fields <- setdiff(names(x), .textual_prep_cross_group_fields)
  if (length(missing_fields) > 0L) {
    stop(sprintf("`cross_group` is missing: %s.", paste(missing_fields, collapse = ", ")), call. = FALSE)
  }
  if (length(unknown_fields) > 0L) {
    stop(sprintf("`cross_group` contains unexpected field(s): %s.", paste(unknown_fields, collapse = ", ")), call. = FALSE)
  }

  out <- lapply(.textual_prep_cross_group_fields, function(name) {
    .textual_prep_validate_claim_list(
      x[[name]],
      field = paste0("cross_group$", name),
      registry = registry,
      group = NULL,
      context = context,
      allow_user_context = length(context) > 0L
    )
  })
  names(out) <- .textual_prep_cross_group_fields

  if (comparison_mode == "isolated" && any(lengths(out) > 0L)) {
    stop("All `cross_group` arrays must be empty in isolated mode.", call. = FALSE)
  }

  out
}

.validate_textual_prep_parsed <- function(parsed,
                                          expected_groups,
                                          registry,
                                          context,
                                          analysis_scope,
                                          comparison_mode) {
  if (!is.list(parsed) || is.data.frame(parsed)) {
    stop("The JSON root must be an object.", call. = FALSE)
  }
  unknown_top <- setdiff(names(parsed), c("groups", "cross_group"))
  missing_top <- setdiff(c("groups", "cross_group"), names(parsed))
  if (length(missing_top) > 0L) {
    stop(sprintf("The JSON root is missing: %s.", paste(missing_top, collapse = ", ")), call. = FALSE)
  }
  if (length(unknown_top) > 0L) {
    stop(sprintf("Unexpected top-level JSON field(s): %s.", paste(unknown_top, collapse = ", ")), call. = FALSE)
  }
  if (!is.list(parsed$groups) || is.data.frame(parsed$groups)) {
    stop("`groups` must be a named object.", call. = FALSE)
  }
  if (is.null(names(parsed$groups)) || !setequal(names(parsed$groups), expected_groups)) {
    stop("The parsed group names do not match the generation unit.", call. = FALSE)
  }

  groups <- stats::setNames(
    lapply(expected_groups, function(group_name) {
      .textual_prep_validate_group_profile(
        parsed$groups[[group_name]],
        group_name = group_name,
        registry = registry,
        context = context
      )
    }),
    expected_groups
  )

  cross_group <- .textual_prep_validate_cross_group(
    parsed$cross_group,
    registry = registry,
    context = context,
    comparison_mode = comparison_mode
  )

  list(
    groups = groups,
    cross_group = cross_group,
    metadata = list(
      analysis_scope = analysis_scope,
      comparison_mode = comparison_mode,
      groups = expected_groups,
      parse_status = "success"
    )
  )
}

.parse_textual_prep_response <- function(text,
                                         expected_groups,
                                         textual_evidence,
                                         context,
                                         analysis_scope,
                                         comparison_mode) {
  tryCatch({
    text <- paste(text, collapse = "\n")
    text <- gsub("\r\n", "\n", text, fixed = TRUE)
    text <- gsub("\r", "\n", text, fixed = TRUE)
    trimmed <- trimws(text)

    if (!nzchar(trimmed)) {
      stop("The LLM response is empty.", call. = FALSE)
    }
    if (grepl("```", trimmed, fixed = TRUE)) {
      stop("The LLM response contains a Markdown fence; strict JSON was required.", call. = FALSE)
    }
    if (substr(trimmed, 1L, 1L) != "{" ||
        substr(trimmed, nchar(trimmed), nchar(trimmed)) != "}") {
      stop("The LLM response must contain one strict JSON object and no surrounding text.", call. = FALSE)
    }

    parsed <- jsonlite::fromJSON(trimmed, simplifyDataFrame = FALSE)
    profiles <- .validate_textual_prep_parsed(
      parsed = parsed,
      expected_groups = expected_groups,
      registry = textual_evidence$evidence_registry,
      context = context,
      analysis_scope = analysis_scope,
      comparison_mode = comparison_mode
    )

    list(
      parse_status = "success",
      parse_error = NULL,
      textual_profiles = profiles
    )
  }, error = function(e) {
    list(
      parse_status = "error",
      parse_error = conditionMessage(e),
      textual_profiles = NULL
    )
  })
}

.textual_prep_response_text <- function(response) {
  if (is.null(response)) return("")
  if (is.data.frame(response) && "response" %in% names(response)) {
    return(paste(response$response, collapse = "\n"))
  }
  if (is.list(response) && !is.null(response$response)) {
    return(paste(response$response, collapse = "\n"))
  }
  paste(response, collapse = "\n")
}

# ---------------------------------------------------------------------------
# Output assembly and compatibility
# ---------------------------------------------------------------------------

.textual_prep_empty_cross_group <- function() {
  stats::setNames(
    lapply(.textual_prep_cross_group_fields, function(x) list()),
    .textual_prep_cross_group_fields
  )
}

.textual_prep_mechanical_limit_claim <- function(text) {
  list(
    text = text,
    status = "user_context",
    evidence_ids = character(0),
    validation_needed = NULL
  )
}

.textual_prep_empty_group_profile <- function(group, reason) {
  out <- list(
    group = group,
    core_textual_profile = NULL,
    main_themes = list(),
    dominant_concerns = list(),
    tone_or_stance = NULL,
    narrative_frames = list(),
    motivations = list(),
    barriers = list(),
    perceived_benefits = list(),
    social_norms = list(),
    identity_cues = list(),
    contradictions = list(),
    minority_positions = list(),
    representative_verbatims = list(),
    tension_verbatims = list(),
    intra_group_consistency = NULL,
    interpretation_limits = list(.textual_prep_mechanical_limit_claim(reason))
  )
  out[.textual_prep_group_fields]
}

.textual_prep_add_sampling_limits <- function(textual_profiles, textual_evidence) {
  for (group_name in names(textual_profiles$groups)) {
    diag <- textual_evidence$group_diagnostics[
      textual_evidence$group_diagnostics$group == group_name,
      ,
      drop = FALSE
    ]
    if (nrow(diag) == 0L) next

    if (diag$n_non_empty[[1]] == 0L) {
      textual_profiles$groups[[group_name]] <- .textual_prep_empty_group_profile(
        group_name,
        "No non-empty verbatim was available for this group."
      )
      next
    }

    if (diag$n_included_in_prompt[[1]] == 0L) {
      textual_profiles$groups[[group_name]] <- .textual_prep_empty_group_profile(
        group_name,
        "No verbatim from this group was included in the prompt."
      )
      next
    }

    if (is.finite(diag$sampling_fraction[[1]]) && diag$sampling_fraction[[1]] < 1) {
      limit <- .textual_prep_mechanical_limit_claim(
        paste0(
          "Only ", diag$n_included_in_prompt[[1]], " of ",
          diag$n_non_empty[[1]],
          " non-empty verbatims from this group were included in the prompt; minority positions may therefore be omitted."
        )
      )
      textual_profiles$groups[[group_name]]$interpretation_limits <- c(
        textual_profiles$groups[[group_name]]$interpretation_limits,
        list(limit)
      )
    }
  }

  textual_profiles
}

.textual_prep_combine_units <- function(unit_results,
                                        all_groups,
                                        textual_evidence,
                                        analysis_scope,
                                        comparison_mode) {
  statuses <- vapply(
    unit_results,
    function(x) x$parsed$parse_status,
    character(1)
  )

  if (length(statuses) == 0L || all(statuses == "no_evidence")) {
    return(list(
      parse_status = "no_evidence",
      parse_error = "No verbatim was included in any generation unit.",
      textual_profiles = NULL
    ))
  }

  if (any(statuses == "error")) {
    errors <- vapply(
      unit_results[statuses == "error"],
      function(x) x$parsed$parse_error,
      character(1)
    )
    return(list(
      parse_status = "error",
      parse_error = paste(unique(errors), collapse = " | "),
      textual_profiles = NULL
    ))
  }

  if (comparison_mode == "joint") {
    profiles <- unit_results[[1]]$parsed$textual_profiles
  } else {
    groups <- list()
    for (unit in unit_results) {
      if (unit$parsed$parse_status == "success") {
        groups <- c(groups, unit$parsed$textual_profiles$groups)
      }
    }
    profiles <- list(
      groups = groups,
      cross_group = .textual_prep_empty_cross_group(),
      metadata = list(
        analysis_scope = analysis_scope,
        comparison_mode = comparison_mode,
        groups = all_groups,
        parse_status = "success"
      )
    )
  }

  missing_groups <- setdiff(all_groups, names(profiles$groups))
  for (group_name in missing_groups) {
    profiles$groups[[group_name]] <- .textual_prep_empty_group_profile(
      group_name,
      "No semantic profile was generated for this group."
    )
  }
  profiles$groups <- profiles$groups[all_groups]
  profiles <- .textual_prep_add_sampling_limits(profiles, textual_evidence)

  list(
    parse_status = "success",
    parse_error = NULL,
    textual_profiles = profiles
  )
}

.textual_profile_claim_text <- function(x) {
  if (is.null(x) || !is.list(x) || is.null(x$text)) return(NA_character_)
  as.character(x$text)
}

.textual_profile_claim_texts <- function(x) {
  if (is.null(x) || length(x) == 0L) return(character(0))
  out <- vapply(x, .textual_profile_claim_text, character(1))
  out[!is.na(out) & nzchar(out)]
}

.textual_profile_group_to_legacy <- function(group_profile) {
  representative <- if (length(group_profile$representative_verbatims) > 0L) {
    vapply(group_profile$representative_verbatims, function(x) x$quotation, character(1))
  } else {
    character(0)
  }
  tension <- if (length(group_profile$tension_verbatims) > 0L) {
    vapply(group_profile$tension_verbatims, function(x) x$quotation, character(1))
  } else {
    character(0)
  }
  core <- .textual_profile_claim_text(group_profile$core_textual_profile)
  consistency <- .textual_profile_claim_text(group_profile$intra_group_consistency)

  list(
    core_textual_profile = core,
    main_themes = .textual_profile_claim_texts(group_profile$main_themes),
    dominant_concerns = .textual_profile_claim_texts(group_profile$dominant_concerns),
    tone_or_stance = .textual_profile_claim_texts(list(group_profile$tone_or_stance)),
    intra_group_consistency = consistency,
    intra_group_consistency_raw = consistency,
    injectable_summary = core,
    central_verbatim_cues = representative,
    contrastive_verbatim_cues = tension,
    tension_verbatim_cues = tension
  )
}

.build_textual_prep_legacy_groups <- function(result,
                                              attach_selected_verbatims,
                                              n_central_verbatims,
                                              n_tension_verbatims,
                                              max_verbatim_chars) {
  groups <- names(result$textual_evidence$groups)
  profiles <- if (!is.null(result$textual_profiles)) result$textual_profiles$groups else list()

  stats::setNames(lapply(groups, function(group_name) {
    profile <- profiles[[group_name]]
    parsed <- if (is.null(profile)) {
      list(
        core_textual_profile = NA_character_,
        main_themes = character(0),
        dominant_concerns = character(0),
        tone_or_stance = character(0),
        intra_group_consistency = NA_character_,
        intra_group_consistency_raw = NA_character_,
        injectable_summary = NA_character_,
        central_verbatim_cues = character(0),
        contrastive_verbatim_cues = character(0),
        tension_verbatim_cues = character(0)
      )
    } else {
      .textual_profile_group_to_legacy(profile)
    }

    selected <- if (attach_selected_verbatims && !is.null(profile)) {
      central <- utils::head(parsed$central_verbatim_cues, n_central_verbatims)
      tension <- utils::head(parsed$tension_verbatim_cues, n_tension_verbatims)
      list(
        central = .truncate_verbatim_textprep(central, max_chars = max_verbatim_chars),
        contrastive = .truncate_verbatim_textprep(tension, max_chars = max_verbatim_chars),
        tension = .truncate_verbatim_textprep(tension, max_chars = max_verbatim_chars)
      )
    } else {
      list(central = character(0), contrastive = character(0), tension = character(0))
    }

    unit_name <- if (result$metadata$comparison_mode == "joint") "joint" else group_name
    unit <- result$units[[unit_name]]
    group_info <- result$textual_evidence$groups[[group_name]]

    list(
      prompt = if (!is.null(unit)) unit$prompt else NULL,
      response = if (!is.null(unit)) unit$response else NULL,
      parsed = parsed,
      corpus_metrics = result$textual_evidence$corpus_metrics[[group_name]],
      lexical_profile = group_info$lexical_profile,
      selected_verbatims = selected,
      frequent_terms = group_info$frequent_terms,
      notable_expressions = group_info$frequent_terms
    )
  }), groups)
}

#' Prepare traceable textual evidence and semantic group profiles
#'
#' @description
#' `nail_textual_prep()` separates two layers. R first builds a complete and
#' deterministic `textual_evidence` object containing every source row,
#' verbatim identifier, volume diagnostic, sampling decision, lexical indicator,
#' and evidence registry. An optional language model then produces a constrained
#' `textual_description` whose claims cite presented verbatim identifiers,
#' explain their support, and receive stable `claim_id` values from R.
#'
#' `textual_profiles` remains available as a compatibility view derived from
#' the canonical description. Cross-group interpretation is deliberately
#' deferred to the integration workflow.
#'
#' The function is a preparation workflow rather than a final narrative report.
#' Its outputs are intended for later use by `nail_textual()` and
#' `nail_textual_contextualized()`.
#'
#' @param dataset A data frame containing a grouping column and a textual column.
#' @param num.var Integer index of the grouping column.
#' @param num.text Integer index of the textual column.
#' @param model Character scalar naming the LLM model.
#' @param provider LLM provider, either `"ollama"` or `"gemini"`.
#' @param sample.pct Fraction of non-empty verbatims retained within each group.
#'   Values in `[0, 1]` are accepted. Sampling is deterministic for a given data
#'   set and `seed`; all source rows remain in `textual_evidence`.
#' @param seed Optional integer used by the deterministic within-group sampling
#'   rank. The implementation does not alter R's global random-number state.
#' @param language Stop-word language used by the optional lexical analysis.
#' @param prompt_style Prompt verbosity, either `"detailed"` or `"compact"`.
#' @param text_role Terminology used only in the preparation prompt to refer
#'   to the source texts: responses, comments, or verbatims. It does not modify
#'   the evidence, schema, parsing, or analytical results.
#' @param include_verbatims_in_prompt Deprecated compatibility argument.
#'   Traceable semantic profiles always require the sampled verbatims to be
#'   included. Supplying `FALSE` produces a warning and is otherwise ignored.
#' @param attach_selected_verbatims Whether to populate the legacy
#'   `selected_verbatims` compatibility view.
#' @param n_central_verbatims Maximum number of representative verbatims
#'   requested per group and retained in the legacy view.
#' @param n_tension_verbatims Maximum number of contrastive verbatims
#'   requested per group and retained under the historical tension-verbatim
#'   name in the compatibility view.
#' @param max_verbatim_chars Maximum displayed length in the legacy compatibility
#'   view. Exact quotations in `textual_profiles` are never truncated.
#' @param lexical_analysis Whether to compute mechanical lexical indicators from
#'   the complete non-empty corpus.
#' @param lexical_unit Lexical unit used by `FactoMineR::descfreq()`:
#'   occurrences or documents.
#' @param lexical_proba Exploratory p-value threshold used for lexical markers.
#' @param min_word_frequency Minimum retained frequency for a lexical term.
#' @param min_word_length Minimum retained word length.
#' @param top_n_characteristic_words Maximum number of positive and negative
#'   lexical markers retained per group.
#' @param top_n_frequent_terms Number of mechanically frequent terms retained per
#'   group.
#' @param include_indicators_in_prompt Whether mechanical diagnostics and lexical
#'   indicators are included in the LLM prompt. This does not modify
#'   `textual_evidence`.
#' @param compute_length_analysis Whether to compute the mechanical response-
#'   length analysis.
#' @param generate Logical. When `FALSE`, all evidence, prompts, and machine
#'   schemas are built but no LLM call is made. When `TRUE`, Ollama receives the
#'   schema through `format` and Gemini through `responseJsonSchema`.
#' @param analysis_scope Optional analytical emphasis: `"general"`,
#'   `"sociological"`, `"consumer"`, `"psychological"`, `"marketing"`,
#'   `"innovation"`, or `"cross_functional"`. The emphasis cannot expand the
#'   reduced core textual-description schema.
#' @param comparison_mode `"isolated"` creates one generation unit per group;
#'   `"joint"` creates one unit containing all groups that have at least one
#'   verbatim included in the prompt. Groups without usable prompt evidence
#'   remain fully represented in `textual_evidence`.
#' @param isolate.groups Deprecated logical alias for `comparison_mode`.
#' @param request Optional additional analytical request. It supplements but
#'   cannot replace the mandatory evidence and JSON rules.
#' @param context Optional external context supplied as a character scalar or a
#'   named list. It is displayed separately from the textual evidence.
#' @param max_prompt_characters Maximum number of characters of verbatim evidence
#'   included per group after sampling. This is a character budget, not a token
#'   count. Use `Inf` for no budget.
#' @param ... Additional provider-specific LLM options.
#'
#' @return A list of class `nail_textual_prep` containing:
#'   * `prompt`, `response`, and `parsed`;
#'   * `textual_description`, the canonical constrained semantic artifact;
#'   * `textual_profiles`, a compatibility view or `NULL`;
#'   * `textual_evidence`, the complete mechanical artifact;
#'   * `units`, including the prompt, machine schema, raw response, and status;
#'   * `generation` and `validation`, with call counts, errors, and the claim
#'     registry;
#'   * `legacy_groups`, a transitional view of the historical fields;
#'   * `metadata`, including the preparation scope, comparison mode, stored
#'     context, preparation request, and compatibility settings required to
#'     resume an offline preparation without rebuilding its evidence.
#'
#' `textual_evidence` is invariant to model, provider, request, context,
#' `analysis_scope`, `comparison_mode`, prompt style, and `generate` when the
#' data and mechanical settings are unchanged.
#'
#' @examples
#' prep <- nail_textual_prep(
#'   dataset = local_food,
#'   num.var = 1,
#'   num.text = 2,
#'   sample.pct = 0.5,
#'   seed = 123,
#'   lexical_analysis = FALSE,
#'   generate = FALSE
#' )
#'
#' prep$textual_evidence$group_diagnostics
#' prep$prompt
#'
#' @export
nail_textual_prep <- function(dataset,
                              num.var,
                              num.text,
                              model = "llama3",
                              provider = c("ollama", "gemini"),
                              sample.pct = 1,
                              seed = NULL,
                              language = c("en", "fr", "none"),
                              prompt_style = c("detailed", "compact"),
                              text_role = c("responses", "comments", "verbatims"),
                              include_verbatims_in_prompt = TRUE,
                              attach_selected_verbatims = TRUE,
                              n_central_verbatims = 2,
                              n_tension_verbatims = 1,
                              max_verbatim_chars = 220,
                              lexical_analysis = TRUE,
                              lexical_unit = c("occurrence", "document"),
                              lexical_proba = 0.05,
                              min_word_frequency = 2,
                              min_word_length = 4,
                              top_n_characteristic_words = 8,
                              top_n_frequent_terms = 5,
                              include_indicators_in_prompt = TRUE,
                              compute_length_analysis = TRUE,
                              generate = FALSE,
                              analysis_scope = c(
                                "general",
                                "sociological",
                                "consumer",
                                "psychological",
                                "marketing",
                                "innovation",
                                "cross_functional"
                              ),
                              comparison_mode = c("isolated", "joint"),
                              isolate.groups = NULL,
                              request = NULL,
                              context = NULL,
                              max_prompt_characters = Inf,
                              ...) {
  comparison_mode_missing <- missing(comparison_mode)

  provider <- match.arg(provider)
  language <- match.arg(language)
  prompt_style <- match.arg(prompt_style)
  text_role <- match.arg(text_role)
  lexical_unit <- match.arg(lexical_unit)
  analysis_scope <- match.arg(analysis_scope)
  comparison_mode <- match.arg(comparison_mode)

  if (!is.null(isolate.groups)) {
    if (!is.logical(isolate.groups) || length(isolate.groups) != 1L || is.na(isolate.groups)) {
      stop("`isolate.groups` must be NULL or a single logical value.", call. = FALSE)
    }
    mapped_mode <- if (isolate.groups) "isolated" else "joint"
    if (!comparison_mode_missing && !identical(comparison_mode, mapped_mode)) {
      stop("`isolate.groups` and `comparison_mode` specify conflicting modes.", call. = FALSE)
    }
    warning(
      "`isolate.groups` is deprecated; use `comparison_mode` instead.",
      call. = FALSE
    )
    comparison_mode <- mapped_mode
  }

  if (!isTRUE(include_verbatims_in_prompt)) {
    warning(
      paste(
        "`include_verbatims_in_prompt = FALSE` is deprecated and ignored.",
        "Traceable semantic profiles require the sampled verbatims in the prompt."
      ),
      call. = FALSE
    )
    include_verbatims_in_prompt <- TRUE
  }

  context <- .textual_prep_validate_context(context)
  .validate_textual_prep_options(
    dataset = dataset,
    num.var = num.var,
    num.text = num.text,
    sample.pct = sample.pct,
    seed = seed,
    max_prompt_characters = max_prompt_characters,
    include_verbatims_in_prompt = include_verbatims_in_prompt,
    attach_selected_verbatims = attach_selected_verbatims,
    n_central_verbatims = n_central_verbatims,
    n_tension_verbatims = n_tension_verbatims,
    max_verbatim_chars = max_verbatim_chars,
    lexical_analysis = lexical_analysis,
    lexical_proba = lexical_proba,
    min_word_frequency = min_word_frequency,
    min_word_length = min_word_length,
    top_n_characteristic_words = top_n_characteristic_words,
    top_n_frequent_terms = top_n_frequent_terms,
    include_indicators_in_prompt = include_indicators_in_prompt,
    compute_length_analysis = compute_length_analysis,
    generate = generate,
    request = request,
    context = context
  )

  textual_evidence <- .build_textual_evidence(
    dataset = dataset,
    num.var = num.var,
    num.text = num.text,
    sample.pct = sample.pct,
    seed = seed,
    max_prompt_characters = max_prompt_characters,
    language = language,
    lexical_analysis = lexical_analysis,
    lexical_unit = lexical_unit,
    lexical_proba = lexical_proba,
    min_word_frequency = min_word_frequency,
    min_word_length = min_word_length,
    top_n_characteristic_words = top_n_characteristic_words,
    top_n_frequent_terms = top_n_frequent_terms,
    compute_length_analysis = compute_length_analysis
  )

  units <- .nail_text_build_units(
    textual_evidence = textual_evidence,
    analysis_scope = analysis_scope,
    comparison_mode = comparison_mode,
    request = request,
    context = context,
    prompt_style = prompt_style,
    text_role = text_role,
    include_indicators_in_prompt = include_indicators_in_prompt,
    n_central_verbatims = n_central_verbatims,
    n_contrastive_verbatims = n_tension_verbatims
  )

  result <- .nail_text_build_preparation_result(
    units = units,
    textual_evidence = textual_evidence,
    analysis_scope = analysis_scope,
    comparison_mode = comparison_mode,
    provider = provider,
    model = model,
    generate = generate,
    context = context,
    request = request,
    prompt_style = prompt_style,
    text_role = text_role,
    attach_selected_verbatims = attach_selected_verbatims,
    n_central_verbatims = n_central_verbatims,
    n_contrastive_verbatims = n_tension_verbatims,
    max_verbatim_chars = max_verbatim_chars,
    llm_api_options = list(...)
  )

  class(result) <- c("nail_textual_prep", "list")
  result$legacy_groups <- .build_textual_prep_legacy_groups(
    result = result,
    attach_selected_verbatims = attach_selected_verbatims,
    n_central_verbatims = n_central_verbatims,
    n_tension_verbatims = n_tension_verbatims,
    max_verbatim_chars = max_verbatim_chars
  )

  attr(result, "textual_evidence") <- result$textual_evidence
  attr(result, "textual_profiles") <- result$textual_profiles
  attr(result, "textual_description") <- result$textual_description
  attr(result, "legacy_textual_prep") <- result$legacy_groups
  attr(result, "corpus_metrics") <- result$textual_evidence$corpus_metrics
  attr(result, "length_group_analysis") <- result$textual_evidence$length_group_analysis
  attr(result, "lexical_analysis") <- result$textual_evidence$lexical_analysis
  result
}
