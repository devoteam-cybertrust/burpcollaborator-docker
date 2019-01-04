#!/bin/sh
cd /opt/burp
exec java -jar /opt/burp/pkg/burp.jar --collaborator-server --collaborator-config=/opt/burp/conf/burp.config
