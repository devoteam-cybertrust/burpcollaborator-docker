FROM debian

RUN apt-get update && \
    apt-get -yqq dist-upgrade
RUN apt-get autoremove -yqq && \
    apt-get clean && \
    /bin/rm -rf /var/lib/apt/lists/*

RUN mkdir /opt/certbot
WORKDIR /opt/certbot

ADD https://raw.githubusercontent.com/certbot/certbot/master/certbot-auto /opt/certbot/certbot-auto
RUN chmod a+x /opt/certbot/certbot-auto && \
    cd /opt/certbot
RUN /opt/certbot/certbot-auto --noninteractive --install-only

ADD ./docker/docker-entrypoint.sh /docker-entrypoint.sh

ENTRYPOINT ["/docker-entrypoint.sh"]

