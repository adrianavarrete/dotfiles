#!/bin/bash
# ralph_opencode.sh
# Usage: ./ralph_opencode.sh <iterations>

set -e

if [ -z "$1" ]; then
  echo "Usage: $0 <iterations>"
  exit 1
fi

# Export permission settings to allow automatic edits
export OPENCODE_PERMISSION='{
        "bash": {
            "*": "ask",
            "cat *": "allow",
            "tree *": "allow",
            "ls *": "allow",
            "du *": "allow",
            "xargs *": "allow",
            "pnpm --version*": "allow",
            "node --version*": "allow",
            "npm --version": "allow",
            "npm test*": "allow",
            "pnpm type-check": "allow",
            "pnpm install": "allow",
            "pnpm typecheck*": "allow",
            "pnpm test*": "allow",
            "xcrun simctl openurl*": "allow",
            "xcrun simctl io*": "allow",
            "pnpm list*": "allow",
            "gh repo view*": "allow",
            "gh pr list*": "allow",
            "gh issue list*": "allow",
            "git add*": "allow",
            "git commit*": "allow",
            "git log*": "allow",
            "git diff*": "allow",
            "git status*": "allow",
            "tail*": "allow",
            "head*": "allow",
            "mkdir*": "allow",
            "find*": "allow",
            "node*": "deny",
            "pnpm tsc*": "allow"
        },
        "websearch": "allow",
        "webfetch": "ask",
        "skill": "allow"
    }'

# For each iteration, run OpenCode with the following prompt
for ((i=1; i<=$1; i++)); do
  echo "=== Iteration $i of $1 ==="
  
  result=$(opencode run \
    --model github-copilot/claude-sonnet-4.5 \
    "$PWD/.agents/plans/prd.json $PWD/.agents/plans/progress.txt \
1. Decide which task to work on next. \
This should be the one YOU decide has the highest priority, \
- not necessarily the first in the list. \
3. One task is one PRD item. Work ONLY on that PRD item. \
2. Check any feedback loops, such as types and tests. \
3. Append your progress to the progress.txt file. \
4. Append in the pdr.json file the work that was done. \
5. Make a git commit of that task. \
ONLY WORK ON A SINGLE TASK. \
If, while implementing the task, you notice that the PRD is complete, \
output <promise>COMPLETE</promise>." 2>&1 | tee /dev/tty)

  if [[ "$result" == *"<promise>COMPLETE</promise>"* ]]; then
    echo "PRD complete, exiting."
    exit 0
  fi
  
  echo "=== Completed iteration $i ==="
done

echo "All $1 iterations completed."
