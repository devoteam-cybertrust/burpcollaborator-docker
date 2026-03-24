#!/bin/bash

if [ $# -ne 1 ]; then
echo usage: ./$0 \<domain\>
exit 0
fi

DOMAIN=$1

echo Running certbot for domain $DOMAIN

# Check if stdout is connected to a terminal. Only apply -ti if this is the case.
[ -t 1 ] && TTY_FLAGS="-ti" || TTY_FLAGS=""
docker run --rm --name certbot --hostname certbot $TTY_FLAGS -p 53:53/udp -p 53:53 -v $PWD/certbot/logs:/var/log/letsencrypt -v $PWD/certbot/letsencrypt:/etc/letsencrypt/ certbot-burp renew --force-renewal
