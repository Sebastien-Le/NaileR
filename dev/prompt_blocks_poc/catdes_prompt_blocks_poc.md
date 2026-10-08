# CATDES prompt blocks proof of concept

## Scope

This proof of concept is limited to the modern `nail_catdes()` prompt path on
branch `dev-catdes-prompt-audit`, starting from `c06d1d81106241aaa54540a6784a8d301f69588e`.
It changes prompt representation only. Statistical preparation, marker
selection, binary completion, semantic-facing evidence, generation scope, and
the public evidence accessor are unchanged.

## Before architecture

Each local CATDES prompt was assembled as one character string. The string
contained the introduction, one mixed statistical/semantic guide, the request,
the local task, and the group-specific data. The semantic guide combined
statistical reading conventions with interpretation and ontology rules.

## After architecture

The modern local prompt is first represented as a named list with this stable
order:

```text
context
reading
question
interpretation
local_task
evidence
output
```

There is no CATDES `reusable` block and no output parser contract. The `output`
slot is therefore explicitly present and currently `NULL`. The renderer emits
it only if a future CATDES output instruction is supplied.

The rendered default prompt is ordered as follows:

```text
# Introduction                         context
## How to Read the Statistical Evidence reading
# Overall Analytical Request           question
## Interpretation Rules                 interpretation
# Local Task                           local_task
# Data                                 evidence
# Output                               output, when non-empty
```

The block lists are stored on the result as:

```r
attr(result, "catdes_prompt_blocks", exact = TRUE)
```

They are named by category/group. `nail_prompt()` continues to return the
rendered prompt as a character string.

## Default reading

The default reading is the R2 statistical reading selected in the preceding
CATDES experiments. Standard mode uses `category`; latent mode uses `group`.
The statistical semantics are otherwise shared:

```text
R has already performed the statistical analysis.
Read each statement below as a factual comparison between this category/group and the full sample.
MORE FREQUENT and LESS FREQUENT describe relative modality prevalence.
HIGHER and LOWER describe the category/group mean relative to the full-sample mean for the same variable.
Percentages are descriptive values, not p-values or measures of statistical strength.
Means are compared only within the same variable.
An undisplayed modality or variable is not thereby absent, average, rejected, or unimportant.
```

The prompt still exposes the existing semantic-facing evidence only. It does
not add p-values, v-tests, ranks, evidence IDs, sampling metadata, display
origins, or representation flags.

## Standard and latent blocks

In standard mode, the interpretation block identifies observed categories,
preserves their original names, prevents latent-profile reinterpretation and
invented empirical facts, permits traceable higher-level synthesis, and marks a
broader contextual hypothesis as a hypothesis. The local task is restricted to
the displayed observed category and does not compare unseen categories.

In latent mode, the interpretation block identifies a constructed group or
latent profile, treats its label as an identifier, permits inference of its
meaning and a concise meaningful name, and preserves traceability and the
distinction between synthesis and direct fact. The local task is restricted to
the displayed constructed group and does not compare unseen groups.

The statistical reading is shared; only the category/group vocabulary and
ontology/naming permissions differ.

## Public API status

No public argument, accessor, return contract, statistical option, or backend
interface was added. The existing `introduction`, `request`,
`interpretation_mode`, `isolate.groups`, sampling, and generation arguments
retain their current roles. An editable public `reading=` interface remains a
future design question and is not part of this pass.

## Operational example

The validation example uses `NaileR::atomic_habit`, target column 2
(`never_plane_capable`), standard mode, the category
`I feel able not to take the plane`, `isolate.groups = TRUE`, full sampling,
and `generate = FALSE`.

For this category, the semantic-facing evidence remains 10 qualitative markers
and 2 quantitative markers. The prompt renderer only changes how the existing
evidence is surrounded by named semantic blocks.

The latent validation uses the same reproducible input in latent mode. It uses
the same statistical reading semantics with `group` terminology and retains
the permission to infer a meaningful name for a constructed group.

## Tests and known issue

The new targeted tests cover block structure, rendered ordering, R2 reading
semantics, standard/latent separation, evidence visibility, and canonical
evidence references. The existing `isolate.groups = FALSE` request-versus-
local-first scope inconsistency identified in the CATDES audit is deliberately
not changed in this proof of concept.
