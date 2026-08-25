<br />
<div align="center">
  <img src="images/Nailer_final.png" alt="NaileR logo" width="244" height="284">

  <h3 align="center">NaileR</h3>

  <p align="center">
    <i>Evidence first, interpretation second.</i>
  </p>
</div>

## Overview

`NaileR` connects statistical characterization in R with large language
models (LLMs). Its central principle is simple:

```text
statistical or textual evidence produced in R
                    ↓
          selected factual evidence
                    ↓
              LLM interpretation
```

The statistical evidence is retained independently of the LLM. The exact
prompt and the raw model response are retained as well. This makes the
interpretive workflow inspectable and allows the analyst to distinguish what
was established mechanically from what was proposed semantically.

NaileR currently supports local models through Ollama and Google Gemini.

## Installation

Install the current GitHub version with:

```r
install.packages("devtools")
devtools::install_github("Sebastien-Le/NaileR")
library(NaileR)
```

## A common user interface

The main evidence-first analyses share the same inspection grammar:

```r
res <- nail_xxx(...)

nail_evidence(res, select = ...)
nail_prompt(res, select = ...)
nail_response(res, select = ...)
```

- `nail_evidence()` returns the canonical evidence retained for the analysis;
- `nail_prompt()` returns the exact prompt sent to the LLM;
- `nail_response()` returns the raw LLM response.

Use `generate = FALSE` to inspect evidence and prompts without calling an LLM.
Use `generate = TRUE` when a model response is required.

## Main analyses

### Sensory product profiles: `nail_qda()`

`nail_qda()` characterizes products from QDA data using
`SensoMineR::decat()` and retains canonical product profiles.

```r
library(SensoMineR)
data(chocolates)

res_qda <- nail_qda(
  dataset = sensochoc,
  formul = "~Product+Panelist",
  firstvar = 5,
  isolate.groups = TRUE,
  product_knowledge = "known",
  provider = "ollama",
  model = "mistral-small3.2",
  generate = FALSE
)

nail_evidence(res_qda, select = "choc1")
nail_prompt(res_qda, select = "choc1")
```

With `generate = TRUE`, reusable product interpretations can be reviewed or
edited by an expert with `nail_qda_interpretation()`.

### Sensory product space: `nail_qda_space()`

A QDA result can be projected into a PCA product space and interpreted
dimension by dimension:

```r
res_space <- nail_qda_space(
  res_qda,
  ncp = 2,
  expertise_mode = "sensory",
  provider = "ollama",
  model = "mistral-small3.2",
  generate = FALSE
)

nail_evidence(res_space, select = "Dim1")
nail_prompt(res_space, select = "Dim1")
```

### Continuous variables and latent dimensions: `nail_condes()`

```r
data(decathlon, package = "FactoMineR")

res_condes <- nail_condes(
  dataset = decathlon,
  num.var = 12,
  interpretation_mode = "standard",
  provider = "ollama",
  model = "mistral-small3.2",
  generate = FALSE
)

nail_evidence(res_condes)
nail_prompt(res_condes)
```

For a synthetic score or factor axis, use `interpretation_mode = "latent"`.
When variable scales have domain-specific meanings, provide that information
in `introduction`; for example, lower running times mean better performance.

### Groups and clusters: `nail_catdes()`

Observed categories and constructed clusters use the same statistical engine
but different interpretation modes.

```r
res_catdes <- nail_catdes(
  dataset = iris,
  num.var = 5,
  interpretation_mode = "standard",
  isolate.groups = TRUE,
  provider = "ollama",
  model = "mistral-small3.2",
  generate = FALSE
)

nail_evidence(res_catdes, select = "setosa")
nail_prompt(res_catdes, select = "setosa")
```

Use `interpretation_mode = "latent"` for clusters or other constructed
profiles whose substantive meaning must be inferred.

### Frequency and contingency profiles: `nail_descfreq()`

```r
data(beard_cont)

res_descfreq <- nail_descfreq(
  beard_cont,
  interpretation_mode = "description",
  isolate.groups = TRUE,
  provider = "ollama",
  model = "mistral-small3.2",
  generate = FALSE
)

nail_evidence(res_descfreq, select = "B1")
nail_prompt(res_descfreq, select = "B1")
```

The complete contingency profile remains available in `nail_evidence()`,
whereas only statistically retained markers are used for interpretation.

### Grouped open-ended text: `nail_textual()`

```r
data(fabric)

fabric_A <- droplevels(
  fabric[fabric$Fabric == "A", , drop = FALSE]
)

res_text <- nail_textual(
  dataset = fabric_A,
  num.var = 4,
  num.text = 3,
  isolate.groups = TRUE,
  sample.pct = 0.35,
  seed = 123,
  provider = "ollama",
  model = "mistral-small3.2",
  generate = FALSE
)

nail_evidence(res_text, select = "0")
nail_prompt(res_text, select = "0")
```

The canonical textual evidence contains the complete text registry. Sampling
affects only the subset shown to the LLM.

### Statistical anchor plus textual enrichment: `nail_catdes_textual()`

`nail_catdes_textual()` combines an existing CATDES result with an existing
TEXTUAL result. The statistical profile remains the anchor; text is used as a
supplementary interpretive layer.

```text
CATDES statistical evidence
           ↓
        anchor
           ↑
    textual enrichment
```

The function does not recompute CATDES and does not re-analyze the raw text.

## Evidence-first interpretation does not remove expert judgment

A model response is an interpretation, not a statistical result. In particular,
domain semantics can matter. A negative association between running time and a
performance score means something different from a negative association
between an ordinary increasing measurement and that score.

NaileR therefore keeps three objects distinct:

```r
nail_evidence(res)
nail_prompt(res)
nail_response(res)
```

This separation makes disagreement between the statistical evidence and an LLM
interpretation visible rather than hiding it.

## LLM backends

The current public analytical API supports:

- `provider = "ollama"` for local Ollama models;
- `provider = "gemini"` for Google Gemini.

Backend selection is deliberately separated from the statistical analysis so
that additional LLM interfaces can be added later without changing the
evidence-first analytical contract.

## License

NaileR is released under the GPL (>= 2) license.

## Contact

Sébastien Lê — sebastien.le@institut-agro.fr

Project: https://github.com/Sebastien-Le/NaileR

## Acknowledgements

This work has benefited from a government grant managed by the Agence
Nationale de la Recherche under the France 2030 programme under reference
ANR-23-PESA-0005.

Ce travail a bénéficié d'une aide de l'Etat gérée par l'Agence Nationale de la
Recherche au titre de France 2030 portant la référence ANR-23-PESA-0005.
