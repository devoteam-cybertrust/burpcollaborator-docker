#!/bin/sh

if [ -e ./init.sh_has_been_run ]; then
echo Script has already been run. Bailing out.
exit 0
fi

if [ ! -e ./burp/pkg/burp.jar ]; then
echo ERROR: no burp.jar found. Make sure it is in ./burp/pkg/burp.jar
exit 0
fi

which docker > /dev/null 2>&1

if [ $? -eq 1 ]; then
echo ERROR: docker is missing. Please install first
exit 0
fi

which bc > /dev/null 2>&1

if [ $? -eq 1 ]; then
echo ERROR: bc is missing. Please install first
exit 0
fi

which openssl > /dev/null 2>&1
if [ $? -eq 1 ]; then
echo ERROR: openssl is missing. Please install first
exit 0
fi
exit

if [ $# -ne 2 ]; then
echo usage: ./init.sh \<domain\> \<ip\>
exit 0
fi

DOMAIN=$1
IP=$2

echo Initialization to be done with domain *.$1 and public ip $2 && \
read -p "Press any key to continue, or CTRL-C to bail out" var_p  && \

docker build  -t certbot certbot && \
docker build  -t dnsmasq dnsmasq && \
docker build  -t burp burp && \
./certbot/new.sh $DOMAIN && \
docker stop dnsmasq && \
/bin/cp -f ./certbot/letsencrypt/live/$DOMAIN/*.pem ./burp/keys && \
/bin/sed -i "s/DOMAIN/$DOMAIN/g" ./burp/conf/burp.config && \
/bin/sed -i "s/IP/$IP/g" ./burp/conf/burp.config && \
./burp/run.sh && \
/bin/mv ./init.sh ./init.sh_has_been_run && \
/bin/chmod 000 ./init.sh_has_been_run && \

echo Burp is now running with the letsencrypt certificate for domain *.$DOMAIN

