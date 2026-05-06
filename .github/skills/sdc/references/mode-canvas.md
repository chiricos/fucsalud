# Mode B: `canvas`

Use this reference when the component will be rendered via Drupal Canvas. Props are pure JSON Schema — Canvas generates the editor UI automatically.

**Reference component**: `references/card-canvas/` — a complete production-ready Canvas component. Read it before writing any code.

---

## Table of Contents

- [component.yml rules](#componentyml-rules)
- [`|raw` usage rules (CRITICAL — read this first)](#raw-usage-rules-critical)
- [Prop examples](#prop-examples)
- [canvas:image include](#canvasimage-include)
- [Twig rules and template](#twig-rules)
- [Key differences from Layout Builder mode](#key-differences-from-layout-builder-mode)

---

## `*.component.yml` rules

| Prop type | Definition | Twig | Notes |
|---|---|---|---|
| Image | `$ref: json-schema-definitions://canvas.module/image` | `canvas:image` include | Provides `src`, `alt`, `width`, `height` |
| Video | `$ref: json-schema-definitions://canvas.module/video` | `video.src`, `video.poster` | — |
| Plain text | `type: string` | `{{ prop }}` | Use whenever HTML markup is not required |
| HTML text | `type: string` + `contentMediaType: text/html` + `x-formatting-context: block` | `{{ prop\|raw }}` | **Only when HTML markup is strictly required** — see `\|raw` rules |
| Enum | `type: string` + `enum` + `meta:enum` | `{{ prop }}` | `meta:enum` for human-readable labels in the UI |
| Boolean | `type: boolean` | `{% if prop %}` | — |
| Integer | `type: integer` | `{{ prop }}` | — |
| URI | `type: string` + `format: uri` | `{{ prop }}` | Absolute URL only |
| URI-reference | `type: string` + `format: uri-reference` | `{{ prop }}` | Absolute or relative URL |
| Array (simple) | `type: array` + `items.type: string` + `maxItems` | `{% for item in prop %}` | — |
| Array (complex) | `type: array` + `items.type: object` + `items.properties` | `item.prop_name` | Sub-props follow canvas rules, including `$ref` for images |

> ❌ Never include `Drupal\Core\Template\Attribute` props or `*_classes`/`*_utility_classes` arrays.

---

## `|raw` usage rules (CRITICAL)

This is the highest-risk area in Canvas mode. Getting this wrong introduces XSS vulnerabilities.

- ✅ **Use `|raw`** only when the prop has `contentMediaType: text/html` — Canvas passes real HTML that must be rendered unescaped
- ❌ **Never use `|raw`** on `type: string` props without `contentMediaType` — Twig auto-escaping protects against XSS
- ❌ **Do not add `contentMediaType: text/html` by default** — only when the editor genuinely needs to input HTML markup (e.g., body text with `<strong>`, `<em>`, `<a>`, lists)
- When in doubt, use plain `type: string` — safer and sufficient for most cases

```yaml
# ✅ Plain text — no |raw needed
title:
  type: string
  title: Title
  description: "Card title. Plain text only."
  examples:
    - "Card title"

# ✅ HTML text — |raw required, justified because editor needs markup
body:
  type: string
  title: Body
  description: "Body content. HTML markup allowed (bold, italic, links, lists)."
  contentMediaType: text/html
  x-formatting-context: block
  examples:
    - "Simple body text."
    - "Text with <strong>bold</strong> and <a href='/example'>a link</a>."

# ❌ Wrong — contentMediaType on a prop that only needs plain text
subtitle:
  type: string
  contentMediaType: text/html   # unnecessary, remove it
  examples:
    - "A simple subtitle"
```

```twig
{# ✅ Plain text — auto-escaped by Twig #}
{% if title is not empty %}
  <h3 class="c-card__title">{{ title }}</h3>
{% endif %}

{# ✅ HTML text — |raw only because contentMediaType: text/html is defined #}
{% if body is not empty %}
  <div class="c-card__body">{{ body|raw }}</div>
{% endif %}

{# ❌ Wrong — |raw on a plain string prop #}
{% if subtitle is not empty %}
  <p>{{ subtitle|raw }}</p>
{% endif %}
```

---

## Prop examples

```yaml
# Image
image:
  $ref: json-schema-definitions://canvas.module/image
  type: object
  title: Image
  description: "Card image."
  examples:
    - src: "https://placehold.co/400x300"
      alt: "Card image"
      width: 400
      height: 300

# URI-reference
link_url:
  type: string
  title: Link URL
  description: "Absolute or relative URL."
  format: uri-reference
  examples:
    - "/destinations/example"
    - "https://www.example.com"

# Enum (no meta:enum)
link_target:
  type: string
  title: Link target
  enum:
    - _self
    - _blank
  default: _self
  examples:
    - _self

# Simple array
tags:
  type: array
  title: Tags
  description: "List of tag labels."
  items:
    type: string
  maxItems: 5
  examples:
    - ["Nature", "Travel"]

# Complex array
cards:
  type: array
  title: Cards
  description: "List of card items."
  items:
    type: object
    properties:
      image:
        $ref: json-schema-definitions://canvas.module/image
        title: Image
        examples:
          - src: "https://placehold.co/400x300"
            alt: "Card image"
            width: 400
            height: 300
      title:
        type: string
        title: Title
        examples:
          - "Card title"
      text:
        type: string
        title: Text
        description: "Plain text description."
        examples:
          - "Short descriptive text."
      link_url:
        type: string
        title: Link URL
        format: uri-reference
        examples:
          - "/destinations/example"
      link_text:
        type: string
        title: Link text
        examples:
          - "Read more"
  maxItems: 6
  examples:
    - - image:
          src: "https://placehold.co/400x300"
          alt: "Card image"
          width: 400
          height: 300
        title: "Card title"
        text: "Short descriptive text."
        link_url: "/destinations/example"
        link_text: "Read more"
```

---

## `canvas:image` include

**Never render images manually with `<img>`** — always use `{% include 'canvas:image' %}`.

| Property | Required | Type | Description |
|---|---|---|---|
| `src` | ✅ | string | Relative, absolute or stream wrapper URI |
| `alt` | — | string | Alt text — always provide for accessibility |
| `width` | — | integer | Prevents layout shifts (CLS) |
| `height` | — | integer | Prevents layout shifts (CLS) |
| `sizes` | — | string | Responsive sizes (e.g., `(max-width: 768px) 100vw, 50vw`) |
| `loading` | — | string | `lazy` (default) or `eager` (above-the-fold only) |
| `class` | — | string | CSS class(es) for the `<img>` element |
| `attributes` | — | Attribute | Extra HTML attributes via `create_attribute({...})` |

```twig
{# Standard usage #}
{% if image.src is not empty %}
  {% include 'canvas:image' with image|merge({
    loading: 'lazy',
    sizes: '(max-width: 480px) 100vw, (max-width: 768px) 50vw, 33vw',
    class: 'c-card__img',
  }) only %}
{% endif %}

{# Hero / above-the-fold #}
{% if image.src is not empty %}
  {% include 'canvas:image' with image|merge({
    loading: 'eager',
    sizes: '100vw',
    class: 'c-hero__img',
  }) only %}
{% endif %}

{# Inside a complex array item #}
{% if card.image.src is not empty %}
  {% include 'canvas:image' with card.image|merge({
    loading: 'lazy',
    sizes: '(max-width: 768px) 100vw, 33vw',
    class: 'c-cards__img',
  }) only %}
{% endif %}
```

---

## Twig rules

- `{% set classes = [...] %}` + `{{ attributes.addClass(classes) }}` — never `addClass('c-...')` directly
- `{% set attributes = attributes ?: create_attribute() %}`
- ❌ No `title_prefix` / `title_suffix`
- ❌ No manual `<img>` — always `canvas:image`
- `|raw` only on props with `contentMediaType: text/html` — never on plain `type: string`
- Image check: `{% if image.src is not empty %}`
- Arrays: always guard with `{% if items is not empty %}`

### Template example

```twig
{% set attributes = attributes ?: create_attribute() %}
{% set classes = [
  'c-card',
  is_featured ? 'c-card--featured' : '',
] %}

<article {{ attributes.addClass(classes) }}>

  {% if image.src is not empty %}
    <div class="c-card__image">
      {% include 'canvas:image' with image|merge({
        loading: 'lazy',
        sizes: '(max-width: 480px) 100vw, (max-width: 768px) 50vw, 33vw',
        class: 'c-card__img',
      }) only %}
    </div>
  {% endif %}

  <div class="c-card__content">
    {% if tags is not empty %}
      <ul class="c-card__tags">
        {% for tag in tags %}
          <li class="c-card__tag">{{ tag }}</li>
        {% endfor %}
      </ul>
    {% endif %}

    {% if title is not empty %}
      <h3 class="c-card__title">{{ title }}</h3>
    {% endif %}

    {# Plain text — no |raw #}
    {% if text is not empty %}
      <div class="c-card__text">{{ text }}</div>
    {% endif %}

    {# HTML text — |raw only because contentMediaType: text/html #}
    {% if body is not empty %}
      <div class="c-card__body">{{ body|raw }}</div>
    {% endif %}

    {% if link_url is not empty and link_text is not empty %}
      <div class="c-card__footer">
        <a
          href="{{ link_url }}"
          class="c-card__link"
          target="{{ link_target|default('_self') }}"
          {% if (link_target|default('_self')) == '_blank' %}rel="noopener noreferrer"{% endif %}
        >
          {{ link_text }}
        </a>
      </div>
    {% endif %}
  </div>

</article>
```

---

## Key differences from Layout Builder mode

| Concern | Canvas | Layout Builder |
|---|---|---|
| Image props | `$ref: canvas.module/image` | `type: string` (Drupal renders) |
| Enum labels | `meta:enum` supported | `meta:enum` supported |
| HTML text | `contentMediaType: text/html` + `\|raw` | Not needed |
| Image rendering | `{% include 'canvas:image' %}` | `{{ image }}` (already rendered) |
| Block title slots | ❌ Never | `{{ title_prefix }}` / `{{ title_suffix }}` |
| Custom CSS classes | ❌ Not used | `*_classes` / `*_utility_classes` arrays |
| `Attribute` type | ❌ Not supported | Supported |

→ Back to [SKILL.md](../SKILL.md)
