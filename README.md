# Burp Collaborator Server docker container with LetsEncrypt certificate

This repository includes a set of scripts to install a Burp Collaborator Server in a docker environment, using a LetsEncrypt wildcard certificate.
The objective is to simplify as much as possible the process of setting up and maintaining the server.

## Setup your domain
Delegate a domain or subdomain to your soon-to-be burp collaborator server IP address. At the minimum you'll need an NS record for the domain/subdomain to be used.  

For example, if your collaborator domain is `burpserver.example`, you need to make NS records pointing with an A record to the public IP of the server: `1.2.3.4`

Here as an example `dig` command to confirm:
```bash
dig NS burpserver.example

Output:
; <<>> DiG 9.10.6 <<>> NS burpserver.example
;; global options: +cmd
;; Got answer:
;; ->>HEADER<<- opcode: QUERY, status: NOERROR, id: 49449
;; flags: qr rd ra; QUERY: 1, ANSWER: 2, AUTHORITY: 0, ADDITIONAL: 3

;; OPT PSEUDOSECTION:
; EDNS: version: 0, flags:; udp: 4000
;; QUESTION SECTION:
;burpserver.example.                       IN      NS

;; ANSWER SECTION:
burpserver.example.                308     IN      NS      ns2.burpserver.example.
burpserver.example.                308     IN      NS      ns1.burpserver.example.

;; ADDITIONAL SECTION:
ns2.burpserver.example.            308     IN      A       1.2.3.4
ns1.burpserver.example.            308     IN      A       1.2.3.4

;; Query time: 52 msec
;; SERVER: 8.8.8.8#53(8.8.8.8)
;; WHEN: Fri Jul 12 11:20:29 EDT 2024
;; MSG SIZE  rcvd: 104
```

Check https://portswigger.net/burp/documentation/collaborator/deploying#dns-configuration for further info.

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

* There's a renewal script in ```./certbot/certificaterenewal.sh```. When run, it renews the certificate if it expires in 30 days or less;
* Optionally, edit the RENEWDAYS variable if you wish to. By default it will renew the certificate every 60 days. *If you want to force the renewal to check if everything is working, just set it to 89 days, and run it manually. Remember to set it back to 60 afterwards.*;
* Set your crontab to run this script once a day.

## Updating Burp Suite

* Download it and make sure you put it in ```./burp/pkg/burp.jar```
* Restart the container with ```docker restart burp```  

---
**Author:** [Bruno Morisson](https://twitter.com/morisson)

Thanks to [Fábio Pires](https://twitter.com/fabiopirespt) (check his burp collaborator w/letsencrypt [tutorial](https://blog.fabiopires.pt/running-your-instance-of-burp-collaborator-server/)) and [Herman Duarte](https://twitter.com/hdontwit) (for betatesting and fixes)


