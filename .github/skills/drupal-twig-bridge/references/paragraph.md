# Paragraph Entity Template

## Filename & Location

**Folder**: `templates/paragraph-custom/`
**Pattern**: `paragraph--{type}--{view-mode}.html.twig`

**Examples**: `paragraph--text-with-image--default.html.twig`, `paragraph--cta-banner--full.html.twig`

---

## Available Variables

| Variable | Description |
|---|---|
| `paragraph` | The paragraph entity object |
| `content` | Rendered fields array |
| `attributes` | HTML attributes for the wrapper |
| `view_mode` | Current view mode string |

**No `utility_classes`** — paragraphs do not use vlsuite utility_classes.

---

## Classes Array

```twig
{%
  set classes = [
  'paragraph',
  'paragraph--type--' ~ paragraph.bundle|clean_class,
  view_mode ? 'paragraph--view-mode--' ~ view_mode|clean_class,
  not paragraph.isPublished() ? 'paragraph--unpublished',
]
%}
```

---

## Template — with `{% include %}` (no slots)

```twig
{#
/**
 * @file
 * Paragraph: {type} — {view-mode}
 * Component: theme:{component-name}
 */
#}
{%
  set classes = [
  'paragraph',
  'paragraph--type--' ~ paragraph.bundle|clean_class,
  view_mode ? 'paragraph--view-mode--' ~ view_mode|clean_class,
  not paragraph.isPublished() ? 'paragraph--unpublished',
]
%}

{% block paragraph %}
  {% include "theme:component" with {
    title: content.field_title.0|default(),
    image: content.field_image,
  } only %}
{% endblock paragraph %}
```

## Template — with `{% embed %}` (slots needed)

```twig
{#
/**
 * @file
 * Paragraph: {type} — {view-mode}
 * Component: theme:{component-name}
 */
#}
{%
  set classes = [
  'paragraph',
  'paragraph--type--' ~ paragraph.bundle|clean_class,
  view_mode ? 'paragraph--view-mode--' ~ view_mode|clean_class,
  not paragraph.isPublished() ? 'paragraph--unpublished',
]
%}

{% block paragraph %}
  {% embed "theme:component" with {
    title: content.field_title.0|default(),
    title_link: content.field_link.0['#url'].toString()|default(),
    image: content.field_image,
  } %}
    {% block footer %}
      <div class="c-card__footer">
        {% include 'theme:button' with {
          url: content.field_link.0['#url'].toString()|default(),
          url_target: content.field_link.0['#url'].options['attributes'].target|default(),
          content: content.field_link.0['#title']|default(),
          tag: 'a',
          view_mode: 'simple',
        } only %}
      </div>
    {% endblock %}
  {% endembed %}
{% endblock paragraph %}
```

---

## Accessing Paragraph Fields

For fields accessed directly on the entity (not through `content`):

| Data needed | Pattern |
|---|---|
| Raw text | `paragraph.field_name.value` |
| Referenced entity field | `paragraph.field_name.entity.field_name.value` |
| Reference target ID | `paragraph.field_name.target_id` |
