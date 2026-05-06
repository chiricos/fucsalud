#!/usr/bin/env bash
# =============================================================================
# rollback.sh — Restauracion segura al snapshot pre-update
#
# Uso:
#   bash scripts/rollback.sh [snapshot-name]
#   bash scripts/rollback.sh --list-checkpoints
#   bash scripts/rollback.sh --to-commit <hash>
#
# Si no se pasa nombre, busca en paso-02-snapshot.json
# =============================================================================

set -euo pipefail

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

REPORT_DIR="reports/drupal-update"
SNAPSHOT_REPORT="$REPORT_DIR/paso-02-snapshot.json"

echo "======================================"
echo "  DRUPAL UPDATE -- Rollback"
echo "======================================"
echo ""

# -- Flag: --list-checkpoints --
if [ "${1:-}" = "--list-checkpoints" ]; then
    echo "  Commits que pueden usarse como checkpoint:"
    echo ""
    if git rev-parse --git-dir > /dev/null 2>&1; then
        git --no-pager log --oneline --all | grep -iE "(update|checkpoint|batch|pre-update|snapshot|paso)" | head -30 || echo "  (ninguno encontrado)"
    else
        echo "  Error: No es un repositorio Git"
        exit 1
    fi
    echo ""
    echo "  Usa: bash scripts/rollback.sh --to-commit <hash>"
    exit 0
fi

# -- Flag: --to-commit <hash> --
if [ "${1:-}" = "--to-commit" ]; then
    HASH="${2:?'--to-commit requiere un hash de commit. Usa --list-checkpoints para ver opciones.'}"
    echo "  Restaurando composer.json y composer.lock desde commit: $HASH"
    echo ""
    git checkout "$HASH" -- composer.json composer.lock
    echo -e "${GREEN}  Composer files restaurados${NC}"
    echo ""
    echo "  Reinstalando dependencias..."
    ddev exec bash -c 'export COMPOSER_MEMORY_LIMIT=-1 && composer install' 2>&1
    echo ""
    echo "  Ejecutando post-update hooks..."
    ddev drush updb -y 2>&1 || true
    ddev drush cr 2>&1 || true
    echo ""
    echo -e "${GREEN}  Rollback a commit $HASH completado.${NC}"
    exit 0
fi

# Determinar nombre del snapshot
if [ -n "${1:-}" ]; then
    SNAPSHOT_NAME="$1"
    echo "Usando snapshot proporcionado: $SNAPSHOT_NAME"
elif [ -f "$SNAPSHOT_REPORT" ]; then
    SNAPSHOT_NAME=$(jq -r '.data.snapshot_name' "$SNAPSHOT_REPORT" 2>/dev/null)
    if [ -z "$SNAPSHOT_NAME" ] || [ "$SNAPSHOT_NAME" = "null" ]; then
        echo -e "${RED}✗ No se pudo leer el nombre del snapshot del reporte${NC}"
        echo "Uso: bash scripts/rollback.sh <snapshot-name>"
        echo "Snapshots disponibles:"
        ddev snapshot --list
        exit 1
    fi
    echo "Usando snapshot del reporte: $SNAPSHOT_NAME"
else
    echo -e "${RED}✗ No se encontró reporte de snapshot ni se proporcionó nombre${NC}"
    echo "Uso: bash scripts/rollback.sh <snapshot-name>"
    echo "Snapshots disponibles:"
    ddev snapshot --list
    exit 1
fi

# Verificar que el snapshot existe
if ! ddev snapshot --list 2>/dev/null | grep -q "$SNAPSHOT_NAME"; then
    echo -e "${RED}✗ Snapshot '$SNAPSHOT_NAME' no encontrado${NC}"
    echo "Snapshots disponibles:"
    ddev snapshot --list
    exit 1
fi

echo -e "${YELLOW}⚠ Se va a restaurar el snapshot: $SNAPSHOT_NAME${NC}"
echo "  Esto revertirá la base de datos al estado pre-actualización."
echo ""

# Restaurar snapshot (BD)
echo "1/4 Restaurando snapshot de base de datos..."
ddev snapshot restore "$SNAPSHOT_NAME" 2>&1
echo -e "${GREEN}✓ Base de datos restaurada${NC}"

# Restaurar composer files desde git
echo "2/4 Restaurando composer.json y composer.lock..."
if git rev-parse --git-dir &> /dev/null; then
    # Buscar el commit pre-update
    PRE_UPDATE_COMMIT=$(git log --oneline --all | grep "config export pre-update" | head -1 | awk '{print $1}')
    if [ -n "$PRE_UPDATE_COMMIT" ]; then
        git checkout "$PRE_UPDATE_COMMIT" -- composer.json composer.lock 2>/dev/null || true
        echo -e "${GREEN}✓ Composer files restaurados desde commit $PRE_UPDATE_COMMIT${NC}"
    else
        echo -e "${YELLOW}⚠ No se encontró commit pre-update. Restaurando desde HEAD~1${NC}"
        git checkout HEAD~1 -- composer.json composer.lock 2>/dev/null || true
    fi
else
    echo -e "${YELLOW}⚠ No hay Git. No se pueden restaurar composer files automáticamente.${NC}"
fi

# Reinstalar dependencias
echo "3/4 Reinstalando dependencias con composer install..."
ddev exec bash -c 'export COMPOSER_MEMORY_LIMIT=-1 && composer install' 2>&1
echo -e "${GREEN}✓ Dependencias reinstaladas${NC}"

# Verificar
echo "4/4 Verificando estado post-rollback..."
DRUPAL_VER=$(ddev drush status --field=drupal-version 2>/dev/null || echo "error")
HTTP_STATUS=$(ddev exec curl -s -o /dev/null -w "%{http_code}" http://localhost 2>/dev/null || echo "000")

echo ""
echo "══════════════════════════════════════════"
if [ "$HTTP_STATUS" -lt 400 ] && [ "$DRUPAL_VER" != "error" ]; then
    echo -e "${GREEN}  ROLLBACK EXITOSO ✓${NC}"
    echo "  Drupal version: $DRUPAL_VER"
    echo "  HTTP Status: $HTTP_STATUS"
else
    echo -e "${RED}  ROLLBACK CON PROBLEMAS${NC}"
    echo "  Drupal version: $DRUPAL_VER"
    echo "  HTTP Status: $HTTP_STATUS"
    echo "  Revisa manualmente el estado del sitio."
fi
echo "══════════════════════════════════════════"

# Generar reporte de rollback
mkdir -p "$REPORT_DIR"
cat > "$REPORT_DIR/rollback.json" << EOF
{
  "name": "rollback",
  "timestamp": "$(date -Iseconds)",
  "snapshot_restored": "$SNAPSHOT_NAME",
  "drupal_version": "$DRUPAL_VER",
  "http_status": $HTTP_STATUS,
  "success": $([ "$HTTP_STATUS" -lt 400 ] && echo "true" || echo "false")
}
EOF

echo "Reporte guardado en $REPORT_DIR/rollback.json"
