---
name: numiko-review
description: Consolidated Numiko code review covering Drupal backend, frontend (Twig/SCSS/JS), Vue, and config — apply when reviewing any changed files in a Numiko project
---

# Numiko Review Skill

You are performing a consolidated Numiko code review. Follow every step in order.

---

## Step 1 — Get the diff

The diff has already been provided to you (either from the `/review` command or directly). Use it to identify every changed file.

---

## Step 2 — Read personal patterns

Read the file at `~/.claude/CLAUDE.md`. Every coding rule in that file is a personal coding rule that must be checked against the changed code. Treat violations as findings.

---

## Step 3 — Detect file types in scope

Categorise the changed files:

- **Drupal backend**: `.php`, `.module`, `.install`, `.theme`, `.inc`, `*.services.yml`, `*.routing.yml`, `*.permissions.yml`, `*.info.yml`
- **Drupal config**: `config/install/*.yml`, `config/optional/*.yml`
- **Frontend**: `.twig`, `.html.twig`, `.component.yml`, `.scss`, `.css`, `.js` (non-Vue), `.ts` (non-Vue)
- **Vue**: `.vue`, composables, Vue-adjacent `.ts`

---

## Step 4 — Load applicable review layers

Always apply:

- **4-Layer review** (see below): applies to every file

Apply conditionally based on file types detected in Step 3:

- Any **Drupal backend** files → apply Drupal Backend rules (see below)
- Any **Frontend / Twig** files → apply Frontend rules (see below)
- Any **Vue** files → apply Vue rules (see below)

---

## Step 5 — Run a single unified review pass

Review all files together. Do not split into separate reports. Apply all loaded layers simultaneously and produce one report.

---

## Review Layers

### Layer A — 4-Layer Code Review (always applies)

For every changed file, check:

1. **Correctness** — Logic errors, wrong conditionals, off-by-one, unhandled edge cases (null/empty/undefined), broken error handling
2. **Security** — Injection, auth bypass, data exposure, missing sanitisation, unescaped output
3. **Performance** — O(n²) on unbounded data, N+1 queries, blocking I/O on hot paths, missing cache metadata
4. **Style** — Does it follow existing patterns? Excessive nesting? Poor naming? Unnecessary complexity?

Only report findings with ≥80% confidence. If uncertain, investigate before flagging.

---

### Layer B — Drupal Backend rules (when .php / config present)

**Security:**

- No raw SQL — use `$this->database->select()` with placeholders
- All output must be sanitised — `Html::escape()`, `Xss::filter()`, or render arrays
- Never expose sensitive data in logs or error messages
- Access checks must use `->accessCheck(TRUE)` on entity queries
- No hardcoded credentials or tokens
- CSRF protection on all state-changing forms

**Dependency Injection:**

- No `\Drupal::service()` calls inside class methods — use constructor injection
- Classes must implement `ContainerInjectionInterface` or `ContainerFactoryPluginInterface`
- Services must be declared in `.services.yml`

**Coding Standards:**

- PSR-4 namespacing
- Docblocks on all public methods
- No deprecated Drupal APIs
- All user-facing strings wrapped in `t()`
- PHP 8 attributes preferred over annotations

**Performance:**

- Cache metadata (`CacheableMetadata`, `#cache`) on all render arrays that depend on dynamic data
- No entity loads or DB queries inside loops
- Lazy-load services where possible

**Config:**

- Config schema must exist in `config/schema/`
- UUIDs preserved on config export
- `config/install` only for truly default config

**Project-specific checks:**

- Shared field storage reused via `createDuplicate()` — NOT `drush field:create` (which creates duplicate storage)
- All standard shared fields present on new content types: `field_slices`, `field_image`, `field_teaser_summary`, `field_hero_media`, `field_hero_title`, `field_meta`
- Content types added to `workflows.workflow.editorial`
- Form display uses `field_group` tabs — Content / Hero / Teaser (not a flat list)
- Custom fields are in `content:` not `hidden:` in the form display YAML
- `field_slices` widget uses `add_mode: modal` and `dialog_style: tiles`
- `hidden:` contains only `langcode`, `promote`, `status`, `sticky`
- Slice paragraph types are prefixed `slice_` — item types have no prefix
- Item types are NOT registered in node `field_slices` — only slice types are
- Paragraph form display is flat (no `field_group` tabs) with `hidden: [created, status, uid]`
- Config export/import order followed: export AFTER creating types/fields but BEFORE writing display YAMLs; import AFTER writing display YAMLs
- Display YAML files preserve the `uuid` assigned by Drupal on first export
- Dev-only config changes are in `config/dev/` not `config/sync/`

Before reviewing PHP code, check coding standards:
```bash
docker compose exec web ./vendor/bin/phpcs -p docroot/modules/custom/
```
If PHPCS errors exist, note them as findings (ask developer to run `phpcbf` first if severe).

---

### Layer C — Frontend rules (when .twig / .scss / .js present)

**Twig:**

- `attributes.addClass()` must be used — never hardcoded class strings in attribute positions
- `{% include %}`/`{% embed %}` must always use the `only` keyword
- No inline styles
- Component class prefix must be `c-`
- No Drupal globals accessed directly in templates
- Use `{% block %}` for slots, `{% if %}` guards for optional content
- When using `|render` to inspect render arrays for conditional checks, always output with `|raw` to prevent HTML escaping: `{% set rendered = var|render %}{% if 'x' in rendered %}{{ rendered|raw }}{% endif %}`
- New templates must copy initial comments and structure from the original Drupal template file before modifying
- Paragraph template filename matches convention: `paragraph--slice-[name-without-slice-prefix].html.twig`
- Field data passed through Twig filters (`|field_display_value`) not raw field arrays
- Nested paragraph items iterated via `content.field_items['#items']`
- Media fields passed as rendered output, not raw entity references

**SDC Component YAML (`component.yml`):**

- `$schema` field present
- `attributes` prop defined with type `Drupal\Core\Template\Attribute`
- All props have explicit types (string, boolean, array, object)
- Enum values defined where the prop has a fixed set of options
- Slot `required` field specified

**CSS / SCSS:**

- Filenames must use underscores; CSS files prefixed with `_` (non-entry chunk for Vite)
- Only write styles that Tailwind cannot handle
- No hardcoded hex values — use design tokens / CSS custom properties
- No chained BEM modifiers as combined selectors (e.g. `&--modifier-a&--modifier-b {}` — hard to search for)
- Avoid overcomplicated or deeply nested rules

**JavaScript:**

- Filenames must use underscores; JS files prefixed with `_` (non-entry chunk for Vite)
- Use `data-js-*` attributes as selectors — never class names or IDs
- Must be registered in `framework/src/js/dynamic-imports/main-site.js` (or equivalent entry point)
- No global state
- No IIFE — Drupal handles JS init order
- No `document.ready` or equivalent listeners — Drupal loads JS after DOM is ready
- No `setTimeout` / `setInterval` — race condition risk
- Keep JS minimal; prefer CSS or Twig solutions
- If already using Vue, use VueUse for event listeners, not native

**Tailwind:**

- No raw hex values in class props (e.g. `text-[#abc123]`) — use semantic tokens
- No default Tailwind palette colours (e.g. `bg-blue-500`) — project tokens only
- Use only project-defined breakpoints: `sm:`, `md:`, `lg:`, `xl:`, `2xl:`, `3xl:`
- Fluid typography uses `text-h1`–`text-h6` / `text-body-*` — not `text-xl`, `text-sm` etc for headings
- Dark mode via `data-theme="dark"` on a parent — no `dark:` Tailwind variant needed

**Accessibility:**

- All buttons must have an explicit `type` attribute
- Buttons with generic text (e.g. "Load more", "Close") must include `sr-only` context text or an `aria-label`
- Limit use of `id` attributes in markup

**Naming:**

- Variable names must be descriptive — no excessive abbreviation
- Prefer verbose and readable over terse

---

### Layer D — Vue rules (when .vue present)

- Use VueUse for all event listeners and utilities — not native browser APIs
- No direct DOM manipulation — use Vue's reactivity system
- Composition API (`setup()`) preferred over Options API
- Props must be typed
- No global state outside of dedicated stores (Pinia)
- Use the best available tool/composable for the job rather than reimplementing

---

## Step 6 — Output format

Produce a single unified report with this structure:

```
## Files Reviewed
[list each file with its type: Backend / Frontend / Vue / Config]

## Overall Assessment
APPROVE | REQUEST CHANGES | NEEDS DISCUSSION
[1–2 sentence summary]

## Critical
[Findings that must be fixed before merge — bugs, security issues, broken behaviour]

## Major
[Significant issues that should be addressed — wrong patterns, missing guards, accessibility failures]

## Minor
[Small issues worth fixing — naming, unnecessary complexity, minor convention violations]

## Nitpick
[Preferences and style — only include if genuinely useful]

## Numiko Patterns Compliance
[Check each rule from ~/.claude/CLAUDE.md — list any violations found, or confirm compliance]

## Positive Observations
[Always include — note what was done well]

## Philosophy Compliance
[Check against: Early Exit, Parse Don't Validate, Atomic Predictability, Fail Fast, Intentional Naming, Security by Default, Performance Awareness]
```

**Tone rules:**

- Direct and matter-of-fact — not accusatory, not sycophantic
- No "Great job", no "Thanks for", no flattery
- If you flag a bug, explain the exact scenario where it breaks
- Only flag findings with ≥80% confidence
- Do not review pre-existing unchanged code
