# NaileR — Reference workflow without LLM parsing

## Purpose

This directory contains a deterministic reference interpretation of the simulated business dataset.

The statistical and textual evidence registries are produced by NaileR. The semantic claims are written directly as R lists by the analyst. No LLM response and no JSON parser are used.

## What each function contributes

1. `nail_catdes_prep()` creates the complete statistical profiles and evidence IDs.
2. `nail_catdes(generate = FALSE)` exposes the selected evidence and the statistical prompt.
3. `nail_textual_prep(generate = FALSE)` preserves every verbatim and creates stable textual evidence IDs.
4. `nail_textual()` turns validated textual profiles into structured or Markdown reports. In this script, the profiles are written manually rather than parsed from JSON.
5. `nail_textual_contextualized(generate = FALSE)` aligns the statistical and textual evidence and builds the modular prompts.
6. The final `core_analysis` is then written manually and rendered through the same deterministic compatibility and reporting layers.

## What the normal parsed workflow automates

In normal use, the LLM proposes the same kind of claims as those written manually here. The NaileR parser and validators then check the structure, evidence IDs, group membership, relationships and epistemic constraints before creating the final report.

## Main output files

- `02-statistical-evidence-registry.csv`
- `03-textual-evidence-registry.csv`
- `04-textual-report-manual-reference.md`
- `05-combined-evidence-registry.csv`
- `06-manual-reference-claims.csv`
- `07-manual-contextualized-report.md`
- `07-manual-final-result.rds`
- `09-reference-validation-checks.csv`

Output directory: `dev/business_validation_outputs/reference-without-parsing-20260716-201253`
