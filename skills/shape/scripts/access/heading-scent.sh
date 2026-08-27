#!/usr/bin/env bash
# heading-scent.sh — a heading must answer a reader's question, not name a topic.
#
# Usage: heading-scent.sh <blocks.json>
#
# Two tells, both mechanical:
#   - the heading is a bare topic noun from the closed stop-list
#   - its scent does not reach the first three words (information foraging)
#
# ⚠️ Deliberately conservative. This rule proposes; the model decides. A
# false positive that rewrites a good heading costs more than a miss.
#
# Exit: 0 clean · 1 findings · 2 usage · 4 the check did not run

set -euo pipefail

blocks="${1:-}"
if [[ -z "$blocks" || ! -r "$blocks" ]]; then
  echo "usage: heading-scent.sh <blocks.json>" >&2
  exit 2
fi
if ! jq -e '.blocks | length > 0' "$blocks" >/dev/null 2>&1; then
  echo "🛑 $blocks unreadable or empty — heading-scent did not run" >&2
  exit 4
fi

# Topic nouns that name a subject instead of answering a question.
STOPLIST="overview|introduction|background|details|analysis|discussion|notes|misc|miscellaneous|general|information|about|other|summary|conclusion|appendix|architecture|design|implementation|usage|configuration|reference"

findings=0
while IFS=$'\t' read -r line text; do
  lower="$(printf '%s' "$text" | tr '[:upper:]' '[:lower:]')"
  first3="$(printf '%s' "$lower" | awk '{print $1, $2, $3}')"

  if printf '%s' "$lower" | grep -qE "^($STOPLIST)s?$"; then
    printf '❌ line %s — topic-named heading: "%s"\n' "$line" "$text"
    findings=$((findings + 1))
  elif printf '%s' "$first3" | grep -qE "^(the|a|an|this|that|some|how|what|it) (is|are|was|were|of|to|and) "; then
    printf '⚠️  line %s — no scent in the first three words: "%s"\n' "$line" "$text"
    findings=$((findings + 1))
  fi
done < <(jq -r '.blocks[] | select(.type == "heading")
                | [(.start | tostring), (.path | split(" > ") | last)] | @tsv' "$blocks")

if [[ $findings -gt 0 ]]; then
  printf '\n%d heading finding(s) — each proposes, none converts\n' "$findings"
  exit 1
fi
echo "✅ headings carry scent"
