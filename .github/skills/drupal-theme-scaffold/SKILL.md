---
name: drupal-theme-scaffold
description: Use this skill to scaffold a new Drupal custom theme from scratch. Generates the full directory structure, all base files with the theme name applied, and gulp build tooling in the project root. Trigger whenever the user wants to create a new Drupal theme, set up a base custom theme structure, scaffold a Drupal theme, prepare an empty theme, or start a Drupal project with theming. Use it even if they only say "I need a theme", "set up the theme", or "create the theme" without explicitly mentioning "scaffold".
---

## Rol

Especialista en crear temas Drupal personalizados desde cero. Orquesta la generación completa del tema mediante cuatro subagentes especializados ejecutándose en paralelo.

---

## Flujo de trabajo

### Paso 1 — Nombre del tema

Pregunta al usuario:

> "¿Qué nombre quieres ponerle al tema?"

**Reglas de normalización:**
- Siempre en minúsculas; espacios → guiones bajos
- Ejemplos: `Hiberus Theme` → `hiberus_theme`, `Mi Tema` → `mi_tema`
- Guarda como `{theme_name}` — se usará en nombres de archivo, funciones, rutas y contenidos

### Paso 2 — Detectar web root

Lee el directorio raíz del proyecto:
- Si existe `web/` → `web_root = web`
- Si existe `docroot/` → `web_root = docroot`
- Si ninguna existe → pregunta: "¿La carpeta raíz del proyecto es `web/` o `docroot/`?"

La ruta del tema será: `{web_root}/themes/custom/{theme_name}/`

### Paso 3 — Variables de diseño Figma

Pregunta al usuario:

> "¿Tienes archivos de Figma de los que extraer variables CSS (colores, tipografía, etc.)? Puedes pasar una o varias URLs o IDs, e indicar qué contiene cada una (ej: colores, tipografía, espaciado…)."

Los tipos soportados son: `colors`, `typography`, `spacing`, `other`.

**Si hay URLs de Figma** → lee `references/figma-scss-rules.md` antes de lanzar el Subagente B. Contiene las reglas exactas de colocación por tipo, resolución de conflictos entre fuentes, e invariantes (z-index, transiciones) que nunca se modifican.

**Sin Figma** → el Subagente B usa los valores predeterminados de `references/scss-templates.md`.

### Paso 4 — Generar archivos del tema

Con `{theme_name}`, `{web_root}` y la decisión sobre Figma resueltos, lanza los cuatro subagentes en paralelo — son completamente independientes entre sí. La estructura de directorios completa esperada está en `references/theme-directory-tree.md`.

---

#### Subagente A — Configuración Drupal

Lee: `references/drupal-config.md`

Genera en `{web_root}/themes/custom/{theme_name}/`:
- `{theme_name}.info.yml`, `{theme_name}.libraries.yml`, `{theme_name}.theme`
- `includes/libraries.inc`, `includes/preprocess.inc`, `includes/suggestions.inc`
- `js/custom/example.es6.js`
- Carpetas vacías con `.gitkeep` (lista en la referencia)
- `favicon.ico` vacío, `logo.svg` copiado de `assets/logo.svg`

---

#### Subagente B — Arquitectura SCSS

Lee: `references/scss-templates.md`
Si hay datos Figma, lee también: `references/figma-scss-rules.md`

Genera en `{web_root}/themes/custom/{theme_name}/scss/`:
- `_variables.scss`, `style.scss`
- `base/_generic.scss`
- `layout/header.scss`, `layout/footer.scss`
- `variables/_variables-css.scss`, `variables/_mixins.scss`, `variables/_fonts.scss`
- `variables/fonts/_fuenteejemplo.scss`

---

#### Subagente C — Plantillas Twig

Lee: `references/twig-templates.md`

Genera en `{web_root}/themes/custom/{theme_name}/`:
- `templates/includes/header.html.twig`
- `templates/includes/footer.html.twig`
- `templates/layout/page.html.twig`
- `templates/layout/html.html.twig`

---

#### Subagente D — Build Tooling

Lee: `references/build-tooling.md`

Genera en la **raíz del proyecto** (mismo nivel que `composer.json`):
- `package.json` con todas las dependencias Gulp/Babel/PostCSS
- `gulpfile.js` con `basePath = "./{web_root}/themes/custom/"`

---

### Paso 5 — Verificación final

Cuando los cuatro subagentes completen su trabajo, verifica activamente:
- Sin placeholders residuales `{theme_name}` o `{web_root}` en ningún archivo generado
- Todas las carpetas vacías tienen `.gitkeep`
- `gulpfile.js` tiene el `basePath` correcto
- `_variables-css.scss` contiene los bloques `// Z-index` y `// Transition`

El checklist completo está en `references/post-generation-checklist.md`.

---

## Skills relacionadas

- **@sdc** — Para crear componentes SDC dentro del nuevo tema
- **@drupal-twig-bridge** — Para conectar plantillas de entidad con componentes SDC
- **@drupal-frontend** — Arquitectura SCSS y patrones JavaScript
- **@figma-import** — Si se van a crear componentes desde un diseño Figma
