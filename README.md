# Burp Collaborator Server in Docker

Run a private Burp Collaborator Server in Docker with a Let's Encrypt certificate or cert of your choice. One command performs first-time setup and starts the server; one command shuts it down.

## Table of contents

- [What you need](#what-you-need)
- [1. Delegate a domain](#1-delegate-a-domain)
- [2. Start Collaborator](#2-start-collaborator)
  - [Use CLI flags](#use-cli-flags)
  - [Or use a config file](#or-use-a-config-file)
- [Burp JAR downloads](#burp-jar-downloads)
- [Use a certificate from DigiCert or another CA](#use-a-certificate-from-digicert-or-another-ca)
- [Command cheatsheet](#command-cheatsheet)
- [Certificate renewal](#certificate-renewal)
- [Ports](#ports)
- [Configure Burp Suite](#configure-burp-suite)
- [Update Burp Suite](#update-burp-suite)
- [Start over completely](#start-over-completely)
- [Troubleshooting](#troubleshooting)
  - [Docker is unavailable](#docker-is-unavailable)
  - [Port 53 is already in use](#port-53-is-already-in-use)
  - [Certificate issuance fails](#certificate-issuance-fails)
- [Return static web content](#return-static-web-content)
- [Credits](#credits)

## What you need

- A Linux server with a public IPv4 address
- Bash and a working Docker installation
- A domain or subdomain delegated to the server
- Permission to download Burp Suite under PortSwigger's terms, or a local Burp Suite JAR
- Internet access to ports used by Collaborator

## 1. Delegate a domain

Choose a dedicated domain or subdomain.
If you're using a top level domain like `collab.com`, set the NS server (glue) records for it.
If you're using a subdomain instead, you can set the NS records for it by setting A records for ns1 and ns2.

Confirm the NS records have IPs:
```bash
dig ns1.collab.com

# Should look something like
ns1.collab.com.     A      1.2.3.4
```

Confirm the NS delegation:
```bash
dig NS collab.com

# Should look something like
collab.com.      NS  ns1.collab.com.
collab.com.      NS  ns2.collab.com.
```

For Let's Encrypt:
TCP & UDP port 53 must be reachable on your server. Not only for Burp to work but also to do your Let's Encrypt certs.
See [PortSwigger's DNS configuration documentation](https://portswigger.net/burp/documentation/collaborator/deploying#dns-configuration) for additional background.

## 2. Start Collaborator

Clone the repository, enter it, and run the wizard:

```bash
git clone https://github.com/intrudir/burpcollaborator-docker.git
cd burpcollaborator-docker
./collaborator up
```

On first use, the wizard asks for:

- The delegated domain, such as `collab.com`
- The server's public IPv4 address
- Whether to use Let's Encrypt or certificate files from another CA

If no managed Burp Suite JAR exists, the command downloads the latest stable release from PortSwigger and verifies its checksum. It then builds the Docker images, prepares the certificates, and starts Collaborator.

After setup succeeds, the wizard writes a complete `collaborator.conf` containing the domain, public IP, managed JAR location, certificate mode, and managed certificate paths. Later invocations load that file and start the existing installation:

```bash
./collaborator up
```

### Use CLI flags

For unattended setup, provide named flags:

```bash
./collaborator up \
  --domain collab.example.com \
  --ip 1.2.3.4
```

The missing JAR is downloaded automatically. Use `--jar FILE` to bootstrap from a local JAR instead.

### Or use a config file

The wizard creates `collaborator.conf` automatically. To prepare one before the first run, copy the example and edit it:

```bash
cp collaborator.conf.example collaborator.conf
```

```ini
domain=collab.com
public_ip=1.2.3.4
burp_jar_source=download
certificate_source=letsencrypt
```

To use a local JAR instead:

```ini
burp_jar_source=file
burp_jar=/path/to/burpsuite.jar
```

The default file is loaded automatically:

```bash
./collaborator up
```

Use `--config FILE` only when loading a different config path:

```bash
./collaborator up --config /path/to/another.conf
```

CLI flags override config values, and `collaborator.conf` is ignored by Git. After a successful first-time setup, the generated file uses managed values like these:

```ini
domain=collab.com
public_ip=1.2.3.4

burp_jar_source=existing
burp_jar=burp/pkg/burp.jar

certificate_source=managed-letsencrypt
certificate_file=burp/keys/cert.pem
private_key_file=burp/keys/privkey.pem
chain_file=burp/keys/chain.pem
fullchain_file=burp/keys/fullchain.pem
```

For a certificate supplied by DigiCert or another CA, the generated source is `managed-files` instead. These managed settings make future `./collaborator up` calls reuse the installed artifacts; they are not replacement or update requests.

## Burp JAR downloads

During first-time setup, the latest stable JAR is downloaded automatically only when `burp/pkg/burp.jar` is missing and no local JAR was specified. If the managed JAR already exists, ordinary `./collaborator up` commands reuse it without checking for or downloading updates.

To explicitly download the latest stable JAR directly from PortSwigger:

```bash
./collaborator up --download-jar
```

The command displays the [PortSwigger license agreement](https://portswigger.net/burp/eula), obtains the version and SHA-256 checksum from the official [Burp download page](https://portswigger.net/burp/downloads), and verifies the JAR before installing it. A failed download or checksum mismatch leaves the existing JAR untouched.

Use `--jar FILE` to explicitly install a local JAR. `--jar` and `--download-jar` cannot be combined. When an explicitly installed JAR changes, a running Collaborator container is restarted; when the JAR is already identical, it is left running.

## Use a certificate from DigiCert or another CA

Let's Encrypt is the default, but it is not required. Supply a PEM-encoded leaf certificate, its private key, and either the CA chain or a complete full-chain file.

With CLI flags and a CA chain:
- If the CA provides a ready-made file containing the leaf certificate and intermediates, use `--fullchain` instead of `--chain`:
```bash
./collaborator up \
  --domain collab.example.com \
  --ip 1.2.3.4 \
  --jar /path/to/burpsuite.jar \
  --certificate-source files \
  --cert /path/to/certificate.pem \
  --key /path/to/private-key.pem \
  --chain /path/to/ca-chain.pem
```

The equivalent config file entries are:

```ini
certificate_source=files
certificate_file=/path/to/certificate.pem
private_key_file=/path/to/private-key.pem
chain_file=/path/to/ca-chain.pem
# Use fullchain_file instead of chain_file when appropriate.
```

The files are copied into `burp/keys`; the container does not depend on the original paths after setup. Certificate files must be PEM encoded and the certificate must be a wildcard cert.

## Command cheatsheet

Start or create the deployment:

```bash
./collaborator up
```

Stop it while preserving the JAR, configuration, and certificates:

```bash
./collaborator down
```

Check its state:

```bash
./collaborator status
```

Follow the Burp container logs:

```bash
./collaborator logs
```

Check for certificate renewal:

```bash
./collaborator renew
```

Display command help:

```bash
./collaborator --help
```

## Certificate renewal

For Let's Encrypt deployments, `./collaborator renew` asks Certbot to renew certificates that are close to expiry. When renewal occurs, the new files are installed and Burp is restarted automatically. If nothing is due, Burp is left untouched.

For supplied certificates, renewal remains the responsibility of the CA or administrator.

For unattended renewal, run the command daily from cron:

```cron
17 3 * * * cd /absolute/path/to/burpcollaborator-docker && ./collaborator renew >> certbot/logs/cron.log 2>&1
```

## Ports

The container publishes these host ports:

| Host port | Protocol | Purpose |
| --- | --- | --- |
| 53 | TCP/UDP | Authoritative DNS and interaction capture |
| 80 | TCP | HTTP interaction capture |
| 443 | TCP | HTTPS interaction capture |
| 25 | TCP | SMTP interaction capture |
| 465 | TCP | SMTPS interaction capture |
| 587 | TCP | SMTP submission interaction capture |
| 9090 | TCP | HTTP polling and metrics path |
| 9443 | TCP | HTTPS polling |

Docker-published ports can bypass ordinary UFW expectations. Review the host's Docker/UFW forwarding policy and expose only what you need. In particular, restrict polling ports to the IP addresses that should be allowed to use your private Collaborator instance.

## Configure Burp Suite

In Burp Suite, open the Collaborator server settings and use your delegated domain. This project exposes secure polling on port `9443`.

The generated server configuration is stored at `burp/conf/burp.config`. The randomly generated metrics path is printed after first-time setup.

## Update Burp Suite

Explicitly download the latest stable JAR:

```bash
./collaborator up --download-jar
```

Or install a local JAR:

```bash
./collaborator up --jar /path/to/new/burpsuite.jar
```

Collaborator never updates an existing JAR automatically. Automatic downloading is limited to bootstrapping a deployment that has no JAR.

## Start over completely

`./collaborator down` preserves deployment data. To repeat first-time setup, stop the containers and remove the generated state:

```bash
./collaborator down
rm -f burp/conf/burp.config burp/keys/*.pem burp/pkg/burp.jar
rm -rf certbot/letsencrypt/* certbot/logs/*
./collaborator up
```

This permanently removes the current private key, certificates, Certbot account data, logs, and copied Burp JAR. Keep backups if any of them are needed.

## Troubleshooting

### Docker is unavailable

If the command reports that it cannot access Docker, verify that the daemon is running and that the current user can run `docker info` without `sudo`.

### Port 53 is already in use

Local resolvers such as `systemd-resolved` commonly bind port 53. Identify the process before changing the host:

```bash
sudo ss -lntup '( sport = :53 )'
```

The Collaborator container cannot start until both TCP and UDP port 53 are available.

### Certificate issuance fails

Verify all of the following:

- The domain's NS record is visible from a public resolver.
- The nameserver address resolves to this server's public IP.
- Inbound TCP and UDP port 53 are permitted by the cloud firewall and host firewall.
- No other process or container is using port 53.
- The domain and public IP passed to the setup command are correct.

After correcting the problem, run `./collaborator up` again. Failed first-time setup removes its temporary container and can be retried.

## Return static web content

Burp can return custom HTML when someone visits the instance. Add a `customHttpContent` section to `burp/conf/burp.config`:

```json
{
  "customHttpContent": [
    {
      "path": "/",
      "contentType": "text/html",
      "base64Content": "<base64-encoded HTML>"
    }
  ]
}
```

Restart the deployment after editing the configuration:

```bash
./collaborator down
./collaborator up
```

## Credits

Created by [Bruno Morisson](https://twitter.com/morisson), with thanks to [Fábio Pires](https://twitter.com/fabiopirespt) and [Herman Duarte](https://twitter.com/hdontwit).
