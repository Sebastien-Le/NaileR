# CORE 5 / TEXTUAL — frozen classic assembly and implementation handoff

**Prepared:** 2026-10-16  
**Status:** **EXACT SCIENTIFIC TEXT VERIFIED — READY FOR TARGETED IMPLEMENTATION / OPERATIONAL REVIEW OPEN**. This is an implementation reference, **not** a claim that the overall assembled runtime has already been reviewed through R and actual LLM output.  
**Branch:** `dev-core5-textual-integration-20261016`; source HEAD before this document: `22cd988a4756d9ed064768e258669be3f6617ea2`.  
**Reference:** [`TEXTUAL_MODULAR_PROMPT.md`](reading_review/TEXTUAL_MODULAR_PROMPT.md) and [`TEXTUAL_ASSEMBLY_REVIEW.md`](reading_review/TEXTUAL_ASSEMBLY_REVIEW.md). See also [`CORE5_TEXTUAL_INTEGRATION_REVIEW.md`](CORE5_TEXTUAL_INTEGRATION_REVIEW.md).

## 1. Literal scientific freeze

The English texts of **all four** classic blocks (`reading`, `interpretation`, `local_task`, `output`) in the assembly below were programmatically compared for **exact substring equality** against their corresponding approved blocks in `TEXTUAL_MODULAR_PROMPT.md` on 2026-10-16. All four matched. The assembly's introduction, analytical request and R evidence are **placeholders**, not text to replace the analyst's actual input or statistical/textual records.

Therefore **do not edit, simplify, embellish or paraphrase the four approved English blocks during R integration**. Preserve the intended repetition between `reading` and `output`; the standalone assembly review remains open pending actual generated prompt and LLM inspection. Substituting the original group label for `[identifier]` is the sole authorized variable part of the approved local task.

### Classic assembled prompt — literal reference

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

## 2. Exact runtime mapping and compatibility boundary

| Rendered section | Current source | Integration requirement |
| --- | --- | --- |
| `# Introduction` | `nail_textual()` / `blocks$context` | Preserve the actual analyst `introduction` byte-for-byte when provided; keep a default if omitted. |
| `## How to Read the Textual Evidence` | `.build_textual_guide_blocks()` / `blocks$reading` | Replace the old semantic reading by the **approved `reading`**, verbatim. Do not add generic selected-vs-unseen-text instructions. |
| `# Overall Analytical Request` | `nail_textual()` / `blocks$question` | Preserve analyst `request` verbatim; do not append a second default global comparative task. |
| `## Interpretation Rules` | `.build_textual_guide_blocks()` / `blocks$interpretation` | Replace old semantic interpretation by the **approved `interpretation`**, verbatim. |
| `# Local Task` | `.build_textual_prompt_bundle()` / `blocks$local_task` | Insert approved `local_task`, replacing `[identifier]` with the **exact original group label**. Preserve existing **no-text exception** and no-generation status. |
| `# Data` | `.textual_group_data_block()` | Retain exact selected source texts, `TXT%06d` identifiers and local group identity; do not conflate multiple source observations with distinct individuals. Keep canonical coverage/provenance in R. |
| `# Required output` | `.textual_canonical_conclusion()` / `blocks$output` | Replace default classic output's wording by **approved classic six-field `output`**, verbatim. Keep `# Required output` as the renderer's outer heading, not a seventh field. Custom `conclusion` must remain unmodified. |

**Routing:** `isolate.groups = TRUE` means a named list of local prompts or results; `FALSE` means a combined *view* of independent local calls. **Never** generate an additional global comparison. Both display modes use local tasks and local source evidence.

**Historical API:** Keep existing formal argument positions and names (`sample.pct`, `seed`, `text_role`, `prompt_style`, `default_blocks`, `generate`, `isolate.groups` and `...`). Keep `default_blocks` opt-out/ablation behavior; custom introduction/request/conclusion are always retained.

**Style choice for this implementation:** The default `detailed` prompt must use all four approved literal blocks. The previously drafted compact scientific prompt is **NOT APPROVED**. Do not add alternate paraphrased scientific reading/interpretation for `compact`. The safe implementation is to reuse **the same approved reading/interpretation** in both public style settings; preserve `prompt_style` compatibility and any existing difference in automatically generated default requests. If this changes documented token savings or descriptions of `prompt_style`, update `R` roxygen + `man/nail_textual.Rd` and test the contract; do not remove the option. This implementation choice is provisional until the analyst approves the rendered prompts.

**TEXTUAL prep is outside the active CORE 5 development target:** `nail_textual_prep()` calls `nail_textual()` and intentionally supplies its own `introduction`, `request` and `conclusion` with a *different* preparatory output schema. Its shared reading will inherit changes, but the prep output must **not** be silently replaced by the six-field classic format. Do **not** change `build_request_textual_prep()`, `build_conclusion_textual_prep()`, `parse_textual_prep_response()` or generated/mechanically selected cue logic as part of this integration; run focused compatibility tests.

**Compatibility consumers:** Keep `textual_evidence`, `interpretation_input`, `textual_profiles`, `textual_prompt_blocks`, `local_prompts`, `llm_io`, `textual_data_summary` and all accessors. `nail_catdes_textual()` consumes the canonical profile fields and resolves text IDs; its development is frozen, but its current tests should not regress.

## 3. Nonnegotiable invariants

- Full `textual_evidence$text_registry` retains exact original source-row IDs, group, source row and registered text (with existing normalization); repeated identical texts have independent IDs.
- `interpretation_input` tracks selected texts, `sample.pct`, `seed`, group status and coverage; changes to prompt wording never change canonical evidence or the selected ID subset under the same settings.
- `generate = FALSE` never calls an LLM; `generate = TRUE` calls it only for ready groups. Empty groups are `no_texts`; all-empty input remains rejected by existing validation. No invented themes or IDs for empty groups.
- The classic six-field parser names and order remain unchanged; `Within-group coherence` only accepts `strong/moderate/mixed/weak`. Do not invent a fifth category `not assessable` or convert sparse evidence mechanically to `weak`.
- `Representative text IDs` and `Tension text IDs` refer only to the **selected texts shown to the model**. Preserve `parse_failed` on invented IDs; **do not mistake parser success for scientific accuracy**.
- The data are textual **observations**, not necessarily independent respondents. Duplicate phrases or their frequency are not respondent prevalence or group consensus. Interpretations must preserve negations, reported claims versus actual behavior, conditional statements and minority views.

## 4. Acceptance experiments (run locally in Codex, not yet done)

**Offline cases:** realistic multi-group dataset with repeated statements, explicit negation, conditional attitudes, a substantive minority view, competing thematic frames, one single-text group, and one group with no usable texts. Supplement with a NaileR packaged realistic corpus such as `fabric`; retain a simple deterministic fixture as well. Check `isolate.groups` TRUE/FALSE, `sample.pct` 1 and partial with fixed `seed`, `text_role` all values, `default_blocks` ablations, `prompt_style` detailed/compact, custom context/question/final requirements, `nail_prompt()`, `nail_evidence()`, and exact `TXT%06d` IDs.

**Real LLM:** Ollama `mistral-small3.2` on several groups (including heterogeneous and sparse groups) in local-first mode; inspect output fields, parser statuses, evidence-backed source IDs and raw responses. Run `isolate.groups = FALSE` at least once and check that the number of model calls still equals the number of nonempty groups, not one extra global call. Scientific review specifically evaluates false consensus, lost negations, minority/contradictory opinions, invented quotes, ungrounded social or psychological profiles, and coherence overconfidence.

**Prep regression only:** confirm `nail_textual_prep()` with `include_verbatims_in_prompt` TRUE and FALSE still receives its distinct output schema, and generated fields parse through the prep parser; ensure mechanically attached source-linked verbatims are not conflated with model-generated `Central/Tension verbatim cues`.

**Tests/check and handoff:** `devtools::load_all()`, `devtools::test_active_file("tests/testthat/test-textual-semantic-rebuild.R")` and other relevant prep/compatibility tests, `devtools::test()`, `git diff --check`, `devtools::check(document = FALSE)` if local permissions allow, and explicit environmental error log otherwise. Do not call deprecated `devtools::test_file()`. Record the exact model, calls, prompts, raw text, IDs, parsed output and an expert assessment of interpretive quality.

**Version control:** No R edit, commit or push has been performed by this specification itself. Codex should integrate in a dedicated worktree and **stop for analyst review before committing/pushing**; stage neither generated `Rplots.pdf` nor local operational archives. Integrate upstream only after final technical/scientific acceptance.
