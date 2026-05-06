#!/usr/bin/env bash
# =============================================================================
# paso-06-generacion.sh — Generación de archivos de test Playwright
# Uso: bash "$SKILL_DIR/scripts/paso-06-generacion.sh" [webform_id] [site_url] [form_path]
# Ejemplo: bash paso-06-generacion.sh contact https://uk.ddev.site /webform/contact
# =============================================================================

WEBFORM_ID=$1
SITE_URL=$2
FORM_PATH=${3:-/webform/$WEBFORM_ID}
MODEL_FILE="reports/e2e-tests/model-${WEBFORM_ID}.json"
SITE_SLUG=$(echo "$SITE_URL" | sed 's|https\?://||;s|\.ddev\.site||;s|[^a-zA-Z0-9]|-|g')
TEST_FILE="tests/playwright/tests/${WEBFORM_ID}-${SITE_SLUG}.spec.ts"
DATA_FILE="tests/playwright/fixtures/${WEBFORM_ID}-${SITE_SLUG}.ts"

if [ -z "$WEBFORM_ID" ] || [ -z "$SITE_URL" ]; then
    echo "❌ Uso: $0 [webform_id] [site_url] [form_path]"
    exit 1
fi

if [ ! -f "$MODEL_FILE" ]; then
    echo "❌ Modelo no encontrado: $MODEL_FILE. Ejecuta primero paso-05-modelado.sh"
    exit 1
fi

mkdir -p tests/playwright/tests tests/playwright/fixtures

echo "🔧 Generando test para: $WEBFORM_ID @ $SITE_URL$FORM_PATH"

# Generar archivos con Python desde el modelo JSON
python3 - "$MODEL_FILE" "$SITE_URL" "$FORM_PATH" "$TEST_FILE" "$DATA_FILE" "$SITE_SLUG" <<'PYEOF'
import sys, json, re

model_file, site_url, form_path, test_file, data_file, site_slug = sys.argv[1:]

with open(model_file) as f:
    model = json.load(f)

webform_id = model['id']
title = model['title']
confirmation = model.get('confirmation_message', '')

# Convert elements dict to a fields list for generation
# paso-05-modelado.sh outputs 'elements' as a dict: { field_id: { id, type, title, required, ... } }
elements = model.get('elements', {})
fields = []
for el_id, el_data in elements.items():
    if isinstance(el_data, dict):
        fields.append({
            'id': el_data.get('id', el_id),
            'type': el_data.get('type', 'textfield'),
            'title': el_data.get('title', el_id),
            'required': el_data.get('required', '') == 'true' or el_data.get('required', False) is True,
            'options': el_data.get('options', {}),
        })

# Derive submit label from elements or use default
submit_label = 'Submit'
for f in fields:
    if f['type'] in ('webform_actions', 'actions'):
        submit_label = f.get('title', 'Submit')
        fields.remove(f)
        break

# --- Generar fixture de datos de prueba ---
fixture_lines = [
    f"// Test data for {title} ({site_url})",
    f"export const testData = {{",
]
for field in fields:
    fid = field['id']
    ftype = field['type']
    ftitle = field['title']
    if ftype == 'email':
        fixture_lines.append(f"  {fid}: 'test@example.com', // {ftitle}")
    elif ftype == 'select':
        first_option = next(iter(field.get('options', {'value': 'value'})))
        fixture_lines.append(f"  {fid}: '{first_option}', // {ftitle} - options: {', '.join(field.get('options', {}).keys())}")
    elif ftype == 'textarea':
        fixture_lines.append(f"  {fid}: 'This is an automated test message. Please ignore.', // {ftitle}")
    else:
        fixture_lines.append(f"  {fid}: 'Test {ftitle}', // {ftitle}")
fixture_lines.append("};")

with open(data_file, 'w') as f:
    f.write('\n'.join(fixture_lines) + '\n')

# --- Generar spec de Playwright ---
def drupal_selector(field_id, field_type):
    """Genera selector CSS para campos de Drupal webform."""
    # Drupal convierte _ a - en los IDs
    drupal_id = field_id.replace('_', '-')
    # Usar selector por name (más estable que ID)
    if field_type == 'select':
        return f'select[name="{field_id}"]'
    elif field_type == 'textarea':
        return f'textarea[name="{field_id}"]'
    else:
        return f'input[name="{field_id}"]'

spec_lines = [
    f"import {{ test, expect }} from '@playwright/test';",
    f"import {{ testData }} from '../fixtures/{webform_id}-{site_slug}';",
    f"",
    f"/**",
    f" * Tests E2E para: {title}",
    f" * Sitio: {site_url}",
    f" * Ruta del formulario: {form_path}",
    f" */",
    f"test.describe('{title}', () => {{",
    f"  const FORM_URL = '{site_url}{form_path}';",
    f"  const CONFIRMATION_TEXT = '{confirmation}';",
    f"",
    f"  test.beforeEach(async ({{ page }}) => {{",
    f"    await page.goto(FORM_URL);",
    f"    await expect(page.locator('form.webform-submission-{webform_id.replace('_', '-')}-form')).toBeVisible({{ timeout: 10000 }});",
    f"  }});",
    f"",
    f"  test('envío correcto con datos válidos', async ({{ page }}) => {{",
]

# Rellenar campos
for field in fields:
    fid = field['id']
    ftype = field['type']
    ftitle = field['title']
    selector = drupal_selector(fid, ftype)

    if ftype == 'select':
        spec_lines.append(f"    // {ftitle}")
        spec_lines.append(f"    await page.selectOption('{selector}', testData.{fid});")
    elif ftype == 'textarea':
        spec_lines.append(f"    // {ftitle}")
        spec_lines.append(f"    await page.fill('{selector}', testData.{fid});")
    else:
        spec_lines.append(f"    // {ftitle}")
        spec_lines.append(f"    await page.fill('{selector}', testData.{fid});")

spec_lines += [
    f"",
    f"    // Enviar formulario",
    f"    await page.click('input[type=\"submit\"], button[type=\"submit\"]');",
    f"",
    f"    // Verificar confirmación",
    f"    await expect(page.locator('body')).toContainText(CONFIRMATION_TEXT, {{ timeout: 10000 }});",
    f"  }});",
    f"",
    f"  test('validación de campos requeridos', async ({{ page }}) => {{",
    f"    // Intentar enviar sin rellenar nada",
    f"    await page.click('input[type=\"submit\"], button[type=\"submit\"]');",
    f"",
    f"    // Verificar que no se muestra la confirmación",
    f"    await expect(page.locator('body')).not.toContainText(CONFIRMATION_TEXT);",
    f"",
    f"    // Verificar mensajes de error en campos requeridos",
]

for field in fields:
    if field.get('required'):
        fid = field['id']
        drupal_id = fid.replace('_', '-')
        spec_lines.append(f"    await expect(page.locator('#edit-{drupal_id}--error, [id*=\"{drupal_id}\"][id*=\"error\"]')).toBeVisible({{ timeout: 5000 }}).catch(() => {{}});")

spec_lines += [
    f"  }});",
    f"}});",
]

with open(test_file, 'w') as f:
    f.write('\n'.join(spec_lines) + '\n')

print(f'✅ Test generado: {test_file}')
print(f'✅ Fixtures generados: {data_file}')
PYEOF

echo ""
echo "📁 Archivos generados:"
echo "   - $TEST_FILE"
echo "   - $DATA_FILE"
echo ""
echo "▶️  Para ejecutar: npx playwright test $TEST_FILE --reporter=line"
