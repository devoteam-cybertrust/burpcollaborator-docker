#!/bin/bash

if [ $# -ne 3 ]; then
echo usage: ./$0 \<domain\> \<acme challenge 1\> \<acme challenge 2\>
exit 0
fi

DOMAIN=$1

ACMECHALLENGEONE=$2
ACMECHALLENGETWO=$3

# run dnsmasq
docker run -d --rm --name dnsmasq -p 53:5353/udp -p 53:5353 dnsmasq -d -q --dns-rr=$DOMAIN,257,000569737375656C657473656E63727970742E6F7267 --txt-record=_acme-challenge.$DOMAIN,"$ACMECHALLENGEONE" --txt-record=_acme-challenge.$DOMAIN,"$ACMECHALLENGETWO" --no-resolv --port=5353  && \

# prepare renewal
echo docker run -d --rm --name dnsmasq -p 53:5353/udp -p 53:5353 dnsmasq -d -q --dns-rr=$DOMAIN,257,000569737375656C657473656E63727970742E6F7267 --txt-record=_acme-challenge.$DOMAIN,"$ACMECHALLENGEONE" --txt-record=_acme-challenge.$DOMAIN,"$ACMECHALLENGETWO" --no-resolv --port=5353 > ./dnsmasq/renew.sh && \
/bin/chmod a+x ./dnsmasq/renew.sh
