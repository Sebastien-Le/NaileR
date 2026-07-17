# NaileR: mécanique versus LLM + parsing

- Fournisseur : `ollama`
- Modèle : `mistral-small3.2`
- Jeu simulé : 45 observations, 3 groupes
- Preuves statistiques : 25 evidence IDs
- Preuves textuelles : 45 evidence IDs

## Question évaluée

La comparaison ne cherche pas à déterminer si l'interprétation du LLM est identique à celle d'un humain ou d'un autre LLM.

Elle montre exactement ce que NaileR produit avec les calculs mécaniques seuls, puis ce que le LLM, le parsing et les validateurs ajoutent à partir des mêmes sources de vérité.

## Les deux branches

| Étape | NaileR mécanique | NaileR + LLM + parsing |
|---|---|---|
| Profils statistiques | Calculés et traçables | Identiques ; ils servent de preuves |
| Verbatims | Conservés avec evidence IDs | Identiques ; ils servent de preuves |
| Prompts | Construits, inspectables | Envoyés au modèle |
| Interprétation textuelle | Absente | Profils parsés et structurés |
| Intégration statistique-textuelle | Préparée mais non interprétée | Claims validés par groupe |
| Synthèse intergroupes | Absente | Produite après validation des groupes |
| Rapport métier | Pas de contenu sémantique final | Rapport structuré, Markdown ou compact |

## Invariants vérifiés

- **OK** — Same statistical profiles feed both branches. Both branches use the single object `statistical_profiles`.
- **OK** — Same mechanical textual preparation starts both branches. The LLM textual branch starts from `textual_preparation_mechanical`.
- **OK** — Textual evidence registry is unchanged by LLM generation. The LLM adds semantic profiles but must not alter verbatims or evidence IDs.
- **OK** — Combined evidence registry is unchanged by contextualized LLM generation. The LLM adds integrated claims but must not alter the combined source-of-truth registry.

## Valeur ajoutée observée

| Fonction | Mécanique | LLM + parsing |
|---|---|---|
| Statistical evidence registry | 25 IDs | 25 identical IDs |
| Textual evidence registry | 45 IDs | 45 identical IDs |
| Prompts | 3 contextualized prompt previews | Consumed by the LLM |
| Raw LLM response | Absent | Present |
| Parsed textual profiles | Absent | 0 flattened textual claims |
| Parsed contextualized claims | Absent | 18 validated contextualized claims |
| Cross-group synthesis | Absent | 0 cross-group claims |
| Evidence-linked semantic claims | Absent | 12 claims with cited evidence |
| Normalization warnings | Not applicable | 0 |
| Semantic audit warnings | Not applicable | 1 |
| Final semantic report | Mechanical-only / not generated | Present |

## Statuts d'exécution

| Étape | Branche | Succès | Statut de parsing | Appels LLM | Temps (s) | Erreur |
|---|---|---:|---|---:|---:|---|
| Common mechanical preparation | shared | TRUE | not_applicable | 0 |  |  |
| Mechanical nail_catdes | mechanical | TRUE | not_applicable | 0 |  |  |
| Mechanical nail_textual | mechanical | TRUE | not_generated | 0 |  |  |
| Mechanical nail_textual_contextualized | mechanical | TRUE | not_generated | 0 |  |  |
| LLM nail_catdes | llm | TRUE | not_applicable | 1 |  |  |
| LLM + parsing nail_textual | llm_parsing | TRUE | error | 1 |  |  |
| LLM + parsing nail_textual_contextualized | llm_parsing | TRUE | partial | 4 |  |  |

## Résultats sémantiques ajoutés

- Claims textuels parsés : **0**
- Claims contextualisés validés : **18**
- Profils de groupe contextualisés : **3**
- Claims transversaux : **0**
- Normalisations déterministes : **0**
- Alertes d'audit sémantique : **1**

## Interprétation correcte de la comparaison

La branche mécanique produit les sources de vérité, les sélections, les diagnostics, les alignements et les prompts. Elle ne produit pas une interprétation sémantique finale.

La branche LLM + parsing transforme ces mêmes sources en propositions interprétatives structurées. NaileR vérifie ensuite leur forme, les evidence IDs, l'appartenance aux groupes, les relations attendues et conserve les avertissements nécessitant une revue métier.

Le gain opérationnel est donc l'automatisation d'une première interprétation traçable et réutilisable. La comparaison ne prouve pas à elle seule que toutes les affirmations sont justes sur le fond.

## Fichiers à examiner en priorité

- `05-value-added-by-llm-and-parsing.csv`
- `04-llm-parsed-textual-claims.csv`
- `04-llm-parsed-contextualized-claims.csv`
- `07-claim-to-evidence-traceability.csv`
- `06-llm-parsing-warnings.csv`
- `03-llm-contextualized-report.md`

Dossier de sortie : `dev/business_validation_outputs/mechanical-vs-llm-parsing-ollama-20260716-213744`
