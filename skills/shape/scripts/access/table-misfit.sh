#!/usr/bin/env bash
# table-misfit.sh — a table carrying something a table cannot carry.
#
# Usage: table-misfit.sh <blocks.json> <source-file>
#
# A table answers one question: for these n items, what are these m attributes?
# ⭐ Tables carry a comparison; they cannot carry a topology, a proportion or
# two orders of magnitude. Everything below is a table doing one of the latter.
#
# 🛑 Every rule here was observed, none was reasoned out. Measured 2026-08-28
# over four real `shape` passes: a dossier of 7 documents scored 35/35 on the
# five existing access checks with 27 tables, 216 table rows and zero diagrams,
# and a later pass replaced four of those tables with mermaid figures. Three
# further tells that looked plausible in the abstract — a constant column, a
# multi-sentence cell, a one-row table — never occurred, and are deliberately
# NOT implemented. See references/calibration.md.
#
# The rules:
#   chronology  a column of dates over ≥ 3 rows — a sequence in a grid
#   series      every column but the first is numeric — a chart, or a
#               proportion when the units are percentages
#
# ⛔ A fourth rule — two columns whose second carries sentences, "a definition
# list wearing table clothes" — was implemented, measured, and REMOVED the same
# hour. It fired 7 times on this repo, on `Risk | Mitigation`,
# `Construct | Unavailable → use`, `Finding | …`. Every one was a legitimate
# mapping whose left column is a scannable index; demoting them to a definition
# list would destroy the `locate` affordance it exists to protect. The scan that
# suggested it had filed those cases as *borderline*, not misfit — and borderline
# is not evidence. See references/calibration.md.
#
# ⛔ Topology is NOT here. "This table is really a graph" is not mechanically
# decidable, and belongs to the model (see references/tasks/*.md).
#
# ⚠️ Deliberately conservative, like every rule in this directory: it proposes,
# the model decides. A table wrongly demoted costs more than one missed.
#
# Exit: 0 clean · 1 findings · 2 usage · 4 the check did not run

set -euo pipefail
# shellcheck source=../lib.sh
. "$(dirname "${BASH_SOURCE[0]}")/../lib.sh"

blocks="${1:-}"
src="${2:-}"
if [[ -z "$blocks" || -z "$src" || ! -r "$blocks" || ! -r "$src" ]]; then
  echo "usage: table-misfit.sh <blocks.json> <source-file>" >&2
  exit 2
fi
if ! jq -e '.blocks | length > 0' "$blocks" >/dev/null 2>&1; then
  echo "🛑 $blocks unreadable or empty — table-misfit did not run" >&2
  exit 4
fi

rows="${TMPDIR:-/tmp}/shape-tmisfit-$$.tsv"
trap 'rm -f "$rows"' EXIT
jq_rows "$rows" table-misfit \
  '.blocks[] | select(.type == "table") | [.start, .end] | @tsv' "$blocks"
if rows_empty "$rows"; then
  echo "⚠️  no tables in the census — nothing to check"
  exit 0
fi

findings=0
while IFS=$'\t' read -r start end; do
  verdict="$(sed -n "${start},${end}p" "$src" | awk '
    function trim(s) {
      gsub(/^[[:space:]]+|[[:space:]]+$/, "", s)
      gsub(/[*`_]/, "", s)
      return trim_again(s)
    }
    function trim_again(s) {
      gsub(/^[[:space:]]+|[[:space:]]+$/, "", s)
      return s
    }
    function is_sep(s) { return (s ~ /^:?-+:?$/) }
    function is_date(s) {
      return (s ~ /^[0-9][0-9][0-9][0-9]-[0-9][0-9]-[0-9][0-9]$/ ||
              s ~ /^[0-9][0-9][0-9][0-9]-[0-9][0-9]$/ ||
              s ~ /^[0-9]{1,2}\/[0-9]{1,2}\/[0-9]{2,4}$/)
    }
    # A number, optionally signed or approximated, optionally with a short unit
    # or a percent sign. `678 MB`, `88 %`, `402 s`, `1,234`, `~12`.
    function is_num(s) {
      return (s ~ /^[<>~≈+-]?[0-9][0-9.,]*[[:space:]]*(%|[A-Za-z]{1,4})?$/)
    }
    function is_pct(s) { return (s ~ /%$/) }
    # ⚠️ An escaped pipe inside a cell would split one cell into two and
    # invent a column. Refuse the table rather than measure a fiction.
    /\\\|/ { escaped = 1 }

    {
      line = $0
      sub(/^[[:space:]]*\|/, "", line)
      sub(/\|[[:space:]]*$/, "", line)
      n = split(line, C, "|")
      r++
      ncell[r] = n
      for (c = 1; c <= n; c++) cell[r, c] = trim(C[c])
      if (n > ncols) ncols = n
    }

    END {
      if (escaped) { print "skip"; exit }
      if (r < 3 || ncols < 2) { print "clean"; exit }
      # Row 2 must be the separator; data starts at row 3.
      for (c = 1; c <= ncell[2]; c++) if (!is_sep(cell[2, c])) { print "clean"; exit }
      data = r - 2
      if (data < 3) { print "clean"; exit }

      for (c = 1; c <= ncols; c++) {
        dates[c] = 0; nums[c] = 0; pcts[c] = 0
        for (i = 3; i <= r; i++) {
          v = cell[i, c]
          if (v == "") continue
          if (is_date(v)) dates[c]++
          if (is_num(v))  { nums[c]++; if (is_pct(v)) pcts[c]++ }
        }
      }

      # chronology — any column that is overwhelmingly dates
      for (c = 1; c <= ncols; c++)
        if (dates[c] >= 3 && dates[c] * 10 >= data * 8) {
          printf "chronology\t%s\t%d\n", cell[1, c], data; exit
        }

      # series — every column after the first is numeric
      allnum = 1
      for (c = 2; c <= ncols; c++) if (nums[c] * 10 < data * 8) allnum = 0
      if (allnum) {
        anypct = 0
        for (c = 2; c <= ncols; c++) if (pcts[c] * 10 >= data * 8) anypct = 1
        printf "%s\t%s\t%d\n", (anypct ? "proportion" : "series"), cell[1, 1], data
        exit
      }

      print "clean"
    }
  ')"

  kind="$(printf '%s' "$verdict" | cut -f1)"
  label="$(printf '%s' "$verdict" | cut -f2)"
  n="$(printf '%s' "$verdict" | cut -f3)"
  case "$kind" in
    chronology)
      printf '❌ lines %s-%s — %s rows of dates under "%s": a sequence in a grid, not a comparison. A timeline or an ordered list.\n' \
        "$start" "$end" "$n" "$label"
      findings=$((findings + 1)) ;;
    proportion)
      printf '❌ lines %s-%s — %s rows keyed by "%s", all values numeric and one column a percentage: a proportion. A table cannot show a share of a whole.\n' \
        "$start" "$end" "$n" "$label"
      findings=$((findings + 1)) ;;
    series)
      printf '❌ lines %s-%s — %s rows, every column but "%s" is numeric: a quantitative series. Two orders of magnitude do not read as digits.\n' \
        "$start" "$end" "$n" "$label"
      findings=$((findings + 1)) ;;
    skip)
      printf '⚠️  lines %s-%s — escaped pipe in a cell, not measured\n' "$start" "$end" ;;
  esac
done < "$rows"

if [[ $findings -gt 0 ]]; then
  printf '\n%d table finding(s) — each proposes, none converts\n' "$findings"
  printf '⛔ Topology is not checked here; that one is the reader of this report.\n'
  exit 1
fi
echo "✅ no table carries what a table cannot carry"
