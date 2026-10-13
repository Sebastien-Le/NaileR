# DESCFREQ V1 — methodological reference

**Status: APPROVED METHODOLOGICAL REFERENCE**

## Status and scope

This document is the approved scientific reference for the DESCFREQ prompt. It specifies the methodological meaning of the evidence and the interpretive limits for contingency-table frequency profiles. It is not a package implementation change and is not yet wired into `nail_descfreq()`.

The reference covers local row descriptions, joint row descriptions, and joint comparisons where those routes are supported by the current API. It preserves the original introduction, analytical request, row identifiers, output format, parser contract, and reusable metadata contract.

## Statistical object

DESCFREQ characterizes rows of a contingency table through row profiles and deviations from the overall table profile. For a cell with count `n_ij`, row total `n_i+`, attribute total `n_+j`, and grand total `n_++`:

- `row profile percentage = 100 × n_ij / n_i+`;
- `global profile percentage = 100 × n_+j / n_++`;
- `row frequency = n_ij`;
- `total attribute frequency = n_+j`.

The global profile is the reference formed by the entire analyzed table; it is not a particular row. These quantities describe table occurrences and need not be proportions or counts of distinct individuals. A statistically overrepresented attribute may remain a minority of a row, and an underrepresented attribute may still account for a substantial part of it.

## Integral approved prompt

The following text is reproduced verbatim from the approved DESCFREQ V1 source. Bracketed items are runtime placeholders or conditional sections; they are part of the specification and are not silently rewritten here.

````
# Introduction

[Original user-provided study introduction, preserved verbatim.]

---

## How to Read the Statistical Evidence

The results below come from `FactoMineR::descfreq()` applied to a contingency table.

Rows represent the entities, categories, or profiles being characterized. Columns represent attributes counted in the table.

The statistical analysis identifies attributes whose relative frequency in a row differs significantly from their relative frequency in the overall table profile.

### Understanding row profiles

For each displayed attribute:

- **Row profile percentage** is the attribute count within the row divided by the total count of all attributes in that row.
- **Global profile percentage** is the attribute count across the entire table divided by the total count of all attributes in the table.
- **Row frequency** is the observed count for that attribute in the specified row.
- **Total attribute frequency** is the attribute's count across all rows.

These values describe the composition of a contingency table.

They are not necessarily percentages or counts of distinct individuals. Their substantive interpretation depends on how the original table was constructed.

### Understanding statistical directions

An attribute is **OVERREPRESENTED** when its relative frequency in a row is statistically higher than its relative frequency in the overall table profile.

An attribute is **UNDERREPRESENTED** when its relative frequency in a row is statistically lower than its relative frequency in the overall table profile.

The global table profile is the statistical reference. It is not another specific row.

Statistical overrepresentation does not imply that an attribute is the majority response, the most frequent attribute, or the main component of the row.

An overrepresented attribute may account for only a small minority of the row's total counts. An underrepresented attribute may still represent a substantial proportion of the row.

Always interpret the statistical direction alongside the row percentage, global percentage, and available counts.

Do not confuse the proportion of a row's counts attributable to an attribute with the proportion of that attribute's total counts contributed by the row.

### Statistical evidence and substantive importance

The displayed attributes have been retained according to the statistical analysis and current evidence-selection settings.

Statistical significance establishes a departure from the corresponding reference under the statistical procedure. It does not by itself establish substantive importance, representativeness, or causal explanation.

When supplied, p.value and v.test describe statistical evidence and standardized deviation. Neither is a direct measure of the attribute's importance for constructing a meaningful profile.

Do not rank the substantive importance of attributes solely by statistical significance, relative overrepresentation, or rarity.

An uncommon attribute may be distinctive without being a dominant characteristic of the row.

### Understanding partial evidence

The displayed results may represent only a selected subset of statistically retained attributes.

[Dynamic description of the actual significance threshold, sample.pct, selection policy, and drop.negative setting.]

An undisplayed attribute must not automatically be considered absent, average, non-significant, or unimportant.

If underrepresented attributes have been excluded, the displayed evidence emphasizes positive deviations. Do not infer that the row has no statistically underrepresented attributes.

Adapt the interpretation to the number and diversity of displayed facts.

When only one or very few attributes are available, characterize the supported statistical singularities without constructing a broader multidimensional profile unsupported by the evidence.

### Meaning of attributes and context

Interpret attribute labels according to their actual meaning in the study.

Preserve negations, reverse-worded expressions, and distinctions between stated perceptions, descriptions, intentions, preferences, and observed behaviors.

Do not transform a descriptive attribute into an individual personality trait, social identity, causal mechanism, or universal characteristic.

The introduction provides scientific context for interpreting the attributes. It is not additional statistical evidence.

Distinguish direct statistical findings, higher-level interpretive synthesis, and broader contextual hypotheses.

---

# Analytical Request

[Original user-provided analytical request, preserved verbatim.]

---

## Interpretation Rules

### 1. Identify the distinctive attributes

Identify the main overrepresented and underrepresented attributes visible in the statistical evidence.

Explain what distinguishes the row relative to the overall table profile.

Preserve the difference between relative distinctiveness and absolute importance within the row.

Do not assume that the most statistically distinctive attribute is necessarily the most substantively important.

### 2. Construct a substantive interpretation

Where several displayed attributes describe related aspects of the same phenomenon, interpret them jointly.

Identify the most meaningful configuration supported by their frequencies, observed counts, substantive meanings, and coherence.

A higher-level interpretation is encouraged when it synthesizes several facts and remains traceable to them.

Such a synthesis is an interpretation of the profile, not an additional measured attribute or statistical result.

Avoid merely listing the attributes one by one when a substantive synthesis is justified.

### 3. Preserve exceptions and heterogeneity

Do not force every displayed attribute into a single coherent narrative.

Identify relevant exceptions, tensions, or contrasting characteristics.

An interpretable profile may remain heterogeneous.

Do not hide a qualifying attribute merely because it complicates the dominant interpretation.

### 4. Calibrate interpretation to evidence availability

The specificity of the interpretation must reflect the number, diversity, and substantive clarity of displayed attributes.

A single marker can establish a relative statistical singularity, but generally cannot establish an elaborate group identity or a multidimensional substantive configuration.

A concise characterization of one well-supported attribute is preferable to an invented broader profile.

Do not manufacture supporting attributes to satisfy an expectation of synthesis.

### 5. Interpret rare attributes cautiously

A rare or sparsely represented attribute may be statistically distinctive and scientifically informative.

Consider its within-row percentage, observed count, and substantive meaning before assigning it a central interpretive role.

Do not dismiss rare attributes automatically.

However, do not use one rare attribute alone to infer an extensive sociological, psychological, behavioral, or personality profile.

### 6. Preserve inferential limits

The statistical characterization compares row profiles with the global table profile.

It does not establish causality.

Do not infer associations between attributes from their separate marginal frequencies.

Do not infer individual-level relationships or universal characteristics from aggregated frequency profiles.

When several rows are displayed, descriptive contrasts are permitted, but unreported pairwise statistical significance must not be claimed.

---

## Row Identity and Scope Rules

### Row identity

Preserve the original row identifiers and any user-provided row labels.

These labels provide context and are not additional statistical evidence.

A descriptive name may supplement an original identifier when the evidence supports it.

Do not replace an existing identity or force a new name for a sparsely characterized row.

### LOCAL TASK — One displayed row

[Include only when isolate.groups = TRUE.]

Interpret only the row displayed below.

Characterize its relative-frequency profile using the available evidence and the overall analytical request.

Explain its main statistical singularities and, where sufficiently supported, their substantive meaning.

Do not describe, compare, or infer the profiles of rows whose evidence is not displayed.

### JOINT DESCRIPTION TASK — Several rows

[Include when the selected task is a joint description.]

Characterize every displayed row using its own statistical evidence.

Identify meaningful distinctive attributes, related patterns, and qualifying exceptions.

Preserve each original row identifier.

Do not impose a common interpretive structure if the rows do not support one.

### JOINT COMPARISON TASK — Several rows

[Include when the selected task is a joint comparison.]

Compare the displayed rows descriptively using their deviations from the global table profile.

Identify supported similarities, contrasts, and broader configurations.

Do not claim unreported pairwise statistical significance.

Do not infer a progression, hierarchy, transition, or temporal gradient solely from the ordering of rows.

An ordered interpretation is permitted only when the study context and displayed evidence justify it.

---

# Data

[Automatically generated selected DESCFREQ evidence.]

For each displayed row, preserve:

- Original row identifier and label.
- Attribute identity.
- Statistical direction.
- Row profile percentage.
- Global profile percentage.
- Row frequency.
- Total attribute frequency.

[Include additional statistical information only if authorized by the validated evidence policy.]

Row totals and overall table totals may be displayed when supported by a future validated evidence-presentation policy. Their absence must not invite the LLM to invent them.

The canonical statistical profiles and the evidence selected for interpretation must remain distinct.

---

# Final Interpretation Requirements

Produce a substantive, evidence-grounded interpretation rather than a mechanical inventory of attribute frequencies.

For each displayed row, provide:

1. **Main characterization** — what distinguishes the row relative to the overall table profile.
2. **Supporting evidence** — the attributes and relative frequencies supporting that characterization.
3. **Substantive interpretation** — the meaning of the configuration when sufficient evidence is available.
4. **Nuances and limitations** — important exceptions, rare attributes, heterogeneity, and limitations due to evidence selection.
5. **Optional descriptive name** — only when the available evidence supports a meaningful characterization.

When the displayed evidence is sparse, produce a limited interpretation and explicitly avoid unsupported synthesis.

For joint comparisons, identify the main supported contrasts between rows without claiming unreported pairwise statistical tests.

Preserve the analyst's original introduction, analytical request, and row identities.

Avoid unnecessary numerical repetition, but retain enough statistical support to make each interpretation traceable.

Preserve the existing NaileR output-format, parser, and reusable-metadata contracts.

The output must use valid Quarto Markdown.
````

## Runtime sections and route mapping

The reference uses the following dynamic components:

| Reference section | Runtime content | Local route | Joint description | Joint comparison |
| --- | --- | --- | --- | --- |
| Introduction | Original study context, preserved verbatim | included | included | included |
| How to Read the Statistical Evidence | Method-specific reading and dynamic selection settings | included | included | included |
| Analytical Request | Original user request, preserved verbatim | included | included | included |
| Interpretation Rules | Shared epistemic and substantive rules | included | included | included |
| Row Identity and Scope Rules | Local identity or joint task scope | one displayed row only | every displayed row | descriptive contrasts only |
| Data | Selected semantic-facing DESCFREQ evidence | selected row | selected rows | selected rows |
| Final Interpretation Requirements | Required facts, interpretation, limits, names, and Quarto output | local | joint description | joint comparison |

`isolate.groups = TRUE` maps to the local route: the prompt must characterize only the displayed row. `isolate.groups = FALSE` maps to a joint prompt. The joint task is either description or comparison according to `interpretation_mode`; a comparison remains descriptive and does not create unreported pairwise tests.

Row identifiers and explicit user labels remain identities. A descriptive name can supplement an identifier only when supported; it cannot silently replace an original name. `rows_are_ordered` permits discussion of a gradient only when context and displayed evidence support it. Order alone is not evidence. `explicit_row_labels` protects supplied labels from renaming.

## Evidence selection and statistical limits

`proba` is the significance threshold passed to `FactoMineR::descfreq()`. The statistical result is produced by FactoMineR; the prompt does not recompute it. `sample.pct` selects a deterministic proportion of eligible retained markers for prompt evidence: zero selects none, while positive values use the canonical ranking and the corresponding ceiling count. When both directions are eligible and at least two slots are available, the current policy preserves one strongest marker from each direction before filling remaining slots by rank. `drop.negative = TRUE` removes underrepresented markers from prompt selection only.

The canonical frequency profiles and evidence registry are distinct from the selected semantic-facing evidence. Changing `sample.pct`, `drop.negative`, route, task, introduction, request, or conclusion must not change the canonical statistical object. An undisplayed marker is not thereby absent, non-significant, or unimportant. Sparse displayed evidence limits the specificity of the permitted interpretation; one marker may support a singularity but generally cannot support an elaborate multidimensional identity.

Rare attributes must neither be discarded automatically nor allowed to define a broad profile without sufficient convergent support. Statistical significance, frequency, rarity, and substantive importance are different concepts. Separate marginal frequencies do not establish associations between attributes, individual-level relationships, causality, or universal characteristics.

## Output and implementation boundary

The approved reference requires valid Quarto Markdown and preserves the existing NaileR output, parser, reusable-metadata, and accessor contracts. It distinguishes direct statistical facts, higher-level synthesis, and broader contextual hypotheses.

The current implementation is intentionally not changed by this PASS. In particular, the current `nail_descfreq()` reading, semantic-facing evidence, selection logic, builders, arguments, and return objects remain the source of currently executed behavior. This document is a future methodological specification: it is more explicit than the current runtime prompt about denominators, occurrences versus individuals, evidence sparsity, rare attributes, and the limits of comparisons.

Current implementation facts relevant to this boundary:

- one `FactoMineR::descfreq()` analysis produces the canonical profiles;
- semantic-facing facts expose row/global percentages and counts, but not `p.value`, `v.test`, or evidence IDs;
- `nail_evidence()` exposes the canonical artifact;
- local prompts are one per row; joint prompts contain all selected rows;
- `interpretation_mode = "description"` and `"comparison"` are joint-task distinctions in the current builder, while the local route is row-focused;
- no prompt integration of this approved V1 is performed here.

## Scientific status

V1 is the approved methodological reference. Its future implementation must be preceded by a targeted comparison against the currently executed prompt and by operational validation. The compact document in this directory is a draft and is not an alternative approved doctrine.
