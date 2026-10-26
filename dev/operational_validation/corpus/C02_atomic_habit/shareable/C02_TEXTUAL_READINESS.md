# C02 — Préparation du futur workflow TEXTUAL

## Audit des justifications

Les dix colonnes 31–40 sont des chaînes de caractères. Chacune contient 167
réponses non vides et aucune valeur manquante. Le nombre de textes distincts
varie de 148 à 164 selon la question ; les doublons sont donc présents et ne
doivent pas être interprétés comme des individus supplémentaires.

Les effectifs par groupe sont calculés dans `text_audit_by_group.csv`. Les
dénominateurs appropriés sont les individus du groupe (84, 13 et 70), tandis
que le nombre de textes effectivement sélectionnés dépendra de la colonne, du
sampling et du contrat de `nail_textual()`.

Chaque question fermée possède une colonne de justification textuelle
correspondante : `car_alone_text`, `never_plane_text`, `loan_text`,
`second_hand_text`, `unpackaged_text`, `local_products_text`, `turn off_text`,
`drop_temperature_text`, `vegan_text` et `linen_text`. La présence de textes
ne prouve pas que la justification décrit exclusivement la réponse fermée ;
cette relation devra être conservée comme contexte et non comme vérité
causale.

## Fonctions pertinentes

Un futur cas textuel pourrait appeler `nail_textual()` une question à la fois,
par exemple avec `num.var = 51` et `num.text = 31`, puis répéter le protocole
pour les neuf autres colonnes. `nail_textual_prep()` pourrait préparer les
profils textuels avant une composition. `nail_textual_contextualized()` ne
devrait être envisagée qu'après validation de l'alignement exact entre les
groupes CATDES et TEXTUAL.

Ces appels ne sont pas exécutés dans C02. Aucune génération textuelle n'est
réalisée et aucun verbatim n'est copié dans les livrables partageables.

## Risques

- Le groupe 2 est petit, ce qui réduit la stabilité des thèmes et des taux.
- Les réponses répétées ne sont pas une preuve de répondants distincts.
- Une contextualisation doit distinguer citation, thème synthétique et
  hypothèse interprétative.
- Les données originales peuvent contenir des informations personnelles ; une
  revue de divulgation est requise avant tout partage de textes.
