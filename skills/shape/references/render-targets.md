# Render targets — capability matrix

⚠️ Fallbacks are **declared here**, never improvised at edit time. This is the
prototype's Confluence/mermaid lesson, generalised: an editor that discovers at
write time that mermaid does not render will invent a workaround and get it
wrong.

| Target | mermaid | tables | emoji | footnotes | collapsible | anchors |
| --- | --- | --- | --- | --- | --- | --- |
| `github` | ✅ | ✅ | ✅ | ✅ `[^1]` | ✅ `<details>` | ✅ auto |
| `confluence` | ⛔ | ✅ | ✅ | ⛔ | ✅ macro | ✅ explicit |
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
