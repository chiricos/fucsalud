#!/usr/bin/env bash
# =============================================================================
# paso-06b-content-audit.sh -- Audita contenido HTML especial en campos de texto.
#
# Detecta patrones que afectan las decisiones de configuración de CKEditor 5:
#   - <iframe>: necesita SourceEditing con <iframe> en allowed_tags
#   - <div class="...">: el Style plugin de CKE5 no admite <div>; requiere SourceEditing
#   - Templates de CKE4: si el plugin estaba activo en la toolbar
#
# Uso:
#   bash paso-06b-content-audit.sh [--dry-run]
#
# Variables de entorno: REPORT_DIR
# =============================================================================

set -uo pipefail

# shellcheck disable=SC2034  # SCRIPT_DIR reservado para uso por scripts que hacen source
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

REPORT_DIR="${REPORT_DIR:-reports/drupal-update}"
DRY_RUN="${DRY_RUN:-false}"

while [ $# -gt 0 ]; do
    case "$1" in
        --dry-run) DRY_RUN="true" ;;
    esac
    shift
done

if ! ddev describe > /dev/null 2>&1; then
    echo "  Stopped: DDEV no esta activo"
    exit 1
fi

mkdir -p "$REPORT_DIR"

echo ""
echo "  [content-audit] Auditando contenido HTML especial..."

# =============================================================================
# 1. Descubrir tablas con columnas de tipo texto largo
# =============================================================================
TEXT_COLUMNS=$(ddev drush sql:query "
SELECT CONCAT(TABLE_NAME, '.', COLUMN_NAME) AS tc
FROM information_schema.COLUMNS
WHERE TABLE_SCHEMA = DATABASE()
  AND DATA_TYPE IN ('longtext', 'mediumtext', 'text')
  AND COLUMN_NAME LIKE '%_value'
ORDER BY TABLE_NAME, COLUMN_NAME;
" 2>/dev/null | grep -v '^tc$' | grep -v '^$' || echo "")

echo "  Columnas de texto encontradas: $(echo "$TEXT_COLUMNS" | grep -c '[^[:space:]]')"

# =============================================================================
# 2. Contar registros con <iframe> por tabla
# =============================================================================
echo "  Buscando <iframe> en el contenido..."

IFRAME_TOTAL=0
IFRAME_DETAILS="[]"
IFRAME_TABLES=0

while IFS= read -r TC; do
    [ -z "$TC" ] && continue
    TABLE="${TC%%.*}"
    COL="${TC#*.}"

    COUNT=$(ddev drush sql:query \
        "SELECT COUNT(*) FROM \`$TABLE\` WHERE \`$COL\` LIKE '%<iframe%';" \
        2>/dev/null | grep -E '^[0-9]+$' | head -1 || echo "0")

    COUNT="${COUNT:-0}"
    if [ "$COUNT" -gt 0 ]; then
        IFRAME_TOTAL=$((IFRAME_TOTAL + COUNT))
        IFRAME_TABLES=$((IFRAME_TABLES + 1))
        IFRAME_DETAILS=$(echo "$IFRAME_DETAILS" | jq \
            --arg t "$TABLE" --arg c "$COL" --argjson n "$COUNT" \
            '. + [{"table": $t, "column": $c, "count": $n}]' 2>/dev/null || echo "$IFRAME_DETAILS")
        echo "    $TABLE.$COL: $COUNT iframe(s)"
    fi
done <<< "$TEXT_COLUMNS"

echo "  Total <iframe>: $IFRAME_TOTAL en $IFRAME_TABLES tabla(s)"

# =============================================================================
# 3. Contar registros con <div class=...> — relevante por limitación de CKE5 Style
# =============================================================================
echo "  Buscando <div class=...> en el contenido..."

DIV_CLASS_TOTAL=0
DIV_CLASS_TABLES=0

while IFS= read -r TC; do
    [ -z "$TC" ] && continue
    TABLE="${TC%%.*}"
    COL="${TC#*.}"

    COUNT=$(ddev drush sql:query \
        "SELECT COUNT(*) FROM \`$TABLE\` WHERE \`$COL\` LIKE '%<div class=%';" \
        2>/dev/null | grep -E '^[0-9]+$' | head -1 || echo "0")

    COUNT="${COUNT:-0}"
    if [ "$COUNT" -gt 0 ]; then
        DIV_CLASS_TOTAL=$((DIV_CLASS_TOTAL + COUNT))
        DIV_CLASS_TABLES=$((DIV_CLASS_TABLES + 1))
    fi
done <<< "$TEXT_COLUMNS"

echo "  Total <div class=...>: $DIV_CLASS_TOTAL en $DIV_CLASS_TABLES tabla(s)"

# =============================================================================
# 4. Detectar si el plugin Templates de CKE4 estaba activo en algún formato
# =============================================================================
echo "  Verificando plugin Templates CKE4..."

TEMPLATES_ACTIVE=$(ddev drush eval "
\$editors = \Drupal::entityTypeManager()->getStorage('editor')->loadMultiple();
\$found = [];
foreach (\$editors as \$id => \$editor) {
    \$settings = \$editor->getSettings();
    if (!empty(\$settings['toolbar']['rows'])) {
        foreach (\$settings['toolbar']['rows'] as \$row) {
            foreach (\$row as \$item) {
                if (is_array(\$item) && !empty(\$item['items'])) {
                    if (in_array('Templates', \$item['items'])) {
                        \$found[] = \$id;
                    }
                }
            }
        }
    }
}
echo implode(',', \$found);
" 2>/dev/null || echo "")

if [ -n "$TEMPLATES_ACTIVE" ]; then
    echo "  Plugin Templates activo en: $TEMPLATES_ACTIVE"
else
    echo "  Plugin Templates no activo en ningun formato"
fi

# =============================================================================
# 5. Recomendaciones SourceEditing
# =============================================================================
RECOMMENDATIONS="[]"
if [ "$IFRAME_TOTAL" -gt 0 ]; then
    RECOMMENDATIONS=$(echo "$RECOMMENDATIONS" | jq \
        '. + [{"tag": "<iframe>", "reason": "iframe content found in database", "count": '"$IFRAME_TOTAL"'}]' \
        2>/dev/null || echo "$RECOMMENDATIONS")
fi
if [ "$DIV_CLASS_TOTAL" -gt 0 ]; then
    RECOMMENDATIONS=$(echo "$RECOMMENDATIONS" | jq \
        '. + [{"tag": "<div class=\"...\">", "reason": "CKE5 Style plugin does not support <div>; use SourceEditing", "count": '"$DIV_CLASS_TOTAL"'}]' \
        2>/dev/null || echo "$RECOMMENDATIONS")
fi

# =============================================================================
# 6. Escribir reporte JSON
# =============================================================================
jq -n \
    --argjson iframe_total "$IFRAME_TOTAL" \
    --argjson iframe_tables "$IFRAME_TABLES" \
    --argjson iframe_details "$IFRAME_DETAILS" \
    --argjson div_class_total "$DIV_CLASS_TOTAL" \
    --argjson div_class_tables "$DIV_CLASS_TABLES" \
    --arg templates_active "$TEMPLATES_ACTIVE" \
    --argjson recommendations "$RECOMMENDATIONS" \
    --argjson dry_run "${DRY_RUN}" \
    '{
        iframe: {
            total_records: $iframe_total,
            tables_affected: $iframe_tables,
            details: $iframe_details
        },
        div_with_class: {
            total_records: $div_class_total,
            tables_affected: $div_class_tables
        },
        templates_plugin_active_in: ($templates_active | split(",") | map(select(length > 0))),
        source_editing_recommendations: $recommendations,
        dry_run: $dry_run
    }' > "$REPORT_DIR/paso-06b-content-audit.json"

echo ""
echo "  Reporte: $REPORT_DIR/paso-06b-content-audit.json"

export IFRAME_TOTAL
export DIV_CLASS_TOTAL
export TEMPLATES_ACTIVE
