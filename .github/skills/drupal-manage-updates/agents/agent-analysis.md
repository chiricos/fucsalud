---
name: agent-analysis
description: 'Performs environment telemetry, safety snapshot, version targeting, patch inventory, compatibility analysis and deprecated module detection.'
---

# Agent Analysis — Reconocimiento del Entorno + Detección de Deprecated

> **Rutas:** Scripts en `$SKILL_DIR/scripts/`. Informes en `reports/drupal-update/`.
> **🚨 SOLO ejecuta los scripts listados a continuación. NO inventes comandos propios.**
> **REGLA:** SIEMPRE usa `ddev composer`, `ddev drush`, NUNCA sin `ddev`.

## F1 — Verificación de conectividad

Antes de cualquier otra acción, verifica la conectividad a drupal.org:

```bash
curl -sf --max-time 10 https://www.drupal.org > /dev/null
```

Si falla:

```
FAILED
Error: Cannot reach drupal.org. Check your internet connection and retry.
Suggestion: verify proxy settings, DNS, or try again in a few minutes.
```

## Ejecución

Ejecuta los scripts en orden. Detente inmediatamente ante cualquier fallo BLOQUEANTE.

### Paso 1: Telemetría

`bash "$SKILL_DIR/scripts/paso-01-telemetria.sh"`

### Paso 2: Snapshot de seguridad

`bash "$SKILL_DIR/scripts/paso-02-snapshot.sh"` — Si falla → DETENER INMEDIATAMENTE.

### Paso 3: Versión objetivo

**Antes de ejecutar**, pregunta al usuario qué tipo de actualización quiere:

```
🎯 TIPO DE ACTUALIZACIÓN

El sitio está en Drupal {current_version} ({current_major}).
¿Qué tipo de actualización quieres realizar?

  a) Minor/patch — Actualizar dentro de D{current_major} (ej: D10.3 → D10.4)
  b) Salto mayor — Saltar a D{next_major} (ej: D10 → D11)

Tu elección (a/b):
```

Según la respuesta:

- **a) Minor/patch:**
  ```bash
  bash "$SKILL_DIR/scripts/paso-03-version-objetivo.sh"
  ```
- **b) Salto mayor:**
  ```bash
  bash "$SKILL_DIR/scripts/paso-03-version-objetivo.sh" --major-jump
  ```

Si el usuario ya indicó su intención al invocar la skill (ej: "actualizar a D11",
"quiero Drupal 11"), pasa `--major-jump` directamente sin preguntar.

Si el script reporta `READY_FOR_MAJOR_JUMP: false` con `--major-jump`, informa
al usuario que debe actualizar primero a la última minor de la versión actual.
Ofrece la opción `--force-major` solo si el usuario insiste (y advierte del riesgo).

### Paso 4: Inventario de patches y código custom

`bash "$SKILL_DIR/scripts/paso-04-inventario.sh"`

### Paso 5: Análisis de compatibilidad

`bash "$SKILL_DIR/scripts/paso-05-analisis-compatibilidad.sh"`

### Paso 6b: Detección de deprecated — F4 (solo detección, sin corrección)

```bash
bash "$SKILL_DIR/scripts/paso-06b-deprecated.sh" --detect-only
```

Genera `reports/drupal-update/paso-06b-deprecated.json` sin aplicar correcciones.
Los módulos deprecated se conocen desde el inicio del pipeline.

## F3 — Estimación de tiempo

Tras el paso 5: `eta_minutes = total_modules * 1.5`

Presenta: `ETA: ~{eta_minutes} min (~2 min/módulo primer lote, ~1 min/módulo siguientes)`

## Modo dry-run (F8)

Todos los pasos son de solo lectura — ejecútalos normalmente. `$dry_run` no tiene efecto aquí.

## Report-Back

En caso de éxito:

```
COMPLETED
- Pending modules (compat): N
- Pending modules (security/support): M
- Deprecated detected: X (CKEditor: yes/no)
- ETA update: ~Y minutes
- Snapshot: [snapshot-id]
```

En caso de fallo crítico:

```
FAILED
Error: [step that failed] — [error message]
```
