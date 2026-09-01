#!/usr/bin/env bash
# first-window.sh — the document as far as the fold, and nothing after it.
#
# Usage: first-window.sh <blocks.json> [--window N] [--wrap N]
#
# Emits the source text of the blocks that begin above the fold — what a reader
# has before scrolling. ⭐ This is the material for a **truncated-input**
# retrieval run: hand a cold subagent this slice and the task's acceptance
# questions, and it cannot ingest the whole document because it was never given
# the whole document.
#
# 🛑 Why that matters, and it is the reason this script exists. The cold-Reader
# retrieval loop cannot grade form: measured over twelve Readers on two
# unrelated document families, every one of them loaded the whole file in a
# single read and not one issued a `grep`. *Blocks opened* counts navigation
# from a subject that does not navigate. Truncating the input is the cheapest
# instrument that makes form cost something again — nothing has to be enforced,
# because nothing else was ever supplied. See ../references/calibration.md.
#
# ⚠️ It is not an access check and it grades nothing. It selects; the Reader
# answers; a human reads the separation. Adding a verdict here would make it the
# seventh check, which the saturation rule forbids until a corpus exists.
#
# The window is V3's, in rendered lines, so this slice and `V3_first_screen`
# always agree — the selection is made once, in metrics.sh, and read here.
#
# Exit: 0 slice emitted · 2 usage or unreadable input
#       · 3 metrics.sh did not run — the slice is undefined, never the whole file
#       · 4 the census produced no window

set -euo pipefail
# shellcheck source=lib.sh
. "$(dirname "${BASH_SOURCE[0]}")/lib.sh"

here="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

blocks="${1:-}"
shift || true
pass_through=()
while [[ $# -gt 0 ]]; do
  case "$1" in
    --window|--wrap)
      if [[ -z "${2:-}" ]]; then
        echo "usage: first-window.sh <blocks.json> [--window N] [--wrap N] — $1 needs a value" >&2
        exit 2
      fi
      pass_through+=("$1" "$2"); shift 2 ;;
    *)
      echo "usage: first-window.sh <blocks.json> [--window N] [--wrap N]" >&2
      exit 2 ;;
  esac
done

if [[ -z "$blocks" || ! -r "$blocks" ]]; then
  echo "usage: first-window.sh <blocks.json> [--window N] [--wrap N]" >&2
  exit 2
fi

jq_value source first-window '.source // empty' "$blocks"
if [[ -z "$source" || ! -r "$source" ]]; then
  echo "🛑 the census names a source this script cannot read: ${source:-<none>}" >&2
  exit 2
fi

# 🛑 metrics.sh runs in its own statement, into a real file, and its status is
# read before anything is taken from the output. A metrics run that died must
# never fall through to "the window is the whole document" — that is the
# fail-towards-a-pass direction this repo keeps paying for.
metrics="${TMPDIR:-/tmp}/shape-first-window-$$.json"
trap 'rm -f "$metrics"' EXIT
metrics_status=0
"$here/metrics.sh" "$blocks" "${pass_through[@]+"${pass_through[@]}"}" > "$metrics" \
  || metrics_status=$?
if [[ $metrics_status -eq 4 ]]; then
  echo "🛑 the census produced no metrics — the window is undefined" >&2
  exit 4
elif [[ $metrics_status -ne 0 ]]; then
  echo "🛑 metrics.sh exited $metrics_status — the window is undefined, NOT the whole file" >&2
  exit 3
fi

jq_value last_index first-window \
  '.metrics.V3_first_screen.blocks_in_window | last // empty' "$metrics"
if [[ -z "$last_index" ]]; then
  echo "🛑 no block sits above the fold — the census produced no window" >&2
  exit 4
fi

# The blocks above the fold are a prefix in document order, so the slice is
# lines 1..end of the last one. Blank lines between blocks are kept: they are
# what the reader sees, and dropping them would change the rendered length of
# the very thing being measured.
jq_value last_line first-window \
  --argjson i "$last_index" '.blocks[] | select(.i == $i) | .end' "$blocks"

sed -n "1,${last_line}p" "$source"
