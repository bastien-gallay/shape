# F12 — visual rhythm and figure justification

🛑 **Everything here is report-only.** Every number is a hypothesis, not a
setting. No metric gates anything until the calibration protocol in
`references/calibration.md` has run over a corpus.

## The model

In docs-as-text there are no pixels to control. There is a **sequence of
blocks**, and that sequence produces the rendered rhythm.

⚠️ **Blank lines are not the unit.** Markdown normalises them at render. Air is
produced by *changes of block type* — a heading, a table, an admonition, a
figure each open space at display time.

⚠️ **White space signifies only by contrast.** A uniformly airy document
focuses nothing; it has diluted its lack of hierarchy. The target is
**differential** air — more space around what matters — which is why every
metric below is a distribution or a maximum, never a mean.

## The metrics

All computed from one census pass (`scripts/census.sh`). ⛔ No metric
re-parses the document.

| id | Definition | Hypothesis | Confidence |
| --- | --- | --- | --- |
| `V1` longest-prose-run | Max consecutive rendered lines in paragraph blocks with no other block type between | 8 lines | ⭐ high — best proxy for *wall of text* |
| `V2` screen-density | Over each sliding window of 45 rendered lines, share of lines in paragraph blocks; the max is reported | no window at 100 % | ⭐ high |
| `V3` first-screen | Within the first 40 lines: purpose · audience · ≥ 1 non-prose block | all three present | ⭐ high — cheapest and most consequential |
| `V4` block-type-run | Max consecutive blocks of the same non-prose type | 3 | medium — three tables in a row are as monotone as a wall of prose |
| `V5` figure-mention-distance | Blocks between a figure and its nearest caption or mention | 0 | medium — Mayer contiguity |
| `V6` section-length-CV | Coefficient of variation of section lengths at one heading depth | report only | ⚠️ low — likely noise |
| `V7` differential-air | Structural-block density around marker-bearing blocks vs the document mean | report only | ⚠️ exploratory — expect it to be dropped |

📌 V6 and V7 ship **report-only** on purpose. They are the two most likely to
fail calibration, and shipping them as candidates is how that gets established.

⚠️ **Declare the column width.** V2 counts *rendered* lines, which depend on an
assumed wrap width. It lives in `.shape.toml` and is printed in the report — a
metric whose unit is implicit is not reproducible.

## When a figure is justified

Larkin & Simon said *sometimes*. The *sometimes* is decidable from content
shape, with no image analysis.

| Passage shape | Target form | Detection |
| --- | --- | --- |
| **Relational** — named entities linked to each other | Diagram | ≥ 4 named entities and ≥ 3 relational verbs within a section |
| **Parallel on two dimensions** — cases × attributes | Table | ≥ 3 repeated syntactic frames sharing ≥ 2 slots |
| **Linear sequence, no branching** | ⛔ Ordered list, **not** a flowchart | Ordered steps, no conditional |

🛑 Detection **proposes**; it never converts. Conversion is a judgement call and
stays with the model, per §T1.

⚠️ The trigger is the shape of the content, never the length of the passage. A
long passage is not a reason for a figure.

## Prose and figure divide the labour

Mayer's redundancy principle is explicit: prose and diagram saying the same
thing is worse than either alone.

| id | Rule | Check |
| --- | --- | --- |
| `R1` | Every figure has ≥ 1 adjacent sentence **not derivable** from it — the why, the exception, the trap | model judgement, flagged for review |
| `R2` | ⛔ No paragraph walks a figure's edges | `scripts/access/prose-restates-table.sh` — entity overlap |
| `R3` | Caption inside the figure where the format allows | census: `caption` block type |

R2 generalises the prototype's *prose restating a table* to figures.

## Per mode

| Mode | F12 behaviour |
| --- | --- |
| `diagnose` | reports the full profile, every metric labelled **unvalidated** |
| `access-only` | may act on V3 and V1 only |
| `restructure` | may act on all metrics, and may *propose* figures |
| `condense` | reports V1–V3 after the pass — ⚠️ condensing raises prose density and can worsen them |

## Out of scope

⛔ Typography · colour · actual rendered output · content of images · page
layout.

Not a limitation to apologise for: the levers with real empirical support —
signalling, contiguity, redundancy, contrast — are all structural, hence
reachable from text. The typographic literature is weak anyway.

🔒 **Falsification condition.** If no metric separates high-cost from low-cost
documents on the corpus, F12 reverts to advisory prose in the rulesets and ships
no numbers at all.
