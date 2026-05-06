---
name: twig-best-practices
description: Twig templating security standards and composition patterns for Drupal 10.3+. Enforce secure class assignment, proper template organization, and DRY principles.
---

## Role & Capabilities

You are a specialist in Twig templating for Drupal 10.3+. Your expertise covers secure rendering, attribute manipulation, template composition, template debugging, and Drupal-specific Twig patterns.

## Core Principles

- **Security First**: Never concatenate user input into HTML attributes
- **Attribute Objects**: Always use Drupal's Attribute system for HTML attributes
- **Template Composition**: Use includes, extends, and embeds for reusability
- **Documentation Required**: Document all variables in template file headers
- **DRY Principle**: Avoid duplicating template logic across files

## Critical Rules

### 1. Class Assignment (XSS Prevention)

**ALWAYS use `attributes.addClass()` - NEVER concatenate classes.**

```twig
{# ✅ CORRECT #}
{% set classes = ['component', variant ? 'component--' ~ variant, is_active ? 'is-active'] %}
<div{{ attributes.addClass(classes) }}>{{ content }}</div>

{# ❌ FORBIDDEN - XSS vulnerability #}
<div class="component {{ custom_class }}">{{ content }}</div>
```

**Attribute manipulation:** `attributes.removeClass()`, `attributes.setAttribute()`, `create_attribute()`

### 2. Library Attachment

**Context-specific rules for library attachment:**

#### SDC Components
- **NOT NEEDED** - SDC components automatically load CSS/JS files when the component renders
- Asset filenames must match the component directory name
- No `.libraries.yml` entries or `attach_library()` calls required

#### Regular Twig Templates
- **FORBIDDEN** - Never use `{{ attach_library() }}` in regular templates
- Always use preprocess hooks in `{theme_file}` (from config) instead

```php
function {theme_name}_preprocess_node(&$variables) {
  if ($variables['node']->bundle() === 'event') {
    $variables['#attached']['library'][] = '{theme_name}/node__event__full';
  }
}
```

### 3. Template Composition

```twig
{# Include with context #}
{% include '@theme_name/includes/header.html.twig' with {'items': items} %}

{# Template inheritance #}
{% extends "node.html.twig" %}
{% block content %}{{ content }}{% endblock %}
```

### 4. Template Documentation

**ALWAYS document variables/props/slots at top in English.**

```twig
{#
/**
 * @file
 * Event card component.
 *
 * Props:
 * - title: (string) Card title
 * - image_url: (string) Image path
 * - is_featured: (boolean) Featured state
 * - attributes: (Attribute) HTML attributes
 *
 * Slots:
 * - badge: Optional badge content
 */
#}
```

## Conditional Rendering Patterns

### Basic Conditionals

```twig
{# Check if variable exists and is not empty #}
{% if image is not empty %}
  <div class="image-wrapper">{{ image }}</div>
{% endif %}

{# Check for specific value #}
{% if view_mode == 'full' %}
  {# Full view mode rendering #}
{% endif %}

{# Boolean check #}
{% if is_promoted %}
  <span class="badge">Featured</span>
{% endif %}

{# Null check #}
{% if content.field_subtitle is not null %}
  {{ content.field_subtitle }}
{% endif %}
```

### Conditional Regions

```twig
{# Only render region if it has content #}
{% if page.sidebar_first %}
  <aside class="sidebar-first">
    {{ page.sidebar_first }}
  </aside>
{% endif %}

{# Multiple region check #}
{% if page.pre_footer or page.footer %}
  <footer class="site-footer">
    {% if page.pre_footer %}
      <section class="pre-footer">{{ page.pre_footer }}</section>
    {% endif %}

    {% if page.footer %}
      <section class="footer">{{ page.footer }}</section>
    {% endif %}
  </footer>
{% endif %}
```

### Ternary Operator

```twig
{# Simple ternary #}
{% set heading_tag = heading_level ? 'h' ~ heading_level : 'h2' %}

{# Ternary in class array #}
{% set classes = [
  'component',
  variant ? 'component--' ~ variant : 'component--default',
  is_active ? 'is-active' : '',
] %}

{# Ternary for default values #}
{{ title|default('Untitled') }}
{{ position ?: 'center' }}
```

## Advanced Twig Patterns

### Variable Manipulation

```twig
{# Set simple variable #}
{% set title = 'My Page Title' %}

{# Set from content #}
{% set title = content.field_title.0['#context'].value %}

{# Build array #}
{% set classes = ['component', 'component--default'] %}

{# Merge arrays #}
{% set all_classes = base_classes|merge(custom_classes) %}

{# Array push #}
{% set classes = classes|merge(['new-class']) %}

{# String concatenation #}
{% set full_name = first_name ~ ' ' ~ last_name %}

{# Arithmetic #}
{% set total = price * quantity %}
```

### Loops and Iteration

```twig
{# Loop through array #}
{% for item in items %}
  <div class="item">{{ item }}</div>
{% endfor %}

{# Loop with key #}
{% for key, value in data %}
  <div data-key="{{ key }}">{{ value }}</div>
{% endfor %}

{# Loop with conditions #}
{% for item in items if item.published %}
  <div class="item">{{ item.title }}</div>
{% endfor %}

{# Loop variables #}
{% for item in items %}
  <div class="item item-{{ loop.index }}">
    {% if loop.first %}<strong>{% endif %}
    {{ item }}
    {% if loop.first %}</strong>{% endif %}
  </div>
{% endfor %}

{# Loop with else (no items) #}
{% for item in items %}
  <div>{{ item }}</div>
{% else %}
  <p>No items found.</p>
{% endfor %}
```

**Loop Variables**:
- `loop.index`: Current iteration (1-indexed)
- `loop.index0`: Current iteration (0-indexed)
- `loop.first`: True if first iteration
- `loop.last`: True if last iteration
- `loop.length`: Number of items
- `loop.parent`: Parent context in nested loops

### Macros for Reusable Logic

```twig
{# Define macro #}
{% macro render_icon(name, size) %}
  <span class="icon icon--{{ name }} icon--{{ size|default('md') }}"></span>
{% endmacro %}

{# Import and use macro #}
{% import _self as helpers %}
{{ helpers.render_icon('star', 'lg') }}

{# Macro in separate file #}
{# macros.html.twig #}
{% macro button(text, url, variant) %}
  <a href="{{ url }}" class="btn btn--{{ variant|default('primary') }}">
    {{ text }}
  </a>
{% endmacro %}

{# Use in template #}
{% import '@theme_name/includes/macros.html.twig' as ui %}
{{ ui.button('Click Me', '/path', 'secondary') }}
```

### Filters

**Common Drupal Filters**:

```twig
{# Render filter - convert render array to HTML #}
{{ content.body|render }}

{# Safe markup - mark string as safe HTML #}
{{ custom_html|raw }}

{# Clean class - sanitize for CSS class names #}
{{ variant|clean_class }}

{# Translate #}
{{ 'Hello World'|t }}
{{ 'Hello @name'|t({'@name': user.name}) }}

{# Format date #}
{{ node.created.value|date('Y-m-d') }}
{{ node.created.value|format_date('medium') }}

{# Default value #}
{{ title|default('Untitled') }}

{# Trim whitespace #}
{{ text|trim }}

{# Convert to lowercase/uppercase #}
{{ title|lower }}
{{ title|upper }}

{# Length #}
{% if items|length > 5 %}
  {# More than 5 items #}
{% endif %}

{# Join array #}
{{ classes|join(' ') }}

{# Slice array #}
{{ items|slice(0, 3) }}  {# First 3 items #}
```

### Without Filter for Selective Rendering

```twig
{# Render content except specific fields #}
{{ content|without('field_image', 'field_tags') }}

{# Render all remaining fields #}
<div class="node-content">
  {{ content.field_image }}
  {{ content.field_tags }}

  {# Render everything else #}
  {{ content|without('field_image', 'field_tags') }}
</div>
```

## Template Namespaces

### Namespace Syntax

```twig
{# Theme namespace - regular templates #}
{% include '@theme_name/includes/header.html.twig' %}
{% include '@theme_name/templates/layout/page.html.twig' %}

{# Module namespace #}
{% include '@my_module/templates/block.html.twig' %}

{# SDC namespace - components #}
{% include 'theme_name:button' with {...} only %}
{% include 'theme_name:card' with {...} only %}
{% embed 'theme_name:banner' with {...} %}{% endembed %}
```

**Namespace Resolution**:
- `@theme_name`: Resolves to theme directory (replace with actual theme name)
- `@module_name`: Resolves to module directory
- `theme_name:component_name`: Resolves to SDC component (no @ prefix, replace with actual theme name)

## Anti-Patterns

```twig
{# ❌ Direct class concatenation #}
<div class="component {{ custom }}">

{# ❌ Layout logic in content templates #}
<div class="container"><article>...</article></div>

{# ❌ attach_library() in templates #}

{# ❌ Undocumented variables #}
```

## Quick Reference

| Task               | Method                               | Status      |
| ------------------ | ------------------------------------ | ----------- |
| Add classes        | `attributes.addClass(classes)`       | ✅ Required |
| Direct concat      | `class="{{ var }}"`                  | ❌ XSS Risk |
| Attach library     | Preprocess hook                      | ✅ Required |
| Document variables | Comment block at top in English      | ✅ Required |
| Include partial    | `{% include '@theme_name/path' %}` | ✅ DRY      |
| Conditional region | `{% if page.region %}...{% endif %}` | ✅ Required |

**Paths**: Paths are read from `agent.config.json` - use `{paths.theme_file}`, `{paths.templates}/layout/page.html.twig`, etc.
