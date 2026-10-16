# CORE 5 / QDA — initial scientific and architectural runtime audit

**Date:** 2026-10-16  
**Status:** **STATIC AUDIT COMPLETE — IMPLEMENTATION NOT STARTED; NO LOCAL R TESTS OR LIVE LLM CALLS IN THIS AUDIT.**  
**Audit branch:** `dev-core5-qda-integration-20261016`; starting HEAD `3f6af8444c9ddb44ae7fab3504cd78c5b0d68ce7`.  
**Approved scientific references:** [`QDA_MODULAR_PROMPT.md`](reading_review/QDA_MODULAR_PROMPT.md) and [`QDA_ASSEMBLY_REVIEW.md`](reading_review/QDA_ASSEMBLY_REVIEW.md), approved 2026-10-14.  
**Code read on the branch:** `R/nail_qda.R`, `R/nail_qda_product_interpretations.R`, `R/utils_ollama.R`, `R/nail_qda_space.R`, `R/nail_qda_spaceprep.R`, `R/nail_qda_interpretation.R`, and relevant `tests/testthat/test-qda-*.R` / `test-nail-qda-interpretation.R`.  
**Scope:** `nail_qda()` core-five finalization only. Do not refactor the statistical layer, modify secondary `nail_qda_space()`, or add unrelated features.

## 1. Executive diagnosis

The QDA **statistical/evidence-first foundation is already implemented**. The runtime prompt is modular in an engineering sense, but **does not implement the exact scientifically approved operational blocks**. Unlike CATDES/DESCFREQ, QDA must additionally preserve a machine-readable `NAILER_PRODUCT_INTERPRETATION` HTML-comment contract used by existing downstream expert review and QDA-space reuse. A separate, concrete runtime issue was found: **joint live generation currently passes a named list rather than a scalar prompt string to the backend**, even though both Ollama and Gemini validate a scalar character prompt. Address that before considering joint real-LLM validation successful.

No code or tests were edited as part of this audit.

## 2. Present implementation that should be frozen

- A single `SensoMineR::decat(dataset, formul, firstvar, lastvar, proba, graph = FALSE)` call in `nail_qda()`; result normalized and retained as `decat_result`.
- Canonical `product_profiles`, with every requested descriptor's adjusted mean, retained `decat` markers, `higher`/`lower` directions, p-values/v-tests and stable evidence IDs; legacy `profile_summary` preserved for compatibility.
- Deterministic `interpretation_evidence` via `sample.pct`, `sample.method = stratified/top`, `drop.negative`; `semantic_facing_evidence` reports direction, adjusted mean, p-value and v-test.
- `generate = FALSE` preview and `generate = TRUE` backend route; named per-product prompts when `isolate.groups = TRUE`, named `portfolio` prompt when `FALSE`; shared `nail_evidence()`, `nail_prompt()`, `nail_response()`, `llm_io`.
- `product_knowledge = known/unknown` already exists and is independent of `isolate.groups`. Unknown **means anonymously labelled observed stimulus, not statistically estimated latent group**.
- `qda_prompt_blocks` already records assembled sections; `default_blocks = c("reading", "interpretation", "local_task")` and `prompt_style = detailed/compact` are established public options that must not be removed or silently broken.
- Structured reusable PASS1 `product_interpretations`, statuses `not_generated` / `available` / `parse_failed`, evidence IDs and manual-expert revision via `nail_qda_interpretation()`. `nail_qda_space()` consumes both the QDA statistical evidence and any valid reusable interpretation.

This is a code inspection, not an independent assertion of statistical correctness of every edge case.

## 3. Gaps between approved science and current runtime

| Priority | Verified location / behavior | Gap / action |
| --- | --- | --- |
| **P1 — approved reading** | `R/nail_qda.R` → `.build_qda_guide_blocks()` | The dynamic default `reading` describes sampling percentages, top/stratified policy, suppressed LOWER evidence and undisplayed attributes. The analyst explicitly approved **removing these generic prompt-selection explanations without replacement** on 2026-10-14. Preserve those diagnostics in canonical R evidence, not the ordinary LLM reading. Replace the whole default `reading` by the approved block verbatim. |
| **P1 — approved interpretation** | Same helper's `epistemic` / `relative_interpretation` variants | Existing technical protections overlap scientifically but are not the approved complete text; also mention specific sensory domains in the general semantic task. Integrate the complete approved, modality-neutral `interpretation` verbatim. Maintain HIGHER/LOWER and the distinction between sensory facts and higher-order interpretation. |
| **P1 — identity** | `build_request_qda()`, `.build_qda_local_task()` and interpretation labels | `known` / `unknown` currently scattered rather than independent approved identity blocks. Add exact `known` or `unknown` identity block to default assembly, without adding public identity arguments or equating unknown with a latent group. |
| **P1 — task** | `build_request_qda()` and `.build_qda_local_task()` | Legacy request and task repeat instructions; integrate the approved `local` (exact identifier) or `joint` task. Preserve analyst's original `request` as the separate question; avoid inventing a new `interpretation_mode`. |
| **P1 — output** | `build_conclusion_qda()` | Default output imposes numbered `# Final Summary Task` and **mandatory Quarto Markdown**. Replace the ordinary default output with exact approved `output` text; keep verbatim user-supplied `conclusion` and the separate reusable metadata schema. No new compulsory Quarto requirement. |
| **P2 — tests** | `test-qda-semantic-rebuild.R` | Current tests **positively assert old selection caveats**, old wording and legacy headings (`## How to Read the Evidence`, `# Analytical Question`, `# Local Task`). Rewrite these assertions to **freeze the approved literal English blocks** and four assemblies; preserve remaining statistical evidence tests. |
| **P2 — style / opt-out compatibility** | `prompt_style`, `default_blocks` | `compact` currently shortens scientific instructions, and `default_blocks` can omit three optional semantic sections. Keep public values and opt-out behavior; ensure the standard/default route exactly matches scientific approval, and do not introduce an **unapproved alternate scientific reading** for `compact`. If unavoidable, request an explicit methodological decision before altering semantics. |
| **P2 — empty marker states** | `.build_semantic_facing_evidence_qda()` | `no_available_markers`, `no_eligible_markers` and `selection_empty` are distinguished; these should not become claims that a stimulus equals the average or has no distinguishing qualities. Test sparse, zero-selected and LOWER-only cases. Specific empty-state information is different from globally instructing the LLM to speculate about hidden attributes. |

### Scientific rules to enforce in every default configuration

- The average product is a **statistical reference**, not an actual tested product.
- HIGHER and LOWER are attribute-specific **relative to that reference**; LOWER does not imply absence or the presence of an unmeasured opposite.
- The **adjusted mean is a model-adjusted score**, not the difference to the reference; do not compare means across different attributes as though they measured the same property.
- `v.test` / `p.value` do not measure sensory strength or practical relevance.
- Descriptive contrasts among evaluated products are **not pairwise statistical tests**.
- Do not infer liking, quality, preference, manufacturing causes, or unsupported sensory notes from QDA profiling alone. Meaningful sensory synthesis is permitted as an *interpretation*, not a new measured descriptor.
- The known identity remains the known identity; for coded unknown stimuli, a supported sensory name may be proposed **alongside the original code**, without guessing actual identity.

## 4. Specific operational blocker: joint `generate = TRUE`

The current `.build_qda_prompt_bundle()` returns `prompts = list(portfolio = "<full joint prompt>")` in the joint case. In `nail_qda()`, the nonisolated generation branch executes:

```r
if (!isolate.groups) {
  result <- .call_llm(prompts)
  # ...
}
```

The inner `.call_llm()` forwards its `prompt` unmodified to `.call_llm_base()`; `.call_ollama_base()` and `.call_gemini_base()` both reject any prompt that is not **a nonempty character scalar**. Thus the current live joint route is incompatible with the backend argument contract, even though `generate = FALSE` works and an overly permissive mocked joint generation test passes. This is not a statistical error.

**Minimal proposed fix:** pass the scalar portfolio prompt to the backend (`prompts$portfolio`) while retaining the externally visible `list(portfolio = ...)` preview/llm_io structure. Add a strict mocked-provider test that checks `is.character(prompt) && length(prompt) == 1L` for **both** joint and isolated generation, plus one actual joint Ollama call after integration. Do not loosen provider validators and do not redesign `llm_io`. Recheck that generated `data.frame` retains its exact prompt and returns reusable per-product blocks.

## 5. Strict technical safeguard: reusable product interpretations

`R/nail_qda_product_interpretations.R` contains `.build_qda_product_interpretation_instruction()`, requiring an exact `<!-- NAILER_PRODUCT_INTERPRETATION ... END_NAILER_PRODUCT_INTERPRETATION -->` comment **for each product** and a parser for `product`, `core_profile`, `dominant_configuration`, `secondary_configuration`, `distinctive_interpretation`, `descriptive_name`. The parsed products retain status/provenance and displayed evidence IDs. `nail_qda_interpretation()` and `nail_qda_space()` depend on this distinction between raw statistical evidence and optional LLM interpretations.

The approved `output` block is **editorial prose**, while the HTML-comment block is an **independent technical reuse contract**. Both must coexist, and neither may silently cancel the other. Keep the parser, raw response, identifiers, field markers and `parse_failed` handling unchanged; ensure `known` identities are not overwritten by a model-proposed `descriptive_name`.

Add realistic tests verifying that both local and joint generation can produce one valid parsed product interpretation per actual product without new model calls, including when `conclusion` is custom. Test malformed and missing comment blocks fail closed, with no fabricated reusable interpretation. Do not modify downstream `nail_qda_space()` as part of this core-five task.

## 6. Current regression coverage and gaps

Existing tests worth retaining:

- `test-qda-semantic-rebuild.R`: canonical product profiles, invariance to interpretation-only settings, deterministic/stratified/top selection, HIGHER/LOWER facts, custom user context/question, block omission, `llm_io`, mocked local generation.
- `test-qda-product-interpretations.R`: reusable PASS1 parsed fields, per-product ID mapping, mock joint/local calls, fail-closed parse.
- `test-nail-qda-interpretation.R`: expert revision, provenance and inspection.
- `test-qda-space-condes-engine.R` and legacy compatibility artifacts: should remain untouched and pass to guard secondary consumers.

Main gaps: approved-block **exact text** checks, four default identity/task assemblies, global provider scalar type, actual joint Ollama generation with parser, and evidence-lean/sparse semantic interpretation. Current mocked joint parser test checks call count and parsed output but **does not assert that `prompt` is a scalar character string**.

No current `R CMD check`, `testthat`, or actual Ollama execution was performed in this static audit. Past reported operational testing applies only to previous runtime versions.

## 7. Recommended narrow implementation order (for Codex, not yet authorized to edit)

1. In a **dedicated QDA worktree**, use branch `dev-core5-qda-integration-20261016` (the new audit documentation commit will move the branch HEAD), and first capture baseline `nail_prompt()`, `nail_evidence()`, `product_profiles`, `product_interpretations` structures for realistic chocolate and at least one non-food sensory case.
2. Write a strict regression exposing the joint `generate = TRUE` list-versus-scalar defect. Correct only this forwarding argument. Keep `generate = FALSE` and `llm_io` shape identical.
3. Integrate the six approved semantic blocks (reading, interpretation, known/unknown identity, local/joint task, output) in the existing prompt-bundle framework **as exact literal text**. Reuse the existing data/evidence render and structured HTML-comment instruction; preserve original analyst `introduction`, `request`, `conclusion`.
4. Preserve public parameters and defaults: `prompt_style`, `default_blocks`, `product_knowledge`, `isolate.groups`, `sample.pct`, `sample.method`, `drop.negative`, `proba`, `generate`. No new `row_identity_mode`, `interpretation_mode`, parser values, extra LLM call, or cross-module refactoring.
5. Update ONLY affected QDA tests; freeze exact approved blocks, four prompt assemblies, known/unknown identity, local/joint evidence membership, custom input blocks, strict provider argument and reusable PASS1 contract; assert `product_profiles` and `nail_evidence()` unchanged when interpretation-only arguments change.
6. Offline previews for 2 identities × 2 scopes, compact/detailed public options, optional disabled blocks, mixed HIGHER/LOWER and `drop.negative = TRUE`, sparse/ambiguous descriptors; compare prompts with the approved documentary assemblies.
7. Run realistic Ollama `generate = TRUE` with **at least one joint** and one local example and, if feasible, all four approved combinations. Inspect actual raw interpretation AND parsed reusable blocks (never equate nice prose with valid structured parsing). Review any unsupported pairwise significance, intensity, hedonic/causal inference, or lost product IDs.
8. Execute `devtools::load_all()`, targeted `devtools::test_active_file()`, full `devtools::test()`, `git diff --check` and `devtools::check()` where the environment permits. Record the known possibility of Codex `processx` sandbox failure separately from package health. **No commit/push before human review**.

## 8. Definition of exit

Do not mark QDA finished on an approved prompt alone, nor on mock tests alone. Require scientifically reviewed rendered prompts; unchanged R evidence and provider/parser contracts; at least one actual local and joint LLM run; realistic examples; passing scoped/full tests; and a recorded `R CMD check` outcome or explicit user-accepted environment-limited gate. Human acceptance of residual interpretive model limitations remains required.

**Next core-five target after QDA:** classic `nail_textual()`. All secondary QDA-space and CATDES+TEXTUAL prompt work remains frozen by `dev/FINALIZATION_CORE5.md`.
