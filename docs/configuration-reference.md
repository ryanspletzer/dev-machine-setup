# Configuration Reference

This document provides a complete reference for all configuration options available across all platforms in the dev-machine-setup project.

## Overview

Each platform (macOS, Windows, Ubuntu, and Fedora) uses YAML-based configuration
files (`vars.yaml`) to define what gets installed and configured.
While the specific variable names may differ between platforms,
the structure and concepts remain consistent.

## Common Configuration Structure

```yaml
# Basic Git configuration (all platforms)
git_user_email: ''                 # Your Git email address
git_user_name: ''                  # Your Git display name

# Custom commands (all platforms)
custom_commands_user: []           # Commands run as regular user
custom_commands_elevated: []       # Commands run with elevated privileges
custom_script: ''                  # Path to custom script file

# VS Code extensions (all platforms)
vscode_extensions: []              # List of VS Code extensions

# PowerShell modules (all platforms)
powershell_modules: []             # List of PowerShell modules

# Python packages via pipx (all platforms)
pipx_packages: []                  # List of Python CLI tools
```

## macOS Configuration Reference

### System Configuration

```yaml
# Rosetta 2 installation for Apple Silicon Macs
install_rosetta: false            # Set to true to install Rosetta 2
```

### Homebrew Configuration

```yaml
# Homebrew package repositories
homebrew_taps:
  - aws/tap                        # AWS CLI tools
  - azure/bicep                    # Azure Bicep tools
  - hashicorp/tap                  # HashiCorp tools

# Command-line tools and libraries
homebrew_formulae:
  - git                           # Version control
  - docker                        # Container runtime
  - terraform                     # Infrastructure as code
  - awscli                        # AWS command line interface

# GUI applications
homebrew_casks:
  - visual-studio-code            # Code editor
  - docker-desktop                # Docker GUI
  - google-chrome                 # Web browser
  - microsoft-office              # Office suite
```

### Additional Package Managers

```yaml
# Node.js global packages
npm_global_packages:
  - aws-cdk                       # AWS CDK toolkit
  - '@angular/cli'                # Angular CLI
  - prettier                      # Code formatter

# .NET global tools
dotnet_tools:
  - Amazon.Lambda.Tools           # AWS Lambda tools for .NET
  - dotnet-ef                     # Entity Framework tools
```

### Custom Commands

```yaml
# Commands executed as the current user
custom_commands_user:
  # Show hidden files in Finder
  - defaults write com.apple.finder AppleShowAllFiles -bool true
  # Set Finder to list view
  - defaults write com.apple.finder FXPreferredViewStyle -string "Nlsv"
  # Configure Dock auto-hide
  - defaults write com.apple.dock autohide -bool true

# Commands executed with sudo privileges
custom_commands_elevated:
  # Add fish to allowed shells
  - echo "/opt/homebrew/bin/fish" | sudo tee -a /etc/shells
```

## Windows Configuration Reference

### Chocolatey Packages

```yaml
# Applications and tools via Chocolatey
choco_packages:
  - name: git                     # Version control
  - name: vscode                  # Code editor
  - name: docker-desktop          # Container platform
  - name: terraform               # Infrastructure as code
  - name: kubernetes-cli          # Kubernetes command line
  - name: azure-cli               # Azure command line
  - name: awscli                  # AWS command line
```

### Additional Package Managers

```yaml
# Node.js global packages (installed via npm after Node.js)
npm_global_packages:
  - aws-cdk                       # AWS CDK toolkit
  - '@angular/cli'                # Angular CLI
  - typescript                    # TypeScript compiler
```

### Custom Commands

```yaml
# Commands executed as the current user
custom_commands_user:
  # Enable Windows features
  - Enable-WindowsOptionalFeature -Online -FeatureName Microsoft-Windows-Subsystem-Linux -NoRestart
  # Configure PowerShell execution policy
  - Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser

# Commands executed with administrator privileges
custom_commands_elevated:
  # Install Windows features that require elevation
  - dism.exe /online /enable-feature /featurename:VirtualMachinePlatform /all /norestart
```

## Ubuntu Configuration Reference

### APT Packages

```yaml
# System packages and command-line tools
apt_packages:
  - git                          # Version control
  - curl                         # HTTP client
  - wget                         # Download utility
  - build-essential              # Compilation tools
  - software-properties-common   # Repository management
  - apt-transport-https          # HTTPS transport for APT
```

### Snap Packages

```yaml
# GUI applications via Snap
snap_packages:
  - code --classic               # VS Code with classic confinement
  - discord                      # Communication app
  - slack --classic              # Team communication
```

### WSL Configuration

```yaml
# Windows Subsystem for Linux specific settings
is_wsl: false                    # Set to true when running in WSL environment
```

### Custom Commands

```yaml
# Commands executed as the current user
custom_commands_user:
  # Configure Git to use Windows credential manager in WSL
  - git config --global credential.helper "/mnt/c/Program\ Files/Git/mingw64/bin/git-credential-manager.exe"
  # Set dark theme
  - gsettings set org.gnome.desktop.interface gtk-theme 'Adwaita-dark'

# Commands executed with sudo privileges
custom_commands_elevated:
  # Add user to docker group
  - sudo usermod -aG docker $USER
  # Enable and start Docker service
  - sudo systemctl enable docker --now
```

## Fedora Configuration Reference

### DNF Packages

```yaml
# System packages and command-line tools
dnf_packages:
  - git                          # Version control
  - curl                         # HTTP client
  - wget                         # Download utility
  - gcc                          # C compiler
  - make                         # Build automation
  - dnf-plugins-core             # DNF plugin support
```

### Flatpak Packages

```yaml
# GUI applications via Flatpak
flatpak_packages:
  - com.visualstudio.code        # VS Code
  - com.discordapp.Discord       # Communication app
  - com.slack.Slack              # Team communication
```

### External DNF Repositories

```yaml
# Additional DNF repositories
external_dnf_repositories:
  - name: hashicorp
    baseurl: https://rpm.releases.hashicorp.com/fedora/$releasever/$basearch/stable
    gpgkey: https://rpm.releases.hashicorp.com/gpg
```

### WSL Configuration

```yaml
# Windows Subsystem for Linux specific settings
is_wsl: false                    # Set to true when running in WSL environment
```

### Custom Commands

```yaml
# Commands executed as the current user
custom_commands_user:
  # Configure Git to use Windows credential manager in WSL
  - git config --global credential.helper "/mnt/c/Program\ Files/Git/mingw64/bin/git-credential-manager.exe"
  # Set dark theme
  - gsettings set org.gnome.desktop.interface gtk-theme 'Adwaita-dark'

# Commands executed with sudo privileges
custom_commands_elevated:
  # Add user to docker group
  - sudo usermod -aG docker $USER
  # Enable and start Docker service
  - sudo systemctl enable docker --now
```

## Cross-Platform Configuration Options

### VS Code Extensions

Extensions use the same format across all platforms:

```yaml
vscode_extensions:
  # GitHub integration
  - github.copilot                # GitHub Copilot
  - github.copilot-chat          # Copilot Chat
  - github.vscode-pull-request-github # PR management

  # Language support
  - ms-python.python             # Python
  - golang.go                    # Go
  - rust-lang.rust-analyzer      # Rust
  - ms-dotnettools.csharp        # C#

  # Development tools
  - ms-azuretools.vscode-docker  # Docker support
  - hashicorp.terraform          # Terraform
  - ms-kubernetes-tools.vscode-kubernetes-tools # Kubernetes

  # Code quality
  - esbenp.prettier-vscode       # Code formatter
  - streetsidesoftware.code-spell-checker # Spell checker
  - usernamehw.errorlens         # Inline error display
```

### PowerShell Modules

PowerShell modules use consistent names across platforms:

```yaml
powershell_modules:
  # Azure tools
  - Az.Accounts                  # Azure authentication
  - Az.Resources                 # Azure resource management

  # AWS tools
  - AWS.Tools.Common             # AWS PowerShell common
  - AWS.Tools.EC2                # AWS EC2 management

  # Development tools
  - posh-git                     # Git integration for PowerShell
  - PSReadLine                   # Enhanced command line editing
  - PSScriptAnalyzer             # PowerShell script analysis

  # Utility modules
  - powershell-yaml              # YAML parsing
  - Microsoft.Graph.Authentication # Microsoft Graph
```

### Python Packages (pipx)

Python CLI tools installed via pipx:

```yaml
pipx_packages:
  # Development tools
  - poetry                       # Dependency management
  - black                        # Code formatter
  - flake8                       # Linting
  - mypy                         # Type checking

  # AWS tools
  - taskcat                      # CloudFormation testing
  - awscli-local                 # LocalStack CLI

  # DevOps tools
  - ansible                      # Automation (where not system package)
  - cookiecutter                 # Project templating
```

## Advanced Configuration Options

### Git Configuration

```yaml
# Git user settings
git_user_email: 'user@example.com'     # Required: Your Git email
git_user_name: 'Full Name'              # Optional: Defaults to system full name

# Advanced Git configuration (via custom commands)
custom_commands_user:
  # Set default branch name
  - git config --global init.defaultBranch main
  # Enable rerere (reuse recorded resolution)
  - git config --global rerere.enabled true
  # Set pull strategy
  - git config --global pull.rebase false
```

### Environment Variables

```yaml
# Set environment variables via custom commands
custom_commands_user:
  # Set development environment
  - echo 'export ENVIRONMENT=development' >> ~/.bashrc
  # Configure editor
  - echo 'export EDITOR=code' >> ~/.bashrc

  # macOS specific
  - echo 'export HOMEBREW_NO_ANALYTICS=1' >> ~/.zshrc

  # Windows specific (PowerShell profile)
  - Add-Content $PROFILE '$env:EDITOR = "code"'
```

### Custom Script Integration

```yaml
# Path to custom script (relative or absolute)
custom_script: './custom_setup.sh'     # Unix platforms
custom_script: './custom_setup.ps1'    # Windows platform
```

Example custom script structure:

```bash
#!/bin/bash
# custom_setup.sh

echo "Running custom setup..."

# Install additional tools not in package managers
curl -sSL https://get.docker.com | sh

# Configure development directories
mkdir -p ~/Development/{personal,work,experiments}

# Set up SSH keys
ssh-keygen -t ed25519 -C "user@example.com" -f ~/.ssh/id_ed25519 -N ""

echo "Custom setup complete!"
```

## Configuration Validation

### Required Fields

Some fields are required for proper operation:

```yaml
# Required on all platforms
git_user_email: 'user@example.com'     # Must be set or passed via -e flag

# Platform-specific required fields
# (Most other fields have sensible defaults)
```

### Data Types and Formats

```yaml
# Boolean values
install_rosetta: true                   # true or false
is_wsl: false                          # true or false

# String values
git_user_email: 'user@example.com'     # Single-quoted strings
custom_script: './setup.sh'            # File paths

# Arrays of strings
homebrew_formulae:                      # YAML array format
  - git
  - docker

# Arrays of objects (Windows Chocolatey)
choco_packages:
  - name: git                           # Object with 'name' field
  - name: docker-desktop
```

### Comments and Documentation

YAML files support comments for documentation:

```yaml
# This is a comment explaining the next section
homebrew_formulae:
  - git              # Version control system
  - docker           # Container runtime
  # - disabled-package  # This package is temporarily disabled
```

## Platform-Specific Differences

### Package Names

The same software may have different package names:

| Software | macOS (Homebrew) | Windows (Chocolatey) | Ubuntu (APT/Snap) | Fedora (DNF/Flatpak) |
|----------|------------------|---------------------|-------------------|---------------------|
| VS Code | `visual-studio-code` | `vscode` | `code` (snap) | `com.visualstudio.code` (flatpak) |
| Node.js | `node` | `nodejs` | `nodejs` (apt) | `nodejs` (dnf) |
| Docker | `docker-desktop` | `docker-desktop` | `docker.io` (apt) | `docker-ce` (dnf) |
| Git | `git` | `git` | `git` (apt) | `git` (dnf) |

### Command Syntax

Custom commands must use platform-appropriate syntax:

```yaml
# macOS/Ubuntu (Bash)
custom_commands_user:
  - echo "Hello World"
  - mkdir -p ~/Development

# Windows (PowerShell)
custom_commands_user:
  - Write-Host "Hello World"
  - New-Item -ItemType Directory -Path ~/Development -Force
```

### File Paths

Use appropriate path separators:

```yaml
# macOS/Ubuntu
custom_script: './examples/custom_script.sh'

# Windows
custom_script: './examples/custom_script.ps1'
```

## Configuration Best Practices

### Organization

```yaml
# Group related packages together with comments
# =================================
# Version Control and Git Tools
# =================================
homebrew_formulae:
  - git
  - git-lfs
  - gh

# =================================
# Container and Orchestration Tools
# =================================
  - docker
  - kubectl
  - helm
```

### Maintenance

```yaml
# Include version comments for packages with specific requirements
homebrew_formulae:
  - terraform        # Latest stable version
  - node@18          # Specific LTS version required for project compatibility

# Document why packages are included
vscode_extensions:
  - github.copilot   # AI coding assistance for team productivity
  - ms-python.python # Python development support
```

### Security

```yaml
# Avoid hardcoding sensitive information
git_user_email: ''   # Set via command line: ./setup.sh -e "user@example.com"

# Don't include credentials in config files
custom_commands_user:
  # ❌ Don't do this
  # - aws configure set aws_access_key_id AKIA...

  # ✅ Do this instead
  - echo "Please configure AWS credentials manually: aws configure"
```

This configuration reference provides all the details needed to customize your development environment setup across all supported platforms. Use this as a comprehensive guide when creating or modifying your `vars.yaml` files.
