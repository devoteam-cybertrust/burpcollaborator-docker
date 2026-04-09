#!/bin/sh
#
# Certbot auth hook for DNS-01 challenge.
# Adds an _acme-challenge TXT record to Burp Collaborator's config
# and restarts Burp so it serves the record via its built-in DNS.
#
# Certbot provides: CERTBOT_DOMAIN, CERTBOT_VALIDATION

CONFIG=/opt/burp/conf/burp.config

# Append a TXT record to customDnsRecords (create array if absent)
jq --arg val "$CERTBOT_VALIDATION" '
  if .customDnsRecords then
    .customDnsRecords += [{"label": "_acme-challenge", "type": "TXT", "record": $val, "ttl": 60}]
  else
    .customDnsRecords = [{"label": "_acme-challenge", "type": "TXT", "record": $val, "ttl": 60}]
  end
' "$CONFIG" > "$CONFIG.tmp" && mv "$CONFIG.tmp" "$CONFIG"

# Restart Burp to pick up the new DNS record
docker restart -t 5 burp

# Wait for Burp to start and serve the new record
echo "Waiting for Burp restart..."
sleep 10
