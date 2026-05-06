#!/usr/bin/env bash
# =============================================================================
# paso-05-generacion.sh — Generación de backstop.json y configuración
# Uso: bash "$SKILL_DIR/scripts/paso-05-generacion.sh" <site_alias> <model_file> <prod_url> <local_url>
#   site_alias: Alias del sitio (ej: uk, de, es) — corresponde al env folder del add-on
#   model_file: Path to model JSON (from paso-04)
#   prod_url:   Production base URL (e.g., https://www.example.com)
#   local_url:  Local DDEV URL (e.g., https://uk.ddev.site)
# =============================================================================

SITE_ALIAS=$1
MODEL_FILE=$2
PROD_URL=$3
LOCAL_URL=$4

if [ -z "$SITE_ALIAS" ] || [ -z "$MODEL_FILE" ] || [ -z "$PROD_URL" ] || [ -z "$LOCAL_URL" ]; then
    echo "❌ Uso: $0 <site_alias> <model_file> <prod_url> <local_url>"
    echo "   Ejemplo: $0 uk reports/backstop-tests/model-menu-main.json https://www.example.com https://uk.ddev.site"
    exit 1
fi

if [[ ! "$SITE_ALIAS" =~ ^[a-zA-Z0-9_-]+$ ]]; then
    echo "❌ SITE_ALIAS inválido: '$SITE_ALIAS'. Solo se permiten caracteres alfanuméricos, guiones y guiones bajos."
    exit 1
fi

if [ ! -f "$MODEL_FILE" ]; then
    echo "❌ Modelo no encontrado: $MODEL_FILE. Ejecuta primero paso-04-modelado.sh"
    exit 1
fi

ENV_DIR="tests/backstopjs/$SITE_ALIAS"

# Ensure env directory structure exists (should already be created by paso-02-setup.sh)
mkdir -p "$ENV_DIR/backstop_data/engine_scripts/puppet"

echo "🔧 Generando backstop.json desde: $MODEL_FILE"
echo "   Entorno (env folder): $SITE_ALIAS"
echo "   PROD (referencia):    $PROD_URL"
echo "   LOCAL (test):         $LOCAL_URL"

# Generate backstop.json using Python
python3 - "$SITE_ALIAS" "$MODEL_FILE" "$PROD_URL" "$LOCAL_URL" <<'PYEOF'
import sys, json, os

site_alias, model_file, prod_url, local_url = sys.argv[1:]

# Strip trailing slashes
prod_url = prod_url.rstrip('/')
local_url = local_url.rstrip('/')

with open(model_file) as f:
    model = json.load(f)

component_type = model['type']
component_id = model['id']
css_selectors = model.get('css_selectors', ['document'])
pages = model.get('pages_to_test', [{'label': 'Homepage', 'path': '/'}])
valid_viewports = model.get('valid_viewports', [
    {"label": "Desktop", "width": 1920, "height": 1080},
    {"label": "Tablet", "width": 768, "height": 1024},
    {"label": "Mobile", "width": 375, "height": 812}
])

if not valid_viewports:
    print("⚠️  Ningún viewport válido detectado. El componente podría no ser visible en ningún layout.")
    sys.exit(1)

# Build scenarios
scenarios = []
for page in pages:
    label = page['label']
    path = page['path']
    submenu_target = page.get('submenuTarget')

    scenario = {
        "label": f"{component_id} - {label}",
        "url": f"{local_url}{path}",
        "referenceUrl": f"{prod_url}{path}",
        "selectors": css_selectors,
        "misMatchThreshold": 0.1,
        "requireSameDimensions": False,
        "delay": 500,
        "readyEvent": "",
        "readySelector": "",
        "hideSelectors": [],
        "removeSelectors": [],
        "onBeforeScript": "puppet/onBefore.js",
        "onReadyScript": "puppet/onReady.js",
    }

    if submenu_target:
        scenario["custom"] = {"submenuTarget": submenu_target}
        # Submenus often exceed the bounding box of the menu wrapper. Capture viewport.
        scenario["selectors"] = ["viewport"]
        scenario["delay"] = 1500

    # For document-level captures, use full-page settings
    if 'document' in css_selectors:
        scenario["selectors"] = ["document"]
        scenario["delay"] = 2000

    scenarios.append(scenario)

# Build backstop config
backstop_config = {
    "id": f"backstop_{component_type}_{component_id}",
    "viewports": valid_viewports,
    "scenarios": scenarios,
    "paths": {
        "bitmaps_reference": "backstop_data/bitmaps_reference",
        "bitmaps_test": "backstop_data/bitmaps_test",
        "engine_scripts": "backstop_data/engine_scripts",
        "html_report": "backstop_data/html_report",
        "ci_report": "backstop_data/ci_report",
    },
    "report": ["browser", "CI"],
    "engine": "puppeteer",
    "engineOptions": {
        "args": ["--no-sandbox", "--ignore-certificate-errors"],
    },
    "asyncCaptureLimit": 5,
    "asyncCompareLimit": 50,
    "debug": False,
    "debugWindow": False,
}

config_dir = f"tests/backstopjs/{site_alias}"
os.makedirs(config_dir, exist_ok=True)
config_path = f"{config_dir}/backstop.json"
with open(config_path, 'w') as f:
    json.dump(backstop_config, f, indent=2)

print(f"✅ backstop.json generado: {config_path}")
print(f"   ID: {backstop_config['id']}")
print(f"   Viewports: {len(backstop_config['viewports'])} ({', '.join([v['label'] for v in valid_viewports])})")
print(f"   Scenarios: {len(backstop_config['scenarios'])}")
print(f"   Total capturas esperadas: {len(backstop_config['viewports']) * len(backstop_config['scenarios'])}")
print()
print("📋 Escenarios generados:")
for s in scenarios:
    print(f"   - {s['label']}")
    print(f"     Test URL:  {s['url']}")
    print(f"     Ref URL:   {s['referenceUrl']}")
    print(f"     Selectors: {s['selectors']}")
PYEOF

if [ $? -ne 0 ]; then
    echo "❌ Falló la generación de backstop.json"
    exit 1
fi

echo ""
echo "✅ Generación completada. Archivos:"
echo "   📄 $ENV_DIR/backstop.json"
echo "   📄 $ENV_DIR/backstop_data/engine_scripts/puppet/onReady.js"
echo "   📄 $ENV_DIR/backstop_data/engine_scripts/puppet/onBefore.js"
echo ""
echo "▶️  Para ejecutar los tests:"
echo "   ddev backstop $SITE_ALIAS reference"
echo "   ddev backstop $SITE_ALIAS test"
