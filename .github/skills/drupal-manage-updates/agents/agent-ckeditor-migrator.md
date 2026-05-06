---
name: agent-ckeditor-migrator
description: 'Guides the CKEditor 4→5 migration: audits content, classifies plugins, coordinates UI migration format-by-format, applies post-UI YAML config, cleans up CKE4 packages, and produces a production deploy runbook.'
---

# Agent CKEditor Migrator — Migración Guiada CKEditor 4→5

> **Rutas:** Scripts en `$SKILL_DIR/scripts/`. Informes en `reports/drupal-update/`.
> **🚨 NUNCA migres sin informar al usuario. Pregunta ante cualquier decisión.**
> **REGLA:** SIEMPRE usa `ddev composer`, `ddev drush`, NUNCA sin `ddev`.
> **FUNDAMENTAL:** La migración de formatos de texto SOLO puede hacerse vía UI de Drupal.
> El wizard mapea la toolbar automáticamente, migra settings y detecta incompatibilidades.
> Cambiar el editor programáticamente (_via drush eval o PHP directo_) omite ese trabajo
> y deja la configuración rota. No existe alternativa programática fiable.

## Condición de guarda

```bash
bash "$SKILL_DIR/scripts/paso-06b-ckeditor.sh" --phase=detect
```

Lee el JSON generado en `reports/drupal-update/paso-06b-ckeditor.json`.
Si `formats_using_cke4 == 0`:

```
COMPLETED
CKEditor 4 not detected — migration skip.
```

Continúa solo si hay formatos usando CKEditor 4.

## Paso 0: Auditoría de contenido pre-migración

Antes de planificar, audita el contenido para detectar HTML especial que afectará
las decisiones de configuración de SourceEditing:

```bash
bash "$SKILL_DIR/scripts/paso-06b-content-audit.sh"
```

Lee el JSON generado en `reports/drupal-update/paso-06b-content-audit.json` y presenta:

```
Auditoría de contenido pre-migración:
  <iframe> encontrados: N registros en X tablas
  <div> con clases especiales: N registros
  Templates CKE4 activos: sí / no
  Recomendación SourceEditing: [etiquetas a añadir según lo encontrado]
```

Esta información determina qué `allowed_tags` configurar en el Paso 5.

## Paso 1: Plugins CKEditor 4 detectados

Lee `reports/drupal-update/paso-06b-ckeditor.json`:

- Formatos de texto que usan CKEditor 4 (`format_names`)
- Plugins contrib CKE4 instalados (`plugin_names`)

## Paso 2: Clasificación de plugins y plan

Leyendo `references/ckeditor-migration.md`, clasifica cada plugin contrib CKE4
y presenta el mapa al usuario **antes de proceder**:

```
Clasificación de plugins CKEditor 4→5:
  Migrados automáticamente por el wizard: Bold, Italic, DrupalLink, ...
  Requieren configuración manual post-UI:
    - Iframe → SourceEditing con <iframe> en allowed_tags
    - Templates → [evaluar ckeditor5_template o prescindir según audit]
    - Styles con <div> → SourceEditing (Style de CKE5 no soporta <div>)
```

Espera confirmación del usuario antes de continuar.

## Paso 3: Verificar dependencias

```bash
ddev drush pm:uninstall ckeditor --dry-run 2>&1
```

Si hay módulos habilitados que dependen de `ckeditor` → presenta diagnóstico
al usuario y espera su decisión antes de continuar.

## Paso 4: Migración vía UI — un formato a la vez

**El agente NO migra formatos programáticamente.** Para cada formato en `format_names`,
indica al usuario:

```
📋 UI HANDOFF — Formato: {nombre_formato}

Ve a: /admin/config/content/formats/manage/{nombre_formato}

1. Cambia "Text editor": CKEditor → CKEditor 5
2. Drupal mostrará avisos en amarillo sobre plugins sin equivalente — es normal
3. Revisa la toolbar generada automáticamente
4. Guarda con "Save configuration"

Cuando termines, indícame:
  a) Si se guardó correctamente
  b) Qué warnings/mensajes aparecieron (cópialos aquí)
```

Espera respuesta del usuario antes de pasar al siguiente formato.
En caso de error inesperado → PARAR → diagnosticar → presentar opciones.

Warnings esperados (no bloquean):

- "The CKEditor 4 button Iframe does not have a known upgrade path" → gestionar en Paso 5
- "The CKEditor 4 button Templates does not have a known upgrade path" → gestionar en Paso 5
- "The CKEditor 4 button ShowBlocks does not have a known upgrade path" → feature eliminada, OK

## Paso 5: Configuración post-UI en YAML

Una vez el usuario confirma todos los formatos migrados, exporta la config:

```bash
ddev drush cex -y
```

### 5a: SourceEditing — añadir etiquetas del audit

Edita `config/default/editor.editor.{formato_full}.yml`.
Busca `sourceEditing.allowed_tags` y añade las etiquetas identificadas en el Paso 0:

- `<iframe>` si el audit detectó iframes en el contenido
- `<div class="ejemplo">` para cada clase especial detectada (Style de CKE5 no acepta `<div>`)

Ejemplo de resultado en YAML:

```yaml
sourceEditing:
  allowed_tags:
    - '<iframe>'
    - '<div class="contain-max">'
```

### 5b: Verificar estilos (Style plugin)

Revisa la sección `style.styles` en `config/default/editor.editor.{formato}.yml`.
El wizard habrá migrado la mayoría automáticamente. Comprueba:

- `<span>`, `<h2-h6>`, `<p>`, `<blockquote>` → deben estar presentes como Style
- `<div>` con clases → **NO pueden estar en Style**; muévelos a `sourceEditing.allowed_tags`

### 5c: Estrategia para Templates (si aplica)

Si el Paso 0 detectó el plugin Templates activo, pregunta al usuario:
"¿Los editores usan activamente las plantillas de CKEditor?"

- Sí, uso frecuente → evaluar módulo contrib `ckeditor5_template` antes de desinstalar
- No / uso esporádico → prescindir y documentar en el commit

Importa y reconstruye la caché:

```bash
ddev drush cim -y
ddev drush cr
```

## Paso 6: Limpieza de paquetes CKEditor 4

> ⚠️ **ADVERTENCIA DE DESPLIEGUE — presenta esto al usuario antes de ejecutar:**
>
> Eliminar paquetes de composer rompe producción si el módulo sigue activo en BD:
> al desplegar, `composer install` no tendrá los archivos del módulo y `drush cim`
> fallará al intentar desinstalar sin esos archivos presentes.
>
> **Runbook obligatorio para producción** (ejecutar en el servidor con el código
> ANTIGUO todavía activo):
>
> ```bash
> drush pm:uninstall ckeditor ckeditor_iframe ckeditor_templates fakeobjects -y
> ```
>
> Solo después se puede desplegar el nuevo código.

Tras confirmación del usuario:

```bash
ddev drush pm:uninstall ckeditor ckeditor_iframe ckeditor_templates -y
ddev composer remove drupal/ckeditor drupal/ckeditor_iframe drupal/ckeditor_templates 2>&1
ddev composer remove npm-asset/fakeobjects 2>&1 || true
```

Limpia entradas huérfanas de `composer.json` (repositorios y `installer-paths` de los
paquetes eliminados). Edita directamente y valida:

```bash
python3 -m json.tool composer.json > /dev/null && echo "JSON válido"
```

### Modo dry-run (F8)

Si `$dry_run == true`: describe las acciones sin ejecutar ninguna.
Marca toda la salida como `[DRY-RUN — no changes applied]`.

## Paso 7: Export de config y commit selectivo

```bash
ddev drush cex -y
```

`drush cex` captura todo el config del sitio. Haz un commit solo con los ficheros
de esta migración:

```bash
git add \
  composer.json \
  composer.lock \
  config/default/core.extension.yml \
  config/default/editor.editor.*.yml \
  config/default/filter.format.*.yml
```

El commit message debe incluir el runbook de producción:

```
feat: migrate CKEditor 4 to CKEditor 5

- Enable ckeditor5 module (core)
- Migrate {lista de formatos} text formats to CKEditor 5 via UI wizard
- Configure SourceEditing with {lista de etiquetas} for {formato}
- Remove: ckeditor, ckeditor_iframe, ckeditor_templates (and composer packages)

DEPLOY NOTE: Before deploying this code to production, run on the server
while the OLD code is still active:
  drush pm:uninstall ckeditor ckeditor_iframe ckeditor_templates fakeobjects -y
Then deploy normally: composer install → drush cim -y → drush cr
```

Si hay otros ficheros de config modificados no relacionados con CKEditor,
compromételos en un commit separado:

```bash
git add config/default/
git reset HEAD config/default/editor.editor.*.yml config/default/filter.format.*.yml
git commit -m "chore: export pending config changes"
```

## Paso 8: Validación post-migración

```bash
bash "$SKILL_DIR/scripts/paso-06b-ckeditor.sh" --phase=validate
```

El script verifica: CKE5 habilitado, CKE4 desinstalado, watchdog sin errores.

A continuación, pide al usuario verificación en la UI:

```
✅ Validación manual — verifica en el navegador:

1. /admin/config/content/formats
   → Sin avisos de migración pendiente

2. Edita un nodo con formato {full_html}
   → Toolbar CKEditor 5 visible y funcional
   → Botones de estilo custom activos
   → Botón Source editing (</>) funciona

3. Si hay <iframe> en el contenido:
   → Abre source de un nodo con <iframe>
   → El iframe se mantiene sin errores

4. Verifica el front-end de páginas con contenido rico
   → HTML se renderiza igual que antes

¿Todo correcto? (sí / describe los problemas)
```

## Report-Back

En caso de éxito:

```
COMPLETED
- Formatos migrados: {lista}
- Plugins auto-migrados por el wizard: {lista}
- SourceEditing configurado: {etiquetas} en {formatos}
- Templates: {gestionadas / prescindidas / contrib evaluado}
- Paquetes CKE4 eliminados: {lista}
- Commit: {hash}
- DEPLOY NOTE incluida: sí
- Validación automática: pass
- Validación manual: pendiente confirmación usuario
```

En caso de fallo:

```
FAILED
Stage: {paso donde falló}
Error: {motivo}
```
