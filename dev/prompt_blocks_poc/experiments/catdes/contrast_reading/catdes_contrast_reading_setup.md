# CATDES contrast-reading benchmark setup

branch: dev-catdes-prompt-audit
HEAD: c06d1d81106241aaa54540a6784a8d301f69588e
dataset: NaileR::atomic_habit (167 rows, 50 columns)
target: never_plane_capable (column 2)
category: I feel able not to take the plane
interpretation_mode = standard
isolate.groups = TRUE
quali.sample = 1; quanti.sample = 1; drop.negative = FALSE

canonical/selected evidence IDs: 12; identical R2/R3 = TRUE
qualitative markers: 10
quantitative markers: 2

Internal semantic-facing qualitative classification (not shown to LLM):
- binary_complete_contrast: never_plane_restrictive | linen_capable
- multilevel_selected_only: never_plane_capable_restrictive | linen_capable_restrictive | local_products_capable_restrictive

Exact R2 reading:

R has already performed the statistical analysis. Read each statement below as a factual comparison between this group and the full sample. MORE FREQUENT and LESS FREQUENT describe relative modality prevalence; HIGHER and LOWER describe the group mean relative to the full-sample mean for the same variable. When percentages are shown, the group percentage describes the modality within this group and the full-sample percentage describes the same modality in the full sample; these are descriptive values, not p-values or measures of statistical strength. When means are shown, compare the group mean only with the full-sample mean for that same variable; do not compare mean values across variables as if they shared one scale. An undisplayed modality or variable is not thereby absent, average, rejected, or unimportant.

Exact R3 reading:

R has already performed the statistical analysis. Read each statement below as a factual comparison between this group and the full sample. MORE FREQUENT and LESS FREQUENT describe relative modality prevalence; HIGHER and LOWER describe the group mean relative to the full-sample mean for the same variable. When percentages are shown, the group percentage describes the modality within this group and the full-sample percentage describes the same modality in the full sample; these are descriptive values, not p-values or measures of statistical strength. When means are shown, compare the group mean only with the full-sample mean for that same variable; do not compare mean values across variables as if they shared one scale. An undisplayed modality or variable is not thereby absent, average, rejected, or unimportant. For a binary qualitative variable, two displayed modalities may be complementary sides of the same significant contrast and should be interpreted together. For a multi-level qualitative variable, interpret only the modalities displayed below; do not infer the status of unshown modalities.

Exact shared displayed evidence:

- The response/modality "I don't feel able not to take the plane.never plane is restrictive" for variable/proposition "never plane capable restrictive" is LESS FREQUENT in this group than in the full sample (group=0.00%; full sample=43.11%).
- The response/modality "I feel able not to take the plane.never plane is not restrictive" for variable/proposition "never plane capable restrictive" is MORE FREQUENT in this group than in the full sample (group=76.54%; full sample=37.13%).
- The response/modality "I feel able not to take the plane.never plane is restrictive" for variable/proposition "never plane capable restrictive" is MORE FREQUENT in this group than in the full sample (group=23.46%; full sample=11.38%).
- The response/modality "I don't feel able not to take the plane.never plane is not restrictive" for variable/proposition "never plane capable restrictive" is LESS FREQUENT in this group than in the full sample (group=0.00%; full sample=8.38%).
- The response/modality "never plane is not restrictive" for variable/proposition "never plane restrictive" is MORE FREQUENT in this group than in the full sample (group=76.54%; full sample=45.51%).
- The response/modality "never plane is restrictive" for variable/proposition "never plane restrictive" is LESS FREQUENT in this group than in the full sample (group=23.46%; full sample=54.49%).
- The response/modality "I don't feel able to let my washing air dry rather than use a tumble dryer.linen is restrictive" for variable/proposition "linen capable restrictive" is MORE FREQUENT in this group than in the full sample (group=12.35%; full sample=7.19%).
- The response/modality "I feel able to buy only locally sourced food products.local products is restrictive" for variable/proposition "local products capable restrictive" is MORE FREQUENT in this group than in the full sample (group=25.93%; full sample=19.16%).
- The response/modality "I feel able to let my washing air dry rather than use a tumble dryer" for variable/proposition "linen capable" is LESS FREQUENT in this group than in the full sample (group=87.65%; full sample=92.22%).
- The response/modality "I don't feel able to let my washing air dry rather than use a tumble dryer" for variable/proposition "linen capable" is MORE FREQUENT in this group than in the full sample (group=12.35%; full sample=7.78%).
- The mean of "From 0 to 5 never plane is restrictive" is LOWER in this group than in the full sample (group mean=1.68; full-sample mean=2.68).
- The mean of "From 0 to 5 turn off is restrictive" is HIGHER in this group than in the full sample (group mean=1.93; full-sample mean=1.65).

R2 prompt characters: 4956
R3 prompt characters: 5246
Difference: 290

provider: ollama
model: mistral-small3.2
temperature = 0.7; top_p = 0.9; top_k = 40; stream = FALSE
No seed supplied to Ollama; identical generation settings for all six calls.
3 R2 + 3 R3 = 6 fresh responses.

Invariance: canonical evidence, selected IDs, displayed evidence, order, percentages, means, context, question, interpretation, local task, output contract, model, and generation parameters are identical. Only the reading block differs.
R3 is exactly R2 followed by the two contrast-aware sentences.

Blind assignment uses set.seed(20261008). The key is stored separately in catdes_contrast_reading_blind_key.csv.
