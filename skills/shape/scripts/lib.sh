# lib.sh — guards shared by every check. Sourced, never executed.
#
# 🛑 This file exists because the same defect has now been written four times
# in this repo: a `jq` producer inside a process substitution, whose failure
# `set -euo pipefail` cannot see. The loop reads zero rows and the check prints
# a cheerful ✅. See CLAUDE.md, "the failure mode this repo keeps producing".
#
# Use `jq_rows` for every census read. It runs the producer in its own
# statement, into a real file, and checks it.

# jq_rows <out-file> <check-name> <jq-args...>
#
# Exits 4 — the check did not run — when the producer fails. It deliberately
# does NOT treat zero rows as an error: a document with no headings, no tables
# or no paragraphs is a real document, and the caller's own census guard has
# already established that the parse itself succeeded. ⚠️ Zero rows is still
# never a ✅ — the caller must say "nothing to check", which is what
# `rows_empty` is for.
jq_rows() {
  local out="$1" name="$2"
  shift 2
  if ! jq -r "$@" > "$out"; then
    printf '🛑 %s: the census producer failed — the check did not run\n' "$name" >&2
    exit 4
  fi
}

# rows_empty <file> — true when the producer legitimately selected nothing.
rows_empty() { [[ ! -s "$1" ]]; }

# jq_value <var-name> <check-name> <jq-args...>
#
# The scalar counterpart. ⚠️ A bare `x="$(jq …)"` under `set -e` aborts with
# jq's own status — 5, say — which is not in the exit contract at all, so the
# caller cannot tell "the check did not run" from anything else.
jq_value() {
  local __var="$1" __name="$2" __out __st=0
  shift 2
  __out="$(jq -r "$@")" || __st=$?
  if [[ $__st -ne 0 ]]; then
    printf '🛑 %s: the census producer failed — the check did not run\n' "$__name" >&2
    exit 4
  fi
  printf -v "$__var" '%s' "$__out"
}
