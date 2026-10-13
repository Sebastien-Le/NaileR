# CONDES compact prompt

**Status: DRAFT — NOT APPROVED**

This is a future short-form candidate. It is not implemented, not validated, and must be reviewed against [CONDES_REFERENCE_PROMPT.md](CONDES_REFERENCE_PROMPT.md) before use.

## Draft reading

The facts below come from FactoMineR::condes() under the displayed significance threshold. One numeric target is characterized by:

- signed correlations with quantitative predictors;
- global R2 associations with qualitative predictors;
- category and derived-state Estimates associated with lower or higher target values.

For a quantitative predictor, POSITIVE means that higher predictor values tend to accompany higher target values; NEGATIVE means the opposite. Absolute correlation describes linear-association magnitude. Interpret direction using what the predictor measures: higher numerical values are not automatically better or worse. Correlation is association, not prediction or causality.

R2 is a global association between the target and a categorical partition under the fitted one-way analysis. It has no sign and does not identify one category's contribution. Read category-level information separately.

Derived states such as Above-average value, Below-average value, and Intermediate value are created from the original quantitative predictor using the configured standardization threshold. They are not independent measurements. A continuous predictor and its derived states must not be counted as independent confirmations.

Estimate is a signed category coefficient under the sum-to-zero coding of the fitted one-factor model. It is expressed in target units and interpreted relative to the model reference. It is not automatically category mean minus the empirical mean of all individuals, not a standardized or multiple-regression coefficient, not causal, and not a universal importance measure. Preserve category labels, negations and reverse wording.

p.value describes evidence against its corresponding null under the performed analysis. It is neither association magnitude nor substantive importance. The displayed facts may be only a selected subset controlled by proba, sample.pct and sample.method. The actual quanti.threshold also matters for derived states. An undisplayed result is not automatically absent, unassociated, non-significant or unimportant.

Use the introduction for the meaning of the study and variables, but do not treat context as statistical evidence.

## Draft interpretation rules

Consider correlations, global qualitative associations and end profiles together. Identify the main coherent configuration rather than listing facts mechanically. Translate signs according to measured meaning, describe lower and higher target values, and use end profiles to illustrate or qualify the broader pattern.

A higher-level synthesis is allowed when several displayed associations support it. Present it as an interpretation, not a new measured variable, prediction, causal mechanism, or individual-level fact. Preserve exceptions, mixed findings, uncertainty and rare or marginal results. Do not force one homogeneous explanation.

## Standard mode

The target is an observed quantitative variable. Preserve its original name and meaning. Explain its variation and both ends without renaming it. A broader evidence-grounded synthesis may supplement its identity.

## Latent mode

The target is a synthetic or constructed quantitative dimension. Keep its original identifier visible and interpret the contrast between lower and higher ends. If the factor/component sign is arbitrary, do not treat the positive pole as intrinsically superior. Propose one concise measured-domain name only when the evidence supports it; otherwise describe the configuration without forcing a label. An optional target_concept may guide contextual wording but is not evidence and must not override the displayed facts.

## Draft task

Interpret one target using the displayed evidence and the user's analytical request. Explain the main associations, their substantive directions, both ends, the main contrast, and relevant limits. Use the standard or latent identity rule selected for this prompt.

## Draft output

Provide:

1. overall meaning of the target;
2. lower-end characteristics;
3. higher-end characteristics;
4. the main contrast between both ends;
5. nuances and limits.

For latent mode, optionally provide a concise evidence-grounded name. For standard mode, preserve the observed target name. Keep enough factual support for traceability and preserve valid Quarto Markdown, existing NaileR metadata, parser and output contracts.

## Dynamic sections retained

- introduction and request are user/context blocks;
- target interpretation rules select exactly one standard or latent branch;
- selection text reports actual proba, sample.pct, sample.method and quanti.threshold;
- data are the selected semantic-facing evidence;
- canonical continuous_profile remains distinct from interpretation_evidence and prompt evidence;
- there is no local/global or multi-group CONDES branch.

## Condensation risks and open arbitrations

- The compact wording may weaken the distinction between model-reference Estimate and empirical overall mean.
- Shortening the R2 explanation may make global categorical association look like a modality-level effect.
- Removing detail about sum-to-zero coding may encourage ordinary-language interpretation of Estimate signs.
- The compact version must preserve the fact that derived quantitative states are not independent evidence.
- p.value, association magnitude and substantive importance must remain distinct.
- A selected subset must not be read as an exhaustive profile.
- Rare labels, negative labels and reversed scales require literal semantic treatment.
- The standard/latent branches must remain mutually exclusive.
- The optional target_concept must remain contextual guidance, not evidence or an automatic renaming rule.
- No comparison has established behavioral equivalence between this draft and V1.

