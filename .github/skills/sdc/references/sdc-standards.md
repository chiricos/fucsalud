# SDC Technical Standards

Reference for component structure, file conventions, metadata schema, slots, variants, shared Twig patterns, styling rules, and debugging.

---

## Table of Contents

- [Component Structure & Levels](#component-structure--levels)
- [Required Files](#required-files)
- [Component Metadata](#component-metadata)
- [Props: Field-Level Rules](#props-field-level-rules)
- [Slots](#slots)
- [Variants](#variants)
- [Shared Twig Patterns](#shared-twig-patterns)
- [Styling (SCSS) and JavaScript](#styling-scss-and-javascript)
- [Icons](#icons)
- [Automatic Asset Loading](#automatic-asset-loading)
- [Debugging](#debugging)

---

## Component Structure & Levels

```
docroot/themes/custom/{theme_name}/components/
├── atoms/           # Basic UI elements
├── molecules/       # Simple component groups
├── organisms/       # Complex component assemblies
└── drupal/          # Drupal system component overrides
```

**Naming Convention**: Use `kebab-case` for directories and files.

| Level | Description | Examples |
|---|---|---|
| **Atoms** | Smallest reusable units | button, heading, alert, image, link |
| **Molecules** | Combinations of atoms | card, banner, accordion-item, video |
| **Organisms** | Complex UI sections | slider, accordion, FAQs, block-cards |
| **Drupal** | System component overrides | tabs, breadcrumbs, messages |

---

## Required Files

```
components/molecules/card/
├── card.component.yml  # Component metadata (REQUIRED)
├── card.twig           # Template (REQUIRED)
├── card.scss           # Styles (optional, auto-loaded)
└── card.js             # JavaScript (optional, auto-loaded)
```

- Filenames **must match** the component directory name
- `*.component.yml` and `*.twig` are mandatory
- SCSS/JS are optional but auto-loaded when present

---

## Component Metadata

```yaml
$schema: https://git.drupalcode.org/project/drupal/-/raw/10.3.x/core/assets/schemas/v1/metadata.schema.json
name: Component Name
status: stable
description: Clear description of what this component does and when to use it
group: Molecules
```

- `$schema`: use the version matching the project's Drupal version — ask if unsure
- `status`: `stable`, `experimental`, or `deprecated`
- `group`: Content, Layout, Media, Molecules, Organisms, etc.

---

## Props: Field-Level Rules

These rules apply regardless of mode (Layout Builder or Canvas):

- **`examples` are MANDATORY** for all props, including sub-props inside complex arrays
- Use `enum` for limited value sets
- `meta:enum` provides human-readable labels for the UI — use it in both `drupal-layout-builder` and `canvas` modes
- Always set sensible `default` values
- For arrays: always define `items.type` and `maxItems` when there is a logical limit
- **Never mix** `drupal-layout-builder` and `canvas` patterns in the same component

---

## Slots

```yaml
slots:
  header:
    title: Header
    description: "Optional header content (badges, icons, etc.)"
    examples:
      - "<h2>Card Header</h2>"
  content:
    title: Content
    required: true
    description: "Main content area (required)"
    examples:
      - "<p>Card body content.</p>"
```

- Mark required slots explicitly with `required: true`
- Use semantic names: `header`, `content`, `footer`, `image`, `info`
- Provide HTML examples showing expected structure
- Use `{% embed %}` in the calling template, not `{% include %}`, when a component accepts slots

---

## Variants

```yaml
variants:
  default:
    title: Default
    description: Standard layout
  featured:
    title: Featured
    description: Highlighted variant with stronger visual weight
```

- Variants are applied via CSS classes: `'c-card--' ~ variant`
- Variants don't set prop values — they're purely visual modifiers

---

## Shared Twig Patterns

These patterns are required in every component template, regardless of mode. They are repeatedly needed; internalise them.

### 1. Attributes initialisation

Always initialise `attributes` before use so the template works whether or not Drupal passes the object in:

```twig
{% set attributes = attributes ?: create_attribute() %}
```

### 2. BEM class list + `addClass`

Build the class list as an array, then apply via `attributes.addClass()`. Never pass a class string directly:

```twig
{% set classes = [
  'c-card',
  modifier ? 'c-card--' ~ modifier : '',
] %}

<article {{ attributes.addClass(classes) }}>
```

Empty strings in the array are filtered automatically — this is the canonical way to apply conditional modifiers.

### 3. Non-empty guard for optional props

Always check before rendering optional content to avoid empty markup:

```twig
{% if title is not empty %}
  <h3 class="c-card__title">{{ title }}</h3>
{% endif %}
```

For Canvas images, check the `src` sub-property specifically:

```twig
{% if image.src is not empty %}
  {# ... canvas:image include #}
{% endif %}
```

### 4. Array iteration with non-empty guard

Always guard the loop to avoid rendering an empty wrapper element:

```twig
{% if tags is not empty %}
  <ul class="c-card__tags">
    {% for tag in tags %}
      <li class="c-card__tag">{{ tag }}</li>
    {% endfor %}
  </ul>
{% endif %}
```

For complex arrays, access sub-props with dot notation and guard each sub-prop individually:

```twig
{% if cards is not empty %}
  <div class="c-cards__list">
    {% for card in cards %}
      <div class="c-cards__item">
        {% if card.title is not empty %}
          <h3 class="c-cards__title">{{ card.title }}</h3>
        {% endif %}
      </div>
    {% endfor %}
  </div>
{% endif %}
```

### 5. Semantic root element

Choose the root element based on content semantics:

| Content type | Element |
|---|---|
| Independent content (article, news) | `<article>` |
| Grouped related content | `<section>` |
| Navigation | `<nav>` |
| Generic layout | `<div>` |

### 6. Security: attribute concatenation

Never concatenate user input directly into HTML attributes. Use Drupal's attribute system or Twig escaping. For details, refer to **@twig**.

---

## Styling (SCSS) and JavaScript

### SCSS

**CRITICAL — follow this order every time**:
1. Use an Explore subagent to read `{paths.scss_variables}/_variables-css.scss` and return all available CSS custom properties
2. Use ONLY variables that exist in that file
3. Never invent CSS variable names
4. If a needed variable doesn't exist, ask the user before creating it

All CSS custom property names must be lowercase (`--spacing-md`, not `--spacingMd`).

**Orden de propiedades CSS (stylelint `order/properties-order`)**

El proyecto aplica `stylelint-order`. Escribe siempre las propiedades en este orden dentro de cada bloque:

```
1.  all · content
2.  position · inset · top · right · bottom · left · z-index
3.  display · vertical-align
4.  flex · flex-grow · flex-shrink · flex-basis · flex-direction · flex-flow · flex-wrap
5.  grid · grid-area · grid-template · grid-template-areas · grid-template-rows · grid-template-columns
    grid-row · grid-row-start · grid-row-end · grid-column · grid-column-start · grid-column-end
    grid-auto-rows · grid-auto-columns · grid-auto-flow · grid-gap · grid-row-gap · grid-column-gap
    gap · row-gap · column-gap
6.  place-content · align-content · justify-content
    place-items · align-items · justify-items
    place-self · align-self · justify-self
7.  order · float · clear · object-fit
8.  overflow · overflow-x · overflow-y · overflow-scrolling · clip
9.  box-sizing · width · min-width · max-width · height · min-height · max-height
10. margin · margin-inline · margin-block · margin-top · margin-right · margin-bottom · margin-left
11. padding · padding-inline · padding-block · padding-top · padding-right · padding-bottom · padding-left
12. border (shorthand → por lados → border-radius → border-image)
13. background · background-color · background-image · background-attachment
    background-position · background-position-x · background-position-y
    background-clip · background-origin · background-size · background-repeat
14. color · box-decoration-break · box-shadow
15. outline · outline-width · outline-style · outline-color · outline-offset
16. table-layout · caption-side · empty-cells
17. list-style · list-style-position · list-style-type · list-style-image
18. font · font-family · font-weight · font-style · font-variant · font-size-adjust · font-stretch · font-size
    src · line-height · letter-spacing
19. quotes · counter-increment · counter-reset · -ms-writing-mode
20. text-align · text-align-last · text-decoration · text-emphasis · text-emphasis-position
    text-emphasis-style · text-emphasis-color · text-indent · text-justify · text-outline
    text-transform · text-wrap · text-overflow · text-overflow-ellipsis · text-overflow-mode
    text-shadow · white-space · word-spacing · word-wrap · word-break · overflow-wrap
    tab-size · hyphens · interpolation-mode
21. opacity · visibility · filter · resize · cursor · pointer-events · user-select
22. unicode-bidi · direction
23. columns · column-span · column-width · column-count · column-fill · column-gap
    column-rule · column-rule-width · column-rule-style · column-rule-color
24. break-before · break-inside · break-after · page-break-before · page-break-inside · page-break-after
    orphans · widows · zoom · max-zoom · min-zoom · user-zoom · orientation
25. fill · stroke
26. transition · transition-delay · transition-timing-function · transition-duration · transition-property
27. transform · transform-origin
28. animation · animation-name · animation-duration · animation-play-state
    animation-timing-function · animation-delay · animation-iteration-count
    animation-direction · animation-fill-mode
```

Regla práctica: **posicionamiento → layout (flex/grid) → caja (box-model) → fondo → color → tipografía → efectos → animación**.

### JavaScript

Refer to **@frontend** for `Drupal.behaviors`, `once()` patterns, and build system integration.

---

## Icons

- Use `::before`/`::after` pseudo-elements for icons
- Refer to **@icons** for the full icon code list
- Avoid inline `<svg>` unless required for animation or dynamic colour

---

## Automatic Asset Loading

CSS/JS files are auto-loaded when the component renders — no `.libraries.yml` or `attach_library()` calls needed.

```bash
gulp        # Compile all SCSS and JS
gulp watch  # Watch and auto-compile
```

---

## Debugging

| Problem | Steps |
|---|---|
| Component not found | Check directory name matches `machine_name`, verify YML + Twig exist, `ddev drush cr` |
| Styles not loading | Check SCSS filename matches directory, run `gulp`, verify compiled `.css` exists, `ddev drush cr` |
| JS not working | Check JS filename matches directory, check browser console errors, verify `Drupal.behaviors` + `once()` |
| Props not rendering | Check prop names match between YML ↔ Twig, use `{{ dump(prop_name) }}` |
| Slots not working | Use `{% embed %}` not `{% include %}`, verify block name matches slot key |

```twig
{# Debug helpers #}
{{ dump() }}           {# All variables in context #}
{{ dump(title) }}      {# Specific prop #}
{{ dump(_context) }}   {# Full context object #}
```

→ Back to [SKILL.md](../SKILL.md)
