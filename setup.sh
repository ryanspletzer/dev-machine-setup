#!/bin/sh
# setup.sh
# Installs prerequisites and runs the Ansible playbook

# Exit on error
set -e

# Initialize verbosity level as empty
VERBOSITY=""

# Parse command line arguments
while getopts "v" opt; do
  case $opt in
    v)
      # Count the number of 'v's to determine verbosity level
      if [ -z "$VERBOSITY" ]; then
        VERBOSITY="-v"
      elif [ "$VERBOSITY" = "-v" ]; then
        VERBOSITY="-vv"
      elif [ "$VERBOSITY" = "-vv" ]; then
        VERBOSITY="-vvv"
      fi
      ;;
    \?)
      echo "Invalid option: -$OPTARG" >&2
      exit 1
      ;;
  esac
done

# Reset argument pointer
shift $((OPTIND-1))

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

# Store password in keychain with a unique service name
KEYCHAIN_SERVICE="ansible-devmachinesetup-temp"
KEYCHAIN_ACCOUNT="sudo-password"

# Store password in keychain (overwrite if exists)
security delete-generic-password -s "$KEYCHAIN_SERVICE" -a "$KEYCHAIN_ACCOUNT" &>/dev/null || true
security add-generic-password -s "$KEYCHAIN_SERVICE" -a "$KEYCHAIN_ACCOUNT" -w "$SUDO_PASSWORD"

# Create a temporary askpass script that retrieves the password from keychain
ASKPASS_SCRIPT=$(mktemp)
chmod 700 "$ASKPASS_SCRIPT"
cat > "$ASKPASS_SCRIPT" << EOF
#!/bin/sh
security find-generic-password -s "$KEYCHAIN_SERVICE" -a "$KEYCHAIN_ACCOUNT" -w
EOF

# Set SUDO_ASKPASS and other environment variables
export SUDO_ASKPASS="$ASKPASS_SCRIPT"
export ANSIBLE_SUDO_PASS="$SUDO_PASSWORD"

# For Homebrew
export HOMEBREW_SUDO_ASKPASS="$ASKPASS_SCRIPT"

# sudo with password
printf '%s\n' "$SUDO_PASSWORD" | sudo -S -v
# Start background process to keep sudo alive and store its PID
( while true; do sudo -n true; sleep 15; done ) 2>/dev/null &
SUDO_KEEP_ALIVE_PID=$!

# Install Homebrew if not already installed
if [ -x "/opt/homebrew/bin/brew" ]; then
  echo "Homebrew already installed." | tee -a "$LOG_FILE"
else
  echo "Installing Homebrew..." | tee -a "$LOG_FILE"
  # Use NONINTERACTIVE to avoid prompts during Homebrew installation
  NONINTERACTIVE=1 /bin/bash \
    -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)" 2>&1 | tee -a "$LOG_FILE"
  (echo; echo 'eval "$(/opt/homebrew/bin/brew shellenv)"') >> ~/.zprofile
  (echo; echo 'eval "$(/opt/homebrew/bin/brew shellenv)"') >> ~/.bash_profile
  eval "$(/opt/homebrew/bin/brew shellenv)"
fi

# Install Ansible using Homebrew
echo "Installing Ansible via Homebrew..." | tee -a "$LOG_FILE"
run_and_log /opt/homebrew/bin/brew install ansible

echo "Using provided sudo password for privileged operations" | tee -a "$LOG_FILE"

# Export the sudo password as an environment variable for Ansible
export ANSIBLE_SUDO_PASS="$SUDO_PASSWORD"

# Create Ansible configuration directory if it doesn't exist
mkdir -p ~/.ansible/

# Configure Ansible logging
cat > ~/.ansible/ansible.cfg << EOF
[defaults]
log_path = $PWD/$LOG_FILE
stdout_callback = yaml
display_skipped_hosts = True
display_ok_hosts = True
callbacks_enabled = profile_tasks

[callback_profile_tasks]
task_output_limit = 100
EOF

echo "Configured Ansible logging to: $LOG_FILE" | tee -a "$LOG_FILE"

# Run the playbook with increased verbosity for better progress tracking
echo "Running Ansible playbook: $PLAYBOOK_FILE" | tee -a "$LOG_FILE"
if [ -n "$VERBOSITY" ]; then
  echo "Using verbosity level: $VERBOSITY" | tee -a "$LOG_FILE"
fi
/opt/homebrew/bin/ansible-playbook $VERBOSITY "$PLAYBOOK_FILE"

# Cleanup
echo "Cleaning up temporary files and environment variables..." | tee -a "$LOG_FILE"

# Kill the sudo refresh process
if [ -n "$SUDO_KEEP_ALIVE_PID" ]; then
  echo "Killing sudo keep alive process (PID: $SUDO_KEEP_ALIVE_PID)" | tee -a "$LOG_FILE"
  kill "$SUDO_KEEP_ALIVE_PID" >/dev/null 2>&1 || true
fi

# Unset environment variables
unset SUDO_ASKPASS
unset ANSIBLE_SUDO_PASS
unset HOMEBREW_SUDO_ASKPASS

# Remove the temporary askpass script
echo "Removing temporary askpass script: $ASKPASS_SCRIPT" | tee -a "$LOG_FILE"
if [ -f "$ASKPASS_SCRIPT" ]; then
  rm -f "$ASKPASS_SCRIPT"
  if [ -f "$ASKPASS_SCRIPT" ]; then
    echo "Warning: Failed to remove askpass script: $ASKPASS_SCRIPT" | tee -a "$LOG_FILE"
  else
    echo "Successfully removed askpass script" | tee -a "$LOG_FILE"
  fi
fi

# Remove password from keychain
echo "Removing password from keychain..." | tee -a "$LOG_FILE"
security delete-generic-password -s "$KEYCHAIN_SERVICE" -a "$KEYCHAIN_ACCOUNT" &>/dev/null
if [ $? -eq 0 ]; then
  echo "Successfully removed password from keychain" | tee -a "$LOG_FILE"
else
  echo "Warning: Failed to remove password from keychain" | tee -a "$LOG_FILE"
fi

echo "Setup complete." | tee -a "$LOG_FILE"
echo "Full log available at: $LOG_FILE" | tee -a "$LOG_FILE"

# Function to clean up before exit
cleanup() {
  echo "Performing cleanup..." | tee -a "$LOG_FILE"

  # Kill the sudo refresh process if it exists
  if [ -n "$SUDO_KEEP_ALIVE_PID" ]; then
    echo "Killing sudo keep alive process (PID: $SUDO_KEEP_ALIVE_PID)" | tee -a "$LOG_FILE"
    kill "$SUDO_KEEP_ALIVE_PID" >/dev/null 2>&1 || true
  fi

  # Unset environment variables
  unset SUDO_ASKPASS
  unset ANSIBLE_SUDO_PASS
  unset HOMEBREW_SUDO_ASKPASS

  # Remove the temporary askpass script
  if [ -n "$ASKPASS_SCRIPT" ] && [ -f "$ASKPASS_SCRIPT" ]; then
    echo "Removing temporary askpass script: $ASKPASS_SCRIPT" | tee -a "$LOG_FILE"
    rm -f "$ASKPASS_SCRIPT"
    if [ -f "$ASKPASS_SCRIPT" ]; then
      echo "Warning: Failed to remove askpass script: $ASKPASS_SCRIPT" | tee -a "$LOG_FILE"
    else
      echo "Successfully removed askpass script" | tee -a "$LOG_FILE"
    fi
  fi

  # Remove password from keychain
  if [ -n "$KEYCHAIN_SERVICE" ] && [ -n "$KEYCHAIN_ACCOUNT" ]; then
    echo "Removing password from keychain..." | tee -a "$LOG_FILE"
    security delete-generic-password -s "$KEYCHAIN_SERVICE" -a "$KEYCHAIN_ACCOUNT" &>/dev/null
    if [ $? -eq 0 ]; then
      echo "Successfully removed password from keychain" | tee -a "$LOG_FILE"
    else
      echo "Warning: Failed to remove password from keychain" | tee -a "$LOG_FILE"
    fi
  fi
}

# Set up trap to ensure cleanup on exit
trap cleanup EXIT INT TERM
