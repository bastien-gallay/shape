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
| `table-misfit.sh` | a table carrying a chronology, a proportion or a series | ⭐ local, **observed** on 4 real passes 2026-08-28 |

Each reads `blocks.json` from `census.sh` for structure and the source only for
the text of the spans the census points at — ⛔ no re-parse (spec §4).

Exit contract, per T4: `0` clean · `1` findings · `2` usage · `4` the check did
not run.

🛑 Every census read goes through `jq_rows` or `jq_value` in `../lib.sh`, never
through a process substitution and never through a bare `x="$(jq …)"`. Both
run the producer in its own statement and turn a failed one into exit 4. This
is not style: the same defect — a crashed producer, a loop over zero rows, and
a cheerful ✅ — has been written four times in this repo.

⚠️ Zero rows is *not* an error here. A document with no headings, no tables or
no paragraphs is a real document; the census guard has already established that
the parse itself worked. But zero rows is never a ✅ either — the check says
"nothing to check" and exits 0.

⚠️ **`table-misfit.sh` is the only rule here derived from measurement rather
than from reasoning**, and it is also the only one that has already had a rule
removed from it. A fourth tell — two columns whose second carries sentences —
fired 7 times on this repo, every one a legitimate mapping. It was deleted the
hour it was written. ⭐ That is the promotion bar working in the direction it is
usually not tested in.

## Before promoting a rule

A rule leaves this directory only with: the corpus it was measured on, its size
and date, the false-positive rate observed, and two releases of stability.
Anything less is a rule designed in the abstract.
