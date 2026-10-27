# NaileR examples style guide

This guide defines the presentation standard for package help and operational
examples. It applies to the main analytical workflows; `nail_sort()` is a
deferred, low-priority exception and is not being rewritten in this pass.

## 1. Scientific context

Every applied example should state, in concise English:

- what was collected or measured;
- the observational unit;
- whether groups, scores or axes are observed or constructed;
- the scientific question addressed by the example.

The context must not introduce facts absent from the data documentation.

## 2. Data preparation

Use package data through the public path whenever possible:

```r
data(dataset_name, package = "NaileR")
```

Use the source package explicitly for external datasets. Prepare only the
variables required by the function and prefer named columns or documented
ranges over unexplained numeric indices. Preserve real plans: do not create a
`Session` factor when the study has no sessions.

## 3. Analytical question

Use explicit objects for non-trivial context and requests:

```r
introduction <- "..."
request <- "..."
```

The request must say what the evidence can support. It must distinguish
observations, declared opinions, constructed groups, textual material and
interpretations. It must not request causal mechanisms, preferences,
normative scores or unobserved behaviour without a documented basis.

## 4. Offline preview

Ordinary help examples must use `generate = FALSE`. They must not contact
Ollama, Gemini or another provider. A generation example belongs in
`\\dontrun{}` and must make the provider and optional nature of the call
explicit.

## 5. Evidence and prompt inspection

Examples should expose the canonical inspection route:

```r
evidence <- nail_evidence(result)
prompt <- nail_prompt(result, print = FALSE)
```

Use `nail_response()` only for an object that was actually generated. Do not
assume that CATDES, CONDES, DESCFREQ, QDA and TEXTUAL evidence have the same
substructure; use the accessor output appropriate to the workflow.

## 6. Optional generation

Keep generation separate from the deterministic preview. Generation examples
must be opt-in, preserve the exact prompt and parameters used, and never embed
API keys or private responses. The documentation should state that a structured
parse is a technical result, not a scientific validation of the interpretation.

## 7. Workflow-specific conventions

### CATDES and CATDES preparation

Show both direct `nail_catdes(dataset = ..., num.var = ...)` and one advanced
`nail_catdes_prep()` reuse route. Preserve `standard` versus `latent`, and
explain that constructed group identifiers are not automatically substantive
names.

### CONDES

State whether the target is observed or a constructed score/dimension. For
ACM, PCA or CA-derived axes, describe associations as descriptive
characterisations of the displayed geometry, not independent validation tests.
Mention that factor-axis signs are arbitrary when relevant.

### DESCFREQ

Distinguish `description` of row profiles from `comparison` of several row
profiles. Absence of a retained marker is not evidence of absence, equality or
similarity. Preserve the historical Beards and Children objectives and the
deterministic Rorschach coding rule.

### QDA and QDA-space

Use real sensory plans and preserve product, panelist and session structure.
Explain that HIGHER/LOWER are relative to the product mean when applicable.
Do not invent sensory meanings for unresolved labels. For QDA-space, separate
PCA geometry, CONDES associations and QDA product markers.

### TEXTUAL

Document `sample.pct`, `seed`, stable `TXT%06d` identifiers, response coverage
and the local-first architecture. A set of local group prompts is not a joint
statistical comparison. Keep corrected Distinction translations separate from
historical translation artefacts.

### TEXTUAL preparation and contextualisation

Describe preparation helpers as specialised or compatibility workflows when
that is their actual contract. Do not promise the full canonical accessor
contract if a helper returns a preparation-specific list.

### CATDES-TEXTUAL

Keep the deterministic composition fixture because it tests the composition
contract without a provider. Label the textual profiles as constructed or
expert-reviewed when they are not observed LLM outputs. Keep authoritative
CATDES evidence distinct from narrative text evidence.

### SORT

The historical `nail_sort()` example remains a low-priority `\\dontrun{}`
example. It is not required to conform artificially to the canonical evidence
accessor pattern until a dedicated maintenance task is approved.

## 8. Language and reproducibility

Use English for comments, introductions, requests, README material and help
headings. Preserve source variable names when they are part of reproducibility
and never invent translations for unresolved scientific labels.

Examples should run from an installed package and should not depend on
`/private/tmp`, user-specific paths, validation RDS files or untracked local
files.

## 9. Validation checklist

For each example family, check:

- dataset exists and has the documented structure;
- every referenced variable and factor level exists;
- the formula matches the actual experimental design;
- `generate = FALSE` produces a usable preview;
- `nail_evidence()` and `nail_prompt()` work;
- `nail_response()` is used only after generation;
- no automatic example contacts a provider;
- the example works after package installation;
- the statistical question and the interpretation request agree;
- no historical example was dropped without a recorded decision.

The audit matrix in `EXAMPLES_AUDIT.md` is the source for tracking these
checks. No code or data change is justified solely by a stylistic mismatch;
API or scientific inconsistencies must be reported separately.
