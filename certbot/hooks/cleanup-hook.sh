#!/bin/sh
set -eu
#
# Certbot cleanup hook. Removes _acme-challenge TXT records
# from Burp Collaborator's config after validation.
#

CONFIG=/opt/burp/conf/burp.config
TMP="$CONFIG.tmp.$$"
trap 'rm -f "$TMP"' EXIT HUP INT TERM

jq --arg val "$CERTBOT_VALIDATION" '
  .customDnsRecords = [
    (.customDnsRecords // [])[] |
    select(.label != "_acme-challenge" or .record != $val)
  ]
' "$CONFIG" > "$TMP"
mv "$TMP" "$CONFIG"

# Remove the validated token from the live DNS server as well as from disk.
docker restart -t 5 burp
