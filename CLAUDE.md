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
- **`skills/shape/assets/facts-schema.json`** — the fact-inventory schema that
  `extract-facts.sh` emits and `verify-facts.sh` consumes. The two must move
  together.
- **`skills/shape/templates/shape-config.toml`** — the `.shape.toml` users copy
  into their repos. Its section names (`[defaults]`, `[markers]`, `[protect]`,
  `[transforms]`, `[style]`) are parsed by `SKILL.md` §3.1; renaming one is a
  breaking change.
- **`fixtures/`** — the regression corpus (brief §T6). Currently empty; that
  gap is the main thing standing between this scaffold and a v1.
- **`install.sh`** — symlinks (default) or copies `skills/shape` into
  `~/.claude/skills/shape`. Symlink is the intended mode so edits propagate
  live without reinstalling.

## Commands

```sh
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
- **Markers are a closed set with a density budget.** A marker is an eye-catch,
  and eye-catch is a budget. Markers that drift into decoration are a defect
  even when they are in the table.

## State — what is open

Scaffolded 2026-08-27 from `docs/shape-brief.md`. Nothing released; version
`0.1.0` in both manifests is a placeholder.

- 📌 **`lucid-lint` has no `access` category** (brief §5 item 2) — heading
  informativeness, scent in the first three words, contents present, section
  length, prose-list tells, prose restating an adjacent table. This is the gap
  the whole skill is chasing, and it is currently measured by nothing. The
  brief's recommendation is that it lands **inside** lucid-lint as a 6th
  category, not in a separate analyser. Until then, `lint-delta.sh` pins
  lucid-lint's JSON schema at v2 and fails loudly on drift, and access
  structure is judged rather than measured — the report must say so.
- 📌 **`fixtures/` is empty.** No idempotence regression, no diagnose
  regression. The ruleset files can be changed today with nothing to catch it.
- 📌 **The shared norm layer with `glance` is not extracted** (brief §9 item 2).
  `glance` is this norm applied to Claude's output; `shape` is the same norm
  applied to files on disk. They currently carry two independent definitions of
  the marker set and the heading rule. `glance/build.sh` already generates
  surfaces from one `prompt.md`, so a third surface is a known move.
- 📌 **The cold-subagent retrieval loop (brief §F7) is specified, not
  scripted.** It is the primary metric and the only gate with no script behind
  it.
