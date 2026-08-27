#!/usr/bin/env bash
# census.sh — one parse, many metrics.
#
# Usage: census.sh <file> > blocks.json
#
# Emits the block sequence of a document per assets/blocks-schema.json. ⛔ No
# metric re-parses the source: every F12 metric is a pure function over this
# output (spec v1.1 §4).
#
# ⚠️ `chars` is counted in bytes. The one-true-awk shipped on macOS has no
# UTF-8 length, and a document with markers would report inflated widths. Every
# consumer must treat `chars` as a byte count, which is what the rendered-line
# estimate in metrics.sh assumes.
#
# ⚠️ `source` is stored as an absolute path. Consumers resolve line spans back
# against it (access/contents-present.sh does), and a cwd-relative path turns
# "run from another directory" into a silent finding.
#
# Exit: 0 census written · 2 usage/unreadable file
#       · 4 nothing parsed — an extraction that failed, not an empty document

set -euo pipefail

file="${1:-}"
if [[ -z "$file" || ! -r "$file" ]]; then
  echo "usage: census.sh <readable-file>" >&2
  exit 2
fi

# Absolute, so a consumer resolving spans is not bound to our cwd.
src_abs="$(cd "$(dirname "$file")" && pwd)/$(basename "$file")"

rows="${TMPDIR:-/tmp}/shape-census-$$.tsv"
trap 'rm -f "$rows"' EXIT

awk '
function flush(   n) {
  if (btype == "") return
  n = end - start + 1
  printf "%d\t%s\t%s\t%d\t%d\t%d\t%d\t%s\t%s\n", \
    idx++, btype, (blevel == "" ? "null" : blevel), start, end, n, bchars, path, markers
  lasttype = btype
  btype = ""; blevel = ""; bchars = 0; markers = ""
}
# 🛑 Accumulates into `markers`, and every line of the block is scanned. An
# earlier revision scanned only the opening line of a block, so a marker in the
# second sentence of a paragraph vanished — which is where most markers in the
# docs of this repo sit. V7 and the markers.md density budget are both computed
# from this field, so a truncated set silently understates both.
function add_markers(line,   i, g) {
  split("⭐ ⚠️ ⛔ 🛑 🔒 📌 ✅ ❌", G, " ")
  for (i = 1; i <= 8; i++) {
    g = G[i]
    if (index(line, g) > 0 && index(" " markers " ", " " g " ") == 0)
      markers = (markers == "" ? g : markers " " g)
  }
}
function open(t, lvl) {
  btype = t; blevel = lvl; start = NR; end = NR
  bchars = length($0); markers = ""; add_markers($0)
}
function extend() { end = NR; bchars += length($0); add_markers($0) }

BEGIN { idx = 0; btype = ""; path = ""; lasttype = ""; infm = 0; incode = 0 }

# --- frontmatter, only when it opens on line 1 -------------------------------
NR == 1 && /^---[[:space:]]*$/ { open("frontmatter", ""); infm = 1; next }
infm {
  extend()
  if (/^---[[:space:]]*$/) { infm = 0; flush() }
  next
}

# --- fenced code, which swallows every other rule ----------------------------
incode {
  extend()
  if ($0 ~ /^[[:space:]]*(```|~~~)/) {
    incode = 0
    # A mermaid fence is a figure, not code: B3 and V5 reason about figures.
    if (fence_lang ~ /mermaid/) btype = "figure"
    flush()
  }
  next
}
/^[[:space:]]*(```|~~~)/ {
  flush()
  fence_lang = $0
  sub(/^[[:space:]]*(```|~~~)/, "", fence_lang)
  open("code", ""); incode = 1; next
}

# --- blank line closes the current block -------------------------------------
/^[[:space:]]*$/ { flush(); next }

# --- headings maintain the ancestry path -------------------------------------
/^#{1,6}[[:space:]]/ {
  flush()
  lvl = index($0, " ")
  hashes = substr($0, 1, lvl - 1)
  lvl = length(hashes)
  text = substr($0, lvl + 2)
  # Truncate the ancestry to this depth, then append.
  for (d = lvl; d <= 6; d++) htitle[d] = ""
  htitle[lvl] = text
  path = ""
  for (d = 1; d <= 6; d++)
    if (htitle[d] != "") path = (path == "" ? htitle[d] : path " > " htitle[d])
  open("heading", lvl)
  flush()
  next
}

/^([-*_][[:space:]]*){3,}$/            { flush(); open("rule", "");       flush(); next }
/^>[[:space:]]*\[![A-Za-z]+\]/         { if (btype != "admonition") flush(); if (btype == "") open("admonition", ""); else extend(); next }
/^>/                                   { if (btype != "quote" && btype != "admonition") { flush(); open("quote", "") } else extend(); next }
/^[[:space:]]*\|/                      { if (btype != "table") { flush(); open("table", "") } else extend(); next }
/^[[:space:]]*([-*+]|[0-9]+[.)])[[:space:]]/ { if (btype != "list") { flush(); open("list", "") } else extend(); next }
/^[[:space:]]*!\[/                     { flush(); open("figure", ""); flush(); next }
/^[[:space:]]*</                       { if (btype != "html") { flush(); open("html", "") } else extend(); next }

# A caption is an emphasised line, or a Figure/Table label, directly under a
# figure or a table. Contiguity is the whole point (B4 R3, V5).
/^[[:space:]]*([*_].*[*_]|(Figure|Table|Fig\.)[[:space:]]*[0-9]*[.:]?)[[:space:]]*$/ {
  if (btype == "" && (lasttype == "figure" || lasttype == "table")) {
    open("caption", ""); flush(); next
  }
}

{ if (btype != "paragraph") { flush(); open("paragraph", "") } else extend() }

END { flush() }
' "$file" > "$rows"

# Zero rows is an extraction that failed, not a document with nothing in it.
if [[ ! -s "$rows" ]]; then
  echo "🛑 census parsed no blocks in $file — the census did not run" >&2
  exit 4
fi

jq -Rn --arg source "$src_abs" '
  [inputs | split("\t") | {
     i:       (.[0] | tonumber),
     type:    .[1],
     level:   (if .[2] == "null" then null else (.[2] | tonumber) end),
     start:   (.[3] | tonumber),
     end:     (.[4] | tonumber),
     lines:   (.[5] | tonumber),
     chars:   (.[6] | tonumber),
     path:    .[7],
     markers: (if .[8] == "" then [] else (.[8] | split(" ")) end)
   }] as $blocks
  | {version: 1, source: $source, blocks: $blocks}
' < "$rows"
