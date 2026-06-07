#!/usr/bin/env bash
# =============================================================================
# scripts/dev-tunnel.sh — start a Cloudflare quick tunnel and point n8n at it
# -----------------------------------------------------------------------------
# The Telegram trigger is webhook-based, so n8n needs a public HTTPS URL that
# Telegram can reach. The free "quick tunnel" gives a *random* URL that changes
# every time it restarts. This script:
#   1. starts the quick tunnel to n8n (localhost:5678),
#   2. captures the generated https://*.trycloudflare.com URL,
#   3. writes it to N8N_BASE_URL in .env,
#   4. recreates the n8n container so WEBHOOK_URL picks it up.
#
# n8n re-registers the Telegram webhook for ACTIVE workflows on startup, so as
# long as the workflow is toggled Active ONCE, this is all you need to run.
#
# Keep this process running (it holds the tunnel open). Re-run it after a reboot
# or whenever the tunnel drops.   Requires: cloudflared, docker compose.
# =============================================================================
set -euo pipefail
cd "$(dirname "$0")/.."

command -v cloudflared >/dev/null 2>&1 || { echo "ERROR: cloudflared is not installed."; exit 1; }
[ -f .env ] || { echo "ERROR: .env not found in $(pwd)."; exit 1; }

PORT="${N8N_PORT:-5678}"
LOG="$(mktemp)"
echo "▶ Starting Cloudflare quick tunnel to http://localhost:${PORT} ..."
cloudflared tunnel --url "http://localhost:${PORT}" >"$LOG" 2>&1 &
TUN_PID=$!
trap 'echo; echo "Stopping tunnel (PID $TUN_PID)"; kill $TUN_PID 2>/dev/null || true' INT TERM

URL=""
for _ in $(seq 1 30); do
  URL="$(grep -oE 'https://[a-z0-9-]+\.trycloudflare\.com' "$LOG" | head -1 || true)"
  [ -n "$URL" ] && break
  sleep 1
done
[ -n "$URL" ] || { echo "ERROR: could not detect tunnel URL. Log: $LOG"; cat "$LOG"; kill $TUN_PID 2>/dev/null || true; exit 1; }
echo "✔ Tunnel URL: $URL"

if grep -q '^N8N_BASE_URL=' .env; then
  sed -i "s#^N8N_BASE_URL=.*#N8N_BASE_URL=${URL}#" .env
else
  printf '\nN8N_BASE_URL=%s\n' "$URL" >> .env
fi
echo "✔ Set N8N_BASE_URL in .env"

echo "▶ Recreating n8n so WEBHOOK_URL=${URL} takes effect ..."
docker compose up -d n8n
echo "✔ n8n recreated. It will re-register the Telegram webhook at ${URL}"
echo
echo "If you have NOT already: open n8n → Jarvis · Telegram Assistant → toggle Active (once)."
echo "Keep this window open — closing it drops the tunnel. Press Ctrl+C to stop."
echo "(tunnel log: $LOG)"
wait "$TUN_PID"
