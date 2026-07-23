FROM certbot/certbot:latest@sha256:34ee91d2f43008eb78a007d22f23ed4b2eaa9a454cb27ca2c042b49527a695b4

USER root
RUN apk add --no-cache jq docker-cli bind-tools

COPY hooks/ /opt/hooks/
COPY download_burp_jar.py /opt/download_burp_jar.py
RUN chmod +x /opt/hooks/*.sh
