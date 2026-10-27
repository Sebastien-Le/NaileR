# Planned integration lots

These are plans only. No file is staged, committed or pushed by this
intervention.

## T1 — modernize the six distributed dataset helps

Expected paths:

    R/datasets.R
    man/local_food.Rd
    man/waste.Rd
    man/nutriscore.Rd
    man/quality.Rd
    man/atomic_habit.Rd
    man/atomic_habit_clust.Rd

Changes: documentation and examples only. Ordinary previews use
generate = FALSE, public accessors and package data; real generation stays
inside dontrun. Tests: devtools::document(), six checkRd calls, six
clean-session example executions, devtools::test(), and git diff --check.
Proposed commit: docs: modernize transition dataset examples.

The eventual staging command must name these seven paths explicitly. The
temporary reconstruction directory is not part of this package commit unless
the scientific owner decides to version it separately.

## T2 — preserve C01/C02 operational validation

Candidate paths are selected from the already audited shareable files under:

    dev/operational_validation/corpus/C01_local_food/
    dev/operational_validation/corpus/C02_atomic_habit/shareable/

Do not stage raw individual data, raw call objects, API keys, private archives,
condition mappings, Rplots.pdf, or unreviewed C02-R1 responses. Tests are the
existing C01/C02 validation scripts plus a privacy-manifest review. Proposed
commit: docs(validation): preserve C01 and C02 operational cases.

The exact list must be regenerated from the shareable manifests immediately
before staging; no recursive git add is planned.

## T3 — integrate a new external study

No T3 source is currently ready. A future T3 commit must include only a
de-identified object under data/, its roxygen source and generated .Rd,
its dictionary/provenance documentation, and a deterministic offline test.
The first candidate is the shared SPISE / Distinction study after its
extraction rule, selected model, package versions and rights are frozen.
Proposed commit:
feat(data): add validated transition study.

## T4 — index and teach the corpus

Expected paths are a separately reviewed README dataset index and a focused
transition vignette. It must cite only distributed or explicitly external
data and must not embed private paths, individual records or unvalidated
scientific claims. Tests are vignette rendering without LLM plus package
documentation checks. Proposed commit:
docs: index transition validation corpus.

## Push procedure for any approved lot

Before each lot, verify the branch and upstream, stage explicit paths only,
run git diff --cached --name-status, git diff --cached --check, review new
contents for secrets/identifiers, commit the proposed message, push the
current development branch without force-push, and verify the remote SHA.
No lot should be merged into the reference branch automatically.
