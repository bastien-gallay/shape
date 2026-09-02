---
name: shape
description: >
  Improve a docs-as-text document for its reader's task and prove it did:
  classify audience × reader task, repair access structure (title, purpose,
  TL;DR, contents, informative headings), then verify with a fact-survival
  gate at 100 % and a cold-subagent retrieval test. Four modes — diagnose
  (read-only, the default), access-only, restructure, condense. Trigger: the
  user types /shape, asks to "clean up this doc", "make this README
  scannable", "restructure this page", "is this document clear", « rendre ce
  document lisible », « restructurer cette doc », or hands over a document
  that is hard to navigate.
argument-hint: "<file> [--mode diagnose|access-only|restructure|condense] [--task locate|execute|decide|learn|comply] [--audience dev-doc|public|falc] [--target github|confluence|mdbook|pdf|terminal|plain]"
---

# shape

> **The one idea.** A document is improved *for a reader's task*, not toward a
> generic notion of clarity. The transform is chosen by that task; the result is
> measured by whether a reader still finds the facts.
>
> **Kept verbatim.** *A verification you skipped is not a verification you
> passed.* *The score is evidence, never the objective.*

## 0. Always-on directives

1. **Diagnose first.** On an unknown document `diagnose` is the mode until the
   user chooses another; starting from `condense` is the documented failure mode.
2. **No new claims.** Every assertion in the output traces to a source span.
   Output sentences with no source match are listed in the report, not silently
   kept.
3. **Never whole-file rewrite above ~1 500 words** — that is the mechanism by
   which facts disappear. Outline pass, then section-level edits.
4. **A missing tool reports *not run*** — never silently skipped, never fatal,
   never *passed*.
5. **Read every exit status in its own statement.** In a pipe you read `tail`'s
   status; in a process substitution you read nothing at all. Every
   verification carries a positive control.
6. **Word count, the lucid-lint score and every F12 number are signals, never
   gates.** Report them; never credit them, never optimise them. A document
   written well sentence by sentence and unusable structurally scores high, and
   turning prose into tables raises the score mechanically — see
   `references/calibration.md` for what would earn any of them a gate.
7. **The agent that edits does not grade.** Retrieval scoring runs in a cold
   subagent with no knowledge of the edit.

## 1. Modes

| Mode | What it may change | Deletions |
| --- | --- | --- |
| `diagnose` ⭐ default | nothing — read-only | none |
| `access-only` | title, purpose, TL;DR, contents, headings, anchors | ⚠️ an alarm |
| `restructure` | block order and grouping, tables from prose | bounded |
| `condense` | the above, plus transient prose | expected |

## 2. Classify before transforming

Two **orthogonal** axes. State the inferred pair *and its evidence*; ask when
confidence is low. Assuming `dev-doc` × `locate` was the prototype's mistake.

| Axis | Values | Maps to |
| --- | --- | --- |
| Audience | `dev-doc` · `public` · `falc` | `lucid-lint --profile` |
| Reader task | `locate` · `execute` · `decide` · `learn` · `comply` | `references/tasks/<task>.md` |

Load **one** ruleset — `references/tasks/<task>.md` — and treat its forbidden
transforms as hard rules. `references/render-targets.md` says what `--target`
allows; fallbacks are declared there, never improvised at edit time.

## 3. The pass

1. **Config** — read `.shape.toml` if present (`templates/shape-config.toml`).
   The skill carries *method*; the repo carries *policy* — and every threshold.
2. **Classify** (§2) and announce the pair, the mode, and the target.
3. **Inventory facts** — `scripts/extract-facts.sh <file> > facts.json`, per
   `assets/facts-schema.json`. This runs **before** any edit.
4. **Census** — `scripts/census.sh <file> > blocks.json`. ⛔ One parse; nothing
   downstream re-parses the document.
5. **Baseline** — `scripts/metrics.sh` (§4b), the five checks under
   `scripts/access/`, `lint-delta.sh --baseline` as a signal, and the retrieval
   run (§4). Stop here in `diagnose`.
6. **Branch** — one branch or worktree, one commit. Reviewable and reversible.
7. **Outline pass, then section edits** — never the whole file at once.
8. **Verify** — every gate in §5, each by its script, each exit status read.
9. **Report** — §6 — and 🛑 always write the ledger, whatever the mode:
   `scripts/ledger.sh … --facts f --facts-survived N --not-measured
   "<reasons>|none"`. Neither is optional: an inventory without its survival
   count stores the question and discards the answer. ⚠️ `N` is the **distinct**
   count `verify-facts.sh` prints, not the number of inventory entries — the
   two differ by a factor of four on a document with repeated fragments.

## 4. Reader-task verification — the primary metric

1. Derive 5–8 retrieval questions from the document's stated purpose, or take
   them from the user. ⭐ User-supplied questions are stronger evidence; prefer
   them whenever offered.
2. A **cold subagent** — fresh context, no knowledge of the edit — answers from
   the document alone and records which sections it opened.
3. Score **answers correct** only, before and after, same questions. ⛔ Blocks
   opened goes to the ledger, never to a score — withdrawn 2026-08-31, see §5.
4. Print the caveats: a proxy for a human reader, not a human test, on
   questions the same model derived and therefore finds salient.

## 4b. Visual rhythm — F12, report-only

⚠️ There are no pixels in docs-as-text. There is a **sequence of blocks**, and
that sequence produces the rendered rhythm — air comes from *changes of block
type*, not from blank lines, and it signifies only by contrast.

`scripts/metrics.sh blocks.json --wrap <cols>` reports seven metrics over the
census. 🛑 Label every value `unvalidated` and print the wrap width — V2 counts
*rendered* lines, and a metric whose unit is implicit is not reproducible.
🛑 Detection **proposes**; conversion stays with the model, per §T1.

`references/f12-visual-rhythm.md` carries the metric definitions, the per-mode
table, and when a figure is justified.

## 5. Acceptance gates

| Gate | Threshold | Instrument |
| --- | --- | --- |
| Fact survival | 🛑 100 % | `scripts/verify-facts.sh` |
| Retrieval accuracy | ≥ baseline | cold subagent (§4) |
| Locate cost (blocks opened) | ⛔ withdrawn 2026-08-31 | see `references/calibration.md` |
| Idempotence | no semantic diff | `scripts/check-idempotence.sh` |
| Markdown / links / mermaid | pass or *not run* | `scripts/check-render.sh` |
| Word count | ⚠️ informational | `git show HEAD:<file> \| wc -w` |

🛑 A fact that did not survive **fails the pass** — never a trade-off. ⛔ The
lucid-lint score and every F12 metric are deliberately *not* here.

## 6. Report contract

Retrieval before/after · fact-survival list · what was removed, by category ·
**what could not be measured, and why** · the diff stat · 🛑 **the gates do not
cover form** — §4 grades fact retrievability, not table-versus-figure.

Signals, each labelled as such and none of them a verdict: per-category
lucid-lint delta · the F12 profile with its wrap width, labelled *unvalidated* ·
`scripts/access/` findings · word count, labelled *informational*.

## 7. Hard rules

- 🔒 Protected classes — normative wording (`MUST`, `SHALL`, citations),
  measurements, dates, commands, warnings, caveats, identifiers, links —
  survive verbatim or the pass fails.
- ⛔ Out of scope, always: style or voice rewriting · translation · content
  creation · making a document *look nicer* · replacing human review.
- ⛔ A pass that raises any score while lowering retrieval accuracy has failed.
- 🛑 No threshold is hard-coded in a script. They live in `.shape.toml`, dated,
  beside the corpus size they came from, and both are printed in the report. A
  number with no provenance is not a threshold.
- Markers come from the closed set in `references/markers.md`; a marker that is
  decoration is a defect.
- v1 format scope: `.md` and `.txt` native, everything else `diagnose`-only via
  `pandoc -t json`. ⚠️ Never round-trip through pandoc to rewrite.

## 8. Anti-patterns

`references/anti-patterns.md` — read it when a pass feels finished. Every entry
is a symptom of a directive in §0 having been skipped.
