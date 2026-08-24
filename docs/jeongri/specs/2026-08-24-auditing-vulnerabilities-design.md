# Design: `auditing-vulnerabilities` skill

**Date:** 2026-08-24
**Status:** Approved

## Overview

A structured skill for auditing a codebase for security vulnerabilities in the Jeongri marketplace. The user points it at a target — the whole repo, a subfolder, or a single file — and it evaluates the logic within that scope for exploitable flaws, producing a report of findings ranked by severity, each carrying two independent 0–100% confidence numbers (exploitability and analyst-certainty).

The skill reuses the analysis → verify → report spine established by `reviewing-github-prs`, adapted from diff review to whole-scope audit. It is built around one goal the user stated explicitly: be **as deterministic as an LLM can be**. Four structural levers serve that goal:

1. A **fixed, enumerated CWE/OWASP checklist** every analyst walks in the same order, forced to log an explicit entry (finding or `No findings`) per category — no category is silently skipped.
2. **Structured JSON output schemas** so the shape of a finding is stable across runs and units.
3. An **adversarial refutation verification pass** on every high-severity finding — the main false-positive killer.
4. **Numeric confidence gates** (e.g. the PoC threshold) rather than subjective judgment calls.

The report is written to a dated Markdown file under `docs/security/` and summarised in chat.

---

## Workflow

Seven phases in order:

1. **Scope & Setup** — Resolve the target path (from the skill argument; if none, default to the repository root and confirm). Enumerate source files within scope, detect languages, and filter out vendored / generated / dependency / binary paths. Estimate size (unit count).
2. **Partition** — Group the surviving files into analysis *units*. A unit is one file, or a small tightly-coupled module cluster, capped at a soft budget (~1500 LOC) so each fits an analyst subagent's context without truncation. Produce a scan manifest listing every unit and every skipped path.
3. **Analysis fan-out** — Dispatch analyst subagents in bounded parallel batches (~8–10 concurrent), one per unit. Each walks the fixed checklist and returns a structured findings array. Report progress between batches.
4. **Aggregate & dedupe** — Merge all unit results, collapse cross-unit duplicates (same CWE + same root cause), and rank by severity band, then exploitability % within band.
5. **Verification** — For every **Critical** and **High** finding, dispatch an adversarial refutation subagent that tries to prove the finding wrong or unreachable. Adjust severity and both confidence numbers on the result; drop or downgrade refuted findings.
6. **PoC generation** — For **confirmed** findings whose exploitability exceeds the threshold (default 75, configurable), generate a minimal illustrative proof-of-concept. Others are tagged "PoC available on request."
7. **Report** — Write the full report to `docs/security/YYYY-MM-DD-<scope>-audit.md` and print a tight ranked summary in chat.

---

## Scope Resolution & Configuration

**Scope** comes from the skill argument as a path — a directory or a single file. If no argument is given, default to the repository root and confirm with the user before a full-repo run (potentially long and token-heavy).

**Config knobs** (sensible defaults; user may override in the invocation):

| Knob | Default | Effect |
|---|---|---|
| `scope` | repo root | Directory or file to audit |
| `poc_threshold` | 75 | Min exploitability % for auto-generated PoC |
| `severity_floor` | Info | Lowest severity included in the report |

---

## Partition & Scale Guards

- **Unit = one file**, unless files are tiny and tightly coupled — then cluster a module up to ~1500 LOC so an analyst sees whole logic paths without truncation.
- **Filter before partitioning:** skip `node_modules`, `vendor`, `dist`, `build`, `.git`, lockfiles, minified/generated code, and binary assets. The dependency category (13) reads manifests only (`package.json`, `requirements.txt`, `go.mod`, …), never vendored source.
- **Bounded concurrency:** dispatch analysts in batches of ~8–10 rather than all at once; report progress between batches.
- **Hard scale guard:** if the unit count exceeds a ceiling (~150), stop and tell the user — recommend narrowing scope or ask them to confirm a long run. Never silently truncate. The scan manifest always logs what was covered and what was skipped, so a bounded run never reads as full coverage.

---

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

---

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

---

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

---

## Analyst Subagent (`analysis-subagent.md`)

Receives one unit's files, the full checklist, and the schema. Instructions:

- Walk all fourteen categories in order; log an explicit entry per category — never skip a row.
- Trace reachability where possible: is the sink reached from an entry point or from untrusted input? Reachability drives the exploitability number.
- When a cross-file call cannot be resolved from the unit alone, record the assumption in `evidence` and cap `certainty` accordingly.
- Return **only** the JSON findings array — no prose.

---

## Verification Subagent (`verification-subagent.md`)

Fires once per Critical or High finding. Adversarial by design — the prompt instructs it to **refute**:

> Here is a claimed finding. Prove it is NOT exploitable: show the input is sanitized upstream, the path is unreachable, the sink is safe, or the severity is inflated. Default to skeptical.

Returns one of:

- **Confirmed** — with a concrete attack path (file:line, call chain). Lock severity; set exploitability from the proven path.
- **Refuted** — with the reason the initial reading was wrong. Drop the finding, or downgrade to Info if still worth noting.
- **Inconclusive** — with what was checked and what remains open. Keep the finding, cap exploitability at 60, and flag the uncertainty in the report.

Medium / Low / Info findings are not verified — they are reported with their analyst-assigned confidence.

---

## PoC Generation

- Runs only on **confirmed** findings with **exploitability > `poc_threshold`** (default 75).
- Produces a minimal illustrative payload or request plus a one-line explanation of how it works. Defensive framing: the code owner is auditing their own code to fix it.
- Below the threshold, `poc` stays null and the finding is tagged **"PoC available on request"** so the user can ask for a specific one afterwards.

---

## Report

Written to `docs/security/YYYY-MM-DD-<scope>-audit.md`, with a tight summary echoed in chat.

**Structure:**

1. **Header** — scope audited, date, unit count, files skipped, config used.
2. **Summary table** — one row per finding: severity, title, CWE, OWASP, file:line, exploitability %, certainty %, status.
3. **Per-finding detail** — ranked most-severe first: title, location, evidence / attack path, remediation, PoC (if generated), verification status.
4. **Coverage note** — what was scanned, what was skipped and why, any scale-guard truncation.

The chat summary is the header plus the summary table plus counts by severity — not the full per-finding detail.

---

## Communication Tone

- Write to an engineer auditing their own system. Assume good intent, state findings plainly.
- No hedging on confirmed high-severity findings — be clear about what is exploitable and why.
- State the problem, the evidence, then the fix. No preamble, no editorializing.
- `No findings` per category is a valid and expected result — never manufacture a finding to fill a row.

---

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

---

## File Location

```
skills/
└── auditing-vulnerabilities/
    ├── SKILL.md                    # orchestration, checklist, severity/confidence rules
    ├── analysis-subagent.md        # per-unit analyst prompt template
    ├── verification-subagent.md    # adversarial refutation verifier template
    └── report-template.md          # Markdown report structure
```
