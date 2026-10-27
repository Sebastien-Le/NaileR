# ProjetSystAlimED 2023–2024

**Status:** `retrouvée mais incomplète`
**Priority:** medium after join resolution
**Distribution:** local/private

## Sources

The project is under `/Users/sebastienle/Documents/2023-2024/Traitement de
données d'enquêtes/ProjetSystAlimED/` and its duplicate `ProjetSystAlimED 2/`.
Key files are `Base_K.xlsx`, `Base_F.xlsx`, `SystalimED.R`,
`Projet_systalim_ED.Rmd`, and `SystAlimED.Rdata`.

## What the scripts establish

The executable analyses use MCA → HCPC → CATDES. The surrounding protocol is
Q-sort-like, but the code found is not a classical Q-method factor analysis.
The local audit found 576 rows in `Base_K`, 658 in `Base_F`, 11 duplicate IDs
in `Base_F`, 536 common IDs and a saved 586 × 64 snapshot with missing values.

## NaileR route and blocker

After a justified join and de-identification, the resulting group table could
use `nail_catdes_prep()` followed by `nail_catdes()` and the public accessors.
No final object is proposed now: choosing a join or filling missing values
would be an undocumented analytical decision. The original questionnaire and
rights also require confirmation.
