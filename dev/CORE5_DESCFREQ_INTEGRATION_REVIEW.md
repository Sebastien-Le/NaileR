# CORE 5 / DESCFREQ — first runtime-integration audit

**Date:** 2026-10-15
**Status:** INITIAL STATIC AUDIT — SCIENTIFIC RUNTIME PROMPT NOT YET INTEGRATED; NO R TEST/LLM RUN PERFORMED IN THIS PASS.
**Working branch:** `dev-core5-descfreq-integration-20261015`.
**Scientific sources:** [DESCFREQ_MODULAR_PROMPT.md](reading_review/DESCFREQ_MODULAR_PROMPT.md) and [DESCFREQ_ASSEMBLY_REVIEW.md](reading_review/DESCFREQ_ASSEMBLY_REVIEW.md) (approved bilingual wording and six documentary assemblies).
**Scope:** `nail_descfreq()` only. Existing CATDES fixes are inherited by ancestry and remain pending a local post-fix R check.

## 1. What is already implemented

`R/nail_descfreq.R` (about 1,607 lines) has a complete statistical and generation pipeline:

- `FactoMineR::descfreq()` results normalized into canonical `frequency_profiles` with evidence IDs and metadata.
- Deterministic `interpretation_evidence` selection with `sample.pct`, `drop.negative` and `proba`.
- `semantic_facing_evidence` with explicit direction, row/global profile percentages, row counts and column totals.
- Offline `generate = FALSE`, live `generate = TRUE`, `llm_io` and shared `nail_evidence()`, `nail_prompt()`, `nail_response()`.
- Local versus joint scope via `isolate.groups`; joint `interpretation_mode = "description"` or `"comparison"`; `rows_are_ordered` and `explicit_row_labels` context flags.
- Existing `tests/testthat/test-descfreq-semantic-rebuild.R` covers canonical evidence, parameter invariance, selected facts, by.quali, LLM I/O and input validation (10 `test_that` blocks in the consulted file).

These are *static observations about current code*, not an independent confirmation of all edge cases.

## 2. Confirmed gap against the approved scientific blocks

The actual default prompt still comes from:

- `build_request_descfreq()` — lengthy legacy local, joint-description and joint-comparison instructions.
- `build_conclusion_descfreq()` — numbered summaries with a mandatory **Quarto Markdown** requirement.
- `build_guide_descfreq()` — a legacy introduction-embedded reading that calls columns **attributes**, rather than consistently using the approved **row/column/count/profile** terminology.
- `get_prompt_descfreq()` — `build_standard_prompt()` assembly with guide prepended to user introduction, not the approved dedicated `reading`, `interpretation`, identity, task and editable `output` blocks.

The approved scientific operational language in `DESCFREQ_MODULAR_PROMPT.md` is **not yet integrated**. Changing the statistical engine is unnecessary and out of scope.

## 3. Six scientific combinations to protect

The accepted documentary combinations are:

| Row identity | Scope/task |
| --- | --- |
| observed/standard | local |
| observed/standard | joint description |
| observed/standard | joint comparison |
| constructed/latent | local |
| constructed/latent | joint description |
| constructed/latent | joint comparison |

The current runtime only exposes `interpretation_mode = description/comparison` (joint task), `isolate.groups`, and `explicit_row_labels` (substantive names already given, no renaming). **It has no independent observed/constructed identity parameter.** `explicit_row_labels = FALSE` does NOT logically imply a constructed group; it may also mean that an observed row is represented by a technical label. Do not silently conflate these concepts. A backwards-compatible identity-routing choice needs a distinct, explicitly approved implementation decision.

`rows_are_ordered` is independent context; do not infer statistically tested gradients from row order alone.

## 4. Proposed narrow integration order (not yet executed)

1. Freeze current data contract and representative raw prompt and evidence for local, joint-description and joint-comparison routes (both `explicit_row_labels` states, ordered/unordered rows). Verify the current tests and output/API requirements.
2. Compare existing rendered text against each exact scientific approved block. Add internal approved English `reading`, `interpretation` and `output` helpers, protecting analyst `introduction`, `request`, `conclusion` and any non-negotiable backend/parser contracts.
3. Resolve observed-vs-constructed identity **without silently inferring it from** `explicit_row_labels`. Maintain backward compatibility and seek an explicit design decision if adding a public option is truly needed.
4. Assemble local/joint-description/joint-comparison `task` blocks conditionally and avoid legacy duplication; preserve statistical evidence and `llm_io`.
5. Add frozen independent text tests, six-way prompt identity/task checks, exact prompt inspection, canonical evidence invariance, real Ollama generations, targeted/full suite, full `R CMD check`, scoped commit/push.
6. Use realistic contingency tables, including an observed table with substantive row labels, an externally constructed cluster table, a sparse or negated-column case, an ordered-row test, and a heterogeneous case.

**Important interpretation safeguards:** global profile, not pairwise row significance; overrepresentation is not majority; counts need not represent distinct individuals; no column-column, respondent-level or causal association is established by `descfreq()`.

## 5. Release gate

DESCFREQ is *not* technically finalized by this audit. No DESCFREQ R source, tests or man page were changed. Avoid any work on QDA, TEXTUAL or secondary analyses until the DESCFREQ gate is finished and documented.
