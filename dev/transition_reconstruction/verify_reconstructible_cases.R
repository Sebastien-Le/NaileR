#!/usr/bin/env Rscript

# Read-only structural checks for the transition reconstruction working set.
# This script does not write files, modify source projects, or call an LLM.

repo <- normalizePath(Sys.getenv("NAILER_REPO", unset = "."), mustWork = TRUE)
stopifnot(requireNamespace("readxl", quietly = TRUE))
stopifnot(requireNamespace("FactoMineR", quietly = TRUE))

source_dir <- function(variable, default) {
  Sys.getenv(variable, unset = default)
}

irtsat_dir <- source_dir(
  "NAILER_IRTSAT_DIR",
  file.path("/Users/sebastienle/Documents/2024-2025",
            "Traitement de Données Enquêtes", "IRTSAT")
)
survey_dir <- source_dir(
  "NAILER_SURVEY_DIR",
  "/Users/sebastienle/Documents/2025-2026/Survey"
)
spise_dir <- source_dir(
  "NAILER_SPISE_DIR",
  "/Users/sebastienle/Documents/2025-2026/Spise"
)
mashs_dir <- source_dir(
  "NAILER_MASHS_DIR",
  "/Users/sebastienle/Documents/2023-2024/MASHS/quality"
)
if (file.exists(file.path(repo, "DESCRIPTION")) &&
    requireNamespace("devtools", quietly = TRUE)) {
  devtools::load_all(repo, quiet = TRUE)
}

check_package_cases <- function() {
  ns <- loadNamespace("NaileR")
  expected <- c(local_food = 573L, waste = 180L, nutriscore = 112L,
                quality = 55L, atomic_habit = 167L,
                atomic_habit_clust = 167L)
  for (nm in names(expected)) {
    obj <- getExportedValue("NaileR", nm)
    stopifnot(nrow(obj) == expected[[nm]], !anyNA(obj))
    cat(sprintf("package %-18s %d x %d\n", nm, nrow(obj), ncol(obj)))
  }
  cl <- getExportedValue("NaileR", "atomic_habit_clust")$clust
  stopifnot(identical(as.integer(table(cl)), c(84L, 13L, 70L)))
}

check_irtsat <- function() {
  path <- file.path(irtsat_dir, "data_536.csv")
  if (!file.exists(path)) return(cat("IRTSAT: source unavailable\n"))
  x <- read.csv(path, check.names = FALSE)
  stopifnot(nrow(x) == 536L, ncol(x) == 56L)
  cat(sprintf("IRTSAT data_536.csv %d x %d; candidate items 3:50 = %d\n",
              nrow(x), ncol(x), ncol(x[, 3:50, drop = FALSE])))
}

check_spise <- function() {
  path <- file.path(spise_dir, "data", "Bretons.xlsx")
  if (!file.exists(path)) return(cat("SPISE: source unavailable\n"))
  x <- readxl::read_excel(path)
  stopifnot(nrow(x) == 182L, ncol(x) == 81L)
  cat(sprintf("SPISE/Distinction Bretons subset %d x %d; candidate items = 48\n",
              nrow(x), ncol(x)))
}

check_survey <- function() {
  path <- file.path(
    survey_dir,
    "questionnaire___alimentation_territoire_et_distinction (2).xlsx"
  )
  if (!file.exists(path)) return(cat("Survey/Distinction: source unavailable\n"))
  x <- readxl::read_excel(path, sheet = 1, col_names = FALSE)
  cat(sprintf("SPISE/Distinction export first sheet: %d x %d; raw identifiers not printed\n",
              nrow(x), ncol(x)))
}

check_mashs <- function() {
  path <- file.path(mashs_dir, "perception de la qualité 2024.xlsx")
  if (!file.exists(path)) return(cat("MASHS: source unavailable\n"))
  raw <- readxl::read_excel(path)
  # The historical script removes the first two identifier columns, not rows.
  dat <- raw[, -c(1, 2), drop = FALSE]
  stopifnot(nrow(dat) == 55L, ncol(dat) == 9L)
  pca <- FactoMineR::PCA(dat, ncp = 6, graph = FALSE)
  hcpc <- FactoMineR::HCPC(pca, nb.clust = 3, graph = FALSE)
  cat(sprintf("MASHS logos %d x %d; HCPC sizes: %s\n", nrow(dat), ncol(dat),
              paste(as.integer(table(hcpc$data.clust$clust)), collapse = "/")))
}

check_package_cases()
check_irtsat()
check_survey()
check_spise()
check_mashs()
cat("read-only transition reconstruction checks: PASS\n")
