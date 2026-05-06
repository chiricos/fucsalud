#!/usr/bin/env bash
# =============================================================================
# paso-02-snapshot.sh — Crea un snapshot de seguridad antes de tocar nada
# Uso: bash "$SKILL_DIR/scripts/paso-02-snapshot.sh"
# Genera: reports/drupal-update/paso-02-snapshot.json
# =============================================================================

set -uo pipefail

REPORT_DIR="reports/drupal-update"
REPORT_FILE="$REPORT_DIR/paso-02-snapshot.json"
mkdir -p "$REPORT_DIR"

echo "═══ Paso 2: Snapshot de Seguridad ═══"
echo ""

SNAPSHOT_NAME="pre-update-$(date +%Y%m%d-%H%M%S)"
STATUS="ok"
VERIFIED="false"

# Crear snapshot
echo "  Creando snapshot: $SNAPSHOT_NAME ..."
if ddev snapshot --name="$SNAPSHOT_NAME" 2>&1; then
    echo "  ✓ Snapshot creado"

    # Verificar que existe
    if ddev snapshot --list 2>/dev/null | grep -q "$SNAPSHOT_NAME"; then
        VERIFIED="true"
        echo "  ✓ Snapshot verificado"
    else
        echo "  ⚠ Snapshot creado pero no se pudo verificar en la lista"
        STATUS="warning"
    fi
else
    echo "  ✗ ERROR al crear snapshot"
    STATUS="error"
fi

# Generar reporte
cat > "$REPORT_FILE" << JSONEOF
{
  "step": 2,
  "name": "snapshot",
  "timestamp": "$(date -Iseconds)",
  "status": "$STATUS",
  "data": {
    "snapshot_name": "$SNAPSHOT_NAME",
    "verified": $VERIFIED
  },
  "rollback_command": "ddev snapshot restore $SNAPSHOT_NAME"
}
JSONEOF

echo ""
echo "  Reporte guardado en: $REPORT_FILE"

if [ "$STATUS" = "error" ]; then
    echo ""
    echo "  ⛔ SNAPSHOT FALLIDO. Sin punto de retorno NO se puede continuar."
    exit 1
fi

echo "  🔄 Rollback disponible: ddev snapshot restore $SNAPSHOT_NAME"
exit 0
