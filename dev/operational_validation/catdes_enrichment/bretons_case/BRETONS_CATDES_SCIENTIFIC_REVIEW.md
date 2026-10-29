# Breton CATDES with textual enrichment — preliminary scientific review

Date: 2026-10-29

## Scope

This validation uses the package-ready Breton subset derived from `distinction`:
485 respondents, 47 assertion variables and 485 non-missing English open
responses. A three-group ACM–HCPC partition was recomputed on the subset alone
with `set.seed(1)`, `ncp = 10` and `nb.clust = 3`.

This is an exploratory validation of the NaileR workflow. The group numbers are
local to this Breton analysis and must not be compared as if they were the
groups of the full Distinction sample.

## Technical results

| Item | Result |
| --- | --- |
| Group 1 | 133 respondents; 66 selected comments |
| Group 2 | 297 respondents; 148 selected comments |
| Group 3 | 55 respondents; 28 selected comments |
| CATDES evidence, classic vs enriched | identical |
| Textual sampling | `textual.sample = 0.5`, `textual.seed = 123` |
| First-pass prompt | 72,335 characters |
| Second-pass prompt | 104,391 characters |
| First response | 8,002 characters; status `generated` |
| Second response | 14,739 characters; status `generated` |
| Generation calls | 2 logical calls, one per pass; `max_tries = 1` |
| Total generation runtime | approximately 62 seconds; per-pass timings were not recorded by the wrapper |

The preview and generated first-pass prompts are identical. The selected text
IDs are also identical between preview and generation. Canonical CATDES
evidence is unchanged by the textual column and by the enrichment workflow.
Both generation statuses are `generated`, with no recorded error. The wrapper
does not provide an independent `finishReason`; completion therefore means a
non-empty returned response, not proof of provider-level normal termination.

## First-pass interpretation

The first response identifies a strong contrast in response intensity and
direction: Group 1 is described as predominantly strongly affirmative, Group 3
as predominantly strongly dissenting, and Group 2 as more moderate. This is a
reasonable synthesis of the displayed CATDES configuration.

The response also notes exceptions within Groups 1 and 3 rather than treating
them as perfectly homogeneous. That is useful and compatible with the
evidence. However, labels such as “consensus seekers”, “fervent advocates” or
“staunch critics” remain interpretive labels, not observed attributes of
respondents. The technical assertion identifiers in the response limit
substantive readability; they should be replaced by documented English labels
in a future user-facing example if available.

The small Group 3 (55 respondents) requires particular caution. No group-level
generalization beyond this exploratory sample is warranted.

## Enrichment supplied by the comments

The second pass adds a useful thematic layer to the statistical profiles. It
associates the comments with recurring themes such as locality and seasonality,
health and naturalness, ethics and sustainability, taste, affordability and
practical constraints. It also distinguishes Group 2's more qualified or
pragmatic formulations from the stronger polarity of Groups 1 and 3.

The most scientifically valuable contribution concerns Group 3: the comments
are broadly positive descriptions of desirable food qualities even though the
CATDES profile shows strong disagreement with many survey assertions. This
supports a careful distinction between rejecting specific propositions and
rejecting the idea of quality food in general. The comments do not establish
which assertion wording caused the disagreement.

## Limits and unsupported extensions

- The open question is not a direct response to every one of the 47 assertions.
  Comments can clarify what respondents mention as desirable, but they cannot
  explain the reason for every CATDES contrast.
- The interpretation cannot establish causes, behaviour, political attitudes,
  regional representativeness or membership in a sociological type.
- “Pragmatic”, “principled”, “alternative visionaries” and similar terms are
  hypotheses for scientific discussion, not statistical results.
- The enrichment response occasionally moves from thematic co-occurrence to
  claims about systemic skepticism, individualism or disillusionment. Those
  claims require direct grounding in specific assertions and comments before
  being accepted.
- The comments contain the raw material for richer interpretation, but their
  presence does not make an inference causal or representative.

## Recommended user examples

The reproducible examples are in `bretons_user_examples.R`. They show:

1. loading `bretons` from the package;
2. recomputing the subset-specific ACM–HCPC classification;
3. running classical CATDES with `generate = FALSE`;
4. running the two-pass textual preview with a fixed seed;
5. inspecting `nail_evidence()`, `nail_prompt()` and
   `nail_catdes_enrichment()`;
6. an explicitly disabled optional Gemini generation block.

The project authority has authorized publication of `bretons` with the same
documentation and schema as `distinction`. The bilingual audit object is not
needed by the package API and remains outside the package; the full generated
prompts and responses are experimental validation artefacts rather than
dataset documentation.

## Artefact hashes

| Artefact | SHA-256 |
| --- | --- |
| `PASS1_PROMPT.txt` | `e72c8400c00ac98e6093ff6d2e0699a268ff2ff720df03f5ca1dfdbf742d328e` |
| `PASS2_PROMPT.txt` | `6ae62a2537c003af581174a2d9a3e9fd2e014bac8246b7b119271d32832ec3a4` |
| `PASS1_RESPONSE.txt` | `968c5aef0734305b580671f40490e6f6d94039e92fc1b46ff427a4be5a7c8002` |
| `PASS2_RESPONSE.txt` | `9c6e1488ff358aaf11f57460b552a7fdf1f5ed29a4c4720d131e8ce5a1cbcbf9` |
| `CATDES_ENRICHED_PREVIEW.rds` | `f8cad62cdacd75f208579893252f3f2b20619007e0426e90fe0ebb714f3862b6` |
| `CATDES_ENRICHED_GEMINI_RESULT_PRIVATE.rds` | `0c16044c3f76c11f4b0a0bfb35aeb936665eb10e7f31605fa9a3a1c735927a22` |

The prompts, responses, selected texts and private RDS objects are stored in
`/private/tmp/nailer-bretons-distinction-20261029/validation/`. They contain
individual textual responses and are not public-package artefacts.
