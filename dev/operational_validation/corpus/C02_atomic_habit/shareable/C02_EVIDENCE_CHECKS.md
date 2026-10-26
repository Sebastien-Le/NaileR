# C02 — Contrôles des preuves et des accessors

## Assertions exécutées

Le script `C02_ATOMIC_HABIT_VALIDATION.R` vérifie automatiquement :

1. les dimensions 167×50 et 167×51 ;
2. l'identité ligne par ligne et colonne par colonne des 50 variables communes ;
3. les types, plages 0–5, niveaux et valeurs manquantes ;
4. les effectifs des groupes 1/2/3 : 84/13/70 ;
5. la reproduction exacte de la classification par les deux candidates AFM–HCPC ;
6. la construction `FactoMineR::catdes()` puis `nail_catdes_prep(x = ...)` ;
7. l'invariance des profils statistiques et du registre de preuves entre les
   quatre previews local/global × `drop.negative` ;
8. la présence de prompts non vides et de tous les groupes en mode local ;
9. le retour explicite de `nail_response()` indiquant qu'aucune réponse n'est
   disponible avec `generate = FALSE`.

## Résultat

Toutes les assertions ont réussi hors réseau. Aucun appel LLM n'a été effectué.
Les prompts sont conservés intégralement dans `prompts/`, et les preuves
agrégées dans `evidence_registry.csv` et `evidence/*.rds`. Aucun verbatim
individuel n'est exporté dans les rapports ou dans l'archive partageable.

Le warning de démarrage `testthat` lié à la version de R installée est un
warning d'environnement observé pendant `devtools::load_all()` ; il ne provient
pas du workflow CATDES.
