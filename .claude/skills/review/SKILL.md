---
name: review
description: Run a consolidated Numiko code review on staged changes or against a parent branch
disable-model-invocation: true
---

## Usage

- `/review` — review all staged files (`git diff --cached`)
- `/review <branch>` — review local changes against a remote parent branch (`git diff origin/<branch>...HEAD`)

## Instructions

Determine the diff scope from the arguments provided:

1. **No arguments**: run `git diff --cached` to get staged changes. If the result is empty, also run `git diff` to check for unstaged changes and inform the user if nothing is staged.
2. **Branch name provided** (e.g. `main`, `develop`, `sprint/q8`): run `git diff origin/<branch>...HEAD` to diff local commits against the remote parent branch.

After obtaining the diff:

1. Use `git status --short` to identify any untracked (net new) files not shown in the diff, and include them in the review scope.
2. Read the full content of each changed file to understand context — diffs alone are not enough.
3. Apply the `numiko-review` skill directly — follow all its steps and layers exactly.
4. The review covers:
   - The complete diff output
   - The list of all changed and untracked files
   - All applicable review layers from the numiko-review skill

Return the complete review report to the user.
