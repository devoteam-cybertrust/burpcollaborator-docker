#!/bin/bash
if [ $# -ne 1 ]; then
echo usage: ./$0 \<domain\>
exit 0
fi

DOMAIN=$1

docker run --rm --name certbot --hostname certbot -ti -v $PWD/certbot/docker/docker-entrypoint-renew.sh:/docker-entrypoint.sh -v $PWD/certbot/logs:/var/log/letsencrypt -v $PWD/certbot/letsencrypt:/etc/letsencrypt/ certbot  certonly -d $DOMAIN -d *.$DOMAIN --server https://acme-v02.api.letsencrypt.org/directory --manual --agree-tos --no-eff-email --manual-public-ip-logging-ok --preferred-challenges dns-01
