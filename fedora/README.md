# Fedora Development Machine Setup

This directory contains Ansible automation scripts to set up a consistent development environment on Fedora.
The automation installs and configures common development tools, applications, and settings to create a ready-to-use
development environment.

## Features

- **DNF Package Management**: Installs essential development tools and applications
- **Flatpak Package Management**: Installs GUI applications via Flatpak
- **Docker Setup**: Installs Docker and adds the user to the Docker group
- **PowerShell Setup**: Installs PowerShell and modules for development
- **Python Setup**: Installs Python versions via pyenv and pipx modules
- **Ruby Setup**: Installs Ruby via chruby
- **Node.js Setup**: Installs Node.js via nvm
- **Rust Setup**: Installs Rust via rustup
- **Go Setup**: Installs Go
- **.NET Setup**: Installs .NET SDK
- **VS Code Extensions**: Configures VS Code with essential development extensions
- **Git Setup**: Configures Git with user information, Git LFS, and Git Credential Manager
- **Custom Script Support**: Allows for additional customization via custom scripts

## Prerequisites

- Fedora 43 (also works on recent Fedora releases)
- Internet connection
- Administrator (sudo) privileges

## System Compatibility

This setup has been tested and confirmed to work on:

- Fedora 43
- WSL Fedora

## Quick Start

1. Get the script:

    ```bash
    # Clone the repository if you haven't already
    git clone https://github.com/ryanspletzer/dev-machine-setup.git
    cd dev-machine-setup/fedora

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

#### System Packages

```yaml
# Command-line tools and libraries via DNF
dnf_packages:
  - name: git
  - name: curl
  - name: cmake

# GUI applications via Flatpak
flatpak_packages:
  - name: com.slack.Slack
  - name: com.jgraph.drawio.desktop
```

#### Development Tools

```yaml
# PowerShell modules
powershell_modules:
  - AWS.Tools.Common
  - Terminal-Icons

# Python packages via pipx
pipx_packages:
  - poetry
  - ruff

# VS Code extensions
vscode_extensions:
  - ms-vscode.powershell
  - github.copilot
```

### WSL Specific Settings

If you're running in WSL,
set `is_wsl: true` in `vars.yaml` to enable WSL-specific configurations.

### Adding Custom Commands

You can add custom commands to be executed during setup
by adding entries to `custom_commands_user` and `custom_commands_elevated` in `vars.yaml`.

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

## Additional Resources

For comprehensive documentation and examples:

- [Complete Documentation](../docs/README.md) - Full project documentation
- [Design Principles](../docs/design-principles.md) - Understanding the philosophy
- [Troubleshooting Guide](../docs/troubleshooting.md) - Common issues and solutions
- [Architecture Overview](../docs/architecture.md) - How all the pieces fit together
- [Package Management Strategy](../docs/package-management.md) - Our approach to managing packages

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

### Applications

- Visual Studio Code
- Flatpak applications (configurable)

See `vars.yaml` for the complete list of installed packages.

## Ansible Tags

The playbook uses tags to allow selective execution of tasks:

- `dnf`: All DNF-related tasks
  - `update`: Only update DNF cache
  - `upgrade`: Only upgrade packages
  - `packages`: Only install packages
  - `repositories`: Only add repositories
- `flatpak`: Flatpak package installation
- `powershell`: PowerShell installation and module setup
- `pipx`: Python package installation via pipx
- `dotnet`: .NET SDK installation
- `npm`: Node.js package installation
- `vscode`: VS Code extension installation
- `git`: Git configuration tasks
- `custom`: Custom commands and script execution

You can run the playbook with specific tags using the `-t` option:

```bash
ansible-playbook -t dnf,git setup.yaml
```

## Troubleshooting

- **Logs**: All installation logs are saved to a timestamped log file in the current directory.
- **Verbosity**: Use the `-v` flag (can be repeated for more detail)
  to see more information during setup.
- **Failed Tasks**: You can safely rerun the setup script - it will skip already completed tasks.
- **Dependencies**: If you encounter errors about missing dependencies,
  try running with the `-p` flag first to install prerequisites,
  then run the script again normally.

## Security Notes

- The setup script securely handles your sudo password.
- All sudo operations are performed via Ansible which is safer than multiple direct sudo calls.
- The script only runs commands defined in the Ansible playbook or in your custom commands / custom script.

## WSL Notes

If you're using WSL (Windows Subsystem for Linux), make sure to:

1. Set `is_wsl: true` in `vars.yaml`
2. Consider whether you need all the GUI applications since WSL is primarily a terminal environment
3. Some features like Docker might be better installed on the Windows host when using WSL 2
