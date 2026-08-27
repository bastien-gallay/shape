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
    files=(fixtures/*.md)
    if [[ ${#files[@]} -eq 0 ]]; then
        echo "no fixtures yet — see fixtures/README.md" >&2
        exit 0
    fi
    tmp="${TMPDIR:-/tmp}/shape-fixtures-$$"
    mkdir -p "$tmp"
    trap 'rm -rf "$tmp"' EXIT
    failed=0
    for f in "${files[@]}"; do
        echo "── $f"
        if ! skills/shape/scripts/extract-facts.sh "$f" > "$tmp/facts.json"; then
            echo "   ⚠️  no fact candidates — skipped"
            continue
        fi
        skills/shape/scripts/verify-facts.sh "$tmp/facts.json" "$f" | tail -1
        if [[ ${PIPESTATUS[0]} -ne 0 ]]; then failed=$((failed + 1)); fi
        skills/shape/scripts/check-render.sh "$f" || failed=$((failed + 1))
    done
    echo
    echo "${#files[@]} fixture(s), $failed failure(s)"
    exit $(( failed > 0 ))

# Lint every markdown file in the repo.
lint:
    markdownlint '**/*.md' --ignore node_modules
