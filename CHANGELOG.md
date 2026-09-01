# Changelog

## Unreleased

### Changed — 2026-09-01 (the fact gate stops counting repeats)

- `verify-facts.sh` reports **distinct fragments**, not inventory entries. N
  entries carrying the same fragment were one verification reported N times —
  `grep -F` searches the whole document, so they pass and fail together.
- 🛑 The corpus, before and after: `T2-topology-01a` 50 → **9**,
  `T2-topology-02b` 79 → **21**, `T2-runbook-01` 21 → **14**. A
  `50/50 facts survived` was nine strings.
- ⭐ Detection is unchanged. A fragment present anywhere still passes; one
  deleted everywhere still fails. Seven hand-run controls, including a fragment
  appearing three times and removed from all three.
- ⚠️ The five existing `runs/` entries record the old denominator. Their
  survival figures stand; their fact counts are not comparable with later ones.
- The summary now names the collapse — `21/21 distinct facts survived
  (79 inventory entries, 58 repeats collapsed)`.
- Below `SHAPE_MIN_FACTS` (default 5) the run says the gate is protecting very
  little of the document and why. ⚠️ Uncalibrated and advisory: it changes what
  is printed, never the exit code.
- `justfile` — `check-fixtures` read the verification through `| tail -1`, which
  showed the warning's least informative line and hid the count it warned about.
  It now reads the status in its own statement and prints from the first loss,
  or the summary, to the end.

### Fixed — 2026-09-01 (a mermaid diagram is finally rendered, not skipped)

- `check-render.sh` **resolves the browser `mmdc` drives** instead of leaving
  the choice to the revision mermaid-cli pins — the newest
  `chrome-headless-shell`, else the newest `chrome`, under
  `${PUPPETEER_CACHE_DIR:-~/.cache/puppeteer}` — and prints which one it used.
  Nothing is downloaded. Overrides, in precedence order:
  `SHAPE_PUPPETEER_CONFIG`, then `PUPPETEER_EXECUTABLE_PATH`.
- 🛑 The pin was the whole blockage: mermaid-cli 11.13.0 demanded Chrome
  **131.0.6778.204** on a machine holding 148 and 152, so both mermaid arms of
  the corpus reported **NOT RUN** on diagrams that render. `just check-fixtures`
  now runs **7 fixtures, 0 failure, 0 not run**; the caveat in `CLAUDE.md` that
  a clean corpus could exit non-zero is closed for its mermaid instance.
- 🛑 **And the classifier was wrong, which only a working browser could show.**
  A failed `mmdc` was read as *browser unavailable* whenever its output matched
  `puppeteer` — but mermaid parses inside the browser, so a genuine **parse
  error** carries a stack whose every frame names a puppeteer file. A malformed
  block reported NOT RUN. Stack frames and file paths are now stripped before
  the reason is matched, as lychee already strips the URL, and the ❌ line
  carries the parse error rather than the progress banner.
- ⚠️ The three outcomes are controlled by hand: a valid fixture ✅ exit 0, a
  malformed block ❌ exit 1, an empty `PUPPETEER_CACHE_DIR` ⚠️ NOT RUN exit 3.
  A diagram that was never rendered is still never a diagram that renders.
- **`--out-dir DIR`** keeps the compiled SVGs and prints their paths, so a human
  can *look at* the diagram the check just graded. It changes no verdict.
- Setup, the two overrides and `--out-dir` are documented in
  `references/render-targets.md`.

### Added — 2026-09-01 (the corpus reaches `execute` and `decide`)

- `fixtures/T2-runbook-01` — an `execute` fixture: a certificate-rotation
  procedure carrying one planted defect per acceptance question of
  `references/tasks/execute.md` — a step with two actions, a conditional step
  whose action precedes its condition, a prerequisite that only surfaces at the
  step needing it, and a step with no expected result.
- `fixtures/T2-adr-01` — a `decide` fixture: four options as four prose
  paragraphs, an unmarked and hedged recommendation, and one option rejected
  without a reason. ⭐ Its Q5 is a trap — the obvious repair is an option table,
  and tidying that table means dropping the reasonless option, which
  `decide.md` forbids.
- ⚠️ Both are single documents, not A/B arms. They measure whether `diagnose`
  finds what its own ruleset says to find; they do not measure form. Both keys
  record the tautology caveat: one author chose what is hidden and what is asked.
- The corpus is now 7 documents over 3 of the 5 reader tasks. `learn` and
  `comply` remain unrepresented.

### Found — 2026-09-01 (`extract-facts.sh` is blind to numbers written in words)

- Surfaced by the widening itself. `T2-adr-01` is 868 words of argued prose and
  yields **2 facts**; `verify-facts.sh` reports a green **2/2 survived**.
- 🛑 Every quantity the document argues from is spelled out — *two hundred and
  forty euros a month*, *nine thousand batches a day*, *twelve duplicate rows* —
  and the extractor keys on digits and code spans. The gate does not report a
  loss it cannot see; it reports a pass.
- ⚠️ Specific to argued prose, which is `decide` and much of `learn`. The
  `locate` fixtures yield 29–79 facts and `T2-runbook-01` yields 21.
- Not patched here: a new producer in front of the 100 % gate needs its own
  controls first. Entry in `references/calibration.md`.

### Measured — 2026-09-01 (the truncated Reader, #8)

- k = 3 cold subagents per arm of the frozen triple, each handed **only** the
  slice above the fold and never the document: **a 3/30 · b 30/30 · c 29/30**.
  Nine Readers, **one tool call each**, reader tokens within 0.6 %.
- ⭐ **The first separation this corpus has produced**, and the exit condition in
  `references/calibration.md` is met for **consolidation**: two arms of identical
  content, 3/30 against 30/30, from an instrument that grades nothing itself.
- 🛑 **Not met for form.** `b → c` is 30 against 29 — a table and a graph with
  the same edges above the fold stay indistinguishable, as they were under the
  untruncated Reader. c's single miss is one Reader naming five services where
  the key has four.
- ⚠️ **The limit ships with the number.** The questions need the topology and the
  instrument rewards the arm that put the topology above the fold, which is
  close to tautological. What is measured is *what is above the fold*, not the
  cost of a form. A document can put the wrong thing there, and that now shows;
  two documents that both put the right thing there cannot be ranked.
- Arm a returned `INSUFFICIENT` rather than guessing on nine of ten questions,
  which is why the option was offered — without it the measurement would have
  scored invention.

### Added — 2026-09-01 (an instrument that can see form, #8)

- **`scripts/first-window.sh`** emits the source text of the blocks above the
  fold. ⭐ It exists to make a **truncated-input** retrieval run possible: hand a
  cold subagent this slice and the task's acceptance questions, and it cannot
  ingest the whole document because it was never given it. That is the exit
  condition from `references/calibration.md` — *a Reader that cannot ingest the
  whole document* — obtained by capping the input rather than policing the
  Reader, so there is nothing to enforce.
- **`V3_first_screen` is raised, not duplicated.** Its window is now the first
  `--window` **rendered** lines rather than the first 40 *source* lines — a
  400-character paragraph is one source line and eight rendered ones, and the
  hardcoded 40 disagreed with the window every other metric uses. It also emits
  `blocks_in_window`, which is what `first-window.sh` slices on. 🛑 Deliberately
  not a seventh access check: the saturation rule holds, and the count stays at
  8 metrics and 6 checks. 📌 Ledger entries written before this date are not
  comparable on V3.
- **The instrument separates the frozen triple before any Reader runs.** Above
  the fold: `02a` carries **7 of 20** services, `02b` the **complete** 22-row
  dependency table, `02c` **all 30** mermaid edges. The ten frozen questions —
  four needing a reverse edge, four needing a two-hop path — are answerable from
  the fold of `b` and `c` and not from that of `a`. ⚠️ That is a mechanical
  prediction, not a result: no Reader has been run under truncation yet.
- Controls exercised by hand: metrics dead → exit 3/4 with an **empty** slice,
  never the whole file; census naming an unreadable source → exit 2; a document
  shorter than the window → emitted whole; a smaller window → a shorter slice.

### Fixed — 2026-09-01 (two scripts read and write in the wrong place, #7)

- **`check-render.sh` names the config it linted with**, and a **no-config
  failure is now NOT RUN (exit 3), never ❌**. The walk-up from the file already
  existed since 2026-08-28; what was missing is that a document held in a
  scratchpad — which is how shape edits a copy — has no config above it at all,
  so MD013 and MD041 fired although the governing repo disables both. That
  verdict was a statement about where the file sat, the same class as `mmdc`
  without a browser. ⚠️ A no-config *pass* stays ✅: stock rules are stricter
  than a config that disables some. `SHAPE_MD_CONFIG` names the governing
  config when the document is linted away from the repo that owns it.
- **`lint-delta.sh` no longer writes into the working tree.** The baseline was
  `.shape-baseline.json` relative to the cwd; it now lands under
  `$SHAPE_BASELINE_DIR` (default `$TMPDIR`), keyed by the document's absolute
  path **and** the profile. 🛑 The keying is part of the fix, not a flourish: one
  file per repo root already collided between two documents, and a shared store
  makes that certain — while a `falc` baseline compared against a `dev-doc` run
  is the same silent wrong answer one level up. Both the write and the
  missing-baseline error print the path.
- Controls exercised by hand on both: config found / absent / overridden /
  absent-but-clean, and a baseline round trip with two documents and two
  profiles. `just check-fixtures` unchanged — 5 fixtures, 0 failures, 2 NOT RUN
  for the absent mermaid browser.

### Changed — 2026-09-01 (a proxy withdrawn)

- The **150-line ceiling on `SKILL.md` is withdrawn**, in `CLAUDE.md`, in
  `.wrap.md` (the Seiso `wc -l` check goes with it) and in `docs/shape-brief.md`
  §T4 and §T1 — ⛔ retracted in place there, never rewritten. Three reasons, none
  of them the body getting longer: the number was never measured; a *line* is a
  wrap artifact at 80 columns rather than a unit of content; and the rationale
  it rested on ("small enough to be read reliably") is a claim about attention,
  which line count is a proxy for and does not measure. The repo already applies
  this standard to *blocks opened*.
- 📌 It was never breached under its own convention: the v1.1 increment counted
  the body after the frontmatter — 144 lines then, 145 now, against 150. The
  159 that `CLAUDE.md` reported counted the frontmatter too.
- **What limit `SKILL.md` should carry is now open**, ranked 3 in
  `CLAUDE.md` `### Start here`. The way in is dogfooding: run `shape` on
  `SKILL.md` itself. 🛑 `diagnose` only, or against a copy — the install is a
  symlink.

### Changed — 2026-08-31 (reconciled to the measurement)

- The locate-cost gate is **withdrawn** everywhere it was still enforced or
  described: `SKILL.md` §5 (where it was a live acceptance gate) and §4,
  `references/tasks/locate.md` acceptance question 4, `README.md`,
  `docs/shape-brief.md` F7 and its §6 gate table, `docs/shape-spec-v1.1.md`
  calibration step 3, `docs/shape-validation-protocol.md` control 5, its
  measures table and decision rule 5. ⛔ Retracted in place with a dated
  pointer, never rewritten — a reader arriving with the old claim must be able
  to recognise it.
- `SKILL.md` §6 report contract now states that **the gates do not cover form**,
  which `references/calibration.md` had instructed twice and nothing had done.
- ⚠️ The lucid-lint falsification condition ("if the score tracks locate cost,
  the gate comes back") is marked **suspended, not dropped**: there is no valid
  locate-cost measure left to correlate against.
- `docs/shape-spec-v1.1.md` §6 ledger schema gains the `calibration` block and
  the `external` regime, and the filename claim is corrected to
  `runs/<date>-<slug>.json` there, in `CLAUDE.md` and in `calibration.md`.
- `fixtures/README.md` reports the `02` result and states the scoring rule for a
  triple as well as a pair.

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
