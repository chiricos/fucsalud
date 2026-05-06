---
name: agent-custom-code-fixer
description: 'Analyzes and fixes compatibility issues in custom modules and themes for the target Drupal and PHP versions.'
---

# Agent Custom Code Fixer — Análisis y Corrección de Código Custom

> **Rutas:** Scripts en `$SKILL_DIR/scripts/`. Informes en `reports/drupal-update/`.
> **🚨 SOLO modifica ficheros en `modules/custom/` y `themes/custom/`. NUNCA toques contrib ni core.**
> **REGLA:** SIEMPRE usa `ddev composer`, `ddev drush`, NUNCA sin `ddev`.

## Por qué este paso importa

El código custom del proyecto puede usar APIs internas de Drupal que cambian o
desaparecen entre versiones mayores. Si actualizamos el core sin adaptar el
código custom primero, el sitio se rompe con errores fatales en runtime. Este
agente detecta esos problemas y los corrige antes del salto de core.

## Entrada

Lee el informe de escaneo generado previamente:

- `reports/drupal-update/paso-06c-custom-code.json` — hallazgos por módulo/tema

Si el informe no existe, ejecuta el escaneo primero:

```bash
bash "$SKILL_DIR/scripts/paso-06c-custom-code-check.sh"
```

Lee también la referencia de patrones de migración para el salto que aplique:

- `references/custom-code-migration.md` — tabla de reemplazos API por versión de Drupal

## Modo dry-run (F8)

Si `$dry_run == true`:

- Ejecuta el escaneo normalmente (es solo lectura)
- Presenta el plan de correcciones pero NO modifica ficheros
- Reporta como simulación

## Ejecución

### Fase 1: Verificar y presentar el diagnóstico

Lee el JSON y presenta el resumen al usuario:

```
📋 CÓDIGO CUSTOM — Diagnóstico de compatibilidad

  Versión objetivo:  D{target_major} ({target_version})
  Extensiones:       {total} ({modules} módulos, {themes} temas)

  ❌ Errores (bloquean el upgrade):  {total_errors}
  ⚠️  Warnings (revisar):            {total_warnings}

  Módulos afectados:
    - foo_custom:   3 errores, 2 warnings
    - bar_theme:    0 errores, 5 warnings
    - baz_module:   1 error
```

Si `status == "clean"` → reportar COMPLETED sin correcciones.

### Fase 2: Planificar correcciones

Para cada hallazgo con `severity: "error"`, consulta `references/custom-code-migration.md`
para encontrar el patrón de reemplazo. Agrupa por módulo para commits limpios.

Presenta el plan de correcciones al usuario y espera aprobación:

```
🔧 PLAN DE CORRECCIONES

  foo_custom/ (3 errores):
    1. foo_custom.module:45 — entity_load() → \Drupal::entityTypeManager()->getStorage()->load()
    2. foo_custom.module:89 — drupal_set_message() → \Drupal::messenger()->addMessage()
    3. src/Plugin/Block/FooBlock.php:23 — Actualizar tipo de retorno de blockAccess()

  baz_module/ (1 error):
    4. baz_module.install:12 — db_query() → \Drupal::database()->query()

¿Apruebas las correcciones? (sí/no/modificar)
```

### Fase 3: Aplicar correcciones

Para cada módulo, en orden:

1. **Lee el fichero completo** donde está el hallazgo
2. **Comprende el contexto** — no reemplaces a ciegas, entiende qué hace el código
3. **Aplica el fix** usando el patrón correcto de `references/custom-code-migration.md`
4. **Verifica** que el fix no rompe la lógica (tipos, variables, scope)
5. **Commit por módulo:**
   ```bash
   git add {docroot}/modules/custom/{module}/
   git commit -m "fix({module}): update deprecated APIs for Drupal {target_major}"
   ```

Principios para aplicar correcciones:

- **Una API a la vez** — no mezcles reemplazos diferentes en la misma edición
- **Preserva la lógica** — si el código original tiene error handling, mantenlo
- **No refactorices** — solo reemplaza lo que drupal-check señaló, no "mejores" el código
- **Si no estás seguro** — marca como `needs_manual_review` y explica al usuario por qué

### Fase 4: Verificación post-fix

Tras aplicar todas las correcciones, re-escanea para verificar:

```bash
bash "$SKILL_DIR/scripts/paso-06c-custom-code-check.sh"
```

Si quedan errores:

- Diferencia los errores: ¿son nuevos o los mismos que no se pudieron corregir?
- Los que persisten → marcar como `needs_manual_review` con explicación
- Los nuevos → corregir (posible regresión de un fix anterior)

### Fase 5: Warnings (opcionales)

Los warnings (ej: hooks procedurales que migran a OOP en D11) son informativos.
Presenta la lista al usuario y pregunta:

```
⚠️  {N} warnings opcionales (hooks procedurales → OOP Hook attributes)

Estos no bloquean el upgrade pero son recomendables para D11.
¿Quieres que los corrija también? (sí/no/seleccionar)
```

Si el usuario acepta, aplica de la misma manera (fase 3-4 para warnings).

## Ejecución independiente

Este agente puede ejecutarse fuera del pipeline, por ejemplo para auditorías
periódicas. Cuando se ejecuta de forma independiente:

1. Ejecuta `paso-06c-custom-code-check.sh` directamente
2. Si no hay datos de telemetría, el script obtiene la versión actual vía Drush
3. Puedes pasar `--module foo_bar` para escanear un solo módulo

```bash
bash "$SKILL_DIR/scripts/paso-06c-custom-code-check.sh" --module mi_modulo
```

## Report-Back

En caso de éxito:

```
COMPLETED
- Escaneados: N extensiones (M módulos, T temas)
- Errores corregidos: X / Y
- Warnings resueltos: W (de Z)
- Manual review: K hallazgos requieren revisión manual
- Commits: C
```

En caso de errores que no se pudieron corregir:

```
COMPLETED_WITH_WARNINGS
- Escaneados: N extensiones
- Errores corregidos: X / Y
- Sin corregir: [lista de ficheros y razón]
- Acción requerida: revisión manual antes de aprobar core
```

En caso de fallo del escaneo:

```
FAILED
Error: [drupal-check no disponible / DDEV no activo / etc.]
Instrucciones: [cómo resolver]
```
