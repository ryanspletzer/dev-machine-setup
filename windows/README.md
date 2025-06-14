# Windows Development Environment Setup

This directory contains scripts and Ansible playbooks to set up a Windows development environment.

## Steps to Bootstrap Ansible

1. Run the `bootstrap_ansible.ps1` script to install Chocolatey, Python, pipx, and Ansible:

    ```powershell
    #Requires -RunAsAdministrator
    Set-ExecutionPolicy -ExecutionPolicy Unrestricted
    ./install_prerequisites.ps1
    ```

2. Run the Ansible playbook to install tools and configure the environment:

    ```powershell
    ansible-playbook -i localhost, setup.yaml
    ```

## Tools Installed

The tools installed are listed in `spec.md` and include:

- .NET Core SDK
- .NET Framework
- .NET SDK
- AWS CLI
- AdoptOpenJDK
- Azure CLI
- Azure Data Studio
- Azure Functions Core Tools
- Bicep
- Cascadia Code
- Cascadia Code Nerd Font
- Docker
- Fiddler
- Firefox
- GnuPG
- Hack Font
- ILSpy
- Maven
- Microsoft Azure Storage Explorer
- Node.js
- Notepad++
- Office 365 ProPlus
- Packer
- Postman
- Python
- RSAT
- SQL Server Management Studio
- Serverless
- Service Bus Explorer
- Slack
- Source Code Pro
- Terraform
- Vault
- Visual Studio 2022 Enterprise
- Visual Studio Code
- Windows SDK 10
- Zoom
