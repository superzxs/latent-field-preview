#!/usr/bin/env bash
# One-time setup: installs the auto-update job on the server.
# After this, publishing from the local machine updates the site within ~5 minutes.
set -euo pipefail

if [ "$(id -u)" -ne 0 ]; then
  echo "Please run: curl -fsSL <url> | sudo bash"
  exit 1
fi

BASE=raw.githubusercontent.com/superzxs/latent-field-preview/main
MIRRORS=(
  "https://gh-proxy.com/https://$BASE"
  "https://ghfast.top/https://$BASE"
  "https://ghproxy.net/https://$BASE"
  "https://$BASE"
)

export DEBIAN_FRONTEND=noninteractive
command -v curl >/dev/null || apt-get install -y curl
command -v flock >/dev/null || apt-get install -y util-linux
if ! dpkg -s cron >/dev/null 2>&1; then
  apt-get update -y
  apt-get install -y cron
fi
systemctl enable --now cron

echo "==> Installing /usr/local/bin/latent-field-sync"
OK=0
for base in "${MIRRORS[@]}"; do
  echo "Trying: $base/sync.sh"
  if curl -fsSL --connect-timeout 10 --max-time 60 "$base/sync.sh?t=$(date +%s)" -o /usr/local/bin/latent-field-sync; then
    OK=1
    break
  fi
done

if [ "$OK" -ne 1 ]; then
  echo "Failed to download sync.sh"
  exit 1
fi
chmod 755 /usr/local/bin/latent-field-sync

echo "==> Installing cron job (every 5 minutes)"
cat > /etc/cron.d/latent-field <<'CRON'
SHELL=/bin/bash
PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin
*/5 * * * * root /usr/local/bin/latent-field-sync >> /var/log/latent-field-sync.log 2>&1
CRON
chmod 644 /etc/cron.d/latent-field

echo "==> Running first sync now"
/usr/local/bin/latent-field-sync || true

echo "==> Done"
echo "Auto-update installed. Logs: /var/log/latent-field-sync.log"
echo "Site: http://119.91.193.252/"
