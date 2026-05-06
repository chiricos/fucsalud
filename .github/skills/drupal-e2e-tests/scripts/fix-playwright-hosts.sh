#!/usr/bin/env bash
# =============================================================================
# fix-playwright-hosts.sh — Fix DNS resolution inside the Playwright container
#
# Docker DNS propagates 127.0.0.1 for *.ddev.site from the host, but inside
# the Playwright container 127.0.0.1 is its own loopback. This script adds
# the correct entries pointing to the ddev-router (traefik) IP.
#
# Run after each `ddev start` or `ddev restart`.
# Usage: bash scripts/fix-playwright-hosts.sh
# =============================================================================

set -euo pipefail

echo "🔧 Fixing DNS entries in the Playwright container..."

# Get the ddev-router IP from the DDEV network
ROUTER_IP=$(docker inspect -f '{{range .NetworkSettings.Networks}}{{.IPAddress}}{{end}}' ddev-router 2>/dev/null || true)

if [ -z "$ROUTER_IP" ]; then
    echo "❌ Could not find ddev-router container. Is DDEV running?"
    echo "   Run: ddev start"
    exit 1
fi

echo "   ddev-router IP: $ROUTER_IP"

# Get the Playwright container name
PW_CONTAINER=$(docker ps --filter "name=playwright" --format '{{.Names}}' | grep -v "^$" | head -1)

if [ -z "$PW_CONTAINER" ]; then
    echo "❌ Playwright container not found. Is the Playwright addon installed?"
    echo "   Run: ddev add-on get julienloizelet/ddev-playwright && ddev restart"
    exit 1
fi

echo "   Playwright container: $PW_CONTAINER"

# Get all *.ddev.site hostnames from the ddev-router
DDEV_HOSTS=$(docker exec ddev-router sh -c 'cat /etc/hosts' 2>/dev/null | grep 'ddev.site' | awk '{print $2}' | sort -u)

if [ -z "$DDEV_HOSTS" ]; then
    # Fallback: detect from ddev describe
    DDEV_HOSTS=$(ddev describe -j 2>/dev/null | python3 -c "
import sys, json
try:
    data = json.load(sys.stdin)
    urls = data.get('raw', {}).get('hostnames', [])
    for h in urls:
        print(h)
except:
    pass
" 2>/dev/null || true)
fi

if [ -z "$DDEV_HOSTS" ]; then
    echo "❌ No *.ddev.site hosts could be detected."
    echo "   Ensure DDEV is running and try: ddev describe"
    exit 1
fi

# Remove old entries and add correct ones
for HOST in $DDEV_HOSTS; do
    docker exec "$PW_CONTAINER" sh -c 'sed -i "/$1/d" /etc/hosts 2>/dev/null; printf "%s %s\n" "$2" "$1" >> /etc/hosts' -- "$HOST" "$ROUTER_IP"
    echo "   ✅ $HOST → $ROUTER_IP"
done

echo ""
echo "✅ DNS entries updated in Playwright container."
echo "   Verify with: ddev exec -s playwright getent hosts <hostname>"
