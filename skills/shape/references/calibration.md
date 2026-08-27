# Calibration — how a threshold is earned

⚠️ **Every number shipped today is a hypothesis, not a setting.** This protocol
is the deliverable of the v1.1 increment, more than the metrics themselves.

## The protocol

| Step | Action | Output |
| --- | --- | --- |
| 1 | Assemble 10–15 real documents spanning the five reader tasks | corpus |
| 2 | Run the census on all of them — **before setting any threshold** | metric distributions |
| 3 | Run the F7 retrieval test on each: answers correct, blocks opened | locate cost per doc |
| 4 | Check which metrics separate high-cost from low-cost documents | surviving metric set |
| 5 | Set thresholds from the distribution of the survivors, not from the hypotheses | `.shape.toml` |
| 6 | Record corpus size and date beside every threshold; print both in reports | provenance |

⚠️ **Expect two or three survivors out of seven.** Stated in advance so that
dropping metrics reads as the protocol working, not as the increment failing.

⚠️ **This is calibration, not science.** n ≈ 12, one author, correlated writing
habits. The result is a locally useful setting, not a finding — do not present
it as one.

## What the ledger is for

`scripts/ledger.sh` appends `runs/<date>-<doc>.json` on **every** pass, whatever
the mode. That is what makes the two open questions answerable by accumulation
rather than by argument:

| Question | Closed by |
| --- | --- |
| Does the lucid-lint score track locate cost? | score and retrieval stored side by side, every run |
| Does any F12 metric separate high-cost documents? | census and retrieval stored side by side, every run |

## Closing the lucid-lint question

| Finding | Action |
| --- | --- |
| The score tracks locate cost | 🔒 promote back to a gate — stating the correlation and the corpus size |
| No relationship | keep as a signal, or drop it from the report |
| Score improves while locate cost worsens | 🛑 Goodhart confirmed — remove it from the report entirely |

## Promoting a local rule into lucid-lint

```text
local script → measured on corpus → stable across 2 releases → proposed as a lucid-lint rule
```

⭐ A deterministic rule is badly designed in the abstract. `shape` is the
proving ground. A rule leaves `scripts/access/` only with the corpus it was
measured on, its size and date, its observed false-positive rate, and two
releases of stability.

📌 **Measured 2026-08-27, before any corpus exists.** On a four-block probe, the
`prose-restates-table` hypothesis of 0.6 overlap missed a paragraph that
restated its adjacent table term for term; the same check fired at 0.5. One
document is not evidence for moving the number — it is evidence that the number
was picked in the abstract, which is what this protocol exists to fix.
