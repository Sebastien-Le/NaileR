# Transition studies: reconstruction working set

This directory is a working record for the focused reconstruction of
transition-related studies already used around NaileR. It is not package data
and it is not a claim that the external source files are redistributable.

The documents distinguish four statuses:

- `retrouvée et reconstructible`: the source, transformations and executable
  route are identified and the relevant preparation has been checked;
- `retrouvée mais incomplète`: a source or an essential methodological link is
  still missing;
- `reconstructible mais non diffusable en l'état`: the route can be rerun
  locally, but privacy, rights or volume prevent package distribution;
- `introuvable`: targeted searches did not locate the required source.

The R script in this directory performs read-only structural checks and the
smallest reproducible preparations. It does not write to source projects, call
an LLM, or alter NaileR data.

The six distributed datasets are documented separately in `R/datasets.R`.
Their C01/C02 validation material remains in
`dev/operational_validation/corpus/` and is not copied here.
