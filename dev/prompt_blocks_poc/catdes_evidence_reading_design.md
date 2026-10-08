# CATDES evidence-reading design

This document is a design audit, not a package change. It proposes a future
separation between CATDES reading, interpretation, and local task blocks.
No R source, test, man, namespace, description, or existing development
document was modified for this pass. No LLM was called.

## 1. Scope and source of truth

The source of truth is the working tree of NaileR on:

~~~
branch: dev-catdes-prompt-audit
HEAD:   c06d1d81106241aaa54540a6784a8d301f69588e
~~~

The active implementation was inspected in:

~~~
R/nail_catdes.R
R/nail_catdes_prep.R
tests/testthat/test-catdes-stage2.R
tests/testthat/test-catdes-stage3.R
~~~

The historical implementation was inspected through Git history, including
the pre-refactor implementation at 8ee4473 (Avant Refonte). Existing audit
documents were consulted but deliberately left unchanged:

~~~
dev/prompt_blocks_poc/catdes_prompt_audit.md
dev/prompt_blocks_poc/PROMPT_ANALYSIS_FINDINGS.md
dev/prompt_blocks_poc/EXPERIMENTS_INDEX.md
~~~

The current working-tree modifications and untracked experimental artifacts
were pre-existing and were preserved.

## 2. Historical CATDES reading review

### 2.1 Historical rules and modern status

| Historical rule or field | Current equivalent | Still relevant? | Visible to LLM? | Candidate destination |
|---|---|---:|---:|---|
| Cla/Mod | percentage_in_modality | Yes for audit and denominator clarity | Not necessarily | Canonical evidence / optional descriptive reading |
| Mod/Cla | percentage_in_group | Yes for the group/global contrast | Yes in a value-bearing representation, with a definition | Semantic-facing evidence |
| Global | global_percentage | Yes as the full-sample reference | Yes in a value-bearing representation | Semantic-facing evidence |
| Mean in category | group_mean | Yes | Yes, provisionally | Semantic-facing evidence |
| Overall mean | overall_mean | Yes | Yes, provisionally | Semantic-facing evidence |
| sd in category, Overall sd | standard deviations in canonical profiles | Sometimes | No by default | Canonical evidence; future dispersion view |
| Positive/negative v.test explains direction | R derives direction and renders MORE/LESS FREQUENT or HIGHER/LOWER | Yes upstream | Raw sign no longer needs to be shown | Statistical preparation plus reading |
| Smaller p.value and larger abs(v.test) mean stronger evidence | rank, p_value, abs_v_test, selection logic | Yes for selection/audit | Not by default | Canonical evidence / selection |
| Larger p.value or smaller abs(v.test) mean weaker evidence | No current semantic equivalent | Relevant only in a strength task | Not currently | Future interpretation design |
| Full table-column glossary | Plain-language factual projection | Partly | No if the projection defines its words | Historical compatibility guide |
| Category/group description and naming rules | Current guide, request, local task | Yes, but not evidence semantics | No in pure reading | Interpretation and/or local task |

The historical guide was useful because it made source tables legible: it
defined denominators, the reference population, direction, and the distinction
between qualitative and quantitative markers. In the modern path the LLM does
not receive those tables. A modern reading should therefore explain the
semantics of the plain-language facts, rather than reproduce a table glossary
for hidden fields.

The old get_prompt_catdes path and table helpers remain historical or
compatibility material. The active path builds statistical_profiles, selects
interpretation_evidence, projects it into semantic_facing_evidence, and
renders local prompts with .build_local_semantic_prompts_nail_catdes().

## 3. Current LLM-facing evidence semantics

The modern pipeline has four levels:

~~~
statistical_profiles
    complete canonical statistical artifact

interpretation_evidence
    deterministic selected subset controlled by quali.sample,
    quanti.sample, and drop.negative

semantic_facing_evidence
    plain-language projection for interpretation

local prompt
    context + guide + request + local task + one group's factual statements
~~~

The canonical profiles are not changed when prompt selection changes.
nail_evidence() returns the canonical statistical artifact. The prompt-facing
projection is a later representation.

### 3.1 Qualitative facts

For a selected qualitative marker, the active code renders:

~~~
The response/modality "<modality>" for variable/proposition "<variable>"
is MORE FREQUENT or LESS FREQUENT in this group than in the full sample
(group=<percentage_in_group>; full sample=<global_percentage>).
~~~

The direction is mechanical:

~~~
overrepresented  -> MORE FREQUENT
underrepresented -> LESS FREQUENT
~~~

The current semantic line exposes percentage_in_group and global_percentage.
It does not expose percentage_in_modality, p_value, v_test, or evidence_id.
The canonical qualitative row also retains observed, expected,
direction_basis, abs_v_test, rank, source_row, and source.

The phrase “in this group than in the full sample” is a relative comparison;
it is not a statement that a modality is intrinsically present or absent.
An unshown modality is not thereby absent, average, rejected, or irrelevant.

### 3.2 Quantitative facts

For a selected quantitative marker, the active code renders:

~~~
The mean of "<variable>" is HIGHER or LOWER in this group than in the full
sample (group mean=<group_mean>; full-sample mean=<overall_mean>).
~~~

The direction is mechanical:

~~~
higher -> HIGHER
lower  -> LOWER
~~~

The current semantic line exposes group_mean and overall_mean. It does not
expose standard deviations, p_value, v_test, evidence_id, rank, or the
direction fallback used during canonical preparation. Means are descriptive
contrasts on one variable scale; they are not a cross-variable measure of
evidence strength or importance.

### 3.3 Evidence selection and binary completion

interpretation_evidence selects markers by deterministic rank and the requested
sampling proportions. With drop.negative = TRUE, negative directions are
excluded from the selected prompt subset. The canonical profiles remain
unchanged.

For a selected binary qualitative variable, the semantic-facing layer can
display both significant sides of the contrast. The extra displayed row is
traceable in the semantic-facing object through display_origin and
representation_block; that plumbing is not shown to the LLM. For a
multi-level qualitative variable, only selected modalities are displayed.

A minimal user-facing rule is:

> For a binary qualitative variable, two displayed modalities may represent
> the complementary sides of one statistical contrast and should be read
> together. For a multi-level qualitative variable, interpret only the
> modalities displayed below; an undisplayed modality is not evidence of
> absence, average status, or rejection.

This describes the semantic consequence without exposing sampling quotas or
internal completion mechanics.

## 4. Field-by-field evidence classification

The following classification uses:

~~~
A = establishes retention or statistical significance
B = establishes direction
C = describes substantive magnitude or descriptive contrast
D = traceability and audit
~~~

### 4.1 Qualitative evidence

| Field | Role | Needed by R? | Needed by LLM? | Useful to LLM? | Risk if exposed without framing |
|---|---|---:|---:|---:|---|
| v_test | A + B | Yes | No | Sometimes for explicit strength comparison | Statistical strength becomes substantive importance or intensity |
| p_value | A | Yes | No | Usually no | Confusion with probability of a characteristic or practical importance |
| percentage_in_group | C | Yes | Not strictly | Yes, within-group prevalence | Denominator misunderstanding |
| percentage_in_modality | C / audit | Yes | No by default | Potentially for a future concentration question | Denominator confusion with within-group prevalence |
| global_percentage | C | Yes | Not strictly | Yes, as full-sample reference | Mistaken for evidence strength |
| direction | B | Yes | Yes | Essential; R has resolved relative direction | Polarity reversal |
| rank / abs_v_test | A / D | Yes | No | Not reliably as a substantive hierarchy | Mechanical primary/secondary labels distort interpretation |
| evidence_id | D | Yes | No | No | Technical noise |
| observed / expected | A / audit | Yes where available | No | Not for the current statement | Recalculation and denominator confusion |

The provisional conclusion is to retain direction and group/global percentages
in the semantic representation, while keeping v_test, p_value, IDs, and rank
in the canonical/audit layer. Percentages are descriptive, not significance
or evidence-strength measures.

### 4.2 Quantitative evidence

| Field | Role | Needed by R? | Needed by LLM? | Useful to LLM? | Risk if exposed without framing |
|---|---|---:|---:|---:|---|
| v_test | A + B | Yes | No | Sometimes for explicit strength comparison | False substantive hierarchy or confusion with mean magnitude |
| p_value | A | Yes | No | Usually no | Confusion with certainty or practical importance |
| group_mean | C | Yes | Not strictly | Yes, to make the contrast concrete | Cross-variable scale comparison |
| overall_mean | C | Yes | Not strictly | Yes, as same-variable reference | Cross-variable scale comparison |
| standard_deviation | C / audit | Yes | No by default | Only in a dispersion task | Distracts from mean contrast |
| overall_standard_deviation | C / audit | Yes | No by default | Only in a dispersion task | Same risk |
| direction | B | Yes | Yes | Essential; HIGHER and LOWER are relative | Polarity reversal |
| rank / abs_v_test | A / D | Yes | No | Not safely as generic hierarchy | Statistical strength becomes substantive centrality |
| evidence_id | D | Yes | No | No | Technical noise |

Means should provisionally remain visible because they provide descriptive
contrast that is different from statistical evidence strength. They should be
accompanied by a rule: compare a group mean only with the full-sample mean for
the same variable, and do not treat the numerical difference as a common-scale
importance score across variables.

This is not a decision to expose more raw statistics. It preserves current
descriptive values while keeping complete numerical evidence separately.

## 5. Qualitative evidence analysis

The qualitative semantic fact has three layers:

~~~
statistical selection
    -> marker passed the deterministic CATDES selection rule

relative factual meaning
    -> modality is MORE or LESS FREQUENT in the group than globally

substantive interpretation
    -> several relative facts may be synthesized into a defensible pattern
~~~

The LLM should not rediscover direction from v_test. R has already done that.
Conversely, the LLM may interpret what a coherent set of relative frequency
facts means, provided it does not turn a synthesis into a directly observed
fact.

The percentages are useful because they show the descriptive contrast omitted
by words alone. They are not substitutes for p_value or v_test. The reading
must prevent:

~~~
rarely selected in the group -> absent from the group
not overrepresented       -> average or rejected
large percentage contrast -> statistically stronger by itself
one modality displayed    -> other modalities absent
~~~

## 6. Quantitative evidence analysis

The quantitative semantic fact is a same-variable comparison against the full
sample. Current values support interpretation of coherent higher/lower patterns
and can therefore have substantive value.

The following distinctions must remain explicit:

~~~
group mean vs overall mean
    descriptive magnitude on one variable

v.test / p.value
    statistical characterization and retention evidence

interpretive synthesis
    model-based meaning assigned to a convergent pattern
~~~

The reading should not encourage “the largest mean is the most important
characteristic” or “the biggest mean difference is the strongest evidence”.
Variables may use different units and scales. Statistical strength is not the
same as substantive importance.

Standard deviations remain valuable in the canonical artifact and may be
needed for a dispersion task. They are not required in the current
mean-contrast fact.

## 7. Binary/multilevel contrast analysis

The current implementation distinguishes:

~~~
binary qualitative variable
    a selected variable may be shown as a complete significant contrast

multi-level qualitative variable
    only selected modalities are shown
~~~

A binary contrast can be read as two complementary sides of one variable,
while a multi-level variable may have unshown levels whose status is not
established by the prompt.

The minimum rule needed to prevent the main failure is:

> Read the displayed modalities as the reported statistical contrast for this
> group. Do not infer that an undisplayed modality is absent, average,
> rejected, or non-existent.

A more precise future reading is:

> For a binary qualitative variable, two displayed modalities may be
> complementary sides of the same significant contrast and should be
> interpreted together. For a multi-level qualitative variable, only the
> displayed modalities are supported by the evidence shown here; do not infer
> the status of unshown modalities.

This avoids exposing completed_binary_contrast, selection quotas, or
drop.negative plumbing. It remains valid when both binary sides were selected
normally and when one side was added to complete a displayed contrast.

## 8. Standard versus latent reading

The evidence mechanics are the same in both modes:

~~~
reference: full sample
qualitative direction: MORE / LESS FREQUENT
quantitative direction: HIGHER / LOWER
binary and multilevel display rules
group-local scope
~~~

What changes is the epistemic status of the target label and the permissible
interpretation:

| Mode | Target label | Interpretation consequence |
|---|---|---|
| Standard | observed category of a named categorical variable | Preserve the observed category name; do not replace it with a latent-profile name |
| Latent | constructed group/profile identifier | Treat the label as an identifier; infer substantive meaning and propose an interpretive name |

This supports a shared mechanical core reading in a future design. Mode-specific
sentences should move to interpretation and/or local_task:

~~~
standard -> preserve observed category name; do not rename
latent   -> labels are identifiers; interpret and propose a meaningful name
~~~

The shared reading must not claim identical ontology. It should say that the
facts have the same mechanical semantics while target-label interpretation
differs.

## 9. Current semantic-guide decomposition

.semantic_guide_nail_catdes() currently mixes several conceptual layers.
The following decomposition is proposed without changing implementation.

| Current sentence or rule | Future destination | Reason |
|---|---|---|
| R has already performed the statistical analysis | reading | The model is not the statistical engine |
| Every Data line is mechanically derived from selected significant markers | reading | Defines displayed evidence status |
| MORE/LESS FREQUENT and HIGHER/LOWER must be read literally | reading | Defines direction semantics |
| Binary variables may display both significant sides | reading | Defines displayed contrast |
| Multi-level variables show only selected modalities | reading | Defines qualitative evidence scope |
| Facts listed under this group belong ONLY to this group | local_task / scope | Binds evidence to the local object |
| Do not invent a new empirical characteristic | interpretation | Fact versus interpretation |
| Higher-level interpretation is encouraged when traceable | interpretation | Permissible interpretive lift |
| Broader contextual hypothesis must be marked | interpretation | Epistemic status |
| Combine convergent facts rather than paraphrase every line | interpretation | Synthesis |
| Observed category names must be preserved | standard local_task / ontology | Protects observed label without suppressing interpretation |
| Categories must not be treated as latent profiles | standard ontology / local_task | Mode-specific semantics |
| Constructed labels are identifiers and may receive names | latent local_task / ontology | Enables latent interpretation |
| Interpret ONLY this group/category | local_task | Generation scope |
| Do not compare unseen groups/categories | local_task | Prevents unsupported comparisons |

The reading block should not contain naming, no-renaming, contextual-hypothesis,
or higher-level synthesis rules, except for a minimal cross-reference needed to
avoid a category error. Those are interpretation or scope rules.

## 10. Candidate reading R1 — Minimal semantic

### Exact candidate text

~~~text
R has already performed the statistical analysis. Read each statement below as a factual comparison between this group and the full sample. MORE FREQUENT and LESS FREQUENT describe relative modality prevalence; HIGHER and LOWER describe the group mean relative to the full-sample mean for the same variable. An undisplayed modality or variable is not thereby absent, average, rejected, or unimportant.
~~~

Advantages:

- shortest default and easiest to inspect or edit;
- explicit full-sample reference and relative semantics;
- protects against “unshown means absent”;
- leaves interpretive lift to a separate interpretation block.

Risks:

- assumes binary contrasts will be explained elsewhere when needed;
- does not define the descriptive percentages and means;
- gives less help to users unfamiliar with CATDES.

R1 is the best candidate for a reduced prompt, but may be too short as the
ordinary default for mixed CATDES evidence.

## 11. Candidate reading R2 — Semantic + descriptive values

### Exact candidate text

~~~text
R has already performed the statistical analysis. Read each statement below as a factual comparison between this group and the full sample. MORE FREQUENT and LESS FREQUENT describe relative modality prevalence; HIGHER and LOWER describe the group mean relative to the full-sample mean for the same variable. When percentages are shown, the group percentage describes the modality within this group and the full-sample percentage describes the same modality in the full sample; these are descriptive values, not p-values or measures of statistical strength. When means are shown, compare the group mean only with the full-sample mean for that same variable; do not compare mean values across variables as if they shared one scale. An undisplayed modality or variable is not thereby absent, average, rejected, or unimportant.
~~~

Advantages:

- preserves current percentages and means while defining their status;
- separates descriptive magnitude from significance and strength;
- supports substantive interpretation of coherent patterns;
- avoids exposing raw p_value and v_test.

Risks:

- longer than R1;
- numeric values may still attract undue attention;
- does not explicitly explain binary or multi-level display.

R2 is the most direct candidate if descriptive values remain visible.

## 12. Candidate reading R3 — Contrast-aware

### Exact candidate text

~~~text
R has already performed the statistical analysis. Read each statement below as a factual comparison between this group and the full sample. MORE FREQUENT and LESS FREQUENT describe relative modality prevalence; HIGHER and LOWER describe the group mean relative to the full-sample mean for the same variable. When percentages are shown, the group percentage describes the modality within this group and the full-sample percentage describes the same modality in the full sample; these are descriptive values, not p-values or measures of statistical strength. When means are shown, compare the group mean only with the full-sample mean for that same variable; do not compare mean values across variables as if they shared one scale. For a binary qualitative variable, two displayed modalities may be complementary sides of the same significant contrast and should be interpreted together. For a multi-level qualitative variable, interpret only the modalities displayed below; do not infer the status of unshown modalities. An undisplayed modality or variable is not thereby absent, average, rejected, or unimportant.
~~~

Advantages:

- includes the minimum binary/multi-level guard;
- preserves the descriptive safeguards of R2;
- avoids exposing selection quotas and internal flags;
- directly addresses the undisplayed-modality failure.

Risks:

- longest candidate;
- “significant contrast” must remain accurate under future selection policies;
- it still does not communicate a graded strength measure.

R3 is the strongest full default candidate for mixed binary, multi-level, and
quantitative descriptors. R1 remains a reasonable reduced prompt and R2
isolates the value of descriptive numbers.

## 13. Evidence representation candidates

| Candidate | Direction words | Percentages | Means | Raw p_value / v_test | Contrast rule |
|---|---:|---:|---:|---:|---:|
| Current semantic + descriptive | Yes | Yes | Yes | No | Partly in guide, not pure reading |
| R1 | Yes | Allowed, not explained | Allowed, not explained | No | Minimal undisplayed guard |
| R2 | Yes | Yes, defined | Yes, defined | No | Minimal undisplayed guard |
| R3 | Yes | Yes, defined | Yes, defined | No | Binary and multi-level rule |

No representation is proposed as universally optimal. QDA experiments show
that semantic simplification can help, but do not justify removing all
numerical values or mechanically assigning primary/secondary labels. CATDES
should retain canonical numerical evidence and test the projection empirically.

### Does CATDES need evidence strength in the prompt?

The statistical pipeline needs evidence strength to select and rank markers. The
LLM does not necessarily need raw strength numbers to read a factual statement.
A future task asking which results are more statistically strongly characterized
could require a separate representation, but that is not solved automatically
by showing p_value or v_test.

Rank can preserve deterministic ordering and auditability, but should not be
presented as substantive importance or a universal primary/secondary hierarchy.
The QDA experiments showed that such a hierarchy can distort interpretation.
Percentages and means must not substitute for statistical strength.

Provisional position:

~~~
canonical profiles: retain p_value, v_test, abs_v_test, rank
semantic prompt: retain direction and descriptive values
reading: explain descriptive values and their limits
future strength experiment: separate, not assumed here
~~~

## 14. Mechanical examples

All examples below use generate = FALSE. They inspect R-produced objects and
prompts only; no backend was contacted.

### Example 1 — standard observed category with quantitative evidence

~~~r
devtools::load_all(quiet = TRUE)
data(iris)

standard <- nail_catdes(
  dataset = iris,
  num.var = 5,
  interpretation_mode = "standard",
  isolate.groups = TRUE,
  quali.sample = 1,
  quanti.sample = 1,
  generate = FALSE
)

profiles <- nail_evidence(standard, print = FALSE)
selected <- attr(standard, "interpretation_evidence")
semantic <- attr(standard, "semantic_facing_evidence")
prompt <- nail_prompt(standard, select = "setosa", print = FALSE)
~~~

Observed result for setosa:

~~~text
canonical registry: 9 rows
selected evidence:
  setosa::quanti::Petal.Length
  setosa::quanti::Petal.Width
  setosa::quanti::Sepal.Length
  setosa::quanti::Sepal.Width
semantic projection:
  Petal Length  LOWER  1.46 vs 3.76
  Petal Width   LOWER  0.25 vs 1.20
  Sepal Length  LOWER  5.01 vs 5.84
  Sepal Width   HIGHER 3.43 vs 3.06
~~~

This standard example has no selected qualitative marker at the default
threshold, but it demonstrates the quantitative side of the common reading.

~~~text
R1: applicable
R2: applicable and informative because means are visible
R3: applicable; its contrast sentence is inert here
~~~

### Example 2 — reproducible constructed group with both evidence types

The following creates a constructed grouping only for mechanical prompt
inspection. The grouping is obtained by kmeans; CATDES characterizes the
resulting groups. This does not establish a substantive latent interpretation.

~~~r
data(iris)
set.seed(42)
km <- stats::kmeans(
  scale(iris[, 1:4]),
  centers = 2,
  nstart = 20
)
latent_data <- transform(
  iris,
  ConstructedGroup = factor(km$cluster)
)

latent <- nail_catdes(
  dataset = latent_data,
  num.var = 6,
  interpretation_mode = "latent",
  isolate.groups = TRUE,
  quali.sample = 1,
  quanti.sample = 1,
  generate = FALSE
)

latent_profiles <- nail_evidence(latent, print = FALSE)
latent_selected <- attr(latent, "interpretation_evidence")
latent_semantic <- attr(latent, "semantic_facing_evidence")
latent_prompt <- nail_prompt(latent, select = "1", print = FALSE)
~~~

Observed result for group 1:

~~~text
canonical registry: 14 rows
selected evidence:
  1::quali::Species::setosa
  1::quali::Species::versicolor
  1::quali::Species::virginica
  1::quanti::Petal.Length
  1::quanti::Petal.Width
  1::quanti::Sepal.Length
  1::quanti::Sepal.Width
semantic projection:
  Species setosa      MORE FREQUENT
  Species versicolor  LESS FREQUENT
  Species virginica   LESS FREQUENT
  Petal Length        LOWER  1.46 vs 3.76
  Petal Width         LOWER  0.25 vs 1.20
  Sepal Length        LOWER  5.01 vs 5.84
  Sepal Width         HIGHER 3.43 vs 3.06
~~~

Both evidence types are present. The label 1 is an identifier in latent mode;
future interpretation/local-task blocks may allow a meaningful name. The
mechanical reading of each fact is the same as in standard mode.

~~~text
R1: applicable
R2: applicable and informative
R3: applicable; multi-level Species makes its selected-modality guard useful
~~~

### Example 3 — binary qualitative contrast

This example creates a binary descriptor and binary target from iris. A small
qualitative sampling proportion selects one side of the binary descriptor,
allowing the semantic-facing layer to complete the displayed contrast when
negative directions are retained.

~~~r
data(iris)
binary_data <- transform(
  iris,
  BinaryProfile = factor(ifelse(Petal.Length < 2, "small", "not_small")),
  Group = factor(ifelse(Species == "setosa", "A", "B"))
)

binary_full_contrast <- nail_catdes(
  dataset = binary_data,
  num.var = 7,
  isolate.groups = TRUE,
  quali.sample = 0.2,
  quanti.sample = 0,
  drop.negative = FALSE,
  generate = FALSE
)

binary_positive_only <- nail_catdes(
  dataset = binary_data,
  num.var = 7,
  isolate.groups = TRUE,
  quali.sample = 0.2,
  quanti.sample = 0,
  drop.negative = TRUE,
  generate = FALSE
)
~~~

For group A:

~~~text
drop.negative = FALSE
  selected: A::quali::BinaryProfile::not_small
  displayed: not_small LESS FREQUENT; small MORE FREQUENT
  representation_block: binary_complete_contrast
  completed rows: 1

drop.negative = TRUE
  selected/displayed: small MORE FREQUENT
  representation_block: binary_complete_contrast
  completed rows: 0
~~~

The canonical evidence is not changed. Only selection and semantic-facing
display differ. R3 explicitly explains the two-sided binary display; R1 and R2
need the local task or interpretation block to supply that explanation.

## 15. What should remain hidden from the LLM

Unless a future explicit experiment justifies a carefully defined projection,
keep these in the canonical/audit layer:

- raw p_value and v_test;
- abs_v_test, rank, and evidence IDs;
- observed and expected counts;
- direction_basis and fallback mechanics;
- source_row and source provenance;
- display_origin and representation_block flags;
- sampling quotas and selected/excluded registries;
- drop.negative plumbing;
- the fact that a row was completed internally;
- the complete statistical registry when the prompt is local to one group.

These fields are not unimportant; their audit role is different from the
semantic role of plain-language evidence.

## 16. Editable-reading implications

Future CATDES reading should satisfy both:

~~~
good default for ordinary users
safe and understandable object for expert customization
~~~

Working doctrine:

> reading should be treated as a method-provided default convention for
> reading the evidence, but it should ultimately be inspectable and editable
> by the user.

A future reading should use visible concepts and stable denominators, not
hidden implementation facts. “The group percentage is the modality prevalence
within this group” is editable and understandable. Internal completion after a
quota filter is not a useful ordinary semantic convention.

The reading remains method-specific. QDA HIGHER/LOWER concerns relative sensory
means; CATDES responses and descriptors are not the same evidence ontology.
A shared conceptual grammar may be useful, but a universal wording renderer is
not justified yet.

The LLM interpretation remains a prediction conditional on evidence, prompt,
model, and generation settings. The aim is methodological correctness,
traceability, inspectability, and reasonable interpretive guidance, not
deterministic error-free output.

isolate.groups is not a reading problem. Its plural request can coexist with a
local single-group prompt. A future scope design should resolve that through
question, local_task, or generation scope; reading should not be used to repair
it.

## 17. Smallest useful next experiment

The smallest discriminating benchmark should compare only the LLM-facing
reading/evidence representation:

~~~text
A = current semantic + descriptive values
B = semantic minimal (R1)
C = compact descriptive contrast (R2)
~~~

Hold constant:

~~~text
same canonical statistical_profiles
same selected evidence IDs
same semantic-facing rows and group
same introduction/context
same request/question
same interpretation rules
same local task and mode
same provider, model, generation options, and repetitions
sample proportions = 1 where evidence density requires it
~~~

Use at least the three mechanical situations above: a quantitative profile, a
constructed group with qualitative and quantitative evidence, and a binary
contrast. Add R3 only if the binary case shows that its contrast sentence
cannot be evaluated through local task alone.

Do not execute this benchmark here. Review interpretive lift, evidence fidelity,
calibration, unsupported overreach, and transformations of relative facts into
absolute claims. No composite winner should be inferred from one small model
comparison.

## 18. Open questions

1. Should a future semantic representation expose a qualitative contrast value
   without exposing the unused percentage_in_modality denominator?
2. Should CATDES expose a model-readable notion of statistical strength, and if
   so, can it avoid a false primary/secondary substantive hierarchy?
3. Should standard and latent share one exact reading string, or only one
   method-specific core with mode-specific ontology outside it?
4. Should a dispersion-focused request expose standard deviations, or remain an
   explicit alternative evidence view?
5. How should a future output block be represented for CATDES, given that the
   current function stores free-form responses and has no parser contract?
6. How should local singular task interact with plural comparative wording when
   isolate.groups = FALSE?
7. Can the binary-completion sentence remain valid under every future evidence
   selection policy, including policies that retain only positive directions?
8. What is the minimum reading length that preserves understanding of percentages
   and means without reducing interpretive lift?

The current recommendation is not to refactor yet. First choose the smallest
benchmark representation and test whether R2 or R3 improves traceability and
relative-fact fidelity without suppressing defensible higher-level synthesis.
