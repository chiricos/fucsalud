#!/usr/bin/env bash
# =============================================================================
# paso-01-analisis.sh — Análisis del proyecto Drupal y sus sitios
# Uso: bash "$SKILL_DIR/scripts/paso-01-analisis.sh"
# =============================================================================

SKILL_DIR=$(dirname "$(dirname "$(realpath "$0")")")

echo "🔍 Iniciando análisis del proyecto..."

# 1. Detectar DOCROOT (jq solo disponible dentro de DDEV)
DOCROOT="web" # Fallback
if [ -f "composer.json" ]; then
    DOCROOT=$(ddev exec jq -r '.extra["drupal-scaffold"].locations["web-root"] // "web"' /var/www/html/composer.json 2>/dev/null)
    DOCROOT="${DOCROOT%/}"
fi
# Si sigue vacío, usar fallback
[ -z "$DOCROOT" ] && DOCROOT="web"
echo "✅ Docroot detectado: $DOCROOT"

# 2. Listar sitios en web/sites/
SITES=()
if [ -d "$DOCROOT/sites" ]; then
    for d in $(ls -d $DOCROOT/sites/*/ 2>/dev/null); do
        sitename=$(basename "$d")
        if [[ "$sitename" != "all" && "$sitename" != "default" ]]; then
            SITES+=("$sitename")
        fi
    done
fi
# Añadir default
if [[ ! " ${SITES[@]} " =~ " default " ]]; then
    SITES+=("default")
fi

echo "✅ Sitios detectados: ${SITES[*]}"

# 3. Detectar Alias de Drush configurados
echo "📢 Buscando alias de drush..."
ddev drush sa 2>&1 || echo "ℹ️ No se encontraron alias de drush definidos."

# 4. Listar Webforms disponibles (buscando en archivos de config)
echo "📋 Listando webforms disponibles (via archivos YAML de configuración)..."
WEBFORM_FILES=()
for config_dir in config/*/; do
    while IFS= read -r yml; do
        wf_id=$(basename "$yml" .yml | sed 's/^webform\.webform\.//')
        WEBFORM_FILES+=("$wf_id ($yml)")
    done < <(find "$config_dir" -maxdepth 1 -name 'webform.webform.*.yml' 2>/dev/null | sort)
done

if [ ${#WEBFORM_FILES[@]} -gt 0 ]; then
    echo "✅ Webforms encontrados:"
    for wf in "${WEBFORM_FILES[@]}"; do
        echo "   - $wf"
    done
else
    echo "ℹ️ No se encontraron archivos webform.webform.*.yml en config/"
fi

# 5. Crear carpeta de reportes
mkdir -p reports/e2e-tests

# 6. Guardar progreso
SITES_ARRAY=$(printf '%s\n' "${SITES[@]}" | python3 -c "import sys,json; print(json.dumps([l.strip() for l in sys.stdin if l.strip()]))")
cat <<EOF > reports/e2e-tests/progress.json
{
  "phase": "analisis",
  "docroot": "$DOCROOT",
  "sites": $SITES_ARRAY,
  "timestamp": "$(date -u +"%Y-%m-%dT%H:%M:%SZ")"
}
EOF

echo "✅ Análisis completado."
