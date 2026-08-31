# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with
code in this repository.

## What this repo is

A single-skill repository. It packages **one** Claude Code skill — `shape` —
and nothing else. There is no application and no test suite; the "product" is
the protocol prose plus five verification scripts. `SKILL.md` is the
deliverable, and everything else exists to install, lint, and iterate on it.

`shape` improves a docs-as-text document *for its reader's task* and proves it
did — a fact-survival gate at 100 % and a cold-subagent retrieval test, rather
than a word count.

## Files that matter

- **`docs/shape-spec-v1.1.md`** — the evolution spec, and the amendment in
  force: lucid-lint stops being a gate, visual rhythm becomes a measured
  property, every pass writes a ledger. It amends the brief's §5 and §6 and
  adds F12. Where the two disagree, the spec wins.
- **`docs/shape-brief.md`** — the requirements brief the skill is written
  *from*. It is the spec, not the skill body, and it is addressed to the skill
  author. Every design question already answered lives here; read it before
  proposing a change to the protocol. Its `§F1–F11` / `§T1–T6` labels are the
  reference scheme `SKILL.md` and `CHANGELOG.md` cite.
- **`skills/shape/SKILL.md`** — the canonical protocol and the only prose file
  Claude executes. YAML frontmatter (`name`, `description`, `argument-hint`)
  drives discovery and triggering; the body is the pass. 🛑 Keep it **≤ 150
  lines** (brief §T4) — that ceiling is what keeps it read reliably, and it is
  the reason detail lives in `references/` rather than inline.
- **`skills/shape/references/tasks/<task>.md`** — one ruleset per reader task,
  loaded on demand. Each declares target shape · allowed transforms ·
  **forbidden** transforms · acceptance questions. The five slugs
  `locate|execute|decide|learn|comply` are load-bearing: they appear in the
  frontmatter `argument-hint`, in `SKILL.md` §2, in the config template, and as
  filenames. Renaming one is a breaking change in four places.
- **`skills/shape/references/render-targets.md`** — the capability matrix.
  Fallbacks are *declared here*, never improvised at edit time.
- **`skills/shape/references/markers.md`** — the closed marker set. Closed
  means closed: `.shape.toml` may narrow it, never extend it.
- **`skills/shape/scripts/*.sh`** — one script per verification, each with an
  exit-code contract stated in its header comment. See the contract below.
- **`skills/shape/scripts/lib.sh`** — `jq_rows` and `jq_value`, the two guarded
  ways to read the census. 🛑 Sourced by every `access/` check; adding a sixth
  check means sourcing it too, not hand-rolling a sixth producer.
- **`skills/shape/assets/facts-schema.json`** — the fact-inventory schema that
  `extract-facts.sh` emits and `verify-facts.sh` consumes. The two must move
  together.
- **`skills/shape/templates/shape-config.toml`** — the `.shape.toml` users copy
  into their repos. Its section names (`[defaults]`, `[markers]`, `[protect]`,
  `[transforms]`, `[style]`) are parsed by `SKILL.md` §3.1; renaming one is a
  breaking change.
- **`skills/shape/scripts/census.sh`** — one parse, many metrics. ⛔ Nothing
  downstream re-parses the document; `metrics.sh` and the `access/` checks are
  functions over its output. Its schema is `assets/blocks-schema.json`.
- **`skills/shape/scripts/access/`** — the structural rules, owned here rather
  than imported from lucid-lint. Rules are promoted *outward* once measured;
  see that directory's README for the promotion bar.
- **`skills/shape/scripts/ledger.sh`** — writes `runs/<date>-<doc>.json` on
  every pass, and ⚠️ never overwrites: a same-day rerun takes a `-2` suffix,
  because two passes over one document in one day is the normal loop and the
  second silently replacing the first destroys the evidence. `--facts` requires
  `--facts-survived`. This is the instrument that makes both open questions
  answerable by accumulation instead of by argument, so a pass that skips it
  costs evidence that cannot be recovered later.
  `--external <id>` is the regime for a document that may not be described
  here: counts and metrics survive, `doc` / `census.source` / every heading in
  `census.blocks[].path` are replaced by an opaque id, and the entry is refused
  if a path survives anywhere in it. ⛔ Exclusive with `--fixture-id`.
- **`skills/shape/references/calibration.md`** — how a threshold is earned, and
  both falsification conditions. Read before changing any number anywhere.
- **`fixtures/`** — the regression corpus (brief §T6) and the calibration
  corpus (spec §5). Two files per fixture, never one: `<id>.md` is all any
  instrument or Reader sees, `<id>.key.yaml` holds the answers and the frozen
  `document_sha256`. ⚠️ `T2-topology-01a`/`-01b` are an **A/B pair** — same
  content, table vs graph — and scoring one arm without the other reintroduces
  the blindness the pair exists to measure.
- **`install.sh`** — symlinks (default) or copies `skills/shape` into
  `~/.claude/skills/shape`. Symlink is the intended mode so edits propagate
  live without reinstalling.

## Commands

```sh
just profile <file>      # census + F12 + access checks for one document
just lint                # markdownlint over every .md
just check-versions      # plugin.json and marketplace.json agree
just check-fixtures      # run the scripts over fixtures/*.md
just package             # build dist/shape-v<version>.skill
just release 0.2.0       # bump both manifests, commit, tag

./install.sh             # symlink into ~/.claude/skills/shape
./install.sh --copy      # copy instead
```

Run a single verification directly — this is how to test a script change:

```sh
skills/shape/scripts/extract-facts.sh docs/shape-brief.md > "$TMPDIR/facts.json"
skills/shape/scripts/verify-facts.sh "$TMPDIR/facts.json" docs/shape-brief.md
skills/shape/scripts/lint-delta.sh --baseline docs/shape-brief.md
skills/shape/scripts/lint-delta.sh --compare  docs/shape-brief.md
skills/shape/scripts/check-render.sh docs/shape-brief.md --target github
skills/shape/scripts/check-idempotence.sh first.md second.md
```

## The exit-code contract

Every script follows it, and `SKILL.md` §0.4 depends on it:

| Exit | Means | The skill must |
| --- | --- | --- |
| 0 | passed | report ✅ |
| 1 | findings — the document failed the gate | report ❌, stop the pass |
| 2 | usage error, unreadable input | fix the invocation, not the document |
| 3 | tool absent, errored, or schema drifted | report **not run** — never *passed* |
| 4 | a positive control failed | the check itself is untrustworthy |

⚠️ 3 is the load-bearing one. *A verification you skipped is not a verification
you passed* — a crashed linter must never read as a clean document.

🛑 **The failure mode this repo keeps producing is a gate that reports a pass
it never ran.** Two code reviews on 2026-08-27 found it **eight** times: three
in the first five scripts, then five more in the v1.1 increment — the four
`access/` checks, and `check-render.sh` discarding lychee status with
`|| true`. Always the same shape: a producer whose failure `set -euo pipefail`
cannot see. The loop reads zero rows, and the script prints `0/0 facts
survived` / `✅ headings carry scent` and exits 0.

⚠️ **It came back in the very increment that documented it.** Writing the rule
here did not prevent it; a shared guard did. The rule any new script must
follow:

- **Run the producer in its own statement, into a real file, and check it.**
  Never `done < <(jq …)`. Never process substitution at all — `/dev/fd` is also
  unavailable under some sandboxes, where `diff <(…) <(…)` fails and reads as a
  *semantic diff* on a document that is fine.
- **Zero rows is exit 4, not exit 0.** An empty inventory is an extraction that
  failed, not a document with nothing to protect. ⚠️ With one deliberate
  exception, stated in `access/README.md`: a *selection* that legitimately
  matches nothing — no headings, no tables — is not a failed extraction. Those
  checks print "nothing to check" and exit 0. They never print ✅.
- **Read the status of every script in its own statement, including in the
  `justfile`.** `check.sh … | jq` reads jq's status, so a check that exited 4
  printed nothing and read as clean. `just profile` was doing exactly this.
- **Source `lib.sh`.** `jq_rows` for a row stream, `jq_value` for a scalar.
  Hand-rolling the pattern is how it got written four more times.

## The iteration loop

The protocol is improved by running it on real documents, then folding what the
run exposed back into the prose:

1. Run `shape` on a real document; capture friction verbatim as it happens.
2. Decide where it belongs. **Anything mechanically decidable is a linter rule,
   not a prompt instruction** (brief §T1) — that split is what keeps `SKILL.md`
   under its line ceiling. Deterministic detections go down into `lucid-lint`;
   only judgement calls stay in the skill body.
3. Fold it: a task ruleset, an always-on directive in §0, or an anti-pattern in
   §8. Record the *why* under `## Design decisions worth not re-litigating`, so
   the reasoning does not live only in git history.

**Editing `SKILL.md` while shaping this repo's own docs is a hazard**, not a
convenience: the install is a symlink, so the protocol changes while it is
executing and the run stops being reproducible. Capture during the pass; edit
after it closes.

## Design decisions worth not re-litigating

- **Name is `shape`, bare.** Settled in the brief: one free autocomplete
  initial, monosyllabic verb-and-noun like `wrap` and `glance`, and broad
  enough to cover `diagnose` as well as `condense` — which `carve` or `hone`,
  naming only the cutting, would not. The directory `docs/` still holds the
  brief under the settled name; an earlier `doc-shape-brief.md` is superseded.
- **`diagnose` is the default, not `condense`.** The prototype's failure mode
  was starting from condensation. The default is what prevents it, so a change
  that makes another mode the default reintroduces the exact bug.
- **Word count is informational, permanently.** The prototype's own
  2026-08-25 measurement — a restructuring that felt large and measured
  −4.8 % — is why. The report must not credit effort.
- **lucid-lint is a signal, not a gate, and shape does not wait for it.** Two
  reasons, both recorded so the decision can be revisited: the five categories
  are intra-sentential, so a document written well sentence by sentence and
  unusable structurally scores high — gating on it would validate exactly what
  shape rejects; and converting prose to tables raises the score mechanically,
  which hands shape a lever on its own grade. The dependency arrow is inverted
  with it: structural rules are written locally under `scripts/access/` and
  promoted outward once a corpus has measured them, because a deterministic
  rule is badly designed in the abstract.
- **Every number ships unvalidated, and says so.** The v1.1 increment delivers
  a census, a metric set and a calibration protocol — not thresholds. Expect
  two or three of the seven F12 metrics to survive; that is the protocol
  working, not the increment failing. ⚠️ And when they are calibrated, n ≈ 12
  and one author: a locally useful setting, never a finding.
- **Both changes carry a written falsification condition.** If the lint score
  turns out to track locate cost, the gate comes back. If no F12 metric
  separates high-cost from low-cost documents, F12 reverts to advisory prose
  and ships no numbers. Neither condition may be quietly dropped — they are
  what makes the increment a claim rather than a preference.
- **The transforming agent never grades.** Retrieval scoring runs in a cold
  subagent with fresh context. This is not caution; a self-graded retrieval
  test measures nothing.
- **Two orthogonal axes, not one genre.** Audience and reader task are
  independent — a FALC procedure and a FALC reference page need opposite
  structures. Collapsing them into one classification looks simpler and is
  wrong.
- **Fact loss is a failure, never a trade-off.** The 100 % gate is not tunable.
  A skill that reports "3 facts dropped for concision" has become the thing it
  exists to prevent.
- **Policy is configuration, method is the skill body.** Depersonalising,
  worktree use, English-only were fused into the prototype's method; they are
  now `.shape.toml` keys, off by default. ⚠️ Depersonalise is actively wrong on
  a credits page or an ADR.
- **`verify-facts.sh` reads fragments as base64, not `@tsv`.** jq's `@tsv`
  escapes a literal backslash to `\\`, which turned a `\|` inside a table cell
  into a pattern matching nothing. Measured 2026-08-27 on this repo's own
  brief: one false LOST on a document that had not been edited at all. The
  positive controls in that script exist because a fact checker that reports
  false losses is worse than none.
- **Every script reads its exit status in its own statement.** In a pipe you
  read `tail`'s status, not the command's — and under `set -e` a bare
  command-substitution assignment aborts before you can classify a non-zero as
  *findings* rather than *crash*. Both traps were paid for; do not "simplify"
  the assignments back.
- **`verify-facts.sh` refuses a multi-line fragment rather than checking it.**
  `grep -F` on a multi-line pattern matches an OR of its lines, not the block,
  so a two-line protected fact whose second line was deleted reported ✅. The
  obvious repair — `grep -qzF` — is worse than the bug here: `grep` on this
  machine is ugrep, where `-z` means *decompress*, and it matched a fabricated
  block. So the script enforces brief §F4 instead: the fragment lives on one
  line. That is what `grep_fragment` is for, and `extract-facts.sh` now always
  emits one.
- **A fact's fragment is the distinctive token, not the source line.** §T3
  mandates section-level edits, which reflow lines; a checker keyed to the line
  fails a pass where nothing was lost. ⚠️ `normative` is the deliberate
  exception — `comply.md` forbids rewording a normative sentence at all, so a
  reflowed one *has* been modified and the strict whole-line check is right.
- **No `\b` or `\<` in any awk regex.** The one-true-awk shipped on macOS
  ignores them silently — which dropped every normative fact on a document that
  had four, with no error. Use `([^A-Za-z]|$)`.
- **`ln -sfn` does not replace a real directory.** It creates the link *inside*
  it and exits 0. `install.sh` removes a non-symlink target first and then
  verifies its own `readlink`, because the failure it prevents is a `✅ Skill
  linked` over a stale copy that keeps being served.
- **Idempotence ignores trailing whitespace only.** In Markdown, leading
  indentation is list nesting and a blank line is a paragraph boundary;
  `--ignore-all-space --ignore-blank-lines` called a re-nested list and two
  merged paragraphs "whitespace-only".
- **A metric that cannot be computed reports `null`, never its best value.**
  V2 returned `0` — the ideal score — on any document shorter than its window,
  so a short dense wall of prose graded perfect. ⚠️ The direction of the error
  is what matters: a metric that fails *towards* a pass is worse than one that
  fails loudly, because nothing downstream ever asks again.
- **No apostrophe inside a single-quoted `awk` or `jq` program.** It closes the
  string, and the shell then parses the program body as shell. Cost twice on
  2026-08-27, both times as `syntax error near unexpected token` pointing at a
  line that was fine. Write "the opening line of a block", not "the block's
  opening line".
- **Zero rows means different things in different checks.** An empty *fact
  inventory* is an extraction that failed — exit 4. An empty *selection* (no
  headings in this document) is a real document — exit 0, and never a ✅.
  Collapsing the two either hides a broken extractor or fails clean documents.
- **Instrumentation has a saturation point, and this repo reached it on
  2026-08-28.** Eight F12 metrics and six access checks, none calibrated. ⛔ Do
  not add a ninth number or a seventh check before a corpus exists. The
  `table-misfit` definition rule was caught only because a real document set
  was available to run it against; without one, the next bad rule ships.
- **Markers are a closed set with a density budget.** A marker is an eye-catch,
  and eye-catch is a budget. Markers that drift into decoration are a defect
  even when they are in the table.

## State — what is open

Scaffolded 2026-08-27 from `docs/shape-brief.md`, then hardened the same day
after a code review of the initial commit — 11 findings, all fixed, each with a
regression exercised by hand. Nothing released; version `0.1.0` in both
manifests is a placeholder.

- ✅ **Settled 2026-08-27 — the lucid-lint dependency is inverted.** shape no
  longer waits for an `access` category; the six structural rules are
  implemented under `scripts/access/`, each with a positive and a negative
  control. Promotion into lucid-lint is now an outward move gated on corpus
  evidence, not a blocking import.
- 📌 **`fixtures/` holds an A/B pair and an A/B/C triple; none of the triple is
  measured yet.** `T2-topology-01a`/`-01b` landed 2026-08-28 with the first two
  ledger entries. `T2-topology-02a`/`-02b`/`-02c` landed 2026-08-31: 20 services,
  30 edges, ~950 words, ten frozen questions of which four need a reverse edge.
  ⭐ Its three arms separate the two variables `01` confounded — `a → b` is
  consolidation, `b → c` is form — and 🛑 no arm is evidence on its own.
  Measured 2026-08-31: **30/30 on all three arms**, 1.67 / 1.67 / 2.00 blocks
  opened, reader tokens within 0.7 %. Still blocked on more fixtures beyond
  topology: the idempotence regression, the diagnose regression, and every
  threshold in `.shape.toml`.
- ⚠️ **`01` restates its own topology in prose**, in `Deploy order` and
  `On call`. Found 2026-08-31. It is a third live explanation for the `01` null
  result and it is left in place — the document is frozen and its two ledger
  entries would be discarded by a re-cut. `02` does not reproduce it.
- 📌 **The v1.1 increment is implemented through step 3 of its own sequencing.**
  Census, metrics and ledger exist and run. Steps 4–6 (corpus, calibration,
  gates) are untouched, by construction: they need documents and cold-subagent
  retrieval runs, not code.
- 📌 **The shared norm layer with `glance` is not extracted** (brief §9 item 2).
  `glance` is this norm applied to Claude's output; `shape` is the same norm
  applied to files on disk. They currently carry two independent definitions of
  the marker set and the heading rule. `glance/build.sh` already generates
  surfaces from one `prompt.md`, so a third surface is a known move.
- 🛑 **The primary metric does not measure locate cost at all — the mechanism
  was found 2026-08-31, and it is the most consequential thing known about this
  protocol.** Across the `02` triple, **all nine cold Readers loaded the whole
  document and not one issued a single `grep`.** *Blocks opened* counts
  navigation; this Reader does not navigate, it ingests. ⛔ So the measure is
  **invalid, not insensitive** — no larger k, no further arm and no document of
  this size can rescue it. Two rival explanations for the earlier null result
  are discharged with it: the document was not too small (1.8× longer, 3.3× the
  edges, less separation), and `01`'s prose restatement of its own topology was
  not what did it (`02` has none and still scored perfectly). The exit
  condition is now concrete — a Reader that cannot hold the document, or a human
  first-screen test — and is written in `references/calibration.md`.
- 🛑 **The earlier form-blindness entry — measured 2026-08-28.** An `access-only` pass
  scored 35/35 on the access checks and 8/8 on retrieval over a dossier of 7
  documents carrying 27 tables and zero figures; a later non-`shape` pass added
  15 mermaid diagrams to the same documents because they were unreadable. ⚠️ No
  accumulation of runs will surface this — the instrument that would record the
  evidence is the one that cannot perceive it. **Tested 2026-08-28 on the A/B
  pair: 24/24 both arms, blocks opened 2.67 vs 3.00, all six access checks
  identical.** Locate cost was the candidate companion measure and it did not
  move either. Only `V8_table_share` and `V5_figure_mention` separated the two
  forms. Full entry, the three limits of that measurement, and the exit
  conditions in `references/calibration.md`.
- 📌 **The cold-subagent retrieval loop (brief §F7) is specified, not
  scripted.** It is the primary metric and the only gate with no script behind
  it.
