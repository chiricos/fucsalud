#!/usr/bin/env bash
# =============================================================================
# paso-02-setup.sh — Instalación del DDEV BackstopJS add-on y setup del entorno
# Uso: bash "$SKILL_DIR/scripts/paso-02-setup.sh" <site_alias>
#   site_alias: El alias del sitio seleccionado (ej: uk, de, es) — usado como env folder
# =============================================================================

SITE_ALIAS=${1:-local}

# Validate SITE_ALIAS to prevent path traversal (consistent with paso-05/paso-06)
if [[ ! "$SITE_ALIAS" =~ ^[a-zA-Z0-9_-]+$ ]]; then
    echo "❌ SITE_ALIAS inválido: '$SITE_ALIAS'. Solo se permiten letras, números, guiones y guiones bajos."
    exit 1
fi

ENV_DIR="tests/backstopjs/$SITE_ALIAS"

echo "🛠️ Configurando DDEV BackstopJS add-on para entorno: $SITE_ALIAS"

# 1. Verificar que DDEV está corriendo
if ! ddev describe > /dev/null 2>&1; then
    echo "❌ DDEV no está corriendo. Ejecuta 'ddev start' primero."
    exit 1
fi

# 2. Instalar el add-on ddev-backstopjs
if [ -f ".ddev/docker-compose.backstopjs.yaml" ]; then
    echo "✅ El add-on ddev-backstopjs ya está instalado."
else
    echo "📦 Instalando add-on Metadrop/ddev-backstopjs..."
    echo "   ⚠️  La imagen backstopjs/backstopjs es ~1.6GB. La primera descarga tarda varios minutos."
    # Pinned version — to update: check https://github.com/Metadrop/ddev-backstopjs/releases
    # then change the tag here and run the script again. Also update SKILL.md addon docs.
    BACKSTOPJS_ADDON_VERSION="v2.8.0"
    if ddev add-on get "Metadrop/ddev-backstopjs@${BACKSTOPJS_ADDON_VERSION}" 2>/dev/null; then
        echo "✅ Add-on instalado con 'ddev add-on get' (${BACKSTOPJS_ADDON_VERSION})"
    elif ddev get "Metadrop/ddev-backstopjs@${BACKSTOPJS_ADDON_VERSION}"; then
        echo "✅ Add-on instalado con 'ddev get' (${BACKSTOPJS_ADDON_VERSION})"
    else
        echo "❌ Error instalando el add-on. Verifica la conectividad a GitHub y vuelve a intentar."
        exit 1
    fi
    echo "🔄 Reiniciando DDEV para activar el contenedor backstopjs..."
    ddev restart
    if [ $? -ne 0 ]; then
        echo "❌ Error reiniciando DDEV."
        exit 1
    fi
    echo "✅ Add-on ddev-backstopjs instalado y activo."
fi

# 3. Crear estructura de directorios para el entorno
echo "📁 Creando estructura en: $ENV_DIR"

BACKSTOP_BASE_DIR="tests/backstopjs"
if [ -d "$BACKSTOP_BASE_DIR" ] && [ ! -w "$BACKSTOP_BASE_DIR" ]; then
    echo "🔧 Reparando permisos de $BACKSTOP_BASE_DIR..."
    DDEV_PROJECT=$(ddev status 2>/dev/null | python3 -c "import sys,re; m=re.search(r'Project: (\S+)', sys.stdin.read()); print(m.group(1) if m else '')" 2>/dev/null || echo "")
    if [ -n "$DDEV_PROJECT" ]; then
        docker exec -u root "ddev-${DDEV_PROJECT}-web" chmod -R 775 "/var/www/html/${BACKSTOP_BASE_DIR}" 2>/dev/null
    fi
fi

mkdir -p "$ENV_DIR/backstop_data/engine_scripts/puppet"
mkdir -p "$ENV_DIR/backstop_data/bitmaps_reference"
mkdir -p "$ENV_DIR/backstop_data/bitmaps_test"
mkdir -p "$ENV_DIR/backstop_data/html_report"

# Verify volume is synced to the container
CONTAINER_DIR=$(ddev exec -s backstopjs ls -d "/src/tests/$SITE_ALIAS" 2>/dev/null)
if [ -z "$CONTAINER_DIR" ]; then
    echo "⚠️  El directorio de tests no está visible en el contenedor backstopjs."
    echo "   Esto ocurre cuando se crean carpetas nuevas después de levantar el contenedor."
    echo "🔄 Ejecutando 'ddev restart' para sincronizar volúmenes..."
    ddev restart
    if [ $? -ne 0 ]; then
        echo "❌ Error al reiniciar ddev."
        exit 1
    fi
fi

# 4. Crear onBefore.js base
if [ ! -f "$ENV_DIR/backstop_data/engine_scripts/puppet/onBefore.js" ]; then
    cat <<'JSEOF' > "$ENV_DIR/backstop_data/engine_scripts/puppet/onBefore.js"
module.exports = async (page, scenario, viewport, isReference, browserContext) => {
  await page.setExtraHTTPHeaders({
    'Accept-Language': 'en-US,en;q=0.9'
  });
};
JSEOF
    echo "✅ Creado onBefore.js"
fi

# 5. Crear onReady.js base con lógica avanzada de submenús
cat <<'JSEOF' > "$ENV_DIR/backstop_data/engine_scripts/puppet/onReady.js"
module.exports = async (page, scenario, viewport, isReference, browserContext) => {
  // 1. Dismiss cookie banners (adapt selectors per project)
  await page.evaluate(() => {
    // OneTrust
    ['#onetrust-banner-sdk', '#onetrust-consent-sdk', '.onetrust-pc-dark-filter'].forEach(sel => {
      document.querySelectorAll(sel).forEach(el => el.remove());
    });
    const acceptBtn = document.querySelector('#onetrust-accept-btn-handler');
    if (acceptBtn) acceptBtn.click();
    // EU Cookie Compliance
    const euBanner = document.querySelector('.eu-cookie-compliance-banner, #sliding-popup');
    if (euBanner) {
      const agreeBtn = euBanner.querySelector('.agree-button, .eu-cookie-compliance-default-button');
      if (agreeBtn) agreeBtn.click();
      else euBanner.style.display = 'none';
    }
    // CookieBot
    const cookiebot = document.querySelector('#CybotCookiebotDialog');
    if (cookiebot) {
      const acceptBtn = document.querySelector('#CybotCookiebotDialogBodyLevelButtonLevelOptinAllowAll, #CybotCookiebotDialogBodyButtonAccept');
      if (acceptBtn) acceptBtn.click();
      else cookiebot.style.display = 'none';
    }
  });

  // 2. Open submenu if specified
  const custom = scenario.custom || {};
  const submenuTarget = custom.submenuTarget;

  if (submenuTarget) {
    const targets = Array.isArray(submenuTarget) ? submenuTarget : [submenuTarget];

    for (const target of targets) {
      // PRIORITY 1: Use JS framework API (most reliable when available)
      const apiOpened = await page.evaluate((sel) => {
        // jQuery + Bootstrap 3/4/5 collapse
        const jq = typeof jQuery !== 'undefined' ? jQuery : (typeof $ !== 'undefined' ? $ : null);
        if (jq && jq.fn && jq.fn.collapse) {
          jq(sel).collapse('show');
          return 'jquery-collapse';
        }
        // jQuery + Bootstrap dropdown
        if (jq && jq.fn && jq.fn.dropdown) {
          jq(sel).dropdown('show');
          return 'jquery-dropdown';
        }
        // Bootstrap 5 native API (no jQuery needed)
        if (typeof bootstrap !== 'undefined') {
          const el = document.querySelector(sel);
          if (el && bootstrap.Collapse) {
            new bootstrap.Collapse(el, { toggle: true });
            return 'bs5-collapse';
          }
          if (el && bootstrap.Dropdown) {
            bootstrap.Dropdown.getOrCreateInstance(el).show();
            return 'bs5-dropdown';
          }
        }
        return null;
      }, target);

      if (!apiOpened) {
        // PRIORITY 2: DOM manipulation fallback
        await page.evaluate((sel) => {
          const el = document.querySelector(sel);
          if (!el) return;
          el.classList.add('show');
          el.classList.remove('collapse'); // remove Bootstrap collapse hiding
          el.style.display = 'block';
          el.style.height = 'auto';
          el.style.overflow = 'visible';
          el.style.visibility = 'visible';
          el.style.opacity = '1';
        }, target);
      }
    }

    // Wait for transitions (Bootstrap default: 350ms)
    await new Promise(r => setTimeout(r, 1000));
  }

  // 3. Wait for fonts + stabilization
  await page.evaluate(() => document.fonts.ready);
  await new Promise(r => setTimeout(r, 1000));
};
JSEOF
echo "✅ Creado onReady.js (con lógica dinámica de submenús)"

echo ""
echo "✅ Setup completado."
echo "ℹ️  Los comandos de BackstopJS ahora se ejecutan con:"
echo "   ddev backstop $SITE_ALIAS reference"
echo "   ddev backstop $SITE_ALIAS test"
echo "   ddev backstopjs-report $SITE_ALIAS"
