# Field Entity Template

## Filename & Location

**Folder**: `templates/field-custom/`
**Pattern**: `field--{entity-type}--{field-name}--{bundle}.html.twig`

**Examples**: `field--node--field-services--landing-page.html.twig`, `field--paragraph--field-items--accordion.html.twig`

---

## Available Variables

| Variable | Description |
|---|---|
| `items` | Array of rendered field items |
| `label` | Field label |
| `label_hidden` | Boolean — whether label is hidden |
| `label_display` | Label display mode (`above`, `inline`, `visually_hidden`, `hidden`) |
| `multiple` | Boolean — whether field allows multiple values |
| `attributes` | HTML attributes for the wrapper |
| `title_attributes` | HTML attributes for the label element |

**No `utility_classes`** — field templates do not use vlsuite utility_classes.

---

## When to use field templates

Field templates are ideal when an SDC component expects an **array of structured objects** built from multi-value field items (e.g., accordion panels, card grids, tab sets). For single-value fields, mapping via `content.field_name` in the entity template is usually simpler.

---

## Template — Simple (passes items directly)

Use when the SDC component accepts Drupal's rendered items as-is.

```twig
{#
/**
 * @file
 * Field: {field-name} — {bundle}
 * Component: theme:{component-name}
 */
#}
{% set title_classes = [
  label_display == 'visually_hidden' ? 'visually-hidden',
] %}

{% if not label_hidden %}
  <div{{ title_attributes.addClass(title_classes) }}>{{ label }}</div>
{% endif %}

{% include "theme:component" with {
  items: items,
} only %}
```

---

## Template — Complex (builds array from paragraph items)

Use when the SDC component expects an array of plain objects, not rendered Twig output. Build the array using `merge` inside a `{% for %}` loop.

```twig
{#
/**
 * @file
 * Field: {field-name} — {bundle}
 * Component: theme:{component-name}
 */
#}
{% set title_classes = [
  label_display == 'visually_hidden' ? 'visually-hidden',
] %}

{% set component_items = [] %}
{% for item in items %}
  {% set component_items = component_items|merge([{
    header: item.content['#paragraph'].field_title.value|default(''),
    body: item.content['#paragraph'].field_body.value|default(''),
    image: item.content['#paragraph'].field_image.entity.uri.value|default(''),
  }]) %}
{% endfor %}

{% if not label_hidden %}
  <div{{ title_attributes.addClass(title_classes) }}>{{ label }}</div>
{% endif %}

{% include "theme:component" with {
  items: component_items,
} only %}
```

---

## Accessing Data Inside `{% for item in items %}`

| Data needed | Pattern |
|---|---|
| Paragraph entity | `item.content['#paragraph']` |
| Paragraph raw text | `item.content['#paragraph'].field_name.value` |
| Paragraph referenced entity field | `item.content['#paragraph'].field_name.entity.field_name.value` |
| Rendered item | `item.content` |
