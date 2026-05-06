#!/usr/bin/env bash
# =============================================================================
# vrt-report.sh -- Genera vrt-summary.md consolidando JSONs de cada fase VRT.
# Uso: bash vrt-report.sh
# Variables: SKILL_DIR (raiz skill), REPORTS_DIR (directorio reportes)
# =============================================================================

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SKILL_DIR="${SKILL_DIR:-$(cd "$SCRIPT_DIR/.." && pwd)}"
REPORTS_DIR="${REPORTS_DIR:-reports/drupal-update}"

BASELINE="$REPORTS_DIR/vrt-baseline.json"
POST="$REPORTS_DIR/vrt-post-modules.json"
FINAL="$REPORTS_DIR/vrt-final.json"
SUMMARY="$REPORTS_DIR/vrt-summary.md"

mkdir -p "$REPORTS_DIR"

# Helpers: extraen campo string/int de JSON (jq si disponible, sino grep)
# shellcheck disable=SC2015
_jf() { command -v jq &>/dev/null && jq -r ".${2} // empty" "$1" 2>/dev/null \
    || grep -o "\"${2}\":[[:space:]]*\"[^\"]*\"" "$1" 2>/dev/null \
    | sed 's/.*: *"\(.*\)"/\1/' | head -1; }
# shellcheck disable=SC2015
_ji() { command -v jq &>/dev/null && jq -r ".${2} // 0" "$1" 2>/dev/null \
    || grep -o "\"${2}\":[[:space:]]*[0-9]*" "$1" 2>/dev/null \
    | grep -o '[0-9]*$' | head -1 || echo "0"; }

DATE=$(date '+%Y-%m-%d %H:%M')

# Sin ningun JSON VRT -> summary minimo
if [ ! -f "$BASELINE" ] && [ ! -f "$POST" ] && [ ! -f "$FINAL" ]; then
    printf "# VRT Summary -- %s\n\nVRT no ejecutado en este pipeline.\n" "$DATE" > "$SUMMARY"
    echo "  VRT no ejecutado -- summary generado: $SUMMARY"; exit 0
fi

# Seccion: Known Diffs
if [ -f "$BASELINE" ]; then
    KNOWN=$(command -v jq &>/dev/null && jq -r '.known_diffs[]? // empty' "$BASELINE" 2>/dev/null \
        | sed 's/^/- /' || echo "")
    [ -z "$KNOWN" ] && KNOWN="Ninguno detectado"
    SCENARIOS=$(_ji "$BASELINE" "scenarios_count")
    KNOWN_SECTION="$KNOWN\n\nEscenarios totales: $SCENARIOS"
else
    KNOWN_SECTION="No ejecutado"
fi

# Seccion: Post-modulos
if [ -f "$POST" ]; then
    POST_SECTION="$(_ji "$POST" regressions_new) regresiones nuevas / $(_ji "$POST" regressions_known) conocidas -- Estado: $(_jf "$POST" status)"
else
    POST_SECTION="No ejecutado"
fi

# Seccion: Final + estado global
if [ -f "$FINAL" ]; then
    NEW=$(_ji "$FINAL" regressions_new)
    FINAL_SECTION="$NEW regresiones nuevas / $(_ji "$FINAL" regressions_known) conocidas -- Estado: $(_jf "$FINAL" status)"
    [ "$NEW" -gt 0 ] && STATE_ICON="FAIL" || STATE_ICON="PASS"
else
    FINAL_SECTION="No ejecutado"
    [ -f "$BASELINE" ] && STATE_ICON="SKIP -- Baseline capturado, final no ejecutado" || STATE_ICON="SKIP -- VRT no ejecutado"
fi

# Links HTML de BackstopJS
HTML=""
for PHASE in baseline post-modules final; do
    [ -f "$REPORTS_DIR/vrt-${PHASE}.json" ] && [ -f "backstop_data/html_report/index.html" ] \
        && HTML="${HTML}- [${PHASE}](backstop_data/html_report/index.html)\n"
done
[ -z "$HTML" ] && HTML="No disponibles"

# Escribir vrt-summary.md
{
printf "# VRT Summary -- %s\n\n" "$DATE"
printf "## Known Diffs (Baseline PROD<->LOCAL)\n\n"
printf "%b\n\n" "$KNOWN_SECTION"
printf "## Regresiones Post-Modulos\n\n%s\n\n" "$POST_SECTION"
printf "## Regresiones Finales\n\n%s\n\n" "$FINAL_SECTION"
printf "## Estado Final\n\n%s\n\n" "$STATE_ICON"
printf "## Reportes HTML\n\n%b\n" "$HTML"
} > "$SUMMARY"

echo "  VRT summary generado: $SUMMARY"
echo "  Estado final: $STATE_ICON"
