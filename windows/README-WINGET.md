# Windows Development Environment Setup with WinGet Configure

This directory contains scripts and configuration files to set up a Windows development environment using WinGet Configure. It leverages modern Windows tools while still using Chocolatey as the primary package manager.

## Features

- **Declarative Configuration**: Uses WinGet Configure for a declarative approach to system configuration
- **Dynamic Configuration Generation**: Uses vars.yaml as a parameter file to dynamically generate the WinGet configuration
- **Chocolatey Integration**: Installs and uses Chocolatey for package management
- **PowerShell Modules**: Installs PowerShell modules for development
- **Windows Features**: Enables Windows features like WSL
- **Git Configuration**: Sets up Git with your preferred settings
- **Idempotent Execution**: Can be run multiple times without causing issues
- **Error Handling**: Robust error handling and detailed logging

## Prerequisites

The script will automatically check for and install the necessary prerequisites:

- WinGet CLI (will be installed if not present)
- PowerShell YAML module (for processing vars.yaml)
- Internet connection for downloading packages

## Usage

### Quick Start

Open PowerShell as Administrator and run:

```powershell
.\setup.ps1
```

### Validate Configuration Only

To validate the configuration file without applying changes:

```powershell
.\setup.ps1 -ValidateOnly
```

### Force Configuration Application

To force configuration application without prompts:

```powershell
.\setup.ps1 -Force
```

### Specify Git User Information

To set Git user information during setup:

```powershell
.\setup.ps1 -GitUserEmail "your.email@example.com" -GitUserName "Your Name"
```

### Use Custom Variables File

To use a different variables file:

```powershell
.\setup.ps1 -VarsFile "examples\custom-vars.yaml"
```

## Configuration Details

The configuration is defined in two files:

1. `vars.yaml` - Contains all the customizable values
2. `config.yaml` - Dynamically generated from vars.yaml by the setup script

The setup includes:

- **Windows Features**: Enables WSL and other Windows features
- **Chocolatey Packages**: Installs developer tools and applications via Chocolatey
- **PowerShell Modules**: Installs PowerShell modules for development
- **Git Configuration**: Sets up Git user settings and preferences

## Customization

You can customize the configuration by editing the `vars.yaml` file:

- Add/remove Windows features
- Add/remove Chocolatey packages
- Modify PowerShell modules
- Update Git configuration

Example `vars.yaml` structure:

```yaml
# Windows Features to enable
WindowsFeatures:
  - Name: Microsoft-Windows-Subsystem-Linux
  - Name: VirtualMachinePlatform

# Chocolatey packages to install
ChocolateyPackages:
  - Name: git
    params: "/WindowsTerminal /NoShellIntegration"
  - Name: vscode
  - Name: nodejs

# PowerShell modules to install
PowerShellModules:
  - Name: PSReadLine
  - Name: posh-git

# Git configuration script
GitConfigScript: |
  # Set Git user email if provided
  if ($env:GIT_USER_EMAIL) {
    git config --global user.email $env:GIT_USER_EMAIL
  }

  # Set Git user name if provided
  if ($env:GIT_USER_NAME) {
    git config --global user.name $env:GIT_USER_NAME
  }
```

## How It Works

The setup process follows these steps:

1. Checks for and installs WinGet if needed
2. Installs the PowerShell YAML module if needed
3. Reads `vars.yaml` to get the configuration values
4. Dynamically generates `config.yaml` for WinGet Configure
5. Sets network profiles to Private (required for WinRM)
6. Configures WinRM for remote management
7. Applies the WinGet configuration file using `winget configure`

The generated configuration file:
- Installs Windows features
- Installs Chocolatey
- Installs PowerShell 7
- Installs developer tools via Chocolatey
- Installs PowerShell modules
- Configures Git

## Troubleshooting

The setup script creates a detailed log file in the current directory with timestamps. Check this file for information about any errors.

If you encounter issues:

1. Run with `-ValidateOnly` to check the configuration file for errors
2. Check the log file for specific error messages
3. Ensure your user account has administrative privileges
4. Try running with `-Force` to skip interactive prompts

## Why WinGet Configure?

WinGet Configure provides several advantages over DSC 3.0 for developer machine setup:

1. **Native Windows Tool**: Built into recent versions of Windows
2. **Simpler Schema**: More straightforward configuration syntax
3. **Better Stability**: Fewer compatibility issues with Windows features
4. **PowerShell Integration**: Can execute PowerShell scripts as part of configuration
5. **Idempotent Operations**: Only makes necessary changes when run multiple times
