# Customization Guide

This guide explains how to customize the dev-machine-setup to fit your specific development needs and preferences.

## Overview

The dev-machine-setup project is designed to be easily customizable without requiring you to modify the core scripts or fork the repository. All customization is done through configuration files and optional custom scripts.

## Customization Approaches

### 1. Configuration File Customization (Recommended)

Edit the `vars.yaml` file for your platform to modify:

- Package lists (add, remove, or change packages)
- System preferences and settings
- Git configuration
- Custom commands to run during setup

### 2. Custom Scripts

Create custom scripts that run after the main setup process for:

- Additional software installation
- Complex configuration tasks
- Integration with company-specific tools
- Personal preference settings

### 3. Example-Based Customization

Use the provided examples as starting points:

- `examples/macOS_vars.yaml` - Extended macOS configuration
- `examples/windows_vars.yaml` - Extended Windows configuration
- `examples/ubuntu_vars.yaml` - Extended Ubuntu configuration
- `examples/fedora_vars.yaml` - Extended Fedora configuration
- `examples/*_custom_script.*` - Custom script examples

## Platform-Specific Customization

### macOS Customization

#### Package Management

```yaml
# Homebrew taps (additional package repositories)
homebrew_taps:
  - hashicorp/tap        # Add Terraform, Vault, etc.
  - azure/functions      # Add Azure Functions tools

# Command-line tools and libraries
homebrew_formulae:
  - git                  # Version control
  - docker              # Containerization
  - terraform           # Infrastructure as code
  - kubectl             # Kubernetes CLI

# GUI applications
homebrew_casks:
  - visual-studio-code   # Code editor
  - docker-desktop       # Docker GUI
  - microsoft-teams      # Communication
  - 1password           # Password manager
```

#### System Preferences

```yaml
custom_commands_user:
  # Show hidden files in Finder
  - defaults write com.apple.finder AppleShowAllFiles -bool true
  # Disable the warning when changing file extensions
  - defaults write com.apple.finder FXEnableExtensionChangeWarning -bool false
  # Set trackpad tracking speed
  - defaults write -g com.apple.trackpad.scaling -float 2.0

custom_commands_elevated:
  # Commands that require sudo
  - echo "/opt/homebrew/bin/fish" | sudo tee -a /etc/shells
```

### Windows Customization

#### Package Management

```yaml
# Chocolatey packages (applications and tools)
choco_packages:
  - name: git
  - name: vscode
  - name: docker-desktop
  - name: terraform
  - name: kubernetes-cli

# PowerShell modules
powershell_modules:
  - Az.Accounts
  - AWS.Tools.Common
  - posh-git
  - PSReadLine
```

#### System Settings

```yaml
custom_commands_user:
  # Windows-specific settings
  - Set-ItemProperty -Path "HKCU:\Control Panel\Mouse" -Name MouseSpeed -Value 2
  - Set-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" -Name Hidden -Value 1

custom_commands_elevated:
  # Commands that require administrator privileges
  - Enable-WindowsOptionalFeature -Online -FeatureName Microsoft-Windows-Subsystem-Linux -NoRestart
```

### Ubuntu Customization

#### Package Management

```yaml
# APT packages (system packages and CLI tools)
apt_packages:
  - git
  - docker.io
  - curl
  - wget
  - build-essential

# Snap packages (GUI applications)
snap_packages:
  - code --classic
  - discord
  - slack --classic
```

#### System Configuration

```yaml
custom_commands_user:
  # User-level commands
  - gsettings set org.gnome.desktop.interface gtk-theme 'Adwaita-dark'
  - gsettings set org.gnome.desktop.background picture-uri 'file:///path/to/wallpaper.jpg'

custom_commands_elevated:
  # Commands that require sudo
  - sudo systemctl enable docker
  - sudo usermod -aG docker $USER
```

### Fedora Customization

#### Package Management

```yaml
# DNF packages (system packages and CLI tools)
dnf_packages:
  - git
  - docker-ce
  - curl
  - wget
  - gcc
  - make

# Flatpak packages (GUI applications)
flatpak_packages:
  - com.visualstudio.code
  - com.discordapp.Discord
  - com.slack.Slack
```

#### System Configuration

```yaml
custom_commands_user:
  # User-level commands
  - gsettings set org.gnome.desktop.interface gtk-theme 'Adwaita-dark'
  - gsettings set org.gnome.desktop.background picture-uri 'file:///path/to/wallpaper.jpg'

custom_commands_elevated:
  # Commands that require sudo
  - sudo systemctl enable docker
  - sudo usermod -aG docker $USER
```

## Common Customization Scenarios

### Adding a New Package

1. **Find the package**: Search the appropriate package manager for your desired software
2. **Determine the category**: CLI tool, GUI application, VS Code extension, etc.
3. **Add to the appropriate list** in `vars.yaml`:

```yaml
# Example: Adding a new CLI tool on macOS
homebrew_formulae:
  - git
  - docker
  - your-new-tool  # Add this line

# Example: Adding a VS Code extension (same across all platforms)
vscode_extensions:
  - github.copilot
  - ms-python.python
  - your.new-extension  # Add this line
```

### Creating Development Environment Profiles

Create different configuration files for different purposes:

```bash
# Work environment
cp vars.yaml work_vars.yaml
# Edit work_vars.yaml to include work-specific tools

# Personal environment
cp vars.yaml personal_vars.yaml
# Edit personal_vars.yaml to include personal tools

# Run with specific configuration
./setup.sh personal_vars.yaml
```

### Setting Up Team Configurations

1. **Create a shared configuration**:

```yaml
# team_vars.yaml
git_user_email: "team@company.com"
homebrew_formulae:
  - git
  - docker
  - company-cli-tool
  - terraform

vscode_extensions:
  - ms-python.python
  - hashicorp.terraform
  - company.internal-extension
```

2. **Share via version control**:

```bash
# Team members can use the shared config
git clone company-repo/dev-setup-configs
./setup.sh -e "user@company.com" team_vars.yaml
```

### Adding Custom Installation Scripts

1. **Create a custom script**:

```bash
#!/bin/bash
# custom_company_setup.sh

echo "Installing company-specific tools..."

# Install company VPN client
curl -O https://company.com/vpn-client.pkg
sudo installer -pkg vpn-client.pkg -target /

# Configure company certificates
sudo security add-trusted-cert -d -r trustRoot -k /System/Library/Keychains/SystemRootCertificates.keychain company-root.crt

echo "Company-specific setup complete!"
```

2. **Reference it in vars.yaml**:

```yaml
custom_script: "./custom_company_setup.sh"
```

### Language-Specific Setups

#### Python Development Environment

```yaml
# Enhanced Python setup
homebrew_formulae:
  - python
  - pyenv
  - poetry

pipx_packages:
  - poetry
  - black
  - flake8
  - mypy
  - pytest

vscode_extensions:
  - ms-python.python
  - ms-python.pylance
  - ms-python.black-formatter
```

#### Web Development Environment

```yaml
# Web development setup
homebrew_formulae:
  - node
  - yarn
  - nginx

homebrew_casks:
  - google-chrome
  - firefox
  - postman

npm_global_packages:
  - '@angular/cli'
  - vue-cli
  - create-react-app
  - eslint
  - prettier

vscode_extensions:
  - ms-vscode.vscode-typescript-next
  - esbenp.prettier-vscode
  - bradlc.vscode-tailwindcss
```

#### DevOps Environment

```yaml
# DevOps and cloud development
homebrew_formulae:
  - terraform
  - kubectl
  - helm
  - awscli
  - azure-cli
  - docker

homebrew_casks:
  - docker-desktop
  - lens

vscode_extensions:
  - hashicorp.terraform
  - ms-kubernetes-tools.vscode-kubernetes-tools
  - ms-azuretools.vscode-docker
```

## Advanced Customization

### Conditional Package Installation

Use custom commands to install packages based on conditions:

```yaml
custom_commands_user:
  # Install Rosetta 2 only on Apple Silicon Macs
  - |
    if [[ $(uname -m) == "arm64" ]]; then
      sudo softwareupdate --install-rosetta --agree-to-license
    fi
```

### Environment-Specific Configuration

```yaml
# Use environment variables in your setup
custom_commands_user:
  - |
    if [[ "$WORK_ENV" == "true" ]]; then
      brew install company-specific-tool
    fi
```

### Modular Configuration Files

Break large configurations into smaller, focused files:

```yaml
# Include other YAML files (requires custom scripting)
# base_vars.yaml - common packages
# work_vars.yaml - work-specific additions
# personal_vars.yaml - personal additions
```

### Custom Package Sources

Add private or custom package repositories:

```yaml
# macOS: Custom Homebrew taps
homebrew_taps:
  - company/private-tap

# Ubuntu: Custom APT repositories
custom_commands_elevated:
  - curl -fsSL https://company.com/gpg | sudo apt-key add -
  - echo "deb https://company.com/packages stable main" | sudo tee /etc/apt/sources.list.d/company.list
  - sudo apt update
```

## Testing Your Customizations

### Validation Checklist

Before running your customized setup:

1. **Syntax validation**: Ensure YAML files are valid
2. **Package availability**: Verify all packages exist in their repositories
3. **Permission requirements**: Check if custom commands need elevation
4. **Custom script permissions**: Ensure custom scripts are executable

### Safe Testing Approaches

1. **Use virtual machines**: Test configurations in VMs before applying to your main system
2. **Prerequisites-only mode**: Use the `-p` flag to test prerequisite installation
3. **Verbose mode**: Use `-v` or `-vv` flags to see detailed output during testing
4. **Incremental testing**: Add packages gradually rather than all at once

### Common Validation Commands

```bash
# Validate YAML syntax
python -c "import yaml; yaml.safe_load(open('vars.yaml'))"

# Test package availability (macOS)
brew search your-package-name

# Test package availability (Ubuntu)
apt search your-package-name

# Test package availability (Fedora)
dnf search your-package-name

# Test custom script syntax
bash -n your_custom_script.sh
```

## Troubleshooting Customizations

### Common Issues

1. **Package not found**:
   - Check package name spelling
   - Verify package exists in the repository
   - Check if package requires additional taps/repositories

2. **Permission denied**:
   - Move commands requiring elevation to `custom_commands_elevated`
   - Ensure script has executable permissions (`chmod +x`)

3. **Configuration not applied**:
   - Check YAML syntax and indentation
   - Verify custom script path is correct
   - Check log files for error messages

### Getting Help

1. **Check the logs**: All operations are logged to timestamped files
2. **Use verbose mode**: Add `-v` flags for more detailed output
3. **Review examples**: Look at the provided example configurations
4. **Test incrementally**: Add customizations gradually to isolate issues

## Best Practices

### Configuration Management

1. **Version control your configs**: Keep your customized `vars.yaml` files in version control
2. **Document your changes**: Add comments explaining why you added specific packages
3. **Keep backups**: Save working configurations before making major changes
4. **Use meaningful names**: Name custom scripts and configs descriptively

### Maintenance

1. **Regular updates**: Periodically review and update package lists
2. **Remove unused packages**: Clean up packages you no longer need
3. **Test after changes**: Always test configuration changes before deploying
4. **Share with team**: Consider sharing useful customizations with colleagues

### Security

1. **Verify package sources**: Only add packages from trusted repositories
2. **Review custom scripts**: Ensure custom scripts don't contain malicious code
3. **Minimize elevation**: Avoid using `sudo` unless absolutely necessary
4. **Keep credentials secure**: Don't hardcode secrets in configuration files

By following this guide, you can create a personalized development environment that meets your specific needs while maintaining the reliability and automation benefits of the dev-machine-setup project.
