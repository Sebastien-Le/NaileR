test_that("historical CONDES examples remain reproducible offline", {
  data(decathlon, package = "FactoMineR")
  standard <- nail_condes(
    decathlon,
    num.var = 12,
    interpretation_mode = "standard",
    generate = FALSE
  )
  pca <- FactoMineR::PCA(decathlon[, 1:10], graph = FALSE)
  latent <- nail_condes(
    data.frame(Dim1 = pca$ind$coord[, 1], decathlon[, 1:10]),
    num.var = 1,
    interpretation_mode = "latent",
    target_label = "Dim1",
    generate = FALSE
  )

  expect_true(nrow(nail_evidence(standard)$evidence_registry) > 0L)
  expect_true(nrow(nail_evidence(latent)$evidence_registry) > 0L)
  expect_true(nzchar(nail_prompt(standard, print = FALSE)))
  expect_true(nzchar(nail_prompt(latent, print = FALSE)))
})

test_that("Agri and Glossophobia use their documented ACM partitions", {
  data(agri_studies, package = "NaileR")
  agri_mca <- FactoMineR::MCA(agri_studies, quali.sup = 39:42, graph = FALSE)
  agri <- nail_condes(
    data.frame(Dim1 = agri_mca$ind$coord[, 1], agri_studies),
    num.var = 1,
    interpretation_mode = "latent",
    target_label = "Dim1",
    generate = FALSE
  )

  data(glossophobia, package = "NaileR")
  gloss_mca <- FactoMineR::MCA(glossophobia, quali.sup = 26:41, graph = FALSE)
  gloss <- nail_condes(
    data.frame(Dim1 = gloss_mca$ind$coord[, 1], glossophobia),
    num.var = 1,
    interpretation_mode = "latent",
    target_label = "Dim1",
    generate = FALSE
  )

  expect_equal(dim(agri_studies), c(53L, 42L))
  expect_equal(dim(glossophobia), c(139L, 41L))
  expect_true(nrow(nail_evidence(agri)$evidence_registry) > 0L)
  expect_true(nrow(nail_evidence(gloss)$evidence_registry) > 0L)
})

test_that("Beard AFC example uses row profiles rather than raw rows", {
  data(beard_cont, package = "NaileR")
  beard_ca <- FactoMineR::CA(beard_cont, graph = FALSE)
  profiles <- sweep(as.matrix(beard_cont), 1, rowSums(beard_cont), "/")
  result <- nail_condes(
    data.frame(Dim1 = beard_ca$row$coord[, 1], profiles, check.names = FALSE),
    num.var = 1,
    interpretation_mode = "latent",
    target_label = "Dim1",
    generate = FALSE
  )

  expect_equal(dim(beard_cont), c(8L, 335L))
  expect_equal(dim(profiles), c(8L, 335L))
  expect_true(all(abs(rowSums(profiles) - 1) < 1e-12))
  expect_true(nrow(nail_evidence(result)$evidence_registry) > 0L)
})

test_that("local_food keeps 45 active and 18 supplementary variables", {
  data(local_food, package = "NaileR")
  food_mca <- FactoMineR::MCA(
    local_food,
    quali.sup = 46:63,
    ncp = 100,
    graph = FALSE
  )
  result <- nail_condes(
    data.frame(Dim1 = food_mca$ind$coord[, 1], local_food),
    num.var = 1,
    interpretation_mode = "latent",
    target_label = "Dim1",
    target_concept = "sustainable food-system representations",
    generate = FALSE
  )

  expect_equal(ncol(local_food), 63L)
  expect_equal(ncol(local_food[, 1:45]), 45L)
  expect_equal(ncol(local_food[, 46:63]), 18L)
  expect_true(nrow(nail_evidence(result)$evidence_registry) > 0L)
})

test_that("IRTSAT uses the 48-item instrument without joining profile rows", {
  data(irtsat_items_2024_2025, package = "NaileR")
  item_mca <- FactoMineR::MCA(
    irtsat_items_2024_2025,
    ncp = 5,
    graph = FALSE
  )
  result <- nail_condes(
    data.frame(
      Dim1 = item_mca$ind$coord[, 1],
      irtsat_items_2024_2025,
      check.names = FALSE
    ),
    num.var = 1,
    interpretation_mode = "latent",
    target_label = "Dim1",
    target_concept = "local-food representations",
    generate = FALSE
  )

  expect_equal(dim(irtsat_items_2024_2025), c(541L, 48L))
  expect_equal(sum(is.na(irtsat_items_2024_2025)), 14L)
  expect_true(nrow(nail_evidence(result)$evidence_registry) > 0L)
})

test_that("Distinction uses a documented assertion subset", {
  data(distinction, package = "NaileR")
  active <- c(
    grep("^assertion_q17_", names(distinction), value = TRUE),
    grep("^assertion_q2[1-5]_", names(distinction), value = TRUE)
  )
  active_data <- distinction[, active, drop = FALSE]
  distinction_mca <- FactoMineR::MCA(active_data, ncp = 5, graph = FALSE)
  result <- nail_condes(
    data.frame(
      Dim1 = distinction_mca$ind$coord[, 1],
      active_data,
      check.names = FALSE
    ),
    num.var = 1,
    interpretation_mode = "latent",
    target_label = "Dim1",
    target_concept = "food-transition representations",
    generate = FALSE
  )

  expect_equal(nrow(distinction), 1226L)
  expect_equal(length(active), 47L)
  expect_false("quality_food_open" %in% active)
  expect_true(nrow(nail_evidence(result)$evidence_registry) > 0L)
})

test_that("Distinction semantic assertion labels preserve the statistics", {
  data(distinction, package = "NaileR")
  label_path <- system.file(
    "extdata", "distinction_assertion_labels.csv", package = "NaileR"
  )
  if (!nzchar(label_path) || !file.exists(label_path)) {
    label_path <- testthat::test_path(
      "..", "..", "inst", "extdata", "distinction_assertion_labels.csv"
    )
  }
  dictionary <- utils::read.csv(
    label_path,
    check.names = FALSE,
    stringsAsFactors = FALSE,
    fileEncoding = "UTF-8"
  )
  active <- c(
    grep("^assertion_q17_", names(distinction), value = TRUE),
    grep("^assertion_q2[1-5]_", names(distinction), value = TRUE)
  )
  rows <- match(active, dictionary$technical_name)
  labels <- dictionary$label_en[rows]
  french_labels <- dictionary$label_fr[rows]
  expect_length(active, 47L)
  expect_false(anyNA(rows))
  expect_length(unique(labels), 47L)
  expect_true(all(nzchar(labels)))
  expect_true(all(dictionary$translation_status[rows] %in%
                    c("proposed", "proposed_review")))
  expect_false(any(labels %in% active))

  technical_data <- distinction[, active, drop = FALSE]
  semantic_data <- technical_data
  names(semantic_data) <- labels
  technical_mca <- FactoMineR::MCA(technical_data, ncp = 5, graph = FALSE)
  semantic_mca <- FactoMineR::MCA(semantic_data, ncp = 5, graph = FALSE)
  expect_equal(technical_mca$eig, semantic_mca$eig, tolerance = 1e-12)
  expect_true(isTRUE(all.equal(
    unname(technical_mca$ind$coord),
    unname(semantic_mca$ind$coord),
    tolerance = 1e-12,
    check.attributes = FALSE
  )))
  expect_true(isTRUE(all.equal(
    unname(technical_mca$ind$contrib),
    unname(semantic_mca$ind$contrib),
    tolerance = 1e-12,
    check.attributes = FALSE
  )))
  expect_true(isTRUE(all.equal(
    unname(technical_mca$ind$cos2),
    unname(semantic_mca$ind$cos2),
    tolerance = 1e-12,
    check.attributes = FALSE
  )))
  expect_true(isTRUE(all.equal(
    unname(technical_mca$var$coord),
    unname(semantic_mca$var$coord),
    tolerance = 1e-12,
    check.attributes = FALSE
  )))
  expect_true(isTRUE(all.equal(
    unname(technical_mca$var$contrib),
    unname(semantic_mca$var$contrib),
    tolerance = 1e-12,
    check.attributes = FALSE
  )))
  expect_true(isTRUE(all.equal(
    unname(technical_mca$var$cos2),
    unname(semantic_mca$var$cos2),
    tolerance = 1e-12,
    check.attributes = FALSE
  )))

  technical_result <- nail_condes(
    data.frame(Dim1 = technical_mca$ind$coord[, 1], technical_data,
               check.names = FALSE),
    num.var = 1,
    interpretation_mode = "latent",
    target_label = "Dim1",
    target_concept = "food-transition representations",
    generate = FALSE
  )
  semantic_result <- nail_condes(
    data.frame(Dim1 = semantic_mca$ind$coord[, 1], semantic_data,
               check.names = FALSE),
    num.var = 1,
    interpretation_mode = "latent",
    target_label = "Dim1",
    target_concept = "food-transition representations",
    generate = FALSE
  )
  technical_evidence <- nail_evidence(technical_result)
  semantic_evidence <- nail_evidence(semantic_result)
  registry_columns <- c(
    "family", "category", "direction", "statistic", "statistic_name",
    "p_value", "rank"
  )
  expect_true(isTRUE(all.equal(
    technical_evidence$evidence_registry[registry_columns],
    semantic_evidence$evidence_registry[registry_columns],
    tolerance = 1e-12,
    check.attributes = FALSE
  )))
  expect_equal(
    nrow(technical_evidence$evidence_registry),
    nrow(semantic_evidence$evidence_registry)
  )
  semantic_prompt <- nail_prompt(semantic_result, print = FALSE)
  expect_true(grepl("I systematically look at the geographical origin", semantic_prompt,
                    fixed = TRUE))
  expect_false(any(vapply(french_labels, grepl, logical(1),
                          x = semantic_prompt, fixed = TRUE)))
  expect_false(grepl("assertion_q17_", semantic_prompt, fixed = TRUE))
})
