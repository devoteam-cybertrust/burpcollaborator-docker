FROM debian

RUN apt-get update && \
    apt-get -yqq dist-upgrade
RUN apt-get -yqq install default-jre && \
    apt-get autoremove -yqq && \
    apt-get clean && \
    /bin/rm -rf /var/lib/apt/lists/*

RUN groupadd -g 999 burp && \
    useradd -r -u 999 -g burp -d /opt/burp burp
 
USER burp
ADD entrypoint.sh /opt/burp/entrypoint.sh
WORKDIR  /opt/burp
ENTRYPOINT ["/opt/burp/entrypoint.sh"]
