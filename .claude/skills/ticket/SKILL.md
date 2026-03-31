---
name: ticket
description: Analyse a Jira ticket and optional Figma design, then produce an approved frontend implementation plan before any implementation begins
disable-model-invocation: true
---

## Usage

- `/ticket PROJ-123` — analyse ticket only, prompt for Figma URL if relevant
- `/ticket PROJ-123 https://figma.com/design/...?node-id=1-2` — analyse ticket + Figma frame together

## Instructions

Parse the arguments:

- First token is the **Jira key** (e.g. `PROJ-123`)
- Second token (optional) is the **Figma URL**

### Step 1 — Gather context in parallel

Run all of the following at the same time:

1. **Jira** — fetch the full ticket using the Atlassian MCP: summary, description, acceptance criteria, linked issues, labels, and any attachments or comments.
2. **Figma** — if a Figma URL was provided, fetch the design context for that node using the Figma MCP. Extract: component structure, spacing, typography, colours, responsive behaviour, and any visible states (hover, active, empty, error).
3. **Codebase** — identify any existing components, templates, paragraph types, or SDC components that are relevant to the ticket. Return file paths and a brief description of what each does.

### Step 2 — Ask for initial thoughts

Once the context is gathered, present a brief summary of what the ticket is asking for and what the Figma design shows (if provided), then ask the user:

> "Before I write the plan — do you have any initial thoughts on the approach? For example: components to reuse, things to avoid, preferred patterns, or constraints I should know about."

Wait for their response. If they say "no" or "just go ahead", proceed without constraints.

### Step 3 — Generate the implementation plan

Apply the `plan-protocol` skill and produce a detailed frontend implementation plan that covers:

1. **Summary** — what is being built and why
2. **Figma → code mapping** — translate Figma design tokens (spacing, colour, type) to Tailwind classes or CSS custom properties used in the project; note any gaps where design doesn't map cleanly
3. **Component breakdown** — list each file to create or modify (template, SDC component, paragraph config, CSS, JS if unavoidable), with a brief description of what changes
4. **Reuse decisions** — explicitly state what will be reused vs built from scratch and why
5. **Constraints applied** — list any constraints from the user's initial thoughts
6. **Open questions** — anything ambiguous in the ticket or design that needs a decision before or during implementation
7. **Out of scope** — anything the ticket mentions that is backend/config work already done

Follow the personal coding rules in `~/.claude/CLAUDE.md` throughout: minimal changes, data-attributes for JS, no hardcoded values, no timeouts, sr-only text on ambiguous buttons.

Apply the `drupal-frontend` skill and `drupal-paragraph` skill as relevant to the ticket type.

### Step 4 — Approval gate

After presenting the plan, ask:

> "Does this plan look right, or would you like to adjust anything before I start implementing?"

- If the user approves → reply: "Plan approved. When you're ready, just say 'implement' and I'll start."
- If the user requests changes → update the plan and ask again
- Do NOT begin implementation until explicitly told to
