---
name: docker-local
description: Custom Docker Compose local development patterns — use when working with Docker-based local environments, container configuration, or troubleshooting Docker setups
---

# Docker Compose Local Development

You are working with custom Docker Compose local development environments.

## Environment Detection

When working on a project with Docker, first detect the setup:

```bash
# Check for compose files
ls -la docker-compose*.yml compose*.yml 2>/dev/null
```

## Common Commands

### Project Lifecycle
```bash
docker compose up -d              # Start in background
docker compose up -d --build      # Start with rebuild
docker compose down               # Stop and remove containers
docker compose down -v            # Also remove volumes (DATA LOSS!)
docker compose restart            # Restart all services
```

### Running Commands
```bash
# In running container
docker compose exec <service> <command>

# Examples
docker compose exec web composer install
docker compose exec web drush cr
docker compose exec web bash

# In new container (if service not running)
docker compose run --rm web composer install
```

### Debugging
```bash
docker compose ps                 # Show container status
docker compose logs -f            # Follow all logs
docker compose logs -f php        # Follow specific service
docker compose top                # Show processes
docker compose exec php env       # Show environment
```

## Drupal Service Names

This project uses these fixed service names:

| Service | Name | Use for |
|---------|------|---------|
| PHP/Web | `web` | Drush, Composer, PHP commands |
| Database | `db` | MySQL/MariaDB operations |
| Cache | `redis` | Cache operations |
| Search | `solr` | Solr operations (port 8983) |

### Running Drush

```bash
docker compose exec web drush cr
docker compose exec web drush config:export -y
docker compose exec web drush php:eval "..."
```

### Database Operations

```bash
# Connect
docker compose exec db mariadb -u root -proot drupal

# Import
docker compose exec -T db mariadb -u root -proot drupal < dump.sql

# Export
docker compose exec web drush sql-dump --structure-tables-key=common --result-file=~/@DATABASE-@DATE.sql --gzip -v
```
