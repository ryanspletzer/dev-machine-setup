#Requires -RunAsAdministrator
#Requires -Version 5.1
# Modern Windows Developer Machine Setup with WinGet Configure
# This script bootstraps a Windows development environment using:
# - WinGet Configure for declarative configuration
# - Chocolatey for package management
# - PowerShell modules from PSGallery

[CmdletBinding()]
param (
    [Parameter()]
    [switch]
    $ValidateOnly,

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
    $VarsFile = "vars.yaml",

    [Parameter()]
    [string]
    $ConfigFile = "config.yaml"
)

# Define the transcript file path
$transcriptFile = "setup_$(Get-Date -Format 'yyyyMMdd_HHmmss').log"
Start-Transcript -Path $transcriptFile

# Set environment variables for Git configuration
if ($GitUserEmail) {
    [Environment]::SetEnvironmentVariable("GIT_USER_EMAIL", $GitUserEmail, "Process")
    Write-Host "Git email set to: $GitUserEmail"
}

if ($GitUserName) {
    [Environment]::SetEnvironmentVariable("GIT_USER_NAME", $GitUserName, "Process")
    Write-Host "Git name set to: $GitUserName"
}

# Function to check if WinGet is installed and install it if needed
function Test-WinGetInstalled {
    try {
        $wingetVersion = winget --version
        Write-Host "WinGet is already installed. Version: $wingetVersion"
    }
    catch {
        Write-Host "WinGet is not installed. Installing WinGet..."

        # Download the Microsoft.DesktopAppInstaller package from the GitHub releases
        $wingetUrl = "https://github.com/microsoft/winget-cli/releases/latest/download/Microsoft.DesktopAppInstaller_8wekyb3d8bbwe.msixbundle"
        $wingetInstallerPath = Join-Path $env:TEMP "Microsoft.DesktopAppInstaller_8wekyb3d8bbwe.msixbundle"

        Invoke-WebRequest -Uri $wingetUrl -OutFile $wingetInstallerPath

        # Install the package
        Add-AppxPackage -Path $wingetInstallerPath

        # Clean up
        Remove-Item $wingetInstallerPath -Force

        # Verify installation
        try {
            $wingetVersion = winget --version
            Write-Host "WinGet installed successfully. Version: $wingetVersion"
        }
        catch {
            Write-Error "Failed to install WinGet. Please install it manually from the Microsoft Store."
            exit 1
        }
    }
}

# Check for WinGet and install if needed
Test-WinGetInstalled

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

# Ensure WinRM is enabled
Write-Host "Configuring WinRM..."
winrm quickconfig -q

# Check if PowerShell YAML module is installed
if (-not (Get-Module -ListAvailable -Name powershell-yaml)) {
    Write-Host "Installing PowerShell YAML module..."
    Install-Module -Name powershell-yaml -Force -Scope CurrentUser
}

# Import the PowerShell YAML module
Import-Module powershell-yaml

# Define file paths
$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$varsFilePath = Join-Path -Path $scriptDir -ChildPath $VarsFile
$configFilePath = Join-Path -Path $scriptDir -ChildPath $ConfigFile

# Import vars.yaml
if (Test-Path -Path $varsFilePath) {
    Write-Host "Importing vars from $varsFilePath..."
    $varsContent = Get-Content -Path $varsFilePath -Raw
    $vars = ConvertFrom-Yaml -Yaml $varsContent
} else {
    Write-Error "Variables file not found: $varsFilePath"
    exit 1
}

# Function to generate the WinGet configuration file
function New-WinGetConfigFile {
    param (
        [Parameter(Mandatory = $true)]
        [hashtable]$Variables,

        [Parameter(Mandatory = $true)]
        [string]$OutputPath
    )

    # Initialize the configuration object
    $config = @{
        '$schema' = 'https://aka.ms/configuration-schema-v2'
        properties = @{
            scope = 'machine'
            locale = 'en-US'
        }
        resources = @()
    }

    # Add Windows Features
    foreach ($feature in $Variables.WindowsFeatures) {
        $config.resources += @{
            resource = 'Microsoft.Windows.Feature'
            directives = @{
                description = "Install Windows Feature: $($feature.Name)"
                allowPrerelease = $true
            }
            settings = @{
                featureName = $feature.Name
                state = 'Enabled'
            }
        }
    }

    # Install Chocolatey Package Manager
    $config.resources += @{
        resource = 'Microsoft.Windows.PowerShell'
        id = 'install_chocolatey'
        directives = @{
            description = 'Install Chocolatey'
            allowPrerelease = $true
        }
        settings = @{
            executeAsPowershell = $true
            executionPolicy = 'Bypass'
            source = @'
if (-not (Get-Command -Name choco -ErrorAction SilentlyContinue)) {
  Write-Host "Installing Chocolatey..."
  Set-ExecutionPolicy -ExecutionPolicy Bypass -Scope Process -Force
  [System.Net.ServicePointManager]::SecurityProtocol = [System.Net.ServicePointManager]::SecurityProtocol -bor 3072
  Invoke-Expression -Command ((New-Object -TypeName System.Net.WebClient).DownloadString('https://chocolatey.org/install.ps1'))
  $env:Path = [System.Environment]::GetEnvironmentVariable("Path", "Machine") + ";" + [System.Environment]::GetEnvironmentVariable("Path", "User")
  Write-Host "Chocolatey installed successfully."
} else {
  Write-Host "Chocolatey is already installed."
}
'@
        }
    }

    # Install PowerShell 7 (pwsh)
    $config.resources += @{
        resource = 'Microsoft.WinGet.DSC/WinGetPackage'
        id = 'install_pwsh'
        directives = @{
            description = 'Install PowerShell 7'
            allowPrerelease = $true
            dependsOn = @('install_chocolatey')
        }
        settings = @{
            id = 'Microsoft.PowerShell'
            source = 'winget'
            ensure = 'Present'
        }
    }

    # Generate Chocolatey packages installation script
    $chocoPackagesScript = @'
# Function to install Chocolatey package if not already installed
function Install-ChocoPackageIfNotInstalled {
    param(
        [string]$PackageName,
        [string]$Params = ""
    )

    if (-not (choco list --local-only --exact $PackageName | Select-String -Pattern "^$PackageName\s")) {
        Write-Host "Installing $PackageName..."
        if ($Params) {
            choco install $PackageName -y --no-progress --params="$Params"
        } else {
            choco install $PackageName -y --no-progress
        }
    } else {
        Write-Host "$PackageName is already installed."
    }
}

# Install Chocolatey packages
$packages = @(

'@

    # Add each Chocolatey package to the script
    foreach ($package in $Variables.ChocolateyPackages) {
        if ($package.params) {
            $chocoPackagesScript += "    @{ Name = ""$($package.Name)""; Params = ""$($package.params)"" },`n"
        } else {
            $chocoPackagesScript += "    @{ Name = ""$($package.Name)"" },`n"
        }
    }

    # Complete the Chocolatey packages script
    $chocoPackagesScript += @'
)

# Install each package
foreach ($package in $packages) {
    if ($package.Params) {
        Install-ChocoPackageIfNotInstalled -PackageName $package.Name -Params $package.Params
    } else {
        Install-ChocoPackageIfNotInstalled -PackageName $package.Name
    }
}
'@

    # Add Chocolatey packages installation to config
    $config.resources += @{
        resource = 'Microsoft.Windows.PowerShell'
        id = 'install_choco_packages'
        directives = @{
            description = 'Install Developer Tools via Chocolatey'
            allowPrerelease = $true
            dependsOn = @('install_chocolatey')
        }
        settings = @{
            executeAsPowershell = $true
            executionPolicy = 'Bypass'
            source = $chocoPackagesScript
        }
    }

    # Generate PowerShell modules installation script
    $psModulesScript = @'
# Install PowerShell modules if not already installed
$modules = @(

'@

    # Add each PowerShell module to the script
    foreach ($module in $Variables.PowerShellModules) {
        $psModulesScript += "    ""$($module.Name)"",`n"
    }

    # Complete the PowerShell modules script
    $psModulesScript += @'
)

foreach ($module in $modules) {
    if (-not (Get-Module -ListAvailable -Name $module)) {
        Write-Host "Installing PowerShell module: $module..."
        Install-Module -Name $module -Force -AllowClobber -Scope AllUsers
    } else {
        Write-Host "PowerShell module $module is already installed."
    }
}
'@

    # Add PowerShell modules installation to config
    $config.resources += @{
        resource = 'Microsoft.Windows.PowerShell'
        id = 'install_powershell_modules'
        directives = @{
            description = 'Install PowerShell Modules'
            allowPrerelease = $true
            dependsOn = @('install_pwsh')
        }
        settings = @{
            executeAsPowershell = $true
            executionPolicy = 'Bypass'
            source = $psModulesScript
        }
    }

    # Add Git configuration if provided
    if ($Variables.ContainsKey('GitConfigScript') -and -not [string]::IsNullOrWhiteSpace($Variables.GitConfigScript)) {
        $config.resources += @{
            resource = 'Microsoft.Windows.PowerShell'
            id = 'configure_git'
            directives = @{
                description = 'Configure Git'
                allowPrerelease = $true
                dependsOn = @('install_choco_packages')
            }
            settings = @{
                executeAsPowershell = $true
                executionPolicy = 'Bypass'
                source = $Variables.GitConfigScript
            }
        }
    }

    # Convert configuration to YAML and save to file
    $configYaml = ConvertTo-Yaml -Data $config -OutFile $OutputPath -Force
    Write-Host "WinGet configuration file generated: $OutputPath"
}

# Generate the WinGet configuration file
New-WinGetConfigFile -Variables $vars -OutputPath $configFilePath

# Apply the configuration
if ($ValidateOnly) {
    Write-Host "Validating configuration..."
    winget configure validate -f $configFilePath
} else {
    Write-Host "Applying configuration..."
    if ($Force) {
        winget configure -f $configFilePath --accept-configuration-agreements --disable-interactivity
    } else {
        winget configure -f $configFilePath
    }
}

Stop-Transcript

Write-Host "`nSetup completed successfully!"
Write-Host "Full log available at: $transcriptFile"
