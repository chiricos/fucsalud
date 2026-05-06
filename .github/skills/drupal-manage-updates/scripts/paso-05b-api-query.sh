#!/usr/bin/env bash
# =============================================================================
# paso-05b-api-query.sh
# Consulta la API JSON de drupal.org para módulos incompatibles con la versión
# objetivo del core. Clasifica en: puente, solo-target.
#
# Entrada:  $TMP_DIR/needs-research.json
# Salida:   variables exportadas BRIDGE, TARGET_ONLY, MANUAL (JSON arrays)
#           escritas a $TMP_DIR/bridge.json, $TMP_DIR/target-only.json,
#           $TMP_DIR/manual.json
# Variables de entorno requeridas: TARGET_MAJOR, CURRENT_MAJOR, TMP_DIR,
#                                  PATCHES_JSON
# =============================================================================

set -uo pipefail

: "${TARGET_MAJOR:?'TARGET_MAJOR es requerido'}"
: "${CURRENT_MAJOR:?'CURRENT_MAJOR es requerido'}"
: "${TMP_DIR:?'TMP_DIR es requerido'}"
: "${PATCHES_JSON:='{}'}"

# =============================================================================
# Función auxiliar: parsear XML de drupal.org con awk/grep nativo (sin Python)
# Devuelve: bridge_ver|bridge_compat|target_ver|target_compat|project_status|
#           maintenance_status|development_status|security_covered
# =============================================================================
parse_release_xml() {
    local XML="$1"
    local CUR="$2"
    local TGT="$3"

    # Extraer releases con awk para evitar Python inline
    # Usamos xmlstarlet si está disponible, sino awk
    if command -v xmlstarlet &>/dev/null; then
        _parse_with_xmlstarlet "$XML" "$CUR" "$TGT"
    else
        _parse_with_awk "$XML" "$CUR" "$TGT"
    fi
}

_parse_with_xmlstarlet() {
    local XML="$1"
    local CUR="$2"
    local TGT="$3"

    local BRIDGE_VER="" BRIDGE_COMPAT="" TARGET_VER="" TARGET_COMPAT=""
    local BRIDGE_VER_PRE="" BRIDGE_COMPAT_PRE="" TARGET_VER_PRE="" TARGET_COMPAT_PRE=""
    local PROJECT_STATUS="" MAINTENANCE_STATUS="" DEVELOPMENT_STATUS="" SECURITY_COVERED=""
    local SECURITY_COVERED_PRE=""

    PROJECT_STATUS=$(echo "$XML" | xmlstarlet sel -t -v "/project/project_status" 2>/dev/null || echo "")
    MAINTENANCE_STATUS=$(echo "$XML" | xmlstarlet sel -t -v "/project/terms/term[name='Maintenance status']/value" 2>/dev/null || echo "")
    DEVELOPMENT_STATUS=$(echo "$XML" | xmlstarlet sel -t -v "/project/terms/term[name='Development status']/value" 2>/dev/null || echo "")

    while IFS='|' read -r ver compat status sec; do
        [ "$status" != "published" ] && continue
        { [[ "$ver" == *-dev* ]] || [[ "$ver" == *-unstable* ]]; } && continue

        local IS_PRE=""
        echo "$ver" | grep -qiE '(-alpha|-beta|-rc)' && IS_PRE="1"

        local norm_ver
        norm_ver=$(echo "$ver" | sed -E 's/^[0-9]+\.x-//')

        local HAS_CUR HAS_TGT
        HAS_CUR=$(_has_major "$compat" "$CUR")
        HAS_TGT=$(_has_major "$compat" "$TGT")

        if [ "$HAS_CUR" = "1" ] && [ "$HAS_TGT" = "1" ]; then
            if [ -z "$IS_PRE" ] && [ -z "$BRIDGE_VER" ]; then
                BRIDGE_VER="$norm_ver"
                BRIDGE_COMPAT="$compat"
                [ "$sec" = "1" ] && SECURITY_COVERED="1"
            elif [ -n "$IS_PRE" ] && [ -z "$BRIDGE_VER_PRE" ]; then
                BRIDGE_VER_PRE="$norm_ver"
                BRIDGE_COMPAT_PRE="$compat"
                [ "$sec" = "1" ] && SECURITY_COVERED_PRE="1"
            fi
        elif [ "$HAS_TGT" = "1" ] && [ "$HAS_CUR" != "1" ]; then
            if [ -z "$IS_PRE" ] && [ -z "$TARGET_VER" ]; then
                TARGET_VER="$norm_ver"
                TARGET_COMPAT="$compat"
            elif [ -n "$IS_PRE" ] && [ -z "$TARGET_VER_PRE" ]; then
                TARGET_VER_PRE="$norm_ver"
                TARGET_COMPAT_PRE="$compat"
            fi
        fi

        [ -n "$BRIDGE_VER" ] && [ -n "$TARGET_VER" ] && break
    done < <(echo "$XML" | xmlstarlet sel -t -m "/project/releases/release" \
        -v "version" -o "|" -v "core_compatibility" -o "|" -v "status" -o "|" \
        -v "security/@covered" -n 2>/dev/null)

    # Preferir stable; pre-release solo como fallback
    [ -z "$BRIDGE_VER" ] && BRIDGE_VER="$BRIDGE_VER_PRE" && BRIDGE_COMPAT="$BRIDGE_COMPAT_PRE" && SECURITY_COVERED="$SECURITY_COVERED_PRE"
    [ -z "$TARGET_VER" ] && TARGET_VER="$TARGET_VER_PRE" && TARGET_COMPAT="$TARGET_COMPAT_PRE"

    echo "${BRIDGE_VER}|${BRIDGE_COMPAT}|${TARGET_VER}|${TARGET_COMPAT}|${PROJECT_STATUS}|${MAINTENANCE_STATUS}|${DEVELOPMENT_STATUS}|${SECURITY_COVERED}"
}

_parse_with_awk() {
    local XML="$1"
    local CUR="$2"
    local TGT="$3"

    # Paso 1: normalizar XML — pone cada </release> en su propia línea.
    # La API de drupal.org devuelve todos los releases concatenados en una línea.
    # split() con separador de cadena es POSIX y funciona en BSD awk y GNU awk.
    local NORMALIZED
    NORMALIZED=$(printf '%s\n' "$XML" | awk '{
        n = split($0, parts, "</release>")
        for (i = 1; i < n; i++) print parts[i] "</release>"
        if (n > 0 && parts[n] != "") print parts[n]
    }')

    # Paso 2: parsear con awk POSIX puro (sin extensiones GNU/GAWK):
    #   extract_tag():        index()/substr() para el PRIMER tag (evita gsub greedy)
    #   extract_term_value(): extrae <value> del término nombrado, sin getline
    #   has_major():          2-arg match (POSIX) + RSTART/RLENGTH/substr
    printf '%s\n' "$NORMALIZED" | awk -v cur="$CUR" -v tgt="$TGT" '
    function has_major(compat, major,    pat, open_ver) {
        pat = "\\^" major "[^0-9]|\\^" major "$|~" major "[^0-9]|~" major "$|>=" major "[^0-9]|>=" major "$"
        if (compat ~ pat) return 1
        if (match(compat, />=[0-9]+/)) {
            open_ver = substr(compat, RSTART + 2, RLENGTH - 2) + 0
            if (open_ver > 0 && open_ver < major + 0) return 1
        }
        return 0
    }
    function normalize_ver(v,   r) {
        r = v; gsub(/^[0-9]+\.x-/, "", r); return r
    }
    function extract_tag(line, tag,   tlen, pos, rest, i) {
        tlen = length(tag)
        pos = index(line, "<" tag ">")
        if (pos == 0) return ""
        rest = substr(line, pos + tlen + 2)
        i = index(rest, "<")
        return (i == 0) ? rest : substr(rest, 1, i - 1)
    }
    function extract_term_value(line, name,   search, pos, rest, i) {
        search = "<name>" name "</name><value>"
        pos = index(line, search)
        if (pos == 0) return ""
        rest = substr(line, pos + length(search))
        i = index(rest, "<")
        return (i == 0) ? rest : substr(rest, 1, i - 1)
    }

    /<release>/ { in_rel=1; ver=""; compat=""; status=""; sec_covered=""; is_pre=0 }
    in_rel && /<version>/ { ver = extract_tag($0, "version") }
    in_rel && /<core_compatibility>/ { compat = extract_tag($0, "core_compatibility") }
    in_rel && /<status>/ { status = extract_tag($0, "status") }
    in_rel && /covered="1"/ { sec_covered="1" }
    /<\/release>/ {
        in_rel=0
        if (status != "published" || ver ~ /-dev/ || ver ~ /-unstable/) next
        is_pre = (ver ~ /[Aa]lpha|[Bb]eta|-rc/) ? 1 : 0
        nver = normalize_ver(ver)
        hc = has_major(compat, cur)
        ht = has_major(compat, tgt)
        if (hc && ht) {
            if (!is_pre && bridge_ver_stable == "") { bridge_ver_stable=nver; bridge_compat_stable=compat; if (sec_covered=="1") sec_stable="1" }
            if (is_pre  && bridge_ver_pre    == "") { bridge_ver_pre=nver;    bridge_compat_pre=compat;    if (sec_covered=="1") sec_pre="1"    }
        }
        if (ht && !hc) {
            if (!is_pre && target_ver_stable == "") { target_ver_stable=nver; target_compat_stable=compat }
            if (is_pre  && target_ver_pre    == "") { target_ver_pre=nver;    target_compat_pre=compat    }
        }
    }

    /project_status/ { proj_status = extract_tag($0, "project_status") }
    /Maintenance status/ { tmp = extract_term_value($0, "Maintenance status"); if (tmp != "") maint_status = tmp }
    /Development status/ { tmp = extract_term_value($0, "Development status"); if (tmp != "") dev_status = tmp }

    END {
        bridge_ver    = bridge_ver_stable != "" ? bridge_ver_stable : bridge_ver_pre
        bridge_compat = bridge_ver_stable != "" ? bridge_compat_stable : bridge_compat_pre
        sec           = bridge_ver_stable != "" ? sec_stable : sec_pre
        target_ver    = target_ver_stable != "" ? target_ver_stable : target_ver_pre
        target_compat = target_ver_stable != "" ? target_compat_stable : target_compat_pre
        print bridge_ver "|" bridge_compat "|" target_ver "|" target_compat "|" proj_status "|" maint_status "|" dev_status "|" sec
    }
    '
}

_has_major() {
    local COMPAT="$1"
    local MAJOR="$2"
    echo "$COMPAT" | grep -qE '\^'"$MAJOR"'[^0-9]|\^'"$MAJOR"'$|~'"$MAJOR"'[^0-9]|~'"$MAJOR"'$|>='"$MAJOR"'[^0-9]|>='"$MAJOR"'$' && echo "1" && return
    # Open constraint: >=X where X < MAJOR
    local OPEN_VER
    OPEN_VER=$(echo "$COMPAT" | grep -oE '>=[0-9]+' | head -1 | tr -d '>=')
    if [ -n "$OPEN_VER" ] && [ "$OPEN_VER" -lt "$MAJOR" ] 2>/dev/null; then
        echo "1"
    fi
}

BRIDGE="[]"
TARGET_ONLY="[]"
MANUAL="[]"

NEEDS_RESEARCH=$(jq 'length' "$TMP_DIR/needs-research.json" 2>/dev/null || echo "0")

if [ "$NEEDS_RESEARCH" -gt 0 ]; then
    echo "  [5b] Consultando drupal.org para $NEEDS_RESEARCH módulos..."
    echo ""

    IDX=0
    while IFS= read -r LINE; do
        IDX=$((IDX + 1))
        MODULE=$(echo "$LINE" | jq -r '.name')
        CUR_VER=$(echo "$LINE" | jq -r '.version')
        CORE_REQ=$(echo "$LINE" | jq -r '.core_require')
        SHORT_NAME=$(echo "$MODULE" | sed 's/drupal\///')

        # Info de parches
        HAS_PATCHES="false"
        PATCH_COUNT=0
        if echo "$PATCHES_JSON" | jq -e ".\"$MODULE\"" > /dev/null 2>&1; then
            HAS_PATCHES="true"
            PATCH_COUNT=$(echo "$PATCHES_JSON" | jq ".\"$MODULE\" | if type == \"object\" then length elif type == \"array\" then length else 0 end" 2>/dev/null || echo "0")
        fi

        printf "  [%d/%d] %-40s " "$IDX" "$NEEDS_RESEARCH" "$MODULE"

        # Usar /all para obtener releases de todas las ramas, independientemente del core instalado.
        # /current filtra por el core actualmente instalado y oculta releases D10/D11 en sitios D9.
        RELEASE_XML=$(curl -sf --max-time 10 "https://updates.drupal.org/release-history/$SHORT_NAME/all" 2>/dev/null || echo "")

        BRIDGE_VER=""
        BRIDGE_COMPAT=""
        TARGET_VER=""
        TARGET_COMPAT=""
        MAINTENANCE_STATUS=""
        DEVELOPMENT_STATUS=""
        PROJECT_STATUS=""
        SECURITY_COVERED=""

        if [ -n "$RELEASE_XML" ] && ! echo "$RELEASE_XML" | grep -q "No release history"; then
            RESULT=$(parse_release_xml "$RELEASE_XML" "$CURRENT_MAJOR" "$TARGET_MAJOR")

            BRIDGE_VER=$(echo "$RESULT" | cut -d'|' -f1)
            BRIDGE_COMPAT=$(echo "$RESULT" | cut -d'|' -f2)
            TARGET_VER=$(echo "$RESULT" | cut -d'|' -f3)
            TARGET_COMPAT=$(echo "$RESULT" | cut -d'|' -f4)
            PROJECT_STATUS=$(echo "$RESULT" | cut -d'|' -f5)
            MAINTENANCE_STATUS=$(echo "$RESULT" | cut -d'|' -f6)
            DEVELOPMENT_STATUS=$(echo "$RESULT" | cut -d'|' -f7)
            SECURITY_COVERED=$(echo "$RESULT" | cut -d'|' -f8)
        fi

        # Detectar warnings para el output
        WARNINGS_OUTPUT=""

        if [ -n "$BRIDGE_VER" ] && echo "$BRIDGE_VER" | grep -qiE '(alpha|beta|rc)'; then
            WARNINGS_OUTPUT=" ⚠️pre-release"
        elif [ -n "$TARGET_VER" ] && echo "$TARGET_VER" | grep -qiE '(alpha|beta|rc)'; then
            WARNINGS_OUTPUT=" ⚠️pre-release"
        fi

        case "$MAINTENANCE_STATUS" in
            "Minimally maintained")
                WARNINGS_OUTPUT="$WARNINGS_OUTPUT ⚠️minimal-maint" ;;
            "Seeking new maintainer"|"Seeking co-maintainer")
                WARNINGS_OUTPUT="$WARNINGS_OUTPUT ⚠️seeking-maint" ;;
            "Unsupported"|"Abandoned")
                WARNINGS_OUTPUT="$WARNINGS_OUTPUT ❌unsupported" ;;
        esac

        if [ "$SECURITY_COVERED" != "1" ] && [ -n "$BRIDGE_VER$TARGET_VER" ]; then
            WARNINGS_OUTPUT="$WARNINGS_OUTPUT ⚠️no-security"
        fi

        if [ -n "$BRIDGE_VER" ]; then
            printf "🌉 puente: %s (%s)%s\n" "$BRIDGE_VER" "$BRIDGE_COMPAT" "$WARNINGS_OUTPUT"
            BRIDGE_PRERELEASE="false"
            echo "$BRIDGE_VER" | grep -qiE '(alpha|beta|rc)' && BRIDGE_PRERELEASE="true"

            BRIDGE=$(echo "$BRIDGE" | jq \
                --arg name "$MODULE" \
                --arg ver "$CUR_VER" \
                --arg req "$CORE_REQ" \
                --arg nv "$BRIDGE_VER" \
                --arg nc "$BRIDGE_COMPAT" \
                --argjson hp "$HAS_PATCHES" \
                --argjson pc "$PATCH_COUNT" \
                --argjson pr "$BRIDGE_PRERELEASE" \
                --arg maint "$MAINTENANCE_STATUS" \
                --arg dev "$DEVELOPMENT_STATUS" \
                --arg proj "$PROJECT_STATUS" \
                --arg sec "$SECURITY_COVERED" \
                '. + [{
                    module: $name, current_version: $ver, core_require: $req,
                    new_version: $nv, new_core_compatibility: $nc,
                    has_patches: $hp, patch_count: $pc, is_prerelease: $pr,
                    maintenance_status: $maint, development_status: $dev,
                    project_status: $proj, security_covered: ($sec == "1"),
                    action: "update_bridge"
                }]')
        elif [ -n "$TARGET_VER" ]; then
            printf "🎯 solo D%s: %s (%s)%s\n" "$TARGET_MAJOR" "$TARGET_VER" "$TARGET_COMPAT" "$WARNINGS_OUTPUT"
            TARGET_PRERELEASE="false"
            echo "$TARGET_VER" | grep -qiE '(alpha|beta|rc)' && TARGET_PRERELEASE="true"

            TARGET_ONLY=$(echo "$TARGET_ONLY" | jq \
                --arg name "$MODULE" \
                --arg ver "$CUR_VER" \
                --arg req "$CORE_REQ" \
                --arg nv "$TARGET_VER" \
                --arg nc "$TARGET_COMPAT" \
                --argjson hp "$HAS_PATCHES" \
                --argjson pc "$PATCH_COUNT" \
                --argjson pr "$TARGET_PRERELEASE" \
                --arg maint "$MAINTENANCE_STATUS" \
                --arg dev "$DEVELOPMENT_STATUS" \
                --arg proj "$PROJECT_STATUS" \
                --arg sec "$SECURITY_COVERED" \
                '. + [{
                    module: $name, current_version: $ver, core_require: $req,
                    new_version: $nv, new_core_compatibility: $nc,
                    has_patches: $hp, patch_count: $pc, is_prerelease: $pr,
                    maintenance_status: $maint, development_status: $dev,
                    project_status: $proj, security_covered: ($sec == "1"),
                    action: "update_with_core"
                }]')
        else
            printf "❌ sin release%s\n" "$WARNINGS_OUTPUT"
            MANUAL=$(echo "$MANUAL" | jq \
                --arg name "$MODULE" \
                --arg ver "$CUR_VER" \
                --arg req "$CORE_REQ" \
                --argjson hp "$HAS_PATCHES" \
                --argjson pc "$PATCH_COUNT" \
                --arg maint "$MAINTENANCE_STATUS" \
                --arg dev "$DEVELOPMENT_STATUS" \
                --arg proj "$PROJECT_STATUS" \
                --arg sec "$SECURITY_COVERED" \
                '. + [{
                    module: $name, current_version: $ver, core_require: $req,
                    new_version: "none", new_core_compatibility: "none",
                    has_patches: $hp, patch_count: $pc,
                    maintenance_status: $maint, development_status: $dev,
                    project_status: $proj, security_covered: ($sec == "1"),
                    action: "manual"
                }]')
        fi

    done < <(jq -c '.[]' "$TMP_DIR/needs-research.json")
fi

# Escribir resultados a archivos temporales para que paso-05c los lea
echo "$BRIDGE" > "$TMP_DIR/bridge.json"
echo "$TARGET_ONLY" > "$TMP_DIR/target-only.json"
echo "$MANUAL" > "$TMP_DIR/manual.json"
