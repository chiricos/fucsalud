# Mode A: `drupal-layout-builder`

Use this reference when the component will be rendered via Drupal — through Layout Builder, a block plugin, node field mapping, or preprocess hooks.

**Golden sample**: `references/card/` — a complete production-ready Layout Builder component. Read it as the definitive structural template before writing any code.

---

## Sub-mode: block vs node

> **"¿El componente se va a asociar a un bloque o a un nodo/entidad?"**

- **Block**: include `{{ title_prefix }}` and `{{ title_suffix }}` in the Twig template
- **Node / entity**: do NOT include `title_prefix` / `title_suffix`

---

## `*.component.yml` rules

| Prop type | Definition | Notes |
|---|---|---|
| Image | `type: string` | Drupal renders the field as a string/render array — **never use a custom image type** |
| Video | `type: string` | Same as image — Drupal renders the embed field as a string |
| Text | `type: string` | No `contentMediaType`, no `x-formatting-context` |
| Enum | `type: string` + `enum` + `meta:enum` | `meta:enum` for human-readable labels in the UI |
| Boolean | `type: boolean` | — |
| Array (simple) | `type: array` + `items.type: string` + `maxItems` | — |
| Array (complex) | `type: array` + `items.type: object` + `items.properties` | Sub-props follow the same drupal-layout-builder rules |
| Attributes | `type: Drupal\Core\Template\Attribute` | Only when wrapper needs Drupal-managed attributes |
| Custom classes | `type: array` + `items.type: string` | `*_classes` and `*_utility_classes` for preprocess CSS control |

> **Imagen y vídeo son siempre `type: string`** — Drupal entrega el campo ya renderizado (HTML de `<img>` o `<iframe>`). Nunca uses un tipo personalizado ni `$ref` para estos campos en modo `drupal-layout-builder`. En el Twig se pinta simplemente con `{{ image }}` o `{{ video }}`, sin `|raw`.

### YAML examples

```yaml
# Enum with meta:enum
align:
  type: string
  title: Text alignment
  description: "Horizontal alignment of the text content."
  enum:
    - left
    - right
  meta:enum:
    '': Default
    left: Left
    right: Right
  default: left
  examples:
    - left

# Simple array
tags:
  type: array
  title: Tags
  description: "List of tag labels."
  items:
    type: string
  maxItems: 5
  examples:
    - ["Tag one", "Tag two"]

# Complex array
cards:
  type: array
  title: Cards
  description: "List of card items."
  items:
    type: object
    properties:
      image:
        type: string
        title: Image
        description: "Rendered image field output from Drupal."
        examples:
          - "<img src='/sites/default/files/card.jpg' alt='Card' />"
      title:
        type: string
        title: Title
        examples:
          - "Card title"
      url:
        type: string
        title: URL
        examples:
          - "/destinations/example"
  maxItems: 6
  examples:
    - - image: "<img src='/sites/default/files/card.jpg' alt='Card' />"
        title: "Card title"
        url: "/destinations/example"
```

---

## `*.twig` rules

- `{% set classes = [...] %}` + `{{ attributes.addClass(classes) }}` — never `addClass('c-...')` directly
- `{% set attributes = attributes ?: create_attribute() %}`
- Render image/text: `{{ image }}`, `{{ text }}` — no `|raw` needed, Drupal already renders the value safely
- Arrays: `{% for item in items %}` — always guard with `{% if items is not empty %}`
- Complex arrays: access sub-props with `item.prop_name`
- **Block only**: include `{{ title_prefix }}` and `{{ title_suffix }}` immediately after the opening tag

### Template example

```twig
{% set attributes = attributes ?: create_attribute() %}
{% set classes = [
  'c-card',
  align ? 'c-card--' ~ align : '',
] %}

<article {{ attributes.addClass(classes) }}>
  {{ title_prefix }}
  {{ title_suffix }}

  {% if image is not empty %}
    <div class="c-card__image">{{ image }}</div>
  {% endif %}

  {% if tags is not empty %}
    <ul class="c-card__tags">
      {% for tag in tags %}
        <li class="c-card__tag">{{ tag }}</li>
      {% endfor %}
    </ul>
  {% endif %}

  {% if cards is not empty %}
    <div class="c-cards__list">
      {% for card in cards %}
        <div class="c-cards__item">
          {% if card.image is not empty %}
            <div class="c-cards__image">{{ card.image }}</div>
          {% endif %}
          {% if card.title is not empty %}
            <h3 class="c-cards__title">{{ card.title }}</h3>
          {% endif %}
        </div>
      {% endfor %}
    </div>
  {% endif %}
</article>
```

---

## Key differences from Canvas mode

| Concern | Layout Builder | Canvas |
|---|---|---|
| Image props | `type: string` (Drupal renders) | `$ref: canvas.module/image` |
| Enum labels | `meta:enum` supported | `meta:enum` supported |
| HTML text | Not needed — Drupal handles | `contentMediaType: text/html` + `\|raw` |
| Image rendering | `{{ image }}` (already rendered) | `{% include 'canvas:image' %}` |
| Block title slots | `{{ title_prefix }}` / `{{ title_suffix }}` | ❌ Never |
| Custom CSS classes | `*_classes` / `*_utility_classes` arrays | ❌ Not used |
| `Attribute` type | Supported | ❌ Not supported |

→ Back to [SKILL.md](../SKILL.md)
