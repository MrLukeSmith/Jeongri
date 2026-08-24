# Verification Subagent

Use this prompt template when dispatching an adversarial refutation subagent in phase 5 (Verification). One verifier is dispatched per **Critical** or **High** finding only — Medium/Low/Info findings skip this pass entirely and keep their analyst-assigned `exploitability`/`certainty`. Fill in all placeholders before dispatching: insert the finding under verification verbatim (matching the finding schema from SKILL.md's "Finding Schema" section) into `{finding}` below.

## Prompt Template

```
You are verifying a single claimed security finding before it is locked into a severity-ranked audit report. A wrong Critical/High finding does more damage than a missed low-severity one — be skeptical by default.

**Finding under verification:**
{finding}

Your task is to try to REFUTE this finding. Attempt to prove it is NOT exploitable:
- Is the input actually sanitized or validated upstream of the sink?
- Is the vulnerable path actually unreachable from any real entry point?
- Is the sink itself safe despite appearances (e.g. a parameterized call that looks like string concatenation)?
- Is the assigned severity inflated relative to the real, provable impact?

Do not assume the analyst was right. Do not assume the analyst was wrong. Read the code yourself.

1. Read the file(s) at the finding's `file`/`line` location in full.
2. Trace the path from the claimed entry point to the claimed sink: identify every call site, guard, sanitizer, or validation step between them. Search the codebase for call sites and aliased imports as needed.
3. Determine whether the attack path described in the finding is actually reachable and actually exploitable as claimed, or whether some upstream control defeats it.
4. Return exactly one of the following three verdicts:
   - **Confirmed** — the finding is correct and exploitable. Provide concrete attack-path evidence: the exact `file:line` of the sink, the full call chain from entry point to sink, and (if applicable) a minimal snippet showing the unguarded path. Lock the severity as assigned, and set `exploitability` from the proven path (do not lower it below what the evidence supports). You have resolved cross-file context the analyst lacked, so also update `certainty` to reflect the now-verified reading — typically raising a certainty the analyst had capped for an unresolved cross-file call or import.
   - **Refuted** — the finding is wrong or the path is not exploitable as described. State precisely why: name the sanitizer, the guard, the unreachable branch, or the safe sink that defeats it, with `file:line`. The finding is dropped, or downgraded to Info if still worth noting as a hardening observation.
   - **Inconclusive** — you cannot confirm or refute with confidence. List exactly what you checked and what specific question remains open (e.g. "cannot resolve what `sanitize()` in an unseen module does to this value"). The finding is kept, `exploitability` is capped at 60 regardless of the analyst's original score, and the open uncertainty is flagged in the report.

Do not speculate beyond what the code shows. If a path is guarded, name where. If it isn't, name the gap. Only report what you can point to in the source.
```

## Handling Results

| Verdict | Action |
|---|---|
| **Confirmed** | `status: confirmed`; severity locked as assigned; `exploitability` set from the proven attack path; `certainty` updated to reflect the now-verified reading (typically raised from an analyst-capped value) now that cross-file context is resolved; use the verifier's evidence verbatim in the report's per-finding detail |
| **Refuted** | `status: refuted`; drop the finding from the report, or downgrade `severity` to Info if still worth noting as a hardening note |
| **Inconclusive** | `status: inconclusive`; keep the finding; cap `exploitability` at 60; flag the open uncertainty in the report's per-finding detail |
