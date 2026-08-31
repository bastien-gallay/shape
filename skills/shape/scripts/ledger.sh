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
#             [--reader-family F] [--out-dir runs] \
#             [--external ID [--external-map PATH]]
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
# --- The external regime -----------------------------------------------------
#
# `--external ID` records a run over a document that may not be described here
# at all — a client document, an internal page. Only the numbers come back.
#
# 🛑 The entry as built without it leaks the document. `census.blocks[].path`
# carries the text of every heading verbatim, `census.source` carries an
# absolute path, and `doc` carries the filename. Three fields, and together
# they reconstruct the outline of a document nobody was allowed to read.
# `--external` replaces all three with the opaque ID, then refuses to write if
# any path survives anywhere in the entry.
#
# ⚠️ What is forfeited, stated plainly: an external entry is reproducible by
# nobody, its author included. That is the price of the regime, and the reason
# the census counts — blocks, levels, tables, figures — are kept: they are what
# lets a later reader say which kind of document a conclusion came from.
#
# The ID ↔ real path mapping is appended to `--external-map`, default
# `$SHAPE_EXTERNAL_MAP` or `~/.shape/external-map.tsv`. It lives outside the
# repository by construction and the script refuses a map path inside the
# worktree, because a mapping committed by accident undoes the whole regime.
#
# ⚠️ This script protects the ledger, not the report. A `diagnose` report
# quotes headings. Never paste one into `calibration.md` or a commit message —
# restate the finding in abstract terms.
#
# Exit: 0 written · 2 usage · 4 an input file was unreadable or not JSON, a
#       control failed, or the entry still carried a path

set -euo pipefail

doc=""; mode=""; task=""; audience=""; target=""
census_before=""; census_after=""; metrics_before=""; metrics_after=""
retrieval=""; lucid=""; facts=""; survived=""; words=""; not_measured=""; out_dir="runs"
fixture_id=""; ruleset_version=""; run_index=""; reader_family=""
external=""; external_map=""

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
    --external) external="$2"; shift 2 ;;
    --external-map) external_map="$2"; shift 2 ;;
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
if [[ -n "$external_map" && -z "$external" ]]; then
  echo "🛑 --external-map without --external — there is nothing to map" >&2
  exit 2
fi
# 🛑 The two regimes do not mix. A fixture is a document this repository ships;
# an external document is one it may not describe. An entry claiming to be both
# is one that will later be read as reproducible when it is not.
if [[ -n "$fixture_id" && -n "$external" ]]; then
  echo "🛑 --fixture-id and --external are exclusive — a fixture is in-repo by definition" >&2
  exit 2
fi
if [[ -n "$external" && ! "$external" =~ ^[A-Za-z0-9][A-Za-z0-9_-]*$ ]]; then
  echo "🛑 --external ID must be a bare slug (letters, digits, - and _) — it stands in for a path" >&2
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

tmp_base="${TMPDIR:-/tmp}/shape-ledger-$$"

# --- Scrub and guard ---------------------------------------------------------
#
# One definition of the scrub, used by the entry and by its own positive
# control. Written without an apostrophe: this is a single-quoted program, and
# an apostrophe inside one hands the program body to the shell.
SCRUB_PROG='
  if . == null then null
  else
      (if has("source") then .source = $id else . end)
    | (if has("blocks") then
         .blocks |= map(if has("path") then .path = "" else . end)
       else . end)
  end'

# read_census FILE → stdout. Scrubbed when the run is external.
read_census() {
  if [[ -z "$1" ]]; then printf 'null\n'; return 0; fi
  if [[ -z "$external" ]]; then cat "$1"; return 0; fi
  jq --arg id "$external" "$SCRUB_PROG" "$1"
}

read_json() {
  if [[ -z "$1" ]]; then echo "null"; else cat "$1"; fi
}

# leak_scan FILE TOKEN… → 0 clean · 1 a leak · 2 the scan itself did not run.
# ⚠️ The producer runs in its own statement, into a real file, and its status is
# read. A scan that read zero strings is a scan that did not happen, and must
# never report clean.
leak_scan() {
  local file="$1"; shift
  local strings="$tmp_base-strings.txt"
  local st=0 found=0 tok
  jq -r '.. | strings' "$file" > "$strings" || st=$?
  if [[ $st -ne 0 ]]; then
    echo "🛑 could not read the entry back to scan it — not written" >&2
    return 2
  fi
  if [[ ! -s "$strings" ]]; then
    echo "🛑 the leak scan read zero strings — the scan did not run" >&2
    return 2
  fi
  if grep -nE '(^|[^A-Za-z0-9])(/[A-Za-z0-9._~-]+){2,}' "$strings" >&2; then
    echo "🛑 the entry carries a filesystem path" >&2
    found=1
  fi
  for tok in "$@"; do
    if [[ ${#tok} -lt 3 ]]; then continue; fi
    if grep -niF -- "$tok" "$strings" >&2; then
      echo "🛑 the entry carries '$tok', a component of the source path" >&2
      found=1
    fi
  done
  return $found
}

if [[ -n "$external" ]]; then
  # Positive control: the scrubber must remove a heading and a source path it
  # is handed. Negative control: the guard must refuse an entry that still has
  # one. Both run on every invocation, because a scrubber trusted without being
  # exercised is how a path reaches a commit.
  sentinel="shape_leak_control_$$"
  ctl_in="$tmp_base-ctl-in.json"
  ctl_out="$tmp_base-ctl-out.json"
  printf '{"version":1,"source":"/Users/nobody/%s.md","blocks":[{"i":0,"type":"heading","level":1,"path":"%s","markers":[]}]}\n' \
    "$sentinel" "$sentinel" > "$ctl_in"

  ctl_st=0
  jq --arg id "$external" "$SCRUB_PROG" "$ctl_in" > "$ctl_out" || ctl_st=$?
  if [[ $ctl_st -ne 0 ]]; then
    echo "🛑 positive control failed: the scrubber errored — ledger entry not written" >&2
    exit 4
  fi
  if grep -qF -- "$sentinel" "$ctl_out"; then
    echo "🛑 positive control failed: the scrubber left a known heading and path in place" >&2
    exit 4
  fi
  ctl_st=0
  leak_scan "$ctl_in" "$sentinel" >/dev/null 2>&1 || ctl_st=$?
  if [[ $ctl_st -eq 0 ]]; then
    echo "🛑 negative control failed: the leak guard passed a document path" >&2
    exit 4
  fi

  external_map="${external_map:-${SHAPE_EXTERNAL_MAP:-$HOME/.shape/external-map.tsv}}"
  map_dir="$(dirname "$external_map")"
  mkdir -p "$map_dir"
  map_abs="$(cd "$map_dir" && pwd)/$(basename "$external_map")"
  repo_root=""
  repo_root="$(git rev-parse --show-toplevel 2>/dev/null)" || repo_root=""
  if [[ -n "$repo_root" && "$map_abs" == "$repo_root"/* ]]; then
    echo "🛑 --external-map is inside the worktree ($map_abs) — a committed mapping undoes the regime" >&2
    exit 2
  fi

  # An ID stands for one document, permanently. Reusing it for another pools
  # two documents into one row of the attribution matrix.
  doc_abs="$(cd "$(dirname "$doc")" 2>/dev/null && pwd)/$(basename "$doc")" || doc_abs="$doc"
  if [[ -f "$map_abs" ]]; then
    prev=""
    prev="$(awk -F'\t' -v id="$external" '$1 == id {print $2; exit}' "$map_abs")" || prev=""
    if [[ -n "$prev" && "$prev" != "$doc_abs" ]]; then
      echo "🛑 $external already stands for a different document in $map_abs" >&2
      exit 2
    fi
  fi
fi

date_stamp="$(date -u +%Y-%m-%d)"
slug="$(printf '%s' "$doc" | tr '/' '-' | sed -e 's/^-*//' -e 's/\.[^.]*$//')"
# A fixture run names itself: fixture, ruleset, run index. The `-2` suffix
# below is a last-resort collision breaker, never the thing that distinguishes
# one k = 3 replicate from another.
if [[ -n "$fixture_id" ]]; then
  slug="$fixture_id-$ruleset_version${run_index:+-r$run_index}"
fi
# 🛑 An external run names itself after the ID, never after the document — the
# filename is part of the entry.
if [[ -n "$external" ]]; then
  slug="$external${ruleset_version:+-$ruleset_version}${run_index:+-r$run_index}"
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
tmp="$tmp_base.json"
trap 'rm -f "$tmp" "$tmp_base"-*' EXIT

jq -n \
  --arg doc "${external:-$doc}" --arg mode "$mode" --arg task "$task" \
  --arg audience "$audience" --arg target "$target" \
  --arg at "$(date -u +%Y-%m-%dT%H:%M:%SZ)" \
  --argjson external "$(if [[ -n "$external" ]]; then echo true; else echo false; fi)" \
  --argjson census_before "$(read_census "$census_before")" \
  --argjson census_after "$(read_census "$census_after")" \
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
    external: $external,
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

if [[ -n "$external" ]]; then
  # Every heading must be gone, whatever the scrub thought it did.
  left=0
  left="$(jq '[.census | .. | objects | select(has("path")) | .path | select(. != "")] | length' "$tmp")"
  if [[ "$left" -ne 0 ]]; then
    echo "🛑 $left heading text(s) survived the scrub — ledger entry not written" >&2
    exit 4
  fi
  # Tokens of the real path, plus the home directory, must appear nowhere —
  # including in --not-measured and in a retrieval note.
  scan_st=0
  leak_scan "$tmp" $(printf '%s' "$doc_abs" | tr '/' ' ') "$HOME" || scan_st=$?
  if [[ $scan_st -ne 0 ]]; then
    echo "🛑 the entry still describes the document — not written" >&2
    exit 4
  fi
fi

mv "$tmp" "$out"

if [[ -n "$external" ]]; then
  printf '%s\t%s\t%s\n' "$external" "$doc_abs" "$(date -u +%Y-%m-%dT%H:%M:%SZ)" >> "$map_abs"
  echo "✅ ledger entry: $out (external, mapping in $map_abs)"
else
  echo "✅ ledger entry: $out"
fi
