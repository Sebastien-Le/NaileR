# CONDES prompt decisions

**Scope:** scientific decision log for PASS 7C.2. The V1 prompt is the approved methodological reference; the compact prompt is a draft. No package implementation, tests, statistical evidence, selection rule, argument, contract, parser, or documentation page is changed here.

## D1 — Correlations

- **Initial problem:** A correlation sign can be interpreted as favorable/unfavorable rather than numerical direction.
- **Methodological risk:** The LLM imports an evaluative meaning not present in the measured scale.
- **Recommendations discussed:** Define positive and negative directions, explain absolute correlation magnitude, and require interpretation according to the predictor's measurement scale.
- **Decision:** The sign expresses numerical association direction. It is not automatically positive or negative in substantive value.
- **Justification:** A higher time, rank, error count, or difficulty value may have a different substantive meaning from a higher performance score.
- **Prompt section:** How to Read the Statistical Evidence — Quantitative associations.
- **Possible future code consequences:** Preserve signed correlation, absolute correlation and source variable identity in semantic-facing evidence.
- **Status:** VALIDATED.

## D2 — Correlation and causality

- **Initial problem:** Association may be read as causal influence or independent predictive contribution.
- **Methodological risk:** The output attributes mechanisms or prediction not established by CONDES.
- **Recommendations discussed:** Explicitly distinguish association, prediction and causality.
- **Decision:** A correlation does not establish causality, independent predictive contribution, or a direct substantive relationship beyond the measured association.
- **Justification:** FactoMineR::condes() supplies association statistics, not a causal or predictive design.
- **Prompt section:** Quantitative associations; Interpretation Rules 4 and 5.
- **Possible future code consequences:** None; preserve the current statistical result and wording safeguard.
- **Status:** VALIDATED.

## D3 — Qualitative R2

- **Initial problem:** A global R2 may be interpreted as the effect of a particular modality.
- **Methodological risk:** The model confuses global variable-level association with category-level characterization.
- **Recommendations discussed:** Define R2 as a global association under the one-way analysis and treat category-level results separately.
- **Decision:** R2 has no direction and does not identify a particular category's contribution.
- **Justification:** The global categorical partition and its individual category terms are different levels of evidence.
- **Prompt section:** How to Read the Statistical Evidence — Global qualitative associations.
- **Possible future code consequences:** Keep qualitative_associations and end_profiles as distinct evidence families.
- **Status:** VALIDATED.

## D4 — Estimate and statistical reference

- **Initial problem:** Estimate can be described incorrectly as category mean minus the empirical mean of all individuals.
- **Methodological risk:** The LLM applies an incorrect reference and misstates the model coefficient.
- **Recommendations discussed:** Describe Estimate as a category coefficient under sum-to-zero coding and distinguish the model reference from the empirical overall mean.
- **Decision:** Estimate is interpreted under the sum-to-zero contrast coding used by the fitted one-factor model. Do not impose the general formula Estimate = category mean - overall empirical mean. Under usual sum-contrast conditions, the reference relates to the mean of modality means, with weights affecting the fitted calculation.
- **Justification:** This reflects the actual FactoMineR implementation and avoids collapsing model coefficients into an unconditional empirical contrast.
- **Prompt section:** How to Read the Statistical Evidence — Category and end-profile evidence.
- **Possible future code consequences:** Preserve the fitted coding/model provenance if Estimate is exposed or further documented.
- **Status:** VALIDATED.

## D5 — Estimate units and interpretation

- **Initial problem:** Estimate may be mistaken for a standardized loading, a partial regression coefficient, or a causal effect.
- **Methodological risk:** The model assigns an inappropriate scale or causal meaning.
- **Recommendations discussed:** State that Estimates use the target's units and are relative to the fitted model reference.
- **Decision:** Estimate is in the unit of the target; it is not a standardized coefficient, not a multiple-regression partial coefficient, not a causal effect, and not a universal importance measure.
- **Justification:** The coefficient is produced by the one-factor fitted coding used by condes().
- **Prompt section:** Category and end-profile evidence.
- **Possible future code consequences:** None beyond retaining target and model provenance.
- **Status:** VALIDATED.

## D6 — Derived quantitative states

- **Initial problem:** Above-average, Below-average and Intermediate states may be counted as independent evidence in addition to the original correlation.
- **Methodological risk:** One predictor receives disproportionate interpretive weight.
- **Recommendations discussed:** Explain the configurable quanti.threshold and retain the link to the original quantitative variable.
- **Decision:** Derived states are technical categorizations of original quantitative predictors. They illustrate or qualify the continuous association and are not independent measurements or confirmations.
- **Justification:** The implementation keeps the continuous predictor and adds a state copy before one condes() call.
- **Prompt section:** Category and end-profile evidence; Data.
- **Possible future code consequences:** Preserve source-variable mapping and avoid duplicate evidence counting.
- **Status:** VALIDATED.

## D7 — Significance

- **Initial problem:** A small p.value may be interpreted as substantive importance or association magnitude.
- **Methodological risk:** The LLM ranks meaning by statistical support alone.
- **Recommendations discussed:** Separate p.value, association magnitude and interpretive relevance.
- **Decision:** p.value describes evidence against the corresponding null under the performed analysis; it does not measure substantive importance or magnitude.
- **Justification:** Statistical support and substantive centrality are different properties.
- **Prompt section:** Statistical significance and evidence selection.
- **Possible future code consequences:** Preserve p.values without turning them into an automatic interpretive ranking.
- **Status:** VALIDATED.

## D8 — Evidence selection

- **Initial problem:** sample.pct and sample.method may be confused with changes to the canonical CONDES profile.
- **Methodological risk:** A partial prompt is presented as the complete analysis, or the canonical evidence is silently altered.
- **Recommendations discussed:** Describe selection dynamically and keep condes_result, continuous_profile, interpretation_evidence and semantic-facing evidence separate.
- **Decision:** sample.pct and sample.method control selection of evidence for interpretation only. They do not alter the canonical continuous_profile.
- **Justification:** The implementation demonstrates this invariance and the reproduction script asserts it.
- **Prompt section:** Statistical significance and evidence selection; Data.
- **Possible future code consequences:** Preserve evidence IDs, selection settings and invariance tests.
- **Status:** VALIDATED.

## D9 — Labels and polarity

- **Initial problem:** Variable labels, technical states, negative wording and reversed scales can be silently reinterpreted.
- **Methodological risk:** The output invents social, psychological or evaluative content from labels.
- **Recommendations discussed:** Preserve literal labels and interpret them according to the measured scale and study context.
- **Decision:** Preserve variable/category identifiers, negations and reverse wording. Do not infer a social, psychological or behavioral mechanism from a label alone.
- **Justification:** Labels are evidence descriptors, not independent theories of the target.
- **Prompt section:** Category and end-profile evidence; Interpretation Rules 2 and 5.
- **Possible future code consequences:** No recoding or lexical substitution in evidence generation.
- **Status:** VALIDATED.

## D10 — Standard mode

- **Initial problem:** An observed target may be renamed as though it were a latent construct.
- **Methodological risk:** The target identity and interpretation contract are changed.
- **Recommendations discussed:** Preserve the observed name and meaning while allowing a broader synthesis of its associations.
- **Decision:** Standard mode preserves the original quantitative target name and identity.
- **Justification:** The target is observed; interpretation supplements but does not replace it.
- **Prompt section:** Target Interpretation Rules — STANDARD MODE.
- **Possible future code consequences:** Keep the standard branch separate from latent naming rules.
- **Status:** VALIDATED.

## D11 — Latent mode

- **Initial problem:** A synthetic score may be treated as a naturally occurring homogeneous psychological or social construct.
- **Methodological risk:** A technical label becomes an unsupported ontology.
- **Recommendations discussed:** Retain the identifier, interpret the contrast between its ends, and make naming optional.
- **Decision:** Latent mode reconstructs the dimension from its associations and lower/higher ends. A concise name may be proposed only when supported by the measured evidence; the original identifier remains visible.
- **Justification:** A factor/component or synthetic score has a numerical profile, but its substantive meaning is not guaranteed by construction alone.
- **Prompt section:** Target Interpretation Rules — LATENT MODE.
- **Possible future code consequences:** Preserve identifiers and do not impose a name when evidence is heterogeneous.
- **Status:** VALIDATED.

## D12 — Factor orientation

- **Initial problem:** The positive sign of a factor/component can be treated as intrinsically superior or substantively better.
- **Methodological risk:** The arbitrary orientation of a dimension becomes a value judgment.
- **Recommendations discussed:** Describe the opposition between poles and avoid claims about intrinsic superiority.
- **Decision:** When sign orientation is arbitrary, interpret the contrast between lower and higher poles, not the positive pole as inherently preferable.
- **Justification:** Multiplying a factor by -1 preserves the dimension while reversing its numeric sign.
- **Prompt section:** Target Interpretation Rules — LATENT MODE.
- **Possible future code consequences:** None; the prompt must preserve the original identifier and describe both ends.
- **Status:** VALIDATED.

## D13 — Synthesis and heterogeneity

- **Initial problem:** A prompt can either paraphrase indicators line by line or force one unifying concept.
- **Methodological risk:** The LLM loses interpretive value or conceals contradictions and weak evidence.
- **Recommendations discussed:** Encourage synthesis of related associations while requiring exceptions, uncertainty and mixed patterns.
- **Decision:** Higher-level interpretation is encouraged when supported by several displayed associations, but no single concept is mandatory and heterogeneity must remain visible.
- **Justification:** Interpretive lift is useful only when traceable and calibrated to the evidence.
- **Prompt section:** Interpretation Rules 1, 3, 4 and 5; Final Interpretation Requirements.
- **Possible future code consequences:** None; preserve selected evidence and output contract.
- **Status:** VALIDATED.

## D14 — Context and user request

- **Initial problem:** Introduction and request can be treated as additional statistical evidence or silently rewritten.
- **Methodological risk:** Contextual hypotheses become measured findings, or the user's analytical objective is displaced.
- **Recommendations discussed:** Preserve introduction and request faithfully, use context for meaning, and distinguish context from evidence.
- **Decision:** The introduction and request retain their analytical roles. They orient interpretation but are not statistical evidence.
- **Justification:** The user supplies study meaning and the analytical question; CONDES supplies the statistical facts.
- **Prompt section:** Role of the study context; Analytical Question.
- **Possible future code consequences:** Keep context and request as separate prompt blocks.
- **Status:** VALIDATED.

## D15 — target_concept

- **Initial problem:** The optional target_concept may appear to be a study fact or an automatic target label.
- **Methodological risk:** A contextually supplied concept is treated as evidence or forces an unsupported latent name.
- **Recommendations discussed:** Inspect the actual code path before classifying this as a bug; document provenance and defer correction if the exact issue is not established.
- **Decision:** In the current implementation, target_concept is validated and passed to the prompt builders. It is ignored by build_request_condes() and by standard interpretation. In latent mode, it is used only as contextual guidance in the concept_rule; the default is the generic phrase “the target concept”. It is not inserted into introduction or request. This is an implementation observation, not a confirmed defect.
- **Justification:** The behavior is established by reading R/nail_condes.R and the generated Case B prompt.
- **Prompt section:** Latent Interpretation Rules; runtime target_concept behavior.
- **Possible future code consequences:** Any change requires an explicit API and prompt-contract decision.
- **Status:** TO VERIFY; no code correction in this PASS.

## D16 — Reference and compact version

- **Initial problem:** A shorter prompt can silently remove statistical safeguards or become a second doctrine.
- **Methodological risk:** The compact version appears equivalent without preserving meaning.
- **Recommendations discussed:** Keep a complete approved reference, derive a shorter candidate, and record every condensation risk.
- **Decision:** The complete V1 is the scientific source of truth. The compact version is DRAFT — NOT APPROVED and will not be implemented or validated in this PASS.
- **Justification:** Concision is an operational hypothesis, not evidence of methodological equivalence.
- **Prompt section:** All sections, especially reading, interpretation, target mode and output.
- **Possible future code consequences:** No provider-specific selection or prompt_style change is authorized.
- **Status:** VALIDATED as documentation policy; compact implementation DEFERRED.

## Traceability matrix

| Decision | Reference section | Compact formulation | Coverage | Difference / risk | Status |
| --- | --- | --- | --- | --- | --- |
| D1 | Quantitative associations | Draft reading, correlation direction | Complete | Scale-dependent meaning is shorter | Covered |
| D2 | Quantitative associations; interpretation rules | Draft reading and interpretation | Complete | Prediction distinction is compressed | Covered |
| D3 | Global qualitative associations | Draft reading, R2 paragraph | Complete | Category-level separation is shorter | Covered |
| D4 | Category and end-profile evidence | Draft Estimate paragraph | Complete | Sum-to-zero reference needs future operational check | Covered with caution |
| D5 | Category and end-profile evidence | Draft Estimate paragraph | Complete | Model provenance is condensed | Covered |
| D6 | Category/end-profile evidence; Data | Draft derived-state paragraph | Complete | Threshold details are shorter | Covered |
| D7 | Statistical significance and selection | Draft p.value paragraph | Complete | Null wording is condensed | Covered |
| D8 | Statistical significance and evidence selection | Draft selection paragraph | Complete | Dynamic settings listed compactly | Covered |
| D9 | Category/end-profile evidence; interpretation rules | Draft label/polarity safeguards | Complete | Fewer examples | Covered |
| D10 | Standard mode | Draft Standard mode | Complete | No substantive difference intended | Covered |
| D11 | Latent mode | Draft Latent mode | Complete | Naming uncertainty is shorter | Covered |
| D12 | Latent mode | Draft latent orientation sentence | Complete | Factor sign explanation is compressed | Covered |
| D13 | Interpretation Rules 1–5 | Draft interpretation rules | Complete with risk | Heterogeneity wording is shorter | Covered with caution |
| D14 | Context; Analytical Question | Draft context/task wording | Complete | User-request preservation is summarized | Covered |
| D15 | Dynamic target_concept behavior | Draft latent target_concept sentence | Partial by design | Exact current provenance remains an open verification item | TO VERIFY |
| D16 | Whole prompt specification | Draft status and risk list | Complete | Draft is explicitly unapproved | Covered |

## Status summary

- **Validated methodological decisions:** D1–D14 and the documentation policy in D16.
- **Implementation observation to verify:** D15 target_concept behavior; no confirmed bug and no code change.
- **Deferred:** prompt integration, prompt_style changes, compact-prompt validation, provider-specific selection, and any API change.

