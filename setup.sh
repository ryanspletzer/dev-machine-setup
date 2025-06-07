#!/bin/sh
# setup.sh
# Installs prerequisites and runs the Ansible playbook

# Exit on error
set -e

# Check for optional YAML file argument
PLAYBOOK_FILE=${1:-setup.yaml}

# Install Homebrew if not already installed
if [ -x "/opt/homebrew/bin/brew" ]; then
  echo "Homebrew already installed."
else
  echo "Installing Homebrew..."
  /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
  (echo; echo 'eval "$(/opt/homebrew/bin/brew shellenv)"') >> ~/.zprofile
  (echo; echo 'eval "$(/opt/homebrew/bin/brew shellenv)"') >> ~/.bash_profile
  eval "$(/opt/homebrew/bin/brew shellenv)"
fi

# Install Ansible using Homebrew
echo "Installing Ansible via Homebrew..."
brew install ansible

echo "Running Ansible playbook: $PLAYBOOK_FILE"
echo "You will be prompted for your sudo password to perform privileged operations"
ansible-playbook "$PLAYBOOK_FILE" -K

echo "Setup complete."
