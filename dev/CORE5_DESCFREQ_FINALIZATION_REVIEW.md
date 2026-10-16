# NaileR — CORE 5 / DESCFREQ finalization review

**Date:** 2026-10-16  
**Status:** **TECHNICALLY FINALIZED FOR CORE-FIVE PROGRESSION** — NOT a release-level `R CMD check` certificate.  
**Implementation commit:** `5621473bf3ae3641293ac938f89f90636cde3a6f` on `dev-core5-descfreq-integration-20261015`.  
**Scientific authority:** `dev/reading_review/DESCFREQ_MODULAR_PROMPT.md` and `dev/reading_review/DESCFREQ_ASSEMBLY_REVIEW.md` (approved 2026-10-14).

## Decision and scope

The analyst explicitly accepted technical closeout on 2026-10-16 after scientific re-reading of two iterative operational archives, a final label-identity correction, real LLM examples and the test results below. This approves proceeding to the next core-five function, `nail_qda()`, **not** declaring the entire R package release-ready. This review documents reported local execution, independently inspected committed code, and the outstanding limitation separately.

## Implemented runtime and compatibility (GitHub-verified)

- The runtime builds discrete approved `reading`, `interpretation`, row-`identity`, local/description/comparison `task`, `evidence` and `output` blocks; the new default has no mandatory Quarto format.
- User `introduction`, `request` and `conclusion` are passed as their own sections and retained; historical prompt-helper functions still exist but are not used in the new default assembly.
- New `row_identity_mode = c("auto", "standard", "latent")` distinguishes observed rows from constructed groups. `auto` retains the established default, remaining neutral when no explicit labels are supplied. Identity is independent of `isolate.groups` and `interpretation_mode = description/comparison`.
- The new public option is placed **after `...`**, so is name-only; prior positional `generate` calls retain their argument positions. A focused regression test exercises a complete historical positional call with a mocked LLM response.
- With `row_identity_mode = "latent", explicit_row_labels = TRUE`, the runtime explicitly says: preserve the analyst-supplied identifier/label exactly and do not propose a replacement name. A new focused regression test checks both local and joint prompts; with the flag false, an evidence-supported descriptive name may be proposed.
- All displayed rows remain explicitly identified, even when their prompt selection yields zero evidence; zero selected markers is not evidence of equality with the global profile or of no statistical deviation.
- Final commit contains exactly `R/nail_descfreq.R`, `man/nail_descfreq.Rd` and `tests/testthat/test-descfreq-semantic-rebuild.R`. No other runtime API or common accessor was intentionally changed.

## Statistical and epistemic boundary

`FactoMineR::descfreq()`, canonical `frequency_profiles`, `interpretation_evidence`, semantic-facing evidence and `nail_evidence()` were retained, rather than refactored. The code diff inspection and Codex's offline comparison support invariance across interpretation-only options. The row-to-global reference is not a direct pairwise row test; statistical overrepresentation is not synonymous with prevalence or a majority. Column counts need not represent distinct persons. The LLM narrative has no authority to establish additional tests, associations or causal relationships.

## Operational validation and provenance

Reported by Codex and shared by the analyst (not independently executed by this reviewer in an R session):

| Check | Final result, 2026-10-16 |
| --- | --- |
| `devtools::load_all()` | OK |
| `devtools::test_active_file("tests/testthat/test-descfreq-semantic-rebuild.R")` | **91 PASS, 0 FAIL, 0 WARN** |
| `devtools::test()` | **1,352 PASS, 0 FAIL, 0 WARN** |
| `git diff --check` | OK |
| `devtools::check(document = FALSE)` | **NOT COMPLETED**: `processx` failed at `.onLoad` (`Operation not permitted`) before package construction |

Six combinations (standard/latent × local/joint-description/joint-comparison) were checked with `generate = FALSE`. Positional `generate`, `auto`, analyst-supplied label protections, global missing-evidence rows and unchanged canonical evidence were covered by tests. Realistic example tables included observed product categories, constructed clusters, ordered rows, rare/negated columns and sparse rows. Earlier work included actual Ollama `mistral-small3.2` generation; follow-up label and positional changes did not require another generation campaign. Local operational archives remain untracked and were not published as part of this code commit.

## Residual risks and release gate

Real LLM outputs sometimes claimed statistically significant differences between rows without direct tests; conflated overrepresentation with a majority; or overweighted rare attributes and invented desirability/causality. The underlying R evidence remained distinct from such unsupported narrative. These limitations are accepted as **non-blocking for scoped technical progression**, while expert review and provenance of LLM output remain necessary.

**Prior to package release:** complete `R CMD check` successfully in unrestricted RStudio or equivalent build environment, and review any resulting errors/warnings/notes. Do not report a clean check on the basis of this Codex run. The older `dev/CORE5_DESCFREQ_INTEGRATION_REVIEW.md` remains an intentionally historical pre-integration audit; subsequent statuses supersede its initial gap assessment.

## Git handoff

The analyst reported a successful push of implementation commit `5621473bf3ae3641293ac938f89f90636cde3a6f` to `origin/dev-core5-descfreq-integration-20261015`; verified the GitHub commit and that only three authorized implementation files changed. The integration branch will receive this review and progress documentation before a strict fast-forward to `dev-statistical-prompt-framework`. The next development branch starts from that integrated commit with QDA as the fourth core-five priority. Do not stage `tests/testthat/Rplots.pdf` or blanket-commit `dev/operational_validation/`.
