# ---------------------------------------------------------------------------
# nail_textual_prep(): structured textual preparation and lexical indicators
# ---------------------------------------------------------------------------

# This file contains only the helpers and exported function required by
# nail_textual_prep(). It depends on nail_textual() for prompt construction and
# on internal NaileR helpers .call_llm_base() and .strip_markdown_fences().

# ---------------------------------------------------------------------------
# Validation and generic helpers
# ---------------------------------------------------------------------------

.validate_textual_prep_options <- function(include_verbatims_in_prompt,
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
                                           compute_length_analysis) {
  logical_args <- list(
    include_verbatims_in_prompt = include_verbatims_in_prompt,
    attach_selected_verbatims = attach_selected_verbatims,
    lexical_analysis = lexical_analysis,
    include_indicators_in_prompt = include_indicators_in_prompt,
    compute_length_analysis = compute_length_analysis
  )

  invalid_logicals <- names(logical_args)[
    !vapply(
      logical_args,
      function(x) is.logical(x) && length(x) == 1 && !is.na(x),
      logical(1)
    )
  ]

  if (length(invalid_logicals) > 0) {
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
    )) 0 else 1

    if (!is.numeric(value) || length(value) != 1 || is.na(value) ||
        !is.finite(value) || value != floor(value) || value < minimum) {
      stop(
        sprintf(
          "`%s` must be a single integer >= %d.",
          arg_name,
          minimum
        ),
        call. = FALSE
      )
    }
  }

  if (!is.numeric(max_verbatim_chars) || length(max_verbatim_chars) != 1 ||
      is.na(max_verbatim_chars) || !is.finite(max_verbatim_chars) ||
      max_verbatim_chars != floor(max_verbatim_chars) ||
      max_verbatim_chars < 4) {
    stop("`max_verbatim_chars` must be a single integer >= 4.", call. = FALSE)
  }

  if (!is.numeric(lexical_proba) || length(lexical_proba) != 1 ||
      is.na(lexical_proba) || !is.finite(lexical_proba) ||
      lexical_proba <= 0 || lexical_proba > 1) {
    stop("`lexical_proba` must be a single numeric value in ]0, 1].", call. = FALSE)
  }

  invisible(TRUE)
}

.empty_parsed_textprep <- function() {
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

.text_keyword_score_textprep <- function(text, keywords) {
  if (length(keywords) == 0) return(0)

  text_tokens <- .tokenize_one_text_textprep(
    text,
    min_word_length = 1,
    stopwords = character(0),
    unique_only = TRUE
  )

  sum(keywords %in% text_tokens)
}

.lexical_distance_to_set_textprep <- function(text, set_texts) {
  if (length(set_texts) == 0) return(0)

  tokenize <- function(x) {
    .tokenize_one_text_textprep(
      x,
      min_word_length = 3,
      stopwords = character(0),
      unique_only = TRUE
    )
  }

  tokens_a <- tokenize(text)
  if (length(tokens_a) == 0) return(1)

  distances <- vapply(set_texts, function(reference_text) {
    tokens_b <- tokenize(reference_text)
    if (length(tokens_b) == 0) return(1)

    intersection_size <- length(intersect(tokens_a, tokens_b))
    union_size <- length(unique(c(tokens_a, tokens_b)))

    if (union_size == 0) 1 else 1 - intersection_size / union_size
  }, numeric(1))

  min(distances, na.rm = TRUE)
}

.select_representative_verbatims_textprep <- function(dataset,
                                                      num.var,
                                                      num.text,
                                                      textual_summary = NULL,
                                                      lexical_profiles = NULL,
                                                      n_central = 2,
                                                      n_tension = 1,
                                                      min_chars = 25,
                                                      max_chars = 220) {
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
    corpus <- .extract_nonempty_texts_textprep(group_data[[text_name]])
    corpus <- .deduplicate_texts_textprep(corpus)
    corpus <- corpus[nchar(corpus) >= min_chars]

    if (length(corpus) == 0) {
      out[[group_name]] <- list(
        central = character(0),
        contrastive = character(0),
        tension = character(0)
      )
      next
    }

    parsed <- if (!is.null(textual_summary) && group_name %in% names(textual_summary)) {
      textual_summary[[group_name]]
    } else {
      NULL
    }

    characteristic_words <- character(0)
    if (!is.null(lexical_profiles) && group_name %in% names(lexical_profiles)) {
      characteristic_words <- lexical_profiles[[group_name]]$characteristic_words
    }

    keywords <- .tokenize_keywords_textprep(c(
      if (!is.null(parsed)) parsed$main_themes else NULL,
      if (!is.null(parsed)) parsed$dominant_concerns else NULL,
      if (!is.null(parsed)) parsed$core_textual_profile else NULL,
      characteristic_words
    ))

    character_lengths <- nchar(corpus)
    median_length <- stats::median(character_lengths)

    keyword_scores <- vapply(
      corpus,
      .text_keyword_score_textprep,
      numeric(1),
      keywords = keywords
    )
    length_scores <- -abs(character_lengths - median_length)

    ranking <- data.frame(
      text = corpus,
      keyword_score = keyword_scores,
      length_score = length_scores,
      stringsAsFactors = FALSE
    )
    ranking <- ranking[
      order(-ranking$keyword_score, -ranking$length_score),
      ,
      drop = FALSE
    ]

    central <- utils::head(ranking$text, n_central)
    remainder <- setdiff(corpus, central)
    contrastive <- character(0)

    if (length(remainder) > 0 && n_tension > 0) {
      contrastive_ranking <- data.frame(
        text = remainder,
        keyword_score = vapply(
          remainder,
          .text_keyword_score_textprep,
          numeric(1),
          keywords = keywords
        ),
        lexical_distance = vapply(
          remainder,
          .lexical_distance_to_set_textprep,
          numeric(1),
          set_texts = central
        ),
        stringsAsFactors = FALSE
      )

      contrastive_ranking <- contrastive_ranking[
        order(
          contrastive_ranking$keyword_score,
          -contrastive_ranking$lexical_distance
        ),
        ,
        drop = FALSE
      ]

      contrastive <- utils::head(contrastive_ranking$text, n_tension)
    }

    central <- .truncate_verbatim_textprep(central, max_chars = max_chars)
    contrastive <- .truncate_verbatim_textprep(
      contrastive,
      max_chars = max_chars
    )

    out[[group_name]] <- list(
      central = central,
      contrastive = contrastive,
      # Backward-compatible alias. The selected texts are contrastive
      # candidates and are not evidence of a demonstrated internal tension.
      tension = contrastive
    )
  }

  out
}

# ---------------------------------------------------------------------------
# Structured prompt builders
# ---------------------------------------------------------------------------

build_request_textual_prep <- function(include_verbatims = TRUE,
                                       include_indicators = TRUE) {
  base <- c(
    "Using only the evidence below, produce a short structured summary of this group.",
    "",
    "The goal is to prepare a later comparison between:",
    "- what this group expresses in its texts,",
    "- which words statistically characterize this group relative to the other groups, when lexical indicators are supplied,",
    "- and how this group is characterized by external statistical descriptors in a later analysis.",
    "",
    "Interpretive rules:",
    "- Start from recurring themes before proposing a broader interpretation.",
    "- Treat individual phrases as illustrative evidence, not as standalone proof.",
    "- Treat recurring patterns as group-level textual evidence, not as properties shared by every individual.",
    "- Distinguish central themes from secondary or marginal elements.",
    "- Distinguish demonstrated internal tensions from isolated contrastive or atypical contributions.",
    "- Report an internal tension only when it is supported by several elements of the corpus.",
    "- A minority, atypical, or less central contribution may still be reported as a contrastive cue, but it must not be presented as proof of an internal contradiction.",
    "- Do not infer hidden motives, unexpressed intentions, deep personality traits, or moral qualities.",
    "- Summarize reasons only when they are explicitly expressed in the texts.",
    "- Do not treat the absence or under-representation of a word as proof that the group rejects or does not care about the corresponding topic.",
    "- Stay close to the texts."
  )

  if (include_indicators) {
    base <- c(
      base,
      "- Use mechanical indicators as supporting evidence, not as a substitute for reading the texts.",
      "- A statistically over-represented word is comparatively frequent in this group; it is not necessarily used by every individual and does not by itself define a theme.",
      "- Response length describes quantity of expression only and must not be interpreted as textual quality, richness, or evidential strength."
    )
  }

  base <- c(
    base,
    "- Use the exact output format below.",
    "",
    "Output format:",
    "Core textual profile:",
    "[One short sentence summarizing what mainly characterizes this group in the texts.]",
    "",
    "Main themes:",
    "[3 to 5 short themes separated by semicolons.]",
    "",
    "Dominant concerns or expressed reasons:",
    "[1 to 3 short phrases separated by semicolons. Include reasons only when they are explicitly expressed. If unclear, write: unclear]",
    "",
    "Tone or stance:",
    "[One short expression such as supportive / critical / ambivalent / pragmatic / engaged / hesitant / resigned / mixed]",
    "",
    "Intra-group consistency:",
    "[Choose exactly one: strong / moderate / mixed / weak, according to how consistently the main themes recur across the available texts.]",
    "",
    "Injectable summary:",
    "[One short sentence reusable later in a contextualized cross-group interpretation.]"
  )

  if (!include_verbatims) {
    return(paste(base, collapse = "\n"))
  }

  paste(
    c(
      base,
      "",
      "Central verbatim cues:",
      "[1 to 2 very short quoted excerpts or paraphrased cues separated by semicolons. Use them only as illustrative cues, not as proof.]",
      "",
      "Potential tension or contrastive verbatim cues:",
      "[0 to 2 very short quoted excerpts or paraphrased cues separated by semicolons. Retain a cue when the corpus contains a clearly minority, atypical, less central, or contrasting contribution. Describe it cautiously and do not treat it as proof of a contradiction. If no such contribution is identifiable, write: none]"
    ),
    collapse = "\n"
  )
}

build_conclusion_textual_prep <- function(include_verbatims = TRUE) {
  fields <- c(
    "Core textual profile:",
    "Main themes:",
    "Dominant concerns or expressed reasons:",
    "Tone or stance:",
    "Intra-group consistency:",
    "Injectable summary:"
  )

  if (include_verbatims) {
    fields <- c(
      fields,
      "Central verbatim cues:",
      "Potential tension or contrastive verbatim cues:"
    )
  }

  paste(
    c(
      "# Output constraint",
      "Your answer must contain exactly the following field labels and nothing else.",
      "Do not number the fields.",
      "Write each field label exactly as shown below:",
      fields
    ),
    collapse = "\n"
  )
}

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

.build_indicator_block_textprep <- function(group_name,
                                            corpus_metrics,
                                            lexical_profile,
                                            lexical_settings,
                                            sample.pct,
                                            max_terms = 8) {
  lines <- c(
    "## Mechanical corpus and lexical indicators",
    "The indicators in this section were calculated directly from the complete non-empty corpus, independently of the language model."
  )

  if (!is.null(corpus_metrics)) {
    lines <- c(
      lines,
      paste0(
        "Corpus volume for group '", group_name, "': ",
        corpus_metrics$n_texts, " non-empty texts out of ",
        corpus_metrics$n_rows, " rows (response rate = ",
        .format_number_textprep(100 * corpus_metrics$response_rate), "%); ",
        "median length = ",
        .format_number_textprep(corpus_metrics$median_characters),
        " characters and ",
        .format_number_textprep(corpus_metrics$median_words),
        " word-like tokens."
      )
    )
  }

  if (!is.null(lexical_profile)) {
    unit_label <- if (identical(lexical_profile$unit, "document")) {
      "number of individual texts containing each word"
    } else {
      "number of word occurrences"
    }

    lines <- c(
      lines,
      paste0(
        "Lexical unit used for the group-by-word table: ",
        unit_label,
        "."
      ),
      paste0(
        "Statistically over-represented words according to FactoMineR::descfreq() at p <= ",
        .format_number_textprep(lexical_settings$lexical_proba),
        ": ",
        .format_characteristic_terms_textprep(
          lexical_profile$overrepresented,
          max_terms = max_terms
        ),
        "."
      ),
      paste0(
        "Statistically under-represented words at the same threshold: ",
        .format_characteristic_terms_textprep(
          lexical_profile$underrepresented,
          max_terms = max_terms
        ),
        "."
      ),
      "These tests are exploratory and no multiple-testing adjustment has been applied."
    )
  }

  if (sample.pct < 1) {
    lines <- c(
      lines,
      "Important: the mechanical indicators use the complete corpus, whereas the raw texts displayed below are only a sample of that corpus."
    )
  }

  paste(lines, collapse = "\n")
}

.inject_indicator_block_textprep <- function(prompt, indicator_block) {
  if (is.null(indicator_block) || !nzchar(trimws(indicator_block))) {
    return(prompt)
  }

  marker <- "# Output constraint"
  marker_position <- regexpr(marker, prompt, fixed = TRUE)[1]

  if (marker_position < 0) {
    return(paste(prompt, indicator_block, sep = "\n\n"))
  }

  before <- substr(prompt, 1, marker_position - 1)
  after <- substr(prompt, marker_position, nchar(prompt))

  paste0(before, indicator_block, "\n\n", after)
}

# ---------------------------------------------------------------------------
# Structured response parser
# ---------------------------------------------------------------------------

.extract_field_block_textual <- function(text, field, next_fields = NULL) {
  escaped_field <- gsub(
    "([][{}()+*^$|\\\\?.])",
    "\\\\\\1",
    field
  )

  field_prefix <- "(?:(?:\\*\\*|__|#{1,6}|[-*+]|\\d+[.)])\\s*)*"

  if (is.null(next_fields) || length(next_fields) == 0) {
    pattern <- paste0(
      "(?is)",
      "(?:^|\\n)\\s*",
      field_prefix,
      escaped_field,
      "\\s*(?:\\*\\*|__)?\\s*:?\\s*\\n?",
      "(.*)$"
    )
  } else {
    escaped_next <- vapply(
      next_fields,
      function(x) {
        gsub(
          "([][{}()+*^$|\\\\?.])",
          "\\\\\\1",
          x
        )
      },
      character(1)
    )

    next_pattern <- paste(
      paste0(
        field_prefix,
        escaped_next,
        "\\s*(?:\\*\\*|__)?\\s*:?"
      ),
      collapse = "|"
    )

    pattern <- paste0(
      "(?is)",
      "(?:^|\\n)\\s*",
      field_prefix,
      escaped_field,
      "\\s*(?:\\*\\*|__)?\\s*:?\\s*\\n?",
      "(.*?)",
      "(?=\\n\\s*(?:", next_pattern, ")|$)"
    )
  }

  match_object <- regexec(pattern, text, perl = TRUE)
  matched_text <- regmatches(text, match_object)[[1]]

  if (length(matched_text) >= 2) {
    trimws(matched_text[2])
  } else {
    NA_character_
  }
}

.clean_field_textual <- function(x) {
  if (is.na(x) || !nzchar(trimws(x))) {
    return(NA_character_)
  }

  x <- trimws(x)
  x <- gsub("^[-*+]\\s*", "", x)
  x <- gsub("\\n+", " ", x)
  x <- gsub("[[:space:]]+", " ", x)
  trimws(x)
}

.split_field_textual <- function(x, none_words = NULL) {
  if (is.na(x) || !nzchar(trimws(x))) {
    return(character(0))
  }

  values <- unlist(strsplit(x, ";|\\n", perl = TRUE), use.names = FALSE)
  values <- trimws(values)
  values <- values[nzchar(values)]
  values <- gsub("^[-*+]\\s*", "", values)
  values <- gsub("^[[:punct:][:space:]]+", "", values)
  values <- gsub("[[:punct:][:space:]]+$", "", values)
  values <- trimws(values)
  values <- values[nzchar(values)]

  if (!is.null(none_words) && length(values) == 1 &&
      tolower(values) %in% tolower(none_words)) {
    return(character(0))
  }

  values
}

parse_textual_prep_response <- function(text, include_verbatims = TRUE) {
  text <- paste(text, collapse = "\n")
  text <- gsub("\r\n", "\n", text, fixed = TRUE)
  text <- gsub("\r", "\n", text, fixed = TRUE)
  text <- .strip_markdown_fences(text)

  text <- gsub(
    "(?im)^\\s*here is the output\\s*:?\\s*\\n?",
    "",
    text,
    perl = TRUE
  )
  text <- gsub(
    "(?im)^\\s*output\\s*:?\\s*\\n?",
    "",
    text,
    perl = TRUE
  )

  # Backward compatibility with former field labels.
  text <- gsub(
    "Dominant concerns or motives",
    "Dominant concerns or expressed reasons",
    text,
    ignore.case = TRUE
  )
  text <- gsub(
    "Tension verbatim cues",
    "Potential tension or contrastive verbatim cues",
    text,
    ignore.case = TRUE
  )

  field_order <- c(
    "Core textual profile",
    "Main themes",
    "Dominant concerns or expressed reasons",
    "Tone or stance",
    "Intra-group consistency",
    "Injectable summary"
  )

  if (include_verbatims) {
    field_order <- c(
      field_order,
      "Central verbatim cues",
      "Potential tension or contrastive verbatim cues"
    )
  }

  get_block <- function(field) {
    index <- match(field, field_order)
    next_fields <- if (index < length(field_order)) {
      field_order[(index + 1):length(field_order)]
    } else {
      NULL
    }

    .extract_field_block_textual(text, field, next_fields = next_fields)
  }

  core_textual_profile <- .clean_field_textual(
    get_block("Core textual profile")
  )
  main_themes_raw <- get_block("Main themes")
  dominant_concerns_raw <- get_block(
    "Dominant concerns or expressed reasons"
  )
  tone_or_stance_raw <- .clean_field_textual(get_block("Tone or stance"))
  intra_group_consistency_raw <- .clean_field_textual(
    get_block("Intra-group consistency")
  )
  injectable_summary <- .clean_field_textual(
    get_block("Injectable summary")
  )

  central_verbatim_cues_raw <- if (include_verbatims) {
    get_block("Central verbatim cues")
  } else {
    NA_character_
  }

  contrastive_verbatim_cues_raw <- if (include_verbatims) {
    get_block("Potential tension or contrastive verbatim cues")
  } else {
    NA_character_
  }

  main_themes <- .split_field_textual(main_themes_raw)
  dominant_concerns <- .split_field_textual(
    dominant_concerns_raw,
    none_words = c("unclear")
  )
  central_verbatim_cues <- .split_field_textual(
    central_verbatim_cues_raw
  )
  contrastive_verbatim_cues <- .split_field_textual(
    contrastive_verbatim_cues_raw,
    none_words = c("none")
  )
  tone_or_stance <- .split_field_textual(tone_or_stance_raw)

  normalize_consistency <- function(x) {
    if (is.na(x) || !nzchar(trimws(x))) {
      return(NA_character_)
    }

    x_lower <- tolower(trimws(x))

    if (grepl("\\bstrong\\b", x_lower)) return("strong")
    if (grepl("\\bmoderate\\b|\\bmedium\\b", x_lower)) return("moderate")
    if (grepl("\\bmixed\\b", x_lower)) return("mixed")
    if (grepl("\\bweak\\b", x_lower)) return("weak")

    NA_character_
  }

  list(
    core_textual_profile = core_textual_profile,
    main_themes = main_themes,
    dominant_concerns = dominant_concerns,
    tone_or_stance = tone_or_stance,
    intra_group_consistency = normalize_consistency(
      intra_group_consistency_raw
    ),
    intra_group_consistency_raw = intra_group_consistency_raw,
    injectable_summary = injectable_summary,
    central_verbatim_cues = central_verbatim_cues,
    contrastive_verbatim_cues = contrastive_verbatim_cues,
    # Backward-compatible alias.
    tension_verbatim_cues = contrastive_verbatim_cues
  )
}

# ---------------------------------------------------------------------------
# Main function
# ---------------------------------------------------------------------------

#' Prepare structured textual profiles and statistical lexical indicators
#'
#' Builds one structured textual profile for each level of a grouping variable.
#' The function combines three complementary layers of evidence:
#'
#' 1. a language-model synthesis of the raw texts;
#' 2. explicit corpus-volume and response-length indicators;
#' 3. a statistical lexical characterization based on a group-by-word
#'    contingency table and [FactoMineR::descfreq()].
#'
#' The output is intended for later triangulation with a statistical group
#' profile in [nail_textual_contextualized()]. The function does not collapse
#' these different layers into a single score, because response quantity,
#' lexical specificity, internal diversity, and semantic interpretation do not
#' measure the same construct.
#'
#' @param dataset A data frame containing a grouping variable and an
#'   open-ended textual variable. Rows generally correspond to individuals,
#'   observations, or textual contributions.
#' @param num.var A single integer giving the column index of the grouping
#'   variable in `dataset`.
#' @param num.text A single integer giving the column index of the textual
#'   variable in `dataset`. `num.var` and `num.text` must be different.
#' @param model Character string giving the model used by the selected LLM
#'   provider. The default is `"llama3"`.
#' @param provider LLM backend used when `generate = TRUE`. One of
#'   `"ollama"` or `"gemini"`.
#' @param sample.pct Numeric value in ]0, 1] giving the proportion of non-empty
#'   texts shown to the LLM within each group. Statistical indicators are
#'   always calculated from the complete non-empty corpus.
#' @param seed Optional seed controlling only within-group text sampling.
#' @param language Language used for the basic stopword list in the mechanical
#'   lexical analysis. One of `"en"`, `"fr"`, or `"none"`. This argument
#'   does not translate the texts or control the language of the LLM response.
#' @param prompt_style Prompt style passed to [nail_textual()]. One of
#'   `"detailed"` or `"compact"`.
#' @param text_role Name used for textual units in the prompt. One of
#'   `"responses"`, `"comments"`, or `"verbatims"`.
#' @param include_verbatims_in_prompt Logical indicating whether the LLM should
#'   return central and contrastive verbatim cues.
#' @param attach_selected_verbatims Logical indicating whether verbatims should
#'   also be selected mechanically from the original corpus after generation.
#' @param n_central_verbatims Maximum number of mechanically selected central
#'   verbatims per group.
#' @param n_tension_verbatims Maximum number of mechanically selected
#'   contrastive verbatims per group. The historical argument name is retained
#'   for compatibility; these texts are not evidence of a demonstrated
#'   internal tension.
#' @param max_verbatim_chars Maximum number of characters retained for each
#'   mechanically selected verbatim.
#' @param lexical_analysis Logical indicating whether to build a group-by-word
#'   table and run [FactoMineR::descfreq()].
#' @param lexical_unit Unit used in the group-by-word table passed to
#'   [FactoMineR::descfreq()]. One of:
#'
#'   - `"occurrence"`: each cell is the total number of occurrences of a word
#'     in the group;
#'   - `"document"`: each cell is the number of individual texts in the group
#'     containing the word at least once.
#'
#'   The document-based option limits the influence of highly verbose
#'   individuals, whereas the occurrence-based option describes the complete
#'   lexical mass of each group.
#'   This argument controls the contingency table passed to `descfreq()` and
#'   the global group-by-word association analysis.
#'
#'   It does not change the lexical diversity indicators stored in
#'   `lexical_profile$occurrence_metrics`. These indicators are always
#'   calculated from the retained word-occurrence table.
#'
#' @param lexical_proba Significance threshold passed to
#'   [FactoMineR::descfreq()]. No multiple-testing adjustment is added by this
#'   function; lexical markers should therefore be treated as exploratory.
#' @param min_word_frequency Minimum global frequency required for a word to be
#'   retained in the lexical contingency table. With `lexical_unit =
#'   "document"`, this is a minimum number of texts containing the word.
#' @param min_word_length Minimum number of characters required for a word to
#'   be retained after tokenization.
#' @param top_n_characteristic_words Maximum number of over-represented and
#'   under-represented words retained per group from `descfreq()`.
#' @param top_n_frequent_terms Number of simple frequency-ranked terms returned
#'   per group. These terms are not necessarily statistically characteristic.
#' @param include_indicators_in_prompt Logical indicating whether group-specific
#'   corpus metrics and lexical markers should be inserted into the prompt.
#'   This gives the isolated LLM prompt comparative lexical evidence even
#'   though the raw texts of the other groups are not displayed.
#' @param compute_length_analysis Logical indicating whether to analyse the
#'   association between group membership and response length. The outcome is
#'   `log1p(number of characters)`. The returned analysis includes classical
#'   ANOVA, Welch's test, eta-squared, and omega-squared.
#' @param generate Logical. If `FALSE`, the enriched prompts and mechanical
#'   indicators are returned without calling an LLM. If `TRUE`, one request is
#'   sent independently for each group and the responses are parsed.
#' @param ... Additional provider-specific arguments passed to the selected LLM
#'   backend.
#'
#' @details
#' ## Separation from `nail_textual()`
#'
#' `nail_textual()` remains the general-purpose function for free narrative
#' interpretation of grouped texts. `nail_textual_prep()` is a preparation
#' function: it creates a stable, parseable object intended for reuse by a
#' later workflow.
#'
#' Internally, `nail_textual_prep()` first calls [nail_textual()] with
#' `isolate.groups = TRUE` and `generate = FALSE` to construct one base prompt
#' per group. It then adds group-specific mechanical indicators and performs
#' generation itself when requested.
#'
#' ## Corpus metrics
#'
#' For each group, `corpus_metrics` reports explicit quantities rather than an
#' undocumented `evidence_strength` label:
#'
#' - number of rows and number of non-empty texts;
#' - response rate;
#' - total, mean, median, interquartile range, minimum, and maximum numbers of
#'   characters;
#' - the same descriptive indicators for word-like tokens.
#'
#' These metrics describe corpus volume only. They do not measure quality,
#' richness, representativeness, validity, or saturation.
#'
#' ## Response-length group effect
#'
#' When `compute_length_analysis = TRUE`, a one-way model is fitted to
#' `log1p(number of characters)`. The analysis reports:
#'
#' - the classical ANOVA F-test;
#' - Welch's heteroscedastic one-way test;
#' - eta-squared and omega-squared effect sizes;
#' - group-level descriptive statistics.
#'
#' This analysis answers whether groups differ in quantity of expression. It
#' must not be interpreted as a test of textual content or quality.
#'
#' ## Statistical lexical profile
#'
#' The occurrence table is constructed with [FactoMineR::textual()]. After
#' stopword, length, and global-frequency filtering, the selected contingency
#' table is analysed with [FactoMineR::descfreq()]. For each group, the function
#' separates:
#'
#' - over-represented words, which occur comparatively more often than in the
#'   complete corpus;
#' - under-represented words, which occur comparatively less often.
#'
#' A characteristic word is a comparative lexical marker. It is not
#' necessarily used by every individual, it is not by itself a complete theme,
#' and its absence must not be interpreted as rejection of the corresponding
#' topic.
#'
#' The complete lexical analysis also reports a global chi-square association,
#' total correspondence-analysis inertia, Cramer's V, and expected-count
#' diagnostics. The asymptotic p-value may be unreliable when the word table is
#' sparse; the diagnostics are returned so that this limitation remains
#' visible.
#'
#' ## Occurrence-based lexical indicators
#'
#' Independently of `lexical_unit`, the function calculates several
#' descriptive indicators from the retained group-by-word occurrence table.
#'
#' These indicators are stored in:
#'
#' ```
#' lexical_profile$occurrence_metrics
#' ```
#'
#' They include:
#'
#' - `total_retained_word_occurrences`: total number of retained word
#'   occurrences after stopword, word-length, and frequency filtering;
#' - `retained_vocabulary_size`: number of retained distinct word forms;
#' - `type_token_ratio`: ratio between retained vocabulary size and retained
#'   word occurrences;
#' - `shannon_entropy`: entropy of the retained word-frequency distribution;
#' - `normalized_shannon_entropy`: Shannon entropy divided by its theoretical
#'   maximum for the retained vocabulary.
#'
#' These indicators are always calculated from word occurrences, including
#' when `lexical_unit = "document"`. In that case, the document-frequency
#' table is used for `descfreq()`, whereas the occurrence table is used for
#' these descriptive indicators.
#'
#' The word `retained` is important: these quantities concern only terms that
#' remain after lexical filtering. They are therefore different from the
#' unfiltered word counts reported in `corpus_metrics`.
#'
#' The type-token ratio and entropy depend on corpus size and preprocessing.
#' They must not be interpreted as intrinsic measures of intellectual,
#' linguistic, or evidential quality.
#'
#' ## LLM and mechanical evidence
#'
#' The parsed LLM response contains a core textual profile, main themes,
#' expressed concerns or reasons, tone or stance, intra-group consistency, and
#' an injectable summary. Optional LLM verbatim cues may be paraphrased.
#'
#' Mechanically selected verbatims are taken directly from the original corpus.
#' Central selection uses both the parsed themes and statistically
#' over-represented words. Contrastive selection favors texts that are less
#' aligned with the central keywords and lexically more distant from the
#' selected central texts.
#'
#' Neither procedure demonstrates that a text is representative of every group
#' member or that a contrastive text constitutes an internal contradiction.
#'
#' ## Sampling
#'
#' `sample.pct` affects only the texts displayed to the LLM. Corpus metrics,
#' lexical tables, `descfreq()` results, frequent terms, and mechanically
#' selected verbatims are calculated from the complete available corpus. The
#' prompt states this explicitly when sampling is used.
#'
#' @return
#' With `generate = FALSE`, a named list of enriched character prompts is
#' returned. With `generate = TRUE`, a named list is returned with one element
#' per group. Each group element contains:
#'
#' - `prompt`: exact prompt sent to the LLM;
#' - `response`: raw LLM response;
#' - `parsed`: structured fields extracted from the response;
#' - `corpus_metrics`: explicit group-level corpus indicators;
#' - `lexical_profile`: the lexical analysis unit, over-represented and
#'   under-represented words, marker counts, and occurrence-based descriptive
#'   indicators;
#' - `selected_verbatims`: `central`, `contrastive`, and the backward-compatible
#'   alias `tension`;
#' - `frequent_terms`: most frequent filtered terms;
#' - `notable_expressions`: backward-compatible alias of `frequent_terms`.
#'
#' The complete returned object has the following attributes:
#'
#' - `corpus_metrics`;
#' - `length_group_analysis`;
#' - `lexical_analysis`, containing the contingency tables, raw
#'   [FactoMineR::descfreq()] result, group lexical profiles, global association,
#'   and analysis settings;
#' - `textual_data_summary`, inherited from [nail_textual()] for backward
#'   compatibility.
#'
#' @seealso [nail_textual()], [nail_textual_contextualized()],
#'   [FactoMineR::textual()], [FactoMineR::descfreq()]
#'
#' @export
#'
#' @examples
#' textual_example <- data.frame(
#'   group = factor(c(
#'     rep("Local orientation", 4),
#'     rep("Convenience orientation", 4)
#'   )),
#'   response = c(
#'     "I prefer the local market and seasonal products.",
#'     "Buying directly from nearby producers matters to me.",
#'     "I try to support local shops and regional food.",
#'     "Knowing where products come from is important.",
#'     "Shopping must be fast and easy after work.",
#'     "The supermarket is practical because everything is available.",
#'     "Opening hours and convenience guide my choices.",
#'     "I use the drive service because it saves time."
#'   ),
#'   stringsAsFactors = FALSE
#' )
#'
#' prep_prompts <- nail_textual_prep(
#'   textual_example,
#'   num.var = 1,
#'   num.text = 2,
#'   language = "en",
#'   lexical_unit = "document",
#'   min_word_frequency = 1,
#'   generate = FALSE
#' )
#'
#' names(prep_prompts)
#' attr(prep_prompts, "corpus_metrics")
#' attr(prep_prompts, "length_group_analysis")
#' attr(prep_prompts, "lexical_analysis")$group_profiles
#'
#' \dontrun{
#' textual_result <- nail_textual_prep(
#'   textual_example,
#'   num.var = 1,
#'   num.text = 2,
#'   model = "llama3",
#'   provider = "ollama",
#'   language = "en",
#'   lexical_unit = "document",
#'   min_word_frequency = 1,
#'   generate = TRUE
#' )
#'
#' textual_result[["Local orientation"]]$parsed
#' textual_result[["Local orientation"]]$lexical_profile
#' textual_result[["Local orientation"]]$selected_verbatims
#' }
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
                              ...) {
  prompt_style <- match.arg(prompt_style)
  text_role <- match.arg(text_role)
  language <- match.arg(language)
  provider <- match.arg(provider)
  lexical_unit <- match.arg(lexical_unit)

  .validate_textual_prep_options(
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
    compute_length_analysis = compute_length_analysis
  )

  intro <- paste(
    "The texts below come from one specific group.",
    "The goal is to summarize this group's textual profile in a short structured format that can later be combined with external statistical descriptors."
  )

  request <- build_request_textual_prep(
    include_verbatims = include_verbatims_in_prompt,
    include_indicators = include_indicators_in_prompt
  )
  conclusion <- build_conclusion_textual_prep(
    include_verbatims = include_verbatims_in_prompt
  )

  # Prompt construction and validation are delegated to nail_textual().
  base_prompts <- nail_textual(
    dataset = dataset,
    num.var = num.var,
    num.text = num.text,
    introduction = intro,
    request = request,
    conclusion = conclusion,
    model = model,
    provider = provider,
    isolate.groups = TRUE,
    sample.pct = sample.pct,
    seed = seed,
    prompt_style = prompt_style,
    text_role = text_role,
    generate = FALSE
  )

  corpus_metrics <- .compute_corpus_metrics_textprep(
    dataset = dataset,
    num.var = num.var,
    num.text = num.text
  )

  length_group_analysis <- if (compute_length_analysis) {
    .compute_length_group_analysis_textprep(
      dataset = dataset,
      num.var = num.var,
      num.text = num.text
    )
  } else {
    .empty_length_analysis_textprep(
      "The analysis was disabled by `compute_length_analysis = FALSE`."
    )
  }

  lexical_results <- if (lexical_analysis) {
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
    )
  } else {
    list(
      settings = list(
        lexical_unit = lexical_unit,
        language = language,
        lexical_proba = lexical_proba,
        min_word_frequency = min_word_frequency,
        min_word_length = min_word_length,
        top_n_characteristic_words = top_n_characteristic_words,
        multiple_testing_adjustment = "none",
        disabled = TRUE
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

  frequent_terms <- .extract_frequent_terms_textprep(
    dataset = dataset,
    num.var = num.var,
    num.text = num.text,
    top_n = top_n_frequent_terms,
    min_word_length = min_word_length,
    language = language
  )

  enriched_prompts <- base_prompts

  if (include_indicators_in_prompt) {
    for (group_name in names(enriched_prompts)) {
      group_lexical_profile <- if (
        group_name %in% names(lexical_results$group_profiles)
      ) {
        lexical_results$group_profiles[[group_name]]
      } else {
        NULL
      }

      indicator_block <- .build_indicator_block_textprep(
        group_name = group_name,
        corpus_metrics = corpus_metrics[[group_name]],
        lexical_profile = group_lexical_profile,
        lexical_settings = lexical_results$settings,
        sample.pct = sample.pct,
        max_terms = top_n_characteristic_words
      )

      enriched_prompts[[group_name]] <- .inject_indicator_block_textprep(
        enriched_prompts[[group_name]],
        indicator_block
      )
    }
  }

  attach_result_attributes <- function(x) {
    attr(x, "corpus_metrics") <- corpus_metrics
    attr(x, "length_group_analysis") <- length_group_analysis
    attr(x, "lexical_analysis") <- lexical_results
    class(x) <- unique(c("nail_textual_prep", class(x)))
    x
  }

  if (!generate) {
    return(attach_result_attributes(enriched_prompts))
  }

  llm_api_options <- list(...)

  generated_results <- lapply(enriched_prompts, function(prompt) {
    result <- .call_llm_base(
      provider = provider,
      model = model,
      prompt = prompt,
      output = "df",
      llm_api_options = llm_api_options
    )
    result$prompt <- prompt
    result
  })
  names(generated_results) <- names(enriched_prompts)

  parsed_only <- lapply(generated_results, function(x) {
    response_text <- if (!is.null(x$response)) {
      paste(x$response, collapse = "\n")
    } else {
      ""
    }

    tryCatch(
      parse_textual_prep_response(
        response_text,
        include_verbatims = include_verbatims_in_prompt
      ),
      error = function(e) .empty_parsed_textprep()
    )
  })
  names(parsed_only) <- names(generated_results)

  selected_verbatims <- if (attach_selected_verbatims) {
    .select_representative_verbatims_textprep(
      dataset = dataset,
      num.var = num.var,
      num.text = num.text,
      textual_summary = parsed_only,
      lexical_profiles = lexical_results$group_profiles,
      n_central = n_central_verbatims,
      n_tension = n_tension_verbatims,
      max_chars = max_verbatim_chars
    )
  } else {
    stats::setNames(
      lapply(seq_along(parsed_only), function(i) {
        list(
          central = character(0),
          contrastive = character(0),
          tension = character(0)
        )
      }),
      names(parsed_only)
    )
  }

  out <- lapply(names(generated_results), function(group_name) {
    generated <- generated_results[[group_name]]
    response_text <- if (!is.null(generated$response)) {
      paste(generated$response, collapse = "\n")
    } else {
      ""
    }

    lexical_profile <- if (
      group_name %in% names(lexical_results$group_profiles)
    ) {
      lexical_results$group_profiles[[group_name]]
    } else {
      .empty_lexical_profile_textprep(unit = lexical_unit)
    }

    terms <- if (group_name %in% names(frequent_terms)) {
      frequent_terms[[group_name]]
    } else {
      character(0)
    }

    list(
      prompt = enriched_prompts[[group_name]],
      response = response_text,
      parsed = parsed_only[[group_name]],
      corpus_metrics = corpus_metrics[[group_name]],
      lexical_profile = lexical_profile,
      selected_verbatims = selected_verbatims[[group_name]],
      frequent_terms = terms,
      # Backward-compatible alias.
      notable_expressions = terms
    )
  })

  names(out) <- names(generated_results)
  attach_result_attributes(out)
}
