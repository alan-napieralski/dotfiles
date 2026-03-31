---
name: jira-ticket-review
description: Fetch assigned Jira tickets from a project and produce a prioritised, actionable review table showing what to work on today, complexity estimates, and BE dependencies
disable-model-invocation: true
---

# Jira Ticket Review

You are helping a **frontend developer** plan their work. Goal: a prioritised table of their Jira tickets so they know what to tackle first, how long each will take, and whether BE needs to act first.

If the user hasn't specified a project key, ask before proceeding.

## Step 1 — Gather tickets

1. Call `atlassian_getAccessibleAtlassianResources` → `cloudId`
2. Call `atlassian_atlassianUserInfo` → `accountId`
3. Fetch with `atlassian_searchJiraIssuesUsingJql`:
   - JQL: `project = {PROJECT_KEY} AND assignee = "{accountId}" AND statusCategory != Done AND status NOT IN ("Approved", "Ready for Approval", "Dev Done", "Closed", "Closed by QA") ORDER BY updated DESC`
     - Use the literal `accountId` value retrieved in step 2 — never use `currentUser()` as it resolves to the API token's identity, not the user's
   - Fields: `summary, description, priority, status, comment, labels, customfield_10016, customfield_10020`
   - Max results: 50
4. **Strict assignee validation**: After fetching, discard any issue where `fields.assignee.accountId` does not exactly match the `accountId` from step 2. Log discarded tickets as a warning (e.g. "Skipped PROJ-123 — assignee mismatch"). This guards against `currentUser()` resolving incorrectly or JQL returning unexpected results.
5. Use the comments returned in the bulk result directly. Do **not** do per-ticket fetches — that creates expensive API cascades. Read the **latest 5 comments** per ticket by default; expand to 15 if those 5 reference an ongoing unresolved discussion (back-and-forth disagreement, multiple stakeholders, unresolved blocker). No date cutoff — old comments on untouched tickets can still be the most relevant signal.

## Step 2 — Exclude tickets that are effectively done

Filter before scoring. Excluded tickets are not scored.

- Exclude if `statusCategory = Done`
- Exclude done-like statuses: `Dev done`, `Ready for approval`, `Ready for QA`, `Closed`, `Resolved`, `Merged`, `Deployed`, `Approved`, `Ready for Approval`, `Closed by QA` — normalise status names (trim, lowercase, collapse whitespace) before matching
- **Override**: if newer evidence exists after the done-like state (reopen comment, failed QA pointing to FE, reviewer requesting FE changes), keep the ticket and mark it **needs confirmation**
- If unsure → keep in scored set, mark **needs confirmation**

## Step 2b — Route tickets into buckets

All surviving (non-excluded) tickets must be routed into exactly one of three buckets:

**Bucket A — Pushed back / no FE action**
A ticket belongs here if ALL of the following are true:
- The latest comment(s) explicitly state that nothing can be done from a FE perspective — e.g. "this is native browser behaviour", "out of scope", "advising client not to do this", "no fix possible", "by design"
- There is no newer comment re-opening the question or requesting FE to try something else
→ Move to **Excluded** with reason: "pushed back — latest comments confirm no FE action possible"

**Bucket B — Amendments (open PR)**
A ticket belongs here if it has an open Bitbucket pull request. To detect this:
- Use `bitbucket_listRepositories` to find repos in the workspace (default workspace is `numiko`), then `bitbucket_getPullRequests` with `state: OPEN` filtered by branch names matching the ticket key (e.g. `FINDS-760`). Do this efficiently — batch where possible, do not do one API call per ticket naively.
- Also check Jira comments for explicit PR mention (e.g. "PR open", "pull request", a Bitbucket URL) as a fallback signal.
- Tickets where FE work is complete and a PR is open (even if `Dev done`, `In Progress FE`, `Rejected`) → route to Amendments bucket.
- A `Dev done` ticket with a reopen signal from QA/reviewer AND an open PR → still goes to Amendments (not the scored table), because the action is responding to review feedback, not starting fresh work.

**Bucket C — New work**
Everything else: tickets where FE work hasn't started or needs to start fresh. These go to the scored Priority table.

## Step 3 — BE dependency check

For each remaining ticket, read description and latest comments. Does this ticket need anything from BE before you can start — CMS fields, API endpoints, env vars, feature flags, content types, data models, auth changes?

- **Needs BE first** — clear blocker (be specific: "needs `hero_subtitle` CMS field")
- **FE ready** — everything in place
- **Unclear** — genuinely can't tell

## Step 4 — Score and sort

Score each ticket out of 15. Show the breakdown.

**JP — Jira priority (0–4)**
Blocker → 4 / Critical → 3 / Major or High → 2 / Medium → 1 / Minor, Low, or None → 0

**DU — Discussion urgency & actionability (0–4)**
Read description, acceptance criteria, and latest 5–10 comments.
- 4 = Explicit blocker/escalation/reopen with actionable pending FE work
- 3 = Clear urgency or someone actively waiting on FE
- 2 = Moderate urgency, action likely needed
- 1 = Mild or unclear urgency
- 0 = Latest comments indicate nothing to do / already resolved

Weight the latest comments and commenter context (PM escalation, QA blocker, reviewer requesting changes). Downgrade if the latest conversation signals closure.

**SP — Sprint pressure (0–3)**
Use `customfield_10020` for sprint end date. If unavailable, look for clues in the sprint name.
- Ending within ~2 days AND still open → 3
- Ending within ~5 days → 2
- Active sprint, plenty of time → 1
- No sprint or unavailable → 0

**PR — PR activity (0–2)**
Default 0. Only score higher if the user confirms an open PR or a Jira comment explicitly mentions one.
- Open PR with recent review activity → 2
- Open PR, no recent activity → 1
- No PR → 0

**CB — Complexity bonus (0–2)**
Harder tasks score higher — they need to surface early so you can ask questions and avoid last-minute surprises.
- Complex (significant feature, multiple files/components, uncertain scope) → 2
- Medium complexity → 1
- Trivial (single small change, obvious solution) → 0

**Estimated time** — 0.5h increments. Use `Xh` when confident, `Xh–Yh` for uncertainty. Covers investigation + implementation only. For flaky bugs or wide-ranging scope, use a range and note the reason in per-ticket notes.

## Step 5 — Output

**Legend:** JP = Jira Priority (0–4), DU = Discussion Urgency (0–4), SP = Sprint Pressure (0–3), PR = PR Activity (0–2), CB = Complexity Bonus (0–2)

### New Work

| # | Ticket | Summary | Score | Breakdown | Est. Time | BE Status | Sprint |
|---|--------|---------|-------|-----------|-----------|-----------|--------|
| 1 | [PROJ-123](link) | Short summary | 12/15 | JP:3 DU:3 SP:3 PR:1 CB:2 | 4.5h | Needs BE first | Sprint 24 |
| 2 | [PROJ-456](link) | Short summary | 8/15 | JP:2 DU:1 SP:2 PR:2 CB:1 | 1h–2.5h | FE ready | Sprint 24 |

Sort descending by score.

### Amendments — Open PRs

| Ticket | Summary | Action needed | Sprint |
|--------|---------|---------------|--------|
| [PROJ-789](link) | Short summary | Respond to Jake's review comment on image sizing | Sprint 24 |

Sort by most recently updated first (use Jira updated order from the original fetch). Do not score these tickets.

### Excluded

- **[PROJ-321](link)** — status `Ready for QA`; latest evidence (comment, 2026-03-09, QA analyst, Jira) confirms FE work complete.
- **[PROJ-654](link)** — latest comment (2026-03-08, Isaac Marshall, Jira) confirms PR merged with no subsequent reopen or blocker.
- **[PROJ-999](link)** — pushed back; latest comment (date, author) confirms no FE action possible: "this is native browser behaviour for date pickers on iOS/Android".

### Per-ticket notes

Only for tickets that need elaboration — BE blockers, wide estimates, contested scope, anything the table can't capture.

**PROJ-123 — Summary**
- **BE blocker**: Needs `hero_subtitle` field on `LandingPage` content type. Ping BE today.
- **Note**: PM comment 2 days ago asking for update — gentle urgency.

### Closing summary

One paragraph of genuine tech-lead advice. What's the single most important action right now? Which tickets become risky if you wait? Make it feel read, not generated.

## Notes on tool efficiency

- One JQL fetch for all tickets — never fetch per-ticket
- Reuse `cloudId` and `accountId` — don't re-fetch
- No Figma MCP or local codebase reads
- No per-ticket comment fetches — use what the bulk JQL returns
- No description or comments → mark "insufficient info", score conservatively
- If the API response is truncated or too large, re-fetch with `maxResults: 25` — do **not** delegate file parsing to an explore agent or read temp files

## Execution notes
- Call all Atlassian and Bitbucket tools directly and synchronously — do NOT delegate to explore/researcher agents
- Do NOT delegate file reads — use the read tool directly if needed
- The only acceptable delegation is if two genuinely independent long-running tasks can run in parallel with no other productive work possible in the meantime
