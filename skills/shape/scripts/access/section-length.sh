#!/usr/bin/env bash
# section-length.sh — a section running long without a subheading.
#
# Usage: section-length.sh <blocks.json> [--max-blocks N]
#
# ⚠️ N is a hypothesis, not a setting. It belongs in `.shape.toml`, dated and
# beside the corpus size it came from; the default here exists only so the
# script runs before calibration.
#
# Exit: 0 clean · 1 findings · 2 usage · 4 the check did not run

set -euo pipefail
# shellcheck source=../lib.sh
. "$(dirname "${BASH_SOURCE[0]}")/../lib.sh"

blocks="${1:-}"
max=8
if [[ "${2:-}" == "--max-blocks" && -n "${3:-}" ]]; then max="$3"; fi
if [[ -z "$blocks" || ! -r "$blocks" ]]; then
  echo "usage: section-length.sh <blocks.json> [--max-blocks N]" >&2
  exit 2
fi
if ! jq -e '.blocks | length > 0' "$blocks" >/dev/null 2>&1; then
  echo "🛑 $blocks unreadable or empty — section-length did not run" >&2
  exit 4
fi

jq_value findings section-length --argjson max "$max" '
  [.blocks[] | select(.type == "heading" and .level <= 2) | .i] as $heads
  | .blocks as $b
  | [ range(0; ($heads | length)) as $k
      | $heads[$k] as $h
      | (if $k + 1 < ($heads | length) then $heads[$k + 1] else ($b | length) end) as $next
      | {head: $h,
         path: $b[$h].path,
         start: $b[$h].start,
         blocks: ([$b[] | select(.i > $h and .i < $next)] | length),
         subheads: ([$b[] | select(.i > $h and .i < $next and .type == "heading")] | length)}
      | select(.blocks > $max and .subheads == 0) ]
  | .[] | "line \(.start) — \(.blocks) blocks, no subheading: \(.path)"' "$blocks"

if [[ -n "$findings" ]]; then
  printf '%s\n' "$findings"
  printf '\n⚠️ threshold %s is unvalidated — see .shape.toml\n' "$max"
  exit 1
fi
echo "✅ no section runs long without a subheading"
