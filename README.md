# Burp Collaborator Server docker container with LetsEncrypt certificate

This repository includes a set of scripts to install a Burp Collaborator Server in a docker environment, using a LetsEncrypt wildcard certificate.
The objective is to simplify as much as possible the process of setting up and maintaining the server.

## Setup your domain

Delegate a subdomain to your soon to be burp collaborator server IP address. At the minimum you'll need a NS record for the subdomain to be used (e.g. burp.example.com) pointing to your new server's A record:

```burp.example.com IN NS burpserver.example.com```

```burpserver.example.com IN A 1.2.3.4```

Check https://portswigger.net/burp/help/collaborator_deploying#dns for further info.

## Requirements

* Internet accessible server 
* bash
* docker
* bc 
* openssl
* Burp Suite Professional

## Setup the environment 

* Clone or download the repository to the server (tested on ubuntu 16.04) to a directory of your choice.
* Put the Burp Suite JAR file in ```./burp/pkg/burp.jar``` (make sure the name is exactly ```burp.jar```, and it is the actual file **not a link**)
* Run init.sh with your subdomain and server public IP address as argument:

```./init.sh burp.example.com 1.2.3.4```

This will start the environment for the subdomain ```burp.example.com```, creating a wildcard certificate as ```*.burp.example.com```.

I'm using an ugly hack on the certbot-dns-cloudflare plugin from certbot, where it just runs a local dnsmasq with the required records, and makes
all of this automagically happen.

If everything is OK, burp will start with the following message:

> Burp is now running with the letsencrypt certificate for domain *.burp.example.com

You can check by running ```docker ps```, and going to burp, and pointing the collaborator configuration to your new server. 
Keep it mind that this configuration configures the *polling server on port 9443*.

The init.sh script will be renamed and disabled, so no accidents may happen.

## Certificate renewal

* Edit the file ```./certbot/certificaterenewal.sh``` and configure the "```BASEDIR```" variable to the correct path of the main directory (where the init.sh script resides).
* Optionally, edit the RENEWDAYS variable if you wish to. By default it will renew the certificate every 60 days. *If you want to force the renewal to check if everything is working, just set it to 89 days, and run it manually. Remember to set it back to 60 afterwards.*
* Set your crontab to run this script once a day, with the domain as an argument.

## Updating Burp Suite

* Download it and make sure you put it in ```./burp/pkg/burp.jar```
* Restart the container with ```docker restart burp```  

---
**Author:** [Bruno Morisson](https://twitter.com/morisson)

Thanks to [Fábio Pires](https://twitter.com/fabiopirespt) (check his burp collaborator w/letsencrypt [tutorial](https://blog.fabiopires.pt/running-your-instance-of-burp-collaborator-server/)) and [Herman Duarte](https://twitter.com/hdontwit) (for betatesting and fixes)


