---
title: shape — evolution spec v1.1
status: draft, unimplemented
applies to: shape v1 (first implementation)
amends: shape-brief §5, §6; adds F12
---

# shape — evolution spec v1.1

**Goal** — two changes to shape v1: lucid-lint stops being a gate, and visual
rhythm becomes a measured property. Both are written to **produce evidence**, not
to assert thresholds.

**Intended audience** — whoever implements the increment. Assumes shape v1 exists
and `shape-brief.md` has been read.

**TL;DR** — ⚠️ **Every number in this spec is a hypothesis, not a setting.** The
deliverable of this increment is a block census, a metric set, and a calibration
protocol. Thresholds are earned from the corpus afterwards, and each change carries
an explicit condition under which it is wrong.

**Contents** — Change A · Change B · The census · Calibration · Ledger ·
Acceptance · Sequencing · Risks.

---

## 1. What changes

| # | Change | Amends |
| --- | --- | --- |
| A | lucid-lint: acceptance gate → informational signal; dependency arrow inverted | §5, §6 |
| B | F12 — visual rhythm and figure justification | new |
| C | Every pass writes a ledger entry, so A and B can be decided by accumulation | new |

---

## 2. Change A — lucid-lint from gate to signal

### A1 — Gate removal

`shape-brief` §6, row *lucid-lint `access` score*: **delete the row**. Move to §8
report contract as a signal, printed with its score and no pass/fail semantics.

Two reasons, both recorded so the decision can be revisited:

- ⚠️ **False green.** The five current categories are intra-sentential. A document
  written well sentence by sentence and unusable structurally scores high. Gating on
  it would validate exactly what shape exists to reject.
- ⚠️ **Goodhart, direct.** Converting prose to tables shortens units mechanically and
  raises the score whether or not anything improved. shape would hold a lever on its
  own grade.

### A2 — Dependency arrow inverted

⛔ shape does **not** wait for a lucid-lint `access` category.

shape v1.1 writes its structural checks as local scripts under
`scripts/access/`. Rules are promoted outward, never imported inward:

```text
local script → measured on corpus → stable across 2 releases → proposed as a lucid-lint rule
```

⭐ A deterministic rule is badly designed in the abstract. shape is the proving
ground; the `access` category becomes a lucid-lint roadmap item justified by
evidence rather than a blocking dependency.

### A3 — What must be recorded to close the question

Every pass stores the lucid-lint score **next to** the retrieval result (§5). After
the corpus is covered, check whether the two move together.

| Finding | Action |
| --- | --- |
| `access`-relevant score tracks locate cost | Promote back to gate, with the correlation and the corpus size stated |
| No relationship | Keep as signal, or drop from the report |
| Score improves while locate cost worsens | 🛑 Goodhart confirmed — remove from the report entirely |
| ⛔ *Blocked since 2026-08-31* | no valid locate-cost measure exists to correlate against; ⚠️ suspended, not dropped |

🔒 **Falsification condition for Change A.** If the score turns out to track locate
cost on the corpus, this change was wrong and reverts.

⚠️ **Suspended 2026-08-31, not dropped.** There is no valid locate-cost measure
left to correlate the score against, so the condition cannot be evaluated until
one exists. See `skills/shape/references/calibration.md`.

### A4 — Unchanged

T5 already covers absence: lucid-lint missing → **not run**, never silently skipped,
never fatal.

---

## 3. Change B — F12, visual rhythm

### B1 — The model

In docs-as-text there are no pixels to control. There is a **sequence of blocks**,
and that sequence produces the rendered rhythm.

⚠️ **Blank lines are not the unit.** Markdown normalises them at render. Air is
produced by *changes of block type* — a heading, a table, an admonition, a figure
each open space at display time.

⚠️ **White space signifies only by contrast.** A uniformly airy document focuses
nothing; it has diluted its lack of hierarchy. The target is **differential** air —
more space around what matters — which is why every metric below is a distribution
or a maximum, never a mean.

### B2 — Metrics

All computed from one census pass (§4). ⚠️ Thresholds are **hypotheses**, unvalidated,
to be replaced by §5 output.

| id | Definition | Hypothesis | Confidence |
| --- | --- | --- | --- |
| `V1` longest-prose-run | Max consecutive lines belonging to paragraph blocks with no other block type between | 8 lines | ⭐ high — best proxy for *wall of text* |
| `V2` screen-density | Over each sliding window of 45 rendered lines, share of lines in paragraph blocks; report the max | no window at 100 % | ⭐ high |
| `V3` first-screen | Within the first 40 lines: purpose sentence · audience · ≥ 1 non-prose block | all three present | ⭐ high — cheapest and most consequential check |

⚠️ **Amended 2026-09-01.** V3's window is the first `--window` **rendered**
lines, not the first 40 source lines: a 400-character paragraph is one source
line and eight rendered ones, and the hardcoded 40 disagreed with the window
every other metric uses. V3 now also emits `blocks_in_window`, which
`scripts/first-window.sh` slices the document on. 📌 Ledger entries written
before that date are not comparable on V3.
| `V4` block-type-run | Max consecutive blocks of the same non-prose type | 3 | medium — three tables in a row are as monotone as a wall of prose |
| `V5` figure-mention-distance | Lines between a figure and its first textual mention | 0 (same block group) | medium — Mayer contiguity |
| `V6` section-length-CV | Coefficient of variation of section lengths at one heading depth | report only, no threshold | ⚠️ low — likely noise |
| `V7` differential-air | Structural-block density around marker-bearing blocks vs document mean | report only | ⚠️ exploratory — the least well operationalised metric here; expect it to be dropped |

📌 V6 and V7 ship **report-only** on purpose. They are the two most likely to fail
calibration, and shipping them as candidates is how that gets established.

### B3 — When a figure is justified

Larkin & Simon said *sometimes*. The *sometimes* is decidable from content shape, with
no image analysis.

| Passage shape | Target form | Detection |
| --- | --- | --- |
| **Relational** — named entities linked to each other | Diagram | ≥ 4 named entities and ≥ 3 relational verbs within a section |
| **Parallel on two dimensions** — cases × attributes | Table | ≥ 3 repeated syntactic frames sharing ≥ 2 slots |
| **Linear sequence, no branching** | ⛔ Ordered list, **not** a flowchart | Ordered steps, no conditional |

🛑 Detection **proposes**; it never converts. Conversion is a judgement call and stays
with the model, per T1.

⚠️ The trigger is the shape of the content, never the length of the passage. A long
passage is not a reason for a figure.

### B4 — Division of labour between prose and figure

Mayer's redundancy principle is explicit: prose and diagram saying the same thing is
worse than either alone.

| id | Rule | Check |
| --- | --- | --- |
| `R1` | Every figure has ≥ 1 adjacent sentence **not derivable** from it — the why, the exception, the trap | Model judgement, flagged for review |
| `R2` | ⛔ No paragraph walks a figure's edges | Entity-overlap between figure labels and adjacent paragraph above a threshold |
| `R3` | Caption inside the figure where the format allows | Census: caption block type |

R2 generalises the prototype's *prose restating a table* to figures.

### B5 — Out of scope for F12

⛔ Typography · colour · actual rendered output · content of images · page layout.

Not a limitation to apologise for: the levers with real empirical support — signalling,
contiguity, redundancy, contrast — are all structural, hence reachable from text. The
typographic literature is weak anyway.

### B6 — Where F12 acts, per mode

| Mode | F12 behaviour |
| --- | --- |
| `diagnose` | Reports the full visual profile, every metric labelled **unvalidated** |
| `access-only` | May act on V3 and V1 only |
| `restructure` | May act on all metrics and propose figures per B3 |
| `condense` | Reports V1–V3 after the pass; ⚠️ condensation raises prose density and can worsen them |

---

## 4. The census — single instrumentation

One parse, many metrics. ⛔ No metric re-parses the document.

`scripts/census.sh <file> → blocks.json`

| Field | Meaning |
| --- | --- |
| `i` | Index in document order |
| `type` | `heading` · `paragraph` · `list` · `table` · `code` · `quote` · `figure` · `admonition` · `caption` · `rule` · `frontmatter` · `html` |
| `level` | Heading depth, null otherwise |
| `start`, `end` | Source line span |
| `lines`, `chars` | Size |
| `path` | Heading ancestry, for section grouping |
| `markers` | Marker glyphs found in the leading cell |

Format handling is unchanged from T2: Markdown parsed natively, other formats via
`pandoc -t json` for **analysis only**.

⚠️ **Declare the column width.** V2 counts *rendered* lines, which depend on an assumed
wrap width. Put it in `.shape.toml` and print it in the report — a metric whose unit is
implicit is not reproducible.

Exit contract, per T4: `0` clean · `1` findings · `2` tool error. 🛑 The skill must never
read *tool error* as *document clean*.

---

## 5. Calibration protocol

How thresholds are earned. This is the deliverable, more than the metrics themselves.

| Step | Action | Output |
| --- | --- | --- |
| 1 | Assemble 10–15 real documents spanning the five reader tasks | corpus |
| 2 | Run the census on all of them — **before setting any threshold** | metric distributions |
| 3 | Run the F7 retrieval test on each: answers correct | retrieval accuracy per doc — ⛔ locate cost withdrawn 2026-08-31 |
| 4 | Check which metrics separate high-cost from low-cost documents | surviving metric set |
| 5 | Set thresholds from the distribution of the survivors, not from §B2 | `.shape.toml` |
| 6 | Record corpus size and date beside every threshold; print both in reports | provenance |

⚠️ **Expect two or three survivors out of seven.** Stated in advance so that dropping
metrics reads as the protocol working, not as the increment failing.

⚠️ **This is calibration, not science.** n ≈ 12, one author, correlated writing habits.
The result is a locally useful setting, not a finding — do not present it as one.

🔒 **Falsification condition for Change B.** If no metric separates high-cost from
low-cost documents, F12 reverts to advisory prose in the ruleset and ships no numbers
at all.

---

## 6. Ledger

Every pass appends `runs/<date>-<slug>.json`, whatever the mode. The slug is the
document path, the fixture id, or the opaque id of an `--external` run. This is
what makes both open questions answerable by accumulation rather than by
argument.

| Field | Why |
| --- | --- |
| `version`, `at` | Schema version and the UTC timestamp of the pass |
| `doc` | The document path — or the opaque id when `external` is true |
| `external` | ⛔ true when `doc` is an opaque id: path, source and every heading are scrubbed |
| `classification` | `mode`, `task`, `audience`, `target` — the classification actually applied (F1) |
| `calibration` | `fixture_id`, `ruleset_version`, `run_index`, `reader_family` — what makes a run attributable |
| `census` | The block census from `census.sh` — `blocks[]` and `source` — before and after |
| `metrics` | The F12 metric set, before and after, carrying `unvalidated: true` |
| `retrieval` | `questions`, `correct_per_run`, `accuracy`, `opens_per_run`, `reader_tokens_per_run`, `reader_family` |
| `lucid_lint` | Score and per-category values, or `not_run` |
| `facts` | `inventory`, `survived`, `all_survived` — the boolean the 🛑 100 % gate is read from |
| `word_count` | Informational |
| `not_measured` | Every check that could not run, and why |

⛔ `retrieval.opens_per_run` is **recorded, never scored** — see the locate-cost
retraction in §5.

⛔ **The external regime, added 2026-08-31.** A ledger entry built without it
reconstructs the document: `census.blocks[].path` carries the text of every
heading, `census.source` an absolute path, `doc` the filename. `--external <id>`
replaces all three and refuses to write if a path survives anywhere in the
entry. ⚠️ Such an entry is reproducible by nobody, its author included; the
counts are kept so a later reader can still say which *kind* of document a
conclusion came from. See `fixtures/README.md`.

📌 The `not_measured` field is mandatory and may not be empty by omission. A
verification you skipped is not a verification you passed.

---

## 7. Acceptance criteria for this increment

| Criterion | Threshold |
| --- | --- |
| Census runs over the corpus with a clean exit contract | 🛑 100 % |
| Every metric derives from a single census pass | 🛑 no re-parse |
| No threshold hard-coded in a script | 🛑 all in `.shape.toml`, dated, with corpus size |
| No F12 metric acts as a gate before calibration | 🛑 |
| `diagnose` prints the visual profile labelled unvalidated | required |
| lucid-lint absent → *not run*, pass completes | required |
| Ledger written on every pass, `not_measured` populated | required |
| Both falsification conditions written into the repo | required |

---

## 8. Non-goals for this increment

⛔ Adding reader tasks · new formats · touching F1–F11 · promoting anything into
lucid-lint · shipping a validated threshold set. The increment ends when the corpus has
been measured — not when the numbers look good.

---

## 9. Sequencing

Each step is useless without the previous one, and the usual failure is starting at 3.

1. **Census** — the parser and its schema. Nothing else can be built first.
2. **Metrics** — pure functions over `blocks.json`, report-only, no thresholds.
3. **Ledger** — so runs from step 2 onward accumulate rather than evaporate.
4. **Corpus and retrieval tests** — the expensive step; it is also the only one that
   produces evidence.
5. **Calibration** — survivors and thresholds.
6. **Gates** — only for what survived.

---

## 10. Risks

| Risk | Mitigation |
| --- | --- |
| Metric set grows toward what is easy to compute | Fixed at seven for this increment; additions require a corpus result |
| Thresholds from 12 documents read as universal | Corpus size printed beside every threshold in every report |
| Census diverges between native Markdown and pandoc paths | Fixture with both paths, compared block for block |
| Rendered-line estimate ≠ real rendering | Wrap width declared in config and in the report (§4) |
| `condense` degrades V1–V3 while reporting success | V1–V3 reported after every condense pass (B6) |
| The retrieval test is skipped because it is slow | It is the only evidence-producing step; without it this increment has no output |
