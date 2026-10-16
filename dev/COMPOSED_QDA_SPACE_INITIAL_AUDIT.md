# NaileR — composed analysis 1/2: `nail_qda_space()` initial architectural and scientific audit

**Audit date:** 2026-10-16  
**Status:** INITIAL **STATIC** SOURCE AUDIT COMPLETE — **NO IMPLEMENTATION OR NEW R/LLM TEST RUN**.  
**Starting SHA:** `c9527cc475d1cc9431e143144bb823213b21e0d6` on `dev-composed-qda-space-20261016`.  
**Scope:** composed function `nail_qda_space()` only. Next, separately, `nail_catdes_textual()`; later the general seven-function architecture audit, documentation examples and provider comparison.  
**Primary source files:** `R/nail_qda_space.R`, `R/nail_qda.R`, `R/nail_condes.R`, `R/nail_qda_product_interpretations.R`, `R/nail_qda_interpretation.R`, `R/nail_llm_io.R`, `tests/testthat/test-qda-space-condes-engine.R`, `man/nail_qda_space.Rd` and CORE 5 closeout reviews. No change to `nail_qda_spaceprep()` is authorized without a separate compatibility decision.

## 1. Scientific object and existing processing chain

`nail_qda_space()` is not a new QDA analysis; it composes **three scientific objects of different status**:

1. **Sensory measurement/statistical layer:** `nail_qda()` canonical `product_profiles` records model-adjusted sensory attribute means per product, retained QDA markers and their directions against the evaluated-set average. The raw `SensoMineR::decat()` `adjmean` matrix is a documented compatibility input with fewer available product interpretations.
2. **Geometric/axis layer:** `FactoMineR::PCA` on the **product-by-attribute adjusted-mean matrix**, default `scale.unit = TRUE`; axis scores, correlations, inertia, product positions and `contrib`/`cos2` describe the same product space. For each retained axis, `nail_condes(..., interpretation_mode = "latent", generate = FALSE)` characterizes its quantitative associations with adjusted sensory attributes. The internal CONDES *end profiles* are retained as inspectable R evidence, **not sent** to the final LLM.
3. **Interpretive layer:** extreme real products on each axis with canonical QDA distinctive marker directions (classified into `reinforcing`, `additional`, `conflicting`) and optionally a **reused**, source-labelled `product_interpretations` entry from QDA (possibly expert-edited); the final LLM receives an axis-specific prompt and generates an analytical narrative only if `generate = TRUE`.

The full `qda_space_evidence` is attached with a `qda_space` compatibility alias, `axis_condes`, canonical upstream `product_profiles` and `product_interpretations`, `qda_space_settings` and canonical `llm_io`. `nail_evidence()`, `nail_prompt()`, `nail_response()` support inspection. The return is a **named axis prompt list** for preview or **named final axis LLM results** for generation; it is not a `textual_profiles`-style structured parser contract.

**Existing test baseline (read, not rerun):** `test-qda-space-condes-engine.R` covers real `nail_condes()` latent profiles, prompt excluding internal implementation jargon, `end_profiles` retained only in R, expert revisions, QDA invariance, one LLM call per retained axis, appropriate warnings for reused model-assisted interpretations, and default scaled PCA.

## 2. Highest-priority scientific review: correlations are descriptive, not independent confirmation

The implementation computes a PCA on the adjusted-mean sensory attributes, then regresses/correlates **each attribute of that same matrix** with the resulting axis score through `nail_condes()`. This is entirely legitimate as a **descriptive characterization of a PCA component**, but the axes were *constructed from those very attributes*.

Consequently, correlations, statistical-sounding significance thresholds and `p_value` fields supplied by CONDES **must not be interpreted as independent tests confirming that an attribute “causes”, “significantly predicts” or “validates” an axis**. The association is partly mechanically induced by PCA construction. The code already emphasizes sensory continua, axis-sign arbitrariness and no causal/hedonic inference, but the resulting prompts and explanations require explicit scientific inspection. In particular:

- `condes_proba` may act as an **internal descriptive selection heuristic**, not a license for independent inferential statements.
- Separate **inertia / PCA contributions / axis-attribute correlations**, **QDA adjusted means and its own retained markers**, and **LLM summary**. They answer different questions and have different evidential status.
- The labels `reinforcing`, `conflicting`, `additional` result from a **deterministic cross-reference of marker direction and selected PCA-axis correlation sign**; they are interpretive roles relative to a pole, **not separate tests of product–axis interactions or pairwise significance**.
- The PCA axes' positive and negative signs are arbitrary; the opposition matters, not a fixed positive-value sensory merit.

**Recommended gate before any prompt rewrite:** inspect a few complete generated axis prompts with an analyst and decide whether the *scientific framing* needs changes. No new methodology is imposed by this audit.

## 3. Technical and epistemic contracts to preserve

| Priority | Area/source | Review question and acceptance condition |
| --- | --- | --- |
| P1 | `.qda_space_extract_inputs()` and `.qda_space_adjmean_from_product_profiles()` | Prefer complete canonical adjusted means, not LLM summaries; raw `decat$adjmean` fallback remains supported. Product identity, attribute order, finiteness and consistency must be preserved. Test true `nail_qda()` results as well as existing synthetic fixtures. |
| P1 | `.build_qda_space_pca()` | Understand `ncp` limit, default `scale.unit = TRUE`, inertia selection, constant variables, nearly singular/low-rank matrices. Never silently change PCA geometry just to improve the LLM narrative. |
| P1 | `.build_qda_space_condes()` | It actually calls `nail_condes()` in latent preview mode once per retained axis; no hidden upstream model call. Check that the selected quantitative association fields keep their CONDES semantics and that no `end_profiles` enter the LLM axis prompt. |
| P1 | `.qda_space_classify_product_markers()` | Deterministic reinforcing/conflicting/additional labels derive from selected axis correlations and canonical QDA marker directions. They are *not* new significance tests. Check marker sorting/caps and any contradictions and do not lose original IDs. |
| P1 | `.qda_space_product_interpretation()`, `nail_qda_interpretation()` | Use only `status = "available"` reusable interpretations. Distinguish `source = "expert"` vs `source = "llm_pass1"`; parse failures fall back to canonical QDA markers, rather than hallucinated replacement. Preserve expert edits, upstream raw responses and evidence. |
| P1 | Final prompt: `build_guide_qda_space()`, `build_request_qda_space()`, `build_conclusion_qda_space()` | Check three modes (`sensory`, `positioning`, `hybrid`) and user `introduction/request/conclusion`; ensure claims are grounded and avoid hedonic, quality, causal or marketing assertions from sensory geometry. Product profile LOWER means relative lower adjusted mean, never absolute absence. |
| P1 | `.call_llm_base()` / `llm_io` | In `generate = FALSE`, zero provider calls; in `TRUE`, one call per retained PCA axis. The exact axis prompts and raw responses remain accessible and attributable to their axis; no default global model synthesis. |
| P2 | No retained axes | `min_inertia_pct` may suppress all axes. The special return has inspectable empty evidence but no `llm_io` attribute; verify public accessor behavior and documentation, with no invented interpretation. |
| P2 | `ncp` / degenerate PCA | `ncp` is capped by products and attributes. Constant variables fail explicitly; strongly collinear/rank-deficient product matrices and tiny product counts need realistic tests, since small or zero-variance axis scores could make internal CONDES profiling fragile. |
| P2 | Warnings | The package warns non-blockingly when `llm_pass1` product interpretations are used during actual final-axis generation, but not for expert-only edits. Keep that provenance-dependent warning and compare unsupported summary claims against QDA marker facts. |

The existing `profile_summary` and `llm_product_summaries` arguments are deprecated/ignored for compatibility; do not remove during this phase. No broad provider refactor and no new scientific output schema should be smuggled into this scoped intervention.

## 4. Operational scenarios and acceptance gates

### A. Independent statistical demonstration with real sensory data

Use a real small/medium sensory QDA dataset (e.g. `SensoMineR::sensochoc`, after verifying its actual object name and structure locally). Produce `nail_qda(..., generate = FALSE)` then `nail_qda_space(..., generate = FALSE)`; inspect adjusted means, PCA eigenvalues, chosen axes, CONDES associations, selected product extremes, marker direction roles and exact rendered axis prompts. Compare 1 vs 2 axes, default standardized and explicit unscaled PCA, `min_inertia_pct` below and above inertia, and input order invariance where statistically appropriate.

### B. Reusable product interpretation provenance

Run QDA with a real local model so product interpretations are generated and parsed. Use the resulting object in QDA space; then edit one product interpretation via `nail_qda_interpretation()` and check that expert revision appears, keeps the original canonical stats, and does not overwrite LLM provenance. Separately construct a parse-failed or unavailable product interpretation and check the statistical fallback and appropriate message/warning. Never confuse reuse with new QDA statistical evidence.

### C. Modes and interpretation quality

Build **all three** prompt modes (`sensory`, `positioning`, `hybrid`) with identical frozen statistical evidence and custom introduction/request sentinels. The `positioning` and `hybrid` modes should not invent product quality, likability, market preference, positioning validation, or causal explanations. Discuss whether `Quarto Markdown` is a desirable **output formatting choice** rather than a scientific requirement, but do not silently remove compatibility constraints.

Perform actual `mistral-small3.2` generations on at least 1–2 interpretable axes, recording full prompts, raw responses, retained `llm_io` and a scientifically critical human assessment: correctness of pole oppositions, use of extreme product examples, coherence of sensory narrative, treatment of contradictory markers and edited-vs-model summaries. Do not count a well-formatted response as scientifically validated.

### D. Test coverage and release checks

Extend existing `tests/testthat/test-qda-space-condes-engine.R` only when specific contract checks are missing. Include QDA integration, real CONDES calls, raw `decat` fallback, no axes case, malformed interpretation fallback, parameterized `expertise_mode`, QDA `product_profiles` immutability, `nail_evidence/nail_prompt/nail_response`, and no model calls on preview. Test edge cases including invalid input, constant attributes and small/rank-deficient product spaces.

Run locally `devtools::load_all()`, `devtools::test_active_file("tests/testthat/test-qda-space-condes-engine.R")`, relevant upstream QDA/CONDES tests, `devtools::test()`, `git diff --check`, and `devtools::check(document = FALSE)` with RStudio/Pandoc configured. Note that older environments blocked `processx`, then vignette build lacked Pandoc; neither is a passed full package check.

## 5. Execution order and decision gates

**Do not refactor on the strength of this static audit alone.** A sensible sequence is:

1. **Operational baseline first, without R code edits:** true `nail_qda()` → `nail_qda_space()`, record R-derived PCA/CONDES facts and three final-axis prompt variants.
2. **Scientific analyst review** of geometric/descriptive vs statistical inferential language; explicitly decide which, if any, existing guide/request/output sentences need surgical revision. Avoid the mistake of treating `condes_proba` as independent validation.
3. Only then make **minimal scope-limited R changes**, if demonstrated necessary; preserve interfaces, canonical evidence and source provenance.
4. Execute focused tests, full regression tests and real LLM cases; report substantive quality and known limitations separately from syntax/parser success.
5. Ask the analyst to accept and authorize a targeted code commit/push. Then integrate, and audit `nail_catdes_textual()`.
6. Only after the **two composed analyses** are finished, begin the separately requested seven-function general architecture audit. Until then no framework-wide refactoring.

The project-wide question remains explicit: **are the seven functions independent LLM wrappers or applications of one scientifically sound, extensible interpretation architecture?** It will be answered by evidence from code and composability tests, not assumed in advance.
