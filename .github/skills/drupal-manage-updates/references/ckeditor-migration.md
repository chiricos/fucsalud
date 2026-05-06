# Referencia: Migración CKEditor 4 → CKEditor 5

Drupal 10 requiere CKEditor 5. Los proyectos en Drupal 9 o que migran de D9→D10
deben migrar sus text formats y configuraciones de CKEditor 4 a CKEditor 5.

Referenciada exclusivamente por: `agent-ckeditor-migrator.md`.
Módulos: `ckeditor` (D9, deprecado en D10) → `ckeditor5` (D10+, core).

> **Nota de arquitectura:** La migración de formatos **debe hacerse vía UI de Drupal**
> (`/admin/config/content/formats`), no programáticamente. El wizard mapea la toolbar,
> migra settings y detecta plugins sin equivalente. Cambiar el editor vía `drush eval`
> o PHP directo omite ese trabajo y genera configuraciones rotas.

---

## Mapa de plugins CKEditor 4 → CKEditor 5

| Plugin CKE4             | Equivalente CKE5              | Migración                                              |
| ----------------------- | ----------------------------- | ------------------------------------------------------ |
| `Bold`                  | `Bold`                        | Automática por el wizard                               |
| `Italic`                | `Italic`                      | Automática por el wizard                               |
| `Underline`             | `Underline`                   | Automática por el wizard                               |
| `Strike`                | `Strikethrough`               | Automática por el wizard                               |
| `Link`                  | `Link`                        | Automática por el wizard                               |
| `Image` / `ImageUpload` | `Image` / `ImageBlock`        | Automática por el wizard con ajuste                    |
| `Table` / `TableTools`  | `Table`                       | Automática por el wizard                               |
| `HtmlEmbed`             | `HtmlEmbed`                   | Automática por el wizard                               |
| `MediaEmbed`            | `MediaEmbed`                  | Automática por el wizard                               |
| `SourceEditing`         | `SourceEditing`               | Automática por el wizard                               |
| `Format` (headings)     | `Heading`                     | Automática por el wizard                               |
| `List` / `ListStyle`    | `List`                        | Automática por el wizard                               |
| `Alignment`             | `Alignment`                   | Automática por el wizard                               |
| `BlockQuote`            | `BlockQuote`                  | Automática por el wizard                               |
| `Styles` (stylescombo)  | `Style`                       | **Parcialmente automática** — ver nota abajo           |
| `Font` (size/color)     | ❌ Sin equivalente            | Manual / contrib (`ckeditor5_font`)                    |
| `Iframe` plugin         | SourceEditing                 | **Manual** — añadir `<iframe>` a `allowed_tags`        |
| `Templates` plugin      | ❌ Sin equivalente directo    | **Manual** — evaluar `ckeditor5_template` o prescindir |
| `ShowBlocks`            | ❌ Eliminado en CKE5          | Feature removida; eliminar de toolbar                  |
| Plugins contrib custom  | Verificar página del proyecto | Caso a caso                                            |

### Nota sobre `Styles` (stylescombo)

El wizard de Drupal migra automáticamente la mayoría de los estilos (`<span>`, `<h2-h6>`,
`<p>`, `<blockquote>`, etc.). Sin embargo, **CKEditor 5 Style plugin no soporta el elemento
`<div>`**. Los estilos que usaban `<div class="...">` en CKE4 no se pueden definir en el
plugin Style de CKE5: deben trasladarse a `SourceEditing.allowed_tags` con la clase
correspondiente.

---

## Limitación crítica: Style plugin de CKE5 no admite `<div>`

CKEditor 5 sólo permite definir estilos sobre elementos de bloque con semántica
establecida (`<h2>`, `<p>`, `<blockquote>`, `<table>`, etc.) y elementos inline
(`<span>`, `<a>`, `<strong>`, etc.). El elemento `<div>` no está permitido en
el plugin Style.

**Solución:** Para cualquier clase CSS que se aplicaba a `<div>` en CKE4
(ej: `<div class="contain-max">`), usa SourceEditing:

```yaml
# En editor.editor.full_html.yml
sourceEditing:
  allowed_tags:
    - '<div class="contain-max">'
```

Los editores acceden a este elemento abriendo el modo Source (`</>` button).

---

## Estrategia para `<iframe>` — SourceEditing

No existe un plugin `<iframe>` nativo en CKEditor 5 core. La solución recomendada
es SourceEditing: añadir `<iframe>` a las etiquetas permitidas del plugin Source Editing,
permitiendo que los editores inserten/editen iframes vía el código fuente.

**No requiere módulo contrib** para el caso de uso habitual (embeds de YouTube, Vimeo,
Google Maps u otros). El contenido existente se conserva y se renderiza correctamente
porque el filtro de texto (`filter.format.full_html.yml`) ya permite `<iframe>` en
`allowed_html`.

Configuración en `editor.editor.full_html.yml`:

```yaml
sourceEditing:
  allowed_tags:
    - '<iframe>'
```

Si se necesita una interfaz visual con un botón dedicado, evaluar el módulo contrib
`ckeditor5_embedded_content` u otros similares. Solo necesario para sitios con
creación frecuente de nuevos iframes.

---

## Estrategia para Templates

El plugin `Templates` de CKEditor 4 no tiene equivalente directo en CKEditor 5 core.
Opciones:

1. **Prescindir** (recomendado si el uso es esporádico): los editores pueden usar
   bloques de contenido de Drupal, párrafos reutilizables, o copiar/pegar desde
   documentos referencia. Documentar en el commit que la feature se elimina.

2. **Módulo contrib `ckeditor5_template`**: proporciona funcionalidad equivalente.
   Evaluar si el uso es frecuente y crítico para los editores.

Antes de decidir, audita mediante `paso-06b-content-audit.sh` si el plugin estaba
activo en algún formato (`templates_plugin_active_in`).

---

## Migración de Text Formats — Flujo correcto

**Solo vía UI** (wizard de Drupal):

1. Ir a `/admin/config/content/formats/manage/{nombre_formato}`
2. Cambiar "Text editor": `CKEditor` → `CKEditor 5`
3. Drupal muestra avisos en amarillo sobre plugins sin equivalente — esperados, no bloquean
4. Revisar la toolbar generada y guardar

**NO usar:**

```php
// ❌ Roto — omite el wizard de migración
$editor->setEditor('ckeditor5');
$editor->save();
```

### Ajustes manuales post-UI

```bash
ddev drush cex -y
# Editar editor.editor.{formato}.yml: añadir sourceEditing.allowed_tags
ddev drush cim -y
ddev drush cr
```

---

## Detección de plugins custom

```bash
grep -r "Plugin\|ckeditor" web/modules/custom/ --include="*.info.yml" -l
find web/modules/custom/ -path "*/js/ckeditor/*" -name "*.js"
grep -r "ckeditor_plugins\|plugins:" config/ --include="*.yml" -l
```

Los plugins custom de CKEditor 4 (`Plugin` con `CKEDITOR.plugins.add`) requieren
reescritura completa en CKEditor 5 (`ClassicEditor.builtinPlugins`). No hay migración
automática para código custom.

---

## Validación post-migración

```bash
ddev drush pm:list --filter=ckeditor --fields=name,status   # debe ser uninstalled
ddev drush pm:list --filter=ckeditor5 --fields=name,status  # debe ser enabled
ddev drush watchdog:show --type=ckeditor5 --count=20
```

O usar el script:

```bash
bash "$SKILL_DIR/scripts/paso-06b-ckeditor.sh" --phase=validate
```

**Señales de migración exitosa:**

- `/admin/config/content/formats` no muestra warnings de migración pendiente
- Watchdog sin errores de `ckeditor5`
- Los text formats se renderizan correctamente en el front-end
- Los estilos custom aplican las clases CSS esperadas
