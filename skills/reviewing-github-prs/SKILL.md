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
