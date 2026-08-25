test_that("nail_evidence exposes canonical CATDES statistical profiles", {
  x <- nail_catdes(
    dataset = iris,
    num.var = 5,
    interpretation_mode = "standard",
    isolate.groups = TRUE,
    generate = FALSE
  )

  expected <- attr(
    x,
    "statistical_profiles",
    exact = TRUE
  )

  observed <- nail_evidence(x)

  expect_identical(
    observed,
    expected
  )
  expect_s3_class(
    observed,
    "statistical_profiles"
  )
})


test_that("nail_evidence selects one CATDES group by name or position", {
  x <- nail_catdes(
    dataset = iris,
    num.var = 5,
    interpretation_mode = "standard",
    isolate.groups = TRUE,
    generate = FALSE
  )

  evidence <- attr(
    x,
    "statistical_profiles",
    exact = TRUE
  )

  by_name <- nail_evidence(
    x,
    select = "setosa"
  )
  by_position <- nail_evidence(
    x,
    select = 1
  )

  expect_identical(
    by_name,
    evidence$groups[["setosa"]]
  )
  expect_identical(
    by_position,
    evidence$groups[[1L]]
  )
})


test_that("nail_evidence accepts direct CATDES preparation evidence", {
  raw <- FactoMineR::catdes(
    iris,
    num.var = 5,
    proba = 0.05
  )

  prepared <- nail_catdes_prep(
    x = raw
  )

  expect_identical(
    nail_evidence(prepared),
    prepared
  )

  expect_identical(
    nail_evidence(
      prepared,
      select = "setosa"
    ),
    prepared$groups[["setosa"]]
  )
})


test_that("nail_evidence prefers composed evidence over retained upstream evidence", {
  qda_space <- structure(
    list(
      axes = list(
        Dim1 = list(
          dimension = "Dim1",
          evidence = "axis evidence"
        )
      ),
      metadata = list(
        schema = "NaileR::qda_space_evidence"
      )
    ),
    class = c(
      "nail_qda_space_evidence",
      "list"
    )
  )

  product_profiles <- structure(
    list(
      products = list(
        P1 = list(
          product = "P1"
        )
      )
    ),
    class = c(
      "nail_qda_product_profiles",
      "list"
    )
  )

  x <- structure(
    list(),
    qda_space_evidence = qda_space,
    product_profiles = product_profiles
  )

  expect_identical(
    nail_evidence(x),
    qda_space
  )
  expect_identical(
    nail_evidence(
      x,
      select = "Dim1"
    ),
    qda_space$axes$Dim1
  )
})


test_that("nail_evidence exposes QDA product profiles", {
  profiles <- structure(
    list(
      products = list(
        A = list(
          product = "A",
          marker = "crunchy"
        ),
        B = list(
          product = "B",
          marker = "sweet"
        )
      ),
      evidence_registry = data.frame(
        evidence_id = character(0)
      ),
      settings = list(),
      metadata = list(
        schema = "NaileR::qda_product_profiles"
      )
    ),
    class = c(
      "nail_qda_product_profiles",
      "list"
    )
  )

  x <- structure(
    "prompt",
    product_profiles = profiles
  )

  expect_identical(
    nail_evidence(x),
    profiles
  )
  expect_identical(
    nail_evidence(
      x,
      select = "B"
    ),
    profiles$products$B
  )
})


test_that("nail_evidence exposes CONDES continuous profile", {
  profile <- structure(
    list(
      target = list(
        variable = "Dim1",
        index = 1L
      ),
      evidence_registry = data.frame(),
      settings = list(),
      metadata = list()
    ),
    class = c(
      "nail_condes_continuous_profile",
      "list"
    )
  )

  x <- structure(
    "prompt",
    continuous_profile = profile
  )

  expect_identical(
    nail_evidence(x),
    profile
  )
  expect_identical(
    nail_evidence(
      x,
      select = 1
    ),
    profile
  )
  expect_identical(
    nail_evidence(
      x,
      select = "Dim1"
    ),
    profile
  )

  expect_error(
    nail_evidence(
      x,
      select = "Dim2"
    ),
    'The available target is "Dim1"',
    fixed = TRUE
  )
})


test_that("nail_evidence textual group selection includes exact registered texts", {
  dat <- data.frame(
    group = factor(
      c("A", "A", "A", "B", "B")
    ),
    text = c(
      "first A response",
      "second A response",
      NA,
      "first B response",
      "second B response"
    ),
    stringsAsFactors = FALSE
  )

  x <- nail_textual(
    dataset = dat,
    num.var = 1,
    num.text = 2,
    sample.pct = 0.5,
    seed = 123,
    generate = FALSE
  )

  complete <- nail_evidence(x)
  selected <- nail_evidence(
    x,
    select = "A"
  )

  expect_s3_class(
    complete,
    "nail_textual_evidence"
  )
  expect_s3_class(
    selected,
    "nail_textual_group_evidence"
  )
  expect_identical(
    selected$text_ids,
    complete$groups$A$text_ids
  )
  expect_identical(
    selected$texts$text_id,
    complete$groups$A$text_ids
  )
  expect_identical(
    selected$texts$text,
    c(
      "first A response",
      "second A response"
    )
  )
})


test_that("nail_evidence exposes CATDES-textual contextualized evidence", {
  evidence <- structure(
    list(
      groups = list(
        G1 = list(
          group = "G1",
          statistical_anchor = list(
            factual_text = "fact"
          ),
          textual_enrichment = list(
            core_textual_profile = "text"
          )
        )
      ),
      settings = list(),
      metadata = list(
        schema = "NaileR::catdes_textual_evidence"
      )
    ),
    class = c(
      "nail_catdes_textual_evidence",
      "list"
    )
  )

  x <- structure(
    list(),
    contextualized_evidence = evidence
  )

  expect_identical(
    nail_evidence(x),
    evidence
  )
  expect_identical(
    nail_evidence(
      x,
      select = "G1"
    ),
    evidence$groups$G1
  )
})


test_that("nail_evidence rejects unknown selections clearly", {
  profiles <- structure(
    list(
      products = list(
        A = list(product = "A"),
        B = list(product = "B")
      )
    ),
    class = c(
      "nail_qda_product_profiles",
      "list"
    )
  )

  x <- structure(
    list(),
    product_profiles = profiles
  )

  expect_error(
    nail_evidence(
      x,
      select = "C"
    ),
    'Available product names are: "A", "B"',
    fixed = TRUE
  )

  expect_error(
    nail_evidence(
      x,
      select = 3
    ),
    "out of range",
    fixed = TRUE
  )

  expect_error(
    nail_evidence(
      x,
      select = 0
    ),
    "positive integer",
    fixed = TRUE
  )
})


test_that("nail_evidence does not fall back to interpretation evidence", {
  interpretation <- structure(
    list(
      groups = list(
        G1 = list()
      )
    ),
    class = c(
      "nail_catdes_interpretation_evidence",
      "list"
    )
  )

  x <- structure(
    list(),
    interpretation_evidence = interpretation
  )

  expect_error(
    nail_evidence(x),
    "No canonical NaileR evidence could be found",
    fixed = TRUE
  )
})


test_that("nail_evidence exposes DESCFREQ frequency profiles", {
  tab <- data.frame(
    sweet = c(40, 5),
    bitter = c(5, 40),
    row.names = c("A", "B")
  )

  x <- nail_descfreq(
    tab,
    isolate.groups = TRUE,
    generate = FALSE
  )

  expected <- attr(
    x,
    "frequency_profiles",
    exact = TRUE
  )

  expect_identical(
    nail_evidence(x),
    expected
  )

  expect_identical(
    nail_evidence(
      x,
      select = "A"
    ),
    expected$rows$A
  )
})
