#!/usr/bin/env bash
# =============================================================================
# paso-01-analisis.sh — Análisis del proyecto Drupal y sus sitios
# Uso: bash "$SKILL_DIR/scripts/paso-01-analisis.sh"
# =============================================================================

SKILL_DIR=$(dirname "$(dirname "$(realpath "$0")")")

echo "🔍 Iniciando análisis del proyecto para BackstopJS..."

# 0. Verificar que DDEV está corriendo
echo ""
echo "🐳 Estado de DDEV:"
DDEV_STATUS=$(ddev status 2>&1)
if echo "$DDEV_STATUS" | grep -q "is not running\|not found\|Error"; then
    echo "❌ DDEV no está corriendo. Ejecuta 'ddev start' primero."
    exit 1
fi
echo "$DDEV_STATUS" | head -6
echo ""

# 1. Detectar DOCROOT
DOCROOT="web"
if [ -f "composer.json" ]; then
    DOCROOT=$(ddev exec jq -r '.extra["drupal-scaffold"].locations["web-root"] // "web"' /var/www/html/composer.json 2>/dev/null)
    DOCROOT="${DOCROOT%/}"
fi
[ -z "$DOCROOT" ] && DOCROOT="web"
echo "✅ Docroot detectado: $DOCROOT"

# 2. Listar sitios en web/sites/
SITES=()
if [ -d "$DOCROOT/sites" ]; then
    for d in $(ls -d $DOCROOT/sites/*/ 2>/dev/null); do
        sitename=$(basename "$d")
        if [[ "$sitename" != "all" && "$sitename" != "default" && "$sitename" != "simpletest" ]]; then
            SITES+=("$sitename")
        fi
    done
fi
# Añadir default como sitio principal
SITES+=("default")
echo "✅ Sitios detectados: ${SITES[*]}"

# 3. Detectar URLs activas desde ddev status + sites.php
# Strategy: parse "Project URLs" from ddev status (reflects actually running hostnames),
# then cross-reference with sites.php to map each URL -> site folder.
# Fall back to parsing .ddev/config.yaml additional_hostnames if needed.
echo ""
echo "🔗 Detectando URLs locales DDEV activas (ddev status + sites.php)..."

SITE_URL_MAP=$(python3 - "$DOCROOT" "$DDEV_STATUS" << 'PY'
import sys, re, os, json

docroot = sys.argv[1]
ddev_status = sys.argv[2]
ddev_tld = "ddev.site"

# 1. Extract all ddev.site HTTPS URLs from "ddev status" Project URLs section
# Handle line-wrapping: some long URLs get split across adjacent table rows
active_urls = []
in_urls_section = False
accumulated = ""
for line in ddev_status.splitlines():
    if "Project URLs" in line:
        in_urls_section = True
    if in_urls_section:
        # Extract text from the URL/PORT column (3rd pipe-delimited cell)
        cells = line.split("│")
        cell_text = cells[3].strip() if len(cells) > 3 else ""
        if cell_text:
            # Accumulate text to handle wrapped URLs (e.g. "https://supportingpharmacy.ddev." + "site, ...")
            accumulated += " " + cell_text
        # Stop after the URLs section ends (look for a new service row with OK status)
        if in_urls_section and "│ OK │" in line and "Project URLs" not in line:
            in_urls_section = False

# Parse all https ddev.site URLs from accumulated text (handles wrapped names)
# First join split domain parts: "...ddev.  site" → "...ddev.site"
accumulated = re.sub(r"ddev\.\s+site", "ddev.site", accumulated)
for url in re.findall(r"https?://[a-zA-Z0-9._-]+\.ddev\.site(?::\d+)?", accumulated):
    # Skip mailpit/webmail ports
    if not re.search(r":(80[0-9]{2}|[89]\d{3})", url):
        if url not in active_urls:
            active_urls.append(url)

# 2. Parse sites.php to build domain -> site_folder mapping
sites_map = {}
sites_php = os.path.join(docroot, "sites", "sites.php")
if os.path.exists(sites_php):
    with open(sites_php) as f:
        content = f.read()
    for m in re.finditer(r"""\$sites\[['"]([^'"]+)['"]\]\s*=\s*['"]([^'"]+)['"]\s*;""", content):
        domain, folder = m.group(1), m.group(2)
        sites_map[domain] = folder

# 3. Parse .ddev/config.yaml for project name and additional_hostnames
project_name = ""
additional_hostnames = []
config_path = ".ddev/config.yaml"
if os.path.exists(config_path):
    with open(config_path) as f:
        content = f.read()
    m = re.search(r"^name:\s*(.+)$", content, re.MULTILINE)
    if m:
        project_name = m.group(1).strip()
    in_block = False
    for line in content.splitlines():
        stripped = line.strip()
        if stripped.startswith("additional_hostnames:") and not stripped.startswith("#"):
            in_block = True
            continue
        if in_block:
            if stripped.startswith("- ") and not stripped.startswith("#"):
                additional_hostnames.append(stripped[2:].strip())
            elif stripped and not stripped.startswith("-"):
                in_block = False

# 4. Build site_alias -> URL mapping
result = {}

# Map active ddev status URLs to site folders via sites.php
for url in active_urls:
    m = re.search(r"https?://([^/:]+\.ddev\.site)", url)
    if not m:
        continue
    hostname = m.group(1)
    slug = hostname.replace(f".{ddev_tld}", "")
    folder = sites_map.get(hostname) or ("default" if slug == project_name.lower() else slug)
    if folder and folder not in result:
        result[folder] = f"https://{hostname}"

# Fill in additional_hostnames not yet seen in ddev status (e.g. after config change, before restart)
for hostname in additional_hostnames:
    fqdn = f"{hostname}.{ddev_tld}"
    folder = sites_map.get(fqdn) or hostname
    if folder not in result:
        result[folder] = f"https://{fqdn} (pendiente ddev restart)"

# Ensure 'default' is mapped to main project URL
if "default" not in result and project_name:
    result["default"] = f"https://{project_name.lower()}.{ddev_tld}"

print(json.dumps(result))
PY
)

echo "🗺️  Mapeo sitio → URL local DDEV:"
echo "$SITE_URL_MAP" | python3 -c "
import sys, json
m = json.load(sys.stdin)
for site, url in sorted(m.items()):
    if 'pendiente' in url:
        status = '⏳'
    elif 'ddev.site' in url:
        status = '✅'
    else:
        status = '⚠️ '
    print(f'   {status} {site:<22} → {url}')
print()
has_pending = any('pendiente' in u for u in m.values())
has_missing = set()
" 2>/dev/null || echo "   (error al mostrar mapa)"

# Check for sites without any DDEV URL
for site in "${SITES[@]}"; do
    URL=$(echo "$SITE_URL_MAP" | python3 -c "import sys,json; m=json.load(sys.stdin); print(m.get(sys.argv[1],''))" "$site" 2>/dev/null)
    if [ -z "$URL" ]; then
        echo "   ⚠️  $site → sin URL DDEV configurada"
    fi
done
echo ""
echo "   Para sitios sin URL, añade la entrada a .ddev/config.yaml additional_hostnames"
echo "   y mapea el dominio en web/sites/sites.php, luego ejecuta 'ddev restart'."

# 4. Detectar alias de Drush
echo ""
echo "📢 Alias de drush disponibles:"
DRUSH_SA=$(ddev drush sa --format=list 2>/dev/null)
if [ -n "$DRUSH_SA" ] && ! echo "$DRUSH_SA" | grep -q "No site aliases\|success.*No"; then
    echo "$DRUSH_SA" | while IFS= read -r alias; do
        [ -z "$alias" ] && continue
        ALIAS_URI=$(ddev drush sa "$alias" --format=json 2>/dev/null | python3 -c "import sys,json; d=json.load(sys.stdin); print(d.get('uri',d.get('root','')))" 2>/dev/null)
        echo "   @${alias} → ${ALIAS_URI:-URI desconocida}"
    done
else
    echo "   ℹ️  No hay alias de drush definidos."
    DRUSH_SITES_DIR="drush/sites"
    if [ ! -d "$DRUSH_SITES_DIR" ]; then
        echo "   💡 Para crear alias, añade archivos .site.yml en $DRUSH_SITES_DIR/"
    fi
fi
echo ""
# Also list any .site.yml files found
ALIAS_FILES=$(find drush/sites 2>/dev/null -name "*.site.yml" | head -10)
if [ -n "$ALIAS_FILES" ]; then
    echo "   📄 Archivos de alias encontrados:"
    echo "$ALIAS_FILES" | while IFS= read -r f; do echo "      $f"; done
fi

# 5. Detectar temas activos por sitio (usando URL DDEV correcta)
echo "🎨 Detectando temas activos..."
for site in "${SITES[@]}"; do
    SITE_URL=$(echo "$SITE_URL_MAP" | python3 -c "import sys,json; url=json.load(sys.stdin).get(sys.argv[1],''); print(url.split(' ')[0])" "$site" 2>/dev/null)
    if [ -n "$SITE_URL" ]; then
        THEME=$(ddev drush --uri="$SITE_URL" config:get system.theme default --format=string 2>/dev/null)
    else
        THEME=$(ddev drush config:get system.theme default --format=string 2>/dev/null)
    fi
    echo "   $site (${SITE_URL:-sin URL DDEV}) → theme: ${THEME:-desconocido}"
done

# 6. Listar menús disponibles (del sitio default)
echo ""
echo "📋 Menús disponibles (sitio: default):"
DEFAULT_URI=$(echo "$SITE_URL_MAP" | python3 -c "import sys,json; url=json.load(sys.stdin).get('default',''); print(url.split(' ')[0])" 2>/dev/null)
MENUS_JSON=$(ddev drush --uri="$DEFAULT_URI" eval "foreach(\Drupal::entityTypeManager()->getStorage('menu')->loadMultiple() as \$m) echo \$m->id().' | '.\$m->label().PHP_EOL;" 2>/dev/null)
if [ -n "$MENUS_JSON" ]; then
    echo "$MENUS_JSON" | while IFS= read -r line; do
        echo "   - $line"
    done
else
    echo "   ℹ️  No se pudieron listar los menús vía drush."
fi

# 7. Crear carpeta de reportes
mkdir -p "$SKILL_DIR/reports/backstop-tests"

# 8. Guardar progreso (clean URLs without trailing notes)
CLEAN_URL_MAP=$(echo "$SITE_URL_MAP" | python3 -c "
import sys,json
m=json.load(sys.stdin)
clean={k: v.split(' ')[0] for k,v in m.items()}
print(json.dumps(clean))
")
SITES_ARRAY=$(printf '%s\n' "${SITES[@]}" | python3 -c "import sys,json; print(json.dumps([l.strip() for l in sys.stdin if l.strip()]))")
cat <<EOF > "$SKILL_DIR/reports/backstop-tests/progress.json"
{
  "phase": "analisis",
  "docroot": "$DOCROOT",
  "sites": $SITES_ARRAY,
  "site_urls": $CLEAN_URL_MAP,
  "timestamp": "$(date -u +"%Y-%m-%dT%H:%M:%SZ")"
}
EOF

echo ""
echo "✅ Análisis completado. Resultados en reports/backstop-tests/progress.json"
echo ""
echo "💡 Al seleccionar un sitio, usa siempre su URL DDEV local (del mapeo arriba) para:"
echo "   - El parámetro local_url de paso-05-generacion.sh"
echo "   - Los comandos ddev drush --uri=<URL>"
echo "   - Las URLs de los escenarios en backstop.json"
