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

## 🛑 The primary metric is form-blind — measured 2026-08-28

**What was measured.** Four real `shape` passes were scanned. One was an
`access-only` pass over a dossier of seven documents. It scored **35/35** on all
five access checks and **8/8 on retrieval, at 2.125 files per question**,
carrying 27 tables, 216 table rows and **zero figures**. A later pass — not a
`shape` pass — added 15 mermaid diagrams and 3 ASCII figures to those same seven
documents, because they were not readable.

**What it means.** The cold-subagent retrieval test is what brief §F7 calls *the
primary metric*, and §5 makes it an acceptance gate. It cannot see this class of
defect. A reader that answers the question correctly answers it correctly
whether the comparison is a table or the topology is a table. Retrieval accuracy
is **form-blind by construction**.

⚠️ **This is not a threshold to tune, and no accumulation of runs will surface
it.** Every other open question in this file is answerable by letting the ledger
fill up. This one is not: the instrument that would record the evidence is the
instrument that cannot perceive it. That is why it is written here rather than
left to be discovered.

**The candidate companion measure.** Control 5 of the validation protocol
already asks the Reader which sections it opened. **Locate cost may be
form-sensitive where accuracy is not** — a topology given as a graph may be
reachable in fewer opened blocks than the same topology given as a table, at
identical accuracy. 📌 That is a hypothesis, not a finding. It is untested, and
it is the reason the first fixture should be a topology document.

| Finding | Action |
| --- | --- |
| Locate cost separates the diagram version from the table version, accuracy does not | ⭐ locate cost joins retrieval as a reported measure; §F7 gains a second number |
| Neither separates them | 🛑 the retrieval loop cannot grade form at all — say so in the report contract, and stop implying the gate covers it |
| Accuracy itself separates them | the blindness was an artefact of that one dossier — record the counter-measurement here and keep the single metric |

**Falsification of this entry.** A corpus in which documents needing figures
score measurably worse on retrieval than their figure-bearing versions. One
dossier is not a corpus; it is the reason to build one.

## Falsified — `table-misfit`, the definition rule, 2026-08-28

**Hypothesis.** A two-column table whose second column averages ≥ 10 words is a
definition list wearing table clothes, and reads better as bold lead-in bullets.

**Where it came from.** A scan of four real `shape` passes filed four such
tables as *borderline*, alongside four measured misfits. The rule was written
because it was on the list, not because the scan supported it. ⚠️ Borderline is
not evidence, and a list is not a measurement.

**Measurement.** Implemented and run over every document in this repo: 7 hits.
`Risk | Mitigation`, `Construct | Unavailable → use`, `✅ Keep | Why it is
right`, `Finding | …`, `Mode | …`, `Agreement | …`. Every one is a mapping whose
left column is a scannable index — the exact affordance a `locate` reader needs.
Converting them to a definition list would remove it.

**Verdict.** 🛑 Removed the same hour. The three surviving rules — chronology,
proportion, series — were each observed as a table that a later pass actually
replaced with a figure. They fire on the controls and produce **zero** findings
across this repo.

**What would revive it.** A corpus measurement showing that readers of
two-column sentence tables have higher locate cost than readers of the
equivalent bullets. Not a preference, and not a second list.
