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

### Notes

- Named `shape`, bare, per the brief's settled decision — one free autocomplete
  initial, monosyllabic like `wrap` and `glance`, broad enough to cover
  `diagnose` as well as `condense`.
- 📌 lucid-lint has no `access` category yet (brief §5 item 2). Until it lands,
  access structure is judged by the skill, not measured, and the report says so.
