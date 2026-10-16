# NaileR scientific benchmark v1

This directory contains the first offline prompt-and-evidence fixture set for
the seven-workflow NaileR scientific validation campaign. It was generated
from commit `f697f006e04faa8f9613885ec40cd37799bd7282` on branch
`validation-seven-functions-prompts-20261016`.

## Scope

The preparation phase executes NaileR with `generate = FALSE` only. It makes
no Ollama, Gemini, OpenAI, or other LLM request. The six directly previewable
analyses are:

- `nail_condes()` on consumer satisfaction;
- `nail_catdes()` on the three consumer groups;
- `nail_descfreq()` on group-by-channel frequencies;
- `nail_textual()` on individual comments;
- `nail_qda()` on `SensoMineR::sensochoc`;
- `nail_qda_space()` on the prepared QDA object, with `ncp = 1`.

`nail_catdes_textual()` is explicitly deferred in this prompt-only phase.
Its public contract requires a `nail_textual(generate = TRUE)` result with
successfully parsed textual profiles. Introducing a mock response would not
be an exact preview of the public offline workflow, so no fabricated
composition prompt is published here.

The seven-workflow campaign can therefore reuse the six upstream prompt
families here and add the composition only after ChatGPT supplies genuine
TEXTUAL interpretations for reinjection.

## Studies

`study_consumer/` contains a reproducible synthetic study of 96 consumers in
neutral groups `G1`, `G2`, and `G3`. Quantitative, qualitative, and open-text
data share the stable respondent identifiers `C001`--`C096`. The open
comments include recurrent themes, minority positions, qualifications, and
contradictions. The data-generation mechanism is documented separately and
is not stated to the LLM as an observed result.

`study_sensory/` uses the documented `SensoMineR::sensochoc` example. QDA is
run in portfolio mode and QDA-space is restricted to one retained axis. The
axis has selected CONDES associations in the current installed dependency
versions; the complete evidence remains in the corresponding RDS and JSON
artifacts.

## Files

- `MANIFEST.csv` inventories every exact prompt, its evidence file, SHA-256
  digest, main scientific arguments, and the number of calls that would be
  required with `generate = TRUE`.
- `prompts/` contains the exact UTF-8 prompt strings returned by
  `nail_prompt(..., print = FALSE)`, written without added headings or
  separators.
- `evidence/` contains readable JSON projections of the canonical evidence.
- `objects/` contains the complete preview RDS objects for offline
  reinjection and inspection.
- `checks/` contains usage previews, alignment checks, and preparation status.
- `scripts/prepare_benchmark_v1.R` regenerates the fixture from this commit.

## Limits

The prompts are prepared for independent scientific reading, not scored in
this phase. A prompt being technically available does not establish that a
future LLM response will be statistically faithful. The benchmark must keep
statistical facts, interpretations, and hypotheses distinct. No personal
data or API key is included.
