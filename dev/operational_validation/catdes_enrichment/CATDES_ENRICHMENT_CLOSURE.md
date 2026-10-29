# CATDES with textual enrichment — closure report

Date: 2026-10-29
Branch: `dev-core5-condes-integration-20261015`
HEAD examined: `61758042ba5aa699f0d4acea2a0271686e9575a1`

## Scope and final status

The CATDES textual-enrichment workflow is technically validated on three real
cases with different purposes:

- `atomic_habit_clust`: technical and scientific review of the two-pass
  workflow, including the limitation of the small 13-person group and the
  distinction between CATDES modalities and open comments;
- `distinction`: complete-sample validation with a three-group exploratory
  classification, including a documented truncated second response;
- `bretons`: subset-specific ACM–HCPC classification, CATDES comparison,
  reproducible comment selection and two successful Gemini passes.

The final status is **technically validated and documented; scientific
interpretation remains provisional and requires researcher review**. The
grounding phase and broader CORE5 UX decisions remain explicitly deferred.

## Bretons data-diffusion decision

The project authority has confirmed that the Bretons data are publishable and
that their inclusion in NaileR is authorized. This decision is recorded as the
project's publication decision for this integration. It covers the public
teaching object `bretons`, including its English `quality_food_open` field.

The package object contains 485 respondents and 105 columns, with the exact
schema of `distinction`, 47 active assertion variables and 485 translated open
responses. It excludes the original source export, the French audit mapping,
and the GC-MS datasets. The English texts are the previously prepared
translations used by `distinction`; no new translation was performed for the
Breton subset.

The public dataset documentation identifies the selection rule (administrative
Brittany postal-code prefixes 22, 29, 35 and 56), the exploratory nature of
the ACM–HCPC groups and the limits on behavioural, causal and regional claims.
The publication decision does not turn the three exploratory groups into a
historically established typology.

## Files integrated or prepared

Documentation and package data:

- `data/bretons.rda` — package dataset, currently untracked pending review;
- `R/datasets.R` — roxygen documentation and executable preview example;
- `man/bretons.Rd` — generated help file.

Operational examples and validation:

- `bretons_case/bretons_user_examples.R` — concise public workflow example;
- `bretons_case/run_bretons_catdes_enrichment.R` — reproducible validation
  script with the existing generation parameters;
- `bretons_case/BRETONS_PACKAGE_READY_STATUS.md` — schema and provenance
  checks;
- `bretons_case/BRETONS_CATDES_SCIENTIFIC_REVIEW.md` — scientific review;
- `bretons_case/BRETONS_CLASSIFICATION_REPORT.md` and
  `BRETONS_VS_DISTINCTION.md` — aggregate comparison reports.

The private ZIP containing selected comments, prompts, responses and RDS files
was intentionally not added to Git.

## Controls completed

- `bretons` installed successfully and loaded with `data(bretons,
  package = "NaileR")`;
- installed-package `bretons` example extracted with `tools::Rd2ex()` and
  executed successfully with `generate = FALSE`;
- ACM–HCPC row order checked explicitly;
- CATDES classic and enriched evidence identical;
- seeded comment selection reproduced exactly;
- public accessors `nail_evidence()`, `nail_prompt()`, `nail_response()` and
  `nail_catdes_enrichment()` exercised;
- targeted tests: 64 PASS in `test-catdes-textual-enrichment.R` and 78 PASS
  in `test-catdes-stage3.R`;
- full `devtools::test()`: completed without reported failures;
- `devtools::document()`: succeeded;
- `tools::checkRd('man/bretons.Rd')`: no issues;
- `git diff --check`: passed.

The package installation was tested in a temporary library. No Gemini call was
made during this documentation/integration phase.

## Check limitation

`devtools::check(document = FALSE)` could not start because the Codex
environment blocked `processx` with:

`Operation not permitted`

This is an infrastructure limitation, not a successful package check. The
result must remain recorded as **not executed to completion**.

## Known limitations and deferred work

- The Gemini wrapper does not preserve provider `finishReason` or token
  counters. Non-empty output is not proof of normal provider termination.
- CATDES group numbers are local identifiers for each exploratory partition.
- Open comments supplement CATDES evidence but do not explain every assertion
  or establish causality.
- The scientific value of labels and cross-dimensional hypotheses still needs
  researcher-led review and, where appropriate, grounding to exact evidence
  and comment IDs.
- No change was made to the CATDES core, prompts, or grounding architecture.

## Git status of this closure

No commit or push has been performed. The package data, generated help and
closure documents remain available for review, while existing unrelated local
changes and temporary artifacts have not been staged.
