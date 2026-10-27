# NaileR examples audit — initial inventory

Date: 2026-10-27
Reference branch: `dev-core5-condes-integration-20261015`
Reference HEAD: `421fe64a1e8ed312b2b624b4c6d96527487d45e6`

This is the initial audit requested before any harmonisation change. The
current source and current public API are authoritative. `R_old/` and
`R_old_old/` were consulted only to recover historical scientific examples.

`nail_sort()` is deliberately kept at low priority. Its historical beard
clustering example is inventoried, but no migration or API intervention is
planned in this pass.

## Public example inventory

| Function | Dataset / case | Historical example | Current example or script | State | Action |
|---|---|---|---|---|---|
| `nail_catdes()` | `iris` | Iris species characterization | `R/nail_catdes.R`, preview, evidence and prompt accessors | preserved | Keep as the minimal observed-category example |
| `nail_catdes()` | `waste` | MCA/HCPC food-waste survey | `R/nail_catdes.R`, `dev/operational_validation/` | adapted | Recheck the current public call and retain descriptive, non-normative wording |
| `nail_catdes()` | `local_food` | MCA/HCPC transition survey | `R/nail_catdes.R`, C01 corpus | adapted | Preserve the C01 `ncp = 100` reference and distinguish declared positions from behaviour |
| `nail_catdes()` | `atomic_habit_clust` | Constructed ecological-habit groups | `R/nail_catdes.R`, C02 corpus | adapted | Keep group identifiers and the prepared-profile route |
| `nail_catdes()` | prepared profiles | Not present as a stable public route in the oldest help | `nail_catdes_prep()` plus current help | new | Keep as the advanced reusable-profile example |
| `nail_catdes_prep()` | `iris` | No equivalent stable historical public workflow located | `R/nail_catdes_prep.R` | preserved | Keep the deterministic preparation example |
| `nail_condes()` | `decathlon` | Not present in the oldest examples | Current help | new | Keep observed-target and latent-dimension contrast |
| `nail_condes()` | `agri_studies` | Not present in the oldest examples | Current help | new | Keep ACM dimension example; retain declared-expectation wording |
| `nail_condes()` | `glossophobia` | Not present in the oldest examples | Current help | new | Keep the non-clinical interpretation boundary |
| `nail_condes()` | `beard_cont` | Historical CA-derived beard dimension | Current help | adapted | Keep row-profile construction and avoid individual-level claims |
| `nail_condes()` | `local_food` | Historical transition-related dimensions | Current help | adapted | Preserve active/supplementary distinction and English assertion labels |
| `nail_condes()` | IRTSAT / Distinction | Not in the oldest help | Current help and transition assets | new | Keep as categorical ACM demonstrations; do not call them IRT analyses |
| `nail_descfreq()` | `beard_cont` | Eight beard types, description and naming | Current help and validation script | adapted | Keep as the description-mode example |
| `nail_descfreq()` | `children` | Education-level comparison of hesitation reasons | Current help and validation script | adapted | Keep as the comparison-mode example |
| `nail_descfreq()` | `rorschach` | Not in the old help | Current help and validation script | new | Keep deterministic observed-term coding and document its limits |
| `nail_qda()` | chocolates | No public current help equivalent in the old source inspected | Current help and QDA validation scripts | new | Keep the real sensory-panel example |
| `nail_qda()` | strawberries, apples, perfumes, melons | Not in the oldest help | Current help, distributed data and local validation | new | Keep the five sensory studies; do not add artificial sessions |
| `nail_qda_space()` | chocolates | No historical public example located | Current help and Phase 4 validation script | new | Keep one concise geometry example; preserve deterministic axis limits |
| `nail_textual()` | `fabric` | No equivalent modern structured example in the old source | Current help and operational script | adapted | Keep as the smallest local-first preview; use corrected `num.var = 4`, `num.text = 3` |
| `nail_textual()` | `car_alone`, `atomic_habit_clust` | No equivalent in the old help | Current help and operational scripts | new | Keep declared perceptions distinct from behaviour |
| `nail_textual()` | `rorschach` | Historical textual corpus available locally | Current help and operational script | adapted | Preserve verbatims and the non-diagnostic framing |
| `nail_textual()` | `distinction` | Historical validation corpus and corrected translations | Current help and post-correction review | adapted | Use the corrected English corpus and preserve sampling/ID provenance |
| `nail_textual_prep()` | `fabric` | No stable old public example located | Current `R/nail_textual.R` block | new | Keep as a preparation-only, offline example |
| `nail_textual_contextualized()` | contextualized profiles | No public historical example located | No current `@examples` block; operational assets exist | missing | Add documentation only after a dedicated API-contract check |
| `nail_catdes_textual()` | deterministic composition fixture | No historical equivalent located | Current help and tests | new | Keep the artificial fixture because it tests composition deterministically; label it as constructed |
| `nail_sort()` | `beard_wide` | Historical LLM clustering of beard descriptions | Current `\dontrun{}` help | preserved | Low priority; leave unchanged unless a separate request targets this function |

## Historical recovery summary

The oldest inspected source contains substantive examples for CATDES (Iris,
food waste, local food), DESCFREQ (beards and children), CONDES (the beard CA
route) and SORT (beard clustering). These objectives are still represented in
the current help or operational scripts, but several calls necessarily use the
current evidence/accessor contract rather than the historical `$response`
contract.

The current package adds substantial applied coverage for transition surveys,
QDA sensory studies, structured TEXTUAL previews, Rorschach and composition.
These are `new` or `adapted`, not silently restored legacy code.

No historical example was found that justifies reintroducing direct
`ollamar::generate()` calls into current help. Generation examples must remain
optional and outside automatic checks.

## Functions without a complete current applied example

- `nail_textual_contextualized()` has a public API and operational coverage,
  but no dedicated `@examples` block. It needs a separate contract review
  before documentation is added.
- `nail_catdes_ground()` and `nail_group_profile_prep()` are public support
  functions whose contracts are exercised by operational workflows, but they
  do not currently have a complete, standalone applied example in the main
  help. They should be documented through a small offline example only after
  their intended user-facing role is confirmed.
- `nail_qda_interpretation()` and `nail_qda_spaceprep()` are public advanced
  support routes covered by QDA/QDA-space validation assets. Their current
  operational coverage is useful evidence, but it is not yet a concise
  standalone help example.
- `nail_sort()` has a historical `\dontrun{}` example only. It is explicitly
  deferred because it is not a priority for this harmonisation pass.
- Accessors are demonstrated through the principal workflows rather than as
  independent synthetic examples.

## Current risks to resolve before harmonisation

1. Run examples from a clean installed package, not only with `load_all()`.
2. Check that all current data names and column ranges match the distributed
   objects after installation.
3. Replace or qualify any remaining normative wording in legacy food-waste
   examples.
4. Keep source-specific exceptions explicit: QDA plans, ACM/HCPC preparation,
   Rorschach term coding and TEXTUAL local-first sampling are not interchangeable.
5. Keep generated responses, private survey text and API credentials outside
   ordinary help examples.

## Scope and Phase 2 outcome

The audit baseline is now followed by a targeted documentation pass. It does
not change package algorithms, function signatures, internal prompts,
datasets, tests, or output contracts. The detailed common presentation rules
are in `EXAMPLES_STYLE_GUIDE.md`.

The Phase 2 pass updated only roxygen examples and their generated help files:

- `nail_catdes_prep()` now shows the public route from mechanical preparation
  to `nail_catdes()`, `nail_evidence()`, and `nail_prompt()`;
- `nail_qda_space()` now states the sensory/PCA context and distinguishes
  descriptive CONDES associations from causal or independent inferential
  claims;
- `nail_qda_spaceprep()` is explicitly labelled as a compatibility helper,
  with the rebuilt `nail_qda()` -> `nail_qda_space()` route preferred;
- `nail_catdes_textual()` explicitly labels its deterministic fixture as
  constructed rather than an observed LLM output or a real survey.

No standalone examples were added for `nail_textual_contextualized()`,
`nail_catdes_ground()`, `nail_group_profile_prep()`, or
`nail_qda_interpretation()`: their advanced or composed contracts need more
than a short isolated example to be documented safely. `nail_sort()` remains
deferred as requested.

The four touched help topics pass `tools::checkRd()` and all 64 topics pass
`tools::Rd2ex()`. The full test suite remains at 1,442 PASS, 0 FAIL, 0 WARN,
and 0 SKIP. An approved local `devtools::check(document = FALSE)` reached
vignette rebuilding but stopped because Pandoc is not installed; this is an
environment limitation, not a package test result.

## Offline checks already run

The following existing operational assets were executed from the source
checkout with `generate = FALSE`:

| Check | Result |
|---|---|
| CONDES applied bench | PASS; 8 cases, including `local_food`, IRTSAT items and Distinction; retained marker counts 20–248 depending on the case |
| DESCFREQ Rorschach example | PASS; 600 × 5 source, 10 × 6 contingency table, 22 retained markers |
| TEXTUAL examples | PASS; Fabric, Car Alone, Atomic Habits, Rorschach and corrected Distinction previews |
| QDA sensory previews | PASS; chocolates, strawberries, apples, perfumes and melons; QDA-space preview also produced one eligible axis |
| CATDES applied previews | PASS; Iris, Waste, `local_food` and `atomic_habit_clust` |
| DESCFREQ Beards and Children | PASS after selecting a local prompt for the isolated Beards case; 70 and 10 retained markers respectively |
| `tools::checkRd()` | PASS for the 4 touched `.Rd` files; 5 pre-existing non-ASCII encoding findings remain in other topics |

The first Beards check intentionally exposed the documented accessor nuance:
an isolated DESCFREQ result contains one prompt per row, so
`nail_prompt(result)` is a named collection and
`nail_prompt(result, select = "B1")` is the scalar inspection route. This is
an example-contract detail to preserve in the help, not a reason to alter the
function.
