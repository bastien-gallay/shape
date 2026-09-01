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

### Confirmed independently, 2026-08-31 — a fourth document, another chain

⭐ The mechanism above is not a property of the topology fixtures. It reproduces
on an unrelated document, measured by someone who was not looking for it.

Two `shape` passes (`diagnose` then `restructure`) ran that day on a CN2S-318
Jira description in a client repo, outside this corpus and with no knowledge of
the triple result. Three cold Readers were spawned — a baseline, a re-run and a
third measurement. Their transcripts hold **one tool call each**: a whole-file
`Read`, no `offset`, no `limit`, and no `grep`. Same behaviour, different
document family, different operator, different day.

🛑 **And that pass reported a locate cost anyway — 5/5 blocks before, 8/11
after, 692 → 641 words.** Those numbers are the Reader's *retrospective
self-report*, produced after ingesting everything: `SKILL.md` §4 asks it to
"report which sections it had to open", and it answers a question about a
navigation that never happened. The pass then failed its own locate-cost gate on
them and recorded the failure as a confound in the block count.

⭐ So the defect is worse than an invalid measure — the instrument **manufactures
plausible numbers**. A null result invites a second look; a specific, moving,
self-consistent number does not. This is the sharpest form yet of the entry
under *A null result can belong to the instrument*: read the transcript of what
the subject did, never the number it reported about itself.

⚠️ A ledger field that carries a self-report must say so in its name or its
schema. None currently does.

### ⭐ Measured under truncation, 2026-09-01 — the first separation

The same three arms, the same ten frozen questions, k = 3 — but each Reader was
handed **only `first-window.sh`'s slice**, never the document. Nine cold
subagents, isolated directories, the file named `service-map.md` in each.

| Arm | Above the fold | Correct | Tool calls |
| --- | --- | --- | --- |
| a — scattered | 7 of 20 service entries | **3 / 30** | 1 each |
| b — table | the complete 22-row table | **30 / 30** | 1 each |
| c — graph | all 30 mermaid edges | **29 / 30** | 1 each |

Arm a answered one question per run — the two-hop chain whose both entries
happen to sit above the fold — and returned `INSUFFICIENT` for the rest rather
than guessing. Arms b and c answered everything; c's single miss is one Reader
naming five services where the key has four.

⭐ **The exit condition is met for consolidation.** Two arms of a frozen triple
whose content is identical, separated 3/30 against 30/30 by an instrument that
grades nothing itself. `a → b` is now measurable.

🛑 **It is not met for form.** `b → c` is 30/30 against 29/30 — a table and a
graph carrying the same edges above the fold are still indistinguishable here,
exactly as they were under the untruncated Reader. The claim *this form reads
better* remains unmeasured; what is now measurable is *this content is above
the fold*.

⚠️ **The limit to state whenever this number is quoted.** The questions need the
topology, and the instrument rewards the arm that put the topology above the
fold. That is close to tautological, and it is the honest reading: this measures
**what is above the fold**, not the cost of a form. It is still a real
instrument — a document can put the wrong thing above the fold, and now that
shows — but it cannot rank two documents that both put the right thing there.

📌 Also unchanged: one model family, k = 3, one document family, and reader
token counts within 0.6 % across all nine, so the separation is not a budget
artefact.

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
   ⭐ Cheapest form of this, added 2026-09-01: **truncate the input** rather
   than police the Reader. Show it only the blocks that fit in the first
   `window_lines` and ask the task's acceptance questions. Nothing has to be
   enforced, because nothing else was ever supplied — and what fits above the
   fold is a property of form. `V3_first_screen` already occupies this ground
   and tests only whether ingredients are present.
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

## 🛑 `extract-facts.sh` is blind to a quantity written in words — 2026-09-01

**How it surfaced.** Widening the corpus past `locate`. `T2-adr-01` is 868 words
of decision prose, and the extractor found **two** facts in it: one code span and
one ISO date. `verify-facts.sh` then reported **2/2 survived ✅**.

**What it missed.** Every quantity the document argues from, because each is
spelled out: *two hundred and forty euros a month*, *nine thousand batches a
day*, *twelve duplicate rows*, *one batch in fifty*, *four times current peak*,
*another five times*. The extractor keys on digits and code spans, so a document
that writes its numbers as words has almost nothing to protect.

⚠️ **The direction is the dangerous one.** This is the failure this repo keeps
paying for, in a new place: the gate does not report a loss it cannot see, it
reports a **pass**. A `condense` run could delete the cost estimate, the volume
and the duplicate count from that document and the 100 % fact-survival gate
would stay green — and 100 % of two is exactly as green as 100 % of seventy-nine.

📌 **What it does not mean.** The gate is not broken for the documents it was
built on. The five `locate` fixtures yield 29–79 facts each, and `T2-runbook-01`
yields 21, because procedures and topologies carry their facts as commands,
identifiers and digits. The blindness is specific to argued prose — which is
`decide` and much of `learn`, the two tasks the corpus had never contained.

⛔ **The counts in that paragraph are entry counts — retracted 2026-09-01**, the
same day, by *The fact-survival denominator counted entries, not facts* below:
the five `locate` fixtures yield **9–21 distinct fragments**, not 29–79, and
`T2-runbook-01` yields **14**, not 21. ⚠️ The finding stands and the gap narrows
rather than closing — 2 against 9–21 is still the difference between a document
the gate protects and one it cannot see into. The numbers are left in place
because the entry was written against them.

🛑 **Not fixed here, deliberately.** A spelled-out-number extractor is a new
producer on the path of a gate, and this repo's rule is that a producer whose
failure is invisible is how the pass-it-never-ran bug returns. It needs its own
positive and negative controls, and a decision about what counts as a quantity,
before it goes in front of the 100 % gate. ⭐ The cheap interim signal is already
available and costs nothing: **the fact count itself**. A tier-2 document
yielding fewer than ~5 facts is a document the gate is not protecting, and the
report should say so rather than print a green 2/2.

## ⚠️ The fact-survival denominator counted entries, not facts — 2026-09-01

**What it was.** `verify-facts.sh` reported one line per inventory entry.
`grep -F` searches the whole document, so N entries carrying the same fragment
are one verification reported N times: they pass and fail together, and they
test one string. The gate's own denominator was inflated by repetition.

**Measured across the corpus**, after the same-line fix in `2bcb1ec` made the
inflation visible:

| Fixture | Entries | Distinct fragments |
| --- | --- | --- |
| `T2-topology-01a` | 50 | **9** |
| `T2-topology-01b` | 33 | **9** |
| `T2-topology-02a` | 59 | **21** |
| `T2-topology-02b` | 79 | **21** |
| `T2-topology-02c` | 29 | **21** |
| `T2-runbook-01` | 21 | **14** |
| `T2-adr-01` | 2 | **2** |

🛑 A `50/50 facts survived` was nine strings. ⭐ Only the flattering number was
removed: deduplication changes nothing about detection, because a fragment
present anywhere passes and a fragment deleted everywhere fails, exactly as
before. Control 3 of the seven run on the change exercises precisely that — a
fragment appearing three times, deleted from all three, still fails.

⚠️ **The ledger entries predate this.** The five `runs/` entries record the old
denominator. They are not wrong about survival — every one was 100 % — but their
fact counts are entry counts and are not comparable with anything written after
this date.

📌 **The count is now also the coverage signal**, which is what makes it worth
having. Below `SHAPE_MIN_FACTS` (default 5) the run says the gate is protecting
very little, and names why: the extractor keys on digits and code spans, so
argued prose yields almost nothing. ⚠️ The threshold is uncalibrated and
advisory — it changes what is printed, never the exit code — and it is not a
ninth metric or a seventh check. It reads a number the inventory already emits.
