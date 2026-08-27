#!/usr/bin/env bash
# contents-present.sh — is there a way in above the first substantive section?
#
# Usage: contents-present.sh <blocks.json> [source-file]
#
# The `locate` reader needs a contents, a scan line, or a summary table before
# the first depth-2 section. Not a style preference: it is the access structure
# F3 makes a first-class object.
#
# Exit: 0 present · 1 absent · 2 usage · 4 the check did not run

set -euo pipefail
# shellcheck source=../lib.sh
. "$(dirname "${BASH_SOURCE[0]}")/../lib.sh"

blocks="${1:-}"
# The source is optional; without it only a table or list counts as a way in.
src_hint="${2:-$(jq -r '.source // ""' "${1:-/dev/null}" 2>/dev/null)}"
if [[ -z "$blocks" || ! -r "$blocks" ]]; then
  echo "usage: contents-present.sh <blocks.json> [source-file]" >&2
  exit 2
fi
if ! jq -e '.blocks | length > 0' "$blocks" >/dev/null 2>&1; then
  echo "🛑 $blocks unreadable or empty — contents-present did not run" >&2
  exit 4
fi

jq_value first_section contents-present \
  '[.blocks[] | select(.type == "heading" and .level == 2) | .i] | first // 9999' "$blocks"
jq_value lead_in contents-present --argjson fs "$first_section" \
  '[.blocks[] | select(.i < $fs and (.type == "table" or .type == "list"))] | length' "$blocks"

# ⚠️ A contents is not always a list. This brief writes its own as a prose line
# — "**Contents** — Position in the stack · What the prototype teaches · …" —
# and an earlier revision of this check flagged it. A way in is a way in.
#
# 🛑 And a source we cannot read is not a document without a contents. The
# census stores an absolute path precisely so this check survives being run
# from another directory; if the source is still unreadable, the prose branch
# cannot run and concluding ❌ from it would be a verdict reached by not
# looking.
prose_toc=0
if [[ "$lead_in" -eq 0 ]]; then
  if [[ -z "$src_hint" || ! -r "$src_hint" ]]; then
    echo "🛑 cannot read the source (${src_hint:-unset}) — contents-present did not run" >&2
    exit 4
  fi
  rows="${TMPDIR:-/tmp}/shape-contents-$$.tsv"
  trap 'rm -f "$rows"' EXIT
  jq_rows "$rows" contents-present --argjson fs "$first_section" \
    '.blocks[] | select(.i < $fs and .type == "paragraph") | [.start, .end] | @tsv' "$blocks"
  while IFS=$'\t' read -r start end; do
    if sed -n "${start},${end}p" "$src_hint" \
       | grep -qiE '(contents|on this page|in this (document|page)|tl;dr|sommaire)'; then
      prose_toc=1
      break
    fi
  done < "$rows"
fi

if [[ "$lead_in" -gt 0 || "$prose_toc" -eq 1 ]]; then
  echo "✅ a contents or scan structure precedes the first section"
  exit 0
fi
echo "❌ nothing between the title and the first section but prose — no way in"
exit 1
