# SPISE / Distinction 2025–2026: Distinction materials

**Status:** source materials remain `local/private`; the de-identified
48-item teaching object is distributed separately
**Priority:** medium
**Distribution:** local/private pending de-identification

## Sources

The main Distinction materials are under
`/Users/sebastienle/Documents/2025-2026/Survey/`:
the questionnaire XLSX/DOCX/PDF versions, `Distinction.qmd`,
`Distinction_plus.qmd`, `quality.xlsx`, `quality.omv`, `dta.xlsx` and notes.
Related SPISE scripts and exports are under
`/Users/sebastienle/Documents/2025-2026/Spise/` and
`/Users/sebastienle/Documents/2025-2026/Albin/`. These are working subsets
and analysis stages of the same study, not a second independent survey.

## What is established

The files document a Bourdieu-inspired theoretical framing and observed
questions on food practices, territory, accessibility, time and taste. The
large export contains identifiers or quasi-identifiers, including technical
survey fields. A small number of open questions are present, but their
individual sharing status and exact row key require confirmation.

No IRT script or executed IRT result was found in the Distinction materials.
The SPISE IRT/GRM work belongs to the same overall study but must not be
projected onto a Distinction table unless the exact observations and
transformations are demonstrated.

## Candidate NaileR route

After de-identification and a data dictionary, a selected group or class could
be passed through `nail_catdes_prep()` and `nail_catdes()`. A question-level
text corpus could use `nail_textual()`; CATDES + TEXTUAL requires a demonstrated
common population, group mapping and explicit coverage denominators.

## Blocking decisions

Freeze one questionnaire export, remove identifiers, document missingness and
coding, obtain permission for open text, and decide whether the theoretical
constructs are context only or measured variables. Until then no distributed
score, class or open-text object is proposed. The distributed
`spise_distinction_items_2025_2026` object contains only the de-identified
48-item instrument and does not claim to reproduce the full Distinction
export.
