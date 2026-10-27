#!/usr/bin/env Rscript

# Build the public Distinction teaching dataset from the audited private
# preparation. The original Excel file and all French response archives stay
# outside the package. No translation service is called here.

prep_dir <- Sys.getenv("NAILER_DISTINCTION_PREP", unset = "")
corrections_path <- Sys.getenv("NAILER_DISTINCTION_CORRECTIONS", unset = "")
output_path <- Sys.getenv(
  "NAILER_DISTINCTION_OUTPUT",
  unset = file.path("data", "distinction.rda")
)
dictionary_output <- Sys.getenv(
  "NAILER_DISTINCTION_DICTIONARY_OUTPUT",
  unset = file.path("dev", "transition_reconstruction", "DISTINCTION_VARIABLE_DICTIONARY.csv")
)

if (!nzchar(prep_dir) || !dir.exists(prep_dir)) {
  stop("Set NAILER_DISTINCTION_PREP to the audited private preparation directory.", call. = FALSE)
}
if (!nzchar(corrections_path) || !file.exists(corrections_path)) {
  stop("Set NAILER_DISTINCTION_CORRECTIONS to the reviewed correction CSV.", call. = FALSE)
}

closed_path <- file.path(prep_dir, "private", "distinction_closed_preparation_no_postal.rds")
originals_path <- file.path(prep_dir, "private", "open_text_originals.rds")
translations_path <- file.path(prep_dir, "private", "open_text_translations_full.rds")
dictionary_path <- file.path(prep_dir, "DISTINCTION_VARIABLE_DICTIONARY.csv")
stopifnot(file.exists(closed_path), file.exists(originals_path),
          file.exists(translations_path), file.exists(dictionary_path))

closed <- as.data.frame(readRDS(closed_path), stringsAsFactors = FALSE)
originals <- readRDS(originals_path)
translations <- readRDS(translations_path)
corrections <- read.csv(
  corrections_path,
  stringsAsFactors = FALSE,
  check.names = FALSE,
  fileEncoding = "UTF-8"
)
dictionary <- read.csv(
  dictionary_path,
  stringsAsFactors = FALSE,
  check.names = FALSE,
  fileEncoding = "UTF-8"
)

stopifnot(nrow(closed) == 1226L, ncol(closed) == 105L)
open_col <- grep("^quality_food_open_fr[[:space:]]*$", names(closed))
stopifnot(length(open_col) == 1L)
stopifnot(!any(grepl("postal|code|identifier|timestamp|ip|user", names(closed),
                      ignore.case = TRUE)))
stopifnot(nrow(originals) == nrow(closed))
stopifnot(isTRUE(all.equal(
  as.character(closed[[open_col]]),
  as.character(originals$original_fr),
  check.attributes = FALSE
)))
stopifnot(length(unique(translations$text_hash)) == 1189L)
stopifnot(length(unique(corrections$text_hash)) == nrow(corrections))

translation_by_hash <- setNames(translations$translation_en, translations$text_hash)
for (i in seq_len(nrow(corrections))) {
  h <- corrections$text_hash[i]
  source_text <- originals$original_fr[originals$text_hash == h &
    !is.na(originals$original_fr)]
  current <- translations$translation_en[translations$text_hash == h]
  stopifnot(length(source_text) >= 1L, length(unique(source_text)) == 1L)
  stopifnot(identical(as.character(source_text[[1L]]), corrections$original_fr[i]))
  stopifnot(length(current) == 1L)
  stopifnot(identical(as.character(current[[1L]]), corrections$current_translation_en[i]))
  translation_by_hash[[h]] <- corrections$proposed_translation_en[i]
}

translated_open <- unname(translation_by_hash[originals$text_hash])
stopifnot(length(translated_open) == nrow(closed))
stopifnot(sum(!is.na(translated_open)) == 1225L)
stopifnot(all(nzchar(trimws(translated_open[!is.na(translated_open)]))))

distinction <- closed
names(distinction)[open_col] <- "quality_food_open"
distinction[[open_col]] <- translated_open
stopifnot(nrow(distinction) == 1226L, ncol(distinction) == 105L)
stopifnot(!"residential_postal_code" %in% names(distinction))
stopifnot(!"quality_food_open_fr" %in% names(distinction))
stopifnot(any(distinction$quality_food_open == ".", na.rm = TRUE))
stopifnot(any(vapply(distinction, is.ordered, logical(1))))

dir.create(dirname(output_path), recursive = TRUE, showWarnings = FALSE)
save(distinction, file = output_path, compress = "xz", version = 2)

# Publish a dictionary for the 105 final columns only. Removed export
# metadata, exact postal code and their source modalities are not included.
keep <- !is.na(dictionary$english_name) &
  dictionary$english_name != "residential_postal_code" &
  dictionary$output_class != "removed"
dictionary_public <- dictionary[keep, , drop = FALSE]
dictionary_public$english_name[dictionary_public$english_name == "quality_food_open_fr"] <-
  "quality_food_open"
dictionary_public$translation_status[
  dictionary_public$english_name == "quality_food_open"
] <- "translated locally; human review required"
dictionary_public$modalities_english[
  dictionary_public$english_name == "quality_food_open"
] <- "free English text; one missing response"
stopifnot(nrow(dictionary_public) == 105L)
stopifnot(!any(grepl("postal", dictionary_public$english_name, ignore.case = TRUE)))
dir.create(dirname(dictionary_output), recursive = TRUE, showWarnings = FALSE)
write.csv(dictionary_public, dictionary_output, row.names = FALSE, fileEncoding = "UTF-8")

cat(sprintf(
  "Built %s: %d rows x %d columns; %d non-missing English open responses; %d dictionary rows.\n",
  output_path, nrow(distinction), ncol(distinction),
  sum(!is.na(distinction$quality_food_open)), nrow(dictionary_public)
))
