#!/bin/bash

set -e

# Cleanup handler for errors
cleanup() {
    echo "An error occurred during the execution of the script. Please check the output for details."
    [ -f ./burp/conf/burp.config.full ] && /bin/mv ./burp/conf/burp.config.full ./burp/conf/burp.config
    [ -f ./burp/conf/burp.config.dnsonly ] && /bin/rm -f ./burp/conf/burp.config.dnsonly
    exit 1
}
trap cleanup ERR

# Check if a file exists
check_file() {
    if [ "$1" = "burp.jar" ]; then
        local file_path="./burp/pkg/$1"
    else
        local file_path="$1"
    fi

    if [ ! -e "$file_path" ]; then
        echo "ERROR: $file_path not found. Make sure it is in the correct location."
        exit 1
    fi
}

# Check if a command exists
check_command() {
    if ! command -v "$1" >/dev/null 2>&1; then
        echo "ERROR: $1 is missing. Please install first."
        exit 1
    fi
}

handle_docker_permission_error() {
    echo "ERROR: Permission denied while trying to connect to the Docker daemon. Your user likely needs to use 'sudo' with docker, but we can add your user to the docker group and it should fix this."
    read -p "Would you like to add your user to the Docker group to fix this? (y/n): " choice
    if [ "$choice" = "y" ]; then
        sudo usermod -aG docker $USER
        echo "User added to the Docker group. Please log out and back in for the changes to take effect, then try the init script again."
    else
        echo "Exiting script. Please fix the Docker permissions manually."
    fi
    exit 1
}

if [ -e ./init.sh_has_been_run ]; then
    echo "Script has already been run. Bailing out."
    exit 0
fi

if [ -e ./.init_has_been_run ]; then
    echo "Script has already been run. Bailing out."
    exit 0
fi

check_file "burp.jar"
check_command "docker"
check_command "bc"
check_command "jq"
check_command "openssl"

if [ $# -ne 2 ]; then
    echo "Usage: ./init.sh <domain> <ip>"
    exit 1
fi

# Check if port 53 is available
if ss -lntu | grep -q ':53 '; then
    echo "ERROR: Port 53 is already in use. This is commonly caused by systemd-resolved."
    echo "To free port 53, you can run:"
    echo "  sudo systemctl stop systemd-resolved"
    echo "  sudo systemctl disable systemd-resolved"
    echo "  echo 'nameserver 8.8.8.8' | sudo tee /etc/resolv.conf"
    exit 1
fi

DOMAIN=$1
IP=$2
METRICS=$(LC_CTYPE=C tr -dc A-Za-z0-9 < /dev/urandom | fold -w 10 | head -1)

echo "Initialization to be done with domain *.$1 and public IP $2"
read -p "Press any key to continue, or CTRL-C to bail out" var_p

# check if docker works
docker container ls || handle_docker_permission_error

# build the containers
docker build -t certbot-burp certbot
docker build -t burp burp

# Create full burp.config from template
/bin/cp ./burp/conf/burp.config.template ./burp/conf/burp.config
/bin/sed -i "s/DOMAIN/$DOMAIN/g" ./burp/conf/burp.config
/bin/sed -i "s/IP/$IP/g" ./burp/conf/burp.config
/bin/sed -i "s/jnaicmez8/$METRICS/g" ./burp/conf/burp.config

# Create a DNS-only config for the initial certificate fetch.
# Burp can't start with certificate paths that don't exist yet,
# so we strip HTTPS/SMTPS and polling sections entirely.
jq 'del(.eventCapture.https, .eventCapture.smtps, .polling)' \
    ./burp/conf/burp.config > ./burp/conf/burp.config.dnsonly
/bin/cp ./burp/conf/burp.config ./burp/conf/burp.config.full
/bin/mv ./burp/conf/burp.config.dnsonly ./burp/conf/burp.config

# Start Burp with DNS-only config and minimal port mappings
./burp/run-dnsonly.sh

# Get certificates. The auth hook will inject TXT records into burp.config
# and restart Burp for each challenge.
./certbot/new.sh "$DOMAIN"

# Restore the full config (with certificate paths)
/bin/mv ./burp/conf/burp.config.full ./burp/conf/burp.config

# Copy certificate files to burp/keys
/bin/cp -L ./certbot/letsencrypt/live/$DOMAIN/cert.pem ./burp/keys/cert.pem
/bin/cp -L ./certbot/letsencrypt/live/$DOMAIN/chain.pem ./burp/keys/chain.pem
/bin/cp -L ./certbot/letsencrypt/live/$DOMAIN/fullchain.pem ./burp/keys/fullchain.pem
/bin/cp -L ./certbot/letsencrypt/live/$DOMAIN/privkey.pem ./burp/keys/privkey.pem

# Change ownership of the privkey.pem file to UID 999 and GID 999
sudo chown 999:999 ./burp/keys/privkey.pem

# Restart Burp with the full config and certificates
docker stop burp && docker rm burp
./burp/run.sh

# Disable init script from running again
sudo /bin/mv ./init.sh ./init.sh_has_been_run
sudo /bin/chmod 000 ./init.sh_has_been_run

echo
echo "SUCCESS! Burp is now running with the letsencrypt certificate for domain *.$DOMAIN"
echo
echo "Your metrics path was set to $METRICS. Change addressWhitelist to access it remotely."
echo "Initialization script has completed."
