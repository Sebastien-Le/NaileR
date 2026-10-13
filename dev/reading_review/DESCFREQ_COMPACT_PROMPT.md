# DESCFREQ compact prompt — candidate

**Status: DRAFT — NOT APPROVED**

## Intended use

This is a shortened candidate derived from the approved DESCFREQ V1 reference for future operational experiments, including local models such as `mistral-small3.2`. It is not integrated into NaileR, is not a validated replacement, and must not be treated as a separate scientific doctrine.

## Introduction

[Original user-provided study introduction, preserved verbatim.]

## How to Read the Statistical Evidence

These results come from `FactoMineR::descfreq()` applied to a contingency table. Rows are the entities or profiles being described; columns are counted attributes.

For attribute count `n_ij`, row total `n_i+`, attribute total `n_+j`, and grand total `n_++`: `row profile % = 100 × n_ij / n_i+`; `global profile % = 100 × n_+j / n_++`; `row frequency = n_ij`; `total attribute frequency = n_+j`. The global profile is the whole-table reference, not another row. These are table occurrences, not necessarily distinct individuals.

OVERREPRESENTED means a statistically higher row profile percentage than the global profile percentage; UNDERREPRESENTED means lower. Neither means majority, dominance, absolute frequency, substantive importance, or causality. Read direction with both percentages and available counts.

[Dynamic description of `proba`, `sample.pct`, the selection policy, and `drop.negative`.] Displayed evidence may be only a selected subset. An undisplayed attribute is not automatically absent, average, non-significant, or unimportant. `drop.negative` may make the prompt emphasize positive deviations while canonical evidence remains unchanged. Adapt specificity to the number and diversity of displayed facts.

Interpret labels according to the study. Preserve negations and distinctions among perceptions, descriptions, intentions, preferences, and observed behavior. The introduction supplies context, not statistical evidence.

## Analytical Request

[Original user-provided analytical request, preserved verbatim.]

## Interpretation Rules

- Identify the main displayed over- and underrepresented attributes relative to the global profile.
- Synthesize related displayed facts when they support a coherent higher-level interpretation; label it as interpretation, not as an additional measured frequency.
- Preserve exceptions, contradictions, heterogeneity, and minority patterns.
- Calibrate specificity to evidence quantity and diversity. One marker can support a statistical singularity but generally not an elaborate multidimensional profile.
- Treat rare attributes as potentially distinctive but do not let one sparse signal define a broad sociological, psychological, behavioral, or personality profile.
- Do not infer causality, pairwise significance, individual-level relationships, or universal characteristics from aggregated profiles.
- For joint prompts, descriptive contrasts are allowed; do not claim unreported pairwise tests or infer progression from row order alone.

## Row Identity and Scope Rules

Preserve original row identifiers and user labels. A descriptive name may supplement, not replace, them.

[LOCAL TASK — include only for `isolate.groups = TRUE`.] Interpret only the displayed row and do not describe rows whose evidence is not displayed.

[JOINT DESCRIPTION TASK — include for a joint description.] Characterize every displayed row using its own evidence and preserve exceptions.

[JOINT COMPARISON TASK — include for a joint comparison.] Compare displayed rows descriptively through deviations from the global profile, without unreported pairwise tests. Do not infer a gradient, hierarchy, transition, or temporal trend from order alone.

## Data

[Automatically generated selected DESCFREQ evidence.] Preserve each original row identifier/label, attribute, direction, row profile percentage, global profile percentage, row frequency, and total attribute frequency. Keep canonical profiles distinct from selected prompt evidence.

## Final Interpretation Requirements

Use valid Quarto Markdown. For each displayed row, provide:

1. the main characterization relative to the global profile;
2. supporting attributes and frequencies;
3. a substantive interpretation when sufficiently supported;
4. nuances, exceptions, rare attributes, heterogeneity, and selection limits;
5. an optional descriptive name only when supported.

When evidence is sparse, keep the interpretation limited and state the limitation. For joint comparisons, report supported descriptive contrasts without pairwise significance claims. Preserve the original introduction, request, and row identities. Retain enough numerical support for traceability and preserve the existing output, parser, and reusable-metadata contracts.

## Condensation risks requiring validation

This draft may lose precision about the distinction between occurrences and individuals, the exact selection policy, the status of `p.value` and `v.test`, the difference between joint description and comparison, or the treatment of rare and contradictory attributes. These losses are hypotheses for validation, not accepted changes.
