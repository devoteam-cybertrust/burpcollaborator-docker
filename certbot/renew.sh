#!/bin/bash

echo "Running certbot renewal"

# Check if stdout is connected to a terminal
[ -t 1 ] && TTY_FLAGS="-ti" || TTY_FLAGS=""

docker run --rm --name certbot --hostname certbot $TTY_FLAGS \
    -v /var/run/docker.sock:/var/run/docker.sock \
    -v "$PWD/burp/conf":/opt/burp/conf \
    -v "$PWD/certbot/logs":/var/log/letsencrypt \
    -v "$PWD/certbot/letsencrypt":/etc/letsencrypt/ \
    certbot-burp renew --force-renewal
