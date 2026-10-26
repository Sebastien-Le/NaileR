# C01 — Validation end-to-end Gemini, condition A

## Référence

- branche : `dev-core5-condes-integration-20261015` ;
- commit : `0a47b546e284dd88e3964db64fc3f3b9295c6d95` ;
- objet réutilisé : `profiles_from_dataset.rds` ;
- aucun recalcul de l'ACM, de la HCPC ou de `catdes()`.

## Appel exécuté

```r
res_A <- nail_catdes(
  x = profiles,
  interpretation_mode = "latent",
  isolate.groups = TRUE,
  drop.negative = FALSE,
  provider = "gemini",
  model = "gemini-2.5-flash",
  max_output_tokens = 8192L,
  max_tries = 1L,
  timeout = 90,
  generate = TRUE
)
```

La clé était disponible dans R mais n'a jamais été affichée ni enregistrée. La durée totale des trois appels séquentiels est de `105,091` secondes. Aucun retry n'a été demandé.

## Résultats

| Contrôle | Résultat |
|---|---|
| Interprétations produites | 3 |
| Groupes | `1`, `2`, `3` |
| Prompts réels vs prompts préparés | identiques |
| Evidence canonique vs référence | identique |
| Nombre de marqueurs de référence | 314 |
| `llm_io` | présent, stage `interpretation`, scope `local` |
| `catdes_settings$llm_calls` | 3 |
| Statut des profils sémantiques | `generated` pour les trois groupes |

Les réponses brutes sont conservées dans `gemini_end_to_end_A/response_1.txt`, `response_2.txt` et `response_3.txt`. Leurs longueurs sont respectivement de 4 739, 4 712 et 5 639 caractères.

Le résultat RDS complet est conservé localement dans `gemini_end_to_end_A/result_A.rds`. Il contient les attributs analytiques et les structures de provenance du résultat intégré. Une version partageable excluant ce résultat complet est fournie dans l'archive afin de ne pas diffuser de structures potentiellement individuelles.

## Portée scientifique

Cette passe valide le chemin technique `nail_catdes(generate = TRUE)` pour la condition A et la conservation des prompts, réponses, preuves et métadonnées. Elle ne conclut pas à la qualité scientifique des interprétations : leur fidélité, leur capacité de synthèse, leurs noms et leurs éventuelles extrapolations doivent encore être relus dans ChatGPT.

Les conditions B et C n'ont pas été exécutées.
