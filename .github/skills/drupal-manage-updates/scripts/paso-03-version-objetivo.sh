#!/usr/bin/env bash
# =============================================================================
# paso-03-version-objetivo.sh — Determina la versión objetivo de Drupal
# Lee paso-01-telemetria.json y decide el salto recomendado
# Genera: reports/drupal-update/paso-03-version-objetivo.json
#
# Flags:
#   --major-jump    Permite saltos mayores (D10→D11) si ya estás en última minor
#   --force-major   Fuerza salto mayor incluso si no estás en última minor (RIESGO)
# =============================================================================

set -uo pipefail

# Parsear argumentos
ALLOW_MAJOR_JUMP="false"
FORCE_MAJOR_JUMP="false"

for arg in "$@"; do
    case "$arg" in
        --major-jump)
            ALLOW_MAJOR_JUMP="true"
            ;;
        --force-major)
            FORCE_MAJOR_JUMP="true"
            ALLOW_MAJOR_JUMP="true"  # force-major implica allow-major
            ;;
    esac
done

REPORT_DIR="reports/drupal-update"
REPORT_FILE="$REPORT_DIR/paso-03-version-objetivo.json"
TELE_FILE="$REPORT_DIR/paso-01-telemetria.json"
mkdir -p "$REPORT_DIR"

echo "═══ Paso 3: Versión Objetivo ═══"
echo ""

# Leer telemetría
if [ ! -f "$TELE_FILE" ]; then
    echo "  ⛔ No se encontró $TELE_FILE. Ejecuta el paso 1 primero."
    exit 1
fi

DRUPAL_VERSION=$(jq -r '.data.drupal.version' "$TELE_FILE")
DRUPAL_MAJOR=$(jq -r '.data.drupal.major' "$TELE_FILE")
PHP_VERSION=$(jq -r '.data.php.version' "$TELE_FILE")
PHP_MAJOR=$(echo "$PHP_VERSION" | cut -d. -f1)
PHP_MINOR=$(echo "$PHP_VERSION" | cut -d. -f2)

echo "  Drupal actual: $DRUPAL_VERSION (major: $DRUPAL_MAJOR)"
echo "  PHP actual:    $PHP_VERSION"

# Consultar última versión estable de Drupal (limpiar Deprecation Notices)
echo "  Consultando últimas versiones estables..."
RAW_CORE=$(ddev composer show drupal/core-recommended --all --format=json 2>/dev/null || echo '')
CLEAN_CORE=$(echo "$RAW_CORE" | sed -n '/^{/,/^}/p')
LATEST_D9=$(echo "$CLEAN_CORE" | jq -r '.versions[]' 2>/dev/null | grep -E '^9\.' | grep -v 'dev\|alpha\|beta\|rc' | sort -V | tail -1 || echo "")
LATEST_D10=$(echo "$CLEAN_CORE" | jq -r '.versions[]' 2>/dev/null | grep -E '^10\.' | grep -v 'dev\|alpha\|beta\|rc' | sort -V | tail -1 || echo "")
LATEST_D11=$(echo "$CLEAN_CORE" | jq -r '.versions[]' 2>/dev/null | grep -E '^11\.' | grep -v 'dev\|alpha\|beta\|rc' | sort -V | tail -1 || echo "")

# Determinar versión objetivo
TARGET=""
JUMP_TYPE=""
PHP_OK="true"
PHP_ACTION=""
DRUSH_TARGET=""
WARNINGS="[]"
NEXT_MAJOR_AVAILABLE=""
READY_FOR_MAJOR_JUMP="false"
UPGRADE_STRATEGY=""

case "$DRUPAL_MAJOR" in
    9)
        # Extraer versión minor actual
        CURRENT_MINOR=$(echo "$DRUPAL_VERSION" | cut -d. -f2)
        LATEST_D9_MINOR=$(echo "${LATEST_D9:-9.5.11}" | cut -d. -f2)

        # ¿Ya estamos en la última minor de D9?
        if [ "$CURRENT_MINOR" -ge "$LATEST_D9_MINOR" ]; then
            READY_FOR_MAJOR_JUMP="true"
        fi

        # Lógica de decisión
        if [ "$READY_FOR_MAJOR_JUMP" = "true" ] && [ "$ALLOW_MAJOR_JUMP" = "true" ]; then
            # Ya en última D9 y usuario permite salto mayor
            if [ "$PHP_MAJOR" -eq 8 ] && [ "$PHP_MINOR" -ge 2 ]; then
                TARGET="${LATEST_D10:-10.4.0}"
                JUMP_TYPE="major (D9→D10)"
                DRUSH_TARGET="^12.5"
                UPGRADE_STRATEGY="major_jump_approved"
            elif [ "$PHP_MAJOR" -eq 8 ] && [ "$PHP_MINOR" -eq 1 ]; then
                TARGET="10.2.9"
                JUMP_TYPE="major (D9→D10, PHP limitado)"
                DRUSH_TARGET="^12"
                PHP_OK="false"
                PHP_ACTION="Subir a PHP 8.2+ para acceder a Drupal 10.3+"
                UPGRADE_STRATEGY="major_jump_approved"
                WARNINGS=$(echo "$WARNINGS" | jq '. + ["PHP 8.1 limita a Drupal 10.2.x. Recomendamos subir PHP."]')
            else
                echo "  ⛔ PHP $PHP_VERSION no soporta Drupal 10"
                TARGET="none"
                JUMP_TYPE="blocked"
                PHP_OK="false"
                PHP_ACTION="Subir a PHP 8.1+ mínimo, 8.2+ recomendado"
                UPGRADE_STRATEGY="blocked"
            fi
        elif [ "$READY_FOR_MAJOR_JUMP" = "false" ] && [ "$FORCE_MAJOR_JUMP" = "true" ]; then
            # Usuario fuerza salto sin estar en última minor (RIESGO)
            if [ "$PHP_MAJOR" -eq 8 ] && [ "$PHP_MINOR" -ge 2 ]; then
                TARGET="${LATEST_D10:-10.4.0}"
                JUMP_TYPE="major (D9→D10, FORZADO)"
                DRUSH_TARGET="^12.5"
                UPGRADE_STRATEGY="major_jump_forced"
                WARNINGS=$(echo "$WARNINGS" | jq '. + ["⚠️ RIESGO: Saltando a D10 sin estar en última minor de D9 ('"${LATEST_D9}"'). Se recomienda actualizar primero a D9.'"$LATEST_D9_MINOR"'"]')
            elif [ "$PHP_MAJOR" -eq 8 ] && [ "$PHP_MINOR" -eq 1 ]; then
                TARGET="10.2.9"
                JUMP_TYPE="major (D9→D10, FORZADO, PHP limitado)"
                DRUSH_TARGET="^12"
                PHP_OK="false"
                PHP_ACTION="Subir a PHP 8.2+ para acceder a Drupal 10.3+"
                UPGRADE_STRATEGY="major_jump_forced"
                WARNINGS=$(echo "$WARNINGS" | jq '. + ["⚠️ RIESGO: Saltando a D10 sin estar en D9.'"$LATEST_D9_MINOR"'", "PHP 8.1 limita a Drupal 10.2.x. Recomendamos subir PHP."]')
            else
                echo "  ⛔ PHP $PHP_VERSION no soporta Drupal 10"
                TARGET="none"
                JUMP_TYPE="blocked"
                PHP_OK="false"
                PHP_ACTION="Subir a PHP 8.1+ mínimo, 8.2+ recomendado"
                UPGRADE_STRATEGY="blocked"
            fi
        else
            # Estrategia por defecto: actualizar a última minor de D9 primero
            TARGET="${LATEST_D9:-9.5.11}"
            JUMP_TYPE="minor/patch"
            DRUSH_TARGET="^11.6"
            UPGRADE_STRATEGY="incremental_minor_first"

            # Informar que hay D10 disponible después
            if [ -n "$LATEST_D10" ]; then
                NEXT_MAJOR_AVAILABLE="$LATEST_D10"
                if [ "$READY_FOR_MAJOR_JUMP" = "true" ]; then
                    WARNINGS=$(echo "$WARNINGS" | jq '. + ["Ya estás en última minor de D9. Usa --major-jump para actualizar a D10."]')
                else
                    WARNINGS=$(echo "$WARNINGS" | jq '. + ["Drupal 10 disponible. Actualiza primero a D9.'"$LATEST_D9_MINOR"', luego a D10 con --major-jump"]')
                fi
            fi
        fi
        ;;
    10)
        # Extraer versión minor actual
        CURRENT_MINOR=$(echo "$DRUPAL_VERSION" | cut -d. -f2)
        LATEST_D10_MINOR=$(echo "${LATEST_D10:-10.4.0}" | cut -d. -f2)

        # ¿Ya estamos en la última minor de D10?
        if [ "$CURRENT_MINOR" -ge "$LATEST_D10_MINOR" ]; then
            READY_FOR_MAJOR_JUMP="true"
        fi

        # Lógica de decisión
        if [ "$READY_FOR_MAJOR_JUMP" = "true" ] && [ "$ALLOW_MAJOR_JUMP" = "true" ]; then
            # Ya en última D10 y usuario permite salto mayor
            if [ "$PHP_MAJOR" -eq 8 ] && [ "$PHP_MINOR" -ge 3 ] && [ -n "$LATEST_D11" ]; then
                TARGET="$LATEST_D11"
                JUMP_TYPE="major (D10→D11)"
                DRUSH_TARGET="^13"
                UPGRADE_STRATEGY="major_jump_approved"
            else
                # PHP no cumple para D11
                TARGET="${LATEST_D10:-10.4.0}"
                JUMP_TYPE="minor/patch"
                DRUSH_TARGET="^12.5"
                UPGRADE_STRATEGY="minor_update_only"
                if [ "$PHP_MINOR" -lt 3 ]; then
                    PHP_OK="warning"
                    PHP_ACTION="Subir a PHP 8.3+ para Drupal 11"
                    WARNINGS=$(echo "$WARNINGS" | jq '. + ["PHP 8.3+ requerido para Drupal 11. Actualmente: '"$PHP_VERSION"'"]')
                fi
                NEXT_MAJOR_AVAILABLE="$LATEST_D11"
            fi
        elif [ "$READY_FOR_MAJOR_JUMP" = "false" ] && [ "$FORCE_MAJOR_JUMP" = "true" ]; then
            # Usuario fuerza salto sin estar en última minor (RIESGO)
            if [ "$PHP_MAJOR" -eq 8 ] && [ "$PHP_MINOR" -ge 3 ] && [ -n "$LATEST_D11" ]; then
                TARGET="$LATEST_D11"
                JUMP_TYPE="major (D10→D11, FORZADO)"
                DRUSH_TARGET="^13"
                UPGRADE_STRATEGY="major_jump_forced"
                WARNINGS=$(echo "$WARNINGS" | jq '. + ["⚠️ RIESGO: Saltando a D11 sin estar en última minor de D10 ('"${LATEST_D10}"'). Se recomienda actualizar primero a D10.'"$LATEST_D10_MINOR"'.x"]')
            fi
        else
            # Estrategia por defecto: actualizar a última minor de D10 primero
            TARGET="${LATEST_D10:-10.4.0}"
            JUMP_TYPE="minor/patch"
            DRUSH_TARGET="^12.5"
            UPGRADE_STRATEGY="incremental_minor_first"

            if [ "$PHP_MINOR" -lt 2 ]; then
                PHP_OK="false"
                PHP_ACTION="Subir a PHP 8.2+ para Drupal 10.3+"
            fi

            # Informar que hay D11 disponible después
            if [ -n "$LATEST_D11" ]; then
                NEXT_MAJOR_AVAILABLE="$LATEST_D11"
                if [ "$READY_FOR_MAJOR_JUMP" = "true" ]; then
                    WARNINGS=$(echo "$WARNINGS" | jq '. + ["Ya estás en última minor de D10. Usa --major-jump para actualizar a D11."]')
                else
                    WARNINGS=$(echo "$WARNINGS" | jq '. + ["Drupal 11 disponible. Actualiza primero a D10.'"$LATEST_D10_MINOR"', luego a D11 con --major-jump"]')
                fi
            fi
        fi
        ;;
    11)
        TARGET="${LATEST_D11:-11.0.0}"
        JUMP_TYPE="minor/patch"
        DRUSH_TARGET="^13"
        UPGRADE_STRATEGY="minor_update_only"
        ;;
    *)
        echo "  ⛔ Versión de Drupal no reconocida: $DRUPAL_MAJOR"
        TARGET="none"
        JUMP_TYPE="unknown"
        UPGRADE_STRATEGY="unknown"
        ;;
esac

# Generar reporte usando jq para mayor robustez
jq -n \
  --arg step "3" \
  --arg name "version_objetivo" \
  --arg timestamp "$(date -Iseconds)" \
  --arg status "$([ "$TARGET" = "none" ] && echo "blocked" || echo "ok")" \
  --arg current_version "$DRUPAL_VERSION" \
  --argjson current_major "$DRUPAL_MAJOR" \
  --arg target_version "$TARGET" \
  --arg jump_type "$JUMP_TYPE" \
  --arg upgrade_strategy "$UPGRADE_STRATEGY" \
  --argjson ready_for_major_jump "$READY_FOR_MAJOR_JUMP" \
  --arg next_major_available "$NEXT_MAJOR_AVAILABLE" \
  --arg php_version "$PHP_VERSION" \
  --arg php_ok "$PHP_OK" \
  --arg php_action "$PHP_ACTION" \
  --arg drush_target "$DRUSH_TARGET" \
  --arg latest_d9 "$LATEST_D9" \
  --arg latest_d10 "$LATEST_D10" \
  --arg latest_d11 "$LATEST_D11" \
  --argjson allow_major_jump "$ALLOW_MAJOR_JUMP" \
  --argjson force_major_jump "$FORCE_MAJOR_JUMP" \
  --argjson warnings "$WARNINGS" \
  '{
    step: ($step | tonumber),
    name: $name,
    timestamp: $timestamp,
    status: $status,
    data: {
      current_version: $current_version,
      current_major: $current_major,
      target_version: $target_version,
      jump_type: $jump_type,
      upgrade_strategy: $upgrade_strategy,
      ready_for_major_jump: $ready_for_major_jump,
      next_major_available: (if $next_major_available == "" then null else $next_major_available end),
      php_version: $php_version,
      php_adequate: (if $php_ok == "true" then true elif $php_ok == "false" then false else $php_ok end),
      php_action_needed: (if $php_action == "" then null else $php_action end),
      drush_target: $drush_target,
      latest_d9: $latest_d9,
      latest_d10: $latest_d10,
      latest_d11: $latest_d11,
      flags: {
        allow_major_jump: $allow_major_jump,
        force_major_jump: $force_major_jump
      }
    },
    warnings: $warnings
  }' > "$REPORT_FILE"

echo ""
echo "  ╔════════════════════════════════════════════════════╗"
echo "  ║ VERSIÓN OBJETIVO                                   ║"
echo "  ╠════════════════════════════════════════════════════╣"
echo "  ║ Actual:        Drupal $DRUPAL_VERSION"
echo "  ║ Objetivo:      Drupal $TARGET"
echo "  ║ Tipo salto:    $JUMP_TYPE"
echo "  ║ Estrategia:    $UPGRADE_STRATEGY"
echo "  ║ PHP OK:        $PHP_OK"
echo "  ║ Drush target:  $DRUSH_TARGET"
if [ -n "$NEXT_MAJOR_AVAILABLE" ]; then
echo "  ║ ──────────────────────────────────────────────────  ║"
echo "  ║ 📌 Drupal $NEXT_MAJOR_AVAILABLE disponible después de completar D10"
fi
if [ "$READY_FOR_MAJOR_JUMP" = "true" ] && [ "$ALLOW_MAJOR_JUMP" = "false" ]; then
echo "  ║ ──────────────────────────────────────────────────  ║"
echo "  ║ ✅ Listo para salto mayor. Usa --major-jump        ║"
fi
echo "  ╚════════════════════════════════════════════════════╝"
echo ""

# Mostrar warnings si existen
if [ "$(echo "$WARNINGS" | jq 'length')" -gt 0 ]; then
    echo "  ⚠️  ADVERTENCIAS:"
    echo "$WARNINGS" | jq -r '.[]' | while read -r warning; do
        echo "      • $warning"
    done
    echo ""
fi

echo "  Reporte guardado en: $REPORT_FILE"

[ "$TARGET" = "none" ] && exit 1 || exit 0