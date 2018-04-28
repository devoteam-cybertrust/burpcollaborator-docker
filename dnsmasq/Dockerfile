FROM debian

RUN apt-get update && \
    apt-get -yqq dist-upgrade
RUN apt-get -yq install dnsmasq
RUN apt-get autoremove -yqq && \
    apt-get clean && \
    /bin/rm -rf /var/lib/apt/lists/*


EXPOSE 5353/tcp 5353/udp

USER dnsmasq
ENTRYPOINT ["dnsmasq"]
