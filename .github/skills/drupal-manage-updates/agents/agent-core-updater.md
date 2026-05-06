---
name: agent-core-updater
description: 'Updates Drupal core with a mandatory dry-run conflict check, user approval gate, updb and config export.'
---

# Agent Core Updater — Actualización de Core con Dry-Run Obligatorio (F5)

> **Rutas:** Scripts en `$SKILL_DIR/scripts/`. Informes en `reports/drupal-update/`.
> **🚨 `-W` (--with-all-dependencies) SOLO está permitido en este agente para actualizaciones de core.**
> **REGLA:** SIEMPRE usa `ddev composer`, `ddev drush`, NUNCA sin `ddev`.

## Paso 1: Gate de checkpoint

Antes de continuar, muestra el estado y solicita aprobación explícita:

```
🔴 CHECKPOINT — Actualización de Core

Drupal core actual:   {current_version}
Drupal core objetivo: {target_version}

Esta operación actualiza el core de Drupal usando -W (--with-all-dependencies).
Se ejecutará un dry-run obligatorio primero para detectar conflictos antes de cualquier cambio.

Escribe "aprobar core" para continuar.
```

Espera a que el usuario escriba exactamente "aprobar core" antes de continuar.

## Paso 2: F5 — Dry-run previo al core obligatorio

Ejecuta el dry-run ANTES de cualquier cambio real:

```bash
ddev composer update drupal/core-* drupal/core-composer-scaffold drupal/core-project-message -W --dry-run
```

### Analiza la salida del dry-run

Busca:

- Conflictos de dependencias (el paquete X requiere la versión Y pero otro paquete requiere >Y)
- Patches que no pueden aplicarse a la nueva versión de core
- Downgrades inesperados de módulos contrib
- Avisos de incompatibilidad

Si se detectan conflictos:

- Presenta el diagnóstico detallado usando `references/troubleshooting.md`
- NO continúes con la actualización real
- Reporta FAILED con instrucciones claras para resolver cada conflicto

Si el dry-run está limpio → continuar al Paso 3.

## Paso 3: Actualización de core

> ⚠️ Nota: `-W` se usa exclusivamente aquí. Ningún otro agente de esta skill usa este flag.

```bash
ddev composer update drupal/core-* drupal/core-composer-scaffold drupal/core-project-message -W
```

### Modo dry-run global (F8)

Si `$dry_run == true`: ejecuta solo el Paso 2 (dry-run). NO ejecutes este paso.
Reporta el resultado como simulación.

## Paso 4: Pasos post-core

Ejecuta en orden:

```bash
ddev drush updb -y
ddev drush cex -y
git add -A && git commit -m "feat: update Drupal core to {target_version}"
bash "$SKILL_DIR/scripts/paso-02-snapshot.sh" post-core
```

## Paso 5: Módulos target-only

Los módulos `target-only` (categorizados como `fase2_target_only` en `paso-05-compatibilidad.json`)
solo tienen release compatible con la versión objetivo del core — por eso no podían actualizarse
en Stage 3. Ahora que el core ya está actualizado, instálalos:

```bash
bash "$SKILL_DIR/scripts/paso-06-actualizar-modulo.sh" --auto --batch-size {batch_size} --group target
```

Aplica el mismo algoritmo de batch adaptativo y gestión de fallos que en Stage 3. Si no hay
módulos en el grupo `target`, el script lo indicará y continúas. Si `$dry_run == true`, pasa
`--dry-run` al script.

## Report-Back

En caso de éxito:

```
COMPLETED
- Core actualizado: {old_version} → {target_version}
- Actualizaciones de base de datos: N aplicadas
- Configuración exportada y commiteada
- Snapshot: post-core-[id]
```

En caso de conflicto detectado en el dry-run:

```
FAILED
Error: el dry-run detectó conflictos — [detalles]
Instrucciones: [cómo resolver, consultando troubleshooting.md]
```
