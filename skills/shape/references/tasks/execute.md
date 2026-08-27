# Reader task — `execute`

The reader is doing the thing while reading. Every sentence is read under load.

**Target shape** — one action per step, imperative mood, a preconditions block
before the first step.

**Signature rule** — ⚠️ **condition before action, always.** `If the build is
green, tag the release` — never `Tag the release if the build is green`. The
reader who acts on the first half of the sentence has already made the mistake.

## Allowed transforms

- Split a step containing two actions into two steps.
- Hoist scattered prerequisites into one preconditions block.
- Move rationale **out of the step** into a note after it.
- Convert narrative ("we then run…") to imperative ("run…").
- Add expected result to a step that has none.

## Forbidden transforms

- ⛔ Merging steps to shorten the procedure.
- ⛔ Removing an expected-result line, a warning, or a rollback instruction.
- ⛔ Paraphrasing a command. Commands are protected verbatim, including flags
  and quoting.
- ⛔ Reordering steps — order is semantics here, not presentation.

## Acceptance questions

1. Does every step contain exactly one action?
2. Does every conditional step state its condition before its action?
3. Are all prerequisites reachable before step 1?
4. Is every command byte-identical to the source?
