# Breton subset — package-ready status

Date: 2026-10-29

## Decision on the source

The relevant source is the processed questionnaire object `questionnaire` in
`/Users/sebastienle/Documents/2025-2026/Albin/environnement.RData`. The files
`data_final.rds`, `Data-align_global.csv`, `Tableau données.csv` and the
`resultats_gc_ms_*` directories are GC-MS artefacts and were not used.

The subset is defined by the administrative Brittany department prefixes
`22`, `29`, `35` and `56` (Côtes-d'Armor, Finistère, Ille-et-Vilaine and
Morbihan). Loire-Atlantique (`44`) is deliberately excluded. This criterion
selects 485 respondents.

## Compatibility with `distinction`

The object `bretons` was created by row-filtering the published package object
`distinction`, not by reconstructing a reduced table. It therefore has:

- 485 observations;
- 105 columns;
- the exact same column names and order as `distinction`;
- the exact same column classes;
- the exact same factor levels and level order;
- the same 47 active assertion columns;
- the same non-missing English open-text field, `quality_food_open` (485 rows).

The source questionnaire and `distinction` were checked for row alignment using
age and the missingness pattern of the open response. The 47 assertion values
were also checked against the French questionnaire using the documented
five-level Likert recoding before the subset was built.

No `profile` column was added. A Breton classification must be recomputed from
this subset for a later CATDES/TEXTUAL analysis; it must not be copied from the
full-sample `distinction` object.

## English translation

No new translation was generated. The English responses in `bretons$quality_food_open`
are exactly the already validated translations distributed in `distinction`.
This preserves the same structure and makes the subset usable with the same
NaileR workflow. The French source responses are retained only in the private
audit object `bretons_private_fr_en.rds`.

## Reproducible build

The build script is:

`build_bretons_package_ready.R`

It reads the two source objects, applies the postal-prefix selection, checks
schema and translation invariants, and writes the package-ready objects to the
private preparation directory. It does not read or alter GC-MS files and does
not call an LLM.

Outputs in `/private/tmp/nailer-bretons-distinction-20261029/`:

| File | SHA-256 | Status |
| --- | --- | --- |
| `bretons.rda` | `1fe84cdd3579bcee5baec876d6c5a0bd019403204c154d4b79be046cf5466fb9` | package-ready candidate |
| `bretons.rds` | `02c6b231b30e57fc2248c2a579bd4bb5bf26409011dee342e33ec9c4888e8322` | package-ready candidate |
| `bretons_private_fr_en.rds` | `2db34f59e3375a2301a19e43ba47d45c2106aa01d1f041f486f9cb85bdda90d1` | private audit copy; contains individual French responses |
| `BRETONS_PACKAGE_READY_MANIFEST.csv` | `39690fb1e54d5d34b5d71870a560f798584f56ed43c889eda9d68e43da43f426` | manifest |

The earlier 48-column `bretons_distinction_textual_input.rds` remains a
minimal textual-input artifact. It is not the package-ready object because it
does not preserve the complete `distinction` schema.

## Publication status

The project authority has confirmed that the Bretons data are publishable and
authorized their inclusion in NaileR. The package-ready object is therefore
eligible for integration into `data/` and public documentation. The current
working copy has already been copied provisionally to `data/bretons.rda`, but
it has not yet been committed or pushed.

The French–English audit object is not required by the package API and remains
outside the package to keep the public distribution limited to the validated
English presentation layer. The generated Gemini prompts, responses and RDS
validation objects remain separate experimental artefacts and are not part of
the dataset publication.
