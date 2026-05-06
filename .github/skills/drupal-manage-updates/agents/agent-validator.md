---
name: agent-validator
description: 'Runs post-update health check, security audit and config diff; offers total or partial rollback on failure.'
---

# Agent Validator — Validación Post-Actualización con Rollback Granular (F6)

> **Rutas:** Scripts en `$SKILL_DIR/scripts/`. Informes en `reports/drupal-update/`.
> **🚨 SOLO ejecuta los scripts listados a continuación. NO inventes comandos propios.**
> **REGLA:** SIEMPRE usa `ddev composer`, `ddev drush`, NUNCA sin `ddev`.

## Paso 1: Health Check

> **⚠️ SOLO EN PRIMER PLANO (FOREGROUND)** — Ejecuta este script de forma síncrona (bloqueante). Nunca lo lances como proceso en background. El siguiente paso lee `health-check.json` inmediatamente después; si el script aún está en ejecución, el fichero estará incompleto o ausente.

```bash
bash "$SKILL_DIR/scripts/health-check.sh"
```

Espera a que el script termine completamente antes de continuar.

Lee el resultado de `health-check.json`: PASS / WARN / FAIL.

## Paso 2: Auditoría de seguridad

Ejecuta `ddev composer audit` y `ddev drush pm:security --format=json`. Compara el número de vulnerabilidades antes (baseline de paso-03) vs. después.

## Paso 3: Exportación de configuración

Tras el pipeline de actualizaciones, la base de datos puede contener cambios de
configuración que aún no se han exportado a disco. Este paso es **obligatorio**.

```bash
ddev drush updb -y        # asegurar que no quedan updates de BD pendientes
ddev drush cr              # reconstruir cachés
ddev drush cex -y          # exportar TODA la configuración activa
```

Si la exportación genera cambios (git detecta ficheros modificados):

```bash
git add -A && git commit -m "chore: export configuration after update pipeline"
```

Verifica que la configuración queda sincronizada:

```bash
ddev drush config:status --format=json
```

Si devuelve `[]` (array vacío) → la config está en sync. Continúa al Paso 4.
Si aún muestra diferencias → reporta al usuario (posible override activo o config split).

## F6 — Opciones de rollback (en caso de FAIL)

Si el resultado del health check es FAIL, presenta 3 opciones:

```
❌ Validación fallida. Opciones de rollback:

a) Rollback TOTAL — Restaurar el estado completo previo a la actualización:
   bash scripts/rollback.sh

b) Rollback PARCIAL — Volver a un commit específico:
   bash scripts/rollback.sh --to-commit <hash>
   (Si no conoces el hash, ejecuta: git log --oneline -10)

c) Continuar investigando — Mantener el estado actual y diagnosticar más
   (Usar si el problema es un WARN, no un FAIL crítico)

Tu elección (a/b/c):
```

Para la opción b: solicita el hash de commit al usuario y luego ejecuta:

```bash
git log --oneline -10   # mostrar commits recientes si el usuario necesita orientación
bash scripts/rollback.sh --to-commit <provided-hash>
```

## Paso 4: Informe final (en caso de PASS o WARN)

Genera `reports/drupal-update/resumen-final.json` y presenta un resumen:
Versión Drupal antes→después, módulos actualizados/fallidos, vulnerabilidades de seguridad antes→después, tiempo total, commits realizados, elementos manuales pendientes, nombre del snapshot de rollback.

## Report-Back

```
COMPLETED — estado_global: success|partial
Informe final: reports/drupal-update/resumen-final.json
```

O:

```
FAILED — rollback ejecutado: total|partial|investigation-pending
```
