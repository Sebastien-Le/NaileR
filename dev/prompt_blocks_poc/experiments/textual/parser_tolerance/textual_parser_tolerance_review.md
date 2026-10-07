# TEXTUAL parser tolerance review

P0 is the current strict parser. P1 is a syntax-only prototype. P2 adds only the documented semantic aliases. This compares extraction behavior and does not judge interpretation quality.

## Parser definitions

- P0: current parser, unchanged.
- P1: Markdown markers, case, optional colons, singular/plural variants, multiline values, and IDs embedded in adjacent text.
- P2: P1 plus `Higher-Level Interpretation` / `Higher level interpretation` → `Core textual profile`, `Main themes` / `Key themes` → `Dominant themes`, and `Structured Textual Profile` as a heading-only marker. No coherence value is inferred from prose.

## Study context

The study examines how respondents discuss lower-flying travel choices.

## Analytical question

Identify recurring frames while preserving internal diversity and distinguish interpretation from literal respondent expression.

## Corpus

[TXT000001] I value travel but would reduce flights when alternatives are practical.

[TXT000002] Train travel is preferable when time and cost allow it.

[TXT000003] Family abroad makes complete avoidance of flying difficult.

## Responses

## R01 — condition I — repetition 3

### Raw response

### Structured Textual Profile of Group "A"

#### **Dominant Themes:**
1. **Preference for Lower-Flying Alternatives:**
   - Respondents express a willingness to reduce air travel when feasible alternatives (e.g., train travel) are available.
   - Representative Texts: [TXT000001], [TXT000002]

2. **Practical Constraints on Avoiding Flying:**
   - Some respondents acknowledge that personal circumstances (e.g., family abroad) make complete avoidance of flying difficult.
   - Representative Text: [TXT000003]

#### **Higher-Level Interpretation:**
The group's discourse reflects a **balanced approach to reducing air travel**, where respondents weigh environmental concerns against practical necessities. There is a shared **frame of mindful travel choices**, though individual circumstances lead to variations in how this is expressed.

#### **Internal Diversity:**
- **Proactive Reduction of Flights:** Some respondents actively seek alternatives (e.g., trains) when possible.
- **Reluctant Acceptance of Flying:** Others recognize that flying remains necessary due to personal obligations.

#### **Representative Texts:**
- [TXT000001] – Illustrates a general willingness to reduce flights when alternatives exist.
- [TXT000002] – Highlights a preference for train travel as a practical alternative.
- [TXT000003] – Demonstrates the tension between environmental concerns and personal constraints.

#### **Tension Texts:**
- [TXT000003] – Introduces a **conflict between ideal preferences and real-world limitations**, contrasting with the more optimistic framing in [TXT000001] and [TXT000002].

This profile captures the group's shared orientation toward reducing air travel while acknowledging individual differences in feasibility.

### P0 — strict current parser

Core textual profile: missing — NA
Dominant themes: missing — NA
Within-group coherence: missing — NA
Internal diversity: missing — NA
Representative IDs: missing — NA
Tension IDs: missing — NA
Invalid IDs: (none)

### P1 — syntax tolerant

Core textual profile: missing — NA
Dominant themes: recovered via syntax tolerance — 1. **Preference for Lower-Flying Alternatives; Respondents express a willingness to reduce air travel when feasible alternatives (e.g., train travel) are available
Within-group coherence: missing — NA
Internal diversity: recovered via syntax tolerance — **Proactive Reduction of Flights:** Some respondents actively seek alternatives (e.g., trains) when possible. - **Reluctant Acceptance of Flying:** Others recognize that flying remains necessary due to personal obligations.
Representative IDs: recovered via syntax tolerance — TXT000001; TXT000002; TXT000003
Tension IDs: recovered via syntax tolerance — TXT000003; TXT000001; TXT000002
Invalid IDs: (none)

### P2 — semantic aliases

Core textual profile: recovered via semantic alias — The group's discourse reflects a **balanced approach to reducing air travel**, where respondents weigh environmental concerns against practical necessities. There is a shared **frame of mindful travel choices**, though individual circumstances lead to variations in how this is expressed.
Dominant themes: recovered exactly — 1. **Preference for Lower-Flying Alternatives; Respondents express a willingness to reduce air travel when feasible alternatives (e.g., train travel) are available
Within-group coherence: missing — NA
Internal diversity: recovered exactly — **Proactive Reduction of Flights:** Some respondents actively seek alternatives (e.g., trains) when possible. - **Reluctant Acceptance of Flying:** Others recognize that flying remains necessary due to personal obligations.
Representative IDs: recovered exactly — TXT000001; TXT000002; TXT000003
Tension IDs: recovered exactly — TXT000003; TXT000001; TXT000002
Invalid IDs: (none)

### What changed

P1 recovered: themes; diversity; representative IDs; tension IDs
P2 additionally recovered: core
Still missing: coherence
Invalid IDs observed: (none)

---

## R02 — condition M — repetition 1

### Raw response

### Structured Textual Profile of Group "A"

#### **Dominant Themes:**
1. **Preference for Lower-Flying Alternatives:** Respondents express a willingness to reduce air travel when viable alternatives exist.
2. **Practical Constraints:** Some acknowledge challenges in completely avoiding flying due to personal circumstances (e.g., family abroad).

#### **Higher-Level Interpretation:**
Respondents in Group "A" demonstrate a nuanced approach to reducing air travel, balancing environmental concerns with practical realities. They favor alternatives like train travel when feasible but recognize that complete avoidance may not always be possible.

#### **Internal Diversity:**
- **Proactive Reduction:** Some respondents actively seek alternatives (e.g., trains) to minimize flying.
- **Reluctant Acceptance:** Others acknowledge that personal obligations (e.g., family abroad) limit their ability to avoid flying entirely.

#### **Representative Text IDs:**
- **TXT000001:** Reflects a general willingness to reduce flights when alternatives are available.
- **TXT000002:** Highlights a preference for train travel as a practical alternative.

#### **Tension Text ID:**
- **TXT000003:** Introduces a contrasting perspective where personal circumstances make complete avoidance of flying difficult, highlighting the tension between environmental intent and practical constraints.

### P0 — strict current parser

Core textual profile: missing — NA
Dominant themes: missing — NA
Within-group coherence: missing — NA
Internal diversity: missing — NA
Representative IDs: missing — NA
Tension IDs: missing — NA
Invalid IDs: (none)

### P1 — syntax tolerant

Core textual profile: missing — NA
Dominant themes: recovered via syntax tolerance — 1. **Preference for Lower-Flying Alternatives:** Respondents express a willingness to reduce air travel when viable alternatives exist; 2. **Practical Constraints:** Some acknowledge challenges in completely avoiding flying due to personal circumstances (e.g., family abroad
Within-group coherence: missing — NA
Internal diversity: recovered via syntax tolerance — **Proactive Reduction:** Some respondents actively seek alternatives (e.g., trains) to minimize flying. - **Reluctant Acceptance:** Others acknowledge that personal obligations (e.g., family abroad) limit their ability to avoid flying entirely.
Representative IDs: recovered via syntax tolerance — TXT000001; TXT000002
Tension IDs: recovered via syntax tolerance — TXT000003
Invalid IDs: (none)

### P2 — semantic aliases

Core textual profile: recovered via semantic alias — Respondents in Group "A" demonstrate a nuanced approach to reducing air travel, balancing environmental concerns with practical realities. They favor alternatives like train travel when feasible but recognize that complete avoidance may not always be possible.
Dominant themes: recovered exactly — 1. **Preference for Lower-Flying Alternatives:** Respondents express a willingness to reduce air travel when viable alternatives exist; 2. **Practical Constraints:** Some acknowledge challenges in completely avoiding flying due to personal circumstances (e.g., family abroad
Within-group coherence: missing — NA
Internal diversity: recovered exactly — **Proactive Reduction:** Some respondents actively seek alternatives (e.g., trains) to minimize flying. - **Reluctant Acceptance:** Others acknowledge that personal obligations (e.g., family abroad) limit their ability to avoid flying entirely.
Representative IDs: recovered exactly — TXT000001; TXT000002
Tension IDs: recovered exactly — TXT000003
Invalid IDs: (none)

### What changed

P1 recovered: themes; diversity; representative IDs; tension IDs
P2 additionally recovered: core
Still missing: coherence
Invalid IDs observed: (none)

---

## R03 — condition R — repetition 3

### Raw response

### Structured Textual Profile of Group "A"

#### **Dominant Themes:**
1. **Preference for Lower-Flying Alternatives:**
   - Respondents express a willingness to reduce air travel when feasible alternatives exist.
   - Train travel is highlighted as a preferred option when time and cost constraints permit.

2. **Practical Constraints on Avoiding Flying:**
   - Some respondents acknowledge that personal circumstances (e.g., family abroad) make complete avoidance of flying difficult.

#### **Higher-Level Interpretation:**
The group demonstrates a nuanced approach to lower-flying travel choices, balancing environmental concerns with practical realities. While there is a clear preference for alternatives like train travel, personal obligations sometimes necessitate air travel.

#### **Internal Diversity:**
- **Proactive Reduction of Flights:** Some respondents actively seek alternatives (e.g., TXT000001, TXT000002).
- **Practical Limitations:** Others recognize that complete avoidance is not always possible (e.g., TXT000003).

#### **Representative Text IDs:**
- **TXT000001:** Reflects the general sentiment of valuing travel but reducing flights when alternatives are available.
- **TXT000002:** Highlights the preference for train travel as a practical alternative.

#### **Tension Text ID:**
- **TXT000003:** Introduces a contrasting perspective where personal circumstances limit the ability to avoid flying entirely.

This profile captures the group's internal diversity while identifying the dominant themes and interpretations.

### P0 — strict current parser

Core textual profile: missing — NA
Dominant themes: missing — NA
Within-group coherence: missing — NA
Internal diversity: missing — NA
Representative IDs: missing — NA
Tension IDs: missing — NA
Invalid IDs: (none)

### P1 — syntax tolerant

Core textual profile: missing — NA
Dominant themes: recovered via syntax tolerance — 1. **Preference for Lower-Flying Alternatives; Respondents express a willingness to reduce air travel when feasible alternatives exist; Train travel is highlighted as a preferred option when time and cost constraints permit; 2. **Practical Constraints on Avoiding Flying; Some respondents acknowledge that personal circumstances (e.g., family abroad) make complete avoidance of flying difficult
Within-group coherence: missing — NA
Internal diversity: recovered via syntax tolerance — **Proactive Reduction of Flights:** Some respondents actively seek alternatives (e.g., TXT000001, TXT000002). - **Practical Limitations:** Others recognize that complete avoidance is not always possible (e.g., TXT000003).
Representative IDs: recovered via syntax tolerance — TXT000001; TXT000002
Tension IDs: recovered via syntax tolerance — TXT000003
Invalid IDs: (none)

### P2 — semantic aliases

Core textual profile: recovered via semantic alias — The group demonstrates a nuanced approach to lower-flying travel choices, balancing environmental concerns with practical realities. While there is a clear preference for alternatives like train travel, personal obligations sometimes necessitate air travel.
Dominant themes: recovered exactly — 1. **Preference for Lower-Flying Alternatives; Respondents express a willingness to reduce air travel when feasible alternatives exist; Train travel is highlighted as a preferred option when time and cost constraints permit; 2. **Practical Constraints on Avoiding Flying; Some respondents acknowledge that personal circumstances (e.g., family abroad) make complete avoidance of flying difficult
Within-group coherence: missing — NA
Internal diversity: recovered exactly — **Proactive Reduction of Flights:** Some respondents actively seek alternatives (e.g., TXT000001, TXT000002). - **Practical Limitations:** Others recognize that complete avoidance is not always possible (e.g., TXT000003).
Representative IDs: recovered exactly — TXT000001; TXT000002
Tension IDs: recovered exactly — TXT000003
Invalid IDs: (none)

### What changed

P1 recovered: themes; diversity; representative IDs; tension IDs
P2 additionally recovered: core
Still missing: coherence
Invalid IDs observed: (none)

---

## R04 — condition M — repetition 2

### Raw response

### Structured Textual Profile of Group "A"

#### **Dominant Themes:**
1. **Preference for Lower-Flying Alternatives:** Respondents express a willingness to reduce air travel when viable alternatives exist.
2. **Practical Constraints:** Some acknowledge challenges in completely avoiding flying due to personal circumstances (e.g., family abroad).

#### **Higher-Level Interpretation:**
Respondents in Group "A" demonstrate a nuanced approach to reducing air travel, balancing environmental concerns with practical realities. They favor alternatives like train travel when feasible but recognize that complete avoidance may not always be possible.

#### **Internal Diversity:**
- **Proactive Reduction:** Some respondents actively seek alternatives (e.g., train travel) to minimize flying.
- **Personal Constraints:** Others highlight external factors (e.g., family obligations) that limit their ability to avoid flying entirely.

#### **Representative Text IDs:**
- **TXT000001:** Reflects a general willingness to reduce flights when alternatives are available.
- **TXT000002:** Emphasizes a preference for train travel as a practical alternative.

#### **Tension Text ID:**
- **TXT000003:** Introduces a contrasting perspective by acknowledging the difficulty of completely avoiding flying due to personal circumstances, highlighting the tension between environmental intentions and real-world constraints.

### P0 — strict current parser

Core textual profile: missing — NA
Dominant themes: missing — NA
Within-group coherence: missing — NA
Internal diversity: missing — NA
Representative IDs: missing — NA
Tension IDs: missing — NA
Invalid IDs: (none)

### P1 — syntax tolerant

Core textual profile: missing — NA
Dominant themes: recovered via syntax tolerance — 1. **Preference for Lower-Flying Alternatives:** Respondents express a willingness to reduce air travel when viable alternatives exist; 2. **Practical Constraints:** Some acknowledge challenges in completely avoiding flying due to personal circumstances (e.g., family abroad
Within-group coherence: missing — NA
Internal diversity: recovered via syntax tolerance — **Proactive Reduction:** Some respondents actively seek alternatives (e.g., train travel) to minimize flying. - **Personal Constraints:** Others highlight external factors (e.g., family obligations) that limit their ability to avoid flying entirely.
Representative IDs: recovered via syntax tolerance — TXT000001; TXT000002
Tension IDs: recovered via syntax tolerance — TXT000003
Invalid IDs: (none)

### P2 — semantic aliases

Core textual profile: recovered via semantic alias — Respondents in Group "A" demonstrate a nuanced approach to reducing air travel, balancing environmental concerns with practical realities. They favor alternatives like train travel when feasible but recognize that complete avoidance may not always be possible.
Dominant themes: recovered exactly — 1. **Preference for Lower-Flying Alternatives:** Respondents express a willingness to reduce air travel when viable alternatives exist; 2. **Practical Constraints:** Some acknowledge challenges in completely avoiding flying due to personal circumstances (e.g., family abroad
Within-group coherence: missing — NA
Internal diversity: recovered exactly — **Proactive Reduction:** Some respondents actively seek alternatives (e.g., train travel) to minimize flying. - **Personal Constraints:** Others highlight external factors (e.g., family obligations) that limit their ability to avoid flying entirely.
Representative IDs: recovered exactly — TXT000001; TXT000002
Tension IDs: recovered exactly — TXT000003
Invalid IDs: (none)

### What changed

P1 recovered: themes; diversity; representative IDs; tension IDs
P2 additionally recovered: core
Still missing: coherence
Invalid IDs observed: (none)

---

## R05 — condition F — repetition 3

### Raw response

### Structured Textual Profile of Group "A"

#### **Dominant Themes:**
1. **Preference for Lower-Flying Travel Choices:**
   - Respondents express a willingness to reduce air travel when alternatives are available.
   - Train travel is highlighted as a preferred alternative when feasible.

2. **Practical Constraints on Avoiding Flying:**
   - Personal circumstances (e.g., family abroad) make complete avoidance of flying difficult.

#### **Higher-Level Interpretation:**
The group demonstrates a **balanced approach to reducing air travel**, weighing environmental concerns against practical necessities. While there is a clear preference for alternatives like train travel, personal obligations (such as maintaining connections with family abroad) limit the ability to completely eliminate flying.

#### **Internal Diversity:**
- **Proactive Reduction of Flights:** Some respondents actively seek alternatives (e.g., trains) when possible (TXT000001, TXT000002).
- **Practical Limitations:** Others acknowledge that flying remains necessary due to personal circumstances (TXT000003).

#### **Representative Text IDs:**
- **TXT000001:** Reflects the general sentiment of valuing travel while seeking alternatives.
- **TXT000002:** Highlights the preference for train travel as a practical alternative.

#### **Tension Text ID:**
- **TXT000003:** Introduces a contrasting perspective where flying is unavoidable due to personal obligations, creating tension with the broader theme of reducing air travel.

This profile captures the group's nuanced stance on lower-flying travel choices, balancing ideal preferences with real-world constraints.

### P0 — strict current parser

Core textual profile: missing — NA
Dominant themes: missing — NA
Within-group coherence: missing — NA
Internal diversity: missing — NA
Representative IDs: missing — NA
Tension IDs: missing — NA
Invalid IDs: (none)

### P1 — syntax tolerant

Core textual profile: missing — NA
Dominant themes: recovered via syntax tolerance — 1. **Preference for Lower-Flying Travel Choices; Respondents express a willingness to reduce air travel when alternatives are available; Train travel is highlighted as a preferred alternative when feasible; 2. **Practical Constraints on Avoiding Flying; Personal circumstances (e.g., family abroad) make complete avoidance of flying difficult
Within-group coherence: missing — NA
Internal diversity: recovered via syntax tolerance — **Proactive Reduction of Flights:** Some respondents actively seek alternatives (e.g., trains) when possible (TXT000001, TXT000002). - **Practical Limitations:** Others acknowledge that flying remains necessary due to personal circumstances (TXT000003).
Representative IDs: recovered via syntax tolerance — TXT000001; TXT000002
Tension IDs: recovered via syntax tolerance — TXT000003
Invalid IDs: (none)

### P2 — semantic aliases

Core textual profile: recovered via semantic alias — The group demonstrates a **balanced approach to reducing air travel**, weighing environmental concerns against practical necessities. While there is a clear preference for alternatives like train travel, personal obligations (such as maintaining connections with family abroad) limit the ability to completely eliminate flying.
Dominant themes: recovered exactly — 1. **Preference for Lower-Flying Travel Choices; Respondents express a willingness to reduce air travel when alternatives are available; Train travel is highlighted as a preferred alternative when feasible; 2. **Practical Constraints on Avoiding Flying; Personal circumstances (e.g., family abroad) make complete avoidance of flying difficult
Within-group coherence: missing — NA
Internal diversity: recovered exactly — **Proactive Reduction of Flights:** Some respondents actively seek alternatives (e.g., trains) when possible (TXT000001, TXT000002). - **Practical Limitations:** Others acknowledge that flying remains necessary due to personal circumstances (TXT000003).
Representative IDs: recovered exactly — TXT000001; TXT000002
Tension IDs: recovered exactly — TXT000003
Invalid IDs: (none)

### What changed

P1 recovered: themes; diversity; representative IDs; tension IDs
P2 additionally recovered: core
Still missing: coherence
Invalid IDs observed: (none)

---

## R06 — condition I — repetition 1

### Raw response

### Structured Textual Profile of Group "A"

#### **Dominant Themes:**
1. **Preference for Lower-Flying Alternatives:**
   - Respondents express a willingness to reduce air travel when feasible alternatives (e.g., train travel) are available.
   - Representative Texts: [TXT000001], [TXT000002]

2. **Practical Constraints on Avoiding Flying:**
   - Some respondents acknowledge that personal circumstances (e.g., family abroad) make complete avoidance of flying difficult.
   - Representative Text: [TXT000003]

#### **Higher-Level Interpretation:**
The group exhibits a shared discourse around **balancing environmental concerns with practical realities**. While there is a clear preference for reducing air travel when alternatives exist, personal obligations sometimes limit the ability to fully adopt lower-flying choices.

#### **Internal Diversity:**
- **Proactive Reduction of Flights:** Some respondents actively seek alternatives (e.g., trains) to minimize flying.
- **Reluctant Acceptance of Flying:** Others recognize that flying remains necessary due to personal commitments.

#### **Representative Text IDs:**
- [TXT000001] – Illustrates the willingness to reduce flights when alternatives are practical.
- [TXT000002] – Highlights a preference for train travel as a substitute.
- [TXT000003] – Reflects the tension between environmental preferences and personal constraints.

#### **Tension Text ID:**
- [TXT000003] – Demonstrates the conflict between the desire to reduce flying and the necessity of air travel due to family obligations.

This profile captures the nuanced perspectives within the group while identifying a coherent overarching theme.

### P0 — strict current parser

Core textual profile: missing — NA
Dominant themes: missing — NA
Within-group coherence: missing — NA
Internal diversity: missing — NA
Representative IDs: missing — NA
Tension IDs: missing — NA
Invalid IDs: (none)

### P1 — syntax tolerant

Core textual profile: missing — NA
Dominant themes: recovered via syntax tolerance — 1. **Preference for Lower-Flying Alternatives; Respondents express a willingness to reduce air travel when feasible alternatives (e.g., train travel) are available
Within-group coherence: missing — NA
Internal diversity: recovered via syntax tolerance — **Proactive Reduction of Flights:** Some respondents actively seek alternatives (e.g., trains) to minimize flying. - **Reluctant Acceptance of Flying:** Others recognize that flying remains necessary due to personal commitments.
Representative IDs: recovered via syntax tolerance — TXT000001; TXT000002; TXT000003
Tension IDs: recovered via syntax tolerance — TXT000003
Invalid IDs: (none)

### P2 — semantic aliases

Core textual profile: recovered via semantic alias — The group exhibits a shared discourse around **balancing environmental concerns with practical realities**. While there is a clear preference for reducing air travel when alternatives exist, personal obligations sometimes limit the ability to fully adopt lower-flying choices.
Dominant themes: recovered exactly — 1. **Preference for Lower-Flying Alternatives; Respondents express a willingness to reduce air travel when feasible alternatives (e.g., train travel) are available
Within-group coherence: missing — NA
Internal diversity: recovered exactly — **Proactive Reduction of Flights:** Some respondents actively seek alternatives (e.g., trains) to minimize flying. - **Reluctant Acceptance of Flying:** Others recognize that flying remains necessary due to personal commitments.
Representative IDs: recovered exactly — TXT000001; TXT000002; TXT000003
Tension IDs: recovered exactly — TXT000003
Invalid IDs: (none)

### What changed

P1 recovered: themes; diversity; representative IDs; tension IDs
P2 additionally recovered: core
Still missing: coherence
Invalid IDs observed: (none)

---

## R07 — condition I — repetition 2

### Raw response

### Structured Textual Profile of Group "A"

#### **Dominant Themes:**
1. **Preference for Lower-Flying Alternatives:**
   - Respondents express a willingness to reduce air travel when feasible alternatives (e.g., train travel) are available.
   - Representative Texts: [TXT000001], [TXT000002]

2. **Practical Constraints on Avoiding Flying:**
   - Some respondents acknowledge that personal circumstances (e.g., family abroad) make complete avoidance of flying difficult.
   - Representative Text: [TXT000003]

#### **Higher-Level Interpretation:**
The group demonstrates a **shared discourse of environmental consciousness**, where respondents recognize the value of reducing air travel for sustainability. However, their ability to act on this preference varies based on practical considerations such as cost, time, and personal obligations.

#### **Internal Diversity:**
- **Proactive Reduction of Flights:** Some respondents actively seek alternatives (e.g., trains) when possible ([TXT000001], [TXT000002]).
- **Reluctant Acceptance of Flying:** Others acknowledge that flying remains necessary due to external factors ([TXT000003]).

#### **Representative Text IDs:**
- [TXT000001] (Values travel but reduces flights when alternatives exist)
- [TXT000002] (Prefers train travel when feasible)

#### **Tension Text ID:**
- [TXT000003] (Family obligations make complete avoidance of flying difficult, highlighting a conflict between environmental preferences and personal constraints)

This profile reflects a nuanced balance between environmental awareness and practical realities in travel choices.

### P0 — strict current parser

Core textual profile: missing — NA
Dominant themes: missing — NA
Within-group coherence: missing — NA
Internal diversity: missing — NA
Representative IDs: missing — NA
Tension IDs: missing — NA
Invalid IDs: (none)

### P1 — syntax tolerant

Core textual profile: missing — NA
Dominant themes: recovered via syntax tolerance — 1. **Preference for Lower-Flying Alternatives; Respondents express a willingness to reduce air travel when feasible alternatives (e.g., train travel) are available
Within-group coherence: missing — NA
Internal diversity: recovered via syntax tolerance — **Proactive Reduction of Flights:** Some respondents actively seek alternatives (e.g., trains) when possible ([TXT000001], [TXT000002]). - **Reluctant Acceptance of Flying:** Others acknowledge that flying remains necessary due to external factors ([TXT000003]).
Representative IDs: recovered via syntax tolerance — TXT000001; TXT000002; TXT000003
Tension IDs: recovered via syntax tolerance — TXT000003
Invalid IDs: (none)

### P2 — semantic aliases

Core textual profile: recovered via semantic alias — The group demonstrates a **shared discourse of environmental consciousness**, where respondents recognize the value of reducing air travel for sustainability. However, their ability to act on this preference varies based on practical considerations such as cost, time, and personal obligations.
Dominant themes: recovered exactly — 1. **Preference for Lower-Flying Alternatives; Respondents express a willingness to reduce air travel when feasible alternatives (e.g., train travel) are available
Within-group coherence: missing — NA
Internal diversity: recovered exactly — **Proactive Reduction of Flights:** Some respondents actively seek alternatives (e.g., trains) when possible ([TXT000001], [TXT000002]). - **Reluctant Acceptance of Flying:** Others acknowledge that flying remains necessary due to external factors ([TXT000003]).
Representative IDs: recovered exactly — TXT000001; TXT000002; TXT000003
Tension IDs: recovered exactly — TXT000003
Invalid IDs: (none)

### What changed

P1 recovered: themes; diversity; representative IDs; tension IDs
P2 additionally recovered: core
Still missing: coherence
Invalid IDs observed: (none)

---

## R08 — condition F — repetition 2

### Raw response

### Structured Textual Profile of Group "A"

#### **Dominant Themes:**
1. **Preference for Lower-Flying Travel Choices:**
   - Respondents express a willingness to reduce air travel when alternatives are available.
   - Train travel is highlighted as a preferred alternative when feasible.

2. **Practical Constraints on Avoiding Flying:**
   - Some respondents acknowledge that personal circumstances (e.g., family abroad) make complete avoidance of flying difficult.

#### **Higher-Level Interpretation:**
The group demonstrates a **balanced approach to reducing air travel**, recognizing both the desirability of alternatives (like trains) and the practical limitations that may prevent complete avoidance of flying. Their discourse reflects a **pragmatic stance**, where environmental or personal preferences are weighed against real-world constraints.

#### **Internal Diversity:**
- **Proactive Reduction of Flights:** Some respondents emphasize actively seeking alternatives (e.g., TXT000001, TXT000002).
- **Acknowledgment of Necessity:** Others highlight unavoidable circumstances that necessitate flying (e.g., TXT000003).

#### **Representative Text IDs:**
- **TXT000001** ("I value travel but would reduce flights when alternatives are practical.") – Captures the core theme of balancing travel preferences with lower-flying choices.
- **TXT000002** ("Train travel is preferable when time and cost allow it.") – Illustrates the preference for alternatives like trains.

#### **Tension Text ID:**
- **TXT000003** ("Family abroad makes complete avoidance of flying difficult.") – Introduces a contrasting perspective where personal circumstances limit the ability to avoid flying entirely.

This profile preserves the internal diversity of the group while identifying a coherent, pragmatic interpretation of their discourse.

### P0 — strict current parser

Core textual profile: missing — NA
Dominant themes: missing — NA
Within-group coherence: missing — NA
Internal diversity: missing — NA
Representative IDs: missing — NA
Tension IDs: missing — NA
Invalid IDs: (none)

### P1 — syntax tolerant

Core textual profile: missing — NA
Dominant themes: recovered via syntax tolerance — 1. **Preference for Lower-Flying Travel Choices; Respondents express a willingness to reduce air travel when alternatives are available; Train travel is highlighted as a preferred alternative when feasible; 2. **Practical Constraints on Avoiding Flying; Some respondents acknowledge that personal circumstances (e.g., family abroad) make complete avoidance of flying difficult
Within-group coherence: missing — NA
Internal diversity: recovered via syntax tolerance — **Proactive Reduction of Flights:** Some respondents emphasize actively seeking alternatives (e.g., TXT000001, TXT000002). - **Acknowledgment of Necessity:** Others highlight unavoidable circumstances that necessitate flying (e.g., TXT000003).
Representative IDs: recovered via syntax tolerance — TXT000001; TXT000002
Tension IDs: recovered via syntax tolerance — TXT000003
Invalid IDs: (none)

### P2 — semantic aliases

Core textual profile: recovered via semantic alias — The group demonstrates a **balanced approach to reducing air travel**, recognizing both the desirability of alternatives (like trains) and the practical limitations that may prevent complete avoidance of flying. Their discourse reflects a **pragmatic stance**, where environmental or personal preferences are weighed against real-world constraints.
Dominant themes: recovered exactly — 1. **Preference for Lower-Flying Travel Choices; Respondents express a willingness to reduce air travel when alternatives are available; Train travel is highlighted as a preferred alternative when feasible; 2. **Practical Constraints on Avoiding Flying; Some respondents acknowledge that personal circumstances (e.g., family abroad) make complete avoidance of flying difficult
Within-group coherence: missing — NA
Internal diversity: recovered exactly — **Proactive Reduction of Flights:** Some respondents emphasize actively seeking alternatives (e.g., TXT000001, TXT000002). - **Acknowledgment of Necessity:** Others highlight unavoidable circumstances that necessitate flying (e.g., TXT000003).
Representative IDs: recovered exactly — TXT000001; TXT000002
Tension IDs: recovered exactly — TXT000003
Invalid IDs: (none)

### What changed

P1 recovered: themes; diversity; representative IDs; tension IDs
P2 additionally recovered: core
Still missing: coherence
Invalid IDs observed: (none)

---

## R09 — condition R — repetition 2

### Raw response

### Structured Textual Profile of Group "A"

#### **Dominant Themes:**
1. **Preference for Lower-Flying Alternatives:**
   - Respondents express a willingness to reduce air travel when feasible alternatives (e.g., train travel) are available.
   - Representative Text IDs: [TXT000001], [TXT000002]

2. **Practical Constraints on Avoiding Flying:**
   - Some respondents acknowledge that personal circumstances (e.g., family abroad) make complete avoidance of flying difficult.
   - Representative Text ID: [TXT000003]

#### **Higher-Level Interpretation:**
The group demonstrates a nuanced approach to lower-flying travel choices, balancing environmental concerns with practical realities. While there is a clear preference for alternatives like train travel when possible, personal obligations sometimes necessitate air travel.

#### **Internal Diversity:**
- **Proactive Reduction of Flights:** Some respondents actively seek alternatives to flying (e.g., [TXT000001], [TXT000002]).
- **Reluctant Acceptance of Flying:** Others recognize that flying may be unavoidable due to personal circumstances (e.g., [TXT000003]).

#### **Representative Text IDs:**
- [TXT000001] – Reflects the value placed on reducing flights when alternatives exist.
- [TXT000002] – Highlights the preference for train travel as a lower-flying alternative.
- [TXT000003] – Illustrates the tension between environmental preferences and personal constraints.

#### **Tension Text ID:**
- [TXT000003] – Contrasts with the proactive reduction of flights seen in other responses, highlighting the conflict between ideals and practicalities.

This profile captures the group's discourse while preserving the diversity of perspectives within it.

### P0 — strict current parser

Core textual profile: missing — NA
Dominant themes: missing — NA
Within-group coherence: missing — NA
Internal diversity: missing — NA
Representative IDs: invalid — TXT000001; TXT000002; 2. **Practical Constraints on Avoiding Flying; Some respondents acknowledge that personal circumstances (e.g; family abroad) make complete avoidance of flying difficult; Representative Text ID: [TXT000003; Higher-Level Interpretation; The group demonstrates a nuanced approach to lower-flying travel choices; balancing environmental concerns with practical realities. While there is a clear preference for alternatives like train travel when possible; personal obligations sometimes necessitate air travel; Internal Diversity; Proactive Reduction of Flights:** Some respondents actively seek alternatives to flying (e.g; Reluctant Acceptance of Flying:** Others recognize that flying may be unavoidable due to personal circumstances (e.g; TXT000003; Representative Text IDs; TXT000001] – Reflects the value placed on reducing flights when alternatives exist; TXT000002] – Highlights the preference for train travel as a lower-flying alternative; TXT000003] – Illustrates the tension between environmental preferences and personal constraints; Tension Text ID; TXT000003] – Contrasts with the proactive reduction of flights seen in other responses; highlighting the conflict between ideals and practicalities; This profile captures the group's discourse while preserving the diversity of perspectives within it
Tension IDs: missing — NA
Invalid IDs: 2. **Practical Constraints on Avoiding Flying; Some respondents acknowledge that personal circumstances (e.g; family abroad) make complete avoidance of flying difficult; Representative Text ID: [TXT000003; Higher-Level Interpretation; The group demonstrates a nuanced approach to lower-flying travel choices; balancing environmental concerns with practical realities. While there is a clear preference for alternatives like train travel when possible; personal obligations sometimes necessitate air travel; Internal Diversity; Proactive Reduction of Flights:** Some respondents actively seek alternatives to flying (e.g; Reluctant Acceptance of Flying:** Others recognize that flying may be unavoidable due to personal circumstances (e.g; Representative Text IDs; TXT000001] – Reflects the value placed on reducing flights when alternatives exist; TXT000002] – Highlights the preference for train travel as a lower-flying alternative; TXT000003] – Illustrates the tension between environmental preferences and personal constraints; Tension Text ID; TXT000003] – Contrasts with the proactive reduction of flights seen in other responses; highlighting the conflict between ideals and practicalities; This profile captures the group's discourse while preserving the diversity of perspectives within it

### P1 — syntax tolerant

Core textual profile: missing — NA
Dominant themes: recovered via syntax tolerance — 1. **Preference for Lower-Flying Alternatives; Respondents express a willingness to reduce air travel when feasible alternatives (e.g., train travel) are available
Within-group coherence: missing — NA
Internal diversity: recovered via syntax tolerance — **Proactive Reduction of Flights:** Some respondents actively seek alternatives to flying (e.g., [TXT000001], [TXT000002]). - **Reluctant Acceptance of Flying:** Others recognize that flying may be unavoidable due to personal circumstances (e.g., [TXT000003]).
Representative IDs: recovered via syntax tolerance — TXT000001; TXT000002; TXT000003
Tension IDs: recovered via syntax tolerance — TXT000003
Invalid IDs: (none)

### P2 — semantic aliases

Core textual profile: recovered via semantic alias — The group demonstrates a nuanced approach to lower-flying travel choices, balancing environmental concerns with practical realities. While there is a clear preference for alternatives like train travel when possible, personal obligations sometimes necessitate air travel.
Dominant themes: recovered exactly — 1. **Preference for Lower-Flying Alternatives; Respondents express a willingness to reduce air travel when feasible alternatives (e.g., train travel) are available
Within-group coherence: missing — NA
Internal diversity: recovered exactly — **Proactive Reduction of Flights:** Some respondents actively seek alternatives to flying (e.g., [TXT000001], [TXT000002]). - **Reluctant Acceptance of Flying:** Others recognize that flying may be unavoidable due to personal circumstances (e.g., [TXT000003]).
Representative IDs: recovered exactly — TXT000001; TXT000002; TXT000003
Tension IDs: recovered exactly — TXT000003
Invalid IDs: (none)

### What changed

P1 recovered: themes; diversity; representative IDs; tension IDs
P2 additionally recovered: core
Still missing: coherence
Invalid IDs observed: 2. **Practical Constraints on Avoiding Flying; Some respondents acknowledge that personal circumstances (e.g; family abroad) make complete avoidance of flying difficult; Representative Text ID: [TXT000003; Higher-Level Interpretation; The group demonstrates a nuanced approach to lower-flying travel choices; balancing environmental concerns with practical realities. While there is a clear preference for alternatives like train travel when possible; personal obligations sometimes necessitate air travel; Internal Diversity; Proactive Reduction of Flights:** Some respondents actively seek alternatives to flying (e.g; Reluctant Acceptance of Flying:** Others recognize that flying may be unavoidable due to personal circumstances (e.g; Representative Text IDs; TXT000001] – Reflects the value placed on reducing flights when alternatives exist; TXT000002] – Highlights the preference for train travel as a lower-flying alternative; TXT000003] – Illustrates the tension between environmental preferences and personal constraints; Tension Text ID; TXT000003] – Contrasts with the proactive reduction of flights seen in other responses; highlighting the conflict between ideals and practicalities; This profile captures the group's discourse while preserving the diversity of perspectives within it

---

## R10 — condition F — repetition 1

### Raw response

### Structured Textual Profile of Group "A"

#### **Dominant Themes:**
1. **Preference for Lower-Flying Travel Choices:**
   - Respondents express a willingness to reduce air travel when alternatives are available.
   - Train travel is highlighted as a preferred alternative when feasible.

2. **Practical Constraints on Avoiding Flying:**
   - Some respondents acknowledge that personal circumstances (e.g., family abroad) make complete avoidance of flying difficult.

#### **Higher-Level Interpretation:**
The group demonstrates a **balanced approach** to reducing air travel, recognizing both the **desirability of alternatives** (e.g., trains) and the **real-world limitations** that may prevent complete avoidance of flying. Their discourse reflects a **pragmatic stance**, where environmental or personal values are weighed against practical constraints.

#### **Internal Diversity:**
- **Proactive Reduction of Flights:** Some respondents emphasize actively seeking alternatives (e.g., trains) when possible (TXT000001, TXT000002).
- **Acknowledgment of Necessity:** Others highlight unavoidable circumstances that necessitate flying (TXT000003).

#### **Representative Text IDs:**
- **TXT000001** ("I value travel but would reduce flights when alternatives are practical.") – Captures the **balanced approach** of valuing travel while seeking alternatives.
- **TXT000002** ("Train travel is preferable when time and cost allow it.") – Illustrates the **preference for lower-flying alternatives**.

#### **Tension Text ID:**
- **TXT000003** ("Family abroad makes complete avoidance of flying difficult.") – Introduces a **contrasting perspective** where personal circumstances limit the ability to fully reduce flying.

This profile preserves the **internal diversity** within the group while identifying a **coherent interpretive frame** of pragmatic environmental consciousness.

### P0 — strict current parser

Core textual profile: missing — NA
Dominant themes: missing — NA
Within-group coherence: missing — NA
Internal diversity: missing — NA
Representative IDs: missing — NA
Tension IDs: missing — NA
Invalid IDs: (none)

### P1 — syntax tolerant

Core textual profile: missing — NA
Dominant themes: recovered via syntax tolerance — 1. **Preference for Lower-Flying Travel Choices; Respondents express a willingness to reduce air travel when alternatives are available; Train travel is highlighted as a preferred alternative when feasible; 2. **Practical Constraints on Avoiding Flying; Some respondents acknowledge that personal circumstances (e.g., family abroad) make complete avoidance of flying difficult
Within-group coherence: missing — NA
Internal diversity: recovered via syntax tolerance — **Proactive Reduction of Flights:** Some respondents emphasize actively seeking alternatives (e.g., trains) when possible (TXT000001, TXT000002). - **Acknowledgment of Necessity:** Others highlight unavoidable circumstances that necessitate flying (TXT000003).
Representative IDs: recovered via syntax tolerance — TXT000001; TXT000002
Tension IDs: recovered via syntax tolerance — TXT000003
Invalid IDs: (none)

### P2 — semantic aliases

Core textual profile: recovered via semantic alias — The group demonstrates a **balanced approach** to reducing air travel, recognizing both the **desirability of alternatives** (e.g., trains) and the **real-world limitations** that may prevent complete avoidance of flying. Their discourse reflects a **pragmatic stance**, where environmental or personal values are weighed against practical constraints.
Dominant themes: recovered exactly — 1. **Preference for Lower-Flying Travel Choices; Respondents express a willingness to reduce air travel when alternatives are available; Train travel is highlighted as a preferred alternative when feasible; 2. **Practical Constraints on Avoiding Flying; Some respondents acknowledge that personal circumstances (e.g., family abroad) make complete avoidance of flying difficult
Within-group coherence: missing — NA
Internal diversity: recovered exactly — **Proactive Reduction of Flights:** Some respondents emphasize actively seeking alternatives (e.g., trains) when possible (TXT000001, TXT000002). - **Acknowledgment of Necessity:** Others highlight unavoidable circumstances that necessitate flying (TXT000003).
Representative IDs: recovered exactly — TXT000001; TXT000002
Tension IDs: recovered exactly — TXT000003
Invalid IDs: (none)

### What changed

P1 recovered: themes; diversity; representative IDs; tension IDs
P2 additionally recovered: core
Still missing: coherence
Invalid IDs observed: (none)

---

## R11 — condition R — repetition 1

### Raw response

### Structured Textual Profile of Group "A"

#### **Dominant Themes:**
1. **Preference for Lower-Flying Alternatives:**
   - Respondents express a willingness to reduce air travel when feasible alternatives exist.
   - Train travel is highlighted as a preferred option when time and cost constraints permit.

2. **Practical Challenges in Avoiding Flying:**
   - Some respondents acknowledge that personal circumstances (e.g., family abroad) make complete avoidance of flying difficult.

#### **Higher-Level Interpretation:**
The group demonstrates a nuanced approach to lower-flying travel choices, balancing environmental concerns with practical realities. While there is a clear preference for alternatives like train travel, personal obligations sometimes necessitate air travel.

#### **Internal Diversity:**
- **Proactive Reduction of Flights:** Some respondents actively seek alternatives (e.g., TXT000001, TXT000002).
- **Practical Constraints:** Others recognize that flying may still be necessary due to personal circumstances (e.g., TXT000003).

#### **Representative Text IDs:**
- **TXT000001:** Reflects the general sentiment of valuing travel while reducing flights when alternatives are available.
- **TXT000002:** Illustrates the preference for train travel as a practical alternative.

#### **Tension Text ID:**
- **TXT000003:** Introduces a contrasting perspective where personal obligations complicate the avoidance of flying, highlighting internal diversity within the group.

This profile captures the group's balanced discourse on lower-flying travel choices, acknowledging both proactive efforts and practical constraints.

### P0 — strict current parser

Core textual profile: missing — NA
Dominant themes: missing — NA
Within-group coherence: missing — NA
Internal diversity: missing — NA
Representative IDs: missing — NA
Tension IDs: missing — NA
Invalid IDs: (none)

### P1 — syntax tolerant

Core textual profile: missing — NA
Dominant themes: recovered via syntax tolerance — 1. **Preference for Lower-Flying Alternatives; Respondents express a willingness to reduce air travel when feasible alternatives exist; Train travel is highlighted as a preferred option when time and cost constraints permit; 2. **Practical Challenges in Avoiding Flying; Some respondents acknowledge that personal circumstances (e.g., family abroad) make complete avoidance of flying difficult
Within-group coherence: missing — NA
Internal diversity: recovered via syntax tolerance — **Proactive Reduction of Flights:** Some respondents actively seek alternatives (e.g., TXT000001, TXT000002). - **Practical Constraints:** Others recognize that flying may still be necessary due to personal circumstances (e.g., TXT000003).
Representative IDs: recovered via syntax tolerance — TXT000001; TXT000002
Tension IDs: recovered via syntax tolerance — TXT000003
Invalid IDs: (none)

### P2 — semantic aliases

Core textual profile: recovered via semantic alias — The group demonstrates a nuanced approach to lower-flying travel choices, balancing environmental concerns with practical realities. While there is a clear preference for alternatives like train travel, personal obligations sometimes necessitate air travel.
Dominant themes: recovered exactly — 1. **Preference for Lower-Flying Alternatives; Respondents express a willingness to reduce air travel when feasible alternatives exist; Train travel is highlighted as a preferred option when time and cost constraints permit; 2. **Practical Challenges in Avoiding Flying; Some respondents acknowledge that personal circumstances (e.g., family abroad) make complete avoidance of flying difficult
Within-group coherence: missing — NA
Internal diversity: recovered exactly — **Proactive Reduction of Flights:** Some respondents actively seek alternatives (e.g., TXT000001, TXT000002). - **Practical Constraints:** Others recognize that flying may still be necessary due to personal circumstances (e.g., TXT000003).
Representative IDs: recovered exactly — TXT000001; TXT000002
Tension IDs: recovered exactly — TXT000003
Invalid IDs: (none)

### What changed

P1 recovered: themes; diversity; representative IDs; tension IDs
P2 additionally recovered: core
Still missing: coherence
Invalid IDs observed: (none)

---

## R12 — condition M — repetition 3

### Raw response

### Structured Textual Profile of Group "A"

#### **Dominant Themes:**
1. **Preference for Lower-Flying Alternatives:** Respondents express a willingness to reduce air travel when feasible alternatives exist.
2. **Practical Constraints:** Some acknowledge that personal circumstances (e.g., family abroad) make complete avoidance of flying difficult.
3. **Train Travel as a Preferred Alternative:** Train travel is highlighted as a viable option when time and cost permit.

#### **Higher-Level Interpretation:**
The group demonstrates a nuanced approach to reducing air travel, balancing environmental concerns with practical realities. While there is a clear preference for lower-flying alternatives (e.g., trains), personal obligations sometimes limit the ability to fully eliminate flying.

#### **Internal Diversity:**
- **Proactive Reduction of Flights:** Some respondents actively seek alternatives (e.g., TXT000001, TXT000002).
- **Personal Constraints:** Others acknowledge unavoidable flying due to family commitments (e.g., TXT000003).

#### **Representative Text IDs:**
- **TXT000001:** Reflects a general willingness to reduce flights when alternatives are available.
- **TXT000002:** Highlights train travel as a preferred alternative.

#### **Tension Text ID:**
- **TXT000003:** Introduces a contrasting perspective where personal circumstances necessitate flying, creating tension with the broader theme of reducing air travel.

This profile captures the group's balanced view on lower-flying travel choices, acknowledging both environmental preferences and practical limitations.

### P0 — strict current parser

Core textual profile: missing — NA
Dominant themes: missing — NA
Within-group coherence: missing — NA
Internal diversity: missing — NA
Representative IDs: missing — NA
Tension IDs: missing — NA
Invalid IDs: (none)

### P1 — syntax tolerant

Core textual profile: missing — NA
Dominant themes: recovered via syntax tolerance — 1. **Preference for Lower-Flying Alternatives:** Respondents express a willingness to reduce air travel when feasible alternatives exist; 2. **Practical Constraints:** Some acknowledge that personal circumstances (e.g., family abroad) make complete avoidance of flying difficult; 3. **Train Travel as a Preferred Alternative:** Train travel is highlighted as a viable option when time and cost permit
Within-group coherence: missing — NA
Internal diversity: recovered via syntax tolerance — **Proactive Reduction of Flights:** Some respondents actively seek alternatives (e.g., TXT000001, TXT000002). - **Personal Constraints:** Others acknowledge unavoidable flying due to family commitments (e.g., TXT000003).
Representative IDs: recovered via syntax tolerance — TXT000001; TXT000002
Tension IDs: recovered via syntax tolerance — TXT000003
Invalid IDs: (none)

### P2 — semantic aliases

Core textual profile: recovered via semantic alias — The group demonstrates a nuanced approach to reducing air travel, balancing environmental concerns with practical realities. While there is a clear preference for lower-flying alternatives (e.g., trains), personal obligations sometimes limit the ability to fully eliminate flying.
Dominant themes: recovered exactly — 1. **Preference for Lower-Flying Alternatives:** Respondents express a willingness to reduce air travel when feasible alternatives exist; 2. **Practical Constraints:** Some acknowledge that personal circumstances (e.g., family abroad) make complete avoidance of flying difficult; 3. **Train Travel as a Preferred Alternative:** Train travel is highlighted as a viable option when time and cost permit
Within-group coherence: missing — NA
Internal diversity: recovered exactly — **Proactive Reduction of Flights:** Some respondents actively seek alternatives (e.g., TXT000001, TXT000002). - **Personal Constraints:** Others acknowledge unavoidable flying due to family commitments (e.g., TXT000003).
Representative IDs: recovered exactly — TXT000001; TXT000002
Tension IDs: recovered exactly — TXT000003
Invalid IDs: (none)

### What changed

P1 recovered: themes; diversity; representative IDs; tension IDs
P2 additionally recovered: core
Still missing: coherence
Invalid IDs observed: (none)

---

