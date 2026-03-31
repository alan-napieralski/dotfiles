---
name: drupal-config
description: Use when managing Drupal configuration — exporting, importing, checking status, or understanding config split across dev/stage/prod environments
---

# Drupal Config Management

## Overview

Drupal uses config split to manage environment-specific overrides and config_ignore to protect settings that shouldn't be overwritten on import.

**Docker command prefix:** `docker compose exec web`

---

## Daily Workflow

```
Make changes in Drupal UI or via drush
        ↓
docker compose exec web drush config:status   ← check what changed
        ↓
docker compose exec web drush config:export -y
        ↓
Review the git diff (config/sync/)
        ↓
Commit to git
```

---

## Key Commands

```bash
# Check what's out of sync
docker compose exec web drush config:status

# Export active config to sync directory
docker compose exec web drush config:export -y

# Import sync directory to database
docker compose exec web drush config:import -y

# Preview import changes without applying
docker compose exec web drush config:import --preview

# Clear cache after import
docker compose exec web drush cr
```

---

## Config Split — Three Environments

| Split | Path | Purpose |
|---|---|---|
| `dev` | `config/dev/` | Dev-only modules (devel, masquerade, stage_file_proxy) |
| `stage` | `config/stage/` | Staging-specific overrides |
| `prod` | `config/prod/` | Production overrides (aggregation, caching, etc.) |

The active split is controlled by environment settings in `.env` / `settings.php`. On local, `dev` split is active.

**When exporting locally**, dev split config is saved to `config/dev/` not `config/sync/`. This is correct — don't move it manually.

---

## Config Ignore

Certain configs are excluded from import so they can differ per environment without being overwritten. Check current ignore list:

```bash
cat /path/to/config/sync/config_ignore.settings.yml
```

Common ignored configs include:
- `system.site` (site name, email per environment)
- `system.performance` (caching settings)
- API keys and third-party integration settings

**Never export sensitive credentials into config/sync.** Put them in `settings.php` or `.env`.

---

## Handling Conflicts

If `drush config:status` shows unexpected diffs after a pull:

```bash
# See exactly what's different
docker compose exec web drush config:status

# Import what's in sync (overwrites database — safe if you've exported first)
docker compose exec web drush config:import -y

# If something is stuck, force a full cache clear first
docker compose exec web drush cr && docker compose exec web drush config:import -y
```

**Never force-import without checking the diff first** — you could overwrite content type or field changes.

---

## After Creating Content Types / Fields / Paragraphs

Always export immediately after any structural change:

```bash
docker compose exec web drush config:export -y
git diff config/sync/   # review before committing
```

Expected files for a new content type:
- `node.type.BUNDLE.yml`
- `field.field.node.BUNDLE.*.yml`
- `core.entity_form_display.node.BUNDLE.default.yml`
- `core.entity_view_display.node.BUNDLE.*.yml`
- `workflows.workflow.editorial.yml`

---

## Troubleshooting

**"Configuration was modified in the database"** — run `drush cex -y` and commit.

**"Config already exists"** on import — usually means UUID mismatch. Check `drush config:status` and resolve by deleting the conflicting config from the database or the sync file.

**Paragraph field_slices changes not showing** — after adding a new paragraph type to field_slices, check all content type field configs were exported: `field.field.node.*.field_slices.yml`
