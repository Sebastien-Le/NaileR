# NaileR interpretive deepening — exploratory A/B generations

Reference commit for exact A/B prompts: `339c26de2365e76301243b274e05a5ebe7a839d5`.

The experiment changes **exactly one sentence in the request** between A and B. All statistical/textual evidence, context, default guide blocks and output contracts are unchanged. The original NaileR code and default prompts were not modified.

The five **A** prompts are byte-identical to those used in the prior, already validated ChatGPT (GPT-6) campaign. Rather than regenerate A with a different conversational context, the comparison reuses those **five existing A responses** from `gpt6/responses/` and `gpt6/composition/responses/`.

The five newly authored **B** responses are in `interpretive_deepening/responses/`. They are original ChatGPT (GPT-6) conversation drafts against the B prompts, **not** results of API calls to Gemini/Ollama/OpenAI. There is no authentic provider usage, token count or API cost to report. Do not impute zero usage/cost metadata to fake an API result.

`RESPONSE_PAIR_MANIFEST.csv` maps each exact pair of prompts and responses. All file paths in that CSV are relative to `validation/scientific_benchmark_v1/`. Git blob SHA-1 identifiers identify the exact stored raw response bytes and are distinct from raw SHA-256 prompt hashes.

`EXPLORATORY_REVIEW.md` records an **unblinded qualitative** comparison; this experiment is not a causal or statistically conclusive evaluation of prompt efficacy. The previously published A files are known to parse in offline NaileR reinjection. The new B files **have not yet been parsed by NaileR** and must undergo the same checks through a no-network simulated backend.

QDA B retains exactly six `NAILER_PRODUCT_INTERPRETATION` blocks, one per product. CATDES-TEXTUAL B uses exactly the five required fields in order for each group. Do not silently change any response bytes when reinjecting.
