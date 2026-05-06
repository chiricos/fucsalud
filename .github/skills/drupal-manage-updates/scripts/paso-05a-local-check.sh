#!/usr/bin/env bash
# =============================================================================
# paso-05a-local-check.sh
# Lee composer.lock y clasifica módulos contrib por compatibilidad de versión
# local con la versión objetivo del core.
#
# Salida: $TMP_DIR/modules-raw.json, $TMP_DIR/already-ok.json,
#         $TMP_DIR/needs-research.json
# Variables de entorno requeridas: TARGET_MAJOR, TMP_DIR
# =============================================================================

set -uo pipefail

: "${TARGET_MAJOR:?'TARGET_MAJOR es requerido'}"
: "${TMP_DIR:?'TMP_DIR es requerido'}"
: "${REPORT_DIR:?'REPORT_DIR es requerido'}"

mkdir -p "$REPORT_DIR" "$TMP_DIR"

echo "  [5a] Leyendo composer.lock..."

if [ ! -f "composer.lock" ]; then
    echo "  ⛔ No se encontró composer.lock"
    exit 1
fi

jq '
    [(.packages // [])[]] |
    map(select(.name | startswith("drupal/"))) |
    map(select(.name | test("^drupal/core") | not)) |
    map({
        name: .name,
        version: .version,
        core_require: (
            .require["drupal/core"] //
            .require["drupal/core-recommended"] //
            "not-specified"
        )
    }) |
    sort_by(.name)
' composer.lock > "$TMP_DIR/modules-raw.json" 2>/dev/null

TOTAL=$(jq 'length' "$TMP_DIR/modules-raw.json")
echo "  Módulos en composer.lock: $TOTAL"

# Cruzar con Drush para excluir paquetes que Drupal no conoce
# (dependencias transitivas, paquetes en composer.json pero no habilitados)
echo "  [5a] Verificando módulos en Drupal via Drush..."
DRUSH_JSON=$(ddev drush pm:list --status=enabled --format=json 2>/dev/null || echo "")

if [ -n "$DRUSH_JSON" ] && echo "$DRUSH_JSON" | jq -e 'type == "object"' > /dev/null 2>&1; then
    DRUPAL_KNOWN=$(echo "$DRUSH_JSON" | jq '[keys[] | "drupal/" + .]')
    jq --argjson known "$DRUPAL_KNOWN" \
        'map(select(.name as $n | $known | index($n) != null))' \
        "$TMP_DIR/modules-raw.json" > "$TMP_DIR/modules-drupal.json"
    DRUPAL_TOTAL=$(jq 'length' "$TMP_DIR/modules-drupal.json")
    EXCLUDED=$((TOTAL - DRUPAL_TOTAL))
    echo "  Módulos en Drupal:        $DRUPAL_TOTAL (excluidos $EXCLUDED no registrados)"
    mv "$TMP_DIR/modules-drupal.json" "$TMP_DIR/modules-raw.json"
    TOTAL=$DRUPAL_TOTAL
else
    echo "  ⚠️  Drush no disponible — usando composer.lock completo (pueden aparecer módulos no habilitados)"
fi

# Ya compatible con target: su require actual incluye ^TARGET_MAJOR
jq --arg tm "$TARGET_MAJOR" '
    map(select(
        .core_require == "not-specified" or
        (.core_require | test("\\^" + $tm + "[^0-9]|\\^" + $tm + "$|>=" + $tm + "|~" + $tm))
    ))
' "$TMP_DIR/modules-raw.json" > "$TMP_DIR/already-ok.json" 2>/dev/null

# Incompatible: necesita investigar en drupal.org
jq --arg tm "$TARGET_MAJOR" '
    map(select(
        .core_require != "not-specified" and
        (.core_require | test("\\^" + $tm + "[^0-9]|\\^" + $tm + "$|>=" + $tm + "|~" + $tm) | not)
    ))
' "$TMP_DIR/modules-raw.json" > "$TMP_DIR/needs-research.json" 2>/dev/null

ALREADY_OK=$(jq 'length' "$TMP_DIR/already-ok.json")
NEEDS_RESEARCH=$(jq 'length' "$TMP_DIR/needs-research.json")

echo "  Ya compatibles (sin acción): $ALREADY_OK"
echo "  Necesitan investigar:        $NEEDS_RESEARCH"
