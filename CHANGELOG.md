# Changelog

## Unreleased

### Measured — 2026-08-31 (the triple)

- k = 3 cold-subagent runs over all three arms of `T2-topology-02`. 30/30 on
  every arm; blocks opened 1.67 / 1.67 / 2.00; reader tokens within 0.7 %.
- 🛑 **The result is a property of the instrument, not of the documents.** All
  nine Readers loaded the whole document and not one issued a `grep`. *Blocks
  opened* counts navigation, and this Reader ingests rather than navigates, so
  it is an **invalid** measure of locate cost rather than an insensitive one.
- Discharges two rival explanations for the `01` null result: the document was
  not too small, and `01`'s prose restatement of its topology was not the cause.
- `references/calibration.md` records the measurement, the mechanism, and a
  concrete exit condition — a Reader that cannot hold the document, or a human
  first-screen test.
- `runs/` gains three more ledger entries.

### Added — 2026-08-31 (the long topology)

- `fixtures/T2-topology-02a` / `-02b` / `-02c` — 20 services, 30 edges, ~950
  words, ten hand-authored questions frozen with the arms. ⭐ A triple, not a
  pair: `a` states each edge only inside its own per-service entry, `b`
  consolidates them into one table, `c` into one mermaid graph. `a → b` varies
  consolidation and `b → c` varies form, which the `01` pair confounded.
- Every answer was re-derived from the arm-b table by script rather than by eye,
  and the three arms are byte-identical outside the one section that varies.
- 🛑 Recorded, not fixed: `01` restates its own topology in `Deploy order` and
  `On call`, which answers some of its questions from prose. That is a third
  live explanation for its null result. `02` does not reproduce it.

### Added — 2026-08-31 (the external regime)

- `ledger.sh --external <id>` — record a run over a document this repository may
  not describe. The entry keeps every count and every metric; `doc`,
  `census.source` and the heading text in `census.blocks[].path` are replaced by
  an opaque id. 🛑 Without it a ledger entry reconstructs the outline of the
  document verbatim, which made the ledger unusable over anything confidential.
- The scrub refuses to write when a filesystem path or a component of the source
  path survives anywhere in the entry — including in a `--not-measured` reason
  or a retrieval note — and exercises a positive and a negative control on every
  invocation.
- `--fixture-id` and `--external` are exclusive; the id ↔ path mapping is
  appended to `$SHAPE_EXTERNAL_MAP` (default `~/.shape/external-map.tsv`), and a
  map path inside the worktree is refused.
- `fixtures/README.md` documents the two regimes, and how to derive an in-repo
  fixture from a document that cannot ship: regenerate from the skeleton, never
  anonymise in place.

### Added — 2026-08-28 (fixtures)

- `fixtures/T2-topology-01a` / `-01b` — the first fixtures. An A/B pair: one
  dependency topology given as a table, the same content given as a mermaid
  graph, differing in one section and nothing else. Two files per fixture, key
  frozen by `document_sha256`.
- First measurement of the pair, recorded in `references/calibration.md`:
  retrieval 24/24 on both arms at k = 3, blocks opened 2.67 vs 3.00, all six
  access checks identical. Only `V8_table_share` and `V5_figure_mention`
  separate the forms.
- `runs/` gains its first two real ledger entries.

### Fixed — 2026-08-28 (fixtures)

- `check-render.sh` no longer reports a valid mermaid diagram as broken when
  the headless browser `mmdc` drives is unavailable. That path now exits **3 —
  NOT RUN**, per the exit-code contract. Found by the first fixture.
- `just check-fixtures` counts NOT RUN separately from failures, so a missing
  tool no longer reads as a failing document.

Initial scaffold, written from `docs/shape-brief.md`.

### Added — from measurement, 2026-08-28

- `scripts/access/table-misfit.sh` — the sixth structural check, and ⭐ the
  first derived from measurement rather than from reasoning. Three rules, each
  observed on a real pass: a chronology in a grid, a proportion, a quantitative
  series. ⛔ Topology is deliberately absent — "this table is really a graph" is
  not mechanically decidable and stays with the model.
- `metrics.sh` gains **V8**, the share of display blocks that are tables, with
  the table and figure counts beside it. V4 caps only *consecutive* same-type
  runs, so a document alternating table and paragraph scored perfectly while
  every table was the wrong form.
- `references/f12-visual-rhythm.md` gains *the reverse direction*: the matrix
  there only ever asked what prose should become, never whether an existing
  table was the right form.

### Removed — falsified, 2026-08-28

- 🛑 A fourth `table-misfit` rule — two columns whose second carries sentences
  — was implemented, measured and deleted the same hour. It fired 7 times on
  this repo, every one a legitimate mapping (`Risk | Mitigation`,
  `Construct | Unavailable → use`) whose left column is the scannable index a
  `locate` reader needs. The scan that suggested it had filed those cases as
  *borderline*; borderline is not evidence. Recorded in
  `references/calibration.md`.

### Changed

- `ledger.sh` gains a `calibration` block — `--fixture-id`,
  `--ruleset-version`, `--run-index`, `--reader-family` — and names fixture
  runs `<date>-<fixture>-<ruleset>-r<k>.json`. Without these the §9 attribution
  matrix was unreconstructable and the k = 3 replicates of one fixture differed
  only by a collision-breaking filename suffix. `--fixture-id` without
  `--ruleset-version` is refused.
- Control 2 of the validation protocol asked for a different model *family*,
  which no implementation here can select — so it was breached on every run,
  undetected. It now matches brief §F7, and the family that ran is recorded
  either way rather than the risk being silently discharged.

- **A fixture is now two files**: `<id>.md` carries the document and nothing
  else, `<id>.key.yaml` carries the frozen answer key. 🛑 A single file put
  `must_preserve` and the `q:`/`a:` pairs in the frontmatter of the document
  itself, which `census.sh` reads as a block and `verify-facts.sh` greps — so a
  cold Reader scored 100 % with no transform at all, and a fragment quoted in
  the frontmatter satisfied the fact gate on a body that had deleted every
  occurrence. Both instruments reported a pass they never ran.
- `document_sha256` in the key makes "fixtures are frozen" mechanical:
  `just check-fixtures` verifies it and refuses to run on a drifted fixture.
- `just check-fixtures` no longer counts `fixtures/README.md` as a fixture.
- `.markdownlint.jsonc` sets `MD025: { front_matter_title: "" }`, so the
  `title:` + H1 convention every document in `docs/` uses is legitimate rather
  than merely tolerated. The repo now lints clean.

### Fixed — second review, 2026-08-27

13 findings, all closed, each with a positive and a negative control run by
hand.

- 🛑 **Five more gates that reported a pass they never ran.** The four
  `access/` checks fed their loop from `done < <(jq …)`, and
  `check-render.sh` discarded lychee status with `|| true`. Every census read
  now goes through `jq_rows`/`jq_value` in the new `scripts/lib.sh`.
- 🛑 **`check-render.sh` reported a dead link as a check that did not run.**
  The transport-failure pattern was matched against the whole `[ERROR]` line,
  URL included, so a 404 on `…/proxy-guide` matched `proxy`. The URL is
  stripped before the reason is matched.
- 🛑 **`ledger.sh` lost the evidence it exists to collect.** `exit 4` inside a
  command substitution ended the subshell only and left a truncated entry; a
  same-day rerun overwrote the previous one; and `survived` was hard-coded
  `null`, so fact survival — the one gate that is not tunable — was never
  recorded. Inputs are now validated up front, entries are built into a temp
  file and moved, reruns take a `-2` suffix, and `--facts` requires
  `--facts-survived`.
- **`census.sh` lost every marker past a block first line**, which is where
  most markers sit; V7 and the density budget were computed from a truncated
  set. `source` is now absolute, and an empty parse exits 4 rather than 1.
- **V2 reported its best possible value** on a document shorter than the
  window, and **V6 dropped the final section**, returning `null` at two
  sections. Both now report `null` when not measurable.
- **`metrics.sh --wrap` with no value exited 1** — "the document failed the
  gate" — instead of 2.
- **`just profile` read the status of `jq` and `sed`, not of the checks**, so a
  check that exited 4 printed nothing and read as clean.

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
