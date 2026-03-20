---
name: phasing
description: "Use when a project is too large for a single spec. Decomposes the project into ordered phases, reviews the decomposition, gets user sign-off, then hands off to the ruminate skill for the first phase."
---

# Phasing

Decompose a large project into ordered, independently specifiable phases before design begins.

## When to Use

Invoked by the ruminate skill when scope assessment reveals multiple independent subsystems. Can also be invoked directly when decomposition is needed before any design work starts.

## Checklist

1. **Confirm project goal** — summarise what is being built (from ruminate context, or ask if invoked directly)
2. **Check for existing phases doc** — look in `docs/jeongri/phases/` for a pre-existing document for this topic; if found, present it and ask whether to continue from it or start fresh
3. **Decompose into phases** — help the user identify independent pieces, their relationships, and the right build order
4. **Write phases document** — save to `docs/jeongri/phases/YYYY-MM-DD-<topic>.md`
5. **Phase review loop** — dispatch phase-reviewer subagent (see phase-reviewer.md); fix issues and re-dispatch until approved (max 3 iterations, then surface to human)
6. **User sign-off** — present the phases document and wait for explicit approval; if changes requested, update and re-run phase reviewer before proceeding
7. **Commit** — `docs: add phases for <topic>`
8. **Hand off** — ask: *"Phases approved. Ready to start on Phase 1: `<phase name>`?"*
   - If yes → invoke the ruminate skill, passing Phase 1 context (phase number, phase name, phases document path, project goal summary)
   - If no → end here; the phases document is committed and ready for a future session

## Decomposition Guidelines

- Each phase should be independently specifiable and buildable
- Order phases so foundational pieces come first — each phase may depend on the previous, but not vice versa
- Aim for roughly consistent effort across phases; if one is much larger than the others, consider splitting it
- A phase should be small enough that its spec fits a single planning cycle

## Phases Document Format

```markdown
# Phases: <Topic>

Created: YYYY-MM-DD

## Phases

- [ ] **1. <Phase Name>** — <brief description> | Spec: pending
- [ ] **2. <Phase Name>** — <brief description> | Spec: pending
- [ ] **3. <Phase Name>** — <brief description> | Spec: pending
```

## Handing Off to Ruminate

When invoking ruminate for Phase 1, pass the following as context:

- Phase number and name (e.g. "Phase 1 of 3 — Data Model")
- Path to the phases document
- Project goal summary

Ruminate will skip its context update and scope assessment — both are already complete.
