<br />
<div align="center">
  <img src="images/Nailer_final.png" alt="NaileR logo" width="244" height="284">

  <h3 align="center">NaileR</h3>

  <p align="center">
    <i>Evidence first, interpretation second.</i>
  </p>
</div>

# NaileR

**Evidence first, interpretation second.**

NaileR helps you describe and interpret data by combining statistical methods in R with large language models (LLMs). It turns statistical results into structured prompts that you can inspect, customize, and optionally send to an LLM.

NaileR is designed for researchers, data analysts, and students working with statistical groups, numerical dimensions, sensory profiles, frequency tables, or open-ended responses. **The statistics are computed in R; the LLM suggests interpretations.** You remain responsible for evaluating them.

## How it works

```text
Your data → Statistical analysis in R → Selected evidence
          → Prompt built around your question → Optional LLM interpretation
```

You can inspect the statistical evidence and the exact prompt **without using an LLM**. NaileR also preserves the complete statistical evidence, even when only part of it is selected for the prompt.

## What can NaileR analyze?

| Function | What it helps you do |
| --- | --- |
| `nail_condes()` | Describe a numerical variable or a continuous dimension using its associations with other variables. |
| `nail_catdes()` | Describe the characteristics of groups or clusters. |
| `nail_descfreq()` | Describe the rows of a contingency table using its associations with the columns. |
| `nail_qda()` | Describe the sensory profiles of products or other stimuli. |
| `nail_textual()` | Explore and compare open-ended responses across groups. |

## Installation

**For the forthcoming public release**, install NaileR from its public GitHub repository:

```r
install.packages("remotes")
remotes::install_github("Sebastien-Le/NaileR")
library(NaileR)
```

> The examples below describe the forthcoming release. They should be used with the updated public version once it has been published; an older installed version may behave differently.

## First example: describing pre-defined groups

The `iris` dataset contains four flower measurements for three species. **Which measurements characterize each species?**

```r
library(NaileR)
data(iris)

iris_preview <- nail_catdes(
  dataset = iris,
  num.var = 5,                      # Species identifies the groups
  introduction = "Three iris species were measured using four flower characteristics.",
  request = "Describe the characteristics that distinguish each species.",
  isolate.groups = TRUE,           # One prompt per species
  generate = FALSE                 # No LLM call
)

# Explore the statistical evidence and the prompt for one species
nail_evidence(iris_preview, select = "setosa")
nail_prompt(iris_preview, select = "setosa")
```

The evidence shows which measurements are associated with a species. These associations do not mean that a characteristic belongs exclusively to that species. The prompt combines your question with the selected statistical results.

Set `isolate.groups = FALSE` to prepare a single prompt that considers all species together.

## Second example: sensory profiles

The `sensochoc` dataset, provided by **SensoMineR**, contains sensory ratings of six chocolates. **Which sensory attributes characterize each chocolate?**

```r
library(NaileR)
data(chocolates, package = "SensoMineR")

chocolate_preview <- nail_qda(
  dataset = sensochoc,
  formul = "~Product+Panelist",
  firstvar = 5,
  lastvar = 18,
  introduction = "Six chocolates were evaluated by a sensory panel.",
  request = "Describe the sensory characteristics of each chocolate.",
  isolate.groups = TRUE,
  generate = FALSE
)

nail_evidence(chocolate_preview, select = "choc1")
nail_prompt(chocolate_preview, select = "choc1")
```

Attributes marked **HIGHER** or **LOWER** describe differences relative to the mean product profile.

You can change `introduction` to explain your study and `request` to ask a different question.

## Using an LLM

When you are ready to generate an interpretation, set `generate = TRUE` and choose a configured provider:

- **Ollama** for a model running locally.
- **Gemini** for Google's models.

For example, with a local Ollama model already installed:

```r
# Requires Ollama to be running with the selected model available.
# iris_result <- nail_catdes(
#   dataset = iris, num.var = 5,
#   provider = "ollama", model = "llama3",
#   generate = TRUE
# )
# nail_response(iris_result)
```

The common accessors help you inspect the workflow:

```r
nail_evidence(iris_preview)  # Statistical evidence
nail_prompt(iris_preview)    # Prompt prepared for the LLM
# nail_response(iris_result) # Raw reply after generation
```

A model response is a **proposal for interpretation**, not a statistical finding. Compare it with the evidence, your research question, and the study context.

## Datasets and documentation

NaileR includes examples drawn from questionnaires, sensory studies, frequency tables, and open-ended comments. Explore the included datasets and function help from R:

```r
help(package = "NaileR")
?nail_catdes
?nail_qda
```

Some examples use external datasets: `iris` comes with R, and `sensochoc` comes from SensoMineR.

## Citation and license

If you use NaileR in research or teaching, please cite the package:

```r
citation("NaileR")
```

For the scientific communication introducing NaileR, also cite:

Hervé, N., Thoby, S., & Lê, S. (2024). *Interpréter une variable latente avec un modèle de langage, une application du package NaileR à la compréhension des systèmes alimentaires durables.* Recueil des résumés, Modèles et apprentissages en sciences humaines et sociales (MASHS 2024), Paris, 14 October 2024, p. 15. [Conference abstract](https://mashs2024.sciencesconf.org/data/book_mashs2024.pdf).

This is a conference abstract, not a journal article or a peer-reviewed publication. No DOI is assigned here.

NaileR was originally developed by **Nel Hervé and Sébastien Lê** and is currently maintained and further developed by **Sébastien Lê**. It is distributed under **GPL (>= 2)**. Cite the original data source when relevant.

## Contact

Sébastien Lê — sebastien.le@institut-agro.fr

Project: https://github.com/Sebastien-Le/NaileR

## Acknowledgements

This work has benefited from a government grant managed by the Agence Nationale de la Recherche under the France 2030 programme under reference ANR-23-PESA-0005.

Ce travail a bénéficié d'une aide de l'Etat gérée par l'Agence Nationale de la Recherche au titre de France 2030 portant la référence ANR-23-PESA-0005.
