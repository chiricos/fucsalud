#!/usr/bin/env bash
# =============================================================================
# paso-06b-ckeditor.sh -- Detecta el estado CKEditor y valida post-migración.
#
# IMPORTANTE: Este script NO migra los formatos de texto. La migración de cada
# formato DEBE realizarse vía UI de Drupal (/admin/config/content/formats),
# usando el wizard que mapea la toolbar, migra settings y detecta plugins sin
# equivalente. Cambiar el editor programáticamente omite ese trabajo y deja la
# configuración rota.
#
# Fases:
#   detect    (default) Detecta formatos usando CKE4 y plugins contrib activos.
#   validate  Valida que CKE5 está activo, CKE4 desinstalado, watchdog limpio.
#
# Uso:
#   bash paso-06b-ckeditor.sh [--phase=detect|validate] [--dry-run]
#
# Variables de entorno: REPORT_DIR, DRY_RUN, SKILL_DIR
# =============================================================================

set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

REPORT_DIR="${REPORT_DIR:-reports/drupal-update}"
DRY_RUN="${DRY_RUN:-false}"
PHASE="detect"

while [ $# -gt 0 ]; do
    case "$1" in
        --dry-run)       DRY_RUN="true" ;;
        --phase=*)       PHASE="${1#--phase=}" ;;
        --phase)         PHASE="${2:-detect}"; shift ;;
    esac
    shift
done

if ! ddev describe > /dev/null 2>&1; then
    echo "  Stopped: DDEV no esta activo"
    exit 1
fi

SKILL_DIR="${SKILL_DIR:-$(cd "$SCRIPT_DIR/.." && pwd)}"
if [ -f "$SKILL_DIR/scripts/detect-docroot.sh" ]; then
    # shellcheck source=/dev/null
    source "$SKILL_DIR/scripts/detect-docroot.sh"
else
    DOCROOT="docroot"; [ -d "web" ] && DOCROOT="web"
fi

mkdir -p "$REPORT_DIR"

# =============================================================================
# FASE: detect
# =============================================================================
if [ "$PHASE" = "detect" ]; then
    echo ""
    echo "  [ckeditor] Detectando estado CKEditor..."

    # Formatos de texto que aún usan CKE4
    CKE4_FORMATS=$(ddev drush eval "
\$editors = \Drupal::entityTypeManager()->getStorage('editor')->loadMultiple();
foreach (\$editors as \$editor) {
    if (\$editor->getEditor() === 'ckeditor') {
        echo \$editor->id() . PHP_EOL;
    }
}
" 2>/dev/null || echo "")

    CKE4_FORMAT_COUNT=$(echo "$CKE4_FORMATS" | grep -c '[^[:space:]]' 2>/dev/null || echo "0")

    # Plugins contrib CKE4 (identificados por la presencia de CKEditorPlugin PHP)
    CKE4_PLUGINS=$(ddev exec find "$DOCROOT/modules/contrib" "$DOCROOT/modules/custom" \
        -path "*/src/Plugin/CKEditorPlugin/*.php" -type f 2>/dev/null | \
        sed 's|.*/modules/[^/]*/\([^/]*\)/.*|\1|' | sort -u || echo "")

    CKE4_PLUGIN_COUNT=$(echo "$CKE4_PLUGINS" | grep -c '[^[:space:]]' 2>/dev/null || echo "0")

    CKE5_STATUS=$(ddev drush pm:list --filter=ckeditor5 --status=enabled --format=json 2>/dev/null | \
        grep -c 'ckeditor5' || echo "0")

    echo "  Formatos usando CKE4 : $CKE4_FORMAT_COUNT"
    echo "  Plugins CKE4 contrib : $CKE4_PLUGIN_COUNT"
    echo "  CKEditor 5 habilitado: $([ "$CKE5_STATUS" -gt 0 ] && echo "SI" || echo "NO")"

    if [ "$CKE4_FORMAT_COUNT" -gt 0 ]; then
        echo ""
        echo "  ACCION REQUERIDA: Migrar los siguientes formatos vía UI de Drupal:"
        echo "  /admin/config/content/formats"
        echo "$CKE4_FORMATS" | while IFS= read -r fmt; do
            [ -z "$fmt" ] && continue
            echo "    - $fmt  →  /admin/config/content/formats/manage/$fmt"
        done
    else
        echo "  OK Sin formatos CKE4 activos"
    fi

    jq -n \
        --argjson format_count "$CKE4_FORMAT_COUNT" \
        --arg formats "$(echo "$CKE4_FORMATS" | tr '\n' ',' | sed 's/,$//')" \
        --argjson plugin_count "$CKE4_PLUGIN_COUNT" \
        --arg plugins "$(echo "$CKE4_PLUGINS" | tr '\n' ',' | sed 's/,$//')" \
        --argjson cke5_enabled "$([ "$CKE5_STATUS" -gt 0 ] && echo "true" || echo "false")" \
        --argjson dry_run "${DRY_RUN}" \
        '{
            formats_using_cke4: $format_count,
            format_names: ($formats | split(",") | map(select(length > 0))),
            cke4_contrib_plugins: $plugin_count,
            plugin_names: ($plugins | split(",") | map(select(length > 0))),
            cke5_already_enabled: $cke5_enabled,
            dry_run: $dry_run,
            migration_method: "ui_wizard_required"
        }' > "$REPORT_DIR/paso-06b-ckeditor.json"

    echo ""
    echo "  Reporte: $REPORT_DIR/paso-06b-ckeditor.json"
fi

# =============================================================================
# FASE: validate
# =============================================================================
if [ "$PHASE" = "validate" ]; then
    echo ""
    echo "  [ckeditor] Validando estado post-migración..."

    ERRORS=0

    # CKEditor 5 debe estar habilitado
    CKE5_ENABLED=$(ddev drush pm:list --filter=ckeditor5 --status=enabled --format=json 2>/dev/null | \
        grep -c 'ckeditor5' || echo "0")
    if [ "$CKE5_ENABLED" -gt 0 ]; then
        echo "  OK ckeditor5 habilitado"
    else
        echo "  FAIL ckeditor5 NO está habilitado"
        ERRORS=$((ERRORS + 1))
    fi

    # CKEditor 4 NO debe estar habilitado
    CKE4_ENABLED=$(ddev drush pm:list --filter=ckeditor --status=enabled --format=json 2>/dev/null | \
        grep -c '"ckeditor"' || echo "0")
    if [ "$CKE4_ENABLED" -eq 0 ]; then
        echo "  OK ckeditor (CKE4) desinstalado"
    else
        echo "  FAIL ckeditor (CKE4) sigue habilitado"
        ERRORS=$((ERRORS + 1))
    fi

    # No deben quedar formatos usando CKE4
    CKE4_REMAINING=$(ddev drush eval "
\$editors = \Drupal::entityTypeManager()->getStorage('editor')->loadMultiple();
\$count = 0;
foreach (\$editors as \$editor) {
    if (\$editor->getEditor() === 'ckeditor') { \$count++; }
}
echo \$count;
" 2>/dev/null || echo "0")
    if [ "${CKE4_REMAINING:-0}" -eq 0 ]; then
        echo "  OK Sin formatos de texto usando CKE4"
    else
        echo "  FAIL Hay $CKE4_REMAINING formato(s) aún usando CKE4"
        ERRORS=$((ERRORS + 1))
    fi

    # Watchdog — buscar errores recientes de ckeditor5
    WD_ERRORS=$(ddev drush watchdog:show --type=ckeditor5 --severity=Error --count=5 \
        --format=string 2>/dev/null | grep -c 'ckeditor5' || echo "0")
    if [ "${WD_ERRORS:-0}" -eq 0 ]; then
        echo "  OK Sin errores ckeditor5 en watchdog"
    else
        echo "  WARN $WD_ERRORS error(es) de ckeditor5 en watchdog — revisar"
    fi

    VALIDATION_STATUS="PASS"
    if [ "$ERRORS" -gt 0 ]; then
        VALIDATION_STATUS="FAIL"
        echo ""
        echo "  FAIL Validacion fallida con $ERRORS error(es)"
    else
        echo ""
        echo "  OK Validacion automatica superada"
        echo "  PENDIENTE: validacion manual en UI (toolbar, estilos, front-end)"
    fi

    jq -n \
        --arg status "$VALIDATION_STATUS" \
        --argjson errors "$ERRORS" \
        --argjson cke5_enabled "$([ "$CKE5_ENABLED" -gt 0 ] && echo "true" || echo "false")" \
        --argjson cke4_removed "$([ "${CKE4_ENABLED:-0}" -eq 0 ] && echo "true" || echo "false")" \
        --argjson watchdog_errors "${WD_ERRORS:-0}" \
        '{
            status: $status,
            errors: $errors,
            cke5_enabled: $cke5_enabled,
            cke4_removed: $cke4_removed,
            watchdog_errors: $watchdog_errors,
            manual_validation_pending: true
        }' > "$REPORT_DIR/paso-06b-ckeditor-validate.json"

    echo "  Reporte: $REPORT_DIR/paso-06b-ckeditor-validate.json"
fi

export PHASE
export DRY_RUN
