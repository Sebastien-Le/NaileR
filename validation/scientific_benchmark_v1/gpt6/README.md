# NaileR scientific benchmark v1 — ChatGPT interpretation outputs

Source prompts and evidence were fetched from `Sebastien-Le/NaileR`, commit `1f49afef3aa17c137c115156e4854cede689dbfb`, directory `validation/scientific_benchmark_v1/`.

This bundle contains eight manually authored model responses that follow the eight exact prompts. All response files are UTF-8 text with no extra headers. These are **ChatGPT (GPT-6) conversational generations**, **not** Gemini/OpenAI API calls. There are **no real tokens, duration, HTTP metadata, or provider costs** for these responses.

`responses/` contains files whose basenames match the corresponding GitHub prompt files. `RESPONSE_MANIFEST.csv` maps each response back to its source prompt and SHA-256. `SCIENTIFIC_REVIEW.md` contains a separate interpretation-quality assessment and reproducible offline-reinjection instructions.

`nail_catdes_textual()` must be prepared as a second stage from parsed TEXTUAL objects; no composition response is included in this archive.

No GitHub branch was changed in preparing this bundle. If Codex publishes outputs, keep them on a dedicated validation branch and avoid merging generated responses into production package code.
