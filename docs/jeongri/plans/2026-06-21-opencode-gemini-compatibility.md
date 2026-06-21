# OpenCode and Gemini CLI compatibility config — Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Add OpenCode and Gemini CLI packaging/config so the existing Jeongri skills are discoverable on those platforms, plus a Bash/jq version-bump script and mise config to keep manifest versions in sync.

**Architecture:** Mirror the `obra/superpowers` multi-platform packaging pattern: an OpenCode plugin auto-registers the repo `skills/` directory, a Gemini CLI extension manifest points to a root `GEMINI.md` context file, and install docs live under `.opencode/` and `docs/`. A small Bash script backed by `jq` updates the three versioned manifests together.

**Tech Stack:** Bash, `jq`, JavaScript ESM (OpenCode plugin), Markdown, TOML (mise).

## Global Constraints

- No new bootstrap or `using-superpowers` skill.
- No changes to existing skill content.
- No auto-update mechanism beyond the git-backed plugin spec.
- All versioned manifests start at `1.0.2` to match the current Claude plugin release.
- The OpenCode plugin does not inject bootstrap context — it only registers the `skills/` directory.
- `GEMINI.md` must be self-contained (no `@` imports).

---

### Task 1: Declare `jq` dependency in mise config

**Files:**
- Create: `.mise.toml`

**Interfaces:**
- Produces: `.mise.toml` with a `[tools]` section declaring `jq`.

- [ ] **Step 1: Create `.mise.toml`**

```toml
[tools]
jq = "latest"
```

- [ ] **Step 2: Verify the file is valid TOML and jq is available**

Run: `mise install && mise exec -- jq --version`
Expected: `jq-` prefix followed by a version number.

- [ ] **Step 3: Commit**

```bash
git add .mise.toml
git commit -m "chore: declare jq dependency for release scripts"
```

---

### Task 2: Create OpenCode plugin

**Files:**
- Create: `.opencode/plugins/jeongri.js`

**Interfaces:**
- Produces: ESM export `JeongriPlugin` with a `config` hook that mutates `config.skills.paths`.
- Consumes: the repo root-relative `skills/` directory.

- [ ] **Step 1: Create `.opencode/plugins/jeongri.js`**

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

- [ ] **Step 2: Validate JavaScript syntax**

Run:
```bash
node --check --input-type=module < .opencode/plugins/jeongri.js
```
Expected: `SYNTAX OK` (the file is ESM; Node defaults `.js` to CommonJS without a `package.json` declaring `"type": "module"`, so the literal `node --check` invocation would fail with `SyntaxError: Cannot use import statement outside a module`).

- [ ] **Step 3: Commit**

```bash
git add .opencode/plugins/jeongri.js
git commit -m "feat(opencode): add plugin to register skills directory"
```

---

### Task 3: Create Gemini CLI extension manifest

**Files:**
- Create: `gemini-extension.json`

**Interfaces:**
- Produces: valid extension manifest with `name`, `description`, `version`, and `contextFileName`.

- [ ] **Step 1: Create `gemini-extension.json`**

```json
{
  "name": "jeongri",
  "description": "A curated collection of opinionated skills for organising and cleaning up development.",
  "version": "1.0.2",
  "contextFileName": "GEMINI.md"
}
```

- [ ] **Step 2: Validate JSON**

Run: `jq . gemini-extension.json`
Expected: pretty-printed JSON matching the file contents.

- [ ] **Step 3: Commit**

```bash
git add gemini-extension.json
git commit -m "feat(gemini): add extension manifest"
```

---

### Task 4: Create `GEMINI.md` context file

**Files:**
- Create: `GEMINI.md`

**Interfaces:**
- Produces: self-contained context file describing the existing Jeongri skills and Gemini tool mappings.

- [ ] **Step 1: Create `GEMINI.md`**

````markdown
# Jeongri for Gemini CLI

Jeongri (정리) is a collection of opinionated skills for cleaning up and organising development work.

## Available skills

- `phasing` — decompose a large project into ordered, buildable phases.
- `reviewing-github-prs` — structured GitHub pull-request review.
- `ruminate` — explore requirements and produce a design spec.
- `writing-pr-descriptions` — write reviewer-focused PR descriptions.

Activate any skill with:

```
activate_skill <skill-name>
```

## Tool mapping

Jeongri skills speak in platform-agnostic actions. On Gemini CLI these resolve to:

| Action | Gemini CLI tool |
|---|---|
| Read a file | `read_file` |
| Read multiple files | `read_many_files` |
| Create a file | `write_file` |
| Edit a file | `replace` |
| Run a shell command | `run_shell_command` |
| Search file contents | `grep_search` |
| Find files by name | `glob` |
| List files and subdirectories | `list_directory` |
| Fetch a URL | `web_fetch` |
| Invoke a skill | `activate_skill` |
| Dispatch a subagent | `invoke_agent` with `agent_name: "generalist"` |
| Create or update todos | `write_todos` |
````

- [ ] **Step 2: Verify Markdown renders and has no `@` imports**

Run:
```bash
grep -E '^@' GEMINI.md && echo "FAIL: found @ import" || echo "OK: no @ imports"
```
Expected: `OK: no @ imports`.

- [ ] **Step 3: Commit**

```bash
git add GEMINI.md
git commit -m "feat(gemini): add Gemini CLI context file"
```

---

### Task 5: Create OpenCode install docs

**Files:**
- Create: `.opencode/INSTALL.md`

**Interfaces:**
- Produces: install guide for adding the plugin to `opencode.json`.

- [ ] **Step 1: Create `.opencode/INSTALL.md`**

````markdown
# Installing Jeongri for OpenCode

## Prerequisites

- [OpenCode.ai](https://opencode.ai) installed

## Installation

Add Jeongri to the `plugin` array in your `opencode.json` (global or project-level):

```json
{
  "plugin": ["jeongri@git+https://github.com/MrLukeSmith/Jeongri.git"]
}
```

Restart OpenCode. The plugin registers the `skills/` directory automatically.

Verify by asking:

```
use skill tool to list skills
```

You should see `phasing`, `reviewing-github-prs`, `ruminate`, and `writing-pr-descriptions`.

## Pinning a version

To stay on a specific release:

```json
{
  "plugin": ["jeongri@git+https://github.com/MrLukeSmith/Jeongri.git#v1.0.2"]
}
```

## Troubleshooting

- Make sure the plugin loaded: `opencode run --print-logs "list skills" 2>&1 | grep -i jeongri`.
- If skills do not appear, use the `skill` tool to inspect discovered paths.
````

- [ ] **Step 2: Verify Markdown**

Run: `ls -la .opencode/INSTALL.md`
Expected: file exists.

- [ ] **Step 3: Commit**

```bash
git add .opencode/INSTALL.md
git commit -m "docs(opencode): add install instructions"
```

---

### Task 6: Create OpenCode usage guide

**Files:**
- Create: `docs/README.opencode.md`

**Interfaces:**
- Produces: full usage guide with tool mapping and per-skill examples.

- [ ] **Step 1: Create `docs/README.opencode.md`**

````markdown
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
````

- [ ] **Step 2: Verify Markdown and relative references**

Run:
```bash
ls -la docs/README.opencode.md
grep -F '.opencode/INSTALL.md' docs/README.opencode.md
```
Expected: file exists and contains a reference to the install doc.

- [ ] **Step 3: Commit**

```bash
git add docs/README.opencode.md
git commit -m "docs(opencode): add usage guide"
```

---

### Task 7: Create version bump script

**Files:**
- Create: `scripts/bump-version.sh`

**Interfaces:**
- Consumes: `.claude-plugin/plugin.json` (source of current version), `.claude-plugin/marketplace.json`, `gemini-extension.json`.
- Produces: in-place updated manifests with the bumped version.

- [ ] **Step 1: Create `scripts/bump-version.sh`**

```bash
#!/usr/bin/env bash
set -euo pipefail

LEVEL="${1:-patch}"

current=$(jq -r '.version' .claude-plugin/plugin.json)

IFS='.' read -r major minor patch <<< "$current"

case "$LEVEL" in
  major) new="$((major + 1)).0.0" ;;
  minor) new="$major.$((minor + 1)).0" ;;
  patch) new="$major.$minor.$((patch + 1))" ;;
  *) echo "Usage: $0 {patch|minor|major}" >&2; exit 1 ;;
esac

jq --arg v "$new" '.version = $v' .claude-plugin/plugin.json > .claude-plugin/plugin.json.tmp
mv .claude-plugin/plugin.json.tmp .claude-plugin/plugin.json

jq --arg v "$new" '.plugins[0].version = $v' .claude-plugin/marketplace.json > .claude-plugin/marketplace.json.tmp
mv .claude-plugin/marketplace.json.tmp .claude-plugin/marketplace.json

jq --arg v "$new" '.version = $v' gemini-extension.json > gemini-extension.json.tmp
mv gemini-extension.json.tmp gemini-extension.json

echo "Bumped version to $new"
```

- [ ] **Step 2: Make it executable and validate syntax**

Run:
```bash
chmod +x scripts/bump-version.sh
bash -n scripts/bump-version.sh
```
Expected: no output from `bash -n`.

- [ ] **Step 3: Test the script in a temporary copy**

Run:
```bash
rm -rf /tmp/jeongri-bump-test
mkdir -p /tmp/jeongri-bump-test
cp .claude-plugin/plugin.json .claude-plugin/marketplace.json gemini-extension.json scripts/bump-version.sh /tmp/jeongri-bump-test/
(
  cd /tmp/jeongri-bump-test
  ./bump-version.sh patch
  jq -r '.version' plugin.json
  jq -r '.plugins[0].version' marketplace.json
  jq -r '.version' gemini-extension.json
)
```
Expected: all three `jq` commands output `1.0.3`.

- [ ] **Step 4: Commit**

```bash
git add scripts/bump-version.sh
git commit -m "feat(release): add version bump script"
```

---

### Task 8: Final verification

**Files:**
- Verify: all new files from previous tasks.

**Interfaces:**
- Consumes: `.mise.toml`, `.opencode/plugins/jeongri.js`, `gemini-extension.json`, `GEMINI.md`, `.opencode/INSTALL.md`, `docs/README.opencode.md`, `scripts/bump-version.sh`.

- [ ] **Step 1: Validate all JSON files**

Run:
```bash
jq . .claude-plugin/plugin.json > /dev/null
jq . .claude-plugin/marketplace.json > /dev/null
jq . gemini-extension.json > /dev/null
```
Expected: all three commands exit `0`.

- [ ] **Step 2: Validate OpenCode plugin syntax**

Run: `node --check .opencode/plugins/jeongri.js`
Expected: no output.

- [ ] **Step 3: Validate version bump script syntax**

Run: `bash -n scripts/bump-version.sh`
Expected: no output.

- [ ] **Step 4: Confirm file tree matches the spec**

Run:
```bash
find .mise.toml .opencode/plugins/jeongri.js .opencode/INSTALL.md docs/README.opencode.md GEMINI.md gemini-extension.json scripts/bump-version.sh -type f
```
Expected: list of all seven files.

- [ ] **Step 5: Commit any final fixes and final check**

If any fixes were needed, commit them. Then run:

```bash
git log --oneline -8
```

Expected: eight commits covering Tasks 1–7 plus any fixups, ending with the final verification state.

---

## Self-review

**Spec coverage:**
- `.mise.toml` with `jq` → Task 1.
- OpenCode plugin registering `skills/` → Task 2.
- OpenCode install docs → Task 5.
- OpenCode full usage guide → Task 6.
- Gemini extension manifest → Task 3.
- Gemini context file (`GEMINI.md`) → Task 4.
- Version bump script → Task 7.
- Final verification → Task 8.

**Placeholder scan:**
- No `TBD`, `TODO`, or vague steps.
- Every file creation step contains the complete file content.
- Every verification step contains exact commands and expected output.

**Type consistency:**
- Plugin export is `JeongriPlugin` in both code and task description.
- Manifest version field paths match the actual JSON shape (`plugins[0].version` for `marketplace.json`).
- The bump script writes to the same three files listed in the spec.
