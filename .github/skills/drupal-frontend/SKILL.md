---
name: drupal-frontend
description: Expert in Drupal 10.3+ frontend theming, SCSS, JavaScript, and theme structure. Use this skill for general Drupal theming tasks (not SDC-specific).
---

## Role & Capabilities

You are a specialist in Drupal 10.3+ frontend theming. Your expertise covers theme structure, SCSS/CSS architecture, JavaScript integration with Drupal.behaviors, and Drupal's theming system (excluding SDC components - use the `sdc` skill for that).

## Critical Context Paths (Knowledge Base)

**Note**: All paths below use `{theme_path}` and `{theme_name}` placeholders. The agent reads actual values from `agent.config.json` at session start.

- **Global SCSS**: `{theme_path}/scss/variables` (Variables, mixins, and base styles)
- **Theme Root**: `{theme_path}/` (Theme structure and configuration)
- **Libraries**: `{theme_path}/{theme_name}.libraries.yml` (Asset definitions)
- **Preprocess**: `{theme_path}/{theme_name}.theme` (Preprocess hooks)

## Drupal 10.3+ Theming Standards

### Theme Architecture (Showcase Theme)

The `{theme_path}` theme is located at `{theme_base}` and follows **Atomic Design** principles.

### SCSS/CSS

- **BEM Naming**: Use BEM convention for class names (`.block__element--modifier`)
- **CSS Variables**: Use CSS Variables for theme tokens (colors, spacing). All CSS variables are defined in `{theme_path}/scss/variables/_variables-css.scss`.
- **Theme Mixins**: Prioritize theme mixins from `{theme_path}/scss/variables`
- **SCSS Imports**: Import only `@import '{theme_path}/scss/variables';` - this file already contains all necessary imports (mixins, variables, functions). Do not import individual files from the variables directory.
```scss
// ✅ CORRECT - Import only this (contains all necessary imports)
@import 'variables';

// ❌ WRONG - Don't import individual files
@import 'variables/mixins';
@import 'variables/colors';
```

**Responsive:**
- Mobile-first approach
- Use Bootstrap-style mixins:
  ```scss
  @include media-breakpoint-up(md) {
    // Styles for md and up
  }
  @include media-breakpoint-down(lg) {
    // Styles for lg and down
  }
  ```

  Available breakpoints defined in `{theme_path}/scss/variables/_mixins.scss`

**Modern CSS:**
- Use CSS Grid and Flexbox
- Leverage custom properties
- Container queries when appropriate
- Avoid floats and clearfix hacks

**Accessibility:**
- Maintain 4.5:1 color contrast for text
- Define proper focus states (`:focus`, `:focus-visible`)
- Don't rely solely on color for meaning


### JavaScript (CRITICAL)

**Pattern:** Drupal.behaviors (MANDATORY)

```javascript
// ✅ CORRECT - Always use this pattern
;(function (Drupal, once) {
  'use strict'

  Drupal.behaviors.myComponentBehavior = {
    attach: function (context, settings) {
      once('my-component', '.my-component', context).forEach(
        function (element) {
          // Initialization code here
          element.addEventListener('click', function(e) {
            // Event handling
          })
        }
      )
    }
  }
})(Drupal, once)
```

**Requirements:**
- Use `once` library to prevent double-initialization
- ES6+ syntax (const/let, arrow functions, template literals)
- Vanilla JavaScript only (jQuery is FORBIDDEN)
- Proper error handling with try/catch for critical operations

### Theme Structure

- **Declaration and regions**: Define regions in `THEME_NAME.info.yml`
- **Libraries**: Define assets in `THEME_NAME.libraries.yml`
- **Preprocess**: Use preprocess hooks in `THEME_NAME.theme` for logic
- **Templates**: Override Twig templates in `templates/` directory
- **Breakpoints**: Define responsive breakpoints in `THEME_NAME.breakpoints.yml`

### Icons

- **Pseudo-elements**: Use `::before`/`::after` for SVG icons
- **Icon Lookup**: For specific icon code lookups and content values, refer to **@icons** skill
- **Implementation**: Apply icons via SCSS using the icon font system

### Twig Integration

- **Security**: For class assignment and library attachment best practices, refer to **@twig** skill
- **Template Suggestions**: Use appropriate template suggestions for granular overrides
- **Preprocess**: Attach libraries via preprocess functions, not in templates

## Related Skills

- **@sdc**: For Single Directory Components work
- **@twig**: For Twig templating standards and security
- **@icons**: For finding icon codes and class names
