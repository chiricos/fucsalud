#!/usr/bin/env bash
# =============================================================================
# progress.sh — Gestión del fichero de progreso central
#
# Uso: source "$SKILL_DIR/scripts/progress.sh"
#      update_progress "phase" "step" "description" [extra_json_fields]
#      read_progress
#
# Fichero: reports/drupal-update/progress.json
# =============================================================================

PROGRESS_FILE="reports/drupal-update/progress.json"

# Inicializar progress.json si no existe
init_progress() {
    mkdir -p "reports/drupal-update"
    if [ ! -f "$PROGRESS_FILE" ]; then
        local DRUPAL_VER
        DRUPAL_VER=$(ddev drush status --field=drupal-version 2>/dev/null || echo "unknown")
        cat > "$PROGRESS_FILE" << JSONEOF
{
  "started": "$(date -Iseconds)",
  "updated": "$(date -Iseconds)",
  "current_phase": "analysis",
  "current_step": "not_started",
  "drupal_from": "$DRUPAL_VER",
  "drupal_to": "pending",
  "modules": {
    "total": 0,
    "updated": 0,
    "blocked": 0,
    "pending": 0
  },
  "deprecated_resolved": false,
  "checkpoint_approved": false,
  "core_updated": false,
  "last_action": "Iniciado",
  "last_snapshot": "",
  "next_action": "Ejecutar paso-01-telemetria.sh"
}
JSONEOF
    fi
}

# Actualizar campos del progress.json
# Uso: update_progress "campo" "valor" ["campo2" "valor2" ...]
update_progress() {
    init_progress
    local TEMP_FILE="${PROGRESS_FILE}.tmp"
    cp "$PROGRESS_FILE" "$TEMP_FILE"

    # Siempre actualizar timestamp
    TEMP_FILE2="${PROGRESS_FILE}.tmp2"
    jq --arg ts "$(date -Iseconds)" '.updated = $ts' "$TEMP_FILE" > "$TEMP_FILE2" 2>/dev/null && mv "$TEMP_FILE2" "$TEMP_FILE"

    # Procesar pares clave=valor
    while [ $# -ge 2 ]; do
        local KEY="$1"
        local VALUE="$2"
        shift 2

        # Detectar si el valor es numérico, booleano, o string
        case "$VALUE" in
            true|false)
                jq --argjson v "$VALUE" ".$KEY = \$v" "$TEMP_FILE" > "$TEMP_FILE2" 2>/dev/null && mv "$TEMP_FILE2" "$TEMP_FILE"
                ;;
            [0-9]*)
                if [[ "$VALUE" =~ ^[0-9]+$ ]]; then
                    jq --argjson v "$VALUE" ".$KEY = \$v" "$TEMP_FILE" > "$TEMP_FILE2" 2>/dev/null && mv "$TEMP_FILE2" "$TEMP_FILE"
                else
                    jq --arg v "$VALUE" ".$KEY = \$v" "$TEMP_FILE" > "$TEMP_FILE2" 2>/dev/null && mv "$TEMP_FILE2" "$TEMP_FILE"
                fi
                ;;
            *)
                jq --arg v "$VALUE" ".$KEY = \$v" "$TEMP_FILE" > "$TEMP_FILE2" 2>/dev/null && mv "$TEMP_FILE2" "$TEMP_FILE"
                ;;
        esac
    done

    mv "$TEMP_FILE" "$PROGRESS_FILE"
    rm -f "$TEMP_FILE2"
}

# Leer un campo del progress.json
# Uso: VALUE=$(read_progress "current_phase")
read_progress() {
    local KEY="$1"
    if [ -f "$PROGRESS_FILE" ]; then
        jq -r ".$KEY // \"\"" "$PROGRESS_FILE" 2>/dev/null
    fi
}

# Mostrar resumen de progreso en terminal
show_progress() {
    if [ ! -f "$PROGRESS_FILE" ]; then
        echo "  ℹ No hay progreso registrado. Ejecutar paso-01 para comenzar."
        return
    fi

    echo ""
    echo "  ╔══════════════════════════════════════════════╗"
    echo "  ║ PROGRESO DE ACTUALIZACIÓN                     ║"
    echo "  ╠══════════════════════════════════════════════╣"
    printf "  ║ Fase actual:  %-31s║\n" "$(read_progress 'current_phase')"
    printf "  ║ Drupal:       %-31s║\n" "$(read_progress 'drupal_from') → $(read_progress 'drupal_to')"
    printf "  ║ Módulos:      %-31s║\n" "$(read_progress 'modules.updated')/$(read_progress 'modules.total') actualizados"
    printf "  ║ Bloqueados:   %-31s║\n" "$(read_progress 'modules.blocked')"
    printf "  ║ Deprecated:   %-31s║\n" "$([ "$(read_progress 'deprecated_resolved')" = "true" ] && echo "✅ Resuelto" || echo "⏳ Pendiente")"
    printf "  ║ Checkpoint:   %-31s║\n" "$([ "$(read_progress 'checkpoint_approved')" = "true" ] && echo "✅ Aprobado" || echo "🛑 Pendiente")"
    printf "  ║ Core:         %-31s║\n" "$([ "$(read_progress 'core_updated')" = "true" ] && echo "✅ Actualizado" || echo "⏳ Pendiente")"
    echo "  ╠══════════════════════════════════════════════╣"
    printf "  ║ Último:       %-31s║\n" "$(read_progress 'last_action' | cut -c1-31)"
    printf "  ║ Siguiente:    %-31s║\n" "$(read_progress 'next_action' | cut -c1-31)"
    echo "  ╚══════════════════════════════════════════════╝"
}
