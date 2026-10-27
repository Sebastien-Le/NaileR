test_that("historical beard description example is an offline preview", {
  data(beard_cont, package = "NaileR")

  result <- nail_descfreq(
    dataset = beard_cont,
    interpretation_mode = "description",
    isolate.groups = TRUE,
    generate = FALSE
  )

  expect_equal(dim(beard_cont), c(8L, 335L))
  expect_equal(length(nail_prompt(result, print = FALSE)), 8L)
  expect_equal(
    attr(result, "descfreq_settings")$interpretation_mode,
    "description"
  )
  expect_true(length(nail_evidence(result)$evidence_registry$evidence_id) > 0L)
})

test_that("historical children comparison example is an offline preview", {
  data(children, package = "FactoMineR")
  children_table <- children[1:14, 1:5] |> t() |> as.data.frame()
  rownames(children_table) <- c(
    "No education", "Elementary school", "Middle school",
    "High school", "University"
  )

  result <- nail_descfreq(
    dataset = children_table,
    interpretation_mode = "comparison",
    isolate.groups = FALSE,
    generate = FALSE
  )

  expect_equal(dim(children_table), c(5L, 14L))
  expect_equal(length(nail_prompt(result, print = FALSE)), 1L)
  expect_equal(
    attr(result, "descfreq_settings")$interpretation_mode,
    "comparison"
  )
  expect_true(length(nail_evidence(result)$evidence_registry$evidence_id) > 0L)
})

test_that("Rorschach descriptions produce a deterministic frequency preview", {
  data(rorschach, package = "NaileR")

  expect_equal(dim(rorschach), c(600L, 5L))
  expect_equal(
    names(rorschach),
    c("Panel", "Inkblot", "Panelist", "Consumer", "Description")
  )
  expect_true(all(vapply(rorschach[1:4], is.factor, logical(1))))
  expect_true(is.character(rorschach$Description))
  expect_equal(nlevels(rorschach$Panel), 3L)
  expect_equal(nlevels(rorschach$Inkblot), 10L)
  expect_equal(nlevels(rorschach$Panelist), 20L)

  rorschach_terms <- c(
    "animal", "bat", "black", "butterfly", "color", "red"
  )
  rorschach_tokens <- strsplit(
    tolower(gsub("[^a-z]+", " ", rorschach$Description)),
    "\\s+"
  )
  rorschach_counts <- vapply(
    rorschach_terms,
    function(term) {
      vapply(
        rorschach_tokens,
        function(tokens) as.numeric(term %in% tokens),
        numeric(1)
      )
    },
    numeric(nrow(rorschach))
  )
  rorschach_table <- aggregate(
    rorschach_counts,
    by = list(Inkblot = rorschach$Inkblot),
    FUN = sum
  )
  rownames(rorschach_table) <- as.character(rorschach_table$Inkblot)
  rorschach_table$Inkblot <- NULL
  rorschach_table <- rorschach_table[
    , colSums(rorschach_table) > 0,
    drop = FALSE
  ]

  expect_equal(dim(rorschach_table), c(10L, 6L))
  expect_equal(rownames(rorschach_table), as.character(1:10))
  expect_true(all(rorschach_table >= 0))
  expect_true(all(rorschach_table == round(rorschach_table)))
  expect_true(all(colSums(rorschach_table) > 0))
  expect_equal(
    as.numeric(colSums(rorschach_table)),
    c(75, 42, 70, 27, 68, 25)
  )

  result <- nail_descfreq(
    dataset = rorschach_table,
    introduction = paste(
      "Participants described ten Rorschach inkblots.",
      "This contingency table counts six observed descriptive terms",
      "at most once per description across the ten inkblots."
    ),
    request = paste(
      "Describe the perceptual characteristics associated with each inkblot",
      "using the retained frequency evidence. Distinguish inkblots based on",
      "their descriptions without inferring personality or causal mechanisms."
    ),
    proba = 0.05,
    interpretation_mode = "comparison",
    isolate.groups = FALSE,
    generate = FALSE
  )

  expect_equal(
    attr(result, "descfreq_settings")$interpretation_mode,
    "comparison"
  )
  expect_false(attr(result, "descfreq_settings")$generate)
  expect_length(nail_prompt(result, print = FALSE), 1L)
  expect_equal(nrow(nail_evidence(result)$evidence_registry), 22L)
  expect_error(
    nail_response(result, print = FALSE),
    "No LLM response is available"
  )
})

test_that("Rorschach panel A remains usable with the public TEXTUAL API", {
  data(rorschach, package = "NaileR")
  rorschach_A <- droplevels(rorschach[rorschach$Panel == "A", ])

  result <- nail_textual(
    rorschach_A,
    num.var = 2,
    num.text = 5,
    introduction = "Twenty people described ten Rorschach inkblots in panel A.",
    request = "Describe recurring perceptions while preserving variation in the responses.",
    isolate.groups = FALSE,
    generate = FALSE
  )

  expect_type(result, "character")
  expect_length(result, 1L)
  expect_length(nail_prompt(result, print = FALSE), 10L)
  expect_true(all(nzchar(nail_prompt(result, print = FALSE))))
  expect_error(
    nail_response(result, print = FALSE),
    "No LLM response is available"
  )
})
