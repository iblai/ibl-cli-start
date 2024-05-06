# IBL CLI Start Script

This script automates the process of setting up an IBL server. It checks the system requirements, installs necessary dependencies, configures AWS and IBL services, and launches the IBL services.

## Requirements

- Ubuntu 20.04 or later
- At least 20G of memory
- At least 30G of storage

## Dependencies

- Docker
- Docker Compose
- AWS CLI
- Pyenv
- Python 3.8.3
- Cargo
- Pip
- Unzip

## Usage

1. Clone the script on your server `git clone https://github.com/iblai/ibl-cli-start.git`
2. Enter `ibl-cli-start` dir.
3. Make the script executable:

```bash
chmod +x ibl-cli-start.sh
```

Run the script:
```bash
./ibl-cli-start.sh
```

During the execution of the script, you will be prompted to enter your `AWS Access Key ID`,` AWS Secret Access Key`, and `Git Access Token`. These are necessary for the configuration of AWS and the installation of the IBL CLI.

*NOTE: These are prompts to avoid leaving secrets and keys in the bash history and also store them in the script.*

## Overriding Default Variables
The script uses default values for some variables like the AWS region, output format, and the repository branch. You can override these defaults by setting the following environment variables before running the script:

- AWS_DEFAULT_REGION: The default AWS region to use. Default is "us-east-1".
- AWS_DEFAULT_OUTPUT_FORMAT: The default AWS output format to use. Default is "json".
- BRANCH: The branch of the repository to use. Default is "develop".

For example, to use the "us-west-2" region, "text" output format, and "main" branch, you can run:

```
export AWS_DEFAULT_REGION="us-west-2"
export AWS_DEFAULT_OUTPUT_FORMAT="text"
export BRANCH="main"

./ibl-cli-start.sh
```
