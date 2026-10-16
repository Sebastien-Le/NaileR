# Scientific review — NaileR CATDES–TEXTUAL, benchmark v1

## Scientific principle

The `nail_catdes_textual()` prompts explicitly make the **mechanical CATDES facts authoritative** and the parsed TEXTUAL profiles **supplementary**. A textual theme is not automatically a statistical marker. All three generated answers retain exactly five fields; the statistical-anchor fields contain only stated CATDES findings.

## Group G1

**Statistical information.** Relative to the whole sample, price is more frequently selected as the primary concern and environmental and quality concerns less frequently selected; conventional diet is more frequent. Average spending, age, purchasing frequency and household size are lower.

**Textual contribution.** Manageable price and familiar taste help contextualize the salience of price. Uncertainty about the environment and ingredients, convenience after work, and limited choice supplement the statistical results.

**Protection against unsupported inference.** The response does not infer causes for lower spending, frequency or demographic means, nor infer that the conventional diet arises from the expressed prices or convenience. Environmental questions in comments are not interpreted as invalidating lower statistical selection of 'environment' as a primary concern.

**Limit.** There are only four distinct formulations across 32 comments, restricting the richness of independent qualitative voices.

## Group G2

**Statistical information.** G2 has higher means for spending, purchasing frequency, satisfaction, age and household size; the flexitarian modality and online shopping are more frequent, conventional diet less frequent.

**Textual contribution.** Satisfaction with assortment is qualified by price comparison; online time savings are qualified by delivery reliability; remarks about spending beyond the plan provide context for perceived expense.

**Protection against unsupported inference.** The response does not infer that the flexitarian modality causes higher spending, that higher age explains purchasing patterns, or that comments about occasional overspending explain the statistical mean.

**Limit.** Only six distinct comment formulations occur among 32 comments.

## Group G3

**Statistical information.** The only retained marker is lower mean satisfaction (5.88 versus 6.46); neither a shopping profile nor a demographic structure is statistically established here.

**Textual contribution.** Pleasant experiences may coexist with perceived expense, unverifiable environmental claims and difficulty accessing local alternatives. These contextual concerns need not be CATDES-confirmed attributes.

**Protection against unsupported inference.** The response neither explains the observed satisfaction difference causally nor attributes all these views to every G3 respondent.

**Limit.** Only five distinct comment formulations occur in 32 observations. Even complete response coverage does not imply broad diversity of expressed experiences.

## Evaluation status and next verification

The response content was checked against the three exact GitHub prompts and against the five required labels in order. This is a **manual preparation check**, not a claim that the R parser or downstream result objects have been executed.

Codex should replay the response texts through a prompt-SHA keyed, no-network backend, call `nail_catdes_textual(generate=TRUE)` with the previously validated CATDES and TEXTUAL objects, and verify:
1. Three parsed contextualized profiles have status `available` and no parse issues.
2. Canonical CATDES and original TEXTUAL evidences are unchanged.
3. Each exact prompt and each exact raw response are preserved.
4. `nail_usage()` does not invent a provider invocation or usage metadata.
5. The new composition adds analytical meaning without overwriting the statistical anchor.
6. Test results and limitations are committed to validation fixtures only, not to the package source.

The benchmark should later be expanded to include more independent verbatim formulations and a less sparse statistical profile for G3.
