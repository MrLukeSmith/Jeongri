---
name: auditing-vulnerabilities
description: Use when asked to audit a codebase, folder, or file for security vulnerabilities — fans out per-unit analysts over a fixed CWE/OWASP checklist, verifies high-severity findings by refutation, and writes a severity-ranked report with exploitability and certainty scores
---

# Auditing Vulnerabilities

Scope-targeted security audit that evaluates a repo, folder, or file for exploitable flaws and produces a severity-ranked report, each finding carrying two independent confidence scores — exploitability and analyst-certainty. The skill reuses the analysis → verify → report spine established by `reviewing-github-prs`, adapted from diff review to whole-scope audit, and is built around one goal stated explicitly by the user: be as deterministic as an LLM can be. Four structural levers serve that goal: a fixed, enumerated CWE/OWASP checklist every analyst walks in the same order, forced to log an explicit entry per category; structured JSON output schemas so the shape of a finding is stable across runs and units; an adversarial refutation verification pass on every high-severity finding; and numeric confidence gates rather than subjective judgment calls.

**Announce at start:** "I'm using the auditing-vulnerabilities skill to audit this scope for security vulnerabilities."

## Workflow

Seven phases in order:

1. **Scope & Setup** — Resolve scope from the skill argument as a path: a directory or a single file. If no argument is given, default to the repository root and **confirm with the user before a full-repo run** — it can be long and token-heavy. Apply config knobs, using sensible defaults unless the user overrides them in the invocation:

   | Knob | Default | Effect |
   |---|---|---|
   | `scope` | repo root | Directory or file to audit |
   | `poc_threshold` | 75 | Min exploitability % for auto-generated PoC |
   | `severity_floor` | Info | Lowest severity included in the report |

2. **Partition** — Filter before partitioning: skip `node_modules`, `vendor`, `dist`, `build`, `.git`, lockfiles, minified/generated code, and binary assets. The dependency category reads manifests only (`package.json`, `requirements.txt`, `go.mod`, …), never vendored source. Partition the remaining files into units: a unit is **one file**, unless files are tiny and tightly coupled — then cluster into a coupled module capped at ~1500 LOC so an analyst sees whole logic paths without truncation. Dispatch analysts with **bounded concurrency**: batches of ~8–10 units at a time rather than all at once, reporting progress between batches. Apply the **hard scale guard**: if the unit count exceeds a ceiling of ~150, stop and tell the user — recommend narrowing scope, or ask them to confirm a long run — and never silently truncate. The scan manifest always logs what was covered and what was skipped, so a bounded run never reads as full coverage.
3. **Analysis fan-out** — ...
4. **Aggregate & dedupe** — ...
5. **Verification** — ...
6. **PoC generation** — ...
7. **Report** — ...
