#!/usr/bin/env bash
# check-render.sh — markdown, links and mermaid, per render target.
#
# Usage: check-render.sh <file> [--target github|confluence|mdbook|pdf|terminal|plain]
#
# ⚠️ Every absent tool reports NOT RUN. A verification you skipped is not a
# verification you passed.
#
# Exit: 0 all checks that ran passed · 1 a check failed · 2 usage

set -euo pipefail

file="${1:-}"
target="github"
[[ "${2:-}" == "--target" && -n "${3:-}" ]] && target="$3"
if [[ -z "$file" || ! -r "$file" ]]; then
  echo "usage: check-render.sh <file> [--target T]" >&2
  exit 2
fi

failed=0

run_or_skip() {
  local tool="$1"; shift
  if ! command -v "$tool" >/dev/null 2>&1; then
    printf '⚠️  %-12s NOT RUN (not installed)\n' "$tool"
    return
  fi
  if "$@" >/dev/null 2>&1; then
    printf '✅ %-12s pass\n' "$tool"
  else
    printf '❌ %-12s fail\n' "$tool"
    failed=1
  fi
}

run_or_skip markdownlint markdownlint "$file"
run_or_skip lychee       lychee --no-progress "$file"

if grep -q '```mermaid' "$file"; then
  case "$target" in
    confluence|terminal|plain)
      echo "❌ mermaid   present but unsupported on --target $target"
      echo "   fallback: see references/render-targets.md — a labelled table."
      failed=1
      ;;
    *)
      if ! command -v mmdc >/dev/null 2>&1; then
        printf '⚠️  %-12s NOT RUN (not installed)\n' "mmdc"
      else
        # ⚠️ `mmdc --version` proves the binary answers, not that the diagram
        # renders. Each block is extracted and actually compiled.
        block_dir="${TMPDIR:-/tmp}/shape-mermaid-$$"
        mkdir -p "$block_dir"
        awk -v dir="$block_dir" '
          /^```mermaid[[:space:]]*$/ { n++; inblock = 1; next }
          /^```[[:space:]]*$/        { inblock = 0; next }
          inblock                    { print > (dir "/block-" n ".mmd") }
        ' "$file"
        for block in "$block_dir"/block-*.mmd; do
          if mmdc -i "$block" -o "$block.svg" >/dev/null 2>&1; then
            printf '✅ %-12s %s renders\n' "mmdc" "$(basename "$block")"
          else
            printf '❌ %-12s %s does not render\n' "mmdc" "$(basename "$block")"
            failed=1
          fi
        done
        rm -rf "$block_dir"
      fi
      ;;
  esac
fi

exit "$failed"
