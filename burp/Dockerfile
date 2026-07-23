FROM debian:bullseye-slim@sha256:cba95a21c96c1f5fc2470081829363eed57706634f7dc26e8c6712934303d57a

ARG JDK_VERSION=21.0.11
ARG JDK_SHA256=41f1355f8d4c995f73e292f25f7f3e3074195c13ee3253c22fdd4a4340499039

RUN apt-get update && \
    apt-get -yqq dist-upgrade

# Install wget to download JDK
RUN apt-get -yqq install wget && \
    apt-get autoremove -yqq && \
    apt-get clean && \
    /bin/rm -rf /var/lib/apt/lists/*

# Download and install a verified Oracle JDK 21 build.
RUN wget -q "https://download.oracle.com/java/21/archive/jdk-${JDK_VERSION}_linux-x64_bin.deb" -O jdk-21_linux-x64_bin.deb && \
    echo "${JDK_SHA256}  jdk-21_linux-x64_bin.deb" | sha256sum -c - && \
    dpkg -i jdk-21_linux-x64_bin.deb && \
    rm jdk-21_linux-x64_bin.deb

# Create a user and group for Burp
RUN groupadd -g 999 burp && \
    useradd -r -u 999 -g burp -d /opt/burp burp && \
    install -d -o burp -g burp /opt/burp/.java/.userPrefs

# Switch to the burp user
USER burp

COPY entrypoint.sh /opt/burp/entrypoint.sh
WORKDIR  /opt/burp
ENTRYPOINT ["/opt/burp/entrypoint.sh"]
