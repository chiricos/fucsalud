#!/usr/bin/env bash
# =============================================================================
# preflight.sh — Verificación rápida de prerrequisitos
# Uso: bash scripts/preflight.sh
# Retorna: 0 si todo OK, 1 si hay blockers
# =============================================================================

set -euo pipefail

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

BLOCKERS=0
WARNINGS=0

echo "══════════════════════════════════════════"
echo "  DRUPAL UPDATE — Pre-Flight Check"
echo "══════════════════════════════════════════"
echo ""

# 1. ¿DDEV está instalado?
if ! command -v ddev &> /dev/null; then
    echo -e "${RED}✗ DDEV no está instalado${NC}"
    BLOCKERS=$((BLOCKERS + 1))
else
    DDEV_VER=$(ddev version 2>/dev/null | head -1 | awk '{print $NF}')
    echo -e "${GREEN}✓ DDEV instalado (${DDEV_VER})${NC}"
fi

# 2. ¿DDEV está corriendo?
DDEV_STATUS=$(ddev describe -j 2>/dev/null | jq -r '.raw.status' 2>/dev/null || echo "stopped")
if [ "$DDEV_STATUS" != "running" ]; then
    echo -e "${RED}✗ DDEV no está activo (status: $DDEV_STATUS). Ejecuta 'ddev start'${NC}"
    BLOCKERS=$((BLOCKERS + 1))
else
    DDEV_NAME=$(ddev describe -j 2>/dev/null | jq -r '.raw.name' 2>/dev/null || echo "unknown")
    echo -e "${GREEN}✓ DDEV activo (proyecto: $DDEV_NAME)${NC}"
fi

# 3. ¿Existe composer.json?
if [ ! -f "composer.json" ]; then
    echo -e "${RED}✗ No se encuentra composer.json en el directorio actual${NC}"
    BLOCKERS=$((BLOCKERS + 1))
else
    echo -e "${GREEN}✓ composer.json encontrado${NC}"
fi

# 4. ¿Es un proyecto Drupal?
if [ -f "composer.json" ]; then
    IS_DRUPAL=$(cat composer.json | jq -r '.require["drupal/core-recommended"] // .require["drupal/core"] // "not-found"' 2>/dev/null)
    if [ "$IS_DRUPAL" = "not-found" ]; then
        echo -e "${RED}✗ No parece un proyecto Drupal (no se encuentra drupal/core en composer.json)${NC}"
        BLOCKERS=$((BLOCKERS + 1))
    else
        echo -e "${GREEN}✓ Proyecto Drupal detectado (constraint: $IS_DRUPAL)${NC}"
    fi
fi

# 5. ¿Drush está disponible?
if ddev drush version &> /dev/null; then
    DRUSH_VER=$(ddev drush version --format=string 2>/dev/null || echo "unknown")
    echo -e "${GREEN}✓ Drush disponible (v$DRUSH_VER)${NC}"
else
    echo -e "${RED}✗ Drush no está disponible${NC}"
    BLOCKERS=$((BLOCKERS + 1))
fi

# 6. ¿Drupal está bootstrapped?
if [ "$DDEV_STATUS" = "running" ]; then
    BOOTSTRAP=$(ddev drush status --field=bootstrap 2>/dev/null || echo "failed")
    if [ "$BOOTSTRAP" = "Successful" ]; then
        DRUPAL_VER=$(ddev drush status --field=drupal-version 2>/dev/null || echo "unknown")
        echo -e "${GREEN}✓ Drupal bootstrap OK (v$DRUPAL_VER)${NC}"
    else
        echo -e "${RED}✗ Drupal no puede arrancar (bootstrap: $BOOTSTRAP)${NC}"
        BLOCKERS=$((BLOCKERS + 1))
    fi
fi

# 7. ¿Git está limpio?
if command -v git &> /dev/null && git rev-parse --git-dir &> /dev/null; then
    DIRTY=$(git status --porcelain 2>/dev/null | wc -l)
    BRANCH=$(git branch --show-current 2>/dev/null || echo "detached")
    if [ "$DIRTY" -gt 0 ]; then
        echo -e "${YELLOW}⚠ Git tiene $DIRTY archivo(s) sin commit (branch: $BRANCH)${NC}"
        WARNINGS=$((WARNINGS + 1))
    else
        echo -e "${GREEN}✓ Git limpio (branch: $BRANCH)${NC}"
    fi
else
    echo -e "${YELLOW}⚠ No es un repositorio Git o Git no está instalado${NC}"
    WARNINGS=$((WARNINGS + 1))
fi

# 8. ¿jq está disponible? (necesario para parsear JSON)
if ! command -v jq &> /dev/null; then
    echo -e "${YELLOW}⚠ jq no está instalado. Los reportes JSON no se podrán parsear localmente${NC}"
    WARNINGS=$((WARNINGS + 1))
else
    echo -e "${GREEN}✓ jq disponible${NC}"
fi

# 9. Verificar PHP
if [ "$DDEV_STATUS" = "running" ]; then
    PHP_VER=$(ddev exec php -r "echo PHP_MAJOR_VERSION.'.'.PHP_MINOR_VERSION;" 2>/dev/null || echo "unknown")
    if [ "$PHP_VER" != "unknown" ]; then
        PHP_MAJOR=$(echo "$PHP_VER" | cut -d. -f1)
        PHP_MINOR=$(echo "$PHP_VER" | cut -d. -f2)
        if [ "$PHP_MAJOR" -lt 8 ] || { [ "$PHP_MAJOR" -eq 8 ] && [ "$PHP_MINOR" -lt 1 ]; }; then
            echo -e "${RED}✗ PHP $PHP_VER no soporta Drupal 10+ (mínimo 8.1)${NC}"
            BLOCKERS=$((BLOCKERS + 1))
        else
            echo -e "${GREEN}✓ PHP $PHP_VER${NC}"
        fi
    fi
fi

# 10. Espacio en disco
DISK_AVAIL=$(df -BM . 2>/dev/null | tail -1 | awk '{print $4}' | tr -d 'M')
if [ -n "$DISK_AVAIL" ] && [ "$DISK_AVAIL" -lt 1024 ]; then
    echo -e "${YELLOW}⚠ Poco espacio en disco (${DISK_AVAIL}MB disponibles). Se recomienda > 1GB${NC}"
    WARNINGS=$((WARNINGS + 1))
else
    echo -e "${GREEN}✓ Espacio en disco OK${NC}"
fi

# 11. Conectividad con drupal.org
if curl -sf --max-time 5 https://updates.drupal.org/release-history/drupal/current > /dev/null 2>&1; then
    echo -e "${GREEN}✓ drupal.org accesible${NC}"
else
    echo -e "${YELLOW}⚠ drupal.org no accesible (paso-05 consultara API con timeout mayor)${NC}"
    WARNINGS=$((WARNINGS + 1))
fi

# Resumen
echo ""
echo "══════════════════════════════════════════"
if [ "$BLOCKERS" -gt 0 ]; then
    echo -e "${RED}  RESULTADO: $BLOCKERS BLOCKER(S), $WARNINGS WARNING(S)${NC}"
    echo -e "${RED}  No se puede continuar hasta resolver los blockers.${NC}"
    exit 1
elif [ "$WARNINGS" -gt 0 ]; then
    echo -e "${YELLOW}  RESULTADO: OK con $WARNINGS WARNING(S)${NC}"
    echo -e "${YELLOW}  Se puede continuar, pero revisa los warnings.${NC}"
    exit 0
else
    echo -e "${GREEN}  RESULTADO: TODO OK ✓${NC}"
    echo -e "${GREEN}  Listo para iniciar la actualización.${NC}"
    exit 0
fi
