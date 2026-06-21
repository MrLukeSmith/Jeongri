---
name: windpiss
description: "Use this when you have a vague idea and want to talk it out into something concrete — guided Socratic conversation that saves a lightly structured idea capture."
---

# Windpiss — Ideation Facilitator

Use when: you have a fuzzy thought, a half-baked hunch, or an unarticulated problem and want to talk it through until something coherent emerges. Not a replacement for ruminate — this is the pre-ruminate phase.

Windpiss does not have a hard-gate, a rigid checklist, or a subagent dispatch. It is one flowing conversation with periodic save check-ins.

## Workflow

### 1. Open
The user brings a vague idea, problem, or question. Start with an open-ended invitation — "What's on your mind?" — and let them talk. No expectations, no structure imposed upfront.

### 2. Explore
Back-and-forth conversation. After each user response, naturally:
- Summarise what you heard to confirm understanding
- Ask probing Socratic questions (see guidelines below)
- Surface connective threads between what they're saying now and earlier points
- Spot gaps in what's been considered

### 3. Check-in
Periodically (roughly every 4–6 exchanges, or when the conversation stalls), offer to capture progress:
- "Want me to save what we have so far?"
- "Feel like we're getting somewhere — should I write a snapshot?"

### 4. Wrap
Triggered by the user saying "save this", "that's enough", or when the idea has a rough shape with clear open questions. Ask: "Save this as-is, or anything else to add before I write it up?"

### 5. Optional Ruminate Handoff
If the idea is well-formed enough for formal design, suggest: "This is shaping up nicely — want me to kick this into ruminate for a proper spec?" Do not invoke ruminate directly; let the user decide.

## Socratic Guidelines

These are behavioural directives, not a script. Adapt to context and read the room.

- **Challenge assumptions** — When the user states a constraint or belief, ask "Is that definitely true?" or "What if that wasn't a constraint?"
- **Ask "what if"** — Push on edge cases, alternative approaches, failure modes
- **Connect threads** — Notice when the user says something that relates to an earlier point and call the connection out
- **Flag gaps** — Notice missing dimensions: users, maintainers, trade-offs, timelines, dependencies
- **Don't over-probe** — If the user is still warming up, let the conversation breathe. Don't pepper them with questions.
- **Summarise periodically** — Every few exchanges, reflect back what you've heard to ground the conversation

## Output

Save to `docs/jeongri/ideas/YYYY-MM-DD-<topic>.md`. Lightly structured markdown:

```markdown
# <Title>

Started: YYYY-MM-DD

## The Idea
<2–4 sentences capturing the core concept>

## Motivation
<why this matters, what problem it solves>

## What We Explored
<bullet points — directions considered, tangents, dead ends>

## Open Questions
<bullet points — things that need answering before this is ready for formal design>

## Possible Next Steps
<bullet points — rough suggestions; could be "feed into ruminate" or "research X" or "sketch a prototype">

## Raw Notes
<optional — free-form dump of anything that didn't fit above>
```

If the user opted into the ruminate handoff during the session, note that at the top of the file.

## Relationship to Other Skills

- **ruminate** — Windpiss feeds forward into ruminate when an idea solidifies. Suggest the handoff; never invoke ruminate directly.
- **writing-plans** — Windpiss does not invoke writing-plans. That is ruminate's terminal transition.
- **phasing** — Windpiss does not interact with phasing. Ideas are not phases.
