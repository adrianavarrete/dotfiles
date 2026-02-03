#!/bin/sh

# Install starship if not present
if ! command -v starship &> /dev/null; then
    echo "Installing starship..."
    brew install starship
fi

# Symlink config
mkdir -p ~/.config
ln -sf ~/.dotfiles/starship/starship.toml ~/.config/starship.toml

echo "Starship installed and configured."
echo "Add 'eval \"\$(starship init zsh)\"' to your .zshrc if not already present."