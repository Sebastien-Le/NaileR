# CATDES `isolate.groups` scope contract

This note records the CATDES interpretation-scope contract restored on the
`dev-catdes-prompt-audit` branch. It is a development artifact, not package
documentation.

## Decision history

The historical CATDES contract was `FALSE` = one joint prompt and `TRUE` =
one prompt per category/group. An August local-first change made the first
semantic pass local for both settings. This PASS deliberately revises that
choice: `FALSE` is again joint, while `TRUE` remains the autonomous local
portrait mode.

Statistical relativity does not by itself determine the appropriate LLM
interpretation scope. `isolate.groups` controls whether CATDES evidence is
interpreted jointly or as autonomous group portraits.

## Scope

`isolate.groups` changes only the scope of the LLM interpretation after the
canonical and semantic-facing evidence have been built. It does not change
the statistical computation, evidence selection, evidence IDs, sampling, or
the semantic-facing text.

## `isolate.groups = FALSE`

CATDES builds one `portfolio` prompt containing the evidence for all selected
categories or groups. When generation is requested and selected evidence is
available, this prompt is sent in one backend call. The response is a joint
interpretation: it can describe each profile and compare the displayed
profiles. The ordinary returned backend data frame contains this actual joint
response.

The local prompts remain available as audit material, but they are not used
for generation. `semantic_profiles` therefore does not fabricate a separate
response for each group; group responses are `NULL`, with metadata recording
`architecture = "joint"` and
`local_responses_generated = FALSE`.

Isolation can also be useful when a joint CATDES prompt becomes too large for
the selected LLM.

## `isolate.groups = TRUE`

CATDES builds one named local prompt per ready category or group. Generation
uses one backend call per ready group, and the returned list contains the
corresponding autonomous local portraits. The prompt-block artifact is a
named list by category/group, and `semantic_profiles` records the local
responses.

## Prompt blocks

Both scopes retain the same conceptual block keys:

```text
context, reading, question, interpretation, local_task, evidence, output
```

There is no `global_task` block. In joint mode the `portfolio` blocks use
plural interpretation rules and a global scope task; in local mode the
existing singular local wording is preserved. The joint reading explicitly
states the comparison unit and guards against presenting a displayed contrast
as an unshown pairwise statistical test.

## Invariants and validation

The two scopes reuse the same `statistical_profiles`,
`interpretation_evidence`, and `semantic_facing_evidence`; only their prompt
projection and generation scope differ. No second-stage synthesis or parser
was introduced. The targeted CATDES prompt-block, stage 2, stage 3, and
LLM-IO tests pass, and the complete test suite passes with 1069 PASS, 0 FAIL,
and 0 WARN.
