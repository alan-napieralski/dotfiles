---
name: drupal-frontend
description: Use when creating or modifying frontend components, templates, or styles in the numiko Drupal theme — covers SDC component creation, Tailwind patterns, Vite build workflow, and JS dynamic imports
---

# Drupal Frontend

## Overview

The `numiko` theme uses:
- **SDC** (Single Directory Components) for all UI components
- **Tailwind CSS** with a custom multi-theme color token system
- **Vite** for building (with HMR in dev)
- **Twig** templates that include/embed SDC components
- **Dynamic JS imports** triggered by `data-js-*` attributes

**Theme path:** `docroot/themes/custom/numiko/`

**Build commands** (run from theme root):
```bash
npm run dev    # Vite dev server with HMR (port 5173, HTTPS)
npm run build  # Production build → dist/
npm run watch  # Watch mode build
```

Node version: `v24.12.0` (use `.nvmrc` — run `nvm use` before anything)

---

## Component Architecture

Components live in `components/` organised by atomic design tier:

| Tier | Path | Use for |
|---|---|---|
| `atoms/` | Simple, single-purpose UI elements | button, icon, image, wysiwyg |
| `molecules/` | Small combinations | accordion-item, video, statistic |
| `organisms/` | Complex, composite | hero, accordion, gallery, alert |
| `shared/` | Layout wrappers | layout |

---

## Creating a New SDC Component

Every component is a directory containing 2–4 files.

### Step 1: Create the directory

```
components/[tier]/[component-name]/
```

Use kebab-case. Match the tier to complexity.

### Step 2: Component YAML (`component-name.component.yml`)

```yaml
$schema: https://git.drupalcode.org/project/sdc/-/raw/1.x/src/metadata.schema.json
name: 'Component Name'
status: experimental
props:
  type: object
  properties:
    attributes:
      type: Drupal\Core\Template\Attribute
    title:
      type: string
    variant:
      type: string
      enum: [primary, secondary]
slots:
  my_slot:
    title: 'Slot label'
    required: false
```

**Always include `attributes`** — Drupal passes HTML attributes through it.

### Step 3: Twig template (`component-name.twig`)

```twig
{%
  set classes = [
    'c-component-name',
    variant ? 'c-component-name--' ~ variant,
  ]
%}

<div{{ attributes.addClass(classes) }}>
  {% if title %}
    <h2 class="text-h2 font-bold">{{ title }}</h2>
  {% endif %}
  {% block my_slot %}{% endblock %}
</div>
```

**Naming conventions:**
- BEM class prefix `c-` for components (`c-button`, `c-hero`)
- Always use `attributes.addClass()` — never replace `attributes` entirely
- Use Tailwind utility classes for layout/spacing; `c-*` classes for component identity

### Step 4: CSS (`_component-name.css`) — only if needed

Prefix with `_` — Vite treats these as non-entry CSS chunks.

```css
.c-component-name {
  /* Only styles that can't be done with Tailwind */
  /* Use Tailwind utilities in the template instead */
}
```

### Step 5: JavaScript (`_component-name.js`) — only if needed

Prefix with `_`. Use `data-js-*` attributes as hooks — never select by class or ID.

```javascript
const elements = document.querySelectorAll('[data-js-component-name]');
elements.forEach((el) => {
  // initialise behaviour
});
```

Then **register the dynamic import** in `framework/src/js/dynamic-imports/main-site.js`:

```javascript
'[data-js-component-name]': () => import('@components/[tier]/component-name/_component-name.js'),
```

The import only fires if the selector matches — safe to add all components.

---

## Tailwind Usage

### Breakpoints

| Name | px |
|---|---|
| `sm` | 375 |
| `md` | 768 |
| `lg` | 1024 |
| `xl` | 1280 |
| `2xl` | 1440 |
| `3xl` | 1920 |

```twig
<div class="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3">
```

### Color tokens

Colors come from a semantic theme system — never use raw hex or Tailwind default colors. Use semantic surface/button/state tokens:

```twig
{# Surface colors #}
<div class="bg-surface-primary-background text-surface-primary-foreground">

{# Button colors #}
<button class="bg-button-primary-background text-button-primary-foreground
               hover:bg-button-primary-background-hover">

{# State colors #}
<div class="bg-surface-critical-background text-surface-critical-foreground">
```

Dark mode is `data-theme="dark"` on a parent — handled by Tailwind's selector strategy, no extra classes needed.

### Fluid typography (Utopia)

Use `text-h1` through `text-h6` and `text-body-*` for fluid text that scales between breakpoints — don't set font sizes manually.

### Container queries

Use `@container` with `@[size]:` prefix for component-level responsive behaviour:

```twig
<div class="@container">
  <div class="grid @md:grid-cols-2">
```

---

## Twig Template Patterns

Drupal paragraph templates live in `templates/paragraph/`. They should pass field data to SDC components.

### Include (no slots)

```twig
{# templates/paragraph/paragraph--slice-example.html.twig #}
{% include 'numiko:slice-example' with {
  attributes: attributes,
  title: content.field_title|field_display_value,
  summary: content.field_summary|field_display_value,
} only %}
```

### Embed (uses slots)

```twig
{% embed 'numiko:hero' with {
  title: content.field_hero_title|field_display_value,
} only %}
  {% block hero_media %}
    {{ content.field_hero_media }}
  {% endblock %}
{% endembed %}
```

### Paragraph template naming

For slice paragraphs, the template file should be named:
`paragraph--slice-[machine-name-without-slice].html.twig`

e.g. `slice_number_bullets` → `paragraph--slice-number-bullets.html.twig`

The `numiko.theme` hook auto-adds a `paragraph__slice` suggestion for all slice_ paragraphs.

### Accessing nested paragraph items

```twig
{% for item in content.field_items['#items'] %}
  {% include 'numiko:number-bullet-item' with {
    title: item.entity.field_title.value,
    content: item.entity.field_content.value,
  } only %}
{% endfor %}
```

---

## Common Mistakes

- **Selecting by class or ID in JS** — always use `data-js-*` attributes as selectors.
- **Forgetting to register in dynamic-imports/main-site.js** — JS won't load if not registered.
- **Using `attributes` without `.addClass()`** — replaces all attributes, breaks Drupal's accessibility injections.
- **Using raw hex or Tailwind default palette colors** — use semantic tokens from the color config.
- **Writing CSS that Tailwind can handle** — prefer utilities in the template over a CSS file.
- **Not including `attributes` prop in component.yml** — means Drupal can't pass HTML attributes.
- **Forgetting `only` on includes** — without it, the entire Drupal template scope bleeds into the component.
- **Naming CSS/JS files without `_` prefix** — Vite will treat them as entry points and bundle them separately.
