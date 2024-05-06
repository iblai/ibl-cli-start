#!/bin/bash
# Check Ubuntu version
echo "[0/10] Checking Ubuntu version..."
UBUNTU_VERSION=$(lsb_release -rs)
REQUIRED_VERSION="20.04"
if [[ $UBUNTU_VERSION != $REQUIRED_VERSION* ]]; then
    echo "Error: This script requires Ubuntu $REQUIRED_VERSION or later. Exiting..."
    exit 1
fi

# Check system memory
echo "[0/10] Checking system memory..."
TOTAL_MEMORY=$(free -h | awk '/^Mem:/ {print $2}')
REQUIRED_MEMORY="20G"
if [[ $TOTAL_MEMORY < $REQUIRED_MEMORY ]]; then
    echo "Error: Insufficient memory. This script requires at least $REQUIRED_MEMORY of memory. Exiting..."
    exit 1
fi

# Check system storage
echo "[0/10] Checking system storage..."
TOTAL_STORAGE=$(df -h / | awk '/^\/dev\// {print $2}')
REQUIRED_STORAGE="30G"
if [[ $TOTAL_STORAGE < $REQUIRED_STORAGE ]]; then
    echo "Error: Insufficient storage. This script requires at least $REQUIRED_STORAGE of storage. Exiting..."
    exit 1
fi

# Update and install dependencies
echo "[1/10] Updating and installing dependencies..."
sudo apt-get update

if ! command -v docker &> /dev/null; then
    echo "Error: Docker is not installed. Installing Docker..."
    sudo apt-get install -y docker
fi

if ! command -v docker-compose &> /dev/null; then
    echo "Error: Docker Compose is not installed. Installing Docker Compose..."
    sudo apt-get install -y docker-compose
fi

sudo apt-get install -y unzip awscli \
build-essential libssl-dev zlib1g-dev libbz2-dev libreadline-dev libsqlite3-dev \
wget curl llvm libncurses5-dev libncursesw5-dev xz-utils tk-dev libffi-dev \
liblzma-dev python3-openssl git

# Setup default directories
# Setup default directories
echo "[2/10] Setting up default directories..."
if [ ! -d "/ibl/" ]; then
    sudo mkdir /ibl/
fi
export IBL_ROOT=/ibl/
sudo chown -R $USER:$USER /ibl/

# Update ~/.bashrc with export IBL_ROOT=/ibl/
echo -e 'export IBL_ROOT=/ibl/\nexport PATH="~/.pyenv/bin:$PATH"\neval "$(pyenv init -)"\neval "$(pyenv virtualenv-init -)"\npyenv activate ibl-cli-ops\n. "$HOME/.cargo/env"' >> ~/.bashrc

# Setup pyenv
# Check if pyenv is already installed
if ! command -v pyenv &> /dev/null; then
    echo "[3/10] Setting up pyenv..."
    curl https://pyenv.run | bash
fi

# Python installation
echo "[4/10] Installing Python..."
pyenv install 3.8.3
pyenv global 3.8.3
pyenv virtualenv 3.8.3 ibl-cli-ops
pyenv activate ibl-cli-ops

# Install cargo
echo "[5/10] Installing cargo..."
curl https://sh.rustup.rs -sSf | sh

# Apply changes to the current session
source ~/.bashrc

# Install AWS CLI
echo "[6/10] Installing AWS CLI..."
curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
unzip awscliv2.zip
sudo ./aws/install

# AWS Configuration
echo "[7/10] Configuring AWS..."
read -sp 'AWS Access Key ID: ' AWS_ACCESS_KEY_ID
read -sp 'AWS Secret Access Key: ' AWS_SECRET_ACCESS_KEY
AWS_DEFAULT_REGION=${AWS_DEFAULT_REGION:-"us-east-1"}
AWS_DEFAULT_OUTPUT_FORMAT=${AWS_DEFAULT_OUTPUT_FORMAT:-"json"}
aws configure set aws_access_key_id $AWS_ACCESS_KEY_ID
aws configure set aws_secret_access_key $AWS_SECRET_ACCESS_KEY
aws configure set default.region $AWS_DEFAULT_REGION
aws configure set default.output $AWS_DEFAULT_OUTPUT_FORMAT

# AWS ECR Docker Login
echo "[8/10] Logging in to AWS ECR..."
aws ecr get-login-password --region us-east-1 | docker login --username AWS --password-stdin 765174860755.dkr.ecr.us-east-1.amazonaws.com

# Check if GIT_ACCESS_TOKEN was provided as an argument
read -sp 'GIT Access Token: ' GIT_ACCESS_TOKEN

if [ -z "$GIT_ACCESS_TOKEN" ]
then
    echo "Error: No GIT_ACCESS_TOKEN provided. Exiting..."
    exit 1
fi

BRANCH=${BRANCH:-"develop"}

# Then use $BRANCH in your script where you need to specify the branch
# Install IBL CLI
pip install -e git+https://$GIT_ACCESS_TOKEN@github.com/ibleducation/ibl-cli-ops.git@$BRANCH#egg=ibl-cli

# Configure IBL replicator
echo "[9/10] Configuring IBL replicator..."
echo "n" | ibl replicator configure

# Launch IBL replicator
echo "[10/10] Launching IBL services..."
echo "n" | ibl launch --ibl-replicator
ibl replicator up -d
ibl launch --ibl-dm --ibl-edx --ibl-oauth --ibl-oidc --ibl-edx-manager --ibl-axd-reporter --ibl-axd-web-analytics --ibl-search
