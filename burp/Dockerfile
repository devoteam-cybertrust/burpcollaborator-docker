FROM debian:bullseye-slim

RUN apt-get update && \
    apt-get -yqq dist-upgrade

# Install wget to download JDK
RUN apt-get -yqq install wget && \
    apt-get autoremove -yqq && \
    apt-get clean && \
    /bin/rm -rf /var/lib/apt/lists/*

# Download and install Oracle JDK 21
RUN wget https://download.oracle.com/java/21/latest/jdk-21_linux-x64_bin.deb && \
    dpkg -i jdk-21_linux-x64_bin.deb && \
    rm jdk-21_linux-x64_bin.deb

# Create a user and group for Burp
RUN groupadd -g 999 burp && \
    useradd -r -u 999 -g burp -d /opt/burp burp

# Switch to the burp user
USER burp

ADD entrypoint.sh /opt/burp/entrypoint.sh
WORKDIR  /opt/burp
ENTRYPOINT ["/opt/burp/entrypoint.sh"]
