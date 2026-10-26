# Git status and synchronization plan

## Diagnostic executed — historical snapshot, 2026-10-26

The requested non-destructive checks were run after `git fetch --prune`:

```text
branch: dev-core5-condes-integration-20261015
HEAD:   0a47b546e284dd88e3964db64fc3f3b9295c6d95
upstream: origin/dev-core5-condes-integration-20261015
```

The worktree has no tracked modifications. It contains many pre-existing
untracked validation/build artifacts, including `dev/operational_validation/`,
`local_data/`, `NaileR.Rcheck/`, `NaileR_2.1.0.tar.gz`, `Rplots.pdf` and
`tests/testthat/Rplots.pdf`. They were not staged or removed.

`git diff --check` passed. `git ls-files dev/operational_validation` and
`git ls-files local_data` returned no paths: these directories are currently
entirely untracked.

## Synchronization

At the time of this audit, the branch was two commits behind its upstream:

```text
0737040 docs: update core-five state after CONDES technical closeout
4ed141e docs(condes): record completed local technical validation
```

No local-only commits were reported. This historical diagnostic did not yet
perform a pull, merge, rebase, reset or push.

## Synchronization completed after review

After explicit authorization, the two commits above were integrated with
`git pull --ff-only` on 2026-10-26. The resulting local and upstream commit is:

```text
073704095b14fbe7bf8db68d52ecdaff1b058ce8
```

No local validation artifact was overwritten. The later corpus commits are
prepared separately from the functional CONDES history.

## Branches and PRs

The repository contains active core-five branches for CATDES, CONDES, DESCFREQ,
QDA, TEXTUAL, QDA-space and CATDES–TEXTUAL, as well as validation branches for
the seven-function benchmark and interpretive deepening. The only PR returned
by the GitHub read-only query was:

- PR #1, `feat/default-interpretive-insight` → `master`, open:
  https://github.com/Sebastien-Le/NaileR/pull/1

The local C01/C02 documentation is not part of that PR and should not be mixed
with its production/test changes.

## Conflict risks

1. `dev/operational_validation/` is a broad untracked tree with historical
   artifacts from multiple passes; `git add .` would be unsafe.
2. `local_data/` contains local standardizations and must be kept out of a
   public package commit unless explicitly approved.
3. The current branch is behind remote CONDES documentation; later commits
   should be made only after deciding whether to integrate those two commits.
4. Existing worktrees point to several core-five branches; no worktree should
   be reset or switched as part of this corpus audit.
