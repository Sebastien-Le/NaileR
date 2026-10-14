# QDA modular prompt — bilingual scientific review

**Status:** SCIENTIFICALLY APPROVED AND STABILIZED (2026-10-14). Complete bilingual `reading`, `interpretation`, `known` / `unknown` identity blocks, local/joint `task`, and `output` have all been explicitly approved. Four documentary configurations are assembled. No R code integration or LLM operational validation has occurred.
**Branch:** `dev-statistical-prompt-framework`.
**Technical source:** `R/nail_qda.R` (`SensoMineR::decat()`, canonical `product_profiles`, interpretation evidence and semantic-facing markers).
**Scope:** scientific/operational prompt wording only. No R runtime changes, test modifications, evidence-selection changes or API changes.

## Approved cross-functional methodological decision

The LLM must interpret the provided statistical facts as well as possible, with a coherent, substantive and well-grounded sensory synthesis. The default operational prompt does **not** explain that `sample.pct`, `drop.negative`, or `sample.method` might have hidden other eligible observations. That provenance and selection policy remain transparent in R and canonical evidence. Do not infer unmeasured sensory qualities or relationships; interpretation remains supported by the transmitted evidence.

The analyst explicitly agreed to **delete without replacement** the earlier candidate paragraph:

> The displayed evidence may contain only a selection of statistically retained attributes. Do not infer that undisplayed attributes are absent, average, or unimportant. If LOWER attributes have been excluded, the displayed evidence provides only a partial characterization.

The deletion was approved separately and subsequently the complete bilingual `reading` text below was explicitly approved on 2026-10-14, unchanged.

## 1. `reading` — APPROVED (complete bilingual wording, 2026-10-14)

### English — approved operational text

The results come from `SensoMineR::decat()` and characterize evaluated products or stimuli through their sensory attributes, relative to the average sensory profile of the evaluated set. This average product is a statistical reference, not an actual evaluated product.

For a given attribute, HIGHER means that the product's adjusted sensory score is statistically higher than the reference; LOWER means it is statistically lower. These directions are relative: LOWER does not mean that the attribute is absent or that its opposite is present.

The adjusted mean is the model-adjusted sensory score for the product and attribute, not its difference from the reference. The `v.test` is a signed standardized statistic, while the `p.value` describes statistical evidence. Neither measures sensory intensity or substantive importance. Do not compare adjusted means across different attributes as if they measured the same sensory characteristic.

Preserve the meaning of each sensory attribute. Use the study context to understand the sensory characteristics, without treating it as additional statistical evidence. Do not infer liking, preference, quality, manufacturing causes, or statistically demonstrated differences between pairs of products from these results.

### Français — traduction de contrôle validée

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
- Complete `reading` wording was explicitly approved in English and French on 2026-10-14, without altering this `interpretation` block. No R code changes.



## 3. Product/stimulus identity — APPROVED (2026-10-14)

The two identity modes share the general interpretive principles of `standard` and `latent` in the other NaileR workflows, while preserving the scientific distinction between an **anonymized observed stimulus** and a **statistically constructed latent group**.

### `product_knowledge = "known"` — APPROVED

**English — approved operational text**

Each product or stimulus has a known identity or a meaningful label provided by the analyst. Preserve its original identifier and label.

Use this identity as contextual information when interpreting the sensory profile, without letting it substitute for the statistical evidence.

Do not replace the known identity with an invented descriptive name. A concise sensory characterization may complement it when useful.

**Français — traduction de contrôle validée**

Chaque produit ou stimulus possède une identité connue ou un intitulé significatif fourni par l'analyste. Conservez son identifiant et son intitulé d'origine.

Utilisez cette identité comme information contextuelle pour interpréter le profil sensoriel, sans qu'elle se substitue aux résultats statistiques.

Ne remplacez pas l'identité connue par un nom descriptif inventé. Une caractérisation sensorielle concise peut la compléter lorsqu'elle est utile.

### `product_knowledge = "unknown"` — APPROVED

**English — approved operational text**

Each stimulus is identified by a code or label that does not reveal its substantive identity. Preserve this original identifier.

Interpret its sensory profile to characterize what makes it distinctive. When supported by a coherent sensory pattern, propose a concise, meaningful sensory name alongside the identifier.

Do not attempt to guess the stimulus's actual identity or force a descriptive name when the profile does not support one.

**Français — traduction de contrôle validée**

Chaque stimulus est identifié par un code ou un intitulé qui ne révèle pas son identité substantielle. Conservez cet identifiant d'origine.

Interprétez son profil sensoriel pour caractériser ce qui le distingue. Lorsque les résultats présentent une configuration sensorielle cohérente, proposez un nom sensoriel court et significatif, en complément de l'identifiant.

Ne cherchez pas à deviner l'identité réelle du stimulus ni à lui attribuer artificiellement un nom descriptif lorsque son profil ne le justifie pas.

### Architectural decision

- Conceptual correspondence: `known` resembles `standard` (identity already meaningful); `unknown` resembles `latent` (meaning must be constructed from the profile), **without** claiming that unknown QDA stimuli are statistical latent entities.
- Retain the existing QDA API values `product_knowledge = "known"` / `"unknown"`; do not rename or reinterpret function arguments.
- Product/stimulus identity is independent of `isolate.groups` (local versus joint task).
- Preserve actual product identifiers and analyst labels; a descriptive name, when supported, may only supplement the original identifier.
- These are approved editorial blocks only: no R code modifications or tests in this pass.

## 4. Local/joint tasks

### Local task — APPROVED (bilingual wording, 2026-10-14)

**English — approved operational text**

Interpret only the product or stimulus "[identifier]" using its displayed statistical evidence and the user's analytical request.

Characterize its distinctive sensory profile relative to the average product. Do not describe or compare other products or stimuli.

**Français — traduction de contrôle validée**

Interprétez uniquement le produit ou stimulus « [identifier] » à partir de ses résultats statistiques et de la question analytique de l'utilisateur.

Caractérisez son profil sensoriel distinctif relativement au produit moyen. Ne décrivez pas et ne comparez pas les autres produits ou stimuli.

**Decision**

- Apply only when `isolate.groups = TRUE`; `[identifier]` is the actual product/stimulus identifier substituted at runtime.
- The identity mode `known` / `unknown` is independent of task scope.
- Interpretation rules and relative statistical reference are owned by the common `interpretation` and `reading` blocks.
- No R code or existing runtime prompt is changed here.

### Joint task — APPROVED (bilingual wording, 2026-10-14)

**English — approved operational text**

Interpret the displayed products or stimuli jointly, using their statistical evidence and the user's analytical request.

Characterize each sensory profile, then identify the main similarities, contrasts and, when supported, coherent sensory families across the evaluated set.

Ground comparisons in the displayed sensory profiles, interpreted relative to the average product. Do not present descriptive contrasts as statistically demonstrated pairwise differences between products or stimuli.

**Français — traduction de contrôle validée**

Interprétez conjointement les produits ou stimuli présentés, à partir de leurs résultats statistiques et de la question analytique de l'utilisateur.

Caractérisez chaque profil sensoriel, puis identifiez les principales ressemblances, différences et, lorsque les résultats le permettent, les familles sensorielles cohérentes au sein de l'ensemble évalué.

Fondez les comparaisons sur les profils sensoriels présentés, interprétés relativement au produit moyen. Ne présentez pas les contrastes descriptifs comme des différences statistiquement démontrées entre produits ou stimuli pris deux à deux.

**Decision**

- Apply this task when `isolate.groups = FALSE`; it deliberately combines descriptions of each sensory profile with descriptive cross-profile comparisons.
- A sensory family or sensory pole is an interpretive synthesis, not a clustering result or evidence of a pairwise statistical test.
- This route is independent of `product_knowledge`; identifiers and optional naming are handled by `known` / `unknown`.
- No new QDA `interpretation_mode` argument is authorized and no R code is modified in this pass.


## 5. `output` — APPROVED (bilingual wording, 2026-10-14)

### English — approved operational text

Write a clear, well-structured and substantive interpretation of the evaluated sensory profiles.

Support the main conclusions with the most relevant sensory attributes, preserving their HIGHER/LOWER directions. Include adjusted means or other statistical values when they help clarify and substantiate the interpretation.

Avoid mechanically reproducing the statistical results or unnecessary numerical repetition.

### Français — traduction de contrôle validée

Rédigez une interprétation claire, structurée et substantielle des profils sensoriels évalués.

Appuyez les principales conclusions sur les attributs sensoriels les plus pertinents, en respectant leur direction HIGHER/LOWER. Mentionnez les moyennes ajustées ou d'autres valeurs statistiques lorsqu'elles permettent d'éclairer et d'étayer l'interprétation.

Évitez de reproduire mécaniquement les résultats statistiques ou de multiplier les répétitions numériques inutiles.

### Decision

- Editorial restitution block expressly approved in English and French on 2026-10-14.
- Interpretation synthesis is owned by `interpretation`, identity/naming by `known` or `unknown`, and scope/comparison by the selected `task`.
- No hard-coded Quarto/Markdown formatting requirement in the customizable editorial text; technical parsing and output contracts remain separately applicable at implementation.
- No R source code was changed.



## Final scientific sign-off (2026-10-14)

The analyst explicitly confirmed the complete bilingual `reading` block exactly as proposed after the four configuration assemblies and redundancy audit. Together with the previously validated `interpretation`, `known`/`unknown`, local/joint `task`, and `output`, this closes QDA's modular scientific wording review. The small intentional overlaps concerning HIGHER/LOWER directions, the average reference, and warnings against nonexistent pairwise tests remain unchanged pending operational assessment with actual LLMs.

The four assembled examples in [QDA_ASSEMBLY_REVIEW.md](QDA_ASSEMBLY_REVIEW.md) are documentary compositions. The scientific sign-off does not imply tests with real data or integration into R. `product_knowledge`, `isolate.groups`, evidence sampling parameters and existing output/parser contracts are preserved.

## Implementation boundary

The runtime implementation in `R/nail_qda.R` still includes explicit selection policy and undisplayed-attribute explanations in its generated reading. This scientific proposal does not modify that code. When integrating the modular prompt later, preserve the statistical-selection controls, evidence registry, and invariance contracts; separate prompt editorial wording from provenance.
