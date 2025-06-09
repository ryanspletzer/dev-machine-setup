#!/bin/sh
# install_prerequisites.sh
# Installs Homebrew and Ansible on a fresh macOS system

# Exit on error
set -e

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

echo "Installing Ansible via Homebrew..."
/opt/homebrew/bin/brew install ansible
echo "Prerequisites installation complete."
