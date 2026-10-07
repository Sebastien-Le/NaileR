# NaileR TEXTUAL modular prompt blocks PoC

## Baseline

- Source branch: `dev-modular-prompt-blocks-poc`
- Source commit: `e47377ce1f85b39d0dac505758b3c1f3cf31d352`
- PoC branch: `dev-textual-prompt-blocks-poc`

This PoC concerns only the modern semantic path of `nail_textual()`. It does
not modify QDA, `nail_textual_prep()`, or
`nail_textual_contextualized()`.

## Architecture

Each local group prompt is represented internally as the following ordered
seven-block list:

```text
context
reading
question
interpretation
local_task
evidence
output
```

The representation is stored in `attr(x, "textual_prompt_blocks")`, as a
named list by group. Disabled optional blocks are represented by `NULL`.
The `reusable` block is intentionally absent: TEXTUAL's structured output
contract remains part of `output`, where it is already parsed into
`textual_profiles` for downstream use by `nail_catdes_textual()`.

The renderer emits:

```text
# Introduction
## How to Read the Textual Evidence
# Overall Analytical Request
## Interpretation Rules
# Local Task
# Data
# Required output
```

The final output block is preserved verbatim. In particular, the canonical
`# Required output` heading is not added a second time.

## Full prompt

This exact prompt uses the existing two-group test fixture, group `A`,
`sample.pct = 1`, and:

```r
default_blocks = c("reading", "interpretation", "local_task")
```

```text
# Introduction

The study examines how respondents discuss lower-flying travel choices.

---

## How to Read the Textual Evidence

The evidence below consists of raw responses.
Each displayed text has a mechanically assigned ID that refers to an exact observation.
Do not assume that a statistical or observed group necessarily has a homogeneous discourse.
Do not treat the absence of a theme as evidence that the group rejects or ignores it.
Representative and tension texts must be referenced only by supplied text IDs.

---

# Overall Analytical Request

Identify recurring frames while preserving internal diversity and distinguish interpretation from literal respondent expression.

---

## Interpretation Rules

Base the interpretation on recurring patterns across several texts.
A shared discourse may consist of a common interpretive frame even when positions vary within that frame.
When several texts or themes support the same pattern, you may offer a higher-level contextual interpretation.
Distinguish that interpretation from what respondents literally expressed, and do not present it as a direct quotation or empirical fact stated by them.
Do not infer hidden motives, personality traits, or moral qualities.

---

# Local Task

Interpret only the group shown below. Do not compare it with groups whose texts are not shown. Address the overall analytical request while respecting the evidence rules.

---

# Data

## Group "A"

### Corpus information

- Individuals/observations in group: 4
- Non-empty textual responses: 3
- Response coverage: 75.0%
- Distinct textual responses: 3
- Texts shown for this interpretation: 3 of 3 (100.0%)

### Texts

[TXT000001] I value travel but would reduce flights when alternatives are practical.

[TXT000002] Train travel is preferable when time and cost allow it.

[TXT000003] Family abroad makes complete avoidance of flying difficult.

---

# Required output

Your answer must contain exactly these fields and nothing else:

Core textual profile:
[One concise statement describing what mainly characterizes the discourse.]

Dominant themes:
[1 to 5 short themes separated by semicolons.]

Within-group coherence:
[Choose exactly one: strong / moderate / mixed / weak]

Internal diversity:
[One concise statement describing meaningful variations, tensions, minority positions, or the absence of clear internal diversity.]

Representative text IDs:
[1 to 3 supplied text IDs separated by semicolons.]

Tension text IDs:
[0 to 3 supplied text IDs separated by semicolons, or none.]
```

## Minimal prompt

This exact prompt uses the same data, context, request, selected texts, and
output, with:

```r
default_blocks = character(0)
```

```text
# Introduction

The study examines how respondents discuss lower-flying travel choices.

---

# Overall Analytical Request

Identify recurring frames while preserving internal diversity and distinguish interpretation from literal respondent expression.

---

# Data

## Group "A"

### Corpus information

- Individuals/observations in group: 4
- Non-empty textual responses: 3
- Response coverage: 75.0%
- Distinct textual responses: 3
- Texts shown for this interpretation: 3 of 3 (100.0%)

### Texts

[TXT000001] I value travel but would reduce flights when alternatives are practical.

[TXT000002] Train travel is preferable when time and cost allow it.

[TXT000003] Family abroad makes complete avoidance of flying difficult.

---

# Required output

Your answer must contain exactly these fields and nothing else:

Core textual profile:
[One concise statement describing what mainly characterizes the discourse.]

Dominant themes:
[1 to 5 short themes separated by semicolons.]

Within-group coherence:
[Choose exactly one: strong / moderate / mixed / weak]

Internal diversity:
[One concise statement describing meaningful variations, tensions, minority positions, or the absence of clear internal diversity.]

Representative text IDs:
[1 to 3 supplied text IDs separated by semicolons.]

Tension text IDs:
[0 to 3 supplied text IDs separated by semicolons, or none.]
```

## Invariance and downstream contract

For the same dataset, sampling, seed, context, request, and output:

- `textual_evidence` is identical between full and minimal prompts;
- `interpretation_input` is identical;
- selected text IDs are identical;
- `textual_data_summary` is identical;
- `nail_evidence()` returns identical canonical textual evidence;
- the evidence block contains only the selected texts for its own group;
- the parsed semantic fields in `textual_profiles` remain identical with the
  same mock response, while the stored prompt and backend result correctly
  retain their condition-specific values.

The open architectural question is that a custom `conclusion` is preserved
verbatim in `output`, but may not contain the canonical fields required by the
`textual_profiles` parser. This PoC deliberately preserves that existing
compatibility behavior rather than resolving it.
