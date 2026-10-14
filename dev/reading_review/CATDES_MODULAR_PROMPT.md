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

## 2. `interpretation` — APPROVED (consolidated bilingual block, 2026-10-14)

### English — approved operational text

Interpret each group by considering its statistical characteristics jointly, rather than describing variables one by one. Identify meaningful patterns and distinctive configurations, and develop a substantive synthesis that reveals what emerges from their combination.

Use the study context to connect characteristics conceptually, while grounding your interpretation in the provided evidence. Do not present these connections as statistically demonstrated relationships or causal mechanisms. Preserve important nuances and ambiguities, without forcing an artificial coherence.

### Français — traduction de contrôle validée

Interprétez chaque groupe en considérant conjointement ses caractéristiques statistiques, plutôt qu'en décrivant les variables une à une. Identifiez les régularités et les configurations qui distinguent le groupe, et construisez une synthèse substantielle faisant émerger ce que révèle leur combinaison.

Utilisez le contexte de l'étude pour rapprocher conceptuellement les caractéristiques, en fondant votre interprétation sur les résultats présentés. Ne présentez pas ces rapprochements comme des relations statistiquement démontrées ou des mécanismes causaux. Préservez les nuances et les ambiguïtés importantes, sans chercher à imposer une cohérence artificielle.

**Scope:** shared by `standard` and `latent`; group-identity rules remain separate. This consolidated wording supersedes the earlier partial drafts. Analyst customization and the need for multidimensional synthesis remain part of the design objectives; actual customization support must be verified in the R API.

## 3. Group identity — standard / latent

### `standard` — APPROVED (2026-10-14)

**English — approved operational text**

Each group corresponds to an observed category defined by a specific variable and one of its response modalities. All group members share this modality.

Use the meaning of both the defining variable and its modality to guide the interpretation of the group's statistical characteristics. Explain how the displayed findings characterize this category, combining its known identity with the multidimensional profile emerging from the evidence.

Preserve the original category name. You may develop a higher-level interpretation, but do not replace the observed category with an invented identity.

**Français — traduction de contrôle validée**

Chaque groupe correspond à une catégorie observée définie par une variable particulière et l'une de ses modalités de réponse. Tous les individus du groupe partagent cette modalité.

Utilisez la signification de la variable définissant le groupe et celle de sa modalité pour orienter l'interprétation de ses caractéristiques statistiques. Expliquez comment les résultats présentés caractérisent cette catégorie, en articulant son identité connue avec le profil multidimensionnel qui émerge des résultats.

Conservez le nom d'origine de la catégorie. Vous pouvez développer une interprétation de niveau supérieur, mais ne remplacez pas la catégorie observée par une identité inventée.

**Implementation check pending:** verify that the prompt actually provides the grouping-variable name as well as the category modality. This is a technical verification, not a prerequisite to approving the scientific wording.

### `latent` — APPROVED (2026-10-14)

**English — approved operational text**

Each group is a constructed group whose identifier does not define its substantive meaning. Interpret its combined statistical characteristics to identify what makes it distinctive.

When supported by the evidence, propose a concise, meaningful name that captures the group's overall profile. Keep the original identifier alongside the proposed name.

Do not force a label when the profile is too heterogeneous or insufficiently informative.

**Français — traduction de contrôle validée**

Chaque groupe est un groupe construit dont l'identifiant ne définit pas la signification substantielle. Interprétez conjointement ses caractéristiques statistiques pour identifier ce qui fait sa singularité.

Lorsque les résultats le permettent, proposez un nom court et significatif qui rende compte du profil global du groupe. Conservez l'identifiant d'origine à côté du nom proposé.

Ne cherchez pas à attribuer artificiellement un nom lorsque le profil est trop hétérogène ou insuffisamment informatif.



## 4. Task scope — local / global

### `local_task` — APPROVED (2026-10-14)

**English — approved operational text**

Interpret only the selected group using its displayed statistical evidence. Do not describe groups whose profiles have not been provided.

**Français — traduction de contrôle validée**

Interprétez uniquement le groupe sélectionné à partir des résultats statistiques présentés. Ne décrivez pas les groupes dont les profils ne sont pas fournis.

### `global_task` — APPROVED (2026-10-14)

**English — approved operational text**

Interpret each displayed group, then provide an overall synthesis of meaningful similarities, contrasts, and configurations across groups. Do not present descriptive contrasts as statistically demonstrated pairwise differences.

**Français — traduction de contrôle validée**

Interprétez chaque groupe présenté, puis proposez une synthèse d'ensemble des principales ressemblances, différences et configurations entre les groupes. Ne présentez pas les contrastes descriptifs comme des différences statistiquement démontrées entre groupes pris deux à deux.


## 5. `output` — APPROVED (2026-10-14)

**English — approved operational text**

Write a clear, substantive interpretation highlighting the central profile, its main supporting statistical characteristics, and important nuances or exceptions. Favor meaningful synthesis over repetitive numerical reporting.

**Français — traduction de contrôle validée**

Rédigez une interprétation claire et substantielle mettant en évidence le profil général, les principales caractéristiques statistiques qui le soutiennent, ainsi que les nuances ou exceptions importantes. Privilégiez une synthèse porteuse de sens plutôt qu'une répétition des résultats numériques.

**Approved design choice:** the analyst may customize this instruction block, just like `reading` and `interpretation`. No mandatory Quarto Markdown instruction is included in the editable default. Any non-negotiable machine-readable output requirement must be enforced by a separate technical contract, subject to later code verification.


## Assembly review — concise wording approved (2026-10-14)

The analyst agreed with the critical review of the illustrative assembled CATDES prompt. These architectural editing decisions and the revised bilingual `local_task`, `global_task` and `output` formulations were explicitly approved. The blocks above contain the current approved wording.

- Keep `reading`, `interpretation`, and `standard`/`latent` scientific substance unchanged.
- Reduce repetitive requests for multidimensional synthesis across `interpretation`, `local_task`, `global_task`, and `output`; leave the main substantive synthesis mandate in `interpretation`.
- Restrict local/global scope wording to scope-related needs; keep global-only instructions in `global_task` rather than conditionally repeating them in `output`.
- Verify in actual R prompt assembly that the grouping variable name AND its category modality are transmitted, especially for `standard` mode. This technical check has not been performed.
- Let the analyst choose response language through their request/context, rather than impose a language in mandatory scientific blocks.
- No change to R code, evidence selection, parser, or existing approved reference is authorized by this agreement.
- Next: verify actual prompt assembly, user-editable blocks, and transmitted grouping variable/modality in R before operational testing.

## Change policy

Append or modify only an explicitly user-approved bilingual block and record its status. Preserve the approved scientific reference unchanged; do not change NaileR R code or the pending compact draft as a consequence of this document alone.
