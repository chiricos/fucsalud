#!/usr/bin/env bash
# =============================================================================
# paso-04-prep-modulos.sh — Preparación Exhaustiva de Drupal para tests
# Uso: bash "$SKILL_DIR/scripts/paso-04-prep-modulos.sh" [site_uri] [--uninstall]
#
# ⚠️  IMPORTANTE: Este script usa `drush pm:uninstall`, que ELIMINA la configuración
#     del módulo en base de datos. Tras los tests, reinstala los módulos con
#     `drush pm:install <módulo>` y reimporta config: `drush config:import -y`.
#     Drupal 8+ no dispone de pm:disable; pm:uninstall es la única opción.
# =============================================================================

SITE_URI=$1
UNINSTALL_FLAG=$2

if [ -z "$SITE_URI" ] || [[ "$SITE_URI" == "--uninstall" ]]; then
    echo "ℹ️ No se especificó URI válida, usando sitio por defecto."
    DRUSH_CMD="ddev drush"
    [ "$SITE_URI" == "--uninstall" ] && UNINSTALL_FLAG="--uninstall"
else
    echo "🌐 Sitio objetivo: $SITE_URI"
    DRUSH_CMD="ddev drush --uri=$SITE_URI"
fi

echo "🛡️ Fase 0: Verificación de Seguridad y Anti-spam..."

# 1. Detectar módulos vía composer (más exhaustivo)
echo "📦 Buscando módulos en composer.json..."
COMPOSER_MODULES=$(ddev composer show | grep -E "captcha|antibot|honeypot|recaptcha|shield|cookiebot|hcaptcha" | awk '{print $1}' | sed 's/drupal\///')

# 2. Verificar cuáles están activos en el sitio
MODULOS_ACTIVOS=()
PM_LIST_JSON=$($DRUSH_CMD pm:list --type=module --status=enabled --format=json 2>/dev/null)

if [ -n "$PM_LIST_JSON" ]; then
    for mod in $COMPOSER_MODULES "captcha" "honeypot" "antibot" "recaptcha" "shield" "image_captcha"; do
        is_enabled=$(echo "$PM_LIST_JSON" | MOD_NAME="$mod" python3 -c "
import sys, json, os
mod = os.environ['MOD_NAME']
data = json.load(sys.stdin)
print('Enabled' if any(m.get('name') == mod and m.get('status') == 'Enabled' for m in data.values()) else 'Disabled')
")
        if [ "$is_enabled" == "Enabled" ]; then
            # Evitar duplicados
            [[ ! " ${MODULOS_ACTIVOS[@]} " =~ " ${mod} " ]] && MODULOS_ACTIVOS+=("$mod")
        fi
    done
fi

if [ ${#MODULOS_ACTIVOS[@]} -gt 0 ]; then
    echo "⚠️ Módulos BLOQUEANTES detectADOS: ${MODULOS_ACTIVOS[*]}"
    if [ "$UNINSTALL_FLAG" == "--uninstall" ]; then
        echo "🗑️ Desinstalando módulos..."
        $DRUSH_CMD pm:uninstall "${MODULOS_ACTIVOS[@]}" -y
        echo "✅ Módulos desinstalados."
    else
        echo "❌ ERROR: Debes desinstalar estos módulos para que los tests funcionen."
        echo "👉 Ejecuta: $DRUSH_CMD pm:uninstall ${MODULOS_ACTIVOS[*]} -y"
    fi
else
    echo "✅ No se detectaron módulos anti-spam activos."
fi

# 3. Verificar Flood Control
echo "🌊 Verificando Flood Control..."
FLOOD_LIMIT=$($DRUSH_CMD config:get contact.settings flood.limit --format=json 2>/dev/null | python3 -c "import sys,json; print(json.load(sys.stdin))" 2>/dev/null)
if [ -n "$FLOOD_LIMIT" ] && [ "$FLOOD_LIMIT" != "None" ] && [ "$FLOOD_LIMIT" -lt 100 ]; then
    echo "⚠️ Flood control restrictivo ($FLOOD_LIMIT)."
    if [ "$UNINSTALL_FLAG" == "--uninstall" ]; then
        $DRUSH_CMD config:set contact.settings flood.limit 1000 -y
        echo "✅ Flood control ajustado a 1000."
    fi
else
    echo "✅ Flood control OK."
fi

# 4. Verificar Transporte de Email (Seguridad)
echo "📧 Verificando transporte de email..."
MAILER_TYPE="symfony_mailer"
MAIL_CONF=$($DRUSH_CMD config:get symfony_mailer.settings default_transport --format=json 2>/dev/null)
if [ -z "$MAIL_CONF" ]; then
    MAIL_CONF=$($DRUSH_CMD config:get swiftmailer.transport transport --format=json 2>/dev/null)
    MAILER_TYPE="swiftmailer"
fi

if [ -n "$MAIL_CONF" ] && [ "$MAIL_CONF" != "None" ]; then
    TRANSPORT=$(echo "$MAIL_CONF" | python3 -c "import sys,json; print(json.load(sys.stdin))" 2>/dev/null)
    echo "📬 Transporte actual ($MAILER_TYPE): $TRANSPORT"
    if [[ "$TRANSPORT" =~ (smtp|gmail|mailgun|sendgrid) ]]; then
        echo "❌ ALERTA: Estás usando un transporte de email REAL ($TRANSPORT)."
        echo "⚠️  Los tests podrían enviar correos reales a clientes. Cambia a 'mailpit' o 'test'."
    else
        echo "✅ Transporte de email seguro para tests."
    fi
fi

echo "✅ Fase de preparación completada."
