#!/usr/bin/env bash
# =============================================================================
# paso-06b-apply.sh -- Aplica correcciones a modulos deprecated (no-CKEditor)
#
# Uso:
#   source ... && _apply_deprecated_fixes
#   bash paso-06b-apply.sh [--dry-run] [--skip-ckeditor]
#
# Variables de entorno: REPORT_DIR, DRY_RUN, ACTIONS_AUTO (lineas NAME|ACTION|DETAIL)
# =============================================================================

set -uo pipefail

REPORT_DIR="${REPORT_DIR:-reports/drupal-update}"
DRY_RUN="${DRY_RUN:-false}"
SKIP_CKEDITOR="false"

while [ $# -gt 0 ]; do
    case "$1" in
        --dry-run)      DRY_RUN="true" ;;
        --skip-ckeditor) SKIP_CKEDITOR="true" ;;
    esac
    shift
done

if ! ddev describe > /dev/null 2>&1; then
    echo "  Stopped: DDEV no esta activo"
    exit 1
fi

DETECT_REPORT="$REPORT_DIR/paso-06b-detect.json"
if [ ! -f "$DETECT_REPORT" ]; then
    echo "  Warning: No se encontro $DETECT_REPORT. Ejecuta paso-06b-detect.sh primero."
    exit 1
fi

echo ""
echo "  [apply] Aplicando correcciones a modulos deprecated (no-CKEditor)..."

FIXED_COUNT=0
FIXED_LIST=""

# Leer modulos auto-fixable del reporte de deteccion
ITEMS=$(jq -c '.items[] | select(.auto_fixable == true)' "$DETECT_REPORT" 2>/dev/null || echo "")

while IFS= read -r ITEM; do
    [ -z "$ITEM" ] && continue
    MOD_NAME=$(echo "$ITEM" | jq -r '.name')
    MOD_ACTION=$(echo "$ITEM" | jq -r '.recommended_action')

    # Skip CKEditor si se pidio
    if [ "$SKIP_CKEDITOR" = "true" ] && [ "$MOD_NAME" = "ckeditor" ]; then
        echo "    Skip ckeditor (--skip-ckeditor activo)"
        continue
    fi
    # CKEditor se maneja en paso-06b-ckeditor.sh, no aqui
    [ "$MOD_NAME" = "ckeditor" ] && continue

    case "$MOD_ACTION" in
        uninstall_safe)
            if [ "$DRY_RUN" = "true" ]; then
                echo "    (dry-run) ddev drush pmu $MOD_NAME -y"
            else
                echo "    Desinstalando: $MOD_NAME"
                ddev drush pmu "$MOD_NAME" -y 2>&1 | sed 's/^/      /' || true
                FIXED_COUNT=$((FIXED_COUNT + 1))
                FIXED_LIST="$FIXED_LIST $MOD_NAME"
            fi ;;
    esac
done <<< "$ITEMS"

# Post-fix: exportar config + commit (solo si se hicieron cambios reales)
if [ "$DRY_RUN" = "false" ] && [ $FIXED_COUNT -gt 0 ]; then
    echo ""
    echo "  Post-fix: exportar config y commit..."
    ddev drush cex -y 2>/dev/null | sed 's/^/    /' || true
    git add -A
    git commit -m "chore: remove deprecated/obsolete extensions ($FIXED_COUNT modules)" 2>/dev/null | sed 's/^/    /' || true
    ddev snapshot --name="post-deprecated-cleanup-$(date +%Y%m%d-%H%M%S)" 2>/dev/null | sed 's/^/    /' || true
    echo "  OK Config exportada, commit y snapshot creados"
fi

# Generar reporte JSON
DRY_RUN_JSON="false"; [ "$DRY_RUN" = "true" ] && DRY_RUN_JSON="true"
cat > "$REPORT_DIR/paso-06b-apply.json" << JSONEOF
{
  "step": "6b-apply",
  "timestamp": "$(date -Iseconds)",
  "dry_run": $DRY_RUN_JSON,
  "skip_ckeditor": $SKIP_CKEDITOR,
  "fixed_count": $FIXED_COUNT,
  "fixed_modules": "$(echo "$FIXED_LIST" | xargs)"
}
JSONEOF

echo ""
echo "  Corregidos: $FIXED_COUNT"
echo "  Reporte: $REPORT_DIR/paso-06b-apply.json"
