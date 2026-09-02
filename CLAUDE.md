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
  drives discovery and triggering; the body is the pass. ⛔ The **150-line
  ceiling (brief §T4) is withdrawn since 2026-09-01** — unmeasured, and a line
  is a wrap artifact at 80 columns, not a unit of content. Detail still lives in
  `references/` because it is loaded on demand, not to hit a number.
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
- **`skills/shape/scripts/first-window.sh`** — emits the document as far as the
  fold and nothing after it, on `V3_first_screen.blocks_in_window`. ⭐ It is the
  material for a **truncated-input** retrieval run: a Reader handed only this
  cannot ingest the whole document, because it was never given the whole
  document. ⚠️ It selects and grades nothing — a verdict here would make it the
  seventh check, which the saturation rule forbids.
- **`skills/shape/scripts/access/`** — the structural rules, owned here rather
  than imported from lucid-lint. Rules are promoted *outward* once measured;
  see that directory's README for the promotion bar.
- **`skills/shape/scripts/ledger.sh`** — writes `runs/<date>-<slug>.json` on
  every pass — the slug is the document path, the fixture id, or the opaque
  `--external` id — and ⚠️ never overwrites: a same-day rerun takes a `-2` suffix,
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
  `document_sha256`. ⚠️ `T2-topology-01a`/`-01b` are an **A/B pair** and
  `T2-topology-02a`/`-02b`/`-02c` an **A/B/C triple** — same content, differing
  in one section — and scoring one arm without the others reintroduces the
  blindness they exist to measure.
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
   a set of judgement calls rather than a rulebook. Deterministic detections go
   down into `lucid-lint`; only judgement calls stay in the skill body.
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
  turns out to track locate cost, the gate comes back — ⚠️ **suspended, not
  dropped, since 2026-08-31**: there is no valid locate-cost measure left to
  correlate against, so the condition cannot be evaluated until one exists. If no F12 metric
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
- **A Jira key is not all-caps, and `emit()` matched once per line.** Two
  independent holes in `extract-facts.sh`, found 2026-09-01 from a session
  report on a document with five Jira keys and zero `identifier` facts.
  `[A-Z]{2,}-[0-9]+` cannot match `CN2-598` — a project key may carry digits
  after its first letter — and `emit()` used a bare `match()`, so only the
  *first* occurrence of a kind on a line was inventoried: `PROJ-12 and ABC-9`
  protected one of two. ⚠️ The reported cause was macOS awk ignoring `{2,}`
  intervals; that is **wrong** — one-true-awk 20200816 applies them, verified
  directly. It is the sibling of the `\b` rule below and reads identically
  from outside, which is why it must be checked rather than assumed. Fixed to
  `[A-Z][A-Z0-9]+-[0-9]+` and a scanning loop; fact counts rose 68 → 113 on
  this repo's own brief. 🛑 Every one of those 45 was a fact the 100 % gate was
  reporting as protected while never looking at it.
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
- **A stack trace is not a reason.** `check-render.sh` classified a failed
  `mmdc` as *the browser is unavailable* whenever its output matched
  `puppeteer` — and mermaid renders inside the browser, so a genuine **parse
  error** carries a stack whose every frame names a puppeteer file. Found
  2026-09-01, the moment a browser was actually available to fail properly: a
  deliberately malformed block reported NOT RUN. Stack frames and file paths are
  stripped before the reason is matched, exactly as lychee strips the URL. ⚠️ The
  bug was invisible while nothing rendered — a classifier is only exercised once
  the thing it classifies can succeed.
- **Zero rows means different things in different checks.** An empty *fact
  inventory* is an extraction that failed — exit 4. An empty *selection* (no
  headings in this document) is a real document — exit 0, and never a ✅.
  Collapsing the two either hides a broken extractor or fails clean documents.
- **Instrumentation has a saturation point, and this repo reached it on
  2026-08-28.** Eight F12 metrics and six access checks, none calibrated. ⛔ Do
  not add a ninth number or a seventh check before a corpus exists. The
  `table-misfit` definition rule was caught only because a real document set
  was available to run it against; without one, the next bad rule ships.
- **A null result can belong to the instrument, not to what it measures.**
  Two documents scored identically on retrieval and the conclusion drawn was
  "these forms cost the same". The third measurement looked at what the Readers
  *did*: all nine loaded the whole document and none issued a `grep`. The
  measure counted navigation from a subject that never navigates. ⭐ So before
  reading a null result as a fact about the documents, read the transcript of
  what the instrument's subject actually did — the number alone cannot tell an
  insensitive measure from an invalid one, and the two call for opposite
  responses: more data, or a different instrument.
- **A gate counts distinct things, never occurrences of them.**
  `verify-facts.sh` reported one line per inventory entry, and `grep -F`
  searches the whole document — so N entries carrying the same fragment were
  one verification reported N times. A `50/50 facts survived` was nine strings.
  ⚠️ The trap is that the inflated number is the *reassuring* one, so nothing
  downstream ever questions it, and a producer fix that legitimately finds more
  occurrences makes the gate look stronger while covering exactly as much.
  Measured 2026-09-01 across the whole corpus; the denominator is distinct
  fragments and the count doubles as the coverage signal.
- **Markers are a closed set with a density budget.** A marker is an eye-catch,
  and eye-catch is a budget. Markers that drift into decoration are a defect
  even when they are in the table.

## State — what is open

Scaffolded 2026-08-27 from `docs/shape-brief.md`, then hardened the same day
after a code review of the initial commit — 11 findings, all fixed, each with a
regression exercised by hand. Nothing released; version `0.1.0` in both
manifests is a placeholder.

### Start here — reconciled 2026-09-02, findings dated 2026-09-01

⚠️ The two dates are not a typo: the wrap that reconciled this section ran past
midnight. Every finding below was measured on 2026-09-01 and nothing was
measured on the 2nd.

**Settled.** The locate-cost half of the primary metric is withdrawn: *blocks
opened* counts navigation and the cold Reader ingests instead of navigating, so
it is an invalid measure rather than an insensitive one. `SKILL.md` §5 says so
where the gate stood, and the report contract now states that the gates do not
cover form.

**Settled 2026-09-01, and both are the same defect in two instruments.** The
fact gate counted inventory entries, not distinct fragments — a
`50/50 facts survived` was nine strings — and `check-render.sh` honoured the
Chrome revision mermaid-cli pins, so every mermaid diagram reported NOT RUN on a
machine holding two newer Chromes. ⭐ Both were a number that read as a verdict
and was a statement about something else. The corpus now runs **7 fixtures, 0
failure, 0 not run**, with fact counts of 9–21 where they read 29–79.
⚠️ **Outside an agent's command sandbox.** Inside one the same command still
reports **2 not run** and exits 1, because headless Chrome cannot launch under
seatbelt — a statement about the sandbox, not about the corpus. `.wrap.md`
carries the rule.

⚠️ **And changing that denominator broke its consumer, which is the part worth
remembering.** `ledger.sh` still computed `inventory` as the entry count, so it
wrote `all_survived: false` on a document where nothing was lost — 21 survived
against an inventory it called 79. Fixed the same day, with the entry count kept
beside it as `inventory_entries`. 🛑 The definition of *distinct* now lives in
two scripts and they must move together.

⭐ **The material for the human first-screen test is identified**, which is the
one thing standing between the form question and an answer. Not a fixture: a
real dossier of seven documents in another repo, with a before arm and an after
arm differing only in the figures, and a human verdict already on record.
`references/calibration.md`, under *The material for the human test*.

**Open, ranked.**

1. **An instrument now grades what is above the fold — and only that.**
   `scripts/first-window.sh` hands a cold Reader the slice above the fold and
   nothing else. Measured 2026-09-01 on the frozen triple: **a 3/30 · b 30/30 ·
   c 29/30**, the first separation this corpus has produced. ⭐ The exit
   condition is met for **consolidation**. 🛑 It is **not** met for form: `b → c`
   stays 30 against 29, so a table and a graph remain indistinguishable, and the
   claim *this form reads better* is still unmeasured. ⚠️ And the honest reading
   of the win is narrow — the questions need the topology and the instrument
   rewards the arm that put it above the fold, which is nearly tautological.
   Full entry and limits in `references/calibration.md`.
2. **The corpus is seven documents and covers three of the five tasks.**
   `T2-runbook-01` (`execute`) and `T2-adr-01` (`decide`) landed 2026-09-01,
   each planting one defect per acceptance question of its own ruleset, listed
   in the key under `planted:`. ⚠️ Neither is an A/B arm and neither measures
   form. Still missing: `learn` and `comply`. The idempotence regression, the
   diagnose regression and every `.shape.toml` threshold remain unbuilt — the
   fixtures now exist to build them against, which they did not before.
   🛑 **And widening the corpus immediately found an instrument defect**, which
   is what widening it was for: `extract-facts.sh` is blind to a quantity
   written in words, so `T2-adr-01` yields **2 facts** and the 100 % gate
   reports a green 2/2 over a document whose every number it cannot see. Failing
   towards a pass, again. Entry and the reason it is not patched yet in
   `references/calibration.md`.
3. **What limit, if any, `SKILL.md` should carry — open since the ceiling was
   withdrawn 2026-09-01, and the way in is dogfooding.** Run `shape` on
   `SKILL.md` itself and let the protocol name its own constraint, instead of a
   proxy chosen by the author. 🛑 `diagnose` only, or against a copy: the install
   is a symlink, so a mutating pass edits the protocol while it is executing.
   ⚠️ Not ticketed, same reason.

**What will look like a contradiction and is not.**

- `docs/shape-brief.md`, `docs/shape-spec-v1.1.md` and
  `docs/shape-validation-protocol.md` still *define* F7 and control 5 with
  blocks opened as locate cost, each with a dated ⛔ retraction beside it. They
  are superseded in place, never rewritten, so a reader arriving with the old
  claim can still recognise it. ⚠️ `SKILL.md` §4 still *collects* the number —
  for the ledger, never for a score — which is deliberate and says so.
- `just check-fixtures` can exit non-zero on a corpus with nothing wrong with
  it. ⚠️ That is a property of the machine, not of the fixtures: any check that
  reports **NOT RUN** raises the count. The exit-code contract forbids reading a
  NOT RUN as a pass. ✅ **The mermaid instance of it is closed 2026-09-01** —
  `check-render.sh` now resolves a browser out of the puppeteer cache instead of
  honouring the revision mermaid-cli pins, and the corpus runs **0 not run** on
  this machine. Setup and the two overrides in `references/render-targets.md`.
- ⚠️ **`runs/` is gitignored.** The five ledger entries exist only on this
  machine, and they are un-reproducible measurements. Whether the accumulation
  the ledger exists for should be committed is an open question that the
  `--external` scrub now makes answerable. 📌 Their fact counts are **entry**
  counts — the old denominator — and are not comparable with anything measured
  after 2026-09-01. Their survival figures stand; every one was 100 %.
- **Two documents still carry the pre-2026-09-01 numbers on purpose.** The
  `CHANGELOG.md` entry recording *5 fixtures, 0 failures, 2 NOT RUN* and the
  fact counts *29–79* in `references/calibration.md` are both dated records of
  what was true when written, each superseded in place rather than rewritten.
  ⚠️ A changelog is history by construction — reading an old entry as current
  status is the misread to expect, not a defect to fix.
- **The `runs/` entries and the ones written after 2026-09-01 disagree about
  what `inventory` counts**, and both are right for their date. Before, entries;
  after, distinct fragments, with the entry count preserved beside it as
  `inventory_entries`. An entry holding only `inventory` is a pre-2026-09-01 one.

**Resume block** — paste as the opening message of a fresh session:

```text
Repo: ~/Dev/oss/skills/shape. Read CLAUDE.md `## State — what is open`,
`### Start here` first, then skills/shape/references/calibration.md.
Corpus: 7 fixtures, 3 of 5 reader tasks; `learn` and `comply` have none.
Next: the human first-screen test. Its material is a real seven-document
dossier already identified in calibration.md under "The material for the
human test" — it needs a reader, not more code.
```

No document was deleted or consolidated in the passes that wrote this, so there
is no provenance record to follow. The 2026-09-01 wrap removed one dead function
— `run_or_skip()` in `check-render.sh`, callerless since `78775c6` — and
`.DS_Store` plus `docs/.DS_Store`. ⚠️ Those two were never tracked, so their
removal leaves no trace in git. Nothing that carried evidence.

- ✅ **Settled 2026-08-27 — the lucid-lint dependency is inverted.** shape no
  longer waits for an `access` category; the six structural rules are
  implemented under `scripts/access/`, each with a positive and a negative
  control. Promotion into lucid-lint is now an outward move gated on corpus
  evidence, not a blocking import.
- 📌 **`fixtures/` holds an A/B pair and an A/B/C triple, both measured.** `T2-topology-01a`/`-01b` landed 2026-08-28 with the first two
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
  ⭐ **Confirmed independently 2026-08-31** on a fourth document, in another
  repo, by an operator not looking for it: three cold Readers, one whole-file
  `Read` each, no `grep`. That pass still *reported* 5/5 → 8/11 blocks opened —
  the Reader's retrospective self-report, since `SKILL.md` §4 asks it which
  sections it had to open. 🛑 The instrument does not merely fail to measure;
  it manufactures a plausible number, which is harder to catch than a null.
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
  it. ⛔ And it grades **fact retrievability only** — its locate-cost half was
  withdrawn 2026-08-31 and `SKILL.md` §5 now says so where the gate stood.
