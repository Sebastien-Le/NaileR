===== DESCFREQ_BEFORE =====


# Introduction

A survey was conducted about beards and eight types of beards were described. I will give you the results for one type of beard.

---

## How to Read the Evidence
The source is a contingency table: rows are the entities or categories to interpret, and columns are frequency attributes.
For each row, FactoMineR identifies attributes whose relative frequency differs statistically from the overall table profile.
The factual statements below report the retained direction and the row-versus-global relative frequencies.
They are statistical characterizations, not causal explanations.
A higher relative frequency means that an attribute is over-represented in that row relative to the global table profile.
A lower relative frequency means that an attribute is under-represented.
Technical p-values and v-tests remain available in `nail_evidence()` for audit but are deliberately not used as semantic content in this prompt.
Prioritize coherent configurations of several attributes over isolated single signals.
A higher-level substantive characterization may synthesize several displayed frequency facts, but it is an interpretation of the profile rather than an additional measured frequency.

# Task

Please summarize what makes this beard unique and give its profile a concise descriptive name.

# Data

## Row 'B1'

### Retained relative-frequency facts

- Attribute "neat" has a higher relative frequency in this row than in the whole table (row profile=14.39%; global profile=3.86%; row frequency=20; total attribute frequency=41).
- Attribute "clean" has a higher relative frequency in this row than in the whole table (row profile=8.63%; global profile=1.69%; row frequency=12; total attribute frequency=18).
- Attribute "classic" has a higher relative frequency in this row than in the whole table (row profile=7.91%; global profile=1.79%; row frequency=11; total attribute frequency=19).
- Attribute "modern" has a higher relative frequency in this row than in the whole table (row profile=2.88%; global profile=0.47%; row frequency=4; total attribute frequency=5).
- Attribute "elegant" has a higher relative frequency in this row than in the whole table (row profile=3.6%; global profile=0.75%; row frequency=5; total attribute frequency=8).
- Attribute "confident" has a higher relative frequency in this row than in the whole table (row profile=2.88%; global profile=0.75%; row frequency=4; total attribute frequency=8).
- Attribute "educated" has a higher relative frequency in this row than in the whole table (row profile=1.44%; global profile=0.19%; row frequency=2; total attribute frequency=2).
- Attribute "Parisian bobo" has a higher relative frequency in this row than in the whole table (row profile=1.44%; global profile=0.19%; row frequency=2; total attribute frequency=2).

# Final Summary Task
1. **A concise interpretation of the row as a relative frequency profile**.
2. **The main attributes supporting that interpretation**.
3. **An optional descriptive row name**, only if clearly supported.

# Output format
Your output must be **formatted using valid Quarto Markdown**.

===== END DESCFREQ_BEFORE =====

===== DESCFREQ_AFTER =====

# Introduction

A survey was conducted about beards and eight types of beards were described. I will give you the results for one type of beard.

---

## How to Read the Evidence
The source is a contingency table: rows are the entities or categories to interpret, and columns are frequency attributes.
For each row, FactoMineR identifies attributes whose relative frequency differs statistically from the overall table profile.
The factual statements below report the retained direction and the row-versus-global relative frequencies.
They are statistical characterizations, not causal explanations.
A higher relative frequency means that an attribute is over-represented in that row relative to the global table profile.
A lower relative frequency means that an attribute is under-represented.
Technical p-values and v-tests remain available in `nail_evidence()` for audit but are deliberately not used as semantic content in this prompt.
Prioritize coherent configurations of several attributes over isolated single signals.
A higher-level substantive characterization may synthesize several displayed frequency facts, but it is an interpretation of the profile rather than an additional measured frequency.
Build the main interpretation and any descriptive name primarily from the strongest coherent pattern. Rare or sparsely represented attributes may provide secondary contextual nuance, but they should not drive the descriptive name unless supported by several convergent signals.

# Task

Please summarize what makes this beard unique and give its profile a concise descriptive name.

# Data

## Row 'B1'

### Retained relative-frequency facts

- Attribute "neat" has a higher relative frequency in this row than in the whole table (row profile=14.39%; global profile=3.86%; row frequency=20; total attribute frequency=41).
- Attribute "clean" has a higher relative frequency in this row than in the whole table (row profile=8.63%; global profile=1.69%; row frequency=12; total attribute frequency=18).
- Attribute "classic" has a higher relative frequency in this row than in the whole table (row profile=7.91%; global profile=1.79%; row frequency=11; total attribute frequency=19).
- Attribute "modern" has a higher relative frequency in this row than in the whole table (row profile=2.88%; global profile=0.47%; row frequency=4; total attribute frequency=5).
- Attribute "elegant" has a higher relative frequency in this row than in the whole table (row profile=3.6%; global profile=0.75%; row frequency=5; total attribute frequency=8).
- Attribute "confident" has a higher relative frequency in this row than in the whole table (row profile=2.88%; global profile=0.75%; row frequency=4; total attribute frequency=8).
- Attribute "educated" has a higher relative frequency in this row than in the whole table (row profile=1.44%; global profile=0.19%; row frequency=2; total attribute frequency=2).
- Attribute "Parisian bobo" has a higher relative frequency in this row than in the whole table (row profile=1.44%; global profile=0.19%; row frequency=2; total attribute frequency=2).

# Final Summary Task
1. **A concise interpretation of the row as a relative frequency profile**.
2. **The main attributes supporting that interpretation**.
3. **An optional descriptive row name**, only if clearly supported.

# Output format
Your output must be **formatted using valid Quarto Markdown**.

===== END DESCFREQ_AFTER =====

