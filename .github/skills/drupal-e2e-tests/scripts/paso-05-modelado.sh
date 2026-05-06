#!/usr/bin/env bash
# =============================================================================
# paso-05-modelado.sh — Análisis de Webforms y generación de modelo con Lógica Condicional
# Uso: bash "$SKILL_DIR/scripts/paso-05-modelado.sh" [webform_id] [optional_site_or_path]
# =============================================================================

WEBFORM_ID=$1
SEARCH_HINT=$2

if [ -z "$WEBFORM_ID" ]; then
    echo "❌ Uso: $0 [webform_id] [optional_site_or_path]"
    exit 1
fi

echo "📐 Buscando configuración para webform: $WEBFORM_ID"

CONFIG_PATH=""
if [ -f "$SEARCH_HINT" ]; then CONFIG_PATH="$SEARCH_HINT"; fi
if [ -z "$CONFIG_PATH" ]; then
    FOUND_FILES=$(find config -name "webform.webform.${WEBFORM_ID}.yml")
    if [ -n "$FOUND_FILES" ]; then
        if [ -n "$SEARCH_HINT" ]; then CONFIG_PATH=$(echo "$FOUND_FILES" | grep "/$SEARCH_HINT/" | head -n 1); fi
        if [ -z "$CONFIG_PATH" ]; then CONFIG_PATH=$(echo "$FOUND_FILES" | head -n 1); fi
    fi
fi
if [ -z "$CONFIG_PATH" ]; then CONFIG_PATH=$(find config -name "*${WEBFORM_ID}*" -name "*.yml" | head -n 1); fi

if [ -z "$CONFIG_PATH" ] || [ ! -f "$CONFIG_PATH" ]; then
    echo "❌ Archivo de configuración no encontrado."
    exit 1
fi

echo "✅ Configuración encontrada en: $CONFIG_PATH"

# Extraer Título y Confirmación
TITLE=$(grep "^title:" "$CONFIG_PATH" | sed 's/title: //' | tr -d "'\"")
CONFIRMATION=$(grep -A 1 "confirmation_message:" "$CONFIG_PATH" | tail -n 1 | sed 's/.*<p>\(.*\)<\/p>.*/\1/' | sed "s/['\"]//g" | sed 's/confirmation_message: //')

# Extraer Elementos, Validaciones y Lógica Condicional (#states) usando Python
# Variables are passed as sys.argv to avoid shell injection in the heredoc.
mkdir -p reports/e2e-tests
python3 - "$WEBFORM_ID" "$TITLE" "$CONFIRMATION" "$CONFIG_PATH" <<'PYEOF' > "reports/e2e-tests/model-${WEBFORM_ID}.json"
import sys, json, re

webform_id, title, confirmation, config_path = sys.argv[1:5]

def parse_elements(path):
    with open(path, 'r') as f:
        content = f.read()
    
    match = re.search(r'elements: \|-\n(.*?)(?=\n[a-z_]+:)', content, re.DOTALL)
    if not match: match = re.search(r'elements: \|-\n(.*)', content, re.DOTALL)
    if not match: return {}

    elements_block = match.group(1)
    elements = {}
    current_el = None
    in_states = False
    
    for line in elements_block.split('\n'):
        el_match = re.match(r'^  ([a-zA-Z0-9_]+):', line)
        if el_match:
            current_el = el_match.group(1)
            elements[current_el] = {'id': current_el, 'states': {}}
            in_states = False
            continue
        
        if current_el:
            if "'#states':" in line:
                in_states = True
                continue
            
            attr_match = re.match(r"^    '#([a-z_]+)':\s*(.*)", line)
            if attr_match and not in_states:
                key = attr_match.group(1)
                val = attr_match.group(2).strip("' ")
                elements[current_el][key] = val
            
            if in_states and "':input[name=" in line:
                logic_match = re.search(r'input\[name=\\u0022(.*?)\\u0022\]":\s*\{"(.*?)":\s*"?(.*?)"?\}', line)
                if logic_match:
                    trigger_field = logic_match.group(1)
                    condition = logic_match.group(2)
                    value = logic_match.group(3).strip("' ")
                    elements[current_el]['states'][trigger_field] = {'condition': condition, 'value': value}

    return elements

data = {
    'id': webform_id,
    'title': title,
    'confirmation_message': confirmation,
    'elements': parse_elements(config_path),
    'config_file': config_path
}
print(json.dumps(data, indent=2))
PYEOF

echo "✅ Modelo detallado con lógica condicional generado en reports/e2e-tests/model-$WEBFORM_ID.json"
