---
name: weekly-summary
description: >
  Transforms raw weekly team catchup transcripts or meeting notes into a structured
  summary message ready for Slack Canvas. Use this skill whenever the user provides
  meeting notes, a transcript from a weekly standup/catchup, or asks to summarize a
  team sync, weekly meeting, or sprint update — even if they don't say "weekly summary"
  explicitly. Also triggers when the user mentions "catchup notes", "meeting recap",
  "weekly update", or "team sync summary". IMPORTANT: The user frequently shares
  transcripts for purposes other than weekly summaries. Always ask the user for
  confirmation before generating a weekly summary — never assume that's the intent
  just because a transcript is present.
---

# Weekly Summary

Transform raw weekly team catchup content (transcripts, notes, bullet points) into a
polished, high-level summary formatted for Slack Canvas in English.

## Why this structure matters

Teams skim weekly updates — they need to quickly grasp what happened, what's next, and
what's blocked on someone else. The three-section format serves each of these needs
cleanly, so readers can jump to the section they care about.

## Before you start

Always confirm with the user before generating a summary. The user often shares
transcripts for other purposes (translation, extracting specific info, etc.). A simple
check like "Would you like me to generate a weekly summary from this?" is enough. Only
proceed once they confirm.

## Input

The user will provide raw meeting content. This could be:

- An auto-generated meeting transcript (often messy, with overlapping speakers and off-topic chatter)
- Handwritten bullet-point notes
- A mix of both

The input may be in **any language** (commonly Spanish). The output is **always in English**.

## Processing the input

1. **Filter out noise** — Meeting transcripts contain small talk, jokes, tangents, and
   filler. Focus only on information that is actionable or status-relevant. If the team
   was chatting about someone's new laptop, that's not summary material.

2. **Identify the three categories** — As you read, mentally bucket information into:
   - Things that already happened or are in progress (past/present)
   - Things planned for upcoming days or weeks (future)
   - Things that require action from someone outside the immediate team — stakeholders,
     other departments, external partners (blockers/dependencies)

3. **Translate and elevate** — Don't transcribe; synthesize. A 3-minute rambling
   explanation about a feature should become one or two clear bullet points.

## Output format

Use this exact structure. The output should be professional but approachable — the kind
of update a tech lead posts in a shared Slack channel.

```
📅 How the week went

[2-5 bullet points summarizing progress, achievements, and current status. Each bullet
should be a self-contained update. Use sub-bullets for relevant details. Use emoji
status indicators where helpful: ✅ done, 🔄 in progress, 🐛 bug-related]

🔮 What's coming up

[2-5 bullet points about planned work for the next days/weeks. Include specific dates
or timeframes if mentioned. Group related items together.]

⏳ Pending actions from stakeholders

[Bullet points listing what's needed from people outside the team. Each item should
clearly state WHO needs to do WHAT and by WHEN (if a deadline was mentioned). If no
pending stakeholder actions were discussed, write "No pending stakeholder actions
this week."]
```

## Style guidelines

- **Professional but human** — Not robotic corporate-speak, not overly casual either
- **Concise** — Each bullet point should be 1-2 lines max. Sub-bullets for details
- **Specific** — Use names, feature names, and dates when available from the source
- **Bold key terms** — Bold product names, feature names, and important concepts on
  first mention for scannability
- **Status indicators** — Use emoji markers (✅ 🔄 🐛 ✨ 📄) at the start of bullet
  points to indicate status at a glance, as shown in the format template above

## Example

Given a transcript where the team discussed: finishing a feature redesign, working on
accessibility improvements, fixing bugs, planning demo sessions, and needing design
input from another team:

```
📅 How the week went

- ✅ **Dashboard redesign** is practically finalized on the admin side
- 🔄 **Accessibility improvements**: Sara finalizing implementation, already included in demo sessions scope
- 🐛 Fixing previously identified bugs — may not all be resolved before demo session
- 🔄 **Theme support**: Alex coordinating with the design team, already in progress

🔮 What's coming up

- 📅 Demo sessions scheduled for next week (Monday: Admin Flow; Wednesday: User Flow)
- ✨ **Quick Actions modal** with keyboard shortcuts — needed for beta, will be activated when it launches
- 📄 **CSV import**: Jordan doing initial investigation on supported formats and edge cases

⏳ Pending actions from stakeholders

- **Design team** — Confirm color palette specs for the first version
- **Product team** — Align on beta opening timeline given confluence with other projects
```
