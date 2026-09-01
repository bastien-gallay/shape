# shape release automation.
#
# Usage: just release 0.2.0
#
# Bumps version in .claude-plugin/plugin.json and .claude-plugin/marketplace.json
# atomically, commits, and creates an annotated git tag. Prevents the
# "forgot to bump plugin.json on release" silent-freeze failure mode.

set shell := ["bash", "-uc"]

default:
    @just --list

# Release a new version: bump manifests, commit, tag.
release VERSION:
    #!/usr/bin/env bash
    set -euo pipefail

    if [[ ! "{{VERSION}}" =~ ^[0-9]+\.[0-9]+\.[0-9]+(-[0-9A-Za-z.-]+)?$ ]]; then
        echo "error: VERSION must be semver (X.Y.Z or X.Y.Z-prerelease), got '{{VERSION}}'" >&2
        exit 2
    fi

    if ! git diff-index --quiet HEAD --; then
        echo "error: working tree is dirty, commit or stash first" >&2
        exit 2
    fi

    if git rev-parse "v{{VERSION}}" >/dev/null 2>&1; then
        echo "error: tag v{{VERSION}} already exists" >&2
        exit 2
    fi

    if ! grep -qE "^## v{{VERSION}}( |$)" CHANGELOG.md; then
        echo "error: CHANGELOG.md has no '## v{{VERSION}}' section — rename '## Unreleased' before releasing" >&2
        exit 2
    fi

    plugin=".claude-plugin/plugin.json"
    market=".claude-plugin/marketplace.json"

    tmp="$(mktemp)"
    jq --arg v "{{VERSION}}" '.version = $v' "$plugin" > "$tmp" && mv "$tmp" "$plugin"

    tmp="$(mktemp)"
    jq --arg v "{{VERSION}}" '.metadata.version = $v | .plugins[0].version = $v' "$market" > "$tmp" && mv "$tmp" "$market"

    git add "$plugin" "$market"
    git commit -m "chore: release v{{VERSION}}"
    git tag -a "v{{VERSION}}" -m "Release v{{VERSION}}"

    echo "✓ Tagged v{{VERSION}}. Push with: git push && git push --tags"

# Verify plugin.json and marketplace.json versions agree.
check-versions:
    #!/usr/bin/env bash
    set -euo pipefail
    p=$(jq -r .version .claude-plugin/plugin.json)
    m=$(jq -r .metadata.version .claude-plugin/marketplace.json)
    mp=$(jq -r .plugins[0].version .claude-plugin/marketplace.json)
    if [[ "$p" != "$m" || "$p" != "$mp" ]]; then
        echo "version mismatch: plugin.json=$p marketplace.metadata=$m marketplace.plugins[0]=$mp" >&2
        exit 1
    fi
    echo "✓ versions aligned: $p"

# Build the skill bundle as a .skill file into dist/.
# A .skill file is a plain zip archive with a .skill extension,
# OS-registered to Claude Desktop for one-click install via
# double-click and also accepted by the claude.ai web uploader.
# Archive layout: shape/SKILL.md at the root (no skills/ prefix), with
# references/, scripts/, assets/ and templates/ alongside it.
# Build the .skill bundle into dist/.
package:
    #!/usr/bin/env bash
    set -euo pipefail

    version=$(jq -r .version .claude-plugin/plugin.json)
    if [[ -z "$version" || "$version" == "null" ]]; then
        echo "error: could not read version from plugin.json" >&2
        exit 1
    fi

    mkdir -p dist
    out="dist/shape-v${version}.skill"
    rm -f "$out"

    (cd skills && zip -r "../$out" shape \
        -x 'shape/.*' 'shape/**/.*')

    echo "✓ built $out"
    unzip -l "$out"

# Every fixture is surveyed and a tally printed; one failing fixture must not
# end the sweep, or the corpus only ever reports its first problem.
# Run every verification script against the fixture corpus.
check-fixtures:
    #!/usr/bin/env bash
    set -uo pipefail
    shopt -s nullglob
    # README.md documents the corpus; it is not a member of it.
    files=()
    for f in fixtures/*.md; do
        [[ "$(basename "$f")" == "README.md" ]] || files+=("$f")
    done
    if [[ ${#files[@]} -eq 0 ]]; then
        echo "no fixtures yet — see fixtures/README.md" >&2
        exit 0
    fi
    tmp="${TMPDIR:-/tmp}/shape-fixtures-$$"
    mkdir -p "$tmp"
    trap 'rm -rf "$tmp"' EXIT
    failed=0
    not_run=0
    for f in "${files[@]}"; do
        echo "── $f"
        # Control 6 of docs/shape-validation-protocol.md, enforced rather than
        # promised: a fixture edited without re-freezing is an error, not a
        # matter of discipline. No key yet means the fixture is not frozen.
        key="${f%.md}.key.yaml"
        if [[ -f "$key" ]]; then
            want="$(sed -n 's/^document_sha256:[[:space:]]*"\{0,1\}\([0-9a-f]*\).*/\1/p' "$key")"
            got="$(shasum -a 256 "$f" | cut -d" " -f1)"
            if [[ -z "$want" ]]; then
                echo "   🛑 $key has no document_sha256 — the fixture is not frozen"
                failed=$((failed + 1)); continue
            elif [[ "$want" != "$got" ]]; then
                echo "   🛑 $f changed since it was frozen — NOT RUN"
                echo "      frozen $want"
                echo "      actual $got"
                failed=$((failed + 1)); continue
            fi
        fi
        if ! skills/shape/scripts/extract-facts.sh "$f" > "$tmp/facts.json"; then
            echo "   ⚠️  no fact candidates — skipped"
            continue
        fi
        # 🛑 Own statement, real file, status read directly. `| tail -1` was
        # right only while the summary was the last line — a low-coverage
        # warning now follows it, and tail -1 showed its least informative
        # line while hiding the count it was warning about.
        vf_st=0
        skills/shape/scripts/verify-facts.sh "$tmp/facts.json" "$f" \
            > "$tmp/verify.txt" 2>&1 || vf_st=$?
        # From the first loss, or from the summary when there is none, to the
        # end — so ❌ lines and the coverage warning both survive the filter.
        awk '/^❌/ || /distinct facts survived/ {p=1} p' "$tmp/verify.txt" > "$tmp/verify-cut.txt"
        # An exit-4 run prints neither, and must not be summarised as silence.
        if [[ -s "$tmp/verify-cut.txt" ]]; then
            sed 's/^/   /' "$tmp/verify-cut.txt"
        else
            sed 's/^/   /' "$tmp/verify.txt"
        fi
        if [[ $vf_st -ne 0 ]]; then failed=$((failed + 1)); fi
        # ⚠️ 3 is NOT RUN, not a failing document. Counting it as a failure
        # would say the fixture is broken when the machine is.
        render_st=0
        skills/shape/scripts/check-render.sh "$f" || render_st=$?
        case "$render_st" in
            0) ;;
            3) not_run=$((not_run + 1)) ;;
            *) failed=$((failed + 1)) ;;
        esac
    done
    echo
    echo "${#files[@]} fixture(s), $failed failure(s), $not_run not run"
    if [[ $not_run -gt 0 ]]; then
        echo "🛑 $not_run check(s) did not run — this is not a clean corpus report" >&2
    fi
    exit $(( failed > 0 || not_run > 0 ))

# Lint every markdown file in the repo.
lint:
    markdownlint '**/*.md' --ignore node_modules

# Census + F12 metrics + the access checks for one document. Report-only.
#
# Every script status is read in its own statement. Piping a check into `jq` or
# `sed` reads the *formatter's* status, so a check that exited 4 — did not run
# — printed nothing and read as a clean document.
profile FILE:
    #!/usr/bin/env bash
    set -uo pipefail
    S=skills/shape/scripts
    tmp="${TMPDIR:-/tmp}/shape-profile-$$"
    mkdir -p "$tmp"
    trap 'rm -rf "$tmp"' EXIT

    st=0; "$S/census.sh" "{{FILE}}" > "$tmp/blocks.json" || st=$?
    if [[ $st -ne 0 ]]; then
        echo "🛑 census exited $st — nothing downstream can be trusted" >&2
        exit "$st"
    fi
    echo "── census"
    jq -r '.blocks | group_by(.type) | map("   \(.[0].type): \(length)") | .[]' "$tmp/blocks.json"

    echo "── F12 (unvalidated — see references/calibration.md)"
    st=0; "$S/metrics.sh" "$tmp/blocks.json" > "$tmp/metrics.json" || st=$?
    if [[ $st -ne 0 ]]; then
        echo "   🛑 metrics NOT RUN (exit $st)"
    else
        jq -r '.metrics | to_entries[] | "   \(.key): \(.value.value)"' "$tmp/metrics.json"
    fi

    echo "── access"
    worst=0
    run_check() {
        local name="$1"; shift
        local out="$tmp/$name.txt" cst=0
        "$@" > "$out" 2>&1 || cst=$?
        sed 's/^/   /' "$out"
        case "$cst" in
            0) ;;
            1) [[ $worst -lt 1 ]] && worst=1 ;;
            *) echo "   🛑 $name NOT RUN (exit $cst)"; worst=4 ;;
        esac
    }
    for c in heading-scent contents-present section-length; do
        run_check "$c" "$S/access/$c.sh" "$tmp/blocks.json"
    done
    for c in prose-list prose-restates-table table-misfit; do
        run_check "$c" "$S/access/$c.sh" "$tmp/blocks.json" "{{FILE}}"
    done
    exit "$worst"
