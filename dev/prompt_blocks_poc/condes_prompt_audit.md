# `nail_condes()` prompt and evidence audit

Audit baseline:

```text
branch: dev-condes-prompt-audit
HEAD:   2735270200e71f3885aa7191261506e12cf771ff
```

This PASS is descriptive only. No R file, test, user documentation, branch,
commit, or statistical implementation was modified.

## 1. Executive conclusion

`nail_condes()` has a defensible evidence-first architecture. It performs one
`FactoMineR::condes()` analysis on an augmented data set, stores the R-derived
material in a canonical `continuous_profile`, selects a deterministic subset,
translates it into explicit semantic-facing facts, and exposes the exact
prompt and response through public accessors.

The canonical object is sufficiently complete and stable for audit. The main
caution is the coexistence of complementary and partly redundant views:
quantitative associations, global qualitative associations, and category/state
end profiles. End profiles are not independent measurements of a new endpoint.

The principal prompt ambiguity is the word `strongest`: it can refer to
statistical evidence strength, association magnitude, or interpretive
centrality. These are not equivalent. This should be clarified in a later
wording-only pass; no wording is changed here.

```text
KEEP AS IS: canonical computation, continuous_profile, evidence access,
            standard/latent separation.
CHANGE LATER: distinguish statistical strength from interpretive centrality.
POSTPONE: numerical suppression, public block APIs, broad benchmarking.
```

NaileR does not need a perfect LLM answer. It needs a statistically defensible
and inspectable chain from evidence to prompt to prediction.

## 2. Historical contract

The older implementation used `FactoMineR::condes()` output directly in
prompt-oriented tables, with discretization helpers and sampled textual
descriptions. The `V2`/`Nantes` lineage retained that classical approach.

Commit `f84bf6b` (`Rebuild condes around canonical continuous evidence`)
introduced the current evidence-first reconstruction: `continuous_profile`,
deterministic interpretation evidence, semantic-facing evidence, and the
single-analysis contract. Later prompt work, including `33ba78e`, changed
interpretive wording without replacing the canonical statistical object.

The history informs compatibility but is not a reason to restore the former
prompt construction.

## 3. Statistical semantics of `FactoMineR::condes()`

The installed `FactoMineR:::condes` implementation was inspected directly.
It receives a data frame, a numeric target column, optional weights, and
`proba`.

### Quantitative predictors

For each quantitative predictor, `condes()` computes a weighted Pearson
correlation using `cov.wt(..., cor = TRUE)` when weights are supplied. The
two-sided p-value uses the usual correlation t statistic with `n - 2` degrees
of freedom. Predictors with `p.value <= proba` are retained in `$quanti`.

- correlation sign: direction of linear association;
- absolute correlation: descriptive linear-association magnitude;
- p-value: inferential evidence against zero correlation;
- neither statistic establishes causality or substantive importance.

NaileR reorders retained rows deterministically by p-value, absolute
correlation, and variable name before assigning ranks.

### Qualitative predictors

For each factor, `condes()` fits a weighted one-way ANOVA. The global statistic
is an R2-like explained-variation ratio and the global p-value is an F-test.
`$quali` retains factors passing `proba`.

For modalities, sum-contrast coefficients are computed and completed so their
effects sum to zero. A modality `Estimate` is therefore a signed model
effect/deviation relative to the grand-mean coding, not a probability and not
a direct endpoint measurement. Its p-value is a modality-level association
test.

The global factor test and modality tests are computed in the same pass, but
modality rows are not strictly gated by the global p-value before being
returned. They are separate evidence paths.

Positive/negative directions are statistical directions. They are not
automatically favorable/unfavorable judgments, causal mechanisms, practical
importance, or substantive target labels.

## 4. Current NaileR pipeline

```text
dataset
  -> .build_condes_augmented_data()
  -> one FactoMineR::condes() call
  -> .build_continuous_profile_condes()
  -> .build_interpretation_evidence_condes()
  -> .build_semantic_facing_evidence_condes()
  -> build_guide_condes() + build_request_condes()
  -> build_standard_prompt()
  -> optional LLM call
```

Preparation preserves original numeric predictors and adds technical factor
states. The one `condes()` result is projected into the canonical profile,
then selected and converted to semantic-facing prose. `condes_result` is the
original single FactoMineR result; `condes_profile_result` is a compatibility
alias to the same object.

The code contains one `FactoMineR::condes()` call per analysis. Generation,
interpretation mode, prompt style, sampling, labels, context, request, and
conclusion occur after that calculation.

## 5. Canonical `continuous_profile`

The object has class `nail_condes_continuous_profile` and contains:

```text
target
quantitative_associations
qualitative_associations
end_profiles$low
end_profiles$high
evidence_registry
metrics
settings
metadata
```

The association tables preserve source variables, statistics, p-values,
directions where applicable, and deterministic evidence IDs/ranks. The
registry normalizes the families into a common audit table.

The profile is invariant to:

```text
generate, interpretation_mode, prompt_style, sample.pct, sample.method,
target_label, target_concept, introduction, request, conclusion
```

This follows from code placement and existing invariance tests. It is not
invariant to data, target index, `proba`, weights, `quanti.threshold`, or
`quanti.cat`, which legitimately affect the statistics.

## 6. Interpretation evidence selection

Selection is performed independently for quantitative associations, qualitative
associations, low-end profiles, and high-end profiles. With `sample.pct = 1`,
all rows are retained. With smaller values, `top` keeps the first ranked rows
and `stratified` keeps an anchor plus deterministic exploration. Quantitative
selection can preserve both directions. Selection changes
`interpretation_evidence`, not the canonical profile.

## 7. Semantic-facing evidence

| Family | Visible to LLM | Hidden from LLM |
|---|---|---|
| Quantitative | variable, `POSITIVELY`/`NEGATIVELY`, correlation, p-value | evidence ID, rank, absolute-correlation field |
| Qualitative | variable, R2, p-value | evidence ID, rank, raw table |
| Lower/higher end | variable/category, `LOWER`/`HIGHER`, Estimate, p-value | evidence ID, rank, absolute-Estimate field |

The semantic-facing text is explicit factual prose. It hides IDs and ranks but
deliberately retains numerical values.

## 8. Quantitative associations

The representation is appropriate for signed linear direction. `correlation`
should remain visible. Its absolute value gives a cautious descriptive
association magnitude, subject to linearity, outliers, and sample context.
`p.value` can remain visible as inferential evidence strength, provided it is
not presented as substantive importance.

It is defensible to discuss statistically stronger retained results when
p-values are shown. It is not defensible to treat that ordering as a complete
measure of interpretive centrality: a very small p-value can coexist with a
modest association in a large sample.

## 9. Qualitative associations

The global qualitative result is an ANOVA-style association. R2 represents
explained target variation under the factor model; it has no direction by
itself. The global p-value represents inferential evidence for a non-zero
overall factor effect.

Directional modality information appears in end-profile rows through signed
`Estimate`. The current semantic-facing representation is statistically
readable, although the relationship between global R2, modality effects, and
end profiles could be explained more explicitly in a future reading pass.

## 10. End profiles

End profiles are constructed by NaileR, not directly returned as endpoint
objects by `condes()`. For every original numeric predictor, NaileR preserves
the numeric column and adds a technical factor:

```text
z >=  quanti.threshold  -> Above-average value
z <= -quanti.threshold  -> Below-average value
otherwise               -> Intermediate value
```

The same single `condes()` call analyzes the original continuous predictors
and these state factors. NaileR maps negative modality estimates to `low` and
positive estimates to `high`, while preserving original qualitative
categories.

End profiles add an interpretable state/category view of the two ends. They
are complementary but partly redundant with quantitative correlations and are
not independent evidence. They should be treated as complementary or
illustrative evidence, not as a second measurement of the continuum.

The current hierarchy is justified as a methodological convention:

```text
continuous associations       -> main direct direction evidence
global qualitative associations -> complementary global evidence
end profiles                  -> illustrative evidence for the two ends
```

## 11. Numeric information shown to the LLM

| Number | Legitimate operation | Assessment |
|---|---|---|
| correlation | read direction and compare linear association magnitude cautiously | KEEP |
| p.value | distinguish inferential support from tentative retained signals | KEEP, calibrated |
| R2 | assess global factor association magnitude | KEEP, not importance |
| Estimate | read signed modality/state association with target level | KEEP |
| rank | audit/selection order | correctly hidden |
| evidence_id | traceability only | correctly hidden |
| abs correlation/Estimate | ordering/magnitude support | keep canonically; no need to expose separately |

Thus:

```text
p.value     -> statistical evidence strength
correlation -> signed association and descriptive magnitude
Estimate    -> signed category/state effect
R2          -> global qualitative association magnitude
```

None directly measures substantive importance or causality.

## 12. Reading audit

`build_guide_condes()` combines several functions:

| Current statement | Classification | Assessment |
|---|---|---|
| facts come from `FactoMineR::condes()` under `p <= proba` | provenance/rule | KEEP |
| continuous associations are main direct direction evidence | methodological convention | KEEP, as a hierarchy of views |
| global qualitative associations are complementary | methodological convention | KEEP |
| end profiles illustrate the two ends | interpretation convention | KEEP |
| positive/negative correlation meanings | exact reading rule | KEEP |
| negative/positive Estimate gives lower/higher side | reading rule after NaileR mapping | KEEP with reference caveat |
| smaller p-values are stronger evidence | inferential convention | KEEP, not importance |
| synthesize coherent variables, not lines | interpretation instruction | KEEP |

The guide is mostly sound. It slightly mixes statistical reading and
interpretive hierarchy, especially where “strongest” appears. This is a
wording ambiguity, not a statistical error.

## 13. Standard versus latent

The distinction is correctly confined to the interpretation layer.

**Standard:** the target is an observed quantitative variable whose name is
meaningful; preserve the name and explain what the associations add to its
meaning.

**Latent:** the target is a synthetic/latent score; treat its lower and higher
values as opposite manifestations of one continuum, reconstruct the common
meaning, and propose a name when justified.

The canonical profile and semantic evidence do not change between modes. This
is analogous to CATDES standard/latent but not identical: CATDES changes the
ontology of categories/groups, whereas CONDES changes whether the one target
label is already meaningful.

## 14. Current prompt decomposition

`build_standard_prompt()` produces:

```text
# Introduction
[introduction]
---
[build_guide_condes()]

# Task
[build_request_condes()]

# Data
[semantic_facing_evidence$prompt_text]

[build_conclusion_condes()]
```

Conceptually this is:

```text
context        -> introduction
reading        -> guide
question       -> request
interpretation -> partly guide/request
evidence       -> semantic-facing prompt text
output         -> conclusion
```

A separate `local_task` is not currently necessary: each call has one target
continuous variable and the target binding already appears in introduction and
request. If modularized later, `context + reading + question + interpretation
+ evidence + output` is the better minimal grammar. Do not force CONDES into
the QDA/CATDES local/joint scope model.

## 15. Operational examples

No LLM was called.

Using `FactoMineR::decathlon`, target column 12 (`Points`), standard mode and
`generate = FALSE` produced:

```text
quantitative associations: 9
qualitative associations: 0
low-end profiles: 7
high-end profiles: 9
selected evidence rows: 25
prompt length: 6096 characters
```

A PCA on the first ten decathlon performance variables was then supplied as
`Dim1` with `interpretation_mode = "latent"` and `generate = FALSE`:

```text
quantitative associations: 7
qualitative associations: 0
low-end profiles: 6
high-end profiles: 7
selected evidence rows: 20
prompt length: 5673 characters
```

In both cases `nail_evidence()` exposes the canonical profile and
`nail_prompt()` exposes the exact final prompt. Standard preserves the
observed target identity; latent treats `Dim1` as a technical label.

The existing semantic rebuild tests additionally exercise qualitative
predictors and confirm explicit correlation, R2, lower-end, and higher-end
facts.

## 16. Comparison with QDA and CATDES

| Method | Statistical object | Reference | Direction | Semantic unit | Natural scope | Standard/latent |
|---|---|---|---|---|---|---|
| QDA | product-by-attribute profile | panel/sample comparisons | higher/lower attributes | product/stimulus | portfolio or isolated product | known vs constructed interpretation |
| CATDES | category/group profile | full sample | more/less frequent, higher/lower means | category/group | joint portfolio or autonomous portrait | observed category vs constructed group |
| CONDES | one continuous target | target distribution/grand mean | correlation sign, Estimate sign, lower/higher end | one continuum | one target | observed variable vs latent score |

QDA/CATDES characterize discrete units or profiles. CONDES characterizes one
continuous target and its two ends; its end profiles are views of that
continuum, not independent local units.

## 17. Risks and ambiguities

- Technical state copies create partly redundant evidence with original numeric
  correlations.
- A modality `Estimate` can be mistaken for an endpoint magnitude.
- Global R2 has no direction by itself.
- Global factor significance does not strictly gate modality rows.
- “Strongest” may mean smallest p-value, largest association magnitude, or
  central interpretive role. The current hybrid ordering is not a universal
  definition of substantive centrality.
- Request, reading, and conclusion share mild responsibilities for synthesis.

These are audit observations, not evidence that an LLM will necessarily fail.
They must be distinguished from model prediction errors.

## Wording stabilization

The wording-only stabilization preserves the statistical and evidence objects.
It makes four distinctions explicit in the reading layer:

- `p.value` indicates statistical support against the corresponding null
  association under the fitted analysis; it is not substantive importance.
- `correlation` keeps its sign as direction and uses its absolute value as a
  descriptive magnitude of linear association; magnitude is not automatically
  interpretive centrality.
- `Estimate` remains a signed effect relative to the fitted coding/model for
  displayed modalities or states, orienting toward the lower or higher end;
  it is not an importance measure or an independent confirmation.
- interpretive centrality is explicitly a synthesis of the coherent displayed
  evidence, potentially informed by context, rather than a direct statistic.

End profiles remain complementary and illustrative, partly redundant with
variable-level evidence, and conceptually secondary to the direct
variable-level associations. No computation, selection, ranking, evidence
family, ID, or standard/latent contract was changed.

## 18. KEEP / CHANGE / POSTPONE

### KEEP

- one `condes()` computation per analysis;
- canonical `continuous_profile` and evidence registry;
- `condes_result` as source of truth and `condes_profile_result` as alias;
- deterministic selection and stable evidence IDs;
- semantic-facing factual evidence and public accessors;
- standard/latent interpretation separation;
- end profiles as complementary/illustrative evidence.

### CHANGE

- clarify statistical evidence strength versus association magnitude versus
  interpretive centrality;
- explain modality `Estimate` as a signed target-scale model effect;
- make end-profile redundancy explicit in the reading contract;
- reduce request/conclusion overlap only if a future audit finds a practical
  problem.

### POSTPONE

- removing correlation, p-value, R2, or Estimate;
- collapsing end profiles into correlations;
- public editable reading/block APIs;
- evidence-family ablation benchmarking;
- a new CONDES renderer;
- forcing CONDES into the QDA/CATDES local/joint scope model.

## 19. Recommended next PASS

The smallest useful next PASS is wording-only. Preserve every canonical field
and semantic-facing fact, but replace ambiguous `strongest` formulations with:

```text
statistical evidence strength -> p-value / inferential support
association magnitude         -> |correlation|, R2, |Estimate|
interpretive centrality       -> coherent synthesis across several facts
```

The pass should confirm byte-for-byte invariance of `nail_evidence()` and
preserve custom introduction, request, and conclusion text. No numerical
suppression or modularization is justified before that targeted audit.

## 20. Required questions — explicit answers

1. `continuous_profile` is a good canonical source: yes.
2. The four families are useful but not independent: keep canonically, without
   assigning them equal semantic weight automatically.
3. End profiles are both complementary and partly redundant.
4. Quantitative associations are correctly represented for signed linear
   direction and inferential support.
5. Qualitative associations are correctly represented globally via R2/p-value,
   with directional modality information in end profiles.
6. The visible numbers have identifiable interpretive operations when their
   status is respected.
7. `p.value` should remain visible as inferential evidence strength.
8. `correlation` should remain visible as signed association and cautious
   descriptive magnitude.
9. `Estimate` should remain visible as signed modality/state effect.
10. The reading mixes statistical and interpretive instructions slightly.
11. The request mixes analytical question, synthesis, naming, and output
    responsibilities.
12. Standard and latent are correctly separated in the interpretation layer.
13. Higher-level interpretation with traceability is permitted.
14. Future modularization should separate context, reading, question,
    interpretation, evidence, and output.
15. The computation, canonical profile, IDs, family structure, and accessors
    should not be changed.
16. The smallest useful next change is wording-only calibration of the three
    meanings of “strong”.
