# DESCFREQ modular prompt — bilingual scientific review

**Status:** Terminology decision APPROVED (2026-10-14); complete `reading` below is the consolidated candidate pending final verbatim approval. Other blocks pending.
**Branch:** `dev-statistical-prompt-framework`.
**Methodological source:** [DESCFREQ_REFERENCE_PROMPT.md](DESCFREQ_REFERENCE_PROMPT.md) (approved).
**Previous compact:** [DESCFREQ_COMPACT_PROMPT.md](DESCFREQ_COMPACT_PROMPT.md) (draft, not approved).

## Approved terminology decision (2026-10-14)

Use the statistical language of contingency tables: **row, column, cell count, row profile, global profile**, rather than the more interpretive `attribute`. A column's substantive meaning depends on the study; it is not necessarily an intrinsic attribute of an individual. This decision applies consistently to the operational DESCFREQ `reading` text. Do not change the approved long scientific reference or code in this documentation pass.

## 1. `reading` — CONSOLIDATED CANDIDATE (terminology approved)

### English — proposed operational text

The results come from `FactoMineR::descfreq()` and describe rows of a contingency table through their frequency profiles across columns. Each row is compared with the overall table profile, not with another row.

For each column, the row profile percentage is its count within a row divided by the total count of that row. The global profile percentage is its total count across all rows divided by the total count of the table.

The cell count gives the observed frequency for a particular row and column. The column total gives its frequency across all rows. These counts do not necessarily represent distinct individuals.

OVERREPRESENTED means that a column's row profile percentage is statistically higher than its global profile percentage; UNDERREPRESENTED means statistically lower. Overrepresentation does not imply that a column accounts for the majority of a row or is its most frequent column. Interpret each direction together with both percentages and the available counts.

Statistical distinctiveness does not necessarily imply substantive importance. A column with a low overall frequency can be distinctive without defining the entire row. The displayed evidence may be a selection rather than the complete profile; do not draw conclusions about unreported columns.

Interpret column labels according to their actual meaning, including negations and distinctions between perceptions, intentions, and observed behaviors. Do not infer associations between columns, individual-level relationships, or causal mechanisms from these frequency profiles. Use the study context to understand what the counts represent, without treating it as additional statistical evidence.

### Français — traduction de contrôle proposée

Les résultats proviennent de `FactoMineR::descfreq()` et décrivent les lignes d'un tableau de contingence à partir de leurs profils de fréquences sur les différentes colonnes. Chaque ligne est comparée au profil global du tableau, et non à une autre ligne.

Pour chaque colonne, le pourcentage dans le profil d'une ligne correspond à son effectif dans cette ligne rapporté à l'effectif total de la ligne. Le pourcentage dans le profil global correspond à l'effectif total de cette colonne rapporté à l'effectif total du tableau.

L'effectif d'une cellule correspond à la fréquence observée pour une ligne et une colonne particulières. Le total d'une colonne correspond à sa fréquence dans l'ensemble des lignes. Ces effectifs ne représentent pas nécessairement des individus distincts.

OVERREPRESENTED signifie que le pourcentage d'une colonne dans le profil de la ligne est statistiquement supérieur à son pourcentage dans le profil global ; UNDERREPRESENTED signifie qu'il est statistiquement inférieur. Une surreprésentation n'implique pas qu'une colonne représente la majorité des effectifs d'une ligne ou qu'elle soit la plus fréquente. Interprétez chaque direction en tenant compte des deux pourcentages et des effectifs disponibles.

Une singularité statistique n'implique pas nécessairement une importance substantielle. Une colonne de faible fréquence globale peut être distinctive sans définir l'ensemble du profil d'une ligne. Les résultats présentés peuvent constituer une sélection plutôt que le profil complet ; ne tirez pas de conclusions sur les colonnes non présentées.

Interprétez les intitulés des colonnes selon leur signification réelle, notamment les négations et les distinctions entre perceptions, intentions et comportements observés. Ne déduisez pas de relations entre colonnes, de relations au niveau individuel ou de mécanismes causaux à partir de ces profils de fréquences. Utilisez le contexte de l'étude pour comprendre ce que représentent les effectifs, sans le considérer comme une preuve statistique supplémentaire.

## 2. `interpretation` — APPROVED (bilingual wording, 2026-10-14)

### English — approved operational text

Interpret each row by considering its displayed statistical characteristics jointly, rather than describing columns one by one. Identify meaningful patterns in its frequency profile, taking into account both what distinguishes the row from the global profile and the relative importance of each column within the row.

Use the study context to develop a substantive synthesis grounded in the displayed evidence. Do not present conceptual connections between columns as statistically demonstrated relationships or causal mechanisms. When the evidence is sparse or points to several distinct themes, describe what it supports without forcing a single global interpretation.

### Français — traduction de contrôle validée

Interprétez chaque ligne en considérant conjointement ses caractéristiques statistiques, plutôt qu'en décrivant les colonnes une à une. Identifiez les configurations significatives de son profil de fréquences, en tenant compte à la fois de ce qui distingue la ligne du profil global et de l'importance relative de chaque colonne au sein de la ligne.

Utilisez le contexte de l'étude pour construire une synthèse substantielle fondée sur les résultats présentés. Ne présentez pas les rapprochements conceptuels entre colonnes comme des relations statistiquement démontrées ou des mécanismes causaux. Lorsque les résultats sont peu nombreux ou renvoient à plusieurs thèmes distincts, décrivez ce qu'ils permettent d'interpréter sans imposer une interprétation générale unique.

### Decision

- Validated the bilingual `interpretation` block with the analyst's requested wording `single global interpretation` instead of `single overarching interpretation`.
- Here `global interpretation` refers to a unifying substantive interpretation of a row; it does not designate the statistical `global profile` used as reference in `reading`.
- Maintain a distinction between the statistical distinctiveness of a column and its share of the row's counts.
- No R code changes or evidence-presentation changes authorized.



## 3. Row identity — APPROVED (2026-10-14)

### `standard` — APPROVED

**English — approved operational text**

Each row represents an observed entity or category whose identity is already defined. Preserve its original name and any label provided by the analyst.

Interpret its frequency profile to characterize what distinguishes this entity or category, without replacing its known identity with an invented one.

**Français — traduction de contrôle validée**

Chaque ligne représente une entité ou une catégorie observée dont l'identité est déjà définie. Conservez son nom d'origine ainsi que tout intitulé fourni par l'analyste.

Interprétez son profil de fréquences pour caractériser ce qui distingue cette entité ou cette catégorie, sans remplacer son identité connue par une identité inventée.

### `latent` — APPROVED

**English — approved operational text**

Each row represents a constructed group whose identifier does not define its substantive meaning.

Interpret its frequency profile to identify what makes the group distinctive. When supported by the evidence, propose a concise, meaningful name. Keep the original identifier alongside the proposed name.

Do not force a name when the profile is too heterogeneous or insufficiently informative.

**Français — traduction de contrôle validée**

Chaque ligne représente un groupe construit dont l'identifiant ne définit pas la signification substantielle.

Interprétez son profil de fréquences pour identifier ce qui distingue le groupe. Lorsque les résultats le permettent, proposez un nom court et significatif. Conservez l'identifiant d'origine à côté du nom proposé.

Ne cherchez pas à attribuer artificiellement un nom lorsque le profil est trop hétérogène ou insuffisamment informatif.

### Architectural decision

- Use explicit `standard` and `latent` identity-specific prompt blocks, not LLM inference from row labels.
- `standard` applies to observed row entities or categories, such as sensory products described by words; `latent` applies to constructed groups, such as clusters.
- These identity modes are conceptually independent of `isolate.groups` (local vs joint scope) and the existing `interpretation_mode = "description" / "comparison"` (joint task).
- `row_identity_mode` is only a **possible future API name**, not a currently implemented function argument. Assess interaction with existing `explicit_row_labels` at implementation design.
- This is a prompt-documentation approval; do not modify package code.



## 4. Task scope (local / joint description / joint comparison)

### Local task — APPROVED (2026-10-14)

**English — approved operational text**

Interpret only the row "[row_identifier]" using its displayed statistical evidence and the user's analytical request.

Characterize what distinguishes this row from the overall table profile. Do not describe or compare rows whose evidence is not displayed.

**Français — traduction de contrôle validée**

Interprétez uniquement la ligne « [row_identifier] » à partir de ses résultats statistiques et de la question analytique de l'utilisateur.

Caractérisez ce qui distingue cette ligne du profil global du tableau. Ne décrivez pas et ne comparez pas les lignes dont les résultats ne sont pas présentés.

**Decision**

- Include this task only for the local route `isolate.groups = TRUE`.
- Keep the task independent of `standard` or `latent` row identity; only evidence for the named row is in scope.
- `[row_identifier]` is a runtime placeholder for the actual identifier, not literal text in the evidence.

### Joint description task — APPROVED (2026-10-14)

**English — approved operational text**

Interpret each displayed row using its own statistical evidence and the user's analytical request.

Characterize what distinguishes each row from the overall table profile. Develop a substantive interpretation of each frequency profile, considering the displayed columns jointly.

Preserve each row's identity. Do not force comparisons between rows when the analytical task is to describe them.

**Français — traduction de contrôle validée**

Interprétez chaque ligne présentée à partir de ses propres résultats statistiques et de la question analytique de l'utilisateur.

Caractérisez ce qui distingue chaque ligne du profil global du tableau. Construisez une interprétation substantielle de chaque profil de fréquences, en considérant conjointement les colonnes présentées.

Préservez l'identité de chaque ligne. Ne cherchez pas à imposer des comparaisons entre les lignes lorsque l'objectif analytique est de les décrire.

**Routing:** `isolate.groups = FALSE`; `interpretation_mode = "description"`. Identity mode remains independent.


### Joint comparison task — APPROVED (bilingual wording, 2026-10-14)

**English — approved operational text**

Compare the displayed rows using their statistical evidence and the user's analytical request.

Identify meaningful similarities and differences between their frequency profiles, considering how each row differs from the overall table profile.

Develop a substantive interpretation of the main contrasts while preserving each row's identity. Do not claim statistically significant differences between rows unless direct comparisons have been provided.

Do not infer a progression or hierarchy from the order of the rows alone.

**Français — traduction de contrôle validée**

Comparez les lignes présentées à partir de leurs résultats statistiques et de la question analytique de l'utilisateur.

Identifiez les ressemblances et différences significatives sur le plan substantiel entre leurs profils de fréquences, en considérant la manière dont chaque ligne se distingue du profil global du tableau.

Construisez une interprétation substantielle des principaux contrastes tout en préservant l'identité de chaque ligne. N'affirmez pas l'existence de différences statistiquement significatives entre les lignes si des comparaisons directes n'ont pas été fournies.

Ne déduisez pas une progression ou une hiérarchie du seul ordre des lignes.

**Routing:** `isolate.groups = FALSE`; `interpretation_mode = "comparison"`. Original row order alone does not establish a statistically tested gradient; the separate contextual flag `rows_are_ordered` may justify discussing ordered patterns when also supported by evidence.


## 5. `output` — PENDING

## Change policy

Only change the approval status for exact bilingual wording after user validation. Keep the approved scientific reference intact; do not modify R code or the earlier compact draft as a consequence of this scientific documentation alone.
