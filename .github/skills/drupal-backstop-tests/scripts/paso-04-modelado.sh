#!/usr/bin/env bash
# =============================================================================
# paso-04-modelado.sh — Robust Dynamic Component Analysis
# =============================================================================

SKILL_DIR=$(dirname "$(dirname "$(realpath "$0")")")
COMPONENT_TYPE="$1"
COMPONENT_REF="$2"
SITE_URI="$3"
REPORT_DIR="$SKILL_DIR/reports/backstop-tests"

if [ -z "$COMPONENT_TYPE" ] || [ -z "$COMPONENT_REF" ]; then
    echo "❌ Usage: $0 <type> <reference> [site_uri]"
    exit 1
fi

# Type-specific COMPONENT_REF validation (each type has different valid characters)
case "$COMPONENT_TYPE" in
    menu|menu-pages)
        # Menu machine names: only lowercase, digits, hyphens, underscores (used in drush eval)
        if [[ ! "$COMPONENT_REF" =~ ^[a-z0-9_-]+$ ]]; then
            echo "❌ Referencia de menú inválida: '$COMPONENT_REF'. Solo se permiten letras minúsculas, números, guiones y guiones bajos."
            exit 1
        fi
        ;;
    selector)
        # CSS selectors: allow #, ., [, ], =, ", spaces, colons, hyphens. Block shell metacharacters.
        # Note: ] must be first in class, - must be last (POSIX character class rules)
        SELECTOR_REGEX='^[][a-zA-Z0-9_.#=" :-]+$'
        if [[ ! "$COMPONENT_REF" =~ $SELECTOR_REGEX ]]; then
            echo "❌ Selector CSS inválido: '$COMPONENT_REF'. Contiene caracteres no permitidos."
            exit 1
        fi
        ;;
    page)
        # URL paths: allow /, letters, digits, hyphens, underscores, dots, query params
        PAGE_REGEX='^[a-zA-Z0-9_./?&=%-]+$'
        if [[ ! "$COMPONENT_REF" =~ $PAGE_REGEX ]]; then
            echo "❌ Ruta de página inválida: '$COMPONENT_REF'. Contiene caracteres no permitidos."
            exit 1
        fi
        ;;
esac

mkdir -p "$REPORT_DIR"

if [[ -n "$SITE_URI" ]]; then
    if [[ ! "$SITE_URI" =~ ^[a-zA-Z0-9./:_-]+$ ]]; then
        echo "❌ URI inválida: contiene caracteres no permitidos."
        exit 1
    fi
fi

if [ -n "$SITE_URI" ]; then
    CLEAN_URI=$(echo "$SITE_URI" | sed -E 's|https?://||' | sed 's|/||g')
    DRUSH_CMD=("ddev" "drush" "--uri=$CLEAN_URI")
    FETCH_URL="https://$CLEAN_URI/"
else
    DRUSH_CMD=("ddev" "drush")
    FETCH_URL="http://127.0.0.1/"
fi

echo "📐 Analyzing component: type=$COMPONENT_TYPE ref=$COMPONENT_REF"

case "$COMPONENT_TYPE" in
    menu)
        # Dynamic discovery of the real menu block selector
        TMP_HTML=$(mktemp)
        ddev exec curl -sk "$FETCH_URL" > "$TMP_HTML"
        MENU_ID="$COMPONENT_REF"
        ACTIVE_THEME=$("${DRUSH_CMD[@]}" config:get system.theme default --format=string 2>/dev/null || echo "olivero")
        
        python3 - "$MENU_ID" "$ACTIVE_THEME" "$REPORT_DIR" "$TMP_HTML" <<'PYEOF'
import json, sys, re, os
menu_id, active_theme, report_dir, html_file = sys.argv[1:]
with open(html_file, 'r', encoding='utf-8', errors='ignore') as f:
    html = f.read()

selectors = []
block_pattern = r'id="([^"]+)"[^>]*data-block-plugin-id="system_menu_block:' + menu_id + '"'
match = re.search(block_pattern, html)
if match:
    selectors.append(f"#{match.group(1)}")
if f"menu--{menu_id}" in html:
    selectors.append(f".menu--{menu_id}")
if not selectors:
    selectors.append(f"#block-{active_theme}-{menu_id}".replace("_", "-"))

pages = [{'label': 'Default State', 'path': '/'}]
triggers = re.findall(r'(?:href|data-target|data-bs-target)="(#[^"]+)"[^>]*(?:data-toggle|data-bs-toggle|aria-haspopup)', html)
for t in set(triggers):
    if f'id="{t[1:]}"' in html:
        pages.append({'label': f"{t[1:].title().replace('-', ' ')} Open", 'path': '/', 'submenuTarget': t})

# Menu type uses only Desktop viewport by default. SKILL.md "Detección de viewports
# válidos" requires inspecting DOM visibility classes (d-none, d-lg-block, etc.)
# before adding Tablet/Mobile. paso-05 is responsible for final viewport selection.
model = {'type': 'menu', 'id': menu_id, 'theme': active_theme, 'css_selectors': selectors, 'valid_viewports': [{"label": "Desktop", "width": 1920, "height": 1080}], 'pages_to_test': pages}
with open(f'{report_dir}/model-menu-{menu_id}.json', 'w') as f: json.dump(model, f, indent=2)
print(f"✅ Model generated: {report_dir}/model-menu-{menu_id}.json")
PYEOF
        rm -f "$TMP_HTML"
        ;;

    menu-pages)
        MENU_ID="$COMPONENT_REF"
        echo "🔍 Extracting pages from: $MENU_ID"
        
        # We output to a temporary file to preserve newlines perfectly
        TMP_LINKS=$(mktemp)
        "${DRUSH_CMD[@]}" eval "
\$params = new \Drupal\Core\Menu\MenuTreeParameters();
\$params->setMaxDepth(9);
\$tree = \Drupal::menuTree()->load('$MENU_ID', \$params);
\$manipulators = [['callable' => 'menu.default_tree_manipulators:checkAccess'], ['callable' => 'menu.default_tree_manipulators:generateIndexAndSort']];
\$tree = \Drupal::menuTree()->transform(\$tree, \$manipulators);
function dump_links(\$tree) {
    foreach (\$tree as \$el) {
        \$link = \$el->link;
        \$url = \$link->getUrlObject();
        \$path = \$url->isRouted() ? \$url->toString() : '';
        if (\$path) echo 'PAGE_URL:' . \$link->getTitle() . '|||' . \$path . \"\n\";
        if (\$el->subtree) dump_links(\$el->subtree);
    }
}
dump_links(\$tree);
" > "$TMP_LINKS" 2>/dev/null

        python3 - "$MENU_ID" "$REPORT_DIR" "$TMP_LINKS" <<'PYEOF'
import sys, json, os
menu_id, report_dir, links_file = sys.argv[1:]
pages = [{'label': 'Homepage', 'path': '/'}]
seen = {'/', ''}

with open(links_file, 'r') as f:
    for line in f:
        if line.startswith('PAGE_URL:'):
            parts = line[9:].strip().split('|||', 1)
            if len(parts) == 2:
                title, path = parts[0].strip(), parts[1].strip()
                if path and path not in seen and not path.startswith('http'):
                    pages.append({'label': title, 'path': path})
                    seen.add(path)

model = {
    'type': 'menu-pages',
    'id': menu_id,
    'css_selectors': ['document'],
    'valid_viewports': [{"label": "Desktop", "width": 1920, "height": 1080}, {"label": "Tablet", "width": 768, "height": 1024}, {"label": "Mobile", "width": 375, "height": 812}],
    'pages_to_test': pages
}
output_file = f'{report_dir}/model-menu-pages-{menu_id}.json'
with open(output_file, 'w') as f:
    json.dump(model, f, indent=2)
print(f"✅ Model generated: {output_file} (Total pages: {len(pages)})")
PYEOF
        rm -f "$TMP_LINKS"
        ;;

    selector)
        SELECTOR="$COMPONENT_REF"
        echo "🔍 Creating model for selector: $SELECTOR"
        model_file="$REPORT_DIR/model-selector-$(echo "$SELECTOR" | sed 's/[^a-zA-Z0-9]/-/g').json"
        python3 - "$SELECTOR" "$REPORT_DIR" "$model_file" <<'PYEOF'
import sys, json
selector, report_dir, output_file = sys.argv[1:]
model = {
    'type': 'selector',
    'id': selector,
    'css_selectors': [selector],
    'valid_viewports': [{"label": "Desktop", "width": 1920, "height": 1080}, {"label": "Tablet", "width": 768, "height": 1024}, {"label": "Mobile", "width": 375, "height": 812}],
    'pages_to_test': [{'label': f'Component {selector}', 'path': '/'}]
}
with open(output_file, 'w') as f:
    json.dump(model, f, indent=2)
print(f"✅ Model generated: {output_file}")
PYEOF
        ;;

    page)
        PAGE_PATH="$COMPONENT_REF"
        echo "🔍 Creating model for page: $PAGE_PATH"
        model_file="$REPORT_DIR/model-page-$(echo "$PAGE_PATH" | sed 's/[^a-zA-Z0-9]/-/g').json"
        python3 - "$PAGE_PATH" "$REPORT_DIR" "$model_file" <<'PYEOF'
import sys, json
page_path, report_dir, output_file = sys.argv[1:]
if not page_path.startswith('/'):
    page_path = '/' + page_path
model = {
    'type': 'page',
    'id': page_path,
    'css_selectors': ['document'],
    'valid_viewports': [{"label": "Desktop", "width": 1920, "height": 1080}, {"label": "Tablet", "width": 768, "height": 1024}, {"label": "Mobile", "width": 375, "height": 812}],
    'pages_to_test': [{'label': f'Page {page_path}', 'path': page_path}]
}
with open(output_file, 'w') as f:
    json.dump(model, f, indent=2)
print(f"✅ Model generated: {output_file}")
PYEOF
        ;;

    *)
        echo "❌ Tipo de componente no soportado: '$COMPONENT_TYPE'. Tipos válidos: menu, menu-pages, selector, page"
        exit 1
        ;;
esac
echo "✅ Modeling completed."
