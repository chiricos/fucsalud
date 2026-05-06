#!/usr/bin/env bash
# =============================================================================
# paso-01-telemetria.sh — Recopila el estado completo del entorno
# Uso: bash "$SKILL_DIR/scripts/paso-01-telemetria.sh"
# Genera: reports/drupal-update/paso-01-telemetria.json
# =============================================================================

set -uo pipefail

REPORT_DIR="reports/drupal-update"
REPORT_FILE="$REPORT_DIR/paso-01-telemetria.json"
mkdir -p "$REPORT_DIR"

# Detectar docroot del proyecto
SKILL_DIR="${SKILL_DIR:-$(cd "$(dirname "$0")/.." && pwd)}"
# shellcheck source=/dev/null
source "$SKILL_DIR/scripts/detect-docroot.sh"

echo "═══ Paso 1: Telemetría del Entorno ═══"
echo "  Docroot detectado: $DOCROOT"
echo ""

# --- Recopilar datos ---

# DDEV
echo "  Consultando DDEV..."
DDEV_JSON=$(ddev describe -j 2>/dev/null || echo '{}')
DDEV_STATUS=$(echo "$DDEV_JSON" | jq -r '.raw.status // .status // "unknown"' 2>/dev/null || echo "unknown")
DDEV_NAME=$(echo "$DDEV_JSON" | jq -r '.raw.name // .name // "unknown"' 2>/dev/null || echo "unknown")
DDEV_PHP=$(echo "$DDEV_JSON" | jq -r '.raw.php_version // .php_version // "unknown"' 2>/dev/null || echo "unknown")
DDEV_WEBSERVER=$(echo "$DDEV_JSON" | jq -r '.raw.webserver_type // .webserver_type // "unknown"' 2>/dev/null || echo "unknown")

# Base de datos: probar múltiples rutas en el JSON
DDEV_DBTYPE=$(echo "$DDEV_JSON" | jq -r '
    .raw.database.type //
    .raw.dbinfo.mariadb_version // 
    .raw.dbinfo.dbType //
    .database_type //
    "unknown"
' 2>/dev/null || echo "unknown")

DDEV_DBVER=$(echo "$DDEV_JSON" | jq -r '
    .raw.database.version //
    .raw.dbinfo.mariadb_version //
    .raw.dbinfo.mysql_version //  
    .database_version //
    "unknown"
' 2>/dev/null || echo "unknown")

# Si no se pudo extraer la BD del JSON, intentar via mysql
if [ "$DDEV_DBTYPE" = "unknown" ] || [ "$DDEV_DBVER" = "unknown" ]; then
    DB_VERSION_RAW=$(ddev mysql --version 2>/dev/null || ddev exec mysql --version 2>/dev/null || echo "")
    if echo "$DB_VERSION_RAW" | grep -qi "mariadb"; then
        DDEV_DBTYPE="mariadb"
        DDEV_DBVER=$(echo "$DB_VERSION_RAW" | grep -oE '[0-9]+\.[0-9]+\.[0-9]+' | head -1 || echo "unknown")
    elif [ -n "$DB_VERSION_RAW" ]; then
        DDEV_DBTYPE="mysql"
        DDEV_DBVER=$(echo "$DB_VERSION_RAW" | grep -oE '[0-9]+\.[0-9]+\.[0-9]+' | head -1 || echo "unknown")
    fi
fi

DDEV_URL=$(echo "$DDEV_JSON" | jq -r '.raw.primary_url // .primary_url // "unknown"' 2>/dev/null || echo "unknown")

# PHP (versión real dentro del contenedor)
echo "  Consultando PHP..."
PHP_VERSION=$(ddev exec php -r "echo PHP_MAJOR_VERSION.'.'.PHP_MINOR_VERSION.'.'.PHP_RELEASE_VERSION;" 2>/dev/null || echo "unknown")
PHP_MEMORY=$(ddev exec php -r "echo ini_get('memory_limit');" 2>/dev/null || echo "unknown")
PHP_MAXEXEC=$(ddev exec php -r "echo ini_get('max_execution_time');" 2>/dev/null || echo "unknown")

# Drupal via Drush
echo "  Consultando Drupal (Drush)..."
DRUSH_STATUS_JSON=$(ddev drush status --format=json 2>/dev/null || echo '{}')
DRUPAL_VERSION=$(echo "$DRUSH_STATUS_JSON" | jq -r '.["drupal-version"] // "unknown"' 2>/dev/null || echo "unknown")
DRUPAL_PROFILE=$(echo "$DRUSH_STATUS_JSON" | jq -r '.["install-profile"] // "unknown"' 2>/dev/null || echo "unknown")
DRUPAL_THEME=$(echo "$DRUSH_STATUS_JSON" | jq -r '.["theme"] // "unknown"' 2>/dev/null || echo "unknown")
DRUPAL_ADMIN_THEME=$(echo "$DRUSH_STATUS_JSON" | jq -r '.["admin-theme"] // "unknown"' 2>/dev/null || echo "unknown")
DRUPAL_CONFIG_SYNC=$(echo "$DRUSH_STATUS_JSON" | jq -r '.["config-sync"] // "unknown"' 2>/dev/null || echo "unknown")
DRUPAL_FILES=$(echo "$DRUSH_STATUS_JSON" | jq -r '.["files"] // "unknown"' 2>/dev/null || echo "unknown")

# Calcular major version
DRUPAL_MAJOR="0"
if [ "$DRUPAL_VERSION" != "unknown" ]; then
    DRUPAL_MAJOR=$(echo "$DRUPAL_VERSION" | cut -d. -f1)
fi

# Composer
echo "  Consultando Composer..."
COMPOSER_VERSION=$(ddev composer --version 2>/dev/null | sed -n 's/.*Composer version \([0-9][0-9]*\.[0-9][0-9]*\.[0-9][0-9]*\).*/\1/p' || echo "unknown")
if [ -z "$COMPOSER_VERSION" ]; then
    # Fallback: intentar extraer cualquier patrón x.y.z de la salida
    COMPOSER_VERSION=$(ddev composer --version 2>/dev/null | grep -oE '[0-9]+\.[0-9]+\.[0-9]+' | head -1 || echo "unknown")
fi
[ -z "$COMPOSER_VERSION" ] && COMPOSER_VERSION="unknown"

# Drush
echo "  Consultando Drush..."
DRUSH_VERSION=$(ddev drush version 2>/dev/null | grep -oE '[0-9]+\.[0-9]+\.[0-9]+' | head -1 || echo "unknown")
[ -z "$DRUSH_VERSION" ] && DRUSH_VERSION="unknown"

# Git
echo "  Consultando Git..."
GIT_BRANCH=$(git branch --show-current 2>/dev/null || echo "N/A")
GIT_DIRTY=$(git status --porcelain 2>/dev/null | wc -l | tr -d ' ')
GIT_CLEAN="true"
if [ "$GIT_DIRTY" -gt 0 ] 2>/dev/null; then
    GIT_CLEAN="false"
fi

# --- Validaciones ---

OVERALL_STATUS="ok"
WARNINGS="[]"
BLOCKERS="[]"

if [ "$DDEV_STATUS" != "running" ]; then
    BLOCKERS=$(echo "$BLOCKERS" | jq '. + ["DDEV no está activo. Ejecuta ddev start."]')
    OVERALL_STATUS="error"
fi

if [ "$GIT_CLEAN" = "false" ]; then
    WARNINGS=$(echo "$WARNINGS" | jq --arg n "$GIT_DIRTY" '. + ["Hay " + $n + " archivo(s) sin commit. Recomendamos commit o stash."]')
    if [ "$OVERALL_STATUS" = "ok" ]; then OVERALL_STATUS="warning"; fi
fi

if [ "$PHP_VERSION" != "unknown" ]; then
    PHP_MAJOR=$(echo "$PHP_VERSION" | cut -d. -f1)
    PHP_MINOR=$(echo "$PHP_VERSION" | cut -d. -f2)
    if [ "$PHP_MAJOR" -lt 8 ] 2>/dev/null || { [ "$PHP_MAJOR" -eq 8 ] && [ "$PHP_MINOR" -lt 1 ]; } 2>/dev/null; then
        BLOCKERS=$(echo "$BLOCKERS" | jq --arg v "$PHP_VERSION" '. + ["PHP " + $v + " no soporta Drupal 10+. Se requiere PHP 8.1+."]')
        OVERALL_STATUS="error"
    fi
fi

# --- Generar reporte JSON ---

cat > "$REPORT_FILE" << JSONEOF
{
  "step": 1,
  "name": "telemetria",
  "timestamp": "$(date -Iseconds)",
  "status": "$OVERALL_STATUS",
  "data": {
    "docroot": "$DOCROOT",
    "ddev": {
      "status": "$DDEV_STATUS",
      "name": "$DDEV_NAME",
      "php_version": "$DDEV_PHP",
      "webserver": "$DDEV_WEBSERVER",
      "database": "$DDEV_DBTYPE",
      "db_version": "$DDEV_DBVER",
      "router_url": "$DDEV_URL"
    },
    "drupal": {
      "version": "$DRUPAL_VERSION",
      "major": $DRUPAL_MAJOR,
      "profile": "$DRUPAL_PROFILE",
      "theme_default": "$DRUPAL_THEME",
      "theme_admin": "$DRUPAL_ADMIN_THEME",
      "config_sync": "$DRUPAL_CONFIG_SYNC",
      "files_path": "$DRUPAL_FILES"
    },
    "composer": {
      "version": "$COMPOSER_VERSION"
    },
    "drush": {
      "version": "$DRUSH_VERSION"
    },
    "php": {
      "version": "$PHP_VERSION",
      "memory_limit": "$PHP_MEMORY",
      "max_execution_time": "$PHP_MAXEXEC"
    },
    "git": {
      "branch": "$GIT_BRANCH",
      "dirty_files": $GIT_DIRTY,
      "clean": $GIT_CLEAN
    }
  },
  "warnings": $WARNINGS,
  "blockers": $BLOCKERS
}
JSONEOF

# --- Mostrar resumen ---

echo ""
echo "  ┌────────────────────────────────────┐"
echo "  │ DDEV:     $DDEV_STATUS ($DDEV_NAME)"
echo "  │ Drupal:   $DRUPAL_VERSION (major: $DRUPAL_MAJOR)"
echo "  │ PHP:      $PHP_VERSION"
echo "  │ Composer: $COMPOSER_VERSION"
echo "  │ Drush:    $DRUSH_VERSION"
echo "  │ Git:      $GIT_BRANCH (dirty: $GIT_DIRTY)"
echo "  │ Status:   $OVERALL_STATUS"
echo "  └────────────────────────────────────┘"
echo ""
echo "  Reporte guardado en: $REPORT_FILE"

# Salir con error si hay blockers
BLOCKER_COUNT=$(echo "$BLOCKERS" | jq 'length')
if [ "$BLOCKER_COUNT" -gt 0 ]; then
    echo ""
    echo "  ⛔ HAY $BLOCKER_COUNT BLOCKER(S). No se puede continuar."
    echo "$BLOCKERS" | jq -r '.[] | "     → " + .'
    exit 1
fi

exit 0
