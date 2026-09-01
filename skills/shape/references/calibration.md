# Calibration — how a threshold is earned

⚠️ **Every number shipped today is a hypothesis, not a setting.** This protocol
is the deliverable of the v1.1 increment, more than the metrics themselves.

## The protocol

| Step | Action | Output |
| --- | --- | --- |
| 1 | Assemble 10–15 real documents spanning the five reader tasks | corpus |
| 2 | Run the census on all of them — **before setting any threshold** | metric distributions |
| 3 | Run the F7 retrieval test on each: answers correct | retrieval accuracy per doc — ⛔ **not** locate cost, see below |
| 4 | Check which metrics separate high-cost from low-cost documents | surviving metric set |
| 5 | Set thresholds from the distribution of the survivors, not from the hypotheses | `.shape.toml` |
| 6 | Record corpus size and date beside every threshold; print both in reports | provenance |

⚠️ **Expect two or three survivors out of seven.** Stated in advance so that
dropping metrics reads as the protocol working, not as the increment failing.

⚠️ **This is calibration, not science.** n ≈ 12, one author, correlated writing
habits. The result is a locally useful setting, not a finding — do not present
it as one.

## What the ledger is for

`scripts/ledger.sh` appends `runs/<date>-<slug>.json` on **every** pass,
whatever the mode — the slug is the document path, the fixture id, or the
opaque id of an `--external` run. That is what makes the two open questions answerable by accumulation
rather than by argument:

| Question | Closed by |
| --- | --- |
| Does the lucid-lint score track locate cost? | ⛔ **unanswerable since 2026-08-31** — no valid locate-cost measure exists |
| Does any F12 metric separate high-cost documents? | census and retrieval stored side by side, every run |

## Closing the lucid-lint question

| Finding | Action |
| --- | --- |
| The score tracks locate cost | 🔒 promote back to a gate — stating the correlation and the corpus size |
| ⛔ *Blocked since 2026-08-31* | no valid locate-cost measure exists to correlate against; ⚠️ suspended, not dropped |
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

**The candidate companion measure.** ⛔ *Settled 2026-08-31 — it was not one.
Read the next two sections before this one; the hypothesis below is recorded as
it stood, not as it stands.* Control 5 of the validation protocol
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

### Measured on the A/B pair, 2026-08-28 — no separation

`fixtures/T2-topology-01a` (dependency graph as a **table**) and `-01b` (the
same content as a **mermaid graph**) differ in one section and nothing else.
Eight hand-authored questions, five of them needing two or three edges. Cold
subagents, k = 3 per arm, isolated directory, key unreachable.

| Measure | A — table | B — graph | Separates? |
| --- | --- | --- | --- |
| Answers correct | 24/24 | 24/24 | ❌ no |
| Blocks opened, mean | 2.67 | 3.00 | ❌ no — and the wrong way |
| Reader tokens, mean | 23 976 | 24 167 | ❌ no |
| Access checks (6) | identical verdicts | identical verdicts | ❌ no |
| `V8_table_share` | 0.75 | 0.50 | ✅ yes |
| `V5_figure_mention` | `null` | 1 | ✅ yes |

🛑 **The second row is the finding.** Locate cost was the candidate companion
measure, and it did not move. On this pair, the retrieval loop cannot grade
form at all — not through accuracy, and not through cost. Per the table above,
that is the middle row: **say so in the report contract, and stop implying the
gate covers form.**

⚠️ **What this measurement cannot settle.** Three limits, stated so the number
is not over-read:

- **n = 3 per arm, one fixture, one model family.** A locally useful reading,
  not a finding — the same caveat that governs every threshold in this file.
- **The Reader is not the population.** An LLM issuing `sed` ranges does not
  pay the visual scan cost a human pays on a nine-row dependency table. The
  claim the protocol cares about is about human readers; this instrument
  cannot reach them.
- **The document is small.** 538 words, one screen per section. Both arms were
  answerable from two or three opens, so there was little cost for form to
  move. ⭐ A longer topology — 20 services, dependencies split across sections
  — is the next fixture, and the real test of the hypothesis.
  **Done 2026-08-31; see the next section. It did not rescue the measure.**

📌 **What survives.** Two census numbers moved and everything model-facing did
not. `V8_table_share` and `V5_figure_mention` are, so far, the only instruments
in this repo that can see the defect the user reported. That is a reason to
calibrate them, and not yet a reason to trust them.

### Measured on the A/B/C triple, 2026-08-31 — the measure is invalid, not insensitive

`fixtures/T2-topology-02a` (30 edges stated only inside 20 per-service entries),
`-02b` (the same edges consolidated into one table) and `-02c` (the same edges as
a mermaid graph). ~950 words, ten hand-authored questions of which four need a
reverse edge and four need a path of two hops or more. Cold subagents, k = 3 per
arm, isolated directory, neutral filename, key unreachable.

Three arms rather than two, because the `01` pair varied consolidation and form
at once: `a → b` is consolidation, `b → c` is form.

| Measure | A — scattered | B — table | C — graph | Separates? |
| --- | --- | --- | --- | --- |
| Answers correct | 30/30 | 30/30 | 30/30 | ❌ no |
| Blocks opened, mean | 1.67 | 1.67 | 2.00 | ❌ no |
| Reader tokens, mean | 46 486 | 46 668 | 46 805 | ❌ no — 0.7 % spread |
| `V8_table_share` | 1 | 1 | 0.67 | ⚠️ b vs c only |
| `V5_figure_mention` | `null` | `null` | 1 | ⚠️ b vs c only |
| `V6_section_length_cv` | 1.27 | 0.85 | 0.80 | ⚠️ a vs b only |

🛑 **The finding is not in the table, it is in what the readers did.** All nine
loaded the **whole document** — `Read`, `cat`, `cat -n`, or a `head` and a `sed`
covering every line. **Not one issued a single `grep` or targeted search.**

⭐ That makes *blocks opened* an invalid measure of locate cost, not merely an
insensitive one. The measure counts navigation, and this reader does not
navigate: it ingests. A document it can hold entire costs the same to read
whatever shape it is in, and no amount of k, no third arm, and no further
fixture of this size will change that. **The instrument was never measuring the
quantity its name claims.**

📌 **Two live explanations for the `01` null result are discharged.**

- *"The document was too small for form to cost anything."* The document is now
  1.8× longer with 3.3× the edges, and every measure moved less than before.
- *"`01` restates its own topology in prose, so neither form was needed."* `02`
  does not — Deploy order states the rule and not the sequence, On call names
  ownership and not dependencies, no failure mode names a path — and all three
  arms still scored perfectly.

What is left is the mechanism above, and it is a property of the Reader rather
than of the documents.

⚠️ **What this still cannot settle.** One model family, k = 3, one document
family. And the claim the protocol cares about — that form costs a *human*
reader something — remains untouched by any of this.

### 🛑 Consequence for the protocol

The cold-subagent retrieval loop (brief §F7) grades **fact retrievability**. It
does not grade form, it cannot be made to grade form by enlarging the document,
and the report contract must say so rather than let the gate imply coverage it
does not have.

⭐ The exit condition, stated so it can be met rather than argued: an instrument
earns the right to grade form when it separates two arms of a frozen A/B pair
whose content is identical. Two candidates, neither built:

1. **A Reader that cannot ingest the whole document** — a corpus large enough,
   or a context budget tight enough, that navigation is forced rather than
   optional. Only then does *blocks opened* count what it is named after.
2. **A human first-screen test**, which is the population the claim is about,
   and which `docs/shape-validation-protocol.md` §2 already budgets at ~20
   minutes per release.

Until one exists, `V8_table_share` and `V5_figure_mention` remain the only
instruments here that have ever seen a form difference — measured twice now,
across five documents — and they are census numbers, not gates.

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

## 📌 Observed on the first fixture — `contents-present` cannot see a way in inside the first section

Both arms of `T2-topology-01` open on a `## Where to start` section whose whole
body is a two-column scan table. `contents-present.sh` reports ❌ on both: its
rule is that the way in must precede the first depth-2 heading, and this one
*is* the first depth-2 heading.

⚠️ **Not changed.** One document is not evidence for moving a rule — the same
bar that removed the `table-misfit` definition rule. The rule also fires on
this repo's own `README.md` and `SKILL.md`, and does not fire on the three
files in `docs/`, so the disagreement is real and repeated rather than a
one-off.

**What would settle it.** ⛔ *Not this, since 2026-08-31.* The experiment as
written needs a locate-cost measure, and there is none: a pair differing only in
where the scan table sits would return the same number whatever the answer, for
the same reason the topology triple did. Settling this rule now waits on the
instrument named in *Consequence for the protocol* above — a Reader that cannot
hold the document whole, or a human first-screen test. Recorded as it stood: if
locate cost were identical the rule would be measuring a preference and should
relax to *a way in within the first section*; if it separated them the rule
would be right as written.
