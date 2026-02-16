#!/bin/bash
# setup.sh
# Installs prerequisites and runs the Ansible playbook for Ubuntu
#
# Usage: ./setup.sh [-v] [-e git_email] [-n git_name] [-p] [-c] [playbook_file]
#   -v              Enable verbose output (can be repeated for more verbosity)
#   -e git_email    Specify Git user email
#   -n git_name     Specify Git user name
#   -p              Install prerequisites only (Ansible), don't run Ansible playbook
#   -c              CI mode: skip interactive sudo prompts (assumes passwordless sudo)
#   playbook_file   Optional playbook file name (defaults to setup.yaml)

# Exit on error
set -e

# Initialize verbosity level as empty
VERBOSITY=""
GIT_EMAIL=""
GIT_NAME=""
PREREQS_ONLY=false
CI_MODE=false

# Parse command line arguments
while getopts "ve:n:pc" opt; do
  case $opt in
    v)
      # Increment verbosity level with each -v flag
      if [ -z "$VERBOSITY" ]; then
        VERBOSITY="-v"
      else
        VERBOSITY="${VERBOSITY}v"
      fi
      ;;
    e)
      GIT_EMAIL="$OPTARG"
      ;;
    n)
      GIT_NAME="$OPTARG"
      ;;
    p)
      PREREQS_ONLY=true
      ;;
    c)
      # CI mode: skip interactive sudo prompts
      CI_MODE=true
      ;;
    \?)
      echo "Invalid option: -$OPTARG" >&2
      exit 1
      ;;
    :)
      echo "Option -$OPTARG requires an argument." >&2
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

if [ "$CI_MODE" = true ]; then
  echo "CI mode: using passwordless sudo" | tee -a "$LOG_FILE"
  export ANSIBLE_SUDO_PASS=""
else
  # Prompt for sudo password once and store it securely
  read -s -p "Enter sudo password: " SUDO_PASSWORD
  echo

  # Start background process to keep sudo alive and store its PID
  ( while true; do sudo -k; echo "$SUDO_PASSWORD" | sudo -S -v >/dev/null 2>&1; sleep 15; done ) &
  SUDO_KEEP_ALIVE_PID=$!

  # Export the sudo password as an environment variable for Ansible
  export ANSIBLE_SUDO_PASS="$SUDO_PASSWORD"
fi

# Check if apt-get is available
if ! command -v apt-get >/dev/null 2>&1; then
  echo "Error: apt-get not found. This script is intended for Ubuntu systems." | tee -a "$LOG_FILE"
  exit 1
fi

# Update package lists
echo "Updating package lists..." | tee -a "$LOG_FILE"
if [ "$CI_MODE" = true ]; then
  sudo apt-get update -y 2>&1 | tee -a "$LOG_FILE"
else
  echo "$SUDO_PASSWORD" | sudo -S apt-get update -y 2>&1 | tee -a "$LOG_FILE"
fi

# Install dependencies
echo "Installing required dependencies..." | tee -a "$LOG_FILE"
if [ "$CI_MODE" = true ]; then
  sudo apt-get install -y software-properties-common python3 python3-pip 2>&1 | tee -a "$LOG_FILE"
else
  echo "$SUDO_PASSWORD" | sudo -S apt-get install -y software-properties-common python3 python3-pip 2>&1 | tee -a "$LOG_FILE"
fi

# Install Ansible
echo "Installing Ansible..." | tee -a "$LOG_FILE"
if [ "$CI_MODE" = true ]; then
  sudo apt-get install -y ansible 2>&1 | tee -a "$LOG_FILE"
else
  echo "$SUDO_PASSWORD" | sudo -S apt-get install -y ansible 2>&1 | tee -a "$LOG_FILE"
fi

# Check if we're in "prereqs only" mode
if [ "$PREREQS_ONLY" = true ]; then
  echo "Prerequisites installation complete." | tee -a "$LOG_FILE"
  echo "Skipping Ansible playbook execution as requested (-p flag)." | tee -a "$LOG_FILE"

  # Clean up
  if [ "$CI_MODE" != true ]; then
    kill "$SUDO_KEEP_ALIVE_PID" >/dev/null 2>&1 || true
  fi
  unset ANSIBLE_SUDO_PASS

  exit 0
fi

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
localhost_warning = False
deprecation_warnings = False

[callback_profile_tasks]
task_output_limit = 100
EOF

echo "Configured Ansible logging to: $LOG_FILE" | tee -a "$LOG_FILE"

# Build extra vars for Git email and name if provided
EXTRA_VARS=""
if [ -n "$GIT_EMAIL" ]; then
  EXTRA_VARS="$EXTRA_VARS git_user_email='$GIT_EMAIL'"
fi
if [ -n "$GIT_NAME" ]; then
  EXTRA_VARS="$EXTRA_VARS git_user_name='$GIT_NAME'"
fi

# Run the playbook with the specified verbosity
echo "Running Ansible playbook: $PLAYBOOK_FILE" | tee -a "$LOG_FILE"
if [ -n "$VERBOSITY" ]; then
  echo "Using verbosity level: $VERBOSITY" | tee -a "$LOG_FILE"
fi

if [ -n "$EXTRA_VARS" ]; then
  ansible-playbook $VERBOSITY --extra-vars "$EXTRA_VARS" "$PLAYBOOK_FILE"
else
  ansible-playbook $VERBOSITY "$PLAYBOOK_FILE"
fi

# Clean up
echo "Cleaning up..." | tee -a "$LOG_FILE"

if [ "$CI_MODE" != true ]; then
  # Kill the sudo refresh process
  if [ -n "$SUDO_KEEP_ALIVE_PID" ]; then
    kill "$SUDO_KEEP_ALIVE_PID" >/dev/null 2>&1 || true
  fi
fi

# Unset environment variables
unset ANSIBLE_SUDO_PASS

echo "Setup complete." | tee -a "$LOG_FILE"
echo "Full log available at: $LOG_FILE" | tee -a "$LOG_FILE"
echo "You may need to restart your shell or source your .bashrc to apply all changes."

# Function to clean up before exit
cleanup() {
  if [ "$CI_MODE" != true ]; then
    # Kill the sudo refresh process if it exists
    if [ -n "$SUDO_KEEP_ALIVE_PID" ]; then
      kill "$SUDO_KEEP_ALIVE_PID" >/dev/null 2>&1 || true
    fi
  fi

  # Unset environment variables
  unset ANSIBLE_SUDO_PASS
}

# Set up trap to ensure cleanup on exit
trap cleanup EXIT INT TERM
