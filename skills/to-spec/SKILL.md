---
name: to-spec
description: Create a spec by synthesizing the current conversation and codebase understanding, without interviewing the user, and writing the result to `.agents/specs/`.
---

This skill will be invoked when the user wants to create a spec. Do NOT interview the user; synthesize what you already know from the conversation and the codebase. Go through the steps below. You may skip steps if you don't consider them necessary.

1. Gather the problem, the proposed solution, and the decisions already made from the current conversation.

2. Explore the repo, if you haven't already, to verify those assertions and understand the current state of the codebase.

3. Sketch out the major modules you will need to build or modify to complete the implementation. Actively look for opportunities to extract deep modules that can be tested in isolation.

A deep module (as opposed to a shallow module) is one which encapsulates a lot of functionality in a simple, testable interface which rarely changes.

Check with the user, in a single message, that these modules match their expectations and which modules they want tests written for. This is the only question you should ask.

4. Write the spec using the template below. Where the conversation and the codebase leave a decision open, do not ask about it; record it as an open question in Further Notes. The spec should be stored in the `.agents/specs` directory, and should be named after the feature you are building. For example, if you are building a feature called "Add balance to mobile banking app", the spec should be stored in .agents/specs/add-balance-to-mobile-banking-app.md.

<spec-template>

## Problem Statement

The problem that the user is facing, from the user's perspective.

## Solution

The solution to the problem, from the user's perspective.

## User Stories

A LONG, numbered list of user stories. Each user story should be in the format of:

1. As an <actor>, I want a <feature>, so that <benefit>

<user-story-example>
1. As a mobile bank customer, I want to see balance on my accounts, so that I can make better informed decisions about my spending
</user-story-example>

This list of user stories should be extremely extensive and cover all aspects of the feature.

## Implementation Decisions

A list of implementation decisions that were made. This can include:

- The modules that will be built/modified
- The interfaces of those modules that will be modified
- Technical clarifications from the developer
- Architectural decisions
- Schema changes
- API contracts
- Specific interactions

Do NOT include specific file paths or code snippets. They may end up being outdated very quickly.

## Testing Decisions

A list of testing decisions that were made. Include:

- A description of what makes a good test (only test external behavior, not implementation details)
- Which modules will be tested
- Prior art for the tests (i.e. similar types of tests in the codebase)

## Out of Scope

A description of the things that are out of scope for this spec.

## Further Notes

Any further notes about the feature.

</spec-template>
