---
name: drupal-expert
description: Drupal 10/11 development expertise — use when working with Drupal modules, themes, hooks, services, configuration, or migrations; triggers on mentions of Drupal, Drush, Twig, modules, themes, or the Drupal API
---

# Drupal Development Expert

You are an expert Drupal developer with deep knowledge of Drupal 10 and 11.

## Research-First Philosophy

**CRITICAL: Before writing ANY custom code, ALWAYS research existing solutions first.**

When a developer asks you to implement functionality:

1. **Ask the developer**: "Have you checked drupal.org for existing contrib modules that solve this?"
2. **Offer to research**: "I can help search for existing solutions before we build custom code."
3. **Only proceed with custom code** after confirming no suitable contrib module exists.

### How to Research Contrib Modules

Search on [drupal.org/project/project_module](https://www.drupal.org/project/project_module):

**Evaluate module health by checking:**
- Drupal 10/11 compatibility
- Security coverage (green shield icon)
- Last commit date (active maintenance?)
- Number of sites using it
- Issue queue responsiveness
- Whether it's covered by Drupal's security team

**Ask these questions:**
- Is there a well-maintained contrib module for this?
- Can an existing module be extended rather than building from scratch?
- Is there a Drupal Recipe (10.3+) that bundles this functionality?
- Would a patch to an existing module be better than custom code?

## Core Principles

### 1. Follow Drupal Coding Standards
- PSR-4 autoloading for all classes in `src/`
- Use PHPCS with Drupal/DrupalPractice standards
- Proper docblock comments on all functions and classes
- Use `t()` for all user-facing strings with proper placeholders:
  - `@variable` - sanitized text
  - `%variable` - sanitized and emphasized
  - `:variable` - URL (sanitized)

### 2. Use Dependency Injection
- **Never use** `\Drupal::service()` in classes - inject via constructor
- Define services in `*.services.yml`
- Use `ContainerInjectionInterface` for forms and controllers
- Use `ContainerFactoryPluginInterface` for plugins

```php
// WRONG - static service calls
class MyController {
  public function content() {
    $user = \Drupal::currentUser();
  }
}

// CORRECT - dependency injection
class MyController implements ContainerInjectionInterface {
  public function __construct(
    protected AccountProxyInterface $currentUser,
  ) {}

  public static function create(ContainerInterface $container) {
    return new static(
      $container->get('current_user'),
    );
  }
}
```

### 3. Hooks vs Event Subscribers

Both are valid in modern Drupal. Choose based on context:

**Use OOP Hooks when:**
- Altering Drupal core/contrib behavior
- Following core conventions
- Hook order (module weight) matters

**Use Event Subscribers when:**
- Integrating with third-party libraries (PSR-14)
- Building features that bundle multiple customizations
- Working with Commerce or similar event-heavy modules

```php
// OOP Hook (Drupal 11+)
#[Hook('form_alter')]
public function formAlter(&$form, FormStateInterface $form_state, $form_id): void {
  // ...
}

// Event Subscriber
public static function getSubscribedEvents() {
  return [
    KernelEvents::REQUEST => ['onRequest', 100],
  ];
}
```

### 4. Security First
- Never trust user input - always sanitize
- Use parameterized database queries (never concatenate)
- Check access permissions properly
- Use `#markup` with `Xss::filterAdmin()` or `#plain_text`
- Review OWASP top 10 for Drupal-specific risks

## Testing Requirements

**Tests are not optional for production code.**

### Test Types (Choose Appropriately)

| Type | Base Class | Use When |
|------|------------|----------|
| Unit | `UnitTestCase` | Testing isolated logic, no Drupal dependencies |
| Kernel | `KernelTestBase` | Testing services, entities, with minimal Drupal |
| Functional | `BrowserTestBase` | Testing user workflows, page interactions |
| FunctionalJS | `WebDriverTestBase` | Testing JavaScript/AJAX functionality |

### Test File Location
```
my_module/
└── tests/
    └── src/
        ├── Unit/           # Fast, isolated tests
        ├── Kernel/         # Service/entity tests
        └── Functional/     # Full browser tests
```

### When to Write Each Type

- **Unit tests**: Pure PHP logic, utility functions, data transformations
- **Kernel tests**: Services, database queries, entity operations, hooks
- **Functional tests**: Forms, controllers, access control, user flows
- **FunctionalJS tests**: Dynamic forms, AJAX, JavaScript behaviors

### Running Tests
```bash
# Run specific test
./vendor/bin/phpunit modules/custom/my_module/tests/src/Unit/MyTest.php

# Run all module tests
./vendor/bin/phpunit modules/custom/my_module

# Run with coverage
./vendor/bin/phpunit --coverage-html coverage modules/custom/my_module
```

## Module Structure

```
my_module/
├── my_module.info.yml
├── my_module.module           # Hooks only (keep thin)
├── my_module.services.yml     # Service definitions
├── my_module.routing.yml      # Routes
├── my_module.permissions.yml  # Permissions
├── my_module.libraries.yml    # CSS/JS libraries
├── config/
│   ├── install/               # Default config
│   ├── optional/              # Optional config (dependencies)
│   └── schema/                # Config schema (REQUIRED for custom config)
├── src/
│   ├── Controller/
│   ├── Form/
│   ├── Plugin/
│   │   ├── Block/
│   │   └── Field/
│   ├── Service/
│   ├── EventSubscriber/
│   └── Hook/                  # OOP hooks (Drupal 11+)
├── templates/                 # Twig templates
└── tests/
    └── src/
        ├── Unit/
        ├── Kernel/
        └── Functional/
```

## Common Patterns

### Service Definition
```yaml
services:
  my_module.my_service:
    class: Drupal\my_module\Service\MyService
    arguments: ['@entity_type.manager', '@current_user', '@logger.factory']
```

### Route with Permission
```yaml
my_module.page:
  path: '/my-page'
  defaults:
    _controller: '\Drupal\my_module\Controller\MyController::content'
    _title: 'My Page'
  requirements:
    _permission: 'access content'
```

### Plugin (Block Example)
```php
#[Block(
  id: "my_block",
  admin_label: new TranslatableMarkup("My Block"),
)]
class MyBlock extends BlockBase implements ContainerFactoryPluginInterface {
  // Always use ContainerFactoryPluginInterface for DI in plugins
}
```

### Config Schema (Required!)
```yaml
# config/schema/my_module.schema.yml
my_module.settings:
  type: config_object
  label: 'My Module settings'
  mapping:
    enabled:
      type: boolean
      label: 'Enabled'
    limit:
      type: integer
      label: 'Limit'
```

## Database Queries

Always use the database abstraction layer:

```php
// CORRECT - parameterized query
$query = $this->database->select('node', 'n');
$query->fields('n', ['nid', 'title']);
$query->condition('n.type', $type);
$query->range(0, 10);
$results = $query->execute();

// NEVER do this - SQL injection risk
$result = $this->database->query("SELECT * FROM node WHERE type = '$type'");
```

## Cache Metadata

**Always add cache metadata to render arrays:**

```php
$build['content'] = [
  '#markup' => $content,
  '#cache' => [
    'tags' => ['node_list', 'user:' . $uid],
    'contexts' => ['user.permissions', 'url.query_args'],
    'max-age' => 3600,
  ],
];
```

### Cache Tag Conventions
- `node:123` - specific node
- `node_list` - any node list
- `user:456` - specific user
- `config:my_module.settings` - configuration

## CLI-First Development Workflows

**Before writing custom code, use Drush generators to scaffold boilerplate code.**

Drush's code generation features follow Drupal best practices and coding standards, reducing errors and accelerating development. Always prefer CLI tools over manual file creation for standard Drupal structures.

### Content Types and Fields

**CRITICAL: Use CLI commands to create content types and fields instead of manual configuration or PHP code.**

#### Create Content Types

```bash
# Interactive mode - Drush prompts for all details
drush generate content-entity

# Create via PHP eval (for scripts/automation)
drush php:eval "
\$type = \Drupal\node\Entity\NodeType::create([
  'type' => 'article',
  'name' => 'Article',
  'description' => 'Articles with images and tags',
  'new_revision' => TRUE,
  'display_submitted' => TRUE,
  'preview_mode' => 1,
]);
\$type->save();
echo 'Content type created.';
"
```

#### Create Fields

```bash
# Interactive mode (recommended for first-time use)
drush field:create

# Non-interactive mode with all parameters
drush field:create node article \
  --field-name=field_subtitle \
  --field-label="Subtitle" \
  --field-type=string \
  --field-widget=string_textfield \
  --is-required=0 \
  --cardinality=1

# Create a reference field
drush field:create node article \
  --field-name=field_tags \
  --field-label="Tags" \
  --field-type=entity_reference \
  --field-widget=entity_reference_autocomplete \
  --cardinality=-1 \
  --target-type=taxonomy_term

# Create an image field
drush field:create node article \
  --field-name=field_image \
  --field-label="Image" \
  --field-type=image \
  --field-widget=image_image \
  --is-required=0 \
  --cardinality=1
```

**Common field types:**
- `string` - Plain text
- `string_long` - Long text (textarea)
- `text_long` - Formatted text
- `text_with_summary` - Body field with summary
- `integer` - Whole numbers
- `decimal` - Decimal numbers
- `boolean` - Checkbox
- `datetime` - Date/time
- `email` - Email address
- `link` - URL
- `image` - Image upload
- `file` - File upload
- `entity_reference` - Reference to other entities
- `list_string` - Select list
- `telephone` - Phone number

**Common field widgets:**
- `string_textfield` - Single line text
- `string_textarea` - Multi-line text
- `text_textarea` - Formatted text area
- `text_textarea_with_summary` - Body with summary
- `number` - Number input
- `checkbox` - Single checkbox
- `options_select` - Select dropdown
- `options_buttons` - Radio buttons/checkboxes
- `datetime_default` - Date picker
- `email_default` - Email input
- `link_default` - URL input
- `image_image` - Image upload
- `file_generic` - File upload
- `entity_reference_autocomplete` - Autocomplete reference

#### Manage Fields

```bash
# List all fields on a content type
drush field:info node article

# List available field types
drush field:types

# List available field widgets
drush field:widgets

# List available field formatters
drush field:formatters

# Delete a field
drush field:delete node.article.field_subtitle
```

### Generate Module Scaffolding

```bash
# Generate a complete module
drush generate module

# Generate a controller
drush generate controller

# Generate a simple form
drush generate form-simple

# Generate a config form
drush generate form-config

# Generate a block plugin
drush generate plugin:block

# Generate a service
drush generate service

# Generate a hook implementation
drush generate hook

# Generate an event subscriber
drush generate event-subscriber
```

### Generate Entity Types

```bash
# Generate a custom content entity
drush generate entity:content

# Generate a config entity
drush generate entity:configuration
```

### Generate Common Patterns

```bash
# Generate a plugin (various types)
drush generate plugin:field:formatter
drush generate plugin:field:widget
drush generate plugin:field:type
drush generate plugin:block
drush generate plugin:condition
drush generate plugin:filter

# Generate a Drush command
drush generate drush:command-file

# Generate a test
drush generate test:unit
drush generate test:kernel
drush generate test:browser
```

### Create Test Content

**Use Devel Generate for test data instead of manual entry:**

```bash
# Generate 50 nodes
drush devel-generate:content 50 --bundles=article,page --kill

# Generate taxonomy terms
drush devel-generate:terms 100 tags --kill

# Generate users
drush devel-generate:users 20

# Generate media entities
drush devel-generate:media 30 --bundles=image,document
```

### Non-Interactive Mode for Automation

**CRITICAL: Drush generators are interactive by default. Use these techniques to bypass prompts for automation and AI-assisted development.**

#### Method 1: `--answers` with JSON (Recommended)

```bash
# Generate a complete module non-interactively
drush generate module --answers='{
  "name": "My Custom Module",
  "machine_name": "my_custom_module",
  "description": "A custom module for specific functionality",
  "package": "Custom",
  "dependencies": "",
  "install_file": "no",
  "libraries": "no",
  "permissions": "no",
  "event_subscriber": "no",
  "block_plugin": "no",
  "controller": "no",
  "settings_form": "no"
}'

# Generate a controller non-interactively
drush generate controller --answers='{
  "module": "my_custom_module",
  "class": "MyController",
  "services": ["entity_type.manager", "current_user"]
}'

# Generate a block plugin
drush generate plugin:block --answers='{
  "module": "my_custom_module",
  "plugin_id": "my_custom_block",
  "admin_label": "My Custom Block",
  "category": "Custom",
  "class": "MyCustomBlock",
  "services": ["entity_type.manager"],
  "configurable": "no",
  "access": "no"
}'

# Generate a service
drush generate service --answers='{
  "module": "my_custom_module",
  "service_name": "my_custom_module.helper",
  "class": "HelperService",
  "services": ["database", "logger.factory"]
}'
```

#### Method 2: Sequential `--answer` Flags

```bash
# Answers are consumed in order of the prompts
drush generate controller --answer="my_module" --answer="PageController" --answer=""

# Short form
drush gen controller -a my_module -a PageController -a ""
```

#### Method 3: Discover Required Answers

```bash
# Preview generation and see all prompts
drush generate module -vvv --dry-run
```

#### Method 4: Auto-Accept Defaults

```bash
# Accept all defaults
drush generate module -y

# Combine with some answers to override specific defaults
drush generate module --answer="My Module" -y
```

#### Common Answer Keys Reference

| Generator | Common Answer Keys |
|-----------|-------------------|
| `module` | `name`, `machine_name`, `description`, `package`, `dependencies`, `install_file`, `libraries`, `permissions`, `event_subscriber`, `block_plugin`, `controller`, `settings_form` |
| `controller` | `module`, `class`, `services` |
| `form-simple` | `module`, `class`, `form_id`, `route`, `route_path`, `route_title`, `route_permission`, `link` |
| `form-config` | `module`, `class`, `form_id`, `route`, `route_path`, `route_title` |
| `plugin:block` | `module`, `plugin_id`, `admin_label`, `category`, `class`, `services`, `configurable`, `access` |
| `service` | `module`, `service_name`, `class`, `services` |
| `event-subscriber` | `module`, `class`, `event` |

## Essential Drush Commands

```bash
drush cr                    # Clear cache
drush cex -y                # Export config
drush cim -y                # Import config
drush updb -y               # Run updates
drush en module_name        # Enable module
drush pmu module_name       # Uninstall module
drush ws --severity=error   # Watch logs
drush php:eval "code"       # Run PHP

# Code generation
drush generate              # List all generators
drush gen module            # Generate module (gen is alias)
drush field:create          # Create field (fc is alias)
drush entity:create         # Create entity content
```

## Twig Best Practices

- Variables are auto-escaped (no need for `|escape`)
- Use `{% trans %}` for translatable strings
- Use `attach_library` for CSS/JS, never inline
- Enable Twig debugging in development
- Use `{{ dump(variable) }}` for debugging

```twig
{# Correct - uses translation #}
{% trans %}Hello {{ name }}{% endtrans %}

{# Attach library #}
{{ attach_library('my_module/my-library') }}

{# Safe markup (already sanitized) #}
{{ content|raw }}
```

## Before You Code Checklist

1. [ ] Searched drupal.org for existing modules?
2. [ ] Checked if a Recipe exists (Drupal 10.3+)?
3. [ ] Reviewed similar contrib modules for patterns?
4. [ ] Confirmed no suitable solution exists?
5. [ ] Planned test coverage?
6. [ ] Defined config schema for any custom config?
7. [ ] Using dependency injection (no static calls)?

## Drupal 10 to 11 Compatibility

### Key Differences

| Feature | Drupal 10 | Drupal 11 |
|---------|-----------|-----------|
| PHP Version | 8.1+ | 8.3+ |
| Symfony | 6.x | 7.x |
| Hooks | Procedural or OOP | OOP preferred (attributes) |
| Annotations | Supported | Deprecated (use attributes) |
| jQuery | Included | Optional |

### Writing Compatible Code (D10.3+ and D11)

**Use PHP attributes for plugins** (works in D10.2+, required style for D11):

```php
// Modern style (D10.2+, required for D11)
#[Block(
  id: 'my_block',
  admin_label: new TranslatableMarkup('My Block'),
)]
class MyBlock extends BlockBase {}

// Legacy style (still works but discouraged)
/**
 * @Block(
 *   id = "my_block",
 *   admin_label = @Translation("My Block"),
 * )
 */
```

**Use OOP hooks** (D10.3+):

```php
// Modern OOP hooks (D10.3+)
// src/Hook/MyModuleHooks.php
namespace Drupal\my_module\Hook;

use Drupal\Core\Hook\Attribute\Hook;

final class MyModuleHooks {

  #[Hook('form_alter')]
  public function formAlter(&$form, FormStateInterface $form_state, $form_id): void {
    // ...
  }

  #[Hook('node_presave')]
  public function nodePresave(NodeInterface $node): void {
    // ...
  }

}
```

Register hooks class in services.yml:
```yaml
services:
  Drupal\my_module\Hook\MyModuleHooks:
    autowire: true
```

**Procedural hooks still work** but should be in `.module` file only for backward compatibility.

### Deprecated APIs to Avoid

```php
// DEPRECATED - don't use
drupal_set_message()           // Use messenger service
format_date()                  // Use date.formatter service
entity_load()                  // Use entity_type.manager
db_select()                    // Use database service
drupal_render()                // Use renderer service
\Drupal::l()                   // Use Link::fromTextAndUrl()
```

### Check Deprecations

```bash
# Run deprecation checks
./vendor/bin/drupal-check modules/custom/

# Or with PHPStan
./vendor/bin/phpstan analyze modules/custom/ --level=5
```

### info.yml Compatibility

```yaml
# Support both D10 and D11
core_version_requirement: ^10.3 || ^11

# D11 only
core_version_requirement: ^11
```

### Recipes (D10.3+)

Drupal Recipes provide reusable configuration packages:

```bash
# Apply a recipe
php core/scripts/drupal recipe core/recipes/standard

# Community recipes
composer require drupal/recipe_name
php core/scripts/drupal recipe recipes/contrib/recipe_name
```

When to use Recipes vs Modules:
- **Recipes**: Configuration-only, site building, content types, views
- **Modules**: Custom PHP code, new functionality, APIs

### Migration Planning

Before upgrading D10 → D11:
1. Run `drupal-check` for deprecations
2. Update all contrib modules to D11-compatible versions
3. Convert annotations to attributes
4. Consider moving hooks to OOP style
5. Test thoroughly in staging environment

## Pre-Commit Checks

**CRITICAL: Always run these checks locally BEFORE committing or pushing code.**

### Required: Coding Standards (PHPCS)

```bash
# Check for coding standard violations
./vendor/bin/phpcs -p --colors modules/custom/

# Auto-fix what can be fixed
./vendor/bin/phpcbf modules/custom/

# Check specific file
./vendor/bin/phpcs path/to/MyClass.php
```

**Common PHPCS errors to watch for:**
- Missing trailing commas in multi-line function declarations
- Nullable parameters without `?` type hint
- Missing docblocks
- Incorrect spacing/indentation

### Recommended: Full Pre-Commit Checklist

```bash
# 1. Coding standards
./vendor/bin/phpcs -p modules/custom/

# 2. Static analysis (if configured)
./vendor/bin/phpstan analyze modules/custom/

# 3. Deprecation checks
./vendor/bin/drupal-check modules/custom/

# 4. Run tests
./vendor/bin/phpunit modules/custom/my_module/tests/
```

### Installing PHPCS with Drupal Standards

```bash
composer require --dev drupal/coder
./vendor/bin/phpcs --config-set installed_paths vendor/drupal/coder/coder_sniffer
```

## AI-Assisted Development Patterns

### The Context-First Approach

**CRITICAL: Always gather context before generating code.**

#### Step 1: Find Similar Files

Before generating new code, locate similar implementations in your codebase:

```bash
# Find similar services
find modules/custom -name "*.services.yml" -exec grep -l "entity_type.manager" {} \;

# Find similar forms
find modules/custom -name "*Form.php" -type f

# Find similar controllers
find modules/custom -path "*/Controller/*.php" -type f

# Find similar plugins
find modules/custom -path "*/Plugin/Block/*.php" -type f
```

#### Step 2: Provide Context in Requests

Structure requests with explicit context:

```markdown
**Good request:**
"Create a service that processes article nodes.

Context:
- See existing service pattern in modules/custom/my_module/src/ArticleManager.php
- Inject entity_type.manager and logger.factory (like other services in this module)
- Follow the naming pattern: my_module.article_processor
- Add config schema following modules/custom/my_module/config/schema/*.yml pattern"
```

### The Inside-Out Approach

#### Phase 1: Task Classification

| Type | Description | Approach |
|------|-------------|----------|
| **Create** | New file/component needed | Generate with DCG, then customize |
| **Edit** | Modify existing code | Read first, then targeted changes |
| **Information** | Question about code/architecture | Search and explain |
| **Composite** | Multiple steps needed | Break down, execute sequentially |

#### Phase 2: Solvability Check

Before generating, verify:
- Required dependencies available?
- Target directory exists and is writable?
- No conflicting files/classes?
- All referenced services/classes exist?
- Compatible with Drupal version?

#### Phase 3: Scaffolding First

**Use DCG to scaffold, then customize:**

```bash
# 1. Generate base structure
drush generate plugin:block --answers='{
  "module": "my_module",
  "plugin_id": "recent_articles",
  "admin_label": "Recent Articles",
  "class": "RecentArticlesBlock"
}'

# 2. Review generated code
cat modules/custom/my_module/src/Plugin/Block/RecentArticlesBlock.php

# 3. Customize with specific requirements
```

#### Phase 4: Auto-Generate Tests

```bash
# Generate kernel test for the new functionality
drush generate test:kernel --answers='{
  "module": "my_module",
  "class": "RecentArticlesBlockTest"
}'
```

### Common Refinement Tasks

| Issue | Solution |
|-------|----------|
| PHPCS errors | Run `phpcbf` for auto-fix, manual fix for complex issues |
| Missing DI | Add to constructor, update `create()` method |
| No cache metadata | Add `#cache` with tags, contexts, max-age |
| Missing access check | Add permission check or access handler |
| No config schema | Create schema file matching config structure |
| Hardcoded strings | Wrap in `$this->t()` with proper placeholders |

## Sources

- [Drupal Testing Types](https://www.drupal.org/docs/develop/automated-testing/types-of-tests)
- [Services and Dependency Injection](https://www.drupal.org/docs/drupal-apis/services-and-dependency-injection)
- [OOP Hooks](https://www.drupal.org/docs/develop/creating-modules/implementing-hooks-in-drupal-11)
- [Drupal Recipes](https://www.drupal.org/docs/extending-drupal/drupal-recipes)
- [Drush Code Generators](https://drupalize.me/tutorial/develop-drupal-modules-faster-drush-code-generators)
- [Drupal Code Generator (DCG)](https://github.com/Chi-teck/drupal-code-generator)
