#!/usr/bin/env bash
set -euo pipefail

if [ "$(id -u)" -ne 0 ]; then
  echo "Please run: curl -fsSL <url> | sudo bash"
  exit 1
fi

export DEBIAN_FRONTEND=noninteractive

echo "==> Installing nginx"
apt-get update -y
apt-get install -y nginx unzip curl ca-certificates

echo "==> Downloading preview"
mkdir -p /var/www/latent-field
rm -rf /var/www/latent-field/*
ZIP_OK=0
for url in \
  "https://cdn.jsdelivr.net/gh/superzxs/latent-field-preview@main/latent-field-preview.zip" \
  "https://raw.githubusercontent.com/superzxs/latent-field-preview/main/latent-field-preview.zip"
do
  if curl -fL --retry 3 --connect-timeout 15 "$url" -o /tmp/latent-field-preview.zip; then
    ZIP_OK=1
    break
  fi
done

if [ "$ZIP_OK" -ne 1 ]; then
  echo "Failed to download preview zip."
  exit 1
fi

unzip -oq /tmp/latent-field-preview.zip -d /var/www/latent-field
chown -R www-data:www-data /var/www/latent-field

echo "==> Configuring nginx"
cat > /etc/nginx/sites-available/latent-field <<'NGINX'
server {
    listen 80 default_server;
    listen [::]:80 default_server;
    server_name _;
    root /var/www/latent-field;
    index index.html;

    location / {
        try_files $uri $uri/ =404;
    }

    location = /404.html {
        internal;
    }

    error_page 404 /404.html;
}
NGINX

rm -f /etc/nginx/sites-enabled/default
ln -sf /etc/nginx/sites-available/latent-field /etc/nginx/sites-enabled/latent-field

nginx -t
systemctl enable nginx
systemctl restart nginx

echo "==> Health check"
curl -sI http://127.0.0.1/ | head -n 1
echo "DONE: http://119.91.193.252/"
