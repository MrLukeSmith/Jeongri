# Design: `reviewing-github-prs` — expanded criteria (human-centric review)

**Date:** 2026-04-23
**Status:** Approved
**Relationship:** extends [2026-04-21-reviewing-github-prs-design.md](2026-04-21-reviewing-github-prs-design.md); does not replace it.

## Motivation

Comparison of four agentic review runs (3 Sonnet, 1 Opus) against Konrad's human review of [livelink/web-kiosk#13025](https://github.com/livelink/web-kiosk/pull/13025) surfaced consistent blind spots in the agent output. Agents reliably assessed correctness, complexity, and test coverage against what was visible in the diff. They did not:

- Interrogate the *justification* for non-obvious changes (deletions, defensive guards, workarounds, undocumented additions)
- Search for pre-existing abstractions the PR should have used
- Evaluate whether a human reviewer could hold the PR in their head well enough to review it competently

Konrad's review was dominated by questions ("Why?", "What was the problem?", "What about other callers?") and by a top-level request to decompose the PR into 3–5 smaller, independently-reviewable changes. Agents made assertions from inside the diff; Konrad asked what the diff did not explain.

The goal of this design is to close those gaps without duplicating what Rubocop, Danger, or other existing tooling already surfaces.

## Scope

Three changes to the `reviewing-github-prs` skill:

1. **Broaden criterion 6** (Codebase Consistency) — add an active check for pre-existing abstractions the PR should be using.
2. **Add criterion 8** (Justification Audit) — interrogate the *why* behind non-obvious changes; default to questions, not assertions.
3. **Add criterion 9** (Reviewer Cognitive Load) — assess whether the PR is too large for a human to review competently, and if so, propose a decomposition.

Plus one supporting change:

4. **Soften the "bikeshedding naming" anti-pattern** — still ban preference-based naming nits, but allow flagging genuine naming problems (stutter, misleading names, ambiguity) under criterion 6.

The criteria count rises from 7 to 9. No existing criterion is removed.

## Explicit non-goals

- **No duplication of Rubocop / Danger / linter output.** If the existing toolchain surfaces it, the skill should not.
- **No replacement of the human reviewer.** Criterion 9 exists specifically to preserve the human's role by not overloading them. Agents can process arbitrary complexity; humans cannot. The skill is written from the perspective of serving the human reviewer.
- **No whitelist-vs-blacklist criterion.** This design concern (raised by Konrad on `is_a?(ActiveStorageStore)`) is handled as an example under criterion 6, not a new criterion.
- **No rename-naming criterion.** Naming issues, when genuine, belong under criterion 6. They do not warrant their own top-level criterion.

---

## Criterion 6 — Codebase Consistency (broadened)

**Current text:**
> Does this introduce a new pattern where one exists? Does it break established conventions identified in Step 1?

**New text:**
> Does this introduce a new pattern where one exists? Does it break established conventions identified in Step 1? **Does it reimplement behaviour that an existing helper, abstraction, or test-support module already provides?**

**Severity:**
- `[suggestion]` in most cases, including when a pre-existing abstraction would fit better
- `[blocking]` only if the inconsistency is likely to cause bugs (e.g. diverging from a safety convention)

**Active check** (added instruction):
Before concluding "no findings" on this criterion, scan the codebase for helpers or modules whose names suggest overlap with what the PR adds. Candidates: `*Switching`, `*Helper`, `Shared*`, or module names close to the domain of the new code. The "Existing abstractions" note from Step 1 is the input to this check.

**Example trigger (from PR #13025):** the PR inlines per-example storage backend switching in `image_file_render_spec.rb`, but `StorageBackendSwitching` already exists for that purpose.

---

## Criterion 8 — Justification Audit (new)

Interrogate the *why* behind non-obvious changes. Comments for this criterion default to **questions, not assertions** — the one criterion in the skill where a clarifying question is the desired output, not a direction.

**Triggers:**

- **Deletions** of code, tests, or test-support helpers without evident reason — ask: "why is this safe to remove now?"
- **Defensive guards** added without a named failure mode (`&.`, `respond_to?`, new `rescue`) — ask: "what scenario does this protect against? If it's a bug, should we surface it instead of silencing it?"
- **Workarounds** — new subclasses, monkey-patches, config overrides, or test-support patches that bypass a problem rather than fix its source — ask: "what is the underlying issue, and why can't we address it there?"
- **New classes, modules, or services without a class-level comment** explaining their purpose. Especially when the class exists as a workaround (e.g., a subclass that bypasses credential validation against an emulator).
- **Undocumented changes** — diff content not mentioned in the PR description. Flag the specific change and ask that the description be updated.

**Severity:**
- `[suggestion]` — default. The change looks reasonable but needs a documented rationale.
- `[blocking]` — rare. Use only when the unexplained change carries real risk: a defensive guard that may hide a correctness bug, or a deletion of behaviour that is load-bearing elsewhere.

**Format note:** comments for this criterion are often most useful as direct questions. Prefer `"Why X?"` or `"What happens when Y?"` over assertions. This is the one criterion where a clarifying question, rather than a direction, is the desired output. The rest of the skill's communication guidance (direct, no hedging, no filler) still applies — a question can be short and direct.

**Rationale for the question-led tone:** Konrad's questions worked *because* they invited the author to supply missing context rather than forcing the reviewer to guess it. Assertions without context read as either obvious or wrong; questions without context read as genuine inquiry.

---

## Criterion 9 — Reviewer Cognitive Load (new)

Independent of scope coherence. Even a perfectly-scoped PR can be too much for a human reviewer to hold in their head and review competently. The check: "Could a human reviewer comfortably hold this PR in their head and produce a competent, cohesive review?"

**Triggers** (judgment, not strict thresholds):
- The diff contains multiple independent logical concerns that could each stand alone (e.g., routing change + new service class + test-support overhaul + hidden model mutation)
- The PR description's section count under-represents the number of concerns in the diff
- A single concern's code change is small, but its support changes (test helpers, config, log suppression) are large and independently reviewable

**When triggered, produce a top-level decomposition proposal** in the aggregate summary — never as an inline comment. Format:

```
Suggested decomposition (optional — this PR is coherent, just large for one review pass):

PR 1 (standalone): <what it does>. Files: <paths>.
PR 2 (depends on PR 1): <what it does>. Files: <paths>.
PR 3: <what it does>. Files: <paths>.
```

Constraints on the decomposition block:
- One sentence per PR
- Name files only when it clarifies the split
- Dependencies between PRs must be explicit (`standalone`, `depends on PR N`)
- Three to five PRs is typical; more than five suggests the reviewer is over-decomposing

**Severity:** always `[suggestion]`. Never blocks merge. Never produces an inline comment — the decomposition is PR-level by nature.

**If the PR is appropriately sized for one review pass**, write `No findings` and move on. Do not manufacture a decomposition to fill the slot.

**Rationale:** agents can process arbitrary complexity; humans cannot. A review that blesses a too-large PR as correct fails the human reviewer who inherits it. This criterion exists to preserve the human's role in the loop, not to gatekeep on size alone.

---

## Anti-pattern softening

**Current entry in the skill's anti-pattern table:**
> Bikeshedding naming when the existing name is clear

**Revised:**
> Bikeshedding naming when the existing name is clear and unambiguous. Genuine naming problems — redundant class/method stutter (e.g. `DataBlobStore.blob_store`), misleading names, or identifiers that obscure intent — should still be flagged under Codebase Consistency as `[suggestion]`.

**Rationale:** the current wording reads as "don't flag naming, ever." That suppresses genuine API-ergonomics issues. The revised version still bans preference-based nits while allowing real naming problems through.

---

## Impact on existing skill structure

- **Step 2 (Analysis Pass):** now iterates nine criteria, not seven. The instruction that *every* criterion produces an explicit entry (even `No findings`) still applies.
- **Step 3 (Verification Pass):** unchanged. Criteria 8 and 9 produce `[suggestion]`-level findings almost exclusively, so the verification subagent rarely applies. When criterion 8 produces a `[blocking]` finding (e.g., a defensive guard that may hide a bug), the normal verification flow applies.
- **Step 4 (Draft Review):** when criterion 9 triggers, the decomposition block is appended to the aggregate summary body, above or below the recommended event type. It does not appear in the `comments` array of the GitHub API payload.
- **Step 5 (Show):** display the decomposition block alongside the rest of the aggregate summary before confirming.

No changes to steps 1, 6, 7 (Context Pass, Confirm, Save as Draft).

---

## Validation

After implementation, re-run the expanded skill against PR #13025 and compare the output to Konrad's review. Success criteria:
- At least one finding under criterion 8 corresponding to Konrad's "why this deletion?" / "why this safe-nav?" / "why this hidden change?" questions.
- At least one finding under criterion 6 (broadened) corresponding to Konrad's `StorageBackendSwitching` observation.
- A decomposition proposal under criterion 9 that broadly matches Konrad's "3–5 PRs could be extracted" framing.

If none of the three new/broadened criteria produce findings on a PR that a human reviewer found "overwhelmingly complex," the design has failed to close the gap and needs revision.
