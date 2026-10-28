# TEXTUAL scientific validation state

## Status

**Operational validation successful; preliminary scientific validation only,
not definitive.**

This record preserves the Gemini campaign run from the existing TEXTUAL
examples. It documents operational and traceability checks; it is not an
automatic scientific approval of the generated interpretations.

## Reference and campaign

- Branch: `dev-core5-condes-integration-20261015`
- Campaign scope: Fabric, Car Alone, Atomic Habits, Rorschach and Distinction
- Provider: Gemini
- Model: `gemini-2.5-flash`
- `generate = TRUE`, `max_output_tokens = 8192`, `max_tries = 1`, timeout 90 s
- 26 successful generations; no retry or provider error was recorded
- Total wall-clock duration: 366.7 s; mean 14.1 s; median 13.3 s

The campaign preserved the exact previews, prompts, raw responses, canonical
evidence, parsed profiles and execution metadata. The campaign was run from
an external validation script and did not modify package code, data or
internal prompt templates.

| Case | Generations | Main configuration |
|---|---:|---|
| Fabric | 2 | two observed groups, local prompts |
| Car Alone | 4 | four observed groups, local prompts |
| Atomic Habits | 3 | three constructed groups, local prompts |
| Rorschach | 10 | ten inkblots from panel A, local prompts |
| Distinction, global | 1 | 1,225 non-empty translated comments |
| Distinction, highest education | 6 | six observed education categories, sampled prompts |

The checks confirmed preview/generation prompt identity, canonical evidence
invariance, non-empty responses, usable accessors, available parsed profiles,
and valid references to the selected text IDs. The stable `TXT%06d` registry
was preserved. Structured profiles did not expose an additional `source`
field; this record therefore does not claim an `llm_pass1` provenance label.

## Scientific limits and review candidates

`isolate.groups = FALSE` remains local-first in the current TEXTUAL contract:
it combines local prompts/results and does not produce a global comparative
LLM synthesis. Sampling affects the interpretation input but not the complete
registered textual evidence. In particular, the Distinction education
preview uses `sample.pct = 0.1`; it is not exhaustive.

The candidate grounding material includes configurations supported by several
Car Alone or Atomic Habits comments, concepts that go beyond literal wording,
internal tensions, and claims whose link to specific comments is difficult to
reconstruct. These are review targets, not scientific scores or accepted
findings. A technical parse does not establish the validity of a claim, and
the comments do not by themselves establish causes, preferences or behaviour.

The Distinction outputs contain translated individual comments and must remain
subject to the project's private-data review before any redistribution.

## Archive

The complete review archive is kept outside Git:

`NaileR_TEXTUAL_Gemini_scientific_review.zip`

SHA-256:

`c5638e350dcf49239ccb2752e11ebafdc81672455d354adf8f9ce375397b2b9d`

The archive contains exact prompts and raw responses, evidence registries,
RDS results, metadata, reproducible scripts and grounding traceability files.
It contains no API key or bearer token, but its Distinction text material is
not automatically suitable for public distribution.
