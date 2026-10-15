# TEXTUAL — operational block assembly review

**Status:** SCIENTIFIC BLOCKS APPROVED; ASSEMBLY REVIEW OPEN (2026-10-15).
**Branch:** `dev-statistical-prompt-framework`.
**Source:** [TEXTUAL_MODULAR_PROMPT.md](TEXTUAL_MODULAR_PROMPT.md); [TEXTUAL_REFERENCE_PROMPT.md](TEXTUAL_REFERENCE_PROMPT.md) and the `R/nail_textual.R` / `R/nail_textual_semantic.R` runtime contract.

The English `reading`, `interpretation`, `local_task`, and two `output` blocks below reproduce their **approved wording**, with the single documented conditional omission of verbatim-cue instructions when `include_verbatims_in_prompt = FALSE`. The original study introduction, question and R-selected text evidence are represented by placeholders: the assembled text is a **scientific document for review, not the current executable prompt**. The existing route-specific output parsers and R sampling/registry logic remain authoritative. French control translations are preserved in the modular source.

## Routing and invariants

- Classic `nail_textual()`: one prompt per group, with a six-field structured output for `textual_profiles`. `isolate.groups = FALSE` combines local prompts/results, not a comparative or global LLM interpretation.
- `nail_textual_prep()`: calls `nail_textual()` locally with its own fixed introduction, preparatory request and parser; the generated output includes six required fields, with two optional verbatim-cue fields selected by `include_verbatims_in_prompt`.
- `attach_selected_verbatims` is a separate mechanical, post-generation choice; it must **not** be confused with generation of `Central verbatim cues` / `Tension verbatim cues` by an LLM.
- All cases retain original group labels and `TXT%06d` source-observation identifiers when source texts are provided.
- No generic prompt warning about texts omitted by `sample.pct`; the sample registry, coverage and seed remain recorded in R.
- `nail_textual_contextualized()` and statistical/textual fusion are intentionally out of scope.

## Three documentary configurations (two workflows)

### 1. Classic `nail_textual()`

```text
# Introduction

[Original analyst-provided study introduction — preserve the actual runtime content.]

---

## How to Read the Textual Evidence

The evidence consists of textual observations associated with one group. These texts are the empirical material for qualitative analysis. Themes and broader interpretations are constructed from the texts by the language model; they are not statistical results calculated beforehand.

Each text has an identifier linked to a source observation. An observation does not necessarily represent a distinct individual, and identical statements may occur more than once. Preserve the original wording and use the supplied text identifiers when referring to supporting or contrasting evidence. Do not invent quotations.

Interpret the meaning and strength of each statement carefully, preserving negations, hesitation, qualifications, ambiguity and contradictions. Distinguish expressed opinions, perceptions, intentions, reported experiences and observed behaviors.

Distinguish recurring ideas in the texts from the prevalence of opinions among individuals. Repetition does not necessarily imply independent agreement or group consensus. Do not invent numerical prevalence estimates.

Use the study context to understand the responses and the analytical question, without treating it as additional empirical evidence.

---

# Overall Analytical Request

[Original analyst-provided analytical request — preserve the actual runtime content.]

---

## Interpretation Rules

Identify the main themes expressed in the texts, grouping statements according to their meaning rather than shared vocabulary. Explain their substantive significance in relation to the analytical question.

Interpret the group's discourse by considering these themes jointly, rather than presenting them as a simple list. When supported by the texts, develop a higher-level interpretation that captures the broader concerns, perspectives or frames of meaning emerging from their combination.

Examine internal diversity, including differences in emphasis, reservations, ambivalence, contradictions and meaningful minority perspectives. A shared interpretive frame may accommodate different positions, while several distinct or conflicting frames may coexist within the same group.

Assess whether the discourse exhibits a recognizable common frame. Treat coherence as a qualitative interpretation, not a statistical measure. Do not impose unity when the texts support multiple perspectives or when the evidence is insufficient.

Adapt the depth of interpretation to the richness and diversity of the texts. Avoid elaborate group-level characterizations from sparse evidence. Do not infer hidden motives, personality traits, social identities or causal mechanisms that the texts do not support.

---

# Local Task

Interpret only the texts associated with group "[identifier]", in light of the user's analytical request.

Construct a substantive textual profile of this group without describing, comparing or inferring the discourse of other groups.

---

# Data

[Original group identifier, R-derived group/corpus information and the selected texts, with source-linked text IDs. No example data invented.]

---

# Required output

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
```

---

### 2. Preparation with verbatim cues (`include_verbatims_in_prompt = TRUE`)

```text
# Introduction

[Preparation route's fixed introductory text — preserve the actual runtime content.]

---

## How to Read the Textual Evidence

The evidence consists of textual observations associated with one group. These texts are the empirical material for qualitative analysis. Themes and broader interpretations are constructed from the texts by the language model; they are not statistical results calculated beforehand.

Each text has an identifier linked to a source observation. An observation does not necessarily represent a distinct individual, and identical statements may occur more than once. Preserve the original wording and use the supplied text identifiers when referring to supporting or contrasting evidence. Do not invent quotations.

Interpret the meaning and strength of each statement carefully, preserving negations, hesitation, qualifications, ambiguity and contradictions. Distinguish expressed opinions, perceptions, intentions, reported experiences and observed behaviors.

Distinguish recurring ideas in the texts from the prevalence of opinions among individuals. Repetition does not necessarily imply independent agreement or group consensus. Do not invent numerical prevalence estimates.

Use the study context to understand the responses and the analytical question, without treating it as additional empirical evidence.

---

# Overall Analytical Request

[Preparation route's fixed analytical request — preserve the actual runtime content.]

---

## Interpretation Rules

Identify the main themes expressed in the texts, grouping statements according to their meaning rather than shared vocabulary. Explain their substantive significance in relation to the analytical question.

Interpret the group's discourse by considering these themes jointly, rather than presenting them as a simple list. When supported by the texts, develop a higher-level interpretation that captures the broader concerns, perspectives or frames of meaning emerging from their combination.

Examine internal diversity, including differences in emphasis, reservations, ambivalence, contradictions and meaningful minority perspectives. A shared interpretive frame may accommodate different positions, while several distinct or conflicting frames may coexist within the same group.

Assess whether the discourse exhibits a recognizable common frame. Treat coherence as a qualitative interpretation, not a statistical measure. Do not impose unity when the texts support multiple perspectives or when the evidence is insufficient.

Adapt the depth of interpretation to the richness and diversity of the texts. Avoid elaborate group-level characterizations from sparse evidence. Do not infer hidden motives, personality traits, social identities or causal mechanisms that the texts do not support.

---

# Local Task

Interpret only the texts associated with group "[identifier]", in light of the user's analytical request.

Construct a substantive textual profile of this group without describing, comparing or inferring the discourse of other groups.

---

# Data

[Original group identifier, R-derived group/corpus information and the selected texts, with source-linked text IDs. No example data invented.]

---

# Required output

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
```

---

### 3. Preparation without verbatim cues (`include_verbatims_in_prompt = FALSE`)

```text
# Introduction

[Preparation route's fixed introductory text — preserve the actual runtime content.]

---

## How to Read the Textual Evidence

The evidence consists of textual observations associated with one group. These texts are the empirical material for qualitative analysis. Themes and broader interpretations are constructed from the texts by the language model; they are not statistical results calculated beforehand.

Each text has an identifier linked to a source observation. An observation does not necessarily represent a distinct individual, and identical statements may occur more than once. Preserve the original wording and use the supplied text identifiers when referring to supporting or contrasting evidence. Do not invent quotations.

Interpret the meaning and strength of each statement carefully, preserving negations, hesitation, qualifications, ambiguity and contradictions. Distinguish expressed opinions, perceptions, intentions, reported experiences and observed behaviors.

Distinguish recurring ideas in the texts from the prevalence of opinions among individuals. Repetition does not necessarily imply independent agreement or group consensus. Do not invent numerical prevalence estimates.

Use the study context to understand the responses and the analytical question, without treating it as additional empirical evidence.

---

# Overall Analytical Request

[Preparation route's fixed analytical request — preserve the actual runtime content.]

---

## Interpretation Rules

Identify the main themes expressed in the texts, grouping statements according to their meaning rather than shared vocabulary. Explain their substantive significance in relation to the analytical question.

Interpret the group's discourse by considering these themes jointly, rather than presenting them as a simple list. When supported by the texts, develop a higher-level interpretation that captures the broader concerns, perspectives or frames of meaning emerging from their combination.

Examine internal diversity, including differences in emphasis, reservations, ambivalence, contradictions and meaningful minority perspectives. A shared interpretive frame may accommodate different positions, while several distinct or conflicting frames may coexist within the same group.

Assess whether the discourse exhibits a recognizable common frame. Treat coherence as a qualitative interpretation, not a statistical measure. Do not impose unity when the texts support multiple perspectives or when the evidence is insufficient.

Adapt the depth of interpretation to the richness and diversity of the texts. Avoid elaborate group-level characterizations from sparse evidence. Do not infer hidden motives, personality traits, social identities or causal mechanisms that the texts do not support.

---

# Local Task

Interpret only the texts associated with group "[identifier]", in light of the user's analytical request.

Construct a substantive textual profile of this group without describing, comparing or inferring the discourse of other groups.

---

# Data

[Original group identifier, R-derived group/corpus information and the selected texts, with source-linked text IDs. No example data invented.]

---

# Required output

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

Do not add other fields or introductory text. Do not invent quotations or present isolated excerpts as evidence of group consensus.
```

## Cross-block audit — findings and recommendations (NOT YET APPROVED)

1. **No hard scientific contradiction detected in the approved wording.** `reading` establishes the source-observation and epistemic rules; `interpretation` constructs themes, higher-level frames, internal diversity and non-statistical coherence; `local_task` delimits the group; and each `output` specifies a distinct downstream structure.
2. **Purposeful overlap:** `reading` warns against inferring consensus from recurrence; classic `output` repeats that representative quotations are not prevalence evidence. Keep this short safeguard until realistic LLM tests determine whether it is redundant.
3. **Purposeful overlap:** `interpretation` emphasizes grounded themes and nuance; both outputs also constrain interpretation. Avoid adding further repeated imperatives at integration; assess final prompt length with a small local model.
4. **Two field contracts must remain distinct:** classic labels are `Core textual profile`, `Dominant themes`, `Within-group coherence`, `Internal diversity`, `Representative text IDs`, `Tension text IDs`. Prep labels are `Core textual profile`, `Main themes`, `Dominant concerns or motives`, `Tone or stance`, `Intra-group consistency`, `Injectable summary`, plus optional `Central verbatim cues` and `Tension verbatim cues`.
5. **Current runtime duplication:** `build_request_textual_prep()` already includes both interpretation rules and an output schema; `build_conclusion_textual_prep()` repeats field names in a second formatting instruction. The new editorial `output` must replace or reconcile these eventually, **not** be blindly appended on top of both. Do not change R until a dedicated implementation pass.
6. **Sparse/empty evidence requires testing:** both outputs demand one of four coherence categories, while scientific logic distinguishes an unassessable state from `weak`. `not assessable` is NOT an allowed parser category; retain existing behavior and flag this for a separately approved contract decision.
7. **Prep 3–5 themes are conditional:** “when the texts support them” and “Do not invent themes to reach a specified number” prevent forced fabrication in sparse corpora. Test that the parser accepts fewer themes and handles no-text groups without treating malformed responses as valid profiles.
8. **Cue provenance:** LLM-generated quoted or paraphrased cues should not be treated as independently source-ID-verified extracts. Mechanically selected verbatims are a separate R-attached source of traceable excerpts; verify the exact downstream accessors and provenance.
9. **Contextual interpretation boundary:** the prep `Injectable summary` describes the group's text-supported qualitative profile only; neither causal explanations nor statistical descriptors may be smuggled into it from general expectations.
10. **Rendering detail:** the approved documentation shows some field labels in Markdown bold, but the existing parsers are keyed to literal field names. Preserve parser-compatible labels and order when implementing; test with both `prompt_style` values and `include_verbatims_in_prompt` TRUE/FALSE.

## Review conclusion

Both scientific workflows are articulated without a major semantic conflict. Do **not** silently amend previously approved blocks. Next steps: review these three assemblies with the analyst, decide whether to keep deliberate overlap and how to deal with known sparse/no-text limitations, and then perform local end-to-end model/parser tests during the future R integration phase. This document is only an editorial assembly and audit, not evidence of operational equivalence or a release-ready implementation.
