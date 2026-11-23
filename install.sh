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

echo "==> Downloading site"
TMP=/tmp/latent-field-site.tar.gz
rm -f "$TMP"
OK=0
for url in \
  "https://gh-proxy.com/https://raw.githubusercontent.com/superzxs/latent-field-preview/main/latent-field-preview.tar.gz" \
  "https://ghfast.top/https://raw.githubusercontent.com/superzxs/latent-field-preview/main/latent-field-preview.tar.gz" \
  "https://ghproxy.net/https://raw.githubusercontent.com/superzxs/latent-field-preview/main/latent-field-preview.tar.gz" \
  "https://raw.githubusercontent.com/superzxs/latent-field-preview/main/latent-field-preview.tar.gz"
do
  echo "Trying: $url"
  if curl -fL --retry 1 --connect-timeout 10 --max-time 120 "$url" -o "$TMP"; then
    OK=1
    break
  fi
done

if [ "$OK" -ne 1 ]; then
  echo "Failed to download site archive."
  exit 1
fi

echo "==> Extracting"
rm -rf /var/www/latent-field
mkdir -p /var/www/latent-field
tar -xzf "$TMP" -C /var/www/latent-field

if [ ! -f /var/www/latent-field/index.html ]; then
  echo "index.html missing after extract."
  exit 1
fi
chown -R www-data:www-data /var/www/latent-field

echo "==> Configuring nginx"
cat > /etc/nginx/sites-available/latent-field <<'NGINX'
server {
    listen 80 default_server;
    listen [::]:80 default_server;
    server_name _;
    root /var/www/latent-field;
    index index.html;

    charset utf-8;

    location /_astro/ {
        try_files $uri =404;
        expires 30d;
        add_header Cache-Control "public, max-age=2592000, immutable";
    }

    location / {
        try_files $uri $uri/ =404;
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
curl -s http://127.0.0.1/ | grep -o '<title>[^<]*</title>' | head -n 1
echo "DONE: http://119.91.193.252/"
