# Ubuntu Development Machine Setup

This directory contains Ansible automation scripts to set up a consistent development environment on Ubuntu.
The automation installs and configures common development tools, applications, and settings to create a ready-to-use
development environment.

## Features

- 📦 **APT Package Management**: Installs essential development tools and applications
- 📱 **Snap Package Management**: Installs GUI applications via Snap
- 🐳 **Docker Setup**: Installs Docker and adds the user to the Docker group
- 🔧 **PowerShell Setup**: Installs PowerShell and modules for development
- 🐍 **Python Setup**: Installs Python versions via pyenv and pipx modules
- 💎 **Ruby Setup**: Installs Ruby via rbenv
- 🟦 **Node.js Setup**: Installs Node.js via nvm
- 🦀 **Rust Setup**: Installs Rust via rustup
- ⚡ **Go Setup**: Installs Go
- 🔷 **.NET Setup**: Installs .NET SDK
- 💻 **VS Code Extensions**: Configures VS Code with essential development extensions
- 🔄 **Git Setup**: Configures Git with user information, Git LFS, and Git Credential Manager
- 🚀 **Custom Script Support**: Allows for additional customization via custom scripts

## Prerequisites

- Ubuntu 24.04 (also works on older versions)
- Internet connection
- Administrator (sudo) privileges

## System Compatibility

This setup has been tested and confirmed to work on:

- Ubuntu 24.04 LTS
- Ubuntu 22.04 LTS
- WSL Ubuntu

## Quick Start

1. Get the script:

    ```bash
    # Clone the repository if you haven't already
    git clone https://github.com/yourusername/ansible-devmachinesetup.git
    cd ansible-devmachinesetup/ubuntu

    # Allow the setup.sh script to run
    chmod +x ./setup.sh
    ```

2. Run the setup script:

    ```bash
    # Run the script
    ./setup.sh -e "your.email@example.com"
    ```

## Setup Options

The `setup.sh` script accepts several options:

```bash
Usage: ./setup.sh [-v] [-e git_email] [-n git_name] [-p] [playbook_file]
  -v              Enable verbose output (can be repeated for more verbosity, e.g. -vv or -vvv)
  -e git_email    Specify Git user email
  -n git_name     Specify Git user name
  -p              Install prerequisites only (Ansible), don't run Ansible playbook
  playbook_file   Optional playbook file name (defaults to setup.yaml)
```

### Examples

- Basic installation with Git email:

  ```bash
  ./setup.sh -e "your.email@example.com"
  ```

- Install with verbose output and custom Git name:

  ```bash
  ./setup.sh -v -e "your.email@example.com" -n "Your Name"
  ```

- Install prerequisites only (Ansible):

  ```bash
  ./setup.sh -p
  ```

- Use a custom playbook file:

  ```bash
  ./setup.sh custom_setup.yaml
  ```

## Customization

### Modifying Installed Packages

Edit `vars.yaml` to customize which packages get installed:

- `apt_packages`: Command-line tools and libraries to install via APT
- `snap_packages`: GUI applications to install via Snap
- `powershell_modules`: PowerShell modules to install
- `pipx_modules`: Python packages to install via pipx
- `vscode_extensions`: VS Code extensions to install

### WSL Specific Settings

If you're running in WSL, set `is_wsl: true` in `vars.yaml` to enable WSL-specific configurations.

### Adding Custom Commands

You can add custom commands to be executed during setup by adding entries to `custom_commands_user` and `custom_commands_elevated` in `vars.yaml`.

### Adding Custom Scripts

To add additional setup steps:

1. Create a custom script in the `examples/` directory or elsewhere
2. Set the `custom_script` variable in `vars.yaml` to point to your script
3. Make sure the script is executable (`chmod +x your_script.sh`)

## Components

- `setup.sh`: Main setup script that installs prerequisites and runs the Ansible playbook
- `setup.yaml`: Ansible playbook that performs the installation and configuration
- `vars.yaml`: Configuration variables defining what gets installed
- `examples/`: Directory containing example custom scripts

## Notable Default Packages

The default setup includes a curated selection of popular development tools and applications:

### Developer Tools

- Docker
- Git and Git LFS
- Visual Studio Code
- .NET SDK
- Python, Node.js, Ruby, Go, Rust
- AWS CLI, Azure CLI
- PowerShell
- Wine64 (Windows compatibility layer)

### Applications

- Visual Studio Code
- Spotify
- Slack
- Docker Desktop

See `vars.yaml` for the complete list of installed packages.

## Ansible Tags

The playbook uses tags to allow selective execution of tasks:

- `apt`: All APT-related tasks
  - `update`: Only update APT cache
  - `upgrade`: Only upgrade packages
  - `packages`: Only install packages
  - `repositories`: Only add repositories
- `snap`: Snap package installation
- `docker`: Docker installation and configuration
- `powershell`: PowerShell installation and module setup
- `python`: Python setup with pyenv
- `pipx`: Python package installation via pipx
- `ruby`: Ruby setup with rbenv
- `nodejs`: Node.js setup with nvm
- `go`: Go installation
- `rust`: Rust installation
- `dotnet`: .NET SDK installation
- `vscode`: VS Code extension installation
- `git`: Git configuration tasks
- `custom`: Custom commands and script execution

You can run the playbook with specific tags using the `-t` option:

```bash
ansible-playbook -t apt,git setup.yaml
```

## Troubleshooting

- **Logs**: All installation logs are saved to a timestamped log file in the current directory.
- **Verbosity**: Use the `-v` flag (can be repeated for more detail) to see more information during setup.
- **Failed Tasks**: You can safely rerun the setup script - it will skip already completed tasks.
- **Dependencies**: If you encounter errors about missing dependencies, try running with the `-p` flag first to install prerequisites, then run the script again normally.

## Security Notes

- The setup script securely handles your sudo password.
- All sudo operations are performed via Ansible which is safer than multiple direct sudo calls.
- The script only runs commands defined in the Ansible playbook or in your custom commands / custom script.

## WSL Notes

If you're using WSL (Windows Subsystem for Linux), make sure to:

1. Set `is_wsl: true` in `vars.yaml`
2. Consider whether you need all the GUI applications since WSL is primarily a terminal environment
3. Some features like Docker might be better installed on the Windows host when using WSL 2
