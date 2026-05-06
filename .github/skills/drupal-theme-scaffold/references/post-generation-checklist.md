# Checklist post-generación

Puntos de verificación activa al finalizar todos los subagentes.

---

## Reglas de sustitución

Antes de crear cualquier archivo, reemplaza **todas** las ocurrencias de `{theme_name}` y `{web_root}` en:

| Contexto | Ejemplos |
|---|---|
| Nombres de archivo y carpeta | `{theme_name}.info.yml`, `{web_root}/themes/…` |
| Nombres de función PHP | `{theme_name}_preprocess_node()`, `Drupal.behaviors.{theme_name}` |
| Referencias `.yml` | clave `libraries:`, región `{theme_name}/global-styling` |
| Plantillas `.twig` | `@{theme_name}/includes/header.html.twig` |
| Archivos `.scss` y `.js` | rutas `@font-face`, `basePath`, includes |
| Nombres de hooks, librerías y rutas de includes | cualquier string que contenga el placeholder |

---

## Tema

- [ ] Nombre del tema normalizado (minúsculas, espacios → guiones bajos)
- [ ] Web root detectado (`web/` o `docroot/`)
- [ ] Todas las ocurrencias de `{theme_name}` reemplazadas en todos los archivos generados
- [ ] Todas las ocurrencias de `{web_root}` reemplazadas en todos los archivos generados
- [ ] Carpetas vacías creadas con `.gitkeep` (ver lista en `drupal-config.md`)

## Figma (si aplica)

- [ ] Variables CSS aplicadas por tipo (`colors`, `typography`, `spacing`, `other`)
- [ ] Conflictos de nombres entre fuentes documentados con `// [CONFLICT resolved from <url>]`
- [ ] Bloques `// Z-index` y `// Transition` presentes e intactos en `_variables-css.scss`

## Build tooling

- [ ] `gulpfile.js` y `package.json` creados en la raíz del proyecto
- [ ] `basePath` del gulpfile usa el web root correcto: `"./{web_root}/themes/custom/"`
