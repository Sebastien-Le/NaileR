# NaileR validation corpus

This register tracks operational validation cases separately from package
source code. A successful prompt preview or LLM generation is not, by itself,
a scientific validation.

## Status vocabulary

- `identified`: the case is located but its structure or provenance is not yet
  sufficiently characterized;
- `documented`: sources and a reproducible plan are described;
- `ready_for_validation`: technical/statistical preparation is executable and
  archived, but the planned scientific evaluation is incomplete;
- `validated`: the stated technical and scientific checks for that case have
  actually been executed and documented;
- `blocked`: provenance, privacy, alignment or another limitation prevents a
  responsible validation.

## Current cases

| ID | Case and provenance | NaileR functions | Tested branch / SHA | Technical/statistical status | Scientific status | Limits | Durable location |
|---|---|---|---|---|---|---|---|
| C01 | `local_food`, package data, ACM–HCPC/CATDES workflow | `nail_catdes_prep()`, `nail_catdes()` | `dev-core5-condes-integration-20261015` / `0a47b546e284dd88e3964db64fc3f3b9295c6d95` | validated; 314-marker reference and A/B/C invariance checked | exploratory comparative review completed; not a general superiority claim | 9 responses, one incomplete (`G3_R01`); no API stop reason retained | `C01_local_food/` |
| C02 | `atomic_habit_clust`, package data, three constructed groups | `nail_catdes_prep()`, `nail_catdes()`; future `nail_textual()`/composition | `dev-core5-condes-integration-20261015` / `0a47b546e284dd88e3964db64fc3f3b9295c6d95` | ready_for_validation; 167×51, groups 84/13/70, 63 evidence rows, previews complete | not yet evaluated; no LLM generation | exact historical AFM route unresolved; group 2 is n=13; texts remain local | `C02_atomic_habit/` |

## C01 — `local_food`

The package data and the ACM–HCPC/CATDES pipeline were checked. Nine Gemini
interpretations were produced across conditions A/B/C and compared in the
completed exploratory review. `G3_R01` is incomplete; the wrapper did not
preserve `finishReason` or the raw HTTP JSON. This case is technically and
statistically validated for the executed protocol, with that generation limit
explicitly retained.

## C02 — `atomic_habit_clust`

The 167×51 object was checked against the 167×50 object: all 50 common columns
are identical and the group factor has sizes 84/13/70. A FactoMineR CATDES
reference and `nail_catdes_prep(x = raw_catdes)` were executed on columns 1:20
plus the published group. Four offline previews were produced (local/joint ×
`drop.negative`). The two documented AFM candidates both reproduce the
published classification exactly, but this does not prove which historical
route was used. The case remains `ready_for_validation`; no LLM response has
been generated. The raw `catdes_reference.rds` was inspected and its
`call$X` (167×21) is retained only in the private mirror; it is excluded from
the shareable corpus.

## Recommended future entries

Future cases should receive their own directory with a reproducible script,
source manifest, aggregate statistical reference, prompt previews, raw LLM
responses only when sharing is authorized, parser/accessor checks and a
scientific evaluation report. Sensitive individual data and API keys must
remain outside the shareable corpus.
