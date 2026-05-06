#!/usr/bin/env bash
# =============================================================================
# paso-05-analisis-compatibilidad.sh — Wrapper
# Clasifica módulos contrib en 3 grupos:
#   1. PUENTE: tienen release compatible con versión actual Y objetivo
#   2. SOLO-TARGET: solo tienen release para versión objetivo
#   3. MANUAL: no tienen release compatible → revisión manual
#
# Lee composer.lock (local) + consulta drupal.org para incompatibles.
# Genera: reports/drupal-update/paso-05-compatibilidad.json
#
# Uso:
#   bash paso-05-analisis-compatibilidad.sh
# =============================================================================

set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

export REPORT_DIR="reports/drupal-update"
export REPORT_FILE="$REPORT_DIR/paso-05-compatibilidad.json"
TARGET_FILE="$REPORT_DIR/paso-03-version-objetivo.json"
TELE_FILE="$REPORT_DIR/paso-01-telemetria.json"
PATCHES_FILE="$REPORT_DIR/paso-04-inventario.json"
export TMP_DIR="$REPORT_DIR/.tmp"
mkdir -p "$REPORT_DIR" "$TMP_DIR"

echo "═══ Paso 5: Análisis de Compatibilidad (3 fases) ═══"
echo ""

# --- Leer telemetría y versión objetivo ---
if [ ! -f "$TARGET_FILE" ]; then
    echo "  ⛔ No se encontró $TARGET_FILE. Ejecuta paso 3 primero."
    exit 1
fi
if [ ! -f "$TELE_FILE" ]; then
    echo "  ⛔ No se encontró $TELE_FILE. Ejecuta paso 1 primero."
    exit 1
fi

TARGET_VERSION=$(jq -r '.data.target_version' "$TARGET_FILE" 2>/dev/null || echo "")
export TARGET_VERSION
CURRENT_VERSION=$(jq -r '.data.drupal.version' "$TELE_FILE" 2>/dev/null || echo "")
export CURRENT_VERSION
CURRENT_MAJOR=$(jq -r '.data.drupal.major' "$TELE_FILE" 2>/dev/null || echo "")
export CURRENT_MAJOR

# Validar que se leyeron correctamente los valores
if [ -z "$TARGET_VERSION" ] || [ "$TARGET_VERSION" = "null" ] || [ "$TARGET_VERSION" = "none" ]; then
    echo "  ⛔ Error: No se pudo leer target_version del paso 3."
    echo "     Verifica que $TARGET_FILE sea un JSON válido."
    exit 1
fi

if [ -z "$CURRENT_VERSION" ] || [ "$CURRENT_VERSION" = "null" ]; then
    echo "  ⛔ Error: No se pudo leer la versión actual del paso 1."
    exit 1
fi

TARGET_MAJOR=$(echo "$TARGET_VERSION" | cut -d. -f1)
export TARGET_MAJOR
if [ -z "$TARGET_MAJOR" ] || ! [[ "$TARGET_MAJOR" =~ ^[0-9]+$ ]]; then
    echo "  ⛔ Error: TARGET_MAJOR inválido ($TARGET_MAJOR) derivado de TARGET_VERSION ($TARGET_VERSION)"
    exit 1
fi

echo "  Drupal actual:   $CURRENT_VERSION (major: $CURRENT_MAJOR)"
echo "  Drupal objetivo: $TARGET_VERSION (major: $TARGET_MAJOR)"

# --- Leer parches activos ---
export PATCHES_JSON="{}"
if [ -f "$PATCHES_FILE" ]; then
    PATCHES_JSON=$(jq '.data.patches.by_package // {}' "$PATCHES_FILE" 2>/dev/null || echo '{}')
fi
export PATCHES_JSON

# Fase A: clasificación local desde composer.lock
# shellcheck source=/dev/null
source "$SCRIPT_DIR/paso-05a-local-check.sh"

echo ""

# Fase B: consulta API drupal.org para módulos incompatibles
# shellcheck source=/dev/null
source "$SCRIPT_DIR/paso-05b-api-query.sh"

echo ""

# Fase D: revisión de seguridad/soporte en módulos ya compatibles
# shellcheck source=/dev/null
source "$SCRIPT_DIR/paso-05d-security-check.sh"

echo ""

# Fase C: generar JSON final y resumen
# shellcheck source=/dev/null
source "$SCRIPT_DIR/paso-05c-classify.sh"

# Limpiar temporales
rm -rf "$TMP_DIR"
