# Writing Style Reference

Rules for writing architectural documentation. These merge principles from William Zinsser's _On Writing Well_ with patterns established across technical documentation I've written (RFCs, system designs, feature designs, conceptual explanations).

The goal of this documentation is to **teach** and, when needed, **convince**. Not to entertain.

## Core Principles

- **Clear thinking becomes clear writing** one can't exist without the other. Before writing a section, ask: what am I trying to say?
- **Strip every sentence to its cleanest components** clutter is the disease of writing. Cut unnecessary words, pompous frills, and meaningless jargon
- **Never say anything in writing you wouldn't say in conversation** if you don't say "indeed" or "moreover" out loud, don't write it
- **Problem before solution** always explain the current state and the pain before proposing anything. The reader needs to understand why before they care about what
- **Be honest about uncertainty** mark undecided things as open questions, use "TBW" for sections to be written later, say "pending to decide" when things are undecided. Don't pretend everything is figured out

## Voice and Tone

- **Use "we" throughout** write as if talking to a colleague. "We will add", "We currently have", "Our proposed solution"
- **Conversational but professional** approachable, not casual. The reader should feel like they're being walked through something by someone who knows it well, not reading a spec document
- **Teacher-like** explain concepts by building up from fundamentals. Explain the "why" before the "how"
- **Direct** "The problem with this approach is..." not "It could be argued that one potential concern might be..."
- **Humble when appropriate** acknowledge limitations, trade-offs, and things you don't know yet. This builds trust
- **Convicted when recommending** when proposing a solution, be clear about why you believe it's the right one. Label recommendations explicitly (e.g., "Option A: ... (Recommended)")

## Structure

- **Progressive detail** — start with a 2-3 sentence summary, then expand. Each section goes deeper than the previous
- **Real examples from the codebase** — never use abstract "FooService" examples. Use actual module names, entity names, file paths so the reader can go look at the code
- **Show type signatures** — when introducing data models or entities, show the TypeScript type definition
- **Show code examples** — when explaining patterns, show how they look in actual code with real entities
- **Reference actual files** — include file paths so readers can find the code
- **Build concepts progressively** — explain foundational ideas before building on them. Don't reference something you haven't introduced yet

## Formatting

- **Comparison tables** for trade-offs and rejected approaches:
  ```
  | Approach | Why It Fails |
  | --- | --- |
  ```
- **Callout blocks** for important insights or warnings that should stand out from the main text
- **Mermaid diagrams** for execution flows and component interactions
- **Checklists** (`- [ ]`) for implementation plans listing what needs to be built
- **Bold for key terms** when first introducing them: "The **WorkflowJournal** holds the source of truth"
- **Code blocks with language hints** for types, code examples, and file structures
- **Don't use Dashes for asides, use normal comas or other punctuation** use them to add clarification without breaking the sentence flow
- **Mix sentence lengths** short punchy sentences for key points, longer ones for explanations. Don't let either dominate

## Content

- **Contextualize in the codebase** relate abstract concepts to concrete things. "This is similar to how the video output module is architected"
- **Explain the "why" behind decisions** don't just state what was chosen, explain why alternatives were rejected
- **List open questions explicitly** use a dedicated "Open Questions" section with numbered items
- **Cross-reference** link to related RFCs, PRs, code files, and other documentation
- **Acknowledge edge cases** discuss known limitations and edge cases openly rather than hiding them
- **State what is deferred** if something is intentionally left for later, say so in a "Future Improvements" section
- **Use analogies sparingly** when a concept maps well to something the reader already knows, use it. Don't force it

## Avoid

- Generic descriptions disconnected from the codebase
- Hiding uncertainty behind confident-sounding language
- Over-formalizing. This is internal documentation for engineers, not a specification for an external audience
- Duplicating content from other docs, link to them instead
- Passive voice. Prefer active. "We implemented X" not "X was implemented"
- Unnecessary organizational comments or headers that don't add information
- Conclusions that just repeat what was already said
- Pompous phrases hiding painful truths, call problems what they are
- Jargon without explanation, if a term isn't obvious, explain it on first use
- Long unbroken paragraphs, break them up
