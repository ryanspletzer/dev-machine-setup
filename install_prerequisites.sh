#!/bin/sh
# install_prerequisites.sh
# Installs Homebrew and Ansible on a fresh macOS system

# Exit on error
set -e

# Install Homebrew if not already installed
if ! command -v brew >/dev/null 2>&1; then
  echo "Installing Homebrew..."
  /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
else
  echo "Homebrew already installed."
fi

echo "Installing Ansible via Homebrew..."
brew install ansible
echo "Prerequisites installation complete."
