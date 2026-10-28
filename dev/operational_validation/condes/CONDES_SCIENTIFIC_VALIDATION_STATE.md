# CONDES scientific validation state

## Status

**Operational validation successful; preliminary scientific validation only,
not definitive.**

This document records the CONDES Gemini campaign completed from the existing
examples. It is a technical preservation record, not a scientific approval of
the generated interpretations.

## Reference and campaign parameters

- Repository branch: `dev-core5-condes-integration-20261015`
- Repository HEAD at campaign time: `23ca89f88ea3b894ff41dfe1d5dc684b4d3f98d2`
- Provider: Gemini
- Model: `gemini-2.5-flash`
- `generate = TRUE`
- `max_output_tokens = 8192`
- `max_tries = 1`
- `timeout = 90`
- Eight cases were executed sequentially.
- The external campaign allowed up to five attempts per case; all eight
  succeeded on the first attempt.

The statistical previews were generated and saved before the network calls.
No package code, dataset, statistical calculation or internal prompt was
modified for the campaign.

## Cases and technical results

| Case | Mode | Target | Retained markers | Duration (s) | Result |
|---|---|---|---:|---:|---|
| `decathlon_standard` | standard | `Points` | 25 | 10.46669 | success |
| `decathlon_pca` | latent | `Dim1` | 20 | 11.89454 | success |
| `agri_studies` | latent | `Dim1` | 39 | 15.05908 | success |
| `glossophobia` | latent | `Dim1` | 127 | 24.18942 | success |
| `beard_cont` | latent | `Dim1` | 29 | 15.07937 | success |
| `local_food` | latent | `Dim1` | 216 | 32.46619 | success |
| `irtsat_items_2024_2025` | latent | `Dim1` | 248 | 16.35164 | success |
| `distinction` | latent | `Dim1` | 243 | 21.26487 | success |

For all eight cases:

- `nail_prompt()` returned the exact prompt saved from `llm_io`;
- the generated prompt matched the offline preview byte-for-byte;
- `nail_evidence()` was identical between preview and generation;
- `nail_response()` returned a non-empty raw response;
- the provider, model and execution metadata were present in `llm_io`.

The current CONDES contract returns raw textual responses. It does not expose
the structured product-profile parser used by some other NaileR workflows.
Therefore a non-empty response and successful accessor checks do not establish
scientific validity.

## Preliminary scientific reading

The first reading is deliberately provisional. The outputs are retained for
grounding against the canonical evidence, with particular attention to:

- **Agri Studies:** whether a synthesis of several retained associations
  remains a description of reported expectations, without becoming a claim
  about ability, causes or general student characteristics.
- **Local Food:** whether the model combines several response associations
  into a coherent configuration while respecting the distinction between
  active statements, supplementary variables and observed behaviour.

These are candidates for further scientific grounding, not accepted
interpretations. Any attractive synthesis must be checked against the exact
evidence identifiers and statistics in the saved registries. Concepts added by
the model are not rejected merely because the wording is absent from a
variable label, but they require explicit evidential support before use.

The generated texts must also be checked for confusion between association and
causality, overstatement of low-ranked findings, and claims extending beyond
the measured variables.

## Archive

The complete review archive is:

`NaileR_CONDES_Gemini_scientific_review.zip`

SHA-256:

`90e074b572a37c1d53f95bfe0ec2ebd3480b6a7edd73a458c75988d120cd35da`

The archive contains the exact prompts and responses, RDS results, evidence
registries, `llm_io`, technical checks, parameters, durations and reproducible
external scripts. It contains no API key or bearer token.

## Limits

The current Gemini wrapper does not retain a provider finish reason, so normal
termination is not inferred from response non-emptiness. The archive is
intended for scientific review in ChatGPT and by the project researcher. No
final scientific conclusion should be drawn from this state record alone.
