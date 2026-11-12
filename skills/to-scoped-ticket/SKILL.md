---
name: to-scoped-ticket
description: Turn one scoped task, usually an Asana task from another project, into a single ticket for the agent workflow orchestrator without writing a spec first. It asks only what the ticket template still needs, generates a short spec and a one-ticket plan, and after the user confirms, creates the parent spec task and the ticket in Asana through the Asana MCP. It stops and points to /to-spec and /to-tickets when the task is not scoped.
disable-model-invocation: true
---

Turn one scoped task into one ticket that the agent workflow orchestrator can run, without asking the user to write a spec. The orchestrator needs a parent spec task with an Initiative and a ticket that follows the ticket template, so this skill produces both: a short spec that carries the context, and a ticket that carries what to build. Nothing reaches Asana until the user confirms.

This is the one-ticket path next to `/to-tickets`. It reuses that skill's size criteria and its Asana creation step by reference, in `~/.dotfiles/skills/to-tickets/SKILL.md`: read them there instead of reconstructing them, so that a fix in `/to-tickets` reaches this skill too.

## 1. Locate the orchestrator, the checkout, and the inputs

- The orchestrator is `~/Documents/agent-workflow`, and the commands run as `~/Documents/agent-workflow/bin/agent-workflow-tickets <check|render|status> <plan>`. If `config.json` does not exist there, stop and tell the user to run `npm run setup:asana` in that directory. Read `config.json`, and never write it.
- The ticket template is `~/Documents/agent-workflow/templates/ticket.md`, the same for every repository.
- Run from a checkout of the repository the ticket targets, because the Starting point comes from its code. The primary checkout is the first `worktree` line of `git worktree list --porcelain`. If the current directory is not in a Git repository, stop and ask the user to run the skill from the target repository.
- The repository is the key of `repositories` in `config.json` that matches, ignoring case, the name of `git remote get-url origin`, its last path component without `.git`, and you write it as the key spells it. Do not compare paths: the path of `agent-workflow` there is the agents' clone, not the developer's checkout. If no key matches, stop and say that the orchestrator cannot run tickets of this repository.
- The source task is the Asana URL or gid that the user passes. Read its name, description, and comments with the Asana MCP. It is only material to start from: never write to it, move it, or link to it.
- If the conversation already holds a grill-me or a discussion of this task, its answers count as given. Ask only what they leave open.

## 2. Ask the Initiative and the Repository

Ask with the AskUserQuestion tool, in one call, before anything else:

- **Initiative**, which becomes the branch prefix and goes on the parent task. It follows the team's branch naming guide: a short kebab-case name of the project, such as `ai` or `multi-content`. Propose first the one that fits best among the `initiative` values of the plans in `<primary>/.agents/tickets/*.json` and a name derived from the source task's project.
- **Repository**, with the one from step 1 as the first option.

## 3. Grill for the ticket

Read the template, the source task, and the code the task touches. Then build the ticket section by section, and ask the user only what the source task, the conversation, and the code do not answer. Ask one question at a time, each with your recommended answer. When the code can answer a question, read the code instead of asking.

- **Goal**: one or two sentences on the behavior and why it matters.
- **Scope**: an `**Includes:**` line and an `**Excludes:**` line.
- **Acceptance criteria**: one observable behavior per bullet, each one verifiable by a test.
- **Verification**: how a reviewer checks the result end to end. Do not say here whether the ticket needs automated tests.
- **Automated tests**: `Required` by default, without asking. Ask only when the task is of a kind that usually has nothing to test, such as copy, i18n, configuration, or a purely visual change. Write `Not required: <reason>` only when the user rules tests out, with the user's reason.
- **Starting point**: the files, modules, and patterns to start from, which you find in the code.

Name the ticket as a short task description, because the orchestrator builds the branch name from it.

Collect for the spec, as you go:

- **Context**: the problem and why it matters, from the source task and the answers.
- **Decisions**: design choices that are not acceptance criteria, such as which existing endpoint to reuse or which obvious alternative was discarded and why.

## 4. Stop when the task is not scoped

Apply the **Small** and **Self-contained** criteria of step 3 of `/to-tickets`. As soon as the task clearly exceeds them, for example because it needs more than six acceptance criteria, more than about 15 files, more than one agent session of an hour, or a split into slices, stop asking. Write what the grill produced so far to `<primary>/.agents/specs/scoped/<slug>.draft.md`, write nothing to Asana, and tell the user to run `/to-spec` and then `/to-tickets`. Do not split the task into several tickets yourself.

## 5. Write the spec and the plan

`<slug>` is the ticket name in kebab-case.

The spec is `<primary>/.agents/specs/scoped/<slug>.md`:

```markdown
---
repository: <repository>
---

# <title>

## Context

<the problem and why it matters>

Source task: <Asana URL of the source task>

## Decisions

<one bullet per decision>

## Testing Decisions

<why automated tests are not required>
```

- The title becomes the parent task's name. Use the ticket name unless the user prefers another.
- Leave out `## Decisions` when there are none. Write `## Testing Decisions` only when the ticket says `Not required`, with the same reason, so that the spec and the ticket agree.
- Never repeat a requirement of the ticket in the spec. The agent and the review read both, and a requirement written twice can contradict itself. The spec says why, and the ticket says what.

The plan is `<primary>/.agents/tickets/scoped-<slug>.json`. If it already exists, follow the rules of step 1 of `/to-tickets` for an existing plan before anything else, because an earlier run may have created tasks in Asana already.

```json
{
	"spec": "/Users/<user>/<checkout>/.agents/specs/scoped/<slug>.md",
	"name": "<title>",
	"initiative": "<initiative>",
	"parentGid": null,
	"tickets": [
		{
			"key": "T1",
			"name": "<ticket name>",
			"enabling": true,
			"blockedBy": [],
			"gid": null,
			"description": "## Goal\n\n...\n\n## Scope\n\n**Includes:** ...\n\n**Excludes:** ...\n\n## Acceptance criteria\n\n- ...\n\n## Verification\n\n...\n\n## Automated tests\n\nRequired\n\n## Starting point (optional)\n\n..."
		}
	]
}
```

- `spec` is the absolute path with `~` expanded, because the commands resolve a relative path against the Edpuzzle-Web checkout and do not expand `~`.
- The single ticket is always the enabling slice, without blockers, because `check` requires exactly one.

Run `check` on the plan and fix every problem it reports before showing anything. If it reports that the spec or the ticket is larger than Asana accepts, the task is not scoped: go to step 4.

## 6. Confirm

Show the ticket name, the Initiative, the Repository, the full ticket description, and the spec, and mention both file paths. Then ask with the AskUserQuestion tool whether to create the parent task and the ticket in Asana as shown, with the user free to describe adjustments instead. Apply any adjustment to the files, run `check` again, and ask again. Do not create anything in Asana until the user confirms.

## 7. Create the tasks in Asana

Follow step 5 of `/to-tickets` as written there: `render`, then the loop of `status` and the Asana MCP calls until `status` reports that the plan is complete. Its rules apply as they are: copy the payloads without editing the HTML, only create and link tasks, never move the ticket out of `Backlog`, and never touch a task that is not in the plan, which includes the source task.

## 8. Report

Tell the user that the ticket is in `Backlog`, give the links to the parent task and the ticket, and say that moving it to `Ready` starts it. Say that the source task was left as it was.
