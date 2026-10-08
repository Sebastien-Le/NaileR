# CATDES Prompt Architecture Audit

## 1. Scope and source of truth

This is a code and prompt audit only. No CATDES code, test, statistical
evidence, prompt, or package documentation was modified, and no LLM was
called.

The audit was performed on:

- branch: `dev-catdes-prompt-audit`;
- HEAD: `c06d1d81106241aaa54540a6784a8d301f69588e`;
- source baseline: `dev-textual-prompt-blocks-poc` at the same commit;
- out of scope and preserved: the pre-existing untracked
  `dev/operational_validation/` directory.

The main sources were `R/nail_catdes.R`, `R/nail_catdes_prep.R`,
`R/nail_catdes_ground.R`, `R/nail_catdes_textual.R`, `R/nail_evidence.R`,
`R/nail_llm_io.R`, the CATDES stage/preparation/grounding/textual tests, and
the QDA/TEXTUAL prompt-block development records.

The labels below are used deliberately:

- **Observed in code**: directly supported by the current implementation.
- **Observed in mechanical prompt**: directly supported by a `generate = FALSE`
  prompt inspection.
- **Interpretation**: an architectural reading of those observations.
- **Working hypothesis**: a claim requiring an experiment.
- **Architectural implication**: a possible design consequence, not a change
  made in this pass.
- **Open question**: unresolved by the current code and mechanical examples.

## 2. Active CATDES execution path

### 2.1 Modern path

The active path is:

```text
dataset / x
  ↓
.normalize_nail_catdes_input()
  ↓
nail_catdes_prep() or canonicalization of an existing object
  ↓
statistical_profiles
  ↓
.build_interpretation_evidence_nail_catdes()
  ↓
interpretation_evidence
  ↓
.build_semantic_facing_evidence_nail_catdes()
  ↓
semantic_facing_evidence
  ↓
build_request_catdes() when request is NULL
  + .semantic_guide_nail_catdes()
  + .local_task_nail_catdes()
  + local group text
  ↓
.build_local_semantic_prompts_nail_catdes()
  ↓
one local prompt per group
  ↓
local LLM interpretation when generate = TRUE
  ↓
semantic_profiles
```

**Observed in code.** In `nail_catdes()` (`R/nail_catdes.R:1886-2106`),
`statistical_profiles` is obtained before any prompt wording is assembled.
The selection and semantic-facing stages are also completed before
`introduction` defaults and `request` defaults are resolved. With
`generate = FALSE`, the function returns either the named local prompts or a
combined local-first preview; no backend is called.

`semantic_profiles` stores each local prompt and, after generation, the raw
response and backend result. Its settings explicitly declare
`architecture = "local_first"` and
`global_synthesis_performed = FALSE` (`R/nail_catdes.R:1587-1645`).

### 2.2 Code that is active, compatibility-only, or historical

| Component | Current status | Evidence |
|---|---|---|
| `.normalize_nail_catdes_input()` and `nail_catdes_prep()` | Active preparation/canonicalization path | Called from `nail_catdes()` before evidence selection |
| `statistical_profiles` | Canonical statistical artifact | Attached to every modern CATDES result |
| `.build_interpretation_evidence_nail_catdes()` | Active selected-evidence stage | Called directly by `nail_catdes()` |
| `.build_semantic_facing_evidence_nail_catdes()` | Active LLM-facing projection | Called directly by `nail_catdes()` |
| `.semantic_guide_nail_catdes()` | Active prompt guide | Called by `.build_local_semantic_prompts_nail_catdes()` |
| `build_request_catdes()` | Active default request builder | Called only when `request = NULL` in `nail_catdes()` |
| `.local_task_nail_catdes()` | Active local scope/instruction block | Called for every local prompt |
| `.build_local_semantic_prompts_nail_catdes()` | Active renderer | Constructs the current local prompt |
| `semantic_profiles` | Active local-first storage | Used by CATDES result and compatibility accessors |
| `get_prompt_catdes()` | Historical/compatibility helper, not active in modern `nail_catdes()` | No call site was found outside its definition |
| `get_sentences_quali()` / `get_sentences_quanti()` | Historical helpers for `get_prompt_catdes()` | No modern call site was found |
| `build_guide_catdes()` | Historical/public-style table-guide builder, not used by modern prompt construction | No call site was found outside its definition |
| `nail_catdes_ground()` | Separate optional grounding pass | Consumes frozen CATDES artifacts; it is not the PASS 1 prompt path |
| `nail_catdes_textual()` | Separate composed CATDES + TEXTUAL analysis | Consumes CATDES semantic evidence; it is not the active `nail_catdes()` renderer |

The legacy `get_prompt_catdes()` path is materially different: it builds a
`# Introduction`, `# Task`, and `# Data` prompt from older tables and exposes
formatted statistical columns such as `p.value` and `v.test`. It must not be
confused with the modern semantic-facing path.

## 3. Canonical statistical evidence

### 3.1 `statistical_profiles`

**Observed in code.** The canonical object is produced from FactoMineR CATDES
output or accepted from a supported prepared/statistical object. Its groups
contain:

- qualitative marker tables;
- quantitative marker tables;
- positive and negative marker views;
- group metrics and factual summaries;
- a global `evidence_registry` with unique evidence IDs;
- settings describing the preparation, threshold, ranking, and evidence-ID
  rules;
- metadata recording provenance, including the statistical source and the
  absence of LLM computation.

Qualitative markers retain variable, modality, direction, percentages,
`v_test`, `p_value`, rank, and related source information. Their direction is
relative to the full sample: `overrepresented` means a modality occurs more
often in the group than globally; `underrepresented` means less often.

Quantitative markers retain group mean, overall mean, standard deviations,
direction, `v_test`, `p_value`, and rank. `higher` and `lower` mean that the
group mean is respectively above or below the overall mean.

The canonical profiles are not the prompt. They are the full statistical
artifact from which later selections and textual projections are derived.

### 3.2 `interpretation_evidence`

**Observed in code.** `.build_interpretation_evidence_nail_catdes()` selects
markers by group using `quali.sample`, `quanti.sample`, and `drop.negative`.
It records selected evidence IDs, excluded negative IDs, selection status,
and counts/metrics. It validates that selected rows can be matched back to the
canonical registry.

The distinction is:

```text
statistical_profiles
    complete canonical statistical evidence

interpretation_evidence
    deterministic subset selected for interpretation
```

Changing sampling or `drop.negative` does not mutate
`statistical_profiles`. It changes the evidence selected for downstream
interpretation.

### 3.3 `semantic_facing_evidence`

**Observed in code.** The projection is mechanical and method-specific:

| Canonical direction | Plain-language fact shown to the LLM |
|---|---|
| qualitative `overrepresented` | `MORE FREQUENT` |
| qualitative `underrepresented` | `LESS FREQUENT` |
| quantitative `higher` | `HIGHER` mean |
| quantitative `lower` | `LOWER` mean |

The qualitative wording includes group and full-sample percentages. The
quantitative wording includes group and full-sample means. Facts are grouped
by variable and then rendered as bullet points.

For a binary qualitative variable, once that variable has selected evidence,
the renderer can display every significant modality available for that
variable in the group. This is represented as
`binary_complete_contrast`; rows not in the selected subset are marked
`completed_binary_contrast`. With `drop.negative = TRUE`, underrepresented
rows are removed before the binary block is completed. Multi-level variables
remain `multilevel_selected_only` and are not completed with unselected
modalities.

This means that `selected_evidence_ids` and the rows displayed in the prompt
are related but not always identical: a binary contrast may display an
additional, traceable row. The semantic-facing object records both the
selected IDs and the displayed rows/metrics.

### 3.4 What the LLM actually sees

**Observed in code.** The modern semantic-facing prompt does not expose:

- `p.value`;
- `v.test`;
- canonical `evidence_id` values.

It exposes plain-language facts, percentages, means, group labels, variable
labels, and the statistical direction words `MORE FREQUENT`, `LESS FREQUENT`,
`HIGHER`, and `LOWER`.

This is distinct from mechanical audit information. The audit objects retain
the statistical markers and IDs; the current LLM-facing representation hides
those technical fields while preserving their derived factual meaning.

`nail_evidence()` returns the canonical `statistical_profiles` artifact for
CATDES, not merely the selected prompt-facing subset. `nail_prompt()` returns
the exact local prompt through the stored `semantic_profiles` compatibility
path. Unlike the newer canonical `llm_io` pattern used by some rebuilt
analyses, modern `nail_catdes()` does not attach a dedicated `llm_io` object;
the public accessor still works through the CATDES semantic-profile adapter.

## 4. Standard versus latent epistemology

### 4.1 Standard mode

**Observed in code and mechanical prompt.** The target is an observed
categorical variable. Its category names are retained as contextual labels,
not treated as statistical evidence and not replaced by latent-profile names.
The prompt says, in substance:

```text
These are observed categories of 'Species'. Preserve their original names.
Do not reinterpret the categories as latent profiles and do not rename them.
A category name is contextual information, not statistical evidence.
```

The current rules allow a higher-level interpretation when it synthesizes
several displayed facts and remains traceable. They also allow a broader
contextual hypothesis only when it is explicitly identified as a hypothesis.
The local task repeats the no-renaming and no-unseen-category-comparison
constraints.

### 4.2 Latent mode

**Observed in code and mechanical prompt.** The target is described as a
constructed profile or latent class. Its current label is an identifier, not
an interpretation, and the prompt explicitly permits proposing a meaningful
name. The local task says to explain what the group seems to represent and
propose one concise interpretive name.

The latent guide still states that the LLM should combine convergent facts into
a higher-level semantic interpretation, but its explicit empirical guard is
shorter: `Do not invent an unlisted statistical characteristic.` It does not
repeat the standard mode's explicit contextual-hypothesis rule or its explicit
traceability wording in the mode-specific empirical rule.

### 4.3 Comparison

| Difference | Classification | Reason |
|---|---|---|
| Standard preserves observed category names | Methodologically justified | The name already denotes the observed target level |
| Latent permits a meaningful group name | Methodologically justified | Numeric/class labels are not substantive interpretations |
| Standard explicitly distinguishes synthesis, direct fact, and contextual hypothesis | Methodologically justified in principle, but asymmetrical in wording | Standard mode must protect observed labels, while latent mode needs naming; the different epistemic situations justify different rules |
| Latent empirical guard is less explicit about traceability and hypothesis status | Open question / probably incomplete calibration | The shared instruction still permits higher-level synthesis, but the latent-specific wording is less explicit |
| Standard and latent use different default introductions and nouns | Methodologically justified | They describe different target ontologies |

This asymmetry is not evidence of a statistical difference. It is a prompt-
epistemology difference. Whether the latent mode needs the same explicit
fact/interpretation/hypothesis calibration as standard mode is an open design
question, outside this audit's scope.

## 5. Current prompt anatomy

The modern local renderer is
`.build_local_semantic_prompts_nail_catdes()` (`R/nail_catdes.R:1545-1568`).
For each group it emits:

```text
# Introduction
[introduction]

---

## How to Read the Statistical Evidence
[.semantic_guide_nail_catdes()]

# Overall Analytical Request
[request or build_request_catdes()]

# Local Task
[.local_task_nail_catdes()]

# Data
## Category "..." / ## Group "..."
[semantic-facing group$text]
```

### 5.1 Sentence-level classification

| Current source | Current content | Conceptual function | Status |
|---|---|---|---|
| `introduction` | Study context/default standard or latent context | `context` | Clear |
| `.semantic_guide_nail_catdes()` | How to read directions, binary/multilevel display, group scope, fact status, no-invention rules, higher-level synthesis, mode semantics | `reading` + `interpretation` + mode/scope rules | Mixed |
| `request` / `build_request_catdes()` | What to describe, distinctive evidence, strength, ambiguity, expectedness, and sometimes synthesis/name rules | `question` + `interpretation` | Mixed |
| `.local_task_nail_catdes()` | One group only, combine facts, naming/no renaming, no unseen-group comparison | `local_task` + `interpretation` | Mixed but clearly task-bearing |
| `semantic_facing_evidence$groups[[g]]$text` | Plain-language facts for one group | `evidence` | Clear |
| post-data output contract | None in the modern prompt | `output` | Absent |

The architecture already has a recognizable local-first grammar, but the
boundaries are not explicit internal blocks. The same semantic rule can be
placed in the guide, request, and local task because those strings were
developed as layered safeguards rather than as independently stored blocks.

## 6. Mapping to the common prompt grammar

| Conceptual block | Current CATDES source | Status | CATDES-specific content |
|---|---|---|---|
| `context` | `introduction`, with mode-specific defaults | clear | Observed categorical study vs similarity-based constructed grouping |
| `reading` | `.semantic_guide_nail_catdes()` | mixed | `MORE/LESS FREQUENT`, `HIGHER/LOWER`, binary completion, multilevel selection, local group evidence |
| `question` | `request` or `build_request_catdes()` | mixed | Characterize groups/categories, distinguish strongest from secondary facts, expectedness/ambiguity |
| `interpretation` | Guide empirical rules, request synthesis sentences, local-task synthesis sentences | mixed | Higher-level synthesis, traceability, no invented fact, hypothesis status, naming |
| `local_task` | `.local_task_nail_catdes()` plus group heading | clear/mixed | One category/group only, local evidence boundary, observed-name preservation or latent naming |
| `evidence` | `semantic_facing_evidence$groups[[g]]$text` | clear | Mechanically rendered group-vs-full-sample facts |
| `output` | No separate section in modern CATDES | absent | Free-form response is stored, with no CATDES parser contract |

**Interpretation.** CATDES has most of the conceptual grammar as prompt text,
but not as a block object. The evidence block is the cleanest boundary. The
guide/request/task boundaries are currently semantic rather than structural.

## 7. Functional mixing and duplication

### 7.1 Repeated rules

The following principles occur in more than one active prompt component:

| Rule | Locations | Assessment |
|---|---|---|
| Combine convergent facts into a higher-level interpretation | `.semantic_guide_nail_catdes()`, standard `build_request_catdes()`, standard `.local_task_nail_catdes()` | Functionally repeated; guide gives general epistemic rule, request gives answer objective, local task binds it to one group. The repetition may be useful but is not structurally explicit |
| Do not invent a new empirical/statistical characteristic | Standard guide, standard request, standard local task; shorter latent guide/task variants | Partly redundant; wording differs in strength and scope |
| Preserve observed category names / do not rename | Standard guide, standard request, standard local task | Useful defense at reading, answer, and local-scope levels; still a duplication risk for future edits |
| Labels are identifiers and names may be proposed | Latent guide, latent request, latent local task | Repeated consistently for the latent naming task |
| Do not compare unseen groups/categories | Local task; the plural request can invite comparison when `isolate.groups = FALSE` | This is primarily task binding, not redundant general interpretation |
| Facts belong only to this group | Shared semantic guide | Correct scope guard and appropriate for every local prompt |
| Strong versus secondary evidence / ambiguity | Request and semantic-facing evidence ordering | Request-level interpretation instruction; not an evidence duplication |

No rule was removed or refactored. A future block design should preserve the
useful distinction between a general epistemic rule and a local scope guard;
deduplicating by string alone could weaken either role.

### 7.2 Historical duplication

The old table prompt path separately contains category descriptions, table
column explanations, and mode-specific no-renaming/latent wording. That is a
different implementation, not merely a duplicated active block. It is a
compatibility burden and a potential source of wording drift if it remains
user-visible.

## 8. `isolate.groups` scope audit

**Observed in code.** `isolate.groups` controls:

1. singular versus plural wording passed to `build_request_catdes()`;
2. the outer preview/result shape;
3. whether the returned preview is a named list of local prompts or a
   combined local-first plan.

It does **not** change the first-pass generation architecture. Generation
always loops over `local_prompts` one group at a time, and the settings record
`generation_architecture = "local_first"` and
`global_synthesis_performed = FALSE`.

### 8.1 Scope inconsistency when `isolate.groups = FALSE`

The non-isolated default request is plural/comparative. In standard mode it
contains wording such as:

```text
describe what characterizes each category and what distinguishes it from the others
comment on whether the main differences seem expected, unexpected, or mixed
```

In latent mode it contains:

```text
describe what characterizes each group and what sets it apart from the other groups
how some groups seem more clearly defined or more ambiguous than others
propose a meaningful name for each group
```

However, each backend call receives one local prompt whose local task says,
for example:

```text
Interpret ONLY the observed category shown below.
Do not compare it with unseen categories.
```

or:

```text
Interpret ONLY the constructed group shown below.
Do not compare it with unseen groups.
```

The combined preview contains all local prompts, but the actual generation
loop still sends one prompt per group. Therefore the plural request is
present in the local prompt even though the local evidence and local task are
singular.

**Classification: scope inconsistency in the prompt wording, not a global
generation leak.** The contradiction is between the overall request block and
the local task block. It could explain differences in how a model treats
`isolate.groups = TRUE` versus `FALSE`, even though the number and locality of
LLM calls are unchanged.

**Architectural implication.** Comparative scope should eventually be owned by
an explicit scope/task block, or the default request should be made singular
for local-first calls. No correction is made here because this is an audit.

## 9. `prompt_style` audit

**Observed in code.** On the modern path, `prompt_style` is passed to
`build_request_catdes()` only when `request = NULL`. It changes the default
request text between compact and detailed forms.

It does not change:

- `statistical_profiles`;
- `interpretation_evidence`;
- `semantic_facing_evidence`;
- `.semantic_guide_nail_catdes()`;
- `.local_task_nail_catdes()`;
- the evidence text;
- the local-first generation loop.

Thus, in modern CATDES, `prompt_style` is primarily a question/interpretation
wording switch, not a general renderer density switch. If a custom `request`
is supplied, the style has no textual effect on that request.

The older `build_guide_catdes()` does use `prompt_style` to choose a compact
or detailed table guide, but that helper is not invoked by modern
`nail_catdes()`. This is an important compatibility distinction.

## 10. Output-contract audit

**Observed in mechanical prompt.** The modern CATDES prompt ends with the
`# Data` section and that group's factual evidence. There is no explicit
`# Output`, `# Required output`, or final interpretation-requirements block
after the data.

**Observed in code.** The response is stored as a raw `response` field in
local backend results and in `semantic_profiles`. No CATDES response parser or
structured answer schema is required by `nail_catdes()` itself. The public
`nail_response()` accessor returns the raw current-stage response.

This is different from QDA, whose reusable metadata is a protected downstream
contract, and TEXTUAL, whose `output` block is tied to a structured parser
contract. CATDES currently has a free-form semantic response. The absence of
an output block is therefore a fact about the current architecture, not by
itself evidence that one should be added.

## 11. Mechanical prompt examples

All examples below were inspected with `generate = FALSE`; no LLM was called.

### 11.1 Standard observed category

Command used:

```r
devtools::load_all(quiet = TRUE)

standard <- nail_catdes(
  dataset = iris,
  num.var = 5,
  interpretation_mode = "standard",
  prompt_style = "detailed",
  isolate.groups = TRUE,
  generate = FALSE
)

nail_evidence(standard, select = "setosa")
nail_prompt(standard, select = "setosa", print = FALSE)
```

The generated local prompt begins mechanically as:

```text
# Introduction

For this study, observations were described according to an explicit categorical variable.

---

## How to Read the Statistical Evidence

R has already performed the statistical analysis.
Every line in the Data section is a plain-language factual statement mechanically derived from selected significant statistical markers.
MORE FREQUENT, LESS FREQUENT, HIGHER and LOWER must be read literally.
...
These are observed categories of 'Species'. Preserve their original names.
Do not reinterpret the categories as latent profiles and do not rename them.
A category name is contextual information, not statistical evidence.

# Overall Analytical Request

Based on the results, describe what characterizes this category.
Use the results to clarify the meaning of this category, not to rename it.
...

# Local Task

Interpret ONLY the observed category shown below.
...
Explain what characterizes this category without renaming it.
...
Do not compare it with unseen categories.

# Data

## Category "setosa"
```

The evidence for this local prompt contains mechanical facts such as lower
group means for Petal Length and Petal Width, a lower Sepal Length mean, and a
higher Sepal Width mean relative to the full sample. The prompt contains the
plain-language facts and percentages/means, not p-values, v-tests, or evidence
IDs.

### 11.2 Latent constructed group

For a reproducible constructed example, the following derived grouping was
used. The grouping is not an observed `Species` label; it is a deterministic
binary partition based on a sum of measured variables:

```r
iris_latent <- iris
iris_latent$ConstructedGroup <- factor(
  ifelse(
    iris$Petal.Length + iris$Sepal.Length >
      median(iris$Petal.Length + iris$Sepal.Length),
    "1",
    "2"
  )
)

latent <- nail_catdes(
  dataset = iris_latent,
  num.var = 6,
  interpretation_mode = "latent",
  prompt_style = "detailed",
  isolate.groups = TRUE,
  generate = FALSE
)

nail_evidence(latent, select = "1")
nail_prompt(latent, select = "1", print = FALSE)
```

The generated local prompt begins mechanically as:

```text
# Introduction

For this study, observations were grouped according to their similarities.

---

## How to Read the Statistical Evidence

R has already performed the statistical analysis.
...
Do not invent an unlisted statistical characteristic.
Your role is to combine convergent facts into a higher-level semantic interpretation,
not to recalculate the statistics or paraphrase every line.
These groups are constructed profiles or latent classes whose meaning must be inferred from the results.
Their current labels are identifiers, not interpretations; you may propose a meaningful name for each group.

# Overall Analytical Request

Based on the results shown here, describe what characterizes this group and what makes it distinctive.
...
Then, based on these characteristics, propose a meaningful name for this group.

# Local Task

Interpret ONLY the constructed group shown below.
Combine its facts to identify the strongest convergent semantic pattern.
Explain what this group seems to represent and propose one concise interpretive name.
Do not infer characteristics that are not listed below and do not compare it with unseen groups.

# Data

## Group "1"
```

This example demonstrates the latent naming permission mechanically. It does
not claim that this simple deterministic partition is equivalent to HCPC or to
any particular clustering algorithm; it is only a reproducible constructed
group for prompt inspection.

### 11.3 Scope variation

With `isolate.groups = FALSE`, the returned object is one combined
`# Local-first semantic interpretation plan` preview containing one local
prompt per category/group. With `isolate.groups = TRUE`, the returned object
is a named list of those local prompts. The generation architecture remains
local-first in both cases.

## 12. Invariance matrix

| Option | Changes canonical `statistical_profiles`? | Changes selected evidence? | Changes semantic rendering? | Changes prompt instructions? | Changes outer return shape? |
|---|---:|---:|---:|---:|---:|
| `interpretation_mode` | No | No | No factual change | Yes: standard/latent ontology, naming, no-renaming rules, defaults | No |
| `prompt_style` | No | No | No | Yes, only default `request` wording on modern path | No |
| `isolate.groups` | No | No | No factual change | Yes, plural/singular default request and combined-preview headings | Yes |
| `quali.sample` | No | Yes | Yes: selected/displayed qualitative facts | Indirectly, through data text | No |
| `quanti.sample` | No | Yes | Yes: selected/displayed quantitative facts | Indirectly, through data text | No |
| `drop.negative` | No | Yes | Yes: negative directions may be removed; binary completion changes accordingly | Indirectly, through data text | No |
| custom `introduction` | No | No | No | Yes: context only | No |
| custom `request` | No | No | No | Yes: replaces generated request | No |

This matrix is a code-level invariance statement, not a statistical claim
that all prompt changes have no effect on model responses.

The tests reinforce the main invariants: selection does not mutate canonical
profiles; local prompts contain only their own group's evidence; standard and
latent target status is preserved; and `isolate.groups = FALSE` remains
local-first while changing the outer presentation.

## 13. Comparison with QDA and TEXTUAL

| Block | Convergence | CATDES-specific rule that must remain | Candidate shared principle |
|---|---|---|---|
| `context` | All three methods accept study context distinct from evidence | Standard observed target versus latent constructed grouping | Context can give substantive meaning but is not statistical evidence |
| `reading` | All need method-specific instructions on how to read evidence | `MORE/LESS FREQUENT`, `HIGHER/LOWER`, binary completion, selected modalities | Reading semantics are method-specific, not interchangeable wording |
| `question` | All state an analytical objective | Category/group characterization, distinctiveness, expectedness/ambiguity, naming in latent mode | User request and method default request should remain inspectable |
| `interpretation` | All permit controlled movement beyond literal facts | Category names must remain in standard; latent labels may be replaced by interpretive names | Evidence-first means traceable synthesis, not literal paraphrase |
| `local_task` | QDA product binding and TEXTUAL group binding have close functional analogues | One CATDES category/group only; no unseen-group comparison; standard/latent target status | Scope binding, comparison boundary, and instruction binding are useful subfunctions |
| `evidence` | All expose a semantic-facing subset while retaining canonical evidence | CATDES relative group-vs-full-sample facts and binary contrast completion | Evidence projection must preserve method semantics and traceability |
| `output` | QDA and TEXTUAL have explicit downstream output concerns | CATDES currently has free-form responses and no parser contract | Output is analytically separate from evidence and should not be inferred from storage alone |

QDA and CATDES both use relative reference structures, but they are not
statistically equivalent. QDA `HIGHER`/`LOWER` describes an adjusted sensory
profile relative to an evaluated product set. CATDES
`overrepresented`/`underrepresented` describes a modality relative to the
full sample, while CATDES `higher`/`lower` describes a group mean relative to
the overall mean. The common architecture can share the idea of preserving
relative direction, but not the method-specific interpretation text.

TEXTUAL evidence consists of exact raw responses and text IDs. CATDES evidence
consists of mechanically derived statistical facts. The same `local_task`
subfunctions—scope, comparison boundary, and instruction binding—appear
relevant, but the comparison boundary has a CATDES-specific tension because
the default plural request can coexist with local-only evidence.

## 14. Assessment of hypotheses H1-H7

| Hypothesis | Status | Evidence and qualification |
|---|---|---|
| H1. Modern CATDES already has most of `context`, `reading`, `question`, `interpretation`, `local_task`, and `evidence`, but functions mix them | **confirmed** | `nail_catdes()` has all six functions as prompt content or pipeline stages; guide/request/task strings cross conceptual boundaries |
| H2. `output` is not an explicit analytical block in the modern path | **confirmed** | Local prompts end with `# Data` and group facts; raw responses are stored without a CATDES parser/response schema |
| H3. `.semantic_guide_nail_catdes()` mixes evidence reading with interpretation | **confirmed** | It combines direction semantics, binary/multilevel display rules, no-invention, higher-level synthesis, mode semantics, and local-fact scope |
| H4. `build_request_catdes()` mixes analytical question and interpretation rules | **confirmed** | It asks what to describe while also regulating synthesis, direct-fact status, naming, ambiguity, and expectedness |
| H5. `.local_task_nail_catdes()` is close to TEXTUAL task binding | **confirmed** | It binds one category/group, limits unseen comparisons, and adds standard/latent instruction binding; it also contains interpretation wording |
| H6. `isolate.groups = FALSE` may create plural-request versus local-evidence tension | **confirmed** | Plural/comparative default request is inserted into each local prompt, while local task forbids unseen-group comparison; actual calls remain local-first |
| H7. Standard and latent may not grant exactly the same higher-level interpretation permission | **partially confirmed** | Both allow convergent higher-level interpretation, but standard explicitly marks traceability and contextual-hypothesis status while latent has shorter guards and explicit naming permission |

## 15. Candidate CATDES block decomposition

This is a conceptual candidate only. No block object, renderer, API, or code
change is proposed in this pass.

| Block | Function | Current CATDES content that could belong here | Standard/latent specificity | Uncertainty |
|---|---|---|---|---|
| `context` | Situate the study | `introduction` and its defaults | Standard: explicit observed categorical variable; latent: similarity-based constructed grouping | Whether target-label context should be separate from general introduction |
| `reading` | Define evidence semantics | Direction words, binary contrast rule, multilevel rule, full-sample reference, displayed-fact status | Same mechanical rules, but labels/category-vs-group descriptions differ | Whether mode rule belongs here or in `local_task` |
| `question` | State what answer is sought | `build_request_catdes()`'s characterization/distinctiveness/ambiguity request | Standard: clarify named category; latent: infer profile and propose name | Comparative plural wording should probably be resolved here or by scope metadata |
| `interpretation` | Regulate interpretive lift and epistemic status | Higher-level synthesis, traceability, no invented facts, contextual hypothesis, direct-fact distinction | Standard: preserve category names; latent: allow naming and interpret constructed meaning | Latent mode needs an explicit decision on hypothesis/traceability wording |
| `local_task` | Bind one analytical object and scope | `.local_task_nail_catdes()`, group heading, no unseen-group comparison | Standard observed category/no renaming; latent constructed group/name proposal | Need to separate scope binding from interpretation sentences |
| `evidence` | Supply local statistical support | `semantic_facing_evidence$groups[[g]]$text` | Same renderer with mode-neutral facts; source is CATDES-specific | Binary added rows need clear “displayed but not selected” audit semantics |
| `output?` | Specify answer form or downstream contract | Currently absent; raw response stored in `semantic_profiles` | No current standard/latent distinction beyond naming instruction | Whether CATDES should remain free-form or acquire a minimal response contract |

The most conservative next design would keep the evidence pipeline unchanged
and expose only a CATDES-specific conceptual representation for inspection.
The `output` question should remain open until the need for response
comparability or parsing is demonstrated.

## 16. Risks of premature refactoring

1. Moving wording without preserving standard/latent asymmetry could allow a
   standard category to be renamed or prevent a latent group from receiving a
   meaningful name.
2. Treating `semantic_facing_evidence` as interchangeable with
   `interpretation_evidence` could lose the binary contrast rule or expose the
   wrong selected/displayed distinction.
3. Making `isolate.groups` a purely presentational option without resolving
   the plural request would preserve the current scope inconsistency under a
   new abstraction.
4. Copying QDA's reusable output block or TEXTUAL's parser contract into CATDES
   would introduce an unrequested response schema and could change the free-
   form semantic stage.
5. Refactoring the legacy `get_prompt_catdes()` path together with the modern
   path would conflate compatibility behavior and current evidence-first
   behavior.
6. Generalizing a renderer before testing CATDES-specific binary/multilevel
   semantics could make the architecture look uniform while silently changing
   what the LLM sees.

## 17. Questions to answer experimentally

Priority is given to experiments that resolve architectural uncertainty rather
than to a broad factorial campaign.

1. **Scope calibration:** with identical local evidence, compare singular/local
   request wording with the current plural request under
   `isolate.groups = FALSE`. Does the plural request cause cross-group claims
   or merely redundant wording?
2. **Mode calibration:** compare standard and latent prompts with matched
   evidence and context to test whether the shorter latent guard produces more
   unsupported naming or whether the explicit naming permission is sufficient.
3. **Evidence rendering:** with the same profiles, compare selected-only
   binary evidence versus completed binary contrast, and with/without
   percentages, while assessing factual direction, synthesis, and
   interpretive calibration separately.

An output-contract experiment should follow only if there is a concrete need
for CATDES response comparability or downstream parsing; it should not be
introduced merely to make CATDES look like QDA or TEXTUAL.

## 18. Recommended next PASS

The next pass should remain observational or experimental before any package
refactor:

1. freeze the current standard and latent `generate = FALSE` prompts and their
   canonical evidence artifacts;
2. run a small, blinded scope comparison focused on the plural-request/local-
   task tension;
3. decide whether a CATDES-specific block representation is needed for audit,
   without adding a package-wide renderer or `default_blocks` API.

The statistical method determines the semantics of the evidence; the prompt
architecture determines how the language model is allowed to reason from that
evidence. In this audit that remains a working principle, not a direct
experimental result:

```text
statistical method
    -> produces and defines the evidence

prompt architecture
    -> organizes reasoning from that evidence

LLM
    -> produces the substantive interpretation
```
