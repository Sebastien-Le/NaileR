# CONDES prompt blocks PoC

## Scope

This proof of concept separates the internal CONDES prompt into six ordered
responsibilities without changing the public `nail_condes()` arguments or the
statistical/evidence pipeline.

The six blocks are:

1. `context` — the study introduction supplied by the user or the current
   mode-specific default. It gives substantive context and is not statistical
   evidence.
2. `reading` — method-specific rules for reading `FactoMineR::condes()` facts,
   including correlation, p.value, Estimate, retention, sampling, and
   end-profile status.
3. `question` — the analytical question supplied by the user or the current
   standard/latent default.
4. `interpretation` — rules for moving from evidence to substantive meaning,
   including non-causality, coherent synthesis, interpretive centrality, and
   the standard/latent contract.
5. `evidence` — the unchanged semantic-facing evidence text generated from
   `semantic_facing_evidence`.
6. `output` — the unchanged standard or latent output contract from
   `build_conclusion_condes()`.

There is deliberately no `local_task` block: a CONDES call naturally targets
one continuous variable or continuum.

## Internal representation

The ordered artifact is stored as:

```r
attr(result, "condes_prompt_blocks", exact = TRUE)
```

with exactly these names:

```r
c("context", "reading", "question", "interpretation", "evidence", "output")
```

`.build_condes_prompt_blocks()` is the single constructor and
`.render_condes_prompt()` is the single renderer. `nail_prompt()` and the LLM
backend both use the resulting character prompt; no second prompt version is
created.

## Methodological boundary

The separation is conceptual as well as technical:

```text
context != evidence
reading != interpretation
statistical direction != substantive direction
association magnitude != statistical support
statistical support != interpretive centrality
```

In particular, statistical direction is not substantive direction. Domain
context may be required to translate one into the other, so domain information
belongs in `context`, not in the statistical `evidence` block.

The architecture does not introduce toggles, editable reading, a new public
accessor, or a general prompt-block API. The public interface remains
`nail_evidence()`, `nail_prompt()`, and `nail_response()`.

## Relationship to other methods

QDA and CATDES provide useful precedents for separating statistical evidence
from interpretation, but this PoC is restricted to CONDES. A future editable
reading layer may be considered only after this representation and its
invariance have been reviewed. No universal renderer is implied yet.
