# Reconstruction status of existing transition studies

Review date: 2026-10-27
NaileR reference: `dev-core5-condes-integration-20261015` at the local
validation baseline `48b6967b45613f535d4b8b75d541d0dd84328d95`.

This is a focused reconstruction report, not a new inventory. No LLM was
called and no individual response is reproduced.

| Case | Status | NaileR route | Main decision still required |
|---|---|---|---|
| IRTSAT 2024–2025 | `validated` for the distributed frozen export | `nail_condes()` on the retained IRT score; `nail_catdes()` on the frozen four-profile table | Preserve the caveat that the visible three-centre script is not the final classification and document the source-order alignment |
| SPISE / Distinction 2025–2026 | `reconstructible mais non diffusable en l'état` | `nail_catdes_prep()`/`nail_catdes()` on a de-identified selected table; `nail_condes()` on documented scores; text routes only after authorization | Treat SPISE and Distinction as one study with distinct subsets/analysis stages; freeze the canonical export, transformations and rights |
| MASHS ideal food system 2023–2024 | `validated` for the distributed de-identified export | MCA/HCPC → `nail_catdes()` | Keep this Q-sort-like questionnaire distinct from the separate MASHS logo study and retain numeric group identifiers |
| ProjetSystAlimED 2023–2024 | `retrouvée mais incomplète` | `nail_catdes_prep()`/`nail_catdes()` after a justified join | Resolve the 576/586 discrepancy, duplicate IDs and the 536-row join |
| C01 `local_food` | `retrouvée et reconstructible` and technically validated | MCA/HCPC → `nail_catdes()` | Keep the exploratory semantic review distinct from a general superiority claim |
| C02 `atomic_habit_clust` | `retrouvée et reconstructible` for offline preparation; semantic generation blocked/unfinished | MFA/HCPC reference → `nail_catdes()` | Preserve the published 84/13/70 classes and obtain a scientific decision on private text use |

## IRTSAT 2024–2025

Source directory:
`/Users/sebastienle/Documents/2024-2025/Traitement de Données Enquêtes/IRTSAT/`.
The visible analysis reads `data_536.csv`, treats columns 3:50 as 48 ordered
Likert items, groups them into six blocks of eight, fits graded models with
`mirt()`, extracts `fscores()`, rescales scores, and runs seeded k-means with
three centres. The current scientific decision is four profiles: disengaged
territorial, distant consumers, pragmatic involved consumers, and territorial
activists. The latter decision must not be silently replaced by the visible
three-centre script.

The distributed object `irtsat_2024_2025` is the frozen 529-row export used for
the package preview. It contains the retained IRT score, 34 categorical
descriptors and the four-level profile assignment; no direct personal key is
distributed. The score and profile are aligned by the retained workspace row
order. The object was checked with `nail_condes()` on the score/descriptors
table and with `nail_catdes()` on the four-profile table, both offline.

The visible three-centre script remains a historical or illustrative route and
must not be presented as the final scientific classification. The frozen
export does not claim to reconstruct every upstream IRT fitting choice.

## SPISE / Distinction 2025–2026

SPISE and Distinction are two names used for the same 2025--2026 study. The
working files are distributed across `/Users/sebastienle/Documents/2025-2026/Spise/`,
`Survey/` and related `Albin` material. The names identify different subsets,
questionnaire exports or analysis stages, not two independent surveys.

The questionnaire and Quarto analyses are retrievable, but some exports
contain identifiers or quasi-identifiers (including technical survey fields).
No IRT execution was found in the Distinction survey materials. The
Bourdieu-based framework is theoretical context, not a measured latent
variable by itself.

The local route is technically plausible after de-identification: select a
documented set of attitudes/practices, derive a classification only with a
recorded rule, and pass the resulting table to `nail_catdes()`. Open text can
reach `nail_textual()` or `nail_catdes_textual()` only after consent,
individual matching, and denominator rules are documented.

## SPISE / Distinction working subsets

The SPISE working subset is in `/Users/sebastienle/Documents/2025-2026/Spise/`, principally
`data/Bretons.xlsx` (182 rows, 81 columns, 48 Likert items). The diagnostics,
GRM/mirt scripts, model registry, item parameters, fit, information, local
dependence and scores are present. This establishes executed IRT work, but not
one final psychometric model. `Bretons_no_NA.xlsx` is a derived 181-row file
and is not the same source.

The same study also appears in the Distinction questionnaire and Quarto
materials. These materials must be compared as subsets or processing stages,
not treated as an independent second survey. A future NaileR case should use
a frozen, documented table and `nail_condes()` in latent mode, or
`nail_catdes()` after a canonical classification is selected. The six blocks
and their labels are useful context, but the available diagnostics do not by
themselves validate a single global continuum. The data remain local pending
rights and extraction documentation.

## MASHS ideal food system

The 2023--2024 MASHS study concerns opinions about an ideal food system. Its
working protocol is Q-sort-like, while the retained computational route is
MCA followed by HCPC. The distributed object `mashs_food_system` contains 573
rows, 60 categorical questionnaire responses and the four-level constructed
group identifier `clust` (226/113/116/118). Demographic columns were omitted
from the package object. The object was checked with `nail_catdes()` offline;
the group identifiers are preserved without replacing them by substantive
names.

The study is separate from the MASHS logo analysis described below and must
not be conflated with the package dataset `quality`.

## MASHS logos

`/Users/sebastienle/Documents/2023-2024/MASHS/quality/Analyse_logos.R`
reads the 2024 workbook, removes two metadata rows, runs PCA and HCPC with
three groups (15/8/32), then uses CONDES and CATDES. The package `quality`
object has 55 rows and nine numeric logo ratings. The local preparation is
reconstructible and the package documentation now uses the public NaileR
preview/accessor route rather than a direct backend call.

The historical workbook and package object must still be related by an
explicit provenance statement. Abbreviated logo names are not expanded into
new scientific meanings without the original codebook.

## ProjetSystAlimED

The sources are in
`/Users/sebastienle/Documents/2023-2024/Traitement de données d'enquêtes/ProjetSystAlimED/`.
The scripts visibly use MCA → HCPC → CATDES and the Q-sort protocol is not a
classical Q-method factor extraction. `Base_K.xlsx`, `Base_F.xlsx` and the
saved RData do not yet provide a justified common row key: row counts differ,
duplicate IDs occur, and the saved snapshot has a different missingness
pattern. No NaileR object is prepared until that join is resolved.

## C01 and C02

C01 uses the distributed `local_food` object and a seeded three-group
MCA/HCPC route. Its technical/statistical evidence and Gemini material are
already archived under `dev/operational_validation/corpus/C01_local_food/`.
C02 uses `atomic_habit_clust` with groups 84, 13 and 70 and a 63-marker
reference under `dev/operational_validation/corpus/C02_atomic_habit/`.

For C01, the semantic review remains exploratory and includes a documented
truncated response. For C02, the statistical preparation is validated offline;
the small group and the individual text columns require privacy and alignment
controls before any composition experiment. Neither case licenses causal or
behavioural claims.

## Current reproducible actions

Run `Rscript dev/transition_reconstruction/verify_reconstructible_cases.R`
from the repository root. It reads external files and package data, reports
dimensions and the MASHS PCA/HCPC group sizes, and exits non-zero if a known
structural invariant fails. It does not write output files or call a provider.

## Decisions required from the scientific owner

1. Freeze the IRTSAT export, four-group class table and model-selection record.
2. Approve the de-identification and distribution policy for Survey/Distinction,
   SPISE and individual Atomic Habits texts.
3. Confirm the historical MASHS workbook/package `quality` relationship and
   citations.
4. Resolve the ProjetSystAlimED join before any group interpretation.
