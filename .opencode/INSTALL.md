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

You should see `phasing`, `reviewing-github-prs`, `ruminate`, `windpiss`, and `writing-pr-descriptions`.

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
