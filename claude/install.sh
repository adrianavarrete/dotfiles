#!/bin/bash
#
# Claude Code configuration setup
# Symlinks the statusline script and provides a template for settings

DOTFILES_CLAUDE="$HOME/.dotfiles/claude"
CLAUDE_DIR="$HOME/.claude"

# Create ~/.claude directory if it doesn't exist
mkdir -p "$CLAUDE_DIR"
mkdir -p "$CLAUDE_DIR/commands"

# Symlink the statusline script
# Remove existing file/symlink first to ensure clean state
if [ -e "$CLAUDE_DIR/statusline.sh" ] || [ -L "$CLAUDE_DIR/statusline.sh" ]; then
  rm "$CLAUDE_DIR/statusline.sh"
fi
ln -s "$DOTFILES_CLAUDE/statusline.sh" "$CLAUDE_DIR/statusline.sh"
chmod +x "$DOTFILES_CLAUDE/statusline.sh"

echo "  Linked statusline.sh"

# Symlink command files
if [ -d "$DOTFILES_CLAUDE/commands" ]; then
  for cmd_file in "$DOTFILES_CLAUDE/commands"/*.md; do
    if [ -f "$cmd_file" ]; then
      cmd_name=$(basename "$cmd_file")
      target="$CLAUDE_DIR/commands/$cmd_name"

      # Remove existing file/symlink
      if [ -e "$target" ] || [ -L "$target" ]; then
        rm "$target"
      fi

      ln -s "$cmd_file" "$target"
      echo "  Linked command: /$(basename "$cmd_name" .md)"
    fi
  done
fi

# If settings.json doesn't exist, copy the template
if [ ! -f "$CLAUDE_DIR/settings.json" ]; then
  cp "$DOTFILES_CLAUDE/settings.json.example" "$CLAUDE_DIR/settings.json"
  echo "  Created settings.json from template"
  echo "  → You may want to add your AWS profile and other machine-specific settings"
else
  echo "  settings.json already exists (not modified)"
  echo "  → Ensure it has statusLine.command set to ~/.claude/statusline.sh"
fi