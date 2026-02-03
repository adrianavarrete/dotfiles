#!/bin/bash
# Setup SSH key for GitHub
# Usage: ./setup-github.sh [email]

set -e

SSH_DIR="$HOME/.ssh"
SSH_KEY="$SSH_DIR/github"
EMAIL="${1:-}"

# Prompt for email if not provided
if [ -z "$EMAIL" ]; then
    read -p "Enter your GitHub email: " EMAIL
fi

if [ -z "$EMAIL" ]; then
    echo "Error: Email is required"
    exit 1
fi

# Create .ssh directory if it doesn't exist
mkdir -p "$SSH_DIR"
chmod 700 "$SSH_DIR"

# Generate key if it doesn't exist
if [ ! -f "$SSH_KEY" ]; then
    echo "Generating new SSH key..."
    ssh-keygen -t ed25519 -C "$EMAIL" -f "$SSH_KEY" -N ""
    echo "SSH key generated at $SSH_KEY"
else
    echo "SSH key already exists at $SSH_KEY"
fi

# Start ssh-agent and add key
eval "$(ssh-agent -s)"
ssh-add --apple-use-keychain "$SSH_KEY" 2>/dev/null || ssh-add "$SSH_KEY"

# Configure SSH config for GitHub (if not already configured)
SSH_CONFIG="$SSH_DIR/config"
if ! grep -q "Host github.com" "$SSH_CONFIG" 2>/dev/null; then
    echo "Adding GitHub configuration to SSH config..."
    cat >> "$SSH_CONFIG" <<EOF

# GitHub
Host github.com
    HostName github.com
    User git
    IdentityFile $SSH_KEY
    AddKeysToAgent yes
    UseKeychain yes
EOF
    chmod 600 "$SSH_CONFIG"
    echo "SSH config updated"
else
    echo "GitHub already configured in SSH config"
fi

# Copy public key to clipboard (macOS)
if command -v pbcopy &>/dev/null; then
    pbcopy < "${SSH_KEY}.pub"
    echo ""
    echo "Public key copied to clipboard!"
fi

echo ""
echo "Next step: Add the public key to GitHub"
echo "  1. Go to: https://github.com/settings/ssh/new"
echo "  2. Paste the key and save"
echo ""
echo "Your public key:"
cat "${SSH_KEY}.pub"
