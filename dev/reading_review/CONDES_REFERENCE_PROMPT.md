# CONDES reference prompt V1

**Status:** APPROVED METHODOLOGICAL REFERENCE — not yet wired into nail_condes().

**Scope:** This document is the scientific reference for interpreting one quantitative CONDES target from quantitative associations, global qualitative associations, and category/end-profile evidence. It is a specification, not a package implementation change.

**Source:** the complete CONDES V1 prompt supplied for PASS 7C.2. The English prompt below is reproduced integrally and without condensation. Runtime placeholders are intentional.

## Scientific scope

CONDES is not CATDES. It does not characterize several observed or constructed groups against a full sample. It characterizes one numeric target through:

- signed correlations with quantitative predictors;
- global R² associations with qualitative predictors;
- category-level and derived-state Estimates describing lower and higher target values.

The reference preserves the distinction between statistical evidence, substantive synthesis, and broader contextual hypothesis. It allows a higher-level interpretation supported by several associations, but does not authorize causal, predictive, psychological, behavioral, or social claims not established by the displayed evidence.

The target mode is explicit:

- **standard:** preserve the observed quantitative target name and meaning;
- **latent:** retain the original technical identifier, interpret the contrast between its ends, and propose a descriptive name only when justified.

There is no CATDES-style local/global route. CONDES has one target per analysis.

## Integral approved prompt (English)

```text
# Introduction

[Original study introduction, preserved verbatim.]

---

## How to Read the Statistical Evidence

The statistical results below come from `FactoMineR::condes()` under the current significance threshold.

The analysis characterizes one quantitative target using associations with quantitative predictors, global associations with qualitative variables, and category-level descriptions of the target's lower and higher values.

R has performed the statistical calculations. Interpret the displayed evidence; do not recompute or invent statistical results.

### Quantitative associations

For quantitative predictors, the reported correlation describes a linear association with the target.

- A **POSITIVE** correlation means that higher predictor values tend to accompany higher target values.
- A **NEGATIVE** correlation means that higher predictor values tend to accompany lower target values.
- The absolute correlation describes the magnitude of the linear association.

Interpret every direction according to what the predictor measures. Higher numerical values do not necessarily mean greater capability, better performance, or a more favorable outcome.

For example, smaller values may represent better results for a time, ranking, error count, or difficulty measure.

A correlation does not establish causality, independent predictive contribution, or a direct relationship between the substantive concepts beyond the measured association.

### Global qualitative associations

For qualitative predictors, the reported R² summarizes the proportion of target variation associated with the variable's categorical partition under the fitted one-way analysis.

R² is not a signed correlation, does not identify the contribution of any particular category, and does not imply causality.

Category-specific information must be interpreted separately from this global association.

### Category and end-profile evidence

End profiles describe how qualitative categories and derived states of quantitative predictors are associated with lower or higher values of the target.

The derived quantitative states, such as Above-average value and Below-average value, are constructed from the original quantitative predictors using the reported standardization threshold.

They are not independent measurements.

For a quantitative predictor, its continuous correlation and its derived states describe related information from the same underlying variable. End profiles illustrate or qualify the interpretation of the association; they must not be treated as independent statistical confirmations.

**Estimate** is a signed category effect under the sum-to-zero coding used by the fitted one-way model. It expresses the category's deviation from the model reference in the target's units.

A positive Estimate indicates a category associated with higher target values relative to that reference; a negative Estimate indicates lower target values.

Estimate is not a standardized regression weight, an adjusted multiple-regression coefficient, a causal effect, or a universal importance measure.

Interpret the displayed category or state literally. Preserve negations and reverse-worded labels.

Do not infer unmeasured characteristics from a category name or treat a socially descriptive label as evidence of an underlying psychological or sociological mechanism.

### Statistical significance and evidence selection

The p.value describes statistical evidence against the corresponding null hypothesis under the analysis performed.

A smaller p.value does not necessarily mean a larger association or greater substantive importance.

Distinguish statistical support, association magnitude, and interpretive relevance.

The results shown below may represent only a selected subset of the statistically retained evidence.

[Dynamic description of significance threshold, sampling proportion, selection method, and quantitative-state threshold.]

An undisplayed predictor, category, or end-profile statement must not be interpreted as absent, unassociated, non-significant, or unimportant.

Construct the interpretation from the displayed evidence without claiming that it is necessarily exhaustive.

### Role of the study context

The introduction supplies information about the study, the measured variables, and their substantive meanings.

Use it to interpret the statistical results, but do not treat it as additional statistical evidence.

Distinguish direct findings, evidence-grounded synthesis, and broader contextual hypotheses.

---

# Analytical Question

[Original user-provided request, preserved verbatim.]

---

## Interpretation Rules

### 1. Identify the main statistical configuration

Consider the quantitative correlations, global qualitative associations, and end-profile findings together.

Identify the principal directions of association and the most coherent substantive configuration supported by the displayed evidence.

Use statistical support and association magnitude appropriately, without treating either as synonymous with interpretive importance.

Do not merely paraphrase the individual statistical results.

### 2. Translate signs into substantive meaning

Interpret every variable according to its measured meaning and numerical orientation.

Do not assume that positive correlations are favorable or negative correlations unfavorable.

Preserve the literal meaning of qualitative labels, including negative or reverse-worded statements.

### 3. Interpret both ends of the target

Describe the characteristics associated with lower target values and those associated with higher target values.

Use end-profile evidence to illustrate, refine, or qualify the broader variable-level associations.

Do not double-count a quantitative predictor and its derived categorical states as independent evidence.

### 4. Construct a meaningful synthesis

When several findings describe related aspects of the same phenomenon, interpret them jointly when justified.

A higher-level conceptual interpretation is encouraged when it meaningfully synthesizes several displayed associations.

Present this concept as an analytical synthesis, not as an additional measured variable or a statistically demonstrated causal mechanism.

Do not force a single explanation when the results support several distinct dimensions of meaning.

### 5. Preserve exceptions and uncertainty

Identify relevant inconsistencies, asymmetric patterns, or associations that qualify the dominant interpretation.

Do not exaggerate a single rare category, isolated association, or marginal result.

Adapt the specificity of the interpretation to the amount and coherence of the evidence available.

Do not infer causality, unsupported individual characteristics, or unmeasured psychological, behavioral, or social mechanisms.

---

## Target Interpretation Rules

[Include only the section corresponding to the selected interpretation mode.]

### STANDARD MODE — Observed quantitative target

The target is an observed quantitative variable whose original name and meaning must be preserved.

Explain what the statistical associations reveal about its variation.

Characterize lower and higher target values in the substantive terms of the study.

Do not rename the observed target or reinterpret it automatically as an underlying latent construct.

A broader synthesis is permitted when grounded in the displayed associations, but it must not replace the original target identity.

### LATENT MODE — Synthetic or constructed dimension

The target is interpreted as a quantitative dimension whose substantive meaning may need to be reconstructed from its associations.

The original target label is an identifier and must remain visible.

Interpret lower and higher values as positions along the same numerical dimension.

Identify the main substantive contrast between these positions, using the variables associated with each end.

If the target represents a factor or component whose numerical sign is arbitrary, do not attribute intrinsic superiority or value to its positive end.

When the findings support a coherent overarching interpretation, propose a concise descriptive name for the dimension.

The name must reflect the measured domains and supplement rather than replace the original identifier.

Do not assume that the dimension necessarily represents one homogeneous psychological, behavioral, or social construct.

If the evidence is heterogeneous or insufficient, describe the configuration without forcing a single interpretive label.

---

# Task

Interpret the continuous target "[target_identifier]" using the displayed statistical evidence and the overall analytical request.

Identify the main associations, explain the substantive meaning of their directions, characterize both ends of the target, and construct an evidence-grounded interpretation.

Preserve meaningful exceptions and acknowledge limitations of the displayed evidence.

In latent mode, explain what principally distinguishes the two ends and propose a descriptive name only when justified.

---

# Data

[Automatically generated CONDES evidence for the current target.]

The evidence may include:

- Quantitative correlations and their p.values.
- Global qualitative associations, R² and their p.values.
- Category and derived-state Estimates with their p.values.
- Current selection and threshold information.

Preserve the original variable and category identifiers, reported directions, numerical values, and existing NaileR evidence contracts.

---

# Final Interpretation Requirements

Produce a substantive synthesis rather than a mechanical inventory of associations.

Your interpretation should explain:

1. **Overall meaning** — what the associations reveal about the quantitative target.
2. **Lower end** — the characteristics associated with lower target values.
3. **Higher end** — the characteristics associated with higher target values.
4. **Main contrast** — the substantive configuration that distinguishes both ends.
5. **Nuances and limits** — relevant exceptions, mixed findings, and interpretive uncertainty.

For a synthetic dimension, a concise descriptive name may be proposed when supported by the evidence.

For an observed quantitative target, preserve the original name and its meaning.

Use the original analytical question to determine the appropriate emphasis and level of detail.

Avoid unnecessary numerical repetition, but retain sufficient factual support to make the interpretation traceable.

Preserve the existing NaileR output-format, parser, and reusable-metadata contracts.

The output must use valid Quarto Markdown.
```

## Runtime substitutions and dynamic sections

The V1 prompt is a specification. At execution time:

| V1 component | Runtime content |
| --- | --- |
| Introduction | Public introduction or the current default introduction, preserved as user/context text |
| Analytical Question | Public request or current mode-specific default request |
| Target Interpretation Rules | Exactly one standard or latent branch |
| Task | The single-target task with the actual target identifier |
| Data | Semantic-facing selected CONDES evidence |
| Dynamic selection description | Actual proba, sample.pct, sample.method, and quanti.threshold settings |
| Final Interpretation Requirements | Public conclusion/default output requirements and existing reusable contract |

The runtime data must retain original variable/category identifiers, directions, statistics and p.values that are actually exposed. The current implementation creates one FactoMineR::condes() result on augmented data, builds a canonical continuous_profile, selects interpretation_evidence, and renders semantic_facing_evidence. The reference describes this separation but does not authorize changing it.

The optional target_concept is contextual guidance for latent interpretation only. In the current code it is used in the latent interpretation rule when explicitly supplied; the generic default is the phrase “the target concept”. It is not inserted into the introduction or analytical request, and standard mode does not use it to rename the observed target. This behavior is documented as an implementation observation and remains to verify before any future change.

## Statistical information rules

### Correlations

A positive or negative sign gives the numerical direction of the linear association. Absolute correlation describes linear-association magnitude. The substantive meaning depends on what the predictor measures; higher numerical values are not automatically better or worse.

Correlation is not causality, a prediction-performance measure, or an independent causal contribution.

### Qualitative variables

R² is a global association between the target and the categorical partition under the fitted one-way analysis. It has no sign and does not identify the contribution of a particular modality. Category-level information must be read separately.

### Estimate and model reference

Estimate is a signed category coefficient under the sum-to-zero coding used by the fitted one-way model. It is expressed in the target's units and is interpreted relative to the model reference. It must not be described generically as category mean minus the empirical mean of all individuals. Under the usual one-factor sum-contrast interpretation, the reference relates to the mean of modality means, with weights affecting the fitted calculation.

Estimate is not a standardized coefficient, not a partial coefficient from a multiple regression, not a causal effect, and not a universal importance measure. Its sign is coding/model dependent.

### Derived quantitative states

Above-average value, Below-average value, and Intermediate value are technical states derived from the original quantitative predictors using the configured quanti.threshold, expressed in standardization units according to the implementation. The threshold is parameterized and is not always ±1. The continuous predictor and its derived states are related views of the same variable and must not be counted as independent confirmations.

### Significance and selection

p.value reports statistical evidence against the corresponding null under the performed analysis. It is not association magnitude or substantive importance. The displayed evidence may be selected from a larger canonical profile according to proba, sample.pct and sample.method. An undisplayed result is not automatically absent, unassociated, non-significant or unimportant.

## Evidence and contract matrices

### Prompt block matrix

| Block | Role | Runtime source | Status |
| --- | --- | --- | --- |
| Introduction | Study context and measured constructs | introduction/default | Context, not statistical evidence |
| How to Read the Statistical Evidence | CONDES-specific statistical semantics | NaileR reading plus dynamic settings | Mandatory |
| Analytical Question | User's analytic objective | request/default | Preserved user question |
| Interpretation Rules | Synthesis and epistemic safeguards | NaileR interpretation doctrine | Mandatory |
| Target Interpretation Rules | Standard or latent identity | interpretation_mode | Exactly one branch |
| Task | Single-target scope | target identifier and mode | Mandatory |
| Data | Selected semantic-facing evidence | evidence builder | Mandatory |
| Final Interpretation Requirements | Visible answer and reusable output requirements | conclusion/default | Final semantic instruction |

### Canonical versus LLM-facing evidence

| Layer | Content | Contract |
| --- | --- | --- |
| condes_result | One original FactoMineR result on augmented data | Statistical source of truth |
| continuous_profile | Complete mapped profile, registry, settings and metadata | Canonical evidence; invariant to interpretation-layer options |
| interpretation_evidence | Deterministic selected subset by evidence family | May change with sample.pct/sample.method |
| semantic_facing_evidence | Plain-language facts sent to the LLM | Must preserve direction, identifiers, values and p.values shown |
| condes_prompt_blocks / condes_prompt | Ordered context, reading, question, interpretation, evidence and output | Exact prompt audit |
| llm_io | Prompt and optional raw response | Existing accessor/output contract |

### Mode and output matrix

| Mode | Identity rule | Required interpretation | Naming |
| --- | --- | --- | --- |
| Standard | Observed quantitative target identity is preserved | Explain variation and both ends without renaming the target | No replacement target name |
| Latent | Technical/synthetic target label remains visible | Reconstruct the contrast between lower and higher ends | Optional evidence-grounded name |
| Both | One target only; no group comparison route | Preserve mixed findings and uncertainty | Valid Quarto Markdown plus existing metadata/parser contract |

## Future execution composition

A future renderer may compose the prompt in this conceptual order:

1. Introduction.
2. How to Read the Statistical Evidence.
3. Analytical Question.
4. Interpretation Rules.
5. Selected standard or latent Target Interpretation Rules.
6. Task.
7. Data.
8. Final Interpretation Requirements.

Only the selected mode branch should be included at runtime. The canonical statistical profile, evidence IDs, sampling rules, and output schema must remain separate from this rendering specification.

## Implementation boundary

This PASS does not modify R code, tests, package documentation, arguments, prompt builders, prompt_style, interpretation_mode, target_concept, statistical calculations, evidence selection, contracts, or parsers. The current generated prompt remains executable behavior until a later implementation PASS explicitly adopts a reviewed subset of V1.

