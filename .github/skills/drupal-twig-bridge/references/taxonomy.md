# Taxonomy Term Entity Template

## Filename & Location

**Folder**: `templates/taxonomy-custom/`
**Pattern**: `taxonomy-term--{vocabulary}--{view-mode}.html.twig`

**Examples**: `taxonomy-term--tags--card.html.twig`, `taxonomy-term--category--teaser.html.twig`

---

## Available Variables

| Variable | Description |
|---|---|
| `term` | The taxonomy term entity object |
| `name` | Term name |
| `url` | Canonical term URL |
| `content` | Rendered fields array |
| `attributes` | HTML attributes for the wrapper |
| `view_mode` | Current view mode string |

**No `utility_classes`** — taxonomy terms do not use vlsuite utility_classes.

---

## Classes Array

```twig
{%
  set classes = [
  'taxonomy-term',
  'taxonomy-term__' ~ term.bundle|clean_class,
  'vocabulary-' ~ term.bundle|clean_class,
  'taxonomy-term__' ~ term.bundle|clean_class ~ '--' ~ view_mode|clean_class,
]
%}
```

---

## Template — with `{% include %}` (no slots)

```twig
{#
/**
 * @file
 * Taxonomy: {vocabulary} — {view-mode}
 * Component: theme:{component-name}
 */
#}
{%
  set classes = [
  'taxonomy-term',
  'taxonomy-term__' ~ term.bundle|clean_class,
  'vocabulary-' ~ term.bundle|clean_class,
  'taxonomy-term__' ~ term.bundle|clean_class ~ '--' ~ view_mode|clean_class,
]
%}

{% include "theme:component" with {
  title: content.name|default(),
  url: url,
  image: content.field_image,
} only %}
```

## Template — with `{% embed %}` (slots needed)

```twig
{#
/**
 * @file
 * Taxonomy: {vocabulary} — {view-mode}
 * Component: theme:{component-name}
 */
#}
{%
  set classes = [
  'taxonomy-term',
  'taxonomy-term__' ~ term.bundle|clean_class,
  'vocabulary-' ~ term.bundle|clean_class,
  'taxonomy-term__' ~ term.bundle|clean_class ~ '--' ~ view_mode|clean_class,
]
%}

{% embed "theme:component" with {
  title: content.name|default(),
  url: url,
  image: content.field_image,
} %}
  {% block footer %}
    {# Slot content #}
  {% endblock %}
{% endembed %}
```

---

## Accessing Term Fields

| Data needed | Pattern |
|---|---|
| Raw text | `term.field_name.value` |
| Referenced entity | `term.field_name.entity` |
| Term name | `name` (variable) or `term.name.value` |
| Term URL | `url` (variable) |
