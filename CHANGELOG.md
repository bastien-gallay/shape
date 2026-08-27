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

### Notes

- Named `shape`, bare, per the brief's settled decision — one free autocomplete
  initial, monosyllabic like `wrap` and `glance`, broad enough to cover
  `diagnose` as well as `condense`.
- 📌 lucid-lint has no `access` category yet (brief §5 item 2). Until it lands,
  access structure is judged by the skill, not measured, and the report says so.
