---
name: writing-pr-descriptions
description: Use when creating a pull request to generate a reviewer-facing PR description that cuts fluff and focuses on what matters
---

# Writing PR Descriptions

## Overview

A PR description exists for the reviewer, not the author. Only write what a reviewer cannot determine from the diff itself.

**Announce at start:** "I'm using the writing-pr-descriptions skill to write the PR description."

## The Process

### Step 1: Check for a PR template

Look for a project PR template in order:
1. `.github/PULL_REQUEST_TEMPLATE.md`
2. `.github/pull_request_template.md`
3. `.github/PULL_REQUEST_TEMPLATE/` (directory)
4. `docs/pull_request_template.md`
5. `*/pull_request_template.md`

### Step 2: Read the diff and commits

```bash
# Diff against base branch
git diff <base>...HEAD

# Commits on this branch (full messages)
git log <base>..HEAD
```

Read the design doc if one exists — for context on intent, not to copy from. Check for commited plans on the current working tree or use the chat context to determine the location of the design documents or plans.

### Step 3: Ask for context

Before writing, ask the user the following questions in a single message. Wait for their response before proceeding.

- **Rationale:** What was the motivation or justification for this work? (e.g. a bug report, a product decision, a performance problem)
- **Related changes:** Are there any related PRs, issues, or external links to reference?
- **Anything else:** Is there anything non-obvious the reviewer should know that isn't clear from the diff or commits?

Accept partial answers — if the user skips a question, infer what you can from the diff and commits.

### Step 4: Write the description

**If a PR template exists:** Fill it in following the rules below. Don't pad sections with filler to seem thorough. If a template section has nothing reviewer-relevant to say, write "N/A" or a single sentence. Respect the template structure; the fluff rules still apply.

**If no PR template exists:** Use this format:

```markdown
## Why

<1-2 sentences: why this change exists, linking to issue/prior PRs if relevant>

## Watch out for

- <Only items needing reviewer attention>
```

Omit "Watch out for" entirely if there's nothing to flag.

## What Belongs

- Why this change exists (1 sentence of context)
- Breaking changes or migration steps
- Things that look wrong but are intentional (and why)
- Decisions that were controversial or non-obvious
- Risks the reviewer should evaluate

## What Does NOT Belong

- Anything visible in the diff ("added specs", "replaced X with Y", "updated callers")
- Commit structure explanations — the reviewer can see the commits
- Things you didn't change ("ManualX was not migrated")
- What you preserved — only mention what you *didn't* preserve
- Narration of your implementation process

## Format Rules

- Never exceed ~10 lines of your content (template boilerplate doesn't count)
- A mostly-empty PR description is better than a padded one
- Link related PRs/issues inline, not in dedicated sections

## Anti-Patterns

| Don't write this | Why | Instead |
|---|---|---|
| "Added comprehensive specs adapted from existing coverage" | Reviewer sees the specs | *(omit)* |
| "Replaced X callback with Y" | Visible in the diff | *(omit)* |
| "The current-1 offset is preserved" | Tell what changed, not what didn't | Flag what's *different* |
| "Commit structure: 4 commits for clarity" | Reviewer sees the commits | *(omit)* |
| "ManualX was not migrated (unused)" | Don't mention what you didn't do | *(omit)* |
| "Updated caller tests for ActiveJob patterns" | Narrating the diff | *(omit)* |

**The pattern:** If "Instead" is *(omit)*, delete the line entirely — don't reword it.

## Red Flags

**Never:**
- Narrate what the diff shows
- Pad sections to seem thorough
- Copy-paste from the design doc or plan
- Describe your commit strategy

**Always:**
- Check for a project PR template first
- Read the full diff before writing
- Ask: "Would the reviewer learn this from the diff?" — if yes, cut it
