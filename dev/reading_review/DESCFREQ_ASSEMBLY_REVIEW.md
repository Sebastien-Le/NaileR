# DESCFREQ — scientific assembly and redundancy audit

**Status:** SCIENTIFICALLY STABILIZED — all bilingual blocks including complete `reading` and simplifications A/B/C explicitly APPROVED (2026-10-14). Six English documentary combinations assembled; R integration and LLM evaluation not yet performed.
**Date:** 2026-10-14
**Source:** [DESCFREQ_MODULAR_PROMPT.md](DESCFREQ_MODULAR_PROMPT.md) (complete approved bilingual blocks, including `reading`).

All assembled English operational paragraphs below are copied from their source blocks without editing. Introduction, analytical request, and statistical data are runtime placeholders. The source reference [DESCFREQ_REFERENCE_PROMPT.md](DESCFREQ_REFERENCE_PROMPT.md) remains the approved long scientific doctrine.

Each combination includes the common `reading`, `interpretation`, one `standard`/`latent` identity block, one local/description/comparison task, and common `output`. When `isolate.groups = TRUE` use local; otherwise `interpretation_mode` determines the joint task. No new identity-mode argument is currently implemented.

## Six assembled prompt candidates

## standard × local

```text
# Introduction

[Original user-provided study introduction — preserved verbatim.]

---

## How to Read the Statistical Evidence

The results come from `FactoMineR::descfreq()` and describe rows of a contingency table through their frequency profiles across columns. Statistical overrepresentation and underrepresentation are assessed relative to the overall table profile, not through direct pairwise tests between rows. Descriptive comparisons between row profiles remain possible.

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

Support the main findings with the most relevant columns and enough row and global percentages or counts to make the interpretation traceable.

Avoid unnecessary numerical repetition.
```

---

## standard × description

```text
# Introduction

[Original user-provided study introduction — preserved verbatim.]

---

## How to Read the Statistical Evidence

The results come from `FactoMineR::descfreq()` and describe rows of a contingency table through their frequency profiles across columns. Statistical overrepresentation and underrepresentation are assessed relative to the overall table profile, not through direct pairwise tests between rows. Descriptive comparisons between row profiles remain possible.

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

Focus on characterizing each row without forcing comparisons between rows.

---

# Data

[Selected DESCFREQ evidence for all displayed rows, with row identities, signed deviations, row/global percentages, and counts.]

---

## Final Interpretation Requirements

Write a clear, substantive interpretation of the displayed frequency profiles.

Support the main findings with the most relevant columns and enough row and global percentages or counts to make the interpretation traceable.

Avoid unnecessary numerical repetition.
```

---

## standard × comparison

```text
# Introduction

[Original user-provided study introduction — preserved verbatim.]

---

## How to Read the Statistical Evidence

The results come from `FactoMineR::descfreq()` and describe rows of a contingency table through their frequency profiles across columns. Statistical overrepresentation and underrepresentation are assessed relative to the overall table profile, not through direct pairwise tests between rows. Descriptive comparisons between row profiles remain possible.

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

Support the main findings with the most relevant columns and enough row and global percentages or counts to make the interpretation traceable.

Avoid unnecessary numerical repetition.
```

---

## latent × local

```text
# Introduction

[Original user-provided study introduction — preserved verbatim.]

---

## How to Read the Statistical Evidence

The results come from `FactoMineR::descfreq()` and describe rows of a contingency table through their frequency profiles across columns. Statistical overrepresentation and underrepresentation are assessed relative to the overall table profile, not through direct pairwise tests between rows. Descriptive comparisons between row profiles remain possible.

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

Support the main findings with the most relevant columns and enough row and global percentages or counts to make the interpretation traceable.

Avoid unnecessary numerical repetition.
```

---

## latent × description

```text
# Introduction

[Original user-provided study introduction — preserved verbatim.]

---

## How to Read the Statistical Evidence

The results come from `FactoMineR::descfreq()` and describe rows of a contingency table through their frequency profiles across columns. Statistical overrepresentation and underrepresentation are assessed relative to the overall table profile, not through direct pairwise tests between rows. Descriptive comparisons between row profiles remain possible.

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

Focus on characterizing each row without forcing comparisons between rows.

---

# Data

[Selected DESCFREQ evidence for all displayed rows, with row identities, signed deviations, row/global percentages, and counts.]

---

## Final Interpretation Requirements

Write a clear, substantive interpretation of the displayed frequency profiles.

Support the main findings with the most relevant columns and enough row and global percentages or counts to make the interpretation traceable.

Avoid unnecessary numerical repetition.
```

---

## latent × comparison

```text
# Introduction

[Original user-provided study introduction — preserved verbatim.]

---

## How to Read the Statistical Evidence

The results come from `FactoMineR::descfreq()` and describe rows of a contingency table through their frequency profiles across columns. Statistical overrepresentation and underrepresentation are assessed relative to the overall table profile, not through direct pairwise tests between rows. Descriptive comparisons between row profiles remain possible.

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

Support the main findings with the most relevant columns and enough row and global percentages or counts to make the interpretation traceable.

Avoid unnecessary numerical repetition.
```
## Assembly review — decisions confirmed (2026-10-14)

**Approved and incorporated in the six complete assemblies:**

- **A:** Joint-description task focuses on each row separately; statistical reference and synthesis instructions are not repeated.
- **B:** Editable `output` emphasizes substantive writing, traceable evidence and no numerical repetition; no repeated instructions about task mode, identity or column-by-column inventory.
- **C:** `reading` explains the statistical reference as deviations from the global profile rather than tests between rows, and explicitly permits descriptive comparisons.

**Reviewed, unchanged:** `interpretation`, `standard`, `latent`, local task, joint-comparison task. Their bilingual operational paragraphs remain approved as previously recorded in the modular source.

**Outstanding decisions for implementation (not silently introduced into the editable prompt):**

- Explicit conditional guidance for `rows_are_ordered = TRUE`: gradients and transitions only if substantively and statistically supported by the displayed evidence and the contextual order. The approved comparison task warns that order alone is insufficient.
- Preserve analyst labels with `explicit_row_labels = TRUE`, especially when `latent` permits an additional descriptive name.
- Correct dynamic evidence-selection notices for `drop.negative`, `sample.pct`, and `proba`.
- Keep technical Quarto/output parser contracts separate from user-customizable `output` instructions, as in the approved long methodological reference.
- Complete `reading` wording in English and French was explicitly approved on 2026-10-14. It remains unchanged from the assembled text; no further scientific wording approval is pending.
- The six configurations in this file are documentary assemblies, not the prompt currently emitted by the package. No code or existing API is modified.

## Final sign-off (2026-10-14)

The final bilingual `reading` was expressly validated after the A/B/C modifications were accepted and applied. Thus the scientific content of all six combinations (`standard` / `latent` × local / joint description / joint comparison) is stabilized. This is a **documentary scientific sign-off** only, not an assertion that the corresponding prompt-assembly code exists or has passed tests. Retain the long methodological reference as an approved reference and preserve the outstanding conditional implementation checks above.

## Status of repetition audit

The major avoidable repetitions identified in the first review have been removed. Remaining overlaps merit a final read but were preserved to maintain task-specific safeguards:

- `reading` describes the global statistical reference; the local and comparison tasks mention that reference to keep the analysis in scope.
- `interpretation` supplies safeguards about inferring relationships; comparison adds a specific warning against unperformed pairwise significance tests.
- `standard` and `latent` preserve identities; `output` no longer reiterates that requirement.
