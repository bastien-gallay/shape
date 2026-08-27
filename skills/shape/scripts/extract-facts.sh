#!/usr/bin/env bash
# extract-facts.sh — seed a fact inventory from a document.
#
# Usage: extract-facts.sh <file> > facts.json
#
# Deterministic classes only. The judgement classes — which caveat is
# load-bearing, which sentence is a warning — are added by the skill after
# reading the document. This script gives it a floor, not a complete inventory.
#
# Two properties the floor must have, both learned the hard way:
#
#   - Every fact carries a `grep_fragment`: the distinctive token itself, not
#     the whole source line. A section edit that reflows a line has not lost
#     the fact, and a checker keyed to the line would fail the pass anyway.
#     ⚠️ Except `normative`, deliberately: comply.md forbids rewording a
#     normative sentence at all, so a reflowed one HAS been modified and the
#     strict whole-line check is the correct behaviour there.
#   - A line can produce more than one fact. An earlier version classified each
#     line by the first rule that fired, so a date inside a line that also held
#     a link was never inventoried.
#
# Exit: 0 seeded · 2 usage/unreadable · 3 no candidate found (suspicious)

set -euo pipefail

file="${1:-}"
if [[ -z "$file" || ! -r "$file" ]]; then
  echo "usage: extract-facts.sh <readable-file>" >&2
  exit 2
fi

sha="$(git hash-object "$file" 2>/dev/null || echo "")"
now="$(date -u +%Y-%m-%dT%H:%M:%SZ)"

# One candidate per line: LINE<TAB>KIND<TAB>SPAN<TAB>FRAGMENT
candidates="$(
  awk '
    function emit(kind, re,   s) {
      if (match($0, re)) {
        s = substr($0, RSTART, RLENGTH)
        printf "%d\t%s\t%s\t%s\n", NR, kind, $0, s
      }
    }
    {
      emit("command",    "`[^`]+`")
      emit("normative",  "^.*$")             # whole line, on purpose — see header
      emit("date",       "[0-9]{4}-[0-9]{2}-[0-9]{2}")
      emit("link",       "https?://[^ )>]+")
      emit("identifier", "v?[0-9]+\\.[0-9]+\\.[0-9]+")
      emit("identifier", "[A-Z]{2,}-[0-9]+")
      emit("measurement","[-+~]?[0-9][0-9 ,.]*[ ]?%")
      emit("measurement","[-+~]?[0-9][0-9 ,.]*[ ]?(ms|s|m|h|KB|MB|GB|TB|px|k)([^A-Za-z0-9]|$)")
      emit("measurement","[-+~]?[0-9][0-9 ,.]*[ ]?(second|minute|hour|day|week|month|year|word|line|file|commit|run|token)s?([^A-Za-z]|$)")
    }
    # `normative` is emitted only when the line actually carries normative
    # wording; the emit() above would otherwise fire on every line.
    ' "$file" | awk -F'\t' '
      $2 == "normative" && $3 !~ /(^|[^A-Za-z])(MUST|SHALL|SHOULD|MAY)([^A-Za-z]|$)/ { next }
      { print }
    '
)"

if [[ -z "$candidates" ]]; then
  echo "no deterministic fact candidate in $file — verify by hand before editing" >&2
  exit 3
fi

{
  printf '{\n  "version": 1,\n'
  printf '  "source": %s,\n' "$(printf '%s' "$file" | jq -Rs .)"
  printf '  "source_sha": %s,\n' "$(printf '%s' "$sha" | jq -Rs .)"
  printf '  "extracted_at": "%s",\n' "$now"
  printf '  "facts": [\n'
  n=0
  while IFS=$'\t' read -r lineno kind span fragment; do
    n=$((n + 1))
    if [[ $n -gt 1 ]]; then printf ',\n'; fi
    printf '    {"id": "F-%03d", "kind": "%s", "line": %s, "span": %s, "grep_fragment": %s}' \
      "$n" "$kind" "$lineno" \
      "$(printf '%s' "$span"     | jq -Rs 'rtrimstr("\n")')" \
      "$(printf '%s' "$fragment" | jq -Rs 'rtrimstr("\n")')"
  done <<< "$candidates"
  printf '\n  ]\n}\n'
}
