# Jeongri for OpenCode / Agents

OpenCode-specific notes for working in this repo. Skills live under `skills/` and are loaded with the `skill` tool.

## Commit attribution

When an agent creates a commit, append this trailer to the commit message:

```
Co-authored-by: <model-name>
```

Replace `<model-name>` with the model currently powering the agent (e.g. the value reported in the agent's runtime or system info) — adapt it per model rather than treating any one name as fixed. No email — keep it as a bare name. Add it as the last line of the commit body, separated by a blank line from the message text.