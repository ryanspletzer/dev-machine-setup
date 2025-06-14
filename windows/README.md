# Windows Development Environment Setup

This directory contains scripts and Ansible playbooks to set up a Windows development environment.

## Steps to Bootstrap Ansible

1. Run the `setup.ps1` script with the `-PrereqsOnly` parameter to install Chocolatey, Python, pipx, and Ansible:

    ```powershell
    #Requires -RunAsAdministrator
    Set-ExecutionPolicy -ExecutionPolicy Unrestricted
    ./setup.ps1 -PrereqsOnly
    ```

2. Run the full setup script to install tools and configure the environment:

    ```powershell
    ./setup.ps1
    ```

   Or run the Ansible playbook directly:

    ```powershell
    ansible-playbook -i localhost, setup.yaml
    ```

## Setup Script Options

The `setup.ps1` script supports several options:

```powershell
./setup.ps1 [-Verbosity <0-3>] [-PrereqsOnly]
```

- `-Verbosity`: Sets the verbosity level for Ansible (0-3)
- `-PrereqsOnly`: Only installs prerequisites without running the Ansible playbook

Examples:

```powershell
# Install prerequisites only
./setup.ps1 -PrereqsOnly

# Run with increased verbosity
./setup.ps1 -Verbosity 2
```
