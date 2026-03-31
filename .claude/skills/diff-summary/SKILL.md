---
name: diff-summary
description: Summarise the current branch's git diff into a concise, PR-ready description grouped by feature/intent — invoke with /diff-summary {target-branch} {optional context}
disable-model-invocation: true
---

# Diff Summary

Generate a concise, PR-ready summary of all changes on the current branch compared to a target branch. The output is a scannable list grouped by feature or intent — small enough to paste straight into a pull request description.

## Invocation

```
/diff-summary {target-branch} {additional context / ticket description}
```

Parse the arguments as follows:
- The first word is the target branch
- Everything after the first word is optional additional context or ticket description

If no target branch is provided, ask the user for it before proceeding.

## Understanding the changes

You have three sources of truth for understanding *what* changed and *why*. Use them in this strict priority order — each level fills gaps left by the one above, not replaces it.

### 1. Session context (highest priority)

If this skill is invoked during a session where the changes were made, you already have rich context about the reasoning behind each change — the conversations, decisions, and trade-offs that led to them. This is the most accurate source because it captures actual intent, not just the result. Use it first.

### 2. Commit messages

Run `git log {target-branch}..HEAD --format="%h %s%n%b" --no-merges` to read the commit messages. Good commit messages reveal reasoning and intent. When session context is thin or absent (e.g. a fresh session), these become your primary source.

### 3. Agent inference from the diff (last resort)

Only fall back to reading and interpreting the raw diff when neither session context nor commit messages adequately explain a change. If additional context or a ticket description was provided by the user, use it to guide your reasoning. If you still can't determine the purpose of a specific change, say so briefly rather than guessing — honesty is more useful than speculation in a PR description.

## Steps

1. **Determine the target branch.** Use the one provided in the invocation. If missing, ask the user.

2. **Read commit messages.** Run `git log {target-branch}..HEAD --format="%h %s%n%b" --no-merges` to get subjects and bodies.

3. **Get a diff overview.** Run `git diff {target-branch}...HEAD --stat` for a file-level summary. This helps you understand the scope before diving in.

4. **Read the full diff where needed.** Run `git diff {target-branch}...HEAD` — or target specific files if the diff is large. Skip binary files.

5. **The final diff is the source of truth for what's in.** The final `git diff {target-branch}...HEAD` shows exactly what ended up in the branch — nothing more, nothing less. Commit messages and session context explain *why* and help with *grouping*, but they must never introduce changes into the summary that aren't visible in the final diff. If an earlier commit added something that a later commit removed or rewrote, it won't appear in the final diff — don't mention it.

6. **Group changes by feature or intent.** Don't organise file-by-file — group by what the changes achieve. A single feature might touch multiple files (group them together). A single file might contain changes for multiple purposes (split them across groups).

7. **Write both summaries.** Use the output format below — always produce both sections.

## Output format

Always produce **both** sections below, in this order.

---

### PR Summary

For developers and code reviewers. Technical, specific, grouped by feature or intent.

```markdown
## Changes:

**[Feature/intent group name]:**
- Change description with brief reasoning
- Another related change in this group

**[Another feature/intent group]:**
- Change description with brief reasoning
```

#### Writing guidelines

- **Be specific.** "Fixed table image sizing" is better than "CSS changes".
- **Include the why when it adds value.** "Added `min-w-[6rem]` to table images — prevents columns collapsing when the table overflows" beats "Added min-width to images".
- **Skip the obvious.** If a change is self-explanatory (typo fix, import cleanup), a brief description without reasoning is fine.
- **One line per change.** If you need two lines, the description is too detailed for a PR summary.
- **Don't list every file.** Group by intent, not by file path. Mention specific files only when it genuinely helps the reader understand the change.
- **Keep it short.** The whole summary should be scannable in under 30 seconds. If it's longer than ~15 bullet points, you're probably being too granular — step back and group more aggressively.
- **Only describe what's in the final diff.** Commit messages describe intent at the time of writing — some of those changes may have been overwritten, reverted, or superseded by later commits. Always verify against the final diff before including a change in the summary.

---

### QA Summary

For testers and Jira ticket comments. Plain language, no technical jargon — just what changed from a user or feature perspective, and what needs testing.

```markdown
Changes:

- **[Feature name]** — one sentence describing what it does now / what was fixed
- **[Another feature]** — same, written so a non-developer can understand it
```

#### Writing guidelines

- **No technical language.** No file names, class names, config keys, or CSS. Describe what the user sees or can do.
- **Focus on testable behaviour.** Each bullet should map to something QA can check in the browser or CMS.
- **Keep it brief.** Aim for 2–6 bullets. If it's longer, group more aggressively.
- **Use plain past or present tense.** "Underline formatting is now available in the editor" not "Added underline to CKEditor toolbar config".
