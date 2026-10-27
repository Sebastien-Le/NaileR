# Read-only reconstruction and T1 verification run

Date: 2026-10-27
Repository branch: dev-core5-condes-integration-20261015
HEAD: b257e708cd437343b35d7e3d35ed3c153905664d

## Reconstruction script

Command:

    Rscript --vanilla dev/transition_reconstruction/verify_reconstructible_cases.R

Observed checks:

| Check | Result |
|---|---|
| Installed package cases: local_food, waste, nutriscore, quality, atomic_habit, atomic_habit_clust | PASS; dimensions match the documented objects and no missing values were found |
| IRTSAT/data_536.csv | PASS; 536 x 56, candidate item block 3:50 has 48 columns |
| Survey / Distinction export | PASS for structural reading; 1229 x 116 first sheet; raw identifiers were not printed or copied |
| SPISE/data/Bretons.xlsx | PASS; 182 x 81; candidate item count 48 |
| MASHS logos | PASS; identifier columns removed as in the historical script, 55 x 9, PCA/HCPC route gives 15/8/32 with ncp = 6 |

The script only reads source files and computes the existing MASHS
preparation in memory. It writes no files and does not call a provider.

## T1 documentation checks

The six ordinary examples were extracted with tools::Rd2ex() and executed
in separate R sessions after devtools::load_all():

- local_food: PASS;
- waste: PASS;
- nutriscore: PASS;
- quality: PASS;
- atomic_habit: PASS;
- atomic_habit_clust: PASS.

tools::checkRd() passed for all six generated pages. The full
devtools::test(reporter = "summary") suite completed without a failure.
The only message was the local environment warning that testthat had been
built under R 4.4.3.

No LLM was called. The quality example now uses nail_condes() and public
accessors; its optional generation remains in \\dontrun{}. The waste example
no longer requests a normative 0–10 wastefulness grade.
