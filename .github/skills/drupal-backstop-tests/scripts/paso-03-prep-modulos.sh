#!/usr/bin/env bash
# =============================================================================
# paso-03-prep-modulos.sh — Desactivar módulos que interfieren con screenshots
# Uso: bash "$SKILL_DIR/scripts/paso-03-prep-modulos.sh" [site_uri] [--uninstall]
# =============================================================================

SITE_URI="$1"
UNINSTALL_FLAG="$2"

# Validate SITE_URI: only allow alphanumeric, dots, hyphens, colons, slashes
if [[ -n "$SITE_URI" && "$SITE_URI" != "--uninstall" ]]; then
    if [[ ! "$SITE_URI" =~ ^[a-zA-Z0-9./:_-]+$ ]]; then
        echo "❌ URI inválida: contiene caracteres no permitidos."
        exit 1
    fi
fi

if [ -z "$SITE_URI" ] || [[ "$SITE_URI" == "--uninstall" ]]; then
    echo "ℹ️ No se especificó URI válida, usando sitio por defecto."
    DRUSH_CMD=("ddev" "drush")
    [ "$SITE_URI" == "--uninstall" ] && UNINSTALL_FLAG="--uninstall"
else
    echo "🌐 Sitio objetivo: $SITE_URI"
    DRUSH_CMD=("ddev" "drush" "--uri=$SITE_URI")
fi

echo "🛡️ Verificando módulos que interfieren con capturas de pantalla..."

# 1. Módulos que generan overlays/banners/popups
BLOCKER_MODULES=(
    "eu_cookie_compliance"
    "cookiebot"
    "cookie_content_blocker"
    "cookie_consent"
    "gdpr_consent"
    "simple_popup_blocks"
    "captcha"
    "image_captcha"
    "recaptcha"
    "honeypot"
    "antibot"
    "shield"
    "hcaptcha"
)

# 2. Detectar módulos vía composer
echo "📦 Buscando módulos bloqueadores en composer..."
COMPOSER_MODULES=$(ddev composer show 2>/dev/null | grep -E "cookie|captcha|antibot|honeypot|recaptcha|shield|hcaptcha|gdpr|popup" | awk '{print $1}' | sed 's/drupal\///')

# 3. Verificar cuáles están activos
MODULOS_ACTIVOS=()
PM_LIST_JSON=$("${DRUSH_CMD[@]}" pm:list --type=module --status=enabled --format=json 2>/dev/null)

if [ -n "$PM_LIST_JSON" ]; then
    for mod in "${BLOCKER_MODULES[@]}" $COMPOSER_MODULES; do
        is_enabled=$(echo "$PM_LIST_JSON" | python3 -c "
import sys, json
try:
    data = json.load(sys.stdin)
    mod = sys.argv[1]
    # Check both as key and as name field
    if mod in data and data[mod].get('status') == 'Enabled':
        print('Enabled')
    elif any(v.get('name') == mod and v.get('status') == 'Enabled' for v in data.values()):
        print('Enabled')
    else:
        print('Disabled')
except:
    print('Disabled')
" "$mod" 2>/dev/null)
        if [ "$is_enabled" == "Enabled" ]; then
            [[ ! " ${MODULOS_ACTIVOS[@]} " =~ " ${mod} " ]] && MODULOS_ACTIVOS+=("$mod")
        fi
    done
fi

if [ ${#MODULOS_ACTIVOS[@]} -gt 0 ]; then
    echo "⚠️ Módulos BLOQUEANTES detectados: ${MODULOS_ACTIVOS[*]}"
    if [ "$UNINSTALL_FLAG" == "--uninstall" ]; then
        echo "🗑️ Desinstalando módulos temporalmente..."
        for mod in "${MODULOS_ACTIVOS[@]}"; do
            "${DRUSH_CMD[@]}" pm:uninstall "$mod" -y 2>/dev/null && echo "   ✅ $mod desinstalado" || echo "   ⚠️ No se pudo desinstalar $mod"
        done
        echo "✅ Módulos bloqueantes desinstalados."
        echo ""
        echo "⚠️ IMPORTANTE: Recuerda reinstalar estos módulos después de los tests:"
        echo "   ${DRUSH_CMD[*]} pm:enable ${MODULOS_ACTIVOS[*]} -y"
    else
        echo "❌ Estos módulos pueden interferir con las capturas de pantalla."
        echo "👉 Ejecuta con --uninstall para desactivarlos:"
        echo "   bash \$SKILL_DIR/scripts/paso-03-prep-modulos.sh $SITE_URI --uninstall"
    fi
else
    echo "✅ No se detectaron módulos bloqueantes activos."
fi

# 4. Verificar Shield (basic auth)
echo "🔒 Verificando Shield (protección HTTP básica)..."
SHIELD_STATUS=$("${DRUSH_CMD[@]}" config:get shield.settings shield_enable --format=string 2>/dev/null)
if [ "$SHIELD_STATUS" == "1" ] || [ "$SHIELD_STATUS" == "true" ]; then
    echo "⚠️ Shield está activado. Las capturas fallarán con HTTP 401."
    if [ "$UNINSTALL_FLAG" == "--uninstall" ]; then
        "${DRUSH_CMD[@]}" config:set shield.settings shield_enable 0 -y 2>/dev/null
        echo "✅ Shield desactivado temporalmente."
    fi
fi

echo "✅ Fase de preparación completada."
