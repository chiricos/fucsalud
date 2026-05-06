---
name: sdc
description: Use this skill when working with SDC component creation, modification, or troubleshooting in Drupal 10.3+. Trigger for requests about Single Directory Components, SDC props, slots, component.yml, Twig templates for Drupal components, Canvas components, Layout Builder components, Drupal theming components, or any request involving creating or editing a Drupal frontend component. Trigger even if the user does not mention "SDC" explicitly — if they ask about creating a visual block, card, banner, hero, or any UI element in a Drupal theme, this skill applies.
---

## Role & Capabilities

You are a specialist in Drupal 10.3+ Single Directory Components (SDC). Your expertise covers component structure, metadata definition, props/slots management, and integration with Drupal's theming system.

## Core Principles

- **Component-First Architecture**: SDC components are self-contained, reusable UI building blocks
- **Atomic Design**: Follow the project's atomic design structure (atoms → molecules → organisms)
- **Props over Configuration**: Use props for data, slots for content areas
- **Automatic Asset Loading**: CSS/JS files are loaded automatically when component renders
- **Documentation Required**: All props, slots, and variables must be documented

## Critical Context Paths

All paths are constructed from `agent.config.json`. The key variables are `theme_name` and `drupal_root`.

> **Subagent opportunity — Environment Setup**: Before writing code on a new component, use an Explore subagent to gather context in one pass:
> 1. Read `agent.config.json` → extract `theme_name`, `drupal_root`, and the `paths` object
> 2. Read `{paths.scss_variables}/_variables-css.scss` → return all available CSS custom properties
> 3. Scan `{paths.golden_sample}` → return the YML structure and Twig attribute/class patterns
>
> The subagent should return a structured summary. Work from that summary — do not re-read those files during code generation.

- **Reference Components**: `skills/sdc/references/` — use `manifest.json` to locate components by mode
- **Global SCSS variables**: `{paths.scss_variables}/_variables-css.scss`
- **Golden Sample**: `{paths.golden_sample}` — definitive structural template for the project

## SDC Reference Protocol

- **Consistency**: Prioritise coherence with existing components; reuse mixins/variables from the current theme.
- **Security**: Never expose secrets or credentials. If any are found in context, notify the user and omit them.

---

## ⚠️ Component Context Mode (REQUIRED FIRST STEP)

**At the start of EVERY component creation task, before writing any code, always ask:**

> **"¿Este componente va a estar asociado a Drupal Layout Builder / nodo, o se va a renderizar con Canvas?"**

> **Exception**: if the mode has already been resolved by an invoking skill (e.g. **@figma-import**), skip this question and use the resolved mode directly.

The answer determines how props are defined and how the Twig template is structured. **Never mix patterns from both modes.**

---

## Mode Routing

Once the mode is resolved, load the corresponding reference document and reference component before generating any code:

### Mode A: `drupal-layout-builder`

**Read now**: `references/mode-drupal-layout-builder.md`

This covers:
- Sub-mode question (block vs node — determines `title_prefix`/`title_suffix`)
- `*.component.yml` prop type rules and YAML examples (`meta:enum`, `Attribute`, `*_classes`)
- `*.twig` rules and a complete template example

**Reference component**: `references/card/` — production-ready Layout Builder component with YML, Twig, SCSS, and JS.

### Mode B: `canvas`

**Read now**: `references/mode-canvas.md`

This covers:
- `*.component.yml` prop type rules including `$ref` image, `uri-reference`, `contentMediaType`
- `|raw` usage and XSS safety rules (critical — read before writing any Twig)
- Canvas prop examples and the `canvas:image` include reference
- `*.twig` rules and a complete template example

**Reference component**: `references/card-canvas/` — production-ready Canvas component with YML, Twig, and SCSS.

---

## Universal Props Rules

These apply regardless of mode — internalize them before writing any `*.component.yml`:

- **`examples` are MANDATORY** for all props, including sub-props inside complex arrays
- Use `enum` for limited value sets
- `meta:enum` provides human-readable labels for the UI — use it in both `drupal-layout-builder` and `canvas` modes
- Always set sensible `default` values
- For arrays: always define `items.type` and `maxItems` when there is a logical limit
- **Never mix** `drupal-layout-builder` and `canvas` patterns in the same component

Para patrones Twig compartidos (atributos, clases, guards de vacío, iteración de arrays) consulta [`references/sdc-standards.md#shared-twig-patterns`](references/sdc-standards.md#shared-twig-patterns). Para reglas de props y slots consulta [`#props-field-level-rules`](references/sdc-standards.md#props-field-level-rules) y [`#slots`](references/sdc-standards.md#slots).

---

## XSS Safety Reminder

The `|raw` filter bypasses Twig's auto-escaping. In Canvas mode, it is only safe when the prop explicitly declares `contentMediaType: text/html` — Canvas is then responsible for sanitising the content before passing it. On any plain `type: string` prop, `|raw` is a security vulnerability. See the full rules in `references/mode-canvas.md`.

---

## Component Creation Workflow

Follow these steps in order for every new component:

1. **Resolve mode** — Ask the mode question (or receive it from `@figma-import`). Do not proceed without it.
2. **Gather context** (subagent opportunity) — Use an Explore subagent to read `agent.config.json`, SCSS variables, and the golden sample in one pass.
3. **Load mode reference** — Read `references/mode-drupal-layout-builder.md` or `references/mode-canvas.md` depending on mode.
4. **Read the reference component** — Open the matching component in `references/card/` (Layout Builder) or `references/card-canvas/` (Canvas) as a structural guide.
5. **Determine atomic level** — Decide atom / molecule / organism based on complexity. See [`references/sdc-standards.md#component-structure--levels`](references/sdc-standards.md#component-structure--levels) for definitions and examples.
6. **Generate files** — Create `{name}.component.yml` and `{name}.twig`. Apply SCSS only if styling is needed. For shared Twig patterns (attributes, classes, non-empty guards, array iteration) see [`sdc-standards.md#shared-twig-patterns`](references/sdc-standards.md#shared-twig-patterns). For SCSS property order see [`sdc-standards.md#styling-scss-and-javascript`](references/sdc-standards.md#styling-scss-and-javascript).

> **Subagente — Validar variables SCSS** (paso 7): Una vez redactado el SCSS, usa un subagente Explore para leer `{paths.scss_variables}/_variables-css.scss` y verificar que cada propiedad CSS personalizada usada en el componente existe en ese archivo. El subagente debe devolver:
> - Lista de variables CSS usadas en el componente
> - ✅ / ❌ para cada una según si existe en el archivo
> - Si hay variables inventadas: elimínalas del SCSS o pregunta al usuario antes de añadirlas al archivo de variables.

> **Subagente — Quality check** (paso 8): Usa un subagente Explore para comparar el componente generado contra el reference component del modo activo. El subagente debe comprobar y reportar:
> - [ ] Convención de nombres en YML (snake_case para props, kebab-case para el nombre del componente)
> - [ ] Manejo correcto de `attributes` y `addClass()` en Twig
> - [ ] Nombres de clase BEM coherentes con el proyecto
> - [ ] Variables SCSS existentes (no inventadas)
> - [ ] Ausencia de patrones del modo contrario (p. ej. `title_prefix` en Canvas, o `$ref` en Layout Builder)
> - [ ] `examples` presentes en todas las props
> Para cada criterio: ✅ correcto / ⚠️ desviación encontrada + descripción.

> **Subagente — Post-creación** (paso 9): Usa un subagente para ejecutar `gulp` desde la raíz del proyecto y verificar que el SCSS compila sin errores. El subagente debe devolver el output completo de gulp y marcar ✅ si no hay errores o ⚠️ con el mensaje exacto del error si los hay. Recuerda al usuario ejecutar `ddev drush cr` para limpiar la caché de Drupal.

Para troubleshooting de componentes (no encontrado, estilos no cargan, JS no funciona) consulta [`sdc-standards.md#debugging`](references/sdc-standards.md#debugging).

---

## Related Skills

- **@twig**: Twig templating standards, security, and best practices
- **@icons**: Icon codes and class names — refer to before using `::before`/`::after` pseudo-elements
- **@frontend**: SCSS architecture, JavaScript patterns (`Drupal.behaviors`, `once()`), preprocess hooks
- **@figma-import**: Converting Figma designs to SDC components (resolves mode before invoking this skill)