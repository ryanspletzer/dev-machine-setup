# macOS Development Machine Setup

This directory contains Ansible automation scripts to set up a consistent development environment on macOS.
The automation installs and configures common development tools, applications, and settings to create a ready-to-use
development environment.

## Features

- 🍺 **Homebrew Package Management**: Installs Homebrew taps, casks, and formulae
- 🔧 **PowerShell Module Installation**: Sets up PowerShell modules for development
- 📦 **Python Package Management**: Installs pipx modules
- 🧩 **Node.js Package Management**: Installs npm packages globally
- ⚙️ **.NET Global Tools**: Installs .NET global tools (when .NET SDK is available)
- 💻 **VS Code Extensions**: Configures VS Code with essential development extensions
- 🔄 **Git Setup**: Configures Git with user information and LFS support
- ⚙️ **macOS System Preferences**: Applies recommended macOS system preferences
- 🚀 **Custom Script Support**: Allows for additional customization via custom scripts

## Prerequisites

- macOS (works on both Intel and Apple Silicon)
- Internet connection
- Administrator (sudo) privileges

## System Compatibility

This setup has been tested and confirmed to work on:

- macOS Sequoia (15.x)

Some applications may require Rosetta 2, which can be installed automatically by setting `install_rosetta: true` in
`vars.yaml`.

## Quick Start

1. Get the script:

    ```zsh
    # Copy the contents of the macOS directory to somewhere like Downloads if you don't have git installed yet to clone
    # the repo

    # Change to that directory
    cd ~/Downloads

    # Allow the setup.sh script to run
    chmod 700 ./setup.sh
    ```

2. Run the setup script:

    ```zsh
    # Run the script
    ./setup.sh -e "your.email@example.com"
    ```

## Setup Options

The `setup.sh` script accepts several options:

```zsh
Usage: ./setup.sh [-v] [-e git_email] [-n git_name] [-p] [playbook_file]
  -v              Enable verbose output (can be repeated for more verbosity, e.g. -vv or -vvv)
  -e git_email    Specify Git user email
  -n git_name     Specify Git user name
  -p              Install prerequisites only (Homebrew and Ansible), don't run Ansible playbook
  playbook_file   Optional playbook file name (defaults to setup.yaml)
```

### Examples

- Basic installation with Git email:

  ```zsh
  ./setup.sh -e "your.email@example.com"
  ```

- Install with verbose output and custom Git name:

  ```zsh
  ./setup.sh -v -e "your.email@example.com" -n "Your Name"
  ```

- Install prerequisites only (Homebrew and Ansible):

  ```zsh
  ./setup.sh -p
  ```

- Use a custom playbook file:

  ```zsh
  ./setup.sh -e "your.email@example.com" custom_playbook.yaml
  ```

## Customization

### Modifying Installed Packages

Edit `vars.yaml` to customize which packages get installed:

- `homebrew_taps`: List of Homebrew taps to add
- `homebrew_casks`: GUI applications to install
- `homebrew_formulae`: Command-line tools to install
- `powershell_modules`: PowerShell modules to install
- `pipx_modules`: Python packages to install via pipx
- `npm_global_packages`: Node.js packages to install globally via npm
- `dotnet_tools`: .NET global tools to install (requires .NET SDK)
- `vscode_extensions`: VS Code extensions to install

### macOS System Preferences

The setup automatically configures macOS with developer-friendly preferences:

- Show hidden files in Finder
- Enable path bar and status bar in Finder
- Disable warnings when changing file extensions
- Prevent .DS_Store file creation on network/USB volumes
- Set Finder to list view by default
- Configure Dock behavior (auto-hide, animation speed)
- Configure TextEdit to use plain text by default
- Configure trackpad settings

You can customize these settings by editing the `custom_commands_user` and `custom_commands_elevated` sections in
`vars.yaml`.

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
- AWS CLI, Azure CLI, Terraform, Packer
- PowerShell
- Global npm packages (AWS CDK, npmrc)
- .NET global tools (Amazon Lambda Tools)

### Applications

- iTerm2
- Microsoft Office
- Microsoft Edge
- Microsoft Teams
- Rectangle Pro (window management)
- 1Password
- Docker Desktop

See `vars.yaml` for the complete list of installed packages.

## Ansible Tags

The playbook uses tags to allow selective execution of tasks:

- `homebrew`: All Homebrew-related tasks
  - `taps`: Only Homebrew taps
  - `casks`: Only Homebrew casks (applications)
  - `formulae`: Only Homebrew formulae (CLI tools)
- `powershell`: PowerShell module installation
- `pipx`: Python package installation via pipx
- `npm`: Node.js package installation via npm
- `dotnet`: .NET global tools installation
- `vscode`: VS Code extension installation
- `git`: Git configuration tasks
- `macos`: macOS system preferences
  - `preferences`: macOS preference settings
  - `user-commands`: User-level commands
  - `elevated-commands`: Commands requiring sudo
- `custom`: Custom script execution

## Troubleshooting

- **Logs**: All installation logs are saved to a timestamped log file in the current directory.
- **Verbosity**: Use the `-v` flag (can be repeated for more detail) to see more information during setup.
- **Failed Tasks**: You can safely rerun the setup script - it will skip already completed tasks.

## Security Notes

- The setup script securely handles your sudo password via storing it securely in macOS Keychain and removes it after
  completion.
  This is to prevent additional prompts throughout the running of the script.
- All credentials are temporary and cleaned up when the script exits.
- The script only runs commands defined in the Ansible playbook or in your custom commands / custom script.

## Notes for Apple Silicon Macs

- Some applications require Rosetta 2. To install it, set `install_rosetta: true` in `vars.yaml`.
- Some Homebrew packages may have compatibility issues with Apple Silicon.
