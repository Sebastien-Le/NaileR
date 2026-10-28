# DESCFREQ scientific validation state

## Status

**Operational validation successful; preliminary scientific validation only,
not definitive.**

This record preserves the DESCFREQ Gemini campaign completed from the three
existing examples. It is not an automatic scientific rating of the generated
interpretations.

## Campaign results

- 8 Beard responses: `B1`–`B8`;
- 1 Children comparison response;
- 1 Rorschach comparison response;
- 10 non-empty Gemini responses in total;
- 70 retained Beard markers, 10 Children markers and 22 Rorschach markers;
- model: `gemini-2.5-flash`;
- provider: Gemini;
- `max_tries = 1`, `max_output_tokens = 8192`, timeout 90 seconds;
- no automatic retry was used.

For every output, the preview and generated canonical evidence were
identical. The generated prompts matched the previews, and
`nail_evidence()`, `nail_prompt()` and `nail_response()` returned usable
objects. The current Gemini wrapper does not provide a provider finish reason;
termination is therefore not inferred beyond the recorded non-empty response.

For Beard, the recorded duration is the aggregate wall-clock duration of the
single `nail_descfreq(generate = TRUE)` invocation containing eight isolated
calls; per-profile durations are not exposed by the current `llm_io` contract.

## Preliminary grounding candidates

The raw outputs are retained for review. Two particularly useful candidates
for later grounding are:

- **Children:** the proposed transition from immediate economic and
  unemployment concerns at lower education levels to future-oriented concerns
  at intermediate levels, and the separate University pattern. The exact
  markers are retained in the evidence registry and prompt files; extensions
  such as financial stability or family planning must be checked against the
  measured terms.
- **Beard B5:** the synthesis of `goatee`, `fifties`, scientist/computer
  scientist and quirky/corny descriptors into a retro or intellectual profile.
  This is a candidate configuration, not an accepted social characterization.

These passages are hypotheses for scientific discussion. They must not be
treated as direct measurements, causal claims, preference statements or
validated descriptions without checking the complete frequency profiles.

## Archive

The exact campaign archive is:

`NaileR_DESCFREQ_Gemini_scientific_review.zip`

SHA-256:

`9fdec540238f1dadb9afe39e43869a04d038de9a09e8f81f35b55f5ed1ccd6a7`

The archive contains the contingency tables, complete frequency profiles,
selected evidence, prompts, raw responses, RDS objects, parameters, hashes,
accessor checks and candidate grounding passages. No API key or bearer token
is included.

## Limits

The outputs remain subject to a human scientific review. Parsing or a
non-empty response would not establish interpretive validity. In particular,
the data describe frequency profiles and reported categories; they do not by
themselves establish personality, causality, preference or behaviour.
