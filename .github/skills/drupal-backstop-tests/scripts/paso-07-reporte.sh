#!/usr/bin/env bash
# =============================================================================
# paso-07-reporte.sh — Generación de reporte final y guía de re-ejecución
# Uso: bash "$SKILL_DIR/scripts/paso-07-reporte.sh" <site_alias> <component_type> <component_id>
#   site_alias: Alias del sitio (ej: uk, de, es) — env folder del add-on
# =============================================================================

SKILL_DIR=$(dirname "$(dirname "$(realpath "$0")")")
SITE_ALIAS=$1
COMPONENT_TYPE=$2
COMPONENT_ID=$3
REPORT_DIR="$SKILL_DIR/reports/backstop-tests"
ENV_DIR="tests/backstopjs/$SITE_ALIAS"
CONFIG="$ENV_DIR/backstop.json"

if [ -z "$SITE_ALIAS" ] || [ -z "$COMPONENT_TYPE" ] || [ -z "$COMPONENT_ID" ]; then
    echo "❌ Uso: $0 <site_alias> <component_type> <component_id>"
    exit 1
fi

if [[ ! "$SITE_ALIAS" =~ ^[a-zA-Z0-9_-]+$ ]] || [[ ! "$COMPONENT_TYPE" =~ ^[a-zA-Z0-9_-]+$ ]] || [[ ! "$COMPONENT_ID" =~ ^[a-zA-Z0-9_-]+$ ]]; then
    echo "❌ Argumentos inválidos: solo se permiten caracteres alfanuméricos, guiones y guiones bajos."
    exit 1
fi

mkdir -p "$REPORT_DIR"

echo "📊 Generando reporte final para: $SITE_ALIAS / $COMPONENT_TYPE / $COMPONENT_ID"

# Count screenshots
REF_COUNT=$(find "$ENV_DIR/backstop_data/bitmaps_reference" -name "*.png" 2>/dev/null | wc -l)
TEST_COUNT=$(find "$ENV_DIR/backstop_data/bitmaps_test" -name "*.png" 2>/dev/null | wc -l)

# Extract scenario count from backstop.json
SCENARIO_COUNT=0
VIEWPORT_COUNT=0
if [ -f "$CONFIG" ]; then
    SCENARIO_COUNT=$(python3 -c "
import json
with open('$CONFIG') as f:
    c = json.load(f)
print(len(c.get('scenarios', [])))
" 2>/dev/null)
    VIEWPORT_COUNT=$(python3 -c "
import json
with open('$CONFIG') as f:
    c = json.load(f)
print(len(c.get('viewports', [])))
" 2>/dev/null)
fi

cat <<EOF > "$REPORT_DIR/resumen-${SITE_ALIAS}-${COMPONENT_TYPE}-${COMPONENT_ID}.md"
# Reporte de Visual Regression: $SITE_ALIAS / $COMPONENT_TYPE / $COMPONENT_ID

**Fecha:** $(date +"%Y-%m-%d %H:%M")
**Sitio:** $SITE_ALIAS
**Tipo:** $COMPONENT_TYPE
**ID:** $COMPONENT_ID

---

## 📊 Resumen

- **Escenarios:** $SCENARIO_COUNT
- **Viewports:** $VIEWPORT_COUNT (Desktop 1920×1080, Tablet 768×1024, Mobile 375×812)
- **Total capturas esperadas:** $(( SCENARIO_COUNT * VIEWPORT_COUNT ))
- **Screenshots de referencia:** $REF_COUNT
- **Screenshots de test:** $TEST_COUNT

---

## 📁 Archivos Generados

| Archivo | Descripción |
|---------|-------------|
| \`$ENV_DIR/backstop.json\` | Configuración principal de BackstopJS |
| \`$ENV_DIR/backstop_data/engine_scripts/puppet/onReady.js\` | Script de preparación (cookies, fonts) |
| \`$ENV_DIR/backstop_data/engine_scripts/puppet/onBefore.js\` | Script pre-navegación |
| \`$ENV_DIR/backstop_data/bitmaps_reference/\` | Screenshots de producción (referencia) |
| \`$ENV_DIR/backstop_data/bitmaps_test/\` | Screenshots locales (test) |
| \`$ENV_DIR/backstop_data/html_report/index.html\` | Reporte HTML interactivo |

---

## 🚀 Cómo ejecutar los tests en el futuro

### 1. Ejecutar comparación visual (Local vs PROD)
Compara el estado actual del sitio local con las capturas de referencia de producción.
\`\`\`bash
ddev backstop $SITE_ALIAS test
\`\`\`

### 2. Actualizar referencia (nueva captura de PROD)
Si la versión de producción cambió y quieres capturar nuevas screenshots de referencia:
\`\`\`bash
ddev backstop $SITE_ALIAS reference
\`\`\`

### 3. Aprobar diferencias
Si las diferencias son intencionales (tu cambio local es correcto), aprueba los nuevos screenshots:
\`\`\`bash
ddev backstop $SITE_ALIAS approve
\`\`\`

### 4. Ver el reporte HTML en el navegador
\`\`\`bash
ddev backstopjs-report $SITE_ALIAS
\`\`\`
O abre directamente el archivo:
\`\`\`
$ENV_DIR/backstop_data/html_report/index.html
\`\`\`

---

## ⚙️ Personalización

### Ajustar umbral de diferencia
En \`$ENV_DIR/backstop.json\`, modifica \`misMatchThreshold\` por escenario:
- \`0.1\` — Estricto (detecta diferencias mínimas)
- \`1.0\` — Tolerante (ignora diferencias menores al 1%)
- \`5.0\` — Muy tolerante (útil para contenido dinámico)

### Ocultar elementos dinámicos
Añade selectores a \`hideSelectors\` en cada escenario para ocultar elementos que cambian:
\`\`\`json
"hideSelectors": [".carousel", ".timestamp", ".ad-banner"]
\`\`\`

### Excluir elementos completamente
Usa \`removeSelectors\` para eliminar del DOM antes de capturar:
\`\`\`json
"removeSelectors": [".chat-widget", ".cookie-popup"]
\`\`\`

---

## ⚠️ Notas importantes

- Los módulos bloqueadores (cookie banners, captcha, shield) deben desactivarse antes de ejecutar los tests.
- Si cambias el contenido en PROD, necesitas actualizar la referencia con \`ddev backstop $SITE_ALIAS reference\`.
- Los screenshots se guardan en Git (opcional). Si el repo es grande, considera añadir \`bitmaps_reference/\` y \`bitmaps_test/\` a \`.gitignore\`.
EOF

echo "✅ Reporte generado: $REPORT_DIR/resumen-${SITE_ALIAS}-${COMPONENT_TYPE}-${COMPONENT_ID}.md"
echo "---"
cat "$REPORT_DIR/resumen-${SITE_ALIAS}-${COMPONENT_TYPE}-${COMPONENT_ID}.md"
