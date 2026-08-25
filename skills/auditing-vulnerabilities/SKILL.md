---
name: auditing-vulnerabilities
description: Use when asked to audit a codebase, folder, or file for security vulnerabilities — fans out per-unit analysts over a fixed CWE/OWASP checklist, verifies high-severity findings by refutation, and writes a severity-ranked report with exploitability and certainty scores
---

# Auditing Vulnerabilities

Scope-targeted security audit that evaluates a repo, folder, or file for exploitable flaws and produces a severity-ranked report, each finding carrying two independent confidence scores — exploitability and analyst-certainty. The skill reuses the analysis → verify → report spine established by `reviewing-github-prs`, adapted from diff review to whole-scope audit, and is built around one goal stated explicitly by the user: be as deterministic as an LLM can be. Four structural levers serve that goal: a fixed, enumerated CWE/OWASP checklist every analyst walks in the same order, forced to log an explicit entry per category; structured JSON output schemas so the shape of a finding is stable across runs and units; an adversarial refutation verification pass on every high-severity finding; and numeric confidence gates rather than subjective judgment calls.

**Announce at start:** "I'm using the auditing-vulnerabilities skill to audit this scope for security vulnerabilities."

## Workflow

Eight phases in order:

1. **Scope & Setup** — Resolve scope from the skill argument as a path: a directory or a single file. If no argument is given, default to the repository root and **confirm with the user before a full-repo run** — it can be long and token-heavy. Apply config knobs, using sensible defaults unless the user overrides them in the invocation:

   | Knob | Default | Effect |
   |---|---|---|
   | `scope` | repo root | Directory or file to audit |
   | `poc_threshold` | 75 | Min exploitability % for auto-generated PoC |
   | `severity_floor` | Info | Lowest severity included in the report |

   **Subtree-scope warning.** When the scope is a subtree rather than the whole repo (e.g. `app/models` only), state up front — in chat and in the report's coverage note — that **cross-layer vulnerabilities are out of coverage by construction**: a weak primitive in the scoped layer (a truncated secret, a type-loose query argument, an unbounded builder) whose exploitable sink lives in an unscoped layer (a controller, a view, a job) cannot be confirmed from the scope alone. The cross-file linking pass (phase 5) reads unscoped callers to resolve these where it can, but a bug that is only dangerous through an unscoped entry point may still be under-scored. Recommend a paired pass over the caller layer, or a whole-repo run, for auth/secret/ID flows.

2. **Partition** — Filter before partitioning: skip `node_modules`, `vendor`, `dist`, `build`, `.git`, lockfiles, minified/generated code, and binary assets. The dependency category reads manifests only (`package.json`, `requirements.txt`, `go.mod`, …), never vendored source. Partition the remaining files into units: a unit is **one file**, unless files are tiny and tightly coupled — then cluster into a coupled module capped at ~1500 LOC so an analyst sees whole logic paths without truncation. Dispatch analysts with **bounded concurrency**: batches of ~8–10 units at a time rather than all at once, reporting progress between batches. Apply the **hard scale guard**: if the unit count exceeds a ceiling of ~150, stop and tell the user — recommend narrowing scope, or ask them to confirm a long run — and never silently truncate. The scan manifest always logs what was covered and what was skipped, so a bounded run never reads as full coverage.
3. **Analysis fan-out** — Dispatch analyst subagents in bounded batches of ~8–10 concurrent, one analyst per unit, using the `analysis-subagent.md` prompt template. Each analyst receives its unit's files, the full fourteen-category checklist, and the finding schema, and returns a structured findings array. Report progress between batches (units completed / units total) so a long run is visible rather than silent.
4. **Aggregate & dedupe** — Merge every unit's findings array into one list. Collapse cross-unit duplicates: two findings referring to the **same CWE and the same root cause** (not merely the same file) collapse into one entry, keeping the strongest evidence and widest location reference. Rank the merged list by severity band first (Critical > High > Medium > Low > Info), then by exploitability % descending within each band.
5. **Cross-file linking** — Resolve the findings whose danger is only visible across a unit boundary, so the per-unit isolation that makes analysis deterministic does not silently drop emergent bugs. Two inputs feed this pass:
   - **Primitives of concern** — analyst notes flagged `primitive_of_concern: true`: a dangerous construct with no in-unit sink (a secret truncated for a lookup key, a type-loose value passed to a query/auth method, an unbounded allocation builder). These are *not yet findings*; each one must be resolved here or explicitly discharged.
   - **Cross-file-dependent findings** — findings flagged `cross_file_dependency: true`: an analyst capped certainty because the caller, sink, or sanitizer sits outside the unit.

   For each, search the **whole repository** — including layers outside the audit scope, read-only — for the callers and sinks the analyst could not see. Taint-follow security tokens, secrets, and untrusted IDs from the scoped primitive into the query/auth/render/fetch methods that consume them. Promote a resolved primitive into a concrete finding with a real attack path; merge a resolved cross-file finding's now-known reachability into its score; discharge (drop) any that provably reach no dangerous sink, recording why. A primitive whose caller cannot be found because it lives outside a subtree scope is kept as an explicit **unresolved-cross-layer** note in the report, not silently dropped.
6. **Verification** — Dispatch an adversarial refutation subagent (`verification-subagent.md`) for every finding that is **Critical or High**, **or** carries `cross_file_dependency: true`, **or** was promoted from a `primitive_of_concern` in phase 5 — regardless of its severity band. This closes the trap where a real bug is scored low *precisely because* its cross-file context was unresolved, and so never reaches the one pass that resolves cross-file context. Findings that are Medium/Low/Info **and** self-contained (no cross-file flag) skip this pass and keep their analyst-assigned confidence. Apply the result:
   - **Confirmed** — lock the severity and set `status: confirmed`; exploitability is set from the proven attack path; certainty is also updated to reflect the now-verified reading, since the verifier has resolved cross-file context the analyst lacked. Re-rank if the confirmed severity changed.
   - **Refuted** — drop the finding, or downgrade it to Info if still worth noting as a hardening note; `status: refuted`.
   - **Inconclusive** — keep the finding, cap `exploitability` at 60, set `status: inconclusive`, and flag the open uncertainty in the report.
7. **PoC generation** — Generate a minimal illustrative proof-of-concept **only** for findings with `status: confirmed` **and** `exploitability` above `poc_threshold` (default 75). Every other finding — below the threshold, or not confirmed — keeps `poc: null` and is tagged **"PoC available on request"** so the user can ask for one afterwards. PoCs are defensively framed: the code owner is auditing their own code to fix it.
8. **Report** — Before writing, apply `severity_floor`: drop any finding whose severity band is below the configured floor (Critical > High > Medium > Low > Info) from the report; the default, Info, excludes nothing. Write the full report to `docs/security/YYYY-MM-DD-<scope>-audit.md` using the `report-template.md` structure, then echo a tight summary in chat: header, summary table, and counts by severity — not the full per-finding detail.

## The Checklist (the anchor)

Every analyst walks these fourteen categories in order and logs an explicit entry per category — a finding, or `No findings`. Categories 1–13 are closed and repeatable; category 14 is the deliberate open-ended slot for logic flaws no checklist enumerates. Grounded in OWASP Top 10 (2021) and the CWE Top 25, trimmed to what is detectable from source.

| # | Category | Primary CWEs | OWASP |
|---|---|---|---|
| 1 | Injection (SQL / NoSQL / OS / LDAP) | CWE-89, 78, 90 | A03:2021 |
| 2 | Cross-site scripting | CWE-79 | A03:2021 |
| 3 | Broken access control / authorization (incl. IDOR) | CWE-284, 285, 639 | A01:2021 |
| 4 | Authentication & session management | CWE-287, 384, 613 | A07:2021 |
| 5 | Cryptographic failures | CWE-327, 328, 916, 330 | A02:2021 |
| 6 | Secrets & hardcoded credentials | CWE-798, 259 | A07:2021 |
| 7 | Deserialization & unsafe input parsing (incl. XXE) | CWE-502, 611 | A08:2021 |
| 8 | SSRF & unvalidated redirects | CWE-918, 601 | A10:2021 |
| 9 | Path traversal & unrestricted file handling | CWE-22, 434 | A01:2021 |
| 10 | Input validation & memory bounds | CWE-20, 787, 125 | A03:2021 |
| 11 | Security misconfiguration & insecure defaults | CWE-16, 732 | A05:2021 |
| 12 | Sensitive data exposure & logging | CWE-200, 532 | A02:2021 |
| 13 | Vulnerable dependencies (manifest signals) | CWE-1104 | A06:2021 |
| 14 | Business-logic / race / TOCTOU | CWE-367, 362 | — |

### Framework-footgun cues

The fourteen categories are sink-signature oriented — they cue on code that *looks* dangerous (raw SQL, raw path join, raw fetch). Some of the worst bugs route through an API that looks *safe*: the danger is the argument's type or the library's decode behaviour, not the call's surface. While walking the relevant category, treat these as first-class candidates, not safe-by-default:

- **ORM query type-confusion (category 1).** A query/finder method fed a value whose type the attacker controls. In ActiveRecord, `where` / `exists?` / `find_by` / `destroy_by` accept an Array or Hash as a raw conditions fragment — so a JSON value that reaches `Model.exists?(attacker_value)` without coercion to a scalar is SQL injection even with no visible string interpolation. Equivalent footguns exist in other ORMs (Sequel dataset filters, Django `extra`/`raw`, Mongoose `$where`). Flag any query argument that is not provably a coerced scalar/typed id.
- **Dynamic dispatch (categories 1, 3).** `send`/`public_send`/`constantize`/`__send__` with an attacker-influenced name.
- **Decode/allocation bombs (category 10).** Image/media/archive decoders that allocate on *declared* dimensions before any resize — `GdkPixbuf::Pixbuf.new(file:, width:, height:)`, ImageMagick, Cairo surfaces, zip/gzip. A size-capping constructor argument does **not** prove safety; the pre-resize decode is the sink. Safe pattern is a header-only inspection first (e.g. `get_file_info`).
- **Deserialization that looks bounded (category 7).** `YAML.load` (version-dependent), `Marshal.load`, `Oj` in object mode, pickle — even when the source looks internal, flag it and let phase 5 resolve who can write the source.
- **Truncated / predictable security values (categories 4, 5).** A secret, token, or id sliced (`[0, n]`), hashed from low-entropy input (timestamp, sequential id), or compared by prefix. Usually a **primitive of concern** — the auth bypass materialises in the caller that trusts it; flag `primitive_of_concern` and let phase 5 link it.

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
  "status": "unverified",
  "cross_file_dependency": false,
  "primitive_of_concern": false
}
```

- **`exploitability`** (0–100) — how likely the finding is a real, reachable, exploitable vulnerability. Set from reachability analysis, refined by the verifier.
- **`certainty`** (0–100) — the analyst's confidence in its own reading of the code, independent of exploitability. Capped low when cross-file context is unavailable.
- **`status`** — `unverified` → `confirmed` | `refuted` | `inconclusive` after phase 6.
- **`poc`** — null until phase 7; filled only when confirmed and above the threshold.
- **`cross_file_dependency`** (bool) — set `true` whenever certainty was capped because the caller, sink, or sanitizer needed to judge this finding sits outside the analysed unit. This flag routes the finding into phase 5 (linking) and forces phase 6 (verification) even below High — so a real bug scored low *only* for lack of cross-file context still gets resolved.
- **`primitive_of_concern`** (bool) — set `true` for a dangerous construct that has **no exploitable sink inside this unit** but would become one in a caller: a truncated/predictable secret, a type-loose value handed to a query/auth method, an unbounded allocation. Report it as a finding with the severity its worst plausible caller-side impact would carry, set `cross_file_dependency: true` as well, and describe the missing link in `evidence`. Phase 5 either promotes it to a concrete finding or discharges it — it is never silently dropped.

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
| Dropping a dangerous primitive because its sink is outside the unit | Cross-layer bugs (weak secret in a model, auth bypass in the controller) vanish; flag `primitive_of_concern` and let phase 5 link it |
| Treating a size-capping argument or a safe-looking ORM call as proof of safety | The sink is the argument's type or the pre-resize decode, not the call surface; see Framework-footgun cues |
