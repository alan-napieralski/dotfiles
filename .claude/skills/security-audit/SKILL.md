---
name: security-audit
description: Audit a Drupal site for security vulnerabilities — updates, file permissions, debug mode, custom code XSS/injection risks, and role permissions
disable-model-invocation: true
---

# Drupal Security Audit

Perform a security audit of the Drupal site.

**Usage:** `/security-audit [path]`

If a path is provided, focus on that module/directory. Otherwise audit site-wide.

**Docker prefix:** `docker compose exec web`

**Webroot:** `docroot/`

**Custom modules:** `docroot/modules/custom/`

## Steps

### 1. Security Updates

```bash
docker compose exec web composer audit
```

Any advisories require immediate action.

### 2. Outdated Packages

```bash
docker compose exec web composer outdated drupal/*
```

### 3. File Permissions

```bash
# settings.php should not be world-writable
ls -la docroot/sites/default/settings.php

# No PHP files in files directory
find docroot/sites/default/files -name "*.php" -type f
```

### 4. Debug Mode (must be off in production)

```bash
docker compose exec web drush php:eval "var_dump(\$config['system.logging']['error_level'] ?? 'hide');"
docker compose exec web drush php:eval "var_dump(\$settings['twig_debug'] ?? false);"
```

Both should be `hide` / `false` in production.

### 5. Trusted Host Patterns

```bash
docker compose exec web drush php:eval "print_r(\$settings['trusted_host_patterns'] ?? 'NOT SET');"
```

Must be set in production to prevent host header injection.

### 6. Custom Code Scan

```bash
# Potential XSS — raw markup with variables
grep -rn "#markup.*\$" docroot/modules/custom/

# Hardcoded credentials
grep -rni "password\s*=\|api_key\s*=\|secret" docroot/modules/custom/

# Static service calls (code smell)
grep -rn "\\\\Drupal::" docroot/modules/custom/src/
```

### 7. User Permissions

```bash
docker compose exec web drush role:list
```

Check for overly permissive anonymous/authenticated roles.

### 8. Recent Error Logs

```bash
docker compose exec web drush watchdog:show --severity=error --count=20
```

### 9. Composer Audit

```bash
docker compose exec web composer audit
```

## Report Format

### CRITICAL (fix immediately)
- Security updates available
- XSS or SQL injection in custom code
- Debug mode on in production
- Missing trusted_host_patterns
- PHP files in files directory

### HIGH (fix soon)
- Hardcoded credentials
- Overly permissive file permissions
- Outdated packages without security advisories

### MEDIUM
- Static `\Drupal::` calls in custom code
- Unused roles with broad permissions

## Automated Scanning

```bash
# Security Review module (if installed)
docker compose exec web drush en security_review
docker compose exec web drush security:review

# Coding standards
docker compose exec web ./vendor/bin/phpcs --standard=Drupal,DrupalPractice docroot/modules/custom/
```
