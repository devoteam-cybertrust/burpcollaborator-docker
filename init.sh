#!/bin/bash

set -e

# Check if a file exists
check_file() {
    if [ "$1" == "burp.jar" ]; then
        local file_path="./burp/pkg/$1"
    else
        local file_path="$1"
    fi

    if [ ! -e "$file_path" ]; then
        echo "ERROR: $file_path not found. Make sure it is in the correct location."
        exit 0
    fi
}

# Check if a command exists
check_command() {
    which "$1" > /dev/null 2>&1
    if [ $? -eq 1 ]; then
        echo "ERROR: $1 is missing. Please install first."
        exit 0
    fi
}

handle_docker_permission_error() {
    echo "ERROR: Permission denied while trying to connect to the Docker daemon. Your user likely needs to use 'sudo' with docker, but we can add your user to the docker group and it should fix this."
    read -p "Would you like to add your user to the Docker group to fix this? (y/n): " choice
    if [ "$choice" == "y" ]; then
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

check_file "burp.jar"
check_command "docker"
check_command "bc"
check_command "openssl"

if [ $# -ne 2 ]; then
    echo "Usage: ./init.sh <domain> <ip>"
    exit 0
fi

DOMAIN=$1
IP=$2
METRICS=$(LC_CTYPE=C tr -dc A-Za-z0-9 < /dev/urandom | fold -w 10 | head -1)

echo "Initialization to be done with domain *.$1 and public IP $2"
read -p "Press any key to continue, or CTRL-C to bail out" var_p

{
    # check if docker works
    docker container ls || handle_docker_permission_error

    # build the containers
    docker build -t certbot-burp certbot/certbot-dns-burp
    docker build -t burp burp

    # Get certs for the first time. The certbot container will be removed automatically afterwards.
    ./certbot/new.sh $DOMAIN

    # The symlinks from certbot will be wrong.
    # Copy the actual certificate files from the archive directory to burp/keys
    sudo cp ./certbot/letsencrypt/archive/$DOMAIN/cert1.pem ./burp/keys/cert.pem
    sudo cp ./certbot/letsencrypt/archive/$DOMAIN/chain1.pem ./burp/keys/chain.pem
    sudo cp ./certbot/letsencrypt/archive/$DOMAIN/fullchain1.pem ./burp/keys/fullchain.pem
    sudo cp ./certbot/letsencrypt/archive/$DOMAIN/privkey1.pem ./burp/keys/privkey.pem
    
    # Change ownership of the privkey.pem file to UID 999 and GID 999
    sudo chown 999:999 ./burp/keys/privkey.pem

    # Replace placeholders in burp config
    sudo /bin/sed -i "s/DOMAIN/$DOMAIN/g" ./burp/conf/burp.config
    sudo /bin/sed -i "s/IP/$IP/g" ./burp/conf/burp.config
    sudo /bin/sed -i "s/jnaicmez8/$METRICS/g" ./burp/conf/burp.config
    
    # run the burp container
    ./burp/run.sh
    sudo /bin/mv ./init.sh ./init.sh_has_been_run
    sudo /bin/chmod 000 ./init.sh_has_been_run
    
    # replace placeholders in renewal script
    sudo /bin/sed -i "s/__DOMAIN__/$DOMAIN/g" ./certbot/certificaterenewal.sh
    sudo /bin/sed -i "s#__BASEDIR__#$PWD#g" ./certbot/certificaterenewal.sh
} || {
    echo "An error occurred during the execution of the script. Please check the output for details."
    exit 1
}

echo
echo "SUCCESS! Burp is now running with the letsencrypt certificate for domain *.$DOMAIN"
echo
echo "Your metrics path was set to $METRICS. Change addressWhitelist to access it remotely."
echo "Initialization script has completed."
