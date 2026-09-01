---
title: shape — requirements brief
status: draft for review
supersedes: doc-rationalise (prototype)
---

# shape — requirements brief

**Goal** — a Claude Code skill that improves a docs-as-text document *for its
reader's task*, in any source format, and proves it did rather than asserting it.

**Intended audience** — the skill author. Not the skill body: this is the brief
the SKILL.md is written *from*.

**Contents** — Position in the stack · What the prototype teaches · Functional
requirements · Technical requirements · lucid-lint contract · Acceptance gates ·
Non-goals · Risks · Open decisions · Evidence base.

---

## 1. Position in the stack

Three layers are currently blurred across the three artefacts. Separating them is
the main architectural move.

| Layer | Question it answers | Owner today | Owner target |
| --- | --- | --- | --- |
| **Norm** | what does *clear* mean, here, for whom | duplicated in glance + prototype | one shared spec, consumed by both |
| **Measure** | is this document clear | lucid-lint (prose only) | lucid-lint + an `access` category |
| **Transform** | make it clearer | prototype (prompt-only) | `shape` |

⭐ `glance` is the norm applied to **Claude's output**; `shape` is the same norm
applied to **files on disk**. They should not carry two independent definitions of a
marker set or a heading rule. Factor the shared body out; `glance/build.sh` already
generates surfaces from one `prompt.md`, so adding a third surface is a known move.

⚠️ **The gap nobody covers.** lucid-lint's five categories — Structure · Rhythm ·
Lexicon · Syntax · Readability — are all *intra-sentential*. None measures **access
structure**: whether a reader can find a fact without reading the document. That is
the property the prototype is actually chasing, and it is currently measured by
nothing.

---

## 2. What the prototype teaches

| ✅ Keep | Why it is right |
| --- | --- |
| *What never goes* table | An editing agent silently dropping a load-bearing fact is the dominant risk. Naming the protected classes is the correct instinct. |
| Verification with positive controls | The zsh word-split trap and the pipe-exit-status trap are real, paid-for lessons. |
| "A verification you skipped is not a verification you passed" | Keep this sentence verbatim in the report contract. |
| Dated measurements inline | The −4.8 % note is the most valuable line in the file. |
| Closed marker set | Markers only work as eye-catch if they are stable across documents. |

| ⛔ Blocks generalisation | Fix |
| --- | --- |
| One target shape (scannable working doc) | Classify the reader's task first; select a ruleset (§F1–F2) |
| Word-count reduction as the metric — and the file itself proves it is a bad one | Demote to informational; primary metric becomes retrieval (§F7) |
| Repo policy fused into method (worktree, English-only, depersonalise, command markers) | Move to config (§F11). ⚠️ Depersonalise is actively wrong on a credits or an ADR page. |
| Verification steps written as prose an agent may skip | Each becomes a script with an exit code (§T4) |
| Deterministic detections written as prompt instructions (prose-list tells) | Migrate down into lucid-lint (§T1) |
| Markdown-only, implicitly GitHub-rendered | Format layer + render-target capability matrix (§F9, §T3) |

---

## 3. Functional requirements

### F1 — Classify before transforming

Two **orthogonal** axes. The skill states the inferred pair and the evidence for it,
and asks when confidence is low.

| Axis | Values | Maps to |
| --- | --- | --- |
| Audience | `dev-doc` · `public` · `falc` | lucid-lint `--profile` (already exists) |
| Reader task | `locate` · `execute` · `decide` · `learn` · `comply` | 📌 new — no equivalent today |

⚠️ These are independent. A FALC procedure and a FALC reference page need opposite
structures. The prototype has neither axis and assumes `dev-doc` × `locate`.

### F2 — One ruleset per reader task

`references/tasks/<task>.md`, loaded on demand. Each declares: target shape ·
allowed transforms · **forbidden** transforms · acceptance questions.

| Task | Target shape | Signature rule |
| --- | --- | --- |
| `locate` | access structure first — informative headings, contents, tables, stable order | Scent in the **first three words** of every heading and link |
| `execute` | one action per step, imperative, preconditions block | ⚠️ Condition **before** action, always. Rationale leaves the step. |
| `decide` | option table or decision tree, criteria as columns | Recommendation carries ⭐; discarded options keep one line each |
| `learn` | worked example first, figure and its label contiguous | ⛔ Never state the same content in prose *and* diagram |
| `comply` | structured by obligation, not by narrative | 🔒 Normative wording (`MUST`, `SHALL`, legal citations) is untouchable |

### F3 — Access structure is a first-class object

The skill produces or repairs, as a unit: title · one-line purpose · audience ·
TL;DR · scan line or contents · informative headings · anchors.

Heading test: **a heading must answer a reader's question, not name a topic.**
*"What the prototype teaches"* passes; *"Analysis"* fails.

### F4 — Fact-preservation contract

1. **Before** any edit, extract an inventory to `facts.json`: `id`, `kind`, verbatim
   span, source line.
   Kinds: `measurement` · `warning` · `command` · `caveat` · `normative` · `number` ·
   `date` · `link` · `identifier`.
2. **After**, verify each survives — grep a fragment that lives on **one line**, with
   a positive control.
3. 🛑 Gate at 100 %. A missing fact fails the pass; it is not reported as a trade-off.
4. **No new claims.** Every assertion in the output traces to a source span.
   Unmatched output sentences are listed in the report.

### F5 — Diff-based, reviewable, reversible

Branch or worktree, one commit, merge stat read and reported. Many deletions on
`condense` is expected; deletions on `access-only` is an alarm.

### F6 — Idempotence

A second run over the output produces no semantic change. Whitespace-only diffs are
tolerated. Tested in CI over the fixture corpus.

### F7 — Reader-task verification — the primary metric

The computable analogue of a read-and-locate test:

1. Derive 5–8 retrieval questions from the document's stated purpose, or take them
   from the user.
2. A **cold subagent** — fresh context, no knowledge of the edit — answers from the
   document alone and reports which sections it had to open.
3. Score: **answers correct** (comprehension) and **blocks opened**.
4. Same questions, before and after.

⛔ **Retracted 2026-08-31.** Blocks opened is not a locate-cost measure: the
cold Reader loads the document whole rather than navigating it, so the number
is the same whatever the form. Measured over three arms of one topology; see
`skills/shape/references/calibration.md`. What replaces it is not yet built.

⚠️ Honesty caveats, to be printed with the result:

- This is a proxy for a human reader, not a human test.
- 🛑 The agent that transformed the document must not be the agent that grades it.
- Question derivation by the same model biases toward what that model finds salient;
  user-supplied questions are stronger evidence and should be preferred when offered.

### F8 — Report contract

Per-category lucid-lint delta · retrieval result before/after · fact-survival list ·
what was removed by category · **what could not be measured, and why** · word count,
labelled *informational*.

### F9 — Render-target awareness

`--target`: `github` · `confluence` · `mdbook` · `pdf` · `terminal` · `plain`.
A capability matrix (mermaid · tables · emoji · footnotes · collapsible · anchors)
decides which constructs are allowed. Fallbacks are declared in the matrix, never
improvised at edit time — this is the prototype's Confluence/mermaid lesson,
generalised.

### F10 — Modes

`diagnose` (read-only) · `access-only` · `restructure` · `condense`.
⭐ `diagnose` is the **default** on first contact with an unknown document. The
prototype's failure mode is starting from `condense`.

### F11 — Policy is configuration

`.shape.toml` at repo root: marker set · protected-name list · keep-patterns ·
house style · forbidden transforms · default target · default task.
The skill body carries **method**; the repo carries **policy**.

---

## 4. Technical requirements

### T1 — Deterministic / judgement split

**Rule: anything mechanically decidable is a linter rule, not a prompt instruction.**

| Migrate into lucid-lint | Stays a judgement call for the skill |
| --- | --- |
| Prose-list tells: `(1)…(2)…`, 3+ parallel clauses, inverse-verdict tail | Is this passage transient or load-bearing? |
| Heading is non-informative / topic-named | Which shape fits this reader's task? |
| Section longer than N blocks without a subheading | Is this repetition redundancy or reinforcement? |
| Prose restating an adjacent table | Does this diagram earn its space? |

This is also what keeps SKILL.md small enough to be read reliably.

### T2 — Format independence

- `pandoc -t json` as the **analysis** AST for non-Markdown sources.
- ⚠️ Do **not** round-trip through pandoc to rewrite: it normalises and loses source
  fidelity. Analyse via AST, edit the native source.
- Exception: formats with no meaningful text source (`.docx`) — round-trip accepted
  and declared lossy in the report.
- v1 scope recommendation: `.md` and `.txt` native; everything else `diagnose`-only.

### T3 — Chunking

Outline pass first (headings + block map), then section-level edits. 🛑 No whole-file
rewrite above ~1 500 words — the whole-file rewrite is the mechanism by which facts
disappear.

### T4 — Packaging

- `SKILL.md` ≤ ~150 lines: trigger · classification procedure · pointers.
- `references/` — task rulesets, capability matrix, marker legend.
- `scripts/` — one script per verification, each with a clean exit-code contract.
  ⚠️ Read every exit status in its own statement; in a pipe you read `tail`'s status.
- `assets/facts-schema.json`.

### T5 — Graceful degradation

Missing `lucid-lint`, `pandoc`, `mmdc`, `lychee` → the check reports **not run**.
Never silently skipped, never fatal to the pass.

### T6 — Fixture corpus and regression

5–10 real documents spanning the five tasks, with expected properties. CI runs
`diagnose` plus the idempotence test on every change to the rulesets.

---

## 5. lucid-lint contract

What `shape` needs from lucid-lint, in dependency order.

| # | Need | Status | Note |
| --- | --- | --- | --- |
| 1 | `--format=json`, schema pinned and versioned | ✅ exists | Version the schema so the skill can fail loudly on drift |
| 2 | 📌 **`access` category** — 6th scoring category | ⛔ absent | Heading informativeness · scent in first 3 words · contents present · section length · prose-list · prose-restating-table |
| 3 | Exit-code contract: no findings / findings / tool error distinguished | to verify | The skill cannot treat *tool crashed* as *document clean* |
| 4 | Baseline diff mode — score delta between two files | 📌 | Feeds F8 directly |
| 5 | Task axis, or per-run rule subsets | 📌 | Profiles are audience; the task axis (F1) has no home yet |
| 6 | `explain <rule-id>` as machine-readable | ✅ exists as TTY | Lets the skill quote the rationale into its report |
| 7 | stdin | ✅ exists | Makes the pandoc path work today |

⭐ Recommendation: item 2 goes **into lucid-lint**, not into a separate analyser. It
is the same product thesis — cognitive load, deterministic rules — and it inherits CI
integration, `explain`, scoring and the FR/EN parity for free. It also makes
lucid-lint measure something no competitor in its comparison table measures.

---

## 6. Acceptance gates

| Gate | Threshold | Instrument |
| --- | --- | --- |
| Fact survival | 🛑 100 % | `scripts/verify-facts.sh` |
| Retrieval accuracy | ≥ baseline | cold subagent (F7) |
| Locate cost (blocks opened) | ⛔ withdrawn 2026-08-31, see F7 | — |
| Idempotence | no semantic diff | second run |
| lucid-lint `access` score | ≥ baseline | `--format=json` delta |
| Markdown / links / mermaid | pass or *not run* | existing scripts |
| Word count | ⚠️ informational only | `git show HEAD:<file> \| wc -w` |

---

## 7. Non-goals

⛔ Style or voice rewriting · translation · content creation · making a document
*look nicer* · replacing human review · **optimising the lucid-lint score as a
target** (the score is evidence; a pass that raises the score while lowering
retrieval accuracy has failed).

---

## 8. Risks

| Risk | Mitigation |
| --- | --- |
| Goodhart on the lint score | Score is a gate floor, never an objective; retrieval is the objective |
| Silent fact loss | F4 inventory + 100 % gate + chunked edits (T3) |
| Agent grades its own work | Cold subagent, ideally a different model (F7) |
| Genre misclassified → wrong transform applied confidently | F1 states the inference and its evidence; `diagnose` default (F10) |
| Markers drift into decoration | Closed set in config; a lint rule counting marker density |
| Restructuring feels large, measures small | Already documented at −4.8 %; the report must not credit effort |

---

## 9. Open decisions

| # | Decision | Recommendation |
| --- | --- | --- |
| 1 | `access` rules — inside lucid-lint or a separate analyser? | ⭐ Inside, as a 6th category |
| 2 | Shared norm layer with `glance` — extract, or accept duplication? | ⭐ Extract; `build.sh` gains a third surface |
| 3 | v1 format scope | ⭐ `.md` + `.txt` native, others `diagnose`-only |
| 4 | Depersonalise / worktree / English-only | ⭐ Config, never default |
| 5 | Language of the skill body | EN, matching lucid-lint and glance |

✅ **Settled** — name. `shape`, bare, no `doc-` prefix. One free autocomplete
initial (`s`), monosyllabic verb-and-noun like `wrap` and `glance`, and broad
enough to cover `diagnose` as well as `condense` — which `carve` or `hone`,
naming only the cutting, would not.

---

## 10. Evidence base

*Expert judgement on the mapping, not a measurement. References unverified in this
session — check dates and attributions before citing them.*

| Requirement | Rests on |
| --- | --- |
| Scent in the first three words (F2 `locate`) | Information foraging — Pirolli & Card |
| Access structure as an object (F3) | Waller, on access structure; Twyman's configuration matrix for shape selection |
| Condition before action, one action per step (F2 `execute`) | Carroll's minimalism; ASD-STE100 |
| Worked example first, no prose/diagram redundancy (F2 `learn`) | Mayer's multimedia principles; Sweller on cognitive load |
| Retrieval test as the primary metric (F7) | Schriver's reader-focused evaluation methods |
| Word count demoted (F8) | The prototype's own 2026-08-25 measurement |
| Signalling and marker discipline | Lemarié, Lorch, Eyrolle & Virbel; Hartley |
