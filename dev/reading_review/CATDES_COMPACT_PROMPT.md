# CATDES compact prompt

**Status: DRAFT — NOT APPROVED**

This is a future short-form candidate for CATDES. It is not wired into NaileR, must not be used as an implementation specification without review, and must not replace the approved V1 reference in [CATDES_REFERENCE_PROMPT.md](CATDES_REFERENCE_PROMPT.md).

## Draft compact reading block

The results below come from FactoMineR::catdes(). Each displayed fact compares one qualitative response modality or one quantitative variable in the category/group with the same modality or variable in the full analyzed sample. The full sample is the reference; it is not a reference category.

MORE FREQUENT and LESS FREQUENT describe relative overrepresentation and underrepresentation. Group percentage is the proportion of group members with the displayed modality; full-sample percentage is that modality's proportion in the analyzed sample. Relative overrepresentation is not necessarily a majority, and a less frequent modality may remain a majority response. Do not confuse the proportion of group members with a modality and the proportion of all people with that modality who belong to the group.

HIGHER and LOWER compare the group mean with the full-sample mean for the same quantitative variable. Interpret the direction using what the variable measures. Do not compare unrelated variable means as if they shared a scale. When supplied, v.test describes standardized statistical deviation and p.value describes evidence against a corresponding null hypothesis; neither is a direct measure of substantive importance.

Preserve negative wording, reverse wording, and double negation. Do not infer an opposite modality unless the coding and displayed evidence justify it. Keep reported capability, intention, behavior, preference, and perceived constraint distinct. The displayed evidence is selected evidence: an omitted variable or modality is not automatically absent or unimportant. If both modalities of a binary variable are displayed, read them as complementary descriptions. Use the introduction for substantive meaning, but do not treat context, labels, or hypotheses as statistical evidence.

## Draft interpretation rules

Synthesize related displayed findings into a meaningful profile instead of listing isolated facts. A higher-level concept is encouraged when several facts support it and the interpretation remains traceable. Mark it as a synthesis rather than a directly measured variable or a demonstrated relationship.

Preserve exceptions, tensions, and heterogeneous features. Do not exaggerate isolated findings or hide qualifying evidence. Respect every displayed direction and comparison. Do not invent unmeasured behaviors, beliefs, preferences, motivations, causes, or psychological traits. Contextual explanations may be proposed only as clearly identified hypotheses.

Compare several groups descriptively when they are displayed, but do not claim an unreported pairwise significance test or universal individual-level membership.

## Draft identity variants

### Standard mode — observed categories

Preserve each observed category name and identity. Describe its displayed associations without replacing it by a latent profile or a new category name. A higher-level interpretation may summarize the category's associations but must not overwrite its observed identity.

### Latent mode — constructed groups

Treat numeric or technical labels as identifiers, not substantive descriptions. Interpret each constructed group from its displayed profile and propose a concise measured-domain name only when the evidence is sufficiently coherent. Keep the identifier with the name. Do not invent psychological, moral, personality, or behavioral archetypes; if the profile is sparse or heterogeneous, retain the identifier without forcing a label.

## Draft task variants

### Local

Interpret only the displayed category/group. Combine its qualitative and quantitative findings, mention meaningful exceptions, preserve its identifier, and do not describe undisplayed groups.

### Global

Interpret every displayed category/group from its own evidence. Then summarize supported similarities, contrasts, and broader configurations while preserving all identifiers and avoiding unreported pairwise significance.

## Draft output

For every category/group, provide a core profile, supporting characteristics, nuances or exceptions, a distinctive interpretation relative to the full sample, and a descriptive name only when the selected mode permits and the evidence supports one. For global output, add descriptive similarities and differences. Avoid unnecessary numerical repetition while retaining traceable support. Preserve existing NaileR metadata and output-format contracts. Produce valid Quarto Markdown.

## Condensation risks and open arbitrations

- Shortening the qualitative percentage rules may make group percentages and modality percentages easier to confuse.
- Removing the explicit distinction between v.test/p.value and substantive importance could reintroduce a statistical-strength interpretation that CATDES semantic-facing evidence does not currently support.
- Compressing polarity, double-negation, capability, intention, behavior, preference, and constraint rules may change the epistemic meaning of responses.
- The compact version must retain the evidence-first distinction between factual evidence, synthesis, and contextual hypothesis.
- The wording for the standard/latent identity branches must remain mutually exclusive at runtime.
- The wording for local/global tasks must not imply pairwise tests that were not supplied.
- The current implementation does not expose p.value, v.test, or evidence IDs in the semantic-facing prompt; any compact wording that assumes their presence requires a separate implementation decision.
- The final reusable metadata and parser contract must remain protected if this draft is ever implemented.
- No experimental comparison has established that the shorter prompt preserves the behavior of V1 across CATDES datasets or providers.

