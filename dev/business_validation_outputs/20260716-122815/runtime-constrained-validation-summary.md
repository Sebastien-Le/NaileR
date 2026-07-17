# NaileR — Validation métier avec constrained decoding temporaire

- Script réutilisé : `dev/validate_business_workflow_with_llm_v2.R`
- Modèle : `mistral-small3.2`
- Nombre d'appels contraints : 2
- Nombre d'appels contraints attendu : 2
- Routage des deux appels structurés validé : TRUE
- Tous les appels contraints ont produit du JSON pur : TRUE
- Fonction interne restaurée après l'exécution : TRUE

## Interprétation

Le jeu de données, les fonctions publiques, les contrôles et les rapports sont ceux du script de validation précédent. Seule la stratégie de décodage des sorties structurées a changé.

## Étape humaine

Comparer les rapports aux fichiers `expected-business-reference.csv` et `expected-claims-review.csv`, puis compléter `business-review.csv`.
