# CATDES–TEXTUAL: offline GPT-6 benchmark interpretation responses

This directory contains three **ChatGPT GPT-6 conversation-authored** interpretation responses for `nail_catdes_textual()`, prepared from the *exact* second-stage prompts exported by Codex.

Source: `Sebastien-Le/NaileR`, branch `validation-seven-functions-gpt6-20261016`, commit `06865aaa6b0c451495cec436d9f5730c141af31d`. Underlying package source commit: `f697f006e04faa8f9613885ec40cd37799bd7282`.

## Contents

- `responses/catdes_textual_G1.txt`, `G2.txt`, `G3.txt` contain **only** the five response fields requested by the respective prompts, in the original order.
- `COMPOSITION_MANIFEST.csv` maps each response to the source prompt SHA-256 and exact Git blob SHA-1 of the response file. File references are relative to `validation/scientific_benchmark_v1/gpt6/`. Git blob SHAs are Git's content-object identifiers, not a substitute for raw-file SHA-256.
- `SCIENTIFIC_REVIEW.md` is separate from the machine-ingestable responses.

These responses are **not** Gemini/OpenAI API completions. No real provider token, elapsed-time, HTTP status or cost observations exist. They must remain absent/NA, never fabricated as zero. Prompt identity, parsing, object attachment, `nail_usage()`, and statistical evidence invariance still require offline validation by Codex.

Do not modify the NaileR source, the underlying CATDES or TEXTUAL evidence, or the user prompts when reinjecting these responses.
