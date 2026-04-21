# Design: `reviewing-github-prs` skill

**Date:** 2026-04-21
**Status:** Approved

## Overview

A structured skill for reviewing GitHub PRs in the Jeongri marketplace. It separates thinking from writing: Claude reads the PR in full context, analyses it against a principled set of criteria, verifies any blocking findings via subagent before asserting them, then drafts per-comment severity labels and an aggregate judgment — all before touching the GitHub API. The result is saved as a **draft review** (pending state) via the GitHub API; the user submits it manually via the GitHub UI.

The skill builds on the mechanical workflow established by the aidankinzett `github-pr-review` skill (gh CLI, show → confirm → save), and adds substantive guidance over how Claude should actually think about and communicate a review.

---

## Workflow

Seven steps in order:

1. **Context pass** — Fetch the PR (title, description, diff, linked issues). Browse the broader codebase for established patterns: test presence, naming conventions, error handling style, existing abstractions.
2. **Analysis pass** — Work through the seven review criteria (see below). For each criterion, assess whether there are findings and tag them by severity. Produce an internal findings list before drafting any comments.
3. **Verification pass** — For every `[blocking]` finding, dispatch a subagent to trace the specific issue in the codebase and confirm or refute the initial assertion. The subagent returns evidence (file paths, line numbers, call paths). Findings that are refuted are downgraded to `[suggestion]` or dropped.
4. **Draft** — Write comments from the verified findings list, applying the communication guidelines below. Blocking comments must include the evidence from the verification pass.
5. **Show** — Display the full draft review to the user exactly as it will appear: all comments, their severity labels, and the aggregate summary with event type.
6. **Confirm** — Ask for explicit user approval before touching the GitHub API. Do not proceed without it.
7. **Save as draft** — Use `gh api` to create a pending review. Do not submit. Leave submission to the user via the GitHub UI.

---

## Prerequisites

- `gh` CLI installed and authenticated (`gh --version` to verify)
- The target PR number (ask the user if not provided)

---

## Review Criteria

Applied in this order. For each criterion, read the codebase context before judging the diff. If a criterion has no findings, say nothing — don't manufacture observations.

### 1. Correctness

Logic errors, wrong assumptions, off-by-ones, incorrect branching. Any plausible path where this code produces the wrong result.

- `[blocking]` — any realistic path to incorrect output

### 2. Error & Edge Case Handling

Silent failures, unhandled nulls, missing state transitions, unchecked return values.

- `[blocking]` — data loss, crashes, or security-relevant failures
- `[suggestion]` — degraded-but-recoverable paths that aren't handled

### 3. Security

Input validation, auth/authz boundaries, exposed secrets, injection surface, insecure defaults.

- `[blocking]` — any genuine vulnerability with a realistic attack path
- `[suggestion]` — theoretical risks or defence-in-depth improvements with no clear attack path

### 4. Test Coverage

Context-sensitive. Before judging, check whether the codebase has existing tests, and whether the modified component was previously tested.

- `[blocking]` if:
  - Complex new logic is added with no tests, regardless of existing coverage
  - An existing tested component is modified without updating coverage for the new behaviour
- `[suggestion]` if:
  - Simple additions to a codebase with no existing tests (bad practice, but not a blocker)
- `[nit]` if:
  - A trivial helper in an otherwise well-tested codebase lacks a test

### 5. Complexity

Unnecessary indirection, deep nesting, confusing naming, functions that do too many things.

- `[suggestion]` — in most cases; the author may have context that justifies the complexity
- `[blocking]` — only if the code is genuinely unmaintainable or obscures correctness issues

### 6. Codebase Consistency

Does this introduce a new pattern where one already exists? Does it break conventions the rest of the codebase follows? Established patterns were identified in the context pass.

- `[suggestion]` — in most cases
- `[blocking]` — only if the inconsistency is likely to cause bugs (e.g., diverging from a safety convention)

### 7. Scope Creep

Does the PR do more than its description says? Does it mix unrelated concerns in a way that makes review harder or rollback riskier?

- `[suggestion]` — always; sometimes scope creep is valid, but worth surfacing explicitly

---

## Severity Labels

| Label | Meaning | Requires verification | Blocks merge |
|---|---|---|---|
| `[blocking]` | Must be fixed before merge | Yes — subagent confirms with evidence | Yes |
| `[suggestion]` | Should be addressed; author's call | No | No |
| `[nit]` | Minor; no pressure | No | No |

---

## Verification Pass

For each `[blocking]` finding, dispatch a subagent with:
- The specific claim (what the issue is, where it is)
- The relevant code snippets
- The question to answer (e.g., "can `userId` be null here?", "is this endpoint reachable without authentication?")

The subagent traces the code paths, checks call sites, reads related files, and returns:
- **Confirmed** — with evidence (file, line, call path)
- **Refuted** — with explanation of why the initial reading was wrong
- **Inconclusive** — with what was checked and what remains uncertain

On refutation, downgrade to `[suggestion]` or drop. On inconclusive, retain as `[blocking]` but note the uncertainty in the comment.

---

## Comment Structure

**Blocking comments** (must include evidence):
```
[blocking] <what the problem is> — <why it matters>.
<specific evidence: file:line, call path, or code snippet>
Consider: <what to do instead or where to look>.
```

**Suggestions:**
```
[suggestion] <observation> — <brief reasoning>. Consider <direction>.
```

**Nits:**
```
[nit] <observation>.
```

---

## Aggregate Summary

After all per-comment findings, write a 2–3 sentence summary. Include a **recommended event type** for the user to select when they manually submit via the GitHub UI:

- If requesting changes: name the specific blocking issues
- If approving with suggestions: say so explicitly so the author knows they can merge
- If neutral comment: explain what's uncertain or what the questions are

**Recommended event type (user selects on submission):**
- `APPROVE` — no blocking issues; suggestions/nits are present or absent
- `REQUEST_CHANGES` — one or more verified blocking issues remain
- `COMMENT` — used for clarifying questions or when the reviewer lacks enough context to approve or block

The review is always saved as `PENDING` (draft) regardless of recommended event type. Claude never submits.

---

## Communication Tone

- Write to a colleague, not a student. Assume good intent.
- Don't soften blocking issues with excessive hedging — be clear about what's wrong.
- Don't editorialize. State the problem, state why it matters, offer a direction.
- For suggestions and nits, be brief. No need for extended reasoning.

---

## Anti-Patterns

Do not do any of the following:

| Anti-pattern | Why it's wrong |
|---|---|
| Style opinions when no style guide or linter rule exists | Personal preference dressed as a standard |
| Bikeshedding naming when the existing name is clear enough | Noise that obscures real findings |
| Blocking on personal preference | Wastes the author's time; undermines trust in reviews |
| Flagging every criterion on every PR | If a criterion has no findings, say nothing |
| Asserting a blocking issue without verification | A wrong blocking finding is worse than a missed suggestion |
| Submitting the review | User controls submission via GitHub UI |

---

## GitHub API Mechanics

### Verify CLI
```bash
gh --version
```

### Create draft review (do not submit)

The GitHub reviews API requires JSON for nested comment arrays — use `--input` with a JSON payload:

```bash
gh api repos/{owner}/{repo}/pulls/{pr_number}/reviews \
  --method POST \
  --input - <<EOF
{
  "body": "<aggregate summary with recommended event type>",
  "event": "PENDING",
  "comments": [
    {
      "path": "<file path>",
      "position": <diff hunk position>,
      "body": "<[severity] comment text>"
    }
  ]
}
EOF
```

The `position` field is the line number within the diff hunk (not the file line number) — verify against the PR diff before constructing the payload. The review remains in PENDING state. The user navigates to the GitHub PR UI and submits when satisfied.

---

## File Location

```
skills/
└── reviewing-github-prs/
    └── SKILL.md
```

Supporting subagent prompt for verification pass (if needed for length):
```
skills/
└── reviewing-github-prs/
    ├── SKILL.md
    └── verification-subagent.md
```
