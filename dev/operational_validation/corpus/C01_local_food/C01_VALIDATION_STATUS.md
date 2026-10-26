# C01 — Statut de validation

## Matrice de contrôle

| Domaine | Contrôle | Résultat |
|---|---|---|
| Technique | appels MCA, HCPC et `catdes()` | PASS |
| Technique | `nail_catdes_prep()` depuis dataset et `catdes()` | PASS, avec warning de dépréciation sur le chemin historique |
| Technique | `nail_catdes(generate = FALSE)` local et joint | PASS |
| Technique | `nail_evidence()` et `nail_prompt()` | PASS |
| Technique | `nail_response()` sans génération | PASS : absence signalée explicitement |
| Technique | appels LLM | PASS : 0 appel |
| Statistique | données 573 x 63 et variables supplémentaires 46:63 | PASS |
| Statistique | classification 573 x 64, cible `clust` en colonne 64 | PASS |
| Statistique | trois groupes avec graine 1 : 226 / 188 / 159 | PASS |
| Statistique | deux vecteurs d'affectations individuels avec graine 1 | PASS, identiques ligne par ligne |
| Statistique | 314 marqueurs qualitatifs, 0 quantitatif | PASS |
| Statistique | invariance des preuves canoniques entre variantes | PASS |
| Préparation de campagne | prompts A/B/C et invariance de la classification/evidence | PASS, sans LLM |
| Statistique | invariance des identifiants et tables de groupes entre préparations | PASS |
| Sémantique préparatoire | prompts lisibles et structurés | PASS, revue statique |
| Sémantique préparatoire | fidélité des modalités, directions et pourcentages | PASS, contrôle du contenu affiché |
| Sémantique LLM | qualité des interprétations | PASS exploratoire, revue comparative réalisée |
| Sémantique LLM | comparaison humaine / LLM | PASS exploratoire, sans seconde évaluation indépendante |
| Génération LLM | réponses produites | 9 réponses ; `G3_R01` est incomplète |

## Statut du cas

`local_food` est **validated** pour les contrôles statistiques et techniques end-to-end exécutés dans C01. Neuf interprétations Gemini ont été produites et une évaluation scientifique comparative exploratoire a été réalisée. La réponse `G3_R01` (condition C, groupe 3) est incomplète ; son motif d'arrêt n'est pas disponible dans les artefacts sauvegardés. Les résultats A/B/C restent exploratoires et ne démontrent pas une supériorité systématique d'une configuration. Aucune seconde évaluation indépendante n'est prévue.

## Artefacts

- `C01_local_food_validation.R` : script autonome ;
- `catdes_reference.rds` : résultat FactoMineR de référence ;
- `profiles_from_dataset.rds` et `profiles_from_catdes.rds` : objets de préparation ;
- `preview_*.rds` : previews NaileR ;
- `metadata.rds`, `run_summary.rds`, `group_sizes.csv` ;
- `prompts/` : prompts intégraux UTF-8 des configurations exécutées.
- `prompts_conditions_ABC/` : trois jeux de trois prompts pour A (défaut/défaut), B (introduction contextualisée/défaut) et C (introduction contextualisée/requête historique).
- `C01_TRUNCATION_DIAGNOSTIC.md` : diagnostic de la réponse incomplète `G3_R01` et limites de provenance du motif d'arrêt.

## Statut inchangé

Le cas reste `ready_for_validation`, et non `validated` : les assertions statistiques et les previews sont stabilisées, mais aucune réponse LLM n'a été générée ni évaluée scientifiquement.
