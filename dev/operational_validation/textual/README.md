# TEXTUAL operational examples

`run_textual_examples.R` runs offline previews for the historical datasets and
the Distinction survey. It uses the public `nail_textual()`,
`nail_evidence()` and `nail_prompt()` accessors and never calls an LLM.

Run from the repository with:

```sh
NAILER_REPO=/absolute/path/to/NaileR \
TEXTUAL_OUTPUT_DIR=/absolute/path/to/results \
Rscript dev/operational_validation/textual/run_textual_examples.R
```

The five cases are:

* `fabric`: fabric A, with the historical appreciation groups `0` and `1`;
* `car_alone`: four groups combining declared car use and perceived restriction;
* `atomic_habits`: the three published groups, after excluding the historical
  `"THAT"` value from the air-travel response column;
* `rorschach_panel_A`: ten local prompts, one for each inkblot;
* `distinction_global`: one profile containing all 1,225 non-empty translated
  comments about food quality, plus `distinction_highest_education`, a
  reproducible groupwise preview across six observed education categories.

The Distinction group variable is `highest_education`. Its smallest category
contains 26 respondents, and every category has at least one non-empty text.
The full-corpus preview uses `sample.pct = 1`; the education comparison uses
`sample.pct = 0.1` and `seed = 20261027` to keep each prompt inspectable. A
sampled response is not an exhaustive analysis of all comments.

The script saves complete prompts, evidence and result objects only when
`TEXTUAL_OUTPUT_DIR` is supplied.
