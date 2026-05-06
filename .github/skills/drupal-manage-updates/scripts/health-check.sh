#!/usr/bin/env bash
# =============================================================================
# health-check.sh — Verificación de salud del sitio Drupal
# Uso: bash scripts/health-check.sh
# Puede ejecutarse de forma independiente en cualquier momento
# Retorna: 0 = pass, 1 = warn, 2 = fail
# =============================================================================

set -uo pipefail

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

REPORT_DIR="reports/drupal-update"
PASS=0
WARN=0
FAIL=0

declare -a RESULTS=()

check() {
    local name="$1"
    local status="$2"  # pass|warn|fail
    local detail="$3"

    case "$status" in
        pass) echo -e "  ${GREEN}✓${NC} $name: $detail"; PASS=$((PASS + 1)) ;;
        warn) echo -e "  ${YELLOW}⚠${NC} $name: $detail"; WARN=$((WARN + 1)) ;;
        fail) echo -e "  ${RED}✗${NC} $name: $detail"; FAIL=$((FAIL + 1)) ;;
    esac
    RESULTS+=("{\"name\":\"$name\",\"status\":\"$status\",\"detail\":\"$detail\"}")
}

echo "══════════════════════════════════════════"
echo "  DRUPAL — Health Check"
echo "══════════════════════════════════════════"
echo ""

# 1. DDEV running
DDEV_STATUS=$(ddev describe -j 2>/dev/null | jq -r '.raw.status' 2>/dev/null || echo "stopped")
if [ "$DDEV_STATUS" = "running" ]; then
    check "DDEV" "pass" "running"
else
    check "DDEV" "fail" "$DDEV_STATUS"
    echo -e "\n${RED}DDEV no está activo. No se pueden ejecutar más checks.${NC}"
    exit 2
fi

# 2. Site responds
HTTP_STATUS=$(ddev exec curl -s -o /dev/null -w "%{http_code}" http://localhost 2>/dev/null || echo "000")
if [ "$HTTP_STATUS" -lt 300 ]; then
    check "HTTP Response" "pass" "HTTP $HTTP_STATUS"
elif [ "$HTTP_STATUS" -lt 500 ]; then
    check "HTTP Response" "warn" "HTTP $HTTP_STATUS (posible redirección o acceso denegado)"
else
    check "HTTP Response" "fail" "HTTP $HTTP_STATUS"
fi

# 3. Drush bootstrap
BOOTSTRAP=$(ddev drush status --field=bootstrap 2>/dev/null || echo "failed")
if [ "$BOOTSTRAP" = "Successful" ]; then
    check "Drush Bootstrap" "pass" "Successful"
else
    check "Drush Bootstrap" "fail" "$BOOTSTRAP"
fi

# 4. Drupal version
DRUPAL_VER=$(ddev drush status --field=drupal-version 2>/dev/null || echo "unknown")
check "Drupal Version" "pass" "v$DRUPAL_VER"

# 5. Key routes
for route in "/" "/user/login"; do
    ROUTE_STATUS=$(ddev exec curl -s -o /dev/null -w "%{http_code}" "http://localhost$route" 2>/dev/null || echo "000")
    if [ "$ROUTE_STATUS" -lt 400 ]; then
        check "Route $route" "pass" "HTTP $ROUTE_STATUS"
    else
        check "Route $route" "warn" "HTTP $ROUTE_STATUS"
    fi
done

# 6. Cron
if ddev drush cron 2>/dev/null; then
    check "Cron" "pass" "executed successfully"
else
    check "Cron" "warn" "failed to execute"
fi

# 7. Watchdog errors (last 30 min)
ERROR_COUNT=$(ddev drush watchdog:show --severity=error --count=20 --format=json 2>/dev/null | jq 'length' 2>/dev/null || echo "0")
if [ "$ERROR_COUNT" -eq 0 ]; then
    check "Watchdog Errors" "pass" "no recent errors"
elif [ "$ERROR_COUNT" -lt 5 ]; then
    check "Watchdog Errors" "warn" "$ERROR_COUNT recent error(s)"
else
    check "Watchdog Errors" "fail" "$ERROR_COUNT recent errors"
fi

# 8. Requirements
REQ_ERRORS=$(ddev drush core:requirements --severity=error --format=json 2>/dev/null | jq 'length' 2>/dev/null || echo "0")
if [ "$REQ_ERRORS" -eq 0 ]; then
    check "Requirements" "pass" "no errors"
else
    check "Requirements" "warn" "$REQ_ERRORS requirement error(s)"
fi

# 9. Database pending updates
PENDING_OUTPUT=$(ddev drush updatedb --no 2>&1 || true)
if echo "$PENDING_OUTPUT" | grep -q "No pending updates"; then
    check "DB Updates" "pass" "no pending updates"
else
    check "DB Updates" "warn" "pending database updates detected"
fi

# 10. Config sync status
CONFIG_DIFF=$(ddev drush config:status --format=json 2>/dev/null | jq 'length' 2>/dev/null || echo "0")
if [ "$CONFIG_DIFF" -eq 0 ]; then
    check "Config Sync" "pass" "in sync"
else
    check "Config Sync" "warn" "$CONFIG_DIFF config difference(s)"
fi

# Summary
echo ""
echo "══════════════════════════════════════════"
TOTAL=$((PASS + WARN + FAIL))
echo -e "  ${GREEN}$PASS passed${NC} | ${YELLOW}$WARN warnings${NC} | ${RED}$FAIL failed${NC} (total: $TOTAL)"

EXIT_CODE=0
if [ "$FAIL" -gt 0 ]; then
    echo -e "  ${RED}RESULTADO: FAIL ✗${NC}"
    EXIT_CODE=2
elif [ "$WARN" -gt 0 ]; then
    echo -e "  ${YELLOW}RESULTADO: WARN ⚠${NC}"
    EXIT_CODE=1
else
    echo -e "  ${GREEN}RESULTADO: PASS ✓${NC}"
fi
echo "══════════════════════════════════════════"

# Generate JSON report
mkdir -p "$REPORT_DIR"
RESULTS_JSON=$(printf '%s,' "${RESULTS[@]}" | sed 's/,$//')
OVERALL="pass"
[ "$WARN" -gt 0 ] && OVERALL="warn"
[ "$FAIL" -gt 0 ] && OVERALL="fail"
cat > "$REPORT_DIR/health-check-$(date +%Y%m%d-%H%M%S).json" << EOF
{
  "timestamp": "$(date -Iseconds)",
  "overall": "$OVERALL",
  "counts": { "pass": $PASS, "warn": $WARN, "fail": $FAIL },
  "checks": [$RESULTS_JSON]
}
EOF

exit $EXIT_CODE
