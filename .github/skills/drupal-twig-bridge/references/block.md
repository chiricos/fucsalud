# Block Entity Template

## Filename & Location

**Folder**: `templates/block-custom/`
**Pattern**: `block--block-content--view-type--{bundle}--{view-mode}.html.twig`

**Examples**: `block--block-content--view-type--hero-banner--default.html.twig`

---

## Available Variables

| Variable | Description |
|---|---|
| `configuration` | Block configuration array (includes `provider`) |
| `plugin_id` | Plugin ID string |
| `bundle` | Block content bundle |
| `view_mode` | Current view mode string |
| `label` | Block label |
| `content` | Rendered fields array |
| `attributes` | HTML attributes for the wrapper |
| `title_prefix` / `title_suffix` | Contextual links regions |
| `utility_classes` | vlsuite utility_classes map (block-only feature) |

**Uses `utility_classes`** — always ask which keys this block uses and which SDC prop each maps to.

> `view-type` is a literal fixed string in the filename — it does not change.

---

## vlsuite `utility_classes` Mapping

`utility_classes` keys are **always mapped to a component prop** — never to the classes array. Each key can map to any prop type (enum, string, boolean). Always use `|default()` fallback.

```twig
{# Document the mapping in the file header #}
{# utility_classes: position → position, heading-level → heading_level #}

{% set position = utility_classes['position']|default('right') %}
{% set heading_level = utility_classes['heading-level']|default('2') %}
{% set color_variant = utility_classes['color']|default('light') %}
```

---

## Classes Array

```twig
{% set classes = [
  'block',
  'block-' ~ configuration.provider|clean_class,
  'block-' ~ plugin_id|clean_class,
  bundle ? 'block__' ~ bundle|clean_class,
  view_mode ? 'block__' ~ bundle|clean_class ~ '__' ~ view_mode|clean_class,
] %}
```

---

## Template — with `{% include %}` (no slots)

```twig
{#
/**
 * @file
 * Block: {bundle} — {view-mode}
 * Component: theme:{component-name}
 * utility_classes: {key} → {prop}, {key} → {prop}
 */
#}
{% set classes = [
  'block',
  'block-' ~ configuration.provider|clean_class,
  'block-' ~ plugin_id|clean_class,
  bundle ? 'block__' ~ bundle|clean_class,
  view_mode ? 'block__' ~ bundle|clean_class ~ '__' ~ view_mode|clean_class,
] %}

{% set position = utility_classes['position']|default('right') %}

{# Pasar classes y attributes solo si el componente SDC declara estas props #}
{% include "theme:component" with {
  image: content.field_image|default(),
  position: position,
  label: label,
} only %}
```

## Template — with `{% embed %}` (slots needed)

```twig
{#
/**
 * @file
 * Block: {bundle} — {view-mode}
 * Component: theme:{component-name}
 * utility_classes: {key} → {prop}, {key} → {prop}
 */
#}
{% set classes = [
  'block',
  'block-' ~ configuration.provider|clean_class,
  'block-' ~ plugin_id|clean_class,
  bundle ? 'block__' ~ bundle|clean_class,
  view_mode ? 'block__' ~ bundle|clean_class ~ '__' ~ view_mode|clean_class,
] %}

{% set position = utility_classes['position']|default('right') %}
{% set heading_level = utility_classes['heading-level']|default('2') %}

{# Pasar classes y attributes solo si el componente SDC declara estas props #}
{% embed "theme:component" with {
  image: content.field_image|default(),
  position: position,
  heading_level: heading_level,
  label: label,
} %}
  {% block info %}
    {# Slot content #}
  {% endblock %}
{% endembed %}
```
