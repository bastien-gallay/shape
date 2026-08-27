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
- 📌 Empty for now. The corpus is the gap between this scaffold and a v1.
