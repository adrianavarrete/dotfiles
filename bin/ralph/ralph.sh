# ralph.sh
# Usage: ./ralph.sh <iterations>

set -e

if [ -z "$1" ]; then
  echo "Usage: $0 <iterations>"
  exit 1
fi

# For each iteration, run Claude Code with the following prompt.
# This prompt is basic, we'll expand it later.
for ((i=1; i<=$1; i++)); do
  result=$(claude --permission-mode acceptEdits  "$PWD/.agents/plans/prd.json $PWD/.agents/plans/progress.txt \
1. Decide which task to work on next. \
This should be the one YOU decide has the highest priority, \
- not necessarily the first in the list. \
2. One task is one PRD item. Work ONLY on that PRD item. \
3. Check any feedback loops, such as types and tests. \
4. Append your progress to the progress.txt file. \
5. Append in the pdr.json file the work that was done. \
6. Make a git commit of that task. \
ONLY WORK ON A SINGLE TASK. \
If, while implementing the task, you notice that the PRD is complete, \
output <promise>COMPLETE</promise>." 2>&1 | tee /dev/tty)

  if [[ "$result" == *"<promise>COMPLETE</promise>"* ]]; then
    echo "PRD complete, exiting."
    exit 0
  fi
done


