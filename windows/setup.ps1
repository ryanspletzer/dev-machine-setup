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

# Function to refresh the PATH environment variable
function Update-PathEnvironment {
    $machinePath = [System.Environment]::GetEnvironmentVariable("Path", "Machine")
    $userPath = [System.Environment]::GetEnvironmentVariable("Path", "User")
    $env:Path = "$machinePath;$userPath"
    return $env:Path
}

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
Update-PathEnvironment

# Install pipx using Python
if (-not (Get-Command -Name pipx -ErrorAction SilentlyContinue)) {
    Write-Output -InputObject "Installing pipx..."
    python -m pip install --user pipx
    python -m pipx ensurepath

    Update-PathEnvironment
}

# Install Ansible using pipx
if (-not (Get-Command -Name ansible -ErrorAction SilentlyContinue)) {
    Write-Output -InputObject "Installing Ansible..."
    pipx install ansible --include-deps

    # Refresh PATH to include pipx binaries
    Update-PathEnvironment

    # Get the user's AppData local directory for pipx
    $pipxBinPath = Join-Path -Path ([Environment]::GetFolderPath('LocalApplicationData')) -ChildPath 'py\Scripts'
    if (Test-Path -Path $pipxBinPath) {
        Write-Output -InputObject "Adding pipx bin directory to PATH: $pipxBinPath"
        $env:Path = "$pipxBinPath;$env:Path"
    }
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

# Ensure ansible-playbook is in the PATH
$ansiblePlaybook = Get-Command -Name ansible-playbook -ErrorAction SilentlyContinue
if (-not $ansiblePlaybook) {
    # Try to find it in common locations
    $potentialPaths = @(
        # Standard pipx location in AppData
        (Join-Path -Path ([Environment]::GetFolderPath('LocalApplicationData')) -ChildPath 'py\Scripts\ansible-playbook.exe'),
        # Legacy pipx location
        (Join-Path -Path ([Environment]::GetFolderPath('LocalApplicationData')) -ChildPath 'pipx\venvs\ansible\Scripts\ansible-playbook.exe'),
        # Python user base location
        (Join-Path -Path (python -m site --user-base) -ChildPath 'Scripts\ansible-playbook.exe')
    )

    foreach ($path in $potentialPaths) {
        if (Test-Path $path) {
            Write-Output -InputObject "Found ansible-playbook at: $path"
            $ansiblePlaybook = $path
            break
        }
    }

    if (-not $ansiblePlaybook) {
        Write-Error -Message "Could not find ansible-playbook. Please ensure it is installed and in your PATH."
        exit 1
    }
}

Write-Output -InputObject "Running Ansible playbook to set up the environment..."
& $ansiblePlaybook -i localhost, $verbosityFlag setup.yaml

Stop-Transcript
