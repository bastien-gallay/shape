# Reader task — `decide`

The reader is choosing between options and needs the criteria side by side.

**Target shape** — an option table or a decision tree, with criteria as columns.

**Signature rule** — the recommendation carries ⭐; every discarded option keeps
at least one line saying why it was discarded.

## Allowed transforms

- Turn option prose into a table, one row per option, criteria as columns.
- Promote the recommendation to the top and mark it ⭐.
- Compress a discarded option to one line — but never to zero.
- Name the criteria explicitly when the source only implies them.

## Forbidden transforms

- ⛔ Deleting a rejected option. A future reader arrives holding that option and
  needs to recognise it as already considered.
- ⛔ Inventing a criterion the source does not evaluate.
- ⛔ Strengthening a hedged recommendation. `probably` stays `probably`.
- ⛔ Dropping the date or the author of a decision.

## Acceptance questions

1. Is there one row per option, including the rejected ones?
2. Are the criteria the same across every option?
3. Is the recommendation marked and attributed?
4. Does every hedge in the source survive at the same strength?
