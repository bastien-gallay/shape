# Anti-patterns

Each is a symptom, and each names the directive it means was skipped. Read this
when a pass feels finished.

| Symptom | What it means |
| --- | --- |
| Reaching for `condense` on first contact | §0.1 skipped |
| "Restructured for clarity", no numbers | §6 skipped |
| A gate reported as passed with no script run | §0.5 — say *not run* |
| Deletions in `access-only` | wrong mode, or scope creep |
| Headings that name topics (`Analysis`, `Details`) | a heading must answer a reader's question |
| The editing agent scoring its own retrieval | §0.7 |
| An F12 number reported without `unvalidated` | §4b — it is a hypothesis |
| A ledger entry with an empty `not_measured` | §3.10 — empty by omission is a lie |
| Facts "lost" on an HTML page because the pandoc copy has no table | §7 v1 format scope — a `<br>` (any block content) inside a cell makes pandoc emit the table as raw HTML, which `-raw_html` strips; the gate then reads a conversion artefact, not a loss (2026-09-18: 35/39, then 39/39 once the `<br>` became an inline separator). Diagnose the copy before the document |

## The one that keeps coming back

🛑 **A gate that reports a pass it never ran.** It has appeared in this repo's
own scripts three times: a producer whose failure the shell does not see, a
loop that then reads zero rows, and a cheerful `✅`. The shape is always the
same — the check did not run, and nothing said so.

*A verification you skipped is not a verification you passed.*
