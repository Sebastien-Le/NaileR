# NaileR statistical prompt framework

## 0. Scope and status vocabulary

This report consolidates the current prompt architecture of QDA, TEXTUAL,
CATDES, CONDES, and CATDES + TEXTUAL. It was prepared on the working branch
`dev-statistical-prompt-framework`, created from:

```text
source branch: dev-condes-prompt-audit
source HEAD:   a3e51d1315c270d8f8b6bcef1897dfb7c734706a
```

No R code, tests, user documentation, or LLM benchmark was changed or run by
this consolidation pass. The existing development artifacts were read as
evidence, not treated as package documentation.

The report deliberately separates four epistemic statuses:

- **Verified implementation contract** — directly visible in current R code,
  accessors, stored attributes, or regression tests.
- **Observed experimental finding** — recorded in a development benchmark or
  blind review under specified data/model/settings.
- **Stabilized methodological decision** — a decision already adopted in the
  development work because it is compatible with the verified contracts and
  recorded evidence.
- **Open hypothesis** — plausible, useful for planning, but not established by
  the current implementation or experiments.

The main methodological boundary is:

```text
statistical method
    -> produces and defines canonical evidence

prompt architecture
    -> organizes how the LLM may reason from that evidence

LLM
    -> produces a revisable substantive interpretation
```

The prompt framework must therefore preserve the distinction between
statistical evidence, evidence-reading conventions, interpretive permission,
scope, and output serialization.

## 1. Executive consolidation

### Verified implementation contract

NaileR currently has four method-specific prompt architectures:

1. QDA: eight internal components, including a QDA-specific reusable metadata
   contract and optional default blocks.
2. TEXTUAL: seven internal components, with optional reading, interpretation,
   and local-task blocks and a parser-backed output contract.
3. CATDES: seven internal components, with a method-specific joint/local scope
   distinction and no active output/parser block.
4. CONDES: six internal components, without `local_task`, because one call
   naturally targets one continuous variable or continuum.

All four retain method-specific canonical artifacts distinct from the
LLM-facing projection. `nail_evidence()` is intended to expose the canonical
evidence; `nail_prompt()` exposes the prompt actually constructed; and
`nail_response()` exposes the stored response through the common LLM-IO layer.

### Stabilized methodological decisions

- Evidence-first does not mean evidence-only or paraphrase-only.
- A higher-level concept is acceptable when it synthesizes several displayed
  facts and remains traceable to them.
- Fidelity concerns the meaning and epistemic status of a fact, not mandatory
  preservation of its literal vocabulary.
- Method-specific reading rules must not be replaced by a universal wording
  template.
- Canonical evidence must remain complete, deterministic, and independent of
  prompt wording and LLM generation.
- Domain context belongs in `context`, not in statistical or textual evidence.
- No package-wide renderer or public universal prompt-block API is justified
  yet.

### Open hypotheses

- A shared conceptual grammar may improve auditability without requiring one
  universal renderer.
- `reading` could eventually become user-editable, provided that editing it
  cannot modify canonical evidence, evidence selection, or statistical
  computation.
- Scope binding may be a reusable conceptual function, but its implementation
  must remain method-specific because `isolate.groups` does not have the same
  semantics in QDA, TEXTUAL, CATDES, and CATDES + TEXTUAL.
- The contribution of reading, interpretation, and local task is probably
  interactive rather than additive, but the current experiments do not prove a
  general interaction law.

## 2. Comparative block matrix

The table describes current implementation, not an ideal future API.

| Method | Current ordered blocks | Optional blocks | Protected / method-specific blocks | Internal artifact | Renderer status |
| --- | --- | --- | --- | --- | --- |
| QDA | `context`, `reading`, `question`, `interpretation`, `local_task`, `evidence`, `reusable`, `output` | `reading`, `interpretation`, `local_task` through `default_blocks` | `evidence`, `reusable`, `output` | `qda_prompt_blocks`, named by product or portfolio | QDA-specific renderer; local or portfolio |
| TEXTUAL | `context`, `reading`, `question`, `interpretation`, `local_task`, `evidence`, `output` | `reading`, `interpretation`, `local_task` through `default_blocks` | `context`, `question`, `evidence`, `output` | `textual_prompt_blocks`, named by group | TEXTUAL-specific renderer; always local-first generation |
| CATDES | `context`, `reading`, `question`, `interpretation`, `local_task`, `evidence`, `output` | None in current public API | `evidence`; scope-specific `local_task`; `output` currently `NULL` | `catdes_prompt_blocks`, named by group or `portfolio` | CATDES-specific renderer; joint or local |
| CONDES | `context`, `reading`, `question`, `interpretation`, `evidence`, `output` | None in current public API | `evidence`; one-target scope; output contract | `condes_prompt_blocks`, one ordered list | CONDES-specific renderer; no `local_task` |
| CATDES + TEXTUAL | No unified prompt-block artifact; local prompt built from contextualized evidence | None in current public API | Statistical anchor and textual enrichment are protected as separate sources | `contextualized_evidence`, local prompts, contextualized profiles | Composition-specific local renderer |

### Interpretation of the matrix

**Verified implementation contract.** The common names are already useful as
an audit vocabulary, but their content is not interchangeable. In particular,
QDA's `reusable` block is an HTML metadata serialization instruction, whereas
TEXTUAL's machine-readable contract lives inside `output`; CATDES currently
has no corresponding output parser; and CONDES has no per-object local task.

**Stabilized methodological decision.** Do not copy QDA's `reusable` block into
other methods and do not force CATDES or CONDES to acquire artificial blocks
just to make the matrix rectangular.

## 3. Canonical versus LLM-facing evidence

| Method | Canonical evidence | Selection / interpretation layer | LLM-facing projection | What the LLM sees | Public evidence path |
| --- | --- | --- | --- | --- | --- |
| QDA | `product_profiles` from `SensoMineR::decat()` | `interpretation_evidence` selects retained markers, sampling, and polarity rules | `semantic_facing_evidence` | Relative `HIGHER` / `LOWER` sensory facts, adjusted means, `v.test`, p-values, product/stimulus labels | `nail_evidence()` returns canonical product profiles |
| TEXTUAL | `textual_evidence`, including complete text registry and stable text IDs | `interpretation_input` selects texts and records shown IDs/coverage | Per-group data block from `textual_evidence` + `interpretation_input` | Exact selected texts, IDs, group coverage and corpus metrics | `nail_evidence()` returns canonical textual evidence |
| CATDES | `statistical_profiles` with group profiles and evidence registry | `interpretation_evidence` selects qualitative/quantitative facts and tracks IDs | `semantic_facing_evidence` | Plain-language `MORE/LESS FREQUENT` and `HIGHER/LOWER` facts; p-values, v-tests, ranks, IDs and display-origin metadata are not exposed | `nail_evidence()` returns canonical statistical profiles |
| CONDES | `continuous_profile` with quantitative, qualitative, end-profile families and registry | `interpretation_evidence` selects each family deterministically | `semantic_facing_evidence` | Correlation, R2, Estimate, p-values, directions, lower/higher end facts; evidence IDs are not exposed in the prose | `nail_evidence()` returns canonical continuous profile |
| CATDES + TEXTUAL | CATDES `semantic_facing_evidence` plus TEXTUAL `textual_evidence` / parsed `textual_profiles` | Validation joins group names and text IDs; no recomputation | `contextualized_evidence` with `statistical_anchor` and `textual_enrichment` | CATDES facts remain the statistical anchor; exact representative/tension texts are resolved from canonical text IDs | `nail_evidence()` exposes the composed contextualized artifact |

### Consequences

**Verified implementation contract.** The LLM-facing object is a projection,
not a replacement for canonical evidence. Sampling may change the selected
interpretation layer while leaving the canonical artifact unchanged. The
projections are deliberately method-specific because the underlying evidence
has different semantics:

- QDA directions are relative sensory deviations;
- TEXTUAL evidence consists of exact raw respondent expressions;
- CATDES facts are relative category/group prevalence or within-variable mean
  comparisons;
- CONDES facts are continuous associations, global qualitative associations,
  and end-profile effects.

**Stabilized methodological decision.** A future framework must never treat
these four LLM-facing representations as a single generic evidence schema
without retaining method-specific reading metadata.

**Open hypothesis.** A common provenance envelope could be useful around the
method-specific payload, for example source schema, object scope, selected IDs,
and rendering policy. This would be safer than normalizing all factual text
into one universal representation.

## 4. Scope and output contract matrix

`isolate.groups` is intentionally compared rather than equated.

| Method | Scope unit | `isolate.groups = TRUE` | `isolate.groups = FALSE` | Generation calls | Output / downstream contract |
| --- | --- | --- | --- | --- | --- |
| QDA | Product/stimulus or portfolio | One prompt/result per product or stimulus | One portfolio prompt/result | One per local product, or one portfolio call | QDA product interpretation metadata is appended and parsed downstream; `nail_prompt()` selects local or portfolio prompt |
| TEXTUAL | Group | Named local prompts/results returned | Combined outer preview/result, but generation remains one call per group | One per ready group in both modes | Canonical structured textual profile parsed from fields and text IDs; no global synthesis |
| CATDES | Observed category or constructed group | One local prompt/result per group | One joint prompt/result containing all groups; local prompts retained for audit | One per group locally, one joint call otherwise | Free-form semantic profiles; `output` currently `NULL`; no response parser contract |
| CONDES | One continuous target or continuum | Not applicable | Not applicable | One call for the target | Standard/latent summary contract; no parser-specific reusable metadata |
| CATDES + TEXTUAL | One matched group at a time | One contextualized prompt/result per group | Combined outer shape, but contextualization remains local-first | One per group in both modes | `contextualized_evidence` preserves CATDES statistical anchor and textual enrichment separately |

### Scope findings

**Verified implementation contract.** TEXTUAL and CATDES both use local-first
generation, but their `isolate.groups = FALSE` return semantics differ:

- TEXTUAL preserves a historical combined outer shape while still making
  independent local calls;
- CATDES actually constructs and sends one joint prompt containing all groups.

QDA genuinely changes between a portfolio prompt and local product prompts.
CATDES + TEXTUAL remains local-first even when its outer return is combined.
CONDES has no group isolation dimension.

**Observed experimental finding.** The TEXTUAL factorial work indicates that
`local_task` may do more than add a generic application reminder. A bridge
block improved the RI condition but did not reproduce the full condition. This
does not establish a causal decomposition of `local_task`.

**Stabilized methodological decision.** Scope binding must not be inferred
from the name `isolate.groups` alone. Any future common framework should store
explicit scope metadata such as `local`, `joint`, `local-first-combined`, or
`single-target`.

## 5. Reading, context, interpretation and traceability

### 5.1 Reading editability

| Method | Current inspectability | Current editability | Main risk of early public editability |
| --- | --- | --- | --- |
| QDA | `qda_prompt_blocks$reading` | Selectable/removable through `default_blocks`, not replaceable through public `reading=` | Removing or replacing HIGHER/LOWER semantics could create horizontal distortion |
| TEXTUAL | `textual_prompt_blocks$reading` | Selectable/removable through `default_blocks`, not replaceable through public `reading=` | Raw texts need exact-ID and diversity rules; generic statistical wording would be wrong |
| CATDES | `catdes_prompt_blocks$reading` | Not currently selectable or replaceable | Percentages and means have within-variable, descriptive semantics; p-values/v-tests are intentionally absent from the LLM projection |
| CONDES | `condes_prompt_blocks$reading` | Not currently selectable or replaceable | Correlation, p-value, R2, Estimate, and end profiles require distinct interpretation rules |

**Stabilized decision.** Treat `reading` as a method-provided convention before
considering a public editing API. Any future override must leave canonical
evidence, selection, provenance, and accessors untouched and must be visibly
marked as a prompt convention rather than a statistical result.

**Open hypothesis.** Expert-editable reading may be valuable for specialized
domains or local models, but it should probably be an advanced, method-specific
override with validation and provenance rather than a universal character
argument.

### 5.2 Domain context

**Verified implementation contract.** `introduction` is inserted into the
context layer of every current prompt architecture. It is not part of the
canonical evidence.

The operational examples demonstrate why this matters:

- QDA context can explain the study and sensory task;
- CONDES context can explain domain meaning, such as running times versus
  jumping/throwing distances or heights in `decathlon`;
- TEXTUAL context can situate the discourse being analyzed;
- CATDES context can explain whether labels are observed categories or
  constructed groups;
- CATDES + TEXTUAL context explains that CATDES is the statistical anchor and
  text is supplementary enrichment.

**Stabilized decision.** Context may help translate statistical direction into
substantive meaning, but it must never be silently promoted to statistical
evidence.

### 5.3 Statistical versus interpretive scope

The framework should retain this sequence:

```text
canonical evidence
    -> method-specific reading convention
    -> analytical question
    -> interpretation permission and epistemic status
    -> scope/local task
    -> LLM-facing evidence
    -> output contract
```

The exact order is rendered method-specifically. CONDES has no local task;
CATDES has an explicit local task because category/group scope is otherwise
ambiguous; QDA and TEXTUAL bind the task to a product/stimulus or group.

### 5.4 Traceability

**Verified implementation contract.** Traceability is strongest where the
LLM-facing representation preserves stable identifiers:

- TEXTUAL displays exact text IDs and validates parsed representative/tension
  IDs against the selected subset;
- CATDES retains canonical evidence IDs internally, but does not expose them
  in the semantic-facing prose;
- QDA retains canonical marker IDs internally while presenting readable
  product facts;
- CONDES retains an evidence registry internally while presenting readable
  family-specific facts.

**Stabilized decision.** Hiding technical IDs from the LLM can improve
readability, but every semantic-facing fact should remain mechanically
resolvable to a canonical source. CATDES + TEXTUAL demonstrates the strongest
current composition pattern: statistical facts and selected exact texts remain
separate and are joined through validated identifiers.

**Open hypothesis.** A stable optional evidence-reference annotation could
improve human auditability without exposing ranking metadata to the LLM. This
should be tested method by method; it should not be added as a universal prompt
requirement now.

## 6. CATDES + TEXTUAL composition

### Verified implementation contract

`nail_catdes_textual()` does not recompute CATDES or re-analyze raw text. It
requires:

1. CATDES canonical semantic-facing evidence;
2. TEXTUAL canonical evidence;
3. parsed TEXTUAL profiles;
4. matching group names;
5. representative and tension IDs that belong to the selected text subset.

The resulting `contextualized_evidence` stores, per group:

```text
statistical_anchor
    status
    factual_text
    selected_evidence_ids
    n_selected_evidence
    n_displayed_evidence
    existing_semantic_interpretation

textual_enrichment
    core_textual_profile
    dominant_themes
    within_group_coherence
    internal_diversity
    representative_texts
    tension_texts
    coverage metrics
```

The statistical and textual layers are deliberately asymmetric: CATDES
anchors the group characterization; TEXTUAL adds respondent-level language,
themes, diversity, and exact supporting texts.

### Stabilized methodological decision

The composition must not flatten the two evidence types into one undifferentiated
profile. A textual theme may enrich or contextualize a CATDES characteristic,
but it must not rewrite the CATDES fact or be generalized to unrelated CATDES
dimensions.

### Open hypotheses and risks

- The current contextualized prompt has no separate prompt-block artifact;
  composition is structurally explicit in `contextualized_evidence` but less
  inspectable at the prompt-block level.
- The default request is carefully asymmetric, but an LLM may still infer
  broader reasons or motives from text unless the distinction is preserved.
- The output contract for contextualized profiles is structured, but its
  relationship to the upstream CATDES and TEXTUAL parsers deserves a dedicated
  audit.

## 7. Operational validation matrix

This matrix records existing validation, not new execution in this pass.

| Method / path | Existing operational material | What was held invariant | What was actually observed | Status |
| --- | --- | --- | --- | --- |
| QDA | `qda_prompt_blocks_poc.md`; QDA evidence-level and relative-wording experiments | Dataset, product, selected evidence, context, request, output and model within each comparison | Prompt block ablations and blind wording comparisons; full prompt often strong, minimal prompt viable; interpretive lift can improve without changing profiles | Recorded experiment; limited model/sample scope |
| TEXTUAL | `textual_prompt_blocks_poc.md`; benchmark 1, benchmark 2, factorial and bridge artifacts | Corpus, context, question, selected texts, output, model and generation settings within each comparison | `F` ranked strongly in benchmark 2/factorial; `RI` did not reproduce `F`; bridge `RIB` improved over `RI` but did not reach `F`; parser tolerance and analytical usefulness diverged | Recorded experiment; partial cell reuse limitation |
| CATDES | `catdes_prompt_blocks_poc.md`; CATDES tests and evidence-value/contrast-reading materials | Statistical profiles and selected evidence across prompt architecture comparisons | Standard/latent naming rules and canonical evidence separation preserved; joint/local scope remains method-specific | Code/tests verified; no new benchmark here |
| CONDES | `condes_prompt_blocks_poc.md`; CONDES audit and prompt-block tests | `continuous_profile`, selected evidence, semantic-facing evidence and target identity | Six-block representation works; standard preserves observed target name; latent permits continuum naming; no `local_task` needed | Code/tests verified; no LLM benchmark here |
| CATDES + TEXTUAL | `test-catdes-textual.R`; contextualized evidence implementation | CATDES semantic facts, textual IDs, group matching, parsed textual profiles | CATDES remains statistical anchor; exact representative/tension texts are resolved and validated | Code/tests verified; composition benchmark remains open |

### Experimental interpretation

**Observed finding.** The experiments support modularity as an audit and
ablation instrument. They do not establish a universal best block set, a
universal renderer, or an additive quality contribution for each block.

## 8. Cross-method decisions and non-decisions

### Stabilized decisions

1. Keep method-specific canonical evidence as the source of truth.
2. Keep LLM-facing evidence as a traceable projection rather than a second
   statistical analysis.
3. Keep context separate from evidence.
4. Keep reading separate conceptually from interpretation, even where legacy
   builders still contain mixed wording outside the PoCs.
5. Permit vertical interpretive lift when multiple facts support it.
6. Penalize horizontal semantic distortion and status changes, not abstraction
   itself.
7. Treat output contracts and analytical quality as distinct dimensions.
8. Treat scope as explicit metadata, not as an assumed consequence of a
   similarly named argument.

### Explicit non-decisions

- No universal `PromptBlocks` S3 class or `+` operator.
- No universal public `reading=` argument.
- No universal `default_blocks` API across methods.
- No package-wide renderer.
- No global parser redesign.
- No replacement of technical evidence by LLM-facing prose.
- No assumption that QDA, TEXTUAL, CATDES, and CONDES should have identical
  isolate semantics.

## 9. Ranked candidate improvements

The ranking concerns methodological value and risk, not implementation effort.

### 1. Add explicit scope and provenance assertions

Create method-specific tests or internal metadata checks ensuring that every
prompt-facing unit records its scope (`product`, `group`, `category`,
`portfolio`, `joint`, or `single-target`), source artifact, selected IDs, and
generation architecture. This addresses the CATDES `isolate.groups` ambiguity
without changing the public argument immediately.

### 2. Design an advanced, method-specific reading override

Before exposing `reading=` publicly, define validation and provenance rules:
the override may change interpretation instructions but not evidence, sampling,
canonical objects, or output contracts. Start with one method-specific design
document and a no-LLM prompt equivalence test.

### 3. Strengthen canonical-to-facing traceability

Add an inspectable mapping from every displayed semantic-facing fact or text
ID to its canonical evidence ID/source row. Keep technical IDs optional in the
LLM prompt, but make human audit resolution direct and mechanically testable.

### 4. Give CATDES + TEXTUAL an explicit composition prompt artifact

Add a read-only internal artifact describing the contextualized prompt as
`context`, `question`, `statistical_anchor`, `textual_enrichment`, and
`output`, while preserving the current asymmetric evidence contract and local
generation. Do not merge statistical and textual facts.

### 5. Run an independent cross-method ablation replication

Use new responses rather than reused cells, with fixed evidence/context/request/
model and blind review. Compare only method-relevant block variants and score
interpretive lift, grounding, calibration, horizontal distortion, and output
contract compliance separately.

### 6. Decide whether CATDES output needs a protected contract

Only after the scope and composition audits, determine whether CATDES should
remain free-form or acquire a minimal structured output contract. Do not copy
QDA's reusable metadata or TEXTUAL's parser schema by analogy alone.

## 10. Proposed next PASS

The next PASS should be a **scope-and-provenance contract audit**, not a
package-wide renderer refactor and not an LLM benchmark.

Recommended scope:

1. document and test the explicit generation architecture for QDA, TEXTUAL,
   CATDES, CONDES, and CATDES + TEXTUAL;
2. verify that each prompt-facing unit can be resolved to its canonical source;
3. add regression tests for the non-equivalence of `isolate.groups` semantics;
4. record `local`, `joint`, `local-first-combined`, and `single-target` status
   without changing public return shapes;
5. prepare, but do not yet implement, the design for a method-specific
   `reading` override;
6. add a composition artifact design for CATDES + TEXTUAL only if it can be
   done without changing its statistical anchor or parser contracts.

Success criteria for that PASS should be entirely structural:

```text
no statistical object changes
no evidence selection changes
no public accessor changes
no LLM calls required
all current tests remain green
scope and provenance are inspectable and method-specific
```

## 11. Source artifacts consulted

- `R/nail_qda.R`
- `R/nail_textual.R`
- `R/nail_textual_semantic.R`
- `R/nail_catdes.R`
- `R/nail_catdes_textual.R`
- `R/nail_condes.R`
- `R/nail_evidence.R`
- `R/nail_llm_io.R`
- QDA, TEXTUAL, CATDES, CATDES + TEXTUAL, CONDES, evidence, and LLM-IO tests
- `dev/prompt_blocks_poc/PROMPT_ANALYSIS_FINDINGS.md`
- `dev/prompt_blocks_poc/qda_prompt_blocks_poc.md`
- `dev/prompt_blocks_poc/textual_prompt_blocks_poc.md`
- `dev/prompt_blocks_poc/catdes_prompt_blocks_poc.md`
- `dev/prompt_blocks_poc/condes_prompt_blocks_poc.md`
- `dev/prompt_blocks_poc/catdes_evidence_reading_design.md`
- `dev/prompt_blocks_poc/catdes_prompt_audit.md`
- `dev/prompt_blocks_poc/condes_prompt_audit.md`

No benchmark key, response, or new LLM result was generated or modified.
