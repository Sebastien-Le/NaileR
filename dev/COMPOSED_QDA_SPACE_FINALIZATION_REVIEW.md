# NaileR — composed QDA-space finalization review

**Date:** 2026-10-16  
**Disposition:** **TECHNICALLY FINALIZED — approved for integration and progression to `nail_catdes_textual()`**. Does not establish whole-package release readiness or independently re-execute R/Ollama checks.  
**Code commit:** [`67bca18a1e2428bde570ed5a16cf0d969169197b`](https://github.com/Sebastien-Le/NaileR/commit/67bca18a1e2428bde570ed5a16cf0d969169197b)  
**Branch:** `dev-composed-qda-space-20261016`.  
**Initial audit:** [`COMPOSED_QDA_SPACE_INITIAL_AUDIT.md`](COMPOSED_QDA_SPACE_INITIAL_AUDIT.md).  
**Only tracked code change files:** `R/nail_qda_space.R`, `man/nail_qda_space.Rd`, `tests/testthat/test-qda-space-condes-engine.R`.

## Scientific and software contract

The composed flow uses canonical QDA adjusted product means to form an ACP/PCA with `FactoMineR::PCA()`; `nail_condes()` runs in latent preview mode on the same product–attribute data to provide *descriptive* attribute–axis characterizations. CONDES correlation and selection `p_value` must **not** be sold as independent validation of a PCA axis. PCA inertia, axis geometry (`coordinate`, `contribution`, `cos2`), QDA product marker profiles and optional source-labelled QDA product summaries remain distinct bodies of evidence.

Following realistic `SensoMineR::sensochoc` operational validation and Ollama `mistral-small3.2` trials, the guide was made clearer about axis asymmetry, contributions vs cos², the arbitrary sign of dimensions, descriptive vs independent inferential status, and avoidance of unsupported cultural, hedonic and marketing vocabulary. Correlations shown in prompts now use three decimal places without modifying underlying R-derived coefficients.

**Deterministic eligibility control (Phase 4):** every retained axis carries `characterization_status` derived from the number of selected quantitative associations under `condes_proba`:

- `associations_selected`: final axis LLM generation is eligible.
- `no_selected_associations`: no LLM call for that axis; preserve the complete axis and original upstream evidence and provide an explicitly R-derived deterministic limitation/restitution, **not** an LLM response.

This is a *selection-limited status*, not a claim that the PCA axis is intrinsically devoid of meaning. Raising `condes_proba` can change eligibility, but it does **not** independently validate the component. `nail_prompt()` retains an auditable candidate prompt for each axis, including non-sent axes; `nail_response()` shows only real model responses. Mixed generated/non-generated axis output must never misrepresent deterministic R text as an API response.

Canonical adjusted means, PCA/eigenvalues, full CONDES objects and end profiles, QDA retained marker IDs, expert-edited and model-assisted product interpretation provenance, public function arguments and legacy compatibility paths are preserved. `generate = FALSE` sends no LLM calls.

## Local operational evidence (reported and reviewed, not independently re-executed on GitHub)

**Real corpus:** `SensoMineR::sensochoc`, 6 products × 14 sensory attributes. Scaled PCA: Dim1 **88.79% inertia**, Dim2 **7.58%**. Under `condes_proba = 0.05`, Dim1 had **8 selected correlations** and Dim2 **0**. A particularly useful geometric caution is that choc3 accounts for approximately **75.0% of Dim1 contribution**, while some Dim2 pole examples had very low cos² (choc3 about **0.008**).

**Phase 2:** 13 Ollama calls demonstrated strong Dim1 characterizations, but overly confident Dim2 interpretation and occasional `traditional/modern/indulgent` language in broad interpretation modes.  
**Phase 3:** prompt-only scientific improvements; 67 focused PASS, 1,429 whole-suite PASS reported. Five aligned LLM calls still revealed *residual* Dim2 over-interpretation, justifying the Phase 4 deterministic guard.  
**Phase 4:** `sensochoc` with two axes, `condes_proba = 0.05`: **Dim1 generated, Dim2 deterministic, one Ollama call only**. At `condes_proba = 1`, both were eligible (exploratory sensitivity, **not inferential support**). Synthetic mixed eligibility case passed. Reported tests: **93 focused PASS; 1,455 full-suite PASS; 0 FAIL/WARN**, `devtools::document()` and `git diff --check` OK; canonical input/evidence invariance reported true. `git diff --cached --check` passed before targeted push.

**Git verification:** the branch remotely points to `67bca18a1e2428bde570ed5a16cf0d969169197b`, commit touches exactly the three approved files, and there is no divergence relative to the prior development branch. The untracked local `Rplots.pdf`, `tests/testthat/Rplots.pdf` and `dev/operational_validation/` remained excluded from the code commit.

## Nonblocking limitations and deferred work

1. **Accessor UX:** `nail_prompt()` retains an *unsubmitted candidate* for ineligible axes. Asking `nail_response(select = "Dim2")` when only Dim1 was generated may currently yield `Unknown select` rather than an explanatory `no LLM call` message. This is not data/provenance corruption; consider after the seven-function architecture review.
2. **Scientific interpretation:** eligibility is necessary but not sufficient for epistemic soundness. Under `expertise_mode = "hybrid"`, speculative product-cultural/marketing wording remains possible from the LLM. Keep human review and core QDA/PCA/CONDES evidence accessible. Relative LOWER QDA marker scores must not be described as proven absolute absence.
3. **Package release:** a complete R CMD check in an environment with functional Pandoc, processx and vignette tools has **not** been established; preserve this gate for the documentation/release stage.

## Next step

Fast-forward the integration branch, open a dedicated `nail_catdes_textual()` audit branch, and perform **static/source and realistic operational validation before edits**. Preserve statistical CATDES and textual evidence as different sources with their own provenance and interpretive status. Once both composed functions are technically finalized, conduct the explicit general seven-function architecture audit before documentation examples and local-vs-external LLM comparison.
