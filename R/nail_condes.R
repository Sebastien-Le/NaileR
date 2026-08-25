#' @importFrom dplyr mutate across where case_when filter desc arrange
#' @importFrom glue glue
#' @importFrom tibble rownames_to_column column_to_rownames
#' @importFrom dplyr slice_sample group_by select ungroup
#' @importFrom stats quantile
#' @importFrom FactoMineR condes
#' @importFrom rlang .data

# ===========================================================================
# Validation
# ===========================================================================

validate_condes_inputs <- function(dataset,
                                   num.var,
                                   quanti.threshold = 1,
                                   quanti.cat = c(
                                     "Above-average value",
                                     "Below-average value",
                                     "Intermediate value"
                                   ),
                                   sample.pct = 1,
                                   sample.method = c("stratified", "top"),
                                   weights = NULL,
                                   proba = 0.05,
                                   generate = FALSE,
                                   interpretation_mode = c(
                                     "standard",
                                     "latent"
                                   ),
                                   prompt_style = c(
                                     "detailed",
                                     "compact"
                                   )) {
  interpretation_mode <- match.arg(interpretation_mode)
  prompt_style <- match.arg(prompt_style)
  sample.method <- match.arg(sample.method)

  assert_data_frame(dataset, "dataset")

  if (ncol(dataset) < 2L) {
    stop(
      "`dataset` must contain at least two columns.",
      call. = FALSE
    )
  }

  assert_column_index(num.var, ncol(dataset), "num.var")

  if (!is.numeric(dataset[[num.var]])) {
    stop(
      paste(
        "`num.var` must refer to a numeric target variable",
        "for `FactoMineR::condes()`."
      ),
      call. = FALSE
    )
  }

  assert_numeric_scalar(
    quanti.threshold,
    "quanti.threshold",
    lower = 0,
    inclusive = TRUE
  )

  if (!is.character(quanti.cat) ||
      length(quanti.cat) != 3L ||
      any(is.na(quanti.cat)) ||
      any(!nzchar(quanti.cat))) {
    stop(
      paste(
        "`quanti.cat` must be a character vector of exactly",
        "three non-empty labels."
      ),
      call. = FALSE
    )
  }

  if (anyDuplicated(quanti.cat)) {
    stop(
      "`quanti.cat` must contain three distinct labels.",
      call. = FALSE
    )
  }

  assert_proportion(sample.pct, "sample.pct")
  assert_proportion(proba, "proba")
  assert_single_logical(generate, "generate")

  if (!is.null(weights)) {
    if (!is.numeric(weights) ||
        length(weights) != nrow(dataset) ||
        any(is.na(weights)) ||
        any(weights < 0) ||
        sum(weights) <= 0) {
      stop(
        paste(
          "`weights` must be NULL or a non-negative numeric vector",
          "with one non-missing value per row and a positive sum."
        ),
        call. = FALSE
      )
    }
  }

  invisible(TRUE)
}


# ===========================================================================
# Mechanical helpers
# ===========================================================================

.condes_numeric <- function(x) {
  suppressWarnings(as.numeric(as.character(x)))
}


.condes_p_text <- function(p) {
  if (length(p) == 0L || is.na(p) || !is.finite(p)) {
    return("NA")
  }

  if (p < 0.001) {
    return("<0.001")
  }

  sprintf("%.3f", p)
}


.condes_standardize <- function(x, weights = NULL) {
  x <- .condes_numeric(x)
  out <- rep(NA_real_, length(x))
  ok <- is.finite(x)

  if (!any(ok)) {
    return(out)
  }

  if (is.null(weights)) {
    if (sum(ok) <= 1L) {
      out[ok] <- 0
      return(out)
    }

    s <- stats::sd(x[ok])

    if (!is.finite(s) || s == 0) {
      out[ok] <- 0
      return(out)
    }

    out[ok] <- (x[ok] - mean(x[ok])) / s
    return(out)
  }

  w <- as.numeric(weights)
  ok <- ok & is.finite(w) & w > 0

  if (!any(ok)) {
    return(out)
  }

  mu <- stats::weighted.mean(x[ok], w[ok])
  variance <- sum(w[ok] * (x[ok] - mu)^2) / sum(w[ok])
  s <- sqrt(variance)

  if (!is.finite(s) || s == 0) {
    out[ok] <- 0
    return(out)
  }

  out[ok] <- (x[ok] - mu) / s
  out
}


# Historical helper retained for compatibility. Missing quantitative values
# remain missing instead of being silently classified as intermediate.
get_bins <- function(dataset,
                     keep,
                     quanti.threshold,
                     quanti.cat,
                     weights = NULL) {
  dta <- dataset

  for (j in seq_along(dta)) {
    if (!is.numeric(dta[[j]])) {
      next
    }

    z <- .condes_standardize(dta[[j]], weights = weights)

    state <- rep(NA_character_, length(z))
    state[!is.na(z) & z >= quanti.threshold] <- quanti.cat[[1L]]
    state[!is.na(z) & z <= -quanti.threshold] <- quanti.cat[[2L]]
    state[
      !is.na(z) &
        is.na(state)
    ] <- quanti.cat[[3L]]

    dta[[j]] <- factor(
      state,
      levels = quanti.cat
    )
  }

  cbind(
    dataset[, keep, drop = FALSE],
    dta
  )
}


.build_condes_augmented_data <- function(dataset,
                                         num.var,
                                         quanti.threshold,
                                         quanti.cat,
                                         weights = NULL) {
  predictor_index <- setdiff(seq_along(dataset), num.var)

  out <- data.frame(
    NCONDTARGET = dataset[[num.var]],
    check.names = FALSE
  )

  variable_map_parts <- list()
  category_map_parts <- list()

  for (k in seq_along(predictor_index)) {
    j <- predictor_index[[k]]
    variable <- colnames(dataset)[[j]]
    x <- dataset[[j]]

    if (is.numeric(x)) {
      continuous_name <- sprintf("NCONDQ%03d", k)
      state_name <- sprintf("NCONDS%03d", k)

      out[[continuous_name]] <- x

      variable_map_parts[[length(variable_map_parts) + 1L]] <- data.frame(
        condes_variable = continuous_name,
        variable = variable,
        source_type = "quantitative",
        stringsAsFactors = FALSE
      )

      z <- .condes_standardize(
        x,
        weights = weights
      )

      state <- rep(NA_character_, length(z))
      state[!is.na(z) & z >= quanti.threshold] <- quanti.cat[[1L]]
      state[!is.na(z) & z <= -quanti.threshold] <- quanti.cat[[2L]]
      state[!is.na(z) & is.na(state)] <- quanti.cat[[3L]]

      level_id <- sprintf(
        "NCONDC%03d",
        seq_along(quanti.cat)
      )
      names(level_id) <- quanti.cat

      coded_value <- unname(
        level_id[
          match(state, names(level_id))
        ]
      )
      coded_value[is.na(state)] <- NA_character_

      out[[state_name]] <- factor(
        coded_value,
        levels = unname(level_id)
      )

      variable_map_parts[[length(variable_map_parts) + 1L]] <- data.frame(
        condes_variable = state_name,
        variable = variable,
        source_type = "technical_state",
        stringsAsFactors = FALSE
      )

      category_map_parts[[length(category_map_parts) + 1L]] <- data.frame(
        condes_variable = state_name,
        condes_level = unname(level_id),
        condes_rowname = paste0(
          state_name,
          "=",
          unname(level_id)
        ),
        variable = variable,
        category = quanti.cat,
        source_type = "quantitative",
        stringsAsFactors = FALSE
      )

      next
    }

    factor_name <- sprintf("NCONDF%03d", k)
    x_chr <- as.character(x)

    raw_levels <- if (is.factor(x)) {
      levels(x)
    } else {
      unique(x_chr[!is.na(x_chr)])
    }

    raw_levels <- raw_levels[
      !is.na(raw_levels) &
        nzchar(raw_levels)
    ]

    level_id <- sprintf(
      "NCONDC%03d",
      seq_along(raw_levels)
    )
    names(level_id) <- raw_levels

    coded_value <- unname(
      level_id[
        match(x_chr, names(level_id))
      ]
    )
    coded_value[is.na(x_chr)] <- NA_character_

    out[[factor_name]] <- factor(
      coded_value,
      levels = unname(level_id)
    )

    variable_map_parts[[length(variable_map_parts) + 1L]] <- data.frame(
      condes_variable = factor_name,
      variable = variable,
      source_type = "qualitative",
      stringsAsFactors = FALSE
    )

    category_map_parts[[length(category_map_parts) + 1L]] <- data.frame(
      condes_variable = factor_name,
      condes_level = unname(level_id),
      condes_rowname = paste0(
        factor_name,
        "=",
        unname(level_id)
      ),
      variable = variable,
      category = raw_levels,
      source_type = "qualitative",
      stringsAsFactors = FALSE
    )
  }

  variable_map <- if (length(variable_map_parts) == 0L) {
    data.frame(
      condes_variable = character(0),
      variable = character(0),
      source_type = character(0),
      stringsAsFactors = FALSE
    )
  } else {
    do.call(rbind, variable_map_parts)
  }

  category_map <- if (length(category_map_parts) == 0L) {
    data.frame(
      condes_variable = character(0),
      condes_level = character(0),
      condes_rowname = character(0),
      variable = character(0),
      category = character(0),
      source_type = character(0),
      stringsAsFactors = FALSE
    )
  } else {
    do.call(rbind, category_map_parts)
  }

  rownames(variable_map) <- NULL
  rownames(category_map) <- NULL

  list(
    data = out,
    variable_map = variable_map,
    category_map = category_map
  )
}

.empty_condes_quantitative <- function() {
  data.frame(
    evidence_id = character(0),
    variable = character(0),
    correlation = numeric(0),
    abs_correlation = numeric(0),
    direction = character(0),
    p_value = numeric(0),
    rank = integer(0),
    stringsAsFactors = FALSE
  )
}


.empty_condes_qualitative <- function() {
  data.frame(
    evidence_id = character(0),
    variable = character(0),
    r2 = numeric(0),
    p_value = numeric(0),
    rank = integer(0),
    stringsAsFactors = FALSE
  )
}


.empty_condes_end_profile <- function() {
  data.frame(
    evidence_id = character(0),
    variable = character(0),
    category = character(0),
    source_type = character(0),
    estimate = numeric(0),
    abs_estimate = numeric(0),
    side = character(0),
    p_value = numeric(0),
    rank = integer(0),
    stringsAsFactors = FALSE
  )
}


.build_condes_quantitative <- function(res_cd,
                                        variable_map) {
  raw <- res_cd$quanti

  if (is.null(raw) || nrow(as.data.frame(raw)) == 0L) {
    return(.empty_condes_quantitative())
  }

  raw <- as.data.frame(raw)
  raw_variable <- rownames(raw)
  map_index <- match(
    raw_variable,
    variable_map$condes_variable
  )

  keep <- !is.na(map_index) &
    variable_map$source_type[map_index] == "quantitative"

  if (!any(keep)) {
    return(.empty_condes_quantitative())
  }

  raw <- raw[keep, , drop = FALSE]
  map_index <- map_index[keep]

  correlation <- .condes_numeric(raw[["correlation"]])

  out <- data.frame(
    evidence_id = NA_character_,
    variable = variable_map$variable[map_index],
    correlation = correlation,
    abs_correlation = abs(correlation),
    direction = ifelse(
      correlation >= 0,
      "positive",
      "negative"
    ),
    p_value = .condes_numeric(raw[["p.value"]]),
    rank = NA_integer_,
    stringsAsFactors = FALSE
  )

  out <- out[
    order(
      out$p_value,
      -out$abs_correlation,
      out$variable,
      na.last = TRUE
    ),
    ,
    drop = FALSE
  ]

  out$rank <- seq_len(nrow(out))
  out$evidence_id <- sprintf(
    "CONDQ%03d",
    out$rank
  )
  rownames(out) <- NULL
  out
}

.build_condes_qualitative <- function(res_cd,
                                       variable_map) {
  raw <- res_cd$quali

  if (is.null(raw) || nrow(as.data.frame(raw)) == 0L) {
    return(.empty_condes_qualitative())
  }

  raw <- as.data.frame(raw)
  raw_variable <- rownames(raw)
  map_index <- match(
    raw_variable,
    variable_map$condes_variable
  )

  keep <- !is.na(map_index) &
    variable_map$source_type[map_index] == "qualitative"

  if (!any(keep)) {
    return(.empty_condes_qualitative())
  }

  raw <- raw[keep, , drop = FALSE]
  map_index <- map_index[keep]

  out <- data.frame(
    evidence_id = NA_character_,
    variable = variable_map$variable[map_index],
    r2 = .condes_numeric(raw[["R2"]]),
    p_value = .condes_numeric(raw[["p.value"]]),
    rank = NA_integer_,
    stringsAsFactors = FALSE
  )

  out <- out[
    order(
      out$p_value,
      -out$r2,
      out$variable,
      na.last = TRUE
    ),
    ,
    drop = FALSE
  ]

  out$rank <- seq_len(nrow(out))
  out$evidence_id <- sprintf(
    "CONDF%03d",
    out$rank
  )
  rownames(out) <- NULL
  out
}

.build_condes_end_profiles <- function(res_cd,
                                      category_map) {
  raw <- res_cd$category

  if (is.null(raw) || nrow(as.data.frame(raw)) == 0L) {
    return(
      list(
        low = .empty_condes_end_profile(),
        high = .empty_condes_end_profile()
      )
    )
  }

  raw <- as.data.frame(raw)
  full_label <- rownames(raw)

  # FactoMineR prefixes each modality with its source variable name.
  # Match robustly without depending on the exact separator used internally.
  map_index <- vapply(
    full_label,
    function(label) {
      hits <- which(
        startsWith(
          label,
          category_map$condes_variable
        ) &
          endsWith(
            label,
            category_map$condes_level
          )
      )

      if (length(hits) == 1L) {
        return(as.integer(hits))
      }

      NA_integer_
    },
    integer(1)
  )

  estimate <- .condes_numeric(raw[["Estimate"]])
  p_value <- .condes_numeric(raw[["p.value"]])

  all_profiles <- data.frame(
    evidence_id = NA_character_,
    variable = category_map$variable[map_index],
    category = category_map$category[map_index],
    source_type = category_map$source_type[map_index],
    estimate = estimate,
    abs_estimate = abs(estimate),
    side = ifelse(
      estimate < 0,
      "low",
      ifelse(
        estimate > 0,
        "high",
        "neutral"
      )
    ),
    p_value = p_value,
    rank = NA_integer_,
    stringsAsFactors = FALSE
  )

  mapped <- !is.na(map_index)
  all_profiles <- all_profiles[
    mapped &
      all_profiles$side %in% c("low", "high"),
    ,
    drop = FALSE
  ]

  build_side <- function(side_name,
                         prefix) {
    out <- all_profiles[
      all_profiles$side == side_name,
      ,
      drop = FALSE
    ]

    if (nrow(out) == 0L) {
      return(.empty_condes_end_profile())
    }

    out <- out[
      order(
        out$p_value,
        -out$abs_estimate,
        out$variable,
        out$category,
        na.last = TRUE
      ),
      ,
      drop = FALSE
    ]

    out$rank <- seq_len(nrow(out))
    out$evidence_id <- sprintf(
      "%s%03d",
      prefix,
      out$rank
    )
    rownames(out) <- NULL
    out
  }

  list(
    low = build_side(
      "low",
      "CONDL"
    ),
    high = build_side(
      "high",
      "CONDH"
    )
  )
}

.build_condes_registry <- function(quantitative,
                                   qualitative,
                                   end_profiles) {
  registry_parts <- list()

  if (nrow(quantitative) > 0L) {
    registry_parts[[length(registry_parts) + 1L]] <- data.frame(
      evidence_id = quantitative$evidence_id,
      family = "quantitative_association",
      variable = quantitative$variable,
      category = NA_character_,
      direction = quantitative$direction,
      statistic = quantitative$correlation,
      statistic_name = "correlation",
      p_value = quantitative$p_value,
      rank = quantitative$rank,
      stringsAsFactors = FALSE
    )
  }

  if (nrow(qualitative) > 0L) {
    registry_parts[[length(registry_parts) + 1L]] <- data.frame(
      evidence_id = qualitative$evidence_id,
      family = "qualitative_association",
      variable = qualitative$variable,
      category = NA_character_,
      direction = "global",
      statistic = qualitative$r2,
      statistic_name = "R2",
      p_value = qualitative$p_value,
      rank = qualitative$rank,
      stringsAsFactors = FALSE
    )
  }

  for (side_name in c("low", "high")) {
    x <- end_profiles[[side_name]]

    if (nrow(x) == 0L) {
      next
    }

    registry_parts[[length(registry_parts) + 1L]] <- data.frame(
      evidence_id = x$evidence_id,
      family = "end_profile",
      variable = x$variable,
      category = x$category,
      direction = side_name,
      statistic = x$estimate,
      statistic_name = "Estimate",
      p_value = x$p_value,
      rank = x$rank,
      stringsAsFactors = FALSE
    )
  }

  if (length(registry_parts) == 0L) {
    return(
      data.frame(
        evidence_id = character(0),
        family = character(0),
        variable = character(0),
        category = character(0),
        direction = character(0),
        statistic = numeric(0),
        statistic_name = character(0),
        p_value = numeric(0),
        rank = integer(0),
        stringsAsFactors = FALSE
      )
    )
  }

  out <- do.call(rbind, registry_parts)
  rownames(out) <- NULL
  out
}


.build_continuous_profile_condes <- function(res_cd,
                                             augmented,
                                             dataset,
                                             num.var,
                                             proba,
                                             quanti.threshold,
                                             quanti.cat,
                                             weights = NULL) {
  quantitative <- .build_condes_quantitative(
    res_cd = res_cd,
    variable_map = augmented$variable_map
  )

  qualitative <- .build_condes_qualitative(
    res_cd = res_cd,
    variable_map = augmented$variable_map
  )

  end_profiles <- .build_condes_end_profiles(
    res_cd = res_cd,
    category_map = augmented$category_map
  )

  registry <- .build_condes_registry(
    quantitative = quantitative,
    qualitative = qualitative,
    end_profiles = end_profiles
  )

  target_variable <- if (is.null(colnames(dataset))) {
    paste0("V", num.var)
  } else {
    colnames(dataset)[[num.var]]
  }

  out <- list(
    target = list(
      variable = target_variable,
      index = as.integer(num.var)
    ),
    quantitative_associations = quantitative,
    qualitative_associations = qualitative,
    end_profiles = end_profiles,
    evidence_registry = registry,
    metrics = list(
      n_quantitative_associations = as.integer(nrow(quantitative)),
      n_qualitative_associations = as.integer(nrow(qualitative)),
      n_low_end_profiles = as.integer(nrow(end_profiles$low)),
      n_high_end_profiles = as.integer(nrow(end_profiles$high))
    ),
    settings = list(
      num_var = as.integer(num.var),
      proba = proba,
      quanti_threshold = quanti.threshold,
      quanti_cat = quanti.cat,
      weights_supplied = !is.null(weights),
      statistical_source = "single_condes_on_augmented_data"
    ),
    metadata = list(
      n_observations = as.integer(nrow(dataset)),
      n_variables = as.integer(ncol(dataset))
    )
  )

  class(out) <- c(
    "nail_condes_continuous_profile",
    "list"
  )
  out
}

.validate_continuous_profile_condes <- function(x) {
  required <- c(
    "target",
    "quantitative_associations",
    "qualitative_associations",
    "end_profiles",
    "evidence_registry",
    "settings",
    "metadata"
  )

  if (!is.list(x) || !all(required %in% names(x))) {
    stop(
      "Invalid internal `continuous_profile` object.",
      call. = FALSE
    )
  }

  invisible(TRUE)
}


# ===========================================================================
# Deterministic interpretation selection
# ===========================================================================

.select_condes_ranked <- function(df,
                                  sample_pct,
                                  sample_method = c(
                                    "stratified",
                                    "top"
                                  ),
                                  preserve_direction = FALSE) {
  sample_method <- match.arg(sample_method)

  if (!is.data.frame(df) || nrow(df) == 0L) {
    return(df)
  }

  n_available <- nrow(df)

  if (sample_pct <= 0) {
    return(df[0, , drop = FALSE])
  }

  n_keep <- if (sample_pct >= 1) {
    n_available
  } else {
    ceiling(n_available * sample_pct)
  }

  n_keep <- min(n_keep, n_available)

  if (n_keep >= n_available) {
    return(df)
  }

  if (identical(sample_method, "top") || n_keep <= 2L) {
    return(
      df[
        seq_len(n_keep),
        ,
        drop = FALSE
      ]
    )
  }

  n_anchor <- min(
    n_keep - 1L,
    max(2L, ceiling(0.60 * n_keep))
  )
  n_explore <- n_keep - n_anchor

  anchor_idx <- seq_len(n_anchor)
  remaining_idx <- setdiff(
    seq_len(n_available),
    anchor_idx
  )
  explore_idx <- integer(0)

  if (isTRUE(preserve_direction) &&
      "direction" %in% names(df) &&
      n_explore > 0L) {
    anchor_direction <- unique(
      as.character(df$direction[anchor_idx])
    )
    available_direction <- intersect(
      c("positive", "negative"),
      unique(as.character(df$direction))
    )
    missing_direction <- setdiff(
      available_direction,
      anchor_direction
    )

    if (length(missing_direction) > 0L) {
      opposite_idx <- which(
        df$direction %in% missing_direction &
          seq_len(n_available) %in% remaining_idx
      )[1L]

      if (length(opposite_idx) > 0L &&
          !is.na(opposite_idx)) {
        explore_idx <- c(
          explore_idx,
          opposite_idx
        )
      }
    }
  }

  slots_left <- n_explore - length(explore_idx)

  if (slots_left > 0L) {
    exploration_pool <- setdiff(
      remaining_idx,
      explore_idx
    )

    if (length(exploration_pool) <= slots_left) {
      explore_idx <- c(
        explore_idx,
        exploration_pool
      )
    } else {
      probs <- seq_len(slots_left) / (slots_left + 1)
      pool_positions <- unique(
        as.integer(
          round(
            1 + probs * (length(exploration_pool) - 1)
          )
        )
      )

      pool_positions <- pmax(
        1L,
        pmin(
          length(exploration_pool),
          pool_positions
        )
      )

      if (length(pool_positions) < slots_left) {
        missing_positions <- setdiff(
          seq_along(exploration_pool),
          pool_positions
        )
        pool_positions <- c(
          pool_positions,
          utils::head(
            missing_positions,
            slots_left - length(pool_positions)
          )
        )
      }

      explore_idx <- c(
        explore_idx,
        exploration_pool[
          sort(unique(pool_positions))[seq_len(slots_left)]
        ]
      )
    }
  }

  selected_idx <- sort(
    unique(
      c(anchor_idx, explore_idx)
    )
  )

  if (length(selected_idx) < n_keep) {
    completion <- setdiff(
      seq_len(n_available),
      selected_idx
    )
    selected_idx <- c(
      selected_idx,
      utils::head(
        completion,
        n_keep - length(selected_idx)
      )
    )
  }

  selected_idx <- sort(
    unique(selected_idx)
  )[seq_len(n_keep)]

  out <- df[
    selected_idx,
    ,
    drop = FALSE
  ]
  rownames(out) <- NULL
  out
}


.build_interpretation_evidence_condes <- function(continuous_profile,
                                                  sample_pct = 1,
                                                  sample_method = c(
                                                    "stratified",
                                                    "top"
                                                  )) {
  sample_method <- match.arg(sample_method)
  .validate_continuous_profile_condes(continuous_profile)

  quantitative <- .select_condes_ranked(
    continuous_profile$quantitative_associations,
    sample_pct = sample_pct,
    sample_method = sample_method,
    preserve_direction = TRUE
  )

  qualitative <- .select_condes_ranked(
    continuous_profile$qualitative_associations,
    sample_pct = sample_pct,
    sample_method = sample_method,
    preserve_direction = FALSE
  )

  low <- .select_condes_ranked(
    continuous_profile$end_profiles$low,
    sample_pct = sample_pct,
    sample_method = sample_method,
    preserve_direction = FALSE
  )

  high <- .select_condes_ranked(
    continuous_profile$end_profiles$high,
    sample_pct = sample_pct,
    sample_method = sample_method,
    preserve_direction = FALSE
  )

  out <- list(
    target = continuous_profile$target,
    quantitative_associations = quantitative,
    qualitative_associations = qualitative,
    end_profiles = list(
      low = low,
      high = high
    ),
    selected_evidence_ids = c(
      quantitative$evidence_id,
      qualitative$evidence_id,
      low$evidence_id,
      high$evidence_id
    ),
    settings = list(
      sample_pct = sample_pct,
      sample_method = sample_method,
      selection_rule = if (identical(sample_method, "top")) {
        paste(
          "Within each evidence family, retain the strongest",
          "ceiling(n * sample.pct) items."
        )
      } else {
        paste(
          "Within each evidence family, preserve a statistical anchor",
          "and deterministically explore lower-ranked retained evidence."
        )
      }
    )
  )

  class(out) <- c(
    "nail_condes_interpretation_evidence",
    "list"
  )
  out
}


# ===========================================================================
# Semantic-facing evidence
# ===========================================================================

.condes_quantitative_fact <- function(row,
                                      target_label) {
  direction_word <- if (identical(row$direction, "positive")) {
    "POSITIVELY"
  } else {
    "NEGATIVELY"
  }

  paste0(
    'Variable "', row$variable, '" is ', direction_word,
    ' associated with "', target_label, '"',
    " (correlation=", sprintf("%.2f", row$correlation),
    "; p.value=", .condes_p_text(row$p_value), ")."
  )
}


.condes_qualitative_fact <- function(row,
                                     target_label) {
  paste0(
    'Qualitative variable "', row$variable,
    '" is globally associated with "', target_label, '"',
    " (R2=", sprintf("%.2f", row$r2),
    "; p.value=", .condes_p_text(row$p_value), ")."
  )
}


.condes_end_fact <- function(row,
                             target_label) {
  side_word <- if (identical(row$side, "low")) {
    "LOWER"
  } else {
    "HIGHER"
  }

  if (identical(row$source_type, "quantitative")) {
    return(
      paste0(
        'For variable "', row$variable, '", the state "',
        row$category, '" is associated with the ', side_word,
        ' end of "', target_label, '"',
        " (Estimate=", sprintf("%.2f", row$estimate),
        "; p.value=", .condes_p_text(row$p_value), ")."
      )
    )
  }

  paste0(
    'Category "', row$category, '" of variable "',
    row$variable, '" is associated with the ', side_word,
    ' end of "', target_label, '"',
    " (Estimate=", sprintf("%.2f", row$estimate),
    "; p.value=", .condes_p_text(row$p_value), ")."
  )
}


.condes_fact_lines <- function(df,
                               FUN,
                               target_label,
                               empty_text) {
  if (!is.data.frame(df) || nrow(df) == 0L) {
    return(empty_text)
  }

  paste0(
    "- ",
    vapply(
      seq_len(nrow(df)),
      function(i) {
        FUN(
          df[i, , drop = FALSE],
          target_label = target_label
        )
      },
      character(1)
    )
  )
}


.build_semantic_facing_evidence_condes <- function(interpretation_evidence,
                                                   target_label) {
  quantitative_lines <- .condes_fact_lines(
    interpretation_evidence$quantitative_associations,
    FUN = .condes_quantitative_fact,
    target_label = target_label,
    empty_text = "*No retained continuous-variable association is available.*"
  )

  qualitative_lines <- .condes_fact_lines(
    interpretation_evidence$qualitative_associations,
    FUN = .condes_qualitative_fact,
    target_label = target_label,
    empty_text = "*No retained global qualitative-variable association is available.*"
  )

  low_lines <- .condes_fact_lines(
    interpretation_evidence$end_profiles$low,
    FUN = .condes_end_fact,
    target_label = target_label,
    empty_text = "*No retained low-end profile is available.*"
  )

  high_lines <- .condes_fact_lines(
    interpretation_evidence$end_profiles$high,
    FUN = .condes_end_fact,
    target_label = target_label,
    empty_text = "*No retained high-end profile is available.*"
  )

  prompt_text <- paste(
    "## Variable-level evidence",
    "",
    "### Continuous variables",
    paste(quantitative_lines, collapse = "\n"),
    "",
    "### Qualitative variables",
    paste(qualitative_lines, collapse = "\n"),
    "",
    "## End-profile evidence",
    "",
    "### Lower end",
    paste(low_lines, collapse = "\n"),
    "",
    "### Higher end",
    paste(high_lines, collapse = "\n"),
    sep = "\n"
  )

  out <- list(
    target_label = target_label,
    quantitative_facts = quantitative_lines,
    qualitative_facts = qualitative_lines,
    low_end_facts = low_lines,
    high_end_facts = high_lines,
    prompt_text = prompt_text
  )

  class(out) <- c(
    "nail_condes_semantic_facing_evidence",
    "list"
  )
  out
}


# ===========================================================================
# Prompt builders
# ===========================================================================

build_guide_condes <- function(mode = c("standard", "latent"),
                               target_label = "the target variable",
                               prompt_style = c("detailed", "compact"),
                               proba = 0.05,
                               sample.pct = 1,
                               sample.method = c("stratified", "top"),
                               quanti.threshold = 1) {
  mode <- match.arg(mode)
  prompt_style <- match.arg(prompt_style)
  sample.method <- match.arg(sample.method)

  sampling_line <- if (sample.pct >= 1) {
    "All retained evidence is shown to the LLM."
  } else if (identical(sample.method, "top")) {
    paste0(
      round(100 * sample.pct, 1),
      "% of each eligible evidence family is shown,",
      " using the strongest retained items."
    )
  } else {
    paste0(
      round(100 * sample.pct, 1),
      "% of each eligible evidence family is shown,",
      " using deterministic anchor + exploration selection."
    )
  }

  common <- c(
    "## How to Read the Evidence",
    paste0(
      "The R-derived facts below come from `FactoMineR::condes()`",
      " under the current retention threshold (p <= ",
      proba,
      ")."
    ),
    "Continuous-variable associations are the main direct evidence for the direction of the continuum.",
    "Global qualitative-variable associations provide complementary evidence.",
    paste0(
      "End profiles illustrate the two ends of the continuum.",
      " Quantitative predictors are represented by above-average, below-average, or intermediate-value states",
      " using a threshold of ",
      quanti.threshold,
      " standard-deviation unit(s); original qualitative categories are preserved."
    ),
    sampling_line,
    "Do not infer causality from these associations."
  )

  if (prompt_style == "detailed") {
    common <- c(
      common,
      "A positive correlation means that higher values of the predictor tend to accompany higher values of the target; a negative correlation means the opposite.",
      "For end profiles, a negative Estimate indicates the lower end of the target and a positive Estimate indicates the higher end.",
      "Treat smaller p.values as stronger evidence among the displayed retained results.",
      "Interpret the pattern formed by several coherent variables rather than merely paraphrasing each line."
    )
  }

  mode_lines <- if (mode == "standard") {
    c(
      paste0(
        'The target label "', target_label,
        '" is meaningful and refers to an observed continuous variable.'
      ),
      "Preserve this meaning and do not rename the target."
    )
  } else {
    c(
      paste0(
        'The target label "', target_label,
        '" may be a technical label for a synthetic or latent continuous score.'
      ),
      "Treat its two ends as opposite manifestations of one continuum and reconstruct its substantive meaning from the evidence."
    )
  }

  paste(
    c(common, mode_lines),
    collapse = "\n"
  )
}


build_request_condes <- function(
    mode = c("standard", "latent"),
    target_concept = "the target concept",
    target_label = "the target variable",
    prompt_style = c("detailed", "compact")) {
  mode <- match.arg(mode)
  prompt_style <- match.arg(prompt_style)

  if (mode == "standard") {
    if (prompt_style == "compact") {
      return(
        paste(
          paste0(
            'Interpret the observed continuous variable "',
            target_label,
            '" using only the evidence below.'
          ),
          "Identify the main associations and describe what characterizes its lower and higher ends.",
          "Synthesize what the evidence adds to the understanding of the variable without renaming it.",
          "Do not invent causal explanations.",
          sep = "\n"
        )
      )
    }

    return(
      paste(
        paste0(
          'Using only the evidence below, interpret the observed continuous variable "',
          target_label,
          '".'
        ),
        "1. Identify the strongest and most coherent variable-level associations.",
        "2. Translate their directions into substantive meaning.",
        "3. Describe what characterizes the lower end of the target.",
        "4. Describe what characterizes the higher end of the target.",
        "5. Use the end-profile evidence to illustrate or qualify the variable-level pattern.",
        "6. Explain what these associations add to the understanding of the target as a whole.",
        "Do not rename the target, do not force coherence, and do not invent causal explanations.",
        sep = "\n"
      )
    )
  }

  concept_rule <- if (identical(
    target_concept,
    "the target concept"
  )) {
    "Prefer the simplest unifying name supported by the strongest and most coherent evidence."
  } else {
    paste0(
      'Use "', target_concept,
      '" only as contextual guidance; do not force that label if the evidence supports a more precise or different continuum.'
    )
  }

  if (prompt_style == "compact") {
    return(
      paste(
        paste0(
          'Interpret "', target_label,
          '" as one continuous latent or synthetic dimension using only the evidence below.'
        ),
        "Identify the main variable-level associations, describe the two ends, and infer the common meaning that best explains their opposition.",
        'State explicitly: "What separates the higher end from the lower end of the continuum is..."',
        "Then propose one concise name for the continuum.",
        concept_rule,
        "Do not invent causal explanations.",
        sep = "\n"
      )
    )
  }

  paste(
    paste0(
      'Using only the evidence below, interpret "',
      target_label,
      '" as one continuous latent or synthetic dimension.'
    ),
    "1. Identify the strongest and most coherent variable-level associations.",
    "2. Translate their directions into substantive meaning.",
    "3. Describe the lower end of the continuum.",
    "4. Describe the higher end of the continuum.",
    "5. Use the end-profile evidence to illustrate, refine, or qualify those two ends.",
    "6. Infer the common underlying meaning that best explains both ends as opposite manifestations of one continuum.",
    '7. Write one sentence beginning with: "What separates the higher end from the lower end of the continuum is..."',
    "8. Propose one concise name for the continuum and justify it from the strongest coherent evidence.",
    "9. Mention mixed, ambiguous, or only weakly supported patterns when necessary.",
    concept_rule,
    "Do not simply restate the evidence line by line and do not invent causal explanations.",
    sep = "\n"
  )
}


build_conclusion_condes <- function(
    mode = c("standard", "latent"),
    target_label = "the target variable") {
  mode <- match.arg(mode)

  if (mode == "standard") {
    return(
      paste(
        "# Final Summary Task",
        "End with:",
        paste0(
          '1. **Meaning of "', target_label,
          '"** - a concise synthesis of what the evidence shows.'
        ),
        "2. **Lower end** - the main characteristics associated with lower values.",
        "3. **Higher end** - the main characteristics associated with higher values.",
        "4. **Overall interpretation** - the main coherent pattern, including any important nuance or mixed evidence.",
        "",
        "# Output format",
        "Your output must be **formatted using valid Quarto Markdown**.",
        sep = "\n"
      )
    )
  }

  paste(
    "# Final Summary Task",
    "End with:",
    "1. **Main continuum** - one concise statement of the opposition represented by the score.",
    "2. **Lower end** - the main characteristics of one end.",
    "3. **Higher end** - the main characteristics of the other end.",
    '4. **What separates the ends** - one sentence beginning with "What separates the higher end from the lower end of the continuum is...".',
    "5. **Proposed latent dimension** - one concise name and its evidence-based justification.",
    "",
    "# Output format",
    "Your output must be **formatted using valid Quarto Markdown**.",
    sep = "\n"
  )
}


# ===========================================================================
# LLM IO and artifact attachment
# ===========================================================================

.condes_backend_response_text <- function(x) {
  if (is.data.frame(x) &&
      "response" %in% names(x) &&
      nrow(x) > 0L) {
    return(
      paste(
        as.character(x$response),
        collapse = "\n"
      )
    )
  }

  if (is.list(x) && !is.null(x$response)) {
    return(
      paste(
        as.character(x$response),
        collapse = "\n"
      )
    )
  }

  if (is.character(x)) {
    return(
      paste(
        x,
        collapse = "\n"
      )
    )
  }

  stop(
    paste(
      "The condes LLM backend result does not contain",
      "a readable raw response."
    ),
    call. = FALSE
  )
}


.attach_condes_artifacts <- function(x,
                                     continuous_profile,
                                     interpretation_evidence,
                                     semantic_facing_evidence,
                                     prompt,
                                     response,
                                     condes_result,
                                     condes_profile_result,
                                     condes_settings,
                                     target_label) {
  prompt_list <- stats::setNames(
    list(prompt),
    target_label
  )

  response_list <- if (is.null(response)) {
    NULL
  } else {
    stats::setNames(
      list(response),
      target_label
    )
  }

  attr(x, "continuous_profile") <- continuous_profile
  attr(x, "interpretation_evidence") <- interpretation_evidence
  attr(x, "semantic_facing_evidence") <- semantic_facing_evidence
  attr(x, "condes_prompt") <- prompt

  # Historical raw objects retained as compatibility/direct-evidence views.
  attr(x, "condes_result") <- condes_result
  # Deprecated compatibility alias. Both attributes contain the same single
  # `FactoMineR::condes()` result; no second statistical analysis is run.
  attr(x, "condes_profile_result") <- condes_profile_result

  attr(x, "condes_settings") <- condes_settings
  attr(x, "llm_io") <- .new_nail_llm_io(
    stage = "interpretation",
    prompts = prompt_list,
    responses = response_list,
    metadata = list(
      analysis = "nail_condes",
      scope = "continuous_target",
      provider = condes_settings$provider,
      model = condes_settings$model,
      interpretation_mode = condes_settings$interpretation_mode,
      target_label = target_label
    )
  )

  x
}


# ===========================================================================
# Main
# ===========================================================================

#' Interpret a continuous variable or latent continuum
#'
#' `nail_condes()` characterizes one continuous target using
#' [FactoMineR::condes()]. It first builds a canonical R-derived
#' `continuous_profile`, then selects a deterministic subset of that evidence
#' for semantic interpretation by the LLM.
#'
#' `interpretation_mode = "standard"` interprets an observed continuous
#' variable whose label is already meaningful. `interpretation_mode = "latent"`
#' interprets a synthetic or latent score as a continuum whose substantive
#' meaning may need to be reconstructed.
#'
#' The canonical `continuous_profile` is invariant to `generate`,
#' `interpretation_mode`, `sample.pct`, `sample.method`, `prompt_style`,
#' `target_concept`, `target_label`, `introduction`, `request`, and
#' `conclusion`. These arguments affect only the interpretation layer.
#'
#' @param dataset A data frame containing one numeric target variable and
#'   quantitative and/or qualitative explanatory variables.
#' @param num.var Index of the numeric variable to characterize.
#' @param introduction Optional contextual introduction added to the prompt.
#' @param request Optional analytical request sent to the LLM.
#' @param conclusion Optional final output-instruction block.
#' @param model Model name for the selected provider.
#' @param provider LLM backend. Currently `"ollama"` or `"gemini"`.
#' @param quanti.threshold Threshold, in standard-deviation units, used to
#'   convert quantitative predictors into the three technical states defined
#'   by `quanti.cat` for end-profile construction.
#' @param quanti.cat Three distinct labels used for above-average,
#'   below-average, and intermediate quantitative predictor values, in that
#'   order. These labels describe predictor values, not the target variable.
#' @param sample.pct Proportion of each eligible evidence family included in
#'   the LLM evidence. This does not alter the canonical `continuous_profile`.
#' @param sample.method Deterministic evidence-selection strategy when
#'   `sample.pct < 1`. `"stratified"` (default) preserves a statistical anchor
#'   and explores lower-ranked retained evidence; `"top"` retains only the
#'   strongest evidence.
#' @param weights Optional non-negative row weights passed to
#'   [FactoMineR::condes()]. When supplied, quantitative predictors are also
#'   standardized with these weights for end-profile construction.
#' @param proba Significance threshold passed to [FactoMineR::condes()].
#' @param generate If `FALSE`, build the prompt without calling an LLM. If
#'   `TRUE`, call the selected backend.
#' @param interpretation_mode Either `"standard"` for an observed variable or
#'   `"latent"` for a synthetic/latent continuum.
#' @param prompt_style Either `"detailed"` or `"compact"`.
#' @param target_concept Optional contextual concept for latent interpretation.
#'   It guides but does not constrain the evidence-based naming of the
#'   continuum.
#' @param target_label Optional display label for the target in the prompt.
#'   If `NULL`, the dataset column name is used. This does not alter the
#'   canonical target identity stored in `continuous_profile`.
#' @param ... Additional provider-specific generation arguments.
#'
#' @return For backward compatibility, a prompt string when
#'   `generate = FALSE`, or the backend data frame when `generate = TRUE`.
#'   Analytical artifacts are attached as attributes:
#'
#'   * `continuous_profile`: canonical R-derived evidence.
#'   * `interpretation_evidence`: deterministic subset shown to the LLM.
#'   * `semantic_facing_evidence`: explicit factual statements used in the
#'     prompt.
#'   * `llm_io`: exact prompt and raw LLM response for [nail_prompt()] and
#'     [nail_response()].
#'   * `condes_result`: the single original FactoMineR result used as the
#'     statistical source of truth.
#'   * `condes_profile_result`: deprecated compatibility alias of
#'     `condes_result`; no second `condes()` analysis is performed.
#'   * `condes_settings`: execution settings.
#'
#' @export
#'
#' @examples
#' \dontrun{
#' data(decathlon, package = "FactoMineR")
#'
#' # Observed-variable interpretation
#' x <- nail_condes(
#'   decathlon,
#'   num.var = 12,
#'   interpretation_mode = "standard",
#'   generate = FALSE
#' )
#' nail_prompt(x)
#'
#' # A synthetic dimension should use latent mode
#' pca <- FactoMineR::PCA(
#'   decathlon[, 1:10],
#'   scale.unit = TRUE,
#'   graph = FALSE
#' )
#' work <- data.frame(
#'   Dim1 = pca$ind$coord[, 1],
#'   decathlon[, 1:10]
#' )
#' dim1 <- nail_condes(
#'   work,
#'   num.var = 1,
#'   interpretation_mode = "latent",
#'   target_label = "Dim1",
#'   generate = FALSE
#' )
#' nail_prompt(dim1)
#' }
nail_condes <- function(dataset,
                        num.var,
                        introduction = NULL,
                        request = NULL,
                        conclusion = NULL,
                        model = "llama3",
                        provider = c("ollama", "gemini"),
                        quanti.threshold = 1,
                        quanti.cat = c(
                          "Above-average value",
                          "Below-average value",
                          "Intermediate value"
                        ),
                        sample.pct = 1,
                        sample.method = c(
                          "stratified",
                          "top"
                        ),
                        weights = NULL,
                        proba = 0.05,
                        generate = FALSE,
                        interpretation_mode = c(
                          "standard",
                          "latent"
                        ),
                        prompt_style = c(
                          "detailed",
                          "compact"
                        ),
                        target_concept = "the target concept",
                        target_label = NULL,
                        ...) {
  interpretation_mode <- match.arg(
    interpretation_mode
  )
  prompt_style <- match.arg(prompt_style)
  provider <- match.arg(provider)
  sample.method <- match.arg(sample.method)

  validate_condes_inputs(
    dataset = dataset,
    num.var = num.var,
    quanti.threshold = quanti.threshold,
    quanti.cat = quanti.cat,
    sample.pct = sample.pct,
    sample.method = sample.method,
    weights = weights,
    proba = proba,
    generate = generate,
    interpretation_mode = interpretation_mode,
    prompt_style = prompt_style
  )

  target_variable <- if (is.null(colnames(dataset))) {
    paste0("V", num.var)
  } else {
    colnames(dataset)[[num.var]]
  }

  if (is.null(target_label)) {
    target_label <- target_variable
  }

  if (!is.character(target_label) ||
      length(target_label) != 1L ||
      is.na(target_label) ||
      !nzchar(trimws(target_label))) {
    stop(
      "`target_label` must be NULL or one non-empty character string.",
      call. = FALSE
    )
  }

  if (!is.character(target_concept) ||
      length(target_concept) != 1L ||
      is.na(target_concept) ||
      !nzchar(trimws(target_concept))) {
    stop(
      "`target_concept` must be one non-empty character string.",
      call. = FALSE
    )
  }

  if (is.null(introduction)) {
    introduction <- if (interpretation_mode == "standard") {
      paste0(
        'The continuous variable analyzed here is "',
        target_label,
        '".'
      )
    } else {
      paste0(
        'The continuous score analyzed here is "',
        target_label,
        '". Its substantive meaning may need to be reconstructed',
        " from the variables associated with its two ends."
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

  if (is.null(conclusion)) {
    conclusion <- build_conclusion_condes(
      mode = interpretation_mode,
      target_label = target_label
    )
  }

  augmented <- .build_condes_augmented_data(
    dataset = dataset,
    num.var = num.var,
    quanti.threshold = quanti.threshold,
    quanti.cat = quanti.cat,
    weights = weights
  )

  # One canonical statistical analysis. Original quantitative predictors are
  # kept continuous, while technical categorical copies provide end-profile
  # information in the same `condes()` result.
  res_cd <- FactoMineR::condes(
    augmented$data,
    num.var = 1,
    weights = weights,
    proba = proba
  )

  continuous_profile <- .build_continuous_profile_condes(
    res_cd = res_cd,
    augmented = augmented,
    dataset = dataset,
    num.var = num.var,
    proba = proba,
    quanti.threshold = quanti.threshold,
    quanti.cat = quanti.cat,
    weights = weights
  )

  interpretation_evidence <- .build_interpretation_evidence_condes(
    continuous_profile = continuous_profile,
    sample_pct = sample.pct,
    sample_method = sample.method
  )

  semantic_facing_evidence <- .build_semantic_facing_evidence_condes(
    interpretation_evidence = interpretation_evidence,
    target_label = target_label
  )

  guide <- build_guide_condes(
    mode = interpretation_mode,
    target_label = target_label,
    prompt_style = prompt_style,
    proba = proba,
    sample.pct = sample.pct,
    sample.method = sample.method,
    quanti.threshold = quanti.threshold
  )

  prompt_introduction <- paste(
    introduction,
    guide,
    sep = "\n\n---\n\n"
  )

  final_prompt <- build_standard_prompt(
    introduction = prompt_introduction,
    request = request,
    data = semantic_facing_evidence$prompt_text,
    conclusion = conclusion
  )

  condes_settings <- list(
    num_var = as.integer(num.var),
    target_variable = target_variable,
    target_label = target_label,
    quanti_threshold = quanti.threshold,
    quanti_cat = quanti.cat,
    sample_pct = sample.pct,
    sample_method = sample.method,
    weights_supplied = !is.null(weights),
    proba = proba,
    statistical_source = "single_condes_on_augmented_data",
    interpretation_mode = interpretation_mode,
    prompt_style = prompt_style,
    target_concept = target_concept,
    generate = generate,
    provider = provider,
    model = model
  )

  if (!generate) {
    return(
      .attach_condes_artifacts(
        x = final_prompt,
        continuous_profile = continuous_profile,
        interpretation_evidence = interpretation_evidence,
        semantic_facing_evidence = semantic_facing_evidence,
        prompt = final_prompt,
        response = NULL,
        condes_result = res_cd,
        condes_profile_result = res_cd,
        condes_settings = condes_settings,
        target_label = target_label
      )
    )
  }

  extra_args <- list(...)

  res_llm <- .call_llm_base(
    provider = provider,
    model = model,
    prompt = final_prompt,
    output = "df",
    llm_api_options = extra_args
  )

  res_llm$prompt <- final_prompt
  raw_response <- .condes_backend_response_text(
    res_llm
  )

  .attach_condes_artifacts(
    x = res_llm,
    continuous_profile = continuous_profile,
    interpretation_evidence = interpretation_evidence,
    semantic_facing_evidence = semantic_facing_evidence,
    prompt = final_prompt,
    response = raw_response,
    condes_result = res_cd,
    condes_profile_result = res_cd,
    condes_settings = condes_settings,
    target_label = target_label
  )
}
