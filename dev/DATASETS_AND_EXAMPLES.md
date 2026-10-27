# NaileR — Datasets and scientific examples register

Date of review: 2026-10-27
Reference branch: `dev-core5-condes-integration-20261015`
Reference commit: `d6c5205d587efd561f85de2e3dd3467fd6122bb9`

This register records the datasets and examples that can support NaileR
demonstrations. It separates technical availability from scientific review and
publication rights. A successful data load, prompt preview, or LLM generation
is not by itself a scientific validation.

No LLM was called for this review. The nine package datasets were loaded from a
real installed NaileR package built from the reference branch. The installed
package was checked with R 4.4.2 on macOS 26.6.2. The nine objects covered by
this register loaded successfully and contained no missing values in the
installed copies.

## Status vocabulary

The following lifecycle states are used in this document:

- `identified`: a candidate is located, but its structure or provenance is not
  sufficiently characterized;
- `prepared`: sources, transformations, or a reproducible analysis plan are
  available;
- `validated_offline`: the stated offline technical checks have been executed;
- `scientifically_reviewed`: the specified scientific interpretation has been
  reviewed, with its limits recorded;
- `distributed`: a dataset is present in the package `data/` directory;
- `installed_and_tested`: the dataset was loaded from an installed package and
  its documented access path was checked;
- `blocked`: a provenance, privacy, rights, alignment, or scientific decision
  prevents responsible progression.

These states are not mutually exclusive. For example, a dataset can be both
`distributed` and `installed_and_tested` while its associated scientific case
remains only `prepared`.

## Executive matrix

| Study / object | Theme and observed unit | Dimensions and verified structure | Package status | NaileR candidates | Technical status | Scientific / rights status |
|---|---|---|---|---|---|---|
| `local_food` | Sustainable food-system representations and opinions; participants | 573 × 63; all factors; 45 acceptability statements, 14 opinion statements, 4 contextual variables; no NA | `distributed`, `installed_and_tested` | `nail_catdes_prep()`, `nail_catdes()`; possible future TEXTUAL only with an approved text corpus | C01 technical/statistical workflow validated; 314-marker reference and A/B/C invariance checked | C01 exploratory semantic review completed; not a general prompt-superiority claim. Provenance to historical files remains separate from package availability |
| `mashs_food_system` | Same ideal-food-system survey as `local_food`, in a distinct prepared representation | 573 × 61; 59 response variables, `Age`, and `clust`; four groups 226/113/116/118; no NA | `distributed`, `installed_and_tested` | `nail_catdes()` on the retained four-group table | Offline preview and installed-package checks validated | Teaching representation; group identifiers are preserved and are not substantive names |
| `irtsat_2024_2025` | IRTSAT local-food practices and representations | 529 × 36; `IRT_score`, 34 categorical descriptors and four-level `profile`; no NA | `distributed`, `installed_and_tested` | `nail_condes()` on the score and `nail_catdes()` on the frozen profile table | Offline previews, tests and installed-package checks validated | Four profiles are retained; historical names are not asserted as verified code mappings |
| `irtsat_items_2024_2025` | IRTSAT questionnaire instrument | 541 × 48 ordered factors; six blocks of eight items; 14 item-level NA; English variable names and levels | `distributed`, `installed_and_tested` | Instrument inspection; no CATDES without an external documented grouping | Item structure and English presentation validated offline | Independent item export; no validated row key to the 529-row profile table |
| `waste` | Food-waste attitudes, self-reported habits, disposal reasons and context | 180 × 77; all factors; no NA; one constant item is removed in the historical MCA example | `distributed`, `installed_and_tested` | MCA/HCPC → `nail_catdes_prep()` / `nail_catdes()` | Dataset load verified; historical example is not yet a current offline validation case | Rights and exact questionnaire provenance require confirmation; self-reports are not observed behavior |
| `nutriscore` | Perceptions of the Nutri-Score and eating habits | 112 × 36; all factors; no NA; documentation treats columns 17:36 as supplementary/contextual | `distributed`, `installed_and_tested` | MCA/HCPC → `nail_catdes()` | Dataset load verified; historical example is not yet a current offline validation case | Rights/provenance and question coding should be confirmed before scientific reuse |
| `quality` | Perceived quality associated with nine food logos | 55 × 9; tibble/data.frame; nine numeric scores; ranges are observed in the package object and are not recoded | `distributed`, `installed_and_tested` | PCA/HCPC → `nail_condes()` and `nail_catdes()` | Historical MASHS pipeline is documented; current help example needs API modernization | Historical source and reuse status need explicit confirmation; no normative quality score should be requested without a validated criterion |
| `atomic_habit` | Declared capacity and perceived restrictiveness of ecological habits, with explanations | 167 × 50; 10 binary capability factors, 10 numeric 0–5 restrictiveness variables, 10 binary variables, 10 text columns, 10 derived composite factors; no NA | `distributed`, `installed_and_tested` | MFA/HCPC upstream; `nail_textual()` and `nail_catdes_textual()` only with privacy and alignment controls | Source object loaded and structurally checked; C02 uses its first 20 variables for the statistical reference | Texts are individual responses and remain unsuitable for the shareable corpus without a privacy decision. Capability is declared, not observed behavior |
| `atomic_habit_clust` | Same questionnaire with a published three-level constructed classification | 167 × 51; same 50 columns plus factor `clust`; group sizes 84/13/70; no NA | `distributed`, `installed_and_tested` | `nail_catdes_prep()`, `nail_catdes()`; future composition after alignment review | C02 prepared and technically validated offline; 63 selected markers and four previews are archived | Status `ready_for_validation`; historical AFM route unresolved, group 2 is small, and no semantic LLM validation is currently claimed |

## Package datasets: verified structures

### `local_food`

The installed object is a 573 × 63 data frame with 63 factor columns and no
missing values. Columns 1–45 are full English statements about a sustainable
food system. Columns 46–59 are opinion or constraint statements. Columns
60–63 are age, marital status, city size, and socio-professional category.
The five-level response scales and the contextual factor levels are preserved
as distributed. The package documentation describes an MCA with columns 46:63
as supplementary variables and an HCPC classification. The C01 validation
uses the package object and a published three-group classification; it does
not claim that the package object is byte-identical to every historical
questionnaire export.

The appropriate interpretation is about configurations of declared
acceptability and opinions. It must not be rewritten as a description of
individual behavior or as a causal explanation of food-system choices.

`local_food` and `mashs_food_system` share the same 573 participants and the
same first 60 variable names, but they are not identical encodings. Their
factor levels and values reflect different preparation steps. `local_food`
retains the participant-level table with four contextual variables and is used
by the C01 three-group MCA/HCPC example. `mashs_food_system` retains 59
response variables, `Age`, and a frozen four-group identifier, and is intended
to illustrate a second CATDES route. The two objects should therefore be
presented as complementary representations of the same survey, not merged or
treated as interchangeable raw exports.

### `mashs_food_system`

This de-identified object contains 573 rows, 59 categorical response
variables, `Age`, and the four-level constructed identifier `clust`. The
historical group sizes are 226, 113, 116 and 118. The retained computational
route is MCA followed by HCPC; the questionnaire protocol was Q-sort-like but
this object is not presented as the result of a classical Q-method factor
analysis. The ordinary example uses `nail_catdes(generate = FALSE)` and the
public `nail_evidence()` and `nail_prompt()` accessors.

The four `clust` values remain numeric identifiers. Historical profile names
are not embedded as validated semantic labels.

### `irtsat_2024_2025`

This frozen de-identified table contains 529 observations and no missing
values. `IRT_score` is the retained score, the 34 following variables are
categorical descriptors, and `profile` is the four-level profile identifier.
The table is suitable for a CATDES preview on `profile` and for a CONDES
preview on the score after excluding the profile column. The historical
three-centre k-means script is not used as the final classification.

The current profile-level strings are preserved as distributed identifiers.
The historical names “Territorially disengaged”, “Distant consumers”,
“Pragmatic involved consumers” and “Territorial activists” are listed only as
separate historical labels; this documentation does not assert their exact
correspondence to the current codes.

### `irtsat_items_2024_2025`

This independent object contains the 48 assertions used in the IRTSAT
instrument for 541 respondents. The assertions are grouped into six blocks of
eight and retain 14 missing responses. Variable names and Likert response
levels are in English; the exact French wording is preserved in the local
dictionary `dev/transition_reconstruction/IRTSAT_48_ITEMS_DICTIONARY.csv`.
Timestamp, region and complementary questionnaire fields are excluded.

There is no validated common key between these 541 rows and the 529-row
profile table. The item object is therefore suitable for instrument-oriented
teaching and data inspection, but must not be joined to `irtsat_2024_2025` by
row order or used for profile CATDES without a separately documented grouping
variable.

### `spise_distinction_items_2025_2026`

This de-identified object contains 181 complete responses to the same
48-item food-transition instrument in the SPISE / Distinction study. The six
blocks and the English Likert levels are retained, while the source respondent
identifier and auxiliary context/choice fields are excluded. It is a clean
instrument export for teaching and inspection, not an IRT score table and not
a classification. The source and reconstruction script are documented in
`dev/transition_reconstruction/SPISE_2025_2026.md` and
`dev/transition_reconstruction/build_spise_distinction_data.R`.

Because SPISE and Distinction refer to one study represented by several
stages, this object must not be treated as a second survey or joined to a
Distinction table without a demonstrated row key and transformation history.

### `waste`

The installed object is a 180 × 77 factor data frame with no missing values.
The columns are full questions covering perceived environmental impact,
disposal practices and reasons, shopping channels, information sources,
readiness to change, and demographic/contextual variables. One historical
item has only one observed level; the existing example removes column 14
before MCA. This is a data-quality fact to document, not a reason to silently
alter the distributed object.

The current example proposes an ordinal grade from 0 to 10 for how wasteful a
group is. That request is not supported by a validated statistical scale in
the package and should be replaced in a future documentation lot by a
descriptive, evidence-grounded request.

### `nutriscore`

The installed object is a 112 × 36 factor data frame with no missing values.
The first 16 variables concern perceptions and uses of the Nutri-Score; the
remaining variables cover demographics and eating practices. The existing
MCA example uses columns 17:36 as supplementary variables, followed by HCPC
and CATDES. This is a plausible pedagogical workflow, but its scientific
interpretation remains descriptive and should preserve the distinction between
views about the label and actual dietary behavior.

### `quality`

The installed object is a 55 × 9 tibble/data frame containing nine numeric
logo scores. The observed ranges are: `AB` 3–10, `LabelRouge` 3–10,
`FairTrade` 2–10, `BleuBlanc` 2–10, `AOC` 5–10, `PdtBretagne` 2–10,
`ViandesFrance` 0–9, `SansOGM` 0–9, and `MedaillesAgro` 1–10. The package
object contains no factor labels or missing values. The historical MASHS
analysis describes a PCA, HCPC and CATDES/CONDES workflow on these nine
ratings, with three HCPC groups of sizes 15, 8 and 32 in the saved analysis.

The abbreviated column names are not full scientific definitions. The
documentation lists the logo meanings, but the example should be checked
against the original codebook before being presented as a fully reproducible
scientific case.

### `atomic_habit` and `atomic_habit_clust`

Both objects contain the same 50 questionnaire columns in the same order.
The first ten factors record declared ability for specific changes; columns
11–20 are numeric restrictiveness scores on [0, 5]; columns 21–30 are binary
restrictiveness variables; columns 31–40 are non-empty character responses;
and columns 41–50 are derived ability/restrictiveness combinations.

`atomic_habit_clust` adds the factor `clust` with levels 1, 2 and 3 and sizes
84, 13 and 70. The C02 statistical reference intentionally uses columns 1:20
plus `clust`; text columns, binary copies and derived composites are not
independent statistical evidence. The group labels are identifiers for
constructed groups, not substantive names.

## Current examples and required documentation work

The existing dataset help pages are useful historical starting points but are
not yet a uniform public workflow.

| Help page | Current pattern | Issue / proposed T1 action | Offline status in this review |
|---|---|---|---|
| `local_food` | MCA/HCPC, then `nail_catdes()` with custom context | Retain the C01 protocol parameters and use public accessors; clarify that C01 is not reproduced if parameters are simplified | Data installed; C01 case already validated offline and technically end-to-end |
| `mashs_food_system` | Frozen four-group MCA/HCPC representation, then `nail_catdes()` | Use the same public preview/evidence/prompt route while explaining its complementarity with `local_food` | Data installed; preview, targeted tests and installed-package checks pass |
| `irtsat_2024_2025` | Frozen four-profile table; `nail_catdes()` plus score-only `nail_condes()` | Keep current profile identifiers and list historical names separately without asserting code correspondence | Data installed; previews, targeted tests and installed-package checks pass |
| `irtsat_items_2024_2025` | 48-item instrument inspection with English variable names and levels | Use for item-level teaching; do not infer profiles or join to the 529-row table by order | Data installed; structure and missingness tests pass |
| `spise_distinction_items_2025_2026` | 48-item SPISE / Distinction instrument inspection with English variable names and levels | Use for item-level teaching; no score or class is inferred | Data installed; de-identified 181 × 48 structure and ordered levels pass |
| `waste` | MCA/HCPC, then `nail_catdes()` | Remove the unsupported 0–10 “wastefulness” grading request; use descriptive group characterization and evidence inspection | Data installed; historical example not rerun in this pass |
| `nutriscore` | MCA/HCPC, then `nail_catdes()` | Keep descriptive scope and add explicit evidence/prompt access; check current `num.var` and supplementary-variable convention | Data installed; historical example not rerun in this pass |
| `quality` | PCA/HCPC/CONDES, then direct `ollamar::generate()` | Replace the direct backend call by `nail_condes(..., generate = FALSE/TRUE)` and public accessors in a future documentation-only lot | Data installed; historical MASHS pipeline documented locally |
| `atomic_habit` | MFA/HCPC preparation only | Add an offline public workflow only after deciding how to handle texts and generated groups | Data installed; no semantic generation claimed |
| `atomic_habit_clust` | Direct `FactoMineR::catdes()` in the example | Show `nail_catdes(x = ...)` or `nail_catdes_prep()` with `generate = FALSE`, while preserving the published `clust` factor | Data installed; C02 offline preparation validated |

The old examples in `R/datasets.R` and the generated `.Rd` files also contain
legacy direct-backend patterns in other datasets. Those are outside this
initial transition consolidation unless a documentation lot explicitly
includes them. No such files were modified in this review.

## Reusable validation cases already available

### C01 — `local_food`

The shareable corpus is under
`dev/operational_validation/corpus/C01_local_food/`. It contains the
reproducible script, aggregate statistical references, prompts, responses and
the exploratory comparison of conditions A/B/C. The technical/statistical
checks include the 573 × 63 data, a 573 × 64 classification, three groups of
226/188/159, 314 qualitative markers, and line-by-line reproducibility of the
seeded HCPC assignments. One response (`G3_R01`) is truncated and its API stop
reason was not retained. The C01 register has an internal wording
inconsistency (`validated` in the detailed status versus `ready_for_validation`
in a later “status unchanged” paragraph); this should be corrected in the
corpus register before the next publication pass, not silently ignored.

### C02 — `atomic_habit_clust`

The shareable corpus is under
`dev/operational_validation/corpus/C02_atomic_habit/`. The statistical table
uses columns 1:20 plus the published `clust` factor. It contains 63 selected
markers and the group sizes 84/13/70. The published classification is
reproduced by two documented AFM candidates, but the historical AFM route is
not identified. Gemini validation was blocked by quota/HTTP 429 in the logged
campaign; no semantic quality claim is made. The raw `call$X` object and
individual texts remain private.

## Other transition-related studies

The following inventory reuses the local audit reports in
`/private/tmp/nailer-survey-audit-20261026/`. These source projects are not
package data and are not copied into the repository by this review.

| Candidate | Source and evidence | Possible NaileR use | Current status | Main blocker |
|---|---|---|---|---|
| 2023–2024 ProjetSystAlimED | `Base_K.xlsx`, `Base_F.xlsx`, `SystalimED.R`, `Projet_systalim_ED.Rmd`, `SystAlimED.Rdata`; MCA/HCPC/CATDES visible | `nail_catdes_prep()`/`nail_catdes()` after stabilizing the join | `identified`, potentially `blocked` | 576/586 discrepancy, duplicated IDs, 45/46 assertion discrepancy, rights/anonymization unknown |
| 2024–2025 IRTSAT | Frozen `dta_gold`/`theta` workspace export, `analyse_irt_multidim.Rmd`, visible `mirt()`/k-means history | `nail_condes()` on the retained score; `nail_catdes()` on the frozen four-profile table | `distributed`, `installed_and_tested` | Four profiles are retained; the visible three-centre script is historical and is not the final classification |
| 2025–2026 SPISE / Distinction | `Spise/data/Bretons.xlsx` and the documented `Bretons_no_NA.xlsx` derivative; Distinction questionnaire and Quarto materials; GRM/mirt scripts and outputs | `spise_distinction_items_2025_2026` for instrument inspection; `nail_condes(..., interpretation_mode="latent")` only after a documented score table; later CATDES/text routes after canonical classification and alignment | `distributed`, `installed_and_tested` for the de-identified 48-item instrument; latent scores/classes remain local | One study represented by several subsets/stages; no distributed score or classification is asserted |
| 2025–2026 Distinction complete survey | Complete 1,226-row questionnaire preparation; 105 public scientific columns after removal of ten technical fields and exact postal code; 48 ordered assertions and translated `quality_food_open` | `nail_catdes()`, `nail_condes()` and `nail_textual()` offline previews through public accessors | `distributed` after the integration lot; translation is technically complete but not fully human linguistically validated | Eleven reviewed translation corrections applied, including seven corrected observations in the latest audit; 87 heuristic review alerts remain documented; original French texts and exact postal code remain private |
| 2023–2024 MASHS ideal food system | `don_clust.rData`, questionnaire/Q-sort-like protocol, MCA/HCPC route | `nail_catdes()` on `mashs_food_system` | `distributed`, `installed_and_tested` | Complementary to `local_food`; not the separate MASHS logo study |
| 2023–2024 MASHS logos | `quality/Analyse_logos.R`, `perception de la qualité 2024.xlsx`, saved PCA/HCPC/NaileR objects, historical reports | Reproduce the nine-logo PCA/HCPC/CONDES/CATDES example | `documented`, private source | Historical data and saved objects are local; rights and exact relation to package `quality` need confirmation |

### Scientific distinctions that must remain explicit

- The 2023–2024 Q-sort protocol is documented, but the executable analysis
  found in the sources is MCA → HCPC → CATDES, not classical Q-method factor
  extraction.
- The 2024–2025 scientific decision is four profiles. The visible three-center
  k-means script is a reproducibility discrepancy, not a reason to silently
  replace the scientific decision.
- SPISE contains executed IRT/GRM work on `Bretons.xlsx`, while the
  Distinction materials document the same study through questionnaire and
  Quarto stages without an independently identified IRT run. These are not
  two independent surveys, and neither should be confused with IRTSAT.
- Bourdieu-inspired concepts are theoretical framing, not automatically
  measured latent variables. Scores, classes, declared practices and text
  responses must not be conflated.

## Concrete lots

### T1 — Stabilize the six distributed datasets

Documentation-only changes in `R/datasets.R` and generated `.Rd` files:

1. Align the descriptions with the verified structures above.
2. State active/supplementary/contextual roles where they are actually known.
3. Replace unsupported normative or causal requests, especially the waste
   grading request.
4. Replace direct `ollamar::generate()` in the `quality` example with the
   public NaileR preview/accessor workflow.
5. Keep ordinary examples offline and put real generation in `\\dontrun{}`.

This lot must not alter statistical calculations or prompt templates.

### T2 — Preserve operational examples

Keep C01 and C02 in their separate validation directories. Version only
shareable scripts, aggregate evidence, prompts and reports. Keep individual
texts, raw `call$X`, keys, condition mappings and private archives outside
Git. Historical prompts and responses must not be rewritten to make current
labels look uniform.

### T3 — Add new transition datasets only after decisions

The complete Distinction teaching object is now prepared from the audited
1,226-row survey. It excludes the exact postal code and technical export
fields, keeps the translated open responses, and records the translation
limitations above. The object is not a replacement for the separate
`spise_distinction_items_2025_2026` instrument table and must not be joined to
it by row order. ProjetSystAlimED and any additional SPISE/Distinction score
or class tables still require the join/version/classification decisions below.
MASHS ideal-food-system and IRTSAT are already distributed as the documented
teaching objects described above. A future candidate order for remaining
cases is:

1. a de-identified, documented SPISE subset if the 182-row extraction can be
   reproduced;
2. a de-identified Survey/Distinction derivative only if open-text and
   identifier governance permits it;
3. ProjetSystAlimED only after the 576/586 and duplicate-ID issues are solved.

### T4 — Discovery and citation

After T1, add a short dataset index to the README and later prepare a focused
transition vignette. Do not build a large vignette while the source and rights
questions remain unresolved.

## Decisions required before the next integration pass

1. Confirm the distribution rights and citations for `local_food`, `waste`,
   `nutriscore`, `quality`, `atomic_habit`, and `atomic_habit_clust`.
2. Decide whether the current package examples should be modernized as one
   documentation-only T1 lot.
3. Resolve the C01 status wording inconsistency.
4. Confirm the historical AFM route for C02, or explicitly accept that the
   published `clust` factor is the sole reference.
5. Decide whether individual atomic-habit texts may ever be used in a private
   NaileR composition validation, with explicit matching and denominator rules.
6. For IRTSAT, document the canonical source export, four-group table and
   model-selection diagnostics.
7. For SPISE / Distinction, document the 182-row extraction, item dictionary,
   model versions, subset relation and rights.
8. For ProjetSystAlimED, complete de-identification and join/version
   documentation before any package integration.

## Proposed commit plan

No commit or push was performed in this review. Proposed future commands are
intentionally explicit:

```sh
git add R/datasets.R man/local_food.Rd man/waste.Rd man/nutriscore.Rd \
  man/quality.Rd man/atomic_habit.Rd man/atomic_habit_clust.Rd
git commit -m "docs(data): stabilize transition dataset examples"

git add dev/operational_validation/corpus/C01_local_food/<selected-shareable-files>
git commit -m "docs(validation): preserve C01 reproducibility materials"

git add dev/operational_validation/corpus/C02_atomic_habit/<selected-shareable-files>
git commit -m "docs(validation): preserve C02 preparation materials"
```

The angle-bracket paths are placeholders and must be replaced by an audited
file list. `git add .` and directory-wide staging are deliberately excluded.
Each lot must run `devtools::document()`, `devtools::load_all()`, offline
examples, targeted tests, the full test suite, `git diff --check`, and a
package check where the environment allows it.

## Scope and exclusions of this first intervention

- No R code, tests, package data, prompts, or source questionnaire was
  modified.
- No LLM or network generation was performed.
- No private questionnaire, verbatim, API key, or external source file was
  copied into the repository.
- The existing tracked C02 status edit and all untracked validation/QDA
  artifacts were preserved unchanged.
- The present document is a decision register for the next lots; it does not
  declare every candidate scientifically validated.
