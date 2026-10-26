# Proposed targeted commits

No commit is authorized or created by this audit.

## Commit 1 — Corpus register and privacy manifest

Suggested message:

```text
docs(validation): register C01 and C02 corpus
```

Candidate paths:

```text
dev/operational_validation/corpus/ARCHIVE_SHA256.txt
dev/operational_validation/corpus/C01_C02_ARTIFACT_MANIFEST.csv
dev/operational_validation/corpus/GIT_STATUS_AND_SYNC_PLAN.md
dev/operational_validation/corpus/PROPOSED_COMMITS.md
dev/operational_validation/corpus/VALIDATION_ARCHIVE_AUDIT.md
dev/operational_validation/corpus/VALIDATION_CORPUS.md
```

These files contain only the public inventory, hashes and publication rules.
Private paths are represented by logical locations; private mirrors and
archives are excluded.

## Commit 2 — C01 documentation and reproducibility

Suggested message:

```text
docs(validation): archive C01 local_food reproducibility artifacts
```

Candidate paths, all under the durable shareable corpus:

```text
dev/operational_validation/corpus/VALIDATION_ARCHIVE_AUDIT.md
dev/operational_validation/corpus/VALIDATION_CORPUS.md
dev/operational_validation/corpus/GIT_STATUS_AND_SYNC_PLAN.md
dev/operational_validation/corpus/PROPOSED_COMMITS.md
dev/operational_validation/corpus/C01_local_food/C01_TRUNCATION_DIAGNOSTIC.md
dev/operational_validation/corpus/C01_local_food/C01_VALIDATION_STATUS.md
dev/operational_validation/corpus/C01_local_food/shareable/
```

The `shareable/` directory contains 47 files. It excludes the blind condition
key and all API secrets. Before staging, review every response and RDS file
against the repository's sharing policy.

## Commit 3 — C02 preparatory validation

Suggested message:

```text
docs(validation): add C02 atomic habit CATDES preparation
```

Candidate paths:

```text
dev/operational_validation/corpus/C02_atomic_habit/shareable/
```

This directory contains 25 files: the script, reports, prompts, aggregate
audits and privacy-reviewed CATDES objects. It excludes raw questionnaire
data, all individual verbatims and `catdes_reference.rds`, whose `call$X`
contains a 167x21 observation table and is retained only in the private
mirror. This commit should be made only after review of the unresolved AFM
provenance and the decision that the remaining structured RDS objects are
permitted in Git.

## Staging discipline

Use explicit pathspecs, never `git add .`.

For Commit 1:

```bash
git add -- \
  dev/operational_validation/corpus/VALIDATION_ARCHIVE_AUDIT.md \
  dev/operational_validation/corpus/VALIDATION_CORPUS.md \
  dev/operational_validation/corpus/GIT_STATUS_AND_SYNC_PLAN.md \
  dev/operational_validation/corpus/PROPOSED_COMMITS.md \
  dev/operational_validation/corpus/ARCHIVE_SHA256.txt \
  dev/operational_validation/corpus/C01_C02_ARTIFACT_MANIFEST.csv
```

For Commit 2:

```bash
git add -- \
  dev/operational_validation/corpus/C01_local_food/C01_TRUNCATION_DIAGNOSTIC.md \
  dev/operational_validation/corpus/C01_local_food/C01_VALIDATION_STATUS.md \
  dev/operational_validation/corpus/C01_local_food/shareable
```

For Commit 3, stage only the explicit C02 path after its privacy review:

```bash
git add -- dev/operational_validation/corpus/C02_atomic_habit/shareable
```

Do not stage the private mirror, temporary originals, Desktop archives, the
private C02 archive, `catdes_reference.rds`, `Rplots.pdf`, build outputs,
`local_data/`, or any C01 condition key.

The exact file list can be regenerated before staging with:

```bash
find dev/operational_validation/corpus/C01_local_food/shareable -type f -print | sort
find dev/operational_validation/corpus/C02_atomic_habit/shareable -type f -print | sort
```

No `.gitignore` change was made. A future ignore rule may be appropriate for
`NaileR.Rcheck/`, `*.tar.gz`, `Rplots.pdf`, `tests/testthat/Rplots.pdf` and
the private/local validation directories, but that policy requires separate
approval because several of these paths predate this audit.
