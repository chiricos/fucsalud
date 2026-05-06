#!/usr/bin/env bash
# =============================================================================
# paso-06-manual.sh — Modo individual y batch manual + reporte Markdown
#
# Uso:
#   source "$SCRIPT_DIR/paso-06-manual.sh"
#   run_individual_mode <module> <version>
#   run_batch_mode <module:version> [<module:version>...]
#   generate_markdown_report
#
# Variables de entorno: REPORT_DIR, DRY_RUN
# Requiere: paso-06-lib.sh, paso-06-post-batch.sh
# =============================================================================

[[ -n "${_PASO06_MANUAL_LOADED:-}" ]] && return 0
_PASO06_MANUAL_LOADED=1

SCRIPT_DIR_MANUAL="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=/dev/null
source "$SCRIPT_DIR_MANUAL/paso-06-lib.sh"
# shellcheck source=/dev/null
source "$SCRIPT_DIR_MANUAL/paso-06-post-batch.sh"

REPORT_DIR="${REPORT_DIR:-reports/drupal-update/modulos}"

# =============================================================================
# generate_markdown_report() — Genera resumen Markdown legible
# =============================================================================
generate_markdown_report() {
    local MD_FILE="reports/drupal-update/paso-06-reporte.md"
    local TOTAL=0 UPDATED=0 BLOCKED=0 SKIPPED=0 FAILED=0
    local UPDATED_LIST="" BLOCKED_LIST="" FAILED_LIST="" SKIPPED_LIST=""
    local PATCH_WARNINGS="" PATCH_WARN_COUNT=0

    for RFILE in "$REPORT_DIR"/*.json; do
        [ -f "$RFILE" ] || continue
        TOTAL=$((TOTAL + 1))
        local STATUS MODULE FROM_VER TO_VER BLOCK_REASON
        STATUS=$(jq -r '.status // "unknown"' "$RFILE" 2>/dev/null)
        MODULE=$(jq -r '.module // "?"' "$RFILE" 2>/dev/null)
        FROM_VER=$(jq -r '.from_version // "?"' "$RFILE" 2>/dev/null)
        TO_VER=$(jq -r '.to_version // "?"' "$RFILE" 2>/dev/null)
        local P_COUNT P_STATUS
        P_COUNT=$(jq -r '.patches.count // 0' "$RFILE" 2>/dev/null | tr -dc '0-9')
        P_COUNT=${P_COUNT:-0}
        P_STATUS=$(jq -r '.patches.status // "none"' "$RFILE" 2>/dev/null)

        local PATCH_FLAG=""
        if [ "$P_COUNT" -gt 0 ]; then
            case "$P_STATUS" in
                some_failed)
                    PATCH_FLAG=" 🩹❌"; PATCH_WARN_COUNT=$((PATCH_WARN_COUNT + 1))
                    local P_NAMES
                    P_NAMES=$(jq -r '.patches.definitions[]?.name // "?"' "$RFILE" 2>/dev/null | tr '\n' ', ' | sed 's/,$//')
                    PATCH_WARNINGS="${PATCH_WARNINGS}| ${MODULE} | ${TO_VER} | ❌ Falló | ${P_NAMES} |
" ;;
                not_verified)
                    PATCH_FLAG=" 🩹?"; PATCH_WARN_COUNT=$((PATCH_WARN_COUNT + 1))
                    local P_NAMES
                    P_NAMES=$(jq -r '.patches.definitions[]?.name // "?"' "$RFILE" 2>/dev/null | tr '\n' ', ' | sed 's/,$//')
                    PATCH_WARNINGS="${PATCH_WARNINGS}| ${MODULE} | ${TO_VER} | ⚠️ Sin verificar | ${P_NAMES} |
" ;;
                all_applied) PATCH_FLAG=" 🩹✅" ;;
            esac
        fi

        case "$STATUS" in
            updated)
                UPDATED=$((UPDATED + 1))
                UPDATED_LIST="${UPDATED_LIST}| ${MODULE} | ${FROM_VER} | ${TO_VER} | ✅${PATCH_FLAG} |
" ;;
            already_updated)
                SKIPPED=$((SKIPPED + 1))
                SKIPPED_LIST="${SKIPPED_LIST}| ${MODULE} | ${FROM_VER} | — | ⏭️ Ya estaba |
" ;;
            blocked_manual)
                BLOCKED=$((BLOCKED + 1))
                BLOCK_REASON=$(jq -r '.block_reason // "Sin diagnóstico"' "$RFILE" 2>/dev/null)
                local BLOCKERS
                BLOCKERS=$(jq -r '.diagnosis.blockers[]?.module // empty' "$RFILE" 2>/dev/null | tr '\n' ', ' | sed 's/,$//')
                BLOCKED_LIST="${BLOCKED_LIST}| ${MODULE} | ${FROM_VER} | ${TO_VER} | ${BLOCK_REASON} | ${BLOCKERS:-—} |
" ;;
            failed)
                FAILED=$((FAILED + 1))
                FAILED_LIST="${FAILED_LIST}| ${MODULE} | ${FROM_VER} | ${TO_VER} | ❌ |
" ;;
        esac
    done

    local COMPAT_FILE="${COMPAT_FILE:-reports/drupal-update/paso-05-compatibilidad.json}"
    local TOTAL_CONTRIB=0 ALREADY_COMPAT=0 TARGET_ONLY=0 MANUAL_COUNT=0
    if [ -f "$COMPAT_FILE" ]; then
        TOTAL_CONTRIB=$(jq -r '.data.total_modules // 0' "$COMPAT_FILE" 2>/dev/null)
        ALREADY_COMPAT=$(jq -r '.data.already_compatible // 0' "$COMPAT_FILE" 2>/dev/null)
        TARGET_ONLY=$(jq -r '.data.target_only_count // 0' "$COMPAT_FILE" 2>/dev/null)
        MANUAL_COUNT=$(jq -r '.data.manual_count // 0' "$COMPAT_FILE" 2>/dev/null)
    fi

    cat > "$MD_FILE" << MDEOF
# Reporte de Actualización — Fase 1 (Módulos Puente)

**Generado:** $(date '+%Y-%m-%d %H:%M:%S')
**Proyecto:** $(basename "$(pwd)")

---

## Panorama General

| Concepto | Cantidad |
|----------|----------|
| Total módulos contrib | $TOTAL_CONTRIB |
| Ya compatibles (sin acción) | $ALREADY_COMPAT |
| Puente (Fase 1) | $((UPDATED + BLOCKED + FAILED + SKIPPED)) |
| Solo-target (Fase 3) | $TARGET_ONLY |
| Sin release (manual) | $MANUAL_COUNT |

## Progreso Fase 1

\`\`\`
✅ Actualizados:    $UPDATED
⏭️  Ya estaban:     $SKIPPED
🚫 Bloqueados:      $BLOCKED (requieren intervención manual)
❌ Fallidos:         $FAILED (reintentables)
───────────────────
   Total procesados: $TOTAL
\`\`\`

MDEOF

    [ $UPDATED -gt 0 ] && cat >> "$MD_FILE" << MDEOF
---

## ✅ Módulos Actualizados ($UPDATED)

| Módulo | Anterior | Nueva | Estado |
|--------|----------|-------|--------|
${UPDATED_LIST}
MDEOF

    [ $BLOCKED -gt 0 ] && cat >> "$MD_FILE" << MDEOF
---

## 🚫 Módulos Bloqueados — Requieren Intervención Manual ($BLOCKED)

| Módulo | Actual | Objetivo | Razón | Bloqueado por |
|--------|--------|----------|-------|---------------|
${BLOCKED_LIST}
MDEOF

    [ $FAILED -gt 0 ] && cat >> "$MD_FILE" << MDEOF
---

## ❌ Módulos Fallidos — Reintentables ($FAILED)

| Módulo | Anterior | Objetivo | Estado |
|--------|----------|----------|--------|
${FAILED_LIST}
MDEOF

    [ $SKIPPED -gt 0 ] && cat >> "$MD_FILE" << MDEOF
---

## ⏭️ Módulos Ya Actualizados ($SKIPPED)

| Módulo | Versión | Objetivo | Nota |
|--------|---------|----------|------|
${SKIPPED_LIST}
MDEOF

    [ $PATCH_WARN_COUNT -gt 0 ] && cat >> "$MD_FILE" << MDEOF
---

## 🩹 Parches que Requieren Atención ($PATCH_WARN_COUNT)

| Módulo | Versión | Estado Parche | Parche(s) |
|--------|---------|---------------|-----------|
${PATCH_WARNINGS}
MDEOF

    echo "  📄 Reporte Markdown: $MD_FILE"
}

# =============================================================================
# run_individual_mode() — Actualiza un módulo individual
# =============================================================================
run_individual_mode() {
    local MODULE="$1"
    local RAW_VERSION="$2"

    echo "═══ Actualizando: $MODULE → $RAW_VERSION ═══"
    update_single_module "$MODULE" "$RAW_VERSION"
    local EXIT=$?
    if [ $EXIT -eq 0 ]; then
        post_batch "$MODULE" "$MODULE"
        echo ""
        echo "  ┌────────────────────────────────────┐"
        echo "  │ ✅ $MODULE actualizado"
        echo "  └────────────────────────────────────┘"
    fi
    return $EXIT
}

# =============================================================================
# run_batch_mode() — Actualiza varios módulos en un lote manual
# =============================================================================
run_batch_mode() {
    local BATCH_MODULES=("$@")
    local BATCH_SIZE=${#BATCH_MODULES[@]}

    echo "═══ Actualizando lote de $BATCH_SIZE módulos ═══"
    echo ""
    echo "  Intentando lote completo..."

    local BATCH_REQUIRE_ARGS=""
    local PRE_VERSIONS_FILE
    PRE_VERSIONS_FILE=$(mktemp)

    for ENTRY in "${BATCH_MODULES[@]}"; do
        local MOD="${ENTRY%%:*}" VER="${ENTRY##*:}"
        local NORMALIZED
        NORMALIZED=$(normalize_version "$VER")
        BATCH_REQUIRE_ARGS="$BATCH_REQUIRE_ARGS ${MOD}:${NORMALIZED}"
        local CUR_VER_MOD
        CUR_VER_MOD=$(jq -r --arg m "$MOD" '[.packages[], ."packages-dev"[]] | map(select(.name == $m)) | .[0].version // "unknown"' composer.lock 2>/dev/null || echo "unknown")
        echo "${MOD}=${CUR_VER_MOD}" >> "$PRE_VERSIONS_FILE"
    done

    local BATCH_CMD="ddev composer require $BATCH_REQUIRE_ARGS --ignore-platform-reqs"
    echo "  $BATCH_CMD"
    local BATCH_EXIT
    # shellcheck disable=SC2086
    timeout 180 $BATCH_CMD 2>&1
    BATCH_EXIT=$?

    local UPDATED_MODULES="" FAILED_MODULES="" UPDATED_COUNT=0 FAILED_COUNT=0

    if [ $BATCH_EXIT -eq 0 ]; then
        echo "  ✅ Lote completo exitoso"
        for ENTRY in "${BATCH_MODULES[@]}"; do
            local MOD="${ENTRY%%:*}" VER="${ENTRY##*:}"
            local SAFE_NAME INSTALLED PREV_VER
            SAFE_NAME=$(echo "$MOD" | tr '/' '--')
            INSTALLED=$(jq -r --arg m "$MOD" '[.packages[], ."packages-dev"[]] | map(select(.name == $m)) | .[0].version // "unknown"' composer.lock 2>/dev/null || echo "$VER")
            PREV_VER=$(grep "^${MOD}=" "$PRE_VERSIONS_FILE" | cut -d= -f2- || echo "unknown")
            UPDATED_MODULES="$UPDATED_MODULES $MOD"; UPDATED_COUNT=$((UPDATED_COUNT + 1))
            cat > "$REPORT_DIR/$SAFE_NAME.json" << JSONEOF
{"module":"$MOD","timestamp":"$(date -Iseconds)","status":"updated","from_version":"$PREV_VER","to_version":"$INSTALLED"}
JSONEOF
            echo "    ✅ $MOD → $INSTALLED"
        done
        local BATCH_LABEL
        BATCH_LABEL=$(printf '%s ' "${BATCH_MODULES[@]}" | cut -c1-80)
        # shellcheck disable=SC2086
        post_batch "$BATCH_LABEL" $UPDATED_MODULES
    else
        echo "  ⚠️ Lote falló. Reintentando uno a uno..."
        for ENTRY in "${BATCH_MODULES[@]}"; do
            local MOD="${ENTRY%%:*}" VER="${ENTRY##*:}"
            if update_single_module "$MOD" "$VER"; then
                UPDATED_MODULES="$UPDATED_MODULES $MOD"; UPDATED_COUNT=$((UPDATED_COUNT + 1))
            else
                FAILED_MODULES="$FAILED_MODULES $MOD"; FAILED_COUNT=$((FAILED_COUNT + 1))
            fi
        done
        # shellcheck disable=SC2086
        [ $UPDATED_COUNT -gt 0 ] && post_batch "$UPDATED_COUNT módulos" $UPDATED_MODULES
    fi

    rm -f "$PRE_VERSIONS_FILE"

    echo ""
    echo "  ╔══════════════════════════════════════════╗"
    echo "  ║ RESULTADO DEL LOTE                       ║"
    printf "  ║ Actualizados: %-25s║\n" "$UPDATED_COUNT de $BATCH_SIZE"
    printf "  ║ Fallidos:     %-25s║\n" "$FAILED_COUNT"
    echo "  ╚══════════════════════════════════════════╝"

    [ $FAILED_COUNT -gt 0 ] && return 1 || return 0
}
