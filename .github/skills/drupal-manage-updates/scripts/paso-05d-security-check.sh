#!/usr/bin/env bash
# =============================================================================
# paso-05d-security-check.sh
# Revisa módulos ya compatibles con la versión objetivo para detectar:
#   - Estado de mantenimiento problemático (unsupported, abandoned, obsolete)
#   - Versiones con parches de seguridad pendientes (release de seguridad
#     más reciente que la versión instalada)
#   - Nota: security_covered==false indica que el proyecto no está inscrito en
#     el programa Security Advisory de Drupal, NO implica vulnerabilidad activa.
#     Se incluye como campo informativo en el JSON pero no fuerza actualización.
#
# Solo actualiza los módulos que NECESITAN atención; los demás permanecen
# en already-ok.json sin cambios (action: "none").
#
# Entrada:  $TMP_DIR/already-ok.json
#           Variables: CURRENT_MAJOR, TARGET_MAJOR, PATCHES_JSON
# Salida:   $TMP_DIR/security-update.json  (módulos que necesitan actualización)
#           $TMP_DIR/already-ok.json        (sobreescrito sin los que se movieron)
# =============================================================================

set -uo pipefail

: "${CURRENT_MAJOR:?'CURRENT_MAJOR es requerido'}"
: "${TARGET_MAJOR:?'TARGET_MAJOR es requerido'}"
: "${TMP_DIR:?'TMP_DIR es requerido'}"
: "${PATCHES_JSON:='{}'}"

ALREADY_OK_FILE="$TMP_DIR/already-ok.json"
SECURITY_UPDATE="[]"

if [ ! -f "$ALREADY_OK_FILE" ]; then
    echo "  [5d] No se encontró already-ok.json — saltando revisión de seguridad."
    echo "[]" > "$TMP_DIR/security-update.json"
    # shellcheck disable=SC2317
    return 0 2>/dev/null || exit 0
fi

TOTAL_OK=$(jq 'length' "$ALREADY_OK_FILE")
if [ "$TOTAL_OK" -eq 0 ]; then
    echo "  [5d] No hay módulos compatibles que revisar."
    echo "[]"> "$TMP_DIR/security-update.json"
    # shellcheck disable=SC2317
    return 0 2>/dev/null || exit 0
fi

echo "  [5d] Revisando $TOTAL_OK módulos compatibles por seguridad/soporte..."
echo ""

# Reuse parse functions from paso-05b if available (sourced by wrapper)

REMAINING_OK="[]"
IDX=0

while IFS= read -r LINE; do
    IDX=$((IDX + 1))
    MODULE=$(echo "$LINE" | jq -r '.name')
    CUR_VER=$(echo "$LINE" | jq -r '.version')
    SHORT_NAME=$(echo "$MODULE" | sed 's/drupal\///')

    # Info de parches
    HAS_PATCHES="false"
    PATCH_COUNT=0
    if echo "$PATCHES_JSON" | jq -e ".\"$MODULE\"" > /dev/null 2>&1; then
        HAS_PATCHES="true"
        PATCH_COUNT=$(echo "$PATCHES_JSON" | jq ".\"$MODULE\" | if type == \"object\" then length elif type == \"array\" then length else 0 end" 2>/dev/null || echo "0")
    fi

    printf "  [%d/%d] %-40s " "$IDX" "$TOTAL_OK" "$MODULE"

    RELEASE_XML=$(curl -sf --max-time 10 "https://updates.drupal.org/release-history/$SHORT_NAME/current" 2>/dev/null || echo "")

    NEEDS_UPDATE="false"
    UPDATE_REASONS=""
    MAINTENANCE_STATUS=""
    DEVELOPMENT_STATUS=""
    PROJECT_STATUS=""
    SECURITY_COVERED="1"
    LATEST_SECURE_VER=""
    IS_PRERELEASE="false"

    if [ -n "$RELEASE_XML" ] && ! echo "$RELEASE_XML" | grep -q "No release history"; then
        # Extraer metadatos del proyecto
        if command -v xmlstarlet &>/dev/null; then
            PROJECT_STATUS=$(echo "$RELEASE_XML" | xmlstarlet sel -t -v "/project/project_status" 2>/dev/null || echo "")
            MAINTENANCE_STATUS=$(echo "$RELEASE_XML" | xmlstarlet sel -t -v "/project/terms/term[name='Maintenance status']/value" 2>/dev/null || echo "")
            DEVELOPMENT_STATUS=$(echo "$RELEASE_XML" | xmlstarlet sel -t -v "/project/terms/term[name='Development status']/value" 2>/dev/null || echo "")
        else
            PROJECT_STATUS=$(echo "$RELEASE_XML" | sed -n 's/.*<project_status>\([^<]*\)<.*/\1/p' | head -1 || echo "")
            MAINTENANCE_STATUS=$(echo "$RELEASE_XML" | awk '
                function extract_term(line, name,   search, pos, rest, i) {
                    search = "<name>" name "</name><value>"
                    pos = index(line, search)
                    if (pos == 0) return ""
                    rest = substr(line, pos + length(search))
                    i = index(rest, "<")
                    return (i == 0) ? rest : substr(rest, 1, i - 1)
                }
                /Maintenance status/ { v = extract_term($0, "Maintenance status"); if (v != "") { print v; exit } }
            ' || echo "")
            DEVELOPMENT_STATUS=$(echo "$RELEASE_XML" | awk '
                function extract_term(line, name,   search, pos, rest, i) {
                    search = "<name>" name "</name><value>"
                    pos = index(line, search)
                    if (pos == 0) return ""
                    rest = substr(line, pos + length(search))
                    i = index(rest, "<")
                    return (i == 0) ? rest : substr(rest, 1, i - 1)
                }
                /Development status/ { v = extract_term($0, "Development status"); if (v != "") { print v; exit } }
            ' || echo "")
        fi

        # Comprobar security_covered en las releases (grep -oE es POSIX y macOS-compatible)
        SECURITY_COVERED=$(echo "$RELEASE_XML" | grep -oE 'covered="[^"]*"' | head -1 | sed 's/covered="//;s/"$//' || echo "")
        [ -z "$SECURITY_COVERED" ] && SECURITY_COVERED="0"

        # Buscar si existe un release de seguridad más reciente que la versión instalada.
        # Comparamos por posición en el XML (las releases vienen ordenadas de más reciente
        # a más antigua). Si encontramos un release con security update="TRUE" antes de
        # llegar a la versión instalada, hay un parche de seguridad pendiente.
        LATEST_SECURE_VER=$(printf '%s\n' "$RELEASE_XML" | awk '{
            n = split($0, parts, "</release>")
            for (i = 1; i < n; i++) print parts[i] "</release>"
            if (n > 0 && parts[n] != "") print parts[n]
        }' | awk -v installed="$CUR_VER" -v cur_major="$CURRENT_MAJOR" -v tgt_major="$TARGET_MAJOR" '
        function has_major(compat, major,   pat) {
            pat = "\\^" major "[^0-9]|\\^" major "$|~" major "[^0-9]|~" major "$|>=" major "[^0-9]|>=" major "$"
            if (compat ~ pat) return 1
            return 0
        }
        function extract_tag(line, tag,   tlen, pos, rest, i) {
            tlen = length(tag)
            pos = index(line, "<" tag ">")
            if (pos == 0) return ""
            rest = substr(line, pos + tlen + 2)
            i = index(rest, "<")
            return (i == 0) ? rest : substr(rest, 1, i - 1)
        }
        /<release>/ { in_rel=1; ver=""; compat=""; status=""; sec_update="" }
        in_rel && /<version>/ { ver = extract_tag($0, "version") }
        in_rel && /<core_compatibility>/ { compat = extract_tag($0, "core_compatibility") }
        in_rel && /<status>/ { status = extract_tag($0, "status") }
        in_rel && /security update/ { sec_update="1" }
        /<\/release>/ {
            in_rel=0
            if (status != "published") next
            if (ver ~ /-dev/ || ver ~ /-unstable/) next
            nver = ver; gsub(/^[0-9]+\.x-/, "", nver)
            if (nver == installed) exit
            if (sec_update == "1" && (has_major(compat, cur_major) || has_major(compat, tgt_major))) {
                print nver
                exit
            }
        }
        ')

        # Evaluar criterios
        case "$MAINTENANCE_STATUS" in
            "Unsupported"|"Abandoned")
                NEEDS_UPDATE="true"
                UPDATE_REASONS="unsupported" ;;
            "Seeking new maintainer"|"Seeking co-maintainer"|"Minimally maintained")
                # Solo flag — actualizar si además hay otra razón
                ;;
        esac

        if [ "$DEVELOPMENT_STATUS" = "Obsolete" ]; then
            NEEDS_UPDATE="true"
            [ -n "$UPDATE_REASONS" ] && UPDATE_REASONS="$UPDATE_REASONS,"
            UPDATE_REASONS="${UPDATE_REASONS}obsolete"
        fi

        if [ -n "$LATEST_SECURE_VER" ]; then
            NEEDS_UPDATE="true"
            [ -n "$UPDATE_REASONS" ] && UPDATE_REASONS="$UPDATE_REASONS,"
            UPDATE_REASONS="${UPDATE_REASONS}security_patch_pending"
        fi
    else
        printf "⚠️  sin datos API\n"
        # Sin datos de API → dejamos en already-ok (conservador)
        REMAINING_OK=$(echo "$REMAINING_OK" | jq --argjson mod "$LINE" '. + [$mod]')
        continue
    fi

    if [ "$NEEDS_UPDATE" = "true" ]; then
        echo "$LATEST_SECURE_VER" | grep -qiE '(alpha|beta|rc)' && IS_PRERELEASE="true"
        NEW_VER="${LATEST_SECURE_VER:-latest}"

        # Indicadores para el output
        DISPLAY_REASONS=$(echo "$UPDATE_REASONS" | tr ',' ' ' | sed 's/unsupported/❌unsupported/;s/obsolete/❌obsolete/;s/no_security_coverage/⚠️no-sec/;s/security_patch_pending/🔒sec-patch/')
        printf "🔒 necesita actualización: %s (%s)\n" "$NEW_VER" "$DISPLAY_REASONS"

        SECURITY_UPDATE=$(echo "$SECURITY_UPDATE" | jq \
            --arg name "$MODULE" \
            --arg ver "$CUR_VER" \
            --arg nv "$NEW_VER" \
            --argjson hp "$HAS_PATCHES" \
            --argjson pc "$PATCH_COUNT" \
            --argjson pr "$IS_PRERELEASE" \
            --arg maint "$MAINTENANCE_STATUS" \
            --arg dev "$DEVELOPMENT_STATUS" \
            --arg proj "$PROJECT_STATUS" \
            --arg sec "$SECURITY_COVERED" \
            --arg reasons "$UPDATE_REASONS" \
            '. + [{
                module: $name, current_version: $ver,
                new_version: $nv,
                has_patches: $hp, patch_count: $pc, is_prerelease: $pr,
                maintenance_status: $maint, development_status: $dev,
                project_status: $proj, security_covered: ($sec == "1"),
                update_reasons: ($reasons | split(",")),
                action: "security_or_support"
            }]')
    else
        printf "✅ OK\n"
        REMAINING_OK=$(echo "$REMAINING_OK" | jq --argjson mod "$LINE" '. + [$mod]')
    fi
done < <(jq -c '.[]' "$ALREADY_OK_FILE")

# Escribir resultados
echo "$SECURITY_UPDATE" > "$TMP_DIR/security-update.json"
echo "$REMAINING_OK" > "$ALREADY_OK_FILE"

SEC_COUNT=$(echo "$SECURITY_UPDATE" | jq 'length')
REMAINING_COUNT=$(echo "$REMAINING_OK" | jq 'length')
echo ""
echo "  [5d] Resultado: $SEC_COUNT requieren actualización de seguridad/soporte, $REMAINING_COUNT OK"
