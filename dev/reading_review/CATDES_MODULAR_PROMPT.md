# CATDES modular prompt — bilingual validation

**Status:** IN PROGRESS — block-by-block scientific validation.
**Branch:** `dev-statistical-prompt-framework`
**Methodological source:** [CATDES_REFERENCE_PROMPT.md](CATDES_REFERENCE_PROMPT.md) (approved).
**Earlier compact proposal:** [CATDES_COMPACT_PROMPT.md](CATDES_COMPACT_PROMPT.md) (draft, not approved).

This file records **only instructions explicitly validated in conversation**. Approval of a block does not imply that the full modular prompt is approved, implemented in R, or experimentally validated on local LLMs. English is the prospective operational text; French is a faithful validation translation.

## 1. `reading` — APPROVED (scientific wording, 2026-10-14)

### English — operational text

The results come from `FactoMineR::catdes()`. Each qualitative finding compares the frequency of a response modality within a group with its frequency in the full analyzed sample.

MORE FREQUENT indicates statistical overrepresentation; LESS FREQUENT indicates statistical underrepresentation. The full sample is the reference, not another group.

Overrepresentation does not necessarily imply a majority within the group. Interpret each direction together with the reported group and full-sample percentages.

Interpret each response modality according to its actual meaning, including negation and, when relevant, its position on an ordered scale. Do not infer the distribution of unreported modalities from a single displayed result.

Each quantitative finding compares a variable's mean within a group with its mean in the full analyzed sample. HIGHER and LOWER indicate that the group mean is statistically higher or lower, respectively.

Read each difference according to what the variable measures, its unit when known, and the meaning of high and low values. Do not assume that higher means better or lower means worse.

If the variable's meaning, scale, or unit is unclear, do not invent it. Do not compare means of unrelated variables as if they were measured on the same scale.

Base your analysis on the provided statistical evidence. Do not make assumptions about variables or modalities that are not shown.

### Français — traduction de contrôle validée

Les résultats proviennent de `FactoMineR::catdes()`. Chaque résultat qualitatif compare la fréquence d'une modalité de réponse dans un groupe à sa fréquence dans l'ensemble de l'échantillon analysé.

MORE FREQUENT indique une surreprésentation statistique ; LESS FREQUENT indique une sous-représentation statistique. La référence est l'échantillon complet et non un autre groupe.

Une modalité surreprésentée n'est pas nécessairement majoritaire dans le groupe. Chaque résultat doit être interprété en tenant compte des pourcentages observés dans le groupe et dans l'échantillon complet.

Chaque modalité de réponse doit être interprétée selon sa signification réelle, notamment lorsqu'elle comporte une négation ou, le cas échéant, selon sa position sur une échelle ordonnée. Ne pas déduire la distribution des modalités non présentées à partir d'un seul résultat.

Chaque résultat quantitatif compare la moyenne d'une variable dans un groupe à sa moyenne dans l'ensemble de l'échantillon analysé. HIGHER et LOWER indiquent respectivement que la moyenne du groupe est statistiquement supérieure ou inférieure à celle de l'échantillon complet.

Chaque différence doit être comprise en tenant compte de ce que mesure la variable, de son unité lorsqu'elle est connue et de la signification des valeurs élevées ou faibles. Il ne faut pas supposer qu'une valeur élevée est nécessairement meilleure, ni qu'une valeur faible est nécessairement moins bonne.

Si la signification, l'échelle ou l'unité de mesure d'une variable n'est pas claire, il ne faut pas l'inventer. Il ne faut pas non plus comparer les moyennes de variables différentes comme si elles étaient mesurées sur la même échelle.

Fondez votre analyse sur les résultats statistiques présentés. Ne faites pas d'hypothèses sur les variables ou les modalités qui ne sont pas présentées.

### Scope and decisions

- `reading` is shared by `standard` and `latent` modes; group identity and substantive profile-building belong to separate blocks.
- Interpret ordered modalities according to their supplied meanings, without inferring unshown distributions.
- Interpret quantitative directions in light of measurement meaning, units, and scale orientation, without inventing unknown units.
- Keep operational instructions concise; do not include irrelevant illustrative examples (e.g., 100-metre race times). Such examples belong to evaluation tests.
- The user decides evidence-selection options. The LLM interprets what is displayed; the prompt need not detail internal `sample.pct` or `drop.negative` behavior.
- Optional analyst-provided variable descriptions may currently be part of the introduction. A separate `variable_context` block is an **unapproved future architectural idea**, not an implemented or validated feature.

## 2. `interpretation` — NOT YET REVIEWED

No operational wording approved.

## 3. `standard` / `latent` — NOT YET REVIEWED

No operational wording approved.

## 4. `local_task` / `global_task` — NOT YET REVIEWED

No operational wording approved.

## 5. `output` — NOT YET REVIEWED

No operational wording approved.

## Change policy

Append or modify only an explicitly user-approved bilingual block and record its status. Preserve the approved scientific reference unchanged; do not change NaileR R code or the pending compact draft as a consequence of this document alone.
