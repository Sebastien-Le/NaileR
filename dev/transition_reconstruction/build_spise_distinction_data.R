#!/usr/bin/env Rscript

# Build the de-identified 48-item teaching object for the SPISE / Distinction
# study.  The source files are not modified and no score or classification is
# reconstructed here.

repo <- normalizePath(
  Sys.getenv("NAILER_REPO", unset = "."),
  mustWork = TRUE
)
source_path <- Sys.getenv(
  "NAILER_SPISE_ITEMS_XLSX",
  unset = file.path(
    "/Users/sebastienle/Documents/2025-2026/Spise",
    "data",
    "Bretons_no_NA.xlsx"
  )
)
stopifnot(file.exists(source_path))
if (!requireNamespace("readxl", quietly = TRUE)) {
  stop("Package 'readxl' is required to build the SPISE teaching object.")
}

raw <- readxl::read_excel(source_path)
stopifnot(nrow(raw) == 181L, ncol(raw) == 81L)

item_source_names <- names(raw)[2:49]
item_names <- c(
  "origin_geographic_origin_attention",
  "processed_food_origin_attention",
  "recognize_local_label",
  "know_local_producers_or_brands",
  "prefer_food_within_100km",
  "choose_local_or_france_label",
  "avoid_imported_fruit_vegetables",
  "effort_local_processed_food",
  "buy_amap_farm_shop",
  "buy_direct_from_producer",
  "subscribe_local_producer_basket",
  "reduced_supermarket_purchases",
  "visit_market_weekly",
  "prefer_small_food_shops",
  "choose_place_near_production",
  "know_local_market_sellers",
  "know_local_food_actors",
  "know_regional_food_products",
  "informed_about_local_food_issues",
  "know_local_food_policy",
  "buy_from_territory_respecting_producers",
  "willing_to_pay_more_local_producer",
  "recommend_local_producers_products",
  "participated_producer_support_action",
  "know_seasonal_fruit_vegetables",
  "choose_seasonal_food",
  "avoid_out_of_season_imports",
  "consult_seasonal_calendars",
  "consider_ecological_impact",
  "limit_overpackaged_food",
  "prefer_organic_food",
  "reduce_intensive_livestock_meat",
  "local_food_affordable",
  "adapted_purchases_without_extra_cost",
  "know_local_affordable_solutions",
  "easy_access_to_local_food",
  "pay_attention_to_local_food_price",
  "know_local_food_aid",
  "participated_solidarity_food_shop",
  "support_solidarity_food_schemes",
  "participated_local_food_event",
  "volunteer_local_food_organization",
  "recommend_local_food_to_relatives",
  "share_local_food_information",
  "food_as_social_transformation_lever",
  "vote_or_campaign_for_territorial_food",
  "value_local_food_sovereignty",
  "support_local_food_in_public_policies"
)
stopifnot(length(item_source_names) == 48L, length(item_names) == 48L)

dimensions <- rep(
  c(
    "Geographical origin",
    "Procurement modes",
    "Local territory and actors",
    "Environment, seasonality and ecology",
    "Accessibility and social justice",
    "Engagement and civic participation"
  ),
  each = 8L
)
scale_levels <- c(
  "Strongly disagree",
  "Disagree",
  "Neither agree nor disagree",
  "Agree",
  "Strongly agree"
)

items <- raw[2:49]
names(items) <- item_names
for (j in seq_along(items)) {
  values <- suppressWarnings(as.numeric(items[[j]]))
  stopifnot(all(is.finite(values)), all(values %in% 1:5))
  items[[j]] <- ordered(scale_levels[values], levels = scale_levels)
}
spise_distinction_items_2025_2026 <- as.data.frame(items, stringsAsFactors = FALSE)
stopifnot(
  nrow(spise_distinction_items_2025_2026) == 181L,
  ncol(spise_distinction_items_2025_2026) == 48L,
  !anyNA(spise_distinction_items_2025_2026),
  all(vapply(spise_distinction_items_2025_2026, is.ordered, logical(1)))
)

dir.create(file.path(repo, "data"), showWarnings = FALSE)
save(
  spise_distinction_items_2025_2026,
  file = file.path(repo, "data", "spise_distinction_items_2025_2026.rda"),
  version = 2,
  compress = "xz"
)

dictionary <- data.frame(
  variable = item_names,
  dimension = dimensions,
  source_variable = item_source_names,
  response_scale = paste(scale_levels, collapse = " | "),
  missing_values = "None in Bretons_no_NA export",
  stringsAsFactors = FALSE
)
write.csv(
  dictionary,
  file.path(
    repo,
    "dev",
    "transition_reconstruction",
    "SPISE_DISTINCTION_48_ITEMS_DICTIONARY.csv"
  ),
  row.names = FALSE,
  fileEncoding = "UTF-8"
)

cat("Created SPISE / Distinction 48-item teaching dataset\n")
