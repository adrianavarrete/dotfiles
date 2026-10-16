---
name: to-tickets
description: Split a spec from `.agents/specs` into vertical-slice tickets for the agent workflow orchestrator, and after the user confirms them, create the parent spec task, its subtasks in Backlog, and their "blocked by" links in Asana through the Asana MCP. Rerunning it on the same spec resumes a creation that failed halfway without duplicating tickets.
disable-model-invocation: true
---

Turn a spec into tickets that the agent workflow orchestrator can run. Each ticket is implemented by one agent session of at most an hour that sees only the spec and the ticket, and becomes one PR that the user reviews in one sitting. Nothing reaches Asana until the user confirms the proposal.

The orchestrator's ticket plan commands do the deterministic work: they check the plan against the shared ticket template, render the Asana descriptions, and compare the plan with what Asana already holds. Use their output instead of judging these things yourself.

## 1. Locate the orchestrator and the plan

- The primary checkout is the first `worktree` line of `git worktree list --porcelain`. The orchestrator is `<primary>/.agents/agent-workflow`, and the commands run as `<primary>/.agents/agent-workflow/bin/agent-workflow-tickets <check|render|status> <plan>`. If `config.json` does not exist there, stop and tell the user to run `npm run setup:asana` in that directory.
- The spec is the file the user names, or one they pick from `.agents/specs`. Its path in the plan is relative to the primary checkout, such as `.agents/specs/archive-classes.md`. If the spec exists only in the current worktree, copy it to the same path in the primary checkout first, because the parent task is rendered from there.
- The plan is `<primary>/.agents/tickets/<spec file name>.json`. If it already exists, run `status` on it before anything else:
  - If `status` found the parent task or any ticket in Asana, the user already confirmed this plan in an earlier run. Show what is left, ask once whether to finish it, and go to step 5. Do not propose new tickets, because different names would duplicate the ones that exist.
  - Otherwise the plan is an unconfirmed draft. Ask whether to start from it or propose again.

## 2. Read the spec and the code

Read the whole spec, the ticket template at `<primary>/.agents/templates/ticket.md`, and the code the spec touches, so that each ticket can name its real starting point. Read `check-architecture` when the spec changes a module's public API, a command, query, or event, an OpenAPI schema, or the frontend data layer, because those boundaries decide where a slice can be cut.

## 3. Propose the tickets

Split the spec into vertical slices:

- **Vertical.** Each ticket delivers working behavior through every layer it needs, such as schema, use case, endpoint, and UI, and can be verified end to end on its own. A ticket that touches both frontend and backend is fine: its PR uses the `(Web - FS)` prefix. Do not split by layer.
- **Small.** One agent session implements it test-first in under an hour, with one commit per acceptance criterion, and the user can review the PR in one sitting. Three to six acceptance criteria is a good size. Split anything larger.
- **Self-contained.** The agent sees only the spec and the ticket. Name the files, modules, and patterns to start from in Starting point, and say in Scope which work belongs to other tickets, by their name.
- **Enabling slice.** Identify the first slice that opens the path for the rest, usually the thinnest end-to-end path, and mark it as the enabling slice. Exactly one ticket is the enabling slice, and it has no blockers.
- **Dependencies.** A ticket is blocked by another only when it builds on that ticket's code. The orchestrator starts a ticket only when every blocker is done, so a dependency that is not needed only delays the work. Tickets that do not depend on each other run in parallel.

Write each ticket in the template's sections, as Markdown with `##` headings:

- **Goal**: one or two sentences on the behavior and why it matters.
- **Scope**: an `**Includes:**` line and an `**Excludes:**` line.
- **Acceptance criteria**: one observable behavior per bullet, each one verifiable by a test.
- **Verification**: how a reviewer checks the result end to end.
- **Starting point** (optional): the files and patterns to start from.

Name each ticket as a short task description, because the orchestrator builds the branch name from it. Propose an Initiative for the branch prefix, following the team's branch naming guide: a short kebab-case name of the project, such as `ai` or `multi-content`. Reuse the Initiative the spec or the user already named.

Write the plan file:

```json
{
	"spec": ".agents/specs/archive-classes.md",
	"name": "Archive classes",
	"initiative": "classes",
	"parentGid": null,
	"tickets": [
		{
			"key": "T1",
			"name": "Archive one class from the class list",
			"enabling": true,
			"blockedBy": [],
			"gid": null,
			"description": "## Goal\n\n...\n\n## Scope\n\n**Includes:** ...\n\n**Excludes:** ...\n\n## Acceptance criteria\n\n- ...\n\n## Verification\n\n...\n\n## Starting point (optional)\n\n..."
		}
	]
}
```

`name` is the spec's title, which becomes the parent task's name. Run `check` on the plan and fix every problem it reports before showing the proposal. If it reports that the spec is larger than Asana accepts, do not shorten the spec yourself: tell the user how large it is, because the spec is theirs to cut.

## 4. Confirm the proposal

Show the proposal in the conversation: a table with each ticket's key, name, blockers, and whether it is the enabling slice, followed by each ticket's Goal and acceptance criteria. Mention the plan file for the full text.

Then ask with the AskUserQuestion tool, in one call:

- Whether to create the tickets in Asana as proposed, with the user free to describe adjustments instead.
- Which Initiative to use, with your proposal as the first option.

Apply any adjustment to the plan file, run `check` again, and ask again. Do not create anything in Asana until the user confirms.

## 5. Create the tickets in Asana

Run `render` on the plan. It writes `<plan>.asana.json` with the project ID, the section IDs, the `html_notes`, and the custom field values for the parent and for each ticket. Copy those values as they are. Do not write or edit the HTML yourself, because the orchestrator validates the tickets from that HTML.

Then repeat this loop until `status` reports that the plan is complete:

1. Run `status` on the plan. It finds what already exists in Asana, by the gids in the plan or by exact name, records the gids in the plan, and lists what is left in the order it can be done.
2. Do what it lists, with the Asana MCP tools:
   - **Parent task**: `create_tasks` with `project_id`, the `section_id` of Specs, the `name`, the `html_notes`, and the `custom_fields` from the parent payload. `create_tasks` takes `custom_fields` as a JSON string.
   - **Subtasks**: one `create_tasks` call for every missing ticket, each with `parent` set to the parent task's gid, `project_id`, the `section_id` of Backlog, and the ticket's `name`, `html_notes`, and `custom_fields`.
   - **Project membership, fields, parent, and dependencies**: `update_tasks`, with `add_projects` (the project and the Backlog section), `custom_fields`, `parent`, or `add_dependencies` (the gids of the blockers), as each item says.
   - **A description that fails the TicketValidator**: rewrite it with `update_tasks` and the ticket's `html_notes` from the payload, but only while the ticket is still in Backlog. Otherwise ask the user, because someone may have edited it.
   - **Several tasks with the same name**: stop and ask the user which one to keep. Never pick one yourself.
3. Run `status` again.

A call that fails or that only partly succeeds needs no special handling: the next `status` shows what is still missing. If the same item stays on the list after two attempts, stop and report the error that Asana returned.

Only create and link tasks. Do not move tickets out of Backlog, comment on tasks, or touch tasks that are not in the plan, because the orchestrator is the only other component that writes to this project, and moving a ticket to `Ready` is the user's approval.

## 6. Report

Tell the user that the tickets are in Backlog, give the link to the parent task, and name the enabling slice, which is the ticket to move to `Ready` first.
