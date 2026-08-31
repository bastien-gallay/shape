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
| `document_sha256` + `frozen_at` | ⚠️ makes "fixtures are frozen" mechanical — `just check-fixtures` exits 4 on a mismatch instead of trusting discipline |

## Rules

- ⛔ No client identifiers, ticket refs, production hostnames, or real
  people's telemetry. A skill that travels to other people's repos must not
  carry someone's identifiers in its own corpus.
- A fixture is committed with its expected `diagnose` output, so a ruleset
  change shows up as a diff rather than as a judgement call.
- ⚠️ **An A/B pair is scored as a pair.** `T2-topology-01a` / `-01b` are the
  same content in two forms. Reporting one arm without the other reintroduces
  the form-blindness the pair exists to measure.

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

📌 **First result, 2026-08-28.** Both arms scored 24/24 on retrieval at k = 3,
with identical blocks opened and identical verdicts from all six access checks.
Only two census numbers moved. See `references/calibration.md`.
