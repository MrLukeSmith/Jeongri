# Auditing Vulnerabilities Skill — Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Build the `auditing-vulnerabilities` skill — a scope-targeted security auditor that fans out per-file analysts over a fixed CWE/OWASP checklist, verifies high-severity findings by refutation, and produces a severity-ranked report with dual confidence scores.

**Architecture:** Four authored Markdown files under `skills/auditing-vulnerabilities/`: an orchestrating `SKILL.md` plus three subagent/template files it dispatches or fills. No runtime code — the deliverable is skill content. Determinism comes from a fixed enumerated checklist, structured JSON schemas, an adversarial verification pass, and numeric confidence gates.

**Tech Stack:** Markdown skill files (Claude Code plugin `skills/` auto-discovery). Verification via `bash` (grep, python3 `json.loads`) and a YAML-frontmatter check.

**Spec:** `docs/jeongri/specs/2026-08-24-auditing-vulnerabilities-design.md`

## Global Constraints

- Skill name (gerund house style): **`auditing-vulnerabilities`** — must match the directory name and the `name:` frontmatter exactly.
- Two confidence numbers per finding, always: **`exploitability`** (0–100) and **`certainty`** (0–100). Never collapse to one.
- Severity bands, verbatim: **Critical / High / Medium / Low / Info**.
- PoC auto-generation gate: **exploitability > 75** (config default `poc_threshold = 75`).
- Verification (refutation) pass runs on **Critical and High only**.
- Checklist is **14 categories**, walked in order, explicit entry per category (finding or `No findings`).
- Report path (in the audited project): **`docs/security/YYYY-MM-DD-<scope>-audit.md`**.
- Field names are shared across all four files — keep them identical to the schema in Task 3: `title, category, cwe, owasp, file, line, severity, exploitability, certainty, evidence, remediation, poc, status`.
- House style: match `skills/reviewing-github-prs/SKILL.md` — announce line at top, phased workflow, severity table, verification subagent, anti-pattern table, communication tone section.

---

### Task 1: Scaffold skill + `SKILL.md` skeleton

**Files:**
- Create: `skills/auditing-vulnerabilities/SKILL.md`

**Interfaces:**
- Produces: the skill directory and a valid `SKILL.md` with frontmatter (`name`, `description`), the announce line, an Overview naming the four determinism levers, and the ordered seven-phase list. Later tasks fill each phase in place.

- [ ] **Step 1: Create the file with frontmatter + announce + overview + phase list**

Content required (draw prose from spec "Overview" + "Workflow"):

```markdown
---
name: auditing-vulnerabilities
description: Use when asked to audit a codebase, folder, or file for security vulnerabilities — fans out per-unit analysts over a fixed CWE/OWASP checklist, verifies high-severity findings by refutation, and writes a severity-ranked report with exploitability and certainty scores
---

# Auditing Vulnerabilities

Scope-targeted security audit... [Overview: the four determinism levers — fixed enumerated checklist; structured JSON schemas; adversarial refutation pass; numeric confidence gates.]

**Announce at start:** "I'm using the auditing-vulnerabilities skill to audit this scope for security vulnerabilities."

## Workflow

Seven phases in order:

1. **Scope & Setup** — ...
2. **Partition** — ...
3. **Analysis fan-out** — ...
4. **Aggregate & dedupe** — ...
5. **Verification** — ...
6. **PoC generation** — ...
7. **Report** — ...
```

Each phase is a one-line stub here; Tasks 2–4 expand them.

- [ ] **Step 2: Verify frontmatter parses and name matches**

Run:
```bash
python3 -c "import yaml,io; f=open('skills/auditing-vulnerabilities/SKILL.md').read(); fm=f.split('---')[1]; d=yaml.safe_load(fm); assert d['name']=='auditing-vulnerabilities', d['name']; assert d.get('description'); print('frontmatter OK')"
```
Expected: `frontmatter OK`

- [ ] **Step 3: Verify announce line and all seven phases present**

Run:
```bash
grep -q "I'm using the auditing-vulnerabilities skill" skills/auditing-vulnerabilities/SKILL.md && \
for p in "Scope & Setup" "Partition" "Analysis fan-out" "Aggregate & dedupe" "Verification" "PoC generation" "Report"; do \
  grep -q "$p" skills/auditing-vulnerabilities/SKILL.md || { echo "MISSING: $p"; exit 1; }; done && echo "phases OK"
```
Expected: `phases OK`

- [ ] **Step 4: Commit**

```bash
git add skills/auditing-vulnerabilities/SKILL.md
git commit -m "feat(auditing-vulnerabilities): scaffold skill with frontmatter and phase list"
```

---

### Task 2: `SKILL.md` — Scope & Setup, Partition, scale guards, config

**Files:**
- Modify: `skills/auditing-vulnerabilities/SKILL.md` (expand phases 1–2)

**Interfaces:**
- Consumes: the phase stubs from Task 1.
- Produces: concrete scope-resolution rules, the config table, the filter list, the unit-partition rule, bounded concurrency, and the hard scale guard — consumed conceptually by the fan-out orchestration in Task 4.

- [ ] **Step 1: Expand phase 1 (Scope & Setup) and phase 2 (Partition)**

Author from spec sections "Scope Resolution & Configuration" and "Partition & Scale Guards". Must include:
- Scope from skill argument (dir or file); default repo root **and confirm before a full-repo run**.
- The config table verbatim:

```markdown
| Knob | Default | Effect |
|---|---|---|
| `scope` | repo root | Directory or file to audit |
| `poc_threshold` | 75 | Min exploitability % for auto-generated PoC |
| `severity_floor` | Info | Lowest severity included in the report |
```

- Filter list: skip `node_modules`, `vendor`, `dist`, `build`, `.git`, lockfiles, minified/generated, binaries. Dependency category reads manifests only.
- Unit = one file, or a coupled module cluster capped ~1500 LOC.
- Bounded concurrency: batches of ~8–10, progress between batches.
- Hard scale guard: unit count > ~150 → stop and ask; never silently truncate; scan manifest logs covered vs skipped.

- [ ] **Step 2: Verify required knobs and guards present**

Run:
```bash
for s in "poc_threshold" "severity_floor" "node_modules" "1500" "150" "manifest"; do \
  grep -q "$s" skills/auditing-vulnerabilities/SKILL.md || { echo "MISSING: $s"; exit 1; }; done && echo "scope+partition OK"
```
Expected: `scope+partition OK`

- [ ] **Step 3: Commit**

```bash
git add skills/auditing-vulnerabilities/SKILL.md
git commit -m "feat(auditing-vulnerabilities): add scope, config, partition and scale guards"
```

---

### Task 3: `SKILL.md` — checklist, finding schema, severity rubric

**Files:**
- Modify: `skills/auditing-vulnerabilities/SKILL.md`

**Interfaces:**
- Produces: **the canonical finding schema and the 14-category checklist** — every other file (analyst, verifier, report template) references these exact field names and category numbers. This is the source of truth for field naming in the Global Constraints.

- [ ] **Step 1: Add the 14-category checklist table**

Copy the table verbatim from spec section "The Checklist (the anchor)" — 14 rows, columns `# | Category | Primary CWEs | OWASP`. Include the note: categories 1–13 closed/repeatable, category 14 (business-logic/race/TOCTOU) the open-ended slot. State the rule: walk in order, explicit entry per category, `No findings` is valid.

- [ ] **Step 2: Add the finding schema JSON block**

Exact block (source of truth):

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

Then the field semantics: `exploitability` (reachable/exploitable), `certainty` (confidence in the read, capped low without cross-file context), `status` (`unverified` → `confirmed`|`refuted`|`inconclusive`), `poc` (null until phase 6).

- [ ] **Step 3: Add the severity rubric table**

Copy verbatim from spec "Severity Rubric" — 5 bands with meaning and typical exploitability. State ranking: severity band, then exploitability % within band.

- [ ] **Step 4: Verify checklist completeness, schema validity, severity bands**

Run:
```bash
# 14 categories: CWE ids for all mapped rows appear
for c in 89 79 284 287 327 798 502 918 22 20 16 200 1104 367; do \
  grep -q "CWE-$c" skills/auditing-vulnerabilities/SKILL.md || { echo "MISSING CWE-$c"; exit 1; }; done
# schema JSON parses and has both confidence fields
python3 - <<'PY'
import re,json
t=open('skills/auditing-vulnerabilities/SKILL.md').read()
blk=re.search(r'\{\s*"title".*?"status":\s*"unverified"\s*\}', t, re.S).group(0)
d=json.loads(blk)
assert 'exploitability' in d and 'certainty' in d, d.keys()
assert d['status']=='unverified'
print('schema OK')
PY
# 5 severity bands
for s in Critical High Medium Low Info; do grep -q "$s" skills/auditing-vulnerabilities/SKILL.md || { echo "MISSING band $s"; exit 1; }; done
echo "checklist+schema+severity OK"
```
Expected: `schema OK` then `checklist+schema+severity OK`

- [ ] **Step 5: Commit**

```bash
git add skills/auditing-vulnerabilities/SKILL.md
git commit -m "feat(auditing-vulnerabilities): add checklist, finding schema and severity rubric"
```

---

### Task 4: `SKILL.md` — orchestration (fan-out, aggregate, verify, PoC, report), tone, anti-patterns

**Files:**
- Modify: `skills/auditing-vulnerabilities/SKILL.md`

**Interfaces:**
- Consumes: config + partition (Task 2), schema + severity (Task 3).
- Produces: the orchestration prose that dispatches `analysis-subagent.md` (Task 5) and `verification-subagent.md` (Task 6) and fills `report-template.md` (Task 7). Names those three files by path.

- [ ] **Step 1: Expand phases 3–7 + tone + anti-patterns**

Author from spec sections "Analyst Subagent", "Verification Subagent", "PoC Generation", "Report", "Communication Tone", "Anti-Patterns". Must state:
- Phase 3: dispatch analysts in bounded batches, one per unit, using `analysis-subagent.md`.
- Phase 4: merge, dedupe (same CWE + same root cause), rank by band then exploitability %.
- Phase 5: refutation verify **Critical/High only** via `verification-subagent.md`; Confirmed locks severity, Refuted drops/downgrades, Inconclusive keeps + caps exploitability at 60.
- Phase 6: PoC only for confirmed findings with exploitability > `poc_threshold` (75); else tag "PoC available on request."
- Phase 7: write `docs/security/YYYY-MM-DD-<scope>-audit.md` via `report-template.md`; echo summary in chat.
- Anti-pattern table copied verbatim from spec.

- [ ] **Step 2: Verify orchestration references and gates**

Run:
```bash
for s in "analysis-subagent.md" "verification-subagent.md" "report-template.md" "Critical/High" "poc_threshold" "docs/security/" "PoC available on request"; do \
  grep -q "$s" skills/auditing-vulnerabilities/SKILL.md || { echo "MISSING: $s"; exit 1; }; done && echo "orchestration OK"
```
Expected: `orchestration OK`

- [ ] **Step 3: Verify no placeholders left in SKILL.md**

Run:
```bash
! grep -nE "TBD|TODO|FIXME|\.\.\.$|fill in|implement later" skills/auditing-vulnerabilities/SKILL.md && echo "no placeholders"
```
Expected: `no placeholders`

- [ ] **Step 4: Commit**

```bash
git add skills/auditing-vulnerabilities/SKILL.md
git commit -m "feat(auditing-vulnerabilities): add orchestration, tone and anti-patterns"
```

---

### Task 5: `analysis-subagent.md`

**Files:**
- Create: `skills/auditing-vulnerabilities/analysis-subagent.md`

**Interfaces:**
- Consumes: the checklist + schema (Task 3) by reference.
- Produces: the per-unit analyst prompt template dispatched in phase 3.

- [ ] **Step 1: Author the analyst template**

From spec "Analyst Subagent". Must instruct:
- Input: one unit's files + the full 14-category checklist + the schema.
- Walk all 14 categories in order; explicit entry per category; never skip a row.
- Trace reachability (sink reached from entry point / untrusted input?) → drives `exploitability`.
- Unresolved cross-file call → record assumption in `evidence`, cap `certainty`.
- Output: **only** the JSON findings array, no prose.

- [ ] **Step 2: Verify required instructions present**

Run:
```bash
for s in "14" "explicit entry" "reachab" "certainty" "JSON"; do \
  grep -qi "$s" skills/auditing-vulnerabilities/analysis-subagent.md || { echo "MISSING: $s"; exit 1; }; done && echo "analyst OK"
```
Expected: `analyst OK`

- [ ] **Step 3: Commit**

```bash
git add skills/auditing-vulnerabilities/analysis-subagent.md
git commit -m "feat(auditing-vulnerabilities): add analyst subagent template"
```

---

### Task 6: `verification-subagent.md`

**Files:**
- Create: `skills/auditing-vulnerabilities/verification-subagent.md`

**Interfaces:**
- Consumes: a single finding (schema from Task 3).
- Produces: the adversarial refutation verifier dispatched in phase 5.

- [ ] **Step 1: Author the verifier template**

From spec "Verification Subagent". Must include:
- Refute framing: prove the finding is NOT exploitable (sanitized upstream / unreachable / safe sink / inflated severity); default skeptical.
- Three outputs: **Confirmed** (attack path evidence, lock severity, set exploitability from proven path), **Refuted** (reason; drop or downgrade to Info), **Inconclusive** (what's open; keep, cap exploitability at 60, flag uncertainty).

- [ ] **Step 2: Verify refute framing and three verdicts present**

Run:
```bash
for s in "refute\|Refute\|NOT exploitable" "Confirmed" "Refuted" "Inconclusive" "60"; do \
  grep -qE "$s" skills/auditing-vulnerabilities/verification-subagent.md || { echo "MISSING: $s"; exit 1; }; done && echo "verifier OK"
```
Expected: `verifier OK`

- [ ] **Step 3: Commit**

```bash
git add skills/auditing-vulnerabilities/verification-subagent.md
git commit -m "feat(auditing-vulnerabilities): add refutation verifier template"
```

---

### Task 7: `report-template.md`

**Files:**
- Create: `skills/auditing-vulnerabilities/report-template.md`

**Interfaces:**
- Consumes: the finding schema (Task 3) — the summary-table columns are the schema fields.
- Produces: the Markdown report structure filled in phase 7.

- [ ] **Step 1: Author the report template**

From spec "Report". Four sections: (1) Header — scope, date, unit count, files skipped, config used; (2) Summary table — one row per finding: severity, title, CWE, OWASP, file:line, exploitability %, certainty %, status; (3) Per-finding detail, most-severe first: title, location, evidence/attack path, remediation, PoC if generated, status; (4) Coverage note — scanned, skipped + why, any truncation.

- [ ] **Step 2: Verify all four sections and both confidence columns**

Run:
```bash
for s in "Header\|Scope" "Summary" "exploitability" "certainty" "Per-finding\|Detail" "Coverage"; do \
  grep -qiE "$s" skills/auditing-vulnerabilities/report-template.md || { echo "MISSING: $s"; exit 1; }; done && echo "report OK"
```
Expected: `report OK`

- [ ] **Step 3: Commit**

```bash
git add skills/auditing-vulnerabilities/report-template.md
git commit -m "feat(auditing-vulnerabilities): add report template"
```

---

### Task 8: Integration — version bump, cross-file consistency, registration

**Files:**
- Modify: `.claude-plugin/plugin.json`
- Modify: `.claude-plugin/marketplace.json` (if the version also lives there — verify first)
- Modify: `README.md` (optional skill mention, if README lists skills — verify first)

**Interfaces:**
- Consumes: all four skill files.
- Produces: a released, consistent skill.

- [ ] **Step 1: Confirm skill is auto-discovered (no manifest entry needed)**

Run:
```bash
ls skills/auditing-vulnerabilities/ && echo "--- confirm reviewing-github-prs has no explicit registration ---" && grep -rl "reviewing-github-prs" .claude-plugin/ || echo "skills auto-discovered (none listed in manifest) — no registration needed"
```
Expected: four files listed; registration confirmed unnecessary (mirrors the existing skill).

- [ ] **Step 2: Bump version 1.0.2 → 1.1.0**

Update `version` in `.claude-plugin/plugin.json` (both the top-level and the nested `plugins[0]` entry). Check `marketplace.json` for a version field and bump it too if present.

Run:
```bash
grep -n "\"version\"" .claude-plugin/*.json
```
Expected: all version fields read `1.1.0`.

- [ ] **Step 3: Cross-file field-name consistency check**

Run:
```bash
python3 - <<'PY'
import glob
fields=["exploitability","certainty","poc","status","severity"]
files=glob.glob("skills/auditing-vulnerabilities/*.md")
txt="\n".join(open(f).read() for f in files)
for f in fields:
    assert f in txt, f"field {f} missing across skill files"
# threshold consistent
assert txt.count("75")>=1 and "poc_threshold" in txt
# severity bands
for b in ["Critical","High","Medium","Low","Info"]:
    assert b in txt, b
print("cross-file consistency OK")
PY
```
Expected: `cross-file consistency OK`

- [ ] **Step 4: Full placeholder scan across the skill**

Run:
```bash
! grep -rnE "TBD|TODO|FIXME|fill in|implement later" skills/auditing-vulnerabilities/ && echo "no placeholders"
```
Expected: `no placeholders`

- [ ] **Step 5: Commit**

```bash
git add .claude-plugin/ README.md skills/auditing-vulnerabilities/
git commit -m "feat(auditing-vulnerabilities): bump to v1.1.0 and finalize skill"
```

---

## Self-Review

**Spec coverage:**
- Overview / determinism levers → Task 1 (Overview) + enforced structurally across Tasks 3–6.
- Workflow 7 phases → Tasks 1 (list), 2 (1–2), 4 (3–7).
- Scope resolution & config → Task 2.
- Partition & scale guards → Task 2.
- Checklist (14 cats) → Task 3.
- Finding schema (dual confidence) → Task 3.
- Severity rubric → Task 3.
- Analyst subagent → Task 5.
- Verification subagent → Task 6.
- PoC generation → Task 4 (gate) + Task 6 (verdict feeds it).
- Report + template → Task 4 (phase) + Task 7 (template).
- Tone + anti-patterns → Task 4.
- File location (4 files) → Tasks 1, 5, 6, 7; registration → Task 8.

No gaps.

**Placeholder scan:** Task 1's `...` phase stubs are intentional one-line stubs expanded in Tasks 2/4, and Task 4 Step 3 explicitly greps them out before release. Verified elsewhere via the no-placeholder checks in Tasks 4 and 8.

**Type consistency:** Field names fixed in Task 3 schema and asserted identical across files in Task 8 Step 3. Severity bands, `poc_threshold=75`, and "Critical/High only" verification are stated once in Global Constraints and checked in Tasks 3, 4, 8.
