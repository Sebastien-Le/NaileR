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

## 2. `interpretation` — PENDING

## 3. Row identity — PENDING

## 4. Task scope (local / joint description / joint comparison) — PENDING

## 5. `output` — PENDING

## Change policy

Only change the approval status for exact bilingual wording after user validation. Keep the approved scientific reference intact; do not modify R code or the earlier compact draft as a consequence of this scientific documentation alone.
