---
name: drupal-content-type
description: Use when creating a new content type in Drupal — covers shared fields, form display tabs, editorial workflow, view displays, views updates, sitemap config, and config export
---

# Drupal Content Type Creation

## Overview

Drupal has a consistent content type pattern: shared field storage, tabbed form display using field_group, and the editorial workflow. Always follow this pattern exactly.

**Docker command prefix:** `docker compose exec web`

---

## Step 1: Create the Content Type

```bash
docker compose exec web drush php:eval "
\$type = \Drupal\node\Entity\NodeType::create([
  'type' => 'machine_name',
  'name' => 'Human Label',
  'description' => 'Use to add a ...',
  'new_revision' => TRUE,
  'display_submitted' => FALSE,
  'preview_mode' => 0,
]);
\$type->save();
echo 'Content type created.' . PHP_EOL;
"
```

---

## Step 2: Attach Shared Fields

Always reuse existing field storage via `createDuplicate()`. Copy from the `page` bundle.

**Standard shared fields** (include all that apply):

| Field | Always include? | Purpose |
|---|---|---|
| `body` | Most types | Main body text |
| `field_hero_media` | Most types | Hero media |
| `field_hero_title` | Most types | Hero title override |
| `field_image` | Always | Teaser/featured image |
| `field_teaser_summary` | Always | Summary for listings |
| `field_slices` | Always | Paragraph content builder |
| `field_meta` | Most types | SEO meta |
| `field_publish_date` | News/events | Editorial date |
| `field_search_boost` | Searchable types | Search ranking |
| `field_category` | Most types | Taxonomy |
| `field_section` | Most types | Taxonomy |
| `field_related_content` | Most types | Related content |
| `field_show_related_content` | Most types | Toggle sidebar |

```bash
docker compose exec web drush php:eval "
node_add_body_field(\Drupal\node\Entity\NodeType::load('machine_name'));

\$fields = [
  'field_hero_media',
  'field_hero_title',
  'field_image',
  'field_teaser_summary',
  'field_slices',
  'field_meta',
  // add more as needed
];

foreach (\$fields as \$field_name) {
  \$existing = \Drupal\field\Entity\FieldConfig::loadByName('node', 'page', \$field_name);
  if (!\$existing) { echo 'WARNING: ' . \$field_name . ' not found on page' . PHP_EOL; continue; }
  if (\Drupal\field\Entity\FieldConfig::loadByName('node', 'machine_name', \$field_name)) {
    echo \$field_name . ' already exists, skipping.' . PHP_EOL; continue;
  }
  \$field = \$existing->createDuplicate();
  \$field->set('bundle', 'machine_name');
  \$field->set('id', 'node.machine_name.' . \$field_name);
  \$field->save();
  echo \$field_name . ' added.' . PHP_EOL;
}
"
```

---

## Step 3: Add to Editorial Workflow

```bash
docker compose exec web drush php:eval "
\$workflow = \Drupal\workflows\Entity\Workflow::load('editorial');
\$config = \$workflow->get('type_settings');
\$config['entity_types']['node'][] = 'machine_name';
\$workflow->set('type_settings', \$config);
\$workflow->save();
echo 'Added to editorial workflow.' . PHP_EOL;
"
```

---

## Step 4: Export Config (capture type + field configs)

**CRITICAL — do this before writing any YAML display files.**

Steps 1–3 created the content type and fields in the database only. You must export now to write `node.type.BUNDLE.yml`, `field.field.node.BUNDLE.*.yml`, and the updated `workflows.workflow.editorial.yml` into `config/sync`. If you skip this step and export later, it will overwrite your hand-written display files with Drupal's broken auto-generated defaults.

```bash
docker compose exec web drush config:export -y
```

Verify the diff shows only expected new/updated files:
- `node.type.BUNDLE.yml` (new)
- `field.field.node.BUNDLE.*.yml` (new)
- `workflows.workflow.editorial.yml` (updated)
- `core.entity_form_display.node.BUNDLE.default.yml` (new — broken auto-generated, will be replaced in Step 5)
- `core.entity_view_display.node.BUNDLE.*.yml` (new — broken auto-generated, will be replaced in Step 6)

---

## Step 5: Fix the Form Display

**IMPORTANT:** The auto-generated form display puts all custom fields in `hidden`. You MUST replace it with the correct YAML.

Overwrite `config/sync/core.entity_form_display.node.BUNDLE.default.yml`, preserving the `uuid` that was just exported. Model the content on `core.entity_form_display.node.page.default.yml`.

### Tab structure to follow

```
group_BUNDLE (tabs)
├── group_content (tab: "📄 Content", open)
│   ├── title
│   ├── group_intro (details: "🪧 Intro", open)
│   │   └── body
│   └── field_slices
├── group_hero (tab: "🖼️ Hero", closed)
│   ├── field_hero_title
│   └── field_hero_media
├── group_teaser (tab: "🗣️ Teaser", closed)
│   ├── field_image
│   └── field_teaser_summary
└── (optional) group_taxonomy (tab: "🔗 Taxonomy", closed)
    ├── field_section
    └── field_category
```

**Sidebar groups** (outside tabs, use `details_sidebar` format):
- `group_publishing` — `scheduler_settings`
- `group_search_boost` — `field_search_boost` (if applicable)

**field_slices widget settings** (copy exactly from page):
```yaml
field_slices:
  type: paragraphs
  settings:
    edit_mode: closed
    closed_mode: summary
    add_mode: modal
    default_paragraph_type: slice_content
    features:
      collapse_edit_all: collapse_edit_all
      duplicate: duplicate
  third_party_settings:
    paragraphs_features:
      add_in_between: true
      add_in_between_link_count: 5
    paragraphs_ee:
      paragraphs_ee:
        dialog_off_canvas: true
        dialog_style: tiles
```

**Fields that must be in `hidden`:** `langcode`, `promote`, `status`, `sticky`

---

## Step 6: Set Up View Displays

Overwrite all view display YAML files in `config/sync/`, preserving the `uuid` from each exported file. Model them on `core.entity_view_display.node.page.*.yml`.

### Required view modes

| Mode | File | What to show |
|---|---|---|
| `default` | `node.BUNDLE.default.yml` | `content: {}` — everything hidden. Theme handles display. |
| `teaser` | `node.BUNDLE.teaser.yml` | `field_image` (teaser_landscape) + `field_teaser_summary` |
| `full` | `node.BUNDLE.full.yml` | `body`, `field_hero_media` (hero), `field_hero_title`, `field_slices`, `content_moderation_control` |
| `listing_teaser` | `node.BUNDLE.listing_teaser.yml` | `field_image` (default, link: true) + `field_publish_date` if available |
| `search_index` | `node.BUNDLE.search_index.yml` | `body` + `field_slices` (for full-text search indexing) |
| `search_result` | `node.BUNDLE.search_result.yml` | `field_image` (teaser_landscape) + `reading_time` |

### Key formatter settings

**field_image in teaser/search_result:**
```yaml
field_image:
  type: entity_reference_entity_view
  label: hidden
  settings:
    view_mode: teaser_landscape
    link: false
```

**field_image in listing_teaser:**
```yaml
field_image:
  type: entity_reference_entity_view
  label: hidden
  settings:
    view_mode: default
    link: true
```

**field_hero_media in full:**
```yaml
field_hero_media:
  type: entity_reference_entity_view
  label: hidden
  settings:
    view_mode: hero
    link: false
```

**field_slices in full/search_index:**
```yaml
field_slices:
  type: entity_reference_revisions_entity_view
  label: hidden
  settings:
    view_mode: default
    link: ''
```

### Fields that must always be in `hidden` (all modes)
`langcode`, `links`, `node_read_time`, `reading_time` (except search_result), `search_api_excerpt`, `content_moderation_control`, `workbench_moderation_control` (except full), `field_meta`, `field_search_boost`

---

## Step 7: Update Views With Hardcoded Bundle Lists

Two views have explicit bundle lists that must be updated manually.

### views.view.content.yml — Admin content list (`/admin/content`)

Find the `plugin_id: bundle` filter and add the new type to the `value:` map:

```yaml
value:
  all: all
  article: article
  blog: blog
  # ... existing types ...
  your_new_type: your_new_type   # ← add this
```

### views.view.related_content_selectable.yml — Related content picker

Only update this if the new content type has `field_related_content` and should be selectable as related content. The filter is `exposed: false` so it's an internal restriction:

```yaml
value:
  article: article
  page: page
  your_new_type: your_new_type   # ← add if needed
```

**Note:** `views.view.moderated_content.yml` does NOT need updating — it uses `value: {}` which auto-includes all content types.

---

## Step 8: Add to XML Sitemap

Create `config/sync/simple_sitemap.bundle_settings.default.node.BUNDLE.yml`:

```yaml
index: true
priority: '0.5'
changefreq: ''
include_images: false
```

**Priority guide:**

| Priority | Use for |
|---|---|
| `1.0` + `changefreq: daily` | Homepage only |
| `0.8` | Listing/index pages |
| `0.7` | Landing pages |
| `0.6` | Events |
| `0.5` | Standard content (article, blog, page, course) |
| `0.4` | People profiles |

---

## Step 9: Import Config

Apply all the display files and sitemap config you just wrote:

```bash
docker compose exec web drush config:import -y
```

The import should show only the display/sitemap files as updated — NOT the node type or field configs (those were already exported in Step 4 and haven't changed).

---

## Common Mistakes

- **Don't use `drush field:create`** for shared fields — it creates duplicate storage. Always use `createDuplicate()`.
- **Don't skip Step 4 (export)** — if you write display YAMLs before exporting, a later `drush cex` will overwrite them with Drupal's broken auto-generated defaults.
- **Don't skip Step 5** — the auto-generated form display always hides fields.
- **Don't forget the workflow** — content without editorial workflow can't be published.
- **Preserve UUIDs when rewriting display files** — copy the `uuid` from the exported file before overwriting it.
