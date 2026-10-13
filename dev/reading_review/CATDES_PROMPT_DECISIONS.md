# CATDES prompt decisions

**Scope:** decision log for PASS 7B.2. The approved V1 prompt is a methodological reference; it is not yet wired into the package. No R code, tests, man pages, evidence, statistical calculation, sampling, accessor, parser, or output contract is changed by this log.

## Decision log

### D1 — Overrepresentation

- **Initial problem:** A MORE FREQUENT modality can be read as if it were present in a majority of the group.
- **Methodological risk:** Relative overrepresentation becomes an absolute or individual-level claim.
- **Recommendations discussed:** Define MORE/LESS FREQUENT, retain group and full-sample percentages, explain denominators, and state explicitly that a MORE FREQUENT modality may still be a minority.
- **Decision:** A MORE FREQUENT modality is an overrepresentation relative to the full analyzed sample, not necessarily a majority within the group. A LESS FREQUENT modality may remain the majority response.
- **Scientific justification:** CATDES compares frequencies with the full sample; the direction and both denominators are needed to preserve its meaning.
- **Prompt section:** How to Read the Statistical Evidence — Understanding qualitative evidence.
- **Possible code consequences:** Keep modality identity, group percentage, full-sample percentage, and direction in semantic-facing evidence.
- **Status:** VALIDATED.

### D2 — Polarity

- **Initial problem:** Statistical direction and linguistic polarity are easily conflated, especially for negative, reverse-worded, or double-negative modalities.
- **Methodological risk:** A less frequent negative statement becomes a positive claim, or a statistical direction is treated as a semantic inversion.
- **Recommendations discussed:** Read statistical direction and modality meaning separately; infer an opposite only when coding and displayed evidence justify it.
- **Decision:** Preserve the semantic meaning of each modality independently of MORE/LESS FREQUENT. Do not automatically transform a negative response into a positive characteristic.
- **Scientific justification:** Frequency direction does not reverse the construct expressed by the response modality.
- **Prompt section:** How to Read the Statistical Evidence — Preserving the meaning of response modalities.
- **Possible code consequences:** No statistical recoding; preserve current modality labels and directions.
- **Status:** VALIDATED.

### D3 — Quantitative evidence

- **Initial problem:** HIGHER and LOWER can be read as universal positive/negative judgments or compared across unrelated variables.
- **Methodological risk:** The model invents a common scale or the wrong substantive polarity.
- **Recommendations discussed:** Define HIGHER/LOWER as comparison of the group mean with the full-sample mean for the same variable.
- **Decision:** HIGHER and LOWER concern the mean of a group relative to the mean of the full analyzed sample for the same variable. Their substantive meaning depends on what the variable measures.
- **Scientific justification:** This is the actual CATDES comparison and avoids cross-variable comparisons without a justified common scale.
- **Prompt section:** How to Read the Statistical Evidence — Understanding quantitative evidence.
- **Possible code consequences:** Retain variable identity and group/full-sample means in semantic-facing evidence.
- **Status:** VALIDATED.

### D4 — Synthesis and exceptions

- **Initial problem:** Listing characteristics one by one does not produce a useful group profile, while a single label can erase contradictions.
- **Methodological risk:** Either paraphrase-only output or an artificially uniform narrative.
- **Recommendations discussed:** Search for a dominant configuration, synthesize related findings, and require exceptions, tensions, and heterogeneous features.
- **Decision:** Construct a meaningful dominant configuration from the displayed findings without hiding relevant exceptions, contradictions, or tensions.
- **Scientific justification:** A profile can be substantively interpretable while remaining heterogeneous.
- **Prompt section:** Interpretation Rules 1 and 2; Final Interpretation Requirements.
- **Possible code consequences:** None to the evidence; prompt instructions must allow synthesis and qualification.
- **Status:** VALIDATED.

### D5 — Higher-level semantic constructions

- **Initial problem:** Evidence-first may be reduced to evidence-only paraphrase.
- **Methodological risk:** The LLM is prevented from constructing a useful concept, or conversely presents a synthesis as a measured fact.
- **Recommendations discussed:** Permit concepts supported by several displayed facts, while requiring traceability and explicit distinction from direct measurement.
- **Decision:** A higher-level interpretation is allowed and encouraged when it synthesizes several findings defensibly. It is an analytical synthesis, not a new empirical fact, measured variable, or demonstrated relationship.
- **Scientific justification:** A new semantic concept is not the same as an invented empirical observation.
- **Prompt section:** Interpretation Rules 1 and 4; Final Interpretation Requirements.
- **Possible code consequences:** No evidence change; preserve interpretive lift and fact/interpretation/hypothesis calibration.
- **Status:** VALIDATED.

### D6 — Standard mode

- **Initial problem:** Observed category names may be replaced by a substantive label.
- **Methodological risk:** The output changes the identity of the target variable.
- **Recommendations discussed:** Preserve observed names and use any higher-level interpretation only to describe their associations.
- **Decision:** Standard mode preserves the original names and identities of observed categories. A category must not be renamed or reinterpreted as a constructed latent profile.
- **Scientific justification:** The observed label is part of the data contract; its associations may be interpreted without replacing it.
- **Prompt section:** Group Identity Rules — STANDARD MODE.
- **Possible code consequences:** Keep the standard branch separate from latent naming rules.
- **Status:** VALIDATED.

### D7 — Latent mode

- **Initial problem:** A constructed partition can be treated as a pre-existing psychological class or naturally homogeneous type.
- **Methodological risk:** Technical group identifiers become unsupported substantive entities.
- **Recommendations discussed:** Keep identifiers, treat them as non-substantive labels, and permit optional measured-domain names only when the profile supports them.
- **Decision:** Latent groups are constructed groups, not automatically probabilistic latent classes or psychological entities. A concise descriptive name is optional, must remain grounded in measured characteristics, and must supplement the original identifier.
- **Scientific justification:** The upstream construction does not by itself establish the nature or homogeneity of the groups.
- **Prompt section:** Group Identity Rules — LATENT MODE.
- **Possible code consequences:** Select the latent branch explicitly and preserve identifiers in local and global output.
- **Status:** VALIDATED.

### D8 — Evidence selection

- **Initial problem:** The parameters quali.sample, quanti.sample, and drop.negative can be mistaken for changes to the underlying CATDES profile.
- **Methodological risk:** Prompt evidence is treated as the complete or modified statistical result.
- **Recommendations discussed:** Describe selection settings dynamically and keep canonical profiles separate from semantic-facing selected evidence.
- **Decision:** These settings control the information transmitted to the LLM, not the canonical statistical profiles.
- **Scientific justification:** Selection is a presentation policy; it must not rewrite the statistical analysis.
- **Prompt section:** Scope and selection of evidence; Data.
- **Possible code consequences:** Preserve evidence registry, selected IDs, canonical profiles, and invariance tests.
- **Status:** VALIDATED.

### D9 — Binary completion

- **Initial problem:** Two modalities of a binary variable may be treated as independent facts, or a missing complement may be invented.
- **Methodological risk:** Double counting or unsupported modality inference.
- **Recommendations discussed:** Present both modalities only when they are actually available under the validated policy; explain complementarity without fabricating evidence.
- **Decision:** The two modalities may be presented when both correspond to available facts. They are complementary descriptions of one variable; an unshown modality is not invented.
- **Scientific justification:** The rule respects binary structure and the evidence-selection contract.
- **Prompt section:** Scope and selection of evidence; Preserving the meaning of response modalities.
- **Possible code consequences:** Preserve current binary completion and semantic-facing evidence behavior.
- **Status:** VALIDATED.

### D10 — Local and global scope

- **Initial problem:** User analytical requests and automatically generated local/global instructions can be conflated.
- **Methodological risk:** A local prompt describes undisplayed groups, or a global prompt makes unsupported pairwise claims; user intent may be silently rewritten.
- **Recommendations discussed:** Preserve the original request and add only explicit operational scope instructions.
- **Decision:** The original user request is preserved. A local task concerns one displayed category/group; a global task characterizes the complete displayed set and compares profiles descriptively without unreported pairwise significance.
- **Scientific justification:** Scope is an operational constraint, while the request supplies the analytical question.
- **Prompt section:** Overall Analytical Request; Task — LOCAL/GLOBAL.
- **Possible code consequences:** Keep local and joint routes distinct, including their active prompt and audit semantics.
- **Status:** VALIDATED.

### D11 — Role of the introduction

- **Initial problem:** Context can be treated as additional statistical evidence.
- **Methodological risk:** Domain hypotheses or group labels are presented as CATDES findings.
- **Recommendations discussed:** Use introduction to give meaning to measured constructs, but explicitly separate context, evidence, synthesis, and hypothesis.
- **Decision:** The introduction supplies substantive context for interpretation; it is not an additional statistical observation or substitute for displayed evidence.
- **Scientific justification:** Context is necessary for meaning but does not change the CATDES comparison.
- **Prompt section:** How to Read the Statistical Evidence — Role of the study context; Interpretation Rules 3 and 4.
- **Possible code consequences:** Preserve introduction as a separate prompt component and do not merge it into evidence.
- **Status:** VALIDATED.

### D12 — Significance information

- **Initial problem:** The reference should explain v.test and p.value when those fields are supplied, although current CATDES semantic-facing evidence intentionally does not systematically expose them.
- **Methodological risk:** Documentation is mistaken for current runtime behavior, or fields are exposed without a separate evidence-policy review.
- **Recommendations discussed:** Define v.test and p.value conditionally; retain canonical values for audit; defer systematic semantic-facing exposure.
- **Decision:** V1 defines v.test and p.value only when supplied. Whether to expose these statistics systematically in LLM-facing evidence remains to be arbitrated before implementation.
- **Scientific justification:** This preserves the canonical-versus-LLM-facing distinction and avoids silently changing the evidence contract.
- **Prompt section:** Understanding statistical significance; Data.
- **Possible code consequences:** Any exposure requires a dedicated implementation, invariance checks, and an interpretive benchmark.
- **Status:** TO VERIFY BEFORE IMPLEMENTATION / DEFERRED.

### D13 — Reference versus compact prompt

- **Initial problem:** A shorter prompt can accidentally become a second methodological doctrine.
- **Methodological risk:** Condensation removes protections or changes the semantics while appearing equivalent.
- **Recommendations discussed:** Treat V1 as the stable long reference; make the compact version a faithful draft and identify every condensation risk.
- **Decision:** The reference prompt is the approved methodological source of truth. The compact prompt is a future operational candidate marked DRAFT — NOT APPROVED. It must be reviewed against V1 before any implementation.
- **Scientific justification:** Shortening is useful for local models, but length alone does not establish methodological equivalence.
- **Prompt section:** All sections, especially reading, interpretation, identity, task, and output.
- **Possible code consequences:** No automatic short/long selection, provider-specific branch, or code change in this PASS.
- **Status:** VALIDATED as documentation policy; compact implementation DEFERRED.

## Traceability matrix

| ID | Reference wording / rule | Compact wording / location | Coverage | Difference or open issue |
| --- | --- | --- | --- | --- |
| D1 | MORE/LESS FREQUENT is relative to the full sample; group and full-sample percentages; not necessarily majority | Compact opening reading block | Complete | Denominator explanation is shorter and should be checked in a future comparison. |
| D2 | Preserve modality polarity, negative wording, reverse wording and justified complements | Compact opening reading block | Complete | Less elaborated than V1. |
| D3 | HIGHER/LOWER compares the same variable with the full-sample mean | Compact opening reading block | Complete | Shorter construct explanation. |
| D4 | Construct a meaningful profile and preserve exceptions/tensions | Compact interpretation rules | Complete | Compact version may need examples for heterogeneous profiles. |
| D5 | Higher-level concept is synthesis, not a new fact or measured variable | Compact interpretation rules | Complete | Main condensation risk is over-compression of calibration. |
| D6 | Standard mode preserves observed names and identities | Compact standard mode | Complete | No substantive difference intended. |
| D7 | Latent labels are identifiers; names are optional and measured-domain grounded | Compact latent mode | Complete | Optional naming remains to be tested operationally. |
| D8 | Selection parameters control transmitted evidence, not canonical profiles | Compact reading block and risk list | Partial | Dynamic parameter wording is condensed. |
| D9 | Binary modalities may be complementary when both are available; do not invent one | Compact reading block | Complete | Runtime completion policy still needs explicit implementation review. |
| D10 | Preserve request; local/global task defines scope and comparison limits | Compact task variants | Complete | Compact global wording is shorter. |
| D11 | Context gives meaning but is not statistical evidence | Compact opening reading block | Complete | Context distinction is shorter. |
| D12 | Explain v.test/p.value when supplied; systematic exposure remains open | Compact reading block and risk list | Partial by design | Must not be interpreted as current semantic-facing exposure. |
| D13 | V1 is approved reference; compact is a draft, not a second doctrine | Compact status and condensation risks | Complete | Compact remains explicitly unapproved. |

## Status summary

- **Validated methodological decisions:** D1–D11 and the documentation policy in D13.
- **Open before implementation:** D12 systematic exposure of significance statistics.
- **Deferred:** any renderer change, compact/default selection, provider-specific logic, or package-wide prompt refactor.
- **Required next review:** compare V1 and the compact draft on standard/latent and local/global cases with canonical-evidence invariance and output-contract checks.

