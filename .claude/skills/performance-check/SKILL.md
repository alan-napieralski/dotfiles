---
name: performance-check
description: Analyze Drupal site performance and caching configuration, identify missing cache metadata, N+1 queries, and bloated tables
disable-model-invocation: true
---

# Drupal Performance Check

Analyze site performance configuration and identify optimisation opportunities.

**Usage:** `/performance-check`

**Docker prefix:** `docker compose exec web`

**Custom modules path:** `docroot/modules/custom/`

## Steps

### 1. Check Caching Configuration

```bash
docker compose exec web drush config:get system.performance cache.page.max_age
docker compose exec web drush config:get system.performance css.preprocess
docker compose exec web drush config:get system.performance js.preprocess
```

Production should have `max_age` > 0, CSS/JS preprocess both `true`.

### 2. Check Cache Backends

```bash
docker compose exec web drush php:eval "print_r(\$settings['cache']['default'] ?? 'database');"
docker compose exec web drush cache:list
```

Production should use Redis (configured in this project via `docker-compose.yml`).

### 3. Check BigPipe

```bash
docker compose exec web drush pm:list --filter=big_pipe
```

### 4. Check Database Table Sizes

```bash
docker compose exec web drush sql:query "SELECT table_name, ROUND(((data_length + index_length) / 1024 / 1024), 2) AS 'MB' FROM information_schema.tables WHERE table_schema = DATABASE() ORDER BY (data_length + index_length) DESC LIMIT 10;"
```

Look for bloated cache or watchdog tables.

### 5. Check for Missing Cache Metadata in Custom Code

```bash
grep -r "#markup" docroot/modules/custom/ | grep -v "#cache"
grep -r "getQuery\|entityQuery" docroot/modules/custom/
```

Every render array must have `#cache` with `tags`, `contexts`, and `max-age`.

### 6. Check for N+1 Query Patterns

```bash
grep -rn "->load(" docroot/modules/custom/
```

Use `loadMultiple()` instead of `load()` inside loops.

### 7. Check Views

```bash
docker compose exec web drush views:list
docker compose exec web drush views:analyze
```

Look for views with no caching, no pagination, or inefficient filters.

### 8. Check Queue Backlog

```bash
docker compose exec web drush queue:list
```

## Report Format

### Critical
- Page cache disabled
- CSS/JS aggregation off
- No Redis in production

### Warnings
- Missing `#cache` on render arrays
- N+1 query patterns
- Views without caching
- Bloated cache/watchdog tables

### Quick Wins

```bash
docker compose exec web drush config:set system.performance cache.page.max_age 3600
docker compose exec web drush config:set system.performance css.preprocess true
docker compose exec web drush config:set system.performance js.preprocess true
docker compose exec web drush cr
```
