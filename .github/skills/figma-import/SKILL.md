---
name: figma-import
description: Figma to SDC conversion. Use this skill whenever the user shares a Figma URL, references a Figma design, asks to implement a mockup or design file, wants to convert a visual design into a Drupal component, or mentions props, slots, arrays, icons, or responsive behaviour. Trigger even if they don't say "SDC" or "Figma" explicitly — if there's a design to implement in Drupal, this skill applies.
---

## Role

Expert frontend architect specialized in translating Figma designs into scalable, design-system-consistent, production-ready Drupal SDC components.

Generate clean, maintainable code aligned with modern frontend best practices: responsive, accessible, and reusable. Prioritize developer-friendly code consistent with the design system over pixel-perfect fidelity.

---

## Skills and references

Load these resources when relevant to the current step — do not read all of them upfront:

| Resource | When to load |
|---|---|
| `references/component-mapping.md` | When mapping Figma layers → SDC props/slots |
| `references/design-tokens.md` | When mapping Figma values → CSS variables |
| `@sdc` | When generating the SDC component structure |
| `@icons` | When resolving icons from the design |
| `@image-styles` | When the design has images at multiple breakpoints |
| `@frontend` | For advanced SCSS/JS patterns |

---

## Critical preconditions

Verify these conditions **before** generating any code:

1. **Semantic variables** — any variable the design requires such as `--primary-color`, `--secondary-color`, `--primary-font`, `--accent-color`, etc. must exist in `{paths.scss_variables}/_variables-css.scss`. If it does not → **STOP** and ask the user before continuing.
2. **Arrays in Canvas** — complex arrays (`items.type: object`) are not supported as props in Canvas mode; they must always be converted to slots.
3. **Icons** — look up in the project icon library (`@icons`) first; only if no match is found, extract the SVG from the Figma node.
4. **Colors and dimensions** — never hardcode values; use CSS variables and `currentColor`.

---

## Workflow

The flow has 4 phases. Phases 1, 2, and 3 are good candidates for delegation to subagents for greater efficiency.

### Phase 1 — Analysis

**Recommended subagent**: Explore subagent with access to Figma MCP tools.

1. Obtain the Figma URL. If not provided, request it before continuing.
2. In a single pass, invoke the Figma MCP tools to:
   - Read all layers, variants, texts, and icons.
   - Extract geometry: dimensions, spacing, typography, colors.
   - Detect required semantic variables and list any that are missing from the project.
   - Identify arrays and classify them (simple vs. complex).
   - Generate and save a screenshot if MCP supports it.
   - Return a structured summary: layer names, detected props, breakpoints, image/text/link areas.
3. If semantic variables are missing → stop the flow and ask the user before continuing to Phase 2.
4. Confirm with the user whether they want to generate the SDC component or just review the analysis.

> **If Figma MCP is unavailable**: ask the user to provide a screenshot or description of the component structure and continue to Phase 2 with what is available.

### Phase 2 — Generation

**Recommended subagent**: subagent with access to `@sdc`, `@icons`, and `@image-styles`.

1. Resolve the component mode — ask:
   > **"Is this component going to be associated with Drupal Layout Builder / a node, or will it be rendered with Canvas?"**
   - **Layout Builder / node** → `drupal-layout-builder` mode in `@sdc`
   - **Canvas** → `canvas` mode in `@sdc`

2. Map the Figma structure → SDC (see `references/component-mapping.md`):
   - Simple arrays (`items.type: string` or `number`) → prop in both modes.
   - Complex arrays (`items.type: object`) → **N named slots in Canvas** (one per Figma array element — never wrap them in `{% if %}`); prop in Layout Builder.
   - Icons → follow [Icon Rules](#icon-rules) below.
   - All prop names in `snake_case`.

3. Apply the design rules before invoking `@sdc`:
   - [Layout Rules](#layout-rules) — Auto Layout → Flexbox/Grid
   - [Size Rules](#size-rules) — px to rem conversion
   - [Font Rules](#font-rules) — typography variables
   - [Color Rules](#color-rules) — color and semantic variables

4. Invoke `@sdc` passing the resolved mode and the component structure. `@sdc` must not ask for the mode again.

5. Apply [Height Rules](#height-rules) to every generated SCSS block.

### Phase 3 — Validation

**Recommended subagent**: Explore subagent.

Verify the output before presenting it to the user:

- No fixed `height` on containers or text wrappers (only allowed on `<img>` with `object-fit`).
- All prop names are `snake_case`.
- All CSS variables used in SCSS exist in `{paths.scss_variables}/_variables-css.scss`.
- Complex arrays in Canvas are slots, not props.
- Icon SVGs use `currentColor`, not hardcoded colors.

Report any violations found and fix them before moving to Phase 4.

### Phase 4 — Presentation and feedback

1. If a screenshot was generated in Phase 1, save it to `{paths.components}/{component_name}/screenshots/`.
2. Present the result following the [Output Format](#output-format).
3. Summarise the decisions made and any ambiguities detected.

---

## Output Format

The response must include these sections in order:

1. **Component name** — chosen `kebab-case` name
2. **Layout decision** — why Flexbox or Grid was chosen; the detected pattern
3. **Props (Twig variables)** — typed list of all SDC props
4. **HTML** — semantic markup
5. **Twig** — SDC template using `{{ variable }}` — no hardcoded content
6. **CSS / SCSS (BEM + variables)** — all spacing, font, and color variables used or created
7. **Responsive strategy** — breakpoint behaviour, stacking, spacing adjustments
8. **Design system generated** — all variables created or reused
9. **Notes** — assumptions made, ambiguities found, suggested improvements

---

## Layout Rules

### Auto Layout → CSS (CRITICAL)

| Figma Auto Layout | CSS output |
|---|---|
| `layoutMode: HORIZONTAL` | `display: flex; flex-direction: row;` |
| `layoutMode: VERTICAL` | `display: flex; flex-direction: column;` |
| `layoutMode: NONE` | infer from geometry (see below) |
| `itemSpacing` | `gap: Xrem` |
| `paddingTop/Right/Bottom/Left` | `padding: Xrem Xrem Xrem Xrem` |
| `primaryAxisAlignItems: CENTER` | `justify-content: center` |
| `primaryAxisAlignItems: SPACE_BETWEEN` | `justify-content: space-between` |
| `counterAxisAlignItems: CENTER` | `align-items: center` |
| `counterAxisAlignItems: STRETCH` | `align-items: stretch` |
| `layoutGrow: 1` on child | `flex: 1` on that child |
| `layoutAlign: STRETCH` on child | `align-self: stretch` on that child |

Use **CSS Grid** instead of Flexbox when:
- `layoutMode: NONE` but children form a visible grid (multiple rows + columns).
- Columns repeat at equal sizes (`repeat(N, 1fr)`).

When `layoutMode: NONE`: analyse geometry and children to infer intent. Never output `position: absolute` to replicate Figma's absolute positioning — infer the semantic layout (flex, grid, or flow).

Common patterns to detect: `hero-banner`, `card-list`, `navbar`, `gallery`, `feature-grid`.

Use `gap` instead of margins between children.

---

## Size Rules (CRITICAL)

- Round all values to the nearest integer before converting to rem (≥ .5 → round up, < .5 → round down).
- Base: `16px = 1rem`. Formula: integer ÷ 16, rounded to exactly 1 decimal place.
- Examples: `26px → 1.6rem` / `28px → 1.8rem` / `24px → 1.5rem`
- **Never more than 1 decimal place**. Use `clamp()` on large font sizes where it improves responsive behaviour.
- Reuse existing spacing variables if a value is within 1–2px of an existing one. Create new variables only when no close match exists.

---

## Font Rules

Always use typography CSS variables. Never hardcode font values.

```scss
--font-body-size: 1.6rem;
--font-body-weight: 400;
--font-body-line-height: 1.5;
```

Use `clamp()` on large type sizes where it improves responsive behaviour.

---

## Color Rules

Always use CSS custom properties. Never hardcode hex or rgb values.

Mandatory naming convention: `--color-name-weight`

```scss
--blue-800: #1a3060;
--gray-200: #e5e7eb;
```

If a required color variable does not exist, create it following the convention above.

**Special semantic color names — `error`, `warning`, `success`:**

When a Figma color layer or token is named `error`, `warning`, or `success` (case-insensitive, with any weight suffix such as `error-500`):

1. Do **not** use the standard `--color-name-weight` pattern.
2. Use the prefix pattern instead: `--error-weight`, `--warning-weight`, `--success-weight`.
   - Example: Figma color `error-500` → `--error-500`; `warning-300` → `--warning-300`.
3. Before creating the variable, read `{paths.scss_variables}/_variables-css.scss` to check if it already exists.
   - If it **does** exist → assign the new variable the existing one as its value:
     ```scss
     --error-500: var(--existing-variable);
     ```
   - If it **does not** exist → create it with the extracted color value:
     ```scss
     --error-500: #d32f2f;
     ```

**CRITICAL — Semantic color variables (blocking step):**

For any semantic variable the design requires (`--primary-color`, `--secondary-color`, `--primary-font`, `--secondary-font`, `--accent-color`, etc.):

1. Read `{paths.scss_variables}/_variables-css.scss` to check whether it already exists.
2. If it exists → use it as-is. Do not ask the user anything.
3. **If it does NOT exist → STOP. Do not generate any SCSS or Twig code.** Ask the user first:
   > "Before continuing I need to define the following semantic variables that do not exist in the project: `--primary-color`, `--secondary-color` (or others detected). Which color variable should we associate with each?"

   Only proceed with code generation after the user has answered. Never invent or assume a value for a missing semantic color variable.

---

## Icon Rules

1. **Look up the icon library first** — invoke `@icons` to search for the unicode value or class name in the project's icon system. If a match is found, render it via CSS or an `<i>` element as the skill instructs.

2. **Fall back to inline SVG** — if no icon library is available or the icon has no match, extract the SVG path data directly from the Figma vector node (via MCP). Never invent or approximate paths — always use the exact `<path>`, `<circle>`, `<rect>`, etc. from the Figma node:

```twig
{# Icon: arrow-right — extracted from Figma vector node, no library match #}
<svg xmlns="http://www.w3.org/2000/svg" width="24" height="24" viewBox="0 0 24 24" aria-hidden="true" focusable="false">
  {# paths extracted verbatim from Figma #}
  <path d="..." fill="currentColor"/>
</svg>
```

   - Always add `aria-hidden="true"` and `focusable="false"` to decorative SVGs.
   - If the icon is meaningful (not decorative), add a visually-hidden `<span>` with a text label instead of `aria-label` on the SVG.
   - Never hardcode colors inside the SVG — use `currentColor` so the icon inherits the text color and is themeable via CSS.
   - Extract `width` and `height` from the Figma bounding box; never guess dimensions.

---

## Height Rules (CRITICAL)

Fixed heights on containers break content flow when text length or viewport changes. This is the most common regression in Figma-to-code conversions because Figma frames always have fixed sizes.

```scss
// ❌ WRONG — mirrors Figma frame height directly
.c-card {
  height: 224px;
}

// ✅ CORRECT — let content drive height; constrain with min/max if needed
.c-card {
  min-height: 200px; // optional minimum only

  &__image {
    height: 224px; // fixed height is fine on <img> with object-fit
    object-fit: cover;
  }
}
```

- `height: auto` — always fine (it's the default)
- `min-height` / `max-height` — fine for constraints
- Fixed `height` on `<img>` with `object-fit` — fine
- Fixed `height` on containers or text wrappers — **forbidden**

---

## Naming Rules

- `kebab-case` for all CSS classes and component names. Never use generic names (`frame`, `group`, `rectangle`, `container1`).
- Base names on design intent: `hero-banner`, `card-list`, `feature-grid`, `nav-primary`.
- SDC prop names must always be `snake_case`:

| Figma | SDC prop |
|---|---|
| `buttonText` | `button_text` |
| `ShowIcon` | `show_icon` |
| `BgColor` | `background_color` |
| `CTALabel` | `cta_label` |

---

## Accessibility Rules

- Use semantic HTML: `<section>`, `<nav>`, `<ul>`, `<button>`, `<article>`, etc.
- Maintain a logical structure for screen readers.
- Never use `<div>` when a semantic element is appropriate.