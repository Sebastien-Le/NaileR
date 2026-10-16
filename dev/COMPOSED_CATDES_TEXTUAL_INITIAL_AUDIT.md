# NaileR — composed analysis 2/2: initial audit of `nail_catdes_textual()`

**Date:** 2026-10-16  
**Status:** INITIAL SOURCE/CONTRACT AUDIT — **no R source edits or new local tests or LLM calls**.  
**Branch:** `dev-composed-catdes-textual-20261016`, created from `56730be7f9e78691766fd876661dbfe316dae4c0`.  
**Scope:** `nail_catdes_textual()` exclusively, as the second composed NaileR analysis. Do not refactor CATDES, TEXTUAL, PREP/contextualized helpers or the shared provider framework during this review.

**Inspected source:** `R/nail_catdes_textual.R` (including both compositional validators, construction of canonical composed evidence, ID resolution, prompt guide, parser, local-first output and accessors), `tests/testthat/test-catdes-textual.R`, `R/nail_llm_io.R`, `man/nail_catdes_textual.Rd`, and the already-finalized CATDES/TEXTUAL development contracts.

## 1. Scientific question and existing architecture

`nail_catdes_textual()` answers: **How do open-ended responses substantively enrich, qualify or supplement a statistical characterization of a given observed or latent group, without turning text into statistical confirmation of unrelated CATDES markers?**

The two upstream sources have different scientific statuses and are **asymmetric by design**:

- **Statistical anchor:** mechanical `semantic_facing_evidence` from `nail_catdes()`. Its retained CATDES characteristics and `selected_evidence_ids` remain authoritative. An earlier generated CATDES semantic response, if available, is *secondary* and kept separately.
- **Textual enrichment:** `textual_evidence`, `interpretation_input`, and successfully parsed `textual_profiles` from `nail_textual(generate = TRUE)`. Textual profile themes and claims are **LLM syntheses**, not fresh statistical variables, effect sizes or independent confirmation of CATDES results. The underlying `TXT%06d` source IDs and exact quoted texts provide inspectable source grounding for representative and tension excerpts.
- **Composed interpretation:** exactly **one local LLM call per group** with `generate = TRUE`; `isolate.groups = FALSE` combines the *outputs of local calls*, never a new global multi-group interpretation. `generate = FALSE` builds prompts and canonical composed evidence without a new LLM call.

Current five-field generated format: `Statistical anchor`, `Textual enrichment`, `Additional insights`, `Internal diversity`, `Contextualized profile`. The parsed `contextualized_profiles` distinguishes `available`, `parse_failed` and non-generated preview statuses. Parser success assesses the presence of the five fields, **not** the truth or relevance of the links claimed.

The composed return carries `contextualized_evidence`, `contextualized_profiles`, `local_prompts`, `catdes_textual_settings` and `llm_io`. Inspect with `nail_evidence()`, `nail_prompt()`, `nail_response()` and direct source attributes. No upstream CATDES or TEXTUAL calculations should be recomputed or silently changed.

## 2. Priority epistemic concern — alignment of populations and groups

The validator currently uses `setequal(names(semantic_facing$groups), names(textual_profiles$groups))`. This **verifies identical group labels only**, *not* that the two analyses describe the same observations, individuals, group definition, study wave, inclusion criteria, or population.

It is possible to construct statistically valid but **scientifically incommensurable** CATDES and TEXTUAL objects with the same group names; the composed function would then weave a spurious explanatory story. Even equality of counts alone would be insufficient proof of row-level identity.

**Acceptance gate:** use a realistic common-source dataset and construct both analyses from the **same explicitly documented grouping assignment**; record row indices/IDs upstream and inspect per-group counts. Construct a deliberate counterexample using different source data with identical group labels to demonstrate current limits. Decide with the analyst whether to keep a documented caller precondition, introduce optional common-source provenance, or require stricter contract metadata. **No automatic API change** in this initial audit. Do not claim provenance validation not implemented in code.

Important distinction: a text row is not necessarily an independent person; `n_group_rows` is an **observation denominator**. The current guide says response coverage counts how many *group members* supplied text, and the default introduction says *individuals in the same group*, which may be scientifically inaccurate for repeated-response datasets. Verify the appropriate semantics before changing approved instructions.

## 3. Priority epistemic concern — generated inference on top of generated inference

The composed LLM may receive:

- R-certified CATDES factual text and its statistical IDs;
- optionally a previous **LLM-generated** CATDES summary;
- an existing **LLM-generated** textual thematic profile;
- representative and tension source texts resolved from the original `TXT%06d` registry.

These are **not four independent bodies of evidence**. The LLM may rephrase a prior unsupported assertion as if mutually confirmed by CATDES and TEXTUAL. The implementation warns when a prior CATDES generated interpretation is reused during the final generation; the textual profile itself is necessarily already an interpreted layer.

**Acceptance gate:** compare `nail_catdes(generate = FALSE)` versus `TRUE` as the statistical input to an otherwise identical enriched prompt, and inspect the incremental effect of reusing the prior CATDES generated summary. Keep machine-derived CATDES facts as the ranking of authority and trace every proposed text–statistic connection to a named CATDES characteristic and actually observed source texts. Preserve tensions, ambivalence, negative statements, conditional claims and minority views. A theme with no substantive CATDES counterpart may be a separate additional insight, **not** an invented contradiction or statistical finding.

The extraction helper `.extract_catdes_semantic_response()` retrieves a nonempty `response` when found, without itself checking a `generated` status or substantive validity. The distinct warning helper `.catdes_has_reused_llm_interpretation()` checks `status = "generated"`. Check malformed, stale and partially generated upstream semantic returns rather than assuming a warning is a scientific validator.

## 4. Canonical evidence and parsing invariants

| Area | Current guarantee | Additional operational challenge |
| --- | --- | --- |
| Groups | Same group-name sets required; CATDES groups must be `ready`; TEXTUAL profiles must be `available`. | Group-label agreement is not source-population identity. Test swapped or unrelated rows with identical labels, sparse groups and mismatched sets. |
| Statistical evidence | From `semantic_facing_evidence` and retained IDs; no CATDES recomputation. | Confirm only selected mechanical facts are attributed to CATDES, and a prior CATDES LLM response remains secondary. |
| Text provenance | Representative/tension IDs must belong to the **shown selection** and resolve to exact text and correct group. | Test duplicated text at separate source rows, invented ID, valid ID from another group and a sampled subset. No paraphrase should be treated as a literal respondent quotation. |
| Coverage | Both group response coverage and proportion of available texts used in the earlier textual profile are preserved. | Use the correct denominators; low coverage limits generality but is not evidence of absence of unreported themes. |
| Parser | Exactly five named fields expected; missing field returns `parse_failed`. | Test model output with Markdown headings, missing/renamed fields and structurally valid but **scientifically unsupported** linkages. |
| Local-first | Both isolated and combined return modes generate independently per group. | Count final LLM calls; no global reanalysis and no cross-group leakage. |
| LLM I/O | `llm_io` stores exact local prompts and raw responses; accessors public. | Preview must contain prompts but no responses; `nail_response()` returns only backend text, not parsed R summaries. |
| Lack of a text | Function fails closed if **any** group has no available textual profile. | Test whether whole-analysis refusal is appropriate for a composed operation when one group has no text; scientific decision before changing. |
| User controls | Custom introduction/request/conclusion and provider/model forwarded. | Verify unchanged user wording, coupled with statistical-anchor safeguards; no shared backend refactor. |

## 5. Review of existing tests and documentation

`tests/testthat/test-catdes-textual.R` already includes tests for canonical consumption, asymmetry, exact cited text resolution, missing textual profiles, differing group sets, combined local-first operation, structured parse, warning when CATDES LLM output is reused, `llm_io` accessors, missing fields, and text-driven scope. Those test cases demonstrate valuable implementation discipline, but largely rely on a constructed **mock textual profile** produced from a `generate = FALSE` preview and manually changed to `status = "available"`.

The `man/nail_catdes_textual.Rd` runnable illustration similarly manufactures a parsed textual profile for offline documentation, which is reasonable for determinism but **does not establish** that the full real LLM pipeline works end-to-end or is scientifically convincing.

**Operational test should therefore begin with live `nail_textual(generate = TRUE)`, not only an injected structured fixture.** Keep the mocked fixture as a separate regression baseline.

## 6. Recommended validation phases, before editing R code

**Phase A — real coherent study design, no code edits:** Create a realistic mixed quantitative/qualitative open-ended survey with ~3 distinct observed or latent groups; common group assignments for both upstream analyses; substantive domain such as access to local food or mobility constraints. Include plural viewpoints, negations, minority positions, duplicate responses, missing texts and a condition where text is relevant to only **one** CATDES characteristic rather than all. Run `nail_catdes(generate = FALSE)` and `nail_textual(generate = TRUE)` with a real installed local Ollama model, then `nail_catdes_textual(generate = FALSE)`. Preserve per-stage evidence and audit exact local prompts. Account for all upstream and composed LLM calls separately.

**Phase B — scientific comparison with live generated enrichments:** Under the same frozen source evidence, run `nail_catdes_textual(generate = TRUE)` in isolated and combined-local display. Evaluate the five fields, direct links to named CATDES markers, faithful source-text grounding, conflicts, unsupported cross-trait attribution, and persistence of minority statements. Verify that `additional insights` do not become spurious CATDES markers. Compare with/without reused **prior CATDES generated interpretation**, and with distinct sampling coverage. Use at least one sparse/ambivalent case where a weak synthesis is scientifically preferable.

**Phase C — edge conditions and gate decisions:** Different input datasets with **same** labels, nonidentical group names, missing group text, malformed textual IDs, poor coverage, repeated-person responses and malformed upstream CATDES profiles. Verify exact failure or warning semantics; discuss alignment guarantee, availability fallback, and observational-versus-person coverage language with the analyst.

**Phase D — only justified surgical corrections:** Make changes to `nail_catdes_textual()` code/test/Rd only when demonstrably required by Phases A–C. Preserve the existing five-field schema, CATDES statistical anchor, textual provenance, canonical objects and generic accessors unless the analyst explicitly authorizes a contract change. Rerun `devtools::load_all()`, targeted `devtools::test_active_file("tests/testthat/test-catdes-textual.R")`, upstream CATDES/TEXTUAL tests, `devtools::test()`, and `devtools::check(document = FALSE)` if Pandoc/processx available; report any environment limitation. Commit and push **only after** scientific review.

## 7. Future architecture audit contribution

This composition tests whether NaileR can combine *heterogeneous evidence types with different epistemic status* while retaining exact provenance. It is stronger evidence for a general interpretation architecture than a shared `.call_llm_base()` wrapper alone. We must not assume success merely because both upstream functions expose `nail_evidence()` and `nail_prompt()`. The general seven-function architecture audit is explicitly deferred until this composed function is finalized.
