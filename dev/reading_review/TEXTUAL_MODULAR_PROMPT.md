# TEXTUAL modular prompt — bilingual scientific review

**Status:** ALL BILINGUAL SCIENTIFIC BLOCKS APPROVED (2026-10-15): `reading`, `interpretation`, `local_task`, `nail_textual()` `output` and `nail_textual_prep()` `output`. Cross-route assembly review and operational validation remain separate; R code is unchanged.
**Branch:** `dev-statistical-prompt-framework`.
**Methodological reference:** [TEXTUAL_REFERENCE_PROMPT.md](TEXTUAL_REFERENCE_PROMPT.md) (already approved as scientific V1).
**Decision log:** [TEXTUAL_PROMPT_DECISIONS.md](TEXTUAL_PROMPT_DECISIONS.md).
**Earlier compact draft:** [TEXTUAL_COMPACT_PROMPT.md](TEXTUAL_COMPACT_PROMPT.md) (not approved).

This document records only bilingual operational wording explicitly approved block by block. It concerns classic `nail_textual()` and the reading layer shared with `nail_textual_prep()` **without merging their distinct outputs**. It does not define the separate `nail_textual_contextualized()`, `nail_catdes_textual()`, statistical/textual fusion or multiagent contracts. Scientific approval does not imply implementation or operational validation in R.

## 1. `reading` — APPROVED (complete English/French wording, 2026-10-15)

### English — approved operational text

The evidence consists of textual observations associated with one group. These texts are the empirical material for qualitative analysis. Themes and broader interpretations are constructed from the texts by the language model; they are not statistical results calculated beforehand.

Each text has an identifier linked to a source observation. An observation does not necessarily represent a distinct individual, and identical statements may occur more than once. Preserve the original wording and use the supplied text identifiers when referring to supporting or contrasting evidence. Do not invent quotations.

Interpret the meaning and strength of each statement carefully, preserving negations, hesitation, qualifications, ambiguity and contradictions. Distinguish expressed opinions, perceptions, intentions, reported experiences and observed behaviors.

Distinguish recurring ideas in the texts from the prevalence of opinions among individuals. Repetition does not necessarily imply independent agreement or group consensus. Do not invent numerical prevalence estimates.

Use the study context to understand the responses and the analytical question, without treating it as additional empirical evidence.

### Français — traduction de contrôle validée

Les résultats sont constitués d'observations textuelles associées à un groupe. Ces textes constituent le matériau empirique de l'analyse qualitative. Les thèmes et les interprétations plus générales sont construits par le modèle de langage à partir des textes ; ils ne constituent pas des résultats statistiques préalablement calculés.

Chaque texte possède un identifiant lié à une observation source. Une observation ne représente pas nécessairement un individu distinct et des formulations identiques peuvent apparaître plusieurs fois. Préservez les formulations originales et utilisez les identifiants fournis pour référencer les éléments qui soutiennent ou nuancent une interprétation. N'inventez pas de citations.

Interprétez attentivement le sens et la force de chaque propos, en préservant les négations, les hésitations, les réserves, les ambiguïtés et les contradictions. Distinguez les opinions exprimées, les perceptions, les intentions, les expériences rapportées et les comportements observés.

Distinguez la récurrence des idées dans les textes de la prévalence des opinions parmi les individus. La répétition ne traduit pas nécessairement des accords indépendants ni un consensus au sein du groupe. N'inventez pas d'estimations numériques de prévalence.

Utilisez le contexte de l'étude pour comprendre les réponses et la question analytique, sans le considérer comme une preuve empirique supplémentaire.

### Decision and scope

- English and French formulations above were explicitly approved by the analyst on 2026-10-15, with no editorial changes.
- TEXTUAL observations are empirical material; themes and higher-level constructs are LLM interpretations, not R-derived quantitative findings.
- Preserve traceability through the supplied identifiers without assuming one unique respondent per observation.
- Distinguish thematic recurrence from individual-level prevalence, maintaining linguistic nuance and non-invented quotations.
- Per the cross-functional evidence scope decision ([PROMPT_EVIDENCE_SCOPE_DECISION.md](PROMPT_EVIDENCE_SCOPE_DECISION.md)), do not add generic prompt-visible caveats about unsupplied sampled texts. Canonical evidence, sampling metadata and source-row links remain recorded in R.
- This `reading` is shared conceptually by classic `nail_textual()` and the `nail_textual_prep()` preparation pathway. Their `output` contracts remain different.

## 2. `interpretation` — APPROVED (complete bilingual wording, 2026-10-15)

### English — approved operational text

Identify the main themes expressed in the texts, grouping statements according to their meaning rather than shared vocabulary. Explain their substantive significance in relation to the analytical question.

Interpret the group's discourse by considering these themes jointly, rather than presenting them as a simple list. When supported by the texts, develop a higher-level interpretation that captures the broader concerns, perspectives or frames of meaning emerging from their combination.

Examine internal diversity, including differences in emphasis, reservations, ambivalence, contradictions and meaningful minority perspectives. A shared interpretive frame may accommodate different positions, while several distinct or conflicting frames may coexist within the same group.

Assess whether the discourse exhibits a recognizable common frame. Treat coherence as a qualitative interpretation, not a statistical measure. Do not impose unity when the texts support multiple perspectives or when the evidence is insufficient.

Adapt the depth of interpretation to the richness and diversity of the texts. Avoid elaborate group-level characterizations from sparse evidence. Do not infer hidden motives, personality traits, social identities or causal mechanisms that the texts do not support.

### Français — traduction de contrôle validée

Identifiez les principaux thèmes exprimés dans les textes, en regroupant les propos selon leur signification plutôt que selon leur vocabulaire commun. Expliquez leur portée substantielle au regard de la question analytique.

Interprétez le discours du groupe en considérant conjointement ces thèmes, plutôt qu'en les présentant sous la forme d'une simple liste. Lorsque les textes le permettent, construisez une interprétation de niveau supérieur qui rende compte des préoccupations, des perspectives ou des cadres de sens plus généraux émergeant de leur combinaison.

Examinez la diversité interne, notamment les différences d'accentuation, les réserves, les ambivalences, les contradictions et les points de vue minoritaires significatifs. Un cadre interprétatif partagé peut accueillir des positions différentes, tandis que plusieurs cadres distincts ou contradictoires peuvent coexister au sein d'un même groupe.

Évaluez si le discours présente un cadre de sens commun identifiable. Considérez la cohérence comme une appréciation qualitative, et non comme une mesure statistique. N'imposez pas une unité lorsque les textes révèlent plusieurs perspectives ou lorsque les éléments disponibles sont insuffisants.

Adaptez la profondeur de l'interprétation à la richesse et à la diversité des textes. Évitez de construire des caractérisations élaborées du groupe à partir d'un matériau trop limité. Ne déduisez pas de motivations cachées, de traits de personnalité, d'identités sociales ou de mécanismes causaux que les textes ne permettent pas d'étayer.

### Decision and scope

- The analyst explicitly approved this operational English wording and its French control translation on 2026-10-15 without changes.
- Themes should arise from meaning, not mere lexical similarity; interpretation should relate the thematic configuration to the analyst's question.
- Allow higher-level grounded interpretations, while protecting meaningful disagreement, ambivalence, minority positions and multiple frames.
- Within-group coherence is qualitative, not statistical. The current allowed coherence values belong to the separate output/parser contract.
- Avoid ungrounded personal, social or causal inferences and overinterpretation of sparse material.
- No R implementation or output contract is changed.



## 3. `local_task` — APPROVED (complete bilingual wording, 2026-10-15)

### English — approved operational text

Interpret only the texts associated with group "[identifier]", in light of the user's analytical request.

Construct a substantive textual profile of this group without describing, comparing or inferring the discourse of other groups.

### Français — traduction de contrôle validée

Interprétez uniquement les textes associés au groupe « [identifier] », à la lumière de la question analytique de l'utilisateur.

Construisez un profil textuel substantiel de ce groupe, sans décrire, comparer ou inférer le discours des autres groupes.

### Decision and scope

- This exact English/French wording was explicitly approved on 2026-10-15.
- The classic TEXTUAL workflow is local-first. `isolate.groups = FALSE` collects separate local prompts/results but does not authorize a global inter-group comparison or synthesis.
- `[identifier]` denotes the original group label substituted by R. The study introduction and user request remain preserved separately.
- A group without a non-empty text has no defensible textual profile; this remains a separate technical situation to handle within the existing output contract.
- No R runtime, parser or other output contract is modified.



## 4. Output

### 4.1 `nail_textual()` — APPROVED (bilingual operational wording, 2026-10-15)

**English — approved operational text**

Produce a concise, substantive and evidence-grounded qualitative profile of the group.

Use exactly the following fields and preserve their names and order:

Core textual profile:
One concise statement capturing the main configuration of meaning emerging from the discourse.

Dominant themes:
One to five concise themes, separated by semicolons.

Within-group coherence:
Choose exactly one: `strong` / `moderate` / `mixed` / `weak`, based on the qualitative organization of the discourse, not numerical recurrence alone.

Internal diversity:
One concise statement identifying meaningful variations, reservations, tensions or minority perspectives.

Representative text IDs:
One to three supplied text identifiers supporting the central interpretation, separated by semicolons.

Tension text IDs:
Zero to three supplied text identifiers illustrating tensions or contrasting perspectives, separated by semicolons, or `none`.

Do not add other fields or introductory text. Use only supplied text identifiers. Representative texts illustrate an interpretation; they do not establish the prevalence of a theme.

**Français — traduction de contrôle validée**

Produisez un profil qualitatif du groupe, concis, substantiel et fondé sur les observations textuelles.

Utilisez exactement les champs suivants, en conservant leurs noms et leur ordre :

Core textual profile :

Une formulation concise résumant la principale configuration de sens qui émerge du discours.

Dominant themes :

Un à cinq thèmes concis, séparés par des points-virgules.

Within-group coherence :

Choisissez exactement une valeur parmi `strong` / `moderate` / `mixed` / `weak`, selon l'organisation qualitative du discours, et non sur la seule récurrence numérique.

Internal diversity :

Une formulation concise décrivant les variations significatives, les réserves, les tensions ou les perspectives minoritaires.

Representative text IDs :

Un à trois identifiants de textes fournis, étayant l'interprétation centrale et séparés par des points-virgules.

Tension text IDs :

Zéro à trois identifiants de textes fournis illustrant les tensions ou les perspectives contrastées, séparés par des points-virgules, ou `none`.

N'ajoutez aucun autre champ ni texte introductif. Utilisez uniquement les identifiants fournis. Les textes représentatifs illustrent une interprétation ; ils ne permettent pas d'établir la prévalence d'un thème.

**Scientific and technical decisions**

- English wording and French control translation above were explicitly approved by the analyst on 2026-10-15.
- Keep exactly the six field labels recognized by `.parse_textual_profile_response()`; this approval is editorial only, not a parser modification.
- Coherence is a qualitative assessment; technical values `strong`, `moderate`, `mixed`, `weak` remain unchanged. Insufficient evidence is conceptually distinct from `weak`, but `not assessable` is **not** introduced as a fifth value without separate parser/contract approval.
- Output text-ID values must belong to the supplied textual evidence; representative observations are illustrative, not prevalence measurements.
- The no-text or sparse-text case remains a separate implementation/test concern; the approval does not authorize invented profiles or fabricated IDs.

### 4.2 `nail_textual_prep()` — APPROVED (bilingual operational wording, 2026-10-15)

**English — approved operational text**

Produce a concise, evidence-grounded textual profile that can be reused in a subsequent contextualized analysis.

Use exactly the following fields, preserving their names and order:

**Core textual profile:**

One short sentence capturing what mainly characterizes the group's discourse.

**Main themes:**

Three to five concise themes, separated by semicolons, when the texts support them. Do not invent themes to reach a specified number.

**Dominant concerns or motives:**

One to three concise expressions describing concerns or reasons supported by the texts. If these cannot be established, write `unclear`. Do not invent hidden motivations.

**Tone or stance:**

One short expression describing the stance conveyed by the texts, such as positive, negative, ambivalent, pragmatic or mixed.

**Intra-group consistency:**

Choose exactly one: `strong` / `moderate` / `mixed` / `weak`, based on the qualitative organization of the discourse.

**Injectable summary:**

One short, self-contained sentence synthesizing the group's textual profile for later interpretation alongside separate statistical evidence. Do not anticipate or invent statistical findings.

When verbatim cues are requested, also include:

**Central verbatim cues:**

One or two brief quotations or clearly identified paraphrases illustrating central themes, separated by semicolons.

**Tension verbatim cues:**

Up to two brief quotations or clearly identified paraphrases illustrating meaningful tensions, separated by semicolons, or `none`.

Do not add other fields or introductory text. Do not invent quotations or present isolated excerpts as evidence of group consensus.

**Français — traduction de contrôle validée**

Produisez un profil textuel concis, fondé sur les observations, pouvant être réutilisé dans une analyse contextualisée ultérieure.

Utilisez exactement les champs suivants, en conservant leurs noms et leur ordre :

**Core textual profile :**

Une phrase courte résumant ce qui caractérise principalement le discours du groupe.

**Main themes :**

Trois à cinq thèmes concis, séparés par des points-virgules, lorsque les textes permettent de les identifier. N'inventez pas de thèmes pour atteindre un nombre imposé.

**Dominant concerns or motives :**

Une à trois expressions concises décrivant des préoccupations ou des raisons étayées par les textes. Si elles ne peuvent pas être établies, indiquez `unclear`. N'inventez pas de motivations cachées.

**Tone or stance :**

Une expression courte décrivant la position exprimée dans les textes, par exemple positive, négative, ambivalente, pragmatique ou mixte.

**Intra-group consistency :**

Choisissez exactement une valeur parmi `strong` / `moderate` / `mixed` / `weak`, selon l'organisation qualitative du discours.

**Injectable summary :**

Une phrase courte et autonome synthétisant le profil textuel du groupe, destinée à une interprétation ultérieure aux côtés de résultats statistiques distincts. N'anticipez pas et n'inventez pas de résultats statistiques.

Lorsque des extraits textuels sont demandés, ajoutez également :

**Central verbatim cues :**

Une ou deux citations courtes ou paraphrases explicitement identifiées, illustrant les thèmes centraux, séparées par des points-virgules.

**Tension verbatim cues :**

Jusqu'à deux citations courtes ou paraphrases explicitement identifiées, illustrant des tensions significatives, séparées par des points-virgules, ou `none`.

N'ajoutez aucun autre champ ni texte introductif. N'inventez pas de citations et ne présentez pas des extraits isolés comme une preuve de consensus dans le groupe.

**Scientific and technical decisions**

- This complete bilingual output wording was explicitly approved by the analyst on 2026-10-15.
- Keep the six required parser field labels `Core textual profile`, `Main themes`, `Dominant concerns or motives`, `Tone or stance`, `Intra-group consistency`, `Injectable summary`; add `Central verbatim cues` and `Tension verbatim cues` only when `include_verbatims_in_prompt = TRUE`.
- The distinction between textual expressions, inferred themes, and a short reusable `Injectable summary` remains intact. No statistical finding should be invented or anticipated from the textual material.
- Generated verbatim cues can be short quotes or labeled paraphrases. They must not be mistaken for the mechanically selected, source-row-linked verbatims attached separately by the `nail_textual_prep()` post-processing workflow.
- `Intra-group consistency` retains the four existing values; no fifth category is introduced. When data are empty or too sparse, technical representation and validation require separate operational tests.
- This agreement does not modify the executed R prompts, output parsers or downstream evidence and attachment contracts.


## Implementation boundary

No R source code, evidence registry, interpretation selection, prompts run at execution, output parsers or tests have been changed. When approved wording is eventually integrated, validate the `TXT%06d` evidence IDs, group-local behavior, sparse/empty groups, duplicate responses, text-role semantics, selection provenance and both downstream output contracts on realistic end-to-end examples.
