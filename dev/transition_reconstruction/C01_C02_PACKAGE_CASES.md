# Existing package cases: C01 and C02

## C01 — `local_food`

Source object: distributed `local_food`, 573 × 63, with a seeded MCA/HCPC
classification used by the operational corpus. The validated workflow has
three groups of 226, 188 and 159 participants and 314 selected markers. The
shareable reports, aggregate evidence and scripts are under
`dev/operational_validation/corpus/C01_local_food/`. The technical and
statistical workflow is validated; the semantic review remains exploratory
and includes a documented truncated response. No causal or general prompt
superiority claim follows from that review.

Current route: `nail_catdes(generate = FALSE)` for preview, then the public
evidence/prompt/response accessors for a permitted generation.

## C02 — `atomic_habit_clust`

Source object: distributed `atomic_habit_clust`, 167 × 51, with `clust` levels
1, 2 and 3 and sizes 84, 13 and 70. The offline reference uses columns 1:20
plus `clust`, yielding 63 selected markers. Text columns and derived columns
are retained in the source object but are not silently used as independent
statistical evidence. The shareable preparation is under
`dev/operational_validation/corpus/C02_atomic_habit/`.

Current route: reuse the prepared profiles or call `nail_catdes()` on the
documented statistical subset with `generate = FALSE`. Any TEXTUAL or
CATDES–TEXTUAL use requires an explicit privacy decision and exact matching;
group 2 is small. The previous Gemini campaign was blocked/limited and does
not constitute a semantic quality validation.
