# Validation archive audit — C01/C02

Date of audit: 2026-10-26

## Durable locations

The original temporary directories were preserved in private local storage:

- C01 — 272 files, about 9.9 MB;
- C02 — 62 files, about 664 KB.

Durable copies were created without deleting or moving the originals:

- shareable corpus: `dev/operational_validation/corpus/`;
- complete private mirror outside the Git worktree.

The private mirror is deliberately outside the Git worktree. It contains the
full C01/C02 temporary artifacts, including the C01 condition mapping and
RDS files. It must not be added to Git automatically.

## Shareable copy

The version intended for review is split by case:

- `C01_local_food/`: reports, prompts, responses, blind packet, aggregate
  evidence and metadata; the condition key is excluded;
- `C02_atomic_habit/`: script, reports, prompts and aggregate CATDES objects;
  questionnaire data and individual verbatims are excluded.

The durable shareable copy contains 49 C01 files and 25 C02 files. A privacy
inspection found that the raw C02 `catdes_reference.rds` contains
`call$X`, a 167x21 data frame. That generated copy was moved to the private
mirror, and the C02 archive containing it was also moved there. The original
Desktop archive and temporary tree were preserved. The remaining C02 RDS
objects in the shareable copy contain structured 1:20 + group CATDES data or
derived aggregate profiles, not the ten open-text columns.

## Original archives

The four C01 Desktop archives were copied, not replaced, to
`dev/operational_validation/corpus/archives/`. The C02 archive is retained in
the private mirror because it contains the raw `call$X`. SHA-256 values for
all five original archives:

| Archive | SHA-256 |
|---|---|
| `NaileR_C01_Gemini_A_B_C_20261026.zip` | `27ef0f8ce440bebe6db5541af31873eb9de90023ebdfd77c78f9652c1d0212c0` |
| `NaileR_C01_Gemini_end_to_end_A_20261026.zip` | `2c623db767bdd780a1ec408242f6e478db66184187f6a9cd56fa53a48cd1e02e` |
| `NaileR_C01_Gemini_validation_20261026.zip` | `5f9565e23446adb260b129263cc425f0e40574826f14891f0b5c15224d7088a2` |
| `NaileR_C01_local_food_validation_20261026.zip` | `186ae435839bbc3d0e407519f4362af5c1ef231a1d0e8b42c433f6f677781c25` |
| `NaileR_C02_atomic_habit_validation_20261026.zip` | `711d574c8eb01078dbdbc4849bb0cf1857035f369db3d847015fd8546a431d81` |

All five archives passed `unzip -tqq`. Their hashes are distinct; no exact
duplicate archive was detected. They are nevertheless partly overlapping
historical snapshots, so the archive names and hashes must be retained.

## Readability checks

The durable C01/C02 copies were enumerated successfully. Representative RDS
files from both cases were read successfully with R; the raw C02
`catdes_reference.rds` was explicitly inspected and quarantined because of
`call$X`. The prompts and reports are UTF-8 text files and the ZIP archives
are structurally readable.

The durable C02 script copy has only trailing-whitespace normalization relative
to the temporary source; the original script remains unchanged in the private
mirror. No executable or analytical content was changed.

## Missing or not durable externally

- No independent backup service or second physical disk was verified.
- C02 semantic LLM generations and human scientific evaluation do not exist;
  this is intentional and is recorded in its status.
- The C02 raw `call$X` RDS and archive remain private and must not be staged.
- The C01 blind key is intentionally absent from the shareable corpus but is
  present in the private mirror.

An independent backup is still recommended before treating these results as
the sole durable record.
