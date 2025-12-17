#!/bin/sh

# Disable output buffering for real-time logs
export PYTHONUNBUFFERED=1
stty -icanon 2>/dev/null || true

# Configuration via environment variables
GLUETUN_API_URL="${GLUETUN_API_URL:-http://gluetun:8000}"
QBITTORRENT_API_URL="${QBITTORRENT_API_URL:-http://qbittorrent:8080}"
QBITTORRENT_USERNAME="${QBITTORRENT_USERNAME:-admin}"
QBITTORRENT_PASSWORD="${QBITTORRENT_PASSWORD:-adminadmin}"
CHECK_INTERVAL="${CHECK_INTERVAL:-300}"
RETRY_INTERVAL="${RETRY_INTERVAL:-60}"
LOG_LEVEL="${LOG_LEVEL:-INFO}"  # INFO or DEBUG

# Logging functions
log_info() {
  echo "[$(date '+%Y-%m-%d %H:%M:%S')] [INFO] $*"
}

log_debug() {
  if [ "$LOG_LEVEL" = "DEBUG" ]; then
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] [DEBUG] $*"
  fi
}

log_error() {
  echo "[$(date '+%Y-%m-%d %H:%M:%S')] [ERROR] $*" >&2
}

log_info "Starting Gluetun Port Forward Sync..."
log_info "Gluetun API: $GLUETUN_API_URL"
log_info "qBittorrent API: $QBITTORRENT_API_URL"
log_info "Check interval: ${CHECK_INTERVAL}s"
log_info "Log level: $LOG_LEVEL"

while true; do
  log_info "Retrieving port from Gluetun..."

  RESPONSE=$(curl -s -w "\n%{http_code}" "$GLUETUN_API_URL/v1/openvpn/portforwarded")
  HTTP_CODE=$(echo "$RESPONSE" | tail -n1)
  BODY=$(echo "$RESPONSE" | head -n-1)

  log_debug "Gluetun HTTP response code: $HTTP_CODE"
  log_debug "Gluetun response body: $BODY"

  PORT=$(echo "$BODY" | jq -r .port 2>/dev/null)

  if [ -z "$PORT" ] || [ "$PORT" = "null" ] || [ "$HTTP_CODE" != "200" ]; then
    log_error "Failed to get port from Gluetun (HTTP $HTTP_CODE), retrying in ${RETRY_INTERVAL}s..."
    sleep "$RETRY_INTERVAL"
    continue
  fi

  log_info "Got forwarded port: $PORT"

  # Login to qBittorrent
  log_debug "Logging into qBittorrent..."
  LOGIN_RESPONSE=$(curl -s -w "\n%{http_code}" --cookie-jar /tmp/cookies.txt \
    --data "username=$QBITTORRENT_USERNAME" \
    --data "password=$QBITTORRENT_PASSWORD" \
    "$QBITTORRENT_API_URL/api/v2/auth/login")

  LOGIN_CODE=$(echo "$LOGIN_RESPONSE" | tail -n1)
  log_debug "qBittorrent login HTTP response code: $LOGIN_CODE"

  if [ "$LOGIN_CODE" != "200" ]; then
    log_error "Failed to login to qBittorrent (HTTP $LOGIN_CODE), retrying in ${RETRY_INTERVAL}s..."
    sleep "$RETRY_INTERVAL"
    continue
  fi

  # Get current port
  log_debug "Getting current qBittorrent port..."
  PREFS_RESPONSE=$(curl -s -w "\n%{http_code}" --cookie /tmp/cookies.txt \
    "$QBITTORRENT_API_URL/api/v2/app/preferences")

  PREFS_CODE=$(echo "$PREFS_RESPONSE" | tail -n1)
  PREFS_BODY=$(echo "$PREFS_RESPONSE" | head -n-1)

  log_debug "qBittorrent preferences HTTP response code: $PREFS_CODE"

  CURRENT=$(echo "$PREFS_BODY" | jq -r .listen_port 2>/dev/null)

  if [ "$PORT" = "$CURRENT" ]; then
    log_info "Port already set to $PORT, sleeping ${CHECK_INTERVAL}s..."
  else
    log_info "Updating qBittorrent port from $CURRENT to $PORT..."

    UPDATE_RESPONSE=$(curl -s -w "\n%{http_code}" --cookie /tmp/cookies.txt \
      --data-urlencode "json={\"listen_port\":$PORT}" \
      "$QBITTORRENT_API_URL/api/v2/app/setPreferences")

    UPDATE_CODE=$(echo "$UPDATE_RESPONSE" | tail -n1)
    log_debug "qBittorrent update HTTP response code: $UPDATE_CODE"

    if [ "$UPDATE_CODE" = "200" ]; then
      log_info "Port updated successfully!"
    else
      log_error "Failed to update port (HTTP $UPDATE_CODE)"
    fi
  fi

  sleep "$CHECK_INTERVAL"
done
