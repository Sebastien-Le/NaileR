# CORE 5 / CONDES — runtime prompt integration, first implementation review

**Date:** 2026-10-15
**Status:** TECHNICALLY VALIDATED LOCALLY (2026-10-15) — READY FOR INTEGRATION. LLM interpretation quality remains model-dependent.
**Integration branch:** `dev-core5-condes-integration-20261015`.
**Source branch / intended merge target:** `dev-statistical-prompt-framework`.
**Approved scientific source:** [CONDES_MODULAR_PROMPT.md](reading_review/CONDES_MODULAR_PROMPT.md).

## 1. Scope of the staged changes

Changed **only**:

- `R/nail_condes.R`: replace the body of `build_guide_condes()`, `.build_condes_interpretation()` and `build_conclusion_condes()` with the approved CONDES scientific operational wording; keep the standard/latent identity distinction and a short per-target task. The `.build_condes_interpretation()` call now also passes the unchanged original R variable name so a custom `target_label` cannot conceal its source identifier.
- `tests/testthat/test-condes-semantic-rebuild.R`: update obsolete literal prompt expectations to match the approved science; add focused assertions for the output wording, intro/request/conclusion overrides, optional `target_concept`, and custom display labels.

The six established top-level prompt blocks remain `context`, `reading`, `question`, `interpretation`, `evidence`, `output`. To avoid changing the six-block contract, the approved `identity` and `task` texts are included as separately headed subsections of `interpretation`, not as new top-level blocks.

The approved `reading` omits generic descriptions of R sampling/undisplayed evidence. Sampling parameters, significance threshold and derived-state threshold still control the existing R logic and remain inspectable in returned settings/evidence. The approved editable `output` no longer forces Quarto formatting; no dedicated CONDES parser requires it.

## 2. What was statically checked

Using the GitHub file snapshots on the base and integration branches, an initial comparison with the three prompt helper functions excluded showed **all other text in `R/nail_condes.R` byte-identical**. A subsequent narrowly scoped update passed the existing `target_variable` identifier into the interpretation builder to preserve it alongside a custom presentation label; no statistical-computation logic was edited. The original `FactoMineR::condes()` call, canonical `continuous_profile` construction, registry, evidence-selection logic, R accessors and LLM call/return paths were not edited. Approved key English paragraphs were present in the new R helper bodies. Test-file modifications are confined to existing prompt wording tests plus two new focused cases.

**This is NOT proof of runtime invariance, syntactic correctness or test success:** this environment has no R/Rscript. There was no execution of `devtools::load_all()`, `devtools::test()`, `devtools::check()`, or actual Ollama/Gemini generation. Do not merge the integration branch or mark CONDES complete on the basis of a static comparison.

## 3. Decisions and compatibility risks to inspect before merging

1. **`prompt_style` option:** `"detailed"` and `"compact"` remain legal and still appear in settings, but the approved scientific `reading`, `interpretation` and `output` wording is now **identical** across both: compact no longer shortens these blocks. This is a semantic compatibility change to assess. Do not silently claim the compact output is preserved.
2. **`target_concept` option:** an explicit, non-default user-provided concept still appears in the latent interpretation as guidance (the original non-forcing caveat is retained). Confirm that an analyst-supplied hypothesis is not presented as a measured property.
3. **`target_label` versus source variable identifier:** the task uses the analyst's presentation label and the identity subsection now explicitly retains the original dataset column identifier when the two labels differ. A focused regression assertion was added; runtime verification remains pending.
4. **Six-block contract:** adding `### Target Identity` and `### Task` inside the interpretation block retains the structural API but alters its inner formatting. Verify downstream clients do not assume the interpretation block consists only of plain sentences.
5. **Default `output` behavior:** approved editorial wording replaces the historical summary headings and the Quarto requirement. Caller-supplied `conclusion` remains unchanged. Confirm downstream PolisheR or other clients do not parse the historical heading structure.
6. **Target-specific parameter narration:** the new reading omits the previously prompt-visible numeric `quanti.threshold` and `proba` explanations. This follows the approved editorial decision not to explain sampling, but the end-state threshold may still be useful analytical context; examine whether existing evidence is sufficiently self-explanatory.
7. **No contract expansion:** do not add unapproved categories, statistical transformations, hidden inferred pairwise relations, or new fields while closing this pass.

## 4. Required local R checks

After checking out the integration branch in the repository:

```r
devtools::load_all()

# These will need to pass after updating the literal wording assertions.
devtools::test_active_file("tests/testthat/test-condes-semantic-rebuild.R")
devtools::test()

# Manual no-LLM verification with a realistic FactoMineR dataset.
data(decathlon, package = "FactoMineR")
a <- nail_condes(decathlon, num.var = 12,
                 interpretation_mode = "standard", generate = FALSE)
b <- nail_condes(decathlon, num.var = 12,
                 interpretation_mode = "latent", generate = FALSE)

stopifnot(identical(
  attr(a, "continuous_profile", exact = TRUE),
  attr(b, "continuous_profile", exact = TRUE)
))
stopifnot(identical(
  nail_evidence(a), nail_evidence(b)
))

cat(nail_prompt(a, print = FALSE))
cat(nail_prompt(b, print = FALSE))

devtools::check()
```

Additional targeted manual checks:

- Sample selection `sample.pct = 1` versus `0.5` (same canonical evidence, selected evidence may differ); use both selection strategies.
- `interpretation_mode = "standard"` versus `"latent"` on the **same dataset**, including negatively oriented score variables and user-supplied scale semantics.
- `prompt_style = "detailed"` and `"compact"`, noting the open compatibility question.
- Custom `introduction`, `request`, `conclusion`, `target_label`, and `target_concept`; compare exact blocks and source column labels.
- A sparse/no-significant-finding case and an ambiguous mixture of positive and negative associations.
- At least one true `generate = TRUE` Ollama example, inspected for faithful numerical direction, correct statistical reference, and non-speculative substantive synthesis.
- Verify `nail_prompt()`, `nail_response()` and `nail_evidence()` in preview and generated modes, along with representative downstream clients.

## 5. Merge gate

Before merging into `dev-statistical-prompt-framework`, retain local test logs and generated prompts, compare this staged diff, resolve or explicitly accept the noted compatibility concerns, run a final local check, and record analyst confirmation. Proceed to CATDES only after CONDES is genuinely finalized. Until then the core-five scope freeze continues.

### Provenance note

The historical `PROJECT_STATE.md` records earlier CONDES and cross-method tests on the older runtime. They do **not** certify the newly integrated scientific blocks staged on this branch.


## 6. Completed local technical validation — 2026-10-15

**Source of verification:** Local execution and results reported by the analyst and Codex on the integration branch. The earlier sections document the original pre-execution review; they are preserved as historical checkpoints, not the current validation status.

- `devtools::load_all()`: successful.
- `devtools::test_active_file("tests/testthat/test-condes-semantic-rebuild.R")`: 105 PASS, 0 FAIL, 0 WARN.
- `devtools::test()`: 1,299 PASS, 0 FAIL, 0 WARN.
- `R CMD build`, `R CMD INSTALL` and smoke test from a temporary library: successful.
- Full `devtools::check()` from RStudio: **0 errors, 0 warnings, 1 NOTE** (`checking for future file timestamps ... unable to verify current time`, environmental). Vignettes and rebuilding outputs succeeded.
- Canonical `continuous_profile`, `nail_evidence()` and statistical profiles compared equal across tested standard/latent, presentation style and evidence-selection settings.
- `generate = FALSE` preview and real `generate = TRUE` Ollama (`mistral-small3.2`) runs exercised. `nail_prompt()`, `nail_response()`, `nail_evidence()`, source variable identity and custom `target_label` verified.
- Follow-up fix committed: a source-safe `R\u00B2` escape renders as `R²` in prompts, without a non-ASCII source-code warning. `.Rbuildignore` excludes three local validation artifacts without removing them.

**Accepted/recorded behavior:** `prompt_style = "compact"` and `"detailed"` currently render the same approved scientific guidance; the default final output no longer mandates Quarto formatting. These are known editorial/compatibility changes, not hidden assurances of historical textual equivalence.

**Separately recorded interpretive experiment:** On the first PCA component of `FactoMineR::decathlon`, 15 local model generations compared current prompt A, added verification B and R-derived directional assistance C: 4/5, 4/5 and 5/5 directionally coherent responses respectively. This small single-case exploratory study does **not** establish general superiority of C or a technical defect in the package. No new CATDES/QDA or other scope was authorized by that study. Full local prompts, generations and review remain in untracked `dev/operational_validation/condes_abc/`.

**Technical closeout decision:** CONDES is technically finalized for the current five-function stabilization effort. No further CONDES prompt optimization is a prerequisite for starting CATDES. The package's R-statistical truth and model-generated interpretation are separate responsibilities; substantive LLM outputs require analyst review.
