# QDA — four prompt assemblies and repetition audit

**Status:** SCIENTIFICALLY STABILIZED (2026-10-14). All English operational blocks and their French control translations, including complete `reading`, are explicitly approved. Four complete documentary assemblies preserved; R implementation and LLM operational tests remain pending.
**Source:** [QDA_MODULAR_PROMPT.md](QDA_MODULAR_PROMPT.md), with `R/nail_qda.R` as technical baseline.

The approved English operational blocks, including `reading`, are reproduced **verbatim**. Introduction, analytical request and R-computed data appear as placeholders to demonstrate assembly, not as invented example evidence.

`product_knowledge` chooses `known` vs `unknown` independently of `isolate.groups` (`TRUE` → local task; `FALSE` → joint task). The current QDA API does not have a distinct joint `interpretation_mode`; the joint task describes profiles and supported contrasts in one pass.

## Four assembled configurations

### known × local

```text
# Introduction

[Original study introduction — preserved verbatim.]

---

## How to Read the Statistical Evidence

The results come from `SensoMineR::decat()` and characterize evaluated products or stimuli through their sensory attributes, relative to the average sensory profile of the evaluated set. This average product is a statistical reference, not an actual evaluated product.

For a given attribute, HIGHER means that the product's adjusted sensory score is statistically higher than the reference; LOWER means it is statistically lower. These directions are relative: LOWER does not mean that the attribute is absent or that its opposite is present.

The adjusted mean is the model-adjusted sensory score for the product and attribute, not its difference from the reference. The `v.test` is a signed standardized statistic, while the `p.value` describes statistical evidence. Neither measures sensory intensity or substantive importance. Do not compare adjusted means across different attributes as if they measured the same sensory characteristic.

Preserve the meaning of each sensory attribute. Use the study context to understand the sensory characteristics, without treating it as additional statistical evidence. Do not infer liking, preference, quality, manufacturing causes, or statistically demonstrated differences between pairs of products from these results.

---

# Analytical Request

[Original analyst request — preserved verbatim.]

---

## Interpretation Rules

Interpret each product or stimulus by considering its displayed sensory attributes jointly, rather than describing them one by one. Identify meaningful patterns and distinctive configurations, and develop a substantive interpretation of the overall sensory profile.

Use knowledge of sensory perception and the study context to connect conceptually related characteristics across the relevant perceptual dimensions. When several attributes converge, develop a higher-level interpretation that captures their combined meaning.

Preserve the relative direction and meaning of each attribute. Distinguish higher-level interpretations from directly measured characteristics, and do not present conceptual connections as statistically demonstrated relationships.

Preserve meaningful contrasts, nuances, and ambiguities. When the evidence is heterogeneous or insufficient to support a unified characterization, do not force a single global interpretation.

---

## Identity — known

Each product or stimulus has a known identity or a meaningful label provided by the analyst. Preserve its original identifier and label.

Use this identity as contextual information when interpreting the sensory profile, without letting it substitute for the statistical evidence.

Do not replace the known identity with an invented descriptive name. A concise sensory characterization may complement it when useful.

---

## Task — local

Interpret only the product or stimulus "[identifier]" using its displayed statistical evidence and the user's analytical request.

Characterize its distinctive sensory profile relative to the average product. Do not describe or compare other products or stimuli.

---

# Data

[R-derived statistical evidence for one product(s)/stimulus(i): sensory attributes, HIGHER/LOWER directions, adjusted means and any available test statistics.]

---

# Final Interpretation Requirements

Write a clear, well-structured and substantive interpretation of the evaluated sensory profiles.

Support the main conclusions with the most relevant sensory attributes, preserving their HIGHER/LOWER directions. Include adjusted means or other statistical values when they help clarify and substantiate the interpretation.

Avoid mechanically reproducing the statistical results or unnecessary numerical repetition.
```

---

### known × joint

```text
# Introduction

[Original study introduction — preserved verbatim.]

---

## How to Read the Statistical Evidence

The results come from `SensoMineR::decat()` and characterize evaluated products or stimuli through their sensory attributes, relative to the average sensory profile of the evaluated set. This average product is a statistical reference, not an actual evaluated product.

For a given attribute, HIGHER means that the product's adjusted sensory score is statistically higher than the reference; LOWER means it is statistically lower. These directions are relative: LOWER does not mean that the attribute is absent or that its opposite is present.

The adjusted mean is the model-adjusted sensory score for the product and attribute, not its difference from the reference. The `v.test` is a signed standardized statistic, while the `p.value` describes statistical evidence. Neither measures sensory intensity or substantive importance. Do not compare adjusted means across different attributes as if they measured the same sensory characteristic.

Preserve the meaning of each sensory attribute. Use the study context to understand the sensory characteristics, without treating it as additional statistical evidence. Do not infer liking, preference, quality, manufacturing causes, or statistically demonstrated differences between pairs of products from these results.

---

# Analytical Request

[Original analyst request — preserved verbatim.]

---

## Interpretation Rules

Interpret each product or stimulus by considering its displayed sensory attributes jointly, rather than describing them one by one. Identify meaningful patterns and distinctive configurations, and develop a substantive interpretation of the overall sensory profile.

Use knowledge of sensory perception and the study context to connect conceptually related characteristics across the relevant perceptual dimensions. When several attributes converge, develop a higher-level interpretation that captures their combined meaning.

Preserve the relative direction and meaning of each attribute. Distinguish higher-level interpretations from directly measured characteristics, and do not present conceptual connections as statistically demonstrated relationships.

Preserve meaningful contrasts, nuances, and ambiguities. When the evidence is heterogeneous or insufficient to support a unified characterization, do not force a single global interpretation.

---

## Identity — known

Each product or stimulus has a known identity or a meaningful label provided by the analyst. Preserve its original identifier and label.

Use this identity as contextual information when interpreting the sensory profile, without letting it substitute for the statistical evidence.

Do not replace the known identity with an invented descriptive name. A concise sensory characterization may complement it when useful.

---

## Task — joint

Interpret the displayed products or stimuli jointly, using their statistical evidence and the user's analytical request.

Characterize each sensory profile, then identify the main similarities, contrasts and, when supported, coherent sensory families across the evaluated set.

Ground comparisons in the displayed sensory profiles, interpreted relative to the average product. Do not present descriptive contrasts as statistically demonstrated pairwise differences between products or stimuli.

---

# Data

[R-derived statistical evidence for all displayed product(s)/stimulus(i): sensory attributes, HIGHER/LOWER directions, adjusted means and any available test statistics.]

---

# Final Interpretation Requirements

Write a clear, well-structured and substantive interpretation of the evaluated sensory profiles.

Support the main conclusions with the most relevant sensory attributes, preserving their HIGHER/LOWER directions. Include adjusted means or other statistical values when they help clarify and substantiate the interpretation.

Avoid mechanically reproducing the statistical results or unnecessary numerical repetition.
```

---

### unknown × local

```text
# Introduction

[Original study introduction — preserved verbatim.]

---

## How to Read the Statistical Evidence

The results come from `SensoMineR::decat()` and characterize evaluated products or stimuli through their sensory attributes, relative to the average sensory profile of the evaluated set. This average product is a statistical reference, not an actual evaluated product.

For a given attribute, HIGHER means that the product's adjusted sensory score is statistically higher than the reference; LOWER means it is statistically lower. These directions are relative: LOWER does not mean that the attribute is absent or that its opposite is present.

The adjusted mean is the model-adjusted sensory score for the product and attribute, not its difference from the reference. The `v.test` is a signed standardized statistic, while the `p.value` describes statistical evidence. Neither measures sensory intensity or substantive importance. Do not compare adjusted means across different attributes as if they measured the same sensory characteristic.

Preserve the meaning of each sensory attribute. Use the study context to understand the sensory characteristics, without treating it as additional statistical evidence. Do not infer liking, preference, quality, manufacturing causes, or statistically demonstrated differences between pairs of products from these results.

---

# Analytical Request

[Original analyst request — preserved verbatim.]

---

## Interpretation Rules

Interpret each product or stimulus by considering its displayed sensory attributes jointly, rather than describing them one by one. Identify meaningful patterns and distinctive configurations, and develop a substantive interpretation of the overall sensory profile.

Use knowledge of sensory perception and the study context to connect conceptually related characteristics across the relevant perceptual dimensions. When several attributes converge, develop a higher-level interpretation that captures their combined meaning.

Preserve the relative direction and meaning of each attribute. Distinguish higher-level interpretations from directly measured characteristics, and do not present conceptual connections as statistically demonstrated relationships.

Preserve meaningful contrasts, nuances, and ambiguities. When the evidence is heterogeneous or insufficient to support a unified characterization, do not force a single global interpretation.

---

## Identity — unknown

Each stimulus is identified by a code or label that does not reveal its substantive identity. Preserve this original identifier.

Interpret its sensory profile to characterize what makes it distinctive. When supported by a coherent sensory pattern, propose a concise, meaningful sensory name alongside the identifier.

Do not attempt to guess the stimulus's actual identity or force a descriptive name when the profile does not support one.

---

## Task — local

Interpret only the product or stimulus "[identifier]" using its displayed statistical evidence and the user's analytical request.

Characterize its distinctive sensory profile relative to the average product. Do not describe or compare other products or stimuli.

---

# Data

[R-derived statistical evidence for one product(s)/stimulus(i): sensory attributes, HIGHER/LOWER directions, adjusted means and any available test statistics.]

---

# Final Interpretation Requirements

Write a clear, well-structured and substantive interpretation of the evaluated sensory profiles.

Support the main conclusions with the most relevant sensory attributes, preserving their HIGHER/LOWER directions. Include adjusted means or other statistical values when they help clarify and substantiate the interpretation.

Avoid mechanically reproducing the statistical results or unnecessary numerical repetition.
```

---

### unknown × joint

```text
# Introduction

[Original study introduction — preserved verbatim.]

---

## How to Read the Statistical Evidence

The results come from `SensoMineR::decat()` and characterize evaluated products or stimuli through their sensory attributes, relative to the average sensory profile of the evaluated set. This average product is a statistical reference, not an actual evaluated product.

For a given attribute, HIGHER means that the product's adjusted sensory score is statistically higher than the reference; LOWER means it is statistically lower. These directions are relative: LOWER does not mean that the attribute is absent or that its opposite is present.

The adjusted mean is the model-adjusted sensory score for the product and attribute, not its difference from the reference. The `v.test` is a signed standardized statistic, while the `p.value` describes statistical evidence. Neither measures sensory intensity or substantive importance. Do not compare adjusted means across different attributes as if they measured the same sensory characteristic.

Preserve the meaning of each sensory attribute. Use the study context to understand the sensory characteristics, without treating it as additional statistical evidence. Do not infer liking, preference, quality, manufacturing causes, or statistically demonstrated differences between pairs of products from these results.

---

# Analytical Request

[Original analyst request — preserved verbatim.]

---

## Interpretation Rules

Interpret each product or stimulus by considering its displayed sensory attributes jointly, rather than describing them one by one. Identify meaningful patterns and distinctive configurations, and develop a substantive interpretation of the overall sensory profile.

Use knowledge of sensory perception and the study context to connect conceptually related characteristics across the relevant perceptual dimensions. When several attributes converge, develop a higher-level interpretation that captures their combined meaning.

Preserve the relative direction and meaning of each attribute. Distinguish higher-level interpretations from directly measured characteristics, and do not present conceptual connections as statistically demonstrated relationships.

Preserve meaningful contrasts, nuances, and ambiguities. When the evidence is heterogeneous or insufficient to support a unified characterization, do not force a single global interpretation.

---

## Identity — unknown

Each stimulus is identified by a code or label that does not reveal its substantive identity. Preserve this original identifier.

Interpret its sensory profile to characterize what makes it distinctive. When supported by a coherent sensory pattern, propose a concise, meaningful sensory name alongside the identifier.

Do not attempt to guess the stimulus's actual identity or force a descriptive name when the profile does not support one.

---

## Task — joint

Interpret the displayed products or stimuli jointly, using their statistical evidence and the user's analytical request.

Characterize each sensory profile, then identify the main similarities, contrasts and, when supported, coherent sensory families across the evaluated set.

Ground comparisons in the displayed sensory profiles, interpreted relative to the average product. Do not present descriptive contrasts as statistically demonstrated pairwise differences between products or stimuli.

---

# Data

[R-derived statistical evidence for all displayed product(s)/stimulus(i): sensory attributes, HIGHER/LOWER directions, adjusted means and any available test statistics.]

---

# Final Interpretation Requirements

Write a clear, well-structured and substantive interpretation of the evaluated sensory profiles.

Support the main conclusions with the most relevant sensory attributes, preserving their HIGHER/LOWER directions. Include adjusted means or other statistical values when they help clarify and substantiate the interpretation.

Avoid mechanically reproducing the statistical results or unnecessary numerical repetition.
```

## Repetition audit — retained observations, no new changes approved

1. **HIGHER / LOWER direction:** `reading` defines the directional terms; `interpretation` requires preserving them and `output` repeats this. Keeping the statistical definition in `reading` is necessary. Consider whether repetition in `output` is useful for smaller LLMs or should be removed.
2. **Relative average product:** the statistical reference is defined in `reading`, restated in `local task` and `joint task`. Some repetition safeguards against fictitious pairwise significance; avoid extra method explanation in `task`.
3. **Higher-level interpretation:** `interpretation` covers combined sensory meanings, nuances and conceptual inferences; identity blocks allow a descriptive characterization or name. Those different responsibilities are not inconsistent.
4. **Joint task:** the caveat prohibiting unperformed pairwise statistical claims is worth retaining, even if `reading` already establishes the reference.
5. **Known/unknown:** anonymous QDA stimuli are not latent constructs. Identifiers are always preserved; `unknown` permits only an additional evidence-grounded descriptive name.
6. **Not food-specific:** the operational interpretation text makes no food-only assumption and applies to sensory evaluations beyond taste, aroma or texture.
7. **Selection policy:** the operational `reading` does not call attention to unprovided attributes or marker-selection parameters. Canonical evidence, prompt-selection metadata, and provenance stay in R.
8. **Approved full reading:** the complete English and French `reading` paragraphs were explicitly approved on 2026-10-14 following review of `adjusted mean`, `v.test`, `p.value`, relative average and the limits of the statistical inferences. No subsequent wording change has been introduced.
9. **Technical requirements:** preserve current R parser/Quarto contracts separately from the editable editorial `output` when integrating.

## Final scientific sign-off — 2026-10-14

The analyst explicitly confirmed the full bilingual `reading` after the four assemblies and repetition review. Thus, each of the four combinations (`known`/`unknown` × local/joint) now uses scientifically approved wording. The relatively short repetitions on HIGHER/LOWER directions, average-product reference and unperformed pairwise tests have **not** been edited: their usefulness can be assessed later with real local-model outputs.

Four configurations are coherent without a detected hard contradiction. This constitutes a **scientific/documentary validation**, not evidence that the new modular prompt has been implemented or operationally tested. Preserve the original R code and its canonical evidence, prompts, accessors, output/parsing and selection contracts until the designated integration phase.
