#!/bin/bash

if [ $# -ne 1 ]; then
    echo "usage: $0 <domain>"
    exit 1
fi

DOMAIN=$1

echo "Running certbot for domain $DOMAIN"

[ -t 1 ] && TTY_FLAGS="-ti" || TTY_FLAGS=""

docker run --rm --name certbot --hostname certbot $TTY_FLAGS \
    -v /var/run/docker.sock:/var/run/docker.sock \
    -v "$PWD/burp/conf":/opt/burp/conf \
    -v "$PWD/certbot/logs":/var/log/letsencrypt \
    -v "$PWD/certbot/letsencrypt":/etc/letsencrypt/ \
    certbot-burp certonly \
    -d "$DOMAIN" -d "*.$DOMAIN" \
    --server https://acme-v02.api.letsencrypt.org/directory \
    --agree-tos --no-eff-email \
    --manual --preferred-challenges dns-01 \
    --manual-auth-hook /opt/hooks/auth-hook.sh \
    --manual-cleanup-hook /opt/hooks/cleanup-hook.sh \
    --register-unsafely-without-email \
    --non-interactive
