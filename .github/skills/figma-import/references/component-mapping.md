# Figma Layer → SDC Component Mapping

How to translate Figma design structures into SDC props, slots, and template patterns for both rendering modes.

For the SDC prop type rules that govern each mode, refer to `@sdc` → `references/mode-drupal-layout-builder.md` or `references/mode-canvas.md`.

---

## Figma Layer Type → SDC Prop Type

| Figma layer | SDC prop (Layout Builder) | SDC prop (Canvas) | Notes |
|---|---|---|---|
| Text layer | `type: string` | `type: string` | Plain text; no `\|raw` unless HTML formatting needed |
| Rich text / paragraph | `type: string` | `type: string` + `contentMediaType: text/html` | Canvas only: add `x-formatting-context: block` and use `\|raw` in Twig |
| Image | `type: string` | `$ref: canvas.module/image` | LB: Drupal renders as string; Canvas: object with `src`, `alt`, `width`, `height` |
| Video | `type: string` | `$ref: canvas.module/video` | Canvas object has `src`, `poster` |
| Link / CTA button | `type: string` (url) + `type: string` (label) | `format: uri-reference` + `type: string` (label) | Always split URL and label into separate props |
| Boolean layer (show/hide) | `type: boolean` | `type: boolean` | Figma property "Show X" → `show_x: boolean` |
| Variant property | `type: string` + `enum` | `type: string` + `enum` | Figma variant names → enum values (lowercase, snake_case) |
| Repeating item (list) | `type: array` + `items.type: string` | `type: array` + `items.type: string` | Add `maxItems` if there's a logical cap |
| Card / repeating complex block | `type: array` + `items.type: object` | **slot** (see Canvas array rule below) | Canvas does not support `items.type: object` — must be a slot |
| Icon | CSS `::before`/`::after` via `@icons` skill | CSS `::before`/`::after` via `@icons` skill | Not a prop — icon is part of SCSS |
| Slot area (arbitrary content) | `slots:` block | `slots:` block | Use when content is structured markup, not a simple string |

---

## Figma Variants → Enum Props

Figma variants define visual states. These map directly to SDC enum props:

**Figma variant property:**
- Property: `Style`
- Values: `Default`, `Featured`, `Compact`

**SDC equivalent:**
```yaml
style:
  type: string
  title: Style
  description: "Visual style of the component."
  enum:
    - default
    - featured
    - compact
  meta:enum:
    default: Default
    featured: Featured
    compact: Compact
  default: default
  examples:
    - default
```

**Twig usage:**
```twig
{% set classes = [
  'c-card',
  style != 'default' ? 'c-card--' ~ style : '',
] %}
```

**Conversion rules for variant values:**
- Strip leading/trailing whitespace
- Convert to lowercase
- Replace spaces with hyphens: `"Text Image"` → `text-image`
- Do not use the Figma variant name verbatim if it's camelCase: `FeaturedCard` → `featured-card`

---

## Figma Boolean Properties → SDC Boolean Props

Figma boolean properties ("Show badge", "Has icon") map to `type: boolean`:

```yaml
# Figma: "Show badge" property (True/False)
show_badge:
  type: boolean
  title: Show badge
  description: "Display the badge element on the card."
  default: false
  examples:
    - false
```

**Twig:**
```twig
{% if show_badge %}
  <span class="c-card__badge">{{ badge_text }}</span>
{% endif %}
```

---

## Figma Auto-Layout → CSS

| Figma auto-layout | CSS equivalent |
|---|---|
| Direction: Horizontal | `display: flex; flex-direction: row` |
| Direction: Vertical | `display: flex; flex-direction: column` |
| Gap | `gap: var(--spacing-*)` |
| Padding | `padding: var(--spacing-*)` |
| Align items: Center | `align-items: center` |
| Justify content: Space between | `justify-content: space-between` |
| Wrap: Wrap | `flex-wrap: wrap` |

Never hard-code spacing values — always map to the closest `--spacing-*` variable.

---

## Variable Naming Rules (Enforcement)

All SDC prop names must be in `snake_case` (lowercase + underscores). Convert any Figma variable names during mapping — never use Figma's naming directly if it's camelCase or contains spaces.

| Figma name | SDC prop name |
|---|---|
| `buttonText` | `button_text` |
| `ShowIcon` | `show_icon` |
| `Card Title` | `title` (or `card_title` if ambiguous) |
| `BgColor` | `background_color` (avoid abbreviations) |
| `CTALabel` | `cta_label` |
| `isActive` | `is_active` |

**Rule**: if the prop name has more than two words, always use underscores. Abbreviations are allowed only if universally understood (`cta`, `url`, `id`).

---

## Responsive Frames → Image Styles

When a Figma design has multiple frames at different breakpoints (mobile, tablet, desktop), use `@image-styles` to generate Drupal responsive image styles:

1. Note the image dimensions at each Figma frame width
2. Map frame widths to Drupal breakpoints:

| Figma frame | Drupal breakpoint |
|---|---|
| 375px (mobile) | `xs` / `xxs` |
| 768px (tablet) | `md` |
| 1280px (desktop) | `xl` |
| 1920px (large) | `xxl` |

3. Invoke `@image-styles` with dimensions per breakpoint to generate the `image.style.*.yml` config files

---

## Slot vs Prop Decision

Use a **prop** when the content is:
- A scalar value (string, number, boolean, URL)
- An array of **simple** items (`items.type: string` or `items.type: number`)
- Data that comes from a Drupal field

Use a **slot** when the content is:
- Arbitrary HTML markup rendered by the caller
- A nested Drupal block or region
- Content whose structure the component doesn't control
- An array of **complex** items (`items.type: object`) in **Canvas mode**

### Canvas array rule (CRITICAL)

Canvas does **not** support `items.type: object` in props. Any repeating block where each item has multiple sub-fields (e.g. cards, features, steps) **must** be modelled as slots, not an array prop.

**N Figma elements → N named slots**: count the repeating items in the Figma design and generate exactly that many named slots — one per item.

```yaml
# ❌ WRONG in Canvas — complex array as prop
props:
  items:
    type: array
    items:
      type: object
      properties:
        title: { type: string }
        description: { type: string }

# ✅ CORRECT in Canvas — one named slot per Figma array element
# Example: Figma array had 3 feature items
slots:
  feature_1:
    title: Feature 1
    description: "First feature item."
    examples:
      - "<div class='c-features__item'><h3>Title</h3><p>Description.</p></div>"
  feature_2:
    title: Feature 2
    description: "Second feature item."
    examples:
      - "<div class='c-features__item'><h3>Title</h3><p>Description.</p></div>"
  feature_3:
    title: Feature 3
    description: "Third feature item."
    examples:
      - "<div class='c-features__item'><h3>Title</h3><p>Description.</p></div>"
```

**Twig — never use `{% if %}` on Canvas slots**:

```twig
{# ✅ Render slots directly — NEVER wrap in {% if %} #}
<div class="c-features__list">
  <div class="c-features__item">{{ feature_1 }}</div>
  <div class="c-features__item">{{ feature_2 }}</div>
  <div class="c-features__item">{{ feature_3 }}</div>
</div>

{# ❌ WRONG — slots must not be conditional #}
{% if feature_1 is not empty %}
  {{ feature_1 }}
{% endif %}
```

In Layout Builder mode, `items.type: object` is allowed as a prop.

```yaml
# Slot example — the component doesn't know what's inside
slots:
  footer:
    title: Footer
    description: "Optional footer content — any HTML or nested component."
    examples:
      - "<button class='c-btn'>Read more</button>"
```

→ Back to [SKILL.md](../SKILL.md)
