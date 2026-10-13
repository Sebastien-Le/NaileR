# TEXTUAL compact candidate

**Status: DRAFT — NOT APPROVED**

## Purpose and scope

This is a compact candidate derived from TEXTUAL V1 for a future offline/operational comparison. It is not behaviorally equivalent to V1 until validated. It is provider-independent and does not change `prompt_style` or any runtime contract.

Scope: classic `nail_textual()` and `nail_textual_prep()` only. Contextualized, CATDES/TEXTUAL and multiagent routes are excluded.

## Candidate prompt

````
# Introduction

[Original study introduction, preserved verbatim.]

---

## How to Read the Textual Evidence

The texts shown for this group are the empirical material for a qualitative interpretation. Each displayed text has a mechanically assigned ID linked to a source observation; an observation is not necessarily a distinct individual, and identical wording may occur in several observations.

[Dynamic corpus coverage, sampling settings, selected IDs, and displayed texts.]

Interpret only the texts displayed. A sample may omit themes, minority positions, contradictions, or frequency patterns from the complete corpus. Do not treat an omitted theme as absent, rejected, or irrelevant.

Distinguish occurrences, distinct textual formulations, observations, and individuals. Repetition is not automatically consensus or independent confirmation. Do not invent prevalence estimates.

Preserve the actual strength and meaning of the language, including negations, double negations, litotes, hesitation, conditions, ambiguity, irony when supported, reservations, contradictions, and differences between attitudes, intentions, experiences, and behaviors.

Identify recurring or substantively meaningful themes without forcing homogeneity. Connect related themes into a higher-level frame only when the texts support it. Preserve incompatible frames, tensions, and meaningful minority positions.

Interpretations may go beyond literal wording as grounded analytical syntheses, but must be distinguished from direct respondent statements. Do not infer hidden motives, personality traits, moral qualities, social identities, psychological dispositions, causal mechanisms, or unsupported behaviors.

Adapt specificity to the number and richness of displayed texts. With one or two texts, remain cautious. With no non-empty text, no qualitative profile, theme, coherence judgment, quotation, or text identifier may be invented.

Use the study introduction as context for the research setting and analytical focus, not as an additional observed response.

---

# Overall Analytical Request

[Original user-provided request, preserved verbatim.]

---

## Interpretation Rules

1. Identify the central thematic configuration and explain its substantive meaning.
2. Assess whether a common interpretive frame exists, distinguishing shared frames with variations from coexisting or conflicting frames.
3. Preserve internal diversity, tensions, ambiguities, reservations, contradictions, and minority positions.
4. Assess coherence qualitatively: `strong` means a clearly shared frame with limited divergence; `moderate` means a recognizable frame with notable qualifications; `mixed` means several substantive frames coexist; `weak` means no sufficiently identifiable common frame. Do not treat this as a statistical measure or equate shared vocabulary with agreement. If evidence is absent or too sparse, coherence is not assessable subject to the current output contract.
5. Construct a substantive synthesis grounded in the displayed texts and distinguish direct expression, thematic grouping, and higher-level interpretation.
6. Support principal interpretations with supplied text IDs when required. A representative text illustrates an interpretation; it does not establish prevalence. Never fabricate quotations or references.

---

## Local Scope

Interpret only the displayed group. Do not compare it with groups whose texts are not shown. Multiple returned group interpretations remain separate local interpretations; no automatic global synthesis is implied.

---

# Data

[Automatically generated corpus information and selected textual evidence.]

Preserve the group identifier, text IDs and source links, displayed text content, coverage and sampling information, and the distinction between non-empty, distinct, and displayed texts. Keep canonical `textual_evidence` separate from `interpretation_input`.

---

# Final Interpretation Requirements

[Use the existing route-specific output contract.]

For `nail_textual()`, retain the current structured fields: Core textual profile; Dominant themes; Within-group coherence; Internal diversity; Representative text IDs; Tension text IDs.

For `nail_textual_prep()`, retain its distinct short preparatory synthesis and reusable-output fields. Do not silently add fields or categorical values. No profile is justified for a group without non-empty texts.

Preserve the original introduction, analytical request, and group identifiers. Keep all interpretations proportional to the displayed evidence and compatible with the existing parser.
````

## Preserved methodological content

- Texts are empirical observations; themes, frames and coherence are qualitative constructions by the LLM, not precomputed thematic statistics.
- Text IDs preserve traceability to source observations without guaranteeing distinct respondents.
- `sample.pct` and `seed` affect displayed interpretation input, not canonical evidence; absence from a sample is not absence from the corpus.
- Repeated texts remain separate occurrences but do not establish independent consensus.
- Negations, ambiguity, reservations, contradictions and intensity differences must remain visible.
- Conceptual synthesis is allowed when grounded; unsupported motives, identities, moral traits and causal claims are not.
- Sparse and empty groups require reduced or absent interpretation.
- Local scope is preserved; `isolate.groups = FALSE` does not imply global synthesis.
- The output contracts of `nail_textual()` and `nail_textual_prep()` remain distinct.

## Validation required before approval

Compare this candidate with V1 using identical evidence, context, request, model, provider and sampling. Check canonical-evidence invariance, text-ID traceability, nuanced language, duplicates, sparse groups, empty groups, parser compatibility, local-first behavior, and route-specific output fields. No conclusion of equivalence should be drawn from textual inspection alone.
