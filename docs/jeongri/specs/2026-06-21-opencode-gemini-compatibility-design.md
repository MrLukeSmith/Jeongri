# Design: OpenCode and Gemini CLI compatibility config

**Date:** 2026-06-21
**Status:** Approved

## Overview

Add platform-specific configuration so the existing Jeongri skill collection can be discovered and used from OpenCode and Gemini CLI, mirroring the packaging approach used by `obra/superpowers`. No existing skills or the Claude plugin are changed; the work is purely additive.

The configuration includes an OpenCode plugin that auto-registers the repo's `skills/` directory, a Gemini CLI extension manifest plus context file, and install/usage documentation for both platforms. Bootstrap injection is intentionally out of scope for this change.

## Goals

- OpenCode users can install Jeongri as a plugin and have its four skills discovered by the `skill` tool.
- Gemini CLI users can install Jeongri as an extension and see its skills listed via `activate_skill`.
- Both platforms get clear install steps and a tool-mapping reference.
- Version numbers stay in sync across `.claude-plugin/plugin.json`, `.claude-plugin/marketplace.json`, and the new `gemini-extension.json`.
- A single script bumps all versioned manifests together.

## Non-goals

- No new bootstrap or `using-superpowers` skill.
- No changes to existing skill content.
- No auto-update mechanism beyond the git-backed plugin spec.

## New files and directory structure

```
Jeongri/
├── .claude-plugin/
│   ├── marketplace.json        (existing, unchanged)
│   └── plugin.json             (existing, unchanged)
├── .mise.toml                  (new)
├── .opencode/
│   ├── INSTALL.md              (new)
│   └── plugins/
│       └── jeongri.js          (new)
├── docs/
│   └── README.opencode.md      (new)
├── scripts/
│   └── bump-version.sh         (new)
├── GEMINI.md                   (new)
├── gemini-extension.json       (new)
└── skills/                     (existing, unchanged)
    ├── phasing/
    ├── reviewing-github-prs/
    ├── ruminate/
    └── writing-pr-descriptions/
```

## OpenCode plugin — `.opencode/plugins/jeongri.js`

A single ESM plugin that registers the repo's `skills/` directory in OpenCode's config.

Responsibilities:
- Add `path/to/repo/skills` to `config.skills.paths` if not already present.
- Do **not** inject bootstrap context (per scope decision).

Implementation sketch:

```js
import path from 'path';
import { fileURLToPath } from 'url';

const __dirname = path.dirname(fileURLToPath(import.meta.url));

export const JeongriPlugin = async () => ({
  config: async (config) => {
    config.skills = config.skills || {};
    config.skills.paths = config.skills.paths || [];
    const skillsDir = path.resolve(__dirname, '../../skills');
    if (!config.skills.paths.includes(skillsDir)) {
      config.skills.paths.push(skillsDir);
    }
  }
});
```

## OpenCode documentation

`.opencode/INSTALL.md`:
- How to add the plugin to `opencode.json` via a git-backed plugin spec.
- How to verify skills are discovered (`use skill tool to list skills`).
- How to load a skill.
- Brief troubleshooting.

`docs/README.opencode.md`:
- Full usage guide covering the same topics as `INSTALL.md` with more context.
- Tool mapping table for Jeongri skill actions to OpenCode tools.
- Update/pinning instructions.
- Per-skill examples (load `ruminate`, `phasing`, `reviewing-github-prs`, `writing-pr-descriptions`).

## Gemini CLI extension — `gemini-extension.json` + `GEMINI.md`

`gemini-extension.json`:

```json
{
  "name": "jeongri",
  "description": "A curated collection of opinionated skills for organising and cleaning up development.",
  "version": "1.0.2",
  "contextFileName": "GEMINI.md"
}
```

`GEMINI.md`:
- Short intro to the four skills and when to use them.
- Gemini CLI tool mapping table for skill actions.
- Usage example for activating a skill.
- Keep the file self-contained (no `@` imports) to avoid coupling to a bootstrap skill.

## Versioning

The versioned manifests are:

- `.claude-plugin/plugin.json`
- `.claude-plugin/marketplace.json` (`plugins[0].version`)
- `gemini-extension.json`

All start at `1.0.2` to match the current Claude plugin release. Future releases must bump all three together to avoid drift.

### Version bump script

`scripts/bump-version.sh` reads the current version from `.claude-plugin/plugin.json`, increments it by `patch`, `minor`, or `major`, and writes the new version to every versioned manifest using `jq`.

Dependency: `jq` is declared in `.mise.toml`:

```toml
[tools]
jq = "latest"
```

Usage:

```bash
./scripts/bump-version.sh patch
./scripts/bump-version.sh minor
./scripts/bump-version.sh major
```

Behaviour:

1. Parse the current version from `.claude-plugin/plugin.json`.
2. Validate the argument and bump the semver component.
3. Update each manifest in place with `jq`.
4. Print the new version.

Implementation sketch:

```bash
#!/usr/bin/env bash
set -euo pipefail

LEVEL="${1:-patch}"

current=$(jq -r '.version' .claude-plugin/plugin.json)

IFS='.' read -r major minor patch <<< "$current"

new=""
case "$LEVEL" in
  major) new="$((major + 1)).0.0" ;;
  minor) new="$major.$((minor + 1)).0" ;;
  patch) new="$major.$minor.$((patch + 1))" ;;
  *) echo "Usage: $0 {patch|minor|major}" >&2; exit 1 ;;
esac

jq --arg v "$new" '.version = $v' .claude-plugin/plugin.json > tmp.json && mv tmp.json .claude-plugin/plugin.json
jq --arg v "$new" '.plugins[0].version = $v' .claude-plugin/marketplace.json > tmp.json && mv tmp.json .claude-plugin/marketplace.json
jq --arg v "$new" '.version = $v' gemini-extension.json > tmp.json && mv tmp.json gemini-extension.json

echo "Bumped version to $new"
```

The OpenCode plugin (`.opencode/plugins/jeongri.js`) does not need its own version field; OpenCode resolves the plugin version from the git ref specified in `opencode.json`.

## Testing / verification

- After implementation, run `opencode run --print-logs "list skills"` and confirm the four Jeongri skills appear.
- For Gemini CLI, confirm the extension is loaded and `activate_skill ruminate` (or another Jeongri skill) responds with the skill content.
- Inspect the generated files for invalid JSON/Markdown and broken relative paths.
