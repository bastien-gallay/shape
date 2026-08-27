# Marker legend — closed set

Markers work as eye-catch only if they are **stable across documents**. The set
is closed: a marker outside this table is a defect, and a marker used as
decoration is a defect even when it is in the table.

| Marker | Word form | Means | Not for |
| --- | --- | --- | --- |
| ⭐ | `[recommended]` | the recommendation among options | anything merely good |
| ⚠️ | `[warning]` | acting on this wrongly costs something | mild caveats |
| ⛔ | `[forbidden]` | a transform or action that must not happen | discouraged |
| 🛑 | `[gate]` | a hard gate; failing it stops the pass | strong warnings |
| 🔒 | `[protected]` | verbatim-protected content | important content |
| 📌 | `[open]` | known gap, decision not yet made | to-do items |
| ✅ ❌ | `[pass]` `[fail]` | verification outcome | approval or opinion |

## Density

A marker is an eye-catch, and eye-catch is a budget. More than roughly one
marker per five lines of prose means the markers have stopped marking anything.
The repo's `.shape.toml` may narrow this set; it may not extend it.
