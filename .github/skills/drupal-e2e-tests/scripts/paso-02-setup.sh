#!/usr/bin/env bash
# =============================================================================
# paso-02-setup.sh — Configuración de Playwright en DDEV
# Uso: bash "$SKILL_DIR/scripts/paso-02-setup.sh" [SITE_URL]
# Ejemplo: bash "$SKILL_DIR/scripts/paso-02-setup.sh" https://uk.ddev.site
# =============================================================================

SITE_URL="${1:-}"

if [ -z "$SITE_URL" ]; then
    echo "❌ Uso: $0 [SITE_URL]"
    echo "   Ejemplo: $0 https://uk.ddev.site"
    exit 1
fi

echo "🛠️ Configurando el entorno de Playwright..."

# 1. SSL: Detectar proxy corporativo y manejar certificados si es necesario
# En lugar de deshabilitar la verificación SSL, detectamos y confiamos en la CA del proxy.
_detect_and_trust_proxy_cert() {
    echo "🔍 Verificando proxy SSL (firewall corporativo)..."
    # Comprobar si packages.drupal.org tiene un certificado de proxy/autofirmado
    CERT_ISSUER=$(ddev exec bash -c 'echo | openssl s_client -connect packages.drupal.org:443 2>/dev/null | openssl x509 -noout -issuer 2>/dev/null' || true)

    if echo "$CERT_ISSUER" | grep -qi "proxy\|firewall\|zscaler\|hiberus\|fortigate\|palo.alto\|bluecoat\|symantec.cloud"; then
        echo "⚠️  Proxy SSL corporativo detectado: $CERT_ISSUER"
        echo "   Extrayendo y confiando en el certificado CA del proxy..."

        # Extraer el certificado CA de la cadena
        ddev exec bash -c '
            echo | openssl s_client -connect packages.drupal.org:443 -showcerts 2>/dev/null \
            | awk "/-----BEGIN CERTIFICATE-----/{found++} found==2{print} /-----END CERTIFICATE-----/{if(found==2) exit}" \
            > /usr/local/share/ca-certificates/corporate-proxy.crt 2>/dev/null \
            && update-ca-certificates 2>/dev/null
        ' || true

        echo "   ✅ Certificado CA del proxy confiado (si se encontró)."
    else
        echo "   ✅ No se detectó proxy corporativo. Verificación SSL intacta."
    fi
}
_detect_and_trust_proxy_cert

# 2. Addon Playwright (install if not present)
# ⚠️ Siempre instala julienloizelet/ddev-playwright con versión pinneada (ejemplo: @2.6.0). Nunca uses latest.
if ! ddev describe | grep -q "playwright"; then
    echo "📦 Instalando addon de playwright..."
    ddev add-on get julienloizelet/ddev-playwright@2.6.0 || {
        echo "⚠️ ddev add-on get falló, intentando instalación manual..."
        # ==================================================================
        # Versión pinneada del addon + hash de integridad.
        # Esto es el fallback manual — solo se ejecuta si `ddev add-on get`
        # falla (p.ej. detrás de un proxy corporativo).
        #
        # CÓMO ACTUALIZAR:
        #   1. Comprobar última versión: https://github.com/julienloizelet/ddev-playwright/releases
        #   2. Actualizar PLAYWRIGHT_ADDON_VERSION a continuación.
        #   3. Calcular nuevo hash:
        #      curl -sL "https://github.com/julienloizelet/ddev-playwright/archive/refs/tags/v<VERSION>.tar.gz" | sha256sum
        #   4. Actualizar PLAYWRIGHT_ADDON_SHA256 con el nuevo hash.
        # ==================================================================
        PLAYWRIGHT_ADDON_VERSION="2.6.0"
        PLAYWRIGHT_ADDON_SHA256="8286454ab64ccb20553158db10d6e39534b696ff5a235aff7c10c33d5cff5600"
        TARBALL="v${PLAYWRIGHT_ADDON_VERSION}.tar.gz"

        curl -LO "https://github.com/julienloizelet/ddev-playwright/archive/refs/tags/${TARBALL}"

        # Verificar integridad — abortar si no coincide para prevenir ataques de supply-chain
        if command -v sha256sum &>/dev/null; then
            ACTUAL_SHA=$(sha256sum "$TARBALL" | awk '{print $1}')
            if [ "$ACTUAL_SHA" != "$PLAYWRIGHT_ADDON_SHA256" ]; then
                echo "❌ SHA256 no coincide para ${TARBALL}!"
                echo "   Esperado: $PLAYWRIGHT_ADDON_SHA256"
                echo "   Obtenido: $ACTUAL_SHA"
                echo "   Si actualizaste PLAYWRIGHT_ADDON_VERSION, actualiza también PLAYWRIGHT_ADDON_SHA256."
                rm -f "$TARBALL"
                exit 1
            fi
            echo "   ✅ SHA256 verificado."
        else
            echo "⚠️ sha256sum no disponible — no se puede verificar la integridad del tarball."
            echo "   Asegúrate de que la fuente de descarga (github.com) es de confianza antes de continuar."
        fi

        tar -xzf "$TARBALL"
        cp -r "ddev-playwright-${PLAYWRIGHT_ADDON_VERSION}/playwright-build" .ddev/
        cp "ddev-playwright-${PLAYWRIGHT_ADDON_VERSION}/docker-compose.playwright.yaml" .ddev/
        mkdir -p .ddev/commands/playwright
        cp -r "ddev-playwright-${PLAYWRIGHT_ADDON_VERSION}/commands/playwright/"* .ddev/commands/playwright/
        rm -rf "$TARBALL" "ddev-playwright-${PLAYWRIGHT_ADDON_VERSION}"
    }
    ddev restart
fi

# 3. Playwright Config Base (uses SITE_URL parameter)
if [ ! -f "playwright.config.ts" ]; then
    cat <<EOF > playwright.config.ts
import { defineConfig, devices } from '@playwright/test';
export default defineConfig({
  testDir: './tests/playwright/tests',
  fullyParallel: true,
  reporter: 'line',
  use: { baseURL: '${SITE_URL}', ignoreHTTPSErrors: true },
  projects: [{ name: 'chromium', use: { ...devices['Desktop Chrome'] } }],
});
EOF
    echo "   ✅ playwright.config.ts creado con baseURL: ${SITE_URL}"
else
    echo "   ℹ️  playwright.config.ts ya existe (omitiendo)."
fi

# 4. Crear estructura de carpetas
mkdir -p tests/playwright/tests/helpers tests/playwright/fixtures

# 5. Instalación de navegadores y dependencias dentro del contenedor
echo "🌐 Instalando Chromium y dependencias de sistema..."
ddev exec npx playwright install chromium
ddev exec npx playwright install-deps chromium

# 6. Instalar Playwright MCP con versión pinneada
# ⚠️ IMPORTANTE: Instala siempre una versión fija para evitar regresiones upstream.
# ==================================================================
# Pinned MCP version.
# CÓMO ACTUALIZAR:
#   1. Comprobar última versión: https://github.com/microsoft/playwright-mcp/releases
#   2. Actualizar la versión en el comando a continuación.
# ==================================================================
ddev exec npm install --save-dev @microsoft/playwright-mcp@0.7.0

echo "✅ Setup completado con éxito."
