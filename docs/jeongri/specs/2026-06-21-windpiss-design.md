# Design: `windpiss` skill

**Date:** 2026-06-21
**Status:** Approved

## Overview

A lightweight ideation facilitator for the messy, pre-ruminate phase. Windpiss helps turn vague thoughts, half-baked hunches, and unarticulated problems into something concrete enough to either feed into ruminate or save as-is. It's a rubberduck with an edge — guided conversation with Socratic probing.

Windpiss does not have a hard-gate, a rigid checklist, or a subagent dispatch. It's one flowing conversation with periodic save check-ins.

---

## Positioning

Windpiss sits *before* ruminate in the workflow:

```
Vague idea → Windpiss → Coherent direction → Ruminate → Formal spec → Writing-plans → Implementation
                      ↘ Save as idea capture (done for now)
```

**Key differences from ruminate:**

| Dimension | Ruminate | Windpiss |
|---|---|---|
| Input | Defined idea or request | Vague thought, problem, hunch |
| Output | Full design doc (architecture, testing, etc.) | Lightly structured idea capture |
| Process | Step-by-step checklist | Guided but free-flowing conversation |
| Guardrails | Hard-gate before implementation | No hard-gate |
| Subagents | Spec reviewer, phasing | None |
| Socratic probing | Not emphasised | Core behaviour |

---

## Workflow

### 1. Open
User brings a vague idea, problem, or question. Windpiss greets and invites them to talk it out. First prompt is open-ended — "What's on your mind?" — no expectations.

### 2. Explore
Back-and-forth conversation. After each user response, windpiss naturally:
- Summarises what it heard (confirms understanding)
- Asks probing Socratic questions — "What about X?", "Why not Y?", "What happens if that breaks?"
- Surfaces connective threads — "Doesn't this link back to what you said about Z?"
- Spots gaps — "You mentioned users but not who maintains it — any thoughts there?"
- Challenges assumptions gently — "Is that actually a constraint, or an assumption?"

The Socratic prompting is encoded as behavioural instructions in SKILL.md, not a literal script. The AI adapts to context.

### 3. Check-in
Periodically (roughly every 4–6 exchanges, or when conversation stalls), windpiss offers:
- "Want me to capture what we have so far?"
- "Feel like we're getting somewhere — should I save a snapshot?"

### 4. Wrap
Triggered by user saying "save this", "that's enough", or windpiss detecting a natural resolution (idea has rough shape, key open questions identified). Windpiss asks: "Save this as-is, or anything else to add before I write it up?"

### 5. Optional Ruminate Handoff
If the idea seems well-formed enough, windpiss suggests: "This is shaping up nicely — want me to kick this into ruminate for a proper spec?" The user can accept or decline.

---

## Socratic Guidelines (SKILL.md content)

Encoded as behavioural directives in the skill:

- **Challenge assumptions** — When the user states a constraint or belief, ask "Is that definitely true?" or "What if that wasn't a constraint?"
- **Ask "what if"** — Push on edge cases, alternative approaches, failure modes
- **Connect threads** — Notice when the user says something that relates to an earlier point and call the connection out
- **Flag gaps** — Notice missing dimensions: users, maintainers, trade-offs, timelines, dependencies
- **Don't over-probe** — Read the room. If the user is clearly still warming up, don't pepper them. Let the conversation breathe.
- **Summarise periodically** — Every few exchanges, reflect back what you've heard to ground the conversation

---

## Output Format

Saved to `docs/jeongri/ideas/YYYY-MM-DD-<topic>.md`. Lightly structured markdown:

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

If the user opts into the ruminate handoff during the session, note that at the top of the file.

---

## File Location

```
skills/
└── windpiss/
    └── SKILL.md
```

Single file, no subagents or companion prompts.

---

## Relationship to Other Skills

- **ruminate** — Windpiss feeds forward into ruminate when an idea solidifies. Windpiss never invokes ruminate directly; it suggests the handoff and the user decides.
- **writing-plans** — Windpiss does not invoke writing-plans. That's ruminate's terminal transition.
- **phasing** — Windpiss does not interact with phasing. Ideas are not phases.
