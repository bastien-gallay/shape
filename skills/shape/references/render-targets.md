# Render targets — capability matrix

⚠️ Fallbacks are **declared here**, never improvised at edit time. This is the
prototype's Confluence/mermaid lesson, generalised: an editor that discovers at
write time that mermaid does not render will invent a workaround and get it
wrong.

| Target | mermaid | tables | emoji | footnotes | collapsible | anchors |
| --- | --- | --- | --- | --- | --- | --- |
| `github` | ✅ | ✅ | ✅ | ✅ `[^1]` | ✅ `<details>` | ✅ auto |
| `confluence` | ⛔ | ✅ | ✅ | ⛔ | ✅ macro | ✅ explicit |
| `jira` | ⛔ | ✅ ⚠️ no leading `>` in a cell | ✅ | ⛔ | ✅ macro | ⛔ |
| `mdbook` | ✅ plugin | ✅ | ✅ | ✅ | ⛔ | ✅ auto |
| `pdf` | ✅ pre-render | ✅ | ⚠️ font-dependent | ✅ | ⛔ | ⛔ |
| `terminal` | ⛔ | ⚠️ width-bound | ⚠️ width-bound | ⛔ | ⛔ | ⛔ |
| `plain` | ⛔ | ⛔ | ⛔ | ⛔ | ⛔ | ⛔ |

## Declared fallbacks

| Construct | Unavailable → use |
| --- | --- |
| mermaid | a labelled table of the same relation, or a pre-rendered image with alt text. Never ASCII art. |
| footnote | an inline parenthetical, or a `Notes` section with explicit back-links |
| collapsible | a subheading — the content stays visible |
| auto anchor | an explicit anchor/id declared next to the heading |
| emoji marker | the marker's word form from `markers.md`, in brackets |
| table | a definition list; if `plain`, a labelled paragraph per row |
| comparison symbol in a `jira` cell | **words** — *above*, *one or more*, *at most* — never `>`, `<`, `>=` at the start of a cell |
| aligned text on `jira` | a `{code}` block — nothing else keeps columns |

## `jira` is not `confluence`

Added 2026-09-16 from issue #6. Jira was absent and `confluence` served as the
nearest proxy; it is wrong on a trap that already cost a real inversion. 🛑 A
`>` at the start of a Jira table cell is read as a blockquote marker and
**eaten**: on 2026-07-30 an acceptance criterion *fail = `>0` dead-lettered
messages* rendered as *fail = `0` …* — the inverse — on a shared board.
`check-render.sh --target jira` fails on such a cell. Two more, advisory:
headings beyond two levels render oversized, and the REST API confirms the
payload you sent, not what the renderer kept of it — ⚠️ re-read the stored
body after every write.

## Width

`terminal` and `plain` assume 80 columns. A table wider than that is a
definition list instead — decided here, not at edit time.

## Rendering mermaid locally

`check-render.sh` compiles every mermaid block rather than trusting that `mmdc`
answers `--version`. `mmdc` drives headless Chrome through puppeteer, so the
check needs a browser as well as the binary:

```sh
brew install mermaid-cli                       # or: npm i -g @mermaid-js/mermaid-cli
npx puppeteer browsers install chrome-headless-shell
```

The script finds that browser itself — the newest `chrome-headless-shell`, else
the newest `chrome`, under `${PUPPETEER_CACHE_DIR:-~/.cache/puppeteer}` — and
prints which one it used. ⚠️ It does **not** use the revision mermaid-cli pins:
that pin is what made every mermaid fixture report NOT RUN on a machine holding
two newer Chromes. Two overrides, in order of precedence:

| Variable | Use it when |
| --- | --- |
| `SHAPE_PUPPETEER_CONFIG` | a puppeteer config file this machine needs — proxy, extra flags |
| `PUPPETEER_EXECUTABLE_PATH` | a browser outside the puppeteer cache |

To *look at* the diagrams rather than only grade them, pass `--out-dir`; the
rendered SVGs are kept and their paths printed:

```sh
skills/shape/scripts/check-render.sh doc.md --target github --out-dir /tmp/svg
```

🛑 With no browser reachable the check still reports **NOT RUN** and exits 3. A
diagram that was never rendered is not a diagram that renders.
