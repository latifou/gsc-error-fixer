#!/usr/bin/env bash
# Installe le skill gsc-error-fixer pour tous vos projets Claude Code (~/.claude/skills).
# Usage : ./install.sh            -> installation globale
#         ./install.sh /chemin/projet -> installation dans un seul projet
set -euo pipefail
SRC="$(cd "$(dirname "$0")" && pwd)/.claude/skills/gsc-error-fixer"
DEST="${1:-$HOME}/.claude/skills/gsc-error-fixer"
mkdir -p "$DEST"
cp -R "$SRC/." "$DEST/"
echo "Skill installé dans $DEST"
