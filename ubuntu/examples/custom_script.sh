#!/bin/bash

echo "This script is intended to be run on Ubuntu systems to customize settings."
echo "You can add your own custom commands here."

# Install Homebrew on Linux if not already installed
if ! command -v brew &> /dev/null; then
    echo "Homebrew not found. Installing Homebrew..."
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
    eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)"
fi

# Install istioctl using Homebrew
if command -v brew &> /dev/null; then
    echo "Installing istioctl..."
    brew install istioctl
fi

echo "Custom script completed successfully."
