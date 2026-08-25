# NaileR 2.1.0

This release introduces the evidence-first analytical architecture that will
serve as the stable baseline for the second edition of *Analyzing Sensory Data
with R*.

## Common evidence-first user interface

* Added `nail_evidence()` as the public accessor for canonical analytical
  evidence.
* Stabilized `nail_prompt()` and `nail_response()` as the common interface for
  inspecting exact LLM prompts and raw responses.
* The recommended public workflow is now:
  `analysis -> nail_evidence() -> nail_prompt() -> nail_response()`.
* Rebuilt analyses preserve historical return shapes where practical while
  storing canonical evidence independently from interpretation-only settings.

## `nail_qda()`

* Rebuilt QDA interpretation around canonical `product_profiles` derived from
  `SensoMineR::decat()`.
* Product profiles retain adjusted means, statistically retained markers,
  directions, metrics, and deterministic evidence identifiers.
* Added reusable product interpretations and the expert-in-the-loop
  `nail_qda_interpretation()` editor.
* Added `nail_qda_space()` for evidence-first interpretation of PCA dimensions
  built from QDA adjusted product means.
* `nail_qda_space()` characterizes retained axes through real latent
  `nail_condes()` calls and combines axis geometry with product-level evidence.

## `nail_condes()`

* Rebuilt continuous-variable interpretation around canonical
  `continuous_profile` evidence.
* Continuous and qualitative associations, end profiles, evidence identifiers,
  settings, and metrics remain inspectable independently of the LLM.
* Added explicit `standard` and `latent` interpretation modes.

## `nail_catdes()`

* Rebuilt CATDES around canonical `statistical_profiles` produced by
  `nail_catdes_prep()`.
* Removed the parallel statistical characterization path from the semantic
  stage.
* Statistical evidence is now separated from deterministic prompt selection and
  semantic-facing factual statements.
* Observed categories and constructed/latent groups receive distinct
  interpretation rules while sharing the same canonical evidence.

## `nail_descfreq()`

* Rebuilt contingency-table interpretation around canonical
  `frequency_profiles`.
* Complete row profiles are retained separately from statistically retained
  markers.
* Prompt selection is deterministic and does not alter canonical evidence.
* Over- and under-represented attributes remain explicitly distinguishable.

## `nail_textual()`

* Rebuilt grouped textual analysis around canonical `textual_evidence`.
* Added exact text identifiers and a complete text registry.
* Sampling affects only the interpretation input; the complete textual evidence
  remains unchanged.
* Local responses can be parsed into reusable textual profiles containing core
  profile, dominant themes, within-group coherence, internal diversity, and
  representative/tension text identifiers.

## Composed statistical and textual interpretation

* Added `nail_catdes_textual()` to enrich CATDES group characterization with
  previously generated textual profiles.
* CATDES remains the statistical anchor; textual evidence is explicitly treated
  as supplementary contextual information.
* `nail_textual_contextualized()` remains available as a compatibility façade
  for historical workflows.

## LLM I/O and backend architecture

* Rebuilt analyses store current-stage LLM interaction through a common
  `llm_io` contract when available.
* Ollama and Google Gemini remain the supported public backends.
* Statistical functions are kept separate from backend implementation so that
  additional LLM interfaces can be added later without changing the analytical
  evidence contract.

## Validation and book baseline

* Added extensive tests for canonical evidence, invariance to
  interpretation-only options, prompt/response access, and composed workflows.
* Added an end-to-end operational stabilization campaign covering QDA,
  QDA-space, observed and latent CONDES, observed and latent CATDES, DESCFREQ,
  TEXTUAL, and CATDES + TEXTUAL.
* The operational campaign is intended to remain in `dev/` as a reproducible
  user-facing regression and book-baseline check.


# NaileR 2.0.0

This is a major release focused on robustness and maintainability.
The most significant changes include a complete rewrite of `nail_sort()` to use JSON,
the addition of a new robust Google Gemini API client,
and the centralization of code into helper functions.

## New Features

**Google Gemini Support:**
    * Added a new standalone function `gemini_generate()`.
    * This function acts as a robust, production-ready client for the Google Gemini API.
    * It supports detailed generation parameters, including `system_instruction` and `seed`.

**Centralized Utility Functions:**
    * A new `utils-formatting.R` file has been created to centralize common logic.
    * `format_stats_as_markdown()`: A new helper that cleanly formats statistics data frames (from `FactoMineR`) into Markdown tables for LLM prompts.
    * `parse_factominer_rownames()`: A new helper to parse complex `FactoMineR` row names (e.g., "variable=modality") into clean "Variable" and "Modalite" columns.
    * `sample_numeric_distribution()`: A centralized function for stratified sampling, now used by `nail_catdes()`.

## Major Refactoring & Enhancements

**`nail_sort()`: JSON Parsing for Robustness**
    * The prompt has been rewritten to **explicitly request a JSON array** from the LLM.
    * The core logic now uses `jsonlite::fromJSON()` to parse the response.
    * A robust validation loop now checks for valid JSON, correct item count (`nrow(dataset)`), correct `stimulus_id` order, group name length (`name_size`), and cluster count (`nb.clusters`).

**Markdown Formatting & "How to Read" Guides**
    * The prompt generation in `nail_catdes()`, `nail_condes()`, `nail_descfreq()`, and `nail_qda()` has been rewritten.
    * They now call the new `format_stats_as_markdown()` helper to present statistical data to the LLM in a clean, tabular Markdown format.
    * Each of these functions now injects a `GUIDE_*` (e.g., `GUIDE_QDA`) into the prompt. This "How to Read" guide explains the meaning of statistical columns (like `v.test`, `p.value`, `Cla/Mod`) to the LLM, significantly improving the quality and relevance of its analysis.

**Improved Robustness & Error Handling**
    * All data-processing functions (`nail_catdes`, `nail_condes`, `nail_descfreq`, `nail_qda`, `nail_textual`) now wrap their core `FactoMineR` calls and prompt generation in a `tryCatch` block.
    * If an underlying analysis yields no significant results, the function now stops gracefully with an informative message (e.g., "No significant differences between stimuli, execution was halted.") instead of erroring during prompt generation.

**LLM Parameter Control (`...`)**
    * All functions calling `ollamar::generate` (`nail_catdes`, `nail_condes`, `nail_descfreq`, `nail_qda`, `nail_textual`) now accept the `...` (dots) argument.
    * These arguments (e.g., `temperature`, `seed`) are correctly passed to the LLM using `do.call(ollamar::generate, ...)`, allowing for fine-grained control over the generation process.

**Enhanced `nail_qda()` Prompts**
    * The default `introduction`, `request`, and `conclusion` prompts in `nail_qda()` have been significantly improved to guide the LLM toward producing a structured, report-style summary. The prompt now explicitly asks for key contrasts and valid Quarto Markdown output.

**Centralized Sampling in `nail_catdes()`**
    * The local `sample_numeric_distribution` function was removed from `nail_catdes.R`.
    * The function now uses the new centralized version from `utils-formatting.R`, driven by the existing `quali.sample` and `quanti.sample` parameters.

## Bug Fixes

**`nail_condes()`:** Fixed a critical bug in the `get_bins` helper function. It now uses `.keep = 'all'` instead of `.keep = 'unused'` during the `mutate(across(...))` step, ensuring that the original data (including the variable of interest) is not dropped.

# NaileR 1.2.3

* Added a `NEWS.md` file to track changes to the package.
* Enhanced prompt generation in `nail_sort()` to enforce stricter group limits
* Added new parameters to `nail_catdes()` and `nail_condes()` to sample significant results when too many
* Enhanced prompt in `nail_qda()` to generate reports
