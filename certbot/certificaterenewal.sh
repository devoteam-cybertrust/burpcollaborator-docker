#!/bin/sh

set -eu

BASEDIR=$(cd "$(dirname "$0")/.." && pwd)
cd "$BASEDIR"

# Certbot decides whether renewal is due. Its deploy hook updates the mounted
# Burp keys and restarts Burp only when a certificate was actually renewed.
exec "$BASEDIR/certbot/renew.sh"
