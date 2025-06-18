#!/bin/bash

echo "This script is intended to be run on Ubuntu systems to customize settings."
echo "You can add your own custom commands here."

# Create a Projects directory
mkdir -p ~/Projects

# Create a bin directory for user scripts and add to PATH if not already present
mkdir -p ~/bin
if ! grep -q 'PATH="$HOME/bin:$PATH"' ~/.bashrc; then
    echo 'export PATH="$HOME/bin:$PATH"' >> ~/.bashrc
fi

# Example: Configure git aliases
git config --global alias.co checkout
git config --global alias.br branch
git config --global alias.ci commit
git config --global alias.st status

# Example: Set up a SSH key if none exists
if [ ! -f ~/.ssh/id_ed25519 ]; then
    echo "No SSH key found, creating one..."
    ssh-keygen -t ed25519 -f ~/.ssh/id_ed25519 -N ""
    echo "SSH key created. Don't forget to add it to your GitHub/GitLab account."
    echo "Your public key is:"
    cat ~/.ssh/id_ed25519.pub
fi

echo "Custom script completed successfully."
