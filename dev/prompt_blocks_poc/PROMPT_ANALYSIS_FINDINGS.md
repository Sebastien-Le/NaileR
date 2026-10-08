# Prompt Analysis Findings

This is a living methodological journal for the prompt-block experiments in NaileR. It records observations, interpretations, working hypotheses, architectural decisions, and open questions separately. It is not package documentation and it does not define a general prompt API.

## 1. Purpose

The experiments ask how the construction of a statistical-analysis prompt changes the balance between interpretive lift, evidence fidelity, internal diversity, epistemic calibration, and machine-readable downstream output. They are development experiments, not a replacement for statistical validation. The evidence, its selection, and its canonical accessors remain the reference point.

Current scope:

- QDA modular prompt-block proof of concept;
- TEXTUAL modular prompt-block proof of concept and ablations;
- prompt wording experiments around relative sensory interpretation;
- no package-wide prompt refactoring is implied.

The current source branch is `dev-textual-prompt-blocks-poc`. The QDA PoC was started from `dev-modular-prompt-blocks-poc` at `e47377ce`; the current PASS5 TEXTUAL artifact records that lineage in `dev/prompt_blocks_poc/textual_prompt_blocks_poc.md`.

## 2. Working definition

> A statistical data-analysis prompt is an epistemic workflow expressed in language: it establishes the context, defines how evidence should be read, states the analytical question, regulates interpretive lift, binds these rules to the current analytical object, presents the evidence, and specifies the expected form of the answer.

The working doctrine is:

> NaileR should not force the LLM to stay inside the vocabulary of the evidence; it should force the LLM to remain accountable to the evidence.

## 3. Common prompt grammar

The experiments suggest a shared conceptual vocabulary, not yet a universal renderer.

| Block | Conceptual function |
| --- | --- |
| `context` | Situates the study and supplies substantive context useful for meaning-making; it is not statistical evidence. |
| `reading` | Defines the epistemic status of the evidence and how the method-specific evidence should be read. |
| `question` | States the analytical objective to answer. |
| `interpretation` | Regulates how far the answer may move beyond literal evidence, including interpretive lift, traceability, and status marking. |
| `local_task` | Binds the instructions to the current analytical object. It can be decomposed into scope binding, comparison boundary, and instruction binding. |
| `evidence` | Provides the empirical/statistical constraint for the current object. |
| `output` | Specifies the answer form. Analytical quality and a machine-readable downstream contract are related but distinct concerns. |

The grammar is ordered: context gives the setting, reading gives evidence semantics, question gives purpose, interpretation regulates the permissible distance from evidence, local task binds the scope, evidence supplies the support, and output defines the requested answer.

## 4. QDA experiments

### 4.1 Modular prompt architecture

**Observed result.** The QDA PoC represents an isolated product prompt as `context`, `reading`, `question`, `interpretation`, `local_task`, `evidence`, `reusable`, and `output`. The internal representation is stored as a QDA-specific block artifact; `nail_prompt()` still returns the final rendered character prompt. The QDA `reusable` block remains a downstream-specific HTML metadata instruction and was not redesigned as a general contract.

**Observed result.** The full prompt places the final interpretation requirements after the reusable metadata instruction. The evidence block and canonical `product_profiles` remain unchanged between full and minimal prompt variants.

**Architectural decision.** Keep the QDA block model method-specific for the PoC. Do not introduce a package-wide grammar, `+` operator, or public block accessor yet.

### 4.2 Full versus reduced prompts

**Observed result.** In the QDA ablation with `mistral-small3.2`, the full prompt gave the best overall behaviour, while the minimal prompt was unexpectedly solid. `interpretation` alone gave limited benefit and `reading` alone was less convincing. These are observations from the recorded development comparison, not a general model law.

**Interpretation.** The default assistance is useful, but the evidence and the user's analytical request already carry substantial information. Removing blocks changes the prompt, not the statistical evidence.

**Open question.** The relative contribution of each block may depend on model, task, evidence density, and output contract. More ablations would be needed before selecting a universal default for other methods.

### 4.3 Interpretation wording experiments

**Observed result.** The current QDA interpretation wording outperformed the tested alternatives in the recorded blind comparisons. The wording allows a higher-level sensory concept when it synthesizes several displayed facts, while prohibiting unsupported empirical attributes and causal claims.

**Observed result.** The current semantic-facing evidence rendering also outperformed the tested alternative that directly replaced the relative markers by “more pronounced / less pronounced”.

**Interpretation.** A useful QDA prompt separates three operations:

```text
HIGHER / LOWER
        -> relative characterization
        -> sensory configuration
        -> higher-level interpretation
        -> descriptive name
```

**Architectural decision.** Keep the rule that `R` determines which sensory facts statistically characterize the product, while the LLM interprets the configuration of those relative facts. Do not collapse the configuration into a list of isolated paraphrases.

### 4.4 HIGHER / LOWER wording experiment

**Observed result.** The first relative-interpretation rule was unstable. In the final blind comparison, the B2 wording was preferred in all three repetitions and was retained in the QDA PoC.

**Interpretation.** Explicitly preserving relative meaning helps prevent a `LOWER` attribute from being converted into an invented positive opposite or an absolute claim. It also leaves room for a substantive synthesis such as a dark, intense, or less sweet sensory configuration when several displayed facts converge.

**Open question.** The result is based on a small, model-specific blind comparison. It supports retaining the wording in this PoC; it does not prove that the same wording is optimal for every model or QDA design.

### 4.5 Evidence-level representation experiments

These experiments tested how much deterministic statistical transformation R
should perform before presenting QDA evidence to the LLM. They changed only
the LLM-facing `reading` and `evidence` blocks. The canonical evidence,
selected markers, product, context, question, interpretation, local task,
reusable instruction, output requirement, model, and generation settings were
held fixed within each comparison.

#### Evidence-level experiment — `choc1`

**Observed result.** The four conditions were:

```text
A = numeric table
B = current semantic + numeric
C = semantic minimal
D = semantic + mechanical primary/secondary hierarchy
```

The experiment used `choc1`, Ollama `mistral-small3.2`, and the ten retained
markers `QDAP001E001` through `QDAP001E010`. The blind review produced:

| Condition | Ranks | Mean | Median |
|---|---|---:|---:|
| C | 1, 3, 4 | 2.67 | 3 |
| A | 2, 7, 8 | 5.67 | 7 |
| B | 5, 6, 12 | 7.67 | 6 |
| D | 9, 10, 11 | 10.00 | 10 |

The tested ordering was therefore `C > A > B > D` in this small blind
comparison.

**Interpretation.** Semantic minimal performed best on this dense and highly
coherent product profile. The numeric table remained viable, while the
semantic-plus-numeric condition did not outperform the simpler alternatives.
The mechanically imposed `primary / secondary` dichotomy performed poorly.
This is a result for the tested product, model, prompt, and small replication,
not evidence that semantic minimal is universally superior.

**Observed fidelity issue.** `LOWER` was sometimes converted into `absence
of` or `lacks`. This is horizontal semantic distortion: it changes the
meaning or polarity of a relative fact. It is not ordinary vertical
interpretive lift.

#### Less-dense replication — `choc2`

**Observed result.** The replication compared A, B, and C on the six retained
markers below, with the same six evidence IDs in all conditions:

```text
Crunchy     HIGHER   v.test =  6.92
MilkF       LOWER    v.test = -5.16
CocoaF      HIGHER   v.test =  2.95
Melting     LOWER    v.test = -2.59
Caramel     LOWER   v.test = -2.48
Sweetness   LOWER   v.test = -2.08
```

The blind review produced:

| Condition | Ranks | Mean | Median |
|---|---|---:|---:|
| A | 1, 6, 7 | 4.67 | 6 |
| B | 2, 9, 3 | 4.67 | 3 |
| C | 8, 4, 5 | 5.67 | 5 |

The small development comparison was compatible with `A ≈ B > C`, but it is
not a statistically demonstrated difference.

**Observed hierarchy issue.** Even when numeric `v.test` values were visible,
responses frequently placed HIGHER attributes in a `dominant_configuration`
and LOWER attributes in a `secondary_configuration`. This occurred despite
`MilkF` having stronger statistical characterization than `CocoaF`.

**Interpretation.** Availability of statistical information does not
guarantee that the LLM will use it according to its statistical meaning. A
weaker statistical marker was also sometimes rendered as a “moderate” sensory
intensity, conflating statistical evidence strength with sensory intensity.

#### Signed-v.test ordering experiment — `choc2`

**Observed result.** This experiment compared semantic minimal evidence in its
existing order (C) with the same evidence ordered by signed decreasing
`v.test` (E), while explicitly instructing the model to inspect both ends:

```text
C: Crunchy, MilkF, CocoaF, Melting, Caramel, Sweetness
E: Crunchy, CocoaF, Sweetness, Caramel, Melting, MilkF
```

E preserved the signed ordering associated with the `decat()` output structure;
it did not sort by `abs(v.test)` and did not create a primary/secondary label.
The blind review produced:

| Condition | Ranks | Mean | Median |
|---|---|---:|---:|
| C | 2, 4, 2 | 2.67 | 2 |
| E | 6, 1, 5 | 4.00 | 5 |

**Interpretation.** E produced the individually best response but also two
weaker responses. It did not show a consistent improvement over C, and the
explicit instruction to inspect both positive and negative extremes did not
reliably make the local model express a two-sided statistical hierarchy in its
structured interpretation.

This does not show that signed `decat()` order is statistically or
methodologically wrong. It distinguishes methodological justifiability from
empirical prompt-ranking superiority:

```text
methodological justifiability != empirical prompt-ranking superiority
```

**Architectural / methodological consequences.** The canonical statistical
output remains authoritative, while the LLM-facing representation may be a
compact, traceable projection. Numeric visibility and ordering are prompt
design variables, not replacements for the canonical evidence. The results do
not justify a universal winning representation, a universal primary/secondary
taxonomy, or removal of raw statistics from the canonical object.

NaileR should preserve the canonical statistical evidence as the authoritative
result and treat the LLM response as a model-based, revisable interpretation
of that evidence.

The experiments support keeping the LLM-facing evidence as simple as the
analytical task permits, while retaining the complete numerical evidence in
the canonical statistical object. They do not support the stronger claim that
numeric statistics should be removed.

The following concepts must remain distinct:

```text
statistical evidence strength
sensory intensity
effect size
substantive importance
semantic centrality in the LLM interpretation
```

A large absolute `v.test` supports stronger statistical characterization. It
does not by itself imply a more intense sensory perception, a more substantively
important descriptor, or mandatory membership in a “dominant sensory
configuration”.

**Methodological principle.** The LLM interpretation is a prediction
conditional on the evidence, prompt, model, and generation settings.
Variability between plausible responses is expected and should not be confused
with variability in the underlying statistical result. Interpretive
variability is not statistical error. However, horizontal semantic distortion
such as `LOWER -> absent`, `LOWER -> an opposite positive attribute`,
statistical strength becoming sensory intensity, or descriptive evidence
becoming consumer preference remains a fidelity problem.

**Open questions.** It remains unresolved how to expose evidence hierarchy
without encouraging `HIGHER = dominant` and `LOWER = secondary`, how to
preserve signed direction in a compact representation, and whether these
patterns persist with other products, models, independent replications, or a
different response contract.

### 4.6 QDA lessons

**Observed result.** The QDA artifacts preserve statistical evidence while making prompt layers inspectable and ablatable. Full and minimal prompts can be compared without recomputing the analysis.

**Working hypothesis.** Prompt modularity is most useful when it preserves a clear distinction between evidence semantics, interpretive permission, local task binding, and output contract.

**Architectural decision.** QDA's `reusable` block remains local to QDA until its downstream parsing contract is deliberately redesigned. Generalization should not begin by copying that block to other methods.

## 5. TEXTUAL experiments

### 5.1 Modularization PASS 5

**Observed result.** The current TEXTUAL implementation exposes, for each local group, the ordered blocks `context`, `reading`, `question`, `interpretation`, `local_task`, `evidence`, and `output` in `attr(x, "textual_prompt_blocks")`. Disabled optional blocks are represented by `NULL`.

**Observed result.** The detailed renderer uses the headings:

```text
# Introduction
## How to Read the Textual Evidence
# Overall Analytical Request
## Interpretation Rules
# Local Task
# Data
# Required output
```

The minimal renderer retains only:

```text
# Introduction
# Overall Analytical Request
# Data
# Required output
```

**Observed result.** On the realistic `NaileR::fabric` example, changing only `default_blocks` changed prompt length (2615 versus 1453 characters in the manual check) but left `textual_evidence`, `interpretation_input`, and `nail_evidence()` identical. Existing tests additionally verify selected text IDs and parsed fields under identical mocked backend responses.

**Architectural decision.** Preserve the parser and the current output contract in this PASS. The TEXTUAL `output` block can contain a canonical machine-readable contract, but a custom conclusion may remain a human-facing instruction and therefore need not be parser-compatible.

### 5.2 Benchmark 1

**Observed result.** Benchmark 1 compared `M`, `R`, `I`, and `F` with three repetitions per condition, holding corpus, context, question, evidence, model, and other settings constant. The benchmark established the first working ablation vocabulary and supplied examples for human review.

**Methodological caution.** Small blind samples and model responses should not be converted into universal rank claims. The benchmark is evidence about the tested prompt/model combination.

### 5.3 Parser tolerance study

**Observed result.** In the recorded 12-response parser study, all 12 responses failed the strict P0 canonical parser. The average recovered field count was 0 for P0, 4 for the syntax-tolerant P1 condition, and 5 for the semantic-alias P2 condition. Within-group coherence was recovered for 0/12.

**Interpretation.** Human-facing analytical usefulness and machine-readable structured projection are distinct dimensions. A response can provide useful interpretive material while failing an exact downstream schema.

**Working hypothesis.** A tolerant parser could increase recoverability, but semantic aliases may blur levels such as “Higher-Level Interpretation” and “Core textual profile”.

**Architectural decision.** Do not infer from this study that P2 should be implemented. Do not change `.parse_textual_profile_response()` in this journal pass.

### 5.4 Benchmark 2

**Observed result.** Benchmark 2 used the `fabric` group A corpus with eight texts and compared `M`, `R`, `I`, and `F`. In the blind review, `F` occupied ranks 1, 2, and 3, with mean rank 2.0. The `I` condition produced strong interpretive lift, including constructions such as “functional elegance”, but showed more fidelity fragility.

**Interpretation.** The result is compatible with the hypothesis that an interpretation block can promote conceptual lift. It does not establish that the block alone causes better interpretation, nor that every abstraction is unsupported overreach.

### 5.5 Full 2 x 2 x 2 factorial benchmark

**Observed result.** The factorial benchmark tested `M`, `R`, `I`, `L`, `RI`, `RL`, `IL`, and `F`, with three repetitions per cell and a blind review. Mean ranks were:

| Condition | Mean rank |
| --- | ---: |
| `F` | 2.0 |
| `R` | 11.3 |
| `I` | 12.0 |
| `IL` | 12.7 |
| `M` | 13.0 |
| `L` | 15.7 |
| `RL` | 16.0 |
| `RI` | 17.3 |

**Interpretation.** `F` was very strong in this benchmark, but no isolated block explains that result. `RI` did not reproduce `F`; `local_task` alone was insufficient. The pattern is compatible with a block-interaction hypothesis, not proof of one.

**Methodological limitation.** The earlier `M/R/I/F` responses were reused and re-blinded in the factorial packet. This is not a fully independent replication of all eight cells.

### 5.6 Bridge experiment RI / RIB / F

**Observed result.** PASS6E generated 15 new independent responses: five for each of `RI`, `RIB`, and `F`. The exact bridge block was:

```text
# Application

Apply the instructions above to the evidence shown below.
```

Blind mean ranks were `F = 4.6` (median 3), `RIB = 8.2` (median 8), and `RI = 11.2` (median 13). The observed ordering was `F > RIB > RI`.

**Provisional interpretation.** The bridge appears useful in this experiment, but it does not reproduce the full `local_task` condition. This is compatible with `local_task` carrying more than an application reminder.

**Working hypothesis.** `local_task` may combine three functions:

1. scope binding;
2. comparison boundary;
3. instruction binding.

The bridge result does not demonstrate that decomposition causally.

### 5.7 TEXTUAL lessons

**Working hypotheses.** TEXTUAL results suggest that:

- evidence-first should not be reduced to evidence-only;
- interpretive lift and evidence fidelity should be evaluated separately;
- local task binding may interact with interpretation and reading rather than add a simple independent amount of quality;
- prompt order may matter, especially the proximity of task binding to the evidence;
- the analytical prompt and the machine-readable output contract should be evaluated as distinct layers.

**Open question.** Whether these effects persist with independent replications, other models, other corpora, and generated responses that satisfy the parser remains unresolved.

## Cross-method findings

The following are provisional convergences between the QDA and TEXTUAL
experiments. They are working interpretations of the recorded experiments,
not demonstrated laws.

1. **Prompt architecture can vary without changing evidence.** In both QDA
   and TEXTUAL, the prompt structure can be changed while the canonical
   statistical or textual evidence remains unchanged. This conclusion is
   limited to the tested implementations, inputs, and ablations.
2. **The optional blocks are conceptually different.** `reading`,
   `interpretation`, and `local_task` represent different functions even when
   their behavioural effects are not additive or independently measurable.
3. **Evidence-first is not evidence-only.** It should not be reduced to
   paraphrase-only output. A higher-level interpretation is acceptable when
   its support remains traceable and its status is marked appropriately.
4. **Fidelity concerns meaning and status.** Fidelity should preserve the
   meaning and epistemic status of the facts, not require the LLM to retain
   the literal vocabulary of the variables or texts.
5. **Reading rules remain method-specific.** `HIGHER`/`LOWER` QDA markers and
   raw textual responses in TEXTUAL do not have the same epistemic status;
   their reading instructions should therefore not be treated as
   interchangeable wording.
6. **A common conceptual grammar may be possible.** The shared block
   vocabulary appears useful for audit and experiment design, but a universal
   renderer is not currently justified.
7. **Canonical and LLM-facing evidence are different layers.** Canonical
   evidence should remain complete, authoritative, and auditable. LLM-facing
   evidence is a method-specific projection designed for interpretation; the
   QDA experiments do not justify assuming that every method should expose
   the same representation.
8. **Reading mediates between evidence and interpretation.** The `reading`
   block defines the intended semantics of the displayed evidence:

   ```text
   evidence -> reading convention -> model interpretation
   ```

   Its wording is therefore neither evidence nor substantive interpretation.
9. **Interpretation is a revisable prediction.** The LLM output is a
   model-based interpretation conditional on the evidence, prompt, model, and
   generation settings. It is not a computed statistical result.

The following is a theoretical working principle, not a direct experimental
result:

```text
statistical method
    -> produces and defines the evidence

prompt architecture
    -> organizes reasoning from that evidence

LLM
    -> produces the substantive interpretation
```

In prose:

> The statistical method determines the semantics of the evidence; the prompt
> architecture determines how the language model is allowed to reason from
> that evidence.

**Working hypothesis.** This separation may be a useful basis for future
method-specific prompt blocks, provided that the evidence contract remains
independent and auditable.

## 7. Negative and non-confirmatory findings

The following are explicit negative or non-confirmatory findings. They should not be silently turned into positive architectural claims:

- more text does not suffice to produce better interpretation;
- `reading` alone was not systematically better;
- `interpretation` alone does not guarantee evidence fidelity;
- `local_task` alone does not explain the full-condition result;
- `RI` did not reproduce `F` in the factorial benchmark;
- the generic bridge may improve `RI`, but did not reach `F`;
- a strict parser can fail on useful natural-language responses;
- structural prompt compliance is not a proxy for analytical quality.

These negatives support caution about additive block theories. They do not show that any block is useless in every task.

## 8. Emerging theory of a statistical data-analysis prompt

> A good statistical prompt does not merely tell a language model what to say. It organizes the distance the model may take from the evidence while preserving accountability to that evidence.

> The prompt should be viewed less as a set of instructions than as a functional sequence linking analytical context, evidence semantics, interpretive permission, task binding, empirical support, and response form.

The distinction between vertical and horizontal movement is useful:

- **Vertical interpretive lift** builds a higher-level concept from several convergent displayed results. Examples include “functional elegance”, “pragmatic evaluation”, “balance between aesthetics and functionality”, and “simplicity versus sophistication”. These are not automatically hallucinations; their status depends on traceable support.
- **Horizontal semantic distortion** changes the meaning or polarity of a displayed fact. Examples include `not too unpleasant` becoming `pleasant`, `not thick enough` becoming `not durable` or `not robust`, `difficult to maintain` becoming `unsuitable` or `impossible`, `different priorities` becoming `opposing positions`, and a natural appearance becoming `ecological` or `sustainable`.

**Working principle.** Interpretive distance itself is not the problem. Loss of accountability is the problem.

A statistical data-analysis prompt should not be expected to make a stochastic
language model perfectly deterministic or error-free. Its role is to make the
path from evidence to interpretation explicit, inspectable, methodologically
defensible, and revisable.

NaileR does not replace statistical results with an LLM interpretation. It
preserves the statistical evidence, exposes the prompt used to reason from it,
and produces a model-based interpretation that should be treated as revisable
rather than as an additional statistical result.

The retained methodological doctrine is:

> NaileR should not force the LLM to stay inside the vocabulary of the
> evidence; it should force the LLM to remain accountable to the evidence.

These three principles coexist. A higher-level concept may be substantively
useful, but a change in the meaning or epistemic status of a displayed fact is
still a fidelity problem.

## 9. Architectural consequences for NaileR

**Architectural decision.** Keep a shared conceptual vocabulary but use method-specific structured objects and renderers for now.

For QDA, the PoC uses:

```text
context, reading, question, interpretation, local_task,
evidence, reusable, output
```

The QDA `reusable` block remains downstream-specific.

For TEXTUAL, the PoC uses:

```text
context, reading, question, interpretation, local_task,
evidence, output
```

with default optional blocks:

```r
c("reading", "interpretation", "local_task")
```

The preserved combinations are useful for experiments, but they are not yet a public general-purpose prompt grammar.

**Open question.** A universal renderer could reduce duplication but could also erase method-specific epistemic distinctions. Generalization should wait until more methods have been audited.

### Reading as a future editable convention

**Observed in current QDA code.** `reading` is inspectable through
`qda_prompt_blocks` and can be enabled or disabled through the current
optional-block mechanism. It is not directly replaceable through the public
`nail_qda()` API.

**Working design principle.** `reading` should be treated as a method-provided
default convention for reading the evidence, but it should ultimately be
inspectable and editable by the user.

This distinction matters because:

```text
reading != evidence != substantive interpretation
```

`reading` defines how the displayed evidence representation should be
understood. Its default wording must remain method-specific, but an expert
user should eventually be able to replace it without changing canonical
evidence, evidence selection, or statistical computation.

The provisional conceptual status is:

```text
User-facing / editable in principle
-----------------------------------
context
reading
question
interpretation

More strongly method/scope controlled
-------------------------------------
local_task

Protected / evidence-derived
----------------------------
evidence
reusable technical metadata
```

This is a design hypothesis, not an implemented API. Prompt modularity is not
only an optimization mechanism; it is also an auditability and
methodological-justification mechanism.

### Audit chain

The user should be able to inspect the three layers separately:

```text
nail_response()
      ↓ why?
nail_prompt()
      ↓ based on what?
nail_evidence()
```

Conceptually, this is:

```text
model interpretation
      ↓
prompt shown to the model
      ↓
canonical statistical evidence
```

The response is revisable; the prompt makes the reasoning instructions
inspectable; the canonical evidence remains the authoritative statistical
result.

## 10. Open questions

- Which effects replicate with independently generated responses rather than reused benchmark cells?
- How do model size, provider, temperature, and sampling interact with block effects?
- Can parser tolerance be improved without collapsing analytical levels or weakening the output contract?
- Should `local_task` remain one block internally while exposing its three subfunctions for auditing?
- How should a custom human-facing conclusion coexist with a protected machine-readable output contract?
- When does contextual information improve substantive meaning without being mistaken for statistical evidence?
- Can prompt comparison be made reproducible without reducing evaluation to a single composite score?
- Can `reading` become user-editable while preserving method-specific defaults
  and keeping evidence selection/statistical computation unchanged?
- Do output fields such as `dominant_configuration` and
  `secondary_configuration` systematically encourage `HIGHER = dominant` and
  `LOWER = secondary`, even when that is not statistically justified?

For future work in EnTraineR, a related question is whether prompt
architecture can preserve the same separation while adapting an explanation
to its audience:

```text
NaileR:
evidence -> substantive interpretation

EnTraineR:
evidence -> statistical interpretation -> audience-adapted explanation
```

> Can prompt architecture separate evidence semantics, interpretive reasoning,
> and audience adaptation while preserving the statistical meaning of the
> evidence?

## 11. Next methods to test

These are candidates for later PoCs, not implementation decisions:

### CATDES transition

The CATDES architecture has now been audited separately in
`dev/prompt_blocks_poc/catdes_prompt_audit.md`. CATDES is therefore no longer
only an unaudited candidate; its current evidence contract, prompt anatomy,
standard/latent asymmetry, legacy paths, and `isolate.groups` scope tension
have been documented. This documentation does not refactor CATDES.

The next methodological pass should examine:

1. what CATDES canonical evidence objectively means;
2. what CATDES should transform mechanically before the LLM;
3. which percentages and means should remain visible;
4. what the CATDES `reading` block needs to explain;
5. how standard and latent interpretation permissions should be calibrated;
6. how the `isolate.groups` plural/local contradiction should be resolved;
7. whether `reading` should also be user-editable in CATDES.

| Method | Priority | Reason to test |
| --- | --- | --- |
| CONDES | High | Continuous target interpretation separates observed target naming from evidence-based synthesis. |
| CATDES | High | Observed categories and constructed groups require different naming and grounding rules. |
| DESCFREQ | High | Frequency patterns invite substantive characterization while sparse attributes need calibration. |
| CATDES + TEXTUAL | Medium | Tests how statistical anchors and textual enrichment interact. |
| QDA-space | Medium | Latent dimensions need explicit interpretive naming while preserving component evidence. |

Legacy and compatibility paths should be treated as special cases rather than silently folded into a new universal architecture.

No implementation of these next methods is undertaken by this journal entry.
