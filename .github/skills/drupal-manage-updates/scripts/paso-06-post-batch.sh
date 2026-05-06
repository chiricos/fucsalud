#!/usr/bin/env bash
# =============================================================================
# paso-06-post-batch.sh — Post-lote: updb + cex + commit + snapshot
#
# Uso: source "$SCRIPT_DIR/paso-06-post-batch.sh" && post_batch <label> [modules...]
# Variables de entorno: REPORT_DIR, DRY_RUN
# =============================================================================

[[ -n "${_PASO06_POSTBATCH_LOADED:-}" ]] && return 0
_PASO06_POSTBATCH_LOADED=1

REPORT_DIR="${REPORT_DIR:-reports/drupal-update/modulos}"

# =============================================================================
# post_batch() — Ejecuta updb + cex + commit + snapshot tras actualizar módulos
# =============================================================================
post_batch() {
    local BATCH_LABEL="$1"
    shift
    local MODULES_LIST="$*"
    local DRY_RUN="${DRY_RUN:-false}"

    echo ""
    echo "  ── Post-lote: updb + cex + commit ──"

    if [ "$DRY_RUN" = "true" ]; then
        echo "    (dry-run) ddev drush updb -y"
        echo "    (dry-run) ddev drush cr && ddev drush cex -y"
        echo "    (dry-run) git add -A && git commit -m \"update batch: $BATCH_LABEL\""
        echo "    (dry-run) ddev snapshot --name=post-batch-..."
        return 0
    fi

    local UPDB_OUTPUT
    UPDB_OUTPUT=$(ddev drush updb -y 2>&1)
    local UPDB_EXIT=$?

    if [ $UPDB_EXIT -ne 0 ]; then
        echo "  ❌ drush updb falló"
        echo "$UPDB_OUTPUT" | tail -5 | sed 's/^/    /'
        return 1
    fi
    echo "  ✅ drush updb OK"

    ddev drush cr 2>/dev/null || true
    ddev drush cex -y 2>/dev/null || true

    git add -A
    local COMMIT_MSG="update batch: $BATCH_LABEL"
    git commit -m "$COMMIT_MSG" 2>/dev/null || true
    local COMMIT_HASH
    COMMIT_HASH=$(git rev-parse --short HEAD 2>/dev/null || echo "unknown")

    local SNAPSHOT_NAME
    SNAPSHOT_NAME="post-batch-$(date +%Y%m%d-%H%M%S)"
    ddev snapshot --name="$SNAPSHOT_NAME" 2>/dev/null || true

    echo "  Commit: $COMMIT_HASH"
    echo "  Snapshot: $SNAPSHOT_NAME"

    for MOD in $MODULES_LIST; do
        local SAFE RFILE TMP_RF
        SAFE=$(echo "$MOD" | tr '/' '--')
        RFILE="$REPORT_DIR/$SAFE.json"
        TMP_RF="${RFILE}.tmp"
        if [ -f "$RFILE" ]; then
            jq --arg c "$COMMIT_HASH" --arg s "$SNAPSHOT_NAME" \
                '. + {commit: $c, snapshot: $s, updb: "success"}' "$RFILE" > "$TMP_RF" 2>/dev/null && mv "$TMP_RF" "$RFILE"
        fi
    done

    return 0
}
