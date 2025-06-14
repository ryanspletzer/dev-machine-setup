#Requires -RunAsAdministrator
#Requires -Version 5.1

# Bootstrap Chocolatey, Python, pipx, and Ansible on Windows
[CmdletBinding()]
param()

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

Stop-Transcript

# TODO: simply this by removing this script and just adding an -install-prerequisites option to the main script
