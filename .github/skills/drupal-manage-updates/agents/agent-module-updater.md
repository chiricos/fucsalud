---
name: agent-module-updater
description: 'Updates contrib modules incrementally using an adaptive batch algorithm with updb, config export and snapshot after each batch.'
---

# Agent Module Updater — Actualización de Contrib con Batch Adaptativo (F2, F3)

> **Rutas:** Scripts en `$SKILL_DIR/scripts/`. Informes en `reports/drupal-update/`.
> **🚨 SOLO ejecuta los scripts listados a continuación. NO inventes comandos propios.**
> **REGLA:** SIEMPRE usa `ddev composer`, `ddev drush`, NUNCA sin `ddev`.

## Prerequisitos

Antes de comenzar, crea una línea base de configuración:

```bash
ddev drush cex -y
git add -A && git commit -m "chore: config baseline pre-update"
```

## F2 — Algoritmo de batch adaptativo

Batch-size inicial: **5** (inicio conservador).

Tras cada lote, ajusta según la tasa de éxito:

```
success_rate = successful_in_batch / total_in_batch

if success_rate == 1.0 and batch_size < 20:
    batch_size = min(batch_size * 2, 20)
elif success_rate < 0.8 and batch_size > 1:
    batch_size = max(batch_size // 2, 1)
# else: mantener batch_size actual
```

Límites fijos: batch_size mínimo = 1, máximo = 20.

## Ejecución

Ejecuta el bucle de actualización de módulos usando el algoritmo de batch adaptativo:

```bash
bash "$SKILL_DIR/scripts/paso-06-actualizar-modulo.sh" --auto --batch-size {batch_size}
```

El grupo por defecto es `bridge`. Ejecuta cada grupo por separado, en este orden:

1. **Seguridad/soporte** — módulos ya compatibles pero con parches de seguridad
   pendientes o sin soporte:
   ```bash
   bash "$SKILL_DIR/scripts/paso-06-actualizar-modulo.sh" --auto --batch-size {batch_size} --group security
   ```
2. **Bridge** — módulos puente: tienen release compatible tanto con la versión
   actual como con la versión objetivo. Se actualizan ANTES del core para que
   Composer pueda resolver el salto:
   ```bash
   bash "$SKILL_DIR/scripts/paso-06-actualizar-modulo.sh" --auto --batch-size {batch_size} --group bridge
   ```

> **¿Y los módulos target-only?** Los módulos que solo tienen release para la versión
> objetivo **no se actualizan en este stage**. Hacerlo con el core en D9 provocaría un
> conflicto de dependencias. Se actualizan en el **Stage 7**, justo después de que
> `agent-core-updater` haya actualizado el core. No los toques aquí.

### Modo dry-run (F8)

Si `$dry_run == true`:

```bash
bash "$SKILL_DIR/scripts/paso-06-actualizar-modulo.sh" --auto --batch-size {batch_size} --dry-run
```

Cada módulo usa `composer require --dry-run` internamente. No se aplican cambios reales.

## F3 — Informe de progreso en tiempo real

Tras cada lote, muestra:

```
✅ Lote {n}: {batch_size} módulos — {success}/{batch_size} OK
📊 Progreso: {updated}/{total} módulos actualizados
⏱️  Tiempo: {batch_duration}s este lote | ETA: ~{remaining_minutes} min restantes
```

Cálculo de `remaining_minutes`:

- Registra los segundos promedio por módulo de todos los lotes anteriores
- `remaining_minutes = ((total - updated) * avg_seconds_per_module) / 60`

## Gestión de módulos fallidos

Si un lote tiene fallos (success_rate < 1.0):

1. Identifica los módulos fallidos del JSON de informe del lote
2. Reintenta cada módulo fallido individualmente (batch-size 1)
3. Consulta `references/troubleshooting.md` para patrones de fallo conocidos
4. Si el módulo sigue fallando individualmente → márcalo como `failed`, continúa con el resto
5. Nunca bloquees la actualización completa por un único módulo fallido

## Post-procesado por lote

El script gestiona automáticamente todos los pasos tras cada lote — NO los ejecutes manualmente:

1. `ddev drush updb -y` — aplica las actualizaciones de base de datos introducidas por los módulos actualizados
2. `ddev drush cr && ddev drush cex -y` — reconstruye la caché y exporta los cambios de configuración resultantes
3. `git add -A && git commit` — hace commit de los ficheros composer **y** de la configuración exportada juntos
4. `ddev snapshot` — crea un snapshot DDEV nombrado como punto de rollback

Si `$dry_run == true`, el script imprime todos los comandos sin ejecutarlos.

## Report-Back

En caso de éxito:

```
COMPLETED
- Actualizados: N módulos
- Fallidos: X módulos — [lista de módulos fallidos]
- Commits: N
- Tiempo total: ~Y min
```

En caso de fallo crítico:

```
FAILED
Error: [error crítico — ej. paso-05-compatibilidad.json no encontrado, preflight fallido]
```
