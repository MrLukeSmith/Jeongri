# Jeongri for OpenCode

Complete guide for using Jeongri with [OpenCode.ai](https://opencode.ai).

## Installation

See `.opencode/INSTALL.md` for plugin setup.

## Finding skills

Use OpenCode's native `skill` tool:

```
use skill tool to list skills
```

## Loading a skill

```
use skill tool to load ruminate
```

Or for codebase review:

```
use skill tool to load reviewing-github-prs
```

## Available skills

- `phasing` — decompose a large project into ordered phases.
- `reviewing-github-prs` — structured GitHub PR review.
- `ruminate` — explore requirements and produce a design spec.
- `windpiss` — guided Socratic ideation from a vague idea to a lightly structured capture.
- `writing-pr-descriptions` — write reviewer-focused PR descriptions.

## Tool mapping

Jeongri skills speak in platform-agnostic actions. On OpenCode these resolve to:

| Action | OpenCode tool |
|---|---|
| Create or update todos | `todowrite` |
| Dispatch a subagent (general-purpose) | `task` with `subagent_type: "general"` |
| Invoke a skill | `skill` |
| Read a file | `read` |
| Create, edit, or delete files | `apply_patch` |
| Run a shell command | `bash` |
| Search file contents | `grep` |
| Find files by name | `glob` |
| Fetch a URL | `webfetch` |

## Updating

OpenCode installs Jeongri through a git-backed plugin spec. If updates do not appear after a restart, clear OpenCode's package cache or reinstall the plugin.
