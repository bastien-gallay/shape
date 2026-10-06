#!/usr/bin/env bash
# verify-facts.sh — 🛑 the 100 % gate.
#
# Usage: verify-facts.sh <facts.json> <edited-file>
#
# Every fact's grep_fragment (or its span, when single-line) must still be
# findable in the edited file. A fact that did not survive FAILS the pass; it
# is not a trade-off.
#
# Three traps this script exists to avoid, each paid for:
#   - jq's @tsv escapes a literal backslash, turning `\|` in a table cell into
#     a pattern matching nothing → fragments travel as base64.
#   - a pipeline's exit status is `tail`'s, and a process substitution's
#     failure is invisible to `set -e` → jq runs first, into a file, checked.
#   - `grep -F` on a multi-line pattern matches an OR of its lines, not the
#     block — and `-z` means "decompress" under ugrep, not "null-data". So a
#     multi-line fragment is REFUSED, per brief §F4: the fragment must live on
#     one line. Supply `grep_fragment` for a span that does not.
#
# 🛑 The denominator is DISTINCT fragments, not inventory entries. `grep -F`
# searches the whole document, so N entries carrying the same fragment are one
# verification reported N times: they pass or fail together and test one string.
# Counting entries inflated the gate's own denominator — measured 2026-09-01 on
# `T2-topology-02b`, 79 entries over 21 distinct fragments — and a `79/79`
# overstated what had been checked. Only the flattering number is removed; a
# fact that is lost still fails exactly as before.
#
# ⚠️ The count is also the coverage signal, because the gate cannot tell a
# well-protected document from one it cannot see into. `extract-facts.sh` keys
# on digits and code spans, so a document that spells its quantities out yields
# almost nothing and the gate reports a green 2/2 over it. Below
# SHAPE_MIN_FACTS the run says so. ⚠️ That threshold is uncalibrated and
# advisory: it changes what is printed, never the exit code.
#
# ⚠️ A lost measurement that is a RUN of numbers ("1 250 740 2 980 s", from
# labels packed under a stacked ASCII bar) gets one more chance (issue #14).
# extract-facts.sh reads the space thousands separator, so it cannot tell
# three values from one long number and glues them. When the values are later
# set apart, the glued fragment exists nowhere. The fallback cuts the run
# into thousands groups (a group of several tokens = 1 to 3 digits, then
# exactly 3 per token), gives each group the unit, and passes the fact as ⚠️
# SPLIT if every value of one cut is present. A split is a guess: two cuts
# can both match, and a value found elsewhere in the document counts. So the
# run says which cut it took and how many matched; a reviewer checks those
# lines. Only digits separated by single spaces qualify, and at most 12
# tokens (2^11 cuts); a comma or a dot in the run keeps the plain ❌.
#
# Exit: 0 all survived · 1 at least one lost · 2 usage/unreadable
#       · 4 the check itself is not trustworthy (control failed, unreadable
#         inventory, empty inventory, deduplication that lost every row, or a
#         multi-line fragment)

set -euo pipefail

facts="${1:-}"
target="${2:-}"
if [[ -z "$facts" || -z "$target" || ! -r "$facts" || ! -r "$target" ]]; then
  echo "usage: verify-facts.sh <facts.json> <edited-file>" >&2
  exit 2
fi

# Positive control: a string we KNOW is present must be found, and one we know
# is absent must not be. If either misbehaves, the grep path is broken and a
# clean run below would be meaningless.
control_present="$(head -c 40 "$target")"
if ! grep -qF -- "$control_present" "$target"; then
  echo "positive control failed: known-present string not found" >&2
  exit 4
fi
if grep -qF -- "__shape_control_absent_$$__" "$target"; then
  echo "negative control failed: known-absent string was found" >&2
  exit 4
fi

# ⚠️ jq runs in its own statement, into a file. In a process substitution its
# failure is invisible to `set -e`: the loop would read zero lines and the
# script would print "0/0 facts survived" and exit 0 — the gate reporting a
# pass on an inventory it could not read. Measured 2026-08-27.
rows="${TMPDIR:-/tmp}/shape-verify-$$.tsv"
trap 'rm -f "$rows"' EXIT
if ! jq -r '.facts[] | [.id, .kind, ((.grep_fragment // .span) | @base64)] | join("\t")' \
     "$facts" > "$rows"; then
  echo "🛑 cannot read $facts — the gate did not run" >&2
  exit 4
fi

# An empty inventory is not a clean document; it is an extraction that failed.
if [[ ! -s "$rows" ]]; then
  echo "🛑 $facts contains no facts — the gate did not run" >&2
  exit 4
fi
entries="$(wc -l < "$rows" | tr -d ' ')"

# ⚠️ Own statement, real file, status checked — the same rule as the jq above.
# A dedup that dies must never leave an empty loop reading as "0/0 survived".
uniq_rows="${TMPDIR:-/tmp}/shape-verify-uniq-$$.tsv"
trap 'rm -f "$rows" "$uniq_rows"' EXIT
if ! awk -F'\t' '!seen[$3]++' "$rows" > "$uniq_rows"; then
  echo "🛑 could not deduplicate the inventory — the gate did not run" >&2
  exit 4
fi
# Non-empty in, empty out is a broken dedup, not a document with nothing to
# protect. It is the same distinction the empty-inventory check draws above.
if [[ ! -s "$uniq_rows" ]]; then
  echo "🛑 deduplication dropped every row of a non-empty inventory — the gate did not run" >&2
  exit 4
fi

# The cuts of a glued run, one per line, values tab-separated, each carrying
# the unit; prints nothing when the fragment is not such a run. See the header.
split_candidates() {
  awk -v f="$1" '
    function rec(i, acc, k,    j, m, g, ok) {
      if (i > n) { if (k >= 2) print acc; return }
      for (j = i; j <= n; j++) {
        ok = (j == i) || (length(t[i]) <= 3)
        for (m = i + 1; ok && m <= j; m++) if (length(t[m]) != 3) ok = 0
        if (!ok) continue
        g = t[i]; for (m = i + 1; m <= j; m++) g = g " " t[m]
        g = ((k == 0) ? sign : "") g sep unit
        rec(j + 1, (acc == "" ? g : acc "\t" g), k + 1)
      }
    }
    BEGIN {
      if (!match(f, /^[-+~]?[0-9]+( [0-9]+)+ ?([A-Za-z]+|%)$/)) exit
      sign = ""; if (f ~ /^[-+~]/) { sign = substr(f, 1, 1); f = substr(f, 2) }
      match(f, /[A-Za-z%]+$/); unit = substr(f, RSTART); f = substr(f, 1, RSTART - 1)
      sep = ""; if (f ~ / $/) { sep = " "; f = substr(f, 1, length(f) - 1) }
      n = split(f, t, " ")
      if (n > 12) exit
      rec(1, "", 0)
    }'
}

lost=0
split_pass=0
total=0
while IFS=$'\t' read -r id kind fragment_b64; do
  total=$((total + 1))
  fragment="$(printf '%s' "$fragment_b64" | base64 -d)"

  # Refused rather than mis-verified: see the header.
  if [[ "$fragment" == *$'\n'* ]]; then
    printf '🛑 %s (%s) has a multi-line fragment — set grep_fragment to a single line\n' \
      "$id" "$kind" >&2
    exit 4
  fi

  # -F fixed string, -- ends options, quoted so a dash-leading fragment stays
  # one pattern.
  if grep -qF -- "$fragment" "$target"; then
    printf '✅ %s (%s)\n' "$id" "$kind"
  else
    first="" matched=0
    if [[ "$kind" == measurement ]]; then
      while IFS= read -r cut; do
        all=1
        IFS=$'\t' read -r -a values <<< "$cut"
        for v in "${values[@]}"; do
          grep -qF -- "$v" "$target" || { all=0; break; }
        done
        if [[ $all -eq 1 ]]; then
          matched=$((matched + 1))
          [[ -n "$first" ]] || first="$(printf '%s' "$cut" | sed $'s/\t/ · /g')"
        fi
      done < <(split_candidates "$fragment")
    fi
    if [[ $matched -gt 0 ]]; then
      printf '⚠️  %s (%s) SPLIT: %s → %s (%d cut(s) matched; check the values were moved, not dropped)\n' \
        "$id" "$kind" "$fragment" "$first" "$matched"
      split_pass=$((split_pass + 1))
    else
      printf '❌ %s (%s) LOST: %s\n' "$id" "$kind" "$fragment"
      lost=$((lost + 1))
    fi
  fi
done < "$uniq_rows"

printf '\n%d/%d distinct facts survived' "$((total - lost))" "$total"
if [[ "$entries" -ne "$total" ]]; then
  printf ' (%d inventory entries, %d repeats collapsed)' "$entries" "$((entries - total))"
fi
if [[ $split_pass -gt 0 ]]; then
  printf ', %d of them only as a split (⚠️ above)' "$split_pass"
fi
printf '\n'

min_facts="${SHAPE_MIN_FACTS:-5}"
if [[ $total -lt $min_facts ]]; then
  printf '⚠️  %d distinct fact(s) — the gate is protecting very little of this document.\n' "$total"
  printf '   extract-facts.sh keys on digits and code spans; a document that spells its\n'
  printf '   quantities out in words yields almost nothing, and 100 %% of nothing is green.\n'
  printf '   ⚠️  uncalibrated threshold (SHAPE_MIN_FACTS=%d), advisory — the exit code is unchanged.\n' "$min_facts"
fi

if [[ $lost -gt 0 ]]; then
  echo "🛑 gate failed — $lost fact(s) lost" >&2
  exit 1
fi
