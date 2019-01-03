#!/bin/sh

# Renew certificates every X days
#
# requires openssl and bc
#

RENEWDAYS=30

BASEDIR=/collab


if [ $# -ne 1 ]; then
echo usage: ./$0 \<domain\>
exit 0
fi

DOMAIN=$1

CURRENT=`/bin/date +%s`
CERTIFICATE=`/usr/bin/openssl x509 -noout -dates -in $BASEDIR/certbot/letsencrypt/live/$DOMAIN/cert.pem  | /bin/grep notAfter | /usr/bin/cut -d "=" -f 2`
CERTDATE=`/bin/date -d "$CERTIFICATE" +%s`

DAYS=`/bin/echo \($CERTDATE - $CURRENT\)/60/60/24 | /usr/bin/bc`

if [ $DAYS -lt $RENEWDAYS  ]; then

echo Renewing certificate...
# this may fail, we don't care
docker stop burp
docker rm burp
cd $BASEDIR && \
./certbot/renew.sh $DOMAIN  && \
/bin/cp -f $BASEDIR/certbot/letsencrypt/live/$DOMAIN/*.pem $BASEDIR/burp/keys && \
./burp/run.sh && \
echo Certificate renewed

else

echo Still $DAYS days to expire. Not renewing

fi
