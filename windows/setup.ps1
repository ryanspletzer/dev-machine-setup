#Requires -RunAsAdministrator
#Requires -Version 5.1
# Modern Windows Developer Machine Setup with DSC 3.0
# This script bootstraps a Windows development environment using:
# - PowerShell (pwsh) from Chocolatey
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
    $VarsFile = "vars.yaml"
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

# We'll use built-in PowerShell cmdlets for logging:
# - Write-Output for standard information
# - Write-Verbose for detailed information
# - Write-Warning for warnings
# - Write-Error for errors

#region Install Prerequisites

# Install Chocolatey if not already installed
if (-not (Get-Command -Name choco -ErrorAction SilentlyContinue)) {
    Write-Output -InputObject "Installing Chocolatey..."
    Set-ExecutionPolicy -ExecutionPolicy Bypass -Scope Process -Force
    [System.Net.ServicePointManager]::SecurityProtocol = [System.Net.ServicePointManager]::SecurityProtocol -bor 3072
    Invoke-Expression -Command ((New-Object -TypeName System.Net.WebClient).DownloadString('https://chocolatey.org/install.ps1'))
    Update-PathEnvironment
}


# Install PowerShell 7.4+ if not already installed or if Force is specified
if (-not (Get-Command -Name pwsh -ErrorAction SilentlyContinue)) {
    Write-Output -InputObject "Installing PowerShell (pwsh) using Chocolatey..."
    choco install pwsh -yes --no-progress
    Update-PathEnvironment
}

# Install Microsoft.DSC and dsc CLI
if (-not (Get-Command -Name dsc -ErrorAction SilentlyContinue)) {
    Write-Output -InputObject "Installing DSC CLI tool using Chocolatey..."
    choco install dsc -yes --no-progress
    Update-PathEnvironment
}

# Check if we need to install or update required DSC resources
$requiredModules = @(
    @{ Name = 'PSDesiredStateConfiguration'; Version = '2.0.7' },
    @{ Name = 'ChocolateyDsc'; Version = '1.0.0' },
    @{ Name = 'ComputerManagementDsc'; Version = '10.0.0' }
)

Write-Output -InputObject "Installing required DSC resources..."
foreach ($module in $requiredModules) {
    Write-Verbose -Message "Installing $($module.Name) (required version: $($module.Version))..."
    # Use pwsh to ensure we're using PowerShell 7+
    & pwsh -NoProfile -Command "Install-PSResource -Name $($module.Name) -Version $($module.Version) -TrustRepository -Scope CurrentUser" -ErrorAction SilentlyContinue
}

Write-Output -InputObject "Prerequisites installation complete."

# Exit if prerequisites only mode
if ($PrereqsOnly) {
    Write-Output -InputObject "Skipping DSC configuration application (-PrereqsOnly switch specified)."
    Stop-Transcript
    exit 0
}

#endregion Install Prerequisites

#region Generate and Apply DSC Configuration

# Install powershell-yaml module if not already installed
if (-not (Get-Module -Name powershell-yaml -ListAvailable)) {
    Write-Output -InputObject "Installing powershell-yaml module..."
    Install-PackageProvider -Name NuGet -MinimumVersion 2.8.5.201 -Force
    Set-PackageSource -Name PSGallery -Trusted
    Install-Module -Name powershell-yaml -Force -Scope CurrentUser
}
Import-Module -Name powershell-yaml

# Define paths
$varsPath = Join-Path -Path $PSScriptRoot -ChildPath $VarsFile

# Load variables from vars.yaml
Write-Output -InputObject "Loading configuration from $varsPath..."
$vars = ConvertFrom-Yaml -Yaml (Get-Content -Path $varsPath -Raw)

# Create the base configuration object
$dscConfig = @{
    version = "1.0.0"
    name = "WindowsDevMachineSetup"
    '$schema' = "https://aka.ms/dsc/schemas/v3/bundled/config/document.json"
    resources = @(
        @{
            name = "Windows_Features"
            type = "WindowsFeature"
            properties = $vars.WindowsFeatures
        },
        @{
            name = "ChocolateyPackages"
            type = "ChocolateyPackage"
            properties = $vars.ChocolateyPackages
        },
        @{
            name = "PowerShellModules"
            type = "PSModuleResource"
            properties = $vars.PowerShellModules
        }
    )
}

# Optionally add Git configuration if values are provided
if ($vars.ContainsKey('GitUserEmail') -and $vars.ContainsKey('GitUserName')) {
    $gitResource = @{
        name = "GitConfig"
        type = "Script"
        properties = @{
            getScript = @'
$gitEmail = git config --global --get user.email
$gitName = git config --global --get user.name
return @{
    Result = "Git configuration: Email=$gitEmail, Name=$gitName"
}
'@
            testScript = @'
$gitEmail = git config --global --get user.email
$gitName = git config --global --get user.name
$emailConfigured = -not [string]::IsNullOrEmpty($gitEmail)
$nameConfigured = -not [string]::IsNullOrEmpty($gitName)
return $emailConfigured -and $nameConfigured
'@
            setScript = $vars.GitConfigScript.Replace('${GitUserEmail}', $vars.GitUserEmail).Replace('${GitUserName}', $vars.GitUserName)
        }
    }
    $dscConfig.resources += $gitResource
}

# Optionally add custom commands
if ($vars.ContainsKey('CustomCommands')) {
    $customCommandsResource = @{
        name = "CustomCommands"
        type = "Script"
        properties = @{
            getScript = @'
return @{
    Result = "Custom commands execution status"
}
'@
            testScript = @'
# Always return false to ensure the setScript runs
return $false
'@
            setScript = $vars.CustomCommands
        }
    }
    $dscConfig.resources += $customCommandsResource
}

# Convert to YAML
$yamlContent = $dscConfig | ConvertTo-Yaml

# Add a header comment
$headerComment = @"
# DSC 3.0 configuration for Windows developer machine setup
# This file is automatically generated - do not edit directly
# Generated on: $(Get-Date -Format "yyyy-MM-dd HH:mm:ss")
# Source: vars.yaml

"@

# Combine header and YAML content
$finalYamlContent = $headerComment + $yamlContent

# Write to setup.yaml
$setupPath = Join-Path $PSScriptRoot "setup.yaml"
$finalYamlContent | Out-File -FilePath $setupPath -Encoding utf8 -Force

Write-Host "DSC configuration has been generated at: $setupPath"

# Set verbosity for DSC based on parameter
$verbosityFlag = if ($DscVerbose) { "--verbose" } else { "" }

# Apply DSC configuration using the dsc CLI tool
Write-Output -InputObject "Applying DSC configuration from config.yaml..."
try {
    if ($verbosityFlag) {
        & pwsh -NoProfile -Command "dsc config set --file $setupPath $verbosityFlag"
    }
    else {
        & pwsh -NoProfile -Command "dsc config set --file $setupPath"
    }

    if ($LASTEXITCODE -ne 0) {
        Write-Error -Message "Error applying DSC configuration. Exit code: $LASTEXITCODE"
        exit $LASTEXITCODE
    }

    Write-Output -InputObject "DSC configuration applied successfully."
}
catch {
    Write-Error -Message "Error applying DSC configuration: $_"
    exit 1
}

#endregion Generate and Apply DSC Configuration

Write-Output -InputObject "Setup complete."
Stop-Transcript

Write-Output -InputObject "`nSetup completed successfully!"
Write-Output -InputObject "Full log available at: $transcriptFile"
