#!/usr/bin/env bash
# =============================================================================
# paso-06-lib.sh — Funciones compartidas para paso-06
#
# Incluye:
#   normalize_version()   — Convierte versión Drupal a constraint Composer
#   analyze_blockers()    — Analiza errores de composer y detecta bloqueadores
#   update_single_module() — Actualiza un módulo individual
#
# Uso: source "$SCRIPT_DIR/paso-06-lib.sh"
# =============================================================================

# Guard contra doble sourcing
[[ -n "${_PASO06_LIB_LOADED:-}" ]] && return 0
_PASO06_LIB_LOADED=1

REPORT_DIR="${REPORT_DIR:-reports/drupal-update/modulos}"
COMPAT_FILE="${COMPAT_FILE:-reports/drupal-update/paso-05-compatibilidad.json}"

# =============================================================================
# normalize_version() — Convierte versión Drupal → constraint Composer
# =============================================================================
normalize_version() {
    local ver="$1"
    ver=$(echo "$ver" | sed -E 's/^[0-9]+\.x-//')
    if [[ "$ver" =~ ^[\^~\>] ]]; then echo "$ver"; return; fi
    if [[ "$ver" == "latest" ]] || [[ "$ver" == "Latest" ]]; then echo "*"; return; fi
    if [[ "$ver" =~ -dev$ ]] || [[ "$ver" =~ ^[0-9]+\.x-dev$ ]]; then echo "$ver"; return; fi
    if [[ "$ver" =~ ^([0-9]+\.[0-9]+(\.[0-9]+)?)-((alpha|beta|rc|RC)[0-9]*)$ ]]; then
        local base="${BASH_REMATCH[1]}"
        local stability
        stability=$(echo "${BASH_REMATCH[4]}" | tr '[:upper:]' '[:lower:]')
        echo "^${base}@${stability}"; return
    fi
    echo "^$ver"
}

# =============================================================================
# analyze_blockers() — Analiza errores de composer y detecta dependencias
# =============================================================================
analyze_blockers() {
    local MODULE="$1"
    local ERROR_OUTPUT="$2"

    local PROBLEMS
    PROBLEMS=$(echo "$ERROR_OUTPUT" | grep -A5 "Problem [0-9]" | grep -v "^--$" || echo "")

    if [ -z "$PROBLEMS" ]; then
        echo '{"blockers":[],"suggestion":null}'
        return
    fi

    local BLOCKERS="[]"

    while IFS= read -r BLOCKER_NAME; do
        [ -z "$BLOCKER_NAME" ] && continue
        local IN_BRIDGE="false" IN_TARGET="false" BRIDGE_VER="" TARGET_VER=""

        if [ -f "$COMPAT_FILE" ]; then
            BRIDGE_VER=$(jq -r --arg m "$BLOCKER_NAME" '
                .data.fase1_bridge[]? | select(.module == $m) | .new_version // empty
            ' "$COMPAT_FILE" 2>/dev/null || echo "")
            [ -n "$BRIDGE_VER" ] && IN_BRIDGE="true"

            TARGET_VER=$(jq -r --arg m "$BLOCKER_NAME" '
                .data.fase2_target_only[]? | select(.module == $m) | .new_version // empty
            ' "$COMPAT_FILE" 2>/dev/null || echo "")
            [ -n "$TARGET_VER" ] && IN_TARGET="true"
        fi

        BLOCKERS=$(echo "$BLOCKERS" | jq \
            --arg name "$BLOCKER_NAME" \
            --argjson ib "$IN_BRIDGE" \
            --argjson it "$IN_TARGET" \
            --arg bv "$BRIDGE_VER" \
            --arg tv "$TARGET_VER" \
            '. + [{
                module: $name,
                in_bridge_list: $ib,
                in_target_list: $it,
                bridge_version: (if $bv != "" then $bv else null end),
                target_version: (if $tv != "" then $tv else null end)
            }]')
    done < <(echo "$PROBLEMS" | grep -oE 'drupal/[a-zA-Z0-9_-]+' | sort -u | grep -v "^$MODULE$")

    local SUGGESTION="null"
    local JOINT_MODULES=""

    while IFS= read -r LINE; do
        local BNAME BVER
        BNAME=$(echo "$LINE" | jq -r '.module')
        BVER=$(echo "$LINE" | jq -r '.bridge_version // .target_version // empty')
        if [ -n "$BVER" ]; then
            JOINT_MODULES="$JOINT_MODULES ${BNAME}:$(normalize_version "$BVER")"
        fi
    done < <(echo "$BLOCKERS" | jq -c '.[] | select(.in_bridge_list or .in_target_list)')

    if [ -n "$JOINT_MODULES" ]; then
        local SUGGEST_CMD="ddev composer require${JOINT_MODULES} --ignore-platform-reqs"
        SUGGESTION=$(echo "$SUGGEST_CMD" | jq -Rs '.')
    fi

    jq -n \
        --argjson blockers "$BLOCKERS" \
        --argjson suggestion "$SUGGESTION" \
        '{blockers: $blockers, suggestion: $suggestion}'
}

# =============================================================================
# update_single_module() — Actualiza un módulo individual
# Retorna: 0=éxito, 1=fallo require, 2=fallo updb
# ⛔ NUNCA usa -W (--with-all-dependencies).
# =============================================================================
update_single_module() {
    local MODULE="$1"
    local RAW_VERSION="$2"
    local DRY_RUN="${DRY_RUN:-false}"
    local SAFE_NAME
    SAFE_NAME=$(echo "$MODULE" | tr '/' '--')
    local REPORT_FILE="$REPORT_DIR/$SAFE_NAME.json"

    local COMPOSER_VERSION
    COMPOSER_VERSION=$(normalize_version "$RAW_VERSION")

    local CURRENT_VERSION
    CURRENT_VERSION=$(jq -r --arg m "$MODULE" '
        [.packages[], ."packages-dev"[]] | map(select(.name == $m)) | .[0].version // "unknown"
    ' composer.lock 2>/dev/null || echo "unknown")

    echo ""
    echo "  📦 $MODULE: $CURRENT_VERSION → $RAW_VERSION (constraint: $COMPOSER_VERSION)"

    # Skip si ya está en la versión objetivo
    local NORM_CURRENT NORM_TARGET
    NORM_CURRENT="${CURRENT_VERSION#v}"
    NORM_TARGET="${RAW_VERSION#v}"

    normalize_for_compare() {
        local VER="$1"
        local NUM_PART SUFFIX DOTS
        NUM_PART="${VER%%-*}"
        SUFFIX=$(echo "$VER" | grep -o '\-.*' || echo "")
        DOTS=$(echo "$NUM_PART" | tr -cd '.' | wc -c | tr -d ' ')
        if [ "$DOTS" -eq 0 ]; then NUM_PART="${NUM_PART}.0.0"
        elif [ "$DOTS" -eq 1 ]; then NUM_PART="${NUM_PART}.0"; fi
        echo "${NUM_PART}${SUFFIX}"
    }

    NORM_CURRENT=$(normalize_for_compare "$NORM_CURRENT")
    NORM_TARGET=$(normalize_for_compare "$NORM_TARGET")

    if [ "$NORM_CURRENT" = "$NORM_TARGET" ]; then
        echo "    ⏭️  SKIP: ya está en versión objetivo ($CURRENT_VERSION)"
        cat > "$REPORT_FILE" << JSONEOF
{
  "module": "$MODULE",
  "timestamp": "$(date -Iseconds)",
  "status": "already_updated",
  "from_version": "$CURRENT_VERSION",
  "to_version": "$CURRENT_VERSION"
}
JSONEOF
        return 0
    fi

    # Detección de parches
    local PATCH_COUNT=0 PATCHES_JSON="[]"
    if [ -f "composer.json" ]; then
        PATCHES_JSON=$(jq --arg m "$MODULE" '
            .extra.patches[$m] // {} |
            if type == "object" then to_entries | map({name: .key, url: .value})
            elif type == "array" then map({name: "patch", url: .})
            else [] end
        ' composer.json 2>/dev/null || echo "[]")
        PATCH_COUNT=$(echo "$PATCHES_JSON" | jq 'length' 2>/dev/null || echo "0")
        PATCH_COUNT=$(echo "$PATCH_COUNT" | tr -dc '0-9')
        PATCH_COUNT=${PATCH_COUNT:-0}
    fi

    if [ "$PATCH_COUNT" -gt 0 ]; then
        echo "    ⚠️  $PATCH_COUNT parche(s) activo(s):"
        echo "$PATCHES_JSON" | jq -r '.[] | "       🩹 \(.name)"' 2>/dev/null | head -5
    fi

    # Dry-run: solo reportar sin ejecutar
    if [ "$DRY_RUN" = "true" ]; then
        echo "    (dry-run) ddev composer require ${MODULE}:${COMPOSER_VERSION} --ignore-platform-reqs"
        cat > "$REPORT_FILE" << JSONEOF
{
  "module": "$MODULE",
  "timestamp": "$(date -Iseconds)",
  "status": "dry_run",
  "from_version": "$CURRENT_VERSION",
  "to_version": "$RAW_VERSION",
  "command": "ddev composer require ${MODULE}:${COMPOSER_VERSION} --ignore-platform-reqs",
  "dry_run": true
}
JSONEOF
        return 0
    fi

    local REQUIRE_CMD="ddev composer require ${MODULE}:${COMPOSER_VERSION} --ignore-platform-reqs"
    local REQUIRE_OUTPUT
    REQUIRE_OUTPUT=$($REQUIRE_CMD 2>&1)
    local REQUIRE_EXIT=$?

    if [ $REQUIRE_EXIT -eq 124 ]; then
        echo "    ⏰ TIMEOUT (120s) — Composer no respondió a tiempo"
        cat > "$REPORT_FILE" << JSONEOF
{
  "module": "$MODULE",
  "timestamp": "$(date -Iseconds)",
  "status": "failed",
  "from_version": "$CURRENT_VERSION",
  "to_version": "$RAW_VERSION",
  "command": "$REQUIRE_CMD",
  "error_output": "Timeout: composer no respondió en 120 segundos",
  "problems": "",
  "diagnosis": {"blockers":[],"suggestion":null}
}
JSONEOF
        return 1
    fi

    # Verificar versión REAL instalada
    local UPGRADE_DETECTED="false" UPGRADE_TO=""
    if echo "$REQUIRE_OUTPUT" | grep -q "Upgrading ${MODULE}"; then
        UPGRADE_DETECTED="true"
        UPGRADE_TO=$(echo "$REQUIRE_OUTPUT" | grep "Upgrading ${MODULE}" | grep -oE '[0-9]+\.[0-9]+[^ )*]*' | tail -1)
    fi

    sync 2>/dev/null || true
    local INSTALLED_VERSION
    INSTALLED_VERSION=$(jq -r --arg m "$MODULE" '
        [.packages[], ."packages-dev"[]] | map(select(.name == $m)) | .[0].version // "unknown"
    ' composer.lock 2>/dev/null || echo "unknown")

    local VERSION_CHANGED="false"
    [ "$INSTALLED_VERSION" != "$CURRENT_VERSION" ] && [ "$INSTALLED_VERSION" != "unknown" ] && VERSION_CHANGED="true"

    if [ "$VERSION_CHANGED" = "true" ] || [ "$UPGRADE_DETECTED" = "true" ]; then
        local FINAL_VER="${INSTALLED_VERSION}"
        [ "$FINAL_VER" = "$CURRENT_VERSION" ] && [ -n "$UPGRADE_TO" ] && FINAL_VER="$UPGRADE_TO"
        [ $REQUIRE_EXIT -ne 0 ] && echo "    ⚠️ Composer reportó warnings pero el módulo SÍ se actualizó"
        echo "    ✅ $CURRENT_VERSION → $FINAL_VER"

        local PATCHES_STATUS="none" PATCHES_FAILED="[]" PATCHES_OK="[]"
        if [ "$PATCH_COUNT" -gt 0 ]; then
            local FAILED_PATCHES APPLIED_PATCHES
            FAILED_PATCHES=$(echo "$REQUIRE_OUTPUT" | grep -i "could not apply patch\|patch failed\|cannot apply\|patching failed" || echo "")
            APPLIED_PATCHES=$(echo "$REQUIRE_OUTPUT" | grep -i "Applying patch" | grep -i "$MODULE" || echo "")
            if [ -n "$FAILED_PATCHES" ]; then
                PATCHES_STATUS="some_failed"
                echo "    ⚠️  PARCHES CON PROBLEMAS:"
                echo "$FAILED_PATCHES" | head -5 | sed 's/^/       ❌ /'
                PATCHES_FAILED=$(echo "$FAILED_PATCHES" | jq -R -s 'split("\n") | map(select(length > 0))' 2>/dev/null || echo "[]")
            elif [ -n "$APPLIED_PATCHES" ]; then
                PATCHES_STATUS="all_applied"
                echo "    🩹 Parches aplicados correctamente"
                PATCHES_OK=$(echo "$APPLIED_PATCHES" | jq -R -s 'split("\n") | map(select(length > 0))' 2>/dev/null || echo "[]")
            else
                PATCHES_STATUS="not_verified"
                echo "    🩹 $PATCH_COUNT parche(s) — verificar manualmente"
            fi
        fi

        cat > "$REPORT_FILE" << JSONEOF
{
  "module": "$MODULE",
  "timestamp": "$(date -Iseconds)",
  "status": "updated",
  "from_version": "$CURRENT_VERSION",
  "to_version": "$FINAL_VER",
  "command": "$REQUIRE_CMD",
  "composer_exit_code": $REQUIRE_EXIT,
  "patches": {
    "count": $PATCH_COUNT,
    "status": "$PATCHES_STATUS",
    "definitions": $PATCHES_JSON,
    "failed": $PATCHES_FAILED,
    "applied": $PATCHES_OK
  }
}
JSONEOF
        return 0
    fi

    if [ $REQUIRE_EXIT -eq 0 ]; then
        echo "    ✅ $CURRENT_VERSION → $INSTALLED_VERSION"
        cat > "$REPORT_FILE" << JSONEOF
{
  "module": "$MODULE",
  "timestamp": "$(date -Iseconds)",
  "status": "updated",
  "from_version": "$CURRENT_VERSION",
  "to_version": "$INSTALLED_VERSION",
  "command": "$REQUIRE_CMD",
  "patches": {
    "count": $PATCH_COUNT,
    "status": "$([ "$PATCH_COUNT" -gt 0 ] && echo "not_verified" || echo "none")",
    "definitions": $PATCHES_JSON
  }
}
JSONEOF
        return 0
    fi

    # Fallo real
    echo "    ❌ FALLO"
    local CLEAN_ERROR
    CLEAN_ERROR=$(echo "$REQUIRE_OUTPUT" | grep -v "Deprecation Notice" | grep -v "^$" | tail -20)
    echo "$CLEAN_ERROR" | head -5 | sed 's/^/    /'

    local PROBLEMS HAS_FATAL
    PROBLEMS=$(echo "$REQUIRE_OUTPUT" | grep -A5 "Problem [0-9]" | grep -v "^--$" || echo "")
    HAS_FATAL=$(echo "$REQUIRE_OUTPUT" | grep -ci "PHP Fatal error\|Fatal error:" 2>/dev/null || true)
    HAS_FATAL=$(echo "$HAS_FATAL" | head -1 | tr -dc '0-9')
    HAS_FATAL=${HAS_FATAL:-0}

    echo "    🔍 Analizando bloqueadores..."
    local DIAGNOSIS
    DIAGNOSIS=$(analyze_blockers "$MODULE" "$REQUIRE_OUTPUT")

    local BLOCKER_COUNT
    BLOCKER_COUNT=$(echo "$DIAGNOSIS" | jq '.blockers | length' 2>/dev/null | head -1 | tr -dc '0-9')
    BLOCKER_COUNT=${BLOCKER_COUNT:-0}

    local IS_BLOCKED="false" BLOCK_REASON=""
    if [ "$BLOCKER_COUNT" -gt 0 ]; then
        IS_BLOCKED="true"; BLOCK_REASON="Dependencia bloqueante"
        echo "    📋 Bloqueadores detectados:"
        echo "$DIAGNOSIS" | jq -r '.blockers[] | "       → \(.module)"' 2>/dev/null | head -5
        local SUGG
        SUGG=$(echo "$DIAGNOSIS" | jq -r '.suggestion // empty' 2>/dev/null)
        [ -n "$SUGG" ] && echo "    💡 $SUGG"
    elif [ -n "$PROBLEMS" ]; then
        IS_BLOCKED="true"; BLOCK_REASON="Conflicto de dependencias (Problem)"
    elif [ "$HAS_FATAL" -gt 0 ]; then
        IS_BLOCKED="true"; BLOCK_REASON="PHP Fatal error — incompatibilidad con core actual"
    fi

    local FINAL_STATUS="failed"
    if [ "$IS_BLOCKED" = "true" ]; then
        FINAL_STATUS="blocked_manual"
        echo "    🚫 Marcado como MANUAL — $BLOCK_REASON"
    fi

    cat > "$REPORT_FILE" << JSONEOF
{
  "module": "$MODULE",
  "timestamp": "$(date -Iseconds)",
  "status": "$FINAL_STATUS",
  "block_reason": $(echo "$BLOCK_REASON" | jq -Rs '.'),
  "from_version": "$CURRENT_VERSION",
  "to_version": "$RAW_VERSION",
  "installed_version": "$INSTALLED_VERSION",
  "command": "$REQUIRE_CMD",
  "error_output": $(echo "$CLEAN_ERROR" | jq -Rs '.'),
  "problems": $(echo "$PROBLEMS" | jq -Rs '.'),
  "diagnosis": $(echo "$DIAGNOSIS" | jq '.' 2>/dev/null || echo '{}'),
  "patches": {
    "count": $PATCH_COUNT,
    "status": "not_updated",
    "definitions": $PATCHES_JSON
  }
}
JSONEOF
    return 1
}
