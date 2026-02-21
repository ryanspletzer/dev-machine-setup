# Windows Development Machine Setup

This directory contains scripts and configuration files to automate the setup of a Windows development environment using
PowerShell and various package managers.

## Overview

The setup script (`setup.ps1`) automates the installation and configuration of:

- [Chocolatey](https://chocolatey.org/) packages (applications and tools)
- [PowerShell](https://github.com/PowerShell/PowerShell) modules (via PSResourceGet)
- Windows PowerShell modules (via PowerShellGet)
- [pipx](https://pypa.github.io/pipx/) packages (Python tools)
- [npm](https://www.npmjs.com/) global packages (Node.js tools)
- [.NET Global Tools](https://docs.microsoft.com/en-us/dotnet/core/tools/global-tools) (when .NET SDK is available)
- [Visual Studio Code](https://code.visualstudio.com/) extensions
- Git configuration
- System preferences and Windows features

## Prerequisites

- Windows 11
- Administrative privileges
- PowerShell 5.1 or higher (comes with Windows 11)
- Internet connection

## Quick Start

1. Clone this repository or download the repository contents
2. Open Windows PowerShell as Administrator
3. Navigate to the `windows` directory
4. Run the setup script:

```powershell
# Clone the repository if you haven't already
git clone https://github.com/ryanspletzer/dev-machine-setup.git
cd dev-machine-setup/windows

# Or copy the contents of the windows directory to somewhere like ~/Downloads if you don't have git installed yet
# cd ~/Downloads

# Change the PowerShell Execution Policy
# Note this is _not_ a security boundary, so don't worry...
# See this for more info:
# https://learn.microsoft.com/en-us/powershell/module/microsoft.powershell.core/about/about_execution_policies
Set-ExecutionPolicy -ExecutionPolicy Unrestricted -Force

# Run the script
.\setup.ps1 -e your.email@example.com
```

Email is for the git user.email config.

The script also sets git user.name and it can be provided as shown below -- - if no name is provided, the script will
try to use the output of `(Get-LocalUser -Name $env:USERNAME).FullName` to pull the user's full name from the local
Windows user information (as long as it is not empty -- if it is the script will stop).

```powershell
# Provide your name for git user.name config if you know your proper full name isn't set for your local windows user
.\setup.ps1 -e your.email@example.com -n 'Your Name'
```

## Notable Default Packages

The default setup includes a curated selection of popular development tools and applications:

### Developer Tools

- Docker
- Git and Git LFS
- Visual Studio Code
- .NET SDK and .NET Framework
- Python, Node.js, Go, Rust
- AWS CLI, Azure CLI, Terraform, Packer, Vault
- PowerShell 7+
- Global npm packages (AWS CDK, npmrc)
- .NET global tools (Amazon Lambda Tools)

### Applications

- 1Password
- Microsoft Office 365 Business
- Slack
- Zoom
- SQL Server Management Studio
- Microsoft Azure Storage Explorer

See `vars.yaml` for the complete list of installed packages.

## Configuration

The setup is driven by the `vars.yaml` file, which contains configurable options for the following items below.

### Make It Your Own

_**It is encourage to take the vars.yaml file and customize it to your needs!**_

There are many common items in there that are desirable for dev machine setup, but each person is different and will
want to cater their own `vars.yaml` file to their needs.

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

> **Note**: Some modules like `Pester` are pre-installed with Windows PowerShell. If you need to install a newer
> version, you might need to use `-SkipPublisherCheck` when installing manually.
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

### npm Global Packages

Node.js packages installed globally:

```yaml
npm_global_packages:
  - aws-cdk
  - npmrc
  # etc.
```

### .NET Global Tools

.NET global tools to install (requires .NET SDK):

```yaml
dotnet_tools:
  - Amazon.Lambda.Tools
  # etc.
```

> **Note**: .NET global tools are only installed if the .NET SDK is available on the system. The setup script will
> automatically detect if `dotnet` command is available and skip this section if not found.

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

## 📚 Additional Resources

For comprehensive documentation and examples:

- [Complete Documentation](../docs/README.md) - Full project documentation
- [Design Principles](../docs/design-principles.md) - Understanding the philosophy
- [Troubleshooting Guide](../docs/troubleshooting.md) - Common issues and solutions
- [Architecture Overview](../docs/architecture.md) - How all the pieces fit together
- [Package Management Strategy](../docs/package-management.md) - Our approach to managing packages

## Advanced Usage

### Running with Specific Options

```powershell
.\setup.ps1
```

### Passing Git Configuration Values

If you don't want to store your Git user email/name in the vars.yaml file, you can set them via command line arguments:

```powershell
.\setup.ps1 -e your.email@example.com -n 'Your Name'
```

## Customization

### Adding Packages

To add more packages, edit the `vars.yaml` file and add entries to the appropriate sections.

### Custom Scripts

For more complex customizations, create a script in the `examples` directory and reference it in the `custom_script`
section of `vars.yaml`.

### Path Environment Variable Warning

When installing PowerShell modules, you might see a warning like:

```text
WARNING: The installation path for the script does not currently appear in the CurrentUser path environment variable.
To make the script discoverable, add the script installation path, C:\Users\username\Documents\PowerShell\Modules, to
the environment PATH variable.
```

This warning is informational and doesn't prevent the modules from being used within PowerShell. It only means that
executable scripts within the modules won't be directly callable from the command line without specifying their full
path. Add the suggested path to your environment variables if you need this functionality.

## Troubleshooting

### Windows Features

Some Windows features require a system restart to take effect:

```powershell
Enable-WindowsOptionalFeature -FeatureName Microsoft-Windows-Subsystem-Linux -Online -NoRestart
```

After running the script, consider restarting your system to ensure all changes take effect.
