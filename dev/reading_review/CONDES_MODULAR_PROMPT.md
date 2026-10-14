# CONDES modular prompt — bilingual scientific review

**Status:** BILINGUAL OPERATIONAL BLOCKS AND ASSEMBLY SIMPLIFICATIONS APPROVED (2026-10-14) — not yet implemented or evaluated with LLMs.
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

Statistical significance does not measure association strength or substantive importance.

Preserve the meaning of variables and categories, including negations and reverse-worded labels. Use the study context to understand the measurements, without treating that context as additional statistical evidence. Do not infer causality from these associations.

### Français — traduction de contrôle soumise avec le bloc approuvé

Les résultats proviennent de `FactoMineR::condes()` et décrivent les associations entre une variable quantitative cible et d'autres variables. R a réalisé les calculs statistiques ; interprétez les résultats présentés sans inventer de résultats supplémentaires.

Pour les variables explicatives quantitatives, une corrélation POSITIVE signifie que des valeurs plus élevées de la variable tendent à s'accompagner de valeurs plus élevées de la variable cible ; une corrélation NEGATIVE signifie que des valeurs plus élevées de la variable tendent à s'accompagner de valeurs plus faibles de la cible. La valeur absolue de la corrélation indique la force de l'association linéaire. Interprétez les directions selon la signification et l'orientation des échelles. Des valeurs élevées ne signifient pas nécessairement de meilleurs résultats.

Pour les variables qualitatives, le R² décrit l'association globale entre la variable et la cible. Il n'a pas de direction et ne permet pas d'identifier la contribution d'une modalité particulière.

Un Estimate positif ou négatif indique qu'une modalité est associée respectivement à des valeurs plus élevées ou plus faibles de la cible, relativement à la référence du modèle à un facteur ajusté avec un codage à somme nulle. Estimate est exprimé dans l'unité de la variable cible. Il ne correspond pas nécessairement à une différence avec la moyenne globale de l'échantillon, ni à un effet ajusté sur les autres variables explicatives.

Les états dérivés, tels que Above-average value et Below-average value, proviennent des variables quantitatives originales. Ils ne constituent pas des mesures indépendantes. Utilisez-les pour illustrer ou nuancer les associations continues, et non comme des confirmations indépendantes.

La significativité statistique ne mesure ni la force d'une association ni son importance substantielle.

Préservez la signification des variables et des modalités, notamment les négations et les formulations inversées. Utilisez le contexte de l'étude pour comprendre les mesures, sans considérer ce contexte comme une preuve statistique supplémentaire. Ne déduisez pas de relations causales de ces associations.

### Decision

- The scientist approved the currently proposed English operational reading, including the precise description of Estimate relative to the sum-to-zero one-factor model reference.
- Preserve distinctions among correlation, global qualitative R², category-level Estimate, and derived quantitative states.
- Keep model/evidence implementation details outside the operational text unless needed for sound interpretation.
- Proceed block by block; do not approve or implement subsequent blocks without explicit user review.

## 2. `interpretation` — APPROVED (V2 bilingual wording, 2026-10-14)

### English — approved operational text

Interpret the quantitative target by considering its statistical associations jointly, rather than describing variables one by one. Identify meaningful patterns associated with lower and higher target values, and develop a substantive synthesis of what emerges from their combination.

Use the study context to connect findings conceptually, while grounding your interpretation in the provided evidence. Do not present these connections as statistically demonstrated relationships between predictors or causal mechanisms. When the results reveal several distinct aspects of the target, describe them without forcing a single overarching interpretation.

### Français — traduction de contrôle validée

Interprétez la variable quantitative cible en considérant conjointement ses associations statistiques, plutôt qu'en décrivant les variables une à une. Identifiez les configurations significatives associées aux valeurs faibles et élevées de la cible, et construisez une synthèse substantielle faisant émerger ce que révèle leur combinaison.

Utilisez le contexte de l'étude pour rapprocher conceptuellement les résultats, en fondant votre interprétation sur les preuves statistiques présentées. Ne présentez pas ces rapprochements comme des relations statistiquement démontrées entre les variables explicatives ou comme des mécanismes causaux. Lorsque les résultats révèlent plusieurs aspects distincts de la variable cible, décrivez-les sans chercher à imposer une interprétation générale unique.

### Decisions

- Approved the streamlined V2 wording in English and French.
- Avoid the implementation-specific phrase `end-profile evidence` in operational interpretation instructions; use the concept of patterns associated with lower and higher target values instead.
- Replace the abstract instruction to preserve `exceptions, asymmetries, and ambiguities` with a clearer safeguard against forcing one overarching interpretation when several distinct aspects emerge.
- Multidimensional synthesis belongs here; statistical semantics belong in `reading`.

## 3. Target identity — `standard` / `latent`

### `standard` — APPROVED (bilingual wording, 2026-10-14)

**English — approved operational text**

The target is an observed quantitative variable. Preserve its original name and measured meaning.

Interpret how the displayed associations characterize its lower and higher values. A broader substantive interpretation may emerge from these associations, but do not replace the observed variable with an inferred latent construct.

**Français — traduction de contrôle validée**

La cible est une variable quantitative observée. Conservez son nom d'origine et sa signification en tant que mesure.

Interprétez comment les associations présentées caractérisent ses valeurs faibles et élevées. Une interprétation substantielle plus générale peut émerger de ces associations, mais ne remplacez pas la variable observée par un construit latent inféré.

### `latent` — APPROVED (bilingual wording, 2026-10-14)

**English — approved operational text**

The target is a constructed quantitative dimension whose substantive meaning must be inferred from its statistical associations. Its original identifier must be preserved.

Interpret the contrast between lower and higher values to identify what the dimension represents. When the numerical orientation is arbitrary, as with a principal component, do not assume that higher values are inherently better or more desirable.

When supported by the evidence, propose a concise, meaningful name that captures the dimension's main interpretation. Keep the original identifier alongside the proposed name.

Do not force a single name or interpretation when the associations are too heterogeneous or insufficiently informative.

**Français — traduction de contrôle validée**

La cible est une dimension quantitative construite dont la signification substantielle doit être déduite de ses associations statistiques. Son identifiant d'origine doit être conservé.

Interprétez l'opposition entre ses valeurs faibles et élevées pour identifier ce que représente la dimension. Lorsque l'orientation numérique est arbitraire, comme pour une composante principale, ne supposez pas que les valeurs élevées sont intrinsèquement meilleures ou plus souhaitables.

Lorsque les résultats le permettent, proposez un nom court et significatif qui rende compte de l'interprétation principale de la dimension. Conservez l'identifiant d'origine à côté du nom proposé.

Ne cherchez pas à imposer un nom ou une interprétation unique lorsque les associations sont trop hétérogènes ou insuffisamment informatives.

## 4. `task` — APPROVED, streamlined after assembly review (2026-10-14)

### English — approved operational text

Interpret the quantitative target "[target_identifier]" using the displayed statistical evidence and the user's analytical request.

### Français — traduction de contrôle validée

Interprétez la variable quantitative cible « [target_identifier] » à partir des résultats statistiques présentés et de la question analytique de l'utilisateur.

### Decision

- CONDES has a single quantitative target, so no CATDES-style local/global task distinction is needed.
- Keep the task short: target identifier, analyst request, and evidence scope. Multidimensional synthesis instructions belong to `interpretation`.
- `[target_identifier]` is a runtime placeholder for the actual variable identifier, not literal evidence.


## 5. `output` — APPROVED (bilingual wording, 2026-10-14)

### English — approved operational text

Write a clear, substantive interpretation of the quantitative target. Present the main characteristics associated with its lower and higher values, and explain the overall contrast they suggest.

Support your interpretation with the most relevant statistical findings, while acknowledging important limitations. Favor a meaningful synthesis over repetitive numerical reporting.

### Français — traduction de contrôle validée

Rédigez une interprétation claire et substantielle de la variable quantitative cible. Présentez les principales caractéristiques associées à ses valeurs faibles et élevées, et expliquez le contraste général qu'elles suggèrent.

Appuyez votre interprétation sur les résultats statistiques les plus pertinents, tout en reconnaissant les limites importantes. Privilégiez une synthèse porteuse de sens plutôt qu'une répétition systématique des résultats numériques.

### Decision

- `output` sets editorial expectations, without repeating the full scientific doctrine in `interpretation`.
- The analyst may customize this block; do not impose mandatory Quarto Markdown or JSON formatting in the editable operational default.
- Any indispensable output/parser requirements belong in a separate technical contract, to be examined before implementation.



## Assembly review — APPROVED (2026-10-14)

After reviewing the complete standard-mode assembly and the latent-mode alternative, the analyst approved two concise changes:

- `task` now consists only of the target identifier, the displayed evidence and the user's analytical request. Statements on target poles and unshown evidence remain covered by `reading`, `interpretation` and identity-specific blocks.
- `output` retains the substantive summary and numerical-repetition safeguard, without repeating the ban on variable-by-variable description already covered by `interpretation`.

Keep `reading`, `interpretation`, `standard` and `latent` unchanged. No package-code modifications are authorized by this documentary approval. The eventual runtime assemblage and the evidence representation require separate verification.

## Cross-functional evidence-selection wording decision — APPROVED (2026-10-14)

The analyst explicitly approved removing operational instructions that tell the LLM the transmitted evidence may be only a selection, or ask it to speculate about variables, modalities, or attributes not supplied. The model should produce the most meaningful **evidence-grounded synthesis of the information actually supplied**. This decision does **not** permit fabricating unsupported measurements, implying statistical relationships that were not tested, or changing the statistical significance/relative-reference semantics.

Selection parameters and missing-marker diagnostics remain documented and auditable **in R and canonical evidence**, not described as a generic caveat in the LLM's editable `reading`. Local-scope limitations (do not describe unprovided groups) remain relevant because they identify the task target. Historical long methodological references and decision logs are retained as archival sources. The existing R runtime has not been modified in this pass.

## Change policy

Save explicitly approved wording only. Keep methodological reference intact. Do not modify R code or the earlier compact draft as a consequence of this documentation approval alone.
