# Dev Machine Setup

A collection of automated scripts and configurations to set up consistent development environments across macOS and
Windows platforms.
This repository helps you quickly configure a new development machine with common tools, applications, and settings used
by developers.

## 🚀 Features

- **Cross-Platform Support**: Setup scripts for both [macOS](./macOS/README.md) and [Windows](./windows/README.md)
- **Package Management**: Install common developer tools and applications
- **Editor Configuration**: Set up Visual Studio Code with essential extensions
- **Shell Configuration**: Configure PowerShell with useful modules
- **System Preferences**: Apply developer-friendly system settings
- **Customization**: Easily customize the installation to fit your needs

## 📋 Quick Links

- [macOS Setup](./macOS/README.md) - Set up a macOS development environment
- [Windows Setup](./windows/README.md) - Set up a Windows development environment

## 🔧 Overview

This repository is designed to help developers quickly set up new machines with a consistent development environment.
It automates the installation of common tools, applications, and configurations that developers use daily.

The setup is platform-specific but provides a similar set of tools across both macOS and Windows:

### Common Tools Installed

- **Version Control**: Git, Git LFS
- **Editors & IDEs**: Visual Studio Code with extensions
- **Package Managers**: Homebrew (macOS), Chocolatey (Windows)
- **Languages & Runtimes**: Python, Node.js, .NET SDK, etc.
- **Cloud Tools**: AWS CLI, Azure CLI, Terraform, etc.
- **Containers**: Docker
- **Shell Enhancements**: PowerShell modules, Terminal customizations

## 🚀 Getting Started

### macOS

1. Clone this repository
2. Navigate to the `macOS` directory
3. Run the setup script:

```bash
./setup.sh -e "your.email@example.com"
```

[Detailed macOS Setup Instructions](./macOS/README.md)

### Windows

1. Clone this repository
2. Open PowerShell as Administrator
3. Navigate to the `windows` directory
4. Run the setup script:

```powershell
.\setup.ps1 -e your.email@example.com
```

[Detailed Windows Setup Instructions](./windows/README.md)

## ⚙️ Customization

Both platforms support customization through their respective configuration files:

- **macOS**: Edit `macOS/vars.yaml` to customize the Ansible playbook
- **Windows**: Edit `windows/vars.yaml` to customize the PowerShell script

You can add or remove packages, change system preferences, and even add custom scripts to run at the end of the setup
process.

## 🙏 Acknowledgments

- [Ansible](https://www.ansible.com/) for the macOS automation
- [PowerShell](https://github.com/PowerShell/PowerShell) for the Windows automation
- [Homebrew](https://brew.sh/) and [Chocolatey](https://chocolatey.org/) for package management
- All the developers who maintain the tools and applications installed by these scripts
