# CONDES applied examples

`run_condes_examples.R` is an offline, reproducible bench for the
`nail_condes()` examples. It does not call an LLM. Set `NAILER_REPO` to run
against a source checkout, or run it from an installation containing NaileR.
Set `CONDES_OUTPUT_DIR` to save each prompt, evidence object, result object
and a CSV summary.

The examples preserve the distinction between the variables that construct an
ACM/AFC, supplementary variables, and variables passed to `nail_condes()` for
characterization. The sign of a factorial axis is arbitrary, so all requests
refer to the opposition between lower and higher values rather than assigning
an intrinsic meaning to a positive sign.

| Case | Active variables | Supplementary variables | Input | Dim1 inertia (%) | Purpose |
|---|---:|---:|---:|---:|---|
| `decathlon` | 10 quantitative PCA variables | none | 41 × 13 source; 41 × 10 PCA input | existing help example | observed and PCA reference |
| `agri_studies` | 38 assertions | 4 personal variables | 53 × 42 | 5.239203 | historical ACM |
| `glossophobia` | 25 assertions | 16 personal/context variables | 139 × 41 | 7.932556 | historical ACM |
| `beard_cont` | 335 row-profile descriptors | none | 8 × 335 | 21.68056 | historical AFC |
| `local_food` | 45 assertions | 18 opinion/context variables | 573 × 63 | 1.981552 | MASHS ACM |
| `irtsat_items_2024_2025` | 48 assertions | none | 541 × 48 | 7.80818 | IRTSAT instrument ACM |
| `distinction` | 47 assertions from six blocks | none in this example | 1226 × 47 | 6.954734 | Distinction ACM |

The IRTSAT item table is not joined to the separate 529-row profile table.
The Distinction open-response column is not an active ACM variable. The
47-variable Distinction selection is intentional: it covers the six coherent
blocks `q17` and `q21`--`q25`; the separate novelty block `q30` remains outside
this illustrative axis.

The numeric association between an ACM/AFC coordinate and an input variable is
descriptive. For active variables it is partly linked to the construction of
the axis and must not be presented as an independent validation of the axis.
