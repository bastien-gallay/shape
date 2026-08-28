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

## What is in it

| Fixture | Task | Form | Why it exists |
| --- | --- | --- | --- |
| `T2-topology-01a` | locate | table | the misfit no script can catch — a graph given as rows |
| `T2-topology-01b` | locate | mermaid graph | the comparator arm, identical content |

📌 **First result, 2026-08-28.** Both arms scored 24/24 on retrieval at k = 3,
with identical blocks opened and identical verdicts from all six access checks.
Only two census numbers moved. See `references/calibration.md`.
