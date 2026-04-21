# Reviewing GitHub PRs — Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Create a `reviewing-github-prs` skill for the Jeongri marketplace that guides Claude through a structured, evidence-backed PR review and saves it as a GitHub draft.

**Architecture:** Two files — `SKILL.md` contains the full workflow and review criteria, `verification-subagent.md` holds the prompt template Claude dispatches when verifying blocking findings. The skill has seven workflow steps: context pass → analysis pass → verification pass → draft → show → confirm → save as PENDING draft via `gh api`.

**Tech Stack:** Markdown skill files, `gh` CLI, GitHub Pull Reviews API

---

## File Map

| File | Action | Purpose |
|---|---|---|
| `skills/reviewing-github-prs/SKILL.md` | Create | Main skill — full workflow, criteria, API mechanics |
| `skills/reviewing-github-prs/verification-subagent.md` | Create | Subagent prompt template for verifying `[blocking]` findings |

---

## Task 1: Scaffold SKILL.md — frontmatter, overview, prerequisites

**Files:**
- Create: `skills/reviewing-github-prs/SKILL.md`

- [ ] **Step 1: Create the file with frontmatter, overview, and prerequisites**

Write `skills/reviewing-github-prs/SKILL.md` with this exact content:

```markdown
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
```

Ask the user for the PR number if not provided. Identify `{owner}` and `{repo}` from the current git remote:

```bash
git remote get-url origin
```

---
```

- [ ] **Step 2: Verify the file exists with correct content**

```bash
head -20 skills/reviewing-github-prs/SKILL.md
```

Expected: YAML frontmatter block followed by the heading and announce line.

- [ ] **Step 3: Commit**

```bash
git add skills/reviewing-github-prs/SKILL.md
git commit -m "feat: scaffold reviewing-github-prs skill"
```

---

## Task 2: Write workflow Steps 1–3 (context, analysis, verification)

**Files:**
- Modify: `skills/reviewing-github-prs/SKILL.md`

- [ ] **Step 1: Append the Workflow heading and Steps 1–3**

Append to `skills/reviewing-github-prs/SKILL.md`:

```markdown
## Workflow

### Step 1 — Context Pass

Fetch the PR metadata and diff:

```bash
gh pr view {pr_number} --json title,body,additions,deletions,files,baseRefName
gh pr diff {pr_number}
```

Read the full PR title, description, and diff. Then browse the broader codebase to build context:

- **Test presence:** Are there test files? What testing framework? What's the coverage pattern for the files being modified?
- **Error handling conventions:** How does this codebase handle errors — exceptions, result types, error codes?
- **Naming and structural patterns:** What conventions are established in nearby files?
- **Existing abstractions:** What utilities or patterns already exist that the PR should be using?

This context informs every severity judgment in the next step.

### Step 2 — Analysis Pass

Work through all seven criteria in order. For each, assess the diff against the codebase context from Step 1. Produce an internal findings list before drafting any comment.

**Internal working format — record each finding as:**
```
Criterion: <name>
Finding: <what the issue is, specifically>
Location: <file:line or area of diff>
Severity: [blocking] / [suggestion] / [nit]
Reason: <one sentence on why this severity>
```

If a criterion has no findings, move on — do not manufacture observations.

**The seven criteria:**

**1. Correctness** — Logic errors, wrong assumptions, off-by-ones, incorrect branching. Any plausible path where this code produces the wrong result.
- `[blocking]` — any realistic path to incorrect output

**2. Error & Edge Case Handling** — Silent failures, unhandled nulls, missing state transitions, unchecked return values.
- `[blocking]` — data loss, crashes, or security-relevant failures
- `[suggestion]` — degraded-but-recoverable paths that aren't handled

**3. Security** — Input validation, auth/authz boundaries, exposed secrets, injection surface, insecure defaults.
- `[blocking]` — genuine vulnerability with a realistic attack path
- `[suggestion]` — theoretical risks or defence-in-depth improvements with no clear attack path

**4. Test Coverage** — Before judging, check the codebase for existing tests and whether the modified component was previously tested.
- `[blocking]` if: complex new logic has no tests regardless of existing coverage; OR an existing tested component is modified without updating coverage for the new behaviour
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

Do not proceed to drafting until all `[blocking]` findings have been verified.

---
```

- [ ] **Step 2: Verify the append landed correctly**

```bash
grep -n "Step 1\|Step 2\|Step 3\|Verification Pass" skills/reviewing-github-prs/SKILL.md
```

Expected: lines for all three step headings.

- [ ] **Step 3: Commit**

```bash
git add skills/reviewing-github-prs/SKILL.md
git commit -m "feat: add workflow steps 1-3 to reviewing-github-prs"
```

---

## Task 3: Write workflow Steps 4–7 (draft, show, confirm, save)

**Files:**
- Modify: `skills/reviewing-github-prs/SKILL.md`

- [ ] **Step 1: Append Steps 4–7**

Append to `skills/reviewing-github-prs/SKILL.md`:

```markdown
### Step 4 — Draft Review

Write comments from the verified findings list.

**Blocking comment (must include evidence):**
```
[blocking] <what the problem is> — <why it matters>.
<evidence: file:line, call path, or code snippet from the verification subagent>
Consider: <what to do instead, or where to look>.
```

**Suggestion:**
```
[suggestion] <observation> — <brief reasoning>. Consider <direction>.
```

**Nit:**
```
[nit] <observation>.
```

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
- All comments with severity labels and file locations
- The aggregate summary
- The recommended event type and what it means for the author

### Step 6 — Confirm

Ask explicitly:

> "This will be saved as a draft review on GitHub in PENDING state — visible only to you until you submit via the GitHub UI. Shall I save it?"

Do not proceed without a clear yes.

### Step 7 — Save as Draft

Get the diff to extract correct hunk positions (the `position` field is the sequential line number within the unified diff output, not the file line number):

```bash
gh pr diff {pr_number} --patch
```

Post the pending review:

```bash
gh api repos/{owner}/{repo}/pulls/{pr_number}/reviews \
  --method POST \
  --input - <<'EOF'
{
  "body": "<aggregate summary with recommended event type>",
  "event": "PENDING",
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

The review is now in PENDING state. Navigate to the GitHub PR to inspect, edit, and submit.

---
```

- [ ] **Step 2: Verify all seven steps are present**

```bash
grep -n "Step [1-7] —" skills/reviewing-github-prs/SKILL.md
```

Expected: seven lines, one per step.

- [ ] **Step 3: Commit**

```bash
git add skills/reviewing-github-prs/SKILL.md
git commit -m "feat: add workflow steps 4-7 to reviewing-github-prs"
```

---

## Task 4: Write anti-patterns and communication tone sections

**Files:**
- Modify: `skills/reviewing-github-prs/SKILL.md`

- [ ] **Step 1: Append anti-patterns and tone**

Append to `skills/reviewing-github-prs/SKILL.md`:

```markdown
## Anti-Patterns

Do not do any of the following:

| Anti-pattern | Why |
|---|---|
| Style opinions without a style guide or linter rule | Personal preference dressed as a standard |
| Bikeshedding naming when the existing name is clear | Noise that obscures real findings |
| Blocking on personal preference | Wastes author time; undermines trust in reviews |
| Flagging every criterion on every PR | If no findings, say nothing |
| Asserting `[blocking]` without verification | A wrong blocking claim is worse than a missed suggestion |
| Submitting the review | User controls submission via GitHub UI |
| Writing comments before finishing the analysis pass | Leads to redundant or contradictory feedback |

---

## Communication Tone

- Write to a colleague, not a student. Assume good intent.
- Don't soften blocking issues with excessive hedging — be clear about what's wrong.
- Don't editorialize. State the problem, why it matters, offer a direction.
- For suggestions and nits, be brief. No extended reasoning needed.
```

- [ ] **Step 2: Verify the sections landed**

```bash
grep -n "Anti-Patterns\|Communication Tone" skills/reviewing-github-prs/SKILL.md
```

Expected: both headings present.

- [ ] **Step 3: Commit**

```bash
git add skills/reviewing-github-prs/SKILL.md
git commit -m "feat: add anti-patterns and tone to reviewing-github-prs"
```

---

## Task 5: Create verification-subagent.md

**Files:**
- Create: `skills/reviewing-github-prs/verification-subagent.md`

- [ ] **Step 1: Create the subagent prompt file**

Write `skills/reviewing-github-prs/verification-subagent.md` with this exact content:

```markdown
# Verification Subagent

Use this prompt template when dispatching a verification subagent for a `[blocking]` finding. Fill in all placeholders before dispatching.

## Prompt Template

```
You are verifying a specific claim about a code change before it is posted as a blocking review comment. Be precise and thorough — a wrong blocking assertion does more harm than a missed suggestion.

**Repository:** {owner}/{repo}
**PR:** #{pr_number}
**Claim:** {specific assertion — e.g. "`processPayment()` can receive a null `userId` from the unauthenticated route at `/checkout/guest`"}
**Location in diff:** {file path}:{approximate line range}

Your task:
1. Read the code at the specified location in full.
2. Trace all call sites that can reach this code — follow the call chain as deep as needed.
3. Check whether the condition described in the claim is actually reachable with a realistic input or code path.
4. Return exactly one of:
   - **Confirmed** — the claim is correct. Provide: the specific `file:line` where the problem exists, the full call path that reaches it, and a minimal code snippet demonstrating the issue.
   - **Refuted** — the claim is wrong. Explain precisely why: what mechanism prevents the problem from occurring?
   - **Inconclusive** — you cannot confirm or deny with confidence. List every file you checked and what specific question remains unanswered.

Do not speculate. Only report what the code actually shows. If a path is guarded somewhere, name where. If it isn't, name where the gap is.
```

## Handling Results

| Result | Action |
|---|---|
| **Confirmed** | Use the provided evidence verbatim in the `[blocking]` comment body |
| **Refuted** | Downgrade to `[suggestion]` or drop the finding entirely |
| **Inconclusive** | Retain as `[blocking]`, add to comment: "Unable to fully trace this path — recommend verifying manually" |
```

- [ ] **Step 2: Verify the file exists**

```bash
head -5 skills/reviewing-github-prs/verification-subagent.md
```

Expected: `# Verification Subagent` heading.

- [ ] **Step 3: Commit**

```bash
git add skills/reviewing-github-prs/verification-subagent.md
git commit -m "feat: add verification subagent prompt for reviewing-github-prs"
```

---

## Task 6: Self-review against spec and fix gaps

**Files:**
- Modify: `skills/reviewing-github-prs/SKILL.md` (if gaps found)

- [ ] **Step 1: Read the spec**

```bash
cat docs/jeongri/specs/2026-04-21-reviewing-github-prs-design.md
```

- [ ] **Step 2: Read the completed SKILL.md**

```bash
cat skills/reviewing-github-prs/SKILL.md
```

- [ ] **Step 3: Check spec coverage**

Verify each spec requirement maps to a section in SKILL.md:

| Spec requirement | Covered by |
|---|---|
| Context pass (fetch PR + browse codebase) | Step 1 section |
| Analysis pass (7 criteria with internal list) | Step 2 section |
| Verification pass (subagent for blocking) | Step 3 section |
| Draft with per-comment labels | Step 4 section |
| Show before posting | Step 5 section |
| Explicit confirm | Step 6 section |
| Save as PENDING draft, never submit | Step 7 section |
| Severity table ([blocking]/[suggestion]/[nit]) | Step 2 severity rules |
| Test coverage context-sensitivity | Step 2 criterion 4 |
| Aggregate summary + recommended event type | Step 4 section |
| Anti-patterns table | Anti-Patterns section |
| Communication tone | Communication Tone section |
| gh CLI verification | Prerequisites section |
| JSON payload with --input | Step 7 section |
| diff hunk position explanation | Step 7 section |

Fix any gaps found before proceeding.

- [ ] **Step 4: Check for internal consistency**

Verify that:
- Every reference to `verification-subagent.md` matches the actual filename
- The event types listed in Step 4 (APPROVE/REQUEST_CHANGES/COMMENT) match those in the spec
- The severity labels used throughout are exactly `[blocking]`, `[suggestion]`, `[nit]` — no variations

- [ ] **Step 5: Commit any fixes**

```bash
git add skills/reviewing-github-prs/
git commit -m "fix: address self-review gaps in reviewing-github-prs"
```

If no gaps were found, skip this step.

---

## Task 7: Final verification

**Files:** none

- [ ] **Step 1: Verify the complete file structure**

```bash
find skills/reviewing-github-prs -type f
```

Expected output:
```
skills/reviewing-github-prs/SKILL.md
skills/reviewing-github-prs/verification-subagent.md
```

- [ ] **Step 2: Verify the skill name matches the directory**

```bash
grep "^name:" skills/reviewing-github-prs/SKILL.md
```

Expected: `name: reviewing-github-prs`

- [ ] **Step 3: Confirm the skill appears in session**

The skill will be available as `jeongri:reviewing-github-prs` once the plugin is reloaded. No action required — the file structure is all that's needed.

- [ ] **Step 4: Final commit if anything was missed**

```bash
git status
```

If clean, done. If there are uncommitted changes, stage and commit them now.
