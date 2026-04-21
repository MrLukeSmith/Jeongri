---
name: reviewing-github-prs
description: Use when asked to review a GitHub pull request — runs a structured analysis, verifies blocking findings via subagent, and saves a draft review for manual submission via the GitHub UI
---

# Reviewing GitHub PRs

Structured PR review in two phases: think first, write second. Claude analyses the PR against a principled set of criteria, verifies any blocking findings before asserting them, then saves a draft review on GitHub for you to inspect and submit.

**Announce at start:** "I'm using the reviewing-github-prs skill to review this pull request."

**The review is always saved as a draft (PENDING state). Claude never submits. You control submission via the GitHub UI.**

## Prerequisites

Verify the `gh` CLI is installed and authenticated:

```bash
gh --version
gh auth status
```

Ask the user for the PR number if not provided. Identify `{owner}` and `{repo}` from the current git remote:

```bash
git remote get-url origin
```

---

## Workflow

### Step 1 — Context Pass

Fetch the PR metadata and diff:

```bash
gh pr view {pr_number} --json title,body,additions,deletions,files,baseRefName
gh pr diff {pr_number}
```

Read the full PR title, description, and diff. Then browse the broader codebase to build context — focus on the files directly modified and their immediate dependencies; do not read the entire codebase:

- **Test presence:** Are there test files? What testing framework? What's the coverage pattern for the files being modified?
- **Error handling conventions:** How does this codebase handle errors — exceptions, result types, error codes?
- **Naming and structural patterns:** What conventions are established in nearby files?
- **Existing abstractions:** What utilities or patterns already exist that the PR should be using?

This context informs every severity judgment in the next step.

### Step 2 — Analysis Pass

Work through all seven criteria in order. For each, assess the diff against the codebase context from Step 1. Produce an internal findings list before drafting any comment.

**Internal working format — write this list explicitly in your response before proceeding to Step 3:**
```
Criterion: <name>
Finding: <what the issue is, specifically>
Location: <file:line or area of diff>
Severity: `[blocking]` / `[suggestion]` / `[nit]`
Reason: <one sentence on why this severity>
```

If a criterion has no findings, move on — do not manufacture observations.

**The seven criteria:**

**1. Correctness** — Logic errors, wrong assumptions, off-by-ones, incorrect branching. Any plausible path where this code produces the wrong result.
- `[blocking]` — any realistic path to incorrect output
- If uncertain whether a correctness concern is actually reachable, still tag it `[blocking]` and let the verification subagent confirm — do not silently drop it

**2. Error & Edge Case Handling** — Silent failures, unhandled nulls, missing state transitions, unchecked return values.
- `[blocking]` — data loss, crashes, or security-relevant failures
- `[suggestion]` — degraded-but-recoverable paths that aren't handled

**3. Security** — Input validation, auth/authz boundaries, exposed secrets, injection surface, insecure defaults.
- `[blocking]` — genuine vulnerability with a realistic attack path
- `[suggestion]` — theoretical risks or defence-in-depth improvements with no clear attack path

**4. Test Coverage** — Before judging, check the codebase for existing tests and whether the modified component was previously tested.
- `[blocking]` if: complex new logic has no tests regardless of existing coverage (complex = multiple branches, state mutation, or external I/O — not a single-expression helper); OR an existing tested component is modified without updating coverage for the new behaviour
- `[suggestion]` if: simple additions to a codebase with no existing tests (bad practice, not a blocker)
- `[nit]` if: a trivial helper in an otherwise well-tested codebase lacks a test

**5. Complexity** — Unnecessary indirection, deep nesting, confusing naming, functions doing too many things.
- `[suggestion]` in most cases; author may have context that justifies it
- `[blocking]` only if genuinely unmaintainable or obscures correctness

**6. Codebase Consistency** — Does this introduce a new pattern where one exists? Does it break established conventions identified in Step 1?
- `[suggestion]` in most cases
- `[blocking]` only if the inconsistency is likely to cause bugs (e.g. diverging from a safety convention)

**7. Scope Creep** — Does the PR do more than described? Does it mix unrelated concerns in a way that makes review harder or rollback riskier?
- `[suggestion]` always — sometimes scope creep is valid, but worth surfacing

### Step 3 — Verification Pass

For every `[blocking]` finding in the list, dispatch a verification subagent before writing the comment. See `verification-subagent.md` for the exact prompt template.

The subagent returns one of:
- **Confirmed** — with evidence: specific file:line, call path, or code snippet proving the claim
- **Refuted** — with explanation of why the initial reading was wrong
- **Inconclusive** — with what was checked and what remains uncertain

**On refutation:** downgrade to `[suggestion]` or drop the finding entirely.
**On inconclusive:** retain as `[blocking]` but note the uncertainty explicitly in the comment.

If the findings list contains no `[blocking]` items, proceed directly to Step 4.

Do not proceed to drafting until all `[blocking]` findings have been verified.
