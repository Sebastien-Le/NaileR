# NaileR — composed CATDES–TEXTUAL finalization review

**Date:** 2026-10-16  
**Status:** **TECHNICALLY FINALIZED AND ACCEPTED** for incorporation in the development branch. This is not a complete package/release certification and does not validate every LLM narrative.  
**Code commit:** [`8239e3b871e80068d922f764f01703d8afb95d1d`](https://github.com/Sebastien-Le/NaileR/commit/8239e3b871e80068d922f764f01703d8afb95d1d)  
**Branch:** `dev-composed-catdes-textual-20261016`  
**Initial audit:** [`COMPOSED_CATDES_TEXTUAL_INITIAL_AUDIT.md`](COMPOSED_CATDES_TEXTUAL_INITIAL_AUDIT.md)  
**Tracked implementation files, and only those:** `R/nail_catdes_textual.R`, `man/nail_catdes_textual.Rd`, `tests/testthat/test-catdes-textual.R`.

## Accepted user-facing contract

`nail_catdes_textual(catdes = existing_catdes_result, textual = existing_textual_result, generate = ...)` **remains the only current input design**. The user explicitly chose scientific composability: explore CATDES and TEXTUAL separately, inspect intermediate objects, and then synthesize them. **Do not add** `dataset`, `num.var`, `num.text`, `quali` or `quanti` to this composed function. Do not alter primary `nail_catdes()` / `nail_condes()` APIs to accommodate optional textual columns.

Analyst **assumes responsibility** for the scientific comparability of the populations, study waves and group assignments underlying the two supplied objects. Code verifies compatible **group names** and available sources, *not* row/person identity; no compulsory IDs, dataset fingerprints or recurring alignment warnings are approved. The assumption must be documented without presenting same group names or sample sizes as proof of source identity.

The composition is **local-first** with an independent prompt and model call per group; `isolate.groups` controls the outward result shape, not whether groups are compared in a single model call. No CATDES or TEXTUAL re-estimation is performed. `generate = FALSE` creates a preview with no composed-model calls. Prior TEXTUAL profiles must already be parsed and available, typically from `nail_textual(generate = TRUE)`.

## Source-of-truth boundary — accepted Phase 3 solution B

Statistical CATDES selected facts are read from:
`contextualized_evidence$groups[[g]]$statistical_anchor`.

Each group in `contextualized_profiles` now exposes additive `statistical_anchor_authoritative`, a deterministic projection of that canonical anchor, including the mechanical factual text and selected evidence identifiers/metrics. It is not a new independent statistical analysis. This remains available with `generate = FALSE`, missing responses, or LLM parse failures.

The five historically parsed LLM output fields remain: `statistical_anchor`, `textual_enrichment`, `additional_insights`, `internal_diversity`, `contextualized_profile`. The LLM-produced `statistical_anchor` field is a **narrative proposal**, never promoted to a verified CATDES fact. Its raw text and all exact prompts remain auditable in `llm_io` and public `nail_prompt()` / `nail_response()` accessors. The prompt received a minimal extra CATDES/textual separation instruction, without an open-ended restructuring of instructions or changes to upstream primary methods.

TEXTUAL profiles derive from observed texts, selected examples/anti-examples, source `TXT%06d` IDs, and existing model interpretation. Model-derived themes and a previous optional CATDES model summary are **not statistically independent evidence** validating CATDES. Selected CATDES evidence and original textual responses carry different epistemic statuses.

## Operational and test evidence

**Phase 1:** realistic, 3-group coherent study; actual `mistral-small3.2` run; 3 TEXTUAL upstream and 6 composed local/combined LLM calls. Three textual profiles parsed, as did all composed outputs. `TXT%06d` references were verified against selected source texts. One subgroup had only 5 nonempty texts out of 15 observations (33.3% response coverage), and the analysis properly separates corpus response coverage from prompt interpretation coverage. An all-empty subgroup refused composition rather than inventing a profile. The same group labels in unrelated statistical/textual objects were accepted, proving the absence of automatic population alignment checks. A generated `Statistical anchor` included `limited evening service` found only in qualitative responses; other text generalized 'main transport mode' to 'exclusive car use'.

**Phase 2:** a scientific-design comparison accepted **option B**, deterministic authoritative CATDES anchor separate from LLM proposal, rather than reliance on stricter prompting alone. The two-object interface and analyst comparability responsibility were reaffirmed.

**Phase 3:** added the deterministic field and a minimal prompt clarification while preserving public inputs and schema. Codex-reported checks: **94 targeted PASS, 1,475 full-suite PASS, 0 FAIL, 0 WARN**; `devtools::document()`, `git diff --check` OK. Six live `mistral-small3.2` composed calls (three local and three combined); all three group profiles parsed under each outward mode; canonical composed evidence and local/combined evidence remained identical; deterministic anchors exactly reproduced source CATDES facts. These were local operational validations **reported and reviewed**, not independently repeated on GitHub.

GitHub commit verification: `8239e3b871e80068d922f764f01703d8afb95d1d` touches exclusively three approved files; local untracked `dev/operational_validation/` and `tests/testthat/Rplots.pdf` were not included in that commit.

## Accepted limitations and postponed assessments

1. Parser success means that five fields were extracted; it is **not an epistemic validator** of their narratives.
2. LLM output may still overgeneralize, notably claiming a group uses cars **exclusively** where CATDES described cars as the **main** reported mode, despite occasional transit being mentioned in verbatims. Keep the LLM narrative visible and require analyst review. R's authoritative anchor must never absorb these extrapolations.
3. `statistical_anchor_authoritative` is authoritative for the **selected CATDES facts supplied to the composed stage**, not an unrestricted reconstruction of all unselected data or a certification that the statistical assumptions hold.
4. Input populations and grouping assignments are not automatically aligned; the analyst knowingly accepts responsibility.
5. Complete `R CMD check` with functional Pandoc/vignette tools and comprehensive documentation-example validation remain separate package release requirements.

## Next approved work

Both composed functions, `nail_qda_space()` and `nail_catdes_textual()`, are now technically finalized. Next: a **read-only, code-grounded global architectural audit** covering seven functions `nail_condes()`, `nail_catdes()`, `nail_descfreq()`, `nail_qda()`, `nail_textual()`, `nail_qda_space()`, `nail_catdes_textual()`. Evaluate shared scientific and software contracts, genuinely shared/reusable components versus duplication, different epistemic guarantees, LLM I/O, preview/generation semantics, upstream/composition contracts, provenance, compatibility, maintainability and scientific risks. Do **not** start a generic framework rewrite merely because functions look similar. After audit/decisions: verify examples, documentation and vignettes and only then assess provider backends (local Ollama vs remote Gemini) and release gates.
