# QDA scientific validation state

Date: 2026-10-28
Package branch: `dev-core5-condes-integration-20261015`
Package commit used for the consolidated campaign: `06758d5e88f1dfc05aca9fe247e89805cc5de373`

## Scope and operational outcome

The consolidated Gemini campaign covered the five sensory studies used in the
QDA examples:

| Study | Active prompts | Selected markers per prompt | Gemini responses |
|---|---:|---:|---:|
| Chocolates | 6 local product prompts | 46 | 6 |
| Strawberries | 1 joint prompt | 17 | 1 |
| Apples | 1 joint prompt | 92 | 1 |
| Perfumes | 1 joint prompt | 89 | 1 |
| Melons | 6 local product prompts | 15 | 6 |
| **Total** | **15** | — | **15** |

All fifteen responses were retained as raw outputs together with the exact
prompts, canonical evidence, selected markers, generation metadata and parsed
product interpretations. The campaign was an operational validation of the
generation and traceability path; it is not a definitive scientific
validation of the sensory interpretations.

## Corrective event

The three first joint attempts for Strawberries, Apples and Perfumes stopped
before an HTTP request because the backend received a one-element list where
the provider contract required one non-empty character string. The minimal
fix was committed in `06758d5` (`fix(qda): pass scalar prompt for joint
generation`). It changes only the joint prompt transmission path and adds a
mocked regression check; the QDA computations, markers, prompts and public
accessors were preserved.

The three studies were then regenerated with their original prompts and
parameters. Chocolates and Melons were not regenerated after the fix.

## Traceability and invariance checks

The campaign checks reported:

- exact equality between preview prompts and prompts recorded for generation;
- invariance of canonical QDA evidence between preview and generated objects;
- preservation of product identifiers, marker references and group metadata;
- successful retrieval through `nail_evidence()`, `nail_prompt()` and
  `nail_response()`;
- fifteen parsed product interpretations with status `available` and source
  `llm_pass1`.

These checks establish operational and provenance integrity. A parsed
structured response is not, by itself, evidence that its claims are
scientifically warranted.

## Preliminary scientific reading

The first review identified potentially useful configurations of sensory
families for a later, evidence-by-evidence grounding exercise. The main
candidates are:

- Apples, where the joint response combines several families of descriptors
  and should be checked against the exact marker directions and magnitudes;
- Perfumes, where semantic labels can invite extrapolation beyond the
  measured descriptor associations;
- Chocolates, especially the `choc3` profile whose highly concentrated
  contribution makes balanced two-pole narratives potentially misleading.

The proposed sensory families are useful hypotheses for review, not validated
constructs. Any evaluative wording about liking, quality or consumer
preference must remain separate from the descriptive QDA evidence. The panel
data support statements about measured sensory profiles and their statistical
associations; they do not by themselves establish consumer judgments,
causes, market value or superiority.

## Archive

The consolidated review archive is kept outside Git:

`/private/tmp/NaileR_QDA_Gemini_scientific_review.zip`

Recorded SHA-256:

`6b9f77469ff1b02342075be9bc5d5b515f60b95027a4bcb1f7ad5826eb8c7b14`

The archive contains the fifteen prompts and raw responses, evidence and
parsed outputs used for the review. Secrets and API credentials are excluded.

## Status

**Operational validation successful; preliminary scientific validation only,
not definitive.**

The next scientific step is grounding candidate claims to the canonical QDA
markers and product-level evidence. No conclusion about the quality or
validity of the Gemini narratives should be inferred from this operational
state document alone.
