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

Work through all seven criteria in order. For each, assess the diff against the codebase context from Step 1. **Every criterion must produce an explicit entry** — write this list in your response before proceeding to Step 3.

**Internal working format:**
```
Criterion: <name>
Finding: <what the issue is, specifically> — or "No findings"
Location: <file:line or area of diff> — omit if no findings
Severity: `[blocking]` / `[suggestion]` / `[nit]` — omit if no findings
Reason: <one sentence on why this severity> — omit if no findings
```

All seven criteria must appear in the list. `No findings` is a valid and expected result — do not manufacture observations to fill it.

**Severity reference:**

| Label | Meaning | Requires subagent verification | Blocks merge |
|---|---|---|---|
| `[blocking]` | Must be fixed before merge | Yes — for reachability/correctness claims | Yes |
| `[suggestion]` | Should be addressed; author's call | No | No |
| `[nit]` | Minor; no pressure | No | No |

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

For every `[blocking]` finding that involves a reachability or correctness claim, dispatch a verification subagent before writing the comment. See `verification-subagent.md` for the exact prompt template.

For `[blocking]` findings on Complexity or Codebase Consistency (where the concern is about design quality rather than a reachable bug), assess the evidence inline — the verification subagent is not applicable to these.

The subagent returns one of:
- **Confirmed** — with evidence: specific file:line, call path, or code snippet proving the claim
- **Refuted** — with explanation of why the initial reading was wrong
- **Inconclusive** — with what was checked and what remains uncertain

**On refutation:** downgrade to `[suggestion]` or drop the finding entirely.
**On inconclusive:** retain as `[blocking]` but note the uncertainty explicitly in the comment.

If the findings list contains no `[blocking]` items, proceed directly to Step 4.

Do not proceed to drafting until all `[blocking]` findings have been verified.

---

### Step 4 — Draft Review

Write comments from the verified findings list.

**Blocking comment (must include evidence):**
```
[AI][blocking] <what the problem is — one tight sentence>.

<evidence: file:line or minimal code snippet from the verification subagent>

Consider: <what to do instead or where to look>.
```

**Suggestion:**
```
[AI][suggestion] <observation — one tight sentence>. Consider <direction>.
```

**Nit:**
```
[AI][nit] <observation>.
```

**Formatting note:** GitHub Markdown requires a blank line between sections for paragraph breaks. In the JSON payload, represent blank lines as `\n\n` between the three sections of a blocking comment. Suggestions and nits are single-line — no blank lines needed.

After all per-comment findings, write an **aggregate summary** (2–3 sentences):
- State the overall picture
- Include the **recommended event type** — what you would submit if you were submitting: `APPROVE`, `REQUEST_CHANGES`, or `COMMENT`
- If requesting changes: name the specific blocking issues by name
- If approving with suggestions: say so explicitly so the author knows they can merge

**Recommended event type guide:**
- `APPROVE` — no verified blocking issues remain
- `REQUEST_CHANGES` — one or more verified blocking issues remain
- `COMMENT` — clarifying questions only, or insufficient context to approve or block

### Step 5 — Show

Display the full draft to the user before touching GitHub:
- Each comment in the exact body text it will be posted (verbatim, not summarised), alongside its file path and severity label
- The aggregate summary
- The recommended event type and what it means for the author

### Step 6 — Confirm

Ask explicitly:

> "This will be saved as a draft review on GitHub — visible only to you until you submit via the GitHub UI. Shall I save it?"

Do not proceed without a clear yes.

### Step 7 — Save as Draft

Get the diff to extract correct hunk positions (the `position` field is the sequential line number within the unified diff output, not the file line number):

To derive the correct position: within the patch output, find the hunk containing your target line. Count lines sequentially from 1 starting at that hunk's `@@` header line (the `@@` line itself is position 1). Context lines, added lines, and removed lines all increment the counter; only the file header lines (`---`/`+++`) do not.

```bash
gh pr diff {pr_number} --patch
```

**Omit the `event` field entirely.** GitHub creates the review in PENDING (draft) state when no `event` is provided. The recommended event type is advisory prose in the `body` — for the user to select manually when they submit. Never add an `event` field to the payload.

Post the pending review:

```bash
gh api repos/{owner}/{repo}/pulls/{pr_number}/reviews \
  --method POST \
  --input - <<'EOF'
{
  "body": "<aggregate summary with recommended event type>",
  "comments": [
    {
      "path": "<file path relative to repo root>",
      "position": <diff hunk position>,
      "body": "<[severity] comment text including evidence if blocking>"
    }
  ]
}
EOF
```

If there are no inline file comments, use `"comments": []` in the payload.

The review is now in PENDING state. Navigate to the GitHub PR to inspect, edit, and submit.

---

## Anti-Patterns

Do not do any of the following:

| Anti-pattern | Why |
|---|---|
| Style opinions without a style guide or linter rule | Personal preference dressed as a standard |
| Bikeshedding naming when the existing name is clear and unambiguous | Noise. Genuine stutter/ambiguity/misleading names belong under Codebase Consistency |
| Blocking on personal preference | Wastes author time; undermines trust in reviews |
| Flagging every criterion on every PR | If no findings, say nothing |
| Asserting `[blocking]` without verification | A wrong blocking claim is worse than a missed suggestion |
| Submitting the review | User controls submission via GitHub UI |
| Writing comments before finishing the analysis pass | Leads to redundant or contradictory feedback |
| Referencing facts about the codebase not visible in the diff or the Step 1 read | Hallucinated context; treat only what you can observe as ground truth |

---

## Communication Tone

- Write to a colleague, not a student. Assume good intent.
- Don't soften blocking issues with excessive hedging — be clear about what's wrong.
- Don't editorialize. State the problem, why it matters, offer a direction. Nothing else.
- For suggestions and nits, be brief. No extended reasoning needed.
- Cut filler phrases: "Worth noting that", "It might be worth", "You might want to", "This could potentially", "Consider whether" — none of these add meaning. Drop them.
- State the problem first. Evidence second. Direction third. No preamble.
- Target length: [nit] = one sentence. [suggestion] = one to two sentences. [blocking] = three short sections (problem, evidence, direction).
