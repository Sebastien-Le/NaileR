# CORE 5 / CATDES — operational finalization review

**Date:** 2026-10-15
**Status:** OPERATIONALLY VALIDATED BEFORE LAST EDITORIAL/PACKAGING FIXES; **post-fix local R test/check rerun pending**.
**Branch:** `dev-core5-catdes-finalization-20261015`.
**Original experimental source commit:** `1ce4b2526db2c00d600d910ef7de1a376c4456c6`.
**Approved scientific wording:** [CATDES_MODULAR_PROMPT.md](reading_review/CATDES_MODULAR_PROMPT.md).

## 1. Scope and operational evidence

Codex executed the four `standard`/`latent` × local/joint routes in a separate local Git worktree at `/private/tmp/nailer-catdes-finalization-20261015`, without changing R code. Real `ollama` / `mistral-small3.2` calls used temperature 0.2 and seed 20261015:

| Route | Data | LLM calls |
| --- | --- | ---: |
| standard, local | `iris` (`Species`) | 3 |
| standard, joint | `iris` (`Species`) | 1 |
| latent, local | `atomic_habit_clust` | 2 |
| latent, joint | `atomic_habit_clust` | 1 |

All 7 calls succeeded. Prompts preserved source grouping variable, observed categories or constructed identifiers, scope, analyst introduction and request. The local/joint and standard/latent contracts, canonical statistical invariance on tested options, and `nail_evidence()`, `nail_prompt()`, `nail_response()` were verified.

Codex reported: `devtools::test_active_file("tests/testthat/test-catdes-prompt-blocks.R")` **185 PASS / 0 FAIL / 0 WARN**, and `devtools::test()` **1299 PASS / 0 FAIL / 0 WARN**. Its own `devtools::check()` was blocked by process permissions (`processx: Operation not permitted`), without changing NaileR.

The analyst then ran the **complete** `devtools::check(pkg = "/private/tmp/nailer-catdes-finalization-20261015", document = FALSE)` from RStudio: **0 errors, 0 warnings, 2 NOTEs** (`.git` worktree metadata unexpectedly included in package build; system clock could not be verified). Vignettes, tests, package load and Rd checks succeeded.

**Limitations of LLM text:** Some `iris` outputs introduced ecological/adaptation hypotheses not established by CATDES; some constructed-group interpretations overextended from reported capabilities to confidence or lifestyle identity; global contrasts were descriptive, not pairwise-significance tests. These limits do not by themselves show a calculation or prompt-construction regression.

**Original local artifacts (not committed):** `dev/operational_validation/catdes_finalization_20261015/` under the worktree, including `catdes_operational_report.md`, prompts, responses, scripts and log. This report summarizes analyst-shared results; they are not independently rerun in this GitHub-only editing environment.

## 2. Minimal post-review corrections

The analyst authorized two corrections after reading the scientific operational report.

1. `R/nail_catdes.R`: removed two generic caveats about undisplayed variables/modalities from `.catdes_approved_reading_nail_catdes()`, to match the **exact previously approved** eight paragraphs in `CATDES_MODULAR_PROMPT.md`. No computations, selected facts, IDs, API, or statistical functions were modified.
2. `tests/testthat/test-catdes-prompt-blocks.R`: updated the frozen independent scientific reading reference and added regression assertions to prevent reintroducing the two unapproved statements.
3. `.Rbuildignore`: added `^\\.git$` so the special worktree `.git` file/directory is excluded from R builds.

Static GitHub verification confirmed all eight approved reading paragraphs are included verbatim, both extra sentences are absent, and the build-ignore rule is present. **This does not constitute a rerun of R tests or `R CMD check` on the edited branch.**

## 3. Finalization gate

**Pending, before declaring CATDES fully finalized or merging these commits:**

```r
pkg <- "/private/tmp/nailer-catdes-finalization-20261015"
devtools::load_all(pkg, quiet = TRUE)
devtools::test_active_file("tests/testthat/test-catdes-prompt-blocks.R")
devtools::test(pkg = pkg)
devtools::check(pkg = pkg, document = FALSE)
```

The script's current working directory must be the CATDES worktree when running `test_active_file()`, or the corresponding target file must be opened in RStudio with that package loaded. The separate worktree must first fetch and fast-forward to the new remote branch HEAD; **do not reset/delete untracked validation artifacts**.

Expected target: 0 errors, 0 warnings; the system-clock NOTE is environmental. Inspect the final R CMD build output to confirm the `.git` NOTE is gone. Record exact results, then update `PROJECT_STATE.md` / `dev/FINALIZATION_CORE5.md` and merge by fast-forward into `dev-statistical-prompt-framework`.

## 4. Scope control

The old `build_guide_catdes()` helper is not part of the modern CATDES prompt route and was not touched. Default request repetitions, alternative latent naming strategies, further model benchmarking and downstream `nail_catdes_textual()` remain deferred. No statistical or API redesign is authorized by this correction.
