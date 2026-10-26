# C02 — Revue des prompts hors ligne

## Introduction et requête utilisées

Les quatre previews utilisent la même introduction et la même requête, afin de
séparer les effets d'assemblage du prompt des effets statistiques.

Introduction :

> These data come from a survey of 167 people about everyday practices.
> Participants reported whether they felt able to adopt several practices
> and how restrictive they perceived them to be. The three groups are
> constructed profiles from an upstream classification; their labels are
> identifiers, not substantive names.

Requête :

> Interpret the constructed groups from the displayed capability and
> perceived-restrictiveness evidence. Synthesize convergent findings,
> distinguish declared capability from perceived constraint, and do not
> turn intentions into observed behaviour or perceived constraints into
> demonstrated causes.

## Configurations

| Configuration | Prompts | Taille approximative des prompts |
|---|---:|---|
| `local_full` | 3 | 8 486 / 6 227 / 7 599 caractères |
| `local_drop_negative` | 3 | 5 655 / 5 234 / 6 406 caractères |
| `joint_full` | 1 | 15 062 caractères |
| `joint_drop_negative` | 1 | 10 045 caractères |

Le mode latent est utilisé parce que `clust` est une classification construite.
Les identifiants 1, 2 et 3 restent des identifiants ; aucun nom substantif de
groupe n'est imposé par le script.

Le contenu statistique canonique reste identique. `drop.negative` agit sur la
présentation des marqueurs négatifs dans les prompts, pas sur la preuve
statistique sous-jacente.

Les prompts complets, sans troncature, sont dans les sous-dossiers de
`prompts/`. Aucune réponse LLM n'a été produite.
