# QDA evidence-level representation — less-dense replication

This is a blind replication of the previous QDA evidence-representation
benchmark. It compares only A, B, and C on `choc2`; condition D is not
included.

## Mechanical pre-screening

The same QDA configuration as the first benchmark was used with
`generate = FALSE`:

```text
dataset = SensoMineR::sensochoc
formul = ~Product+Panelist
firstvar = 5
proba = 0.05
drop.negative = FALSE
sample.pct = 1
sample.method = stratified
prompt_style = detailed
product_knowledge = known
isolate.groups = TRUE
```

| product | selected | HIGHER | LOWER | min p | max p | min abs(v.test) | max abs(v.test) |
|---|---:|---:|---:|---:|---:|---:|---:|
| `choc2` | 6 | 2 | 4 | `<.001` | 0.037730 | 2.077780 | 6.917251 |
| `choc4` | 8 | 4 | 4 | 0.000027 | 0.028279 | 2.193394 | 4.197756 |

`choc2` was selected mechanically because the first criterion is fewer
retained markers than `choc1` and `choc4`. It also contains both HIGHER and
LOWER directions and six markers, avoiding a one- or two-marker profile.

For `choc2`, in the fixed R order:

```text
attributes: Crunchy; MilkF; CocoaF; Melting; Caramel; Sweetness
directions: HIGHER; LOWER; HIGHER; LOWER; LOWER; LOWER
v.test:     6.92; -5.16; 2.95; -2.59; -2.48; -2.08
p.value:    <.001; <.001; 0.003220; 0.009609; 0.012966; 0.037730
evidence:   QDAP002E001 ... QDAP002E006
```

## Conditions and replication

The retained prompt blocks and generation settings are identical to the first
benchmark. Only `reading` and `evidence` vary:

- A: numeric table with `Variable`, `Coeff`, `Adjust mean`, `p.value`,
  `v.test`;
- B: current semantic-facing QDA evidence with numeric values;
- C: semantic minimal evidence preserving only HIGHER/LOWER direction and the
  average-product reference.

There are three independent Ollama generations per condition, nine retained
responses total, using `mistral-small3.2` and no forced seed.

## Blind review

The replication is blinded independently from the `choc1` benchmark with
identifiers `R01` through `R09`. The key is separate from the response file
and review packet. The review uses the same four axes as the previous
benchmark:

- statistical fidelity;
- evidence hierarchy;
- interpretive lift;
- unjustified extrapolation.

No response interpretation or winner calculation is performed automatically.
