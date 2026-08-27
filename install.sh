#!/usr/bin/env bash
# shape — install the skill into ~/.claude/skills/
#
# Usage:
#   ./install.sh           # symlink (recommended — edits propagate)
#   ./install.sh --copy    # copy instead of symlink
#
# After install, use `/shape` in Claude Code.

set -euo pipefail

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# The skill lives at skills/shape/ (class-A layout); link that dir so
# ~/.claude/skills/shape/SKILL.md resolves for discovery.
SKILL_SRC="$REPO_DIR/skills/shape"
TARGET_DIR="$HOME/.claude/skills"
TARGET="$TARGET_DIR/shape"

if [[ ! -f "$SKILL_SRC/SKILL.md" ]]; then
  echo "❌ Expected $SKILL_SRC/SKILL.md — is the repo layout intact?" >&2
  exit 1
fi

mkdir -p "$TARGET_DIR"

if [[ "${1:-}" == "--copy" ]]; then
  rm -rf "$TARGET"
  cp -R "$SKILL_SRC" "$TARGET"
  echo "✅ Skill copied to: $TARGET"
else
  ln -sfn "$SKILL_SRC" "$TARGET"
  echo "✅ Skill linked: $TARGET → $SKILL_SRC"
fi

echo
echo "Next (optional): drop a .shape.toml at your project root — see"
echo "skills/shape/templates/shape-config.toml. Then type /shape <file>."
echo "First contact with an unknown document runs in diagnose mode."
