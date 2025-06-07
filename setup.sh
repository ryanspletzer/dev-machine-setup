#!/bin/sh
# setup.sh
# Installs prerequisites and runs the Ansible playbook

# Exit on error
set -e

# Check for optional YAML file argument
PLAYBOOK_FILE=${1:-setup.yaml}

# Prompt for sudo password once and store it securely
read -s -p "Enter sudo password: " SUDO_PASSWORD
echo

# sudo with password
printf '%s\n' "$SUDO_PASSWORD" | sudo -S -v
( while true; do sudo -n true; sleep 15; done ) 2>/dev/null &

# Install Homebrew if not already installed
if [ -x "/opt/homebrew/bin/brew" ]; then
  echo "Homebrew already installed."
else
  echo "Installing Homebrew..."
  # Use NONINTERACTIVE to avoid prompts during Homebrew installation
  NONINTERACTIVE=1 /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
  (echo; echo 'eval "$(/opt/homebrew/bin/brew shellenv)"') >> ~/.zprofile
  (echo; echo 'eval "$(/opt/homebrew/bin/brew shellenv)"') >> ~/.bash_profile
  eval "$(/opt/homebrew/bin/brew shellenv)"
fi

# Install Ansible using Homebrew
echo "Installing Ansible via Homebrew..."
brew install ansible

echo "Running Ansible playbook: $PLAYBOOK_FILE"
echo "You will be prompted for your sudo password to perform privileged operations"

# Export the sudo password as an environment variable for Ansible
export ANSIBLE_SUDO_PASS="$SUDO_PASSWORD"

# Run the playbook with the sudo password from the environment variable
ansible-playbook "$PLAYBOOK_FILE" -K

# Unset the sudo password variable for security
unset ANSIBLE_SUDO_PASS

echo "Setup complete."
