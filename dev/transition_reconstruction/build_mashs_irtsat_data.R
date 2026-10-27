#!/usr/bin/env Rscript

# Build the two de-identified package datasets from the locally retained
# research exports. This script does not modify the original source files.
#
# Override the source paths when running on another machine:
# NAILER_MASHS_QSORT_RDATA and NAILER_IRTSAT_WORKSPACE.

repo <- normalizePath(
  Sys.getenv("NAILER_REPO", unset = "."),
  mustWork = TRUE
)
dir.create(file.path(repo, "data"), showWarnings = FALSE)

mashs_path <- Sys.getenv(
  "NAILER_MASHS_QSORT_RDATA",
  unset = file.path(
    "/Users/sebastienle/Documents/2023-2024/MASHS",
    "don_clust.rData"
  )
)
irtsat_path <- Sys.getenv(
  "NAILER_IRTSAT_WORKSPACE",
  unset = file.path(
    "/Users/sebastienle/Documents/2024-2025",
    "Traitement de Données Enquêtes",
    "IRTSAT",
    ".RData"
  )
)

stopifnot(file.exists(mashs_path), file.exists(irtsat_path))

# MASHS: the first 60 columns are questionnaire responses. The source
# analysis used columns 1:45 as active MCA variables and columns 46:63 as
# supplementary variables. The three demographic columns (61:63) are
# deliberately excluded from the package object; the four-level class is
# retained as the final column.
mashs_env <- new.env(parent = emptyenv())
load(mashs_path, envir = mashs_env)
stopifnot(exists("don_clust", envir = mashs_env, inherits = FALSE))
mashs_raw <- get("don_clust", envir = mashs_env)
stopifnot(
  is.data.frame(mashs_raw),
  nrow(mashs_raw) == 573L,
  ncol(mashs_raw) == 64L,
  identical(names(mashs_raw)[64], "clust")
)
mashs_food_system <- mashs_raw[, c(1:60, 64), drop = FALSE]
mashs_food_system$clust <- factor(
  as.character(mashs_food_system$clust),
  levels = c("1", "2", "3", "4")
)
stopifnot(
  nrow(mashs_food_system) == 573L,
  ncol(mashs_food_system) == 61L,
  !("ID" %in% names(mashs_food_system)),
  !anyNA(mashs_food_system),
  identical(as.integer(table(mashs_food_system$clust)),
            c(226L, 113L, 116L, 118L))
)
save(
  mashs_food_system,
  file = file.path(repo, "data", "mashs_food_system.rda"),
  version = 2,
  compress = "xz"
)

# IRTSAT: dta_gold is the frozen de-identified descriptor/class table and
# theta is the matching frozen IRT score vector in the same source workspace.
irtsat_env <- new.env(parent = emptyenv())
load(irtsat_path, envir = irtsat_env)
stopifnot(
  exists("dta_gold", envir = irtsat_env, inherits = FALSE),
  exists("theta", envir = irtsat_env, inherits = FALSE)
)
irtsat_raw <- get("dta_gold", envir = irtsat_env)
irtsat_theta <- get("theta", envir = irtsat_env)
stopifnot(
  is.data.frame(irtsat_raw),
  nrow(irtsat_raw) == 529L,
  ncol(irtsat_raw) == 35L,
  is.matrix(irtsat_theta),
  nrow(irtsat_theta) == nrow(irtsat_raw),
  ncol(irtsat_theta) == 1L,
  all(is.finite(irtsat_theta[, 1])),
  !anyNA(irtsat_raw)
)

irtsat_names <- c(
  "relationship_to_local_food",
  "region",
  "motivation_environmental_impact",
  "motivation_accessibility",
  "motivation_geographical_proximity",
  "motivation_nutritional_quality",
  "motivation_taste",
  "motivation_price",
  "motivation_support_producers",
  "motivation_eat_healthier",
  "motivation_limit_ecological_footprint",
  "motivation_rooted_in_territory",
  "motivation_reduce_intermediaries",
  "motivation_political_act",
  "motivation_none",
  "perception_reflex",
  "perception_effort",
  "perception_unattainable_ideal",
  "perception_constraint",
  "perception_passing_trend",
  "perception_admire_not_follow",
  "barrier_none",
  "barrier_dont_know_where",
  "barrier_habit",
  "barrier_information",
  "barrier_supply",
  "barrier_time",
  "barrier_price",
  "solution_financial_aid",
  "solution_signage",
  "solution_events",
  "solution_online_offers",
  "solution_producer_links",
  "solution_no_change"
)
stopifnot(length(irtsat_names) == 34L)
irtsat_2024_2025 <- irtsat_raw[, 1:34, drop = FALSE]
names(irtsat_2024_2025) <- irtsat_names
irtsat_2024_2025$IRT_score <- as.numeric(irtsat_theta[, 1])
irtsat_2024_2025$profile <- factor(
  as.character(irtsat_raw$cluster),
  levels = c(
    "désengagés territoriaux-1",
    "consommateurs distants-2",
    "impliqués pragmatiques-3",
    "militants territorialisés-4"
  ),
  labels = c(
    "Territorially disengaged-1",
    "Distant consumers-2",
    "Pragmatic involved consumers-3",
    "Territorial activists-4"
  )
)
relationship_labels <- c(
  "C’est central pour moi, je fais beaucoup d’efforts" =
    "It is central to me; I make a strong effort",
  "C’est important, mais ce n’est pas toujours simple" =
    "It is important, but not always easy",
  "J’y suis sensible, mais je n’agis pas beaucoup" =
    "I care about it, but I do not act much",
  "Je m’y intéresse peu ou pas" =
    "I have little or no interest in it"
)
old_relationship <- as.character(irtsat_2024_2025$relationship_to_local_food)
irtsat_2024_2025$relationship_to_local_food <- factor(
  unname(relationship_labels[old_relationship]),
  levels = unname(relationship_labels)
)
irtsat_2024_2025 <- irtsat_2024_2025[
  c("IRT_score", irtsat_names, "profile")
]
stopifnot(
  nrow(irtsat_2024_2025) == 529L,
  ncol(irtsat_2024_2025) == 36L,
  identical(names(irtsat_2024_2025)[c(1, ncol(irtsat_2024_2025))],
            c("IRT_score", "profile")),
  !anyNA(irtsat_2024_2025),
  identical(as.integer(table(irtsat_2024_2025$profile)),
            c(83L, 180L, 179L, 87L))
)
save(
  irtsat_2024_2025,
  file = file.path(repo, "data", "irtsat_2024_2025.rda"),
  version = 2,
  compress = "xz"
)

cat("Created mashs_food_system.rda and irtsat_2024_2025.rda\n")
