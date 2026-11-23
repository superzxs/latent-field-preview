#!/usr/bin/env bash
# Pull the latest published build and swap it in. Safe to run repeatedly.
# Installed on the server as /usr/local/bin/latent-field-sync (cron every 5 min).
set -uo pipefail

ROOT=/var/www/latent-field
STATE=/var/lib/latent-field
BASE=raw.githubusercontent.com/superzxs/latent-field-preview/main
MIRRORS=(
  "https://gh-proxy.com/https://$BASE"
  "https://ghfast.top/https://$BASE"
  "https://ghproxy.net/https://$BASE"
  "https://$BASE"
)

mkdir -p "$STATE"

# One run at a time.
exec 9>/var/lock/latent-field-sync.lock
flock -n 9 || exit 0

log() { echo "[$(date '+%Y-%m-%d %H:%M:%S')] $*"; }

TMP=$(mktemp -d)
trap 'rm -rf "$TMP"' EXIT

fetch() { # fetch <remote-path> <local-file>
  local remote_path=$1 out=$2 url
  for base in "${MIRRORS[@]}"; do
    url="$base/$remote_path?bust=$(date +%s)"
    if curl -fsSL --connect-timeout 8 --max-time 90 "$url" -o "$out"; then
      return 0
    fi
  done
  return 1
}

if ! fetch version.txt "$TMP/version.txt"; then
  log "version check failed (network), skipping"
  exit 0
fi

NEW=$(tr -d '[:space:]' < "$TMP/version.txt")
if [ -z "$NEW" ]; then
  log "empty version, skipping"
  exit 0
fi

CURRENT=$(cat "$STATE/version" 2>/dev/null | tr -d '[:space:]')
if [ "$NEW" = "$CURRENT" ]; then
  exit 0
fi

log "updating $CURRENT -> $NEW"

if ! fetch latent-field-preview.tar.gz "$TMP/site.tar.gz"; then
  log "archive download failed"
  exit 1
fi

mkdir -p "$TMP/site"
if ! tar -xzf "$TMP/site.tar.gz" -C "$TMP/site"; then
  log "extract failed"
  exit 1
fi

if [ ! -f "$TMP/site/index.html" ]; then
  log "index.html missing after extract, aborting"
  exit 1
fi

chown -R www-data:www-data "$TMP/site"

rm -rf "$ROOT.new" "$ROOT.old"
mv "$TMP/site" "$ROOT.new"
if [ -d "$ROOT" ]; then
  mv "$ROOT" "$ROOT.old"
fi
mv "$ROOT.new" "$ROOT"

if systemctl reload nginx 2>/dev/null || systemctl restart nginx; then
  echo "$NEW" > "$STATE/version"
  rm -rf "$ROOT.old"
  log "deployed $NEW"
else
  log "nginx reload failed, rolling back"
  rm -rf "$ROOT.broken"
  mv "$ROOT" "$ROOT.broken"
  if [ -d "$ROOT.old" ]; then mv "$ROOT.old" "$ROOT"; fi
  systemctl restart nginx
  exit 1
fi
