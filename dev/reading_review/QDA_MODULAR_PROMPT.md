# QDA modular prompt — bilingual scientific review

**Status:** IN PROGRESS — `interpretation` fully APPROVED (2026-10-14); `reading` remains a candidate with its selection/missing-attribute paragraph removed by explicit approval. Identity, task, and output blocks pending.
**Branch:** `dev-statistical-prompt-framework`.
**Technical source:** `R/nail_qda.R` (`SensoMineR::decat()`, canonical `product_profiles`, interpretation evidence and semantic-facing markers).
**Scope:** scientific/operational prompt wording only. No R runtime changes, test modifications, evidence-selection changes or API changes.

## Approved cross-functional methodological decision

The LLM must interpret the provided statistical facts as well as possible, with a coherent, substantive and well-grounded sensory synthesis. The default operational prompt does **not** explain that `sample.pct`, `drop.negative`, or `sample.method` might have hidden other eligible observations. That provenance and selection policy remain transparent in R and canonical evidence. Do not infer unmeasured sensory qualities or relationships; interpretation remains supported by the transmitted evidence.

The analyst explicitly agreed to **delete without replacement** the earlier candidate paragraph:

> The displayed evidence may contain only a selection of statistically retained attributes. Do not infer that undisplayed attributes are absent, average, or unimportant. If LOWER attributes have been excluded, the displayed evidence provides only a partial characterization.

This deletion alone is approved; scientific review of the remaining wording follows.

## 1. `reading` — CANDIDATE (not yet fully approved)

### English — proposed operational text

The results come from `SensoMineR::decat()` and characterize evaluated products or stimuli through their sensory attributes, relative to the average sensory profile of the evaluated set. This average product is a statistical reference, not an actual evaluated product.

For a given attribute, HIGHER means that the product's adjusted sensory score is statistically higher than the reference; LOWER means it is statistically lower. These directions are relative: LOWER does not mean that the attribute is absent or that its opposite is present.

The adjusted mean is the model-adjusted sensory score for the product and attribute, not its difference from the reference. The `v.test` is a signed standardized statistic, while the `p.value` describes statistical evidence. Neither measures sensory intensity or substantive importance. Do not compare adjusted means across different attributes as if they measured the same sensory characteristic.

Preserve the meaning of each sensory attribute. Use the study context to understand the sensory characteristics, without treating it as additional statistical evidence. Do not infer liking, preference, quality, manufacturing causes, or statistically demonstrated differences between pairs of products from these results.

### Français — traduction de contrôle proposée

Les résultats proviennent de `SensoMineR::decat()` et caractérisent les produits ou stimuli évalués à partir de leurs attributs sensoriels, relativement au profil sensoriel moyen de l'ensemble des produits évalués. Ce produit moyen constitue une référence statistique, et non un produit réellement évalué.

Pour un attribut donné, HIGHER signifie que le score sensoriel ajusté du produit est statistiquement supérieur à celui de la référence ; LOWER signifie qu'il lui est statistiquement inférieur. Ces directions sont relatives : LOWER ne signifie pas que l'attribut est absent ou que son contraire est présent.

La moyenne ajustée (*adjusted mean*) est le score sensoriel du produit pour cet attribut, ajusté par le modèle, et non son écart à la référence. Le `v.test` est une statistique de test standardisée et signée, tandis que la `p.value` décrit la preuve statistique. Aucun des deux ne mesure l'intensité sensorielle ou l'importance substantielle. Ne comparez pas les moyennes ajustées de différents attributs comme si elles mesuraient une même caractéristique sensorielle.

Préservez la signification de chaque attribut sensoriel. Utilisez le contexte de l'étude pour comprendre les caractéristiques sensorielles, sans le considérer comme une preuve statistique supplémentaire. Ne déduisez pas de ces résultats des conclusions concernant l'appréciation hédonique, les préférences, la qualité, les causes liées à la fabrication ou des différences statistiquement démontrées entre paires de produits.

## 2. `interpretation` — APPROVED (bilingual wording, 2026-10-14)

### English — approved operational text

Interpret each product or stimulus by considering its displayed sensory attributes jointly, rather than describing them one by one. Identify meaningful patterns and distinctive configurations, and develop a substantive interpretation of the overall sensory profile.

Use knowledge of sensory perception and the study context to connect conceptually related characteristics across the relevant perceptual dimensions. When several attributes converge, develop a higher-level interpretation that captures their combined meaning.

Preserve the relative direction and meaning of each attribute. Distinguish higher-level interpretations from directly measured characteristics, and do not present conceptual connections as statistically demonstrated relationships.

Preserve meaningful contrasts, nuances, and ambiguities. When the evidence is heterogeneous or insufficient to support a unified characterization, do not force a single global interpretation.

### Français — traduction de contrôle validée

Interprétez chaque produit ou stimulus en considérant conjointement ses attributs sensoriels présentés, plutôt qu'en les décrivant un à un. Identifiez les configurations significatives et distinctives, et construisez une interprétation substantielle du profil sensoriel d'ensemble.

Mobilisez les connaissances sur la perception sensorielle et le contexte de l'étude pour rapprocher des caractéristiques conceptuellement liées, en tenant compte des dimensions perceptives pertinentes. Lorsque plusieurs attributs convergent, construisez une interprétation de niveau supérieur qui rende compte de leur signification conjointe.

Préservez le sens relatif et la signification de chaque attribut. Distinguez les interprétations de niveau supérieur des caractéristiques directement mesurées et ne présentez pas les rapprochements conceptuels comme des relations statistiquement démontrées.

Préservez les contrastes, les nuances et les ambiguïtés significatives. Lorsque les résultats sont hétérogènes ou insuffisants pour soutenir une caractérisation unifiée, ne cherchez pas à imposer une interprétation générale unique.

### Decision

- Scientific wording explicitly approved in French and English, replacing a food-centric earlier draft.
- The semantic synthesis must remain applicable to non-food sensory evaluation (e.g. visual, tactile, acoustic, olfactory or other perceptual dimensions) without hard-coding any such examples into the operational text.
- Conceptual sensory synthesis is legitimate, but is not itself an additional measured descriptor or a demonstrated statistical association.
- `reading` remains a candidate pending separate full validation. No R code changes.



## 3. Product/stimulus identity — PENDING

`product_knowledge = "known"` vs `"unknown"` governs labels, not necessarily observed vs constructed entities. Scientific design still to be reviewed.

## 4. Local/joint tasks — PENDING

## 5. `output` — PENDING

## Implementation boundary

The runtime implementation in `R/nail_qda.R` still includes explicit selection policy and undisplayed-attribute explanations in its generated reading. This scientific proposal does not modify that code. When integrating the modular prompt later, preserve the statistical-selection controls, evidence registry, and invariance contracts; separate prompt editorial wording from provenance.
