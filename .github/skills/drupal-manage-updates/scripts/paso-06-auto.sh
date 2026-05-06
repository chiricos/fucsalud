#!/usr/bin/env bash
# =============================================================================
# paso-06-auto.sh — Modo automático con batch adaptativo
#
# Lee paso-05-compatibilidad.json y procesa módulos en lotes adaptativos.
# Batch adaptativo:
#   - Lee batch_size_hint del resumen anterior (default: 5)
#   - 100% éxito → ×2 (máx 20); >20% fallos → ÷2 (mín 1)
#   - Guarda batch_size_hint, avg_time_per_module, success_rate al terminar
#
# Variables de entorno: REPORT_DIR, COMPAT_FILE, DRY_RUN, BATCH_SIZE, GROUP
# Requiere: paso-06-lib.sh, paso-06-post-batch.sh, progress.sh
# =============================================================================

set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# shellcheck source=/dev/null
source "$SCRIPT_DIR/paso-06-lib.sh"
# shellcheck source=/dev/null
source "$SCRIPT_DIR/paso-06-post-batch.sh"

REPORT_DIR="${REPORT_DIR:-reports/drupal-update/modulos}"
COMPAT_FILE="${COMPAT_FILE:-reports/drupal-update/paso-05-compatibilidad.json}"
DRY_RUN="${DRY_RUN:-false}"
GROUP="${GROUP:-bridge}"

# Cargar funciones de progreso
SKILL_DIR="${SKILL_DIR:-$(cd "$SCRIPT_DIR/.." && pwd)}"
if [ -f "$SKILL_DIR/scripts/progress.sh" ]; then
    # shellcheck source=/dev/null
    source "$SKILL_DIR/scripts/progress.sh"
fi

mkdir -p "$REPORT_DIR"

# =============================================================================
# Batch adaptativo: leer hint previo
# =============================================================================
SUMMARY_FILE="reports/drupal-update/paso-06-auto-resumen.json"
BATCH_SIZE_HINT=5

if [ -f "$SUMMARY_FILE" ]; then
    PREV_HINT=$(jq -r '.batch_size_hint // 5' "$SUMMARY_FILE" 2>/dev/null || echo "5")
    # shellcheck disable=SC2034
    PREV_SUCCESS_RATE=$(jq -r '.success_rate // 1.0' "$SUMMARY_FILE" 2>/dev/null || echo "1.0")
    BATCH_SIZE_HINT=$PREV_HINT
    # Ajuste adaptativo
    if awk "BEGIN {exit (\$PREV_SUCCESS_RATE < 1.0 ? 1 : 0)}" 2>/dev/null; then
        # 100% éxito → multiplicar por 2, máx 20
        BATCH_SIZE_HINT=$(( BATCH_SIZE_HINT * 2 ))
        [ "$BATCH_SIZE_HINT" -gt 20 ] && BATCH_SIZE_HINT=20
    elif awk "BEGIN {exit (\$PREV_SUCCESS_RATE > 0.8 ? 1 : 0)}" 2>/dev/null; then
        : # entre 80-100%: mantener
    else
        # >20% fallos → dividir por 2, mín 1
        BATCH_SIZE_HINT=$(( BATCH_SIZE_HINT / 2 ))
        [ "$BATCH_SIZE_HINT" -lt 1 ] && BATCH_SIZE_HINT=1
    fi
fi

# Parámetro explícito tiene precedencia sobre el hint
BATCH_SIZE="${BATCH_SIZE:-$BATCH_SIZE_HINT}"

if [ ! -f "$COMPAT_FILE" ]; then
    echo "  ⛔ No se encontró: $COMPAT_FILE"
    echo "  Ejecuta primero: bash paso-05-analisis-compatibilidad.sh"
    exit 1
fi

# Seleccionar grupo de módulos
case "$GROUP" in
    bridge)   JQ_FILTER='.data.fase1_bridge';                GROUP_LABEL="Módulos puente (bridge)" ;;
    target)   JQ_FILTER='.data.fase2_target_only';           GROUP_LABEL="Módulos solo-target" ;;
    security) JQ_FILTER='.data.fase4_security_or_unsupported'; GROUP_LABEL="Módulos seguridad/soporte" ;;
    *)
        echo "  ⛔ --group debe ser 'bridge', 'target' o 'security'. Recibido: $GROUP"
        exit 1 ;;
esac

MODULES_JSON=$(jq "$JQ_FILTER" "$COMPAT_FILE" 2>/dev/null)
if [ -z "$MODULES_JSON" ] || [ "$MODULES_JSON" = "null" ] || [ "$MODULES_JSON" = "[]" ]; then
    echo "  ℹ No hay módulos en el grupo '$GROUP'."
    exit 0
fi

TOTAL_MODULES=$(echo "$MODULES_JSON" | jq 'length')

# Filtrar módulos ya procesados
PENDING_MODULES="[]"
ALREADY_DONE=0
BLOCKED_COUNT=0

while IFS= read -r LINE; do
    local_mod=$(echo "$LINE" | jq -r '.module')
    local_safe=$(echo "$local_mod" | tr '/' '--')
    local_report="$REPORT_DIR/$local_safe.json"

    if [ -f "$local_report" ]; then
        PREV_STATUS=$(jq -r '.status' "$local_report" 2>/dev/null || echo "")
        if [ "$PREV_STATUS" = "updated" ] || [ "$PREV_STATUS" = "already_updated" ]; then
            ALREADY_DONE=$((ALREADY_DONE + 1)); continue
        elif [ "$PREV_STATUS" = "blocked_manual" ]; then
            BLOCKED_COUNT=$((BLOCKED_COUNT + 1)); continue
        fi
    fi
    PENDING_MODULES=$(echo "$PENDING_MODULES" | jq --argjson mod "$LINE" '. + [$mod]')
done < <(echo "$MODULES_JSON" | jq -c '.[]')

PENDING_COUNT=$(echo "$PENDING_MODULES" | jq 'length')

echo ""
echo "═══ Modo AUTO: $GROUP_LABEL ═══"
echo ""
echo "  Total módulos en grupo:    $TOTAL_MODULES"
echo "  Ya actualizados:           $ALREADY_DONE"
echo "  Bloqueados (manual):       $BLOCKED_COUNT"
echo "  Pendientes:                $PENDING_COUNT"
echo "  Tamaño de lote (adaptativo): $BATCH_SIZE"
echo "  Dry run:                   $DRY_RUN"
echo ""

if [ "$PENDING_COUNT" -eq 0 ]; then
    echo "  ✅ No quedan módulos pendientes en el grupo '$GROUP'."
    [ "$BLOCKED_COUNT" -gt 0 ] && echo "  🚫 $BLOCKED_COUNT módulos bloqueados requieren intervención manual."
    exit 0
fi

# Tabla de pendientes
echo "  ┌──────────────────────────────────────┬─────────────┬─────────────┬────────┐"
echo "  │ Módulo                               │ Actual      │ Nueva       │ Parches│"
echo "  ├──────────────────────────────────────┼─────────────┼─────────────┼────────┤"
echo "$PENDING_MODULES" | jq -r '.[] |
    "  │ " + (.module | . + " " * (37 - length) | .[0:37]) +
    "│ " + (.current_version | . + " " * (12 - length) | .[0:12]) +
    "│ " + (.new_version | . + " " * (12 - length) | .[0:12]) +
    "│ " + (.patch_count | tostring | . + " " * (7 - length) | .[0:7]) + "│"
' 2>/dev/null || echo "  │ (error formateando tabla)                                              │"
echo "  └──────────────────────────────────────┴─────────────┴─────────────┴────────┘"
echo ""

# Dry-run: mostrar plan y salir
if [ "$DRY_RUN" = "true" ]; then
    echo "  ── DRY RUN: comandos que se ejecutarían ──"
    echo ""
    local_batch_num=0
    local_batch_items=()
    local_idx=0

    while IFS= read -r LINE; do
        local_mod=$(echo "$LINE" | jq -r '.module')
        local_ver=$(echo "$LINE" | jq -r '.new_version')
        local_batch_items+=("${local_mod}:${local_ver}")
        local_idx=$((local_idx + 1))

        if [ ${#local_batch_items[@]} -eq "$BATCH_SIZE" ] || [ "$local_idx" -eq "$PENDING_COUNT" ]; then
            local_batch_num=$((local_batch_num + 1))
            echo "  Lote $local_batch_num:"
            if [ ${#local_batch_items[@]} -eq 1 ]; then
                local_s="${local_batch_items[0]}"
                echo "    bash paso-06-actualizar-modulo.sh ${local_s%%:*} ${local_s##*:}"
            else
                echo -n "    bash paso-06-actualizar-modulo.sh --batch"
                for item in "${local_batch_items[@]}"; do echo " \\"; echo -n "      $item"; done
                echo ""
            fi
            echo ""
            local_batch_items=()
        fi
    done < <(echo "$PENDING_MODULES" | jq -c '.[]')

    echo "  Total lotes: $local_batch_num"
    exit 0
fi

# Verificar DDEV
ddev describe > /dev/null 2>&1 || { echo "  ⛔ DDEV no está activo"; exit 1; }

# Tomar los primeros BATCH_SIZE módulos pendientes
BATCH_ITEMS=()
IDX=0
while IFS= read -r LINE; do
    MOD_NAME=$(echo "$LINE" | jq -r '.module')
    NEW_VER=$(echo "$LINE" | jq -r '.new_version')
    BATCH_ITEMS+=("${MOD_NAME}:${NEW_VER}")
    IDX=$((IDX + 1))
    [ "$IDX" -ge "$BATCH_SIZE" ] && break
done < <(echo "$PENDING_MODULES" | jq -c '.[]')

BATCH_COUNT=${#BATCH_ITEMS[@]}
UPDATED=0
FAILED=0
FAILED_LIST=""
UPDATED_LIST=""

echo ""
echo "  ╔══════════════════════════════════════════════╗"
printf "  ║ PROCESANDO %d de %d pendientes              ║\n" "$BATCH_COUNT" "$PENDING_COUNT"
echo "  ╚══════════════════════════════════════════════╝"

# Medir tiempo de inicio
BATCH_START=$SECONDS

if [ "$BATCH_COUNT" -eq 1 ]; then
    SINGLE_MOD="${BATCH_ITEMS[0]%%:*}"
    SINGLE_VER="${BATCH_ITEMS[0]##*:}"
    if update_single_module "$SINGLE_MOD" "$SINGLE_VER"; then
        post_batch "$SINGLE_MOD" "$SINGLE_MOD"
        UPDATED=1; UPDATED_LIST="$SINGLE_MOD"
    else
        FAILED=1; FAILED_LIST="$SINGLE_MOD"
    fi
else
    BATCH_REQUIRE_ARGS=""
    PRE_VERSIONS_FILE=$(mktemp)

    for ENTRY in "${BATCH_ITEMS[@]}"; do
        MOD="${ENTRY%%:*}"; VER="${ENTRY##*:}"
        NORMALIZED=$(normalize_version "$VER")
        BATCH_REQUIRE_ARGS="$BATCH_REQUIRE_ARGS ${MOD}:${NORMALIZED}"
        CUR_VER_MOD=$(jq -r --arg m "$MOD" '[.packages[], ."packages-dev"[]] | map(select(.name == $m)) | .[0].version // "unknown"' composer.lock 2>/dev/null || echo "unknown")
        echo "${MOD}=${CUR_VER_MOD}" >> "$PRE_VERSIONS_FILE"
    done

    echo ""
    echo "  Intentando lote completo..."
    BATCH_CMD="ddev composer require $BATCH_REQUIRE_ARGS --ignore-platform-reqs"
    echo "  $BATCH_CMD"

    # shellcheck disable=SC2086
    timeout 180 $BATCH_CMD 2>&1
    BATCH_EXIT=$?

    if [ $BATCH_EXIT -eq 0 ]; then
        echo "  ✅ Lote completo exitoso"
        for ENTRY in "${BATCH_ITEMS[@]}"; do
            MOD="${ENTRY%%:*}"; VER="${ENTRY##*:}"
            SAFE_NAME=$(echo "$MOD" | tr '/' '--')
            INSTALLED=$(jq -r --arg m "$MOD" '[.packages[], ."packages-dev"[]] | map(select(.name == $m)) | .[0].version // "unknown"' composer.lock 2>/dev/null || echo "$VER")
            PREV_VER=$(grep "^${MOD}=" "$PRE_VERSIONS_FILE" | cut -d= -f2- || echo "unknown")
            UPDATED=$((UPDATED + 1)); UPDATED_LIST="$UPDATED_LIST $MOD"
            cat > "$REPORT_DIR/$SAFE_NAME.json" << JSONEOF
{"module":"$MOD","timestamp":"$(date -Iseconds)","status":"updated","from_version":"$PREV_VER","to_version":"$INSTALLED"}
JSONEOF
            echo "    ✅ $MOD → $INSTALLED"
        done
        BATCH_LABEL=$(printf '%s ' "${BATCH_ITEMS[@]}" | cut -c1-80)
        # shellcheck disable=SC2086
        post_batch "$BATCH_LABEL" $UPDATED_LIST
    else
        echo "  ⚠️ Lote falló. Reintentando uno a uno..."
        for ENTRY in "${BATCH_ITEMS[@]}"; do
            MOD="${ENTRY%%:*}"; VER="${ENTRY##*:}"
            if update_single_module "$MOD" "$VER"; then
                UPDATED=$((UPDATED + 1)); UPDATED_LIST="$UPDATED_LIST $MOD"
            else
                FAILED=$((FAILED + 1)); FAILED_LIST="$FAILED_LIST $MOD"
            fi
        done
        # shellcheck disable=SC2086
        [ -n "$UPDATED_LIST" ] && post_batch "lote (parcial)" $UPDATED_LIST
    fi

    rm -f "$PRE_VERSIONS_FILE"
fi

BATCH_TIME=$((SECONDS - BATCH_START))
AVG_TIME_PER_MODULE=0
[ "$BATCH_COUNT" -gt 0 ] && AVG_TIME_PER_MODULE=$((BATCH_TIME / BATCH_COUNT))

# Calcular success_rate y nuevos bloqueados
NEW_BLOCKED=0
for FM in $FAILED_LIST; do
    FM_SAFE=$(echo "$FM" | tr '/' '--')
    FM_STATUS=$(jq -r '.status' "$REPORT_DIR/$FM_SAFE.json" 2>/dev/null || echo "")
    [ "$FM_STATUS" = "blocked_manual" ] && NEW_BLOCKED=$((NEW_BLOCKED + 1))
done
TOTAL_BLOCKED=$((BLOCKED_COUNT + NEW_BLOCKED))

SUCCESS_RATE="1.0"
[ "$BATCH_COUNT" -gt 0 ] && SUCCESS_RATE=$(awk "BEGIN {printf \"%.2f\", $UPDATED / $BATCH_COUNT}")

REMAINING=$((PENDING_COUNT - UPDATED - FAILED))

echo ""
echo "  ╔══════════════════════════════════════════════════╗"
echo "  ║ RESULTADO                                        ║"
echo "  ╠══════════════════════════════════════════════════╣"
printf "  ║ Actualizados:  %-33s║\n" "$UPDATED"
printf "  ║ Bloqueados:    %-33s║\n" "$NEW_BLOCKED (→ manual)"
printf "  ║ Restantes:     %-33s║\n" "$REMAINING"
printf "  ║ Tiempo:        %-33s║\n" "${BATCH_TIME}s (avg ${AVG_TIME_PER_MODULE}s/módulo)"
printf "  ║ Siguiente lote:%-33s║\n" "$BATCH_SIZE_HINT (hint adaptativo)"
echo "  ╚══════════════════════════════════════════════════╝"

# Recopilar blocked_manual
ALL_BLOCKED_JSON="[]"
for BFILE in "$REPORT_DIR"/*.json; do
    [ -f "$BFILE" ] || continue
    BSTATUS=$(jq -r '.status' "$BFILE" 2>/dev/null || echo "")
    if [ "$BSTATUS" = "blocked_manual" ]; then
        ALL_BLOCKED_JSON=$(echo "$ALL_BLOCKED_JSON" | jq --argjson entry "$(jq '{module, block_reason, diagnosis}' "$BFILE" 2>/dev/null)" '. + [$entry]')
    fi
done

# Guardar resumen con batch_size_hint adaptativo para siguiente ejecución
NEXT_HINT="$BATCH_SIZE"
if awk "BEGIN {exit ($SUCCESS_RATE < 1.0 ? 1 : 0)}" 2>/dev/null; then
    NEXT_HINT=$(( BATCH_SIZE * 2 )); [ "$NEXT_HINT" -gt 20 ] && NEXT_HINT=20
elif awk "BEGIN {exit ($SUCCESS_RATE > 0.8 ? 1 : 0)}" 2>/dev/null; then
    : # mantener
else
    NEXT_HINT=$(( BATCH_SIZE / 2 )); [ "$NEXT_HINT" -lt 1 ] && NEXT_HINT=1
fi

cat > "$SUMMARY_FILE" << JSONEOF
{
  "step": 6,
  "name": "auto_update",
  "timestamp": "$(date -Iseconds)",
  "group": "$GROUP",
  "batch_size": $BATCH_SIZE,
  "batch_size_hint": $NEXT_HINT,
  "avg_time_per_module": $AVG_TIME_PER_MODULE,
  "success_rate": $SUCCESS_RATE,
  "status": "$([ $REMAINING -eq 0 ] && echo "complete" || echo "in_progress")",
  "this_batch": {"updated": $UPDATED, "failed": $((FAILED - NEW_BLOCKED)), "blocked": $NEW_BLOCKED},
  "progress": {
    "total_in_group": $TOTAL_MODULES,
    "updated": $((ALREADY_DONE + UPDATED)),
    "blocked_manual": $TOTAL_BLOCKED,
    "remaining": $REMAINING
  },
  "blocked_modules": $ALL_BLOCKED_JSON
}
JSONEOF

# Generar reporte Markdown
if [ -f "$SCRIPT_DIR/paso-06-manual.sh" ]; then
    # shellcheck source=/dev/null
    source "$SCRIPT_DIR/paso-06-manual.sh" 2>/dev/null || true
fi
generate_markdown_report 2>/dev/null || true

echo ""
echo "  Resumen: reports/drupal-update/paso-06-auto-resumen.json"
[ $REMAINING -gt 0 ] && echo "  ℹ Quedan $REMAINING módulos. Vuelve a ejecutar." || echo "  ✅ Grupo '$GROUP' completado."
[ "$TOTAL_BLOCKED" -gt 0 ] && echo "  🚫 $TOTAL_BLOCKED módulos requieren intervención MANUAL."

[ $FAILED -gt 0 ] && exit 1 || exit 0
