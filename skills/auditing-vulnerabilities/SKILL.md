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
3. **Analysis fan-out** — Dispatch analyst subagents in bounded batches of ~8–10 concurrent, one analyst per unit, using the `analysis-subagent.md` prompt template. Each analyst receives its unit's files, the full fourteen-category checklist, and the finding schema, and returns a structured findings array. Report progress between batches (units completed / units total) so a long run is visible rather than silent.
4. **Aggregate & dedupe** — Merge every unit's findings array into one list. Collapse cross-unit duplicates: two findings referring to the **same CWE and the same root cause** (not merely the same file) collapse into one entry, keeping the strongest evidence and widest location reference. Rank the merged list by severity band first (Critical > High > Medium > Low > Info), then by exploitability % descending within each band.
5. **Verification** — For every **Critical** and **High** finding only, dispatch an adversarial refutation subagent using the `verification-subagent.md` prompt template — it tries to prove the finding wrong or unreachable. Medium/Low/Info findings skip this pass and keep their analyst-assigned confidence. Apply the result:
   - **Confirmed** — lock the severity and set `status: confirmed`; exploitability is set from the proven attack path.
   - **Refuted** — drop the finding, or downgrade it to Info if still worth noting as a hardening note; `status: refuted`.
   - **Inconclusive** — keep the finding, cap `exploitability` at 60, set `status: inconclusive`, and flag the open uncertainty in the report.
6. **PoC generation** — Generate a minimal illustrative proof-of-concept **only** for findings with `status: confirmed` **and** `exploitability` above `poc_threshold` (default 75). Every other finding — below the threshold, or not confirmed — keeps `poc: null` and is tagged **"PoC available on request"** so the user can ask for one afterwards. PoCs are defensively framed: the code owner is auditing their own code to fix it.
7. **Report** — Write the full report to `docs/security/YYYY-MM-DD-<scope>-audit.md` using the `report-template.md` structure, then echo a tight summary in chat: header, summary table, and counts by severity — not the full per-finding detail.

## The Checklist (the anchor)

Every analyst walks these fourteen categories in order and logs an explicit entry per category — a finding, or `No findings`. Categories 1–13 are closed and repeatable; category 14 is the deliberate open-ended slot for logic flaws no checklist enumerates. Grounded in OWASP Top 10 (2021) and the CWE Top 25, trimmed to what is detectable from source.

| # | Category | Primary CWEs | OWASP |
|---|---|---|---|
| 1 | Injection (SQL / NoSQL / OS / LDAP) | CWE-89, 78, 90 | A03 |
| 2 | Cross-site scripting | CWE-79 | A03 |
| 3 | Broken access control / authorization (incl. IDOR) | CWE-284, 285, 639 | A01 |
| 4 | Authentication & session management | CWE-287, 384, 613 | A07 |
| 5 | Cryptographic failures | CWE-327, 328, 916, 330 | A02 |
| 6 | Secrets & hardcoded credentials | CWE-798, 259 | A07 |
| 7 | Deserialization & unsafe input parsing (incl. XXE) | CWE-502, 611 | A08 |
| 8 | SSRF & unvalidated redirects | CWE-918, 601 | A10 |
| 9 | Path traversal & unrestricted file handling | CWE-22, 434 | A01 |
| 10 | Input validation & memory bounds | CWE-20, 787, 125 | A03 |
| 11 | Security misconfiguration & insecure defaults | CWE-16, 732 | A05 |
| 12 | Sensitive data exposure & logging | CWE-200, 532 | A02 |
| 13 | Vulnerable dependencies (manifest signals) | CWE-1104 | A06 |
| 14 | Business-logic / race / TOCTOU | CWE-367, 362 | — |

## Finding Schema

Every analyst returns an array of findings in this shape:

```json
{
  "title": "SQL injection in user lookup",
  "category": 1,
  "cwe": "CWE-89",
  "owasp": "A03:2021",
  "file": "src/db/users.py",
  "line": 42,
  "severity": "Critical",
  "exploitability": 90,
  "certainty": 85,
  "evidence": "Raw f-string interpolation of request.args['id'] into query; no parameterization. Reachable from unauthenticated /lookup route.",
  "remediation": "Use a parameterized query: cursor.execute(sql, (id,)).",
  "poc": null,
  "status": "unverified"
}
```

- **`exploitability`** (0–100) — how likely the finding is a real, reachable, exploitable vulnerability. Set from reachability analysis, refined by the verifier.
- **`certainty`** (0–100) — the analyst's confidence in its own reading of the code, independent of exploitability. Capped low when cross-file context is unavailable.
- **`status`** — `unverified` → `confirmed` | `refuted` | `inconclusive` after phase 5.
- **`poc`** — null until phase 6; filled only when confirmed and above the threshold.

## Severity Rubric

Assigned by the analyst, adjusted by the verifier. Anchored to impact and reachability so it is not a vibe.

| Severity | Meaning | Typical exploitability |
|---|---|---|
| **Critical** | Unauthenticated RCE, auth bypass, or trivial data exfiltration | ≥ 80 |
| **High** | Significant impact but requires some condition (authenticated user, specific config) | 60–90 |
| **Medium** | Limited impact or a hard-to-reach path | 30–70 |
| **Low** | Defence-in-depth gap or minor info leak | < 40 |
| **Info** | Hardening note; no direct attack path | — |

The report ranks by severity band, then by exploitability % within the band.

## Communication Tone

- Write to an engineer auditing their own system. Assume good intent, state findings plainly.
- No hedging on confirmed high-severity findings — be clear about what is exploitable and why.
- State the problem, the evidence, then the fix. No preamble, no editorializing.
- `No findings` per category is a valid and expected result — never manufacture a finding to fill a row.

## Anti-Patterns

| Anti-pattern | Why it's wrong |
|---|---|
| Reporting a finding without a reachability / attack-path argument | Theoretical noise; erodes trust in the report |
| Asserting Critical/High without the refutation pass | A wrong high-severity finding is worse than a missed low one |
| Skipping a checklist category silently | Breaks the determinism guarantee; the explicit `No findings` entry is the point |
| Manufacturing findings to fill every category | Padding hides the real signal |
| Silently truncating a large scope | Reads as full coverage when it isn't; always log what was skipped |
| Generating a PoC below the threshold unprompted | Offensive code should be gated on confirmed, high-exploitability findings |
| Reporting file/function facts not visible in the scanned unit | Hallucinated context; treat only observed code as ground truth |
