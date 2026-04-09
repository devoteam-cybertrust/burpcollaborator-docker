FROM certbot/certbot

USER root
RUN apk add --no-cache jq docker-cli bind-tools

COPY hooks/ /opt/hooks/
RUN chmod +x /opt/hooks/*.sh
