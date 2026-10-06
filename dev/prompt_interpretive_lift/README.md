# NaileR interpretive-lift blind benchmark

This directory contains a prompt-only A/B benchmark prepared from the NaileR
2.1.0 baseline and the local `dev-prompt-interpretive-lift` working tree.

No LLM call is made by the preparation step. All cases use `generate = FALSE`.
The prompts were generated in two separate checkouts with the same data,
statistical options, introductions, requests, provider/model settings, and
`sample.pct = 1` where the API exposes that argument.

## Files

- `prompt_bundle_blinded.md`: exact prompts with blind identifiers only;
- `responses_blinded.md`: empty response slots for ChatGPT responses;
- `blinding_key.csv`: private mapping from blind identifiers to versions;
- `benchmark_prompts.qmd`: report template and post-response evaluation workflow.

The deterministic blinding seed is `20261006`. Do not transmit
`blinding_key.csv` with `prompt_bundle_blinded.md`.

## Cases

1. `nail_qda()` on `SensoMineR::sensochoc`;
2. `nail_condes()` standard on `FactoMineR::decathlon` Points;
3. `nail_condes()` latent on a PCA Dim1 constructed from decathlon;
4. `nail_catdes()` standard on `iris` Species;
5. `nail_catdes()` latent on constructed groups from `atomic_habit_clust`;
6. `nail_descfreq()` description on `beard_cont`;
7. `nail_textual()` on the Fabric A consumer comments.

The latent CONDES and CATDES cases are witnesses: their prompts should remain
identical across versions. The selected canonical evidence and selected
evidence hashes were checked before the bundle was created and are identical
within every A/B pair.

The CATDES latent witness also records an independent follow-up issue. A name
for a constructed group must not automatically turn perceived capability,
intention, or attitude into observed behavior. The term `adopters` in the
latent benchmark response should be revisited in a later, separate chantier;
it is not part of the current interpretive-lift adjustment.

## Procedure

1. Send only `prompt_bundle_blinded.md` to ChatGPT.
2. Copy each complete response into the matching slot in `responses_blinded.md`.
3. Render `benchmark_prompts.qmd`.
4. Score each response before consulting the final reveal section.

Use the six requested criteria: Interpretive value, Grounding / traceability,
Calibration, Synthesis, Unsupported overreach, and Paraphrase tendency. Use
the 0--2 scales defined in the Quarto document and add a qualitative comment.
Do not compute an automatic global score at this stage.

## Historical sources consulted

The cases reuse the current operational examples in
`dev/NaileR_operational_stabilization_examples.R`, which themselves preserve
the public accessor workflow `nail_evidence()`, `nail_prompt()`, and
`nail_response()`.

The pedagogical introductions and requests were cross-checked against the
CRAN 1.2.3 reference manual and vignette, especially the examples for
`sensochoc`, `decathlon`, `iris`, `beard_cont`, `fabric`, and
`atomic_habit_clust`. Historical variants in `R_old/` and `R_old_old/` were
used only as wording references; no legacy internal access was reintroduced.
