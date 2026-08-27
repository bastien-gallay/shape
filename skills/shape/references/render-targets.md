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
