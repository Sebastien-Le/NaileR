# Contextualized statistical-textual analysis

Parse status: **partial**

## Ancrés locaux

Alignment: `matched_without_textual_profile`.
Available sources: statistical, textual_evidence.

### Mechanical limits
- Textual evidence may be available, but no validated textual profile is available for this group.
- The textual profile could not be parsed: The LLM response contains a Markdown fence; strict JSON was required.

### Integrated profile
- Les Ancrés locaux se caractérisent par une forte implication dans les circuits courts et une préférence marquée pour les produits locaux et de saison. Ils cuisinent fréquemment, privilégient les marchés et petits commerces, et montrent un engagement territorial élevé ainsi qu'une bonne connaissance des produits alimentaires. [expert_interpretation] Statistical evidence: Ancrés locaux::quali::cooking_frequency::Quotidienne, Ancrés locaux::quali::purchase_place::Marché/local, Ancrés locaux::quanti::territorial_engagement, Ancrés locaux::quanti::food_knowledge; textual evidence: Ancrés locaux::verbatim::1, Ancrés locaux::verbatim::2, Ancrés locaux::verbatim::4, Ancrés locaux::verbatim::6. Relationship: convergence.

### Convergences
- La fréquence élevée de cuisson quotidienne (86.67% dans le groupe contre 40% globalement) converge avec les verbatims soulignant l'importance de contrôler la qualité des aliments en cuisinant soi-même. [expert_interpretation] Statistical evidence: Ancrés locaux::quali::cooking_frequency::Quotidienne; textual evidence: Ancrés locaux::verbatim::1, Ancrés locaux::verbatim::12. Relationship: convergence.
- La préférence pour les achats en marché/local (60% dans le groupe contre 31.11% globalement) est confirmée par les verbatims insistant sur l'habitude d'acheter au marché et la provenance des produits. [expert_interpretation] Statistical evidence: Ancrés locaux::quali::purchase_place::Marché/local; textual evidence: Ancrés locaux::verbatim::1, Ancrés locaux::verbatim::3, Ancrés locaux::verbatim::5, Ancrés locaux::verbatim::7. Relationship: convergence.

### Statistical-only findings
- Le groupe montre une sous-représentation significative des achats en hard-discount (0% dans le groupe contre 20% globalement), ce qui n'est pas explicitement mentionné dans les verbatims. [expert_interpretation] Statistical evidence: Ancrés locaux::quali::purchase_place::Hard-discount; textual evidence: none. Relationship: statistical_only.

### Interpretation limits
- L'absence de profil textuel validé limite la possibilité d'identifier des tensions ou convergences plus subtiles entre les données qualitatives et quantitatives. [expert_interpretation] Statistical evidence: none; textual evidence: none. Relationship: scope_limit.
- Les verbatims disponibles pourraient ne pas couvrir l'ensemble des aspects mesurés par les marqueurs quantitatifs, notamment en ce qui concerne l'engagement territorial et la connaissance alimentaire. [expert_interpretation] Statistical evidence: none; textual evidence: none. Relationship: scope_limit.

## Curieux flexibles

Alignment: `matched_without_textual_profile`.
Available sources: statistical, textual_evidence.

### Mechanical limits
- Textual evidence may be available, but no validated textual profile is available for this group.
- The textual profile could not be parsed: The LLM response contains a Markdown fence; strict JSON was required.

### Integrated profile
- The Curieux flexibles group exhibits a high openness to innovation and a flexible approach to purchasing, combining various shopping circuits and showing a preference for online/mixed purchasing while avoiding hard-discount stores. They frequently purchase organic products and are interested in discovering new ways of consuming, valuing diversity and practicality. [expert_interpretation] Statistical evidence: Curieux flexibles::quali::organic_purchase::Parfois, Curieux flexibles::quali::purchase_place::En ligne/mixte, Curieux flexibles::quali::purchase_place::Hard-discount, Curieux flexibles::quanti::openness_to_innovation; textual evidence: Curieux flexibles::verbatim::31, Curieux flexibles::verbatim::32, Curieux flexibles::verbatim::35, Curieux flexibles::verbatim::36. Relationship: convergence.

### Convergences
- The group's high openness to innovation is supported by both statistical data showing a higher mean score and verbal expressions of interest in testing new products and services. [expert_interpretation] Statistical evidence: Curieux flexibles::quanti::openness_to_innovation; textual evidence: Curieux flexibles::verbatim::32, Curieux flexibles::verbatim::33, Curieux flexibles::verbatim::39. Relationship: convergence.
- The preference for online/mixed purchasing is echoed in the verbatims where respondents mention combining different shopping circuits and using online platforms. [expert_interpretation] Statistical evidence: Curieux flexibles::quali::purchase_place::En ligne/mixte; textual evidence: Curieux flexibles::verbatim::31, Curieux flexibles::verbatim::35, Curieux flexibles::verbatim::37, Curieux flexibles::verbatim::40. Relationship: convergence.

### Statistical-only findings
- The group is significantly underrepresented in hard-discount purchasing, which is not directly addressed in the verbatims. [expert_interpretation] Statistical evidence: Curieux flexibles::quali::purchase_place::Hard-discount; textual evidence: none. Relationship: statistical_only.

### Interpretation limits
- The absence of a validated textual profile limits the depth of integration between statistical and textual evidence. [expert_interpretation] Statistical evidence: none; textual evidence: none. Relationship: scope_limit.
- The verbatims may not fully capture the nuances of the statistical markers, particularly regarding the underrepresentation in hard-discount purchasing. [expert_interpretation] Statistical evidence: none; textual evidence: none. Relationship: scope_limit.

## Pragmatiques contraints

Alignment: `matched_without_textual_profile`.
Available sources: statistical, textual_evidence.

### Mechanical limits
- Textual evidence may be available, but no validated textual profile is available for this group.
- The textual profile could not be parsed: The LLM response contains a Markdown fence; strict JSON was required.

### Integrated profile
- Les Pragmatiques contraints sont fortement contraints par le prix et le temps, ce qui influence leurs choix d'achat. Ils privilégient les hard-discounts (60% contre 20% globalement) et achètent rarement des produits bio (66.67% contre 28.89% globalement). Leur préférence pour les circuits locaux est faible (0% contre 31.11% globalement), tout comme leur fréquence de cuisson quotidienne (13.33% contre 40% globalement). Ils ont un niveau de connaissance alimentaire plus bas (moyenne de 3.93 contre 6.06) et une contrainte de prix plus élevée (moyenne de 7.73 contre 5.74). Leur engagement territorial et leur ouverture à l'innovation sont également plus faibles. [expert_interpretation] Statistical evidence: Pragmatiques contraints::quali::purchase_place::Hard-discount, Pragmatiques contraints::quali::organic_purchase::Rarement, Pragmatiques contraints::quali::purchase_place::Marché/local, Pragmatiques contraints::quanti::food_knowledge, Pragmatiques contraints::quanti::price_constraint; textual evidence: Pragmatiques contraints::verbatim::16, Pragmatiques contraints::verbatim::17, Pragmatiques contraints::verbatim::23, Pragmatiques contraints::verbatim::24. Relationship: convergence.

### Convergences
- Les Pragmatiques contraints expriment une préférence pour les circuits locaux lorsqu'ils sont accessibles, ce qui converge avec leur sous-représentation dans l'achat en marché/local. [expert_interpretation] Statistical evidence: Pragmatiques contraints::quali::purchase_place::Marché/local; textual evidence: Pragmatiques contraints::verbatim::16, Pragmatiques contraints::verbatim::20. Relationship: convergence.
- Le manque d'informations simples pour arbitrer leurs choix, mentionné dans les verbatims, correspond à leur faible niveau de connaissance alimentaire. [expert_interpretation] Statistical evidence: Pragmatiques contraints::quanti::food_knowledge; textual evidence: Pragmatiques contraints::verbatim::18, Pragmatiques contraints::verbatim::25. Relationship: convergence.

### Statistical-only findings
- Le groupe a une ouverture à l'innovation plus faible que la moyenne, ce qui n'est pas directement évoqué dans les verbatims. [expert_interpretation] Statistical evidence: Pragmatiques contraints::quanti::openness_to_innovation; textual evidence: none. Relationship: statistical_only.

### Interpretation limits
- L'absence de profil textuel validé limite la possibilité d'identifier des tensions ou convergences supplémentaires. [expert_interpretation] Statistical evidence: none; textual evidence: none. Relationship: scope_limit.
- Les verbatims disponibles sont limités et pourraient ne pas couvrir l'ensemble des aspects du groupe. [expert_interpretation] Statistical evidence: none; textual evidence: none. Relationship: scope_limit.

# Cross-group analysis

