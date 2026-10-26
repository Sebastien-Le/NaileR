# C01 — Technical checks for conditions B and C

| Condition | Responses | Prompts identical | Evidence identical | Groups | Duration (s) |
|---|---:|---|---|---|---:|
| B | 3 | TRUE | TRUE | 1, 2, 3 | 105.162 |
| C | 3 | TRUE | TRUE | 1, 2, 3 | 104.055 |

`nail_prompt()`, `nail_response()` and `nail_evidence()` were executed for both conditions. No package warning was emitted by the generation calls; the known local startup warning concerns the installed build version of `testthat`.

The A/B/C blind packet contains three responses per group, with independent within-group randomization. Its mapping is separate and excluded from the shareable archive.
