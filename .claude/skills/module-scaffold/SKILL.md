---
name: module-scaffold
description: Generate a new Drupal custom module with best-practice structure using Drush generators
disable-model-invocation: true
---

# Drupal Module Scaffolding

Create a new Drupal custom module following best practices.

**Usage:** `/module-scaffold [module_name]`

**Docker prefix:** `docker compose exec web`

**Custom modules path:** `docroot/modules/custom/`

## Step 1: Research First

Before creating a custom module, ask:
1. Have you searched drupal.org for existing contrib modules?
2. Would you like me to search for contrib alternatives first?

Only proceed with custom code if no suitable contrib module exists.

## Step 2: Gather Requirements

- **Machine name** — lowercase, underscores only (e.g. `my_module`)
- **Human name** — e.g. "My Module"
- **Description** — one sentence
- **What it needs:** service, block, form, controller, permissions, event subscriber?

## Step 3: Generate Structure

Use Drush generators for scaffolding — don't create files manually:

```bash
# Generate module skeleton
docker compose exec web drush generate module --answers='{
  "name": "My Module",
  "machine_name": "my_module",
  "description": "Does something useful.",
  "package": "Custom"
}'

# Generate additional components as needed
docker compose exec web drush generate service --answers='{"module": "my_module", "class": "MyService"}'
docker compose exec web drush generate plugin:block --answers='{"module": "my_module", "plugin_id": "my_block", "admin_label": "My Block", "class": "MyBlock"}'
docker compose exec web drush generate form-config --answers='{"module": "my_module", "class": "SettingsForm"}'
docker compose exec web drush generate controller --answers='{"module": "my_module", "class": "MyController"}'
```

## Step 4: Key Standards to Enforce

- **Always use dependency injection** — no `\Drupal::service()` in classes
- **Use PHP 8 attributes** for plugins (not annotations): `#[Block(...)]`
- **Config schema required** for any custom config in `config/schema/`
- **Cache metadata required** on all render arrays (`#cache` with tags/contexts)
- **Use constructor property promotion** for injected services

## Step 5: Enable and Verify

```bash
docker compose exec web drush en my_module
docker compose exec web drush cr
docker compose exec web drush pm:list --filter=my_module
```

## Step 6: Export Config

If the module ships with default config:

```bash
docker compose exec web drush config:export -y
```

## Module Location

```
docroot/modules/custom/my_module/
├── my_module.info.yml
├── my_module.module
├── my_module.services.yml
├── config/
│   ├── install/
│   └── schema/
├── src/
│   ├── Hook/
│   ├── Service/
│   ├── Plugin/Block/
│   ├── Form/
│   └── Controller/
└── tests/src/
    ├── Unit/
    ├── Kernel/
    └── Functional/
```
