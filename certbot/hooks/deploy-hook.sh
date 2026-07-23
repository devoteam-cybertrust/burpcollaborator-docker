#!/bin/sh

set -eu

: "${RENEWED_LINEAGE:?Certbot did not provide RENEWED_LINEAGE}"

cp -L -f "$RENEWED_LINEAGE/cert.pem" /opt/burp/keys/cert.pem
cp -L -f "$RENEWED_LINEAGE/chain.pem" /opt/burp/keys/chain.pem
cp -L -f "$RENEWED_LINEAGE/fullchain.pem" /opt/burp/keys/fullchain.pem
cp -L -f "$RENEWED_LINEAGE/privkey.pem" /opt/burp/keys/privkey.pem
chown 999:999 /opt/burp/keys/privkey.pem

docker restart burp
echo "Burp Collaborator is now using the renewed certificate."
