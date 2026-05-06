#!/usr/bin/env bash
# =============================================================================
# paso-06b-deprecated.sh — Wrapper: gestionar extensiones deprecated/obsolete
#
# Detecta dinámicamente extensiones con lifecycle: deprecated|obsolete
# y delega en sub-scripts especializados.
#
# Uso:
#   bash scripts/paso-06b-deprecated.sh                # Analisis completo
#   bash scripts/paso-06b-deprecated.sh --fix          # Aplicar correcciones automaticas
#   bash scripts/paso-06b-deprecated.sh --fix-ckeditor # Solo migrar CKEditor 4-5
#   bash scripts/paso-06b-deprecated.sh --dry-run      # Mostrar que haria --fix
#   bash scripts/paso-06b-deprecated.sh --skip-ckeditor # Fix sin CKEditor
#
# Reportes:
#   reports/drupal-update/paso-06b-detect.json
#   reports/drupal-update/paso-06b-deprecated.json
#   reports/drupal-update/paso-06b-deprecated.md
# =============================================================================

set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

export REPORT_DIR="${REPORT_DIR:-reports/drupal-update}"
export DRY_RUN="false"
SKIP_CKEDITOR="false"
MODE="analyze"

while [ $# -gt 0 ]; do
    case "$1" in
        --fix)           MODE="fix" ;;
        --fix-ckeditor)  MODE="fix-ckeditor" ;;
        --dry-run)       DRY_RUN="true"; MODE="fix" ;;
        --skip-ckeditor) SKIP_CKEDITOR="true" ;;
        --help|-h)
            echo "Uso:"
            echo "  paso-06b-deprecated.sh              Analisis: detectar deprecated/obsolete"
            echo "  paso-06b-deprecated.sh --fix        Aplicar correcciones automaticas"
            echo "  paso-06b-deprecated.sh --fix-ckeditor  Solo migrar CKEditor 4-5"
            echo "  paso-06b-deprecated.sh --dry-run    Ver que haria --fix sin ejecutar"
            echo "  paso-06b-deprecated.sh --skip-ckeditor  Fix omitiendo CKEditor"
            exit 0
            ;;
        *) echo "  Warning: Argumento no reconocido: $1" ;;
    esac
    shift
done

echo ""
echo "══════════════════════════════════════════════════════"
echo "  PASO 6B — Extensiones Deprecated y Obsolete"
echo "══════════════════════════════════════════════════════"
echo ""

mkdir -p "$REPORT_DIR"

echo ""
echo "====================================================="
echo "  PASO 6B -- Extensiones Deprecated y Obsolete"
echo "====================================================="
echo ""

# -- Fase 1: Deteccion --
# shellcheck source=/dev/null
source "$SCRIPT_DIR/paso-06b-detect.sh"

# Leer resultado de deteccion
DETECT_STATUS=$(jq -r '.status' "$REPORT_DIR/paso-06b-detect.json" 2>/dev/null || echo "clean")
CKE4_DETECTED=$(jq -r '.ckeditor4_detected' "$REPORT_DIR/paso-06b-detect.json" 2>/dev/null || echo "false")

if [ "$DETECT_STATUS" = "clean" ]; then
    echo ""
    echo "  No hay extensiones deprecated/obsolete activas."
    cp "$REPORT_DIR/paso-06b-detect.json" "$REPORT_DIR/paso-06b-deprecated.json"
    exit 0
fi

# -- Fase 2: Aplicar correcciones CKEditor (si aplica) --
if [ "$MODE" = "fix" ] || [ "$MODE" = "fix-ckeditor" ]; then
    if [ "$CKE4_DETECTED" = "true" ] && [ "$SKIP_CKEDITOR" != "true" ]; then
        export DRY_RUN
        bash "$SCRIPT_DIR/paso-06b-ckeditor.sh"
    fi
fi

# -- Fase 3: Aplicar correcciones no-CKEditor --
if [ "$MODE" = "fix" ]; then
    APPLY_ARGS=""
    [ "$SKIP_CKEDITOR" = "true" ] && APPLY_ARGS="--skip-ckeditor"
    export DRY_RUN
    bash "$SCRIPT_DIR/paso-06b-apply.sh" $APPLY_ARGS
fi

# -- Enlazar reporte final --
cp "$REPORT_DIR/paso-06b-detect.json" "$REPORT_DIR/paso-06b-deprecated.json" 2>/dev/null || true

echo ""
echo "  Reportes:"
echo "    $REPORT_DIR/paso-06b-detect.json"
echo "    $REPORT_DIR/paso-06b-deprecated.json"
echo ""

AUTO_COUNT=$(jq -r '.auto_fixable' "$REPORT_DIR/paso-06b-detect.json" 2>/dev/null || echo "0")
MANUAL_COUNT=$(jq -r '.manual_review' "$REPORT_DIR/paso-06b-detect.json" 2>/dev/null || echo "0")

if [ "$MANUAL_COUNT" -gt 0 ] && [ "$MODE" = "analyze" ]; then
    echo "  Warning: $MANUAL_COUNT extension(es) requieren decision manual."
fi

if [ "$MODE" = "analyze" ] && [ "$AUTO_COUNT" -gt 0 ]; then
    echo "  Info: $AUTO_COUNT correcciones automaticas disponibles con --fix"
fi
