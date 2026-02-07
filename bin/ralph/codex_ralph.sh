#!/bin/bash
# codex_ralph.sh - Multi-iteration development orchestrator using Codex
# Usage: ./codex_ralph.sh <iterations>

set -e

# Validate arguments
if [ -z "$1" ]; then
  echo "Usage: $0 <iterations>"
  exit 1
fi

# Configuration
WORKING_DIR="${PWD}"
PRD_FILE="${WORKING_DIR}/.agents/plans/prd.json"
PROGRESS_FILE="${WORKING_DIR}/.agents/plans/progress.txt"
TEMP_OUTPUT="/tmp/codex_ralph_output_$$.txt"

# Main iteration loop
for ((i=1; i<=$1; i++)); do
  echo "=== Iteration $i of $1 ==="

  # Execute Codex with sandboxed environment
  codex exec \
    --sandbox workspace-write \
    --full-auto \
    -C "${WORKING_DIR}" \
    -o "${TEMP_OUTPUT}" \
    "${PRD_FILE} ${PROGRESS_FILE} \
1. Decide which task to work on next. \
This should be the one YOU decide has the highest priority, \
- not necessarily the first in the list. \
2. Check any feedback loops, such as types and tests. \
3. Append your progress to the progress.txt file. \
4. Append in the prd.json file the work that was done. \
5. Make a git commit of that feature. \
ONLY WORK ON A SINGLE FEATURE. \
If, while implementing the feature, you notice that the PRD is complete, \
output <promise>COMPLETE</promise>. IMPORTANT DO NOT WRITE <promise>COMPLETE</promise> IF PRD IS NOT COMPLETED TO AVOID BREAKING THE LOOP "

  # Display output and check for completion
  if [ -f "${TEMP_OUTPUT}" ]; then
    cat "${TEMP_OUTPUT}"

    if grep -q "<promise>COMPLETE</promise>" "${TEMP_OUTPUT}"; then
      echo "PRD complete, exiting."
      rm -f "${TEMP_OUTPUT}"
      exit 0
    fi
  fi
done

# Cleanup
rm -f "${TEMP_OUTPUT}"
echo "Completed $1 iterations."