#!/usr/bin/env bash
# extract-facts.sh — seed a fact inventory from a document.
#
# Usage: extract-facts.sh <file> > facts.json
#
# Deterministic classes only (number, date, command, link, normative). The
# judgement classes — measurement, warning, caveat, identifier — are added by
# the skill after reading the document; this script gives it a floor, not a
# complete inventory.
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

# One candidate per line: LINE<TAB>KIND<TAB>SPAN
candidates="$(
  awk '
    { line = $0 }
    line ~ /`[^`]+`/                              { print NR "\tcommand\t"  line; next }
    line ~ /\b(MUST|MUST NOT|SHALL|SHOULD|MAY)\b/ { print NR "\tnormative\t" line; next }
    line ~ /[0-9]{4}-[0-9]{2}-[0-9]{2}/           { print NR "\tdate\t"     line; next }
    line ~ /https?:\/\//                          { print NR "\tlink\t"     line; next }
    line ~ /[-+]?[0-9]+([.,][0-9]+)?[ ]?%/        { print NR "\tnumber\t"   line; next }
  ' "$file"
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
  while IFS=$'\t' read -r lineno kind span; do
    n=$((n + 1))
    [[ $n -gt 1 ]] && printf ',\n'
    printf '    {"id": "F-%03d", "kind": "%s", "line": %s, "span": %s}' \
      "$n" "$kind" "$lineno" "$(printf '%s' "$span" | jq -Rs 'rtrimstr("\n")')"
  done <<< "$candidates"
  printf '\n  ]\n}\n'
}
