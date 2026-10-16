# NaileR — seven-function architecture audit: charter and execution protocol

**Date:** 2026-10-16  
**Status:** AUDIT CHARTER ONLY — **no audit findings, no source code changes, no fresh R/LLM test execution**.  
**Branch:** `dev-seven-function-architecture-audit-20261016`  
**Code baseline:** `903c89b8426f3d30a0ef876ea5dff73c838c5eeb`, fast-forward integrated from the completed CATDES–TEXTUAL composed-analysis review.  
**Authoritative history:** `PROJECT_STATE.md`, `dev/FINALIZATION_CORE5.md`, `dev/COMPOSED_QDA_SPACE_FINALIZATION_REVIEW.md`, `dev/COMPOSED_CATDES_TEXTUAL_FINALIZATION_REVIEW.md`.

## 1. Scientific question

**Are the seven accepted NaileR analyses genuinely instances of a coherent, extensible, evidence-first scientific interpretation architecture, or merely independent functions with similar prompt/LLM wrappers?** Answer from actual code, tests and realistic workflows, not from aspiration, naming conventions or memory.

No framework redesign, deprecation, feature addition, broad DRY refactor or API change is preauthorized by this charter. The five CORE methods and two composed functions are **technically finalized** for proceeding to this review, **not** approved for an unconditional public release.

## 2. Scope and sources

Primary public functions (exactly seven):

1. `nail_condes()` — continuous target characterization.
2. `nail_catdes()` — category/group characterization.
3. `nail_descfreq()` — frequency description.
4. `nail_qda()` — trained sensory panel/product profiles.
5. `nail_textual()` — group-organized observed text and model-assisted profile interpretation.
6. `nail_qda_space()` — QDA adjusted product profiles → scaled PCA → descriptive CONDES axis characterization → model-assisted interpretation when eligible.
7. `nail_catdes_textual()` — compose **previously computed** CATDES and TEXTUAL results, preserving statistical/textual epistemic separation.

Read live files in `R/`, especially their named source files and supporting: `nail_catdes_prep.R`, `nail_group_profile_prep.R`, `nail_qda_spaceprep.R`, `nail_textual_semantic.R`, `nail_qda_interpretation.R`, `nail_evidence.R`, `nail_llm_io.R`, `utils_ollama.R`, `gemini_generate.R`, `utils_prompt.R`, `utils_parsing.R`, `utils_sampling.R`, `utils_validation.R` and neighboring helpers as needed.

Consult `man/`, tests in `tests/testthat/`, `DESCRIPTION`, `NAMESPACE`, and prior accepted review docs. Other functions such as `nail_textual_contextualized()`, `nail_catdes_ground()`, `nail_textual_prep()` are **supporting/boundary dependencies**, not additional core audit items unless a dependency impacts one of the seven.

## 3. Audit axes — assess each function individually, then cross-functionally

### A. Data preparation and statistical truth

- Precisely identify statistical engine, inputs, filtering/missingness, numerical transformations, grouping, output schemas and sources of truth.
- Where does NaileR compute facts deterministically and where does the LLM generate interpretations? Examine whether copied summaries could be mistaken for independent computations.
- Are quantitative/qualitative/textual/sensory evidence families represented without losing scientific meaning? Do names/units/signs/thresholds survive?
- What is genuinely invariant under `generate`, prompt style, sample selection, provider and custom `introduction/request/conclusion`? Cite tests or establish missing tests.

### B. Selection and rendering of evidence

- Follow the chain: canonical evidence → interpretation subset → semantic-facing facts → final prompt.
- Compare `evidence_id` provenance, dropped/negative markers, directions, quantitative precision, text IDs, response coverage and exceptions.
- Distinguish *ranked/selected* evidence from full evidence, and deterministic facts from model-produced syntheses.
- Verify whether absence of evidence is wrongly communicated as absence of a phenomenon.

### C. Interpretation contracts and scientific safeguards

- Catalogue the scientific reading, local task, requested final output, allowed user overrides and their precedence for all seven functions.
- Compare observed vs latent target constraints; PCA axis signs; QDA above/below relative mean (not absence); descriptive CONDES correlations; source-specific confidence for qualitative text.
- Identify where safeguards are **deterministic** versus simply prompt instructions. Check unknown/failed/empty generation and special gating cases.
- Catalog accepted residual limitations explicitly instead of disguising them as solved.

### D. LLM and provider boundary

- Inspect call sites and shared provider implementations: `ollama` / `gemini`, `model`, `generate`, `...`, `output`, retries/errors, reproducibility, call accounting.
- Contrast preview vs generation; group-local vs combined returns; raw responses vs parsed fields. Compare exact `nail_prompt()` and `nail_response()` semantics per function, including unavailable or candidate-only units.
- Identify where the same helper really implements a shared capability versus only name similarity. Avoid unnecessary provider overhaul: a separate local/remote backend audit is scheduled **after** documentation checks.

### E. Composition and provenance

- For `nail_qda_space()`, verify canonical `product_profiles`, PCA evidence, CONDES characterization, interpretative status `associations_selected` versus `no_selected_associations`, no LLM call when no selected attributes, deterministic statement not masquerading as `nail_response()`.
- For `nail_catdes_textual()`, verify the two-object `catdes` + `textual` interface, group-label checks, analyst responsibility for population comparability, prior TEXTUAL profile provenance, exact `TXT%06d` quotes, five parsed fields, **deterministic** `statistical_anchor_authoritative` versus LLM-produced narrative `statistical_anchor`.
- Investigate whether both compositions could be built with shared contracts *without* erasing their distinct scientific epistemology. Be explicit about reusable and necessarily method-specific operations.

### F. Tests, documentation, extensibility and maintenance

- Review current coverage of error paths, empty/degenerate data, missing texts, small groups, sign ambiguity, source mismatches, stale model responses and malformed upstream objects. Differentiate exercised tests, mocked tests, real LLM validations and proposed tests.
- Evaluate `DESCRIPTION`, S3 classes, naming, accessors, compatibility layers, duplicated code, coupling, package documentation, and how feasible it would be to add an eighth method without rewriting the seven.
- Identify drift between code and documentation; **do not execute/fix all examples now**. Documentation examples, vignettes and `R CMD check` form a distinct next phase and still require a configured Pandoc environment.

## 4. Required grounded deliverables

Prepare a structured audit document with:

1. **Seven-function inventory matrix**, one row per function: public signature, source file, required inputs, statistical/data engine, core R artifact, prompt/view artifact, response/parse artifact, `generate=FALSE/TRUE` behavior, actual LLM call scope, provenance and scientific invariant.
2. **Dependency/data-flow graph** showing where primary methods share real code and where composed methods consume their outputs; annotate sources of statistical and textual truth.
3. **Contract taxonomy** explicitly distinguishing R-computed facts, prompt selection, interpretive summaries, external LLM raw output, and deterministic R guards.
4. **Evidence-backed findings** with exact file/function/line references, severity and reproduced or test-grounded impact. Report truly shared components, copy/paste duplication, inconsistent accessors, API hazards and scientific overstatements.
5. **Negative cases and test gap register**, classified into reported past validation, source-inspected behavior, mocked tests, real end-to-end tests and gaps. Do not claim that inspection alone is test execution.
6. **Prioritized remediation options**: `P0` scientific incorrectness / provenance corruption, `P1` material maintenance or UX risk, `P2` optional unification/cleanup. Each option must include smallest safe change, expected user behavior and backwards-compatibility risk.
7. **Answer to the central question**: is NaileR already an architectural framework? Identify the smallest contracts that would need formalization to make it truly extensible, and what should intentionally remain method-specific.
8. **Explicit decision gates** requiring analyst approval before any modification, commit, push, renaming/deprecation or broader refactoring.

## 5. Executable review discipline

Begin with a **read-only code and test audit**, no edits to `R/`, `man/`, `tests/`, `DESCRIPTION`, `NAMESPACE` or site documentation. No commits, pushes or merges. Preserve the branch and baseline SHA. Use operational examples only when they sharpen an actual question or validate a claim; distinguish offline/mock from real Ollama runs.

For local validation when available, use `devtools::load_all()`, `devtools::test_active_file("tests/testthat/<file>.R")` (never deprecated `test_file()`), `devtools::test()`, `git diff --check`; separately report missing Pandoc/processx/vignette prereqs for `devtools::check(document = FALSE)`. Do not claim an unrun test passed.

Report the full findings **before recommending code modifications**. The analyst chooses whether to accept a shared abstraction, a targeted fix, or no code change.

## 6. Established decisions not open to accidental reversal

- Five primary methods and two composed methods have been technically finalized on the development branch; release readiness remains pending.
- Preserve scientific judgment and independent exploration: no implicit end-to-end mega-function that hides the stages.
- `nail_catdes()` and `nail_condes()` retain their current independent input interfaces; only `nail_catdes_textual(catdes, textual)` composes text with groups; do **not** add a `textual` argument to `nail_catdes()`.
- For CATDES–TEXTUAL, analyst accepts comparability responsibility; group-label matching is not population-identity proof and should not be overclaimed.
- R-only authoritative artifacts are distinct from the raw/parsed LLM narrative; parser compliance does not confer epistemic authority.
- QDA-space deterministic axis eligibility is selection-specific, not a universal inferential validation of PCA geometry.
- Full documentation/example and provider audits occur **after** this architecture audit, not as substitutes.
