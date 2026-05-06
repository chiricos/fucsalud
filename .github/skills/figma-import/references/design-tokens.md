# Design Token Mapping: Figma → CSS Variables

When translating a Figma design to a Drupal SDC component, every numeric or styled value from Figma should map to an existing CSS custom property in the project theme rather than being hard-coded. This makes components maintainable and consistent.

**Before writing any SCSS**: use an Explore subagent to read `{paths.scss_variables}/_variables-css.scss` and return all available custom properties. Use only variables that exist there — if a needed variable is missing, ask the user before creating a new one.

---

## Token Mapping Table

| Figma category | Figma example | CSS variable pattern | Example value |
|---|---|---|---|
| Color (fill) | `#1A3A6C` | `var(--color-primary)` | `#1A3A6C` |
| Color (text) | `#333333` | `var(--color-text)` | `#333333` |
| Color (background) | `#F5F5F5` | `var(--color-bg-subtle)` | `#F5F5F5` |
| Spacing (padding) | `16px` | `var(--spacing-md)` | `1rem` |
| Spacing (gap) | `24px` | `var(--spacing-lg)` | `1.5rem` |
| Spacing (margin) | `8px` | `var(--spacing-sm)` | `0.5rem` |
| Font size | `18px` | `var(--font-size-md)` | `1.1rem` |
| Font weight | `700` | `var(--font-weight-bold)` | `700` |
| Line height | `1.5` | `var(--line-height-base)` | `1.5` |
| Border radius | `8px` | `var(--border-radius-md)` | `0.5rem` |
| Border color | `#DDDDDD` | `var(--color-border)` | `#DDDDDD` |
| Box shadow | `0 2px 8px rgba(0,0,0,0.1)` | `var(--shadow-md)` | `0 2px 8px …` |

---

## Common Pitfalls

### Opacity
Figma layers with opacity produce a color + alpha, not a separate `opacity` property. Map to a CSS color variable that includes the alpha:

```scss
// ❌ Figma opacity layer → hard-coded rgba
background-color: rgba(26, 58, 108, 0.4);

// ✅ Map to a scrim/overlay variable if it exists
background-color: var(--color-overlay);

// ✅ Or ask user if a semi-transparent variable should be added
```

### Auto-layout gap
Figma auto-layout spacing → CSS `gap` (for flex/grid), not `margin`:

```scss
// Figma: auto-layout, gap 16px
.c-card__content {
  display: flex;
  flex-direction: column;
  gap: var(--spacing-md); // not margin-bottom on children
}
```

### Shadows
Figma shadow values are usually mapped directly or to a shadow variable. Never hard-code the full value if a `--shadow-*` variable exists:

```scss
// ❌
box-shadow: 0 4px 16px rgba(0, 0, 0, 0.12);

// ✅
box-shadow: var(--shadow-lg);
```

### Figma "Effect" styles (blur, inner shadow)
These rarely have direct CSS variable equivalents. Document them as a comment in the SCSS and ask the user if a variable should be added:

```scss
// TODO: Figma uses "Card Elevated" effect style — no --shadow-elevated variable found.
// Using closest match: var(--shadow-md)
box-shadow: var(--shadow-md);
```

### Letter spacing
Figma uses points (pt) or percentage; convert to `em` before looking for a variable:

```
Figma letter-spacing: 5% → 0.05em → check for var(--letter-spacing-wide)
```

---

## Token Naming Convention

All CSS custom properties in Drupal themes follow these rules:

- Lowercase only: `--color-primary`, not `--colorPrimary` or `--Color-Primary`
- Hyphen-separated: `--spacing-md`, not `--spacing_md`
- Category prefix: `--color-`, `--spacing-`, `--font-size-`, `--font-weight-`, `--border-radius-`, `--shadow-`, `--line-height-`
- Scale names: `xs`, `sm`, `md`, `lg`, `xl`, `xxl` (not `small`, `medium`, `large`)

---

## When No Variable Exists

If a Figma value doesn't have a matching CSS custom property:

1. Check if a close variant exists (e.g., `--spacing-sm` vs `--spacing-xs`)
2. If none fits, **ask the user** before hard-coding or creating a new variable
3. Never invent variable names — that breaks theme coherence

→ Back to [SKILL.md](../SKILL.md)
