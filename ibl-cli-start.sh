#!/bin/bash

SCRIPT_VERSION='version 0.7'

# Term Color vars
red='\033[0;31m'
green='\033[0;32m'
blue='\033[0;34m'
yellow='\033[0;33m'
cyan='\033[0;36m'
purple='\033[0;35m'
clear='\033[0m'
lyellow='\033[2;33m'


function ibl_describeme () {

        echo -e "${green}"

        echo -e " ___ ____  _        ____ _     ___   ____ _____  _    ____ _____ "
        echo -e "|_ _| __ )| |      / ___| |   |_ _| / ___|_   _|/ \  |  _ \_   _|"
        echo -e " | ||  _ \| |     | |   | |    | |  \___ \ | | / _ \ | |_) || |  "
        echo -e " | || |_) | |___  | |___| |___ | |   ___) || |/ ___ \|  _ < | |  "
        echo -e "|___|____/|_____|  \____|_____|___| |____/ |_/_/   \_\_| \_\|_|  "

        echo " "
        echo -e "${purple}                                                    ${SCRIPT_VERSION}"
        echo -e "${clear}"
        echo " ---------------------------------------------------------------"
        echo ""
}

ibl_describeme



# Check Ubuntu version
echo -e "[${yellow}0${clear}/18] Checking Ubuntu version..."
UBUNTU_VERSION=$(lsb_release -rs)
REQUIRED_VERSION="22.04"
if [[ $UBUNTU_VERSION != $REQUIRED_VERSION* ]]; then
    echo -e "${red}Error: This script requires Ubuntu $REQUIRED_VERSION or later. Exiting...${clear}"
    exit 1
fi


# Check system memory
# Check system memory
echo -e "[${yellow}0${clear}/18] Checking system memory..."
TOTAL_MEMORY=$(free | awk '/^Mem:/ {print $2}')
REQUIRED_MEMORY="20000000"

if [[ $TOTAL_MEMORY -lt $REQUIRED_MEMORY ]]; then
    REQUIRED_MEMORY=$(expr $REQUIRED_MEMORY / 1000000)
    echo -e "${red}Error: Insufficient memory. This script requires at least ${REQUIRED_MEMORY}GB of memory. Exiting...${clear}"
    exit 1
fi

# Check system storage
echo -e "[${yellow}0${clear}/18] Checking system storage..."
TOTAL_STORAGE=$(df / | awk '/^\/dev\// {print $4}')
REQUIRED_STORAGE="30000000"
if [[ $TOTAL_STORAGE -lt $REQUIRED_STORAGE ]]; then
    REQUIRED_STORAGE=$(expr $REQUIRED_STORAGE / 1000000)
    echo -e "${red}Error: Insufficient storage. This script requires at least ${REQUIRED_STORAGE}GB of storage. Exiting...${clear}"
    exit 1
fi

# Update and install dependencies
echo -e "[${yellow}1${clear}/19] Updating and installing dependencies..."
sudo apt-get update

if ! command -v docker &> /dev/null; then
    echo -e "${red}Error: Docker is not installed. Installing Docker...${clear}"
    # Update existing list of packages
    sudo apt update

    # Install a few prerequisite packages which let apt use packages over HTTPS
    sudo apt install apt-transport-https ca-certificates curl software-properties-common

    # Add the GPG key for the official Docker repository to your system
    curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo apt-key add -

    # Add the Docker repository to APT sources
    sudo add-apt-repository "deb [arch=amd64] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable"

    # Update the package database with the Docker packages from the newly added repo
    sudo apt update

    # Make sure you are about to install from the Docker repo instead of the default Ubuntu repo
    apt-cache policy docker-ce

    # Install Docker
    sudo apt install docker-ce

    # Check Docker status
    sudo systemctl status docker
fi

if ! command -v docker-compose &> /dev/null; then
    echo -e "${red}Error: Docker Compose is not installed. Installing Docker Compose...${clear}"
    sudo apt-get install -y docker-compose
fi


if ! getent group docker | grep -qw "$USER"; then
    sudo adduser $USER docker
    echo "Please end the SSH session and start a new one to be able to use Docker commands."
    echo "You can end the session by typing 'exit' and then reconnect."
    exit
fi

sudo apt-get install -y unzip awscli \
build-essential libssl-dev zlib1g-dev libbz2-dev libreadline-dev libsqlite3-dev \
wget curl llvm libncurses5-dev libncursesw5-dev xz-utils tk-dev libffi-dev \
liblzma-dev python3-openssl git

# Setup default directories
echo -e "[${yellow}2${clear}/19] Setting up default directories..."
if [ ! -d "/ibl/" ]; then
    sudo mkdir /ibl/
    sudo chown -R $USER:$USER /ibl/
fi


# Update ~/.bashrc with export IBL_ROOT=/ibl/
BASH_DONE=$(cat ~/.bashrc | grep -i -c "IBL_ROOT")
 if [[ $BASH_DONE -eq 0 ]]; then
echo -e 'export IBL_ROOT=/ibl/\nexport PATH="~/.pyenv/bin:$PATH"\neval "$(pyenv init -)"\neval "$(pyenv virtualenv-init -)"\npyenv activate ibl-cli-ops' >> ~/.bashrc

# Apply changes before penv install
 export IBL_ROOT=/ibl/
 . "$HOME/.cargo/env"

fi

# Setup pyenv
# Check if pyenv is already installed
if ! command -v pyenv &> /dev/null; then
    echo -e "[${yellow}3${clear}/19] Setting up pyenv..."
    curl https://pyenv.run | bash
fi

# load pyenv bash without reload
 export PATH="~/.pyenv/bin:$PATH"
 eval "$(pyenv init -)"
 eval "$(pyenv virtualenv-init -)"
 pyenv activate ibl-cli-ops\n

# Python installation
echo -e "[${yellow}4${clear}/19] Installing Python..."
pyenv install 3.8.3
pyenv global 3.8.3
pyenv virtualenv 3.8.3 ibl-cli-ops
pyenv activate ibl-cli-ops

# Install cargo
echo -e "[${yellow}5${clear}/19] Installing cargo..."
curl https://sh.rustup.rs -sSf | sh

# Apply changes to the current session
echo -e '\n. "$HOME/.cargo/env"' >> ~/.bashrc
source ~/.bashrc

# Install AWS CLI
echo -e "[${yellow}6${clear}/19] Installing AWS CLI..."
curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
unzip awscliv2.zip
sudo ./aws/install

# AWS Configuration
echo -e "[${yellow}7${clear}/19] Configuring AWS..."
read -p 'AWS Access Key ID: ' AWS_ACCESS_KEY_ID
read -p 'AWS Secret Access Key: ' AWS_SECRET_ACCESS_KEY
AWS_DEFAULT_REGION=${AWS_DEFAULT_REGION:-"us-east-1"}
AWS_DEFAULT_OUTPUT_FORMAT=${AWS_DEFAULT_OUTPUT_FORMAT:-"json"}
aws configure set aws_access_key_id $AWS_ACCESS_KEY_ID
aws configure set aws_secret_access_key $AWS_SECRET_ACCESS_KEY
aws configure set default.region $AWS_DEFAULT_REGION
aws configure set default.output $AWS_DEFAULT_OUTPUT_FORMAT

# AWS ECR Docker Login
echo -e "[${yellow}8${clear}/19] Logging in to AWS ECR..."
aws ecr get-login-password --region us-east-1 | docker login --username AWS --password-stdin 765174860755.dkr.ecr.us-east-1.amazonaws.com

# Check if GIT_ACCESS_TOKEN was provided as an argument
read -sp 'GIT Access Token: ' GIT_ACCESS_TOKEN

if [ -z "$GIT_ACCESS_TOKEN" ]
then
    echo -e "${red}Error: No GIT_ACCESS_TOKEN provided. Exiting...${clear}"
    exit 1
fi

echo -e "[${yellow}9${clear}/19] Install urllib3==1.26.15 and CLI..."
pip install urllib3==1.26.15

BRANCH=${BRANCH:-"develop"}

# Then use $BRANCH in your script where you need to specify the branch
# Install IBL CLI
pip install -e git+https://$GIT_ACCESS_TOKEN@github.com/ibleducation/ibl-cli-ops.git@$BRANCH#egg=ibl-cli



echo -e "[${yellow}10${clear}/19] Setup Base Domain..."
# Ask the user for the base domain
echo "Please enter the base domain:"
read BASE_DOMAIN

# Save the base domain in the ibl config
ibl config save --set BASE_DOMAIN=$BASE_DOMAIN

# Configure IBL replicator
echo -e "[${yellow}11${clear}/19] Configuring IBL replicator..."
echo "n" | ibl replicator configure

# Launch IBL replicator
echo -e "[${yellow}12${clear}/19] Launching IBL services..."

echo -e "\n[${yellow}13${clear}/19] Launching IBL Replicator..."
echo "n" | ibl launch --ibl-replicator
ibl replicator up -d

echo -e "[${yellow}14${clear}/19] Launching IBL Data Manager..."
ibl launch --ibl-dm

echo -e "[${yellow}15${clear}/19] Launching IBL edX..."
ibl launch --ibl-edx
ibl launch --ibl-oauth
ibl launch --ibl-oidc
ibl launch --ibl-edx-manager

echo -e "[${yellow}16${clear}/19] Launching IBL AXD Reporter..."
ibl launch --ibl-axd-reporter

echo -e "[${yellow}17${clear}/19] Launching IBL AXD Web Analytics..."
ibl launch --ibl-axd-web-analytics

echo -e "[${yellow}18${clear}/19] Launching IBL Search..."
ibl launch --ibl-search

echo -e "[${yellow}19${clear}/19] Launching IBL Search..."
ibl global-proxy launch