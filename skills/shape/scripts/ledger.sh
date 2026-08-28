#!/usr/bin/env bash
# ledger.sh — append one run to the ledger (spec v1.1 §6).
#
# Usage:
#   ledger.sh --doc <path> --mode M --task T --audience A --target G \
#             [--census-before f] [--census-after f] \
#             [--metrics-before f] [--metrics-after f] \
#             [--retrieval f] [--lucid-lint f] \
#             [--facts f --facts-survived N] \
#             [--word-count N] --not-measured "<reason>|none" \
#             [--fixture-id ID] [--ruleset-version V] [--run-index K] \
#             [--reader-family F] [--out-dir runs]
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
# 🛑 `--facts` requires `--facts-survived`. Recording the size of an inventory
# without recording how much of it survived stores the question and throws away
# the answer — and fact survival is the one gate in the protocol that is not
# tunable.
#
# ⚠️ Calibration keys. `--fixture-id`, `--ruleset-version` and `--run-index`
# are what make the §9 attribution matrix — ruleset version × fixture × measure
# — reconstructable. Without them the k = 3 runs of a single fixture land in
# `-2`/`-3` suffixed files distinguishable only by filename, and a run is
# evidence about nothing in particular. `--reader-family` records which model
# family graded, per control 2: a same-family run is not discharged, it is
# same-family evidence, and numbers pooled without the label cannot be re-read
# when a second family becomes available.
#
# ⚠️ Never overwrites. Two passes over the same document on the same day are
# the normal iteration loop, and the second silently replacing the first would
# destroy exactly the evidence this file exists to accumulate; later entries
# take a `-2`, `-3` suffix.
#
# Exit: 0 written · 2 usage · 4 an input file was unreadable or not JSON

set -euo pipefail

doc=""; mode=""; task=""; audience=""; target=""
census_before=""; census_after=""; metrics_before=""; metrics_after=""
retrieval=""; lucid=""; facts=""; survived=""; words=""; not_measured=""; out_dir="runs"
fixture_id=""; ruleset_version=""; run_index=""; reader_family=""

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
    --facts-survived) survived="$2"; shift 2 ;;
    --word-count) words="$2"; shift 2 ;;
    --not-measured) not_measured="$2"; shift 2 ;;
    --fixture-id) fixture_id="$2"; shift 2 ;;
    --ruleset-version) ruleset_version="$2"; shift 2 ;;
    --run-index) run_index="$2"; shift 2 ;;
    --reader-family) reader_family="$2"; shift 2 ;;
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
if [[ -n "$facts" && -z "$survived" ]]; then
  echo "🛑 --facts requires --facts-survived N — the inventory without the gate result is not evidence" >&2
  exit 2
fi
if [[ -n "$survived" && ! "$survived" =~ ^[0-9]+$ ]]; then
  echo "🛑 --facts-survived must be a count" >&2
  exit 2
fi
if [[ -n "$run_index" && ! "$run_index" =~ ^[0-9]+$ ]]; then
  echo "🛑 --run-index must be a count" >&2
  exit 2
fi
# 🛑 A fixture run without its ruleset version cannot be attributed to anything,
# and an unattributable calibration run is worse than an absent one: it looks
# like evidence in the pile.
if [[ -n "$fixture_id" && -z "$ruleset_version" ]]; then
  echo "🛑 --fixture-id requires --ruleset-version — an unattributable run is not evidence" >&2
  exit 2
fi

# 🛑 Validation runs here, in the main shell, before anything is built or
# written. An earlier revision called this from inside `$(…)`: its `exit 4`
# ended the subshell only, so an invalid input yielded an empty string, jq
# failed, and the script exited 2 — "fix your invocation" — after `>` had
# already truncated the entry to zero bytes.
for pair in "census-before:$census_before" "census-after:$census_after" \
            "metrics-before:$metrics_before" "metrics-after:$metrics_after" \
            "retrieval:$retrieval" "lucid-lint:$lucid" "facts:$facts"; do
  path="${pair#*:}"
  if [[ -z "$path" ]]; then continue; fi
  if [[ ! -r "$path" ]]; then
    echo "🛑 cannot read $path (--${pair%%:*}) — ledger entry not written" >&2
    exit 4
  fi
  if ! jq -e . "$path" >/dev/null 2>&1; then
    echo "🛑 $path (--${pair%%:*}) is not valid JSON — ledger entry not written" >&2
    exit 4
  fi
done

# Every path above is readable and parses; this only reads.
read_json() {
  if [[ -z "$1" ]]; then echo "null"; else cat "$1"; fi
}

date_stamp="$(date -u +%Y-%m-%d)"
slug="$(printf '%s' "$doc" | tr '/' '-' | sed -e 's/^-*//' -e 's/\.[^.]*$//')"
# A fixture run names itself: fixture, ruleset, run index. The `-2` suffix
# below is a last-resort collision breaker, never the thing that distinguishes
# one k = 3 replicate from another.
if [[ -n "$fixture_id" ]]; then
  slug="$fixture_id-$ruleset_version${run_index:+-r$run_index}"
fi
mkdir -p "$out_dir"
out="$out_dir/$date_stamp-$slug.json"
n=2
while [[ -e "$out" ]]; do
  out="$out_dir/$date_stamp-$slug-$n.json"
  n=$((n + 1))
done

# Built into a temp file and moved into place, so a jq failure cannot leave a
# truncated entry behind.
tmp="${TMPDIR:-/tmp}/shape-ledger-$$.json"
trap 'rm -f "$tmp"' EXIT

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
  --arg survived "$survived" \
  --arg fixture_id "$fixture_id" --arg ruleset_version "$ruleset_version" \
  --arg run_index "$run_index" --arg reader_family "$reader_family" \
  --arg not_measured "$not_measured" '
  {
    version: 1,
    at: $at,
    doc: $doc,
    classification: {mode: $mode, task: $task, audience: $audience, target: $target},
    calibration: {
      fixture_id:      (if $fixture_id == "" then null else $fixture_id end),
      ruleset_version: (if $ruleset_version == "" then null else $ruleset_version end),
      run_index:       (if $run_index == "" then null else ($run_index | tonumber) end),
      reader_family:   (if $reader_family == "" then null else $reader_family end)
    },
    census: {before: $census_before, after: $census_after},
    metrics: {before: $metrics_before, after: $metrics_after, unvalidated: true},
    retrieval: $retrieval,
    lucid_lint: (if $lucid == null then "not_run" else $lucid end),
    facts: (if $facts == null then null else
             {inventory: ($facts.facts | length),
              survived: ($survived | tonumber),
              all_survived: (($survived | tonumber) == ($facts.facts | length))} end),
    word_count: (if $words == "" then null else ($words | tonumber) end),
    not_measured: (if $not_measured == "none" then [] else ($not_measured | split(";")) end)
  }' > "$tmp"

mv "$tmp" "$out"
echo "✅ ledger entry: $out"
