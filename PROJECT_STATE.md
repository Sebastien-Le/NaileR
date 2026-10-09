# NaileR — PROJECT_STATE

> **State record prepared — 2026-10-09.** This file records the methodological decisions and development status established from the current repository state. Local operational artifacts remain separate from this memory file unless explicitly committed.

## 1. Source of truth and branch

- Repository: `https://github.com/Sebastien-Le/NaileR`.
- Development branch: `dev-statistical-prompt-framework`. The original state record was prepared from commit `5390ec1` (2026-10-09); **this is a historical reference, not the current HEAD**. Subsequent validated milestones include `7fd4303` (CATDES + TEXTUAL warning) and `4593546` (QDA-space warning). Always consult Git for the current HEAD. `master` has not yet integrated this development work.
- Declared package version at review: `2.1.0` (`DESCRIPTION`). The historical `CRAN-SUBMISSION` file refers to `1.2.3` and is not proof of a current submission.
- Operational validation scripts, exact prompts, responses and reports under `dev/operational_validation/` were executed and retained **locally and untracked** as reported by the analyst. They are not published GitHub artifacts and must not be added to a documentation-only commit.

## 2. Fundamental architectural principle — STABILIZED

**Evidence first, interpretation second.** Maintain a clear distinction between:

1. canonical evidence calculated or registered in R;
2. the selection and rendering of evidence shown to an LLM;
3. the LLM's interpretive hypotheses and syntheses;
4. the raw prompt and response, and their provenance.

`nail_evidence()`, `nail_prompt()`, and `nail_response()` are the shared public inspection interface for rebuilt workflows. Interpretation-only options must not silently alter canonical statistical evidence.

## 3. CATDES + TEXTUAL — SCIENTIFIC DECISION STABILIZED 2026-10-09

**Purpose.** Start from a **global interpretation of a group's CATDES profile**, developed by synthesizing a **combination of statistical characteristics**. Then confront that global interpretation with the group's open-ended responses. Texts may **illustrate, clarify, deepen, qualify, or call into question** the interpretive portrait. The final result is an **enriched global group interpretation**, not a second mandatory analysis of individuals.

**Use of respondent-level pairing.** When available, individual closed-question responses linked to each verbatim are an **optional interpretive resource**: they can help choose relevant examples, understand what a speaker means, and check whether a quotation is compatible with that person's declared characteristics. They are **not** an obligatory target for constructing within-group typologies, counting individual configurations, or printing individual profiles.

**Epistemic safeguards.**

- Never require a one-to-one explanation or quotation for every CATDES descriptor.
- Preserve the CATDES statistical evidence as the check on any global interpretation. The generated CATDES interpretation is a proposal, not new measured evidence.
- A divergent verbatim does not refute a group-level statistical association; it may instead qualify an over-generalized interpretation or describe an exception.
- Statements by respondents about their motives are **reported explanations**, not independently established causal mechanisms.
- Texts may introduce genuinely new themes that have no CATDES counterpart. Keep their textual provenance and evidential status clear.
- Keep selected quotes verbatim, identifiable through the canonical text registry, and avoid cherry-picking only confirming examples.
- Individual pairing must be verified before use; preserve missingness, group membership, exact wording, and respondent/text identifiers.
- Do not force the LLM to mention individual response values just because those values are available.

**Implication for prompts.** Give the LLM the task of examining the *global CATDES interpretation* in the light of discourse, not mechanically matching isolated CATDES variables to snippets. Treat individual closed responses as optional support for interpretation and validation, not an obligatory output section.

**Status.** Methodological purpose is stabilized. The final public API/prompt implementation is **not** yet approved. The A–D, B–E, and E–E2 experiments are exploratory; further prompt tuning is paused while the warning below remains open.

## 4. Operational experiments and deferred warning

A local reproducible experiment created 90 synthetic respondents in three groups and linked the closed-question responses and verbatims. The reported checks found 87 nonmissing texts, exact respondent/text matching, deliberate-mismatch rejection, and no mutation of CATDES/TEXTUAL canonical evidence. The study data were specifically simulated; this is not validation on a real survey.

On G2, four controlled contextualization conditions used the same upstream CATDES and TEXTUAL outputs:

- **A:** current CATDES + TEXTUAL contextualization;
- **B:** task centered on the global CATDES portrait;
- **C:** B plus additional verbatims;
- **D:** C plus the same speakers' individual closed responses.

Reported invariance controls were `TRUE`. One local `mistral-small3.2` response was generated per condition. In the first qualitative examination, the four interpretations remained similar and D did not visibly exploit individual closed responses in a traceable way. **This does not establish that pairing is useless**; it does not justify requiring explicit analysis of individual configurations either. Further intervention must be motivated by the stabilized purpose above.

The local experiments and blind-review material are exploratory, not a formal LLM benchmark.

### WARNING — Downstream propagation of LLM interpretive overreach (deferred, 2026-10-09)

**Observed:** In the G2 CATDES → CATDES + TEXTUAL composition, the existing upstream CATDES interpretation already included unsupported amplifications of the mechanical CATDES facts (e.g., a 90% frequency for the `supermarket` response was expressed as shopping *exclusively* at supermarkets; claims about choosing convenience *over product quality* were not measured). Downstream compositions frequently repeated such assertions. In the controlled E vs E2 comparison (three G2 generations per condition, frozen evidence and verbatims), all six responses repeated the unsupported exclusivity claim even though E2 explicitly instructed the model to treat the CATDES interpretation as revisable. E2 had 14/14 reported prompt-invariance checks and 3/3 parse-available outputs. This is evidence of a **risk of error propagation**, not a controlled demonstration of its causal mechanism or a proof that TEXTUAL caused the error.

**Risk:** An LLM interpretation reused by another LLM can acquire the appearance of an established fact, although only the underlying canonical CATDES results have statistical evidential authority.

**Decision and implementation:** The methodological risk remains **unresolved; deeper remediation deferred**. Commit `7fd4303` adds one non-blocking R warning when `nail_catdes_textual(generate = TRUE)` reuses a generated CATDES interpretation. This detects and signals the risk; it does not validate or correct the inherited claims. Stop the E/E2 prompt-variant loop. Do not impose individual-configuration analysis or change the API merely to address this issue now. When reviewing composed interpretations, distinguish mechanical facts from upstream and downstream hypotheses; revisit before claiming release-level semantic validation of CATDES + TEXTUAL.

**Provenance:** Controlled A–D, B–E and E–E2 experimental artifacts currently exist **locally and untracked** under `dev/operational_validation/`; they are not yet GitHub-published benchmarks.

## 5. Method inventory

| Domain | Functions / scope | State | Next action |
|---|---|---|---|
| Sensory profiles | `nail_qda()`, reusable product interpretations, `nail_qda_interpretation()` | Evidence-first rebuild substantially complete | Consolidate realistic interpretation checks; avoid unvalidated prompt proliferation |
| Sensory product space | `nail_qda_space()` | **Operationally validated on `sensochoc`**; PCA / latent CONDES / product evidence; one non-blocking LLM-reuse warning published in `4593546` | Preserve Dim2 interpretive limitation; retain expert review and compatibility documentation |
| Continuous targets | `nail_condes()` | Evidence-first rebuild with observed/latent modes | Limited additional applied checks |
| Group characterization | `nail_catdes_prep()`, `nail_catdes()` | Evidence-first rebuild, observed/latent and local/joint scope, canonical LLM I/O | Freeze evidence and prompt contracts once validated; safeguard 'latent profile' wording |
| Contingency profiles | `nail_descfreq()` | **Operationally validated on two local contingency tables**; prompt modularity/invariance verified | Validate interpretive quality on additional real tables when available; no immediate correction |
| Grouped texts | `nail_textual_prep()`, `nail_textual()` | **Operationally validated with reservations** on a local three-group case; registry, sampling, exact IDs, accessors and backward-compatible preview checked | Retain human review of themes, minority discourse and possible overinterpretation; no blocking correction observed |
| Composition | `nail_catdes_textual()` | Operational local workflow and global-portrait objective stabilized; runtime warning in `7fd4303`; interpretive-propagation issue remains open | Pause prompt calibration; revisit before release-level semantic validation |
| Epistemic review | `nail_catdes_ground()` | Optional assertion-level review implemented | Evaluate false reassurance/false alarms empirically |
| Sorting | `nail_sort()` | Historical export; **excluded from active development scope** | No new audit/refactor; evaluate deprecation/removal separately after dependency and compatibility review |
| LLM similarity/distance | `sim_llm()`, `dist_mat_llm()`, `dist_ref_llm()` | Historical exports; **excluded from active development scope** | No new audit/refactor; evaluate deprecation/removal separately after dependency and compatibility review |
| Compatibility | `nail_textual_contextualized()`, `nail_group_profile_prep()`, `nail_qda_spaceprep()` | Retained compatibility paths | Document modern replacement; preserve unless removal is deliberately planned |

### DESCFREQ — operational validation (2026-10-09)

Local Codex report (not a published benchmark): `FactoMineR::descfreq()` worked on two contingency tables, including a case with ambiguous/rare attributes. Six `generate = FALSE` previews covered isolated descriptions, global descriptions and comparisons. Four Ollama `mistral-small3.2` generation attempts were reported: three nonempty responses; one ambiguous case had no selected evidence and therefore no generated response, as expected. `sample.pct`, `drop.negative`, local/global scope and comparison did not change canonical `frequency_profiles`; `drop.negative = TRUE` changed only prompt evidence. `nail_evidence()`, `nail_prompt()`, `nail_response()` and stored LLM I/O were consistent.

A separate modularity check succeeded: changing `introduction`, `request` or `conclusion` changed only its intended prompt block; a reading-guide flag changed the internally built guide; evidence selection changed the prompt evidence but not canonical statistics. The guide has no public free-form `reading` parameter. Descriptive naming was mostly coherent with the dominant patterns, but substantive abstractions still require human inspection. **Status: operational on tested cases; no blocking correction. Not a claim of broad semantic validation.**

### QDA-space — operational validation and interpretive limits (2026-10-09)

Local Codex report using `SensoMineR::sensochoc`: six products, 13 sensory attributes, PCA of QDA adjusted means and `nail_condes(interpretation_mode = "latent")` axis characterization. With `min_inertia_pct = 0` in the operational script, Dim1 (88.79% inertia) and Dim2 (7.58%) were interpreted. Six real Ollama `mistral-small3.2` QDA product interpretations were available and parsed; two real QDA-space axis responses were generated. QDA profiles remained invariant, and evidence/prompt/response accessors and LLM I/O were coherent. Expert-edited summaries and statistical-only fallback paths were also exercised.

Qualitative review: **Dim1** captured a coherent cacao/bitter/astringent versus milky/sweet/melting opposition, although some language exceeded measured sensory facts. **Dim2** was much less substantiated: no CONDES sensory attribute was retained at the tested threshold, some pole exemplars had weak representation (notably `choc3`), and the LLM nevertheless proposed an overly coherent opposition. The low-inertia Dim2 would not have been retained with the function's default `min_inertia_pct = 10`; the operational script deliberately set it to zero. This is a **known scientific interpretation limitation**, not an observed blocking R defect.

Commit `4593546` adds a single non-blocking warning for `generate = TRUE` **only if** an `available` `llm_pass1` product `core_profile` is actually reused among displayed pole products. No specific warning is emitted for expert-only or statistical-only prompts or for previews. It changes neither PCA/QDA/CONDES evidence nor prompt composition. Codex reported 34 passing focused tests and 1,154 passing package tests, with no failures/warnings; these results were **reported from the local R session**, not independently re-executed here. **Status: operational on the tested case; warning published; scientific limitation retained for future review.**

### TEXTUAL — final operational validation (2026-10-09)

Local Codex report (not committed to GitHub) on 54 source rows across G1/G2/G3, of which 52 had nonempty texts: exact stable `TXT######` IDs, group membership and canonical registry were verified. `textual_evidence` remained invariant between `sample.pct = 1` and `0.5`; a fixed seed reproduced the same selection, and no unselected text was represented as available to the LLM. `nail_evidence()`, `nail_prompt()` and `nail_response()` worked; `nail_textual_prep(generate = FALSE)` remained compatible. Three previously generated real Ollama outputs were reused, without new calls; cited text IDs belonged to the displayed samples. Targeted local tests: **149 PASS, 0 FAIL, 0 WARN**; `devtools::load_all()` and `git diff --check` were reported OK, with no tracked package files changed. Local script/report/results are under `dev/operational_validation/textual_final/` and remain untracked.

**Decision: TEXTUAL validated with reservations on the tested workflow.** Continue human review of narrative synthesis, minority voices and possible overinterpretation; no technical blocker demonstrated. Do not open an additional TEXTUAL refactoring/prompt-tuning pass during the one-day stabilization sprint.

### CROSS-METHOD — final integration smoke (2026-10-09)

Local Codex report (untracked; not an independent execution here) used existing operational evidence and raw LLM responses, with **zero new LLM calls** and no edits to `R/`, `tests/` or `man/`. All **50/50 cross-method assertions passed**, `git diff --check` was clean, and a temporary `Rplots.pdf` was removed. The reviewed workflows were `nail_condes()` (standard and latent), `nail_catdes_prep()`/`nail_catdes()`, `nail_descfreq()` (local, global, comparison), `nail_qda()`, `nail_textual_prep()`/`nail_textual()`, `nail_catdes_textual()` and `nail_qda_space()`. Previews, public evidence/prompt/response accessors where applicable, and reuse of established operational artifacts were consistent. No new blocking defect was reported.

**Decision:** core NaileR workflows are ready to move to **documentation and packaging**, subject to those final checks; this does not establish full scientific/semantic validation. Document intentional differences: TEXTUAL is local-first even with `isolate.groups = FALSE`; latent modes describe constructed targets; composed LLM interpretations can trigger provenance warnings and require expert oversight; QDA-space axes lacking retained CONDES associations should not be overinterpreted. Report/script exist locally under `dev/operational_validation/cross_method_final/`, not in GitHub.

### DOCUMENTATION — source-selection rule for final sprint

Reuse and verify **existing historical NaileR applications** first. Search `vignettes/NaileR-vignette.Rmd`, `R/datasets.R`, `R_old/`, `R_old_old/`, `README.md`, and especially `dev/NaileR_operational_book_baseline.R` and `dev/NaileR_operational_stabilization_examples.R`. Prefer supplied real datasets: iris (observed CATDES), atomic habits/waste/local food (latent CATDES), decathlon (observed/latent CONDES), beard_cont (DESCFREQ), fabric (TEXTUAL), sensochoc from SensoMineR::chocolates (QDA/QDA-space), plus an aligned CATDES+TEXTUAL case. Keep substantive **introduction** and **request** grounded in the original scientific context, adapt to the current API and accessors, and avoid unsupported causal/scoring requests in historical prompts. The old `inst/extdata/res_iris.rds` and `res_waste.rds` response structures must not be assumed compatible. The vignette must build **without requiring Ollama or Gemini** and should not inadvertently execute expensive LLM calls. Explicitly verify whether README installation instructions target the development branch rather than default `master`. Do not fabricate example outputs.

## 6. Remaining cross-cutting work, priority order

1. **Composed interpretations:** CATDES + TEXTUAL and QDA-space are operational on tested cases with published non-blocking reuse warnings; propagation/semantic overreach remains a **known unresolved scientific risk**. Do not relaunch prompt tuning merely to chase this risk or require individual configurations.
2. **Scientific validation:** collect diverse realistic cases; evaluate factual fidelity, interpretive value, causality overreach, provenance, diversity and limitations. DESCFREQ needs additional real contingency tables; QDA-space needs scrutiny of weakly characterized axes. Do not mistake parser/test success for semantic reliability.
3. **Scoped maintenance:** freeze new feature work; reserve code edits for demonstrated release-blocking issues in retained workflows. Defer CATDES grounding evaluation and additional QDA/CONDES studies to a later scientific-validation phase. Do not spend the one-day stabilization budget auditing historical SORT/distance exports.
4. **Documentation:** update the historical primary vignette to evidence-first usage; retain examples and demonstrate `introduction`/`request` importance, observed vs latent modes, user inspection/accessors.
5. **CI and packaging:** add practical automated `testthat`/`R CMD check` workflow; perform local package check and reverse-dependency/consumer review (including PolisheR) before version publication.
6. **Compatibility and release:** document legacy aliases, migration notes, `NEWS.md`, version choice, and branch integration; avoid merging uncommitted experimental artifacts blindly.

## 7. Rules for future PASS tasks

- Start from the current Git HEAD and relevant canonical source; never substitute historical archives for it.
- State the *scientific question* and *what is held invariant* before prompting or editing.
- Prefer small external experiments in `dev/operational_validation/` before changing exported functions.
- For code changes: `devtools::load_all()` -> realistic manual example -> targeted `devtools::test_active_file()` -> `devtools::test()` -> optional `devtools::check()` -> `git diff` -> targeted commit/push after authorization.
- Keep the statistical facts, original individual responses, and LLM interpretations distinguishable.
- Do not treat local untracked artifacts as present in GitHub; audit before committing or ignoring them.

## 8. Immediate next work — ONE-DAY STABILIZATION SPRINT (decision 2026-10-09)

**Objective:** prepare a credible, installable, documented **internal release candidate** from the retained evidence-first workflows within approximately one full workday. This is **not** a commitment to CRAN submission or release-level semantic validation in one day.

**Core scope:** CONDES, CATDES (including preparation), DESCFREQ, QDA and QDA-space, TEXTUAL (including preparation), CATDES + TEXTUAL, and inspection through `nail_evidence()`, `nail_prompt()`, `nail_response()`. `nail_catdes_ground()` remains optional/experimental. Historical SORT (`nail_sort()`) and LLM distance/similarity exports (`sim_llm()`, `dist_mat_llm()`, `dist_ref_llm()`) are **out of active development scope**, but not yet removed from the public API: first check compatibility and dependents. Keep historical aliases unchanged unless a blocking defect is established.

**Time budget (analyst's full workday: 12–14 hours; target 13 hours / 780 minutes):** 45 min scope/freeze; 90 min targeted TEXTUAL applied validation with missing/short texts, sampling, accessors and a few real calls; 120 min cross-method smoke tests and regression review for the retained workflows; 180 min essential vignette/examples and user-facing guidance; 180 min `devtools::test()`, build, install and `devtools::check()`/R CMD check including necessary blocking fixes; 75 min export/dependency compatibility, Git review and release-candidate notes; 90 min contingency reserve. If constrained to 12 hours, shorten documentation polish and contingency; if 14 hours are available, invest the extra time in independent installation/check and example review, not new features or broad prompt retuning. Release gates and priority order still prevail.

**Release gates:** (i) clean, reproducible R installation/build; (ii) required workflows either demonstrated operational or carry an honest documented limitation; (iii) no newly introduced blocking test/check failures; (iv) usable README/vignette with direct evidence/prompt/response examples, user `introduction`/`request`, modes, known interpretive risks; (v) explicit list of unresolved non-blockers; (vi) focused Git commits with local operational artifacts preserved and untracked unless intentionally selected. Do not change canonical evidence contracts during the sprint.

**Order:** TEXTUAL final smoke is complete (149 passing targeted tests; validated with reservations), and cross-method checks are complete (50/50 passing assertions, no new LLM calls). **Next: prepare historically grounded essential documentation and then build/install/package check**, fixing only demonstrated release blockers. Run an additional clean install/check if time permits. No refactoring of SORT/distance, no blanket removal of exports, no new semantic prompt experiments. Commit/push package code only after review; later decide branch integration, version and CRAN readiness separately.

**Known limitations:** TEXTUAL group syntheses may overstate minority/majority patterns and require human review; CATDES + TEXTUAL and QDA-space may propagate upstream LLM interpretation errors; published runtime warnings signal but do not solve them. QDA-space weakly characterized axes can yield unjustifiably coherent prose. DESCFREQ and other outputs require human interpretive review. Local operational materials under `dev/operational_validation/` are not GitHub-published.

