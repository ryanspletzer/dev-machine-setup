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
    [ValidateSet('error', 'warning', 'info', 'debug', 'trace')]
    [string]
    $DscTraceLevel = 'trace',

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

#region Install Prerequisites

# Install Chocolatey if not already installed
if (-not (Get-Command -Name choco -ErrorAction SilentlyContinue)) {
    Write-Output -InputObject "Installing Chocolatey..."
    Set-ExecutionPolicy -ExecutionPolicy Bypass -Scope Process -Force
    [System.Net.ServicePointManager]::SecurityProtocol = [System.Net.ServicePointManager]::SecurityProtocol -bor 3072
    Invoke-Expression -Command ((New-Object -TypeName System.Net.WebClient).DownloadString('https://chocolatey.org/install.ps1'))
    Update-PathEnvironment
}

# Install PowerShell (pwsh) if not already installed or if Force is specified
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

# Install NuGet provider if not already installed
Install-PackageProvider -Name NuGet -MinimumVersion 2.8.5.201 -Force

# Set PSRepository PSGallery as trusted
Set-PSRepository -Name PSGallery -InstallationPolicy Trusted

# Check if we need to install or update required DSC resources
$requiredModules = @(
    @{ Name = 'cChoco'; RequiredVersion = '2.6.0' },
    @{ Name = 'xPSDesiredStateConfiguration'; RequiredVersion = '9.2.1' }
)

Write-Output -InputObject "Installing required DSC resources..."
foreach ($module in $requiredModules) {
    Write-Output -Message "Installing $($module.Name) (required version: $($module.RequiredVersion))..."
    # Use pwsh to install the module
    Install-Module -Name $($module.Name) -RequiredVersion $($module.RequiredVersion)
}

# Install powershell-yaml module if not already installed
if (-not (Get-Module -Name powershell-yaml -ErrorAction SilentlyContinue)) {
    Write-Output -InputObject "Installing powershell-yaml module..."
    Install-Module -Name powershell-yaml -Force
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

# Define paths
$varsPath = Join-Path -Path $PSScriptRoot -ChildPath $VarsFile

# Load variables from vars.yaml
Write-Output -InputObject "Loading configuration from $varsPath..."
$vars = ConvertFrom-Yaml -Yaml (Get-Content -Path $varsPath -Raw)

# Create the base configuration object
$dscConfig = @{
    metadata = @{
        name    = "WindowsDevMachineSetup"
        version = "1.0.0"
        'Microsoft.DSC' = @{
            securityContext = 'elevated'
        }
    }
    '$schema' = "https://aka.ms/dsc/schemas/v3/bundled/config/document.json"
    resources = @(
        @{
            name       = "Configuration"
            type       = "Microsoft.Windows/WindowsPowerShell"
            properties = @{
                resources = @()
            }
        }
    )
}

# Add Windows Features
# foreach ($feature in $vars.WindowsFeatures) {
#     $dscConfig.resources[0].properties.resources += @{
#         name       = "WindowsFeature_$($feature.name)"
#         type       = "xPSDesiredStateConfiguration/xWindowsOptionalFeature"
#         properties = $feature
#     }
# }

# Add Chocolatey Packages
foreach ($package in $vars.ChocolateyPackages) {
    $dscConfig.resources[0].properties.resources += @{
        name       = "ChocolateyPackage_$($package.name)"
        type       = "cChoco/cChocoPackageInstaller"
        properties = $package
    }
}

# Add PowerShell Modules
# foreach ($module in $vars.PowerShellModules) {
#     $dscConfig.resources += @{
#         name       = "PSResource_$($module.name)"
#         type       = "PSResourceGet/PSResource"
#         properties = $module
#     }
# }

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
# if ($vars.ContainsKey('CustomCommands')) {
#     $customCommandsResource = @{
#         name = "CustomCommands"
#         type = "Script"
#         properties = @{
#             getScript = @'
# return @{
#     Result = "Custom commands execution status"
# }
# '@
#             testScript = @'
# # Always return false to ensure the setScript runs
# return $false
# '@
#             setScript = $vars.CustomCommands
#         }
#     }
#     $dscConfig.resources += $customCommandsResource
# }

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

# Ensure NetConnectionProfiles are set to Private or Domain, if not set Public ones to Private
$netConnectionProfiles = Get-NetConnectionProfile
if ($netConnectionProfiles) {
    foreach ($profile in $netConnectionProfiles) {
        if ($profile.NetworkCategory -eq 'Public') {
            Write-Output -InputObject "Setting network profile '$($profile.Name)' to Private..."
            Set-NetConnectionProfile -InterfaceIndex $profile.InterfaceIndex -NetworkCategory Private
        }
    }
} else {
    Write-Warning -Message "No network connection profiles found."
}

# Ensure WinRM is enabled -- this is required for DSC to work
winrm quickconfig -q

# Apply DSC configuration using the dsc CLI tool
Write-Output -InputObject "Applying DSC configuration from config.yaml..."
try {
    dsc --trace-level $DscTraceLevel config set --file $setupPath
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
