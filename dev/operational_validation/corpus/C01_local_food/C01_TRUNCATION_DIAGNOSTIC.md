# C01 — Diagnostic de la réponse incomplète `G3_R01`

## Objet contrôlé

La clé de correspondance identifie `G3_R01` comme la réponse du groupe 3
produite dans la condition C (introduction contextualisée et requête
historique). La réponse brute correspondante est :

`gemini_end_to_end_BC/C/response_3.txt`

Elle contient 3 563 octets et se termine par :

> Their responses often show a higher frequency of "Neither acceptable nor unacceptable," suggesting a general inclination towards neutrality when

La phrase est grammaticalement incomplète. La réponse sauvegardée est donc
effectivement tronquée, indépendamment de toute interprétation scientifique.

## Paramètres disponibles

La génération a été exécutée avec :

- fournisseur : `gemini` ;
- modèle : `gemini-2.5-flash` ;
- `max_output_tokens = 8192` ;
- `max_tries = 1` ;
- timeout par appel : `90` secondes ;
- condition : `C` ;
- groupe : `3`.

La génération intégrée de C a produit trois réponses et a été enregistrée
comme réussie au niveau du workflow. Le résultat C conserve le prompt, le
texte retourné et l'objet `llm_io`, mais pas la réponse HTTP complète.

## Métadonnées et raison d'arrêt

Aucune valeur de `finishReason`, `usageMetadata`, nombre de tokens ou statut
HTTP final n'est disponible dans les artefacts de cette génération. Aucune
raison d'arrêt n'est donc enregistrée pour `G3_R01`.

## Comportement de `gemini_generate()`

Le wrapper actuel :

1. construit une requête `generateContent` avec `maxOutputTokens` lorsque
   l'argument est fourni ;
2. exécute `httr2::req_perform()` puis `resp_body_json()` ;
3. vérifie qu'un candidat et du texte existent ;
4. concatène les parties textuelles du premier candidat ;
5. retourne uniquement cette chaîne de caractères.

Il ne renvoie ni le JSON HTTP brut, ni `finishReason`, ni les métadonnées de
consommation. Il ne peut donc pas distinguer a posteriori une limite de
sortie, un arrêt normal du modèle, une interruption de transmission ou une
autre cause lorsque le serveur a tout de même fourni du texte.

## Conclusion causale

**Démontré :** le texte conservé est incomplet et aucun motif d'arrêt n'est
présent dans les artefacts accessibles.

**Non démontré :** une limite de tokens, un arrêt explicite du modèle, un
incident de transmission ou toute autre cause précise. La longueur observée
est compatible avec plusieurs hypothèses et ne permet pas d'en retenir une.

Aucune régénération n'a été effectuée et le wrapper n'a pas été modifié.

## Conséquence pour C01

C01 conserve ses validations statistique et technique ainsi que ses neuf
interprétations produites. La réponse incomplète doit être signalée comme
une limite de la campagne ; elle ne fait pas l'objet d'une seconde
évaluation indépendante. Les résultats A/B/C restent exploratoires et ne
permettent pas de conclure à la supériorité systématique d'une configuration.
