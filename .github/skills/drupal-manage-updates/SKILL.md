---
name: drupal-manage-updates
description: |
  Manages Drupal updates and upgrades for sites running on DDEV. Use when the
  user needs to: update between major Drupal versions (9→10, 10→11), update to
  the latest stable release, apply security patches, resolve deprecated modules
  before a version upgrade, plan or simulate the upgrade path, migrate
  CKEditor 4→5, update outdated core/contrib packages, or resume an interrupted
  update. Not applicable for: new Drupal installations, custom module
  development, environments without DDEV, or other package managers (npm, yarn).

  Use also for: Drupal upgrade path, update Drupal, security release Drupal,
  composer outdated drupal, CKEditor 5 migration, resume Drupal update.
allowed-tools:
  - run_in_terminal
  - read_file
  - create_file
  - replace_string_in_file
  - multi_replace_string_in_file
  - list_dir
  - file_search
  - grep_search
  - semantic_search
  - get_errors
---

# Drupal Update Manager — Orquestador

## Regla principal

**Ante cualquier error o bloqueo: PARAR → REPORTAR → PREGUNTAR al usuario.**

No improvises soluciones. No reintentas con flags diferentes. No ejecutes
comandos fuera de los scripts. Presenta el diagnóstico y las opciones al
usuario. Él decide.

## Reglas técnicas

1. **Solo scripts** — ejecuta los scripts de `$SKILL_DIR/scripts/`, no comandos sueltos
2. **Todo vía DDEV** — nunca `composer` o `drush` sin prefijo `ddev`
3. **Nunca `-W`** — prohibido `--with-all-dependencies` y `composer update`
4. **Nunca `composer remove`** sin aprobación del usuario
5. **Pregunta antes de actuar** en cualquier situación no prevista

## Clasificación de módulos contrib

Durante un salto de versión mayor (D9→D10, D10→D11), cada módulo contrib cae
en una de estas categorías — el pipeline las trata en momentos distintos:

| Categoría       | Definición                                                                                                               | Cuándo se actualiza                                                                                 |
| --------------- | ------------------------------------------------------------------------------------------------------------------------ | --------------------------------------------------------------------------------------------------- |
| **bridge**      | Tiene release compatible con la versión **actual Y la objetivo** (`^9 \|\| ^10`). Se puede instalar con el core antiguo. | Stage 3, **antes** de subir el core. Permite que Composer resuelva el salto de core sin conflictos. |
| **target-only** | Solo tiene release para la versión **objetivo** (`^10`). Instalarlo con el core antiguo rompería Composer.               | Stage 7, **justo después** de subir el core.                                                        |
| **security**    | Ya es compatible con ambas versiones pero tiene un parche de seguridad pendiente o está sin soporte.                     | Stage 3, antes de bridge.                                                                           |
| **manual**      | No tiene release para la versión objetivo. Requiere decisión humana (desinstalar, buscar alternativa, etc.).             | No se actualiza automáticamente.                                                                    |

El orden bridge-antes-del-core / target-only-después-del-core no es opcional:
invertirlo provoca conflictos de dependencias irresolubles en Composer.

## Criterios de selección de módulos

NO se actualizan todos los módulos del proyecto. Solo se actualizan los que
cumplen **al menos uno** de estos criterios:

1. **Compatibilidad con versión mayor objetivo** — el módulo necesita
   actualizarse para funcionar con la siguiente versión de Drupal (categorías
   bridge y target-only, ver tabla anterior)
2. **Parche de seguridad pendiente** — existe un release de seguridad más
   reciente que la versión instalada (categoría security)
3. **Versión sin soporte** — la versión instalada está marcada como
   unsupported, abandoned u obsolete (categoría security)

> **Nota sobre `security_covered`:** El campo `security_covered: false` en la
> API de drupal.org indica que el proyecto **no está inscrito en el programa
> Security Advisory de Drupal**, no que tenga una vulnerabilidad activa.
> Se muestra como dato informativo en el plan pero **no obliga a actualizar**.

Los módulos compatibles, con soporte activo y sin parches de seguridad
pendientes se mantienen en su versión actual.

## Inicialización

```bash
export SKILL_DIR="$(cd "$(dirname "$0")/.." && pwd)"   # raíz de la skill
REPORTS_DIR="$PROJECT_ROOT/reports/drupal-update"
```

> **Importante:** usar siempre `export SKILL_DIR=...` y nunca asignación inline
> (`SKILL_DIR=value bash script.sh`). Los terminales de algunos entornos de agente
> (VS Code/Copilot) simplifican los comandos y eliminan las asignaciones inline.

Al iniciar, leer `$REPORTS_DIR/progress.json`:

- Si existe → informar al usuario en qué fase está y qué falta
- Si no existe → iniciar desde Stage 1

## Checkpoint Flags

Los flags se detectan comprobando existencia y contenido de ficheros JSON:

| Flag              | Fuente de verdad                                                                 |
| ----------------- | -------------------------------------------------------------------------------- |
| `PREFLIGHT_OK`    | `paso-01-telemetria.json` existe                                                 |
| `SNAPSHOT_OK`     | `paso-02-snapshot.json` existe                                                   |
| `BASELINE_VRT_OK` | `vrt-baseline.json` existe (o N/A si usuario declinó o `VRT_DISPONIBLE = false`) |
| `ANALYSIS_OK`     | `paso-05-compatibilidad.json` existe                                             |
| `PLAN_APPROVED`   | `progress.json` → campo `plan_approved == true`                                  |
| `MODULES_OK`      | `paso-06-reporte.md` existe sin líneas "pending"                                 |
| `VRT_POST_OK`     | `vrt-post-modules.json` → campo `status: "PASS"` (o N/A si usuario declinó)      |
| `DEPRECATED_OK`   | `paso-06b-deprecated.json` → campo `status: "resolved"`                          |
| `CKEDITOR_OK`     | `paso-06b-ckeditor.json` existe (o N/A si no aplica)                             |
| `CUSTOM_CODE_OK`  | `paso-06c-custom-code.json` → campo `status != "needs_fix"` (o `clean`)          |
| `CHECKPOINT_OK`   | `progress.json` → campo `checkpoint_approved == true`                            |
| `CORE_OK`         | `progress.json` → campo `core_status: "completed"`                               |
| `VALIDATED`       | `health-check.json` → campo `status: "PASS"`                                     |
| `VRT_FINAL_OK`    | `vrt-final.json` existe (o N/A si usuario declinó)                               |

> Validar la estructura JSON mínima, no solo la existencia del fichero.
> `N/A` en `progress.json` equivale a flag activo: el stage fue decidido (ejecutado o saltado) y no debe re-ejecutarse.

## Prerequisito VRT

Detectar disponibilidad antes de Stages 1.5, 3.5 y 9:

```
VRT_DISPONIBLE = skill drupal-backstop-tests disponible
             AND ddev-backstopjs addon instalado
             AND DDEV corriendo
```

Si alguna condición falla → `VRT_DISPONIBLE = false` → saltar stages VRT con WARNING.

`stage_file_proxy`: recomendado para sincronizar imágenes PROD→LOCAL; si falta →
WARNING al usuario, NO bloquea `VRT_DISPONIBLE`.

Si `VRT_DISPONIBLE = true`, el orquestador pregunta al usuario de forma
**independiente antes de cada stage VRT** (1.5, 3.5 y 9). Cada fase es una
decisión separada: el usuario puede ejecutar el baseline, saltarse el
post-módulos, ejecutar el final, o cualquier combinación.

Si el usuario declina un stage → escribir el flag N/A en `progress.json`
y avanzar al siguiente stage sin VRT.

- Flag `--no-vrt` → salta todos los stages VRT sin preguntar
- Si `VRT_DISPONIBLE = false` → salta todos los stages VRT sin preguntar

## Dispatch Table

Re-ejecutar detección de flags después de cada sub-agente.

| Stage   | Condición de entrada                                  | Sub-agente / Acción        | Gate de salida                                 |
| ------- | ----------------------------------------------------- | -------------------------- | ---------------------------------------------- |
| **1**   | `!PREFLIGHT_OK OR !SNAPSHOT_OK`                       | `agent-analysis`           | `PREFLIGHT_OK AND SNAPSHOT_OK AND ANALYSIS_OK` |
| **1.5** | `ANALYSIS_OK AND VRT_DISPONIBLE AND !BASELINE_VRT_OK` | `agent-vrt` (baseline)     | `BASELINE_VRT_OK` (opcional)                   |
| **2**   | `ANALYSIS_OK AND !PLAN_APPROVED`                      | `agent-planner`            | `PLAN_APPROVED` (requiere aprobación usuario)  |
| **3**   | `PLAN_APPROVED AND !MODULES_OK`                       | `agent-module-updater`     | `MODULES_OK`                                   |
| **3.5** | `MODULES_OK AND VRT_DISPONIBLE AND !VRT_POST_OK`      | `agent-vrt` (post-modules) | `VRT_POST_OK` (opcional)                       |
| **4**   | `MODULES_OK AND !DEPRECATED_OK`                       | `agent-deprecated-handler` | `DEPRECATED_OK`                                |
| **5**   | `DEPRECATED_OK AND !CKEDITOR_OK`                      | `agent-ckeditor-migrator`  | `CKEDITOR_OK` (o N/A)                          |
| **5.5** | `CKEDITOR_OK AND !CUSTOM_CODE_OK`                     | `agent-custom-code-fixer`  | `CUSTOM_CODE_OK`                               |
| **6**   | `CUSTOM_CODE_OK AND !CHECKPOINT_OK`                   | Checkpoint (orquestador)   | `CHECKPOINT_OK` (requiere aprobación usuario)  |
| **7**   | `CHECKPOINT_OK AND !CORE_OK`                          | `agent-core-updater`       | `CORE_OK` (requiere aprobación usuario)        |
| **8**   | `CORE_OK AND !VALIDATED`                              | `agent-validator`          | `VALIDATED`                                    |
| **9**   | `VALIDATED AND VRT_DISPONIBLE AND !VRT_FINAL_OK`      | `agent-vrt` (final)        | `VRT_FINAL_OK` (opcional)                      |
| **10**  | `VALIDATED AND (VRT_FINAL_OK OR !VRT_DISPONIBLE)`     | Cleanup (orquestador)      | —                                              |

Antes de cada fase informar al usuario: sub-agente que se invocará y estimación de tiempo.

## Modo dry-run

Flag global `--dry-run` propagado a todos los sub-agentes y scripts:

```bash
bash "$SKILL_DIR/scripts/<script>.sh" --dry-run
```

En modo dry-run: mostrar plan de acción sin ejecutar cambios destructivos.

## Protocolo UI Handoff

Algunas operaciones no pueden automatizarse y requieren que el usuario actúe en
el navegador. Cuando un sub-agente necesita que el usuario realice una acción en
la UI de Drupal, usa este formato estándar:

```
📋 UI HANDOFF — {descripción de la tarea}

Ve a: {URL exacta}

Pasos:
1. {paso concreto}
2. {paso concreto}
3. {paso concreto}

Cuando termines, indícame:
  a) Si completó correctamente
  b) {qué información reportar al agente — mensajes, warnings, errores}
```

**Reglas del protocolo:**

- El agente **espera respuesta del usuario** antes de continuar al siguiente paso.
- Si el usuario reporta un error inesperado → PARAR → diagnosticar → presentar opciones.
- Describir qué resultados/warnings son esperados versus cuáles requieren intervención.
- Si hay múltiples iteraciones (ej: migrar varios formatos), repetir el handoff una vez
  por cada acción, en lugar de mezclar instrucciones para todas a la vez.

## Flag --no-vrt

```
--no-vrt    Desactiva todos los stages VRT (1.5, 3.5, 9) sin preguntar.
            Equivalente a declinar cada stage VRT individualmente.
```

Usar si BackstopJS ralentiza el pipeline o en actualizaciones no-visuales.

## Flag --major-jump

```
--major-jump    Indica que el usuario quiere un salto de versión mayor (D9→D10, D10→D11).
                Sin este flag, paso-03 solo actualiza dentro de la versión mayor actual.
```

El agente de análisis (Stage 1) **debe preguntar al usuario** qué tipo de
actualización quiere antes de ejecutar paso-03, a menos que la intención ya
sea clara por el mensaje del usuario (ej: "actualizar a D11" → `--major-jump`).

Si el usuario invoca la skill diciendo "actualizar a Drupal 11", "saltar a D11",
"upgrade a D11", o cualquier referencia a una versión mayor diferente a la actual,
el orquestador debe propagar `--major-jump` al Stage 1.

## Dispatch: cómo invocar un sub-agente

"Despachar a un sub-agente" **no** significa lanzar un proceso separado ni usar
herramientas de sub-agente (como `runSubagent` o `Agent`). Los sub-agentes son
**ficheros de instrucciones** — documentos `.md` que el agente principal lee y
ejecuta directamente.

### Secuencia para cada stage

1. **Anuncia** al usuario qué stage va a ejecutar y estima el tiempo.
2. **Lee** el fichero del sub-agente con `read_file`:
   ```
   read_file("$SKILL_DIR/agents/agent-analysis.md")
   ```
3. Si el sub-agente referencia ficheros de `references/`, **léelos también**.
4. **Ejecuta** los pasos descritos en el fichero usando tu propio terminal:
   ```bash
   export SKILL_DIR="/ruta/a/la/skill"
   bash "$SKILL_DIR/scripts/paso-01-telemetria.sh"
   ```
5. Al terminar, **genera el report-back** indicado en el fichero del sub-agente.
6. **Vuelve al dispatch table**, re-evalúa flags, y avanza al siguiente stage.

### Gestión de contexto entre stages

Cada fichero `agents/*.md` solo es relevante durante su stage. Para preservar
la ventana de contexto a lo largo del pipeline:

- **Un stage a la vez** — cuando entres en un nuevo stage, las instrucciones
  del stage anterior ya no aplican. Solo importan las del `agents/*.md` que
  acabas de leer.
- **No releas** ficheros de stages anteriores. Si necesitas un dato de un
  stage previo, léelo del JSON de `reports/drupal-update/`, no del agent `.md`.
- **No acumules references** — lee `references/*.md` solo cuando el
  sub-agente actual lo indique; no vuelvas a leerlos en stages posteriores.
- **Los gates de usuario** (aprobaciones, checkpoints) crean cortes naturales.
  Aprovéchalos: resume el estado al usuario con datos de `progress.json`
  antes de continuar.

### Restricciones

> **Prohibido:** No uses `runSubagent`, `Agent`, ni ningún mecanismo de
> delegación a agentes externos. Esos agentes no tienen acceso a terminal
> y no pueden ejecutar scripts.

> **Importante:** Nunca uses asignación inline (`SKILL_DIR=value bash ...`)
> — el terminal puede perderla. Usa siempre `export` previo.

## Tabla de carga progresiva

| Fichero                                                                                           | Quién lo carga     | Cuándo                                                                                     |
| ------------------------------------------------------------------------------------------------- | ------------------ | ------------------------------------------------------------------------------------------ |
| `agents/agent-analysis.md`                                                                        | Stage 1            | Al ejecutar análisis                                                                       |
| `agents/agent-vrt.md` + `references/vrt-integration.md`                                           | Stages 1.5, 3.5, 9 | Si VRT disponible y usuario confirma el stage                                              |
| `agents/agent-planner.md` + `references/incremental-strategy.md` + `references/version-matrix.md` | Stage 2            | Al planificar                                                                              |
| `agents/agent-module-updater.md`                                                                  | Stage 3            | Al actualizar módulos                                                                      |
| `agents/agent-deprecated-handler.md`                                                              | Stage 4            | Al gestionar deprecated                                                                    |
| `agents/agent-ckeditor-migrator.md` + `references/ckeditor-migration.md`                          | Stage 5            | Si CKEditor aplica — el agente invoca `paso-06b-ckeditor.sh` y `paso-06b-content-audit.sh` |
| `agents/agent-custom-code-fixer.md` + `references/custom-code-migration.md`                       | Stage 5.5          | Análisis y corrección de código custom — invoca `paso-06c-custom-code-check.sh`            |
| `agents/agent-core-updater.md` + `references/version-matrix.md` + `references/troubleshooting.md` | Stage 7            | Al subir el core                                                                           |
| `agents/agent-validator.md`                                                                       | Stage 8            | Al validar                                                                                 |

El orquestador carga cada fichero `agents/*.md` (y sus `references/*`) **solo
cuando el dispatch table lo indica** — uno por stage. Al pasar al siguiente
stage, las instrucciones del anterior dejan de aplicar; el estado persistente
vive en los JSON de `reports/drupal-update/`, no en la memoria de la conversación.

## Reglas de portabilidad de scripts

Todos los scripts deben funcionar en macOS (bash 3.2 + BSD tools) y Linux (bash 4+ + GNU tools):

| Prohibido                                 | Alternativa POSIX                                                      |
| ----------------------------------------- | ---------------------------------------------------------------------- |
| `grep -P` / `grep -oP`                    | `sed -n 's/.../\1/p'` o `grep -oE`                                     |
| `awk match($0, /pat/, arr)` (3-arg, GAWK) | `awk` con `gsub()` o 2-arg `match()` + `RSTART`/`RLENGTH`/`substr()`   |
| `awk gensub()`                            | `awk sub()` / `gsub()`                                                 |
| `mapfile` / `readarray` (bash 4+)         | `while IFS= read -r x; do arr+=("$x"); done < <(...)`                  |
| `sed -i 's/.../.../'` (GNU)               | `sed -i '' 's/.../.../'` (macOS) — usar `sed -i.bak` para portabilidad |
| Inline env vars: `VAR=val cmd`            | `export VAR=val && cmd`                                                |

Todo script debe pasar `shellcheck` sin warnings. Los `# shellcheck disable=SCXXXX`
deben tener comentario explicando por qué.

## Referencia de arquitectura

- Documentación de estados: `docs/state-machine.md`
- Reglas del orquestador: `docs/orchestrator-contract.md`
- Scripts disponibles: `agents/README.md`
- Matriz de versiones: `references/version-matrix.md`
