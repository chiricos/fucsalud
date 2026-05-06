#!/usr/bin/env bash
# =============================================================================
# paso-08-reporte.sh — Generación de informe final y guía de ejecución
# Uso: bash "$SKILL_DIR/scripts/paso-08-reporte.sh" [webform_id]
# =============================================================================

WEBFORM_ID=$1
REPORT_DIR="reports/e2e-tests"

# Discover actual test file(s) — paso-06 generates with SITE_SLUG suffix
TEST_FILE=$(find tests/playwright -name "${WEBFORM_ID}*.spec.ts" -print -quit 2>/dev/null)
if [ -z "$TEST_FILE" ]; then
    echo "⚠️  No se encontró archivo .spec.ts para '$WEBFORM_ID'. Usando ruta genérica."
    TEST_FILE="tests/playwright/tests/${WEBFORM_ID}.spec.ts"
fi

echo "📊 Generando reporte final para: $WEBFORM_ID"
echo "   Archivo de test: $TEST_FILE"

# 1. Crear el archivo de reporte en Markdown
cat <<EOF > $REPORT_DIR/resumen-${WEBFORM_ID}.md
# Reporte de Tests E2E: $WEBFORM_ID

## ✅ Estado de la Generación
- **Webform ID:** $WEBFORM_ID
- **Archivo de Test:** \`$TEST_FILE\`
- **Helpers utilizados:** \`tests/playwright/tests/helpers/form.helper.ts\`
- **Datos de prueba:** \`tests/playwright/fixtures/${WEBFORM_ID}-*.ts\`

---

## 🚀 Cómo ejecutar los tests

Puedes ejecutar los tests en diferentes modos según tu necesidad:

### 1. Modo Silencioso (Headless - Recomendado para CI)
Es el modo más rápido, no abre el navegador visualmente.
\`\`\`bash
ddev exec npx playwright test $TEST_FILE --reporter=line
\`\`\`

### 2. Modo Visual (Headed)
Abre el navegador para que puedas ver la interacción.
> ⚠️ El modo headed requiere el servicio `playwright` con Xvfb. NUNCA uses `ddev exec` sin `-s playwright`.
\`\`\`bash
ddev exec -s playwright npx playwright test $TEST_FILE --headed --reporter=line
\`\`\`

### 3. Modo Interactivo (UI Mode)
Interfaz gráfica para depurar paso a paso, ver pantallazos y logs.
\`\`\`bash
ddev playwright test --ui
\`\`\`
*(Nota: Requiere que el puerto 9323 esté libre en tu host)*

### 4. Ver Reporte HTML
Playwright genera un reporte visual detallado tras la ejecución.
\`\`\`bash
ddev exec npx playwright show-report --host 0.0.0.0
\`\`\`

---

## 📁 Ubicación de Archivos de Resultados
- **Reporte HTML:** \`playwright-report/index.html\`
- **Traza y Fallos:** \`test-results/\`
- **Manual completo:** \`$REPORT_DIR/manual-desarrollador.md\`

EOF

echo "✅ Reporte generado en $REPORT_DIR/resumen-${WEBFORM_ID}.md"
echo "---"
cat $REPORT_DIR/resumen-${WEBFORM_ID}.md
