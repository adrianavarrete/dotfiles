---
name: architecture-doc
description: Create architectural documentation (RFCs, system design docs, feature design docs, conceptual explanations). Use when the user wants to write, draft, or create documentation about system design, architecture, technical decisions, or new features/initiatives.
---

# Architecture Doc Writer

Helps create architectural documentation following a consistent writing style and structure. Covers four document types: RFCs, system designs, feature designs, and conceptual explanations.

## When to Use

- User wants to create an RFC
- User wants to document a system design or technical architecture
- User wants to write a feature/initiative design document
- User wants to write a conceptual explanation of a system or pattern
- User mentions writing documentation about how something works or should work

## Document Types

| Type                       | Purpose                                             | When to Use                                   |
| -------------------------- | --------------------------------------------------- | --------------------------------------------- |
| **RFC**                    | Technical decision with options and trade-offs      | There's a decision to make between approaches |
| **System Design**          | Deep technical design of a system component         | Designing how a system works internally       |
| **Feature Design**         | Implementation plan for a new feature/initiative    | Planning what to build and how                |
| **Conceptual Explanation** | Educational document explaining how something works | Teaching the team about a system or pattern   |

## Writing Style

**Always read [WRITING_STYLE.md](./WRITING_STYLE.md) before writing.** It contains the full set of rules for voice, tone, structure, formatting, and content.

The key points:

- Problem before solution
- Use "we", be direct, be honest about uncertainty
- Real examples from the codebase, not abstract ones
- Progressive detail — summary first, then depth
- Comparison tables for trade-offs, mermaid diagrams for flows
- Explain "why", not just "what"

## Workflow

### Step 1: Determine Document Type

Ask the user which type of document they want to create if it's not clear from context.

### Step 2: Gather Context

Before writing anything:

1. **Search the project documentation first** — look for existing docs related to the topic
2. **Explore the codebase** — understand the current state of the code related to the topic. Use the Explore agent to find relevant modules, entities, and patterns
3. **Ask the user** what they want to communicate. Key questions vary by doc type:
   - **RFC**: What problem? What options have been considered? What's undecided?
   - **System Design**: What components? What are the design constraints? What approaches were rejected?
   - **Feature Design**: What's the goal? What modules are involved? What's the current state?
   - **Conceptual Explanation**: What does the team need to understand? What misconceptions exist?

### Step 3: Determine File Location

Ask the user where the document should live. Common patterns:

- RFCs typically go in a `work-in-progress/rfc/` area
- Initiative designs go alongside the initiative documentation
- Conceptual explanations go in the relevant platform/topic area
- System designs go alongside the related module or initiative

### Step 4: Write the Document

Follow the writing style from [WRITING_STYLE.md](./WRITING_STYLE.md) and use the structure template for the chosen document type below.

### Step 5: Update Indexes

After creating the document, check if any index files should reference the new document and update them.

---

## Document Type Structures

### RFC

1. **Title** — `# RFC: <Title>`
2. **Author and Status** — author link and status (Drafting, Debating, Accepted, Rejected, Implemented)
3. **Summary** — 2-3 sentences: what problem and what proposed solution, high-level
4. **Context and Problem Statement** — current state of the codebase (reference actual files), what problem we're solving, why it matters now, any relevant history
5. **Proposed Solution** — one or more options, each with concrete changes (file paths), pros, cons. Label the recommended option. Include an "Open Questions" subsection for undecided aspects
6. **Decision and Outcome** — what was decided and why, or "Pending discussion" if not yet decided
7. **References** — links to code files, PRs, other docs

### System Design

1. **Opening paragraph** — the core problem this design solves, no heading, just direct text
2. **Design Principles** — short declarative bullet points
3. **Components** — bold name + one-line description of responsibility for each
4. **Execution Diagram** — mermaid sequence or flow diagram showing component interactions
5. **Sections per major design area**, each with:
   - The specific problem/challenge
   - Approaches considered and rejected (comparison table)
   - Chosen approach with explanation, code examples, concrete examples
   - Edge cases
   - Trade-off analysis table
6. **Data Model** — TypeScript type definitions for entities involved
7. **Future Improvements** — what's explicitly deferred to later

### Feature Design

1. **Goal** — one paragraph: why this feature exists and what value it provides
2. **Context** — current codebase state: which modules, how things work today, relevant entities, previous work
3. **Proposal** — high-level approach, then sections per module/component:
   - Entity/aggregate root type signatures
   - Methods
   - Application layer — checklist of use cases with descriptions
   - Infrastructure layer — checklist of repositories and services with method signatures
4. **Infrastructure Integration** — how the feature integrates with external services, type signatures for inputs/outputs

### Conceptual Explanation

1. **Core concepts as top-level sections** — each one explained directly, starting with why it matters. Use real examples from the codebase
2. **Frame shifts** — explain how concepts change the way the team thinks or works. "We move from X to Y"
3. **Callout blocks** for key insights that should stand out
4. **Progressive building** — each section builds on the previous
5. **Mistakes to Avoid** — numbered list of common mistakes with explanations of why they're mistakes and what to do instead
