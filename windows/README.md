# Windows Development Machine Setup

This directory contains scripts and configuration files to automate the setup of a Windows development environment using PowerShell and various package managers.

## Overview

The setup script (`setup.ps1`) automates the installation and configuration of:

- [Chocolatey](https://chocolatey.org/) packages (applications and tools)
- [PowerShell](https://github.com/PowerShell/PowerShell) modules (via PSResourceGet)
- Windows PowerShell modules (via PowerShellGet)
- [pipx](https://pypa.github.io/pipx/) packages (Python tools)
- [Visual Studio Code](https://code.visualstudio.com/) extensions
- Git configuration
- System preferences and Windows features

## Prerequisites

- Windows 11
- Administrative privileges
- PowerShell 5.1 or higher (comes with Windows 11)
- Internet connection

## Quick Start

1. Clone this repository or download the files
2. Open Windows PowerShell as Administrator
3. Navigate to the `windows` directory
4. Run the setup script:

```powershell
.\setup.ps1
```

## Configuration

The setup is driven by the `vars.yaml` file, which contains configurable options for:

### Chocolatey Packages

Applications and tools installed via Chocolatey. Each entry has:

- `name`: Package name (required)
- `parameters`: Optional installation parameters (e.g., `/WindowsTerminal`)
- `prerelease`: Optional boolean to allow prerelease versions

```yaml
choco_packages:
  - name: git
    parameters: /WindowsTerminal /NoShellIntegration
  - name: vscode
  # etc.
```

### PowerShell Modules

PowerShell modules installed via PSResourceGet in PowerShell 7+ (pwsh):

```yaml
powershell_modules:
  - AWS.Tools.Common
  - Terminal-Icons
  # etc.
```

> **Note**: Some modules like `Pester` are pre-installed with Windows PowerShell. If you need to install a newer version, you might need to use `-SkipPublisherCheck` when installing manually.
>
### Windows PowerShell Modules

Legacy modules to install in Windows PowerShell 5.1 (if needed):

```yaml
windows_powershell_modules:
  # - AWS.Tools.Common
  # etc.
```

### pipx Packages

Python tools installed in isolated environments:

```yaml
pipx_packages:
  - cfn-lint
  - poetry
  # etc.
```

### Visual Studio Code Extensions

Extensions to install in VS Code:

```yaml
vscode_extensions:
  - ms-vscode.powershell
  - github.copilot
  # etc.
```

### Git Configuration

Git user settings:

```yaml
git_user_email: 'your.email@example.com'
git_user_name: 'Your Name'
```

### Custom Commands

PowerShell commands to execute after setup:

```yaml
custom_commands:
  - Write-Output "Enabling dark mode..."
  - Set-ItemProperty -Path HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Themes\Personalize -Name SystemUsesLightTheme -Value 0
  # etc.
```

### Custom Script

An optional script to run at the end of setup:

```yaml
custom_script: "./examples/custom_script.ps1"
```

## Advanced Usage

### Running with Specific Options

```powershell
.\setup.ps1
```

### Passing Git Configuration Values

If you don't want to store your Git credentials in the vars.yaml file, you can set them via environment variables:

```powershell
$env:GIT_USER_EMAIL = "your.email@example.com"
$env:GIT_USER_NAME = "Your Name"
.\setup.ps1
```

## Customization

### Adding Packages

To add more packages, edit the `vars.yaml` file and add entries to the appropriate sections.

### Custom Scripts

For more complex customizations, create a script in the `examples` directory and reference it in the `custom_script` section of `vars.yaml`.

### Path Environment Variable Warning

When installing PowerShell modules, you might see a warning like:

```text
WARNING: The installation path for the script does not currently appear in the CurrentUser path environment variable.
To make the script discoverable, add the script installation path, C:\Users\username\Documents\PowerShell\Modules, to the environment PATH variable.
```

This warning is informational and doesn't prevent the modules from being used within PowerShell. It only means that executable scripts within the modules won't be directly callable from the command line without specifying their full path. Add the suggested path to your environment variables if you need this functionality.

## Troubleshooting

### Windows Features

Some Windows features require a system restart to take effect:

```powershell
Enable-WindowsOptionalFeature -FeatureName Microsoft-Windows-Subsystem-Linux -Online -NoRestart
```

After running the script, consider restarting your system to ensure all changes take effect.

## License

See the [LICENSE](../LICENSE) file in the root directory for details.
