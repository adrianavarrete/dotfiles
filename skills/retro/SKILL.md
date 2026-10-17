---
name: retro
description: "Conduct a retrospective on a coding session, or on a spec that the agent workflow orchestrator ran."
disable-model-invocation: true
---

The user has asked for a **retrospective**. You are suggesting improvements to the coding agent's **environment** to improve future runs.

There are two kinds of retrospective:

- **Spec**: the user names a spec that the agent workflow orchestrator ran, as a file in `.agents/specs`, its Asana task (URL or gid), or its name. Follow [Spec retrospective](#spec-retrospective).
- **Session**: anything else, including no argument. Follow [Session retrospective](#session-retrospective).

## Session retrospective

1. If the `writing-for-agents` skill is available, call the Skill tool with it for the writing style guide.

2. Read the primary sources for the session the user specifies. This may mean searching through session logs on this machine. If the user doesn't specify a session, default to the current one.

3. Look for candidates for improvement in the [categories](#categories).

4. Present these candidates to the user, in order of severity.

## Spec retrospective

A spec retrospective finds patterns across the tickets of a spec, not in a single session. It only proposes changes. Do not edit any file, and do not write to Asana or GitHub: the user decides what changes for future runs.

1. **Locate the orchestrator.** The primary checkout is the first `worktree` line of `git worktree list --porcelain`, and the orchestrator is `<primary>/.agents/agent-workflow`. Its run record commands run as `<primary>/.agents/agent-workflow/bin/agent-workflow-runs <list|export>`. If `config.json` does not exist there, stop and tell the user that the orchestrator is not set up.

2. **Find the spec task.** `agent-workflow-runs export` takes the spec task's gid, its Asana URL, or part of its name. For a file in `.agents/specs`, the ticket plan `<primary>/.agents/tickets/<spec file name>.json` that `/to-tickets` wrote holds the task's gid in `parentGid`. When unsure, run `agent-workflow-runs list`, which shows the specs with run records.

3. **Export the records.** Run `agent-workflow-runs export <spec>`. It writes one Markdown file, whose path it prints, with each ticket of the spec: its section, one entry per phase that ran, and its Asana comments, oldest first. This file in the orchestrator's `state` folder is the only file a retrospective writes. Each phase entry has the model, the outcome, the duration, the tokens, the approximate change in plan usage, the failed attempts, and a table of its session calls with their denied actions. The Triage entry also lists every review finding with its classification and whether Refactor fixed it. Read the whole file, in parts if it is long.

   - If tickets of the spec are not in `Done`, say so before going on, because the patterns of an unfinished spec may change.
   - The plan usage percentages cover the whole account, including the user's own sessions, so treat them as a rough comparison between phases, not as a cost.

4. **Read the evidence behind a pattern.** The orchestrator's comments, which start with 🤖, name the session IDs of each phase. When a pattern needs more than the records and comments, read the transcript of a session with `find ~/.claude/projects -name '<session ID>.jsonl'`. Read only the sessions that support a pattern, such as a failed attempt, a denied action, or a phase that used far more turns than the same phase of other tickets.

5. **Find patterns across tickets.** A pattern is something that happened in more than one ticket, or once with a high cost. Look for:

   - **Failures and retries**: the phases that failed or needed their retry, and whether the same cause repeats, such as a lint error, a missing test command, or a timeout of the same phase.
   - **Denied actions**: the same kind of action denied by the same layer in several sessions, which means that an instruction sends agents to an action they cannot take.
   - **Review findings**: defects that Review keeps finding after Standards ran, which Standards or a check should catch earlier; spec deviations, which mean Implement missed an acceptance criterion; and findings that Triage did not confirm, which mean the review reports noise.
   - **Stops**: spec contradictions, `Needs human`, cut sessions, and CI corrections, and what the ticket or the spec lacked.
   - **The user's comments**: `/agent` requests and copied GitHub comments that ask for the same kind of change in several tickets.
   - **Cost**: phases whose turns, duration, tokens, or test lock waits stand out against the same phase of the other tickets.

6. **Propose changes.** Propose only changes to:

   - **Skills**: such as `/to-tickets`, `review-change`, or `create-pr`.
   - **Coding standards**: the files that the Standards phase and the review read.
   - **Automated checks**: lint rules, tests, hooks, or CI jobs. Prefer a check to a rule whenever the violation is mechanical, as [Coding standards](#categories) explains.
   - **Instructions**: `AGENTS.md` or `CLAUDE.md` files, the ticket template, and the orchestrator's phase prompts.

   When the evidence points somewhere else, such as a phase limit or a model in the orchestrator's configuration, mention it in one line as an observation, not as a proposal.

7. **Report.** Present the proposals in order of severity. For each one, give the file to change, the change itself, the evidence (the tickets, the phases, and the session or comment IDs), and what it should prevent in future runs. End with the patterns you checked and found nothing for, in one line each.

## Categories

- **Navigation**: how easy was it for the agent to find the right files? Are there hidden dependencies between files? Would a **navigation pointer** make it easier? _Use when_ the session took a long time to find a piece of information.
- **Automated checks**: are there automated checks that could catch errors the agent made? Linting, typing, tests, filesystem linters? Read the repo's own check command first (its `package.json`/build-tool `lint`/`check` scripts, its CI workflow), so a check that already exists but sits unwired or silently broken is the finding, not a reinvention. A repo with no **guardrail** (no pre-commit hook and no CI job running its lint/typecheck/test command) is itself a finding: an un-linted repo is a standing missed opportunity, not a neutral default. _Use when_ the agent made a mistake an automated check could have caught, or the repo has no guardrail at all.
- **Coding standards**: should the **reviewer agent** be given a new rule to enforce? Should an existing rule be removed or clarified? Classify the violation first: a **mechanical** one (a fixed syntactic pattern, a banned API, an import shape, a file-location rule) gets a deterministic check, full stop: a custom rule in the repo's own linter, a new pre-commit hook, or a new CI job, whichever the repo's language and existing guardrail make cheapest. Default to building the check over writing the rule. Reserve `CODING_STANDARDS.md` for genuine **judgement calls** (cross-file consistency, "matches the surrounding style," anything no guardrail could ever substitute for). _Use when_ the reviewer agent failed to catch a mistake.
- **Global AGENTS.md**: are there any steering instructions that should be moved to coding standards (or automated checks) instead? _Use when_ the AGENTS.md file is particularly large - in the repo OR the user's global scope.
- **Tool economy**: did the agent make expensive tool calls that could be streamlined? Is there any custom tooling (CLI's, MCP's) that is particularly token-inefficient? _Use when_ the agent made an expensive tool call.
- **No-ops**: look for instructions in steering files that don't modify the agent's behavior. _Use when_ the steering files are large and unwieldy.
- **Information access**: look for opportunities to increase the agent's access to information. Teeing dev server logs, readonly access to third-party services. _Use when_ a crucial piece of information was not available to the agent.

## Reference

### Implementation vs Review

Remember that all work goes through two stages: implementation and review. The implementation agent has the most **context pressure**. They are responsible for exploration, writing code, and debugging failures.

The review agent has the least context pressure - it receives a diff, so no exploration needed. It often does not need to write code or debug.

This means that the review agent should be responsible for imposing coding standards, not the implementation agent.

### Files

You have access to several files in the repo:

- `CLAUDE.md`/`AGENTS.md`: these files are pushed to the context window of any agent working in this repo. They should be used incredibly sparingly, usually only for **navigation pointers** to other files.
- `CODING_STANDARDS.md`: this file is read during review, not implementation. Add **navigation pointers** to docs folders if the standards file gets more than 1,000 lines long.
- Docs: use docs as references files, pointed to by other files. Look for existing docs before writing new ones.
- Skills: use skills for docs (since their description goes into the agent's context window), or for user-invoked commands. Follow the advice in the `writing-for-agents` skill.
