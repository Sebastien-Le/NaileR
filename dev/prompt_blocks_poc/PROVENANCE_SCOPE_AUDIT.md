# NaileR — Provenance and scope audit

## 0. Scope and method

This is a diagnostic audit of the code present on:

```text
branch: dev-statistical-prompt-framework
HEAD: a3e51d1
```

The audit covers `nail_qda()`, `nail_textual()`, `nail_catdes()`,
`nail_condes()`, and the composed `nail_catdes_textual()` path. It uses the
current R implementation, tests, and the existing development reports. No R
code, tests, user documentation, statistical computation, or experimental
result was changed. No LLM call was made.

The labels used below have a deliberately narrow meaning:

- **[VERIFIED]**: directly supported by the current implementation or by a
  reproducible `generate = FALSE` check.
- **[OBSERVED]**: observed in existing tests or development experiments, but
  not a general guarantee of the implementation.
- **[PARTIAL]**: a guarantee exists for part of the path, but the current
  implementation is indirect, asymmetric, or not exposed uniformly.
- **[DECISION]**: a methodological or architectural decision already encoded
  in the current design.
- **[HYPOTHESIS]**: a proposal or risk that still requires validation.

## 1. Executive findings

### Main guarantees currently present

1. **[VERIFIED] Canonical evidence is separated from prompt-facing evidence.**
   QDA, TEXTUAL, CATDES, and CONDES construct a canonical artifact before
   selecting or rendering the evidence shown to the LLM. The composed
   CATDES+TEXTUAL path consumes stored artifacts rather than recomputing the
   upstream analyses.
2. **[VERIFIED] Prompt selection does not mutate the primary evidence.**
   `sample.pct`, `sample.method`, `drop.negative`, `quali.sample`,
   `quanti.sample`, and the textual selected-text layer alter the prompt-facing
   selection while leaving the canonical evidence object unchanged.
3. **[VERIFIED] Method-specific reading rules are explicit.** QDA directions
   are sensory deviations, TEXTUAL evidence is respondent language, CATDES
   facts are within-variable prevalence/mean comparisons, and CONDES facts are
   associations and end profiles. The code does not collapse these meanings
   into a universal statistical sentence format.
4. **[VERIFIED] Scope is implemented differently by method.** QDA changes
   between a portfolio prompt and local product prompts. TEXTUAL remains
   local-first even when its outer return is combined. CATDES really sends a
   joint prompt when `isolate.groups = FALSE`. CATDES+TEXTUAL is local-first in
   both outer modes. CONDES is a single-target analysis.
5. **[VERIFIED] Traceable text grounding is strongest in TEXTUAL and
   CATDES+TEXTUAL.** Stable `TXT...` identifiers are retained, selected IDs
   are checked against the canonical text registry, and representative/tension
   texts are resolved back to exact source rows.

### Concrete gaps

1. **[VERIFIED] CATDES does not attach a canonical `llm_io` artifact in
   `nail_catdes()`.** `nail_prompt()` and `nail_response()` can still work
   through compatibility extraction from the result, but the exact current
   interaction is not stored under the same canonical structure used by QDA,
   TEXTUAL, CONDES, and CATDES+TEXTUAL. This is a provenance asymmetry, not a
   statistical error.
2. **[VERIFIED] `semantic_facing_evidence` is not uniformly independently
   inspectable through `nail_evidence()`.** The public evidence accessor returns
   the canonical object, while prompt-facing selected evidence is available
   through attributes and method-specific artifacts. The distinction is safe
   but not equally ergonomic across methods.
3. **[VERIFIED] Scope metadata is mostly stored in method settings rather than
   in a shared provenance envelope.** A consumer must know whether
   `isolate.groups = FALSE` means joint generation, combined outer shape, or
   local-first combined output.
4. **[VERIFIED] CATDES has no parser-backed output contract.** Its
   `semantic_profiles` are stored as free-form stage output. This is coherent
   with its current scope, but weaker than QDA's reusable metadata contract and
   TEXTUAL's parsed profile contract.
5. **[HYPOTHESIS] CATDES+TEXTUAL would benefit most from a dedicated composed
   prompt artifact, provided that it preserves the asymmetric statistical
   anchor/textual enrichment contract.** This should not be implemented as a
   universal renderer or by flattening the two sources.

## 2. QDA provenance and scope

### Provenance chain

```text
SensoMineR::decat()
    -> product_profiles
    -> interpretation_evidence
    -> semantic_facing_evidence
    -> QDA prompt blocks
    -> LLM response / reusable product interpretation
```

- **[VERIFIED] Canonical source:** `product_profiles`, derived from the
  standardized `decat()` result and retained for all products/stimuli.
- **[VERIFIED] Selection layer:** `interpretation_evidence` applies the
  deterministic marker selection, sampling strategy, polarity policy, and
  evidence IDs. `drop.negative` affects this layer only.
- **[VERIFIED] LLM-facing layer:** `semantic_facing_evidence` renders selected
  markers as explicit HIGHER/LOWER sensory facts and retains adjusted means,
  `v.test`, and p-values in the displayed factual line.
- **[VERIFIED] Prompt blocks:** `context`, `reading`, `question`,
  `interpretation`, `local_task`, `evidence`, `reusable`, and `output` are
  retained in `qda_prompt_blocks`. `reading`, `interpretation`, and
  `local_task` are selectable through `default_blocks`; evidence, reusable
  metadata, and output remain protected.
- **[VERIFIED] Exact interaction:** QDA attaches canonical `llm_io` with the
  rendered prompt(s) and raw response(s). `nail_prompt()` returns those exact
  prompts.

### Scope and output

- **[VERIFIED] `isolate.groups = TRUE`:** one local prompt/result per product
  or stimulus, with named block artifacts.
- **[VERIFIED] `isolate.groups = FALSE`:** one portfolio prompt/result. The
  local product blocks are not the active generation scope in this mode.
- **[VERIFIED] Local task:** binds the model to the current product/stimulus
  and preserves the identifier semantics selected by `product_knowledge`.
- **[VERIFIED] Downstream contract:** the reusable block contains the existing
  HTML metadata instruction. It is parsed into `product_interpretations` and
  is not merely explanatory prose.

### Guarantees, gaps, and minimal improvement

| Item | Status | Audit finding |
| --- | --- | --- |
| Canonical evidence independent of prompt wording | [VERIFIED] | Full and partial-selection previews had identical `nail_evidence()` output. |
| Selected evidence can differ without changing canonical profiles | [VERIFIED] | `interpretation_evidence` and `semantic_facing_evidence` changed under sampling/drop-negative while `product_profiles` did not. |
| Prompt-to-LLM traceability | [VERIFIED] | `llm_io$prompts` and `nail_prompt()` were identical in the preview check. |
| Product/portfolio scope | [VERIFIED] | Stored in QDA settings and reflected in named blocks. |
| Reusable output protection | [VERIFIED] | Reusable metadata is rendered before final output and parsed separately. |
| Public provenance envelope | [HYPOTHESIS] | A shared envelope could make scope and selected IDs easier to consume, but it is not needed to preserve current correctness. |
| Minimal next improvement | [DECISION] | Add structural scope/provenance assertions before considering any shared API. |

## 3. TEXTUAL provenance and scope

### Provenance chain

```text
raw grouped texts
    -> textual_evidence + complete text_registry
    -> interpretation_input + selected_text_ids
    -> local textual data block
    -> parsed textual_profiles
    -> optional CATDES+TEXTUAL contextualization
```

- **[VERIFIED] Canonical source:** `textual_evidence` contains the complete
  grouped text registry and stable text IDs.
- **[VERIFIED] Selection layer:** `interpretation_input` applies per-group
  sampling and records selected IDs, coverage, and the input actually shown to
  the model. It does not rewrite `textual_evidence`.
- **[VERIFIED] LLM-facing layer:** the group data block includes exact selected
  texts, their `TXT...` identifiers, and corpus/group coverage metrics.
- **[VERIFIED] Prompt blocks:** `context`, `reading`, `question`,
  `interpretation`, `local_task`, `evidence`, and `output` are retained in
  `textual_prompt_blocks`. The first three optional semantic blocks are
  controlled by `default_blocks`.
- **[VERIFIED] Output contract:** the textual output is parsed into structured
  fields, including representative/tension text IDs and internal diversity.
- **[VERIFIED] Exact interaction:** TEXTUAL attaches canonical `llm_io` for
  local prompts and responses.

### Scope and output

- **[VERIFIED] Generation is local-first in both isolation modes.** Each ready
  group is interpreted independently.
- **[VERIFIED] `isolate.groups = TRUE`:** named local prompts/results are
  returned.
- **[VERIFIED] `isolate.groups = FALSE`:** the outer return shape is combined,
  but this does not create a global synthesis call. This is intentionally not
  equivalent to CATDES joint mode.
- **[VERIFIED] Local task:** prevents comparison with groups whose texts are
  not displayed and binds the prompt to the current group.
- **[VERIFIED] Parser provenance:** parsed representative/tension IDs are
  checked against the selected IDs shown to the model; this protects against
  fabricated or out-of-scope references.

### Guarantees, gaps, and minimal improvement

| Item | Status | Audit finding |
| --- | --- | --- |
| Canonical text registry independent of sampling | [VERIFIED] | Full and half-sampled previews had identical `nail_evidence()` output. |
| Selected IDs resolve to exact texts | [VERIFIED] | Sampled IDs were all members of the canonical registry. |
| Exact prompt storage | [VERIFIED] | `llm_io$prompts` matched `nail_prompt()` in the preview check. |
| Internal diversity protection | [VERIFIED] | It is a parsed output field and is preserved into contextualization. |
| Parser compliance equals analytical usefulness | [OBSERVED] | Prior TEXTUAL experiments show that a response can be useful without satisfying every parser field, and vice versa. |
| Selection provenance exposed uniformly | [PARTIAL] | It is inspectable through attributes, but there is no common public accessor for the selected input layer. |
| Minimal next improvement | [DECISION] | Keep exact text IDs and selection metadata as the primary contract; do not generalize raw textual evidence into statistical evidence. |

## 4. CATDES provenance and scope

### Provenance chain

```text
FactoMineR::catdes() / nail_catdes_prep()
    -> statistical_profiles + evidence_registry
    -> interpretation_evidence
    -> semantic_facing_evidence
    -> local or joint CATDES prompt
    -> free-form semantic_profiles
```

- **[VERIFIED] Canonical source:** `statistical_profiles` contains group
  profiles, canonical marker tables, and an evidence registry. The dataset path
  performs the statistical preparation through `nail_catdes_prep()`; prepared
  profiles are reused rather than recomputed.
- **[VERIFIED] Selection layer:** `interpretation_evidence` selects
  qualitative and quantitative markers by deterministic rank and requested
  proportions. `drop.negative` excludes negative directions only from the
  selected prompt subset.
- **[VERIFIED] Semantic projection:** `semantic_facing_evidence` presents
  MORE/LESS FREQUENT modality prevalence and HIGHER/LOWER within-variable
  means. P-values, v-tests, ranks, and evidence IDs remain in audit structures
  but are not shown to the LLM.
- **[VERIFIED] Binary completion:** when selection would show only part of a
  significant binary contrast, the semantic projection can add the paired
  modality. The existing regression tests verify that this completion is
  suppressed when `drop.negative = TRUE`.
- **[VERIFIED] Prompt blocks:** CATDES retains `context`, `reading`,
  `question`, `interpretation`, `local_task`, `evidence`, and an output slot
  that is currently `NULL`. The local and joint renderers are CATDES-specific.
- **[VERIFIED] Standard/latent scope:** standard prompts preserve observed
  category names; latent prompts treat labels as identifiers and request an
  interpretive name for constructed groups. This distinction is present in
  reading, interpretation, and local-task wording.

### `isolate.groups` is a real semantic distinction here

- **[VERIFIED] `TRUE`:** one prompt and one generated profile per category or
  group. Each local prompt contains only that unit's selected semantic facts.
- **[VERIFIED] `FALSE`:** one portfolio prompt containing all selected groups,
  with a joint analytical request. One backend call is made when generation is
  requested and evidence is available. Local prompts are retained for audit,
  but they are not the active generation input.
- **[DECISION]** CATDES must not inherit TEXTUAL's local-first combined
  semantics merely because both functions use `isolate.groups`.

### Important LLM-IO asymmetry

- **[VERIFIED]** `nail_catdes()` currently attaches prompt blocks, canonical
  evidence, local prompts, semantic profiles, and settings, but not a canonical
  `llm_io` attribute.
- **[VERIFIED]** The common accessors can nevertheless recover prompts and
  generated responses through compatibility adapters that inspect CATDES
  `semantic_profiles`, data-frame columns, or the joint result.
- **[VERIFIED]** Therefore `nail_prompt()` is usable, but the provenance path is
  indirect and differs from QDA/TEXTUAL/CONDES. A direct `attr(x, "llm_io")`
  check is not a valid CATDES guarantee on this branch.
- **[HYPOTHESIS]** A future CATDES-only intervention could attach canonical
  `llm_io` without changing evidence, statistics, scope, or return shape. It
  should be treated as a separate compatibility pass, not folded into a
  generic provenance refactor.

### Guarantees, gaps, and minimal improvement

| Item | Status | Audit finding |
| --- | --- | --- |
| Canonical statistical object is preserved | [VERIFIED] | Local/joint previews and sampling variations did not alter `statistical_profiles`. |
| Semantic evidence hides technical ranking metadata | [VERIFIED] | The CATDES semantic projection omits p-values/v-tests/evidence IDs from the LLM text. |
| Binary completion is controlled | [VERIFIED] | Existing stage-3 tests cover completion and the `drop.negative` exception. |
| Local/joint scope is explicit | [VERIFIED] | `generation_architecture` and `prompt_scope` distinguish `local` and `joint`. |
| Canonical exact prompt/response artifact | [PARTIAL] | Common accessors recover it, but `llm_io` is not attached canonically by `nail_catdes()`. |
| Output parser contract | [VERIFIED] | No parser contract is claimed; profiles remain free-form. |
| Minimal next improvement | [DECISION] | First add a CATDES-specific `llm_io` regression contract, without altering output or evidence. |

## 5. CONDES provenance and scope

### Provenance chain

```text
FactoMineR::condes()
    -> continuous_profile
    -> interpretation_evidence
    -> semantic_facing_evidence
    -> single-target prompt blocks
    -> raw response
```

- **[VERIFIED] Canonical source:** `continuous_profile` stores quantitative
  associations, qualitative associations, end profiles, an evidence registry,
  settings, and metadata for the single target.
- **[VERIFIED] Selection layer:** `interpretation_evidence` retains the
  deterministic family-specific evidence used for the prompt.
- **[VERIFIED] Semantic projection:** the prompt exposes correlation, R2,
  p-values, Estimate, direction, and lower/higher end statements in prose.
  The reading block distinguishes statistical support, association magnitude,
  and interpretive centrality.
- **[VERIFIED] Prompt blocks:** CONDES has `context`, `reading`, `question`,
  `interpretation`, `evidence`, and `output`. It intentionally has no
  `local_task`: one call targets one continuous variable/continuum.
- **[VERIFIED] Standard/latent interpretation:** the evidence and reading
  machinery remain statistically invariant; standard preserves the observed
  target name, while latent allows reconstruction and naming of a constructed
  continuum.
- **[VERIFIED] Exact interaction:** CONDES attaches canonical `llm_io`, and
  the stored prompt matched `nail_prompt()` in the preview check.

### Guarantees, gaps, and minimal improvement

| Item | Status | Audit finding |
| --- | --- | --- |
| Single-target scope | [VERIFIED] | The function has no group isolation dimension and stores one target. |
| Statistical/interpretive separation | [VERIFIED] | The prompt explicitly distinguishes p-value evidence, association magnitude, and interpretive centrality. |
| Context boundary | [VERIFIED] | The standard interpretation block treats introduction as substantive context, not statistical evidence. |
| Canonical interaction storage | [VERIFIED] | `llm_io` stores the exact rendered prompt and response slot. |
| End-profile interpretation risk | [HYPOTHESIS] | A model may overread end profiles as independent confirmation; current reading wording mitigates but does not empirically eliminate this. |
| Minimal next improvement | [DECISION] | Preserve method-specific reading rules and test target/scope metadata before considering any generic block API. |

## 6. CATDES + TEXTUAL composition

### Composition chain

```text
CATDES semantic_facing_evidence
    + TEXTUAL textual_evidence
    + TEXTUAL interpretation_input
    + parsed textual_profiles
    -> contextualized_evidence
    -> one local contextualization prompt per group
    -> contextualized_profiles
```

- **[VERIFIED] Inputs are validated before composition.** The CATDES result
  must carry semantic-facing evidence; the TEXTUAL result must carry canonical
  textual evidence, interpretation input, and parsed textual profiles; group
  names must match.
- **[VERIFIED] Text IDs are provenance-checked.** Representative and tension
  IDs from the parsed TEXTUAL profile must belong to the selected allowed IDs
  and to the same group. They are then resolved back to exact rows in the
  canonical text registry.
- **[VERIFIED] The composed object is asymmetric by design.** Each group has a
  `statistical_anchor` containing CATDES facts and selected IDs, and a
  `textual_enrichment` containing parsed themes, diversity, metrics, and exact
  representative/tension texts.
- **[VERIFIED] CATDES is not recomputed and raw text is not reanalyzed** by
  `nail_catdes_textual()`. Existing CATDES semantic interpretation, when
  present, is stored separately from the mechanical statistical anchor.
- **[VERIFIED] Scope is local-first.** `isolate.groups = FALSE` changes the
  outer return shape but still performs one independent contextualization call
  per group when generation is enabled.
- **[VERIFIED] Public evidence path:** `nail_evidence()` recognizes and
  returns `contextualized_evidence`, which is a composed stage artifact rather
  than a replacement for either upstream canonical artifact.
- **[VERIFIED] Exact interaction:** the composition function attaches canonical
  `llm_io` for its local contextualization prompts/responses.

### Guarantees, gaps, and minimal improvement

| Item | Status | Audit finding |
| --- | --- | --- |
| Statistical anchor remains separate | [VERIFIED] | CATDES facts are held in `statistical_anchor`; text does not rewrite them. |
| Exact textual grounding | [VERIFIED] | Selected representative/tension IDs are resolved and group-validated. |
| Local-first semantics | [VERIFIED] | Outer `isolate.groups` does not create a global synthesis. |
| Composed prompt inspectability | [PARTIAL] | Local prompts and contextualized evidence are retained, but there is no named prompt-block artifact analogous to QDA/TEXTUAL/CATDES. |
| Evidence status across stages | [PARTIAL] | `contextualized_evidence` contains upstream parsed/model-assisted material alongside mechanical anchors; the distinction is explicit in fields but not wrapped in one common provenance envelope. |
| Parser/output relationship | [HYPOTHESIS] | The final contextualized profile's relationship to upstream parsers deserves a dedicated contract audit. |
| Minimal next intervention | [DECISION] | Audit and document the composed prompt artifact first; do not generalize the renderer or flatten CATDES and TEXTUAL evidence. |

## 7. Comparative block matrix

| Method | Ordered conceptual blocks | Optional blocks | Protected blocks | Internal artifact | Current scope renderer |
| --- | --- | --- | --- | --- | --- |
| QDA | context, reading, question, interpretation, local_task, evidence, reusable, output | reading, interpretation, local_task | evidence, reusable, output | `qda_prompt_blocks` | portfolio or local product |
| TEXTUAL | context, reading, question, interpretation, local_task, evidence, output | reading, interpretation, local_task | context, question, evidence, output | `textual_prompt_blocks` | local-first |
| CATDES | context, reading, question, interpretation, local_task, evidence, output slot | none | evidence; scope-specific local task | `catdes_prompt_blocks` | joint or local |
| CONDES | context, reading, question, interpretation, evidence, output | none | evidence and output | `condes_prompt_blocks` | single target |
| CATDES + TEXTUAL | context and request around contextualized evidence; no unified named block artifact | none | statistical anchor and textual enrichment | `contextualized_evidence`, local prompts | local-first composition |

**[DECISION]** The shared block names are an audit vocabulary, not evidence
that the blocks are interchangeable. QDA's `reusable` block is a downstream
HTML metadata contract; TEXTUAL's contract is parsed from its output; CATDES
has no parser-backed output contract; CONDES has no per-object local task.

## 8. Canonical versus LLM-facing evidence matrix

| Method | Canonical artifact | Selection/intermediate artifact | LLM-facing projection | Evidence semantics shown to the model | `nail_evidence()` |
| --- | --- | --- | --- | --- | --- |
| QDA | `product_profiles` | `interpretation_evidence` | `semantic_facing_evidence` | Relative sensory HIGHER/LOWER facts with means, v.test, p-values | canonical `product_profiles` |
| TEXTUAL | `textual_evidence` + text registry | `interpretation_input` | exact selected texts and metrics | Raw respondent expressions with stable IDs | canonical `textual_evidence`; selected group adds exact texts |
| CATDES | `statistical_profiles` + registry | `interpretation_evidence` | `semantic_facing_evidence` | Relative modality prevalence and same-variable group/full means | canonical `statistical_profiles` |
| CONDES | `continuous_profile` + registry | `interpretation_evidence` | `semantic_facing_evidence` | Correlations, R2, p-values, end-profile effects | canonical `continuous_profile` |
| CATDES + TEXTUAL | upstream CATDES semantic projection plus TEXTUAL canonical/parsed artifacts | validated group/ID joins | `contextualized_evidence` | CATDES statistical anchor plus exact textual enrichment | composed `contextualized_evidence` |

### Provenance implications

- **[DECISION]** A prompt-facing projection is not a replacement for canonical
  evidence.
- **[VERIFIED]** Sampling changes the selected interpretation layer while
  preserving the primary canonical artifact in QDA, TEXTUAL, CATDES, and
  CONDES.
- **[DECISION]** Literal vocabulary need not be preserved in a substantive
  interpretation, but the meaning and epistemic status of the supporting facts
  must remain traceable.
- **[HYPOTHESIS]** A shared provenance envelope could record `analysis`,
  `source_schema`, `scope`, `selected_ids`, `rendering_policy`, and
  `generation_architecture` without normalizing away method-specific payloads.

## 9. Scope and output contract matrix

| Method | Scope unit | `isolate.groups = TRUE` | `isolate.groups = FALSE` | Generation calls | Output/downstream contract |
| --- | --- | --- | --- | --- | --- |
| QDA | product/stimulus or portfolio | local product prompts/results | one portfolio prompt/result | one per local product or one portfolio call | reusable HTML metadata parsed into product interpretations |
| TEXTUAL | group | named local prompts/results | combined outer shape, still local-first | one per ready group in both modes | structured textual profile parsed from fields and IDs |
| CATDES | observed category or constructed group | local prompt/result per group | one joint prompt/result; local prompts audit-only | one per group locally or one joint call | free-form semantic profiles; no parser contract |
| CONDES | one continuous target/continuum | not applicable | not applicable | one call | structured textual output request, no parser-backed reusable metadata |
| CATDES + TEXTUAL | one matched group | local contextualized prompt/result | combined outer shape, still local-first | one per group in both modes | contextualized evidence preserves the two layers separately |

**[DECISION]** `isolate.groups` is not a common semantic contract. It is a
method-specific control whose meaning must be read with `generation_architecture`
and the return contract.

## 10. Operational validation matrix

The following checks were run locally with `generate = FALSE` after
`devtools::load_all()`. They did not contact a backend.

| Check | Result | What it supports |
| --- | --- | --- |
| QDA `sensochoc`, full versus sampled/drop-negative | canonical evidence identical; selected and semantic evidence changed | selection layer is separate from `product_profiles` |
| QDA exact prompt accessor | `llm_io$prompts` identical to `nail_prompt()` | exact prompt storage for QDA |
| TEXTUAL two-group synthetic corpus, full versus half sample | canonical evidence identical; selected IDs changed; sampled IDs all resolve in registry | stable text provenance and selection separation |
| TEXTUAL exact prompt accessor | `llm_io$prompts` identical to `nail_prompt()` | exact prompt storage for TEXTUAL |
| CATDES two-group synthetic preview, local versus joint | canonical `statistical_profiles` identical; local audit prompts retained; joint prompt contains both groups | `isolate.groups` has actual CATDES generation semantics |
| CATDES binary completion | existing `test-catdes-stage3.R` verifies completion and `drop.negative` behavior | paired binary contrast is a controlled semantic projection |
| CONDES `FactoMineR::decathlon` preview | canonical evidence path remains distinct from prompt; exact prompt matched `llm_io` | single-target provenance and exact prompt storage |
| CATDES+TEXTUAL composition | implementation/tests inspected; no generated upstream textual profiles were fabricated for this audit | composition invariants remain a code/test claim, not a new benchmark result |

### What was not tested here

- **[DECISION]** No live Ollama/Gemini generation was performed.
- **[DECISION]** No new CATDES+TEXTUAL benchmark was run because the request
  was a provenance/scope audit, not an experimental campaign.
- **[OBSERVED]** Existing tests and development artifacts remain the relevant
  evidence for parser behavior and prior LLM quality findings.

## 11. Reading editability, context, and traceability

### Reading

| Method | Inspectable internally | Publicly replaceable | Main method-specific risk |
| --- | --- | --- | --- |
| QDA | yes, in `qda_prompt_blocks$reading` | selectable/removable, not replaceable | changing HIGHER/LOWER meaning can create horizontal distortion |
| TEXTUAL | yes, in `textual_prompt_blocks$reading` | selectable/removable, not replaceable | raw texts require exact-ID and diversity rules |
| CATDES | yes, in `catdes_prompt_blocks$reading` | no | percentages/means have descriptive within-variable semantics |
| CONDES | yes, in `condes_prompt_blocks$reading` | no | correlation, R2, p-value, Estimate, and end profiles are not interchangeable |
| CATDES + TEXTUAL | embedded in composition prompt | no | statistical anchor and respondent text have asymmetric status |

**[DECISION]** Reading is currently a method-provided convention. Any future
override should be method-specific, validated, recorded as a prompt
convention, and unable to modify evidence selection or statistical computation.

### Domain context

- **[VERIFIED]** `introduction` enters the context layer and is not part of
  the canonical evidence object.
- **[DECISION]** Context may supply substantive meaning for a pattern, but it
  must not be silently reclassified as statistical evidence.
- **[HYPOTHESIS]** A provenance envelope should distinguish context from
  evidence explicitly if downstream tools need to audit the complete prompt.

### Traceability

- **[VERIFIED]** QDA traceability is primarily through product/evidence IDs in
  internal artifacts and reusable metadata.
- **[VERIFIED]** TEXTUAL traceability is strongest at the raw-text level because
  stable IDs are displayed and parser-selected IDs are validated.
- **[VERIFIED]** CATDES retains evidence IDs internally but intentionally hides
  them from semantic-facing prose; traceability therefore requires joining
  `interpretation_evidence` to the displayed semantic facts.
- **[VERIFIED]** CONDES retains an evidence registry and family-specific
  selection, while the prose projection omits IDs.
- **[PARTIAL]** CATDES+TEXTUAL preserves exact text IDs and CATDES selected IDs,
  but the current-stage composition artifact does not expose a single uniform
  source map across all nested fields.

## 12. Divergences from `STATISTICAL_PROMPT_FRAMEWORK.md`

The prior framework report is broadly consistent with the current code and was
not modified. The following refinements are needed for precision:

1. **[VERIFIED divergence]** The framework describes a common LLM-IO layer as
   if it were uniformly canonical across QDA, TEXTUAL, CATDES, and CONDES.
   In the current `nail_catdes()` implementation, no `llm_io` attribute is
   attached by the CATDES artifact helper. The accessors recover prompts and
   responses through compatibility adapters. The framework should therefore
   describe CATDES as *accessor-compatible but not canonically llm_io-backed*
   until a separate CATDES correction is made.
2. **[VERIFIED refinement]** The framework correctly identifies
   CATDES+TEXTUAL `contextualized_evidence` as the public composed evidence
   artifact, but this object is a stage-specific composition containing parsed
   textual/model-assisted material as well as mechanical CATDES anchors. It
   should not be read as a new purely statistical canonical object.
3. **[EDITORIAL]** The framework's canonical-vs-facing section repeats the
   CATDES comparison sentence once. This is editorial only and has no code or
   contract consequence.

No other material divergence was found that changes the framework's main
conclusions about method-specific blocks, evidence separation, or
`isolate.groups` semantics.

## 13. Three most useful improvements

Ranked by expected value and limited scope:

### 1. Add method-specific scope/provenance regression assertions

Record and test, without changing return shapes:

```text
scope = local | joint | local-first-combined | single-target
source artifact
selected evidence/text IDs
generation architecture
```

This would make the non-equivalence of `isolate.groups` explicit and prevent
future prompt-block work from accidentally changing generation scope.

### 2. Normalize CATDES current-stage LLM-IO storage

Add a CATDES-specific canonical `llm_io` attachment, preserving the existing
joint/local return objects, semantic profiles, evidence, and accessors. The
goal is provenance symmetry and exact prompt/response inspection, not a
package-wide refactor.

### 3. Design a CATDES+TEXTUAL composition artifact

Expose a clearly named, inspectable local composition record containing:

```text
scope
CATDES source and selected evidence IDs
TEXTUAL source and selected TXT IDs
statistical_anchor
textual_enrichment
exact rendered prompt
```

This should be designed and regression-tested before any attempt to generalize
the prompt renderer or expose a public reading override.

## 14. Recommended next intervention: `nail_catdes_textual()`

The next intervention should be a **diagnostic composition-contract PASS**, not
an architecture rewrite and not an LLM benchmark.

Recommended sequence:

1. Construct a small simulated CATDES + TEXTUAL object pair using existing test
   fixtures or mocked upstream profiles, with two groups and known text IDs.
2. Assert that every CATDES selected evidence ID in the composition maps to the
   upstream CATDES interpretation evidence.
3. Assert that every representative/tension `TXT...` ID maps to the canonical
   TEXTUAL registry, belongs to the selected input, and belongs to the same
   group.
4. Assert local-first generation semantics for both `isolate.groups` values
   without calling a backend.
5. Compare `nail_evidence()` on the composed result with the nested
   `contextualized_evidence` object and assert that the statistical anchor and
   textual enrichment remain separate.
6. Only after these structural checks, decide whether a named
   `catdes_textual_prompt_blocks` artifact is needed.

The intervention should explicitly avoid:

- flattening CATDES and TEXTUAL evidence;
- treating text as a statistical explanation of every CATDES fact;
- introducing a universal renderer;
- changing `isolate.groups` semantics;
- adding a new public accessor before the nested provenance contract is stable.

## 15. Conclusion

NaileR already provides a credible evidence-first architecture for the four
primary methods. The strongest verified property is not that all prompts have
the same shape; it is that each method keeps its canonical analytical object
separate from the selected, rendered, and interpreted view.

The main remaining risk is therefore **provenance asymmetry**, not statistical
recomputation: CATDES lacks canonical `llm_io`, and CATDES+TEXTUAL lacks a
single explicit composition prompt artifact. Scope is also method-specific and
must remain so.

The working principle supported by the current implementation is:

```text
statistical method
    -> produces and defines method-specific evidence

prompt architecture
    -> organizes how a model may reason from that evidence

LLM
    -> produces the substantive interpretation within the recorded scope
```

This is a **[DECISION]** for architectural discipline and a **[HYPOTHESIS]**
about future generalization, not a claim that one universal renderer or one
universal evidence schema has already been validated.
