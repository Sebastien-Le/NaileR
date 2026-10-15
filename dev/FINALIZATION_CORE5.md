# NaileR — CORE 5 finalization plan

**Decision date:** 2026-10-15
**Decision:** APPROVED by the analyst.
**Branch:** `dev-statistical-prompt-framework`.
**Authoritative status:** This scope and priority freeze supersedes the broader next-work priorities in `PROJECT_STATE.md` dated 2026-10-09. No R code changes were made when recording the decision.

## 1. Scientific boundary: FIVE main functions only

The only active analytical-development and finalization targets are:

| Function | Scientific question | Current evidence (as of 2026-10-15) | Remaining gates |
| --- | --- | --- | --- |
| `nail_condes()` | What characterizes an observed quantitative target or a constructed latent dimension, based on associations with other variables? | Evidence-first implementation present; approved bilingual modular wording and assembly simplifications in `dev/reading_review/CONDES_MODULAR_PROMPT.md`. | Integrate approved runtime wording; preserve statistics and user introduction/request; real-case prompt and LLM review; tests and checks. |
| `nail_catdes()` | What characterizes an observed class or latent cluster using quantitative and qualitative statistical associations? | Evidence-first implementation with canonical profiles; approved bilingual blocks and local/global assembly in `dev/reading_review/CATDES_MODULAR_PROMPT.md`. | Integrate approved runtime wording; verify grouping variable and group modality in rendered prompt; preserve canonical evidence, options and observed/latent semantics; real cases and tests. |
| `nail_descfreq()` | What do contingency-table row profiles reveal, in local description or supported comparison? | Operational testing on two tables reported 2026-10-09; approved bilingual modular blocks and six assemblies in `dev/reading_review/DESCFREQ_MODULAR_PROMPT.md` and `DESCFREQ_ASSEMBLY_REVIEW.md`. | Integrate approved runtime wording; additional realistic sparse/ambiguous contingency cases; regression and parser/preview checks. |
| `nail_qda()` | What sensory configuration characterizes each evaluated product or stimulus relative to the average product? | Evidence-first canonical product profiles; approved bilingual `reading`, `interpretation`, identities, local/joint tasks, `output` and four assemblies in `dev/reading_review/QDA_MODULAR_PROMPT.md` and `QDA_ASSEMBLY_REVIEW.md`. | Integrate approved runtime wording; test known/unknown × local/joint, HIGHER/LOWER and model-adjusted means across diverse sensory cases; check no invented pairwise significance. |
| `nail_textual()` | What discourse, themes, frames, internal diversity and qualitative coherence characterize each observed/constructed group from its open-ended texts? | Canonical `textual_evidence`, `interpretation_input` and `textual_profiles` implemented; operational testing reported with reservations 2026-10-09; `reading`, `interpretation`, `local_task`, and classic `output` approved, with assembled variants in `dev/reading_review/TEXTUAL_MODULAR_PROMPT.md` and `TEXTUAL_ASSEMBLY_REVIEW.md`. | Integrate only the approved **classic** TEXTUAL route wording; preserve six-field profile parser and local-first semantics, TXT identifiers and sampling invariance; realistic diverse/sparse/contradictory corpora and LLM review. |

**Interpretation of status:** Approved scientific prompt documents are not implemented runtime prompts. Earlier local test reports verify only the versions and cases they exercised; they do not certify that the newly approved wording has been integrated or independently evaluated with LLMs.

## 2. Explicit freeze — no work on other analytical functions until all five pass

**Secondary scientific analyses (pause even if operational):**

- `nail_qda_space()` — pause new interpretation/prompt work.
- `nail_catdes_textual()` — pause new composition, prompt variants and interpretive-propagation experiments; retain the previously documented known risk.

**Intermediate or compatibility routes (maintenance-only, not separate finalization targets):**

- `nail_catdes_prep()`, `nail_textual_prep()`, `nail_group_profile_prep()`, `nail_qda_spaceprep()`.
- `nail_textual_contextualized()` — historical compatibility and canonical routing.
- `nail_qda_interpretation()` — expert review accessor; `nail_catdes_ground()` — optional research/grounding.

Approved scientific wording for the preparatory TEXTUAL output remains archived and valid as a documentary decision, **but this freeze does not authorize implementing or separately validating that intermediate route now**.

**Other historical exports:** `nail_sort()`, `sim_llm()`, `dist_mat_llm()`, `dist_ref_llm()`, and related legacy enhancements remain out of development scope.

**Shared infrastructure:** `nail_evidence()`, `nail_prompt()`, `nail_response()`, and package build/test tooling can be exercised or minimally repaired **only as necessary to finalize the core five**. No redesign of shared contracts just for tidiness. Do not delete legacy exports or break dependencies.

**No exceptions for attractive new features:** no new agents, semantic-global TEXTUAL comparison, renewed CATDES + TEXTUAL experiments, prompt format expansion, broad refactoring, or work on secondary functions before the five gates have passed. Only a demonstrated core-five blocker or narrowly necessary shared-compatibility correction may interrupt the order; document why.

## 3. Explicit definition of FINALIZED for each of five

All of these gates must pass, or carry an explicit analyst-approved limitation and corresponding documented non-blocking risk:

1. **Scientific objective and contract fixed:** method-specific question, observed/latent and local/joint boundaries, statistical or textual semantics, and requested output fields are documented and noncontradictory.
2. **Runtime prompt integrated:** the approved bilingual-reviewed *English operational blocks* are assembled in the actual R function; no unapproved editorial expansion, no generic statements about R-selected but unshown evidence in the LLM prompt; the user-supplied `introduction` and `request` are preserved. Any French wording remains a control translation unless specifically supported by a separate language contract.
3. **Canonical evidence unchanged:** interpretation/prompt options affect only what is displayed, not underlying statistics or complete text registry; IDs, selection provenance, significance and direction, metadata and missing/empty statuses remain inspectable.
4. **Output and API compatible:** `generate = FALSE` previews, `generate = TRUE` results, parsers where applicable, group identifiers, `nail_evidence()`, `nail_prompt()`, `nail_response()` and the existing public API remain functional. Do not add a new parser value (such as `not assessable`) without an independent authorized contract decision.
5. **Realistic applied examples:** one or more nontrivial domain-appropriate examples per function; compare narrative output with raw statistical/textual facts. Specifically assess interpretive value, linguistic direction, nuances, unsupported causal/pairwise statements, sparse evidence and appropriate limits. Use actual LLM results where relevant; clearly distinguish a model experiment from an offline test fixture.
6. **Regression and package health:** `devtools::load_all()` → targeted manual R example → `devtools::test_active_file()` if a focused test exists → `devtools::test()` → `devtools::check()` or equivalent R CMD check when appropriate → `git diff --check` → targeted commit/push. Track known warnings; do not claim zero warnings without verifying.
7. **User-facing demonstration:** readable, offline-safe README/vignette examples for that function, emphasizing meaningful `introduction` and `request` and source-vs-interpretation distinctions.

Do not mark a function finalized merely because the prompt text has been approved or `testthat` passes. Record test command/results, example, provider/model, date and outstanding reservations. Independent expert approval is required for any release-relevant scientific compromise.

## 4. Execution plan — one function at a time

**Default order:** `nail_condes()` → `nail_catdes()` → `nail_descfreq()` → `nail_qda()` → `nail_textual()`.

This order reuses stabilized scientific blocks without reopening scientific debates and leaves the qualitatively distinct TEXTUAL model/parsing checks as the final core gate. It is an *execution order*, not a claim that CONDES has the largest or smallest gap; reprioritize only for a demonstrated blocking dependency.

For each function:

1. Verify current HEAD R source and the exact approved `dev/reading_review/*_MODULAR_PROMPT.md` source; review generated prompt against the documentary assembly.
2. Make the smallest R prompt change needed; preserve `introduction`, `request`, canonical objects, selection logic, and technical output/parser contracts.
3. Inspect `generate = FALSE` variants and their exact prompt sections. Run realistic LLM cases and examine factual faithfulness and interpretive lift.
4. Run tests/checks and record a short signed-off function outcome. Commit only a targeted unit of work.
5. Move to the next function **only when the current one meets its agreed finalization gates or has an explicitly accepted, documented limitation**.

## 5. Progress board — baseline at decision time

| Function | Evidence-first implementation | Scientific bilingual blocks | New wording implemented in R | New wording operationally tested | Finalization |
| --- | --- | --- | --- | --- | --- |
| `nail_condes()` | Existing; testing required at final gate | Approved | Not yet | Not yet | OPEN |
| `nail_catdes()` | Existing; testing required at final gate | Approved | Not yet | Not yet | OPEN |
| `nail_descfreq()` | Existing; previous applied cases tested | Approved | Not yet | Not yet | OPEN |
| `nail_qda()` | Existing; previous applied cases tested | Approved | Not yet | Not yet | OPEN |
| `nail_textual()` | Existing; previous applied tests with reservations | Approved | Not yet | Not yet | OPEN |

This board does **not** override precise older operational-test records or imply that prior runs have been repeated. Update status only from completed, reproducible evidence.

## 5A. Progress update — 2026-10-15 (after local validation)

The section 5 board above is a **historical baseline at the scope-freeze decision**, not the current state. The function-by-function technical finalization status is now:

| Function | Current state | Source |
| --- | --- | --- |
| `nail_condes()` | TECHNICALLY FINALIZED | `dev/CORE5_CONDES_INTEGRATION_REVIEW.md` |
| `nail_catdes()` | TECHNICALLY FINALIZED (post-fix checks user-confirmed) | `dev/CORE5_CATDES_FINALIZATION_REVIEW.md` |
| `nail_descfreq()` | NEXT: scientific runtime integration and end-to-end validation | `dev/CORE5_DESCFREQ_INTEGRATION_REVIEW.md` on its integration branch |
| `nail_qda()` | OPEN | Approved scientific prompt in `dev/reading_review/` |
| `nail_textual()` | OPEN | Approved classic scientific prompt in `dev/reading_review/` |

The order of finalization and evidence-first separation remain unchanged. A locally observed model interpretive error is not the same as a failure in R statistical truth, selection, or software behavior. Current exact local R test output is retained in the corresponding review records or marked as analyst-reported when not attached.

## 6. Exit condition

The freeze lifts **only after all five functions are explicitly finalized** and the analyst agrees on the next phase. Then consider the two composed analyses `nail_qda_space()` and `nail_catdes_textual()`, and only later deprecations/cleanup of intermediate functions. Until then, no extra feature roadmap.
