# Changelog

## Unreleased

Initial scaffold, written from `docs/shape-brief.md`.

### Added

- `skills/shape/SKILL.md` — the protocol: always-on directives, four modes, the
  two-axis classification, the pass, the primary metric, the acceptance gates,
  the report contract, hard rules, anti-patterns.
- `skills/shape/references/tasks/` — one ruleset per reader task (`locate`,
  `execute`, `decide`, `learn`, `comply`), each declaring target shape, allowed
  transforms, **forbidden** transforms, and acceptance questions.
- `skills/shape/references/render-targets.md` — capability matrix and declared
  fallbacks per render target.
- `skills/shape/references/markers.md` — the closed marker set and its density
  budget.
- `skills/shape/scripts/` — `extract-facts.sh`, `verify-facts.sh` (the 100 %
  gate, with positive controls), `lint-delta.sh`, `check-idempotence.sh`,
  `check-render.sh`. Each carries an exit-code contract; a missing tool exits 3
  and reports *not run*.
- `skills/shape/assets/facts-schema.json` — the fact-inventory schema.
- `skills/shape/templates/shape-config.toml` — the `.shape.toml` policy
  template.
- `fixtures/` — corpus for the idempotence and diagnose regression runs.
- Packaging: `install.sh`, `justfile` (`release`, `check-versions`, `package`,
  `check-fixtures`, `lint`), `.claude-plugin/` manifests.

### Fixed

Review of the initial commit, 2026-08-27 — 11 findings, all confirmed by
running the code, all fixed.

- 🛑 **Three gates reported passes they never ran.** `jq` inside a process
  substitution fails invisibly to `set -euo pipefail`; the loop read zero rows
  and `verify-facts.sh` printed `0/0 facts survived`, exit 0, on an unreadable
  or empty inventory. `lint-delta.sh --compare` did the same. Producers now run
  in their own statement into a file, checked, and zero rows exits 4.
- `verify-facts.sh` reported ✅ for a multi-line fact whose second line was
  deleted — `grep -F` matches an OR of the lines. Multi-line fragments are now
  refused (exit 4), per brief §F4.
- `lint-delta.sh` pinned the schema of fresh output but never the baseline's —
  the drift the pin exists to catch reached the comparison.
- `extract-facts.sh` never emitted `grep_fragment`, so a reflowed line failed
  the gate although the fact survived; and its `number` class only matched
  percentages while a `next` cascade let one rule per line win. It now emits a
  distinctive fragment, recognises measurements, versions and identifiers, and
  lets a line produce several facts. ⚠️ No `\b` in the regexes: macOS awk
  ignores it silently and dropped every normative fact.
- `install.sh` linked *inside* an existing real directory and reported success,
  leaving a `--copy` install stale.
- `check-render.sh` proved mermaid by running `mmdc --version`; it now extracts
  each block and compiles it.
- `check-idempotence.sh` ignored all whitespace and blank lines, calling a
  re-nested list and two merged paragraphs "whitespace-only".
- `references/render-targets.md` marked GitHub ⛔ for footnotes; GFM has
  supported `[^1]` since 2021.
- `just check-fixtures` aborted at the first failing fixture; it now surveys
  the corpus and prints a tally.

### Changed — spec v1.1

Implements `docs/shape-spec-v1.1.md` through step 3 of its own sequencing
(§9). Steps 4–6 — corpus, calibration, gates — need documents and retrieval
runs, not code, and are deliberately untouched.

- **lucid-lint is a signal, not a gate.** The `access`-score row is gone from
  the acceptance gates; `lint-delta.sh --compare` reports a regression and
  exits 0. Two reasons, both recorded: the five categories are intra-sentential,
  so a structurally unusable document can score high; and converting prose to
  tables raises the score mechanically. 🔒 If the score turns out to track
  locate cost on the corpus, the gate comes back.
- **The dependency arrow is inverted.** shape no longer waits for a lucid-lint
  `access` category. The six structural rules live in `scripts/access/`
  — heading scent, contents present, section length, prose-list, prose
  restating a table — each with a positive and a negative control. Promotion
  outward requires a corpus, a false-positive rate, and two stable releases.
- **F12 — visual rhythm.** `census.sh` emits the block sequence
  (`assets/blocks-schema.json`); `metrics.sh` computes V1–V7 as pure functions
  over it. ⛔ No metric re-parses the document. 🛑 Every value ships labelled
  `unvalidated` and gates nothing. The wrap width is part of the unit and is
  printed with the result.
- **Every pass writes a ledger.** `ledger.sh` appends `runs/<date>-<doc>.json`
  with the classification applied, census and metrics before/after, retrieval,
  lint score, facts, word count, and a mandatory `not_measured` field that may
  not be empty by omission. This is what makes both open questions answerable
  by accumulation rather than by argument.
- **Thresholds moved to `.shape.toml`** under `[thresholds]`, each beside
  `corpus_size` and `derived_on`. `corpus_size = 0` states plainly that nothing
  has been calibrated yet. 🛑 No threshold is hard-coded in a script.
- `just profile <file>` runs the census, the metrics and the access checks over
  one document.
- SKILL.md absorbed F12, the census and the ledger while staying under the
  §T4 ceiling: the anti-patterns table moved to `references/anti-patterns.md`,
  and the F12 detail to `references/f12-visual-rhythm.md`. Body 144 lines.

### Notes

- Named `shape`, bare, per the brief's settled decision — one free autocomplete
  initial, monosyllabic like `wrap` and `glance`, broad enough to cover
  `diagnose` as well as `condense`.
- 📌 lucid-lint has no `access` category yet (brief §5 item 2). Until it lands,
  access structure is judged by the skill, not measured, and the report says so.
