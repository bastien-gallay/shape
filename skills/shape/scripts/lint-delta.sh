#!/usr/bin/env bash
# lint-delta.sh — per-category lucid-lint score, before vs after.
#
# Usage:
#   lint-delta.sh --baseline <file> [--profile dev-doc|public|falc]
#   lint-delta.sh --compare  <file> [--profile dev-doc|public|falc]
#
# 🛑 SIGNAL, NOT A GATE (spec v1.1 §A1). This script never fails a pass on the
# score. Two reasons, recorded so the decision can be revisited:
#
#   - False green. The five current categories are intra-sentential. A document
#     written well sentence by sentence and unusable structurally scores high;
#     gating on it would validate exactly what shape exists to reject.
#   - Goodhart, direct. Converting prose to tables shortens units mechanically
#     and raises the score whether or not anything improved. shape would hold a
#     lever on its own grade.
#
# ⚠️ Suspended 2026-08-31, not dropped: no valid locate-cost measure exists to
# correlate the score against. See `../references/calibration.md`.
#
# 🔒 Falsification condition. If the score turns out to track locate cost on the
# corpus, this change was wrong and the gate comes back — with the correlation
# and the corpus size stated. The ledger (scripts/ledger.sh) is what makes that
# answerable: it stores the score next to the retrieval result on every pass.
#
# ⛔ shape does not wait for a lucid-lint `access` category. Structural checks
# are owned locally under scripts/access/ and promoted outward once measured.
#
# Exit: 0 the signal was produced (regression or not) · 2 usage
#       · 3 lucid-lint absent, errored, or drifted — the check is NOT RUN
#       · 4 the comparison itself did not run (unreadable or empty scores)
#
# The baseline is written under $SHAPE_BASELINE_DIR (default $TMPDIR), never
# into the working tree. Its path is printed by --baseline and named by
# --compare when it is missing.

set -euo pipefail

# Pinned: lucid-lint's JSON schema version this script understands. A bump means
# the shape may have moved; fail loudly rather than read a field that no longer
# means what it did.
SCHEMA_VERSION=2

mode="${1:-}"
file="${2:-}"
profile="dev-doc"
if [[ "${3:-}" == "--profile" && -n "${4:-}" ]]; then profile="$4"; fi

if [[ -z "$file" || ! -r "$file" ]]; then
  echo "usage: lint-delta.sh --baseline|--compare <file> [--profile P]" >&2
  exit 2
fi

# 🛑 The baseline never lands in the working tree. It used to be
# `.shape-baseline.json` relative to the cwd, so a pass run from a repo root
# dropped an untracked file there — invisible in this repo, which gitignores
# it, and in a shared checkout that is how a stray file ends up in someone
# else's commit. Measured 2026-08-31 on a client repo.
#
# ⚠️ Keyed by the document's ABSOLUTE path and the profile, because the store
# is now shared across repos: one file per repo root already collided between
# two documents, and a `falc` baseline compared against a `dev-doc` run is the
# same silent wrong answer one level up. Override the directory with
# SHAPE_BASELINE_DIR.
doc_abs="$(cd "$(dirname "$file")" && pwd)/$(basename "$file")"
baseline_dir="${SHAPE_BASELINE_DIR:-${TMPDIR:-/tmp}}"
baseline_key="$(printf '%s\n' "$doc_abs" | cksum | tr -d ' \n' | cut -c1-12)"
baseline_name="$(basename "$file" | sed -e 's/\.[^.]*$//' -e 's/[^A-Za-z0-9_-]/-/g')"
baseline="$baseline_dir/shape-baseline-$baseline_name-$profile-$baseline_key.json"

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
    # ⚠️ Reported, never returned as a failure: this is a signal (§A1). The
    # exit code says the signal was produced, not that the document is good.
    if [[ $regressed -eq 1 ]]; then
      echo "⚠️  a category regressed — signal only, this does not fail the pass"
    else
      echo "✅ no category regressed"
    fi
    echo "📌 informational: the score is evidence, never the objective."
    exit 0
    ;;
  *)
    echo "usage: lint-delta.sh --baseline|--compare <file> [--profile P]" >&2
    exit 2
    ;;
esac
