# CATDES textual enrichment — scientific state

## Campaign identity

- Dataset: `atomic_habit_clust`
- Campaign date: 29 October 2026
- Branch: `dev-core5-condes-integration-20261015`
- Execution commit: `0497a4539ae3ccc66c6b45ea0e28f7bec201e5ed`
- Ancestry check: the execution commit is a descendant of `ed76c217`.
- Statistical mode: `latent`, joint (`isolate.groups = FALSE`)
- `num.var = 51`, `num.textual = 31`
- `textual.sample = 0.5`, `textual.seed = 123`
- Provider/model: Gemini / `gemini-2.5-flash`
- `max_output_tokens = 8192`, `timeout = 90`
- Backend `max_tries = 5`, with no external retry loop

## Technical outcome

Two logical calls succeeded: one first-pass CATDES interpretation and one
second-pass textual enrichment. Both succeeded on their first backend attempt;
the retry log contains two POST events and no retry notices. The first response
contains 8,850 characters and the second 13,661 characters; total elapsed time
was 67.948 seconds.

The generated first-pass prompt is identical to the approved preview. The
canonical CATDES evidence is identical to the offline preview and to classic
CATDES without the textual column. The seeded text selection is identical to
the offline preview. All 51 `TXT` identifiers cited in the second response are
present in the selected registry.

The wrapper does not preserve the provider `finishReason`. Non-empty complete-
looking responses are therefore not treated as proof of a normal provider
termination.

## Scientific findings

### Groups 1 and 3

The comments genuinely enrich the interpretation of the solo-car dimension.
For group 1 they add concrete logistical, scheduling, rural, family and
alternative-transport pathways behind a generally lower perceived restriction.
For group 3 they clarify how schedules, spontaneity, geographical isolation,
family arrangements, autonomy and comfort can be experienced as constraints.
The comments also show that “feeling able not to take a car alone” can reflect
different pathways, including not owning a car or already using alternatives.

These are useful contextual qualifications, but they remain limited to the
car-alone question and cannot explain every CATDES dimension.

### Group 2

Group 2 contains 13 observations and only 6 selected comments. The comments
are technically grounded and describe alternative mobility, cost or
environmental considerations, but they do not directly cover the group's main
statistical contrasts concerning household practices and air travel. Their
limited coverage makes any substantive generalization especially fragile.

## Traceability error

The first and second responses describe “I love meat too much” as an open-ended
comment. It is actually a CATDES modality of the `vegan_text` variable. It is
statistically present in the prompt, but it is not part of the selected
`car_alone_text` comment corpus. This is a source-identification error that
must be corrected in any scientific use of the response; the raw response is
preserved unchanged.

## Interpretive hypotheses and limits

The responses propose interesting hypotheses about the interaction of perceived
capability with existing lifestyles, structural conditions and autonomy. They
also suggest an “awareness-action gap”. These are hypotheses, not demonstrated
psychological or causal mechanisms.

The main risk is generalizing from comments about solo-car use to the complete
multidimensional environmental profile. The second pass is therefore best
described as a contextual enrichment of one dimension, not a complete
explanation of the groups.

## Grounding questions for future review

1. Does each cited `TXT` passage support the exact claim made around it?
2. Are modality-level CATDES findings consistently distinguished from raw
   comments?
3. Are labels for groups 1 and 3 still warranted after accounting for
   within-group heterogeneity?
4. Is the group 2 evidence sufficient for any label beyond its original ID?
5. Which proposed syntheses remain valid when restricted to the car-alone
   question?
6. Can the `vegan_text` source confusion be prevented by a more explicit output
   schema or provenance display?

## Artifact references and SHA-256

The following hashes refer to the original local artifacts. Raw responses and
RDS files remain private and must not be published without confidentiality
review.

| File | SHA-256 |
|---|---|
| `gemini_retry_20261029/run_catdes_enrichment_gemini_retry.R` | `f066b2688bbfe8b7ec456c7dffcf555e527319993da992177b03e6770750c33c` |
| `gemini_retry_20261029/CATDES_ENRICHMENT_GEMINI_FULL.rds` | `6da0182c23862756aa07268816234b36c0de70178c1eea6a64fbe001d54ceb41` |
| `gemini_retry_20261029/CATDES_ENRICHMENT_GEMINI_RESULT.rds` | `e68147e92913fd7ae13e5e128946ea870426b2a61bd0b3580325f48d3113ac15` |
| `gemini_retry_20261029/PASS1_PROMPT.txt` | `5d000d5174d104050ea8c9f7ff78d90091c2efb9f4ba26d4caf8a1f9d213dc7b` |
| `gemini_retry_20261029/PASS1_RESPONSE.txt` | `fb93cbb6c2e250313b415299e6b44a340283106f4e177299491c1dc6345e3ba9` |
| `gemini_retry_20261029/PASS2_PROMPT.txt` | `efef9cde8d6ff9308f56d9c0fe5152b69510c90d049411c1d8182cff3c8aa3e9` |
| `gemini_retry_20261029/PASS2_RESPONSE.txt` | `b4a17ae929e2f02cc8724e048d44ea292fa930db93906d5b734aa25d15ed43d7` |
| `gemini_retry_20261029/EVIDENCE_REGISTRY.csv` | `ba919f0741ab99625eacf4d5166ac01c87cd9f95cf696a6765fd06edfa5a8bf4` |
| `gemini_retry_20261029/SELECTED_TEXT_IDS.csv` | `c448f4aa6bf77dce804c872e3a65939afc31196d1c7f62f47a87944b47b48866` |
| `gemini_retry_20261029/RETRY_LOG.txt` | `e9c66b2abe6ef75954de5579b190bcf6a2347d74f5bd1394778f9a0f497a20e3` |
| `gemini/GENERATION_ERROR.txt` (initial failed attempt) | `f0859ea227b7d4ce6e7048d85f54dcb1a653945f99a0e31ad6c2e232f58e9e01` |
| `gemini/CATDES_ENRICHMENT_GEMINI_RESULT.rds` (initial failed attempt) | `b642c0e0a3218311bbcb9e3c18e01fba18ab076e5e5b16e6da641cb55a6d089c` |
| `ATOMIC_HABITS_PROMPT_PASS1.txt` (offline baseline) | `222c3dbba2f170c23e28ba5f6daef97053194fe8a769c28847672c6718f38f29` |
| `ATOMIC_HABITS_ENRICHMENT_ARTIFACT.rds` (offline baseline) | `26bc589dd5b5d5eb9d2a2abfcec1183324ab824e5c5939e0d8a5a91f9317f0c6` |

The metadata discrepancy and its correction are documented in
`gemini_retry_20261029/METADATA_CORRECTION.md`. The historical full RDS is
not modified.

## Publication status

This is an operational and scientific review state, not a definitive
validation of the LLM interpretation. No package code, tests, prompts or
examples were modified for this campaign.
