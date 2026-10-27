# Survey / Distinction 2025–2026

**Status:** `reconstructible mais non diffusable en l'état`
**Priority:** medium
**Distribution:** local/private pending de-identification

## Sources

The main files are under `/Users/sebastienle/Documents/2025-2026/Survey/`:
the questionnaire XLSX/DOCX/PDF versions, `Distinction.qmd`,
`Distinction_plus.qmd`, `quality.xlsx`, `quality.omv`, `dta.xlsx` and notes.
Related scripts and exports are under `/Users/sebastienle/Documents/2025-2026/Albin/`.

## What is established

The files document a Bourdieu-inspired theoretical framing and observed
questions on food practices, territory, accessibility, time and taste. The
large export contains identifiers or quasi-identifiers, including technical
survey fields. A small number of open questions are present, but their
individual sharing status and exact row key require confirmation.

No IRT script or executed IRT result was found in the Survey project. SPISE
is a related but separate execution context and must not be used to claim that
this survey already ran IRT.

## Candidate NaileR route

After de-identification and a data dictionary, a selected group or class could
be passed through `nail_catdes_prep()` and `nail_catdes()`. A question-level
text corpus could use `nail_textual()`; CATDES + TEXTUAL requires a demonstrated
common population, group mapping and explicit coverage denominators.

## Blocking decisions

Freeze one questionnaire export, remove identifiers, document missingness and
coding, obtain permission for open text, and decide whether the theoretical
constructs are context only or measured variables. Until then no distributed
object is proposed.
