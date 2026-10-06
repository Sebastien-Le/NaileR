# NaileR QDA modular prompt blocks PoC

## Baseline

- Source branch: `dev-prompt-interpretive-lift`
- Source commit: `33ba78e`
- PoC branch: `dev-modular-prompt-blocks-poc`
- PoC branch HEAD: `33ba78ee842457961ef08ffefaa86a194d42ab9e`

## Conceptual blocks

The QDA-only prompt representation stores the following ordered components for
each product or portfolio prompt:

1. `context`: user/default introduction;
2. `reading`: method-specific `SensoMineR::decat()`, HIGHER/LOWER,
   adjusted-mean, v.test, significance, sampling, and undisplayed-attribute
   reading rules;
3. `question`: user/default analytical request;
4. `interpretation`: evidence-first sensory synthesis, epistemic rules, and
   semantic safeguards for reading HIGHER/LOWER evidence;
5. `local_task`: the exact product/stimulus currently being interpreted;
6. `evidence`: unchanged semantic-facing QDA evidence;
7. `reusable`: protected product-interpretation metadata instruction;
8. `output`: final interpretation requirements.

The internal artifact is `attr(x, "qda_prompt_blocks")`. It is a named list
by product for isolated QDA and contains the eight component names. Disabled
default blocks remain represented as `NULL` values, while `context`,
`question`, `evidence`, `reusable`, and `output` remain protected.

## Renderer

The QDA renderer emits Markdown sections in this order:

```text
# Introduction
## How to Read the Evidence
# Analytical Question
## Interpretation Rules
# Local Task
# Data
## Reusable NaileR Metadata
# Final Interpretation Requirements
```

The public `introduction`, `request`, and `conclusion` values are kept as
their corresponding block contents. A default conclusion is placed under the
explicit final-requirements heading; custom conclusion text is preserved
verbatim under that heading. The reusable metadata instruction is emitted
before the final output requirement and its parser contract is unchanged.
PASS 2 keeps semantic interpretation rules in `interpretation` and reduces
`reusable` to the downstream serialization instruction.

PASS 3 adds the validated B2 operational relative-verbalization rule to
`interpretation` only.

## Full default QDA prompt

The following prompt was generated with `generate = FALSE`, using
`SensoMineR::sensochoc`, `~Product+Panelist`, `firstvar = 5`,
`isolate.groups = TRUE`, `sample.pct = 1`, and the operational
introduction/request/conclusion used by the PoC.

```text
# Introduction

Six chocolates were evaluated by a trained sensory panel. The objective is to understand their sensory profiles.

---

## How to Read the Evidence

The R-derived facts below come from `SensoMineR::decat()` under the current significance threshold (p <= 0.05).
HIGHER and LOWER describe the relative sensory profile of each product compared with the average profile across the evaluated set.
The adjusted mean is the model-adjusted score for the sensory attribute.
The v.test gives the direction and strength of the retained deviation; smaller p.values indicate stronger statistical evidence.

The LLM receives 100% of the eligible retained markers under the current sampling setting.
All eligible retained markers are shown, so the sampling method has no effect.
Both HIGHER and LOWER retained markers are eligible for the LLM evidence.
Do not treat an undisplayed attribute as evidence that the attribute is average: it may be absent because it was not statistically retained or because of the prompt-selection settings.

---

# Analytical Question

Interpret each product as a coherent sensory configuration. Do not merely paraphrase the retained attributes one by one. When several attributes converge, infer the higher-level sensory meaning while keeping that interpretation traceable to the evidence.

---

## Interpretation Rules

Interpret the retained attributes as a sensory profile: first identify the coherent pattern formed by the bundle, then use individual facts to justify that interpretation.
Do not invent a new empirical sensory attribute that is not supported by the displayed evidence.
A higher-level sensory concept is allowed when it is a reasonable synthesis of several displayed attributes; present it as an interpretation, not as a directly measured attribute.
Do not turn associations into causal explanations.
If you move beyond direct sensory description, make clear that you are offering an interpretation or hypothesis.
Preserve the direction of every displayed fact: HIGHER means more of the named attribute and LOWER means less of the named attribute.
Do not turn a LOWER attribute into a positive presence of that attribute or infer an opposite attribute that was not measured.
Do not change the technical meaning of an attribute or introduce unsupported sensory descriptors.
Do not present a synthesis as a directly measured sensory fact, and do not introduce unsupported hedonic, evaluative, marketing, positioning, or causal claims.
Product labels are meaningful identifiers. Preserve them as identifiers. A descriptive name may supplement the identifier when requested, but it must not replace the original product label.
Interpret every HIGHER/LOWER result relative to the average product profile.
Prefer:
- "more marked by [attribute]" for HIGHER;
- "less marked by [attribute]" for LOWER.
Preserve this relative meaning when building the overall sensory interpretation.

---

# Local Task

Interpret only product "choc1".
Preserve "choc1" as its product identifier.

---

# Data

## Product 'choc1'

R-derived facts retained for this product:
- Attribute "Bitterness" is HIGHER than the average sensory profile for this item (adjusted mean=7.07; v.test=9.95; p.value=<0.001).
- Attribute "MilkF" is LOWER than the average sensory profile for this item (adjusted mean=1.57; v.test=-8.70; p.value=<0.001).
- Attribute "CocoaF" is HIGHER than the average sensory profile for this item (adjusted mean=8.07; v.test=8.48; p.value=<0.001).
- Attribute "Sweetness" is LOWER than the average sensory profile for this item (adjusted mean=3.14; v.test=-8.29; p.value=<0.001).
- Attribute "Astringency" is HIGHER than the average sensory profile for this item (adjusted mean=4.76; v.test=7.08; p.value=<0.001).
- Attribute "Caramel" is LOWER than the average sensory profile for this item (adjusted mean=1.67; v.test=-6.99; p.value=<0.001).
- Attribute "Acidity" is HIGHER than the average sensory profile for this item (adjusted mean=4.66; v.test=6.14; p.value=<0.001).
- Attribute "Vanilla" is LOWER than the average sensory profile for this item (adjusted mean=1.10; v.test=-4.77; p.value=<0.001).
- Attribute "CocoaA" is HIGHER than the average sensory profile for this item (adjusted mean=7.09; v.test=3.90; p.value=<0.001).
- Attribute "MilkA" is LOWER than the average sensory profile for this item (adjusted mean=3.59; v.test=-3.41; p.value=<0.001).

---

## Reusable NaileR Metadata

After the visible answer, append exactly one reusable HTML comment block for each product or stimulus represented in the evidence.
The block is for downstream reuse and is not part of the visible report.
Use the exact product/stimulus label shown in the evidence.
Populate the fields consistently with the visible interpretation grounded in the evidence displayed in this prompt.

<!-- NAILER_PRODUCT_INTERPRETATION
product: <exact label>
core_profile: <one concise evidence-grounded sensory synthesis>
dominant_configuration: <2 to 5 evidence-grounded sensory descriptors or short phrases separated by semicolons>
secondary_configuration: <secondary evidence-grounded descriptors or short phrases separated by semicolons; write none if absent>
distinctive_interpretation: <one concise strictly sensory statement of what distinguishes this item relative to the evaluated set>
descriptive_name: <short evidence-grounded descriptive name; write none only if no descriptive name is requested or no defensible name can be proposed>
END_NAILER_PRODUCT_INTERPRETATION -->

Repeat the complete comment block once for every product/stimulus represented in the answer.

---

# Final Interpretation Requirements

Provide a concise descriptive name for this product. The name may go beyond the literal vocabulary of the measured attributes when it reasonably synthesizes several convergent sensory facts.
```

## Minimal modular QDA prompt

This prompt uses the same call and evidence with
`default_blocks = character(0)`. Only the protected context, question,
evidence, reusable metadata, and final output blocks remain.

```text
# Introduction

Six chocolates were evaluated by a trained sensory panel. The objective is to understand their sensory profiles.

---

# Analytical Question

Interpret each product as a coherent sensory configuration. Do not merely paraphrase the retained attributes one by one. When several attributes converge, infer the higher-level sensory meaning while keeping that interpretation traceable to the evidence.

---

# Data

## Product 'choc1'

R-derived facts retained for this product:
- Attribute "Bitterness" is HIGHER than the average sensory profile for this item (adjusted mean=7.07; v.test=9.95; p.value=<0.001).
- Attribute "MilkF" is LOWER than the average sensory profile for this item (adjusted mean=1.57; v.test=-8.70; p.value=<0.001).
- Attribute "CocoaF" is HIGHER than the average sensory profile for this item (adjusted mean=8.07; v.test=8.48; p.value=<0.001).
- Attribute "Sweetness" is LOWER than the average sensory profile for this item (adjusted mean=3.14; v.test=-8.29; p.value=<0.001).
- Attribute "Astringency" is HIGHER than the average sensory profile for this item (adjusted mean=4.76; v.test=7.08; p.value=<0.001).
- Attribute "Caramel" is LOWER than the average sensory profile for this item (adjusted mean=1.67; v.test=-6.99; p.value=<0.001).
- Attribute "Acidity" is HIGHER than the average sensory profile for this item (adjusted mean=4.66; v.test=6.14; p.value=<0.001).
- Attribute "Vanilla" is LOWER than the average sensory profile for this item (adjusted mean=1.10; v.test=-4.77; p.value=<0.001).
- Attribute "CocoaA" is HIGHER than the average sensory profile for this item (adjusted mean=7.09; v.test=3.90; p.value=<0.001).
- Attribute "MilkA" is LOWER than the average sensory profile for this item (adjusted mean=3.59; v.test=-3.41; p.value=<0.001).

---

## Reusable NaileR Metadata

After the visible answer, append exactly one reusable HTML comment block for each product or stimulus represented in the evidence.
The block is for downstream reuse and is not part of the visible report.
Use the exact product/stimulus label shown in the evidence.
Populate the fields consistently with the visible interpretation grounded in the evidence displayed in this prompt.

<!-- NAILER_PRODUCT_INTERPRETATION
product: <exact label>
core_profile: <one concise evidence-grounded sensory synthesis>
dominant_configuration: <2 to 5 evidence-grounded sensory descriptors or short phrases separated by semicolons>
secondary_configuration: <secondary evidence-grounded descriptors or short phrases separated by semicolons; write none if absent>
distinctive_interpretation: <one concise strictly sensory statement of what distinguishes this item relative to the evaluated set>
descriptive_name: <short evidence-grounded descriptive name; write none only if no descriptive name is requested or no defensible name can be proposed>
END_NAILER_PRODUCT_INTERPRETATION -->

Repeat the complete comment block once for every product/stimulus represented in the answer.

---

# Final Interpretation Requirements

Provide a concise descriptive name for this product. The name may go beyond the literal vocabulary of the measured attributes when it reasonably synthesizes several convergent sensory facts.
```

## Structural comparison

The full and minimal prompts differ only in the presence of the selectable
default blocks. In PASS 2, semantic direction and grounding rules are carried
by `interpretation`, while `reusable` contains only the downstream HTML
metadata instruction. PASS 3 adds B2 to `interpretation` only; it does not
change `reading`, the evidence renderer, or the evidence content. The
descriptive-name field accepts either a short evidence-grounded name or `none`
when no name is requested or defensible. The statistical evidence and
canonical `product_profiles` are identical: `TRUE`.

## Experimental synthesis

The observed ablation results with `mistral-small3.2` were:

- `full`: best overall behaviour;
- `minimal`: unexpectedly solid;
- `interpretation` alone: limited benefit;
- `reading` alone: less convincing.

The current `reading` wording outperformed both a long coefficient
explanation and a short explanatory relative version. The current evidence
renderer also outperformed the alternative semantic renderer that directly
used “more pronounced / less pronounced”. These alternatives are therefore
not integrated.

The first relative interpretation rule was unstable. B2 was preferred in all
three repetitions of the final blind comparison and is integrated as a
positive verbalization grammar:

```text
HIGHER / LOWER
        -> relative characterization
        -> sensory configuration
        -> higher-level interpretation
        -> descriptive name
```

The retained methodological principle is:

```text
R determines which sensory facts statistically characterize the product.
The LLM interprets the configuration of those relative facts.
```

This is a development artifact for the QDA proof of concept only. It does not
define a package-wide prompt grammar and does not generalize the architecture
to CONDES, CATDES, DESCFREQ, TEXTUAL, QDA-space, or CATDES+TEXTUAL.
