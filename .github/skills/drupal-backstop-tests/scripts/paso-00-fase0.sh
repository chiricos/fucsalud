#!/usr/bin/env bash
# =============================================================================
# paso-00-fase0.sh — FASE 0: Análisis exhaustivo de la estructura del menú
# Read-only inspection commands with script-enforced input validation.
# Uso: bash "$SKILL_DIR/scripts/paso-00-fase0.sh" <menu_name> [site_uri]
#   menu_name: Machine name del menú Drupal (ej: main, footer)
#   site_uri:  URI opcional del sitio (ej: https://uk.ddev.site)
# =============================================================================

MENU_NAME="$1"
SITE_URI="$2"

if [ -z "$MENU_NAME" ]; then
    echo "❌ Usage: $0 <menu_name> [site_uri]"
    echo "   menu_name: Drupal menu machine name (e.g. main, footer)"
    echo "   site_uri:  Optional site URI (e.g. https://uk.ddev.site)"
    exit 1
fi

# Script-enforced validation — prevents PHP injection in drush eval
if [[ ! "$MENU_NAME" =~ ^[a-z0-9_-]+$ ]]; then
    echo "❌ Nombre de menú inválido: '$MENU_NAME'. Solo letras minúsculas, números, guiones y guiones bajos."
    exit 1
fi

# Validate SITE_URI if provided
if [[ -n "$SITE_URI" ]]; then
    if [[ ! "$SITE_URI" =~ ^[a-zA-Z0-9./:_-]+$ ]]; then
        echo "❌ URI inválida: '$SITE_URI'. Contiene caracteres no permitidos."
        exit 1
    fi
    CLEAN_URI=$(echo "$SITE_URI" | sed -E 's|https?://||' | sed 's|/||g')
    DRUSH_CMD=("ddev" "drush" "--uri=$CLEAN_URI")
    FETCH_URL="https://$CLEAN_URI/"
else
    DRUSH_CMD=("ddev" "drush")
    FETCH_URL="http://127.0.0.1/"
fi

echo "🔍 FASE 0 — Análisis del menú '$MENU_NAME'"
echo "============================================"

# --- Step 1: Obtener el árbol completo desde Drupal ---
echo ""
echo "📋 1. Árbol completo del menú '$MENU_NAME':"
echo "--------------------------------------------"
"${DRUSH_CMD[@]}" eval "
\$menu = \Drupal::menuTree();
\$params = \$menu->getCurrentRouteMenuTreeParameters('$MENU_NAME');
\$params->setMaxDepth(9);
\$tree = \$menu->load('$MENU_NAME', \$params);
function dump_tree(\$items, \$depth = 0) {
  foreach (\$items as \$item) {
    \$link = \$item->link;
    \$has_children = \$item->subtree ? ' [+children]' : '';
    echo str_repeat('  ', \$depth) . \$link->getTitle() . ' -> ' . \$link->getUrlObject()->toString() . \$has_children . PHP_EOL;
    if (\$item->subtree) dump_tree(\$item->subtree, \$depth + 1);
  }
}
dump_tree(\$tree);
"

# --- Step 2: Inspeccionar mecanismos de interacción en el DOM ---
echo ""
echo "🔧 2. Triggers de submenú detectados en el DOM:"
echo "-------------------------------------------------"
ddev exec curl -sk "$FETCH_URL" | python3 -c "
import sys, re
html = sys.stdin.read()
triggers = re.findall(r'<[^>]+(aria-haspopup|aria-expanded|data-toggle|data-bs-toggle|data-bs-target)[^>]*>', html)
if not triggers:
    print('  (ningún trigger de submenú encontrado)')
else:
    for t in triggers:
        print('  ' + re.sub(r'\s+', ' ', t)[:200])
"

# --- Step 3: Detectar clases de visibilidad (viewport detection) ---
echo ""
echo "👁️ 3. Clases de visibilidad del menú (viewport detection):"
echo "-----------------------------------------------------------"
ddev exec curl -sk "$FETCH_URL" | python3 -c "
import sys, re
html = sys.stdin.read()
menu_name = '$MENU_NAME'
# Find the menu block region
pattern = r'(<[^>]*(?:id=\"[^\"]*' + menu_name + r'[^\"]*\"|class=\"[^\"]*menu--' + menu_name + r'[^\"]*\")[^>]*>)'
matches = re.findall(pattern, html, re.IGNORECASE)
visibility_classes = ['d-none', 'd-block', 'd-sm-none', 'd-sm-block', 'd-md-none', 'd-md-block',
                      'd-lg-none', 'd-lg-block', 'd-xl-none', 'd-xl-block',
                      'hidden-xs', 'hidden-sm', 'hidden-md', 'hidden-lg',
                      'visible-xs', 'visible-sm', 'visible-md', 'visible-lg']
found = False
for m in matches:
    for vc in visibility_classes:
        if vc in m:
            if not found:
                found = True
            print(f'  {vc} in: {m[:150]}')
if not found:
    print('  (sin clases de visibilidad responsive — menú visible en todos los viewports)')
"

echo ""
echo "✅ FASE 0 completado. Usa esta información para paso-04 (modelado)."
