# NaileR — PROJECT_STATE

> **State record prepared — 2026-10-09.** This file records the methodological decisions and development status established from the current repository state. Local operational artifacts remain separate from this memory file unless explicitly committed.

## 1. Source of truth and branch

- Repository: `https://github.com/Sebastien-Le/NaileR`.
- Development branch at review: `dev-statistical-prompt-framework`, parent HEAD `5390ec1` (2026-10-09). This documentation commit establishes the present project-state record; `master` has not yet integrated this development work.
- Declared package version at review: `2.1.0` (`DESCRIPTION`). The historical `CRAN-SUBMISSION` file refers to `1.2.3` and is not proof of a current submission.
- Recent operational validations (including CATDES + TEXTUAL individual grounding) were executed locally but remain **untracked**. Do not mistake them for published GitHub artifacts or include them in this documentation commit.

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

**Decision:** Record as **known methodological warning — unresolved; remediation deferred**. Stop the E/E2 prompt-variant loop. Do not impose individual-configuration analysis, change the API, or modify package code merely to address this warning now. When reviewing composed interpretations, distinguish mechanical facts from upstream and downstream hypotheses; return to this issue before claiming release-level semantic validation of CATDES + TEXTUAL.

**Provenance:** Controlled A–D, B–E and E–E2 experimental artifacts currently exist **locally and untracked** under `dev/operational_validation/`; they are not yet GitHub-published benchmarks.

## 5. Method inventory

| Domain | Functions / scope | State | Next action |
|---|---|---|---|
| Sensory profiles | `nail_qda()`, reusable product interpretations, `nail_qda_interpretation()` | Evidence-first rebuild substantially complete | Consolidate realistic interpretation checks; avoid unvalidated prompt proliferation |
| Sensory product space | `nail_qda_space()` | Canonical PCA / latent CONDES / product evidence path implemented | Audit semantic quality of axis and pole descriptions; keep QDA compatibility route documented |
| Continuous targets | `nail_condes()` | Evidence-first rebuild with observed/latent modes | Limited additional applied checks |
| Group characterization | `nail_catdes_prep()`, `nail_catdes()` | Evidence-first rebuild, observed/latent and local/joint scope, canonical LLM I/O | Freeze evidence and prompt contracts once validated; safeguard 'latent profile' wording |
| Contingency profiles | `nail_descfreq()` | Evidence-first rebuild implemented | Focused prompt/interpretation audit and applied examples |
| Grouped texts | `nail_textual_prep()`, `nail_textual()` | Canonical text registry, selection, parsing and traceability implemented | Investigate parser robustness, sampling and representative/tension texts |
| Composition | `nail_catdes_textual()` | Technically operational; global-portrait objective stabilized; interpretive-propagation WARNING open | Pause prompt calibration; preserve warning and revisit before release-level semantic validation |
| Epistemic review | `nail_catdes_ground()` | Optional assertion-level review implemented | Evaluate false reassurance/false alarms empirically |
| Sorting | `nail_sort()` | Historical JSON-based workflow with validation | Add targeted malformed-output, retry and API-behavior tests |
| LLM similarity/distance | `sim_llm()`, `dist_mat_llm()`, `dist_ref_llm()` | Historical utilities | Audit score parsing, variability, missing output, tests |
| Compatibility | `nail_textual_contextualized()`, `nail_group_profile_prep()`, `nail_qda_spaceprep()` | Retained compatibility paths | Document modern replacement; preserve unless removal is deliberately planned |

## 6. Remaining cross-cutting work, priority order

1. **CATDES + TEXTUAL:** objective stabilized and exploratory A–D, B–E, E–E2 comparisons reviewed. **Known methodological warning** about propagation of upstream overinterpretation recorded in §4; further prompt tuning and code changes are **deferred**. Do not require individual configurations.
2. **Scientific validation:** maintain diverse operational cases; evaluate factual fidelity, interpretive value, causality overreach, provenance, diversity, and limitations. Do not treat parser success as semantic quality.
3. **Targeted maintenance:** finish QDA-space / DESCFREQ interpretation review and assess optional CATDES grounding; test `nail_sort()` and distance utilities.
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

## 8. Immediate next work

Move past CATDES + TEXTUAL prompt variants with the above warning explicitly open. Prioritize a **focused, realistic operational review of `nail_descfreq()`**, starting from the current implementation, documentation, and tests before proposing any code change. Record observed interpretation issues separately from mechanical or API defects. Then continue the remaining targeted maintenance and scientific validation work in §6.
