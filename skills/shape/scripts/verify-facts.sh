#!/usr/bin/env bash
# verify-facts.sh — 🛑 the 100 % gate.
#
# Usage: verify-facts.sh <facts.json> <edited-file>
#
# Every fact's grep_fragment (or its span, when single-line) must still be
# findable in the edited file. A fact that did not survive FAILS the pass; it
# is not a trade-off.
#
# Two traps this script exists to avoid:
#   - zsh word-splitting a multi-line span into separate patterns
#   - reading a pipeline's exit status and getting `tail`'s
#
# Exit: 0 all survived · 1 at least one lost · 2 usage/unreadable
#       · 4 positive control failed (the check itself is not trustworthy)

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

lost=0
total=0
while IFS=$'\t' read -r id kind fragment_b64; do
  total=$((total + 1))
  # ⚠️ base64, not @tsv: @tsv escapes a literal backslash to `\\`, which turned
  # a `\|` inside a table cell into a pattern that matches nothing. Measured
  # 2026-08-27 — one false LOST on a document that had not been edited at all.
  fragment="$(printf '%s' "$fragment_b64" | base64 -d)"
  # -F fixed string, -- ends options, quoted so a multi-line or dash-leading
  # fragment stays one pattern.
  if grep -qF -- "$fragment" "$target"; then
    printf '✅ %s (%s)\n' "$id" "$kind"
  else
    printf '❌ %s (%s) LOST: %s\n' "$id" "$kind" "$fragment"
    lost=$((lost + 1))
  fi
done < <(jq -r '.facts[] | [.id, .kind, ((.grep_fragment // .span) | @base64)] | join("\t")' "$facts")

printf '\n%d/%d facts survived\n' "$((total - lost))" "$total"
if [[ $lost -gt 0 ]]; then
  echo "🛑 gate failed — $lost fact(s) lost" >&2
  exit 1
fi
