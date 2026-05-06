#!/usr/bin/env bash
# =============================================================================
# paso-06-actualizar-modulo.sh -- Wrapper
# Actualiza modulos contrib de Drupal delegando en sub-scripts.
#
# MODO AUTO:   bash paso-06-actualizar-modulo.sh --auto [--dry-run] [--batch-size N] [--group bridge|target]
# INDIVIDUAL:  bash paso-06-actualizar-modulo.sh drupal/addtoany 2.0.6
# LOTE:        bash paso-06-actualizar-modulo.sh --batch drupal/a:2.0 drupal/b:3.0
#
# Genera: reports/drupal-update/modulos/drupal--<nombre>.json
# =============================================================================

set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

export REPORT_DIR="reports/drupal-update/modulos"
export COMPAT_FILE="reports/drupal-update/paso-05-compatibilidad.json"
mkdir -p "$REPORT_DIR"

SKILL_DIR="${SKILL_DIR:-$(cd "$SCRIPT_DIR/.." && pwd)}"
if [ -f "$SKILL_DIR/scripts/progress.sh" ]; then
    # shellcheck source=/dev/null
    source "$SKILL_DIR/scripts/progress.sh"
fi

if [ "${1:-}" = "--help" ] || [ "${1:-}" = "-h" ]; then
    echo "Uso:"
    echo "  paso-06-actualizar-modulo.sh --auto [--dry-run] [--batch-size N] [--group bridge|target|security]"
    echo "  paso-06-actualizar-modulo.sh drupal/modulo 2.0.6"
    echo "  paso-06-actualizar-modulo.sh --batch drupal/mod1:2.0 drupal/mod2:3.0"
    exit 0
fi

HAS_AUTO="false"
HAS_BATCH="false"
REMAINING_ARGS=()
export DRY_RUN="false"
export GROUP="bridge"
export BATCH_SIZE="5"

for arg in "$@"; do
    case "$arg" in
        --auto)    HAS_AUTO="true" ;;
        --batch)   HAS_BATCH="true" ;;
        --dry-run) DRY_RUN="true" ;;
        *)         REMAINING_ARGS+=("$arg") ;;
    esac
done

IDX=0
CLEAN_ARGS=()
while [ $IDX -lt ${#REMAINING_ARGS[@]} ]; do
    arg="${REMAINING_ARGS[$IDX]}"
    case "$arg" in
        --batch-size)
            IDX=$((IDX + 1))
            [ $IDX -lt ${#REMAINING_ARGS[@]} ] && export BATCH_SIZE="${REMAINING_ARGS[$IDX]}" ;;
        --group)
            IDX=$((IDX + 1))
            [ $IDX -lt ${#REMAINING_ARGS[@]} ] && export GROUP="${REMAINING_ARGS[$IDX]}" ;;
        [0-9]*)
            export BATCH_SIZE="$arg" ;;
        *)
            CLEAN_ARGS+=("$arg") ;;
    esac
    IDX=$((IDX + 1))
done

# MODO AUTO: delegar en paso-06-auto.sh
if [ "$HAS_AUTO" = "true" ]; then
    exec "$SCRIPT_DIR/paso-06-auto.sh"
fi

# Verificar DDEV para modos individual y batch
ddev describe > /dev/null 2>&1 || { echo "Stopped: DDEV no esta activo"; exit 1; }

# MODO INDIVIDUAL
if [ "$HAS_BATCH" = "false" ]; then
    # shellcheck source=/dev/null
    source "$SCRIPT_DIR/paso-06-lib.sh"
    # shellcheck source=/dev/null
    source "$SCRIPT_DIR/paso-06-post-batch.sh"
    # shellcheck source=/dev/null
    source "$SCRIPT_DIR/paso-06-manual.sh"
    MODULE="${CLEAN_ARGS[0]:?'Modulo requerido (ej: drupal/addtoany). Usa --help.'}"
    RAW_VERSION="${CLEAN_ARGS[1]:?'Version requerida (ej: 2.0.6). Usa --help.'}"
    if [[ ! "$MODULE" =~ / ]]; then
        echo "  '$MODULE' no parece un nombre de modulo valido (debe tener /)."
        exit 1
    fi
    run_individual_mode "$MODULE" "$RAW_VERSION"
    exit $?
fi

# MODO LOTE: delegar en paso-06-manual.sh
# shellcheck source=/dev/null
source "$SCRIPT_DIR/paso-06-lib.sh"
# shellcheck source=/dev/null
source "$SCRIPT_DIR/paso-06-post-batch.sh"
# shellcheck source=/dev/null
source "$SCRIPT_DIR/paso-06-manual.sh"

if [ ${#CLEAN_ARGS[@]} -eq 0 ]; then
    echo "  --batch sin modulos -> redirigiendo a modo automatico"
    exec "$SCRIPT_DIR/paso-06-auto.sh"
fi

BATCH_MODULES=()
for ENTRY in "${CLEAN_ARGS[@]}"; do
    if [[ ! "$ENTRY" =~ ^[a-zA-Z0-9_-]+/[a-zA-Z0-9_-]+:.+ ]]; then
        echo "  Formato invalido: '$ENTRY' (requiere drupal/modulo:version)"
        exit 1
    fi
    BATCH_MODULES+=("$ENTRY")
done

run_batch_mode "${BATCH_MODULES[@]}"
exit $?
