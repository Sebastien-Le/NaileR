# NaileR — A/B interpretive deepening of the four remaining functions

Reference branch: `validation-interpretive-deepening-20261016`.

## Scope

These six cases cover the four NaileR functions not included in the initial A/B experiment:

- `nail_condes()` (one satisfaction target);
- `nail_descfreq()` (one frequency table, G1–G3);
- `nail_qda_space()` (one sensory axis);
- `nail_textual()` (three locally interpreted groups, G1, G2, G3).

For every case, condition A uses the **exact prompt and already generated GPT-6 response** from `validation/scientific_benchmark_v1/prompts/` and `gpt6/responses/`. Condition B keeps the entire A prompt verbatim except for one sentence appended to its request:

> When the evidence allows it, identify and explain the most informative insight that emerges from the configuration of findings rather than from any one finding alone, without presenting that insight as an additional demonstrated fact.

The B prompts and GPT-6-authored B responses are stored separately in `prompts/` and `responses/`. No code in `R/` and no default prompt in the package was edited.

## Evidence integrity and limitations

Each B prompt was built by inserting one sentence into the frozen A prompt. Exact string comparisons confirmed that removing that sentence recovers the original A prompt and that the `# Data` section is byte-identical. **This does not substitute for an R preview/reinjection test**, which Codex should run offline against the existing R objects and schemas.

The existing A responses were written and tested in the earlier GPT-6 benchmark. The new B responses were authored in this ChatGPT conversation with knowledge of the intervention. Only the external evaluation by Gemini will be **blind**. Do not report a statistically independent randomized model trial.

Important:
- `nail_descfreq()` has a selected marker **only for G2**; do not manufacture G1/G3 portraits.
- The original DESC frequency prompt treats rows as externally ordered, although the G1/G2/G3 identifiers are not substantively ordered. This historical weakness is preserved identically in A and B for comparability, not endorsed as scientifically appropriate.
- `nail_qda_space()` distinguishes a principal-component axis's correlated sensory attributes from product-specific markers. `choc3` contributes 75.01% to the axis; the positive and negative ends are not symmetric in product contribution.
- TEXTUAL cases contain only 4, 6 and 5 unique formulations for G1, G2 and G3, respectively, despite 32 comments each.
- No actual LLM API call or provider usage telemetry is implied by these offline response texts.

## Gemini blind review

Each of six cases must include the actual evidence and the two **full response texts** identified only by opaque codes, with order counterbalanced. The blinded reviewer receives no generation prompts, A/B labels, previous ratings or decoding key. Use F (statistical fidelity), M (multidimensional integration), E (interpretive emergence), P (epistemic restraint), each 0–4, with ties permitted.

After Gemini returns a finalized review, decode its six verdicts using the independent key. Evaluate both substantive improvement and violations of the source evidence.

## Next technical validation

Codex should check the six B prompts against actual `generate = FALSE` previews using the frozen R package, validate parsing for three TEXTUAL six-field outputs and parseability for other functions through a simulated no-network backend, verify canonical-evidence invariance, and publish reproducible reports. No NaileR package source changes.
