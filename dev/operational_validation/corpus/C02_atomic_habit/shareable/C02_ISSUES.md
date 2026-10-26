# C02 — Questions ouvertes et limites

## Provenance de la classification

La documentation fournit deux descriptions compatibles avec la classification
publiée : une AFM sur 30 variables avec le troisième groupe supplémentaire,
et une AFM sur les 20 premières variables. Les deux reproductions donnent
exactement les affectations 84/13/70, mais aucun script historique canonique
retrouvé ne permet de choisir entre elles. La classification distribuée doit
être conservée comme référence et la provenance exacte reste `unknown`.

## Choix de la table CATDES

La référence utilise les 20 variables structurées (capacité et échelle de
restrictivité) plus `clust`. Les facteurs binaires 21–30, les dix textes et les
composites 41–50 sont exclus pour éviter de compter comme indépendantes des
informations redondantes ou dérivées. Ce choix est documenté et n'altère pas
les objets originaux.

## Limites scientifiques

- `clust` est construit : le mode `latent` est un choix d'interprétation, pas
  une preuve automatique de la nature des groupes.
- Une capacité déclarée ne doit pas être réécrite comme comportement adopté.
- Une contrainte perçue ne doit pas être présentée comme cause démontrée.
- Le groupe 2 (13 individus) exige une prudence particulière.
- Les textes sont individuels et potentiellement sensibles ; ils restent
  locaux jusqu'à décision de partage.

## Statut

Le cas est `ready_for_validation` pour une validation LLM ultérieure. La phase
présente valide la structure, la classification publiée, la préparation
CATDES, les preuves et les prompts hors ligne ; elle ne valide pas la qualité
des interprétations générées.
