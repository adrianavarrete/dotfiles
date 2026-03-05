#!/bin/bash
#
# Play a notification sound for Claude Code hooks.
# Usage: notify-sound.sh [stop|notification]

SOUND_DIR="/System/Library/Sounds"

case "${1:-stop}" in
  stop)
    # Agent finished - play a pleasant completion sound
    afplay "$SOUND_DIR/Glass.aiff" &
    ;;
  notification)
    # Agent needs input - play an attention sound
    afplay "$SOUND_DIR/Blow.aiff" &
    ;;
esac
