# Windows Development Environment Setup with DSC 3.0

This directory contains scripts and DSC 3.0 configuration to set up a Windows development environment. It uses modern technologies like PowerShell 7.4+, the new DSC CLI tool, and YAML-based configuration with a template + values approach.

## Features

- **Template + Values Approach**: Separates configuration template from values for flexibility
- **Modern Configuration Management**: Uses DSC 3.0 with YAML configuration files
- **Idempotent Execution**: Can be run multiple times without causing issues
- **Advanced State Management**: Properly manages Windows features, Chocolatey packages, PowerShell modules, and more
- **Error Handling**: Robust error handling and detailed logging
- **Extensible**: Easy to customize and extend

## Prerequisites

All prerequisites are automatically installed by the setup script:

- PowerShell 7.4+ (installed via Chocolatey if needed)
- DSC 3.0 CLI tool (installed via Chocolatey)
- Required DSC resources (installed via PSResource module)

## Usage

### Quick Start

Open PowerShell as Administrator and run:

```powershell
.\setup.ps1
```

### Install Prerequisites Only

To only install prerequisites without applying the DSC configuration:

```powershell
.\setup.ps1 -PrereqsOnly
```

### Increase Verbosity

For more detailed output:

```powershell
.\setup.ps1 -Verbosity 2
```

### Force Reinstallation of Prerequisites

To force reinstallation of prerequisites:

```powershell
.\setup.ps1 -Force
```

### Specify Git User Information

To set Git user information during setup:

```powershell
.\setup.ps1 -GitUserEmail "your.email@example.com" -GitUserName "Your Name"
```

### Use Custom Template and Values Files

To use different template or values files:

```powershell
.\setup.ps1 -TemplateFile "examples\custom-template.yaml" -ValuesFile "examples\custom-values.yaml"
```

## Configuration Details

The configuration is defined in two files:

1. `setup.yaml` - Template configuration with placeholders
2. `vars.yaml` - Values to populate the template

The setup includes:

- **Windows Features**: Enables WSL, Hyper-V, and other Windows features
- **Chocolatey Packages**: Installs developer tools and applications
- **PowerShell Modules**: Installs PowerShell modules for development
- **Git Configuration**: Sets up Git user settings and preferences
- **Custom Commands**: Executes specific commands that don't fit into other categories

## Customization

You can customize the configuration by editing the `vars.yaml` file:

- Add/remove Windows features
- Add/remove Chocolatey packages
- Modify PowerShell modules
- Update Git configuration
- Add custom commands

Example `vars.yaml` structure:

```yaml
# Windows Features to enable
WindowsFeatures:
  - name: Microsoft-Windows-Subsystem-Linux
    ensure: Present
    includeAllSubFeature: true

# Chocolatey packages to install
ChocolateyPackages:
  - name: git
    ensure: Present
  - name: visualstudiocode
    ensure: Present

# PowerShell modules to install
PowerShellModules:
  - name: PSReadLine
    ensure: Present
  - name: posh-git
    ensure: Present

# Git configuration script
GitConfigScript: |
  # Git user configuration
  if (-not [string]::IsNullOrEmpty('${GitUserEmail}')) {
    git config --global user.email '${GitUserEmail}'
  }
  # ...more configuration...
```

You can also create custom template and values files in the examples directory for different scenarios.

## Troubleshooting

The setup script creates a detailed log file in the current directory with timestamps. Check this file for information about any errors.

If you encounter issues:

1. Run with `-Verbosity 3` for maximum detail
2. Check the log file for specific error messages
3. Ensure your user account has administrative privileges
4. Try running with `-Force` to reinstall prerequisites
