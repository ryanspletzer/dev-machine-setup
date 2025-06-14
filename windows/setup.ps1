#Requires -RunAsAdministrator
#Requires -Version 5.1

# Modern Windows Developer Machine Setup with DSC 3.0
# This script bootstraps a Windows development environment using:
# - PowerShell 7.5+ from Chocolatey
# - DSC 3.0 with YAML configuration
# - PowerShell modules from PSGallery using PSResource

[CmdletBinding()]
param (
    [Parameter()]
    [switch]
    $DscVerbose,

    [Parameter()]
    [switch]
    $PrereqsOnly,

    [Parameter()]
    [switch]
    $Force,

    [Parameter()]
    [string]
    $GitUserEmail,

    [Parameter()]
    [string]
    $GitUserName,

    [Parameter()]
    [string]
    $TemplateFile = "setup.yaml",

    [Parameter()]
    [string]
    $ValuesFile = "vars.yaml"
)

# Function to refresh the PATH environment variable
function Update-PathEnvironment {
    $machinePath = [System.Environment]::GetEnvironmentVariable("Path", "Machine")
    $userPath = [System.Environment]::GetEnvironmentVariable("Path", "User")
    $env:Path = "$machinePath;$userPath"
    return $env:Path
}

# Define the transcript file path
$transcriptFile = "setup_$(Get-Date -Format 'yyyyMMdd_HHmmss').log"
Start-Transcript -Path $transcriptFile

# Function to output messages with timestamps and log level
function Write-Log {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory)]
        [string]$Message,

        [Parameter()]
        [ValidateSet('INFO', 'WARNING', 'ERROR')]
        [string]$Level = 'INFO'
    )

    $timestamp = Get-Date -Format 'yyyy-MM-dd HH:mm:ss'
    $formattedMessage = "[$timestamp] [$Level] $Message"

    switch ($Level) {
        'INFO' { Write-Host $formattedMessage -ForegroundColor Cyan }
        'WARNING' { Write-Host $formattedMessage -ForegroundColor Yellow }
        'ERROR' { Write-Host $formattedMessage -ForegroundColor Red }
    }
}

#region Install Prerequisites

# Install Chocolatey if not already installed
if (-not (Get-Command -Name choco -ErrorAction SilentlyContinue)) {
    Write-Log "Installing Chocolatey..."
    Set-ExecutionPolicy Bypass -Scope Process -Force
    [System.Net.ServicePointManager]::SecurityProtocol = [System.Net.ServicePointManager]::SecurityProtocol -bor 3072
    Invoke-Expression -Command ((New-Object System.Net.WebClient).DownloadString('https://chocolatey.org/install.ps1'))
    Update-PathEnvironment
}

# Install Python using Chocolatey
Write-Log "Installing Python..."
choco install python -y
Update-PathEnvironment

# Install pipx using Python
if (-not (Get-Command -Name pipx -ErrorAction SilentlyContinue)) {
    Write-Log "Installing pipx..."
    python -m pip install --user pipx
    python -m pipx ensurepath

    Update-PathEnvironment
}

# Install PowerShell 7.4+ if not already installed or if Force is specified
$pwshInstalled = $false
$pwsh = Get-Command -Name pwsh -ErrorAction SilentlyContinue
if ($pwsh) {
    $pwshVersion = & pwsh -NoProfile -Command '$PSVersionTable.PSVersion.ToString()'
    $pwshMajor = $pwshVersion.Split('.')[0]
    $pwshMinor = $pwshVersion.Split('.')[1]

    if ([int]$pwshMajor -ge 7 -and [int]$pwshMinor -ge 4) {
        $pwshInstalled = $true
        Write-Log "PowerShell $pwshVersion already installed."
    }
}

if (-not $pwshInstalled -or $Force) {
    Write-Log "Installing PowerShell 7.4+ using Chocolatey..."
    choco install powershell-core -y --no-progress
    Update-PathEnvironment
}

# Install Microsoft.DSC and dsc CLI
if (-not (Get-Command -Name dsc -ErrorAction SilentlyContinue) -or $Force) {
    Write-Log "Installing DSC CLI tool using Chocolatey..."
    choco install dsc -y --no-progress
    Update-PathEnvironment
}

# Install PSResource module if not already installed
$psresourceModule = Get-Module -ListAvailable -Name Microsoft.PowerShell.PSResourceGet -ErrorAction SilentlyContinue
if (-not $psresourceModule -or $Force) {
    Write-Log "Installing PSResource module..."
    if (-not (Get-Module -ListAvailable -Name PowerShellGet -ErrorAction SilentlyContinue)) {
        Install-Module -Name PowerShellGet -Force -AllowClobber -Scope CurrentUser
    }
    Install-Module -Name Microsoft.PowerShell.PSResource -Force -AllowClobber -Scope CurrentUser
}

# Check if we need to install or update required DSC resources
$requiredModules = @(
    @{ Name = 'Microsoft.DSC.Core'; MinimumVersion = '0.1.0' },
    @{ Name = 'PSDesiredStateConfiguration'; MinimumVersion = '2.0.7' },
    @{ Name = 'ChocolateyDsc'; MinimumVersion = '1.0.0' },
    @{ Name = 'ComputerManagementDsc'; MinimumVersion = '9.0.0' },
    @{ Name = 'WindowsFeaturesDsc'; MinimumVersion = '1.0.0' }
)

Write-Log "Installing required DSC resources..."
foreach ($module in $requiredModules) {
    Write-Log "  Installing $($module.Name) (minimum version: $($module.MinimumVersion))..."
    # Use pwsh to ensure we're using PowerShell 7+
    & pwsh -NoProfile -Command "Install-PSResource -Name $($module.Name) -MinimumVersion $($module.MinimumVersion) -TrustRepository -Scope CurrentUser" -ErrorAction SilentlyContinue
    if ($LASTEXITCODE -ne 0) {
        Write-Log "Warning: Failed to install $($module.Name) using Install-PSResource. Trying Install-Module..." -Level WARNING
        & pwsh -NoProfile -Command "Install-Module -Name $($module.Name) -MinimumVersion $($module.MinimumVersion) -Force -AllowClobber -Scope CurrentUser" -ErrorAction SilentlyContinue
    }
}

Write-Log "Prerequisites installation complete."

# Exit if prerequisites only mode
if ($PrereqsOnly) {
    Write-Log "Skipping DSC configuration application (-PrereqsOnly switch specified)."
    Stop-Transcript
    exit 0
}

#region Generate and Apply DSC Configuration

# Install powershell-yaml module if not already installed
if (-not (Get-Module -Name powershell-yaml -ListAvailable)) {
    Write-Log "Installing powershell-yaml module..."
    Install-Module -Name powershell-yaml -Force -Scope CurrentUser
}
Import-Module powershell-yaml

# Define paths
$templatePath = Join-Path -Path $PSScriptRoot -ChildPath $TemplateFile
$valuesPath = Join-Path -Path $PSScriptRoot -ChildPath $ValuesFile
$dscConfigPath = Join-Path -Path $PSScriptRoot -ChildPath "dscconfig.yaml"

Write-Log "Generating DSC configuration from template and values..."
try {
    # Read template and values files
    $templateContent = Get-Content -Path $templatePath -Raw
    $valuesContent = Get-Content -Path $valuesPath -Raw

    # Convert values YAML to PowerShell object
    $values = ConvertFrom-Yaml -Yaml $valuesContent

    # Replace variables in template with values
    $configContent = $templateContent

    # Process variables by type
    foreach ($key in $values.Keys) {
        $value = $values[$key]

        # Handle array/collection values specially
        if ($value -is [System.Collections.IEnumerable] -and -not ($value -is [string])) {
            if ($key -eq "CustomCommands" -or $key -eq "GitConfigScript") {
                # For script blocks, join with newlines
                $joined = ($value -join "`r`n")
                $configContent = $configContent -replace "\$\{$key\}", $joined
            }
            else {
                # Convert array to YAML format
                $valueYaml = ConvertTo-Yaml -Data $value -OutFile $null
                $configContent = $configContent -replace "\$\{$key\}", $valueYaml
            }
        }
        else {
            # Handle simple string replacement
            $configContent = $configContent -replace "\$\{$key\}", $value
        }
    }

    # Special handling for git user details
    $configContent = $configContent -replace '\$\{GitUserEmail\}', $GitUserEmail
    $configContent = $configContent -replace '\$\{GitUserName\}', $GitUserName

    # Write the generated configuration to file
    $configContent | Set-Content -Path $dscConfigPath -Force
    Write-Log "DSC configuration generated successfully at $dscConfigPath"
}
catch {
    Write-Log "Error generating DSC configuration: $_" -Level ERROR
    exit 1
}

# Set verbosity for DSC based on parameter
$verbosityFlag = if ($DscVerbose) { "--verbose" } else { "" }

# Apply DSC configuration using the dsc CLI tool
Write-Log "Applying DSC configuration from dscconfig.yaml..."
try {
    if ($verbosityFlag) {
        & pwsh -NoProfile -Command "dsc config apply $dscConfigPath $verbosityFlag"
    }
    else {
        & pwsh -NoProfile -Command "dsc config apply $dscConfigPath"
    }

    if ($LASTEXITCODE -ne 0) {
        Write-Log "Error applying DSC configuration. Exit code: $LASTEXITCODE" -Level ERROR
        exit $LASTEXITCODE
    }

    Write-Log "DSC configuration applied successfully."
}
catch {
    Write-Log "Error applying DSC configuration: $_" -Level ERROR
    exit 1
}

Write-Log "Setup complete."
Stop-Transcript

Write-Host "`nSetup completed successfully!" -ForegroundColor Green
Write-Host "Full log available at: $transcriptFile" -ForegroundColor Green
