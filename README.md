# shape

A [Claude Code](https://claude.com/claude-code) skill that improves a
docs-as-text document **for its reader's task** — and proves it did, rather
than asserting it.

Most doc-cleanup passes optimise a generic notion of clarity and report a word
count. `shape` starts from a different question: *what is this reader trying to
do?* A procedure and a reference page need opposite structures, and the pass is
graded by whether a reader still finds the facts — not by how much shorter the
file got.

## What it does

1. **Classifies** the document on two orthogonal axes — audience (`dev-doc` ·
   `public` · `falc`) and reader task (`locate` · `execute` · `decide` ·
   `learn` · `comply`) — and states the evidence for the inference.
2. **Loads one ruleset** for that task, with its allowed *and forbidden*
   transforms. `comply` forbids condensing entirely; `learn` forbids the
   prose/diagram redundancy that `locate` welcomes.
3. **Inventories every load-bearing fact** before touching the file —
   measurements, warnings, commands, caveats, normative wording, numbers,
   dates, links, identifiers.
4. **Repairs access structure** as a unit: title, one-line purpose, audience,
   TL;DR, contents, informative headings, anchors.
5. **Verifies** — fact survival at 100 %, a cold-subagent retrieval test before
   and after, idempotence, render checks.
6. **Reports** what changed, what was removed by category, and **what could not
   be measured, and why** — plus the signals: the lint delta, the visual-rhythm
   profile, the structural findings, the word count.
7. **Writes a ledger entry**, whatever the mode, so the open questions get
   answered by accumulation rather than by argument. `--external <id>` records a
   run over a document that may not be described in the repository: the counts
   and metrics survive, the path and every heading do not.

🛑 A fact that did not survive fails the pass. It is not reported as a
trade-off.

## Modes

| Mode | What it may change | Deletions |
| --- | --- | --- |
| `diagnose` ⭐ default | nothing — read-only report | none |
| `access-only` | title, purpose, TL;DR, contents, headings, anchors | ⚠️ an alarm |
| `restructure` | block order and grouping, tables from prose | expected, bounded |
| `condense` | the above, plus removal of transient prose | expected |

⭐ On first contact with an unknown document, `diagnose` is the mode. Starting
from `condense` is the documented failure mode of the prototype this skill
replaces.

## Install

```sh
git clone https://github.com/bastien-gallay/shape
cd shape && ./install.sh          # symlink — edits propagate live
```

## Usage

```text
/shape README.md
/shape docs/runbook.md --mode restructure --task execute
/shape docs/policy.md --task comply --target confluence
```

| Argument | Meaning | Default |
| --- | --- | --- |
| `<file>` | the document to shape | asked |
| `--mode` | `diagnose` · `access-only` · `restructure` · `condense` | `diagnose` |
| `--task` | `locate` · `execute` · `decide` · `learn` · `comply` | inferred |
| `--audience` | `dev-doc` · `public` · `falc` | inferred |
| `--target` | `github` · `confluence` · `mdbook` · `pdf` · `terminal` · `plain` | `github` |

Drop a `.shape.toml` at your repo root to set defaults, protected names, and
forbidden transforms — see `skills/shape/templates/shape-config.toml`. The
skill body carries *method*; your repo carries *policy*.

## Two things it deliberately does not do

🛑 **It does not gate on a score.** Not the word count, not the lucid-lint
score, not any of the seven visual-rhythm metrics. A prose linter's categories
are intra-sentential, so a document written well sentence by sentence and
unusable structurally scores high — gating on that would validate exactly what
`shape` exists to reject. Every score is a signal in the report, and
`references/calibration.md` states what would earn one a gate.

🛑 **It does not ship a number it has not measured.** The visual-rhythm metrics
are labelled `unvalidated` and gate nothing; thresholds live in `.shape.toml`
beside the corpus size and the date they were derived from. `corpus_size = 0`
says plainly that none of them has been calibrated yet. Both changes carry a
written falsification condition — if no metric separates documents readers
struggle with from documents they don't, the whole metric set reverts to
advisory prose and ships no numbers at all.

## The primary metric

Not the word count, and not the lint score. A **cold subagent** — fresh
context, no knowledge of the edit — answers 5–8 retrieval questions from the
document alone and reports which sections it had to open. Answers correct is
comprehension. Same questions, before and after.

⛔ **Blocks opened is not locate cost, and this metric does not grade form.**
Measured 2026-08-31 over three arms of one topology — scattered, table, graph:
30/30 on every arm, and all nine Readers loaded the whole document without
issuing a single `grep`. The measure counts navigation; the Reader ingests.
`skills/shape/references/calibration.md` carries the numbers and the exit
condition.

⭐ **Since 2026-09-01 one instrument does separate those arms — by truncating
its input.** `scripts/first-window.sh` hands a cold Reader the slice above the
fold and nothing else; on the same three arms that scored 30/30 each, it scored
**3/30 · 30/30 · 29/30**. 🛑 That is a result about **consolidation**, not about
form: the table and the graph are still 30 against 29. And the honest reading is
narrow — the questions need the topology and the instrument rewards the arm that
put the topology above the fold.

⚠️ Printed with every result: this is a proxy for a human reader, not a human
test. The agent that transformed the document never grades it. User-supplied
questions beat model-derived ones and are preferred whenever offered.

## Scope

Native editing on `.md` and `.txt`. Every other format is `diagnose`-only,
analysed through `pandoc -t json` — never round-tripped, because pandoc
normalises and loses source fidelity.

⛔ Out of scope, always: style or voice rewriting · translation · content
creation · making a document *look nicer* · replacing human review · optimising
the lint score as a target.

## Requirements

All optional; each absent tool reports **not run**, never *passed*.

| Tool | Used for |
| --- | --- |
| [`lucid-lint`](https://github.com/bastien-gallay/lucid-lint) | per-category prose score and delta — a signal, never a gate |
| `jq` | fact inventory |
| `pandoc` | analysis AST for non-Markdown sources |
| `markdownlint`, `lychee`, `mmdc` | render checks |

## License

MIT — see [LICENSE](LICENSE).
