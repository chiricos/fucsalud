#!/usr/bin/env bash
# =============================================================================
# paso-06-ejecucion.sh — Ejecutar BackstopJS reference + test vía ddev add-on
# Uso: bash "$SKILL_DIR/scripts/paso-06-ejecucion.sh" <site_alias> [mode]
#   site_alias: Alias del sitio (ej: uk, de, es) — env folder del add-on
#   mode:       reference | test | approve | all (default: all)
#
# Requiere: ddev-backstopjs add-on instalado (see paso-02-setup.sh)
# Comandos del add-on:
#   ddev backstop <env> reference   — capturar screenshots de PROD (referencia)
#   ddev backstop <env> test        — comparar local vs referencia
#   ddev backstop <env> approve     — aprobar diferencias como nueva referencia
#   ddev backstopjs-report <env>    — abrir reporte HTML en el navegador
# =============================================================================

SITE_ALIAS=$1
MODE=${2:-all}

if [ -z "$SITE_ALIAS" ]; then
    echo "❌ Uso: $0 <site_alias> [mode]"
    echo "   Ejemplo: $0 uk all"
    exit 1
fi

if [[ ! "$SITE_ALIAS" =~ ^[a-zA-Z0-9_-]+$ ]]; then
    echo "❌ SITE_ALIAS inválido: '$SITE_ALIAS'. Solo se permiten caracteres alfanuméricos, guiones y guiones bajos."
    exit 1
fi

ENV_DIR="tests/backstopjs/$SITE_ALIAS"
CONFIG="$ENV_DIR/backstop.json"

if [ ! -f "$CONFIG" ]; then
    echo "❌ No se encontró $CONFIG. Ejecuta primero paso-05-generacion.sh"
    exit 1
fi

# Verify the ddev-backstopjs add-on is installed
if [ ! -f ".ddev/docker-compose.backstopjs.yaml" ]; then
    echo "❌ El add-on ddev-backstopjs no está instalado. Ejecuta primero paso-02-setup.sh"
    exit 1
fi

run_reference() {
    echo "📸 Capturando screenshots de REFERENCIA (PRODUCCIÓN)..."
    echo "   Entorno: $SITE_ALIAS"
    echo "   Esto puede tardar dependiendo del número de escenarios y la velocidad de conexión."
    echo ""
    ddev backstop "$SITE_ALIAS" reference 2>&1
    REF_EXIT=$?
    if [ $REF_EXIT -eq 0 ]; then
        echo ""
        echo "✅ Screenshots de referencia capturados correctamente."
        REF_COUNT=$(find "$ENV_DIR/backstop_data/bitmaps_reference" -name "*.png" 2>/dev/null | wc -l)
        echo "   📊 Total screenshots de referencia: $REF_COUNT"
    else
        echo ""
        echo "❌ Error capturando screenshots de referencia (exit code: $REF_EXIT)."
        echo "   Revisa los errores arriba. Problemas comunes:"
        echo "   - URL de producción no accesible desde DDEV"
        echo "   - Shield/Basic Auth activo en PROD"
        echo "   - Timeout por carga lenta"
        return $REF_EXIT
    fi
}

run_test() {
    echo "🧪 Ejecutando test visual (LOCAL vs REFERENCIA)..."
    echo "   Entorno: $SITE_ALIAS"
    echo ""
    ddev backstop "$SITE_ALIAS" test 2>&1
    TEST_EXIT=$?
    if [ $TEST_EXIT -eq 0 ]; then
        echo ""
        echo "✅ ¡Test visual PASADO! No se detectaron diferencias significativas."
    else
        echo ""
        echo "⚠️ Test visual FALLIDO — Se detectaron diferencias visuales."
        echo "   📊 Ver reporte HTML:"
        echo "   → $ENV_DIR/backstop_data/html_report/index.html"
        echo "   → O ejecuta: ddev backstopjs-report $SITE_ALIAS"
        echo ""
        echo "   Si las diferencias son esperadas (cambios intencionales), apruébalas con:"
        echo "   ddev backstop $SITE_ALIAS approve"
    fi

    TEST_COUNT=$(find "$ENV_DIR/backstop_data/bitmaps_test" -name "*.png" 2>/dev/null | wc -l)
    echo "   📊 Total screenshots de test: $TEST_COUNT"
    return $TEST_EXIT
}

run_approve() {
    echo "✅ Aprobando diferencias como nueva referencia..."
    ddev backstop "$SITE_ALIAS" approve 2>&1
    echo "✅ Los screenshots de test son ahora la nueva referencia."
}

case "$MODE" in
    reference)
        run_reference
        ;;
    test)
        run_test
        ;;
    approve)
        run_approve
        ;;
    all)
        run_reference
        REF_RESULT=$?
        if [ $REF_RESULT -ne 0 ]; then
            echo "❌ Abortando: no se puede continuar sin screenshots de referencia."
            exit $REF_RESULT
        fi
        echo ""
        echo "═══════════════════════════════════════════════════════"
        echo ""
        run_test
        ;;
    *)
        echo "❌ Modo no válido: $MODE"
        echo "   Modos: reference, test, approve, all"
        exit 1
        ;;
esac
