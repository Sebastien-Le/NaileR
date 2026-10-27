# T1 — documentation-only modernization of six distributed datasets

## Files

The implementation scope is restricted to `R/datasets.R` and the six generated
pages `man/local_food.Rd`, `man/waste.Rd`, `man/nutriscore.Rd`,
`man/quality.Rd`, `man/atomic_habit.Rd`, and `man/atomic_habit_clust.Rd`.
No data, tests, analytical function or prompt template is changed.

## Editorial decisions

- Ordinary examples are offline previews (`generate = FALSE`) and use the
  public NaileR accessors.
- Real generation is retained only inside `\dontrun{}` and never runs during
  package checks.
- The waste example asks for an evidence-grounded descriptive profile rather
  than an unsupported 0–10 normative wastefulness grade.
- The quality example uses `nail_condes()` and no direct `ollamar::generate()`.
- `atomic_habit_clust` uses the published statistical subset (columns 1:20
  plus `clust`) and does not treat text or derived columns as independent
  CATDES evidence.
- C01 and C02 are referred to as repository validation cases; their local
  files are not embedded in examples.

## Checks

Run `devtools::document()`, extract the six example sections with
`tools::Rd2ex()`, execute them in a clean session, run the targeted tests and
the full suite, then inspect `git diff --check`. Any unrelated Roxygen change
must be reverted or reported separately.
