#!/usr/bin/env bash
# check-idempotence.sh — a second pass over the output changes nothing semantic.
#
# Usage: check-idempotence.sh <first-pass-output> <second-pass-output>
#
# Whitespace-only diffs are tolerated; anything else is a failure. A skill that
# keeps finding work on its own output has no fixed point, and its report is a
# record of churn.
#
# Exit: 0 idempotent · 1 semantic diff · 2 usage

set -euo pipefail

a="${1:-}"
b="${2:-}"
if [[ -z "$a" || -z "$b" || ! -r "$a" || ! -r "$b" ]]; then
  echo "usage: check-idempotence.sh <first> <second>" >&2
  exit 2
fi

if diff -q "$a" "$b" >/dev/null 2>&1; then
  echo "✅ byte-identical"
  exit 0
fi

if diff --ignore-all-space --ignore-blank-lines -q "$a" "$b" >/dev/null 2>&1; then
  echo "✅ whitespace-only diff — tolerated"
  exit 0
fi

echo "❌ semantic diff on the second pass:"
diff --ignore-all-space --ignore-blank-lines -u "$a" "$b" || true
exit 1
