#!/usr/bin/env bash
# =============================================================================
# paso-07-ejecucion.sh — Ejecución de tests Playwright en diferentes modos
# Uso: bash "$SKILL_DIR/scripts/paso-07-ejecucion.sh" <test_file> [mode]
#   test_file: path to the .spec.ts file
#   mode:      headless (default) | headed | ui
# =============================================================================

TEST_FILE="$1"
MODE="${2:-headless}"

if [ -z "$TEST_FILE" ]; then
    echo "❌ Uso: $0 <test_file> [mode]"
    echo "   Modos: headless (default), headed, ui"
    echo "   Ejemplo: $0 tests/playwright/tests/contact-uk.spec.ts headed"
    exit 1
fi

if [ ! -f "$TEST_FILE" ]; then
    echo "❌ Archivo de test no encontrado: $TEST_FILE"
    echo "   Busca archivos disponibles con: find tests/playwright -name '*.spec.ts'"
    exit 1
fi

echo "▶️  Ejecutando test: $TEST_FILE (modo: $MODE)"

case "$MODE" in
    headless)
        echo "🔇 Modo headless (sin navegador visible)..."
        ddev exec npx playwright test "$TEST_FILE" --reporter=line
        EXIT_CODE=$?
        ;;

    headed)
        echo "👁️  Modo headed (navegador visible)..."
        echo "   ⚠️ Usando servicio 'playwright' con display Xvfb."

        # Verify playwright service is running
        if ! ddev describe | grep -q "playwright"; then
            echo "❌ El servicio playwright no está disponible."
            echo "   Instálalo con: ddev add-on get julienloizelet/ddev-playwright && ddev restart"
            exit 1
        fi

        # Verify Chromium is installed in playwright service
        if ! ddev exec -s playwright ls /ms-playwright/ 2>/dev/null | grep -q chromium; then
            echo "⚠️ Chromium no instalado. Instalando..."
            ddev exec -s playwright npx playwright install chromium
        fi

        ddev exec -s playwright npx playwright test "$TEST_FILE" --headed --reporter=line
        EXIT_CODE=$?
        ;;

    ui)
        echo "🖥️  Modo UI interactivo..."
        ddev playwright test --ui
        EXIT_CODE=$?
        ;;

    *)
        echo "❌ Modo no reconocido: $MODE"
        echo "   Modos válidos: headless, headed, ui"
        exit 1
        ;;
esac

if [ "$EXIT_CODE" -eq 0 ]; then
    echo ""
    echo "✅ Tests completados exitosamente."
else
    echo ""
    echo "❌ Tests fallaron (exit code: $EXIT_CODE)."
    echo "   Revisa el reporte: ddev exec npx playwright show-report --host 0.0.0.0"
fi

exit $EXIT_CODE
