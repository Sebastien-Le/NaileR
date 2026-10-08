# QDA evidence-level representation experiment

## Research question

What is the minimal representation of QDA evidence that lets the LLM
preserve statistical direction, reference, and evidence hierarchy while
producing a useful higher-level sensory interpretation?

The experiment separates the canonical statistical evidence from four
LLM-facing representations. It does not modify `nail_qda()`, its prompt
blocks, its evidence selection, or its public API.

## Source and configuration

- source branch used: `dev-catdes-prompt-audit`;
- source commit: `c06d1d81106241aaa54540a6784a8d301f69588e`;
- QDA implementation source: the QDA modular prompt-block implementation
  present at that commit;
- dataset: `SensoMineR::sensochoc`, loaded through
  `data(chocolates, package = "SensoMineR")`;
- formula: `~Product+Panelist`;
- `firstvar = 5`;
- `lastvar`: package default, `length(colnames(sensochoc))`;
- `proba = 0.05`;
- `drop.negative = FALSE`;
- `sample.pct = 1`;
- `sample.method = "stratified"`;
- `prompt_style = "detailed"`;
- `product_knowledge = "known"`;
- `isolate.groups = TRUE`;
- product/stimulus: `choc1`;
- provider/model: Ollama / `mistral-small3.2`;
- replications: 3 per condition, 12 generations total;
- no fixed Ollama seed is passed; each call is an independent local request.

The context, analytical question, interpretation, local task, reusable
metadata instruction, and final output requirement are copied from the
reference QDA prompt blocks. Only `reading` and `evidence` are replaced in
the experimental prompts.

## Conditions

| Condition | Representation | Additional rule |
|---|---|---|
| A | Numeric table | `Variable`, `Coeff`, `Adjust mean`, `p.value`, `v.test` |
| B | Current semantic + numeric | Exact current `semantic_facing_evidence` wording |
| C | Semantic minimal | Direction and average-product reference only; no numeric/statistical metadata |
| D | Semantic + mechanical hierarchy | C plus `Primary statistical marker` for rank 1 and `Secondary statistical marker` for rank > 1 |

Condition D deliberately uses no new v.test or p.value threshold. Its rule is
derived only from the existing deterministic `rank` field and is documented
as a relative display priority, not as sensory intensity, effect magnitude,
or substantive importance.

## Invariance checks

The script constructs one reference QDA object with `generate = FALSE`, then
extracts `product_profiles`, `interpretation_evidence`,
`semantic_facing_evidence`, and `qda_prompt_blocks`. All four conditions are
assembled from the same selected marker table for `choc1`.

The script checks that A/B/C/D use identical:

- `product_profiles`;
- `interpretation_evidence`;
- selected evidence IDs;
- marker count;
- marker directions;
- product label;
- ordering basis and marker order.

The semantic-facing artifact itself is allowed to differ because the
experiment changes the LLM-facing representation. The canonical source and
selected marker table must not differ.

## Blind-review procedure

The raw results retain condition labels for audit. The review packet contains
only a common context, question, evidence description, and shuffled response
identifiers `R01` through `R12`. The blind key is written separately and is
not included in the review packet.

The review dimensions are:

- statistical fidelity;
- evidence hierarchy;
- interpretive lift;
- unjustified extrapolation.

The review distinguishes vertical interpretive lift from horizontal semantic
distortion. It does not assign an automatic winner or composite score.

## Limitations

- Three repetitions per condition are a small, model-specific comparison.
- The numeric-table representation is reconstructed from the current selected
  marker table; it is not a rerun of an historical selection algorithm.
- The rank-based D labels express display priority only. They do not establish
  a general statistical notion of primary or secondary evidence.
- The experiment evaluates prompt representations, not statistical validity or
  the universal quality of any LLM wording.

## Execution note

The retained benchmark contains exactly 12 responses: three final responses
for each of A, B, C, and D. Two earlier complete Ollama runs were discarded
before inclusion: the first failed while serializing result names, and the
second exposed a duplicated product heading in condition B. The corrected
third run regenerated the retained 12-response artifact set. The discarded
responses are not present in the raw RDS, blind response file, key, or review
packet.
