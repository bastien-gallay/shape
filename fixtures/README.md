# Fixture corpus

5–10 real documents spanning the five reader tasks, each with the properties a
`diagnose` run is expected to report. `just check-fixtures` runs the fact
inventory, the survival check and the render checks over every `fixtures/*.md`.

## What a fixture needs

| Field | Why |
| --- | --- |
| A reader task it exemplifies | the ruleset under test |
| Expected classification | catches classifier drift |
| Known access defects | what `diagnose` must find |
| Known protected spans | what must never disappear |

## Rules

- ⛔ No client identifiers, ticket refs, production hostnames, or real
  people's telemetry. A skill that travels to other people's repos must not
  carry someone's identifiers in its own corpus.
- A fixture is committed with its expected `diagnose` output, so a ruleset
  change shows up as a diff rather than as a judgement call.
- 📌 Empty for now. The corpus is the gap between this scaffold and a v1.
