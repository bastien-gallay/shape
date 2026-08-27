#!/usr/bin/env bash
# check-idempotence.sh — a second pass over the output changes nothing semantic.
#
# Usage: check-idempotence.sh <first-pass-output> <second-pass-output>
#
# Trailing-whitespace-only diffs are tolerated; anything else is a failure. A
# skill that keeps finding work on its own output has no fixed point, and its
# report is a record of churn.
#
# ⚠️ NOT `--ignore-all-space --ignore-blank-lines`. In Markdown, leading
# indentation is list nesting and a blank line is a paragraph boundary: those
# flags reported "whitespace-only" for a second pass that re-nested a list or
# merged two paragraphs. Only trailing whitespace is safe to ignore, and BSD
# diff has no flag for it — hence the sed.
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

# Real files, not process substitution: `/dev/fd` is unavailable under some
# sandboxes, and diff failing on it exits non-zero — which reads as "semantic
# diff" and fails a document that is fine.
tmp="${TMPDIR:-/tmp}/shape-idem-$$"
mkdir -p "$tmp"
trap 'rm -rf "$tmp"' EXIT
sed -e 's/[[:space:]]*$//' "$a" > "$tmp/a"
sed -e 's/[[:space:]]*$//' "$b" > "$tmp/b"

if diff -q "$tmp/a" "$tmp/b" >/dev/null 2>&1; then
  echo "✅ trailing-whitespace-only diff — tolerated"
  exit 0
fi

echo "❌ semantic diff on the second pass:"
diff -u "$tmp/a" "$tmp/b" || true
exit 1
