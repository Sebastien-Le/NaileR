# Operational defect 001 — text leakage into the statistical branch

## Function

`nail_textual_contextualized()` — raw/beginner path.

## Exact call

```r
nail_textual_contextualized(
  dataset = dataset,
  num.var = match("group", names(dataset)),
  num.text = match("comment", names(dataset)),
  analysis_scope = "cross_functional",
  comparison_mode = "joint",
  lexical_analysis = FALSE,
  generate = FALSE
)
```

## Observed result

The raw path passes the complete data frame to `nail_catdes_prep()`. Consequently, the `comment` column selected by `num.text` is converted to a qualitative descriptor and analysed by `FactoMineR::catdes()`.

In the reproducible operational example with recurring realistic comments:

- advanced statistical registry: 47 rows;
- raw/beginner statistical registry: 74 rows;
- spurious statistical markers derived from `comment`: 27 rows;
- raw and advanced statistical groups/registries: not identical.

## Why this is a defect

The documented five-function workflow treats structured variables and verbatims as distinct evidence streams. A text selected through `num.text` must enter `nail_textual_prep()`, not the statistical `catdes()` branch. The current raw path violates that separation and can create circular “statistical–textual” convergence from the same text.

## Cause

The raw statistical preparation call does not pass `exclude = num.text`:

```r
group_profile_prep <- nail_catdes_prep(
  dataset = dataset,
  num.var = num.var,
  proba = proba,
  row.w = row.w
)
```

## Severity

**Blocking for the required beginner/advanced path consistency criterion.** It can also contaminate the combined evidence registry.

## Minimal correction

Pass only the selected text-column index to the existing `exclude` argument:

```r
group_profile_prep <- nail_catdes_prep(
  dataset = dataset,
  num.var = num.var,
  exclude = num.text,
  proba = proba,
  row.w = row.w
)
```

No statistical, textual, parsing, validation, or report contract needs to change.

## Non-regression test

Extend the raw-path upstream-call test to assert that `nail_catdes_prep()` receives `exclude` equal to `num.text`.
