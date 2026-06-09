#' @importFrom stringr str_replace_all str_squish str_split_fixed
#' @importFrom tibble rownames_to_column
#' @importFrom dplyr mutate across where
#' @noRd
parse_factominer_rownames <- function(text) {
  # This helper function parses complex rownames from FactoMineR
  # e.g., "var.name=modality_one" or "quantitative.var"
  # It returns a list with two elements: Variable and Modalite.

  # Split into max 2 parts at the first '='
  # 'n = 2' ensures that any '=' in the modality name is kept
  parts <- stringr::str_split_fixed(text, "=", n = 2)

  # Clean the variable name (part 1)
  # Replace all dots with spaces and trim whitespace
  var_name <- stringr::str_replace_all(parts[1, 1], "\\.", " ")
  var_name <- stringr::str_squish(var_name)

  mod_name <- NA_character_

  if (nzchar(parts[1, 2])) {
    # A modality exists (part 2)
    # Replace all dots and underscores with spaces and trim
    mod_name <- stringr::str_replace_all(parts[1, 2], "[\\._]", " ")
    mod_name <- stringr::str_squish(mod_name)
  }

  return(list(Variable = var_name, Modalite = mod_name))
}


#' @importFrom tibble rownames_to_column
#' @importFrom dplyr mutate across where
#' @noRd
format_stats_as_markdown <- function(
    df_stats,
    title = "Statistical Results",
    round_digits = 2
) {

  if (is.null(df_stats) || nrow(df_stats) == 0) {
    return(paste0("### ", title, "\n\n*No significant data to display.*\n"))
  }

  df_proc <- df_stats |>
    tibble::rownames_to_column(var = "RawItem")

  parsed_cols <- do.call(rbind, lapply(df_proc$RawItem, parse_factominer_rownames))
  df_proc <- cbind(as.data.frame(parsed_cols), df_proc)

  stat_cols <- colnames(df_stats)

  for (j in stat_cols) {
    if (is.numeric(df_proc[[j]])) {
      if (grepl("p.value", j, fixed = TRUE)) {
        df_proc[[j]] <- ifelse(
          df_proc[[j]] < 0.001,
          "<0.001",
          format(round(df_proc[[j]], 3), nsmall = 3)
        )
      } else {
        df_proc[[j]] <- format(round(df_proc[[j]], round_digits), nsmall = round_digits)
      }
    }
  }

  if (all(is.na(df_proc$Modalite))) {
    df_final <- df_proc[, c("Variable", stat_cols), drop = FALSE]
  } else {
    df_final <- df_proc[, c("Variable", "Modalite", stat_cols), drop = FALSE]
    df_final$Modalite[is.na(df_final$Modalite)] <- "-"
  }

  header <- paste("|", paste(colnames(df_final), collapse = " | "), "|")
  separator <- paste("|", paste(rep("---", ncol(df_final)), collapse = " | "), "|")

  rows <- apply(df_final, 1, function(row) {
    row[is.na(row)] <- "NA"
    paste("|", paste(row, collapse = " | "), "|")
  })

  md_table <- paste(
    header,
    separator,
    paste(rows, collapse = "\n"),
    sep = "\n"
  )

  return(paste0("### ", title, "\n\n", md_table, "\n"))
}
# ---------------------------------------------------------------------------
# sample_numeric_distribution
# ---------------------------------------------------------------------------
#' @importFrom tibble rownames_to_column column_to_rownames
#' @importFrom dplyr slice_sample group_by
#' @importFrom stats quantile
#' @importFrom rlang sym
#' @importFrom rlang .data
sample_numeric_distribution <- function(data,
                                        num_var_index,
                                        sample_pct,
                                        method = "stratified",
                                        bins = 5,
                                        return_matrix = TRUE,
                                        seed = NULL) {
  assert_data_frame(data, "data")
  assert_column_index(num_var_index, ncol(data), "num_var_index")
  assert_proportion(sample_pct, "sample_pct")
  assert_positive_integerish(bins, "bins")

  num_var <- colnames(data)[num_var_index]

  if (!is.numeric(data[[num_var]])) {
    stop("The selected column is not numeric.", call. = FALSE)
  }

  sampled_data <- .with_preserved_seed(seed, {
    data_work <- tibble::rownames_to_column(data, var = "OriginalRowName")
    sample_size <- min(nrow(data_work), max(1, round(nrow(data_work) * sample_pct)))

    if (method == "probability") {
      prob <- data_work[[num_var]] - min(data_work[[num_var]], na.rm = TRUE) + 1
      prob[is.na(prob)] <- 0
      if (sum(prob, na.rm = TRUE) <= 0) {
        prob <- rep(1, nrow(data_work))
      }
      prob <- prob / sum(prob, na.rm = TRUE)
      data_work[sample(seq_len(nrow(data_work)), size = sample_size, prob = prob, replace = FALSE), , drop = FALSE]

    } else if (method == "stratified") {
      n_unique <- length(unique(stats::na.omit(data_work[[num_var]])))
      bins_eff <- min(bins, max(1, n_unique - 1))

      if (bins_eff < 1 || n_unique < 2) {
        warning("Not enough unique values for stratified sampling. Defaulting to random sampling.", call. = FALSE)
        data_work[sample(seq_len(nrow(data_work)), size = sample_size, replace = FALSE), , drop = FALSE]
      } else {
        breaks <- unique(stats::quantile(
          data_work[[num_var]],
          probs = seq(0, 1, length.out = bins_eff + 1),
          na.rm = TRUE
        ))

        if (length(breaks) <= 1) {
          warning("Insufficient variation in data. Using random sampling.", call. = FALSE)
          data_work[sample(seq_len(nrow(data_work)), size = sample_size, replace = FALSE), , drop = FALSE]
        } else {
          data_work$bin <- cut(data_work[[num_var]], breaks = breaks, include.lowest = TRUE, labels = FALSE)
          split_bins <- split(data_work, data_work$bin, drop = TRUE)
          split_bins <- split_bins[vapply(split_bins, nrow, integer(1)) > 0]

          n_bins <- length(split_bins)
          base_n <- max(1, floor(sample_size / n_bins))
          selected <- lapply(split_bins, function(x) {
            n_take <- min(nrow(x), base_n)
            x[sample(seq_len(nrow(x)), size = n_take, replace = FALSE), , drop = FALSE]
          })

          sampled <- do.call(rbind, selected)

          if (nrow(sampled) > sample_size) {
            sampled <- sampled[sample(seq_len(nrow(sampled)), size = sample_size, replace = FALSE), , drop = FALSE]
          }

          sampled$bin <- NULL

          remaining <- sample_size - nrow(sampled)
          if (remaining > 0) {
            pool <- data_work[!data_work$OriginalRowName %in% sampled$OriginalRowName, , drop = FALSE]
            pool$bin <- NULL
            if (nrow(pool) > 0) {
              extra_n <- min(remaining, nrow(pool))
              extra <- pool[sample(seq_len(nrow(pool)), size = extra_n, replace = FALSE), , drop = FALSE]
              sampled <- rbind(sampled, extra)
            }
          }

          sampled
        }
      }
    } else {
      stop("Invalid method. Choose 'probability' or 'stratified'.", call. = FALSE)
    }
  })

  sampled_data <- sampled_data |>
    dplyr::arrange(dplyr::desc(.data[[num_var]])) |>
    tibble::column_to_rownames(var = "OriginalRowName")

  if (return_matrix) {
    as.matrix(sampled_data)
  } else {
    sampled_data
  }
}
