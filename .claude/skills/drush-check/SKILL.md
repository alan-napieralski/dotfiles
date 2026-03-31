---
name: drush-check
description: Run a series of Drush commands to check Drupal site health, config sync status, pending updates, and recent errors
disable-model-invocation: true
---

# Drush Health Check

Run a series of Drush commands to check site health and status.

**Usage:** `/drush-check`

**Docker prefix:** `docker compose exec web`

## Steps

1. Check Drush is available:
   ```bash
   docker compose exec web drush status
   ```

2. Check for security updates:
   ```bash
   docker compose exec web composer audit
   ```

3. Check configuration sync status:
   ```bash
   docker compose exec web drush config:status
   ```

4. Check for pending database updates:
   ```bash
   docker compose exec web drush updatedb:status
   ```

5. Check watchdog for recent errors (severity 3 = Error):
   ```bash
   docker compose exec web drush watchdog:show --severity=3 --count=10
   ```

## Report Findings

Summarise:
- Drupal version and status
- Any security updates needed
- Configuration sync status (any overrides or out-of-sync items)
- Pending database updates
- Recent errors in logs
