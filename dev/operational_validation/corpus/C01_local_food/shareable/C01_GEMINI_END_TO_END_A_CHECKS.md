# C01 — Contrôles techniques end-to-end, condition A

## Accessors et invariances

- `nail_prompt(res_A, print = FALSE)` : trois prompts nommés, identiques aux prompts A préparés ;
- `nail_response(res_A, print = FALSE)` : trois réponses non vides, conservées intégralement ;
- `nail_evidence(res_A)` : identique à l'evidence de référence du preview ;
- `statistical_profiles$evidence_registry` : 314 lignes, inchangé ;
- groupes : `1`, `2`, `3`, inchangés ;
- `llm_io` : trois prompts et trois réponses, provider `gemini`, modèle `gemini-2.5-flash` ;
- `catdes_settings$llm_calls` : 3 ;
- profils sémantiques : statut `generated` pour chaque groupe.

## Identité des prompts

La comparaison porte sur les listes complètes de prompts, pas seulement sur leur taille. Les prompts actualisés sont sauvegardés dans `gemini_end_to_end_A/prompt_actual_*.txt` et les prompts attendus dans `prompt_expected_*.txt`.

Longueurs des prompts actualisés : 24 204, 22 348 et 21 607 caractères R. Les différences entre octets et caractères résultent de l'encodage UTF-8 ; l'identité est vérifiée par comparaison des chaînes R.

## Réponses

| Groupe | Caractères | SHA-256 du fichier brut |
|---|---:|---|
| 1 | 4 739 | `db464854e03815d5f94996358a39d0d96d0ae3c47a712ac3c87c6e044be23328` |
| 2 | 4 712 | `62f111adb862ab573e56b117b2bf870e00b92c8ed2da4f6ae5851bf5a370ebea` |
| 3 | 5 639 | `60cc7eb39ed4e0db0392d4f624e84437d6b1365a1fe4874c919671a9ca36ed63` |

Les textes n'ont pas été comparés à la réponse directe indépendante du groupe 1 : cette comparaison n'est pas attendue, car les générations sont indépendantes.

## Avertissements

Le seul avertissement observé pendant le chargement local concernait `testthat` compilé sous R 4.4.3 alors que le processus utilise R 4.4.2. Aucun avertissement propre à `nail_catdes()` ou au backend Gemini n'a été produit pendant la génération end-to-end.

## Conclusion technique

La condition A est techniquement opérationnelle end-to-end. Cette conclusion ne vaut pas validation sémantique des textes générés et ne s'étend pas aux conditions B ou C.
