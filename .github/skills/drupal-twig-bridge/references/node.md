# Node Entity Template

## Filename & Location

**Folder**: `templates/content-custom/`
**Pattern**: `node--{content-type}--{view-mode}.html.twig`

**Examples**: `node--article--teaser.html.twig`, `node--landing-page--full.html.twig`

---

## Available Variables

| Variable | Description |
|---|---|
| `node` | The node entity object |
| `label` | Node title |
| `content` | Rendered fields array |
| `url` | Canonical node URL |
| `attributes` | HTML attributes for the wrapper |
| `title_prefix` / `title_suffix` | Contextual links regions |
| `view_mode` | Current view mode string |

**No `utility_classes`** — nodes do not use vlsuite utility_classes.

---

## Classes Array

```twig
{%
  set classes = [
  'node',
  'node__' ~ node.bundle|clean_class,
  node.isPromoted() ? 'node--promoted',
  node.isSticky() ? 'node--sticky',
  not node.isPublished() ? 'node--unpublished',
  view_mode ? 'node--view-mode-' ~ view_mode|clean_class,
  'node__' ~ node.bundle|clean_class ~ '--' ~ view_mode|clean_class,
  'clearfix',
]
%}
```

---

## Template — with `{% include %}` (no slots)

```twig
{#
/**
 * @file
 * Node: {content-type} — {view-mode}
 * Component: theme:{component-name}
 */
#}
{%
  set classes = [
  'node',
  'node__' ~ node.bundle|clean_class,
  node.isPromoted() ? 'node--promoted',
  node.isSticky() ? 'node--sticky',
  not node.isPublished() ? 'node--unpublished',
  view_mode ? 'node--view-mode-' ~ view_mode|clean_class,
  'node__' ~ node.bundle|clean_class ~ '--' ~ view_mode|clean_class,
  'clearfix',
]
%}

{% include "theme:component" with {
  title: content.field_title.0['#context'].value|default(''),
  image: content.field_image,
  url: url,
} only %}
```

## Template — with `{% embed %}` (slots needed)

```twig
{#
/**
 * @file
 * Node: {content-type} — {view-mode}
 * Component: theme:{component-name}
 */
#}
{%
  set classes = [
  'node',
  'node__' ~ node.bundle|clean_class,
  node.isPromoted() ? 'node--promoted',
  node.isSticky() ? 'node--sticky',
  not node.isPublished() ? 'node--unpublished',
  view_mode ? 'node--view-mode-' ~ view_mode|clean_class,
  'node__' ~ node.bundle|clean_class ~ '--' ~ view_mode|clean_class,
  'clearfix',
]
%}

{% embed "theme:component" with {
  title: content.field_title.0['#context'].value|default(''),
  image: content.field_image,
  url: url,
} %}
  {% block header %}
    {# Slot content #}
  {% endblock %}
  {% block footer %}
    {# Slot content #}
  {% endblock %}
{% endembed %}
```
