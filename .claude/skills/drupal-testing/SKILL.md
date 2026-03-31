---
name: drupal-testing
description: Use when writing or running tests in Drupal — covers test structure, base classes, helpers, and running tests via DrupalTestTraits against the real database
---

# Drupal Testing

## Overview

Tests run against the **real installed database** using DrupalTestTraits (`ExistingSiteBase`). No Drupal install happens per test — it connects to the live site.

**Where tests live:**

| What | Where |
|---|---|
| Content types | `docroot/modules/custom/site_tests/tests/src/Functional/Content/` |
| Slice paragraphs | `docroot/modules/custom/site_tests/tests/src/Functional/Slices/` |
| Custom modules (unit) | `docroot/modules/custom/[module]/tests/src/Unit/` |
| Custom modules (functional) | `docroot/modules/custom/[module]/tests/src/Functional/` |

**For custom modules, prefer unit tests.** Unit tests are fast, need no database, and are ideal for services, utilities, and pure PHP logic. Only use functional tests when you need the full Drupal stack (rendering, routing, form submission).

**Docker prefix:** `docker compose exec web`

---

## Test Types & When to Use Each

| Type | Directory | Use for |
|---|---|---|
| **Unit** | `[module]/tests/src/Unit/` | Pure PHP logic — services, utilities, data transforms (no DB, no Drupal stack) |
| **Content** | `site_tests/Functional/Content/` | Verifying a content type can be created, drafted, and published |
| **Persona** | `site_tests/Functional/Personas/` | Verifying a user role can/cannot access pages and perform actions |
| **Slice** | `site_tests/Functional/Slices/` | Verifying a paragraph slice renders its fields on a published node |

**When in doubt: write a unit test first.** If your code makes no Drupal API calls, it can be unit tested.

---

## Base Classes & Traits

### Class hierarchy

```
Your test
  ↓ extends
IntegrationTestBase  (numiko/integration_tests)
  ↓ extends
ExistingSiteBase  (weitzman/DrupalTestTraits)
```

### ContentTestTrait (`Drupal\site_tests\ContentTestTrait`)

Always use this when your test creates nodes — it creates dummy homepage and error page nodes in `setUp()` to prevent URL alias corruption.

```php
use Drupal\site_tests\ContentTestTrait;

abstract class AbstractMyTestCase extends IntegrationTestBase {
  use ContentTestTrait;
}
```

---

## Available Helpers

These are provided by `IntegrationTestBase` (via `numiko/integration_tests`):

### Creating entities

```php
// Create an unpublished node (draft state)
$node = $this->createNode([
  'type' => 'article',
  'title' => 'Test Article',
  'field_image' => $this->getSampleImageMedia(),
]);

// Create and immediately publish a node
$node = $this->createPublishedNode([
  'type' => 'page',
  'title' => 'Test Page',
]);

// Create a paragraph
$para = $this->createParagraph([
  'type' => 'slice_content',
  'field_title' => 'My heading',
  'field_content' => ['value' => '<p>Body text</p>', 'format' => 'full_html'],
]);

// Create media
$image = $this->getSampleImageMedia();
$doc = $this->getSampleDocumentMedia();
$video = $this->getSampleCoreVideoMedia();
```

### Creating users

```php
// Create user with one or more roles and log in
$this->createUserWithRoleAndLogin('edit_content');
$this->createUserWithPersonaAndLogin(['edit_content', 'publish_content']);

// Log out
$this->drupalLogout();
```

### Assertions

```php
// Visit a URL and assert the HTTP status code
$this->visitCheckCode('/node/add/article', 200);
$this->visitCheckCode('/admin/people', 403);

// Assert add/edit/delete access for a content/media type
$this->assertAddContentTypeReturnsStatusCode('article', 200);
$this->assertEditContentTypeReturnsStatusCode('article', $node->id(), 200);
$this->assertDeleteContentTypeReturnsStatusCode('article', $node->id(), 403);
$this->assertAddMediaTypeReturnsStatusCode('image', 200);

// Assert workflow transitions
$this->assertCanUseTransition($node, 'publish');
$this->assertCannotUseTransition($node, 'archive');
```

### Utilities

```php
// Clear all caches (called automatically in setUp)
$this->clearCache();

// Index content into search (for listing/facet tests)
$this->indexItemsInSearch();
```

---

## Patterns by Test Type

### Unit test (custom modules)

For services, utilities, or any pure PHP logic in a custom module. Extends `UnitTestCase` — no database, no Drupal bootstrap.

```php
namespace Drupal\Tests\my_module\Unit;

use Drupal\Tests\UnitTestCase;
use Drupal\my_module\Service\MyService;

class MyServiceTest extends UnitTestCase {

  public function testDoesWhatItShould(): void {
    $service = new MyService();
    $result = $service->process('input');
    $this->assertSame('expected output', $result);
  }

}
```

Place at: `docroot/modules/custom/[module]/tests/src/Unit/[ClassName]Test.php`

Run with:
```bash
docker compose exec web vendor/bin/phpunit --configuration . docroot/modules/custom/my_module/tests/src/Unit/
```

---

### Content test

Tests that a content type can be created, saved as draft (inaccessible to anonymous), then published.

```php
namespace Drupal\Tests\site_tests\Functional\Content;

use Drupal\integration_tests\IntegrationTestBase;
use Drupal\site_tests\ContentTestTrait;

class CourseContentTest extends IntegrationTestBase {
  use ContentTestTrait;

  public function testCourseContent(): void {
    $editor = $this->createUserWithRoleAndLogin('edit_content');

    $node = $this->createNode([
      'type' => 'course',
      'title' => 'Test Course',
      'field_image' => $this->getSampleImageMedia(),
      'field_teaser_summary' => 'Summary text',
    ]);

    // Draft — accessible to editor, forbidden to anonymous
    $this->visitCheckCode($node->toUrl()->toString(), 200);
    $this->drupalLogout();
    $this->visitCheckCode($node->toUrl()->toString(), 403);

    // Publish — accessible to anonymous
    $publisher = $this->createUserWithRoleAndLogin('publish_content');
    $this->assertCanUseTransition($node, 'publish');
    $this->visitCheckCode($node->toUrl()->toString(), 200);
    $this->assertSession()->pageTextContains('Test Course');
  }

}
```

### Slice test

Tests that all fields on a paragraph slice render on a published node.

```php
namespace Drupal\Tests\site_tests\Functional\Slices;

class NumberBulletsSliceTest extends AbstractSliceTestCase {

  public function testNumberBulletsSliceDisplay(): void {
    $item1 = $this->createParagraph([
      'type' => 'number_bullet_item',
      'field_title' => 'Step one',
      'field_content' => ['value' => '<p>First step content</p>', 'format' => 'full_html'],
    ]);

    $slice = $this->createParagraph([
      'type' => 'slice_number_bullets',
      'field_title' => 'How it works',
      'field_items' => [$item1],
    ]);

    $node = $this->createPublishedNode([
      'type' => 'page',
      'title' => 'Slice Test',
      'field_slices' => [$slice],
    ]);

    $this->visitCheckCode($node->toUrl()->toString(), 200);
    $this->assertSession()->pageTextContains('How it works');
    $this->assertSession()->pageTextContains('Step one');
    $this->assertSession()->pageTextContains('First step content');
  }

}
```

### Persona test

Tests that a user role can and cannot perform actions.

```php
namespace Drupal\Tests\site_tests\Functional\Personas;

class ContentEditorTest extends AbstractPersonaTestCase {

  public function testContentEditorCanCreateArticle(): void {
    $this->createUserWithRoleAndLogin('edit_content');
    $this->assertAddContentTypeReturnsStatusCode('article', 200);
  }

  public function testContentEditorCannotPublish(): void {
    $this->createUserWithRoleAndLogin('edit_content');
    $node = $this->createNode(['type' => 'article', 'title' => 'Test']);
    $this->assertCannotUseTransition($node, 'publish');
  }

}
```

---

## Running Tests

```bash
# Run all functional tests
docker compose exec web vendor/bin/phpunit --configuration . docroot/modules/custom

# Run a specific test class
docker compose exec web vendor/bin/phpunit --configuration . docroot/modules/custom/site_tests/tests/src/Functional/Slices/NumberBulletsSliceTest.php

# Run a specific test method
docker compose exec web vendor/bin/phpunit --configuration . --filter=testNumberBulletsSliceDisplay docroot/modules/custom/site_tests/tests/src/Functional/Slices/NumberBulletsSliceTest.php

# Run all tests in a directory
docker compose exec web vendor/bin/phpunit --configuration . docroot/modules/custom/site_tests/tests/src/Functional/Content/
```

Failures produce browser output in `docroot/sites/simpletest/browser_output/` and screenshots in `docroot/sites/simpletest/screenshots/`.

---

## Common Mistakes

- **Not using `ContentTestTrait`** when creating nodes — URL aliases will be wrong for any node that isn't the first one created.
- **Using `createNode()` for published content** — use `createPublishedNode()` when you need anonymous access.
- **Not marking entities for cleanup** — call `$this->markEntityForCleanup($entity)` for any entity you create outside the helper methods if it's not cleaned up automatically.
- **Not clearing cache** — `clearCache()` is called in `setUp()` automatically via `IntegrationTestBase`, but if a test adds config changes call it again before asserting.
- **Skipping tests instead of implementing them** — use `$this->markTestSkipped('...')` only as a temporary placeholder with a comment explaining what needs to be done.
