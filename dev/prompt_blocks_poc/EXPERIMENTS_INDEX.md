# Prompt Analysis Experiments Index

This directory contains experimental material used to study the architecture of statistical data-analysis prompts in NaileR.

The experiments are development and methodological experiments. They do not constitute a formal benchmark of language models.

The raw experimental material is preserved so that the analyses can be revisited and reused, including for future work in NaileR and EnTraineR.

## How to read this index

The raw responses, blind keys, review packets, and `.rds` result bundles are
kept together within each experiment. The blind keys are preserved as raw
materials; the index does not reveal or recompute blind judgments. Main
observations below are copied from the methodological journal and are not new
analyses.

`PROMPT_ANALYSIS_FINDINGS.md` is the cross-experiment synthesis. The QDA
design document `qda_prompt_blocks_poc.md` and the TEXTUAL design document
`textual_prompt_blocks_poc.md` remain at the root of `dev/prompt_blocks_poc/`.

## Experiment inventory

| Experiment | Method | Research question | Corpus / analytical object | Conditions | Replications | Model | Blind review | Main files | Main observed result | Main limitation |
| --- | --- | --- | --- | --- | ---: | --- | --- | --- | --- | --- |
| Initial modular ablation | QDA | How do full and reduced prompt blocks affect interpretation? | QDA product prompt / `choc1` PoC | `full`, `minimal`, `interpretation`, `reading` | 3 per condition | `mistral-small3.2` | Yes | `experiments/qda/initial_ablation/` | Full was best overall; minimal was unexpectedly solid; interpretation alone had limited benefit; reading alone was less convincing. | Small, model-specific development comparison. |
| Evidence rendering comparison | QDA | Does the semantic-facing evidence rendering improve interpretation relative to a direct relative paraphrase? | QDA product evidence | Current evidence rendering vs relative semantic rendering | 3 per condition | Recorded in raw responses | Yes | `experiments/qda/evidence_rendering/` | Current rendering outperformed the tested “more pronounced / less pronounced” alternative. | Limited comparison and model context. |
| Relative interpretation experiments | QDA | How should relative sensory facts be connected to a higher-level interpretation? | QDA product / relative sensory configuration | Current interpretation vs relative interpretation wording | 3 per condition | Recorded in raw responses | Yes | `experiments/qda/relative_interpretation/` | The final wording supports a traceable movement from relative facts to sensory configuration and interpretation. | Small blind comparison; not a universal wording result. |
| Relative wording experiments | QDA | Which wording best preserves the relative meaning of `HIGHER` and `LOWER`? | QDA product with relative markers | Current, full statistical, and short relative wording variants | 3 per condition | Recorded in raw responses | Yes | `experiments/qda/relative_wording/` | The retained wording was preferred to the tested alternatives. | Model- and prompt-specific comparison. |
| B2 versus B3 | QDA | Does the operational relative grammar outperform an explicit relative synthesis? | QDA product / relative interpretation | `B2_operational_relative`, `B3_explicit_relative_synthesis` | 3 per condition | Recorded in raw responses | Yes | `experiments/qda/b2_vs_b3/` | B2 was preferred in all three repetitions of the final comparison. | Very small comparison. |
| Final relative rule | QDA | Should the selected relative interpretation rule be retained? | QDA product / final rule check | Current interpretation vs `B2_operational_relative` | 3 per condition | Recorded in raw responses | Yes | `experiments/qda/final_relative_rule/` | The B2 operational relative rule was retained in the QDA PoC. | Blind result is not a general model evaluation. |
| Evidence levels — `choc1` | QDA | What is the minimal useful representation of retained QDA evidence? | `choc1` product profile | `A` numeric table, `B` current semantic + numeric, `C` semantic minimal, `D` semantic + mechanical primary/secondary hierarchy | 3 per condition | `mistral-small3.2` | Yes | `experiments/qda/evidence_levels/` | `C > A > B > D` in the small blind comparison; semantic minimal performed best on this dense coherent profile. | Product- and model-specific development comparison; LOWER-to-absence distortions remained possible. |
| Evidence levels replication — `choc2` | QDA | Does semantic-minimal evidence remain sufficient for a less-dense profile? | `choc2` product profile | `A` numeric table, `B` current semantic + numeric, `C` semantic minimal | 3 per condition | `mistral-small3.2` | Yes | `experiments/qda/evidence_levels/replication_less_dense/` | `A ≈ B > C` in this small development replication. | Not a statistically demonstrated difference; numerical visibility did not guarantee correct evidence hierarchy. |
| Signed-v.test order — `choc2` | QDA | Does preserving signed decreasing `v.test` order improve two-sided evidence hierarchy? | `choc2` product profile | `C` existing semantic order, `E` signed decreasing `v.test` order with both-extremes instruction | 3 per condition | `mistral-small3.2` | Yes | `experiments/qda/evidence_levels/vtest_order/` | `E` produced the individually best response but no consistent improvement over `C`. | Small comparison; methodological justifiability is distinct from prompt-ranking superiority. |
| Benchmark 1 M/R/I/F | TEXTUAL | What is the effect of the initial optional blocks? | Travel-choice texts, group A | `M`, `R`, `I`, `F` | 3 per condition | `mistral-small3.2` | Yes | `experiments/textual/benchmark1/` | Established the first ablation vocabulary and supplied material for human review. | Small sample; ranks should not be overgeneralized. |
| Parser tolerance P0/P1/P2 | TEXTUAL | How much structured output is recovered under strict, syntax-tolerant, and semantic-alias parsing? | Responses from the initial TEXTUAL benchmark | `P0`, `P1`, `P2` | 12 responses | Same benchmark model | Review of parser outcomes | `experiments/textual/parser_tolerance/` | All 12 failed strict P0; mean recovered fields were 0, 4, and 5 for P0, P1, and P2; within-group coherence was recovered for 0/12. | Human-facing quality and machine-readable projection are distinct; P2 was not adopted. |
| Benchmark 2 M/R/I/F | TEXTUAL | Does the interpretation block increase conceptual lift while preserving fidelity? | `NaileR::fabric`, group A, eight texts | `M`, `R`, `I`, `F` | 3 per condition | `mistral-small3.2` | Yes | `experiments/textual/benchmark2/` | `F` ranked 1, 2, and 3 with mean rank 2.0; `I` showed strong lift with more fidelity fragility. | Earlier benchmark cells were reused in later factorial material. |
| Full 2 × 2 × 2 factorial | TEXTUAL | What are the separated and combined effects of `reading`, `interpretation`, and `local_task`? | `NaileR::fabric`, group A, eight texts | `M`, `R`, `I`, `L`, `RI`, `RL`, `IL`, `F` | 3 per condition | `mistral-small3.2` | Yes | `experiments/textual/factorial/` | Mean ranks: `F` 2.0, `R` 11.3, `I` 12.0, `IL` 12.7, `M` 13.0, `L` 15.7, `RL` 16.0, `RI` 17.3. | Earlier `M/R/I/F` responses were reused and re-blinded; not a fully independent replication. |
| Bridge RI/RIB/F | TEXTUAL | Does an explicit application bridge reproduce the effect of `local_task`? | `NaileR::fabric`, group A, eight texts | `RI`, `RIB`, `F` | 5 per condition | `mistral-small3.2` | Yes | `experiments/textual/bridge/` | Mean ranks: `F` 4.6, `RIB` 8.2, `RI` 11.2; observed ordering `F > RIB > RI`. | Bridge did not reproduce full `local_task`; decomposition remains a hypothesis. |

## QDA archive map

- `experiments/qda/initial_ablation/`: initial full/reduced prompt ablation,
  including the `mistral_small32_*` bundle.
- `experiments/qda/evidence_rendering/`: current versus relative semantic
  evidence rendering.
- `experiments/qda/relative_interpretation/`: relative interpretation wording.
- `experiments/qda/relative_wording/`: relative wording variants and the
  `qda_relative_vs_absolute_mistral.*` comparison.
- `experiments/qda/b2_vs_b3/`: operational B2 versus explicit B3.
- `experiments/qda/final_relative_rule/`: final blind rule comparison.
- `experiments/qda/evidence_levels/`: evidence-representation comparison on
  `choc1`, its less-dense `choc2` replication, and the signed-v.test-order
  experiment.
- `experiments/qda/evidence_levels/replication_less_dense/`: A/B/C
  less-dense replication on `choc2`.
- `experiments/qda/evidence_levels/vtest_order/`: semantic minimal versus
  signed decreasing-v.test order on `choc2`.

All QDA files were classifiable from their names and recorded contents; no
QDA `misc/` directory was necessary.

## TEXTUAL archive map

- `experiments/textual/benchmark1/`: initial M/R/I/F ablation and its
  interpretive-lift review.
- `experiments/textual/parser_tolerance/`: parser-oriented review and
  summaries, including `textual_ablation_parser_summary.csv`.
- `experiments/textual/benchmark2/`: `textual_ablation2_*` benchmark material.
- `experiments/textual/factorial/`: complete eight-condition factorial.
- `experiments/textual/bridge/`: RI/RIB/F bridge experiment.

No raw result, blind key, blind response, review packet, or intermediate
analysis was deleted. `dev/operational_validation/` was deliberately left
outside this reorganization.

## Reuse notes

The raw artifacts should be reused through their recorded evidence, prompts,
responses, and blind-review material. They should not be treated as a formal
leaderboard. Future experiments should preserve the separation between:

```text
evidence
-> statistical interpretation
-> substantive interpretation
-> audience-adapted explanation
```

The last step is especially relevant to future EnTraineR work and is not
implemented or tested here.
