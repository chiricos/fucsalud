#!/usr/bin/env bash
# =============================================================================
# paso-06b-detect.sh -- Detecta modulos deprecated/obsolete via lifecycle
# Ejecutable de forma independiente (no requiere paso-06b-ckeditor ni apply).
#
# Salida: reports/drupal-update/paso-06b-detect.json
# Variables opcionales: REPORT_DIR, DRY_RUN
# =============================================================================

set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

REPORT_DIR="${REPORT_DIR:-reports/drupal-update}"
DRY_RUN="${DRY_RUN:-false}"
mkdir -p "$REPORT_DIR"

if ! ddev describe > /dev/null 2>&1; then
    echo "  Stopped: DDEV no esta activo"
    exit 1
fi

SKILL_DIR="${SKILL_DIR:-$(cd "$SCRIPT_DIR/.." && pwd)}"
if [ -f "$SKILL_DIR/scripts/detect-docroot.sh" ]; then
    # shellcheck source=/dev/null
    source "$SKILL_DIR/scripts/detect-docroot.sh"
else
    DOCROOT="docroot"
    [ -d "web" ] && DOCROOT="web"
    export DOCROOT
fi

echo ""
echo "  [detect] Detectando extensiones deprecated/obsolete..."
echo ""

DEPRECATED_RAW=$(ddev drush eval "
\$manager = \Drupal::service('extension.list.module');
\$installed = \$manager->getAllInstalledInfo();
foreach (\$installed as \$name => \$info) {
    \$lifecycle = \$info['lifecycle'] ?? 'stable';
    if (in_array(\$lifecycle, ['deprecated', 'obsolete'])) {
        \$link = \$info['lifecycle_link'] ?? '';
        \$package = \$info['package'] ?? 'Other';
        \$version = \$info['version'] ?? 'unknown';
        echo \$name . '|' . \$lifecycle . '|' . \$package . '|' . \$version . '|' . \$link . PHP_EOL;
    }
}
" 2>/dev/null || echo "")

DEPRECATED_THEMES_RAW=$(ddev drush eval "
\$manager = \Drupal::service('extension.list.theme');
\$installed = \$manager->getAllInstalledInfo();
foreach (\$installed as \$name => \$info) {
    \$lifecycle = \$info['lifecycle'] ?? 'stable';
    if (in_array(\$lifecycle, ['deprecated', 'obsolete'])) {
        \$link = \$info['lifecycle_link'] ?? '';
        \$version = \$info['version'] ?? 'unknown';
        echo \$name . '|' . \$lifecycle . '|theme|' . \$version . '|' . \$link . PHP_EOL;
    }
}
" 2>/dev/null || echo "")

ALL_DEPRECATED=$(printf '%s\n%s' "$DEPRECATED_RAW" "$DEPRECATED_THEMES_RAW" | grep '|' | sort)
TOTAL_DEPRECATED=$(echo "$ALL_DEPRECATED" | grep -c '|' || echo "0")

DEP_COUNT=0
OBS_COUNT=0
CKE4_DETECTED="false"
ITEMS_JSON="[]"
ACTIONS_AUTO=()
ACTIONS_MANUAL=()

if [ "$TOTAL_DEPRECATED" -gt 0 ]; then
    echo "  Encontradas $TOTAL_DEPRECATED extensiones deprecated/obsolete:"
    echo ""

    while IFS='|' read -r NAME LIFECYCLE PACKAGE VERSION LINK; do
        [ -z "$NAME" ] && continue
        [ "$LIFECYCLE" = "deprecated" ] && DEP_COUNT=$((DEP_COUNT + 1)) || OBS_COUNT=$((OBS_COUNT + 1))

        ACTION="" DETAIL="" AUTO="false"
        case "$NAME" in
            ckeditor)
                ACTION="migrate_ckeditor5"; DETAIL="Migrar formatos a CKEditor 5."; AUTO="true"; CKE4_DETECTED="true" ;;
            entity_reference|help_topics|migrate_drupal_multilingual|sdc|quickedit)
                ACTION="uninstall_safe"; DETAIL="Funcionalidad integrada en core. Desinstalar sin perdida de datos."; AUTO="true" ;;
            seven) ACTION="theme_switch"; DETAIL="Migrar a Claro (admin theme D10+)."; AUTO="false" ;;
            bartik) ACTION="theme_switch"; DETAIL="Migrar a Olivero o drupal/bartik contrib."; AUTO="false" ;;
            classy|stable) ACTION="theme_switch"; DETAIL="Migrar a Starterkit o instalar contrib."; AUTO="false" ;;
            rdf|color|aggregator|book|forum|tour|tracker)
                ACTION="check_usage_then_uninstall_or_contrib"; DETAIL="Si no se usa -> desinstalar. Sino -> instalar contrib drupal/$NAME."; AUTO="false" ;;
            hal) ACTION="require_contrib"; DETAIL="Disponible como drupal/hal contrib. Considerar JSON:API."; AUTO="false" ;;
            statistics) ACTION="require_contrib"; DETAIL="Instalar drupal/statistics contrib."; AUTO="false" ;;
            layout_builder_expose_all_field_blocks)
                ACTION="uninstall_safe"; DETAIL="Feature flag. Desinstalar mejora rendimiento."; AUTO="false" ;;
            *)
                if [ "$LIFECYCLE" = "obsolete" ]; then
                    ACTION="uninstall_safe"; DETAIL="Obsolete: funcionalidad integrada en core."; AUTO="true"
                else
                    ACTION="review_manual"; DETAIL="Deprecated. Consultar: $LINK"; AUTO="false"
                fi ;;
        esac

        ICON="Warning"; [ "$LIFECYCLE" = "obsolete" ] && ICON="Blocked"
        printf "  [%s] %-35s  %s  ->  %s\n" "$ICON" "$NAME" "$LIFECYCLE" "$ACTION"

        [ "$AUTO" = "true" ] && ACTIONS_AUTO+=("$NAME|$ACTION|$DETAIL") || ACTIONS_MANUAL+=("$NAME|$ACTION|$DETAIL")

        ITEMS_JSON=$(echo "$ITEMS_JSON" | jq \
            --arg name "$NAME" --arg lifecycle "$LIFECYCLE" --arg package "$PACKAGE" \
            --arg version "$VERSION" --arg link "$LINK" --arg action "$ACTION" \
            --arg detail "$DETAIL" --argjson auto "$AUTO" \
            '. + [{name:$name,lifecycle:$lifecycle,package:$package,version:$version,
              lifecycle_link:$link,recommended_action:$action,detail:$detail,auto_fixable:$auto}]')
    done <<< "$ALL_DEPRECATED"

    echo ""
    echo "  Deprecated: $DEP_COUNT | Obsolete: $OBS_COUNT"
    echo "  Auto-fixable: ${#ACTIONS_AUTO[@]} | Requieren decision: ${#ACTIONS_MANUAL[@]}"
    echo "  CKEditor 4 detectado: $CKE4_DETECTED"
fi

# Guardar reporte JSON
AUTO_COUNT=${#ACTIONS_AUTO[@]}
MANUAL_COUNT=${#ACTIONS_MANUAL[@]}
STATUS="clean"
[ "$TOTAL_DEPRECATED" -gt 0 ] && STATUS="needs_action"

cat > "$REPORT_DIR/paso-06b-detect.json" << JSONEOF
{
  "step": "6b-detect",
  "timestamp": "$(date -Iseconds)",
  "status": "$STATUS",
  "deprecated_count": $DEP_COUNT,
  "obsolete_count": $OBS_COUNT,
  "auto_fixable": $AUTO_COUNT,
  "manual_review": $MANUAL_COUNT,
  "ckeditor4_detected": $CKE4_DETECTED,
  "items": $ITEMS_JSON
}
JSONEOF

echo ""
echo "  Reporte: $REPORT_DIR/paso-06b-detect.json"
echo "  Status: $STATUS"

# Exportar para sub-scripts posteriores
export CKE4_DETECTED
ACTIONS_AUTO_JSON="$(printf '%s\n' "${ACTIONS_AUTO[@]+"${ACTIONS_AUTO[@]}"}")";
export ACTIONS_AUTO_JSON
ACTIONS_MANUAL_JSON="$(printf '%s\n' "${ACTIONS_MANUAL[@]+"${ACTIONS_MANUAL[@]}"}")";
export ACTIONS_MANUAL_JSON
