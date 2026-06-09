# ============================================================
# Diagnostics for textual pipeline volume
# ============================================================

# Helpers -----------------------------------------------------

.count_words_simple <- function(x) {
  x <- paste(x, collapse = " ")
  x <- gsub("[[:space:]]+", " ", x)
  x <- trimws(x)
  if (!nzchar(x)) return(0L)
  length(strsplit(x, " ", fixed = TRUE)[[1]])
}

.safe_nchar <- function(x) {
  if (is.null(x)) return(0L)
  nchar(paste(x, collapse = "\n"), type = "chars", allowNA = FALSE)
}

.safe_words <- function(x) {
  if (is.null(x)) return(0L)
  .count_words_simple(paste(x, collapse = "\n"))
}

.extract_nonempty_texts_diag <- function(x) {
  x <- as.character(x)
  x[is.na(x)] <- ""
  x <- trimws(x)
  x[nzchar(x)]
}

# ------------------------------------------------------------
# 1. Raw corpus volume by group
# ------------------------------------------------------------

diagnose_textual_input_volume <- function(dataset, num.var, num.text) {
  var_name <- colnames(dataset)[num.var]
  text_name <- colnames(dataset)[num.text]

  grp <- dataset[[var_name]]
  if (!is.factor(grp)) grp <- as.factor(grp)

  split_data <- split(dataset, grp)

  res <- lapply(names(split_data), function(g) {
    corpus <- .extract_nonempty_texts_diag(split_data[[g]][[text_name]])
    chars_each <- nchar(corpus)
    words_each <- vapply(corpus, .count_words_simple, integer(1))

    data.frame(
      group = g,
      n_texts = length(corpus),
      total_chars = sum(chars_each),
      total_words = sum(words_each),
      mean_chars = if (length(chars_each) > 0) mean(chars_each) else NA_real_,
      median_chars = if (length(chars_each) > 0) stats::median(chars_each) else NA_real_,
      max_chars = if (length(chars_each) > 0) max(chars_each) else NA_real_,
      mean_words = if (length(words_each) > 0) mean(words_each) else NA_real_,
      median_words = if (length(words_each) > 0) stats::median(words_each) else NA_real_,
      max_words = if (length(words_each) > 0) max(words_each) else NA_real_,
      stringsAsFactors = FALSE
    )
  })

  do.call(rbind, res)
}

# ------------------------------------------------------------
# 2. Prompt volume for nail_textual()
# ------------------------------------------------------------

diagnose_textual_prompt_volume <- function(dataset, num.var, num.text,
                                           sample.pct = 1,
                                           prompt_style = "detailed",
                                           text_role = "responses",
                                           isolate.groups = TRUE) {
  prompts <- nail_textual(
    dataset = dataset,
    num.var = num.var,
    num.text = num.text,
    sample.pct = sample.pct,
    prompt_style = prompt_style,
    text_role = text_role,
    isolate.groups = isolate.groups,
    generate = FALSE
  )

  if (!isolate.groups) {
    return(data.frame(
      group = "ALL",
      prompt_chars = .safe_nchar(prompts),
      prompt_words = .safe_words(prompts),
      stringsAsFactors = FALSE
    ))
  }

  out <- lapply(names(prompts), function(g) {
    p <- prompts[[g]]
    data.frame(
      group = g,
      prompt_chars = .safe_nchar(p),
      prompt_words = .safe_words(p),
      stringsAsFactors = FALSE
    )
  })

  do.call(rbind, out)
}

# ------------------------------------------------------------
# 3. Prompt + response volume for nail_textual_prep()
# ------------------------------------------------------------

diagnose_textual_prep_volume <- function(dataset, num.var, num.text,
                                         model = "llama3",
                                         sample.pct = 1,
                                         prompt_style = "detailed",
                                         text_role = "responses",
                                         include_verbatims_in_prompt = TRUE,
                                         attach_selected_verbatims = TRUE,
                                         generate = TRUE,
                                         ...) {
  res <- nail_textual_prep(
    dataset = dataset,
    num.var = num.var,
    num.text = num.text,
    model = model,
    sample.pct = sample.pct,
    prompt_style = prompt_style,
    text_role = text_role,
    include_verbatims_in_prompt = include_verbatims_in_prompt,
    attach_selected_verbatims = attach_selected_verbatims,
    generate = generate,
    ...
  )

  out <- lapply(names(res), function(g) {
    x <- res[[g]]

    central_selected <- if (!is.null(x$selected_verbatims$central)) x$selected_verbatims$central else character(0)
    tension_selected <- if (!is.null(x$selected_verbatims$tension)) x$selected_verbatims$tension else character(0)

    data.frame(
      group = g,
      prompt_chars = .safe_nchar(x$prompt),
      prompt_words = .safe_words(x$prompt),
      response_chars = .safe_nchar(x$response),
      response_words = .safe_words(x$response),
      parsed_main_themes_n = if (!is.null(x$parsed$main_themes)) length(x$parsed$main_themes) else 0L,
      parsed_dominant_concerns_n = if (!is.null(x$parsed$dominant_concerns)) length(x$parsed$dominant_concerns) else 0L,
      parsed_central_cues_n = if (!is.null(x$parsed$central_verbatim_cues)) length(x$parsed$central_verbatim_cues) else 0L,
      parsed_tension_cues_n = if (!is.null(x$parsed$tension_verbatim_cues)) length(x$parsed$tension_verbatim_cues) else 0L,
      selected_central_n = length(central_selected),
      selected_tension_n = length(tension_selected),
      selected_verbatims_chars = .safe_nchar(c(central_selected, tension_selected)),
      injectable_summary_chars = .safe_nchar(x$parsed$injectable_summary),
      stringsAsFactors = FALSE
    )
  })

  do.call(rbind, out)
}

# ------------------------------------------------------------
# 4. Reduction ratio: raw corpus -> prep output
# ------------------------------------------------------------

diagnose_textual_reduction <- function(dataset, num.var, num.text,
                                       model = "llama3",
                                       sample.pct = 1,
                                       prompt_style = "detailed",
                                       text_role = "responses",
                                       ...) {
  raw_vol <- diagnose_textual_input_volume(dataset, num.var, num.text)
  prep_vol <- diagnose_textual_prep_volume(
    dataset = dataset,
    num.var = num.var,
    num.text = num.text,
    model = model,
    sample.pct = sample.pct,
    prompt_style = prompt_style,
    text_role = text_role,
    generate = TRUE,
    ...
  )

  merged <- merge(raw_vol, prep_vol, by = "group", all.x = TRUE)

  merged$raw_to_prompt_ratio_chars <- merged$total_chars / pmax(merged$prompt_chars, 1)
  merged$raw_to_response_ratio_chars <- merged$total_chars / pmax(merged$response_chars, 1)
  merged$raw_to_summary_ratio_chars <- merged$total_chars / pmax(merged$injectable_summary_chars, 1)

  merged$raw_to_prompt_ratio_words <- merged$total_words / pmax(merged$prompt_words, 1)
  merged$raw_to_response_ratio_words <- merged$total_words / pmax(merged$response_words, 1)

  merged
}

# ------------------------------------------------------------
# 5. Compare several sample.pct values
# ------------------------------------------------------------

benchmark_textual_sampling <- function(dataset, num.var, num.text,
                                       sample_grid = c(1, 0.75, 0.5, 0.33, 0.25, 0.2),
                                       prompt_style = "detailed",
                                       text_role = "responses",
                                       isolate.groups = TRUE) {
  out <- lapply(sample_grid, function(sp) {
    vol <- diagnose_textual_prompt_volume(
      dataset = dataset,
      num.var = num.var,
      num.text = num.text,
      sample.pct = sp,
      prompt_style = prompt_style,
      text_role = text_role,
      isolate.groups = isolate.groups
    )
    vol$sample_pct <- sp
    vol
  })

  do.call(rbind, out)
}

# ------------------------------------------------------------
# 6. Heuristic flagging: when should you chunk?
# ------------------------------------------------------------

flag_textual_overload <- function(prompt_volume_df,
                                  prompt_char_threshold = 12000,
                                  prompt_word_threshold = 2500) {
  df <- prompt_volume_df

  df$flag_large_prompt <- with(
    df,
    prompt_chars >= prompt_char_threshold | prompt_words >= prompt_word_threshold
  )

  df$recommended_strategy <- ifelse(
    df$flag_large_prompt,
    "chunk_or_sample",
    "direct_pass"
  )

  df
}

# ------------------------------------------------------------
# 7. Chunking simulator
# ------------------------------------------------------------

simulate_text_chunks <- function(dataset, num.var, num.text,
                                 chunk_size = 20,
                                 max_chars_per_chunk = NULL) {
  var_name <- colnames(dataset)[num.var]
  text_name <- colnames(dataset)[num.text]

  grp <- dataset[[var_name]]
  if (!is.factor(grp)) grp <- as.factor(grp)

  split_data <- split(dataset, grp)

  out <- list()

  for (g in names(split_data)) {
    corpus <- .extract_nonempty_texts_diag(split_data[[g]][[text_name]])

    if (length(corpus) == 0) {
      out[[g]] <- data.frame(
        group = g,
        chunk_id = integer(0),
        n_texts = integer(0),
        total_chars = integer(0),
        total_words = integer(0)
      )
      next
    }

    # Basic chunking by fixed number of texts
    idx <- ceiling(seq_along(corpus) / chunk_size)
    chunks <- split(corpus, idx)

    # Optional second pass: split chunks further if max_chars_per_chunk exceeded
    if (!is.null(max_chars_per_chunk)) {
      chunks2 <- list()
      current <- character(0)
      chunk_counter <- 1

      for (txt in corpus) {
        candidate <- c(current, txt)
        if (.safe_nchar(candidate) > max_chars_per_chunk && length(current) > 0) {
          chunks2[[as.character(chunk_counter)]] <- current
          chunk_counter <- chunk_counter + 1
          current <- txt
        } else {
          current <- candidate
        }
      }

      if (length(current) > 0) {
        chunks2[[as.character(chunk_counter)]] <- current
      }

      chunks <- chunks2
    }

    chunk_df <- lapply(seq_along(chunks), function(i) {
      ch <- chunks[[i]]
      data.frame(
        group = g,
        chunk_id = i,
        n_texts = length(ch),
        total_chars = .safe_nchar(ch),
        total_words = .safe_words(ch),
        stringsAsFactors = FALSE
      )
    })

    out[[g]] <- do.call(rbind, chunk_df)
  }

  do.call(rbind, out)
}

# ------------------------------------------------------------
# 8. Master diagnostic
# ------------------------------------------------------------

run_textual_volume_diagnostics <- function(dataset, num.var, num.text,
                                           model = "llama3",
                                           sample_grid = c(1, 0.5, 0.33, 0.25),
                                           prompt_style = "detailed",
                                           text_role = "responses") {
  raw_input <- diagnose_textual_input_volume(dataset, num.var, num.text)

  prompts_full <- diagnose_textual_prompt_volume(
    dataset = dataset,
    num.var = num.var,
    num.text = num.text,
    sample.pct = 1,
    prompt_style = prompt_style,
    text_role = text_role,
    isolate.groups = TRUE
  )

  prompts_sampling <- benchmark_textual_sampling(
    dataset = dataset,
    num.var = num.var,
    num.text = num.text,
    sample_grid = sample_grid,
    prompt_style = prompt_style,
    text_role = text_role,
    isolate.groups = TRUE
  )

  overload_flags <- flag_textual_overload(prompts_full)

  list(
    raw_input = raw_input,
    prompts_full = prompts_full,
    prompts_sampling = prompts_sampling,
    overload_flags = overload_flags
  )
}
