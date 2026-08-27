#!/usr/bin/env bash
# metrics.sh — F12 visual-rhythm metrics, computed from one census.
#
# Usage: metrics.sh <blocks.json> [--wrap 80] [--window 45]
#
# 🛑 REPORT-ONLY. Every number here is a hypothesis, not a setting (spec v1.1
# §B2). No metric gates anything until the calibration protocol in §5 has run
# over a corpus, and no threshold is hard-coded in this script — thresholds
# live in `.shape.toml`, dated, beside the corpus size they came from.
#
# ⚠️ `--wrap` is the assumed render width. V2 counts *rendered* lines, so a
# metric whose unit is implicit is not reproducible: the value is echoed into
# the output and must be printed in the report.
#
# Exit: 0 metrics written · 2 usage/unreadable · 4 census unreadable or empty
#
# ⚠️ A metric that cannot be computed reports null, never its best value. V2 on
# a document shorter than the window and V6 on a document with one section are
# *not measurable*, and reporting 0 for the first would hand a dense wall of
# prose the ideal score.

set -euo pipefail

blocks="${1:-}"
wrap=80
window=45
shift || true
while [[ $# -gt 0 ]]; do
  # 🛑 A missing option value is a usage error. `shift 2` on a single remaining
  # argument returns non-zero, and under `set -e` the script died with exit 1 —
  # which this repo's contract reads as "the document failed the gate".
  case "$1" in
    --wrap|--window)
      if [[ $# -lt 2 ]]; then
        echo "usage: metrics.sh <blocks.json> [--wrap N] [--window N] — $1 needs a value" >&2
        exit 2
      fi
      if [[ ! "$2" =~ ^[0-9]+$ || "$2" -eq 0 ]]; then
        echo "usage: $1 takes a positive integer, got '$2'" >&2
        exit 2
      fi
      if [[ "$1" == "--wrap" ]]; then wrap="$2"; else window="$2"; fi
      shift 2
      ;;
    *) echo "unknown option: $1" >&2; exit 2 ;;
  esac
done

if [[ -z "$blocks" || ! -r "$blocks" ]]; then
  echo "usage: metrics.sh <blocks.json> [--wrap N] [--window N]" >&2
  exit 2
fi

# The producer runs in its own statement and is checked. An unreadable census
# must never reach the metrics as "a document with no findings".
if ! jq -e '.blocks | length > 0' "$blocks" >/dev/null 2>&1; then
  echo "🛑 $blocks is unreadable or has no blocks — metrics did not run" >&2
  exit 4
fi

jq --argjson wrap "$wrap" --argjson window "$window" '
  .blocks as $b

  # Rendered lines: prose wraps, everything else keeps its source lines.
  | [ $b[] | . + {rendered: (if .type == "paragraph"
                             then ([1, (.chars / $wrap | ceil)] | max)
                             else .lines end)} ] as $r

  # V1 — longest prose run, in rendered lines, uninterrupted by another type.
  | ([ foreach $r[] as $x (0;
         if $x.type == "paragraph" then . + $x.rendered else 0 end) ] | max // 0) as $v1

  # V2 — densest sliding window: share of rendered lines that are prose.
  | ([$r[].rendered] | add // 0) as $total_rendered
  | ([ $r[] | if .type == "paragraph" then .rendered else 0 end ]) as $prose
  | ([$r[].rendered]) as $all
  # ⚠️ null, not 0, when no window reaches $window rendered lines. 0 is the
  # best possible score, so a short dense document used to report the ideal.
  | ([ range(0; ($all | length)) as $i
       | [ foreach range($i; $all | length) as $j ({n: 0, p: 0};
             {n: (.n + $all[$j]), p: (.p + $prose[$j])})
           | select(.n >= $window) | (.p / .n) ] | first // empty ]
     | if length == 0 then null else max end) as $v2

  # V3 — first screen: is the reader oriented in the first 40 source lines?
  | ([ $b[] | select(.start <= 40) ]) as $first
  | { purpose:  ([ $first[] | select(.type == "paragraph") ] | length > 0),
      audience: ([ $first[] | select(.type == "frontmatter" or .type == "table"
                                     or .type == "admonition") ] | length > 0),
      nonprose: ([ $first[] | select(.type != "paragraph" and .type != "heading"
                                     and .type != "rule") ] | length > 0) } as $v3

  # V4 — longest run of consecutive blocks of the same non-prose type.
  | ([ foreach $b[] as $x ({t: "", n: 0};
         if $x.type == .t then {t: .t, n: (.n + 1)} else {t: $x.type, n: 1} end)
       | select(.t != "paragraph" and .t != "rule" and .t != "heading") | .n ]
     | max // 0) as $v4

  # V5 — distance in blocks between a figure and its nearest caption or
  # paragraph. 0 means the mention is contiguous (Mayer contiguity).
  | ([ $b[] | select(.type == "figure") | .i as $fi
       | ([ $b[] | select(.type == "caption" or .type == "paragraph")
            | (.i - $fi) | fabs ] | min // 999) ]) as $v5_each

  # V6 — coefficient of variation of section length at depth 2. ⚠️ The last
  # section closes at the last line of the document, not at 0: emitting 0 for
  # it and filtering it out computed the CV over n−1 sections, and returned
  # null on any document with exactly two.
  | ([ $b[] | select(.type == "heading" and .level == 2) | .start ]) as $h2
  | ([ $b[].end ] | max) as $doc_end
  | ([ range(0; ($h2 | length))
       | (if . + 1 < ($h2 | length) then $h2[. + 1] else $doc_end + 1 end) - $h2[.] ]
     | map(select(. > 0))) as $seclens
  | (if ($seclens | length) > 1
     then ($seclens | add / length) as $mu
       | (($seclens | map(pow(. - $mu; 2)) | add / length | sqrt) / $mu)
     else null end) as $v6

  # V7 — structural-block density around marker-bearing blocks vs the document
  # mean. 📌 Exploratory; expect it to be dropped at calibration.
  | ([ $b[] | select(.type != "paragraph") ] | length) as $struct
  | (($struct / ($b | length))) as $doc_density
  | ([ $b[] | select((.markers | length) > 0) | .i ]) as $marked
  | (if ($marked | length) > 0
     then ([ $marked[] as $m
             | ([ $b[] | select(.i >= $m - 1 and .i <= $m + 1
                                and .type != "paragraph") ] | length) / 3 ]
           | add / length)
     else null end) as $marker_density

  | {
      version: 1,
      unvalidated: true,
      wrap: $wrap,
      window: $window,
      metrics: {
        V1_longest_prose_run:    {value: $v1, unit: "rendered lines"},
        V2_screen_density:       {value: (if $v2 == null then null else (($v2 * 100 | round) / 100) end),
                                  unit: "max prose share",
                                  note: (if $v2 == null then "document shorter than the window — not measurable" else null end)},
        V3_first_screen:         {value: $v3, unit: "presence"},
        V4_block_type_run:       {value: $v4, unit: "blocks"},
        V5_figure_mention:       {value: ($v5_each | max // null), unit: "blocks", per_figure: $v5_each},
        V6_section_length_cv:    {value: (if $v6 == null then null else (($v6 * 100 | round) / 100) end),
                                  unit: "coefficient of variation", note: "report only, no threshold"},
        V7_differential_air:     {value: (if $marker_density == null then null
                                          else ((($marker_density - $doc_density) * 100 | round) / 100) end),
                                  unit: "density delta vs document mean",
                                  note: "exploratory, expect removal at calibration"}
      }
    }
' "$blocks"
