#!/bin/bash

# Global Claude Code Provider Switcher
# Works from any directory - finds .claude/settings.local.json in current or parent dirs
# Add this to your dotfiles (e.g., ~/bin/ or ~/.local/bin/)

find_settings_file() {
    local dir="$PWD"
    while [[ "$dir" != "/" ]]; do
        if [[ -d "$dir/.claude" ]]; then
            echo "$dir/.claude/settings.local.json"
            return 0
        fi
        dir=$(dirname "$dir")
    done
    return 1
}

show_current() {
    local settings_file=$(find_settings_file)
    if [[ -z "$settings_file" ]]; then
        echo "Not in a Claude Code project"
        return 1
    fi

    echo "Project: $(dirname $(dirname "$settings_file"))"
    if [[ -f "$settings_file" ]]; then
        if grep -q '"CLAUDE_CODE_USE_BEDROCK".*"1"' "$settings_file"; then
            echo "Provider: AWS Bedrock ☁️"
        else
            echo "Provider: Claude Pro Subscription 🚀"
        fi
    else
        echo "Provider: Claude Pro Subscription 🚀 (default)"
    fi
}

switch_to_bedrock() {
    local settings_file=$(find_settings_file)
    if [[ -z "$settings_file" ]]; then
        echo "❌ Not in a Claude Code project (.claude/ directory not found)"
        exit 1
    fi

    echo "→ Switching to AWS Bedrock..."

    # Check AWS credentials
    if ! aws sts get-caller-identity &>/dev/null; then
        echo ""
        echo "⚠️  AWS credentials not found or expired."
        echo "   Run: aws sso login --profile <your-profile>"
        echo ""
        exit 1
    fi

    # Read existing settings or create empty object
    if [[ -f "$settings_file" ]]; then
        settings=$(cat "$settings_file")
    else
        settings="{}"
        mkdir -p "$(dirname "$settings_file")"
    fi

    # Merge Bedrock config
    new_settings=$(echo "$settings" | jq '. + {
        "env": (.env // {} | . + {
            "CLAUDE_CODE_USE_BEDROCK": "1",
            "AWS_REGION": "us-east-1",
            "CLAUDE_CODE_MAX_OUTPUT_TOKENS": "4096",
            "MAX_THINKING_TOKENS": "1024",
            "ANTHROPIC_DEFAULT_HAIKU_MODEL": "us.anthropic.claude-haiku-4-5-20251001-v1:0"
        })
    }')

    echo "$new_settings" > "$settings_file"

    echo "✓ Now using AWS Bedrock"
    echo "✓ Restart Claude Code instances to apply"
}

switch_to_subscription() {
    local settings_file=$(find_settings_file)
    if [[ -z "$settings_file" ]]; then
        echo "❌ Not in a Claude Code project (.claude/ directory not found)"
        exit 1
    fi

    echo "→ Switching to Claude Pro Subscription..."

    # Read existing settings or create empty object
    if [[ -f "$settings_file" ]]; then
        settings=$(cat "$settings_file")
    else
        settings="{}"
        mkdir -p "$(dirname "$settings_file")"
    fi

    # Remove Bedrock-specific env vars
    new_settings=$(echo "$settings" | jq 'del(.env.CLAUDE_CODE_USE_BEDROCK, .env.AWS_REGION, .env.ANTHROPIC_DEFAULT_HAIKU_MODEL)')

    echo "$new_settings" > "$settings_file"

    echo "✓ Now using Claude Pro Subscription"
    echo "✓ Restart Claude Code instances to apply"
}

# Parse command
case "${1:-status}" in
    bedrock|b)
        switch_to_bedrock
        ;;
    subscription|sub|s)
        switch_to_subscription
        ;;
    status|st|"")
        show_current
        ;;
    help|h|--help|-h)
        echo "Usage: $(basename "$0") [command]"
        echo ""
        echo "Commands:"
        echo "  bedrock, b         Switch to AWS Bedrock"
        echo "  subscription, s    Switch to Claude Pro Subscription"
        echo "  status (default)   Show current provider"
        echo "  help               Show this help"
        echo ""
        echo "Examples:"
        echo "  $(basename "$0")              # Show current provider"
        echo "  $(basename "$0") bedrock      # Switch to Bedrock"
        echo "  $(basename "$0") s            # Switch to subscription"
        ;;
    *)
        echo "❌ Unknown command: $1"
        echo "Run '$(basename "$0") help' for usage"
        exit 1
        ;;
esac