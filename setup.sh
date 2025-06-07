#!/bin/sh
# setup.sh
# Installs prerequisites and runs the Ansible playbook

# Exit on error
set -e

# Check for optional YAML file argument
PLAYBOOK_FILE=${1:-setup.yaml}

# Install Homebrew if not already installed
if ! command -v brew >/dev/null 2>&1; then
  echo "Installing Homebrew..."
  /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
else
  echo "Homebrew already installed."
fi

# Install Ansible using Homebrew
echo "Installing Ansible via Homebrew..."
brew install ansible

echo "Running Ansible playbook: $PLAYBOOK_FILE"
ansible-playbook "$PLAYBOOK_FILE"

echo "Setup complete."
