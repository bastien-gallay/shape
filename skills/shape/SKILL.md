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
> measured by whether a reader still finds the facts, not by how much shorter it
> got.
>
> **Two sentences kept verbatim.** *A verification you skipped is not a
> verification you passed.* *The score is evidence, never the objective.*

## 0. Always-on directives

1. **Diagnose first.** On an unknown document, `diagnose` is the mode until the
   user chooses another. Starting from `condense` is the documented failure mode.
2. **No new claims.** Every assertion in the output traces to a source span.
   Output sentences with no source match are listed in the report, not silently
   kept.
3. **Never whole-file rewrite above ~1 500 words.** The whole-file rewrite is the
   mechanism by which facts disappear. Outline pass, then section-level edits.
4. **A tool that is missing reports *not run*.** `lucid-lint`, `pandoc`, `mmdc`,
   `lychee` absent → the check is reported as not run. Never silently skipped,
   never fatal.
5. **Read every exit status in its own statement.** In a pipe you read `tail`'s
   status, not the command's. Every verification carries a positive control.
6. **Word count is informational.** Report it; never credit it. A restructuring
   that measures −4.8 % has not failed.
7. **The agent that edits does not grade.** Retrieval scoring runs in a cold
   subagent with no knowledge of the edit.

## 1. Modes

| Mode | What it may change | Deletions |
| --- | --- | --- |
| `diagnose` | nothing — read-only report | none |
| `access-only` | title, purpose, TL;DR, contents, headings, anchors | ⚠️ an alarm |
| `restructure` | block order and grouping, tables from prose | expected, bounded |
| `condense` | all of the above plus removal of transient prose | expected |

## 2. Classify before transforming

Two **orthogonal** axes. State the inferred pair *and the evidence for it*; ask
when confidence is low. The prototype's mistake was assuming `dev-doc` × `locate`.

| Axis | Values | Maps to |
| --- | --- | --- |
| Audience | `dev-doc` · `public` · `falc` | `lucid-lint --profile` |
| Reader task | `locate` · `execute` · `decide` · `learn` · `comply` | `references/tasks/<task>.md` |

Load **one** ruleset — `references/tasks/<task>.md` — and follow its forbidden
transforms as hard rules. Read `references/render-targets.md` for what the
`--target` allows; fallbacks are declared there, never improvised at edit time.

## 3. The pass

1. **Config** — read `.shape.toml` at repo root if present
   (`templates/shape-config.toml` is the template). The skill body carries
   *method*; the repo carries *policy*.
2. **Classify** (§2) and announce the pair, the mode, and the target.
3. **Inventory facts** — `scripts/extract-facts.sh <file> > facts.json`, per
   `assets/facts-schema.json`. This runs **before** any edit.
4. **Baseline** — `scripts/lint-delta.sh --baseline <file>` and the cold-subagent
   retrieval run (§4). Stop here in `diagnose`.
5. **Branch** — one branch or worktree, one commit. Reviewable and reversible.
6. **Outline pass, then section edits** — never the whole file at once.
7. **Verify** — every gate in §5, each by its script, each exit status read.
8. **Report** — §6.

## 4. Reader-task verification — the primary metric

1. Derive 5–8 retrieval questions from the document's stated purpose, or take
   them from the user. ⭐ User-supplied questions are stronger evidence; prefer
   them whenever offered.
2. A **cold subagent** — fresh context, no knowledge of the edit — answers from
   the document alone and reports which sections it had to open.
3. Score **answers correct** (comprehension) and **blocks opened** (locate cost),
   before and after, on the same questions.
4. Print the caveats with the result: this is a proxy for a human reader, not a
   human test; question derivation by the same model biases toward what that
   model finds salient.

## 5. Acceptance gates

| Gate | Threshold | Instrument |
| --- | --- | --- |
| Fact survival | 🛑 100 % | `scripts/verify-facts.sh` |
| Retrieval accuracy | ≥ baseline | cold subagent (§4) |
| Locate cost (blocks opened) | < baseline | cold subagent (§4) |
| Idempotence | no semantic diff | `scripts/check-idempotence.sh` |
| lucid-lint `access` score | ≥ baseline | `scripts/lint-delta.sh` |
| Markdown / links / mermaid | pass or *not run* | `scripts/check-render.sh` |
| Word count | ⚠️ informational | `git show HEAD:<file> \| wc -w` |

🛑 A fact that did not survive **fails the pass**. It is not reported as a
trade-off.

## 6. Report contract

Per-category lucid-lint delta · retrieval before/after · fact-survival list ·
what was removed, by category · **what could not be measured, and why** · word
count, labelled *informational* · the diff stat.

## 7. Hard rules

- 🔒 Normative wording (`MUST`, `SHALL`, legal citations), measurements, dates,
  commands, warnings, caveats, identifiers and links are protected classes. They
  survive verbatim or the pass fails.
- ⛔ Out of scope, always: style or voice rewriting · translation · content
  creation · making a document *look nicer* · replacing human review.
- ⛔ Never optimise the lint score as a target. A pass that raises the score
  while lowering retrieval accuracy has failed.
- Markers come from the closed set in `references/markers.md`. A marker that is
  decoration is a defect.
- v1 format scope: `.md` and `.txt` are edited natively; every other format is
  `diagnose`-only, analysed via `pandoc -t json`. ⚠️ Never round-trip through
  pandoc to rewrite — it normalises and loses source fidelity.

## 8. Anti-patterns

| Symptom | What it means |
| --- | --- |
| Reaching for `condense` on first contact | §0.1 skipped |
| "Restructured for clarity", no numbers | §6 skipped |
| A gate reported as passed with no script run | §0.5 — say *not run* |
| Deletions in `access-only` | wrong mode, or scope creep |
| Headings that name topics (`Analysis`, `Details`) | a heading must answer a reader's question |
| The editing agent scoring its own retrieval | §0.7 |
