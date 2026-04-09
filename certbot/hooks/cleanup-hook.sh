#!/bin/sh
#
# Certbot cleanup hook. Removes _acme-challenge TXT records
# from Burp Collaborator's config after validation.
#

CONFIG=/opt/burp/conf/burp.config

jq 'del(.customDnsRecords[] | select(.label == "_acme-challenge"))' \
  "$CONFIG" > "$CONFIG.tmp" && mv "$CONFIG.tmp" "$CONFIG"
