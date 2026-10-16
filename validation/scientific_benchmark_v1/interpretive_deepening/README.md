# Interpretive deepening preview experiment

No package source, default prompt, statistical calculation or LLM call
was changed or executed. Conditions A and B use the same data, evidence,
context, public options and output contracts. B appends exactly one
sentence to the complete reference request for each function.

## Conditions

- A: validated reference request.
- B: reference request plus: `When the evidence allows it, identify and explain the most informative insight that emerges from the configuration of findings rather than from any one finding alone, without presenting that insight as an additional demonstrated fact.`

## Checks

All evidence comparisons passed: TRUE
All canonical attribute comparisons passed: TRUE
All prompt differences are limited to the added sentence: TRUE

Six previously published CATDES-TEXTUAL prompts unchanged: TRUE
The earlier export bug came from unnamed one-prompt lists: CATDES and
QDA prompts were silently skipped by loops over names(). prompt_list()
now names a unique prompt `portfolio`, rejects empty or ambiguous lists,
and the manifest contains exactly ten prompt rows.

The previews are fixtures for a later blind interpretation comparison;
no model response is included or inferred in this experiment.
