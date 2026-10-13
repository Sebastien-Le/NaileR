# CATDES reference prompt V1

**Status:** APPROVED METHODOLOGICAL REFERENCE — not yet wired into nail_catdes().

**Scope:** This document formalizes the CATDES prompt validated for PASS 7B.2. It is a methodological reference for standard/latent and local/global CATDES interpretations. It does not change the package implementation, statistical computation, evidence selection, output contract, or parser.

**Source:** the exact CATDES V1 prompt supplied for PASS 7B.2. The prompt below is reproduced integrally. Placeholders are intentional: the runtime renderer replaces them with the relevant user input, mode-specific rules, task, settings, and semantic-facing evidence.

## Scientific status and scope

The evidence-first principle is interpreted as:

```text
statistical evidence
→ synthesis
→ evidence-based substantive interpretation
→ optional broader contextual hypothesis
```

The LLM may construct a higher-level concept from several displayed facts. Such a concept is an analytical synthesis, not a new empirical observation. The full analyzed sample is the statistical reference for CATDES; an observed category must keep its observed identity, whereas a constructed group may receive a descriptive name only when the displayed profile supports one.

The reference prompt specifies:

- the semantic meaning of qualitative and quantitative CATDES evidence;
- the distinction between statistical facts, synthesis, and contextual hypothesis;
- the treatment of negative wording, polarity, capability, intention, behavior, preference, and constraint;
- the limits of selected/undisplayed evidence and group comparisons;
- standard versus latent group identity;
- local versus global interpretation;
- the final interpretation requirements and reusable output contract.

## Integral approved prompt (English)

```text
# Introduction

[User-provided study introduction.]

---

## How to Read the Statistical Evidence

The statistical results below come from `FactoMineR::catdes()` using the current significance threshold.

The analysis characterizes each category or group by comparing its qualitative response frequencies and quantitative variable means with those observed in the full analyzed sample.

The full sample is the statistical reference. It is not a particular reference group.

### Understanding qualitative evidence

Each qualitative statement refers to one specific response modality of one variable.

- **MORE FREQUENT** means that the displayed modality is statistically overrepresented in the group relative to its frequency in the full sample.
- **LESS FREQUENT** means that the displayed modality is statistically underrepresented in the group relative to its frequency in the full sample.
- **Group percentage** is the proportion of observations within the group that have the displayed modality.
- **Full-sample percentage** is the proportion of observations in the full analyzed sample that have that same modality.

Statistical overrepresentation does not necessarily imply an absolute majority within the group.

A MORE FREQUENT modality may concern only a minority of group members. Conversely, a LESS FREQUENT modality may remain the majority response within the group.

Always interpret the statistical direction together with the reported within-group percentage.

Do not confuse the proportion of group members having a modality with the proportion of people having that modality who belong to the group.

### Understanding quantitative evidence

Each quantitative statement compares the mean of one variable in the group with the mean of that same variable in the full analyzed sample.

- **HIGHER** means that the group mean is significantly higher than the full-sample mean for the variable.
- **LOWER** means that the group mean is significantly lower than the full-sample mean for the variable.

Interpret the meaning of a higher or lower score according to what the variable actually measures.

A HIGHER score does not necessarily mean a more favorable outcome; a LOWER score does not necessarily mean a less favorable outcome.

Compare each group mean only with the full-sample mean for the same variable. Do not compare means across unrelated variables as if they necessarily shared a meaningful common scale.

### Understanding statistical significance

The displayed statements have been retained according to the statistical analysis and the current evidence-selection settings.

When supplied:

- **v.test** is a signed standardized test statistic describing the statistical deviation associated with the displayed result.
- **p.value** indicates statistical evidence against the corresponding null hypothesis.

Neither statistic directly measures substantive importance, behavioral intensity, or the proportion of individuals sharing a characteristic.

Do not treat the most statistically significant marker as necessarily the most important characteristic for interpreting the group.

### Preserving the meaning of response modalities

Interpret the statistical direction and the semantic meaning of each response modality separately.

Preserve the meaning of negative statements, reverse-worded questions, and double negations.

A MORE FREQUENT negative response remains an overrepresented negative response. A LESS FREQUENT negative response remains an underrepresented negative response.

Do not automatically transform a less frequent negative statement into a positive characteristic.

Infer the frequency of an opposite response only when the coding, category structure, and displayed evidence explicitly justify that inference.

Do not confuse reported capability, reported intention, actual behavior, personal preference, and perceived constraint. These are different constructs unless the study explicitly establishes otherwise.

### Scope and selection of evidence

The information displayed below is the evidence selected for this interpretation.

The statistical analysis may have retained other associations that are not included in the prompt.

An undisplayed modality or variable must not automatically be considered absent, average, insignificant, rejected, or unimportant.

The current selection settings are:

[Dynamic description of significance threshold, qualitative selection, quantitative selection, negative-marker policy, and binary completion when applicable.]

If negative-direction markers have been excluded, the displayed results provide a deliberately restricted characterization. Do not assume that omitted negative deviations do not exist.

If both modalities of a binary variable are displayed, read them as complementary descriptions of that variable rather than independent evidence of two separate phenomena.

### Role of the study context

The introduction explains the study, the measured constructs, and the substantive meaning of the variables.

Use this context to interpret what the observed statistical associations may mean.

However, contextual information, group labels, and the analyst's hypotheses are not additional statistical evidence.

Distinguish measured findings, evidence-grounded synthesis, and broader contextual hypotheses.

---

# Overall Analytical Request

[Original user-provided analytical request, preserved without lexical rewriting.]

---

## Interpretation Rules

### 1. Construct a meaningful group profile

Consider the displayed qualitative and quantitative findings together rather than merely listing them.

Identify the dominant substantive configuration supported by the evidence.

Where several variables describe related aspects of the same activity or phenomenon, synthesize their meanings jointly when justified.

For example, reported capability and perceived restrictiveness may provide complementary perspectives on the same activity. Interpret them together when the measurements support such a reading.

A higher-level interpretation is encouraged when it meaningfully synthesizes several displayed findings and remains traceable to those findings.

Do not present that synthesis as a directly measured variable or as a statistically demonstrated relationship between the underlying variables.

### 2. Preserve nuances, exceptions, and tensions

Do not force all findings into one uniform narrative.

Identify relevant exceptions, contrasting findings, or tensions that qualify the dominant configuration.

Different dimensions may point in different directions. A meaningful profile may therefore be heterogeneous rather than entirely coherent.

The interpretation should reflect the amount, diversity, and consistency of the available evidence.

Do not exaggerate isolated findings or conceal results that meaningfully qualify the proposed synthesis.

### 3. Preserve statistical and semantic fidelity

Respect the original direction of each displayed association.

Interpret every qualitative frequency relative to the same modality in the full sample.

Interpret every quantitative mean relative to the full-sample mean of the same variable.

Do not mistake statistical overrepresentation for a majority, universal membership, or individual-level certainty.

Do not infer an unmeasured opposite modality merely from a lower frequency.

Do not introduce unsupported behaviors, beliefs, preferences, motivations, causal mechanisms, or psychological characteristics.

Do not transform reported perceptions or capabilities into demonstrated actions.

### 4. Distinguish description from interpretation

Use the measured variables to identify what characterizes the group relative to the full analyzed sample.

A broader conceptual label or interpretation may summarize several findings when scientifically defensible.

Such a concept is an analytical synthesis, not an additional empirical observation.

Broader contextual explanations may be suggested as hypotheses when useful, but they must not be presented as established conclusions.

### 5. Respect the limits of group comparisons

Each statistical characterization compares a group with the full sample.

When several groups are displayed, their profiles may be compared descriptively.

Do not present differences between two groups as statistically significant pairwise comparisons unless a corresponding pairwise test is explicitly provided.

Do not claim that a characteristic applies to every individual in a group.

---

## Group Identity Rules

[Include only the section corresponding to the selected interpretation mode.]

### STANDARD MODE — Observed categories

The categories correspond to observed labels of the target variable.

Preserve their original names and identities.

Describe the statistical characteristics associated with each observed category.

Do not rename an observed category or reinterpret it as a constructed latent profile.

A category label provides study context, not independent evidence about the attributes of its members.

Any higher-level interpretation should describe the category's observed associations without replacing its original identity.

### LATENT MODE — Constructed groups

The groups were constructed by an upstream analytical procedure.

Their original labels are identifiers, not substantive descriptions.

Do not assume that the groups represent pre-existing psychological entities, probabilistic latent classes, or naturally occurring homogeneous types.

Their descriptive meaning may be developed from the displayed statistical characteristics.

When supported by a sufficiently coherent configuration of findings, propose a concise descriptive name grounded in the measured domain.

Do not invent personality traits, moral identities, psychological motivations, or behavioral archetypes not established by the data.

An interpretive name must supplement, never replace, the original group identifier.

If the evidence is too sparse, heterogeneous, or ambiguous to justify a meaningful name, retain the original identifier and explain the main characteristics without forcing a label.

---

# Task

[Use the appropriate automatically generated task.]

### LOCAL TASK — One category or group

This prompt concerns only category/group "[group_identifier]" as part of the overall analytical request.

Characterize its dominant profile from the evidence displayed below.

Combine related qualitative and quantitative findings, while identifying relevant exceptions and tensions.

Do not describe other groups whose evidence is not displayed.

Preserve the original group identifier and follow the selected group identity rules.

### GLOBAL TASK — Complete evaluated set

This prompt concerns the complete set of categories or groups displayed below.

Characterize each group from its own evidence.

Then identify the main similarities, contrasts, and broader configurations supported by the displayed profiles.

Preserve all original group identifiers.

Do not claim unreported pairwise statistical significance.

---

# Data

[Automatically generated CATDES evidence for the selected category or groups.]

Each displayed fact should preserve the original variable, modality where applicable, direction, and the relevant descriptive statistics.

When included by the validated evidence policy, statistical test information should be presented consistently.

---

# Final Interpretation Requirements

Produce a substantive interpretation rather than a mechanical restatement of the statistical results.

For each category or group, provide:

1. **Core profile** — a concise, evidence-grounded synthesis of the dominant configuration.
2. **Supporting characteristics** — the main qualitative and quantitative findings supporting that synthesis.
3. **Nuances and exceptions** — meaningful contrasts or heterogeneous features that qualify the dominant configuration.
4. **Distinctive interpretation** — what characterizes the group relative to the full analyzed sample.
5. **Descriptive name** — only when permitted by the selected interpretation mode and sufficiently supported by the evidence.

For global interpretations, also describe the principal differences and similarities between the displayed group profiles, without implying unreported pairwise statistical tests.

Avoid unnecessarily repeating numerical results when a clear semantic synthesis is possible, but retain enough factual support to make the interpretation traceable.

Preserve any existing NaileR reusable metadata and output-format contracts without changing their schema.

The output must use valid Quarto Markdown.
```

## Runtime variants and dynamic sections

The approved V1 is a specification, not a request to rewrite the current CATDES implementation in this PASS.

At runtime, the following substitutions are required conceptually:

| V1 component | Runtime content |
| --- | --- |
| Introduction | The public introduction, or the current default introduction. |
| Overall Analytical Request | The public request, or the current default request, preserved as user text. |
| Group Identity Rules | Exactly one selected branch: STANDARD MODE for observed categories or LATENT MODE for constructed groups. |
| Task | Exactly one task: LOCAL TASK for isolated groups or GLOBAL TASK for the joint evaluated set. |
| Data | Semantic-facing CATDES evidence for the selected group(s), with original direction, modality, and descriptive percentages/means. |
| Current selection settings | Dynamic description of the actual threshold, qualitative/quantitative samples, negative-marker policy, and binary completion. |
| Final Interpretation Requirements | The current CATDES output/reusable contract, without schema changes. |

The standard and latent branches must not be conflated. In standard mode, observed category names are preserved. In latent mode, numeric or technical labels remain identifiers and an interpretive name may be proposed when supported. Likewise, local and global tasks differ: local prompts characterize one group, whereas a joint prompt characterizes the complete displayed set and makes descriptive cross-profile comparisons without inventing pairwise tests.

The implementation currently keeps canonical CATDES profiles and semantic-facing evidence distinct. The semantic-facing prompt intentionally omits p.value, v.test, and evidence IDs in the current code path, while canonical profiles retain the statistical information needed for audit and accessors. V1 describes v.test and p.value conditionally (“when supplied”); systematic exposure of those fields to the LLM remains an open implementation arbitration and is not silently claimed here as implemented.

## Implementation boundary for PASS 7B.2

No R code, tests, documentation pages, statistical calculation, evidence registry, evidence selection, sampling, accessor, parser, or output contract is changed by this document. The current generated prompts remain the executable behavior until a later implementation PASS explicitly adopts a reviewed subset of this reference.

## Comparative block matrix

| Block | Role in V1 | Source at runtime | Required status |
| --- | --- | --- | --- |
| Introduction | Gives substantive meaning to the study and measured constructs | Public introduction or default | User/context block; not statistical evidence |
| How to Read the Statistical Evidence | Defines CATDES semantics and reading safeguards | NaileR method-specific rules plus dynamic settings | Mandatory methodological block |
| Overall Analytical Request | States the analytical question | Public request or default | User block, preserved without lexical rewriting |
| Interpretation Rules | Allows synthesis while protecting traceability and calibration | NaileR interpretation doctrine | Mandatory methodological block |
| Group Identity Rules | Distinguishes observed categories from constructed groups | Standard or latent mode | Exactly one branch |
| Task | Defines local or global scope | Isolated-group or joint route | Exactly one branch |
| Data | Provides semantic-facing selected evidence | CATDES evidence builder | Mandatory evidence block |
| Final Interpretation Requirements | Defines visible answer and reusable output requirements | Public conclusion/default plus current contract | Final high-level instruction |

## Canonical versus LLM-facing evidence

| Evidence layer | Contains | Used for | V1 implication |
| --- | --- | --- | --- |
| Canonical statistical profiles | Full CATDES-derived profiles, registry, IDs, settings and audit information | Reproducibility, accessors, invariance and audit | Must not be altered by prompt assembly |
| Semantic-facing evidence | Selected qualitative modalities and quantitative facts with directions and descriptive percentages/means | LLM interpretation | Must preserve variable/modality identity and displayed direction |
| Dynamic selection description | Threshold, qualitative/quantitative sampling, negative-marker policy and binary completion | Interpretation of what is and is not displayed | Must describe actual settings, not imply a complete profile |
| Optional test information | v.test and p.value when supplied | Statistical reading only | Current CATDES semantic-facing route does not systematically expose these fields; open arbitration |
| Reusable metadata | Existing NaileR parser/output metadata | Downstream structured access | Schema remains unchanged |

The reference therefore distinguishes the evidence that exists canonically from the evidence intentionally exposed to the LLM. A prompt block may explain a canonical policy without exposing every canonical field.

## Scope and output contract matrix

| Dimension | Standard/local | Standard/global | Latent/local | Latent/global |
| --- | --- | --- | --- | --- |
| Identity | Preserve one observed category name | Preserve every observed category name | Retain one constructed-group identifier; optional descriptive name | Retain every constructed-group identifier; optional descriptive names |
| Scope | One displayed category/group only | Complete displayed set; descriptive contrasts | One constructed group only | Complete constructed set; descriptive contrasts |
| Pairwise claims | None unless supplied | No unreported pairwise significance | None unless supplied | No unreported pairwise significance |
| Final answer | Core profile, support, nuances, distinctive interpretation | Same for each group plus similarities/contrasts | Same, with name only if supported | Same for each group, with supported names and global contrasts |
| Output contract | Preserve existing reusable metadata/schema | Preserve existing reusable metadata/schema | Preserve existing reusable metadata/schema | Preserve existing reusable metadata/schema |

## Operational validation matrix

| Check before implementation adoption | Standard | Latent | Local/global | Evidence/output |
| --- | --- | --- | --- | --- |
| Exact rendered prompt can be inspected offline | Required | Required | Required for both routes | Required |
| Canonical statistical profiles are invariant | Required | Required | Required | Required |
| Semantic-facing facts retain direction and denominators | Required | Required | Required | Required |
| Observed names are preserved | Required | Not applicable as observed identity | Local/global scope checked | Required |
| Constructed identifiers remain visible and names are optional | Not applicable | Required | Local/global scope checked | Required |
| Undisplayed evidence is not treated as absent | Required | Required | Required | Required |
| Reusable metadata and parser remain compatible | Required | Required | Required | Required |
| No LLM benchmark is silently replaced by static inspection | Required | Required | Required | Required |

## Ranked candidate improvements

These are candidates for a later PASS, not changes authorized by this document.

1. **Adopt the approved block separation in the CATDES renderer**, after a prompt-diff review against current standard/latent and local/joint behavior.
2. **Decide whether v.test and p.value should be exposed in semantic-facing CATDES evidence**, with an explicit benchmark and invariance tests; do not infer the answer from the reference wording.
3. **Evaluate the compact draft against V1 on representative standard and latent local/global cases**, including sparse, heterogeneous, negative-direction and binary-completion profiles.
4. **Add explicit offline contract tests for mode-branch exclusivity, identifier preservation and reusable metadata parsing** if the renderer is changed.
5. **Only after those checks, consider shared prompt architecture across methods**; method-specific readings should remain separate until their semantics are independently reviewed.
