# NaileR — CORE 5 / TEXTUAL finalization review

**Date:** 2026-10-16  
**Status:** **TECHNICALLY FINALIZED — APPROVED FOR CORE 5 CLOSEOUT**, based on analyst-accepted code review and operational evidence. Not a release-wide R CMD check certification.  
**Code commit:** [`5ab8feb29685c81c9916ad71368ac7d2602142d5`](https://github.com/Sebastien-Le/NaileR/commit/5ab8feb29685c81c9916ad71368ac7d2602142d5)  
**Review branch:** `dev-core5-textual-integration-20261016`  
**Initial audit:** [`CORE5_TEXTUAL_INTEGRATION_REVIEW.md`](CORE5_TEXTUAL_INTEGRATION_REVIEW.md)  
**Frozen assembly:** [`CORE5_TEXTUAL_CLASSIC_IMPLEMENTATION_SPEC.md`](CORE5_TEXTUAL_CLASSIC_IMPLEMENTATION_SPEC.md)  
**Approved editorial source:** [`TEXTUAL_MODULAR_PROMPT.md`](reading_review/TEXTUAL_MODULAR_PROMPT.md)

## Final implementation contract

The approved `reading`, `interpretation`, `local_task` and classic six-field `output` scientific blocks are integrated literally into the classic `nail_textual()` route. `compact` reuses the same approved scientific wording, preserving its public option and any otherwise compatible runtime formatting. The group label is explicitly injected into the local task; `isolate.groups = FALSE` **combines local interpretations without a new global LLM analysis**.

Canonical `textual_evidence`, original-source-row `TXT%06d` identifiers, `interpretation_input`, sampled prompt texts, `textual_profiles`, field-name parser contracts, `llm_io`, `nail_evidence()`, `nail_prompt()`, `nail_response()`, custom context/request/conclusion and compatibility objects remain in place. `text_role` varies **Data-section labels** (`Responses`, `Comments`, `Verbatims`) without changing the approved scientific reading or mechanical evidence. `nail_textual_prep()` retains its **distinct preparatory output** and was smoke-tested with and without LLM-generated verbatim cues, separate from mechanically selected excerpts. `nail_catdes_textual()` was not refactored.

## Operational review, with provenance

Codex ran local checks and real Ollama `mistral-small3.2` trials; the analyst supplied review archives, which were examined in conversation. The GitHub closeout process **did not independently execute** R tests or LLM calls. Final local report after two surgical corrections:

| Gate | Reported result |
| --- | --- |
| Targeted TEXTUAL tests | **194 PASS, 0 FAIL, 0 WARN** |
| Whole `devtools::test()` suite | **1,396 PASS, 0 FAIL, 0 WARN, 0 SKIP** |
| `git diff --check`, staged check | Clean |
| Earlier real `mistral-small3.2` local run | 2/2 profiles parsed |
| Earlier real `mistral-small3.2` combined local-first run | 4/4 profiles parsed, 4 independent calls |
| Group with no nonempty text | `no_texts`; no model call |
| `fabric` operational scenario correction | `num.var = 4L`, `num.text = 3L`; real `Description` comments, groups `0` and `1` |
| Reported evidence invariance | `TRUE` in six offline conditions |
| `text_role` option | Three Data labels vary, canonical text evidence/IDs unchanged |
| PREP regression | Mock-based `generate = TRUE`, cues on/off; distinct preparatory fields retained |
| `tools::checkRd()` | OK |
| `devtools::check(document = FALSE)` | **NOT COMPLETED**: vignette reconstruction blocked by missing **Pandoc**, after resolving a prior `processx` environment issue |

**Important qualification:** The six real Ollama outputs were obtained *before* the final `fabric` offline-example and `text_role` Data-label correction. The later changes were checked through offline previews and tests; no unnecessary claim of rerun model experiments should be made.

## Accepted scientific limits

Qualitative thematic coherence is **not** a statistical measure. A group with only one textual observation can sometimes be called `strong` by the LLM, which **does not establish group-level consensus**. This is an accepted non-blocking model-interpretation limitation, not a reason to fabricate a new parser category or replace `strong` with a mechanical value. A successfully parsed record certifies output structure and text-ID validity, **not substantive truth**. Expert review should check negations, nuanced statements, tensions, minority positions, prevalence/consensus claims and invented quotations. Two distinct outputs — classic profiles vs PREP summaries — must remain separate.

## Git closeout and subsequent order

The implementation commit contains **only** `R/nail_textual.R`, `R/nail_textual_semantic.R`, `man/nail_textual.Rd`, and `tests/testthat/test-textual-semantic-rebuild.R`. Local `dev/operational_validation/` artifacts and `tests/testthat/Rplots.pdf` remain untracked and uncommitted; **do not delete them implicitly**.

The analyst has defined the next sequence: (1) finalize the two composed functions **`nail_qda_space()`**, then **`nail_catdes_textual()`**; (2) conduct a global architecture audit asking whether the seven functions constitute an extensible evidence-grounded interpretation framework versus a set of similar standalone implementations; (3) operationally validate README, vignette and Rd examples; (4) systematically assess local Ollama versus external Gemini/other provider choices, privacy, quality, reliability, reproducibility and cost. Do **not** refactor the common architecture ahead of this audit. Do not claim package release readiness without a completed environment-supported package check.

**CORE 5 gate:** all five fundamental functions have been technically completed and accepted for progression. The narrower CORE 5 feature freeze may now transition to exactly the two composed functions. Broader refactoring or unrelated development remains deferred until explicit scientific/architectural decisions.
