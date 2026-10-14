# Cross-functional decision — prompt-visible evidence and selection metadata

**Approved:** 2026-10-14
**Scope:** CATDES, CONDES, DESCFREQ, QDA; apply the same principle when scientifically reviewing other NaileR prompt families.
**Status:** SCIENTIFICALLY APPROVED; documentation only. R code not yet migrated globally.

## Principle

The LLM should produce the best supported substantive, multidimensional interpretation **from the statistical evidence actually supplied to it**. It does not need a generic warning that R has selected only a subset of eligible evidence, or a reminder to speculate about the absence of attributes, modalities, variables, or markers it has not received.

Remove routine instructions such as:

- “The displayed evidence may be selected rather than exhaustive.”
- “Do not infer results for variables or categories that are not shown.”
- “If LOWER attributes have been excluded, the displayed evidence provides only a partial characterization.”

Do **not** substitute a new disclaimer for these sentences. Preserve the analyst's introduction and analytical request and the method-specific statistical semantics.

## Distinguish three responsibilities

1. **R and canonical evidence:** statistical computation, marker retention, selection thresholds/options (`sample.pct`, `sample.method`, `quali.sample`, `quanti.sample`, `drop.negative`), provenance, evidence IDs, counts, audit metadata, and deterministic invariance. Continue documenting whether the prompt-visible data are complete or selected in machine-readable objects, R output and development docs.
2. **LLM `reading` and `interpretation`:** relative reference, directional semantics, proper denominators and units, substantive synthesis of provided facts; no invented attribute measurements, causal mechanisms, unwarranted multivariate/pairwise statistical relationships, or group profiles outside the selected local task.
3. **Evidence is sparse:** a cautious, concise synthesis based on one or very few presented facts is preferable to an elaborate unsupported interpretation. This is an evidence-strength issue, not a requirement for the LLM to report or discuss excluded findings.

## Verified operational-document impact

| Function | Approved surgical change | File |
| --- | --- | --- |
| CATDES | Remove generic unreported-modalities and unshown-variables sentences; keep modality semantics and evidence-grounded analysis | [CATDES_MODULAR_PROMPT.md](CATDES_MODULAR_PROMPT.md) |
| CONDES | Remove selection/exhaustiveness and unseen-variable warning; keep significance-vs-strength distinction | [CONDES_MODULAR_PROMPT.md](CONDES_MODULAR_PROMPT.md) |
| DESCFREQ | Remove selection/unreported-columns warning; keep frequency-versus-distinctiveness distinction | [DESCFREQ_MODULAR_PROMPT.md](DESCFREQ_MODULAR_PROMPT.md) |
| DESCFREQ assembled variants | Synchronize all six documentary English assembled prompts | [DESCFREQ_ASSEMBLY_REVIEW.md](DESCFREQ_ASSEMBLY_REVIEW.md) |
| QDA | Remove without replacement the complete selection/undisplayed-attribute paragraph from the first `reading` proposal; remaining candidate wording awaits review | [QDA_MODULAR_PROMPT.md](QDA_MODULAR_PROMPT.md) |

## Runtime boundary — requires later implementation and tests

Current `R/nail_catdes.R` embeds the earlier approved CATDES reading, including cautions about unreported modalities. `R/nail_condes.R` dynamically introduces selection information in the prompt builder. `R/nail_qda.R` explicitly details sampling and undisplayed attributes in its guide, while `R/nail_descfreq.R` may mention prompt-selection settings in no-fact situations. These runtime prompts **have not yet been updated**.

Before integrating, compare these contracts across functions, update only the intended editorial instructions, preserve canonical evidence/selection/accessors/LLM output contracts, and verify with `devtools::load_all()`, manual representative examples (including sparse and positive-only cases), `devtools::test()`, `devtools::check()` when appropriate, `git diff`, targeted commit and push.

Long approved method references and pre-existing decision logs retain their historical scientific context; their detailed treatment of selection is not itself an LLM output instruction.
