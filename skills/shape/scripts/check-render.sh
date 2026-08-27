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

# ⚠️ Link checking has a third outcome, and conflating it with the second is
# the whole doctrine failing quietly. A blocked or TLS-intercepted network
# makes every URL "fail" — that is the checker not reaching the network, not
# the document carrying dead links. Measured 2026-08-27: behind a filtering
# proxy, lychee reported both live URLs in README.md as errors.
if ! command -v lychee >/dev/null 2>&1; then
  printf '⚠️  %-12s NOT RUN (not installed)\n' "lychee"
else
  lychee_out="$(lychee --no-progress "$file" 2>&1)" || true

  # NOT RUN only when EVERY error is a transport failure. ⚠️ Matching the
  # transport pattern anywhere is not enough: lychee words a 404 as "Network
  # error: 404", so a loose pattern reports a genuinely dead link as a check
  # that did not run — the false negative this branch exists to prevent, made
  # worse. Measured 2026-08-27 against a stubbed lychee.
  err_total="$(printf '%s\n' "$lychee_out" | grep -cE '^[[:space:]]*\[ERROR\]' || true)"
  err_transport="$(printf '%s\n' "$lychee_out" \
    | grep -E '^[[:space:]]*\[ERROR\]' \
    | grep -ciE 'TLS certificate|connection refused|dns error|failed to lookup|operation timed out|proxy|invalid response data|malformed response' || true)"

  if [[ "$err_total" -gt 0 && "$err_total" -eq "$err_transport" ]]; then
    printf '⚠️  %-12s NOT RUN (network unreachable or intercepted)\n' "lychee"
  elif printf '%s' "$lychee_out" | grep -qE '[1-9][0-9]* Errors'; then
    printf '❌ %-12s fail\n' "lychee"
    printf '%s\n' "$lychee_out" | grep -E '^\[ERROR\]' | sed 's/^/   /'
    failed=1
  else
    printf '✅ %-12s pass\n' "lychee"
  fi
fi

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
