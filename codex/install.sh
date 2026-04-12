#!/usr/bin/env sh
#
# Codex configuration setup
# Symlinks shared and Codex-specific skills

set -eu

DOTFILES_ROOT="$HOME/.dotfiles"
DOTFILES_CODEX="$DOTFILES_ROOT/codex"
CODEX_DIR="$HOME/.codex"

mkdir -p "$CODEX_DIR"
mkdir -p "$CODEX_DIR/skills"

sh "$DOTFILES_ROOT/scripts/link-skills.sh" \
  "Codex" \
  "$CODEX_DIR/skills" \
  "$DOTFILES_ROOT/skills" \
  "$DOTFILES_CODEX/skills"
