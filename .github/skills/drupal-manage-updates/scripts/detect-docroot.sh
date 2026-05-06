#!/usr/bin/env bash
# =============================================================================
# detect-docroot.sh — Detecta el docroot del proyecto Drupal
# Uso: source "$SKILL_DIR/scripts/detect-docroot.sh"
#      Después usar: $DOCROOT
#
# Estrategia de detección (en orden de prioridad):
#   1. composer.json → extra.drupal-scaffold.locations.web-root
#   2. composer.json → extra.installer-paths (busca patrón {web}/)
#   3. .ddev/config.yaml → docroot
#   4. Buscar directorios conocidos: web/, docroot/, html/, httpdocs/
#   5. Si hay core/lib/Drupal.php en la raíz → docroot es "."
# =============================================================================

detect_docroot() {
    local docroot=""

    # 1. composer.json → drupal-scaffold locations
    if [ -f "composer.json" ]; then
        docroot=$(cat composer.json | jq -r '.extra["drupal-scaffold"].locations["web-root"] // empty' 2>/dev/null)
        # Quitar trailing slash si existe
        docroot="${docroot%/}"
    fi

    # 2. composer.json → installer-paths
    if [ -z "$docroot" ] && [ -f "composer.json" ]; then
        # Buscar la primera clave que contenga /modules/contrib/{$name}
        docroot=$(cat composer.json | jq -r '
            .extra["installer-paths"] // {} | keys[] |
            select(contains("modules/contrib")) |
            split("/") | .[0]
        ' 2>/dev/null | head -1)
    fi

    # 3. .ddev/config.yaml → docroot
    if [ -z "$docroot" ] && [ -f ".ddev/config.yaml" ]; then
        docroot=$(grep -E '^\s*docroot:\s*' .ddev/config.yaml 2>/dev/null | sed 's/.*docroot:\s*//' | tr -d '"' | tr -d "'" | xargs)
    fi

    # 4. Buscar directorios conocidos
    if [ -z "$docroot" ]; then
        for candidate in "web" "docroot" "html" "httpdocs" "public_html"; do
            if [ -d "$candidate" ] && [ -f "$candidate/index.php" ]; then
                docroot="$candidate"
                break
            fi
        done
    fi

    # 5. Drupal en la raíz del proyecto
    if [ -z "$docroot" ] && [ -f "index.php" ] && [ -d "core/lib" ]; then
        docroot="."
    fi

    # Si no se detectó nada, avisar
    if [ -z "$docroot" ]; then
        echo "⚠ No se pudo detectar el docroot automáticamente." >&2
        echo "  Buscado en: composer.json, .ddev/config.yaml, web/, docroot/, html/" >&2
        docroot="web"  # fallback por defecto
    fi

    echo "$docroot"
}

# Si se ejecuta como source, exportar la variable
# Si se ejecuta directamente, imprimir el resultado
if [ "${BASH_SOURCE[0]}" = "${0}" ]; then
    # Ejecutado directamente
    DOCROOT=$(detect_docroot)
    echo "$DOCROOT"
else
    # Sourced desde otro script
    DOCROOT=$(detect_docroot)
    export DOCROOT
fi
