#!/usr/bin/env bash
# =============================================================================
# paso-06c-custom-code-check.sh — Escaneo de compatibilidad de código custom
#
# Analiza módulos y temas custom para detectar:
#   - APIs deprecated/eliminadas en la versión objetivo de Drupal
#   - Incompatibilidades PHP con la versión requerida por el target
#   - Hooks procedurales que migran a atributos OOP (D11+)
#
# Puede ejecutarse de forma independiente o como parte del pipeline.
#
# Uso:
#   bash paso-06c-custom-code-check.sh                    # Scan completo
#   bash paso-06c-custom-code-check.sh --summary          # Solo resumen (sin details)
#   bash paso-06c-custom-code-check.sh --module foo_bar   # Solo un módulo
#
# Entrada:  paso-01-telemetria.json (versión actual Drupal y PHP)
#           paso-03-version-objetivo.json (versión objetivo)
#           paso-04-inventario-parches.json (lista de módulos/temas custom)
# Salida:   reports/drupal-update/paso-06c-custom-code.json
#
# Variables de entorno opcionales:
#   REPORT_DIR  — directorio de informes (default: reports/drupal-update)
#   SKILL_DIR   — raíz de la skill (auto-detectado si no se setea)
# =============================================================================

set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SKILL_DIR="${SKILL_DIR:-$(cd "$SCRIPT_DIR/.." && pwd)}"

REPORT_DIR="${REPORT_DIR:-reports/drupal-update}"
REPORT_FILE="$REPORT_DIR/paso-06c-custom-code.json"
mkdir -p "$REPORT_DIR"

SUMMARY_ONLY="false"
SINGLE_MODULE=""
while [ $# -gt 0 ]; do
    case "$1" in
        --summary)    SUMMARY_ONLY="true" ;;
        --module)     shift; SINGLE_MODULE="${1:-}" ;;
        --help|-h)
            echo "Uso:"
            echo "  paso-06c-custom-code-check.sh               Scan completo"
            echo "  paso-06c-custom-code-check.sh --summary      Solo resumen"
            echo "  paso-06c-custom-code-check.sh --module foo   Solo un módulo"
            exit 0
            ;;
        *) echo "  Warning: Argumento no reconocido: $1" ;;
    esac
    shift
done

echo ""
echo "══════════════════════════════════════════════════════"
echo "  PASO 6C — Análisis de Código Custom"
echo "══════════════════════════════════════════════════════"
echo ""

# --- Detectar docroot ---
# shellcheck source=/dev/null
source "$SKILL_DIR/scripts/detect-docroot.sh"

# --- Leer datos del pipeline (si existen) ---
TELE_FILE="$REPORT_DIR/paso-01-telemetria.json"
TARGET_FILE="$REPORT_DIR/paso-03-version-objetivo.json"
INVENTORY_FILE="$REPORT_DIR/paso-04-inventario-parches.json"

CURRENT_DRUPAL=""
CURRENT_PHP=""
TARGET_DRUPAL=""
TARGET_MAJOR=""

if [ -f "$TELE_FILE" ]; then
    CURRENT_DRUPAL=$(jq -r '.data.drupal.version // ""' "$TELE_FILE" 2>/dev/null)
    CURRENT_PHP=$(jq -r '.data.php.version // ""' "$TELE_FILE" 2>/dev/null)
fi

if [ -f "$TARGET_FILE" ]; then
    TARGET_DRUPAL=$(jq -r '.data.target_version // .target_version // ""' "$TARGET_FILE" 2>/dev/null)
    TARGET_MAJOR=$(echo "$TARGET_DRUPAL" | cut -d. -f1)
fi

# Si no hay datos del pipeline, intentar obtenerlos directamente
if [ -z "$CURRENT_DRUPAL" ]; then
    CURRENT_DRUPAL=$(ddev drush status --field=drupal-version 2>/dev/null || echo "unknown")
fi
if [ -z "$CURRENT_PHP" ]; then
    CURRENT_PHP=$(ddev php -r 'echo PHP_VERSION;' 2>/dev/null || echo "unknown")
fi
if [ -z "$TARGET_MAJOR" ] || [ -z "$TARGET_DRUPAL" ]; then
    # Sin versión objetivo → PREGUNTAR, no asumir la actual
    echo ""
    echo "  ⚠️  No se encontró versión objetivo en paso-03-version-objetivo.json."
    echo "     Opciones: ejecutar el pipeline desde Stage 1 para que se genere,"
    echo "     o indicar la versión objetivo manualmente."
    echo ""
    echo "     Ejemplo: la versión actual es $CURRENT_DRUPAL."
    echo "     Si el proyecto va a D11, el agente debe ejecutar Stage 1 primero."
    echo ""
    # Usar current + 1 como target: D10 → D11, D9 → D10
    CURRENT_MAJOR=$(echo "$CURRENT_DRUPAL" | cut -d. -f1)
    TARGET_MAJOR=$((CURRENT_MAJOR + 1))
    TARGET_DRUPAL="${TARGET_MAJOR}.0.0"
    echo "  → Asumiendo versión objetivo: D${TARGET_MAJOR} (${TARGET_DRUPAL})"
    echo "     Si esto es incorrecto, aborta y ejecuta el pipeline completo."
fi

# Validar que target != current (detectar error de configuración)
CURRENT_MAJOR=$(echo "$CURRENT_DRUPAL" | cut -d. -f1)
if [ "$TARGET_MAJOR" = "$CURRENT_MAJOR" ]; then
    echo ""
    echo "  ⚠️  La versión objetivo (D${TARGET_MAJOR}) es la misma que la actual (D${CURRENT_MAJOR})."
    echo "     El escaneo buscará deprecated genéricos, no incompatibilidades de salto mayor."
    echo "     Si se pretende un salto mayor, corregir paso-03-version-objetivo.json."
fi

echo "  Drupal actual:   $CURRENT_DRUPAL"
echo "  Drupal objetivo: $TARGET_DRUPAL (major: $TARGET_MAJOR)"
echo "  PHP actual:      $CURRENT_PHP"
echo ""

# --- Construir flag de drupal-check según versión objetivo ---
DRUPAL_CHECK_FLAG=""
case "$TARGET_MAJOR" in
    10) DRUPAL_CHECK_FLAG="--deprecations" ;;
    11) DRUPAL_CHECK_FLAG="--drupal-11" ;;
    *)  DRUPAL_CHECK_FLAG="--deprecations" ;;
esac

# --- Recoger listado de módulos y temas custom ---
CUSTOM_MODULES=()
CUSTOM_THEMES=()

if [ -n "$SINGLE_MODULE" ]; then
    # Modo single-module: buscar en ambas ubicaciones
    if [ -d "$DOCROOT/modules/custom/$SINGLE_MODULE" ]; then
        CUSTOM_MODULES=("$SINGLE_MODULE")
    elif [ -d "$DOCROOT/themes/custom/$SINGLE_MODULE" ]; then
        CUSTOM_THEMES=("$SINGLE_MODULE")
    else
        echo "  ⛔ Módulo/tema '$SINGLE_MODULE' no encontrado en custom."
        exit 1
    fi
else
    if [ -d "$DOCROOT/modules/custom" ]; then
        while IFS= read -r m; do
            [ -n "$m" ] && CUSTOM_MODULES+=("$m")
        done < <(find "$DOCROOT/modules/custom" -maxdepth 1 -mindepth 1 -type d -exec basename {} \; 2>/dev/null | sort)
    fi
    if [ -d "$DOCROOT/themes/custom" ]; then
        while IFS= read -r t; do
            [ -n "$t" ] && CUSTOM_THEMES+=("$t")
        done < <(find "$DOCROOT/themes/custom" -maxdepth 1 -mindepth 1 -type d -exec basename {} \; 2>/dev/null | sort)
    fi
fi

TOTAL_MODULES=${#CUSTOM_MODULES[@]}
TOTAL_THEMES=${#CUSTOM_THEMES[@]}
TOTAL=$((TOTAL_MODULES + TOTAL_THEMES))

echo "  Módulos custom: $TOTAL_MODULES"
echo "  Temas custom:   $TOTAL_THEMES"
echo ""

if [ "$TOTAL" -eq 0 ]; then
    echo "  ✅ No hay código custom — nada que analizar."
    cat > "$REPORT_FILE" << JSONEOF
{
  "step": "6c",
  "name": "custom_code_check",
  "timestamp": "$(date -Iseconds)",
  "status": "clean",
  "drupal_current": "$CURRENT_DRUPAL",
  "drupal_target": "$TARGET_DRUPAL",
  "php_version": "$CURRENT_PHP",
  "total_scanned": 0,
  "total_errors": 0,
  "total_warnings": 0,
  "findings": []
}
JSONEOF
    echo "  Reporte: $REPORT_FILE"
    exit 0
fi

# --- Verificar drupal-check está disponible ---
DRUPAL_CHECK_AVAILABLE="false"
if ddev exec which drupal-check > /dev/null 2>&1; then
    DRUPAL_CHECK_AVAILABLE="true"
    DRUPAL_CHECK_VERSION=$(ddev exec drupal-check --version 2>/dev/null || echo "unknown")
    echo "  drupal-check: $DRUPAL_CHECK_VERSION"
else
    echo "  ⚠️  drupal-check no instalado."
    echo "     Instalar con: ddev composer require --dev mglaman/drupal-check"
    echo "     Sin drupal-check solo se puede hacer análisis estructural básico."
fi

echo ""

# --- Función: escanear un directorio custom ---
# Genera JSON con findings por fichero
scan_extension() {
    local EXT_TYPE="$1"     # "module" o "theme"
    local EXT_NAME="$2"
    local EXT_PATH="$3"

    local FINDINGS_FILE
    FINDINGS_FILE=$(mktemp)
    echo '[]' > "$FINDINGS_FILE"
    local ERRORS=0
    local WARNINGS=0
    local FILE_COUNT
    FILE_COUNT=$(find "$EXT_PATH" -name '*.php' -o -name '*.module' -o -name '*.theme' -o -name '*.inc' -o -name '*.install' 2>/dev/null | wc -l | tr -d ' ')

    printf "  [%s] %-35s %s archivos PHP... " "$EXT_TYPE" "$EXT_NAME" "$FILE_COUNT"

    # --- drupal-check: deprecaciones ---
    if [ "$DRUPAL_CHECK_AVAILABLE" = "true" ]; then
        local DC_RAW DC_EXIT
        DC_RAW=$(ddev exec drupal-check "$DRUPAL_CHECK_FLAG" "$EXT_PATH" 2>&1) || DC_EXIT=$?
        DC_EXIT=${DC_EXIT:-0}

        # drupal-check usa PHPStan table format:
        #  ------ --------------------------------------------------------
        #   Line   path/to/file.php
        #  ------ --------------------------------------------------------
        #   45     Call to deprecated function entity_load()
        #  ------ --------------------------------------------------------
        #
        # También puede usar inline format:
        #   /path/file.php:45  MESSAGE
        #
        # Strategy: extraer de "Found N errors" primero (exit code y summary),
        # luego parsear líneas de detalle.

        local CURRENT_FILE=""

        while IFS= read -r line; do
            # PHPStan table: header line con nombre de fichero
            # Format: " Line   path/to/file.php" or " Line   path/to/file.module" etc.
            if echo "$line" | grep -qE '^\s+Line\s+.*\.(php|module|theme|inc|install)'; then
                CURRENT_FILE=$(echo "$line" | sed -E 's/^\s+Line\s+//')
                continue
            fi

            # PHPStan table: finding line — starts with a number
            # Format: "  45     Call to deprecated function..."
            if [ -n "$CURRENT_FILE" ] && echo "$line" | grep -qE '^\s+[0-9]+\s+'; then
                local line_num message severity
                line_num=$(echo "$line" | sed -E 's/^\s+//' | cut -d' ' -f1)
                message=$(echo "$line" | sed -E 's/^\s+[0-9]+\s+//')

                if echo "$message" | grep -qiE 'deprecated|removed|has been removed'; then
                    severity="error"
                    ERRORS=$((ERRORS + 1))
                else
                    severity="warning"
                    WARNINGS=$((WARNINGS + 1))
                fi

                local rel_file
                rel_file=$(echo "$CURRENT_FILE" | sed "s|.*$EXT_NAME/||")

                if [ "$SUMMARY_ONLY" != "true" ]; then
                    local TMP_F
                    TMP_F=$(mktemp)
                    jq --arg file "$rel_file" \
                        --arg line "$line_num" \
                        --arg msg "$message" \
                        --arg sev "$severity" \
                        --arg src "drupal-check" \
                        '. + [{file: $file, line: ($line | tonumber), message: $msg, severity: $sev, source: $src}]' \
                        "$FINDINGS_FILE" > "$TMP_F" 2>/dev/null && mv "$TMP_F" "$FINDINGS_FILE"
                fi
                continue
            fi

            # Inline format fallback: "  /path/file.php:45  MESSAGE"
            if echo "$line" | grep -qE '^\s+.*\.(php|module|theme|inc|install):[0-9]+\s'; then
                local file_match line_num message severity
                file_match=$(echo "$line" | sed -E 's/^\s+//' | cut -d: -f1)
                line_num=$(echo "$line" | sed -E 's/^\s+//' | grep -oE ':[0-9]+' | head -1 | tr -d ':')
                [ -z "$line_num" ] && line_num="0"
                message=$(echo "$line" | sed -E 's/^\s+[^ ]+\s+//')

                if echo "$message" | grep -qiE 'deprecated|removed|has been removed'; then
                    severity="error"
                    ERRORS=$((ERRORS + 1))
                else
                    severity="warning"
                    WARNINGS=$((WARNINGS + 1))
                fi

                local rel_file
                rel_file=$(echo "$file_match" | sed "s|.*$EXT_NAME/||")

                if [ "$SUMMARY_ONLY" != "true" ]; then
                    local TMP_F
                    TMP_F=$(mktemp)
                    jq --arg file "$rel_file" \
                        --arg line "$line_num" \
                        --arg msg "$message" \
                        --arg sev "$severity" \
                        --arg src "drupal-check" \
                        '. + [{file: $file, line: ($line | tonumber), message: $msg, severity: $sev, source: $src}]' \
                        "$FINDINGS_FILE" > "$TMP_F" 2>/dev/null && mv "$TMP_F" "$FINDINGS_FILE"
                fi
                continue
            fi

            # Divider line resets current file (end of table block)
            if echo "$line" | grep -qE '^\s+---'; then
                CURRENT_FILE=""
            fi
        done <<< "$DC_RAW"

        # Fallback: si drupal-check reportó errores en su resumen pero no los capturamos
        local SUMMARY_ERRORS
        SUMMARY_ERRORS=$(echo "$DC_RAW" | grep -oE 'Found [0-9]+ error' | grep -oE '[0-9]+' || echo "")
        if [ -n "$SUMMARY_ERRORS" ] && [ "$ERRORS" -eq 0 ]; then
            ERRORS=$((SUMMARY_ERRORS + 0))
            echo "" >&2
            echo "  ⚠️  drupal-check reportó $SUMMARY_ERRORS errores pero el parser no los capturó." >&2
            echo "     Verificar la salida raw manualmente." >&2
        fi
    fi

    # --- Análisis estructural: hooks procedurales que cambian en D11 ---
    if [ "$TARGET_MAJOR" = "11" ] || [ "${TARGET_MAJOR:-0}" -ge 11 ]; then
        local HOOK_HITS
        HOOK_HITS=$(grep -rnE "^function ${EXT_NAME}_(form_alter|preprocess|views_data|entity_|cron|install|update_[0-9])" "$EXT_PATH" 2>/dev/null || true)

        # template_preprocess_* no lleva el nombre del tema/módulo como prefijo
        local TPL_HITS
        TPL_HITS=$(grep -rnE "^function template_preprocess_" "$EXT_PATH" 2>/dev/null || true)
        if [ -n "$TPL_HITS" ]; then
            HOOK_HITS=$(printf '%s\n%s' "$HOOK_HITS" "$TPL_HITS")
        fi

        while IFS= read -r hit; do
            [ -z "$hit" ] && continue
            local hfile hline hmsg
            hfile=$(echo "$hit" | cut -d: -f1 | sed "s|.*$EXT_NAME/||")
            hline=$(echo "$hit" | cut -d: -f2)
            hmsg="Hook procedural detectado — en D11 considerar migrar a Hook attribute (OOP)"

            WARNINGS=$((WARNINGS + 1))
            if [ "$SUMMARY_ONLY" != "true" ]; then
                local TMP_F
                TMP_F=$(mktemp)
                jq --arg file "$hfile" \
                    --arg line "$hline" \
                    --arg msg "$hmsg" \
                    --arg sev "warning" \
                    --arg src "structural-analysis" \
                    '. + [{file: $file, line: ($line | tonumber), message: $msg, severity: $sev, source: $src}]' \
                    "$FINDINGS_FILE" > "$TMP_F" 2>/dev/null && mv "$TMP_F" "$FINDINGS_FILE"
            fi
        done <<< "$HOOK_HITS"

        # Temas: detectar base theme classy/stable (eliminados en D11)
        if [ "$EXT_TYPE" = "theme" ]; then
            local INFO_FILE="$EXT_PATH/$EXT_NAME.info.yml"
            if [ -f "$INFO_FILE" ]; then
                local BASE_THEME
                BASE_THEME=$(grep -E '^\s*base theme\s*:' "$INFO_FILE" 2>/dev/null | sed -E 's/.*:\s*//' | tr -d "'" | tr -d '"' | xargs)
                if [ "$BASE_THEME" = "classy" ] || [ "$BASE_THEME" = "stable" ]; then
                    local bt_line
                    bt_line=$(grep -nE '^\s*base theme\s*:' "$INFO_FILE" | head -1 | cut -d: -f1)
                    [ -z "$bt_line" ] && bt_line="0"
                    ERRORS=$((ERRORS + 1))
                    if [ "$SUMMARY_ONLY" != "true" ]; then
                        local TMP_F
                        TMP_F=$(mktemp)
                        jq --arg file "$EXT_NAME.info.yml" \
                            --arg line "$bt_line" \
                            --arg msg "Base theme '$BASE_THEME' eliminado en D11 — usar starterkit (php core/scripts/drupal generate-theme)" \
                            --arg sev "error" \
                            --arg src "structural-analysis" \
                            '. + [{file: $file, line: ($line | tonumber), message: $msg, severity: $sev, source: $src}]' \
                            "$FINDINGS_FILE" > "$TMP_F" 2>/dev/null && mv "$TMP_F" "$FINDINGS_FILE"
                    fi
                fi
            fi
        fi
    fi

    # Output
    if [ "$ERRORS" -gt 0 ]; then
        printf "❌ %d errores, %d warnings\n" "$ERRORS" "$WARNINGS"
    elif [ "$WARNINGS" -gt 0 ]; then
        printf "⚠️  %d warnings\n" "$WARNINGS"
    else
        printf "✅\n"
    fi

    # Devolver JSON del módulo — usar temp file, no in-memory jq pipe
    local FINAL_FINDINGS
    FINAL_FINDINGS=$(cat "$FINDINGS_FILE")
    rm -f "$FINDINGS_FILE"

    echo "$FINAL_FINDINGS" | jq \
        --arg name "$EXT_NAME" \
        --arg type "$EXT_TYPE" \
        --argjson errors "$ERRORS" \
        --argjson warnings "$WARNINGS" \
        --argjson files "$FILE_COUNT" \
        '{
            name: $name,
            type: $type,
            php_files: $files,
            errors: $errors,
            warnings: $warnings,
            findings: .
        }'
}

# --- Escanear todos los módulos y temas ---
echo "  Escaneando con flag: $DRUPAL_CHECK_FLAG"
echo ""

ALL_RESULTS="[]"
TOTAL_ERRORS=0
TOTAL_WARNINGS=0

for mod in "${CUSTOM_MODULES[@]+"${CUSTOM_MODULES[@]}"}"; do
    [ -z "$mod" ] && continue
    RESULT=$(scan_extension "module" "$mod" "$DOCROOT/modules/custom/$mod")
    MOD_ERRORS=$(echo "$RESULT" | jq '.errors')
    MOD_WARNINGS=$(echo "$RESULT" | jq '.warnings')
    TOTAL_ERRORS=$((TOTAL_ERRORS + MOD_ERRORS))
    TOTAL_WARNINGS=$((TOTAL_WARNINGS + MOD_WARNINGS))
    ALL_RESULTS=$(echo "$ALL_RESULTS" | jq --argjson r "$RESULT" '. + [$r]')
done

for thm in "${CUSTOM_THEMES[@]+"${CUSTOM_THEMES[@]}"}"; do
    [ -z "$thm" ] && continue
    RESULT=$(scan_extension "theme" "$thm" "$DOCROOT/themes/custom/$thm")
    THM_ERRORS=$(echo "$RESULT" | jq '.errors')
    THM_WARNINGS=$(echo "$RESULT" | jq '.warnings')
    TOTAL_ERRORS=$((TOTAL_ERRORS + THM_ERRORS))
    TOTAL_WARNINGS=$((TOTAL_WARNINGS + THM_WARNINGS))
    ALL_RESULTS=$(echo "$ALL_RESULTS" | jq --argjson r "$RESULT" '. + [$r]')
done

# --- Determinar status ---
STATUS="clean"
if [ "$TOTAL_ERRORS" -gt 0 ]; then
    STATUS="needs_fix"
elif [ "$TOTAL_WARNINGS" -gt 0 ]; then
    STATUS="has_warnings"
fi

# --- Generar reporte JSON ---
cat > "$REPORT_FILE" << JSONEOF
{
  "step": "6c",
  "name": "custom_code_check",
  "timestamp": "$(date -Iseconds)",
  "status": "$STATUS",
  "drupal_current": "$CURRENT_DRUPAL",
  "drupal_target": "$TARGET_DRUPAL",
  "php_version": "$CURRENT_PHP",
  "drupal_check_available": $DRUPAL_CHECK_AVAILABLE,
  "drupal_check_flag": "$DRUPAL_CHECK_FLAG",
  "total_scanned": $TOTAL,
  "total_errors": $TOTAL_ERRORS,
  "total_warnings": $TOTAL_WARNINGS,
  "extensions": $ALL_RESULTS
}
JSONEOF

# --- Resumen ---
echo ""
echo "  ┌────────────────────────────────────────┐"
echo "  │ Total escaneado:   $TOTAL ($TOTAL_MODULES módulos, $TOTAL_THEMES temas)"
echo "  │ Errores:           $TOTAL_ERRORS"
echo "  │ Warnings:          $TOTAL_WARNINGS"
echo "  │ Status:            $STATUS"
echo "  └────────────────────────────────────────┘"
echo ""
echo "  Reporte: $REPORT_FILE"

if [ "$STATUS" = "needs_fix" ]; then
    echo ""
    echo "  ⚠️  Se encontraron $TOTAL_ERRORS errores de compatibilidad."
    echo "     Estos deben resolverse ANTES de actualizar el core."
    echo "     El agente agent-custom-code-fixer puede aplicar las correcciones."
fi

exit 0
