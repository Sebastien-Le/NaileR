# NaileR — CORE 5 / TEXTUAL initial scientific and architectural audit

**Audit date:** 2026-10-16  
**Status:** **INITIAL STATIC AUDIT COMPLETE — IMPLEMENTATION NOT STARTED**. No R code, package test suite or LLM experiment executed during this audit.  
**Audited branch:** `dev-core5-textual-integration-20261016` at starting commit `c8403c02691962613808ae5f29091b6a43bb7ce8`.  
**Scientific sources:** [`TEXTUAL_MODULAR_PROMPT.md`](reading_review/TEXTUAL_MODULAR_PROMPT.md), [`TEXTUAL_ASSEMBLY_REVIEW.md`](reading_review/TEXTUAL_ASSEMBLY_REVIEW.md), [`TEXTUAL_REFERENCE_PROMPT.md`](reading_review/TEXTUAL_REFERENCE_PROMPT.md) and [`TEXTUAL_PROMPT_DECISIONS.md`](reading_review/TEXTUAL_PROMPT_DECISIONS.md).  
**Implementation reviewed:** `R/nail_textual.R`, `R/nail_textual_semantic.R`, `R/textual_volume_diagnostics.R`, `R/nail_llm_io.R`, `R/nail_catdes_textual.R`, `R/zzz_nail_textual_contextualized_compat.R`, the relevant `tests/testthat/test-textual-semantic-rebuild.R`, and `dev/FINALIZATION_CORE5.md`.

## 1. Scope and authoritative scientific status

The only active CORE 5 task is **classic `nail_textual()`**, the fifth fundamental function. `nail_textual_prep()` is maintenance-only: preserve its compatibility because it calls `nail_textual()`, but do **not** separately refactor or implement its approved output in this pass. `nail_textual_contextualized()`, `nail_catdes_textual()`, new cross-group/global model interpretation, semantic agents and composed workflows remain frozen.

The bilingual `reading`, `interpretation`, `local_task` and both *distinct* route-specific `output` blocks were approved on 2026-10-15 in `TEXTUAL_MODULAR_PROMPT.md`. **The three-documentary-assembly review is explicitly still OPEN** in `TEXTUAL_ASSEMBLY_REVIEW.md`. Its candidate assemblies are not evidence of a previously approved executable prompt. For this CORE 5 pass, carry over only approved classic semantics, record the assembly details, and obtain analyst sign-off of the final rendered classic prompt as part of operational validation. Do not silently implement a separate preparatory prompt integration.

## 2. Working evidence-first architecture — preserve, do not rewrite

- `R/nail_textual_semantic.R` registers a full `textual_evidence$text_registry` with stable `TXT%06d` IDs based on original source row numbers, original group, source row and text. Duplicate text values remain separate source observations rather than being deduplicated.
- The canonical group metrics record number of source observations, non-empty texts, response coverage, distinct texts and text lengths.
- `interpretation_input` records sampled `selected_text_ids` and the exact `selected_texts`, per-group status `ready` or `no_texts`, coverage and sampling settings. `sample.pct` / `seed` change prompt selection, not the full registry. Sampling uses an RNG-preserving helper.
- `nail_textual()` is **local-first** irrespective of `isolate.groups`: with `FALSE`, local prompts/responses are concatenated for outer compatibility but there is no new global comparative LLM call.
- Structured `textual_profiles` are parsed per group from six output fields, with `strong/moderate/mixed/weak` coherence. Representative and tension IDs must be in the text subset actually displayed. Unrecognized IDs produce `parse_failed`.
- Empty groups remain `no_texts` without any LLM generation for those groups; missing responses and malformed output have separate states. This should remain unchanged.
- `textual_prompt_blocks`, `local_prompts`, `llm_io`, `nail_evidence()`, `nail_prompt()`, and `nail_response()` preserve inspection of prompts/responses. The legacy `textual_data_summary` remains a compatibility view.
- Current `default_blocks = c("reading", "interpretation", "local_task")`, `prompt_style = detailed/compact`, `text_role = responses/comments/verbatims`, `sample.pct`, `seed`, and custom `introduction/request/conclusion` must remain compatible.

These are source-code observations, not independent claims that every edge case has passed an R test in this audit.

## 3. Scientific prompt gaps versus approved blocks

| Priority | Exact runtime location | Findings and recommended narrow action |
| --- | --- | --- |
| P1 | `.build_textual_guide_blocks()` in `R/nail_textual_semantic.R` | Current reading/interpretation is an older collection of abbreviated individual imperatives. It does not reproduce the complete approved `reading` / `interpretation` verbatim. Integrate approved classic text exactly in default rendering. |
| P1 | Same helper; `build_guide_textual()` also remains in `R/nail_textual.R` | The old guide says each bullet point is an **individual contribution**, unlike approved `reading` which correctly says source observations need not correspond to distinct individuals. The active `nail_textual()` route uses `.build_textual_guide_blocks()`, *not* `build_guide_textual()`. Do not confuse historical unused builders with the executable path. |
| P1 | `.build_textual_prompt_bundle()` | Local task says only “Interpret only the group shown below” and lacks the **actual group identifier** required by the approved `local_task`. Render the exact approved local task with substituted original group label while retaining the deliberate no-text exception. |
| P1 | `.textual_canonical_conclusion()` | The current output fields match the **six classic parser names**, but the preapproved editorial introduction, definitions and traceability/qualitative-coherence constraints are not fully present. Replace default classic `output` with approved wording without changing field names/order/parser or overriding custom `conclusion`. |
| P1 | Current `interpretation` instructions | Insufficient explicit protection of ambiguity, negation, intention vs reported experience vs behavior, meaningful minority positions, shared frame with dissent, coexistence of distinct frames and nonnumeric within-group coherence. Approved text addresses these directly; integrate rather than adding independent wording. |
| P2 | `.textual_default_request()` | Historical default question repeats thematic and interpretation instructions. Avoid unnecessary scientific duplication after inserting full approved `interpretation`, but preserve the original analyst `request` exactly. Do not introduce a global comparison task. |
| P2 | `.textual_group_data_block()` | Corpus information includes “Individuals/observations in group”, response coverage and displayed sample counts. This may be useful R metadata but **must not imply unique individuals or statistically measured prevalence**. No generic prompt-visible disclaimer about unsupplied sampled texts is authorized; retain selection provenance in R. Any prompt-data metadata reduction or relabeling requires careful comparison, not blanket deletion. |
| P2 | `prompt_style = "compact"` | Approved `TEXTUAL_COMPACT_PROMPT.md` is explicitly **NOT approved**. The existing public `compact` option may still work, but should not silently get an unapproved alternative “scientific” text; preserve API and require an explicit choice on its rendering before claiming that both styles literally implement approved full blocks. |
| P2 | `default_blocks` | Existing ablation/opt-out machinery must remain stable. Only present optional blocks when requested; context, question, source evidence and output remain. Missing scientific blocks in intentional ablation must not be misrepresented as a default scientific prompt. |

**Epistemic invariants:** Text observations are empirical; themes/syntheses are LLM interpretations, not R statistics. The same expression repeated does not establish prevalence or consensus among independent individuals. Preserve original negations, uncertainties, discourse plurality and tensions. The study introduction is contextual, not evidence. Do not infer hidden motives, personality traits, social identities or unsupported causality. Use source-linked IDs, without inventing quotations.

## 4. Two output contracts: classic now, preparation compatibility only

**Classic `nail_textual()`:** The parser `.parse_textual_profile_response()` in `R/nail_textual_semantic.R` expects exactly the fields `Core textual profile`, `Dominant themes`, `Within-group coherence`, `Internal diversity`, `Representative text IDs`, and `Tension text IDs`. The coherence values are `strong/moderate/mixed/weak`. No fifth `not assessable` category is authorized. Malformed/unsupported IDs must fail closed; no-text groups must not receive fabricated profiles.

**Preparatory `nail_textual_prep()`:** The separate `parse_textual_prep_response()` expects `Core textual profile`, `Main themes`, `Dominant concerns or motives`, `Tone or stance`, `Intra-group consistency`, `Injectable summary`, plus optional `Central verbatim cues` and `Tension verbatim cues`. Those cues are LLM-generated short quotes/paraphrases, **not equivalent to** the separately mechanically selected/source-row-linked attached verbatims. The prep-specific output has been approved scientifically but is **out of scope for separate implementation now**.

**Important coupling:** `nail_textual_prep()` calls `nail_textual(..., isolate.groups = TRUE, introduction = intro, request = req, conclusion = concl)`. Thus changing the shared `.build_textual_guide_blocks()` will *also change preparatory prompts' common reading and interpretation* even if the prep request, conclusion and parser are untouched. This may align with the approved shared reading, but requires explicit compatibility/regression tests for the preparatory route (with and without cues, both styles) without launching a prep refactor. The same downstream principle applies to `nail_catdes_textual()`, which consumes canonical `textual_profiles` and resolves source IDs; it should **not** be changed in this pass.

## 5. Empty/sparse evidence and parser validity

`validate_textual_inputs()` rejects a dataset with no usable text anywhere. Individual groups with no text are represented as `no_texts`; the code bypasses LLM generation for those groups. `sample.pct` currently lies in `(0, 1]`, so `sample.pct = 0` is not an authorized empty-selection state.

The approved classic output **requires** a coherence category even when few texts are available. `weak` refers to weakly shared framing, not necessarily “not assessable”. Do not introduce `not assessable` or invent a profile in a sparse group merely to satisfy output structure; instead retain current statuses and document model limitations.

The current parser validates mandatory field presence, one of the accepted coherence prefixes, and membership of supplied representative/tension IDs, but does **not strictly enforce all numeric output limits** (e.g. 1–5 themes, 1–3 representative IDs). It also normalizes coherence permissively (`startsWith`). This is an existing parser-contract property, not an authorized broad parser rewrite; add focused tests and document its limitation. A syntactically parsed profile is **not automatically qualitatively accurate**.

## 6. Tests currently present and missing

Existing `tests/testthat/test-textual-semantic-rebuild.R` contains tests for:
- canonical `TXT%06d` source-ID registry, coverage and selected-corpus reproducibility/invariance;
- preservation of custom introduction/request, local-only evidence, ordered prompt blocks and default-block ablation;
- `isolate.groups = FALSE` generating separate local calls, with no global synthesis;
- six-field parsing and allowed text IDs; hallucinated IDs fail closed;
- `llm_io` accessors, compatibility summary, custom conclusion and mixed tension IDs/none.

However, several tests assert old prompt strings (`higher-level contextual interpretation`, `what respondents literally expressed`, `# Required output`), and must be updated to the **literal approved English text**, rather than making both old and new prompt wording compulsory.

Required additional tests:
1. Exact approved default `reading`, `interpretation`, `local_task` with original label, and six-field `output`; frozen assembly order and prompt absence of other groups.
2. Corpus duplicate vs distinct source observations; no false respondent-level prevalence claim; text meaning tests with negations, conditional statements, minority disagreements and contradictory passages.
3. Empty group, one-text sparse group, short/long messages, all-empty dataset behavior, `generate = FALSE/TRUE`, `isolate.groups = TRUE/FALSE`.
4. `seed` reproducibility, RNG-state preservation, `sample.pct` selection without canonical corpus mutation, no invented text IDs and recordable selection provenance.
5. Custom `introduction`, `request`, `conclusion`; `prompt_style`, `text_role`, `default_blocks`; no accidental new external parameter or positional signature shift.
6. Preparatory route **regression only**: its different output schema and optional LLM cues preserved after common reading changes; secondary `nail_catdes_textual()` compatibility tests continue to pass.
7. Real LLM responses: parser status AND substantive fidelity separately (no fabricated quotes, hallucinated social/psychological explanations, false consensus, unsupported topic prevalence, erased reservations or minority views).

No R tests or model calls were executed in the static audit. Existing test descriptions are based on code read, not freshly measured pass counts.

## 7. Focused implementation plan and acceptance conditions

1. Work on `dev-core5-textual-integration-20261016` in a separate local worktree. Freeze baseline output snapshots and `textual_evidence`/`interpretation_input` for a realistic, heterogeneous and duplicate-containing corpus.
2. Present the assembled **classic** prompt for analyst confirmation, as the source `TEXTUAL_ASSEMBLY_REVIEW.md` still says *review open*. Do not silently treat the three documentary assemblies as a previously signed-off runtime contract; do not change approved block wording.
3. Make the smallest edits to `R/nail_textual_semantic.R` and `R/nail_textual.R` needed to integrate the approved `reading`, `interpretation`, `local_task` and classic `output` as exact literal texts. Preserve `nail_textual_prep()` request/output/parser and all shared source registries/LLM I/O.
4. Refactor **no** statistical, corpus-selection, quoted-text parser, downstream composition or secondary function code unless a focused test establishes an unavoidable core-five blocker.
5. Update/extend only affected TEXTUAL tests and generated documentation if the public semantics/examples change; preserve prior compatibility assertions and add parser-level regression.
6. Validate realistic `generate = FALSE` prompts against approved text; inspect no-text, sparse, duplicated, ambivalent and contradictory situations and both isolation modes.
7. Execute `generate = TRUE` with a local model for multiple heterogeneous groups, including a locally sparse group, verify statuses and exact ID provenance, and expert-review generated interpretations independently of parser status.
8. `devtools::load_all()`, `devtools::test_active_file("tests/testthat/test-textual-semantic-rebuild.R")`, prep compatibility targeted tests, `devtools::test()`, `git diff --check`, and `devtools::check()` when permitted. If `processx` blocks check before build, document the environment-specific limitation; it is neither a clean package-check pass nor proof of a package defect.
9. No commit/push until analyst reviews real prompts, LLM output and a scoped diff.

**Exit:** TEXTUAL is complete only when the analyst approves the executable assembled classic prompts, corpus and ID invariance holds, sparse/empty statuses and legacy prep consumer remain functional, the six-field parser and raw IO remain traceable, substantive LLM interpretation is examined on realistic corpus variation, and tests/check limitations are documented. Reaching five CORE functions does **not** automatically lift the wider project scope freeze until the analyst agrees.
