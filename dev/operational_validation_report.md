# NaileR — validation opérationnelle end-to-end du workflow à cinq fonctions

## 1. Source de vérité et environnement

La seule source utilisée est l’archive fournie `NaileR-last-version.zip`.

- SHA-256 de l’archive source : `f701c480bb2966f8757046663b42719efdf9e8873524ab38bd61e1c8ba149823`
- `unzip -t` : aucune erreur détectée.
- L’archive fournie était aplatie à sa racine. Son contenu a été replacé, sans substitution de fichiers, dans la structure standard d’un package R (`R/`, `man/`, `data/`, `tests/testthat/`, `vignettes/`, `inst/extdata/`) afin de pouvoir exécuter `devtools` et `R CMD check`.
- Exécution sous R 4.5.0, Debian GNU/Linux 13, locale `C.utf8`.

Les implémentations réelles de `SensoMineR` et `ollamar` n’étaient pas téléchargeables dans l’environnement isolé. Des paquets minimaux temporaires ont uniquement permis de satisfaire le chargement des imports. Toutes les analyses LLM ont traversé la vraie frontière interne `.call_llm_base`, avec réponses simulées, parseurs et validateurs réels. L’analyse lexicale optionnelle a été exécutée avec `lexical_analysis = FALSE`. Aucun appel réel à Ollama ou Gemini n’est revendiqué.

## 2. Inspection des jeux de données fournis

Les 15 jeux de données livrés ont été inventoriés. Certains contiennent des textes (`rorschach`, `fabric`, `beard`, `car_alone`, `atomic_habit`), d’autres un ensemble riche de variables structurées (`local_food`, `waste`, `nutriscore`, `atomic_habit_clust`). Aucun ne réunissait proprement, dans un même tableau et pour une typologie directement exploitable :

- au moins trois groupes ;
- plusieurs variables qualitatives ;
- plusieurs variables quantitatives ;
- un verbatim individuel unique clairement associé au groupe.

Un jeu synthétique reproductible a donc été construit conformément à la consigne.

## 3. Jeu de données opérationnel

Le script crée 108 individus, soit 36 individus dans chacun des groupes suivants :

1. `Territorial cooks` ;
2. `Pragmatic families` ;
3. `Curious urbanites`.

Il contient :

- quatre variables qualitatives : `purchase_place`, `cooking_frequency`, `local_product_preference`, `organic_purchase` ;
- quatre variables quantitatives : `territorial_engagement`, `food_knowledge`, `price_constraint`, `openness_to_innovation` ;
- un verbatim `comment`.

Les commentaires sont des formulations réalistes, distinctes des modalités structurées. Ils permettent d’observer :

- une convergence : engagement territorial et discours sur les producteurs ;
- une nuance : orientation locale sans adhésion absolue aux labels ;
- une tension : ouverture à l’innovation et prudence face à la technologie ;
- un élément uniquement statistique : contrainte de prix ;
- un élément uniquement textuel : coordination familiale, autonomie ou besoin de simplicité.

La graine utilisée est `20260716`.

## 4. Résultats opérationnels

### 4.1 `nail_catdes_prep()`

L’appel réel à `FactoMineR::catdes()` puis `nail_catdes_prep(x = catdes_result)` produit un objet de classes :

```text
nail_catdes_prep, statistical_profiles, list
```

Les trois groupes sont présents. Le registre contient 47 preuves statistiques uniques :

- `Territorial cooks` : 11 marqueurs qualitatifs et 4 quantitatifs ;
- `Pragmatic families` : 13 marqueurs qualitatifs et 4 quantitatifs ;
- `Curious urbanites` : 13 marqueurs qualitatifs et 2 quantitatifs.

Les directions, rangs et identifiants ont été contrôlés. Un résultat `catdes` artificiellement vide mais nommé a également été préparé : le groupe sans marqueur est conservé avec des tables vides stables et des métriques égales à zéro.

**Conclusion : opérationnelle.** Les groupes, marqueurs, directions, rangs et `evidence_id` sont faciles à retrouver et directement exploitables.

### 4.2 `nail_catdes()`

Les deux chemins ont été exécutés :

```r
nail_catdes(x = statistical_profiles, generate = FALSE)
nail_catdes(dataset = structured_dataset, num.var = group_column, generate = FALSE)
```

Les deux restituent exactement le même `statistical_profiles`. Les attributs `interpretation_evidence`, `catdes_result` et `catdes_settings` sont disponibles.

Les valeurs suivantes ont été testées :

- `drop.negative = FALSE` et `TRUE` ;
- `quali.sample = 1` et `0.5` ;
- `quanti.sample = 1` et `0.5` ;
- `isolate.groups = FALSE` et `TRUE`.

Elles modifient la sélection ou l’organisation des prompts, jamais la source mécanique. Un appel LLM simulé en mode joint a été effectué ; l’objet `statistical_profiles` est resté inchangé.

**Conclusion : opérationnelle avec réserve mineure.** La compatibilité historique est préservée, mais l’objet hors ligne reste principalement un texte enrichi d’attributs, ce qui rend les artefacts moins immédiatement découvrables qu’une liste nommée.

### 4.3 `nail_textual_prep()`

La préparation hors ligne conserve les 108 lignes et les 108 textes originaux sans modification. Les trois groupes ont chacun :

- 36 textes non vides ;
- 36 textes inclus dans le prompt ;
- aucun texte exclu ou tronqué dans ce scénario.

Les identifiants sont uniques et déterministes. Une seconde exécution avec les mêmes paramètres produit un `textual_evidence` strictement identique.

Une réponse JSON simulée, construite à partir des vrais `evidence_id` et des citations exactes, a traversé `.call_llm_base`, le parseur strict et le validateur. Le statut final est `success`, et `textual_profiles` est construit.

**Conclusion : opérationnelle avec réserve mineure.** Les preuves, diagnostics et prompts sont inspectables. L’analyse lexicale fondée sur la vraie installation de `SensoMineR` n’a pas pu être exercée dans cet environnement.

### 4.4 `nail_textual()`

À partir d’une préparation hors ligne :

- `textual_evidence` est strictement préservé ;
- `textual_profiles` reste `NULL` ;
- aucun rapport sémantique n’est inventé.

À partir d’une préparation générée et validée, les formats `structured`, `markdown` et `compact` ont été produits sous un mock qui provoquait une erreur si un nouvel appel LLM survenait. Aucun nouvel appel n’a été effectué. Les trois formats reposent sur les mêmes preuves et profils.

**Conclusion : opérationnelle.** La fonction joue correctement son rôle de restitution sans réanalyse implicite.

### 4.5 `nail_textual_contextualized()`

Le chemin avancé hors ligne préserve strictement :

- `statistical_profiles` ;
- `textual_evidence` ;
- `textual_profiles`.

L’alignement des groupes repose sur les noms exacts. Le registre combiné distingue :

- `statistical_qualitative` ;
- `statistical_quantitative` ;
- `textual_verbatim` ;
- `textual_interpretation`.

Une réponse JSON contextualisée simulée a traversé le parseur et le validateur stricts. Pour chacun des trois groupes, le résultat validé contient au moins :

- une convergence ;
- une divergence ou tension ;
- un résultat uniquement statistique ;
- un résultat uniquement textuel ;
- une interprétation sociale prudente ;
- un insight consommateur ;
- une hypothèse psychologique avec `validation_needed` ;
- une implication opérationnelle avec `validation_needed` ;
- une priorité de validation.

**Conclusion : opérationnelle avec réserve mineure.** La synthèse est réelle et non une simple juxtaposition. L’identité du contenu mécanique est assurée entre chemins ; l’objet complet diffère volontairement par ses métadonnées de provenance.

## 5. Défaut opérationnel révélé et correction minimale

### Défaut

Avant correction, le chemin débutant de `nail_textual_contextualized()` envoyait le tableau complet à `nail_catdes_prep()`. La colonne sélectionnée par `num.text` était donc convertie en facteur et analysée comme une variable qualitative par `catdes()`.

Reproduction réelle avec les commentaires récurrents du jeu d’exemple :

```text
Registre avancé : 47 lignes
Registre débutant : 74 lignes
Faux marqueurs issus de comment : 27
Registres identiques : FALSE
```

Ce défaut créait un risque de circularité : le même texte pouvait apparaître à la fois comme marqueur statistique et comme preuve textuelle.

### Correction

Une seule ligne fonctionnelle a été ajoutée au chemin brut :

```r
exclude = num.text
```

La colonne textuelle est désormais exclue uniquement de la branche statistique et reste intégralement disponible pour `nail_textual_prep()`.

### Test de non-régression

Le test du chemin brut vérifie maintenant que `nail_catdes_prep()` reçoit bien `exclude = num.text`.

Après correction :

```text
Registre avancé : 47 lignes
Registre débutant : 47 lignes
Marqueurs issus de comment : 0
Groupes identiques : TRUE
Registres identiques : TRUE
```

## 6. Comparaison des chemins débutant et avancé

Après correction :

- profils de groupes statistiques : identiques ;
- registre statistique et identifiants : identiques ;
- preuves textuelles et identifiants : identiques ;
- alignement des groupes : identique ;
- chemin débutant : 1 préparation statistique, 1 préparation textuelle et 1 calcul `catdes` ;
- chemin avancé : aucun recalcul amont.

L’objet `statistical_profiles` complet n’est pas `identical()` entre ces deux chemins uniquement parce que ses attributs et métadonnées enregistrent la provenance (`dataset` contre `x`) et le fait que `proba` a été appliqué dans la fonction. Le contenu mécanique (`groups` et `evidence_registry`) est identique. Cette distinction est saine mais mérite d’être expliquée dans la documentation utilisateur.

## 7. Nombre d’appels exécutés

Dans le script opérationnel complet :

```text
nail_catdes_prep() : 4 appels, appels internes compris
nail_textual_prep(): 4 appels, appels internes compris

LLM simulé pour nail_catdes()                 : 1 appel
LLM simulé pour nail_textual_prep()            : 1 appel
LLM simulé pour nail_textual_contextualized()  : 1 appel
Total d’appels LLM simulés                     : 3 appels
```

## 8. Évaluation ergonomique

| Niveau | Observation | Effet |
|---|---|---|
| Bloquant, corrigé | La colonne `num.text` entrait dans `catdes()` dans le chemin débutant contextualisé. | Contamination de la preuve statistique et divergence des chemins. |
| Mineur | Les noms principaux de `nail_textual_contextualized()` restent `group_profile_prep` et `textual_prep`, tandis que les alias plus explicites sont `statistical_profiles` et `textual_preparation`. | La signature est moins homogène que le workflow conceptuel. |
| Mineur | L’identité complète des profils diffère entre chemin brut et préparé à cause des métadonnées de provenance. | Un utilisateur peut confondre égalité mécanique et `identical()` de l’objet entier. |
| Mineur | `nail_catdes(generate = FALSE)` renvoie un texte ou une liste de textes enrichi d’attributs. | Les artefacts centraux sont moins visibles qu’avec une liste structurée. |
| Mineur | Le rôle de `generate` diffère légèrement entre préparation, analyse et restitution. | Une documentation de parcours débutant est utile pour éviter l’idée d’un nouvel appel implicite. |
| Cosmétique | Le message `Execution halted: No selected statistical evidence. Nothing to generate.` apparaît dans un test réussi. | Le terme “halted” peut sembler signaler un échec global. |

Aucun nouveau refactoring n’a été entrepris.

## 9. Commandes réellement exécutées

Principales commandes :

```bash
sha256sum /mnt/data/NaileR-last-version.zip
unzip -t /mnt/data/NaileR-last-version.zip
```

```r
devtools::load_all(reset = TRUE)
source("dev/validate_five_function_workflow.R")
source("examples/NaileR-five-function-workflow.R")

devtools::document()
devtools::load_all(reset = TRUE)

testthat::test_file("tests/testthat/test-catdes-prep.R")
testthat::test_file("tests/testthat/test-catdes.R")
testthat::test_file("tests/testthat/test-preparation.R")
testthat::test_file("tests/testthat/test-textual.R")
testthat::test_file("tests/testthat/test-contextualized.R")

devtools::test()
devtools::check()
```

`devtools::document()` a été exécuté, mais roxygen2 7.3.2 était installé alors que le package indique 7.3.3. Aucune régénération de documentation n’a donc été effectuée.

## 10. Résultats techniques finaux

### Tests ciblés

Les cinq fichiers demandés passent sans échec ni warning.

### Suite complète

```text
761 attentes réussies
0 échec
0 warning
0 skip
```

### `devtools::check()`

Le journal final de `R CMD check --as-cran --no-manual` produit par `devtools::check()` indique :

```text
Status: 1 NOTE
```

La seule note est :

```text
checking for future file timestamps ... NOTE
unable to verify current time
```

Tous les autres contrôles sont `OK`, notamment : installation, syntaxe, chargement, dépendances déclarées, documentation, exemples, tests, vignettes et reconstruction des vignettes.

## 11. Fichiers créés ou modifiés

Fichiers modifiés :

- `.Rbuildignore` ;
- `R/nail_textual_contextualized.R` ;
- `tests/testthat/test-contextualized.R`.

Fichiers créés :

- `dev/validate_five_function_workflow.R` ;
- `dev/operational_workflow_dataset.csv` ;
- `dev/operational_textual_report.md` ;
- `dev/operational_contextualized_report.md` ;
- `dev/operational-defect-001.md` ;
- `dev/operational_validation_report.md` ;
- `examples/NaileR-five-function-workflow.R`.

Les dossiers `dev/` et `examples/` sont conservés dans l’archive de travail mais exclus de la construction CRAN via `.Rbuildignore`.

## 12. Verdicts finaux

```text
nail_catdes_prep()             : opérationnelle
nail_catdes()                  : opérationnelle avec réserve mineure
nail_textual_prep()            : opérationnelle avec réserve mineure
nail_textual()                 : opérationnelle
nail_textual_contextualized()  : opérationnelle avec réserve mineure
```

## Verdict global

**Le workflow est opérationnel avec des ajustements mineurs.**

Le seul défaut fonctionnel bloquant révélé par l’exemple a été corrigé de manière locale et couvert par un test. Les chemins bruts et préparés reposent désormais sur les mêmes preuves mécaniques, les simulations LLM traversent les validateurs réels, les rapports sont traçables, les 761 attentes passent et le contrôle de package ne conserve qu’une note liée à l’horloge de l’environnement.
