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
    Install-Module -Name powershell-yaml -Force -Scope CurrentUser
}
Import-Module -Name powershell-yaml

# Define paths
$templatePath = Join-Path -Path $PSScriptRoot -ChildPath $TemplateFile
$valuesPath = Join-Path -Path $PSScriptRoot -ChildPath $ValuesFile
$configPath = Join-Path -Path $PSScriptRoot -ChildPath "config.yaml"

Write-Output -InputObject "Generating DSC configuration from template and values..."
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
    $configContent | Set-Content -Path $configPath -Force
    Write-Verbose -Message "DSC configuration generated successfully at $configPath"
}
catch {
    Write-Error -Message "Error generating DSC configuration: $_"
    exit 1
}

# Set verbosity for DSC based on parameter
$verbosityFlag = if ($DscVerbose) { "--verbose" } else { "" }

# Apply DSC configuration using the dsc CLI tool
Write-Output -InputObject "Applying DSC configuration from dscconfig.yaml..."
try {
    if ($verbosityFlag) {
        & pwsh -NoProfile -Command "dsc config apply $configPath $verbosityFlag"
    }
    else {
        & pwsh -NoProfile -Command "dsc config apply $configPath"
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
