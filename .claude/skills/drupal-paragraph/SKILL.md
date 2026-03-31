---
name: drupal-paragraph
description: Use when creating a new paragraph type in Drupal — covers naming conventions, slice vs item types, standard fields, form display, registering with content types, and config export
---

# Drupal Paragraph Type Creation

## Overview

Sitekit has 34 paragraph types following a strict two-tier pattern. Always follow naming and structure conventions.

**Docker command prefix:** `docker compose exec web`

---

## Naming Convention

| Type | Prefix | Example | Purpose |
|---|---|---|---|
| **Slice** | `slice_` | `slice_accordion` | Top-level content block added via `field_slices` on nodes |
| **Item** | none | `accordion_item` | Sub-component used inside a slice |

Slices are available to editors. Items are only referenced from their parent slice.

---

## Step 1: Create the Paragraph Type

```bash
docker compose exec web drush php:eval "
\$type = \Drupal\paragraphs\Entity\ParagraphsType::create([
  'id' => 'slice_example',
  'label' => 'Example',
  'description' => 'Add an example slice',
]);
\$type->save();
echo 'Paragraph type created.' . PHP_EOL;
"
```

---

## Step 2: Add Fields

### Standard fields for slices

Most slices share these fields. Check `field.field.paragraph.slice_content.*` for reference.

| Field | Type | Notes |
|---|---|---|
| `field_title` | `string` | Optional section heading |
| `field_content` | `text_long` or `text_with_summary` | Main rich text |
| `field_summary` | `text_long` | Short intro text |
| `field_media` | `entity_reference` → media | Single media item |
| `field_link` | `link` | CTA link |
| `field_items` | `entity_reference_revisions` → paragraph | For nested item types |

**Reuse existing field storage** (preferred):
```bash
docker compose exec web drush php:eval "
\$existing = \Drupal\field\Entity\FieldConfig::loadByName('paragraph', 'slice_content', 'field_title');
\$field = \$existing->createDuplicate();
\$field->set('bundle', 'slice_example');
\$field->set('id', 'paragraph.slice_example.field_title');
\$field->save();
echo 'field_title added.' . PHP_EOL;
"
```

**After reusing a field, always check the label** — `createDuplicate()` inherits the label from the source bundle. Update it if needed:
```bash
docker compose exec web drush php:eval "
\$field = \Drupal\field\Entity\FieldConfig::loadByName('paragraph', 'slice_example', 'field_items');
\$field->set('label', 'Items');
\$field->save();
echo 'Label updated to: ' . \$field->getLabel() . PHP_EOL;
"
```

**New field with no existing storage:**
```bash
docker compose exec web drush field:create paragraph slice_example \
  --field-name=field_my_field \
  --field-label="My Field" \
  --field-type=string \
  --field-widget=string_textfield \
  --cardinality=1
```

---

## Step 3: Register Slice with Content Types

All slice types should be available on `field_slices` on every content type. Do **not** add item types here.

```bash
docker compose exec web drush php:eval "
\$node_types = ['article', 'blog', 'course', 'event', 'homepage', 'landing', 'listing', 'page', 'person', 'publication'];
foreach (\$node_types as \$bundle) {
  \$field = \Drupal\field\Entity\FieldConfig::loadByName('node', \$bundle, 'field_slices');
  if (!\$field) continue;
  \$settings = \$field->getSetting('handler_settings');
  \$settings['target_bundles']['slice_example'] = 'slice_example';
  \$settings['target_bundles_drag_drop']['slice_example'] = ['enabled' => TRUE, 'weight' => 10];
  \$field->setSetting('handler_settings', \$settings);
  \$field->save();
  echo \$bundle . ': slice_example added.' . PHP_EOL;
}
"
```

---

## Step 4: Export Config (capture type + field configs)

**CRITICAL — do this before writing any YAML display files.**

Steps 1–3 created everything in the database only. Export now to write all config into `config/sync`. This also creates Drupal's auto-generated form/view display files with their assigned UUIDs — you'll overwrite those in Steps 5–6.

```bash
docker compose exec web drush config:export -y
```

Expected new/updated files:
- `paragraphs.paragraphs_type.MACHINE_NAME.yml` (new)
- `field.storage.paragraph.FIELD_NAME.yml` (new, only if new storage)
- `field.field.paragraph.MACHINE_NAME.*.yml` (new)
- `core.entity_form_display.paragraph.MACHINE_NAME.default.yml` (new — broken auto-generated, overwrite next)
- `core.entity_view_display.paragraph.MACHINE_NAME.default.yml` (new — broken auto-generated, overwrite next)
- `field.field.node.*.field_slices.yml` (updated — one per content type)

**If the display files don't appear in the export**, Drupal hasn't initialized them yet. Create them first, then re-export:

```bash
docker compose exec web drush php:eval "
use Drupal\Core\Entity\Entity\EntityFormDisplay;
use Drupal\Core\Entity\Entity\EntityViewDisplay;
foreach (['slice_example', 'example_item'] as \$bundle) {
  EntityFormDisplay::create(['targetEntityType' => 'paragraph', 'bundle' => \$bundle, 'mode' => 'default', 'status' => TRUE])->save();
  EntityViewDisplay::create(['targetEntityType' => 'paragraph', 'bundle' => \$bundle, 'mode' => 'default', 'status' => TRUE])->save();
  echo \$bundle . ': displays initialized.' . PHP_EOL;
}
"
docker compose exec web drush config:export -y
```

---

## Step 5: Fix the Form Display

Paragraph form displays are **flat** — no `field_group` tabs. Just list fields in content order.

Overwrite `config/sync/core.entity_form_display.paragraph.MACHINE_NAME.default.yml`, **preserving the `uuid`** from the exported file:

```yaml
uuid: PRESERVE-FROM-EXPORT
langcode: en
status: true
dependencies:
  config:
    - field.field.paragraph.slice_example.field_title
    - field.field.paragraph.slice_example.field_content
    - paragraphs.paragraphs_type.slice_example
  module:
    - text
id: paragraph.slice_example.default
targetEntityType: paragraph
bundle: slice_example
mode: default
content:
  field_title:
    type: string_textfield
    weight: 0
    region: content
    settings:
      size: 60
      placeholder: ''
    third_party_settings: {}
  field_content:
    type: text_textarea
    weight: 1
    region: content
    settings:
      rows: 5
      placeholder: ''
    third_party_settings: {}
hidden:
  created: true
  status: true
  uid: true
```

---

## Step 6: Fix the View Display

Overwrite `config/sync/core.entity_view_display.paragraph.MACHINE_NAME.default.yml`, **preserving the `uuid`** from the exported file:

```yaml
uuid: PRESERVE-FROM-EXPORT
langcode: en
status: true
dependencies:
  config:
    - field.field.paragraph.slice_example.field_title
    - field.field.paragraph.slice_example.field_content
    - paragraphs.paragraphs_type.slice_example
  module:
    - text
id: paragraph.slice_example.default
targetEntityType: paragraph
bundle: slice_example
mode: default
content:
  field_title:
    type: string
    label: hidden
    settings:
      link_to_entity: false
    third_party_settings: {}
    weight: 0
    region: content
  field_content:
    type: text_default
    label: hidden
    settings: {}
    third_party_settings: {}
    weight: 1
    region: content
hidden:
  search_api_excerpt: true
```

**Standard formatter types:**

| Field type | Formatter |
|---|---|
| string | `string` (with `link_to_entity: false`) |
| text_long / text_with_summary | `text_default` |
| entity_reference → media | `entity_reference_entity_view` (choose view_mode: default/hero/gallery) |
| entity_reference → node | `entity_reference_entity_view` (view_mode: teaser) |
| entity_reference_revisions → paragraph | `entity_reference_revisions_entity_view` (view_mode: default) |
| link | `link` |

---

## Step 7: Import Config

Apply the corrected display files:

```bash
docker compose exec web drush config:import -y
```

The import should show only the form/view display files as updated.

---

## Nested Paragraph Pattern (Slice + Item)

When a slice needs repeating sub-components (e.g. accordion items):

1. Create item type first (e.g. `accordion_item`) with its own fields
2. Add `field_items` to the slice as `entity_reference_revisions` targeting the item type
3. Do **not** add item types to `field_slices` — they're internal only

Existing nested pairs for reference:
- `slice_accordion` → `accordion_item` (via `field_items`)
- `slice_timeline` → `timeline_item` (via `field_items`)
- `slice_process` → `process_item` (via `field_items`)
- `slice_statistics` → `statistic_item` (via `field_items`)
- `slice_download` → `download_item` (via `field_download_items`)

---

## Common Mistakes

- **Don't write display YAMLs before exporting** — a `drush cex` will overwrite them with Drupal's broken auto-generated defaults.
- **Preserve UUIDs when overwriting display files** — copy the `uuid` from the exported file before overwriting.
- **Don't add item types to `field_slices`** — only slice_ types go there.
- **Don't skip Step 7 (import)** — your corrected display files won't take effect until imported.
