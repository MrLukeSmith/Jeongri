# Verification Subagent

Use this prompt template when dispatching a verification subagent for a `[blocking]` finding. Fill in all placeholders before dispatching.

## Prompt Template

```
You are verifying a specific claim about a code change before it is posted as a blocking review comment. Be precise and thorough — a wrong blocking assertion does more harm than a missed suggestion.

**Repository:** {owner}/{repo}
**PR:** #{pr_number}
**Claim:** {specific assertion — e.g. "`processPayment()` can receive a null `userId` from the unauthenticated route at `/checkout/guest`"}
**Location in diff:** {file path}:{approximate line range}

Your task:
1. Read the code at the specified location in full.
2. Trace all call sites that can reach this code:
   a. Identify the function(s) at the specified location.
   b. Search the entire codebase for every call site using a code search tool (grep or equivalent) on the function name and any aliased imports.
   c. For each call site found, read the surrounding context to determine whether the condition in the claim can be satisfied from that call path.
   Stop as soon as you can confirm or rule out the claim — you do not need to trace every possible path, only enough to reach a confident verdict.
3. Check whether the condition described in the claim is actually reachable with a realistic input or code path.
4. Return exactly one of:
   - **Confirmed** — the claim is correct. Provide: the specific `file:line` where the problem exists, the full call path that reaches it, and a minimal code snippet demonstrating the issue.
   - **Refuted** — the claim is wrong. Explain precisely why: what mechanism prevents the problem from occurring?
   - **Inconclusive** — you cannot confirm or deny with confidence. List every file you checked and what specific question remains unanswered.

Do not speculate. Only report what the code actually shows. If a path is guarded somewhere, name where. If it isn't, name where the gap is.
```

## Handling Results

| Result | Action |
|---|---|
| **Confirmed** | Use the provided evidence verbatim in the `[blocking]` comment body |
| **Refuted** | Downgrade to `[suggestion]` or drop the finding entirely |
| **Inconclusive** | Retain as `[blocking]`, add to comment: "Unable to fully trace this path — recommend verifying manually" |
