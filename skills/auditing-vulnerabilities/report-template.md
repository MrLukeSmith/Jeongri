# Report Template

Fill this structure in phase 7 (Report) and write it to `docs/security/YYYY-MM-DD-<scope>-audit.md` in the audited project. Echo only the Header, the Summary table, and the severity counts into chat — not the full per-finding detail. Replace every `<…>` placeholder; drop the PoC block from a finding that has none and tag it "PoC available on request."

The Summary-table columns are the finding-schema fields from `SKILL.md` ("Finding Schema"): `severity`, `title`, `cwe`, `owasp`, `file:line`, `exploitability`, `certainty`, `status`.

---

```markdown
# Security Audit — <scope>

**Scope audited:** <path (repo root / subfolder / file)>
**Date:** <YYYY-MM-DD>
**Units analysed:** <N>
**Files skipped:** <count> (see Coverage note)
**Config:** poc_threshold=<75>, severity_floor=<Info>

## Summary

Findings by severity: Critical <n> · High <n> · Medium <n> · Low <n> · Info <n>

| Severity | Title | CWE | OWASP | Location | Exploitability | Certainty | Status |
|---|---|---|---|---|---|---|---|
| Critical | <title> | CWE-89 | A03:2021 | `src/db/users.py:42` | 90% | 85% | confirmed |
| High | <title> | CWE-284 | A01:2021 | `src/api/orders.py:118` | 70% | 80% | confirmed |
| Medium | <title> | CWE-79 | A03:2021 | `web/views.py:23` | 45% | 75% | unverified |

Rows are ordered by severity band, then by exploitability % within the band.

## Findings

### 1. <title> — Critical

- **Location:** `src/db/users.py:42`
- **CWE / OWASP:** CWE-89 / A03:2021
- **Exploitability:** 90% · **Certainty:** 85% · **Status:** confirmed
- **Evidence / attack path:** <what the flaw is; how untrusted input reaches the sink; the verified call path from an entry point>
- **Remediation:** <concrete fix guidance>
- **Proof of concept:**

  ```
  <minimal illustrative payload / request, with a one-line note on how it works>
  ```

### 2. <title> — High

- **Location:** `src/api/orders.py:118`
- **CWE / OWASP:** CWE-284 / A01:2021
- **Exploitability:** 70% · **Certainty:** 80% · **Status:** confirmed
- **Evidence / attack path:** <…>
- **Remediation:** <…>
- **Proof of concept:** PoC available on request (exploitability below the 75% threshold).

## Coverage note

- **Scanned:** <what was covered — N units across the scope>.
- **Skipped:** <what was excluded and why — vendored/generated/dependency paths, binaries, lockfiles>.
- **Truncation:** <none — or, if the scale guard tripped, exactly what was not analysed and why>.
```

---

## Notes

- Every finding in the Summary table has a matching detail entry, most-severe first.
- Include the Proof-of-concept block only when phase 6 generated one (confirmed finding, exploitability > `poc_threshold`); otherwise state "PoC available on request."
- The Coverage note must state truncation honestly — a bounded run never reads as full coverage.
