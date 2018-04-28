#!/bin/bash

if [ $# -ne 1 ]; then
echo usage: ./$0 \<domain\>
exit 0
fi

DOMAIN=$1

echo Running certbot for domain $DOMAIN
echo Check the acme records, and use them to run dnsmasq:
echo ~# ./dnsmasq/run.sh $DOMAIN \<acme challenge 1\> \<acme challenge 2\>
echo
read -p "Press any key to continue, or CTRL-C to bail out" var_p

docker run --rm --name certbot --hostname certbot -ti -v $PWD/certbot/logs:/var/log/letsencrypt -v $PWD/certbot/letsencrypt:/etc/letsencrypt/ certbot  certonly -d $DOMAIN -d *.$DOMAIN --server https://acme-v02.api.letsencrypt.org/directory --manual --agree-tos --no-eff-email --manual-public-ip-logging-ok --preferred-challenges dns-01
