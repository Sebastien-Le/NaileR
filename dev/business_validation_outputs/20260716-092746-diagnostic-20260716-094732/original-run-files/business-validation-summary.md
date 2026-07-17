# NaileR — Validation opérationnelle métier avec LLM réel

- Date : 2026-07-16 09:41:05.207106
- Backend : `ollama`
- Modèle : `mistral-small3.2`
- Individus : 45
- Groupes : 3
- Preuves statistiques : 25
- Preuves textuelles : 45
- Preuves combinées : 70

## Contrôles automatiques

- Contrôles mécaniques réussis : 8/8
- Contrôles de compatibilité LLM réussis : 0/7

## Statut des étapes LLM

- Préparation textuelle valide : FALSE
- Analyse contextualisée valide : FALSE

## Temps des appels LLM

- `nail_catdes()` : 129.7 secondes
- `nail_textual_prep()` : 666.8 secondes
- `nail_textual_contextualized()` : non exécuté

## Évaluation métier

- Grille non complétée ou non applicable.
- Verdict : **WORKFLOW MÉCANIQUE OPÉRATIONNEL, MAIS MODÈLE LLM NON COMPATIBLE AVEC LE CONTRAT STRUCTURÉ**

## Diagnostics à examiner en priorité

- `textual-preparation-statuses.csv`
- `textual-preparation-llm-diagnostics.csv`
- les fichiers `textual-preparation-*-parse_error.txt`
- les fichiers `textual-preparation-*-response.txt`
- `integrated-analysis-statuses.csv`
- `automatic-checks.csv`

## Interprétation

Le code mécanique fonctionne, mais le modèle choisi n'a pas fourni une réponse conforme au parsing ou à la validation. Ce résultat constitue une incompatibilité opérationnelle du modèle ou du prompt, et non une preuve d'échec des calculs R.
