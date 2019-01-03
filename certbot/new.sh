#!/bin/bash

if [ $# -ne 1 ]; then
echo usage: ./$0 \<domain\>
exit 0
fi

DOMAIN=$1

echo Running certbot for domain $DOMAIN
echo
read -p "Press any key to continue, or CTRL-C to bail out" var_p

docker run --rm --name certbot --hostname certbot -ti  -p 53:53/udp -p 53:53 -v $PWD/certbot/logs:/var/log/letsencrypt -v $PWD/certbot/letsencrypt:/etc/letsencrypt/ certbot-burp  certonly -d $DOMAIN -d *.$DOMAIN --server https://acme-v02.api.letsencrypt.org/directory --agree-tos --no-eff-email --dns-cloudflare --register-unsafely-without-email --preferred-challenges dns-01
