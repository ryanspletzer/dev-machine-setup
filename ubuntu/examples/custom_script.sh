#!/bin/bash

echo "This script is intended to be run on Ubuntu systems to customize settings."
echo "You can add your own custom commands here."

# 1password installation for arm64/aarch64 architecture
arch="$(dpkg --print-architecture 2>/dev/null || uname -m)"
if [[ "$arch" == "arm64" || "$arch" == "aarch64" ]]; then
  tmpdir="$(mktemp -d)"
  trap 'rm -rf "$tmpdir"' EXIT
  cd "$tmpdir"

  # aarch64 == arm64
  curl -fsSLO https://downloads.1password.com/linux/tar/stable/aarch64/1password-latest.tar.gz
  tar -xzf 1password-latest.tar.gz

  sudo mkdir -p /opt/1Password
  # Copy extracted contents into place (directory name includes version)
  sudo cp -a 1password-*/. /opt/1Password/

  sudo /opt/1Password/after-install.sh
  echo "1Password installed/updated in /opt/1Password"
else
  echo "This machine architecture is '$arch' (not arm64/aarch64). Skipping install."
  exit 1
fi

# Install Homebrew on Linux if not already installed
if ! command -v brew &> /dev/null; then
  echo "Homebrew not found. Installing Homebrew..."
  NONINTERACTIVE=1 /bin/bash -c \
    "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
  eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)"
fi

# Install AWS CLI using Homebrew
if command -v brew &> /dev/null; then
  echo "Installing AWS CLI..."
  brew install awscli
fi

# Install chruby-fish using Homebrew
if command -v brew &> /dev/null; then
  echo "Installing chruby-fish..."
  brew install chruby-fish
fi

# Install istioctl using Homebrew
if command -v brew &> /dev/null; then
  echo "Installing istioctl..."
  brew install istioctl
fi

# Install nvm using Homebrew
if command -v brew &> /dev/null; then
  echo "Installing nvm..."
  brew install nvm
fi

# Install oh-my-posh using Homebrew
if command -v brew &> /dev/null; then
  echo "Installing oh-my-posh..."
  brew install jandedobbeleer/oh-my-posh/oh-my-posh
fi

# Install pyenv using Homebrew
if command -v brew &> /dev/null; then
  echo "Installing pyenv..."
  brew install pyenv
fi

# Install pyenv-virtualenv using Homebrew
if command -v brew &> /dev/null; then
  echo "Installing pyenv-virtualenv..."
    brew install pyenv-virtualenv
fi

# Install zsh-autocomplete using Homebrew
if command -v brew &> /dev/null; then
  echo "Installing zsh-autocomplete..."
  brew install zsh-autocomplete
fi

# Install

echo "Custom script completed successfully."
