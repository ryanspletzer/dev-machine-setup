#Requires -RunAsAdministrator
#Requires -Version 5.1

# Bootstrap Chocolatey, Python, pipx, and Ansible on Windows
#
# .SYNOPSIS
# Installs prerequisites and runs Ansible playbook for Windows development environment setup
#
# .PARAMETER Verbosity
# Sets the verbosity level for Ansible (0-3)
#
# .PARAMETER PrereqsOnly
# Only installs prerequisites (Chocolatey, Python, pipx, and Ansible) without running the Ansible playbook
#
# .EXAMPLE
# .\setup.ps1 -PrereqsOnly
# Installs only the prerequisites without running the Ansible playbook
#
# .EXAMPLE
# .\setup.ps1 -Verbosity 2
# Runs the complete setup with increased verbosity level for Ansible
[CmdletBinding()]
param (
    [Parameter()]
    [ValidateSet(0, 1, 2, 3)]
    [int]
    $Verbosity = 0,

    [Parameter()]
    [switch]
    $PrereqsOnly
)

Start-Transcript

# Install Chocolatey
if (-not (Get-Command -Name choco -ErrorAction SilentlyContinue)) {
    Write-Output -InputObject "Installing Chocolatey..."
    Set-ExecutionPolicy Bypass -Scope Process -Force
    [System.Net.ServicePointManager]::SecurityProtocol = [System.Net.ServicePointManager]::SecurityProtocol -bor 3072
    Invoke-Expression -Command ((New-Object System.Net.WebClient).DownloadString('https://chocolatey.org/install.ps1'))
}

# Install Python using Chocolatey
Write-Output -InputObject "Installing Python..."
choco install python -y
$env:Path = [System.Environment]::GetEnvironmentVariable("Path","Machine") + ";" + [System.Environment]::GetEnvironmentVariable("Path","User")

# Install pipx using Python
if (-not (Get-Command -Name pipx -ErrorAction SilentlyContinue)) {
    Write-Output -InputObject "Installing pipx..."
    python -m pip install --user pipx
    python -m pipx ensurepath

    $env:Path = [System.Environment]::GetEnvironmentVariable("Path","Machine") + ";" + [System.Environment]::GetEnvironmentVariable("Path","User")
}

# Install Ansible using pipx
if (-not (Get-Command -Name ansible -ErrorAction SilentlyContinue)) {
    Write-Output -InputObject "Installing Ansible..."
    pipx install ansible
}

Write-Output -InputObject "Bootstrap complete. Ansible is ready to use."

# Exit if prerequisites only mode
if ($PrereqsOnly) {
    Write-Output -InputObject "Prerequisites installation complete. Skipping Ansible playbook execution (-PrereqsOnly switch specified)."
    Stop-Transcript
    exit 0
}

# Set verbosity for Ansible based on parameter
$verbosityFlag = ""
switch ($Verbosity) {
    1 { $verbosityFlag = "-v" }
    2 { $verbosityFlag = "-vv" }
    3 { $verbosityFlag = "-vvv" }
}

if ($verbosityFlag) {
    Write-Output -InputObject "Using Ansible verbosity level: $verbosityFlag"
}

Write-Output -InputObject "Running Ansible playbook to set up the environment..."
ansible-playbook -i localhost, $verbosityFlag setup.yaml

Stop-Transcript
