#!/usr/bin/env bash
# =============================================================================
# paso-04-inventario.sh — Inventario de parches activos y código custom
# Uso: bash "$SKILL_DIR/scripts/paso-04-inventario.sh"
# Genera: reports/drupal-update/paso-04-inventario-parches.json
# =============================================================================

set -uo pipefail

REPORT_DIR="reports/drupal-update"
REPORT_FILE="$REPORT_DIR/paso-04-inventario-parches.json"
mkdir -p "$REPORT_DIR"

# Detectar docroot del proyecto
SKILL_DIR="${SKILL_DIR:-$(cd "$(dirname "$0")/.." && pwd)}"
# shellcheck source=/dev/null
source "$SKILL_DIR/scripts/detect-docroot.sh"

echo "═══ Paso 4: Inventario de Parches y Código Custom ═══"
echo "  Docroot detectado: $DOCROOT"
echo ""

# --- 4A: Parches ---

echo "  [1/4] Analizando parches en composer.json..."
PATCH_SOURCE="none"
PATCH_PLUGIN="none"
PATCHES_JSON="null"
PATCHES_TOTAL=0

# Verificar si usa cweagans/composer-patches
if cat composer.json | jq -e '.require["cweagans/composer-patches"]' > /dev/null 2>&1; then
    PATCH_PLUGIN="cweagans/composer-patches"
fi

# Extraer parches de composer.json
PATCHES_INLINE=$(cat composer.json | jq '.extra.patches // null' 2>/dev/null)
if [ "$PATCHES_INLINE" != "null" ] && [ -n "$PATCHES_INLINE" ]; then
    PATCHES_JSON="$PATCHES_INLINE"
    PATCH_SOURCE="composer.json"
    PATCHES_TOTAL=$(echo "$PATCHES_INLINE" | jq '[.[] | length] | add // 0' 2>/dev/null || echo "0")
fi

# Verificar patches.json externo
echo "  [2/4] Buscando patches.json externo..."
if [ -f "patches.json" ]; then
    EXTERNAL_PATCHES=$(cat patches.json | jq '.' 2>/dev/null || echo 'null')
    if [ "$EXTERNAL_PATCHES" != "null" ]; then
        if [ "$PATCH_SOURCE" = "composer.json" ]; then
            PATCH_SOURCE="both"
        else
            PATCH_SOURCE="patches.json"
            PATCHES_JSON="$EXTERNAL_PATCHES"
        fi
        EXT_COUNT=$(echo "$EXTERNAL_PATCHES" | jq '[.[] | if type == "object" then length elif type == "array" then length else 0 end] | add // 0' 2>/dev/null || echo "0")
        PATCHES_TOTAL=$((PATCHES_TOTAL + EXT_COUNT))
    fi
fi

# --- 4B: Código Custom ---

echo "  [3/4] Escaneando módulos y temas custom..."

# Módulos custom
CUSTOM_MODULES="[]"
if [ -d "$DOCROOT/modules/custom" ]; then
    CUSTOM_MODULES=$(find "$DOCROOT/modules/custom" -maxdepth 1 -mindepth 1 -type d -exec basename {} \; 2>/dev/null | jq -R -s 'split("\n") | map(select(length > 0))' 2>/dev/null || echo '[]')
fi

# Temas custom
CUSTOM_THEMES="[]"
if [ -d "$DOCROOT/themes/custom" ]; then
    CUSTOM_THEMES=$(find "$DOCROOT/themes/custom" -maxdepth 1 -mindepth 1 -type d -exec basename {} \; 2>/dev/null | jq -R -s 'split("\n") | map(select(length > 0))' 2>/dev/null || echo '[]')
fi

MODULES_COUNT=$(echo "$CUSTOM_MODULES" | jq 'length' 2>/dev/null || echo "0")
THEMES_COUNT=$(echo "$CUSTOM_THEMES" | jq 'length' 2>/dev/null || echo "0")

# --- 4C: Escaneo de deprecaciones ---

echo "  [4/4] Verificando drupal-check para deprecaciones..."
DEPRECATION_AVAILABLE="false"
DEPRECATION_ERRORS=0
DEPRECATION_WARNINGS=0
DEPRECATION_OUTPUT="null"

if ddev exec which drupal-check > /dev/null 2>&1; then
    DEPRECATION_AVAILABLE="true"
    if [ "$MODULES_COUNT" -gt 0 ]; then
        echo "        Ejecutando drupal-check en módulos custom..."
        DEP_RAW=$(ddev exec drupal-check --deprecations "$DOCROOT/modules/custom/" 2>&1 || true)
        # Extraer el número real de errores de la línea "[ERROR] Found N errors"
        DEPRECATION_ERRORS=$(echo "$DEP_RAW" | grep -oE 'Found [0-9]+ errors' | grep -oE '[0-9]+' || echo "0")
        [ -z "$DEPRECATION_ERRORS" ] && DEPRECATION_ERRORS=$(echo "$DEP_RAW" | grep -c "ERROR" 2>/dev/null || echo "0")
        # Contar deprecaciones específicas (removed from drupal:10)
        DEPRECATION_WARNINGS=$(echo "$DEP_RAW" | grep -c "deprecated in drupal" 2>/dev/null || echo "0")
        # Escapar para JSON
        DEPRECATION_OUTPUT=$(echo "$DEP_RAW" | jq -Rs '.' 2>/dev/null || echo '"scan completed"')
    else
        DEPRECATION_OUTPUT='"No hay módulos custom para escanear"'
    fi
else
    DEPRECATION_OUTPUT='"drupal-check no instalado. Instalar con: ddev composer require --dev mglaman/drupal-check"'
fi

# --- Determinar status ---
STATUS="ok"
WARNINGS_ARRAY="[]"

if [ "$PATCHES_TOTAL" -gt 0 ]; then
    STATUS="warning"
    WARNINGS_ARRAY=$(echo "$WARNINGS_ARRAY" | jq --arg n "$PATCHES_TOTAL" '. + [$n + " parche(s) activo(s) que podrían fallar tras la actualización"]')
fi

if [ "$DEPRECATION_ERRORS" -gt 0 ] 2>/dev/null; then
    STATUS="warning"
    WARNINGS_ARRAY=$(echo "$WARNINGS_ARRAY" | jq --arg n "$DEPRECATION_ERRORS" '. + [$n + " error(es) de deprecación en código custom"]')
fi

# --- Generar reporte ---

cat > "$REPORT_FILE" << JSONEOF
{
  "step": 4,
  "name": "inventario_parches_custom",
  "timestamp": "$(date -Iseconds)",
  "status": "$STATUS",
  "data": {
    "docroot": "$DOCROOT",
    "patches": {
      "source": "$PATCH_SOURCE",
      "plugin": "$PATCH_PLUGIN",
      "total": $PATCHES_TOTAL,
      "by_package": ${PATCHES_JSON:-null}
    },
    "custom_code": {
      "modules": $CUSTOM_MODULES,
      "modules_count": $MODULES_COUNT,
      "themes": $CUSTOM_THEMES,
      "themes_count": $THEMES_COUNT,
      "deprecation_scan": {
        "available": $DEPRECATION_AVAILABLE,
        "errors": $DEPRECATION_ERRORS,
        "warnings": $DEPRECATION_WARNINGS,
        "output": $DEPRECATION_OUTPUT
      }
    }
  },
  "warnings": $WARNINGS_ARRAY
}
JSONEOF

# --- Mostrar resumen ---

echo ""
echo "  ┌────────────────────────────────────┐"
echo "  │ Parches activos:     $PATCHES_TOTAL ($PATCH_SOURCE)"
echo "  │ Plugin de parches:   $PATCH_PLUGIN"
echo "  │ Módulos custom:      $MODULES_COUNT"
echo "  │ Temas custom:        $THEMES_COUNT"
echo "  │ drupal-check:        $DEPRECATION_AVAILABLE"
echo "  │ Deprecation errors:  $DEPRECATION_ERRORS"
echo "  │ Status:              $STATUS"
echo "  └────────────────────────────────────┘"
echo ""
echo "  Reporte guardado en: $REPORT_FILE"

exit 0
