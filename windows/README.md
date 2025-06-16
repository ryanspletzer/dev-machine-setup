# Windows Development Environment Setup with WinGet Configure

This directory contains scripts and WinGet configuration to set up a Windows development environment. It uses modern technologies like PowerShell, WinGet Configure, and Chocolatey for package management.

## Features

- **Parameterized Approach**: Uses vars.yaml to dynamically generate the WinGet configuration
- **Modern Configuration Management**: Uses WinGet Configure with YAML configuration files
- **Idempotent Execution**: Can be run multiple times without causing issues
- **Advanced State Management**: Properly manages Windows features, Chocolatey packages, PowerShell modules, and more
- **Error Handling**: Robust error handling and detailed logging
- **Extensible**: Easy to customize and extend

## Prerequisites

All prerequisites are automatically installed by the setup script:

- WinGet (installed if not already present)
- PowerShell YAML module (for processing the vars.yaml file)
- Chocolatey (installed by the configuration)
- PowerShell 7 (installed via WinGet)

## Usage

### Quick Start

Open PowerShell as Administrator and run:

```powershell
.\setup.ps1
```

### Validate Configuration Only

To only validate the configuration without applying it:

```powershell
.\setup.ps1 -ValidateOnly
```

### Force Unattended Installation

To run the installation in unattended mode:

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

The `setup.ps1` script:

1. Installs WinGet if not already present
2. Installs the PowerShell YAML module if needed
3. Reads `vars.yaml` to get the configuration values
4. Dynamically generates `config.yaml` for WinGet Configure
5. Applies the configuration using `winget configure`

The generated `config.yaml` file follows the WinGet Configuration schema and includes:

- Windows Features configuration
- Chocolatey installation script
- PowerShell modules installation
- Git configuration

## Troubleshooting

### Common Issues

- **WinGet Not Found**: Ensure Microsoft.DesktopAppInstaller is installed from the Microsoft Store
- **Access Denied Errors**: Make sure you're running PowerShell as Administrator
- **Chocolatey Installation Fails**: Check your internet connection or proxy settings
- **Configuration Validation Fails**: Check the log file for details on the specific errors

### Logs

The script generates a log file (`setup_YYYYMMDD_HHMMSS.log`) in the current directory with detailed information about the setup process.

## Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

## License

See the LICENSE file in the root of this repository.
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

# Windows Developer Machine Setup

This directory contains DSC 3.0 configuration files for setting up a Windows developer machine.

## How to Use

1. Customize the `vars.yaml` file with your desired configuration:
   - Windows Features
   - Chocolatey packages
   - PowerShell modules
   - Git configuration
   - Custom commands

2. Generate the DSC configuration file by running:
   ```powershell
   Import-Module powershell-yaml
   ./Generate-DscConfig.ps1
   ```

3. Apply the configuration using DSC:
   ```powershell
   # Install DSC v3 if you don't have it yet
   Install-Module Microsoft.DSC -AllowPrerelease

   # Apply the configuration
   Start-DscConfiguration -Path ./setup.yaml
   ```

## Configuration Components

- **Windows Features**: Enable Windows components like WSL, Hyper-V, etc.
- **Chocolatey Packages**: Install development tools and applications
- **PowerShell Modules**: Install PowerShell modules for development
- **Git Configuration**: Set up Git with your preferred settings
- **Custom Commands**: Run additional setup steps

## Customization

To customize Git settings, uncomment and set the `GitUserEmail` and `GitUserName` variables in `vars.yaml`.

## Requirements

- Windows 10/11
- PowerShell 7+
- [DSC v3](https://learn.microsoft.com/en-us/powershell/dsc/concepts/dsc3-overview)
- PowerShell-YAML module (`Install-Module powershell-yaml -Scope CurrentUser`)
