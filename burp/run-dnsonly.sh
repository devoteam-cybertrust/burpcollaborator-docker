#!/bin/bash
# Start Burp with only DNS and HTTP ports, for use during initial certificate issuance.
echo "Starting burp (DNS-only mode)..." && \
docker run -d --restart=always --name burp --hostname burp \
    -p 53:8053 -p 53:8053/udp -p 80:8080 -p 9090:9090 \
    -v $PWD/burp/keys:/opt/burp/keys:ro \
    -v $PWD/burp/conf:/opt/burp/conf:ro \
    -v $PWD/burp/pkg:/opt/burp/pkg:ro \
    burp && \
echo Done.
