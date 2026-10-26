# C02 — Audit des données et de la classification

## Données disponibles

| Objet | Dimensions | Rôle |
|---|---:|---|
| `atomic_habit` | 167 × 50 | réponses du questionnaire sans classification |
| `atomic_habit_clust` | 167 × 51 | mêmes 50 colonnes, plus `clust` |

Les 50 noms de colonnes et les 8 350 cellules communes sont identiques entre
les deux objets, dans le même ordre. La colonne supplémentaire `clust` est un
facteur à trois niveaux : `1` (84), `2` (13) et `3` (70). Aucun NA n'est
présent dans les 51 colonnes.

## Familles de variables

| Colonnes | Contenu observé | Type vérifié | Décision pour la référence CATDES |
|---:|---|---|---|
| 1–10 | capacité déclarée | facteurs | incluses |
| 11–20 | restrictivité perçue, échelle 0–5 | numériques, toutes dans [0, 5] | incluses |
| 21–30 | restrictivité oui/non | facteurs | conservées dans la source, non incluses |
| 31–40 | justifications ouvertes | caractères, 167 non vides par colonne | non incluses |
| 41–50 | combinaisons capacité × restrictivité | facteurs dérivés | non incluses |
| 51 | classification `clust` | facteur | cible CATDES |

La référence statistique C02 utilise donc les colonnes 1–20 et 51. Les textes,
les copies binaires et les composites ne sont pas traités comme des preuves
indépendantes de leurs variables sources.

## Provenance de la classification

La documentation de `atomic_habit.Rd` présente une construction `MFA()` sur
les colonnes 1–30, avec `group = c(10, 10, 10)`, `type = c("n", "s", "n")`,
le troisième groupe supplémentaire (`num.group.sup = 3`), puis `HCPC(...,
nb.clust = 3)`. La documentation de `atomic_habit_clust.Rd` décrit toutefois
la classification comme fondée sur les « 20 first variables ».

Les deux routes ont été reproduites hors ligne avec FactoMineR et produisent
exactement les affectations publiées, y compris les effectifs 84/13/70 et les
étiquettes ligne par ligne. Cette équivalence ne permet pas d'identifier la
route historique réellement utilisée. Le facteur publié `clust` reste donc
la référence ; aucune reconstruction concurrente ne le remplace.

## Limites sémantiques

- Les facteurs de capacité décrivent une capacité déclarée, pas un comportement
  effectivement adopté.
- Les scores 0–5 décrivent une restrictivité perçue ; ils ne constituent pas
  une cause démontrée de la capacité déclarée.
- Le groupe 2 est de petite taille (`n = 13`) et doit être interprété avec
  prudence.
- Les dix colonnes textuelles sont renseignées, mais leurs verbatims restent
  des données individuelles et ne sont pas inclus dans les livrables
  partageables.
- La colonne `turn off_text` comporte un espace dans son nom historique ; elle
  est conservée telle quelle et devra être référencée par `[[...]]` ou par son
  nom exact.
