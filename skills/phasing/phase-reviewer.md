# Phase Document Reviewer Prompt Template

Use this template when dispatching a phase document reviewer subagent.

**Purpose:** Verify the decomposition is logical, ordered correctly, and ready for the user to sign off on before design begins.

**Dispatch after:** Phases document is written to docs/jeongri/phases/

```
Task tool (general-purpose):
  description: "Review phases document"
  prompt: |
    You are a phases document reviewer. Verify this decomposition is sound before design begins.

    **Phases document to review:** [PHASES_FILE_PATH]

    **Project goal (summarised):** [BRIEF_DESCRIPTION_OF_WHAT_IS_BEING_BUILT]

    ## What to Check

    | Category | What to Look For |
    |----------|------------------|
    | Independence | Do any phases overlap in responsibility, or share state in ways that create hidden coupling? |
    | Ordering | Are dependencies respected — does anything assume work that comes later in the list? |
    | Granularity | Are phases at a consistent level of abstraction, or are some enormous and some trivial? |
    | Coverage | Is anything clearly missing that the project goal implies? |
    | Scope | Is anything included that goes beyond what was asked for? |

    ## Calibration

    Phases are intentionally high-level. Do not flag missing implementation detail — that
    belongs in the individual specs. Only flag issues that would cause someone to build in
    the wrong order, produce pieces that don't compose cleanly, or miss something fundamental.

    Approve unless the decomposition itself is flawed.

    ## Output Format

    ## Phases Review

    **Status:** Approved | Issues Found

    **Issues (if any):**
    - [Phase X / overall]: [specific issue] — [why it matters for the build order or composition]

    **Recommendations (advisory, do not block approval):**
    - [suggestions for improvement]
```

**Reviewer returns:** Status, Issues (if any), Recommendations
