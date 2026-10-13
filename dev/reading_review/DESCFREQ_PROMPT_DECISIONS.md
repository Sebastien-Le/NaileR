# DESCFREQ prompt decisions

**Scope:** This journal records the scientific decisions underlying the approved DESCFREQ V1 reference and the draft compact candidate. It does not modify package code, tests, documentation pages, readings, prompt builders, evidence, selection, parsers, or output contracts.

## Status vocabulary

- **VALIDATED:** adopted in the approved V1 reference.
- **OPEN:** explicitly unresolved; the compact draft is not a validated answer.
- **DRAFT COVERAGE:** describes what the compact candidate attempts to retain, not a validation result.

## Decision log

### D1 — Statistical object

- **Initial problem:** DESCFREQ could be read as a generic label-generation task rather than a contingency-table profile analysis.
- **Risk:** The row/global reference structure is lost.
- **Recommendations:** Define rows, counted attributes, row profiles, and deviations from the whole-table profile.
- **Decision:** DESCFREQ characterizes rows of a contingency table through frequency profiles and statistical deviations from the global table profile.
- **Justification:** This is the object produced by `FactoMineR::descfreq()` and preserved by NaileR.
- **Reference section:** Introduction; How to Read the Statistical Evidence.
- **Code consequence:** None in this PASS; preserve the canonical object.
- **Status:** VALIDATED.

### D2 — Denominators

- **Initial problem:** Row and global percentages can be conflated.
- **Risk:** A row composition is mistaken for an attribute's distribution across rows.
- **Recommendations:** State both denominators and retain row/global percentages.
- **Decision:** `row profile = n_ij / n_i+`; `global profile = n_+j / n_++`; directions are relative to the whole-table profile.
- **Justification:** The two quantities answer different questions.
- **Reference section:** Understanding row profiles.
- **Code consequence:** Preserve row/global percentages and counts in semantic-facing evidence.
- **Status:** VALIDATED.

### D3 — Overrepresentation is not majority

- **Initial problem:** OVERREPRESENTED can be read as dominant or majority.
- **Risk:** Relative distinctiveness becomes an absolute claim.
- **Recommendations:** Pair direction with percentages and counts; state that a positive deviation may remain a minority.
- **Decision:** Overrepresentation means a statistically higher row profile than the global profile, not majority, dominance, or highest absolute frequency.
- **Justification:** Statistical direction and absolute composition are distinct.
- **Reference section:** Understanding statistical directions.
- **Code consequence:** No calculation change.
- **Status:** VALIDATED.

### D4 — Occurrences and individuals

- **Initial problem:** Contingency counts may be interpreted as counts of distinct respondents.
- **Risk:** Percentages become unsupported person-level claims.
- **Recommendations:** Explain that entries describe occurrences unless the study design guarantees an individual interpretation.
- **Decision:** Frequencies are not automatically percentages or counts of distinct individuals.
- **Justification:** The same table structure can encode repeated or aggregated occurrences.
- **Reference section:** Understanding row profiles; Meaning of attributes and context.
- **Code consequence:** None.
- **Status:** VALIDATED.

### D5 — Statistical significance and substantive importance

- **Initial problem:** p-values, v-tests, rarity, or relative deviation can be treated as substantive importance.
- **Risk:** Statistical support is mistaken for meaning or centrality.
- **Recommendations:** Separate evidence strength, frequency, rarity, and substantive interpretation.
- **Decision:** None of these quantities alone determines substantive importance.
- **Justification:** Statistical and interpretive roles are different.
- **Reference section:** Statistical evidence and substantive importance.
- **Code consequence:** Preserve audit fields without automatic semantic ranking.
- **Status:** VALIDATED.

### D6 — Evidence selection

- **Initial problem:** Prompt-visible evidence can be confused with the complete statistical result.
- **Risk:** Omitted markers are treated as absent or irrelevant.
- **Recommendations:** Document `proba`, `sample.pct`, ranking, displayed subset, and canonical invariance.
- **Decision:** Selection controls what is transmitted to the LLM; it does not alter canonical statistical profiles.
- **Justification:** NaileR separates `frequency_profiles` from selected interpretation evidence.
- **Reference section:** Understanding partial evidence; Data.
- **Code consequence:** Preserve the current separation.
- **Status:** VALIDATED.

### D7 — `drop.negative`

- **Initial problem:** Excluding underrepresented markers can look like statistical deletion.
- **Risk:** A positive-only prompt is mistaken for a complete profile.
- **Recommendations:** State that the option changes prompt selection only and can create a partial characterization.
- **Decision:** `drop.negative = TRUE` may emphasize positive deviations while underrepresented markers remain canonical.
- **Justification:** This is the current selection behavior.
- **Reference section:** Understanding partial evidence.
- **Code consequence:** None.
- **Status:** VALIDATED.

### D8 — Parsimony

- **Initial problem:** A model may construct a broad identity from one displayed marker.
- **Risk:** Interpretive specificity exceeds evidence availability.
- **Recommendations:** Calibrate claims to the number and diversity of displayed facts.
- **Decision:** One marker can support a relative singularity but generally not a multidimensional profile.
- **Justification:** The prompt cannot synthesize evidence it does not receive.
- **Reference section:** Understanding partial evidence; Interpretation Rules 4.
- **Code consequence:** None in this PASS.
- **Status:** VALIDATED.

### D9 — Rare attributes

- **Initial problem:** Rare markers may be ignored or allowed to dominate a name.
- **Risk:** Distinctive information is lost, or a sparse signal becomes a general identity.
- **Recommendations:** Inspect counts and percentages; retain possible distinctiveness; require convergent support for broad claims.
- **Decision:** Rare attributes may inform interpretation but must not define an extensive profile alone.
- **Justification:** Rarity and distinctiveness are not the same as dominance.
- **Reference section:** Statistical evidence and substantive importance; Interpretation Rules 5.
- **Code consequence:** Preserve the current name micro-calibration.
- **Status:** VALIDATED.

### D10 — Semantic synthesis

- **Initial problem:** Evidence-first can collapse into evidence-only paraphrase.
- **Risk:** Useful higher-level interpretation is prohibited, or synthesis is presented as measured fact.
- **Recommendations:** Permit synthesis of several displayed facts with traceability and explicit epistemic status.
- **Decision:** A higher-level substantive interpretation is encouraged when supported by several attributes and presented as interpretation.
- **Justification:** A new semantic concept need not be a new empirical fact.
- **Reference section:** Interpretation Rules 2; Final Interpretation Requirements.
- **Code consequence:** No evidence change.
- **Status:** VALIDATED.

### D11 — Exceptions and heterogeneity

- **Initial problem:** A single coherent narrative can erase contradictions.
- **Risk:** Heterogeneous profiles become artificially uniform.
- **Recommendations:** Preserve exceptions, tensions, and qualifying attributes.
- **Decision:** Do not force every displayed fact into one narrative.
- **Justification:** A profile can be interpretable while remaining heterogeneous.
- **Reference section:** Interpretation Rules 3.
- **Code consequence:** None.
- **Status:** VALIDATED.

### D12 — Row identity

- **Initial problem:** A descriptive name can replace the observed row identifier.
- **Risk:** The output changes the identity of the analyzed row.
- **Recommendations:** Preserve original identifiers and labels; allow names only as supplements.
- **Decision:** Original identifiers and user labels are never silently replaced.
- **Justification:** Identity is part of the data and output contract.
- **Reference section:** Row Identity and Scope Rules — Row identity.
- **Code consequence:** Keep `explicit_row_labels` behavior.
- **Status:** VALIDATED.

### D13 — Local scope

- **Initial problem:** A local prompt can import facts from undisplayed rows.
- **Risk:** The answer no longer describes only the selected row.
- **Recommendations:** State local scope explicitly.
- **Decision:** A local prompt characterizes only the displayed row.
- **Justification:** `isolate.groups = TRUE` produces one prompt per row.
- **Reference section:** LOCAL TASK — One displayed row.
- **Code consequence:** Preserve local prompt construction.
- **Status:** VALIDATED.

### D14 — Joint description and comparison

- **Initial problem:** Describing several rows and comparing them are not the same task.
- **Risk:** A description invents contrasts, or a comparison is treated as a pairwise test.
- **Recommendations:** Keep route/task instructions distinct.
- **Decision:** Joint description characterizes each displayed row; joint comparison describes supported contrasts from deviations from the global profile.
- **Justification:** The current API exposes `interpretation_mode` for these joint tasks.
- **Reference section:** JOINT DESCRIPTION TASK; JOINT COMPARISON TASK.
- **Code consequence:** Preserve current route distinctions.
- **Status:** VALIDATED.

### D15 — No automatic pairwise tests

- **Initial problem:** Different deviations from the global profile can be called a significant difference between rows.
- **Risk:** An unperformed pairwise test is reported.
- **Recommendations:** Permit descriptive contrasts but prohibit pairwise significance claims.
- **Decision:** Deviations from the global profile do not automatically constitute pairwise tests.
- **Justification:** The reported reference is the whole table, not a row-to-row test.
- **Reference section:** Interpretation Rules 6; JOINT COMPARISON TASK.
- **Code consequence:** None.
- **Status:** VALIDATED.

### D16 — Order and gradients

- **Initial problem:** Row order can be mistaken for a statistical progression.
- **Risk:** A gradient, transition, hierarchy, or temporal trend is invented.
- **Recommendations:** Treat order as context and require displayed evidence plus study context.
- **Decision:** Order alone is insufficient; a gradient is permitted only when context and evidence justify it.
- **Justification:** Ordering is contextual information, not a statistical result.
- **Reference section:** JOINT COMPARISON TASK.
- **Code consequence:** Preserve `rows_are_ordered` as contextual metadata.
- **Status:** VALIDATED.

### D17 — Context and request

- **Initial problem:** Generated instructions can overwrite the analyst's introduction or request.
- **Risk:** The analytical question changes silently or context becomes pseudo-evidence.
- **Recommendations:** Preserve user text verbatim and distinguish context from statistical evidence.
- **Decision:** Introduction and request remain identifiable and preserved; context helps meaning but is not statistical evidence.
- **Justification:** User intent and statistical evidence have different roles.
- **Reference section:** Introduction; Analytical Request; Meaning of attributes and context; Final Interpretation Requirements.
- **Code consequence:** No change.
- **Status:** VALIDATED.

### D18 — `v.test` and `p.value` exposure

- **Initial problem:** It is unclear whether technical significance fields should always be placed in semantic-facing evidence.
- **Risk:** Technical quantities may be overinterpreted, or useful audit information may be hidden.
- **Recommendations:** Keep them in canonical/audit objects; decide separately whether semantic exposure improves interpretation.
- **Decision:** V1 defines their meaning conditionally when supplied, but systematic exposure in semantic-facing evidence remains open.
- **Justification:** The current implementation deliberately keeps them out of semantic-facing text while retaining them canonically.
- **Reference section:** Statistical evidence and substantive importance; Data.
- **Code consequence:** No change authorized.
- **Status:** OPEN.

### D19 — Row margins

- **Initial problem:** Explicit row totals could help calibrate percentages and sparse evidence.
- **Risk:** Adding them could alter evidence presentation and prompt behavior.
- **Recommendations:** Assess their scientific value separately from the current contract.
- **Decision:** Their value is recognized, but adding row/overall margins to presented evidence is a future presentation change, not part of this PASS.
- **Justification:** No evidence-presentation modification is authorized here.
- **Reference section:** Data.
- **Code consequence:** None in this PASS.
- **Status:** OPEN.

### D20 — Long reference and compact candidate

- **Initial problem:** A shorter prompt may silently become the new doctrine.
- **Risk:** Condensation losses are mistaken for validated methodological improvements.
- **Recommendations:** Keep the long approved prompt as source of truth and validate the compact candidate separately.
- **Decision:** V1 is the approved reference; the compact prompt is a draft candidate requiring operational comparison before integration.
- **Justification:** Fewer words do not demonstrate equivalent scientific behavior.
- **Reference section:** Whole V1 specification; compact document.
- **Code consequence:** No integration in this PASS.
- **Status:** VALIDATED.

## Traceability matrix

| Decision | V1 section | Compact candidate coverage | Precision loss / open point | Operational verification needed | Status |
| --- | --- | --- | --- | --- | --- |
| D1 | Introduction; reading | Defines contingency rows/attributes | None intended | Check canonical row/attribute mapping | VALIDATED |
| D2 | Row profiles | Gives both formulas and denominators | Formula is compressed | Compare row/global percentages to canonical object | VALIDATED |
| D3 | Statistical directions | Explicitly says not majority/dominance | None intended | Test positive deviation with minority row percentage | VALIDATED |
| D4 | Row profiles; context | Says occurrences are not necessarily individuals | Study-design nuance is shorter | Review applied tables with repeated/aggregated counts | VALIDATED |
| D5 | Significance and importance | Separates evidence, rarity, frequency, importance | p/v conditional wording shortened | Compare interpretations with/without technical fields | VALIDATED |
| D6 | Partial evidence; Data | Mentions dynamic selection and selected subset | Exact ranking policy is placeholder | Verify `sample.pct`/selection combinations | VALIDATED |
| D7 | Partial evidence | States positive-only emphasis and canonical invariance | No new loss identified | Compare `drop.negative` TRUE/FALSE | VALIDATED |
| D8 | Partial evidence; Interpretation 4 | Calibrates specificity to evidence quantity | No new loss identified | Cases A/C and sparse custom inputs | VALIDATED |
| D9 | Importance; Interpretation 5 | Handles rare signals and name limits | Count-based nuance is compressed | Rare-marker naming evaluation | VALIDATED |
| D10 | Interpretation 2; final | Allows traceable synthesis | No new loss intended | Blind substantive-interpretation comparison | VALIDATED |
| D11 | Interpretation 3 | Preserves exceptions/heterogeneity | No new loss intended | Mixed/contradictory profiles | VALIDATED |
| D12 | Row identity | Preserves identifiers and labels | None intended | Explicit labels and local prompts | VALIDATED |
| D13 | Local task | Local scope placeholder | Route substitution remains to validate | Local prompt inspection | VALIDATED |
| D14 | Joint tasks | Separates description/comparison placeholders | Exact builder wording differs by route | Joint description/comparison cases | VALIDATED |
| D15 | Interpretation 6; comparison | Rejects unreported pairwise tests | None intended | Review comparison outputs | VALIDATED |
| D16 | Comparison | Rejects order-only gradient | Ordered-context nuance is compressed | Ordered and unordered rows | VALIDATED |
| D17 | Introduction/request/context | Preserves original texts and role | No new loss intended | Exact string-invariance check | VALIDATED |
| D18 | Significance; Data | Conditional technical-field mention | Systematic exposure remains open | Decide only after separate evidence experiment | OPEN |
| D19 | Data | Does not require margins | Future presentation remains open | Assess margin addition independently | OPEN |
| D20 | V1 and compact status | Explicitly labels candidate draft | Equivalence not demonstrated | A/B operational validation | VALIDATED |

## Consequences and open work

No package consequence is authorized by this journal. The next methodological step is to compare the compact candidate with the currently executed DESCFREQ prompts under identical evidence, context, request, provider, model, and sampling, then evaluate grounding, interpretive lift, calibration, rare-attribute handling, and paraphrase tendency. Only after that comparison could an integration PASS be considered.
