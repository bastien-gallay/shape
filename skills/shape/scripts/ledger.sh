#!/usr/bin/env bash
# ledger.sh — append one run to the ledger (spec v1.1 §6).
#
# Usage:
#   ledger.sh --doc <path> --mode M --task T --audience A --target G \
#             [--census-before f] [--census-after f] \
#             [--metrics-before f] [--metrics-after f] \
#             [--retrieval f] [--lucid-lint f] [--facts f] \
#             [--word-count N] --not-measured "<reason>|none" \
#             [--out-dir runs]
#
# Every pass writes one entry, whatever the mode. This is what makes the two
# open questions — does the lint score track locate cost, do any F12 metrics
# separate high-cost documents — answerable by accumulation rather than by
# argument.
#
# 🛑 `--not-measured` is mandatory and may not be empty by omission. Pass
# `none` to state explicitly that everything ran. A verification you skipped is
# not a verification you passed.
#
# Exit: 0 written · 2 usage · 4 an input file was unreadable

set -euo pipefail

doc=""; mode=""; task=""; audience=""; target=""
census_before=""; census_after=""; metrics_before=""; metrics_after=""
retrieval=""; lucid=""; facts=""; words=""; not_measured=""; out_dir="runs"

while [[ $# -gt 0 ]]; do
  case "$1" in
    --doc) doc="$2"; shift 2 ;;
    --mode) mode="$2"; shift 2 ;;
    --task) task="$2"; shift 2 ;;
    --audience) audience="$2"; shift 2 ;;
    --target) target="$2"; shift 2 ;;
    --census-before) census_before="$2"; shift 2 ;;
    --census-after) census_after="$2"; shift 2 ;;
    --metrics-before) metrics_before="$2"; shift 2 ;;
    --metrics-after) metrics_after="$2"; shift 2 ;;
    --retrieval) retrieval="$2"; shift 2 ;;
    --lucid-lint) lucid="$2"; shift 2 ;;
    --facts) facts="$2"; shift 2 ;;
    --word-count) words="$2"; shift 2 ;;
    --not-measured) not_measured="$2"; shift 2 ;;
    --out-dir) out_dir="$2"; shift 2 ;;
    *) echo "unknown option: $1" >&2; exit 2 ;;
  esac
done

if [[ -z "$doc" || -z "$mode" || -z "$task" || -z "$audience" || -z "$target" ]]; then
  echo "usage: ledger.sh --doc P --mode M --task T --audience A --target G --not-measured R" >&2
  exit 2
fi
if [[ -z "$not_measured" ]]; then
  echo "🛑 --not-measured is mandatory; pass 'none' to state that everything ran" >&2
  exit 2
fi

# Read a JSON input, or the JSON null when it was not produced. An unreadable
# path that was explicitly named is an error, not a silent null.
read_json() {
  local path="$1"
  if [[ -z "$path" ]]; then echo "null"; return; fi
  if [[ ! -r "$path" ]]; then
    echo "🛑 cannot read $path — ledger entry not written" >&2
    exit 4
  fi
  if ! jq -e . "$path" >/dev/null 2>&1; then
    echo "🛑 $path is not valid JSON — ledger entry not written" >&2
    exit 4
  fi
  cat "$path"
}

date_stamp="$(date -u +%Y-%m-%d)"
slug="$(printf '%s' "$doc" | tr '/' '-' | sed -e 's/^-*//' -e 's/\.[^.]*$//')"
mkdir -p "$out_dir"
out="$out_dir/$date_stamp-$slug.json"

jq -n \
  --arg doc "$doc" --arg mode "$mode" --arg task "$task" \
  --arg audience "$audience" --arg target "$target" \
  --arg at "$(date -u +%Y-%m-%dT%H:%M:%SZ)" \
  --argjson census_before "$(read_json "$census_before")" \
  --argjson census_after "$(read_json "$census_after")" \
  --argjson metrics_before "$(read_json "$metrics_before")" \
  --argjson metrics_after "$(read_json "$metrics_after")" \
  --argjson retrieval "$(read_json "$retrieval")" \
  --argjson lucid "$(read_json "$lucid")" \
  --argjson facts "$(read_json "$facts")" \
  --arg words "$words" \
  --arg not_measured "$not_measured" '
  {
    version: 1,
    at: $at,
    doc: $doc,
    classification: {mode: $mode, task: $task, audience: $audience, target: $target},
    census: {before: $census_before, after: $census_after},
    metrics: {before: $metrics_before, after: $metrics_after, unvalidated: true},
    retrieval: $retrieval,
    lucid_lint: (if $lucid == null then "not_run" else $lucid end),
    facts: (if $facts == null then null else
             {inventory: ($facts.facts | length), survived: null} end),
    word_count: (if $words == "" then null else ($words | tonumber) end),
    not_measured: (if $not_measured == "none" then [] else ($not_measured | split(";")) end)
  }' > "$out"

echo "✅ ledger entry: $out"
