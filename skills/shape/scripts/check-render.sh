#!/usr/bin/env bash
# check-render.sh — markdown, links and mermaid, per render target.
#
# Usage: check-render.sh <file> [--target github|confluence|mdbook|pdf|terminal|plain]
#
# ⚠️ Every absent tool reports NOT RUN. A verification you skipped is not a
# verification you passed.
#
# Exit: 0 all checks that ran passed · 1 a check failed · 2 usage
#       3 a check could not run — the tool is present but its runtime, its
#         browser, its network or its config is not

set -euo pipefail

file="${1:-}"
target="github"
[[ "${2:-}" == "--target" && -n "${3:-}" ]] && target="$3"
if [[ -z "$file" || ! -r "$file" ]]; then
  echo "usage: check-render.sh <file> [--target T]" >&2
  exit 2
fi

failed=0
render_not_run=0
md_not_run=0

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

# ⚠️ Markdown linting is cwd-sensitive and tool-sensitive, and BOTH failures
# report as ❌ fail rather than as NOT RUN — the exact inversion this script
# exists to prevent.
#
#   - markdownlint-cli v1 resolves .markdownlint.json from the CURRENT
#     DIRECTORY, not from the linted file's. Invoked as `markdownlint <file>`
#     from anywhere but the config's own directory it finds no config, applies
#     defaults, and MD013 alone reddens any document whose repo disabled it.
#     Measured 2026-08-28 on markdownlint-cli 0.46.0: 17 MD013 findings on a
#     document that lints clean under its own repo's config, from a cwd one
#     directory below the config. The verdict was a statement about the cwd.
#
#   - markdownlint-cli2 reads .markdownlint-cli2.jsonc and its own ignore
#     config, so it is preferred wherever present. Its trap is the inverse and
#     it is silent: "Linting: 0 files" exits 0. The FILE COUNT is read, never
#     the exit status alone.
#
# So: walk up from the FILE to find the config, run the linter from that
# directory, and PRINT THE CONFIG PATH. A lint whose config is implicit is not
# reproducible, and a lint with no config is a different proposition from a
# lint with one.
#
# 🛑 And a no-config FAILURE is NOT RUN, never ❌. Measured 2026-08-31: a
# document held in a scratchpad — which is how shape edits a copy — has no
# config above it, so MD013 and MD041 fired although the governing repo
# disables both. The verdict was a statement about where the file sat. Same
# class as mmdc without a browser and lychee without a network, and treated
# the same way. ⚠️ A no-config PASS stays ✅: stock rules are stricter than a
# config that disables some, so passing them passes the repo's too.
#
# Set SHAPE_MD_CONFIG to name the governing config when the document is being
# linted away from the repo that owns it.

md_config_file() {
  local dir
  if [[ -n "${SHAPE_MD_CONFIG:-}" ]]; then
    [[ -r "$SHAPE_MD_CONFIG" ]] || return 1
    printf '%s\n' "$SHAPE_MD_CONFIG"; return 0
  fi
  dir="$(cd "$(dirname "$1")" && pwd)"
  while :; do
    for name in .markdownlint-cli2.jsonc .markdownlint-cli2.yaml .markdownlint-cli2.cjs \
                .markdownlint.json .markdownlint.jsonc .markdownlint.yaml .markdownlintrc; do
      [[ -r "$dir/$name" ]] && { printf '%s\n' "$dir/$name"; return 0; }
    done
    [[ "$dir" == "/" ]] && return 1
    dir="$(dirname "$dir")"
  done
}

lint_markdown() {
  local f="$1" root rel out status label n cfg
  if cfg="$(md_config_file "$f")"; then
    root="$(cd "$(dirname "$cfg")" && pwd)"
    label="config $cfg"
  else
    root="$(cd "$(dirname "$f")" && pwd)"
    cfg=""
    label="no-config"
  fi
  rel="$(cd "$(dirname "$f")" && pwd)/$(basename "$f")"
  rel="${rel#"$root"/}"

  if command -v markdownlint-cli2 >/dev/null 2>&1; then
    status=0
    out="$(cd "$root" && markdownlint-cli2 "$rel" 2>&1)" || status=$?
    # 🛑 The count, not the status. `Linting: 0 files` exits 0 having linted
    # nothing — a gate reporting a clean document it never opened.
    n="$(printf '%s\n' "$out" | sed -nE 's/^Linting: ([0-9]+) files?.*/\1/p' | head -1)"
    if [[ -z "$n" ]]; then
      printf '⚠️  %-12s NOT RUN (no "Linting: N files" line, exited %s)\n' "cli2" "$status"
      printf '%s\n' "$out" | head -3 | sed 's/^/   /'
    elif [[ "$n" -eq 0 ]]; then
      printf '⚠️  %-12s NOT RUN (Linting: 0 files — ignored or unmatched)\n' "cli2"
    elif [[ "$status" -eq 0 ]]; then
      printf '✅ %-12s pass (%s file(s), %s)\n' "cli2" "$n" "$label"
    elif [[ -z "$cfg" ]]; then
      printf '⚠️  %-12s NOT RUN (findings under DEFAULT rules — no config above the file)\n' "cli2"
      printf '%s\n' "$out" | grep -E 'MD[0-9]+' | head -10 | sed 's/^/   /'
      printf '   ⚠️  advisory only. Set SHAPE_MD_CONFIG to the governing config.\n'
      md_not_run=1
    else
      printf '❌ %-12s fail (%s)\n' "cli2" "$label"
      printf '%s\n' "$out" | grep -E 'MD[0-9]+' | head -10 | sed 's/^/   /'
      failed=1
    fi
    return
  fi

  if command -v markdownlint >/dev/null 2>&1; then
    status=0
    out="$(cd "$root" && markdownlint "$rel" 2>&1)" || status=$?
    if [[ "$status" -eq 0 ]]; then
      printf '✅ %-12s pass (%s)\n' "markdownlint" "$label"
    elif [[ -z "$cfg" ]]; then
      printf '⚠️  %-12s NOT RUN (findings under DEFAULT rules — no config above the file)\n' \
        "markdownlint"
      printf '%s\n' "$out" | head -10 | sed 's/^/   /'
      printf '   ⚠️  advisory only. Set SHAPE_MD_CONFIG to the governing config.\n'
      md_not_run=1
    else
      printf '❌ %-12s fail (%s)\n' "markdownlint" "$label"
      printf '%s\n' "$out" | head -10 | sed 's/^/   /'
      failed=1
    fi
    return
  fi

  printf '⚠️  %-12s NOT RUN (neither markdownlint-cli2 nor markdownlint installed)\n' "markdown"
}

lint_markdown "$file"

# ⚠️ Link checking has a third outcome, and conflating it with the second is
# the whole doctrine failing quietly. A blocked or TLS-intercepted network
# makes every URL "fail" — that is the checker not reaching the network, not
# the document carrying dead links. Measured 2026-08-27: behind a filtering
# proxy, lychee reported both live URLs in README.md as errors.
if ! command -v lychee >/dev/null 2>&1; then
  printf '⚠️  %-12s NOT RUN (not installed)\n' "lychee"
else
  # 🛑 The status is read in its own statement. An earlier revision discarded
  # it with `|| true` and classified from stdout alone, so a lychee that died
  # on a bad config printed no errors and was read as ✅ pass — a crashed
  # checker reporting a clean document.
  lychee_status=0
  lychee_out="$(lychee --no-progress "$file" 2>&1)" || lychee_status=$?

  # No summary line means lychee never got as far as checking anything.
  if ! printf '%s\n' "$lychee_out" | grep -qE '[0-9]+ Total'; then
    printf '⚠️  %-12s NOT RUN (exited %s with no summary)\n' "lychee" "$lychee_status"
    printf '%s\n' "$lychee_out" | head -3 | sed 's/^/   /'
  else

    # NOT RUN only when EVERY error is a transport failure. ⚠️ Matching the
    # transport pattern anywhere is not enough, twice over: lychee words a 404 as
    # "Network error: 404", and the URL itself is on the [ERROR] line — so
    # https://example.com/proxy-guide returning 404 matched `proxy` and a dead
    # link was reported as a check that did not run. The URL is stripped before
    # the reason is matched. Measured 2026-08-27 against a stubbed lychee.
    err_lines="${TMPDIR:-/tmp}/shape-lychee-$$.txt"
    printf '%s\n' "$lychee_out" | grep -E '^[[:space:]]*\[ERROR\]' > "$err_lines" || true
    err_total="$(wc -l < "$err_lines" | tr -d ' ')"
    err_transport="$(sed -E 's#https?://[^[:space:]]+##g' "$err_lines" \
      | grep -ciE 'TLS certificate|connection refused|dns error|failed to lookup|operation timed out|proxy|invalid response data|malformed response' || true)"

    if [[ "$err_total" -gt 0 && "$err_total" -eq "$err_transport" ]]; then
      printf '⚠️  %-12s NOT RUN (network unreachable or intercepted)\n' "lychee"
    elif printf '%s' "$lychee_out" | grep -qE '[1-9][0-9]* Errors'; then
      printf '❌ %-12s fail\n' "lychee"
      sed 's/^/   /' "$err_lines"
      failed=1
    else
      printf '✅ %-12s pass\n' "lychee"
    fi
    rm -f "$err_lines"
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
        # 🛑 `mmdc` present is not `mmdc` able to run. It drives headless
        # Chrome through puppeteer, and a missing or mis-cached browser exits
        # non-zero with the diagram untouched — which read as "this diagram
        # does not render" on a diagram that is fine. Measured 2026-08-28 on
        # fixtures/T2-topology-01b.md, the first fixture in the corpus: a valid
        # 9-edge graph reported ❌ because Chrome was not installed. The
        # verdict was a statement about the machine.
        for block in "$block_dir"/block-*.mmd; do
          mmdc_status=0
          mmdc_out="$(mmdc -i "$block" -o "$block.svg" 2>&1)" || mmdc_status=$?
          if [[ $mmdc_status -eq 0 ]]; then
            printf '✅ %-12s %s renders\n' "mmdc" "$(basename "$block")"
          elif printf '%s' "$mmdc_out" | grep -qiE 'could not find chrome|puppeteer|failed to launch|browser was not found|ENOENT|no usable sandbox'; then
            printf '⚠️  %-12s NOT RUN (%s — the browser mmdc drives is unavailable)\n' \
              "mmdc" "$(basename "$block")"
            render_not_run=1
          else
            printf '❌ %-12s %s does not render\n' "mmdc" "$(basename "$block")"
            printf '%s\n' "$mmdc_out" | head -3 | sed "s/^/   /"
            failed=1
          fi
        done
        rm -rf "$block_dir"
      fi
      ;;
  esac
fi

if [[ $failed -eq 0 && $render_not_run -eq 1 ]]; then
  echo "🛑 a diagram was NOT RENDERED — this is not a clean render report" >&2
  exit 3
fi
if [[ $failed -eq 0 && $md_not_run -eq 1 ]]; then
  echo "🛑 markdown findings came from DEFAULT rules — this is not a lint of this document" >&2
  exit 3
fi
exit "$failed"
