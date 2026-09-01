# Fixture corpus

5–10 real documents spanning the five reader tasks, each with the properties a
`diagnose` run is expected to report. `just check-fixtures` runs the fact
inventory, the survival check and the render checks over every `fixtures/*.md`
except this README.

## A fixture is two files

🛑 **The answer key never shares a file with the document.** `census.sh` reads
frontmatter as a block and `verify-facts.sh` greps the whole target, so a key
carried in the document defeats both instruments at once: a cold Reader gets the
answers in its context, and a protected fragment quoted in the frontmatter
satisfies the 100 % gate even when the body deleted every occurrence. See
`docs/shape-validation-protocol.md` §3.

| File | Holds | Who reads it |
| --- | --- | --- |
| `<id>.md` | the document, and nothing else | the Reader, `census.sh`, `verify-facts.sh` |
| `<id>.key.yaml` | classification, expected behaviour, `must_preserve`, frozen questions, `document_sha256` | the harness only — ⛔ never a Reader context or an instrument input |

## What a key needs

| Field | Why |
| --- | --- |
| A reader task it exemplifies | the ruleset under test |
| Expected classification | catches classifier drift |
| Known access defects | what `diagnose` must find |
| `must_preserve` | what must never disappear |
| `document_sha256` + `frozen_at` | ⚠️ makes "fixtures are frozen" mechanical — `just check-fixtures` counts a mismatch as a failure and exits 1, instead of trusting discipline |

## Rules

- ⛔ No client identifiers, ticket refs, production hostnames, or real
  people's telemetry. A skill that travels to other people's repos must not
  carry someone's identifiers in its own corpus.
- A fixture is committed with its expected `diagnose` output, so a ruleset
  change shows up as a diff rather than as a judgement call.
- ⚠️ **A pair is scored as a pair, and a triple as a triple.**
  `T2-topology-01a` / `-01b`, and `T2-topology-02a` / `-02b` / `-02c`, are the
  same content in two and three forms. Reporting one arm without the others
  reintroduces the form-blindness they exist to measure.

## Two regimes, and only one of them lives here

Some documents worth measuring may not be described in this repository at all —
a client document, an internal page. They are still usable: the document stays
outside, and only the numbers come back.

| | In-repo corpus | External run |
| --- | --- | --- |
| Where the document lives | `fixtures/<id>.md`, committed | outside the worktree, never copied |
| How a run is recorded | `ledger.sh --fixture-id` | `ledger.sh --external <id>` |
| What the entry names | the real path | an opaque id |
| Reproducible by | anyone | ⛔ nobody, its author included |
| Good for | regressions, thresholds, A/B pairs | a conclusion about a class of document |

🛑 **The two are exclusive.** `--fixture-id` and `--external` together are a
usage error, because an entry claiming to be both is one that will later be read
as reproducible when it is not.

### What `--external` removes, and why it has to

The entry as built without it reconstructs the document. `census.blocks[].path`
carries the text of **every heading** verbatim, `census.source` carries an
absolute path, and `doc` carries the filename. `--external` replaces all three
with the id, then refuses to write if any path survives anywhere in the entry —
including in a `--not-measured` reason or a retrieval note. Its scrubber is
exercised by a positive and a negative control on every invocation.

The counts survive untouched: blocks, heading levels, tables, figures, the F12
metrics, fact-survival and retrieval. ⭐ That is deliberate — they are what lets
a later reader say which *kind* of document a conclusion came from, which is the
only thing standing between an unreproducible finding and a floating one.

The id ↔ path mapping is appended to `$SHAPE_EXTERNAL_MAP`, default
`~/.shape/external-map.tsv`. ⚠️ It lives outside the repository by construction,
and the script refuses a map path inside the worktree.

⚠️ **This protects the ledger, not the report.** A `diagnose` report quotes
headings. Never paste one into `references/calibration.md` or a commit message —
restate the finding in abstract terms.

### Deriving an in-repo fixture from a document you cannot ship

Regenerate, do not anonymise. A search-and-replace over names leaves the
sentence structure, the internal jargon and the business numbers in place: it is
re-identifiable by correlation, and the text is still someone else's.

Take only the skeleton — heading list, block types and their counts, edge or
step count, word count, the defect — and rewrite it in a neutral domain, then
author the key from the **new** document. What `shape` measures is structural
and survives the move: a graph given as rows, dependencies split across
sections, headings that name a topic instead of answering a question.

⛔ Two things do not survive it. A `comply` fixture draws its value from real
normative register, and a credits page from real names; invent a fictional
regime rather than degrade a real one. And a regenerated document that
faithfully reproduces a real architecture still publishes that architecture —
derive the counts, never the map.

## What is in it

| Fixture | Task | Form | Why it exists |
| --- | --- | --- | --- |
| `T2-topology-01a` | locate | table | the misfit no script can catch — a graph given as rows |
| `T2-topology-01b` | locate | mermaid graph | the comparator arm, identical content |
| `T2-topology-02a` | locate | scattered | 30 edges stated only inside 20 per-service entries |
| `T2-topology-02b` | locate | table | the same 30 edges consolidated into one table |
| `T2-topology-02c` | locate | mermaid graph | the same 30 edges as a graph — the comparator |

⚠️ **`02` is a triple, not a pair, and the third arm is the point.** `a → b`
varies consolidation, `b → c` varies form. The `01` pair confounded the two, so
its null result had two live explanations and could not tell them apart.

🛑 **A defect in `01`, found while writing `02`.** Its `Deploy order` section
restates the topology — "`object-store` and `token-cache` — no dependencies"
answers question 3 outright — and `On call` names dependency facts too. That is a
**third** explanation for the `01` null result, alongside "the loop cannot grade
form" and "the document was too small": both arms may simply have been answerable
from prose that neither form was needed for. ⚠️ It is not fixed in `01` — the
document is frozen and re-cutting it would discard the two ledger entries — but
it is not reproduced in `02`, where Deploy order states the rule and not the
sequence, On call names ownership and not dependencies, and no failure mode names
a path.

📌 **First result, 2026-08-28.** Both arms scored 24/24 on retrieval at k = 3,
with 2.67 and 3.00 blocks opened — no separation, and marginally the wrong way —
and identical verdicts from all six access checks. Only two census numbers
moved. See `references/calibration.md`.

📌 **Second result, 2026-08-31 — and it is about the instrument.** All three
arms of `02` scored 30/30, with 1.67 / 1.67 / 2.00 blocks opened and reader
tokens within 0.7 %. ⛔ All nine Readers loaded the **whole document** and not
one issued a `grep`, which makes *blocks opened* an **invalid** measure of
locate cost rather than an insensitive one. It discharges the two rival
explanations for the `01` result: the document was not too small, and `01`'s
prose restatement of its own topology was not the cause.

⭐ **Third result, 2026-09-01 — the first separation this corpus has ever
produced.** Same three arms, same ten questions, k = 3, but each Reader was
given **only the slice above the fold** (`scripts/first-window.sh`) instead of
the document: **a 3/30 · b 30/30 · c 29/30**. Nine Readers, one tool call each.
🛑 It separates `a → b` — consolidation — and **not** `b → c`: table and graph
are still indistinguishable, and c's single miss is one Reader adding a fifth
service to a four-service answer. ⚠️ Read the limit in
`references/calibration.md` before quoting the number: what is demonstrated is
that a topology below the fold cannot be retrieved, which is not yet the same
claim as *this form costs less to read*.
