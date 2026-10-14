# DESCFREQ — assembly and redundancy audit (draft)

**Status:** DRAFT FOR SCIENTIFIC REVIEW — assemblies not yet approved; no R code integration.
**Date:** 2026-10-14
**Source:** [DESCFREQ_MODULAR_PROMPT.md](DESCFREQ_MODULAR_PROMPT.md) (approved bilingual blocks except `reading`, which remains a consolidated candidate with approved row/column terminology).

All assembled English operational paragraphs below are copied from their source blocks without editing. Introduction, analytical request, and statistical data are runtime placeholders. The source reference [DESCFREQ_REFERENCE_PROMPT.md](DESCFREQ_REFERENCE_PROMPT.md) remains the approved long scientific doctrine.

Each combination includes the common `reading`, `interpretation`, one `standard`/`latent` identity block, one local/description/comparison task, and common `output`. When `isolate.groups = TRUE` use local; otherwise `interpretation_mode` determines the joint task. No new identity-mode argument is currently implemented.

## Six assembled prompt candidates

## standard × local

```text
# Introduction

[Original user-provided study introduction — preserved verbatim.]

---

## How to Read the Statistical Evidence

The results come from `FactoMineR::descfreq()` and describe rows of a contingency table through their frequency profiles across columns. Each row is compared with the overall table profile, not with another row.

For each column, the row profile percentage is its count within a row divided by the total count of that row. The global profile percentage is its total count across all rows divided by the total count of the table.

The cell count gives the observed frequency for a particular row and column. The column total gives its frequency across all rows. These counts do not necessarily represent distinct individuals.

OVERREPRESENTED means that a column's row profile percentage is statistically higher than its global profile percentage; UNDERREPRESENTED means statistically lower. Overrepresentation does not imply that a column accounts for the majority of a row or is its most frequent column. Interpret each direction together with both percentages and the available counts.

Statistical distinctiveness does not necessarily imply substantive importance. A column with a low overall frequency can be distinctive without defining the entire row. The displayed evidence may be a selection rather than the complete profile; do not draw conclusions about unreported columns.

Interpret column labels according to their actual meaning, including negations and distinctions between perceptions, intentions, and observed behaviors. Do not infer associations between columns, individual-level relationships, or causal mechanisms from these frequency profiles. Use the study context to understand what the counts represent, without treating it as additional statistical evidence.

---

# Analytical Request

[Original user-provided analytical request — preserved verbatim.]

---

## Interpretation Rules

Interpret each row by considering its displayed statistical characteristics jointly, rather than describing columns one by one. Identify meaningful patterns in its frequency profile, taking into account both what distinguishes the row from the global profile and the relative importance of each column within the row.

Use the study context to develop a substantive synthesis grounded in the displayed evidence. Do not present conceptual connections between columns as statistically demonstrated relationships or causal mechanisms. When the evidence is sparse or points to several distinct themes, describe what it supports without forcing a single global interpretation.

---

## Row Identity — standard

Each row represents an observed entity or category whose identity is already defined. Preserve its original name and any label provided by the analyst.

Interpret its frequency profile to characterize what distinguishes this entity or category, without replacing its known identity with an invented one.

---

## Task — local

Interpret only the row "[row_identifier]" using its displayed statistical evidence and the user's analytical request.

Characterize what distinguishes this row from the overall table profile. Do not describe or compare rows whose evidence is not displayed.

---

# Data

[Selected DESCFREQ evidence for the specified row, with row identities, signed deviations, row/global percentages, and counts.]

---

## Final Interpretation Requirements

Write a clear, substantive interpretation of the displayed frequency profiles.

Support the main findings with the most relevant columns and their row and global percentages or counts, providing enough statistical evidence to make the interpretation understandable and traceable.

Adapt the response to the analytical task: characterize each row in a description, or highlight the main similarities and contrasts in a comparison.

Preserve the original row identifiers and any labels provided by the analyst. Avoid mechanical column-by-column descriptions and unnecessary numerical repetition.
```

---

## standard × description

```text
# Introduction

[Original user-provided study introduction — preserved verbatim.]

---

## How to Read the Statistical Evidence

The results come from `FactoMineR::descfreq()` and describe rows of a contingency table through their frequency profiles across columns. Each row is compared with the overall table profile, not with another row.

For each column, the row profile percentage is its count within a row divided by the total count of that row. The global profile percentage is its total count across all rows divided by the total count of the table.

The cell count gives the observed frequency for a particular row and column. The column total gives its frequency across all rows. These counts do not necessarily represent distinct individuals.

OVERREPRESENTED means that a column's row profile percentage is statistically higher than its global profile percentage; UNDERREPRESENTED means statistically lower. Overrepresentation does not imply that a column accounts for the majority of a row or is its most frequent column. Interpret each direction together with both percentages and the available counts.

Statistical distinctiveness does not necessarily imply substantive importance. A column with a low overall frequency can be distinctive without defining the entire row. The displayed evidence may be a selection rather than the complete profile; do not draw conclusions about unreported columns.

Interpret column labels according to their actual meaning, including negations and distinctions between perceptions, intentions, and observed behaviors. Do not infer associations between columns, individual-level relationships, or causal mechanisms from these frequency profiles. Use the study context to understand what the counts represent, without treating it as additional statistical evidence.

---

# Analytical Request

[Original user-provided analytical request — preserved verbatim.]

---

## Interpretation Rules

Interpret each row by considering its displayed statistical characteristics jointly, rather than describing columns one by one. Identify meaningful patterns in its frequency profile, taking into account both what distinguishes the row from the global profile and the relative importance of each column within the row.

Use the study context to develop a substantive synthesis grounded in the displayed evidence. Do not present conceptual connections between columns as statistically demonstrated relationships or causal mechanisms. When the evidence is sparse or points to several distinct themes, describe what it supports without forcing a single global interpretation.

---

## Row Identity — standard

Each row represents an observed entity or category whose identity is already defined. Preserve its original name and any label provided by the analyst.

Interpret its frequency profile to characterize what distinguishes this entity or category, without replacing its known identity with an invented one.

---

## Task — description

Interpret each displayed row using its own statistical evidence and the user's analytical request.

Characterize what distinguishes each row from the overall table profile. Develop a substantive interpretation of each frequency profile, considering the displayed columns jointly.

Preserve each row's identity. Do not force comparisons between rows when the analytical task is to describe them.

---

# Data

[Selected DESCFREQ evidence for all displayed rows, with row identities, signed deviations, row/global percentages, and counts.]

---

## Final Interpretation Requirements

Write a clear, substantive interpretation of the displayed frequency profiles.

Support the main findings with the most relevant columns and their row and global percentages or counts, providing enough statistical evidence to make the interpretation understandable and traceable.

Adapt the response to the analytical task: characterize each row in a description, or highlight the main similarities and contrasts in a comparison.

Preserve the original row identifiers and any labels provided by the analyst. Avoid mechanical column-by-column descriptions and unnecessary numerical repetition.
```

---

## standard × comparison

```text
# Introduction

[Original user-provided study introduction — preserved verbatim.]

---

## How to Read the Statistical Evidence

The results come from `FactoMineR::descfreq()` and describe rows of a contingency table through their frequency profiles across columns. Each row is compared with the overall table profile, not with another row.

For each column, the row profile percentage is its count within a row divided by the total count of that row. The global profile percentage is its total count across all rows divided by the total count of the table.

The cell count gives the observed frequency for a particular row and column. The column total gives its frequency across all rows. These counts do not necessarily represent distinct individuals.

OVERREPRESENTED means that a column's row profile percentage is statistically higher than its global profile percentage; UNDERREPRESENTED means statistically lower. Overrepresentation does not imply that a column accounts for the majority of a row or is its most frequent column. Interpret each direction together with both percentages and the available counts.

Statistical distinctiveness does not necessarily imply substantive importance. A column with a low overall frequency can be distinctive without defining the entire row. The displayed evidence may be a selection rather than the complete profile; do not draw conclusions about unreported columns.

Interpret column labels according to their actual meaning, including negations and distinctions between perceptions, intentions, and observed behaviors. Do not infer associations between columns, individual-level relationships, or causal mechanisms from these frequency profiles. Use the study context to understand what the counts represent, without treating it as additional statistical evidence.

---

# Analytical Request

[Original user-provided analytical request — preserved verbatim.]

---

## Interpretation Rules

Interpret each row by considering its displayed statistical characteristics jointly, rather than describing columns one by one. Identify meaningful patterns in its frequency profile, taking into account both what distinguishes the row from the global profile and the relative importance of each column within the row.

Use the study context to develop a substantive synthesis grounded in the displayed evidence. Do not present conceptual connections between columns as statistically demonstrated relationships or causal mechanisms. When the evidence is sparse or points to several distinct themes, describe what it supports without forcing a single global interpretation.

---

## Row Identity — standard

Each row represents an observed entity or category whose identity is already defined. Preserve its original name and any label provided by the analyst.

Interpret its frequency profile to characterize what distinguishes this entity or category, without replacing its known identity with an invented one.

---

## Task — comparison

Compare the displayed rows using their statistical evidence and the user's analytical request.

Identify meaningful similarities and differences between their frequency profiles, considering how each row differs from the overall table profile.

Develop a substantive interpretation of the main contrasts while preserving each row's identity. Do not claim statistically significant differences between rows unless direct comparisons have been provided.

Do not infer a progression or hierarchy from the order of the rows alone.

---

# Data

[Selected DESCFREQ evidence for all displayed rows, with row identities, signed deviations, row/global percentages, and counts.]

---

## Final Interpretation Requirements

Write a clear, substantive interpretation of the displayed frequency profiles.

Support the main findings with the most relevant columns and their row and global percentages or counts, providing enough statistical evidence to make the interpretation understandable and traceable.

Adapt the response to the analytical task: characterize each row in a description, or highlight the main similarities and contrasts in a comparison.

Preserve the original row identifiers and any labels provided by the analyst. Avoid mechanical column-by-column descriptions and unnecessary numerical repetition.
```

---

## latent × local

```text
# Introduction

[Original user-provided study introduction — preserved verbatim.]

---

## How to Read the Statistical Evidence

The results come from `FactoMineR::descfreq()` and describe rows of a contingency table through their frequency profiles across columns. Each row is compared with the overall table profile, not with another row.

For each column, the row profile percentage is its count within a row divided by the total count of that row. The global profile percentage is its total count across all rows divided by the total count of the table.

The cell count gives the observed frequency for a particular row and column. The column total gives its frequency across all rows. These counts do not necessarily represent distinct individuals.

OVERREPRESENTED means that a column's row profile percentage is statistically higher than its global profile percentage; UNDERREPRESENTED means statistically lower. Overrepresentation does not imply that a column accounts for the majority of a row or is its most frequent column. Interpret each direction together with both percentages and the available counts.

Statistical distinctiveness does not necessarily imply substantive importance. A column with a low overall frequency can be distinctive without defining the entire row. The displayed evidence may be a selection rather than the complete profile; do not draw conclusions about unreported columns.

Interpret column labels according to their actual meaning, including negations and distinctions between perceptions, intentions, and observed behaviors. Do not infer associations between columns, individual-level relationships, or causal mechanisms from these frequency profiles. Use the study context to understand what the counts represent, without treating it as additional statistical evidence.

---

# Analytical Request

[Original user-provided analytical request — preserved verbatim.]

---

## Interpretation Rules

Interpret each row by considering its displayed statistical characteristics jointly, rather than describing columns one by one. Identify meaningful patterns in its frequency profile, taking into account both what distinguishes the row from the global profile and the relative importance of each column within the row.

Use the study context to develop a substantive synthesis grounded in the displayed evidence. Do not present conceptual connections between columns as statistically demonstrated relationships or causal mechanisms. When the evidence is sparse or points to several distinct themes, describe what it supports without forcing a single global interpretation.

---

## Row Identity — latent

Each row represents a constructed group whose identifier does not define its substantive meaning.

Interpret its frequency profile to identify what makes the group distinctive. When supported by the evidence, propose a concise, meaningful name. Keep the original identifier alongside the proposed name.

Do not force a name when the profile is too heterogeneous or insufficiently informative.

---

## Task — local

Interpret only the row "[row_identifier]" using its displayed statistical evidence and the user's analytical request.

Characterize what distinguishes this row from the overall table profile. Do not describe or compare rows whose evidence is not displayed.

---

# Data

[Selected DESCFREQ evidence for the specified row, with row identities, signed deviations, row/global percentages, and counts.]

---

## Final Interpretation Requirements

Write a clear, substantive interpretation of the displayed frequency profiles.

Support the main findings with the most relevant columns and their row and global percentages or counts, providing enough statistical evidence to make the interpretation understandable and traceable.

Adapt the response to the analytical task: characterize each row in a description, or highlight the main similarities and contrasts in a comparison.

Preserve the original row identifiers and any labels provided by the analyst. Avoid mechanical column-by-column descriptions and unnecessary numerical repetition.
```

---

## latent × description

```text
# Introduction

[Original user-provided study introduction — preserved verbatim.]

---

## How to Read the Statistical Evidence

The results come from `FactoMineR::descfreq()` and describe rows of a contingency table through their frequency profiles across columns. Each row is compared with the overall table profile, not with another row.

For each column, the row profile percentage is its count within a row divided by the total count of that row. The global profile percentage is its total count across all rows divided by the total count of the table.

The cell count gives the observed frequency for a particular row and column. The column total gives its frequency across all rows. These counts do not necessarily represent distinct individuals.

OVERREPRESENTED means that a column's row profile percentage is statistically higher than its global profile percentage; UNDERREPRESENTED means statistically lower. Overrepresentation does not imply that a column accounts for the majority of a row or is its most frequent column. Interpret each direction together with both percentages and the available counts.

Statistical distinctiveness does not necessarily imply substantive importance. A column with a low overall frequency can be distinctive without defining the entire row. The displayed evidence may be a selection rather than the complete profile; do not draw conclusions about unreported columns.

Interpret column labels according to their actual meaning, including negations and distinctions between perceptions, intentions, and observed behaviors. Do not infer associations between columns, individual-level relationships, or causal mechanisms from these frequency profiles. Use the study context to understand what the counts represent, without treating it as additional statistical evidence.

---

# Analytical Request

[Original user-provided analytical request — preserved verbatim.]

---

## Interpretation Rules

Interpret each row by considering its displayed statistical characteristics jointly, rather than describing columns one by one. Identify meaningful patterns in its frequency profile, taking into account both what distinguishes the row from the global profile and the relative importance of each column within the row.

Use the study context to develop a substantive synthesis grounded in the displayed evidence. Do not present conceptual connections between columns as statistically demonstrated relationships or causal mechanisms. When the evidence is sparse or points to several distinct themes, describe what it supports without forcing a single global interpretation.

---

## Row Identity — latent

Each row represents a constructed group whose identifier does not define its substantive meaning.

Interpret its frequency profile to identify what makes the group distinctive. When supported by the evidence, propose a concise, meaningful name. Keep the original identifier alongside the proposed name.

Do not force a name when the profile is too heterogeneous or insufficiently informative.

---

## Task — description

Interpret each displayed row using its own statistical evidence and the user's analytical request.

Characterize what distinguishes each row from the overall table profile. Develop a substantive interpretation of each frequency profile, considering the displayed columns jointly.

Preserve each row's identity. Do not force comparisons between rows when the analytical task is to describe them.

---

# Data

[Selected DESCFREQ evidence for all displayed rows, with row identities, signed deviations, row/global percentages, and counts.]

---

## Final Interpretation Requirements

Write a clear, substantive interpretation of the displayed frequency profiles.

Support the main findings with the most relevant columns and their row and global percentages or counts, providing enough statistical evidence to make the interpretation understandable and traceable.

Adapt the response to the analytical task: characterize each row in a description, or highlight the main similarities and contrasts in a comparison.

Preserve the original row identifiers and any labels provided by the analyst. Avoid mechanical column-by-column descriptions and unnecessary numerical repetition.
```

---

## latent × comparison

```text
# Introduction

[Original user-provided study introduction — preserved verbatim.]

---

## How to Read the Statistical Evidence

The results come from `FactoMineR::descfreq()` and describe rows of a contingency table through their frequency profiles across columns. Each row is compared with the overall table profile, not with another row.

For each column, the row profile percentage is its count within a row divided by the total count of that row. The global profile percentage is its total count across all rows divided by the total count of the table.

The cell count gives the observed frequency for a particular row and column. The column total gives its frequency across all rows. These counts do not necessarily represent distinct individuals.

OVERREPRESENTED means that a column's row profile percentage is statistically higher than its global profile percentage; UNDERREPRESENTED means statistically lower. Overrepresentation does not imply that a column accounts for the majority of a row or is its most frequent column. Interpret each direction together with both percentages and the available counts.

Statistical distinctiveness does not necessarily imply substantive importance. A column with a low overall frequency can be distinctive without defining the entire row. The displayed evidence may be a selection rather than the complete profile; do not draw conclusions about unreported columns.

Interpret column labels according to their actual meaning, including negations and distinctions between perceptions, intentions, and observed behaviors. Do not infer associations between columns, individual-level relationships, or causal mechanisms from these frequency profiles. Use the study context to understand what the counts represent, without treating it as additional statistical evidence.

---

# Analytical Request

[Original user-provided analytical request — preserved verbatim.]

---

## Interpretation Rules

Interpret each row by considering its displayed statistical characteristics jointly, rather than describing columns one by one. Identify meaningful patterns in its frequency profile, taking into account both what distinguishes the row from the global profile and the relative importance of each column within the row.

Use the study context to develop a substantive synthesis grounded in the displayed evidence. Do not present conceptual connections between columns as statistically demonstrated relationships or causal mechanisms. When the evidence is sparse or points to several distinct themes, describe what it supports without forcing a single global interpretation.

---

## Row Identity — latent

Each row represents a constructed group whose identifier does not define its substantive meaning.

Interpret its frequency profile to identify what makes the group distinctive. When supported by the evidence, propose a concise, meaningful name. Keep the original identifier alongside the proposed name.

Do not force a name when the profile is too heterogeneous or insufficiently informative.

---

## Task — comparison

Compare the displayed rows using their statistical evidence and the user's analytical request.

Identify meaningful similarities and differences between their frequency profiles, considering how each row differs from the overall table profile.

Develop a substantive interpretation of the main contrasts while preserving each row's identity. Do not claim statistically significant differences between rows unless direct comparisons have been provided.

Do not infer a progression or hierarchy from the order of the rows alone.

---

# Data

[Selected DESCFREQ evidence for all displayed rows, with row identities, signed deviations, row/global percentages, and counts.]

---

## Final Interpretation Requirements

Write a clear, substantive interpretation of the displayed frequency profiles.

Support the main findings with the most relevant columns and their row and global percentages or counts, providing enough statistical evidence to make the interpretation understandable and traceable.

Adapt the response to the analytical task: characterize each row in a description, or highlight the main similarities and contrasts in a comparison.

Preserve the original row identifiers and any labels provided by the analyst. Avoid mechanical column-by-column descriptions and unnecessary numerical repetition.
```
## Repetition and architecture audit — proposals NOT approved

- `interpretation` says to synthesize columns jointly; the joint-description task repeats substantive synthesis and combined columns. Consider trimming joint-description to scope, each row's own evidence and the prohibition on forced comparisons.
- `reading` defines comparisons to the global table profile; local and description tasks repeat this. Keep enough scope guidance without reproducing statistical doctrine. In comparison, reference to the global table profile is a helpful safeguard against false pairwise significance.
- `output` repeats no column-by-column inventory (`interpretation`), preserve identifiers (identity blocks) and description-vs-comparison objectives (tasks). Consider keeping primarily readability, statistical traceability, and avoidance of numerical repetition.
- An external row order (`rows_are_ordered = TRUE`) may justify describing an evidence-supported gradient, transition, and exceptions; order alone never proves a gradient. Add a conditional instruction if needed, without contradicting the approved comparison task.
- `explicit_row_labels = TRUE` must protect user-defined labels. Reconcile this with the optional naming of latent clusters; new names must not silently replace supplied labels.
- Dynamic evidence-selection disclosures (`drop.negative`, `sample.pct`, `proba`) should correctly identify the scope of shown evidence. A selected positive-only subset must not imply absence of negative deviations.
- Quarto Markdown is a current technical/output contract in the long reference and R code, but not part of the customizable editorial `output`; do not silently drop the technical contract on implementation.
- `global profile` is a statistical reference; `single global interpretation` is the expressly approved conceptual expression. Maintain this distinction.
- None of these simplifications have yet been approved. Preserve approved bilingual blocks until analyst confirmation.
