#!/usr/bin/env bash
# =============================================================================
# paso-05c-classify.sh
# Clasifica módulos en bridge/target-only/manual y genera el JSON final de
# compatibilidad.
#
# Entrada:  $TMP_DIR/{bridge,target-only,manual,already-ok}.json
#           Variables: TARGET_MAJOR, CURRENT_MAJOR, CURRENT_VERSION, TARGET_VERSION
#           TOTAL (total módulos)
# Salida:   $REPORT_FILE (paso-05-compatibilidad.json)
#           Imprime resumen por stdout
# =============================================================================

set -uo pipefail

: "${TARGET_MAJOR:?'TARGET_MAJOR es requerido'}"
: "${CURRENT_MAJOR:?'CURRENT_MAJOR es requerido'}"
: "${CURRENT_VERSION:?'CURRENT_VERSION es requerido'}"
: "${TARGET_VERSION:?'TARGET_VERSION es requerido'}"
: "${REPORT_FILE:?'REPORT_FILE es requerido'}"
: "${TMP_DIR:?'TMP_DIR es requerido'}"
: "${PATCHES_JSON:='{}'}"

BRIDGE=$(cat "$TMP_DIR/bridge.json" 2>/dev/null || echo "[]")
TARGET_ONLY=$(cat "$TMP_DIR/target-only.json" 2>/dev/null || echo "[]")
MANUAL=$(cat "$TMP_DIR/manual.json" 2>/dev/null || echo "[]")
SECURITY_UPDATE=$(cat "$TMP_DIR/security-update.json" 2>/dev/null || echo "[]")

ALREADY_COMPATIBLE=$(jq --argjson patches "$PATCHES_JSON" '
    map(. + {
        has_patches: ($patches[.name] != null),
        patch_count: (if $patches[.name] then ($patches[.name] | if type == "object" then length elif type == "array" then length else 0 end) else 0 end),
        action: "none"
    })
' "$TMP_DIR/already-ok.json")

BRIDGE_COUNT=$(echo "$BRIDGE" | jq 'length')
TARGET_ONLY_COUNT=$(echo "$TARGET_ONLY" | jq 'length')
MANUAL_COUNT=$(echo "$MANUAL" | jq 'length')
SECURITY_UPDATE_COUNT=$(echo "$SECURITY_UPDATE" | jq 'length')
ALREADY_OK=$(jq 'length' "$TMP_DIR/already-ok.json")
TOTAL=$(jq 'length' "$TMP_DIR/modules-raw.json" 2>/dev/null || echo "$((ALREADY_OK + BRIDGE_COUNT + TARGET_ONLY_COUNT + MANUAL_COUNT))")

# Análisis de módulos con problemas de mantenimiento
MAINTENANCE_ISSUES=$(echo "$BRIDGE $TARGET_ONLY $MANUAL" | jq -s 'add | map(select(
    .maintenance_status == "Minimally maintained" or
    .maintenance_status == "Seeking new maintainer" or
    .maintenance_status == "Seeking co-maintainer" or
    .maintenance_status == "Unsupported" or
    .maintenance_status == "Abandoned" or
    .development_status == "Obsolete" or
    .security_covered == false
)) | sort_by(.module)')

MAINTENANCE_ISSUES_COUNT=$(echo "$MAINTENANCE_ISSUES" | jq 'length')

# Generar reporte JSON
cat > "$REPORT_FILE" << JSONEOF
{
  "step": 5,
  "name": "compatibilidad",
  "timestamp": "$(date -Iseconds)",
  "status": "$([ "$MANUAL_COUNT" -gt 0 ] && echo "needs_review" || echo "ready")",
  "data": {
    "current_version": "$CURRENT_VERSION",
    "current_major": $CURRENT_MAJOR,
    "target_version": "$TARGET_VERSION",
    "target_major": $TARGET_MAJOR,
    "total_modules": $TOTAL,
    "already_compatible": $ALREADY_OK,
    "bridge_count": $BRIDGE_COUNT,
    "target_only_count": $TARGET_ONLY_COUNT,
    "manual_count": $MANUAL_COUNT,
    "security_update_count": $SECURITY_UPDATE_COUNT,
    "maintenance_issues_count": $MAINTENANCE_ISSUES_COUNT,
    "fase1_bridge": $BRIDGE,
    "fase2_target_only": $TARGET_ONLY,
    "fase3_manual": $MANUAL,
    "fase4_security_or_unsupported": $SECURITY_UPDATE,
    "compatible_no_action": $ALREADY_COMPATIBLE,
    "maintenance_issues": $MAINTENANCE_ISSUES
  }
}
JSONEOF

echo ""
echo "  ╔══════════════════════════════════════════════════╗"
echo "  ║ RESUMEN DE COMPATIBILIDAD                        ║"
echo "  ╠══════════════════════════════════════════════════╣"
echo "  ║ Total módulos contrib:       $(printf '%-18s' "$TOTAL")║"
echo "  ║ Ya compatibles (sin acción): $(printf '%-18s' "$ALREADY_OK")║"
echo "  ║                                                  ║"
echo "  ║ FASE 1 — Puente (D${CURRENT_MAJOR}+D${TARGET_MAJOR}):   $(printf '%-18s' "$BRIDGE_COUNT")║"
echo "  ║   → Actualizar 1 a 1 ANTES del core             ║"
echo "  ║                                                  ║"
echo "  ║ FASE 2 — Solo D${TARGET_MAJOR}:          $(printf '%-18s' "$TARGET_ONLY_COUNT")║"
echo "  ║   → Actualizar JUNTO con el core                 ║"
echo "  ║                                                  ║"
echo "  ║ FASE 3 — Sin release:       $(printf '%-18s' "$MANUAL_COUNT")║"
echo "  ║   → Revisión manual                              ║"
echo "  ║                                                  ║"
echo "  ║ FASE 4 — Seguridad/Soporte: $(printf '%-18s' "$SECURITY_UPDATE_COUNT")║"
echo "  ║   → Actualizar por seguridad o fin de soporte     ║"
echo "  ╚══════════════════════════════════════════════════╝"

if [ "$MAINTENANCE_ISSUES_COUNT" -gt 0 ]; then
    echo ""
    echo "  ⚠️  MÓDULOS CON PROBLEMAS DE MANTENIMIENTO: $MAINTENANCE_ISSUES_COUNT"
    echo "  ═══════════════════════════════════════════════════════"
    echo "$MAINTENANCE_ISSUES" | jq -r '.[] | "  • \(.module)
      Estado: \(.maintenance_status // "N/A") | Dev: \(.development_status // "N/A")
      Seguridad: \(if .security_covered then "✅ Cubierto" else "❌ NO cubierto" end)"'
    echo ""
    echo "  💡 RECOMENDACIONES:"
    echo "     - Buscar módulos alternativos con mejor mantenimiento"
    echo "     - Revisar issues en drupal.org para módulos sucesores"
    echo "     - Evaluar si el módulo es prescindible"
fi

echo ""
echo "  Reporte guardado en: $REPORT_FILE"
