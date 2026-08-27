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
# Exit: 0 all survived · 1 at least one lost · 2 usage/unreadable
#       · 4 the check itself is not trustworthy (control failed, unreadable
#         inventory, empty inventory, or a multi-line fragment)

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

lost=0
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
    printf '❌ %s (%s) LOST: %s\n' "$id" "$kind" "$fragment"
    lost=$((lost + 1))
  fi
done < "$rows"

printf '\n%d/%d facts survived\n' "$((total - lost))" "$total"
if [[ $lost -gt 0 ]]; then
  echo "🛑 gate failed — $lost fact(s) lost" >&2
  exit 1
fi
