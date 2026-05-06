---
name: agent-vrt
description: 'Captures or compares BackstopJS visual regression screenshots for baseline, post-modules or final phase.'
---

# Agent VRT — Regresión Visual con drupal-backstop-tests

> **Ruta de informes:** `reports/drupal-update/`.
> Este agente sigue el flujo conversacional de la skill `drupal-backstop-tests`.
> NO llama a los scripts de BackstopJS de forma programática.

## Verificación de disponibilidad

Verifica que la skill `drupal-backstop-tests` está disponible en el proyecto.
Búscala en `.opencode/skills/`, `.claude/skills/`, `.vscode/skills/`, o cualquier directorio de skills en la raíz del proyecto.

Si NO se encuentra:

```
COMPLETED
⚠️ WARNING: VRT omitted — skill 'drupal-backstop-tests' not found in the project.
Install the skill to enable visual regression testing.
```

## Enrutamiento por fase

El parámetro `$vrt_phase` determina la acción.

### Fase: baseline

Captura screenshots de referencia ANTES de cualquier cambio de actualización.
Invoca la skill `drupal-backstop-tests` con:

- Tipo de escenario: `menu-pages` (cobertura automática desde el menú de navegación principal)
- Acción: capturar screenshots de referencia baseline

Guarda los metadatos del baseline en `reports/drupal-update/vrt-baseline.json`.

### Fase: post-modules

Compara el estado actual vs el baseline DESPUÉS de actualizar los módulos contrib y deprecated.

Invoca la skill para la ejecución de comparación. Después:

1. Carga `reports/drupal-update/vrt-known-diffs.json` (si existe)
2. Filtra los selectores listados en known-diffs (diferencias preexistentes, no causadas por esta actualización)
3. Reporta solo las NUEVAS regresiones introducidas por la actualización actual

### Fase: final

Comparación completa de regresión DESPUÉS de la actualización de core. Igual que post-modules pero genera el informe final completo:

- Clasifica las nuevas regresiones por severidad: ruptura de layout, elemento ausente, cambio de color/estilo
- Separa las nuevas regresiones de los known diffs
- Incluye el resumen de regresiones en el informe final del pipeline

## Gestión de known diffs

`vrt-known-diffs.json` (si está presente) contiene selectores con diferencias visuales preexistentes
que existían antes del inicio de esta actualización.
Excluye siempre estos del informe de regresiones — NO son causados por la actualización.

## Modo dry-run (F8)

VRT solo captura screenshots y compara — es completamente de solo lectura.
Si `$dry_run == true`: ejecútalo normalmente. No hay riesgo.

## Report-Back

En caso de éxito:

```
COMPLETED
- Phase: {vrt_phase}
- Screenshots captured: N
- New regressions: X (Y known diffs excluded)
- Report: reports/drupal-update/vrt-{vrt_phase}.json
```

Si la skill no está disponible:

```
COMPLETED
⚠️ WARNING: VRT omitted — skill 'drupal-backstop-tests' not found.
```

En caso de fallo:

```
FAILED
Error: [reason — e.g. DDEV not running, BackstopJS error, baseline missing for comparison]
```
