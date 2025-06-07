#!/bin/sh
# setup.sh
# Installs prerequisites and runs the Ansible playbook

# Exit on error
set -e

# Check for optional YAML file argument
PLAYBOOK_FILE=${1:-setup.yaml}

# Create a timestamp for the log file
TIMESTAMP=$(date +"%Y%m%d_%H%M%S")
LOG_FILE="setup_${TIMESTAMP}.txt"

# Inform user about logging
echo "Logging all output to: $LOG_FILE"
echo "Setup started at $(date)" | tee -a "$LOG_FILE"

# Function to log commands and their output
run_and_log() {
  echo "$ $*" | tee -a "$LOG_FILE"
  "$@" 2>&1 | tee -a "$LOG_FILE"
  return ${PIPESTATUS[0]}
}

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
  NONINTERACTIVE=1 /bin/bash \
    -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)" 2>&1 | tee -a "$LOG_FILE"
  (echo; echo 'eval "$(/opt/homebrew/bin/brew shellenv)"') >> ~/.zprofile
  (echo; echo 'eval "$(/opt/homebrew/bin/brew shellenv)"') >> ~/.bash_profile
  eval "$(/opt/homebrew/bin/brew shellenv)"
fi

# Install Ansible using Homebrew
echo "Installing Ansible via Homebrew..." | tee -a "$LOG_FILE"
run_and_log brew install ansible

echo "Running Ansible playbook: $PLAYBOOK_FILE" | tee -a "$LOG_FILE"
echo "Using provided sudo password for privileged operations" | tee -a "$LOG_FILE"

# Export the sudo password as an environment variable for Ansible
export ANSIBLE_SUDO_PASS="$SUDO_PASSWORD"

# Run the playbook (no -K flag since we're using environment variable)
run_and_log ansible-playbook "$PLAYBOOK_FILE"

# Unset the sudo password variable for security
unset ANSIBLE_SUDO_PASS

echo "Setup complete." | tee -a "$LOG_FILE"
echo "Full log available at: $LOG_FILE" | tee -a "$LOG_FILE"
