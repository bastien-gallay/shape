#!/usr/bin/env bash
# prose-restates-table.sh — a paragraph walking the edges of the table beside it.
#
# Usage: prose-restates-table.sh <blocks.json> <source-file> [--overlap 0.6]
#
# R2 of spec v1.1 §B4, and the generalisation of the prototype's *prose
# restating a table*. Measures entity overlap between a table's cells and the
# paragraph directly adjacent to it.
#
# ⚠️ The overlap threshold is a hypothesis. Mayer's redundancy principle says
# the pattern is harmful; it does not say where the line sits.
#
# Exit: 0 clean · 1 findings · 2 usage · 4 the check did not run

set -euo pipefail
# shellcheck source=../lib.sh
. "$(dirname "${BASH_SOURCE[0]}")/../lib.sh"

blocks="${1:-}"
src="${2:-}"
overlap="0.6"
if [[ "${3:-}" == "--overlap" && -n "${4:-}" ]]; then overlap="$4"; fi
if [[ -z "$blocks" || -z "$src" || ! -r "$blocks" || ! -r "$src" ]]; then
  echo "usage: prose-restates-table.sh <blocks.json> <source-file> [--overlap R]" >&2
  exit 2
fi
if ! jq -e '.blocks | length > 0' "$blocks" >/dev/null 2>&1; then
  echo "🛑 $blocks unreadable or empty — prose-restates-table did not run" >&2
  exit 4
fi

# Long tokens only: short words overlap between any two English sentences.
tokens() {
  sed -n "$1,$2p" "$src" \
    | tr '[:upper:]' '[:lower:]' \
    | tr -cs '[:alnum:]' '\n' \
    | awk 'length($0) >= 5' \
    | sort -u
}

rows="${TMPDIR:-/tmp}/shape-restate-$$.tsv"
trap 'rm -f "$rows" "${TMPDIR:-/tmp}/shape-tbl-$$" "${TMPDIR:-/tmp}/shape-pro-$$"' EXIT
jq_rows "$rows" prose-restates-table '
  .blocks as $b
  | [ $b[] | select(.type == "table") ][]
  | .i as $ti | .start as $ts | .end as $te
  | [ $b[] | select(.type == "paragraph" and (.i == $ti - 1 or .i == $ti + 1)) ][]?
  | [$ts, $te, .start, .end] | @tsv' "$blocks"
if rows_empty "$rows"; then
  echo "⚠️  no table with an adjacent paragraph — nothing to check"
  exit 0
fi

findings=0
while IFS=$'\t' read -r t_start t_end p_start p_end; do
  tbl="${TMPDIR:-/tmp}/shape-tbl-$$"; pro="${TMPDIR:-/tmp}/shape-pro-$$"
  tokens "$t_start" "$t_end" > "$tbl"
  tokens "$p_start" "$p_end" > "$pro"
  p_count="$(wc -l < "$pro" | tr -d ' ')"
  if [[ "$p_count" -ge 5 ]]; then
    shared="$(comm -12 "$tbl" "$pro" | wc -l | tr -d ' ')"
    ratio="$(awk -v s="$shared" -v p="$p_count" 'BEGIN { printf "%.2f", s / p }')"
    if awk -v r="$ratio" -v t="$overlap" 'BEGIN { exit !(r >= t) }'; then
      printf '❌ lines %s-%s — %s of its terms are in the adjacent table\n' \
        "$p_start" "$p_end" "$ratio"
      findings=$((findings + 1))
    fi
  fi
  rm -f "$tbl" "$pro"
done < "$rows"

if [[ $findings -gt 0 ]]; then
  printf '\n%d redundancy finding(s) — threshold %s is unvalidated\n' "$findings" "$overlap"
  exit 1
fi
echo "✅ no paragraph restates an adjacent table"
