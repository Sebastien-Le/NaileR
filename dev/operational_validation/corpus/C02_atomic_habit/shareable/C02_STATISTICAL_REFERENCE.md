# C02 — Référence statistique

## Table analytique

La table de référence est construite sans modifier les données originales :

```r
analysis_data <- atomic_habit_clust[, c(1:20, 51), drop = FALSE]
raw_catdes <- FactoMineR::catdes(
  analysis_data,
  num.var = 21L,
  proba = 0.05
)
profiles <- nail_catdes_prep(x = raw_catdes, proba = 0.05)
```

Le passage `x = raw_catdes` utilise l'interface actuelle de préparation et
évite l'ancienne interface `dataset`/`num.var` dépréciée. Le résultat préparé
contient trois groupes et 63 lignes de registre de preuves.

## Reproduction AFM–HCPC

| Construction candidate | Variables | Groupes AFM | Groupe supplémentaire | Tailles HCPC | Accord exact avec `clust` |
|---|---:|---|---|---|---:|
| Documentation `atomic_habit.Rd` | 30 | 10 + 10 + 10 | 3 | 84/13/70 | 1.00 |
| Description « 20 first variables » | 20 | 10 + 10 | aucun | 84/13/70 | 1.00 |

Les deux accords sont également de 1.00 après permutation éventuelle des
étiquettes. La classification distribuée est donc techniquement
reproductible par les deux spécifications documentées, mais la provenance
historique exacte reste indéterminée.

## Preuves CATDES

Le registre canonique comporte :

- groupe 1 : 18 marqueurs qualitatifs et 9 quantitatifs ;
- groupe 2 : 10 marqueurs qualitatifs et 4 quantitatifs ;
- groupe 3 : 14 marqueurs qualitatifs et 8 quantitatifs ;
- total : 42 qualitatifs et 21 quantitatifs.

Les previews local/global ont été exécutées sans LLM, avec la même introduction
et la même requête scientifique. Les quatre configurations sont :

```text
local_full             isolate.groups = TRUE,  drop.negative = FALSE
local_drop_negative    isolate.groups = TRUE,  drop.negative = TRUE
joint_full             isolate.groups = FALSE, drop.negative = FALSE
joint_drop_negative    isolate.groups = FALSE, drop.negative = TRUE
```

Les profils statistiques canoniques et le registre de preuves sont invariants
entre ces configurations. `drop.negative` modifie la présentation du prompt,
pas le calcul CATDES ni la preuve canonique.
