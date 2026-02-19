---
name: before-pr-review
description: Have a look at the diff from parent branch and review the code thoroughly
license: MIT
compatibility: opencode
---

## What I do
- Make sure that the parent branch is up to date by doing `git pull` on the parent branch (parent branch will be specified later on in this prompt)
- Get a diff from the parent branch to see all the changes that's been made for this specific ticket
- Only review the FE changes and any changes made by me: Alan Napieralski
- Review the code thoroughly and find issues in: code quality, best practices, performance, potential bugs, accessibility breaches, unnecesssary repetition of code, wrong spacing or indentation, unrelated or unused code, unnecessary redundancy.
- Have a look at the whole picture, the overall structure and make sure that everything looks fine. 
- While reviewing please make sure to assess based on these rules
    - Never use IIFE since drupal is handling the javascript init in a correct order anyway
    - Never use ready listener and similar since the drupal is loading javascript after the DOM is leaded anyway
    - Always use data-attributes if possible for the javascript functionality, since we want the classes to only handle the the styling
    - Limit the usage of IDs in markup
    - Make sure that all the buttons have an appropriate type
    - Prefer using the safer &hellip; type alternatives. For ... here as an example.
    - For every code you edit, make the most minimal changes possible since we don't want to change the existing logic too much. Just enough to solve a problem described
    - Avoid using overcomplicated and nested solutions. Especially for CSS 
    - Try to never use hardcoded values unless it's not possible otherwise, or when the hardcoding is intentional
    - Never use Timeout function. It creates many race condition problems
    - When creating a new template. Always copy the initial comments and the structure from the original file. So when making a new node-- template I would copy node.html.twig template first and then made the changes on top of it.
    - Buttons with generic text like MUST include sr-only text to provide context for screen readers. Examples: ❌ `<button>Load more</button>` ✅ `<button>Load more <span class="sr-only">courses</span></button>` ✅ `<button aria-label="Load more courses">Load more</button>`
    - Try not to abbreviate the variable names too much since they are mainly for the developer's benefit. Make the variable names as concise and descriptive about what they do as possible
    - When using \`|render\` to inspect Twig render arrays (e.g., for conditional checks), always output the rendered variable with \`|raw\` to prevent HTML escaping. Example: \`{% set rendered = children|render %}{% if 'something' in rendered %}{{ rendered|raw }}{% endif %}
    - Don't implement things with JS, especially with a lot of lines of code since that introduces a lot of potentional runtime errors which we want to avoid at all cost. Stick to simple solutions that do the job and don't introduce any maintainability nightmares in the future. Of course it's different while working with vue files.
    - e.g.  &--multi-colour {} We must avoid chaining CSS in this way. It makes it hard to search for the selector in the CSS and doesn’t really add any value
    - make sure that we're using the best tool for the job. Use tools that are provided with things that we're already using. For example, if we're already using Vue in the file, use VueUse for event listeners, and not native, since they're simply better and made for the job. Apply that thinking to all the tools, utils and libraries we're using.
