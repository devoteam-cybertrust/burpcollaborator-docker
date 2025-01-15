#!/bin/sh

# Renew certificates every X days
#
# requires openssl and bc
#

RENEWDAYS=30

BASEDIR=__BASEDIR__


DOMAIN=__DOMAIN__

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
/bin/cp -r -f $BASEDIR/certbot/letsencrypt/live/$DOMAIN/ $BASEDIR/burp/keys && \
chown 999:999 $PWD/burp/keys/$DOMAIN/privkey.pem && \
./burp/run.sh && \
echo Certificate renewed

else

echo Still $DAYS days to expire. Not renewing

fi

echo waiting for 5 seconds just to make sure all is ok!

sleep 5

if [ ! "$(docker ps -q -f name=burp)" ]; then
    if [ "$(docker ps -aq -f status=exited -f name=burp)" ]; then
        # cleanup
        docker rm burp
    fi
    # run your container
    #docker run -d --name <name> my-docker-image
    $BASEDIR/burp/run.sh
    echo burp docker has been restarted
else

echo burp docker is running

fi
