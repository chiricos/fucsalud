# Contrato del Orquestador — drupal-manage-updates

Reglas inmutables que el orquestador (SKILL.md) DEBE cumplir en todo momento.
No modificar sin actualizar también `docs/state-machine.md`.

---

## Reglas inmutables

### 1. Nunca ejecuta scripts directamente

El orquestador **no** invoca `bash scripts/*.sh` por sí mismo.
Toda ejecución de scripts ocurre dentro de los sub-agentes especializados.

**Correcto**: despachar `agent-analysis` → el sub-agente ejecuta `paso-01-telemetria.sh`
**Incorrecto**: el orquestador ejecuta `bash "$SKILL_DIR/scripts/paso-01-telemetria.sh"` directamente

---

### 1b. Todos los scripts se ejecutan en primer plano (foreground)

Ningún sub-agente lanza scripts en background. Todos los `bash scripts/*.sh` deben ejecutarse
de forma **bloqueante** (foreground), esperando a que el proceso termine antes de leer su
fichero de salida JSON.

**Motivo**: los scripts escriben su resultado en un fichero JSON que el agente lee
inmediatamente después. Si el script sigue corriendo en background cuando se lee el fichero,
el resultado estará incompleto o vacío.

**Correcto**: ejecutar `bash health-check.sh` y esperar a que termine, luego leer `health-check.json`
**Incorrecto**: lanzar `bash health-check.sh` en background y leer `health-check.json` de inmediato

---

### 2. Nunca carga agents/_.md ni references/_ en su propio contexto

El orquestador conoce los nombres de los sub-agentes y las referencias, pero no los lee.
Cada sub-agente carga únicamente los documentos que necesita (ver tabla de carga progresiva en SKILL.md).

**Correcto**: `runSubagent("agent-planner", ...)` con referencia a `incremental-strategy.md`
**Incorrecto**: el orquestador lee `agents/agent-planner.md` antes de despacharlo

---

### 3. Re-detecta estado después de cada sub-agente

Después de que cualquier sub-agente termina (éxito o fallo), el orquestador
re-ejecuta la detección completa de los 12 checkpoint flags antes de decidir
el siguiente stage.

No asume que el flag cambió — lo verifica leyendo el fichero JSON.

---

### 4. En FAILED: reporta, no reintenta

Si un sub-agente devuelve FAILED o si un gate de salida no se cumple:

1. Mostrar el error al usuario con contexto (qué stage falló, qué fichero faltó)
2. Presentar opciones claras
3. **No reintentar automáticamente** con flags diferentes
4. **No continuar al siguiente stage** hasta que el usuario decida

---

### 5. Informa al usuario antes de cada stage

Antes de despachar cualquier sub-agente, el orquestador presenta:

- Qué sub-agente se va a invocar y para qué
- Estimación de tiempo del stage
- Si hay aprobación requerida, solicitarla explícitamente

---

### 6. Propaga --dry-run a todos los sub-agentes

Si el usuario invocó la skill con `--dry-run`, ese flag debe pasarse a cada
sub-agente y a cada script. Ningún stage ejecuta cambios destructivos en dry-run.

---

### 7. VRT es opt-in por fase, nunca bloqueante por si mismo

Si `VRT_DISPONIBLE = true`, el orquestador pregunta al usuario **antes de cada stage
VRT de forma independiente** (stages 1.5, 3.5 y 9). Cada fase es una decisión separada.

- Respuesta afirmativa en un stage → se despacha `agent-vrt` para ese stage
- Respuesta negativa en un stage → se escribe N/A como flag de ese stage y se continúa
- Flag `--no-vrt` → todos los stages VRT se saltan sin preguntar
- Si `VRT_DISPONIBLE = false` → todos los stages VRT se saltan sin preguntar

Los stages VRT solo bloquean si `regressions_new > 0`.
Si VRT falla por prerequisitos → continuar sin VRT.

---

### 8. Deploy Safety: nunca eliminar paquetes de composer sin runbook de producción

Si cualquier sub-agente va a ejecutar `composer remove <drupal/modulo>` sobre un módulo
que sigue **activo en la base de datos de producción**, el orquestador debe:

1. Advertir al usuario **antes de ejecutar** el remove:

   > ⚠️ Eliminar este paquete rompe el despliegue en producción si el módulo sigue
   > activo en BD. En producción, con el código antiguo todavía activo, ejecutar:
   > `drush pm:uninstall {modulo} -y`
   > Solo después desplegar el nuevo código.

2. Incluir el runbook en el **commit message** (campo `DEPLOY NOTE:`).
3. Incluir el runbook en el **report JSON final** del sub-agente.
4. Esperar confirmación explícita del usuario antes de proceder con el remove.

**Motivo:** `composer remove` elimina los archivos PHP del módulo del disco. Al desplegar,
`composer install` no los restaura (ya no están en composer.json). Si la base de datos
de producción aún tiene el módulo habilitado, `drush cim` o `drush updb` fallan porque
Drupal necesita los archivos para ejecutar los hooks de desinstalación.

---

## Invariantes de Estado

Estas condiciones siempre deben ser verdaderas:

1. `CORE_OK = true` implica `CHECKPOINT_OK = true`
2. `CHECKPOINT_OK = true` implica `MODULES_OK = true`
3. `MODULES_OK = true` implica `PLAN_APPROVED = true`
4. `PLAN_APPROVED = true` implica `ANALYSIS_OK = true`
5. `ANALYSIS_OK = true` implica `PREFLIGHT_OK = true` y `SNAPSHOT_OK = true`

Si alguna invariante se rompe (ej: `CORE_OK = true` pero `CHECKPOINT_OK = false`),
es señal de estado corrupto. Mostrar advertencia al usuario y pedir confirmación antes de continuar.

---

## Referencia

- Dispatch table completa: `docs/state-machine.md`
- Tabla de carga progresiva: `SKILL.md` → sección "Tabla de carga progresiva"
- Sub-agentes disponibles: `agents/README.md`
