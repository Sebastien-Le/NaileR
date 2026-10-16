# NaileR — CORE 5 / QDA finalization review

**Date:** 2026-10-16  
**Status:** **TECHNICALLY FINALIZED — ANALYST ACCEPTED** for CORE 5 progression; **NOT** a whole-package release certification.  
**Implementation commit:** [`60ecb18f989999a51180021b480aca7f41597fdf`](https://github.com/Sebastien-Le/NaileR/commit/60ecb18f989999a51180021b480aca7f41597fdf)  
**Branch:** `dev-core5-qda-integration-20261016`  
**Scientific sources:** [`QDA_MODULAR_PROMPT.md`](reading_review/QDA_MODULAR_PROMPT.md), [`QDA_ASSEMBLY_REVIEW.md`](reading_review/QDA_ASSEMBLY_REVIEW.md).  
**Prior static audit:** [`CORE5_QDA_INTEGRATION_REVIEW.md`](CORE5_QDA_INTEGRATION_REVIEW.md).

## 1. Closeout decision and scope

The analyst explicitly approved technical finalization of `nail_qda()` on 2026-10-16 after the targeted R integration, a critical review of the patch and actual LLM outputs, and two complementary Ollama experiments in `product_knowledge = "unknown"`. This decision authorizes integrating QDA into `dev-statistical-prompt-framework` and advancing to the fifth core function, classic `nail_textual()`. It does **not** validate every LLM statement as a statistical result and does **not** certify that `R CMD check` passed.

The implementation commit touches exactly:

- `R/nail_qda.R`
- `man/nail_qda.Rd`
- `tests/testthat/test-qda-semantic-rebuild.R`

Local operational experiment files and generated plot PDFs were intentionally not staged or published.

## 2. Implemented integration (source code independently verified on GitHub)

- The existing `SensoMineR::decat()` and canonical `product_profiles` evidence-first pipeline remains in place; no statistical refactoring was authorized.
- The default prompt includes the scientifically approved English `reading`, `interpretation`, `known` / `unknown` identity, `local` / `joint` task and editorial `output` blocks. Analyst `introduction`, `request` and custom `conclusion` remain distinct from R-derived data. Provider, sampling and product-knowledge settings preserve public contracts.
- The original prompt-selection-policy explanations and compulsory default Quarto Markdown requirement were removed from the ordinary scientific reading/output, according to approved decisions. Selection and provenance remain auditable in R.
- The joint `generate = TRUE` provider bug was fixed by sending `prompts$portfolio` (one string), instead of the entire named list, to the backend. The `list(portfolio = ...)` preview/LLM I/O contract remains intact.
- The structured `NAILER_PRODUCT_INTERPRETATION` HTML comments, `product_interpretations`, parse statuses, evidence IDs, and `nail_qda_interpretation()` review pathway remain supported. Existing `nail_qda_space()` consumers were not modified.
- `known` represents identified evaluated products; `unknown` represents coded **evaluated stimuli**, not latent variables. Original identifiers must be preserved in both cases; an evidence-supported sensory name can supplement anonymous codes.

## 3. Operational evidence, provenance and limits

Results were reported from the dedicated local Codex worktree `/private/tmp/nailer-qda-integration-20261016`, relayed by the analyst and reviewed through an uploaded integration archive in the conversation. They were **not rerun in R by the GitHub-only closeout action**.

| Validation | Result reported on 2026-10-16 |
| --- | --- |
| Focused QDA test suite | **145 PASS, 0 FAIL, 0 WARN** |
| Reusable product-interpretation tests | **32 PASS, 0 FAIL, 0 WARN** |
| Entire package test suite | **1,351 PASS, 0 FAIL, 0 WARN** |
| `git diff --check` / staged diff check | OK |
| `known × local` real Ollama | 2/2 product interpretations parsed |
| `known × global` real Ollama | 2/2 product interpretations parsed |
| `unknown × local` real Ollama | 2/2 product interpretations parsed, 2 calls |
| `unknown × global` real Ollama | 2/2 product interpretations parsed, 1 call |
| `product_profiles` and canonical evidence invariance | Reported preserved across identity/task variants |
| `devtools::check(document = FALSE)` | **NOT COMPLETED**: `processx` namespace load failed with `Operation not permitted` before construction |

**Scientific qualification:** a successful parser means that required fields can be extracted and attributed to the right stimulus; it does **not** establish that each free-form phrase is a correct scientific inference. Real Ollama `mistral-small3.2` responses occasionally converted LOW/LOWER into apparent absence or reduction, in both readable reports and reusable `core_profile` or `distinctive_interpretation` fields. No invented real stimulus identities were reported for the unknown variants, and the original codes `choc1` and `choc2` were retained.

## 4. Accepted scientific interpretation boundary

**Explicit analyst decision on 2026-10-16:** A statement such as “lack of bitterness” can, in context, sometimes be understood as sensory shorthand for *less pronounced bitterness relative to the average product in the evaluated set*. That contextual reading mitigates the interpretation problem and does not justify another speculative prompt-rewriting cycle.

But **LOWER is not an absence test**: technically it means the product's model-adjusted score for that sensory attribute is significantly below the comparison reference for the evaluated set, **not** that the characteristic is unmeasured, zero, or universally absent. Maintain the original R evidence (adjusted means, v-test, p-values and directional markers) as the final scientific reference. In publication, customer-facing reporting and especially any reuse as upstream interpretation in `nail_qda_space()`, experts should correct outright absolute-absence or unsupported causal/hedonic claims. A parsed block can carry overinterpretation; parse success is not an epistemic guarantee.

The analyst accepted this **documented non-blocking model-language limitation**. The approved scientific prompt wording remains frozen. Distinguish statistical truth from optional LLM interpretation throughout subsequent workflows.

## 5. Remaining release-level gate and handoff

A complete `R CMD check` is still outstanding because the Codex environment could not load `processx` (`Operation not permitted`). This failure occurred **before construction**, so it is not a report of package test warnings/errors and not evidence of a clean package check. Re-execute in an unrestricted local RStudio session before declaring package release readiness.

No additional source changes are required by this scoped closeout. Next target: `nail_textual()`, using the frozen approved classic TEXTUAL scientific blocks. `nail_textual_prep()`, `nail_textual_contextualized()`, QDA-space and CATDES+TEXTUAL enhancements remain out of active feature-development scope under the CORE 5 freeze.
