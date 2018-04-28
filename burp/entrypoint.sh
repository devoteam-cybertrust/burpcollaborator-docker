#!/bin/sh
cd /opt/burp
exec java -Xmx3g -Xms3g -jar /opt/burp/pkg/burp.jar --collaborator-server --collaborator-config=/opt/burp/conf/burp.config
