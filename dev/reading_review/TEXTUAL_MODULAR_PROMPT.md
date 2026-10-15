# TEXTUAL modular prompt — bilingual scientific review

**Status:** IN PROGRESS — `reading` APPROVED (full bilingual wording, 2026-10-15). `interpretation`, local task and output blocks pending.
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

## 2. `interpretation` — PENDING

## 3. Local task — PENDING

The current classic TEXTUAL route is local-first: `isolate.groups = FALSE` combines local interpretations, not a global semantic comparison.

## 4. Output — PENDING

Preserve the structured `textual_profiles` contract of `nail_textual()` and the distinct preparatory reusable-summary contract of `nail_textual_prep()`. The exact output formatting must remain compatible with existing parsers.

## Implementation boundary

No R source code, evidence registry, interpretation selection, prompts run at execution, output parsers or tests have been changed. When approved wording is eventually integrated, validate the `TXT%06d` evidence IDs, group-local behavior, sparse/empty groups, duplicate responses, text-role semantics, selection provenance and both downstream output contracts on realistic end-to-end examples.
