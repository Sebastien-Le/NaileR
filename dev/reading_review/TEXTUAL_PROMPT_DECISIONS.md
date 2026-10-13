# TEXTUAL prompt decisions

## Status and scope

This is the methodological decision log for classic TEXTUAL only: `nail_textual()` and `nail_textual_prep()`. It accompanies the approved V1 reference and the non-approved compact candidate.

- V1 status: **APPROVED METHODOLOGICAL REFERENCE**.
- Compact status: **DRAFT — NOT APPROVED**.
- Scope excludes `nail_textual_contextualized()`, `nail_catdes_textual()`, statistical/textual composition and multiagent workflows.
- No decision below changes the current R implementation, parser, accessor, evidence object or output contract.

Each entry records the initial problem, scientific risk, recommendations considered, retained arbitration, justification, V1 location, future code consequence and status.

## D1 — Epistemic nature of TEXTUAL

- **Initial problem:** textual interpretation could be described as if R had calculated thematic statistics.
- **Scientific risk:** model-generated themes could be mistaken for measured frequencies or statistical results.
- **Recommendations discussed:** constrain the model to paraphrase; or define texts as empirical material and allow grounded qualitative construction.
- **Arbitration:** retain the second position. The LLM constructs themes, frames and coherence assessments from empirical texts; these are not precomputed statistics.
- **Justification:** this preserves interpretive lift without confusing interpretation with evidence.
- **V1 section:** *How to Read the Textual Evidence — Thematic interpretation*; *Higher-level interpretation*.
- **Future code consequence:** none for this PASS; any integration must preserve the evidence/interpretation distinction.
- **Status:** stabilized methodological decision.

## D2 — Textual units

- **Initial problem:** a text response may be treated as one respondent.
- **Scientific risk:** repeated observations or multiple responses from one person could be misread as independent individuals.
- **Recommendations discussed:** use respondent language by default; or distinguish observation, response and individual explicitly.
- **Arbitration:** distinguish observations, responses, occurrences, distinct formulations and individuals; never infer respondent uniqueness from a text row.
- **Justification:** the current registry is row-based and does not establish the data-generating design.
- **V1 section:** *How to Read the Textual Evidence — Textual units and traceability*; *Recurrence, prevalence, and importance*.
- **Future code consequence:** metrics and labels must not promise distinct-respondent counts.
- **Status:** stabilized methodological decision.

## D3 — Identifiers and traceability

- **Initial problem:** representative and tension evidence may lose its link to source text.
- **Scientific risk:** fabricated or unverifiable quotations and references.
- **Recommendations discussed:** allow free-text citations; or require mechanically supplied identifiers.
- **Arbitration:** preserve `TXT%06d` IDs and their source-row links; reference only supplied IDs.
- **Justification:** this is the strongest available audit trail without claiming respondent identity.
- **V1 section:** *Textual units and traceability*; *Preserve traceability*.
- **Future code consequence:** parser and preparation attachments must preserve or explicitly document any ID transformation.
- **Status:** stabilized methodological decision.

## D4 — Canonical corpus and selection

- **Initial problem:** the complete corpus and the texts shown to the model can be conflated.
- **Scientific risk:** sampling effects become invisible and canonical evidence can be mistaken for prompt-visible evidence.
- **Recommendations discussed:** treat the selected prompt text as the evidence object; or retain a canonical registry and a separate interpretation input.
- **Arbitration:** retain `textual_evidence` as the canonical registry and `interpretation_input` as the selected input.
- **Justification:** this matches the implemented provenance chain and makes sampling auditable.
- **V1 section:** *Corpus coverage and selection*; *Data*.
- **Future code consequence:** none now; future prompt integration must not collapse the two objects.
- **Status:** stabilized implementation/methodological contract.

## D5 — Sampling

- **Initial problem:** `sample.pct` may be read as changing the corpus itself.
- **Scientific risk:** selected texts could be treated as the full population or as an unbiased estimate.
- **Recommendations discussed:** hide sampling details; or expose selected coverage and `seed` explicitly.
- **Arbitration:** document that sampling controls displayed texts within groups, `seed` supports reproducibility, and canonical evidence remains invariant.
- **Justification:** it reflects the real implementation and limits claims about unshown material.
- **V1 section:** *Corpus coverage and selection*; *Data*.
- **Future code consequence:** integration must preserve selection metadata and RNG-preserving behavior.
- **Status:** stabilized methodological decision.

## D6 — Presence, absence and prevalence

- **Initial problem:** a theme shown in selected texts may be treated as prevalent, while an omitted theme may be treated as absent.
- **Scientific risk:** qualitative evidence is converted into unsupported population or group proportions.
- **Recommendations discussed:** infer prominence from repetition; or distinguish displayed presence, corpus prevalence and individual consensus.
- **Arbitration:** retain the distinction. Do not infer prevalence estimates or treat unshown themes as absent or rejected.
- **Justification:** the route has counts of occurrences and distinct texts, not a validated prevalence estimator.
- **V1 section:** *Corpus coverage and selection*; *Recurrence, prevalence, and importance*.
- **Future code consequence:** no new prevalence field or automatic weighting should be introduced without separate validation.
- **Status:** stabilized methodological decision.

## D7 — Duplicates

- **Initial problem:** identical texts may be collapsed as duplicates.
- **Scientific risk:** collapsing changes occurrence counts; retaining them can be misread as independent agreement.
- **Recommendations discussed:** deduplicate the canonical registry; or retain occurrences and qualify their interpretation.
- **Arbitration:** classic TEXTUAL retains identical non-empty texts as separate occurrences; repetition is not automatically consensus or independent confirmation.
- **Justification:** this preserves source-row provenance without overclaiming independence.
- **V1 section:** *Textual units and traceability*; *Recurrence, prevalence, and importance*.
- **Future code consequence:** preparation-route normalization must remain separate from canonical evidence.
- **Status:** stabilized for classic route; preparation processing remains route-specific.

## D8 — Linguistic fidelity

- **Initial problem:** paraphrase can flatten negations, litotes, hesitation or qualified endorsement.
- **Scientific risk:** acceptance becomes enthusiasm, reservation becomes rejection, or ambiguity becomes a false assertion.
- **Recommendations discussed:** normalize language for thematic extraction; or preserve meaning and strength before synthesis.
- **Arbitration:** preserve negations, double negations, litotes, conditions, hesitations, ambiguity, contradictions and intensity differences.
- **Justification:** interpretive synthesis is acceptable only if the source meaning remains recoverable.
- **V1 section:** *Literal meaning and nuanced expressions*.
- **Future code consequence:** no NLP normalization may alter canonical text content.
- **Status:** stabilized methodological decision.

## D9 — Theme construction

- **Initial problem:** related words may be grouped too quickly, or different concerns may be separated only by vocabulary.
- **Scientific risk:** thematic labels become lexical counts rather than meaningful qualitative categories.
- **Recommendations discussed:** keyword grouping; or semantic grouping that checks the concern, evaluation and interpretation expressed.
- **Arbitration:** organize recurring or substantively meaningful ideas while distinguishing similar vocabulary with different meanings.
- **Justification:** the decision allows synthesis without reducing the analysis to word frequency.
- **V1 section:** *Thematic interpretation*; *Identify the central thematic configuration*.
- **Future code consequence:** no automatic vocabulary-based theme object is implied.
- **Status:** stabilized methodological decision.

## D10 — Higher-level synthesis

- **Initial problem:** evidence-first can be misread as evidence-only paraphrase.
- **Scientific risk:** useful substantive interpretation is suppressed, or an abstract label is mistaken for a new empirical fact.
- **Recommendations discussed:** restrict the model to literal restatement; or allow conceptual synthesis with explicit interpretive status.
- **Arbitration:** permit a higher-level concern, perspective, experience or frame when several texts or themes support it, and distinguish it from literal respondent wording.
- **Justification:** a new semantic concept is allowed; a new unsupported empirical fact is not.
- **V1 section:** *Higher-level interpretation*; *Construct an evidence-grounded synthesis*.
- **Future code consequence:** future prompt integration must preserve the fact/interpretation/hypothesis distinction.
- **Status:** stabilized methodological decision.

## D11 — Limits of inference

- **Initial problem:** substantive language can drift into psychological, moral or causal explanation.
- **Scientific risk:** hidden motives, personality traits, social identities or causal mechanisms are invented.
- **Recommendations discussed:** allow broad contextual theorization; or limit broader claims to clearly marked and text-supported interpretations.
- **Arbitration:** prohibit unsupported motives, personality traits, moral qualities, social identities, psychological dispositions, causal mechanisms and unexpressed behaviors.
- **Justification:** contextual meaning may be constructed, but empirical claims require support in the displayed texts.
- **V1 section:** *Higher-level interpretation*; *Role of the study context*.
- **Future code consequence:** no new guardrail or output field is added in this PASS.
- **Status:** stabilized methodological decision.

## D12 — Diversity and tensions

- **Initial problem:** synthesis can erase disagreement and minority positions.
- **Scientific risk:** an artificially coherent group profile.
- **Recommendations discussed:** optimize for a single central profile; or explicitly retain tensions, contradictions, ambivalence and meaningful minorities.
- **Arbitration:** preserve internal diversity and distinguish variation within a frame from multiple frames.
- **Justification:** qualitative usefulness depends on representing both commonality and qualification.
- **V1 section:** *Internal diversity and tensions*; *Assess the common interpretive frame*.
- **Future code consequence:** current structured fields remain unchanged.
- **Status:** stabilized methodological decision.

## D13 — Qualitative coherence

- **Initial problem:** coherence labels may be treated as statistical measures.
- **Scientific risk:** `strong` or `weak` is interpreted as a calculated significance or reliability metric.
- **Recommendations discussed:** remove coherence labels; or define them as qualitative assessments of displayed discourse.
- **Arbitration:** retain `strong`, `moderate`, `mixed` and `weak` with their V1 meanings, explicitly non-statistical.
- **Justification:** these categories are part of the current parser/output contract and can be scientifically meaningful when qualified.
- **V1 section:** *Assess coherence cautiously*.
- **Future code consequence:** do not change allowed values in this PASS.
- **Status:** stabilized methodology; current categorical contract preserved.

## D14 — Coherence not assessable

- **Initial problem:** insufficient evidence can look like weak coherence.
- **Scientific risk:** sparse or absent data receives a substantive negative judgment.
- **Recommendations discussed:** add `not assessable` immediately; or define it conceptually while deferring any runtime value until parser validation.
- **Arbitration:** retain the concept `not assessable` in the reference, but do not add it to executed outputs or allowed parser values yet.
- **Justification:** the distinction is scientifically necessary, while the current parser contract must not be changed silently.
- **V1 section:** *Assess coherence cautiously*; *Evidence sufficiency*.
- **Future code consequence:** separate parser and end-to-end validation is required before any value is introduced.
- **Status:** methodological decision stabilized; implementation decision open.

## D15 — Sparse corpus

- **Initial problem:** one or two displayed texts can invite elaborate group-level theory.
- **Scientific risk:** unsupported consensus, multiple artificial themes or overconfident identity claims.
- **Recommendations discussed:** always produce the full structured profile; or make specificity proportional to evidence sufficiency.
- **Arbitration:** use cautious, limited interpretation for one or two texts and avoid elaborate group-level claims.
- **Justification:** evidence sufficiency is part of interpretation quality, not a reason to fabricate structure.
- **V1 section:** *Evidence sufficiency*.
- **Future code consequence:** no new threshold is introduced without operational validation.
- **Status:** stabilized methodological decision.

## D16 — Empty group

- **Initial problem:** a group can exist in the factor structure while having no non-empty text.
- **Scientific risk:** invented themes, coherence, quotations or IDs.
- **Recommendations discussed:** drop the group; or retain it with an explicit non-interpretable status.
- **Arbitration:** the reference forbids qualitative characterization of an empty group. The technical missing/empty representation remains open.
- **Justification:** the implementation currently preserves a `no_texts` state in its semantic artifacts, while output representation must remain compatible with the parser.
- **V1 section:** *Evidence sufficiency*; *Final Interpretation Requirements*.
- **Future code consequence:** validate any representation change separately; do not add fields or categorical values here.
- **Status:** scientific rule stabilized; technical representation open.

## D17 — Local scope

- **Initial problem:** several groups in one result can be mistaken for one comparative interpretation.
- **Scientific risk:** information from hidden groups leaks into a local prompt.
- **Recommendations discussed:** add an automatic comparison; or preserve strict group-local interpretation.
- **Arbitration:** each prompt interprets only the displayed group.
- **Justification:** this matches the prompt builder and protects provenance.
- **V1 section:** *Local Scope*.
- **Future code consequence:** no cross-group synthesis may be added implicitly.
- **Status:** stabilized methodological and implementation decision.

## D18 — No automatic global synthesis

- **Initial problem:** `isolate.groups = FALSE` can sound like a joint semantic analysis.
- **Scientific risk:** users assume the LLM has compared groups when it has received separate local prompts.
- **Recommendations discussed:** implement a global synthesis; or document the current local-first behavior.
- **Arbitration:** retain current behavior: prompts/results are combined locally, but `global_synthesis_performed` remains false.
- **Justification:** this PASS does not introduce a new comparison function or alter the architecture.
- **V1 section:** *Local Scope*.
- **Future code consequence:** any future global route needs a separate prompt and contract validation.
- **Status:** stabilized current behavior.

## D19 — Introduction and request

- **Initial problem:** generic runtime wording can replace the user's study context or analytical question.
- **Scientific risk:** the prompt answers a different question or treats context as observed evidence.
- **Recommendations discussed:** normalize user text into a house style; or preserve it verbatim within clearly separated contextual/question blocks.
- **Arbitration:** preserve the user's introduction and request; use introduction as context, not as an additional response.
- **Justification:** this respects user intent and the epistemic boundary.
- **V1 section:** *Role of the study context*; *Overall Analytical Request*.
- **Future code consequence:** no automatic lexical substitution or rewriting is authorized.
- **Status:** stabilized methodological decision.

## D20 — Contract of `nail_textual()`

- **Initial problem:** a new methodological prompt could silently change structured fields or traceability.
- **Scientific risk:** downstream parsing and accessors break.
- **Recommendations discussed:** adopt a richer output; or preserve the current structured group profile.
- **Arbitration:** retain core textual profile, dominant themes, within-group coherence, internal diversity, representative IDs and tension IDs.
- **Justification:** V1 must be compatible with the current route unless a later integration PASS validates a change.
- **V1 section:** *Final Interpretation Requirements*.
- **Future code consequence:** no output change in this PASS.
- **Status:** stabilized output contract.

## D21 — Contract of `nail_textual_prep()`

- **Initial problem:** preparation summaries and classic profiles can be conflated.
- **Scientific risk:** downstream contextualization receives the wrong fields or assumes identical semantics.
- **Recommendations discussed:** unify the outputs; or document the preparation route as distinct.
- **Arbitration:** preserve the short preparatory synthesis and reusable-output fields separately from the classic profile.
- **Justification:** the implementation parses a different contract and performs route-specific post-generation processing.
- **V1 section:** *Final Interpretation Requirements*; route-specific contract boundary.
- **Future code consequence:** no unification or parser refactor in this PASS.
- **Status:** stabilized methodological and implementation distinction.

## D22 — Traceability of preparation extracts

- **Initial problem:** `verbatim cues` and mechanically attached preparation verbatims may not retain the same registry-ID link.
- **Scientific risk:** a later contextual workflow treats an extract as fully traceable when its provenance is only text-based or mechanically reselected.
- **Recommendations discussed:** add IDs to the preparation parser; rebuild the preparation contract; or document the risk until separately validated.
- **Arbitration:** document the risk and leave the technical decision open. Do not change the parser or output now.
- **Justification:** the current PASS is documentary and the preparation route is distinct.
- **V1 section:** *Preserve traceability*; *Final Interpretation Requirements*.
- **Future code consequence:** future integration must validate ID preservation, selected verbatims, truncation and parser compatibility end-to-end.
- **Status:** open implementation hypothesis.

## D23 — Reference and compact versions

- **Initial problem:** a compact prompt can be mistaken for an approved equivalent of V1.
- **Scientific risk:** condensation may remove safeguards about units, sampling, nuance, sparse evidence or output contracts.
- **Recommendations discussed:** approve the compact by inspection; or label it as a candidate for controlled comparison.
- **Arbitration:** V1 is the approved reference. The compact is draft and not approved.
- **Justification:** behavioral equivalence can only be established by the future PASS 8 comparison.
- **V1 section:** entire reference; especially *How to Read the Textual Evidence* and *Final Interpretation Requirements*.
- **Future code consequence:** no `prompt_style` or provider-specific optimization is authorized here.
- **Status:** stabilized methodological decision; compact validation deferred.

## Traceability matrix

The matrix identifies where each decision appears in V1 and how the compact candidate represents it. It is a documentary mapping, not an equivalence claim.

| Decision | V1 section(s) | Compact formulation | Coverage | Condensation risk | Future validation |
| --- | --- | --- | --- | --- | --- |
| D1 | How to Read — epistemic object; Thematic interpretation | Introductory statement about empirical material and qualitative construction | explicit | medium | check fact/interpretation calibration |
| D2 | Textual units and traceability | observation/individual distinction | explicit | medium | test repeated-source scenarios |
| D3 | Textual units; Preserve traceability | mechanically assigned IDs and source links | explicit | low | verify parser IDs |
| D4 | Corpus coverage and selection; Data | canonical evidence/input separation | explicit | low | compare attributes and prompts |
| D5 | Corpus coverage and selection | sampling and seed limitations | explicit | medium | replicate sampling invariance |
| D6 | Corpus coverage; Recurrence/prevalence | no prevalence inference from displayed texts | explicit | high | sparse/sample cases |
| D7 | Recurrence, prevalence, importance | occurrence versus independent consensus | explicit | medium | exact duplicate corpus |
| D8 | Literal meaning and nuanced expressions | compact preservation sentence | explicit | high | negation/litote corpus |
| D9 | Thematic interpretation | semantic rather than lexical grouping | explicit | medium | theme-diversity review |
| D10 | Higher-level interpretation | grounded conceptual synthesis | explicit | medium | blind interpretive-lift review |
| D11 | Higher-level interpretation; Context | unsupported inference prohibitions | explicit | medium | overreach review |
| D12 | Internal diversity and tensions | tensions/minorities retained | explicit | medium | contradictory corpus |
| D13 | Assess coherence cautiously | four qualitative categories and non-statistical status | explicit | medium | parser/output check |
| D14 | Assess coherence; Evidence sufficiency | not-assessable caveat without new value | explicit | high | parser decision before integration |
| D15 | Evidence sufficiency | one/two-text caution | explicit | medium | sparse-group test |
| D16 | Evidence sufficiency; Final Requirements | empty-group prohibition | explicit | high | no-text route validation |
| D17 | Local Scope | local-only interpretation | explicit | low | hidden-group leakage test |
| D18 | Local Scope | no automatic global synthesis | explicit | medium | joint-route inspection |
| D19 | Context; Overall Request | preserved user texts and contextual role | explicit | medium | exact-string comparison |
| D20 | Final Requirements | classic structured fields | explicit | low | parser/accessor tests |
| D21 | Final Requirements; route boundary | distinct preparation contract | explicit | medium | preparation end-to-end test |
| D22 | Traceability; Final Requirements | risk is noted but not solved | partial/open | high | ID/attachment validation |
| D23 | Entire V1; output boundary | candidate labeled not approved | explicit | low | PASS 8 A/B comparison |

## Coverage and open points

All decisions D1–D23 are represented in the reference and mapped to the compact candidate. The compact deliberately compresses examples and explanations; the matrix identifies where that compression may weaken calibration. It must not be integrated or treated as equivalent before operational comparison.

Open implementation points are D14 (runtime `not assessable`), D16 (technical empty-group representation), and D22 (preparation extract IDs). These remain outside the current code and parser contracts.

## Next methodological PASS

PASS 8 should compare V1, the current runtime prompt and the compact candidate with identical corpus, context, request, evidence, provider, model and sampling. It should inspect interpretive lift, grounding, calibration, unsupported overreach, nuance, traceability and parser compatibility without automatically selecting a winner.
