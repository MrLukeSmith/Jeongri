# Reviewing GitHub PRs — Expanded Criteria Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Extend the `reviewing-github-prs` skill with two new review criteria (Justification Audit, Reviewer Cognitive Load), broaden criterion 6 to check for pre-existing abstractions, and soften the bikeshedding-naming anti-pattern so genuine naming problems can be flagged.

**Architecture:** Documentation-only change to a single skill file. Seven discrete edits applied in order, each committed separately. No code, no tests — verification is done by reading back the modified sections and confirming each new/changed block is present and well-formed.

**Tech Stack:** Markdown. Edits via the Edit tool. Verification via the Grep and Read tools.

**Spec:** [docs/jeongri/specs/2026-04-23-reviewing-github-prs-expanded-criteria-design.md](/home/luke/Personal/Jeongri/docs/jeongri/specs/2026-04-23-reviewing-github-prs-expanded-criteria-design.md)

**Single target file:** `/home/luke/Personal/Jeongri/skills/reviewing-github-prs/SKILL.md`

---

## Task 1: Soften the bikeshedding-naming anti-pattern

**Files:**
- Modify: `/home/luke/Personal/Jeongri/skills/reviewing-github-prs/SKILL.md:219`

Smallest, fully-independent edit — done first so the rest of the plan is easier to reason about.

- [ ] **Step 1: Read the current anti-pattern table**

Use the Read tool on `/home/luke/Personal/Jeongri/skills/reviewing-github-prs/SKILL.md` with `offset: 216, limit: 15`.

Confirm line 219 reads:

```
| Bikeshedding naming when the existing name is clear | Noise that obscures real findings |
```

- [ ] **Step 2: Make the edit**

Use the Edit tool on `/home/luke/Personal/Jeongri/skills/reviewing-github-prs/SKILL.md`:

**old_string:**
```
| Bikeshedding naming when the existing name is clear | Noise that obscures real findings |
```

**new_string:**
```
| Bikeshedding naming when the existing name is clear and unambiguous | Noise. Genuine stutter/ambiguity/misleading names belong under Codebase Consistency |
```

- [ ] **Step 3: Verify the edit**

Use the Grep tool:
- pattern: `Bikeshedding naming when the existing name is clear and unambiguous`
- path: `/home/luke/Personal/Jeongri/skills/reviewing-github-prs/SKILL.md`
- output_mode: `count`

Expected: exactly 1 match.

Also confirm the old phrasing is gone:
- pattern: `Bikeshedding naming when the existing name is clear \|`
- output_mode: `count`

Expected: 0 matches (no standalone "clear |" — it should now be "clear and unambiguous").

- [ ] **Step 4: Commit**

```bash
cd /home/luke/Personal/Jeongri && git add skills/reviewing-github-prs/SKILL.md && git commit -m "$(cat <<'EOF'
feat(pr-review): soften bikeshedding-naming anti-pattern

Allow genuine naming problems (stutter, ambiguity, misleading names) to be
flagged under Codebase Consistency. Still blocks preference-based nits.

Co-Authored-By: Claude Opus 4.7 (1M context) <noreply@anthropic.com>
EOF
)"
```

---

## Task 2: Broaden criterion 6 (Codebase Consistency)

**Files:**
- Modify: `/home/luke/Personal/Jeongri/skills/reviewing-github-prs/SKILL.md:97-99`

Adds an active check for pre-existing abstractions that the PR should be reusing.

- [ ] **Step 1: Read the current criterion 6 block**

Use the Read tool on `/home/luke/Personal/Jeongri/skills/reviewing-github-prs/SKILL.md` with `offset: 95, limit: 10`.

Confirm lines 97–99 read:

```
**6. Codebase Consistency** — Does this introduce a new pattern where one exists? Does it break established conventions identified in Step 1?
- `[suggestion]` in most cases
- `[blocking]` only if the inconsistency is likely to cause bugs (e.g. diverging from a safety convention)
```

- [ ] **Step 2: Make the edit**

Use the Edit tool on `/home/luke/Personal/Jeongri/skills/reviewing-github-prs/SKILL.md`:

**old_string:**
```
**6. Codebase Consistency** — Does this introduce a new pattern where one exists? Does it break established conventions identified in Step 1?
- `[suggestion]` in most cases
- `[blocking]` only if the inconsistency is likely to cause bugs (e.g. diverging from a safety convention)
```

**new_string:**
```
**6. Codebase Consistency** — Does this introduce a new pattern where one exists? Does it break established conventions identified in Step 1? Does it reimplement behaviour that an existing helper, abstraction, or test-support module already provides?
- `[suggestion]` in most cases, including when a pre-existing abstraction would fit better
- `[blocking]` only if the inconsistency is likely to cause bugs (e.g. diverging from a safety convention)

Before concluding "no findings" on this criterion, actively scan the codebase for helpers or modules whose names suggest overlap with what the PR adds (e.g. `*Switching`, `*Helper`, `Shared*`, or names close to the domain of the new code). The "Existing abstractions" note from Step 1 is the input.
```

- [ ] **Step 3: Verify the edit**

Use the Grep tool:
- pattern: `reimplement behaviour that an existing helper`
- path: `/home/luke/Personal/Jeongri/skills/reviewing-github-prs/SKILL.md`
- output_mode: `count`

Expected: 1 match.

- pattern: `Before concluding "no findings" on this criterion, actively scan`
- output_mode: `count`

Expected: 1 match.

- [ ] **Step 4: Commit**

```bash
cd /home/luke/Personal/Jeongri && git add skills/reviewing-github-prs/SKILL.md && git commit -m "$(cat <<'EOF'
feat(pr-review): broaden criterion 6 to flag reimplementation of existing abstractions

Adds an active check that runs before concluding "no findings" — scan for
helpers/modules whose names suggest overlap with what the PR adds.

Co-Authored-By: Claude Opus 4.7 (1M context) <noreply@anthropic.com>
EOF
)"
```

---

## Task 3: Add criterion 8 (Justification Audit)

**Files:**
- Modify: `/home/luke/Personal/Jeongri/skills/reviewing-github-prs/SKILL.md` — insert between current criterion 7 (ends line 102) and Step 3 heading (line 104).

This is the first of the two net-new criteria.

- [ ] **Step 1: Read the boundary between criterion 7 and Step 3**

Use the Read tool with `offset: 100, limit: 8`.

Confirm lines 101–104 look like:

```
**7. Scope Creep** — Does the PR do more than described? Does it mix unrelated concerns in a way that makes review harder or rollback riskier?
- `[suggestion]` always — sometimes scope creep is valid, but worth surfacing

### Step 3 — Verification Pass
```

- [ ] **Step 2: Make the edit**

The anchor for the Edit tool is the criterion 7 block + the blank line + the Step 3 heading. Insert criterion 8 between them.

Use the Edit tool on `/home/luke/Personal/Jeongri/skills/reviewing-github-prs/SKILL.md`:

**old_string:**
```
**7. Scope Creep** — Does the PR do more than described? Does it mix unrelated concerns in a way that makes review harder or rollback riskier?
- `[suggestion]` always — sometimes scope creep is valid, but worth surfacing

### Step 3 — Verification Pass
```

**new_string:**
````
**7. Scope Creep** — Does the PR do more than described? Does it mix unrelated concerns in a way that makes review harder or rollback riskier?
- `[suggestion]` always — sometimes scope creep is valid, but worth surfacing

**8. Justification Audit** — Interrogate the *why* behind non-obvious changes. Comments for this criterion default to **questions, not assertions** — the one criterion in the skill where a clarifying question is the desired output.

Triggers:
- **Deletions** of code, tests, or test-support helpers without evident reason — ask: "why is this safe to remove now?"
- **Defensive guards** added without a named failure mode (`&.`, `respond_to?`, new `rescue`) — ask: "what scenario does this protect against? If it's a bug, should we surface it instead of silencing it?"
- **Workarounds** — new subclasses, monkey-patches, config overrides, or test-support patches that bypass rather than fix the source — ask: "what is the underlying issue, and why can't we address it there?"
- **New classes, modules, or services without a class-level comment** explaining their purpose, especially when the class exists as a workaround.
- **Undocumented changes** — diff content not mentioned in the PR description. Flag the specific change and ask that the description be updated.

- `[suggestion]` — default. The change looks reasonable but needs a documented rationale.
- `[blocking]` — rare. Use only when the unexplained change carries real risk: a defensive guard that may hide a correctness bug, or a deletion of behaviour that is load-bearing elsewhere.

Prefer `"Why X?"` or `"What happens when Y?"` over assertions. The rest of the skill's communication guidance (direct, no hedging, no filler) still applies — a question can be short and direct.

### Step 3 — Verification Pass
````

- [ ] **Step 3: Verify the edit**

Use the Grep tool:
- pattern: `^\*\*8\. Justification Audit\*\*`
- path: `/home/luke/Personal/Jeongri/skills/reviewing-github-prs/SKILL.md`
- output_mode: `count`

Expected: 1 match.

- pattern: `questions, not assertions`
- output_mode: `count`

Expected: 1 match.

- pattern: `Undocumented changes`
- output_mode: `count`

Expected: 1 match.

Also confirm criterion 7 still exists and Step 3 heading still exists:
- pattern: `^### Step 3 — Verification Pass$`
- output_mode: `count`

Expected: 1 match.

- [ ] **Step 4: Commit**

```bash
cd /home/luke/Personal/Jeongri && git add skills/reviewing-github-prs/SKILL.md && git commit -m "$(cat <<'EOF'
feat(pr-review): add criterion 8 (Justification Audit)

Interrogates the why behind non-obvious changes (deletions, defensive guards,
workarounds, undocumented additions). Comments for this criterion default to
questions rather than assertions.

Co-Authored-By: Claude Opus 4.7 (1M context) <noreply@anthropic.com>
EOF
)"
```

---

## Task 4: Add criterion 9 (Reviewer Cognitive Load)

**Files:**
- Modify: `/home/luke/Personal/Jeongri/skills/reviewing-github-prs/SKILL.md` — insert between criterion 8 (added in Task 3) and the Step 3 heading.

- [ ] **Step 1: Read the boundary between criterion 8 and Step 3**

Use the Read tool to locate the final paragraph of criterion 8 (ends with `a question can be short and direct.`) and the `### Step 3 — Verification Pass` heading that follows.

Use `offset: 100, limit: 30` — read a wider window to confirm the surrounding text after Task 3's edit.

- [ ] **Step 2: Make the edit**

The new criterion 9 contains a fenced code block. The Edit tool's `old_string` and `new_string` are plain strings, so the triple-backticks inside the new content work as-is.

Use the Edit tool on `/home/luke/Personal/Jeongri/skills/reviewing-github-prs/SKILL.md`:

**old_string:**
```
Prefer `"Why X?"` or `"What happens when Y?"` over assertions. The rest of the skill's communication guidance (direct, no hedging, no filler) still applies — a question can be short and direct.

### Step 3 — Verification Pass
```

**new_string:**
````
Prefer `"Why X?"` or `"What happens when Y?"` over assertions. The rest of the skill's communication guidance (direct, no hedging, no filler) still applies — a question can be short and direct.

**9. Reviewer Cognitive Load** — Independent of scope coherence. Even a perfectly-scoped PR can be too much for a human reviewer to hold in their head and review competently. Agents can process arbitrary complexity; humans cannot — the goal of the review is to serve the human reviewer, not replace them.

Triggers (judgment, not strict thresholds):
- The diff contains multiple independent logical concerns that could each stand alone
- The PR description's section count under-represents the number of concerns in the diff
- A single concern's code change is small, but its support changes (test helpers, config, log suppression) are large and independently reviewable

When triggered, produce a **top-level decomposition proposal** in the aggregate summary — never an inline comment:

```
Suggested decomposition (optional — this PR is coherent, just large for one review pass):

PR 1 (standalone): <what it does>. Files: <paths>.
PR 2 (depends on PR 1): <what it does>. Files: <paths>.
PR 3: <what it does>. Files: <paths>.
```

One sentence per PR. Name files only when it clarifies the split. Dependencies must be explicit (`standalone`, `depends on PR N`). Three to five PRs is typical.

- `[suggestion]` — always. Never blocks merge. Never produces an inline comment — the decomposition is PR-level by nature.

If the PR is appropriately sized for one review pass, write `No findings` and move on — do not manufacture a decomposition.

### Step 3 — Verification Pass
````

**Note on the fenced block inside `new_string`:** this plan file wraps the new content in `````` (four-backtick) fences so the inner ``` (three-backtick) fence is displayed literally. The text passed to the Edit tool should contain normal three-backtick fences as shown above between "never an inline comment:" and "One sentence per PR."

- [ ] **Step 3: Verify the edit**

Use the Grep tool:
- pattern: `^\*\*9\. Reviewer Cognitive Load\*\*`
- path: `/home/luke/Personal/Jeongri/skills/reviewing-github-prs/SKILL.md`
- output_mode: `count`

Expected: 1 match.

- pattern: `Suggested decomposition \(optional`
- output_mode: `count`

Expected: 1 match.

- pattern: `PR 1 \(standalone\)`
- output_mode: `count`

Expected: 1 match.

Also re-confirm criterion 8 is intact and Step 3 heading is intact:
- pattern: `Justification Audit`
- output_mode: `count`

Expected: 1 match.

- pattern: `^### Step 3 — Verification Pass$`
- output_mode: `count`

Expected: 1 match.

- [ ] **Step 4: Commit**

```bash
cd /home/luke/Personal/Jeongri && git add skills/reviewing-github-prs/SKILL.md && git commit -m "$(cat <<'EOF'
feat(pr-review): add criterion 9 (Reviewer Cognitive Load)

Assesses whether the PR is too large for a human to hold in head and review
competently. When triggered, produces a PR-level decomposition proposal in the
aggregate summary. Always [suggestion]; never blocks merge.

Co-Authored-By: Claude Opus 4.7 (1M context) <noreply@anthropic.com>
EOF
)"
```

---

## Task 5: Update the three "seven criteria" references to "nine"

**Files:**
- Modify: `/home/luke/Personal/Jeongri/skills/reviewing-github-prs/SKILL.md:53,65,74`

Three separate references in Step 2. All three need updating.

- [ ] **Step 1: Locate every reference to "seven"**

Use the Grep tool:
- pattern: `seven`
- path: `/home/luke/Personal/Jeongri/skills/reviewing-github-prs/SKILL.md`
- output_mode: `content`
- `-n`: true

Expected: three matches on lines 53, 65, 74 (or similar — line numbers may have shifted after Tasks 2–4 added content). If more than three matches appear, stop and investigate before editing — there may be unexpected references that shouldn't be changed.

- [ ] **Step 2: Update reference 1 — line 53**

Use the Edit tool on `/home/luke/Personal/Jeongri/skills/reviewing-github-prs/SKILL.md`:

**old_string:**
```
Work through all seven criteria in order. For each, assess the diff against the codebase context from Step 1. **Every criterion must produce an explicit entry** — write this list in your response before proceeding to Step 3.
```

**new_string:**
```
Work through all nine criteria in order. For each, assess the diff against the codebase context from Step 1. **Every criterion must produce an explicit entry** — write this list in your response before proceeding to Step 3.
```

- [ ] **Step 3: Update reference 2 — line 65**

Use the Edit tool:

**old_string:**
```
All seven criteria must appear in the list. `No findings` is a valid and expected result — do not manufacture observations to fill it.
```

**new_string:**
```
All nine criteria must appear in the list. `No findings` is a valid and expected result — do not manufacture observations to fill it.
```

- [ ] **Step 4: Update reference 3 — line 74**

Use the Edit tool:

**old_string:**
```
**The seven criteria:**
```

**new_string:**
```
**The nine criteria:**
```

- [ ] **Step 5: Verify all three updates landed**

Use the Grep tool:
- pattern: `seven criteria`
- path: `/home/luke/Personal/Jeongri/skills/reviewing-github-prs/SKILL.md`
- output_mode: `count`

Expected: 0 matches.

- pattern: `nine criteria`
- output_mode: `count`

Expected: 3 matches (one for each updated reference).

- pattern: `The nine criteria:`
- output_mode: `count`

Expected: 1 match.

- [ ] **Step 6: Commit**

```bash
cd /home/luke/Personal/Jeongri && git add skills/reviewing-github-prs/SKILL.md && git commit -m "$(cat <<'EOF'
chore(pr-review): update "seven criteria" references to "nine"

Reflects the addition of criteria 8 (Justification Audit) and 9 (Reviewer
Cognitive Load).

Co-Authored-By: Claude Opus 4.7 (1M context) <noreply@anthropic.com>
EOF
)"
```

---

## Task 6: Add decomposition-block guidance to Step 4

**Files:**
- Modify: `/home/luke/Personal/Jeongri/skills/reviewing-github-prs/SKILL.md:149-153` (aggregate-summary bullets — line numbers will have shifted after Tasks 2–4; anchor by exact text)

Step 4 (Draft Review) currently describes how to write the aggregate summary but doesn't mention criterion 9's decomposition block. This task adds that guidance.

- [ ] **Step 1: Locate the aggregate-summary bullet list**

Use the Grep tool:
- pattern: `If approving with suggestions: say so explicitly so the author knows they can merge`
- path: `/home/luke/Personal/Jeongri/skills/reviewing-github-prs/SKILL.md`
- output_mode: `content`
- `-n`: true
- `-B`: 4

Expected: 1 match with surrounding context showing the four existing bullets.

- [ ] **Step 2: Make the edit**

Use the Edit tool on `/home/luke/Personal/Jeongri/skills/reviewing-github-prs/SKILL.md`:

**old_string:**
```
After all per-comment findings, write an **aggregate summary** (2–3 sentences):
- State the overall picture
- Include the **recommended event type** — what you would submit if you were submitting: `APPROVE`, `REQUEST_CHANGES`, or `COMMENT`
- If requesting changes: name the specific blocking issues by name
- If approving with suggestions: say so explicitly so the author knows they can merge
```

**new_string:**
```
After all per-comment findings, write an **aggregate summary** (2–3 sentences):
- State the overall picture
- Include the **recommended event type** — what you would submit if you were submitting: `APPROVE`, `REQUEST_CHANGES`, or `COMMENT`
- If requesting changes: name the specific blocking issues by name
- If approving with suggestions: say so explicitly so the author knows they can merge
- **If criterion 9 produced a finding**, append the "Suggested decomposition" block to the aggregate summary body. The decomposition is PR-level and does not go in the inline `comments` array of the GitHub API payload.
```

- [ ] **Step 3: Verify the edit**

Use the Grep tool:
- pattern: `If criterion 9 produced a finding`
- path: `/home/luke/Personal/Jeongri/skills/reviewing-github-prs/SKILL.md`
- output_mode: `count`

Expected: 1 match.

- pattern: `Suggested decomposition`
- output_mode: `count`

Expected: 2 matches (one in criterion 9's body from Task 4, one here in Step 4).

- [ ] **Step 4: Commit**

```bash
cd /home/luke/Personal/Jeongri && git add skills/reviewing-github-prs/SKILL.md && git commit -m "$(cat <<'EOF'
feat(pr-review): wire criterion 9's decomposition block into Step 4

Aggregate-summary bullet list now explicitly calls out that a decomposition
block, when produced, goes in the summary body — not in the inline comments
array of the GitHub API payload.

Co-Authored-By: Claude Opus 4.7 (1M context) <noreply@anthropic.com>
EOF
)"
```

---

## Task 7: Full structural verification

**Files:** None modified — verification only. Commits only if a gap is found.

Confirms the skill file is consistent and well-formed after Tasks 1–6.

- [ ] **Step 1: Confirm all nine criteria are present**

Use the Grep tool:
- pattern: `^\*\*[1-9]\. `
- path: `/home/luke/Personal/Jeongri/skills/reviewing-github-prs/SKILL.md`
- output_mode: `content`
- `-n`: true

Expected: exactly 9 matches, numbered 1 through 9 in order:
1. Correctness
2. Error & Edge Case Handling
3. Security
4. Test Coverage
5. Complexity
6. Codebase Consistency
7. Scope Creep
8. Justification Audit
9. Reviewer Cognitive Load

- [ ] **Step 2: Confirm the "seven" → "nine" migration is clean**

Use the Grep tool:
- pattern: `\bseven\b`
- path: `/home/luke/Personal/Jeongri/skills/reviewing-github-prs/SKILL.md`
- output_mode: `content`
- `-n`: true
- `-i`: true

Expected: 0 matches. If any remain, investigate — they may be legitimate unrelated uses, or a missed reference from Task 5.

- [ ] **Step 3: Confirm the anti-pattern softening is in place**

Use the Grep tool:
- pattern: `clear and unambiguous`
- path: `/home/luke/Personal/Jeongri/skills/reviewing-github-prs/SKILL.md`
- output_mode: `count`

Expected: 1 match.

- [ ] **Step 4: Confirm Step 4 references criterion 9**

Use the Grep tool:
- pattern: `criterion 9 produced a finding`
- path: `/home/luke/Personal/Jeongri/skills/reviewing-github-prs/SKILL.md`
- output_mode: `count`

Expected: 1 match.

- [ ] **Step 5: Read the full "nine criteria" block end-to-end**

Use the Read tool on `/home/luke/Personal/Jeongri/skills/reviewing-github-prs/SKILL.md` with `offset: 74, limit: 80` (line range will have shifted — adjust so the read starts at `**The nine criteria:**` and ends at `### Step 3 — Verification Pass`).

Visually confirm:
- The nine criteria appear in numerical order with no gaps
- Criterion 6's "Before concluding 'no findings'" paragraph is present and positioned correctly
- Criterion 8's "Triggers" block and severity bullets are present
- Criterion 9's fenced "Suggested decomposition" code block is present and the fences are correctly paired
- The blank line / separation between criteria is consistent

If any structural issue is found, open a corrective edit and re-run Step 5. Then commit the fix with a message describing what was corrected.

- [ ] **Step 6: Confirm git log reflects the change set**

```bash
cd /home/luke/Personal/Jeongri && git log --oneline -10
```

Expected: the six feature/chore commits from Tasks 1–6 visible, in order (most recent first):
- `feat(pr-review): wire criterion 9's decomposition block into Step 4`
- `chore(pr-review): update "seven criteria" references to "nine"`
- `feat(pr-review): add criterion 9 (Reviewer Cognitive Load)`
- `feat(pr-review): add criterion 8 (Justification Audit)`
- `feat(pr-review): broaden criterion 6 to flag reimplementation of existing abstractions`
- `feat(pr-review): soften bikeshedding-naming anti-pattern`

Preceded by the earlier spec commit (`docs: spec for expanded PR-review criteria`).

- [ ] **Step 7: Report completion**

Report to the user that Tasks 1–7 are complete, the branch is `refine-pr-review`, and the skill is ready for the validation step from the spec (re-run against PR #13025 and compare to Konrad's review). Do not run the validation automatically — it produces a live draft review on GitHub and the user should decide when to trigger that.

---

## Self-review (to be done before handing the plan off)

**Spec coverage check:**
- Criterion 6 broadening → Task 2 ✓
- Criterion 8 (Justification Audit) → Task 3 ✓
- Criterion 9 (Reviewer Cognitive Load) → Task 4 ✓
- Bikeshedding anti-pattern softening → Task 1 ✓
- "Seven → nine" references updated → Task 5 ✓
- Step 4 decomposition-block wiring → Task 6 ✓
- Final structural check → Task 7 ✓

**Placeholder scan:** no TBD / TODO / "fill in later" present. Every edit shows the exact `old_string` and `new_string` the executor will use.

**Type/signature consistency:** N/A — no code. The only cross-task consistency requirement is that criterion numbers (`8.`, `9.`) and references to them (`criterion 9 produced a finding`) are used identically in Tasks 3, 4, and 6. Verified by direct string match.

**Scope:** single file, single skill. Plan is appropriately scoped for one execution pass.
