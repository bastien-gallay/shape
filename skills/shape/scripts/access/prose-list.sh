#!/usr/bin/env bash
# prose-list.sh — a list wearing a paragraph's clothes.
#
# Usage: prose-list.sh <blocks.json> <source-file>
#
# Three tells, all mechanical:
#   - inline enumeration: `(1) … (2) …` or `1) … 2) …`
#   - three or more parallel clauses joined by the same connective
#   - a first/second/third/finally chain
#
# Reads the source only at the line spans the census points at — ⛔ no
# re-parse (spec §4).
#
# Exit: 0 clean · 1 findings · 2 usage · 4 the check did not run

set -euo pipefail
# shellcheck source=../lib.sh
. "$(dirname "${BASH_SOURCE[0]}")/../lib.sh"

blocks="${1:-}"
src="${2:-}"
if [[ -z "$blocks" || -z "$src" || ! -r "$blocks" || ! -r "$src" ]]; then
  echo "usage: prose-list.sh <blocks.json> <source-file>" >&2
  exit 2
fi
if ! jq -e '.blocks | length > 0' "$blocks" >/dev/null 2>&1; then
  echo "🛑 $blocks unreadable or empty — prose-list did not run" >&2
  exit 4
fi

rows="${TMPDIR:-/tmp}/shape-proselist-$$.tsv"
trap 'rm -f "$rows"' EXIT
jq_rows "$rows" prose-list \
  '.blocks[] | select(.type == "paragraph") | [.start, .end] | @tsv' "$blocks"
if rows_empty "$rows"; then
  echo "⚠️  no paragraphs in the census — nothing to check"
  exit 0
fi

findings=0
while IFS=$'\t' read -r start end; do
  text="$(sed -n "${start},${end}p" "$src" | tr '\n' ' ')"

  if printf '%s' "$text" | grep -qE '\([1-9]\)[^(]+\([2-9]\)'; then
    printf '❌ lines %s-%s — inline enumeration, should be a list\n' "$start" "$end"
    findings=$((findings + 1))
    continue
  fi
  if printf '%s' "$text" | grep -qiE '(first(ly)?,).*(second(ly)?,).*(third(ly)?,|finally,)'; then
    printf '❌ lines %s-%s — first/second/third chain, should be a list\n' "$start" "$end"
    findings=$((findings + 1))
    continue
  fi
  semis="$(printf '%s' "$text" | tr -cd ';' | wc -c | tr -d ' ')"
  if [[ "$semis" -ge 3 ]]; then
    printf '⚠️  lines %s-%s — %s parallel clauses, likely a list\n' "$start" "$end" "$semis"
    findings=$((findings + 1))
  fi
done < "$rows"

if [[ $findings -gt 0 ]]; then
  printf '\n%d prose-list finding(s) — each proposes, none converts\n' "$findings"
  exit 1
fi
echo "✅ no prose-list tells"
