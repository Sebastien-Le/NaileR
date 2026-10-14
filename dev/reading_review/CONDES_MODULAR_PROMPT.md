# CONDES modular prompt — bilingual scientific review

**Status:** IN PROGRESS — `reading` English operational block explicitly APPROVED (2026-10-14); remaining blocks pending.
**Branch:** `dev-statistical-prompt-framework`.
**Methodological source:** [CONDES_REFERENCE_PROMPT.md](CONDES_REFERENCE_PROMPT.md) (approved).
**Earlier compact proposal:** [CONDES_COMPACT_PROMPT.md](CONDES_COMPACT_PROMPT.md) (draft, not approved).

This file records only explicitly approved operational instructions. English is the operational wording. French is the accompanying scientific control translation. This approval does not authorize changes to R code, evidence representation or runtime prompts.

## 1. `reading` — APPROVED (English wording, 2026-10-14)

### English — approved operational text

The results come from `FactoMineR::condes()` and describe the associations of one quantitative target with other variables. R has performed the statistical calculations; interpret the displayed evidence without inventing additional findings.

For quantitative predictors, a POSITIVE correlation means that higher predictor values tend to accompany higher target values; a NEGATIVE correlation means that higher predictor values tend to accompany lower target values. The absolute correlation indicates the strength of the linear association. Interpret directions according to the meaning and orientation of each variable's scale. Higher values do not necessarily mean better outcomes.

For qualitative predictors, R² describes the overall association between the variable and the target. It has no direction and does not identify the contribution of any particular category.

A positive or negative Estimate indicates that a category is associated with higher or lower target values, respectively, relative to the reference of the fitted one-factor model (sum-to-zero coding). Estimate is expressed in the target's units. It is not necessarily a difference from the overall sample mean or an effect adjusted for other predictors.

Derived states such as Above-average value and Below-average value come from the original quantitative predictors. They are not independent measurements. Use them to illustrate or qualify the continuous associations, not as separate confirmations.

Statistical significance does not measure association strength or substantive importance. The displayed evidence may be selected rather than exhaustive. Do not infer results for variables or categories that are not shown.

Preserve the meaning of variables and categories, including negations and reverse-worded labels. Use the study context to understand the measurements, without treating that context as additional statistical evidence. Do not infer causality from these associations.

### Français — traduction de contrôle soumise avec le bloc approuvé

Les résultats proviennent de `FactoMineR::condes()` et décrivent les associations entre une variable quantitative cible et d'autres variables. R a réalisé les calculs statistiques ; interprétez les résultats présentés sans inventer de résultats supplémentaires.

Pour les variables explicatives quantitatives, une corrélation POSITIVE signifie que des valeurs plus élevées de la variable tendent à s'accompagner de valeurs plus élevées de la variable cible ; une corrélation NEGATIVE signifie que des valeurs plus élevées de la variable tendent à s'accompagner de valeurs plus faibles de la cible. La valeur absolue de la corrélation indique la force de l'association linéaire. Interprétez les directions selon la signification et l'orientation des échelles. Des valeurs élevées ne signifient pas nécessairement de meilleurs résultats.

Pour les variables qualitatives, le R² décrit l'association globale entre la variable et la cible. Il n'a pas de direction et ne permet pas d'identifier la contribution d'une modalité particulière.

Un Estimate positif ou négatif indique qu'une modalité est associée respectivement à des valeurs plus élevées ou plus faibles de la cible, relativement à la référence du modèle à un facteur ajusté avec un codage à somme nulle. Estimate est exprimé dans l'unité de la variable cible. Il ne correspond pas nécessairement à une différence avec la moyenne globale de l'échantillon, ni à un effet ajusté sur les autres variables explicatives.

Les états dérivés, tels que Above-average value et Below-average value, proviennent des variables quantitatives originales. Ils ne constituent pas des mesures indépendantes. Utilisez-les pour illustrer ou nuancer les associations continues, et non comme des confirmations indépendantes.

La significativité statistique ne mesure ni la force d'une association ni son importance substantielle. Les résultats présentés peuvent constituer une sélection plutôt qu'un ensemble exhaustif. Ne déduisez pas de résultats concernant des variables ou des modalités non présentées.

Préservez la signification des variables et des modalités, notamment les négations et les formulations inversées. Utilisez le contexte de l'étude pour comprendre les mesures, sans considérer ce contexte comme une preuve statistique supplémentaire. Ne déduisez pas de relations causales de ces associations.

### Decision

- The scientist approved the currently proposed English operational reading, including the precise description of Estimate relative to the sum-to-zero one-factor model reference.
- Preserve distinctions among correlation, global qualitative R², category-level Estimate, and derived quantitative states.
- Keep model/evidence implementation details outside the operational text unless needed for sound interpretation.
- Proceed block by block; do not approve or implement subsequent blocks without explicit user review.

## 2. `interpretation` — PENDING

## 3. Target identity (`standard` / `latent`) — PENDING

## 4. Target task — PENDING

## 5. `output` — PENDING

## Change policy

Save explicitly approved wording only. Keep methodological reference intact. Do not modify R code or the earlier compact draft as a consequence of this documentation approval alone.
