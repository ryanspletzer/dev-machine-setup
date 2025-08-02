#!/bin/bash

echo "This script is intended to be run on Ubuntu systems to customize settings."
echo "You can add your own custom commands here."

# Install Homebrew on Linux if not already installed
if ! command -v brew &> /dev/null; then
    echo "Homebrew not found. Installing Homebrew..."
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
    eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)"
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
