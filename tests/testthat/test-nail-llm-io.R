test_that("nail_prompt reads a single preview string exactly", {
  x <- "# Introduction\n\nA prompt."

  expect_identical(
    nail_prompt(x, print = FALSE),
    x
  )
})

test_that("nail_prompt handles named isolated previews", {
  x <- list(
    A = "Prompt A",
    B = "Prompt B"
  )

  expect_identical(
    nail_prompt(x, select = "B", print = FALSE),
    "Prompt B"
  )

  expect_identical(
    nail_prompt(x, select = 1, print = FALSE),
    "Prompt A"
  )

  expect_identical(
    nail_prompt(x, print = FALSE),
    x
  )
})

test_that("nail_response reads historical data-frame outputs", {
  x <- data.frame(
    model = "llama3",
    response = "Raw response",
    prompt = "Exact prompt",
    stringsAsFactors = FALSE
  )

  expect_identical(
    nail_prompt(x, print = FALSE),
    "Exact prompt"
  )

  expect_identical(
    nail_response(x, print = FALSE),
    "Raw response"
  )
})

test_that("nail_prompt and nail_response handle named lists of backend results", {
  x <- list(
    G1 = data.frame(
      response = "Response 1",
      prompt = "Prompt 1",
      stringsAsFactors = FALSE
    ),
    G2 = data.frame(
      response = "Response 2",
      prompt = "Prompt 2",
      stringsAsFactors = FALSE
    )
  )

  expect_identical(
    nail_prompt(x, select = "G2", print = FALSE),
    "Prompt 2"
  )

  expect_identical(
    nail_response(x, select = "G1", print = FALSE),
    "Response 1"
  )

  expect_identical(
    nail_response(x, print = FALSE),
    list(G1 = "Response 1", G2 = "Response 2")
  )
})

test_that("catdes semantic profiles take precedence over combined outer output", {
  x <- data.frame(
    model = "llama3",
    response = "Combined outer response",
    prompt = "Combined outer prompt",
    stringsAsFactors = FALSE
  )

  semantic_profiles <- list(
    groups = list(
      `1` = list(
        prompt = "Actual local prompt 1",
        response = "Actual local response 1"
      ),
      `2` = list(
        prompt = "Actual local prompt 2",
        response = "Actual local response 2"
      )
    )
  )

  attr(x, "semantic_profiles") <- semantic_profiles

  expect_identical(
    nail_prompt(x, select = "1", print = FALSE),
    "Actual local prompt 1"
  )

  expect_identical(
    nail_response(x, select = "2", print = FALSE),
    "Actual local response 2"
  )
})

test_that("catdes grounding exposes current-stage raw reviewer IO", {
  ground <- list(
    semantic_profiles = list(
      groups = list(
        `1` = list(
          prompt = "PASS 1 prompt",
          response = "PASS 1 response"
        )
      )
    ),
    grounding_prompts = list(
      `1` = "PASS 2 grounding prompt"
    ),
    grounded_profiles = list(
      `1` = list(
        raw_response = "PASS 1 response",
        backend_result = data.frame(
          response = '{"assertions":[]}',
          stringsAsFactors = FALSE
        )
      )
    )
  )
  class(ground) <- c("nail_catdes_ground", "list")

  expect_identical(
    nail_prompt(ground, select = "1", print = FALSE),
    "PASS 2 grounding prompt"
  )

  expect_identical(
    nail_response(ground, select = "1", print = FALSE),
    '{"assertions":[]}'
  )
})

test_that("nail_response fails clearly when no generation exists", {
  preview <- list(
    G1 = "Prompt 1",
    G2 = "Prompt 2"
  )

  expect_error(
    nail_response(preview, print = FALSE),
    "No LLM response is available"
  )
})

test_that("selection errors list available names", {
  x <- list(
    GroupA = "Prompt A",
    GroupB = "Prompt B"
  )

  expect_error(
    nail_prompt(x, select = "Missing", print = FALSE),
    'Available names are: "GroupA", "GroupB"'
  )

  expect_error(
    nail_prompt(x, select = 3, print = FALSE),
    "out of range"
  )
})

test_that("print argument is validated", {
  expect_error(
    nail_prompt("Prompt", print = NA),
    "`print` must be a single non-missing logical value"
  )
})

test_that("printing one item does not alter the returned text", {
  x <- list(A = "Line 1\nLine 2")

  printed <- capture.output(
    value <- nail_prompt(x, select = "A", print = TRUE)
  )

  expect_identical(value, "Line 1\nLine 2")
  expect_identical(printed, c("Line 1", "Line 2"))
})

test_that("printing several items adds only UI separators", {
  x <- list(
    A = "Prompt A",
    B = "Prompt B"
  )

  printed <- capture.output(
    value <- nail_prompt(x, print = TRUE)
  )

  expect_identical(
    value,
    list(A = "Prompt A", B = "Prompt B")
  )
  expect_true(any(grepl("NaileR prompt: A", printed, fixed = TRUE)))
  expect_true(any(grepl("NaileR prompt: B", printed, fixed = TRUE)))
  expect_true(any(grepl("Prompt A", printed, fixed = TRUE)))
  expect_true(any(grepl("Prompt B", printed, fixed = TRUE)))
})


test_that("nail_prompt integrates with a real catdes local-first preview", {
  preview <- nail_catdes(
    dataset = iris,
    num.var = 5,
    interpretation_mode = "standard",
    isolate.groups = TRUE,
    generate = FALSE
  )

  semantic_profiles <- attr(preview, "semantic_profiles", exact = TRUE)

  expect_true(is.list(semantic_profiles))
  expect_true("setosa" %in% names(semantic_profiles$groups))

  expect_identical(
    nail_prompt(preview, select = "setosa", print = FALSE),
    semantic_profiles$groups$setosa$prompt
  )

  expect_error(
    nail_response(preview, select = "setosa", print = FALSE),
    "No LLM response is available"
  )
})

test_that("public LLM IO helpers are exported", {
  expect_true("nail_prompt" %in% getNamespaceExports("NaileR"))
  expect_true("nail_response" %in% getNamespaceExports("NaileR"))
})


test_that("canonical llm_io contract has priority over historical storage", {
  x <- data.frame(
    prompt = "Historical prompt",
    response = "Historical response",
    stringsAsFactors = FALSE
  )

  attr(x, "llm_io") <- .new_nail_llm_io(
    stage = "interpretation",
    prompts = list(A = "Canonical prompt"),
    responses = list(A = "Canonical response")
  )

  expect_identical(
    nail_prompt(x, select = "A", print = FALSE),
    "Canonical prompt"
  )

  expect_identical(
    nail_response(x, select = "A", print = FALSE),
    "Canonical response"
  )
})

test_that("canonical llm_io can be stored as an object component", {
  x <- list(
    llm_io = .new_nail_llm_io(
      stage = "interpretation",
      prompts = list(Dim1 = "Dimension prompt"),
      responses = list(Dim1 = "Dimension response")
    )
  )

  expect_identical(
    nail_prompt(x, select = "Dim1", print = FALSE),
    "Dimension prompt"
  )

  expect_identical(
    nail_response(x, select = "Dim1", print = FALSE),
    "Dimension response"
  )
})

test_that("canonical llm_io constructor normalizes scalar IO", {
  io <- .new_nail_llm_io(
    stage = "interpretation",
    prompts = "Prompt",
    responses = "Response"
  )

  expect_identical(io$stage, "interpretation")
  expect_identical(io$prompts, list(`1` = "Prompt"))
  expect_identical(io$responses, list(`1` = "Response"))
})
