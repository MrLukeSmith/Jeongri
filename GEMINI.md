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