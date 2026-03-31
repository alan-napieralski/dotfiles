---
name: plan-review
description: Review implementation plans against quality standards — use when auditing plan quality for citation completeness, task actionability, and phase completeness
disable-model-invocation: true
---

# Plan Review

## TL;DR
Systematic plan review focused on 3 quality categories: Citation Quality, Completeness, and Actionability. Structure is pre-validated — focus on whether the plan provides actionable implementation guidance.

## When to Use This Skill
- When reviewing implementation plans before execution
- When auditing plan quality after creation
- When verifying plans meet documentation standards
- As part of the plan validation workflow

---

## Plan Review Checklist

### 1. Structure (Pre-validated)

> **Note:** Format compliance (YAML frontmatter, status markers, CURRENT marker, numbering) is guaranteed by the plan creation process.
> Focus your review on the quality aspects below.

### 2. Citation Quality

| Requirement | Check |
|-------------|-------|
| Decisions reference sources | `ref:delegation-id` format used |
| No unsubstantiated claims | Architectural decisions cite research |
| Research phases show refs | Completed research tasks include citations |
| Citations are verifiable | IDs match actual delegation outputs |

**Red Flags:**
- Decisions table with empty or `-` in Source column
- Claims like "industry standard" or "best practice" without citation
- Research tasks marked complete without `→ ref:id`

### 3. Completeness

| Requirement | Check |
|-------------|-------|
| Goal is specific | Measurable outcome, not vague intent |
| Phases are logical | Sequential, with clear progression |
| Edge cases considered | Error handling, failure modes addressed |
| Notes section present | Key decisions and observations documented |
| Context & Decisions table | Captures architectural choices with rationale |

**Goal Quality Examples:**
- "Improve authentication" (vague — not acceptable)
- "Make it better" (unmeasurable — not acceptable)
- "Add JWT authentication with refresh token support" (specific — acceptable)
- "Migrate user table to PostgreSQL with zero downtime" (measurable — acceptable)

### 4. Actionability

| Requirement | Check |
|-------------|-------|
| Tasks are specific | Clear what file/component is affected |
| No ambiguous tasks | Avoids "investigate" or "figure out" without scope |
| Dependencies clear | Sequential tasks show logical order |
| Implementation path obvious | Developer can start without clarification |

**Actionability Examples:**
- "Set up the backend" (too vague — not acceptable)
- "Make it work" (no implementation path — not acceptable)
- "Create `src/auth/jwt.ts` with sign/verify functions" (specific file — acceptable)
- "Add bcrypt password hashing to `UserService.create()`" (clear scope — acceptable)

---

## Severity Classification

| Severity | Criteria | Action Required |
|----------|----------|-----------------|
| Critical | Missing citations for key decisions, no clear goal, unactionable tasks | Must fix before execution |
| Major | Vague tasks, incomplete phases, missing edge case handling | Should fix |
| Minor | Missing notes, unclear dependencies, incomplete rationale | Nice to fix |
| Nitpick | Style preferences, wording suggestions | Optional |

---

## Output Format

Structure your plan review as:

```markdown
## Plan Review

### Files Reviewed
- `PLAN.md` (or plan content)

### Overall Assessment
APPROVE | REQUEST_CHANGES | NEEDS_DISCUSSION

### Summary
2-3 sentence overview of plan quality.

### Issues

#### Critical
- [Issue description with specific location]

#### Major
- [Issue description with specific location]

#### Minor
- [Issue description with specific location]

#### Nitpick
- [Suggestion]

### Quality Assessment

| Check | Status |
|-------|--------|
| Goal is specific and measurable | PASS / FAIL |
| Citations support key decisions | PASS / FAIL |
| Tasks are actionable | PASS / FAIL |
| Edge cases addressed | PASS / FAIL |

### Positive Observations
- [What's done well - always include at least one]
```

---

## What NOT to Do

- Do NOT re-validate format — plan creation handles structural validation
- Do NOT evaluate code quality (that's code-review's job)
- Do NOT execute or modify the plan during review
- Do NOT skip citation verification for decisions
- Do NOT accept vague goals or ambiguous tasks
- Do NOT forget to note positive observations

---

## Adherence Checklist

Before completing a plan review, verify:

- [ ] All 3 quality categories analyzed (Citations, Completeness, Actionability)
- [ ] Severity assigned to each finding
- [ ] Specific locations noted for all issues
- [ ] Quality Assessment table completed
- [ ] Positive observations noted
- [ ] Output follows the standard format
