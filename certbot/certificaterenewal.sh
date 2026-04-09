#!/bin/sh

# Renew certificates every X days
#
# requires openssl, bc, and jq
#

RENEWDAYS=30

BASEDIR=$(cd "$(dirname "$0")/.." && pwd)
DOMAIN=$(jq -r '.serverDomain' < "$BASEDIR/burp/conf/burp.config")

CURRENT=$(/bin/date +%s)
CERTIFICATE=$(/usr/bin/openssl x509 -noout -dates -in "$BASEDIR/certbot/letsencrypt/live/$DOMAIN/cert.pem" | /bin/grep notAfter | /usr/bin/cut -d "=" -f 2)
CERTDATE=$(/bin/date -d "$CERTIFICATE" +%s)

DAYS=$(/bin/echo \("$CERTDATE" - "$CURRENT"\)/60/60/24 | /usr/bin/bc)

echo "Certificate renewal job started at $(date) as user $(whoami)"

if [ "$DAYS" -ge "$RENEWDAYS" ]; then
    echo "Still $DAYS days to expire. Not renewing."
    exit 0
fi

echo "Renewing certificate..."

cd "$BASEDIR"
"$BASEDIR/certbot/renew.sh" && \
/bin/cp -L -f "$BASEDIR/certbot/letsencrypt/live/$DOMAIN/cert.pem" "$BASEDIR/burp/keys/cert.pem" && \
/bin/cp -L -f "$BASEDIR/certbot/letsencrypt/live/$DOMAIN/chain.pem" "$BASEDIR/burp/keys/chain.pem" && \
/bin/cp -L -f "$BASEDIR/certbot/letsencrypt/live/$DOMAIN/fullchain.pem" "$BASEDIR/burp/keys/fullchain.pem" && \
/bin/cp -L -f "$BASEDIR/certbot/letsencrypt/live/$DOMAIN/privkey.pem" "$BASEDIR/burp/keys/privkey.pem" && \
chown 999:999 "$BASEDIR/burp/keys/privkey.pem" && \
docker restart burp && \
echo "Certificate renewed"

echo "Waiting 5 seconds to verify..."
sleep 5

if [ ! "$(docker ps -q -f name=burp)" ]; then
    if [ "$(docker ps -aq -f status=exited -f name=burp)" ]; then
        docker rm burp
    fi

    "$BASEDIR/burp/run.sh"
    echo "burp docker has been restarted"
else
    echo "burp docker is running"
fi
