#!/bin/sh

# Renew certificates every X days
#
# requires openssl, bc, and jq (and realpath & dirname, part of GNU coreutils)
#

RENEWDAYS=30

BASEDIR=$(realpath -m "$(dirname "$0")/..")
DOMAIN=$(jq -r '.serverDomain' < "$BASEDIR"/burp/conf/burp.config)

CURRENT=$(/bin/date +%s)
CERTIFICATE=$(/usr/bin/openssl x509 -noout -dates -in "$BASEDIR"/certbot/letsencrypt/live/"$DOMAIN"/cert.pem  | /bin/grep notAfter | /usr/bin/cut -d "=" -f 2)
CERTDATE=$(/bin/date -d "$CERTIFICATE" +%s)

DAYS=$(/bin/echo \("$CERTDATE" - "$CURRENT"\)/60/60/24 | /usr/bin/bc)

echo "Certificate renewal job started at $(date) as user $(whoami)"

if [ $DAYS -ge $RENEWDAYS ]; then
    echo Still "$DAYS" days to expire. Not renewing
    exit 0
fi

echo Renewing certificate...

# this may fail, we don't care
docker stop burp
docker rm burp

cd "$BASEDIR"
"$BASEDIR"/certbot/renew.sh "$DOMAIN"  && \
/bin/cp -r -f -L "$BASEDIR"/certbot/letsencrypt/live/"$DOMAIN"/* "$BASEDIR"/burp/keys && \
chown 999:999 "$BASEDIR"/burp/keys/privkey.pem && \
"$BASEDIR"/burp/run.sh && \
echo Certificate renewed

echo waiting for 5 seconds just to make sure all is ok!

sleep 5

if [ ! "$(docker ps -q -f name=burp)" ]; then
    if [ "$(docker ps -aq -f status=exited -f name=burp)" ]; then
        # cleanup
        docker rm burp
    fi

    # try again?
    "$BASEDIR"/burp/run.sh
    echo burp docker has been restarted
else
    echo burp docker is running
fi
