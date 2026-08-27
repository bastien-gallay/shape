# `scripts/access/` — structural checks, owned here

⛔ `shape` does **not** wait for a lucid-lint `access` category (spec v1.1 §A2).

Every rule here is written and measured locally first. Rules are promoted
outward, never imported inward:

```text
local script → measured on corpus → stable across 2 releases → proposed as a lucid-lint rule
```

⭐ A deterministic rule is badly designed in the abstract. `shape` is the
proving ground; the lucid-lint `access` category becomes a roadmap item
justified by evidence rather than a blocking dependency.

## The rules

| Script | Checks | Promotion status |
| --- | --- | --- |
| `heading-scent.sh` | heading answers a question, scent in the first three words | 📌 local, unmeasured |
| `contents-present.sh` | a contents or scan line above the first substantive section | 📌 local, unmeasured |
| `section-length.sh` | no section runs long without a subheading | 📌 local, unmeasured |
| `prose-list.sh` | prose-list tells — `(1)…(2)…`, 3+ parallel clauses | 📌 local, unmeasured |
| `prose-restates-table.sh` | a paragraph restating the table beside it | 📌 local, unmeasured |

Each reads `blocks.json` from `census.sh` for structure and the source only for
the text of the spans the census points at — ⛔ no re-parse (spec §4).

Exit contract, per T4: `0` clean · `1` findings · `2` usage · `4` the check did
not run.

## Before promoting a rule

A rule leaves this directory only with: the corpus it was measured on, its size
and date, the false-positive rate observed, and two releases of stability.
Anything less is a rule designed in the abstract.
