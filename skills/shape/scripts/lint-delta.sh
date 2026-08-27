#!/usr/bin/env bash
# lint-delta.sh — per-category lucid-lint score, before vs after.
#
# Usage:
#   lint-delta.sh --baseline <file> [--profile dev-doc|public|falc]
#   lint-delta.sh --compare  <file> [--profile dev-doc|public|falc]
#
# ⚠️ The score is evidence, never the objective. A pass that raises the score
# while lowering retrieval accuracy has failed.
#
# 📌 lucid-lint has no `access` category yet (brief §5 item 2). Until it does,
# access structure is judged, not measured, and the report says so.
#
# Exit: 0 ok or improved · 1 a category regressed · 2 usage
#       · 3 lucid-lint absent, errored, or drifted — the check is NOT RUN
#       · 4 the comparison itself did not run (unreadable or empty scores)

set -euo pipefail

# Pinned: lucid-lint's JSON schema version this script understands. A bump means
# the shape may have moved; fail loudly rather than read a field that no longer
# means what it did.
SCHEMA_VERSION=2

mode="${1:-}"
file="${2:-}"
profile="dev-doc"
if [[ "${3:-}" == "--profile" && -n "${4:-}" ]]; then profile="$4"; fi
baseline=".shape-baseline.json"

if [[ -z "$file" || ! -r "$file" ]]; then
  echo "usage: lint-delta.sh --baseline|--compare <file> [--profile P]" >&2
  exit 2
fi

if ! command -v lucid-lint >/dev/null 2>&1; then
  echo "⚠️ lucid-lint not installed — lint check NOT RUN (not passed)" >&2
  exit 3
fi

# `set -e` would abort on a findings exit before we could classify it, so
# capture the status in its own statement with an explicit fallback. Findings
# are a result; a crash is not.
status=0
out="$(lucid-lint check --format json --profile "$profile" "$file")" || status=$?
if [[ $status -gt 1 ]]; then
  echo "lucid-lint errored (exit $status) — treat as NOT RUN, never as clean" >&2
  exit 3
fi

check_schema() {
  local label="$1" json="$2" got
  got="$(printf '%s' "$json" | jq -r '.version // "missing"')"
  if [[ "$got" != "$SCHEMA_VERSION" ]]; then
    echo "$label JSON schema is v$got, this script pins v$SCHEMA_VERSION — NOT RUN" >&2
    exit 3
  fi
}
check_schema "lucid-lint" "$out"

case "$mode" in
  --baseline)
    printf '%s\n' "$out" > "$baseline"
    printf '%s\n' "$out" | jq -r '
      "baseline \(.score.value)/\(.score.max) — " +
      ([.category_scores[] | "\(.category) \(.value)/\(.max)"] | join(" · "))'
    echo "written to $baseline"
    ;;
  --compare)
    if [[ ! -r "$baseline" ]]; then
      echo "no $baseline — run --baseline before editing" >&2
      exit 2
    fi
    # ⚠️ The baseline is checked too. A baseline captured under an older
    # schema is exactly the drift the pin exists to catch, and without this it
    # reached the jq below — where a failure was silent. Measured 2026-08-27.
    check_schema "$baseline" "$(cat "$baseline")"

    # jq runs in its own statement, into a file. In a process substitution its
    # failure is invisible to `set -e`, and the loop reading zero rows printed
    # "✅ no category regressed" — a gate reported as passed with no check run.
    rows="${TMPDIR:-/tmp}/shape-lint-$$.tsv"
    trap 'rm -f "$rows"' EXIT
    if ! jq -rn --slurpfile b "$baseline" --argjson a "$out" '
      ($b[0].category_scores | map({key: .category, value: .value}) | from_entries) as $bs
      | ($a.category_scores  | map({key: .category, value: .value}) | from_entries) as $as
      | (($bs + $as) | keys_unsorted[])
      | [., ($bs[.] // 0), ($as[.] // 0)] | @tsv' > "$rows"; then
      echo "🛑 could not compare scores — the check did not run" >&2
      exit 4
    fi
    if [[ ! -s "$rows" ]]; then
      echo "🛑 no categories to compare — the check did not run" >&2
      exit 4
    fi

    regressed=0
    while IFS=$'\t' read -r cat before after; do
      delta=$((after - before))
      sign="+"; if [[ $delta -lt 0 ]]; then sign=""; fi
      printf '%-14s %3d → %3d (%s%d)\n' "$cat" "$before" "$after" "$sign" "$delta"
      if [[ $delta -lt 0 ]]; then regressed=1; fi
    done < "$rows"
    if [[ $regressed -eq 1 ]]; then
      echo "❌ a category regressed" >&2
    else
      echo "✅ no category regressed"
    fi
    exit "$regressed"
    ;;
  *)
    echo "usage: lint-delta.sh --baseline|--compare <file> [--profile P]" >&2
    exit 2
    ;;
esac
